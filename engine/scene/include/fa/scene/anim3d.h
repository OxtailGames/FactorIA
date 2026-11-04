// Clips for the bones of a skinned rig: the `*.anim.json` files whose `format` is "factoria.anim3d/1"
// (schemas/anim3d.schema.json, docs/ANIMATION.md, "3D bone clips"). A 2D clip (anim_clip.h, "factoria.anim/1") drives fields of
// entities; a 3D clip drives the bones of a skinned .glb, the ones rig.bake makes (docs/RIGGING.md). Both use the same file suffix,
// the same keys (`t`, `value`, `interp`, `in`, `out`), the same easings (clip_ease_names()) and the same events; `format` says which.
//
// WHAT A TRACK STORES. A track is one channel of one bone, the bone named by its canonical name (`thigh_l`, `spine_2`, `root`):
//   rotation     the rotation of the bone's LOCAL frame from its rest pose, in degrees as (x, y, z) = (pitch, yaw, roll) applied in the
//                engine's order (Quat::from_euler_deg: yaw, then pitch, then roll), or as a quaternion (x, y, z, w) when the clip says
//                `"rotation": "quat"`. At rest every rig.bake bone has an identity rotation, so the rotation IS the bone's local
//                rotation, in a frame with the model's axes: +X tips an upward-pointing bone towards +Z (forward).
//   translation  an offset from the bone's rest position in its parent's frame, model units (meters). Only the root normally has one.
//   scale        a multiplier of the rest scale, per axis (1 = rest).
// A bone with no track rests. A track on a bone the model lacks is skipped with one warning (the clip says it was made for another
// rig: retarget it, anim3d.retarget).
//
// HOW IT PLAYS. The Animator of a model (a skinned .glb) with `clips: {"walk": "anim/hero_walk.anim.json"}` binds each clip to the
// skeleton's bones by name and plays it like one of the glTF's own animations (cross-fades, the state machine, events). Nothing is baked into the .glb;
// a change to the file is picked up when `clips` is assigned again. Interpolation between keys follows `interp`; the Animator samples
// it into dense linear keys, so what the preview shows is what the game plays.
//
// Deterministic: nothing here reads a clock; sampling is + - * / and fa::det trigonometry.
#pragma once

#include <array>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/scene/anim_clip.h"
#include "fa/scene/rig3d.h"
#include "fa/scene/skeleton.h"

namespace fa {

inline constexpr const char* kAnim3DFormat = "factoria.anim3d/1";

enum class Anim3DChannel : std::uint8_t { Rotation, Translation, Scale };
const char* anim3d_channel_name(Anim3DChannel c);

struct Anim3DTrack {
    std::string bone;
    Anim3DChannel channel = Anim3DChannel::Rotation;
    // keys[i].value holds 3 numbers (rotation as euler degrees, translation, scale) or 4 (a quaternion x y z w, when the clip's
    // rotation is "quat"). Tangents are filled in for bezier keys that give none.
    std::vector<ClipKey> keys;
};

// A stretch of the clip where a bone rests on the ground (a foot's stance): the clip generators write them, retargeting keeps the
// foot planted through them.
struct Anim3DContact {
    std::string bone;
    float from = 0.0f, to = 0.0f;  // seconds; from > to wraps through the end of a looping clip
};

struct Anim3DClip {
    std::string path;                  // project-relative file ("" for a clip made in memory)
    std::int64_t mtime = -1;
    std::string doc;
    std::string rig;                   // the rig document or model the clip was made for ("" = any), informational
    std::string templateName;          // the rig template (humanoid, quadruped...) the bones follow, "" = unknown
    float duration = 1.0f;
    bool loop = true;
    bool quat = false;                 // rotation keys are quaternions (true) or euler degrees (false)
    float groundSpeed = 0.0f;          // model units per second the ground moves under the feet in stance (0 = no stance or in place)
    std::vector<Anim3DTrack> tracks;
    std::vector<ClipEvent> events;     // ascending in t
    std::vector<Anim3DContact> contacts;
    Json generated = Json();           // what anim3d.generate made it from (kind and parameters), null for a hand-made clip
};

// True when the JSON is a 3D bone clip (its `format` is "factoria.anim3d/1").
bool is_anim3d_json(const Json& json);
// Reads a clip. On failure the Error names the file and the JSON pointer of the first problem and says how many more there are;
// `issues` (may be null) receives all of them.
Result<std::shared_ptr<const Anim3DClip>> parse_anim3d(const Json& json, std::string_view file, std::vector<ClipIssue>* issues = nullptr);
// The clip as JSON, the way parse_anim3d reads it back (numbers rounded to 7 digits so files stay readable and stable).
Json anim3d_to_json(const Anim3DClip& clip);
// Reads the file through fa::fs; cached per path and modification time. A file that is a 2D clip is an Error that says so.
Result<std::shared_ptr<const Anim3DClip>> load_anim3d(std::string_view path, std::vector<ClipIssue>* issues = nullptr);
void clear_anim3d_cache();

// --------------------------------------------------------------------------------------------------------------- playing --
// Which node each track drives: tracks[i] -> node, -1 when the skeleton has no such bone.
struct Anim3DBinding {
    std::vector<int> node;
    std::vector<std::string> missing;  // the distinct bone names the skeleton lacks, in track order
};
Anim3DBinding bind_anim3d(const Anim3DClip& clip, const SkeletonAsset& skeleton);
// Poses `pose` as the clip is at `time` (clamped to [0, duration]); bones with no track keep what `pose` has. Rotation = rest * the
// track's rotation, translation = rest + the track's, scale = rest * the track's.
void sample_anim3d(const Anim3DClip& clip, const Anim3DBinding& binding, const SkeletonAsset& skeleton, float time, Pose& pose);
// The clip as a glTF-style AnimClip of the skeleton (dense linear keys, so eases and beziers survive), with its events and `loop`.
// `name` becomes the clip's name.
AnimClip anim3d_to_anim_clip(const Anim3DClip& clip, const Anim3DBinding& binding, const SkeletonAsset& skeleton, const std::string& name);

// Checks the clip against a rig: every bone a track names must exist (did you mean), contacts must name bones too.
std::vector<ClipIssue> check_anim3d_rig(const Anim3DClip& clip, const Rig3D& rig);

// Keys of a track at `t` is the value; the helper the editor-free tools use to read a key by time.
std::array<float, 4> sample_anim3d_track(const Anim3DTrack& track, bool quat, float time);

}  // namespace fa
