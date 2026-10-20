#include "fa/tooling/export_settings.h"

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <regex>
#include <optional>

#include "fa/core/strings.h"
#include "fa/runtime/project.h"
#include "fa/tooling/ios_privacy.h"
#include "fa/tooling/setup.h"
#include "util.h"

namespace fa {

namespace stdfs = std::filesystem;

// ===========================================================================
// Defaults and small helpers
// ===========================================================================

std::string ProjectExportSettings::icon_for(const std::string& platform) const {
    const std::string* own = nullptr;
    if (platform == "windows") own = &windows.icon;
    else if (platform == "macos") own = &macos.icon;
    else if (platform == "linux") own = &linux.icon;
    else if (platform == "android") own = &android.icon;
    else if (platform == "ios") own = &ios.icon;
    return own && !own->empty() ? *own : icon;
}

int android_version_code_from(const std::string& v) {
    long parts[3] = {0, 0, 0};
    int idx = 0;
    std::size_t i = 0;
    while (idx < 3 && i < v.size() && std::isdigit(static_cast<unsigned char>(v[i]))) {
        long n = 0;
        while (i < v.size() && std::isdigit(static_cast<unsigned char>(v[i]))) n = std::min(n * 10 + (v[i++] - '0'), 99L);
        parts[idx++] = n;
        if (i < v.size() && v[i] == '.') ++i;
        else break;
    }
    const long code = parts[0] * 10000 + parts[1] * 100 + parts[2];
    return int(code < 1 ? 1 : code);
}

int ProjectExportSettings::android_version_code() const {
    return android.versionCode > 0 ? android.versionCode : android_version_code_from(projectVersion);
}

std::string ProjectExportSettings::ios_build_number() const {
    return !ios.buildNumber.empty() ? ios.buildNumber : projectVersion;
}

namespace {

// "factoria.json#/export/android/minSdk: message"
std::string issue_message(const ExportSettingsIssue& i) {
    std::string s = std::string(kProjectFileName);
    if (!i.pointer.empty()) s += "#" + i.pointer;
    return s + ": " + i.message;
}

}  // namespace

std::string ExportSettingsIssue::to_string() const {
    std::string s = issue_message(*this);
    if (!hint.empty()) s += " (hint: " + hint + ")";
    return s;
}

namespace {

constexpr const char* kPlatformNames[] = {"windows", "macos", "linux", "android", "ios"};
constexpr const char* kConfigFormat = "factoria.export-config/1";

std::vector<std::string> names_of(std::initializer_list<const char*> list) {
    return std::vector<std::string>(list.begin(), list.end());
}

bool is_hex_color(const std::string& s) {
    static const std::regex re("^#[0-9A-Fa-f]{6}$");
    return std::regex_match(s, re);
}

bool is_dotted_version(const std::string& s) {
    static const std::regex re("^[0-9]+(\\.[0-9]+){0,2}$");
    return std::regex_match(s, re);
}

// ===========================================================================
// Reading factoria.json
// ===========================================================================

struct Reader : tooling_detail::SettingsReader<ExportSettingsParse> {
    bool take_string(const Json& obj, const std::string& base, const char* key, std::string& out, const std::string& hint) {
        auto it = obj.find(key);
        if (it == obj.end() || it->is_null()) return false;
        if (!it->is_string()) {
            error(base + "/" + key, "expected a string, got " + describe_json_value(*it), hint);
            return false;
        }
        out = it->get<std::string>();
        return true;
    }

    // A non-empty string.
    bool take_nonempty(const Json& obj, const std::string& base, const char* key, std::string& out, const std::string& hint) {
        std::string v;
        if (!take_string(obj, base, key, v, hint)) return false;
        if (v.empty()) {
            error(base + "/" + key, "must not be empty", hint);
            return false;
        }
        out = v;
        return true;
    }

    // Checks a project-relative file path (backslashes become forward slashes); records an error and returns false when
    // it is absolute (unless allowed) or leaves the project. "" is fine: it means "not set".
    bool check_path(const std::string& pointer, std::string& v, bool allowAbsolute) {
        std::replace(v.begin(), v.end(), '\\', '/');
        const bool absolute = !v.empty() && (v[0] == '/' || (v.size() >= 2 && v[1] == ':'));
        if (absolute && !allowAbsolute) {
            error(pointer, "'" + v + "' is an absolute path",
                  "Copy the file into the project and write its path relative to factoria.json, e.g. \"assets/icon.png\".");
            return false;
        }
        if (!absolute) {
            for (const std::string& seg : split(v, '/'))
                if (seg == "..") {
                    error(pointer, "'" + v + "' leaves the project folder",
                          "The file must be inside the project: move it there and use a path like \"assets/icon.png\".");
                    return false;
                }
        }
        return true;
    }

    // A project-relative file (forward slashes; backslashes are converted). "" means "not set".
    bool take_path(const Json& obj, const std::string& base, const char* key, std::string& out, bool allowAbsolute = false) {
        std::string v;
        if (!take_string(obj, base, key, v, "Use a path relative to factoria.json with forward slashes, e.g. \"assets/icon.png\".")) return false;
        if (!check_path(base + "/" + key, v, allowAbsolute)) return false;
        out = v;
        return true;
    }

    // A whole number in [minValue, maxValue].
    bool take_int(const Json& obj, const std::string& base, const char* key, int& out, int minValue, int maxValue,
                  const std::string& hint) {
        auto it = obj.find(key);
        if (it == obj.end() || it->is_null()) return false;
        if (!it->is_number_integer()) {
            error(base + "/" + key, "expected a whole number, got " + describe_json_value(*it), hint);
            return false;
        }
        const long long v = it->get<long long>();
        if (v < minValue) {
            error(base + "/" + key, "value " + std::to_string(v) + " is below the minimum " + std::to_string(minValue),
                  hint);
            return false;
        }
        if (v > maxValue) {
            error(base + "/" + key, "value " + std::to_string(v) + " is above the maximum " + std::to_string(maxValue),
                  hint);
            return false;
        }
        out = int(v);
        return true;
    }

    bool take_hex_color(const Json& obj, const std::string& base, const char* key, std::string& out) {
        std::string v;
        const std::string hint = "Write the colour as \"#RRGGBB\", e.g. \"#FFFFFF\" for white.";
        if (!take_string(obj, base, key, v, hint)) return false;
        if (!is_hex_color(v)) {
            error(base + "/" + key, "'" + v + "' is not a colour", hint);
            return false;
        }
        out = v;
        return true;
    }

    // ---- platforms ---------------------------------------------------------------------------------------------

    void windows(const Json& o, const std::string& base, WindowsExportSettings& s) {
        take_path(o, base, "icon", s.icon);
        unknown_keys(o, base, names_of({"icon"}));
    }

    void macos(const Json& o, const std::string& base, MacosExportSettings& s) {
        take_path(o, base, "icon", s.icon);
        take_nonempty(o, base, "category", s.category,
                      "Use an LSApplicationCategoryType such as \"public.app-category.games\" (or remove the key for that default).");
        std::string minVersion;
        if (take_nonempty(o, base, "minimumSystemVersion", minVersion,
                          "Use a macOS version like \"11.0\" (or remove the key for that default).")) {
            if (!is_dotted_version(minVersion))
                error(base + "/minimumSystemVersion", "'" + minVersion + "' is not a macOS version",
                      "Write it as major.minor, e.g. \"11.0\" or \"13.3\".");
            else if (std::atoi(minVersion.c_str()) < 11)
                error(base + "/minimumSystemVersion", "'" + minVersion + "' is older than macOS 11.0",
                      "FactorIA's macOS player needs macOS 11.0 or newer: use \"11.0\" or higher.");
            else
                s.minimumSystemVersion = minVersion;
        }
        take_string(o, base, "copyright", s.copyright, "Write the notice as text, e.g. \"Copyright 2026 My Studio\".");
        unknown_keys(o, base, names_of({"icon", "category", "minimumSystemVersion", "copyright"}));
    }

