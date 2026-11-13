// Game-ready models (docs/MODELING.md, "Game-ready models"): what turns a mesh into something a game ships. The operations work on any
// MeshData (a model document's result, an organic `sdf` node's result, a mesh imported from a file), so they are plain functions; the settings
// live in the model document under "gameReady" and every bake derives the files from them again.
//
//   origin   where the model's local origin sits (keep, center, bottom, bottom_center): the model is moved, not its collider or LODs apart.
//   merge    submeshes with the same material become one (fewer draw calls), identical vertices are welded, triangles are ordered for the GPU cache.
//   lods     lower-detail copies of the mesh, made by meshoptimizer's simplifier (model_decimate.h: the one engine the SDF mesher uses too). Every
//            submesh is simplified on its own with its border locked, so the parts stay apart and no crack opens between them; normals, uvs and
//            colours weigh in the error, so seams and colour edges survive.
//   collider a box, sphere or capsule fitted to the mesh, its convex hull, or a convex decomposition (V-HACD, run on one thread) of a concave one.
//   budget   triangles and draw calls the model may cost on each platform, and a report of every LOD against them.
//
// Deterministic: serial, float arithmetic with + - * / sqrt, no clock; V-HACD runs synchronously. GPU-free, in fa_scene.
#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/mesh_store.h"
#include "fa/scene/model_doc.h"

