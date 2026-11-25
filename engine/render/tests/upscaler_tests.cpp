// M76-P0: the upscaler setting (fa/render/upscaler.h) and the graphics preset names (fa/render/graphics_preset.h): the parser, its teaching
// errors, the scales, the JSON, and the velocity contract constants of the post plan.
#include <doctest.h>

#include <cmath>
#include <string>

#include "fa/render/graphics_preset.h"
#include "fa/render/upscaler.h"
#include "postprocess.h"

using namespace fa;
using namespace fa::render;

TEST_CASE("upscaler: the defaults are stretch, native, 0.5, and a stretch setting draws as stretch whatever the caps") {
    const UpscalerSettings s;
    CHECK(s.mode == UpscalerMode::Stretch);
    CHECK(s.quality == UpscalerQuality::Native);
    CHECK(s.sharpness == 0.5f);
    for (const bool spatial : {false, true})
        for (const bool temporal : {false, true})
            for (const bool metalfx : {false, true}) {
                UpscalerCaps caps;
                caps.spatial = spatial;
                caps.temporal = temporal;
                caps.metalfx = metalfx;
                CHECK(effective_upscaler_mode(s, caps) == UpscalerMode::Stretch);
            }
    CHECK(effective_upscaler_mode(s) == UpscalerMode::Stretch);
}

TEST_CASE(
    "upscaler: effective_upscaler_mode follows the caps: pixel art is stretch, the rest falls to the best drawable") {
    UpscalerSettings t;
    UpscalerCaps gpu;  // the default caps: spatial only
    // Pixel art keeps its hard edges whatever the setting asks for.
    UpscalerCaps art = gpu;
    art.pixelArt = true;
    art.temporal = art.metalfx = true;
    for (int m = 0; m < kUpscalerModeCount; ++m) {
        t.mode = UpscalerMode(m);
        CAPTURE(upscaler_mode_name(t.mode));
        CHECK(effective_upscaler_mode(t, art) == UpscalerMode::Stretch);
    }
    // A GPU that draws spatial only: spatial, auto, temporal and metalfx all give the spatial upscaler.
    for (const UpscalerMode m :
         {UpscalerMode::Spatial, UpscalerMode::Auto, UpscalerMode::Temporal, UpscalerMode::MetalFx}) {
        t.mode = m;
        CAPTURE(upscaler_mode_name(m));
        CHECK(effective_upscaler_mode(t, gpu) == UpscalerMode::Spatial);
        CHECK(effective_upscaler_mode(t) == UpscalerMode::Spatial);
    }
    // No renderer able to draw anything (no GPU): stretch, so what is read back says what is drawn.
    UpscalerCaps none;
    none.spatial = false;
    for (int m = 0; m < kUpscalerModeCount; ++m) {
        t.mode = UpscalerMode(m);
        CHECK(effective_upscaler_mode(t, none) == UpscalerMode::Stretch);
    }
    // The branches the later packages switch on: temporal and MetalFX when they can be drawn, auto picks the best.
    UpscalerCaps tem = gpu;
    tem.temporal = true;
    t.mode = UpscalerMode::Temporal;
    CHECK(effective_upscaler_mode(t, tem) == UpscalerMode::Temporal);
    t.mode = UpscalerMode::Auto;
    CHECK(effective_upscaler_mode(t, tem) == UpscalerMode::Temporal);
    t.mode = UpscalerMode::MetalFx;
    CHECK(effective_upscaler_mode(t, tem) == UpscalerMode::Temporal);
    UpscalerCaps fx = tem;
    fx.metalfx = true;
    CHECK(effective_upscaler_mode(t, fx) == UpscalerMode::MetalFx);
    t.mode = UpscalerMode::Auto;
    CHECK(effective_upscaler_mode(t, fx) == UpscalerMode::MetalFx);
    t.mode = UpscalerMode::Spatial;
    CHECK(effective_upscaler_mode(t, fx) == UpscalerMode::Spatial);  // an explicit choice is kept
}

