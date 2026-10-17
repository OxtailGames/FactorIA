// sign.macos (fa/tooling/sign.h): the command lines it builds (dry run, on any computer), the order of the steps, where the
// identity and the notary credentials come from and that no secret is ever printed; and, with a fake process runner, what it does
// with the answers of codesign and notarytool. Only the last test signs for real, and only on a Mac (#if __APPLE__).
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
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

constexpr const char* kDeveloperId = "Developer ID Application: Ada Lovelace (ABCDE12345)";
constexpr const char* kPassword = "abcd-efgh-ijkl-mnop";  // an app-specific password, as the environment would hold it

bool has_text(const std::string& haystack, const std::string& needle) { return haystack.find(needle) != std::string::npos; }

bool any_has(const std::vector<std::string>& v, const std::string& needle) {
    return std::any_of(v.begin(), v.end(), [&](const std::string& s) { return has_text(s, needle); });
}

bool contains(const std::vector<std::string>& v, const std::string& s) { return std::find(v.begin(), v.end(), s) != v.end(); }

void write_macho(const stdfs::path& p) { testing::write_all(p, std::string("\xcf\xfa\xed\xfe", 4) + std::string(60, '\0')); }

// A computer with these environment variables.
ExportEnvLookup env_of(std::map<std::string, std::string> vars) {
    return [vars = std::move(vars)](const std::string& name) {
        auto it = vars.find(name);
        return it == vars.end() ? std::string() : it->second;
    };
}

// Exports "Space Dodge" for macOS (the player is a stand-in) and adds the native code a plugin would have put in Frameworks.
struct Game {
    testing::TempDir tmp;
    std::string proj, out;
    stdfs::path app;  // <out>/space-dodge-macos/Space Dodge.app

    Game() {
        proj = tmp.sub("proj");
        ScaffoldOptions so;
        so.name = "Space Dodge";
        so.id = "com.example.spacedodge";
        auto created = create_project(proj, "2d-platformer", so);
        REQUIRE_MESSAGE(created.ok(), (created.ok() ? "" : created.error().to_string()));
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
        REQUIRE(stdfs::exists(app / "Contents" / "Info.plist"));
    }

    void add_plugin_code() {
        const stdfs::path fw = app / "Contents" / "Frameworks";
        testing::write_all(fw / "libplugin.dylib", "dylib");
        write_macho(fw / "Sparkle.framework" / "Versions" / "A" / "Sparkle");
        write_macho(fw / "Helper.app" / "Contents" / "MacOS" / "helper");
        testing::write_all(fw / "Helper.app" / "Contents" / "Info.plist", "<plist/>");
        testing::write_all(fw / "readme.txt", "not code");
    }

    std::string app_str() const { return app.generic_string(); }
    std::string zip_str() const { return (app.parent_path().parent_path() / "space-dodge-macos.zip").generic_string(); }

    // Options for a run on a computer that is not a Mac, with the environment and ~/.factoria/export.json of an empty one.
    SignMacosOptions options(const std::string& host = "linux") {
        SignMacosOptions o;
        o.projectDir = proj;
        o.outDir = out;
        o.app = app.string();  // exactly where the export put it (the temporary folder may be reached through a short name)
        o.host = host;
        o.env = env_of({});
        o.toolConfigPath = tmp.sub("no-export.json");
        o.identity = kDeveloperId;
        return o;
    }
};

std::vector<std::string> titles(const SignReport& r) {
    std::vector<std::string> t;
    for (const SignStep& s : r.steps) t.push_back(s.title);
    return t;
}

const SignStep* step_named(const SignReport& r, const std::string& prefix) {
    for (const SignStep& s : r.steps)
        if (starts_with(s.title, prefix)) return &s;
    return nullptr;
}

std::size_t index_of(const SignReport& r, const std::string& title) {
    for (std::size_t i = 0; i < r.steps.size(); ++i)
        if (r.steps[i].title == title) return i;
    return r.steps.size();
}

// A fake macOS: every program succeeds; notarytool answers like Apple does. `calls` keeps what really would have been run.
struct FakeMac {
    std::vector<ProcessOptions> calls;
    std::string notaryStatus = "Accepted";
    std::string notaryId = "11111111-2222-3333-4444-555555555555";
    int codesignExit = 0;
    std::string codesignError;
    std::string logText = "{\"issues\":[{\"path\":\"Space Dodge.app/Contents/Frameworks/libplugin.dylib\",\"message\":\"The signature does not include a secure timestamp.\"}]}";
    std::vector<std::string> echoed;  // lines it prints to stdout and stderr as it goes (a tool that repeats a password)

