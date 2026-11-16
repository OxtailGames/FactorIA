// The occlusion probe of the engine: answers Audio's rays with the physics world (docs/SOUND.md, "Occlusion").
//
// The audio module sits below physics and cannot cast rays, so Audio asks a probe (Audio::set_occlusion_probe) and the engine sets
// this one. Audio owns the rest: which sources are asked, at most how many per frame, and the smoothing of the answer.
#pragma once

#include "fa/audio/audio.h"
#include "fa/physics/physics.h"

namespace fa {

// True when a collider of `ray.mask` stands between `ray.from` and `ray.to`. Both the 2D colliders (a segment in x and y) and the 3D
// ones are checked, so it works in a 2D and a 3D game. Triggers and the colliders of `ray.source` and of
// `ray.listener` (and their children) never block, and neither does a collider the listener's position is inside. A source inside
// a collider that is not its own (a floor, a room volume) is blocked by it.
bool audio_occlusion_blocked(Physics& physics, World& world, const AudioOcclusionRay& ray);

}  // namespace fa
