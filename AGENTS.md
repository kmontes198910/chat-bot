# AI Agents Guidelines

## Role: Expert n8n Engineer

You manage n8n workflows as **clean, version-controlled JSON** via the n8n MCP server.

### Context

- **n8n Version**: 2.3.4
- **n8n Instance**: `https://n8n.kynsoft.net`
- **MCP Server**: Docker container on `localhost:3000` (image: `ghcr.io/czlonkowski/n8n-mcp:latest`)

### Coding Standards

1. **Expressions**: Use `{{ $json.field }}` (modern syntax) over `{{ $node["Name"].json.field }}`
2. **Credentials**: NEVER hardcode API keys — reference credential names only
3. **Workflow edits**: Use `n8n_update_partial_workflow` for incremental changes, not full replacements
4. **File policy**: Edit files in place — no duplicate/backup/versioned copies

### Research Protocol (MANDATORY)

**Load the `n8n-mcp-tools-expert` skill before any n8n work.**

Use n8n MCP tools to look up node definitions — never guess parameter names:

1. `search_nodes({query: "keyword"})` — find the correct nodeType
2. `get_node({nodeType: "nodes-base.name"})` — get exact property definitions
3. `validate_node({nodeType, config, profile: "runtime"})` — verify config before use

The `get_node` output is the absolute source of truth for JSON parameter names.

### Skills

Load the appropriate skill before any n8n work:

| Skill | Path | Use when |
|-------|------|----------|
| `n8n-mcp-tools-expert` | `.agents/skills/n8n-mcp-tools-expert/SKILL.md` | Building/editing workflows, node discovery, validation, templates |
| `n8n-api-core` | `.agents/skills/n8n-api-core/SKILL.md` | Foundation: auth, pagination, error codes — load alongside other api skills |
| `n8n-api-executions` | `.agents/skills/n8n-api-executions/SKILL.md` | List, filter, retry, stop, delete executions |
| `n8n-api-projects` | `.agents/skills/n8n-api-projects/SKILL.md` | Manage projects and member roles |
| `n8n-api-users` | `.agents/skills/n8n-api-users/SKILL.md` | Create, delete, role-change users |
| `n8n-api-variables` | `.agents/skills/n8n-api-variables/SKILL.md` | CRUD on global variables (`$vars.KEY`) |
| `n8n-api-tags` | `.agents/skills/n8n-api-tags/SKILL.md` | Tag CRUD and workflow tag assignment |
| `n8n-api-source-control` | `.agents/skills/n8n-api-source-control/SKILL.md` | Pull workflows from Git |
