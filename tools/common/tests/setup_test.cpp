// `factoria setup` (fa/tooling/setup.h): status and install flows against a fake world. The downloader serves what the test
// registers, the process runner plays tar, sdkmanager, cmake, xcodebuild and open, and every folder is a temporary one, so
// nothing touches the network or the computer. A few tests use the real curl (file:// URLs) and the real tar on POSIX.
#include <doctest.h>

#include <algorithm>
#include <atomic>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <functional>
#include <map>
#include <set>

#include "fa/core/build_info.h"
#include "fa/core/command.h"
#include "fa/core/hash.h"
#include "fa/core/strings.h"
#include "fa/tooling/setup.h"
#include "fa/tooling/setup_parse.h"
#include "fa_test_paths.h"
#include "test_helpers.h"

#ifndef _WIN32
#include <sys/stat.h>
#endif

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

constexpr const char* kLicenseText = "Terms and Conditions\n\nYou agree to the test license.";

bool is_there(const stdfs::path& p) {
    std::error_code ec;
    return stdfs::exists(p, ec);
}

void put(const stdfs::path& p, const std::string& content = "x") { testing::write_all(p, content); }

std::vector<std::string> listing(const stdfs::path& dir) {
    std::vector<std::string> out;
    std::error_code ec;
    for (stdfs::recursive_directory_iterator it(dir, ec), end; !ec && it != end; it.increment(ec))
        out.push_back(stdfs::relative(it->path(), dir).generic_string());
    std::sort(out.begin(), out.end());
    return out;
}

// "jdk=installed cmdline-tools=skipped ..." : one readable string for a whole report.
std::string steps_of(const SetupReport& r) {
    std::string s;
    for (const SetupStep& step : r.steps) s += (s.empty() ? "" : " ") + step.id + "=" + step.outcome;
    return s;
}

void make_jdk(const stdfs::path& dir, int major) {
    put(dir / "bin" / "java");
    put(dir / "bin" / "javac");
    put(dir / "release", "JAVA_VERSION=\"" + std::to_string(major) + ".0.1\"\n");
}

void make_sdk(const stdfs::path& dir, bool license, bool cmdline, bool packages) {
    std::error_code ec;
    stdfs::create_directories(dir, ec);
    if (license) put(dir / "licenses" / "android-sdk-license", "24333f8a63b6825ea9c5514f83c2829b004d1fee\n");
    if (cmdline) put(dir / "cmdline-tools" / "latest" / "bin" / "sdkmanager", "#!/bin/sh\n");
    if (packages) {
        put(dir / "platform-tools" / "adb");
        put(dir / "platforms" / "android-36" / "android.jar");
        put(dir / "build-tools" / "35.0.0" / "aapt2");
    }
}

// ---- the fake listings --------------------------------------------------------------------------------------------

// One cmdline-tools package of the listing (a Mac archive only: the tests run as a Mac with an M chip).
std::string tools_package(const std::string& path, int major, const std::string& archiveName, const std::string& content) {
    return "<remotePackage path=\"" + path + "\"><revision><major>" + std::to_string(major) + "</major><minor>0</minor></revision><archives><archive><complete>"
           "<size>" + std::to_string(content.size()) + "</size><checksum type=\"sha1\">" + sha1_hex(content) + "</checksum><url>" + archiveName +
           "</url></complete><host-os>macosx</host-os><host-arch>aarch64</host-arch></archive></archives></remotePackage>\n";
}

// Google's listing: the pinned classic tools (the archive that is served) and `latest`, revision 23, an archive nobody serves: a
// test that downloads it fails. With `pinnedListed` false the pinned package is gone and the served archive is `latest`.
std::string repo_xml(const std::string& archiveName, const std::string& content, bool pinnedListed = true) {
    std::string xml = "<sdk:sdk-repository>\n<license id=\"android-sdk-license\" type=\"text\">" + std::string(kLicenseText) + "</license>\n";
    if (pinnedListed) {
        xml += tools_package("cmdline-tools;22.0", 22, archiveName, content);
        xml += tools_package("cmdline-tools;latest", 23, "commandlinetools-mac_arm64-23_latest.zip", "the Android CLI front");
    } else {
        xml += tools_package("cmdline-tools;latest", 23, archiveName, content);
    }
    return xml + "</sdk:sdk-repository>";
}

std::string adoptium_json(const std::string& name, const std::string& content, const std::string& sha = {}) {
    return R"([{"binary":{"package":{"checksum":")" + (sha.empty() ? sha256_hex(content) : sha) +
           R"(","link":"https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.12%2B1/)" + name + R"(","name":")" + name +
           R"(","size":)" + std::to_string(content.size()) + R"(}},"release_name":"jdk-21.0.12+1","version":{"openjdk_version":"21.0.12+1-LTS"}}])";
}

struct Asset {
    std::string name;
    std::string content;
    bool digest = true;
    bool badDigest = false;
    long sizeDelta = 0;  // what the release claims minus the real size
};

std::string release_json(const std::string& tag, const std::vector<Asset>& assets) {
    std::string a;
    for (const Asset& x : assets) {
        const std::string digest = x.digest ? "\"sha256:" + (x.badDigest ? std::string(64, '0') : sha256_hex(x.content)) + "\"" : "null";
        a += std::string(a.empty() ? "" : ",") + R"({"name":")" + x.name + R"(","size":)" + std::to_string(long(x.content.size()) + x.sizeDelta) +
             R"(,"browser_download_url":"https://github.com/OxtailGames/FactorIA/releases/download/)" + tag + "/" + x.name + R"(","digest":)" + digest + "}";
    }
    return R"({"tag_name":")" + tag + R"(","assets":[)" + a + "]}";
}

const char* kTagsUrl = "https://api.github.com/repos/OxtailGames/FactorIA/releases/tags/v0.1.3";
const char* kLatestUrl = "https://api.github.com/repos/OxtailGames/FactorIA/releases/latest";
const char* kCmakeBase = "https://github.com/Kitware/CMake/releases/download/v3.31.6/";

std::string package_url(const std::string& name) { return "https://github.com/OxtailGames/FactorIA/releases/download/v0.1.3/" + name; }

// ---- the fake world -----------------------------------------------------------------------------------------------

struct ProcessCall {
    std::vector<std::string> argv;
    std::map<std::string, std::string> env;
    std::string stdinText;
    std::string packageFile;  // what --package_file named held when sdkmanager ran
};

struct World {
    testing::TempDir tmp;
    std::string home, user, exeDir, apps;
    std::map<std::string, std::string> env;
    std::map<std::string, std::string> served;       // url -> body
    std::map<std::string, int> failing;              // url -> HTTP status
    std::set<std::string> cancelOn;                  // urls whose download is cancelled
    std::vector<std::string> requested;
    std::map<std::string, std::vector<std::string>> headersOf;
    std::vector<ProcessCall> calls;
    std::vector<std::string> said;
    std::map<std::string, std::string> cmakeAt;      // cmake path -> its `--version` output
    std::string developerDir, xcodeVersion, sdks;    // what xcode-select / xcodebuild print ("" = they fail)
    int sdkmanagerExit = 0;                          // the exit code of the package install
    std::string sdkmanagerOutput;                    // its stderr when it fails
    bool jdkBundle = true;                           // the JDK archive has Contents/Home (macOS) inside
    bool unpackWeb = true;                           // every package carries web/ (false: a release older than the web export)
    bool unpackIosLibs = true;                       // the macOS package carries mobile/ios (false: a broken release)
    bool pinnedListed = true;                        // Google's listing still has cmdline-tools;22.0 (false: only `latest`)
    std::string sourceRoot;                          // the checkout `setup webplayer` builds in (a temporary folder; "" = none)
    std::function<Result<ProcessResult>(const ProcessOptions&)> onOther;  // programs the world does not know (bash, emsdk)
    std::string jdkContent = std::string(400, 'J');
    std::string toolsContent = std::string(500, 'T');

    World() {
        user = tmp.sub("user");
        home = tmp.sub("fhome");
        exeDir = tmp.sub("exe");
        apps = tmp.sub("apps");
        for (const std::string& d : {user, exeDir, apps}) stdfs::create_directories(d);
        env["HOME"] = user;
        env["USERPROFILE"] = user;
        env["FACTORIA_HOME"] = home;
    }
    World(const World&) = delete;
    World& operator=(const World&) = delete;

    stdfs::path h() const { return stdfs::path(home); }
    std::string config() const { return (h() / "export.json").string(); }
    std::string jdk_name() const { return "OpenJDK21U-jdk_aarch64_mac_hotspot_21.0.12_1.tar.gz"; }
    std::string tools_name() const { return "commandlinetools-mac_arm64-1_latest.zip"; }
    static std::string adoptium_url() { return "https://api.adoptium.net/v3/assets/latest/21/hotspot?os=mac&architecture=aarch64&image_type=jdk&vendor=eclipse"; }
    std::string jdk_link() const { return "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.12%2B1/" + jdk_name(); }
    std::string tools_url() const { return std::string(kSdkDownloadBase) + tools_name(); }

    void serve_android() {
        served[adoptium_url()] = adoptium_json(jdk_name(), jdkContent);
        served[jdk_link()] = jdkContent;
        served[kSdkRepositoryUrl] = repo_xml(tools_name(), toolsContent, pinnedListed);
        served[tools_url()] = toolsContent;
    }

    // Release v0.1.3 with the three packages (each a distinct body).
    std::vector<Asset> serve_release(bool digests = true) {
        std::vector<Asset> assets;
        for (const char* name : {"FactorIA-windows-x64.zip", "FactorIA-linux-x64.tar.gz", "FactorIA-macos-universal.tar.gz"}) {
            Asset a;
            a.name = name;
            a.content = std::string("package ") + name + std::string(300, 'x');
            a.digest = digests;
            assets.push_back(a);
        }
        publish(assets);
        return assets;
    }
    void publish(const std::vector<Asset>& assets) {
        served[kTagsUrl] = release_json("v0.1.3", assets);
        for (const Asset& a : assets) served[package_url(a.name)] = a.content;
    }

    void serve_cmake(const std::string& archiveName, const std::string& content, const std::string& sumOf = {}) {
        served[std::string(kCmakeBase) + "cmake-3.31.6-SHA-256.txt"] =
            std::string(64, 'e') + "  cmake-3.31.6-files-v1.json\n" + sha256_hex(sumOf.empty() ? content : sumOf) + "  " + archiveName + "\n";
        served[std::string(kCmakeBase) + archiveName] = content;
    }

    SetupContext ctx(const std::string& host = "macos", const std::string& arch = "aarch64") {
        SetupContext c;
        c.env = [this](const std::string& n) {
            auto it = env.find(n);
            return it == env.end() ? std::string() : it->second;
        };
        c.host = host;
        c.hostArch = arch;
        c.engineVersion = "0.1.3";
        c.executableDir = exeDir;
        c.sourceRoot = sourceRoot.empty() ? tmp.sub("no-checkout") : sourceRoot;
        c.applicationsDir = apps;
        c.download = [this](const DownloadRequest& rq) { return download(rq); };
        c.run = [this](const ProcessOptions& o) { return run(o); };
        c.progress = [this](const std::string& line) { said.push_back(line); };
        AndroidToolchainSearch s;
        s.env = c.env;  // only the folders of this world: never the Unity Hub or Android Studio of the computer running the tests
        s.jdk.push_back({(h() / "android" / "jdk").string(), "FactorIA"});
        s.sdk.push_back({(h() / "android" / "sdk").string(), "FactorIA"});
        c.toolchainSearch = s;
        return c;
    }

    DownloadResult download(const DownloadRequest& rq) {
        requested.push_back(rq.url);
        headersOf[rq.url] = rq.headers;
        DownloadResult r;
        auto fail = [&](int status, const std::string& message) {
            r.ok = false;
            r.httpStatus = status;
            r.error = make_error(message, "test hint");
            return r;
        };
        if (cancelOn.count(rq.url)) {
            r.ok = false;
            r.cancelled = true;
            r.error = make_error("cancelled in the test");
            return r;
        }
        if (auto f = failing.find(rq.url); f != failing.end()) return fail(f->second, "HTTP " + std::to_string(f->second) + " for " + rq.url);
        auto it = served.find(rq.url);
        if (it == served.end()) return fail(404, "not served in the test: " + rq.url);
        put(rq.destination, it->second);
        if (rq.onBytes)
            for (std::uint64_t i = 1; i <= 100; ++i) rq.onBytes(it->second.size() * i / 100);
        return r;
    }

