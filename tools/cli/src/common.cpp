#include "common.h"

#include <algorithm>
#include <iostream>
#if defined(_WIN32)
#include <process.h>  // _getpid
#else
#include <unistd.h>   // getpid
#endif

#include "fa/ai/commands.h"
#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/runtime/project.h"
#include "fa/tooling/tooling.h"

namespace fa::cli {

namespace fsys = std::filesystem;

void print_json(std::ostream& out, const Json& j) { out << j.dump(2) << "\n"; }

int report_failure(std::ostream& err, const std::string& message, const std::string& hint) {
    err << "error: " << message << "\n";
    if (!hint.empty()) err << "  hint: " << hint << "\n";
    return 1;
}

std::string absolute_path(const std::string& path) {
    std::error_code ec;
    fsys::path p = fsys::absolute(fsys::path(path), ec);
    if (ec) return path;
    return p.lexically_normal().string();
}

std::string resolve_input_path(const std::string& path, const std::string& projectDir, const std::string& what) {
    std::error_code ec;
    const fsys::path given(path);
    struct Tried {
        fsys::path candidate;
        std::string where;
    };
    std::vector<Tried> tried;
    if (given.is_absolute()) {
        tried.push_back({given.lexically_normal(), "absolute path"});
    } else {
        tried.push_back({fsys::absolute(given, ec).lexically_normal(), "relative to the current directory"});
        if (!projectDir.empty()) {
            fsys::path inProject = (fsys::path(projectDir) / given).lexically_normal();
            if (inProject != tried[0].candidate) tried.push_back({inProject, "relative to the project folder"});
        }
    }
    bool isFolder = false;
    for (const Tried& t : tried) {
        if (fsys::is_regular_file(t.candidate, ec)) return t.candidate.string();
        if (fsys::is_directory(t.candidate, ec)) isFolder = true;
    }
    std::string msg = "Cannot find " + what + " '" + path + "'" + (isFolder ? " (a folder of that name exists, but a file is needed)" : "") +
                      ". Looked in:";
    for (const Tried& t : tried) msg += "\n  - " + t.candidate.generic_string() + " (" + t.where + ")";  // '/' on every platform
    // A similarly named file next to where it was expected.
    std::string similar;
    std::vector<std::string> names;
    for (const Tried& t : tried) {
        const fsys::path dir = t.candidate.parent_path();
        if (!fsys::is_directory(dir, ec)) continue;
        for (const auto& entry : fsys::directory_iterator(dir, ec))
            if (entry.is_regular_file(ec)) names.push_back(entry.path().filename().string());
        std::sort(names.begin(), names.end());
        const std::string match = closest_match(t.candidate.filename().string(), names);
        if (!match.empty()) {
            similar = (given.has_parent_path() ? (given.parent_path() / match) : fsys::path(match)).generic_string();
            break;
        }
    }
    std::string hint = given.is_absolute() ? "Check the path." :
                       "A relative path is looked up in the current directory first, then in the project folder; pass an absolute path to be explicit.";
    if (!similar.empty()) hint += " Did you mean '" + similar + "'?";
    throw UsageError(msg, hint);
}

std::string find_project_dir_or_empty(const Context& ctx, std::size_t posIndex) {
    std::string given = ctx.args.pos(posIndex);
    if (given.empty()) given = ctx.args.str("project");
    if (!given.empty()) {
        std::string abs = absolute_path(given);
        while (abs.size() > 1 && (abs.back() == '/' || abs.back() == '\\')) abs.pop_back();
        return abs;
    }
    std::error_code ec;
    return find_project_root(fsys::current_path(ec).string());
}

std::string resolve_project_dir(const Context& ctx, std::size_t posIndex, bool required) {
    std::string dir = find_project_dir_or_empty(ctx, posIndex);
    if (dir.empty()) {
        if (!required) return {};
        throw CliError("No FactorIA project found: no " + std::string(kProjectFileName) +
                           " in the current directory or any parent.",
                       "Pass the project folder (factoria " + ctx.cmdPath + " path/to/game), use --project, or create one with 'factoria new <dir>'.");
    }
    std::error_code ec;
    if (!fsys::exists(fsys::path(dir) / kProjectFileName, ec)) {
        throw CliError("'" + dir + "' is not a FactorIA project: " + kProjectFileName + " not found.",
                       fsys::is_directory(dir, ec) ? "Create one with 'factoria new " + dir + "', or pass the folder that contains " + kProjectFileName + "."
                                                   : "The directory does not exist. Create it with 'factoria new " + dir + "'.");
    }
    return dir;
}

std::string feedback_path(const std::string& projectDir) {
    std::string file = kFeedbackFileName;
    auto ps = load_project(projectDir);
    if (ps.ok() && !ps->feedbackFile.empty()) file = ps->feedbackFile;
    return (fsys::path(projectDir) / file).string();
}

// ---------------------------------------------------------------------------
// Session
// ---------------------------------------------------------------------------

Session::~Session() {
    if (engine_) engine_->shutdown();
    engine_.reset();
    if (!scratchDir_.empty()) {
        std::error_code ec;
        fsys::remove_all(scratchDir_, ec);
    }
}

std::unique_ptr<Session> Session::open(const std::string& projectDirIn, const SessionOptions& opt) {
    auto s = std::make_unique<Session>();
    s->projectDir_ = projectDirIn;
    if (projectDirIn.empty()) {
        std::error_code ec;
        s->scratchDir_ = fsys::temp_directory_path(ec) / ("factoria-scratch-" + std::to_string(
#if defined(_WIN32)
                                                                       ::_getpid()
#else
                                                                       ::getpid()
#endif
                                                                           ));
        fsys::remove_all(s->scratchDir_, ec);
        auto made = create_project(s->scratchDir_.string(), "2d-empty", {});
        if (!made.ok()) throw CliError("Cannot create scratch project: " + made.error().message, made.error().hint);
        s->projectDir_ = s->scratchDir_.string();
    }
    fs::set_project_root(s->projectDir_);

    EngineConfig cfg;
    cfg.projectDir = s->projectDir_;
    cfg.scene = opt.scene;
    cfg.headless = true;
    cfg.audioDevice = false;
    cfg.width = opt.width;
    cfg.height = opt.height;
    cfg.seed = opt.seed;
    cfg.hotReload = opt.hotReload;
    cfg.renderMode = opt.renderMode;
    cfg.memoryStorage = opt.memoryStorage;

    std::string firstError;
    if (opt.gfx != Gfx::None) {
        cfg.graphics = true;
        auto e = std::make_unique<Engine>();
        std::string err;
        if (e->init(cfg, nullptr, &err)) {
            s->engine_ = std::move(e);
            s->graphics_ = true;
            register_project_commands(*s->engine_, s->projectDir_);
            return s;
        }
        firstError = err;
        e->shutdown();
        if (opt.gfx == Gfx::Required)
            throw CliError("Cannot start the engine with graphics: " + err,
                           "Screenshots need a GPU (headless EGL works with Mesa llvmpipe; windowed code: xvfb-run -a factoria ...).");
    }
    cfg.graphics = false;
    auto e = std::make_unique<Engine>();
    std::string err;
    if (!e->init(cfg, nullptr, &err)) {
        e->shutdown();
        throw CliError("Cannot load project '" + s->projectDir_ + "': " + err,
                       "Run 'factoria validate' to see every problem in the project.");
    }
    if (!firstError.empty())
        FA_WARN("cli", "No GPU available ({}); running without graphics (screenshots are disabled).", firstError);
    s->engine_ = std::move(e);
    register_project_commands(*s->engine_, s->projectDir_);
    return s;
}

// ---------------------------------------------------------------------------
// Commands shared by `call`, `mcp` and `ai run`
// ---------------------------------------------------------------------------

TestReport run_project_tests(Engine& engine, const std::string& nameFilter) {
    std::vector<std::string> files;
    for (const auto& f : fs::list("tests", true, ".js"))
        if (ends_with(f, ".test.js")) files.push_back(f);
    std::sort(files.begin(), files.end());
    if (files.empty()) return {};
    return engine.scripts().run_tests(files, nameFilter);
}

void install_script_check(Engine& engine) {
    Engine* e = &engine;
    set_script_check_hook([e](const std::string&, const std::string& scriptPath) {
        std::vector<ValidationIssue> issues;
        auto r = e->scripts().check_syntax(scriptPath);
        if (!r.ok()) {
            ValidationIssue i;
            i.file = scriptPath;
            i.message = "Syntax error: " + r.error().message;
            i.hint = r.error().hint.empty() ? "Fix the script; 'factoria call script.eval' can test snippets." : r.error().hint;
            issues.push_back(std::move(i));
        }
        return issues;
    });
}

void register_cli_commands(CommandRegistry& registry, const std::string& projectDir, Engine* engine) {
    if (engine) {
        if (!registry.has("project.create")) register_project_commands(*engine, projectDir);
    } else {
        register_docs_commands(registry);
        register_api_export_commands(registry);
        CommandInfo info;
        info.name = "project.templates";
        info.summary = "List the project templates `project.create` can start from.";
        info.description = "Returns [{name, description, dimension}]. Example: {}.";
        info.category = "project";
        registry.add(info, [](const Json&) {
            Json arr = Json::array();
            for (const auto& t : list_templates())
                arr.push_back(Json::object({{"name", t.name}, {"description", t.description}, {"dimension", t.dimension}}));
            return arr;
        });
        CommandInfo ci;
        ci.name = "project.create";
        ci.summary = "Create a new game project from a template.";
        ci.description =
            "Creates `dir` (relative to the server's working directory unless absolute) with factoria.json, a scene, "
            "scripts, a test, AGENTS.md, ENGINE_FEEDBACK.json and the real types/factoria.d.ts. Afterwards start "
            "`factoria mcp --project <dir>` to work on it. Example: {\"dir\":\"my-game\",\"template\":\"2d-platformer\",\"name\":\"My Game\"}.";
        ci.readOnly = false;
        ci.category = "project";
        ci.inputSchema = Json::parse(R"({
          "type":"object","required":["dir"],
          "properties":{
            "dir":{"type":"string","description":"Target folder (created; must be empty or new)."},
            "template":{"type":"string","description":"2d-empty, 2d-platformer or 3d-empty (see project.templates).","default":"2d-empty"},
            "name":{"type":"string","description":"Display name (default: folder name)."},
            "id":{"type":"string","description":"Reverse-DNS id, e.g. com.example.mygame."}
          }})");
        registry.add(ci, [](const Json& a) {
            ScaffoldOptions o;
            o.name = a.value("name", std::string());
            o.id = a.value("id", std::string());
            auto r = create_project(absolute_path(a.at("dir").get<std::string>()), a.value("template", std::string("2d-empty")), o);
            if (!r.ok()) throw CommandError("failed", r.error().message, r.error().hint);
            return r->to_json();
        });
    }
    ai::AiCommandOptions ao;
    ao.projectDir = [projectDir]() { return projectDir; };
    ai::register_ai_commands(registry, ao);
}

Json run_command_json(CommandRegistry& registry, const Json& request) {
    auto fail = [](const std::string& code, const std::string& msg, const std::string& hint) {
        Json e = Json::object({{"code", code}, {"message", msg}});
        if (!hint.empty()) e["hint"] = hint;
        return Json::object({{"ok", false}, {"error", e}});
    };
    if (!request.is_object() || !request.contains("command") || !request["command"].is_string())
        return fail("invalid_request", "A request must be {\"command\": \"name\", \"args\": {...}}.",
                    "Example: {\"command\":\"game.step\",\"args\":{\"frames\":30}}");
    Json args = request.contains("args") ? request["args"] : Json::object();
    if (args.is_null()) args = Json::object();
    if (!args.is_object()) return fail("invalid_request", "'args' must be a JSON object.", "");
    CommandResult r = registry.call(request["command"].get<std::string>(), args);
    if (!r.ok) return Json::object({{"ok", false}, {"error", r.error}});
    return Json::object({{"ok", true}, {"result", r.result}});
}

}  // namespace fa::cli
