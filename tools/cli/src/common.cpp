#include "common.h"

#include <algorithm>
#include <iostream>
#include <unistd.h>

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
        s->scratchDir_ = fsys::temp_directory_path(ec) / ("factoria-scratch-" + std::to_string(::getpid()));
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

    std::string firstError;
    if (opt.gfx != Gfx::None) {
        cfg.graphics = true;
        auto e = std::make_unique<Engine>();
        std::string err;
        if (e->init(cfg, nullptr, &err)) {
            s->engine_ = std::move(e);
            s->graphics_ = true;
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
    if (!projectDir.empty()) {
        register_tooling_commands(registry, projectDir);
    } else {
        register_docs_commands(registry);
        register_api_export_commands(registry);
    }

    {
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
    }
    {
        CommandInfo info;
        info.name = "project.create";
        info.summary = "Create a new game project from a template.";
        info.description =
            "Creates `dir` (relative to the server's working directory unless absolute) with factoria.json, a scene, "
            "scripts, a test, AGENTS.md and ENGINE_FEEDBACK.json. Afterwards start `factoria mcp --project <dir>` "
            "to work on it. Example: {\"dir\":\"my-game\",\"template\":\"2d-platformer\",\"name\":\"My Game\"}.";
        info.readOnly = false;
        info.category = "project";
        info.inputSchema = Json::parse(R"({
          "type":"object","required":["dir"],
          "properties":{
            "dir":{"type":"string","description":"Target folder (created; must be empty or new)."},
            "template":{"type":"string","description":"2d-empty, 2d-platformer or 3d-empty (see project.templates).","default":"2d-empty"},
            "name":{"type":"string","description":"Display name (default: folder name)."},
            "id":{"type":"string","description":"Reverse-DNS id, e.g. com.example.mygame."}
          }})");
        registry.add(info, [](const Json& a) {
            ScaffoldOptions o;
            o.name = a.value("name", std::string());
            o.id = a.value("id", std::string());
            auto r = create_project(absolute_path(a.at("dir").get<std::string>()), a.value("template", std::string("2d-empty")), o);
            if (!r.ok()) throw CommandError("failed", r.error().message, r.error().hint);
            return r->to_json();
        });
    }
    if (engine && !registry.has("project.test")) {
        CommandInfo info;
        info.name = "project.test";
        info.summary = "Run the project's tests (tests/**/*.test.js) headless and report each case.";
        info.description =
            "Returns {ok, passed, failed, cases[{file,name,passed,message,milliseconds}], loadErrors[]}. "
            "Use `filter` to run only tests whose name contains the text. Example: {\"filter\":\"jump\"}.";
        info.category = "project";
        info.inputSchema = Json::parse(R"({"type":"object","properties":{"filter":{"type":"string","description":"Only run tests whose name contains this text."}}})");
        registry.add(info, [engine](const Json& a) {
            TestReport rep = run_project_tests(*engine, a.value("filter", std::string()));
            Json j = rep.to_json();
            if (!j.contains("ok")) j["ok"] = rep.ok();
            return j;
        });
    }

    ai::AiCommandOptions ao;
    ao.projectDir = [projectDir]() { return projectDir; };
    ai::register_ai_commands(registry, ao);
}

}  // namespace fa::cli
