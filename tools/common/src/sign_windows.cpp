// sign.windows: Authenticode signing of the MSIX package (and the exe) with a .pfx, through signtool on Windows or osslsigncode
// elsewhere. Behaviour: fa/tooling/sign.h and docs/EXPORTING.md ("Microsoft Store"). A package for the Store itself is uploaded
// unsigned: the Store signs it.
#include <algorithm>
#include <cctype>
#include <filesystem>
#include <functional>
#include <map>
#include <regex>

#include "export_internal.h"
#include "export_zip.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/tooling/project_fs.h"
#include "fa/tooling/sign.h"
#include "util.h"

namespace fa {

namespace {

namespace stdfs = std::filesystem;
using export_detail::generic;
using export_detail::os_path;

constexpr const char* kRedacted = "<redacted>";
constexpr const char* kDefaultTimestamp = "http://timestamp.digicert.com";
constexpr const char* kPasswordVar = "FACTORIA_WINDOWS_PFX_PASSWORD";

Error err(std::string message, std::string hint = {}) { return Error{std::move(message), std::move(hint)}; }

bool is_file(const stdfs::path& p) {
    std::error_code ec;
    return stdfs::is_regular_file(os_path(p), ec);
}

std::string display_command(const std::vector<std::string>& argv) {
    std::string out;
    for (const std::string& a : argv) {
        const bool plain = !a.empty() && a.find_first_not_of("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-./:=@+,\\") == std::string::npos;
        out += (out.empty() ? "" : " ") + (plain ? a : export_detail::sh_quote(a));
    }
    return out;
}

std::string scrub(std::string line, const std::vector<std::string>& secrets) {
    for (const std::string& s : secrets)
        if (!s.empty()) line = replace_all(std::move(line), s, kRedacted);
    return line;
}

std::string last_lines(const std::string& text, std::size_t n) {
    std::vector<std::string> tail;
    for (const std::string& line : split(text, '\n')) {
        std::string t(trim(line));
        if (t.empty()) continue;
        tail.push_back(std::move(t));
        if (tail.size() > n) tail.erase(tail.begin());
    }
    std::string out;
    for (const std::string& l : tail) out += (out.empty() ? "" : " | ") + l;
    return out;
}

// ---- ~/.factoria/export.json: "sign": {"windows": {"pfx"}} -----------------------------------------------------------------

Result<std::string> read_machine_pfx(const std::string& configPath) {
    std::error_code ec;
    if (!stdfs::exists(stdfs::path(configPath), ec)) return std::string();
    auto text = tooling_detail::read_file(stdfs::path(configPath));
    if (!text) return err("sign.windows: cannot read " + configPath, "Check that the file is readable, or delete it.");
    auto parsed = parse_json(*text, configPath);
    if (!parsed.ok()) return err("sign.windows: " + parsed.error().message, "Fix the JSON of " + configPath + " (or delete it).");
    if (!parsed->is_object()) return std::string();
    auto sign = parsed->find("sign");
    if (sign == parsed->end() || !sign->is_object()) return std::string();
    auto windows = sign->find("windows");
    if (windows == sign->end() || !windows->is_object()) return std::string();
    auto pfx = windows->find("pfx");
    if (pfx == windows->end() || pfx->is_null()) return std::string();
    if (!pfx->is_string())
        return err("sign.windows: " + configPath + "#/sign/windows/pfx: expected a string, got " + describe_json_value(*pfx),
                   "Write {\"sign\": {\"windows\": {\"pfx\": \"C:/keys/my-code-signing.pfx\"}}}. The password does not go here: set " + std::string(kPasswordVar) + ".");
    return pfx->get<std::string>();
}

// ---- the tool -----------------------------------------------------------------------------------------------------------

// The newest signtool.exe of the Windows SDK ("" = none installed).
std::string windows_sdk_signtool(const ExportEnvLookup& env) {
    std::vector<stdfs::path> roots;
    for (const char* var : {"ProgramFiles(x86)", "ProgramFiles"})
        if (const std::string v = env(var); !v.empty()) roots.push_back(stdfs::path(v) / "Windows Kits" / "10" / "bin");
    roots.push_back(stdfs::path("C:/Program Files (x86)/Windows Kits/10/bin"));
    std::vector<stdfs::path> found;
    for (const stdfs::path& root : roots) {
        std::error_code ec;
        for (stdfs::directory_iterator it(os_path(root), ec), end; !ec && it != end; it.increment(ec)) {
            const stdfs::path candidate = it->path() / "x64" / "signtool.exe";
            if (is_file(candidate)) found.push_back(candidate);
        }
        if (is_file(root / "x64" / "signtool.exe")) found.push_back(root / "x64" / "signtool.exe");
    }
    std::sort(found.begin(), found.end(), [](const stdfs::path& a, const stdfs::path& b) { return generic(a) > generic(b); });
    return found.empty() ? std::string() : generic(found.front());
}

Result<MachineToolFound> find_signing_tool(bool windows, const ExportEnvLookup& env, const std::string& configPath) {
    MachineTool tool;
    tool.label = "sign.windows";
    if (windows) {
        tool.tool = "signtool";
        tool.envVar = "FACTORIA_SIGNTOOL";
        tool.configKey = "signtool";
        tool.exeNames = {"signtool"};
        tool.download = "https://developer.microsoft.com/windows/downloads/windows-sdk/ (install the 'Windows SDK Signing Tools for Desktop Apps' component)";
        if (env(tool.envVar).empty()) {
            if (const std::string sdk = windows_sdk_signtool(env); !sdk.empty()) return MachineToolFound{sdk, "Windows SDK"};
        }
    } else {
        tool.tool = "osslsigncode";
        tool.envVar = "FACTORIA_OSSLSIGNCODE";
        tool.configKey = "osslsigncode";
        tool.exeNames = {"osslsigncode"};
        tool.download = "https://github.com/mtrojnar/osslsigncode (brew install osslsigncode; apt install osslsigncode)";
    }
    return find_machine_tool(tool, env, configPath);
}

// "osslsigncode 2.9.0, using:" -> {2, 9}; {0, 0} when unreadable.
std::pair<int, int> osslsigncode_version(const std::string& text) {
    static const std::regex re(R"((\d+)\.(\d+))");
    std::smatch m;
    if (!std::regex_search(text, m, re)) return {0, 0};
    return {std::stoi(m[1].str()), std::stoi(m[2].str())};
}

// ---- the manifest and the certificate subject ------------------------------------------------------------------------------

std::string xml_unescape(std::string s) {
    for (const auto& [from, to] : std::vector<std::pair<const char*, const char*>>{{"&lt;", "<"}, {"&gt;", ">"}, {"&quot;", "\""}, {"&apos;", "'"}, {"&amp;", "&"}})
        s = replace_all(std::move(s), from, to);
    return s;
}

// Package/Identity/@Publisher of AppxManifest.xml inside the package.
Result<std::string> manifest_publisher(const stdfs::path& msix) {
    auto xml = export_detail::zip_read_entry(msix, "AppxManifest.xml");
    if (!xml.ok())
        return err("sign.windows: " + xml.error().message, "Pass the .msix that `project.export --platform windows --format msix` wrote (an MSIX is a zip with AppxManifest.xml inside).");
    const std::size_t id = xml->find("<Identity");
    const std::size_t at = id == std::string::npos ? id : xml->find("Publisher=\"", id);
    if (at == std::string::npos) return err("sign.windows: " + generic(msix) + ": AppxManifest.xml has no <Identity Publisher=\"...\">", "Export the package again.");
    const std::size_t from = at + 11, to = xml->find('"', from);
    if (to == std::string::npos) return err("sign.windows: " + generic(msix) + ": AppxManifest.xml is damaged", "Export the package again.");
    return xml_unescape(xml->substr(from, to - from));
}

// "CN=Ada, O=Org" -> sorted lower-case RDNs, so that the order OpenSSL prints does not matter.
std::vector<std::string> distinguished_name_parts(const std::string& dn) {
    std::vector<std::string> parts;
    std::string cur;
    bool quoted = false;
    for (std::size_t i = 0; i < dn.size(); ++i) {
        const char c = dn[i];
        if (c == '\\' && i + 1 < dn.size()) {
            cur += dn[++i];  // an escaped character is part of the value
        } else if (c == '"') {
            quoted = !quoted;
        } else if ((c == ',' || c == ';') && !quoted) {
            if (!trim(cur).empty()) parts.push_back(to_lower(std::string(trim(cur))));
            cur.clear();
        } else {
            cur += c;
        }
    }
    if (!trim(cur).empty()) parts.push_back(to_lower(std::string(trim(cur))));
    for (std::string& p : parts) {  // "cn = x" -> "cn=x"
        const std::size_t eq = p.find('=');
        if (eq != std::string::npos) p = std::string(trim(std::string_view(p).substr(0, eq))) + "=" + std::string(trim(std::string_view(p).substr(eq + 1)));
    }
    std::sort(parts.begin(), parts.end());
    return parts;
}

// ---- running ------------------------------------------------------------------------------------------------------------

struct Step {
    std::vector<std::string> argv;
    std::vector<std::string> shown;       // the command line the report shows (secrets replaced)
    std::map<std::string, std::string> env;
    std::string stdinText;
    bool stdinSecret = false;             // stdinText carries a password
};

class Runner {
public:
    Runner(const SignWindowsOptions& o, SignWindowsReport& report, std::vector<std::string> secrets) : o_(o), report_(report), secrets_(std::move(secrets)) {}

