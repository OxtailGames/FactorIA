// Uploading exports to stores: finding the exports and the store's tool, writing the build files, running the tool, the
// report and the publish.* commands. What each store's uploader is given is in publish_stores.cpp; the format of the
// "publish" section of factoria.json is in publish_settings.cpp. Behaviour: fa/tooling/publish.h, docs/EXPORTING.md.
#include "fa/tooling/publish.h"

#include <algorithm>
#include <deque>
#include <filesystem>
#include <fstream>

#include "export_internal.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/tooling/export.h"
#include "fa/tooling/project_fs.h"
#include "publish_internal.h"
#include "util.h"

namespace fa {

using namespace publish_detail;
using export_detail::fs_safe_name;
using export_detail::host_platform;

namespace {

// A command line as a person would type it (arguments with spaces or quotes are quoted).
std::string display_command(const std::vector<std::string>& argv) {
    std::string out;
    for (const std::string& a : argv) {
        std::string q = a;
        if (a.empty() || a.find_first_of(" \t\"") != std::string::npos) q = "\"" + replace_all(a, "\"", "\\\"") + "\"";
        out += (out.empty() ? "" : " ") + q;
    }
    return out;
}

std::string scrub(std::string line, const std::vector<std::string>& secrets) {
    for (const std::string& s : secrets)
        if (!s.empty()) line = replace_all(std::move(line), s, kRedacted);
    return line;
}

// ---- the game ----------------------------------------------------------------------------------------------

struct Game {
    stdfs::path dir;
    std::string name, slug, safeName, version = "0.1.0";
    PublishSettings settings;
    std::vector<std::string> warnings;
};

Result<Game> load_game(const std::string& projectDir, const std::string& store) {
    Game g;
    const std::string who = "publish." + store + ": ";
    if (projectDir.empty()) return err(who + "no project directory given", "pass the folder that contains factoria.json");
    std::error_code ec;
    g.dir = stdfs::weakly_canonical(projectDir, ec);
    const stdfs::path file = g.dir / "factoria.json";
    auto text = tooling_detail::read_file(file);
    if (!text) return err(who + generic(file) + " not found", "run it on a game folder (the one containing factoria.json); create a game with `factoria new <dir>`");
    auto parsed = parse_json(*text, generic(file));
    if (!parsed.ok()) return parsed.error();
    if (!parsed->is_object()) return err(generic(file) + "#/: expected a JSON object");
    g.name = parsed->value("name", std::string());
    if (g.name.empty()) return err(generic(file) + "#/name: missing or empty", "set \"name\": \"My Game\" in factoria.json");
    g.slug = tooling_detail::slugify(g.name, '-').empty() ? "game" : tooling_detail::slugify(g.name, '-');
    g.safeName = fs_safe_name(g.name);
    if (auto v = parsed->find("version"); v != parsed->end() && v->is_string() && !v->get<std::string>().empty()) g.version = v->get<std::string>();

    PublishSettingsParse settings = parse_publish_settings(*parsed);
    for (const ExportSettingsIssue& w : settings.warnings) g.warnings.push_back(w.to_string());
    if (!settings.errors.empty()) {
        const ExportSettingsIssue& first = settings.errors.front();
        std::string hint = first.hint;
        if (settings.errors.size() > 1)
            hint += (hint.empty() ? "" : " ") + std::string("(") + std::to_string(settings.errors.size() - 1) + " more problem(s) in publish: run `factoria validate` to list them all.)";
        return err("factoria.json#" + first.pointer + ": " + first.message, hint);
    }
    g.settings = std::move(settings.settings);
    return g;
}

// ---- the exports ---------------------------------------------------------------------------------------------

std::string launch_of(const Game& g, const std::string& platform) {
    const std::string exe = export_detail::desktop_exe_name(g.slug, platform);
    return platform == "macos" ? g.safeName + ".app/Contents/MacOS/" + exe : exe;
}

// Resolves the platform names of the options. A mobile platform and a typo are teaching errors.
Result<std::vector<std::string>> explicit_platforms(const PublishOptions& o) {
    std::vector<std::string> out;
    for (const std::string& name : o.platforms) {
        const std::string normalized = name.empty() ? std::string() : normalize_export_platform(name);
        if (normalized == "android" || normalized == "ios")
            return err("publish." + o.store + ": '" + name + "' cannot be uploaded to " + o.store,
                       "the publish.* commands upload the desktop exports (windows, macos, linux); mobile builds go to Google Play and the App Store.");
        if (normalized.empty())
            return err("publish." + o.store + ": unknown platform '" + name + "'", did_you_mean(name, publish_platforms()));
        if (std::find(out.begin(), out.end(), normalized) == out.end()) out.push_back(normalized);
    }
    return out;
}

// Files and bytes that an upload of `dir` sends (the export's own marker files are left out).
void measure(const stdfs::path& dir, PublishUpload& up) {
    std::error_code ec;
    for (stdfs::recursive_directory_iterator it(os_path(dir), ec), end; !ec && it != end; it.increment(ec)) {
        if (!it->is_regular_file(ec)) continue;
        const std::string rel = generic(it->path().lexically_relative(os_path(dir)));
        if (std::find(excluded_files().begin(), excluded_files().end(), rel) != excluded_files().end()) continue;
        ++up.files;
        if (const auto size = it->file_size(ec); !ec) up.bytes += size;
    }
}

// ---- the tool --------------------------------------------------------------------------------------------------

// `value` names the tool's executable, or the folder that holds it. "" when there is none.
std::string resolve_tool_path(const Store& store, const std::string& value, const ExportEnvLookup& env) {
    const stdfs::path p(tooling_detail::expand_home(value, env));
    if (is_file(p)) return generic(p);
    if (is_dir(p))
        for (const std::string& name : store.exeNames)
            for (const std::string& file : host_platform() == "windows" ? std::vector<std::string>{name + ".exe", name + ".cmd", name + ".bat", name} : std::vector<std::string>{name})
                if (is_file(p / file)) return generic(p / file);
    return {};
}

struct ToolFound {
    std::string path, from;
};

Result<ToolFound> find_tool(const Store& store, const PublishOptions& o) {
    const ExportEnvLookup& env = o.env;
    const std::string configPath = o.toolConfigPath.empty() ? machine_export_config_path(env) : o.toolConfigPath;
    const std::string where = "To set it up: download it from " + store.download + ", then put it on PATH, set " + store.envVar +
                              " to the executable (or its folder), or write {\"publish\": {\"" + store.configKey + "\": \"<path>\"}} in " + configPath + ".";
    if (const std::string value = env(store.envVar); !value.empty()) {
        if (std::string found = resolve_tool_path(store, value, env); !found.empty()) return ToolFound{found, store.envVar};
        return err("publish." + store.name + ": " + store.envVar + " is '" + value + "', which is not " + store.tool + " (it must be the executable or the folder that holds it)",
                   "Fix or unset " + std::string(store.envVar) + ". " + where);
    }
    std::error_code ec;
    if (stdfs::exists(stdfs::path(configPath), ec)) {
        auto text = tooling_detail::read_file(stdfs::path(configPath));
        auto parsed = text ? parse_json(*text, configPath) : Result<Json>(Error{"Cannot read " + configPath + ".", "Check that the file is readable."});
        if (!parsed.ok()) return err("publish." + store.name + ": " + parsed.error().message, "Fix the JSON of " + configPath + " (or delete it).");
        if (parsed->is_object())
            if (auto pub = parsed->find("publish"); pub != parsed->end() && pub->is_object())
                if (auto v = pub->find(store.configKey); v != pub->end() && v->is_string() && !v->get<std::string>().empty()) {
                    if (std::string found = resolve_tool_path(store, v->get<std::string>(), env); !found.empty()) return ToolFound{found, "export.json"};
                    return err("publish." + store.name + ": " + configPath + "#/publish/" + store.configKey + " is '" + v->get<std::string>() + "', which is not " + store.tool +
                                   " (it must be the executable or the folder that holds it)",
                               "Fix or remove that entry. " + where);
                }
    }
    for (const std::string& name : store.exeNames)
        if (std::string found = which(name); !found.empty()) return ToolFound{generic(stdfs::path(found)), "PATH"};
    return err("publish." + store.name + ": " + store.tool + " was not found on this computer (not on PATH, " + store.envVar + " is not set, and " + configPath +
                   " has no publish." + store.configKey + ")",
               where + " Nothing is downloaded for you.");
}

// ---- running -----------------------------------------------------------------------------------------------

Result<void> write_build_files(const Job& job) {
    for (const stdfs::path& d : job.dirs) {
        std::error_code ec;
        stdfs::create_directories(os_path(d), ec);
        if (ec) return err("publish: cannot create " + generic(d) + ": " + ec.message());
    }
    for (const auto& [path, text] : job.files) {
        std::string e;
        if (!tooling_detail::write_file(path, text, &e)) return err("publish: " + e);
    }
    return {};
}

std::string last_lines(const std::deque<std::string>& tail, std::size_t n) {
    std::string out;
    const std::size_t start = tail.size() > n ? tail.size() - n : 0;
    for (std::size_t i = start; i < tail.size(); ++i) out += (out.empty() ? "" : " | ") + tail[i];
    return out;
}

}  // namespace

Json PublishReport::to_json() const {
    Json j = Json::object();
    j["store"] = store;
    j["dryRun"] = dryRun;
    j["uploaded"] = uploaded;
    j["version"] = version;
    j["tool"] = tool;
    j["toolFrom"] = toolFrom;
    if (!dryRun) {
        j["exitCode"] = exitCode;
        j["log"] = log;
    }
    if (failed) j["failure"] = failure;
    Json ups = Json::array();
    for (const PublishUpload& u : uploads)
        ups.push_back(Json::object({{"platform", u.platform}, {"folder", u.folder}, {"destination", u.destination}, {"files", u.files},
                                    {"bytes", u.bytes}, {"uploaded", u.uploaded}}));
    j["uploads"] = ups;
    Json st = Json::array();
    for (const PublishStep& s : steps) {
        Json e = Json::object({{"title", s.title}, {"command", s.command}, {"commandLine", display_command(s.command)}, {"files", s.files}, {"ran", s.ran}});
        if (s.ran) e["exitCode"] = s.exitCode;
        st.push_back(e);
    }
    j["steps"] = st;
    j["files"] = files;
    j["warnings"] = warnings;
    j["nextSteps"] = nextSteps;
    return j;
}

Result<PublishReport> publish_project(const PublishOptions& options) {
    const Store* store = find_store(options.store);
    if (!store) return err("publish: unknown store '" + options.store + "'", did_you_mean(options.store, publish_stores()));
    const std::string who = "publish." + store->name + ": ";

    auto game = load_game(options.projectDir, store->name);
    if (!game.ok()) return game.error();

    Context c;
    c.options = options;
    if (!c.options.env) c.options.env = system_export_env();
    c.projectDir = game->dir;
    c.workDir = game->dir / ".factoria" / "publish" / store->name;
    c.name = game->name;
    c.slug = game->slug;
    c.safeName = game->safeName;
    c.version = game->version;
    c.settings = game->settings;
    c.warnings = game->warnings;

    // ---- which exports ----
    std::error_code ec;
    const stdfs::path outParent = stdfs::weakly_canonical(options.outDir.empty() ? game->dir / "build" / "export" : stdfs::path(options.outDir), ec);
    auto folderOf = [&](const std::string& platform) {
        if (auto it = options.folders.find(platform); it != options.folders.end()) return stdfs::path(it->second);
        return outParent / (c.slug + "-" + platform);
    };
    for (const auto& [platform, folder] : options.folders)
        if (std::find(publish_platforms().begin(), publish_platforms().end(), platform) == publish_platforms().end())
            return err(who + "'" + platform + "' in folders is not a platform", did_you_mean(platform, publish_platforms()));

    std::vector<std::string> platforms;
    auto asked = explicit_platforms(options);
    if (!asked.ok()) return asked.error();
    if (!asked->empty()) {
        platforms = *asked;
    } else {
        std::vector<std::string> existing, ready, skipped;
        for (const std::string& p : publish_platforms()) {
            if (!is_dir(folderOf(p)) || stdfs::is_empty(os_path(folderOf(p)), ec)) continue;
            existing.push_back(p);
            if (store->configured(c.settings, p)) ready.push_back(p);
            else skipped.push_back("Skipped the " + p + " export: factoria.json has no " + (store->name == "steam" ? "depot" : "artifact") + " for it under publish." + store->name +
                                   " (add it, or pass \"platforms\" to choose).");
        }
        if (existing.empty())
            return err(who + "there is no export to upload: no folder " + c.slug + "-<platform> with files in " + generic(outParent),
                       "Export the game first: project.export {\"platform\":\"windows\"} (macos and linux work the same), which writes build/export/" + c.slug +
                           "-windows. Or pass \"out\" (the parent folder of the exports) or \"folders\" ({\"windows\": \"path\"}).");
        // Exports exist but none is set up for this store: keep them, so that the store's planner names what is missing.
        platforms = ready.empty() ? existing : ready;
        if (!ready.empty()) c.warnings.insert(c.warnings.end(), skipped.begin(), skipped.end());
    }

    PublishReport report;
    report.store = store->name;
    report.version = c.version;
    report.dryRun = options.dryRun;
    for (const std::string& p : platforms) {
        const stdfs::path folder = folderOf(p);
        if (!is_dir(folder) || stdfs::is_empty(os_path(folder), ec))
            return err(who + "there is no export of " + p + " at " + generic(folder) + (is_dir(folder) ? " (the folder is empty)" : ""),
                       "Export it first: project.export {\"platform\":\"" + p + "\"} writes build/export/" + c.slug + "-" + p + ". Or pass \"out\" or \"folders\" to say where it is.");
        Folder f{p, stdfs::weakly_canonical(folder, ec), launch_of(*game, p)};
        if (!is_file(f.path / f.launch)) {
            const std::string message = "the " + p + " export at " + generic(f.path) + " has no " + f.launch + ", the game's executable";
            if (store->needsLaunch)
                return err(who + message, "Export the game again (project.export {\"platform\":\"" + p + "\"}): " + store->tool + " is told to launch that file.");
            c.warnings.push_back("Note: " + message + "; is it an export of this game?");
        }
        c.folders.push_back(f);
        PublishUpload up;
        up.platform = p;
        up.folder = generic(f.path);
        measure(f.path, up);
        report.uploads.push_back(std::move(up));
    }

    // ---- the tool, then the store's own checks and build files ----
    auto tool = find_tool(*store, c.options);  // c.options.env is never empty (set above)
    if (!tool.ok()) return tool.error();
    c.tool = tool->path;
    report.tool = tool->path;
    report.toolFrom = tool->from;
    auto planned = store->plan(c);
    if (!planned.ok()) {
        Error e = planned.error();  // planners write "<store>: ..."; every other message of this command starts "publish.<store>: "
        e.message = "publish." + e.message;
        return e;
    }
    std::vector<Job> jobs = std::move(planned.value());
    for (PublishUpload& up : report.uploads)
        for (const Job& job : jobs)
            for (const auto& [platform, destination] : job.uploads)
                if (platform == up.platform) up.destination = destination;
    for (Job& job : jobs) {
        job.argv[0] = tool->path;
        job.shown[0] = tool->path;
        if (auto w = write_build_files(job); !w.ok()) return w.error();
        PublishStep step;
        step.title = job.title;
        step.command = job.shown;
        for (const auto& f : job.files) {
            step.files.push_back(generic(f.first));
            report.files.push_back(generic(f.first));
        }
        report.steps.push_back(std::move(step));
    }
    report.warnings = c.warnings;
    report.nextSteps = c.nextSteps;
    if (options.dryRun) return report;

    // ---- run ----
    stdfs::create_directories(os_path(c.workDir), ec);
    const stdfs::path logPath = c.workDir.parent_path() / (store->name + ".log");
    std::ofstream log(os_path(logPath), std::ios::binary | std::ios::trunc);
    report.log = generic(logPath);
    report.files.push_back(report.log);
    std::vector<std::string> allSecrets;
    for (const Job& job : jobs) allSecrets.insert(allSecrets.end(), job.secrets.begin(), job.secrets.end());

    for (std::size_t i = 0; i < jobs.size(); ++i) {
        const Job& job = jobs[i];
        std::deque<std::string> tail;
        auto line = [&](std::string_view l) {
            if (const std::size_t cr = l.rfind('\r'); cr != std::string_view::npos) l = l.substr(cr + 1);  // progress bars redraw with \r
            const std::string s = scrub(std::string(l), allSecrets);
            if (log) log << s << '\n' << std::flush;
            tail.push_back(s);
            if (tail.size() > 200) tail.pop_front();
            if (options.progress) options.progress(s);
        };
        line("== " + job.title + ": " + display_command(job.shown));
        ProcessOptions po;
        po.argv = job.argv;
        po.workingDir = generic(c.workDir);
        po.env = job.env;
        po.cancel = options.cancel;
        po.captureStdout = false;
        po.onStdoutLine = line;
        po.onStderrLine = line;
        PublishStep& step = report.steps[i];
        auto run = run_process(po);
        auto fail = [&](std::string message, std::string hint) {
            report.failed = true;
            report.failure = std::move(message);
            report.failureHint = std::move(hint);
        };
        if (!run.ok()) {
            fail(who + "cannot start " + store->tool + " (" + tool->path + "): " + run.error().message, run.error().hint.empty() ? "Check that the file is the tool and is executable." : run.error().hint);
            break;
        }
        step.ran = true;
        step.exitCode = run->exitCode;
        report.exitCode = run->exitCode;
        line("== exit code " + std::to_string(run->exitCode));
        if (run->cancelled) {
            fail(who + "cancelled: " + store->tool + " was stopped", "Run it again; an upload that was cut short is sent again.");
            break;
        }
        if (run->exitCode != 0) {
            fail(who + store->tool + " failed (" + job.title + " exited with code " + std::to_string(run->exitCode) + "). Last output: " + last_lines(tail, 8) + ". Full log: " + report.log,
                 job.failureHint);
            break;
        }
        for (PublishUpload& up : report.uploads)
            for (const auto& [platform, destination] : job.uploads)
                if (platform == up.platform) up.uploaded = true;
    }
    report.uploaded = !report.failed;
    return report;
}

namespace {

CommandInfo store_command(const std::string& store) {
    CommandInfo info;
    info.name = "publish." + store;
    info.category = "publish";
    info.readOnly = false;
    std::string props = R"({
        "platforms":{"type":"array","items":{"type":"string"},"description":"Which exports to upload: windows, macos, linux (aliases win, mac, osx also work). Default: every one that has an export folder and is set up for this store in factoria.json; the ones without are skipped with a warning."},
        "out":{"type":"string","description":"Parent folder of the exports, relative to the project (the `out` of project.export). Default: build/export, where the exports are <game-slug>-<platform>."},
        "folders":{"type":"object","description":"Upload another folder for a platform, relative to the project: {\"windows\": \"dist/win\"}. Takes precedence over `out`."},
        "dryRun":{"type":"boolean","default":false,"description":"Write the build files into .factoria/publish/<store>/ and return the exact command lines, what would be uploaded where and the warnings; start nothing and send nothing. Secrets are never in the result."})";
    if (store == "steam")
        props += R"(,
        "account":{"type":"string","description":"Steam account that uploads (the builder account, with the 'Edit App Metadata' permission). Default: publish.steam.account of factoria.json. Its password is never stored: steamcmd keeps the login."},
        "appId":{"type":"integer","description":"Steam app id. Default: the number in steam_appid.txt of the project (not 480, Valve's test app)."},
        "branch":{"type":"string","description":"Beta branch to set the build live on after the upload. Default: publish.steam.branch, else none. 'default' is refused: Steam sets that one by hand."})";
    if (store == "gog")
        props += R"(,
        "branch":{"type":"string","description":"GOG branch to put the build on (Pipeline Builder --branch). Default: none, the build is only uploaded. 'master' is refused: Pipeline Builder cannot publish to it."})";
    info.inputSchema = Json::parse("{\"type\":\"object\",\"properties\":{" + props.substr(1) + "}}");

    if (store == "steam") {
        info.summary = "Upload the desktop exports to Steam (steamcmd, one depot per platform).";
        info.description =
            "Uploads the folders project.export wrote (build/export/<game-slug>-windows, -macos, -linux) as a SteamPipe build: writes app_build_<appid>.vdf and one depot_build_<depot>.vdf per "
            "platform (the content root is the export folder) into .factoria/publish/steam/ and runs `steamcmd +login <account> +run_app_build <vdf> +quit`. Needs: the game's app id in "
            "steam_appid.txt, factoria.json publish.steam {account, depots: {windows: <id>, ...}}, steamcmd (PATH, FACTORIA_STEAMCMD, or publish.steamcmd of ~/.factoria/export.json), and a "
            "steamcmd login done once by hand (it keeps the password and the Steam Guard approval; this command never takes or stores a password). `branch` sets the build live on a beta branch; "
            "the default branch is never touched. The build description is the game's name and its factoria.json version. The export's .factoria-export and AI_CONTENT_DISCLOSURE.md are not uploaded. "
            "Returns {store, dryRun, uploaded, version, tool, uploads[{platform, folder, destination, files, bytes, uploaded}], steps[{title, command, commandLine, files, ran, exitCode}], exitCode, log, "
            "warnings[], nextSteps[]}; a failed steamcmd is an error whose data is that report. Examples: {\"dryRun\":true}, {\"platforms\":[\"windows\"],\"branch\":\"beta\"}. Details: docs_read {\"name\":\"exporting\"}.";
    } else if (store == "itch") {
        info.summary = "Upload the desktop exports to itch.io (butler push, one channel per platform).";
        info.description =
            "Runs `butler push <export folder> <user>/<game>:<channel> --userversion <version>` once per platform; the user/game comes from factoria.json publish.itch.game, the channel from "
            "publish.itch.channels (default windows, mac, linux) and the version from the game's version. Needs butler (PATH, FACTORIA_BUTLER, or publish.butler of ~/.factoria/export.json) signed in: "
            "run `butler login` once, or set BUTLER_API_KEY (never put it in the project). The export's .factoria-export and AI_CONTENT_DISCLOSURE.md are not uploaded. Returns {store, dryRun, uploaded, "
            "version, tool, uploads[{platform, folder, destination, files, bytes, uploaded}], steps[{title, command, commandLine, files, ran, exitCode}], exitCode, log, warnings[], nextSteps[]}; a failed "
            "butler is an error whose data is that report (platforms before it were uploaded). Examples: {\"dryRun\":true}, {\"platforms\":[\"windows\",\"linux\"]}. Details: docs_read {\"name\":\"exporting\"}.";
    } else if (store == "epic") {
        info.summary = "Upload the desktop exports to the Epic Games Store (BuildPatchTool UploadBinary, one artifact per platform).";
        info.description =
            "Runs BuildPatchTool -mode=UploadBinary once per platform with -BuildRoot the export folder, -CloudDir under .factoria/publish/epic/cloud, -BuildVersion the game's version and -AppLaunch the "
            "game's executable. Needs factoria.json publish.epic {organizationId, productId, clientId, artifacts: {windows: <artifact id>, ...}}, BuildPatchTool (PATH, FACTORIA_BUILDPATCHTOOL, or "
            "publish.buildPatchTool of ~/.factoria/export.json) and the client secret in the environment variable FACTORIA_EPIC_CLIENT_SECRET: it is passed by name (-ClientSecretEnvVar), so it is never on a "
            "command line, in the result or in the log. Epic accepts each BuildVersion once per artifact: raise the version for every upload. The export's .factoria-export and AI_CONTENT_DISCLOSURE.md are not "
            "uploaded. Returns {store, dryRun, uploaded, version, tool, uploads[{platform, folder, destination, files, bytes, uploaded}], steps[{title, command, commandLine, files, ran, exitCode}], exitCode, log, "
            "warnings[], nextSteps[]}; a failed BuildPatchTool is an error whose data is that report. Examples: {\"dryRun\":true}, {\"platforms\":[\"windows\"]}. Details: docs_read {\"name\":\"exporting\"}.";
    } else {
        info.summary = "Upload the desktop exports to GOG (Galaxy Pipeline Builder build-game, one project file per platform).";
        info.description =
            "Writes gog-<platform>.json (the Pipeline Builder project: the export folder as the depot, the game's executable as the primary task) into .factoria/publish/gog/ and runs "
            "`GOGGalaxyPipelineBuilder build-game <json> --ignore_list <file> --version <version>` once per platform. Needs factoria.json publish.gog {productId, clientId?, languages?}, Pipeline Builder (PATH, "
            "FACTORIA_GOG_PIPELINE_BUILDER, or publish.galaxyPipelineBuilder of ~/.factoria/export.json) and a sign-in: the credentials it cached, or FACTORIA_GOG_USERNAME and FACTORIA_GOG_PASSWORD "
            "(the password is then an argument of the process while it runs; it is redacted everywhere FactorIA shows anything). The upload is not published: do that in the GOG Developer Portal. The "
            "export's .factoria-export and AI_CONTENT_DISCLOSURE.md are not uploaded. Returns {store, dryRun, uploaded, version, tool, uploads[{platform, folder, destination, files, bytes, uploaded}], "
            "steps[{title, command, commandLine, files, ran, exitCode}], exitCode, log, warnings[], nextSteps[]}; a failed run is an error whose data is that report. Examples: {\"dryRun\":true}, "
            "{\"platforms\":[\"windows\"],\"branch\":\"testing\"}. Details: docs_read {\"name\":\"exporting\"}.";
    }
    return info;
}

}  // namespace

