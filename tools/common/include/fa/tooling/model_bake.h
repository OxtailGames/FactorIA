// Baking model documents (`*.model.json`, docs/MODELING.md): the .glb next to the document, its provenance and recipe in assets.json, and
// whether that file is current. The format and the evaluator are fa_scene's (fa/scene/model_doc.h); this is the project side, shared by the
// model.* commands, project.validate and `factoria export` (which bakes first, like image and audio documents).
#pragma once

#include <cstdint>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/scene/model_doc.h"

namespace fa {

// How a `text` node gets its glyph outlines: fa_render's outline_text (the engine's own fonts, or a project .ttf/.otf read through the VFS
// project root, so hold a ProjectRootGuard / set_project_root while evaluating), and the texel density of the project's style guide
// (assets.json style.texelsPerUnit) as the default of a document's `uv` section.
ModelEvalOptions model_project_eval_options(const std::string& projectDir);

// The project-relative .glb a document at `rel` bakes to: `output.path`, else `rel` with ".model.json" replaced by ".glb".
std::string model_document_output(const ModelDoc& doc, const std::string& rel);

enum class ModelBakeState {
    Fresh,       // the .glb exists and the recipe in assets.json matches the document and every file it read
    Missing,     // no .glb yet
    Stale,       // the document or a file it reads changed since the bake
    Unrecorded,  // the file exists but assets.json does not say it was baked from this document
    Broken       // the document does not load or evaluate
};
struct ModelBakeStatus {
    ModelBakeState state = ModelBakeState::Missing;
    std::string output;  // project-relative; "" when Broken
    std::string reason;  // one sentence for a person
    std::string hint;    // how to fix it, when Broken
};

ModelBakeStatus model_bake_status(const std::string& projectDir, const std::string& rel);
const char* model_bake_state_name(ModelBakeState state);

struct ModelBakeOptions {
    bool onlyIfNeeded = false;  // do nothing when the status is Fresh
    bool overwrite = false;     // replace a file at the output that this document did not make
};
struct ModelBakeResult {
    std::string document;  // project-relative
    std::string output;    // the .glb, project-relative
    bool written = false;  // false: it was Fresh and onlyIfNeeded was set
    std::size_t bytes = 0;
    ModelBuild build;      // what was evaluated (empty when not written)
    std::string sha256;    // of the file's bytes
    std::vector<std::string> inputs;
    Json provenance;       // the record written to assets.json
    std::vector<std::string> extras;  // the files the document's gameReady settings added (LOD .glbs, collider .glbs, the prefab), project-relative, in the order written
    Json texture;          // the texturing report (the image document, the picture the .glb uses, the layer pictures written, the measurements); null without a `texturing` section
    std::vector<std::string> warnings;  // problems the bake worked around (a texture whose uv layout changed under painted layers)
    Json gameReady;        // the game-ready report (model_game_ready.h: LODs and collider against the platform budgets); null when the document has no gameReady settings
};

// What the "gameReady" settings of a document turn into besides the .glb (docs/MODELING.md "Game-ready models"). Derived from the evaluated
// model every bake, so a change to the tree or to the settings changes them all.
struct ModelGameReadyFiles {
    MeshData mesh;                                              // what the main .glb holds: the model after origin and merge
    std::vector<std::pair<std::string, std::vector<std::uint8_t>>> glbs;  // LOD and collider hull .glbs: project path, bytes
    std::string prefabPath, prefabText;                         // "" when the settings have no LOD and no collider
    Json report;                                                // game_ready_report_json, null without settings
    std::vector<std::string> warnings;
};
Result<ModelGameReadyFiles> model_game_ready_files(const ModelDoc& doc, const ModelBuild& build, const std::string& output);
// The extra files the settings are sure to make (LODs, a single convex hull, the prefab); a decomposition's pieces are only known after a bake.
std::vector<std::string> model_expected_extras(const ModelDoc& doc, const std::string& output);
// Evaluates the document and writes the .glb through the mesh.save path (deterministic bytes), then records provenance + recipe {command
// "model.bake", args {path}, inputs: the document and every file it read} in assets.json. Keeps the license and author a person recorded.
Result<ModelBakeResult> bake_model_document(const std::string& projectDir, const std::string& rel, const ModelBakeOptions& options = {});

// Every *.model.json of the project (project-relative, sorted; hidden folders, node_modules and a top-level build/ skipped).
std::vector<std::string> list_model_documents(const std::string& projectDir);
// Bakes the documents whose .glb is missing or stale (what `factoria export` does first). A document that does not load is an error
// naming it. Returns the baked documents.
Result<std::vector<ModelBakeResult>> bake_model_documents_if_needed(const std::string& projectDir);

}  // namespace fa
