// Signed-distance modelling for model documents (docs/MODELING.md, "Organic shapes: sdf"): a field built from shapes (sphere, capsule, ellipsoid,
// rounded box, cylinder, cone, torus) combined with union, subtraction and intersection, each with a smoothness, and meshed into a closed
// triangle mesh. GPU-free and deterministic like the rest of the kernel (model_kernel.h): + - * / and sqrt on floats, fa::det trigonometry,
// integer hashing for the noise, one thread, containers walked in index order. The same field and parameters give the same bits everywhere.
//
// The field. d(p) < 0 inside, > 0 outside, 0 on the surface; for the plain shapes it is the distance to the surface (an ellipsoid and a
// non-uniformly scaled shape give a bound of it, which is all the meshing and the smooth blending need). A tree of nodes: a SHAPE is a leaf with
// a transform; a GROUP combines its children in order (the first child starts the shape, each next one is united with, subtracted from or
// intersected with what came before, with a blend distance), may mirror them across a plane, and is itself placed by a transform and
// combined into its parent. The smooth union is the quadratic `smin`; the smooth subtraction and intersection are its max twins.
//
// What meshing keeps. Every leaf has a `group` (the evaluator's (part, material) index) and an optional colour. At a point, the field also says
// which leaf OWNS it (the one that sets the value: the nearer for a union, the cutter on the walls of a subtraction; inside a blend the one with
// the larger share) and its colour (the colours of the blended shapes, mixed by the same shares). A triangle takes the group of the leaf that
// owns its centre and a vertex the colour at its position, so parts survive meshing and colours melt across a smooth blend.
#pragma once

#include <cstdint>
#include <optional>
#include <vector>

#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/model_kernel.h"

namespace fa {

enum class ModelSdfShape : std::uint8_t { Sphere, Capsule, Ellipsoid, Box, Cylinder, Cone, Torus };
enum class ModelSdfBlend : std::uint8_t { Union, Subtract, Intersect };

// The numbers of one shape, in its own space (centred on its origin, axis along Y, like the mesh primitives). Fields a shape does not use are ignored.
struct ModelSdfShapeParams {
    ModelSdfShape shape = ModelSdfShape::Sphere;
    float radius = 0.5f;      // Sphere, Capsule (the bottom ball), Cylinder, Cone (the base), Torus (of the ring)
    float radiusTop = -1;     // Capsule (the top ball) and Cone (the top circle); < 0: same as `radius` for a capsule, 0 for a cone
    float height = 1;         // Capsule: tip to tip; Cylinder, Cone
    float round = 0;          // Box, Cylinder: radius of the rounded edges
    float tube = 0.15f;       // Torus: radius of the tube
    Vec3 size{1, 1, 1};       // Box: full size; Ellipsoid: the three radii
};

// Where a point of the field "comes from".
struct ModelSdfSample {
    float d = 0;
    std::uint32_t group = 0;  // the owning leaf's group
    Vec4 color{1, 1, 1, 1};   // meaningful when ModelSdf::has_color()
};

class ModelSdf {
public:
    // Adds a shape / a group of already added nodes and returns its index. `local` is the node's transform relative to its parent (scale, rotation,
    // position as the tree writes them); `blend` and `smooth` (metres, 0 = a hard edge) say how it joins the nodes before it in its parent.
    int add_shape(const ModelSdfShapeParams& shape, const Mat4& local, ModelSdfBlend blend, float smooth, std::uint32_t group, std::optional<Vec4> color);
    // `mirror` -1 none, 0, 1, 2: the group's local space is folded across the plane x = 0 / y = 0 / z = 0, so what is on the positive side is repeated on the other.
    int add_group(const std::vector<int>& children, const Mat4& local, ModelSdfBlend blend, float smooth, int mirror);
    void set_root(int node) { root_ = node; }
    int root() const { return root_; }

    bool empty() const { return root_ < 0; }
    std::size_t leaf_count() const { return leaves_; }
    bool has_color() const { return hasColor_; }
    // True when the leaves do not all share one group (so owners matter).
    bool has_several_groups() const { return severalGroups_; }

