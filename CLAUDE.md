# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Working Guidelines

### File Modification Policy
- **ALWAYS modify files in place** - Do NOT create "enhanced", "new", or "v2" versions
- **Edit the original file** - Use the Edit tool to update existing files directly
- **No summary documents** - Do NOT create summary files unless explicitly requested
- **No duplicate files** - Avoid creating backup or alternative versions

### n8n Workflow Management Policy
- **ALWAYS use n8n-mcp MCP tools** - Never use curl or direct API calls for n8n operations
- **Use the MCP server** - Interact with n8n through the n8n-mcp Docker container on `localhost:3002`
- **Prefer incremental updates** - Use `n8n_update_partial_workflow` over full replacements
- **NO direct curl** - Do not bypass the MCP layer with curl commands

## Skills

The `n8n-mcp-tools-expert` skill is installed and **must be loaded before any n8n work**:

```
.agents/skills/n8n-mcp-tools-expert/SKILL.md
```

This skill covers node discovery, validation, workflow management, credentials, templates, and security audits.

## Project Overview

This is an n8n-MCP integration project that bridges AI assistants (Claude Code, GitHub Copilot) with the n8n workflow automation platform through the Model Context Protocol (MCP). The architecture enables natural language interaction with n8n workflows hosted at `n8n.kynsoft.net`.

## Architecture

```
AI Assistant (Claude Code / VS Code + Copilot)
      ↓ (HTTP - direct)
n8n-mcp Server (Docker:3002)
      ↓ (HTTPS - REST API)
n8n Dev Instance (n8n-dev.kynsoft.work)
```

**Components:**

1. **n8n-mcp Server** - Docker container (`ghcr.io/czlonkowski/n8n-mcp:latest`)
   - Exposes MCP tools for n8n interaction
   - Runs in HTTP mode, exposed on host port 3002
   - Health endpoint: `GET http://localhost:3002/health`
   - MCP endpoint: `http://localhost:3002/mcp`

2. **n8n Dev Instance** - `https://n8n-dev.kynsoft.work`
   - Accessed via REST API with `X-N8N-API-KEY` header

## MCP Configuration

### For Claude Code
`~/.config/claude-mcp/config.json`:

```json
{
  "mcpServers": {
    "n8n-mcp": {
      "url": "http://localhost:3002/mcp",
      "headers": {
        "Authorization": "Bearer n8n-mcp-secure-token-2026"
      }
    }
  }
}
```

### For VS Code / Copilot
`.vscode/mcp.json` (already configured):

```json
{
  "servers": {
    "n8n-mcp": {
      "type": "http",
      "url": "http://localhost:3002/mcp",
      "headers": {
        "Authorization": "Bearer n8n-mcp-secure-token-2026"
      }
    }
  }
}
```

## Essential Commands

```bash
# Start MCP server
docker-compose up -d

# Stop MCP server
docker-compose down

# View real-time logs
docker-compose logs -f n8n-mcp

# Check container health
curl http://localhost:3002/health | jq
```

## Environment Configuration

Required variables in `.env` (never commit):

| Variable | Purpose |
|----------|---------|
| `N8N_API_URL` | n8n instance endpoint (`https://n8n.kynsoft.net`) |
| `N8N_API_KEY` | n8n API authentication |
| `MCP_AUTH_TOKEN` | MCP server authentication |
| `MCP_MODE` | Server operation mode (`http`) |
| `MCP_PORT` | HTTP server port (`3002`) |
| `LOG_LEVEL` | Logging verbosity (`error`) |
| `N8N_MCP_TELEMETRY_DISABLED` | Disable telemetry (`true`) |

## Available n8n Workflows

1. **Agente IA MultiModal para WhatsApp, Buffer y RAG** (56 nodes)
   - Multi-modal AI agent with RAG, LangChain, OpenAI embeddings, Supabase vector store

2. **Chatbot-kynsoft** (15 nodes)
   - OpenAI + Google Gemini integration

3. **Scrap info from any Website** (14 nodes)
   - Web scraping via Firecrawl custom node

## MCP Tools Reference

**Node Discovery:**
- `search_nodes` — Search by keyword
- `get_node` — Get node details (use `detail: "standard"` by default)

**Validation:**
- `validate_node` — Validate node config (use `profile: "runtime"`)
- `validate_workflow` — Full workflow validation

**Workflow Management:**
- `n8n_list_workflows`, `n8n_get_workflow`, `n8n_create_workflow`
- `n8n_update_partial_workflow` — Incremental updates (preferred)
- `n8n_delete_workflow`, `n8n_test_workflow`

**Templates:**
- `search_templates`, `get_template`, `n8n_deploy_template`

**Credentials & Security:**
- `n8n_manage_credentials` — CRUD + schema discovery
- `n8n_audit_instance` — Security audit

**Other:**
- `n8n_executions`, `n8n_workflow_versions`, `n8n_manage_datatable`

## nodeType Format Rules

| Context | Format |
|---------|--------|
| `search_nodes`, `get_node`, `validate_node` | `nodes-base.slack` |
| `n8n_create_workflow`, `n8n_update_partial_workflow` | `n8n-nodes-base.slack` |

## Troubleshooting

```bash
# Port conflict
lsof -i :3002

# Auth failure — check tokens match in .env and MCP config
curl https://n8n.kynsoft.net  # verify n8n reachable

# Claude Code can't access MCP
cat ~/.config/claude-mcp/config.json  # verify path to mcp-http-client.cjs
```
