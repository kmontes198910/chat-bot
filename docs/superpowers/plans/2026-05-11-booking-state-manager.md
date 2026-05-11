# Booking State Manager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix AI Agent amnesia in long WhatsApp booking conversations by persisting partial booking state in Redis and injecting it into the system prompt on every turn.

**Architecture:** Two CQRS sub-workflows (Reader query / Updater command) called from the main Agendamiento WhatsApp workflow. Reader injects current state before the AI Agent; Updater extracts confirmed fields via GPT-4.1-mini after the agent responds, applies cascade invalidation, and writes back to Redis.

**Tech Stack:** n8n workflows (JSON), Redis, OpenAI GPT-4.1-mini (HTTP Request with JSON mode), n8n MCP tools for workflow management.

**Spec:** `docs/superpowers/specs/2026-05-11-booking-state-manager-design.md`

---

## Files

| Action | Path | Purpose |
|--------|------|---------|
| Create | `workflows/doctorkyn/DoctorKyn - Booking State Reader.json` | Reader sub-workflow local copy |
| Create | `workflows/doctorkyn/DoctorKyn - Booking State Updater.json` | Updater sub-workflow local copy |
| Modify | `workflows/doctorkyn/DoctorKyn - Agendamiento WhatsApp.json` | Main workflow — 3 new nodes + system prompt update |

---

## Task 1: Create the Booking State Reader sub-workflow

**Files:**
- Create: `workflows/doctorkyn/DoctorKyn - Booking State Reader.json`

### Reference constants (used throughout all tasks)

```
REDIS_CREDENTIAL_ID   = "LuDTeor4M8AG2GWQ"
REDIS_CREDENTIAL_NAME = "Keimer Infra Cache"
OPENAI_CREDENTIAL_ID  = "wLpMuXGfvIEudfkX"
OPENAI_CREDENTIAL_NAME= "Keimer OpenAI"
MAIN_WORKFLOW_ID      = "kbWzPpbDMnz4TyA0"
REDIS_KEY_PATTERN     = "doctorkyn:n8n-dev:whatsapp:{wa_id}:booking"
```

- [ ] **Step 1.1: Create the Reader workflow via n8n MCP**

```javascript
n8n_create_workflow({
  name: "DoctorKyn - Booking State Reader",
  nodes: [
    {
      name: "When Executed by Another Workflow",
      type: "n8n-nodes-base.executeWorkflowTrigger",
      typeVersion: 1,
      position: [-400, 0],
      parameters: {}
    },
    {
      name: "Redis GET - Booking State",
      type: "n8n-nodes-base.redis",
      typeVersion: 1,
      position: [-200, 0],
      parameters: {
        operation: "get",
        propertyName: "value",
        key: "=doctorkyn:n8n-dev:whatsapp:{{ $json.wa_id }}:booking",
        options: {}
      },
      credentials: {
        redis: { id: "LuDTeor4M8AG2GWQ", name: "Keimer Infra Cache" }
      }
    },
    {
      name: "Parse and Default",
      type: "n8n-nodes-base.code",
      typeVersion: 2,
      position: [0, 0],
      parameters: {
        jsCode: `const raw = $input.first().json.value;
let state;
try {
  state = raw ? JSON.parse(raw) : null;
} catch(e) {
  state = null;
}
if (!state) {
  state = {
    cedula: null, service: null, clinic: null,
    date: null, time_slot: null, schedule_id: null,
    price: null, receipt_id: null, status: 'collecting'
  };
}
return [{ json: { bookingState: state } }];`
      }
    },
    {
      name: "Format for System Prompt",
      type: "n8n-nodes-base.code",
      typeVersion: 2,
      position: [200, 0],
      parameters: {
        jsCode: `const state = $input.first().json.bookingState;

const fmt = (v) => {
  if (v === null || v === undefined) return '(pendiente)';
  if (v === 'conflict') return '⚠️ conflict';
  return String(v);
};

