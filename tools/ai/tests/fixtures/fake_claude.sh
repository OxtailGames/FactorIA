#!/bin/sh
# Fake `claude` CLI: prints stream-json lines. Records its argv (and stdin as "stdin:...") in $FAKE_ARGV_FILE if set.
# FAKE_COST overrides total_cost_usd; FAKE_MODE: notloggedin | crash | slow | resume_fails (--resume is answered with
# claude's "No conversation found" error) | mcp_spawn (calls the tool scene_spawn {"name":"CliCoin"} on the HTTP MCP
# server of its --mcp-config with curl, like Claude Code calling a tool; the reply goes to $FAKE_ARGV_FILE.mcp).
# A CLAUDE_CODE_AUTO_COMPACT_WINDOW is recorded as "compact-window:<n>".
# fake_claude.cmd is the same script for Windows.
if [ -n "$FAKE_ARGV_FILE" ]; then
  for a in "$@"; do printf '%s\n' "$a" >> "$FAKE_ARGV_FILE"; done
  if [ -n "$CLAUDE_CODE_AUTO_COMPACT_WINDOW" ]; then printf 'compact-window:%s\n' "$CLAUDE_CODE_AUTO_COMPACT_WINDOW" >> "$FAKE_ARGV_FILE"; fi
fi
stdin=$(cat)
if [ -n "$FAKE_ARGV_FILE" ] && [ -n "$stdin" ]; then printf 'stdin:%s\n' "$stdin" >> "$FAKE_ARGV_FILE"; fi
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
  resume_fails)
    case " $* " in
      *" --resume "*)
        echo '{"type":"result","subtype":"error_during_execution","is_error":true,"num_turns":0,"session_id":"gone","total_cost_usd":0,"usage":{},"errors":["No conversation found with session ID: gone"]}'
        exit 1 ;;
    esac ;;
  mcp_spawn)
    cfg=""; prev=""
    for a in "$@"; do if [ "$prev" = "--mcp-config" ]; then cfg="$a"; fi; prev="$a"; done
    url=$(sed -n 's/.*"url": *"\([^"]*\)".*/\1/p' "$cfg")
    out=/dev/null
    if [ -n "$FAKE_ARGV_FILE" ]; then out="$FAKE_ARGV_FILE.mcp"; fi
    curl -s -o "$out" -H 'content-type: application/json' -H 'accept: application/json, text/event-stream' \
      -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"scene_spawn","arguments":{"name":"CliCoin"}}}' "$url" ;;
esac
cost=${FAKE_COST:-0.0123}
echo '{"type":"system","subtype":"init","session_id":"sess-1","model":"sonnet","mcp_servers":[{"name":"factoria","status":"connected"},{"name":"other","status":"failed"}]}'
echo 'plain warning line that is not json'
echo '{"type":"assistant","message":{"content":[{"type":"text","text":"Looking at the project."},{"type":"tool_use","id":"tu1","name":"mcp__factoria__project_validate","input":{}}]}}'
echo '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"tu1","content":[{"type":"text","text":"{\"ok\":true}"}],"is_error":false}]}}'
echo '{"type":"assistant","message":{"content":[{"type":"text","text":"All good."}],"usage":{"input_tokens":2,"cache_creation_input_tokens":1000,"cache_read_input_tokens":4000,"output_tokens":5}},"parent_tool_use_id":null}'
echo '{"type":"rate_limit_event","rate_limit_info":{"status":"allowed","resetsAt":1792021800,"rateLimitType":"five_hour","unifiedWindows":{"five_hour":{"utilization":0.06,"resetsAt":1792021800},"seven_day":{"utilization":0.07,"resetsAt":1792584000}}}}'
echo '{"type":"result","subtype":"success","is_error":false,"result":"Done: project is valid.","total_cost_usd":'"$cost"',"num_turns":2,"session_id":"sess-1","usage":{"input_tokens":100,"output_tokens":20,"cache_creation_input_tokens":5,"cache_read_input_tokens":50},"modelUsage":{"claude-haiku-5-5":{"inputTokens":100,"outputTokens":20,"cacheReadInputTokens":50,"cacheCreationInputTokens":5,"contextWindow":1000000}}}'
