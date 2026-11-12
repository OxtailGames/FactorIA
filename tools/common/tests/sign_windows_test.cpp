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
    bool present = false;           // the thumbprint step prints PRESENT=1: the certificate (with its key) is in the store already
    bool importedByUs = true;       // the import step prints IMPORTED=1 (false: the certificate was in the store already)
    bool bom = false;               // Windows PowerShell can print a byte order mark before the first line
    int thumbprintExit = 0;
    int importExit = 0;
    bool importCancelled = false;   // the import is cancelled half way
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
                if (has_text(script, "PRESENT=")) {  // step 1: the thumbprint
                    pr.exitCode = thumbprintExit;
                    pr.stdoutText = std::string(bom ? "\xEF\xBB\xBF" : "") + "THUMBPRINT=" + kThumbprint + "\r\nPRESENT=" + (present ? "1" : "0") + "\r\n";
                } else if (has_text(script, "X509Store")) {  // step 2: the import
                    pr.exitCode = importExit;
                    pr.cancelled = importCancelled;
                    pr.stdoutText = std::string("IMPORTED=") + (importedByUs ? "1" : "0") + "\r\n";
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
    REQUIRE(r->steps.size() == 4);

    const SignStep& thumbprint = r->steps[0];
    CHECK(has_text(thumbprint.title, "Read the thumbprint"));
    CHECK(thumbprint.env == std::vector<std::string>{kPasswordVar});
    CHECK(has_text(joined_command(thumbprint.command), "$env:FACTORIA_WINDOWS_PFX_PASSWORD"));
    CHECK_FALSE(has_text(joined_command(thumbprint.command), "X509Store"));  // it imports nothing

    const SignStep& import = r->steps[1];
    CHECK(has_text(import.title, "Import the certificate"));
    CHECK(import.env == std::vector<std::string>{kPasswordVar});
    CHECK(has_text(joined_command(import.command), "$env:FACTORIA_WINDOWS_PFX_PASSWORD"));
    CHECK(has_text(joined_command(import.command), "X509Store"));

    const SignStep& sign = r->steps[2];
    const std::vector<std::string> want = {"sign", "/fd", "SHA256", "/sha1", "<thumbprint>", "/s", "My"};
    CHECK(std::search(sign.command.begin(), sign.command.end(), want.begin(), want.end()) != sign.command.end());
    CHECK(std::find(sign.command.begin(), sign.command.end(), "/p") == sign.command.end());
    CHECK(std::find(sign.command.begin(), sign.command.end(), "/f") == sign.command.end());
    CHECK(sign.env.empty());

    const SignStep& remove = r->steps[3];
    CHECK(has_text(remove.title, "Remove the imported certificate"));
    CHECK(has_text(joined_command(remove.command), "Remove-Item"));

    for (const SignStep& s : r->steps)
        for (const std::string& a : s.command) CHECK_FALSE(has_text(a, kSecret));
    CHECK_FALSE(has_text(r->to_json().dump(), kSecret));
    CHECK(has_text(r->to_json().dump(), kPasswordVar));  // the NAME of the variable is listed, never the value
}

