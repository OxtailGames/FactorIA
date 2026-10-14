@echo off
rem Fake `claude` CLI for Windows (npm installs the real one as a .cmd too): the same script as fake_claude.sh, with the
rem modes the Windows tests need. Records its argv (one argument per line) and then "stdin:<what it was sent>" in
rem %FAKE_ARGV_FILE%. FAKE_COST overrides total_cost_usd; FAKE_MODE=resume_fails answers --resume with claude's
rem "No conversation found" error; FAKE_MODE=mcp_spawn calls the tool scene_spawn {"name":"CliCoin"} on the HTTP MCP
rem server of its --mcp-config with curl, like Claude Code calling a tool (the reply goes to %FAKE_ARGV_FILE%.mcp).
rem A CLAUDE_CODE_AUTO_COMPACT_WINDOW is recorded as "compact-window:<n>". Keep the JSON free of & | < > ^ % and parentheses: cmd.exe would act on them.
if not defined FAKE_COST set FAKE_COST=0.0123
if defined FAKE_ARGV_FILE (
  for %%a in (%*) do >>"%FAKE_ARGV_FILE%" echo %%~a
  if defined CLAUDE_CODE_AUTO_COMPACT_WINDOW >>"%FAKE_ARGV_FILE%" echo compact-window:%CLAUDE_CODE_AUTO_COMPACT_WINDOW%
  <nul set /p "=stdin:">>"%FAKE_ARGV_FILE%"
  findstr "^">>"%FAKE_ARGV_FILE%"
) else (
  findstr "^">nul
)
if "%FAKE_MODE%"=="resume_fails" (
  echo %* | findstr /c:"--resume" >nul && (
    echo {"type":"result","subtype":"error_during_execution","is_error":true,"num_turns":0,"session_id":"gone","total_cost_usd":0,"usage":{},"errors":["No conversation found with session ID: gone"]}
    exit /b 1
  )
)
if "%FAKE_MODE%"=="mcp_spawn" call :mcp_spawn %*
echo {"type":"system","subtype":"init","session_id":"sess-1","model":"sonnet","mcp_servers":[{"name":"factoria","status":"connected"}]}
echo {"type":"assistant","message":{"content":[{"type":"text","text":"Looking at the project."}]}}
echo {"type":"assistant","message":{"content":[{"type":"text","text":"All good."}],"usage":{"input_tokens":2,"cache_creation_input_tokens":1000,"cache_read_input_tokens":4000,"output_tokens":5}},"parent_tool_use_id":null}
echo {"type":"rate_limit_event","rate_limit_info":{"status":"allowed","resetsAt":1792021800,"rateLimitType":"five_hour","unifiedWindows":{"five_hour":{"utilization":0.06,"resetsAt":1792021800},"seven_day":{"utilization":0.07,"resetsAt":1792584000}}}}
echo {"type":"result","subtype":"success","is_error":false,"result":"Done: project is valid.","total_cost_usd":%FAKE_COST%,"num_turns":2,"session_id":"sess-1","usage":{"input_tokens":100,"output_tokens":20,"cache_creation_input_tokens":5,"cache_read_input_tokens":50},"modelUsage":{"claude-haiku-5-5":{"inputTokens":100,"outputTokens":20,"cacheReadInputTokens":50,"cacheCreationInputTokens":5,"contextWindow":1000000}}}
exit /b 0

:mcp_spawn
if "%~1"=="" exit /b 0
if "%~1"=="--mcp-config" goto mcp_call
shift
goto mcp_spawn
:mcp_call
for /f "tokens=2" %%u in ('findstr /c:"/mcp/" "%~2"') do set "MCP_URL=%%~u"
set "MCP_OUT=nul"
if defined FAKE_ARGV_FILE set "MCP_OUT=%FAKE_ARGV_FILE%.mcp"
curl -s -o "%MCP_OUT%" -H "content-type: application/json" -H "accept: application/json, text/event-stream" -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"scene_spawn\",\"arguments\":{\"name\":\"CliCoin\"}}}" "%MCP_URL%"
exit /b 0
