// M79-P1n: what the denoiser's plan says and when its history holds (src/rt_denoise.cpp), without a GPU.
#include <doctest.h>

#include <cmath>
#include <cstdint>
#include <limits>
#include <string>

#include "rt_denoise.h"

using namespace fa::render;

namespace {
DenoiseCamera cam_at(std::uint64_t serial) {
    DenoiseCamera c;
    c.serial = serial;
    c.sceneKey = 1;
    c.prevValid = true;
    return c;
}
DenoiseHistoryState state_of(std::uint64_t serial, std::uint64_t config = 5) {
    DenoiseHistoryState s;
    s.wrote = true;
    s.width = 64;
    s.height = 48;
    s.serial = serial;
    s.sceneKey = 1;
    s.configKey = config;
    return s;
}
}  // namespace

TEST_CASE("denoise plan: the passes and images of each kind") {
    DenoiseSignal s;
    s.kind = DenoiseKind::Visibility;
    const DenoisePlan v = make_denoise_plan(s, 640, 360, true);
    CHECK(v.on);
    CHECK(v.channels == 1);
    CHECK(v.signalPasses == 1 + 5);  // the temporal pass and the five iterations
    CHECK(v.guidePasses == 1);
    CHECK(v.transients == 3);  // the accumulation and the two iteration buffers
    CHECK(v.historyImages == 4);
    CHECK_FALSE(v.hitDistance);

    s.kind = DenoiseKind::Occlusion;
    CHECK(make_denoise_plan(s, 640, 360, true).channels == 1);

    s.kind = DenoiseKind::Diffuse;
    const DenoisePlan d = make_denoise_plan(s, 640, 360, true);
    CHECK(d.channels == 3);
    CHECK_FALSE(d.hitDistance);

    s.kind = DenoiseKind::Specular;
    s.settings.iterations = 2;
    s.debug = DenoiseDebug::Variance;
    const DenoisePlan sp = make_denoise_plan(s, 640, 360, true);
    CHECK(sp.channels == 3);
    CHECK(sp.hitDistance);
    CHECK(sp.signalPasses == 1 + 2 + 1);  // the debug view is one more pass and one more image
    CHECK(sp.transients == 1 + 1 + 1);
}

TEST_CASE("denoise plan: a disabled signal or an empty image costs nothing") {
    DenoiseSignal s;
    s.enabled = false;
    const DenoisePlan off = make_denoise_plan(s, 640, 360, true);
    CHECK_FALSE(off.on);
    CHECK(off.signalPasses == 0);
    CHECK(off.guidePasses == 0);
    CHECK(off.transients == 0);
    CHECK(off.historyImages == 0);
    CHECK(off.historyBytes == 0);
    s.enabled = true;
    CHECK_FALSE(make_denoise_plan(s, 0, 360, true).on);
    CHECK_FALSE(make_denoise_plan(s, 640, -1, true).on);
}

TEST_CASE("denoise plan: the history bytes follow the size and the moments' precision, saturated") {
    DenoiseSignal s;
    const DenoisePlan a = make_denoise_plan(s, 100, 50, true);
    const DenoisePlan b = make_denoise_plan(s, 100, 50, false);
    CHECK(a.historyBytes > b.historyBytes);
    CHECK(a.historyBytes - b.historyBytes == 2u * 100u * 50u * 8u);  // two moment images, 16 bytes against 8 a pixel
    CHECK(a.guideBytes == 2u * 100u * 50u * 8u);
    const DenoisePlan huge = make_denoise_plan(s, 1 << 30, 1 << 30, true);
    CHECK(huge.on);
    CHECK(huge.historyBytes >= (std::uint64_t(1) << 60));  // 64-bit, no wrap
}

TEST_CASE("denoise plan: the settings are clamped and a number that is not finite takes its default") {
    DenoiseSettings s;
    s.iterations = 99;
    s.maxHistory = -4;
    s.fireflyClamp = 1000;
    s.depthTolerance = 0;
    s.normalPower = std::numeric_limits<float>::quiet_NaN();
    s.lumaSigma = std::numeric_limits<float>::infinity();
    s.roughness = 3;
    const DenoiseSettings c = sanitize_denoise_settings(s);
    CHECK(c.iterations == 6);
    CHECK(c.maxHistory == 1.0f);
    CHECK(c.fireflyClamp == 64.0f);
    CHECK(c.depthTolerance == doctest::Approx(0.001f));
    CHECK(c.normalPower == DenoiseSettings{}.normalPower);
    CHECK(c.lumaSigma == DenoiseSettings{}.lumaSigma);
    CHECK(c.roughness == 1.0f);
    s.iterations = 0;
    CHECK(sanitize_denoise_settings(s).iterations == 2);
    // The firefly clamp is for the radiance kinds; a shadow is bounded.
    DenoiseSignal sig;
    sig.kind = DenoiseKind::Visibility;
    CHECK(make_denoise_plan(sig, 8, 8, true).settings.fireflyClamp == 0.0f);
    sig.kind = DenoiseKind::Diffuse;
    CHECK(make_denoise_plan(sig, 8, 8, true).settings.fireflyClamp == 8.0f);
}

