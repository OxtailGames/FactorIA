// The assets.* commands that generate assets and keep their provenance (private; registered by register_ai_commands).
#pragma once

#include <functional>

#include "fa/ai/config.h"
#include "fa/ai/provider.h"
#include "fa/core/command.h"

namespace fa::ai {

// assets.generate_image, assets.generate_sprite_sheet, assets.generate_sound, assets.generate_music,
// assets.generate_voice, assets.generate_model, assets.provenance, assets.set_provenance, assets.disclosure.
void register_asset_commands(CommandRegistry& registry, std::function<Result<AiConfig>()> load,
                             std::function<std::string()> projectDir, ProviderRuntime runtime, const CancelFlag* cancel);

}  // namespace fa::ai
