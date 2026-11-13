// project.validate: the audio documents (*.audio.json, docs/SOUND.md "Audio documents") of the project.
#include "assets_internal.h"
#include "fa/tooling/audio_doc.h"
#include "fa/tooling/validate.h"

namespace fa::assets_detail {

void check_audio_documents(const std::string& projectDir, std::vector<ValidationIssue>& errors,
                           std::vector<ValidationIssue>& warnings) {
    for (const std::string& rel : list_audio_documents(projectDir)) {
        const AudioBakeStatus status = audio_bake_status(projectDir, rel);
        const std::string bake = "factoria call audio.bake '" + Json::object({{"path", rel}}).dump() + "'";
        switch (status.state) {
            case AudioBakeState::Broken: {
                // every issue of the document with its pointer, or the one reason (a source that would be overwritten)
                std::vector<AudioDocIssue> issues;
                {
                    ProjectRootGuard root(projectDir);
                    (void)load_audio_doc(rel, &issues);
                }
                if (issues.empty()) issues.push_back({"", status.reason, status.hint});
                for (const AudioDocIssue& issue : issues)
                    errors.push_back(
                        {rel, issue.pointer, issue.message,
                         issue.hint.empty()
                             ? "Fix the document (docs/SOUND.md \"Audio documents\", schemas/audio.schema.json)."
                             : issue.hint});
                break;
            }
            case AudioBakeState::Missing:
                warnings.push_back({rel, "", "Not baked yet: " + status.reason,
                                    "Render it into a sound with: " + bake + " (factoria export does it too)."});
                break;
            case AudioBakeState::Unrecorded:
                warnings.push_back({rel, "",
                                    "The sound next to the document is not recorded as its bake: " + status.reason,
                                    "Bake it again with: factoria call audio.bake '" +
                                        Json::object({{"path", rel}, {"overwrite", true}}).dump() +
                                        "' to record the recipe (this replaces the file)."});
                break;
            case AudioBakeState::Stale:  // reported by check_recipes, with the regenerate command
            case AudioBakeState::Fresh: break;
        }
    }
}

}  // namespace fa::assets_detail
