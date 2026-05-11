---
name: n8n-api-tags
description: Use when managing n8n tags via API — creating tags, listing all tags, fetching a specific tag by ID, updating tag names, or deleting tags. Tags are used to organize and filter workflows.
---

# n8n API: Tags

## Overview

Manage tag definitions used to organize and filter workflows.
**REQUIRED BACKGROUND:** `n8n-api-core` for authentication and pagination.

---

## Endpoints

| Method | Path | Purpose | Access |
| --- | --- | --- | --- |
| GET | `/tags` | List all tags | authenticated |
| POST | `/tags` | Create a tag | authenticated |
| GET | `/tags/{id}` | Get tag by ID | authenticated |
| PUT | `/tags/{id}` | Update tag name | authenticated |
| DELETE | `/tags/{id}` | Delete tag | authenticated |

---

## Quick Start — List All Tags

```bash
curl "$N8N_HOST/api/v1/tags" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"
```

```javascript
const res = await $helpers.httpRequest({
  method: 'GET',
  url: `${$env.N8N_HOST}/api/v1/tags`,
  headers: { 'X-N8N-API-KEY': $env.N8N_API_KEY }
});
return res.data.map(t => ({ json: t }));
```

---

## Common Operations

### Create a Tag

```bash
curl -X POST "$N8N_HOST/api/v1/tags" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "production"}'
```

```javascript
const tag = await $helpers.httpRequest({
  method: 'POST',
  url: `${$env.N8N_HOST}/api/v1/tags`,
  headers: {
    'X-N8N-API-KEY': $env.N8N_API_KEY,
    'Content-Type': 'application/json'
  },
  body: { name: 'production' }
});
// tag.id is used when assigning to workflows
```

### Get Tag by ID

```bash
curl "$N8N_HOST/api/v1/tags/tag-abc123" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"
```

### Rename a Tag

```javascript
await $helpers.httpRequest({
  method: 'PUT',
  url: `${$env.N8N_HOST}/api/v1/tags/tag-abc123`,
  headers: {
    'X-N8N-API-KEY': $env.N8N_API_KEY,
    'Content-Type': 'application/json'
  },
  body: { name: 'prod-stable' }
});
```

### Delete a Tag

```bash
curl -X DELETE "$N8N_HOST/api/v1/tags/tag-abc123" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"
```

Returns the deleted tag object on success.

### Assign Tags to a Workflow

Tags are assigned at the workflow level — see `n8n-api-workflows`:

```javascript
// Assign tags to a workflow (replaces all existing tags)
await $helpers.httpRequest({
  method: 'PUT',
  url: `${$env.N8N_HOST}/api/v1/workflows/wf-abc123/tags`,
  headers: {
    'X-N8N-API-KEY': $env.N8N_API_KEY,
    'Content-Type': 'application/json'
  },
  body: [{ id: 'tag-abc123' }, { id: 'tag-def456' }]
});
```

---

## Query Parameters (List)

| Param | Type | Description |
| --- | --- | --- |
| `limit` | integer | Results per page |
| `cursor` | string | Pagination cursor |

---

## Key Rules

- ✅ Create the tag first, then use its `id` when assigning to workflows
- ✅ Tag names must be unique across the instance
- ❌ Deleting a tag removes it from all workflows that use it
- ❌ Cannot create a tag with a duplicate name

---

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| Assigning tags by name in workflow endpoints | Workflow tag endpoints need tag `id`, not name |
| Expecting PATCH for update | Tags use PUT (full replace of the name field) |
| Deleting a tag without checking workflow usage | Deletion silently removes tag from all workflows |

---

## Related Skills

- `n8n-api-core` — Auth, pagination, status codes
- `n8n-api-workflows` — Assign/read tags on workflows
