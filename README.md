# n8n-MCP Chatbot Project

[![Docker](https://img.shields.io/badge/Docker-Ready-blue)](https://www.docker.com/)
[![n8n](https://img.shields.io/badge/n8n-Cloud-orange)](https://n8n.kynsoft.net)
[![MCP](https://img.shields.io/badge/MCP-Enabled-green)](https://modelcontextprotocol.io/)

A Model Context Protocol (MCP) server implementation that enables AI assistants like GitHub Copilot to interact with n8n workflow automation platform through natural language.

## 🎯 Project Overview

This project bridges the gap between AI assistants (GitHub Copilot, Claude) and n8n workflows by providing an MCP server that:

- **Exposes n8n API** through MCP protocol
- **Manages workflows** via natural language commands
- **Enables AI-powered automation** development
- **Provides workflow templates** and node discovery

### Architecture

```
VS Code/GitHub Copilot
      ↓ (stdio - JSON-RPC 2.0)
mcp-http-client.cjs
      ↓ (HTTP + SSE - Server-Sent Events)
n8n-mcp Server (Docker:3000)
      ↓ (HTTPS - REST API)
n8n Cloud Instance (n8n.kynsoft.net)
```

**mcp-http-client.cjs** acts as a bridge:
- **Input**: Receives JSON-RPC messages from VS Code via stdin
- **Output**: Sends responses back via stdout
- **Transport**: Converts stdio ↔ HTTP with Server-Sent Events (SSE)
- **Session Management**: Maintains MCP session IDs across requests

## �️ Workflow Management

### ⚡ Quick Commands (Recommended)

Use the provided script for efficient workflow management:

```bash
# List all workflows
./n8n-workflow.sh list

# Get workflow details
./n8n-workflow.sh get <workflow_id>

# Update workflow from JSON file
./n8n-workflow.sh update <workflow_id> <file.json>

# Validate workflow JSON
./n8n-workflow.sh validate <file.json>

# Check MCP server health
./n8n-workflow.sh health
```

### 🔄 Best Practices

**✅ DO:**
- Use MCP tools for direct server interaction
- Validate JSON before updating workflows
- Keep local copies as backup
- Use the management script for common operations

**❌ DON'T:**
- Manually edit JSON files when MCP server is available
- Forget to validate changes
- Update workflows without testing

### 📝 Example Workflow Update

```bash
# 1. Get current workflow
./n8n-workflow.sh get E5pYhC0Z0YlUgiWT > current-workflow.json

# 2. Edit the workflow (manually or programmatically)
# ... make your changes ...

# 3. Validate the JSON
./n8n-workflow.sh validate current-workflow.json

# 4. Update on server
./n8n-workflow.sh update E5pYhC0Z0YlUgiWT current-workflow.json
```

### 🔧 MCP Tools Available

When MCP server is running, use these tools directly:

- **List Workflows**: `mcp_n8n-mcp_n8n_list_workflows`
- **Get Workflow**: `mcp_n8n-mcp_n8n_get_workflow`
- **Update Workflow**: `mcp_n8n-mcp_n8n_update_full_workflow`
- **Partial Update**: `mcp_n8n-mcp_n8n_update_partial_workflow`
- **Validate**: `mcp_n8n-mcp_validate_workflow`
- **Create**: `mcp_n8n-mcp_n8n_create_workflow`
- **Delete**: `mcp_n8n-mcp_n8n_delete_workflow`

## �📊 Current Workflows

The project contains **3 active workflows** with **32 unique node types**:

1. **Agente IA MultiModal para WhatsAp, Buffer y RAG** (56 nodes)
   - Multi-modal AI agent for WhatsApp
   - Implements RAG (Retrieval Augmented Generation)
   - LangChain integration

2. **Chatbot-kynsoft** (15 nodes)
   - Main chatbot automation
   - OpenAI + Google Gemini integration

3. **Scrap info from any Website** (14 nodes)
   - Web scraping using Firecrawl
   - Data extraction and processing

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Node.js 16+ (for MCP client)
- VS Code with GitHub Copilot extension
- Access to n8n instance (Cloud or self-hosted)

### Installation

1. **Clone and navigate to project**:
   ```bash
   git clone <repository-url>
   cd n8n-chatbot
   ```

2. **Configure environment**:
   ```bash
   cp .env.example .env
   ```

   Edit `.env` and set:
   - `N8N_API_KEY`: Your n8n API key
   - `MCP_AUTH_TOKEN`: Secure token for MCP authentication

3. **Start the MCP server**:
   ```bash
   docker-compose up -d
   ```

4. **Verify server health**:
   ```bash
   curl http://localhost:3000/health
   ```

### VS Code Configuration

This project includes a workspace-specific MCP configuration in `.vscode/mcp.json`.

**No additional setup needed!** Just:
1. Open this project folder in VS Code
2. Reload the window (Ctrl+Shift+P → "Developer: Reload Window")
3. Start using n8n-mcp with Copilot!

<details>
<summary>Optional: Use globally across all VS Code projects</summary>

Add to `~/.config/Code/User/mcp.json`:

```json
{
  "servers": {
    "n8n-mcp": {
      "command": "node",
      "args": ["/absolute/path/to/n8n-chatbot/helper/mcp-http-client.cjs"],
      "env": {
        "MCP_AUTH_TOKEN": "n8n-mcp-secure-token-2026"
      }
    }
  }
}
```

</details>

## 📖 Usage

### With GitHub Copilot

Once configured, interact with n8n using natural language in Copilot Chat:

```
"List all n8n workflows"
"Show me nodes in the chatbot workflow"
"Create a new workflow with Slack integration"
"Search for webhook nodes"
```

### Direct API Access

You can also use the n8n API directly:

```bash
# List workflows
curl -X GET "https://n8n.kynsoft.net/api/v1/workflows" \
  -H "X-N8N-API-KEY: your-api-key"

# Execute workflow
curl -X POST "https://n8n.kynsoft.net/api/v1/workflows/{id}/execute" \
  -H "X-N8N-API-KEY: your-api-key"
```

## 🛠️ Available n8n Nodes

### LangChain AI Nodes (12)
- AI Agent, LLM Chain, Chat Trigger
- Document Loader, Text Splitter
- OpenAI Embeddings, Google Gemini
- Memory: Buffer Window, PostgreSQL Chat
- Vector Store: Supabase

### Core n8n Nodes (19)
- Data: Aggregate, Filter, Set, Split Out
- Logic: If, Switch, Wait
- Integration: HTTP Request, Google Drive, Redis
- Communication: WhatsApp, Form Trigger
- Development: Code (JS/Python), Extract from File

### Custom Nodes (1)
- Firecrawl (Advanced web scraping)

## 📂 Project Structure

```
n8n-chatbot/
├── .env                        # Environment variables (not in git)
├── .env.example                # Environment template
├── docker-compose.yml          # MCP server container config
├── mcp-http-client.cjs         # stdio ↔ HTTP bridge for VS Code
├── .vscode/
│   └── mcp.json                # Workspace MCP configuration
├── .github/
│   └── copilot-instructions.md # GitHub Copilot context
├── automation/
│   └── chatbot-kynsoft-workflow.json  # Exported workflow
└── README.md                   # This file
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `N8N_API_URL` | n8n instance URL | `https://n8n.kynsoft.net` |
| `N8N_API_KEY` | n8n API authentication key | *(required)* |
| `MCP_AUTH_TOKEN` | MCP server authentication | *(required)* |
| `MCP_MODE` | Server mode (http/stdio) | `http` |
| `MCP_PORT` | Server port | `3000` |
| `LOG_LEVEL` | Logging verbosity | `error` |
| `N8N_MCP_TELEMETRY_DISABLED` | Disable telemetry | `true` |

### MCP Server Endpoints

- **Health Check**: `GET http://localhost:3000/health`
  - Returns server status, uptime, sessions

- **MCP Protocol**: `POST http://localhost:3000/mcp`
  - JSON-RPC 2.0 endpoint
  - Requires session management

## 💻 Common Commands

### Docker Management

```bash
# Start server
docker-compose up -d

# Stop server
docker-compose down

# View logs
docker-compose logs -f n8n-mcp

# Restart server
docker-compose restart n8n-mcp

# Access container shell
docker exec -it n8n-mcp sh
```

### Server Monitoring

```bash
# Check health
curl http://localhost:3000/health | jq

# View sessions
curl http://localhost:3000/health | jq '.sessions'

# Monitor logs
docker logs n8n-mcp --tail 50 -f
```

## 🐛 Troubleshooting

### MCP Server Won't Start

1. Check if port 3000 is available: `lsof -i :3000`
2. Verify Docker is running: `docker ps`
3. Check logs: `docker-compose logs n8n-mcp`

### Authentication Errors

1. Verify `MCP_AUTH_TOKEN` matches in `.env` and `mcp.json`
2. Check `N8N_API_KEY` is valid and not expired
3. Ensure n8n instance is accessible

### Copilot Can't Connect

1. Reload VS Code window (`Cmd/Ctrl + Shift + P` → "Reload Window")
2. Check server health: `curl http://localhost:3000/health`
3. Verify `.vscode/mcp.json` configuration exists
4. Test the script manually:
   ```bash
   echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | MCP_AUTH_TOKEN=n8n-mcp-secure-token-2026 node mcp-http-client.cjs
   ```
5. Check VS Code Output panel: View → Output → "GitHub Copilot Chat"

### No Sessions Showing

- The MCP server creates sessions on-demand when Copilot connects
- 0 sessions means no active connection yet
- After first use, you should see session activity in health check

## 🔒 Security

- **Never commit** `.env` file to version control
- Use **strong, unique tokens** for `MCP_AUTH_TOKEN`
- **Rotate API keys** regularly
- MCP server is exposed on **localhost only** by default
- Container runs with **nodejs user** (non-root)

## 📚 Documentation

- [n8n Documentation](https://docs.n8n.io/)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [n8n API Reference](https://docs.n8n.io/api/)
- [GitHub Copilot MCP](https://github.com/features/copilot)

## 🤝 Contributing

1. Test changes locally with `docker-compose up -d`
2. Update documentation if adding features
3. Keep sensitive data in `.env` only
4. Follow existing code patterns
5. Document new workflows and nodes

## 📄 License

*Add your license information here*

## 🙏 Acknowledgments

- [n8n-mcp](https://github.com/czlonkowski/n8n-mcp) - MCP server implementation
- [Model Context Protocol](https://modelcontextprotocol.io/) - Protocol specification
- [n8n](https://n8n.io/) - Workflow automation platform

## 🔧 MCP Client Script

The `mcp-http-client.cjs` script enables VS Code to communicate with the Docker-hosted MCP server:

### How It Works

1. **Receives messages** from VS Code via `stdin` (JSON-RPC 2.0 format)
2. **Forwards requests** to Docker MCP server at `http://localhost:3000/mcp`
3. **Handles SSE responses** from server (Server-Sent Events format)
4. **Manages sessions** via `Mcp-Session-Id` headers
5. **Returns responses** to VS Code via `stdout`

### Testing the Script

```bash
# Test initialize
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | \
MCP_AUTH_TOKEN=n8n-mcp-secure-token-2026 node mcp-http-client.cjs

# Test tools list (requires session from initialize)
(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'; \
sleep 0.5; \
echo '{"jsonrpc":"2.0","id":2,"method":"tools/list"}') | \
MCP_AUTH_TOKEN=n8n-mcp-secure-token-2026 node mcp-http-client.cjs
```

### Script Requirements

- **Node.js**: 16+ (uses native `http` module)
- **Environment**: `MCP_AUTH_TOKEN` must be set
- **Network**: Docker MCP server must be running on `localhost:3000`
- **Format**: CommonJS (`.cjs`) to avoid module system conflicts

---

**Last Updated**: January 19, 2026
