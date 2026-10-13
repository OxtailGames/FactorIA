#include "fa/tooling/tooling.h"

namespace fa {

void register_tooling_commands(CommandRegistry& registry, const std::string& projectDir) {
    register_feedback_commands(registry, projectDir);
    register_docs_commands(registry);
    register_api_export_commands(registry);
    register_fs_commands(registry, projectDir);
    register_validate_commands(registry, projectDir);
}

}  // namespace fa