    Result<ProcessResult> run(const ProcessOptions& o) {
        ProcessCall c;
        c.argv = o.argv;
        c.env = o.env;
        c.stdinText = o.stdinText;
        for (const std::string& a : o.argv)
            if (starts_with(a, "--package_file=")) c.packageFile = testing::read_all(a.substr(15));
        calls.push_back(c);
        REQUIRE_FALSE(o.argv.empty());
        const std::string exe = stdfs::path(o.argv[0]).filename().string();
        ProcessResult r;
        r.exitCode = 0;
        if (exe == "tar" || exe == "tar.exe" || exe == "unzip") return unpack(o.argv);
        if (exe == "sdkmanager" || exe == "sdkmanager.bat") return sdkmanager(o);
        if (exe == "cmake" || exe == "cmake.exe") {
            auto it = cmakeAt.find(o.argv[0]);
            if (it == cmakeAt.end()) return make_error("cannot run " + o.argv[0] + " in the test");
            r.stdoutText = it->second;
            return r;
        }
        if (exe == "xcode-select") {
            if (developerDir.empty()) {
                r.exitCode = 1;
                r.stderrText = "xcode-select: error: unable to get active developer directory";
            } else {
                r.stdoutText = developerDir + "\n";
            }
            return r;
        }
        if (exe == "xcodebuild") {
            if (o.argv.size() > 1 && o.argv[1] == "-showsdks") {
                r.stdoutText = sdks;
            } else if (xcodeVersion.empty()) {
                r.exitCode = 1;
                r.stderrText = "xcode-select: error: tool 'xcodebuild' requires Xcode";
            } else {
                r.stdoutText = xcodeVersion;
            }
            return r;
        }
        if (exe == "open") return r;
        if (onOther) return onOther(o);
        return make_error("unexpected program in the test: " + o.argv[0]);
    }

    // What `tar -xf <archive> -C <dest>` (or unzip) would unpack, by the name of the archive.
    Result<ProcessResult> unpack(const std::vector<std::string>& argv) {
        std::string archive, dest;
        for (std::size_t i = 0; i + 1 < argv.size(); ++i) {
            if (argv[i] == "-xf" || argv[i] == "-xzf" || argv[i] == "-o") archive = argv[i + 1];
            if (argv[i] == "-C" || argv[i] == "-d") dest = argv[i + 1];
        }
        REQUIRE(is_there(archive));
        REQUIRE_FALSE(dest.empty());
        const stdfs::path d(dest);
        const std::string name = stdfs::path(archive).filename().string();
        if (starts_with(name, "OpenJDK")) {
            const stdfs::path top = d / "jdk-21.0.12+1";
            make_jdk(jdkBundle ? top / "Contents" / "Home" : top, 21);
        } else if (starts_with(name, "commandlinetools")) {
            put(d / "cmdline-tools" / "bin" / "sdkmanager", "#!/bin/sh\n");
            put(d / "cmdline-tools" / "lib" / "sdklib.jar");
            put(d / "cmdline-tools" / "source.properties", "Pkg.Revision=22.0\n");
        } else if (starts_with(name, "FactorIA-")) {
            const bool windows = name.find("windows") != std::string::npos;
            put(d / "FactorIA" / (windows ? "factoria_player.exe" : "factoria_player"), "player of " + name);
            for (const char* abi : {"arm64-v8a", "x86_64"}) put(d / "FactorIA" / "mobile" / "android" / "jniLibs" / abi / "libfactoria_player.so");
            if (unpackWeb) {  // every package carries the web player
                put(d / "FactorIA" / "web" / "factoria_player.js", "glue of " + name);
                put(d / "FactorIA" / "web" / "factoria_player.wasm", "wasm of " + name);
            }
            if (name.find("macos") != std::string::npos && unpackIosLibs)
                for (const char* sdk : {"iphoneos", "iphonesimulator"}) put(d / "FactorIA" / "mobile" / "ios" / sdk / "libfactoria_player_main.a");
        } else if (starts_with(name, "emsdk")) {
            put(d / "emsdk-main" / "emsdk", "#!/bin/sh\n");
            put(d / "emsdk-main" / "emsdk_env.sh", "# env\n");
        } else if (starts_with(name, "cmake-")) {
            const std::string top = name.substr(0, name.find(".tar.gz"));
            if (name.find("macos") != std::string::npos) put(d / top / "CMake.app" / "Contents" / "bin" / "cmake");
            else put(d / top / "bin" / "cmake");
        } else {
            return make_error("the test does not know how to unpack " + name);
        }
        ProcessResult r;
        r.exitCode = 0;
        return r;
    }

    // sdkmanager as far as `setup android` talks to it: it never gets --licenses (the install records the license itself), and
    // installing packages needs a recorded license, or a "y" on stdin that makes it record one (what the real tools do).
    Result<ProcessResult> sdkmanager(const ProcessOptions& o) {
        std::string root, packageFile;
        for (const std::string& a : o.argv) {
            if (starts_with(a, "--sdk_root=")) root = a.substr(11);
            else if (starts_with(a, "--package_file=")) packageFile = a.substr(15);
        }
        ProcessResult r;
        r.exitCode = 0;
        if (packageFile.empty()) {
            r.exitCode = 2;
            return r;
        }
        if (o.onStdoutLine) {
            o.onStdoutLine("[=====                   ] 20% Downloading platform-tools");  // a progress bar: dropped
            o.onStdoutLine("Installing platform-tools");
        }
        if (sdkmanagerExit != 0) {
            r.exitCode = sdkmanagerExit;
            r.stderrText = sdkmanagerOutput;
            return r;
        }
        const stdfs::path licenseFile = stdfs::path(root) / "licenses" / "android-sdk-license";
        if (trim(is_there(licenseFile) ? testing::read_all(licenseFile.string()) : std::string()).empty()) {
            if (!starts_with(o.stdinText, "y\n")) {
                r.exitCode = 1;
                r.stderrText = "License android-sdk-license: Accept? (y/N): Skipping following packages as the license is not accepted: platform-tools\n";
                return r;
            }
            put(licenseFile, "\n24333f8a63b6825ea9c5514f83c2829b004d1fee");
        }
        for (const std::string& line : split(testing::read_all(packageFile), '\n')) {
            const std::string pkg(trim(line));
            if (pkg == "platform-tools") put(stdfs::path(root) / "platform-tools" / "adb");
            else if (pkg == "platforms;android-36") put(stdfs::path(root) / "platforms" / "android-36" / "android.jar");
            else if (pkg == "build-tools;35.0.0") put(stdfs::path(root) / "build-tools" / "35.0.0" / "aapt2");
        }
        return r;
    }

    std::size_t sdkmanager_calls() const {
        std::size_t n = 0;
        for (const ProcessCall& c : calls) n += stdfs::path(c.argv[0]).filename().string().rfind("sdkmanager", 0) == 0 ? 1 : 0;
        return n;
    }
};

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// Where things live
// ---------------------------------------------------------------------------------------------------------------------

TEST_CASE("setup: factoria_home and the machine settings follow FACTORIA_HOME") {
    std::map<std::string, std::string> e;
    auto lookup = [&](const std::string& n) {
        auto it = e.find(n);
        return it == e.end() ? std::string() : it->second;
    };
    CHECK(factoria_home(lookup) == ".factoria");
    e["HOME"] = "/users/ana";
    e["USERPROFILE"] = "/users/ana";
    CHECK(factoria_home(lookup) == (stdfs::path("/users/ana") / ".factoria").string());
    e["FACTORIA_HOME"] = "/x/fa";
    CHECK(factoria_home(lookup) == "/x/fa");

    CHECK(machine_export_config_path(lookup) == (stdfs::path("/x/fa") / "export.json").string());
    e["FACTORIA_EXPORT_CONFIG"] = "/elsewhere/config.json";
    CHECK(machine_export_config_path(lookup) == "/elsewhere/config.json");

    // What `setup android` installs is searched first and says so.
    const AndroidToolchainSearch search = default_android_toolchain_search(lookup);
    REQUIRE_FALSE(search.jdk.empty());
    REQUIRE_FALSE(search.sdk.empty());
    CHECK(search.jdk[0].path == (stdfs::path("/x/fa") / "android" / "jdk").string());
    CHECK(search.jdk[0].from == "FactorIA");
    CHECK(search.sdk[0].path == (stdfs::path("/x/fa") / "android" / "sdk").string());
    CHECK(search.sdk[0].from == "FactorIA");
}

TEST_CASE("setup: status of an empty computer writes nothing and downloads only the license") {
    World w;
    w.serve_android();
    SetupContext c = w.ctx();

    SetupStatus all = setup_status(c, {}, false);
    REQUIRE(all.components.size() == 9);
    CHECK(all.components[8].id == "webplayer");
    CHECK(all.components[8].state == "unsupported");  // the test world has no checkout
    CHECK(all.components[6].id == "vscode");
    CHECK(all.components[7].id == "ffmpeg");
    CHECK(all.components[0].id == "android");
    CHECK(all.components[1].id == "players");
    CHECK(all.components[2].id == "cmake");
    CHECK(all.components[3].id == "xcode");
    CHECK(all.components[4].id == "appimage");
    CHECK(all.components[4].state == "unsupported");  // a Mac builds no AppImage
    CHECK(all.host == "macos-aarch64");
    CHECK(all.home == w.home);
    CHECK(all.components[0].state == "missing");
    CHECK(all.components[0].canInstall);
    CHECK(all.components[0].installSizeMb == 500);  // JDK 200 + the pinned command-line tools 160 + the packages 140: no Android CLI on top
    CHECK(all.components[0].licenses.empty());  // fetchLicenses off: no request
    CHECK(all.components[1].state == "missing");
    CHECK(all.components[1].installSizeMb > 0);
    CHECK(all.components[2].state == "missing");
    CHECK(all.components[3].state == "missing");
    CHECK(w.requested.empty());
    CHECK_FALSE(is_there(w.home));  // looking is free

    const SetupStatus android = setup_status(c, "android", true);
    REQUIRE(android.components.size() == 1);
    REQUIRE(android.components[0].licenses.size() == 1);
    CHECK(android.components[0].licenses[0].id == "android-sdk-license");
    CHECK(android.components[0].licenses[0].text == kLicenseText);
    CHECK(w.requested == std::vector<std::string>{kSdkRepositoryUrl});
    CHECK_FALSE(is_there(w.home));

    const Json j = all.to_json();
    CHECK(j.at("home").get<std::string>() == w.home);
    CHECK(j.at("components").size() == 9);
    CHECK(j.at("components")[0].at("state").get<std::string>() == "missing");
}

TEST_CASE("setup: the repository listing is fetched once while a cache is shared") {
    World w;
    w.serve_android();
    SetupContext c = w.ctx();
    c.cache = std::make_shared<SetupCache>();
    CHECK(setup_status(c, "android", true).components[0].licenses.size() == 1);
    CHECK(setup_status(c, "android", true).components[0].licenses.size() == 1);
    CHECK(std::count(w.requested.begin(), w.requested.end(), std::string(kSdkRepositoryUrl)) == 1);
}

TEST_CASE("setup: a license that cannot be fetched is a problem, not a crash") {
    World w;  // nothing served
    SetupContext c = w.ctx();
    const SetupComponent a = setup_status(c, "android", true).components[0];
    CHECK(a.licenses.empty());
    bool mentioned = false;
    for (const std::string& p : a.problems) mentioned |= p.find("Could not fetch the license text") != std::string::npos;
    CHECK(mentioned);
}

TEST_CASE("setup: status of a computer that has everything") {
    World w;
    make_jdk(w.h() / "android" / "jdk", 21);
    make_sdk(w.h() / "android" / "sdk", true, true, true);
    SetupContext c = w.ctx();
    const SetupComponent a = setup_status(c, "android", true).components[0];  // would fetch the license if it were missing
    CHECK(a.state == "installed");
    CHECK(a.problems.empty());
    CHECK(a.licenses.empty());
    CHECK(w.requested.empty());
    CHECK(a.details.find("JDK 21") != std::string::npos);
    CHECK(a.installSizeMb == 0);
}

// ---------------------------------------------------------------------------------------------------------------------
// Android
// ---------------------------------------------------------------------------------------------------------------------

