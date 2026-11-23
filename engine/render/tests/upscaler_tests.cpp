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

TEST_CASE("upscaler: the defaults are stretch, native, 0.5, and effective_upscaler_mode is stretch for every mode") {
    const UpscalerSettings s;
    CHECK(s.mode == UpscalerMode::Stretch);
    CHECK(s.quality == UpscalerQuality::Native);
    CHECK(s.sharpness == 0.5f);
    for (int m = 0; m < kUpscalerModeCount; ++m) {
        UpscalerSettings t;
        t.mode = UpscalerMode(m);
        CHECK(effective_upscaler_mode(t) == UpscalerMode::Stretch);  // nothing draws the others yet
    }
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
    CHECK(j.size() == 3);
    auto empty = parse_upscaler_settings(Json::object(), "x", base);
    REQUIRE(empty.ok());
    CHECK(*empty == base);
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
