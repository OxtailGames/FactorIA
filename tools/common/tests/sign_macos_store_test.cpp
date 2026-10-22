// sign.macos with distribution "appStore" (docs/EXPORTING.md, "Mac App Store"): the command lines, the provisioning profile checks and
// every error, with a fake process runner on any computer. The last test sandboxes and runs a real player, and only on a Mac.
#include <doctest.h>

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <map>

#include "fa/core/process.h"
#include "fa/core/strings.h"
#include "fa/tooling/export.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/sign.h"
#include "../src/plist_read.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

constexpr const char* kDistribution = "Apple Distribution: Ada Lovelace (ABCDE12345)";
constexpr const char* kInstaller = "3rd Party Mac Developer Installer: Ada Lovelace (ABCDE12345)";

bool has_text(const std::string& haystack, const std::string& needle) { return haystack.find(needle) != std::string::npos; }
bool any_has(const std::vector<std::string>& v, const std::string& needle) {
    return std::any_of(v.begin(), v.end(), [&](const std::string& s) { return has_text(s, needle); });
}

ExportEnvLookup env_of(std::map<std::string, std::string> vars) {
    return [vars = std::move(vars)](const std::string& name) {
        auto it = vars.find(name);
        return it == vars.end() ? std::string() : it->second;
    };
}

void write_macho(const stdfs::path& p, std::uint32_t filetype = 2) {
    std::string h("\xcf\xfa\xed\xfe\x0c\x00\x00\x01\x00\x00\x00\x00", 12);
    h.push_back(static_cast<char>(filetype));
    h += std::string(47, '\0');
    testing::write_all(p, h);
}

// The XML a signed .provisionprofile holds (the CMS envelope around it is not needed to read it).
std::string profile_xml(const std::string& appId = "ABCDE12345.com.example.spacedodge", const std::string& platform = "OSX",
                        const std::string& extra = "", const std::string& expires = "2099-01-01T00:00:00Z") {
    return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
           "<plist version=\"1.0\"><dict>\n<key>Name</key><string>Space Dodge Store</string>\n<key>Platform</key><array><string>" + platform + "</string></array>\n"
           "<key>ExpirationDate</key><date>" + expires + "</date>\n<key>TeamIdentifier</key><array><string>ABCDE12345</string></array>\n" + extra +
           "<key>Entitlements</key><dict><key>com.apple.application-identifier</key><string>" + appId + "</string>"
           "<key>com.apple.developer.team-identifier</key><string>ABCDE12345</string></dict>\n</dict></plist>\n";
}

struct Game {
    testing::TempDir tmp;
    std::string proj, out, profile;
    stdfs::path app;

    explicit Game(const std::string& macosSettings = "") {
        proj = tmp.sub("proj");
        ScaffoldOptions so;
        so.name = "Space Dodge";
        so.id = "com.example.spacedodge";
        auto created = create_project(proj, "2d-platformer", so);
        REQUIRE_MESSAGE(created.ok(), (created.ok() ? "" : created.error().to_string()));
        if (!macosSettings.empty()) {  // "export": {"macos": ...} written into factoria.json
            auto j = Json::parse(testing::read_all(stdfs::path(proj) / "factoria.json"));
            j["export"]["macos"] = Json::parse(macosSettings);
            testing::write_all(stdfs::path(proj) / "factoria.json", j.dump(2));
        }
        testing::write_all(tmp.sub("fake_player/factoria_player"), "#!/bin/sh\nexit 0\n");
        out = tmp.sub("out");
        ExportOptions o;
        o.projectDir = proj;
        o.platform = "macos";
        o.outDir = out;
        o.playerBinary = tmp.sub("fake_player/factoria_player");
        auto r = export_project(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        app = stdfs::path(r->outputDir) / "Space Dodge.app";
        profile = tmp.sub("store.provisionprofile");
        testing::write_all(profile, std::string("\x30\x82\x0f\x00 CMS envelope ", 18) + profile_xml());
    }

    std::string pkg_str() const { return (app.parent_path().parent_path() / "space-dodge-macos.pkg").generic_string(); }

    SignMacosOptions options(const std::string& host = "linux") {
        SignMacosOptions o;
        o.projectDir = proj;
        o.outDir = out;
        o.app = app.string();
        o.host = host;
        o.env = env_of({});
        o.toolConfigPath = tmp.sub("no-export.json");
        o.distribution = "appStore";
        o.identity = kDistribution;
        o.installerIdentity = kInstaller;
        o.provisioningProfile = profile;
        return o;
    }
};

struct StoreMac {
    std::vector<ProcessOptions> calls;
    std::string profileText;
    std::string lipoArchs = "x86_64 arm64";
    std::string signedEntitlements;
    int productbuildExit = 0, pkgutilExit = 0;