TEST_CASE("setup android: the license is asked for before anything is downloaded") {
    World w;
    w.serve_android();
    SetupContext c = w.ctx();
    SetupInstallOptions o;
    o.component = "android";
    const SetupResult r = setup_install(o, c);
    REQUIRE_FALSE(r.ok);
    CHECK(r.code == "license_required");
    CHECK(r.error.message.find("Android Software Development Kit License Agreement") != std::string::npos);
    CHECK(r.error.hint.find("acceptLicenses") != std::string::npos);
    CHECK(w.requested.empty());
    CHECK(w.calls.empty());
    CHECK_FALSE(is_there(w.home));
}

TEST_CASE("setup android: installs the JDK, the pinned tools, the license and the packages, then skips them") {
    World w;
    w.serve_android();
    SetupContext c = w.ctx();
    SetupInstallOptions o;
    o.component = "android";
    o.acceptLicenses = true;
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(steps_of(r.report) == "jdk=installed cmdline-tools=installed licenses=installed packages=installed config=installed");
    CHECK(r.report.changed);
    CHECK(r.report.warnings.empty());  // the pinned package was there: nothing to warn about

    const stdfs::path jdk = w.h() / "android" / "jdk", sdk = w.h() / "android" / "sdk";
    const stdfs::path tools = sdk / "cmdline-tools" / "22.0";  // the folder is named like the package cmdline-tools;22.0
    CHECK(w.requested == std::vector<std::string>{World::adoptium_url(), w.jdk_link(), kSdkRepositoryUrl, w.tools_url()});  // not the `latest` archive
    CHECK(is_there(jdk / "bin" / "java"));  // Contents/Home of the macOS bundle is the JDK folder
    CHECK(is_there(jdk / "release"));
    CHECK_FALSE(is_there(jdk / "Contents"));
    CHECK(is_there(tools / "bin" / "sdkmanager"));
    CHECK(is_there(tools / "lib" / "sdklib.jar"));
    CHECK(testing::read_all((tools / "source.properties").string()) == "Pkg.Revision=22.0\n");
    CHECK_FALSE(is_there(sdk / "cmdline-tools" / "latest"));
    CHECK(is_there(sdk / "platform-tools"));
    CHECK(is_there(sdk / "platforms" / "android-36"));
    CHECK(is_there(sdk / "build-tools" / "35.0.0"));
    CHECK_FALSE(is_there(w.h() / "staging"));  // nothing left behind
#ifndef _WIN32
    struct stat st {};
    REQUIRE(stat((tools / "bin" / "sdkmanager").string().c_str(), &st) == 0);
    CHECK((st.st_mode & S_IXUSR) != 0);
#endif
    CHECK(r.report.steps[1].detail.find("22.0") != std::string::npos);
    CHECK(r.report.steps[1].path == tools.string());

    // The license: only the one the user agreed to, as the line Google's tools write (a line break, the hash of the text).
    CHECK(testing::read_all((sdk / "licenses" / "android-sdk-license").string()) == "\n" + sdk_license_hash(kLicenseText));
    CHECK(listing(sdk / "licenses") == std::vector<std::string>{"android-sdk-license"});
    CHECK(r.report.steps[2].detail.find("no other license") != std::string::npos);

    // sdkmanager runs once, for the packages (no `--licenses`: that would accept every license Google lists), with JAVA_HOME and the
    // SDK folder, and no "y" answers: the license is recorded already.
    REQUIRE(w.sdkmanager_calls() == 1);
    std::vector<const ProcessCall*> mgr;
    for (const ProcessCall& call : w.calls) {
        if (stdfs::path(call.argv[0]).filename() == "sdkmanager") mgr.push_back(&call);
        for (const std::string& a : call.argv) CHECK(a != "--licenses");
    }
    REQUIRE(mgr.size() == 1);
    CHECK(mgr[0]->argv[0] == (tools / "bin" / "sdkmanager").string());
    CHECK(mgr[0]->argv[1] == "--sdk_root=" + sdk.string());
    CHECK(starts_with(mgr[0]->argv[2], "--package_file="));
    CHECK(mgr[0]->env.at("JAVA_HOME") == jdk.string());
    CHECK(mgr[0]->env.at("ANDROID_USER_HOME") == (w.h() / "android" / "user").string());  // Google's tools keep their files in FactorIA's folder
    CHECK(mgr[0]->packageFile == "platform-tools\nplatforms;android-36\nbuild-tools;35.0.0\n");
    CHECK(mgr[0]->stdinText.empty());

    // The machine settings learned both folders, so `factoria export` finds them.
    auto saved = load_machine_export_config(w.config());
    REQUIRE(saved.ok());
    CHECK(saved->androidJdk == jdk.string());
    CHECK(saved->androidSdk == sdk.string());

    // Progress: named downloads with a few percent lines, sdkmanager's text without its progress bars.
    int percentLines = 0;
    bool unpacking = false, installing = false;
    for (const std::string& line : w.said) {
        REQUIRE_FALSE(line.empty());
        CHECK(line.front() != '[');
        if (starts_with(line, "Downloading JDK") && line.find("%)") != std::string::npos) ++percentLines;
        unpacking |= starts_with(line, "Unpacking");
        installing |= line == "Installing platform-tools";
    }
    CHECK(percentLines >= 2);
    CHECK(percentLines <= 10);
    CHECK(unpacking);
    CHECK(installing);

    // The status agrees (and finds the pinned sdkmanager), and a second run changes nothing.
    const SetupComponent status = setup_status(c, "android", true).components[0];
    CHECK(status.state == "installed");
    CHECK(status.licenses.empty());
    bool pathOfTools = false;
    for (const auto& [name, path] : status.paths) pathOfTools |= name == "sdkmanager" && path == (tools / "bin" / "sdkmanager").string();
    CHECK(pathOfTools);
    const std::size_t requested = w.requested.size(), called = w.calls.size();
    SetupInstallOptions again;
    again.component = "android";  // no acceptLicenses: nothing needs one anymore
    const SetupResult r2 = setup_install(again, c);
    REQUIRE_MESSAGE(r2.ok, r2.error.message);
    CHECK(steps_of(r2.report) == "jdk=skipped cmdline-tools=skipped licenses=skipped packages=skipped");
    CHECK_FALSE(r2.report.changed);
    CHECK(w.requested.size() == requested);
    CHECK(w.calls.size() == called);

    // The report is JSON for the commands.
    const Json j = r.report.to_json();
    CHECK(j.at("component").get<std::string>() == "android");
    CHECK(j.at("steps")[0].at("id").get<std::string>() == "jdk");
    CHECK(j.at("steps")[0].at("outcome").get<std::string>() == "installed");
    CHECK(j.at("steps")[0].at("downloadedBytes").get<std::uint64_t>() == w.jdkContent.size());
    CHECK(j.at("paths").at("sdk").get<std::string>() == sdk.string());
}

TEST_CASE("setup android: when Google's list no longer has the pinned tools, `latest` is installed with a warning") {
    World w;
    w.pinnedListed = false;
    w.serve_android();
    SetupContext c = w.ctx();
    SetupInstallOptions o;
    o.component = "android";
    o.acceptLicenses = true;
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(steps_of(r.report) == "jdk=installed cmdline-tools=installed licenses=installed packages=installed config=installed");
    REQUIRE(r.report.warnings.size() == 1);
    CHECK(r.report.warnings[0].find("cmdline-tools;22.0") != std::string::npos);
    CHECK(r.report.warnings[0].find("cmdline-tools;latest") != std::string::npos);
    CHECK(r.report.warnings[0].find("Android CLI") != std::string::npos);
    CHECK(r.report.warnings[0].find("usage statistics") != std::string::npos);
    CHECK(r.report.to_json().at("warnings").size() == 1);

    const stdfs::path sdk = w.h() / "android" / "sdk";
    CHECK(is_there(sdk / "cmdline-tools" / "latest" / "bin" / "sdkmanager"));
    CHECK_FALSE(is_there(sdk / "cmdline-tools" / "22.0"));
    CHECK(r.report.steps[1].detail.find("Android CLI") != std::string::npos);
    CHECK(r.report.steps[1].path == (sdk / "cmdline-tools" / "latest").string());
    CHECK(is_there(sdk / "licenses" / "android-sdk-license"));
    CHECK(is_there(sdk / "platforms" / "android-36"));

    // The Android CLI keeps its ~250 MB in FactorIA's folder, never in ~/.android; it is not known to accept our license line, so
    // it still gets the "y" answers the user's agreement allows. Nothing asks for `--licenses`.
    REQUIRE(w.sdkmanager_calls() == 1);
    for (const ProcessCall& call : w.calls) {
        if (stdfs::path(call.argv[0]).filename() != "sdkmanager") continue;
        CHECK(call.env.at("ANDROID_USER_HOME") == (w.h() / "android" / "user").string());
        CHECK(call.stdinText.rfind("y\ny\n", 0) == 0);
        for (const std::string& a : call.argv) CHECK(a != "--licenses");
    }
    CHECK(setup_status(c, "android", false).components[0].state == "installed");
}

TEST_CASE("setup android: the license is recorded by the install, only for the user's agreement") {
    // An SDK that has everything but the license: recording it needs no sdkmanager and no package install.
    World lone;
    make_jdk(lone.tmp.path / "jdk", 17);
    lone.env["JAVA_HOME"] = (lone.tmp.path / "jdk").string();
    make_sdk(lone.h() / "android" / "sdk", false, true, true);
    stdfs::create_directories(lone.h() / "android" / "sdk" / "licenses");  // an SDK folder that looks like one, without the license file
    lone.serve_android();
    SetupContext cl = lone.ctx();
    SetupInstallOptions o;
    o.component = "android";
    const SetupResult refused = setup_install(o, cl);  // no agreement: nothing is written
    REQUIRE_FALSE(refused.ok);
    CHECK(refused.code == "license_required");
    CHECK(lone.requested.empty());
    CHECK(listing(lone.h() / "android" / "sdk" / "licenses").empty());

    o.acceptLicenses = true;
    const SetupResult done = setup_install(o, cl);
    REQUIRE_MESSAGE(done.ok, done.error.message);
    CHECK(steps_of(done.report) == "jdk=skipped cmdline-tools=skipped licenses=installed packages=skipped");
    CHECK(lone.requested == std::vector<std::string>{kSdkRepositoryUrl});  // the license text is all it fetches
    CHECK(lone.sdkmanager_calls() == 0);
    CHECK(testing::read_all((lone.h() / "android" / "sdk" / "licenses" / "android-sdk-license").string()) == "\n" + sdk_license_hash(kLicenseText));
    CHECK(setup_status(cl, "android", false).components[0].state == "installed");

    // Tools that were there before (an SDK that was found) are not known to be the classic ones: they get the "y" answers as before.
    World found;
    make_jdk(found.tmp.path / "jdk", 17);
    found.env["JAVA_HOME"] = (found.tmp.path / "jdk").string();
    make_sdk(found.h() / "android" / "sdk", false, true, false);
    found.serve_android();
    SetupContext cf = found.ctx();
    const SetupResult packages = setup_install(o, cf);
    REQUIRE_MESSAGE(packages.ok, packages.error.message);
    CHECK(steps_of(packages.report) == "jdk=skipped cmdline-tools=skipped licenses=installed packages=installed");
    REQUIRE(found.sdkmanager_calls() == 1);
    for (const ProcessCall& call : found.calls)
        if (stdfs::path(call.argv[0]).filename() == "sdkmanager") CHECK(call.stdinText.rfind("y\ny\n", 0) == 0);

    // The listing cannot be fetched: the license cannot be recorded, and nothing is written.
    World offline;
    make_jdk(offline.tmp.path / "jdk", 17);
    offline.env["JAVA_HOME"] = (offline.tmp.path / "jdk").string();
    make_sdk(offline.h() / "android" / "sdk", false, true, true);
    stdfs::create_directories(offline.h() / "android" / "sdk" / "licenses");
    SetupContext co = offline.ctx();
    const SetupResult failed = setup_install(o, co);
    REQUIRE_FALSE(failed.ok);
    CHECK(failed.code == "network");
    CHECK(listing(offline.h() / "android" / "sdk" / "licenses").empty());
}