namespace fa {

// ---- settings (the "gameReady" object of a model document) -------------------------------------------------------------------

inline constexpr std::size_t kGameReadyMaxLods = 4;    // LOD1..LOD4 besides the full mesh
inline constexpr int kGameReadyMaxHullVertices = 256;  // Collider3D's convex hull takes at most this many points

struct ModelLodSpec {
    double ratio = 0;           // keep this fraction of the full mesh's triangles (0 = not given)
    std::size_t triangles = 0;  // or at most this many (0 = not given); both given: the smaller
    double error =
        0;  // the most any collapse may move the surface, metres (0 = no limit); with no target it alone decides
    double distance =
        0;  // camera distance in metres from which the game draws this LOD (0 = automatic, see model_lod_distance)
};
struct ModelColliderSpec {
    std::string shape = "none";  // none, box, sphere, capsule, convex, decomposed
    int maxHulls = 8;            // decomposed: at most this many convex pieces
    int maxVertices = 32;        // convex, decomposed: at most this many points per hull (4..256)
    int resolution = 100000;     // decomposed: voxels V-HACD splits the volume into (more = finer pieces, slower)
    std::string part;   // fit to the submeshes of this part only (a pine's trunk, not its canopy); "" = the whole model
    double radius = 0;  // sphere, capsule: use this radius in metres instead of the fitted one (0 = fitted)
    double height = 0;  // capsule: use this total height in metres instead of the fitted one (0 = fitted)
};
struct ModelGameReady {
    std::string origin = "keep";  // keep, center, bottom, bottom_center
    bool merge = false;
    std::vector<ModelLodSpec> lods;
    ModelColliderSpec collider;
    std::vector<std::string> platforms = {"desktop", "mobile", "web"};  // the budgets the report checks
    bool is_default() const;                                            // nothing asked for: no files besides the .glb
};

// The settings of a document's `gameReady` object, every field checked (problems listed with their JSON pointer under `at`, e.g.
// "/gameReady", with the fix and "did you mean") and the defaults filled in. `issues` gets every problem; the first is also the error.
Result<ModelGameReady> parse_game_ready(const Json& json, const std::string& at,
                                        std::vector<ModelIssue>* issues = nullptr);
Json game_ready_to_json(const ModelGameReady& settings);  // the whole object, defaults included
// The JSON schema of the object (model_doc_schema() embeds it).
Json game_ready_schema();

// ---- budgets --------------------------------------------------------------------------------------------------------------

struct ModelPlatformBudget {
    std::string platform;       // desktop, mobile, web
    std::size_t triangles = 0;  // for one model on screen at its highest detail
    std::size_t submeshes = 0;  // draw calls of one model
    std::string doc;
};
const std::vector<ModelPlatformBudget>& model_platform_budgets();

// ---- the operations (any mesh) ---------------------------------------------------------------------------------------------

// The offset that puts the origin where `origin` says: "keep" none, "center" the middle of the bounding box at (0,0,0), "bottom" the lowest
// point at y = 0 (x and z kept), "bottom_center" both. Empty mesh: zero.
Vec3 model_origin_offset(const MeshData& mesh, const std::string& origin);
// A copy of the mesh moved by `offset` (bounds updated).
MeshData model_translated(const MeshData& mesh, Vec3 offset);

struct ModelMergeInfo {
    std::size_t submeshesBefore = 0, submeshesAfter = 0;
    std::size_t verticesBefore = 0, verticesAfter = 0;
};
// Submeshes with the same material become one (in order of first appearance; its part is the parts joined with "+"), identical vertices
// are welded and triangles are ordered for the vertex cache. The surface is not changed.
Result<MeshData> model_merge_by_material(const MeshData& mesh, ModelMergeInfo* info = nullptr);

struct ModelLodInfo {
    std::size_t triangles = 0, vertices = 0, submeshes = 0;
    double error = 0;     // metres: the largest deviation from the full mesh the simplifier measured (an upper bound)
    double distance = 0;  // metres from which the game draws it (0 for the full mesh)
    bool reachedTarget = true;
};
// A copy of `mesh` with fewer triangles per `spec`. Each submesh is simplified on its own and keeps its material and part; a submesh that
// would vanish entirely keeps a minimum. `info` (optional) gets the measurements.
Result<MeshData> model_make_lod(const MeshData& mesh, const ModelLodSpec& spec, ModelLodInfo* info = nullptr);
// The distance the game switches to LOD `index` (1-based) when the spec gives none: the model's largest dimension times 4, 8, 16, 32.
double model_lod_distance(const MeshData& mesh, std::size_t index, const ModelLodSpec& spec);

struct ModelHull {
    std::vector<Vec3> points;
    std::vector<std::uint32_t> indices;  // triangles over points, counter-clockwise seen from outside
    double volume = 0;
};
struct ModelCollider {
    std::string shape = "none";
    Vec3 center{};                 // box, sphere, capsule: the shape's centre in the mesh's space
    Vec3 size{};                   // box: full extents
    float radius = 0;              // sphere, capsule
    float height = 0;              // capsule: tip to tip along Y
    std::vector<ModelHull> hulls;  // convex: one; decomposed: the pieces
    double volume = 0;             // of the collider
    double meshVolume = 0;         // of the mesh (absolute value of its signed volume; 0 for an open surface)
    double volumeRatio =
        0;  // volume / meshVolume: 1 = a perfect fit, higher = the collider is looser than the mesh (0 when the mesh has no volume)
    std::vector<std::string> warnings;
};
// Fits the collider of `spec.shape` to the mesh. Never fails for a mesh with triangles (a failed decomposition falls back to the convex hull and
// says so in `warnings`).
Result<ModelCollider> model_fit_collider(const MeshData& mesh, const ModelColliderSpec& spec);
// A hull as a mesh (for baking it to a .glb): one submesh, flat normals.
MeshData model_hull_mesh(const ModelHull& hull);
// The convex hull of a point set, reduced to at most `maxVertices` points (4..256). Empty when the points are flat or fewer than four.
ModelHull model_convex_hull(const std::vector<Vec3>& points, int maxVertices);

// ---- the whole thing --------------------------------------------------------------------------------------------------------

struct ModelBudgetRow {
    std::string platform;
    std::size_t budgetTriangles = 0, budgetSubmeshes = 0;
    int firstFittingLod = -1;  // the lowest-numbered LOD within the triangle budget; -1 = none fits
    bool fullMeshFits = false;
    bool submeshesFit = false;
};
struct ModelGameReadyResult {
    MeshData mesh;  // the full mesh after origin and merge
    Vec3 offset{};  // what the origin setting added to every position
    ModelMergeInfo merge;
    std::vector<MeshData> lods;         // LOD1..; each with the origin applied
    std::vector<ModelLodInfo> lodInfo;  // index 0 = the full mesh, then one per entry of `lods`
    ModelCollider collider;             // shape "none" when not asked for
    std::vector<ModelBudgetRow> budget;
    std::vector<std::string> warnings;
};
// origin, merge, LODs, collider and the budget report for `mesh` per `settings`.
Result<ModelGameReadyResult> make_game_ready(const MeshData& mesh, const ModelGameReady& settings);
// The report as JSON (counts per LOD against each platform's budget, the collider, the warnings): what model.game_ready returns.
Json game_ready_report_json(const ModelGameReadyResult& result, const ModelGameReady& settings);

}  // namespace fa
