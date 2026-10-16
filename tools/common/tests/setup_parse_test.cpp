// The readers of the listings `factoria setup` downloads from: Google's SDK repository (XML), Adoptium, GitHub releases
// and Kitware's checksums. Text in, values out: no network.
#include <doctest.h>

#include "fa/core/strings.h"
#include "fa/tooling/setup_parse.h"

using namespace fa;

namespace {

Json parse(const std::string& text) {
    auto j = parse_json(text, "test");
    REQUIRE(j.ok());
    return *j;
}

std::string with_replaced(std::string text, const std::string& from, const std::string& to) {
    REQUIRE_FALSE(from.empty());
    REQUIRE(text.find(from) != std::string::npos);
    for (std::size_t pos = 0; (pos = text.find(from, pos)) != std::string::npos; pos += to.size()) text.replace(pos, from.size(), to);
    return text;
}

// A small repository2-3.xml: an obsolete cmdline-tools;latest first (must be skipped), another package, the real one with
// the four hosts (the two Mac archives told apart by <host-arch>), and two licenses.
const char* kRepoXml = R"(<?xml version='1.0' encoding='utf-8'?>
<sdk:sdk-repository xmlns:sdk="http://schemas.android.com/sdk/android/repo/repository2/03">
  <license id="android-sdk-license" type="text">Terms and Conditions

This is the Android Software Development Kit License Agreement &amp; its "terms" (&lt;1&gt;) &#169; 2019

1. Introduction

January 16, 2019
</license>
  <license id="android-sdk-preview-license" type="text">Preview terms only.</license>
  <remotePackage obsolete="true" path="cmdline-tools;latest">
    <revision><major>1</major></revision>
    <archives><archive><complete><size>1</size><checksum type="sha1">1111111111111111111111111111111111111111</checksum><url>old.zip</url></complete><host-os>linux</host-os></archive></archives>
  </remotePackage>
  <remotePackage path="platforms;android-36">
    <archives><archive><complete><size>65878410</size><checksum type="sha1">2c1a80dd4d9f7d0e6dd336ec603d9b5c55a6f576</checksum><url>platform-36_r02.zip</url></complete></archive></archives>
  </remotePackage>
  <remotePackage path="cmdline-tools;latest">
    <type-details xsi:type="generic:genericDetailsType"/>
    <revision>
      <major>23</major>
      <minor>0</minor>
    </revision>
    <display-name>Android SDK Command-line Tools (latest)</display-name>
    <uses-license ref="android-sdk-license"/>
    <archives>
      <archive>
        <complete>
          <size>181052239</size>
          <checksum type="sha1">e025545c62a8e64c7559119566a569fb1dec5f60</checksum>
          <url>commandlinetools-linux-16111833_latest.zip</url>
        </complete>
        <host-os>linux</host-os>
      </archive>
      <archive>
        <complete>
          <size>155582504</size>
          <checksum type="sha1">112cf9618794a997ff273537d55bee02c22abffe</checksum>
          <url>commandlinetools-mac_x86_64-16111833_latest.zip</url>
        </complete>
        <host-os>macosx</host-os>
        <host-arch>x64</host-arch>
      </archive>
      <archive>
        <complete>
          <size>155384151</size>
          <checksum type="sha1">AD03DC49BFACFD52C110B14104EA548B8A07E830</checksum>
          <url>commandlinetools-mac_arm64-16111833_latest.zip</url>
        </complete>
        <host-os>macosx</host-os>
        <host-arch>aarch64</host-arch>
      </archive>
      <archive>
        <complete>
          <size>154957218</size>
          <checksum type="sha1">57d04f2d75eb8e8fffc5000a987e5de4b5a63e9d</checksum>
          <url>commandlinetools-win-16111833_latest.zip</url>
        </complete>
        <host-os>windows</host-os>
      </archive>
    </archives>
  </remotePackage>
</sdk:sdk-repository>
)";

// Only a Mac archive.
const char* kMacOnlyXml = R"(<sdk:sdk-repository>
  <license id="android-sdk-license" type="text">Terms.</license>
  <remotePackage path="cmdline-tools;latest">
    <revision><major>23</major></revision>
    <archives>
      <archive>
        <complete><size>5</size><checksum type="sha1">ad03dc49bfacfd52c110b14104ea548b8a07e830</checksum><url>mac.zip</url></complete>
        <host-os>macosx</host-os><host-arch>aarch64</host-arch>
      </archive>
    </archives>
  </remotePackage>