    void linux_(const Json& o, const std::string& base, LinuxExportSettings& s) {
        take_path(o, base, "icon", s.icon);
        if (auto it = o.find("categories"); it != o.end() && !it->is_null()) {
            const std::string hint = "Write an array of freedesktop categories, e.g. [\"Game\", \"ActionGame\"].";
            if (!it->is_array()) {
                error(base + "/categories", "expected an array of strings, got " + describe_json_value(*it), hint);
            } else {
                std::vector<std::string> cats;
                bool ok = true;
                for (std::size_t i = 0; i < it->size(); ++i) {
                    const Json& e = (*it)[i];
                    const std::string ptr = base + "/categories/" + std::to_string(i);
                    if (!e.is_string()) {
                        error(ptr, "expected a string, got " + describe_json_value(e), hint);
                        ok = false;
                    } else if (e.get<std::string>().empty() || e.get<std::string>().find(';') != std::string::npos) {
                        error(ptr, "category names must be non-empty and must not contain ';'",
                              "Each array element is one category: [\"Game\", \"ActionGame\"]; FactorIA joins them with ';'.");
                        ok = false;
                    } else {
                        cats.push_back(e.get<std::string>());
                    }
                }
                if (ok) s.categories = std::move(cats);
            }
        }
        unknown_keys(o, base, names_of({"icon", "categories"}));
    }

    void adaptive_icon(const Json& o, const std::string& base, AndroidAdaptiveIconSettings& s) {
        take_path(o, base, "foreground", s.foreground);
        take_path(o, base, "monochrome", s.monochrome);
        std::string bg;
        if (take_string(o, base, "background", bg, "Use \"#RRGGBB\" or the project-relative path of an image.")) {
            if (bg.empty()) {
                error(base + "/background", "must not be empty", "Use \"#RRGGBB\" (default \"#FFFFFF\") or the path of an image.");
            } else if (bg[0] == '#') {
                if (is_hex_color(bg)) s.background = bg;
                else error(base + "/background", "'" + bg + "' is not a colour", "Write the colour as \"#RRGGBB\", e.g. \"#202020\".");
            } else if (check_path(base + "/background", bg, false)) {
                s.background = bg;
            }
        }
        unknown_keys(o, base, names_of({"foreground", "background", "monochrome"}));
    }

    void signing(const Json& o, const std::string& base, AndroidSigningSettings& s) {
        take_path(o, base, "keystore", s.keystore, /*allowAbsolute=*/true);
        take_string(o, base, "alias", s.alias, "Write the key alias as text, e.g. \"upload\".");
        unknown_keys(o, base, names_of({"keystore", "alias"}));
        if (!s.keystore.empty() && s.alias.empty())
            warn(base + "/alias", "signing.keystore is set but signing.alias is not",
                 "Add \"alias\": \"<key alias>\" (the name you gave the key in keytool -genkeypair -alias ...); a release build cannot be signed without it.");
        if (s.keystore.empty() && !s.alias.empty())
            warn(base + "/keystore", "signing.alias is set but signing.keystore is not",
                 "Add \"keystore\": \"<path to the .keystore or .jks file>\"; a release build cannot be signed without it.");
    }

    void android(const Json& o, const std::string& base, AndroidExportSettings& s) {
        take_path(o, base, "icon", s.icon);
        std::string format;
        if (take_string(o, base, "format", format, "Use \"apk\", \"aab\" or \"gradle\".")) {
            const auto allowed = names_of({"apk", "aab", "gradle"});
            if (std::find(allowed.begin(), allowed.end(), format) == allowed.end())
                error(base + "/format", "unknown format '" + format + "'", did_you_mean(format, allowed));
            else
                s.format = format;
        }
        if (const Json* a = object_member(o, base, "adaptiveIcon", "{\"foreground\": \"assets/icon_fg.png\", \"background\": \"#FFFFFF\"}"))
            adaptive_icon(*a, base + "/adaptiveIcon", s.adaptiveIcon);
        take_int(o, base, "versionCode", s.versionCode, 1, 2100000000,
                 "Use a whole number from 1 up; every upload to Google Play needs a higher one. Remove the key to derive it from \"version\" (1.2.3 -> 10203).");
        int minSdk = s.minSdk, targetSdk = s.targetSdk;
        const std::size_t errorsBefore = result.errors.size();
        take_int(o, base, "minSdk", minSdk, 26, 99, "Use an Android API level of at least 26 (Android 8.0), e.g. 26.");
        take_int(o, base, "targetSdk", targetSdk, 26, 99,
                 "Use an Android API level of at least 26; Google Play asks for the latest one (default 36).");
        if (result.errors.size() == errorsBefore) {
            if (minSdk > targetSdk)
                error(base + "/minSdk", "minSdk (" + std::to_string(minSdk) + ") is higher than targetSdk (" + std::to_string(targetSdk) + ")",
                      "Keep 26 <= minSdk <= targetSdk: lower minSdk or raise targetSdk.");
            else {
                s.minSdk = minSdk;
                s.targetSdk = targetSdk;
            }
        }
        if (auto it = o.find("permissions"); it != o.end() && !it->is_null()) {
            const std::string hint = "Write an array of Android permission names, e.g. [\"android.permission.VIBRATE\"].";
            if (!it->is_array()) {
                error(base + "/permissions", "expected an array of strings, got " + describe_json_value(*it), hint);
            } else {
                static const std::regex re("^[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z][A-Za-z0-9_]*)+$");
                std::vector<std::string> perms;
                bool ok = true;
                for (std::size_t i = 0; i < it->size(); ++i) {
                    const Json& e = (*it)[i];
                    const std::string ptr = base + "/permissions/" + std::to_string(i);
                    if (!e.is_string()) {
                        error(ptr, "expected a string, got " + describe_json_value(e), hint);
                        ok = false;
                    } else if (!std::regex_match(e.get<std::string>(), re)) {
                        error(ptr, "'" + e.get<std::string>() + "' is not a permission name",
                              "Permission names are dotted, e.g. \"android.permission.VIBRATE\" or \"com.google.android.gms.permission.AD_ID\".");
                        ok = false;
                    } else {
                        perms.push_back(e.get<std::string>());
                    }
                }
                if (ok) s.permissions = std::move(perms);
            }
        }
        if (const Json* sg = object_member(o, base, "signing", "{\"keystore\": \"keys/upload.keystore\", \"alias\": \"upload\"}"))
            signing(*sg, base + "/signing", s.signing);
        unknown_keys(o, base, names_of({"icon", "format", "adaptiveIcon", "versionCode", "minSdk", "targetSdk", "permissions", "signing"}));
    }

    void ios(const Json& o, const std::string& base, IosExportSettings& s) {
        take_path(o, base, "icon", s.icon);
        take_hex_color(o, base, "iconBackground", s.iconBackground);
        std::string team;
        if (take_string(o, base, "teamId", team, "Use the 10-character Team ID of your Apple developer account, e.g. \"ABCDE12345\".")) {
            static const std::regex re("^[A-Z0-9]{10}$");
            if (!team.empty() && !std::regex_match(team, re))
                error(base + "/teamId", "'" + team + "' is not a team ID",
                      "A Team ID is 10 capital letters and digits (developer.apple.com/account > Membership details), e.g. \"ABCDE12345\".");
            else
                s.teamId = team;
        }
        if (auto it = o.find("buildNumber"); it != o.end() && !it->is_null()) {
            const std::string hint = "CFBundleVersion is up to three whole numbers separated by dots, e.g. \"42\" or \"1.2.3\".";
            std::string v;
            bool valid = true;
            if (it->is_string()) v = it->get<std::string>();
            else if (it->is_number_integer()) v = std::to_string(it->get<long long>());
            else {
                error(base + "/buildNumber", "expected a string, got " + describe_json_value(*it), hint);
                valid = false;
            }
            if (valid) {
                if (!v.empty() && !is_dotted_version(v)) error(base + "/buildNumber", "'" + v + "' is not a build number", hint);
                else s.buildNumber = v;
            }
        }
        if (auto it = o.find("usesNonExemptEncryption"); it != o.end() && !it->is_null()) {
            if (!it->is_boolean())
                error(base + "/usesNonExemptEncryption", "expected true or false, got " + describe_json_value(*it),
                      "Write true only when the game uses encryption beyond what iOS provides (HTTPS through the system is exempt); "
                      "remove the key for the default, false.");
            else
                s.usesNonExemptEncryption = it->get<bool>();
        }
        if (const Json* pv = object_member(o, base, "privacy", "{\"accessedApis\": [{\"category\": \"DiskSpace\", \"reasons\": [\"E174.1\"]}]}"))
            privacy(*pv, base + "/privacy", s.privacy);
        unknown_keys(o, base, names_of({"icon", "iconBackground", "teamId", "buildNumber", "usesNonExemptEncryption", "privacy"}));
    }

