# n8n-MCP Chatbot Project

## Project Overview

This project provides a Model Context Protocol (MCP) server that integrates with n8n workflow automation platform, enabling AI assistants like GitHub Copilot to interact with n8n workflows and automations.

## Architecture

### Components

1. **n8n-mcp Server**: Docker container running the MCP server (ghcr.io/czlonkowski/n8n-mcp:latest)
   - Runs in HTTP mode on port 3000
   - Provides MCP tools to interact with n8n workflows
   - Uses SQLite for persistence

2. **n8n Instance**: Cloud-hosted n8n automation platform (https://n8n.kynsoft.net)
   - Hosts workflow automations
   - Exposes public API for programmatic access
   - Contains 3 active workflows with 32 unique node types

3. **MCP Integration**: Connects GitHub Copilot to n8n via MCP protocol
   - Allows AI-powered workflow management
   - Enables natural language interaction with n8n

### Workflows

The project currently contains 3 workflows:

1. **Agente IA MultiModal para WhatsAp, Buffer y RAG**
   - Multi-modal AI agent for WhatsApp
   - Implements RAG (Retrieval Augmented Generation)
   - Uses LangChain nodes for AI capabilities

2. **Chatbot-kynsoft**
   - Main chatbot automation
   - Integrates with multiple AI models (OpenAI, Google Gemini)

3. **Scrap info from any Website**
   - Web scraping workflow using Firecrawl
   - Extracts and processes web content

## Available n8n Nodes

### LangChain AI Nodes (12)
- `agent` - AI Agent orchestration
- `chainLlm` - LLM Chain execution
- `chatTrigger` - Chat event triggers
- `documentDefaultDataLoader` - Document loading
- `embeddingsOpenAi` - OpenAI embeddings generation
- `googleGemini` - Google Gemini integration
- `lmChatOpenAi` - OpenAI Chat Model
- `memoryBufferWindow` - Conversation memory buffer
- `memoryPostgresChat` - PostgreSQL chat history
- `openAi` - OpenAI API integration
- `textSplitterRecursiveCharacterTextSplitter` - Text chunking
- `vectorStoreSupabase` - Supabase vector storage

### Core n8n Nodes (19)
- `aggregate` - Data aggregation
- `code` - Custom JavaScript/Python execution
- `extractFromFile` - File content extraction
- `filter` - Item filtering
- `formTrigger` - Form submission triggers
- `googleDrive` - Google Drive operations
- `googleDriveTrigger` - Google Drive event triggers
- `httpRequest` - HTTP API calls
- `httpRequestTool` - HTTP request tool
- `if` - Conditional branching
- `noOp` - No operation placeholder
- `redis` - Redis database operations
- `set` - Value setting
- `splitOut` - Item splitting
- `stickyNote` - Workflow documentation
- `switch` - Multi-condition routing
- `wait` - Delay execution
- `whatsApp` - WhatsApp messaging
- `whatsAppTrigger` - WhatsApp event triggers

### Custom Nodes (1)
- `@mendable/n8n-nodes-preview-firecrawl.firecrawl` - Advanced web scraping

## Setup Instructions

### Prerequisites

- Docker and Docker Compose
- Node.js 16+ (for npx commands)
- VS Code with GitHub Copilot extension
- Access to n8n.kynsoft.net instance

### Installation

1. **Clone and navigate to project**:
   ```bash
   cd /home/odixan/Documents/Proyecto/KynSoft/n8n-chatbot
   ```

2. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your credentials:
   # - N8N_API_KEY: Your n8n API key
   # - MCP_AUTH_TOKEN: Token for MCP authentication
   ```

3. **Start the MCP server**:
   ```bash
   docker-compose up -d
   ```

4. **Verify health**:
   ```bash
   curl http://localhost:3000/health
   ```

### VS Code Configuration

Add to your VS Code settings (`~/.config/Code/User/settings.json`):

```json
{
  "github.copilot.chat.mcp.servers": {
    "n8n-mcp": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/client-http", "http://localhost:3000/mcp"],
      "env": {
        "MCP_AUTH_TOKEN": "n8n-mcp-secure-token-2026"
      }
    }
  }
}
```

## How to Use the n8n-MCP Server

### MCP Server Endpoints

- **Health Check**: `GET http://localhost:3000/health`
  - Returns server status, uptime, and session information

