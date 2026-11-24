// M76-P6c: dynamic resolution (fa/render/dynamic_resolution.h): the settings parser with its teaching errors and the controller, fed injected frame times (no
// clock, no GPU), so the same numbers give the same scales on every machine.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <functional>
#include <string>
#include <vector>

#include "fa/render/dynamic_resolution.h"
#include "fa/render/upscaler.h"

using namespace fa;
using namespace fa::render;

namespace {

constexpr double kFrameMs = 1000.0 / 60.0;  // the elapsed time of one tick: the frames of these tests are 60 Hz

DynamicResolutionSettings on(float minScale = 0.5f, float maxScale = 1.0f, double targetMs = 16.7) {
    DynamicResolutionSettings s;
    s.enabled = true;
    s.targetMs = targetMs;
    s.minScale = minScale;
    s.maxScale = maxScale;
    return s;
}

struct Run {
    std::vector<double> changeAt;  // seconds of every change
    std::vector<float> scaleAt;    // the scale after each tick
    double seconds = 0.0;
    int changesBetween(double from, double to) const {
        int n = 0;
        for (double t : changeAt)
            if (t >= from && t < to) ++n;
        return n;
    }
};

// Ticks the controller for `seconds`; `cost(scale, t)` is the frame time the game would take at that scale (ms), `measure` turns it into the sample.
Run drive(
    DynamicResolutionController& c, double seconds, bool exact, const std::function<double(float, double)>& cost,
    const std::function<double(double)>& measure = [](double ms) { return ms; }, double targetMs = 16.7) {
    Run run;
    const int frames = int(std::lround(seconds * 60.0));
    for (int i = 0; i < frames; ++i) {
        run.seconds = double(i) / 60.0;
        const double sample = measure(cost(c.scale(), run.seconds));
        if (c.update(sample, kFrameMs, targetMs, exact)) run.changeAt.push_back(run.seconds);
        run.scaleAt.push_back(c.scale());
    }
    return run;
}

}  // namespace

TEST_CASE("dynamic resolution: the defaults are off, 0.5..1, and the JSON round-trips") {
    const DynamicResolutionSettings d;
    CHECK_FALSE(d.enabled);
    CHECK(d.targetMs == 0.0);
    CHECK(d.minScale == 0.5f);
    CHECK(d.maxScale == 1.0f);
    const Json j = dynamic_resolution_to_json(d);
    auto back = parse_dynamic_resolution_settings(j, "x", DynamicResolutionSettings{});
    REQUIRE(back.ok());
    CHECK(back.value() == d);
    // A partial object changes only its keys.
    auto part = parse_dynamic_resolution_settings(Json::parse(R"({"enabled": true, "minScale": 0.6})"), "x",
                                                  on(0.5f, 0.9f, 33.3));
    REQUIRE(part.ok());
    CHECK(part->enabled);
    CHECK(part->minScale == doctest::Approx(0.6f));
    CHECK(part->maxScale == doctest::Approx(0.9f));
    CHECK(part->targetMs == doctest::Approx(33.3));
    auto nul = parse_dynamic_resolution_settings(Json::parse(R"({"targetMs": null})"), "x", on());
    REQUIRE(nul.ok());
    CHECK(nul->targetMs == 0.0);
}

TEST_CASE("dynamic resolution: a wrong setting teaches with the pointer, the number and the way out") {
    auto fail = [](const char* text, const char* where = "factoria.json#/render/dynamicResolution") {
        auto r = parse_dynamic_resolution_settings(Json::parse(text), where, DynamicResolutionSettings{});
        REQUIRE_FALSE(r.ok());
        return r.error().message + " | " + r.error().hint;
    };
    CHECK(fail(R"({"enabled": "yes"})").find("factoria.json#/render/dynamicResolution/enabled") != std::string::npos);
    CHECK(fail(R"({"targetMs": 2})").find("/targetMs") != std::string::npos);
    CHECK(fail(R"({"targetMs": 2})").find("4..100") != std::string::npos);
    CHECK(fail(R"({"targetMs": "fast"})").find("expected a number") != std::string::npos);
    CHECK(fail(R"({"minScale": 0.1})").find("outside 0.25..1") != std::string::npos);
    CHECK(fail(R"({"maxScale": 1.5})").find("/maxScale") != std::string::npos);
    const std::string order = fail(R"({"minScale": 0.9, "maxScale": 0.6})");
    CHECK(order.find("minScale 0.9 is above maxScale 0.6") != std::string::npos);
    CHECK(fail(R"({"enable": true})").find("enabled") != std::string::npos);  // did you mean
    CHECK(fail("[1]").find("expected an object") != std::string::npos);
    CHECK(fail("{\"enabled\": 3}", "render.dynamic_resolution").find("render.dynamic_resolution/enabled") !=
          std::string::npos);
}

