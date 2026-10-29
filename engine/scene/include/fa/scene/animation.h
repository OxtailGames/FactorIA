// Skeletal animation without a GPU: sampling clips into poses, blending, skinning matrices, and the Animator system
// that plays them. The runtime calls update_animators() once per FIXED step (after physics, before the step's game
// events are dispatched), so animation, clip events and state machine transitions are deterministic and also run in
// headless runs. The renderer only READS Animator::palette (components.h): one skinning matrix per joint of
// each skin (palette = skin 0, skinPalettes = all), ready to upload as the joint matrices of a skinned draw.
//
// An Animator without a glTF model plays keyframed 2D clips instead (*.anim.json, anim_clip.h): it writes the fields the
// clips animate (Transform, Sprite, ...) of its entity and its descendants.
//
// ORDER IN THE FRAME. update_animators() runs once per fixed step, after physics and before the step's game events are
// dispatched and before anything is drawn (engine.cpp, "After the Animator"). When it returns the 2D pose of every
// Animator is in the components, and everything that must see that pose and still change it runs next, in this order:
// systems that solve on top of the animated pose (the IK of bones, M42.2), then skinning / drawing, which only read.
#pragma once

#include <string>
#include <string_view>
#include <vector>

#include "fa/scene/skeleton.h"
#include "fa/scene/world.h"

namespace fa {

// Local transform of every node of a SkeletonAsset (same indices as SkeletonAsset::nodes).
struct Pose {
    std::vector<Vec3> translation;
    std::vector<Quat> rotation;
    std::vector<Vec3> scale;
};

Pose rest_pose(const SkeletonAsset& skeleton);
// Overwrites the nodes the clip animates; the others keep what `pose` has. `time` is clamped to [0, clip.duration].
void sample_clip(const SkeletonAsset& skeleton, const AnimClip& clip, float time, Pose& pose);
// Per node: translation and scale lerp, rotation slerp. weight 0 = a, 1 = b.
Pose blend_poses(const Pose& a, const Pose& b, float weight);
// World (model-space) matrix of every node.
std::vector<Mat4> pose_globals(const SkeletonAsset& skeleton, const Pose& pose);
// jointGlobal * inverseBind for each joint of `skin`; empty when the file has no such skin.
std::vector<Mat4> skin_palette(const SkeletonAsset& skeleton, const Pose& pose, int skin = 0);

// ---------------------------------------------------------------------------------------------------- the system --
// Advances every active Animator by `dt` seconds (already multiplied by the time scale): state machine, clip time,
// cross-fade, clip events (pushed to world.events().game), pose and palette.
void update_animators(World& world, float dt);

// Starts `clip` (glTF animation name), cross-fading from the current pose over `fadeSeconds` (0 = cut). Playing the
// clip that already plays does nothing (it is not restarted). Starting a clip while a fade runs drops the older clip
// of that fade. Errors list the clip names ("did you mean").
Result<void> animator_play(World& world, Entity e, std::string_view clip, float fadeSeconds);
// Back to the bind pose and paused.
Result<void> animator_stop(World& world, Entity e);
// Sets a state machine parameter (number or bool). Unknown names are an error that lists the declared ones.
Result<void> animator_set(World& world, Entity e, std::string_view name, const Json& value);
// Makes a parameter true for the next update only (a one-shot input such as "jump").
Result<void> animator_trigger(World& world, Entity e, std::string_view name);
// Clip names with durations of the model the animator plays: [{"name", "duration"}]. For 2D clips: [{"name", "file",
// "duration", "loop"}] (a file that does not load has "error" instead of "duration").
Result<Json> animator_clips(World& world, Entity e);

// 2D clips only (an Animator with `clips` and no glTF model):
// Poses the entity as clip `clip` is at `time` seconds (clamped to the clip) and leaves the Animator paused there. A
// later play() or an assignment to `clip` plays on.
Result<void> animator_sample(World& world, Entity e, std::string_view clip, float time);
// Sets the weight (0..1) of the layer called `layer`. Weight 0 stops the layer, a rising weight starts it from its first pose.
Result<void> animator_set_layer_weight(World& world, Entity e, std::string_view layer, float weight);
// Plays `clip` on the layer (which has a plain `clip`, no `states`), cross-fading over `fadeSeconds`; "" empties the layer.
Result<void> animator_play_layer(World& world, Entity e, std::string_view layer, std::string_view clip, float fadeSeconds);

}  // namespace fa
