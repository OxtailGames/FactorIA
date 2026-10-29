#include "anim_model.h"

#include <algorithm>
#include <cmath>
#include <map>

namespace fa::editor {

namespace {

constexpr double kTick = 1e-4;  // the commands treat two key times closer than this as one

double round4(double v) { return std::round(v * 10000.0) / 10000.0; }

Json channels_json(const std::array<float, 4>& v, int channels) {
    if (channels <= 1) return double(v[0]);
    Json a = Json::array();
    for (int c = 0; c < channels; ++c) a.push_back(double(v[std::size_t(c)]));
    return a;
}

bool same_track(const ClipTrack& tr, const std::string& path, const std::string& component, const std::string& field) {
    return tr.path == path && tr.component == component && tr.spelled == field;
}

}  // namespace

double clip_round_time(double t) { return std::round(t * 1e6) / 1e6; }

double snap_to_frames(double t, int fps) {
    if (fps <= 0) return clip_round_time(t);
    return clip_round_time(std::round(t * fps) / double(fps));
}

KeyId make_key_id(int track, double t) {
    KeyId k;
    k.track = track;
    k.tick = std::llround(t / kTick);
    k.t = t;
    return k;
}

const ClipKey* find_key_at(const ClipTrack& track, double t) {
    for (const ClipKey& k : track.keys)
        if (std::fabs(double(k.t) - t) < kTick) return &k;
    return nullptr;
}

std::string key_interp_name(const ClipKey& key) {
    switch (key.interp) {
        case ClipInterp::Step: return "step";
        case ClipInterp::Bezier: return "bezier";
        case ClipInterp::Ease: {
            const auto& names = clip_ease_names();
            return key.ease >= 0 && std::size_t(key.ease) < names.size() ? names[std::size_t(key.ease)] : "linear";
        }
        default: return "linear";
    }
}

Json key_value_json(const ClipTrack& track, const ClipKey& key) {
    if (track.stepped) return key.raw;
    return channels_json(key.value, track.channels);
}

Json value_at(const ClipTrack& track, double t) {
    std::array<float, 4> v{};
    const Json* raw = nullptr;
    sample_clip_track(track, float(t), v, &raw);
    if (raw) return *raw;
    return channels_json(v, track.channels);
}

Json key_json(const ClipTrack& track, const ClipKey& key, double t) {
    Json k = Json::object({{"t", clip_round_time(t)}, {"value", key_value_json(track, key)}});
    if (!track.stepped && key.interp != ClipInterp::Linear) {
        k["interp"] = key_interp_name(key);
        if (key.interp == ClipInterp::Bezier) {
            k["in"] = channels_json(key.inTan, track.channels);
            k["out"] = channels_json(key.outTan, track.channels);
        }
    }
    return k;
}

Json track_ref_json(const ClipTrack& track) {
    Json j = Json::object();
    if (!track.path.empty()) j["path"] = track.path;
    if (track.component != "Transform") j["component"] = track.component;
    j["field"] = track.spelled;
    return j;
}

std::string track_title(const ClipTrack& track) {
    return track.component == "Transform" ? track.spelled : track.component + "." + track.spelled;
}

double earliest_time(const KeySet& keys) {
    double t = keys.empty() ? 0.0 : 1e30;
    for (const KeyId& k : keys) t = std::min(t, k.t);
    return t;
}

double latest_time(const KeySet& keys) {
    double t = 0.0;
    for (const KeyId& k : keys) t = std::max(t, k.t);
    return t;
}

std::vector<TrackGroup> group_tracks(const ClipAsset& clip) {
    std::vector<TrackGroup> groups;
    std::map<std::string, std::size_t> at;
    for (std::size_t i = 0; i < clip.tracks.size(); ++i) {
        const std::string& path = clip.tracks[i].path;
        auto it = at.find(path);
        if (it == at.end()) {
            TrackGroup g;
            g.part = path;
            g.title = path.empty() ? "(the entity)" : path;
            groups.push_back(std::move(g));
            it = at.emplace(path, groups.size() - 1).first;
        }
        groups[it->second].tracks.push_back(int(i));
    }
    return groups;
}

std::string unique_name(const std::vector<std::string>& taken, const std::string& base) {
    auto free_name = [&](const std::string& n) { return std::find(taken.begin(), taken.end(), n) == taken.end(); };
    if (free_name(base)) return base;
    for (int i = 2;; ++i)
        if (std::string n = base + std::to_string(i); free_name(n)) return n;
}

double clamp_move_offset(const KeySet& keys, double offset) { return std::max(offset, -earliest_time(keys)); }

double snapped_move_offset(const KeySet& keys, double offset, int fps) {
    if (keys.empty()) return 0.0;
    const double first = earliest_time(keys);
    if (fps > 0) offset = snap_to_frames(first + offset, fps) - first;
    return clip_round_time(clamp_move_offset(keys, offset));
}

double snapped_scale(const KeySet& keys, double scale, int fps) {
    scale = std::max(scale, 0.05);
    const double pivot = earliest_time(keys), span = latest_time(keys) - pivot;
    if (fps <= 0 || span < 1e-6) return scale;
    const double target = snap_to_frames(pivot + span * scale, fps);
    const double snapped = (target - pivot) / span;
    return snapped >= 0.05 ? snapped : scale;
}

KeySet moved_keys(const KeySet& keys, double offset, double scale) {
    KeySet out;
    const double pivot = earliest_time(keys);
    for (const KeyId& k : keys) out.insert(make_key_id(k.track, clip_round_time(pivot + (k.t - pivot) * scale + offset)));
    return out;
}

namespace {
Json key_refs(const KeySet& keys) {
    Json a = Json::array();
    for (const KeyId& k : keys) a.push_back(Json::object({{"track", k.track}, {"t", k.t}}));
    return a;
}
}  // namespace

ModelCall move_keys_call(const std::string& clipPath, const KeySet& keys, double offset, double scale) {
    Json a = Json::object({{"path", clipPath}, {"keys", key_refs(keys)}, {"extendDuration", true}});
    if (std::fabs(offset) > 1e-9) a["offset"] = clip_round_time(offset);
    if (std::fabs(scale - 1.0) > 1e-9) a["scale"] = std::round(scale * 1e6) / 1e6;
    return {"anim.move_keys", std::move(a)};
}

ModelCall set_interp_call(const std::string& clipPath, const KeySet& keys, const std::string& interp) {
    return {"anim.set_interp", Json::object({{"path", clipPath}, {"keys", key_refs(keys)}, {"interp", interp}})};
}

std::vector<ModelCall> delete_keys_calls(const std::string& clipPath, const ClipAsset& clip, const KeySet& keys) {
    std::map<int, std::vector<double>> byTrack;
    for (const KeyId& k : keys)
        if (k.track >= 0 && std::size_t(k.track) < clip.tracks.size()) byTrack[k.track].push_back(k.t);
    std::vector<ModelCall> calls;
    for (const auto& [track, times] : byTrack) {
        Json ts = Json::array();
        for (double t : times) ts.push_back(t);
        calls.push_back({"anim.remove_keys", Json::object({{"path", clipPath}, {"track", track_ref_json(clip.tracks[std::size_t(track)])}, {"times", ts}})});
    }
    return calls;
}

ModelCall set_tangent_call(const std::string& clipPath, const ClipTrack& track, const ClipKey& key, int trackIndex, int channel,
                           bool outgoing, float slope) {
    std::array<float, 4> v = outgoing ? key.outTan : key.inTan;
    v[std::size_t(std::clamp(channel, 0, 3))] = slope;
    Json a = Json::object({{"path", clipPath},
                           {"keys", Json::array({Json::object({{"track", trackIndex}, {"t", double(key.t)}})})},
                           {"interp", "bezier"}});
    a[outgoing ? "out" : "in"] = channels_json(v, track.channels);
    return {"anim.set_interp", std::move(a)};
}

KeyClipboard copy_keys(const ClipAsset& clip, const KeySet& keys) {
    KeyClipboard out;
    const double first = earliest_time(keys);
    for (const KeyId& id : keys) {
        if (id.track < 0 || std::size_t(id.track) >= clip.tracks.size()) continue;
        const ClipTrack& tr = clip.tracks[std::size_t(id.track)];
        const ClipKey* k = find_key_at(tr, id.t);
        if (!k) continue;
        out.keys.push_back({track_ref_json(tr), clip_round_time(id.t - first), key_json(tr, *k, 0.0)});
    }
    return out;
}

std::vector<ModelCall> paste_keys_calls(const std::string& clipPath, const KeyClipboard& clipboard, double at) {
    std::vector<std::string> order;
    std::map<std::string, Json> keysOf, trackOf;
    for (const ClipboardKey& c : clipboard.keys) {
        const std::string id = c.track.dump();
        if (!keysOf.count(id)) {
            order.push_back(id);
            keysOf[id] = Json::array();
            trackOf[id] = c.track;
        }
        Json k = c.key;
        k["t"] = clip_round_time(at + c.rel);
        keysOf[id].push_back(std::move(k));
    }
    std::vector<ModelCall> calls;
    for (const std::string& id : order)
        calls.push_back({"anim.set_keys", Json::object({{"path", clipPath}, {"track", trackOf[id]}, {"keys", keysOf[id]}, {"extendDuration", true}})});
    return calls;
}

KeySet pasted_selection(const ClipAsset& clip, const KeyClipboard& clipboard, double at) {
    KeySet out;
    std::map<std::string, int> index;
    int next = int(clip.tracks.size());
    for (const ClipboardKey& c : clipboard.keys) {
        const std::string id = c.track.dump();
        auto it = index.find(id);
        if (it == index.end()) {
            int found = -1;
            for (std::size_t i = 0; i < clip.tracks.size(); ++i)
                if (same_track(clip.tracks[i], c.track.value("path", std::string()), c.track.value("component", std::string("Transform")),
                               c.track.value("field", std::string())))
                    found = int(i);
            it = index.emplace(id, found >= 0 ? found : next++).first;
        }
        out.insert(make_key_id(it->second, clip_round_time(at + c.rel)));
    }
    return out;
}

// ------------------------------------------------------------------------------------------------------------ record mode --
std::optional<std::string> part_path_of(const World& world, Entity owner, Entity part) {
    if (owner.is_null() || part.is_null() || !world.alive(owner) || !world.alive(part)) return std::nullopt;
    std::vector<std::string> names;
    Entity e = part;
    while (e != owner) {
        if (e.is_null()) return std::nullopt;
        names.push_back(world.info(e).name);
        e = world.parent(e);
    }
    std::string path;
    for (auto it = names.rbegin(); it != names.rend(); ++it) path += (path.empty() ? "" : "/") + *it;
    auto found = resolve_clip_path(world, owner, path);
    if (!found.ok() || *found != part) return std::nullopt;
    return path;
}

std::vector<RecordKey> record_changes(const TypeInfo& type, const FieldInfo& field, const void* live, const Json& newValue) {
    std::vector<RecordKey> out;
    if (!clip_field_animatable(field) || !live) return out;
    DefaultObject scratch(type);
    if (!field_from_json(field, scratch.get(), newValue).ok()) return out;
    int channels = 0;
    switch (field.kind) {
        case FieldKind::Vec2: channels = 2; break;
        case FieldKind::Vec3: channels = 3; break;
        case FieldKind::Vec4: case FieldKind::Color: channels = 4; break;
        default: break;
    }
    const Json whole = field_to_json(field, scratch.get()), wholeBefore = field_to_json(field, live);
    if (channels == 0) {
        const bool differs = field.kind == FieldKind::Float
                                 ? std::fabs(*static_cast<const float*>(field.ptr(scratch.get())) - *static_cast<const float*>(field.ptr(live))) > 1e-6f
                                 : whole != wholeBefore;
        if (differs) out.push_back({type.name, field.name, whole, wholeBefore, field.name, whole, wholeBefore});
        return out;
    }
    const float* now = static_cast<const float*>(field.ptr(scratch.get()));
    const float* was = static_cast<const float*>(field.ptr(live));
    const char* letters = field.kind == FieldKind::Color ? "rgba" : "xyzw";
    for (int c = 0; c < channels; ++c)
        if (std::fabs(now[c] - was[c]) > 1e-6f)
            out.push_back({type.name, field.name + "." + std::string(1, letters[c]), round4(now[c]), round4(was[c]), field.name, whole, wholeBefore});
    return out;
}

std::vector<ModelCall> record_calls(const std::string& clipPath, const ClipAsset& clip, const std::string& part,
                                    const std::vector<RecordKey>& changes, double t) {
    std::vector<ModelCall> calls;
    for (const RecordKey& ch : changes) {
        // A clip that animates the whole vector field (position as [x, y]) takes the whole value, not a second track on a channel.
        int at = -1;
        bool whole = false;
        for (std::size_t i = 0; i < clip.tracks.size(); ++i) {
            if (same_track(clip.tracks[i], part, ch.component, ch.field)) { at = int(i); whole = false; break; }
            if (clip.tracks[i].path == part && clip.tracks[i].component == ch.component && clip.tracks[i].spelled == ch.base &&
                ch.base != ch.field) { at = int(i); whole = true; }
        }
        const ClipTrack* tr = at >= 0 ? &clip.tracks[std::size_t(at)] : nullptr;
        const Json& value = whole ? ch.wholeValue : ch.value;
        Json keys = Json::array();
        if (tr) {
            Json k = Json::object({{"t", clip_round_time(t)}, {"value", value}});
            if (const ClipKey* old = find_key_at(*tr, t)) {
                k = key_json(*tr, *old, t);
                k["value"] = value;
            }
            keys.push_back(std::move(k));
        } else {
            if (t > kTick) keys.push_back(Json::object({{"t", 0.0}, {"value", ch.before}}));
            keys.push_back(Json::object({{"t", clip_round_time(t)}, {"value", ch.value}}));
        }
        Json track = Json::object({{"field", tr ? tr->spelled : ch.field}});
        if (!part.empty()) track["path"] = part;
        if (ch.component != "Transform") track["component"] = ch.component;
        calls.push_back({"anim.set_keys", Json::object({{"path", clipPath}, {"track", track}, {"keys", keys}, {"extendDuration", true}})});
    }
    return calls;
}

}  // namespace fa::editor
