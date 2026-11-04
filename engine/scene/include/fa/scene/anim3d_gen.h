// Clip generators for rig.bake skeletons (docs/ANIMATION.md, "Generators"): a walk or run cycle from stride parameters, the gaits of
// a quadruped (walk, trot, gallop), idle breathing, swings of tails and chains, and hit reactions. The result is an ordinary
// Anim3DClip (anim3d.h), written to a `*.anim.json` by `anim3d.generate`, that the user can then edit key by key.
//
// HOW A GAIT IS MADE. Every foot follows a path: in stance it stays still on the ground (relative to the ground it moves back at the
// walking speed), in the swing it lifts, passes the body and lands one stride further. The pelvis follows a bounce curve, lowered
// only as far as the legs need to reach, and a two-bone solver (ik3d.h) turns each leg to put the ankle on its path, so a planted
// foot does not slide: its clip contacts say when. The clip's `groundSpeed` is the speed of the character, so a game that moves the
// entity at that speed has the feet stand still on the floor. Everything is computed with + - * / and fa::det trigonometry: the same
// bits on every machine.
#pragma once

#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/scene/anim3d.h"
#include "fa/scene/rig3d.h"

namespace fa {

// The generator kinds: walk, run, trot, gallop, idle, swing, hit.
const std::vector<std::string>& anim3d_generator_kinds();
// The catalog for docs and tools: [{kind, doc, templates, params: [{name, doc, default, min, max}]}].
Json anim3d_generator_catalog();
// Makes a clip of `kind` for the rig. `params` holds the kind's parameters (all optional, unknown keys are an error with "did you mean").
// Errors name what the rig lacks (legs, spine, tail) and say which template has it. The clip's `generated` records the kind and
// every parameter with the value used, so the same call reproduces the clip.
Result<Anim3DClip> generate_anim3d(const Rig3D& rig, std::string_view kind, const Json& params = Json::object());

}  // namespace fa
