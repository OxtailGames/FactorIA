#include "fa/tooling/ai_disclosure.h"

#include <algorithm>
#include <format>
#include <iterator>
#include <map>
#include <set>

#include "fa/core/asset_manifest.h"
#include "fa/core/strings.h"

namespace fa {

namespace {

// In the order of the report.
constexpr const char* kCategories[] = {"Art and images", "Sound effects", "Music", "Voice", "3D models",
                                       "Audio (sound effect, music or voice not recorded)"};
constexpr const char* kKinds[] = {"image", "sound", "music", "voice", "model3d"};  // provenance.kind of the first five

std::string text_of(const Json& j, const char* key) {
    auto it = j.find(key);
    return it != j.end() && it->is_string() ? it->get<std::string>() : std::string();
}

const Json* provenance_of(const Json& entry) {
    auto it = entry.find("provenance");
    return it != entry.end() && it->is_object() ? &*it : nullptr;
}

bool is_ai(const Json& provenance) {
    auto it = provenance.find("ai");
    return it != provenance.end() && it->is_boolean() && it->get<bool>();
}

// provenance.kind, else what the file is.
std::string category_of(const std::string& path, const Json& provenance) {
    const std::string kind = text_of(provenance, "kind");
    for (std::size_t i = 0; i < std::size(kKinds); ++i) {
        if (kind == kKinds[i]) return kCategories[i];
    }
    switch (assets::kind_of(path)) {
        case assets::AssetKind::Texture: return kCategories[0];
        case assets::AssetKind::Model: return kCategories[4];
        default: return kCategories[5];
    }
}

}  // namespace

bool has_ai_content(const Json& manifest) {
    auto records = manifest.find("assets");
    if (records == manifest.end() || !records->is_object()) return false;
    for (const auto& [path, entry] : records->items()) {
        const Json* p = entry.is_object() ? provenance_of(entry) : nullptr;
        if (p && is_ai(*p)) return true;
    }
    return false;
}

std::vector<std::string> assets_without_provenance(const Json& manifest, const std::vector<std::string>& assetFiles) {
    std::vector<std::string> missing;
    auto records = manifest.find("assets");
    for (const std::string& file : assetFiles) {
        if (file.rfind("assets/", 0) != 0 || assets::kind_of(file) == assets::AssetKind::Other) continue;
        const Json* entry = nullptr;
        if (records != manifest.end() && records->is_object()) {
            auto it = records->find(file);
            if (it != records->end() && it->is_object()) entry = &*it;
        }
        if (!entry || !provenance_of(*entry)) missing.push_back(file);
    }
    std::sort(missing.begin(), missing.end());
    return missing;
}

std::string ai_content_disclosure(const Json& manifest, const std::vector<std::string>& assetFiles) {
    const std::set<std::string> files(assetFiles.begin(), assetFiles.end());
    struct Row {
        std::string path, category, source, date;
    };
    std::vector<Row> ai;
    std::map<std::string, int> terms;  // "provider: license" -> assets
    auto records = manifest.find("assets");
    if (records != manifest.end() && records->is_object()) {
        for (const auto& [path, entry] : records->items()) {
            const Json* p = entry.is_object() ? provenance_of(entry) : nullptr;
            if (!p || !files.count(path) || !is_ai(*p)) continue;
            std::string provider = text_of(*p, "provider"), model = text_of(*p, "model");
            if (provider.empty()) provider = "unknown provider";
            ai.push_back({path, category_of(path, *p), model.empty() ? provider : provider + " (" + model + ")", text_of(*p, "date")});
            if (const std::string license = text_of(*p, "license"); !license.empty()) ++terms[provider + ": " + license];
        }
    }
    std::sort(ai.begin(), ai.end(), [](const Row& a, const Row& b) { return a.path < b.path; });

    std::string out =
        "# AI-generated content disclosure\n\n"
        "Written from the provenance records in assets.json. Use it to answer the AI-generated content questions of Steam's "
        "content survey (Steamworks, Store Page, Content Survey) and similar store forms. It is only as complete as the "
        "records: check the last section before you submit.\n\n"
        "## Pre-generated content (made with AI before the game shipped)\n\n";
    if (ai.empty()) {
        out += "None of the assets is recorded as made with AI.\n\n";
    } else {
        out += std::format("{} asset{} made with AI tools.\n\n| Category | Assets | Providers and models |\n|---|---|---|\n", ai.size(),
                           ai.size() == 1 ? " was" : "s were");
        for (const char* category : kCategories) {
            int count = 0;
            std::set<std::string> sources;
            for (const Row& r : ai) {
                if (r.category != category) continue;
                ++count;
                sources.insert(r.source);
            }
            if (count > 0) out += std::format("| {} | {} | {} |\n", category, count, fa::join(std::vector<std::string>(sources.begin(), sources.end()), ", "));
        }
        out += "\nAssets:\n\n";
        for (const Row& r : ai) out += std::format("- `{}`: {}, {}{}\n", r.path, r.category, r.source, r.date.empty() ? "" : ", " + r.date);
        out += "\n";
    }
    out += "## Live-generated content (made with AI while the game runs)\n\n"
           "None. The FactorIA engine generates no content at run time: every asset above is a fixed file that ships with the game.\n\n";
    if (!terms.empty()) {
        out += "## Terms recorded for the providers\n\n";
        for (const auto& [term, count] : terms) out += std::format("- {} ({} asset{})\n", term, count, count == 1 ? "" : "s");
        out += "\n";
    }
    const std::vector<std::string> missing = assets_without_provenance(manifest, assetFiles);
    out += "## Assets without provenance\n\n";
    if (missing.empty()) {
        out += "Every art, sound and model file under assets/ has a provenance record.\n";
    } else {
        out += "These files have no provenance record, so this disclosure cannot say how they were made. Record each one with "
               "`assets.set_provenance` (origin original or imported, `ai` true or false), then write the disclosure again.\n\n";
        for (const std::string& f : missing) out += std::format("- `{}`\n", f);
    }
    return out;
}

}  // namespace fa
