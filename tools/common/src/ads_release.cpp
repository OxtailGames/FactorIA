// The ads setup of a game, as `factoria validate` and the Android and iOS exports see it (fa/tooling/ads_release.h).
#include "fa/tooling/ads_release.h"

#include <algorithm>
#include <cctype>
#include <filesystem>
#include <fstream>
#include <map>
#include <sstream>

#include "fa/core/i18n.h"
#include "fa/core/json.h"
#include "fa/runtime/project.h"
#include "fa/services/platform.h"

namespace fa {

namespace stdfs = std::filesystem;

namespace {

bool is_sample(const std::string& id) { return id.rfind("ca-app-pub-3940256099942544", 0) == 0; }

// ca-app-pub-<16 digits>/<10 digits>
bool unit_shape(const std::string& s) {
    static const std::string prefix = "ca-app-pub-";
    if (s.size() != prefix.size() + 16 + 1 + 10 || s.compare(0, prefix.size(), prefix) != 0) return false;
    for (std::size_t i = prefix.size(); i < s.size(); ++i) {
        const bool sep = i == prefix.size() + 16;
        if (sep ? s[i] != '/' : !std::isdigit(static_cast<unsigned char>(s[i]))) return false;
    }
    return true;
}

struct Setup {
    PlatformCatalog catalog;
    Json platform = Json::object();
    Json localization;                // the "localization" section of factoria.json (null when there is none)
    bool adsPluginOnAndroid = false;  // the admob plugin (or the plugin platform.ads.backend names) is built for Android
    bool adsPluginOnIos = false;      // ... and for iOS
    bool ok = false;
};

Setup read_setup(const std::string& dir) {
    Setup s;
    auto project = load_project(dir);
    if (!project.ok()) return s;
    if (project->raw.is_object() && project->raw.contains(kPlatformKey) && project->raw[kPlatformKey].is_object()) {
        s.platform = project->raw[kPlatformKey];
        s.catalog = parse_platform_catalog(s.platform).catalog;
    }
    if (project->raw.is_object() && project->raw.contains("localization")) s.localization = project->raw["localization"];
    for (const PluginSettings& p : project->plugins) {
        if (!(p.name == "admob" || (!s.catalog.adsBackend.empty() && p.name == s.catalog.adsBackend))) continue;
        const auto platforms = project->plugin_platforms(p);
        if (std::find(platforms.begin(), platforms.end(), "android") != platforms.end()) s.adsPluginOnAndroid = true;
        if (std::find(platforms.begin(), platforms.end(), "ios") != platforms.end()) s.adsPluginOnIos = true;
    }
    s.ok = true;
    return s;
}

bool scripts_call_set_under_age(const std::string& dir) {
    std::error_code ec;
    const stdfs::path scripts = stdfs::path(dir) / "scripts";
    if (!stdfs::is_directory(scripts, ec)) return false;
    for (stdfs::recursive_directory_iterator it(scripts, stdfs::directory_options::skip_permission_denied, ec), end; !ec && it != end; it.increment(ec)) {
        if (!it->is_regular_file(ec) || it->path().extension() != ".js") continue;
        std::ifstream in(it->path(), std::ios::binary);
        std::stringstream text;
        text << in.rdbuf();
        if (text.str().find("setUnderAge") != std::string::npos) return true;
    }
    return false;
}

}  // namespace

AdsExportSettings ads_export_settings(const std::string& projectDir, bool release) {
    const Setup s = read_setup(projectDir);
    AdsExportSettings out;
    out.appId = kAdmobSampleAppId;
    out.test = !release;
    out.audience = s.catalog.adsAudience.empty() ? "general" : s.catalog.adsAudience;
    if (release) {
        if (auto it = s.catalog.adsAppIds.find("android"); it != s.catalog.adsAppIds.end() && !it->second.empty()) out.appId = it->second;
    }
    return out;
}

AdsIosSettings ads_ios_settings(const std::string& projectDir, bool release) {
    const Setup s = read_setup(projectDir);
    AdsIosSettings out;
    out.present = s.adsPluginOnIos;
    out.appId = kAdmobSampleAppIdIos;
    out.test = !release;
    out.audience = s.catalog.adsAudience.empty() ? "general" : s.catalog.adsAudience;
    if (release) {
        if (auto it = s.catalog.adsAppIds.find("ios"); it != s.catalog.adsAppIds.end() && !it->second.empty()) out.appId = it->second;
    }
    out.trackingPrompt = s.catalog.adsTrackingPrompt;
    out.trackingDescription = s.catalog.adsTrackingDescription.empty() ? kDefaultTrackingDescription : s.catalog.adsTrackingDescription;
    // A locale key wins over the plain text, as in the products of the catalog: one sentence per language of the game, a key a
    // language lacks falls back to the default language.
    if (!s.catalog.adsTrackingDescriptionKey.empty() && !s.localization.is_null()) {
        const LocalizationSettings localization = parse_localization(s.localization).settings;
        if (localization.enabled()) {
            auto read = [&](const std::string& tag) -> std::string {
                const std::string file = "locales/" + tag + ".json";
                auto doc = load_json_file((stdfs::path(projectDir) / file).generic_string());
                if (!doc.ok()) return {};
                auto table = parse_string_table(*doc, tag, file);
                if (!table.ok()) return {};
                auto it = table->entries.find(s.catalog.adsTrackingDescriptionKey);
                if (it == table->entries.end()) return {};
                return it->second.plural() ? it->second.forms.at(PluralCategory::Other) : it->second.text;
            };
            const std::string base = read(localization.defaultLanguage);
            if (!base.empty()) out.trackingDescription = base;
            for (const std::string& tag : localization.languages) {
                std::string text = read(tag);
                out.trackingDescriptions[tag] = text.empty() ? out.trackingDescription : text;
            }
        }
    }
    return out;
}

std::vector<AdsIssue> check_ads(const std::string& projectDir, const std::string& only) {
    std::vector<AdsIssue> issues;
    const Setup s = read_setup(projectDir);
    if (!s.ok) return issues;
    auto wanted = [&](const char* platform) { return only.empty() || only == platform; };

    // The platforms differ in the wording and in where the ad unit of a placement is written: AdMob has one app per platform, so
    // ids.admob is the Android unit and ids.admob_ios the iOS one.
    struct PerPlatform {
        const char* platform;  // "android"
        const char* display;   // "Android"
        const char* unitKey;   // the key of the placement's ids
        bool present;          // the game has the ads plugin for it
    };
    const PerPlatform platforms[] = {{"android", "Android", "admob", s.adsPluginOnAndroid}, {"ios", "iOS", "admob_ios", s.adsPluginOnIos}};
    for (const PerPlatform& pp : platforms) {
        if (!pp.present || !wanted(pp.platform)) continue;
        const std::string plat = pp.platform;
        const std::string display = pp.display;
        const std::string key = pp.unitKey;
        const std::string appPointer = "/platform/ads/appIds/" + plat;
        const std::string appKey = "platform.ads.appIds." + plat;
        const auto appId = s.catalog.adsAppIds.find(plat);
        if (appId == s.catalog.adsAppIds.end() || appId->second.empty()) {
            issues.push_back({appPointer,
                              "the game has the admob plugin for " + display + " but " + appKey +
                                  " is not set: a release export would carry Google's sample app id and show test ads that earn nothing",
                              "Add the app id from the AdMob console (Apps > App settings): \"platform\": {\"ads\": {\"appIds\": {\"" + plat +
                                  "\": \"ca-app-pub-1234567890123456~1234567890\"}}}. Development exports use Google's test ads on purpose "
                                  "(docs/PLATFORM.md, \"Ads\").",
                              plat});
        } else if (is_sample(appId->second)) {
            issues.push_back({appPointer, appKey + " is Google's sample app id: a release export would show test ads that earn nothing",
                              "Replace it with your app's id from the AdMob console (Apps > App settings).", plat});
        }
        // Each placement needs its own rewarded ad unit for a release export.
        const Json* placements = nullptr;
        if (s.platform.contains("ads") && s.platform["ads"].is_object() && s.platform["ads"].contains("placements") &&
            s.platform["ads"]["placements"].is_array())
            placements = &s.platform["ads"]["placements"];
        if (!placements) continue;
        for (std::size_t i = 0; i < placements->size(); ++i) {
            const Json& e = (*placements)[i];
            if (!e.is_object()) continue;
            const std::string id = e.value("id", std::string());
            const std::string pointer = "/platform/ads/placements/" + std::to_string(i) + "/ids";
            std::string unit;
            if (e.contains("ids") && e["ids"].is_object() && e["ids"].contains(key) && e["ids"][key].is_string())
                unit = e["ids"][key].get<std::string>();
            if (unit.empty()) {
                issues.push_back({pointer,
                                  "the placement \"" + id + "\" has no \"ids\": {\"" + key + "\": ...}: a release build cannot load an ad for it" +
                                      (plat == "ios" ? " on iOS" : ""),
                                  "Create a rewarded ad unit for it in AdMob (Ad units > Add ad unit > Rewarded) in the " + display +
                                      " app and add \"ids\": {\"" + key + "\": \"ca-app-pub-1234567890123456/1234567890\"} to the placement. "
                                      "A development export uses Google's test unit." +
                                      (plat == "ios" ? " AdMob units belong to one app: the Android unit (ids.admob) does not work on iOS." : ""),
                                  plat});
            } else if (is_sample(unit)) {
                issues.push_back({pointer + "/" + key, "the placement \"" + id + "\" uses Google's sample ad unit: a release build would show test ads that earn nothing",
                                  "Replace it with the ad unit of your app from the AdMob console.", plat});
            } else if (!unit_shape(unit)) {
                issues.push_back({pointer + "/" + key, "\"" + unit + "\" is not an AdMob ad unit id: they look like ca-app-pub-1234567890123456/1234567890",
                                  "Copy the ad unit id from the AdMob console (Ad units). An id with a tilde (~) is the app id: it goes in platform.ads.appIds.",
                                  plat});
            }
        }
    }

    if (wanted("ios") && s.catalog.adsTrackingPrompt && !s.adsPluginOnIos) {
        issues.push_back({"/platform/ads/trackingPrompt",
                          "platform.ads.trackingPrompt is true but the game has no ads plugin for iOS: the \"Allow tracking\" sheet will never be shown",
                          "Add the admob backend for iOS on a Mac (`factoria call platform.add_backend '{\"backend\":\"admob\",\"sdk\":\"<Google Mobile Ads SDK for "
                          "iOS>\"}'`), or remove trackingPrompt (docs/PLATFORM.md, \"Ads on iOS\").",
                          "ios"});
    }

    if (s.catalog.adsAudience == "mixed" && !s.catalog.placements.empty() && !scripts_call_set_under_age(projectDir)) {
        issues.push_back({"/platform/ads/audience",
                          "the audience is \"mixed\" but no script calls platform.ads.setUnderAge(): no ad will load, because the engine does not request "
                          "ads or the consent form before it knows whether the player is under age",
                          "Add the menu kit's age gate (`factoria call project.add_menu_kit '{\"parts\":[\"ageGate\"]}'`), or ask the age yourself and call "
                          "platform.ads.setUnderAge(true or false). docs/PLATFORM.md, \"Children and consent\".",
                          ""});
    }
    return issues;
}

}  // namespace fa
