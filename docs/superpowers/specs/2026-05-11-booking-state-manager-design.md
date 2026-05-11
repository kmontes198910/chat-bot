# Booking State Manager — Design Spec

**Date:** 2026-05-11  
**Workflow affected:** DoctorKyn - Agendamiento WhatsApp (`kbWzPpbDMnz4TyA0`)  
**Pattern:** CQRS — separate Query and Command sub-workflows  

---

## Problem

The AI Agent uses a Redis chat memory with a 30-message context window (TTL 2h). In long booking
conversations, data captured early (cedula, service, clinic) gets evicted from the window before
the booking completes. The agent then re-asks for information the patient already provided.

---

## Solution Overview

Introduce a dedicated booking state store in Redis, written and read independently of the chat
memory. On every turn:

1. **Before the AI Agent** — read the current partial state and inject it into the system prompt.
2. **After the AI Agent** — extract any newly confirmed fields via a lightweight LLM call, apply
   cascade invalidation, and persist the merged state back to Redis.

The logic is split into two sub-workflows following the CQRS pattern:
- **Reader** — pure query, no side effects
- **Updater** — command, processes and persists state changes

---

## Data Model

**Redis key:** `doctorkyn:n8n-dev:whatsapp:{wa_id}:booking`  
**Type:** String (serialized JSON)  
**TTL:** 7200s (matches the chat memory session)

```json
{
  "cedula":      "123456789",
  "service":     "Cardiología",
  "clinic":      null,
  "date":        null,
  "time_slot":   null,
  "schedule_id": null,
  "price":       null,
  "status":      "collecting"
}
```

### Field descriptions

| Field         | Type            | Description                                        |
|---------------|-----------------|----------------------------------------------------|
| `cedula`      | string \| null  | Patient national ID                                |
| `service`     | string \| null  | Medical specialty — exact name from MCP            |
| `clinic`      | string \| null  | Clinic name — exact name from MCP                  |
| `date`        | string \| null  | Appointment date `YYYY-MM-DD`                      |
| `time_slot`   | string \| null  | Appointment time `HH:MM`                           |
| `schedule_id` | string \| null  | Schedule ID from `get_time_slots` MCP tool         |
| `price`       | number \| null  | Final price after discounts                        |
| `status`      | string          | `collecting` \| `confirming` \| `booked` \| `cancelled` |

### Cascade dependency chain

If an upstream field **changes value**, all downstream fields are cleared to `null`:

```
cedula     → (no downstream deps)
service    → clears: clinic, date, time_slot, schedule_id, price
clinic     → clears: date, time_slot, schedule_id, price
date       → clears: time_slot, schedule_id
time_slot  → clears: schedule_id
```

### Conflict detection (hybrid)

- **Obvious change** (field value differs from stored value) → cascade handled automatically by the
  Updater Code node.
- **Ambiguous change** (patient implies a change without stating a new value explicitly, e.g.
  "something closer to home") → field is set to `"conflict"` so the agent sees it and resolves it
  in conversation.
- **Any status other than `booked`** → flow continues normally, no gate, no interruption.
- **Booked status** → confirmation gate applies (see below). All other field changes are ignored
  until the gate resolves.

---

## Sub-workflow: DoctorKyn - Booking State Reader (Query)

**Trigger:** Execute Workflow (called by main workflow before AI Agent)  
**Input:** `{ wa_id: string }`  
**Output:** `{ bookingState: object, bookingStateFormatted: string }`

### Node sequence

```
When Executed by Another Workflow
 → Redis GET  (key: doctorkyn:..:{wa_id}:booking)
 → Code: Parse & Default
 → Code: Format for System Prompt
 → (returns to caller)
```

### Parse & Default (Code node)

Parse the Redis value as JSON. If null or parse error, return the empty default state:

```js
{
  cedula: null, service: null, clinic: null,
  date: null, time_slot: null, schedule_id: null,
  price: null, status: "collecting"
}
```

### Format for System Prompt (Code node)

Build the `bookingStateFormatted` string to append to the AI Agent system message:

```
## PROGRESO DE RESERVA ACTUAL
- Cédula:      123456789
- Servicio:    Cardiología
- Clínica:     (pendiente)
- Fecha:       (pendiente)
- Horario:     (pendiente)
- Schedule ID: (pendiente)
- Precio:      (pendiente)
- Estado:      collecting

Nunca vuelvas a pedir un campo que ya esté confirmado (valor distinto de null).
Si un campo muestra "conflict", aclaralo con el paciente antes de continuar.
```

`null` values are rendered as `(pendiente)`. `"conflict"` values are rendered as `⚠️ conflict`.

---

## Sub-workflow: DoctorKyn - Booking State Updater (Command)

**Trigger:** Execute Workflow (called by main workflow after AI Agent)  
**Input:** `{ wa_id: string, agentOutput: string, inputText: string }`  
**Output:** `{ bookingState: object }`

### Node sequence

```
When Executed by Another Workflow
 → Redis GET  (current state)
 → Code: Parse current state
 → Code: Build extraction prompt
 → GPT-4.1-mini (JSON mode): extract confirmed fields
 → Code: Cascade & Merge
 → Redis SET  (TTL 7200s)
 → (returns updated bookingState to caller)
```

### LLM Extraction — system prompt

