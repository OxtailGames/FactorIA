// model_check.h: scale, origin, winding, closed-ness, degenerate triangles and platform budgets of a mesh.
#include "fa/scene/model_check.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <format>
#include <map>
#include <numeric>

#include "fa/scene/model_game_ready.h"

namespace fa {

namespace {

constexpr const char* kNoPart = "(no part)";

struct Tri {
    std::uint32_t v[3];  // welded vertex ids
    std::uint32_t i[3];  // original vertex indices
    std::uint32_t sub = 0;
    bool degenerate = false;
};

struct EdgeUse {
    std::uint32_t a, b;      // welded ids, a < b
    std::uint32_t tri;
    bool forward;            // the triangle walks a -> b (otherwise b -> a)
    std::uint32_t corner;    // which edge of the triangle: 0 (v0-v1), 1 (v1-v2), 2 (v2-v0)
};

Vec3 pos(const MeshData& m, std::uint32_t i) { return {m.positions[i * 3], m.positions[i * 3 + 1], m.positions[i * 3 + 2]}; }

std::string num(double v) {
    if (std::abs(v) >= 100) return std::format("{:.0f}", v);
    if (std::abs(v) >= 1) return std::format("{:.2f}", v);
    return std::format("{:.3g}", v);
}

// A set of triangles or edges a finding is about: counts, parts, bounds, evenly spread samples.
struct Collector {
    const MeshData& mesh;
    std::size_t maxSamples;
    std::size_t count = 0;
    std::vector<bool> partSeen;
    std::vector<Vec3> points;  // one per member (a centroid or an edge middle)
    Vec3 lo{1e30f, 1e30f, 1e30f}, hi{-1e30f, -1e30f, -1e30f};
    Collector(const MeshData& m, std::size_t samples) : mesh(m), maxSamples(samples), partSeen(m.submeshes.size(), false) {}
    void add(std::uint32_t sub, Vec3 p, Vec3 a, Vec3 b) {
        ++count;
        if (sub < partSeen.size()) partSeen[sub] = true;
        points.push_back(p);
        lo = {std::min({lo.x, a.x, b.x}), std::min({lo.y, a.y, b.y}), std::min({lo.z, a.z, b.z})};
        hi = {std::max({hi.x, a.x, b.x}), std::max({hi.y, a.y, b.y}), std::max({hi.z, a.z, b.z})};
    }
    void note_part(std::uint32_t sub) {
        if (sub < partSeen.size()) partSeen[sub] = true;
    }
    void fill(ModelFinding& f) const {
        f.count = count;
        f.bmin = lo;
        f.bmax = hi;
        for (std::size_t s = 0; s < partSeen.size(); ++s) {
            if (!partSeen[s]) continue;
            const std::string name = mesh.submeshes[s].part.empty() ? std::string(kNoPart) : mesh.submeshes[s].part;
            if (std::find(f.parts.begin(), f.parts.end(), name) == f.parts.end()) f.parts.push_back(name);
        }
        std::size_t n = std::min(points.size(), maxSamples);
        for (std::size_t k = 0; k < n; ++k) f.samples.push_back(points[k * points.size() / n]);
    }
};

std::string where(const ModelFinding& f) {
    std::string s;
    if (!f.parts.empty()) {
        s = f.parts.size() == 1 ? "part " : "parts ";
        for (std::size_t i = 0; i < f.parts.size(); ++i) s += (i ? ", " : "") + f.parts[i];
    }
    if (f.count > 0) s += std::format("{}within x {}..{}, y {}..{}, z {}..{} m", s.empty() ? "" : " ", num(f.bmin.x), num(f.bmax.x), num(f.bmin.y), num(f.bmax.y), num(f.bmin.z), num(f.bmax.z));
    return s;
}

int severity_rank(const std::string& s) { return s == "error" ? 0 : s == "warning" ? 1 : 2; }

}  // namespace

const std::vector<ModelCheckKind>& model_check_kinds() {
    static const std::vector<ModelCheckKind> v = {
        {"empty", "error", "The mesh has no triangles."},
        {"inside_out", "error", "A closed piece whose triangles all face inward (negative volume): it renders and lights inside out."},
        {"inconsistent_winding", "error", "Two neighbouring triangles disagree on which side is out: one of them is flipped."},
        {"non_manifold", "error", "An edge shared by more than two triangles: the surface branches there (it has no inside)."},
        {"flipped_normals", "warning", "Triangles whose stored normal points against their winding: they are lit from the wrong side."},
        {"open_edges", "warning", "Edges used by one triangle only: a hole in the surface, so the model is not a closed solid."},
        {"degenerate", "warning", "Triangles with no area (repeated or collinear corners): they draw nothing and only cost."},
        {"scale", "warning", "The size is far from the expected height, or from anything plausible in metres."},
        {"origin", "warning", "The model sits far from its own origin: placing an entity puts it somewhere else."},
        {"triangle_budget", "warning", "More triangles than a platform's budget for one model (info when an LOD fits)."},
        {"draw_call_budget", "warning", "More submeshes (draw calls) than a platform's budget."}};
    return v;
}

ModelCheckReport check_model_mesh(const MeshData& mesh, const ModelCheckOptions& options) {
    ModelCheckReport rep;
    const auto ignored = [&](const char* code) { return std::find(options.ignore.begin(), options.ignore.end(), code) != options.ignore.end(); };
    const auto push = [&](ModelFinding f) {
        if (!ignored(f.code.c_str())) rep.findings.push_back(std::move(f));
    };

    rep.vertices = mesh.vertex_count();
    rep.submeshes = mesh.submeshes.size();

    // The triangles that are drawn: the submesh ranges (indices outside every submesh are not drawn).
    std::vector<Tri> tris;
    const std::size_t vertexCount = mesh.vertex_count();
    for (std::size_t s = 0; s < mesh.submeshes.size(); ++s) {
        const MeshSubmesh& sm = mesh.submeshes[s];
        const std::size_t end = std::min<std::size_t>(std::size_t(sm.start) + sm.count, mesh.indices.size());
        for (std::size_t k = sm.start; k + 3 <= end; k += 3) {
            Tri t;
            bool valid = true;
            for (int c = 0; c < 3; ++c) {
                t.i[c] = mesh.indices[k + std::size_t(c)];
                if (t.i[c] >= vertexCount) valid = false;
            }
            if (!valid) continue;
            t.sub = std::uint32_t(s);
            tris.push_back(t);
        }
    }
    rep.triangles = tris.size();

    if (tris.empty()) {
        ModelFinding f;
        f.code = "empty";
        f.severity = "error";
        f.message = "The mesh has no triangles to draw.";
        f.hint = "Check that the document's tree produces a solid (a primitive or an sdf node) and that nothing hides it; `model.tree` lists the nodes.";
        push(f);
        for (const ModelFinding& f2 : rep.findings) (f2.severity == "error" ? rep.errors : f2.severity == "warning" ? rep.warnings : rep.infos)++;
        return rep;
    }

    // Bounds.
    Vec3 lo = pos(mesh, tris[0].i[0]), hi = lo;
    for (const Tri& t : tris)
        for (int c = 0; c < 3; ++c) {
            Vec3 p = pos(mesh, t.i[c]);
            lo = {std::min(lo.x, p.x), std::min(lo.y, p.y), std::min(lo.z, p.z)};
            hi = {std::max(hi.x, p.x), std::max(hi.y, p.y), std::max(hi.z, p.z)};
        }
    const Vec3 size = hi - lo;
    const double ext = std::max({double(size.x), double(size.y), double(size.z), 1e-6});
    rep.scale.size = size;
    rep.scale.bmin = lo;
    rep.scale.bmax = hi;
    rep.scale.height = size.y;
    rep.scale.versusFigure = double(size.y) / kModelReferenceHeight;

    // Weld the vertices by position (uv and normal seams share a corner).
    const double cell = std::max(ext * 1e-5, 1e-7);
    std::map<std::array<std::int64_t, 3>, std::uint32_t> welded;
    std::vector<std::uint32_t> weldedOf(vertexCount, 0xFFFFFFFFu);
    std::vector<Vec3> weldedPos;
    const auto weld = [&](std::uint32_t i) {
        if (weldedOf[i] != 0xFFFFFFFFu) return weldedOf[i];
        Vec3 p = pos(mesh, i);
        std::array<std::int64_t, 3> key = {std::int64_t(std::llround(double(p.x) / cell)), std::int64_t(std::llround(double(p.y) / cell)), std::int64_t(std::llround(double(p.z) / cell))};
        auto [it, inserted] = welded.try_emplace(key, std::uint32_t(weldedPos.size()));
        if (inserted) weldedPos.push_back(p);
        weldedOf[i] = it->second;
        return it->second;
    };
    for (Tri& t : tris)
        for (int c = 0; c < 3; ++c) t.v[c] = weld(t.i[c]);

    // Degenerate triangles, and the face normals of the rest.
    const double minArea2 = std::max(1e-7 * ext * ext, 1e-14);  // twice the area
    std::vector<Vec3> faceNormal(tris.size());
    Collector degenerate(mesh, options.maxSamples), flipped(mesh, options.maxSamples);
    std::size_t liveTriangles = 0;
    for (std::size_t n = 0; n < tris.size(); ++n) {
        Tri& t = tris[n];
        Vec3 a = pos(mesh, t.i[0]), b = pos(mesh, t.i[1]), c = pos(mesh, t.i[2]);
        Vec3 cr = cross(b - a, c - a);
        double area2 = length(cr);
        if (t.v[0] == t.v[1] || t.v[1] == t.v[2] || t.v[2] == t.v[0] || area2 <= minArea2) {
            t.degenerate = true;
            degenerate.add(t.sub, (a + b + c) / 3.0f, min(min(a, b), c), max(max(a, b), c));
            continue;
        }
        ++liveTriangles;
        faceNormal[n] = cr / float(area2);
        if (mesh.normals.size() == mesh.positions.size()) {
            Vec3 avg{};
            for (int k = 0; k < 3; ++k) avg = avg + Vec3{mesh.normals[t.i[k] * 3], mesh.normals[t.i[k] * 3 + 1], mesh.normals[t.i[k] * 3 + 2]};
            if (dot(avg, faceNormal[n]) < -0.2f * std::max(length(avg), 1e-6f))
                flipped.add(t.sub, (a + b + c) / 3.0f, min(min(a, b), c), max(max(a, b), c));
        }
    }
    rep.degenerateTriangles = degenerate.count;
    rep.flippedNormalTriangles = flipped.count;

    // Edges of the live triangles.
    std::vector<EdgeUse> edges;
    edges.reserve(liveTriangles * 3);
    for (std::size_t n = 0; n < tris.size(); ++n) {
        const Tri& t = tris[n];
        if (t.degenerate) continue;
        for (std::uint32_t c = 0; c < 3; ++c) {
            std::uint32_t a = t.v[c], b = t.v[(c + 1) % 3];
            edges.push_back({std::min(a, b), std::max(a, b), std::uint32_t(n), a < b, c});
        }
    }
    std::stable_sort(edges.begin(), edges.end(), [](const EdgeUse& x, const EdgeUse& y) { return x.a != y.a ? x.a < y.a : x.b < y.b; });

    // Pieces: triangles that touch through a welded vertex.
    std::vector<std::uint32_t> parent(weldedPos.size());
    std::iota(parent.begin(), parent.end(), 0u);
    const auto find = [&](std::uint32_t x) {
        while (parent[x] != x) x = parent[x] = parent[parent[x]];
        return x;
    };
    for (const Tri& t : tris) {
        if (t.degenerate) continue;
        std::uint32_t r0 = find(t.v[0]);
        for (int c = 1; c < 3; ++c) {
            std::uint32_t r = find(t.v[c]);
            if (r != r0) parent[std::max(r, r0)] = std::min(r, r0), r0 = std::min(r, r0);
        }
    }
    std::vector<char> pieceBad(weldedPos.size(), 0);  // an open, branching or disagreeing edge in it

    Collector open(mesh, options.maxSamples), branching(mesh, options.maxSamples), disagree(mesh, options.maxSamples);
    for (std::size_t k = 0; k < edges.size();) {
        std::size_t e = k;
        while (e < edges.size() && edges[e].a == edges[k].a && edges[e].b == edges[k].b) ++e;
        const std::size_t uses = e - k;
        const Vec3 pa = weldedPos[edges[k].a], pb = weldedPos[edges[k].b];
        const Vec3 mid = (pa + pb) * 0.5f;
        const Vec3 emin = min(pa, pb), emax = max(pa, pb);
        const std::uint32_t root = find(edges[k].a);
        if (uses == 1) {
            open.add(tris[edges[k].tri].sub, mid, emin, emax);
            pieceBad[root] = 1;
        } else if (uses > 2) {
            branching.add(tris[edges[k].tri].sub, mid, emin, emax);
            for (std::size_t j = k + 1; j < e; ++j) branching.note_part(tris[edges[j].tri].sub);
            pieceBad[root] = 1;
        } else if (edges[k].forward == edges[k + 1].forward) {
            disagree.add(tris[edges[k].tri].sub, mid, emin, emax);
            disagree.note_part(tris[edges[k + 1].tri].sub);
            pieceBad[root] = 1;
        }
        k = e;
    }
    rep.openEdges = open.count;
    rep.nonManifoldEdges = branching.count;
    rep.inconsistentEdges = disagree.count;

    // Volumes of the closed, consistent pieces (relative to the box middle for precision).
    const Vec3 mid3 = (lo + hi) * 0.5f;
    std::map<std::uint32_t, double> volume;
    std::map<std::uint32_t, std::vector<std::uint32_t>> pieceTris;
    for (std::size_t n = 0; n < tris.size(); ++n) {
        if (tris[n].degenerate) continue;
        std::uint32_t root = find(tris[n].v[0]);
        Vec3 a = weldedPos[tris[n].v[0]] - mid3, b = weldedPos[tris[n].v[1]] - mid3, c = weldedPos[tris[n].v[2]] - mid3;
        volume[root] += double(dot(a, cross(b, c))) / 6.0;
        pieceTris[root].push_back(std::uint32_t(n));
    }
    rep.pieces = volume.size();
    Collector inside(mesh, options.maxSamples);
    double totalVolume = 0;
    for (const auto& [root, v] : volume) {
        if (pieceBad[root]) continue;
        totalVolume += std::abs(v);
        if (v < -1e-9 * ext * ext * ext) {
            ++rep.insideOutPieces;
            for (std::uint32_t n : pieceTris[root]) {
                Vec3 a = pos(mesh, tris[n].i[0]), b = pos(mesh, tris[n].i[1]), c = pos(mesh, tris[n].i[2]);
                inside.add(tris[n].sub, (a + b + c) / 3.0f, min(min(a, b), c), max(max(a, b), c));
            }
        }
    }
    rep.scale.volume = totalVolume;

    // ---- findings, in catalog order ---------------------------------------------------------------------------------------
    if (rep.insideOutPieces > 0) {
        ModelFinding f;
        f.code = "inside_out";
        f.severity = "error";
        inside.fill(f);
        f.message = std::format("{} closed piece{} turned inside out ({} triangles face inward), {}.", rep.insideOutPieces, rep.insideOutPieces == 1 ? " is" : "s are", f.count, where(f));
        f.hint = "A mirrored node keeps its triangles facing out, so look at the nodes of the parts named here (`model.info` lists them): a boolean with its operands swapped, or a mesh imported with reversed triangles. Reverse the winding at its source and bake again.";
        push(f);
    }
    if (rep.inconsistentEdges > 0) {
        ModelFinding f;
        f.code = "inconsistent_winding";
        f.severity = "error";
        disagree.fill(f);
        f.message = std::format("{} edge{} where neighbouring triangles disagree on which side is out, {}.", f.count, f.count == 1 ? "" : "s", where(f));
        f.hint = "One of the two triangles of each edge is flipped. Rebuild the part from the document's nodes instead of editing indices, or flip the whole part when most of it is reversed.";
        push(f);
    }
    if (rep.nonManifoldEdges > 0) {
        ModelFinding f;
        f.code = "non_manifold";
        f.severity = "error";
        branching.fill(f);
        f.message = std::format("{} edge{} shared by more than two triangles, {}.", f.count, f.count == 1 ? " is" : "s are", where(f));
        f.hint = "Two solids touch along an edge or a face was added twice. Move the pieces apart or overlap them clearly, and union them in the tree so the boolean makes one surface.";
        push(f);
    }
    if (rep.flippedNormalTriangles > 0) {
        ModelFinding f;
        f.code = "flipped_normals";
        f.severity = "warning";
        flipped.fill(f);
        f.message = std::format("{} triangle{} stored normals pointing against their winding, {}.", f.count, f.count == 1 ? " has" : "s have", where(f));
        f.hint = "They will be lit from the wrong side. Re-evaluate the document (normals are computed from the winding) and avoid importing meshes whose normals were authored separately.";
        push(f);
    }
    if (rep.openEdges > 0) {
        ModelFinding f;
        f.code = "open_edges";
        f.severity = "warning";
        open.fill(f);
        f.message = std::format("{} edge{} used by a single triangle (a hole or an open border), {}.", f.count, f.count == 1 ? " is" : "s are", where(f));
        f.hint = "Close the hole (a cap, or a boolean with a closed solid) if the model should be solid. An open surface that is meant to be open (a plane, a cloth, a leaf) is fine: pass \"ignore\": [\"open_edges\"].";
        push(f);
    }
    if (rep.degenerateTriangles > 0) {
        ModelFinding f;
        f.code = "degenerate";
        f.severity = "warning";
        degenerate.fill(f);
        f.message = std::format("{} triangle{} no area (repeated or collinear corners), {}.", f.count, f.count == 1 ? " has" : "s have", where(f));
        f.hint = "They draw nothing. Remove the repeated vertices (a zero-size primitive, a revolve that touches its axis twice) or weld the nodes; `model.game_ready` with \"merge\" cleans them from a baked model.";
        push(f);
    }

    // Scale.
    {
        const double h = size.y;
        ModelFinding f;
        f.code = "scale";
        f.severity = "warning";
        f.count = 0;
        if (options.expectedHeight > 0) {
            const double ratio = h / options.expectedHeight;
            if (std::abs(ratio - 1.0) > options.tolerance) {
                const double factor = h > 1e-9 ? options.expectedHeight / h : 0;
                double snapped = factor;
                for (double p : {0.001, 0.01, 0.1, 10.0, 100.0, 1000.0, 0.0254, 39.37, 2.54, 0.3937})
                    if (factor > 0 && std::abs(factor / p - 1.0) < 0.15) snapped = p;
                f.message = std::format("The model is {} m tall (the largest side is {} m) but {} m was expected: {}x too {}.", num(h), num(ext), num(options.expectedHeight), num(ratio >= 1 ? ratio : 1.0 / std::max(ratio, 1e-9)), ratio >= 1 ? "big" : "small");
                f.hint = std::format("Multiply the whole model by {} (the root node's \"scale\"), or change the sizes in the document. Units are metres: the reference figure beside the model in `model.preview` is {} m.", num(snapped), num(kModelReferenceHeight));
                push(f);
            }
        } else if (ext < 0.02 || ext > 100.0) {
            const double target = ext < 0.02 ? 0.5 : 10.0;
            f.message = std::format("The largest side is {} m ({}x the {} m reference figure): {}.", num(ext), num(ext / kModelReferenceHeight), num(kModelReferenceHeight),
                                    ext < 0.02 ? "tiny, probably authored in millimetres or centimetres" : "huge, probably authored in centimetres or millimetres");
            f.hint = std::format("Units are metres (a person is {} m). Scale the root node by {} to make it about {} m, or pass \"expectedHeight\" to check against the height you mean.", num(kModelReferenceHeight),
                                 num(target / ext), num(target));
            push(f);
        }
    }

    // Origin.
    {
        const Vec3 c = (lo + hi) * 0.5f;
        const double reach = std::max(1.0, ext);
        const double dx = std::max({double(lo.x), -double(hi.x), 0.0}), dy = std::max({double(lo.y), -double(hi.y), 0.0}), dz = std::max({double(lo.z), -double(hi.z), 0.0});
        const double d = std::sqrt(dx * dx + dy * dy + dz * dz);
        if (d > reach) {
            ModelFinding f;
            f.code = "origin";
            f.severity = "warning";
            f.message = std::format("The model's box is {} m away from its origin (its middle is at x {}, y {}, z {}): an entity placed at a point shows the model {} m off.", num(d), num(c.x), num(c.y), num(c.z), num(d));
            f.hint = "Move the nodes around the origin, or set \"gameReady\": {\"origin\": \"bottom_center\"} so the baked model stands on its own origin.";
            push(f);
        }
    }

    // Budgets.
    {
        std::vector<std::string> names = options.platforms;
        if (names.empty())
            for (const ModelPlatformBudget& b : model_platform_budgets()) names.push_back(b.platform);
        for (const ModelPlatformBudget& b : model_platform_budgets()) {
            if (std::find(names.begin(), names.end(), b.platform) == names.end()) continue;
            if (rep.triangles > b.triangles) {
                std::size_t fit = 0;
                for (std::size_t i = 0; i < options.lodTriangles.size() && fit == 0; ++i)
                    if (options.lodTriangles[i] <= b.triangles) fit = i + 1;
                ModelFinding f;
                f.code = "triangle_budget";
                f.platform = b.platform;
                if (fit > 0) {
                    f.severity = "info";
                    f.message = std::format("{} triangles, over the {} budget of {} ({}); LOD{} ({} triangles) fits.", rep.triangles, b.platform, b.triangles, b.doc, fit, options.lodTriangles[fit - 1]);
                    f.hint = std::format("Have the game show LOD{} or lower on {} (the baked .glb carries the LODs).", fit, b.platform);
                } else {
                    f.severity = "warning";
                    f.message = std::format("{} triangles, over the {} budget of {} ({}) and no LOD is set to fit it.", rep.triangles, b.platform, b.triangles, b.doc);
                    f.hint = std::format("Lower the detail of the nodes (fewer segments, a coarser sdf resolution) or add \"gameReady\": {{\"lods\": [{{\"triangles\": {}}}]}}.", b.triangles);
                }
                push(f);
            }
            if (rep.submeshes > b.submeshes) {
                ModelFinding f;
                f.code = "draw_call_budget";
                f.severity = "warning";
                f.platform = b.platform;
                f.message = std::format("{} submeshes (draw calls), over the {} budget of {}.", rep.submeshes, b.platform, b.submeshes);
                f.hint = "Set \"gameReady\": {\"merge\": true} to join the submeshes that share a material, or give fewer parts distinct materials.";
                push(f);
            }
        }
    }

    // Errors first, then warnings, then info; the catalog order inside each group.
    std::stable_sort(rep.findings.begin(), rep.findings.end(), [](const ModelFinding& a, const ModelFinding& b) { return severity_rank(a.severity) < severity_rank(b.severity); });
    for (const ModelFinding& f : rep.findings) (f.severity == "error" ? rep.errors : f.severity == "warning" ? rep.warnings : rep.infos)++;
    return rep;
}

}  // namespace fa
