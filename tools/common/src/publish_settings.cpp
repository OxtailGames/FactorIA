// The "publish" section of factoria.json: the ids of the game in the stores (never a secret). The format is described in
// docs/EXPORTING.md ("Uploading to stores") and schemas/project.schema.json; every problem names its JSON pointer, says what
// is wrong and how to fix it.
#include <algorithm>
#include <regex>

#include "fa/core/strings.h"
#include "fa/tooling/publish.h"

namespace fa {

const std::vector<std::string>& publish_stores() {
    static const std::vector<std::string> stores = {"steam", "itch", "epic", "gog"};
    return stores;
}

const std::vector<std::string>& publish_platforms() {
    static const std::vector<std::string> platforms = {"windows", "macos", "linux"};
    return platforms;
}

std::string itch_channel_for(const ItchPublishSettings& settings, const std::string& platform) {
    if (auto it = settings.channels.find(platform); it != settings.channels.end()) return it->second;
    return platform == "macos" ? "mac" : platform;
}

namespace {

std::string token(const std::string& key) {  // JSON pointer escaping
    std::string out;
    for (char c : key) out += c == '~' ? "~0" : c == '/' ? "~1" : std::string(1, c);
    return out;
}

struct Reader {
    PublishSettingsParse result;

    void error(const std::string& pointer, std::string message, std::string hint) {
        result.errors.push_back({pointer, std::move(message), std::move(hint)});
    }

    void unknown_keys(const Json& obj, const std::string& base, std::initializer_list<const char*> names) {
        unknown_keys(obj, base, std::vector<std::string>(names.begin(), names.end()));
    }
    void unknown_keys(const Json& obj, const std::string& base, const std::vector<std::string>& known) {
        for (auto it = obj.begin(); it != obj.end(); ++it) {
            if (std::find(known.begin(), known.end(), it.key()) != known.end()) continue;
            result.warnings.push_back({base + "/" + token(it.key()), "Unknown key '" + it.key() + "'; it is ignored.",
                                       did_you_mean(it.key(), known)});
        }
    }

    // The member `key` of `obj` as an object, or nullptr (absent, null, or an error was recorded).
    const Json* object(const Json& obj, const std::string& base, const char* key, const std::string& example) {
        auto it = obj.find(key);
        if (it == obj.end() || it->is_null()) return nullptr;
        if (!it->is_object()) {
            error(base + "/" + key, "expected an object, got " + describe_json_value(*it), "Write it as " + example + ".");
            return nullptr;
        }
        return &*it;
    }

    // A non-empty string without surrounding spaces.
    bool text(const Json& obj, const std::string& base, const char* key, std::string& out, const std::string& hint) {
        auto it = obj.find(key);
        if (it == obj.end() || it->is_null()) return false;
        if (!it->is_string()) {
            error(base + "/" + key, "expected a string, got " + describe_json_value(*it), hint);
            return false;
        }
        const std::string v = it->get<std::string>();
        if (trim(v).empty() || trim(v).size() != v.size()) {
            error(base + "/" + key, v.empty() ? "must not be empty" : "'" + v + "' has spaces around it", hint);
            return false;
        }
        out = v;
        return true;
    }

    // A whole number 1..4294967295 written as a number or as digits in a string (store ids are often copied as text).
    bool id(const Json& value, const std::string& pointer, std::string& out, const std::string& what) {
        long long n = 0;
        const std::string text = value.is_string() ? value.get<std::string>() : std::string();
        if (value.is_number_integer()) n = value.get<long long>();
        else if (!text.empty() && text.size() <= 10 && std::all_of(text.begin(), text.end(), [](char c) { return c >= '0' && c <= '9'; }))
            n = std::stoll(text);
        if (n < 1 || n > 4294967295LL) {
            error(pointer, "expected " + what + " (a whole number from 1), got " + describe_json_value(value),
                  "Copy it from the store's partner site as digits, e.g. 1234567.");
            return false;
        }
        out = std::to_string(n);
        return true;
    }