TEST_CASE("dynamic resolution: the target follows the display when it is unset") {
    DynamicResolutionSettings s = on();
    s.targetMs = 0.0;
    CHECK(dynamic_target_ms(s, 0.0) == doctest::Approx(1000.0 / 60.0));
    CHECK(dynamic_target_ms(s, 120.0) == doctest::Approx(1000.0 / 120.0));
    CHECK(dynamic_target_ms(s, 5.0) == doctest::Approx(1000.0 / 60.0));  // nonsense: the default
    s.targetMs = 33.3;
    CHECK(dynamic_target_ms(s, 120.0) == doctest::Approx(33.3));
}

namespace {

// Feeds `n` intervals made by `make(i)` and returns the call that finished the estimate (-1: none did).
int feed(RefreshRateEstimator& e, int n, const std::function<double(int)>& make) {
    for (int i = 0; i < n; ++i)
        if (e.add(make(i))) return i;
    return -1;
}

}  // namespace

TEST_CASE("refresh rate estimate: the median of the presented frames, after the first ones, without the hitches") {
    SUBCASE("a steady 144 Hz display, behind a slow start") {
        RefreshRateEstimator e;
        const int last =
            feed(e, 400, [](int i) { return i < RefreshRateEstimator::kSkipFrames ? 40.0 : 1000.0 / 144.0; });
        CHECK(last == RefreshRateEstimator::kSkipFrames + RefreshRateEstimator::kSamples - 1);
        REQUIRE(e.done());
        CHECK(e.hz() == doctest::Approx(144.0));
        CHECK_FALSE(e.add(5.0));  // done: later frames change nothing
        CHECK(e.hz() == doctest::Approx(144.0));
    }
    SUBCASE("noise around 120 Hz and hitches over 50 ms are left out") {
        RefreshRateEstimator e;
        // +-0.4 ms of noise (a fixed pattern, no rng), a 200 ms load every 7th frame and a 30 ms double frame every 13th.
        const int last = feed(e, 400, [](int i) {
            if (i % 7 == 3) return 200.0;
            if (i % 13 == 5) return 30.0;
            return 1000.0 / 120.0 + 0.4 * double((i * 37) % 9 - 4) / 4.0;
        });
        REQUIRE(last > 0);
        CHECK(e.samples() == RefreshRateEstimator::kSamples);
        CHECK(e.hz() == doctest::Approx(120.0).epsilon(0.02));
        // The target it gives: one 120 Hz refresh.
        DynamicResolutionSettings s = on();
        s.targetMs = 0.0;
        CHECK(dynamic_target_ms(s, e.hz()) == doctest::Approx(1000.0 / 120.0).epsilon(0.02));
    }
    SUBCASE("59.94 Hz is not rounded") {
        RefreshRateEstimator e;
        feed(e, 200, [](int) { return 1001.0 / 60.0; });
        CHECK(e.hz() == doctest::Approx(59.94).epsilon(0.0005));
    }
    SUBCASE("a game slower than 20 fps gives up after kMaxFrames, with no rate: the default holds") {
        RefreshRateEstimator e;
        const int last = feed(e, 1000, [](int) { return 70.0; });
        CHECK(last == RefreshRateEstimator::kMaxFrames - 1);
        CHECK(e.done());
        CHECK(e.hz() == 0.0);
        DynamicResolutionSettings s = on();
        s.targetMs = 0.0;
        CHECK(dynamic_target_ms(s, e.hz()) == doctest::Approx(1000.0 / kDynamicDefaultRefreshHz));
    }
    SUBCASE("nonsense intervals are ignored and reset() starts over") {
        RefreshRateEstimator e;
        feed(e, 30, [](int i) { return i % 2 ? -1.0 : 0.0; });
        CHECK(e.samples() == 0);
        CHECK_FALSE(e.done());
        feed(e, 200, [](int) { return 1000.0 / 75.0; });
        CHECK(e.hz() == doctest::Approx(75.0));
        e.reset();
        CHECK_FALSE(e.done());
        CHECK(e.hz() == 0.0);
        CHECK(e.samples() == 0);
        feed(e, 200, [](int) { return 1000.0 / 240.0; });
        CHECK(e.hz() == doctest::Approx(240.0));
    }
    SUBCASE("the same intervals give the same rate") {
        RefreshRateEstimator a, b;
        auto jitter = [](int i) { return 16.0 + double((i * 7919) % 101) / 100.0; };
        feed(a, 300, jitter);
        feed(b, 300, jitter);
        CHECK(a.hz() == b.hz());
    }
}

