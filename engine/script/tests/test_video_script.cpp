// entity.video and the Video component's clock: time follows the game clock, "ended" comes once, a loop wraps, seek / pause /
// stop, the sound goes to the mixer on the Video's bus. engine/core/tests/data/colors.mpg lasts 1.2 s.
#include <doctest.h>

#include <filesystem>

#include "fa_test_paths.h"
#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {

Json ev(TestHost& h, const std::string& code) {
    auto r = h.scripts.eval(code);
    if (!r.ok()) FAIL(r.error().to_string());
    return *r;
}
std::string ev_err(TestHost& h, const std::string& code) {
    auto r = h.scripts.eval(code);
    return r.ok() ? std::string() : r.error().message;
}
double num(TestHost& h, const std::string& code) { return ev(h, code).get<double>(); }

void install_fixture(TestHost& h) {
    std::filesystem::create_directories(h.root / "assets/video");
    std::filesystem::copy_file(FA_VIDEO_FIXTURE, h.root / "assets/video/colors.mpg",
                               std::filesystem::copy_options::overwrite_existing);
}

const char* kSpawn = R"(globalThis.e = world.spawn({ id: 'intro', components: {
    Video: { path: 'assets/video/colors.mpg', size: [320, 180], bus: 'ui' } } });
    globalThis.ended = [];
    e.video.on('ended', (d) => ended.push('mine:' + d.id + ':' + d.path));
    world.on('video.ended', (d) => ended.push('world'));)";

}  // namespace

TEST_CASE("entity.video: time follows the game clock, one second of steps is one second of video") {
    TestHost h("video_clock");
    install_fixture(h);
    REQUIRE(h.start());
    ev(h, kSpawn);
    h.step_frames(1);
    CHECK(num(h, "e.video.duration") == doctest::Approx(1.2).epsilon(0.05));
    CHECK(ev(h, "e.video.playing").get<bool>());  // autoplay
    h.step_frames(29);
    CHECK(num(h, "e.video.time") == doctest::Approx(0.5).epsilon(0.01));  // 30 steps of 1/60 s
    h.step_frames(30);
    CHECK(num(h, "e.video.time") == doctest::Approx(1.0).epsilon(0.01));
    CHECK_FALSE(ev(h, "e.video.ended").get<bool>());
}

TEST_CASE("entity.video: ended arrives once per play, play() after the end starts over") {
    TestHost h("video_ended");
    install_fixture(h);
    REQUIRE(h.start());
    ev(h, kSpawn);
    h.step_frames(120);  // 2 s: past the end of 1.2 s
    CHECK(ev(h, "ended.join(',')").get<std::string>() == "mine:intro:assets/video/colors.mpg,world");
    CHECK(ev(h, "e.video.ended").get<bool>());
    CHECK_FALSE(ev(h, "e.video.playing").get<bool>());
    CHECK(num(h, "e.video.time") == doctest::Approx(num(h, "e.video.duration")));
    h.step_frames(60);
    CHECK(num(h, "ended.length") == 2);  // still the same single event (mine + world), nothing more

    ev(h, "ended.length = 0; e.video.play();");
    h.step_frames(10);
    CHECK_FALSE(ev(h, "e.video.ended").get<bool>());
    CHECK(num(h, "e.video.time") < 0.5);
    CHECK(num(h, "e.video.time") > 0.0);
    h.step_frames(120);
    CHECK(num(h, "ended.length") == 2);  // and it ended again, once
}

TEST_CASE("entity.video: loop wraps without an ended event") {
    TestHost h("video_loop");
    install_fixture(h);
    REQUIRE(h.start());
    ev(h, R"(globalThis.e = world.spawn({ id: 'bg', components: { Video: { path: 'assets/video/colors.mpg', loop: true } } });
        globalThis.ended = 0; world.on('video.ended', () => ended++); globalThis.maxT = 0;)");
    for (int i = 0; i < 6; ++i) {  // 6 s = five times the length
        h.step_frames(60);
        ev(h, "maxT = Math.max(maxT, e.video.time)");
    }
    CHECK(num(h, "ended") == 0);
    CHECK(ev(h, "e.video.playing").get<bool>());
    CHECK(num(h, "maxT") <= num(h, "e.video.duration") + 1e-4);
    CHECK(num(h, "e.video.time") < num(h, "e.video.duration"));
}

