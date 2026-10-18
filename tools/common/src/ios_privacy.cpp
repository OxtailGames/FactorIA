#include "fa/tooling/ios_privacy.h"

#include <algorithm>

namespace fa {

const std::vector<IosPrivacyApiCategory>& ios_privacy_api_categories() {
    static const std::vector<IosPrivacyApiCategory> kCategories = {
        {"FileTimestamp", {"DDA9.1", "C617.1", "3B52.1", "0A2A.1"}},
        {"SystemBootTime", {"35F9.1", "8FFB.1", "3D61.1"}},
        {"DiskSpace", {"E174.1", "85F4.1", "7D9E.1", "B728.1"}},
        {"UserDefaults", {"CA92.1", "1C8F.1", "C56D.1", "AC6B.1"}},
        {"ActiveKeyboards", {"3EC4.1", "54BD.1"}},
    };
    return kCategories;
}

const std::vector<std::string>& ios_privacy_data_types() {
    static const std::vector<std::string> kTypes = {
        "Name", "EmailAddress", "PhoneNumber", "PhysicalAddress", "OtherUserContactInfo", "Health", "Fitness", "PaymentInfo",
        "CreditInfo", "OtherFinancialInfo", "PreciseLocation", "CoarseLocation", "SensitiveInfo", "Contacts", "EmailsOrTextMessages",
        "PhotosOrVideos", "AudioData", "GameplayContent", "CustomerSupport", "OtherUserContent", "BrowsingHistory", "SearchHistory",
        "UserID", "DeviceID", "PurchaseHistory", "ProductInteraction", "AdvertisingData", "OtherUsageData", "CrashData",
        "PerformanceData", "OtherDiagnosticData", "EnvironmentScanning", "Hands", "Head", "OtherDataTypes"};
    return kTypes;
}

const std::vector<std::string>& ios_privacy_purposes() {
    static const std::vector<std::string> kPurposes = {"ThirdPartyAdvertising", "DeveloperAdvertising", "Analytics",
                                                       "ProductPersonalization", "AppFunctionality", "Other"};
    return kPurposes;
}

const std::vector<IosPrivacyApi>& ios_engine_privacy_apis() {
    static const std::vector<IosPrivacyApi> kApis = {
        {"FileTimestamp", {"C617.1"}},
        {"SystemBootTime", {"35F9.1"}},
    };
    return kApis;
}

namespace {

std::string xml_text(const std::string& s) {
    std::string out;
    for (char c : s) {
        if (c == '&') out += "&amp;";
        else if (c == '<') out += "&lt;";
        else if (c == '>') out += "&gt;";
        else out += c;
    }
    return out;
}

std::string strings_array(const std::vector<std::string>& values, const std::string& tabs, const std::string& prefix = {}) {
    if (values.empty()) return tabs + "<array/>\n";
    std::string s = tabs + "<array>\n";
    for (const std::string& v : values) s += tabs + "\t<string>" + xml_text(prefix + v) + "</string>\n";
    return s + tabs + "</array>\n";
}

const char* boolean(bool b) { return b ? "<true/>" : "<false/>"; }

}  // namespace

std::string ios_privacy_manifest(const IosPrivacySettings& settings) {
    // The engine's categories first, then the game's own; the reasons of a category are united.
    std::vector<IosPrivacyApi> apis = ios_engine_privacy_apis();
    for (const IosPrivacyApi& extra : settings.accessedApis) {
        auto it = std::find_if(apis.begin(), apis.end(), [&](const IosPrivacyApi& a) { return a.category == extra.category; });
        if (it == apis.end()) {
            apis.push_back(extra);
            continue;
        }
        for (const std::string& reason : extra.reasons)
            if (std::find(it->reasons.begin(), it->reasons.end(), reason) == it->reasons.end()) it->reasons.push_back(reason);
    }
    std::string s =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
        "<!-- Written by the iOS export of factoria. Add to it with export.ios.privacy in factoria.json (docs/MOBILE.md). -->\n"
        "<plist version=\"1.0\">\n<dict>\n";
    s += std::string("\t<key>NSPrivacyTracking</key>\n\t") + boolean(settings.tracking) + "\n";
    s += "\t<key>NSPrivacyTrackingDomains</key>\n" + strings_array(settings.trackingDomains, "\t");
    s += "\t<key>NSPrivacyCollectedDataTypes</key>\n";
    if (settings.collectedData.empty()) {
        s += "\t<array/>\n";
    } else {
        s += "\t<array>\n";
        for (const IosPrivacyCollectedData& d : settings.collectedData) {
            s += "\t\t<dict>\n";
            s += "\t\t\t<key>NSPrivacyCollectedDataType</key>\n\t\t\t<string>NSPrivacyCollectedDataType" + xml_text(d.type) + "</string>\n";
            s += std::string("\t\t\t<key>NSPrivacyCollectedDataTypeLinked</key>\n\t\t\t") + boolean(d.linked) + "\n";
            s += std::string("\t\t\t<key>NSPrivacyCollectedDataTypeTracking</key>\n\t\t\t") + boolean(d.tracking) + "\n";
            s += "\t\t\t<key>NSPrivacyCollectedDataTypePurposes</key>\n" + strings_array(d.purposes, "\t\t\t", "NSPrivacyCollectedDataTypePurpose");
            s += "\t\t</dict>\n";
        }
        s += "\t</array>\n";
    }
    s += "\t<key>NSPrivacyAccessedAPITypes</key>\n\t<array>\n";
    for (const IosPrivacyApi& api : apis) {
        s += "\t\t<dict>\n";
        s += "\t\t\t<key>NSPrivacyAccessedAPIType</key>\n\t\t\t<string>NSPrivacyAccessedAPICategory" + xml_text(api.category) + "</string>\n";
        s += "\t\t\t<key>NSPrivacyAccessedAPITypeReasons</key>\n" + strings_array(api.reasons, "\t\t\t");
        s += "\t\t</dict>\n";
    }
    s += "\t</array>\n</dict>\n</plist>\n";
    return s;
}

}  // namespace fa
