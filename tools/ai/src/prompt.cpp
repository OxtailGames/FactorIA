// System prompt for the built-in agent: engine guide summary + project context + rules.
#include <algorithm>
#include <filesystem>
#include <fstream>
#include <sstream>

#include "fa/ai/session.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::ai {

namespace fsys = std::filesystem;
using namespace util;

namespace {

constexpr const char* kGuide = R"(# FactorIA engine guide (summary)
FactorIA is an AI-native C++20 2D/3D game engine. Everything is text: projects, scenes and prefabs are JSON
(validated by JSON Schemas), gameplay is JavaScript (QuickJS) in scripts/*.js, project-specific tools are
tools/*.js. Every capability is a command exposed to you as a tool (the tool name is the command name with
'.' replaced by '_', e.g. scene.spawn -> scene_spawn). Errors tell you where, what and how to fix it.
Conventions: right-handed, +Y up, angles in degrees, colors 0..1, 2D units are design pixels, 3D units are
meters. JSON keys are camelCase. The simulation is deterministic: headless runs with a seed and input
replays always give the same result.
Use the docs_* and api_* tools (when present) to read the engine docs and the component reference before
guessing field names.)";

constexpr const char* kRules = R"(# Rules
1. Inspect before you change: list the project files and read the relevant docs/components first.
2. After every meaningful change run project_validate and fix every error it reports.
3. Verify behaviour: run the game headlessly (game_* tools), step frames, read logs and state dumps, and LOOK at
   screenshots (game_screenshot) to check visuals. Do not claim something works without having run it.
4. Write tests for gameplay logic (JavaScript tests in the project) and run them.
5. Keep edits inside the project directory. Prefer the dedicated tools over raw file edits when one exists.
6. ALWAYS record engine gaps with feedback_report before finishing: whenever the engine lacked a feature, an
   error was confusing, or you needed a workaround, add an entry (what was missing, workaround, suggestion).
7. Finish with a short summary: what you changed, how you verified it, open problems.)";

// %TOOL% = the delegation tool: agent_delegate (built-in loop) or ai_run (CLI agents, through the FactorIA MCP server).
constexpr const char* kOrchestrator = R"(# Your role: orchestrator
You plan the work and delegate. Use %TOOL% {role, task} to hand self-contained implementation tasks to
the "worker" role (default for coding) or tiny mechanical edits to the "fast" role: they run the models the user
chose for those roles, so prefer them over doing the work yourself or over sub-agents of your own. Answer
questions and tiny one-step changes yourself. Give each delegated task all the context it needs (file paths,
acceptance criteria): the sub-agent does not see this conversation. It returns its final report as the tool
result. Review results yourself (run project_validate, screenshots) before finishing.

%TOOL% blocks until the sub-agent has finished, which can take many minutes, while the user watches its progress
live. Just wait for the result: it comes back as the tool result. Never end your turn promising to continue or to
be notified later (nothing wakes you up), and never wait for a sub-agent with Bash (sleep, polling loops, background
processes).)";

std::string read_head(const fsys::path& p, std::size_t maxBytes) {
    std::ifstream f(p, std::ios::binary);
    if (!f) return {};
    std::string s(maxBytes, '\0');
    f.read(s.data(), static_cast<std::streamsize>(maxBytes));
    s.resize(static_cast<std::size_t>(f.gcount()));
    return s;
}

std::string file_listing(const fsys::path& root, std::size_t maxEntries) {
    std::vector<std::string> files;
    std::error_code ec;
    for (auto it = fsys::recursive_directory_iterator(root, fsys::directory_options::skip_permission_denied, ec);
         it != fsys::recursive_directory_iterator(); it.increment(ec)) {
        if (ec) break;
        std::string name = it->path().filename().string();
        if (it->is_directory(ec)) {
            if (name.empty() || name[0] == '.' || name == "build" || name == "node_modules") it.disable_recursion_pending();
            continue;
        }
        if (!name.empty() && name[0] == '.') continue;
        files.push_back(fsys::relative(it->path(), root, ec).generic_string());
    }
    std::sort(files.begin(), files.end());
    std::string out;
    std::size_t n = 0;
    for (const auto& f : files) {
        if (n++ >= maxEntries) {
            out += "... (" + std::to_string(files.size() - maxEntries) + " more; use the file-listing tool)\n";
            break;
        }
        out += f + "\n";
    }
    return out;
}

std::string feedback_summary(const fsys::path& root) {
    std::string text = read_head(root / "ENGINE_FEEDBACK.json", 1u << 20);
    if (text.empty()) return "ENGINE_FEEDBACK.json: not found.";
    Json j = parse(text);
    const Json* entries = j.is_discarded() ? nullptr : child(j, "entries");
    if (!entries || !entries->is_array()) return "ENGINE_FEEDBACK.json: unreadable (fix it or run project_validate).";
    int open = 0;
    std::string titles;
    for (const auto& e : *entries) {
        if (str(e, "status", "open") == "open") {
            if (++open <= 10) titles += "- " + str(e, "id") + " [" + str(e, "severity") + "] " + str(e, "title") + "\n";
        }
    }
    std::string out = "ENGINE_FEEDBACK.json: " + std::to_string(entries->size()) + " entries, " + std::to_string(open) + " open.\n";
    out += titles;
    if (open > 10) out += "- ... and " + std::to_string(open - 10) + " more\n";
    return out;
}

}  // namespace

std::string build_system_prompt(const PromptContext& ctx) {
    std::string out = kGuide;
    out += "\n\n";
    out += kRules;
    out += "\n\n";
    if (ctx.canDelegate) {
        std::string role = kOrchestrator;
        const std::string tool = ctx.delegateTool.empty() ? kDelegateTool : ctx.delegateTool;
        for (std::size_t at; (at = role.find("%TOOL%")) != std::string::npos;) role.replace(at, 6, tool);
        out += role;
        out += "\n\n";
    } else if (ctx.role == kRoleWorker) {
        out += "# Your role: worker\nYou implement the task you were given completely and report concisely. You cannot delegate.\n\n";
    } else if (ctx.role == kRoleFast) {
        out += "# Your role: fast\nYou do small mechanical tasks quickly and report in a few lines. You cannot delegate.\n\n";
    }
    out += "# Project context\n";
    if (ctx.projectDir.empty()) {
        out += "No project directory is open.\n";
    } else {
        fsys::path root(ctx.projectDir);
        out += "Project directory: " + root.string() + "\n";
        std::string manifest = read_head(root / "factoria.json", 4000);
        if (!manifest.empty()) out += "\nfactoria.json:\n```json\n" + manifest + "\n```\n";
        out += "\nFiles:\n" + file_listing(root, 150);
        out += "\n" + feedback_summary(root) + "\n";
    }
    if (!ctx.extra.empty()) out += "\n" + ctx.extra + "\n";
    return out;
}

}  // namespace fa::ai
