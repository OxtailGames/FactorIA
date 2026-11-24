#include "fa/render/graphics_preset.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <string>

namespace fa::render {

std::optional<GraphicsPreset> parse_graphics_preset(std::string_view name) {
    std::string lower(name);
    std::transform(lower.begin(), lower.end(), lower.begin(), [](unsigned char c) { return char(std::tolower(c)); });
    for (int i = 0; i < kGraphicsPresetCount; ++i)
        if (kGraphicsPresetNames[std::size_t(i)] == lower) return GraphicsPreset(i);
    return std::nullopt;
}

namespace {

// The limits of one preset. Every number is a cap on what the scene asks for (the defaults of QualityLimits are "no limit"), so Ultra is
// all defaults but the shadow tile and atlas sizes the engine itself never goes past.
//
//   knob                  Low     Medium  High    Ultra
//   temporalAA            off     on      on      on
//   ssao                  off     medium  high    ultra
//   ssr (steps)           off     off     48      128
//   sunShafts             off     off     on      on
//   depthOfField (bokeh)  off     smooth  bokeh   bokeh
//   motionBlur (samples)  off     8       16      32
//   shadowCascades        1       2       3       4
//   shadowAtlasSize       1024    2048    4096    8192
//   shadowTileSize        512     1024    2048    4096
//   softShadows           off     off     on      on
//   localShadows          off     on      on      on
//   contactShadows        off     off     on      on
//   volumetricFog (qual)  off     low     medium  high
//   lodDistanceScale      2       1.5     1       1
//   foliageDensity        0.4     0.7     1       1
//   foliageDistance       0.5     0.75    1       1
//   terrainLodQuality     0.5     0.75    1       1
//   gi2d (qual, res)      off     low .25 medium .5  high 1
//   lightScale            0.5     0.75    1       1
//   realtimeGiProbes      2       4       8       32
//   upscaler (auto)       perf.   balanced quality the game's own
GraphicsPresetTable make_table(GraphicsPreset p) {
    GraphicsPresetTable t;
    QualityLimits& q = t.limits;
    switch (p) {
        case GraphicsPreset::Low:
            q.temporalAA = false;
            q.ssao = false;
            q.ssaoQuality = SsaoQuality::Low;
            q.ssr = false;
            q.ssrSteps = 8;
            q.sunShafts = false;
            q.depthOfField = false;
            q.depthOfFieldBokeh = false;
            q.motionBlur = false;
            q.motionBlurSamples = 4;
            q.shadowCascades = 1;
            q.shadowAtlasSize = 1024;
            q.shadowTileSize = 512;
            q.softShadows = false;
            q.localShadows = false;
            q.contactShadows = false;
            q.volumetricFog = false;
            q.volumetricQuality = VolumetricQuality::Low;
            q.lodDistanceScale = 2.0f;
            q.foliageDensity = 0.4f;
            q.foliageDistance = 0.5f;
            q.terrainLodQuality = 0.5f;
            q.gi2d = false;
            q.gi2dQuality = GI2DQuality::Low;
            q.gi2dResolutionScale = 0.25f;
            q.lightScale = 0.5f;
            q.realtimeGiProbesPerFrame = 2;
            t.upscaler = UpscalerSettings{UpscalerMode::Auto, UpscalerQuality::Performance, 0.5f};
            break;
        case GraphicsPreset::Medium:
            q.temporalAA = true;
            q.ssao = true;
            q.ssaoQuality = SsaoQuality::Medium;
            q.ssr = false;
            q.ssrSteps = 16;
            q.sunShafts = false;
            q.depthOfField = true;
            q.depthOfFieldBokeh = false;
            q.motionBlur = true;
            q.motionBlurSamples = 8;
            q.shadowCascades = 2;
            q.shadowAtlasSize = 2048;
            q.shadowTileSize = 1024;
            q.softShadows = false;
            q.localShadows = true;
            q.contactShadows = false;
            q.volumetricFog = true;
            q.volumetricQuality = VolumetricQuality::Low;
            q.lodDistanceScale = 1.5f;
            q.foliageDensity = 0.7f;
            q.foliageDistance = 0.75f;
            q.terrainLodQuality = 0.75f;
            q.gi2d = true;
            q.gi2dQuality = GI2DQuality::Low;
            q.gi2dResolutionScale = 0.25f;
            q.lightScale = 0.75f;
            q.realtimeGiProbesPerFrame = 4;
            t.upscaler = UpscalerSettings{UpscalerMode::Auto, UpscalerQuality::Balanced, 0.5f};
            break;
        case GraphicsPreset::High:
            q.temporalAA = true;
            q.ssao = true;
            q.ssaoQuality = SsaoQuality::High;
            q.ssr = true;
            q.ssrSteps = 48;
            q.sunShafts = true;
            q.depthOfField = true;
            q.depthOfFieldBokeh = true;
            q.motionBlur = true;
            q.motionBlurSamples = 16;
            q.shadowCascades = 3;
            q.shadowAtlasSize = 4096;
            q.shadowTileSize = 2048;
            q.softShadows = true;
            q.localShadows = true;
            q.contactShadows = true;
            q.volumetricFog = true;
            q.volumetricQuality = VolumetricQuality::Medium;
            q.lodDistanceScale = 1.0f;
            q.foliageDensity = 1.0f;
            q.foliageDistance = 1.0f;
            q.terrainLodQuality = 1.0f;
            q.gi2d = true;
            q.gi2dQuality = GI2DQuality::Medium;
            q.gi2dResolutionScale = 0.5f;
            q.lightScale = 1.0f;
            q.realtimeGiProbesPerFrame = 8;
            t.upscaler = UpscalerSettings{UpscalerMode::Auto, UpscalerQuality::Quality, 0.5f};
            break;
        case GraphicsPreset::Ultra:
            break;  // every limit at its default and no upscaler of its own: the game as its author made it, the picture of `custom`
        case GraphicsPreset::Custom: break;
    }
    return t;
}

const char* ssao_name(SsaoQuality q) {
    switch (q) {
        case SsaoQuality::Low: return "low";
        case SsaoQuality::Medium: return "medium";
        case SsaoQuality::High: return "high";
        case SsaoQuality::Ultra: return "ultra";
    }
    return "medium";
}
const char* volumetric_name(VolumetricQuality q) {
    switch (q) {
        case VolumetricQuality::Low: return "low";
        case VolumetricQuality::Medium: return "medium";
        case VolumetricQuality::High: return "high";
    }
    return "medium";
}
const char* gi2d_name(GI2DQuality q) {
    switch (q) {
        case GI2DQuality::Low: return "low";
        case GI2DQuality::Medium: return "medium";
        case GI2DQuality::High: return "high";
    }
    return "medium";
}
double round3(double v) { return std::round(v * 1000.0) / 1000.0; }

// One knob: its name and how to write it (JSON) and read it as a level (higher = more quality).
struct Knob {
    const char* name;
    Json (*json)(const QualityLimits&);
    double (*level)(const QualityLimits&);
};

#define FA_KNOB_BOOL(field)                                                                                            \
    {#field, [](const QualityLimits& q) { return Json(q.field); },                                                     \
     [](const QualityLimits& q) { return q.field ? 1.0 : 0.0; }}
#define FA_KNOB_INT(field)                                                                                             \
    {#field, [](const QualityLimits& q) { return Json(q.field); },                                                     \
     [](const QualityLimits& q) { return double(q.field); }}
#define FA_KNOB_NUM(field)                                                                                             \
    {#field, [](const QualityLimits& q) { return Json(round3(double(q.field))); },                                     \
     [](const QualityLimits& q) { return double(q.field); }}
#define FA_KNOB_ENUM(field, namefn)                                                                                    \
    {#field, [](const QualityLimits& q) { return Json(std::string(namefn(q.field))); },                                \
     [](const QualityLimits& q) { return double(int(q.field)); }}

const std::vector<Knob>& knobs() {
    static const std::vector<Knob> k = {
        FA_KNOB_BOOL(temporalAA),
        FA_KNOB_BOOL(ssao),
        FA_KNOB_ENUM(ssaoQuality, ssao_name),
        FA_KNOB_BOOL(ssr),
        FA_KNOB_INT(ssrSteps),
        FA_KNOB_BOOL(sunShafts),
        FA_KNOB_BOOL(depthOfField),
        FA_KNOB_BOOL(depthOfFieldBokeh),
        FA_KNOB_BOOL(motionBlur),
        FA_KNOB_INT(motionBlurSamples),
        FA_KNOB_INT(shadowCascades),
        FA_KNOB_INT(shadowAtlasSize),
        FA_KNOB_INT(shadowTileSize),
        FA_KNOB_BOOL(softShadows),
        FA_KNOB_BOOL(localShadows),
        FA_KNOB_BOOL(contactShadows),
        FA_KNOB_BOOL(volumetricFog),
        FA_KNOB_ENUM(volumetricQuality, volumetric_name),
        {"lodDistanceScale", [](const QualityLimits& q) { return Json(round3(double(q.lodDistanceScale))); },
         [](const QualityLimits& q) { return 1.0 / std::max(double(q.lodDistanceScale), 1e-6); }},
        FA_KNOB_NUM(foliageDensity),
        FA_KNOB_NUM(foliageDistance),
        FA_KNOB_NUM(terrainLodQuality),
        FA_KNOB_BOOL(gi2d),
        FA_KNOB_ENUM(gi2dQuality, gi2d_name),
        FA_KNOB_NUM(gi2dResolutionScale),
        FA_KNOB_NUM(lightScale),
        FA_KNOB_INT(realtimeGiProbesPerFrame),
    };
    return k;
}
#undef FA_KNOB_BOOL
#undef FA_KNOB_INT
#undef FA_KNOB_NUM
#undef FA_KNOB_ENUM

}  // namespace

const GraphicsPresetTable& graphics_preset_table(GraphicsPreset p) {
    static const std::array<GraphicsPresetTable, kGraphicsPresetCount> tables = {
        make_table(GraphicsPreset::Low), make_table(GraphicsPreset::Medium), make_table(GraphicsPreset::High),
        make_table(GraphicsPreset::Ultra), make_table(GraphicsPreset::Custom)};
    const int i = int(p);
    return tables[std::size_t(i >= 0 && i < kGraphicsPresetCount ? i : int(GraphicsPreset::Custom))];
}

Json quality_limits_to_json(const QualityLimits& q) {
    Json out = Json::object();
    for (const Knob& k : knobs()) out[k.name] = k.json(q);
    return out;
}

const std::vector<std::string>& quality_knob_names() {
    static const std::vector<std::string> names = [] {
        std::vector<std::string> n;
        for (const Knob& k : knobs()) n.emplace_back(k.name);
        return n;
    }();
    return names;
}

std::vector<double> quality_knob_levels(const QualityLimits& q) {
    std::vector<double> out;
    for (const Knob& k : knobs()) out.push_back(k.level(q));
    return out;
}

QualityResolved resolve_graphics_preset_uncapped(GraphicsPreset preset) {
    const GraphicsPresetTable& t = graphics_preset_table(preset);
    QualityResolved r;
    r.preset = preset;
    r.limits = t.limits;
    r.upscaler = t.upscaler;
    r.gpu = false;
    return r;
}

}  // namespace fa::render
