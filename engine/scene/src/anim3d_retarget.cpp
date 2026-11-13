#include "fa/scene/anim3d_retarget.h"

#include <algorithm>
#include <cmath>
#include <format>
#include <map>
#include <set>

#include "fa/core/det_math.h"
#include "fa/core/strings.h"
#include "fa/scene/ik3d.h"

namespace fa {

namespace {

Quat key_rotation(const Anim3DClip& clip, const std::array<float, 4>& v) {
    return clip.quat ? normalize(Quat{v[0], v[1], v[2], v[3]}) : Quat::from_euler_deg({v[0], v[1], v[2]});
}

float leg_length(const Rig3D& rig, bool& found) {
    found = false;
    for (const char* side : {"l", "r"}) {
        const int a = rig.find_role("thigh", 0, side), b = rig.find_role("shin", 0, side),
                  c = rig.find_role("foot", 0, side);
        if (a >= 0 && b >= 0 && c >= 0) {
            found = true;
            return length(rig.rest_head(b) - rig.rest_head(a)) + length(rig.rest_head(c) - rig.rest_head(b));
        }
    }
    // A quadruped's fore leg, or a rig with no legs at all: the height of the root.
    for (const char* side : {"l", "r"}) {
        const int a = rig.find_role("arm_upper", 0, side), b = rig.find_role("arm_lower", 0, side),
                  c = rig.find_role("hand", 0, side);
        if (a >= 0 && b >= 0 && c >= 0 && rig.templateName == "quadruped") {
            found = true;
            return length(rig.rest_head(b) - rig.rest_head(a)) + length(rig.rest_head(c) - rig.rest_head(b));
        }
    }
    const int root = rig.find_role("root", 0, "");
    return root >= 0 ? std::max(rig.rest_head(root).y, 0.0f) : 0.0f;
}

std::string role_label(const SkelNode& n) { return n.role + (n.side.empty() ? "" : "_" + n.side); }

}  // namespace

Result<RetargetResult> retarget_anim3d(const Anim3DClip& clip, const Rig3D& from, const Rig3D& to,
                                       const RetargetOptions& opt) {
    if (std::string why = rig_generator_problem(from); !why.empty())
        return make_error("cannot retarget: the source rig is not a rig.bake skeleton: " + why,
                          "Bake both models with rig.create (docs/RIGGING.md): retargeting matches bones by role.");
    if (std::string why = rig_generator_problem(to); !why.empty())
        return make_error("cannot retarget: the target rig is not a rig.bake skeleton: " + why,
                          "Bake both models with rig.create (docs/RIGGING.md): retargeting matches bones by role.");
    const SkeletonAsset& fsk = *from.skeleton;
    const SkeletonAsset& tsk = *to.skeleton;
    RetargetResult res;
    Anim3DClip& out = res.clip;
    out.duration = clip.duration;
    out.loop = clip.loop;
    out.quat = clip.quat;
    out.doc = clip.doc;
    out.templateName = to.templateName;
    out.rig = tsk.path;
    out.events = clip.events;
    out.generated = clip.generated;

    // The scale.
    bool fromLegs = false, toLegs = false;
    const float fl = leg_length(from, fromLegs), tl = leg_length(to, toLegs);
    float scale = opt.scale;
    if (scale <= 0.0f) {
        if (fl > 1e-4f && tl > 1e-4f)
            scale = tl / fl;
        else
            scale = 1.0f;
        if (!fromLegs || !toLegs)
            res.notes.push_back(fl > 1e-4f && tl > 1e-4f
                                    ? "a rig has no legs: the height of the root scaled the motion"
                                    : "the rigs have no legs or root height to scale by: scale 1 (pass `scale`)");
    }
    res.scale = scale;
    out.groundSpeed = clip.groundSpeed * scale;

    auto dst_of = [&](int srcNode) -> int {
        const SkelNode& n = fsk.nodes[std::size_t(srcNode)];
        return to.find_role(n.role, n.roleIndex, n.side);
    };

    // Group the tracks by source bone.
    std::set<std::string> droppedSet, resampledSet;
    std::map<std::pair<std::string, std::string>, std::vector<std::size_t>>
        chainsToResample;  // (role, side) -> track indices
    for (std::size_t i = 0; i < clip.tracks.size(); ++i) {
        const Anim3DTrack& tr = clip.tracks[i];
        const int sn = from.find(tr.bone);
        if (sn < 0) {
            droppedSet.insert(tr.bone);
            continue;
        }
        const SkelNode& sNode = fsk.nodes[std::size_t(sn)];
        const int dn = dst_of(sn);
        const auto srcChain = from.chain(sNode.role, sNode.side);
        const auto dstChain = to.chain(sNode.role, sNode.side);
        if (dn >= 0 && srcChain.size() == dstChain.size()) {
            Anim3DTrack t = tr;
            t.bone = tsk.nodes[std::size_t(dn)].name;
            if (tr.channel == Anim3DChannel::Translation) {
                float k = scale;
                if (sNode.role != "root" && from.length[std::size_t(sn)] > 1e-5f && to.length[std::size_t(dn)] > 1e-5f)
                    k = to.length[std::size_t(dn)] / from.length[std::size_t(sn)];
                for (ClipKey& key : t.keys)
                    for (int c = 0; c < 3; ++c) key.value[std::size_t(c)] *= k;
                for (ClipKey& key : t.keys)
                    for (int c = 0; c < 3; ++c) {
                        key.inTan[std::size_t(c)] *= k;
                        key.outTan[std::size_t(c)] *= k;
                    }
            }
            out.tracks.push_back(std::move(t));
            ++res.mapped;
        } else if (!dstChain.empty() && tr.channel == Anim3DChannel::Rotation) {
            chainsToResample[{sNode.role, sNode.side}].push_back(i);
            resampledSet.insert(role_label(sNode));
        } else {
            droppedSet.insert(tr.bone);
        }
    }
    // Chains with another bone count: the total bend, shared evenly.
    for (const auto& [key, indices] : chainsToResample) {
        const auto srcChain = from.chain(key.first, key.second);
        const auto dstChain = to.chain(key.first, key.second);
        std::vector<const Anim3DTrack*> byBone(srcChain.size(), nullptr);
        std::set<float> times;
        for (std::size_t i : indices) {
            const Anim3DTrack& tr = clip.tracks[i];
            const int sn = from.find(tr.bone);
            for (std::size_t b = 0; b < srcChain.size(); ++b)
                if (srcChain[b] == sn) byBone[b] = &tr;
            for (const ClipKey& k : tr.keys) times.insert(k.t);
        }
        std::vector<Anim3DTrack> made(dstChain.size());
        for (std::size_t j = 0; j < dstChain.size(); ++j) {
            made[j].bone = tsk.nodes[std::size_t(dstChain[j])].name;
            made[j].channel = Anim3DChannel::Rotation;
        }
        std::vector<Vec3> prev(dstChain.size());
        bool first = true;
        for (float t : times) {
            Quat total;
            for (const Anim3DTrack* tr : byBone)
                if (tr) total = total * key_rotation(clip, sample_anim3d_track(*tr, clip.quat, t));
            if (total.w < 0) total = {-total.x, -total.y, -total.z, -total.w};
            const Quat part = slerp(Quat{}, total, 1.0f / float(dstChain.size()));
            for (std::size_t j = 0; j < dstChain.size(); ++j) {
                ClipKey k;
                k.t = t;
                if (clip.quat) {
                    k.value = {part.x, part.y, part.z, part.w};
                } else {
                    Vec3 e = part.to_euler_deg();
                    if (!first) {
                        auto wrap = [](float v, float p) {
                            while (v - p > 180.0f) v -= 360.0f;
                            while (v - p < -180.0f) v += 360.0f;
                            return v;
                        };
                        e = {wrap(e.x, prev[j].x), wrap(e.y, prev[j].y), wrap(e.z, prev[j].z)};
                    }
                    prev[j] = e;
                    k.value = {e.x, e.y, e.z, 0.0f};
                }
                made[j].keys.push_back(k);
            }
            first = false;
        }
        for (Anim3DTrack& t : made) out.tracks.push_back(std::move(t));
        ++res.mapped;
        res.resampled.push_back(key.first + (key.second.empty() ? "" : "_" + key.second) +
                                std::format(" ({} bones -> {})", srcChain.size(), dstChain.size()));
    }
    res.dropped.assign(droppedSet.begin(), droppedSet.end());
    // Contacts follow their bones.
    for (const Anim3DContact& c : clip.contacts) {
        const int sn = from.find(c.bone);
        const int dn = sn >= 0 ? dst_of(sn) : -1;
        if (dn < 0) {
            res.notes.push_back(std::format("contact of '{}' dropped: the target has no such bone", c.bone));
            continue;
        }
        Anim3DContact m = c;
        m.bone = tsk.nodes[std::size_t(dn)].name;
        out.contacts.push_back(m);
    }

    // Planted feet: solve the legs with a contact again.
    if (opt.plantFeet && !out.contacts.empty()) {
        struct Leg {
            int sc, sb, sa, dc, db, da;
            std::string name;
        };
        std::vector<Leg> legs;
        for (const Anim3DContact& c : clip.contacts) {
            const int sc = from.find(c.bone);
            const int dc = sc >= 0 ? dst_of(sc) : -1;
            if (sc < 0 || dc < 0) continue;
            const int sb = fsk.nodes[std::size_t(sc)].parent, db = tsk.nodes[std::size_t(dc)].parent;
            const int sa = sb >= 0 ? fsk.nodes[std::size_t(sb)].parent : -1,
                      da = db >= 0 ? tsk.nodes[std::size_t(db)].parent : -1;
            if (sb < 0 || db < 0 || sa < 0 || da < 0) {
                res.notes.push_back(
                    std::format("the feet of '{}' were not re-planted: it is not the end of a two-bone limb", c.bone));
                continue;
            }
            // The limb joins on the same roles on both sides.
            if (fsk.nodes[std::size_t(sb)].role != tsk.nodes[std::size_t(db)].role ||
                fsk.nodes[std::size_t(sa)].role != tsk.nodes[std::size_t(da)].role) {
                res.notes.push_back(std::format(
                    "the feet of '{}' were not re-planted: the limb has other bones in the target", c.bone));
                continue;
            }
            legs.push_back({sc, sb, sa, dc, db, da, tsk.nodes[std::size_t(dc)].name});
        }
        if (!legs.empty()) {
            const Anim3DBinding fb = bind_anim3d(clip, fsk);
            const Anim3DBinding tb = bind_anim3d(out, tsk);
            const int n = std::max(2, int(std::ceil(out.duration * opt.fps - 1e-4f)));
            std::vector<std::vector<Anim3DTrack>> made(legs.size() * 3);
            std::vector<Vec3> prevEuler(legs.size() * 3);
            std::vector<Quat> prevQuat(legs.size() * 3);
            float worst = 0.0f;
            for (int i = 0; i <= n; ++i) {
                const float t = i == n ? out.duration : out.duration * float(i) / float(n);
                Pose sp = from.rest;
                sample_anim3d(clip, fb, fsk, t, sp);
                const PoseFrame sf = pose_frame(fsk, sp);
                Pose tp = to.rest;
                sample_anim3d(out, tb, tsk, t, tp);
                PoseFrame tf = pose_frame(tsk, tp);
                for (std::size_t li = 0; li < legs.size(); ++li) {
                    const Leg& l = legs[li];
                    const Vec3 target = to.rest_head(l.dc) + (sf.pos[std::size_t(l.sc)] - from.rest_head(l.sc)) * scale;
                    const Vec3 pole = tf.pos[std::size_t(l.db)];
                    auto r = solve_two_bone(tsk, tp, l.da, l.db, l.dc, target, pole, 1.0f, sf.rot[std::size_t(l.sc)]);
                    if (r) worst = std::max(worst, r->error);
                    refresh_frame(tsk, tp, tf);
                }
                for (std::size_t li = 0; li < legs.size(); ++li) {
                    const int nodes[3] = {legs[li].da, legs[li].db, legs[li].dc};
                    for (int k = 0; k < 3; ++k) {
                        const std::size_t slot = li * 3 + std::size_t(k);
                        if (made[slot].empty()) {
                            made[slot].resize(1);
                            made[slot][0].bone = tsk.nodes[std::size_t(nodes[k])].name;
                            made[slot][0].channel = Anim3DChannel::Rotation;
                        }
                        Quat q = normalize(to.rest.rotation[std::size_t(nodes[k])].conjugate() *
                                           tp.rotation[std::size_t(nodes[k])]);
                        ClipKey key;
                        key.t = t;
                        if (clip.quat) {
                            if (i > 0 && dot(Vec4{q.x, q.y, q.z, q.w}, Vec4{prevQuat[slot].x, prevQuat[slot].y,
                                                                            prevQuat[slot].z, prevQuat[slot].w}) < 0)
                                q = {-q.x, -q.y, -q.z, -q.w};
                            prevQuat[slot] = q;
                            key.value = {q.x, q.y, q.z, q.w};
                        } else {
                            Vec3 e = q.to_euler_deg();
                            if (i > 0) {
                                auto wrap = [](float v, float p) {
                                    while (v - p > 180.0f) v -= 360.0f;
                                    while (v - p < -180.0f) v += 360.0f;
                                    return v;
                                };
                                e = {wrap(e.x, prevEuler[slot].x), wrap(e.y, prevEuler[slot].y),
                                     wrap(e.z, prevEuler[slot].z)};
                            }
                            prevEuler[slot] = e;
                            key.value = {e.x, e.y, e.z, 0.0f};
                        }
                        made[slot][0].keys.push_back(key);
                    }
                }
            }
            // The new tracks replace the rotation tracks of those bones.
            std::set<std::string> replaced;
            for (auto& m : made) replaced.insert(m[0].bone);
            out.tracks.erase(std::remove_if(out.tracks.begin(), out.tracks.end(),
                                            [&](const Anim3DTrack& t) {
                                                return t.channel == Anim3DChannel::Rotation && replaced.count(t.bone);
                                            }),
                             out.tracks.end());
            for (auto& m : made) out.tracks.push_back(std::move(m[0]));
            for (const Leg& l : legs) res.planted.push_back(l.name);
            if (worst > 0.01f * std::max(tl, 1e-3f))
                res.notes.push_back(std::format("a leg could not reach the foot's path (off by {:.3f}): the target's "
                                                "legs are shorter than the scaled path needs; "
                                                "pass a smaller `scale`",
                                                worst));
        }
    }
    out.doc = out.doc.empty() ? std::string("retargeted") : out.doc;
    return res;
}

}  // namespace fa
