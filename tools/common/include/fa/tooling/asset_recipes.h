// What the editor (and any tool) needs to know about made assets: which entries of assets.json carry a provenance.recipe and
// whether its inputs still match. The same check as `factoria validate` and assets.regenerate (docs/ASSETS.md, "Recipes").
#pragma once

#include <string>
#include <vector>

namespace fa {

struct AssetRecipeStatus {
    std::string path;                  // project-relative path of the made asset
    std::string command;               // the command that makes it again (recipe.command)
    std::vector<std::string> inputs;   // every input path of the recipe (project-relative)
    std::vector<std::string> changed;  // inputs whose sha256 differs from the recorded one: the asset is stale
    std::vector<std::string> missing;  // inputs that no longer exist or cannot be read: it cannot be made again
    bool stale() const { return !changed.empty(); }
};

// Every entry of the project's assets.json that has a recipe and whose file exists, sorted by path. Reads and hashes the inputs
// (small files); empty when there is no assets.json or no recipe.
std::vector<AssetRecipeStatus> asset_recipe_statuses(const std::string& projectDir);

}  // namespace fa
