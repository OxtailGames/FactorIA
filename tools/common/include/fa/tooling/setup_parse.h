// Readers of the listings `factoria setup` downloads from: Google's Android SDK repository (XML), the Adoptium API
// (JSON), GitHub releases (JSON) and Kitware's checksum file. Pure functions over text, so they are tested without a
// network (tools/common/tests/setup_parse_test.cpp). The XML has no library here: it is scanned for the few elements
// that matter.
//
// Every URL that comes out of a listing must start with one of the official download prefixes
// (is_trusted_download_url): a listing that points elsewhere is refused instead of followed.
#pragma once

#include <cstdint>
#include <map>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/tooling/setup.h"

namespace fa {

inline constexpr const char* kSetupReleaseRepo = "OxtailGames/FactorIA";
inline constexpr const char* kSdkRepositoryUrl = "https://dl.google.com/android/repository/repository2-3.xml";
inline constexpr const char* kSdkDownloadBase = "https://dl.google.com/android/repository/";

// True for the official places downloads come from: https://github.com/adoptium/, https://dl.google.com/android/repository/,
// https://github.com/<kSetupReleaseRepo>/releases/download/ and https://github.com/Kitware/CMake/releases/download/.
bool is_trusted_download_url(const std::string& url);

// ---- Android SDK repository (repository2-3.xml) ----------------------------------------------------------------

struct SdkArchive {
    std::string url;            // absolute (kSdkDownloadBase + the relative <url> of the XML)
    std::string checksumType;   // "sha1"
    std::string checksum;       // hex
    std::uint64_t size = 0;     // bytes
    std::string hostOs;         // "macosx" | "windows" | "linux" as the XML says
    std::string hostArch;       // "aarch64" | "x64" | "" (any)
};

struct SdkRepositoryInfo {
    std::string cmdlineToolsRevision;  // "23.0"
    SdkArchive cmdlineTools;           // the archive of `cmdline-tools;latest` for the host
    SetupLicense license;              // the android-sdk-license text
};

// `hostOs` is "macos" | "windows" | "linux", `hostArch` "aarch64" | "x64". The Error says what the listing lacks (a new
// layout of the XML, or no archive for this OS and CPU).
Result<SdkRepositoryInfo> parse_sdk_repository(std::string_view xml, const std::string& hostOs, const std::string& hostArch);

// Replaces &amp; &lt; &gt; &quot; &apos; and numeric references.
std::string decode_xml_entities(std::string_view text);

// ---- Eclipse Temurin (Adoptium API) ------------------------------------------------------------------------------

struct JdkDownload {
    std::string name;       // "OpenJDK21U-jdk_aarch64_mac_hotspot_21.0.12.1_1.tar.gz"
    std::string url;
    std::string sha256;
    std::string release;    // "jdk-21.0.12.1+1"
    std::string version;    // "21.0.12.1+1-LTS"
    std::uint64_t size = 0;
};

// The reply of https://api.adoptium.net/v3/assets/latest/21/hotspot?os=..&architecture=..&image_type=jdk&vendor=eclipse:
// the first entry that has a .tar.gz or .zip package.
Result<JdkDownload> parse_adoptium_assets(const Json& reply);

// ---- GitHub releases ------------------------------------------------------------------------------------------------

struct ReleaseAsset {
    std::string name;
    std::string url;     // browser_download_url
    std::string sha256;  // from "digest": "sha256:..."; empty when GitHub gave none
    std::uint64_t size = 0;
};

struct ReleaseInfo {
    std::string tag;  // "v0.1.3"
    std::vector<ReleaseAsset> assets;
    const ReleaseAsset* find(const std::string& name) const;
};

// The reply of /repos/<repo>/releases/tags/<tag> or /releases/latest.
Result<ReleaseInfo> parse_github_release(const Json& reply, const std::string& repo = kSetupReleaseRepo);

// ---- Kitware's cmake-<version>-SHA-256.txt ---------------------------------------------------------------------------

// "<hex>  <file name>" lines -> file name -> hex.
std::map<std::string, std::string> parse_sha256_sums(std::string_view text);

// The numbers of `cmake --version` output ("cmake version 3.31.6" -> {3,31,6}); empty when it is not CMake's.
std::vector<int> parse_cmake_version(std::string_view output);
// {3,31,6} >= "3.24".
bool version_at_least(const std::vector<int>& version, std::string_view minimum);

}  // namespace fa
