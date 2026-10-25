// The ads setup of a game, as `factoria validate` and the Android export see it (fa/tooling/ads_release.h).
#include "fa/tooling/ads_release.h"

#include <algorithm>
#include <cctype>
#include <filesystem>
#include <fstream>
#include <sstream>

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
    bool adsPluginOnAndroid = false;  // the admob plugin (or the plugin platform.ads.backend names) is built for Android
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
    for (const PluginSettings& p : project->plugins) {
        const auto platforms = project->plugin_platforms(p);
        if (std::find(platforms.begin(), platforms.end(), "android") == platforms.end()) continue;
        if (p.name == "admob" || (!s.catalog.adsBackend.empty() && p.name == s.catalog.adsBackend)) s.adsPluginOnAndroid = true;
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

std::vector<AdsIssue> check_ads(const std::string& projectDir) {
    std::vector<AdsIssue> issues;
    const Setup s = read_setup(projectDir);
    if (!s.ok) return issues;

    if (s.adsPluginOnAndroid) {
        const auto appId = s.catalog.adsAppIds.find("android");
        if (appId == s.catalog.adsAppIds.end() || appId->second.empty()) {
            issues.push_back({"/platform/ads/appIds/android",
                              "the game has the admob plugin for Android but platform.ads.appIds.android is not set: a release export would carry Google's "
                              "sample app id and show test ads that earn nothing",
                              "Add the app id from the AdMob console (Apps > App settings): \"platform\": {\"ads\": {\"appIds\": {\"android\": "
                              "\"ca-app-pub-1234567890123456~1234567890\"}}}. Development exports use Google's test ads on purpose (docs/PLATFORM.md, \"Ads\")."});
        } else if (is_sample(appId->second)) {
            issues.push_back({"/platform/ads/appIds/android",
                              "platform.ads.appIds.android is Google's sample app id: a release export would show test ads that earn nothing",
                              "Replace it with your app's id from the AdMob console (Apps > App settings)."});
        }
        // Each placement needs its own rewarded ad unit for a release export.
        const Json* placements = nullptr;
        if (s.platform.contains("ads") && s.platform["ads"].is_object() && s.platform["ads"].contains("placements") && s.platform["ads"]["placements"].is_array())
            placements = &s.platform["ads"]["placements"];
        if (placements) {
            for (std::size_t i = 0; i < placements->size(); ++i) {
                const Json& e = (*placements)[i];
                if (!e.is_object()) continue;
                const std::string id = e.value("id", std::string());
                const std::string pointer = "/platform/ads/placements/" + std::to_string(i) + "/ids";
                std::string unit;
                if (e.contains("ids") && e["ids"].is_object() && e["ids"].contains("admob") && e["ids"]["admob"].is_string())
                    unit = e["ids"]["admob"].get<std::string>();
                if (unit.empty()) {
                    issues.push_back({pointer, "the placement \"" + id + "\" has no \"ids\": {\"admob\": ...}: a release build cannot load an ad for it",
                                      "Create a rewarded ad unit for it in AdMob (Ad units > Add ad unit > Rewarded) and add \"ids\": {\"admob\": "
                                      "\"ca-app-pub-1234567890123456/1234567890\"} to the placement. A development export uses Google's test unit."});
                } else if (is_sample(unit)) {
                    issues.push_back({pointer + "/admob", "the placement \"" + id + "\" uses Google's sample ad unit: a release build would show test ads that earn nothing",
                                      "Replace it with the ad unit of your app from the AdMob console."});
                } else if (!unit_shape(unit)) {
                    issues.push_back({pointer + "/admob", "\"" + unit + "\" is not an AdMob ad unit id: they look like ca-app-pub-1234567890123456/1234567890",
                                      "Copy the ad unit id from the AdMob console (Ad units). An id with a tilde (~) is the app id: it goes in platform.ads.appIds."});
                }
            }
        }
    }

    if (s.catalog.adsAudience == "mixed" && !s.catalog.placements.empty() && !scripts_call_set_under_age(projectDir)) {
        issues.push_back({"/platform/ads/audience",
                          "the audience is \"mixed\" but no script calls platform.ads.setUnderAge(): no ad will load, because the engine does not request "
                          "ads or the consent form before it knows whether the player is under age",
                          "Add the menu kit's age gate (`factoria call project.add_menu_kit '{\"parts\":[\"ageGate\"]}'`), or ask the age yourself and call "
                          "platform.ads.setUnderAge(true or false). docs/PLATFORM.md, \"Children and consent\"."});
    }
    return issues;
}

}  // namespace fa
