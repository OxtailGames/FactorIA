// Native plugins (fa/runtime/plugins.h) through the static registration path: the same FaPluginApi a DLL gets, without a
// library to build. tools/cli/tests/plugin_test.py loads a real one (factoria run, export, the exported game).
#include <algorithm>
#include <doctest.h>

#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <string>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/plugins.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const FaPluginApi* g_api = nullptr;
int g_inits = 0;

void probe_add(FaCall* call, const char* args, void*) {
    double a = 0, b = 0;
    if (std::sscanf(args, " [ %lf , %lf", &a, &b) != 2) return g_api->fail(call, "add(a, b) takes two numbers", "plugins.probe.add(1, 2)");
    char out[64];
    std::snprintf(out, sizeof out, "%.17g", a + b);
    g_api->reply(call, out);
}

void probe_info(FaCall* call, const char* args, void*) {
    g_api->reply(call, (std::string("{\"platform\":\"") + g_api->platform + "\",\"args\":" + args + "}").c_str());
}

void probe_bad_json(FaCall* call, const char*, void*) { g_api->reply(call, "not json"); }

FA_PLUGIN_INIT(probe) {
    g_api = api;
    ++g_inits;
    FaFunctionDesc add = {"add", "add(a, b): the sum of two numbers.", probe_add, nullptr};
    FaFunctionDesc bad = {"badJson", "Answers with text that is not JSON.", probe_bad_json, nullptr};
    FaCommandDesc info = {"probe.info", "Describe the probe plugin.", "Returns {platform, args}.",
                          R"({"type":"object","properties":{"n":{"type":"integer","default":7}}})", 1, probe_info, nullptr};
    // Refused registrations: the plugin goes on, without them.
    FaCommandDesc wrongPrefix = {"other.info", "Not this plugin's.", nullptr, nullptr, 1, probe_info, nullptr};
    FaCommandDesc noSummary = {"probe.quiet", nullptr, nullptr, nullptr, 1, probe_info, nullptr};
    FaFunctionDesc noDoc = {"undocumented", nullptr, probe_add, nullptr};
    CHECK(api->version == FA_PLUGIN_API_VERSION);
    CHECK(std::string(api->plugin) == "probe");
    CHECK(api->add_function(api, &add) == 0);
    CHECK(api->add_function(api, &bad) == 0);
    CHECK(api->add_command(api, &info) == 0);
    CHECK(api->add_command(api, &wrongPrefix) != 0);
    CHECK(api->add_command(api, &noSummary) != 0);
    CHECK(api->add_function(api, &noDoc) != 0);
    CHECK(api->add_function(api, &add) != 0);  // twice
    api->log(api, 1, "probe ready");
    return 0;
}

int failing_init(const FaPluginApi* api) {
    api->log(api, 3, "no license file");
    return 2;
}

struct Game {
    stdfs::path dir;
    explicit Game(const std::string& plugins) {
        dir = fs::make_temp_dir("fa_plugins_test");
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json") << R"({"format":"factoria.project/1","name":"Plugins","plugins":)" << plugins << "}";
        std::ofstream(dir / "scenes/main.scene.json") << R"({"format":"factoria.scene/1","entities":[]})";
    }
    ~Game() {
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

}  // namespace

TEST_CASE("plugins: a plugin's functions and commands reach scripts and the command registry") {
    fa_register_static_plugin("probe", fa_plugin_init);  // FA_PLUGIN_INIT(probe) defines fa_plugin_init (not static)
    fa_register_static_plugin("broken", failing_init);
    const std::string other = std::string(runtime_platform()) == "android" ? "ios" : "android";
    Game game(R"({"probe": {"path": "native/probe"}, "broken": {"path": "native/broken"}, "missing": {"path": "nowhere"},
                  "elsewhere": {"path": "x", "platforms": [")" + other + R"("]}})");
    Engine engine;
    std::string err;
    REQUIRE(engine.init(game.cfg(), nullptr, &err));

    auto eval = [&](const char* code) { return engine.scripts().eval(code); };
    auto r = eval("plugins.probe.add(1, 2)");
    REQUIRE(r.ok());
    CHECK(r.value() == 3);

