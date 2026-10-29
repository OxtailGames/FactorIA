// The commands that look at clips and at the entities that play them: anim.list (clips, tracks, layers, current state),
// anim.pose (pose an entity as a clip is at a time), anim.filmstrip (a grid picture of a clip's poses, optionally with onion
// skin) and anim.check (what is wrong with a clip or with how it fits its character). The editing commands are in
// anim_commands.cpp.
//
// Posing changes the entity (the clip's fields, the bones, the IK); anim.pose keeps the pose on purpose, anim.filmstrip and
// anim.check put everything back where it was when they are done (PoseGuard).
#include <algorithm>
#include <cmath>
#include <format>
#include <map>
#include <set>

#include "engine_impl.h"
#include "fa/core/fs.h"
#include "fa/core/image_tools.h"
#include "fa/core/strings.h"
#include "fa/scene/animation.h"
#include "fa/scene/anim_clip.h"
#include "fa/scene/bones2d.h"
#include "fa/scene/bounds.h"

namespace fa {

namespace {

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

constexpr int kMaxFilmstripTiles = 64;
constexpr int kMaxSheetSide = 8192;
constexpr double kAutoSheetWidth = 1600;

std::string abs_path(const std::string& p) {
    if (fs::is_absolute(p)) return p;
    return fs::resolve(p).generic_string();
}

double round3(double v) { return std::round(v * 1000.0) / 1000.0; }

Animator& need_animator(Engine::Impl& I, Entity e, const char* command) {
    Animator* a = I.world.get<Animator>(e);
    if (!a)
        throw CommandError("invalid_argument", std::format("{}: '{}' has no Animator.", command, I.world.id_of(e)),
                           "Add one: scene.set_component {id, component: \"Animator\", fields: {clips: {\"walk\": \"anim/walk.anim.json\"}}}.");
    return *a;
}

// The Animator clip NAME for `clip`: a key of Animator.clips, or the file one of them names.
std::string clip_name_of(Entity e, const Animator& a, const Json& clip, const World& w) {
    if (!clip.is_string() || clip.get<std::string>().empty())
        throw CommandError("invalid_argument", "Missing `clip`.", "Pass a clip name of the Animator (anim.list shows them), e.g. \"walk\".");
    const std::string want = clip.get<std::string>();
    std::vector<std::string> names;
    if (a.clips.is_object())
        for (auto it = a.clips.begin(); it != a.clips.end(); ++it) {
            names.push_back(it.key());
            if (it.key() == want || (it.value().is_string() && it.value().get<std::string>() == want)) return it.key();
        }
    throw CommandError("not_found", std::format("'{}' has no clip '{}'. {}", w.id_of(e), want, did_you_mean(want, names)),
                       names.empty() ? "Its Animator.clips is empty: add {\"walk\": \"anim/walk.anim.json\"}." : "Its clips: " + join(names, ", ") + ".");
}

void collect_subtree(const World& w, Entity e, std::vector<Entity>& out) {
    out.push_back(e);
    for (Entity c : w.children(e)) collect_subtree(w, c, out);
}

std::string part_path(const World& w, Entity root, Entity e) {
    std::vector<std::string> names;
    for (Entity c = e; c != root && c != kNullEntity; c = w.parent(c)) names.push_back(w.info(c).name);
    std::reverse(names.begin(), names.end());
    return join(names, "/");
}

// Everything a posing session changes: the Animator's clip, time and playing, the fields the clips drive and the bones'
// Transform (the IK writes them). Put back by the destructor, so a failed command leaves the entity as it was.
class PoseGuard {
public:
    PoseGuard(World& w, Entity root, const std::vector<const ClipAsset*>& clips) : w_(w), root_(root) {
        Animator* a = w.get<Animator>(root);
        if (a) { clip_ = a->clip; time_ = a->time; playing_ = a->playing; hasAnimator_ = true; }
        std::vector<Entity> sub;
        collect_subtree(w, root, sub);
        std::set<std::pair<u64, const FieldInfo*>> seen;
        auto remember = [&](Entity e, const TypeInfo& type, const FieldInfo& f) {
            if (!seen.insert({e.bits(), &f}).second) return;
            if (const void* obj = std::as_const(w_).get(e, type)) saved_.push_back({e, &type, &f, field_to_json(f, obj)});
        };
        for (const ClipAsset* clip : clips)
            for (const ClipTrack& tr : clip->tracks) {
                auto part = resolve_clip_path(w, root, tr.path);
                if (part.ok() && tr.type && tr.info) remember(*part, *tr.type, *tr.info);
            }
        if (const TypeInfo* tt = TypeRegistry::global().of<Transform>())
            if (const FieldInfo *p = tt->field("position"), *r = tt->field("rotation"); p && r)
                for (Entity e : sub)
                    if (w.has<Bone2D>(e)) { remember(e, *tt, *p); remember(e, *tt, *r); }
    }
    ~PoseGuard() {
        for (const Saved& s : saved_)
            if (w_.alive(s.e))
                if (void* obj = w_.get(s.e, *s.type)) (void)field_from_json(*s.field, obj, s.value);
        Animator* a = w_.alive(root_) ? w_.get<Animator>(root_) : nullptr;
        if (a && hasAnimator_) {
            if (!clip_.empty() && a->clips.is_object() && a->clips.contains(clip_)) (void)animator_sample(w_, root_, clip_, time_);
            a->clip = clip_;
            a->time = time_;
            a->playing = playing_;
        }
    }
    PoseGuard(const PoseGuard&) = delete;
    PoseGuard& operator=(const PoseGuard&) = delete;

private:
    struct Saved {
        Entity e;
        const TypeInfo* type;
        const FieldInfo* field;
        Json value;
    };
    World& w_;
    Entity root_;
    std::vector<Saved> saved_;
    std::string clip_;
    float time_ = 0;
    bool playing_ = true, hasAnimator_ = false;
};

void pose_entity(World& w, Entity e, const std::string& clip, float t) {
    auto r = animator_sample(w, e, clip, t);
    if (!r.ok()) throw CommandError("invalid_argument", r.error().message, r.error().hint);
    bind_pending_skins(w);
    update_ik2d(w);
}

Json issues_to_json(const std::vector<ClipIssue>& issues) {
    Json arr = Json::array();
    for (const ClipIssue& i : issues) arr.push_back(Json::object({{"pointer", i.pointer}, {"message", i.message}, {"hint", i.hint}}));
    return arr;
}

std::shared_ptr<const ClipAsset> load_clip_or_throw(const std::string& file, const std::string& what) {
    std::vector<ClipIssue> issues;
    auto c = load_anim_clip(file, &issues);
    if (c.ok()) return *c;
    throw CommandError("invalid_argument", what + ": " + c.error().message, c.error().hint, Json::object({{"issues", issues_to_json(issues)}}));
}

std::string track_label(const ClipTrack& tr) {
    return (tr.path.empty() ? std::string("(the entity itself)") : tr.path) + " " + tr.component + "." + tr.spelled;
}

// Largest spread of any channel over the keys of a track.
double track_spread(const ClipTrack& tr) {
    double spread = 0;
    for (int c = 0; c < tr.channels; ++c) {
        double lo = 1e30, hi = -1e30;
        for (const ClipKey& k : tr.keys) { lo = std::min<double>(lo, k.value[std::size_t(c)]); hi = std::max<double>(hi, k.value[std::size_t(c)]); }
        spread = std::max(spread, hi - lo);
    }
    return spread;
}

double wrap180(double d) {
    d = std::fmod(d, 360.0);
    if (d > 180) d -= 360;
    if (d < -180) d += 360;
    return d;
}

Json clip_detail(const std::string& file, bool full) {
    Json j = Json::object({{"file", file}});
    std::vector<ClipIssue> issues;
    auto c = load_anim_clip(file, &issues);
    if (!c.ok()) {
        j["error"] = c.error().message;
        if (!c.error().hint.empty()) j["hint"] = c.error().hint;
        if (!issues.empty()) j["issues"] = issues_to_json(issues);
        return j;
    }
    const ClipAsset& clip = **c;
    j["duration"] = clip.duration;
    j["loop"] = clip.loop;
    if (!clip.doc.empty()) j["doc"] = clip.doc;
    Json tracks = Json::array();
    for (std::size_t i = 0; i < clip.tracks.size(); ++i) {
        const ClipTrack& tr = clip.tracks[i];
        tracks.push_back(Json::object({{"index", i}, {"path", tr.path}, {"component", tr.component}, {"field", tr.spelled}, {"keys", tr.keys.size()},
                                       {"first", tr.keys.front().t}, {"last", tr.keys.back().t}, {"stepped", tr.stepped}}));
    }
    j["tracks"] = tracks;
    Json events = Json::array();
    for (const ClipEvent& e : clip.events) events.push_back(Json::object({{"t", e.t}, {"name", e.name}}));
    j["events"] = events;
    if (full) {
        auto text = fs::read_text(file);
        if (text.ok())
            if (auto doc = parse_json(*text, file); doc.ok()) j["source"] = *doc;
    }
    return j;
}

struct Finding {
    std::string kind, severity, clip, track, part, message, hint;
    Json to_json() const {
        Json j = Json::object({{"kind", kind}, {"severity", severity}, {"clip", clip}});
        if (!track.empty()) j["track"] = track;
        if (!part.empty()) j["part"] = part;
        j["message"] = message;
        j["hint"] = hint;
        return j;
    }
};

// The checks that need only the clip.
void check_clip_alone(const std::string& label, const ClipAsset& clip, std::vector<Finding>& out) {
    const std::string file = clip.path.empty() ? label : clip.path;
    for (const ClipTrack& tr : clip.tracks) {
        const std::string name = track_label(tr);
        const std::string trackJson = std::format("{{\"path\":\"{}\",\"field\":\"{}\"}}", tr.path, tr.spelled);
        if (tr.keys.size() >= 2) {
            bool same = true;
            for (std::size_t i = 1; i < tr.keys.size() && same; ++i) {
                if (tr.stepped) same = tr.keys[i].raw == tr.keys[0].raw;
                else for (int c = 0; c < tr.channels; ++c)
                    if (std::fabs(tr.keys[i].value[std::size_t(c)] - tr.keys[0].value[std::size_t(c)]) > 1e-6f) same = false;
            }
            if (same)
                out.push_back({"no_change", "warning", label, name, tr.path,
                               std::format("The track {} has {} keys but every key holds the same value, so it changes nothing.", name, tr.keys.size()),
                               "Give one of its keys the pose you want, or remove the track: anim.remove_track {\"path\":\"" + file + "\",\"track\":" + trackJson + "}."});
        }
        if (clip.loop && !tr.stepped && tr.keys.size() >= 2 && clip.duration > 0) {
            std::array<float, 4> a{}, b{};
            const Json* raw = nullptr;
            sample_clip_track(tr, 0.0f, a, &raw);
            sample_clip_track(tr, clip.duration, b, &raw);
            double worst = 0;
            for (int c = 0; c < tr.channels; ++c) {
                const double d = tr.angle ? wrap180(double(b[std::size_t(c)]) - a[std::size_t(c)]) : double(b[std::size_t(c)]) - a[std::size_t(c)];
                if (std::fabs(d) > std::fabs(worst)) worst = d;
            }
            const double tol = std::max(1e-4, 0.02 * track_spread(tr));
            if (std::fabs(worst) > tol)
                out.push_back({"loop_jump", "warning", label, name, tr.path,
                               std::format("The clip loops but the track {} ends {} away from where it starts (at t={}: {}, at t=0: {}), so the loop snaps back every cycle.",
                                           name, round3(std::fabs(worst)), clip.duration, round3(b[0]), round3(a[0])),
                               std::format("Key t={} with the same value as t=0: anim.set_keys {{\"path\":\"{}\",\"track\":{},\"keys\":[{{\"t\":{},\"value\":<the value at t=0>}}]}}, or set loop false.",
                                           clip.duration, file, trackJson, clip.duration)});
        }
    }
}

// The orthographic world rectangle of the camera that draws the game, or nullopt (no camera, or a perspective one).
std::optional<Rect> camera_view_rect(Engine::Impl& I) {
    Entity best = kNullEntity;
    int bestDepth = 0;
    const TypeInfo* ct = TypeRegistry::global().of<Camera>();
    for (Entity e : I.world.entities_with(ct)) {
        const Camera* c = I.world.get<Camera>(e);
        if (!c || !c->primary || !I.world.active_in_hierarchy(e)) continue;
        if (best == kNullEntity || c->depth < bestDepth) { best = e; bestDepth = c->depth; }
    }
    if (best == kNullEntity) return std::nullopt;
    const Camera& c = *I.world.get<Camera>(best);
    if (c.projection != Projection::Orthographic) return std::nullopt;
    const Vec2 design = I.design_size();
    if (!(design.x > 0 && design.y > 0)) return std::nullopt;
    const float halfH = c.orthoSize > 0 ? c.orthoSize : design.y * 0.5f;
    const float halfW = halfH * design.x / design.y;
    const Vec3 p = I.world.world_position(best);
    return Rect{p.x - halfW, p.y - halfH, halfW * 2, halfH * 2};
}

bool rects_overlap(const Rect& a, const Rect& b) { return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h; }

// The checks that need the entity: parts, the camera and the IK.
void check_clip_on_entity(Engine::Impl& I, Entity root, const std::string& label, const std::string& animatorClip, const ClipAsset& clip,
                          int samples, std::vector<Finding>& out, std::vector<std::string>& notes) {
    World& w = I.world;
    std::set<std::size_t> badTracks;
    for (const ClipIssue& issue : check_clip_paths(w, root, clip)) {
        std::size_t index = 0;
        if (issue.pointer.rfind("/tracks/", 0) == 0) index = std::size_t(std::atoi(issue.pointer.c_str() + 8));
        index = std::min(index, clip.tracks.size() - 1);
        badTracks.insert(index);
        const ClipTrack& tr = clip.tracks[index];
        out.push_back({"unknown_part", "error", label, track_label(tr), tr.path, issue.message, issue.hint});
    }
    for (std::size_t i = 0; i < clip.tracks.size(); ++i) {
        if (badTracks.count(i)) continue;
        const ClipTrack& tr = clip.tracks[i];
        auto part = resolve_clip_path(w, root, tr.path);
        if (part.ok() && tr.type && !std::as_const(w).get(*part, *tr.type))
            out.push_back({"unknown_part", "error", label, track_label(tr), tr.path,
                           std::format("The part '{}' has no {} component, so the track {} drives nothing.", tr.path.empty() ? w.id_of(root) : tr.path, tr.component, track_label(tr)),
                           "Add the component to the part (scene.set_component), or change the track's component."});
    }
    if (!badTracks.empty()) {
        notes.push_back("Clip '" + label + "' has tracks that name no part, and the Animator refuses to pose it like that: the view and IK checks were skipped until they are fixed.");
        return;
    }
    if (animatorClip.empty()) {
        notes.push_back("Clip '" + label + "' is not one of the Animator's clips, so it was not posed: the view and IK checks were skipped. Add it to Animator.clips.");
        return;
    }
    std::vector<Entity> sub;
    collect_subtree(w, root, sub);
    // The parts to watch: what the tracks drive and everything below it.
    std::set<u64> watched;
    for (std::size_t i = 0; i < clip.tracks.size(); ++i) {
        if (badTracks.count(i)) continue;
        auto part = resolve_clip_path(w, root, clip.tracks[i].path);
        if (!part.ok()) continue;
        std::vector<Entity> below;
        collect_subtree(w, *part, below);
        for (Entity b : below) watched.insert(b.bits());
    }
    std::vector<Entity> iks;
    for (Entity e : sub)
        if (w.has<IK2D>(e)) iks.push_back(e);
    const std::optional<Rect> view = camera_view_rect(I);
    if (!view) notes.push_back("No orthographic primary Camera: the 'leaves the view' check was skipped.");
    struct Seen { bool in = false, out = false; double firstOut = -1, firstIn = -1; };
    std::map<u64, Seen> seen;
    struct Reach { double worst = 0, from = -1, to = -1; };
    std::map<u64, Reach> reach;
    const VisualMeasure measure = I.measure();
    PoseGuard guard(w, root, {&clip});
    const int n = std::max(2, samples);
    for (int s = 0; s <= n; ++s) {
        const float t = float(clip.duration * s / n);
        pose_entity(w, root, animatorClip, t);
        if (view)
            for (u64 bits : watched) {
                const Entity e = Entity::from_bits(bits);
                auto r = entity_world_rect(w, e, measure);
                if (!r || r->w <= 0 || r->h <= 0) continue;
                Seen& sn = seen[bits];
                if (rects_overlap(*r, *view)) { if (!sn.in) sn.firstIn = t; sn.in = true; }
                else { if (!sn.out) sn.firstOut = t; sn.out = true; }
            }
        for (Entity e : iks) {
            auto d = solve_ik2d(w, e);
            if (!d.ok()) continue;
            Reach& rc = reach[e.bits()];
            if (*d > 0.5) {
                if (rc.from < 0) rc.from = t;
                rc.to = t;
                rc.worst = std::max<double>(rc.worst, *d);
            }
        }
    }
    for (const auto& [bits, sn] : seen)
        if (sn.in && sn.out) {
            const Entity e = Entity::from_bits(bits);
            const std::string name = part_path(w, root, e);
            out.push_back({"leaves_view", "warning", label, "", name,
                           std::format("The part '{}' is in the camera view at t={} but completely outside it at t={}.", name.empty() ? w.id_of(root) : name, round3(sn.firstIn), round3(sn.firstOut)),
                           "Check the position/scale keys that move it (anim.pose then game.screenshot shows it), or move the camera. If it is meant to leave, ignore this."});
        }
    for (const auto& [bits, rc] : reach)
        if (rc.from >= 0) {
            const Entity e = Entity::from_bits(bits);
            const IK2D* ik = w.get<IK2D>(e);
            const std::string name = part_path(w, root, e);
            const std::string target = ik && w.alive(ik->target) ? w.info(ik->target).name : "target";
            out.push_back({"ik_out_of_reach", "warning", label, "", name,
                           std::format("The IK2D on '{}' cannot reach '{}' between t={} and t={}: it stops up to {} units short.", name, target, round3(rc.from), round3(rc.to), round3(rc.worst)),
                           "Move the target closer in the clip (animate its position), lengthen the bones (Bone2D.length) or raise IK2D.chainLength."});
        }
}

void grow_rect(std::optional<Rect>& acc, const Rect& r) {
    if (!acc) { acc = r; return; }
    const float x0 = std::min(acc->x, r.x), y0 = std::min(acc->y, r.y);
    const float x1 = std::max(acc->x + acc->w, r.x + r.w), y1 = std::max(acc->y + acc->h, r.y + r.h);
    acc = Rect{x0, y0, x1 - x0, y1 - y0};
}

}  // namespace

void register_anim_view_commands(Engine& engine, Engine::Impl& I) {
    I.commands.add({"anim.list", "List the 2D clips of an entity's Animator (or of a clip file): tracks, events, layers and the current state.",
           "With `entity`: its Animator's state (`clip`, `time`, `playing`, `state`, `speed`, `loop`), its `layers` and every clip of "
           "Animator.clips as {name, file, duration, loop, tracks: [{index, path, component, field, keys, first, last, stepped}], "
           "events: [{t, name}], problems}; `problems` lists tracks that name no part of this entity, and a clip file that does not "
           "load has `error` and `issues` instead. With `path`: the same description of one clip file (no entity). With neither: "
           "every Animator that plays clip files in the scene. `full: true` adds `source`, the whole file, for editors. The track "
           "`index` is what the anim.* editing commands accept as `track`. Example: anim.list {\"entity\":\"hero\"}",
           parse_schema(R"({"type":"object","properties":{
               "entity":{"type":"string","description":"Entity with the Animator (id or name)."},
               "path":{"type":"string","description":"A clip file to describe on its own."},
               "full":{"type":"boolean","default":false,"description":"Include `source`, the whole clip document."}}})"),
           true, "anim"},
          [&I](const Json& a) {
              const bool full = a.value("full", false);
              if (a.contains("path")) {
                  auto norm = fs::normalize_checked(a["path"].is_string() ? a["path"].get<std::string>() : std::string());
                  if (!norm.ok()) throw CommandError("invalid_argument", norm.error().message, norm.error().hint);
                  if (!fs::exists(*norm))
                      throw CommandError("not_found", "Clip file '" + *norm + "' does not exist.", "anim.create_clip {path, duration} makes one.");
                  return clip_detail(*norm, full);
              }
              auto describe = [&](Entity e) {
                  Animator& an = *I.world.get<Animator>(e);
                  Json j = Json::object({{"entity", I.world.id_of(e)}, {"name", I.world.info(e).name}, {"clip", an.clip}, {"time", an.time},
                                         {"playing", an.playing}, {"state", an.state}, {"speed", an.speed}, {"loop", an.loop}});
                  Json clips = Json::array();
                  if (an.clips.is_object())
                      for (auto it = an.clips.begin(); it != an.clips.end(); ++it) {
                          if (!it.value().is_string()) continue;
                          Json c = clip_detail(it.value().get<std::string>(), full);
                          c["name"] = it.key();
                          if (!c.contains("error")) {
                              auto asset = load_anim_clip(it.value().get<std::string>());
                              c["problems"] = asset.ok() ? issues_to_json(check_clip_paths(I.world, e, **asset)) : Json::array();
                          }
                          clips.push_back(std::move(c));
                      }
                  j["clips"] = clips;
                  j["layers"] = an.layers;
                  return j;
              };
              if (a.contains("entity")) {
                  const Entity e = need_entity(I.world, a, "entity");
                  need_animator(I, e, "anim.list");
                  return describe(e);
              }
              Json all = Json::array();
              for (Entity e : I.world.entities_with(TypeRegistry::global().of<Animator>())) {
                  const Animator* an = I.world.get<Animator>(e);
                  if (an && an->clips.is_object() && !an->clips.empty()) all.push_back(describe(e));
              }
              return Json::object({{"animators", all}});
          });

    I.commands.add({"anim.pose", "Pose an entity as one of its clips is at a time, and leave it there.",
           "`clip` is a name of Animator.clips (or the file one of them names), `t` seconds into it (clamped to the clip). The "
           "entity's parts, bones, skins and IK take that pose and the Animator pauses there until play() or a new `clip`; save the "
           "scene only if you want the pose kept. Result: {entity, clip, t, duration, values: [{track, value}]} with the sampled value of "
           "every track. Use it with game.screenshot to look at one pose, or anim.filmstrip to look at many. Example: "
           "anim.pose {\"entity\":\"hero\",\"clip\":\"walk\",\"t\":0.2}",
           parse_schema(R"({"type":"object","required":["entity","clip"],"properties":{
               "entity":{"type":"string","description":"Entity with the Animator (id or name)."},
               "clip":{"type":"string","description":"Clip name from Animator.clips, or its file."},
               "t":{"type":"number","minimum":0,"default":0,"description":"Seconds into the clip."}}})"),
           false, "anim"},
          [&I](const Json& a) {
              const Entity e = need_entity(I.world, a, "entity");
              Animator& an = need_animator(I, e, "anim.pose");
              const std::string name = clip_name_of(e, an, a.contains("clip") ? a["clip"] : Json(), I.world);
              const double t = a.value("t", 0.0);
              if (!(t >= 0)) throw CommandError("invalid_argument", "t must be 0 or more seconds.", "Seconds from the start of the clip.");
              auto asset = load_clip_or_throw(an.clips[name].get<std::string>(), "clip '" + name + "'");
              const float tc = float(std::min<double>(t, asset->duration));
              pose_entity(I.world, e, name, tc);
              Json values = Json::array();
              for (const ClipTrack& tr : asset->tracks) {
                  std::array<float, 4> v{};
                  const Json* raw = nullptr;
                  sample_clip_track(tr, tc, v, &raw);
                  Json value;
                  if (raw) value = *raw;
                  else if (tr.channels == 1) value = round3(v[0]);
                  else { value = Json::array(); for (int c = 0; c < tr.channels; ++c) value.push_back(round3(v[std::size_t(c)])); }
                  values.push_back(Json::object({{"track", track_label(tr)}, {"value", value}}));
              }
              return Json::object({{"entity", I.world.id_of(e)}, {"clip", name}, {"t", tc}, {"duration", asset->duration}, {"values", values}});
          });

    I.commands.add({"anim.filmstrip", "One picture with a grid of a clip's poses, to see the whole motion at once.",
           "Poses the entity as `clip` at `frames` evenly spaced times (a looping clip: 0, d/n, ... never the duplicate end pose; "
           "otherwise 0 .. duration) and captures each, into one labelled grid PNG (label \"f3 +250\" = pose 3, 250 ms into the clip). "
           "The game is not stepped: only the pose changes, and the entity is put back as it was afterwards. By default the view is the "
           "box around the entity's visuals over all poses (plus a margin), magnified so the sheet is about 1600 px wide; `region` "
           "[x, y, width, height] (design pixels) and `zoom` override it. `onionSkin: true` draws each pose over faint copies of the "
           "previous and next ones, so a stride or a swing shows its arc and a jump between two poses shows as a double image. At "
           "most 64 poses, a sheet at most 8192 px a side. Needs graphics. Without `path` the picture is temporary (the MCP server "
           "shows it then deletes the file); with `path` it is kept. Result: {width, height, frames: [{index, t}], columns, rows, "
           "tileWidth, tileHeight, zoom, region, $image}. Example: anim.filmstrip {\"entity\":\"hero\",\"clip\":\"walk\",\"frames\":8,\"onionSkin\":true}",
           parse_schema(R"({"type":"object","required":["entity","clip"],"properties":{
               "entity":{"type":"string","description":"Entity with the Animator (id or name)."},
               "clip":{"type":"string","description":"Clip name from Animator.clips, or its file."},
               "frames":{"type":"integer","minimum":1,"maximum":64,"default":8,"description":"Number of poses."},
               "columns":{"type":"integer","minimum":1,"maximum":64,"description":"Tiles per row (default: nearly square)."},
               "onionSkin":{"type":"boolean","default":false,"description":"Draw faint copies of the neighbouring poses under each pose."},
               "region":{"type":"array","items":{"type":"number"},"minItems":4,"maxItems":4,"description":"[x, y, width, height] in design pixels; default: around the character."},
               "zoom":{"type":"number","minimum":0.25,"maximum":32,"description":"Magnification of the region (default: a sheet about 1600 px wide)."},
               "path":{"type":"string","description":"Keep the PNG here (project-relative or absolute)."}}})"),
           true, "anim"},
          [&engine, &I](const Json& a) {
              const Entity e = need_entity(I.world, a, "entity");
              Animator& an = need_animator(I, e, "anim.filmstrip");
              const std::string name = clip_name_of(e, an, a.contains("clip") ? a["clip"] : Json(), I.world);
              if (!I.renderer || !I.renderer->initialized())
                  throw CommandError("unavailable", "No renderer: the engine runs with graphics=false.", "anim.filmstrip needs graphics (headless needs Mesa/EGL). anim.pose + anim.check work without.");
              auto asset = load_clip_or_throw(an.clips[name].get<std::string>(), "clip '" + name + "'");
              const int count = a.value("frames", 8);
              if (count < 1 || count > kMaxFilmstripTiles)
                  throw CommandError("invalid_argument", std::format("frames {} is out of range (1 to {}).", count, kMaxFilmstripTiles), "A sheet holds at most 64 poses: use 8 to 16 for a cycle.");
              const bool onion = a.value("onionSkin", false);
              std::vector<float> times;
              for (int i = 0; i < count; ++i) {
                  const double d = asset->duration;
                  times.push_back(float(asset->loop ? d * i / count : (count > 1 ? d * i / (count - 1) : 0.0)));
              }
              PoseGuard guard(I.world, e, {asset.get()});
              const Vec2 view{float(I.renderer->target_width()), float(I.renderer->target_height())};
              Rect region{};
              if (a.contains("region")) {
                  std::string err;
                  if (!json_to(a["region"], region, &err)) throw CommandError("invalid_argument", "region: " + err, "Use [x, y, width, height] in design pixels.");
                  if (!(region.w > 0 && region.h > 0)) throw CommandError("invalid_argument", "region has no area.", "Width and height must be above 0.");
              } else {
                  std::vector<Entity> sub;
                  collect_subtree(I.world, e, sub);
                  std::optional<Rect> box;
                  const VisualMeasure measure = I.measure();
                  for (float t : times) {
                      pose_entity(I.world, e, name, t);
                      for (Entity p : sub)
                          if (auto r = entity_world_rect(I.world, p, measure))
                              for (const Vec2 c : {Vec2{r->x, r->y}, Vec2{r->x + r->w, r->y + r->h}, Vec2{r->x, r->y + r->h}, Vec2{r->x + r->w, r->y}}) {
                                  const Vec2 s = I.renderer->world_to_screen(Vec3{c.x, c.y, 0});
                                  grow_rect(box, Rect{s.x, s.y, 0, 0});
                              }
                  }
                  if (box) {
                      const float m = 8;
                      const float x0 = std::max(0.0f, box->x - m), y0 = std::max(0.0f, box->y - m);
                      const float x1 = std::min(view.x, box->x + box->w + m), y1 = std::min(view.y, box->y + box->h + m);
                      if (x1 - x0 >= 1 && y1 - y0 >= 1) region = Rect{x0, y0, x1 - x0, y1 - y0};
                  }
              }
              const int wanted = a.value("columns", 0);
              const auto at1 = Engine::plan_region(view, region, 1.0);
              if (!at1.error.empty()) throw CommandError("invalid_argument", at1.error, "See the `region` argument of game.screenshot.");
              double zoom = 1.0;
              if (a.contains("zoom")) zoom = a.value("zoom", 1.0);
              else zoom = std::clamp(kAutoSheetWidth / std::max(1, sheet_layout(count, wanted, at1.width, at1.height).width), 0.25, 4.0);
              const auto plan = Engine::plan_region(view, region, zoom);
              if (!plan.error.empty()) throw CommandError("invalid_argument", plan.error, "See the `region` and `zoom` arguments.");
              const SheetLayout predicted = sheet_layout(count, wanted, plan.width, plan.height);
              if (predicted.width > kMaxSheetSide || predicted.height > kMaxSheetSide)
                  throw CommandError("invalid_argument", std::format("The sheet would be {}x{} px, over the 8192 px limit per side.", predicted.width, predicted.height),
                                     "Use a smaller zoom or region, more columns, or fewer frames.");
              std::vector<Image> shots;
              std::vector<std::string> labels;
              Json frames = Json::array();
              std::string err;
              for (int i = 0; i < count; ++i) {
                  pose_entity(I.world, e, name, times[std::size_t(i)]);
                  Image tile;
                  if (!engine.capture_region(tile, region, zoom, &err)) throw CommandError("unavailable", err, "Screenshots need graphics (headless needs Mesa/EGL).");
                  shots.push_back(std::move(tile));
                  const int ms = int(std::lround(times[std::size_t(i)] * 1000.0));
                  labels.push_back("f" + std::to_string(i) + " +" + std::to_string(ms));
                  frames.push_back(Json::object({{"index", i}, {"t", round3(times[std::size_t(i)])}}));
              }
              if (onion && count > 1) {
                  std::vector<Image> blended = shots;
                  for (int i = 0; i < count; ++i) {
                      Image& out = blended[std::size_t(i)];
                      for (int off : {-1, 1}) {
                          int j = i + off;
                          if (asset->loop) j = (j + count) % count;
                          if (j < 0 || j >= count) continue;
                          const Image& other = shots[std::size_t(j)];
                          if (other.width != out.width || other.height != out.height) continue;
                          for (std::size_t p = 0; p + 3 < out.rgba.size(); p += 4)
                              for (std::size_t c = 0; c < 3; ++c)
                                  out.rgba[p + c] = std::uint8_t(std::lround(out.rgba[p + c] * 0.75 + other.rgba[p + c] * 0.25));
                      }
                  }
                  shots = std::move(blended);
              }
              SheetLayout l;
              Image img = contact_sheet(shots, labels, wanted, -1, &l);
              const bool temporary = !(a.contains("path") && a["path"].is_string() && !a["path"].get<std::string>().empty());
              const std::string path = temporary ? ".factoria/screenshots/frame_" + std::to_string(I.frame) + "_anim.png" : a["path"].get<std::string>();
              auto saved = save_png(img, path);
              if (!saved.ok()) throw CommandError("unavailable", saved.error().message, saved.error().hint.empty() ? "Check the path is inside a writable folder." : saved.error().hint);
              const std::string abs = abs_path(path);
              Json j = Json::object();
              if (!temporary) j["path"] = abs;
              j["width"] = img.width;
              j["height"] = img.height;
              j["frames"] = frames;
              j["columns"] = l.columns;
              j["rows"] = l.rows;
              j["tileWidth"] = l.tileWidth;
              j["tileHeight"] = l.tileHeight;
              j["zoom"] = zoom;
              j["region"] = Json::array({plan.x0, plan.y0, plan.x1 - plan.x0, plan.y1 - plan.y0});
              Json image = Json::object({{"path", abs}, {"mimeType", "image/png"}});
              if (temporary) {
                  j["temporary"] = true;
                  j["note"] = "Temporary picture: whoever shows it deletes the file. Pass `path` to keep it.";
                  image["temporary"] = true;
              }
              j["$image"] = image;
              return j;
          });

    I.commands.add({"anim.check", "Find what is wrong with a clip, and with how it fits its character.",
           "Checks clips and returns {checked, findings, ok, samples, notes}. Each finding is {kind, severity, clip, track?, part?, "
           "message, hint}: it names the track or part and says how to fix it. Kinds: `no_change` (a track whose keys all hold one "
           "value), `loop_jump` (a looping clip whose last pose differs from its first, so it snaps every cycle; angles take the "
           "short way round), `unknown_part` (a track that names no part of the entity, or a part without the component), "
           "`leaves_view` (a part that is in the camera view in some poses and completely outside it in others), "
           "`ik_out_of_reach` (an IK2D whose target cannot be reached in some poses) and `invalid_clip` (the file does not load). With "
           "`path` alone only the first two run (the clip file alone); with `entity` the clip is also posed `samples` times along its "
           "length (the entity is put back as it was) for the rest, and all of the Animator's clips are checked unless `clip` names "
           "one. Example: anim.check {\"entity\":\"hero\"} or anim.check {\"path\":\"anim/hero_walk.anim.json\"}",
           parse_schema(R"({"type":"object","properties":{
               "entity":{"type":"string","description":"Entity with the Animator whose clips to check (id or name)."},
               "path":{"type":"string","description":"One clip file to check (with `entity`: checked against that entity)."},
               "clip":{"type":"string","description":"With `entity`: check only this clip of Animator.clips."},
               "samples":{"type":"integer","minimum":2,"maximum":240,"default":24,"description":"Poses to check along the clip."}}})"),
           false, "anim"},
          [&I](const Json& a) {
              if (!a.contains("entity") && !a.contains("path"))
                  throw CommandError("invalid_argument", "Pass `entity` (its Animator's clips) and/or `path` (a clip file).", "Example: anim.check {\"entity\":\"hero\"}.");
              const int samples = a.value("samples", 24);
              if (samples < 2 || samples > 240) throw CommandError("invalid_argument", "samples must be between 2 and 240.", "24 is enough for a walk cycle.");
              std::vector<Finding> findings;
              std::vector<std::string> notes;
              Json checked = Json::array();
              Entity root = kNullEntity;
              Animator* an = nullptr;
              if (a.contains("entity")) {
                  root = need_entity(I.world, a, "entity");
                  an = &need_animator(I, root, "anim.check");
              }
              struct Item { std::string label, file, animatorClip; };
              std::vector<Item> items;
              if (a.contains("path")) {
                  auto norm = fs::normalize_checked(a["path"].is_string() ? a["path"].get<std::string>() : std::string());
                  if (!norm.ok()) throw CommandError("invalid_argument", norm.error().message, norm.error().hint);
                  if (!fs::exists(*norm)) throw CommandError("not_found", "Clip file '" + *norm + "' does not exist.", "anim.create_clip {path, duration} makes one.");
                  Item it{*norm, *norm, ""};
                  if (an && an->clips.is_object())
                      for (auto c = an->clips.begin(); c != an->clips.end(); ++c)
                          if (c.value().is_string() && c.value().get<std::string>() == *norm) it.animatorClip = c.key();
                  items.push_back(it);
              } else {
                  if (a.contains("clip")) {
                      const std::string n = clip_name_of(root, *an, a["clip"], I.world);
                      items.push_back({n, an->clips[n].get<std::string>(), n});
                  } else if (an->clips.is_object()) {
                      for (auto c = an->clips.begin(); c != an->clips.end(); ++c)
                          if (c.value().is_string()) items.push_back({c.key(), c.value().get<std::string>(), c.key()});
                  }
                  if (items.empty()) notes.push_back("The Animator has no 2D clips in `clips`: nothing to check.");
              }
              for (const Item& item : items) {
                  checked.push_back(item.label);
                  std::vector<ClipIssue> issues;
                  auto clip = load_anim_clip(item.file, &issues);
                  if (!clip.ok()) {
                      std::string detail = clip.error().message;
                      for (const ClipIssue& i : issues) detail += "\n  " + i.pointer + ": " + i.message;
                      findings.push_back({"invalid_clip", "error", item.label, "", "", detail, clip.error().hint.empty() ? "Fix the file; anim.list {path} shows what loads." : clip.error().hint});
                      continue;
                  }
                  check_clip_alone(item.label, **clip, findings);
                  if (root != kNullEntity) check_clip_on_entity(I, root, item.label, item.animatorClip, **clip, samples, findings, notes);
              }
              Json list = Json::array();
              for (const Finding& f : findings) list.push_back(f.to_json());
              return Json::object({{"checked", checked}, {"findings", list}, {"ok", findings.empty()}, {"samples", root != kNullEntity ? samples : 0}, {"notes", notes}});
          });
}

}  // namespace fa
