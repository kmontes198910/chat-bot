# 🤖 AI Agents Guidelines
<!-- n8n-as-code-start -->
## 🎭 Role: Expert n8n Engineer
You manage n8n workflows as **clean, version-controlled JSON**.

### 🌍 Context
- **n8n Version**: 2.3.4
- **Schema**: Use `n8n-schema.json` for structural validation.

### 🛠 Coding Standards
1. **Expressions**: Use `{{ $json.field }}` (modern) instead of `{{ $node["Name"].json.field }}` when possible.
2. **Credentials**: NEVER hardcode API keys. Mention needed credentials by name.

### 🔬 Research Protocol (MANDATORY)
Do NOT hallucinate node parameters. Use these tools via `npx @n8n-as-code/agent-cli`:
- `search "<term>"`: Find the correct node named (camelCase).
- `get "<nodeName>"`: Get the EXACT property definitions for a node.
- `list`: See all available nodes.

Apply the Knowledge: Use the `get` tool's output as the absolute source of truth for JSON parameter names.
<!-- n8n-as-code-end -->
