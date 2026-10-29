// Keyframed 2D clips: the `*.anim.json` files (format "factoria.anim/1", schemas/anim.schema.json) the Animator plays when
// it has no glTF model (docs/ANIMATION.md, "2D clips"). GPU-free on purpose: this header is the shared contract of the
// clip loader, the Animator (animation.h), the validation of a project and the editor's timeline.
//
// A clip is `duration`, `loop`, `tracks` and `events`. A track drives ONE reflected field of one entity under the entity
// that plays the clip: `path` names it by EntityInfo names ("body/arm_l/hand", "" = the entity itself), `component` and
// `field` say which field ("Transform" "rotation.z", "Sprite" "color.a", "Sprite" "region"). A key is {t, value, interp}.
// Numbers, vectors, colours and angles interpolate; bools, ints, enums, assets and rects only step.
#pragma once

#include <array>
#include <cstdint>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/reflect.h"
#include "fa/core/types.h"

namespace fa {

class World;

// How a key reaches the next one: `linear`, `step` (holds its value until the next key), `bezier` (a cubic Hermite curve
// with the `out` tangent of this key and the `in` tangent of the next one) or `ease` (linear through one of the easing
// curves of tween(): "quadOut", "backInOut"...). A field that only steps ignores it.
enum class ClipInterp : std::uint8_t { Linear, Step, Bezier, Ease };

struct ClipKey {
    float t = 0.0f;                    // seconds from the start of the clip
    ClipInterp interp = ClipInterp::Linear;
    int ease = -1;                     // Ease: index into clip_ease_names()
    std::array<float, 4> value{};      // interpolating fields: the channels of the value (1 for a number, 2/3/4 for vectors)
    std::array<float, 4> inTan{};      // bezier: slope arriving at this key, field units per second per channel
    std::array<float, 4> outTan{};     // bezier: slope leaving this key
    Json raw;                          // stepping fields: the value as written (bool, integer, enum name, asset path, rect)
};

struct ClipTrack {
    std::string path;                  // as written: names of the entities from the player down, "" = the player itself
    int pathIndex = 0;                 // index in ClipAsset::paths
    std::string component;             // reflected component name, "Transform" when the file leaves it out
    std::string field;                 // reflected field name without the channel ("rotation")
    std::string spelled;               // field as written, with the channel ("rotation.z")
    int channel = -1;                  // -1 = the whole field, 0..3 = one component (x y z w, or r g b a for a Color)
    int channels = 1;                  // number of channels the value of a key has
    bool stepped = false;              // bool, int, enum, asset or rect: switches at the key, never interpolates
    bool angle = false;                // degrees: a cross-fade or a layer takes the short way round
    const TypeInfo* type = nullptr;
    const FieldInfo* info = nullptr;
    std::vector<ClipKey> keys;         // ascending in t, at least one
};

struct ClipEvent {
    float t = 0.0f;
    std::string name;
    Json data = Json::object();        // sent with the event next to {id, clip, time}
};

struct ClipAsset {
    std::string path;                  // project-relative file ("" for a clip parsed from memory)
    std::int64_t mtime = -1;           // modification time the file had when it was read
    float duration = 0.0f;             // seconds; no key or event is later
    bool loop = true;                  // the default of the Animator: a state's `loop` overrides it
    std::string doc;
    std::vector<ClipTrack> tracks;
    std::vector<ClipEvent> events;     // ascending in t
    std::vector<std::string> paths;    // the distinct track paths, in order of first use
    std::vector<std::vector<std::string>> segments;  // paths split at '/'
};

// One problem of a clip file: where (a JSON pointer: "/tracks/2/keys/3/t"), what, and how to fix it.
struct ClipIssue {
    std::string pointer;
    std::string message;
    std::string hint;
};

// The names tween() accepts as an easing, in the order of ClipKey::ease: "linear", then "quadIn", "quadOut", "quadInOut"...
const std::vector<std::string>& clip_ease_names();
// Easing curve `index` of clip_ease_names() at t (0..1 in, 0..1 out; back / elastic overshoot): the curves of factoria.js.
float clip_ease(int index, float t);

// Reads a clip from JSON. `file` is only used in messages. On failure the Error names the file and the JSON pointer of the
// first problem ("anim/walk.anim.json /tracks/1/keys/2/t: ...") and says how many more there are; `issues` (may be null)
// receives every problem, so a tool can list them all. The check of the track paths needs an entity: see
// check_clip_paths.
Result<std::shared_ptr<const ClipAsset>> parse_anim_clip(const Json& json, std::string_view file,
                                                         std::vector<ClipIssue>* issues = nullptr);
// Reads the file through fa::fs. Cached per path and modification time: every animator that plays the same file shares
// one ClipAsset, and a file that changed on disk is read again by the next call (hot reload). An unreadable or invalid
// file is an Error (the cache keeps the last good one).
Result<std::shared_ptr<const ClipAsset>> load_anim_clip(std::string_view path, std::vector<ClipIssue>* issues = nullptr);
// Forgets every cached clip (tests).
void clear_anim_clip_cache();

// The entity at `path` below `root` ("" = root itself): the first child with each name, walking down. The Error lists the
// names at the level that failed with "did you mean", and where a name that exists deeper lives.
Result<Entity> resolve_clip_path(const World& world, Entity root, std::string_view path);
// Every track of `clip` whose path names no entity under `root`, as issues pointing at "/tracks/<i>/path". Empty = the
// clip fits the entity.
std::vector<ClipIssue> check_clip_paths(const World& world, Entity root, const ClipAsset& clip);

// The value of a track at `time` (clamped to [0, clip.duration] by the caller): `out` receives the channels of an
// interpolating field and `raw` the key's value for a stepping one (nullptr otherwise). Used by the Animator and tests.
void sample_clip_track(const ClipTrack& track, float time, std::array<float, 4>& out, const Json** raw);

}  // namespace fa