    Result<ProcessResult> go(const std::string& title, Step step, bool record = true) {
        SignStep rec;
        rec.title = title;
        rec.command = step.shown.empty() ? step.argv : step.shown;
        for (const auto& kv : step.env) rec.env.push_back(kv.first);
        rec.stdinSecret = step.stdinSecret;
        if (o_.dryRun) {
            if (record) report_.steps.push_back(std::move(rec));
            ProcessResult fake;
            fake.exitCode = 0;
            return fake;
        }
        auto line = [this](std::string_view l) {
            if (o_.progress) o_.progress(scrub(std::string(l), secrets_));
        };
        ProcessOptions po;
        po.argv = step.argv;
        po.env = step.env;
        po.stdinText = step.stdinText;
        po.cancel = o_.cancel;
        po.onStdoutLine = line;
        po.onStderrLine = line;
        auto run = o_.run ? o_.run(po) : run_process(po);
        if (!run.ok()) {
            if (record) report_.steps.push_back(std::move(rec));
            return err("sign.windows: " + title + ": cannot start " + step.argv[0] + ": " + scrub(run.error().message, secrets_),
                       run.error().hint.empty() ? "Check the path of the tool (FACTORIA_SIGNTOOL / FACTORIA_OSSLSIGNCODE)." : run.error().hint);
        }
        rec.ran = true;
        rec.exitCode = run->exitCode;
        if (record) report_.steps.push_back(std::move(rec));
        run->stdoutText = scrub(std::move(run->stdoutText), secrets_);
        run->stderrText = scrub(std::move(run->stderrText), secrets_);
        if (run->cancelled || is_cancelled(o_.cancel)) return err("sign.windows: cancelled during " + title, "Run it again; signing a package twice is safe.");
        if (run->timedOut) return err("sign.windows: " + title + " did not finish in time", "Run it again.");
        return run;
    }