TEST_CASE("upscaler: plan_upscale_scale multiplies the player's scale by the quality's, floors it at 0.25, and runs "
          "the stage below 1 or for a filter") {
    constexpr float kMin = 0.25f;
    // The quality presets.
    CHECK(plan_upscale_scale(1.0f, UpscalerQuality::Native, UpscalerMode::Stretch, kMin).scale == 1.0f);
    CHECK(plan_upscale_scale(1.0f, UpscalerQuality::Performance, UpscalerMode::Spatial, kMin).scale == 0.5f);
    CHECK(plan_upscale_scale(1.0f, UpscalerQuality::Quality, UpscalerMode::Spatial, kMin).scale ==
          doctest::Approx(1.0f / 1.5f));
    CHECK(plan_upscale_scale(1.0f, UpscalerQuality::UltraPerformance, UpscalerMode::Spatial, kMin).scale ==
          doctest::Approx(1.0f / 3.0f));
    // The player's scale and the quality multiply.
    CHECK(plan_upscale_scale(0.75f, UpscalerQuality::Performance, UpscalerMode::Spatial, kMin).scale ==
          doctest::Approx(0.375f));
    // The floor: 0.5 x 1/3 and 0.25 x 0.5 are below 0.25.
    CHECK(plan_upscale_scale(0.5f, UpscalerQuality::UltraPerformance, UpscalerMode::Spatial, kMin).scale == kMin);
    CHECK(plan_upscale_scale(0.25f, UpscalerQuality::Performance, UpscalerMode::Spatial, kMin).scale == kMin);
    CHECK(plan_upscale_scale(std::nanf(""), UpscalerQuality::Native, UpscalerMode::Spatial, kMin).scale == kMin);
    // The stage: below 1 always; at 1 only for a mode that is not stretch (the sharpen alone); never above 1.
    CHECK(plan_upscale_scale(0.5f, UpscalerQuality::Native, UpscalerMode::Stretch, kMin).stage);
    CHECK_FALSE(plan_upscale_scale(1.0f, UpscalerQuality::Native, UpscalerMode::Stretch, kMin).stage);
    CHECK(plan_upscale_scale(1.0f, UpscalerQuality::Native, UpscalerMode::Spatial, kMin).stage);
    // The temporal modes at scale 1 draw nothing, but a frame with several cameras makes them spatial (the sharpen): the renderer decides
    // each frame whether the stage runs (Renderer::upscale_stage), so the flag is on.
    CHECK(plan_upscale_scale(1.0f, UpscalerQuality::Native, UpscalerMode::Temporal, kMin).stage);
    CHECK(plan_upscale_scale(1.0f, UpscalerQuality::Native, UpscalerMode::MetalFx, kMin).stage);
    CHECK(plan_upscale_scale(0.5f, UpscalerQuality::Native, UpscalerMode::Temporal, kMin).stage);
    CHECK_FALSE(plan_upscale_scale(2.0f, UpscalerQuality::Native, UpscalerMode::Spatial, kMin).stage);
    CHECK_FALSE(plan_upscale_scale(2.0f, UpscalerQuality::Native, UpscalerMode::Temporal, kMin).stage);
    CHECK_FALSE(plan_upscale_scale(2.0f, UpscalerQuality::Native, UpscalerMode::Stretch, kMin).stage);
}

TEST_CASE("upscaler: the quality scales are 1, 1/1.5, 1/1.7, 1/2, 1/3 and the names round-trip") {
    CHECK(upscaler_quality_scale(UpscalerQuality::Native) == 1.0f);
    CHECK(upscaler_quality_scale(UpscalerQuality::Quality) == doctest::Approx(1.0f / 1.5f));
    CHECK(upscaler_quality_scale(UpscalerQuality::Balanced) == doctest::Approx(1.0f / 1.7f));
    CHECK(upscaler_quality_scale(UpscalerQuality::Performance) == 0.5f);
    CHECK(upscaler_quality_scale(UpscalerQuality::UltraPerformance) == doctest::Approx(1.0f / 3.0f));
    CHECK(upscaler_quality_scale(UpscalerQuality(99)) == 1.0f);
    for (int m = 0; m < kUpscalerModeCount; ++m) {
        const Json j = Json::object({{"mode", std::string(upscaler_mode_name(UpscalerMode(m)))}});
        auto r = parse_upscaler_settings(j, "x", UpscalerSettings{});
        REQUIRE(r.ok());
        CHECK(int(r->mode) == m);
    }
    for (int q = 0; q < kUpscalerQualityCount; ++q) {
        const Json j = Json::object({{"quality", std::string(upscaler_quality_name(UpscalerQuality(q)))}});
        auto r = parse_upscaler_settings(j, "x", UpscalerSettings{});
        REQUIRE(r.ok());
        CHECK(int(r->quality) == q);
    }
}