    ProcessRunner runner() {
        return [this](const ProcessOptions& o) -> Result<ProcessResult> {
            calls.push_back(o);
            ProcessResult r;
            r.exitCode = 0;
            const std::string exe = stdfs::path(o.argv.at(0)).filename().string();
            if (exe == "codesign" && o.argv.size() > 1 && o.argv[1] == "--force") {
                for (std::size_t i = 0; i + 1 < o.argv.size(); ++i)
                    if (o.argv[i] == "--entitlements" && has_text(o.argv.back(), "Space Dodge.app") && !has_text(o.argv.back(), "Frameworks"))
                        signedEntitlements = testing::read_all(o.argv[i + 1]);
            } else if (exe == "codesign" && o.argv.size() > 2 && o.argv[1] == "-d") {
                r.stdoutText = signedEntitlements;
            } else if (exe == "security") {
                r.stdoutText = profileText;
            } else if (exe == "lipo") {
                r.stdoutText = lipoArchs + "\n";
            } else if (exe == "productbuild") {
                r.exitCode = productbuildExit;
                if (productbuildExit) r.stderrText = "productbuild: error: Could not find appropriate signing identity for \"x\"";
            } else if (exe == "pkgutil") {
                r.exitCode = pkgutilExit;
                if (pkgutilExit) r.stderrText = "Status: no signature";
            }
            return r;
        };
    }

    std::vector<std::string> lines() const {
        std::vector<std::string> out;
        for (const ProcessOptions& o : calls) {
            std::string l;
            for (const std::string& a : o.argv) l += (l.empty() ? "" : " ") + a;
            out.push_back(l);
        }
        return out;
    }
};

const SignStep* step_named(const SignReport& r, const std::string& prefix) {
    for (const SignStep& s : r.steps)
        if (starts_with(s.title, prefix)) return &s;
    return nullptr;
}

std::size_t index_of(const SignReport& r, const std::string& prefix) {
    for (std::size_t i = 0; i < r.steps.size(); ++i)
        if (starts_with(r.steps[i].title, prefix)) return i;
    return r.steps.size();
}

}  // namespace

TEST_CASE("plist reader: a provisioning profile, entitlements and escapes") {
    auto p = tooling_detail::parse_xml_plist(std::string("\x30\x82 garbage before ") + profile_xml());
    REQUIRE(p.ok());
    CHECK((*p)["Name"] == "Space Dodge Store");
    CHECK((*p)["Platform"][0] == "OSX");
    CHECK((*p)["Entitlements"]["com.apple.application-identifier"] == "ABCDE12345.com.example.spacedodge");

    auto e = tooling_detail::parse_xml_plist(
        "<plist version=\"1.0\"><dict><key>a</key><true/><key>b</key><false/><key>n</key><integer>7</integer><key>s</key><string>x &amp; &lt;y&gt;</string>"
        "<key>l</key><array><string>one</string><string/></array><key>d</key><dict/></dict></plist>");
    REQUIRE(e.ok());
    CHECK((*e)["a"] == true);
    CHECK((*e)["b"] == false);
    CHECK((*e)["n"] == 7);
    CHECK((*e)["s"] == "x & <y>");
    CHECK((*e)["l"].size() == 2);
    CHECK((*e)["d"].is_object());

    CHECK_FALSE(tooling_detail::parse_xml_plist("not a plist").ok());
    CHECK_FALSE(tooling_detail::parse_xml_plist("<plist><dict><key>a</key>").ok());
}