- **MCP Protocol**: `POST http://localhost:3000/mcp`
  - JSON-RPC 2.0 endpoint for MCP communication
  - Requires session authentication

### Using with GitHub Copilot

Once configured, you can interact with n8n workflows using natural language in Copilot Chat:

**Example Commands**:
- "List all n8n workflows"
- "Show me the nodes in the chatbot workflow"
- "Execute the web scraping workflow"
- "Create a new workflow with HTTP and Code nodes"

### Direct API Access

You can also use the n8n API directly:

```bash
# List all workflows
curl -X GET "https://n8n.kynsoft.net/api/v1/workflows" \
  -H "X-N8N-API-KEY: your-api-key"

# Get workflow details
curl -X GET "https://n8n.kynsoft.net/api/v1/workflows/{id}" \
  -H "X-N8N-API-KEY: your-api-key"

# Execute a workflow
curl -X POST "https://n8n.kynsoft.net/api/v1/workflows/{id}/execute" \
  -H "X-N8N-API-KEY: your-api-key"
```

## Project Structure

```
n8n-chatbot/
├── .github/
│   └── copilot-instructions.md    # This file
├── .env                            # Environment variables (not in git)
├── .env.example                    # Environment template
├── docker-compose.yml              # Docker orchestration
├── COPILOT_MCP_SETUP.md           # MCP setup guide
└── mcp-config-vscode.json         # MCP configuration
```

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `N8N_API_URL` | n8n instance URL | `https://n8n.kynsoft.net` |
| `N8N_API_KEY` | n8n API authentication | `eyJhbGc...` |
| `MCP_AUTH_TOKEN` | MCP server auth token | `n8n-mcp-secure-token-2026` |
| `MCP_MODE` | Server mode | `http` |
| `MCP_PORT` | Server port | `3000` |
| `LOG_LEVEL` | Logging verbosity | `error` |

## Common Development Tasks

### Start the MCP Server
```bash
docker-compose up -d
```

### Stop the MCP Server
```bash
docker-compose down
```

### View Logs
```bash
docker-compose logs -f n8n-mcp
```

### Restart After Config Changes
```bash
docker-compose restart n8n-mcp
```

### Check Server Status
```bash
curl http://localhost:3000/health | jq
```

### Access Container Shell
```bash
docker exec -it n8n-mcp sh
```

## Troubleshooting

### MCP Server Won't Start
1. Check if port 3000 is available: `lsof -i :3000`
2. Verify Docker is running: `docker ps`
3. Check logs: `docker-compose logs n8n-mcp`

### Authentication Errors
1. Verify `MCP_AUTH_TOKEN` matches in `.env` and VS Code settings
2. Check `N8N_API_KEY` is valid and not expired
3. Ensure n8n instance is accessible: `curl https://n8n.kynsoft.net`

### Copilot Can't Connect to MCP
1. Reload VS Code window
2. Check MCP server health: `curl http://localhost:3000/health`
3. Verify VS Code settings.json configuration
4. Check Copilot logs in VS Code Output panel

## Security Notes

- **API Keys**: Never commit `.env` file to version control
- **MCP Token**: Use strong, unique tokens for MCP_AUTH_TOKEN
- **Network**: MCP server is exposed on localhost:3000 by default
- **Docker**: Container runs with default user (nodejs)
- **Telemetry**: Disabled by default (`N8N_MCP_TELEMETRY_DISABLED=true`)

## Additional Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [n8n-mcp GitHub Repository](https://github.com/czlonkowski/n8n-mcp)
- [n8n API Documentation](https://docs.n8n.io/api/)

## Contributing

When working on this project:
1. Test MCP server changes locally first
2. Update this documentation if adding new features
3. Follow existing environment variable patterns
4. Keep sensitive data in `.env` file only
5. Document any new n8n workflows or nodes used

## License

Project-specific license information should be added here.
