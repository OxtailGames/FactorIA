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

Json recipe_args(const Json& a, std::initializer_list<std::pair<const char*, Json>> set) {
    Json out = a.is_object() ? a : Json::object();
    out.erase("overwrite");
    for (const auto& [key, value] : set) {
        if (value.is_null()) out.erase(key);
        else out[key] = value;
    }
    return out;
}

std::string recipe_path(const std::string& rel) {
    auto norm = fs::normalize_checked(rel);
    return norm.ok() && !norm->empty() ? *norm : rel;
}

RecipeCheck check_recipe(const std::string& projectDir, const Json& recipe) {
    RecipeCheck check;
    if (!recipe.is_object() || !recipe.contains("inputs") || !recipe["inputs"].is_array()) return check;
    for (const Json& input : recipe["inputs"]) {
        if (!input.is_object() || !input.contains("path") || !input["path"].is_string()) continue;
        const std::string rel = input["path"].get<std::string>();
        auto norm = fs::normalize_checked(rel);  // a recipe edited by hand must not read outside the project
        if (!norm.ok() || norm->empty()) {
            check.missing.push_back(rel);
            continue;
        }
        auto hash = sha256_file_hex(stdfs::path(projectDir) / *norm);
        if (!hash.ok()) check.missing.push_back(rel);
        else if (*hash != input.value("sha256", std::string())) check.changed.push_back(rel);
    }
    return check;
}

Json recipe_of(const Json& entry) {
    if (!entry.is_object() || !entry.contains("provenance") || !entry["provenance"].is_object()) return Json();
    const Json& prov = entry["provenance"];
    if (!prov.contains("recipe") || !prov["recipe"].is_object()) return Json();
    const Json& recipe = prov["recipe"];
    if (!recipe.contains("command") || !recipe["command"].is_string() || !recipe.contains("args") || !recipe["args"].is_object()) return Json();
    return recipe;
}

}  // namespace fa::assets_detail
