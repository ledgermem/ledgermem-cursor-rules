#!/usr/bin/env bash
# Install LedgerMem rules + MCP config into the current project + user-level Cursor config.
set -euo pipefail

REPO="ledgermem/ledgermem-cursor-rules"
RAW="https://raw.githubusercontent.com/$REPO/main"

# Cursor's MCP entry shells out to `npx` at startup. If npx is not on PATH the
# server silently fails to register and the user sees "no tools available" with
# no clue why. Catch that here so the failure mode is loud and actionable.
if ! command -v npx >/dev/null 2>&1; then
  echo "error: npx is required but not found on PATH."
  echo "       Install Node.js 18+ (https://nodejs.org) or activate your version manager"
  echo "       (nvm, fnm, volta, asdf) and re-run this script."
  exit 1
fi
if ! command -v curl >/dev/null 2>&1; then
  echo "error: curl is required but not found on PATH."
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 is required (used to safely JSON-encode secrets)."
  exit 1
fi

# Step 1 — drop the rules file into the project
mkdir -p .cursor/rules
curl -fsSL -o .cursor/rules/ledgermem.mdc "$RAW/.cursor/rules/ledgermem.mdc"
echo "✓ wrote .cursor/rules/ledgermem.mdc"

# Step 2 — register the MCP server in user config
MCP_FILE="$HOME/.cursor/mcp.json"
mkdir -p "$(dirname "$MCP_FILE")"

# Cursor's mcp.json `env` field expects literal string values; it does NOT
# expand ${env:VAR} placeholders the way VS Code launch.json does. We must
# substitute the values at install time. Refuse to write secrets if missing.
if [[ -z "${LEDGERMEM_API_KEY:-}" ]] || [[ -z "${LEDGERMEM_WORKSPACE_ID:-}" ]]; then
  echo "error: set LEDGERMEM_API_KEY and LEDGERMEM_WORKSPACE_ID before running this script."
  echo "       export LEDGERMEM_API_KEY=lm_live_..."
  echo "       export LEDGERMEM_WORKSPACE_ID=ws_..."
  exit 1
fi

# Escape for safe inclusion in JSON (handles backslashes and quotes).
json_escape() {
  python3 -c 'import json,sys;print(json.dumps(sys.argv[1]))' "$1"
}

API_KEY_JSON=$(json_escape "$LEDGERMEM_API_KEY")
WS_JSON=$(json_escape "$LEDGERMEM_WORKSPACE_ID")

if [[ ! -f "$MCP_FILE" ]]; then
  cat > "$MCP_FILE" <<JSON
{
  "mcpServers": {
    "ledgermem": {
      "command": "npx",
      "args": ["-y", "@ledgermem/mcp-server"],
      "env": {
        "LEDGERMEM_API_KEY": $API_KEY_JSON,
        "LEDGERMEM_WORKSPACE_ID": $WS_JSON
      }
    }
  }
}
JSON
  chmod 600 "$MCP_FILE"
  echo "✓ created $MCP_FILE (mode 600)"
else
  # Match the literal key "ledgermem" with surrounding punctuation so we don't
  # false-positive on substrings inside other server names.
  if grep -Eq '"ledgermem"[[:space:]]*:' "$MCP_FILE"; then
    echo "skip   ledgermem entry already present in $MCP_FILE"
  else
    echo "warn   $MCP_FILE exists. Add this manually under \"mcpServers\":"
    cat <<JSON
    "ledgermem": {
      "command": "npx",
      "args": ["-y", "@ledgermem/mcp-server"],
      "env": {
        "LEDGERMEM_API_KEY": $API_KEY_JSON,
        "LEDGERMEM_WORKSPACE_ID": $WS_JSON
      }
    }
JSON
  fi
fi

echo
echo "Done. Restart Cursor for the MCP server to register."
