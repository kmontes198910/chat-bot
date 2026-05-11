---
name: n8n-api-users
description: Use when managing n8n users via API — listing users, creating user accounts, fetching user by ID or email, deleting users, or changing a user's global role. All write operations require global:owner role.
---

# n8n API: Users

## Overview

Manage n8n user accounts. Most write operations are restricted to `global:owner`.
**REQUIRED BACKGROUND:** `n8n-api-core` for authentication and pagination.

---

## Endpoints

| Method | Path | Purpose | Access |
| --- | --- | --- | --- |
| GET | `/users` | List all users | owner only |
| POST | `/users` | Create one or more users | owner only |
| GET | `/users/{id}` | Get user by ID or email | authenticated |
| DELETE | `/users/{id}` | Delete user | owner only |
| PATCH | `/users/{id}/role` | Change user's global role | owner only |

---

## Quick Start — List Users

```bash
curl -X GET "$N8N_HOST/api/v1/users" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"
```

```javascript
// n8n Code node
const res = await $helpers.httpRequest({
  method: 'GET',
  url: `${$env.N8N_HOST}/api/v1/users`,
  headers: { 'X-N8N-API-KEY': $env.N8N_API_KEY }
});
return res.data.map(u => ({ json: u }));
```

---

## Common Operations

### Create a User

```bash
curl -X POST "$N8N_HOST/api/v1/users" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d '[{"email": "alice@example.com", "role": "global:member"}]'
```

```javascript
const res = await $helpers.httpRequest({
  method: 'POST',
  url: `${$env.N8N_HOST}/api/v1/users`,
  headers: {
    'X-N8N-API-KEY': $env.N8N_API_KEY,
    'Content-Type': 'application/json'
  },
  body: [{ email: 'alice@example.com', role: 'global:member' }]
});
```

Body accepts an **array** — create multiple users in one call.

### Get User by ID or Email

```bash
# By ID
curl "$N8N_HOST/api/v1/users/abc123" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"

# By email (pass email as the {id} parameter)
curl "$N8N_HOST/api/v1/users/alice@example.com" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"
```

### Delete a User

```bash
curl -X DELETE "$N8N_HOST/api/v1/users/abc123" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"
```

Returns `204 No Content` on success.

### Change Global Role

```bash
curl -X PATCH "$N8N_HOST/api/v1/users/abc123/role" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"newRoleName": "global:admin"}'
```

```javascript
await $helpers.httpRequest({
  method: 'PATCH',
  url: `${$env.N8N_HOST}/api/v1/users/abc123/role`,
  headers: {
    'X-N8N-API-KEY': $env.N8N_API_KEY,
    'Content-Type': 'application/json'
  },
  body: { newRoleName: 'global:admin' }
});
```

---

## Query Parameters (List)

| Param | Type | Description |
| --- | --- | --- |
| `limit` | integer | Results per page |
| `cursor` | string | Pagination cursor from previous response |
| `includeRole` | boolean | Include role field in response |
| `projectId` | string | Filter users by project membership |

---

## Global Roles Reference

| Role | Level |
| --- | --- |
| `global:owner` | Full instance control |
| `global:admin` | Administrative access |
| `global:member` | Standard user |

---

## Key Rules

- ✅ POST body is an **array** even when creating a single user
- ✅ `{id}` accepts both the user UUID and their email address
- ❌ Non-owner roles get `403` on list/create/delete/role-change
- ❌ Cannot delete yourself (the authenticated owner)

---

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| Sending single object in POST body | Wrap in array: `[{ email, role }]` |
| 403 on GET /users | Requires `global:owner` — not available to members |
| Passing email with `+` signs in URL | URL-encode the email or use user UUID |

---

## Related Skills

- `n8n-api-core` — Auth, pagination, status codes
- `n8n-api-projects` — Assign users to projects with project-level roles
