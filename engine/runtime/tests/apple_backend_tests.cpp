// The Apple backend plugin (platforms/plugins/apple: StoreKit 2, Game Center, iCloud), built from its template by CMake and
// loaded by a real Engine through plugin ABI v2, the way a game loads it (docs/PLATFORM.md, "Apple").
//
// What runs here is a process with no signature, no Apple Account and no window, so the services answer with their
// teaching errors instead of doing business. The tests check exactly that: the backend registers, every request is answered
// once and in time, and each refusal says what to set up. A real purchase, a Game Center sign-in and an iCloud save need
// App Store Connect, a signed app and a sandbox account: they are the manual checks listed in docs/PLATFORM.md ("Apple"),
// never tests that depend on the machine running them.
#if defined(__APPLE__) && defined(FA_APPLE_PLUGIN_DIR)

#include <doctest.h>

#include <CoreFoundation/CoreFoundation.h>

#include <chrono>
#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/runtime/engine.h"
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

// A game whose only plugin is the Apple one, built into the CMake build tree (engine/runtime/CMakeLists.txt).
struct AppleGame {
    stdfs::path dir;
    AppleGame() {
        dir = fs::make_temp_dir("fa_apple_backend_test");
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json") << R"({"format":"factoria.project/1","name":"Store","plugins":{"apple":{"path":")" << FA_APPLE_PLUGIN_DIR
                                             << R"(","platforms":["macos"]}},"platform":{
          "achievements": [{"id": "first_win", "name": "First win"}],
          "leaderboards": [{"id": "high_score", "name": "High score"}, {"id": "daily_route", "name": "Daily route", "order": "ascending", "period": "daily"}, {"id": "weekly_best", "name": "Weekly best", "period": "weekly"}],
          "products": [{"id": "gems_100", "type": "consumable", "title": "100 gems", "price": 0.99, "ids": {"apple": "com.example.gems100"}}]}})";
        std::ofstream(dir / "scenes/main.scene.json") << R"({"format":"factoria.scene/1","entities":[]})";
    }
    ~AppleGame() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    EngineConfig cfg() const {
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.graphics = false;
        c.hotReload = false;
        c.platformBackend = "apple";  // headless runs force the fake otherwise
        return c;
    }
};

Json run(Engine& engine, const std::string& code) {
    auto r = engine.scripts().eval(code);
    INFO(code << " -> " << (r.ok() ? r.value().dump() : r.error().message));
    REQUIRE(r.ok());
    return r.value();
}

// Frames and the main run loop (where StoreKit and GameKit hop to) until `condition` holds in the scripts or `seconds` pass.
bool settle(Engine& engine, const std::string& condition, double seconds) {
    const auto end = std::chrono::steady_clock::now() + std::chrono::duration<double>(seconds);
    do {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.02, false);
        engine.step(1);
        auto r = engine.scripts().eval(condition);
        if (r.ok() && r.value() == true) return true;
    } while (std::chrono::steady_clock::now() < end);
    return false;
}

constexpr double kPatience = 45.0;  // the plugin answers a silent store after 30 s (restore 120 s, sign-in 20 s)

// Calls `expression` (a platform call returning a promise) and records its outcome in out[name]: {ok, value} or {ok, code,
// message, hint}. Waits for the answer.
Json outcome(Engine& engine, const std::string& name, const std::string& expression, double seconds = kPatience) {
    run(engine, "globalThis.out = globalThis.out || {}; (" + expression + ").then((v) => { out['" + name + "'] = {ok: true, value: v}; }, "
                "(e) => { out['" + name + "'] = {ok: false, code: e.code, message: e.message, hint: e.hint}; }); 0");
    const bool answered = settle(engine, "'" + name + "' in out", seconds);
    INFO(name << ": " << expression);
    REQUIRE_MESSAGE(answered, "no answer within " << seconds << " s");
    return run(engine, "out['" + name + "']");
}

// A refusal that teaches: a code of the contract, what is wrong, and how to fix it.
void check_teaches(const Json& r, const std::vector<std::string>& codes, const char* mentions = nullptr) {
    INFO(r.dump());
    REQUIRE(r["ok"] == false);
    const std::string code = r["code"].get<std::string>();
    bool known = false;
    for (const std::string& c : codes) known = known || c == code;
    CHECK_MESSAGE(known, "unexpected code " << code);
    CHECK_FALSE(r["message"].get<std::string>().empty());
    CHECK_FALSE(r["hint"].get<std::string>().empty());
    if (mentions) CHECK(has(r["message"].get<std::string>() + r["hint"].get<std::string>(), mentions));
}

}  // namespace

TEST_CASE("apple backend: the plugin registers the backend 'apple' with Game Center, StoreKit and iCloud") {
    AppleGame game;
    Engine engine;
    std::string err;
    const std::uint64_t seq = log_last_seq();
    REQUIRE(engine.init(game.cfg(), nullptr, &err));
    const std::string logs = logs_since(seq);
    CHECK(has(logs, "Apple backend ready"));

    CHECK(run(engine, "platform.backend") == "apple");
    for (const char* service : {"achievements", "leaderboards", "purchases", "cloudSave", "overlay"})
        CHECK_MESSAGE(run(engine, std::string("platform.has('") + service + "')") == true, service);
    // Game Center has no stats and no presence: the engine answers those itself.
    CHECK(run(engine, "platform.has('stats')") == false);
    CHECK(run(engine, "platform.has('presence')") == false);

    // apple.status is a command: what works on this device and what to fix.
    CommandResult status = engine.commands().call("apple.status");
    REQUIRE_MESSAGE(status.ok, status.error.dump());
    CHECK(status.result["backend"] == "apple");
    CHECK(status.result["platform"] == "macos");
    CHECK(status.result["gameCenter"]["signedIn"] == false);
    CHECK(status.result["keyValueEntitlement"] == false);  // this test binary is not signed with iCloud's entitlement
    REQUIRE(status.result["problems"].is_array());
    std::string problems;
    for (const Json& p : status.result["problems"]) problems += p.get<std::string>() + "\n";
    CHECK(has(problems, "Game Center"));
    CHECK(has(problems, "com.apple.developer.ubiquity-kvstore-identifier"));
}

