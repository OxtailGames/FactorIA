// provenance.recipe: what the offline makers record so assets.regenerate can make an asset again.
#include "assets_internal.h"
#include "fa/core/hash.h"

namespace fa::assets_detail {

Json make_recipe(const std::string& projectDir, const std::string& command, Json args, const std::vector<std::string>& inputs) {
    Json list = Json::array();
    for (const std::string& rel : inputs) {
        auto hash = sha256_file_hex(project_file(projectDir, rel));
        if (!hash.ok()) fail("failed", "Cannot hash '" + rel + "' for the asset's recipe: " + hash.error().message, hash.error().hint);
        list.push_back(Json::object({{"path", rel}, {"sha256", hash.value()}}));
    }
    Json recipe = Json::object({{"command", command}, {"args", std::move(args)}});
    if (!list.empty()) recipe["inputs"] = std::move(list);
    return recipe;
}

}  // namespace fa::assets_detail
