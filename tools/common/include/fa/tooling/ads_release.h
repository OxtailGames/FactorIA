// What a release export of a game with ads needs (docs/PLATFORM.md, "Ads"): the AdMob app id and ad units in factoria.json, not
// Google's samples. `factoria validate` and the Android and iOS exports ask here; the exports also read the app id and the audience to
// write them into the manifest (platforms/android/app/build.gradle, manifest placeholders) or the Info.plist (platforms/ios).
#pragma once

#include <map>
#include <string>
#include <vector>

namespace fa {

// Google's sample AdMob ids (developers.google.com/admob/android/test-ads, .../ios/test-ads): they show test ads and earn nothing.
// The Android and iOS samples are different apps.
inline constexpr const char* kAdmobSampleAppId = "ca-app-pub-3940256099942544~3347511713";
inline constexpr const char* kAdmobSampleRewardedUnit = "ca-app-pub-3940256099942544/5224354917";
inline constexpr const char* kAdmobSampleAppIdIos = "ca-app-pub-3940256099942544~1458002511";
inline constexpr const char* kAdmobSampleRewardedUnitIos = "ca-app-pub-3940256099942544/1712485313";

// The sentence of the "Allow tracking" sheet (NSUserTrackingUsageDescription) when the catalog gives none.
inline constexpr const char* kDefaultTrackingDescription = "This identifier will be used to deliver personalized ads to you.";

// How the Android export fills the AdMob plugin's manifest placeholders. A development export (no --release) always carries
// Google's sample app id and runs in test mode; a release export carries platform.ads.appIds.android, or the sample id when the
// catalog has none (the Mobile Ads SDK stops an app that has no app id at start).
struct AdsExportSettings {
    std::string appId;      // for the manifest
    bool test = true;       // factoria.ads.test: the plugin loads Google's test ads whatever the catalog says
    std::string audience;   // platform.ads.audience: "general", "children" or "mixed"
};
AdsExportSettings ads_export_settings(const std::string& projectDir, bool release);

// What the iOS export writes into the app's Info.plist for the ads plugin; `present` is false when the game has no ads plugin for
// iOS. Same rule for the ids as on Android: a development export carries Google's iOS sample app id.
struct AdsIosSettings {
    bool present = false;          // the game has the admob plugin (or the one platform.ads.backend names) declared for iOS
    std::string appId;             // GADApplicationIdentifier
    bool test = true;              // FactoriaAdsTest
    std::string audience;          // FactoriaAdsAudience
    bool trackingPrompt = false;   // platform.ads.trackingPrompt: NSUserTrackingUsageDescription is written and the plugin asks
    std::string trackingDescription;  // the sentence in the default language
    // The sentence per language of the game (localization.languages), when platform.ads.trackingDescriptionKey is set and the game
    // is localized: the export writes <tag>.lproj/InfoPlist.strings from it. Empty otherwise.
    std::map<std::string, std::string> trackingDescriptions;
};
AdsIosSettings ads_ios_settings(const std::string& projectDir, bool release);

struct AdsIssue {
    std::string pointer;  // in factoria.json
    std::string message;
    std::string hint;
    std::string platform;  // "android" or "ios" for a problem of one platform's setup, "" for the rest
};

// The problems of the ads setup of the game: with the admob plugin declared for Android or iOS (or named by platform.ads.backend), the
// sample or missing app id and the placements without an AdMob ad unit (a release export would show test ads or none); the tracking
// prompt on a game without an iOS ads plugin; and, for a game of "mixed" audience, that nothing calls platform.ads.setUnderAge.
// `platform` ("android", "ios") keeps only the problems that matter to an export for it (plus the ones of no platform).
std::vector<AdsIssue> check_ads(const std::string& projectDir, const std::string& platform = {});

}  // namespace fa
