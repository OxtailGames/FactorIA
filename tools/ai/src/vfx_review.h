// vfx.review: a one-shot vision review of an effect document (*.vfx.json) the AI that makes the effect can call on its own work
// (docs/PARTICLES.md, "Reviewing an effect").
#pragma once

#include <functional>

#include "fa/ai/commands.h"
#include "fa/ai/config.h"
#include "fa/core/command.h"

namespace fa::ai {

// Registers vfx.review. It calls vfx.budget and vfx.filmstrip (from `registry`, so the engine's commands must be in it) on the effect,
// then hands a vision model the filmstrip, the budget numbers and the document with a checklist (readability, timing, palette, overdraw)
// and asks for a verdict and fixes that are vfx.edit calls. Uses the "fast" role's model (the orchestrator when fast is off).
void register_vfx_review(CommandRegistry& registry, std::function<Result<AiConfig>()> load,
                         std::function<std::string()> projectDir, const AiCommandOptions& options);

}  // namespace fa::ai
