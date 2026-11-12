// sign.windows (fa/tooling/sign.h) and the .pfx password: it is never an argument of a child process (the process list shows those).
// On Windows the .pfx is imported into the user's certificate store for the run (the password travels in the environment of
// PowerShell), signtool signs by thumbprint, and the certificate is removed again; elsewhere osslsigncode reads the password on stdin.
// Dry runs show the plan on any computer; a fake process runner shows what would be run, in which order, with which environment.
#include <doctest.h>

#include <algorithm>
#include <filesystem>
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

constexpr const char* kSecret = "s3cr3t-pfx-pass-ZZ9";
constexpr const char* kThumbprint = "0123456789ABCDEF0123456789ABCDEF01234567";
constexpr const char* kPasswordVar = "FACTORIA_WINDOWS_PFX_PASSWORD";

bool has_text(const std::string& h, const std::string& n) { return h.find(n) != std::string::npos; }

struct WinGame {
    testing::TempDir tmp;
    std::string proj, out, pfx;

    WinGame() {
        proj = tmp.sub("proj");
        ScaffoldOptions so;
        so.name = "Space Dodge";
        so.id = "com.example.spacedodge";
        REQUIRE(create_project(proj, "2d-platformer", so).ok());
        testing::write_all(tmp.sub("fake_player/factoria_player"), "#!/bin/sh\nexit 0\n");
        out = tmp.sub("out");
        ExportOptions e;
        e.projectDir = proj;
        e.platform = "windows";
        e.format = "msix";
        e.outDir = out;
        e.playerBinary = tmp.sub("fake_player/factoria_player");
        auto exported = export_project(e);
        REQUIRE_MESSAGE(exported.ok(), (exported.ok() ? "" : exported.error().to_string()));
        pfx = tmp.sub("keys") + "/code.pfx";
        testing::write_all(pfx, "not a real pfx");
    }

    SignWindowsOptions options(const std::string& host, const std::string& password = kSecret) {
        SignWindowsOptions o;
        o.projectDir = proj;
        o.outDir = out;
        o.pfx = pfx;
        o.host = host;
        o.toolConfigPath = tmp.sub("no-export.json");
        std::map<std::string, std::string> vars;
        if (!password.empty()) vars[kPasswordVar] = password;
        const std::string fake = tmp.sub("tools") + (host == "windows" ? "/signtool.exe" : "/osslsigncode");
        testing::write_all(fake, "tool");
        vars[host == "windows" ? "FACTORIA_SIGNTOOL" : "FACTORIA_OSSLSIGNCODE"] = fake;
        const std::string openssl = tmp.sub("tools") + "/openssl";  // a fake one: the result must not depend on this computer's openssl
        testing::write_all(openssl, "tool");
        vars["FACTORIA_OPENSSL"] = openssl;
        o.env = [vars](const std::string& name) {
            auto it = vars.find(name);
            return it == vars.end() ? std::string() : it->second;
        };
        return o;
    }
};

// The script a `powershell.exe ... -EncodedCommand <UTF-16LE base64>` step runs.
std::string decode_script(const std::vector<std::string>& argv) {
    const auto at = std::find(argv.begin(), argv.end(), "-EncodedCommand");
    REQUIRE(at != argv.end());
    REQUIRE(at + 1 != argv.end());
    const std::vector<unsigned char> bytes = base64_decode(*(at + 1));
    std::string text;
    for (std::size_t i = 0; i + 1 < bytes.size(); i += 2) text += static_cast<char>(bytes[i]);  // the scripts of this test are ASCII
    return text;
}

bool is_powershell(const ProcessOptions& po) { return stdfs::path(po.argv.at(0)).filename() == "powershell.exe"; }

std::string decode_scripts_or_empty(const ProcessOptions& po) { return is_powershell(po) ? decode_script(po.argv) : std::string(); }

std::string joined_command(const std::vector<std::string>& v) {
    std::string s;
    for (const auto& a : v) s += (s.empty() ? "" : " ") + a;
    return s;
}

struct Calls {
    std::vector<ProcessOptions> list;     // every call but the openssl ones
    std::vector<ProcessOptions> openssl;  // the (optional) check of the certificate's subject
    bool importedByUs = true;       // the import step prints IMPORTED=1 (false: the certificate was in the store already)
    int importExit = 0;
    int signExit = 0;
    int removeExit = 0;

