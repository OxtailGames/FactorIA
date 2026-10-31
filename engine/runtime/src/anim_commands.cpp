// The commands that make and edit keyframed 2D clips (*.anim.json, docs/ANIMATION.md, "Commands for clips"): anim.create_clip,
// anim.set_keys, anim.remove_keys, anim.move_keys, anim.set_interp, anim.add_track, anim.remove_track, anim.add_event,
// anim.move_event, anim.set_event, anim.remove_event, anim.set_clip and anim.restore.
//
// Every one of them reads the file as JSON, changes the document, puts it in canonical order (keys sorted by t, events sorted),
// checks the result with the clip loader's own rules (parse_anim_clip: the same errors a game would give) and only then writes
// it. A refused edit leaves the file untouched. The result of each carries `undo`: the command + arguments (anim.restore with
// the whole previous document, or null when the file did not exist) that put the file back; running it returns its own `undo`,
// which is the redo. The editor's timeline (M42.4) and AIs use the same commands.
#include <algorithm>
#include <cmath>
#include <filesystem>
#include <format>

#include "engine_impl.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/scene/anim_clip.h"

namespace fa {

namespace {

constexpr double kTimeEps = 1e-4;  // two keys closer than this (seconds) are the same time

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

double round_time(double t) { return std::round(t * 1e6) / 1e6; }

// ------------------------------------------------------------------------------------------------------------- the file --

std::string clip_files_hint() { return "Clip files end in .anim.json and live in the project, e.g. anim/hero_walk.anim.json."; }

std::vector<std::string> clip_files() {
    std::vector<std::string> out;
    for (const std::string& f : fs::list(".", true, ".json"))
        if (ends_with(to_lower(f), ".anim.json")) out.push_back(f);
    return out;
}

// The project-relative path argument `key`, checked to be a clip file inside the project that a command may write.
std::string need_clip_path(const Json& a, const char* key = "path") {
    if (!a.contains(key) || !a[key].is_string() || a[key].get<std::string>().empty())
        throw CommandError("invalid_argument", std::string("Missing '") + key + "'.", "Pass the clip file, e.g. \"anim/hero_walk.anim.json\". " + clip_files_hint());
    auto norm = fs::normalize_checked(a[key].get<std::string>());
    if (!norm.ok()) throw CommandError("invalid_argument", norm.error().message, norm.error().hint);
    if (!ends_with(to_lower(*norm), ".anim.json"))
        throw CommandError("invalid_argument", "'" + *norm + "' is not a clip file name.", clip_files_hint());
    if (auto w = fs::check_writable(*norm); !w.ok()) throw CommandError("invalid_argument", w.error().message, w.error().hint);
    return *norm;
}

Json read_doc(const std::string& path) {
    if (!fs::exists(path))
        throw CommandError("not_found", "Clip file '" + path + "' does not exist. " + did_you_mean(path, clip_files()),
                           "anim.create_clip {path, duration} makes a new one.");
    auto text = fs::read_text(path);
    if (!text.ok()) throw CommandError("failed", path + ": " + text.error().message, text.error().hint);
    auto doc = parse_json(*text, path);
    if (!doc.ok()) throw CommandError("invalid_argument", doc.error().message, "Fix the JSON syntax of the clip by hand, or rewrite it with anim.create_clip {overwrite: true}.");
    if (!doc->is_object())
        throw CommandError("invalid_argument", path + ": a clip file must be a JSON object.", "Rewrite it with anim.create_clip {overwrite: true}.");
    return std::move(*doc);
}

// The document in the order the files are written: format, doc, duration, loop, tracks, events; each track path, component,
// field, keys; keys sorted by t as t, value, interp, in, out. Anything unknown stays (at the end) for the loader to refuse.
Json canonical(const Json& in) {
    auto copy_known = [](const Json& src, std::initializer_list<const char*> order) {
        Json out = Json::object();
        for (const char* k : order)
            if (src.contains(k)) out[k] = src[k];
        for (auto it = src.begin(); it != src.end(); ++it)
            if (!out.contains(it.key())) out[it.key()] = *it;
        return out;
    };
    Json out = Json::object();
    for (const char* k : {"$schema", "format", "doc", "duration", "loop"})
        if (in.contains(k)) out[k] = in[k];
    if (!out.contains("format")) out["format"] = "factoria.anim/1";
    Json tracks = Json::array();
    if (in.contains("tracks") && in["tracks"].is_array()) {
        for (const Json& tr : in["tracks"]) {
            if (!tr.is_object()) { tracks.push_back(tr); continue; }
            Json t = copy_known(tr, {"path", "component", "field", "keys"});
            if (t.contains("keys") && t["keys"].is_array()) {
                Json keys = Json::array();
                for (const Json& k : t["keys"]) keys.push_back(k.is_object() ? copy_known(k, {"t", "value", "interp", "in", "out"}) : k);
                const bool numeric = std::all_of(keys.begin(), keys.end(), [](const Json& k) { return k.is_object() && k.contains("t") && k["t"].is_number(); });
                if (numeric)
                    std::stable_sort(keys.begin(), keys.end(), [](const Json& x, const Json& y) { return x["t"].get<double>() < y["t"].get<double>(); });
                t["keys"] = std::move(keys);
            }
            tracks.push_back(std::move(t));
        }
    }
    out["tracks"] = std::move(tracks);
    if (in.contains("events") && in["events"].is_array()) {
        Json events = Json::array();
        for (const Json& e : in["events"]) events.push_back(e.is_object() ? copy_known(e, {"t", "name", "data"}) : e);
        const bool numeric = std::all_of(events.begin(), events.end(), [](const Json& e) { return e.is_object() && e.contains("t") && e["t"].is_number(); });
        if (numeric)
            std::stable_sort(events.begin(), events.end(), [](const Json& x, const Json& y) { return x["t"].get<double>() < y["t"].get<double>(); });
        if (!events.empty() || in.contains("events")) out["events"] = std::move(events);
    }
    for (auto it = in.begin(); it != in.end(); ++it)
        if (!out.contains(it.key())) out[it.key()] = *it;
    return out;
}

Json issues_json(const std::vector<ClipIssue>& issues) {
    Json arr = Json::array();
    for (const ClipIssue& i : issues) arr.push_back(Json::object({{"pointer", i.pointer}, {"message", i.message}, {"hint", i.hint}}));
    return arr;
}

// Checks `doc` with the loader's rules; throws with every problem when it is not a valid clip.
void check_doc(const std::string& path, const Json& doc) {
    std::vector<ClipIssue> issues;
    auto parsed = parse_anim_clip(doc, path, &issues);
    if (parsed.ok()) return;
    throw CommandError("invalid_argument", parsed.error().message, parsed.error().hint, Json::object({{"issues", issues_json(issues)}}));
}

Json undo_of(const std::string& path, const Json& before) {
    return Json::object({{"command", "anim.restore"}, {"args", Json::object({{"path", path}, {"clip", before}})}});
}

// Canonical order, validation, write; the result every editing command returns (plus `extra`).
Json commit(const std::string& path, const Json& edited, const Json& before, Json extra = Json::object()) {
    const Json doc = canonical(edited);
    check_doc(path, doc);
    if (auto w = fs::write_text(path, dump_json(doc, JsonFormat{})); !w.ok())
        throw CommandError("failed", path + ": " + w.error().message, w.error().hint.empty() ? "Check that the folder is writable." : w.error().hint);
    clear_anim_clip_cache();
    Json out = Json::object({{"path", path}, {"duration", doc["duration"]}, {"loop", doc.value("loop", true)},
                             {"tracks", doc["tracks"].size()}, {"events", doc.contains("events") ? doc["events"].size() : 0}});
    for (auto it = extra.begin(); it != extra.end(); ++it) out[it.key()] = *it;
    out["undo"] = undo_of(path, before);
    return out;
}

// ------------------------------------------------------------------------------------------------------------- tracks --

struct TrackSpec {
    std::string path, component = "Transform", field;
};

std::string track_label(const std::string& path, const std::string& component, const std::string& field) {
    return (path.empty() ? std::string("(the entity itself)") : path) + " " + component + "." + field;
}
std::string track_label(const Json& tr) {
    return track_label(tr.value("path", std::string()), tr.value("component", std::string("Transform")), tr.value("field", std::string()));
}

TrackSpec parse_track_spec(const Json& j, const char* what = "track") {
    if (!j.is_object())
        throw CommandError("invalid_argument", std::string(what) + " must be an object {path, component, field}, got " + describe_json_value(j) + ".",
                           "Example: {\"path\": \"body/arm_l\", \"component\": \"Transform\", \"field\": \"rotation.z\"}; path \"\" is the entity itself, component defaults to Transform.");
    for (auto it = j.begin(); it != j.end(); ++it)
        if (it.key() != "path" && it.key() != "component" && it.key() != "field")
            throw CommandError("invalid_argument", std::string(what) + ": unknown key '" + it.key() + "'. " + did_you_mean(it.key(), std::vector<std::string>{"path", "component", "field"}),
                               "A track is named by path, component and field.");
    TrackSpec s;
    if (j.contains("path")) {
        if (!j["path"].is_string()) throw CommandError("invalid_argument", std::string(what) + ".path must be a string.", "Names joined with '/': \"body/arm_l\", or \"\" for the entity itself.");
        s.path = j["path"].get<std::string>();
    }
    if (j.contains("component")) {
        if (!j["component"].is_string()) throw CommandError("invalid_argument", std::string(what) + ".component must be a string.", "Write \"Transform\" or \"Sprite\".");
        s.component = j["component"].get<std::string>();
    }
    if (!j.contains("field") || !j["field"].is_string() || j["field"].get<std::string>().empty())
        throw CommandError("invalid_argument", std::string(what) + " needs a `field`.", "Write the field with a channel for one component of a vector: \"position\", \"rotation.z\", \"color.a\".");
    s.field = j["field"].get<std::string>();
    return s;
}

Json& tracks_of(Json& doc) {
    if (!doc.contains("tracks") || !doc["tracks"].is_array()) doc["tracks"] = Json::array();
    return doc["tracks"];
}

int find_track(const Json& doc, const TrackSpec& s) {
    if (!doc.contains("tracks") || !doc["tracks"].is_array()) return -1;
    for (std::size_t i = 0; i < doc["tracks"].size(); ++i) {
        const Json& tr = doc["tracks"][i];
        if (tr.is_object() && tr.value("path", std::string()) == s.path && tr.value("component", std::string("Transform")) == s.component &&
            tr.value("field", std::string()) == s.field)
            return int(i);
    }
    return -1;
}

std::string track_list(const Json& doc) {
    std::string out;
    if (doc.contains("tracks") && doc["tracks"].is_array())
        for (std::size_t i = 0; i < doc["tracks"].size(); ++i)
            out += (out.empty() ? "" : "; ") + std::format("[{}] {}", i, track_label(doc["tracks"][i]));
    return out.empty() ? "The clip has no tracks yet (anim.set_keys or anim.add_track makes one)." : "The clip's tracks: " + out + ".";
}

// A track chosen by its index in `tracks` or by {path, component, field}.
int resolve_track(const Json& doc, const Json& sel, const char* what = "track") {
    if (sel.is_number_integer()) {
        const int i = sel.get<int>();
        if (i < 0 || !doc.contains("tracks") || std::size_t(i) >= doc["tracks"].size())
            throw CommandError("not_found", std::format("{} index {} is out of range.", what, i), track_list(doc));
        return i;
    }
    const TrackSpec s = parse_track_spec(sel, what);
    const int i = find_track(doc, s);
    if (i >= 0) return i;
    std::vector<std::string> labels;
    if (doc.contains("tracks") && doc["tracks"].is_array())
        for (const Json& tr : doc["tracks"]) labels.push_back(track_label(tr));
    throw CommandError("not_found", "The clip has no track " + track_label(s.path, s.component, s.field) + ". " + did_you_mean(track_label(s.path, s.component, s.field), labels), track_list(doc));
}

int find_key(const Json& track, double t) {
    for (std::size_t i = 0; i < track["keys"].size(); ++i)
        if (std::fabs(track["keys"][i].value("t", -1.0) - t) < kTimeEps) return int(i);
    return -1;
}

std::string times_of(const Json& track) {
    std::string out;
    for (const Json& k : track["keys"]) out += (out.empty() ? "" : ", ") + std::format("{}", k.value("t", 0.0));
    return out;
}

double need_time(const Json& j, const char* what) {
    if (!j.is_number() || !std::isfinite(j.get<double>()) || j.get<double>() < 0)
        throw CommandError("invalid_argument", std::string(what) + " must be a number of seconds, 0 or more, got " + describe_json_value(j) + ".", "Seconds from the start of the clip: 0.25.");
    return j.get<double>();
}

// With `entity`: the track must name a part of that entity that has the component.
void check_track_on_entity(Engine::Impl& I, const Json& args, const TrackSpec& s) {
    if (!args.contains("entity") || args["entity"].is_null()) return;
    const Entity root = need_entity(I.world, args, "entity");
    auto part = resolve_clip_path(I.world, root, s.path);
    if (!part.ok()) throw CommandError("not_found", part.error().message, part.error().hint);
    const TypeInfo* type = TypeRegistry::global().find(s.component);
    if (type && !I.world.get(*part, *type))
        throw CommandError("invalid_argument", std::format("The part '{}' has no {} component, so the track {} would drive nothing.", s.path.empty() ? I.world.id_of(root) : s.path, s.component, track_label(s.path, s.component, s.field)),
                           "Add the component first: scene.set_component {id, component: \"" + s.component + "\"}.");
}

// The value `field` ("rotation.z", "color") of the part has now, as clip JSON.
Json current_value(Engine::Impl& I, const Json& args, const TrackSpec& s) {
    const Entity root = need_entity(I.world, args, "entity");
    auto part = resolve_clip_path(I.world, root, s.path);
    if (!part.ok()) throw CommandError("not_found", part.error().message, part.error().hint);
    const TypeInfo* type = TypeRegistry::global().find(s.component);
    if (!type) throw CommandError("not_found", "Unknown component '" + s.component + "'. " + TypeRegistry::global().suggest(s.component), "Component names are PascalCase: Transform, Sprite...");
    const void* obj = I.world.get(*part, *type);
    if (!obj) throw CommandError("invalid_argument", "The part has no " + s.component + " component.", "Add it first with scene.set_component.");
    std::string name = s.field, sub;
    if (const std::size_t dot = name.find('.'); dot != std::string::npos) { sub = name.substr(dot + 1); name = name.substr(0, dot); }
    const FieldInfo* f = type->field(name);
    if (!f) throw CommandError("invalid_argument", s.component + " has no field '" + name + "'.", "api.components lists the fields.");
    Json v = field_to_json(*f, obj);
    if (sub.empty()) return v;
    std::array<float, 4> c{};
    std::string err;
    switch (f->kind) {
        case FieldKind::Vec2: { Vec2 x; if (json_to(v, x, &err)) c = {x.x, x.y, 0, 0}; break; }
        case FieldKind::Vec3: { Vec3 x; if (json_to(v, x, &err)) c = {x.x, x.y, x.z, 0}; break; }
        case FieldKind::Vec4: { Vec4 x; if (json_to(v, x, &err)) c = {x.x, x.y, x.z, x.w}; break; }
        case FieldKind::Color: { Color x; if (json_to(v, x, &err)) c = {x.r, x.g, x.b, x.a}; break; }
        default: break;
    }
    const std::string letters = f->kind == FieldKind::Color ? "rgba" : "xyzw";
    const std::size_t at = sub.size() == 1 ? letters.find(sub[0]) : std::string::npos;
    if (at == std::string::npos) throw CommandError("invalid_argument", "'" + sub + "' is not a component of " + s.component + "." + name + ".", "Use " + std::string(1, letters[0]) + ".. letters: " + letters + ".");
    return double(c[at]);
}

// Reads the `keys` argument: [{t, value, interp?, in?, out?}], each checked for shape (the loader checks the values).
std::vector<Json> read_key_args(const Json& a, const char* key = "keys") {
    if (!a.contains(key) || !a[key].is_array() || a[key].empty())
        throw CommandError("invalid_argument", std::string("'") + key + "' must be a non-empty array of keys.", "Example: [{\"t\": 0, \"value\": 0}, {\"t\": 0.5, \"value\": 30, \"interp\": \"quadOut\"}].");
    std::vector<Json> out;
    for (std::size_t i = 0; i < a[key].size(); ++i) {
        const Json& k = a[key][i];
        const std::string where = std::format("{}[{}]", key, i);
        if (!k.is_object()) throw CommandError("invalid_argument", where + " must be an object {t, value, interp?, in?, out?}, got " + describe_json_value(k) + ".", "Example: {\"t\": 0.25, \"value\": 10}.");
        for (auto it = k.begin(); it != k.end(); ++it)
            if (it.key() != "t" && it.key() != "value" && it.key() != "interp" && it.key() != "in" && it.key() != "out")
                throw CommandError("invalid_argument", where + ": unknown key '" + it.key() + "'. " + did_you_mean(it.key(), std::vector<std::string>{"t", "value", "interp", "in", "out"}), "A key is {t, value, interp?, in?, out?}.");
        if (!k.contains("t")) throw CommandError("invalid_argument", where + " needs `t` (seconds).", "Example: {\"t\": 0.25, \"value\": 10}.");
        if (!k.contains("value")) throw CommandError("invalid_argument", where + " needs `value`.", "The value has the type of the field: a number, [x, y], [r, g, b, a], a bool, an enum name or an asset path.");
        Json copy = k;
        copy["t"] = round_time(need_time(k["t"], (where + ".t").c_str()));
        out.push_back(std::move(copy));
    }
    return out;
}

// Raises `duration` to `needed` (extendDuration) or refuses with the fix.
void fit_duration(Json& doc, double needed, bool extend, const char* what) {
    const double duration = doc.value("duration", 0.0);
    if (needed <= duration + 1e-6) return;
    if (!extend)
        throw CommandError("invalid_argument", std::format("{} at t={} is past the clip's duration {}.", what, needed, duration),
                           std::format("Pass extendDuration: true to raise the duration to {}, or anim.set_clip {{duration}} first, or use an earlier time.", needed));
    doc["duration"] = round_time(needed);
}

struct KeyRef {
    int track = 0;
    double t = 0;
};
// `keys`: [{track, t}] with `track` an index or {path, component, field}.
std::vector<KeyRef> read_key_refs(const Json& doc, const Json& a) {
    if (!a.contains("keys") || !a["keys"].is_array() || a["keys"].empty())
        throw CommandError("invalid_argument", "'keys' must be a non-empty array of {track, t}.", "Example: [{\"track\": 0, \"t\": 0.25}, {\"track\": {\"path\": \"body\", \"field\": \"rotation.z\"}, \"t\": 0.5}]. anim.list shows the tracks.");
    std::vector<KeyRef> out;
    for (std::size_t i = 0; i < a["keys"].size(); ++i) {
        const Json& k = a["keys"][i];
        if (!k.is_object() || !k.contains("track") || !k.contains("t"))
            throw CommandError("invalid_argument", std::format("keys[{}] must be {{track, t}}.", i), "track is the index in the clip's tracks or {path, component, field}; t the time of the key in seconds.");
        KeyRef r;
        r.track = resolve_track(doc, k["track"], "keys[].track");
        r.t = need_time(k["t"], "keys[].t");
        const Json& track = doc["tracks"][std::size_t(r.track)];
        const int at = find_key(track, r.t);
        if (at < 0)
            throw CommandError("not_found", std::format("The track {} has no key at t={}.", track_label(track), r.t), "Its keys are at: " + times_of(track) + ".");
        r.t = track["keys"][std::size_t(at)].value("t", r.t);
        out.push_back(r);
    }
    return out;
}

Json clip_schema_properties() { return Json::object(); }

}  // namespace

void register_anim_view_commands(Engine& engine, Engine::Impl& I);  // anim_view_commands.cpp

void register_anim_commands(Engine& engine, Engine::Impl& I) {
    static const char* kTrackSchema =
        R"({"type":"object","properties":{"path":{"type":"string","default":"","description":"Names (EntityInfo name) from the entity that plays the clip down to the part, joined with '/': \"body/arm_l\". \"\" is the entity itself."},
            "component":{"type":"string","default":"Transform","description":"Reflected component of that part: Transform, Sprite..."},
            "field":{"type":"string","description":"Field with an optional channel: \"rotation.z\", \"position\", \"color.a\", \"Sprite.region\" is component Sprite + field region."}},"required":["field"]})";
    (void)clip_schema_properties;

    I.commands.add({"anim.create_clip", "Write a new keyframed 2D clip file (*.anim.json).",
           "Creates the file with `duration` seconds, `loop`, and optionally its `tracks` and `events` in the format of docs/ANIMATION.md "
           "(\"2D clips\", schemas/anim.schema.json). Everything is checked with the loader's own rules and nothing is written if it is "
           "wrong (errors name the JSON pointer). It refuses to replace a file unless `overwrite` is true. Result: {path, duration, loop, "
           "tracks, events, undo} where `undo` is {command, args} that puts the file back (or deletes the new file); run it with "
           "anim.restore. Then add keys with anim.set_keys and play it from an Animator: Animator.clips {\"walk\": path}. Example: "
           "anim.create_clip {\"path\":\"anim/hero_walk.anim.json\",\"duration\":0.8,\"loop\":true}",
           parse_schema(R"({"type":"object","required":["path","duration"],"properties":{
               "path":{"type":"string","description":"Project-relative file ending in .anim.json."},
               "duration":{"type":"number","minimum":0,"description":"Length of the clip in seconds."},
               "loop":{"type":"boolean","default":true,"description":"true repeats the clip, false stops on the last pose (anim.finished)."},
               "doc":{"type":"string","description":"What the clip shows."},
               "tracks":{"type":"array","description":"Tracks [{path, component, field, keys:[{t, value, interp?}]}]; none = an empty clip to fill with anim.set_keys."},
               "events":{"type":"array","description":"Events [{t, name, data?}] sent to the game when the clip passes t."},
               "overwrite":{"type":"boolean","default":false,"description":"Replace the file if it exists."}}})"),
           false, "anim"},
          [](const Json& a) {
              const std::string path = need_clip_path(a);
              const double duration = need_time(a.contains("duration") ? a["duration"] : Json(), "duration");
              Json before = nullptr;
              if (fs::exists(path)) {
                  if (!a.value("overwrite", false))
                      throw CommandError("invalid_argument", "'" + path + "' already exists.", "Edit it with anim.set_keys, or pass overwrite: true to replace it.");
                  before = read_doc(path);
              }
              Json doc = Json::object({{"format", "factoria.anim/1"}});
              if (a.contains("doc")) doc["doc"] = a["doc"];
              doc["duration"] = round_time(duration);
              doc["loop"] = a.value("loop", true);
              doc["tracks"] = a.contains("tracks") ? a["tracks"] : Json::array();
              if (a.contains("events")) doc["events"] = a["events"];
              return commit(path, doc, before);
          });

    I.commands.add({"anim.set_keys", "Add or replace keys of one track of a clip, creating the track if it is missing.",
           "`track` is {path, component?, field}: the part (names from the entity that plays the clip, \"\" = itself), the component "
           "(default Transform) and the field with an optional channel (\"rotation.z\", \"position\", \"color.a\"). Each key is {t, value, "
           "interp?, in?, out?}: a key at an existing time REPLACES that key, any other time adds one; the keys stay sorted. Numbers, "
           "vectors, colours and angles interpolate (`interp`: linear, step, bezier with in/out tangents, or a tween easing such as "
           "quadOut); bool, int, enum, asset and rect fields only step. With `entity` (the entity that plays the clip) the track's "
           "part and component must exist on it, with \"did you mean\" over the names. A key past the duration is refused unless "
           "`extendDuration` is true (the duration grows to it). Result: {path, track (index), added, replaced, keys, undo}. Example: "
           "anim.set_keys {\"path\":\"anim/hero_walk.anim.json\",\"track\":{\"path\":\"body/arm_l\",\"field\":\"rotation.z\"},"
           "\"keys\":[{\"t\":0,\"value\":-30},{\"t\":0.4,\"value\":30,\"interp\":\"quadInOut\"},{\"t\":0.8,\"value\":-30}]}",
           [] { Json s = parse_schema(R"({"type":"object","required":["path","track","keys"],"properties":{
               "path":{"type":"string","description":"The clip file (.anim.json)."},
               "keys":{"type":"array","minItems":1,"items":{"type":"object","required":["t","value"],"properties":{
                   "t":{"type":"number","minimum":0,"description":"Seconds from the start of the clip."},
                   "value":{"description":"The value at t, shaped like the field."},
                   "interp":{"type":"string","description":"linear (default), step, bezier, or a tween easing (quadOut, backInOut...)."},
                   "in":{"description":"bezier: slope arriving at this key, field units per second, shaped like the value."},
                   "out":{"description":"bezier: slope leaving this key."}}}},
               "entity":{"type":"string","description":"Entity that plays the clip (id or name): the track's part and component are checked against it."},
               "extendDuration":{"type":"boolean","default":false,"description":"Raise the clip's duration when a key is later than it."}}})");
               s["properties"]["track"] = parse_schema(kTrackSchema); return s; }(),
           false, "anim"},
          [&I](const Json& a) {
              const std::string path = need_clip_path(a);
              Json before = read_doc(path);
              Json doc = before;
              const TrackSpec spec = parse_track_spec(a.contains("track") ? a["track"] : Json());
              check_track_on_entity(I, a, spec);
              const std::vector<Json> keys = read_key_args(a);
              const bool extend = a.value("extendDuration", false);
              for (const Json& k : keys) fit_duration(doc, k["t"].get<double>(), extend, "A key");
              int index = find_track(doc, spec);
              if (index < 0) {
                  Json tr = Json::object();
                  if (!spec.path.empty()) tr["path"] = spec.path;
                  if (spec.component != "Transform" || a["track"].contains("component")) tr["component"] = spec.component;
                  tr["field"] = spec.field;
                  tr["keys"] = Json::array();
                  tracks_of(doc).push_back(std::move(tr));
                  index = int(doc["tracks"].size()) - 1;
              }
              Json& track = doc["tracks"][std::size_t(index)];
              int added = 0, replaced = 0;
              for (const Json& k : keys) {
                  const int at = find_key(track, k["t"].get<double>());
                  if (at >= 0) { track["keys"][std::size_t(at)] = k; ++replaced; }
                  else { track["keys"].push_back(k); ++added; }
              }
              return commit(path, doc, before, Json::object({{"track", index}, {"added", added}, {"replaced", replaced}}));
          });

    I.commands.add({"anim.remove_keys", "Remove keys of one track of a clip, by time or all of them.",
           "`times` lists the times (seconds) of the keys to remove; each must be a key of the track (the error lists its times). `all` "
           "removes every key, which removes the track (a track needs at least one key). Result: {path, removed, trackRemoved, undo}. "
           "Example: anim.remove_keys {\"path\":\"anim/hero_walk.anim.json\",\"track\":{\"path\":\"body\",\"field\":\"rotation.z\"},\"times\":[0.4]}",
           [] { Json s = parse_schema(R"({"type":"object","required":["path","track"],"properties":{
               "path":{"type":"string","description":"The clip file (.anim.json)."},
               "times":{"type":"array","items":{"type":"number","minimum":0},"description":"Times of the keys to remove."},
               "all":{"type":"boolean","default":false,"description":"Remove every key (and so the track)."}}})");
               s["properties"]["track"] = parse_schema(R"({"description":"Index in the clip's tracks, or {path, component, field}."})"); return s; }(),
           false, "anim"},
          [](const Json& a) {
              const std::string path = need_clip_path(a);
              Json before = read_doc(path);
              Json doc = before;
              const int index = resolve_track(doc, a.contains("track") ? a["track"] : Json());
              Json& track = doc["tracks"][std::size_t(index)];
              const bool all = a.value("all", false);
              if (all == a.contains("times"))
                  throw CommandError("invalid_argument", all ? "Pass `all` or `times`, not both." : "Nothing to remove: pass `times` or `all: true`.",
                                     "Example: {\"times\": [0.4]} removes the key at 0.4 s; {\"all\": true} removes the whole track.");
              int removed = 0;
              if (all) {
                  removed = int(track["keys"].size());
                  track["keys"] = Json::array();
              } else {
                  if (!a["times"].is_array() || a["times"].empty()) throw CommandError("invalid_argument", "`times` must be a non-empty array of seconds.", "Example: [0.4].");
                  for (const Json& tj : a["times"]) {
                      const int at = find_key(track, need_time(tj, "times[]"));
                      if (at < 0) throw CommandError("not_found", std::format("The track {} has no key at t={}.", track_label(track), tj.get<double>()), "Its keys are at: " + times_of(track) + ".");
                      track["keys"].erase(track["keys"].begin() + at);
                      ++removed;
                  }
              }
              const bool trackRemoved = track["keys"].empty();
              if (trackRemoved) doc["tracks"].erase(doc["tracks"].begin() + index);
              return commit(path, doc, before, Json::object({{"removed", removed}, {"trackRemoved", trackRemoved}}));
          });

    I.commands.add({"anim.move_keys", "Move and scale a selection of keys in time.",
           "`keys` selects keys as [{track, t}] (`track` is the index in the clip's tracks or {path, component, field}; anim.list shows "
           "them). Each selected key goes to `pivot + (t - pivot) * scale + offset` (scale first, about `pivot`; the default pivot is the "
           "earliest selected key, scale 1, offset 0). Keys that are not selected stay. Refused (nothing written) when a key would land "
           "on another key of its track, before 0, or after the duration (unless `extendDuration`). Result: {path, moved, keys: "
           "[{track, from, to}], undo}. Example: slow the swing down by half from its start: anim.move_keys "
           "{\"path\":\"anim/hero_walk.anim.json\",\"keys\":[{\"track\":0,\"t\":0.2},{\"track\":0,\"t\":0.4}],\"scale\":2,\"extendDuration\":true}",
           parse_schema(R"({"type":"object","required":["path","keys"],"properties":{
               "path":{"type":"string","description":"The clip file (.anim.json)."},
               "keys":{"type":"array","minItems":1,"items":{"type":"object","required":["track","t"],"properties":{
                   "track":{"description":"Index in the clip's tracks, or {path, component, field}."},
                   "t":{"type":"number","minimum":0,"description":"Time of the key (seconds)."}}}},
               "offset":{"type":"number","default":0,"description":"Seconds added after scaling (negative moves earlier)."},
               "scale":{"type":"number","exclusiveMinimum":0,"default":1,"description":"Time scale about the pivot: 2 doubles the spacing, 0.5 halves it."},
               "pivot":{"type":"number","minimum":0,"description":"Seconds the scale is about (default: the earliest selected key)."},
               "extendDuration":{"type":"boolean","default":false,"description":"Raise the duration when a key moves past it."}}})"),
           false, "anim"},
          [](const Json& a) {
              const std::string path = need_clip_path(a);
              Json before = read_doc(path);
              Json doc = before;
              const std::vector<KeyRef> refs = read_key_refs(doc, a);
              const double offset = a.value("offset", 0.0), scale = a.value("scale", 1.0);
              if (!(scale > 0)) throw CommandError("invalid_argument", "scale must be above 0.", "Use 2 to slow the selection down, 0.5 to speed it up.");
              if (offset == 0.0 && scale == 1.0) throw CommandError("invalid_argument", "Nothing to do: offset is 0 and scale is 1.", "Pass offset (seconds) and/or scale.");
              double pivot = 1e30;
              for (const KeyRef& r : refs) pivot = std::min(pivot, r.t);
              if (a.contains("pivot")) pivot = need_time(a["pivot"], "pivot");
              const bool extend = a.value("extendDuration", false);
              Json moved = Json::array();
              std::vector<std::pair<int, double>> done;  // track, new time
              double last = 0;
              for (const KeyRef& r : refs) {
                  const double to = round_time(pivot + (r.t - pivot) * scale + offset);
                  if (to < -1e-9)
                      throw CommandError("invalid_argument", std::format("The key at t={} would move to t={}, before the start of the clip.", r.t, to), "Use a smaller negative offset, or move the keys later first.");
                  for (const auto& d : done)
                      if (d.first == r.track && std::fabs(d.second - to) < kTimeEps)
                          throw CommandError("invalid_argument", std::format("Two selected keys of the track {} would both land at t={}.", track_label(doc["tracks"][std::size_t(r.track)]), to), "Use a scale above 0 that keeps them apart.");
                  done.emplace_back(r.track, to);
                  last = std::max(last, to);
              }
              fit_duration(doc, last, extend, "A key");
              // Move: take the selected keys out of their tracks first, then put them back at the new times.
              std::vector<std::pair<int, Json>> carried;
              for (std::size_t i = 0; i < refs.size(); ++i) {
                  Json& track = doc["tracks"][std::size_t(refs[i].track)];
                  const int at = find_key(track, refs[i].t);
                  Json key = track["keys"][std::size_t(at)];
                  key["t"] = done[i].second;
                  carried.emplace_back(refs[i].track, std::move(key));
                  moved.push_back(Json::object({{"track", refs[i].track}, {"from", refs[i].t}, {"to", done[i].second}}));
              }
              for (const KeyRef& r : refs) {
                  Json& keys = doc["tracks"][std::size_t(r.track)]["keys"];
                  const int at = find_key(doc["tracks"][std::size_t(r.track)], r.t);
                  if (at >= 0) keys.erase(keys.begin() + at);
              }
              for (auto& [ti, key] : carried) {
                  Json& track = doc["tracks"][std::size_t(ti)];
                  if (find_key(track, key["t"].get<double>()) >= 0)
                      throw CommandError("invalid_argument", std::format("A key would land on another key of the track {} at t={}.", track_label(track), key["t"].get<double>()),
                                         "Move the keys that are in the way too (select them), or use another offset.");
                  track["keys"].push_back(std::move(key));
              }
              return commit(path, doc, before, Json::object({{"moved", refs.size()}, {"keys", moved}}));
          });

    I.commands.add({"anim.set_interp", "Set how selected keys reach the next key: interp or easing, and bezier tangents.",
           "`keys` selects keys as [{track, t}] (as anim.move_keys). `interp` is linear, step, bezier or a tween easing (quadIn, "
           "quadOut, backInOut, elasticOut...). `in` and `out` set the bezier tangents of the selected keys (slope in field units per "
           "second, shaped like the value); without them a bezier key gets a smooth tangent through its neighbours. Result: {path, "
           "changed, undo}. Example: anim.set_interp {\"path\":\"anim/hero_walk.anim.json\",\"keys\":[{\"track\":0,\"t\":0.4}],\"interp\":\"quadOut\"}",
           parse_schema(R"({"type":"object","required":["path","keys","interp"],"properties":{
               "path":{"type":"string","description":"The clip file (.anim.json)."},
               "keys":{"type":"array","minItems":1,"items":{"type":"object","required":["track","t"],"properties":{
                   "track":{"description":"Index in the clip's tracks, or {path, component, field}."},
                   "t":{"type":"number","minimum":0}}}},
               "interp":{"type":"string","description":"linear, step, bezier or an easing of tween()."},
               "in":{"description":"bezier: incoming slope for every selected key."},
               "out":{"description":"bezier: outgoing slope for every selected key."}}})"),
           false, "anim"},
          [](const Json& a) {
              const std::string path = need_clip_path(a);
              Json before = read_doc(path);
              Json doc = before;
              const std::vector<KeyRef> refs = read_key_refs(doc, a);
              if (!a.contains("interp") || !a["interp"].is_string())
                  throw CommandError("invalid_argument", "Missing `interp`.", "linear, step, bezier or an easing of tween() such as quadOut or backInOut.");
              for (const KeyRef& r : refs) {
                  Json& track = doc["tracks"][std::size_t(r.track)];
                  Json& key = track["keys"][std::size_t(find_key(track, r.t))];
                  key["interp"] = a["interp"];
                  for (const char* tan : {"in", "out"}) {
                      if (a.contains(tan)) key[tan] = a[tan];
                      else if (key.contains(tan) && a["interp"].get<std::string>() != "bezier") key.erase(tan);
                  }
              }
              return commit(path, doc, before, Json::object({{"changed", refs.size()}}));
          });

    I.commands.add({"anim.add_track", "Add a track to a clip, with keys or the part's current value as its first key.",
           "`track` is {path, component?, field}. Give `keys` (as anim.set_keys), or `entity` (the entity that plays the clip) to start "
           "the track with one key at t=0 holding the part's current value; with neither it is refused. An existing track of the same "
           "field is refused (use anim.set_keys to edit it); two tracks may not drive the same field channel. Result: {path, track "
           "(index), keys, undo}. Example: anim.add_track {\"path\":\"anim/hero_walk.anim.json\",\"track\":{\"path\":\"body\",\"field\":\"position.y\"},\"entity\":\"hero\"}",
           [] { Json s = parse_schema(R"({"type":"object","required":["path","track"],"properties":{
               "path":{"type":"string","description":"The clip file (.anim.json)."},
               "keys":{"type":"array","description":"The first keys [{t, value, interp?}]."},
               "entity":{"type":"string","description":"Entity that plays the clip: checks the part and gives the first key its current value."},
               "extendDuration":{"type":"boolean","default":false,"description":"Raise the duration when a key is later than it."}}})");
               s["properties"]["track"] = parse_schema(kTrackSchema); return s; }(),
           false, "anim"},
          [&I](const Json& a) {
              const std::string path = need_clip_path(a);
              Json before = read_doc(path);
              Json doc = before;
              const TrackSpec spec = parse_track_spec(a.contains("track") ? a["track"] : Json());
              if (const int at = find_track(doc, spec); at >= 0)
                  throw CommandError("invalid_argument", "The clip already has the track " + track_label(spec.path, spec.component, spec.field) + " (index " + std::to_string(at) + ").",
                                     "Edit its keys with anim.set_keys, or remove it first with anim.remove_track.");
              check_track_on_entity(I, a, spec);
              Json keys = Json::array();
              if (a.contains("keys")) {
                  for (const Json& k : read_key_args(a)) {
                      fit_duration(doc, k["t"].get<double>(), a.value("extendDuration", false), "A key");
                      keys.push_back(k);
                  }
              } else if (a.contains("entity") && !a["entity"].is_null()) {
                  keys.push_back(Json::object({{"t", 0.0}, {"value", current_value(I, a, spec)}}));
              } else {
                  throw CommandError("invalid_argument", "A track needs a first key.", "Pass `keys` ([{t: 0, value: ...}]) or `entity` (the entity that plays the clip) to start from the part's current value.");
              }
              Json tr = Json::object();
              if (!spec.path.empty()) tr["path"] = spec.path;
              if (spec.component != "Transform" || a["track"].contains("component")) tr["component"] = spec.component;
              tr["field"] = spec.field;
              tr["keys"] = keys;
              tracks_of(doc).push_back(std::move(tr));
              return commit(path, doc, before, Json::object({{"track", int(doc["tracks"].size()) - 1}, {"keys", keys.size()}}));
          });

    I.commands.add({"anim.remove_track", "Remove a whole track (all its keys) from a clip.",
           "`track` is the index in the clip's tracks or {path, component, field}. The tracks after it shift down by one. Result: "
           "{path, removed: {path, component, field, keys}, undo}. Example: anim.remove_track {\"path\":\"anim/hero_walk.anim.json\",\"track\":{\"path\":\"body\",\"field\":\"rotation.z\"}}",
           parse_schema(R"({"type":"object","required":["path","track"],"properties":{
               "path":{"type":"string","description":"The clip file (.anim.json)."},
               "track":{"description":"Index in the clip's tracks, or {path, component, field}."}}})"),
           false, "anim"},
          [](const Json& a) {
              const std::string path = need_clip_path(a);
              Json before = read_doc(path);
              Json doc = before;
              const int index = resolve_track(doc, a.contains("track") ? a["track"] : Json());
              const Json& tr = doc["tracks"][std::size_t(index)];
              Json removed = Json::object({{"path", tr.value("path", std::string())}, {"component", tr.value("component", std::string("Transform"))},
                                           {"field", tr.value("field", std::string())}, {"keys", tr.contains("keys") ? tr["keys"].size() : 0}});
              doc["tracks"].erase(doc["tracks"].begin() + index);
              return commit(path, doc, before, Json::object({{"removed", removed}}));
          });

    // ------------------------------------------------------------------------------------------------------- events --
    auto event_index = [](const Json& doc, const Json& sel) -> int {
        const Json empty = Json::array();
        const Json& events = doc.contains("events") && doc["events"].is_array() ? doc["events"] : empty;
        auto list = [&] {
            std::string s;
            for (std::size_t i = 0; i < events.size(); ++i) s += (s.empty() ? "" : "; ") + std::format("[{}] t={} {}", i, events[i].value("t", 0.0), events[i].value("name", std::string()));
            return s.empty() ? std::string("The clip has no events (anim.add_event adds one).") : "The clip's events: " + s + ".";
        };
        if (sel.is_number_integer()) {
            const int i = sel.get<int>();
            if (i < 0 || std::size_t(i) >= events.size()) throw CommandError("not_found", std::format("event index {} is out of range.", i), list());
            return i;
        }
        if (!sel.is_object() || !sel.contains("t"))
            throw CommandError("invalid_argument", "`event` must be the index of an event or {t, name?}.", list());
        const double t = need_time(sel["t"], "event.t");
        int found = -1, matches = 0;
        for (std::size_t i = 0; i < events.size(); ++i)
            if (std::fabs(events[i].value("t", -1.0) - t) < kTimeEps && (!sel.contains("name") || events[i].value("name", std::string()) == sel["name"].get<std::string>()))
                { found = int(i); ++matches; }
        if (matches == 0) throw CommandError("not_found", std::format("No event at t={}{}.", t, sel.contains("name") ? " named '" + sel["name"].dump() + "'" : std::string()), list());
        if (matches > 1) throw CommandError("invalid_argument", std::format("{} events are at t={}.", matches, t), "Add `name` to {t, name}, or use the event's index. " + list());
        return found;
    };

    I.commands.add({"anim.add_event", "Add an event to a clip: a game event sent when the clip passes its time.",
           "The event {t, name, data?} reaches world.on(name, fn) and entity.animator.on(name, fn) with {id, clip, time} plus `data` "
           "(an object; the keys id, clip and time are reserved), once per loop. Events stay sorted by t. A time past the duration is "
           "refused unless `extendDuration`. Result: {path, event (index), undo}. Example: anim.add_event "
           "{\"path\":\"anim/hero_walk.anim.json\",\"t\":0.2,\"name\":\"footstep\",\"data\":{\"foot\":\"left\"}}",
           parse_schema(R"({"type":"object","required":["path","t","name"],"properties":{
               "path":{"type":"string","description":"The clip file (.anim.json)."},
               "t":{"type":"number","minimum":0,"description":"Seconds from the start of the clip."},
               "name":{"type":"string","minLength":1,"description":"The game event name."},
               "data":{"type":"object","description":"Extra fields sent with the event."},
               "extendDuration":{"type":"boolean","default":false}}})"),
           false, "anim"},
          [](const Json& a) {
              const std::string path = need_clip_path(a);
              Json before = read_doc(path);
              Json doc = before;
              const double t = round_time(need_time(a.contains("t") ? a["t"] : Json(), "t"));
              fit_duration(doc, t, a.value("extendDuration", false), "An event");
              Json ev = Json::object({{"t", t}, {"name", a.contains("name") ? a["name"] : Json()}});
              if (a.contains("data")) ev["data"] = a["data"];
              if (!doc.contains("events") || !doc["events"].is_array()) doc["events"] = Json::array();
              doc["events"].push_back(ev);
              Json out = commit(path, doc, before);
              // The index after sorting: the last event at t (events at one time keep the order they were added in).
              auto after = read_doc(path);
              int index = 0;
              for (std::size_t i = 0; i < after["events"].size(); ++i)
                  if (std::fabs(after["events"][i].value("t", -1.0) - t) < kTimeEps) index = int(i);
              out["event"] = index;
              return out;
          });

    I.commands.add({"anim.move_event", "Move an event of a clip to another time.",
           "`event` is the event's index in the clip's events, or {t, name?} (name needed when two events share the time). Events stay "
           "sorted, so the index in the result is the new one. Result: {path, event, from, to, undo}. Example: anim.move_event "
           "{\"path\":\"anim/hero_walk.anim.json\",\"event\":{\"t\":0.2,\"name\":\"footstep\"},\"to\":0.25}",
           parse_schema(R"({"type":"object","required":["path","event","to"],"properties":{
               "path":{"type":"string","description":"The clip file (.anim.json)."},
               "event":{"description":"Index of the event, or {t, name?}."},
               "to":{"type":"number","minimum":0,"description":"The new time in seconds."},
               "extendDuration":{"type":"boolean","default":false}}})"),
           false, "anim"},
          [event_index](const Json& a) {
              const std::string path = need_clip_path(a);
              Json before = read_doc(path);
              Json doc = before;
              const int at = event_index(doc, a.contains("event") ? a["event"] : Json());
              const double from = doc["events"][std::size_t(at)].value("t", 0.0);
              const double to = round_time(need_time(a.contains("to") ? a["to"] : Json(), "to"));
              fit_duration(doc, to, a.value("extendDuration", false), "An event");
              doc["events"][std::size_t(at)]["t"] = to;
              Json out = commit(path, doc, before, Json::object({{"from", from}, {"to", to}}));
              auto after = read_doc(path);
              int index = 0;
              for (std::size_t i = 0; i < after["events"].size(); ++i)
                  if (std::fabs(after["events"][i].value("t", -1.0) - to) < kTimeEps && after["events"][i].value("name", std::string()) == before["events"][std::size_t(at)].value("name", std::string())) index = int(i);
              out["event"] = index;
              return out;
          });

    I.commands.add({"anim.set_event", "Rename an event of a clip or replace its data.",
           "`event` is the event's index, or {t, name?}. Give `name` and/or `data` (an object that REPLACES the event's data; {} clears it). "
           "Result: {path, event, undo}. Example: anim.set_event {\"path\":\"anim/hero_walk.anim.json\",\"event\":0,\"name\":\"step\",\"data\":{\"foot\":\"right\"}}",
           parse_schema(R"({"type":"object","required":["path","event"],"properties":{
               "path":{"type":"string","description":"The clip file (.anim.json)."},
               "event":{"description":"Index of the event, or {t, name?}."},
               "name":{"type":"string","minLength":1,"description":"The new event name."},
               "data":{"type":"object","description":"The new data object."}}})"),
           false, "anim"},
          [event_index](const Json& a) {
              const std::string path = need_clip_path(a);
              Json before = read_doc(path);
              Json doc = before;
              if (!a.contains("name") && !a.contains("data")) throw CommandError("invalid_argument", "Nothing to change.", "Pass `name` and/or `data`.");
              const int at = event_index(doc, a.contains("event") ? a["event"] : Json());
              Json& ev = doc["events"][std::size_t(at)];
              if (a.contains("name")) ev["name"] = a["name"];
              if (a.contains("data")) { if (a["data"].empty()) ev.erase("data"); else ev["data"] = a["data"]; }
              return commit(path, doc, before, Json::object({{"event", at}}));
          });

    I.commands.add({"anim.remove_event", "Remove an event from a clip.",
           "`event` is the event's index, or {t, name?}. Result: {path, removed: {t, name, data?}, undo}. Example: anim.remove_event "
           "{\"path\":\"anim/hero_walk.anim.json\",\"event\":{\"t\":0.2,\"name\":\"footstep\"}}",
           parse_schema(R"({"type":"object","required":["path","event"],"properties":{
               "path":{"type":"string","description":"The clip file (.anim.json)."},
               "event":{"description":"Index of the event, or {t, name?}."}}})"),
           false, "anim"},
          [event_index](const Json& a) {
              const std::string path = need_clip_path(a);
              Json before = read_doc(path);
              Json doc = before;
              const int at = event_index(doc, a.contains("event") ? a["event"] : Json());
              Json removed = doc["events"][std::size_t(at)];
              doc["events"].erase(doc["events"].begin() + at);
              return commit(path, doc, before, Json::object({{"removed", removed}}));
          });

    I.commands.add({"anim.set_clip", "Set the duration, loop or description of a clip.",
           "Give any of `duration` (seconds), `loop` and `doc`. A duration shorter than the last key or event is refused, naming the "
           "key (move it with anim.move_keys first). Result: {path, duration, loop, undo}. Example: anim.set_clip "
           "{\"path\":\"anim/hero_walk.anim.json\",\"duration\":1.2,\"loop\":false}",
           parse_schema(R"({"type":"object","required":["path"],"properties":{
               "path":{"type":"string","description":"The clip file (.anim.json)."},
               "duration":{"type":"number","minimum":0,"description":"Length of the clip in seconds."},
               "loop":{"type":"boolean","description":"true repeats the clip, false stops on the last pose."},
               "doc":{"type":"string","description":"What the clip shows."}}})"),
           false, "anim"},
          [](const Json& a) {
              const std::string path = need_clip_path(a);
              Json before = read_doc(path);
              Json doc = before;
              if (!a.contains("duration") && !a.contains("loop") && !a.contains("doc"))
                  throw CommandError("invalid_argument", "Nothing to change.", "Pass `duration`, `loop` and/or `doc`.");
              if (a.contains("duration")) doc["duration"] = round_time(need_time(a["duration"], "duration"));
              if (a.contains("loop")) {
                  if (!a["loop"].is_boolean()) throw CommandError("invalid_argument", "loop must be true or false.", "true repeats the clip, false stops on its last pose.");
                  doc["loop"] = a["loop"];
              }
              if (a.contains("doc")) doc["doc"] = a["doc"];
              return commit(path, doc, before);
          });

    I.commands.add({"anim.restore", "Put a clip file back to a whole document, or delete it: the undo and redo of the anim.* edits.",
           "Every editing command returns `undo` = {command: \"anim.restore\", args: {path, clip}}; calling it writes `clip` (the whole "
           "previous document, checked like any clip) or, when `clip` is null, deletes the file (the undo of anim.create_clip). Its own "
           "result carries the `undo` that goes forward again (redo). Example: anim.restore {\"path\":\"anim/hero_walk.anim.json\",\"clip\":null}",
           parse_schema(R"({"type":"object","required":["path","clip"],"properties":{
               "path":{"type":"string","description":"The clip file (.anim.json)."},
               "clip":{"type":["object","null"],"description":"The whole clip document to write, or null to delete the file."}}})"),
           false, "anim"},
          [](const Json& a) {
              const std::string path = need_clip_path(a);
              if (!a.contains("clip")) throw CommandError("invalid_argument", "Missing `clip`.", "Pass the document to write, or null to delete the file.");
              Json before = nullptr;
              if (fs::exists(path)) {
                  auto text = fs::read_text(path);
                  auto parsed = text.ok() ? parse_json(*text, path) : Result<Json>(text.error());
                  before = parsed.ok() ? *parsed : Json(nullptr);
              }
              if (a["clip"].is_null()) {
                  if (!fs::exists(path)) throw CommandError("not_found", "'" + path + "' does not exist, so there is nothing to delete.", "Nothing to undo here.");
                  std::error_code ec;
                  std::filesystem::remove(fs::resolve(path), ec);
                  if (ec) throw CommandError("failed", path + ": " + ec.message(), "Check that the file is not open elsewhere.");
                  clear_anim_clip_cache();
                  return Json::object({{"path", path}, {"deleted", true}, {"undo", undo_of(path, before)}});
              }
              return commit(path, a["clip"], before);
          });

    register_anim_view_commands(engine, I);
}

}  // namespace fa
