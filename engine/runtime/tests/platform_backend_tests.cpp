// Platform backends in the runtime: which backend an engine runs, and a store plugin through plugin ABI version 2
// (fa_plugin.h) registered statically, the same FaPluginApi a shared library gets. Catalog, dispatcher and fake backend
// have their own tests in engine/services/tests; the scripts' `platform` object runs here through Engine and eval.
#include <doctest.h>

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <string>
#include <thread>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/platform_backend.h"
#include "fa/runtime/plugins.h"
#include "fa/services/platform.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

bool has(const std::string& text, const char* part) { return text.find(part) != std::string::npos; }

std::string logs_since(std::uint64_t seq) {
    std::string out;
    for (const LogEntry& e : recent_logs(500, LogLevel::Trace, seq)) out += e.category + ": " + e.message + "\n";
    return out;
}

// ----------------------------------------------------------------------------------------------- the store plugin --
// A backend named "teststore" in the plugin "pstore": answers some requests at once, one from another thread, some from
// its frame callback, and rejects or garbles others.
const FaPluginApi* g_store = nullptr;
std::vector<FaRequest*> g_waiting;  // achievements.unlock: answered by the frame callback
FaRequest* g_stale = nullptr;       // stats.set: answered after the engine is gone
std::string g_unlockArgs;
int g_frames = 0;

void store_request(FaRequest* req, const char* method, const char* args, void*) {
    const std::string m = method;
    if (m == "achievements.unlock") {
        g_unlockArgs = args;
        g_waiting.push_back(req);
    } else if (m == "achievements.progress") {
        g_store->reject(req, "network", "no route to the store", "retry later");
    } else if (m == "purchases.buy") {
        g_store->resolve(req, R"({"status":"purchased","id":"com.test.gems","transactionId":"T-1","receipt":"R-1"})");
        g_store->resolve(req, R"({"status":"cancelled"})");  // the second answer is ignored
    } else if (m == "leaderboards.submit") {
        std::thread([req] { g_store->resolve(req, R"({"id":"high_score","score":5,"best":9})"); }).join();
    } else if (m == "stats.get") {
        g_store->resolve(req, "this is not json");
    } else if (m == "stats.set") {
        g_stale = req;
    } else {
        g_store->reject(req, "mystery", "unexpected method", nullptr);
    }
}

void store_frame(void*) {
    ++g_frames;
    if (g_frames == 2) {
        for (FaRequest* r : g_waiting) g_store->resolve(r, R"({"id":"first_win","unlocked":true,"newly":true})");
        g_waiting.clear();
        g_store->emit(g_store, "overlay", R"({"open":true})");
        g_store->emit(g_store, "overlay", "{broken");  // dropped with a warning
    }
}

int store_init(const FaPluginApi* api) {
    g_store = api;
    CHECK(api->version >= 2);
    FaBackendDesc d = {"teststore", R"(["achievements","stats","leaderboards","purchases"])", store_request, store_frame, nullptr};
    CHECK(api->add_backend(api, &d) == 0);
    return 0;
}

int second_store_init(const FaPluginApi* api) {
    FaBackendDesc d = {"other", R"(["cloudSave"])", store_request, nullptr, nullptr};
    return api->add_backend(api, &d);
}

// ABI refusals: each is logged with the reason and returns non-zero; the plugin itself still loads.
const FaPluginApi* g_late = nullptr;
int g_refusals = 0;

int refusing_init(const FaPluginApi* api) {
    g_late = api;
    auto refused = [&](FaBackendDesc d) { g_refusals += api->add_backend(api, &d) != 0 ? 1 : 0; };
    refused({"Bad Name", R"(["stats"])", store_request, nullptr, nullptr});          // not a backend name
    refused({"refuser", nullptr, store_request, nullptr, nullptr});                  // no services
    refused({"refuser", "not json", store_request, nullptr, nullptr});               // services are not JSON
    refused({"refuser", R"({"a":1})", store_request, nullptr, nullptr});             // not an array
    refused({"refuser", R"(["achievments"])", store_request, nullptr, nullptr});     // not a service: did you mean
    refused({"refuser", R"([])", store_request, nullptr, nullptr});                  // offers nothing
    refused({"refuser", R"(["stats"])", nullptr, nullptr, nullptr});                 // no request handler
    refused({nullptr, R"(["stats"])", store_request, nullptr, nullptr});             // no name
    FaBackendDesc good = {"refuser", R"(["stats", "stats"])", store_request, nullptr, nullptr};
    CHECK(api->add_backend(api, &good) == 0);
    refused({"refuser2", R"(["stats"])", store_request, nullptr, nullptr});          // a second backend
    return 0;
}

