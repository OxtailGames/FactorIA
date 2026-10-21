#include <doctest.h>

#include "fa/core/perf.h"
#include "fa/core/profiler.h"

using namespace fa;

namespace {
ProfFrame frame(double total, double scriptsUpdate, std::vector<ProfClassSample> classes) {
    ProfFrame f;
    f.totalMs = total;
    f.systemMs[std::size_t(ProfSystem::ScriptsUpdate)] = scriptsUpdate;
    f.classes = std::move(classes);
    return f;
}
}  // namespace

TEST_CASE("profiler: system names are stable camelCase keys") {
    CHECK(std::string(prof_system_name(ProfSystem::Platform)) == "platform");
    CHECK(std::string(prof_system_name(ProfSystem::ScriptsFixedUpdate)) == "scriptsFixedUpdate");
    CHECK(std::string(prof_system_name(ProfSystem::EndOfFrame)) == "endOfFrame");
    for (int i = 0; i < kProfSystemCount; ++i) CHECK(std::string(prof_system_name(ProfSystem(i))) != "unknown");
}

TEST_CASE("profiler: off by default, probes do nothing; on, a frame publishes systems and classes slowest first") {
    Profiler& p = Profiler::get();
    p.set_enabled(false);
    {
        ProfSystemScope s(ProfSystem::Audio);
        const std::string c = "A", path = "a.js";
        ProfBehaviourScope b(c, path);
    }
    p.begin_frame();
    p.end_frame();
    CHECK(p.frames() == 0);

    p.set_enabled(true);
    p.begin_frame();
    p.add_system(ProfSystem::Audio, 1.5);
    p.add_behaviour("Slow", "s.js", 4.0);
    p.add_behaviour("Fast", "f.js", 0.5);
    p.add_behaviour("Slow", "s.js", 2.0);
    p.end_frame();
    const ProfFrame f = p.last();
    p.set_enabled(false);
    CHECK(f.systemMs[std::size_t(ProfSystem::Audio)] == doctest::Approx(1.5));
    REQUIRE(f.classes.size() == 2);
    CHECK(f.classes[0].className == "Slow");
    CHECK(f.classes[0].ms == doctest::Approx(6.0));
    CHECK(f.classes[0].calls == 2);
    CHECK(f.classes[1].calls == 1);
    CHECK(f.totalMs >= 0.0);
}

TEST_CASE("ProfileSummary: averages per frame, calls per frame, sorted behaviour classes") {
    ProfileSummary s;
    // The busy class runs every frame (2 calls, 4 ms), the idle one every frame (1 call, 0.1 ms), the rare one in 1 of 4 frames.
    for (int i = 0; i < 4; ++i) {
        std::vector<ProfClassSample> c = {{"Busy", "busy.js", 4.0, 2}, {"Idle", "idle.js", 0.1, 1}};
        if (i == 0) c.push_back({"Rare", "rare.js", 8.0, 1});
        s.add_frame(frame(10.0 + i, 5.0, c));
    }
    const Json j = s.to_json();
    CHECK(j["frames"] == 4);
    for (int i = 0; i < kProfSystemCount; ++i) {
        const Json& sys = j["systems"][prof_system_name(ProfSystem(i))];
        CHECK(sys["avgMs"].get<double>() >= 0.0);
        CHECK(sys["p95Ms"].get<double>() >= 0.0);
        CHECK(sys["maxMs"].get<double>() >= sys["avgMs"].get<double>());
    }
    CHECK(j["systems"]["scriptsUpdate"]["avgMs"].get<double>() == doctest::Approx(5.0));
    CHECK(j["frameMs"]["avg"].get<double>() == doctest::Approx(11.5));
    CHECK(j["frameMs"]["max"].get<double>() == doctest::Approx(13.0));
    CHECK(j["frameMs"]["p95"].get<double>() == doctest::Approx(13.0));  // nearest rank
    const Json& b = j["behaviours"];
    REQUIRE(b.size() == 3);
    CHECK(b[0]["class"] == "Busy");  // 4 ms per frame
    CHECK(b[0]["avgMs"].get<double>() == doctest::Approx(4.0));
    CHECK(b[0]["callsPerFrame"].get<double>() == doctest::Approx(2.0));
    CHECK(b[1]["class"] == "Rare");  // 8 ms in one frame of four = 2 ms per frame
    CHECK(b[1]["avgMs"].get<double>() == doctest::Approx(2.0));
    CHECK(b[1]["callsPerFrame"].get<double>() == doctest::Approx(0.25));
    CHECK(b[1]["maxMs"].get<double>() == doctest::Approx(8.0));
    CHECK(b[2]["class"] == "Idle");
    CHECK(b[2]["path"] == "idle.js");
    CHECK(b[0]["avgMs"].get<double>() > b[2]["avgMs"].get<double>());
}

TEST_CASE("ProfileSummary: gpu is null with the reason, or a number; memory start, end and peak") {
    ProfileSummary s;
    s.add_frame(frame(1, 0, {}));
    s.set_gpu_status(false, "no timer queries on WebGL2 here");
    ProfMemory m;
    m.processBytes = 100u << 20;
    m.jsHeapBytes = 2u << 20;
    m.entities = 5;
    s.add_memory(m);
    m.processBytes = 160u << 20;
    m.entities = 50;
    s.add_memory(m);
    m.processBytes = 120u << 20;
    s.add_memory(m);
    Json j = s.to_json();
    CHECK(j["gpu"]["avgMs"].is_null());
    CHECK(j["gpu"]["reason"] == "no timer queries on WebGL2 here");
    CHECK(j["memory"]["start"]["processMB"].get<double>() == doctest::Approx(100.0));
    CHECK(j["memory"]["end"]["processMB"].get<double>() == doctest::Approx(120.0));
    CHECK(j["memory"]["peak"]["processMB"].get<double>() == doctest::Approx(160.0));
    CHECK(j["memory"]["peak"]["entities"] == 50);
    CHECK(j["memory"]["start"]["jsHeapMB"].get<double>() == doctest::Approx(2.0));

    s.set_gpu_status(true, "");
    s.add_gpu_ms(2.0);
    s.add_gpu_ms(4.0);
    j = s.to_json();
    CHECK(j["gpu"]["avgMs"].get<double>() == doctest::Approx(3.0));
    CHECK(j["gpu"]["samples"] == 2);
    CHECK(j["gpu"]["reason"].is_null());
}

TEST_CASE("ProfileSummary: p95 follows the last window, the maximum and average stay exact") {
    ProfileSummary s;
    const int n = int(ProfileSummary::kMaxWindow) + 100;
    for (int i = 0; i < n; ++i) s.add_frame(frame(i < 100 ? 500.0 : 1.0, 0, {}));  // 100 slow frames, then fast ones
    const Json j = s.to_json();
    CHECK(j["frames"] == n);
    CHECK(j["frameMs"]["max"].get<double>() == doctest::Approx(500.0));
    CHECK(j["frameMs"]["p95"].get<double>() == doctest::Approx(1.0));  // the slow frames left the window
    CHECK(j["frameMs"]["avg"].get<double>() == doctest::Approx((100 * 500.0 + (n - 100) * 1.0) / n).epsilon(0.001));
}

TEST_CASE("current_memory_bytes: the process uses memory, and it is not above the peak") {
    const std::uint64_t now = current_memory_bytes();
    CHECK(now > 1024 * 1024);
    CHECK(now <= peak_memory_bytes() + 64ull * 1024 * 1024);  // sampled at slightly different moments
}
