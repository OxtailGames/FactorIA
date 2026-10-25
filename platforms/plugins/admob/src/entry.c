/* The Apple entry point of the {{NAME}} plugin: the ads backend of the game's `platform` API (docs/PLATFORM.md, "Ads").
 *
 *   iOS    FA_PLUGIN_INIT defines `fa_plugin_init_<name>` (the static library the app links, -DFA_PLUGIN_STATIC) and hands over to
 *          the Swift side (Ads.swift, `fa_admob_init`): Google's consent library (UMP), the App Tracking Transparency prompt and
 *          the Mobile Ads SDK have no C API.
 *   macOS  Google ships no AdMob SDK for macOS. The library only says so in the log and registers no backend, so a Mac build of
 *          the game runs without ads and `platform.has("ads")` is false.
 *
 * CMakeLists.txt passes FA_PLUGIN_NAME. This file is only compiled for Apple platforms; Android has src/plugin.c. */
#include <TargetConditionals.h>

#include "fa_plugin.h"

#if TARGET_OS_IPHONE

extern int fa_admob_init(const FaPluginApi* api);

FA_PLUGIN_INIT(FA_PLUGIN_NAME) { return fa_admob_init(api); }

#else

FA_PLUGIN_INIT(FA_PLUGIN_NAME) {
    api->log(api, 1,
             "AdMob has no SDK for macOS: this build of the game offers no ads (platform.has(\"ads\") is false). "
             "Ads work on Android and iOS.");
    return 0;
}

#endif
