// Helpers shared by the CLI subcommands.
#pragma once

#include <filesystem>
#include <iosfwd>
#include <memory>
#include <string>
#include <vector>

#include "args.h"
#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/runtime/engine.h"

namespace fa::cli {

// ---- command table (each defined in its cmd_*.cpp) ----
Command make_new_command();
Command make_templates_command();
Command make_validate_command();
Command make_export_command();
Command make_editor_command();
Command make_run_command();
Command make_screenshot_command();
Command make_test_command();
Command make_call_command();
Command make_commands_command();
Command make_api_command();
Command make_mcp_command();
Command make_ai_command();
Command make_feedback_command();
Command make_docs_command();

// ---- output ----
void print_json(std::ostream& out, const Json& j);  // pretty, newline-terminated
// "error: message\n  hint: ..." on `err`; returns 1.
int report_failure(std::ostream& err, const std::string& message, const std::string& hint = {});

// ---- paths ----
std::string absolute_path(const std::string& path);  // relative to cwd, normalised
// Project directory for a command: positional `posIndex`, else --project, else the project
// containing the cwd. Throws CliError when none (or when `required` and it is not a project).
std::string resolve_project_dir(const Context& ctx, std::size_t posIndex, bool required = true);
// Same as above but returns "" instead of throwing when nothing is found and no path was given.
std::string find_project_dir_or_empty(const Context& ctx, std::size_t posIndex);
// Feedback file path of a project (honours factoria.json "feedbackFile").
std::string feedback_path(const std::string& projectDir);

// ---- engine sessions ----
enum class Gfx { Auto, None, Required };

struct SessionOptions {
    Gfx gfx = Gfx::Auto;  // Auto: headless GPU when available, else logic-only
    std::string scene;
    int width = 0, height = 0;
    u64 seed = 1;
    bool hotReload = false;
    // Headless sessions simulate every frame but only draw on screenshots (see RenderMode::OnDemand) and keep
    // `storage.*` in memory. `--render-all` / `--persist-storage` turn these off.
    RenderMode renderMode = RenderMode::OnDemand;
    bool memoryStorage = true;
};

// A headless Engine for a project (or, with an empty projectDir, a throw-away scratch project
// so that `commands`/`api` work anywhere). Commands of tooling/AI are NOT registered here.
class Session {
public:
    ~Session();
    Engine& engine() { return *engine_; }
    CommandRegistry& registry() { return engine_->commands(); }
    const std::string& project_dir() const { return projectDir_; }
    bool has_graphics() const { return graphics_; }
    bool scratch() const { return !scratchDir_.empty(); }

    static std::unique_ptr<Session> open(const std::string& projectDir, const SessionOptions& options);  // throws CliError

private:
    std::unique_ptr<Engine> engine_;
    std::string projectDir_;
    bool graphics_ = false;
    std::filesystem::path scratchDir_;
};

// Registers the full command set on `registry`: with an engine, register_project_commands (tooling, fs.*, docs.*,
// feedback.*, project.*) + ai.*; without one (no project: `factoria mcp` bootstrap) docs + project creation + ai.*.
// Session::open already registers the project commands, so this mostly adds ai.*.
void register_cli_commands(CommandRegistry& registry, const std::string& projectDir, Engine* engine);

// Runs tests/**/*.test.js on the engine's scripts.
TestReport run_project_tests(Engine& engine, const std::string& nameFilter);
// Kept for callers that validate through the process-wide hooks (project.validate is already engine-bound).
void install_script_check(Engine& engine);

// --- batch / session helpers (cmd_session.cpp) ---
// Runs `{"command": "...", "args": {...}}` on `registry`; returns {"ok":true,"result":...} or
// {"ok":false,"error":{code,message,hint}}.
Json run_command_json(CommandRegistry& registry, const Json& request);

}  // namespace fa::cli
