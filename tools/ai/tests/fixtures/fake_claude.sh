#!/bin/sh
# Fake `claude` CLI: prints stream-json lines. Records its argv in $FAKE_ARGV_FILE if set.
if [ -n "$FAKE_ARGV_FILE" ]; then
  for a in "$@"; do printf '%s\n' "$a" >> "$FAKE_ARGV_FILE"; done
fi
case "$FAKE_MODE" in
  notloggedin)
    echo '{"type":"result","subtype":"success","is_error":true,"result":"Invalid API key · Please run /login","total_cost_usd":0,"usage":{}}'
    exit 1 ;;
  crash)
    echo "boom: something exploded" >&2
    exit 3 ;;
  slow)
    echo '{"type":"system","subtype":"init","session_id":"s1","model":"sonnet","mcp_servers":[{"name":"factoria","status":"connected"}]}'
    sleep 30
    exit 0 ;;
esac
echo '{"type":"system","subtype":"init","session_id":"sess-1","model":"sonnet","mcp_servers":[{"name":"factoria","status":"connected"},{"name":"other","status":"failed"}]}'
echo 'plain warning line that is not json'
echo '{"type":"assistant","message":{"content":[{"type":"text","text":"Looking at the project."},{"type":"tool_use","id":"tu1","name":"mcp__factoria__project_validate","input":{}}]}}'
echo '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"tu1","content":[{"type":"text","text":"{\"ok\":true}"}],"is_error":false}]}}'
echo '{"type":"assistant","message":{"content":[{"type":"text","text":"All good."}]}}'
echo '{"type":"result","subtype":"success","is_error":false,"result":"Done: project is valid.","total_cost_usd":0.0123,"num_turns":2,"session_id":"sess-1","usage":{"input_tokens":100,"output_tokens":20,"cache_creation_input_tokens":5,"cache_read_input_tokens":50}}'
