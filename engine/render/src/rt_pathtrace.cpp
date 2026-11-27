#include "rt_pathtrace.h"

#include <algorithm>
#include <cstring>

namespace fa::render {

namespace {

struct Fnv {
    std::uint64_t h = 0xCBF29CE484222325ull;
    void bytes(const void* data, std::size_t size) {
        const auto* p = static_cast<const unsigned char*>(data);
        for (std::size_t i = 0; i < size; ++i) h = (h ^ p[i]) * 0x100000001B3ull;
    }
    template <class T>
    void value(const T& v) {
        bytes(&v, sizeof v);
    }
};

}  // namespace

std::uint64_t path_trace_camera_hash(const RtEffectParams& p) {
    Fnv f;
    f.bytes(p.camera, sizeof p.camera);
    const float* basis[] = {p.uRayO0, p.uRayOX,    p.uRayOY,    p.uRayD0,    p.uRayDX,
                            p.uRayDY, p.viewProj0, p.viewProj1, p.viewProj2, p.viewProj3};
    for (const float* b : basis) f.bytes(b, 4 * sizeof(float));
    return f.h;
}

std::uint64_t path_trace_settings_hash(const PathTracerSettings& s, const RtHitParams& hit,
                                       const RtLightParams& lights) {
    Fnv f;
    f.value(s.maxBounces);
    f.value(s.lights);
    f.value(s.seed);
    f.value(s.fireflyClamp);
    f.value(hit);
    if (s.lights) f.value(lights);
    return f.h;
}

std::uint32_t path_trace_samples_cap(std::uint32_t wanted, int width, int height, int maxBounces) {
    const std::uint64_t pixels = std::uint64_t(std::max(width, 1)) * std::uint64_t(std::max(height, 1));
    const std::uint64_t bounces = std::uint64_t(std::clamp(maxBounces, kPtCapBounces, kPtMaxMaxBounces));
    const std::uint64_t most =
        std::max<std::uint64_t>(kPtMaxPathsPerDispatch * std::uint64_t(kPtCapBounces) / (pixels * bounces), 1);
    return std::uint32_t(std::min<std::uint64_t>(wanted, most));
}

PathTraceStep path_trace_step(PathTraceJobState& state, const PathTracerSettings& settings, std::uint64_t cameraHash,
                              std::uint64_t sceneHash, std::uint64_t settingsHash, std::uint64_t imageSerial, int width,
                              int height) {
    PathTraceStep step;
    if (!state.started) {
        step.reset = "start";
    } else if (state.imageSerial != imageSerial || state.width != width || state.height != height) {
        step.reset = "image";
    } else if (state.cameraHash != cameraHash) {
        step.reset = "camera";
    } else if (state.sceneHash != sceneHash) {
        step.reset = "scene";
    } else if (state.settingsHash != settingsHash) {
        step.reset = "settings";
    }
    if (!step.reset.empty()) {
        state.samples = 0;
        state.started = true;
    }
    state.imageSerial = imageSerial;
    state.cameraHash = cameraHash;
    state.sceneHash = sceneHash;
    state.settingsHash = settingsHash;
    state.width = width;
    state.height = height;
    const std::uint32_t cap = settings.maxSamples > 0 ? std::uint32_t(std::min(settings.maxSamples, kPtMaxMaxSamples))
                                                      : std::uint32_t(kPtMaxMaxSamples);
    step.firstSample = state.samples;
    if (state.samples >= cap) {
        step.what = RtPrepare::Hold;
        return step;
    }
    const std::uint32_t perFrame = path_trace_samples_cap(
        std::uint32_t(std::clamp(settings.samplesPerFrame, kPtMinSamplesPerFrame, kPtMaxSamplesPerFrame)), width,
        height, settings.maxBounces);
    step.count = std::min(perFrame, cap - state.samples);
    state.samples += step.count;
    return step;
}

void path_trace_fill_params(RtEffectParams& params, const PathTracerSettings& settings, const PathTraceStep& step,
                            bool lightsUsed) {
    params.frame[0] = step.firstSample;
    params.frame[1] = std::uint32_t(std::clamp(settings.seed, 0, kPtMaxSeed));
    params.frame[2] = std::max<std::uint32_t>(step.count, 1u);
    params.frame[3] = std::uint32_t(std::clamp(settings.maxBounces, kPtMinMaxBounces, kPtMaxMaxBounces) - 1) |
                      (lightsUsed ? 256u : 0u);
    params.user0[0] = std::max(settings.fireflyClamp, 0.0f);
}

void fill_path_trace_lights(RtLightParams& out, const std::vector<LightData>& lights) {
    out = RtLightParams{};
    std::uint32_t n = 0;
    for (const LightData& l : lights) {
        if (l.rank != 2) continue;
        if (n >= std::uint32_t(kRtMaxLights)) break;
        const float type = l.color.w > 1.5f && l.color.w < 2.5f ? 2.0f : 1.0f;
        out.pos[n][0] = l.pos.x;
        out.pos[n][1] = l.pos.y;
        out.pos[n][2] = l.pos.z;
        out.pos[n][3] = l.pos.w;
        out.color[n][0] = l.color.x;
        out.color[n][1] = l.color.y;
        out.color[n][2] = l.color.z;
        out.color[n][3] = type;
        out.dir[n][0] = l.dir.x;
        out.dir[n][1] = l.dir.y;
        out.dir[n][2] = l.dir.z;
        out.dir[n][3] = l.dir.w;
        out.extra[n][0] = l.cosInner;
        ++n;
    }
    out.count[0] = n;
}

}  // namespace fa::render