    // An array of strings, each checked against `allowed` (when not empty) with a "did you mean"; duplicates are dropped.
    // Returns false (after recording the errors) when the array or an element is wrong.
    bool take_names(const Json& obj, const std::string& base, const char* key, const std::string& hint,
                    const std::vector<std::string>& allowed, std::vector<std::string>& out) {
        auto it = obj.find(key);
        if (it == obj.end() || it->is_null()) return true;
        if (!it->is_array()) {
            error(base + "/" + key, "expected an array of strings, got " + describe_json_value(*it), hint);
            return false;
        }
        std::vector<std::string> names;
        bool ok = true;
        for (std::size_t i = 0; i < it->size(); ++i) {
            const Json& e = (*it)[i];
            const std::string ptr = base + "/" + key + "/" + std::to_string(i);
            if (!e.is_string()) {
                error(ptr, "expected a string, got " + describe_json_value(e), hint);
                ok = false;
                continue;
            }
            const std::string v = e.get<std::string>();
            if (!allowed.empty() && std::find(allowed.begin(), allowed.end(), v) == allowed.end()) {
                error(ptr, "'" + v + "' is not a value Apple accepts here", did_you_mean(v, allowed) + " " + hint);
                ok = false;
                continue;
            }
            if (std::find(names.begin(), names.end(), v) == names.end()) names.push_back(v);
        }
        if (ok) out = std::move(names);
        return ok;
    }

