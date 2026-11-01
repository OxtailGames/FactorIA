# M45.4 (hooks for every provider) - work in progress

## Done (builds; fa_test_ai 271/271 and the core interceptor test pass)
- tools/ai: hooks.h/.cpp (events, matchers, run_hooks, apply_hook_answer, recent runs, hooks_for_claude_code),
  hook_js.h (public, include/fa/ai) / hook_js.cpp (QuickJS sandbox), command_hooks.h/.cpp (beforeCommand/afterCommand
  interceptor, hooks_report, test_hooks).
- core: CommandInterceptor on CommandRegistry (+ test in engine/core/tests/test_command.cpp).
- extensions.cpp/h: validate_hooks accepts js handlers, timeout, match alias, beforeCommand/afterCommand.
- extension_plan.cpp/h: API providers run hooks (hookSources, load_command_hooks); notes/scope text updated.
- session.cpp: all seven events in run_chat (hook lines in the transcript, Info events, Stop cap of 8, SessionEnd in finish_with).
- session_timeline.cpp: `hook` kind and totals.hook.
- cli_agent.cpp: Claude Code settings use hooks_for_claude_code (js -> `factoria hooks run`).
- CLI: tools/cli/src/cmd_hooks.cpp (`factoria hooks run`), registered in cli.cpp/common.h.
- Commands ai.hooks / ai.hooks_test (commands.cpp), api_since.json entries, schemas/ai-config.schema.json text.
- Tests: tools/ai/tests/test_hooks.cpp (new), test_extensions.cpp adapted.

## Left
- Editor: show hooks and recent runs/failures in tools/editor/src/ai_extensions.cpp; new autotest section "H2"
  (autotest_tools.cpp, autotest_sections.h, shard lists in tools/editor/CMakeLists.txt).
- Docs: docs/HOOKS.md (embedded like the other docs), AI_PROVIDERS.md "Extensions", SCRIPTING (JS hook API),
  CHANGELOG.md "(M45.4)", then `factoria call docs.write_reference '{"out":"docs"}'` and typings if the API changed.
- Full build of every target + full ctest + H2 autotest; check "// Generated" headers and no machine paths.
- Not run yet: test_extensions/doctor texts elsewhere that may mention "do not use extensions yet" (grep docs and editor).
- Merge note: M45.3 (skills) edits the same "API providers" sentences (extension_plan.cpp kApiSentence/scope, schema description).