let block;
if (state.status === 'booked') {
  block = \`## RESERVA COMPLETADA
- Servicio:    \${fmt(state.service)}
- Clínica:     \${fmt(state.clinic)}
- Fecha:       \${fmt(state.date)}
- Horario:     \${fmt(state.time_slot)}
- Precio:      \${fmt(state.price)}
- Schedule ID: \${fmt(state.schedule_id)}
- Estado:      booked

Si el paciente quiere agendar una nueva cita, pedile confirmación explícita antes de continuar.
Solo cuando confirme, el sistema reseteará el estado para la nueva reserva.\`;
} else {
  block = \`## PROGRESO DE RESERVA ACTUAL
- Cédula:      \${fmt(state.cedula)}
- Servicio:    \${fmt(state.service)}
- Clínica:     \${fmt(state.clinic)}
- Fecha:       \${fmt(state.date)}
- Horario:     \${fmt(state.time_slot)}
- Schedule ID: \${fmt(state.schedule_id)}
- Precio:      \${fmt(state.price)}
- Estado:      \${state.status}

Nunca vuelvas a pedir un campo que ya esté confirmado (valor distinto de null).
Si un campo muestra "conflict", aclaralo con el paciente antes de continuar.\`;
}

return [{ json: {
  bookingState: state,
  bookingStateFormatted: block
} }];`
      }
    }
  ],
  connections: {
    "When Executed by Another Workflow": {
      main: [[{ node: "Redis GET - Booking State", type: "main", index: 0 }]]
    },
    "Redis GET - Booking State": {
      main: [[{ node: "Parse and Default", type: "main", index: 0 }]]
    },
    "Parse and Default": {
      main: [[{ node: "Format for System Prompt", type: "main", index: 0 }]]
    }
  }
})
```

Record the returned workflow ID as `READER_WORKFLOW_ID`.

- [ ] **Step 1.2: Validate the Reader workflow**

```javascript
n8n_validate_workflow({ id: READER_WORKFLOW_ID })
```

Expected: no errors. If errors appear, load the `n8n-validation-expert` skill and fix before continuing.

- [ ] **Step 1.3: Save Reader workflow locally**

```javascript
n8n_get_workflow({ id: READER_WORKFLOW_ID })
```

Write the returned JSON (pretty-printed, 2-space indent, UTF-8) to:
`workflows/doctorkyn/DoctorKyn - Booking State Reader.json`

- [ ] **Step 1.4: Commit**

```bash
git add workflows/doctorkyn/
git commit -m "feat: add Booking State Reader sub-workflow