</sdk:sdk-repository>)";

}  // namespace

TEST_CASE("setup parse: the cmdline-tools archive of each host and the license text") {
    auto arm = parse_sdk_repository(kRepoXml, "macos", "aarch64");
    REQUIRE(arm.ok());
    CHECK(arm->cmdlineToolsRevision == "23.0");
    CHECK(arm->cmdlineTools.url == "https://dl.google.com/android/repository/commandlinetools-mac_arm64-16111833_latest.zip");
    CHECK(arm->cmdlineTools.checksumType == "sha1");
    CHECK(arm->cmdlineTools.checksum == "ad03dc49bfacfd52c110b14104ea548b8a07e830");  // lowercased
    CHECK(arm->cmdlineTools.size == 155384151);
    CHECK(arm->license.id == "android-sdk-license");
    CHECK(arm->license.title == "Android Software Development Kit License Agreement");
    CHECK(starts_with(arm->license.text, "Terms and Conditions"));
    CHECK(ends_with(arm->license.text, "January 16, 2019"));  // trimmed
    CHECK(arm->license.text.find("License Agreement & its \"terms\" (<1>) \xC2\xA9 2019") != std::string::npos);  // entities decoded
    CHECK(arm->license.text.find("Preview terms") == std::string::npos);  // the other license is not mixed in

    auto intel = parse_sdk_repository(kRepoXml, "macos", "x64");
    REQUIRE(intel.ok());
    CHECK(intel->cmdlineTools.url.find("mac_x86_64") != std::string::npos);
    auto win = parse_sdk_repository(kRepoXml, "windows", "x64");
    REQUIRE(win.ok());
    CHECK(win->cmdlineTools.url.find("commandlinetools-win-") != std::string::npos);
    CHECK(win->cmdlineTools.hostArch.empty());
    auto linuxArm = parse_sdk_repository(kRepoXml, "linux", "aarch64");  // the Linux archive is Java: any CPU
    REQUIRE(linuxArm.ok());
    CHECK(linuxArm->cmdlineTools.url.find("commandlinetools-linux-") != std::string::npos);
}

TEST_CASE("setup parse: a repository that lacks what we need says so") {
    auto none = parse_sdk_repository("<sdk:sdk-repository></sdk:sdk-repository>", "linux", "x64");
    REQUIRE_FALSE(none.ok());
    CHECK(none.error().message.find("cmdline-tools;latest") != std::string::npos);
    CHECK_FALSE(none.error().hint.empty());

    // No archive for this host: the error lists what the repository has.
    auto noWin = parse_sdk_repository(kMacOnlyXml, "windows", "x64");
    REQUIRE_FALSE(noWin.ok());
    CHECK(noWin.error().message.find("windows/x64") != std::string::npos);
    CHECK(noWin.error().message.find("macosx/aarch64") != std::string::npos);
    // A Mac archive for the other CPU is no match either.
    CHECK_FALSE(parse_sdk_repository(kMacOnlyXml, "macos", "x64").ok());
    CHECK(parse_sdk_repository(kMacOnlyXml, "macos", "aarch64").ok());

    // An address outside Google's download server is refused, not followed.
    auto refused = parse_sdk_repository(with_replaced(kRepoXml, "commandlinetools-linux-16111833_latest.zip", "https://evil.example/tools.zip"), "linux", "x64");
    REQUIRE_FALSE(refused.ok());
    CHECK(refused.error().message.find("evil.example") != std::string::npos);

    // A checksum that is not a SHA-1 is refused.
    CHECK_FALSE(parse_sdk_repository(with_replaced(kRepoXml, "e025545c62a8e64c7559119566a569fb1dec5f60", "not-a-checksum"), "linux", "x64").ok());

    // A listing without the license text is refused too: the user could not be shown what they agree to.
    auto missing = parse_sdk_repository(with_replaced(kRepoXml, "<license id=\"android-sdk-license\"", "<license id=\"other-license\""), "linux", "x64");
    REQUIRE_FALSE(missing.ok());
    CHECK(missing.error().message.find("android-sdk-license") != std::string::npos);
}

