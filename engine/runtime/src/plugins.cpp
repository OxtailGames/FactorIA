// Native plugins: loading the libraries, the FaPluginApi they register through, and installing what they registered
// into an engine (fa/runtime/plugins.h).
#include "fa/runtime/plugins.h"

#include <algorithm>
#include <cstdlib>
#include <filesystem>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <system_error>

#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/services/platform.h"
#include "plugin_backend.h"

#if defined(_WIN32)
#include <windows.h>
#else
#include <dlfcn.h>
#endif
#if defined(__ANDROID__)
#include "sokol_app.h"
#endif

// One call of a handler: what reply() or fail() answered.
struct FaCall {
    fa::Json result;
    std::string error, hint;
    bool failed = false, answered = false;
};

namespace fa {

namespace stdfs = std::filesystem;

namespace {

struct Command {
    CommandInfo info;
    CommandHandler call;  // the FaHandler and its user pointer, through invoke()
};

// A plugin this process opened. Never unloaded: its handlers and the api pointer it keeps stay valid.
struct Loaded {
    std::string name, library;
    std::string error;  // why it is not loaded ("" = loaded)
    std::vector<Command> commands;
    std::vector<ScriptPlugin::Function> functions;
    std::optional<PluginBackendSpec> backend;  // what add_backend registered (ABI version 2)
    bool initializing = false;  // add_command / add_function / add_backend are accepted only inside the entry point
    FaPluginApi api{};
};

std::mutex g_mutex;

std::map<std::string, std::unique_ptr<Loaded>>& loaded() {  // key: name + '\n' + library
    static std::map<std::string, std::unique_ptr<Loaded>> m;
    return m;
}

std::map<std::string, FaPluginInitFn>& statics() {
    static std::map<std::string, FaPluginInitFn> m;
    return m;
}

Loaded* of(const FaPluginApi* api) { return api ? static_cast<Loaded*>(api->host) : nullptr; }

bool is_snake(const std::string& s) {
    return !s.empty() && s[0] >= 'a' && s[0] <= 'z' &&
           std::all_of(s.begin(), s.end(), [](char c) { return (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_'; });
}

bool is_js_identifier(const std::string& s) {
    auto start = [](char c) { return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_' || c == '$'; };
    return !s.empty() && start(s[0]) && std::all_of(s.begin(), s.end(), [&](char c) { return start(c) || (c >= '0' && c <= '9'); });
}

Json invoke(FaHandler handler, void* user, const Json& args) {
    FaCall call;
    const std::string text = args.dump();
    handler(&call, text.c_str(), user);
    if (call.failed) throw CommandError("failed", call.error, call.hint);
    return call.result;  // null when the handler did not answer
}

int refuse(const Loaded& p, const char* what, const std::string& why) {
    FA_ERROR(p.name, "{} refused: {}", what, why);
    return 1;
}

int add_command(const FaPluginApi* api, const FaCommandDesc* d) {
    Loaded* p = of(api);
    if (!p || !d) return 1;
    const std::string name = d->name ? d->name : "";
    const std::string prefix = p->name + ".";
    if (!p->initializing) return refuse(*p, "add_command", "'" + name + "': register commands inside fa_plugin_init only");
    if (name.rfind(prefix, 0) != 0 || !is_snake(name.substr(prefix.size())))
        return refuse(*p, "add_command", "'" + name + "' is not a command name of this plugin: use \"" + prefix +
                                             "<verb>\" in snake_case, e.g. \"" + prefix + "status\"");
    if (!d->summary || !*d->summary)
        return refuse(*p, "add_command", "'" + name + "' has no summary: every command needs a doc string, one imperative line "
                                             "(\"Unlock an achievement.\") that MCP clients and `factoria commands` show");
    if (!d->handler) return refuse(*p, "add_command", "'" + name + "' has no handler");
    if (std::any_of(p->commands.begin(), p->commands.end(), [&](const Command& c) { return c.info.name == name; }))
        return refuse(*p, "add_command", "'" + name + "' is registered twice");
    Command c;
    c.info.name = name;
    c.info.summary = d->summary;
    c.info.description = d->description ? d->description : "";
    c.info.readOnly = d->read_only != 0;
    c.info.category = p->name;
    if (d->input_schema && *d->input_schema) {
        auto schema = parse_json(d->input_schema, name + " input_schema");
        if (!schema.ok() || !schema->is_object())
            return refuse(*p, "add_command", "the input_schema of '" + name + "' is not a JSON Schema object" +
                                                 (schema.ok() ? std::string() : ": " + schema.error().message) +
                                                 ". Example: {\"type\":\"object\",\"properties\":{\"id\":{\"type\":\"string\"}}}");
        c.info.inputSchema = std::move(schema.value());
    }
    c.call = [handler = d->handler, user = d->user](const Json& args) { return invoke(handler, user, args); };
    p->commands.push_back(std::move(c));
    return 0;
}

int add_function(const FaPluginApi* api, const FaFunctionDesc* d) {
    Loaded* p = of(api);
    if (!p || !d) return 1;
    const std::string name = d->name ? d->name : "";
    if (!p->initializing) return refuse(*p, "add_function", "'" + name + "': register functions inside fa_plugin_init only");
    if (!is_js_identifier(name))
        return refuse(*p, "add_function", "'" + name + "' is not a JavaScript identifier (scripts call plugins." + p->name +
                                              ".<name>(...)): use letters, digits, _ and $, e.g. \"unlockAchievement\"");
    if (!d->doc || !*d->doc)
        return refuse(*p, "add_function", "'" + name + "' has no doc: say what it does, its arguments and its result; it goes "
                                              "into types/factoria.d.ts, which is what AIs read");
    if (!d->handler) return refuse(*p, "add_function", "'" + name + "' has no handler");
    if (std::any_of(p->functions.begin(), p->functions.end(), [&](const ScriptPlugin::Function& f) { return f.name == name; }))
        return refuse(*p, "add_function", "'" + name + "' is registered twice");
    p->functions.push_back({name, d->doc, [handler = d->handler, user = d->user](const Json& args) { return invoke(handler, user, args); }});
    return 0;
}

int add_backend(const FaPluginApi* api, const FaBackendDesc* d) {
    Loaded* p = of(api);
    if (!p || !d) return 1;
    const std::string name = d->name ? d->name : "";
    if (!p->initializing)
        return refuse(*p, "add_backend", "'" + name + "': register the backend inside fa_plugin_init only");
    if (p->backend)
        return refuse(*p, "add_backend", "'" + name + "': this plugin already registered the backend '" + p->backend->name +
                                             "'; a plugin has one backend (make another plugin for another store)");
    if (!is_snake(name))
        return refuse(*p, "add_backend", "'" + name + "' is not a backend name: use lower-case letters, digits and underscores, "
                                             "e.g. \"steam\" (the \"ids\" of the catalog in factoria.json are keyed by it)");
    if (!d->request)
        return refuse(*p, "add_backend", "'" + name + "' has no request handler: it receives every platform request "
                                             "(\"achievements.unlock\", \"purchases.buy\", ...; docs/PLATFORM.md lists them)");
    const std::string services = d->services ? d->services : "";
    const std::string example = "e.g. \"services\": \"[\\\"achievements\\\",\\\"stats\\\"]\" (all of them: " +
                                join(platform_services_all(), ", ") + ")";
    if (services.empty())
        return refuse(*p, "add_backend", "'" + name + "' has no services: pass a JSON array of the ones it offers, " + example);
    auto parsed = parse_json(services, name + " services");
    if (!parsed.ok() || !parsed->is_array())
        return refuse(*p, "add_backend", "the services of '" + name + "' are not a JSON array of strings (" +
                                             (parsed.ok() ? std::string("got ") + parsed->type_name() : parsed.error().message) + "), " + example);
    std::vector<std::string> offered;
    for (const Json& item : parsed.value()) {
        const std::string service = item.is_string() ? item.get<std::string>() : "";
        const auto& all = platform_services_all();
        if (std::find(all.begin(), all.end(), service) == all.end())
            return refuse(*p, "add_backend", "'" + name + "' lists " + (item.is_string() ? "'" + service + "'" : item.dump()) +
                                                 ", which is not a platform service. " + did_you_mean(service, all));
        if (std::find(offered.begin(), offered.end(), service) == offered.end()) offered.push_back(service);
    }
    if (offered.empty())
        return refuse(*p, "add_backend", "'" + name + "' offers no service: list at least one, " + example);
    PluginBackendSpec spec;
    spec.api = &p->api;
    spec.plugin = p->name;
    spec.name = name;
    spec.services = std::move(offered);
    spec.request = d->request;
    spec.frame = d->frame;
    spec.user = d->user;
    p->backend = std::move(spec);
    return 0;
}

void reply(FaCall* call, const char* json) {
    if (!call || call->answered) return;  // the first answer counts
    call->answered = true;
    auto parsed = parse_json(json ? json : "null", "plugin result");
    if (!parsed.ok()) {
        call->failed = true;
        call->error = "the plugin answered with text that is not JSON (" + parsed.error().message + ")";
        call->hint = "reply() takes JSON text: a number \"3\", a string \"\\\"text\\\"\" (with its quotes), an object \"{...}\"";
        return;
    }
    call->result = std::move(parsed.value());
}

void fail(FaCall* call, const char* message, const char* hint) {
    if (!call || call->answered) return;
    call->answered = true;
    call->failed = true;
    call->error = message && *message ? message : "the plugin reported a failure without a message";
    call->hint = hint ? hint : "";
}

void plugin_log(const FaPluginApi* api, int level, const char* message) {
    const Loaded* p = of(api);
    const LogLevel l = level <= 0 ? LogLevel::Debug : level == 1 ? LogLevel::Info : level == 2 ? LogLevel::Warn : LogLevel::Error;
    log(l, p ? p->name : std::string("plugin"), message ? message : "");
}

void* native_handle(const char* name) {
#if defined(__ANDROID__)
    if (name && std::string_view(name) == "android.activity") return const_cast<void*>(sapp_android_get_native_activity());
#else
    (void)name;
#endif
    return nullptr;
}

// Opens the library (or takes the static entry point) and runs the entry point. Returns false when the library could
// not be opened, which is not cached: the next engine tries again (a plugin built in the meantime).
bool load(Loaded& p, FaPluginInitFn init, std::string& error) {
    if (!init) {
#if defined(_WIN32)
        // LOAD_WITH_ALTERED_SEARCH_PATH: the libraries the plugin needs are found next to it (its SDK's DLLs).
        HMODULE h = LoadLibraryExW(stdfs::path(p.library).wstring().c_str(), nullptr, LOAD_WITH_ALTERED_SEARCH_PATH);
        if (!h) {
            error = "cannot load " + p.library + ": " + std::system_category().message(int(GetLastError())) +
                    ". It must be a 64-bit DLL, and the DLLs it needs must be next to it";
            return false;
        }
        init = reinterpret_cast<FaPluginInitFn>(reinterpret_cast<void*>(GetProcAddress(h, "fa_plugin_init")));
#else
        void* h = dlopen(p.library.c_str(), RTLD_NOW | RTLD_LOCAL);
        if (!h) {
            const char* why = dlerror();
            error = "cannot load " + p.library + ": " + (why ? why : "unknown error") +
                    ". It must be built for this OS and CPU, and the libraries it needs must be found (an rpath of $ORIGIN "
                    "on Linux, @loader_path on macOS)";
            return false;
        }
        init = reinterpret_cast<FaPluginInitFn>(dlsym(h, "fa_plugin_init"));
#endif
        if (!init) {
            p.error = p.library + " has no fa_plugin_init entry point. Define it with FA_PLUGIN_INIT(" + p.name +
                      ") from fa_plugin.h, which exports it with C linkage";
            return true;
        }
    }
    p.api = FaPluginApi{FA_PLUGIN_API_VERSION, p.name.c_str(), runtime_platform(), &p, add_command, add_function, reply, fail,
                        plugin_log, native_handle, add_backend, plugin_resolve, plugin_reject, plugin_emit};
    p.initializing = true;
    const int rc = init(&p.api);
    p.initializing = false;
    if (rc != 0) {
        p.error = "its fa_plugin_init returned " + std::to_string(rc) + " (the plugin's log lines above say why)";
        p.commands.clear();
        p.functions.clear();
        p.backend.reset();
    }
    return true;
}

}  // namespace

Result<std::string> plugin_folder(const std::string& projectDir, const PluginSettings& plugin) {
    const std::string where = std::string(kProjectFileName) + "#/plugins/" + plugin.name + "/path";
    std::string out;
    for (std::size_t i = 0; i < plugin.path.size();) {
        if (plugin.path.compare(i, 2, "${") != 0) {
            out += plugin.path[i++];
            continue;
        }
        const std::size_t end = plugin.path.find('}', i + 2);
        if (end == std::string::npos)
            return make_error(where + ": '" + plugin.path + "' has a '${' without its '}'",
                              "Write an environment variable as ${NAME}, e.g. \"${MY_SDK_PLUGINS}/" + plugin.name + "\".");
        const std::string var = plugin.path.substr(i + 2, end - i - 2);
        const char* value = var.empty() ? nullptr : std::getenv(var.c_str());
        if (!value || !*value)
            return make_error(where + ": the environment variable " + var + " in '" + plugin.path + "' is not set",
                              "Set " + var + " to the folder that holds the plugin before starting factoria (it keeps a private "
                              "SDK outside the repository), or write the folder itself in \"path\".");
        out += value;
        i = end + 1;
    }
    stdfs::path p(out);
    if (p.is_relative() && !projectDir.empty()) p = stdfs::path(projectDir) / p;
    return p.lexically_normal().generic_string();
}

std::string plugin_library(const std::string& name, const std::string& platform) {
    if (platform == "windows") return "windows/" + name + ".dll";
    if (platform == "macos") return "macos/lib" + name + ".dylib";
    if (platform == "linux") return "linux/lib" + name + ".so";
    if (platform == "ios") return "ios/iphoneos/lib" + name + ".a";
    return "android";
}

Result<std::string> plugin_build(const std::string& projectDir, const PluginSettings& plugin, const std::string& platform) {
    auto folder = plugin_folder(projectDir, plugin);
    if (!folder.ok()) return folder.error();
    const stdfs::path dir = stdfs::path(folder.value()) / platform;
    const std::string where = std::string(kProjectFileName) + "#/plugins/" + plugin.name + ": ";
    const std::string notFor = "or, when it is not made for " + platform + ", list the platforms it is made for in \"platforms\"";
    std::error_code ec;
    std::vector<std::string> missing;
    if (platform == "android") {
        bool found = stdfs::is_regular_file(dir / "build.gradle", ec) || stdfs::is_regular_file(dir / "build.gradle.kts", ec);
        for (stdfs::directory_iterator it(dir, ec), end; !found && !ec && it != end; it.increment(ec))
            found = it->path().extension() == ".aar" || it->path().extension() == ".jar";
        if (!found)
            return make_error(where + dir.generic_string() + " has no Android build: no build.gradle(.kts), .aar or .jar",
                              "Put a Gradle library module there (the one `factoria call project.new_plugin` writes builds "
                              "lib" + plugin.name + ".so into src/main/jniLibs/<abi>/), or the plugin's .aar files; " + notFor + ".");
    } else if (platform == "ios") {
        for (const char* sdk : {"iphoneos", "iphonesimulator"})
            if (!stdfs::is_regular_file(dir / sdk / ("lib" + plugin.name + ".a"), ec))
                missing.push_back(std::string("ios/") + sdk + "/lib" + plugin.name + ".a");
    } else if (!stdfs::is_regular_file(stdfs::path(folder.value()) / plugin_library(plugin.name, platform), ec)) {
        missing.push_back(plugin_library(plugin.name, platform));
    }
    if (!missing.empty()) {
        return make_error(where + "the " + platform + " build is missing: " + join(missing, ", ") + " not found in " + folder.value(),
                          "Build the plugin for " + platform + " into its folder (its CMakeLists.txt copies the build there, "
                          "docs/EXTENDING.md \"Native plugins\"), " + notFor + ".");
    }
    return dir.generic_string();
}

PluginInstall install_plugins(const ProjectSettings& project, const std::string& projectDir, const std::string& libraryDir,
                              CommandRegistry& commands, ScriptSystem& scripts) {
    PluginInstall result;
    std::vector<ScriptPlugin> forScripts;
    const std::string platform = runtime_platform();
    std::lock_guard<std::mutex> lock(g_mutex);
    for (const PluginSettings& ps : project.plugins) {
        const std::vector<std::string> platforms = project.plugin_platforms(ps);
        if (std::find(platforms.begin(), platforms.end(), platform) == platforms.end()) continue;  // plugins.<name> undefined

        // Where its library is.
        std::string library, error;
        const auto st = statics().find(ps.name);
        const FaPluginInitFn staticInit = st != statics().end() ? st->second : nullptr;
        if (staticInit) {
            library = "(linked into the program)";
        } else if (platform == "android") {
            library = "lib" + ps.name + ".so";  // in the APK: the system linker finds it by name
        } else if (platform == "ios") {
            error = "it is not linked into the app (an iOS plugin is a static library that `factoria export --platform ios` "
                    "links into the Xcode project: export the game again)";
        } else {
            const std::string file = stdfs::path(plugin_library(ps.name, platform)).filename().string();
            std::error_code ec;
            if (libraryDir.empty()) {
                auto dir = plugin_build(projectDir, ps, platform);
                if (dir.ok()) library = dir.value() + "/" + file;
                else error = dir.error().message + " " + dir.error().hint;
            } else if (library = libraryDir + "/" + file; !stdfs::is_regular_file(library, ec)) {
                error = library + " not found next to the game: export it again (`factoria export` copies the plugin's " +
                        platform + " build there)";
            }
        }

        // Load it once per process.
        Loaded* p = nullptr;
        if (error.empty()) {
            const std::string key = ps.name + "\n" + library;
            if (auto it = loaded().find(key); it != loaded().end()) {
                p = it->second.get();
            } else {
                auto fresh = std::make_unique<Loaded>();
                fresh->name = ps.name;
                fresh->library = library;
                if (load(*fresh, staticInit, error)) p = loaded().emplace(key, std::move(fresh)).first->second.get();
            }
            if (p) error = p->error;
        }
        if (!error.empty()) {
            const std::string message = "plugin '" + ps.name + "' is not loaded: " + error;
            FA_WARN("plugin", "{}", message);
            result.problems.push_back(message);
            result.failed.push_back(ps.name);
            forScripts.push_back({ps.name, error, {}});
            continue;
        }

        for (const Command& c : p->commands) commands.add(c.info, c.call);
        forScripts.push_back({ps.name, "", p->functions});
        if (p->backend) {
            PluginBackendSpec spec = *p->backend;
            result.backends.push_back({ps.name, spec.name, spec.services, [spec] { return make_plugin_backend(spec); }});
        }
        FA_DEBUG("plugin", "{}: {} command(s), {} function(s){} from {}", ps.name, p->commands.size(), p->functions.size(),
                 p->backend ? ", platform backend '" + p->backend->name + "'" : std::string(), library);
    }
    scripts.set_plugins(std::move(forScripts));
    return result;
}

}  // namespace fa

extern "C" void fa_register_static_plugin(const char* name, FaPluginInitFn init) {
    if (!name || !*name || !init) return;
    std::lock_guard<std::mutex> lock(fa::g_mutex);
    fa::statics()[name] = init;
}