    Error failed(const std::string& title, const std::vector<std::string>& shown, const ProcessResult& r, const std::string& hint) const {
        const std::string said = last_lines(r.stderrText.empty() ? r.stdoutText : r.stderrText + "\n" + r.stdoutText, 6);
        return err("sign.windows: " + title + " failed (" + display_command(shown) + " exited with code " + std::to_string(r.exitCode) + ")" +
                       (said.empty() ? std::string(".") : ". It said: " + said),
                   hint);
    }

private:
    const SignWindowsOptions& o_;
    SignWindowsReport& report_;
    std::vector<std::string> secrets_;
};

// PowerShell's -EncodedCommand: the script as UTF-16LE, base64. `utf8` is decoded (a path with accents stays one character);
// a byte sequence that is not UTF-8 becomes U+FFFD.
std::string utf16le_base64(const std::string& utf8) {
    std::string bytes;
    const auto put = [&bytes](unsigned unit) {
        bytes += static_cast<char>(unit & 0xff);
        bytes += static_cast<char>((unit >> 8) & 0xff);
    };
    std::size_t i = 0;
    while (i < utf8.size()) {
        const unsigned char c = static_cast<unsigned char>(utf8[i]);
        unsigned cp = c;
        std::size_t extra = 0;
        if (c >= 0xf0 && c < 0xf8) { cp = c & 0x07u; extra = 3; }
        else if (c >= 0xe0 && c < 0xf0) { cp = c & 0x0fu; extra = 2; }
        else if (c >= 0xc0 && c < 0xe0) { cp = c & 0x1fu; extra = 1; }
        else if (c >= 0x80) { put(0xfffd); ++i; continue; }
        bool good = i + extra < utf8.size();  // the whole sequence is there
        for (std::size_t k = 1; good && k <= extra; ++k) {
            const unsigned char cc = static_cast<unsigned char>(utf8[i + k]);
            if ((cc & 0xc0) != 0x80) good = false;
            else cp = (cp << 6) | (cc & 0x3fu);
        }
        if (!good) { put(0xfffd); ++i; continue; }
        i += extra + 1;
        if (cp >= 0x10000) {
            cp -= 0x10000;
            put(0xd800 + (cp >> 10));
            put(0xdc00 + (cp & 0x3ff));
        } else {
            put(cp);
        }
    }
    return base64_encode(bytes.data(), bytes.size());
}

std::string ps_quote(const std::string& s) { return "'" + replace_all(s, "'", "''") + "'"; }

// The PowerShell that finds (or creates) a self-signed code-signing certificate whose subject is `publisher`, saves its public
// part to `cer` and prints THUMBPRINT=<hex>. The private key stays in the user's certificate store.
std::string test_certificate_script(const std::string& publisher, const std::string& cer) {
    return "$ErrorActionPreference = 'Stop'; $subject = " + ps_quote(publisher) +
           "; $c = Get-ChildItem Cert:\\CurrentUser\\My | Where-Object { $_.Subject -eq $subject -and $_.FriendlyName -eq 'FactorIA test certificate' -and $_.NotAfter -gt (Get-Date).AddDays(7) } | Select-Object -First 1; "
           "if (-not $c) { $c = New-SelfSignedCertificate -Type Custom -Subject $subject -KeyUsage DigitalSignature -FriendlyName 'FactorIA test certificate' "
           "-CertStoreLocation 'Cert:\\CurrentUser\\My' -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3', '2.5.29.19={text}') }; "
           "Export-Certificate -Cert $c -FilePath " + ps_quote(cer) + " | Out-Null; Write-Output ('THUMBPRINT=' + $c.Thumbprint)";
}

// The PowerShell that makes the .pfx usable by signtool WITHOUT the password reaching a command line: it reads the password from the
// environment variable of its own process ($env:FACTORIA_WINDOWS_PFX_PASSWORD, set by the runner), never from the script text.
// It reads the thumbprint from the file, imports the .pfx into Cert:\CurrentUser\My unless a certificate with that thumbprint is
// already there, and prints THUMBPRINT=<hex> and IMPORTED=1 (we put it there: remove it afterwards) or IMPORTED=0 (it was there).
std::string import_pfx_script(const std::string& pfx, bool withPassword) {
    std::string s = "$ErrorActionPreference = 'Stop'; $pfx = " + ps_quote(pfx) + "; ";
    if (withPassword) s += "$pw = ConvertTo-SecureString -String $env:" + std::string(kPasswordVar) + " -AsPlainText -Force; ";
    s += std::string("$x = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList ") + (withPassword ? "@($pfx, $pw)" : "@($pfx)") +
         "; $t = $x.Thumbprint; $x.Reset(); "
         "$had = Test-Path -LiteralPath ('Cert:\\CurrentUser\\My\\' + $t); "
         "if (-not $had) { Import-PfxCertificate -FilePath $pfx -CertStoreLocation 'Cert:\\CurrentUser\\My'" + (withPassword ? " -Password $pw" : "") + " | Out-Null }; "
         "Write-Output ('THUMBPRINT=' + $t); Write-Output ('IMPORTED=' + [int](-not $had))";
    return s;
}

// Removes the certificate (and its private key) that import_pfx_script put in the user's store.
std::string remove_certificate_script(const std::string& thumbprint) {
    return "$ErrorActionPreference = 'Stop'; Remove-Item -Path " + ps_quote("Cert:\\CurrentUser\\My\\" + thumbprint) + " -DeleteKey";
}

// A certificate thumbprint as PowerShell prints it: 40 hexadecimal digits (SHA-1); longer hashes are accepted too.
bool is_thumbprint(const std::string& t) {
    if (t.size() < 40 || t.size() > 128) return false;
    return std::all_of(t.begin(), t.end(), [](unsigned char c) { return std::isxdigit(c) != 0; });
}

}  // namespace

Json SignWindowsReport::to_json() const {
    Json j = Json::object();
    j["msix"] = msix;
    j["exe"] = exe;
    j["publisher"] = publisher;
    j["certificate"] = certificate;
    j["certificateFrom"] = certificateFrom;
    j["tool"] = tool;
    j["toolPath"] = toolPath;
    j["timestampUrl"] = timestampUrl;
    j["dryRun"] = dryRun;
    j["signedMsix"] = signedMsix;
    j["signedExe"] = signedExe;
    if (!testCertificateFile.empty()) j["testCertificateFile"] = testCertificateFile;
    Json st = Json::array();
    for (const SignStep& s : steps) {
        Json e = Json::object({{"title", s.title}, {"command", s.command}, {"commandLine", display_command(s.command)}, {"ran", s.ran}});
        if (!s.env.empty()) e["env"] = s.env;
        if (s.stdinSecret) e["stdinSecret"] = true;
        if (s.ran) e["exitCode"] = s.exitCode;
        st.push_back(e);
    }
    j["steps"] = st;
    j["warnings"] = warnings;
    j["nextSteps"] = nextSteps;
    return j;
}

Result<SignWindowsReport> sign_windows(const SignWindowsOptions& options) {
    const std::string who = "sign.windows: ";
    const ExportEnvLookup env = options.env ? options.env : system_export_env();
    const std::string host = options.host.empty() ? export_detail::host_platform() : options.host;
    const bool onWindows = host == "windows";
    SignWindowsReport rep;
    rep.dryRun = options.dryRun;
    rep.timestampUrl = options.timestampUrl.empty() ? kDefaultTimestamp : options.timestampUrl;
    rep.tool = onWindows ? "signtool" : "osslsigncode";

    if (options.testCertificate && !onWindows)
        return err(who + "`testCertificate` needs Windows (it makes the certificate with PowerShell and keeps it in the Windows certificate store); this computer is " + host,
                   "Make a code-signing .pfx yourself (docs/EXPORTING.md, \"Trying the package on your PC\") and pass it as `pfx` with the password in " + std::string(kPasswordVar) +
                       ", or run sign.windows on the PC that will install the package.");

    // ---- what to sign
    std::error_code ec;
    stdfs::path dir, outParent;
    std::string slug;
    if (!options.projectDir.empty()) {
        dir = stdfs::weakly_canonical(options.projectDir, ec);
        auto text = tooling_detail::read_file(dir / "factoria.json");
        if (text) {
            auto parsed = parse_json(*text, generic(dir / "factoria.json"));
            if (parsed.ok() && parsed->is_object()) {
                const std::string name = parsed->value("name", std::string());
                if (!name.empty()) slug = tooling_detail::slugify(name, '-');
                if (slug.empty() && !name.empty()) slug = "game";
            }
        }
        outParent = options.outDir.empty() ? dir / "build" / "export" : stdfs::path(options.outDir);
    } else if (!options.outDir.empty()) {
        outParent = options.outDir;
    }
    stdfs::path msix;
    if (!options.msix.empty()) {
        msix = stdfs::absolute(stdfs::path(options.msix), ec).lexically_normal();
    } else if (!slug.empty()) {
        msix = outParent / (slug + "-windows.msix");
    }
    const bool msixAsked = !options.msix.empty();
    bool signMsix = !msix.empty() && (msixAsked || is_file(msix) || !options.exe);
    if (signMsix && !is_file(msix)) {
        return err(who + "there is no package at " + generic(msix),
                   "Export it first: project.export {\"platform\":\"windows\",\"format\":\"msix\"} writes build/export/<game-slug>-windows.msix. Or pass `msix` (or `out`) to say where it is.");
    }
    if (signMsix && !ends_with(to_lower(msix.filename().string()), ".msix") && !ends_with(to_lower(msix.filename().string()), ".appx"))
        return err(who + "'" + generic(msix) + "' is not an MSIX package (its name does not end in .msix)", "Pass the .msix that project.export wrote.");
    stdfs::path exe;
    if (options.exe) {
        if (slug.empty()) return err(who + "`exe` needs the game folder (factoria.json) to find the exe", "Run it on a game folder, or sign the exe with signtool yourself.");
        exe = outParent / (slug + "-windows") / export_detail::desktop_exe_name(slug, "windows");
        if (!is_file(exe))
            return err(who + "there is no exe at " + generic(exe), "Export the game for Windows first: project.export {\"platform\":\"windows\"}. Or leave `exe` out to sign only the package.");
    }
    if (!signMsix && exe.empty())
        return err(who + "nothing to sign: there is no package to find", "Pass `msix` (the .msix to sign) or run it on a game folder after `project.export {\"platform\":\"windows\",\"format\":\"msix\"}`.");
    if (signMsix) rep.msix = generic(msix);
    if (!exe.empty()) rep.exe = generic(exe);
    if (signMsix) {
        auto pub = manifest_publisher(msix);
        if (!pub.ok()) return pub.error();
        rep.publisher = *pub;
    }

    // ---- the certificate
    const std::string configPath = options.toolConfigPath.empty() ? machine_export_config_path(env) : options.toolConfigPath;
    std::string pfx, password;
    if (options.testCertificate) {
        if (!signMsix) return err(who + "`testCertificate` makes a certificate for the package's Publisher, and there is no package", "Pass `msix`, or export the package first.");
        rep.certificate = "test certificate (self-signed, subject " + rep.publisher + ")";
        rep.certificateFrom = "testCertificate";
    } else {
        if (!options.pfx.empty()) {
            pfx = options.pfx;
            rep.certificateFrom = "argument";
        } else if (const std::string v = env("FACTORIA_WINDOWS_PFX"); !v.empty()) {
            pfx = v;
            rep.certificateFrom = "FACTORIA_WINDOWS_PFX";
        } else {
            auto machine = read_machine_pfx(configPath);
            if (!machine.ok()) return machine.error();
            if (!machine->empty()) {
                pfx = *machine;
                rep.certificateFrom = "export.json";
            }
        }
        if (pfx.empty())
            return err(who + "no certificate: say which .pfx signs the package",
                       "Pass `pfx` (a code-signing certificate file), set FACTORIA_WINDOWS_PFX, or write {\"sign\": {\"windows\": {\"pfx\": \"C:/keys/code-signing.pfx\"}}} in " + configPath +
                           "; the password goes in " + kPasswordVar + " only. To just try the package on your own PC, pass \"testCertificate\": true (Windows). "
                           "A package for the Microsoft Store needs no signing at all: upload the .msix as it is, the Store signs it.");
        pfx = generic(stdfs::absolute(stdfs::path(pfx), ec));
        if (!is_file(pfx)) return err(who + "the certificate file " + pfx + " does not exist", "Check the path of the .pfx (" + rep.certificateFrom + ").");
        rep.certificate = "pfx " + pfx;
        password = env(kPasswordVar);
        if (password.empty())
            rep.warnings.push_back(std::string(kPasswordVar) + " is not set: the .pfx is used without a password. If it has one, signing fails: set the variable (the password is never read from anywhere else).");
    }
    const std::vector<std::string> secrets = {password};

    // ---- the tool
    if (!onWindows && !options.dryRun && host != "macos" && host != "linux")
        return err(who + "cannot sign on " + host, "Run it on Windows, macOS or Linux.");
    auto tool = find_signing_tool(onWindows, env, configPath);
    std::string toolPath = rep.tool;
    if (tool.ok()) {
        toolPath = tool->path;
    } else if (options.dryRun) {
        rep.warnings.push_back(tool.error().message);
    } else {
        return tool.error();
    }
    rep.toolPath = toolPath;
    Runner runner(options, rep, secrets);

    if (!onWindows && !options.dryRun) {
        Step v;
        v.argv = {toolPath, "--version"};
        auto r = runner.go("Check the osslsigncode version", v, false);
        if (!r.ok()) return r.error();
        const auto [major, minor] = osslsigncode_version(r->stdoutText + " " + r->stderrText);
        if (major == 0) rep.warnings.push_back("could not read the version of " + toolPath + "; MSIX signing needs osslsigncode 2.9 or newer.");
        else if (major < 2 || (major == 2 && minor < 9))
            return err(who + toolPath + " is osslsigncode " + std::to_string(major) + "." + std::to_string(minor) + ", which cannot sign MSIX packages correctly (APPX signing arrived in 2.7 and its zip order was fixed in 2.9)",
                       "Install a newer one: brew install osslsigncode, or build it from https://github.com/mtrojnar/osslsigncode. FACTORIA_OSSLSIGNCODE points at the one to use.");
    }

    // ---- the certificate must be the one the manifest names (Windows refuses to install a package signed by someone else)
    if (signMsix && !pfx.empty()) {
        std::string openssl;
        if (auto found = find_machine_tool({"sign.windows", "openssl", "FACTORIA_OPENSSL", "openssl", {"openssl"}, "https://www.openssl.org/"}, env, configPath); found.ok())
            openssl = found->path;
        if (openssl.empty()) {
            rep.warnings.push_back("openssl was not found, so the subject of the certificate was not compared with the Publisher of the package (" + rep.publisher +
                                   "). Windows installs the package only when they are equal.");
        } else if (!options.dryRun) {
            Step s1;
            s1.argv = {openssl, "pkcs12", "-in", pfx, "-nokeys", "-clcerts", "-passin", std::string("env:") + kPasswordVar};
            s1.env[kPasswordVar] = password;
            auto r1 = runner.go("Read the certificate subject", s1, false);
            std::string subject;
            if (r1.ok() && r1->exitCode == 0) {
                Step s2;
                s2.argv = {openssl, "x509", "-noout", "-subject", "-nameopt", "RFC2253"};
                s2.stdinText = r1->stdoutText;
                if (auto r2 = runner.go("Read the certificate subject", s2, false); r2.ok() && r2->exitCode == 0) {
                    subject = std::string(trim(r2->stdoutText));
                    if (starts_with(subject, "subject=")) subject = std::string(trim(std::string_view(subject).substr(8)));
                }
            }
            if (subject.empty()) {
                rep.warnings.push_back("could not read the subject of " + pfx + " with openssl (wrong password, or an old .pfx format); it was not compared with the Publisher of the package.");
            } else if (distinguished_name_parts(subject) != distinguished_name_parts(rep.publisher)) {
                return err(who + "the certificate's subject (" + subject + ") is not the Publisher of the package (" + rep.publisher + "): Windows would refuse to install it",
                           "Sign with the certificate whose subject is the Publisher, or change export.windows.msix.publisher in factoria.json to the certificate's subject and export the package again.");
            }
        }
    }

    // ---- sign
    const std::string stamp = rep.timestampUrl;
    std::string thumbprint;
    stdfs::path cer;

    // signtool takes a .pfx password only as an argument (/p), which every user of the computer can read in the process list. So on
    // Windows the .pfx is imported into the user's certificate store for this run (the password travels in the environment of the
    // PowerShell that imports it), signtool signs with /sha1 <thumbprint>, and the certificate is removed again afterwards, also when
    // signing fails or is cancelled. A certificate that was in the store before the run stays.
    const bool importPfx = onWindows && !options.testCertificate && !pfx.empty();
    SignWindowsOptions cleanupOptions = options;
    cleanupOptions.cancel = nullptr;  // the removal runs after a cancel too
    Runner cleaner(cleanupOptions, rep, secrets);
    bool removalPending = false;
    const auto remove_imported = [&]() {
        if (!removalPending) return;
        removalPending = false;
        const std::string title = "Remove the imported certificate from the user certificate store";
        const std::string script = remove_certificate_script(thumbprint);
        Step s;
        s.argv = {"powershell.exe", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-EncodedCommand", utf16le_base64(script)};
        s.shown = {"powershell.exe", "-NoProfile", "-Command", script};
        auto r = cleaner.go(title, s);
        if (!r.ok() || r->exitCode != 0) {
            const std::string msg = "The certificate " + thumbprint + " imported for signing could not be removed from the user certificate store: remove it by hand (certmgr.msc > Personal > Certificates).";
            rep.warnings.push_back(msg);
            if (options.progress) options.progress(msg);
        }
    };
    struct CleanupGuard {  // the error returns below run the removal too
        std::function<void()> run;
        ~CleanupGuard() {
            if (run) run();
        }
    } cleanupGuard{remove_imported};

    if (importPfx) {
        const std::string title = "Import the certificate into the user certificate store (for this run only)";
        const std::string script = import_pfx_script(pfx, !password.empty());
        Step s;
        s.argv = {"powershell.exe", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-EncodedCommand", utf16le_base64(script)};
        s.shown = {"powershell.exe", "-NoProfile", "-Command", script};
        if (!password.empty()) s.env[kPasswordVar] = password;
        auto r = runner.go(title, s);
        if (!r.ok()) return r.error();
        if (r->exitCode != 0)
            return runner.failed(title, s.shown, *r, "Check that " + std::string(kPasswordVar) + " is the password of " + pfx + " and that the file is a .pfx (PKCS#12) with a private key.");
        bool imported = false;
        if (options.dryRun) {
            thumbprint = "<thumbprint>";
            imported = true;
        } else {
            for (const std::string& line : split(r->stdoutText, '\n')) {
                const std::string t(trim(line));
                if (starts_with(t, "THUMBPRINT=")) thumbprint = std::string(trim(t.substr(11)));
                else if (t == "IMPORTED=1") imported = true;
            }
            if (!is_thumbprint(thumbprint)) {
                thumbprint.clear();
                return err(who + "the import step did not print the thumbprint of the certificate", "Run the command of the step by hand to see why.");
            }
        }
        removalPending = imported;
    }
    if (options.testCertificate) {
        cer = msix.parent_path() / (msix.stem().string() + "-test-certificate.cer");
        const std::string script = test_certificate_script(rep.publisher, generic(cer));
        Step s;
        s.argv = {"powershell.exe", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-EncodedCommand", utf16le_base64(script)};
        s.shown = {"powershell.exe", "-NoProfile", "-Command", script};
        const std::string title = "Create the test certificate";
        auto r = runner.go(title, s);
        if (!r.ok()) return r.error();
        if (r->exitCode != 0) return runner.failed(title, s.shown, *r, "Run PowerShell as the same user and check that New-SelfSignedCertificate works (the PKI module comes with Windows 10 and 11).");
        if (options.dryRun) {
            thumbprint = "<thumbprint>";
        } else {
            for (const std::string& line : split(r->stdoutText, '\n'))
                if (starts_with(trim(line), "THUMBPRINT=")) thumbprint = std::string(trim(trim(line).substr(11)));
            if (thumbprint.empty()) return err(who + "the test certificate step did not print a thumbprint", "Run the command of the step by hand to see why.");
        }
        rep.testCertificateFile = generic(cer);
    }

    const auto sign_one = [&](const stdfs::path& file, const std::string& label) -> Result<void> {
        const std::string title = "Sign the " + label;
        Step s;
        if (onWindows) {
            // The certificate is in the user's store (imported above, or made by testCertificate): no password on the command line.
            s.argv = {toolPath, "sign", "/fd", "SHA256", "/sha1", thumbprint, "/s", "My", "/tr", stamp, "/td", "SHA256", generic(file)};
            s.shown = s.argv;
        } else {
            const stdfs::path tmp = file.parent_path() / (file.filename().string() + ".signed");
            s.argv = {toolPath, "sign", "-pkcs12", pfx};
            // osslsigncode 2.9 and newer read the password from standard input with `-readpass -` (its NEWS for 2.9: "a special - file
            // name to read the passphrase from stdin"): it is neither in the argument list nor in a file of ours.
            if (!password.empty()) {
                s.argv.insert(s.argv.end(), {"-readpass", "-"});
                s.stdinText = password + "\n";
                s.stdinSecret = true;
            }
            s.argv.insert(s.argv.end(), {"-h", "sha256", "-ts", stamp, "-in", generic(file), "-out", generic(tmp)});
            s.shown = s.argv;
        }
        auto r = runner.go(title, s);
        if (!r.ok()) return r.error();
        if (!onWindows && !options.dryRun) {
            const stdfs::path tmp = file.parent_path() / (file.filename().string() + ".signed");
            if (r->exitCode == 0) {
                std::error_code mv;
                stdfs::rename(os_path(tmp), os_path(file), mv);
                if (mv) return err(who + "cannot replace " + generic(file) + " with the signed copy: " + mv.message(), "Check that the folder is writable; the signed copy is " + generic(tmp) + ".");
            } else {
                std::error_code rm;
                stdfs::remove(os_path(tmp), rm);
            }
        }
        if (r->exitCode != 0)
            return runner.failed(title, s.shown, *r,
                                 "Check that the certificate is a code-signing one (Extended Key Usage 'Code Signing'), that " + std::string(kPasswordVar) +
                                     " is its password, and that the time-stamp server " + stamp + " is reachable (timestampUrl).");
        return {};
    };

    if (signMsix) {
        if (auto r = sign_one(msix, "package"); !r.ok()) return r.error();
        rep.signedMsix = true;
    }
    if (!exe.empty()) {
        if (auto r = sign_one(exe, "exe"); !r.ok()) return r.error();
        rep.signedExe = true;
        if (signMsix) rep.warnings.push_back("The exe inside the package is the one that was exported: signing the exe here does not change the package. Sign the exe, then pack it into an MSIX with another tool, if you need both.");
    }

    remove_imported();  // the certificate imported for this run leaves the store (the guard does it on every error return)

    // ---- what to do next
    if (options.testCertificate) {
        rep.nextSteps.push_back("To try the package on this PC, trust the test certificate once. In PowerShell run as Administrator: Import-Certificate -FilePath '" + generic(cer) +
                                "' -CertStoreLocation Cert:\\LocalMachine\\TrustedPeople");
        rep.nextSteps.push_back("Then install it (no administrator needed): Add-AppxPackage -Path '" + rep.msix + "'. Remove it later with Get-AppxPackage *" + "<your package name>" +
                                "* | Remove-AppxPackage, and delete the certificate in certmgr.msc.");
        rep.nextSteps.push_back("A test certificate is for your own PC only. Do not upload this package to the Microsoft Store; upload the unsigned package (export it again).");
    } else if (signMsix) {
        rep.nextSteps.push_back("Install the signed package on a PC that trusts the certificate: Add-AppxPackage -Path '" + rep.msix + "'. A certificate from a public CA already is trusted; a self-signed one needs "
                                "Import-Certificate ... -CertStoreLocation Cert:\\LocalMachine\\TrustedPeople first (as Administrator).");
        rep.nextSteps.push_back("For the Microsoft Store do not sign: upload the unsigned package (project.export again); Microsoft signs it. publish.microsoft uploads it.");
    }
    if (options.dryRun) rep.nextSteps.push_back("This was a dry run: nothing was signed. Run it again without dryRun.");
    return rep;
}

// ---- the command --------------------------------------------------------------------------------------------------------

void register_sign_windows_command(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "sign.windows";
    info.category = "sign";
    info.readOnly = false;
    info.summary = "Sign the Windows MSIX package (and the exe) with a code-signing certificate, to install it outside the Microsoft Store.";
    info.description =
        "Signs <out>/<game-slug>-windows.msix (what `project.export "
        "{\"platform\":\"windows\",\"format\":\"msix\"}` writes) in place, and with `exe` the game's .exe of "
        "the export folder. A package for the Microsoft Store is uploaded UNSIGNED (Microsoft signs it), so "
        "this is for installing the package on a PC outside the Store (yours, a tester's) or for a game sold "
        "elsewhere. The certificate is a code-signing .pfx: `pfx`, else FACTORIA_WINDOWS_PFX, else "
        "sign.windows.pfx of ~/.factoria/export.json; its password ONLY in FACTORIA_WINDOWS_PFX_PASSWORD "
        "(never an argument of any program, a file of the game, a result or a log: on Windows the .pfx is "
        "imported into the user's certificate store for the run and removed afterwards, signtool signs by "
        "thumbprint; osslsigncode reads the password on stdin). The subject of the certificate must "
        "equal the Publisher of the package (checked with openssl when it is installed). Examples: "
        "{\"dryRun\":true}, {\"pfx\":\"C:/keys/code-signing.pfx\"}, {\"testCertificate\":true}."
        FA_COMMAND_DETAILS
        "`testCertificate: true` (Windows) instead creates a self-signed certificate for the package's "
        "Publisher in your user certificate store, signs with it and saves the public part as "
        "<slug>-windows-test-certificate.cer: trust it once (Import-Certificate ... -CertStoreLocation "
        "Cert:\\LocalMachine\\TrustedPeople as Administrator) and `Add-AppxPackage -Path <the .msix>` "
        "installs the game (docs/EXPORTING.md, \"Trying the package on your PC\"). The tool: signtool.exe on "
        "Windows (FACTORIA_SIGNTOOL, else the newest Windows SDK, else PATH); osslsigncode on macOS and "
        "Linux (FACTORIA_OSSLSIGNCODE, else PATH; 2.9 or newer). Digest SHA-256 and an RFC 3161 time stamp "
        "(`timestampUrl`, default http://timestamp.digicert.com). `dryRun: true` checks everything and "
        "returns the exact command lines in steps[] on any computer. Returns {msix, exe, publisher, "
        "certificate, certificateFrom, tool, toolPath, timestampUrl, dryRun, signedMsix, signedExe, "
        "testCertificateFile, steps[{title, command, commandLine, ran, exitCode}], warnings[], nextSteps[]}. "
        "Signing again after every export is needed: the next project.export replaces the package.";
    info.inputSchema = Json::parse(R"({
      "type":"object",
      "properties":{
        "msix":{"type":"string","description":"The .msix to sign, relative to the project. Default: build/export/<game-slug>-windows.msix."},
        "out":{"type":"string","description":"Parent folder of the export, relative to the project (the `out` of project.export). Default: build/export."},
        "exe":{"type":"boolean","default":false,"description":"Also sign the game's .exe in build/export/<game-slug>-windows/ (for a game shared as a folder or a zip). The package is not changed by it."},
        "pfx":{"type":"string","description":"The code-signing certificate (.pfx), absolute or relative to the project. Default: FACTORIA_WINDOWS_PFX, else sign.windows.pfx of ~/.factoria/export.json. The password is read from FACTORIA_WINDOWS_PFX_PASSWORD only."},
        "testCertificate":{"type":"boolean","default":false,"description":"Windows only: create (or reuse) a self-signed certificate whose subject is the package's Publisher, sign with it and save its public part next to the package, to install the package on this PC."},
        "timestampUrl":{"type":"string","description":"RFC 3161 time-stamp server. Default: http://timestamp.digicert.com."},
        "dryRun":{"type":"boolean","default":false,"description":"Check everything and return the exact command lines in steps[]; sign nothing. Works on any computer."}
      }})");
    registry.add(info, [projectDir](const Json& args) {
        SignWindowsOptions o;
        o.projectDir = projectDir;
        auto inside = [&](const std::string& rel, const char* what) {
            auto dir = resolve_project_path(projectDir, rel);
            if (!dir) throw CommandError("invalid_argument", std::string(what) + ": " + dir.error().message, dir.error().hint);
            return dir->string();
        };
        if (std::string v = tooling_detail::arg_string(args, "msix", false); !v.empty()) o.msix = inside(v, "msix");
        if (std::string v = tooling_detail::arg_string(args, "out", false); !v.empty()) o.outDir = inside(v, "out");
        if (std::string v = tooling_detail::arg_string(args, "pfx", false); !v.empty()) o.pfx = stdfs::path(v).is_absolute() ? v : inside(v, "pfx");
        o.exe = tooling_detail::arg_bool(args, "exe", false);
        o.testCertificate = tooling_detail::arg_bool(args, "testCertificate", false);
        o.timestampUrl = tooling_detail::arg_string(args, "timestampUrl", false);
        o.dryRun = tooling_detail::arg_bool(args, "dryRun", false);
        o.progress = [](const std::string& line) { log(LogLevel::Info, "sign.windows", line); };
        auto r = sign_windows(o);
        if (!r.ok()) throw CommandError("failed", r.error().message, r.error().hint);
        return r->to_json();
    });
}

}  // namespace fa
