// Unit tests for the editor's GPU-free pieces. The windowed end-to-end test is
// fa_editor_autotest (ctest label "gpu").
#include <atomic>
#include <chrono>
#include <thread>

#include "doctest.h"
#include "editor_internal.h"

using namespace fa;
using namespace fa::editor;

TEST_CASE("asset type matching") {
    CHECK(asset_matches("texture", "assets/hero.PNG"));
    CHECK_FALSE(asset_matches("texture", "assets/hero.wav"));
    CHECK(asset_matches("audio", "sfx/jump.ogg"));
    CHECK(asset_matches("scene", "scenes/main.scene.json"));
    CHECK_FALSE(asset_matches("scene", "factoria.json"));
    CHECK(asset_matches("prefab", "prefabs/a.prefab.json"));
    CHECK(asset_matches("any", "whatever.bin"));
}

TEST_CASE("case-insensitive filter") {
    CHECK(contains_ci("Main Camera", "cam"));
    CHECK(contains_ci("Main Camera", ""));
    CHECK_FALSE(contains_ci("Player", "enemy"));
}

TEST_CASE("MainThreadQueue runs worker-thread calls on the pumping thread") {
    MainThreadQueue q;
    std::atomic<bool> done{false};
    CommandResult result;
    std::thread::id workerId, runId;
    std::thread worker([&] {
        workerId = std::this_thread::get_id();
        result = q.call("x.y", Json::object({{"a", 1}}), nullptr);
        done = true;
    });
    int ran = 0;
    for (int i = 0; i < 400 && !done; ++i) {
        ran += q.pump([&](const std::string& name, const Json& args) {
            runId = std::this_thread::get_id();
            CommandResult r;
            r.ok = true;
            r.result = Json::object({{"name", name}, {"a", args.value("a", 0)}});
            return r;
        });
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
    worker.join();
    CHECK(ran == 1);
    CHECK(result.ok);
    CHECK(result.result["name"] == "x.y");
    CHECK(result.result["a"] == 1);
    CHECK(runId == std::this_thread::get_id());
    CHECK(runId != workerId);
}

TEST_CASE("MainThreadQueue fails pending calls when closed or cancelled") {
    MainThreadQueue q;
    std::atomic<bool> cancel{false};
    CommandResult r1, r2;
    std::thread t1([&] { r1 = q.call("a.b", Json::object(), &cancel); });
    std::this_thread::sleep_for(std::chrono::milliseconds(60));
    cancel = true;
    t1.join();
    CHECK_FALSE(r1.ok);
    std::thread t2([&] { r2 = q.call("a.b", Json::object(), nullptr); });
    std::this_thread::sleep_for(std::chrono::milliseconds(60));
    q.close();
    t2.join();
    CHECK_FALSE(r2.ok);
    CommandResult r3 = q.call("a.b", Json::object(), nullptr);  // closed queue rejects immediately
    CHECK_FALSE(r3.ok);
    CHECK(r3.error["code"] == "unavailable");
}