Query-side of CQRS pattern — reads and formats booking state
from Redis for injection into AI Agent system prompt."
```

---

## Task 2: Create the Booking State Updater sub-workflow

**Files:**
- Create: `workflows/doctorkyn/DoctorKyn - Booking State Updater.json`

- [ ] **Step 2.1: Create the Updater workflow via n8n MCP**

```javascript
n8n_create_workflow({
  name: "DoctorKyn - Booking State Updater",
  nodes: [
    {
      name: "When Executed by Another Workflow",
      type: "n8n-nodes-base.executeWorkflowTrigger",
      typeVersion: 1,
      position: [-600, 0],
      parameters: {}
    },
    {
      name: "Redis GET - Current State",
      type: "n8n-nodes-base.redis",
      typeVersion: 1,
      position: [-400, 0],
      parameters: {
        operation: "get",
        propertyName: "value",
        key: "=doctorkyn:n8n-dev:whatsapp:{{ $('When Executed by Another Workflow').item.json.wa_id }}:booking",
        options: {}
      },
      credentials: {
        redis: { id: "LuDTeor4M8AG2GWQ", name: "Keimer Infra Cache" }
      }
    },
    {
      name: "Parse Current State",
      type: "n8n-nodes-base.code",
      typeVersion: 2,
      position: [-200, 0],
      parameters: {
        jsCode: `const raw = $input.first().json.value;
let state;
try {
  state = raw ? JSON.parse(raw) : null;
} catch(e) {
  state = null;
}
if (!state) {
  state = {
    cedula: null, service: null, clinic: null,
    date: null, time_slot: null, schedule_id: null,
    price: null, status: 'collecting'
  };
}
return [{ json: { currentState: state } }];`
      }
    },
    {
      name: "Build Extraction Prompt",
      type: "n8n-nodes-base.code",
      typeVersion: 2,
      position: [0, 0],
      parameters: {
        jsCode: `const trigger = $('When Executed by Another Workflow').item.json;
const agentOutput = trigger.agentOutput || '';
const inputText   = trigger.inputText   || '';

const userMessage = \`PATIENT INPUT:\\n\${inputText}\\n\\nASSISTANT RESPONSE:\\n\${agentOutput}\`;

return [{ json: {
  currentState: $('Parse Current State').item.json.currentState,
  extractionUserMessage: userMessage
} }];`
      }
    },
    {
      name: "Extract Fields LLM",
      type: "n8n-nodes-base.httpRequest",
      typeVersion: 4.2,
      position: [200, 0],
      parameters: {
        method: "POST",
        url: "https://api.openai.com/v1/chat/completions",
        authentication: "predefinedCredentialType",
        nodeCredentialType: "openAiApi",
        sendBody: true,
        specifyBody: "json",
        jsonBody: "={\n  \"model\": \"gpt-4.1-mini\",\n  \"temperature\": 0,\n  \"max_tokens\": 200,\n  \"response_format\": { \"type\": \"json_object\" },\n  \"messages\": [\n    {\n      \"role\": \"system\",\n      \"content\": \"You are a structured data extractor for a medical appointment booking system.\\n\\nGiven one conversational turn (patient input + assistant response), extract ONLY the fields that were explicitly confirmed in this turn. Do NOT carry over previous values — return null for anything not confirmed in this specific exchange.\\n\\nReturn valid JSON only, no explanation:\\n{\\n  \\\"cedula\\\": string | null,\\n  \\\"service\\\": string | null,\\n  \\\"clinic\\\": string | null,\\n  \\\"date\\\": string | null,\\n  \\\"time_slot\\\": string | null,\\n  \\\"schedule_id\\\": string | null,\\n  \\\"price\\\": number | null,\\n  \\\"receipt_id\\\": string | null,\\n  \\\"status\\\": \\\"collecting\\\" | \\\"confirming\\\" | \\\"booked\\\" | \\\"cancelled\\\" | null,\\n  \\\"newBookingConfirmed\\\": boolean\\n}\\n\\nnewBookingConfirmed must be true ONLY if the patient explicitly confirmed starting a new booking while a previous one is already booked. Default false.\"\n    },\n    {\n      \"role\": \"user\",\n      \"content\": \"={{ $json.extractionUserMessage }}\"\n    }\n  ]\n}",
        options: {}
      },
      credentials: {
        openAiApi: { id: "wLpMuXGfvIEudfkX", name: "Keimer OpenAI" }
      }
    },
    {
      name: "Cascade and Merge",
      type: "n8n-nodes-base.code",
      typeVersion: 2,
      position: [400, 0],
      parameters: {
        jsCode: `const DOWNSTREAM = {
  service:   ['clinic', 'date', 'time_slot', 'schedule_id', 'price'],
  clinic:    ['date', 'time_slot', 'schedule_id', 'price'],
  date:      ['time_slot', 'schedule_id'],
  time_slot: ['schedule_id'],
};

const current = $('Parse Current State').item.json.currentState;
const FIELDS = ['cedula','service','clinic','date','time_slot','schedule_id','price','receipt_id','status'];

let extracted;
try {
  const raw = $input.first().json.choices[0].message.content;
  extracted = JSON.parse(raw);
} catch(e) {
  // LLM returned invalid JSON — skip write, pass current state through
  return [{ json: { bookingState: current, skipWrite: true } }];
}

// Gate: booked status
if (current.status === 'booked') {
  if (extracted.newBookingConfirmed === true) {
    // Full reset then apply extracted fields
    const   fresh = {
      cedula: null, service: null, clinic: null,
      date: null, time_slot: null, schedule_id: null,
      price: null, receipt_id: null, status: 'collecting'
    };
    for (const f of FIELDS) {
      if (extracted[f] !== null && extracted[f] !== undefined) {
        fresh[f] = extracted[f];
      }
    }
    return [{ json: { bookingState: fresh, skipWrite: false } }];
  } else {
    // Patient is inquiring — no changes
    return [{ json: { bookingState: current, skipWrite: false } }];
  }
}

// Normal flow
const merged = { ...current };
for (const field of FIELDS) {
  const newVal = extracted[field];
  if (newVal === null || newVal === undefined) continue;
  const oldVal = merged[field];
  if (oldVal !== null && oldVal !== newVal && DOWNSTREAM[field]) {
    for (const ds of DOWNSTREAM[field]) {
      merged[ds] = null;
    }
  }
  merged[field] = newVal;
}

return [{ json: { bookingState: merged, skipWrite: false } }];`
      }
    },
    {
      name: "IF Skip Write",
      type: "n8n-nodes-base.if",
      typeVersion: 2.2,
      position: [600, 0],
      parameters: {
        conditions: {
          options: { caseSensitive: true, leftValue: "", typeValidation: "strict" },
          conditions: [{
            id: "skip-write-check-001",
            leftValue: "={{ $json.skipWrite }}",
            rightValue: true,
            operator: { type: "boolean", operation: "equals" }
          }],
          combinator: "and"
        },
        options: {}
      }
    },
    {
      name: "Redis SET - Save State",
      type: "n8n-nodes-base.redis",
      typeVersion: 1,
      position: [800, 100],
      parameters: {
        operation: "set",
        key: "=doctorkyn:n8n-dev:whatsapp:{{ $('When Executed by Another Workflow').item.json.wa_id }}:booking",
        value: "={{ JSON.stringify($('Cascade and Merge').item.json.bookingState) }}",
        expire: true,
        ttl: 7200
      },
      credentials: {
        redis: { id: "LuDTeor4M8AG2GWQ", name: "Keimer Infra Cache" }
      }
    },
    {
      name: "Return State",
      type: "n8n-nodes-base.code",
      typeVersion: 2,
      position: [1000, 0],
      parameters: {
        jsCode: `// Merge both IF branches back into a single output
const state = $('Cascade and Merge').item.json.bookingState;
return [{ json: { bookingState: state } }];`
      }
    }
  ],
  connections: {
    "When Executed by Another Workflow": {
      main: [[{ node: "Redis GET - Current State", type: "main", index: 0 }]]
    },
    "Redis GET - Current State": {
      main: [[{ node: "Parse Current State", type: "main", index: 0 }]]
    },
    "Parse Current State": {
      main: [[{ node: "Build Extraction Prompt", type: "main", index: 0 }]]
    },
    "Build Extraction Prompt": {
      main: [[{ node: "Extract Fields LLM", type: "main", index: 0 }]]
    },
    "Extract Fields LLM": {
      main: [[{ node: "Cascade and Merge", type: "main", index: 0 }]]
    },
    "Cascade and Merge": {
      main: [[{ node: "IF Skip Write", type: "main", index: 0 }]]
    },
    "IF Skip Write": {
      main: [
        [{ node: "Return State", type: "main", index: 0 }],
        [{ node: "Redis SET - Save State", type: "main", index: 0 }]
      ]
    },
    "Redis SET - Save State": {
      main: [[{ node: "Return State", type: "main", index: 0 }]]
    }
  }
})
```

Record the returned workflow ID as `UPDATER_WORKFLOW_ID`.

- [ ] **Step 2.2: Validate the Updater workflow**

```javascript
n8n_validate_workflow({ id: UPDATER_WORKFLOW_ID })
```

Expected: no errors. Fix any issues using the `n8n-validation-expert` skill before continuing.

- [ ] **Step 2.3: Save Updater workflow locally**

```javascript
n8n_get_workflow({ id: UPDATER_WORKFLOW_ID })
```

Write the returned JSON to:
`workflows/doctorkyn/DoctorKyn - Booking State Updater.json`

- [ ] **Step 2.4: Commit**

```bash
git add workflows/doctorkyn/
git commit -m "feat: add Booking State Updater sub-workflow