TEST_CASE("setup parse: XML entities") {
    CHECK(decode_xml_entities("a &amp; b &lt;c&gt; &quot;d&quot; &apos;e&apos;") == "a & b <c> \"d\" 'e'");
    CHECK(decode_xml_entities("&#65;&#x42;&#169;&#8364;") == "AB\xC2\xA9\xE2\x82\xAC");
    CHECK(decode_xml_entities("fish &chips; & no semicolon") == "fish &chips; & no semicolon");
}

namespace {
const char* kJdkLink =
    "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.12.1%2B1/OpenJDK21U-jdk_aarch64_mac_hotspot_21.0.12.1_1.tar.gz";
const char* kAdoptiumSample = R"([{
  "binary": {
    "architecture": "aarch64", "image_type": "jdk", "os": "mac",
    "installer": { "checksum": "575bb8d9d604821d8f350325b28a35e49bcffd7ec33727b41edc8d709537dada",
      "link": "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.12.1%2B1/OpenJDK21U-jdk_aarch64_mac_hotspot_21.0.12.1_1.pkg",
      "name": "OpenJDK21U-jdk_aarch64_mac_hotspot_21.0.12.1_1.pkg", "size": 200564448 },
    "package": { "checksum": "3623232f33a9c3baadf304480b2535f9a3cba8a58d42ecbb438ba267315d9998",
      "link": "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.12.1%2B1/OpenJDK21U-jdk_aarch64_mac_hotspot_21.0.12.1_1.tar.gz",
      "name": "OpenJDK21U-jdk_aarch64_mac_hotspot_21.0.12.1_1.tar.gz", "size": 200073404 }
  },
  "release_name": "jdk-21.0.12.1+1",
  "version": { "major": 21, "openjdk_version": "21.0.12.1+1-LTS" }
}])";
}  // namespace