TEST_CASE("sign.macos appStore dry run: the commands, in order, with the entitlements the player needs") {
    Game g;
    SignMacosOptions o = g.options();
    o.dryRun = true;
    auto r = sign_macos(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK(r->distribution == "appStore");
    CHECK(r->identity == kDistribution);
    CHECK(r->pkg == g.pkg_str());
    CHECK(r->zip.empty());
    CHECK(r->installerIdentity == kInstaller);
    CHECK(r->profile == "Space Dodge Store (ABCDE12345.com.example.spacedodge)");
    CHECK(r->entitlements["com.apple.security.app-sandbox"] == true);
    CHECK(r->entitlements["com.apple.application-identifier"] == "ABCDE12345.com.example.spacedodge");
    CHECK(r->entitlements["com.apple.developer.team-identifier"] == "ABCDE12345");
    CHECK_FALSE(r->notarized);
    CHECK(step_named(*r, "Zip") == nullptr);
    CHECK(step_named(*r, "Notarize") == nullptr);

    const std::size_t read = index_of(*r, "Read the provisioning profile");
    const std::size_t write = index_of(*r, "Write the entitlements of the app");
    const std::size_t embed = index_of(*r, "Embed the provisioning profile");
    const std::size_t sign = index_of(*r, "Sign Space Dodge.app");
    const std::size_t verify = index_of(*r, "Verify the signature");
    const std::size_t back = index_of(*r, "Read back the entitlements");
    const std::size_t build = index_of(*r, "Build and sign the installer package");
    const std::size_t check = index_of(*r, "Check the signature of the installer package");
    for (std::size_t i : {read, write, embed, sign, verify, back, build, check}) REQUIRE(i < r->steps.size());
    CHECK(read < write);
    CHECK(write < embed);
    CHECK(embed < sign);
    CHECK(sign < verify);
    CHECK(verify < back);
    CHECK(back < build);
    CHECK(build < check);

    const std::string ent = (g.app.parent_path().parent_path() / "space-dodge-macos.appstore.entitlements").generic_string();
    const std::vector<std::string> signApp = {"/usr/bin/codesign", "--force", "--timestamp", "--entitlements", ent, "--sign", kDistribution, g.app.generic_string()};
    CHECK(r->steps[sign].command == signApp);  // no hardened runtime for the store
    CHECK(r->steps[read].command == std::vector<std::string>{"/usr/bin/security", "cms", "-D", "-i", stdfs::path(g.profile).generic_string()});
    CHECK(r->steps[build].command == std::vector<std::string>{"/usr/bin/productbuild", "--component", g.app.generic_string(), "/Applications", "--sign", kInstaller, g.pkg_str()});
    CHECK(r->steps[check].command == std::vector<std::string>{"/usr/sbin/pkgutil", "--check-signature", g.pkg_str()});
    for (const SignStep& st : r->steps) CHECK_FALSE(st.ran);
    CHECK_FALSE(stdfs::exists(ent));  // a dry run writes nothing
    CHECK_FALSE(stdfs::exists(g.app / "Contents" / "embedded.provisionprofile"));
}

TEST_CASE("sign.macos appStore: identities come from the argument, the environment, export.json") {
    Game g;
    SignMacosOptions o = g.options();
    o.dryRun = true;
    o.identity.clear();
    o.installerIdentity.clear();
    auto none = sign_macos(o);
    REQUIRE_FALSE(none.ok());
    CHECK(has_text(none.error().message, "no signing identity"));
    CHECK(has_text(none.error().hint, "FACTORIA_MACOS_APPSTORE_IDENTITY"));
    CHECK(has_text(none.error().hint, "appStoreIdentity"));

    o.env = env_of({{"FACTORIA_MACOS_APPSTORE_IDENTITY", kDistribution}});
    auto noInstaller = sign_macos(o);
    REQUIRE_FALSE(noInstaller.ok());
    CHECK(has_text(noInstaller.error().message, "no installer identity"));
    CHECK(has_text(noInstaller.error().hint, "FACTORIA_MACOS_INSTALLER_IDENTITY"));

    o.env = env_of({{"FACTORIA_MACOS_APPSTORE_IDENTITY", kDistribution}, {"FACTORIA_MACOS_INSTALLER_IDENTITY", kInstaller}});
    auto env = sign_macos(o);
    REQUIRE_MESSAGE(env.ok(), (env.ok() ? "" : env.error().to_string()));
    CHECK(env->identityFrom == "FACTORIA_MACOS_APPSTORE_IDENTITY");
    CHECK(env->installerIdentity == kInstaller);

    o.env = env_of({});
    testing::write_all(g.tmp.sub("export.json"), std::string("{\"sign\":{\"macos\":{\"appStoreIdentity\":\"") + kDistribution + "\",\"installerIdentity\":\"" + kInstaller + "\"}}}");
    o.toolConfigPath = g.tmp.sub("export.json");
    auto file = sign_macos(o);
    REQUIRE_MESSAGE(file.ok(), (file.ok() ? "" : file.error().to_string()));
    CHECK(file->identityFrom == "export.json");
    CHECK(file->installerIdentity == kInstaller);
}

TEST_CASE("sign.macos appStore: every error teaches") {
    Game g;
    auto fail = [&](SignMacosOptions o) {
        o.dryRun = true;
        auto r = sign_macos(o);
        REQUIRE_FALSE(r.ok());
        CHECK_FALSE(r.error().hint.empty());
        return r.error();
    };
    {
        SignMacosOptions o = g.options();
        o.distribution = "appstore";
        auto e = fail(o);
        CHECK(has_text(e.message, "unknown distribution 'appstore'"));
        CHECK(has_text(e.hint, "appStore"));
    }
    {
        SignMacosOptions o = g.options();
        o.provisioningProfile.clear();
        CHECK(has_text(fail(o).message, "needs a provisioning profile"));
    }
    {
        SignMacosOptions o = g.options();
        o.identity = "Developer ID Application: Ada Lovelace (ABCDE12345)";
        auto e = fail(o);
        CHECK(has_text(e.message, "cannot sign an app for the Mac App Store"));
        CHECK(has_text(e.hint, "Apple Distribution"));
    }
    {
        SignMacosOptions o = g.options();
        o.installerIdentity = "Developer ID Installer: Ada Lovelace (ABCDE12345)";
        CHECK(has_text(fail(o).message, "cannot sign the .pkg"));
    }
    {
        SignMacosOptions o = g.options();
        o.notarize = true;
        CHECK(has_text(fail(o).message, "does not take notarized apps"));
    }
    auto with_profile = [&](const std::string& xml) {
        testing::write_all(g.profile, xml);
        return fail(g.options());
    };
    CHECK(has_text(with_profile(profile_xml("ABCDE12345.com.example.other")).message, "is for the App ID ABCDE12345.com.example.other, but the game's id is com.example.spacedodge"));
    CHECK(has_text(with_profile(profile_xml("ABCDE12345.*")).message, "wildcard"));
    CHECK(has_text(with_profile(profile_xml("ABCDE12345.com.example.spacedodge", "iOS")).message, "is for iOS, not for macOS"));
    CHECK(has_text(with_profile(profile_xml("ABCDE12345.com.example.spacedodge", "OSX", "<key>ProvisionedDevices</key><array><string>x</string></array>")).message, "development profile"));
    CHECK(has_text(with_profile(profile_xml("ABCDE12345.com.example.spacedodge", "OSX", "<key>ProvisionsAllDevices</key><true/>")).message, "Developer ID profile"));
    CHECK(has_text(with_profile(profile_xml("ABCDE12345.com.example.spacedodge", "OSX", "", "2020-01-01T00:00:00Z")).message, "expired on 2020-01-01"));
    testing::write_all(g.profile, profile_xml());

    testing::write_all(g.tmp.sub("mine.entitlements"), "<plist version=\"1.0\"><dict><key>com.apple.security.network.client</key><true/></dict></plist>");
    SignMacosOptions o = g.options();
    o.entitlements = g.tmp.sub("mine.entitlements");
    auto e = fail(o);
    CHECK(has_text(e.message, "does not turn the App Sandbox on"));

    SignMacosOptions adHoc = g.options();
    adHoc.identity = "-";
    CHECK(has_text(fail(adHoc).message, "needs a real certificate"));  // a profile with an ad hoc identity
}

TEST_CASE("sign.macos appStore (faked Mac): entitlements, helpers, pkg, warnings") {
    Game g(R"({"entitlements":{"com.apple.security.network.client":true,"com.apple.security.files.user-selected.read-write":true}})");
    // Native code: a plugin library, a helper program, a framework, and the backend of another store.
    const stdfs::path fw = g.app / "Contents" / "Frameworks";
    testing::write_all(fw / "libplugin.dylib", "dylib");
    write_macho(fw / "libsteam_api.dylib", 6);
    write_macho(fw / "Helper.app" / "Contents" / "MacOS" / "helper");
    testing::write_all(fw / "Helper.app" / "Contents" / "Info.plist", "<plist/>");
    // The capabilities the plugins asked for.
    testing::write_all(g.app.parent_path() / "space-dodge.entitlements",
                       "<?xml version=\"1.0\"?><plist version=\"1.0\"><dict><key>com.apple.developer.game-center</key><true/>"
                       "<key>com.apple.developer.icloud-container-identifiers</key><array><string>iCloud.TEAMID.com.example.spacedodge</string></array>"
                       "<key>com.apple.developer.team-identifier</key><string>TEAMID</string></dict></plist>");

    StoreMac mac;
    mac.profileText = profile_xml();
    mac.lipoArchs = "x86_64";
    SignMacosOptions o = g.options("macos");
    o.run = mac.runner();
    auto r = sign_macos(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK(r->signedApp);
    CHECK(r->verified);
    CHECK(r->pkgSigned);
    CHECK_FALSE(r->notarized);

    // The entitlements read back from the (faked) signature.
    const Json& e = r->entitlements;
    CHECK(e["com.apple.security.app-sandbox"] == true);
    CHECK(e["com.apple.security.network.client"] == true);
    CHECK(e["com.apple.security.files.user-selected.read-write"] == true);
    CHECK(e["com.apple.developer.game-center"] == true);
    CHECK(e["com.apple.developer.icloud-container-identifiers"][0] == "iCloud.ABCDE12345.com.example.spacedodge");
    CHECK(e["com.apple.application-identifier"] == "ABCDE12345.com.example.spacedodge");
    CHECK(e["com.apple.developer.team-identifier"] == "ABCDE12345");

    // The profile is embedded, the entitlement files are written, helpers inherit the sandbox.
    CHECK(stdfs::exists(g.app / "Contents" / "embedded.provisionprofile"));
    const stdfs::path inherit = g.app.parent_path().parent_path() / "space-dodge-macos.appstore-inherit.entitlements";
    REQUIRE(stdfs::exists(inherit));
    const std::string inheritText = testing::read_all(inherit);
    CHECK(has_text(inheritText, "com.apple.security.inherit"));
    CHECK(has_text(inheritText, "com.apple.security.app-sandbox"));
    bool helperInherits = false, dylibPlain = true;
    for (const std::string& l : mac.lines()) {
        if (has_text(l, "--sign") && has_text(l, "Helper.app") && !has_text(l, "Contents/MacOS") && has_text(l, inherit.generic_string())) helperInherits = true;
        if (has_text(l, "libplugin.dylib") && has_text(l, "--entitlements")) dylibPlain = false;
        CHECK_FALSE(has_text(l, "--options runtime"));
        CHECK_FALSE(has_text(l, "notarytool"));
    }
    CHECK(helperInherits);
    CHECK(dylibPlain);

    // The warnings: another store's backend, the Intel-only executable.
    CHECK(any_has(r->warnings, "libsteam_api.dylib"));
    CHECK(any_has(r->warnings, "x86_64 only"));
    CHECK(any_has(r->nextSteps, "publish.appstore"));
    CHECK(any_has(mac.lines(), "productbuild --component"));
}

TEST_CASE("sign.macos appStore (faked Mac): a failing productbuild or pkgutil stops there") {
    Game g;
    {
        StoreMac mac;
        mac.profileText = profile_xml();
        mac.productbuildExit = 1;
        SignMacosOptions o = g.options("macos");
        o.run = mac.runner();
        auto r = sign_macos(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().message, "Could not find appropriate signing identity"));
        CHECK(has_text(r.error().hint, "installer identity"));
    }
    {
        StoreMac mac;
        mac.profileText = "garbage";
        SignMacosOptions o = g.options("macos");
        o.run = mac.runner();
        auto r = sign_macos(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().message, "cannot read the provisioning profile"));
    }
    {
        StoreMac mac;
        mac.profileText = profile_xml();
        mac.pkgutilExit = 1;
        SignMacosOptions o = g.options("macos");
        o.run = mac.runner();
        auto r = sign_macos(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().message, "no signature"));
    }
    {
        StoreMac mac;
        mac.profileText = profile_xml();
        mac.signedEntitlements = "<plist version=\"1.0\"><dict/></plist>";
        SignMacosOptions o = g.options("macos");
        o.run = [&](const ProcessOptions& po) {  // a codesign that drops the entitlements
            auto base = mac.runner()(po);
            if (base.ok() && po.argv.size() > 2 && po.argv[1] == "-d") base->stdoutText = "<plist version=\"1.0\"><dict/></plist>";
            return base;
        };
        auto r = sign_macos(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().message, "does not carry the App Sandbox entitlement"));
    }
}