TEST_CASE("sign.windows on Windows reads the thumbprint, imports, signs and removes in that order; the password is in the environment of the first two only") {
    WinGame g;
    Calls calls;
    SignWindowsOptions o = g.options("windows");
    o.run = calls.runner();
    std::vector<std::string> shown;
    o.progress = [&](const std::string& line) { shown.push_back(line); };
    auto r = sign_windows(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    REQUIRE(calls.list.size() == 4);
    check_no_secret_in_argv(calls);

    // 1. the thumbprint: imports nothing
    REQUIRE(is_powershell(calls.list[0]));
    CHECK(calls.list[0].env.count(kPasswordVar) == 1);
    CHECK(calls.list[0].env.at(kPasswordVar) == kSecret);
    const std::string thumbprintScript = decode_script(calls.list[0].argv);
    CHECK_FALSE(has_text(thumbprintScript, kSecret));
    CHECK(has_text(thumbprintScript, "$env:FACTORIA_WINDOWS_PFX_PASSWORD"));
    CHECK(has_text(thumbprintScript, "code.pfx"));
    CHECK(has_text(thumbprintScript, "X509Certificate2Collection"));
    CHECK(has_text(thumbprintScript, "HasPrivateKey"));
    CHECK_FALSE(has_text(thumbprintScript, "X509Store"));
    CHECK_FALSE(has_text(thumbprintScript, "Import-PfxCertificate"));
    CHECK_FALSE(has_text(thumbprintScript, "Remove-Item"));
    // default key flags (EphemeralKeySet is missing before .NET Framework 4.7.2), nothing persisted, the temporary keys reset
    CHECK(has_text(thumbprintScript, "DefaultKeySet"));
    CHECK_FALSE(has_text(thumbprintScript, "EphemeralKeySet"));
    CHECK_FALSE(has_text(thumbprintScript, "PersistKeySet"));
    CHECK(has_text(thumbprintScript, "$c.Reset()"));
    // 2. the import: only the certificate with the private key, through X509Store, under the named mutex
    REQUIRE(is_powershell(calls.list[1]));
    CHECK(calls.list[1].env.count(kPasswordVar) == 1);
    const std::string importScript = decode_script(calls.list[1].argv);
    CHECK_FALSE(has_text(importScript, kSecret));
    CHECK(has_text(importScript, "$env:FACTORIA_WINDOWS_PFX_PASSWORD"));
    CHECK(has_text(importScript, "X509Store('My', 'CurrentUser')"));
    CHECK(has_text(importScript, "$_.Thumbprint -eq $t -and $_.HasPrivateKey"));  // "already there" counts only with its key
    CHECK(has_text(importScript, std::string("'") + kThumbprint + "'"));
    CHECK(has_text(importScript, "System.Threading.Mutex"));
    CHECK_FALSE(has_text(importScript, "Import-PfxCertificate"));  // that would import the chain certificates too
    // the mutex is the user's, across logon sessions
    CHECK(has_text(importScript, "'Global\\FactorIA-sign-windows-store-' + [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value"));
    // the order inside the mutex: look in the store first, only then load the file (PersistKeySet writes the key to disk), then add
    const std::size_t check = importScript.find("$had = ");
    const std::size_t load = importScript.find("PersistKeySet, UserKeySet");  // UserKeySet: never the machine's key folder
    const std::size_t add = importScript.find("$store.Add($x)");
    REQUIRE(check != std::string::npos);
    REQUIRE(load != std::string::npos);
    REQUIRE(add != std::string::npos);
    const std::size_t handler = importScript.find("catch {", add);
    REQUIRE(handler != std::string::npos);
    CHECK(check < load);
    CHECK(load < add);
    CHECK(add < handler);
    const std::size_t import = importScript.find("$col.Import");
    CHECK(import != std::string::npos);
    CHECK(import > check);  // no load before the check
    CHECK(import < load);
    CHECK(import == importScript.rfind("$col.Import"));  // one load only
    // nothing but choosing the certificate between the load and the add
    const std::string between = importScript.substr(load, add - load);
    CHECK_FALSE(has_text(between, "$store.Open"));
    CHECK_FALSE(has_text(between, "WaitOne"));
    CHECK_FALSE(has_text(between, "throw"));
    // a failed add deletes the persisted keys (CNG and CAPI), also of the chain certificates that never get into the store
    CHECK(has_text(importScript.substr(handler, 120), "$drop"));
    CHECK(has_text(importScript, "$k.Key.Delete()"));
    CHECK(has_text(importScript, "$k.PersistKeyInCsp = $false; $k.Clear()"));
    CHECK(has_text(importScript, "ReferenceEquals($c, $x)"));
    // 3. sign: by thumbprint, no password anywhere
    REQUIRE(stdfs::path(calls.list[2].argv.at(0)).filename() == "signtool.exe");
    const std::vector<std::string> want = {"/sha1", kThumbprint, "/s", "My"};
    CHECK(std::search(calls.list[2].argv.begin(), calls.list[2].argv.end(), want.begin(), want.end()) != calls.list[2].argv.end());
    CHECK(calls.list[2].env.count(kPasswordVar) == 0);
    // 4. remove, by that thumbprint, under the same mutex
    REQUIRE(is_powershell(calls.list.back()));
    const std::string removeScript = decode_script(calls.list.back().argv);
    CHECK(has_text(removeScript, "Remove-Item"));
    CHECK(has_text(removeScript, kThumbprint));
    CHECK(has_text(removeScript, "System.Threading.Mutex"));
    CHECK(calls.list.back().env.count(kPasswordVar) == 0);
    CHECK(calls.list.back().timeoutSeconds > 120);  // longer than the mutex wait, so a hung PowerShell cannot hold the run for ever
    CHECK(calls.list.back().timeoutSeconds < 600);
    for (const std::string& line : shown) CHECK_FALSE(has_text(line, kSecret));
    CHECK_FALSE(has_text(r->to_json().dump(), kSecret));
}

TEST_CASE("sign.windows parses the thumbprint when PowerShell prints a byte order mark and CRLF lines") {
    WinGame g;
    Calls calls;
    calls.bom = true;
    SignWindowsOptions o = g.options("windows");
    o.run = calls.runner();
    auto r = sign_windows(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    REQUIRE(calls.list.size() == 4);
    const std::vector<std::string> want = {"/sha1", kThumbprint, "/s", "My"};  // the whole thumbprint, nothing of the BOM or the CR
    CHECK(std::search(calls.list[2].argv.begin(), calls.list[2].argv.end(), want.begin(), want.end()) != calls.list[2].argv.end());
    CHECK(has_text(decode_script(calls.list.back().argv), std::string("My\\") + kThumbprint + "'"));
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
        REQUIRE(scripts.size() == 3);  // thumbprint, import, remove
        CHECK(has_text(scripts.back(), "Remove-Item"));
        CHECK(has_text(scripts.back(), kThumbprint));
    }
    {  // already in the store (with its key) before the run: nothing to remove
        Calls calls;
        calls.present = true;
        calls.importedByUs = false;
        SignWindowsOptions o = g.options("windows");
        o.run = calls.runner();
        auto r = sign_windows(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        // the file is not loaded again: only the thumbprint step and signtool run (a second load would leave one more key on disk)
        const std::vector<std::string> scripts = calls.titles_of_powershell();
        REQUIRE(scripts.size() == 1);
        CHECK(has_text(scripts[0], "PRESENT="));
        CHECK(calls.list.size() == 2);
        for (const ProcessOptions& po : calls.list) {
            CHECK_FALSE(has_text(decode_scripts_or_empty(po), "X509Store"));
            CHECK_FALSE(has_text(decode_scripts_or_empty(po), "Remove-Item"));
        }
    }
    {  // another run put it there between the two steps: the import says so, and it is not ours to remove
        Calls calls;
        calls.present = false;
        calls.importedByUs = false;
        SignWindowsOptions o = g.options("windows");
        o.run = calls.runner();
        auto r = sign_windows(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        for (const ProcessOptions& po : calls.list) CHECK_FALSE(has_text(decode_scripts_or_empty(po), "Remove-Item"));
    }
    {  // the thumbprint step fails (wrong password): the error teaches, shows no secret, nothing was imported, so nothing is removed
        Calls calls;
        calls.thumbprintExit = 1;
        SignWindowsOptions o = g.options("windows");
        o.run = calls.runner();
        auto r = sign_windows(o);
        REQUIRE_FALSE(r.ok());
        CHECK(has_text(r.error().hint, kPasswordVar));
        CHECK_FALSE(has_text(r.error().message + r.error().hint, kSecret));
        CHECK(calls.list.size() == 1);
    }
}

TEST_CASE("sign.windows removes the certificate after an import that failed or was cancelled half way") {
    WinGame g;
    for (const bool cancelled : {false, true}) {
        INFO("cancelled: " << cancelled);
        Calls calls;
        calls.importExit = cancelled ? 0 : 1;
        calls.importCancelled = cancelled;
        SignWindowsOptions o = g.options("windows");
        o.run = calls.runner();
        auto r = sign_windows(o);
        REQUIRE_FALSE(r.ok());
        CHECK_FALSE(has_text(r.error().message + r.error().hint, kSecret));
        if (cancelled) CHECK(has_text(r.error().message, "cancelled"));
        else CHECK(has_text(r.error().hint, kPasswordVar));
        const std::vector<std::string> scripts = calls.titles_of_powershell();
        REQUIRE(scripts.size() == 3);  // thumbprint, import, remove: the import may have put the key in the store before it stopped
        CHECK(has_text(scripts.back(), "Remove-Item"));
        CHECK(has_text(scripts.back(), kThumbprint));
        CHECK(calls.list.size() == 3);  // signtool never started
    }
}

TEST_CASE("sign.windows: a certificate that could not be removed is named in the hint of the error that stopped the run") {
    WinGame g;
    Calls calls;
    calls.signExit = 1;
    calls.removeExit = 1;
    SignWindowsOptions o = g.options("windows");
    o.run = calls.runner();
    auto r = sign_windows(o);
    REQUIRE_FALSE(r.ok());
    CHECK(has_text(r.error().message, "failed"));
    CHECK(has_text(r.error().hint, "could not be removed"));
    CHECK(has_text(r.error().hint, kThumbprint));
    CHECK(has_text(r.error().hint, "certmgr.msc"));
}

TEST_CASE("sign.windows quotes a path for PowerShell: the ASCII quote and the typographic single quotes are doubled") {
    WinGame g;
    // ' U+2018 U+2019 U+201A U+201B (the literals are split: "a" after a hex escape would be read as part of it)
    // The folder names are built from UTF-8 (u8string), never from a narrow string: on Windows that goes through the ANSI code page.
    const auto utf8 = [](const std::filesystem::path& p) {
        const std::u8string u = p.generic_u8string();
        return std::string(u.begin(), u.end());
    };
    const std::filesystem::path dir = g.tmp.path / std::filesystem::path(std::u8string(u8"it's \u2018a\u2019 \u201A\u201B x"));
    testing::write_all(dir / "code.pfx", "not a real pfx");
    SignWindowsOptions o = g.options("windows");
    o.pfx = utf8(dir / "code.pfx");
    o.dryRun = true;
    auto r = sign_windows(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    const std::string script = r->steps.at(0).command.back();  // the command line shows the script as it is (UTF-8)
    CHECK(has_text(script, "it''s "));
    CHECK(has_text(script, "\xE2\x80\x98\xE2\x80\x98" "a\xE2\x80\x99\xE2\x80\x99 "));
    CHECK(has_text(script, "\xE2\x80\x9A\xE2\x80\x9A\xE2\x80\x9B\xE2\x80\x9B x"));
    CHECK_FALSE(has_text(script, "\xE2\x80\x98" "a\xE2\x80\x99 "));  // never a single one
    // other characters that start with the same bytes are left alone (U+201C is a double quote)
    const std::filesystem::path other = g.tmp.path / std::filesystem::path(std::u8string(u8"say \u201Chi\u201D"));
    testing::write_all(other / "code.pfx", "not a real pfx");
    o.pfx = utf8(other / "code.pfx");
    auto r2 = sign_windows(o);
    REQUIRE_MESSAGE(r2.ok(), (r2.ok() ? "" : r2.error().to_string()));
    CHECK(has_text(r2->steps.at(0).command.back(), "say \xE2\x80\x9C" "hi\xE2\x80\x9D/code.pfx'"));
}

TEST_CASE("sign.windows without a password: the steps set no variable and the scripts read none") {
    WinGame g;
    SignWindowsOptions o = g.options("windows", "");
    o.dryRun = true;
    auto r = sign_windows(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    REQUIRE(r->steps.size() == 4);
    for (const SignStep& s : r->steps) CHECK(s.env.empty());
    CHECK_FALSE(has_text(joined_command(r->steps[0].command), "$env:FACTORIA_WINDOWS_PFX_PASSWORD"));
    CHECK_FALSE(has_text(joined_command(r->steps[1].command), "$env:FACTORIA_WINDOWS_PFX_PASSWORD"));
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