TEST_CASE("setup android: the pinned tools win over a `latest` folder in the same SDK") {
    World w;
    make_jdk(w.h() / "android" / "jdk", 21);
    make_sdk(w.h() / "android" / "sdk", true, true, true);  // cmdline-tools/latest
    const stdfs::path pinned = w.h() / "android" / "sdk" / "cmdline-tools" / "22.0" / "bin" / "sdkmanager";
    put(pinned, "#!/bin/sh\n");
    SetupContext c = w.ctx();
    const SetupComponent a = setup_status(c, "android", false).components[0];
    std::string found;
    for (const auto& [name, path] : a.paths)
        if (name == "sdkmanager") found = path;
    CHECK(found == pinned.string());
}

TEST_CASE("setup android: a damaged download installs nothing") {
    World w;
    w.serve_android();
    w.served[World::adoptium_url()] = adoptium_json(w.jdk_name(), w.jdkContent, std::string(64, '0'));
    SetupContext c = w.ctx();
    SetupInstallOptions o;
    o.component = "android";
    o.acceptLicenses = true;
    const SetupResult r = setup_install(o, c);
    REQUIRE_FALSE(r.ok);
    CHECK(r.code == "checksum_mismatch");
    CHECK(r.error.message.find("damaged") != std::string::npos);
    CHECK(r.error.message.find(std::string(64, '0')) != std::string::npos);
    CHECK(r.error.hint.find("Nothing was installed") != std::string::npos);
    CHECK_FALSE(is_there(w.h() / "android"));
    CHECK_FALSE(is_there(w.h() / "staging"));
    CHECK_FALSE(is_there(w.config()));
    CHECK(r.report.steps.empty());
}

TEST_CASE("setup android: the Android command-line tools are checked against their SHA-1") {
    World w;
    w.serve_android();
    w.served[w.tools_url()] = std::string(500, 'X');  // not what the listing's checksum is of
    SetupContext c = w.ctx();
    SetupInstallOptions o;
    o.component = "android";
    o.acceptLicenses = true;
    const SetupResult r = setup_install(o, c);
    REQUIRE_FALSE(r.ok);
    CHECK(r.code == "checksum_mismatch");
    CHECK(r.error.message.find("sha1") != std::string::npos);
    CHECK(steps_of(r.report) == "jdk=installed");  // what was done before the failure is reported
    CHECK_FALSE(is_there(w.h() / "android" / "sdk" / "cmdline-tools"));
}

TEST_CASE("setup android: a JDK that is already there is used, not downloaded") {
    World w;
    w.serve_android();
    const stdfs::path jdk17 = w.tmp.path / "jdk17";
    make_jdk(jdk17, 17);
    w.env["JAVA_HOME"] = jdk17.string();
    SetupContext c = w.ctx();
    SetupInstallOptions o;
    o.component = "android";
    o.acceptLicenses = true;
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(steps_of(r.report) == "jdk=skipped cmdline-tools=installed licenses=installed packages=installed config=installed");
    CHECK(r.report.steps[0].path == jdk17.string());
    for (const std::string& url : w.requested) CHECK(url.find("adoptium") == std::string::npos);
    CHECK_FALSE(is_there(w.h() / "android" / "jdk"));
    for (const ProcessCall& call : w.calls)
        if (stdfs::path(call.argv[0]).filename() == "sdkmanager") CHECK(call.env.at("JAVA_HOME") == jdk17.string());
    auto saved = load_machine_export_config(w.config());
    REQUIRE(saved.ok());
    CHECK(saved->androidJdk.empty());  // found by itself: nothing to tell
    CHECK(saved->androidSdk == (w.h() / "android" / "sdk").string());

    // force downloads the JDK anyway.
    SetupInstallOptions forced;
    forced.component = "android";
    forced.force = true;
    const SetupResult f = setup_install(forced, c);
    REQUIRE_MESSAGE(f.ok, f.error.message);
    CHECK(f.report.steps[0].outcome == "installed");
    CHECK(is_there(w.h() / "android" / "jdk" / "bin" / "java"));
}

TEST_CASE("setup android: with the license accepted, only the missing packages are installed and no answer is typed") {
    World w;
    w.serve_android();
    make_jdk(w.tmp.path / "jdk", 17);
    make_sdk(w.tmp.path / "sdk", true, true, false);
    w.env["JAVA_HOME"] = (w.tmp.path / "jdk").string();
    w.env["ANDROID_HOME"] = (w.tmp.path / "sdk").string();
    SetupContext c = w.ctx();
    SetupInstallOptions o;
    o.component = "android";  // no acceptLicenses: the license is accepted already
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(steps_of(r.report) == "jdk=skipped cmdline-tools=skipped licenses=skipped packages=installed");
    REQUIRE(w.sdkmanager_calls() == 1);
    for (const ProcessCall& call : w.calls)
        if (stdfs::path(call.argv[0]).filename() == "sdkmanager") {
            CHECK(call.argv[1] == "--sdk_root=" + (w.tmp.path / "sdk").string());
            CHECK(call.stdinText.empty());
        }
    CHECK(w.requested.empty());
    CHECK(is_there(w.tmp.path / "sdk" / "platforms" / "android-36"));
    CHECK_FALSE(is_there(w.config()));  // everything was found by itself
}

TEST_CASE("setup android: Unity Hub's SDK is never installed into") {
    World w;
    w.serve_android();
    make_jdk(w.tmp.path / "jdk", 17);
    w.env["JAVA_HOME"] = (w.tmp.path / "jdk").string();
    const stdfs::path unity = w.tmp.path / "unity-sdk";
    make_sdk(unity, true, false, true);
    SetupContext c = w.ctx();
    c.toolchainSearch->sdk.push_back({unity.string(), "Unity Hub"});
    const auto before = listing(unity);

    const SetupComponent status = setup_status(c, "android", false).components[0];
    CHECK(status.details.find("Unity Hub's SDK is left alone") != std::string::npos);

    SetupInstallOptions o;
    o.component = "android";
    o.acceptLicenses = true;
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(listing(unity) == before);
    CHECK(is_there(w.h() / "android" / "sdk" / "cmdline-tools" / "22.0" / "bin" / "sdkmanager"));
    for (const ProcessCall& call : w.calls)
        if (stdfs::path(call.argv[0]).filename() == "sdkmanager") CHECK(call.argv[1] == "--sdk_root=" + (w.h() / "android" / "sdk").string());
}

TEST_CASE("setup android: sdkmanager failing says what it printed") {
    World w;
    w.serve_android();
    w.sdkmanagerExit = 1;
    w.sdkmanagerOutput = "Warning: Failed to download https://dl.google.com/x. Connection refused\n";
    SetupContext c = w.ctx();
    SetupInstallOptions o;
    o.component = "android";
    o.acceptLicenses = true;
    const SetupResult r = setup_install(o, c);
    REQUIRE_FALSE(r.ok);
    CHECK(r.code == "failed");
    CHECK(r.error.message.find("Connection refused") != std::string::npos);
    CHECK(steps_of(r.report) == "jdk=installed cmdline-tools=installed licenses=installed");

    // sdkmanager still asking for the license after the user agreed and it was recorded: its tools do not know our line. Not a
    // `license_required` (asking again would change nothing): it names the file and the way out.
    World w2;
    w2.serve_android();
    w2.sdkmanagerExit = 1;
    w2.sdkmanagerOutput = "Failed: the license for platforms;android-36 is not accepted.\n";
    SetupContext c2 = w2.ctx();
    const SetupResult r2 = setup_install(o, c2);
    REQUIRE_FALSE(r2.ok);
    CHECK(r2.code == "failed");
    CHECK(r2.error.message.find("does not accept the license agreement FactorIA recorded") != std::string::npos);
    CHECK(r2.error.message.find((w2.h() / "android" / "sdk" / "licenses" / "android-sdk-license").string()) != std::string::npos);
    CHECK(r2.error.hint.find("--licenses") != std::string::npos);

    // Without the user's agreement in this run (an SDK whose license file is stale), it maps to the license error.
    World w3;
    w3.serve_android();
    make_jdk(w3.tmp.path / "jdk", 17);
    w3.env["JAVA_HOME"] = (w3.tmp.path / "jdk").string();
    make_sdk(w3.h() / "android" / "sdk", true, true, false);
    w3.sdkmanagerExit = 1;
    w3.sdkmanagerOutput = "Failed: the license for platforms;android-36 is not accepted.\n";
    SetupContext c3 = w3.ctx();
    SetupInstallOptions plain;
    plain.component = "android";
    const SetupResult r3 = setup_install(plain, c3);
    REQUIRE_FALSE(r3.ok);
    CHECK(r3.code == "license_required");
}

TEST_CASE("setup android: a JDK archive laid out flat (Linux, Windows) is installed too") {
    World w;
    w.jdkBundle = false;
    w.serve_android();
    SetupContext c = w.ctx();
    SetupInstallOptions o;
    o.component = "android";
    o.acceptLicenses = true;
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(is_there(w.h() / "android" / "jdk" / "bin" / "java"));
}

// ---------------------------------------------------------------------------------------------------------------------
// Players
// ---------------------------------------------------------------------------------------------------------------------

TEST_CASE("setup players: installs the other desktop players and the mobile libraries, then skips them") {
    World w;
    w.serve_release();
    SetupContext c = w.ctx();  // a Mac
    SetupInstallOptions o;
    o.component = "players";
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(steps_of(r.report) == "player-windows=installed player-linux=installed mobile=installed");
    CHECK(w.requested == std::vector<std::string>{kTagsUrl, package_url("FactorIA-windows-x64.zip"), package_url("FactorIA-linux-x64.tar.gz"),
                                                  package_url("FactorIA-macos-universal.tar.gz")});
    const auto& headers = w.headersOf.at(kTagsUrl);
    CHECK(std::find(headers.begin(), headers.end(), "Accept: application/vnd.github+json") != headers.end());

    const stdfs::path root = w.h() / "players" / "0.1.3";
    CHECK(is_there(root / "windows" / "factoria_player.exe"));
    CHECK(is_there(root / "linux" / "factoria_player"));
    CHECK_FALSE(is_there(root / "macos"));  // this machine's own player is the running factoria
    CHECK(is_there(root / "mobile" / "android" / "jniLibs" / "arm64-v8a" / "libfactoria_player.so"));
    CHECK(is_there(root / "mobile" / "android" / "jniLibs" / "x86_64" / "libfactoria_player.so"));
    CHECK(is_there(root / "mobile" / "ios" / "iphoneos" / "libfactoria_player_main.a"));
    CHECK(is_there(root / "mobile" / "ios" / "iphonesimulator" / "libfactoria_player_main.a"));
    CHECK_FALSE(is_there(root / ".tmp-windows"));
    CHECK_FALSE(is_there(w.h() / "staging"));
#ifndef _WIN32
    struct stat st {};
    REQUIRE(stat((root / "linux" / "factoria_player").string().c_str(), &st) == 0);
    CHECK((st.st_mode & S_IXUSR) != 0);
#endif

    // What the export asks for.
    CHECK(installed_player(c, "windows") == (root / "windows" / "factoria_player.exe").string());
    CHECK(installed_player(c, "Linux") == (root / "linux" / "factoria_player").string());
    CHECK(installed_player(c, "macos").empty());
    CHECK(installed_player(c, "android").empty());
    CHECK(installed_mobile_dir(c) == (root / "mobile").string());

    const SetupComponent status = setup_status(c, "players").components[0];
    CHECK(status.state == "installed");

    const std::size_t requested = w.requested.size();
    const SetupResult again = setup_install(o, c);
    REQUIRE_MESSAGE(again.ok, again.error.message);
    CHECK(steps_of(again.report) == "player-windows=skipped player-linux=skipped");  // the mobile libraries are there: not asked for
    CHECK_FALSE(again.report.changed);
    CHECK(w.requested.size() == requested);

    // force downloads them again.
    SetupInstallOptions forced = o;
    forced.force = true;
    forced.platforms = {"windows"};
    const SetupResult f = setup_install(forced, c);
    REQUIRE_MESSAGE(f.ok, f.error.message);
    CHECK(steps_of(f.report) == "player-windows=installed");
}

