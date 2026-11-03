// provenance.recipe: what the offline makers record so assets.regenerate can make an asset again.
#include <algorithm>
#include <cmath>
#include <format>
#include <optional>

#include "assets_internal.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/hash.h"
#include "fa/tooling/style_guide.h"

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

std::optional<double> style_music_loudness(const std::string& projectDir) {
    StyleParse style = load_style_guide(projectDir);
    if (!style.guide.audio) return std::nullopt;
    auto it = style.guide.audio->loudnessLufs.find("music");
    if (it == style.guide.audio->loudnessLufs.end()) return std::nullopt;
    return it->second;
}

void add_style_loudness_context(Json& recipe, const std::optional<double>& target) {
    if (!recipe.contains("context") || !recipe["context"].is_object()) recipe["context"] = Json::object();
    recipe["context"]["styleMusicLufs"] = target ? Json(*target) : Json();
}

std::optional<double> style_texels_per_unit(const std::string& projectDir) {
    StyleParse style = load_style_guide(projectDir);
    return style.guide.texelsPerUnit;
}

void add_style_texels_context(Json& recipe, const std::optional<double>& value) {
    if (!recipe.contains("context") || !recipe["context"].is_object()) recipe["context"] = Json::object();
    recipe["context"]["styleTexelsPerUnit"] = value ? Json(*value) : Json();
}

std::vector<Vec4> style_palette_colors(const std::string& projectDir) {
    std::vector<Vec4> out;
    StyleParse style = load_style_guide(projectDir);
    if (!style.guide.palette) return out;
    for (const auto& c : *style.guide.palette) out.push_back(Vec4{c[0] / 255.0f, c[1] / 255.0f, c[2] / 255.0f, 1.0f});
    return out;
}

namespace {
Json palette_context_json(const std::vector<Vec4>& palette) {
    if (palette.empty()) return Json();
    Json list = Json::array();
    for (const Vec4& c : palette) {
        auto byte = [](float v) { return int(std::lround(std::clamp(v, 0.0f, 1.0f) * 255.0f)); };
        list.push_back(std::format("#{:02x}{:02x}{:02x}", byte(c.x), byte(c.y), byte(c.z)));
    }
    return list;
}
}  // namespace

void add_style_palette_context(Json& recipe, const std::vector<Vec4>& palette) {
    if (!recipe.contains("context") || !recipe["context"].is_object()) recipe["context"] = Json::object();
    recipe["context"]["stylePalette"] = palette_context_json(palette);
}

RecipeCheck check_recipe(const std::string& projectDir, const Json& recipe) {
    RecipeCheck check;
    if (!recipe.is_object()) return check;
    // A value read from assets.json and not from a file: the loudness the style guide asks of music. The recipe records it as a number, or
    // null when the style guide set none; a different value now makes the asset stale.
    if (recipe.contains("context") && recipe["context"].is_object() && recipe["context"].contains("styleMusicLufs")) {
        const Json& recorded = recipe["context"]["styleMusicLufs"];
        const std::optional<double> before = recorded.is_number() ? std::optional<double>(recorded.get<double>()) : std::nullopt;
        const std::optional<double> now = style_music_loudness(projectDir);
        if (before.has_value() != now.has_value() || (before && std::abs(*before - *now) > 1e-9))
            check.changed.push_back(std::string(assets::kManifestFile) + " (style.audio.loudnessLufs.music)");
    }
    // The same for the texel density a model document's `uv` section took from the style guide.
    if (recipe.contains("context") && recipe["context"].is_object() && recipe["context"].contains("styleTexelsPerUnit")) {
        const Json& recorded = recipe["context"]["styleTexelsPerUnit"];
        const std::optional<double> before = recorded.is_number() ? std::optional<double>(recorded.get<double>()) : std::nullopt;
        const std::optional<double> now = style_texels_per_unit(projectDir);
        if (before.has_value() != now.has_value() || (before && std::abs(*before - *now) > 1e-9))
            check.changed.push_back(std::string(assets::kManifestFile) + " (style.texelsPerUnit)");
    }
    // And the palette a model document's `vertexColors` took from the style guide.
    if (recipe.contains("context") && recipe["context"].is_object() && recipe["context"].contains("stylePalette")) {
        if (palette_context_json(style_palette_colors(projectDir)) != recipe["context"]["stylePalette"])
            check.changed.push_back(std::string(assets::kManifestFile) + " (style.palette)");
    }
    if (!recipe.contains("inputs") || !recipe["inputs"].is_array()) return check;
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