    ProcessRunner runner() {
        return [this](const ProcessOptions& o) -> Result<ProcessResult> {
            calls.push_back(o);
            ProcessResult r;
            r.exitCode = 0;
            for (const std::string& line : echoed) {
                if (o.onStdoutLine) o.onStdoutLine(line);
                if (o.onStderrLine) o.onStderrLine(line);
            }
            const std::string exe = stdfs::path(o.argv.at(0)).filename().string();
            if (exe == "codesign" && o.argv.size() > 1 && o.argv[1] == "--force" && codesignExit != 0) {
                r.exitCode = codesignExit;
                r.stderrText = codesignError;
            } else if (exe == "xcrun" && o.argv.size() > 2 && o.argv[1] == "notarytool" && o.argv[2] == "submit") {
                r.stdoutText = "Conducting pre-submission checks...\n{\"id\":\"" + notaryId + "\",\"status\":\"" + notaryStatus + "\",\"message\":\"Processing complete\"}\n";
                r.exitCode = notaryStatus == "Accepted" ? 0 : 1;
            } else if (exe == "xcrun" && o.argv.size() > 2 && o.argv[1] == "notarytool" && o.argv[2] == "log") {
                r.stdoutText = logText;
            }
            return r;
        };
    }

    std::vector<std::string> command_lines() const {
        std::vector<std::string> out;
        for (const ProcessOptions& o : calls) {
            std::string l;
            for (const std::string& a : o.argv) l += (l.empty() ? "" : " ") + a;
            out.push_back(l);
        }
        return out;
    }
};

}  // namespace

TEST_CASE("sign.macos dry run: the command lines, in order, on a computer that is not a Mac") {
    for (const char* host : {"linux", "windows"}) {
        INFO(host);
        Game g;
        g.add_plugin_code();
        SignMacosOptions o = g.options(host);
        o.keychainProfile = "factoria-notary";
        o.dryRun = true;
        auto r = sign_macos(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        CHECK(r->dryRun);
        CHECK(r->app == g.app_str());
        CHECK(r->identity == kDeveloperId);
        CHECK(r->identityFrom == "argument");
        CHECK(r->credentials == "keychain profile 'factoria-notary'");
        CHECK(r->zip == g.zip_str());
        // Nothing happened.
        CHECK_FALSE(r->signedApp);
        CHECK_FALSE(r->verified);
        CHECK_FALSE(r->notarized);
        CHECK_FALSE(r->stapled);
        for (const SignStep& s : r->steps) {
            CHECK_FALSE(s.ran);
            CHECK(s.exitCode == -1);
        }
        CHECK(any_has(r->warnings, std::string("This computer is not a Mac (") + host + ")"));
        CHECK(any_has(r->nextSteps, "dry run"));

        const std::string fw = (g.app / "Contents" / "Frameworks").generic_string();
        auto codesign = [&](const std::string& what, const std::string& extra = {}) {
            std::vector<std::string> a = {"/usr/bin/codesign", "--force", "--options", "runtime", "--timestamp"};
            if (!extra.empty()) a.insert(a.end(), {"--entitlements", extra});
            a.insert(a.end(), {"--sign", kDeveloperId, what});
            return a;
        };
        // The plugin code first, the deepest first (a framework is sealed after the files inside it); never a text file.
        CHECK(step_named(*r, "Sign Contents/Frameworks/readme.txt") == nullptr);
        const std::size_t sparkleBin = index_of(*r, "Sign Contents/Frameworks/Sparkle.framework/Versions/A/Sparkle");
        const std::size_t sparkleFw = index_of(*r, "Sign Contents/Frameworks/Sparkle.framework");
        const std::size_t helperBin = index_of(*r, "Sign Contents/Frameworks/Helper.app/Contents/MacOS/helper");
        const std::size_t helperApp = index_of(*r, "Sign Contents/Frameworks/Helper.app");
        const std::size_t dylib = index_of(*r, "Sign Contents/Frameworks/libplugin.dylib");
        const std::size_t sign = index_of(*r, "Sign Space Dodge.app");
        for (std::size_t i : {sparkleBin, sparkleFw, helperBin, helperApp, dylib, sign}) REQUIRE(i < r->steps.size());
        CHECK(sparkleBin < sparkleFw);
        CHECK(helperBin < helperApp);
        CHECK(std::max({sparkleFw, helperApp, dylib}) < sign);
        CHECK(r->steps[sparkleBin].command == codesign(fw + "/Sparkle.framework/Versions/A/Sparkle"));
        CHECK(r->steps[dylib].command == codesign(fw + "/libplugin.dylib"));
        CHECK(r->steps[sign].command == codesign(g.app_str()));

        // Then, in this order, what Apple asks for.
        std::vector<std::string> after;
        for (std::size_t i = sign; i < r->steps.size(); ++i) after.push_back(r->steps[i].title);
        CHECK(after == std::vector<std::string>{"Sign Space Dodge.app", "Verify the signature", "Zip the app for notarization",
                                                "Notarize (upload to Apple and wait for the verdict)", "Staple the ticket to the app",
                                                "Check the stapled ticket", "Ask Gatekeeper (spctl)", "Zip the app to share"});
        CHECK(r->steps[sign + 1].command == std::vector<std::string>{"/usr/bin/codesign", "--verify", "--deep", "--strict", "--verbose=2", g.app_str()});
        const std::string submitZip = (stdfs::path(g.zip_str()).parent_path() / "space-dodge-macos-notarize.zip").generic_string();
        CHECK(r->steps[sign + 2].command == std::vector<std::string>{"/usr/bin/ditto", "-c", "-k", "--keepParent", g.app_str(), submitZip});
        CHECK(r->steps[sign + 3].command ==
              std::vector<std::string>{"/usr/bin/xcrun", "notarytool", "submit", submitZip, "--keychain-profile", "factoria-notary", "--wait", "--timeout", "40m", "--output-format", "json"});
        CHECK(r->steps[sign + 4].command == std::vector<std::string>{"/usr/bin/xcrun", "stapler", "staple", g.app_str()});
        CHECK(r->steps[sign + 5].command == std::vector<std::string>{"/usr/bin/xcrun", "stapler", "validate", g.app_str()});
        CHECK(r->steps[sign + 6].command == std::vector<std::string>{"/usr/sbin/spctl", "--assess", "--type", "execute", "--verbose=4", g.app_str()});
        CHECK(r->steps[sign + 7].command == std::vector<std::string>{"/usr/bin/ditto", "-c", "-k", "--keepParent", g.app_str(), g.zip_str()});

        // The dry run changed nothing.
        CHECK_FALSE(stdfs::exists(g.zip_str()));
        CHECK_FALSE(stdfs::exists(submitZip));

        // The JSON an AI reads carries the same lines, ready to paste.
        const Json j = r->to_json();
        CHECK(j["dryRun"] == true);
        CHECK(j["steps"].size() == r->steps.size());
        CHECK(has_text(j["steps"][sign]["commandLine"].get<std::string>(), "/usr/bin/codesign --force --options runtime --timestamp --sign 'Developer ID Application: Ada Lovelace (ABCDE12345)' "));
        CHECK(j["steps"][sign]["ran"] == false);
        CHECK_FALSE(j["steps"][sign].contains("exitCode"));
    }
}

TEST_CASE("sign.macos: the app is found where the export wrote it, or where `app` says") {
    Game g;
    SignMacosOptions o = g.options();
    o.dryRun = true;
    SUBCASE("by the project") {
        o.app.clear();
        auto r = sign_macos(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        CHECK(stdfs::path(r->app).filename() == "Space Dodge.app");
        CHECK(stdfs::equivalent(stdfs::path(r->app), g.app));
    }
    SUBCASE("by app") {
        o.projectDir.clear();
        o.outDir.clear();
        auto r = sign_macos(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        CHECK(r->app == g.app_str());
        CHECK(r->zip == g.zip_str());  // next to the <slug>-macos folder
    }
    SUBCASE("a zip of the caller's choosing") {
        o.zip = g.tmp.sub("share/game.zip");
        auto r = sign_macos(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        CHECK(r->zip == stdfs::path(o.zip).generic_string());
    }
    SUBCASE("no export yet") {
        o.app.clear();
        stdfs::remove_all(g.app);
        auto r = sign_macos(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().message, "there is no macOS app at"));
        CHECK(has_text(r.error().hint, "project.export"));
        CHECK(has_text(r.error().hint, "macos"));
    }
    SUBCASE("a folder that is not an app") {
        o.app = g.tmp.sub("out/space-dodge-macos");
        auto r = sign_macos(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().message, "not an app bundle"));
    }
    SUBCASE("an app folder without Info.plist") {
        stdfs::remove(g.app / "Contents" / "Info.plist");
        auto r = sign_macos(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().message, "no Contents/Info.plist"));
    }
    SUBCASE("neither a project nor an app") {
        o.projectDir.clear();
        o.app.clear();
        auto r = sign_macos(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().hint, "app"));
    }
}

