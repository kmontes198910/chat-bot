---
name: n8n-api-projects
description: Use when managing n8n projects via API — creating projects, listing projects, updating project names, deleting projects, listing project members, adding users to a project, removing users, or changing a user's project role.
---

# n8n API: Projects

## Overview

Manage n8n projects: logical groupings of workflows and credentials with their own member access control.
**REQUIRED BACKGROUND:** `n8n-api-core` for authentication and pagination.

---

## Endpoints

### Project Operations

| Method | Path | Purpose | Access |
| --- | --- | --- | --- |
| GET | `/projects` | List all projects | authenticated |
| POST | `/projects` | Create a project | authenticated |
| PUT | `/projects/{projectId}` | Rename a project | authenticated |
| DELETE | `/projects/{projectId}` | Delete project | authenticated |

### Project Member Operations

| Method | Path | Purpose | Access |
| --- | --- | --- | --- |
| GET | `/projects/{projectId}/users` | List project members | authenticated |
| POST | `/projects/{projectId}/users` | Add users to project | authenticated |
| PATCH | `/projects/{projectId}/users/{userId}` | Change member's project role | authenticated |
| DELETE | `/projects/{projectId}/users/{userId}` | Remove user from project | authenticated |

---

## Quick Start — List Projects

```bash
curl "$N8N_HOST/api/v1/projects" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"
```

```javascript
const res = await $helpers.httpRequest({
  method: 'GET',
  url: `${$env.N8N_HOST}/api/v1/projects`,
  headers: { 'X-N8N-API-KEY': $env.N8N_API_KEY }
});
return res.data.map(p => ({ json: p }));
```

---

## Common Operations

### Create a Project

```bash
curl -X POST "$N8N_HOST/api/v1/projects" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "Marketing Automations"}'
```

```javascript
const project = await $helpers.httpRequest({
  method: 'POST',
  url: `${$env.N8N_HOST}/api/v1/projects`,
  headers: {
    'X-N8N-API-KEY': $env.N8N_API_KEY,
    'Content-Type': 'application/json'
  },
  body: { name: 'Marketing Automations' }
});
// project.id used in all subsequent project operations
```

### Rename a Project

```javascript
await $helpers.httpRequest({
  method: 'PUT',
  url: `${$env.N8N_HOST}/api/v1/projects/proj-abc123`,
  headers: {
    'X-N8N-API-KEY': $env.N8N_API_KEY,
    'Content-Type': 'application/json'
  },
  body: { name: 'Marketing Automations v2' }
});
```

### Delete a Project

```bash
curl -X DELETE "$N8N_HOST/api/v1/projects/proj-abc123" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"
```

> ⚠️ Deleting a project may affect workflows and credentials scoped to it.

### List Project Members

```javascript
const members = await $helpers.httpRequest({
  method: 'GET',
  url: `${$env.N8N_HOST}/api/v1/projects/proj-abc123/users`,
  headers: { 'X-N8N-API-KEY': $env.N8N_API_KEY }
});
return members.data.map(m => ({ json: m }));
```

### Add Users to a Project

```javascript
// Add multiple users in one call with their project roles
await $helpers.httpRequest({
  method: 'POST',
  url: `${$env.N8N_HOST}/api/v1/projects/proj-abc123/users`,
  headers: {
    'X-N8N-API-KEY': $env.N8N_API_KEY,
    'Content-Type': 'application/json'
  },
  body: {
    relations: [
      { userId: 'user-111', role: 'project:editor' },
      { userId: 'user-222', role: 'project:viewer' }
    ]
  }
});
```

### Change a Member's Project Role

```javascript
await $helpers.httpRequest({
  method: 'PATCH',
  url: `${$env.N8N_HOST}/api/v1/projects/proj-abc123/users/user-111`,
  headers: {
    'X-N8N-API-KEY': $env.N8N_API_KEY,
    'Content-Type': 'application/json'
  },
  body: { role: 'project:admin' }
});
```

### Remove a User from a Project

```bash
curl -X DELETE "$N8N_HOST/api/v1/projects/proj-abc123/users/user-111" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"
```

---

## Project Roles Reference

| Role | Permissions within project |
| --- | --- |
| `project:admin` | Full control of project resources |
| `project:editor` | Create/edit workflows and credentials |
| `project:viewer` | Read-only access |

> Note: Project roles are independent from global roles. A `global:member` can be a `project:admin` within a specific project.

---

## Query Parameters

| Endpoint | Param | Type | Description |
| --- | --- | --- | --- |
| GET /projects | `limit` | integer | Results per page |
| GET /projects | `cursor` | string | Pagination cursor |
| GET /projects/{id}/users | `limit` | integer | Members per page |
| GET /projects/{id}/users | `cursor` | string | Pagination cursor |

---

## Key Rules

- ✅ `relations` in POST /users is always an array — even for a single user
- ✅ Project roles (`project:admin`) are separate from global roles (`global:owner`)
- ✅ A user must exist in n8n before being added to a project
- ❌ Deleting a project does not automatically delete its workflows — verify impact first
- ❌ Cannot change the built-in "Personal" project

---

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| Sending single object in `relations` | Always use array: `[{userId, role}]` |
| Confusing global roles with project roles | Global: `global:admin` / Project: `project:editor` |
| 404 when adding user | User must exist first — create via `n8n-api-users` |
| Deleting project without migrating workflows | Transfer workflows first via `PUT /workflows/{id}/transfer` |

---

## Related Skills

- `n8n-api-core` — Auth, pagination, status codes
- `n8n-api-users` — Manage user accounts
- `n8n-api-workflows` — Transfer workflows to/from projects
- `n8n-api-credentials` — Transfer credentials to/from projects
- `n8n-api-variables` — Scope variables to projects