// A plugin written against version 1: it knows nothing of backends.
int v1_init(const FaPluginApi* api) {
    FaFunctionDesc f = {"hello", "hello(): says hi.", [](FaCall* call, const char*, void*) { /* answers null */ (void)call; }, nullptr};
    return api->add_function(api, &f);
}

struct StoreGame {
    stdfs::path dir;
    StoreGame(const std::string& plugins, const std::string& platform) {
        dir = fs::make_temp_dir("fa_platform_backend_test");
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json") << R"({"format":"factoria.project/1","name":"Store","plugins":)" << plugins
                                             << R"(,"platform":)" << platform << "}";
        std::ofstream(dir / "scenes/main.scene.json") << R"({"format":"factoria.scene/1","entities":[]})";
    }
    ~StoreGame() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    EngineConfig cfg() const {
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.graphics = false;
        c.hotReload = false;
        return c;
    }
};

const char* kCatalog = R"({
  "achievements": [{"id": "first_win", "name": "First win", "ids": {"teststore": "ACH_ONE"}}],
  "stats": [{"id": "wins"}],
  "leaderboards": [{"id": "high_score", "name": "High score"}],
  "products": [{"id": "gems_100", "type": "consumable", "title": "100 gems", "ids": {"teststore": "com.test.gems"}}]
})";

void register_test_plugins() {
    fa_register_static_plugin("pstore", store_init);
    fa_register_static_plugin("pstore2", second_store_init);
    fa_register_static_plugin("refuser", refusing_init);
    fa_register_static_plugin("oldplugin", v1_init);
}

Json run(Engine& engine, const std::string& code) {
    auto r = engine.scripts().eval(code);
    INFO(code << " -> " << (r.ok() ? r.value().dump() : r.error().message));
    REQUIRE(r.ok());
    return r.value();
}

}  // namespace

// ---------------------------------------------------------------------------------------------------- selection ---
TEST_CASE("platform backend choice: the fake in development, none in an exported game, a plugin when the game has one") {
    PlatformCatalog catalog;
    PluginInstall none;
    auto make = [](const std::string& plugin, const std::string& backend) {
        return PluginBackend{plugin, backend, {"achievements"}, [] { return make_none_backend(); }};
    };

    BackendChoice dev = choose_platform_backend("", "fake", catalog, none, "macos");
    CHECK(dev.backend->name() == "fake");
    CHECK(dev.reason == "no store backend on macos, using the fake backend: purchases are not real (docs/PLATFORM.md)");
    CHECK(dev.warnings.empty());

    BackendChoice shipped = choose_platform_backend("", "none", catalog, none, "windows");
    CHECK(shipped.backend->name() == "none");
    CHECK(has(shipped.reason, "no store backend on windows"));
    CHECK(has(shipped.reason, "platform services are unavailable"));

    // The program can ask for either: headless runs and tests always use the fake, even with a store plugin.
    PluginInstall one;
    one.backends.push_back(make("steam", "steam"));
    CHECK(choose_platform_backend("fake", "none", catalog, one, "windows").backend->name() == "fake");
    CHECK(choose_platform_backend("none", "fake", catalog, one, "windows").backend->name() == "none");

    // One plugin backend wins over the fallback, with nothing to say.
    BackendChoice auto1 = choose_platform_backend("", "none", catalog, one, "windows");
    CHECK(auto1.backend->name() == "none");  // the stub's own name; what matters is it was created by the plugin
    CHECK(auto1.reason.empty());
    CHECK(has(auto1.why, "'steam' registered it"));

    // Several: platform.backend picks, per platform or for all; without it the first by name and a warning.
    PluginInstall two;
    two.backends.push_back(make("steam", "steam"));
    two.backends.push_back(make("apple", "apple"));
    BackendChoice unclear = choose_platform_backend("", "fake", catalog, two, "macos");
    REQUIRE(unclear.warnings.size() == 1);
    CHECK(has(unclear.warnings[0], "several plugins offer a platform backend on macos: apple, steam"));
    CHECK(has(unclear.warnings[0], "Using 'apple'"));
    CHECK(has(unclear.why, "'apple' registered it"));

    catalog.backend = "steam";
    BackendChoice picked = choose_platform_backend("", "fake", catalog, two, "macos");
    CHECK(picked.warnings.empty());
    CHECK(has(picked.why, "'steam' registered it"));
    catalog.backend.clear();
    catalog.backendByPlatform = {{"ios", "apple"}, {"windows", "steam"}};
    CHECK(has(choose_platform_backend("", "fake", catalog, two, "ios").why, "'apple' registered it"));
    CHECK(has(choose_platform_backend("", "fake", catalog, two, "windows").why, "'steam' registered it"));
    CHECK(choose_platform_backend("", "fake", catalog, two, "linux").warnings.size() == 1);  // no entry for linux: unclear again

    // A name that is no plugin with a backend: a warning that suggests, then the fallback.
    catalog.backendByPlatform.clear();
    catalog.backend = "stem";
    BackendChoice typo = choose_platform_backend("", "fake", catalog, two, "macos");
    CHECK(typo.backend->name() == "fake");
    REQUIRE(typo.warnings.size() == 1);
    CHECK(has(typo.warnings[0], "names 'stem', but no plugin of that name offers a platform backend on macos"));
    CHECK(has(typo.warnings[0], "Did you mean 'steam'?"));
    CHECK(has(typo.reason, "using the fake backend"));

    // The plugin exists in the project but did not load: a reason, no warning (the plugin's own warning says why).
    PluginInstall failed;
    failed.failed = {"steam"};
    catalog.backend = "steam";
    BackendChoice broken = choose_platform_backend("", "fake", catalog, failed, "windows");
    CHECK(broken.warnings.empty());
    CHECK(broken.backend->name() == "fake");
    CHECK(has(broken.reason, "names the plugin 'steam', which did not load"));

    // The configuration names a plugin.
    BackendChoice byConfig = choose_platform_backend("steam", "fake", PlatformCatalog{}, two, "windows");
    CHECK(has(byConfig.why, "'steam' registered it"));
    BackendChoice wrong = choose_platform_backend("stam", "fake", PlatformCatalog{}, two, "windows");
    REQUIRE(wrong.warnings.size() == 1);
    CHECK(has(wrong.warnings[0], "the engine configuration names 'stam'"));
}