    float distance(Vec3 p) const;
    ModelSdfSample sample(Vec3 p) const;
    // A box that contains the whole inside of the field (the surface is inside it); false when the field is empty (nothing is left).
    bool bounds(Vec3& bmin, Vec3& bmax) const;

private:
    struct Node {
        bool leaf = true;
        ModelSdfBlend blend = ModelSdfBlend::Union;
        float smooth = 0;
        float distScale = 1;      // the smallest |scale|: the node's distance is the local one times this
        float inv[12] = {};       // the 3x4 affine from the parent's space to this node's
        float fwd[12] = {};       // and back
        ModelSdfShapeParams shape;
        std::uint32_t group = 0;
        Vec4 color{1, 1, 1, 1};
        std::vector<int> children;
        int mirror = -1;
        float capsuleLen = 0;     // Capsule: distance between the ball centres, precomputed
    };
    std::vector<Node> nodes_;
    int root_ = -1;
    std::size_t leaves_ = 0;
    bool hasColor_ = false, severalGroups_ = false;
    bool haveGroup_ = false;
    std::uint32_t firstGroup_ = 0;

    int add_node(Node n, const Mat4& local);
    float eval_distance(const Node& n, Vec3 p) const;
    ModelSdfSample eval_sample(const Node& n, Vec3 p) const;
    bool node_bounds(const Node& n, Vec3& bmin, Vec3& bmax) const;
};

// ---- meshing ---------------------------------------------------------------------------------------------------------------

// The most grid points one meshing may sample, and the most (grid points x shapes) it may evaluate; a request above either is refused with the
// voxel size that would fit.
inline constexpr std::size_t kModelSdfMaxSamples = 12000000;
inline constexpr std::size_t kModelSdfMaxCost = 300000000;
// The most triangles meshing may make before decimation.
inline constexpr std::size_t kModelSdfMaxRawTriangles = 3000000;

struct ModelSdfMeshParams {
    float voxelSize = 0;        // > 0: the size of a sampling cell, metres. 0: `cells` decides.
    int cells = 96;             // cells along the longest side of the shape's bounding box (when voxelSize is 0)
    // Seeded noise added to the field (the surface moves by about amplitude * noise, along its normal): rock. amplitude 0 = none.
    float noiseAmplitude = 0;
    float noiseFrequency = 3;   // features per metre
    int noiseOctaves = 1;
    int noiseSeed = 0;
    // Decimation (model_decimate.h). targetTriangles 0 = no target. maxError < 0: when there is no target, a quarter of the voxel; with a target,
    // no limit. maxError 0 with no target: not decimated. Both: whichever is reached first.
    std::size_t targetTriangles = 0;
    float maxError = -1;
    bool uvs = true;            // a box projection in world units (1 uv per metre); false: all (0, 0)
};

struct ModelSdfMeshInfo {
    float voxelSize = 0;
    int gridX = 0, gridY = 0, gridZ = 0;   // sampled points
    std::size_t samples = 0;
    std::size_t rawTriangles = 0;          // before decimation
    std::size_t triangles = 0;             // the result
    float maxErrorUsed = 0;                // the decimation's error limit (0: none)
    bool touchedEdge = false;              // the shape reached the edge of the sampled box and was cut there (should not happen)
    Vec3 boundsMin{}, boundsMax{};         // the sampled box
};

// Samples the field on a grid, extracts the iso-surface 0 as a closed triangle mesh (marching tetrahedra on the Kuhn subdivision of the grid: every
// vertex on a cell edge, moved onto the exact zero of the field), decimates it, and fills normals (the gradient of the field), uvs and colours.
// The mesh has `triParts` set from the owning leaf's group. Empty mesh (not an error) when the field has no surface.
Result<ModelMesh> model_sdf_mesh(const ModelSdf& sdf, const ModelSdfMeshParams& params, ModelSdfMeshInfo* info = nullptr);

// The noise the meshing adds to the field, exposed so tests and tools evaluate the same function: seeded fractal value noise in about -1..1.
float model_sdf_noise(Vec3 p, float frequency, int octaves, int seed);

}  // namespace fa