TEST_CASE("setup players: the mobile libraries next to factoria are not downloaded again") {
    World w;
    w.serve_release();
    for (const char* abi : {"arm64-v8a", "x86_64"}) put(stdfs::path(w.exeDir) / "mobile" / "android" / "jniLibs" / abi / "libfactoria_player.so");
    for (const char* sdk : {"iphoneos", "iphonesimulator"}) put(stdfs::path(w.exeDir) / "mobile" / "ios" / sdk / "libfactoria_player_main.a");
    SetupContext c = w.ctx();
    const SetupComponent before = setup_status(c, "players").components[0];
    CHECK(before.details.find("next to factoria") != std::string::npos);
    SetupInstallOptions o;
    o.component = "players";
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(steps_of(r.report) == "player-windows=installed player-linux=installed");
    CHECK(w.requested.size() == 3);  // the release, two packages
    CHECK(installed_mobile_dir(c).empty());
}

TEST_CASE("setup players: platforms narrows the install; Windows and Linux hosts") {
    World w;
    w.serve_release();
    SetupContext c = w.ctx("linux", "x64");
    SetupInstallOptions o;
    o.component = "players";
    o.platforms = {"mobile"};
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(steps_of(r.report) == "mobile=installed");
    CHECK(w.requested == std::vector<std::string>{kTagsUrl, package_url("FactorIA-macos-universal.tar.gz")});  // the macOS package holds the iOS libraries
    CHECK(is_there(w.h() / "players" / "0.1.3" / "mobile" / "android" / "jniLibs" / "arm64-v8a" / "libfactoria_player.so"));
    CHECK(is_there(w.h() / "players" / "0.1.3" / "mobile" / "ios" / "iphoneos" / "libfactoria_player_main.a"));  // on a Linux host too
    CHECK(is_there(w.h() / "players" / "0.1.3" / "mobile" / "ios" / "iphonesimulator" / "libfactoria_player_main.a"));
    CHECK_FALSE(is_there(w.h() / "players" / "0.1.3" / "macos"));  // only its mobile/ was asked for
    CHECK(installed_mobile_dir(c) == (w.h() / "players" / "0.1.3" / "mobile").string());
    // The mobile libraries are there, the other desktop players (windows, macos) are not.
    CHECK(setup_status(c, "players").components[0].state == "partial");
}

TEST_CASE("setup players: a Windows host wants the Linux and macOS players") {
    World w;
    w.serve_release();
    SetupContext c = w.ctx("windows", "x64");
    SetupInstallOptions o;
    o.component = "players";
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(steps_of(r.report) == "player-linux=installed player-macos=installed mobile=installed");
    CHECK(is_there(w.h() / "players" / "0.1.3" / "macos" / "factoria_player"));
    CHECK(w.requested.size() == 3);  // the release, linux, and macos (which also holds the mobile libraries)
}

TEST_CASE("setup players: a Windows download has Android only, so the iOS libraries are still fetched from the macOS package") {
    World w;
    w.serve_release();
    for (const char* abi : {"arm64-v8a", "x86_64"}) put(stdfs::path(w.exeDir) / "mobile" / "android" / "jniLibs" / abi / "libfactoria_player.so");
    SetupContext c = w.ctx("windows", "x64");
    const SetupComponent before = setup_status(c, "players").components[0];
    CHECK(before.details.find("iOS libraries") != std::string::npos);
    CHECK(before.details.find("mobile libraries (Android + iOS)") == std::string::npos);  // Android is there already
    SetupInstallOptions o;
    o.component = "players";
    o.platforms = {"mobile"};
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(steps_of(r.report) == "mobile=installed");
    CHECK(w.requested == std::vector<std::string>{kTagsUrl, package_url("FactorIA-macos-universal.tar.gz")});
    CHECK(is_there(w.h() / "players" / "0.1.3" / "mobile" / "ios" / "iphoneos" / "libfactoria_player_main.a"));
    // Both halves are there now: the same request downloads nothing.
    const std::size_t requested = w.requested.size();
    const SetupResult again = setup_install(o, c);
    REQUIRE_MESSAGE(again.ok, again.error.message);
    CHECK(steps_of(again.report) == "mobile=skipped");
    CHECK(w.requested.size() == requested);
}

TEST_CASE("setup players: web comes from this machine's own package, only when asked for") {
    World w;
    w.serve_release();
    SetupContext c = w.ctx("linux", "x64");
    SetupInstallOptions o;
    o.component = "players";
    o.platforms = {"web"};
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(steps_of(r.report) == "web=installed");
    CHECK(w.requested == std::vector<std::string>{kTagsUrl, package_url("FactorIA-linux-x64.tar.gz")});
    const stdfs::path web = w.h() / "players" / "0.1.3" / "web";
    CHECK(testing::read_all(web / "factoria_player.js") == "glue of FactorIA-linux-x64.tar.gz");
    CHECK(testing::read_all(web / "factoria_player.wasm") == "wasm of FactorIA-linux-x64.tar.gz");
    CHECK(installed_player(c, "web") == (web / "factoria_player.js").string());
    CHECK(installed_player(c, "windows").empty());  // nothing else came with it

    const std::size_t requested = w.requested.size();
    const SetupResult again = setup_install(o, c);
    REQUIRE_MESSAGE(again.ok, again.error.message);
    CHECK(steps_of(again.report) == "web=skipped");
    CHECK(w.requested.size() == requested);

    // Together with the other players: the host's package is fetched once more for web (it is not a default player).
    World w2;
    w2.serve_release();
    SetupContext c2 = w2.ctx("windows", "x64");
    SetupInstallOptions both;
    both.component = "players";
    both.platforms = {"windows", "web"};
    const SetupResult r2 = setup_install(both, c2);
    REQUIRE_MESSAGE(r2.ok, r2.error.message);
    CHECK(steps_of(r2.report) == "player-windows=installed web=installed");
    CHECK(w2.requested.size() == 2);  // the release, and one package for both
}

TEST_CASE("setup players: a package without web/ says the release is broken or too old") {
    World w;
    w.serve_release();
    w.unpackWeb = false;
    SetupContext c = w.ctx("linux", "x64");
    SetupInstallOptions o;
    o.component = "players";
    o.platforms = {"web"};
    const SetupResult r = setup_install(o, c);
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.message.find("web/factoria_player.js") != std::string::npos);
    CHECK(r.error.hint.find("--player") != std::string::npos);
    CHECK(installed_player(c, "web").empty());
}

TEST_CASE("setup players: a macOS package without the iOS libraries is a broken release") {
    World w;
    w.serve_release();
    w.unpackIosLibs = false;
    SetupContext c = w.ctx("linux", "x64");
    SetupInstallOptions o;
    o.component = "players";
    o.platforms = {"mobile"};
    const SetupResult r = setup_install(o, c);
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.message.find("mobile/ios") != std::string::npos);
    CHECK(r.error.hint.find("broken") != std::string::npos);
    CHECK_FALSE(is_there(w.h() / "players" / "0.1.3" / "mobile"));
}

TEST_CASE("setup players: a Mac can install a Windows player (.exe)") {
    World w;
    w.serve_release();
    SetupContext c = w.ctx();
    SetupInstallOptions o;
    o.component = "players";
    o.platforms = {"win"};
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(steps_of(r.report) == "player-windows=installed");
    CHECK(installed_player(c, "windows").size() > 4);
    CHECK(ends_with(installed_player(c, "windows"), "factoria_player.exe"));
}

TEST_CASE("setup players: a release without checksums is compared by size") {
    World w;
    Asset pkg;
    pkg.name = "FactorIA-linux-x64.tar.gz";
    pkg.content = std::string(300, 'L');
    pkg.digest = false;
    w.publish({pkg});
    SetupContext c = w.ctx();
    SetupInstallOptions o;
    o.component = "players";
    o.platforms = {"linux"};
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    REQUIRE(r.report.warnings.size() == 1);
    CHECK(r.report.warnings[0].find("no checksum") != std::string::npos);

    World w2;
    pkg.sizeDelta = 10;
    w2.publish({pkg});
    SetupContext c2 = w2.ctx();
    const SetupResult bad = setup_install(o, c2);
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.code == "checksum_mismatch");
    CHECK_FALSE(is_there(w2.h() / "players"));
}

TEST_CASE("setup players: a wrong checksum installs nothing") {
    World w;
    Asset windows;
    windows.name = "FactorIA-windows-x64.zip";
    windows.content = std::string(300, 'W');
    windows.badDigest = true;
    w.publish({windows});
    SetupContext c = w.ctx();
    SetupInstallOptions o;
    o.component = "players";
    o.platforms = {"windows"};
    const SetupResult r = setup_install(o, c);
    REQUIRE_FALSE(r.ok);
    CHECK(r.code == "checksum_mismatch");
    CHECK_FALSE(is_there(w.h() / "players"));
    CHECK_FALSE(is_there(w.h() / "staging"));
}

TEST_CASE("setup players: a development build with no release takes the newest release's players and says they will not match") {
    World w;
    w.failing[kTagsUrl] = 404;  // v0.1.3 was never released
    std::vector<Asset> assets;
    for (const char* name : {"FactorIA-windows-x64.zip", "FactorIA-linux-x64.tar.gz", "FactorIA-macos-universal.tar.gz"}) {
        Asset a;
        a.name = name;
        a.content = std::string("package ") + name + std::string(300, 'x');
        assets.push_back(a);
        w.served["https://github.com/OxtailGames/FactorIA/releases/download/v0.1.2/" + a.name] = a.content;
    }
    w.served[kLatestUrl] = release_json("v0.1.2", assets);
    SetupContext c = w.ctx();
    SetupInstallOptions o;
    o.component = "players";
    o.platforms = {"windows"};
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(steps_of(r.report) == "player-windows=installed");
    // Installed under this version's folder, where the export looks, from the newest release.
    CHECK(installed_player(c, "windows") == (w.h() / "players" / "0.1.3" / "windows" / "factoria_player.exe").string());
    REQUIRE(r.report.warnings.size() == 1);
    CHECK(r.report.warnings[0].find("development build") != std::string::npos);
    CHECK(r.report.warnings[0].find("v0.1.2") != std::string::npos);
    CHECK(r.report.warnings[0].find("fingerprint will not match") != std::string::npos);
    CHECK(r.report.warnings[0].find("allowPlayerMismatch") != std::string::npos);
    CHECK(r.report.nextSteps.back().find("--allow-player-mismatch") != std::string::npos);
    bool said = false;
    for (const std::string& line : w.said) said = said || line.find("fingerprint will not match") != std::string::npos;
    CHECK(said);  // the CLI prints it while it runs
    CHECK(std::find(w.requested.begin(), w.requested.end(), package_url("FactorIA-windows-x64.zip")) == w.requested.end());

    // A released version has no such warning.
    World w2;
    w2.serve_release();
    SetupContext c2 = w2.ctx();
    const SetupResult plain = setup_install(o, c2);
    REQUIRE_MESSAGE(plain.ok, plain.error.message);
    CHECK(plain.report.warnings.empty());

    World w3;  // and when even the newest release cannot be asked
    w3.failing[kTagsUrl] = 404;
    SetupContext c3 = w3.ctx();
    const SetupResult r3 = setup_install(o, c3);
    REQUIRE_FALSE(r3.ok);
    CHECK(r3.code == "no_release");
    CHECK(r3.error.message.find("no release v0.1.3") != std::string::npos);
    CHECK(r3.error.hint.find("--player") != std::string::npos);
}

TEST_CASE("setup players: other failures keep their kind") {
    World w;
    w.failing[kTagsUrl] = 403;  // GitHub's rate limit
    SetupContext c = w.ctx();
    SetupInstallOptions o;
    o.component = "players";
    CHECK(setup_install(o, c).code == "network");

    World w2;  // a release whose package is not uploaded (yet)
    Asset windows;
    windows.name = "FactorIA-windows-x64.zip";
    windows.content = std::string(300, 'W');
    w2.publish({windows});
    SetupContext c2 = w2.ctx();
    const SetupResult r = setup_install(o, c2);
    REQUIRE_FALSE(r.ok);
    CHECK(r.code == "no_release");
    CHECK(r.error.message.find("FactorIA-linux-x64.tar.gz") != std::string::npos);

    World w3;  // cancelled while downloading
    w3.serve_release();
    w3.cancelOn.insert(package_url("FactorIA-windows-x64.zip"));
    SetupContext c3 = w3.ctx();
    CHECK(setup_install(o, c3).code == "cancelled");

    World w4;
    SetupContext c4 = w4.ctx();
    o.platforms = {"windos"};
    const SetupResult bad = setup_install(o, c4);
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.code == "invalid_argument");
    CHECK(bad.error.message.find("Unknown platform 'windos'") != std::string::npos);
    CHECK(bad.error.hint.find("windows") != std::string::npos);
    CHECK(w4.requested.empty());
}

