#!/bin/sh
# Fake `claude` CLI: prints stream-json lines. Records its argv (and stdin as "stdin:...") in $FAKE_ARGV_FILE if set.
# FAKE_COST overrides total_cost_usd; FAKE_MODE: notloggedin | crash | slow | spend (two paid model calls, then silence) | models (answers the `initialize`
# control_request on stdin with a control_response listing three models, after one hook event line; with FAKE_HANG it then keeps running) | resume_fails (--resume is answered with
# claude's "No conversation found" error) | mcp_spawn (calls the tool scene_spawn {"name":"CliCoin"} on the HTTP MCP
# server of its --mcp-config with curl, like Claude Code calling a tool; the reply goes to $FAKE_ARGV_FILE.mcp).
# mcp_run_detach (calls the tool ai_run {"task":"Make a coin","role":"worker"} in the background and ends its turn at once,
# like an orchestrator whose ai_run call was cut off; a prompt that says a worker "finished after your turn ended" -- the
# editor's continuation -- gets a plain answer instead). FAKE_SLEEP=<seconds> keeps it silent that long after its init line.
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
  models)
    case "$stdin" in
      *control_request*)
        echo '{"type":"system","subtype":"hook_started","hook_name":"SessionStart:startup","session_id":"sess-1"}'
        echo '{"type":"control_response","response":{"subtype":"success","request_id":"fa-models","response":{"commands":[],"models":[{"value":"default","displayName":"Default recommended","description":"Opus 5.5 with 1M context","resolvedModel":"claude-opus-5-5"},{"value":"sonnet","displayName":"Sonnet 5.5","description":"Fast and capable","resolvedModel":"claude-sonnet-5-5"},{"value":"claude-haiku-4-5-20251001","displayName":"Haiku 4.5","description":"Fastest for quick answers","resolvedModel":"claude-haiku-4-5-20251001"}]}}}'
        if [ -n "$FAKE_HANG" ]; then sleep 30; fi
        exit 0 ;;
    esac
    exit 1 ;;
  resume_fails)
    case " $* " in
      *" --resume "*)
        echo '{"type":"result","subtype":"error_during_execution","is_error":true,"num_turns":0,"session_id":"gone","total_cost_usd":0,"usage":{},"errors":["No conversation found with session ID: gone"]}'
        exit 1 ;;
    esac ;;
  spend)
    # Two model calls that cost real money, then a long silence (the run's limit must stop it, not the end of the stream).
    echo '{"type":"system","subtype":"init","session_id":"s1","model":"sonnet","mcp_servers":[]}'
    echo '{"type":"assistant","message":{"id":"m1","model":"claude-sonnet-5-5","content":[{"type":"text","text":"a"}],"usage":{"input_tokens":1000,"output_tokens":100}},"parent_tool_use_id":null}'
    echo '{"type":"assistant","message":{"id":"m2","model":"claude-sonnet-5-5","content":[{"type":"text","text":"b"}],"usage":{"input_tokens":1000,"output_tokens":100}},"parent_tool_use_id":null}'
    sleep 30
    exit 0 ;;
  mcp_spawn)
    cfg=""; prev=""
    for a in "$@"; do if [ "$prev" = "--mcp-config" ]; then cfg="$a"; fi; prev="$a"; done
    url=$(sed -n 's/.*"url": *"\([^"]*\)".*/\1/p' "$cfg")
    out=/dev/null
    if [ -n "$FAKE_ARGV_FILE" ]; then out="$FAKE_ARGV_FILE.mcp"; fi
    curl -s -o "$out" -H 'content-type: application/json' -H 'accept: application/json, text/event-stream' \
      -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"scene_spawn","arguments":{"name":"CliCoin"}}}' "$url" ;;
  mcp_run_detach)
    case "$stdin" in
      *"finished after your turn ended"*) ;;
      *)
        cfg=""; prev=""
        for a in "$@"; do if [ "$prev" = "--mcp-config" ]; then cfg="$a"; fi; prev="$a"; done
        url=$(sed -n 's/.*"url": *"\([^"]*\)".*/\1/p' "$cfg")
        curl -s -m 120 -o /dev/null -H 'content-type: application/json' -H 'accept: application/json, text/event-stream' \
          -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"ai_run","arguments":{"task":"Make a coin","role":"worker"}}}' "$url" \
          >/dev/null 2>&1 </dev/null &
        sleep 1 ;;
    esac ;;
esac
cost=${FAKE_COST:-0.0123}
echo '{"type":"system","subtype":"init","session_id":"sess-1","model":"sonnet","mcp_servers":[{"name":"factoria","status":"connected"},{"name":"other","status":"failed"}]}'
if [ -n "$FAKE_SLEEP" ]; then sleep "$FAKE_SLEEP"; fi
echo 'plain warning line that is not json'
echo '{"type":"assistant","message":{"content":[{"type":"text","text":"Looking at the project."},{"type":"tool_use","id":"tu1","name":"mcp__factoria__project_validate","input":{}}]}}'
echo '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"tu1","content":[{"type":"text","text":"{\"ok\":true}"}],"is_error":false}]}}'
echo '{"type":"assistant","message":{"content":[{"type":"text","text":"All good."}],"usage":{"input_tokens":2,"cache_creation_input_tokens":1000,"cache_read_input_tokens":4000,"output_tokens":5}},"parent_tool_use_id":null}'
echo '{"type":"rate_limit_event","rate_limit_info":{"status":"allowed","resetsAt":1792021800,"rateLimitType":"five_hour","unifiedWindows":{"five_hour":{"utilization":0.06,"resetsAt":1792021800},"seven_day":{"utilization":0.07,"resetsAt":1792584000}}}}'
echo '{"type":"result","subtype":"success","is_error":false,"result":"Done: project is valid.","total_cost_usd":'"$cost"',"num_turns":2,"session_id":"sess-1","usage":{"input_tokens":100,"output_tokens":20,"cache_creation_input_tokens":5,"cache_read_input_tokens":50},"modelUsage":{"claude-haiku-5-5":{"inputTokens":100,"outputTokens":20,"cacheReadInputTokens":50,"cacheCreationInputTokens":5,"contextWindow":1000000}}}'