```
You are a structured data extractor for a medical appointment booking system.

Given one conversational turn (patient input + assistant response), extract ONLY the fields that
were explicitly confirmed in this turn. Do NOT carry over previous values — return null for
anything not confirmed in this specific exchange.

Return valid JSON only, no explanation:
{
  "cedula":               string | null,
  "service":              string | null,
  "clinic":               string | null,
  "date":                 string | null,   // YYYY-MM-DD
  "time_slot":            string | null,   // HH:MM
  "schedule_id":          string | null,
  "price":                number | null,
  "status":               "collecting" | "confirming" | "booked" | "cancelled" | null,
  "newBookingConfirmed":  boolean         // true ONLY if patient explicitly confirmed starting
                                          // a new booking while a previous one is already booked
}
```

**LLM parameters:** GPT-4.1-mini, temperature 0, max_tokens 200, response_format: json_object

### Cascade & Merge (Code node)

```
DOWNSTREAM = {
  service:    [clinic, date, time_slot, schedule_id, price],
  clinic:     [date, time_slot, schedule_id, price],
  date:       [time_slot, schedule_id],
  time_slot:  [schedule_id],
}

// Gate: only applies when previous status was "booked"
if current.status === "booked":
  if extracted.newBookingConfirmed === true:
    reset all fields to null, set status = "collecting"
    apply extracted fields to fresh state
  else:
    discard all changes, return current state unchanged  // patient is just inquiring
  end
else:
  // Normal flow — any status other than "booked" continues without gate
  for each extracted field with a non-null value:
    if current[field] !== null AND current[field] !== extracted[field]:
      if field in DOWNSTREAM:
        clear all downstream fields to null   // obvious cascade
    merge extracted[field] into current state
  end
```

**`newBookingConfirmed` flag:** the LLM extractor sets this to `true` only when the patient
explicitly confirms they want to start a new booking (e.g. "sí, quiero agendar otra cita",
"también necesito una para optometría y confirmo que es nueva"). Inquiries about the existing
appointment ("¿a qué hora era mi cita?") leave it `false`.

**Reader behaviour when status is `booked`:** the formatted state block includes both the completed
booking summary and a prompt for the agent:

```
## RESERVA COMPLETADA
- Servicio:    Cardiología
- Recibo:      REC-12345
- Estado:      booked

Si el paciente quiere agendar una nueva cita, pedile confirmación explícita antes de continuar.
Solo cuando confirme, el sistema reseteará el estado para la nueva reserva.
```

Ambiguous conflicts (field stays as-is but downstream may be invalid) are left for the agent to
resolve. When an ambiguous change is detected, the affected downstream fields are set to
`"conflict"` so the agent sees them explicitly in the injected state block and re-verifies via MCP
tools before proceeding.

---

## Changes to Main Workflow (Agendamiento WhatsApp)

### New nodes (3 total)

| Node | Type | Position |
|------|------|----------|
| `Execute: State Reader` | Execute Workflow | After `Set Input Text` |
| `Inject State` | Code | After `Execute: State Reader` |
| `Execute: State Updater` | Execute Workflow | After `AI Agent`, before `Check Output` |

### Inject State (Code node)

Merges `bookingStateFormatted` from the Reader into the data object so the AI Agent's
`systemMessage` expression can reference it:

```js
return [{
  json: {
    ...previousNodeData,
    bookingStateFormatted: $('Execute: State Reader').item.json.bookingStateFormatted
  }
}];
```

### AI Agent — system message update

Append at the end of the existing `systemMessage` expression:

```
\n\n{{ $json.bookingStateFormatted }}
```

### Updated flow

```
Set Input Text
 → Execute: State Reader      { wa_id }  →  { bookingState, bookingStateFormatted }
 → Inject State               merges bookingStateFormatted into context
 → AI Agent                   system prompt now includes booking progress block
 → Execute: State Updater     { wa_id, agentOutput, inputText }  →  { bookingState }
 → Check Output
 → Reply WhatsApp / Fallback Reply WhatsApp
```

Abuse protection, STT path, and all other existing nodes remain unchanged.

---

## Error Handling

- Redis GET returns null (first message or expired session) → Reader returns empty default state, no
  error.
- LLM extraction returns invalid JSON → Updater Code node catches parse error and skips the write,
  leaving current state unchanged.
- Redis SET fails → Updater logs the error and passes through; the agent continues without state
  persistence for this turn (recoverable on next turn).
- All unhandled errors route to `DoctorKyn - Error Handler` (`FAOaoPBNYLkpd3gf`) via the existing
  `errorWorkflow` setting.

---

## Credentials & Infrastructure

| Resource | Credential | Notes |
|----------|-----------|-------|
| Redis | `Keimer Infra Cache` (`LuDTeor4M8AG2GWQ`) | Already used in main workflow |
| OpenAI | `Keimer OpenAI` (`wLpMuXGfvIEudfkX`) | Already used in main workflow |

No new credentials required.

---

## Out of Scope

- Persisting booked appointment state beyond the 2h TTL (long-term storage belongs in the MCP
  calendar service, not in this workflow layer).
- Proactive session resume (notifying a patient about an incomplete booking after session expiry).
- Multi-appointment support within a single session — a new booking resets the state completely;
  the previous booking details are not retained in Redis after the reset (they are already persisted
  in the MCP calendar service via `receiptId`).
