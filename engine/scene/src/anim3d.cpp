#include "fa/scene/anim3d.h"

#include <algorithm>
#include <cmath>
#include <format>
#include <map>
#include <mutex>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/scene/animation.h"

namespace fa {

const char* anim3d_channel_name(Anim3DChannel c) {
    switch (c) {
        case Anim3DChannel::Rotation: return "rotation";
        case Anim3DChannel::Translation: return "translation";
        case Anim3DChannel::Scale: return "scale";
    }
    return "rotation";
}

bool is_anim3d_json(const Json& json) {
    if (!json.is_object()) return false;
    auto it = json.find("format");
    return it != json.end() && it->is_string() && it->get<std::string>() == kAnim3DFormat;
}

// ===================================================================================================== parsing ======

namespace {

struct Parser {
    std::string file;
    std::vector<ClipIssue> issues;
    void err(std::string pointer, std::string message, std::string hint = {}) {
        issues.push_back({std::move(pointer), std::move(message), std::move(hint)});
    }
    void unknown_keys(const Json& obj, const std::string& pointer, const std::vector<std::string>& allowed) {
        for (auto it = obj.begin(); it != obj.end(); ++it) {
            if (std::find(allowed.begin(), allowed.end(), it.key()) != allowed.end()) continue;
            err(pointer + "/" + it.key(), "unknown key '" + it.key() + "'", did_you_mean(it.key(), allowed));
        }
    }
};

bool read_number(const Json& j, float& out) {
    if (!j.is_number()) return false;
    out = j.get<float>();
    return std::isfinite(out);
}

bool read_floats(const Json& j, int n, std::array<float, 4>& out, std::string* why) {
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

const char* kInterpHelp = "linear, step, bezier (not for quaternions), or an easing of tween() such as quadOut or backInOut";

double num(float v) {
    // 7 significant digits: floats print without the noise of their double expansion, and read back to the same float.
    if (!std::isfinite(v)) return 0.0;
    return std::stod(std::format("{:.7g}", v));
}

Json floats_json(const std::array<float, 4>& v, int n) {
    Json a = Json::array();
    for (int i = 0; i < n; ++i) a.push_back(num(v[std::size_t(i)]));
    return a;
}

}  // namespace

Result<std::shared_ptr<const Anim3DClip>> parse_anim3d(const Json& json, std::string_view fileView, std::vector<ClipIssue>* issuesOut) {
    Parser p;
    p.file = std::string(fileView);
    auto clip = std::make_shared<Anim3DClip>();
    clip->path = p.file;
    auto fail = [&]() -> Result<std::shared_ptr<const Anim3DClip>> {
        if (issuesOut) *issuesOut = p.issues;
        const ClipIssue& first = p.issues.front();
        std::string msg = (p.file.empty() ? "<anim3d clip>" : p.file) + " " + (first.pointer.empty() ? "/" : first.pointer) + ": " + first.message;
        if (p.issues.size() > 1) msg += std::format(" (and {} more problem{})", p.issues.size() - 1, p.issues.size() == 2 ? "" : "s");
        return make_error(msg, first.hint);
    };
    if (!json.is_object()) {
        p.err("", "a clip file must be a JSON object, got " + describe_json_value(json),
              "Start from {\"format\": \"factoria.anim3d/1\", \"duration\": 1, \"loop\": true, \"tracks\": []} (schemas/anim3d.schema.json).");
        return fail();
    }
    p.unknown_keys(json, "", {"$schema", "format", "doc", "rig", "template", "duration", "loop", "rotation", "groundSpeed", "tracks",
                              "events", "contacts", "generated"});
    if (auto it = json.find("format"); it == json.end() || !it->is_string() || it->get<std::string>() != kAnim3DFormat)
        p.err("/format", it == json.end() ? "missing `format`" : "format is " + describe_json_value(*it) + ", expected \"factoria.anim3d/1\"",
              "Add \"format\": \"factoria.anim3d/1\" at the top of the file.");
    if (auto it = json.find("doc"); it != json.end() && it->is_string()) clip->doc = it->get<std::string>();
    if (auto it = json.find("rig"); it != json.end()) {
        if (!it->is_string()) p.err("/rig", "rig must be a path, got " + describe_json_value(*it), "Write the rig document or model the clip is for: \"models/hero.rig.json\".");
        else clip->rig = it->get<std::string>();
    }
    if (auto it = json.find("template"); it != json.end()) {
        if (!it->is_string()) p.err("/template", "template must be a string, got " + describe_json_value(*it), "Write a rig template name: humanoid, quadruped, bird, tail, chain or generic.");
        else clip->templateName = it->get<std::string>();
    }
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
    if (auto it = json.find("rotation"); it != json.end()) {
        if (!it->is_string() || (it->get<std::string>() != "euler" && it->get<std::string>() != "quat"))
            p.err("/rotation", "rotation must be \"euler\" or \"quat\", got " + describe_json_value(*it),
                  "\"euler\" (default): rotation keys are [x, y, z] degrees. \"quat\": they are [x, y, z, w].");
        else clip->quat = it->get<std::string>() == "quat";
    }
    if (auto it = json.find("groundSpeed"); it != json.end()) {
        if (!read_number(*it, clip->groundSpeed) || clip->groundSpeed < 0)
            p.err("/groundSpeed", "groundSpeed must be a number, 0 or more, got " + describe_json_value(*it), "Model units per second the ground moves under a planted foot.");
    }
    if (auto it = json.find("generated"); it != json.end()) {
        if (!it->is_object()) p.err("/generated", "generated must be an object, got " + describe_json_value(*it), "It holds the kind and parameters anim3d.generate used.");
        else clip->generated = *it;
    }

    // ---- tracks
    auto tit = json.find("tracks");
    if (tit == json.end() || !tit->is_array()) {
        p.err("/tracks", tit == json.end() ? "missing `tracks`" : "tracks must be an array, got " + describe_json_value(*tit),
              "Write [{\"bone\": \"head\", \"channel\": \"rotation\", \"keys\": [{\"t\": 0, \"value\": [0, 0, 0]}]}].");
    } else {
        for (std::size_t ti = 0; ti < tit->size(); ++ti) {
            const Json& tj = (*tit)[ti];
            const std::string tp = "/tracks/" + std::to_string(ti);
            if (!tj.is_object()) { p.err(tp, "a track is an object, got " + describe_json_value(tj), "Write {\"bone\": \"head\", \"channel\": \"rotation\", \"keys\": [...]}."); continue; }
            p.unknown_keys(tj, tp, {"bone", "channel", "keys"});
            Anim3DTrack tr;
            bool ok = true;
            if (auto it = tj.find("bone"); it == tj.end() || !it->is_string() || it->get<std::string>().empty()) {
                p.err(tp + "/bone", it == tj.end() ? "a track needs `bone`" : "bone must be a bone name, got " + describe_json_value(*it),
                      "Name the bone as the rig does: thigh_l, spine_2, root (rig.info lists them).");
                ok = false;
            } else {
                tr.bone = it->get<std::string>();
            }
            if (auto it = tj.find("channel"); it != tj.end()) {
                const std::string c = it->is_string() ? it->get<std::string>() : std::string();
                if (c == "rotation") tr.channel = Anim3DChannel::Rotation;
                else if (c == "translation") tr.channel = Anim3DChannel::Translation;
                else if (c == "scale") tr.channel = Anim3DChannel::Scale;
                else {
                    p.err(tp + "/channel", "unknown channel " + describe_json_value(*it), did_you_mean(c, std::vector<std::string>{"rotation", "translation", "scale"}) + " Valid: rotation, translation, scale.");
                    ok = false;
                }
            }
            if (ok) {
                for (const Anim3DTrack& o : clip->tracks)
                    if (o.bone == tr.bone && o.channel == tr.channel) {
                        p.err(tp + "/bone", std::format("the {} of '{}' is already driven by an earlier track", anim3d_channel_name(tr.channel), tr.bone),
                              "Two tracks on the same bone and channel would fight: merge their keys into one track.");
                        ok = false;
                        break;
                    }
            }
            const int comps = tr.channel == Anim3DChannel::Rotation && clip->quat ? 4 : 3;
            auto kit = tj.find("keys");
            if (kit == tj.end() || !kit->is_array() || kit->empty()) {
                p.err(tp + "/keys", kit == tj.end() ? "a track needs `keys`" : kit->is_array() ? "a track needs at least one key" : "keys must be an array, got " + describe_json_value(*kit),
                      comps == 4 ? "Write [{\"t\": 0, \"value\": [0, 0, 0, 1]}, {\"t\": 1, \"value\": [0, 0.38, 0, 0.92]}]: t in seconds, value a quaternion."
                                 : "Write [{\"t\": 0, \"value\": [0, 0, 0]}, {\"t\": 1, \"value\": [20, 0, 0]}]: t in seconds, value three numbers.");
                continue;
            }
            std::vector<bool> hasIn, hasOut;
            for (std::size_t k = 0; k < kit->size(); ++k) {
                const Json& kj = (*kit)[k];
                const std::string kp = tp + "/keys/" + std::to_string(k);
                if (!kj.is_object()) { p.err(kp, "a key is an object, got " + describe_json_value(kj), "Write {\"t\": 0.5, \"value\": [10, 0, 0], \"interp\": \"linear\"}."); ok = false; continue; }
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
                } else if (durationOk && t > duration + 1e-6f) {
                    p.err(kp + "/t", std::format("t is {}, past the clip's duration {}", t, duration), std::format("Raise `duration` to at least {} or move the key earlier.", t));
                    keyOk = false;
                } else if (!tr.keys.empty() && t <= tr.keys.back().t) {
                    p.err(kp + "/t", std::format("t is {}, not after the previous key (t {}): keys must be in ascending order of t", t, tr.keys.back().t),
                          "Sort the keys by t, one key per time.");
                    keyOk = false;
                }
                key.t = t;
                if (auto it = kj.find("value"); it == kj.end()) {
                    p.err(kp + "/value", "a key needs `value`", comps == 4 ? "A quaternion [x, y, z, w]." : tr.channel == Anim3DChannel::Rotation ? "Euler degrees [x, y, z]." : "Three numbers [x, y, z].");
                    keyOk = false;
                } else {
                    std::string why;
                    if (!read_floats(*it, comps, key.value, &why)) {
                        p.err(kp + "/value", "value " + why,
                              comps == 4 ? "Write the quaternion as [x, y, z, w] (the clip says rotation: quat)."
                              : tr.channel == Anim3DChannel::Rotation ? "Write euler degrees [x, y, z] (pitch, yaw, roll), or set \"rotation\": \"quat\" on the clip to use quaternions."
                                                                       : "Write three numbers [x, y, z].");
                        keyOk = false;
                    } else if (comps == 4 && key.value[0] * key.value[0] + key.value[1] * key.value[1] + key.value[2] * key.value[2] + key.value[3] * key.value[3] < 1e-8f) {
                        p.err(kp + "/value", "the quaternion is all zeros", "The identity rotation is [0, 0, 0, 1].");
                        keyOk = false;
                    }
                }
                if (auto it = kj.find("interp"); it != kj.end()) {
                    std::string name = it->is_string() ? it->get<std::string>() : std::string();
                    if (name == "linear") key.interp = ClipInterp::Linear;
                    else if (name == "step") key.interp = ClipInterp::Step;
                    else if (name == "bezier") {
                        key.interp = ClipInterp::Bezier;
                        if (comps == 4) {
                            p.err(kp + "/interp", "bezier does not apply to quaternion keys", "Use euler rotation for a bezier curve, or linear / an easing here.");
                            keyOk = false;
                        }
                    } else if (auto pos = std::find(clip_ease_names().begin(), clip_ease_names().end(), name); pos != clip_ease_names().end()) {
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
                    if (comps == 4) {
                        p.err(kp + "/" + tan, "tangents do not apply to quaternion keys", "Leave `in` and `out` out.");
                        keyOk = false;
                    } else if (!read_floats(*it, 3, dst, &why)) {
                        p.err(kp + "/" + tan, "tangent " + why, "A tangent is the slope of the curve in value units per second: three numbers.");
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
            if (!ok || tr.keys.empty()) continue;
            if (comps == 3) {
                for (std::size_t i = 0; i < tr.keys.size(); ++i) {
                    if (hasIn[i] && hasOut[i]) continue;
                    std::array<float, 4> slope{};
                    if (i > 0 && i + 1 < tr.keys.size()) {
                        const float dt = tr.keys[i + 1].t - tr.keys[i - 1].t;
                        for (std::size_t c = 0; c < 3; ++c) slope[c] = dt > 1e-9f ? (tr.keys[i + 1].value[c] - tr.keys[i - 1].value[c]) / dt : 0.0f;
                    }
                    if (!hasIn[i]) tr.keys[i].inTan = slope;
                    if (!hasOut[i]) tr.keys[i].outTan = slope;
                }
            }
            clip->tracks.push_back(std::move(tr));
        }
    }

    // ---- events
    if (auto eit = json.find("events"); eit != json.end()) {
        if (!eit->is_array()) {
            p.err("/events", "events must be an array, got " + describe_json_value(*eit), "Write [{\"t\": 0.25, \"name\": \"footstep\"}].");
        } else {
            for (std::size_t i = 0; i < eit->size(); ++i) {
                const Json& ej = (*eit)[i];
                const std::string ep = "/events/" + std::to_string(i);
                ClipEvent ev;
                if (read_clip_event(ej, ep, duration, durationOk, ev, p.issues)) clip->events.push_back(std::move(ev));
            }
            std::stable_sort(clip->events.begin(), clip->events.end(), [](const ClipEvent& a, const ClipEvent& b) { return a.t < b.t; });
        }
    }

    // ---- contacts
    if (auto cit = json.find("contacts"); cit != json.end()) {
        if (!cit->is_array()) {
            p.err("/contacts", "contacts must be an array, got " + describe_json_value(*cit), "Write [{\"bone\": \"foot_l\", \"from\": 0, \"to\": 0.5}].");
        } else {
            for (std::size_t i = 0; i < cit->size(); ++i) {
                const Json& cj = (*cit)[i];
                const std::string cp = "/contacts/" + std::to_string(i);
                if (!cj.is_object()) { p.err(cp, "a contact is an object, got " + describe_json_value(cj), "Write {\"bone\": \"foot_l\", \"from\": 0, \"to\": 0.5}."); continue; }
                p.unknown_keys(cj, cp, {"bone", "from", "to"});
                Anim3DContact c;
                bool cOk = true;
                if (auto it = cj.find("bone"); it == cj.end() || !it->is_string() || it->get<std::string>().empty()) {
                    p.err(cp + "/bone", "a contact needs the `bone` that rests on the ground", "Write the foot: \"foot_l\".");
                    cOk = false;
                } else {
                    c.bone = it->get<std::string>();
                }
                for (const char* k : {"from", "to"}) {
                    float v = 0;
                    auto it = cj.find(k);
                    float& dst = k[0] == 'f' ? c.from : c.to;
                    if (it == cj.end() || !read_number(*it, v) || v < 0 || (durationOk && v > duration + 1e-6f)) {
                        p.err(cp + "/" + k, std::string("`") + k + "` must be a time inside the clip (0 to " + std::to_string(duration) + "), got " + (it == cj.end() ? "nothing" : describe_json_value(*it)),
                              "Seconds from the start of the clip.");
                        cOk = false;
                    } else {
                        dst = v;
                    }
                }
                if (cOk) clip->contacts.push_back(std::move(c));
            }
        }
    }
    if (!p.issues.empty()) return fail();
    return std::shared_ptr<const Anim3DClip>(clip);
}

Json anim3d_to_json(const Anim3DClip& c) {
    Json j = Json::object();
    j["format"] = kAnim3DFormat;
    if (!c.doc.empty()) j["doc"] = c.doc;
    if (!c.rig.empty()) j["rig"] = c.rig;
    if (!c.templateName.empty()) j["template"] = c.templateName;
    j["duration"] = num(c.duration);
    j["loop"] = c.loop;
    if (c.quat) j["rotation"] = "quat";
    if (c.groundSpeed > 0) j["groundSpeed"] = num(c.groundSpeed);
    Json tracks = Json::array();
    for (const Anim3DTrack& t : c.tracks) {
        const int comps = t.channel == Anim3DChannel::Rotation && c.quat ? 4 : 3;
        Json keys = Json::array();
        for (const ClipKey& k : t.keys) {
            Json kj = Json::object();
            kj["t"] = num(k.t);
            kj["value"] = floats_json(k.value, comps);
            if (k.interp == ClipInterp::Step) kj["interp"] = "step";
            else if (k.interp == ClipInterp::Bezier) {
                kj["interp"] = "bezier";
                kj["in"] = floats_json(k.inTan, 3);
                kj["out"] = floats_json(k.outTan, 3);
            } else if (k.interp == ClipInterp::Ease && k.ease >= 0 && std::size_t(k.ease) < clip_ease_names().size()) {
                kj["interp"] = clip_ease_names()[std::size_t(k.ease)];
            }
            keys.push_back(kj);
        }
        tracks.push_back({{"bone", t.bone}, {"channel", anim3d_channel_name(t.channel)}, {"keys", keys}});
    }
    j["tracks"] = tracks;
    if (!c.events.empty()) {
        Json ev = Json::array();
        for (const ClipEvent& e : c.events) {
            Json o = {{"t", num(e.t)}};
            if (!e.name.empty()) o["name"] = e.name;
            if (e.data.is_object() && !e.data.empty()) o["data"] = e.data;
            if (e.feel.size() == 1) o["feel"] = e.feel.front();
            else if (!e.feel.empty()) o["feel"] = Json(e.feel);
            ev.push_back(o);
        }
        j["events"] = ev;
    }
    if (!c.contacts.empty()) {
        Json cs = Json::array();
        for (const Anim3DContact& k : c.contacts) cs.push_back({{"bone", k.bone}, {"from", num(k.from)}, {"to", num(k.to)}});
        j["contacts"] = cs;
    }
    if (c.generated.is_object()) j["generated"] = c.generated;
    return j;
}

// ===================================================================================================== loading ======

namespace {
struct CacheEntry {
    std::int64_t mtime = -1, size = -1;
    std::shared_ptr<const Anim3DClip> clip;
};
std::mutex g_mutex;
std::map<std::string, CacheEntry>& cache() {
    static std::map<std::string, CacheEntry> c;
    return c;
}
}  // namespace

Result<std::shared_ptr<const Anim3DClip>> load_anim3d(std::string_view pathView, std::vector<ClipIssue>* issues) {
    const std::string path(pathView);
    const std::int64_t mtime = fs::modified_time(path), size = fs::file_size(path);
    {
        std::lock_guard lock(g_mutex);
        auto it = cache().find(path);
        if (it != cache().end() && it->second.mtime == mtime && it->second.size == size) return it->second.clip;
    }
    auto text = fs::read_text(path);
    if (!text) return make_error(path + ": cannot read the clip: " + text.error().message,
                                 text.error().hint.empty() ? "3D clips are *.anim.json files; check the path in Animator.clips." : text.error().hint);
    auto json = parse_json(*text, path);
    if (!json) return json.error();
    if (!is_anim3d_json(*json))
        return make_error(path + " /format: this is not a 3D bone clip",
                          "A 3D clip starts with {\"format\": \"factoria.anim3d/1\", ...}; 2D clips (\"factoria.anim/1\") are played by an Animator with no glTF model.");
    auto parsed = parse_anim3d(*json, path, issues);
    if (!parsed) return parsed.error();
    auto clip = std::make_shared<Anim3DClip>(**parsed);
    clip->mtime = mtime;
    std::shared_ptr<const Anim3DClip> shared = clip;
    std::lock_guard lock(g_mutex);
    cache()[path] = CacheEntry{mtime, size, shared};
    return shared;
}

void clear_anim3d_cache() {
    std::lock_guard lock(g_mutex);
    cache().clear();
}

// ==================================================================================================== sampling ======

std::array<float, 4> sample_anim3d_track(const Anim3DTrack& tr, bool quat, float time) {
    const std::vector<ClipKey>& K = tr.keys;
    std::array<float, 4> out{};
    if (K.empty()) return out;
    const bool isQuat = quat && tr.channel == Anim3DChannel::Rotation;
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
    if (hold || a.interp == ClipInterp::Step) { out = a.value; return out; }
    const ClipKey& b = K[i + 1];
    const float span = b.t - a.t;
    const float f = span > 1e-9f ? (time - a.t) / span : 1.0f;
    if (isQuat) {
        const float u = a.interp == ClipInterp::Ease ? clip_ease(a.ease, f) : f;
        const Quat q = slerp(normalize(Quat{a.value[0], a.value[1], a.value[2], a.value[3]}),
                             normalize(Quat{b.value[0], b.value[1], b.value[2], b.value[3]}), u);
        return {q.x, q.y, q.z, q.w};
    }
    if (a.interp == ClipInterp::Bezier) {
        const float t2 = f * f, t3 = t2 * f;
        const float h00 = 2 * t3 - 3 * t2 + 1, h10 = t3 - 2 * t2 + f, h01 = -2 * t3 + 3 * t2, h11 = t3 - t2;
        for (std::size_t c = 0; c < 3; ++c)
            out[c] = h00 * a.value[c] + h10 * span * a.outTan[c] + h01 * b.value[c] + h11 * span * b.inTan[c];
        return out;
    }
    const float u = a.interp == ClipInterp::Ease ? clip_ease(a.ease, f) : f;
    for (std::size_t c = 0; c < 3; ++c) out[c] = a.value[c] + (b.value[c] - a.value[c]) * u;
    return out;
}

Anim3DBinding bind_anim3d(const Anim3DClip& clip, const SkeletonAsset& sk) {
    Anim3DBinding b;
    for (const Anim3DTrack& t : clip.tracks) {
        const int n = sk.find_node(t.bone);
        b.node.push_back(n);
        if (n < 0 && std::find(b.missing.begin(), b.missing.end(), t.bone) == b.missing.end()) b.missing.push_back(t.bone);
    }
    return b;
}

namespace {
void apply_value(const Anim3DClip& clip, const Anim3DTrack& tr, const std::array<float, 4>& v, const SkelNode& rest, std::size_t n, Pose& pose) {
    switch (tr.channel) {
        case Anim3DChannel::Rotation: {
            const Quat delta = clip.quat ? normalize(Quat{v[0], v[1], v[2], v[3]}) : Quat::from_euler_deg({v[0], v[1], v[2]});
            pose.rotation[n] = normalize(rest.rotation * delta);
            break;
        }
        case Anim3DChannel::Translation: pose.translation[n] = rest.translation + Vec3{v[0], v[1], v[2]}; break;
        case Anim3DChannel::Scale: pose.scale[n] = Vec3{rest.scale.x * v[0], rest.scale.y * v[1], rest.scale.z * v[2]}; break;
    }
}
}  // namespace

void sample_anim3d(const Anim3DClip& clip, const Anim3DBinding& binding, const SkeletonAsset& sk, float time, Pose& pose) {
    time = std::clamp(time, 0.0f, clip.duration);
    for (std::size_t i = 0; i < clip.tracks.size() && i < binding.node.size(); ++i) {
        const int n = binding.node[i];
        if (n < 0) continue;
        apply_value(clip, clip.tracks[i], sample_anim3d_track(clip.tracks[i], clip.quat, time), sk.nodes[std::size_t(n)], std::size_t(n), pose);
    }
}

AnimClip anim3d_to_anim_clip(const Anim3DClip& clip, const Anim3DBinding& binding, const SkeletonAsset& sk, const std::string& name) {
    AnimClip out;
    out.name = name;
    out.duration = clip.duration;
    out.loop = clip.loop ? 1 : 0;
    for (const ClipEvent& e : clip.events) out.events.push_back({e.t, e.name, e.data, e.feel});
    for (std::size_t ti = 0; ti < clip.tracks.size() && ti < binding.node.size(); ++ti) {
        const int node = binding.node[ti];
        if (node < 0) continue;
        const Anim3DTrack& tr = clip.tracks[ti];
        const SkelNode& rest = sk.nodes[std::size_t(node)];
        // Times: every key, plus sub-keys inside segments that are not straight lines in the value the glTF channel holds.
        std::vector<float> times;
        for (std::size_t k = 0; k < tr.keys.size(); ++k) {
            const ClipKey& a = tr.keys[k];
            times.push_back(a.t);
            if (k + 1 >= tr.keys.size()) break;
            const ClipKey& b = tr.keys[k + 1];
            if (a.interp == ClipInterp::Step) {
                if (b.t - a.t > 2e-4f) times.push_back(b.t - 1e-4f);
                continue;
            }
            int parts = 1;
            if (a.interp == ClipInterp::Ease || a.interp == ClipInterp::Bezier) parts = 8;
            if (tr.channel == Anim3DChannel::Rotation) {
                float span = 0.0f;
                if (clip.quat) {
                    const Quat qa = normalize(Quat{a.value[0], a.value[1], a.value[2], a.value[3]}), qb = normalize(Quat{b.value[0], b.value[1], b.value[2], b.value[3]});
                    span = rotation_angle_deg(qb * qa.conjugate());
                } else {
                    for (int c = 0; c < 3; ++c) span = std::max(span, std::fabs(b.value[std::size_t(c)] - a.value[std::size_t(c)]));
                }
                parts = std::max(parts, int(std::ceil(span / 8.0f)));
            }
            parts = std::clamp(parts, 1, 64);
            for (int s = 1; s < parts; ++s) times.push_back(a.t + (b.t - a.t) * float(s) / float(parts));
        }
        AnimChannel ch;
        ch.node = node;
        ch.path = tr.channel == Anim3DChannel::Rotation ? AnimPath::Rotation : tr.channel == Anim3DChannel::Translation ? AnimPath::Translation : AnimPath::Scale;
        ch.interp = AnimInterp::Linear;
        Pose scratch = rest_pose(sk);
        for (float t : times) {
            ch.times.push_back(t);
            apply_value(clip, tr, sample_anim3d_track(tr, clip.quat, t), rest, std::size_t(node), scratch);
            const std::size_t n = std::size_t(node);
            if (ch.path == AnimPath::Rotation) {
                Quat q = scratch.rotation[n];
                if (!ch.values.empty()) {  // stay in one hemisphere so the glTF slerp takes the short way
                    const std::size_t o = ch.values.size() - 4;
                    if (ch.values[o] * q.x + ch.values[o + 1] * q.y + ch.values[o + 2] * q.z + ch.values[o + 3] * q.w < 0.0f) q = {-q.x, -q.y, -q.z, -q.w};
                }
                ch.values.insert(ch.values.end(), {q.x, q.y, q.z, q.w});
            } else {
                const Vec3 v = ch.path == AnimPath::Translation ? scratch.translation[n] : scratch.scale[n];
                ch.values.insert(ch.values.end(), {v.x, v.y, v.z});
            }
        }
        out.channels.push_back(std::move(ch));
    }
    return out;
}

std::vector<ClipIssue> check_anim3d_rig(const Anim3DClip& clip, const Rig3D& rig) {
    std::vector<ClipIssue> out;
    const std::vector<std::string> names = rig.bone_names();
    for (std::size_t i = 0; i < clip.tracks.size(); ++i)
        if (rig.find(clip.tracks[i].bone) < 0)
            out.push_back({"/tracks/" + std::to_string(i) + "/bone",
                           "this model has no bone '" + clip.tracks[i].bone + "'" + (rig.templateName.empty() ? std::string() : " (its rig is a " + rig.templateName + ")"),
                           (names.empty() ? std::string("The model has no skin. ") : did_you_mean(clip.tracks[i].bone, names) + " ") +
                               "A clip made for another skeleton is carried over with anim3d.retarget."});
    for (std::size_t i = 0; i < clip.contacts.size(); ++i)
        if (rig.find(clip.contacts[i].bone) < 0)
            out.push_back({"/contacts/" + std::to_string(i) + "/bone", "this model has no bone '" + clip.contacts[i].bone + "'", did_you_mean(clip.contacts[i].bone, names)});
    return out;
}

}  // namespace fa
