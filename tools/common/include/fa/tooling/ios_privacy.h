// The privacy manifest of an iOS export: PrivacyInfo.xcprivacy, which App Store Connect requires in every app that uses a
// "required reason" API or collects data (docs/MOBILE.md, "Privacy manifest"). The engine declares the APIs it really calls;
// export.ios.privacy of factoria.json adds what the game and its plugins do on top. Text only: it works on every host.
#pragma once

#include <string>
#include <vector>

#include "fa/tooling/export_settings.h"

namespace fa {

// Apple's required-reason API categories and the reason codes each one accepts (developer.apple.com, "Describing use of
// required reason API"). `category` has no NSPrivacyAccessedAPICategory prefix.
struct IosPrivacyApiCategory {
    std::string category;                // "FileTimestamp"
    std::vector<std::string> reasons;    // {"DDA9.1", "C617.1", "3B52.1", "0A2A.1"}
};
const std::vector<IosPrivacyApiCategory>& ios_privacy_api_categories();

// The data types of NSPrivacyCollectedDataTypes ("PurchaseHistory"...) and the purposes ("AppFunctionality"...), without prefix.
const std::vector<std::string>& ios_privacy_data_types();
const std::vector<std::string>& ios_privacy_purposes();

// The required-reason APIs the engine and the player call on iOS, with the reason each one is declared for:
//   FileTimestamp  C617.1  file size and time stamps of the game's files in the app (hot reload checks, file_size, exists)
//   SystemBootTime 35F9.1  the monotonic clock of the frame loop, physics timing and the script runtime
// Plugins that call more (disk space, UserDefaults...) add them in export.ios.privacy.accessedApis.
const std::vector<IosPrivacyApi>& ios_engine_privacy_apis();

// The text of PrivacyInfo.xcprivacy: the engine's APIs merged with settings.accessedApis (reasons of a category united, no
// duplicates), NSPrivacyTracking and its domains, and the collected data types.
std::string ios_privacy_manifest(const IosPrivacySettings& settings);

}  // namespace fa