TEST_CASE("denoise plan: the config key follows what the history's numbers mean, not the filter") {
    DenoiseSignal a;
    DenoiseSignal b = a;
    CHECK(make_denoise_plan(a, 8, 8, true).configKey == make_denoise_plan(b, 8, 8, true).configKey);
    b.settings.iterations = 3;
    b.settings.lumaSigma = 2;
    b.settings.normalPower = 8;
    b.debug = DenoiseDebug::HistoryLength;
    CHECK(make_denoise_plan(a, 8, 8, true).configKey == make_denoise_plan(b, 8, 8, true).configKey);
    b.settings.maxHistory = 16;
    CHECK(make_denoise_plan(a, 8, 8, true).configKey != make_denoise_plan(b, 8, 8, true).configKey);
    b = a;
    b.kind = DenoiseKind::Specular;
    CHECK(make_denoise_plan(a, 8, 8, true).configKey != make_denoise_plan(b, 8, 8, true).configKey);
}

TEST_CASE("denoise history: the first rule that breaks it names the reason") {
    CHECK(denoise_reset_reason(DenoiseHistoryState{}, cam_at(1), 64, 48, 5) == DenoiseReset::Fresh);
    CHECK(denoise_reset_reason(state_of(1), cam_at(2), 64, 48, 5) == DenoiseReset::None);
    CHECK(denoise_reset_reason(state_of(1), cam_at(2), 80, 48, 5) == DenoiseReset::Resize);
    CHECK(denoise_reset_reason(state_of(1), cam_at(2), 64, 40, 5) == DenoiseReset::Resize);
    CHECK(denoise_reset_reason(state_of(1), cam_at(3), 64, 48, 5) == DenoiseReset::Gap);
    CHECK(denoise_reset_reason(state_of(5), cam_at(5), 64, 48, 5) ==
          DenoiseReset::Gap);  // the same frame twice is not a next frame
    DenoiseCamera other = cam_at(2);
    other.sceneKey = 2;
    CHECK(denoise_reset_reason(state_of(1), other, 64, 48, 5) == DenoiseReset::Scene);
    other = cam_at(2);
    other.originShifts = 1;
    CHECK(denoise_reset_reason(state_of(1), other, 64, 48, 5) == DenoiseReset::Origin);
    CHECK(denoise_reset_reason(state_of(1), cam_at(2), 64, 48, 6) == DenoiseReset::Settings);
    other = cam_at(2);
    other.prevValid = false;
    CHECK(denoise_reset_reason(state_of(1), other, 64, 48, 5) == DenoiseReset::Cut);
    // Several at once: the order is Resize, Gap, Scene, Origin, Settings, Cut.
    other.sceneKey = 2;
    other.originShifts = 4;
    CHECK(denoise_reset_reason(state_of(1), other, 64, 48, 6) == DenoiseReset::Scene);
    other.sceneKey = 1;
    CHECK(denoise_reset_reason(state_of(1), other, 64, 48, 6) == DenoiseReset::Origin);
    other.originShifts = 0;
    CHECK(denoise_reset_reason(state_of(1), other, 64, 48, 6) == DenoiseReset::Settings);
}

TEST_CASE("denoise: every kind and reason has a name") {
    for (DenoiseKind k : {DenoiseKind::Visibility, DenoiseKind::Occlusion, DenoiseKind::Diffuse, DenoiseKind::Specular})
        CHECK(std::string(denoise_kind_name(k)).size() > 2);
    for (DenoiseReset r : {DenoiseReset::None, DenoiseReset::Fresh, DenoiseReset::Resize, DenoiseReset::Gap,
                           DenoiseReset::Scene, DenoiseReset::Origin, DenoiseReset::Settings, DenoiseReset::Cut})
        CHECK(std::string(denoise_reset_name(r)).size() > 2);
}

TEST_CASE("denoise: a renderer's denoiser that nothing asked is free") {
    RtDenoiser d;
    CHECK_FALSE(d.shaders_made());
    CHECK_FALSE(d.unavailable());
    CHECK(d.pipeline_count() == 0);
    CHECK(d.history_image_count() == 0);
    CHECK(d.resets() == 0);
    CHECK(d.last_reset(1, 1) == DenoiseReset::Fresh);
    CHECK_FALSE(d.last_used_history(1, 1));
    d.sweep(100);
    d.reset();
    d.drop_signal(1, 1);
    d.forget_targets();
    CHECK_FALSE(d.shaders_made());
}
