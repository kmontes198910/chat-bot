# n8n-MCP Chatbot Project

[![Docker](https://img.shields.io/badge/Docker-Ready-blue)](https://www.docker.com/)
[![n8n](https://img.shields.io/badge/n8n-Cloud-orange)](https://n8n.kynsoft.net)
[![MCP](https://img.shields.io/badge/MCP-Enabled-green)](https://modelcontextprotocol.io/)

A Model Context Protocol (MCP) server that enables AI assistants (Claude Code, GitHub Copilot) to manage n8n workflows through natural language.

## Architecture

```
AI Assistant (Claude Code / VS Code + Copilot)
      ↓ (HTTP - direct)
n8n-mcp Server (Docker:3002)
      ↓ (HTTPS - REST API)
n8n Dev Instance (n8n-dev.kynsoft.work)
```

Both clients connect directly to the Docker container over HTTP — no bridge script needed.

## Quick Start

### Prerequisites

- Docker & Docker Compose
- Node.js 16+
- Claude Code or VS Code with GitHub Copilot

### Setup

1. **Clone the repo and configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env — set N8N_API_KEY and MCP_AUTH_TOKEN
   ```

2. **Start the MCP server:**
   ```bash
   docker-compose up -d
   ```

3. **Verify health:**
   ```bash
   curl http://localhost:3002/health | jq
   ```

### MCP Configuration

**Claude Code** — `~/.config/claude-mcp/config.json`:
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

**VS Code / GitHub Copilot** — workspace config already in `.vscode/mcp.json`:
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

Both connect directly to the Docker container — no bridge script required.

## Project Structure

```
n8n-chatbot/
├── docker-compose.yml          # n8n-mcp Docker config (port 3002)
├── .env                        # Credentials (not in git)
├── .env.example                # Environment template
├── n8n-workflow.sh             # Utility script for workflow ops
├── .vscode/
│   └── mcp.json                # VS Code MCP configuration
├── .agents/
│   └── skills/
│       └── n8n-mcp-tools-expert/  # MCP tools skill (SKILL.md + guides)
├── workflows/
│   └── n8n_kynsoft_keimer_m/   # Version-controlled workflow JSONs
├── AGENTS.md                   # AI agent role and research protocol
└── CLAUDE.md                   # Claude Code working guidelines
```

## Active Workflows (n8n.kynsoft.net)

| Workflow | Nodes | Description |
|----------|-------|-------------|
| Agente IA MultiModal para WhatsApp, Buffer y RAG | 56 | WhatsApp AI agent with RAG, LangChain, Supabase vector store |
| Chatbot-kynsoft | 15 | OpenAI + Google Gemini routing |
| Scrap info from any Website | 14 | Web scraping via Firecrawl |

## MCP Tools Available

**Node Discovery:**
- `search_nodes` — Find nodes by keyword
- `get_node` — Get node schema and operations

**Validation:**
- `validate_node` — Validate node config before deployment
- `validate_workflow` — Full workflow structure check

**Workflow Management:**
- `n8n_list_workflows`, `n8n_get_workflow`
- `n8n_create_workflow`
- `n8n_update_partial_workflow` — Incremental updates (preferred)
- `n8n_delete_workflow`, `n8n_test_workflow`

**Templates:**
- `search_templates` — Search 2,700+ templates
- `get_template`, `n8n_deploy_template`

**Credentials & Security:**
- `n8n_manage_credentials` — CRUD + schema discovery
- `n8n_audit_instance` — Security audit (built-in + custom deep scan)

**Other:**
- `n8n_executions`, `n8n_workflow_versions`, `n8n_manage_datatable`

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `N8N_API_URL` | n8n instance URL | `https://n8n.kynsoft.net` |
| `N8N_API_KEY` | n8n API key | *(required)* |
| `MCP_AUTH_TOKEN` | MCP server auth token | *(required)* |
| `MCP_MODE` | Server mode | `http` |
| `MCP_PORT` | Server port | `3002` |
| `LOG_LEVEL` | Logging verbosity | `error` |
| `N8N_MCP_TELEMETRY_DISABLED` | Disable telemetry | `true` |

## Docker Commands

```bash
docker-compose up -d            # Start server
docker-compose down             # Stop server
docker-compose logs -f n8n-mcp  # Stream logs
docker-compose restart n8n-mcp  # Restart after config changes
curl http://localhost:3002/health | jq  # Health check
```

## Troubleshooting

**Server won't start:**
```bash
lsof -i :3002        # Check port availability
docker ps            # Verify Docker is running
docker-compose logs n8n-mcp
```

**Auth errors:**
1. Verify `MCP_AUTH_TOKEN` matches in `.env` and MCP config
2. Check `N8N_API_KEY` is valid: `curl https://n8n.kynsoft.net`

**Claude Code can't see tools:**
1. Verify absolute path in `~/.config/claude-mcp/config.json` points to `mcp-http-client.cjs`
2. Restart the Claude Code session after config changes

**VS Code / Copilot can't connect:**
1. Reload window: `Ctrl+Shift+P` → "Developer: Reload Window"
2. Verify `.vscode/mcp.json` exists and the server is running

## Security

- Never commit `.env` to version control
- Use a cryptographically random `MCP_AUTH_TOKEN`
- MCP server binds to localhost only by default
- Container runs as non-root (`nodejs` user)
- Telemetry disabled via `N8N_MCP_TELEMETRY_DISABLED=true`

## References

- [n8n-mcp](https://github.com/czlonkowski/n8n-mcp) — MCP server implementation
- [n8n Documentation](https://docs.n8n.io/)
- [Model Context Protocol](https://modelcontextprotocol.io/)

---

*Last updated: May 2026*