Command-side of CQRS pattern — LLM extraction, cascade
invalidation, booked-status gate, and Redis persistence."
```

---

## Task 3: Update the main Agendamiento WhatsApp workflow

**Files:**
- Modify: `workflows/doctorkyn/DoctorKyn - Agendamiento WhatsApp.json`

The main workflow ID is `kbWzPpbDMnz4TyA0`. `READER_WORKFLOW_ID` and `UPDATER_WORKFLOW_ID` are the IDs recorded in Tasks 1 and 2.

- [ ] **Step 3.1: Add Execute State Reader node (after Set Input Text)**

```javascript
n8n_update_partial_workflow({
  id: "kbWzPpbDMnz4TyA0",
  intent: "Add Execute State Reader node after Set Input Text",
  operations: [
    {
      type: "addNode",
      node: {
        name: "Execute: State Reader",
        type: "n8n-nodes-base.executeWorkflow",
        typeVersion: 1.1,
        position: [560, 16],
        parameters: {
          workflowId: {
            __rl: true,
            value: "READER_WORKFLOW_ID",   // replace with actual ID
            mode: "id"
          },
          options: {}
        }
      }
    }
  ]
})
```

- [ ] **Step 3.2: Add Inject State node (after Execute: State Reader)**

```javascript
n8n_update_partial_workflow({
  id: "kbWzPpbDMnz4TyA0",
  intent: "Add Inject State code node to merge bookingStateFormatted into context",
  operations: [
    {
      type: "addNode",
      node: {
        name: "Inject State",
        type: "n8n-nodes-base.code",
        typeVersion: 2,
        position: [720, 16],
        parameters: {
          jsCode: `const inputText = $('Set Input Text').item.json.inputText;
const formatted = $('Execute: State Reader').item.json.bookingStateFormatted || '';
return [{ json: { inputText, bookingStateFormatted: formatted } }];`
        }
      }
    }
  ]
})
```

- [ ] **Step 3.3: Add Execute State Updater node (between AI Agent and Check Output)**

```javascript
n8n_update_partial_workflow({
  id: "kbWzPpbDMnz4TyA0",
  intent: "Add Execute State Updater node between AI Agent and Check Output",
  operations: [
    {
      type: "addNode",
      node: {
        name: "Execute: State Updater",
        type: "n8n-nodes-base.executeWorkflow",
        typeVersion: 1.1,
        position: [1040, 16],
        parameters: {
          workflowId: {
            __rl: true,
            value: "UPDATER_WORKFLOW_ID",   // replace with actual ID
            mode: "id"
          },
          fields: {
            values: [
              {
                name: "wa_id",
                stringValue: "={{ $('WA Trigger').item.json.contacts[0].wa_id }}"
              },
              {
                name: "agentOutput",
                stringValue: "={{ $json.output }}"
              },
              {
                name: "inputText",
                stringValue: "={{ $('Set Input Text').item.json.inputText }}"
              }
            ]
          },
          options: {}
        }
      }
    }
  ]
})
```

- [ ] **Step 3.4: Rewire connections**

Remove the existing `Set Input Text → AI Agent` connection and `AI Agent → Check Output` connection, then add the new routing through the new nodes:

```javascript
n8n_update_partial_workflow({
  id: "kbWzPpbDMnz4TyA0",
  intent: "Rewire connections through new state nodes",
  operations: [
    {
      type: "removeConnection",
      source: "Set Input Text",
      target: "AI Agent"
    },
    {
      type: "removeConnection",
      source: "AI Agent",
      target: "Check Output"
    },
    {
      type: "addConnection",
      source: "Set Input Text",
      target: "Execute: State Reader"
    },
    {
      type: "addConnection",
      source: "Execute: State Reader",
      target: "Inject State"
    },
    {
      type: "addConnection",
      source: "Inject State",
      target: "AI Agent"
    },
    {
      type: "addConnection",
      source: "AI Agent",
      target: "Execute: State Updater"
    },
    {
      type: "addConnection",
      source: "Execute: State Updater",
      target: "Check Output"
    }
  ]
})
```

- [ ] **Step 3.5: Update the AI Agent node — pass wa_id and inject bookingStateFormatted**

The AI Agent's `text` input must now come from `Inject State` (which has `inputText`), and its `systemMessage` must append the state block. Use `patchNodeField` for surgical edits:

```javascript
n8n_update_partial_workflow({
  id: "kbWzPpbDMnz4TyA0",
  intent: "Update AI Agent to use injected booking state in system prompt",
  operations: [
    {
      type: "patchNodeField",
      nodeName: "AI Agent",
      key: "parameters.options.systemMessage",
      value: "=[existing system message content]\n\n## FLUJO DE AGENDAMIENTO\n\nIMPORTANTE: Antes de cada pregunta, revisá el bloque PROGRESO DE RESERVA ACTUAL al final de este mensaje. Seguí estas reglas estrictamente:\n\n- Si un campo ya tiene valor → NO lo vuelvas a pedir. Úsalo directamente.\n- Si un campo muestra ⚠️ conflict → resuélvelo antes de avanzar.\n- Si status es \"booked\" → no inicies una nueva reserva sin confirmación explícita del paciente.\n- Siempre retomá desde el primer campo con valor null en esta secuencia:\n  cedula → service → clinic → date → time_slot → (confirmar precio) → book_appointment\n\nPasos:\n1. cedula null   → pedí la cédula → find_patient(identification)\n2. service null  → SIEMPRE llamá get_available_services() y mostrá lista numerada\n3. clinic null   → get_available_clinics(serviceName). Si no sabe → find_nearby_clinics\n4. date null     → get_available_days(clinicName, serviceName, hoy, hoy+30d). Máx 5 opciones.\n5. time_slot null → get_time_slots(clinicName, serviceName, date). Incluye scheduleId por slot.\n6. Todos completos → get_discounts(cedula, clinic) → confirmá precio final → book_appointment\n\n{{ $json.bookingStateFormatted }}"
    }
  ]
})
```

> **Important:** Before running this step, fetch the current AI Agent system message from the remote workflow using `n8n_get_workflow({ id: "kbWzPpbDMnz4TyA0" })`. Replace the existing `## FLUJO DE AGENDAMIENTO` section with the new state-aware version above, and append `\n\n{{ $json.bookingStateFormatted }}` at the very end. Do not overwrite any other section of the system message.

