#!/bin/sh
if [ -n "$FAKE_ARGV_FILE" ]; then
  for a in "$@"; do printf '%s\n' "$a" >> "$FAKE_ARGV_FILE"; done
fi
echo '{"type":"thread.started","thread_id":"th1"}'
echo '{"type":"turn.started"}'
echo '{"type":"item.started","item":{"id":"i1","type":"mcp_tool_call","server":"factoria","tool":"project_validate","arguments":{},"status":"in_progress"}}'
echo '{"type":"item.completed","item":{"id":"i1","type":"mcp_tool_call","server":"factoria","tool":"project_validate","arguments":{},"result":{"ok":true},"status":"completed"}}'
echo '{"type":"item.completed","item":{"id":"i2","type":"agent_message","text":"Validated the project."}}'
echo '{"type":"turn.completed","usage":{"input_tokens":300,"cached_input_tokens":100,"output_tokens":40}}'