    // export.ios.privacy: what the game adds to the privacy manifest (the engine's own entries are always there).
    void privacy(const Json& o, const std::string& base, IosPrivacySettings& s) {
        if (auto it = o.find("tracking"); it != o.end() && !it->is_null()) {
            if (!it->is_boolean())
                error(base + "/tracking", "expected true or false, got " + describe_json_value(*it),
                      "Write true only when the app or an SDK in it tracks users (NSPrivacyTracking); the default is false.");
            else
                s.tracking = it->get<bool>();
        }
        take_names(o, base, "trackingDomains", "Write the domains that are used to track, e.g. [\"ads.example.com\"].", {}, s.trackingDomains);
        if (s.tracking && s.trackingDomains.empty())
            warn(base + "/tracking", "tracking is true but trackingDomains is empty",
                 "Apple expects the domains that connect to tracking services in trackingDomains; list them, or set tracking back to false.");
        std::vector<std::string> categoryNames;
        for (const IosPrivacyApiCategory& c : ios_privacy_api_categories()) categoryNames.push_back(c.category);
        if (auto it = o.find("accessedApis"); it != o.end() && !it->is_null()) {
            const std::string hint = "Write [{\"category\": \"DiskSpace\", \"reasons\": [\"E174.1\"]}]; docs/MOBILE.md lists the categories and codes.";
            if (!it->is_array()) {
                error(base + "/accessedApis", "expected an array of objects, got " + describe_json_value(*it), hint);
            } else {
                std::vector<IosPrivacyApi> apis;
                bool ok = true;
                for (std::size_t i = 0; i < it->size(); ++i) {
                    const Json& e = (*it)[i];
                    const std::string ptr = base + "/accessedApis/" + std::to_string(i);
                    if (!e.is_object()) {
                        error(ptr, "expected an object, got " + describe_json_value(e), hint);
                        ok = false;
                        continue;
                    }
                    std::string category;
                    if (!take_nonempty(e, ptr, "category", category, "Name the API category, e.g. \"DiskSpace\".")) {
                        if (!e.contains("category")) error(ptr + "/category", "missing", "Name the API category, e.g. \"DiskSpace\".");
                        ok = false;
                        continue;
                    }
                    const auto known = std::find_if(ios_privacy_api_categories().begin(), ios_privacy_api_categories().end(),
                                                    [&](const IosPrivacyApiCategory& c) { return c.category == category; });
                    if (known == ios_privacy_api_categories().end()) {
                        error(ptr + "/category", "'" + category + "' is not a required-reason API category", did_you_mean(category, categoryNames));
                        ok = false;
                        continue;
                    }
                    const std::string reasonHint = "Pick from " + join(known->reasons, ", ") + " (docs/MOBILE.md says what each one allows).";
                    IosPrivacyApi api;
                    api.category = category;
                    if (!e.contains("reasons") || !e["reasons"].is_array() || e["reasons"].empty()) {
                        error(ptr + "/reasons", "missing or empty: Apple wants at least one reason code per category", reasonHint);
                        ok = false;
                        continue;
                    }
                    if (!take_names(e, ptr, "reasons", reasonHint, known->reasons, api.reasons)) {
                        ok = false;
                        continue;
                    }
                    unknown_keys(e, ptr, names_of({"category", "reasons"}));
                    apis.push_back(std::move(api));
                }
                if (ok) s.accessedApis = std::move(apis);
            }
        }
        if (auto it = o.find("collectedData"); it != o.end() && !it->is_null()) {
            const std::string hint = "Write [{\"type\": \"PurchaseHistory\", \"linked\": true, \"purposes\": [\"AppFunctionality\"]}].";
            if (!it->is_array()) {
                error(base + "/collectedData", "expected an array of objects, got " + describe_json_value(*it), hint);
            } else {
                std::vector<IosPrivacyCollectedData> items;
                bool ok = true;
                for (std::size_t i = 0; i < it->size(); ++i) {
                    const Json& e = (*it)[i];
                    const std::string ptr = base + "/collectedData/" + std::to_string(i);
                    if (!e.is_object()) {
                        error(ptr, "expected an object, got " + describe_json_value(e), hint);
                        ok = false;
                        continue;
                    }
                    std::string type;
                    if (!take_nonempty(e, ptr, "type", type, "Name the kind of data, e.g. \"PurchaseHistory\".")) {
                        if (!e.contains("type")) error(ptr + "/type", "missing", "Name the kind of data, e.g. \"PurchaseHistory\".");
                        ok = false;
                        continue;
                    }
                    if (std::find(ios_privacy_data_types().begin(), ios_privacy_data_types().end(), type) == ios_privacy_data_types().end()) {
                        error(ptr + "/type", "'" + type + "' is not a data type of Apple's privacy manifest",
                              did_you_mean(type, ios_privacy_data_types()) + " docs/MOBILE.md lists them.");
                        ok = false;
                        continue;
                    }
                    IosPrivacyCollectedData d;
                    d.type = type;
                    for (const char* flag : {"linked", "tracking"}) {
                        auto f = e.find(flag);
                        if (f == e.end() || f->is_null()) continue;
                        if (!f->is_boolean()) {
                            error(ptr + "/" + flag, "expected true or false, got " + describe_json_value(*f), hint);
                            ok = false;
                        } else {
                            (std::string(flag) == "linked" ? d.linked : d.tracking) = f->get<bool>();
                        }
                    }
                    const std::string purposeHint = "Pick from " + join(ios_privacy_purposes(), ", ") + ".";
                    if (!e.contains("purposes") || !e["purposes"].is_array() || e["purposes"].empty()) {
                        error(ptr + "/purposes", "missing or empty: Apple wants at least one purpose per collected data type", purposeHint);
                        ok = false;
                    } else if (!take_names(e, ptr, "purposes", purposeHint, ios_privacy_purposes(), d.purposes)) {
                        ok = false;
                    }
                    unknown_keys(e, ptr, names_of({"type", "linked", "tracking", "purposes"}));
                    items.push_back(std::move(d));
                }
                if (ok) s.collectedData = std::move(items);
            }
        }
        unknown_keys(o, base, names_of({"tracking", "trackingDomains", "accessedApis", "collectedData"}));
    }
};

}  // namespace

ExportSettingsParse parse_export_settings(const Json& pj) {
    Reader r;
    ProjectExportSettings& s = r.result.settings;
    if (!pj.is_object()) return r.result;
    if (auto it = pj.find("version"); it != pj.end() && it->is_string()) s.projectVersion = it->get<std::string>();
    r.take_path(pj, "", "icon", s.icon);

    auto it = pj.find("export");
    if (it == pj.end() || it->is_null()) return r.result;
    if (!it->is_object()) {
        r.error("/export", "expected an object with one entry per platform, got " + describe_json_value(*it),
                "Write it as {\"android\": {\"format\": \"aab\"}}; platforms: windows, macos, linux, android, ios.");
        return r.result;
    }
    const Json& exp = *it;
    std::vector<std::string> known(std::begin(kPlatformNames), std::end(kPlatformNames));
    known.push_back("scriptBytecode");
    known.push_back("exclude");
    r.unknown_keys(exp, "/export", known);
    if (auto b = exp.find("scriptBytecode"); b != exp.end() && !b->is_null()) {
        if (!b->is_boolean())
            r.error("/export/scriptBytecode", "expected true or false, got " + describe_json_value(*b),
                    "Write \"scriptBytecode\": false to ship the scripts of a --release export as plain source, or remove the key "
                    "(the default, true, compiles them to bytecode).");
        else
            s.scriptBytecode = b->get<bool>();
    }
    if (auto ex = exp.find("exclude"); ex != exp.end() && !ex->is_null()) {
        const std::string hint = "Write a list of project-relative globs, e.g. \"exclude\": [\"store/**\", \"levels/*.tmx\"].";
        if (!ex->is_array()) {
            r.error("/export/exclude", "expected an array of glob strings, got " + describe_json_value(*ex), hint);
        } else {
            for (std::size_t i = 0; i < ex->size(); ++i) {
                const std::string ptr = "/export/exclude/" + std::to_string(i);
                if (!(*ex)[i].is_string()) {
                    r.error(ptr, "expected a glob string, got " + describe_json_value((*ex)[i]), hint);
                    continue;
                }
                std::string g = (*ex)[i].get<std::string>();
                if (g.empty()) r.error(ptr, "the glob is empty", hint);
                else if (r.check_path(ptr, g, false)) s.exclude.push_back(g);
            }
        }
    }
    if (const Json* o = r.object_member(exp, "/export", "windows", "{\"icon\": \"assets/icon.png\"}")) r.windows(*o, "/export/windows", s.windows);
    if (const Json* o = r.object_member(exp, "/export", "macos", "{\"category\": \"public.app-category.games\"}")) r.macos(*o, "/export/macos", s.macos);
    if (const Json* o = r.object_member(exp, "/export", "linux", "{\"categories\": [\"Game\"]}")) r.linux_(*o, "/export/linux", s.linux);
    if (const Json* o = r.object_member(exp, "/export", "android", "{\"format\": \"apk\"}")) r.android(*o, "/export/android", s.android);
    if (const Json* o = r.object_member(exp, "/export", "ios", "{\"teamId\": \"ABCDE12345\"}")) r.ios(*o, "/export/ios", s.ios);
    return r.result;
}

namespace {

std::optional<std::string> read_project_file(const std::string& projectDir, std::string* path) {
    const stdfs::path p = stdfs::path(projectDir.empty() ? "." : projectDir) / kProjectFileName;
    if (path) *path = p.generic_string();
    return tooling_detail::read_file(p);
}

}  // namespace

Result<ProjectExportSettings> load_export_settings(const std::string& projectDir, std::vector<std::string>* warnings) {
    std::string path;
    const auto text = read_project_file(projectDir, &path);
    if (!text)
        return make_error("Cannot read " + path + ".", "Run from the project folder or pass the folder that contains factoria.json.");
    auto parsed = parse_json(*text, path);
    if (!parsed.ok()) return parsed.error();
    if (!parsed->is_object())
        return make_error(path + ": the project file must be a JSON object, got " + describe_json_value(*parsed),
                          "Start from {\"format\": \"factoria.project/1\", \"name\": \"My Game\"}.");
    ExportSettingsParse r = parse_export_settings(*parsed);
    if (warnings)
        for (const auto& w : r.warnings) warnings->push_back(w.to_string());
    if (!r.errors.empty()) {
        const ExportSettingsIssue& first = r.errors.front();
        std::string hint = first.hint;
        if (r.errors.size() > 1)
            hint += (hint.empty() ? "" : " ") + std::string("(") + std::to_string(r.errors.size() - 1) +
                    " more problem(s) in icon/export: run `factoria validate` to list them all.)";
        return make_error(issue_message(first), hint);
    }
    return std::move(r.settings);
}

// ===========================================================================
// Writing factoria.json: patch the text of `icon` and `export` only
// ===========================================================================

namespace {

struct Member {
    std::string key;
    std::size_t keyStart = 0;    // offset of the opening quote of the key
    std::size_t valueStart = 0;  // first character of the value
    std::size_t valueEnd = 0;    // one past its last character
};

struct TopLevel {
    std::size_t open = 0;   // offset of '{'
    std::size_t close = 0;  // offset of '}'
    std::vector<Member> members;
};

bool is_ws(char c) { return c == ' ' || c == '\t' || c == '\n' || c == '\r'; }

std::size_t skip_ws(const std::string& t, std::size_t i) {
    while (i < t.size() && is_ws(t[i])) ++i;
    return i;
}

// One past the closing quote of the string starting at `i` (t[i] == '"'); npos when it never closes.
std::size_t skip_string(const std::string& t, std::size_t i) {
    for (++i; i < t.size(); ++i) {
        if (t[i] == '\\') ++i;
        else if (t[i] == '"') return i + 1;
    }
    return std::string::npos;
}

// One past the end of the JSON value starting at `i`; npos on malformed text.
std::size_t skip_value(const std::string& t, std::size_t i) {
    if (i >= t.size()) return std::string::npos;
    if (t[i] == '"') return skip_string(t, i);
    if (t[i] == '{' || t[i] == '[') {
        int depth = 0;
        for (; i < t.size(); ++i) {
            const char c = t[i];
            if (c == '"') {
                i = skip_string(t, i);
                if (i == std::string::npos) return i;
                --i;
            } else if (c == '{' || c == '[') {
                ++depth;
            } else if (c == '}' || c == ']') {
                if (--depth == 0) return i + 1;
            }
        }
        return std::string::npos;
    }
    while (i < t.size() && t[i] != ',' && t[i] != '}' && t[i] != ']' && !is_ws(t[i])) ++i;
    return i;
}

bool scan_top_level(const std::string& t, TopLevel& out) {
    std::size_t i = skip_ws(t, 0);
    if (t.compare(i, 3, "\xEF\xBB\xBF") == 0) i = skip_ws(t, i + 3);
    if (i >= t.size() || t[i] != '{') return false;
    out.open = i++;
    for (;;) {
        i = skip_ws(t, i);
        if (i >= t.size()) return false;
        if (t[i] == '}') {
            out.close = i;
            return true;
        }
        if (t[i] != '"') return false;
        Member m;
        m.keyStart = i;
        const std::size_t keyEnd = skip_string(t, i);
        if (keyEnd == std::string::npos) return false;
        auto key = parse_json(std::string_view(t).substr(i, keyEnd - i));
        m.key = key.ok() && key->is_string() ? key->get<std::string>() : t.substr(i + 1, keyEnd - i - 2);
        i = skip_ws(t, keyEnd);
        if (i >= t.size() || t[i] != ':') return false;
        i = skip_ws(t, i + 1);
        m.valueStart = i;
        m.valueEnd = skip_value(t, i);
        if (m.valueEnd == std::string::npos) return false;
        out.members.push_back(std::move(m));
        i = skip_ws(t, out.members.back().valueEnd);
        if (i < t.size() && t[i] == ',') ++i;
    }
}

const Member* find_member(const TopLevel& top, const std::string& key) {
    for (auto it = top.members.rbegin(); it != top.members.rend(); ++it)
        if (it->key == key) return &*it;
    return nullptr;
}

// Layout facts of the file, so that new text looks like the old.
struct Style {
    std::string indent = "  ";   // one level (the leading whitespace of the first member)
    std::string newline = "\n";
    bool inlineArrays = false;   // the file keeps arrays of scalars on one line: ["a", "b"]
};

bool has_inline_array(const std::string& t) {
    for (std::size_t i = 0; i < t.size(); ++i) {
        if (t[i] == '"') {
            i = skip_string(t, i);
            if (i == std::string::npos) return false;
            --i;
        } else if (t[i] == '[') {
            std::size_t j = i + 1;
            while (j < t.size() && (t[j] == ' ' || t[j] == '\t')) ++j;
            if (j < t.size() && t[j] != '\n' && t[j] != '\r' && t[j] != ']') return true;
        }
    }
    return false;
}

Style detect_style(const std::string& t, const TopLevel& top) {
    Style s;
    if (t.find("\r\n") != std::string::npos) s.newline = "\r\n";
    s.inlineArrays = has_inline_array(t);
    if (!top.members.empty()) {
        const std::size_t k = top.members.front().keyStart;
        std::size_t b = k;
        while (b > 0 && (t[b - 1] == ' ' || t[b - 1] == '\t')) --b;
        if (b == 0 || t[b - 1] == '\n') {
            if (k > b) s.indent = t.substr(b, k - b);
        }
    }
    return s;
}

// The text of `value` as the member of the top-level object: the engine's layout (2-space levels, scalar arrays on one
// line when the file does that), in the file's own indent unit and line endings.
std::string render_value(const Json& value, const Style& style) {
    JsonFormat compact;
    std::string text = style.inlineArrays ? dump_json(value, compact) : dump_json(value);
    while (!text.empty() && text.back() == '\n') text.pop_back();
    std::string out;
    std::size_t lineStart = 0;
    bool first = true;
    while (lineStart <= text.size()) {
        std::size_t eol = text.find('\n', lineStart);
        if (eol == std::string::npos) eol = text.size();
        std::string line = text.substr(lineStart, eol - lineStart);
        if (!first) {
            std::size_t spaces = 0;
            while (spaces < line.size() && line[spaces] == ' ') ++spaces;
            std::string lead = style.indent;  // the member sits one level in
            for (std::size_t d = 0; d < spaces / 2; ++d) lead += style.indent;
            out += style.newline + lead + line.substr(spaces);
        } else {
            out += line;
        }
        first = false;
        lineStart = eol + 1;
    }
    return out;
}

std::string quoted(const std::string& key) { return Json(key).dump(-1, ' ', false, Json::error_handler_t::replace); }

// Replaces the value of `key`, or appends the member after the last one.
std::string set_member(const std::string& t, const TopLevel& top, const Style& style, const std::string& key,
                       const std::string& valueText) {
    if (const Member* m = find_member(top, key)) {
        std::string out = t;
        out.replace(m->valueStart, m->valueEnd - m->valueStart, valueText);
        return out;
    }
    std::string out = t;
    const std::string member = quoted(key) + ": " + valueText;
    if (top.members.empty()) {
        out.replace(top.open + 1, top.close - top.open - 1, style.newline + style.indent + member + style.newline);
        return out;
    }
    const Member& last = top.members.back();
    // The whitespace that separated the previous member from the last one is reused (newline + indent, or a space).
    std::size_t b = last.keyStart;
    while (b > 0 && is_ws(t[b - 1])) --b;
    const std::string sep = t.substr(b, last.keyStart - b);
    out.insert(last.valueEnd, "," + (sep.empty() ? std::string(" ") : sep) + member);
    return out;
}

std::string remove_member(const std::string& t, const TopLevel& top, const std::string& key) {
    const Member* m = find_member(top, key);
    if (!m) return t;
    const std::size_t i = std::size_t(m - top.members.data());
    const std::size_t n = top.members.size();
    std::string out = t;
    if (n == 1) {
        const std::string between = t.substr(top.open + 1, top.close - top.open - 1);
        out.replace(top.open + 1, top.close - top.open - 1, between.find('\n') != std::string::npos ? "\n" : "");
    } else if (i + 1 < n) {
        out.erase(m->keyStart, top.members[i + 1].keyStart - m->keyStart);
    } else {
        out.erase(top.members[i - 1].valueEnd, m->valueEnd - top.members[i - 1].valueEnd);
    }
    return out;
}

// Sets (or, when `now` is the default, removes) obj[key] if it changed.
template <class T>
void sync_field(Json& obj, const char* key, const T& before, const T& now, const T& def) {
    if (now == before) return;
    if (now == def) obj.erase(key);
    else obj[key] = now;
}

Json& object_at(Json& parent, const char* key) {
    if (!parent.contains(key) || !parent[key].is_object()) parent[key] = Json::object();
    return parent[key];
}

}  // namespace

Result<void> save_export_settings(const std::string& projectDir, const ProjectExportSettings& now) {
    std::string path;
    const auto fileText = read_project_file(projectDir, &path);
    if (!fileText)
        return make_error("Cannot save the export settings: " + path + " does not exist.",
                          "Create the project with `factoria new` or pass the folder that contains factoria.json.");
    const std::string& text = *fileText;
    auto parsed = parse_json(text, path);
    if (!parsed.ok()) return make_error(parsed.error().message, "Fix the JSON syntax of factoria.json first; the export settings are not saved over a broken file.");
    if (!parsed->is_object())
        return make_error(path + ": the project file must be a JSON object, got " + describe_json_value(*parsed),
                          "Start from {\"format\": \"factoria.project/1\", \"name\": \"My Game\"}.");
    TopLevel top;
    if (!scan_top_level(text, top))
        return make_error(path + ": cannot locate the top-level keys to patch.", "Fix the JSON syntax of factoria.json.");

    const ProjectExportSettings before = parse_export_settings(*parsed).settings;
    const ProjectExportSettings def;

    const bool iconChanged = before.icon != now.icon;

    // The new `export` object: the existing one with the changed fields updated (unknown keys stay).
    Json exp = parsed->contains("export") && (*parsed)["export"].is_object() ? (*parsed)["export"] : Json::object();
    bool exportChanged = false;
    auto finish = [&](const char* platform) {  // a platform whose fields are all defaults leaves no object behind
        exportChanged = true;
        if (exp.contains(platform) && exp[platform].is_object() && exp[platform].empty()) exp.erase(platform);
    };
    if (!(before.windows == now.windows)) {
        Json& o = object_at(exp, "windows");
        sync_field(o, "icon", before.windows.icon, now.windows.icon, def.windows.icon);
        finish("windows");
    }
    if (!(before.macos == now.macos)) {
        Json& o = object_at(exp, "macos");
        sync_field(o, "icon", before.macos.icon, now.macos.icon, def.macos.icon);
        sync_field(o, "category", before.macos.category, now.macos.category, def.macos.category);
        sync_field(o, "minimumSystemVersion", before.macos.minimumSystemVersion, now.macos.minimumSystemVersion, def.macos.minimumSystemVersion);
        sync_field(o, "copyright", before.macos.copyright, now.macos.copyright, def.macos.copyright);
        finish("macos");
    }
    if (!(before.linux == now.linux)) {
        Json& o = object_at(exp, "linux");
        sync_field(o, "icon", before.linux.icon, now.linux.icon, def.linux.icon);
        sync_field(o, "categories", before.linux.categories, now.linux.categories, def.linux.categories);
        finish("linux");
    }
    if (!(before.android == now.android)) {
        Json& o = object_at(exp, "android");
        const AndroidExportSettings &b = before.android, &n = now.android, &d = def.android;
        sync_field(o, "icon", b.icon, n.icon, d.icon);
        sync_field(o, "format", b.format, n.format, d.format);
        if (!(b.adaptiveIcon == n.adaptiveIcon)) {
            Json& a = object_at(o, "adaptiveIcon");
            sync_field(a, "foreground", b.adaptiveIcon.foreground, n.adaptiveIcon.foreground, d.adaptiveIcon.foreground);
            sync_field(a, "background", b.adaptiveIcon.background, n.adaptiveIcon.background, d.adaptiveIcon.background);
            sync_field(a, "monochrome", b.adaptiveIcon.monochrome, n.adaptiveIcon.monochrome, d.adaptiveIcon.monochrome);
            if (a.empty()) o.erase("adaptiveIcon");
        }
        sync_field(o, "versionCode", b.versionCode, n.versionCode, d.versionCode);
        sync_field(o, "minSdk", b.minSdk, n.minSdk, d.minSdk);
        sync_field(o, "targetSdk", b.targetSdk, n.targetSdk, d.targetSdk);
        sync_field(o, "permissions", b.permissions, n.permissions, d.permissions);
        if (!(b.signing == n.signing)) {
            Json& s = object_at(o, "signing");
            sync_field(s, "keystore", b.signing.keystore, n.signing.keystore, d.signing.keystore);
            sync_field(s, "alias", b.signing.alias, n.signing.alias, d.signing.alias);
            if (s.empty()) o.erase("signing");
        }
        finish("android");
    }
    if (!(before.ios == now.ios)) {
        Json& o = object_at(exp, "ios");
        sync_field(o, "icon", before.ios.icon, now.ios.icon, def.ios.icon);
        sync_field(o, "iconBackground", before.ios.iconBackground, now.ios.iconBackground, def.ios.iconBackground);
        sync_field(o, "teamId", before.ios.teamId, now.ios.teamId, def.ios.teamId);
        sync_field(o, "buildNumber", before.ios.buildNumber, now.ios.buildNumber, def.ios.buildNumber);
        sync_field(o, "usesNonExemptEncryption", before.ios.usesNonExemptEncryption, now.ios.usesNonExemptEncryption,
                   def.ios.usesNonExemptEncryption);
        // export.ios.privacy is edited in factoria.json only: a save leaves it as it is.
        finish("ios");
    }
    if (before.scriptBytecode != now.scriptBytecode) {
        sync_field(exp, "scriptBytecode", before.scriptBytecode, now.scriptBytecode, def.scriptBytecode);
        exportChanged = true;
    }
    if (!iconChanged && !exportChanged) return {};

    const Style style = detect_style(text, top);
    std::string out = text;
    if (iconChanged) {
        if (now.icon.empty()) out = remove_member(out, top, "icon");
        else out = set_member(out, top, style, "icon", render_value(Json(now.icon), style));
    }
    if (exportChanged) {
        TopLevel top2;
        if (!scan_top_level(out, top2)) return make_error(path + ": internal error while patching the file", "Report this as an engine bug.");
        if (exp.empty()) out = remove_member(out, top2, "export");
        else out = set_member(out, top2, style, "export", render_value(exp, style));
    }

    // Never write a file that would not parse.
    auto check = parse_json(out, path);
    if (!check.ok() || !check->is_object())
        return make_error(path + ": internal error: the patched file would not be valid JSON; nothing was written.",
                          "Report this as an engine bug with the contents of the export settings.");
    std::string err;
    if (!tooling_detail::write_file(stdfs::path(path), out, &err))
        return make_error("Cannot write " + path + ": " + err, "Check that the folder is writable.");
    return {};
}

// ===========================================================================
// Machine settings: ~/.factoria/export.json
// ===========================================================================

ExportEnvLookup system_export_env() {
    return [](const std::string& name) -> std::string {
        const char* v = std::getenv(name.c_str());
        return v ? v : "";
    };
}

std::string machine_export_config_path(const ExportEnvLookup& env) {
    if (auto o = env("FACTORIA_EXPORT_CONFIG"); !o.empty()) return o;
    if (auto h = env("FACTORIA_HOME"); !h.empty()) return (stdfs::path(h) / "export.json").string();
#ifdef _WIN32
    if (auto h = env("USERPROFILE"); !h.empty()) return (stdfs::path(h) / ".factoria" / "export.json").string();
#else
    if (auto h = env("HOME"); !h.empty()) return (stdfs::path(h) / ".factoria" / "export.json").string();
#endif
    return ".factoria/export.json";
}

namespace {

std::string config_path_or_default(const std::string& path) { return path.empty() ? machine_export_config_path() : path; }

}  // namespace

Result<MachineExportConfig> load_machine_export_config(const std::string& pathIn) {
    const std::string path = config_path_or_default(pathIn);
    MachineExportConfig cfg;
    std::error_code ec;
    if (!stdfs::exists(stdfs::path(path), ec)) return cfg;
    auto text = tooling_detail::read_file(stdfs::path(path));
    if (!text) return make_error("Cannot read " + path + ".", "Check that the file is readable, or delete it to start over.");
    auto parsed = parse_json(*text, path);
    if (!parsed.ok()) return make_error(parsed.error().message, "Fix the JSON syntax or delete the file; the editor's Platform settings > Android rewrites it.");
    const Json& j = *parsed;
    const std::string fix = "Expected {\"format\": \"" + std::string(kConfigFormat) +
                            "\", \"android\": {\"sdk\": \"...\", \"jdk\": \"...\", \"keystorePassword\": \"...\", \"keyPassword\": \"...\"}}.";
    if (!j.is_object()) return make_error(path + ": expected a JSON object, got " + describe_json_value(j), fix);
    if (auto it = j.find("format"); it != j.end() && (!it->is_string() || it->get<std::string>() != kConfigFormat))
        return make_error(path + "#/format: unsupported format " + describe_json_value(*it), "Use \"" + std::string(kConfigFormat) + "\" (or remove the key).");
    if (auto it = j.find("android"); it != j.end() && !it->is_null()) {
        if (!it->is_object()) return make_error(path + "#/android: expected an object, got " + describe_json_value(*it), fix);
        auto read = [&](const char* key, std::string& out) -> Result<void> {
            auto f = it->find(key);
            if (f == it->end() || f->is_null()) return {};
            if (!f->is_string())
                return make_error(path + "#/android/" + key + ": expected a string, got " + describe_json_value(*f), fix);
            out = f->get<std::string>();
            return {};
        };
        const std::pair<const char*, std::string*> fields[] = {{"sdk", &cfg.androidSdk},
                                                                {"jdk", &cfg.androidJdk},
                                                                {"keystorePassword", &cfg.androidKeystorePassword},
                                                                {"keyPassword", &cfg.androidKeyPassword}};
        for (const auto& [key, out] : fields) {
            auto r = read(key, *out);
            if (!r.ok()) return r.error();
        }
    }
    cfg.sourcePath = path;
#ifndef _WIN32
    if (!cfg.androidKeystorePassword.empty() || !cfg.androidKeyPassword.empty()) {
        const auto perms = stdfs::status(stdfs::path(path), ec).permissions();
        if ((perms & (stdfs::perms::group_read | stdfs::perms::others_read)) != stdfs::perms::none)
            cfg.warnings.push_back(path + " contains Android signing passwords but other users can read it. Run: chmod 600 " + path);
    }
#endif
    return cfg;
}

Result<void> save_machine_export_config(const MachineExportConfig& cfg, const std::string& pathIn) {
    const std::string path = config_path_or_default(pathIn);
    Json j = Json::object();
    std::error_code ec;
    if (stdfs::exists(stdfs::path(path), ec)) {
        auto text = tooling_detail::read_file(stdfs::path(path));
        if (text) {
            auto parsed = parse_json(*text, path);
            if (parsed.ok() && parsed->is_object()) j = std::move(*parsed);
        }
    }
    j["format"] = kConfigFormat;
    Json android = j.contains("android") && j["android"].is_object() ? j["android"] : Json::object();
    auto put = [&](const char* key, const std::string& v) {
        if (v.empty()) android.erase(key);
        else android[key] = v;
    };
    put("sdk", cfg.androidSdk);
    put("jdk", cfg.androidJdk);
    put("keystorePassword", cfg.androidKeystorePassword);
    put("keyPassword", cfg.androidKeyPassword);
    if (android.empty()) j.erase("android");
    else j["android"] = android;

    const stdfs::path p(path);
    if (p.has_parent_path()) stdfs::create_directories(p.parent_path(), ec);
    {
        std::ofstream f(p, std::ios::binary | std::ios::trunc);
        if (!f) return make_error("Cannot write " + path, "Check that the folder exists and is writable.");
#ifndef _WIN32
        stdfs::permissions(p, stdfs::perms::owner_read | stdfs::perms::owner_write, ec);  // before the passwords go in
#endif
        f << dump_json(j);
        if (!f) return make_error("Cannot write " + path, "Check that the disk is not full and the file is writable.");
    }
    return {};
}

AndroidSigningSecrets resolve_android_signing_secrets(const MachineExportConfig& cfg, const ExportEnvLookup& env) {
    AndroidSigningSecrets s;
    if (auto v = env("FACTORIA_ANDROID_KEYSTORE_PASSWORD"); !v.empty()) {
        s.keystorePassword = v;
        s.keystorePasswordFrom = "FACTORIA_ANDROID_KEYSTORE_PASSWORD";
    } else if (!cfg.androidKeystorePassword.empty()) {
        s.keystorePassword = cfg.androidKeystorePassword;
        s.keystorePasswordFrom = "export.json";
    }
    if (auto v = env("FACTORIA_ANDROID_KEY_PASSWORD"); !v.empty()) {
        s.keyPassword = v;
        s.keyPasswordFrom = "FACTORIA_ANDROID_KEY_PASSWORD";
    } else if (!cfg.androidKeyPassword.empty()) {
        s.keyPassword = cfg.androidKeyPassword;
        s.keyPasswordFrom = "export.json";
    } else if (!s.keystorePassword.empty()) {
        s.keyPassword = s.keystorePassword;
        s.keyPasswordFrom = "keystore password";
    }
    return s;
}

// ===========================================================================
// Android toolchain
// ===========================================================================

Json AndroidToolchain::to_json() const {
    Json j = Json::object({{"ok", ok()}, {"jdk", jdk}, {"jdkFrom", jdkFrom}, {"jdkMajor", jdkMajor}, {"sdk", sdk}, {"sdkFrom", sdkFrom}});
    j["problems"] = problems;
    j["warnings"] = warnings;
    return j;
}

namespace {

// Compares "6000.0.70f1" with "2022.3.10f1": digit runs numerically, other text as is.
bool natural_less(const std::string& a, const std::string& b) {
    std::size_t i = 0, j = 0;
    while (i < a.size() && j < b.size()) {
        if (std::isdigit(static_cast<unsigned char>(a[i])) && std::isdigit(static_cast<unsigned char>(b[j]))) {
            std::size_t ie = i, je = j;
            while (ie < a.size() && std::isdigit(static_cast<unsigned char>(a[ie]))) ++ie;
            while (je < b.size() && std::isdigit(static_cast<unsigned char>(b[je]))) ++je;
            std::string na = a.substr(i, ie - i), nb = b.substr(j, je - j);
            na.erase(0, std::min(na.find_first_not_of('0'), na.size()));
            nb.erase(0, std::min(nb.find_first_not_of('0'), nb.size()));
            if (na.size() != nb.size()) return na.size() < nb.size();
            if (na != nb) return na < nb;
            i = ie;
            j = je;
        } else {
            if (a[i] != b[j]) return a[i] < b[j];
            ++i;
            ++j;
        }
    }
    return (a.size() - i) < (b.size() - j);
}

// A path whose segments may be "*": every existing match, newest version first.
void expand_pattern(const stdfs::path& done, std::vector<stdfs::path> rest, std::vector<std::string>& out) {
    std::error_code ec;
    if (rest.empty()) {
        if (stdfs::exists(done, ec)) out.push_back(done.string());
        return;
    }
    const stdfs::path head = rest.front();
    rest.erase(rest.begin());
    if (head.string() != "*") {
        expand_pattern(done / head, std::move(rest), out);
        return;
    }
    std::vector<std::string> names;
    for (const auto& e : stdfs::directory_iterator(done, ec))
        if (e.is_directory(ec)) names.push_back(e.path().filename().string());
    std::sort(names.begin(), names.end(), [](const std::string& a, const std::string& b) { return natural_less(b, a); });
    for (const std::string& n : names) expand_pattern(done / n, rest, out);
}

std::vector<std::string> expand_candidate(const std::string& pattern) {
    std::vector<std::string> out;
    if (pattern.empty()) return out;
    // Path components: "/" "Applications" "Unity" ... (or "C:" "\\" "Program Files" ... on Windows); "*" expands.
    const stdfs::path pat(pattern);
    auto it = pat.begin();
    if (it == pat.end()) return out;
    const stdfs::path first = *it;
    std::vector<stdfs::path> parts(++it, pat.end());
    expand_pattern(first, std::move(parts), out);
    return out;
}

using tooling_detail::expand_home;

bool is_dir(const stdfs::path& p) {
    std::error_code ec;
    return stdfs::is_directory(p, ec);
}
bool is_file(const stdfs::path& p) {
    std::error_code ec;
    return stdfs::is_regular_file(p, ec);
}

constexpr int kMinJdk = 17;

// "" when `dir` is a JDK of Java 17+; otherwise what is wrong with it. `exists` tells whether the folder is there.
std::string jdk_issue(const std::string& dir, int& major, bool& exists) {
    major = 0;
    exists = is_dir(dir);
    if (!exists) return "'" + dir + "' does not exist.";
    const stdfs::path root(dir);
    if (!is_file(root / "bin" / "java") && !is_file(root / "bin" / "java.exe"))
        return "'" + dir + "' has no bin/java, so it is not a JDK folder (it must be the folder that contains bin/, lib/ and release).";
    if (!is_file(root / "bin" / "javac") && !is_file(root / "bin" / "javac.exe"))
        return "'" + dir + "' is a Java runtime without javac; Gradle needs a full JDK.";
    major = jdk_major_version(dir);
    if (major == 0) return "Cannot tell the Java version of '" + dir + "': its 'release' file is missing or has no JAVA_VERSION.";
    if (major < kMinJdk)
        return "'" + dir + "' is Java " + std::to_string(major) + "; the Android Gradle plugin needs Java " + std::to_string(kMinJdk) + " or newer.";
    return {};
}

// "" when `dir` looks like an Android SDK.
std::string sdk_issue(const std::string& dir, bool& exists) {
    exists = is_dir(dir);
    if (!exists) return "'" + dir + "' does not exist.";
    const stdfs::path root(dir);
    if (!is_dir(root / "platform-tools") && !is_dir(root / "platforms") && !is_dir(root / "licenses"))
        return "'" + dir + "' does not look like an Android SDK (it has no platform-tools, platforms or licenses folder).";
    return {};
}

// One folder to try. `explicitEntry` marks the folders the user named (the config file, an environment variable): when
// one of them is not usable the toolchain says so, with `fix` telling how to correct it.
struct Entry {
    std::string path;
    std::string from;
    std::string label;  // "The JDK folder in ~/.factoria/export.json", "JAVA_HOME"
    std::string fix;
    bool explicitEntry = false;
};

void add_explicit(std::vector<Entry>& v, const std::string& path, const std::string& from, const std::string& label,
                  const std::string& fix) {
    if (!path.empty()) v.push_back({path, from, label, fix, true});
}

void add_candidates(std::vector<Entry>& v, const std::vector<AndroidToolchainCandidate>& list) {
    for (const auto& c : list)
        for (const std::string& p : expand_candidate(c.path)) v.push_back({p, c.from, {}, {}, false});
}

// Picks the first usable entry. `issueOf` returns "" for a usable folder (and sets `exists`/`major`).
struct Pick {
    const Entry* chosen = nullptr;
    int chosenMajor = 0;
    const Entry* unusable = nullptr;  // the first folder that exists but does not qualify, to show it
    int unusableMajor = 0;
    std::string unusableIssue;
    std::vector<std::string> explicitIssues;  // one sentence per configured folder that does not qualify
};

template <class IssueFn>
Pick pick_entry(const std::vector<Entry>& entries, IssueFn issueOf) {
    Pick pick;
    for (const Entry& e : entries) {
        int major = 0;
        bool exists = false;
        const std::string issue = issueOf(e.path, major, exists);
        if (issue.empty()) {
            pick.chosen = &e;
            pick.chosenMajor = major;
            break;
        }
        if (e.explicitEntry) pick.explicitIssues.push_back(e.label + " is not usable: " + issue + " " + e.fix);
        if (exists && !pick.unusable) {
            pick.unusable = &e;
            pick.unusableMajor = major;
            pick.unusableIssue = issue;
        }
    }
    return pick;
}

}  // namespace

int jdk_major_version(const std::string& jdkDir) {
    auto text = tooling_detail::read_file(stdfs::path(jdkDir) / "release");
    if (!text) return 0;
    for (const std::string& line : split(*text, '\n')) {
        const std::string_view l = trim(line);
        if (l.rfind("JAVA_VERSION=", 0) != 0) continue;
        std::string v(l.substr(13));
        v.erase(std::remove(v.begin(), v.end(), '"'), v.end());
        if (v.empty() || !std::isdigit(static_cast<unsigned char>(v[0]))) return 0;
        int first = std::atoi(v.c_str());
        if (first == 1) {  // "1.8.0_392" -> 8
            const std::size_t dot = v.find('.');
            return dot == std::string::npos ? 1 : std::atoi(v.c_str() + dot + 1);
        }
        return first;
    }
    return 0;
}

AndroidToolchainSearch default_android_toolchain_search(const ExportEnvLookup& envLookup) {
    AndroidToolchainSearch s;
    if (envLookup) s.env = envLookup;
    const ExportEnvLookup& env = s.env;
    std::string home = env("HOME");
    if (home.empty()) home = env("USERPROFILE");
    auto under = [&](const char* rel) { return home.empty() ? std::string() : (stdfs::path(home) / rel).string(); };
    // What `factoria setup android` installs (fa/tooling/setup.h) comes first: the user asked FactorIA to provide it.
    const stdfs::path factoriaHome = factoria_home(env);
    s.jdk.push_back({(factoriaHome / "android" / "jdk").string(), "FactorIA"});
    s.sdk.push_back({(factoriaHome / "android" / "sdk").string(), "FactorIA"});
#if defined(__APPLE__)
    s.jdk.push_back({"/Applications/Android Studio.app/Contents/jbr/Contents/Home", "Android Studio"});
    if (!home.empty()) s.jdk.push_back({under("Applications/Android Studio.app/Contents/jbr/Contents/Home"), "Android Studio"});
    s.jdk.push_back({"/Applications/Unity/Hub/Editor/*/PlaybackEngines/AndroidPlayer/OpenJDK", "Unity Hub"});
    if (!home.empty()) s.sdk.push_back({under("Library/Android/sdk"), "default location"});
    s.sdk.push_back({"/Applications/Unity/Hub/Editor/*/PlaybackEngines/AndroidPlayer/SDK", "Unity Hub"});
#elif defined(_WIN32)
    std::string programFiles = env("ProgramFiles");
    if (programFiles.empty()) programFiles = "C:\\Program Files";
    s.jdk.push_back({(stdfs::path(programFiles) / "Android" / "Android Studio" / "jbr").string(), "Android Studio"});
    s.jdk.push_back({(stdfs::path(programFiles) / "Unity" / "Hub" / "Editor" / "*" / "Editor" / "Data" / "PlaybackEngines" / "AndroidPlayer" / "OpenJDK").string(), "Unity Hub"});
    if (auto local = env("LOCALAPPDATA"); !local.empty()) s.sdk.push_back({(stdfs::path(local) / "Android" / "Sdk").string(), "default location"});
    s.sdk.push_back({(stdfs::path(programFiles) / "Unity" / "Hub" / "Editor" / "*" / "Editor" / "Data" / "PlaybackEngines" / "AndroidPlayer" / "SDK").string(), "Unity Hub"});
#else
    s.jdk.push_back({"/opt/android-studio/jbr", "Android Studio"});
    if (!home.empty()) s.jdk.push_back({under("android-studio/jbr"), "Android Studio"});
    s.jdk.push_back({"/snap/android-studio/current/android-studio/jbr", "Android Studio"});
    if (!home.empty()) s.jdk.push_back({under("Unity/Hub/Editor/*/Editor/Data/PlaybackEngines/AndroidPlayer/OpenJDK"), "Unity Hub"});
    if (!home.empty()) s.sdk.push_back({under("Android/Sdk"), "default location"});
    if (!home.empty()) s.sdk.push_back({under("Unity/Hub/Editor/*/Editor/Data/PlaybackEngines/AndroidPlayer/SDK"), "Unity Hub"});
#endif
    return s;
}

AndroidToolchain find_android_toolchain(const MachineExportConfig& config, const AndroidToolchainSearch& search) {
    AndroidToolchain tc;
    const ExportEnvLookup env = search.env ? search.env : system_export_env();
    const std::string configFile = config.sourcePath.empty() ? "~/.factoria/export.json" : config.sourcePath;
    const std::string editor = "Platform settings > Android in the editor";

    // ---- JDK -------------------------------------------------------------------------------------------------
    {
        std::vector<Entry> entries;
        add_explicit(entries, expand_home(config.androidJdk, env), "config", "The JDK folder in " + configFile,
                     "Fix or clear it in " + editor + " or in " + configFile + ".");
        add_explicit(entries, expand_home(env("JAVA_HOME"), env), "JAVA_HOME", "JAVA_HOME",
                     "Fix or unset JAVA_HOME, or choose the JDK in " + editor + ".");
        add_candidates(entries, search.jdk);
        const Pick pick = pick_entry(entries, jdk_issue);
        if (pick.chosen) {
            tc.jdk = pick.chosen->path;
            tc.jdkFrom = pick.chosen->from;
            tc.jdkMajor = pick.chosenMajor;
            for (const std::string& w : pick.explicitIssues)
                tc.warnings.push_back(w + " Using the " + pick.chosen->from + " JDK at '" + pick.chosen->path + "' instead.");
        } else {
            tc.problems = pick.explicitIssues;
            if (pick.unusable) {
                tc.jdk = pick.unusable->path;
                tc.jdkFrom = pick.unusable->from;
                tc.jdkMajor = pick.unusableMajor;
                if (!pick.unusable->explicitEntry)
                    tc.problems.push_back("The JDK found at '" + pick.unusable->path + "' (" + pick.unusable->from + ") is not usable: " + pick.unusableIssue);
            }
            tc.problems.push_back(
                "No JDK " + std::to_string(kMinJdk) + " or newer found. Quickest: run `factoria setup android` (the command `setup.install` does the same), "
                "which downloads a JDK and the Android SDK for you. Or install Android Studio (it bundles a JDK) or a JDK " +
                std::to_string(kMinJdk) + "+ (https://adoptium.net), then point FactorIA at it: " + editor + ", \"android\": {\"jdk\": \"<folder>\"} in " +
                configFile + ", or the JAVA_HOME environment variable. The folder is the one that contains bin/java and release.");
        }
    }

    // ---- SDK -------------------------------------------------------------------------------------------------
    {
        std::vector<Entry> entries;
        const std::string fixSdk = "Fix or clear it in " + editor + " or in " + configFile + ".";
        add_explicit(entries, expand_home(config.androidSdk, env), "config", "The SDK folder in " + configFile, fixSdk);
        add_explicit(entries, expand_home(env("ANDROID_HOME"), env), "ANDROID_HOME", "ANDROID_HOME",
                     "Fix or unset ANDROID_HOME, or choose the SDK in " + editor + ".");
        add_explicit(entries, expand_home(env("ANDROID_SDK_ROOT"), env), "ANDROID_SDK_ROOT", "ANDROID_SDK_ROOT",
                     "Fix or unset ANDROID_SDK_ROOT, or choose the SDK in " + editor + ".");
        add_candidates(entries, search.sdk);
        const Pick pick = pick_entry(entries, [](const std::string& dir, int&, bool& exists) { return sdk_issue(dir, exists); });
        if (pick.chosen) {
            tc.sdk = pick.chosen->path;
            tc.sdkFrom = pick.chosen->from;
            for (const std::string& w : pick.explicitIssues)
                tc.warnings.push_back(w + " Using the SDK at '" + pick.chosen->path + "' (" + pick.chosen->from + ") instead.");
            if (!is_file(stdfs::path(pick.chosen->path) / "licenses" / "android-sdk-license"))
                tc.warnings.push_back(
                    "The Android SDK at '" + pick.chosen->path + "' has no accepted license (licenses/android-sdk-license): Gradle cannot download a "
                    "missing SDK platform until you accept the licenses. Run `factoria setup android` (it shows the license and records it once you "
                    "agree), `sdkmanager --licenses` (cmdline-tools/<revision>/bin) or open Android Studio's SDK Manager.");
        } else {
            tc.problems.insert(tc.problems.end(), pick.explicitIssues.begin(), pick.explicitIssues.end());
            if (pick.unusable) {
                tc.sdk = pick.unusable->path;
                tc.sdkFrom = pick.unusable->from;
                if (!pick.unusable->explicitEntry)
                    tc.problems.push_back("The folder found at '" + pick.unusable->path + "' (" + pick.unusable->from + ") is not usable: " + pick.unusableIssue);
            }
            tc.problems.push_back(
                "No Android SDK found. Quickest: run `factoria setup android` (the command `setup.install` does the same), which downloads the SDK "
                "and a JDK for you. Or install Android Studio (its SDK Manager downloads the SDK) or the command-line tools "
                "(https://developer.android.com/studio#command-line-tools-only, then `sdkmanager \"platform-tools\"`), then point FactorIA at the "
                "SDK folder: " + editor + ", \"android\": {\"sdk\": \"<folder>\"} in " + configFile + ", or the ANDROID_HOME environment variable.");
        }
    }
    return tc;
}

}  // namespace fa