TEST_CASE("platform backend choice: an Engine without a store plugin") {
    StoreGame game("{}", kCatalog);
    std::string err;
    {
        Engine dev;
        REQUIRE(dev.init(game.cfg(), nullptr, &err));
        CHECK(dev.platform_services()->info()["backend"] == "fake");
        CHECK(run(dev, "platform.backend") == "fake");
        CHECK(run(dev, "platform.has('purchases')") == true);
        dev.shutdown();
    }
    {
        EngineConfig shipped = game.cfg();
        shipped.platformFallback = "none";  // what the exported player sets
        Engine engine;
        REQUIRE(engine.init(shipped, nullptr, &err));
        CHECK(run(engine, "platform.backend") == "none");
        CHECK(run(engine, "platform.has('purchases')") == false);
        // Nothing is free: a purchase is rejected with a hint.
        run(engine, "globalThis.out = []; platform.purchases.buy('gems_100').catch((e) => out.push([e.code, e.message, e.hint]))");
        Json out = run(engine, "out");
        REQUIRE(out.size() == 1);
        CHECK(out[0][0] == "unavailable");
        CHECK(has(out[0][1].get<std::string>(), "platform.purchases.buy(\"gems_100\") failed: platform.purchases.buy is not available"));
        CHECK(has(out[0][2].get<std::string>(), "platform.has(\"purchases\")"));
        // The platform commands refuse to act on a store that is not the fake, saying which one runs.
        CommandResult reset = engine.commands().call("platform.reset");
        REQUIRE_FALSE(reset.ok);
        CHECK(has(reset.error["message"].get<std::string>(), "only works with the fake backend, but this game runs the 'none' backend"));
        engine.shutdown();
    }
    {
        EngineConfig forced = game.cfg();
        forced.platformFallback = "none";
        forced.platformBackend = "fake";  // headless runs, tests, call/session and MCP
        Engine engine;
        REQUIRE(engine.init(forced, nullptr, &err));
        CHECK(run(engine, "platform.backend") == "fake");
        engine.shutdown();
    }
}

TEST_CASE("platform backend choice: a catalog with errors is ignored with a warning, not fatal") {
    StoreGame game("{}", R"({"products": [{"id": "a", "type": "consumable ", "title": "A"}]})");
    Engine engine;
    std::string err;
    const std::uint64_t seq = log_last_seq();
    REQUIRE(engine.init(game.cfg(), nullptr, &err));
    const std::string logs = logs_since(seq);
    CHECK(has(logs, "the catalog is ignored"));
    CHECK(has(logs, "factoria.json#/platform/products/0/type"));
    CHECK(has(logs, "did you mean \"consumable\"?"));
    auto r = engine.scripts().eval("platform.purchases.buy('a')");
    REQUIRE_FALSE(r.ok());
    CHECK(has(r.error().message, "\"a\" is not a product of this game: the game declares none"));
}

