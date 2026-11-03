// Rig documents in a project (`*.rig.json`, docs/RIGGING.md): evaluating the model one fits, baking the skinned .glb next to the document, its
// provenance and recipe in assets.json, and whether that file is current. The format, the templates and the fit are fa_scene's
// (fa/scene/rig_doc.h, rig_fit.h, rig_glb.h); this is the project side, shared by the rig.* commands, project.validate and `factoria export`.
#pragma once

#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/scene/model_doc.h"
#include "fa/scene/rig_doc.h"
#include "fa/scene/rig_fit.h"

namespace fa {

// The project-relative .glb a document at `rel` bakes to: `output.path`, else `rel` with ".rig.json" replaced by ".rig.glb".
std::string rig_document_output(const RigDoc& doc, const std::string& rel);

// Reads the document at `rel`; every problem of the file is in `issues` (JSON pointers), also the ones that need the template (names in
// `parts` and `landmarks`, a generic rig's bones).
Result<RigDoc> load_rig_document(const std::string& projectDir, const std::string& rel, std::vector<RigIssue>* issues = nullptr);

// What a rig is fitted to: the document's model evaluated, moved the way the model's `gameReady.origin` moves its .glb (but never merged, so the
// parts stay apart), and textured with the picture the model's own bake made when it has a `texturing` section and was baked.
struct RigEvaluation {
    std::string modelPath;
    ModelDoc model;
    ModelBuild build;
    Vec3 originOffset{};
    MeshData mesh;          // what the .glb holds: the model after the origin offset (and the texture, when there is one)
    RigFit fit;
    std::vector<std::string> inputs;    // project files the result depends on: the model document, what it reads, the picture
    std::vector<std::string> warnings;  // from the fit and from the evaluation
};
Result<RigEvaluation> rig_evaluate(const std::string& projectDir, const RigDoc& doc);

enum class RigBakeState {
    Fresh,       // the .glb exists and the recipe in assets.json matches the rig document, the model document and every file they read
    Missing,     // no .glb yet
    Stale,       // the rig document, the model or a file they read changed since the bake
    Unrecorded,  // the file exists but assets.json does not say it was baked from this document
    Broken       // the document does not load, or its model does not fit
};
struct RigBakeStatus {
    RigBakeState state = RigBakeState::Missing;
    std::string output;  // project-relative; "" when Broken
    std::string reason;  // one sentence for a person
    std::string hint;    // how to fix it, when Broken
};
RigBakeStatus rig_bake_status(const std::string& projectDir, const std::string& rel);
const char* rig_bake_state_name(RigBakeState state);

struct RigBakeOptions {
    bool onlyIfNeeded = false;  // do nothing when the status is Fresh
    bool overwrite = false;     // replace a file at the output that this document did not make
};
struct RigBakeResult {
    std::string document;  // project-relative
    std::string output;    // the .glb, project-relative
    bool written = false;  // false: it was Fresh and onlyIfNeeded was set
    std::size_t bytes = 0;
    std::string sha256;
    std::vector<std::string> inputs;
    Json provenance;       // the record written to assets.json
    RigFit fit;            // the skeleton that was baked (empty when not written)
    std::vector<std::string> warnings;
};
// Fits the rig, writes the skinned .glb (deterministic bytes), then records provenance + recipe {command "rig.bake", args {path}, inputs: the
// rig document, the model document and every file they read} in assets.json.
Result<RigBakeResult> bake_rig_document(const std::string& projectDir, const std::string& rel, const RigBakeOptions& options = {});

// Every *.rig.json of the project (project-relative, sorted; hidden folders, node_modules and a top-level build/ skipped).
std::vector<std::string> list_rig_documents(const std::string& projectDir);
// Bakes the documents whose .glb is missing or stale (what `factoria export` does after the models). A document that does not load is an error
// naming it. Returns the baked documents.
Result<std::vector<RigBakeResult>> bake_rig_documents_if_needed(const std::string& projectDir);

}  // namespace fa
