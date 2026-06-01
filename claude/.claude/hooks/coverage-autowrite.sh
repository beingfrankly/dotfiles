#!/usr/bin/env bash
# ~/.claude/hooks/coverage-autowrite.sh
# SubagentStop hook: auto-writes hooked coverage when an explorer subagent stops.
#
# EXPLORER_TYPES allowlist — only explorer agent types (search/ast-search/lsp-search)
# trigger a coverage write. Update this list if new explorer agent types are added
# to the pipeline.
# Known risk: agent_type filter drift if new explorer agents are introduced
# without also adding their type here.
EXPLORER_TYPES=(search ast-search lsp-search)

HOOKED_BIN=/Users/Frank.vanEldijk/code/hooked/target/release/hooked

set -euo pipefail

main() {
  INPUT=$(cat)

  AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // empty')
  AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // empty')

  # Guard: agent_id must be present
  if [[ -z "$AGENT_ID" ]]; then
    return 0
  fi

  # Guard: agent_type must be in the allowlist
  local matched=0
  for t in "${EXPLORER_TYPES[@]}"; do
    if [[ "$AGENT_TYPE" == "$t" ]]; then
      matched=1
      break
    fi
  done
  if [[ "$matched" -eq 0 ]]; then
    return 0
  fi

  # Guard: binary must exist and be executable
  if [[ ! -x "$HOOKED_BIN" ]]; then
    return 0
  fi

  "$HOOKED_BIN" coverage "$AGENT_ID" --write >/dev/null 2>&1 || true
}

main || true

exit 0