    // {"windows": ..., "macos": ..., "linux": ...}: every key is a platform an export can upload.
    template <class F>
    void per_platform(const Json& obj, const std::string& base, F each) {
        for (auto it = obj.begin(); it != obj.end(); ++it) {
            const std::string pointer = base + "/" + token(it.key());
            const auto& platforms = publish_platforms();
            if (std::find(platforms.begin(), platforms.end(), it.key()) != platforms.end()) {
                each(it.key(), it.value(), pointer);
            } else if (it.key() == "android" || it.key() == "ios") {
                error(pointer, "'" + it.key() + "' cannot be uploaded to these stores",
                      "publish.* uploads the desktop exports (windows, macos, linux); remove this entry.");
            } else {
                error(pointer, "'" + it.key() + "' is not a platform", did_you_mean(it.key(), platforms));
            }
        }
    }

    void steam(const Json& o, const std::string& base, SteamPublishSettings& s) {
        text(o, base, "account", s.account, "Use the name of the Steam account that uploads builds (a build account with the \"Edit App Metadata\" permission), e.g. \"mystudio_build\". Its password is never stored here: steamcmd keeps the login.");
        if (const Json* depots = object(o, base, "depots", "{\"windows\": 1234561, \"macos\": 1234562, \"linux\": 1234563}"))
            per_platform(*depots, base + "/depots", [&](const std::string& platform, const Json& v, const std::string& pointer) {
                std::string id;
                if (this->id(v, pointer, id, "a Steam depot id")) s.depots[platform] = std::stoll(id);
            });
        if (text(o, base, "branch", s.branch, "Use the name of a beta branch of your app, e.g. \"beta\" (Steamworks: App Admin > SteamPipe > Builds).") &&
            to_lower(s.branch) == "default") {
            error(base + "/branch", "Steam never sets a build live on the 'default' branch from an upload",
                  "Use a beta branch such as \"beta\" and make the build default yourself in the Steamworks partner site (App Admin > SteamPipe > Builds).");
            s.branch.clear();
        }
        unknown_keys(o, base, {"account", "depots", "branch"});
    }

    void itch(const Json& o, const std::string& base, ItchPublishSettings& s) {
        std::string game;
        if (text(o, base, "game", game, "Use \"user/game\" as in the page's address, e.g. \"mystudio/space-dodge\".")) {
            static const std::regex re("^[a-z0-9_-]+/[a-z0-9_-]+$");
            if (!std::regex_match(game, re))
                error(base + "/game", "'" + game + "' is not a user/game name",
                      "butler wants two lower-case parts joined by a slash, as in the address of your itch.io page: \"" + to_lower(game) +
                          "\" if that is it.");
            else
                s.game = game;
        }
        if (const Json* channels = object(o, base, "channels", "{\"windows\": \"windows\", \"macos\": \"mac\", \"linux\": \"linux\"}"))
            per_platform(*channels, base + "/channels", [&](const std::string& platform, const Json& v, const std::string& pointer) {
                static const std::regex re("^[a-z0-9]+(-[a-z0-9]+)*$");
                if (!v.is_string() || !std::regex_match(v.get<std::string>(), re))
                    error(pointer, "expected a channel name, got " + describe_json_value(v),
                          "Use lower-case words separated by dashes; itch.io tags the download by the words: \"windows\", \"mac\" or \"osx\", \"linux\" (e.g. \"windows-beta\").");
                else
                    s.channels[platform] = v.get<std::string>();
            });
        unknown_keys(o, base, {"game", "channels"});
    }

