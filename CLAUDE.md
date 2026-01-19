# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Working Guidelines

### File Modification Policy
- **ALWAYS modify files in place** - Do NOT create "enhanced", "new", or "v2" versions
- **Edit the original file** - Use the Edit tool to update existing files directly
- **No summary documents** - Do NOT create summary files (like "SUMMARY.md", "CHANGES.md") unless explicitly requested
- **No duplicate files** - Avoid creating backup or alternative versions

**Example:**
- ❌ Bad: Create `workflow-enhanced.json` when modifying `workflow.json`
- ✅ Good: Edit `workflow.json` directly with improvements
- ❌ Bad: Create `ENHANCEMENT_SUMMARY.md` after making changes
- ✅ Good: Report changes directly in conversation

### When to Create New Files
Only create new files when:
- User explicitly requests a new file
- Adding genuinely new functionality (not modifications)
- Creating required configuration files (.gitignore, etc.)

### n8n Workflow Management Policy
- **ALWAYS use n8n-mcp MCP tools** - Never use curl or direct API calls for n8n operations
- **Use the MCP server** - Interact with n8n through the n8n-mcp Docker container
- **Prefer MCP tools** - Use `n8n_update_partial_workflow`, `n8n_get_workflow`, etc. instead of REST API
- **NO direct curl** - Do not bypass the MCP layer with curl commands

**Example:**
- ❌ Bad: `curl -X PUT "https://n8n.kynsoft.net/api/v1/workflows/{id}"` with manual API calls
- ✅ Good: Use MCP tools like `n8n_update_partial_workflow` or `n8n_get_workflow`
- ❌ Bad: Writing custom Node.js scripts to call n8n API
- ✅ Good: Let the n8n-mcp server handle all n8n communication

## Project Overview

This is an n8n-MCP integration project that bridges AI assistants (Claude Code, GitHub Copilot) with n8n workflow automation platform through the Model Context Protocol (MCP). The architecture enables natural language interaction with n8n workflows hosted at n8n.kynsoft.net.

## Architecture

### Three-Layer Communication Bridge

```
AI Assistant (Claude Code / VS Code)
      ↓ (stdio - JSON-RPC 2.0)
mcp-http-client.cjs
      ↓ (HTTP + SSE - Server-Sent Events)
n8n-mcp Server (Docker:3000)
      ↓ (HTTPS - REST API)
n8n Cloud Instance (n8n.kynsoft.net)
```

**Critical Components:**

1. **mcp-http-client.cjs** - stdio-to-HTTP bridge
   - Reads JSON-RPC messages from stdin (from AI assistants)
   - Converts to HTTP POST requests with SSE handling
   - Manages session state via `Mcp-Session-Id` headers
   - Parses SSE format responses (`event: message\ndata: {...}`)
   - Writes JSON responses to stdout

2. **n8n-mcp Server** - Docker container
   - Exposes 21 MCP tools for n8n interaction
   - Runs in HTTP mode on port 3000
   - Uses SQLite persistence in `/app/data`
   - Health endpoint: `GET http://localhost:3000/health`

3. **n8n Cloud Instance**
   - Production workflows at n8n.kynsoft.net
   - Currently has 3 active workflows with 32 unique node types
   - Accessed via REST API with `X-N8N-API-KEY` header

## MCP Configuration

### For Claude Code
MCP servers are configured in `~/.config/claude-mcp/config.json`:

```json
{
  "mcpServers": {
    "n8n-mcp": {
      "command": "node",
      "args": ["/absolute/path/to/mcp-http-client.cjs"],
      "env": {
        "MCP_AUTH_TOKEN": "your-token-here"
      }
    }
  }
}
```

### For VS Code/Copilot
Workspace-specific config in `.vscode/mcp.json` uses `${workspaceFolder}` variable.

## Essential Commands

### Docker Container Management
```bash
# Start MCP server
docker-compose up -d

# Stop MCP server
docker-compose down

# View real-time logs
docker-compose logs -f n8n-mcp

# Restart after config changes
docker-compose restart n8n-mcp

# Check container health
curl http://localhost:3000/health | jq
```

### Testing MCP Connection
```bash
# Test mcp-http-client.cjs directly
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | \
MCP_AUTH_TOKEN=your-token-here node mcp-http-client.cjs

# List available MCP tools
(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'; \
sleep 1; \
echo '{"jsonrpc":"2.0","id":2,"method":"tools/list"}') | \
MCP_AUTH_TOKEN=your-token-here node mcp-http-client.cjs
```

### n8n API Direct Access
```bash
# List workflows
curl -X GET "https://n8n.kynsoft.net/api/v1/workflows" \
  -H "X-N8N-API-KEY: your-api-key"

# Get workflow details
curl -X GET "https://n8n.kynsoft.net/api/v1/workflows/{id}" \
  -H "X-N8N-API-KEY: your-api-key"

# Execute workflow
curl -X POST "https://n8n.kynsoft.net/api/v1/workflows/{id}/execute" \
  -H "X-N8N-API-KEY: your-api-key"
```

## Environment Configuration

Required variables in `.env` (never commit this file):