// ------------------------------------------------------------------------------------------------ the ABI v2 plugin --
TEST_CASE("platform plugin: a backend answers later from its frame callback and emits events") {
    register_test_plugins();
    StoreGame game(R"({"pstore": {"path": "native/pstore"}})", kCatalog);
    Engine engine;
    std::string err;
    const std::uint64_t seq = log_last_seq();
    REQUIRE(engine.init(game.cfg(), nullptr, &err));
    // Development run: the fake backend is only the fallback; the plugin's backend is chosen.
    CHECK(run(engine, "platform.backend") == "teststore");
    CHECK(run(engine, "platform.has('purchases')") == true);
    CHECK(run(engine, "platform.has('cloudSave')") == false);
    CHECK(logs_since(seq).find("using the fake backend") == std::string::npos);

    g_frames = 0;
    run(engine, "globalThis.out = []; globalThis.events = [];"
                "platform.on('overlay', (e) => events.push(e.open));"
                "platform.achievements.unlock('first_win').then((r) => out.push(r), (e) => out.push('ERR ' + e.message)); 0");
    // The backend was asked with the store's id for the achievement.
    CHECK(Json::parse(g_unlockArgs) == Json::parse(R"({"id":"first_win","storeId":"ACH_ONE"})"));
    CHECK(run(engine, "out.length") == 0);  // not answered yet: nothing resolves without a frame
    engine.step(1);
    CHECK(run(engine, "out.length") == 0);
    CHECK(run(engine, "events.length") == 0);
    engine.step(1);  // the plugin's frame callback answers and emits; the scripts see both at the start of this frame
    CHECK(g_frames == 2);
    CHECK(run(engine, "out") == Json::parse(R"([{"id":"first_win","unlocked":true,"newly":true}])"));
    CHECK(run(engine, "events") == Json::parse("[true]"));
    CHECK(has(logs_since(seq), "the data is not JSON"));  // the broken event was dropped with a warning

    // Answers inside request(): the promise resolves without a frame; the second answer is ignored. The store's id for the
    // product in the answer is mapped back to the catalog id.
    Json bought = run(engine, "(async () => await platform.purchases.buy('gems_100'))()");
    CHECK(bought.size() == 4);  // the store's own "id" is replaced by productId
    CHECK(bought["status"] == "purchased");
    CHECK(bought["productId"] == "gems_100");
    CHECK(bought["transactionId"] == "T-1");
    CHECK(bought["receipt"] == "R-1");
    // The store rejects finish() with a code the engine does not know: "failed", with the plugin's words kept.
    Json finished = run(engine, "(async () => { try { await platform.purchases.finish('T-1'); } catch (e) { return [e.code, e.message]; } })()");
    CHECK(finished[0] == "failed");
    CHECK(has(finished[1].get<std::string>(), "unexpected method (the backend used the error code \"mystery\""));
}

TEST_CASE("platform plugin: rejections, other threads, bad answers and late answers") {
    register_test_plugins();
    StoreGame game(R"({"pstore": {"path": "native/pstore"}})", kCatalog);
    auto holder = std::make_unique<Engine>();
    Engine& engine = *holder;
    std::string err;
    REQUIRE(engine.init(game.cfg(), nullptr, &err));

    // reject(): code, message and hint reach the script as an Error with .code and .hint.
    Json rejected = run(engine, "(async () => { try { await platform.achievements.progress('first_win', 0.5); } catch (e) { return [e.code, e.hint, e.message]; } })()");
    CHECK(rejected[0] == "network");
    CHECK(rejected[1] == "retry later");
    CHECK(rejected[2] == "platform.achievements.progress(\"first_win\", 0.5) failed: no route to the store (hint: retry later)");

    // resolve() from another thread: the answer is queued and reaches the script at the start of the next frame.
    run(engine, "globalThis.best = []; platform.leaderboards.submit('high_score', 5).then((r) => best.push(r.best)); 0");
    CHECK(run(engine, "best.length") == 0);
    engine.step(1);
    CHECK(run(engine, "best") == Json::parse("[9]"));

    // Text that is not JSON fails the request with the code "failed" and names the plugin and the method.
    Json garbled = run(engine, "(async () => { try { await platform.stats.get('wins'); } catch (e) { return [e.code, e.message]; } })()");
    CHECK(garbled[0] == "failed");
    CHECK(has(garbled[1].get<std::string>(), "the plugin 'pstore' answered stats.get with text that is not JSON"));

    // stats.set is answered late (below): the promise is still pending.
    run(engine, "globalThis.late = []; platform.stats.set('wins', 1).then(() => late.push('ok'), (e) => late.push(e.code)); 0");
    CHECK(run(engine, "late.length") == 0);
    CHECK(engine.platform_services()->pending() == 1);

    // Late answers do nothing: the engine is gone, then the plugin answers, twice.
    REQUIRE(g_stale != nullptr);
    FaRequest* stale = g_stale;
    holder.reset();
    g_store->resolve(stale, "{}");
    g_store->resolve(stale, "{}");
    g_store->emit(g_store, "overlay", R"({"open":false})");
    g_store->resolve(nullptr, "{}");
    std::thread([stale] { g_store->reject(stale, "network", "late", nullptr); }).join();
}

