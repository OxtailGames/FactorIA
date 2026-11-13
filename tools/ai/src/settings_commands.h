// ai.settings.get and ai.settings.set (private; registered by register_ai_commands): read and write the AI settings of the open
// project and the user's own, with where each value comes from.
#pragma once

#include <functional>
#include <string>

#include "fa/ai/config.h"
#include "fa/core/command.h"

namespace fa::ai {

// `aiConfigPath` "" = default_config_path(env). Both commands read and write the files on the disk (ai.json, the project's
// .factoria/ai/settings.json). Trust: ai.settings.set never accepts a project's file, so setting a value never writes ai-trust.json
// (a file the user accepted waits again). Removing a value (null) from a file the user accepted keeps it accepted and updates its trust
// record to the smaller file; removing a value from a file that is not accepted leaves it waiting; a removal that empties the file
// deletes it and forgets its trust record (reset_project_setting). scope "user" is refused unless command_caller() is the user.
// `onUserConfigChanged` runs after a successful scope "user" set wrote ai.json, `onProjectConfigChanged` after a project one wrote (or
// removed) the project's file; both on the thread that runs the command (an AI or MCP thread in the editor), possibly from several
// threads at once: they must be thread-safe and quick. Empty = nothing to tell.
void register_settings_commands(CommandRegistry& registry, std::function<std::string()> projectDir,
                                std::string aiConfigPath, EnvLookup env, std::function<void()> onUserConfigChanged = {},
                                std::function<void()> onProjectConfigChanged = {});

}  // namespace fa::ai
