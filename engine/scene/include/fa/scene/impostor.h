// Impostors (M75-P1c, docs/BIG_WORLDS_LOD.md "Impostors"): the file `model.bake_impostor` writes (`<model>.impostor.json`), the layout of its atlas
// and the maths that picks and blends its frames. Pure and GPU-free: the bake (tools), the renderer and the tests all use these functions, and
// shaders/impostor.glsl is the GLSL twin of impostor_direction, impostor_basis and impostor_pick (a test compares the CPU side with the drawn
// pixels).
//
// The atlas is `views` x `views` frames. Frame (i, j) sits at column i, row j (row 0 at the top of the picture) and shows the model from the
// direction impostor_direction(mode, views, i, j) (a unit vector from the model towards the camera, in the model's space), orthographically,
// framed on the square of side 2 * radius around `center` (the sphere that holds the whole mesh, so every direction needs the same frame).
// The two modes map a direction to the atlas with an octahedral projection: `octahedral` covers the whole sphere, `hemiOctahedral` the
// upper hemisphere only (y >= 0: for what is seen from above, trees and rocks; twice the angular resolution for the same size).
#pragma once

#include <string>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"

namespace fa {

enum class ImpostorMode { Octahedral, HemiOctahedral };
const char* impostor_mode_name(ImpostorMode m);  // "octahedral" or "hemiOctahedral"
bool impostor_mode_from_name(const std::string& s, ImpostorMode& out);

inline constexpr int kImpostorMinViews = 2, kImpostorMaxViews = 32;
inline constexpr int kImpostorMinFrame = 8;     // pixels: a smaller frame has no picture worth drawing
inline constexpr int kImpostorMaxAtlas = 4096;  // pixels per side
inline constexpr const char* kImpostorFormat = "factoria.impostor/1";

// The contents of a `*.impostor.json`.
struct ImpostorAtlas {
    ImpostorMode mode = ImpostorMode::Octahedral;
    int views = 8;        // frames per side of the atlas
    int frameSize = 0;    // pixels of one frame's side
    std::string albedo;   // project-relative PNG: base colour (straight alpha: the silhouette)
    std::string normal;   // project-relative PNG: the model-space normal * 0.5 + 0.5
    Vec3 center{};        // the model-space point every frame looks at
    float radius = 1.0f;  // the frames show the square 2 * radius wide around `center`
    std::string source;   // the model the atlas was baked from (for people and tools; the renderer does not read it)
    int atlasSize() const { return views * frameSize; }
};

// Parses and checks `j` (the file `name`): every problem names the JSON pointer, what is wrong and how to fix it.
Result<ImpostorAtlas> impostor_from_json(const Json& j, const std::string& name);
Json impostor_to_json(const ImpostorAtlas& a);

// The direction frame (i, j) looks from (unit, model space). i, j in 0 .. views - 1.
Vec3 impostor_direction(ImpostorMode mode, int views, int i, int j);
// The octahedral coordinates of a unit direction, each in -1..1 (the inverse of impostor_direction before the grid). In hemiOctahedral mode a
// direction below the horizon counts as the one on the horizon under it.
void impostor_encode(ImpostorMode mode, Vec3 direction, float& u, float& v);
// The picture plane of a frame looking from `direction`: `right` and `up`, unit, perpendicular to it and to each other. up is world +y
// projected on the plane (-z within 8 degrees of the poles, where +y has no direction on the plane).
void impostor_basis(Vec3 direction, Vec3& right, Vec3& up);

// The three frames nearest to `direction` and how much each weighs (the weights add up to 1): the corners of the triangle of the grid
// that holds the direction. Indices are j * views + i.
struct ImpostorPick {
    int frame[3]{};
    float weight[3]{};
};
ImpostorPick impostor_pick(ImpostorMode mode, int views, Vec3 direction);

}  // namespace fa
