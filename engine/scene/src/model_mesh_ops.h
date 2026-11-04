// Private helpers shared by the modifiers (model_*.cpp): a triangle soup with welded vertex ids, the edge table, normals by smoothing angle
// and the way back to a ModelMesh. Not a public header: modifiers are in fa/scene/model_modifiers.h.
#pragma once

#include <array>
#include <cstdint>
#include <vector>

#include "fa/scene/model_kernel.h"

namespace fa::mm {

constexpr float kWeldTolerance = 1e-5f;  // positions closer than this are the same point of the surface

// What a triangle corner carries besides its position and normal.
struct Attr {
    Vec2 uv{};
    Vec4 color{1, 1, 1, 1};
};
inline Attr lerp_attr(const Attr& a, const Attr& b, float t) { return {lerp(a.uv, b.uv, t), {lerp(a.color.x, b.color.x, t), lerp(a.color.y, b.color.y, t), lerp(a.color.z, b.color.z, t), lerp(a.color.w, b.color.w, t)}}; }
inline Attr mix_attr(const Attr& a, float wa, const Attr& b, float wb, const Attr& c, float wc) {
    Attr r;
    r.uv = a.uv * wa + b.uv * wb + c.uv * wc;
    r.color = {a.color.x * wa + b.color.x * wb + c.color.x * wc, a.color.y * wa + b.color.y * wb + c.color.y * wc,
               a.color.z * wa + b.color.z * wb + c.color.z * wc, a.color.w * wa + b.color.w * wb + c.color.w * wc};
    return r;
}

// Triangles over WELDED vertex ids: two corners at the same place on the surface have the same id, whatever their normals and uvs, so
// the connectivity of the surface can be walked. Attributes are per corner.
struct Soup {
    std::vector<Vec3> pos;
    std::vector<std::array<std::uint32_t, 3>> tris;
    std::vector<std::array<Attr, 3>> attr;
    std::vector<std::uint32_t> part;
    std::vector<std::uint32_t> src;  // to_soup only: the triangle of the source mesh each soup triangle came from
    bool colors = false;  // the source mesh had vertex colours

    std::size_t triangle_count() const { return tris.size(); }
    std::uint32_t add_vertex(Vec3 p) {
        pos.push_back(p);
        return std::uint32_t(pos.size() - 1);
    }
    void add_tri(std::uint32_t a, std::uint32_t b, std::uint32_t c, const Attr& aa, const Attr& ab, const Attr& ac, std::uint32_t partIndex) {
        tris.push_back({a, b, c});
        attr.push_back({aa, ab, ac});
        part.push_back(partIndex);
    }
    Vec3 face_cross(std::size_t t) const { return cross(pos[tris[t][1]] - pos[tris[t][0]], pos[tris[t][2]] - pos[tris[t][0]]); }
};

// Cluster id of every point: points within `distance` of an earlier cluster's first point join it (spatial hash, processed in order, so
// the answer does not depend on anything but the input). `centers` (optional) gets the average of each cluster's points.
std::vector<std::uint32_t> cluster_points(const std::vector<Vec3>& points, float distance, std::vector<Vec3>* centers = nullptr);

// `welded` (optional) gets, for every vertex of `m`, the id of its welded vertex in the soup.
Soup to_soup(const ModelMesh& m, float tolerance = kWeldTolerance, std::vector<std::uint32_t>* welded = nullptr);

// The mesh with vertices that are bit-identical (position, normal, uv, colour) merged into one; triangles are untouched.
ModelMesh dedup_vertices(const ModelMesh& m);
// The mesh without the triangles that have a repeated index or no area (`triParts` follows).
ModelMesh drop_degenerate(const ModelMesh& m);

// Normals of every corner, 3 per triangle in order: angle-weighted average of the faces around the vertex that turn less than
// `creaseDeg` from this corner's face. 180 or more: every face around the vertex.
std::vector<Vec3> corner_normals(const Soup& s, float creaseDeg);

// The soup as a ModelMesh with normals from `corner_normals(creaseDeg)`; corners with the same position, normal and attributes are one
// vertex. `flat`: every triangle has its own face normal.
ModelMesh from_soup(const Soup& s, float creaseDeg, bool flat = false);
// The same with the corner normals given (3 per triangle).
ModelMesh from_soup_normals(const Soup& s, const std::vector<Vec3>& normals);

// Unique undirected edges of a soup and the triangle sides using each.
struct EdgeUse {
    std::uint32_t tri;
    std::uint8_t slot;  // the side from corner `slot` to corner `slot + 1`
    bool forward;       // the triangle walks it from the lower vertex id to the higher
};
struct Edges {
    struct Edge {
        std::uint32_t lo, hi, first, count;  // uses[first .. first + count)
    };
    std::vector<Edge> edges;
    std::vector<EdgeUse> uses;
    std::vector<std::uint32_t> triEdge;  // 3 per triangle: the edge index of side `slot`
    // True when the edge has exactly two uses that walk it in opposite directions (a regular manifold edge).
    bool regular(std::size_t e) const { return edges[e].count == 2 && uses[edges[e].first].forward != uses[edges[e].first + 1].forward; }
};
Edges build_edges(const Soup& s);

// Angle in degrees between two unit vectors.
float angle_deg(Vec3 a, Vec3 b);
Vec3 unit_or(Vec3 v, Vec3 fallback);

// The mesh moved by `f` (positions only), with normals recomputed to keep each smoothing group of the original: corners of one
// welded vertex that had the same normal share their new normal (angle-weighted average of their faces).
ModelMesh refresh_normals(const ModelMesh& moved, const ModelMesh& original);

}  // namespace fa::mm
