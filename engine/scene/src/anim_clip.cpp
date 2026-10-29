#include "fa/scene/anim_clip.h"

#include <algorithm>
#include <cmath>
#include <format>
#include <map>
#include <mutex>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/scene/world.h"

namespace fa {

// ================================================================================================= easings ======

namespace {

double bounce_out(double t) {
    const double n1 = 7.5625, d1 = 2.75;
    if (t < 1 / d1) return n1 * t * t;
    if (t < 2 / d1) { t -= 1.5 / d1; return n1 * t * t + 0.75; }
    if (t < 2.5 / d1) { t -= 2.25 / d1; return n1 * t * t + 0.9375; }
    t -= 2.625 / d1;
    return n1 * t * t + 0.984375;
}

constexpr const char* kFamilies[] = {"quad", "cubic", "quart", "quint", "sine", "expo", "circ", "back", "elastic", "bounce"};
constexpr int kFamilyCount = 10;

// The "In" curve of family `f`: the definitions of EASE_IN in factoria.js.
double ease_in(int f, double t) {
    switch (f) {
        case 0: return t * t;
        case 1: return t * t * t;
        case 2: return t * t * t * t;
        case 3: return t * t * t * t * t;
        case 4: return 1 - std::cos(t * 3.14159265358979323846 / 2);
        case 5: return t == 0 ? 0 : std::pow(2.0, 10 * t - 10);
        case 6: return 1 - std::sqrt(1 - t * t);
        case 7: { const double c1 = 1.70158; return (c1 + 1) * t * t * t - c1 * t * t; }
        case 8:
            return t == 0 ? 0 : t == 1 ? 1 : -std::pow(2.0, 10 * t - 10) * std::sin((t * 10 - 10.75) * (2 * 3.14159265358979323846 / 3));
        default: return 1 - bounce_out(1 - t);
    }
}

}  // namespace

const std::vector<std::string>& clip_ease_names() {
    static const std::vector<std::string> names = [] {
        std::vector<std::string> n{"linear"};
        for (int f = 0; f < kFamilyCount; ++f)
            for (const char* suffix : {"In", "Out", "InOut"}) n.push_back(std::string(kFamilies[f]) + suffix);
        return n;
    }();
    return names;
}

float clip_ease(int index, float tf) {
    if (index <= 0) return tf;
    const int f = (index - 1) / 3, kind = (index - 1) % 3;
    if (f >= kFamilyCount) return tf;
    const double t = tf;
    switch (kind) {
        case 0: return float(ease_in(f, t));
        case 1: return float(1 - ease_in(f, 1 - t));
        default: return float(t < 0.5 ? ease_in(f, 2 * t) / 2 : 1 - ease_in(f, 2 - 2 * t) / 2);
    }
}

// ================================================================================================== parsing ======

namespace {

struct Parser {
    std::string file;
    std::vector<ClipIssue> issues;

