// player.run_ios_sim (fa/tooling/ios_sim.h): the arguments and the simctl plan, with dryRun on any host. Running the Simulator needs a
// Mac with Xcode and a Simulator build of the player (scripts/ios-smoke.sh does that in CI); nothing here starts one.
#include <doctest.h>

#include <algorithm>

#include "fa/core/command.h"
#include "fa/tooling/ios_sim.h"
#include "fa/tooling/tooling.h"
#include "test_helpers.h"

using namespace fa;

namespace {

bool has_text(const std::string& haystack, const std::string& needle) { return haystack.find(needle) != std::string::npos; }

bool any_step(const Json& steps, const std::string& needle) {
    return std::any_of(steps.begin(), steps.end(), [&](const Json& s) { return has_text(s.get<std::string>(), needle); });
}

const char* kPlist = R"(<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict><key>CFBundleIdentifier</key><string>com.example.sim</string></dict></plist>)";

}  // namespace

TEST_CASE("player.run_ios_sim: dryRun lists the simctl steps with the replay and the orientation in the launch environment") {
    testing::TempDir tmp;
    testing::write_all(tmp.path / "build" / "factoria_player.app" / "Info.plist", kPlist);
    testing::write_all(tmp.path / "replays" / "play.json", R"({"frames":{"0":{"press":["jump"]}}})");
    CommandRegistry registry;
    register_ios_sim_commands(registry, tmp.str());
    const CommandInfo* info = registry.info("player.run_ios_sim");
    REQUIRE(info != nullptr);
    CHECK_FALSE(info->readOnly);
    for (const char* key : {"app", "input", "orientation", "device", "bundleId", "screenshot", "seconds", "dryRun"}) CHECK_MESSAGE(info->inputSchema["properties"].contains(key), key);

    auto r = registry.call("player.run_ios_sim", Json::object({{"app", "build/factoria_player.app"}, {"input", "replays/play.json"}, {"orientation", "landscape"},
                                                               {"device", "iPad Pro 13-inch"}, {"screenshot", "out/ipad.png"}, {"dryRun", true}}));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["bundleId"] == "com.example.sim");  // read from Info.plist
    CHECK(r.result["orientation"] == "landscape");
    const Json& steps = r.result["steps"];
    CHECK(any_step(steps, "simctl boot iPad Pro 13-inch"));
    CHECK(any_step(steps, "simctl install"));
    CHECK(any_step(steps, "SIMCTL_CHILD_FA_INPUT_REPLAY="));
    CHECK(any_step(steps, "play.json"));
    CHECK(any_step(steps, "SIMCTL_CHILD_FA_ORIENTATION=landscape"));
    CHECK(any_step(steps, "--console-pty"));
    CHECK(any_step(steps, "screenshot"));
    CHECK(any_step(steps, "simctl terminate"));
}

TEST_CASE("player.run_ios_sim: wrong arguments say what to fix") {
    testing::TempDir tmp;
    testing::write_all(tmp.path / "x.app" / "Info.plist", "not a plist");
    CommandRegistry registry;
    register_ios_sim_commands(registry, tmp.str());

    auto noApp = registry.call("player.run_ios_sim", Json::object({{"app", "nope.app"}, {"dryRun", true}}));
    REQUIRE_FALSE(noApp.ok);
    CHECK(has_text(noApp.error["message"].get<std::string>(), "not an app bundle"));
    CHECK(has_text(noApp.error["hint"].get<std::string>(), "build_ios.sh --simulator"));

    auto noId = registry.call("player.run_ios_sim", Json::object({{"app", "x.app"}, {"dryRun", true}}));
    REQUIRE_FALSE(noId.ok);
    CHECK(has_text(noId.error["hint"].get<std::string>(), "bundleId"));

    auto noReplay = registry.call("player.run_ios_sim", Json::object({{"app", "x.app"}, {"bundleId", "a.b"}, {"input", "none.json"}, {"dryRun", true}}));
    REQUIRE_FALSE(noReplay.ok);
    CHECK(has_text(noReplay.error["message"].get<std::string>(), "none.json"));

    auto turn = registry.call("player.run_ios_sim", Json::object({{"app", "x.app"}, {"bundleId", "a.b"}, {"orientation", "landscap"}, {"dryRun", true}}));
    REQUIRE_FALSE(turn.ok);
    CHECK(has_text(turn.error["hint"].get<std::string>(), "landscape"));

    auto outside = registry.call("player.run_ios_sim", Json::object({{"app", "x.app"}, {"bundleId", "a.b"}, {"screenshot", "../out.png"}, {"dryRun", true}}));
    REQUIRE_FALSE(outside.ok);
}

TEST_CASE("player.run_ios_sim is part of the tooling every game project gets") {
    testing::TempDir tmp;
    CommandRegistry registry;
    register_tooling_commands(registry, tmp.str());
    CHECK(registry.has("player.run_ios_sim"));
}
