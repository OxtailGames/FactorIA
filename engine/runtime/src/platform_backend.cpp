// The plugin adapter of the platform API (ABI v2 of fa_plugin.h) and the choice of which backend an engine runs.
#include "fa/runtime/platform_backend.h"

#include <algorithm>
#include <atomic>
#include <cstdint>
#include <map>
#include <mutex>

#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/services/fake_platform.h"
#include "plugin_backend.h"

namespace fa {

namespace {

// Plugins outlive engines (the editor starts play sessions, each with its own engine), and a store SDK answers from its
// own threads when it likes. So a FaRequest* is never a pointer into an engine: it is a token, looked up here.
std::mutex g_mutex;
std::uintptr_t g_nextToken = 0;

struct Waiting {
    PlatformSink sink;  // dead once the engine is gone: the answer then does nothing
    std::uint64_t id = 0;
    std::string plugin, method;
};

std::map<std::uintptr_t, Waiting>& waiting() {
    static std::map<std::uintptr_t, Waiting> m;
    return m;
}

// The adapters of running engines: where a plugin's emit() goes.
struct Live {
    const FaPluginApi* api;
    const void* adapter;
    PlatformSink sink;
};

std::vector<Live>& live() {
    static std::vector<Live> v;
    return v;
}

std::uintptr_t token_of(FaRequest* req) { return reinterpret_cast<std::uintptr_t>(req); }

// Removes and returns the request `req` stands for; false when it is not waiting (answered already, or never asked).
bool take(FaRequest* req, Waiting& out) {
    std::lock_guard<std::mutex> lock(g_mutex);
    auto it = waiting().find(token_of(req));
    if (it == waiting().end()) return false;
    out = std::move(it->second);
    waiting().erase(it);
    return true;
}

void warn_not_waiting(const char* what) {
    static std::atomic<bool> warned{false};
    if (warned.exchange(true)) return;
    FA_WARN("plugin", "{}() was called for a platform request that is not waiting for an answer (answered twice, or its game has "
                      "ended): ignored. Answer each FaRequest exactly once. This is logged once.", what);
}

class PluginBackendAdapter final : public PlatformBackend {
public:
    explicit PluginBackendAdapter(PluginBackendSpec spec) : spec_(std::move(spec)) {}

    ~PluginBackendAdapter() override {
        std::lock_guard<std::mutex> lock(g_mutex);
        auto& v = live();
        v.erase(std::remove_if(v.begin(), v.end(), [&](const Live& l) { return l.adapter == this; }), v.end());
    }

    std::string name() const override { return spec_.name; }
    std::vector<std::string> services() const override { return spec_.services; }

    void attach(const PlatformSink& sink) override {
        std::lock_guard<std::mutex> lock(g_mutex);
        auto& v = live();
        v.erase(std::remove_if(v.begin(), v.end(), [&](const Live& l) { return l.adapter == this; }), v.end());
        v.push_back({spec_.api, this, sink});
    }

    void request(std::uint64_t id, const std::string& method, const Json& args, const PlatformSink& sink) override {
        std::uintptr_t token = 0;
        {
            std::lock_guard<std::mutex> lock(g_mutex);
            token = ++g_nextToken;
            waiting()[token] = {sink, id, spec_.plugin, method};
        }
        FaRequest* req = reinterpret_cast<FaRequest*>(token);
        const std::string text = args.dump();
        try {
            spec_.request(req, method.c_str(), text.c_str(), spec_.user);
        } catch (const std::exception& e) {  // a handler must not throw; if one does, the game still gets an answer
            plugin_reject(req, "failed", (spec_.plugin + " threw while handling " + method + ": " + e.what()).c_str(), nullptr);
        } catch (...) {
            plugin_reject(req, "failed", (spec_.plugin + " threw while handling " + method).c_str(), nullptr);
        }
    }

