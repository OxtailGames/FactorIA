// ai.settings.get and ai.settings.set (private; registered by register_ai_commands): read and write the AI settings of the open
// project and the user's own, with where each value comes from.
#pragma once

#include <functional>
#include <string>

#include "fa/ai/config.h"
#include "fa/core/command.h"

namespace fa::ai {

// `aiConfigPath` "" = default_config_path(env). Both commands read and write the files on the disk (ai.json, the project's
// .factoria/ai/settings.json); neither can accept a project's file (ai-trust.json is never written by ai.settings.set).
void register_settings_commands(CommandRegistry& registry, std::function<std::string()> projectDir, std::string aiConfigPath,
                                EnvLookup env);

}  // namespace fa::ai
