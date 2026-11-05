// assets.review: a one-shot vision review the AI that makes the art can call on its own pictures (docs/ASSETS.md, "Reviewing art").
#pragma once

#include <functional>

#include "fa/ai/commands.h"
#include "fa/ai/config.h"
#include "fa/core/command.h"

namespace fa::ai {

// Registers assets.review. It runs assets.check_art (from `registry`) on the same pictures first and hands the model the numbers,
// the style rules and the style reference images with the pictures. Uses the "fast" role's model (the orchestrator when fast is off).
void register_assets_review(CommandRegistry& registry, std::function<Result<AiConfig>()> load,
                            std::function<std::string()> projectDir, const AiCommandOptions& options);

}  // namespace fa::ai
