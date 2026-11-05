// Private to the texturing code (model_texture_maps.cpp, model_texture_paint.cpp): the mesh as flat triangles, the rasterisation of the uv atlas,
// a BVH for ray queries and the edge table that curvature is measured from. Everything is deterministic: integer hashes, + - * / sqrt and
// fa::det trigonometry only, loops in index order.
#pragma once

#include <array>
#include <cstdint>
#include <vector>

#include "fa/core/det_math.h"
#include "fa/core/math.h"
#include "fa/scene/model_texture.h"

namespace fa::mt {

inline std::uint32_t mix32(std::uint64_t x) {
    x += 0x9e3779b97f4a7c15ull;
    x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9ull;
    x = (x ^ (x >> 27)) * 0x94d049bb133111ebull;
    x ^= x >> 31;
    return std::uint32_t(x >> 32);
}
inline float hash01(std::uint64_t x) { return float(mix32(x) >> 8) / 16777216.0f; }
inline float smooth(float x) { return x * x * (3 - 2 * x); }

// The triangles that are drawn (inside a submesh), with what the passes need about each.
struct Geo {
    std::vector<Vec3> pos, nrm;
    std::vector<Vec2> uv;
    std::vector<Vec4> col;                       // empty when the mesh has no colours
    std::vector<std::array<std::uint32_t, 3>> tri;
    std::vector<std::uint32_t> sub;              // submesh of each triangle
    std::vector<Vec3> faceN;                     // unit; zero for a triangle with no area
    std::vector<float> area;
    Vec3 bmin{}, bmax{};
    float diag = 1;
    Vec3 corner(std::size_t t, int k) const { return pos[tri[t][std::size_t(k)]]; }
};
Geo make_geo(const MeshData& mesh);

// The atlas: for every texel the triangle that covers it and the barycentric weights (of corners 1 and 2) of its centre. Texels around the
// pieces are filled by `bleed` rounds of copying the data of a covered neighbour (so the colour computed from it continues past the border).
struct Texels {
    int size = 0;
    std::vector<std::int32_t> tri;               // -1: no triangle
    std::vector<float> b1, b2;
    std::vector<std::uint8_t> bled;              // 1: filled by the bleed
    std::size_t covered = 0;                     // texels inside a triangle (bleed not counted)
    std::size_t overlapped = 0;                  // of those, claimed by two or more triangles
    bool has(std::size_t i) const { return tri[i] >= 0; }
};
Texels rasterize(const Geo& g, int size, int bleed);
Vec3 texel_point(const Geo& g, const Texels& t, std::size_t i);
Vec3 texel_normal(const Geo& g, const Texels& t, std::size_t i);   // interpolated vertex normal, unit

// Nearest hit of a ray with the triangles, both faces.
class Bvh {
public:
    void build(const Geo& g);
    // Distance along `dir` (unit) to the nearest triangle closer than `tmax`, or a negative number for none. `skip` is a triangle to ignore.
    float nearest(Vec3 origin, Vec3 dir, float tmax, std::int32_t skip) const;

private:
    struct Node {
        Vec3 lo, hi;
        std::uint32_t a = 0, b = 0;  // inner: children; leaf: first (in order_) and count
        bool leaf = false;
    };
    std::uint32_t build_range(std::uint32_t first, std::uint32_t count);
    const Geo* g_ = nullptr;
    std::vector<Node> nodes_;
    std::vector<std::uint32_t> order_;
    std::vector<Vec3> centroid_;
};

// Ambient occlusion (1 = open, lower = occluded) and thickness (0..1 of `maxDist`, 1 = thick or open) per texel; NaN where no texel is covered.
std::vector<float> compute_ao(const Geo& g, const Bvh& bvh, const Texels& t, int samples, float distance);
std::vector<float> compute_thickness(const Geo& g, const Bvh& bvh, const Texels& t, int samples, float distance);

// Edges of the mesh welded by position: sharp edges (the surface turns at least `edgeAngle`) as segments with a sign, and the smooth
// curvature of the vertices between them.
class EdgeIndex {
public:
    void build(const Geo& g, float edgeAngleDeg, float maxWidth);
    // The strength 0..1 of the nearest convex and concave sharp edge within `width` of `p` (smooth falloff), then the smooth curvature
    // contribution at a texel: positive convex, negative concave, 0..1 for a surface turning one radian over `width`/2... see soft().
    void bands(Vec3 p, float width, float& convex, float& concave) const;
    // Mean curvature estimate (1/m) at the texel, from the smooth edges around the corners of its triangle.
    float curvature(const Geo& g, const Texels& t, std::size_t i) const;
    std::size_t sharp_edges() const { return segs_.size(); }

private:
    struct Seg {
        Vec3 a, b;
        float strength;
        bool convex;
    };
    std::vector<Seg> segs_;
    std::vector<float> vertexH_;                 // per Geo vertex
    Vec3 lo_{}, hi_{};
    float cell_ = 1;
    int nx_ = 1, ny_ = 1, nz_ = 1;
    std::vector<std::vector<std::uint32_t>> cells_;
    int cell_index(Vec3 p) const;
};

// 3D value noise in 0..1 at `p` (lattice points hashed from the seed).
float value_noise(Vec3 p, int seed);

// Helpers shared by the passes
bool needs(const std::vector<std::string>& list, const std::string& name);  // list empty = everything

}  // namespace fa::mt