TEST_CASE("upscaler: a partial object changes only its keys; to_json is complete and rounded") {
    UpscalerSettings base;
    base.mode = UpscalerMode::Spatial;
    base.quality = UpscalerQuality::Performance;
    auto r = parse_upscaler_settings(Json::object({{"sharpness", 0.3333333}}), "render.upscaler", base);
    REQUIRE(r.ok());
    CHECK(r->mode == UpscalerMode::Spatial);
    CHECK(r->quality == UpscalerQuality::Performance);
    const Json j = upscaler_to_json(*r);
    CHECK(j["mode"] == "spatial");
    CHECK(j["quality"] == "performance");
    CHECK(j["sharpness"].get<double>() == doctest::Approx(0.333));
    CHECK(j.size() == 4);
    CHECK(j["rayReconstruction"] == false);
    auto empty = parse_upscaler_settings(Json::object(), "x", base);
    REQUIRE(empty.ok());
    CHECK(*empty == base);
}

TEST_CASE("upscaler: rayReconstruction is an opt-in boolean, off by default, that a partial object keeps or changes") {
    CHECK_FALSE(UpscalerSettings{}.rayReconstruction);
    UpscalerSettings base;
    base.mode = UpscalerMode::Dlss;
    auto on = parse_upscaler_settings(Json::object({{"rayReconstruction", true}}), "render.upscaler", base);
    REQUIRE(on.ok());
    CHECK(on->rayReconstruction);
    CHECK(on->mode == UpscalerMode::Dlss);
    CHECK_FALSE(*on == base);  // it takes part in the comparison: the renderer sees the change
    CHECK(upscaler_to_json(*on)["rayReconstruction"] == true);
    auto kept = parse_upscaler_settings(Json::object({{"quality", "balanced"}}), "render.upscaler", *on);
    REQUIRE(kept.ok());
    CHECK(kept->rayReconstruction);
    auto off = parse_upscaler_settings(Json::object({{"rayReconstruction", false}}), "render.upscaler", *on);
    REQUIRE(off.ok());
    CHECK_FALSE(off->rayReconstruction);
    // A wrong type names its place and says what is valid.
    for (const Json& v : {Json("yes"), Json(1), Json()}) {
        auto bad =
            parse_upscaler_settings(Json::object({{"rayReconstruction", v}}), "factoria.json#/render/upscaler", base);
        REQUIRE_FALSE(bad.ok());
        CHECK(bad.error().message.find("factoria.json#/render/upscaler/rayReconstruction") != std::string::npos);
        CHECK(bad.error().message.find("expected true or false") != std::string::npos);
    }
    // A near miss of the key is a "did you mean".
    auto typo = parse_upscaler_settings(Json::object({{"rayReconstruciton", true}}), "w", base);
    REQUIRE_FALSE(typo.ok());
    CHECK(typo.error().hint.find("rayReconstruction") != std::string::npos);
}

TEST_CASE("upscaler: every wrong input names its place, says what is valid and suggests the closest") {
    auto bad_mode = parse_upscaler_settings(Json::object({{"mode", "spatail"}}), "render.upscaler", UpscalerSettings{});
    REQUIRE_FALSE(bad_mode.ok());
    CHECK(bad_mode.error().message.find("render.upscaler/mode") != std::string::npos);
    CHECK(bad_mode.error().hint.find("spatial") != std::string::npos);  // did you mean
    auto bad_q = parse_upscaler_settings(Json::object({{"quality", "ultra"}}), "factoria.json#/render/upscaler",
                                         UpscalerSettings{});
    REQUIRE_FALSE(bad_q.ok());
    CHECK(bad_q.error().message.find("factoria.json#/render/upscaler/quality") != std::string::npos);
    CHECK(bad_q.error().hint.find("ultraPerformance") != std::string::npos);
    auto bad_key = parse_upscaler_settings(Json::object({{"sharpnes", 0.5}}), "w", UpscalerSettings{});
    REQUIRE_FALSE(bad_key.ok());
    CHECK(bad_key.error().message.find("w/sharpnes") != std::string::npos);
    CHECK(bad_key.error().hint.find("sharpness") != std::string::npos);
    for (const double v : {-0.1, 1.5}) {
        auto bad = parse_upscaler_settings(Json::object({{"sharpness", v}}), "w", UpscalerSettings{});
        REQUIRE_FALSE(bad.ok());
        CHECK(bad.error().message.find("w/sharpness") != std::string::npos);
        CHECK(bad.error().hint.find("0") != std::string::npos);
    }
    CHECK_FALSE(parse_upscaler_settings(Json::object({{"sharpness", "high"}}), "w", UpscalerSettings{}).ok());
    CHECK_FALSE(parse_upscaler_settings(Json::object({{"mode", 3}}), "w", UpscalerSettings{}).ok());
    CHECK_FALSE(parse_upscaler_settings(Json::array(), "w", UpscalerSettings{}).ok());
    CHECK_FALSE(parse_upscaler_settings(Json("stretch"), "w", UpscalerSettings{}).ok());
}