TEST_CASE("sign.macos: a real run needs a Mac, and the error says what to do instead") {
    Game g;
    FakeMac mac;
    for (const char* host : {"linux", "windows"}) {
        INFO(host);
        SignMacosOptions o = g.options(host);
        o.run = mac.runner();
        auto r = sign_macos(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().message, std::string("this computer is not a Mac (") + host + ")"));
        CHECK(has_text(r.error().message, "codesign"));
        CHECK(has_text(r.error().hint, "dryRun"));
        CHECK(has_text(r.error().hint, "project.new_ci_workflow"));
        CHECK(has_text(r.error().hint, "on a Mac"));
    }
    CHECK(mac.calls.empty());  // nothing was started, nothing was changed
    CHECK_FALSE(stdfs::exists(g.app / "Contents" / "_CodeSignature"));
}

TEST_CASE("sign.macos: where the identity comes from") {
    Game g;
    SignMacosOptions o = g.options();
    o.dryRun = true;
    o.notarize = false;
    stdfs::path config = g.tmp.sub("export.json");
    o.toolConfigPath = config.string();

    SUBCASE("nowhere") {
        o.identity.clear();
        auto r = sign_macos(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().message, "no signing identity"));
        CHECK(has_text(r.error().hint, "FACTORIA_MACOS_SIGN_IDENTITY"));
        CHECK(has_text(r.error().hint, "security find-identity"));
        CHECK(has_text(r.error().hint, config.string()));
        CHECK(has_text(r.error().hint, "\"-\""));
    }
    SUBCASE("the machine settings, then the environment, then the argument") {
        testing::write_all(config, R"json({"sign": {"macos": {"identity": "Developer ID Application: From File (FILE123456)", "keychain": "/Users/me/ci.keychain-db"}}})json");
        o.identity.clear();
        auto fromFile = sign_macos(o);
        REQUIRE_MESSAGE(fromFile.ok(), (fromFile.ok() ? "" : fromFile.error().to_string()));
        CHECK(fromFile->identity == "Developer ID Application: From File (FILE123456)");
        CHECK(fromFile->identityFrom == "export.json");
        const SignStep* sign = step_named(*fromFile, "Sign Space Dodge.app");
        REQUIRE(sign != nullptr);
        CHECK(contains(sign->command, "--keychain"));  // the keychain of the settings goes to codesign
        CHECK(contains(sign->command, "/Users/me/ci.keychain-db"));

        o.env = env_of({{"FACTORIA_MACOS_SIGN_IDENTITY", "Developer ID Application: From Env (ENV1234567)"}});
        auto fromEnv = sign_macos(o);
        REQUIRE(fromEnv.ok());
        CHECK(fromEnv->identity == "Developer ID Application: From Env (ENV1234567)");
        CHECK(fromEnv->identityFrom == "FACTORIA_MACOS_SIGN_IDENTITY");

        o.identity = kDeveloperId;
        auto fromArg = sign_macos(o);
        REQUIRE(fromArg.ok());
        CHECK(fromArg->identity == kDeveloperId);
        CHECK(fromArg->identityFrom == "argument");
    }
    SUBCASE("a settings file that is not valid says where") {
        testing::write_all(config, R"({"sign": {"macos": {"identity": 5}}})");
        o.identity.clear();
        auto r = sign_macos(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().message, "#/sign/macos/identity"));
        CHECK(has_text(r.error().message, "expected a string"));
        testing::write_all(config, "{ not json");
        CHECK_FALSE(sign_macos(o).ok());
    }
}