    ProcessRunner runner() {
        return [this](const ProcessOptions& po) -> Result<ProcessResult> {
            ProcessResult pr;
            pr.exitCode = 0;
            if (stdfs::path(po.argv.at(0)).filename() == "openssl") {
                openssl.push_back(po);
                pr.exitCode = 1;  // cannot read the subject of the fake certificate: a warning, not an error
                return pr;
            }
            list.push_back(po);
            if (is_powershell(po)) {
                const std::string script = decode_script(po.argv);
                if (has_text(script, "Import-PfxCertificate")) {
                    pr.exitCode = importExit;
                    pr.stdoutText = std::string("THUMBPRINT=") + kThumbprint + "\r\nIMPORTED=" + (importedByUs ? "1" : "0") + "\r\n";
                } else if (has_text(script, "Remove-Item")) {
                    pr.exitCode = removeExit;
                }
            } else if (stdfs::path(po.argv.at(0)).filename() == "signtool.exe") {
                pr.exitCode = signExit;
                pr.stderrText = std::string("bad password ") + kSecret;  // a careless tool
            } else if (po.argv.size() > 1 && po.argv[1] == "--version") {
                pr.stdoutText = "osslsigncode 2.9.0, using:\n";
            } else if (stdfs::path(po.argv.at(0)).filename() == "osslsigncode" && po.argv.size() > 1 && po.argv[1] == "sign") {
                const auto it = std::find(po.argv.begin(), po.argv.end(), "-out");
                if (it != po.argv.end()) testing::write_all(*(it + 1), "SIGNED");
            }
            return pr;
        };
    }

    std::vector<std::string> titles_of_powershell() const {
        std::vector<std::string> out;
        for (const ProcessOptions& po : list)
            if (is_powershell(po)) out.push_back(decode_script(po.argv));
        return out;
    }
};

void check_no_secret_in_argv(const Calls& calls) {
    for (const auto* v : {&calls.list, &calls.openssl})
        for (const ProcessOptions& po : *v)
            for (const std::string& a : po.argv) CHECK_FALSE(has_text(a, kSecret));
}

}  // namespace

