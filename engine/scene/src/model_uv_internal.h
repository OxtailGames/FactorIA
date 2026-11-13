// Private pieces of the UV maker (model_uv_*.cpp): the working state, the projections, the xatlas wrapper and the measuring. Not a public
// header: model_uv.h is the interface.
#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "fa/scene/model_uv.h"
#include "model_mesh_ops.h"

namespace fa::uv {

// The mesh being given uvs. Triangles are the source mesh's, in its order; every uv is per CORNER (3 per triangle) in METRES of surface
// (a chart is a rigid piece of the surface laid flat), scaled to texels only when charts are packed or tiled.
struct Work {
    const ModelMesh* mesh = nullptr;
    std::vector<std::uint32_t>
        welded;  // per source vertex: the id of its welded vertex (positions within 1e-5 are one point of the surface)
    std::vector<Vec3> wpos;           // per welded vertex: its position
    std::vector<std::uint32_t> part;  // per triangle: index into `names`
    std::vector<std::string> names;   // the distinct part names, in order of first use
    std::vector<Vec2> uv;             // 3 per triangle
    std::vector<std::int32_t> chart;  // per triangle: the chart it is in (-1 = none yet)
    std::int32_t chartCount = 0;

    std::size_t triangle_count() const { return mesh->triangle_count(); }
    std::uint32_t corner_vertex(std::size_t t, int k) const { return mesh->indices[t * 3 + std::size_t(k)]; }
    std::uint32_t corner_weld(std::size_t t, int k) const { return welded[corner_vertex(t, k)]; }
    Vec3 corner_pos(std::size_t t, int k) const { return wpos[corner_weld(t, k)]; }
    // The direction the surface faces at a triangle: the mean of its corner normals (so a smooth surface is read smoothly), else the face's.
    Vec3 facing(std::size_t t) const;
    float area(std::size_t t) const;
};

Work make_work(const ModelMesh& mesh, const std::vector<std::string>& partNames);

// Projections: each fills `uv` and `chart` for the triangles in `tris` (indices into the mesh) of one part. `axis` is 'x', 'y' or 'z'.
void project_box(Work& w, const std::vector<std::uint32_t>& tris);
void project_planar(Work& w, const std::vector<std::uint32_t>& tris, char axis);
void project_cylinder(Work& w, const std::vector<std::uint32_t>& tris, char axis);
void project_sphere(Work& w, const std::vector<std::uint32_t>& tris, char axis);

// What makes two corners one uv vertex: the welded point and a tag (the projection direction, or the uv itself).
struct CornerKey {
    std::uint64_t a = 0;
    std::uint32_t b = 0;
    bool operator<(const CornerKey& o) const { return a != o.a ? a < o.a : b < o.b; }
    bool operator==(const CornerKey& o) const { return a == o.a && b == o.b; }
};
// Groups `tris` into charts: two triangles are one chart when they share a corner with the same `keys` entry (3 per entry of `tris`).
// Gives each chart a new id in `w.chart`, in order of the first triangle.
void assign_charts(Work& w, const std::vector<std::uint32_t>& tris, const std::vector<CornerKey>& keys);
// The same on its own: the component of each of `triangles` triangles (ids in order of the first triangle), and how many there are.
std::vector<std::int32_t> components(const std::vector<CornerKey>& keys, std::size_t triangles, std::int32_t& count);

// xatlas: cuts the part's triangles into charts and flattens them. `seams` is "few", "balanced" or "many".
// `partTris[p]` are the triangles of part p to unwrap (empty: leave the part alone). Charts come out in metres, upright, one chart id each;
// triangles xatlas cannot place (no area) keep chart -2.
Result<bool> unwrap_parts(Work& w, const std::vector<std::vector<std::uint32_t>>& partTris, float texelsPerMeter,
                          const std::string& seams);

// Packing: one atlas for all the charts (`scales` is the texel density of each part, texels per metre, times `shrink`).
struct PackRequest {
    std::vector<float> texelsPerMeter;  // per part index
    int textureSize = 0;                // 0 = auto
    int padding = 2;
    bool rotate = true;
};
struct PackResult {
    int textureSize = 0;
    double shrink = 1;
    std::size_t charts = 0;
};
// Writes the final normalised uvs (0..1) into w.uv for every triangle that has a chart.
Result<PackResult> pack_atlas(Work& w, const PackRequest& request);

// Tile layout: uv = metres * density / textureSize, no packing.
void tile_uvs(Work& w, const std::vector<float>& texelsPerMeter, int textureSize);

// The mesh with `w.uv` as its uvs: corners that share a vertex, a welded point and a uv stay one vertex, the rest are split.
ModelMesh rebuild_mesh(const Work& w);

// The chart of every triangle by the given corner uvs (3 per triangle): triangles that share a welded point with the same uv are one chart.
std::vector<std::int32_t> charts_by_uv(const Work& w, const std::vector<Vec2>& uv, std::int32_t& count);

}  // namespace fa::uv