#ifndef _WIN32
TEST_CASE("setup players: a real tar.gz is unpacked with the system tar") {
    if (which("tar").empty()) return;
    World w;
    const std::string os =
#if defined(__APPLE__)
        "macos";
    const std::string name = "FactorIA-macos-universal.tar.gz";
#else
        "linux";
    const std::string name = "FactorIA-linux-x64.tar.gz";
#endif
    const stdfs::path pkg = w.tmp.path / "pkg";
    put(pkg / "FactorIA" / "factoria_player", "#!/bin/sh\necho player\n");
    for (const char* abi : {"arm64-v8a", "x86_64"}) put(pkg / "FactorIA" / "mobile" / "android" / "jniLibs" / abi / "libfactoria_player.so", "so");
    for (const char* sdk : {"iphoneos", "iphonesimulator"}) put(pkg / "FactorIA" / "mobile" / "ios" / sdk / "libfactoria_player_main.a", "a");
    const stdfs::path tarball = w.tmp.path / name;
    ProcessOptions po;
    po.argv = {"tar", "-czf", tarball.string(), "-C", pkg.string(), "FactorIA"};
    auto made = run_process(po);
    REQUIRE(made.ok());
    REQUIRE(made->exitCode == 0);
    const std::string bytes = testing::read_all(tarball);
    Asset a;
    a.name = name;
    a.content = bytes;
    Asset macos = a;  // the mobile libraries come from the macOS package: the same archive stands in for it on a Linux host
    macos.name = "FactorIA-macos-universal.tar.gz";
    w.publish({a, macos});

    SetupContext c;  // this machine: the real tar, the real host
    c.env = [&](const std::string& n) {
        auto it = w.env.find(n);
        return it == w.env.end() ? std::string() : it->second;
    };
    c.engineVersion = "0.1.3";
    c.executableDir = w.exeDir;
    c.download = [&](const DownloadRequest& rq) { return w.download(rq); };
    SetupInstallOptions o;
    o.component = "players";
    o.platforms = {os, "mobile"};
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    const stdfs::path player = w.h() / "players" / "0.1.3" / os / "factoria_player";
    CHECK(installed_player(c, os) == player.string());
    CHECK(testing::read_all(player) == "#!/bin/sh\necho player\n");
    struct stat st {};
    REQUIRE(stat(player.string().c_str(), &st) == 0);
    CHECK((st.st_mode & S_IXUSR) != 0);
    CHECK(is_there(w.h() / "players" / "0.1.3" / "mobile" / "android" / "jniLibs" / "x86_64" / "libfactoria_player.so"));
}
#endif

// ---------------------------------------------------------------------------------------------------------------------
// CMake
// ---------------------------------------------------------------------------------------------------------------------

#ifndef _WIN32
TEST_CASE("setup cmake: a CMake that is found is used and nothing is downloaded") {
    World w;
    const stdfs::path bin = w.tmp.path / "bin";
    put(bin / "cmake");
    w.env["PATH"] = bin.string();
    w.cmakeAt[(bin / "cmake").string()] = "cmake version 3.28.1\n\nCMake suite maintained and supported by Kitware (kitware.com/cmake).\n";
    SetupContext c = w.ctx();
    CHECK(find_cmake(c) == (bin / "cmake").string());
    const SetupComponent status = setup_status(c, "cmake").components[0];
    CHECK(status.state == "installed");
    CHECK(status.details.find("3.28.1") != std::string::npos);
    SetupInstallOptions o;
    o.component = "cmake";
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(steps_of(r.report) == "cmake=skipped");
    CHECK_FALSE(r.report.changed);
    CHECK(w.requested.empty());
    CHECK_FALSE(is_there(w.home));
}

TEST_CASE("setup cmake: a CMake that is too old does not count; force installs next to a good one") {
    World w;
    const stdfs::path bin = w.tmp.path / "bin";
    put(bin / "cmake");
    w.env["PATH"] = bin.string();
    w.cmakeAt[(bin / "cmake").string()] = "cmake version 3.20.0\n";
    SetupContext c = w.ctx();
    CHECK(find_cmake(c).empty());
    const SetupComponent status = setup_status(c, "cmake").components[0];
    CHECK(status.state == "missing");
    REQUIRE(status.problems.size() == 1);
    CHECK(status.problems[0].find("older than 3.24") != std::string::npos);
    CHECK(status.installSizeMb > 0);

    // A CMake that is there and good, but force is set.
    w.cmakeAt[(bin / "cmake").string()] = "cmake version 3.31.0\n";
    const std::string archive = "cmake-3.31.6-macos-universal.tar.gz";
    w.serve_cmake(archive, std::string(600, 'C'));
    const stdfs::path installed = w.h() / "tools" / "cmake" / "CMake.app" / "Contents" / "bin" / "cmake";
    w.cmakeAt[installed.string()] = "cmake version 3.31.6\n";
    SetupInstallOptions o;
    o.component = "cmake";
    o.force = true;
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(steps_of(r.report) == "cmake=installed");
    CHECK(r.report.steps[0].path == installed.string());
    CHECK(is_there(installed));
    REQUIRE(r.report.warnings.size() == 1);
    CHECK(r.report.warnings[0].find("comes first") != std::string::npos);
    CHECK_FALSE(is_there(w.h() / "staging"));
}

TEST_CASE("setup cmake: installs Kitware's CMake when none is found, and find_cmake then finds it") {
    World w;
    const std::string archive = "cmake-3.31.6-macos-universal.tar.gz";
    w.serve_cmake(archive, std::string(600, 'C'));
    const stdfs::path installed = w.h() / "tools" / "cmake" / "CMake.app" / "Contents" / "bin" / "cmake";
    w.cmakeAt[installed.string()] = "cmake version 3.31.6\n";
    SetupContext c = w.ctx();
    CHECK(find_cmake(c).empty());
    SetupInstallOptions o;
    o.component = "cmake";
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(steps_of(r.report) == "cmake=installed");
    CHECK(r.report.changed);
    CHECK(w.requested == std::vector<std::string>{std::string(kCmakeBase) + "cmake-3.31.6-SHA-256.txt", std::string(kCmakeBase) + archive});
    CHECK(find_cmake(c) == installed.string());
    CHECK(setup_status(c, "cmake").components[0].state == "installed");

    // Installed: the next run only looks.
    const std::size_t requested = w.requested.size();
    const SetupResult again = setup_install(o, c);
    REQUIRE_MESSAGE(again.ok, again.error.message);
    CHECK(steps_of(again.report) == "cmake=skipped");
    CHECK(w.requested.size() == requested);
}

TEST_CASE("setup cmake: a download that does not match Kitware's checksum installs nothing") {
    World w;
    const std::string archive = "cmake-3.31.6-macos-universal.tar.gz";
    w.serve_cmake(archive, std::string(600, 'C'), std::string(600, 'D'));  // the list is of other bytes
    SetupContext c = w.ctx();
    SetupInstallOptions o;
    o.component = "cmake";
    const SetupResult r = setup_install(o, c);
    REQUIRE_FALSE(r.ok);
    CHECK(r.code == "checksum_mismatch");
    CHECK_FALSE(is_there(w.h() / "tools"));
    CHECK_FALSE(is_there(w.h() / "staging"));

    World w2;  // the archive is not in the checksum list at all
    w2.serve_cmake("cmake-3.31.6-other.tar.gz", "zzz");
    w2.served[std::string(kCmakeBase) + archive] = "body";
    SetupContext c2 = w2.ctx();
    const SetupResult r2 = setup_install(o, c2);
    REQUIRE_FALSE(r2.ok);
    CHECK(r2.code == "failed");
    CHECK(r2.error.message.find(archive) != std::string::npos);
}
#endif

TEST_CASE("setup cmake: other systems have nothing to do unless forced") {
    World w;
    SetupContext c = w.ctx("linux", "x64");
    const SetupComponent status = setup_status(c, "cmake").components[0];
    CHECK(status.state == "unsupported");
    CHECK_FALSE(status.canInstall);
    SetupInstallOptions o;
    o.component = "cmake";
    const SetupResult r = setup_install(o, c);
    REQUIRE_FALSE(r.ok);
    CHECK(r.code == "unsupported");
    CHECK(r.error.hint.find("--force") != std::string::npos);
    CHECK(w.requested.empty());

    const std::string archive = "cmake-3.31.6-linux-x86_64.tar.gz";
    w.serve_cmake(archive, std::string(600, 'C'));
    const stdfs::path installed = w.h() / "tools" / "cmake" / "bin" / "cmake";
    w.cmakeAt[installed.string()] = "cmake version 3.31.6\n";
    o.force = true;
    const SetupResult forced = setup_install(o, c);
    REQUIRE_MESSAGE(forced.ok, forced.error.message);
    CHECK(is_there(installed));
}

// ---------------------------------------------------------------------------------------------------------------------
// Xcode
// ---------------------------------------------------------------------------------------------------------------------

TEST_CASE("setup xcode: a complete Xcode is installed; nothing is run to install it") {
    World w;
    w.developerDir = "/Applications/Xcode.app/Contents/Developer";
    w.xcodeVersion = "Xcode 27.1\nBuild version 27A1\n";
    w.sdks = "iOS SDKs:\n\tiOS 27.1    -sdk iphoneos27.1\n\niOS Simulator SDKs:\n\tSimulator - iOS 27.1    -sdk iphonesimulator27.1\n";
    SetupContext c = w.ctx();
    const SetupComponent status = setup_status(c, "xcode").components[0];
    CHECK(status.state == "installed");
    CHECK(status.details.find("Xcode 27.1") != std::string::npos);
    SetupInstallOptions o;
    o.component = "xcode";
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(steps_of(r.report) == "xcode=skipped");
    for (const ProcessCall& call : w.calls) CHECK(call.argv[0] != "open");
}

TEST_CASE("setup xcode: a missing Xcode opens the App Store and lists the steps, without sudo") {
    World w;
    w.developerDir = "/Library/Developer/CommandLineTools";
    SetupContext c = w.ctx();
    const SetupComponent status = setup_status(c, "xcode").components[0];
    CHECK(status.state == "missing");
    CHECK(status.details.find("Command Line Tools") != std::string::npos);
    SetupInstallOptions o;
    o.component = "xcode";
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(steps_of(r.report) == "xcode=guidance");
    CHECK_FALSE(r.report.changed);
    bool opened = false;
    for (const ProcessCall& call : w.calls) {
        if (call.argv[0] == "open") {
            opened = true;
            REQUIRE(call.argv.size() == 2);
            CHECK(call.argv[1] == "macappstore://apps.apple.com/app/id497799835");
        }
        for (const std::string& a : call.argv) CHECK(a != "sudo");
    }
    CHECK(opened);
    REQUIRE_FALSE(r.report.nextSteps.empty());
    bool selects = false;
    for (const std::string& s : r.report.nextSteps) selects |= s.find("sudo xcode-select -s") != std::string::npos;
    CHECK(selects);  // the user does it: it asks for a password
}

TEST_CASE("setup xcode: Xcode that the command-line tools do not point at is partial") {
    World w;
    w.developerDir = "/Library/Developer/CommandLineTools";
    stdfs::create_directories(stdfs::path(w.apps) / "Xcode.app");
    SetupContext c = w.ctx();
    const SetupComponent status = setup_status(c, "xcode").components[0];
    CHECK(status.state == "partial");
    REQUIRE_FALSE(status.problems.empty());
    CHECK(status.problems[0].find("xcode-select -s") != std::string::npos);
    SetupInstallOptions o;
    o.component = "xcode";
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(steps_of(r.report) == "xcode=guidance");
    for (const ProcessCall& call : w.calls) CHECK(call.argv[0] != "open");  // already installed: no store page
}

TEST_CASE("setup xcode: only exists on macOS") {
    World w;
    SetupContext c = w.ctx("windows", "x64");
    CHECK(setup_status(c, "xcode").components[0].state == "unsupported");
    SetupInstallOptions o;
    o.component = "xcode";
    const SetupResult r = setup_install(o, c);
    REQUIRE_FALSE(r.ok);
    CHECK(r.code == "unsupported");
    CHECK(w.calls.empty());
}

// ---------------------------------------------------------------------------------------------------------------------
// Dispatch, commands
// ---------------------------------------------------------------------------------------------------------------------

