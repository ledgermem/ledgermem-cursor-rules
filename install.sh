#!/usr/bin/env bash
# Install LedgerMem rules + MCP config into the current project + user-level Cursor config.
set -euo pipefail

REPO="ledgermem/ledgermem-cursor-rules"
RAW="https://raw.githubusercontent.com/$REPO/main"

# Step 1 — drop the rules file into the project
mkdir -p .cursor/rules
curl -fsSL -o .cursor/rules/ledgermem.mdc "$RAW/.cursor/rules/ledgermem.mdc"
echo "✓ wrote .cursor/rules/ledgermem.mdc"

# Step 2 — register the MCP server in user config
MCP_FILE="$HOME/.cursor/mcp.json"
mkdir -p "$(dirname "$MCP_FILE")"

if [[ ! -f "$MCP_FILE" ]]; then
  cat > "$MCP_FILE" <<'JSON'
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
JSON
  echo "✓ created $MCP_FILE"
else
  if grep -q '"ledgermem"' "$MCP_FILE"; then
    echo "skip   ledgermem entry already present in $MCP_FILE"
  else
    echo "warn   $MCP_FILE exists. Add this manually under \"mcpServers\":"
    cat <<'JSON'
    "ledgermem": {
      "command": "npx",
      "args": ["-y", "@ledgermem/mcp-server"],
      "env": {
        "LEDGERMEM_API_KEY": "${env:LEDGERMEM_API_KEY}",
        "LEDGERMEM_WORKSPACE_ID": "${env:LEDGERMEM_WORKSPACE_ID}"
      }
    }
JSON
  fi
fi

# Step 3 — env var hint
if [[ -z "${LEDGERMEM_API_KEY:-}" ]]; then
  echo
  echo "Next: set your credentials"
  echo "  export LEDGERMEM_API_KEY=lm_live_..."
  echo "  export LEDGERMEM_WORKSPACE_ID=ws_..."
fi

echo
echo "Done. Restart Cursor for the MCP server to register."
