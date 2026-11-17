// Deprecated script API (core/deprecation.h, docs/design/ARCHITECTURE_CORE.md "Deprecations"): a function, a namespace member and a member of an
// object the module exports still work, and the first call of each logs one warning that names the replacement. The entries are
// test-only: the real deprecated section ships empty.
#include <doctest.h>

#include <mutex>

#include "fa/core/deprecation.h"
#include "fa/core/log.h"
#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {
struct Capture {
    std::mutex mutex;
    std::vector<std::string> lines;
    int id;
    Capture() {
        id = add_log_sink([this](const LogEntry& e) {
            if (e.category != "deprecated") return;
            std::lock_guard<std::mutex> lock(mutex);
            lines.push_back(e.message);
        });
    }
    ~Capture() { remove_log_sink(id); }
};
}  // namespace

TEST_CASE("deprecated script API: the first call warns with the replacement, the call still works") {
    Deprecations::global().set(Json::parse(R"({"script": {
        "didYouMean": {"since": "0.30.0", "use": "tween", "note": "Try the new one."},
        "WorldAPI.find": {"since": "0.30.0", "use": "WorldAPI.get", "note": ""},
        "NoSuchExport": {"since": "0.30.0", "use": "", "note": "Not in the module: ignored."}}})"));
    struct Clear {
        ~Clear() { Deprecations::global().clear(); }
    } clear;
    Capture cap;
    TestHost h("deprecated_api");
    REQUIRE(h.start());
    auto ev = [&](const std::string& code) {
        auto r = h.scripts.eval(code);
        if (!r.ok()) FAIL(r.error().to_string());
        return *r;
    };
    CHECK(cap.lines.empty());  // wrapping the API warns about nothing
    CHECK(ev("didYouMean('woood', ['wood', 'stone'])").get<std::string>() == "wood");
    CHECK(ev("didYouMean('stoone', ['wood', 'stone'])").get<std::string>() == "stone");
    REQUIRE(cap.lines.size() == 1);
    CHECK(cap.lines[0].find("script API 'didYouMean'") != std::string::npos);
    CHECK(cap.lines[0].find("Use 'tween' instead. Try the new one.") != std::string::npos);
    ev("world.spawn({ id: 'x' }); world.find('x'); world.find('x'); 0");
    REQUIRE(cap.lines.size() == 2);  // a member of an object the module exports (`world` is a WorldAPI)
    CHECK(cap.lines[1].find("script API 'WorldAPI.find'") != std::string::npos);
    CHECK(cap.lines[1].find("Use 'WorldAPI.get' instead") != std::string::npos);
    CHECK(ev("world.find('x').id").get<std::string>() == "x");  // and it still works
    CHECK(cap.lines.size() == 2);
    CHECK(h.scripts.errors().empty());
}

// world.spawnPrefab and world.spawn load through the scene loader: its deprecation warning (taken from the once-per-process table)
// must reach the log, not be dropped with the successful report.
TEST_CASE("deprecated component fields: a prefab spawned from a script logs the warning once") {
    Deprecations::global().set(Json::parse(R"({"components": {
        "Sprite.flipX": {"since": "0.30.0", "use": "Sprite.flipY", "note": ""}}})"));
    struct Clear {
        ~Clear() { Deprecations::global().clear(); }
    } clear;
    Capture cap;
    TestHost h("deprecated_prefab");
    h.file("prefabs/flip.prefab.json",
           R"({"format":"factoria.prefab/1","entity":{"name":"Flip","components":{"Sprite":{"flipX":true}}}})");
    REQUIRE(h.start());
    auto r = h.scripts.eval(
        "world.spawnPrefab('prefabs/flip.prefab.json'); world.spawnPrefab('prefabs/flip.prefab.json'); 1");
    if (!r.ok()) FAIL(r.error().to_string());
    REQUIRE(cap.lines.size() == 1);  // two spawns, the process is told once
    CHECK(cap.lines[0].find("component field 'Sprite.flipX'") != std::string::npos);
    CHECK(cap.lines[0].find("Use 'Sprite.flipY' instead") != std::string::npos);
    CHECK(h.scripts.errors().empty());
}
