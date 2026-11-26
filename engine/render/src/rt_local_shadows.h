// The CPU side of the ray traced shadows of point, spot and area lights (M79-P2a-3, docs/design/ARCHITECTURE_RT_SHADOWS.md): which lights the
// frame traces (at most kRtLocalMaxLights, the same ones from frame to frame while they stay among the best) and the constants block the kernel
// reads. No GPU here: pure functions, tested by tests/rt_local_shadow_tests.cpp, used by Renderer::Impl::plan_job and build_graph.
#pragma once

#include <array>
#include <cstdint>
#include <span>

#include "mesh_batch.h"
#include "rt_effect.h"

namespace fa::render {

// A light the frame could trace: a point, spot or area light that casts a shadow, that a caster can reach and that is within its shadow distance
// (the lights shadow_bounds gives a LocalShadowInput).
struct RtLocalCandidate {
    std::uint64_t id = 0;     // the light's entity (LightData::id): what a slot is kept by
    int light = 0;            // its index in the frame's light table
    float importance = 0.0f;  // local_shadow_importance: brightness times the share of its range the camera is inside of
};

// Which light holds each slot, kept per camera from frame to frame. A slot's denoiser history is the history of the light that holds it, so a
// light keeps its slot while it stays a candidate and is replaced only by a clearly better one.
struct RtLocalSlots {
    std::array<std::uint64_t, kRtLocalMaxLights> id{};
    std::array<bool, kRtLocalMaxLights> used{};
};

// A newcomer replaces the weakest holder only when it is this much more important (hysteresis: two lights of equal importance never swap places).
inline constexpr float kRtLocalSwapFactor = 1.25f;

struct RtLocalPick {
    std::array<int, kRtLocalMaxLights> light{-1, -1, -1};  // the light table index of each slot (-1 = no light)
    int count = 0;       // the highest slot in use + 1 (what the kernel loops over)
    int traced = 0;      // how many slots hold a light
    int candidates = 0;  // how many lights asked
    bool changed = false;  // a slot holds another light than in the frame before (or none where it held one): its history is not the light's
};

// Chooses the traced lights among `candidates` (any order; ties go to the lower light index) and updates `slots`:
//   1. a slot whose light is still a candidate keeps it;
//   2. a free slot takes the best candidate no slot has;
//   3. a candidate replaces the weakest holder when its importance is more than kRtLocalSwapFactor times the holder's.
// A candidate with an importance of 0 (or NaN) is never traced.
RtLocalPick pick_rt_local_lights(RtLocalSlots& slots, std::span<const RtLocalCandidate> candidates);

// The kernel's record of one light: its kind, reach, axes and the size of the cone or emitter its rays are spread over. A light whose Light.shadowFilter is Hard, or whose
// Light.shadowSoftness is 0, has none: one ray to its centre, in the soft mode too.
RtLocalLight make_rt_local_light(const LightData& light);

// The constants block for `pick`: the lights of `table` in their slots (an empty slot has a reach of 0, which the kernel skips).
RtLocalParams make_rt_local_params(std::span<const LightData> table, const RtLocalPick& pick);

}  // namespace fa::render
