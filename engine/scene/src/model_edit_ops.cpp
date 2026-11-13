// The edit operations of model documents that work on a selection (fa/scene/model_select.h): extrude_faces, inset_faces, loop_cut,
// bevel_edges, delete_faces and assign_faces.
//
// Method. The mesh is welded into a Soup (model_mesh_ops.h), the selection is evaluated on it (model_select.cpp) and the edit is done on the soup:
// new vertices are appended, the selected triangles are rewired to them and the walls / rings are new triangles. Every triangle keeps the part of the
// one it came from (a wall or ring takes the part of the face it grew from, or `newPart` / `newMaterial` through the evaluator's group table).
// Normals: a triangle that was not touched keeps the normals it had; a new or moved one gets smoothing-group normals computed over the whole
// result (corners of faces that turn by less than 40 degrees share a normal), so a flat cap stays flat and a rounded wall stays round.
#include <algorithm>
#include <cmath>
#include <format>
#include <map>
#include <optional>
#include <set>

#include "fa/core/strings.h"
#include "model_select_impl.h"

namespace fa {

using mm::Attr;
using mm::Edges;
using mm::EdgeUse;
using mm::Soup;
using sel::Selector;

namespace {

Result<ModelEditResult> fail_edit(const std::string& message, const std::string& hint) {
    return make_error(message, hint);
}

// The soup being edited with the normals its triangles keep (zero = compute).
struct Work {
    Soup s;
    std::vector<std::array<Vec3, 3>> nrm;
};

Work make_work(const ModelMesh& m) {
    Work w;
    w.s = mm::to_soup(m);
    w.nrm.assign(w.s.tris.size(), {Vec3{0, 0, 0}, Vec3{0, 0, 0}, Vec3{0, 0, 0}});
    if (m.normals.size() == m.positions.size())
        for (std::size_t t = 0; t < w.s.tris.size(); ++t)
            for (std::size_t k = 0; k < 3; ++k) w.nrm[t][k] = m.normals[m.indices[std::size_t(w.s.src[t]) * 3 + k]];
    return w;
}

void add_tri(Work& w, std::uint32_t a, std::uint32_t b, std::uint32_t c, const Attr& aa, const Attr& ab, const Attr& ac,
             std::uint32_t part) {
    w.s.add_tri(a, b, c, aa, ab, ac, part);
    w.nrm.push_back({Vec3{0, 0, 0}, Vec3{0, 0, 0}, Vec3{0, 0, 0}});
}

constexpr float kCrease = 40.0f;

ModelMesh finish(const Work& w) {
    const std::vector<Vec3> computed = mm::corner_normals(w.s, kCrease);
    std::vector<Vec3> normals(w.s.tris.size() * 3);
    for (std::size_t t = 0; t < w.s.tris.size(); ++t)
        for (std::size_t k = 0; k < 3; ++k)
            normals[t * 3 + k] = length_sq(w.nrm[t][k]) > 0.25f ? w.nrm[t][k] : computed[t * 3 + k];
    return mm::from_soup_normals(w.s, normals);
}

// The border of a set of triangles: the sides that have a selected triangle on one side only.
struct Side {
    std::uint32_t tri;
    std::uint32_t a, b;  // the side as the selected triangle walks it
    Vec3 cross;          // that triangle's (area-weighted) normal, before the edit
    std::array<Attr, 2> attr;
};
struct Region {
    std::vector<Side> border;
    std::vector<char> onBorder, inRegion;  // per welded vertex
};

Region make_region(const Soup& s, const Edges& e, const std::vector<char>& sel) {
    Region r;
    r.onBorder.assign(s.pos.size(), 0);
    r.inRegion.assign(s.pos.size(), 0);
    for (std::size_t t = 0; t < s.tris.size(); ++t)
        if (sel[t])
            for (std::uint32_t v : s.tris[t]) r.inRegion[v] = 1;
    for (std::size_t i = 0; i < e.edges.size(); ++i) {
        std::uint32_t selected = 0, which = 0;
        for (std::uint32_t k = 0; k < e.edges[i].count; ++k)
            if (sel[e.uses[e.edges[i].first + k].tri]) {
                ++selected;
                which = e.edges[i].first + k;
            }
        if (selected != 1) continue;
        const EdgeUse& u = e.uses[which];
        Side side;
        side.tri = u.tri;
        side.a = s.tris[u.tri][u.slot];
        side.b = s.tris[u.tri][(u.slot + 1) % 3];
        side.cross = s.face_cross(u.tri);
        side.attr = {s.attr[u.tri][u.slot], s.attr[u.tri][(u.slot + 1) % 3]};
        r.onBorder[side.a] = r.onBorder[side.b] = 1;
        r.border.push_back(side);
    }
    return r;
}

// Sum of the (area-weighted) normals of the selected triangles around each vertex.
std::vector<Vec3> vertex_normals(const Soup& s, const std::vector<char>& sel) {
    std::vector<Vec3> acc(s.pos.size(), Vec3{0, 0, 0});
    for (std::size_t t = 0; t < s.tris.size(); ++t)
        if (sel[t])
            for (std::uint32_t v : s.tris[t]) acc[v] += s.face_cross(t);
    return acc;
}

std::optional<std::string> opt_string(const Json& p, const char* key) {
    if (!p.contains(key)) return std::nullopt;
    return p[key].get<std::string>();
}

// A material named by an edit op must be one of the document's.
std::optional<std::string> check_material(const std::optional<std::string>& material, const ModelEditContext& ctx,
                                          const char* field) {
    if (!material ||
        std::find(ctx.materialNames.begin(), ctx.materialNames.end(), *material) != ctx.materialNames.end())
        return std::nullopt;
    return std::format("{} \"{}\" is not in the document's `materials`. {}", field, *material,
                       ctx.materialNames.empty() ? "The document has no materials yet: add {\"materials\": {\"" +
                                                       *material + "\": {\"color\": [0.6, 0.4, 0.2, 1]}}}."
                                                 : did_you_mean(*material, ctx.materialNames));
}

std::string rounded(float v) { return std::format("{:g}", std::round(v * 10000.0) / 10000.0); }

std::uint32_t new_group(const ModelEditContext& ctx, std::uint32_t source, const std::optional<std::string>& part,
                        const std::optional<std::string>& material) {
    return part || material ? ctx.group_with(source, part, material) : source;
}

// A mesh with too many triangles is refused before it is built.
std::optional<std::string> too_big(std::size_t triangles, const char* what) {
    if (triangles <= kModelMaxTriangles) return std::nullopt;
    return std::format("{} would make {} triangles, more than the limit of {}", what, triangles, kModelMaxTriangles);
}

// ---- extrude_faces and inset_faces ---------------------------------------------------------------------------------------------

Result<ModelEditResult> extrude_or_inset(const ModelNode& node, const ModelMesh& input, const ModelEditContext& ctx,
                                         Selector& selector, const std::vector<char>& sel, ModelEditResult& result) {
    const Json& p = node.params;
    const bool extrude = node.op == "extrude_faces";
    const Soup& soup = selector.soup();
    const std::optional<std::string> newPart = opt_string(p, "newPart"), newMaterial = opt_string(p, "newMaterial");
    if (auto bad = check_material(newMaterial, ctx, "newMaterial"))
        return fail_edit(*bad, "Use a key of the document's `materials`.");

    Work w;
    w.s = soup;
    w.nrm.assign(soup.tris.size(), {Vec3{0, 0, 0}, Vec3{0, 0, 0}, Vec3{0, 0, 0}});
    if (input.normals.size() == input.positions.size())
        for (std::size_t t = 0; t < soup.tris.size(); ++t)
            for (std::size_t k = 0; k < 3; ++k)
                w.nrm[t][k] = input.normals[input.indices[std::size_t(soup.src[t]) * 3 + k]];

    const Region region = make_region(soup, selector.edge_table(), sel);
    const std::vector<Vec3> vnormal = vertex_normals(soup, sel);
    auto unit = [](Vec3 v) { return mm::unit_or(v, Vec3{0, 0, 0}); };

    // Where each region vertex goes.
    std::vector<Vec3> move(soup.pos.size(), Vec3{0, 0, 0});
    if (extrude) {
        const float distance = p["distance"].get<float>();
        const bool hasDir = p.contains("direction");
        const Vec3 dir = hasDir ? unit(p["direction"].is_string() ? [&] {
            for (const auto& [n, v] : model_named_directions())
                if (n == p["direction"].get<std::string>()) return v;
            return Vec3{0, 1, 0};
        }() : Vec3{p["direction"][0].get<float>(), p["direction"][1].get<float>(), p["direction"][2].get<float>()})
                                : Vec3{0, 0, 0};
        if (std::fabs(distance) < 1e-7f) {
            result.warnings.push_back("distance is 0, so nothing was extruded: give a distance such as 0.2 (negative "
                                      "pushes the faces into the model)");
            result.mesh = input;
            return result;
        }
        for (std::size_t v = 0; v < soup.pos.size(); ++v)
            if (region.inRegion[v]) move[v] = (hasDir ? dir : unit(vnormal[v])) * distance;
    } else {
        const float thickness = p["thickness"].get<float>(), depth = p["depth"].get<float>();
        if (region.border.empty()) {
            result.warnings.push_back("the selected faces have no border to inset from (they are every face of a "
                                      "closed mesh): select a part of the surface, e.g. one side");
            result.mesh = input;
            return result;
        }
        // inward directions on the border: n x edge points to the inside of the selected triangle
        std::vector<Vec3> inwardSum(soup.pos.size(), Vec3{0, 0, 0});
        std::vector<int> inwardCount(soup.pos.size(), 0);
        for (const Side& side : region.border) {
            const Vec3 in = unit(cross(unit(side.cross), soup.pos[side.b] - soup.pos[side.a]));
            inwardSum[side.a] += in;
            inwardSum[side.b] += in;
            ++inwardCount[side.a];
            ++inwardCount[side.b];
        }
        auto offsets = [&](float t) {
            std::vector<Vec3> d(soup.pos.size(), Vec3{0, 0, 0});
            for (std::size_t v = 0; v < soup.pos.size(); ++v)
                if (inwardCount[v] > 0) {
                    const Vec3 avg = inwardSum[v] / float(inwardCount[v]);
                    d[v] = avg * (t / std::max(dot(avg, avg), 0.1f));
                }
            return d;
        };
        auto fits = [&](float t) {
            const std::vector<Vec3> d = offsets(t);
            // a border side must keep its direction: a border pushed past the opposite one is a turned-around copy that the area test accepts
            for (const Side& side : region.border) {
                const Vec3 before = soup.pos[side.b] - soup.pos[side.a];
                const Vec3 after = before + d[side.b] - d[side.a];
                if (dot(before, after) <= 1e-4f * dot(before, before)) return false;
            }
            for (std::size_t tr = 0; tr < soup.tris.size(); ++tr) {
                if (!sel[tr]) continue;
                const auto& ids = soup.tris[tr];
                const Vec3 c = cross(soup.pos[ids[1]] + d[ids[1]] - soup.pos[ids[0]] - d[ids[0]],
                                     soup.pos[ids[2]] + d[ids[2]] - soup.pos[ids[0]] - d[ids[0]]);
                const Vec3 o = soup.face_cross(tr);
                if (dot(c, o) <= 1e-4f * dot(o, o)) return false;
            }
            return true;
        };
        if (!fits(thickness)) {
            float lo = 0, hi = thickness;
            for (int it = 0; it < 24; ++it) {
                const float mid = 0.5f * (lo + hi);
                (fits(mid) ? lo : hi) = mid;
            }
            return fail_edit(
                std::format("thickness {} is more than the selected faces can give: they would turn inside out",
                            rounded(thickness)),
                lo > 1e-4f
                    ? std::format("The most these faces allow is about {}: use {} or less, or select larger faces.",
                                  rounded(lo), rounded(lo * 0.9f))
                    : "The border is too close to the faces' interior: select larger faces, or a region with more "
                      "faces in it.");
        }
        const std::vector<Vec3> d = offsets(thickness);
        for (std::size_t v = 0; v < soup.pos.size(); ++v)
            if (region.inRegion[v]) move[v] = d[v] + unit(vnormal[v]) * depth;
    }

    // Size check before building: the walls or ring are two triangles per border side.
    if (auto big = too_big(soup.tris.size() + region.border.size() * 2, extrude ? "the extrusion" : "the inset"))
        return fail_edit(*big, "Select fewer faces, or use fewer segments on the model below.");

    // Border vertices get a copy that the selected faces move to; the others move where they are.
    const Soup before = soup;
    std::vector<std::uint32_t> copy(soup.pos.size(), UINT32_MAX);
    for (std::size_t v = 0; v < soup.pos.size(); ++v) {
        if (!region.inRegion[v]) continue;
        if (region.onBorder[v])
            copy[v] = w.s.add_vertex(soup.pos[v] + move[v]);
        else
            w.s.pos[v] = soup.pos[v] + move[v];
    }
    for (std::size_t t = 0; t < before.tris.size(); ++t) {
        if (!sel[t]) continue;
        for (std::size_t k = 0; k < 3; ++k)
            if (copy[w.s.tris[t][k]] != UINT32_MAX) w.s.tris[t][k] = copy[before.tris[t][k]];
        w.nrm[t] = {Vec3{0, 0, 0}, Vec3{0, 0, 0}, Vec3{0, 0, 0}};
        if (extrude)
            w.s.part[t] = new_group(ctx, w.s.part[t], newPart, newMaterial);  // the cap is part of what was pushed out
    }
    for (const Side& side : region.border) {
        const std::uint32_t part = new_group(ctx, before.part[side.tri], newPart, newMaterial);
        const std::uint32_t a = side.a, b = side.b, a2 = copy[side.a], b2 = copy[side.b];
        bool flip = false;
        if (extrude)
            flip = dot(move[side.a] + move[side.b], side.cross) <
                   0;  // pushed into the model: the walls face the other way
        if (!flip) {
            add_tri(w, a, b, b2, side.attr[0], side.attr[1], side.attr[1], part);
            add_tri(w, a, b2, a2, side.attr[0], side.attr[1], side.attr[0], part);
        } else {
            add_tri(w, a, b2, b, side.attr[0], side.attr[1], side.attr[1], part);
            add_tri(w, a, a2, b2, side.attr[0], side.attr[0], side.attr[1], part);
        }
    }
    result.mesh = finish(w);
    return result;
}

// ---- loop_cut -----------------------------------------------------------------------------------------------------------------

int axis_of(const std::string& a) { return a == "x" ? 0 : a == "y" ? 1 : 2; }
float comp(Vec3 v, int axis) { return axis == 0 ? v.x : axis == 1 ? v.y : v.z; }

// Cuts every triangle that crosses the plane `axis = h`; returns how many were cut.
std::size_t cut_plane(Work& w, int axis, float h, float eps) {
    Soup& s = w.s;
    const std::size_t count = s.tris.size();
    std::vector<int> side(s.pos.size());
    for (std::size_t v = 0; v < s.pos.size(); ++v) {
        const float c = comp(s.pos[v], axis) - h;
        side[v] = c > eps ? 1 : c < -eps ? -1 : 0;
    }
    Soup out;
    out.pos = s.pos;
    out.colors = s.colors;
    std::vector<std::array<Vec3, 3>> nrm;
    std::map<std::pair<std::uint32_t, std::uint32_t>, std::uint32_t> split;
    std::size_t cuts = 0;
    auto vertex_on = [&](std::uint32_t a, std::uint32_t b) {
        const std::uint32_t lo = std::min(a, b), hi = std::max(a, b);
        auto [it, fresh] = split.emplace(std::make_pair(lo, hi), 0u);
        if (fresh) {
            const float ca = comp(s.pos[lo], axis), cb = comp(s.pos[hi], axis);
            const float t = (h - ca) / (cb - ca);
            Vec3 p = s.pos[lo] + (s.pos[hi] - s.pos[lo]) * t;
            (axis == 0 ? p.x : axis == 1 ? p.y : p.z) = h;
            it->second = out.add_vertex(p);
        }
        return it->second;
    };
    auto push = [&](std::uint32_t a, std::uint32_t b, std::uint32_t c, const Attr& aa, const Attr& ab, const Attr& ac,
                    const Vec3& na, const Vec3& nb, const Vec3& nc, std::uint32_t part) {
        out.add_tri(a, b, c, aa, ab, ac, part);
        nrm.push_back({na, nb, nc});
    };
    auto lerp_n = [](const Vec3& a, const Vec3& b, float t) { return mm::unit_or(a + (b - a) * t, a); };
    for (std::size_t t = 0; t < count; ++t) {
        const auto& ids = s.tris[t];
        const int sg[3] = {side[ids[0]], side[ids[1]], side[ids[2]]};
        const bool crosses = (sg[0] > 0 || sg[1] > 0 || sg[2] > 0) && (sg[0] < 0 || sg[1] < 0 || sg[2] < 0);
        if (!crosses) {
            push(ids[0], ids[1], ids[2], s.attr[t][0], s.attr[t][1], s.attr[t][2], w.nrm[t][0], w.nrm[t][1],
                 w.nrm[t][2], s.part[t]);
            continue;
        }
        ++cuts;
        // rotate so corner 0 is the lone vertex on its side (or the vertex on the plane)
        int k0 = 0;
        const int zeros = (sg[0] == 0) + (sg[1] == 0) + (sg[2] == 0);
        if (zeros == 1)
            k0 = sg[0] == 0 ? 0 : sg[1] == 0 ? 1 : 2;
        else {
            const int pos = (sg[0] > 0) + (sg[1] > 0) + (sg[2] > 0);
            const int loneSide = pos == 1 ? 1 : -1;
            k0 = sg[0] == loneSide ? 0 : sg[1] == loneSide ? 1 : 2;
        }
        const std::size_t k1 = (std::size_t(k0) + 1) % 3, k2 = (std::size_t(k0) + 2) % 3;
        const std::uint32_t A = ids[std::size_t(k0)], B = ids[k1], C = ids[k2];
        const Attr &aA = s.attr[t][std::size_t(k0)], &aB = s.attr[t][k1], &aC = s.attr[t][k2];
        const Vec3 &nA = w.nrm[t][std::size_t(k0)], &nB = w.nrm[t][k1], &nC = w.nrm[t][k2];
        auto along = [&](std::uint32_t from, std::uint32_t to) {
            const float cf = comp(s.pos[from], axis), ct = comp(s.pos[to], axis);
            return (h - cf) / (ct - cf);
        };
        if (zeros == 1) {  // A is on the plane, B and C on opposite sides: split BC
            const std::uint32_t P = vertex_on(B, C);
            const float f = along(B, C);
            const Attr aP = mm::lerp_attr(aB, aC, f);
            const Vec3 nP = length_sq(nB) > 0 && length_sq(nC) > 0 ? lerp_n(nB, nC, f) : Vec3{0, 0, 0};
            push(A, B, P, aA, aB, aP, nA, nB, nP, s.part[t]);
            push(A, P, C, aA, aP, aC, nA, nP, nC, s.part[t]);
        } else {  // A alone on its side: split AB and AC
            const std::uint32_t P = vertex_on(A, B), Q = vertex_on(A, C);
            const float fp = along(A, B), fq = along(A, C);
            const Attr aP = mm::lerp_attr(aA, aB, fp), aQ = mm::lerp_attr(aA, aC, fq);
            const bool hasN = length_sq(nA) > 0 && length_sq(nB) > 0 && length_sq(nC) > 0;
            const Vec3 nP = hasN ? lerp_n(nA, nB, fp) : Vec3{0, 0, 0}, nQ = hasN ? lerp_n(nA, nC, fq) : Vec3{0, 0, 0};
            push(A, P, Q, aA, aP, aQ, nA, nP, nQ, s.part[t]);
            push(P, B, C, aP, aB, aC, nP, nB, nC, s.part[t]);
            push(P, C, Q, aP, aC, aQ, nP, nC, nQ, s.part[t]);
        }
    }
    s = std::move(out);
    w.nrm = std::move(nrm);
    return cuts;
}

Result<ModelEditResult> loop_cut(const ModelNode& node, const ModelMesh& input, ModelEditResult& result,
                                 const ModelEditContext& ctx) {
    const Json& p = node.params;
    const int axis = axis_of(p["axis"].get<std::string>());
    Work w = make_work(input);
    if (w.s.tris.empty()) {
        result.warnings.push_back("there is nothing to cut: the mesh below has no faces");
        result.mesh = input;
        return result;
    }
    float lo = 1e30f, hi = -1e30f;
    for (const auto& tri : w.s.tris)
        for (std::uint32_t v : tri) {
            lo = std::min(lo, comp(w.s.pos[v], axis));
            hi = std::max(hi, comp(w.s.pos[v], axis));
        }
    std::vector<float> planes;
    if (p.contains("at"))
        planes.push_back(p["at"].get<float>());
    else if (p.contains("ratio"))
        planes.push_back(lo + p["ratio"].get<float>() * (hi - lo));
    else {
        const int n = p.contains("count") ? p["count"].get<int>() : 1;
        for (int i = 1; i <= n; ++i) planes.push_back(lo + (hi - lo) * (float(i) / float(n + 1)));
    }
    const float extent = hi - lo;
    const float eps = 1e-5f * std::max(extent, 1e-3f);
    const char axisLetter = "xyz"[axis];

    // Size check: a cut triangle becomes two or three.
    std::size_t crossing = 0;
    for (float h : planes)
        for (const auto& tri : w.s.tris) {
            const float c0 = comp(w.s.pos[tri[0]], axis), c1 = comp(w.s.pos[tri[1]], axis),
                        c2 = comp(w.s.pos[tri[2]], axis);
            if (std::min({c0, c1, c2}) < h && std::max({c0, c1, c2}) > h) ++crossing;
        }
    if (auto big = too_big(w.s.tris.size() + crossing * 2, "the loop cut"))
        return fail_edit(*big, "Lower `count`, or cut a mesh with fewer faces.");

    std::size_t cuts = 0;
    std::vector<float> done;
    for (float h : planes) {
        if (h <= lo + eps || h >= hi - eps) {
            result.warnings.push_back(
                std::format("the plane {} = {} is {} the mesh, which spans {} to {} along {}: nothing was cut there",
                            axisLetter, rounded(h),
                            h < lo   ? "below"
                            : h > hi ? "above"
                                     : "on the edge of",
                            rounded(lo), rounded(hi), axisLetter));
            continue;
        }
        const std::size_t n = cut_plane(w, axis, h, eps);
        if (n == 0)
            result.warnings.push_back(
                std::format("no face crosses the plane {} = {}: the mesh has a gap there, so nothing was cut",
                            axisLetter, rounded(h)));
        cuts += n;
        done.push_back(h);
    }
    if (cuts == 0) {
        result.mesh = input;
        return result;
    }
    result.mesh = finish(w);
    // report the loop(s) that now exist
    Json q = done.size() == 1 ? Json::object({{"by", "loop"}, {"axis", std::string(1, axisLetter)}, {"at", done[0]}})
                              : Json::object({{"by", "or"}, {"of", Json::array()}});
    if (done.size() > 1)
        for (float h : done)
            q["of"].push_back(Json::object({{"by", "loop"}, {"axis", std::string(1, axisLetter)}, {"at", h}}));
    ModelSelectionReport report = model_select_report(result.mesh, q, ModelSelectKind::Edges, ctx);
    report.warnings.clear();
    result.report = report;
    return result;
}

// ---- bevel_edges --------------------------------------------------------------------------------------------------------------

Result<ModelEditResult> bevel_edges(const ModelNode& node, const ModelMesh& input, ModelEditResult& result,
                                    Selector& selector, const std::vector<char>& mask) {
    const Json& p = node.params;
    const Soup& soup = selector.soup();
    const Edges& edges = selector.edge_table();
    std::set<std::array<float, 6>> chosen;
    for (std::size_t i = 0; i < edges.edges.size(); ++i)
        if (mask[i]) {
            const Vec3 a = soup.pos[edges.edges[i].lo], b = soup.pos[edges.edges[i].hi];
            chosen.insert({a.x, a.y, a.z, b.x, b.y, b.z});
        }
    ModelBevelParams q;
    q.width = p["width"].get<float>();
    q.segments = p["segments"].get<int>();
    q.roundness = p["roundness"].get<float>();
    q.angle = 1.0f;  // an edge that is flat is not a corner: leave it
    q.edgeFilter = [&](Vec3 a, Vec3 b) { return chosen.count({a.x, a.y, a.z, b.x, b.y, b.z}) > 0; };
    std::size_t bevelled = 0;
    auto made = model_bevel(input, q, &bevelled);
    if (!made) return fail_edit(made.error().message, made.error().hint);
    if (auto big = too_big(made->triangle_count(), "the bevel"))
        return fail_edit(*big, "Lower `segments`, or select fewer edges.");
    if (bevelled == 0)
        result.warnings.push_back(std::format(
            "none of the {} selected edge(s) could be bevelled: an edge that is flat (the faces on its two sides turn "
            "by less than 1 degree), open or shared by "
            "more than two faces is left alone. Select the corner edges, e.g. {{\"by\": \"sharp\", \"angle\": 30}}",
            result.report.matched));
    else if (bevelled < result.report.matched)
        result.warnings.push_back(std::format(
            "{} of the {} selected edges were bevelled; the others are flat, open or shared by more than two faces",
            bevelled, result.report.matched));
    result.mesh = std::move(*made);
    return result;
}

}  // namespace

bool model_is_edit_op(const std::string& op) {
    return op == "extrude_faces" || op == "inset_faces" || op == "loop_cut" || op == "bevel_edges" ||
           op == "delete_faces" || op == "assign_faces";
}

Result<ModelEditResult> model_apply_edit(const ModelNode& node, const ModelMesh& input,
                                         const ModelEditContext& context) {
    ModelEditResult result;
    result.mesh = input;
    const Json& p = node.params;
    if (node.op == "loop_cut") return loop_cut(node, input, result, context);

    const Soup soup = mm::to_soup(input);
    const Edges edges = mm::build_edges(soup);
    Selector selector(soup, edges, context);
    const bool edgeOp = node.op == "bevel_edges";
    const std::vector<char> mask = edgeOp ? selector.edges(p["edges"]) : selector.faces(p["faces"]);
    result.report = sel::make_report(selector, mask, edgeOp ? ModelSelectKind::Edges : ModelSelectKind::Faces, "");
    result.report.op = node.op;
    result.report.pointer = node.pointer;
    if (result.report.matched == 0) {
        result.report.warnings.push_back(sel::empty_warning(edgeOp ? "edges" : "faces", selector.notes) +
                                         "; the model is unchanged by " + node.op);
        result.warnings = result.report.warnings;
        return result;
    }
    Result<ModelEditResult> done = [&]() -> Result<ModelEditResult> {
        if (node.op == "delete_faces") {
            Work w = make_work(input);
            Work kept;
            kept.s = w.s;
            kept.s.tris.clear();
            kept.s.attr.clear();
            kept.s.part.clear();
            kept.s.src.clear();
            for (std::size_t t = 0; t < w.s.tris.size(); ++t) {
                if (mask[t]) continue;
                kept.s.tris.push_back(w.s.tris[t]);
                kept.s.attr.push_back(w.s.attr[t]);
                kept.s.part.push_back(w.s.part[t]);
                kept.s.src.push_back(w.s.src[t]);
                kept.nrm.push_back(w.nrm[t]);
            }
            if (kept.s.tris.empty()) {
                result.warnings.push_back("every face was deleted, so the node makes nothing: select fewer faces");
                result.mesh = ModelMesh{};
                return result;
            }
            result.mesh = finish(kept);
            return result;
        }
        if (node.op == "assign_faces") {
            const std::optional<std::string> part = opt_string(p, "toPart"), material = opt_string(p, "toMaterial");
            if (auto bad = check_material(material, context, "toMaterial"))
                return fail_edit(*bad, "Use a key of the document's `materials`.");
            for (std::size_t t = 0; t < soup.tris.size(); ++t)
                if (mask[t]) result.mesh.triParts[soup.src[t]] = new_group(context, soup.part[t], part, material);
            return result;
        }
        if (node.op == "bevel_edges") return bevel_edges(node, input, result, selector, mask);
        return extrude_or_inset(node, input, context, selector, mask, result);
    }();
    if (!done) return done;
    // keep the warnings the selection raised (a partial match is not an error)
    for (const std::string& w : result.report.warnings)
        if (std::find(done->warnings.begin(), done->warnings.end(), w) == done->warnings.end())
            done->warnings.push_back(w);
    return done;
}

}  // namespace fa
