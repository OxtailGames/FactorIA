#include <doctest.h>

#include "fa/core/startup.h"

using namespace fa;
using Mark = StartupTimeline::Mark;

TEST_CASE("StartupTimeline: marks keep their order and the first call wins") {
    StartupTimeline t;
    CHECK_FALSE(t.has(Mark::FirstPresent));
    CHECK(t.wall_ms(Mark::FirstPresent) == -1.0);
    t.mark(Mark::WindowReady);
    t.mark(Mark::FirstPresent);
    const double first = t.wall_ms(Mark::FirstPresent);
    t.mark(Mark::InitBegin);
    t.mark(Mark::FirstPresent);  // ignored
    CHECK(t.wall_ms(Mark::FirstPresent) == first);
    const auto order = t.order();
    REQUIRE(order.size() == 3);
    CHECK(order[0] == Mark::WindowReady);
    CHECK(order[1] == Mark::FirstPresent);
    CHECK(order[2] == Mark::InitBegin);
    CHECK(t.wall_ms(Mark::InitBegin) >= first);
}

TEST_CASE("StartupTimeline: the report says null for what did not happen and names the order") {
    StartupTimeline t;
    t.mark(Mark::InitBegin);
    t.mark(Mark::InitEnd);
    t.mark(Mark::FirstGameFrame);
    const Json j = t.to_json();
    CHECK(j["firstPresentMs"].is_null());  // a headless run has no window to present to
    CHECK(j["windowReadyMs"].is_null());
    CHECK(j["firstGameFrameMs"].is_number());
    CHECK(j["initMs"].is_number());
    CHECK(j["warmupMs"].is_null());
    CHECK(j["startupCpuMs"].is_number());
    CHECK(t.startup_cpu_ms() >= 0.0);
    REQUIRE(j["order"].is_array());
    CHECK(j["order"].size() == 3);
    CHECK(j["order"][0] == "initBegin");
    CHECK(j["order"][2] == "firstGameFrame");
}

TEST_CASE("StartupTimeline: startup_cpu_ms needs both ends") {
    StartupTimeline t;
    CHECK(t.startup_cpu_ms() < 0.0);
    t.mark(Mark::InitBegin);
    CHECK(t.startup_cpu_ms() < 0.0);
    t.mark(Mark::FirstGameFrame);
    CHECK(t.startup_cpu_ms() >= 0.0);
}
