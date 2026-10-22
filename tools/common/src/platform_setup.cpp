// platform.add_backend: sets a store backend plugin up in a game (docs/PLATFORM.md, "Store backends"). The shared steps
// are here; what each store needs is in platform_setup_<backend>.cpp.
#include "platform_setup.h"

#include <algorithm>
#include <filesystem>

#include "fa/core/process.h"
#include "fa/core/strings.h"
#include "fa/runtime/plugins.h"
#include "fa/runtime/project.h"
#include "fa/tooling/setup.h"
#include "fa/tooling/tooling.h"

namespace fa {

namespace stdfs = std::filesystem;

namespace platform_setup {

namespace {

const std::vector<Backend>& backends() {
    static const std::vector<Backend> all = {steam_backend(), apple_backend(), googleplay_backend()};
    return all;
}

// The last `lines` lines of `text`.
std::string tail(const std::string& text, std::size_t lines) {
    std::size_t pos = text.size();
    for (std::size_t n = 0; pos > 0 && n <= lines; --pos)
        if (text[pos - 1] == '\n') ++n;
    return text.substr(pos == 0 ? 0 : pos + 1);
}

}  // namespace

std::string Context::ensure_plugin(const std::vector<std::string>& platforms) {
    auto project = load_project(projectDir);
    if (!project.ok()) throw CommandError("invalid_argument", project.error().message, project.error().hint);
    for (const PluginSettings& p : project->plugins) {
        if (p.name != backend) continue;
        auto found = plugin_folder(projectDir, p);
        if (!found.ok()) throw CommandError("invalid_argument", found.error().message, found.error().hint);
        done.push_back("kept the plugin '" + backend + "' factoria.json already declares (" + found.value() + ")");
        folder = found.value();
        return folder;
    }
    Json platformList = Json::array();
    for (const std::string& p : platforms) platformList.push_back(p);
    const CommandResult r = registry->call(
        "project.new_plugin", Json::object({{"name", backend}, {"template", backend}, {"platforms", platformList}, {"dryRun", dryRun}}));
    if (!r.ok)
        throw CommandError(r.error.value("code", std::string("failed")),
                           "could not create the " + backend + " plugin: " + r.error.value("message", std::string()),
                           r.error.value("hint", std::string()));
    folder = r.result.value("folder", std::string());
    for (const Json& f : r.result.value("files", Json::array())) wrote(folder + "/" + f.get<std::string>());
    for (const Json& k : r.result.value("keys", Json::array())) keys.push_back(k.get<std::string>());
    done.push_back(std::string(dryRun ? "would create" : "created") + " the plugin '" + backend + "' from its template in " + folder +
                   " and " + (dryRun ? "declare" : "declared") + " it in factoria.json");
    return folder;
}

void Context::run_cmake(const std::vector<std::string>& arguments, const std::string& what) {
    if (dryRun) {
        done.push_back("would " + what);
        return;
    }
    const std::string cmake = cmakeExe.empty() ? find_cmake() : cmakeExe;
    if (cmake.empty())
        throw CommandError("not_found", "cannot " + what + ": CMake 3.24 or newer is not installed",
                           "Install it with `factoria call setup.install '{\"items\":[\"cmake\"]}'` (or the editor's Setup "
                           "window), then run platform.add_backend again.");
    ProcessOptions po;
    po.argv = {cmake};
    po.argv.insert(po.argv.end(), arguments.begin(), arguments.end());
    po.workingDir = projectDir;
    po.timeoutSeconds = 900;
    auto r = run_process(po);
    if (!r.ok()) throw CommandError("failed", "cannot " + what + ": " + r.error().message, r.error().hint);
    if (r->exitCode != 0) {
        const std::string log = tail(r->stdoutText + "\n" + r->stderrText, 30);
        throw CommandError("failed", "cannot " + what + ": CMake exited with " + std::to_string(r->exitCode) + ". The end of its output:\n" + log,
                           "A C/C++ compiler is needed to build a plugin (Visual Studio on Windows, Xcode on macOS, GCC or Clang on "
                           "Linux). Fix what the output says and run platform.add_backend again.");
    }
}

void Context::build_plugin(const std::string& pluginDir, const std::vector<std::string>& configureArguments) {
    const std::string build = pluginDir + "/build";
    std::vector<std::string> configure = {"-S", pluginDir, "-B", build, "-DCMAKE_BUILD_TYPE=Release"};
    configure.insert(configure.end(), configureArguments.begin(), configureArguments.end());
    run_cmake(configure, "configure the " + backend + " plugin");
    run_cmake({"--build", build, "--config", "Release"}, "build the " + backend + " plugin");
    done.push_back(std::string(dryRun ? "would build" : "built") + " the " + backend + " plugin for " + runtime_platform() + " (" + pluginDir +
                   "/" + runtime_platform() + "/)");
}

}  // namespace platform_setup

void register_platform_setup_commands(CommandRegistry& registry, const std::string& projectDir, const AndroidToolchainSearch* androidSearch) {
    using namespace platform_setup;
    std::vector<std::string> names;
    std::string perBackend;
    Json properties = Json::object();
    for (const Backend& b : backends()) {
        names.push_back(b.name);
        perBackend += " " + b.name + ": " + b.summary;
        for (auto it = b.properties.begin(); it != b.properties.end(); ++it) properties[it.key()] = it.value();
    }
    Json backendNames = Json::array();
    for (const std::string& n : names) backendNames.push_back(n);
    properties["backend"] = Json::object({{"type", "string"}, {"enum", backendNames},
                                          {"description", "The store backend to set up; it is also the plugin's name."}});

    CommandInfo info;
    info.name = "platform.add_backend";
    info.category = "platform";
    info.readOnly = false;
    info.summary = "Set up a store backend for this game: its plugin, its build and what the store needs.";
    info.description =
        "One call instead of the manual steps of docs/PLATFORM.md (\"Store backends\"): writes the backend's plugin from "
        "its template (project.new_plugin with template = backend) unless factoria.json already declares it, builds it for "
        "this computer with CMake, and adds what that store needs." + perBackend +
        " Run it again after a change: it keeps what is there. Returns {backend, folder, done[], nextSteps[]}: nextSteps "
        "lists what only a person can do (store dashboards, accounts). factoria.json is patched, not rewritten: only the "
        "plugins.<backend> key is added, and the other keys, their order and the layout stay as they are. With `dryRun` true "
        "nothing is written, built or copied: the result is {backend, dryRun: true, folder, files[] (what it would write), keys[] "
        "(the factoria.json keys it would write), wouldDo[], nextSteps[]}. An argument that does not exist is an error with a "
        "\"did you mean\" (backend-specific ones like sdk or appId are listed above and are accepted for every backend). "
        "Example: {\"backend\": \"steam\", \"appId\": 480}.";
    properties["dryRun"] = Json::object({{"type", "boolean"}, {"default", false},
                                         {"description", "true = write, build and copy nothing: list the files and factoria.json keys it would write (files, keys) and the steps (wouldDo)."}});
    info.inputSchema = Json::object({{"type", "object"}, {"required", Json::array({"backend"})}, {"properties", properties},
                                     {"additionalProperties", false}});
    registry.add(info, [&registry, projectDir, androidSearch](const Json& a) {
        const std::string name = a.at("backend").get<std::string>();
        const auto& all = backends();
        const auto it = std::find_if(all.begin(), all.end(), [&](const Backend& b) { return b.name == name; });
        if (it == all.end()) {  // the schema's enum stops this first; kept for direct C++ callers
            std::vector<std::string> known;
            for (const Backend& b : all) known.push_back(b.name);
            throw CommandError("invalid_argument", "unknown store backend '" + name + "'", did_you_mean(name, known));
        }
        Context ctx;
        ctx.projectDir = projectDir;
        ctx.backend = name;
        ctx.args = a;
        ctx.dryRun = a.value("dryRun", false);
        ctx.registry = &registry;
        ctx.androidSearch = androidSearch;
        it->run(ctx);
        Json out = Json::object({{"backend", name}});
        if (!ctx.folder.empty()) out["folder"] = ctx.folder;
        for (auto e = ctx.extra.begin(); e != ctx.extra.end(); ++e) out[e.key()] = e.value();
        Json done = Json::array(), next = Json::array();
        for (const std::string& s : ctx.done) done.push_back(s);
        for (const std::string& s : ctx.nextSteps) next.push_back(s);
        out[ctx.dryRun ? "wouldDo" : "done"] = done;
        out["nextSteps"] = next;
        Json files = Json::array(), keys = Json::array();
        for (const std::string& s : ctx.files) files.push_back(s);
        for (const std::string& s : ctx.keys) keys.push_back(s);
        out["files"] = files;
        out["keys"] = keys;
        if (ctx.dryRun) out["dryRun"] = true;
        return out;
    });
}

}  // namespace fa
