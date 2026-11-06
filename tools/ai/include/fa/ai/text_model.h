// One question to a model and its answer as text: no tools, no conversation. For small jobs that the engine does for a person
// and that must not touch the project (ai.review_feedback; the developer's `feedback pull` classification could use it too).
#pragma once

#include <functional>
#include <string>
#include <vector>

#include "fa/ai/config.h"
#include "fa/ai/session.h"
#include "fa/core/types.h"

namespace fa::ai {

// The system text is the instructions, the user text the data. The answer is the model's text.
using TextModel = std::function<Result<std::string>(const std::string& system, const std::string& user)>;

// The same question with pictures: the PNG/JPEG/WebP/GIF files (load_image_data, fa/ai/types.h) are attached to the user text.
// API providers send them as image blocks of the user message (Anthropic `image` blocks, OpenAI-compatible `image_url` data
// URLs, which also serve Gemini, Ollama and the other compatible endpoints). A CLI agent gets them inline when it reads
// stream-json, else as files in its folder named in the prompt. With no images it is exactly a TextModel.
using VisionModel = std::function<Result<std::string>(const std::string& system, const std::string& user, const std::vector<ImageData>& images)>;

struct TextModelOptions {
    // The role whose provider, model and effort answer. A role the user turned off falls back to the orchestrator, so a
    // person who only configured one model still gets answers; the choice is reported in TextModelInfo.
    std::string role = kRoleFast;
    // Used instead of the real providers (tests; the editor passes nothing). Used for every provider kind, with no key check.
    ProviderFactory providerFactory;
    ProviderRuntime runtime;  // HTTP transport and environment of the real providers
    // Folder a CLI agent (Claude Code, Codex...) runs in: an empty one, so the model sees nothing of the project. Created when
    // missing. Empty = a folder in the system temp directory.
    std::string cliWorkDir;
    // Called after every answer with what it used and cost (US dollars; an API provider's is estimated from its price list, a CLI
    // agent's is what it reports, 0 when it reports none), on the thread that asked. The caller adds it to its own run (the
    // retrospective of a long run). Not called when the call failed.
    std::function<void(const Usage&, double costUsd)> onUsage;
};

struct TextModelInfo {
    std::string role;      // the role that answers (the requested one, or "orchestrator" when it is off)
    std::string provider;
    std::string model;
};

// The model of `options.role`. Error (with a hint) when the role names no provider, the CLI is not installed, the provider only
// makes assets or the API provider has no key. Chat providers are called with no tools and 4096 output tokens at most; CLI
// agents run read-only with every tool that changes things or reaches the network disallowed.
// Same checks as make_text_model. A model the provider refuses because of the pictures gets a hint to point the role at a vision
// model; a provider that only makes assets is refused up front.
Result<VisionModel> make_vision_model(const AiConfig& cfg, const TextModelOptions& options = {}, TextModelInfo* info = nullptr);
Result<TextModel> make_text_model(const AiConfig& cfg, const TextModelOptions& options = {}, TextModelInfo* info = nullptr);

}  // namespace fa::ai
