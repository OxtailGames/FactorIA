// Cleaning an imported or generated mesh into something a game ships (`model.import_clean`, docs/MODELING.md, "Cleaning an imported mesh"):
// weld, throw away what floats, fix the winding, scale, put the origin where it belongs, optionally remesh a broken surface through a signed
// distance field, and bring the triangles to a platform's budget. Works on any MeshData (a glTF read by gltf_mesh.h, a mesh `assets.generate_model`
// made); the result is a MeshData again, with the materials and parts of the source, plus a report of everything that was done.
//
// Order of the steps: orient (up axis) -> weld -> drop degenerate and duplicate triangles -> drop floating pieces -> make the winding consistent ->
// scale -> origin -> remesh (optional) -> decimate. Deterministic: serial, + - * / and sqrt on floats, containers walked in index order, no clock.
// GPU-free, in fa_scene.
#pragma once

#include <cstddef>
#include <functional>
#include <optional>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/mesh_store.h"
#include "fa/scene/model_kernel.h"

namespace fa {

// Reads the colour of material `material` (the index of the material in the mesh's submeshes' first-use order, see ModelCleanOptions) at a uv: the
// base colour texture, as RGBA 0..1, or none when the material has no readable texture. Used by the remesh, which cannot keep uvs, to carry the
// texture over as vertex colours.
using ModelTextureSampler = std::function<std::optional<Vec4>(const std::string& materialName, Vec2 uv)>;

struct ModelCleanOptions {
    std::string upAxis =
        "y";  // "y" (glTF, the engine) or "z" (Blender and CAD exports): z is turned to y, the front to -z... (x, y, z) -> (x, z, -y)
    double weldDistance =
        0;  // metres; vertices closer than this (and with the same uv, colour and a similar normal) become one; 0 = a millionth of the model's diagonal
    bool removeFloating = true;  // drop separate pieces smaller than `minPieceSize`
    double minPieceSize =
        0.02;  // a piece whose bounding diagonal is under this fraction of the biggest piece's is "floating" and removed
    std::string origin = "bottom_center";  // keep, center, bottom, bottom_center (the ground centre)
    std::optional<double> height;          // scale so the model is this many metres tall (Y extent)
    std::optional<double> scale;           // scale by this factor (exclusive with height)
    std::size_t targetTriangles = 0;       // decimate to at most this many (0 = leave the count alone)
    bool remesh =
        false;  // rebuild the surface through a signed distance field (closed, manifold, no self-intersection), losing the uvs
    int remeshCells = 128;   // cells along the longest side of the model when remeshing (16..400)
    double remeshVoxel = 0;  // or the cell size in metres (0 = use remeshCells)
    ModelTextureSampler
        textureSampler;  // remesh: carries the base colour textures over as vertex colours (none: the textures are dropped, the factors kept)
};

struct ModelCleanPiece {
    std::size_t triangles = 0;
    double diagonal = 0;  // bounding box diagonal, metres, in the source's scale
    Vec3 center{};        // bounding box centre in the source's (oriented) space
};

struct ModelCleanReport {
    // the source
    std::size_t verticesBefore = 0, trianglesBefore = 0;
    ModelMeshStats statsBefore;  // welded surface checks of the source, as it came
    Vec3 sizeBefore{};
    // weld and clean
    std::size_t verticesWelded = 0;              // vertices merged into another
    std::size_t degenerateRemoved = 0;           // triangles with no area (or two corners welded together)
    std::size_t duplicatesRemoved = 0;           // triangles that repeat another
    std::size_t pieces = 0;                      // connected pieces the surface had
    std::vector<ModelCleanPiece> removedPieces;  // floating pieces dropped (at most 20 listed)
    std::size_t removedPieceCount = 0, removedPieceTriangles = 0;
    std::size_t trianglesReoriented = 0;  // triangles flipped to agree with their neighbours or to face outward
    // scale and origin
    double scaleFactor = 1;
    std::string scaleReason;  // "height 1.8 m", "factor 0.01", "none"
    Vec3 offset{};            // added to every position by the origin step (after scaling)
    // remesh
    bool remeshed = false;
    double remeshVoxel = 0;
    std::size_t remeshRawTriangles = 0;
    bool texturesDropped =
        false;  // the remesh cannot keep uvs: base colour textures were dropped (or carried as vertex colours)
    bool texturesToColors = false;
    // decimate
    bool decimated = false;
    std::size_t trianglesBeforeDecimate = 0;
    double decimateError = 0;  // metres, the largest deviation from the cleaned surface
    bool reachedTarget = true;
    // the result
    std::size_t verticesAfter = 0, trianglesAfter = 0;
    ModelMeshStats statsAfter;
    Vec3 sizeAfter{};
    bool hadUvs = false;  // the source had texture coordinates (and they were kept)
    std::vector<std::string> warnings;
};

struct ModelCleanResult {
    MeshData mesh;  // submeshes (material, part) of the source, those that still have triangles, in the source's order
    ModelCleanReport report;
};

// Cleans `source`. Fails (with the fix) for a mesh with no triangles, a bad option, or a remesh that would need more samples than allowed.
Result<ModelCleanResult> model_import_clean(const MeshData& source, const ModelCleanOptions& options);

// The remesh step on its own (model_import_remesh.cpp): rebuilds `mesh` as the closed surface of its thickened distance field. `triParts` of the
// result are the parts of the nearest source triangles; colours carry the source's vertex colours (and sampled textures when `sampler` is given
// with `groupMaterial` naming the material of each part index).
struct ModelRemeshInfo {
    double voxel = 0;
    std::size_t rawTriangles = 0, triangles = 0;
    std::size_t gx = 0, gy = 0, gz = 0;
    bool texturesToColors = false;
};
Result<ModelMesh> model_remesh_mesh(const ModelMesh& mesh, double voxel, int cells,
                                    const std::vector<std::string>& groupMaterial, const ModelTextureSampler& sampler,
                                    ModelRemeshInfo* info);

Json model_clean_report_json(const ModelCleanReport& report);

}  // namespace fa