- [ ] **Step 3.6: Validate the main workflow**

```javascript
n8n_validate_workflow({ id: "kbWzPpbDMnz4TyA0" })
```

Expected: no errors. Use `n8n-validation-expert` skill for any issues.

- [ ] **Step 3.7: Save main workflow locally**

```javascript
n8n_get_workflow({ id: "kbWzPpbDMnz4TyA0" })
```

Overwrite `workflows/doctorkyn/DoctorKyn - Agendamiento WhatsApp.json` with the returned JSON.

- [ ] **Step 3.8: Commit**

```bash
git add workflows/doctorkyn/
git commit -m "feat: wire booking state manager into Agendamiento WhatsApp

- Add Execute: State Reader before AI Agent (inject current state)
- Add Inject State code node (merge bookingStateFormatted)
- Add Execute: State Updater after AI Agent (extract + persist)
- Update AI Agent system prompt with state-aware FLUJO section"
```

---

## Task 4: End-to-end test scenarios

No automated tests exist for n8n workflows. Validate using n8n's manual test execution and WhatsApp test messages. Run each scenario and verify Redis state after each turn using the `DoctorKyn - Test Redis Helper` workflow.

- [ ] **Step 4.1: Verify Reader returns empty state on first message**

Trigger the Reader sub-workflow manually with input `{ "wa_id": "TEST_NUMBER" }`.

