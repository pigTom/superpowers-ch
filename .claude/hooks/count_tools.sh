#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')

REGISTRY_DIR="/tmp/claude_task_registry"
COUNTER_DIR="/tmp/claude_tool_counts"
mkdir -p "$REGISTRY_DIR" "$COUNTER_DIR"

# Detect task registration: agent's first bash call must be exactly: echo "TASK:<name>"
if [ "$TOOL_NAME" = "Bash" ]; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
    TASK_NAME=$(echo "$COMMAND" | sed -n 's/^echo "TASK:\([^"]*\)"$/\1/p')
    if [ -n "$TASK_NAME" ]; then
        echo "$TASK_NAME" > "${REGISTRY_DIR}/session_${SESSION_ID}"
        echo "$SESSION_ID" > "${REGISTRY_DIR}/task_${TASK_NAME}"
    fi
fi

# Count every tool call per session
COUNTER_FILE="${COUNTER_DIR}/${SESSION_ID}"
COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
echo $((COUNT + 1)) > "$COUNTER_FILE"
