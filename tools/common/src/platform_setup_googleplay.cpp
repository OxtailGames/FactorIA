// platform.add_backend {"backend": "googleplay"}: the Google Play backend (docs/PLATFORM.md, "Google Play"). It creates the plugin
// from platforms/plugins/googleplay (a C bridge plus a Gradle module in Java), builds the bridge for arm64-v8a and x86_64 with the
// Android SDK's NDK, CMake and Ninja, writes the Play Games project id into the module's games-ids.xml, and lists what only a
// person can do in Play Console. The plugin holds no Google code: Gradle fetches Billing, Play Games and Play Integrity when the
// game is exported (platforms/plugins/googleplay/README.md).
#include <algorithm>
#include <cctype>
#include <filesystem>
#include <fstream>
#include <functional>
#include <iterator>
#include <optional>

#include "fa/core/strings.h"
#include "fa/runtime/project.h"
#include "fa/services/platform.h"
#include "fa/tooling/export_settings.h"
#include "fa/tooling/setup.h"
#include "platform_setup.h"
#include "setup_internal.h"
#include "util.h"

namespace fa::platform_setup {

namespace stdfs = std::filesystem;

namespace {

const char* const kIdsFile = "android/src/main/res/values/games-ids.xml";
const char* const kIdName = "game_services_project_id";

using setup_detail::is_dir;
using setup_detail::is_file;

std::string read_all(const stdfs::path& file) { return tooling_detail::read_file(file).value_or(""); }

// ---- the project id in games-ids.xml ----------------------------------------------------------------------------------------

// The text between <string name="game_services_project_id" ...> and </string>; npos in `begin` when the file has no such string.
struct IdSpan {
    std::size_t begin = std::string::npos, end = std::string::npos;
};
IdSpan find_id(const std::string& xml) {
    IdSpan span;
    const std::size_t name = xml.find(std::string("name=\"") + kIdName + "\"");
    if (name == std::string::npos) return span;
    const std::size_t open = xml.find('>', name);
    const std::size_t close = open == std::string::npos ? open : xml.find("</string>", open);
    if (close == std::string::npos) return span;
    span.begin = open + 1;
    span.end = close;
    return span;
}

std::string read_project_id(const stdfs::path& file) {
    const std::string xml = read_all(file);
    const IdSpan span = find_id(xml);
    return span.begin == std::string::npos ? std::string() : std::string(trim(std::string_view(xml).substr(span.begin, span.end - span.begin)));
}

// Play Console shows the project id as a number of 10 to 13 digits ("123456789012"); anything else is a typo.
std::string parse_project_id(const Json& v) {
    std::string s;
    if (v.is_string()) s = v.get<std::string>();
    else if (v.is_number_integer() || v.is_number_unsigned()) s = std::to_string(v.get<long long>());
    else throw CommandError("invalid_argument", "playGamesId must be the project id as a string of digits (or \"\" to turn Play Games off)", {});
    if (!s.empty() && (s.size() > 20 || !std::all_of(s.begin(), s.end(), [](unsigned char c) { return std::isdigit(c) != 0; })))
        throw CommandError("invalid_argument", "playGamesId '" + s + "' is not a Play Games Services project id: it is a number",
                           "Play Console > Play Games Services > Setup and management > Configuration shows the project id (digits only, "
                           "e.g. 123456789012). It is not the package name, the Google Cloud project id or an achievement id (CgkI...).");
    return s;
}

void write_project_id(const stdfs::path& file, const std::string& id) {
    std::string xml = read_all(file);
    const IdSpan span = find_id(xml);
    if (span.begin == std::string::npos)
        throw CommandError("failed", file.generic_string() + " has no <string name=\"" + kIdName + "\"> to put the project id in",
                           "Restore it from platforms/plugins/googleplay in the engine, or add <string name=\"" + std::string(kIdName) +
                               "\" translatable=\"false\">" + id + "</string> inside <resources>.");
    xml.replace(span.begin, span.end - span.begin, id);
    std::ofstream out(file, std::ios::binary | std::ios::trunc);
    out << xml;
    if (!out)
        throw CommandError("failed", "cannot write " + file.generic_string(), "Check that the file is not read-only and the disk has room.");
}

// ---- the Android SDK's NDK, CMake and Ninja ---------------------------------------------------------------------------------

// Google's product-id rules: lowercase letters, digits, underscores and periods, starting with a letter or digit, up to 40 characters.
bool valid_product_id(const std::string& id) {
    if (id.empty() || id.size() > 40) return false;
    if (!(std::islower(static_cast<unsigned char>(id[0])) || std::isdigit(static_cast<unsigned char>(id[0])))) return false;
    return std::all_of(id.begin(), id.end(), [](unsigned char c) { return std::islower(c) || std::isdigit(c) || c == '_' || c == '.'; });
}

}  // namespace

Backend googleplay_backend() {
    Backend b;
    b.name = "googleplay";
    b.summary = "the Google Play Billing, Play Games Services and Play Integrity plugin for Android (a C bridge and a Java module; it builds with the "
                "Android SDK's NDK).";
    b.properties = Json::object(
        {{"playGamesId",
          Json::object({{"type", Json::array({"string", "integer"})},
                        {"description", "googleplay: the Play Games Services project id (digits: Play Console > Play Games Services > Setup and "
                                        "management > Configuration), written to android/src/main/res/values/games-ids.xml. Without it the backend offers "
                                        "purchases, the store page and Play Integrity, and no achievements, leaderboards or cloud saves. Kept as it is when "
                                        "not passed; \"\" turns Play Games off. Export again after changing it."}})},
         {"googleplayBuild",
          Json::object({{"type", "boolean"},
                        {"default", true},
                        {"description", "googleplay: false only writes the plugin and declares it, without building (any computer); build it later "
                                        "where the Android NDK is installed."}})}});
    b.run = [](Context& ctx) {
        const bool build = !ctx.args.contains("googleplayBuild") || !ctx.args["googleplayBuild"].is_boolean() || ctx.args["googleplayBuild"].get<bool>();
        std::optional<std::string> wantedId;
        if (ctx.args.contains("playGamesId") && !ctx.args["playGamesId"].is_null()) wantedId = parse_project_id(ctx.args["playGamesId"]);

        // Find the toolchain before writing anything, so a computer without it changes nothing (and the error says what to do).
        NdkToolchain tc;
        if (build) tc = find_ndk_toolchain(ctx.androidSearch ? *ctx.androidSearch : default_android_toolchain_search(), "googleplay", "the Google Play plugin");

        const std::string folder = ctx.ensure_plugin({"android"});

        // The Play Games project id.
        const stdfs::path idsFile = stdfs::path(folder) / kIdsFile;
        if (wantedId) {
            if (!is_file(idsFile) && !ctx.dryRun)
                throw CommandError("not_found", idsFile.generic_string() + " does not exist, so the project id has nowhere to go",
                                   "The plugin in " + folder + " is not made from the googleplay template. Copy platforms/plugins/googleplay from the "
                                   "engine over it, or remove the plugin from factoria.json and run platform.add_backend again.");
            if (is_file(idsFile) && read_project_id(idsFile) == *wantedId) {
                ctx.done.push_back("kept the Play Games project id " + (wantedId->empty() ? std::string("(none)") : *wantedId) + " in " + idsFile.generic_string());
            } else {
                if (!ctx.dryRun) write_project_id(idsFile, *wantedId);
                ctx.wrote(idsFile.generic_string());
                const std::string would = ctx.dryRun ? "would " : "";
                ctx.done.push_back(wantedId->empty() ? std::string(ctx.dryRun ? "would turn Play Games off (empty" : "turned Play Games off (emptied") + " the project id in " + idsFile.generic_string() + ")"
                                                      : would + "set the Play Games project id " + *wantedId + " in " + idsFile.generic_string());
            }
        }
        const std::string gamesId = is_file(idsFile) ? read_project_id(idsFile) : std::string();
        ctx.extra["playGamesId"] = gamesId;

        // The C bridge for each ABI.
        if (build) build_android_abis(ctx, tc, folder);
        else ctx.done.push_back("did not build (googleplayBuild is false): see the plugin's README.md in " + folder + " for the NDK commands");

        // What the developer does by hand, with the ids of the game's own catalog.
        std::string packageName = "com.example.game";
        if (auto project = load_project(ctx.projectDir); project.ok()) packageName = project->id;
        std::vector<std::string> products, badProducts, achievements, leaderboards, missingIds;
        if (auto file = load_json_file(ctx.projectDir + "/" + kProjectFileName); file.ok() && file->is_object() && file->contains("platform")) {
            const PlatformCatalog catalog = parse_platform_catalog((*file)["platform"]).catalog;
            for (const PlatformProduct& p : catalog.products) {
                products.push_back(p.store_id("googleplay"));
                if (!valid_product_id(p.store_id("googleplay"))) badProducts.push_back(p.store_id("googleplay"));
            }
            for (const PlatformAchievement& a : catalog.achievements) {
                achievements.push_back(a.store_id("googleplay"));
                if (!a.ids.count("googleplay")) missingIds.push_back("achievement " + a.id);
            }
            for (const PlatformLeaderboard& l : catalog.leaderboards) {
                leaderboards.push_back(l.store_id("googleplay"));
                if (!l.ids.count("googleplay")) missingIds.push_back("leaderboard " + l.id);
            }
        }

        ctx.nextSteps.push_back(
            "Play Console: create the app with the package name " + packageName + " (factoria.json \"id\"), and upload a signed release build "
            "(`factoria export --platform android --format aab`, signed with your upload key) to a testing track: internal testing is enough. "
            "Billing and Play Integrity answer only for an app Play knows. Add your Google account as a license tester (Settings > License testing) and "
            "install the app from the track's opt-in link, not with adb.");
        if (products.empty()) {
            ctx.nextSteps.push_back("Products: declare them in factoria.json's \"platform\" section first (docs/PLATFORM.md), then create each in Play Console "
                                    "(Monetize with Play > Products) with the same id.");
        } else {
            ctx.nextSteps.push_back("Products: create " + quoted_list(products) + " in Play Console (Monetize with Play > Products: one-time products, or "
                                    "subscriptions with a base plan), each with exactly that id (set platform.products[].ids.googleplay to use another) and "
                                    "make it active.");
            if (!badProducts.empty())
                ctx.nextSteps.push_back("Google's product-id rules (lowercase letters, digits, _ and ., starting with a letter or digit, at most 40 characters) "
                                        "reject " + quoted_list(badProducts) + ": set platform.products[].ids.googleplay to a valid id for each.");
        }
        ctx.nextSteps.push_back(
            std::string("Play Games Services (achievements, leaderboards, cloud saves): in Play Console > Play Games Services > Setup and management, create the "
                        "project and add an Android credential for ") + packageName + " with the SHA-1 of the key your build is signed with (the upload key for "
            "adb installs and the Play App Signing key for builds from Play), turn Saved Games on for cloud saves, and add yourself as a tester while the project "
            "is unpublished. " +
            (gamesId.empty() ? "Then run platform.add_backend {\"backend\":\"googleplay\",\"playGamesId\":\"<the project id>\"} (the project id is the number "
                               "on the Configuration page) and export again: Play Games stays off until then."
                             : "The project id " + gamesId + " is set already."));
        if (!achievements.empty() || !leaderboards.empty()) {
            std::string text = "Create ";
            if (!achievements.empty()) text += "the achievements " + quoted_list(achievements);
            if (!achievements.empty() && !leaderboards.empty()) text += " and ";
            if (!leaderboards.empty()) text += "the leaderboards " + quoted_list(leaderboards);
            text += " in the Play Games Services project (Achievements / Leaderboards; make a leaderboard's sort order match the catalog's \"order\"). Play "
                    "generates their ids (they start with CgkI): copy each into platform.achievements[].ids.googleplay or platform.leaderboards[].ids.googleplay.";
            if (!missingIds.empty()) text += " Without it, the " + join(missingIds, ", ") + " use the catalog id, which Play never accepts.";
            ctx.nextSteps.push_back(text);
        }
        ctx.nextSteps.push_back("Play Integrity (platform.integrity): link a Google Cloud project in Play Console > Test and release > App integrity, and decode "
                                "the tokens on your server with Google's decodeIntegrityToken (never trust a token on the device).");
        ctx.nextSteps.push_back("Then `factoria export --platform android`: Gradle adds Billing, Play Games and Play Integrity from Google's Maven repository. In "
                                "a running game the command googleplay.status (fa.call) lists what the device lacks. Details and what each method does: "
                                "docs/PLATFORM.md, section Google Play.");
    };
    return b;
}

}  // namespace fa::platform_setup