TEST_CASE("setup parse: Adoptium picks the archive package") {
    auto jdk = parse_adoptium_assets(parse(kAdoptiumSample));
    REQUIRE(jdk.ok());
    CHECK(jdk->name == "OpenJDK21U-jdk_aarch64_mac_hotspot_21.0.12.1_1.tar.gz");
    CHECK(jdk->url == kJdkLink);
    CHECK(jdk->sha256 == "3623232f33a9c3baadf304480b2535f9a3cba8a58d42ecbb438ba267315d9998");
    CHECK(jdk->size == 200073404);
    CHECK(jdk->release == "jdk-21.0.12.1+1");
    CHECK(jdk->version == "21.0.12.1+1-LTS");

    auto empty = parse_adoptium_assets(parse("[]"));
    REQUIRE_FALSE(empty.ok());
    CHECK(empty.error().message.find("no Eclipse Temurin JDK 21") != std::string::npos);
    CHECK(empty.error().hint.find("adoptium.net") != std::string::npos);

    auto refused = parse_adoptium_assets(parse(with_replaced(kAdoptiumSample, kJdkLink, "https://evil.example/jdk.tar.gz")));
    REQUIRE_FALSE(refused.ok());
    CHECK(refused.error().message.find("evil.example") != std::string::npos);

    CHECK_FALSE(parse_adoptium_assets(parse(with_replaced(kAdoptiumSample, "3623232f33a9c3baadf304480b2535f9a3cba8a58d42ecbb438ba267315d9998", ""))).ok());

    // Only a .pkg installer: nothing we can unpack.
    CHECK_FALSE(parse_adoptium_assets(parse(R"([{"binary":{"package":{"checksum":"575bb8d9d604821d8f350325b28a35e49bcffd7ec33727b41edc8d709537dada","link":"https://github.com/adoptium/x/x.pkg","name":"x.pkg","size":1}}}])")).ok());
}

TEST_CASE("setup parse: a GitHub release with digests") {
    const std::string sample = R"({
      "tag_name": "v0.1.3", "name": "FactorIA v0.1.3",
      "assets": [
        { "name": "FactorIA-windows-x64.zip", "size": 12730308,
          "browser_download_url": "https://github.com/OxtailGames/FactorIA/releases/download/v0.1.3/FactorIA-windows-x64.zip",
          "digest": "sha256:7F02FCD4AE21A9B9AB66497A181BB1E176AF5190AFA690597E773E818A184985" },
        { "name": "FactorIA-linux-x64.AppImage", "size": 9144824,
          "browser_download_url": "https://github.com/OxtailGames/FactorIA/releases/download/v0.1.3/FactorIA-linux-x64.AppImage",
          "digest": null }
      ]})";
    auto rel = parse_github_release(parse(sample));
    REQUIRE(rel.ok());
    CHECK(rel->tag == "v0.1.3");
    REQUIRE(rel->assets.size() == 2);
    const ReleaseAsset* win = rel->find("FactorIA-windows-x64.zip");
    REQUIRE(win);
    CHECK(win->sha256 == "7f02fcd4ae21a9b9ab66497a181bb1e176af5190afa690597e773e818a184985");
    CHECK(win->size == 12730308);
    CHECK(win->url == "https://github.com/OxtailGames/FactorIA/releases/download/v0.1.3/FactorIA-windows-x64.zip");
    REQUIRE(rel->find("FactorIA-linux-x64.AppImage"));
    CHECK(rel->find("FactorIA-linux-x64.AppImage")->sha256.empty());  // an old release or GitHub without digests
    CHECK(rel->find("nope") == nullptr);

    auto notFound = parse_github_release(parse(R"({"message":"Not Found"})"));
    REQUIRE_FALSE(notFound.ok());
    CHECK_FALSE(notFound.error().hint.empty());

    const std::string evil = with_replaced(sample, "https://github.com/OxtailGames/", "https://github.com/someoneelse/");
    auto refused = parse_github_release(parse(evil));
    REQUIRE_FALSE(refused.ok());
    CHECK(refused.error().message.find("someoneelse") != std::string::npos);

    // A fork can be named: its own downloads are the trusted ones then.
    CHECK(parse_github_release(parse(evil), "someoneelse/FactorIA").ok());
}

TEST_CASE("setup parse: Kitware's checksum file and CMake versions") {
    const std::string a(64, 'a'), b(64, 'b'), c(64, 'c');
    const std::string sums = a + "  cmake-3.31.6-files-v1.json\n" + b + "  cmake-3.31.6-macos-universal.tar.gz\r\n" + c +
                             " *cmake-3.31.6-windows-x86_64.zip\n"
                             "not a checksum line\n"
                             "tooshort  cmake.txt\n";
    const auto table = parse_sha256_sums(sums);
    CHECK(table.size() == 3);
    CHECK(table.at("cmake-3.31.6-macos-universal.tar.gz") == b);
    CHECK(table.at("cmake-3.31.6-windows-x86_64.zip") == c);  // the "*" of binary mode is dropped
    CHECK(parse_sha256_sums("").empty());

    CHECK(parse_cmake_version("cmake version 3.31.6\n\nCMake suite maintained and supported by Kitware") == std::vector<int>{3, 31, 6});
    CHECK(parse_cmake_version("cmake version 4.4.4-rc1") == std::vector<int>{4, 4, 4});
    CHECK(parse_cmake_version("something else").empty());
    CHECK(version_at_least({3, 31, 6}, "3.24"));
    CHECK(version_at_least({3, 24}, "3.24"));
    CHECK(version_at_least({4, 0, 0}, "3.24"));
    CHECK_FALSE(version_at_least({3, 23, 9}, "3.24"));
    CHECK_FALSE(version_at_least({2, 99}, "3.24"));
    CHECK_FALSE(version_at_least({}, "3.24"));
}

TEST_CASE("setup parse: only the official download addresses are trusted") {
    CHECK(is_trusted_download_url("https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21/x.tar.gz"));
    CHECK(is_trusted_download_url("https://dl.google.com/android/repository/commandlinetools-win-1_latest.zip"));
    CHECK(is_trusted_download_url("https://github.com/OxtailGames/FactorIA/releases/download/v0.1.3/FactorIA-windows-x64.zip"));
    CHECK(is_trusted_download_url("https://github.com/Kitware/CMake/releases/download/v3.31.6/cmake-3.31.6-macos-universal.tar.gz"));
    CHECK_FALSE(is_trusted_download_url("http://dl.google.com/android/repository/x.zip"));  // not https
    CHECK_FALSE(is_trusted_download_url("https://dl.google.com.evil.example/android/repository/x.zip"));
    CHECK_FALSE(is_trusted_download_url("https://github.com/adoptium-evil/x"));
    CHECK_FALSE(is_trusted_download_url("https://github.com/OxtailGames/Other/releases/download/v1/x.zip"));
    CHECK_FALSE(is_trusted_download_url(""));
}