TEST_CASE("sign.windows dry run on Windows: import the .pfx, sign by thumbprint, remove it; the password only in an environment variable") {
    WinGame g;
    SignWindowsOptions o = g.options("windows");
    o.dryRun = true;
    auto r = sign_windows(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    REQUIRE(r->steps.size() == 3);

    const SignStep& import = r->steps[0];
    CHECK(has_text(import.title, "Import the certificate"));
    CHECK(import.env == std::vector<std::string>{kPasswordVar});
    CHECK(has_text(joined_command(import.command), "$env:FACTORIA_WINDOWS_PFX_PASSWORD"));
    CHECK(has_text(joined_command(import.command), "Import-PfxCertificate"));
    CHECK(has_text(joined_command(import.command), "ConvertTo-SecureString"));

    const SignStep& sign = r->steps[1];
    const std::vector<std::string> want = {"sign", "/fd", "SHA256", "/sha1", "<thumbprint>", "/s", "My"};
    CHECK(std::search(sign.command.begin(), sign.command.end(), want.begin(), want.end()) != sign.command.end());
    CHECK(std::find(sign.command.begin(), sign.command.end(), "/p") == sign.command.end());
    CHECK(std::find(sign.command.begin(), sign.command.end(), "/f") == sign.command.end());
    CHECK(sign.env.empty());

    const SignStep& remove = r->steps[2];
    CHECK(has_text(remove.title, "Remove the imported certificate"));
    CHECK(has_text(joined_command(remove.command), "Remove-Item"));

    for (const SignStep& s : r->steps)
        for (const std::string& a : s.command) CHECK_FALSE(has_text(a, kSecret));
    CHECK_FALSE(has_text(r->to_json().dump(), kSecret));
    CHECK(has_text(r->to_json().dump(), kPasswordVar));  // the NAME of the variable is listed, never the value
}

TEST_CASE("sign.windows on Windows runs import, sign and remove in that order; the password is in the environment of the import only") {
    WinGame g;
    Calls calls;
    SignWindowsOptions o = g.options("windows");
    o.run = calls.runner();
    std::vector<std::string> shown;
    o.progress = [&](const std::string& line) { shown.push_back(line); };
    auto r = sign_windows(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    REQUIRE(calls.list.size() >= 3);
    check_no_secret_in_argv(calls);

    // import
    REQUIRE(is_powershell(calls.list[0]));
    CHECK(calls.list[0].env.count(kPasswordVar) == 1);
    CHECK(calls.list[0].env.at(kPasswordVar) == kSecret);
    const std::string importScript = decode_script(calls.list[0].argv);
    CHECK_FALSE(has_text(importScript, kSecret));
    CHECK(has_text(importScript, "$env:FACTORIA_WINDOWS_PFX_PASSWORD"));
    CHECK(has_text(importScript, "code.pfx"));
    // sign: by thumbprint, no password anywhere
    REQUIRE(stdfs::path(calls.list[1].argv.at(0)).filename() == "signtool.exe");
    const std::vector<std::string> want = {"/sha1", kThumbprint, "/s", "My"};
    CHECK(std::search(calls.list[1].argv.begin(), calls.list[1].argv.end(), want.begin(), want.end()) != calls.list[1].argv.end());
    CHECK(calls.list[1].env.count(kPasswordVar) == 0);
    // remove, by that thumbprint
    REQUIRE(is_powershell(calls.list.back()));
    const std::string removeScript = decode_script(calls.list.back().argv);
    CHECK(has_text(removeScript, "Remove-Item"));
    CHECK(has_text(removeScript, kThumbprint));
    CHECK(calls.list.back().env.count(kPasswordVar) == 0);
    CHECK(calls.list.size() == 3);
    for (const std::string& line : shown) CHECK_FALSE(has_text(line, kSecret));
    CHECK_FALSE(has_text(r->to_json().dump(), kSecret));
}

TEST_CASE("sign.windows removes the imported certificate also when signtool fails, and keeps one that was in the store already") {
    WinGame g;
    {
        Calls calls;
        calls.signExit = 1;
        SignWindowsOptions o = g.options("windows");
        o.run = calls.runner();
        auto r = sign_windows(o);
        REQUIRE_FALSE(r.ok());
        CHECK_FALSE(has_text(r.error().message + r.error().hint, kSecret));
        check_no_secret_in_argv(calls);
        const std::vector<std::string> scripts = calls.titles_of_powershell();
        REQUIRE(scripts.size() == 2);
        CHECK(has_text(scripts.back(), "Remove-Item"));
        CHECK(has_text(scripts.back(), kThumbprint));
    }
    {  // already in the store before the run: nothing to remove
        Calls calls;
        calls.importedByUs = false;
        SignWindowsOptions o = g.options("windows");
        o.run = calls.runner();
        auto r = sign_windows(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        const std::vector<std::string> scripts = calls.titles_of_powershell();
        REQUIRE(scripts.size() == 1);
        CHECK(has_text(scripts[0], "Import-PfxCertificate"));
        for (const ProcessOptions& po : calls.list) CHECK_FALSE(has_text(decode_scripts_or_empty(po), "Remove-Item"));
    }
    {  // the import fails (wrong password): the error teaches, shows no secret, and there is nothing to remove
        Calls calls;
        calls.importExit = 1;
        SignWindowsOptions o = g.options("windows");
        o.run = calls.runner();
        auto r = sign_windows(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().hint, kPasswordVar));
        CHECK_FALSE(has_text(r.error().message + r.error().hint, kSecret));
        CHECK(calls.list.size() == 1);
    }
}

TEST_CASE("sign.windows without a password: the import step sets no variable and the script has no ConvertTo-SecureString") {
    WinGame g;
    SignWindowsOptions o = g.options("windows", "");
    o.dryRun = true;
    auto r = sign_windows(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    REQUIRE(r->steps.size() == 3);
    CHECK(r->steps[0].env.empty());
    CHECK_FALSE(has_text(joined_command(r->steps[0].command), "ConvertTo-SecureString"));
}

TEST_CASE("sign.windows with osslsigncode: the password goes on stdin (-readpass -), not in the argument list") {
    WinGame g;
    {  // dry run
        SignWindowsOptions o = g.options("linux");
        o.dryRun = true;
        auto r = sign_windows(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        const SignStep& sign = r->steps.back();
        const std::vector<std::string> want = {"-readpass", "-"};
        CHECK(std::search(sign.command.begin(), sign.command.end(), want.begin(), want.end()) != sign.command.end());
        CHECK(std::find(sign.command.begin(), sign.command.end(), "-pass") == sign.command.end());
        CHECK(sign.stdinSecret);
        for (const SignStep& s : r->steps)
            for (const std::string& a : s.command) CHECK_FALSE(has_text(a, kSecret));
        CHECK_FALSE(has_text(r->to_json().dump(), kSecret));
    }
    {  // run
        Calls calls;
        SignWindowsOptions o = g.options("linux");
        o.run = calls.runner();
        auto r = sign_windows(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        check_no_secret_in_argv(calls);
        bool fed = false;
        for (const ProcessOptions& po : calls.list)
            if (std::find(po.argv.begin(), po.argv.end(), "-readpass") != po.argv.end()) {
                fed = po.stdinText == std::string(kSecret) + "\n";
                CHECK(po.env.count(kPasswordVar) == 0);
            }
        CHECK(fed);
    }
    {  // no password: no -readpass, nothing on stdin (the run above replaced the package with the fake tool's output: export again)
        WinGame g2;
        SignWindowsOptions o = g2.options("linux", "");
        o.dryRun = true;
        auto r = sign_windows(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        const SignStep& sign = r->steps.back();
        CHECK(std::find(sign.command.begin(), sign.command.end(), "-readpass") == sign.command.end());
        CHECK_FALSE(sign.stdinSecret);
    }
}

TEST_CASE("sign.windows testCertificate makes no password step: it signs with the thumbprint of the certificate it made") {
    WinGame g;
    SignWindowsOptions o = g.options("windows");
    o.pfx.clear();
    o.testCertificate = true;
    o.dryRun = true;
    auto r = sign_windows(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    REQUIRE(r->steps.size() == 2);
    for (const SignStep& s : r->steps) CHECK(s.env.empty());
    const std::vector<std::string> want = {"/sha1", "<thumbprint>", "/s", "My"};
    CHECK(std::search(r->steps[1].command.begin(), r->steps[1].command.end(), want.begin(), want.end()) != r->steps[1].command.end());
}