TEST_CASE("sign.macos: notarytool credentials, in order, and nothing secret in the report") {
    Game g;
    SignMacosOptions o = g.options();
    o.dryRun = true;
    auto submit_of = [](const SignReport& r) {
        const SignStep* s = step_named(r, "Notarize");
        REQUIRE(s != nullptr);
        return s->command;
    };

    SUBCASE("a keychain profile, from the argument, the environment or the machine settings; with the keychain") {
        o.env = env_of({{"FACTORIA_NOTARY_PROFILE", "env-profile"}});
        auto fromEnv = sign_macos(o);
        REQUIRE(fromEnv.ok());
        CHECK(contains(submit_of(*fromEnv), "env-profile"));
        o.keychainProfile = "arg-profile";
        o.keychain = "/tmp/ci.keychain-db";
        auto fromArg = sign_macos(o);
        REQUIRE(fromArg.ok());
        const auto argv = submit_of(*fromArg);
        CHECK(contains(argv, "arg-profile"));
        CHECK_FALSE(contains(argv, "env-profile"));
        const auto at = std::find(argv.begin(), argv.end(), "--keychain");
        REQUIRE(at != argv.end());
        CHECK(*(at + 1) == "/tmp/ci.keychain-db");
        testing::write_all(g.tmp.sub("export.json"), R"({"sign": {"macos": {"notaryProfile": "file-profile"}}})");
        o.toolConfigPath = g.tmp.sub("export.json");
        o.env = env_of({});
        o.keychainProfile.clear();
        o.keychain.clear();
        auto fromFile = sign_macos(o);
        REQUIRE(fromFile.ok());
        CHECK(contains(submit_of(*fromFile), "file-profile"));
    }
    SUBCASE("an App Store Connect API key") {
        testing::write_all(g.tmp.sub("AuthKey_ABC123.p8"), "key");
        o.apiKey = g.tmp.sub("AuthKey_ABC123.p8");
        o.apiKeyId = "ABC123";
        o.apiIssuer = "69a6de70-aaaa-bbbb-cccc-dddddddddddd";
        auto r = sign_macos(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        const auto argv = submit_of(*r);
        const std::vector<std::string> want = {"--key", o.apiKey, "--key-id", "ABC123", "--issuer", "69a6de70-aaaa-bbbb-cccc-dddddddddddd"};
        CHECK(std::search(argv.begin(), argv.end(), want.begin(), want.end()) != argv.end());
        CHECK(r->credentials == "App Store Connect API key ABC123");

        o.apiKeyId.clear();  // half of a login
        auto noId = sign_macos(o);
        REQUIRE(noId.ok());  // not asked for: signs, and says why it does not notarize
        CHECK(step_named(*noId, "Notarize") == nullptr);
        CHECK(any_has(noId->warnings, "has no key id"));
        o.notarize = true;
        auto asked = sign_macos(o);
        REQUIRE_FALSE(asked.ok());
        CHECK(has_text(asked.error().message, "cannot notarize"));
        CHECK(has_text(asked.error().message, "no key id"));

        o.apiKeyId = "ABC123";
        o.apiKey = g.tmp.sub("missing.p8");
        auto noFile = sign_macos(o);
        REQUIRE_FALSE(noFile.ok());
        CHECK(has_text(noFile.error().message, "does not exist"));
    }
    SUBCASE("an Apple ID: the password only from the environment, and never shown") {
        o.appleId = "ada@example.com";
        o.teamId = "ABCDE12345";
        o.env = env_of({{"FACTORIA_APPLE_APP_PASSWORD", kPassword}});
        auto r = sign_macos(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        const auto argv = submit_of(*r);
        const std::vector<std::string> want = {"--apple-id", "ada@example.com", "--team-id", "ABCDE12345", "--password", "<redacted>"};
        CHECK(std::search(argv.begin(), argv.end(), want.begin(), want.end()) != argv.end());
        CHECK(r->credentials == "Apple ID ada@example.com (team ABCDE12345)");
        CHECK_FALSE(has_text(r->to_json().dump(), kPassword));

        o.env = env_of({{"FACTORIA_APPLE_ID", "ada@example.com"}, {"FACTORIA_APPLE_TEAM_ID", "ABCDE12345"}});  // no password
        o.appleId.clear();
        o.teamId.clear();
        auto noPassword = sign_macos(o);
        REQUIRE(noPassword.ok());
        CHECK(step_named(*noPassword, "Notarize") == nullptr);
        CHECK(any_has(noPassword->warnings, "FACTORIA_APPLE_APP_PASSWORD"));
    }
    SUBCASE("no credentials: only signs and warns; notarize:true is an error that lists the ways in") {
        auto r = sign_macos(o);
        REQUIRE(r.ok());
        CHECK(step_named(*r, "Notarize") == nullptr);
        CHECK(step_named(*r, "Staple") == nullptr);
        CHECK(step_named(*r, "Zip the app for notarization") == nullptr);
        CHECK(step_named(*r, "Zip the app to share") != nullptr);
        CHECK(any_has(r->warnings, "no notarization credentials were found"));
        CHECK(r->credentials.empty());
        o.notarize = true;
        auto asked = sign_macos(o);
        REQUIRE_FALSE(asked.ok());
        CHECK(has_text(asked.error().hint, "store-credentials"));
        CHECK(has_text(asked.error().hint, "FACTORIA_NOTARY_API_KEY"));
        CHECK(has_text(asked.error().hint, "FACTORIA_APPLE_APP_PASSWORD"));
        CHECK(has_text(asked.error().hint, "notarize: false"));
        o.notarize = false;  // told not to: no warning either
        auto quiet = sign_macos(o);
        REQUIRE(quiet.ok());
        CHECK(quiet->warnings.size() == 1);  // only "this is not a Mac"
    }
    SUBCASE("a certificate that cannot be notarized") {
        for (const char* wrong : {"Apple Development: Ada (ABCDE12345)", "Apple Distribution: Ada (ABCDE12345)", "Mac Developer: Ada (ABCDE12345)", "Developer ID Installer: Ada (ABCDE12345)"}) {
            INFO(wrong);
            o.identity = wrong;
            o.keychainProfile = "p";
            auto signedOnly = sign_macos(o);
            REQUIRE(signedOnly.ok());
            CHECK(step_named(*signedOnly, "Notarize") == nullptr);
            CHECK(any_has(signedOnly->warnings, "not a Developer ID Application certificate"));
            o.notarize = true;
            auto asked = sign_macos(o);
            REQUIRE_FALSE(asked.ok());
            CHECK(has_text(asked.error().message, "Developer ID Application"));
            o.notarize.reset();
        }
    }
}

TEST_CASE("sign.macos: ad hoc signing is for this Mac only") {
    Game g;
    SignMacosOptions o = g.options();
    o.dryRun = true;
    o.identity = "-";
    o.keychainProfile = "p";
    auto r = sign_macos(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    const SignStep* sign = step_named(*r, "Sign Space Dodge.app");
    REQUIRE(sign != nullptr);
    CHECK(*sign->command.rbegin() == g.app_str());
    CHECK(contains(sign->command, "--timestamp=none"));  // an ad hoc signature has no timestamp, and no hardened runtime
    CHECK_FALSE(contains(sign->command, "runtime"));
    CHECK(step_named(*r, "Notarize") == nullptr);
    CHECK(any_has(r->warnings, "Signed ad hoc"));
    CHECK(any_has(r->nextSteps, "Run it on this Mac"));

    o.notarize = true;
    auto asked = sign_macos(o);
    REQUIRE_FALSE(asked.ok());
    CHECK(has_text(asked.error().message, "ad hoc"));
}

TEST_CASE("sign.macos: entitlements and the provisioning profile") {
    Game g;
    const stdfs::path entitlements = g.app.parent_path() / "space-dodge.entitlements";
    testing::write_all(entitlements, "<plist><dict><key>com.apple.developer.team-identifier</key><string>ABCDE12345</string></dict></plist>");
    testing::write_all(g.tmp.sub("Game.provisionprofile"), "profile");
    SignMacosOptions o = g.options();
    o.dryRun = true;
    o.notarize = false;

    SUBCASE("without a profile the export's entitlements are left out, with a warning that says how to turn them on") {
        auto r = sign_macos(o);
        REQUIRE(r.ok());
        const SignStep* sign = step_named(*r, "Sign Space Dodge.app");
        REQUIRE(sign != nullptr);
        CHECK_FALSE(contains(sign->command, "--entitlements"));
        CHECK(any_has(r->warnings, "space-dodge.entitlements"));
        CHECK(any_has(r->warnings, "provisioningProfile"));
        CHECK(step_named(*r, "Embed the provisioning profile") == nullptr);
    }
    SUBCASE("with a profile the app carries both, and the plugin libraries do not get the entitlements") {
        g.add_plugin_code();
        o.provisioningProfile = g.tmp.sub("Game.provisionprofile");
        auto r = sign_macos(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        const SignStep* embed = step_named(*r, "Embed the provisioning profile");
        REQUIRE(embed != nullptr);
        CHECK(embed->command == std::vector<std::string>{"cp", stdfs::path(o.provisioningProfile).generic_string(), (g.app / "Contents" / "embedded.provisionprofile").generic_string()});
        CHECK(index_of(*r, embed->title) < index_of(*r, "Sign Space Dodge.app"));
        const SignStep* sign = step_named(*r, "Sign Space Dodge.app");
        REQUIRE(sign != nullptr);
        const auto at = std::find(sign->command.begin(), sign->command.end(), "--entitlements");
        REQUIRE(at != sign->command.end());
        CHECK(*(at + 1) == entitlements.generic_string());
        CHECK(r->warnings.size() == 1);  // only "this is not a Mac"
        const SignStep* lib = step_named(*r, "Sign Contents/Frameworks/libplugin.dylib");
        REQUIRE(lib != nullptr);
        CHECK_FALSE(contains(lib->command, "--entitlements"));
        CHECK_FALSE(stdfs::exists(g.app / "Contents" / "embedded.provisionprofile"));  // a dry run copies nothing
    }
    SUBCASE("an entitlements file of the caller's") {
        testing::write_all(g.tmp.sub("mine.entitlements"), "<plist/>");
        o.entitlements = g.tmp.sub("mine.entitlements");
        auto r = sign_macos(o);
        REQUIRE(r.ok());
        const SignStep* sign = step_named(*r, "Sign Space Dodge.app");
        REQUIRE(sign != nullptr);
        CHECK(contains(sign->command, stdfs::path(o.entitlements).generic_string()));
        o.entitlements = g.tmp.sub("missing.entitlements");
        auto missing = sign_macos(o);
        REQUIRE_FALSE(missing.ok());
        CHECK(has_text(missing.error().message, "does not exist"));
    }
    SUBCASE("the TEAMID placeholder of the export must be replaced first") {
        testing::write_all(entitlements, "<plist><dict><key>application-identifier</key><string>TEAMID.com.example.spacedodge</string></dict></plist>");
        o.provisioningProfile = g.tmp.sub("Game.provisionprofile");
        auto r = sign_macos(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().message, "placeholder TEAMID"));
        CHECK(has_text(r.error().hint, "10-character"));
    }
    SUBCASE("a profile that does not exist, or with an ad hoc identity") {
        o.provisioningProfile = g.tmp.sub("nope.provisionprofile");
        auto missing = sign_macos(o);
        REQUIRE_FALSE(missing.ok());
        CHECK(has_text(missing.error().message, "does not exist"));
        CHECK(has_text(missing.error().hint, "Apple Developer portal"));
        o.provisioningProfile = g.tmp.sub("Game.provisionprofile");
        o.identity = "-";
        auto adHoc = sign_macos(o);
        REQUIRE_FALSE(adHoc.ok());
        CHECK(has_text(adHoc.error().message, "needs a real certificate"));
    }
}

TEST_CASE("sign.macos on a Mac (faked): sign, verify, notarize, staple, zip") {
    Game g;
    g.add_plugin_code();
    testing::write_all(g.tmp.sub("Game.provisionprofile"), "profile");
    FakeMac mac;
    SignMacosOptions o = g.options("macos");
    o.keychainProfile = "factoria-notary";
    o.provisioningProfile = g.tmp.sub("Game.provisionprofile");
    testing::write_all(g.app.parent_path() / "space-dodge.entitlements", "<plist/>");
    o.run = mac.runner();
    std::vector<std::string> progress;
    o.progress = [&](const std::string& line) { progress.push_back(line); };
    mac.echoed = {"app: signed"};

    auto r = sign_macos(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK_FALSE(r->dryRun);
    CHECK(r->signedApp);
    CHECK(r->verified);
    CHECK(r->notarized);
    CHECK(r->stapled);
    CHECK(r->notarizationId == mac.notaryId);
    CHECK(r->warnings.empty());  // a Mac, a real certificate and credentials: nothing to warn about
    CHECK(stdfs::exists(g.app / "Contents" / "embedded.provisionprofile"));  // the profile was embedded for real
    CHECK(any_has(progress, "app: signed"));
    CHECK(any_has(r->nextSteps, g.zip_str()));

    // The runner was asked for exactly the steps of the report, in order, and every one of them exited 0.
    std::size_t ran = 0;
    for (const SignStep& s : r->steps) {
        CHECK(s.ran);
        CHECK(s.exitCode == 0);
        if (s.title == "Embed the provisioning profile") continue;  // factoria copies the file itself: no program
        CHECK(ran < mac.calls.size());
        if (ran < mac.calls.size()) CHECK(mac.calls[ran].argv == s.command);
        ++ran;
    }
    CHECK(ran == mac.calls.size());
    CHECK(any_has(mac.command_lines(), "xcrun notarytool submit"));
    CHECK(any_has(mac.command_lines(), "xcrun stapler staple"));
    CHECK(mac.calls.back().argv.front() == "/usr/bin/ditto");

    // Notarization is a long wait: the process gets a long timeout, the others a normal one.
    for (const ProcessOptions& p : mac.calls)
        if (p.argv.size() > 2 && p.argv[2] == "submit") CHECK(p.timeoutSeconds >= 40 * 60);
    CHECK_FALSE(stdfs::exists(stdfs::path(g.zip_str()).parent_path() / "space-dodge-macos-notarize.zip"));
}

TEST_CASE("sign.macos on a Mac (faked): when Apple says no, the log says why") {
    Game g;
    FakeMac mac;
    mac.notaryStatus = "Invalid";
    SignMacosOptions o = g.options("macos");
    o.keychainProfile = "factoria-notary";
    o.run = mac.runner();
    auto r = sign_macos(o);
    REQUIRE_FALSE(r.ok());
    CHECK(has_text(r.error().message, "Apple did not accept the app: status Invalid"));
    CHECK(has_text(r.error().message, mac.notaryId));
    CHECK(has_text(r.error().message, "secure timestamp"));  // quoted from `notarytool log`
    CHECK(has_text(r.error().hint, "hardened runtime"));
    // The log was fetched with the same login, and nothing was stapled or zipped for sharing.
    bool fetched = false;
    for (const std::string& l : mac.command_lines()) fetched = fetched || (has_text(l, "notarytool log " + mac.notaryId) && has_text(l, "--keychain-profile factoria-notary"));
    CHECK(fetched);
    CHECK_FALSE(any_has(mac.command_lines(), "stapler"));
    CHECK(mac.command_lines().back().find("notarytool log") != std::string::npos);
    CHECK_FALSE(stdfs::exists(stdfs::path(g.zip_str()).parent_path() / "space-dodge-macos-notarize.zip"));
}

TEST_CASE("sign.macos on a Mac (faked): a failing codesign stops there and quotes what it printed") {
    Game g;
    g.add_plugin_code();
    FakeMac mac;
    mac.codesignExit = 1;
    mac.codesignError = "Developer ID Application: Ada Lovelace (ABCDE12345): no identity found";
    SignMacosOptions o = g.options("macos");
    o.keychainProfile = "p";
    o.run = mac.runner();
    auto r = sign_macos(o);
    REQUIRE_FALSE(r.ok());
    CHECK(has_text(r.error().message, "exited with code 1"));
    CHECK(has_text(r.error().message, "no identity found"));
    CHECK(has_text(r.error().hint, "security find-identity"));
    CHECK(mac.calls.size() == 1);  // the first library; the rest was not tried
}

TEST_CASE("sign.macos: a program that cannot start, and a cancelled run") {
    Game g;
    SUBCASE("it cannot start") {
        SignMacosOptions o = g.options("macos");
        o.run = [](const ProcessOptions&) -> Result<ProcessResult> { return make_error("No such file"); };
        auto r = sign_macos(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().message, "cannot start /usr/bin/codesign"));
        CHECK(has_text(r.error().hint, "xcode-select --install"));
    }
    SUBCASE("cancelled") {
        SignMacosOptions o = g.options("macos");
        CancelFlag cancel;
        cancel = true;
        o.cancel = &cancel;
        o.run = [](const ProcessOptions&) -> Result<ProcessResult> {
            ProcessResult r;
            r.cancelled = true;
            return r;
        };
        auto r = sign_macos(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().message, "cancelled"));
    }
}

TEST_CASE("sign.macos: the app-specific password is passed to notarytool and appears nowhere else") {
    Game g;
    FakeMac mac;
    mac.echoed = {std::string("notarytool: logging in with password ") + kPassword};  // a tool that repeats what it was given
    mac.notaryStatus = "Invalid";
    SignMacosOptions o = g.options("macos");
    o.appleId = "ada@example.com";
    o.teamId = "ABCDE12345";
    o.env = env_of({{"FACTORIA_APPLE_APP_PASSWORD", kPassword}});
    o.run = mac.runner();
    std::vector<std::string> progress;
    o.progress = [&](const std::string& line) { progress.push_back(line); };
    auto r = sign_macos(o);
    REQUIRE_FALSE(r.ok());

    bool passedToTool = false;
    for (const std::string& l : mac.command_lines()) passedToTool = passedToTool || has_text(l, std::string("--password ") + kPassword);
    CHECK(passedToTool);  // notarytool needs it
    CHECK_FALSE(has_text(r.error().message, kPassword));
    CHECK_FALSE(has_text(r.error().hint, kPassword));
    for (const std::string& line : progress) CHECK_FALSE(has_text(line, kPassword));
    CHECK(any_has(progress, "<redacted>"));
}

TEST_CASE("sign.macos: the command") {
    Game g;
    CommandRegistry registry;
    register_sign_commands(registry, g.proj);
    const CommandInfo* info = registry.info("sign.macos");
    REQUIRE(info != nullptr);
    CHECK_FALSE(info->readOnly);
    for (const char* key : {"app", "out", "identity", "keychain", "provisioningProfile", "entitlements", "notarize", "keychainProfile", "apiKey", "apiKeyId", "apiIssuer", "appleId",
                            "teamId", "zip", "dryRun"})
        CHECK_MESSAGE(info->inputSchema["properties"].contains(key), key);
    CHECK_FALSE(info->inputSchema["properties"].contains("password"));  // a password is never an argument
    CHECK_FALSE(info->inputSchema["properties"].contains("appPassword"));
    CHECK(has_text(info->description, "FACTORIA_APPLE_APP_PASSWORD"));
    CHECK(has_text(info->description, "dryRun"));

    auto r = registry.call("sign.macos", Json::object({{"identity", kDeveloperId}, {"out", "../out"}, {"dryRun", true}}));
    CHECK_FALSE(r.ok);  // outside the project
    CHECK(r.error["code"] == "invalid_argument");

    const stdfs::path inProject = stdfs::path(g.proj) / "build" / "export";
    stdfs::create_directories(inProject);
    stdfs::copy(g.app.parent_path(), inProject / "space-dodge-macos", stdfs::copy_options::recursive);
    auto ok = registry.call("sign.macos", Json::object({{"identity", kDeveloperId}, {"notarize", false}, {"dryRun", true}}));
    REQUIRE_MESSAGE(ok.ok, ok.error.dump());
    CHECK(ok.result["dryRun"] == true);
    CHECK(ok.result["identity"] == kDeveloperId);
    CHECK(ok.result["signed"] == false);
    CHECK(ok.result["steps"].is_array());
    CHECK(ok.result["steps"].size() >= 3);
    CHECK(has_text(ok.result["steps"][0]["commandLine"].get<std::string>(), "/usr/bin/codesign"));

    auto none = registry.call("sign.macos", Json::object({{"identity", ""}, {"dryRun", true}, {"app", "build/export/missing.app"}}));
    CHECK_FALSE(none.ok);
    CHECK(none.error["code"] == "failed");
    CHECK_FALSE(none.error["hint"].get<std::string>().empty());
}

#if defined(__APPLE__)
// The one test that signs for real: an ad hoc identity ("-", no certificate, no network) and no notarization, then the system's own
// codesign checks the result.
TEST_CASE("sign.macos on a Mac: an ad hoc signature passes codesign --verify --strict") {
    testing::TempDir tmp;
    const stdfs::path app = tmp.path / "out" / "demo-macos" / "Demo.app";
    testing::write_all(app / "Contents" / "Info.plist",
                       "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
                       "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
                       "<plist version=\"1.0\"><dict><key>CFBundleExecutable</key><string>demo</string>"
                       "<key>CFBundleIdentifier</key><string>com.example.demo</string><key>CFBundleName</key><string>Demo</string>"
                       "<key>CFBundlePackageType</key><string>APPL</string></dict></plist>\n");
    std::error_code ec;
    stdfs::create_directories(app / "Contents" / "MacOS");
    stdfs::copy_file("/usr/bin/true", app / "Contents" / "MacOS" / "demo", stdfs::copy_options::overwrite_existing, ec);
    REQUIRE_MESSAGE(!ec, ec.message());

    SignMacosOptions o;
    o.app = app.string();
    o.identity = "-";
    o.notarize = false;
    o.env = [](const std::string&) { return std::string(); };
    o.toolConfigPath = tmp.sub("no-export.json");
    auto r = sign_macos(o);  // the real codesign and ditto, on the Mac that runs this test
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK(r->signedApp);
    CHECK(r->verified);
    CHECK_FALSE(r->notarized);
    CHECK_FALSE(r->stapled);
    CHECK(stdfs::exists(app.parent_path().parent_path() / "demo-macos.zip"));

    ProcessOptions verify;
    verify.argv = {"/usr/bin/codesign", "--verify", "--strict", "--verbose=2", app.string()};
    auto v = run_process(verify);
    REQUIRE(v.ok());
    CHECK_MESSAGE(v->exitCode == 0, v->stderrText);
    stdfs::path unpacked = tmp.path / "unzipped";
    ProcessOptions unzip;
    unzip.argv = {"/usr/bin/ditto", "-x", "-k", (app.parent_path().parent_path() / "demo-macos.zip").string(), unpacked.string()};
    REQUIRE(run_process(unzip).ok());
    CHECK(stdfs::exists(unpacked / "Demo.app" / "Contents" / "_CodeSignature" / "CodeResources"));
}
#endif