TEST_CASE("platform plugin: two backend plugins need platform.backend to choose") {
    register_test_plugins();
    {
        StoreGame game(R"({"pstore": {"path": "native/pstore"}, "pstore2": {"path": "native/pstore2"}})", "{}");
        Engine engine;
        std::string err;
        const std::uint64_t seq = log_last_seq();
        REQUIRE(engine.init(game.cfg(), nullptr, &err));
        CHECK(run(engine, "platform.backend") == "teststore");  // the first by plugin name
        const std::string logs = logs_since(seq);
        CHECK(has(logs, "several plugins offer a platform backend"));
        CHECK(has(logs, "pstore, pstore2"));
        CommandResult info = engine.commands().call("engine.info");
        REQUIRE(info.ok);
        bool listed = false;
        for (const Json& p : info.result["startupProblems"]) listed = listed || has(p.get<std::string>(), "several plugins offer");
        CHECK(listed);
    }
    {
        StoreGame game(R"({"pstore": {"path": "native/pstore"}, "pstore2": {"path": "native/pstore2"}})", R"({"backend": "pstore2"})");
        Engine engine;
        std::string err;
        REQUIRE(engine.init(game.cfg(), nullptr, &err));
        CHECK(run(engine, "platform.backend") == "other");
        CHECK(run(engine, "platform.has('cloudSave') && !platform.has('purchases')") == true);
    }
    {
        StoreGame game(R"({"pstore": {"path": "native/pstore"}, "pstore2": {"path": "native/pstore2"}})",
                       std::string(R"({"backend": {")") + runtime_platform() + R"(": "pstore2", "android": "pstore"}})");
        Engine engine;
        std::string err;
        REQUIRE(engine.init(game.cfg(), nullptr, &err));
        CHECK(run(engine, "platform.backend") == "other");
    }
}

TEST_CASE("platform plugin: add_backend refuses what it cannot use, and says why") {
    register_test_plugins();
    StoreGame game(R"({"refuser": {"path": "native/refuser"}})", "{}");
    Engine engine;
    std::string err;
    const std::uint64_t seq = log_last_seq();
    REQUIRE(engine.init(game.cfg(), nullptr, &err));
    CHECK(g_refusals == 9);
    const std::string logs = logs_since(seq);
    CHECK(has(logs, "'Bad Name' is not a backend name"));
    CHECK(has(logs, "'refuser' has no services"));
    CHECK(has(logs, "are not a JSON array of strings"));
    CHECK(has(logs, "'refuser' lists 'achievments', which is not a platform service. Did you mean 'achievements'?"));
    CHECK(has(logs, "'refuser' offers no service"));
    CHECK(has(logs, "'refuser' has no request handler"));
    CHECK(has(logs, "this plugin already registered the backend 'refuser'"));
    // The one good registration counts, with the duplicate service listed once.
    CHECK(run(engine, "platform.backend") == "refuser");
    CHECK(run(engine, "platform.has('stats')") == true);
    CHECK(run(engine, "platform.has('achievements')") == false);

    // Registering after the entry point is refused too.
    FaBackendDesc d = {"late", R"(["stats"])", store_request, nullptr, nullptr};
    CHECK(g_late->add_backend(g_late, &d) != 0);
    CHECK(has(logs_since(seq), "register the backend inside fa_plugin_init only"));
}

TEST_CASE("platform plugin: a version 1 plugin keeps working next to the new API") {
    register_test_plugins();
    StoreGame game(R"({"oldplugin": {"path": "native/oldplugin"}})", "{}");
    Engine engine;
    std::string err;
    REQUIRE(engine.init(game.cfg(), nullptr, &err));
    CHECK(run(engine, "typeof plugins.oldplugin.hello") == "function");
    CHECK(run(engine, "platform.backend") == "fake");  // no backend plugin: the development fallback
}
