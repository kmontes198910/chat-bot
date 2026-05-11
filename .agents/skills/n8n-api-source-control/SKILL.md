---
name: n8n-api-source-control
description: Use when syncing n8n workflows from a Git repository via the API, pulling the latest workflow definitions from source control, force-pulling to overwrite local changes, or auto-publishing pulled workflows.
---

# n8n API: Source Control

## Overview

Pull workflow definitions from a connected Git repository into the n8n instance. Requires the Source Control feature to be licensed and configured in n8n settings.
**REQUIRED BACKGROUND:** `n8n-api-core` for authentication.

---

## Endpoints

| Method | Path | Purpose | Access |
| --- | --- | --- | --- |
| POST | `/source-control/pull` | Pull workflows from Git | authenticated |

---

## Quick Start — Pull from Git

```bash
curl -X POST "$N8N_HOST/api/v1/source-control/pull" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"force": false, "autoPublish": false}'
```

```javascript
const result = await $helpers.httpRequest({
  method: 'POST',
  url: `${$env.N8N_HOST}/api/v1/source-control/pull`,
  headers: {
    'X-N8N-API-KEY': $env.N8N_API_KEY,
    'Content-Type': 'application/json'
  },
  body: {
    force: false,
    autoPublish: false
  }
});
return [{ json: result.importResult }];
```

---

## Request Body

| Field | Type | Default | Description |
| --- | --- | --- | --- |
| `force` | boolean | `false` | Overwrite local changes (discard any divergence from Git) |
| `autoPublish` | boolean | `false` | Automatically activate imported workflows |
| `variables` | object | — | Variable overrides to apply after pull |

---

## Operation Modes

### Safe pull (default)

```javascript
// Pull without overwriting local edits
body: { force: false, autoPublish: false }
```

### Force pull (overwrite local)

```javascript
// Discard local changes and sync to Git HEAD
body: { force: true, autoPublish: false }
```

### Pull and activate

```javascript
// Pull and immediately publish all imported workflows
body: { force: false, autoPublish: true }
```

### Pull with variable overrides

```javascript
body: {
  force: true,
  autoPublish: true,
  variables: {
    MY_ENV: 'production',
    API_ENDPOINT: 'https://api.example.com'
  }
}
```

---

## Response

```json
{
  "importResult": {
    "workflows": { "created": [], "updated": [], "skipped": [] },
    "credentials": { "created": [], "updated": [] },
    "variables": { "created": [], "updated": [] }
  }
}
```

---

## Key Rules

- ✅ Source Control must be connected in n8n Settings → Source Control before this endpoint works
- ✅ `force: true` is destructive — local edits not in Git will be lost
- ✅ `autoPublish: true` activates workflows immediately after import
- ❌ Returns `400` if Source Control is not configured
- ❌ There is no push endpoint in the API — push must be done from the n8n UI

---

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| 400 on POST | Source Control not set up — configure in n8n UI Settings first |
| Workflows not activating after pull | Set `autoPublish: true` or activate manually via workflow endpoint |
| Local edits lost unexpectedly | `force: false` should preserve them — check if `force: true` was used |

---

## Related Skills

- `n8n-api-core` — Auth, status codes
- `n8n-api-workflows` — Activate/deactivate workflows after pull
