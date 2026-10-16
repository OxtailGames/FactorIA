// new, templates, validate, export, editor
#include <algorithm>
#include <filesystem>
#include <fstream>
#include <iostream>

#include "common.h"
#include "fa/core/strings.h"
#include "fa/runtime/project.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/tooling.h"
#include "fa/tooling/validate.h"

#if __has_include("fa/tooling/export.h")
#include "fa/tooling/export.h"
#define FA_CLI_HAVE_EXPORT 1
#endif
#if defined(FA_WITH_EDITOR) && __has_include("fa/editor/editor.h")
#include "fa/editor/editor.h"
#define FA_CLI_HAVE_EDITOR 1
#endif

namespace fa::cli {

namespace fsys = std::filesystem;

Command make_new_command() {
    Command c;
    c.name = "new";
    c.summary = "Create a new game project from a template.";
    c.usage = "<dir> [--template T] [--name NAME] [--id ID]";
    c.details =
        "Creates <dir> with factoria.json, a first scene, a script, a test, project tools, AGENTS.md/CLAUDE.md (the guide\n"
        "for AI agents), ENGINE_FEEDBACK.json, the real script typings (types/factoria.d.ts) and a .mcp.json that connects\n"
        "Claude Code to 'factoria mcp'.";
    c.maxPositional = 1;
    c.flags = {{"template", "NAME", "Template: 2d-empty (default), 2d-platformer, 3d-empty. See 'factoria templates'."},
               {"name", "NAME", "Display name (default: the folder name)."},
               {"id", "ID", "Reverse-DNS id, e.g. com.example.mygame (default: com.example.<slug>)."},
               {"force", "", "Allow a non-empty target folder (overwrites template files, keeps the rest)."},
               {"json", "", "Print the created files as JSON."}};
    c.examples = {"factoria new my-game", "factoria new platformer --template 2d-platformer --name \"Pixel Hop\"",
                  "factoria new space --template 3d-empty --id com.acme.space --json"};
    c.run = [](Context& ctx) {
        if (ctx.args.positional().empty()) throw UsageError("Missing project folder.", "Usage: factoria new <dir> [--template T]");
        std::string tmpl = ctx.args.str("template", "2d-empty");
        std::vector<std::string> names;
        for (const auto& t : list_templates()) names.push_back(t.name);
        if (std::find(names.begin(), names.end(), tmpl) == names.end())
            throw UsageError("Unknown template '" + tmpl + "'.", fa::did_you_mean(tmpl, names));
        ScaffoldOptions o;
        o.name = ctx.args.str("name");
        o.id = ctx.args.str("id");
        o.force = ctx.args.has("force");
        auto r = create_project(absolute_path(ctx.args.pos(0)), tmpl, o);
        if (!r.ok()) return report_failure(ctx.err, r.error().message, r.error().hint);
        if (ctx.args.has("json")) {
            print_json(ctx.out, r->to_json());
            return 0;
        }
        ctx.out << "Created " << tmpl << " project in " << r->dir << " (" << r->files.size() << " files)\n\n"
                << "Next steps:\n"
                << "  cd " << ctx.args.pos(0) << "\n"
                << "  factoria validate                      # check the project\n"
                << "  factoria test                          # run tests/*.test.js headless\n"
                << "  factoria run                           # play it (window)\n"
                << "  factoria run --headless --frames 120 --screenshot-at 60   # AI-friendly: PNG without a window\n"
                << "  factoria mcp                           # let an AI drive it (see .mcp.json)\n"
                << "AI agents: read AGENTS.md first.\n";
        return 0;
    };
    return c;
}

Command make_templates_command() {
    Command c;
    c.name = "templates";
    c.summary = "List the project templates.";
    c.flags = {{"json", "", "Machine-readable output."}};
    c.examples = {"factoria templates", "factoria templates --json"};
    c.run = [](Context& ctx) {
        auto ts = list_templates();
        if (ctx.args.has("json")) {
            Json arr = Json::array();
            for (const auto& t : ts)
                arr.push_back(Json::object({{"name", t.name}, {"description", t.description}, {"dimension", t.dimension}}));
            print_json(ctx.out, arr);
            return 0;
        }
        for (const auto& t : ts) ctx.out << t.name << "  [" << t.dimension << "]\n    " << t.description << "\n";
        return 0;
    };
    return c;
}

Command make_validate_command() {
    Command c;
    c.name = "validate";
    c.summary = "Check factoria.json, scenes, prefabs, assets, scripts (syntax) and ENGINE_FEEDBACK.json.";
    c.usage = "[project] [--json]";
    c.details = "Every message names the file, the JSON pointer, what is wrong and how to fix it. Exit code 1 if any error.";
    c.maxPositional = 1;
    c.flags = {{"project", "DIR", "Project folder (alternative to the positional argument)."},
               {"no-scenes", "", "Skip loading scenes (faster)."},
               {"fix-types", "", "Also regenerate types/factoria.d.ts from the engine's script API."},
               {"json", "", "Machine-readable report."}};
    c.examples = {"factoria validate", "factoria validate games/my-game --json"};
    c.run = [](Context& ctx) {
        std::string dir = resolve_project_dir(ctx, 0);
        // Script syntax and Script.props go through a logic-only engine; if the project cannot even load, scripts
        // are skipped and the scene/project errors below explain why.
        std::unique_ptr<Session> session;
        std::string engineProblem;
        try {
            SessionOptions so;
            so.gfx = Gfx::None;
            session = Session::open(dir, so);
        } catch (const CliError& e) {
            engineProblem = e.what();
        }
        ValidateOptions vo = session ? engine_validate_options(session->engine()) : ValidateOptions{};
        vo.checkScenes = !ctx.args.has("no-scenes");
        ValidationReport rep = validate_project(dir, vo);
        if (!engineProblem.empty()) {
            ValidationIssue w;
            w.file = "scripts";
            w.message = "Script syntax was not checked: the engine could not load the project (" + engineProblem + ").";
            w.hint = "Fix the errors above first.";
            rep.warnings.push_back(w);
        }
        if (ctx.args.has("fix-types")) {
            if (!session) return report_failure(ctx.err, "Cannot regenerate typings: " + engineProblem);
            std::string text = session->engine().scripts().typescript_declarations();
            std::string path = (fsys::path(dir) / "types" / "factoria.d.ts").string();
            std::error_code ec;
            fsys::create_directories(fsys::path(path).parent_path(), ec);
            std::ofstream f(path, std::ios::binary);
            if (!f) return report_failure(ctx.err, "Cannot write " + path);
            f << text;
            f.close();
            // The placeholder warning is moot now.
            rep.warnings.erase(std::remove_if(rep.warnings.begin(), rep.warnings.end(),
                                              [](const ValidationIssue& i) { return i.file == "types/factoria.d.ts"; }),
                               rep.warnings.end());
            if (!ctx.args.has("json")) ctx.out << "Wrote " << path << " (" << text.size() << " bytes)\n";
        }
        if (ctx.args.has("json")) {
            print_json(ctx.out, rep.to_json());
        } else {
            ctx.out << rep.to_text();
            if (rep.ok) ctx.out << "OK: " << dir << "\n";
        }
        return rep.ok ? 0 : 1;
    };
    return c;
}

Command make_export_command() {
    Command c;
    c.name = "export";
    c.summary = "Package the game for a platform (desktop bundle, Android/iOS project).";
    c.usage = "[project] [--platform P] [--out DIR] [--release]";
    c.maxPositional = 1;
    c.flags = {{"project", "DIR", "Project folder (alternative to the positional argument)."},
               {"platform", "P", "linux, windows, macos, android or ios (default: this machine)."},
               {"out", "DIR", "Parent folder; the export lands in <out>/<slug>-<platform>/, replaced only when an export wrote it (default out: <project>/build/export)."},
               {"release", "", "Release build (assets packed, no dev tools)."},
               {"engine-root", "DIR", "Android/iOS: compile the engine from this source checkout (\"source\" mode; default: $FACTORIA_ENGINE_DIR, else the prebuilt players, else the build-time source root)."},
               {"mobile-dir", "DIR", "Android/iOS: the prebuilt players (\"prebuilt\" mode; default: the mobile/ folder next to factoria)."},
               {"player", "PATH", "factoria_player binary to bundle (default: the one shipped next to factoria)."},
               {"json", "", "Machine-readable report."}};
    c.examples = {"factoria export --platform linux --release", "factoria export games/my-game --platform android --out dist/android"};
    c.run = [](Context& ctx) {
        std::string dir = resolve_project_dir(ctx, 0);
        std::string platform = ctx.args.str("platform");
        if (!platform.empty()) {
            std::string norm = normalize_export_platform(platform);
            if (norm.empty()) {
                const std::vector<std::string> platforms = {"linux", "windows", "macos", "android", "ios"};
                throw UsageError("Unknown platform '" + platform + "'.", fa::did_you_mean(platform, platforms));
            }
            platform = norm;
        }
#ifdef FA_CLI_HAVE_EXPORT
        ExportOptions eo;
        eo.projectDir = dir;
        eo.platform = platform;
        eo.outDir = ctx.args.has("out") ? absolute_path(ctx.args.str("out")) : "";
        eo.release = ctx.args.has("release");
        eo.engineRoot = ctx.args.has("engine-root") ? absolute_path(ctx.args.str("engine-root")) : "";
        eo.mobileDir = ctx.args.has("mobile-dir") ? absolute_path(ctx.args.str("mobile-dir")) : "";
        eo.playerBinary = ctx.args.has("player") ? absolute_path(ctx.args.str("player")) : "";
        auto r = export_project(eo);
        if (!r.ok()) return report_failure(ctx.err, r.error().message, r.error().hint);
        if (ctx.args.has("json")) {
            print_json(ctx.out, r->to_json());
            return 0;
        }
        ctx.out << "Exported " << (platform.empty() ? "host" : platform) << " build to " << r->outputDir << " (" << r->files.size() << " files"
                << (r->mode.empty() ? "" : ", mode: " + r->mode) << ")\n";
        for (const auto& w : r->warnings) ctx.out << "warning: " << w << "\n";
        if (!r->nextSteps.empty()) ctx.out << "Next steps:\n";
        for (std::size_t i = 0; i < r->nextSteps.size(); ++i) ctx.out << "  " << (i + 1) << ". " << r->nextSteps[i] << "\n";
        return 0;
#else
        return report_failure(ctx.err, "Export is not available in this build of factoria.",
                              "Rebuild with the export module (tools/common export.h) enabled.");
#endif
    };
    return c;
}

Command make_editor_command() {
    Command c;
    c.name = "editor";
    c.summary = "Open the visual editor on a project.";
    c.usage = "[project]";
    c.details = "Without a project (none in the current directory) the editor shows its Open/New project dialog.";
    c.maxPositional = 1;
    c.flags = {{"project", "DIR", "Project folder (alternative to the positional argument)."}};
    c.examples = {"factoria editor", "factoria editor games/my-game"};
    c.run = [](Context& ctx) {
#ifdef FA_CLI_HAVE_EDITOR
        EditorOptions eo;
        eo.projectDir = resolve_project_dir(ctx, 0, false);
        return run_editor(eo);
#else
        (void)ctx;
        return report_failure(ctx.err, "This build of factoria has no editor.",
                              "Rebuild with -DFA_BUILD_EDITOR=ON (desktop), or use 'factoria run' and 'factoria mcp'.");
#endif
    };
    return c;
}

}  // namespace fa::cli
