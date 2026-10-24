// platform.add_backend {"backend": "admob"}: the ads backend for Android (docs/PLATFORM.md, "Ads"). It creates the plugin from
// platforms/plugins/admob (a C bridge plus a Gradle module in Java), builds the bridge for arm64-v8a and x86_64 with the Android
// SDK's NDK, CMake and Ninja, and lists what only a person can do in the AdMob console. The plugin holds no Google code: Gradle
// fetches the Mobile Ads SDK and Google's consent library (UMP) when the game is exported (platforms/plugins/admob/README.md).
#include <filesystem>

#include "fa/core/strings.h"
#include "fa/runtime/project.h"
#include "fa/services/platform.h"
#include "fa/tooling/setup.h"
#include "platform_setup.h"
#include "setup_internal.h"
#include "util.h"

namespace fa::platform_setup {

Backend admob_backend() {
    Backend b;
    b.name = "admob";
    b.summary = "the AdMob ads plugin for Android: Google's consent form (UMP) and rewarded ads. It offers only the \"ads\" service, so it works next to "
                "the store backend of the game (a C bridge and a Java module; it builds with the Android SDK's NDK).";
    b.properties = Json::object(
        {{"admobBuild",
          Json::object({{"type", "boolean"},
                        {"default", true},
                        {"description", "admob: false only writes the plugin and declares it, without building (any computer); build it later "
                                        "where the Android NDK is installed."}})}});
    b.run = [](Context& ctx) {
        const bool build = !ctx.args.contains("admobBuild") || !ctx.args["admobBuild"].is_boolean() || ctx.args["admobBuild"].get<bool>();

        // Find the toolchain before writing anything, so a computer without it changes nothing (and the error says what to do).
        NdkToolchain tc;
        if (build) tc = find_ndk_toolchain(ctx.androidSearch ? *ctx.androidSearch : default_android_toolchain_search(), "admob", "the AdMob plugin");

        const std::string folder = ctx.ensure_plugin({"android"});

        if (build) build_android_abis(ctx, tc, folder);
        else ctx.done.push_back("did not build (admobBuild is false): see the plugin's README.md in " + folder + " for the NDK commands");

        // What the developer does by hand, with the ids of the game's own catalog.
        std::string packageName = "com.example.game";
        if (auto project = load_project(ctx.projectDir); project.ok()) packageName = project->id;
        std::vector<std::string> placements, missingUnits;
        std::string appId, audience = "general";
        if (auto file = load_json_file(ctx.projectDir + "/" + kProjectFileName); file.ok() && file->is_object() && file->contains("platform")) {
            const PlatformCatalog catalog = parse_platform_catalog((*file)["platform"]).catalog;
            for (const PlatformPlacement& p : catalog.placements) {
                placements.push_back(p.id);
                if (!p.ids.count("admob")) missingUnits.push_back(p.id);
            }
            if (auto it = catalog.adsAppIds.find("android"); it != catalog.adsAppIds.end()) appId = it->second;
            audience = catalog.adsAudience;
        }

        ctx.extra["appId"] = appId;
        ctx.extra["audience"] = audience;

        ctx.nextSteps.push_back(
            "Nothing else is needed to see ads in a development export: `factoria export --platform android` (without --release) always uses Google's "
            "test app id and test rewarded ad, which show test ads and earn nothing. Try that first (docs/PLATFORM.md, \"Ads\", has the emulator steps).");
        ctx.nextSteps.push_back(
            "AdMob console (admob.google.com): add the app " + packageName + " (Apps > Add app; if it is not on Google Play yet, add it manually) and copy its "
            "app id (ca-app-pub-<16 digits>~<10 digits>, App settings) into factoria.json: \"platform\": {\"ads\": {\"appIds\": {\"android\": \"<the app id>\"}}}." +
            (appId.empty() ? std::string(" It is not set yet: a release export without it would stop at start.")
                           : " The catalog has " + appId + " already."));
        if (placements.empty()) {
            ctx.nextSteps.push_back("Ad units: declare the places the game shows ads in factoria.json's \"platform\".\"ads\".\"placements\" first (docs/PLATFORM.md), "
                                    "then create a rewarded ad unit for each in AdMob (Ad units > Add ad unit > Rewarded).");
        } else {
            ctx.nextSteps.push_back("Ad units: create a rewarded ad unit in AdMob (Ad units > Add ad unit > Rewarded) for each placement (" + quoted_list(placements) +
                                    ") and copy its id (ca-app-pub-<16 digits>/<10 digits>) into platform.ads.placements[].ids.admob." +
                                    (missingUnits.empty() ? std::string()
                                                          : " The placements " + quoted_list(missingUnits) + " have no ids.admob yet: a release build cannot load an ad for them."));
        }
        ctx.nextSteps.push_back(
            "Consent: in AdMob > Privacy & messaging, create the GDPR message (European regulations) and, if you sell in the United States, the US states "
            "message, and publish them; without a published message the consent library has no form to show. The audience of the game is \"" + audience +
            "\" (platform.ads.audience): \"children\" for a game made for children, \"mixed\" for children and adults (the menu kit's ageGate part asks the age: "
            "`project.add_menu_kit {\"parts\":[\"ageGate\"]}`). Docs/PLATFORM.md, \"Children and consent\", says what each one does.");
        ctx.nextSteps.push_back("Then `factoria export --platform android`: Gradle adds the Mobile Ads SDK and the consent library from Google's Maven repository. "
                                "In a running game the command admob.status (fa.call) lists what the device lacks. Details and what each method does: "
                                "docs/PLATFORM.md, section Ads. Before a release, `factoria validate` warns about the sample app id or a missing app id.");
    };
    return b;
}

}  // namespace fa::platform_setup
