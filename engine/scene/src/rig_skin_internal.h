// Shared by the pieces of the skin weights (rig_skin.cpp, rig_skin_heat.cpp, rig_skin_voxel.cpp, rig_skin_edit.cpp): sparse weights of a vertex, the
// welded mesh, and the two solvers. Private to fa_scene. Deterministic: ordered iteration, no threads, only + - * / and sqrt on floats.
#pragma once

#include <array>
#include <cstdint>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/mesh_store.h"
#include "fa/scene/rig_fit.h"
#include "fa/scene/rig_skin.h"

namespace fa::rig_skin_detail {

// The weights of one vertex: (bone, weight) with weight > 0, sorted by bone.
using Infl = std::vector<std::pair<std::uint16_t, float>>;
constexpr std::uint32_t kNone = 0xFFFFFFFFu;

struct Seg {
    Vec3 a, b;
};
float seg_dist2(Vec3 p, const Seg& s);

// The triangles of a mesh with coincident vertices welded (UV seams, hard edges, the poles of a sphere): the weights are solved on the nodes and every
// vertex reads its node's. `cot` is the cotangent weight of each edge (already summed over its two triangles), `mass` the lumped area of each node.
struct Weld {
    std::vector<std::uint32_t> nodeOf;               // per mesh vertex; kNone when no included triangle uses it
    std::vector<Vec3> pos;                           // per node
    std::vector<std::array<std::uint32_t, 3>> tris;  // triangles of nodes; the ones with no area are left out
    std::vector<std::uint32_t> rowStart;             // CSR of the node graph, neighbours sorted
    std::vector<std::uint32_t> col;
    std::vector<float> cot;
    std::vector<double> mass;
    std::vector<std::uint32_t> component;  // per node: the connected piece it is in, numbered by its lowest node
    std::uint32_t components = 0;
    std::size_t nodes() const { return pos.size(); }
};
// `triOn` (one flag per triangle of the mesh) says which triangles take part. `eps` is the welding distance.
Weld build_weld(const MeshData& mesh, const std::vector<char>& triOn, float eps);

struct HeatStats {
    std::uint32_t componentsSolved = 0;
    std::uint32_t componentsFailed = 0;  // the solver did not converge: those nodes are left unsolved for the caller to bind another way
    std::uint32_t maxIterations = 0;
    double worstResidual = 0;
};
// Bone heat on the welded mesh. `mask[node]` is the bones the node may follow (bit i = bone i, at most 64 bones). `out` gets the weights (normalised) of
// each node; a node of a component that failed is left empty. `locality` scales the heat: higher = weights hug their bone.
void solve_heat(const Weld& weld, const std::vector<std::uint64_t>& mask, const std::vector<Seg>& bones, double locality, std::vector<Infl>& out,
                HeatStats& stats);

struct VoxelStats {
    std::uint32_t voxels = 0;
    int resolution = 0;
};
// Voxel (geodesic) binding of the nodes: the surface is rasterised into a grid, the distance along it from each bone is measured, and a node follows
// the bones that are about as close as the closest. A node that no bone reaches is left empty.
void solve_voxel(const Weld& weld, const std::vector<std::uint64_t>& mask, const std::vector<Seg>& bones, double locality, std::vector<Infl>& out,
                 VoxelStats& stats);

// ---- helpers on sparse weights ------------------------------------------------------------------------------------------------

float weight_of(const Infl& w, std::uint16_t bone);
float total_of(const Infl& w);
// Drops weights under `cut` and renormalises to a sum of 1; a list whose weights are all under `cut` keeps its strongest one; an empty one stays empty.
void normalize_infl(Infl& w, float cut = 1e-5f);
// Keeps the `k` strongest (ties: the lower bone), then renormalises.
void limit_infl(Infl& w, int k);
// Adds `scale * w` into the dense per-bone vector `acc`.
void accumulate(const Infl& w, float scale, std::vector<float>& acc);
Infl from_dense(const std::vector<float>& acc, float cut = 1e-6f);

}  // namespace fa::rig_skin_detail

namespace fa::rig_skin_detail {

// What the pipeline knows about the model: its triangles by part.
struct SkinModel {
    std::vector<std::string> partNames;       // per submesh
    std::vector<std::uint32_t> triSub;        // per triangle: the submesh it is in, kNone when no submesh draws it
    std::vector<std::uint32_t> vertSub;       // per vertex: the submesh of the first triangle that uses it, kNone when none
};
SkinModel make_skin_model(const MeshData& mesh);

// The bones' hop distances: hops[a * n + b].
std::vector<std::uint8_t> bone_hops(const RigFit& fit);

// Applies the document's edits, in order, to the per-vertex weights. Fails with a teaching error when a bone or a part is unknown.
Result<void> apply_skin_edits(const RigSkinSettings& settings, const RigFit& fit, const MeshData& mesh, const SkinModel& model, std::vector<Infl>& weights,
                              RigSkinReport& report);

}  // namespace fa::rig_skin_detail
