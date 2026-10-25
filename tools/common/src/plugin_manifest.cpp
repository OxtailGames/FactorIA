// plugin.json of a native plugin: parse, validate, merge and turn the entitlements into a property list.
#include "fa/tooling/plugin_manifest.h"

#include <algorithm>
#include <cctype>
#include <map>

#include "fa/core/strings.h"
#include "util.h"

namespace fa {

namespace {

Error problem(const std::string& file, const std::string& pointer, const std::string& message, const std::string& hint) {
    return Error{file + (pointer.empty() ? "" : "#" + pointer) + ": " + message, hint};
}

bool framework_name(const std::string& s) {
    if (s.empty() || !std::isalpha(static_cast<unsigned char>(s[0]))) return false;
    return std::all_of(s.begin(), s.end(), [](char c) { return std::isalnum(static_cast<unsigned char>(c)) || c == '_'; });
}

// com.apple.developer.game-center: letters, digits, dots, dashes, underscores.
bool entitlement_key(const std::string& s) {
    if (s.empty()) return false;
    return std::all_of(s.begin(), s.end(),
                       [](char c) { return std::isalnum(static_cast<unsigned char>(c)) || c == '.' || c == '-' || c == '_'; });
}

std::string xml_text(const std::string& s) {
    std::string out;
    for (char c : s) {
        switch (c) {
            case '&': out += "&amp;"; break;
            case '<': out += "&lt;"; break;
            case '>': out += "&gt;"; break;
            default: out += c;
        }
    }
    return out;
}

// One value of a property list at `depth` tabs of indentation (an Info.plist or .entitlements file).
void plist_value(std::string& s, const Json& v, int depth) {
    const std::string pad(static_cast<std::size_t>(depth), '\t');
    if (v.is_boolean()) {
        s += pad + (v.get<bool>() ? "<true/>\n" : "<false/>\n");
    } else if (v.is_number_integer()) {
        s += pad + "<integer>" + std::to_string(v.get<long long>()) + "</integer>\n";
    } else if (v.is_number()) {
        s += pad + "<real>" + v.dump() + "</real>\n";
    } else if (v.is_array()) {
        s += pad + "<array>\n";
        for (const Json& x : v) plist_value(s, x, depth + 1);
        s += pad + "</array>\n";
    } else if (v.is_object()) {
        s += pad + "<dict>\n";
        for (auto it = v.begin(); it != v.end(); ++it) {
            s += pad + "\t<key>" + xml_text(it.key()) + "</key>\n";
            plist_value(s, it.value(), depth + 1);
        }
        s += pad + "</dict>\n";
    } else {
        s += pad + "<string>" + xml_text(v.is_string() ? v.get<std::string>() : v.dump()) + "</string>\n";
    }
}

bool plist_value_ok(const Json& v) {
    if (v.is_null()) return false;
    if (v.is_array()) return std::all_of(v.begin(), v.end(), plist_value_ok);
    if (v.is_object()) return std::all_of(v.begin(), v.end(), plist_value_ok);
    return true;
}

// frameworks/Vendor.xcframework: inside the plugin folder, forward slashes, no "..", ends in .xcframework.
bool xcframework_path(const std::string& s) {
    static const std::string suffix = ".xcframework";
    if (s.size() <= suffix.size() || s.compare(s.size() - suffix.size(), suffix.size(), suffix) != 0) return false;
    if (s[0] == '/' || s.find('\\') != std::string::npos || s.find(':') != std::string::npos) return false;
    for (const std::string& part : split(s, '/', false))
        if (part.empty() || part == "." || part == "..") return false;
    return true;
}

}  // namespace

Result<PluginManifest> parse_plugin_manifest(const std::string& text, const std::string& file) {
    auto parsed = parse_json(text, file);
    if (!parsed.ok()) return parsed.error();
    const Json& root = parsed.value();
    if (!root.is_object())
        return problem(file, "", "a plugin manifest is a JSON object",
                       "Write {\"frameworks\": [\"StoreKit\"], \"swift\": true, \"entitlements\": {...}, \"xcframeworks\": [...], \"infoPlist\": {...}}; "
                       "every key is optional.");
    static const std::vector<std::string> kKeys = {"frameworks", "swift", "entitlements", "xcframeworks", "infoPlist"};
    PluginManifest out;
    for (auto it = root.begin(); it != root.end(); ++it) {
        const std::string& key = it.key();
        const std::string pointer = "/" + key;
        if (std::find(kKeys.begin(), kKeys.end(), key) == kKeys.end())
            return problem(file, pointer, "'" + key + "' is not a plugin manifest key", did_you_mean(key, kKeys));
        if (key == "frameworks") {
            if (!it->is_array())
                return problem(file, pointer, "frameworks is a list of system framework names",
                               "Write \"frameworks\": [\"StoreKit\", \"GameKit\"] (names without .framework).");
            for (std::size_t i = 0; i < it->size(); ++i) {
                const Json& f = (*it)[i];
                const std::string at = pointer + "/" + std::to_string(i);
                if (!f.is_string() || !framework_name(f.get<std::string>()))
                    return problem(file, at, "a framework is its name as a string, such as \"StoreKit\" (got " + describe_json_value(f) + ")",
                                   "Use the name of the system framework without the .framework suffix; letters, digits and underscores.");
                const std::string name = f.get<std::string>();
                if (std::find(out.frameworks.begin(), out.frameworks.end(), name) == out.frameworks.end()) out.frameworks.push_back(name);
            }
        } else if (key == "swift") {
            if (!it->is_boolean())
                return problem(file, pointer, "swift is true or false (got " + describe_json_value(*it) + ")",
                               "true: the plugin is written in Swift, so the iOS app is given the Swift runtime.");
            out.swift = it->get<bool>();
        } else if (key == "xcframeworks") {
            if (!it->is_array())
                return problem(file, pointer, "xcframeworks is a list of paths of .xcframework folders inside the plugin",
                               "Write \"xcframeworks\": [\"frameworks/GoogleMobileAds.xcframework\"]: paths relative to the folder of this plugin.json.");
            for (std::size_t i = 0; i < it->size(); ++i) {
                const Json& f = (*it)[i];
                const std::string at = pointer + "/" + std::to_string(i);
                if (!f.is_string() || !xcframework_path(f.get<std::string>()))
                    return problem(file, at,
                                   "an xcframework is the path of an .xcframework folder inside the plugin, such as \"frameworks/Vendor.xcframework\" (got " +
                                       describe_json_value(f) + ")",
                                   "Use a path relative to the folder of this plugin.json, with forward slashes, no '..' and ending in .xcframework.");
                const std::string path = f.get<std::string>();
                if (std::find(out.xcframeworks.begin(), out.xcframeworks.end(), path) == out.xcframeworks.end()) out.xcframeworks.push_back(path);
            }
        } else if (key == "infoPlist") {
            if (!it->is_object())
                return problem(file, pointer, "infoPlist is an object of Info.plist key to value",
                               "Write \"infoPlist\": {\"SKAdNetworkItems\": [{\"SKAdNetworkIdentifier\": \"cstr6suwn9.skadnetwork\"}]}.");
            for (auto e = it->begin(); e != it->end(); ++e) {
                const std::string at = pointer + "/" + e.key();
                if (e.key().empty() || !plist_value_ok(e.value()))
                    return problem(file, at, "the value of an Info.plist entry is text, true/false, a number, or a list or object of those (got " +
                                                 describe_json_value(e.value()) + ")",
                                   "null has no property-list form: leave the entry out.");
                out.infoPlist[e.key()] = e.value();
            }
        } else {
            if (!it->is_object())
                return problem(file, pointer, "entitlements is an object of entitlement name to value",
                               "Write \"entitlements\": {\"com.apple.developer.game-center\": true}.");
            for (auto e = it->begin(); e != it->end(); ++e) {
                const std::string at = pointer + "/" + e.key();
                if (!entitlement_key(e.key()))
                    return problem(file, at, "'" + e.key() + "' is not an entitlement name",
                                   "An entitlement is a reverse-DNS key such as com.apple.developer.game-center.");
                const Json& v = e.value();
                bool ok = v.is_boolean() || v.is_number_integer() || v.is_string();
                if (v.is_array()) {
                    ok = std::all_of(v.begin(), v.end(), [](const Json& x) { return x.is_string(); });
                }
                if (!ok)
                    return problem(file, at, "the value of an entitlement is true/false, a whole number, text or a list of text (got " +
                                                 describe_json_value(v) + ")",
                                   "Examples: true; \"$(TeamIdentifierPrefix)$(CFBundleIdentifier)\"; [\"group.com.example.game\"].");
                out.entitlements[e.key()] = v;
            }
        }
    }
    return out;
}

Result<PluginManifest> read_plugin_manifest(const std::filesystem::path& folder) {
    const std::filesystem::path file = folder / kPluginManifestFile;
    std::error_code ec;
    if (!std::filesystem::exists(file, ec)) return PluginManifest{};
    const auto text = tooling_detail::read_file(file);
    if (!text) return Error{"cannot read " + file.generic_string(), "Check the file's permissions."};
    return parse_plugin_manifest(*text, file.generic_string());
}

Result<PluginManifest> merge_plugin_manifests(const std::vector<NamedManifest>& manifests) {
    PluginManifest out;
    std::map<std::string, std::string> owner;      // entitlement -> the plugin that asked for it first
    std::map<std::string, std::string> infoOwner;  // Info.plist key -> the plugin that asked for it first
    for (const NamedManifest& n : manifests) {
        for (const std::string& f : n.manifest.frameworks)
            if (std::find(out.frameworks.begin(), out.frameworks.end(), f) == out.frameworks.end()) out.frameworks.push_back(f);
        out.swift = out.swift || n.manifest.swift;
        for (const std::string& x : n.manifest.xcframeworks) {
            const std::string path = n.plugin + "/" + x;
            if (std::find(out.xcframeworks.begin(), out.xcframeworks.end(), path) == out.xcframeworks.end()) out.xcframeworks.push_back(path);
        }
        for (auto it = n.manifest.infoPlist.begin(); it != n.manifest.infoPlist.end(); ++it) {
            auto have = out.infoPlist.find(it.key());
            if (have == out.infoPlist.end()) {
                out.infoPlist[it.key()] = it.value();
                infoOwner[it.key()] = n.plugin;
            } else if (*have != it.value()) {
                return Error{"the plugins '" + infoOwner[it.key()] + "' and '" + n.plugin + "' ask for the Info.plist entry " + it.key() +
                                 " with different values",
                             "Make both manifests (<plugin>/ios/plugin.json) agree, or drop the entry from the plugin that does not need it."};
            }
        }
        for (auto it = n.manifest.entitlements.begin(); it != n.manifest.entitlements.end(); ++it) {
            auto have = out.entitlements.find(it.key());
            if (have == out.entitlements.end()) {
                out.entitlements[it.key()] = it.value();
                owner[it.key()] = n.plugin;
            } else if (*have != it.value()) {
                return Error{"the plugins '" + owner[it.key()] + "' and '" + n.plugin + "' ask for the entitlement " + it.key() +
                                 " with different values (" + have->dump() + " and " + it.value().dump() + ")",
                             "Make both manifests (<plugin>/ios/plugin.json) agree, or drop the entitlement from the plugin that does not need it."};
            }
        }
    }
    return out;
}

std::string info_plist_entries(const Json& entries) {
    std::string s;
    for (auto it = entries.begin(); it != entries.end(); ++it) {
        s += "\t<key>" + xml_text(it.key()) + "</key>\n";
        plist_value(s, it.value(), 1);
    }
    return s;
}

std::string entitlements_plist(const Json& entitlements) {
    return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
           "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
           "<plist version=\"1.0\">\n<dict>\n" +
           info_plist_entries(entitlements) + "</dict>\n</plist>\n";
}

}  // namespace fa