TEST_CASE("setup: an unknown component is an invalid_argument with a suggestion; a cancelled setup does not start") {
    World w;
    SetupContext c = w.ctx();
    SetupInstallOptions o;
    o.component = "andriod";
    const SetupResult r = setup_install(o, c);
    REQUIRE_FALSE(r.ok);
    CHECK(r.code == "invalid_argument");
    CHECK(r.error.hint.find("android") != std::string::npos);

    std::atomic<bool> cancel{true};
    c.cancel = &cancel;
    o.component = "android";
    o.acceptLicenses = true;
    const SetupResult cancelled = setup_install(o, c);
    REQUIRE_FALSE(cancelled.ok);
    CHECK(cancelled.code == "cancelled");
    CHECK(w.requested.empty());
}

TEST_CASE("setup: the commands are registered with the documentation an AI needs") {
    CommandRegistry reg;
    register_setup_commands(reg);
    const CommandInfo* status = reg.info("setup.status");
    const CommandInfo* install = reg.info("setup.install");
    REQUIRE(status);
    REQUIRE(install);
    CHECK(status->category == "setup");
    CHECK(install->category == "setup");
    CHECK(status->readOnly);
    CHECK_FALSE(install->readOnly);
    CHECK(install->description.find("acceptLicenses") != std::string::npos);
    CHECK(install->description.find("license_required") != std::string::npos);
    CHECK(install->description.find("ask the user") != std::string::npos);
    CHECK(status->description.find("licenses") != std::string::npos);
    for (const CommandInfo* info : {status, install}) {
        for (const auto& [name, prop] : info->inputSchema.at("properties").items()) {
            INFO(info->name << "." << name);
            CHECK(prop.contains("description"));
        }
    }
    CHECK(install->inputSchema.at("required")[0].get<std::string>() == "component");

    // Bad input is refused before anything looks at this computer.
    CHECK_FALSE(reg.call("setup.install", Json::object({{"component", "andriod"}})).ok);
    CHECK_FALSE(reg.call("setup.install", Json::object()).ok);
    CHECK_FALSE(reg.call("setup.status", Json::object({{"component", "andriod"}})).ok);
}

// ---------------------------------------------------------------------------------------------------------------------
// curl
// ---------------------------------------------------------------------------------------------------------------------

namespace {

struct FakeCurl {
    int exitCode = 0;
    std::string stderrText;
    bool cancelled = false;
    bool spawnFails = false;
    bool writesFile = true;
    ProcessOptions seen;
    ProcessRunner runner() {
        return [this](const ProcessOptions& o) -> Result<ProcessResult> {
            seen = o;
            if (spawnFails) return make_error("cannot start curl");
            ProcessResult r;
            r.exitCode = exitCode;
            r.stderrText = stderrText;
            r.cancelled = cancelled;
            if (writesFile && exitCode == 0 && !cancelled)
                for (std::size_t i = 0; i + 1 < o.argv.size(); ++i)
                    if (o.argv[i] == "-o") testing::write_all(o.argv[i + 1], "downloaded");
            return r;
        };
    }
};

DownloadRequest request(const World& w, const std::string& url = "https://dl.google.com/android/repository/x.zip") {
    DownloadRequest rq;
    rq.url = url;
    rq.destination = w.tmp.sub("dl/file.bin");
    rq.what = "the test file";
    return rq;
}

}  // namespace

TEST_CASE("curl downloader: the command line and the result of a good download") {
    if (which("curl").empty()) return;
    World w;
    FakeCurl curl;
    DownloadRequest rq = request(w);
    rq.headers = {"Accept: application/json"};
    const DownloadResult r = curl_downloader(curl.runner())(rq);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(testing::read_all(rq.destination) == "downloaded");
    CHECK_FALSE(is_there(rq.destination + ".part"));
    const auto& argv = curl.seen.argv;
    CHECK(stdfs::path(argv[0]).stem() == "curl");
    CHECK(std::find(argv.begin(), argv.end(), "-fL") != argv.end());
    CHECK(std::find(argv.begin(), argv.end(), "--proto-redir") != argv.end());
    CHECK(std::find(argv.begin(), argv.end(), "=https") != argv.end());
    CHECK(std::find(argv.begin(), argv.end(), "Accept: application/json") != argv.end());
    CHECK(argv.back() == rq.url);
    const auto o = std::find(argv.begin(), argv.end(), "-o");
    REQUIRE(o != argv.end());
    CHECK(*(o + 1) == rq.destination + ".part");  // written aside, renamed when complete
}

TEST_CASE("curl downloader: failures say what happened and how to fix it") {
    if (which("curl").empty()) return;
    World w;
    {
        FakeCurl curl;
        curl.exitCode = 22;
        curl.stderrText = "curl: (22) The requested URL returned error: 404\n";
        const DownloadResult r = curl_downloader(curl.runner())(request(w));
        REQUIRE_FALSE(r.ok);
        CHECK(r.httpStatus == 404);
        CHECK(r.error.message.find("HTTP 404") != std::string::npos);
        CHECK(r.error.hint.find("Update FactorIA") != std::string::npos);
        CHECK_FALSE(is_there(w.tmp.sub("dl/file.bin")));
        CHECK_FALSE(is_there(w.tmp.sub("dl/file.bin.part")));
    }
    {
        FakeCurl curl;
        curl.exitCode = 22;
        curl.stderrText = "curl: (22) The requested URL returned error: 403\n";
        const DownloadResult r = curl_downloader(curl.runner())(request(w, "https://api.github.com/repos/x/y/releases/latest"));
        REQUIRE_FALSE(r.ok);
        CHECK(r.httpStatus == 403);
        CHECK(r.error.hint.find("60 anonymous requests") != std::string::npos);
    }
    {
        FakeCurl curl;  // curl 8 with --retry reports an HTTP error as 56, not 22: the status is read from the text
        curl.exitCode = 56;
        curl.stderrText = "curl: (56) The requested URL returned error: 404\n";
        const DownloadResult r = curl_downloader(curl.runner())(request(w));
        REQUIRE_FALSE(r.ok);
        CHECK(r.httpStatus == 404);
        CHECK(r.error.message.find("HTTP 404") != std::string::npos);
    }
    {
        FakeCurl curl;
        curl.exitCode = 56;
        curl.stderrText = "curl: (56) Recv failure: Connection reset by peer\n";
        const DownloadResult r = curl_downloader(curl.runner())(request(w));
        REQUIRE_FALSE(r.ok);
        CHECK(r.httpStatus == 0);
        CHECK(r.error.message.find("broke off") != std::string::npos);
    }
    {
        FakeCurl curl;
        curl.exitCode = 6;
        const DownloadResult r = curl_downloader(curl.runner())(request(w, "https://example.org/a"));
        REQUIRE_FALSE(r.ok);
        CHECK(r.error.message.find("cannot resolve the address example.org") != std::string::npos);
        CHECK(r.error.hint.find("internet connection") != std::string::npos);
    }
    {
        FakeCurl curl;
        curl.exitCode = 28;
        const DownloadResult r = curl_downloader(curl.runner())(request(w));
        REQUIRE_FALSE(r.ok);
        CHECK(r.error.message.find("timed out") != std::string::npos);
    }
    {
        FakeCurl curl;
        curl.exitCode = 60;
        curl.stderrText = "curl: (60) SSL certificate problem: certificate has expired\n";
        const DownloadResult r = curl_downloader(curl.runner())(request(w));
        REQUIRE_FALSE(r.ok);
        CHECK(r.error.message.find("secure connection") != std::string::npos);
        CHECK(r.error.hint.find("date and time") != std::string::npos);
    }
    {
        FakeCurl curl;
        curl.cancelled = true;
        const DownloadResult r = curl_downloader(curl.runner())(request(w));
        REQUIRE_FALSE(r.ok);
        CHECK(r.cancelled);
    }
    {
        FakeCurl curl;
        curl.spawnFails = true;
        const DownloadResult r = curl_downloader(curl.runner())(request(w));
        REQUIRE_FALSE(r.ok);
        CHECK(r.error.message.find("Cannot download the test file") != std::string::npos);
    }
}

#ifndef _WIN32
TEST_CASE("curl downloader: the real curl copies a file:// URL, with progress, and fails clearly for a missing one") {
    if (which("curl").empty()) return;
    World w;
    const std::string body(3 << 20, 'z');
    put(w.tmp.path / "source.bin", body);
    DownloadRequest rq;
    rq.url = "file://" + (w.tmp.path / "source.bin").string();
    rq.destination = w.tmp.sub("out/copy.bin");
    rq.what = "the local file";
    rq.expectedBytes = body.size();
    std::atomic<int> reports{0};
    rq.onBytes = [&](std::uint64_t) { ++reports; };
    const DownloadResult r = curl_downloader()(rq);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(testing::read_all(rq.destination) == body);
    CHECK_FALSE(is_there(rq.destination + ".part"));

    DownloadRequest missing = rq;
    missing.url = "file://" + (w.tmp.path / "nope.bin").string();
    missing.destination = w.tmp.sub("out/none.bin");
    const DownloadResult bad = curl_downloader()(missing);
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error.message.find("Downloading the local file failed") != std::string::npos);
    CHECK_FALSE(is_there(missing.destination));
    CHECK_FALSE(is_there(missing.destination + ".part"));
}
#endif

// ---------------------------------------------------------------------------------------------------------------------
// setup webplayer: the web player built from the checkout (development builds)
// ---------------------------------------------------------------------------------------------------------------------

namespace {

// A checkout `setup webplayer` accepts, a PATH with a CMake, and an Emscripten SDK folder.
void make_checkout(World& w) {
    w.sourceRoot = (w.tmp.path / "checkout").string();
    put(w.tmp.path / "checkout" / "CMakePresets.json", "{}");
    stdfs::create_directories(w.tmp.path / "checkout" / "engine");
    const stdfs::path bin = w.tmp.path / "bin";
    put(bin / "cmake");
    w.env["PATH"] = bin.string();
    w.cmakeAt[(bin / "cmake").string()] = "cmake version 3.31.0\n";
}

stdfs::path make_emsdk(const stdfs::path& dir, const std::string& version) {
    put(dir / "upstream" / "emscripten" / "cmake" / "Modules" / "Platform" / "Emscripten.cmake");
    put(dir / "upstream" / "emscripten" / "emscripten-version.txt", version + "\n");
    put(dir / "emsdk_env.sh");
    return dir;
}

// What the `web-release` build leaves behind: the player of `fingerprint`.
void build_player(const World& w, const std::string& fingerprint) {
    const stdfs::path dir = stdfs::path(w.sourceRoot) / "build" / "web-release" / "player";
    put(dir / "factoria_player.js", "glue");
    put(dir / "factoria_player.wasm", "wasm FA-BUILD-FINGERPRINT:" + fingerprint + ";");
}

}  // namespace

TEST_CASE("setup webplayer: a factoria without its checkout cannot build one and says where the web player comes from") {
    World w;  // the default source folder does not exist
    SetupContext c = w.ctx();
    const SetupComponent st = setup_status(c, "webplayer").components[0];
    CHECK(st.state == "unsupported");
    CHECK_FALSE(st.canInstall);
    CHECK(st.details.find("players --platforms web") != std::string::npos);
    SetupInstallOptions o;
    o.component = "webplayer";
    const SetupResult r = setup_install(o, c);
    REQUIRE_FALSE(r.ok);
    CHECK(r.code == "unsupported");
    CHECK(r.error.hint.find("setup players --platforms web") != std::string::npos);
    CHECK(w.calls.empty());
}