    // A failure is an exception with the plugin's message and hint.
    r = eval("plugins.probe.add('x')");
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("plugins.probe.add failed: add(a, b) takes two numbers (hint: plugins.probe.add(1, 2))") != std::string::npos);
    r = eval("plugins.probe.badJson()");
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("not JSON") != std::string::npos);
    // An unknown function names the ones there are.
    r = eval("plugins.probe.ad(1, 2)");
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("Did you mean 'add'?") != std::string::npos);

    // The command: schema defaults filled in, args passed through, the plugin name as category.
    CommandResult c = engine.commands().call("probe.info", Json::object());
    REQUIRE(c.ok);
    CHECK(c.result["platform"] == runtime_platform());
    CHECK(c.result["args"]["n"] == 7);
    CHECK(engine.commands().info("probe.info")->category == "probe");
    CHECK_FALSE(engine.commands().has("other.info"));
    CHECK_FALSE(engine.commands().has("probe.quiet"));
    r = eval("fa.call('probe.info', {n: 3}).args.n");
    REQUIRE(r.ok());
    CHECK(r.value() == 3);

    // A plugin that did not load: the game runs, and using it says why.
    r = eval("plugins.missing.anything()");
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("the native plugin 'missing' is not loaded") != std::string::npos);
    CHECK(r.error().message.find("not found") != std::string::npos);
    r = eval("plugins.broken.x");
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("fa_plugin_init returned 2") != std::string::npos);
    // Not built for this platform: undefined, so scripts can test for it.
    r = eval("plugins.elsewhere === undefined && typeof plugins.probe.add");
    REQUIRE(r.ok());
    CHECK(r.value() == "function");

    // Typings and the API manifest carry the doc strings.
    const std::string dts = engine.scripts().typescript_declarations();
    CHECK(dts.find("export interface PluginsAPI") != std::string::npos);
    CHECK(dts.find("readonly probe: {") != std::string::npos);
    CHECK(dts.find("add(a, b): the sum of two numbers.") != std::string::npos);
    // A plugin that did not load is listed without its load error, which names this machine's folders.
    CHECK(dts.find("Native plugin 'missing' (not loaded when these typings were generated") != std::string::npos);
    CHECK(dts.find("not found in") == std::string::npos);
    CHECK(engine.scripts().api_manifest()["plugins"].size() == 3);  // probe, broken, missing

    // A second engine in the same process reuses the loaded plugin: its entry point ran once.
    const int inits = g_inits;
    Engine second;
    REQUIRE(second.init(game.cfg(), nullptr, &err));
    CHECK(g_inits == inits);
    CHECK(second.commands().has("probe.info"));
    second.shutdown();
    engine.shutdown();
}

TEST_CASE("plugins: folders, ${VARIABLE} parts and library names") {
    PluginSettings p{"steam", "${FA_PLUGINS_TEST_DIR}/steam", {}};
#if defined(_WIN32)
    _putenv_s("FA_PLUGINS_TEST_DIR", "C:/sdk");
#else
    setenv("FA_PLUGINS_TEST_DIR", "/opt/sdk", 1);
#endif
    auto f = plugin_folder("C:/games/g", p);
    REQUIRE(f.ok());
#if defined(_WIN32)
    CHECK(f.value() == "C:/sdk/steam");
#else
    CHECK(f.value() == "/opt/sdk/steam");
#endif
    p.path = "../private/steam";
    CHECK(plugin_folder("/games/g", p).value() == "/games/private/steam");
    p.path = "${FA_PLUGINS_TEST_UNSET_VAR}/steam";
    auto unset = plugin_folder("/games/g", p);
    REQUIRE_FALSE(unset.ok());
    CHECK(unset.error().message.find("FA_PLUGINS_TEST_UNSET_VAR") != std::string::npos);
    CHECK(unset.error().message.find("factoria.json#/plugins/steam/path") != std::string::npos);

    CHECK(plugin_library("steam", "windows") == "windows/steam.dll");
    CHECK(plugin_library("steam", "linux") == "linux/libsteam.so");
    CHECK(plugin_library("steam", "macos") == "macos/libsteam.dylib");
    CHECK(plugin_library("steam", "ios") == "ios/iphoneos/libsteam.a");
}

TEST_CASE("plugins: factoria.json errors name the field and say how to fix it") {
    auto load = [](const std::string& plugins) {
        Game g(plugins);
        return load_project(g.dir.generic_string());
    };
    auto ok = load(R"({"zeta": {"path": "z"}, "alpha": {"path": "a", "platforms": ["android", "ios"]}})");
    REQUIRE(ok.ok());
    REQUIRE(ok->plugins.size() == 2);
    CHECK(ok->plugins[0].name == "alpha");  // sorted
    CHECK(ok->plugin_platforms(ok->plugins[0]) == std::vector<std::string>{"android", "ios"});
    CHECK(ok->plugin_platforms(ok->plugins[1]).size() == 5);  // every native platform; a browser cannot load a plugin
    const auto all = ok->plugin_platforms(ok->plugins[1]);
    CHECK(std::find(all.begin(), all.end(), "web") == all.end());
    CHECK(platform_names().back() == "web");

    CHECK_FALSE(ok->plugins[0].optional);
    auto opt = load(R"({"a": {"path": "a", "optional": true}, "b": {"path": "b", "optional": false}, "c": {"path": "c"}})");
    REQUIRE(opt.ok());
    CHECK(opt->plugins[0].optional);
    CHECK_FALSE(opt->plugins[1].optional);
    CHECK_FALSE(opt->plugins[2].optional);

    auto bad = load(R"({"steam": {"path": "s", "optional": "yes"}})");
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("#/plugins/steam/optional") != std::string::npos);
    bad = load(R"({"Steam": {"path": "s"}})");
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("#/plugins/Steam: 'Steam' is not a plugin name") != std::string::npos);
    bad = load(R"({"scene": {"path": "s"}})");
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("is a name the engine uses") != std::string::npos);
    bad = load(R"({"steam": {}})");
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("#/plugins/steam/path: missing") != std::string::npos);
    bad = load(R"({"steam": {"path": "s", "platforms": ["window"]}})");
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("#/plugins/steam/platforms/0") != std::string::npos);
    CHECK(bad.error().hint.find("windows") != std::string::npos);
    bad = load(R"(["steam"])");
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("#/plugins: expected an object") != std::string::npos);
}