    void epic(const Json& o, const std::string& base, EpicPublishSettings& s) {
        const std::string hint = "Copy it from the Epic Games Dev Portal.";
        text(o, base, "organizationId", s.organizationId, hint + " The Organization ID is in the Organization settings.");
        text(o, base, "productId", s.productId, hint + " The Product ID is in the product's settings.");
        text(o, base, "clientId", s.clientId,
             hint + " Use the client under Product Settings > General > Build Patch Tool Credentials (not an SDK client). The matching secret goes in FACTORIA_EPIC_CLIENT_SECRET, never here.");
        if (const Json* artifacts = object(o, base, "artifacts", "{\"windows\": \"<artifact id>\", \"macos\": \"<artifact id>\"}"))
            per_platform(*artifacts, base + "/artifacts", [&](const std::string& platform, const Json& v, const std::string& pointer) {
                if (!v.is_string() || trim(v.get<std::string>()).empty())
                    error(pointer, "expected an artifact id, got " + describe_json_value(v), "Each platform has its own artifact: copy the Artifact ID from the Dev Portal (Artifacts and Binaries).");
                else
                    s.artifacts[platform] = v.get<std::string>();
            });
        unknown_keys(o, base, {"organizationId", "productId", "clientId", "artifacts"});
    }

    void gog(const Json& o, const std::string& base, GogPublishSettings& s) {
        if (auto it = o.find("productId"); it != o.end() && !it->is_null()) id(*it, base + "/productId", s.productId, "a GOG product id");
        if (auto it = o.find("clientId"); it != o.end() && !it->is_null()) {
            if (it->is_string() && !it->get<std::string>().empty()) s.clientId = it->get<std::string>();
            else id(*it, base + "/clientId", s.clientId, "a GALAXY client id");
        }
        if (auto it = o.find("languages"); it != o.end() && !it->is_null()) {
            const std::string hint = "Write the locale codes of the game's languages, e.g. [\"en-US\", \"fr-FR\"].";
            std::vector<std::string> languages;
            bool ok = it->is_array() && !it->empty();
            if (!ok) error(base + "/languages", "expected a non-empty array of locale codes, got " + describe_json_value(*it), hint);
            else
                for (std::size_t i = 0; i < it->size(); ++i) {
                    const Json& e = (*it)[i];
                    if (!e.is_string() || e.get<std::string>().empty()) {
                        error(base + "/languages/" + std::to_string(i), "expected a locale code, got " + describe_json_value(e), hint);
                        ok = false;
                    } else {
                        languages.push_back(e.get<std::string>());
                    }
                }
            if (ok) s.languages = std::move(languages);
        }
        unknown_keys(o, base, {"productId", "clientId", "languages"});
    }
};

}  // namespace

PublishSettingsParse parse_publish_settings(const Json& pj) {
    Reader r;
    PublishSettings& s = r.result.settings;
    if (!pj.is_object()) return r.result;
    auto it = pj.find("publish");
    if (it == pj.end() || it->is_null()) return r.result;
    if (!it->is_object()) {
        r.error("/publish", "expected an object with one entry per store, got " + describe_json_value(*it),
                "Write it as {\"itch\": {\"game\": \"user/game\"}}; stores: steam, itch, epic, gog.");
        return r.result;
    }
    const Json& pub = *it;
    r.unknown_keys(pub, "/publish", publish_stores());
    if (const Json* o = r.object(pub, "/publish", "steam", "{\"account\": \"mystudio_build\", \"depots\": {\"windows\": 1234561}}")) r.steam(*o, "/publish/steam", s.steam);
    if (const Json* o = r.object(pub, "/publish", "itch", "{\"game\": \"user/game\"}")) r.itch(*o, "/publish/itch", s.itch);
    if (const Json* o = r.object(pub, "/publish", "epic", "{\"organizationId\": \"...\", \"productId\": \"...\"}")) r.epic(*o, "/publish/epic", s.epic);
    if (const Json* o = r.object(pub, "/publish", "gog", "{\"productId\": \"1234567890\"}")) r.gog(*o, "/publish/gog", s.gog);
    return r.result;
}

}  // namespace fa
