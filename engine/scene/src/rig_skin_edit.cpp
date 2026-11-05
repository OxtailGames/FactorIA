// The edits of a rig's `skin` section (rig_skin_doc.h): set, add, smooth, normalize, limit and mirror on a part or a selection of faces.
#include <algorithm>
#include <cmath>
#include <format>
#include <map>
#include <tuple>

#include "fa/core/strings.h"
#include "fa/scene/model_select.h"
#include "rig_skin_internal.h"

namespace fa::rig_skin_detail {

namespace {

void sort_infl(Infl& w) { std::sort(w.begin(), w.end()); }

// "arm_upper_l" <-> "arm_upper_r"; a name with no side maps to itself
std::string mirror_name(const std::string& n) {
    if (n.size() > 2 && n[n.size() - 2] == '_' && n.back() == 'l') return n.substr(0, n.size() - 1) + "r";
    if (n.size() > 2 && n[n.size() - 2] == '_' && n.back() == 'r') return n.substr(0, n.size() - 1) + "l";
    return n;
}

}  // namespace

Result<void> apply_skin_edits(const RigSkinSettings& settings, const RigFit& fit, const MeshData& mesh, const SkinModel& model, std::vector<Infl>& W,
                              RigSkinReport& report) {
    if (settings.edits.empty()) return {};
    const std::size_t nv = mesh.vertex_count();
    const std::size_t nb = fit.bones.size();
    const std::size_t tris = mesh.indices.size() / 3;
    std::vector<std::string> bone_names;
    for (const RigBoneFit& b : fit.bones) bone_names.push_back(b.name);
    std::vector<std::string> named;
    for (const std::string& p : model.partNames)
        if (!p.empty() && std::find(named.begin(), named.end(), p) == named.end()) named.push_back(p);

    Vec3 lo{mesh.positions.size() >= 3 ? mesh.positions[0] : 0, mesh.positions.size() >= 3 ? mesh.positions[1] : 0, mesh.positions.size() >= 3 ? mesh.positions[2] : 0};
    Vec3 hi = lo;
    for (std::size_t v = 0; v < nv; ++v) {
        const Vec3 p{mesh.positions[v * 3], mesh.positions[v * 3 + 1], mesh.positions[v * 3 + 2]};
        lo = {std::min(lo.x, p.x), std::min(lo.y, p.y), std::min(lo.z, p.z)};
        hi = {std::max(hi.x, p.x), std::max(hi.y, p.y), std::max(hi.z, p.z)};
    }
    const float diag = length(hi - lo);
    auto position = [&](std::size_t v) { return Vec3{mesh.positions[v * 3], mesh.positions[v * 3 + 1], mesh.positions[v * 3 + 2]}; };

    // the surface graph of the whole mesh, built when the first smooth or mirror needs it
    std::vector<char> allOn(tris, 1);
    Weld weld;
    std::vector<std::vector<std::uint32_t>> vertsOf;
    bool haveWeld = false;
    auto ensure_weld = [&] {
        if (haveWeld) return;
        weld = build_weld(mesh, allOn, std::max(diag * 1e-5f, 1e-7f));
        vertsOf.assign(weld.nodes(), {});
        for (std::size_t v = 0; v < nv; ++v)
            if (weld.nodeOf[v] != kNone) vertsOf[weld.nodeOf[v]].push_back(std::uint32_t(v));
        haveWeld = true;
    };

    // the face queries need the model as a ModelMesh
    ModelMesh soup;
    ModelEditContext ctx;
    bool haveSoup = false;
    auto ensure_soup = [&] {
        if (haveSoup) return;
        for (std::size_t v = 0; v < nv; ++v) {
            soup.positions.push_back(position(v));
            soup.normals.push_back({mesh.normals[v * 3], mesh.normals[v * 3 + 1], mesh.normals[v * 3 + 2]});
            soup.uvs.push_back({mesh.uvs.size() > v * 2 + 1 ? mesh.uvs[v * 2] : 0.0f, mesh.uvs.size() > v * 2 + 1 ? mesh.uvs[v * 2 + 1] : 0.0f});
        }
        for (std::size_t t = 0; t < tris; ++t) {
            for (int k = 0; k < 3; ++k) soup.indices.push_back(mesh.indices[t * 3 + std::size_t(k)]);
            soup.triParts.push_back(model.triSub[t] == kNone ? 0u : model.triSub[t]);
        }
        for (const MeshSubmesh& sm : mesh.submeshes) {
            ctx.partNames.push_back(sm.part);
            ctx.materialNames.push_back(sm.material.name);
        }
        haveSoup = true;
    };

    for (const RigSkinEdit& e : settings.edits) {
        for (const std::string& part : e.parts)
            if (std::find(named.begin(), named.end(), part) == named.end())
                return make_error(std::format("{}: the edit works on the part '{}', which the model does not have", e.pointer, part),
                                  did_you_mean(part, named) + " The parts of the model: " + join(named, ", ") + ".");
        int bone = -1;
        if (e.op == "set" || e.op == "add") {
            bone = fit.find(e.bone);
            if (bone < 0) return make_error(std::format("{}: '{}' is not a bone of the {} rig", e.pointer, e.bone, fit.templateName), did_you_mean(e.bone, bone_names));
        }
        // the triangles the edit works on, then their vertices
        std::vector<char> triSel(tris, 1);
        bool restricted = false;
        if (!e.parts.empty()) {
            restricted = true;
            for (std::size_t t = 0; t < tris; ++t) {
                const std::uint32_t s = model.triSub[t];
                triSel[t] = s != kNone && std::find(e.parts.begin(), e.parts.end(), model.partNames[s]) != e.parts.end();
            }
        }
        if (!e.select.is_null()) {
            restricted = true;
            ensure_soup();
            const std::vector<char> q = model_select_triangles(soup, e.select, ctx);
            for (std::size_t t = 0; t < tris; ++t) triSel[t] = triSel[t] && t < q.size() && q[t];
        }
        std::vector<char> sel(nv, restricted ? 0 : 1);
        if (restricted)
            for (std::size_t t = 0; t < tris; ++t)
                if (triSel[t])
                    for (int k = 0; k < 3; ++k) {
                        const std::uint32_t v = mesh.indices[t * 3 + std::size_t(k)];
                        if (v < nv) sel[v] = 1;
                    }

        if (e.op == "set") {
            for (std::size_t v = 0; v < nv; ++v) {
                if (!sel[v]) continue;
                Infl& w = W[v];
                float others = 0;
                for (const auto& x : w)
                    if (x.first != bone) others += x.second;
                Infl next;
                if (others <= 1e-9f) {
                    next.push_back({std::uint16_t(bone), 1.0f});
                } else {
                    for (const auto& x : w)
                        if (x.first != bone) next.push_back({x.first, x.second * (1.0f - e.weight) / others});
                    if (e.weight > 0) next.push_back({std::uint16_t(bone), e.weight});
                }
                sort_infl(next);
                normalize_infl(next, 1e-6f);
                w = std::move(next);
            }
        } else if (e.op == "add") {
            for (std::size_t v = 0; v < nv; ++v) {
                if (!sel[v]) continue;
                Infl w = W[v];
                bool found = false;
                for (auto& x : w)
                    if (x.first == bone) {
                        x.second = std::max(0.0f, x.second + e.amount);
                        found = true;
                    }
                if (!found && e.amount > 0) w.push_back({std::uint16_t(bone), e.amount});
                if (total_of(w) <= 1e-6f) continue;  // the edit would leave nothing: keep the vertex as it was
                sort_infl(w);
                normalize_infl(w, 1e-6f);
                W[v] = std::move(w);
            }
        } else if (e.op == "normalize") {
            for (std::size_t v = 0; v < nv; ++v)
                if (sel[v]) normalize_infl(W[v], e.threshold);
        } else if (e.op == "limit") {
            for (std::size_t v = 0; v < nv; ++v)
                if (sel[v]) limit_infl(W[v], e.max);
        } else if (e.op == "smooth") {
            ensure_weld();
            std::vector<float> acc(nb);
            for (int pass = 0; pass < e.iterations; ++pass) {
                std::vector<Infl> next = W;
                for (std::size_t v = 0; v < nv; ++v) {
                    if (!sel[v] || weld.nodeOf[v] == kNone) continue;
                    const std::uint32_t node = weld.nodeOf[v];
                    // the vertices around: those at the neighbouring nodes, and the others at this node
                    std::vector<std::uint32_t> around;
                    for (std::uint32_t k = weld.rowStart[node]; k < weld.rowStart[node + 1]; ++k)
                        for (std::uint32_t u : vertsOf[weld.col[k]]) around.push_back(u);
                    for (std::uint32_t u : vertsOf[node])
                        if (u != v) around.push_back(u);
                    if (around.empty()) continue;
                    std::fill(acc.begin(), acc.end(), 0.0f);
                    accumulate(W[v], 1.0f - e.strength, acc);
                    for (std::uint32_t u : around) accumulate(W[u], e.strength / float(around.size()), acc);
                    Infl blended = from_dense(acc, 1e-4f);
                    if (blended.empty()) continue;
                    normalize_infl(blended, 0.0f);
                    next[v] = std::move(blended);
                }
                W = std::move(next);
            }
        } else if (e.op == "mirror") {
            ensure_weld();
            // the plane: the fit's symmetry plane; the vertices to change are on the other side of the source
            const float plane = fit.symmetryX;
            const float tol = std::max(diag * 2e-3f, 1e-6f);
            const float cell = std::max(diag * 0.01f, tol);
            using Key = std::tuple<long long, long long, long long>;
            auto key_of = [&](Vec3 p) { return Key{std::llround(double(p.x / cell)), std::llround(double(p.y / cell)), std::llround(double(p.z / cell))}; };
            std::map<Key, std::vector<std::uint32_t>> grid;
            for (std::size_t v = 0; v < nv; ++v)
                if (model.vertSub[v] != kNone) grid[key_of(position(v))].push_back(std::uint32_t(v));
            std::vector<int> boneMirror(nb);
            for (std::size_t b = 0; b < nb; ++b) {
                const int m = fit.find(mirror_name(fit.bones[b].name));
                boneMirror[b] = m >= 0 ? m : int(b);
            }
            const bool fromLeft = e.from == "l";  // character-left is +X
            const float reach = std::max(diag * 0.02f, tol);
            std::vector<Infl> next = W;
            for (std::size_t v = 0; v < nv; ++v) {
                if (!sel[v] || model.vertSub[v] == kNone) continue;
                const Vec3 p = position(v);
                const float side = p.x - plane;
                if (std::fabs(side) <= tol) continue;      // on the plane: it is its own mirror
                if ((side > 0) == fromLeft) continue;      // this is the source side, it stays
                const Vec3 q{2 * plane - p.x, p.y, p.z};
                const int span = int(std::ceil(reach / cell));
                const Key kq = key_of(q);
                float best = reach * reach;
                std::uint32_t found = kNone;
                // vertices of different parts can sit at the same place (where two parts touch): the partner is in the mirrored part
                const std::string wantedPart = mirror_name(model.partNames[model.vertSub[v]]);
                bool foundRight = false;
                for (int dx = -span; dx <= span; ++dx)
                    for (int dy = -span; dy <= span; ++dy)
                        for (int dz = -span; dz <= span; ++dz) {
                            auto it = grid.find(Key{std::get<0>(kq) + dx, std::get<1>(kq) + dy, std::get<2>(kq) + dz});
                            if (it == grid.end()) continue;
                            for (std::uint32_t u : it->second) {
                                const float d = length_sq(position(u) - q);
                                const bool right = model.partNames[model.vertSub[u]] == wantedPart;
                                if (d > reach * reach) continue;
                                if (found == kNone || (right && !foundRight) || (right == foundRight && (d < best || (d == best && u < found)))) {
                                    best = d;
                                    found = u;
                                    foundRight = right;
                                }
                            }
                        }
                if (found == kNone) {
                    ++report.mirrorUnmatched;
                    continue;
                }
                Infl m;
                for (const auto& x : W[found]) m.push_back({std::uint16_t(boneMirror[x.first]), x.second});
                // two bones may map to the same one (a bone with no counterpart): merge
                std::sort(m.begin(), m.end());
                Infl merged;
                for (const auto& x : m) {
                    if (!merged.empty() && merged.back().first == x.first) merged.back().second += x.second;
                    else merged.push_back(x);
                }
                next[v] = std::move(merged);
            }
            W = std::move(next);
        }
        ++report.editsApplied;
    }
    if (report.mirrorUnmatched)
        report.warnings.push_back(std::format("{} vertex(es) had no mirror partner within 2% of the model's size and keep their weights. The model is not symmetric "
                                              "there: edit them by hand, or fit the rig's symmetryX.",
                                              report.mirrorUnmatched));
    return {};
}

}  // namespace fa::rig_skin_detail
