// new, templates, validate, export, editor
#include <algorithm>
#include <cctype>
#include <filesystem>
#include <fstream>
#include <iostream>

#include "common.h"
#include "fa/core/strings.h"
#include "fa/runtime/project.h"
#include "fa/tooling/api_export.h"
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
        if (!r.ok()) return report_failure(ctx, r.error().message, r.error().hint);
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
            if (!session) return report_failure(ctx, "Cannot regenerate typings: " + engineProblem);
            std::string text = export_typescript(session->engine().scripts());
            std::string path = (fsys::path(dir) / "types" / "factoria.d.ts").string();
            std::error_code ec;
            fsys::create_directories(fsys::path(path).parent_path(), ec);
            std::ofstream f(path, std::ios::binary);
            if (!f) return report_failure(ctx, "Cannot write " + path);
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
    c.summary = "Package the game for a platform (desktop bundle, Android APK/AAB, iOS project, web page).";
    c.usage = "[project] [--platform P] [--format apk|aab|gradle|appimage|msix|folder] [--out DIR] [--release [--allow-debug-key]] [--allow-player-mismatch] [--allow-missing-plugins]";
    c.maxPositional = 1;
    c.flags = {{"project", "DIR", "Project folder (alternative to the positional argument)."},
               {"platform", "P", "linux, windows, macos, android, ios or web (default: this machine). web writes <out>/<slug>-web/ (index.html, the web player, game.pak) and <out>/<slug>-web.zip, the file to upload to itch.io as an HTML5 game."},
               {"out", "DIR", "Parent folder; the export lands in <out>/<slug>-<platform>/, replaced only when an export wrote it (default out: <project>/build/export)."},
               {"format", "FORMAT", "Android: apk (default; built with Gradle), aab (the Google Play bundle) or gradle (only write the Gradle project, no JDK or SDK needed). Default: export.android.format of factoria.json, else apk. Linux: appimage also builds <slug>-x86_64.AppImage, the game as one file (needs Linux x86_64 or WSL and `factoria setup appimage`). Windows: msix also writes <slug>-windows.msix, the Microsoft Store package (any host; identity in export.windows.msix of factoria.json); folder writes only the export folder. Default: export.windows.format, else folder."},
               {"release", "", "Release build. Android: the release APK/AAB, signed with export.android.signing (passwords from FACTORIA_ANDROID_KEYSTORE_PASSWORD / FACTORIA_ANDROID_KEY_PASSWORD or ~/.factoria/export.json); without a keystore it is an error unless --allow-debug-key is given. Linux, Windows, macOS: the whole game in ONE file, game.pak, next to the executable instead of a game/ folder, with the scripts compiled to bytecode (export.scriptBytecode: false in factoria.json keeps them as source)."},
               {"allow-debug-key", "", "Android --release without export.android.signing: sign with the debug key instead of failing. Fine for trying the build on your own device; Google Play rejects it, so never upload that build."},
               {"allow-missing-plugins", "", "Leave out a native plugin whose build for the target platform is missing, instead of stopping the export. A warning names each one and the result lists them (pluginsLeftOut). The game runs without the plugin; scripts that call it fail unless the plugin is \"optional\" in factoria.json and they check for it."},
               {"allow-player-mismatch", "", "Bundle the player (desktop, web, or the prebuilt Android and iOS libraries) even when it was built from another commit than this factoria (its build fingerprint differs or is missing). Without it the export stops with an error: an old player may lack what the game uses or fail to start. Rebuild both from one checkout instead when you can."},
               {"engine-root", "DIR", "Android/iOS: compile the engine from this source checkout (\"source\" mode; default: $FACTORIA_ENGINE_DIR, else the prebuilt players, else the build-time source root)."},
               {"mobile-dir", "DIR", "Android/iOS: the prebuilt players (\"prebuilt\" mode; default: the mobile/ folder next to factoria)."},
               {"player", "PATH", "factoria_player binary to bundle (default: the one shipped next to factoria). web: the folder with factoria_player.js and factoria_player.wasm (default: web/ next to factoria, else the one `factoria setup players --platforms web` installed, else a web build of the source)."},
               {"json", "", "Machine-readable report."}};
    c.examples = {"factoria export --platform linux --release", "factoria export games/my-game --platform android --out dist/android",
                  "factoria export --platform android --format aab --release", "factoria export --platform android --format gradle", "factoria export --platform linux --format appimage", "factoria export --platform windows --format msix",
                  "factoria export --platform web"};
    c.run = [](Context& ctx) {
        std::string dir = resolve_project_dir(ctx, 0);
        std::string platform = ctx.args.str("platform");
        if (!platform.empty()) {
            std::string norm = normalize_export_platform(platform);
            if (norm.empty()) {
                const std::vector<std::string> platforms = {"linux", "windows", "macos", "android", "ios", "web"};
                throw UsageError("Unknown platform '" + platform + "'.", fa::did_you_mean(platform, platforms));
            }
            platform = norm;
        }
#ifdef FA_CLI_HAVE_EXPORT
        ExportOptions eo;
        eo.projectDir = dir;
        eo.platform = platform;
        eo.format = ctx.args.str("format");
        if (!eo.format.empty()) {
            std::string f;
            for (char ch : eo.format) f += static_cast<char>(std::tolower(static_cast<unsigned char>(ch)));
            const std::vector<std::string> formats = {"apk", "aab", "gradle", "appimage", "msix", "folder"};
            if (std::find(formats.begin(), formats.end(), f) == formats.end())
                throw UsageError("Unknown format '" + eo.format + "'.", fa::did_you_mean(eo.format, formats));
            eo.format = f;
        }
        eo.outDir = ctx.args.has("out") ? absolute_path(ctx.args.str("out")) : "";
        eo.release = ctx.args.has("release");
        eo.allowDebugKey = ctx.args.has("allow-debug-key");
        eo.allowPlayerMismatch = ctx.args.has("allow-player-mismatch");
        eo.allowMissingPlugins = ctx.args.has("allow-missing-plugins");
        // A long step (the Gradle build of an Android export) shows its output as it goes; --json keeps the output clean
        // (the same lines are in <export folder>/build.log).
        if (!ctx.args.has("json")) eo.progress = [&ctx](const std::string& line) { ctx.err << line << std::endl; };
        eo.engineRoot = ctx.args.has("engine-root") ? absolute_path(ctx.args.str("engine-root")) : "";
        eo.mobileDir = ctx.args.has("mobile-dir") ? absolute_path(ctx.args.str("mobile-dir")) : "";
        eo.playerBinary = ctx.args.has("player") ? absolute_path(ctx.args.str("player")) : "";
        auto r = export_project(eo);
        if (!r.ok()) return report_failure(ctx, r.error().message, r.error().hint);
        if (ctx.args.has("json")) {
            print_json(ctx.out, r->to_json());
            return 0;
        }
        ctx.out << "Exported " << (platform.empty() ? "host" : platform) << " build to " << r->outputDir << " (" << r->files.size() << " files"
                << (r->mode.empty() ? "" : ", mode: " + r->mode) << (r->format.empty() ? "" : ", format: " + r->format) << ")\n";
        if (!r->artifact.empty()) ctx.out << "Built " << r->artifact << "\n";
        if (!r->materials.empty()) ctx.out << "Compiled the shaders of " << r->materials.size() << " material(s): " << fa::join(r->materials, ", ") << "\n";
        for (const auto& w : r->warnings) ctx.out << "warning: " << w << "\n";
        if (!r->nextSteps.empty()) ctx.out << "Next steps:\n";
        for (std::size_t i = 0; i < r->nextSteps.size(); ++i) ctx.out << "  " << (i + 1) << ". " << r->nextSteps[i] << "\n";
        return 0;
#else
        return report_failure(ctx, "Export is not available in this build of factoria.",
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
        return report_failure(ctx, "This build of factoria has no editor.",
                              "Rebuild with -DFA_BUILD_EDITOR=ON (desktop), or use 'factoria run' and 'factoria mcp'.");
#endif
    };
    return c;
}

}  // namespace fa::cli