void register_publish_commands(CommandRegistry& registry, const std::string& projectDir) {
    for (const std::string& store : publish_stores()) {
        registry.add(store_command(store), [projectDir, store](const Json& args) {
            PublishOptions o;
            o.store = store;
            o.projectDir = projectDir;
            if (auto it = args.find("platforms"); it != args.end() && it->is_array())
                for (const Json& p : *it)
                    if (p.is_string()) o.platforms.push_back(p.get<std::string>());
            // Inside the project only, like fs.* and project.export: an AI cannot point an upload at any folder of the computer.
            auto inside = [&](const std::string& rel, const char* what) {
                auto dir = resolve_project_path(projectDir, rel);
                if (!dir) throw CommandError("invalid_argument", std::string(what) + ": " + dir.error().message, dir.error().hint);
                return dir->string();
            };
            if (std::string out = tooling_detail::arg_string(args, "out", false); !out.empty()) o.outDir = inside(out, "out");
            if (auto it = args.find("folders"); it != args.end() && it->is_object())
                for (auto f = it->begin(); f != it->end(); ++f) {
                    const std::string platform = normalize_export_platform(f.key());
                    if (platform.empty() || !f.value().is_string())
                        throw CommandError("invalid_argument", "folders: '" + f.key() + "' is not a platform with a folder path", did_you_mean(f.key(), publish_platforms()));
                    o.folders[platform] = inside(f.value().get<std::string>(), "folders");
                }
            o.dryRun = tooling_detail::arg_bool(args, "dryRun", false);
            o.account = tooling_detail::arg_string(args, "account", false);
            if (auto it = args.find("appId"); it != args.end() && it->is_number_integer()) o.appId = std::to_string(it->get<long long>());
            o.branch = tooling_detail::arg_string(args, "branch", false);
            // Commands have no progress channel of their own: each line of the uploader goes to the log (stderr of `factoria call`
            // and `factoria mcp`, the editor console), already scrubbed of secrets.
            o.progress = [store](const std::string& line) { log(LogLevel::Info, "publish." + store, line); };
            auto r = publish_project(o);
            if (!r.ok()) throw CommandError("failed", r.error().message, r.error().hint);
            if (r->failed) throw CommandError("failed", r->failure, r->failureHint, r->to_json());
            return r->to_json();
        });
    }
}

}  // namespace fa
