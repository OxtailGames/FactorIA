// project.validate: the layered image documents (*.image.json, docs/IMAGES.md) of the project.
#include "assets_internal.h"
#include "fa/tooling/image_doc.h"
#include "fa/tooling/validate.h"

namespace fa::assets_detail {

void check_image_documents(const std::string& projectDir, std::vector<ValidationIssue>& errors, std::vector<ValidationIssue>& warnings) {
    for (const std::string& rel : list_image_documents(projectDir)) {
        std::vector<ImageIssue> issues;
        auto doc = load_image_document(projectDir, rel, &issues);
        if (!doc.ok()) {
            if (issues.empty()) issues.push_back({"", doc.error().message, doc.error().hint});
            for (const ImageIssue& issue : issues)
                errors.push_back({rel, issue.pointer, issue.message,
                                  issue.hint.empty() ? "Fix the document (docs/IMAGES.md, schemas/image.schema.json)." : issue.hint});
            continue;
        }
        const ImageBakeStatus status = image_bake_status(projectDir, rel);
        const std::string bake = "factoria call image.bake '" + Json::object({{"path", rel}}).dump() + "'";
        switch (status.state) {
            case ImageBakeState::Missing:
                warnings.push_back({rel, "", "Not baked yet: " + status.reason,
                                    "Draw it into a PNG with: " + bake + " (factoria export does it too)."});
                break;
            case ImageBakeState::Unrecorded:
                warnings.push_back({rel, "", "The picture next to the document is not recorded as its bake: " + status.reason,
                                    "Bake it again with: " + bake + " to record the recipe (this replaces the PNG)."});
                break;
            case ImageBakeState::Stale:  // reported by check_recipes, with the regenerate command
            case ImageBakeState::Fresh:
            case ImageBakeState::Broken:
                break;
        }
    }
}

}  // namespace fa::assets_detail
