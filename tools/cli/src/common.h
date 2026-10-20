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
Command make_setup_command();
Command make_editor_command();
Command make_run_command();
Command make_screenshot_command();
Command make_test_command();
Command make_call_command();
Command make_session_command();
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
// The same, and when the command runs with --json also {"ok": false, "error": {code, message, hint}} on stdout, so that
// whoever parses stdout always gets an object (docs/CLI.md). Commands use this one.
int report_failure(const Context& ctx, const std::string& message, const std::string& hint = {});
void print_json_error(std::ostream& out, const std::string& code, const std::string& message, const std::string& hint);

// ---- paths ----
// Rule for every file path given to a CLI option (documented in docs/CLI.md, "Paths"):
//   INPUT files (--input, @args.json, --batch-file): an absolute path is used as it is; a relative one is looked up in
//     the current directory first (an existing file there wins), then in the project folder. resolve_input_path.
//   OUTPUT files (--state-out, --screenshot-pattern, --record-audio, --out): a relative path is relative to the
//     current directory, like any shell tool; the result reports the absolute path written. absolute_path.
//   The defaults of outputs live in the project (<project>/.factoria/...). Paths INSIDE engine commands (--scene, the
//   `path` argument of scene.load, game.screenshot...) are project-relative: that is the engine's VFS, not the shell's.
std::string absolute_path(const std::string& path);  // relative to cwd, normalised
// Finds the file named by an input option: absolute as is, else cwd then `projectDir` (skipped when empty). Throws a
// UsageError listing every location tried (and a close file name, if any) when none is a file. `what` names the
// file in the message, e.g. "the --input file".
std::string resolve_input_path(const std::string& path, const std::string& projectDir, const std::string& what);
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
// `testFiles`: files, folders or globs relative to the project (empty: every tests/**/*.test.js); throws CliError for a path
// that is not a test file.
TestReport run_project_tests(Engine& engine, const std::string& nameFilter, const std::vector<std::string>& testFiles = {});

// --- batch / session helpers (cmd_session.cpp) ---
// Runs `{"command": "...", "args": {...}}` on `registry`; returns {"ok":true,"result":...} or
// {"ok":false,"error":{code,message,hint}}.
Json run_command_json(CommandRegistry& registry, const Json& request);

}  // namespace fa::cli