TEST_CASE("dynamic resolution: off is a factor of 1 and never changes") {
    DynamicResolutionController c;
    CHECK(c.scale() == 1.0f);
    CHECK_FALSE(c.update(100.0, kFrameMs, 16.7, true));
    CHECK(c.scale() == 1.0f);
    c.configure(on());
    CHECK(c.scale() == 1.0f);  // starts at the largest scale
    DynamicResolutionSettings off = on();
    off.enabled = false;
    c.configure(off);
    CHECK(c.scale() == 1.0f);
    CHECK(c.changes() == 0);
}

TEST_CASE("dynamic resolution: with a GPU time it converges to the target, then holds without changing") {
    DynamicResolutionController c;
    c.configure(on());
    // The frame costs 24 ms at the full size and follows the picture's area.
    const auto cost = [](float s, double) { return 24.0 * double(s) * double(s); };
    const Run run = drive(c, 40.0, true, cost);
    const double settled = cost(c.scale(), 0.0);
    CHECK(settled <= 16.7 * 0.95);               // under the top of the band
    CHECK(settled >= 16.7 * 0.80);               // and not wastefully low
    CHECK(run.changesBetween(0.0, 40.0) <= 6);   // a few moves, not a search
    CHECK(run.changesBetween(10.0, 40.0) == 0);  // and then it holds
    // The limit of the changes per second: the hold times.
    for (size_t i = 1; i < run.changeAt.size(); ++i) CHECK(run.changeAt[i] - run.changeAt[i - 1] >= 0.5 - 1e-9);
    for (double t = 0.0; t < 39.0; t += 1.0) CHECK(run.changesBetween(t, t + 1.0) <= 2);
    // No scale below the first step's reach or above the range.
    for (float s : run.scaleAt) {
        CHECK(s >= 0.5f);
        CHECK(s <= 1.0f);
    }
}

TEST_CASE("dynamic resolution: a step is at most a quarter of the range down and an eighth up") {
    DynamicResolutionController d;
    d.configure(on(0.25f, 1.0f));
    float before = d.scale();
    CHECK(before == 1.0f);
    int moves = 0;
    for (int i = 0; i < 600; ++i) {
        if (d.update(200.0, kFrameMs, 16.7, true)) {
            ++moves;
            const float after = d.scale();
            CHECK(before - after <= 0.75f * 0.25f + 1e-5f);  // 8 of 32 steps of a 0.75 range
            CHECK(after < before);
            before = after;
        }
    }
    CHECK(moves >= 3);
    CHECK(d.scale() == doctest::Approx(0.25f));  // and it reached the floor
    // Up: a light game after that climbs an eighth (4 of 32 steps) at most per change.
    int ups = 0;
    for (int i = 0; i < 60 * 60; ++i) {
        if (d.update(2.0, kFrameMs, 16.7, true)) {
            ++ups;
            const float after = d.scale();
            CHECK(after - before <= 0.75f / 8.0f + 1e-5f);
            CHECK(after > before);
            before = after;
        }
    }
    CHECK(ups >= 2);
    CHECK(d.scale() == doctest::Approx(1.0f));
}

TEST_CASE("dynamic resolution: a light game stays at the largest scale and never changes") {
    DynamicResolutionController c;
    c.configure(on());
    const Run gpu = drive(c, 30.0, true, [](float s, double) { return 8.0 * double(s) * double(s); });
    CHECK(gpu.changeAt.empty());
    CHECK(c.scale() == 1.0f);
    DynamicResolutionController v;  // the interval measure: vsync pins the frame at the refresh rate
    v.configure(on());
    const Run vs = drive(
        v, 60.0, false, [](float s, double) { return 8.0 * double(s) * double(s); },
        [](double ms) { return std::max(ms, 16.7); });
    CHECK(vs.changeAt.empty());
    CHECK(v.scale() == 1.0f);
}

TEST_CASE("dynamic resolution: the limits hold, a game that cannot reach the target stops at minScale") {
    DynamicResolutionController c;
    c.configure(on(0.6f, 0.9f));
    CHECK(c.scale() == doctest::Approx(0.9f));  // starts at maxScale
    const Run run = drive(c, 30.0, true, [](float, double) { return 100.0; });
    CHECK(c.scale() == doctest::Approx(0.6f));
    for (float s : run.scaleAt) CHECK(s >= 0.6f - 1e-6f);
    CHECK(run.changesBetween(10.0, 30.0) == 0);  // at the floor it stops, nothing to move
    DynamicResolutionController tight;
    tight.configure(on(0.8f, 0.8f));  // a range of one point: nothing to do
    drive(tight, 10.0, true, [](float, double) { return 100.0; });
    CHECK(tight.scale() == doctest::Approx(0.8f));
    CHECK(tight.changes() == 0);
}