TEST_CASE("entity.video: seek, pause, stop and a time written before the file was open") {
    TestHost h("video_seek");
    install_fixture(h);
    REQUIRE(h.start());
    ev(h, R"(globalThis.e = world.spawn({ id: 'v', components: { Video: { path: 'assets/video/colors.mpg', autoplay: false } } });
        e.video.seek(0.9);)");  // before the first step opened the file
    h.step_frames(1);
    CHECK(num(h, "e.video.time") == doctest::Approx(0.9).epsilon(0.001));
    CHECK_FALSE(ev(h, "e.video.playing").get<bool>());
    h.step_frames(30);
    CHECK(num(h, "e.video.time") == doctest::Approx(0.9).epsilon(0.001));  // paused: it did not move
    ev(h, "e.video.play()");
    h.step_frames(6);
    CHECK(num(h, "e.video.time") == doctest::Approx(1.0).epsilon(0.02));
    ev(h, "e.video.pause()");
    const double t = num(h, "e.video.time");
    h.step_frames(20);
    CHECK(num(h, "e.video.time") == doctest::Approx(t));
    ev(h, "e.video.stop()");
    h.step_frames(1);
    CHECK(num(h, "e.video.time") == 0.0);
    CHECK_FALSE(ev(h, "e.video.playing").get<bool>());
    ev(h, "e.video.seek(99)");  // clamped to the end, no ended event from a seek
    h.step_frames(2);
    CHECK(num(h, "e.video.time") == doctest::Approx(num(h, "e.video.duration")));
}

TEST_CASE("entity.video: mistakes teach, and a missing file is a warning, not a crash") {
    TestHost h("video_errors");
    install_fixture(h);
    REQUIRE(h.start());
    ev(h, "globalThis.plain = world.spawn({ id: 'plain', components: {} });");
    CHECK(ev_err(h, "plain.video").find("Video") != std::string::npos);
    ev(h, R"(globalThis.v = world.spawn({ id: 'v', components: { Video: { path: 'assets/video/colors.mpg' } } });)");
    CHECK(ev_err(h, "v.video.on('end', () => {})").find("ended") != std::string::npos);
    CHECK(ev_err(h, "v.video.seek('soon')").find("seconds") != std::string::npos);
    ev(h, R"(globalThis.m = world.spawn({ id: 'm', components: { Video: { path: 'assets/video/missing.mpg' } } });)");
    h.step_frames(5);
    CHECK(num(h, "m.video.duration") == 0.0);
    CHECK_FALSE(ev(h, "m.video.playing").get<bool>());
}

TEST_CASE("Video: the sound is a mixer voice on the chosen bus that ends with the entity") {
    TestHost h("video_audio");
    install_fixture(h);
    REQUIRE(h.start());
    ev(h, kSpawn);
    h.step_frames(10);
    const auto log = h.au.play_log();
    REQUIRE(log.size() == 1);
    CHECK(log[0].path == "assets/video/colors.mpg");
    CHECK(log[0].bus == "ui");
    CHECK(log[0].source == "intro");
    CHECK(log[0].ok);
    CHECK(h.au.stats()["activeVoices"].get<int>() == 1);
    h.step_frames(60);
    CHECK(h.au.stats()["activeVoices"].get<int>() == 1);  // still one voice, never a second one per loop or seek
    ev(h, "e.video.seek(0.2)");
    h.step_frames(2);
    CHECK(h.au.play_log().size() == 1);
    ev(h, "e.destroy()");
    h.step_frames(2);
    CHECK(h.au.stats()["activeVoices"].get<int>() == 0);
}
