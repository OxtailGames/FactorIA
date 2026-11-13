// The project side of a model document's `texturing` section (docs/MODELING.md, "Texturing"): the layer pictures the bake writes next to the
// model, the layered image document (M52) they are composed in and that people and AIs paint on, and the material that makes the .glb (and
// its LODs) use the composed picture. The bake itself (maps, wear, decals, triplanar) is fa_scene's (fa/scene/model_texture.h).
#pragma once

#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/scene/model_doc.h"

namespace fa::model_texture_detail {

// The names of the layers the bake owns in the texture's image document. A layer with one of these names is rewritten on every bake;
// every other layer is the user's and is never touched.
inline constexpr const char* kLayerBase = "model: base";
inline constexpr const char* kLayerDecals = "model: decals";
inline constexpr const char* kLayerWear = "model: wear";
inline constexpr const char* kLayerOcclusion = "model: occlusion";
inline constexpr const char* kLayerUv = "model: uv";

// "assets/models/door.glb" -> "assets/models/door"
std::string output_stem(const std::string& output);
// The image document of the texture: texturing.document, else <stem>.texture.image.json.
std::string document_path(const ModelDoc& doc, const std::string& output);
// The picture files a bake of `doc` writes (the layers and the maps asked for), project-relative, in a fixed order; empty without `texturing`.
// They are the model's extras: made by the bake, removed with it. The image document and its PNG are not: they hold what people paint.
std::vector<std::string> layer_files(const ModelDoc& doc, const std::string& output);

struct TextureBake {
    std::string document;             // the image document, project-relative
    std::string png;                  // the picture it bakes to: what the .glb uses as base colour texture
    std::vector<std::string> files;   // the layer pictures written (project-relative)
    std::vector<std::string> inputs;  // project files read: material textures, decal images and the image document
    ModelTextureReport report;
    bool documentCreated = false;
    int size = 0;
    std::string layout;  // a fingerprint of the uv layout the layers were made for
    std::vector<std::string> warnings;
};

// Bakes the layers of `doc.texturing` over the evaluated `build`, writes them, creates or updates the image document and bakes it. Hold a
// ProjectRootGuard. `previousLayout` is the layout fingerprint the last bake recorded ("" if none). Throws CommandError (assets_detail::fail)
// for a project problem, like the other tools; returns an Error for a bake problem.
Result<TextureBake> bake_model_texture(const std::string& projectDir, const ModelDoc& doc, const ModelBuild& build,
                                       const std::string& output, const std::string& previousLayout);

// Makes the mesh use the composed picture: every submesh gets `png` as its base colour texture (the material colour becomes white: it is
// in the picture), and the vertex colours are dropped when the picture holds them (texturing.vertexColors "bake").
void apply_texture(MeshData& mesh, const ModelDoc& doc, const std::string& png);

Json report_json(const ModelTextureReport& report);

}  // namespace fa::model_texture_detail
