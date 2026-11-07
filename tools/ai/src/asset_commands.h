// The assets.* commands that generate assets and keep their provenance (private; registered by register_ai_commands).
#pragma once

#include <filesystem>
#include <functional>
#include <string>
#include <vector>

#include "fa/ai/assets.h"
#include "fa/ai/config.h"
#include "fa/ai/provider.h"
#include "fa/ai/asset_cost.h"
#include "fa/core/command.h"
#include "fa/tooling/style_guide.h"

namespace fa::ai {

// assets.generate_image, assets.generate_sprite_sheet, assets.generate_sound, assets.generate_music,
// assets.generate_voice, assets.generate_model, assets.pick, assets.provenance, assets.set_provenance, assets.disclosure.
void register_asset_commands(CommandRegistry& registry, std::function<Result<AiConfig>()> load,
                             std::function<std::string()> projectDir, ProviderRuntime runtime, const CancelFlag* cancel,
                             std::string runKey = {}, AssetApprover approver = {});

// What image_provider_commands.cpp shares with the generate_* commands (asset_commands.cpp).
namespace asset_support {

// Points fa::fs and fa::assets (the global project root) at `dir` for the life of the object.
struct ProjectScope {
    std::filesystem::path previous;
    bool changed;
    explicit ProjectScope(const std::string& dir);
    ~ProjectScope();
    ProjectScope(const ProjectScope&) = delete;
    ProjectScope& operator=(const ProjectScope&) = delete;
};
// assets.json "style" (a CommandError that names the problem when it is invalid).
using Style = StyleGuide;
Style load_house_style();
// The reference images at these project-relative paths (a CommandError for one that is not an image or cannot be read).
std::vector<ReferenceImage> load_reference_images(const std::vector<std::string>& paths);
// The paths normalized and without repeats.
std::vector<std::string> normalized_unique_paths(const std::vector<std::string>& raw);
// The provenance record assets.json keeps for a generated image, and storing it for `path`.
Json image_provenance(const Json& args, const ProviderConfig& provider, const AssetResult& made, const std::string& prompt,
                      const std::vector<std::string>& references, const std::string& notes);
void record_provenance(const std::string& path, const Json& provenance);

}  // namespace asset_support

}  // namespace fa::ai
