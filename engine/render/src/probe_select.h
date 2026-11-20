// Which reflection probes a draw reflects (M73-P3c; docs/design/ARCHITECTURE_PROBES.md, "What the meshes read"). A pure function of the
// probes' boxes and the position of the mesh, so the same scene gives the same choice on every machine and in every frame, and a test needs no GPU.
//
// The renderer lists the boxes of this frame's probes (ProbeVolume, in a deterministic order); every mesh is given up to TWO of them with the
// share of the light each holds, in 1/32 steps, and the sky keeps the rest. The choice is part of the mesh's batch key (render_scene.cpp folds
// ProbePick::key() into SceneMesh::probeKey), so meshes that reflect the same probes with the same shares still share a draw and the others do not.
#pragma once

#include <cstdint>
#include <vector>

#include "fa/core/math.h"

namespace fa::render {

// One probe's box of this frame.
struct ProbeVolume {
    std::uint64_t id = 0;  // the entity's bits: the key of the renderer's ProbeEntry
    Vec3 position;         // where the probe captured, in the world (the reflection is read from here)
    Vec3 center;           // the box's centre in the world
    Vec3 axis[3];          // the box's unit axes (the entity's rotation)
    Vec3 half{1, 1, 1};    // half the box's size along each axis, metres (scale applied)
    Vec3 lo, hi;           // the world axis-aligned box that holds the box (a cheap first test)
    float blend = 0.0f;    // metres: the fade-out band inside the box edge
    int importance = 0;
    float volume = 0.0f;  // metres cubed: of two probes of one importance the smaller box wins
    bool projection = true;
    // world -> unit box: row i holds axis[i] / half[i] and the offset -dot(axis[i], center) / half[i]; the box is where all three are in [-1, 1]
    float rows[3][4]{};
};

// The unit box rows of `v` from its centre, axes and half sizes (call after setting them).
void probe_volume_finish(ProbeVolume& v);

inline constexpr int kProbeShareSteps =
    32;  // the shares are multiples of 1 / 32 (the weights are quantised so batches still merge)

struct ProbePick {
    std::uint16_t index[2] = {0, 0};  // 1 + the volume's index in the list, 0 = none
    std::uint8_t steps[2] = {0, 0};   // the probe's own weight (how far inside its box, over blendDistance) in 1/32
    bool any() const { return index[0] != 0; }
    // The two probes' indices and weights as one number (0 = none): equal picks are equal keys.
    std::uint32_t key() const {
        return any() ? std::uint32_t(index[0]) | std::uint32_t(steps[0]) << 9 | std::uint32_t(index[1]) << 15 |
                           std::uint32_t(steps[1]) << 24
                     : 0u;
    }
    // The share of the light each probe holds: A its weight, B its weight of what A leaves; the sky has the rest. 0 for a probe that is not there.
    void shares(float out[2]) const {
        const float a = float(steps[0]) / float(kProbeShareSteps);
        out[0] = index[0] ? a : 0.0f;
        out[1] = index[1] ? float(steps[1]) / float(kProbeShareSteps) * (1.0f - a) : 0.0f;
    }
};

// The probes of `volumes` that reach `p`, best first (the larger importance, then the smaller box, then the nearer capture position, then the
// smaller id); the best two are kept. A probe reaches p inside its box, with the weight 1 deeper than its blendDistance from the box's face and
// falling to 0 at the face; a probe whose weight rounds to 0 does not reach it. When the first holds the whole light (weight 1) the second is
// dropped. At most 511 volumes are looked at (kProbeMaxCount is 256).
ProbePick pick_probes(const std::vector<ProbeVolume>& volumes, Vec3 p);

}  // namespace fa::render
