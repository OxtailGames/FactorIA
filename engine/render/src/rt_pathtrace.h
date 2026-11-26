// Private: the path traced reference mode's state and decisions (M79-P5a, docs/design/ARCHITECTURE_RT_PATHTRACER.md). The kernel is
// shaders/rt/rt_pathtrace.hlsl on the shared ray traced effect pass (rt_effect.h); this file is what is around it and runs on the CPU:
//
//   * the accumulation counter of each camera (PathTraceJobState): how many samples the float image holds, and the hashes of what the image was
//     drawn from (the camera, the scene's instances, the settings): when one changes the image is started over (a reset, with its reason);
//   * `path_trace_step`, the decision of a frame (dispatch how many samples starting at which index, or hold the image as it is), pure so a test
//     drives it without a device;
//   * the constants the kernel reads (`path_trace_fill_params`, `fill_path_trace_lights`).
#pragma once

#include <cstdint>
#include <map>
#include <string>
#include <vector>

#include "fa/render/raytracing.h"
#include "mesh_batch.h"
#include "rt_effect.h"

namespace fa::render {

static_assert(kRtMaxLights == kPtMaxLights, "the lights block holds the lights the setting names");

// The accumulation of one camera's image.
struct PathTraceJobState {
    bool started = false;  // the image holds (or will hold after this frame's dispatch) samples of the hashes below
    std::uint32_t samples = 0;      // the samples in the image
    std::uint64_t imageSerial = 0;  // RtEffectImage::serial the samples are in
    std::uint64_t cameraHash = 0, sceneHash = 0, settingsHash = 0;
    int width = 0, height = 0;
    std::uint64_t lastFrame =
        0;  // the frameSerial of the last frame that planned this camera's pass (PathTraceState::purge)
};

// The most paths (pixels x samples) one dispatch traces: a frame's samples are capped by the image's area, so a big image adds fewer samples a
// frame (the accumulation spreads the rest over the next frames) and no single submit runs long enough for a driver's watchdog (Windows TDR,
// about two seconds). A pixel count, never a time, so the picture a number of frames gives does not depend on the machine.
inline constexpr std::uint64_t kPtMaxPathsPerDispatch = std::uint64_t(1)
                                                        << 24;  // 16.7 million: 8.1 samples of a 1080p image

// The samples one dispatch of an image of `width` x `height` may add: `wanted` (samplesPerFrame), at most kPtMaxPathsPerDispatch / pixels, never
// less than 1.
std::uint32_t path_trace_samples_cap(std::uint32_t wanted, int width, int height);

// What a frame does with the image.
struct PathTraceStep {
    RtPrepare what = RtPrepare::Dispatch;
    std::uint32_t firstSample = 0;  // the index of the first sample of the frame (the samples already in the image)
    std::uint32_t count = 0;        // the samples of the frame (0 when the image is held)
    std::string reset;  // why the image started over this frame: "", "start", "image", "camera", "scene", "settings"
};

// FNV-1a 64 of the bytes the kernel's picture depends on.
std::uint64_t path_trace_camera_hash(const RtEffectParams& params);
std::uint64_t path_trace_settings_hash(const PathTracerSettings& settings, const RtHitParams& hit,
                                       const RtLightParams& lights);

// Decides the frame of one camera and updates its counter: a changed hash (or image) starts over (samples = 0, a `reset` reason), `maxSamples`
// holds the image once it has that many samples, else the frame draws min(samplesPerFrame, what is left until maxSamples) samples.
PathTraceStep path_trace_step(PathTraceJobState& state, const PathTracerSettings& settings, std::uint64_t cameraHash,
                              std::uint64_t sceneHash, std::uint64_t settingsHash, std::uint64_t imageSerial, int width,
                              int height);

// The counters and numbers of a frame's dispatch in RtEffectParams (frame.x first sample, frame.y the seed, frame.z the count, frame.w the
// indirect bounces (maxBounces - 1) | 256 with lights; user0.x the firefly clamp).
void path_trace_fill_params(RtEffectParams& params, const PathTracerSettings& settings, const PathTraceStep& step,
                            bool lightsUsed);

// The first kRtMaxLights point and spot lights (rank 2; an area light is a point light at its centre) in the order the frame collected them.
void fill_path_trace_lights(RtLightParams& out, const std::vector<LightData>& lights);

// The state of the renderer: one counter per camera (job), and the status the commands read.
struct PathTraceState {
    std::map<std::string, PathTraceJobState> jobs;
    PathTracerStatus status;
    void clear() {
        jobs.clear();
        status = PathTracerStatus{};
    }
    // Forgets the cameras no frame planned since `serial - 2` (a camera that went away, a job renamed): the same two frames after which the
    // effect's image is freed (RtEffects::sweep), so a camera that comes back starts over with a new image anyway. Returns how many went.
    std::size_t purge(std::uint64_t serial) {
        std::size_t gone = 0;
        for (auto it = jobs.begin(); it != jobs.end();) {
            if (it->second.lastFrame + 2 < serial) {
                it = jobs.erase(it);
                ++gone;
            } else {
                ++it;
            }
        }
        return gone;
    }
};

}  // namespace fa::render
