// project.validate: the rig documents (*.rig.json, docs/RIGGING.md) of the project.
#include "assets_internal.h"
#include "fa/tooling/rig_bake.h"
#include "fa/tooling/validate.h"

namespace fa::assets_detail {

void check_rig_documents(const std::string& projectDir, std::vector<ValidationIssue>& errors, std::vector<ValidationIssue>& warnings) {
    for (const std::string& rel : list_rig_documents(projectDir)) {
        const RigBakeStatus status = rig_bake_status(projectDir, rel);
        const std::string bake = "factoria call rig.bake '" + Json::object({{"path", rel}}).dump() + "'";
        switch (status.state) {
            case RigBakeState::Broken: {
                // every issue of the document with its pointer; a model that is missing or a fit that fails has none
                std::vector<RigIssue> issues;
                (void)load_rig_document(projectDir, rel, &issues);
                if (issues.empty()) issues.push_back({"", status.reason, status.hint});
                for (const RigIssue& issue : issues)
                    errors.push_back({rel, issue.pointer, issue.message, issue.hint.empty() ? "Fix the document (docs/RIGGING.md, schemas/rig.schema.json)." : issue.hint});
                break;
            }
            case RigBakeState::Missing:
                warnings.push_back({rel, "", "Not baked yet: " + status.reason, "Build the skinned model with: " + bake + " (factoria export does it too)."});
                break;
            case RigBakeState::Unrecorded:
                warnings.push_back({rel, "", "The .glb of the document is not recorded as its bake: " + status.reason,
                                    "Bake it again with: factoria call rig.bake '" + Json::object({{"path", rel}, {"overwrite", true}}).dump() + "' to record the recipe (this replaces the file)."});
                break;
            case RigBakeState::Stale:  // reported by check_recipes, with the regenerate command
            case RigBakeState::Fresh:
                break;
        }
    }
}

}  // namespace fa::assets_detail
