// ai.review_feedback: the AI check of an entry's `share` text before it can leave the machine (docs/ENGINE_FEEDBACK.md).
#pragma once

#include <string>

#include "fa/ai/commands.h"
#include "fa/ai/config.h"
#include "fa/core/command.h"
#include "fa/core/json.h"

namespace fa::ai {

// Runs the review of entry `id` of the project's feedback file. Throws CommandError (not_found with did-you-mean, no_share,
// review_failed...). Never changes the sharing mode and never sends anything: it may rewrite `share` and set `reviewed`.
// `candidateShare` (an object): review that text instead of the saved `share` (the entry needs none), and write nothing: the
// answer carries `share` (the text to use) and `stored: false`.
Json review_feedback_entry(CommandRegistry& registry, const AiConfig& cfg, const AiCommandOptions& options,
                           const std::string& projectDir, const std::string& id, const Json& candidateShare = Json());

}  // namespace fa::ai
