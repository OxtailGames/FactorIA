#include <filesystem>
#include <fstream>
#include <sstream>

#include "fa/core/strings.h"
#include "fa/mcp/server.h"
#include "fa/runtime/project.h"
#include "fa/tooling/docs.h"
#include "fa/tooling/project_fs.h"

namespace fa {

namespace stdfs = std::filesystem;

std::string McpHost::server_version() const { return FA_ENGINE_VERSION; }
std::string McpHost::instructions() const { return default_mcp_instructions(); }
std::vector<McpResource> McpHost::list_resources() { return default_mcp_resources(project_dir()); }
Result<McpResourceContent> McpHost::read_resource(std::string_view uri) { return default_mcp_read_resource(project_dir(), uri); }
std::vector<McpPrompt> McpHost::list_prompts() { return default_mcp_prompts(); }
Result<std::vector<McpPromptMessage>> McpHost::get_prompt(std::string_view name, const Json& arguments) {
    return default_mcp_prompt_messages(name, arguments);
}

std::string default_mcp_instructions() {
    return
R"(FactorIA is an AI-native 2D/3D game engine. You build games by editing JSON (scenes, prefabs, factoria.json) and JavaScript (scripts, tools, tests), and you verify them with the tools below. Everything is text; you can see the game through screenshots.

WORKFLOW (repeat for every change)
1. Read first: docs_list, then docs_read {"name":"ai-guide"} and docs_search for any component or API you are unsure about. Component names and fields are strict: use docs_components {"name":"Sprite"} / docs_commands {"name":"game.step"} instead of guessing. A long page comes in parts with a contents list: read a section with docs_read {"name":"ai-guide","heading":"..."}.
2. Edit files (your own file tools, or fs_read / fs_write / fs_edit / fs_search / fs_list if you have none) or use the scene_* tools on the running game.
3. project_validate after every batch of edits. Errors give file, JSON pointer and a fix hint.
4. Run and LOOK: game_step {"frames":120} then game_screenshot, and check the returned image really shows what you intended. For fine detail (seams, joins, gradient ends) use game_screenshot {"region":[x,y,w,h],"zoom":8}; for an animation a filmstrip {"frames":24,"everyFrames":4}; game_screenshot without a path is not kept (the image is attached, then the file is deleted). game_state / game_logs show entity data and script errors.
5. Run the project's tests (tests/*.test.js) and add a test for every behaviour you add.

CONVENTIONS
- JSON keys camelCase; components PascalCase (Sprite, RigidBody2D). Entities have a stable string "id".
- +Y is up, right-handed, angles in degrees, colors 0..1 (or "#rrggbb"). 2D units are design pixels with the origin at the screen centre; screen-space UI (space "screen") has its origin top-left with +Y down. 3D units are meters.
- Paths are project-relative with forward slashes. Gameplay reads input ACTIONS declared in factoria.json, not raw keys.
- Simulation is deterministic: use the engine rng and dt, never Math.random or wall-clock time.
- Tool names are command names with dots replaced by underscores (feedback.report -> feedback_report). Project tools from tools/*.js appear as project_<name>.

RULE: REPORT ENGINE GAPS. Whenever the engine lacks a feature, has a bug, gives a misleading error, or you build a workaround or drop something because of an engine limitation, call feedback_report IMMEDIATELY (category, severity, title, missing, workaround, suggestion). It records the gap in the project's ENGINE_FEEDBACK.json (closed entries move to ENGINE_FEEDBACK.archive.json), which engine developers use to decide what to build next. Similar reports are merged automatically, so never skip a report for fear of duplicates.

Resources: factoria://docs/<file> (documentation), factoria://project/factoria.json and factoria://project/ENGINE_FEEDBACK.json. Prompts: make-game, add-feature, fix-bug, report-engine-gap.)";
}

std::vector<McpPrompt> default_mcp_prompts() {
    return {
        {"make-game", "Build a complete small game from an idea, step by step, with validation, screenshots and tests.",
         {{"idea", "What game to make (genre, mechanics, look).", true}}},
        {"add-feature", "Add one feature to the current game and verify it.",
         {{"feature", "The feature to add, e.g. 'enemies that chase the player'.", true}}},
        {"fix-bug", "Reproduce, fix and lock in a bug with a regression test.",
         {{"description", "What goes wrong and how to trigger it.", true}}},
        {"report-engine-gap", "Record something the engine lacked, with the workaround, in ENGINE_FEEDBACK.json.",
         {{"summary", "What the engine lacked or got wrong (optional; you will be asked to be specific).", false}}},
    };
}

namespace {
std::string arg_of(const Json& args, const char* key) {
    if (args.is_object() && args.contains(key) && args[key].is_string()) return args[key].get<std::string>();
    return {};
}
}  // namespace

Result<std::vector<McpPromptMessage>> default_mcp_prompt_messages(std::string_view name, const Json& arguments) {
    std::string text;
    if (name == "make-game") {
        std::string idea = arg_of(arguments, "idea");
        if (idea.empty()) return make_error("Prompt 'make-game' needs the argument 'idea'.", "Pass {\"idea\": \"a top-down space shooter\"}.");
        text =
"Make this game with FactorIA: " + idea + "\n\n"
"Follow these steps and do not skip the verification steps.\n"
"1. Read the guide: call docs_read {\"name\":\"ai-guide\"}, then docs_read {\"name\":\"scripting\"} and docs_components for the exact component fields. Read AGENTS.md in the project if present.\n"
"2. Plan in a few lines: core loop, entities, input actions, win/lose condition. Keep scope small enough to finish; prefer Shape2D / primitive meshes over external art.\n"
"3. Set up factoria.json (display size, input actions) and build scenes/main.scene.json with the essential entities.\n"
"4. Call project_validate. Fix every error using its hint, repeat until ok.\n"
"5. Call game_step {\"frames\":60} and game_screenshot. LOOK at the image: is the scene visible, scaled and positioned as intended? Fix and re-check.\n"
"6. Implement behaviour in scripts/*.js (Behaviour classes) one mechanic at a time. After each mechanic: project_validate, game_step with input (game_input), game_screenshot, and check game_logs for script errors.\n"
"7. Write tests in tests/*.test.js for each mechanic (movement, scoring, win/lose) and run them (tool project_test if available, else `factoria test`).\n"
"8. Whenever the engine lacked something and you worked around it or dropped a feature, call feedback_report right away.\n"
"9. Finish with a summary: what works, how to run it (`factoria run`), what you could not do and the feedback you reported.";
    } else if (name == "add-feature") {
        std::string feature = arg_of(arguments, "feature");
        if (feature.empty()) return make_error("Prompt 'add-feature' needs the argument 'feature'.", "Pass {\"feature\": \"enemies that chase the player\"}.");
        text =
"Add this feature to the current FactorIA game: " + feature + "\n\n"
"1. Understand the current state: fs_list / read factoria.json, the main scene and relevant scripts; call game_state to see the live entities.\n"
"2. Check the docs for the components and APIs you will use (docs_search, docs_components). Do not guess field names.\n"
"3. Implement the smallest change that delivers the feature (scene/prefab JSON and/or scripts). Keep existing behaviour working.\n"
"4. Call project_validate and fix every error.\n"
"5. Run: game_step {\"frames\":120} (feed input with game_input if needed), then game_screenshot and LOOK at it. Check game_logs for errors.\n"
"6. Add or extend a test in tests/*.test.js that fails without the feature, and run all tests.\n"
"7. If the engine lacked something you needed, call feedback_report immediately with the workaround you used.\n"
"8. Report what changed and how you verified it.";
    } else if (name == "fix-bug") {
        std::string desc = arg_of(arguments, "description");
        if (desc.empty()) return make_error("Prompt 'fix-bug' needs the argument 'description'.", "Pass {\"description\": \"player falls through the floor after jumping\"}.");
        text =
"Fix this bug in the current FactorIA game: " + desc + "\n\n"
"1. Reproduce it headlessly: project_validate first, then game_step with the input that triggers it (game_input), game_screenshot and game_state. Read game_logs for script errors.\n"
"2. Write a failing test in tests/*.test.js that captures the bug (deterministic: the engine uses a fixed step and seeded rng). Run it and confirm it fails for the right reason.\n"
"3. Find the cause: inspect the relevant scene entries and scripts (fs_read, fs_search). Prefer fixing data/scripts; if the cause is an engine bug, work around it AND call feedback_report with category, severity and a suggestion.\n"
"4. Apply the smallest fix. Run project_validate, the new test and the full test suite.\n"
"5. Take a screenshot to confirm the visual result, then summarize the cause, the fix and the regression test.";
    } else if (name == "report-engine-gap") {
        std::string summary = arg_of(arguments, "summary");
        text =
"Record an engine gap with the feedback_report tool." + (summary.empty() ? std::string() : "\nWhat I noticed: " + summary) + "\n\n"
"1. Call feedback_list {\"status\":\"open\"} to see whether a similar gap is already recorded (similar reports are merged, so it is fine if it is).\n"
"2. Call feedback_report with:\n"
"   - category: rendering-2d, rendering-3d, physics, audio, input, ui, scripting, scene, assets, animation, tooling, ai-integration, docs, platform, performance, networking or other\n"
"   - severity: blocker (could not build it), major (big/fragile workaround), minor (small workaround), nice-to-have\n"
"   - title: short noun phrase, e.g. \"No one-way platforms\"\n"
"   - missing: what exactly the engine lacked and what you were trying to do\n"
"   - workaround: what you did instead, and workaroundFiles listing the files\n"
"   - suggestion: the concrete engine change (component field, command, API) that would remove the workaround\n"
"3. Confirm the returned id, then continue with your task.";
    } else {
        std::vector<std::string> names;
        for (const auto& p : default_mcp_prompts()) names.push_back(p.name);
        return make_error("Unknown prompt '" + std::string(name) + "'. " + did_you_mean(name, names), "Use prompts/list to see available prompts.");
    }
    return std::vector<McpPromptMessage>{{"user", text}};
}

std::vector<McpResource> default_mcp_resources(const std::string& projectDir) {
    std::vector<McpResource> out;
    for (const auto& d : list_docs())
        out.push_back({"factoria://docs/" + d.path.substr(5), d.name, d.title.empty() ? d.name : d.title, "text/markdown"});
    out.push_back({"factoria://docs/components", "components", "Components reference (generated from reflection)", "text/markdown"});
    std::error_code ec;
    auto exists = [&](const char* f) { return stdfs::exists(stdfs::path(projectDir) / f, ec); };
    if (exists("factoria.json")) out.push_back({"factoria://project/factoria.json", "factoria.json", "Project settings", "application/json"});
    if (exists("ENGINE_FEEDBACK.json"))
        out.push_back({"factoria://project/ENGINE_FEEDBACK.json", "ENGINE_FEEDBACK.json", "Engine gaps recorded for this project", "application/json"});
    if (exists("AGENTS.md")) out.push_back({"factoria://project/AGENTS.md", "AGENTS.md", "Game-making guide for AI agents", "text/markdown"});
    return out;
}

Result<McpResourceContent> default_mcp_read_resource(const std::string& projectDir, std::string_view uri) {
    auto mime_for = [](std::string_view path) { return path.size() > 5 && path.substr(path.size() - 5) == ".json" ? "application/json" : "text/markdown"; };
    constexpr std::string_view docsPrefix = "factoria://docs/", projectPrefix = "factoria://project/";
    if (uri.substr(0, docsPrefix.size()) == docsPrefix) {
        auto text = read_doc(uri);
        if (!text.ok()) return text.error();
        return McpResourceContent{std::string(uri), mime_for(uri.substr(docsPrefix.size())), std::move(text.value())};
    }
    if (uri.substr(0, projectPrefix.size()) == projectPrefix) {
        std::string rel(uri.substr(projectPrefix.size()));
        static const char* allowed[] = {"factoria.json", "ENGINE_FEEDBACK.json", "AGENTS.md"};
        bool ok = false;
        for (const char* a : allowed) ok = ok || rel == a;
        if (!ok) return make_error("Project resource '" + rel + "' is not exposed.", "Available: factoria.json, ENGINE_FEEDBACK.json, AGENTS.md. Use fs_read for other files.");
        auto path = resolve_project_path(projectDir, rel);
        if (!path.ok()) return path.error();
        std::ifstream in(path.value(), std::ios::binary);
        if (!in) return make_error("File '" + rel + "' does not exist in the project.", "Create it first.");
        std::ostringstream ss;
        ss << in.rdbuf();
        return McpResourceContent{std::string(uri), mime_for(rel), ss.str()};
    }
    return make_error("Unknown resource '" + std::string(uri) + "'.", "Use resources/list; URIs start with factoria://docs/ or factoria://project/.");
}

}  // namespace fa