Expected output:
```json
{
  "bookingState": {
    "cedula": null, "service": null, "clinic": null,
    "date": null, "time_slot": null, "schedule_id": null,
    "price": null, "status": "collecting"
  },
  "bookingStateFormatted": "## PROGRESO DE RESERVA ACTUAL\n- Cédula:      (pendiente)\n..."
}
```

- [ ] **Step 4.2: Verify Updater captures cedula correctly**

Trigger the Updater manually with:
```json
{
  "wa_id": "TEST_NUMBER",
  "inputText": "Mi cédula es 123456789",
  "agentOutput": "Perfecto, encontré tu registro. ¿Qué especialidad necesitas?"
}
```

Expected: Redis key `doctorkyn:n8n-dev:whatsapp:TEST_NUMBER:booking` contains:
```json
{ "cedula": "123456789", "service": null, ..., "status": "collecting" }
```

- [ ] **Step 4.3: Verify cascade — service change clears clinic, date, time_slot**

Pre-populate Redis with:
```json
{ "cedula": "123456789", "service": "Cardiología", "clinic": "Clínica Norte", "date": "2026-05-20", "time_slot": "09:00", "schedule_id": "SCH-001", "price": 50, "status": "confirming" }
```

Trigger the Updater with:
```json
{
  "wa_id": "TEST_NUMBER",
  "inputText": "Mejor quiero optometría",
  "agentOutput": "Claro, te busco disponibilidad para Optometría. ¿En qué clínica preferís?"
}
```