TEST_CASE("graphics presets: the names are low, medium, high, ultra, custom, read without regard to case") {
    CHECK(kGraphicsPresetCount == 5);
    CHECK(graphics_preset_name(GraphicsPreset::Low) == "low");
    CHECK(graphics_preset_name(GraphicsPreset::Ultra) == "ultra");
    CHECK(graphics_preset_name(GraphicsPreset::Custom) == "custom");
    for (int i = 0; i < kGraphicsPresetCount; ++i) {
        const std::string n(graphics_preset_name(GraphicsPreset(i)));
        REQUIRE(parse_graphics_preset(n).has_value());
        CHECK(int(*parse_graphics_preset(n)) == i);
    }
    CHECK(parse_graphics_preset("High") == GraphicsPreset::High);
    CHECK(parse_graphics_preset("MEDIUM") == GraphicsPreset::Medium);
    CHECK_FALSE(parse_graphics_preset("extreme").has_value());
    CHECK_FALSE(parse_graphics_preset("").has_value());
}

TEST_CASE("velocity contract: a sentinel no real motion reaches, and NaN reads as none") {
    CHECK(VelocityRef::kNone > VelocityRef::kValidLimit);
    CHECK(VelocityRef::kMaxMotion < VelocityRef::kValidLimit);
    CHECK(VelocityRef::is_none(VelocityRef::kNone));
    CHECK(VelocityRef::is_none(-VelocityRef::kNone));
    CHECK(VelocityRef::is_none(std::nanf("")));
    CHECK(VelocityRef::is_none(INFINITY));
    CHECK_FALSE(VelocityRef::is_none(0.0f));
    CHECK_FALSE(VelocityRef::is_none(VelocityRef::kMaxMotion));
    CHECK_FALSE(VelocityRef::is_none(-0.25f));
    VelocityRef v;
    CHECK_FALSE(v.valid());  // no pass writes it yet
    PostPlan plan;
    CHECK_FALSE(plan.velocity.valid());
    CHECK(plan.jitterPx.x == 0.0f);
    CHECK(plan.prevJitterNdc.y == 0.0f);
}

// ---- M78-P1: the vendor modes (dlss, xess, fsr) --------------------------------------------------------------------------------------

TEST_CASE("upscaler vendors: dlss, xess and fsr parse, round-trip and get a did-you-mean") {
    CHECK(kUpscalerModeCount == 8);
    CHECK(upscaler_mode_name(UpscalerMode::Dlss) == "dlss");
    CHECK(upscaler_mode_name(UpscalerMode::Xess) == "xess");
    CHECK(upscaler_mode_name(UpscalerMode::Fsr) == "fsr");
    CHECK(upscaler_mode_name(UpscalerMode::Auto) == "auto");
    for (int i = 0; i < kVendorUpscalerCount; ++i) {
        CHECK(vendor_upscaler_index(vendor_upscaler_mode(i)) == i);
        auto r =
            parse_upscaler_settings(Json::object({{"mode", std::string(upscaler_mode_name(vendor_upscaler_mode(i)))}}),
                                    "x", UpscalerSettings{});
        REQUIRE(r.ok());
        CHECK(r->mode == vendor_upscaler_mode(i));
    }
    CHECK(vendor_upscaler_index(UpscalerMode::MetalFx) == -1);
    CHECK(vendor_upscaler_index(UpscalerMode::Auto) == -1);
    auto typo = parse_upscaler_settings(Json::object({{"mode", "dlls"}}), "render.upscaler", UpscalerSettings{});
    REQUIRE_FALSE(typo.ok());
    CHECK(typo.error().message.find("render.upscaler/mode") != std::string::npos);
    CHECK(typo.error().hint.find("dlss") != std::string::npos);
    auto fsr = parse_upscaler_settings(Json::object({{"mode", "fsr3"}}), "render.upscaler", UpscalerSettings{});
    REQUIRE_FALSE(fsr.ok());
    CHECK(fsr.error().hint.find("fsr") != std::string::npos);
    UpscalerSettings s;
    s.mode = UpscalerMode::Xess;
    CHECK(upscaler_to_json(s)["mode"] == "xess");
}

