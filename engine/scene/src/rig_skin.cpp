// The skin weights pipeline (rig_skin.h): plan each part, solve (heat, voxel or rigid), filter by hierarchy, smooth, limit, apply the document's
// edits, measure.
#include "fa/scene/rig_skin.h"

#include <algorithm>
#include <cmath>
#include <format>
#include <map>

#include "fa/core/det_math.h"
#include "fa/core/strings.h"
#include "rig_skin_internal.h"

namespace fa {

using namespace rig_skin_detail;

namespace rig_skin_detail {

SkinModel make_skin_model(const MeshData& mesh) {
    SkinModel m;
    const std::size_t tris = mesh.indices.size() / 3;
    const std::size_t n = mesh.vertex_count();
    m.triSub.assign(tris, kNone);
    m.vertSub.assign(n, kNone);
    for (std::size_t s = 0; s < mesh.submeshes.size(); ++s) {
        const MeshSubmesh& sm = mesh.submeshes[s];
        m.partNames.push_back(sm.part);
        const std::size_t end = std::min<std::size_t>(mesh.indices.size(), std::size_t(sm.start) + sm.count);
        for (std::size_t i = sm.start; i + 3 <= end; i += 3) m.triSub[i / 3] = std::uint32_t(s);
    }
    for (std::size_t t = 0; t < tris; ++t) {
        if (m.triSub[t] == kNone) continue;
        for (int k = 0; k < 3; ++k) {
            const std::uint32_t v = mesh.indices[t * 3 + std::size_t(k)];
            if (v < n && m.vertSub[v] == kNone) m.vertSub[v] = m.triSub[t];
        }
    }
    return m;
}

std::vector<std::uint8_t> bone_hops(const RigFit& fit) {
    const std::size_t n = fit.bones.size();
    std::vector<std::uint8_t> out(n * n, 0);
    std::vector<int> depth(n, 0);
    for (std::size_t i = 0; i < n; ++i)
        depth[i] = fit.bones[i].parentIndex >= 0 ? depth[std::size_t(fit.bones[i].parentIndex)] + 1 : 0;
    for (std::size_t a = 0; a < n; ++a)
        for (std::size_t b = 0; b < n; ++b) {
            int x = int(a), y = int(b), hops = 0;
            while (x != y) {
                if (depth[std::size_t(x)] >= depth[std::size_t(y)]) {
                    x = fit.bones[std::size_t(x)].parentIndex;
                } else {
                    y = fit.bones[std::size_t(y)].parentIndex;
                }
                ++hops;
                if (x < 0 || y < 0) {
                    hops = 255;
                    break;
                }
            }
            out[a * n + b] = std::uint8_t(std::min(hops, 255));
        }
    return out;
}

}  // namespace rig_skin_detail

int rig_bone_hops(const RigFit& fit, int a, int b) {
    const std::size_t n = fit.bones.size();
    if (a < 0 || b < 0 || std::size_t(a) >= n || std::size_t(b) >= n) return -1;
    return bone_hops(fit)[std::size_t(a) * n + std::size_t(b)];
}

namespace {

struct PartPlan {
    std::string name;
    std::string method;      // heat, voxel, rigid
    std::string requested;   // what the document said (auto, ...)
    std::string used;        // what bound the vertices in the end (heat can fall back to voxel)
    std::uint64_t mask = 0;  // the bones a vertex of the part may follow
    int forced = -1;         // skin.parts[part].bone
    std::vector<int> own;    // the bones that claim the part
    std::size_t vertices = 0;
    std::string note;
};

std::uint64_t all_bits(std::size_t n) { return n >= 64 ? ~std::uint64_t(0) : ((std::uint64_t(1) << n) - 1); }

Seg bone_seg(const RigBoneFit& b) { return {b.head, b.tail}; }

}  // namespace

Result<RigSkinResult> compute_rig_skin(const RigSkinSettings& settings, const RigFit& fit, const MeshData& mesh) {
    const std::size_t nb = fit.bones.size();
    if (nb == 0 || nb > kRigMaxBones)
        return make_error(std::format("a skin needs 1 to {} bones, the rig has {}", kRigMaxBones, nb),
                          "Lower the spine, neck or tail options.");
    const std::size_t nv = mesh.vertex_count();
    const SkinModel model = make_skin_model(mesh);
    const std::vector<std::uint8_t> hops = bone_hops(fit);
    std::vector<Seg> segs;
    for (const RigBoneFit& b : fit.bones) segs.push_back(bone_seg(b));
    const std::uint64_t everyone = all_bits(nb);

    // ---- the plan of every part
    std::vector<std::string> partNames;  // distinct, in submesh order
    for (const std::string& p : model.partNames)
        if (std::find(partNames.begin(), partNames.end(), p) == partNames.end()) partNames.push_back(p);
    std::vector<std::string> namedParts;
    for (const std::string& p : partNames)
        if (!p.empty()) namedParts.push_back(p);
    for (const auto& [part, binding] : settings.parts)
        if (std::find(partNames.begin(), partNames.end(), part) == partNames.end())
            return make_error(std::format("skin.parts names the part '{}', which the model does not have", part),
                              did_you_mean(part, namedParts) + " The parts of the model: " + join(namedParts, ", ") +
                                  ".");
    std::vector<PartPlan> plans;
    for (const std::string& p : partNames) {
        PartPlan plan;
        plan.name = p;
        for (std::size_t b = 0; b < nb; ++b)
            if (std::find(fit.bones[b].parts.begin(), fit.bones[b].parts.end(), p) != fit.bones[b].parts.end())
                plan.own.push_back(int(b));
        std::string requested = settings.method;
        for (const auto& [part, binding] : settings.parts)
            if (part == p) {
                if (!binding.method.empty()) requested = binding.method;
                if (!binding.bone.empty()) {
                    plan.forced = fit.find(binding.bone);
                    if (plan.forced < 0) {
                        std::vector<std::string> names;
                        for (const RigBoneFit& b : fit.bones) names.push_back(b.name);
                        return make_error(std::format("skin.parts.{}.bone is '{}', which is not a bone of the {} rig",
                                                      p, binding.bone, fit.templateName),
                                          did_you_mean(binding.bone, names));
                    }
                }
            }
        plan.requested = requested;
        plan.method = requested == "auto" ? (fit.templateName == "generic" ? "rigid" : "heat") : requested;
        if (p.empty() && plan.method == "rigid" && plan.forced < 0 && plan.own.empty()) plan.method = "heat";
        std::uint64_t m = 0;
        auto add_with_neighbours = [&](int b) {
            m |= std::uint64_t(1) << b;
            if (fit.bones[std::size_t(b)].parentIndex >= 0)
                m |= std::uint64_t(1) << fit.bones[std::size_t(b)].parentIndex;
            for (std::size_t c = 0; c < nb; ++c)
                if (fit.bones[c].parentIndex == b) m |= std::uint64_t(1) << c;
        };
        if (plan.forced >= 0) {
            if (plan.method == "rigid")
                m = std::uint64_t(1) << plan.forced;
            else
                add_with_neighbours(plan.forced);
        } else if (!plan.own.empty()) {
            if (plan.method == "rigid") {
                for (int b : plan.own) m |= std::uint64_t(1) << b;
            } else {
                for (int b : plan.own) add_with_neighbours(b);
            }
        } else {
            m = everyone;
        }
        plan.mask = m;
        plans.push_back(plan);
    }
    auto plan_of_sub = [&](std::uint32_t sub) -> PartPlan& {
        const std::string& name = model.partNames[sub];
        for (PartPlan& p : plans)
            if (p.name == name) return p;
        return plans[0];
    };

    RigSkinResult result;
    RigSkinReport& rep = result.report;
    rep.vertices = nv;
    std::vector<Infl> W(nv);
    std::vector<char> fallbackUsed(nv, 0);  // the method gave nothing: the nearest bone was used
    Vec3 lo{}, hi{};
    if (nv) {
        lo = hi = {mesh.positions[0], mesh.positions[1], mesh.positions[2]};
        for (std::size_t v = 0; v < nv; ++v) {
            const Vec3 p{mesh.positions[v * 3], mesh.positions[v * 3 + 1], mesh.positions[v * 3 + 2]};
            lo = {std::min(lo.x, p.x), std::min(lo.y, p.y), std::min(lo.z, p.z)};
            hi = {std::max(hi.x, p.x), std::max(hi.y, p.y), std::max(hi.z, p.z)};
        }
    }
    const float diag = length(hi - lo);
    auto position = [&](std::size_t v) {
        return Vec3{mesh.positions[v * 3], mesh.positions[v * 3 + 1], mesh.positions[v * 3 + 2]};
    };
    // the nearest bone of the bones in `mask`, measured to the bone's segment
    auto nearest_bone = [&](Vec3 p, std::uint64_t mask) {
        if (!mask) mask = everyone;
        float best = 1e30f;
        int bone = 0;
        for (std::size_t b = 0; b < nb; ++b)
            if (mask >> b & 1) {
                const float d = seg_dist2(p, segs[b]);
                if (d < best) {
                    best = d;
                    bone = int(b);
                }
            }
        return bone;
    };

    // which vertices belong to which plan
    for (std::size_t v = 0; v < nv; ++v)
        if (model.vertSub[v] != kNone) plan_of_sub(model.vertSub[v]).vertices++;

    // ---- rigid parts
    for (PartPlan& plan : plans) {
        if (plan.method != "rigid") continue;
        int bone = plan.forced;
        if (bone < 0) {
            Vec3 c{0, 0, 0};
            std::size_t n = 0;
            for (std::size_t v = 0; v < nv; ++v)
                if (model.vertSub[v] != kNone && &plan_of_sub(model.vertSub[v]) == &plan) {
                    c = c + position(v);
                    ++n;
                }
            if (n) c = c * (1.0f / float(n));
            bone = nearest_bone(c, plan.mask);
        }
        for (std::size_t v = 0; v < nv; ++v)
            if (model.vertSub[v] != kNone && &plan_of_sub(model.vertSub[v]) == &plan)
                W[v] = {{std::uint16_t(bone), 1.0f}};
        plan.note = "follows " + fit.bones[std::size_t(bone)].name;
    }

    // ---- heat and voxel parts: one weld per method
    const std::size_t tris = mesh.indices.size() / 3;
    const float weldEps = std::max(diag * 1e-5f, 1e-7f);
    const int maxHops = std::max(0, settings.maxHops);
    auto hop_filter = [&](Infl& w) {
        if (w.size() < 2) return;
        std::uint16_t s = w[0].first;
        float sv = w[0].second;
        for (const auto& e : w)
            if (e.second > sv) {
                sv = e.second;
                s = e.first;
            }
        Infl kept;
        for (const auto& e : w)
            if (hops[std::size_t(s) * nb + e.first] <= maxHops) kept.push_back(e);
        w = std::move(kept);
        normalize_infl(w, 0.0f);
    };
    for (const char* method : {"heat", "voxel"}) {
        std::vector<char> triOn(tris, 0);
        bool any = false;
        for (std::size_t t = 0; t < tris; ++t)
            if (model.triSub[t] != kNone && plan_of_sub(model.triSub[t]).method == method) {
                triOn[t] = 1;
                any = true;
            }
        if (!any) continue;
        const Weld weld = build_weld(mesh, triOn, weldEps);
        std::vector<std::uint64_t> nodeMask(weld.nodes(), 0);
        for (std::size_t t = 0; t < tris; ++t)
            if (triOn[t]) {
                const std::uint64_t m = plan_of_sub(model.triSub[t]).mask;
                for (int k = 0; k < 3; ++k) {
                    const std::uint32_t v = mesh.indices[t * 3 + std::size_t(k)];
                    if (v < nv && weld.nodeOf[v] != kNone) nodeMask[weld.nodeOf[v]] |= m;
                }
            }
        std::vector<Infl> nodeW;
        std::vector<char> viaVoxel(weld.nodes(), 0);
        if (std::string(method) == "heat") {
            HeatStats hs;
            solve_heat(weld, nodeMask, segs, double(settings.locality), nodeW, hs);
            rep.heatComponents += int(hs.componentsSolved + hs.componentsFailed);
            rep.heatFailed += int(hs.componentsFailed);
            rep.heatIterations = std::max(rep.heatIterations, int(hs.maxIterations));
            bool failed = false;
            for (const Infl& w : nodeW) failed = failed || w.empty();
            if (failed) {
                std::vector<Infl> vox;
                VoxelStats vs;
                solve_voxel(weld, nodeMask, segs, double(settings.locality), vox, vs);
                for (std::size_t j = 0; j < nodeW.size(); ++j)
                    if (nodeW[j].empty() && !vox[j].empty()) {
                        nodeW[j] = vox[j];
                        viaVoxel[j] = 1;
                    }
                if (hs.componentsFailed)
                    rep.warnings.push_back(std::format(
                        "bone heat did not converge on {} piece(s) of the surface; the voxel binding was used for "
                        "them. A mesh with "
                        "inverted or tiny triangles does this: set skin.method to \"voxel\" for those parts.",
                        hs.componentsFailed));
            }
        } else {
            VoxelStats vs;
            solve_voxel(weld, nodeMask, segs, double(settings.locality), nodeW, vs);
        }
        for (Infl& w : nodeW) hop_filter(w);
        // smoothing over the surface: each node moves towards the mean of its neighbours, inside its own bones
        for (int pass = 0; pass < settings.smooth; ++pass) {
            std::vector<Infl> next(nodeW.size());
            std::vector<float> acc(nb);
            for (std::size_t j = 0; j < nodeW.size(); ++j) {
                const std::uint32_t b = weld.rowStart[j], e = weld.rowStart[j + 1];
                if (nodeW[j].empty() || b == e) {
                    next[j] = nodeW[j];
                    continue;
                }
                std::fill(acc.begin(), acc.end(), 0.0f);
                accumulate(nodeW[j], 0.5f, acc);
                float count = 0;
                for (std::uint32_t k = b; k < e; ++k)
                    if (!nodeW[weld.col[k]].empty()) count += 1.0f;
                for (std::uint32_t k = b; k < e; ++k)
                    if (!nodeW[weld.col[k]].empty()) accumulate(nodeW[weld.col[k]], 0.5f / count, acc);
                const std::uint64_t m = nodeMask[j] ? nodeMask[j] : everyone;
                for (std::size_t bone = 0; bone < nb; ++bone)
                    if (!(m >> bone & 1)) acc[bone] = 0;
                next[j] = from_dense(acc, 1e-4f);
                hop_filter(next[j]);
                if (next[j].empty()) next[j] = nodeW[j];
            }
            nodeW = std::move(next);
        }
        for (std::size_t v = 0; v < nv; ++v) {
            if (model.vertSub[v] == kNone || weld.nodeOf[v] == kNone) continue;
            const PartPlan& plan = plan_of_sub(model.vertSub[v]);
            if (plan.method != method) continue;
            Infl w = nodeW[weld.nodeOf[v]];
            const std::uint64_t m = plan.mask ? plan.mask : everyone;
            Infl kept;
            for (const auto& e : w)
                if (m >> e.first & 1) kept.push_back(e);
            w = std::move(kept);
            normalize_infl(w, 0.0f);
            W[v] = std::move(w);
        }
        for (PartPlan& plan : plans)
            if (plan.method == method) {
                bool voxelHere = false;
                for (std::size_t v = 0; v < nv; ++v)
                    if (model.vertSub[v] != kNone && &plan_of_sub(model.vertSub[v]) == &plan &&
                        weld.nodeOf[v] != kNone && viaVoxel[weld.nodeOf[v]])
                        voxelHere = true;
                if (voxelHere) {
                    plan.note = "bone heat did not converge here, so the voxel binding was used";
                    plan.used = "voxel";
                }
            }
    }

    // vertices the methods left empty follow the nearest bone of their part
    for (std::size_t v = 0; v < nv; ++v) {
        if (!W[v].empty()) continue;
        const std::uint64_t m = model.vertSub[v] != kNone ? plan_of_sub(model.vertSub[v]).mask : everyone;
        W[v] = {{std::uint16_t(nearest_bone(position(v), m)), 1.0f}};
        if (model.vertSub[v] != kNone) {
            fallbackUsed[v] = 1;
            ++rep.unweighted;
        }
    }
    if (rep.unweighted)
        rep.warnings.push_back(std::format("{} vertex(es) got no automatic weight and follow their nearest bone. Check "
                                           "that the part's bones are inside or near it "
                                           "(rig.info shows the fit) or set skin.parts.<part>.method to \"rigid\".",
                                           rep.unweighted));
    for (Infl& w : W) limit_infl(w, std::clamp(settings.maxInfluences, 1, 4));

    // ---- the document's edits
    auto edited = apply_skin_edits(settings, fit, mesh, model, W, rep);
    if (!edited.ok()) return edited.error();
    for (Infl& w : W) limit_infl(w, std::clamp(settings.maxInfluences, 1, 4));

    // ---- pack and measure
    RigWeights& out = result.weights;
    out.joints.assign(nv * 4, 0);
    out.weights.assign(nv * 4, 0.0f);
    std::vector<std::size_t> strongest(nb, 0);
    std::size_t totalInfl = 0;
    for (std::size_t v = 0; v < nv; ++v) {
        Infl w = W[v];
        std::sort(w.begin(), w.end(), [](const auto& a, const auto& b) {
            return a.second > b.second || (a.second == b.second && a.first < b.first);
        });
        float sum = 0;
        for (std::size_t k = 0; k < w.size() && k < 4; ++k) sum += w[k].second;
        for (std::size_t k = 0; k < w.size() && k < 4; ++k) {
            out.joints[v * 4 + k] = w[k].first;
            out.weights[v * 4 + k] = w[k].second / sum;
        }
        rep.maxInfluences = std::max(rep.maxInfluences, int(std::min<std::size_t>(w.size(), 4)));
        totalInfl += std::min<std::size_t>(w.size(), 4);
        if (!w.empty()) ++strongest[w[0].first];
        bool far = false;
        for (std::size_t k = 1; k < w.size() && k < 4; ++k)
            if (hops[std::size_t(w[0].first) * nb + w[k].first] > maxHops) far = true;
        if (far) ++rep.farBlends;
    }
    rep.meanInfluences = nv ? double(totalInfl) / double(nv) : 0.0;
    for (std::size_t b = 0; b < nb; ++b) {
        rep.boneVertices.push_back({fit.bones[b].name, strongest[b]});
        if (!strongest[b]) rep.idleBones.push_back(fit.bones[b].name);
    }
    if (!rep.idleBones.empty() && nv)
        rep.warnings.push_back(std::format("{} bone(s) are the strongest of no vertex and move nothing visible by "
                                           "themselves: {}. Name the model part each one moves in "
                                           "the rig's `parts`, or leave them: they are fine as helper bones.",
                                           rep.idleBones.size(), join(rep.idleBones, ", ")));
    for (const PartPlan& plan : plans) {
        RigSkinPartReport pr;
        pr.part = plan.name;
        pr.method = plan.used.empty() ? plan.method : plan.used;
        pr.vertices = plan.vertices;
        pr.note = plan.note;
        for (std::size_t b = 0; b < nb; ++b)
            if (plan.mask >> b & 1) pr.bones.push_back(fit.bones[b].name);
        rep.parts.push_back(pr);
    }
    return result;
}

Json rig_skin_report_to_json(const RigSkinReport& r) {
    Json j = {{"vertices", r.vertices},           {"unweighted", r.unweighted},
              {"maxInfluences", r.maxInfluences}, {"meanInfluences", std::round(r.meanInfluences * 100.0) / 100.0},
              {"farBlends", r.farBlends},         {"editsApplied", r.editsApplied}};
    if (r.mirrorUnmatched) j["mirrorUnmatched"] = r.mirrorUnmatched;
    if (r.heatComponents)
        j["heat"] = {{"pieces", r.heatComponents}, {"failed", r.heatFailed}, {"iterations", r.heatIterations}};
    Json parts = Json::array();
    for (const RigSkinPartReport& p : r.parts) {
        Json e = {{"part", p.part}, {"method", p.method}, {"vertices", p.vertices}};
        if (!p.note.empty()) e["note"] = p.note;
        Json bones = Json::array();
        for (const std::string& b : p.bones) bones.push_back(b);
        e["bones"] = bones;
        parts.push_back(e);
    }
    j["parts"] = parts;
    Json bv = Json::object();
    for (const auto& [name, count] : r.boneVertices) bv[name] = count;
    j["boneVertices"] = bv;
    if (!r.idleBones.empty()) j["idleBones"] = r.idleBones;
    if (!r.warnings.empty()) j["warnings"] = r.warnings;
    return j;
}

namespace {

struct Aff {
    float r[9] = {1, 0, 0, 0, 1, 0, 0, 0, 1};  // row-major
    Vec3 t{0, 0, 0};
    bool identity = true;
    Vec3 apply(Vec3 p) const {
        return {r[0] * p.x + r[1] * p.y + r[2] * p.z + t.x, r[3] * p.x + r[4] * p.y + r[5] * p.z + t.y,
                r[6] * p.x + r[7] * p.y + r[8] * p.z + t.z};
    }
};
Aff compose(const Aff& a, const Aff& b) {  // a after b
    Aff o;
    for (int i = 0; i < 3; ++i)
        for (int j = 0; j < 3; ++j)
            o.r[i * 3 + j] = a.r[i * 3] * b.r[j] + a.r[i * 3 + 1] * b.r[3 + j] + a.r[i * 3 + 2] * b.r[6 + j];
    o.t = a.apply(b.t);
    o.identity = a.identity && b.identity;
    return o;
}

}  // namespace

std::vector<float> rig_skin_pose(const RigFit& fit, const RigWeights& weights, const std::vector<float>& positions,
                                 const std::vector<RigBonePose>& poses) {
    const std::size_t nb = fit.bones.size();
    std::vector<Aff> local(nb), world(nb);
    for (const RigBonePose& p : poses) {
        if (p.bone < 0 || std::size_t(p.bone) >= nb) continue;
        const RigBoneFit& bone = fit.bones[std::size_t(p.bone)];
        Vec3 axis = p.axis;
        if (length_sq(axis) < 1e-12f) {
            Vec3 dir = bone.tail - bone.head;
            if (length_sq(dir) < 1e-12f) dir = {0, 1, 0};
            dir = normalize(dir);
            axis = cross(dir, {0, 1, 0});
            if (length_sq(axis) < 1e-6f) axis = cross(dir, {0, 0, 1});
        }
        axis = normalize(axis);
        float s, c;
        det::sin_cos(p.degrees * kDegToRad, s, c);
        const float t = 1 - c;
        Aff a;
        const float R[9] = {
            c + axis.x * axis.x * t,          axis.x * axis.y * t - axis.z * s, axis.x * axis.z * t + axis.y * s,
            axis.y * axis.x * t + axis.z * s, c + axis.y * axis.y * t,          axis.y * axis.z * t - axis.x * s,
            axis.z * axis.x * t - axis.y * s, axis.z * axis.y * t + axis.x * s, c + axis.z * axis.z * t};
        for (int i = 0; i < 9; ++i) a.r[i] = R[i];
        // rotate about the head: p -> R (p - head) + head
        const Vec3 rh = {R[0] * bone.head.x + R[1] * bone.head.y + R[2] * bone.head.z,
                         R[3] * bone.head.x + R[4] * bone.head.y + R[5] * bone.head.z,
                         R[6] * bone.head.x + R[7] * bone.head.y + R[8] * bone.head.z};
        a.t = bone.head - rh;
        a.identity = p.degrees == 0;
        local[std::size_t(p.bone)] = compose(local[std::size_t(p.bone)], a);
    }
    for (std::size_t b = 0; b < nb; ++b) {
        const int parent = fit.bones[b].parentIndex;
        world[b] = parent >= 0 ? compose(world[std::size_t(parent)], local[b]) : local[b];
    }
    const std::size_t nv = positions.size() / 3;
    std::vector<float> out(positions.size());
    for (std::size_t v = 0; v < nv; ++v) {
        const Vec3 p{positions[v * 3], positions[v * 3 + 1], positions[v * 3 + 2]};
        Vec3 acc{0, 0, 0};
        float sum = 0;
        bool still = true;  // every bone that moves the vertex is at rest: it stays exactly where it is
        if (v < weights.vertex_count())
            for (int k = 0; k < 4; ++k) {
                const float w = weights.weights[v * 4 + std::size_t(k)];
                if (w <= 0) continue;
                const std::size_t b = weights.joints[v * 4 + std::size_t(k)];
                if (b >= nb) continue;
                acc = acc + world[b].apply(p) * w;
                sum += w;
                still = still && world[b].identity;
            }
        if (sum <= 0 || still) acc = p;
        out[v * 3] = acc.x;
        out[v * 3 + 1] = acc.y;
        out[v * 3 + 2] = acc.z;
    }
    return out;
}

}  // namespace fa
