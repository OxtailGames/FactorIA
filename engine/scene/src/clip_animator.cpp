#include "clip_animator.h"

#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/scene/components.h"
#include "fa/scene/serialize.h"

namespace fa {

// ================================================================================================ the runtime box ===

ClipRuntimeBox::ClipRuntimeBox() = default;
ClipRuntimeBox::~ClipRuntimeBox() = default;
// A copy starts empty: what the runtime holds (entities of the tree it animates, the fields it drove) belongs to the
// original. The copy binds to its own tree on its first update.
ClipRuntimeBox::ClipRuntimeBox(const ClipRuntimeBox&) {}
ClipRuntimeBox& ClipRuntimeBox::operator=(const ClipRuntimeBox& other) {
    if (this != &other) p_.reset();
    return *this;
}
ClipRuntimeBox::ClipRuntimeBox(ClipRuntimeBox&&) noexcept = default;
ClipRuntimeBox& ClipRuntimeBox::operator=(ClipRuntimeBox&&) noexcept = default;
ClipRuntime& ClipRuntimeBox::ensure() {
    if (!p_) p_ = std::make_unique<ClipRuntime>();
    return *p_;
}

namespace {

constexpr int kPollUpdates = 15;  // fixed steps between two checks of the clip files and of the entities the tracks name

// ----------------------------------------------------------------------------------------------------- small helpers --

std::string jstr(const Json& o, const char* key, const std::string& def = {}) {
    auto it = o.find(key);
    return it != o.end() && it->is_string() ? it->get<std::string>() : def;
}
float jnum(const Json& o, const char* key, float def) {
    auto it = o.find(key);
    return it != o.end() && it->is_number() ? it->get<float>() : def;
}
bool jbool(const Json& o, const char* key, bool def) {
    auto it = o.find(key);
    return it != o.end() && it->is_boolean() ? it->get<bool>() : def;
}

int field_floats(FieldKind k) {
    switch (k) {
        case FieldKind::Float: return 1;
        case FieldKind::Vec2: return 2;
        case FieldKind::Vec3: return 3;
        case FieldKind::Vec4: case FieldKind::Color: return 4;
        default: return 0;
    }
}

// The channels (bits) of its field a track drives.
unsigned track_mask(const ClipTrack& tr) {
    if (tr.stepped) return 1u;
    return tr.channel >= 0 ? 1u << tr.channel : (1u << tr.channels) - 1u;
}

float short_lerp(float a, float b, float f) {
    float d = std::fmod(b - a, 360.0f);
    if (d > 180.0f) d -= 360.0f;
    else if (d < -180.0f) d += 360.0f;
    return a + d * f;
}

void warn(World& w, Entity e, ClipRuntime& rt, const std::string& message) {
    if (!rt.warned.insert(message).second) return;
    FA_WARN("animation", "entity '{}' Animator: {}", w.id_of(e), message);
}

std::string entity_label(const World& w, Entity e) {
    const EntityInfo& inf = w.info(e);
    return inf.name.empty() ? inf.id : inf.name;
}

ClipBinding* find_binding(ClipRuntime& rt, const std::string& name) {
    if (name.empty()) return nullptr;
    auto it = rt.bindings.find(name);
    return it == rt.bindings.end() ? nullptr : &it->second;
}
const ClipBinding* find_binding(const ClipRuntime& rt, const std::string& name) {
    if (name.empty()) return nullptr;
    auto it = rt.bindings.find(name);
    return it == rt.bindings.end() ? nullptr : &it->second;
}

Error issue_error(const ClipBinding& b) {
    const ClipIssue& first = b.issues.front();
    std::string msg = std::format("{} {}: {}", b.file, first.pointer, first.message);
    if (b.issues.size() > 1) msg += std::format(" (and {} more problem{})", b.issues.size() - 1, b.issues.size() > 2 ? "s" : "");
    return make_error(msg, first.hint);
}

void warn_issues(World& w, Entity e, ClipRuntime& rt, const ClipBinding& b) {
    for (const ClipIssue& is : b.issues)
        warn(w, e, rt, std::format("{} {}: {}{}", b.file, is.pointer, is.message, is.hint.empty() ? "" : " " + is.hint));
}

// ----------------------------------------------------------------------------------------------------------- slots ---

void restore_channels(World& w, ClipSlot& s, unsigned channels) {
    if (s.dead || !w.alive(s.entity)) return;
    void* obj = w.get(s.entity, *s.type);
    if (!obj) return;
    if (s.stepped) {
        (void)field_from_json(*s.field, obj, s.restJson);
    } else {
        float* p = static_cast<float*>(s.field->ptr(obj));
        for (unsigned c = 0; c < 4; ++c)
            if (channels & (1u << c)) p[c] = s.rest[c];
    }
    s.hasWritten = false;
}

// The slot of the field `tr` drives on `ent`, created when it is the first clip to drive it. The channels `tr` adds to a
// slot take their rest value now, from the field as it is.
int slot_for(ClipRuntime& rt, World& w, Entity ent, const ClipTrack& tr) {
    int found = -1;
    for (std::size_t i = 0; i < rt.slots.size(); ++i) {
        const ClipSlot& s = rt.slots[i];
        if (!s.dead && s.entity == ent && s.type == tr.type && s.field == tr.info) { found = int(i); break; }
    }
    if (found < 0) {
        ClipSlot s;
        s.entity = ent;
        s.type = tr.type;
        s.field = tr.info;
        s.stepped = tr.stepped;
        rt.slots.push_back(std::move(s));
        found = int(rt.slots.size()) - 1;
    }
    ClipSlot& s = rt.slots[std::size_t(found)];
    s.angle = s.angle || tr.angle;
    const unsigned mask = track_mask(tr);
    const unsigned fresh = mask & ~s.channels;
    if (fresh) {
        const void* obj = w.get(ent, *tr.type);
        if (s.stepped) {
            s.restJson = field_to_json(*tr.info, obj);
        } else {
            const float* p = static_cast<const float*>(tr.info->ptr(obj));
            for (unsigned c = 0; c < 4; ++c)
                if (fresh & (1u << c)) s.rest[c] = p[c];
        }
        s.channels |= fresh;
    }
    return found;
}

// Hands back to rest every field channel no bound track drives any more (after a clip file lost a track, or a rebind).
void release_unused_slots(World& w, ClipRuntime& rt) {
    std::vector<unsigned> used(rt.slots.size(), 0u);
    for (const auto& [name, b] : rt.bindings)
        for (std::size_t ti = 0; ti < b.slot.size(); ++ti)
            if (b.slot[ti] >= 0 && std::size_t(b.slot[ti]) < used.size()) used[std::size_t(b.slot[ti])] |= track_mask(b.asset->tracks[ti]);
    for (std::size_t i = 0; i < rt.slots.size(); ++i) {
        ClipSlot& s = rt.slots[i];
        if (s.dead) continue;
        const unsigned drop = s.channels & ~used[i];
        if (!drop) continue;
        restore_channels(w, s, drop);
        s.channels &= ~drop;
        if (!s.channels) s.dead = true;
    }
}

// ---------------------------------------------------------------------------------------------------------- binding ---

// Finds the entities the tracks name and the slots they drive. Tracks whose path or component is missing are listed in
// `issues` and skipped; they are tried again at the next poll.
void resolve_binding(World& w, Entity e, ClipRuntime& rt, ClipBinding& b) {
    const ClipAsset& c = *b.asset;
    b.issues.clear();
    b.targets.assign(c.paths.size(), kNullEntity);
    for (std::size_t i = 0; i < c.paths.size(); ++i) {
        auto r = resolve_clip_path(w, e, c.paths[i]);
        if (r) b.targets[i] = *r;
    }
    b.issues = check_clip_paths(w, e, c);
    b.slot.assign(c.tracks.size(), -1);
    for (std::size_t ti = 0; ti < c.tracks.size(); ++ti) {
        const ClipTrack& tr = c.tracks[ti];
        const Entity target = b.targets[std::size_t(tr.pathIndex)];
        if (target.is_null()) continue;
        if (!w.get(target, *tr.type)) {
            b.issues.push_back({"/tracks/" + std::to_string(ti) + "/component",
                                std::format("the entity '{}' has no {} component", entity_label(w, target), tr.component),
                                std::format("Add a {} to it, or point the track at the entity that has one.", tr.component)});
            continue;
        }
        b.slot[ti] = slot_for(rt, w, target, tr);
    }
    std::stable_sort(b.issues.begin(), b.issues.end(), [](const ClipIssue& x, const ClipIssue& y) {
        return std::stoul(x.pointer.substr(8)) < std::stoul(y.pointer.substr(8));  // "/tracks/<n>/..."
    });
    release_unused_slots(w, rt);
}

// The binding of clip `name` (a key of Animator.clips), loaded and resolved on first use.
Result<ClipBinding*> bind_clip(World& w, Entity e, Animator& a, ClipRuntime& rt, const std::string& name) {
    if (!a.clips.is_object() || !a.clips.contains(name)) {
        std::vector<std::string> names;
        if (a.clips.is_object())
            for (auto it = a.clips.begin(); it != a.clips.end(); ++it) names.push_back(it.key());
        return make_error(std::format("the Animator has no 2D clip '{}'", name),
                          names.empty() ? "Declare it: \"clips\": {\"" + name + "\": \"anim/" + name + ".anim.json\"}."
                                        : did_you_mean(name, names) + " Clips: " + join(names, ", ") + ".");
    }
    const Json& entry = a.clips.at(name);
    if (!entry.is_string())
        return make_error(std::format("Animator.clips['{}'] must be a path, got {}", name, describe_json_value(entry)),
                          "Write {\"" + name + "\": \"anim/" + name + ".anim.json\"}.");
    const std::string file = entry.get<std::string>();
    auto asset = load_anim_clip(file);
    if (!asset) return asset.error();
    if (ClipBinding* have = find_binding(rt, name); have && have->file == file && have->asset.get() == asset->get()) return have;
    ClipBinding b;
    b.name = name;
    b.file = file;
    b.asset = *asset;
    ClipBinding& ref = rt.bindings[name];
    ref = std::move(b);
    resolve_binding(w, e, rt, ref);
    return &ref;
}

// Loads every clip of the Animator once and warns about the ones that do not load or do not fit the entity's tree.
void validate_clips(World& w, Entity e, Animator& a, ClipRuntime& rt) {
    if (!a.clips.is_object()) return;
    for (auto it = a.clips.begin(); it != a.clips.end(); ++it) {
        if (!it->is_string()) {
            warn(w, e, rt, std::format("clips['{}'] must be a path, got {}", it.key(), describe_json_value(*it)));
            continue;
        }
        const std::string file = it->get<std::string>();
        auto r = load_anim_clip(file);
        if (!r) {
            warn(w, e, rt, std::format("clip '{}': {}", it.key(), r.error().to_string()));
            continue;
        }
        for (const ClipIssue& is : check_clip_paths(w, e, **r))
            warn(w, e, rt, std::format("{} {}: {}{}", file, is.pointer, is.message, is.hint.empty() ? "" : " " + is.hint));
    }
}

bool binding_in_use(const ClipRuntime& rt, const std::string& name) {
    auto uses = [&](const ClipPlayer& p) { return p.name == name || p.from == name; };
    if (uses(rt.main)) return true;
    for (const ClipLayer& l : rt.layers)
        if (uses(l.player)) return true;
    return false;
}

// A clip file that changed, a clip that moved to another file, or entities that were renamed, added or removed: bind again.
void poll(World& w, Entity e, Animator& a, ClipRuntime& rt) {
    for (auto& [name, b] : rt.bindings) {
        auto entry = a.clips.is_object() ? a.clips.find(name) : a.clips.end();
        if (entry == a.clips.end() || !entry->is_string()) continue;
        const std::string file = entry->get<std::string>();
        bool rebind = false;
        auto r = load_anim_clip(file);
        if (!r) {
            warn(w, e, rt, std::format("clip '{}': {}", name, r.error().to_string()));  // the last good clip keeps playing
        } else if (file != b.file || r->get() != b.asset.get()) {
            b.file = file;
            b.asset = *r;
            rebind = true;
        }
        for (std::size_t i = 0; i < b.asset->paths.size() && !rebind; ++i) {
            auto t = resolve_clip_path(w, e, b.asset->paths[i]);
            rebind = (t ? *t : kNullEntity) != b.targets[i];
        }
        for (std::size_t ti = 0; ti < b.asset->tracks.size() && !rebind; ++ti) {  // a component that appeared or went away
            const ClipTrack& tr = b.asset->tracks[ti];
            const Entity t = b.targets[std::size_t(tr.pathIndex)];
            rebind = (b.slot[ti] >= 0) != (!t.is_null() && w.get(t, *tr.type) != nullptr);
        }
        if (!rebind) continue;
        resolve_binding(w, e, rt, b);
        for (ClipSlot& s : rt.slots) s.hasWritten = false;
        warn_issues(w, e, rt, b);
    }
}

// --------------------------------------------------------------------------------------------------- evaluating ----

struct Val {
    std::array<float, 4> v{};
    unsigned mask = 0;              // channels with a value (a stepping field: bit 0 and `raw`)
    const Json* raw = nullptr;
};

bool under_mask(const std::string& path, const std::vector<std::string>& mask) {
    if (mask.empty()) return true;
    for (const std::string& m : mask) {
        if (m.empty()) return true;
        if (path.size() >= m.size() && path.compare(0, m.size(), m) == 0 && (path.size() == m.size() || path[m.size()] == '/')) return true;
    }
    return false;
}

// What the tracks of `b` give at `time`, per slot. `additive`: the change from the clip's first pose (interpolating
// fields only). `layer`: only the tracks under its mask.
void eval_clip(const ClipRuntime& rt, const ClipBinding& b, float time, bool additive, const ClipLayer* layer, std::vector<Val>& out) {
    out.assign(rt.slots.size(), Val{});
    const ClipAsset& c = *b.asset;
    const float t = std::clamp(time, 0.0f, c.duration);
    for (std::size_t ti = 0; ti < c.tracks.size(); ++ti) {
        const int si = b.slot[ti];
        if (si < 0 || std::size_t(si) >= out.size() || rt.slots[std::size_t(si)].dead) continue;
        const ClipTrack& tr = c.tracks[ti];
        if (layer && !under_mask(tr.path, layer->mask)) continue;
        Val& o = out[std::size_t(si)];
        if (tr.stepped) {
            if (additive) continue;
            const Json* raw = nullptr;
            std::array<float, 4> unused{};
            sample_clip_track(tr, t, unused, &raw);
            o.raw = raw;
            o.mask |= 1u;
            continue;
        }
        std::array<float, 4> v{};
        sample_clip_track(tr, t, v, nullptr);
        if (additive) {
            std::array<float, 4> v0{};
            sample_clip_track(tr, 0.0f, v0, nullptr);
            for (std::size_t k = 0; k < 4; ++k) v[k] -= v0[k];
        }
        if (tr.channel >= 0) {
            o.v[std::size_t(tr.channel)] = v[0];
        } else {
            for (std::size_t k = 0; k < std::size_t(tr.channels); ++k) o.v[k] = v[k];
        }
        o.mask |= track_mask(tr);
    }
}

// The pose a player gives: its clip, cross-faded from the clip it replaces. A channel one of the two clips does not drive
// is taken from `base`. Angles take the short way, fields that only step switch at half the fade.
void blend_player(const ClipRuntime& rt, const ClipPlayer& p, bool additive, const ClipLayer* layer, const std::vector<Val>& base,
                  std::vector<Val>& res) {
    const ClipBinding* to = find_binding(rt, p.name);
    std::vector<Val> B;
    if (to) eval_clip(rt, *to, p.time, additive, layer, B);
    else B.assign(rt.slots.size(), Val{});
    const ClipBinding* from = p.from.empty() || p.fadeDuration <= 0.0f ? nullptr : find_binding(rt, p.from);
    if (!from) {
        res = std::move(B);
        return;
    }
    std::vector<Val> A;
    eval_clip(rt, *from, p.fromTime, additive, layer, A);
    const float f = std::clamp(p.fadeElapsed / p.fadeDuration, 0.0f, 1.0f);
    res.assign(rt.slots.size(), Val{});
    for (std::size_t s = 0; s < rt.slots.size(); ++s) {
        const ClipSlot& slot = rt.slots[s];
        if (slot.dead) continue;
        Val& r = res[s];
        if (slot.stepped) {
            if (!A[s].raw && !B[s].raw) continue;
            const Json* a = A[s].raw ? A[s].raw : base[s].raw;
            const Json* b = B[s].raw ? B[s].raw : base[s].raw;
            r.raw = f < 0.5f ? a : b;
            if (r.raw) r.mask = 1u;
            continue;
        }
        for (unsigned ch = 0; ch < 4; ++ch) {
            const unsigned bit = 1u << ch;
            const bool aHas = A[s].mask & bit, bHas = B[s].mask & bit;
            if (!aHas && !bHas) continue;
            const float av = aHas ? A[s].v[ch] : base[s].v[ch];
            const float bv = bHas ? B[s].v[ch] : base[s].v[ch];
            r.v[ch] = slot.angle && !additive ? short_lerp(av, bv, f) : av + (bv - av) * f;
            r.mask |= bit;
        }
    }
}

// The pose of the Animator: rest, then the main clip, then every layer in order.
void compose_and_write(World& w, Animator& a, ClipRuntime& rt) {
    const std::size_t n = rt.slots.size();
    if (n == 0) return;
    std::vector<Val> cur(n);
    for (std::size_t s = 0; s < n; ++s) {
        const ClipSlot& slot = rt.slots[s];
        cur[s].v = slot.rest;
        cur[s].mask = slot.channels;
        cur[s].raw = slot.stepped ? &slot.restJson : nullptr;
    }
    std::vector<Val> res;
    auto apply_main = [&] {
        rt.main.time = a.time;
        if (rt.main.name.empty()) return;
        blend_player(rt, rt.main, false, nullptr, cur, res);
        for (std::size_t s = 0; s < n; ++s) {
            if (rt.slots[s].stepped) {
                if (res[s].raw) cur[s].raw = res[s].raw;
                continue;
            }
            for (unsigned ch = 0; ch < 4; ++ch)
                if (res[s].mask & (1u << ch)) cur[s].v[ch] = res[s].v[ch];
        }
    };
    apply_main();
    for (const ClipLayer& L : rt.layers) {
        if (L.weight <= 0.0f || L.player.name.empty()) continue;
        std::vector<Val> zero;
        if (L.additive) zero.assign(n, Val{});
        blend_player(rt, L.player, L.additive, &L, L.additive ? zero : cur, res);
        for (std::size_t s = 0; s < n; ++s) {
            if (rt.slots[s].dead) continue;
            if (rt.slots[s].stepped) {
                if (!L.additive && res[s].raw && L.weight >= 0.5f) cur[s].raw = res[s].raw;
                continue;
            }
            for (unsigned ch = 0; ch < 4; ++ch) {
                if (!(res[s].mask & (1u << ch))) continue;
                float& c = cur[s].v[ch];
                if (L.additive) c += res[s].v[ch] * L.weight;
                else c = rt.slots[s].angle ? short_lerp(c, res[s].v[ch], L.weight) : c + (res[s].v[ch] - c) * L.weight;
            }
        }
    }
    for (std::size_t s = 0; s < n; ++s) {
        ClipSlot& slot = rt.slots[s];
        if (slot.dead) continue;
        if (!w.alive(slot.entity)) {
            slot.dead = true;
            continue;
        }
        void* obj = w.get(slot.entity, *slot.type);
        if (!obj) continue;
        if (slot.stepped) {
            const Json* raw = cur[s].raw;
            if (!raw) continue;
            if (!slot.hasWritten || slot.written != *raw) {
                (void)field_from_json(*slot.field, obj, *raw);
                slot.written = *raw;
                slot.hasWritten = true;
            }
        } else {
            float* p = static_cast<float*>(slot.field->ptr(obj));
            for (unsigned ch = 0; ch < 4; ++ch)
                if (slot.channels & (1u << ch)) p[ch] = cur[s].v[ch];
        }
    }
}

// ---------------------------------------------------------------------------------------------------------- players ---

bool main_loop(const Animator& a, const ClipRuntime& rt) {
    const ClipBinding* b = find_binding(rt, rt.main.name);
    const bool assetLoop = b ? b->asset->loop : true;
    return rt.loopForced ? a.loop : a.loop && assetLoop;
}

bool layer_loop(const ClipLayer& L, const ClipRuntime& rt) {
    const ClipBinding* b = find_binding(rt, L.player.name);
    const bool assetLoop = b ? b->asset->loop : true;
    return L.stateLoopSet ? L.stateLoop : L.cfgLoopSet ? L.cfgLoop : assetLoop;
}

// Points a player at clip `name`, fading from what it plays now.
void switch_player(ClipPlayer& p, const std::string& name, float fade, bool curLoop) {
    if (fade > 0.0f && !p.name.empty() && p.name != name) {
        p.from = p.name;
        p.fromTime = p.time;
        p.fromLoop = curLoop;
        p.fadeElapsed = 0.0f;
        p.fadeDuration = fade;
    } else {
        p.from.clear();
        p.fadeElapsed = p.fadeDuration = 0.0f;
    }
    p.name = name;
    p.time = p.lastTime = 0.0f;
    p.prevTime = -1.0f;
    p.finished = false;
}

void fire_clip_events(World& w, Entity e, const Animator& a, const ClipAsset& asset, const std::string& clip, const std::string* layer,
                      float from, float to) {
    struct Hit { float t; const std::string* name; const Json* data; };
    std::vector<Hit> hits;
    for (const ClipEvent& ev : asset.events)
        if (ev.t > from && ev.t <= to) hits.push_back({ev.t, &ev.name, &ev.data});
    if (a.events.is_array()) {
        for (const Json& ev : a.events) {
            if (!ev.is_object() || jstr(ev, "clip") != clip) continue;
            const float t = jnum(ev, "time", 0.0f);
            if (t > from && t <= to) hits.push_back({t, nullptr, &ev});
        }
    }
    std::stable_sort(hits.begin(), hits.end(), [](const Hit& x, const Hit& y) { return x.t < y.t; });
    for (const Hit& h : hits) {
        std::string name;
        Json data = Json::object();
        if (h.name) {
            name = *h.name;
            if (h.data->is_object()) data = *h.data;
        } else {
            name = jstr(*h.data, "name");
        }
        if (name.empty()) continue;
        data["clip"] = clip;
        data["time"] = h.t;
        if (layer) data["layer"] = *layer;
        animdetail::emit_game_event(w, name, e, std::move(data));
    }
}

// Moves a player forward `step` seconds of clip time (`dt` real seconds for the fade). True when a clip that does not loop
// reached its end during this call.
bool advance_player(World& w, Entity e, const Animator& a, ClipRuntime& rt, ClipPlayer& p, float dt, float step, bool loop,
                    const std::string* layer) {
    bool ended = false;
    if (const ClipBinding* b = find_binding(rt, p.name)) {
        const ClipAsset& c = *b->asset;
        const float dur = c.duration;
        float t = std::max(0.0f, p.time + step);
        if (dur <= 0.0f) {
            if (!p.finished && step > 0.0f) fire_clip_events(w, e, a, c, p.name, layer, p.prevTime, 0.0f);
            t = 0.0f;
            p.prevTime = 0.0f;
        } else if (loop) {
            int guard = 0;
            while (t >= dur && step > 0.0f && ++guard < 1000) {
                fire_clip_events(w, e, a, c, p.name, layer, p.prevTime, dur);
                p.prevTime = -1.0f;
                t -= dur;
            }
            if (t >= dur) t = std::fmod(t, dur);
            if (step > 0.0f) fire_clip_events(w, e, a, c, p.name, layer, p.prevTime, t);
            p.prevTime = t;
        } else if (!p.finished) {
            if (t >= dur) {
                fire_clip_events(w, e, a, c, p.name, layer, p.prevTime, dur);
                t = dur;
                p.prevTime = dur;
                p.finished = true;
                ended = true;
            } else {
                if (step > 0.0f) fire_clip_events(w, e, a, c, p.name, layer, p.prevTime, t);
                p.prevTime = t;
            }
        } else {
            t = p.time;
        }
        p.time = p.lastTime = t;
    }
    if (!p.from.empty()) {
        const ClipBinding* fb = find_binding(rt, p.from);
        const float fd = fb ? fb->asset->duration : 0.0f;
        p.fromTime += step;
        if (fd > 0.0f) p.fromTime = p.fromLoop ? std::fmod(p.fromTime, fd) : std::min(p.fromTime, fd);
        p.fadeElapsed += dt;
        if (p.fadeElapsed >= p.fadeDuration) {
            p.from.clear();
            p.fadeElapsed = p.fadeDuration = 0.0f;
        }
    }
    return ended;
}

void emit_finished(World& w, Entity e, const std::string& clip, const std::string* layer) {
    Json data = Json::object({{"clip", clip}});
    if (layer) data["layer"] = *layer;
    animdetail::emit_game_event(w, "anim.finished", e, std::move(data));
}

// ------------------------------------------------------------------------------------------------------ state machine --

struct Pick {
    std::string to;
    float fade = 0.2f;
};

// The first transition of `transitions` that leaves `state` and holds (same rules as the glTF Animator).
bool pick_transition(const Json& states, const Json& transitions, const std::string& state, const Json& values,
                     const std::vector<std::string>& triggers, bool finished, Pick& out) {
    if (!states.is_object() || states.empty() || !transitions.is_array()) return false;
    for (const Json& t : transitions) {
        if (!t.is_object()) continue;
        const std::string from = jstr(t, "from", "*"), to = jstr(t, "to");
        if (to.empty() || to == state) continue;
        if (from != "*" && from != state) continue;
        const bool onFinish = jbool(t, "onFinish", false);
        const std::string when = jstr(t, "when");
        if (onFinish && !finished) continue;
        if (!onFinish && when.empty()) continue;
        if (!when.empty() && !animdetail::condition_holds(when, values, triggers)) continue;
        out.to = to;
        out.fade = jnum(t, "fade", 0.2f);
        return true;
    }
    return false;
}

// Starts `name` on the main player. `strict`: a track that finds no entity or component is an error (play from a script);
// otherwise it is a warning and the other tracks play.
Result<void> start_main(World& w, Entity e, Animator& a, ClipRuntime& rt, const std::string& name, float fade, bool strict) {
    auto bound = bind_clip(w, e, a, rt, name);
    if (!bound) return bound.error();
    ClipBinding& b = **bound;
    if (!b.issues.empty()) {
        if (strict) {
            Error err = issue_error(b);
            if (!binding_in_use(rt, name)) {
                rt.bindings.erase(name);
                release_unused_slots(w, rt);
            }
            return err;
        }
        warn_issues(w, e, rt, b);
    }
    ClipPlayer& p = rt.main;
    p.time = a.time;
    if (p.name == name && a.playing && !p.finished) {
        a.clip = name;
        return {};
    }
    switch_player(p, name, fade, main_loop(a, rt));
    rt.loopForced = false;
    a.clip = name;
    a.time = 0.0f;
    a.playing = true;
    return {};
}

void enter_state(World& w, Entity e, Animator& a, ClipRuntime& rt, const std::string& name, float fade) {
    auto it = a.states.find(name);
    if (it == a.states.end() || !it->is_object()) {
        warn(w, e, rt, std::format("state '{}' is not in `states`", name));
        return;
    }
    const std::string prev = a.state;
    a.state = name;
    a.loop = jbool(*it, "loop", true);
    a.speed = jnum(*it, "speed", 1.0f);
    const std::string clip = jstr(*it, "clip");
    if (!clip.empty()) {
        auto r = start_main(w, e, a, rt, clip, fade, false);
        if (!r) warn(w, e, rt, std::format("state '{}': {}", name, r.error().to_string()));
    }
    rt.loopForced = it->contains("loop");
    const std::string onEnter = jstr(*it, "onEnter");
    if (!onEnter.empty()) animdetail::emit_game_event(w, onEnter, e, Json::object({{"state", name}, {"from", prev}}));
}

void run_main_machine(World& w, Entity e, Animator& a, ClipRuntime& rt) {
    Pick pick;
    if (pick_transition(a.states, a.transitions, a.state, a.values, a.rt.triggers, rt.main.finished, pick))
        enter_state(w, e, a, rt, pick.to, pick.fade);
}

// ---------------------------------------------------------------------------------------------------------- layers ----

Result<void> start_layer_clip(World& w, Entity e, Animator& a, ClipRuntime& rt, ClipLayer& L, const std::string& clip, float fade, bool strict) {
    auto bound = bind_clip(w, e, a, rt, clip);
    if (!bound) return bound.error();
    ClipBinding& b = **bound;
    if (!b.issues.empty()) {
        if (strict) {
            Error err = issue_error(b);
            if (!binding_in_use(rt, clip)) {
                rt.bindings.erase(clip);
                release_unused_slots(w, rt);
            }
            return err;
        }
        warn_issues(w, e, rt, b);
    }
    if (L.player.name == clip && !L.player.finished) return {};
    switch_player(L.player, clip, fade, layer_loop(L, rt));
    return {};
}

void enter_layer_state(World& w, Entity e, Animator& a, ClipRuntime& rt, ClipLayer& L, const std::string& name, float fade) {
    const Json& states = L.config.contains("states") ? L.config["states"] : Json::object();
    auto it = states.is_object() ? states.find(name) : states.end();
    if (!states.is_object() || it == states.end() || !it->is_object()) {
        warn(w, e, rt, std::format("layer '{}': state '{}' is not in its `states`", L.name, name));
        return;
    }
    const std::string prev = L.state;
    L.state = name;
    L.stateLoopSet = it->contains("loop") && (*it)["loop"].is_boolean();
    L.stateLoop = jbool(*it, "loop", true);
    L.stateSpeed = jnum(*it, "speed", 1.0f);
    const std::string clip = jstr(*it, "clip");
    if (!clip.empty()) {
        auto r = start_layer_clip(w, e, a, rt, L, clip, fade, false);
        if (!r) warn(w, e, rt, std::format("layer '{}' state '{}': {}", L.name, name, r.error().to_string()));
    }
    const std::string onEnter = jstr(*it, "onEnter");
    if (!onEnter.empty()) animdetail::emit_game_event(w, onEnter, e, Json::object({{"state", name}, {"from", prev}, {"layer", L.name}}));
}

// Rebuilds the layer list when Animator.layers changed (a script assigned it, or the editor did): players of layers that are
// still there (same name) keep playing, unless their `clip` changed.
void sync_layers(World& w, Entity e, Animator& a, ClipRuntime& rt) {
    if (a.layers == rt.layersSeen) return;
    rt.layersSeen = a.layers;
    std::vector<ClipLayer> next;
    if (a.layers.is_array()) {
        for (std::size_t i = 0; i < a.layers.size(); ++i) {
            const Json& cfg = a.layers[i];
            if (!cfg.is_object()) {
                warn(w, e, rt, std::format("layers[{}] must be an object like {{\"name\": \"arms\", \"clip\": \"shoot\"}}, got {}", i, describe_json_value(cfg)));
                continue;
            }
            const std::string name = jstr(cfg, "name", "layer" + std::to_string(i));
            ClipLayer L;
            for (ClipLayer& old : rt.layers)
                if (old.name == name) { L = old; break; }
            L.name = name;
            L.config = cfg;
            L.weight = std::clamp(jnum(cfg, "weight", 1.0f), 0.0f, 1.0f);
            const std::string mode = jstr(cfg, "mode", "override");
            if (mode != "override" && mode != "additive")
                warn(w, e, rt, std::format("layers[{}] ('{}'): unknown mode '{}'. {} Valid: override, additive.", i, name, mode,
                                           did_you_mean(mode, std::vector<std::string>{"override", "additive"})));
            L.additive = mode == "additive";
            L.speed = jnum(cfg, "speed", 1.0f);
            L.cfgLoopSet = cfg.contains("loop") && cfg["loop"].is_boolean();
            L.cfgLoop = jbool(cfg, "loop", true);
            L.mask.clear();
            if (auto m = cfg.find("mask"); m != cfg.end()) {
                if (m->is_array()) {
                    for (const Json& p : *m) {
                        if (!p.is_string()) { warn(w, e, rt, std::format("layer '{}': mask entries are paths (strings), got {}", name, describe_json_value(p))); continue; }
                        L.mask.push_back(p.get<std::string>());
                    }
                } else if (m->is_string()) {
                    L.mask.push_back(m->get<std::string>());
                } else {
                    warn(w, e, rt, std::format("layer '{}': mask must be an array of paths like [\"body/arm_l\"], got {}", name, describe_json_value(*m)));
                }
            }
            for (const std::string& path : L.mask) {
                auto r = resolve_clip_path(w, e, path);
                if (!r) warn(w, e, rt, std::format("layer '{}' mask '{}': {}{}", name, path, r.error().message, r.error().hint.empty() ? "" : " " + r.error().hint));
            }
            const bool hasStates = cfg.contains("states") && cfg["states"].is_object() && !cfg["states"].empty();
            const std::string clip = jstr(cfg, "clip");
            if (hasStates && !clip.empty())
                warn(w, e, rt, std::format("layer '{}' has both `clip` and `states`: `states` wins", name));
            if (!hasStates && clip.empty())
                warn(w, e, rt, std::format("layer '{}' has no `clip` and no `states`, so it plays nothing", name));
            const std::string key = hasStates ? "states" : "clip:" + clip;
            if (key != L.clipSeen) {
                L.clipSeen = key;
                L.player = ClipPlayer{};
                L.started = false;
                L.state = jstr(cfg, "state");
            }
            next.push_back(std::move(L));
        }
    }
    rt.layers = std::move(next);
}

void update_layers(World& w, Entity e, Animator& a, ClipRuntime& rt, float dt) {
    for (std::size_t i = 0; i < rt.layers.size(); ++i) {
        ClipLayer& L = rt.layers[i];
        const bool hasStates = L.clipSeen == "states";
        if (L.weight <= 0.0f) {
            if (L.started) {
                L.player = ClipPlayer{};
                L.started = false;
                L.state = jstr(L.config, "state");
            }
            continue;
        }
        if (!L.started) {
            L.started = true;
            if (hasStates) {
                const Json& states = L.config["states"];
                const std::string first = states.begin().key();
                enter_layer_state(w, e, a, rt, L, states.contains(L.state) ? L.state : first, 0.0f);
            } else {
                const std::string clip = jstr(L.config, "clip");
                if (!clip.empty()) {
                    auto r = start_layer_clip(w, e, a, rt, L, clip, 0.0f, false);
                    if (!r) warn(w, e, rt, std::format("layer '{}': {}", L.name, r.error().to_string()));
                }
            }
        }
        if (hasStates) {
            Pick pick;
            const Json none = Json::array();
            if (pick_transition(L.config["states"], L.config.contains("transitions") ? L.config["transitions"] : none, L.state, a.values,
                                a.rt.triggers, L.player.finished, pick))
                enter_layer_state(w, e, a, rt, L, pick.to, pick.fade);
        }
        if (L.player.name.empty() || dt <= 0.0f) continue;
        const float step = dt * std::max(0.0f, L.speed * L.stateSpeed);
        if (advance_player(w, e, a, rt, L.player, dt, step, layer_loop(L, rt), &L.name))
            emit_finished(w, e, L.player.name, &L.name);
    }
}

}  // namespace

// ============================================================================================================ the API ===

namespace clipanim {

bool uses_clip_files(const World& w, Entity e, const Animator& a) {
    if (!a.model.empty() || !a.clips.is_object() || a.clips.empty()) return false;
    if (const MeshRenderer* mr = w.get<MeshRenderer>(e))
        if (ends_with(mr->mesh, ".gltf") || ends_with(mr->mesh, ".glb")) return false;
    return true;
}

void update(World& w, Entity e, Animator& a, float dt) {
    AnimatorRuntime& art = a.rt;
    ClipRuntime& rt = art.clip.ensure();
    if (!art.started) {
        art.started = true;
        if (a.values.empty() && a.params.is_object()) a.values = a.params;
        validate_clips(w, e, a, rt);
        if (a.states.is_object() && !a.states.empty()) {
            const std::string first = a.states.begin().key();
            enter_state(w, e, a, rt, a.states.contains(a.state) ? a.state : first, 0.0f);
        } else if (!a.clip.empty()) {
            auto r = start_main(w, e, a, rt, a.clip, 0.0f, false);
            if (!r) warn(w, e, rt, r.error().to_string());
        }
    } else {
        if (++rt.sincePoll >= kPollUpdates) {
            rt.sincePoll = 0;
            poll(w, e, a, rt);
        }
        if (a.clip != rt.main.name) {
            if (a.clip.empty()) {
                rt.main = ClipPlayer{};
                a.time = 0.0f;
            } else {
                auto r = start_main(w, e, a, rt, a.clip, a.fade, false);
                if (!r) {
                    warn(w, e, rt, r.error().to_string());
                    a.clip = rt.main.name;
                }
            }
        }
        if (a.time != rt.main.lastTime) {  // a script seeked: no events for the jump
            rt.main.prevTime = a.time;
            rt.main.lastTime = a.time;
        }
    }
    run_main_machine(w, e, a, rt);
    sync_layers(w, e, a, rt);
    if (a.playing && !rt.main.name.empty() && dt > 0.0f) {
        rt.main.time = a.time;
        const float step = dt * std::max(0.0f, a.speed);
        const bool ended = advance_player(w, e, a, rt, rt.main, dt, step, main_loop(a, rt), nullptr);
        a.time = rt.main.time;
        if (ended) {
            a.playing = false;
            emit_finished(w, e, rt.main.name, nullptr);
        }
    }
    update_layers(w, e, a, rt, dt);
    art.triggers.clear();
    compose_and_write(w, a, rt);
}

Result<void> play(World& w, Entity e, Animator& a, std::string_view clip, float fade) {
    ClipRuntime& rt = a.rt.clip.ensure();
    return start_main(w, e, a, rt, std::string(clip), fade, true);
}

Result<void> stop(World& w, Entity e, Animator& a) {
    (void)e;
    ClipRuntime& rt = a.rt.clip.ensure();
    for (ClipSlot& s : rt.slots) {
        if (s.dead) continue;
        restore_channels(w, s, s.channels);
        s.dead = true;
    }
    rt.slots.clear();
    rt.bindings.clear();
    rt.main = ClipPlayer{};
    rt.loopForced = false;
    for (ClipLayer& L : rt.layers) {
        L.player = ClipPlayer{};
        L.started = false;
        L.state = jstr(L.config, "state");
    }
    a.clip.clear();
    a.time = 0.0f;
    a.playing = false;
    return {};
}

Result<Json> clips(World& w, Entity e, Animator& a) {
    (void)w;
    (void)e;
    Json out = Json::array();
    if (!a.clips.is_object()) return out;
    for (auto it = a.clips.begin(); it != a.clips.end(); ++it) {
        Json entry = Json::object({{"name", it.key()}});
        if (!it->is_string()) {
            entry["error"] = "must be a path, got " + describe_json_value(*it);
            out.push_back(std::move(entry));
            continue;
        }
        const std::string file = it->get<std::string>();
        entry["file"] = file;
        auto r = load_anim_clip(file);
        if (!r) {
            entry["error"] = r.error().to_string();
        } else {
            entry["duration"] = (*r)->duration;
            entry["loop"] = (*r)->loop;
        }
        out.push_back(std::move(entry));
    }
    return out;
}

Result<void> sample(World& w, Entity e, Animator& a, std::string_view clip, float time) {
    ClipRuntime& rt = a.rt.clip.ensure();
    const std::string name(clip);
    auto bound = bind_clip(w, e, a, rt, name);
    if (!bound) return bound.error();
    ClipBinding& b = **bound;
    if (!b.issues.empty()) {
        Error err = issue_error(b);
        if (!binding_in_use(rt, name)) {
            rt.bindings.erase(name);
            release_unused_slots(w, rt);
        }
        return err;
    }
    if (!a.rt.started) {
        a.rt.started = true;
        if (a.values.empty() && a.params.is_object()) a.values = a.params;
    }
    const float t = std::clamp(time, 0.0f, b.asset->duration);
    ClipPlayer& p = rt.main;
    p = ClipPlayer{};
    p.name = name;
    p.time = p.lastTime = p.prevTime = t;
    rt.loopForced = false;
    a.clip = name;
    a.time = t;
    a.playing = false;
    compose_and_write(w, a, rt);
    return {};
}

Result<void> set_layer_weight(World& w, Entity e, Animator& a, std::string_view layer, float weight) {
    ClipRuntime& rt = a.rt.clip.ensure();
    sync_layers(w, e, a, rt);
    std::vector<std::string> names;
    for (ClipLayer& L : rt.layers) {
        names.push_back(L.name);
        if (L.name != layer) continue;
        L.weight = std::clamp(weight, 0.0f, 1.0f);
        for (Json& cfg : a.layers)
            if (cfg.is_object() && jstr(cfg, "name") == L.name) cfg["weight"] = L.weight;
        L.config["weight"] = L.weight;
        rt.layersSeen = a.layers;
        return {};
    }
    return make_error(std::format("the Animator has no layer '{}'", layer),
                      names.empty() ? "Declare it in `layers`: [{\"name\": \"" + std::string(layer) + "\", \"clip\": \"shoot\"}]."
                                    : did_you_mean(std::string(layer), names) + " Layers: " + join(names, ", ") + ".");
}

Result<void> play_layer(World& w, Entity e, Animator& a, std::string_view layer, std::string_view clip, float fade) {
    ClipRuntime& rt = a.rt.clip.ensure();
    sync_layers(w, e, a, rt);
    std::vector<std::string> names;
    for (ClipLayer& L : rt.layers) {
        names.push_back(L.name);
        if (L.name != layer) continue;
        if (L.clipSeen == "states")
            return make_error(std::format("layer '{}' is driven by `states`", layer), "Change its state with a transition, or give the layer a plain `clip`.");
        if (clip.empty()) {
            L.player = ClipPlayer{};
            L.started = false;
        } else {
            auto bound = bind_clip(w, e, a, rt, std::string(clip));
            if (!bound) return bound.error();
            if (L.weight > 0.0f) {
                if (auto r = start_layer_clip(w, e, a, rt, L, std::string(clip), std::max(0.0f, fade), true); !r) return r.error();
                L.started = true;
            }
        }
        for (Json& cfg : a.layers)
            if (cfg.is_object() && jstr(cfg, "name") == L.name) cfg["clip"] = std::string(clip);
        L.config["clip"] = std::string(clip);
        L.clipSeen = "clip:" + std::string(clip);
        rt.layersSeen = a.layers;
        return {};
    }
    return make_error(std::format("the Animator has no layer '{}'", layer),
                      names.empty() ? "Declare it in `layers`: [{\"name\": \"" + std::string(layer) + "\", \"clip\": \"shoot\"}]."
                                    : did_you_mean(std::string(layer), names) + " Layers: " + join(names, ", ") + ".");
}

}  // namespace clipanim

// ======================================================================================================= the scene ====

PoseRest collect_pose_rest(const World& world) {
    PoseRest out;
    const TypeInfo* animType = TypeRegistry::global().of<Animator>();
    if (!animType) return out;
    for (Entity animEntity : world.entities_with(animType)) {
        const Animator* a = world.get<Animator>(animEntity);
        const ClipRuntime* rt = a ? a->rt.clip.get() : nullptr;
        if (!rt) continue;
        for (const ClipSlot& s : rt->slots) {
            if (s.dead || !world.alive(s.entity)) continue;
            const void* obj = world.get(s.entity, *s.type);
            if (!obj) continue;
            Json value;
            if (s.stepped) {
                value = s.restJson;
            } else {
                // The live field with the driven channels put back at rest, as the field's own JSON.
                DefaultObject scratch(*s.type);
                const float* live = static_cast<const float*>(s.field->ptr(obj));
                float* dst = static_cast<float*>(s.field->ptr(scratch.get()));
                for (unsigned c = 0; c < 4; ++c) {
                    if (c >= unsigned(field_floats(s.field->kind))) break;
                    dst[c] = (s.channels & (1u << c)) ? s.rest[c] : live[c];
                }
                value = field_to_json(*s.field, scratch.get());
            }
            out.entries.push_back({s.entity, s.type, s.field, std::move(value)});
        }
    }
    std::stable_sort(out.entries.begin(), out.entries.end(),
                     [](const PoseRestEntry& x, const PoseRestEntry& y) { return x.entity.bits() < y.entity.bits(); });
    return out;
}

}  // namespace fa
