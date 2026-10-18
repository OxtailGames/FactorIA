// Private: convex cores, GJK / EPA and the triangle BVH behind the capsule, convex and mesh colliders of Physics3D.
//
// A shape is a CORE (a point, a segment, a box, a convex vertex cloud or a triangle) grown by a rounding radius: a sphere
// is a point + radius, a capsule a segment + radius. Two shapes touch when the distance between their cores is below the
// sum of the radii, so the common shallow contacts only need GJK distance; EPA runs only when the cores themselves
// overlap (deep penetration).
#pragma once

#include <cstdint>
#include <memory>
#include <vector>

#include "fa/core/math.h"
#include "fa/scene/mesh_geometry.h"

namespace fa::detail {

// Geometry shared by every collider that uses the same mesh: the (reduced) vertex cloud of the convex hull, and the
// triangles with their bounding-volume hierarchy. Vertices are in the model's own space (unscaled, unrotated).
struct ShapeData {
    std::shared_ptr<const MeshGeometry> geometry;
    std::vector<Vec3> hull;  // convex: vertices whose hull equals the mesh's (at most ~256 of them)
    struct Node {
        Vec3 lo, hi;
        int left = -1, right = -1;  // children; -1 = leaf
        int first = 0, count = 0;   // leaf: triangles order[first .. first + count)
    };
    std::vector<Node> nodes;           // nodes[0] = root (mesh only)
    std::vector<std::uint32_t> order;  // triangle indices (index of the first of its three entries / 3), BVH order

    Vec3 tri_vertex(std::uint32_t tri, int k) const { return geometry->positions[geometry->indices[tri * 3 + k]]; }
    // Calls fn(triangle) for every triangle whose bounds overlap [lo, hi] (model space), in a fixed order.
    template <class Fn>
    void query(Vec3 lo, Vec3 hi, Fn&& fn) const {
        if (nodes.empty()) return;
        int stack[64], top = 0;
        stack[top++] = 0;
        while (top > 0) {
            const Node& n = nodes[stack[--top]];
            if (n.lo.x > hi.x || n.hi.x < lo.x || n.lo.y > hi.y || n.hi.y < lo.y || n.lo.z > hi.z || n.hi.z < lo.z)
                continue;
            if (n.left < 0) {
                for (int i = 0; i < n.count; ++i) fn(order[n.first + i]);
            } else {
                stack[top++] = n.right;  // the left child is visited first
                stack[top++] = n.left;
            }
        }
    }
};

// Builds the hull cloud (convex) and/or the BVH (mesh) of a geometry.
std::shared_ptr<ShapeData> make_shape_data(std::shared_ptr<const MeshGeometry> geometry, bool hull, bool bvh);

// First hit of the ray origin + dir * t (t in [0, maxT], dir unit, in MODEL space) with the triangles. Returns false for
// a miss. `tri` is the hit triangle; the normal is the triangle's, facing the ray origin.
bool ray_triangles(const ShapeData& data, Vec3 origin, Vec3 dir, float maxT, float& t, std::uint32_t& tri, Vec3& normal);

// A convex core in world space.
struct Core {
    enum Kind { Point, Segment, Box, Hull, Triangle } kind = Point;
    Vec3 a, b, c;                    // Point: a. Segment: a-b. Triangle: a, b, c. Box/Hull: a = centre / model origin
    Vec3 half{};                     // Box: half extents along ax
    Vec3 ax[3] = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}};  // Box/Hull frame
    const Vec3* verts = nullptr;     // Hull: model-space vertices
    int count = 0;
    Vec3 scale{1, 1, 1};             // Hull: per-axis scale applied before the frame
    float radius = 0.0f;             // rounding radius (sphere, capsule)
};
Vec3 core_support(const Core& c, Vec3 dir);

struct GjkResult {
    bool overlap = false;  // the cores intersect (distance 0)
    float dist = 0.0f;     // between the cores
    Vec3 pa, pb;           // closest points on A and B (when !overlap)
    struct Vertex { Vec3 w, a, b; } v[4];
    int n = 0;             // simplex size (used by EPA when overlap)
};
GjkResult gjk(const Core& A, const Core& B);

struct EpaResult {
    bool ok = false;
    Vec3 normal;  // from A to B
    float depth = 0.0f;
    Vec3 pa, pb;
};
EpaResult epa(const Core& A, const Core& B, const GjkResult& g);

}  // namespace fa::detail