TEST_CASE("setup webplayer: builds with the Emscripten SDK it finds, through a shell that loads the SDK") {
    World w;
    make_checkout(w);
    const stdfs::path emsdk = make_emsdk(w.tmp.path / "user" / "emsdk", "6.0.10");  // ~/emsdk
    SetupContext c = w.ctx();
    CHECK(setup_status(c, "webplayer").components[0].state == "missing");
    std::vector<std::string> argv;
    std::map<std::string, std::string> env;
    w.onOther = [&](const ProcessOptions& o) -> Result<ProcessResult> {
        REQUIRE(stdfs::path(o.argv[0]).filename().string() == "bash");
        argv = o.argv;
        env = o.env;
        CHECK(o.workingDir == w.sourceRoot);
        if (o.onStdoutLine) {
            o.onStdoutLine("[1/10] Building CXX object a.o");
            o.onStdoutLine("[10/10] Linking CXX executable player/factoria_player.js");
        }
        build_player(w, build_fingerprint());
        ProcessResult r;
        r.exitCode = 0;
        return r;
    };
    SetupInstallOptions o;
    o.component = "webplayer";
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(steps_of(r.report) == "emsdk=skipped web-player=installed");
    CHECK(r.report.steps[0].detail.find("~/emsdk") != std::string::npos);
    REQUIRE(argv.size() == 3);
    CHECK(argv[2].find("emsdk_env.sh") != std::string::npos);
    CHECK(argv[2].find("--preset web-release") != std::string::npos);
    CHECK(argv[2].find("--build --preset web-release") != std::string::npos);
    CHECK(env["EMSDK"] == emsdk.string());
    CHECK(w.requested.empty());  // nothing downloaded: the SDK was there
    CHECK(r.report.warnings.empty());
    CHECK(r.report.paths[0].second == (stdfs::path(w.sourceRoot) / "build" / "web-release" / "player").string());
    bool progress = false;
    for (const std::string& line : w.said) progress = progress || line.find("10/10") != std::string::npos;
    CHECK(progress);
    CHECK(setup_status(c, "webplayer").components[0].state == "installed");

    // A player of this build is not built again, unless forced.
    w.calls.clear();
    const SetupResult again = setup_install(o, c);
    REQUIRE_MESSAGE(again.ok, again.error.message);
    CHECK(steps_of(again.report) == "web-player=skipped");
    CHECK(w.calls.empty());
    o.force = true;
    CHECK(setup_install(o, c).ok);
    CHECK_FALSE(w.calls.empty());
}

TEST_CASE("setup webplayer: a player of another commit is built again; an SDK of another version only warns") {
    World w;
    make_checkout(w);
    w.env["EMSDK"] = make_emsdk(w.tmp.path / "sdk", "5.0.0").string();
    build_player(w, "0123456789ab");
    SetupContext c = w.ctx();
    if (std::string(build_fingerprint()) != "unknown") {
        const SetupComponent st = setup_status(c, "webplayer").components[0];
        CHECK(st.state == "partial");
        CHECK(st.problems[0].find("fingerprint mismatch") != std::string::npos);
    }
    int builds = 0;
    w.onOther = [&](const ProcessOptions&) -> Result<ProcessResult> {
        ++builds;
        build_player(w, build_fingerprint());
        ProcessResult r;
        r.exitCode = 0;
        return r;
    };
    SetupInstallOptions o;
    o.component = "webplayer";
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    if (std::string(build_fingerprint()) != "unknown") CHECK(builds == 1);
    REQUIRE(r.report.warnings.size() == 1);
    CHECK(r.report.warnings[0].find("5.0.0") != std::string::npos);
    CHECK(r.report.warnings[0].find("6.0.10") != std::string::npos);
}

TEST_CASE("setup webplayer: without an SDK it fetches the pinned Emscripten into the checkout's .cache") {
    World w;
    make_checkout(w);
    const std::string url = "https://github.com/emscripten-core/emsdk/archive/refs/heads/main.tar.gz";
    w.served[url] = std::string(200, 'E');
    SetupContext c = w.ctx();
    CHECK(setup_status(c, "webplayer").components[0].details.find("fetches Emscripten 6.0.10") != std::string::npos);
    const stdfs::path target = stdfs::path(w.sourceRoot) / ".cache" / "emsdk";
    std::vector<std::vector<std::string>> ran;
    w.onOther = [&](const ProcessOptions& o) -> Result<ProcessResult> {
        ran.push_back(o.argv);
        const std::string exe = stdfs::path(o.argv[0]).filename().string();
        if (exe == "emsdk") {
            CHECK(o.argv[2] == "6.0.10");
            if (o.argv[1] == "activate") make_emsdk(target, "6.0.10");
        } else {
            CHECK(exe == "bash");
            build_player(w, build_fingerprint());
        }
        ProcessResult r;
        r.exitCode = 0;
        return r;
    };
    SetupInstallOptions o;
    o.component = "webplayer";
    const SetupResult r = setup_install(o, c);
    REQUIRE_MESSAGE(r.ok, r.error.message);
    CHECK(steps_of(r.report) == "emsdk=installed web-player=installed");
    CHECK(w.requested == std::vector<std::string>{url});
    REQUIRE(ran.size() == 3);
    CHECK(ran[0][1] == "install");
    CHECK(ran[1][1] == "activate");
    CHECK(is_there(target / "upstream" / "emscripten" / "cmake" / "Modules" / "Platform" / "Emscripten.cmake"));
    CHECK_FALSE(is_there(w.h() / "staging"));
    // The SDK of .cache is found the next time: no second download.
    w.requested.clear();
    o.force = true;
    REQUIRE(setup_install(o, c).ok);
    CHECK(w.requested.empty());
}

TEST_CASE("setup webplayer: a failed build says what the build printed; a missing CMake is named") {
    World w;
    make_checkout(w);
    w.env["EMSDK"] = make_emsdk(w.tmp.path / "sdk", "6.0.10").string();
    w.onOther = [&](const ProcessOptions& o) -> Result<ProcessResult> {
        if (o.onStdoutLine) o.onStdoutLine("FAILED: engine/x.cpp.o");
        ProcessResult r;
        r.exitCode = 1;
        r.stderrText = "error: no such header\n";
        return r;
    };
    SetupContext c = w.ctx();
    SetupInstallOptions o;
    o.component = "webplayer";
    const SetupResult r = setup_install(o, c);
    REQUIRE_FALSE(r.ok);
    CHECK(r.code == "failed");
    CHECK(r.error.message.find("exit code 1") != std::string::npos);
    CHECK(r.error.message.find("no such header") != std::string::npos);
    CHECK(r.error.hint.find("Ninja") != std::string::npos);

    World w2;
    make_checkout(w2);
    w2.env["PATH"] = "";
    w2.cmakeAt.clear();
    SetupContext c2 = w2.ctx("linux", "x64");  // no Homebrew paths on this host
    const SetupResult r2 = setup_install(o, c2);
    REQUIRE_FALSE(r2.ok);
    CHECK(r2.error.message.find("No CMake 3.24") != std::string::npos);
}

TEST_CASE("setup webplayer: the pinned Emscripten version is the one CI, the releases and BUILDING.md use") {
    const stdfs::path root = FA_REPO_ROOT;
    for (const char* file : {".github/workflows/ci.yml", ".github/workflows/release.yml"}) {
        INFO(file);
        CHECK(testing::read_all((root / file).string()).find(std::string("EMSDK_VERSION: ") + kSetupEmscriptenVersion) != std::string::npos);
    }
    CHECK(testing::read_all((root / "docs" / "BUILDING.md").string()).find(std::string("emsdk install ") + kSetupEmscriptenVersion) != std::string::npos);
}

// ---------------------------------------------------------------------------------------------------------------------
// The real listings (network): FACTORIA_SETUP_ONLINE_TESTS=1 ctest -R tooling. They download a few hundred KB and install
// nothing: they catch Google, Adoptium or GitHub changing the format `factoria setup` reads.
// ---------------------------------------------------------------------------------------------------------------------

TEST_CASE("setup online: the real Android SDK repository, Adoptium and GitHub listings still parse") {
    const char* flag = std::getenv("FACTORIA_SETUP_ONLINE_TESTS");
    if (!flag || std::string(flag) != "1") return;
    testing::TempDir tmp;
    SetupContext c;  // the real downloader; folders of this test only, so the computer's own SDK does not count
    c.home = tmp.sub("fhome");
    c.engineVersion = "9.9.9";  // no such release
    const std::string user = tmp.sub("user");
    c.env = [user](const std::string& n) { return n == "HOME" || n == "USERPROFILE" ? user : std::string(); };
    AndroidToolchainSearch search;
    search.env = c.env;
    search.sdk.push_back({tmp.sub("fhome/android/sdk"), "FactorIA"});
    search.jdk.push_back({tmp.sub("fhome/android/jdk"), "FactorIA"});
    c.toolchainSearch = search;

    // Google: the license and the command-line tools of every host.
    for (const auto& [os, arch] : std::vector<std::pair<std::string, std::string>>{{"macos", "aarch64"}, {"macos", "x64"}, {"windows", "x64"}, {"linux", "x64"}}) {
        INFO(os << "/" << arch);
        SetupContext host = c;
        host.host = os;
        host.hostArch = arch;
        const SetupComponent a = setup_status(host, "android", true).components[0];
        const std::string why = a.problems.empty() ? std::string("no problem listed") : a.problems.back();
        REQUIRE_MESSAGE(a.licenses.size() == 1, why);
        CHECK(a.licenses[0].text.size() > 5000);
    }

    // Google again, the listing itself: the pinned classic tools are still offered (not obsolete) for every host, so the install
    // does not fall back to `latest`; and the license text hashes to the line every SDK holds in licenses/android-sdk-license (the
    // text of January 16, 2019: a new text would change it: check with `sdkmanager --licenses` of a classic revision, then update).
    {
        const stdfs::path dir = tmp.path / "google";
        stdfs::create_directories(dir);
        DownloadRequest rq;
        rq.url = kSdkRepositoryUrl;
        rq.destination = (dir / "repository2-3.xml").string();
        rq.what = "the Android SDK package list";
        const DownloadResult d = curl_downloader()(rq);
        REQUIRE_MESSAGE(d.ok, d.error.message);
        const std::string xml = testing::read_all(rq.destination);
        for (const auto& [os, arch] : std::vector<std::pair<std::string, std::string>>{{"macos", "aarch64"}, {"macos", "x64"}, {"windows", "x64"}, {"linux", "x64"}}) {
            INFO(os << "/" << arch);
            auto repo = parse_sdk_repository(xml, os, arch);
            REQUIRE_MESSAGE(repo.ok(), repo.error().message);
            CHECK_MESSAGE(repo->cmdlineToolsPinned, (repo->warnings.empty() ? std::string("not pinned") : repo->warnings[0]));
            CHECK(repo->cmdlineToolsPackage == kSetupAndroidCmdlineTools);
            CHECK(repo->warnings.empty());
            CHECK(sdk_license_hash(repo->license.text) == "24333f8a63b6825ea9c5514f83c2829b004d1fee");
        }
    }

    // Adoptium: a JDK 21 archive for every host.
    std::string text;
    for (const char* query : {"os=mac&architecture=aarch64", "os=mac&architecture=x64", "os=windows&architecture=x64", "os=linux&architecture=x64"}) {
        INFO(query);
        const stdfs::path dir = tmp.path / "adoptium";
        stdfs::create_directories(dir);
        DownloadRequest rq;
        rq.url = std::string("https://api.adoptium.net/v3/assets/latest/21/hotspot?") + query + "&image_type=jdk&vendor=eclipse";
        rq.destination = (dir / "listing.json").string();
        rq.what = "the JDK listing";
        const DownloadResult d = curl_downloader()(rq);
        REQUIRE_MESSAGE(d.ok, d.error.message);
        auto json = parse_json(testing::read_all(rq.destination), "adoptium");
        REQUIRE(json.ok());
        auto jdk = parse_adoptium_assets(*json);
        REQUIRE_MESSAGE(jdk.ok(), jdk.error().message);
        CHECK(jdk->sha256.size() == 64);
        CHECK(jdk->size > (50u << 20));
    }

    // GitHub: the newest release is listed with the packages a development build falls back to (releases/latest).
    {
        const stdfs::path dir = tmp.path / "github";
        stdfs::create_directories(dir);
        DownloadRequest rq;
        rq.url = "https://api.github.com/repos/" + std::string(kSetupReleaseRepo) + "/releases/latest";
        rq.destination = (dir / "latest.json").string();
        rq.what = "the newest release";
        rq.headers = {"Accept: application/vnd.github+json", "X-GitHub-Api-Version: 2022-11-28"};
        const DownloadResult d = curl_downloader()(rq);
        REQUIRE_MESSAGE(d.ok, d.error.message);
        auto json = parse_json(testing::read_all(rq.destination), "latest release");
        REQUIRE(json.ok());
        auto release = parse_github_release(*json);
        REQUIRE_MESSAGE(release.ok(), release.error().message);
        CHECK(release->tag.size() > 1);
        CHECK(release->find("FactorIA-linux-x64.tar.gz") != nullptr);
    }
}