TEST_CASE("apple backend: every request is answered once and in time, and each refusal says what to set up") {
    AppleGame game;
    Engine engine;
    std::string err;
    const std::uint64_t seq = log_last_seq();
    REQUIRE(engine.init(game.cfg(), nullptr, &err));

    // Game Center before the sign-in: the player is not signed in, whatever the call.
    check_teaches(outcome(engine, "unlock", "platform.achievements.unlock('first_win')"), {"notSignedIn"}, "Game Center");
    check_teaches(outcome(engine, "progress", "platform.achievements.progress('first_win', 0.5)"), {"notSignedIn"});
    check_teaches(outcome(engine, "list", "platform.achievements.list()"), {"notSignedIn"});
    check_teaches(outcome(engine, "reset", "platform.achievements.reset()"), {"notSignedIn"});
    check_teaches(outcome(engine, "submit", "platform.leaderboards.submit('high_score', 10)"), {"notSignedIn"});
    check_teaches(outcome(engine, "entries", "platform.leaderboards.entries('high_score', {range: 'friends', count: 5})"), {"notSignedIn"});
    // A daily or weekly board is a Game Center board like another: signed out, it says so (it is not "unavailable").
    check_teaches(outcome(engine, "dailySubmit", "platform.leaderboards.submit('daily_route', 61000)"), {"notSignedIn"});
    check_teaches(outcome(engine, "weeklyEntries", "platform.leaderboards.entries('weekly_best')"), {"notSignedIn"});
    check_teaches(outcome(engine, "overlay", "platform.overlay.open('achievements')"), {"notSignedIn"});
    // The App Store has no overlay for the app's own products.
    check_teaches(outcome(engine, "store", "platform.overlay.open('store')"), {"unavailable"}, "platform.purchases.buy");

    // iCloud: this process has no iCloud entitlement, so cloud saves are unavailable and the error names the entitlement.
    check_teaches(outcome(engine, "csave", "platform.cloud.save('slot1', {level: 3})"), {"unavailable"}, "com.apple.developer.ubiquity-kvstore-identifier");
    check_teaches(outcome(engine, "cload", "platform.cloud.load('slot1')"), {"unavailable"});
    check_teaches(outcome(engine, "clist", "platform.cloud.list()"), {"unavailable"});
    check_teaches(outcome(engine, "cremove", "platform.cloud.remove('slot1')"), {"unavailable"});
    check_teaches(outcome(engine, "cstat", "platform.cloud.stat('slot1')"), {"unavailable"}, "com.apple.developer.ubiquity-kvstore-identifier");

    // The Game Center sign-in: a process with no window cannot show its sheet, so it ends as "not signed in" (or, on a
    // machine whose Game Center accepts this process, as a signed-in player) rather than waiting for ever.
    Json signIn = outcome(engine, "signin", "platform.signIn()");
    if (signIn["ok"] == true) {
        CHECK(signIn["value"]["signedIn"] == true);
    } else {
        check_teaches(signIn, {"notSignedIn"});
    }

    // StoreKit without a signature or a StoreKit configuration: either no products, or an error that teaches. Never a hang.
    Json products = outcome(engine, "products", "platform.purchases.products()");
    if (products["ok"] == true) {
        CHECK(products["value"].is_array());
        CHECK(products["value"].size() <= 1);
    } else {
        check_teaches(products, {"unavailable", "network", "failed"});
    }
    Json bought = outcome(engine, "buy", "platform.purchases.buy('gems_100')");
    if (bought["ok"] == false) check_teaches(bought, {"unavailable", "unknownId", "network", "notAllowed", "failed"});
    Json restored = outcome(engine, "restore", "platform.purchases.restore()");
    if (restored["ok"] == true) CHECK(restored["value"].is_array());
    else check_teaches(restored, {"unavailable", "network", "notAllowed", "failed"});

    // Nothing is left waiting, and the plugin never answered twice.
    CHECK(engine.platform_services()->pending() == 0);
    const std::string logs = logs_since(seq);
    CHECK_FALSE(has(logs, "answered twice"));
    CHECK_FALSE(has(logs, "is not pending"));
}

TEST_CASE("apple backend: the engine checks ids before the plugin sees them") {
    AppleGame game;
    Engine engine;
    std::string err;
    REQUIRE(engine.init(game.cfg(), nullptr, &err));
    auto message = [&](const char* call) {
        return run(engine, std::string("(() => { try { ") + call + "; return ''; } catch (e) { return e.message; } })()").get<std::string>();
    };
    CHECK(has(message("platform.achievements.unlock('first_wn')"), "did you mean \"first_win\""));
    // An unknown transaction rejects with unknownId (no throw at the call); the plugin never sees it either.
    Json rejected = run(engine, "(async () => { try { await platform.purchases.finish('123'); } catch (e) { return [e.code, e.message]; } })()");
    REQUIRE(rejected.is_array());
    CHECK(rejected[0] == "unknownId");
    CHECK(has(rejected[1].get<std::string>(), "is not one this game was told about"));
    CHECK(engine.platform_services()->pending() == 0);  // the plugin never saw either call
}

#endif  // __APPLE__ && FA_APPLE_PLUGIN_DIR