| Variable | Purpose | Example |
|----------|---------|---------|
| `N8N_API_URL` | n8n instance endpoint | `https://n8n.kynsoft.net` |
| `N8N_API_KEY` | n8n API authentication | JWT token from n8n |
| `MCP_AUTH_TOKEN` | MCP server authentication | Secure random token |
| `MCP_MODE` | Server operation mode | `http` (default) |
| `MCP_PORT` | HTTP server port | `3000` (default) |
| `LOG_LEVEL` | Logging verbosity | `error` (default) |
| `N8N_MCP_TELEMETRY_DISABLED` | Disable telemetry | `true` |

Copy `.env.example` to `.env` and fill in actual credentials.

## Available n8n Workflows

### 1. Agente IA MultiModal para WhatsAp, Buffer y RAG (56 nodes)
- Multi-modal AI agent for WhatsApp
- Implements RAG (Retrieval Augmented Generation)
- LangChain integration with OpenAI embeddings
- Supabase vector store for document retrieval

### 2. Chatbot-kynsoft (15 nodes)
- Main chatbot automation
- OpenAI + Google Gemini integration
- Multi-model AI routing

### 3. Scrap info from any Website (14 nodes)
- Web scraping using Firecrawl custom node
- Data extraction and processing

## Node Types Available (32 total)

**LangChain AI (12):** agent, chainLlm, chatTrigger, documentDefaultDataLoader, embeddingsOpenAi, googleGemini, lmChatOpenAi, memoryBufferWindow, memoryPostgresChat, openAi, textSplitterRecursiveCharacterTextSplitter, vectorStoreSupabase

**Core n8n (19):** aggregate, code, extractFromFile, filter, formTrigger, googleDrive, googleDriveTrigger, httpRequest, httpRequestTool, if, noOp, redis, set, splitOut, stickyNote, switch, wait, whatsApp, whatsAppTrigger

**Custom (1):** @mendable/n8n-nodes-preview-firecrawl.firecrawl

## MCP Tools Reference

When using n8n MCP tools (available after configuring MCP), prefer these for workflow operations:

**Node Discovery:**
- `search_nodes` - Search by keyword (e.g., "webhook", "slack")
- `get_node` - Get detailed node information with multiple detail levels

**Validation:**
- `validate_node` - Validate node configuration before deployment
- `validate_workflow` - Full workflow validation (structure, connections, expressions)

**Workflow Management:**
- `n8n_list_workflows` - List all workflows
- `n8n_get_workflow` - Get workflow by ID
- `n8n_create_workflow` - Create new workflow
- `n8n_update_partial_workflow` - Incremental workflow updates (preferred over full update)
- `n8n_delete_workflow` - Delete workflow

**Templates:**
- `search_templates` - Search 2,700+ workflow templates
- `get_template` - Get template by ID
- `n8n_deploy_template` - Deploy template directly to n8n instance

**Execution:**
- `n8n_test_workflow` - Test/trigger workflow execution
- `n8n_executions` - Manage workflow executions

**Version Control:**
- `n8n_workflow_versions` - Manage version history and rollback

## Troubleshooting

### MCP Server Won't Start
```bash
# Check port availability
lsof -i :3000

# Verify Docker is running
docker ps

# Check logs for errors
docker-compose logs n8n-mcp
```

### Authentication Errors
1. Verify `MCP_AUTH_TOKEN` matches in `.env` and MCP config
2. Check `N8N_API_KEY` is valid (test with curl)
3. Ensure n8n instance is accessible: `curl https://n8n.kynsoft.net`

### No Sessions Showing in Health Check
- Sessions are created on-demand when AI assistants connect
- 0 sessions is normal if no active connections
- After first use, check: `curl http://localhost:3000/health | jq '.sessions'`

### Claude Code Can't Access MCP Tools
1. Verify MCP config exists: `cat ~/.config/claude-mcp/config.json`
2. Ensure absolute path to `mcp-http-client.cjs` is correct
3. Restart Claude Code session after config changes
4. Test mcp-http-client.cjs manually with echo command above

## Security Considerations

- **Never commit `.env`** - Contains API keys and tokens
- **Use strong tokens** - MCP_AUTH_TOKEN should be cryptographically random
- **localhost only** - MCP server binds to localhost:3000 by default
- **Container user** - Runs as nodejs user (non-root)
- **Telemetry disabled** - Set `N8N_MCP_TELEMETRY_DISABLED=true`

## Working with Workflows

When creating or modifying workflows:

1. **Use validation first** - Always validate node configs before creating workflows
2. **Incremental updates** - Use `n8n_update_partial_workflow` for changes, not full replacements
3. **Check templates** - Search templates before building from scratch
4. **Test locally** - Use `n8n_test_workflow` before activating in production
5. **Version control** - n8n has built-in versioning, use `n8n_workflow_versions` to rollback if needed

## Development Workflow

1. Ensure MCP server is running: `docker-compose up -d`
2. Verify health: `curl http://localhost:3000/health`
3. Use MCP tools through Claude Code or test with mcp-http-client.cjs
4. Check logs if issues arise: `docker-compose logs -f n8n-mcp`
5. Restart container after environment changes: `docker-compose restart n8n-mcp`
