---
name: n8n-api-executions
description: Use when querying n8n executions via API — listing executions, filtering by status or workflow, getting execution details, retrying failed executions, stopping running executions, or deleting execution records.
---

# n8n API: Executions

## Overview

Monitor and control workflow executions: list, filter, inspect, retry, stop, and delete.
**REQUIRED BACKGROUND:** `n8n-api-core` for authentication and pagination.

---

## Endpoints

| Method | Path | Purpose | Access |
| --- | --- | --- | --- |
| GET | `/executions` | List executions (filtered) | authenticated |
| GET | `/executions/{id}` | Get single execution | authenticated |
| DELETE | `/executions/{id}` | Delete execution record | authenticated |
| POST | `/executions/{id}/retry` | Retry a failed execution | authenticated |
| POST | `/executions/{id}/stop` | Stop a running execution | authenticated |
| POST | `/executions/stop` | Stop multiple executions by filter | authenticated |
| GET | `/executions/{id}/tags` | Get tags on an execution | authenticated |
| PUT | `/executions/{id}/tags` | Update tags on an execution | authenticated |

---

## Quick Start — List Recent Errors

```bash
curl "$N8N_HOST/api/v1/executions?status=error&limit=20" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"
```

```javascript
// n8n Code node
const res = await $helpers.httpRequest({
  method: 'GET',
  url: `${$env.N8N_HOST}/api/v1/executions?status=error&limit=20`,
  headers: { 'X-N8N-API-KEY': $env.N8N_API_KEY }
});
return res.data.map(e => ({ json: e }));
```

---

## Common Operations

### List Executions with Filters

```javascript
const params = new URLSearchParams({
  status: 'error',          // canceled | error | running | success | waiting
  workflowId: 'wf-abc123',  // optional
  limit: '50'
});

const res = await $helpers.httpRequest({
  method: 'GET',
  url: `${$env.N8N_HOST}/api/v1/executions?${params}`,
  headers: { 'X-N8N-API-KEY': $env.N8N_API_KEY }
});
```

### Get Execution with Full Data

```bash
# includeData=true fetches node input/output — use sparingly on large instances
curl "$N8N_HOST/api/v1/executions/12345?includeData=true" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"
```

```javascript
const exec = await $helpers.httpRequest({
  method: 'GET',
  url: `${$env.N8N_HOST}/api/v1/executions/12345?includeData=true`,
  headers: { 'X-N8N-API-KEY': $env.N8N_API_KEY }
});
```

> ⚠️ `includeData=true` is expensive on large workflows — avoid in loops.

### Retry a Failed Execution

```bash
curl -X POST "$N8N_HOST/api/v1/executions/12345/retry" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"loadWorkflow": true}'
```

```javascript
await $helpers.httpRequest({
  method: 'POST',
  url: `${$env.N8N_HOST}/api/v1/executions/12345/retry`,
  headers: {
    'X-N8N-API-KEY': $env.N8N_API_KEY,
    'Content-Type': 'application/json'
  },
  body: { loadWorkflow: true }
});
```

`loadWorkflow: true` — uses the current workflow definition (picks up any fixes).
`loadWorkflow: false` — retries with the exact workflow that ran originally.

### Stop a Running Execution

```bash
curl -X POST "$N8N_HOST/api/v1/executions/12345/stop" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"
```

### Stop Multiple Executions

```javascript
// Stop all currently running executions for a specific workflow
const result = await $helpers.httpRequest({
  method: 'POST',
  url: `${$env.N8N_HOST}/api/v1/executions/stop`,
  headers: {
    'X-N8N-API-KEY': $env.N8N_API_KEY,
    'Content-Type': 'application/json'
  },
  body: {
    status: ['running'],
    workflowId: 'wf-abc123'   // optional
    // startedAfter: '2024-01-01T00:00:00Z'  // optional
    // startedBefore: '2024-12-31T23:59:59Z' // optional
  }
});
// result.stopped = number of executions stopped
```

### Delete an Execution

```bash
curl -X DELETE "$N8N_HOST/api/v1/executions/12345" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"
```

Returns `200` with the deleted execution object.

---

## Query Parameters (List)

| Param | Type | Description |
| --- | --- | --- |
| `status` | string | `canceled` \| `error` \| `running` \| `success` \| `waiting` |
| `workflowId` | string | Filter by workflow ID |
| `projectId` | string | Filter by project |
| `includeData` | boolean | Include full node input/output data |
| `limit` | integer | Results per page |
| `cursor` | string | Pagination cursor |

---

## Execution Status Values

| Status | Meaning |
| --- | --- |
| `running` | Currently executing |
| `success` | Completed successfully |
| `error` | Failed with an error |
| `waiting` | Paused (e.g. waiting for webhook) |
| `canceled` | Manually stopped |

---

## Key Rules

- ✅ Use `status` filter — never fetch all executions without filtering on busy instances
- ✅ `loadWorkflow: true` on retry picks up workflow changes since the original run
- ❌ `includeData=true` is expensive — do not use in loops or list calls
- ❌ Cannot retry a `success` or `running` execution — only `error` and `canceled`

---

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| Using `includeData=true` in a list loop | Fetch list without it, then GET individual IDs |
| Retrying a `success` execution | Only `error`/`canceled` executions can be retried |
| Expecting body from DELETE | DELETE returns the deleted execution object (not 204) |
| Forgetting `status` is a string, not array | Single string: `status=error` (not `["error"]`) |

---

## Related Skills

- `n8n-api-core` — Auth, pagination, status codes
- `n8n-api-workflows` — Activate/deactivate workflows
