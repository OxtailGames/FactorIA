// project.validate: the model documents (*.model.json, docs/MODELING.md) of the project.
#include "assets_internal.h"
#include "fa/tooling/model_bake.h"
#include "fa/tooling/validate.h"

namespace fa::assets_detail {

void check_model_documents(const std::string& projectDir, std::vector<ValidationIssue>& errors, std::vector<ValidationIssue>& warnings) {
    for (const std::string& rel : list_model_documents(projectDir)) {
        const ModelBakeStatus status = model_bake_status(projectDir, rel);
        const std::string bake = "factoria call model.bake '" + Json::object({{"path", rel}}).dump() + "'";
        // a uv section that cannot make good uvs: what the build measured, as warnings (the same words as `model.uv`)
        if (status.state != ModelBakeState::Broken) {
            ProjectRootGuard root(projectDir);
            if (auto doc = load_model_doc(rel); doc.ok() && doc->uv) {
                if (auto build = evaluate_model(*doc, model_project_eval_options(projectDir)); build.ok() && build->uv)
                    for (const std::string& w : build->uv->warnings)
                        warnings.push_back({rel, "/uv", w, "factoria call model.uv '" + Json::object({{"path", rel}}).dump() + "' measures it and draws the layout."});
            }
        }
        switch (status.state) {
            case ModelBakeState::Broken: {
                // every issue of the document with its pointer
                std::vector<ModelIssue> issues;
                {
                    ProjectRootGuard root(projectDir);
                    (void)load_model_doc(rel, &issues);
                }
                if (issues.empty()) issues.push_back({"", status.reason, status.hint});
                for (const ModelIssue& issue : issues)
                    errors.push_back({rel, issue.pointer, issue.message, issue.hint.empty() ? "Fix the document (docs/MODELING.md, schemas/model.schema.json)." : issue.hint});
                break;
            }
            case ModelBakeState::Missing:
                warnings.push_back({rel, "", "Not baked yet: " + status.reason, "Build it into a .glb with: " + bake + " (factoria export does it too)."});
                break;
            case ModelBakeState::Unrecorded:
                warnings.push_back({rel, "", "The .glb next to the document is not recorded as its bake: " + status.reason,
                                    "Bake it again with: factoria call model.bake '" + Json::object({{"path", rel}, {"overwrite", true}}).dump() + "' to record the recipe (this replaces the file)."});
                break;
            case ModelBakeState::Stale:  // reported by check_recipes, with the regenerate command
            case ModelBakeState::Fresh:
                break;
        }
    }
}

}  // namespace fa::assets_detail