TEST_CASE("dynamic resolution: a one-frame hitch changes nothing, a sustained load does and it comes back up") {
    DynamicResolutionController c;
    c.configure(on());
    const auto cost = [](float s, double) { return 12.0 * double(s) * double(s); };
    drive(c, 10.0, true, cost);
    CHECK(c.changes() == 0);
    // One frame of 50 ms (the engine caps a sample at three targets).
    CHECK_FALSE(c.update(50.0, kFrameMs, 16.7, true));
    drive(c, 5.0, true, cost);
    CHECK(c.changes() == 0);
    // A load that lasts (a heavy scene) and then goes away.
    const Run heavy = drive(c, 10.0, true, [](float s, double) { return 30.0 * double(s) * double(s); });
    CHECK(c.scale() < 0.9f);
    CHECK_FALSE(heavy.changeAt.empty());
    drive(c, 30.0, true, cost);
    CHECK(c.scale() == doctest::Approx(1.0f));
}

TEST_CASE("dynamic resolution: with the interval measure it goes down by prediction, tries one step up when quiet, and "
          "a failed try waits longer") {
    DynamicResolutionController c;
    c.configure(on());
    // The game costs 24 ms at full size; the sample is the vsync-pinned interval (a multiple of 16.7 ms is not modelled: one refresh).
    const auto cost = [](float s, double) { return 24.0 * double(s) * double(s); };
    const auto vsync = [](double ms) { return std::max(ms, 16.7); };
    const Run run = drive(c, 120.0, false, cost, vsync);
    CHECK(cost(c.scale(), 0.0) <= 16.7 * 1.08 + 1e-9);  // never settles above the top of the band
    CHECK(cost(c.scale(), 0.0) >= 16.7 * 0.7);          // and not far below it
    for (size_t i = 1; i < run.changeAt.size(); ++i) CHECK(run.changeAt[i] - run.changeAt[i - 1] >= 0.5 - 1e-9);
    // The tries up get rarer (3 s, 6 s, ... up to 48 s): in the last minute there are few changes.
    CHECK(run.changesBetween(40.0, 120.0) == 0);
    CHECK(run.changesBetween(0.0, 120.0) <= 12);
}

TEST_CASE("dynamic resolution: the same numbers give the same scales (no clock, no random)") {
    auto once = [] {
        DynamicResolutionController c;
        c.configure(on());
        return drive(c, 20.0, true,
                     [](float s, double t) { return (20.0 + 5.0 * std::sin(t)) * double(s) * double(s); })
            .scaleAt;
    };
    CHECK(once() == once());
}

TEST_CASE("dynamic resolution: changing the range or turning it off starts at the largest scale again") {
    DynamicResolutionController c;
    c.configure(on());
    drive(c, 10.0, true, [](float, double) { return 100.0; });
    CHECK(c.scale() < 1.0f);
    DynamicResolutionSettings same = on();
    same.targetMs = 33.3;  // only the target: the scale is kept
    const float kept = c.scale();
    c.configure(same);
    CHECK(c.scale() == kept);
    c.configure(on(0.3f, 1.0f));
    CHECK(c.scale() == 1.0f);
    drive(c, 10.0, true, [](float, double) { return 100.0; });
    DynamicResolutionSettings off = on();
    off.enabled = false;
    c.configure(off);
    CHECK(c.scale() == 1.0f);
    c.configure(on());
    CHECK(c.scale() == 1.0f);
}

TEST_CASE("dynamic resolution: plan_upscale_scale multiplies the factor in, floors it at 0.25, and off is the same "
          "arithmetic") {
    constexpr float kMin = 0.25f;
    CHECK(plan_upscale_scale(1.0f, UpscalerQuality::Performance, UpscalerMode::Spatial, kMin, 1.0f).scale ==
          plan_upscale_scale(1.0f, UpscalerQuality::Performance, UpscalerMode::Spatial, kMin).scale);
    const UpscaleScalePlan p = plan_upscale_scale(1.0f, UpscalerQuality::Balanced, UpscalerMode::Stretch, kMin, 0.5f);
    CHECK(p.scale == doctest::Approx(1.0f / 1.7f * 0.5f));
    CHECK(p.stage);
    CHECK(plan_upscale_scale(0.5f, UpscalerQuality::UltraPerformance, UpscalerMode::Stretch, kMin, 0.5f).scale == kMin);
    // A full-size factor at native quality draws nothing extra.
    CHECK_FALSE(plan_upscale_scale(1.0f, UpscalerQuality::Native, UpscalerMode::Stretch, kMin, 1.0f).stage);
    CHECK(plan_upscale_scale(1.0f, UpscalerQuality::Native, UpscalerMode::Stretch, kMin, 0.75f).stage);
}