    void err(std::string pointer, std::string message, std::string hint = {}) {
        issues.push_back({std::move(pointer), std::move(message), std::move(hint)});
    }
    // Keys of `obj` that are not in `allowed` are errors with "did you mean".
    void unknown_keys(const Json& obj, const std::string& pointer, const std::vector<std::string>& allowed) {
        for (auto it = obj.begin(); it != obj.end(); ++it) {
            if (std::find(allowed.begin(), allowed.end(), it.key()) != allowed.end()) continue;
            err(pointer + "/" + it.key(), "unknown key '" + it.key() + "'", did_you_mean(it.key(), allowed));
        }
    }
};

const char* kInterpHelp = "linear, step, bezier, or an easing of tween() such as quadOut or backInOut";

bool angle_field(const std::string& component, const std::string& field, FieldKind kind) {
    if (component == "Transform" && field == "rotation") return true;
    if (kind == FieldKind::Float && (ends_with(field, "Angle") || field == "angle")) return true;
    return false;
}

const char* channel_letters(FieldKind k) { return k == FieldKind::Color ? "rgba" : "xyzw"; }
int kind_channels(FieldKind k) {
    switch (k) {
        case FieldKind::Float: return 1;
        case FieldKind::Vec2: return 2;
        case FieldKind::Vec3: return 3;
        case FieldKind::Vec4: case FieldKind::Color: return 4;
        default: return 0;
    }
}
bool animatable(FieldKind k) {
    switch (k) {
        case FieldKind::Bool: case FieldKind::Int: case FieldKind::Float: case FieldKind::Vec2: case FieldKind::Vec3:
        case FieldKind::Vec4: case FieldKind::Color: case FieldKind::Rect: case FieldKind::Enum: case FieldKind::Asset:
            return true;
        default: return false;
    }
}
}  // namespace

bool clip_field_animatable(const FieldInfo& f) { return animatable(f.kind) && f.serialized && !f.readOnly; }

namespace {

std::vector<std::string> animatable_fields(const TypeInfo& t) {
    std::vector<std::string> out;
    for (const FieldInfo& f : t.fields)
        if (animatable(f.kind) && f.serialized && !f.readOnly) out.push_back(f.name);
    return out;
}

bool read_number(const Json& j, float& out) {
    if (!j.is_number()) return false;
    out = j.get<float>();
    return std::isfinite(out);
}

// `n` numbers: a number for n == 1, else an array of n numbers.
bool read_floats(const Json& j, int n, std::array<float, 4>& out, std::string* why) {
    if (n == 1) {
        if (read_number(j, out[0])) return true;
        *why = "expected a number, got " + describe_json_value(j);
        return false;
    }
    if (!j.is_array() || int(j.size()) != n) {
        *why = std::format("expected an array of {} numbers, got {}", n, describe_json_value(j));
        return false;
    }
    for (int i = 0; i < n; ++i)
        if (!read_number(j[std::size_t(i)], out[std::size_t(i)])) {
            *why = std::format("element {} is {}, expected a number", i, describe_json_value(j[std::size_t(i)]));
            return false;
        }
    return true;
}

// The value of a key of an interpolating field.
bool read_value(const ClipTrack& tr, const Json& j, std::array<float, 4>& out, std::string* why) {
    if (tr.channel >= 0 || tr.info->kind == FieldKind::Float) return read_floats(j, 1, out, why);
    std::string err;
    switch (tr.info->kind) {
        case FieldKind::Vec2: { Vec2 v; if (json_to(j, v, &err)) { out = {v.x, v.y, 0, 0}; return true; } break; }
        case FieldKind::Vec3: { Vec3 v; if (json_to(j, v, &err)) { out = {v.x, v.y, v.z, 0}; return true; } break; }
        case FieldKind::Vec4: { Vec4 v; if (json_to(j, v, &err)) { out = {v.x, v.y, v.z, v.w}; return true; } break; }
        case FieldKind::Color: { Color v; if (json_to(j, v, &err)) { out = {v.r, v.g, v.b, v.a}; return true; } break; }
        default: break;
    }
    *why = err;
    return false;
}

void split_path(const std::string& path, std::vector<std::string>& out, bool* bad) {
    out.clear();
    if (path.empty()) return;
    std::size_t start = 0;
    while (true) {
        const std::size_t at = path.find('/', start);
        const std::string seg = path.substr(start, at == std::string::npos ? std::string::npos : at - start);
        if (seg.empty()) *bad = true;
        out.push_back(seg);
        if (at == std::string::npos) break;
        start = at + 1;
    }
}

void parse_track(Parser& p, const Json& j, const std::string& ptr, float duration, ClipAsset& clip) {
    if (!j.is_object()) {
        p.err(ptr, "a track is an object, got " + describe_json_value(j),
              "Write {\"path\": \"body/arm\", \"component\": \"Transform\", \"field\": \"rotation.z\", \"keys\": [{\"t\": 0, \"value\": 0}]}.");
        return;
    }
    p.unknown_keys(j, ptr, {"path", "component", "field", "keys"});
    ClipTrack tr;
    bool ok = true;

    // ---- path
    if (auto it = j.find("path"); it != j.end() && !it->is_string()) {
        p.err(ptr + "/path", "path must be a string, got " + describe_json_value(*it),
              "Names of the entities from the one that plays the clip down, joined with '/': \"body/arm_l/hand\", or \"\" for the entity itself.");
        ok = false;
    } else if (it != j.end()) {
        tr.path = it->get<std::string>();
    }
    bool badPath = false;
    std::vector<std::string> segments;
    split_path(tr.path, segments, &badPath);
    if (badPath) {
        p.err(ptr + "/path", "path '" + tr.path + "' has an empty name (a leading, trailing or doubled '/')",
              "Join the names with a single '/': \"body/arm_l/hand\".");
        ok = false;
    }

    // ---- component and field
    tr.component = "Transform";
    if (auto it = j.find("component"); it != j.end()) {
        if (!it->is_string()) {
            p.err(ptr + "/component", "component must be a string, got " + describe_json_value(*it), "Write the component name: \"Transform\", \"Sprite\".");
            ok = false;
        } else {
            tr.component = it->get<std::string>();
        }
    }
    const TypeRegistry& reg = TypeRegistry::global();
    if (ok) {
        tr.type = reg.find(tr.component);
        if (!tr.type) {
            const std::string s = reg.suggest(tr.component);
            p.err(ptr + "/component", "unknown component '" + tr.component + "'",
                  s.empty() ? "Component names are PascalCase: Transform, Sprite, Shape2D..." : "Did you mean '" + s + "'?");
            ok = false;
        } else if (tr.type->name == "EntityInfo") {
            p.err(ptr + "/component", "EntityInfo cannot be animated (id, name, tags and active belong to the entity itself)",
                  "To hide a part animate Sprite.color.a, or its Transform.scale.");
            ok = false;
        }
    }
    auto fit = j.find("field");
    if (fit == j.end() || !fit->is_string() || fit->get<std::string>().empty()) {
        p.err(ptr + "/field", fit == j.end() ? "a track needs a field" : "field must be a non-empty string, got " + describe_json_value(*fit),
              "Write the field of the component, with a channel for one component of a vector: \"position\", \"rotation.z\", \"color.a\".");
        ok = false;
    } else {
        tr.spelled = fit->get<std::string>();
    }
    if (ok) {
        std::string name = tr.spelled, sub;
        if (const std::size_t dot = name.find('.'); dot != std::string::npos) {
            sub = name.substr(dot + 1);
            name = name.substr(0, dot);
        }
        tr.field = name;
        tr.info = tr.type->field(name);
        if (!tr.info) {
            const std::vector<std::string> names = animatable_fields(*tr.type);
            p.err(ptr + "/field", std::format("{} has no field '{}'", tr.component, name),
                  names.empty() ? tr.component + " has no field a clip can animate." : did_you_mean(name, names));
            ok = false;
        } else if (!animatable(tr.info->kind) || !tr.info->serialized || tr.info->readOnly) {
            const std::vector<std::string> names = animatable_fields(*tr.type);
            std::string why = tr.info->readOnly ? "it is read-only"
                              : !tr.info->serialized ? "it is runtime state, not part of the scene"
                                                     : std::string("a ") + field_kind_name(tr.info->kind) + " cannot be interpolated or switched by a clip";
            p.err(ptr + "/field", std::format("{}.{} cannot be animated: {}", tr.component, name, why),
                  names.empty() ? std::string("This component has no animatable field.")
                                : "Animatable fields of " + tr.component + ": " + join(names, ", ") + ".");
            ok = false;
        } else {
            const FieldKind kind = tr.info->kind;
            tr.stepped = kind == FieldKind::Bool || kind == FieldKind::Int || kind == FieldKind::Enum || kind == FieldKind::Asset ||
                         kind == FieldKind::Rect;
            tr.channels = tr.stepped ? 0 : kind_channels(kind);
            if (!sub.empty()) {
                const int n = kind_channels(kind);
                const char* letters = channel_letters(kind);
                if (tr.stepped || n <= 1) {
                    p.err(ptr + "/field", std::format("{}.{} is {} and has no components, so '.{}' does not apply", tr.component, name,
                                                      field_kind_name(kind), sub),
                          "Write the field alone: \"" + name + "\".");
                    ok = false;
                } else {
                    int ch = -1;
                    for (int i = 0; i < n && sub.size() == 1; ++i)
                        if (sub[0] == letters[i]) ch = i;
                    if (ch < 0) {
                        p.err(ptr + "/field", std::format("'{}' is not a component of {}.{}", sub, tr.component, name),
                              std::string("The components of a ") + field_kind_name(kind) + " are " + std::string(letters, std::size_t(n)) + ": \"" + name + "." + letters[0] + "\".");
                        ok = false;
                    } else {
                        tr.channel = ch;
                        tr.channels = 1;
                    }
                }
            }
            tr.angle = !tr.stepped && angle_field(tr.component, name, kind);
        }
    }

    // ---- keys
    auto kit = j.find("keys");
    if (kit == j.end() || !kit->is_array() || kit->empty()) {
        p.err(ptr + "/keys", kit == j.end() ? "a track needs `keys`" : kit->is_array() ? "a track needs at least one key" : "keys must be an array, got " + describe_json_value(*kit),
              "Write [{\"t\": 0, \"value\": 0}, {\"t\": 1, \"value\": 90}]: t in seconds, value of the field's type.");
        ok = false;
    }
    if (!ok) return;

    std::vector<bool> hasIn, hasOut;
    for (std::size_t k = 0; k < kit->size(); ++k) {
        const Json& kj = (*kit)[k];
        const std::string kp = ptr + "/keys/" + std::to_string(k);
        if (!kj.is_object()) {
            p.err(kp, "a key is an object, got " + describe_json_value(kj), "Write {\"t\": 0.5, \"value\": 10, \"interp\": \"linear\"}.");
            continue;
        }
        p.unknown_keys(kj, kp, {"t", "value", "interp", "in", "out"});
        ClipKey key;
        bool keyOk = true;
        float t = 0;
        if (auto it = kj.find("t"); it == kj.end() || !read_number(*it, t)) {
            p.err(kp + "/t", it == kj.end() ? "a key needs `t`" : "t must be a number of seconds, got " + describe_json_value(*it), "Write t in seconds from the start of the clip: 0.25.");
            keyOk = false;
        } else if (t < 0) {
            p.err(kp + "/t", std::format("t is {}: a key cannot be before the start of the clip", t), "Keys are at 0 or later.");
            keyOk = false;
        } else if (t > duration + 1e-6f) {
            p.err(kp + "/t", std::format("t is {}, past the clip's duration {}", t, duration),
                  std::format("Raise `duration` to at least {} or move the key earlier.", t));
            keyOk = false;
        } else if (!tr.keys.empty() && t <= tr.keys.back().t) {
            p.err(kp + "/t", std::format("t is {}, not after the previous key (t {}): keys must be in ascending order of t", t, tr.keys.back().t),
                  "Sort the keys by t, one key per time; to jump to another value use two keys a frame apart or interp \"step\".");
            keyOk = false;
        }
        key.t = t;

        if (auto it = kj.find("value"); it == kj.end()) {
            p.err(kp + "/value", "a key needs `value`", "The value has the type of " + tr.component + "." + tr.spelled + " (" + field_kind_name(tr.info->kind) + ").");
            keyOk = false;
        } else if (tr.stepped) {
            DefaultObject def(*tr.type);
            if (tr.info->kind == FieldKind::Int && !it->is_number_integer()) {
                p.err(kp + "/value", "value must be an integer for " + tr.component + "." + tr.field + ", got " + describe_json_value(*it), {});
                keyOk = false;
            } else if (auto r = field_from_json(*tr.info, def.get(), *it); !r) {
                p.err(kp + "/value", r.error().message, r.error().hint);
                keyOk = false;
            } else {
                key.raw = *it;
            }
        } else {
            std::string why;
            if (!read_value(tr, *it, key.value, &why)) {
                p.err(kp + "/value", "value " + why + " for " + tr.component + "." + tr.spelled + " (" +
                                         (tr.channel >= 0 ? "number" : field_kind_name(tr.info->kind)) + ")",
                      tr.channel >= 0 || tr.info->kind == FieldKind::Float ? "Write a number: 0.5."
                      : tr.info->kind == FieldKind::Color ? "Write [r, g, b, a] (0..1), \"#rrggbb\" or a colour name."
                                                          : "Write an array of numbers, one per component.");
                keyOk = false;
            }
        }

        if (auto it = kj.find("interp"); it != kj.end()) {
            std::string name = it->is_string() ? it->get<std::string>() : std::string();
            if (name == "linear") key.interp = ClipInterp::Linear;
            else if (name == "step") key.interp = ClipInterp::Step;
            else if (name == "bezier") key.interp = ClipInterp::Bezier;
            else if (auto pos = std::find(clip_ease_names().begin(), clip_ease_names().end(), name); pos != clip_ease_names().end()) {
                key.interp = ClipInterp::Ease;
                key.ease = int(pos - clip_ease_names().begin());
            } else {
                std::vector<std::string> all{"linear", "step", "bezier"};
                all.insert(all.end(), clip_ease_names().begin() + 1, clip_ease_names().end());
                p.err(kp + "/interp", it->is_string() ? "unknown interp '" + name + "'" : "interp must be a string, got " + describe_json_value(*it),
                      (it->is_string() ? did_you_mean(name, all, 6) + " " : std::string()) + "Valid: " + kInterpHelp + ".");
                keyOk = false;
            }
        }
        bool in = false, out = false;
        for (const char* tan : {"in", "out"}) {
            auto it = kj.find(tan);
            if (it == kj.end()) continue;
            std::array<float, 4>& dst = tan[0] == 'i' ? key.inTan : key.outTan;
            std::string why;
            if (tr.stepped) {
                p.err(kp + "/" + tan, std::string("tangents do not apply: ") + tr.component + "." + tr.field + " only steps", "Leave `in` and `out` out.");
                keyOk = false;
            } else if (!read_floats(*it, tr.channels, dst, &why)) {
                p.err(kp + "/" + tan, std::string("tangent ") + why, "A tangent is the slope of the curve in field units per second, shaped like the value.");
                keyOk = false;
            } else {
                (tan[0] == 'i' ? in : out) = true;
            }
        }
        if (!keyOk) { ok = false; continue; }
        tr.keys.push_back(std::move(key));
        hasIn.push_back(in);
        hasOut.push_back(out);
    }
    if (!ok || tr.keys.empty()) return;

    // Bezier keys without tangents get a smooth curve through their neighbours (zero slope at the ends of the track).
    if (!tr.stepped) {
        for (std::size_t i = 0; i < tr.keys.size(); ++i) {
            if (hasIn[i] && hasOut[i]) continue;
            std::array<float, 4> slope{};
            if (i > 0 && i + 1 < tr.keys.size()) {
                const float dt = tr.keys[i + 1].t - tr.keys[i - 1].t;
                for (std::size_t c = 0; c < 4; ++c) slope[c] = dt > 1e-9f ? (tr.keys[i + 1].value[c] - tr.keys[i - 1].value[c]) / dt : 0.0f;
            }
            if (!hasIn[i]) tr.keys[i].inTan = slope;
            if (!hasOut[i]) tr.keys[i].outTan = slope;
        }
    }

    // Two tracks on the same channel would fight: the later one silently winning hides a mistake.
    for (const ClipTrack& o : clip.tracks) {
        if (o.path != tr.path || o.component != tr.component || o.field != tr.field) continue;
        if (o.channel >= 0 && tr.channel >= 0 && o.channel != tr.channel) continue;
        p.err(ptr + "/field", std::format("{}.{} on {} is already driven by an earlier track ({})", tr.component, tr.spelled,
                                  tr.path.empty() ? std::string("the entity itself") : "'" + tr.path + "'", o.spelled),
              "Put all keys of a channel in ONE track, or drive different channels (\"rotation.z\" and \"rotation.x\") in separate tracks.");
        return;
    }

    // The path joins the table of distinct paths.
    auto found = std::find(clip.paths.begin(), clip.paths.end(), tr.path);
    tr.pathIndex = int(found - clip.paths.begin());
    if (found == clip.paths.end()) {
        clip.paths.push_back(tr.path);
        clip.segments.push_back(segments);
    }
    clip.tracks.push_back(std::move(tr));
}

}  // namespace

Result<std::shared_ptr<const ClipAsset>> parse_anim_clip(const Json& json, std::string_view fileView, std::vector<ClipIssue>* issuesOut) {
    Parser p;
    p.file = std::string(fileView);
    auto clip = std::make_shared<ClipAsset>();
    clip->path = p.file;

    auto fail = [&]() -> Result<std::shared_ptr<const ClipAsset>> {
        if (issuesOut) *issuesOut = p.issues;
        const ClipIssue& first = p.issues.front();
        std::string msg = (p.file.empty() ? "<anim clip>" : p.file) + " " + (first.pointer.empty() ? "/" : first.pointer) + ": " + first.message;
        if (p.issues.size() > 1) msg += std::format(" (and {} more problem{})", p.issues.size() - 1, p.issues.size() == 2 ? "" : "s");
        return make_error(msg, first.hint);
    };

    if (!json.is_object()) {
        p.err("", "a clip file must be a JSON object, got " + describe_json_value(json),
              "Start from {\"format\": \"factoria.anim/1\", \"duration\": 1, \"loop\": true, \"tracks\": []} (schemas/anim.schema.json).");
        return fail();
    }
    p.unknown_keys(json, "", {"$schema", "format", "doc", "duration", "loop", "tracks", "events"});
    if (auto it = json.find("format"); it == json.end() || !it->is_string() || it->get<std::string>() != "factoria.anim/1")
        p.err("/format", it == json.end() ? "missing `format`" : "format is " + describe_json_value(*it) + ", expected \"factoria.anim/1\"",
              "Add \"format\": \"factoria.anim/1\" at the top of the file.");
    if (auto it = json.find("doc"); it != json.end() && it->is_string()) clip->doc = it->get<std::string>();
    float duration = 0;
    bool durationOk = true;
    if (auto it = json.find("duration"); it == json.end() || !read_number(*it, duration) || duration < 0) {
        p.err("/duration", it == json.end() ? "missing `duration`" : "duration must be a number of seconds, 0 or more, got " + describe_json_value(*it),
              "Add \"duration\": 1.2, the length of the clip in seconds (the time of its last key or later).");
        durationOk = false;
    }
    clip->duration = duration;
    if (auto it = json.find("loop"); it != json.end()) {
        if (!it->is_boolean()) p.err("/loop", "loop must be true or false, got " + describe_json_value(*it), "true repeats the clip, false stops on its last pose.");
        else clip->loop = it->get<bool>();
    }

    auto tit = json.find("tracks");
    if (tit == json.end() || !tit->is_array()) {
        p.err("/tracks", tit == json.end() ? "missing `tracks`" : "tracks must be an array, got " + describe_json_value(*tit), "Write \"tracks\": [] for a clip with no animated field yet.");
    } else if (durationOk) {
        for (std::size_t i = 0; i < tit->size(); ++i) parse_track(p, (*tit)[i], "/tracks/" + std::to_string(i), duration, *clip);
    }

    if (auto eit = json.find("events"); eit != json.end()) {
        if (!eit->is_array()) {
            p.err("/events", "events must be an array, got " + describe_json_value(*eit), "Write [{\"t\": 0.25, \"name\": \"footstep\"}].");
        } else {
            for (std::size_t i = 0; i < eit->size(); ++i) {
                const Json& ej = (*eit)[i];
                const std::string ep = "/events/" + std::to_string(i);
                if (!ej.is_object()) { p.err(ep, "an event is an object, got " + describe_json_value(ej), "Write {\"t\": 0.25, \"name\": \"footstep\", \"data\": {}}."); continue; }
                p.unknown_keys(ej, ep, {"t", "name", "data"});
                ClipEvent ev;
                bool evOk = true;
                if (auto it = ej.find("t"); it == ej.end() || !read_number(*it, ev.t)) {
                    p.err(ep + "/t", it == ej.end() ? "an event needs `t`" : "t must be a number of seconds, got " + describe_json_value(*it), "Write t in seconds from the start of the clip.");
                    evOk = false;
                } else if (ev.t < 0 || (durationOk && ev.t > duration + 1e-6f)) {
                    p.err(ep + "/t", std::format("t is {}, outside the clip (0 to {})", ev.t, duration), std::format("Move the event inside the clip, or raise `duration`."));
                    evOk = false;
                }
                if (auto it = ej.find("name"); it == ej.end() || !it->is_string() || it->get<std::string>().empty()) {
                    p.err(ep + "/name", it == ej.end() ? "an event needs `name`" : "name must be a non-empty string, got " + describe_json_value(*it),
                          "The name is the game event world.on(name, fn) listens to.");
                    evOk = false;
                } else {
                    ev.name = it->get<std::string>();
                }
                if (auto it = ej.find("data"); it != ej.end()) {
                    if (!it->is_object()) {
                        p.err(ep + "/data", "data must be an object, got " + describe_json_value(*it), "Write {\"foot\": \"left\"}.");
                        evOk = false;
                    } else {
                        for (const char* reserved : {"id", "clip", "time"})
                            if (it->contains(reserved)) {
                                p.err(ep + "/data/" + reserved, std::string("data cannot use the key '") + reserved + "': the engine sends {id, clip, time} with every clip event",
                                      "Rename the key.");
                                evOk = false;
                            }
                        ev.data = *it;
                    }
                }
                if (evOk) clip->events.push_back(std::move(ev));
            }
            std::stable_sort(clip->events.begin(), clip->events.end(), [](const ClipEvent& a, const ClipEvent& b) { return a.t < b.t; });
        }
    }

    if (!p.issues.empty()) return fail();
    if (issuesOut) issuesOut->clear();
    return std::shared_ptr<const ClipAsset>(std::move(clip));
}

// =================================================================================================== loading ======

namespace {
std::mutex g_clipMutex;
struct ClipCacheEntry {
    std::int64_t mtime = -1;
    std::int64_t size = -1;
    std::shared_ptr<const ClipAsset> asset;
};
std::map<std::string, ClipCacheEntry>& clip_cache() {
    static std::map<std::string, ClipCacheEntry> c;
    return c;
}
}  // namespace

void clear_anim_clip_cache() {
    std::lock_guard lock(g_clipMutex);
    clip_cache().clear();
}

Result<std::shared_ptr<const ClipAsset>> load_anim_clip(std::string_view pathView, std::vector<ClipIssue>* issues) {
    const std::string path(pathView);
    const std::int64_t mtime = fs::modified_time(path);
    const std::int64_t size = fs::file_size(path);
    {
        std::lock_guard lock(g_clipMutex);
        auto it = clip_cache().find(path);
        if (it != clip_cache().end() && it->second.mtime == mtime && it->second.size == size) return it->second.asset;
    }
    auto text = fs::read_text(path);
    if (!text) return make_error(path + ": cannot read the clip: " + text.error().message,
                                 text.error().hint.empty() ? "Clips are *.anim.json files; check the path in Animator.clips." : text.error().hint);
    auto json = parse_json(*text, path);
    if (!json) return json.error();
    auto parsed = parse_anim_clip(*json, path, issues);
    if (!parsed) return parsed.error();
    auto asset = std::make_shared<ClipAsset>(**parsed);
    asset->mtime = mtime;
    std::shared_ptr<const ClipAsset> shared = asset;
    std::lock_guard lock(g_clipMutex);
    clip_cache()[path] = ClipCacheEntry{mtime, size, shared};
    return shared;
}

// ============================================================================================== path lookup ======

Result<Entity> resolve_clip_path(const World& world, Entity root, std::string_view path) {
    if (!world.alive(root)) return make_error("the entity that plays the clip does not exist");
    Entity cur = root;
    std::string walked;
    std::vector<std::string> segs;
    if (!path.empty()) segs = split(path, '/', false);
    for (const std::string& seg : segs) {
        Entity next = kNullEntity;
        std::vector<std::string> names;
        for (Entity c : world.children(cur)) {
            names.push_back(world.info(c).name);
            if (next.is_null() && world.info(c).name == seg) next = c;
        }
        if (next.is_null()) {
            std::string where = walked.empty() ? "'" + (world.info(root).name.empty() ? world.info(root).id : world.info(root).name) + "'" : "'" + walked + "'";
            std::string hint;
            if (names.empty()) hint = "The entity " + where + " has no children. Parts are child entities; names are the EntityInfo name (`name`), joined with '/'.";
            else {
                hint = did_you_mean(seg, names);
                // A name that exists deeper in the tree: say where.
                std::vector<Entity> stack{cur};
                while (!stack.empty()) {
                    Entity e = stack.back();
                    stack.pop_back();
                    for (Entity c : world.children(e)) {
                        if (world.info(c).name == seg) {
                            std::string full;
                            for (Entity x = c; x != root && !x.is_null(); x = world.parent(x))
                                full = world.info(x).name + (full.empty() ? "" : "/" + full);
                            hint += " '" + seg + "' exists at '" + full + "'.";
                            stack.clear();
                            break;
                        }
                        stack.push_back(c);
                    }
                }
            }
            return make_error(std::format("no entity named '{}' under {} (path '{}')", seg, where, path), hint);
        }
        walked += (walked.empty() ? "" : "/") + seg;
        cur = next;
    }
    return cur;
}

std::vector<ClipIssue> check_clip_paths(const World& world, Entity root, const ClipAsset& clip) {
    std::vector<ClipIssue> out;
    std::vector<std::string> failed;  // paths already reported, once each
    for (std::size_t i = 0; i < clip.tracks.size(); ++i) {
        const ClipTrack& tr = clip.tracks[i];
        if (std::find(failed.begin(), failed.end(), tr.path) != failed.end()) continue;
        auto r = resolve_clip_path(world, root, tr.path);
        if (r) continue;
        failed.push_back(tr.path);
        out.push_back({"/tracks/" + std::to_string(i) + "/path", r.error().message, r.error().hint});
    }
    return out;
}

// ================================================================================================== sampling ======

void sample_clip_track(const ClipTrack& tr, float time, std::array<float, 4>& out, const Json** raw) {
    const std::vector<ClipKey>& K = tr.keys;
    if (raw) *raw = nullptr;
    std::size_t i = 0;
    bool hold = true;
    if (K.size() > 1 && time > K.front().t) {
        if (time >= K.back().t) {
            i = K.size() - 1;
        } else {
            const auto it = std::upper_bound(K.begin(), K.end(), time, [](float t, const ClipKey& k) { return t < k.t; });
            i = std::size_t(it - K.begin()) - 1;
            hold = false;
        }
    }
    const ClipKey& a = K[i];
    if (tr.stepped) {
        if (raw) *raw = &a.raw;
        return;
    }
    if (hold || a.interp == ClipInterp::Step) { out = a.value; return; }
    const ClipKey& b = K[i + 1];
    const float span = b.t - a.t;
    const float f = span > 1e-9f ? (time - a.t) / span : 1.0f;
    const std::size_t n = std::size_t(tr.channels);
    if (a.interp == ClipInterp::Bezier) {
        const float t2 = f * f, t3 = t2 * f;
        const float h00 = 2 * t3 - 3 * t2 + 1, h10 = t3 - 2 * t2 + f, h01 = -2 * t3 + 3 * t2, h11 = t3 - t2;
        for (std::size_t c = 0; c < n; ++c)
            out[c] = h00 * a.value[c] + h10 * span * a.outTan[c] + h01 * b.value[c] + h11 * span * b.inTan[c];
        return;
    }
    const float u = a.interp == ClipInterp::Ease ? clip_ease(a.ease, f) : f;
    for (std::size_t c = 0; c < n; ++c) out[c] = a.value[c] + (b.value[c] - a.value[c]) * u;
}

}  // namespace fa