TEST_CASE("sign.macos appStore: ad hoc is a local try, with an unsigned pkg") {
    Game g;
    StoreMac mac;
    SignMacosOptions o = g.options("macos");
    o.identity = "-";
    o.provisioningProfile.clear();
    o.installerIdentity.clear();
    o.run = mac.runner();
    auto r = sign_macos(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK(r->signedApp);
    CHECK_FALSE(r->pkgSigned);
    CHECK(r->entitlements["com.apple.security.app-sandbox"] == true);
    CHECK_FALSE(r->entitlements.contains("com.apple.application-identifier"));
    CHECK(any_has(r->warnings, "Ad hoc sandbox try"));
    const std::vector<std::string> lines = mac.lines();
    CHECK(any_has(lines, "productbuild --component " + g.app.generic_string() + " /Applications " + g.pkg_str()));
    CHECK_FALSE(any_has(lines, "pkgutil"));
    CHECK_FALSE(any_has(lines, "security cms"));
    CHECK(any_has(lines, "--timestamp=none"));
    CHECK(step_named(*r, "Build the installer package (unsigned)") != nullptr);
}

TEST_CASE("sign.macos: the command offers distribution, installerIdentity and pkg") {
    Game g;
    CommandRegistry registry;
    register_sign_commands(registry, g.proj);
    const CommandInfo* info = registry.info("sign.macos");
    REQUIRE(info != nullptr);
    for (const char* key : {"distribution", "installerIdentity", "pkg"}) CHECK_MESSAGE(info->inputSchema["properties"].contains(key), key);
    CHECK(has_text(info->description, "FACTORIA_MACOS_APPSTORE_IDENTITY"));
    CHECK(has_text(info->description, "FACTORIA_MACOS_INSTALLER_IDENTITY"));

    const stdfs::path inProject = stdfs::path(g.proj) / "build" / "export";
    stdfs::create_directories(inProject);
    stdfs::copy(g.app.parent_path(), inProject / "space-dodge-macos", stdfs::copy_options::recursive);
    auto bad = registry.call("sign.macos", Json::object({{"distribution", "store"}, {"identity", "-"}, {"dryRun", true}}));
    CHECK_FALSE(bad.ok);
    CHECK_MESSAGE(has_text(bad.error.dump(), "allowed values"), bad.error.dump());
    auto ok = registry.call("sign.macos", Json::object({{"distribution", "appStore"}, {"identity", "-"}, {"dryRun", true}}));
    REQUIRE_MESSAGE(ok.ok, ok.error.dump());
    CHECK(ok.result["distribution"] == "appStore");
    CHECK(has_text(ok.result["pkg"].get<std::string>(), "space-dodge-macos.pkg"));
}

TEST_CASE("macOS export: Info.plist carries the build number and the encryption declaration") {
    auto plist_of = [](const std::string& macos) {
        Game g(macos);
        return testing::read_all(g.app / "Contents" / "Info.plist");
    };
    const std::string plain = plist_of(R"({"category": "public.app-category.games"})");
    CHECK(has_text(plain, "<key>ITSAppUsesNonExemptEncryption</key><false/>"));
    CHECK(has_text(plain, "<key>CFBundleVersion</key><string>"));
    const std::string custom = plist_of(R"({"buildNumber": "17", "usesNonExemptEncryption": true})");
    CHECK(has_text(custom, "<key>CFBundleVersion</key><string>17</string>"));
    CHECK(has_text(custom, "<key>ITSAppUsesNonExemptEncryption</key><true/>"));
    CHECK_FALSE(has_text(custom, "<key>CFBundleShortVersionString</key><string>17</string>"));
}

#if defined(__APPLE__) && defined(FA_PLAYER_EXE)
// The acceptance test of the Mac App Store export: a real, sandboxed export of a small project passes `codesign --verify --strict`,
// carries the App Sandbox entitlement, and the real player runs inside it (its files go to ~/Library/Containers/<id>).
TEST_CASE("sign.macos appStore on a Mac: the sandboxed app is valid, runs, and lives in its container") {
    testing::TempDir tmp;
    const std::string proj = tmp.sub("proj");
    ScaffoldOptions so;
    so.name = "Sandbox Probe";
    so.id = "com.factoria.sandboxprobe";  // its container is removed at the end (macOS keeps an empty folder of its own in it)
    auto created = create_project(proj, "2d-platformer", so);
    REQUIRE_MESSAGE(created.ok(), (created.ok() ? "" : created.error().to_string()));
    ExportOptions eo;
    eo.projectDir = proj;
    eo.platform = "macos";
    eo.outDir = tmp.sub("out");
    eo.playerBinary = FA_PLAYER_EXE;
    auto exported = export_project(eo);
    REQUIRE_MESSAGE(exported.ok(), (exported.ok() ? "" : exported.error().to_string()));
    const stdfs::path app = stdfs::path(exported->outputDir) / "Sandbox Probe.app";

    const char* home = std::getenv("HOME");
    REQUIRE(home != nullptr);
    const stdfs::path container = stdfs::path(home) / "Library" / "Containers" / so.id;
    struct Cleanup {
        stdfs::path dir;
        ~Cleanup() {
            std::error_code ec;
            stdfs::remove_all(dir, ec);
        }
    } cleanup{container};

    SignMacosOptions o;
    o.projectDir = proj;
    o.app = app.string();
    o.distribution = "appStore";
    o.identity = "-";
    o.env = [](const std::string&) { return std::string(); };
    o.toolConfigPath = tmp.sub("no-export.json");
    auto r = sign_macos(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK(r->verified);
    CHECK(r->entitlements["com.apple.security.app-sandbox"] == true);
    CHECK_FALSE(r->pkgSigned);
    CHECK(stdfs::exists(r->pkg));

    ProcessOptions verify;
    verify.argv = {"/usr/bin/codesign", "--verify", "--strict", "--verbose=2", app.string()};
    auto v = run_process(verify);
    REQUIRE(v.ok());
    CHECK_MESSAGE(v->exitCode == 0, v->stderrText);

    ProcessOptions show;
    show.argv = {"/usr/bin/codesign", "-d", "--entitlements", ":-", app.string()};
    auto d = run_process(show);
    REQUIRE(d.ok());
    CHECK_MESSAGE(has_text(d->stdoutText, "com.apple.security.app-sandbox"), (d->stdoutText + d->stderrText));

    // Run it for a few frames. If this machine cannot open a window (no session), the launch fails before anything runs: skip then.
    ProcessOptions run;
    stdfs::path exe;
    for (const auto& f : stdfs::directory_iterator(app / "Contents" / "MacOS")) exe = f.path();
    REQUIRE_FALSE(exe.empty());
    run.argv = {exe.string(), "--frames", "5"};
    run.timeoutSeconds = 60;
    auto ran = run_process(run);
    REQUIRE(ran.ok());
    CHECK_MESSAGE(ran->exitCode == 0, ran->stderrText);
    // In the sandbox the home folder is the container, so the player's log landed there.
    bool foundLog = false;
    std::error_code ec;
    if (stdfs::exists(container, ec))
        for (stdfs::recursive_directory_iterator it(container, ec), end; !ec && it != end; it.increment(ec))
            if (it->path().filename() == "log.txt") foundLog = true;
    CHECK_MESSAGE(foundLog, ("no log.txt under " + container.string() + ": the app did not run sandboxed"));
}
#endif
