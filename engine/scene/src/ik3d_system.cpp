// The IK3D component's system: parses the `solvers` of an IK3D, runs them on the pose the Animator just built and writes the
// Animator's palettes again (docs/ANIMATION.md, "3D IK"). The maths is in ik3d.cpp.
#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/det_math.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/scene/animation.h"
#include "fa/scene/components.h"
#include "fa/scene/ik3d.h"

namespace fa {

namespace {

const std::vector<std::string> kTypes = {"twoBone", "lookAt", "foot"};

// Where a solver aims: an entity (its world position plus a world-space offset), or a fixed world position.
struct TargetSpec {
    bool set = false;
    std::string entity;
    Vec3 offset{0, 0, 0};
};

struct Solver {
    std::string type, name;
    float weight = 1.0f;
    bool enabled = true;
    int a = -1, b = -1, c = -1;  // twoBone: root, mid, end; foot: thigh, shin, foot; lookAt: a = bone
    TargetSpec target, pole;
    Vec3 forward{0, 0, 1};
    float yawLimit = 70.0f, pitchLimit = 45.0f, turnSpeed = 360.0f;
    float footHeight = -1.0f;  // < 0 = the rest height of the foot bone above the model's origin
    bool alignToGround = true;
    float maxFootAngle = 30.0f;
};

struct Reader {
    std::vector<IKIssue>& issues;
    std::string pointer;
    void err(const std::string& key, std::string message, std::string hint = {}) {
        issues.push_back({pointer + (key.empty() ? "" : "/" + key), std::move(message), std::move(hint)});
    }
    bool number(const Json& o, const char* key, float& out, float lo, float hi) {
        auto it = o.find(key);
        if (it == o.end()) return true;
        if (!it->is_number() || !std::isfinite(it->get<double>())) {
            err(key, std::format("'{}' must be a number, got {}", key, describe_json_value(*it)),
                std::format("Write a number from {} to {}.", lo, hi));
            return false;
        }
        const float v = it->get<float>();
        if (v < lo || v > hi) {
            err(key, std::format("'{}' is {} but must be from {} to {}", key, v, lo, hi),
                "Use a value inside that range.");
            return false;
        }
        out = v;
        return true;
    }
    bool boolean(const Json& o, const char* key, bool& out) {
        auto it = o.find(key);
        if (it == o.end()) return true;
        if (!it->is_boolean()) {
            err(key, std::format("'{}' must be true or false, got {}", key, describe_json_value(*it)),
                "Write true or false.");
            return false;
        }
        out = it->get<bool>();
        return true;
    }
};

bool read_vec3(const Json& j, Vec3& out) {
    if (!j.is_array() || j.size() != 3) return false;
    float v[3];
    for (std::size_t i = 0; i < 3; ++i) {
        if (!j[i].is_number()) return false;
        v[i] = j[i].get<float>();
        if (!std::isfinite(v[i])) return false;
    }
    out = {v[0], v[1], v[2]};
    return true;
}

// A target is an entity id or name ("player"), a world position [x, y, z], or {"entity": "player", "offset": [x, y, z]}.
bool parse_target(const Json& j, TargetSpec& out, Reader& rd, const char* key) {
    out = {};
    if (j.is_string()) {
        out.entity = j.get<std::string>();
        out.set = !out.entity.empty();
        if (!out.set)
            rd.err(key, std::format("'{}' is an empty string", key),
                   "Name the entity to aim at, or give a position [x, y, z].");
        return out.set;
    }
    Vec3 p;
    if (read_vec3(j, p)) {
        out.offset = p;
        out.set = true;
        return true;
    }
    if (j.is_object()) {
        auto e = j.find("entity");
        if (e == j.end() || !e->is_string() || e->get<std::string>().empty()) {
            rd.err(std::string(key) + "/entity", std::format("'{}' as an object needs a string 'entity'", key),
                   "Write {\"entity\": \"player\", \"offset\": [0, 1.6, 0]}.");
            return false;
        }
        out.entity = e->get<std::string>();
        auto o = j.find("offset");
        if (o != j.end() && !read_vec3(*o, out.offset)) {
            rd.err(std::string(key) + "/offset", "'offset' must be an array of 3 numbers",
                   "Write [x, y, z] in world units.");
            return false;
        }
        for (auto it = j.begin(); it != j.end(); ++it)
            if (it.key() != "entity" && it.key() != "offset")
                rd.err(std::string(key) + "/" + it.key(), "unknown key '" + it.key() + "'",
                       did_you_mean(it.key(), std::vector<std::string>{"entity", "offset"}));
        out.set = true;
        return true;
    }
    rd.err(key,
           std::format("'{}' must be an entity id or name, a position [x, y, z] or {{\"entity\", \"offset\"}}, got {}",
                       key, describe_json_value(j)),
           "Write \"player\", [0, 1, 3] or {\"entity\": \"player\", \"offset\": [0, 1.6, 0]}.");
    return false;
}

int chain_first(const Rig3D& rig, const char* role, const std::string& side) {
    auto c = rig.chain(role, side);
    return c.empty() ? -1 : c.front();
}

// Resolves a bone given by name; reports unknown names with "did you mean" when a rig is known.
bool bone_by_name(const Rig3D* rig, const Json& o, const char* key, int& out, Reader& rd, bool required) {
    auto it = o.find(key);
    if (it == o.end()) {
        if (required)
            rd.err("", std::format("missing '{}' (a bone name)", key),
                   "Name the bone, e.g. \"" + std::string(key) + "\": \"arm_upper_l\".");
        return !required;
    }
    if (!it->is_string()) {
        rd.err(key, std::format("'{}' must be a bone name, got {}", key, describe_json_value(*it)),
               "Write a string such as \"hand_l\".");
        return false;
    }
    if (!rig) return true;
    out = rig->find(it->get<std::string>());
    if (out < 0) {
        const auto names = rig->bone_names();
        rd.err(key, std::format("'{}' is not a bone of this skeleton", it->get<std::string>()),
               did_you_mean(it->get<std::string>(), names));
        return false;
    }
    return true;
}

bool parse_side(const Json& o, std::string& side, Reader& rd) {
    side.clear();
    auto it = o.find("side");
    if (it == o.end()) return true;
    if (!it->is_string() || (it->get<std::string>() != "l" && it->get<std::string>() != "r")) {
        rd.err("side", std::format("'side' must be \"l\" or \"r\", got {}", describe_json_value(*it)),
               "l is character-left (+X), r character-right.");
        return false;
    }
    side = it->get<std::string>();
    return true;
}

bool parse_solver(const Json& o, const Rig3D* rig, Solver& s, Reader& rd) {
    if (!o.is_object()) {
        rd.err("", std::format("a solver must be an object, got {}", describe_json_value(o)),
               "Write {\"type\": \"lookAt\", \"bone\": \"head\", \"target\": \"player\"}.");
        return false;
    }
    auto t = o.find("type");
    if (t == o.end() || !t->is_string() ||
        std::find(kTypes.begin(), kTypes.end(), t->get<std::string>()) == kTypes.end()) {
        rd.err("type", t == o.end() ? "missing 'type'" : std::format("unknown solver type {}", describe_json_value(*t)),
               t != o.end() && t->is_string() ? did_you_mean(t->get<std::string>(), kTypes)
                                              : "Use \"twoBone\", \"lookAt\" or \"foot\".");
        return false;
    }
    s.type = t->get<std::string>();
    std::vector<std::string> allowed = {"type", "name", "weight", "enabled"};
    if (s.type == "twoBone")
        for (auto k : {"root", "mid", "end", "limb", "side", "target", "pole"}) allowed.push_back(k);
    if (s.type == "lookAt")
        for (auto k : {"bone", "target", "forward", "yawLimit", "pitchLimit", "turnSpeed"}) allowed.push_back(k);
    if (s.type == "foot")
        for (auto k : {"thigh", "shin", "foot", "side", "footHeight", "alignToGround", "maxFootAngle"})
            allowed.push_back(k);
    bool ok = true;
    for (auto it = o.begin(); it != o.end(); ++it)
        if (std::find(allowed.begin(), allowed.end(), it.key()) == allowed.end()) {
            rd.err(it.key(), "unknown key '" + it.key() + "' for a " + s.type + " solver",
                   did_you_mean(it.key(), allowed));
            ok = false;
        }
    if (auto n = o.find("name"); n != o.end()) {
        if (n->is_string())
            s.name = n->get<std::string>();
        else {
            rd.err("name", "'name' must be a string", "Write a label such as \"left arm\".");
            ok = false;
        }
    }
    ok &= rd.number(o, "weight", s.weight, 0.0f, 1.0f);
    ok &= rd.boolean(o, "enabled", s.enabled);
    std::string side;
    if (s.type == "twoBone") {
        ok &= parse_side(o, side, rd);
        auto limb = o.find("limb");
        if (limb != o.end()) {
            const std::string l = limb->is_string() ? limb->get<std::string>() : "";
            if (l != "arm" && l != "leg") {
                rd.err("limb", std::format("'limb' must be \"arm\" or \"leg\", got {}", describe_json_value(*limb)),
                       "arm = arm_upper, arm_lower, hand (the front leg of a quadruped too); leg = thigh, shin, foot.");
                ok = false;
            } else if (side.empty()) {
                rd.err("side", "'limb' needs a 'side' (\"l\" or \"r\")", "Add \"side\": \"l\".");
                ok = false;
            } else if (rig) {
                s.a = chain_first(*rig, l == "arm" ? "arm_upper" : "thigh", side);
                s.b = chain_first(*rig, l == "arm" ? "arm_lower" : "shin", side);
                s.c = chain_first(*rig, l == "arm" ? "hand" : "foot", side);
                if (s.a < 0 || s.b < 0 || s.c < 0) {
                    rd.err("limb", std::format("this skeleton has no {} on side '{}'", l, side),
                           "Name the bones with root, mid and end instead.");
                    ok = false;
                }
            }
        } else {
            ok &= bone_by_name(rig, o, "root", s.a, rd, true);
            ok &= bone_by_name(rig, o, "mid", s.b, rd, true);
            ok &= bone_by_name(rig, o, "end", s.c, rd, true);
        }
        if (auto tg = o.find("target"); tg != o.end())
            ok &= parse_target(*tg, s.target, rd, "target");
        else {
            rd.err("", "missing 'target' (what the end of the limb reaches)",
                   "Write \"target\": \"ball\" or [x, y, z].");
            ok = false;
        }
        if (auto pl = o.find("pole"); pl != o.end()) ok &= parse_target(*pl, s.pole, rd, "pole");
    } else if (s.type == "lookAt") {
        ok &= bone_by_name(rig, o, "bone", s.a, rd, true);
        if (auto tg = o.find("target"); tg != o.end())
            ok &= parse_target(*tg, s.target, rd, "target");
        else {
            rd.err("", "missing 'target' (what the bone looks at)", "Write \"target\": \"player\" or [x, y, z].");
            ok = false;
        }
        if (auto f = o.find("forward"); f != o.end()) {
            Vec3 v;
            if (f->is_string() && parse_axis_name(f->get<std::string>(), v))
                s.forward = v;
            else if (read_vec3(*f, v) && length_sq(v) > 1e-8f)
                s.forward = normalize(v);
            else {
                rd.err("forward", "'forward' must be an axis name (\"+z\", \"-x\", \"y\") or a direction [x, y, z]",
                       "It is the bone's own axis that looks at the target; heads built by rig.bake look along +z.");
                ok = false;
            }
        }
        ok &= rd.number(o, "yawLimit", s.yawLimit, 0.0f, 180.0f);
        ok &= rd.number(o, "pitchLimit", s.pitchLimit, 0.0f, 90.0f);
        ok &= rd.number(o, "turnSpeed", s.turnSpeed, 0.0f, 100000.0f);
    } else {
        ok &= parse_side(o, side, rd);
        const bool anyName = o.contains("thigh") || o.contains("shin") || o.contains("foot");
        if (anyName) {
            ok &= bone_by_name(rig, o, "thigh", s.a, rd, true);
            ok &= bone_by_name(rig, o, "shin", s.b, rd, true);
            ok &= bone_by_name(rig, o, "foot", s.c, rd, true);
        } else if (side.empty()) {
            rd.err("", "a foot solver needs 'side' (\"l\" or \"r\") or the bones 'thigh', 'shin' and 'foot'",
                   "Write {\"type\": \"foot\", \"side\": \"l\"}.");
            ok = false;
        } else if (rig) {
            s.a = chain_first(*rig, "thigh", side);
            s.b = chain_first(*rig, "shin", side);
            s.c = chain_first(*rig, "foot", side);
            if (s.a < 0 || s.b < 0 || s.c < 0) {
                rd.err("side", std::format("this skeleton has no leg (thigh, shin, foot) on side '{}'", side),
                       "Name the bones with thigh, shin and foot.");
                ok = false;
            }
        }
        ok &= rd.number(o, "footHeight", s.footHeight, 0.0f, 100.0f);
        ok &= rd.boolean(o, "alignToGround", s.alignToGround);
        ok &= rd.number(o, "maxFootAngle", s.maxFootAngle, 0.0f, 90.0f);
    }
    if (ok && rig && s.type != "lookAt") {
        const SkeletonAsset& sk = *rig->skeleton;
        if (sk.nodes[std::size_t(s.b)].parent != s.a || sk.nodes[std::size_t(s.c)].parent != s.b) {
            rd.err("",
                   std::format("the bones '{}', '{}', '{}' are not a chain (each must be the child of the one before)",
                               sk.nodes[std::size_t(s.a)].name, sk.nodes[std::size_t(s.b)].name,
                               sk.nodes[std::size_t(s.c)].name),
                   "Name three bones where each is the child of the previous one.");
            ok = false;
        }
    }
    return ok;
}

std::string entity_label(World& w, Entity e) { return w.id_of(e); }

float smoothstep01(float x) {
    x = clamp(x, 0.0f, 1.0f);
    return x * x * (3.0f - 2.0f * x);
}

struct Context {
    World& w;
    Entity e;
    IK3D& ik;
    Animator& anim;
    const Rig3D& rig;
    Mat4 toWorld, toModel;
    float dt;
    const GroundRaycast& ground;
};

std::optional<Vec3> resolve_world(Context& c, const TargetSpec& t) {
    if (!t.set) return std::nullopt;
    if (t.entity.empty()) return t.offset;
    const Entity en = c.w.find(t.entity);
    if (en == kNullEntity || !c.w.alive(en)) return std::nullopt;
    return c.w.world_position(en) + t.offset;
}

std::optional<Vec3> resolve_model(Context& c, const TargetSpec& t) {
    auto p = resolve_world(c, t);
    if (!p) return std::nullopt;
    return c.toModel.transform_point(*p);
}

std::string label(const Solver& s, std::size_t i) { return s.name.empty() ? std::format("{}[{}]", s.type, i) : s.name; }

Json status_entry(const Solver& s, std::size_t i, bool active) {
    Json j = Json::object();
    j["name"] = label(s, i);
    j["type"] = s.type;
    j["active"] = active;
    return j;
}

}  // namespace

std::vector<IKIssue> ik3d_check_solvers(const Json& solvers, const Rig3D* rig) {
    std::vector<IKIssue> issues;
    if (solvers.is_null()) return issues;
    if (!solvers.is_array()) {
        issues.push_back({"", std::format("'solvers' must be an array, got {}", describe_json_value(solvers)),
                          "Write [{\"type\": \"lookAt\", \"bone\": \"head\", \"target\": \"player\"}]."});
        return issues;
    }
    for (std::size_t i = 0; i < solvers.size(); ++i) {
        Solver s;
        Reader rd{issues, "/" + std::to_string(i)};
        parse_solver(solvers[i], rig, s, rd);
    }
    return issues;
}

void update_ik3d(World& world, float dt, const GroundRaycast& ground) {
    for (Entity e : world.entities_with(&World::type_of<IK3D>())) {
        if (!world.alive(e) || !world.active_in_hierarchy(e)) continue;
        IK3D* ik = world.get<IK3D>(e);
        Animator* an = world.get<Animator>(e);
        if (!ik || !an || !an->rt.skeleton) continue;
        const SkeletonAsset& sk = *an->rt.skeleton;
        if (an->rt.pose.rotation.size() != sk.nodes.size() || sk.nodes.empty()) continue;
        const bool wanted = ik->enabled && ik->weight > 0.0f && ik->solvers.is_array() && !ik->solvers.empty();
        if (!wanted) {
            if (ik->rt.started) {  // the last step drew a solved pose: draw the animated one again
                animator_apply_pose(*an, an->rt.pose);
                ik->rt = {};
                ik->status = Json::array();
            }
            continue;
        }
        const Rig3D rig = make_rig3d(sk, 0);
        std::vector<IKIssue> issues;
        std::vector<Solver> solvers(ik->solvers.size());
        std::vector<bool> valid(solvers.size(), false);
        for (std::size_t i = 0; i < solvers.size(); ++i) {
            Reader rd{issues, "/" + std::to_string(i)};
            valid[i] = parse_solver(ik->solvers[i], &rig, solvers[i], rd);
        }
        if (!issues.empty() && !ik->rt.warned) {
            ik->rt.warned = true;
            const IKIssue& is = issues.front();
            FA_WARN("animation", "IK3D on '{}': solvers{}: {}. {}{}", entity_label(world, e), is.pointer, is.message,
                    is.hint,
                    issues.size() > 1 ? std::format(" ({} more problems; ik3d.check lists them all)", issues.size() - 1)
                                      : "");
        }
        Context c{world, e, *ik, *an, rig, world.world_matrix(e), {}, dt, ground};
        c.toModel = c.toWorld.inverse();
        Pose pose = an->rt.pose;
        const float masterWeight = clamp(ik->weight, 0.0f, 1.0f);
        ik->rt.turn.resize(solvers.size());
        ik->rt.lift.resize(solvers.size(), 0.0f);
        Json status = Json::array();
        for (std::size_t i = 0; i < solvers.size(); ++i) status.push_back(Json::object());
        PoseFrame frame = pose_frame(sk, pose);
        bool feetDone = false;

        for (std::size_t i = 0; i < solvers.size(); ++i) {
            const Solver& s = solvers[i];
            if (!valid[i]) {
                status[i] = status_entry(s, i, false);
                status[i]["problem"] = true;
                continue;
            }
            if (!s.enabled) {
                status[i] = status_entry(s, i, false);
                continue;
            }
            const float weight = s.weight * masterWeight;
            if (s.type == "twoBone") {
                auto target = resolve_model(c, s.target);
                Json st = status_entry(s, i, target.has_value() && weight > 0.0f);
                if (target && weight > 0.0f) {
                    auto pole = resolve_model(c, s.pole);
                    auto r = solve_two_bone(sk, pose, s.a, s.b, s.c, *target, pole, weight);
                    if (r) {
                        st["reached"] = r->reached;
                        st["error"] = r->error;
                    }
                    refresh_frame(sk, pose, frame);
                }
                status[i] = st;
            } else if (s.type == "lookAt") {
                auto target = resolve_model(c, s.target);
                Json st = status_entry(s, i, target.has_value() && weight > 0.0f);
                LookAtParams p;
                p.forward = s.forward;
                p.yawLimit = s.yawLimit;
                p.pitchLimit = s.pitchLimit;
                p.weight = target ? weight : 0.0f;  // no target: the head eases back to the animated aim
                p.maxTurn = s.turnSpeed > 0.0f ? radians(s.turnSpeed) * dt : 0.0f;
                const Vec3 aim = target ? *target : frame.pos[std::size_t(s.a)];
                const LookAtResult r = solve_look_at(sk, pose, s.a, aim, p, ik->rt.turn[i]);
                st["clamped"] = r.clamped;
                st["yaw"] = r.yaw;
                st["pitch"] = r.pitch;
                status[i] = st;
                refresh_frame(sk, pose, frame);
            } else if (!feetDone) {
                feetDone = true;
                // All foot solvers act together: the pelvis follows the lowest ground under them.
                struct Foot {
                    std::size_t index;
                    Vec3 anim;
                    Quat animRot;
                    float contact = 0.0f;
                    bool hit = false;
                    Vec3 normal{0, 1, 0};
                    float off = 0.0f;
                };
                std::vector<Foot> feet;
                const float scale = std::max(length(c.toWorld.transform_dir(Vec3{0, 1, 0})), 1e-4f);
                for (std::size_t k = 0; k < solvers.size(); ++k) {
                    if (!valid[k] || !solvers[k].enabled || solvers[k].type != "foot") continue;
                    const Solver& f = solvers[k];
                    Foot ft;
                    ft.index = k;
                    ft.anim = frame.pos[std::size_t(f.c)];
                    ft.animRot = frame.rot[std::size_t(f.c)];
                    const float footHeight = f.footHeight >= 0.0f ? f.footHeight : std::max(rig.rest_head(f.c).y, 0.0f);
                    const float legLen = length(frame.pos[std::size_t(f.b)] - frame.pos[std::size_t(f.a)]) +
                                         length(ft.anim - frame.pos[std::size_t(f.b)]);
                    if (ground) {
                        const Vec3 originW = c.toWorld.transform_point(ft.anim) + Vec3{0, ik->rayUp, 0};
                        auto hit = ground(originW, Vec3{0, -1, 0}, ik->rayUp + ik->rayDown, ik->groundMask, e);
                        if (hit) {
                            ft.hit = true;
                            const Vec3 gm = c.toModel.transform_point(hit->point);
                            ft.normal = normalize(c.toModel.transform_dir(hit->normal));
                            const float h = ft.anim.y - footHeight;
                            ft.contact = 1.0f - smoothstep01(h / std::max(0.3f * legLen, 1e-3f));
                            ft.off = gm.y * ft.contact;
                        }
                    }
                    float& lift = ik->rt.lift[k];
                    if (!ik->rt.started || ik->pelvisSmooth <= 1e-5f)
                        lift = ft.off;
                    else
                        lift += (ft.off - lift) * (dt / (ik->pelvisSmooth + dt));
                    feet.push_back(ft);
                }
                (void)scale;
                float shift = 0.0f;
                bool any = false;
                for (const Foot& ft : feet)
                    if (ft.hit) {
                        shift = any ? std::min(shift, ik->rt.lift[ft.index]) : ik->rt.lift[ft.index];
                        any = true;
                    }
                shift = clamp(shift, -ik->maxPelvisDrop, ik->maxPelvisRise) * masterWeight;
                ik->rt.pelvisShift = shift;
                const int pelvis = rig.find(ik->pelvis);
                if (pelvis < 0 && !ik->rt.warned) {
                    ik->rt.warned = true;
                    FA_WARN("animation",
                            "IK3D on '{}': pelvis '{}' is not a bone of the model, so the pelvis is not moved. {}",
                            entity_label(world, e), ik->pelvis, did_you_mean(ik->pelvis, rig.bone_names()));
                }
                if (pelvis >= 0 && std::fabs(shift) > 0.0f) {
                    const int pp = sk.nodes[std::size_t(pelvis)].parent;
                    const Vec3 delta{0, shift, 0};
                    pose.translation[std::size_t(pelvis)] +=
                        pp < 0 ? delta : frame.rot[std::size_t(pp)].conjugate().rotate(delta);
                    refresh_frame(sk, pose, frame);
                }
                for (const Foot& ft : feet) {
                    const Solver& f = solvers[ft.index];
                    Json st = status_entry(f, ft.index, ft.hit);
                    st["contact"] = ft.contact;
                    st["lift"] = ik->rt.lift[ft.index];
                    if (ft.hit && weight > 0.0f) {
                        Quat endRot = ft.animRot;
                        if (f.alignToGround && ft.contact > 0.0f) {
                            Quat q = rotation_between(Vec3{0, 1, 0}, ft.normal);
                            const float ang = rotation_angle_deg(q);
                            if (ang > f.maxFootAngle) q = slerp(Quat{}, q, f.maxFootAngle / ang);
                            endRot = normalize(slerp(Quat{}, q, ft.contact) * ft.animRot);
                        }
                        const Vec3 target = ft.anim + Vec3{0, ik->rt.lift[ft.index], 0};
                        const Vec3 pole = frame.pos[std::size_t(f.b)];
                        auto r = solve_two_bone(sk, pose, f.a, f.b, f.c, target, pole, f.weight * masterWeight, endRot);
                        if (r) {
                            st["reached"] = r->reached;
                            st["error"] = r->error;
                        }
                        refresh_frame(sk, pose, frame);
                    }
                    status[ft.index] = st;
                }
            } else if (status[i].empty()) {
                status[i] = status_entry(s, i, false);
            }
        }
        ik->rt.started = true;
        ik->status = status;
        animator_apply_pose(*an, pose);
    }
}

Result<Json> ik3d_solve_once(const Rig3D& rig, Pose& pose, const Json& solver, float groundHeight) {
    if (!rig.skeleton || rig.bones.empty())
        return make_error("the skeleton has no skin", "Give a skinned .rig.glb made by rig.bake.");
    const SkeletonAsset& sk = *rig.skeleton;
    std::vector<IKIssue> issues;
    Solver s;
    Reader rd{issues, ""};
    if (!parse_solver(solver, &rig, s, rd) || !issues.empty()) {
        const IKIssue& first = issues.empty() ? IKIssue{"", "the solver is not valid", ""} : issues.front();
        return make_error("solver" + first.pointer + ": " + first.message +
                              (issues.size() > 1 ? std::format(" ({} more problems)", issues.size() - 1) : ""),
                          first.hint);
    }
    auto fixed = [&](const TargetSpec& t, const char* what) -> Result<std::optional<Vec3>> {
        if (!t.set) return std::optional<Vec3>{};
        if (!t.entity.empty())
            return make_error(
                std::format("the {} names the entity '{}', and there is no scene here", what, t.entity),
                std::format(
                    "Give the {} as a position [x, y, z] in the model's space (the rig's own units: +Y up, facing +Z).",
                    what));
        return std::optional<Vec3>{t.offset};
    };
    PoseFrame frame = pose_frame(sk, pose);
    Json out = Json::object({{"type", s.type}});
    Json bones = Json::array();
    auto list = [&](std::initializer_list<int> nodes) {
        const PoseFrame f = pose_frame(sk, pose);
        for (int n : nodes)
            bones.push_back(Json::object(
                {{"bone", sk.nodes[std::size_t(n)].name},
                 {"head", Json::array({f.pos[std::size_t(n)].x, f.pos[std::size_t(n)].y, f.pos[std::size_t(n)].z})}}));
    };
    if (s.type == "lookAt") {
        auto target = fixed(s.target, "target");
        if (!target) return target.error();
        LookAtParams p;
        p.forward = s.forward;
        p.yawLimit = s.yawLimit;
        p.pitchLimit = s.pitchLimit;
        p.weight = s.weight;
        Quat state;
        const LookAtResult r = solve_look_at(sk, pose, s.a, **target, p, state);
        out["clamped"] = r.clamped;
        out["yaw"] = r.yaw;
        out["pitch"] = r.pitch;
        const PoseFrame f = pose_frame(sk, pose);
        const Vec3 aim = f.rot[std::size_t(s.a)].rotate(s.forward);
        out["aim"] = Json::array({aim.x, aim.y, aim.z});
        return out;
    }
    Vec3 target{};
    std::optional<Vec3> pole;
    Quat endRot = frame.rot[std::size_t(s.c)];
    std::optional<Quat> endRotation;
    if (s.type == "twoBone") {
        auto t = fixed(s.target, "target");
        if (!t) return t.error();
        auto pl = fixed(s.pole, "pole");
        if (!pl) return pl.error();
        target = **t;
        pole = *pl;
    } else {
        // foot: the ankle goes to the height of a flat ground at `groundHeight`, over where it is
        const float footHeight = s.footHeight >= 0.0f ? s.footHeight : std::max(rig.rest_head(s.c).y, 0.0f);
        target = frame.pos[std::size_t(s.c)];
        target.y = groundHeight + footHeight;
        pole = frame.pos[std::size_t(s.b)];
        (void)endRot;
    }
    auto r = solve_two_bone(sk, pose, s.a, s.b, s.c, target, pole, s.weight, endRotation);
    if (!r) return r.error();
    out["reached"] = r->reached;
    out["error"] = r->error;
    out["target"] = Json::array({target.x, target.y, target.z});
    list({s.a, s.b, s.c});
    out["bones"] = bones;
    return out;
}

}  // namespace fa