Expected Redis state after:
```json
{ "cedula": "123456789", "service": "Optometría", "clinic": null, "date": null, "time_slot": null, "schedule_id": null, "price": null, "receipt_id": null, "status": "collecting" }
```

- [ ] **Step 4.4: Verify booked gate — inquiry does NOT reset state**

Pre-populate Redis with:
```json
{ "cedula": "123456789", "service": "Cardiología", "clinic": "Clínica Norte", "date": "2026-05-20", "time_slot": "09:00", "schedule_id": "SCH-001", "price": 50, "status": "booked" }
```

Trigger the Updater with:
```json
{
  "wa_id": "TEST_NUMBER",
  "inputText": "¿A qué hora era mi cita?",
  "agentOutput": "Tu cita de Cardiología en Clínica Norte es el 2026-05-20 a las 09:00."
}
```

Expected: Redis state unchanged — `status` remains `booked`, all fields intact.

- [ ] **Step 4.5: Verify booked gate — explicit confirmation resets state**

Same pre-populated Redis as Step 4.4. Trigger the Updater with:

```json
{
  "wa_id": "TEST_NUMBER",
  "inputText": "Sí, quiero agendar una nueva cita para optometría",
  "agentOutput": "Con gusto. Para la nueva cita, ¿me podés confirmar tu cédula?"
}
```

Expected Redis state after:
```json
{ "cedula": null, "service": "Optometría", "clinic": null, "date": null, "time_slot": null, "schedule_id": null, "price": null, "receipt_id": null, "status": "collecting" }
```

- [ ] **Step 4.6: Verify full WhatsApp conversation — agent does not re-ask captured fields**

Send a real WhatsApp message to the bot from a test number. Progress through:
1. Provide cedula → check Redis, verify `cedula` captured
2. Choose service → check Redis, verify `service` captured, `clinic` still null
3. Choose clinic → check Redis, verify `clinic` captured
4. Send 15+ more messages (simulate long conversation window filling up)
5. Ask for available times → agent should NOT ask for cedula, service, or clinic again

Check Redis state at each step using `DoctorKyn - Test Redis Helper`. Verify the state block appears correctly in the AI Agent's context by checking the execution log in n8n.

- [ ] **Step 4.7: Final commit**

```bash
git add workflows/doctorkyn/
git commit -m "test: verify booking state manager end-to-end scenarios

All 6 test scenarios pass: empty init, field capture, cascade
invalidation, booked inquiry gate, booked reset confirmation,
and full conversation with 15+ message window overflow."
```
