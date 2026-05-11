---
name: n8n-api-variables
description: Use when managing n8n global variables via API — listing variables, creating new variables, updating variable values, or deleting variables. Variables are accessible in workflows via $vars.variableName.
---

# n8n API: Variables

## Overview

Manage n8n global variables: key-value pairs accessible in all workflows via `$vars.variableName`.
**REQUIRED BACKGROUND:** `n8n-api-core` for authentication and pagination.

---

## Endpoints

| Method | Path | Purpose | Access |
| --- | --- | --- | --- |
| GET | `/variables` | List all variables | authenticated |
| POST | `/variables` | Create a variable | authenticated |
| PUT | `/variables/{id}` | Update variable key/value | authenticated |
| DELETE | `/variables/{id}` | Delete variable | authenticated |

---

## Quick Start — List Variables

```bash
curl "$N8N_HOST/api/v1/variables" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"
```

```javascript
const res = await $helpers.httpRequest({
  method: 'GET',
  url: `${$env.N8N_HOST}/api/v1/variables`,
  headers: { 'X-N8N-API-KEY': $env.N8N_API_KEY }
});
return res.data.map(v => ({ json: v }));
```

---

## Common Operations

### Create a Variable

```bash
curl -X POST "$N8N_HOST/api/v1/variables" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"key": "API_BASE_URL", "value": "https://api.example.com"}'
```

```javascript
const variable = await $helpers.httpRequest({
  method: 'POST',
  url: `${$env.N8N_HOST}/api/v1/variables`,
  headers: {
    'X-N8N-API-KEY': $env.N8N_API_KEY,
    'Content-Type': 'application/json'
  },
  body: {
    key: 'API_BASE_URL',
    value: 'https://api.example.com'
  }
});
// variable.id is used for update/delete
```

### Update a Variable

```javascript
// PUT replaces both key and value
await $helpers.httpRequest({
  method: 'PUT',
  url: `${$env.N8N_HOST}/api/v1/variables/var-abc123`,
  headers: {
    'X-N8N-API-KEY': $env.N8N_API_KEY,
    'Content-Type': 'application/json'
  },
  body: {
    key: 'API_BASE_URL',
    value: 'https://api-v2.example.com'
  }
});
```

### Delete a Variable

```bash
curl -X DELETE "$N8N_HOST/api/v1/variables/var-abc123" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"
```

### Upsert Pattern (create or update)

```javascript
// Find existing variable by key, then create or update
const list = await $helpers.httpRequest({
  method: 'GET',
  url: `${$env.N8N_HOST}/api/v1/variables`,
  headers: { 'X-N8N-API-KEY': $env.N8N_API_KEY }
});

const existing = list.data.find(v => v.key === 'MY_VAR');

if (existing) {
  // Update
  await $helpers.httpRequest({
    method: 'PUT',
    url: `${$env.N8N_HOST}/api/v1/variables/${existing.id}`,
    headers: {
      'X-N8N-API-KEY': $env.N8N_API_KEY,
      'Content-Type': 'application/json'
    },
    body: { key: 'MY_VAR', value: 'new-value' }
  });
} else {
  // Create
  await $helpers.httpRequest({
    method: 'POST',
    url: `${$env.N8N_HOST}/api/v1/variables`,
    headers: {
      'X-N8N-API-KEY': $env.N8N_API_KEY,
      'Content-Type': 'application/json'
    },
    body: { key: 'MY_VAR', value: 'new-value' }
  });
}
```

---

## Query Parameters (List)

| Param | Type | Description |
| --- | --- | --- |
| `limit` | integer | Results per page |
| `cursor` | string | Pagination cursor |
| `projectId` | string | Filter by project scope |
| `state` | string | Filter: `empty` returns only unset/empty variables |

---

## Using Variables in Workflows

Once created, variables are available in all n8n expressions:

```
{{ $vars.API_BASE_URL }}
```

In Code nodes:

```javascript
const baseUrl = $vars.API_BASE_URL;
```

---

## Key Rules

- ✅ PUT requires both `key` and `value` — it is a full replace
- ✅ Variable keys are case-sensitive (`API_URL` ≠ `api_url`)
- ❌ No partial update (PATCH) — must send both fields on PUT
- ❌ Creating a duplicate `key` returns a conflict error

---

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| Sending only `value` in PUT body | Include both `key` and `value` |
| Expecting PATCH for partial update | PUT requires full body: `{key, value}` |
| 409 on create | Variable with that key already exists — use PUT to update |
| `$vars.X` undefined in workflow | Variable may not have been created yet — check via list |

---

## Related Skills

- `n8n-api-core` — Auth, pagination, status codes
- `n8n-api-projects` — Scope variables to projects
