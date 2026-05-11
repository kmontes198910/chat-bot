---
name: n8n-api-core
description: Use when working with the n8n REST API, setting up authentication, configuring the API key header, handling pagination with cursors, or interpreting HTTP status codes. Required background for all n8n-api-* skills.
---

# n8n API: Core Concepts

## Overview

Foundation skill for all n8n REST API operations: authentication, base URL, environment variables, cursor pagination, roles, and error codes. **Load this skill before any n8n-api-* resource skill.**

---

## Authentication

Every request requires the API key in the header:

```
X-N8N-API-KEY: <your-api-key>
```

**How to get your API key:** n8n UI → Settings → n8n API → Create or copy key.

### Environment Variables (recommended)

Store these as n8n environment variables or in your `.env`:

```
N8N_HOST=https://your-instance.example.com
N8N_API_KEY=your-api-key-here
```

### curl template

```bash
curl -X GET "$N8N_HOST/api/v1/<resource>" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json"
```

### n8n Code node template

```javascript
const response = await $helpers.httpRequest({
  method: 'GET',
  url: `${$env.N8N_HOST}/api/v1/<resource>`,
  headers: {
    'X-N8N-API-KEY': $env.N8N_API_KEY,
    'Content-Type': 'application/json'
  }
});
return [{ json: response }];
```

---

## Base URL

```
https://<host>/api/v1
```

All endpoint paths in the n8n-api-* skills are relative to this base.

---

## Global Roles

| Role | Permissions |
| --- | --- |
| `global:owner` | Full access — user mgmt, audit, all resources |
| `global:admin` | Admin access — most resources |
| `global:member` | Standard user — own workflows/credentials |

Endpoints marked **owner only** require the `global:owner` role.

---

## Cursor Pagination

All list endpoints use cursor-based pagination (not offset).

**Request pattern:**

```
GET /api/v1/<resource>?limit=20&cursor=<opaque-string>
```

**Response pattern:**

```json
{
  "data": [ ... ],
  "nextCursor": "opaque-token-or-null"
}
```

**Fetch all pages — n8n Code node:**

```javascript
let allItems = [];
let cursor = undefined;

do {
  const params = new URLSearchParams({ limit: '50' });
  if (cursor) params.set('cursor', cursor);

  const res = await $helpers.httpRequest({
    method: 'GET',
    url: `${$env.N8N_HOST}/api/v1/workflows?${params}`,
    headers: { 'X-N8N-API-KEY': $env.N8N_API_KEY }
  });

  allItems = allItems.concat(res.data);
  cursor = res.nextCursor;
} while (cursor);

return allItems.map(item => ({ json: item }));
```

---

## HTTP Status Codes

| Code | Meaning | Action |
| --- | --- | --- |
| 200 | OK | Success |
| 201 | Created | Resource created |
| 204 | No Content | Success (DELETE / some updates) |
| 400 | Bad Request | Fix request body or params |
| 401 | Unauthorized | Check `X-N8N-API-KEY` header |
| 403 | Forbidden | Check role (owner required?) |
| 404 | Not Found | Check resource ID |
| 409 | Conflict | State conflict (e.g. already active) |
| 500 | Server Error | n8n internal error |

---

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| Using offset pagination | n8n uses cursor — use `nextCursor` from response |
| Missing `Content-Type` header on POST/PUT | Always add `Content-Type: application/json` |
| 403 on user endpoints | Those require `global:owner` role |
| Expecting credential secrets in GET | n8n never returns secrets — use schema endpoint |
| Hardcoding host URL | Use `$env.N8N_HOST` — keeps code portable |

---

## Related Skills

- `n8n-api-workflows` — Workflow CRUD, activate/deactivate
- `n8n-api-executions` — Execution monitoring and control
- `n8n-api-credentials` — Credential management
- `n8n-api-users` — User management (owner only)
- `n8n-api-data-tables` — Structured data storage
- `n8n-api-projects` — Project and member management
- `n8n-api-variables` — Global variables
- `n8n-api-tags` — Tag management
- `n8n-api-audit` — Security audit report
- `n8n-api-source-control` — Git pull
