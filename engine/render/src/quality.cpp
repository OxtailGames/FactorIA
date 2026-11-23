#include "quality.h"

#include <algorithm>
#include <string>

namespace fa::render {

QualityResolved resolve_quality(GraphicsPreset preset, const FeatureEnv& env) {
    const GraphicsPresetTable& t = graphics_preset_table(preset);
    QualityResolved r;
    r.preset = preset;
    r.limits = t.limits;
    r.upscaler = t.upscaler;
    r.gpu = env.backend != FeatureBackend::Headless;
    if (!r.gpu || preset == GraphicsPreset::Custom) return r;
    // A knob the preset leaves on, for a feature this GPU cannot draw: off, with the status of the feature's row in render.supports.
    const auto needs = [&](const char* feature, bool& flag, const char* knob) {
        if (!flag) return;
        std::string why;
        const int index = find_feature(feature);
        if (index < 0 || feature_supported(env, index, &why)) return;
        r.capped.push_back({knob, Json(true), Json(false), std::string(feature) + ": " + why});
        flag = false;
    };
    QualityLimits& q = r.limits;
    needs("temporalAA", q.temporalAA, "temporalAA");
    needs("ssao", q.ssao, "ssao");
    needs("ssr", q.ssr, "ssr");
    needs("sunShafts", q.sunShafts, "sunShafts");
    needs("depthOfField", q.depthOfField, "depthOfField");
    needs("motionBlur", q.motionBlur, "motionBlur");
    needs("contactShadows", q.contactShadows, "contactShadows");
    needs("volumetricFog", q.volumetricFog, "volumetricFog");
    needs("2dGlobalIllumination", q.gi2d, "gi2d");
    // Point and spot shadows are drawn from the same atlas: one knob, both rows.
    bool pointSpot = q.localShadows;
    needs("pointShadows", pointSpot, "localShadows");
    if (pointSpot) needs("spotShadows", pointSpot, "localShadows");
    q.localShadows = pointSpot;
    // The sun's cascades need the same atlas: without 32-bit float targets there are none.
    {
        std::string why;
        const int index = find_feature("cascadedShadows");
        if (q.shadowCascades > 0 && index >= 0 && !feature_supported(env, index, &why)) {
            r.capped.push_back({"shadowCascades", Json(q.shadowCascades), Json(0), "cascadedShadows: " + why});
            q.shadowCascades = 0;
        }
    }
    // The atlas is one image: no larger than the GPU's largest texture.
    if (env.maxTextureSize > 0 && q.shadowAtlasSize > env.maxTextureSize) {
        r.capped.push_back(
            {"shadowAtlasSize", Json(q.shadowAtlasSize), Json(env.maxTextureSize),
             "this GPU's largest 2D texture is " + std::to_string(env.maxTextureSize) + " texels a side"});
        q.shadowAtlasSize = env.maxTextureSize;
    }
    q.shadowTileSize = std::min(q.shadowTileSize, q.shadowAtlasSize);
    return r;
}

void apply_quality_limits(PostStack& s, const QualityLimits& q) {
    PostProcess& f = s.fx;
    const auto drop = [&](PostEffect e, bool allowed, bool& flag) {
        if (allowed || !s.has(e)) return;
        s.mask &= ~(1u << int(e));
        flag = false;
    };
    drop(PostEffect::TemporalAA, q.temporalAA, f.temporalAAEnabled);
    drop(PostEffect::Ssao, q.ssao, f.ssaoEnabled);
    drop(PostEffect::Ssr, q.ssr, f.ssrEnabled);
    drop(PostEffect::SunShafts, q.sunShafts, f.sunShaftsEnabled);
    drop(PostEffect::DepthOfField, q.depthOfField, f.depthOfFieldEnabled);
    drop(PostEffect::MotionBlur, q.motionBlur, f.motionBlurEnabled);
    f.ssaoQuality = SsaoQuality(std::min(int(f.ssaoQuality), int(q.ssaoQuality)));
    f.ssrSteps = std::min(f.ssrSteps, q.ssrSteps);
    f.motionBlurSamples = std::min(f.motionBlurSamples, q.motionBlurSamples);
    if (!q.depthOfFieldBokeh) f.depthOfFieldBokeh = false;
}

}  // namespace fa::render