TEST_CASE("upscaler vendors: an explicit vendor mode is itself when its SDK is usable on a jittered single-camera "
          "frame, else the "
          "temporal chain") {
    UpscalerCaps caps;
    caps.temporal = true;
    UpscalerSettings s;
    for (int i = 0; i < kVendorUpscalerCount; ++i) {
        s.mode = vendor_upscaler_mode(i);
        CAPTURE(upscaler_mode_name(s.mode));
        CHECK(effective_upscaler_mode(s, caps) == UpscalerMode::Temporal);  // SDK not usable: the next best
        (i == 0 ? caps.dlss : i == 1 ? caps.xess : caps.fsr) = true;
        CHECK(effective_upscaler_mode(s, caps) == s.mode);
        UpscalerCaps several = caps;
        several.multiCamera = true;
        CHECK(effective_upscaler_mode(s, several) ==
              UpscalerMode::Spatial);  // one history only: the engine's spatial upscaler
        UpscalerCaps noTemporal = caps;
        noTemporal.temporal = false;
        CHECK(effective_upscaler_mode(s, noTemporal) == UpscalerMode::Spatial);
        UpscalerCaps art = caps;
        art.pixelArt = true;
        CHECK(effective_upscaler_mode(s, art) == UpscalerMode::Stretch);  // pixel art stays stretch
        UpscalerCaps none = caps;
        none.spatial = none.temporal = false;
        CHECK(effective_upscaler_mode(s, none) == UpscalerMode::Stretch);
        // The explicit choice does not depend on the GPU's maker (xess and fsr run on any GPU).
        UpscalerCaps other = caps;
        other.gpuVendor = GpuVendor::Other;
        CHECK(effective_upscaler_mode(s, other) == s.mode);
    }
}

TEST_CASE("upscaler vendors: auto picks the SDK of the GPU's maker when usable, else the M76 chain") {
    UpscalerSettings s;
    s.mode = UpscalerMode::Auto;
    UpscalerCaps caps;
    caps.temporal = true;
    caps.dlss = caps.xess = caps.fsr = true;  // all installed: only the maker's counts
    const std::pair<GpuVendor, UpscalerMode> picks[] = {
        {GpuVendor::Nvidia, UpscalerMode::Dlss},    {GpuVendor::Intel, UpscalerMode::Xess},
        {GpuVendor::Amd, UpscalerMode::Fsr},        {GpuVendor::Other, UpscalerMode::Temporal},
        {GpuVendor::Apple, UpscalerMode::Temporal}, {GpuVendor::None, UpscalerMode::Temporal}};
    for (const auto& [maker, expected] : picks) {
        caps.gpuVendor = maker;
        CAPTURE(gpu_vendor_name(maker));
        CHECK(effective_upscaler_mode(s, caps) == expected);
    }
    // The maker's SDK is not usable (not installed, failed): the chain, whatever the other SDKs say.
    caps.gpuVendor = GpuVendor::Nvidia;
    caps.dlss = false;
    CHECK(effective_upscaler_mode(s, caps) == UpscalerMode::Temporal);
    caps.metalfx = true;
    CHECK(effective_upscaler_mode(s, caps) == UpscalerMode::MetalFx);
    caps.dlss = true;
    CHECK(effective_upscaler_mode(s, caps) == UpscalerMode::Dlss);
    // Several cameras: no jittered frame, so no SDK.
    caps.multiCamera = true;
    CHECK(effective_upscaler_mode(s, caps) != UpscalerMode::Dlss);
    caps.multiCamera = false;
    caps.pixelArt = true;
    CHECK(effective_upscaler_mode(s, caps) == UpscalerMode::Stretch);
}

TEST_CASE("upscaler vendors: the plan runs the stage for a vendor mode like for the temporal one") {
    CHECK(plan_upscale_scale(1.0f, UpscalerQuality::Native, UpscalerMode::Dlss, 0.25f).stage);
    CHECK(plan_upscale_scale(0.5f, UpscalerQuality::Native, UpscalerMode::Xess, 0.25f).stage);
    CHECK_FALSE(plan_upscale_scale(2.0f, UpscalerQuality::Native, UpscalerMode::Fsr, 0.25f).stage);
}
