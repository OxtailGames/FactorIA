// What a release export of a game with ads needs (docs/PLATFORM.md, "Ads"): the AdMob app id and ad units in factoria.json, not
// Google's samples. `factoria validate` and the Android export both ask here; the export also reads the app id and the audience to
// write them into the manifest (platforms/android/app/build.gradle, manifest placeholders).
#pragma once

#include <string>
#include <vector>

namespace fa {

// Google's sample AdMob ids (developers.google.com/admob/android/test-ads): they show test ads and earn nothing.
inline constexpr const char* kAdmobSampleAppId = "ca-app-pub-3940256099942544~3347511713";
inline constexpr const char* kAdmobSampleRewardedUnit = "ca-app-pub-3940256099942544/5224354917";

// How the Android export fills the AdMob plugin's manifest placeholders. A development export (no --release) always carries
// Google's sample app id and runs in test mode; a release export carries platform.ads.appIds.android, or the sample id when the
// catalog has none (the Mobile Ads SDK stops an app that has no app id at start).
struct AdsExportSettings {
    std::string appId;      // for the manifest
    bool test = true;       // factoria.ads.test: the plugin loads Google's test ads whatever the catalog says
    std::string audience;   // platform.ads.audience: "general", "children" or "mixed"
};
AdsExportSettings ads_export_settings(const std::string& projectDir, bool release);

struct AdsIssue {
    std::string pointer;  // in factoria.json
    std::string message;
    std::string hint;
};

// The problems of the ads setup of the game: with the admob plugin declared for Android (or named by platform.ads.backend), the
// sample or missing app id and the placements without an AdMob ad unit (a release export would show test ads or none); and, for a
// game of "mixed" audience, that nothing calls platform.ads.setUnderAge.
std::vector<AdsIssue> check_ads(const std::string& projectDir);

}  // namespace fa