    void frame() override {
        if (spec_.frame) spec_.frame(spec_.user);
    }

private:
    PluginBackendSpec spec_;
};

std::string join_names(const std::vector<std::string>& names) { return join(names, ", "); }

}  // namespace

std::unique_ptr<PlatformBackend> make_plugin_backend(const PluginBackendSpec& spec) {
    return std::make_unique<PluginBackendAdapter>(spec);
}

void plugin_resolve(FaRequest* req, const char* resultJson) {
    Waiting w;
    if (!req || !take(req, w)) return warn_not_waiting("resolve");
    auto parsed = parse_json(resultJson ? resultJson : "null", "platform result");
    if (!parsed.ok()) {
        w.sink.fail(w.id, {"failed",
                           "the plugin '" + w.plugin + "' answered " + w.method + " with text that is not JSON (" +
                               parsed.error().message + ")",
                           "resolve() takes JSON text: a number \"3\", a string \"\\\"text\\\"\" (with its quotes), an object \"{...}\"."});
        return;
    }
    w.sink.complete(w.id, std::move(parsed.value()));
}

void plugin_reject(FaRequest* req, const char* code, const char* message, const char* hint) {
    Waiting w;
    if (!req || !take(req, w)) return warn_not_waiting("reject");
    w.sink.fail(w.id, {code && *code ? code : "failed",
                       message && *message ? message : "the plugin '" + w.plugin + "' rejected " + w.method + " without a message",
                       hint ? hint : ""});
}

void plugin_emit(const FaPluginApi* api, const char* event, const char* dataJson) {
    if (!api || !event) return;
    auto parsed = parse_json(dataJson && *dataJson ? dataJson : "{}", "platform event");
    if (!parsed.ok()) {
        FA_WARN("plugin", "emit({}): the data is not JSON ({}): event dropped", event, parsed.error().message);
        return;
    }
    std::vector<PlatformSink> sinks;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        for (const Live& l : live())
            if (l.api == api) sinks.push_back(l.sink);
    }
    for (const PlatformSink& sink : sinks) sink.emit(event, parsed.value());
}

// -------------------------------------------------------------------------------------------------------- choice --

BackendChoice choose_platform_backend(const std::string& requested, const std::string& fallback, const PlatformCatalog& catalog,
                                      const PluginInstall& plugins, const std::string& platform) {
    BackendChoice out;
    auto make_fake = [] { return std::unique_ptr<PlatformBackend>(std::make_unique<FakeBackend>()); };
    auto use_fallback = [&](const std::string& why) {
        const bool none = fallback == "none";
        out.backend = none ? make_none_backend() : make_fake();
        out.reason = why + (none ? ", platform services are unavailable (docs/PLATFORM.md)"
                                                : ", using the fake backend: purchases are not real (docs/PLATFORM.md)");
        out.why = out.reason;
    };
    auto use_plugin = [&](const PluginBackend& b, const std::string& how) {
        out.backend = b.create();
        out.why = "the plugin '" + b.plugin + "' registered it and " + how;
    };
    auto find = [&](const std::string& plugin) -> const PluginBackend* {
        for (const PluginBackend& b : plugins.backends)
            if (b.plugin == plugin) return &b;
        return nullptr;
    };
    std::vector<std::string> names;
    for (const PluginBackend& b : plugins.backends) names.push_back(b.plugin);
    std::sort(names.begin(), names.end());

    // Why the plugin `name` cannot be the backend.
    auto unavailable = [&](const std::string& name, const std::string& source) {
        if (std::find(plugins.failed.begin(), plugins.failed.end(), name) != plugins.failed.end())
            return source + " names the plugin '" + name + "', which did not load (see the warning above)";
        std::string message = source + " names '" + name + "', but no plugin of that name offers a platform backend on " + platform;
        message += names.empty() ? " (no plugin does: a backend plugin registers one with api->add_backend, docs/PLATFORM.md)"
                                 : ". " + did_you_mean(name, names);
        out.warnings.push_back(message);
        return message;
    };

    if (requested == "fake") {
        out.backend = make_fake();
        out.why = "this run asked for it: headless runs, tests, `factoria call` and the MCP server always use the fake backend";
        return out;
    }
    if (requested == "none") {
        out.backend = make_none_backend();
        out.why = "this run asked for it: no platform services";
        return out;
    }
    std::string wanted = requested, source = "the engine configuration";
    if (wanted.empty()) {
        wanted = catalog.backend_for(platform);
        source = "factoria.json platform.backend";
    }
    if (!wanted.empty()) {
        if (const PluginBackend* b = find(wanted)) {
            use_plugin(*b, source + " names it");
            return out;
        }
        use_fallback("no store backend on " + platform + " (" + unavailable(wanted, source) + ")");
        return out;
    }
    if (names.size() == 1) {
        use_plugin(*find(names[0]), "it is the only backend plugin of the game");
        return out;
    }
    if (names.size() > 1) {
        out.warnings.push_back("several plugins offer a platform backend on " + platform + ": " + join_names(names) + ". Using '" +
                               names[0] + "'; set \"backend\" in the \"platform\" section of factoria.json to choose, e.g. "
                               "\"backend\": \"" + names[0] + "\" (or one per platform: {\"windows\": \"" + names[0] + "\"}).");
        use_plugin(*find(names[0]), "it is the first of several");
        return out;
    }
    use_fallback("no store backend on " + platform);
    return out;
}

}  // namespace fa
