// The logic of the editor's Animation panel with no ImGui and no window: which rows the dopesheet shows, keys picked by
// (track, time), what a drag of keys or a pasted selection asks of the anim.* commands, and which keys record mode writes when
// a field of a part changes. Every edit of a clip is a command call (anim.set_keys, anim.move_keys...): this file builds their
// arguments and the panel (anim_panel.cpp) runs them, so an AI sees the same calls. anim_tests.cpp covers it.
#pragma once

#include <array>
#include <optional>
#include <set>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/reflect.h"
#include "fa/scene/anim_clip.h"
#include "fa/scene/world.h"

namespace fa::editor {

// One call of a command: {name, args}. An edit of the panel is a list of them (one undo step).
using ModelCall = std::pair<std::string, Json>;

// ------------------------------------------------------------------------------------------------------------------ time --
// Seconds rounded to a microsecond (what the commands store).
double clip_round_time(double t);
// `t` moved to the nearest frame of a `fps` frames-per-second grid; fps 0 (or less) leaves it as it is.
double snap_to_frames(double t, int fps);

// ------------------------------------------------------------------------------------------------------------------ keys --
// A key of a clip: its track (index in ClipAsset::tracks) and its time. Two times closer than 0.1 ms are the same key (the
// commands' own tolerance), so the ordering uses the time in 0.1 ms ticks.
struct KeyId {
    int track = 0;
    long long tick = 0;
    double t = 0;
    bool operator<(const KeyId& o) const { return track != o.track ? track < o.track : tick < o.tick; }
    bool operator==(const KeyId& o) const { return track == o.track && tick == o.tick; }
};
KeyId make_key_id(int track, double t);
using KeySet = std::set<KeyId>;

// The key of `track` at `t` (within 0.1 ms), or nullptr.
const ClipKey* find_key_at(const ClipTrack& track, double t);
// "linear", "step", "bezier" or the easing name ("quadOut"): how the key reaches the next one, as the file writes it.
std::string key_interp_name(const ClipKey& key);
// The key's value as clip JSON: a number, an array of channels, or the raw value of a stepping field.
Json key_value_json(const ClipTrack& track, const ClipKey& key);
// The value of the track at `t`, as clip JSON (what set_keys needs to put a key exactly where the curve is).
Json value_at(const ClipTrack& track, double t);
// The key as the anim.set_keys argument at time `t`: {t, value, interp?, in?, out?} (interp left out when linear).
Json key_json(const ClipTrack& track, const ClipKey& key, double t);
// The track as the commands name it: {path?, component?, field} (Transform is the default component and is left out).
Json track_ref_json(const ClipTrack& track);
// "rotation.z", "Sprite.color.a": the field of a track with its component when that is not Transform.
std::string track_title(const ClipTrack& track);
// The earliest and latest time in the selection (0 when empty).
double earliest_time(const KeySet& keys);
double latest_time(const KeySet& keys);

// ------------------------------------------------------------------------------------------------------------- the rows --
// The dopesheet groups tracks by part (the track path): "arm_l/hand" is one group with its tracks under it.
struct TrackGroup {
    std::string part;                 // the track path as written ("" = the entity that plays the clip)
    std::string title;                // what the row says: the path, or "(the entity)" for ""
    std::vector<int> tracks;          // indices in ClipAsset::tracks, in clip order
};
std::vector<TrackGroup> group_tracks(const ClipAsset& clip);
// A name that is not in `taken`: base, base2, base3...
std::string unique_name(const std::vector<std::string>& taken, const std::string& base);

// ------------------------------------------------------------------------------------------------------------- key edits --
// How far a selection may move: `offset` raised so the earliest key stays at 0 or later.
double clamp_move_offset(const KeySet& keys, double offset);
// `offset` changed so the earliest key lands on a frame of the grid (fps 0 = unchanged), then clamped.
double snapped_move_offset(const KeySet& keys, double offset, int fps);
// A scale about the earliest key changed so the latest key lands on a frame (fps 0 = unchanged); never below 0.05.
double snapped_scale(const KeySet& keys, double scale, int fps);
// Where the selection's keys end up after scale (about the earliest key) then offset: the selection after the move.
KeySet moved_keys(const KeySet& keys, double offset, double scale);
// anim.move_keys {path, keys, offset, scale, extendDuration}; the pivot is the earliest key.
ModelCall move_keys_call(const std::string& clipPath, const KeySet& keys, double offset, double scale);
// anim.set_interp for the keys: `interp` is linear, step, bezier or an easing name.
ModelCall set_interp_call(const std::string& clipPath, const KeySet& keys, const std::string& interp);
// One anim.remove_keys per track that has selected keys (a track left without keys disappears with them).
std::vector<ModelCall> delete_keys_calls(const std::string& clipPath, const ClipAsset& clip, const KeySet& keys);
// A key set to a bezier tangent: the slope (value units per second) of `channel` (0 for a one-channel track) on the arriving
// (`in`) or leaving (`out`) side. Other channels keep the tangent they have.
ModelCall set_tangent_call(const std::string& clipPath, const ClipTrack& track, const ClipKey& key, int trackIndex, int channel,
                           bool outgoing, float slope);

// Keys copied with their times relative to the earliest copied key.
struct ClipboardKey {
    Json track;      // track_ref_json
    double rel = 0;
    Json key;        // key_json at t = 0 (the time is set when pasted)
};
struct KeyClipboard {
    std::vector<ClipboardKey> keys;
    bool empty() const { return keys.empty(); }
};
KeyClipboard copy_keys(const ClipAsset& clip, const KeySet& keys);
// anim.set_keys, one call per track, with the earliest copied key at `at` (a track the clip lacks is created). Keys past the
// duration extend it.
std::vector<ModelCall> paste_keys_calls(const std::string& clipPath, const KeyClipboard& clipboard, double at);
// The selection a paste makes (so the pasted keys stay selected). `clip` is the clip the paste goes into.
KeySet pasted_selection(const ClipAsset& clip, const KeyClipboard& clipboard, double at);

// ----------------------------------------------------------------------------------------------------------- record mode --
// One animatable channel of a part that a gizmo or the Inspector changed.
struct RecordKey {
    std::string component;   // "Transform"
    std::string field;       // as a track names it: "position.x", "rotation.z", "color.a", "visible", "region"
    Json value;              // the new value (a number for a channel)
    Json before;             // what the part had
    std::string base;        // the field without a channel ("position"); equal to `field` for a whole-field value
    Json wholeValue;         // the whole field after the change ([x, y, z]): what a track that animates the whole field takes
    Json wholeBefore;
};
// The part's path from `owner` down ("" when it is the owner), or nullopt when `part` is not below `owner` or its name finds
// another entity first (a clip names parts by name, so two siblings with one name cannot be told apart).
std::optional<std::string> part_path_of(const World& world, Entity owner, Entity part);
// What changed in `field` of a component when it goes from `live` to `newValue` (JSON as scene.set_component takes it): one
// RecordKey per vector channel that differs, one for a whole-field value that differs; empty when nothing changed or the field
// cannot be animated.
std::vector<RecordKey> record_changes(const TypeInfo& type, const FieldInfo& field, const void* live, const Json& newValue);
// anim.set_keys calls (one per RecordKey) that write the changes as keys at `t`. A key already there keeps its interpolation. A
// track the clip lacks starts with the old value at t=0 as well, when t is later, so the part stays as it was until the new key.
std::vector<ModelCall> record_calls(const std::string& clipPath, const ClipAsset& clip, const std::string& part,
                                    const std::vector<RecordKey>& changes, double t);

}  // namespace fa::editor
