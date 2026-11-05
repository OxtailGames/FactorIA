// UV coordinates for the 3D models the engine makes (model documents' `uv` section, docs/MODELING.md "UVs"): automatic unwrapping (xatlas),
// box, cylinder, sphere and planar projections chosen per PART, packing of the pieces into one square texture at the style's texel
// density, and the measurements that say whether the result is good (stretch, seams, density, overlap, how full the texture is).
//
// It works on any ModelMesh (a model document's merged mesh, an sdf, an imported mesh M58.4 cleans), not only on documents: `model_uv_apply`
// takes a mesh and the part of each triangle and returns the same triangles with new UVs (vertices are split along the seams; triangle
// order, parts, positions, normals and colours are unchanged). GPU-free, single-threaded and deterministic: the same mesh and settings
// give the same UVs on every platform (xatlas runs with fa::det trigonometry, see external/xatlas/xatlas_fa.cpp).
//
// Conventions are the kernel's and glTF's: uv (0, 0) is the top-left of the image, v grows downwards, and a projection shows the
// texture upright and not mirrored when the surface is seen from outside. "Texel density" is texels per metre.
#pragma once

#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/scene/model_kernel.h"

namespace fa {

inline constexpr float kModelUvDefaultTexelsPerMeter = 128;  // when neither the document nor the project's style guide says
inline constexpr int kModelUvMinTextureSize = 16;
inline constexpr int kModelUvMaxTextureSize = 4096;
inline constexpr int kModelUvMaxPadding = 32;

enum class ModelUvMethod {
    Unwrap,    // xatlas: cuts the surface into charts, flattens each with little stretch
    Box,       // each face projected on the axis plane its normal is closest to; one chart per connected run of faces
    Cylinder,  // around an axis, seam on the -e1 side; faces that look along the axis (caps) are projected flat
    Sphere,    // longitude / latitude around an axis
    Planar,    // everything projected along one axis
};
const char* model_uv_method_name(ModelUvMethod method);
const std::vector<std::string>& model_uv_method_names();

// What one part overrides; an unset field inherits the document's.
struct ModelUvPartSettings {
    std::optional<ModelUvMethod> method;
    std::optional<char> axis;                  // 'x', 'y' or 'z'
    std::optional<float> texelsPerUnit;        // texels per metre for this part
};

struct ModelUvSettings {
    // "atlas": every chart packed into [0, 1]^2 (a texture painted for this model). "tile": world-scale uvs that continue across the
    // whole model and repeat (a seamless texture); needs a projection, nothing is cut or packed.
    std::string layout = "atlas";
    std::optional<ModelUvMethod> method;       // default: unwrap for an atlas, box for tile
    char axis = 'y';                           // cylinder, sphere: the axis of the shape; planar: the direction looked along
    std::optional<float> texelsPerUnit;        // texels per metre; default the project's style guide, else kModelUvDefaultTexelsPerMeter
    int textureSize = 0;                       // side of the square texture; 0 = the smallest power of two the charts fit in (at most 4096)
    int padding = 2;                           // empty texels around each chart (atlas)
    std::string seams = "balanced";            // unwrap: "few", "balanced" or "many" charts
    std::optional<bool> rotate;                // atlas: let the packer turn charts; default off when a part is projected (so the texture stays upright)
    std::vector<std::pair<std::string, ModelUvPartSettings>> parts;  // by part name ("" is the nodes that name no part)

    ModelUvMethod method_of(const std::string& part) const;
    char axis_of(const std::string& part) const;
    const ModelUvPartSettings* part_settings(const std::string& part) const;
};

// The settings with every default filled in (the document may leave them out).
Json model_uv_settings_json(const ModelUvSettings& settings);

// ---- measuring ---------------------------------------------------------------------------------------------------------------

struct ModelUvPartReport {
    std::string part;
    std::string method;           // "unwrap", "box", ..., or "none" when the measured mesh was not made here
    std::size_t triangles = 0;
    std::size_t charts = 0;
    double texelsPerMeter = 0;    // area-weighted mean over the part's triangles
    double stretchMean = 0;       // area-weighted mean of the anisotropy (1 = no stretch), see ModelUvReport::stretchMax
    double stretchMax = 0;
};

struct ModelUvReport {
    std::string layout;           // "atlas" or "tile"
    int textureSize = 0;          // the square texture the uvs were made for (0 when measured without one)
    double texelsPerUnit = 0;     // asked for (atlas, tile)
    double texelsPerUnitUsed = 0; // reached: lower than asked when the charts did not fit in `textureSize`
    std::size_t triangles = 0, charts = 0;
    std::size_t seamEdges = 0;    // inner edges whose two triangles do not share their uvs (the surface is cut there)
    double seamLength = 0;        // metres
    double surfaceArea = 0;       // m^2
    double texelsPerMeter = 0;    // area-weighted mean; minimum and maximum over the triangles
    double texelsPerMeterMin = 0, texelsPerMeterMax = 0;
    // Anisotropy of the map from the surface to the texture: the ratio of its largest to its smallest scale, 1 = a perfect
    // (conformal) map, 2 = a texture is drawn twice as long one way as the other. Mean weighted by area, and the worst triangle.
    double stretchMean = 0, stretchMax = 0;
    std::size_t flippedTriangles = 0;  // triangles drawn mirrored against the rest of their chart's side (a texture reads backwards there)
    double utilization = 0;       // atlas: share of the texture the triangles cover
    double overlap = 0;           // atlas: share of the covered texels that two or more triangles share
    std::size_t outsideTriangles = 0;  // atlas: triangles with a uv outside [0, 1]
    std::vector<ModelUvPartReport> parts;
    std::vector<std::string> warnings;
};

// Measures the uvs a mesh has. `partNames[mesh.triParts[t]]` is the part of triangle t (empty list: one unnamed part). `layout` is "atlas"
// (overlap, utilization and range are measured at `textureSize`, 0 = 1024) or "tile". Needs one uv per vertex; a mesh without uvs gets an
// empty report with a warning.
ModelUvReport model_uv_measure(const ModelMesh& mesh, const std::vector<std::string>& partNames, const std::string& layout = "atlas", int textureSize = 0);

// ---- making ------------------------------------------------------------------------------------------------------------------

struct ModelUvOptions {
    // The texel density when the settings give none (the project's style guide). 0: kModelUvDefaultTexelsPerMeter.
    float defaultTexelsPerMeter = 0;
};

struct ModelUvResult {
    ModelMesh mesh;  // same triangles in the same order, new uvs
    ModelUvReport report;
};

// Gives `mesh` new uvs by `settings`. `partNames[mesh.triParts[t]]` names the part of each triangle (the evaluator's groups; empty: one
// unnamed part). Fails with a message that says what to change when a part cannot be unwrapped or the charts cannot fit the texture.
Result<ModelUvResult> model_uv_apply(const ModelMesh& mesh, const std::vector<std::string>& partNames, const ModelUvSettings& settings, const ModelUvOptions& options = {});

}  // namespace fa
