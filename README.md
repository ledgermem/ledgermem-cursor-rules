# `ledgermem-cursor-rules`

Drop-in **Cursor IDE** rules + **MCP server preset** that wire LedgerMem into your AI coding workflow.

> Result: Cursor automatically recalls relevant project memory before generating, and saves design decisions back as you make them.

## Install

```bash
# From your project root
curl -fsSL https://raw.githubusercontent.com/ledgermem/ledgermem-cursor-rules/main/install.sh | bash
```

What that does:

1. Drops `.cursor/rules/ledgermem.mdc` into your project
2. Adds an `mcpServers` entry to `~/.cursor/mcp.json` (or creates the file)
3. Verifies `npx -y @ledgermem/mcp-server` is reachable

## Manual install

```bash
mkdir -p .cursor/rules
curl -fsSL -o .cursor/rules/ledgermem.mdc https://raw.githubusercontent.com/ledgermem/ledgermem-cursor-rules/main/.cursor/rules/ledgermem.mdc
```

Then add to `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "ledgermem": {
      "command": "npx",
      "args": ["-y", "@ledgermem/mcp-server"],
      "env": {
        "LEDGERMEM_API_KEY": "${env:LEDGERMEM_API_KEY}",
        "LEDGERMEM_WORKSPACE_ID": "${env:LEDGERMEM_WORKSPACE_ID}"
      }
    }
  }
}
```

Then in your shell:

```bash
export LEDGERMEM_API_KEY=lm_live_...
export LEDGERMEM_WORKSPACE_ID=ws_...
```

## What's in the rules pack

| Rule | When it fires | What it does |
| --- | --- | --- |
| **Recall before code** | Before any non-trivial generation | Calls `memory_search` for relevant prior decisions |
| **Save decisions** | When user accepts an architectural choice | Calls `memory_add` with the decision + rationale |
| **No repeated questions** | When asking the user something | Searches memory first to avoid asking twice |
| **Stack consistency** | Before suggesting a library | Checks memory for already-chosen libraries in this project |

See [`.cursor/rules/ledgermem.mdc`](.cursor/rules/ledgermem.mdc) for the full rule text.

## Compatible IDEs

Cursor inherits `.cursor/rules/` and MCP config — these also work in:

- [Cursor](https://cursor.sh) (primary)
- [Windsurf](https://codeium.com/windsurf) (MCP only; uses `~/.codeium/windsurf/mcp_config.json`)
- [Cline](https://github.com/cline/cline) (MCP only; uses `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`)

## License

MIT
