# M45.3 skills: state of the work (WIP)

Done (builds; fa_test_ai 269/269, fa_test_tooling skills_test 7/7, editor autotest K2 passes with 0 failures):
- Agent Skills format: tools/common (skills.h/.cpp, validate check_skills, embedded engine skills in skills/<name>/, 11 engine skills).
- tools/ai: skills.h/.cpp (scan, precedence, roles, prompt section, read_skill, skills.list/read/new commands), extensions
  `engine:<name>` paths, plan.implicitSkillDirs for Claude Code, prompt.cpp reads craft guides from skills, small hook in session.cpp.
- templates/common/AGENTS.md trimmed (topic guides moved to skills).
- Editor: Skills table in the AI settings Extensions tab (tools/editor/src/ai_extensions.cpp), autotest section K2
  (autotest_tools.cpp, autotest_sections.h, CMakeLists.txt shard 4).
- Tests: tools/ai/tests/test_skills.cpp, tools/common/tests/skills_test.cpp, test_extensions.cpp adjusted.

Prompt bytes before -> after (measured): orchestrator 5553 -> 4647; orchestrator with artist+audio off 7596 -> 5504;
worker 3890 -> 2982; fast 1887 -> 1887; artist 5122 -> 3048; audio 4921 -> 2669; reviewer 4039 (same); artCritic 3919 (same).
AGENTS.md template 17,737 -> ~12 KB.

Left to do:
- Docs: new docs/SKILLS.md; AI_GUIDE.md; AI_PROVIDERS.md "Extensions" (skills reach every provider); docs/AI_COSTS.md (prompt bytes
  above); docs/EDITOR.md (Skills table + K2); CHANGELOG.md "### New" ending "(M45.3)".
- Regenerate docs/reference (`factoria call docs.write_reference '{"out":"docs"}'`) and example typings; api_since.json already has
  "unreleased" entries for skills.list/read/new.
- Full build of every target + full ctest (~6 min); K2 autotest once more after the last edit.
- Not decided: Codex gets no native skills (prompt lines + skills_read only); examples/*/AGENTS.md are stale copies, untouched.
