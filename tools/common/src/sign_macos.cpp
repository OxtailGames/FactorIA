// sign.macos: Developer ID signing, notarization and stapling of the exported .app, or (distribution "appStore") sandboxing,
// App Store signing and the signed .pkg for the Mac App Store. Behaviour: fa/tooling/sign.h and docs/EXPORTING.md ("Signing and
// notarizing for macOS", "Mac App Store"). The shell version FactorIA's own release uses is scripts/sign-macos.sh.
#include "fa/tooling/sign.h"

#include <algorithm>
#include <cstdint>
#include <deque>
#include <filesystem>
#include <fstream>
#include <regex>

#include "export_internal.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/tooling/plugin_manifest.h"
#include "fa/tooling/project_fs.h"
#include "plist_read.h"
#include "util.h"

namespace fa {

namespace {

namespace stdfs = std::filesystem;
using export_detail::generic;
using export_detail::os_path;

constexpr const char* kRedacted = "<redacted>";
constexpr const char* kCodesign = "/usr/bin/codesign";
constexpr const char* kDitto = "/usr/bin/ditto";
constexpr const char* kXcrun = "/usr/bin/xcrun";
constexpr const char* kSpctl = "/usr/sbin/spctl";
constexpr const char* kSecurity = "/usr/bin/security";
constexpr const char* kProductbuild = "/usr/bin/productbuild";
constexpr const char* kPkgutil = "/usr/sbin/pkgutil";
constexpr const char* kLipo = "/usr/bin/lipo";
constexpr const char* kSandboxKey = "com.apple.security.app-sandbox";

Error err(std::string message, std::string hint = {}) { return Error{std::move(message), std::move(hint)}; }

bool is_dir(const stdfs::path& p) {
    std::error_code ec;
    return stdfs::is_directory(os_path(p), ec);
}
bool is_file(const stdfs::path& p) {
    std::error_code ec;
    return stdfs::is_regular_file(os_path(p), ec);
}

// A command line as a person would type it into a shell: an argument with anything but plain characters is quoted.
std::string display_command(const std::vector<std::string>& argv) {
    std::string out;
    for (const std::string& a : argv) {
        const bool plain = !a.empty() && a.find_first_not_of("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-./:=@+,") == std::string::npos;
        out += (out.empty() ? "" : " ") + (plain ? a : export_detail::sh_quote(a));
    }
    return out;
}

std::string scrub(std::string line, const std::vector<std::string>& secrets) {
    for (const std::string& s : secrets)
        if (!s.empty()) line = replace_all(std::move(line), s, kRedacted);
    return line;
}

std::string first_set(std::initializer_list<std::string> values) {
    for (const std::string& v : values)
        if (!v.empty()) return v;
    return {};
}

std::string last_lines(const std::string& text, std::size_t n) {
    std::deque<std::string> tail;
    for (const std::string& line : split(text, '\n')) {
        std::string t(trim(line));
        if (t.empty()) continue;
        tail.push_back(std::move(t));
        if (tail.size() > n) tail.pop_front();
    }
    std::string out;
    for (const std::string& l : tail) out += (out.empty() ? "" : " | ") + l;
    return out;
}

// ---- ~/.factoria/export.json: "sign": {"macos": {"identity", "keychain", "notaryProfile"}} ---------------------------------

struct MachineSign {
    std::string identity, keychain, notaryProfile, appStoreIdentity, installerIdentity;
};

Result<MachineSign> read_machine_sign(const std::string& configPath) {
    MachineSign m;
    std::error_code ec;
    if (!stdfs::exists(stdfs::path(configPath), ec)) return m;
    auto text = tooling_detail::read_file(stdfs::path(configPath));
    if (!text) return err("sign.macos: cannot read " + configPath, "Check that the file is readable, or delete it.");
    auto parsed = parse_json(*text, configPath);
    if (!parsed.ok()) return err("sign.macos: " + parsed.error().message, "Fix the JSON of " + configPath + " (or delete it).");
    if (!parsed->is_object()) return m;
    auto sign = parsed->find("sign");
    if (sign == parsed->end() || !sign->is_object()) return m;
    auto macos = sign->find("macos");
    if (macos == sign->end() || !macos->is_object()) return m;
    const std::pair<const char*, std::string*> fields[] = {{"identity", &m.identity}, {"keychain", &m.keychain}, {"notaryProfile", &m.notaryProfile},
                                                               {"appStoreIdentity", &m.appStoreIdentity}, {"installerIdentity", &m.installerIdentity}};
    for (const auto& [key, out] : fields) {
        auto f = macos->find(key);
        if (f == macos->end() || f->is_null()) continue;
        if (!f->is_string())
            return err("sign.macos: " + configPath + "#/sign/macos/" + key + ": expected a string, got " + describe_json_value(*f),
                       "Write {\"sign\": {\"macos\": {\"identity\": \"Developer ID Application: Your Name (TEAMID)\", \"notaryProfile\": \"my-profile\"}}}.");
        *out = f->get<std::string>();
    }
    return m;
}

// ---- notarytool credentials -----------------------------------------------------------------------------------------

struct Credentials {
    std::vector<std::string> argv;   // the login arguments after `notarytool submit|log <what>`
    std::vector<std::string> shown;  // the same with the secret replaced
    std::string description;         // "keychain profile 'x'": what the report says
    std::string secret;              // the app-specific password, scrubbed from every output
    std::string problem;             // credentials given halfway: what is missing
    bool found() const { return !argv.empty(); }
};

Credentials resolve_credentials(const SignMacosOptions& o, const ExportEnvLookup& env, const MachineSign& machine, const std::string& keychain) {
    Credentials c;
    const std::string profile = first_set({o.keychainProfile, env("FACTORIA_NOTARY_PROFILE"), machine.notaryProfile});
    if (!profile.empty()) {
        c.argv = {"--keychain-profile", profile};
        if (!keychain.empty()) c.argv.insert(c.argv.end(), {"--keychain", keychain});
        c.shown = c.argv;
        c.description = "keychain profile '" + profile + "'";
        return c;
    }
    const std::string key = first_set({o.apiKey, env("FACTORIA_NOTARY_API_KEY")});
    if (!key.empty()) {
        const std::string keyId = first_set({o.apiKeyId, env("FACTORIA_NOTARY_API_KEY_ID")});
        const std::string issuer = first_set({o.apiIssuer, env("FACTORIA_NOTARY_API_ISSUER")});
        if (keyId.empty()) {
            c.problem = "the App Store Connect API key " + key + " has no key id (apiKeyId, or FACTORIA_NOTARY_API_KEY_ID)";
        } else if (!is_file(key)) {
            c.problem = "the App Store Connect API key file " + key + " does not exist";
        } else {
            c.argv = {"--key", key, "--key-id", keyId};
            if (!issuer.empty()) c.argv.insert(c.argv.end(), {"--issuer", issuer});
            c.shown = c.argv;
            c.description = "App Store Connect API key " + keyId;
        }
        return c;
    }
    const std::string appleId = first_set({o.appleId, env("FACTORIA_APPLE_ID"), env("APPLE_ID")});
    const std::string teamId = first_set({o.teamId, env("FACTORIA_APPLE_TEAM_ID"), env("APPLE_TEAM_ID")});
    const std::string password = first_set({env("FACTORIA_APPLE_APP_PASSWORD"), env("APPLE_APP_PASSWORD")});
    if (appleId.empty() && teamId.empty() && password.empty()) return c;
    std::string missing;
    if (appleId.empty()) missing += "the Apple ID (appleId, or FACTORIA_APPLE_ID)";
    if (teamId.empty()) missing += std::string(missing.empty() ? "" : ", ") + "the Team ID (teamId, or FACTORIA_APPLE_TEAM_ID)";
    if (password.empty()) missing += std::string(missing.empty() ? "" : ", ") + "the app-specific password (FACTORIA_APPLE_APP_PASSWORD)";
    if (!missing.empty()) {
        c.problem = "the Apple ID credentials are incomplete: " + missing + " is missing";
        return c;
    }
    c.argv = {"--apple-id", appleId, "--team-id", teamId, "--password", password};
    c.shown = {"--apple-id", appleId, "--team-id", teamId, "--password", kRedacted};
    c.secret = password;
    c.description = "Apple ID " + appleId + " (team " + teamId + ")";
    return c;
}

// ---- the app ------------------------------------------------------------------------------------------------------

bool is_macho(const stdfs::path& p) {
    std::ifstream f(os_path(p), std::ios::binary);
    unsigned char b[8] = {};
    if (!f.read(reinterpret_cast<char*>(b), 8)) return false;
    const std::uint32_t magic = (std::uint32_t(b[0]) << 24) | (std::uint32_t(b[1]) << 16) | (std::uint32_t(b[2]) << 8) | b[3];
    if (magic == 0xcafebabeu)  // a fat binary (a few architectures) or a Java class file (a version number, 45 and up)
        return ((std::uint32_t(b[4]) << 24) | (std::uint32_t(b[5]) << 16) | (std::uint32_t(b[6]) << 8) | b[7]) < 20;
    return magic == 0xfeedfaceu || magic == 0xfeedfacfu || magic == 0xcefaedfeu || magic == 0xcffaedfeu;
}

// The code inside the app that has to be signed before the app is: libraries, frameworks and helpers under Contents/Frameworks
// (the native plugins land there). Deepest first, so that a framework is sealed after the files inside it.
std::vector<stdfs::path> nested_code(const stdfs::path& app) {
    std::vector<stdfs::path> out;
    const stdfs::path frameworks = app / "Contents" / "Frameworks";
    std::error_code ec;
    for (stdfs::recursive_directory_iterator it(os_path(frameworks), ec), end; !ec && it != end; it.increment(ec)) {
        if (it->is_symlink(ec)) continue;  // Versions/Current and friends point at code that is signed where it is
        const stdfs::path rel = it->path().lexically_relative(os_path(frameworks));
        const std::string ext = to_lower(it->path().extension().string());
        bool code = false;
        if (it->is_directory(ec)) code = ext == ".framework" || ext == ".bundle" || ext == ".app" || ext == ".xpc";
        else if (it->is_regular_file(ec)) code = ext == ".dylib" || ext == ".so" || ext == ".jnilib" || is_macho(it->path());
        if (code) out.push_back(frameworks / rel);
    }
    std::stable_sort(out.begin(), out.end(), [](const stdfs::path& a, const stdfs::path& b) {
        const auto depth = [](const stdfs::path& p) { return std::distance(p.begin(), p.end()); };
        const auto da = depth(a), db = depth(b);
        return da != db ? da > db : a < b;
    });
    return out;
}

// Where the distributable zip goes: next to the export folder (<slug>-macos.zip), so that uploading the folder to a store does not
// upload the zip too; for an app kept anywhere else, next to the app.
stdfs::path default_zip(const stdfs::path& app) {
    const stdfs::path folder = app.parent_path();
    const std::string name = folder.filename().string();
    if (ends_with(name, "-macos")) return folder.parent_path() / (name + ".zip");
    return folder / (app.stem().string() + ".zip");
}

struct NotaryAnswer {
    std::string id, status, message;
};

// notarytool prints one JSON object with --output-format json; anything else around it is progress text.
NotaryAnswer parse_notary(const std::string& output) {
    NotaryAnswer a;
    const std::size_t begin = output.find('{'), end = output.rfind('}');
    if (begin != std::string::npos && end != std::string::npos && end > begin)
        if (auto j = parse_json(output.substr(begin, end - begin + 1), "notarytool"); j.ok() && j->is_object()) {
            a.id = j->value("id", std::string());
            a.status = j->value("status", std::string());
            a.message = j->value("message", std::string());
        }
    return a;  // nothing parsed: the answer stays empty and the error quotes what notarytool printed
}

// ---- running ------------------------------------------------------------------------------------------------------

class Runner {
public:
    Runner(const SignMacosOptions& o, SignReport& report, std::vector<std::string> secrets)
        : o_(o), report_(report), secrets_(std::move(secrets)) {}

    // Records the step; unless this is a dry run, runs it. An Error: the program could not start or the run was cancelled. A program
    // that exits with an error is a successful Result: the caller decides what that means.
    Result<ProcessResult> go(const std::string& title, std::vector<std::string> argv, std::vector<std::string> shown = {}, double timeoutSeconds = 0) {
        SignStep step;
        step.title = title;
        step.command = shown.empty() ? argv : std::move(shown);
        if (o_.dryRun) {
            report_.steps.push_back(std::move(step));
            ProcessResult fake;
            fake.exitCode = 0;
            return fake;
        }
        auto line = [this](std::string_view l) {
            if (o_.progress) o_.progress(scrub(std::string(l), secrets_));
        };
        ProcessOptions po;
        po.argv = argv;
        po.cancel = o_.cancel;
        po.timeoutSeconds = timeoutSeconds;
        po.onStdoutLine = line;
        po.onStderrLine = line;
        auto run = o_.run ? o_.run(po) : run_process(po);
        if (!run.ok()) {
            report_.steps.push_back(std::move(step));
            return err("sign.macos: " + title + ": cannot start " + argv[0] + ": " + run.error().message,
                       run.error().hint.empty() ? "Install Xcode or the Command Line Tools (xcode-select --install): codesign, ditto and xcrun come with them." : run.error().hint);
        }
        step.ran = true;
        step.exitCode = run->exitCode;
        report_.steps.push_back(std::move(step));
        run->stdoutText = scrub(std::move(run->stdoutText), secrets_);
        run->stderrText = scrub(std::move(run->stderrText), secrets_);
        if (run->cancelled || is_cancelled(o_.cancel)) return err("sign.macos: cancelled during " + title, "Run it again; signing an app twice is safe.");
        if (run->timedOut) return err("sign.macos: " + title + " did not finish in time", "Run it again.");
        return run;
    }

    // The error for a program that exited with an error: the step, the code and the end of what it printed.
    Error failed(const std::string& title, const std::vector<std::string>& shown, const ProcessResult& r, const std::string& hint) const {
        const std::string said = last_lines(r.stderrText.empty() ? r.stdoutText : r.stderrText + "\n" + r.stdoutText, 6);
        return err("sign.macos: " + title + " failed (" + display_command(shown) + " exited with code " + std::to_string(r.exitCode) + ")" +
                       (said.empty() ? std::string(".") : ". It said: " + said),
                   hint);
    }

private:
    const SignMacosOptions& o_;
    SignReport& report_;
    std::vector<std::string> secrets_;
};

// ---- the Mac App Store ----------------------------------------------------------------------------------------------

// The path of the files that sit next to the export folder, without extension: <slug>-macos for build/export/<slug>-macos/<Name>.app.
stdfs::path sibling_base(const stdfs::path& app) {
    const stdfs::path folder = app.parent_path();
    const std::string name = folder.filename().string();
    if (ends_with(name, "-macos")) return folder.parent_path() / name;
    return folder / app.stem();
}

// MH_EXECUTE in the header of a thin or fat Mach-O file: a program (a helper) rather than a library.
bool macho_is_executable(const stdfs::path& p) {
    std::ifstream f(os_path(p), std::ios::binary);
    unsigned char b[32] = {};
    f.read(reinterpret_cast<char*>(b), sizeof b);
    if (f.gcount() < 16) return false;
    auto be32 = [](const unsigned char* x) { return (std::uint32_t(x[0]) << 24) | (std::uint32_t(x[1]) << 16) | (std::uint32_t(x[2]) << 8) | x[3]; };
    auto le32 = [](const unsigned char* x) { return (std::uint32_t(x[3]) << 24) | (std::uint32_t(x[2]) << 16) | (std::uint32_t(x[1]) << 8) | x[0]; };
    if (be32(b) == 0xcafebabeu) {  // fat: the first slice tells
        if (f.gcount() < 24) return false;
        f.clear();
        f.seekg(be32(b + 16));
        unsigned char t[16] = {};
        f.read(reinterpret_cast<char*>(t), sizeof t);
        if (f.gcount() < 16) return false;
        return le32(t + 12) == 2 && (le32(t) == 0xfeedfaceu || le32(t) == 0xfeedfacfu);
    }
    return (le32(b) == 0xfeedfaceu || le32(b) == 0xfeedfacfu) && le32(b + 12) == 2;
}

// Code in Contents/Frameworks that runs as a program of its own (a helper app, an XPC service, a command-line tool): in the sandbox
// it is signed with com.apple.security.inherit, so that it lives in the sandbox of the app.
bool is_helper_program(const stdfs::path& code) {
    const std::string ext = to_lower(code.extension().string());
    if (ext == ".app" || ext == ".xpc") return true;
    std::error_code ec;
    return stdfs::is_regular_file(os_path(code), ec) && macho_is_executable(code);
}

struct AppInfo {
    bool parsed = false;
    std::string bundleId, executable, shortVersion, version, category, icon, minOs;
};

AppInfo read_app_info(const stdfs::path& app) {
    AppInfo a;
    auto text = tooling_detail::read_file(app / "Contents" / "Info.plist");
    if (!text) return a;
    auto plist = tooling_detail::parse_xml_plist(*text);
    if (!plist.ok() || !plist->is_object()) return a;
    auto str = [&](const char* key) {
        auto it = plist->find(key);
        return it != plist->end() && it->is_string() ? it->get<std::string>() : std::string();
    };
    a.parsed = true;
    a.bundleId = str("CFBundleIdentifier");
    a.executable = str("CFBundleExecutable");
    a.shortVersion = str("CFBundleShortVersionString");
    a.version = str("CFBundleVersion");
    a.category = str("LSApplicationCategoryType");
    a.icon = str("CFBundleIconFile");
    a.minOs = str("LSMinimumSystemVersion");
    return a;
}

struct ProfileInfo {
    std::string name, appId, teamId, expires;
    bool checked = true;  // false: a dry run that could not read the profile (the identifiers are placeholders)
};

// What the Mac App Store needs of a provisioning profile, as teaching errors. `plist` is the profile's property list.
Result<ProfileInfo> check_profile(const Json& plist, const std::string& bundleId, const std::string& profileFile) {
    const std::string who = "sign.macos: ";
    const std::string get = "Create a profile of type 'Mac App Store Connect' for the App ID " + bundleId +
                            " (developer.apple.com > Certificates, Identifiers & Profiles > Profiles > +), download it and pass its path as `provisioningProfile`.";
    if (!plist.is_object()) return err(who + profileFile + " is not a provisioning profile", get);
    ProfileInfo info;
    info.name = plist.value("Name", std::string());
    info.expires = plist.value("ExpirationDate", std::string());
    if (auto p = plist.find("Platform"); p != plist.end() && p->is_array()) {
        bool mac = false;
        std::string platforms;
        for (const Json& x : *p)
            if (x.is_string()) {
                const std::string v = x.get<std::string>();
                mac = mac || v == "OSX" || v == "macOS";
                platforms += (platforms.empty() ? "" : ", ") + v;
            }
        if (!mac) return err(who + "the provisioning profile " + profileFile + " is for " + platforms + ", not for macOS", get);
    }
    if (plist.contains("ProvisionedDevices"))
        return err(who + "the provisioning profile " + profileFile + " is a development profile (it lists devices), which the Mac App Store rejects",
                   get + " Its type must be 'Mac App Store Connect', not 'Mac App Development'.");
    if (plist.value("ProvisionsAllDevices", false))
        return err(who + "the provisioning profile " + profileFile + " is a Developer ID profile (it provisions all devices), not a Mac App Store one",
                   get + " Developer ID profiles go with sign.macos's default distribution \"developerId\".");
    const Json empty = Json::object();
    const Json& ents = plist.contains("Entitlements") && plist["Entitlements"].is_object() ? plist["Entitlements"] : empty;
    if (ents.value("get-task-allow", false))
        return err(who + "the provisioning profile " + profileFile + " is a development profile (get-task-allow), which the Mac App Store rejects", get);
    info.appId = ents.value("com.apple.application-identifier", ents.value("application-identifier", std::string()));
    info.teamId = ents.value("com.apple.developer.team-identifier", std::string());
    if (info.teamId.empty())
        if (auto t = plist.find("TeamIdentifier"); t != plist.end() && t->is_array() && !t->empty() && (*t)[0].is_string()) info.teamId = (*t)[0].get<std::string>();
    if (info.appId.empty())
        return err(who + "the provisioning profile " + profileFile + " has no application identifier (Entitlements/com.apple.application-identifier)", get);
    const std::size_t dot = info.appId.find('.');
    if (info.teamId.empty() && dot != std::string::npos) info.teamId = info.appId.substr(0, dot);
    if (ends_with(info.appId, ".*"))
        return err(who + "the provisioning profile " + profileFile + " is for a wildcard App ID (" + info.appId + "), which the Mac App Store does not accept",
                   "Create an explicit App ID " + bundleId + " in the developer portal (Identifiers) and a Mac App Store Connect profile for it.");
    if (info.appId != info.teamId + "." + bundleId)
        return err(who + "the provisioning profile " + profileFile + " is for the App ID " + info.appId + ", but the game's id is " + bundleId +
                       " (expected " + info.teamId + "." + bundleId + ")",
                   "Create the profile for the App ID " + bundleId + " (the \"id\" of factoria.json), or change the \"id\" and export again.");
    if (info.expires.size() >= 10 && info.expires.substr(0, 10) < tooling_detail::today_utc())
        return err(who + "the provisioning profile " + profileFile + " expired on " + info.expires.substr(0, 10),
                   "Renew it in the developer portal (Profiles > the profile > Edit > Save) and download it again.");
    return info;
}

// The entitlements the plugins asked for (the export's <slug>.entitlements): without the two identifiers (they come from the profile)
// and with the placeholder TEAMID replaced by the real Team ID.
Result<Json> plugin_entitlements(const stdfs::path& file, const std::string& team) {
    auto text = tooling_detail::read_file(file);
    if (!text) return err("sign.macos: cannot read " + generic(file), "Export the game again.");
    auto plist = tooling_detail::parse_xml_plist(*text);
    if (!plist.ok() || !plist->is_object()) return err("sign.macos: " + generic(file) + ": " + (plist.ok() ? "not a dictionary" : plist.error().message), "Export the game again.");
    Json out = Json::object();
    std::function<Json(const Json&)> fix = [&](const Json& v) -> Json {
        if (v.is_string()) return replace_all(v.get<std::string>(), "TEAMID.", team + ".");
        if (v.is_array()) {
            Json a = Json::array();
            for (const Json& x : v) a.push_back(fix(x));
            return a;
        }
        return v;
    };
    for (auto it = plist->begin(); it != plist->end(); ++it) {
        if (it.key() == "com.apple.application-identifier" || it.key() == "com.apple.developer.team-identifier") continue;
        out[it.key()] = fix(it.value());
    }
    return out;
}

bool looks_like_hash(const std::string& id) {
    return id.size() == 40 && id.find_first_not_of("0123456789abcdefABCDEF") == std::string::npos;
}

std::string nonmac_error_hint() {
    return "Export the game and sign it on a Mac: copy the export folder there, or run `factoria call project.export` and `factoria call sign.macos` "
           "on the Mac (the exported app keeps its permissions only when copied as a folder or a tar, not through a zip made on Windows). "
           "Or let a macOS runner do it: `factoria call project.new_ci_workflow` writes a GitHub Actions workflow with a macOS job. "
           "`dryRun: true` shows the command lines on this computer.";
}

}  // namespace

Json SignReport::to_json() const {
    Json j = Json::object();
    j["app"] = app;
    j["dryRun"] = dryRun;
    j["identity"] = identity;
    j["identityFrom"] = identityFrom;
    j["credentials"] = credentials;
    j["signed"] = signedApp;
    j["verified"] = verified;
    j["notarized"] = notarized;
    j["stapled"] = stapled;
    if (!notarizationId.empty()) j["notarizationId"] = notarizationId;
    j["zip"] = zip;
    j["distribution"] = distribution;
    if (distribution == "appStore") {
        j["pkg"] = pkg;
        j["pkgSigned"] = pkgSigned;
        j["installerIdentity"] = installerIdentity;
        j["entitlements"] = entitlements;
        j["profile"] = profile;
    }
    Json st = Json::array();
    for (const SignStep& s : steps) {
        Json e = Json::object({{"title", s.title}, {"command", s.command}, {"commandLine", display_command(s.command)}, {"ran", s.ran}});
        if (s.ran) e["exitCode"] = s.exitCode;
        st.push_back(e);
    }
    j["steps"] = st;
    j["warnings"] = warnings;
    j["nextSteps"] = nextSteps;
    return j;
}

Result<SignReport> sign_macos(const SignMacosOptions& options) {
    const std::string who = "sign.macos: ";
    const ExportEnvLookup env = options.env ? options.env : system_export_env();
    const std::string host = options.host.empty() ? export_detail::host_platform() : options.host;
    SignReport rep;
    rep.dryRun = options.dryRun;
    if (!options.distribution.empty() && options.distribution != "developerId" && options.distribution != "appStore")
        return err(who + "unknown distribution '" + options.distribution + "'", did_you_mean(options.distribution, std::vector<std::string>{"developerId", "appStore"}) +
                   " \"developerId\" signs and notarizes for sharing outside the store (the default); \"appStore\" sandboxes and signs for the Mac App Store.");
    const bool store = options.distribution == "appStore";
    rep.distribution = store ? "appStore" : "developerId";

    if (host != "macos" && !options.dryRun)
        return err(who + "this computer is not a Mac (" + host + "): codesign, xcrun notarytool and xcrun stapler exist only on macOS",
                   nonmac_error_hint());

    // ---- the app
    std::error_code ec;
    stdfs::path app;
    if (!options.app.empty()) {
        app = stdfs::absolute(stdfs::path(options.app), ec).lexically_normal();
    } else {
        if (options.projectDir.empty()) return err(who + "no app and no project given", "pass `app` (the .app to sign) or run it on a game folder");
        const stdfs::path dir = stdfs::weakly_canonical(options.projectDir, ec);
        auto text = tooling_detail::read_file(dir / "factoria.json");
        if (!text) return err(who + generic(dir / "factoria.json") + " not found", "run it on a game folder (the one containing factoria.json), or pass `app`");
        auto parsed = parse_json(*text, generic(dir / "factoria.json"));
        if (!parsed.ok()) return parsed.error();
        const std::string name = parsed->is_object() ? parsed->value("name", std::string()) : std::string();
        if (name.empty()) return err(generic(dir / "factoria.json") + "#/name: missing or empty", "set \"name\": \"My Game\" in factoria.json");
        const std::string slug = tooling_detail::slugify(name, '-').empty() ? "game" : tooling_detail::slugify(name, '-');
        const stdfs::path outParent = options.outDir.empty() ? dir / "build" / "export" : stdfs::path(options.outDir);
        app = outParent / (slug + "-macos") / (export_detail::fs_safe_name(name) + ".app");
    }
    if (!ends_with(to_lower(app.filename().string()), ".app"))
        return err(who + "'" + generic(app) + "' is not an app bundle (its name does not end in .app)", "pass the .app folder `project.export` wrote for macOS");
    if (!is_dir(app) || !is_file(app / "Contents" / "Info.plist"))
        return err(who + "there is no macOS app at " + generic(app) + (is_dir(app) ? " (the folder has no Contents/Info.plist)" : ""),
                   "Export the game for macOS first: project.export {\"platform\":\"macos\"} writes build/export/<game-slug>-macos/<Name>.app. Or pass `app` (or `out`) to say where it is.");
    rep.app = generic(app);

    // ---- the machine's settings, the identity
    const std::string configPath = options.toolConfigPath.empty() ? machine_export_config_path(env) : options.toolConfigPath;
    auto machine = read_machine_sign(configPath);
    if (!machine.ok()) return machine.error();
    if (!options.identity.empty()) {
        rep.identity = options.identity;
        rep.identityFrom = "argument";
    } else if (store) {
        if (const std::string v = env("FACTORIA_MACOS_APPSTORE_IDENTITY"); !v.empty()) {
            rep.identity = v;
            rep.identityFrom = "FACTORIA_MACOS_APPSTORE_IDENTITY";
        } else if (!machine->appStoreIdentity.empty()) {
            rep.identity = machine->appStoreIdentity;
            rep.identityFrom = "export.json";
        }
    } else if (const std::string v = env("FACTORIA_MACOS_SIGN_IDENTITY"); !v.empty()) {
        rep.identity = v;
        rep.identityFrom = "FACTORIA_MACOS_SIGN_IDENTITY";
    } else if (!machine->identity.empty()) {
        rep.identity = machine->identity;
        rep.identityFrom = "export.json";
    }
    if (rep.identity.empty() && store)
        return err(who + "no signing identity: say which certificate signs the app for the Mac App Store",
                   "Pass `identity` (an \"Apple Distribution: Your Name (TEAMID)\" or \"3rd Party Mac Developer Application: ...\" certificate), set FACTORIA_MACOS_APPSTORE_IDENTITY, or write "
                   "{\"sign\": {\"macos\": {\"appStoreIdentity\": \"...\"}}} in " + configPath + ". `security find-identity -v -p codesigning` lists the names on this Mac. "
                   "\"-\" signs ad hoc: a local try of the sandbox (no profile, an unsigned pkg that App Store Connect refuses). Steps in the developer portal: docs/EXPORTING.md, \"Mac App Store\".");
    if (rep.identity.empty())
        return err(who + "no signing identity: say which certificate signs the app",
                   "Pass `identity` (e.g. \"Developer ID Application: Your Name (TEAMID)\"), set FACTORIA_MACOS_SIGN_IDENTITY, or write {\"sign\": {\"macos\": {\"identity\": \"...\"}}} in " + configPath +
                       ". On the Mac that has the certificate, `security find-identity -v -p codesigning` lists the names. \"-\" signs ad hoc (no certificate: the app runs on this Mac only and cannot be notarized).");
    const bool adHoc = rep.identity == "-";
    const std::string keychain = first_set({options.keychain, env("FACTORIA_MACOS_KEYCHAIN"), machine->keychain});
    // Only a Developer ID Application certificate can notarize an app that is shared outside the Mac App Store.
    const bool wrongKind = !adHoc && (starts_with(rep.identity, "Apple Development") || starts_with(rep.identity, "Mac Developer") ||
                                     starts_with(rep.identity, "Apple Distribution") || starts_with(rep.identity, "3rd Party Mac Developer") ||
                                     starts_with(rep.identity, "Developer ID Installer"));

    if (store && !adHoc) {
        const std::string& id = rep.identity;
        if (starts_with(id, "Developer ID") || starts_with(id, "Apple Development") || starts_with(id, "Mac Developer") ||
            starts_with(id, "3rd Party Mac Developer Installer") || starts_with(id, "Mac Installer Distribution"))
            return err(who + "'" + id + "' cannot sign an app for the Mac App Store",
                       "The Mac App Store takes an app signed with an \"Apple Distribution\" or \"3rd Party Mac Developer Application\" certificate (Certificates > + > Apple Distribution in the "
                       "developer portal). Developer ID certificates are for apps shared outside the store (distribution \"developerId\"); an installer certificate signs the .pkg (`installerIdentity`).");
        if (!starts_with(id, "Apple Distribution") && !starts_with(id, "3rd Party Mac Developer Application") && !looks_like_hash(id))
            rep.warnings.push_back("'" + id + "' is not named like an App Store signing certificate (\"Apple Distribution: ...\" or \"3rd Party Mac Developer Application: ...\"); App Store Connect will refuse the build if it is not one.");
    }
    if (store && options.notarize.value_or(false))
        return err(who + "the Mac App Store does not take notarized apps: Apple signs and checks the app itself when it processes the upload",
                   "Leave `notarize` out (or false) with distribution \"appStore\"; notarization is for distribution \"developerId\".");

    // ---- the provisioning profile and the entitlements
    stdfs::path profile;
    if (!options.provisioningProfile.empty()) {
        profile = stdfs::absolute(stdfs::path(options.provisioningProfile), ec);
        if (!is_file(profile))
            return err(who + "the provisioning profile " + generic(profile) + " does not exist",
                       "Download the macOS provisioning profile for the app's App ID from the Apple Developer portal (Certificates, Identifiers & Profiles > Profiles) and pass its path.");
        if (adHoc) return err(who + "a provisioning profile needs a real certificate, and the identity is \"-\" (ad hoc)", store ? "Sign with your Apple Distribution identity, or leave the profile out for a local try." : "Sign with your Developer ID Application identity, or leave the profile out.");
    }
    if (store && !adHoc && profile.empty())
        return err(who + "the Mac App Store needs a provisioning profile, and none was given",
                   "Pass `provisioningProfile`: the path of the 'Mac App Store Connect' profile for the App ID of the game (developer.apple.com > Certificates, Identifiers & Profiles > Profiles). "
                   "It is embedded in the app and gives the signature its application and team identifiers. Identity \"-\" needs none (a local try).");
    stdfs::path entitlements;
    if (!options.entitlements.empty()) {
        entitlements = stdfs::absolute(stdfs::path(options.entitlements), ec);
        if (!is_file(entitlements)) return err(who + "the entitlements file " + generic(entitlements) + " does not exist", "Pass the path of a .entitlements property list, or leave it out.");
        if (store) {
            auto text = tooling_detail::read_file(entitlements);
            if (!text || text->find(kSandboxKey) == std::string::npos)
                return err(who + generic(entitlements) + " does not turn the App Sandbox on",
                           std::string("The Mac App Store requires ") + kSandboxKey + " set to true in the entitlements of the app. Add it, or leave `entitlements` out: FactorIA writes the entitlements of a sandboxed game itself.");
        }
    } else if (!store) {
        // The export writes <slug>.entitlements next to the app when the plugins ask for capabilities (Game Center, iCloud). They are
        // restricted: macOS kills an app that claims one without a provisioning profile, so they are applied only with a profile.
        std::vector<stdfs::path> found;
        for (stdfs::directory_iterator it(os_path(app.parent_path()), ec), end; !ec && it != end; it.increment(ec))
            if (it->is_regular_file(ec) && it->path().extension() == ".entitlements" && it->path().filename().string().find(".appstore") == std::string::npos) found.push_back(it->path());
        if (found.size() == 1) {
            if (!profile.empty() && !adHoc) {
                entitlements = found.front();
            } else {
                rep.warnings.push_back("The export's " + found.front().filename().string() + " (capabilities the native plugins ask for) was not applied: macOS only accepts such "
                                       "entitlements in an app with a provisioning profile for its App ID. The app is signed without them and those services answer "
                                       "'unavailable'. To turn them on, pass `provisioningProfile` (docs/PLATFORM.md, section Apple).");
            }
        }
    }
    if (!entitlements.empty() && !store) {
        auto text = tooling_detail::read_file(entitlements);
        if (text && text->find("TEAMID") != std::string::npos)
            return err(who + generic(entitlements) + " still has the placeholder TEAMID",
                       "Replace TEAMID with your 10-character Apple Team ID (developer.apple.com > Membership), or set export.ios.teamId in factoria.json and export again.");
    }

    // ---- notarization: whether, and with which credentials
    Credentials credentials = resolve_credentials(options, env, *machine, keychain);
    bool notarize = false;
    if (!store && options.notarize.value_or(true)) {
        const bool asked = options.notarize.has_value();
        std::string cannot;
        if (adHoc) cannot = "an ad hoc signature (identity \"-\") cannot be notarized";
        else if (wrongKind)
            cannot = "'" + rep.identity + "' is not a Developer ID Application certificate, the only kind Apple notarizes for distribution outside the Mac App Store (create one in the Apple Developer portal, Certificates)";
        else if (!credentials.problem.empty()) cannot = credentials.problem;
        else if (!credentials.found()) cannot = "no notarization credentials were found";
        if (cannot.empty()) {
            notarize = true;
        } else if (asked) {
            return err(who + "cannot notarize: " + cannot,
                       credentials.found() || !credentials.problem.empty() || adHoc || wrongKind
                           ? "Use a Developer ID Application identity and complete credentials, or pass notarize: false to only sign."
                           : "Give notarytool a login, one of: a keychain profile saved with `xcrun notarytool store-credentials <name>` (`keychainProfile` or FACTORIA_NOTARY_PROFILE), "
                             "an App Store Connect API key (`apiKey` + `apiKeyId` + `apiIssuer`, or FACTORIA_NOTARY_API_KEY / _KEY_ID / _ISSUER), or an Apple ID (`appleId` + `teamId`, or "
                             "FACTORIA_APPLE_ID / FACTORIA_APPLE_TEAM_ID, and the app-specific password in FACTORIA_APPLE_APP_PASSWORD). Or pass notarize: false to only sign.");
        } else if (!adHoc) {
            rep.warnings.push_back("The app is not notarized: " + cannot + ". Gatekeeper warns about a downloaded app that is signed but not notarized. Give notarytool credentials "
                                   "(docs/EXPORTING.md, \"Signing and notarizing for macOS\") or pass notarize: false to silence this.");
        }
    }
    if (notarize) rep.credentials = credentials.description;
    if (adHoc && !store) rep.warnings.push_back("Signed ad hoc: the app runs on this Mac only. A Mac that downloads it calls it damaged or unidentified; use a Developer ID Application identity to share it.");
    if (host != "macos") rep.warnings.push_back("This computer is not a Mac (" + host + "), so this is a dry run: the command lines are the ones a Mac would run, with this computer's paths.");

    const stdfs::path zip = options.zip.empty() ? default_zip(app) : stdfs::absolute(stdfs::path(options.zip), ec).lexically_normal();
    rep.zip = generic(zip);

    // ---- the Mac App Store: what the app and its profile say, the installer identity, the entitlements
    AppInfo info;
    ProfileInfo profileInfo;
    stdfs::path pkgFile, storeEntitlements, inheritEntitlements;
    Json planned = Json::object();  // the entitlements the signature will carry
    std::string installerIdentity;
    std::vector<std::string> helperNotes;
    bool needInherit = false;
    Runner runner(options, rep, {credentials.secret});
    if (store) {
        info = read_app_info(app);
        if (!info.parsed)
            return err(who + generic(app / "Contents" / "Info.plist") + " cannot be read as an XML property list", "Export the game for macOS again: project.export {\"platform\":\"macos\"} writes a readable Info.plist.");
        if (info.bundleId.empty()) return err(who + "the app's Info.plist has no CFBundleIdentifier", "Set \"id\" in factoria.json (e.g. \"com.mystudio.mygame\") and export again.");
        static const std::regex versionRe("^[0-9]+(\\.[0-9]+){0,2}$");
        for (const auto& [key, value] : {std::pair<const char*, std::string>{"CFBundleShortVersionString", info.shortVersion}, {"CFBundleVersion", info.version}}) {
            if (std::regex_match(value, versionRe)) continue;
            const std::string msg = std::string("the app's ") + key + " is '" + value + "', which the Mac App Store refuses (one to three whole numbers separated by dots)";
            const std::string hint = std::string("Set \"version\" in factoria.json to something like \"1.2.3\"") + (std::string(key) == "CFBundleVersion" ? " (or export.macos.buildNumber)" : "") + " and export again.";
            if (adHoc) rep.warnings.push_back(msg + ". " + hint);
            else return err(who + msg, hint);
        }
        if (info.icon.empty()) rep.warnings.push_back("The app has no icon (CFBundleIconFile): App Store Connect refuses an app without one. Set `icon` in factoria.json (a 1024x1024 PNG) and export again.");
        if (info.category.empty()) rep.warnings.push_back("The app has no LSApplicationCategoryType: App Store Connect needs a category. Set export.macos.category in factoria.json and export again.");

        // Settings of the game: the extra sandbox capabilities.
        Json extras = Json::object();
        if (!options.projectDir.empty() && is_file(stdfs::path(options.projectDir) / "factoria.json")) {
            auto st = load_export_settings(options.projectDir);
            if (!st.ok()) return st.error();
            extras = st->macos.entitlements;
        }

        // The profile.
        if (!adHoc) {
            std::string plistText;
            bool have = false;
            if (!options.dryRun) {
                const std::string title = "Read the provisioning profile";
                const std::vector<std::string> argv = {kSecurity, "cms", "-D", "-i", generic(profile)};
                auto r = runner.go(title, argv);
                if (!r.ok()) return r.error();
                if (r->exitCode != 0) return runner.failed(title, argv, *r, "The file is not a provisioning profile: download it again from the developer portal (Profiles).");
                plistText = r->stdoutText;
                have = true;
            } else {
                (void)runner.go("Read the provisioning profile", {kSecurity, "cms", "-D", "-i", generic(profile)});
                if (auto raw = tooling_detail::read_file(profile)) { plistText = *raw; have = true; }
            }
            auto plist = have ? tooling_detail::parse_xml_plist(plistText) : Result<Json>(Error{"unreadable", ""});
            if (plist.ok()) {
                auto pi = check_profile(*plist, info.bundleId, generic(profile));
                if (!pi.ok()) return pi.error();
                profileInfo = *pi;
            } else if (options.dryRun) {
                profileInfo.checked = false;
                profileInfo.teamId = "TEAMID";
                profileInfo.appId = "TEAMID." + info.bundleId;
                rep.warnings.push_back("Dry run: the provisioning profile could not be read here, so its identifiers are placeholders and it was not checked against the game's id.");
            } else {
                return err(who + "cannot read the provisioning profile " + generic(profile) + ": " + plist.error().message, "Download the profile again from the developer portal.");
            }
            rep.profile = (profileInfo.name.empty() ? std::string("provisioning profile") : profileInfo.name) + " (" + profileInfo.appId + ")";
        }

        // The entitlements: sandbox + the plugins' (only with a profile) + the game's extras + the profile's identifiers.
        planned[kSandboxKey] = true;
        std::vector<stdfs::path> found;
        for (stdfs::directory_iterator it(os_path(app.parent_path()), ec), end; !ec && it != end; it.increment(ec))
            if (it->is_regular_file(ec) && it->path().extension() == ".entitlements" && it->path().filename().string().find(".appstore") == std::string::npos) found.push_back(it->path());
        if (options.entitlements.empty() && found.size() == 1) {
            if (!adHoc) {
                auto pe = plugin_entitlements(found.front(), profileInfo.teamId);
                if (!pe.ok()) return pe.error();
                for (auto it = pe->begin(); it != pe->end(); ++it) planned[it.key()] = it.value();
            } else {
                rep.warnings.push_back("The export's " + found.front().filename().string() + " (capabilities the native plugins ask for) was not applied: macOS only accepts such entitlements in an app with a "
                                       "provisioning profile for its App ID, and an ad hoc signature has none. Those services answer 'unavailable' in this local try.");
            }
        }
        for (auto it = extras.begin(); it != extras.end(); ++it) planned[it.key()] = it.value();
        if (!adHoc) {
            planned["com.apple.application-identifier"] = profileInfo.appId;
            planned["com.apple.developer.team-identifier"] = profileInfo.teamId;
        }
        const stdfs::path base = sibling_base(app);
        if (options.entitlements.empty()) storeEntitlements = base.string() + ".appstore.entitlements";
        else storeEntitlements = entitlements;
        entitlements = storeEntitlements;
        inheritEntitlements = base.string() + ".appstore-inherit.entitlements";
        pkgFile = options.pkg.empty() ? stdfs::path(base.string() + ".pkg") : stdfs::absolute(stdfs::path(options.pkg), ec).lexically_normal();
        rep.pkg = generic(pkgFile);
        rep.zip.clear();

        // The installer identity.
        if (!adHoc) {
            installerIdentity = first_set({options.installerIdentity, env("FACTORIA_MACOS_INSTALLER_IDENTITY"), machine->installerIdentity});
            if (installerIdentity.empty())
                return err(who + "no installer identity: say which certificate signs the .pkg for the Mac App Store",
                           "Pass `installerIdentity` (a \"3rd Party Mac Developer Installer: Your Name (TEAMID)\" / \"Mac Installer Distribution: ...\" certificate: Certificates > + > Mac Installer Distribution in "
                           "the developer portal), set FACTORIA_MACOS_INSTALLER_IDENTITY, or write {\"sign\": {\"macos\": {\"installerIdentity\": \"...\"}}} in " + configPath +
                           ". `security find-identity -v` lists the names (installer certificates are not in the codesigning list).");
            if (starts_with(installerIdentity, "Developer ID Installer") || starts_with(installerIdentity, "Developer ID Application") || starts_with(installerIdentity, "Apple Distribution") ||
                starts_with(installerIdentity, "3rd Party Mac Developer Application"))
                return err(who + "'" + installerIdentity + "' cannot sign the .pkg of a Mac App Store app",
                           "Use a \"3rd Party Mac Developer Installer\" / \"Mac Installer Distribution\" certificate. (Developer ID Installer is for packages shared outside the store; an application certificate signs the app.)");
            rep.installerIdentity = installerIdentity;
        } else if (!options.installerIdentity.empty()) {
            rep.warnings.push_back("The installer identity was ignored: an ad hoc app gets an unsigned .pkg.");
        }
        if (adHoc)
            rep.warnings.push_back("Ad hoc sandbox try: the app is signed with \"-\" and the .pkg is not signed. This is for checking on this Mac only: App Store Connect refuses it. "
                                   "Sign with an Apple Distribution identity, a provisioning profile and an installer identity to upload.");

        // Native code in the app that does not belong in the store.
        for (const stdfs::path& code : nested_code(app)) {
            const std::string lower = to_lower(code.filename().string());
            for (const char* store_name : {"steam", "eossdk", "galaxy"})
                if (lower.find(store_name) != std::string::npos) {
                    rep.warnings.push_back("Contents/Frameworks/" + generic(code.lexically_relative(app / "Contents" / "Frameworks")) + " looks like the backend of another store (" + store_name +
                                           "). A game for the Mac App Store uses the Apple plugin (Game Center, StoreKit); Steam and the like do not belong in it, and Apple may refuse the app. Export without that plugin for the store.");
                    break;
                }
            if (is_helper_program(code)) needInherit = true;
        }
    }

    // ---- the steps
    auto sign_args = [&](const stdfs::path& what, const stdfs::path& withEntitlements) {
        std::vector<std::string> a = {kCodesign, "--force"};
        if (adHoc) a.push_back("--timestamp=none");
        else if (store) a.push_back("--timestamp");
        else a.insert(a.end(), {"--options", "runtime", "--timestamp"});
        if (!withEntitlements.empty()) a.insert(a.end(), {"--entitlements", generic(withEntitlements)});
        a.insert(a.end(), {"--sign", rep.identity});
        if (!keychain.empty()) a.insert(a.end(), {"--keychain", keychain});
        a.push_back(generic(what));
        return a;
    };

    auto write_step = [&](const std::string& title, const stdfs::path& file, const Json& content) -> Result<void> {
        SignStep step;
        step.title = title;
        step.command = {"write", generic(file)};
        if (!options.dryRun) {
            std::string e;
            if (!tooling_detail::write_file(file, entitlements_plist(content), &e)) return err(who + "cannot write " + generic(file) + ": " + e);
            step.ran = true;
            step.exitCode = 0;
        }
        rep.steps.push_back(std::move(step));
        return {};
    };
    if (store) {
        // What the app is made of: the architectures of the executable (informational: a failing lipo does not stop the signing).
        if (!info.executable.empty()) {
            const std::string title = "Check the architectures of the executable";
            const std::vector<std::string> argv = {kLipo, "-archs", generic(app / "Contents" / "MacOS" / info.executable)};
            auto r = runner.go(title, argv);
            if (!r.ok()) return r.error();
            if (!options.dryRun && r->exitCode == 0) {
                const std::string archs(trim(r->stdoutText));
                const bool arm = archs.find("arm64") != std::string::npos, intel = archs.find("x86_64") != std::string::npos;
                if (!archs.empty() && !arm)
                    rep.warnings.push_back("The executable is " + archs + " only: it runs on Apple silicon Macs through Rosetta, and Apple expects Mac apps to run natively there. Use a universal or arm64 player.");
                else if (!archs.empty() && !intel)
                    rep.warnings.push_back("The executable is arm64 only: the app runs on Apple silicon Macs and App Store Connect offers it to those only. Intel Macs need the x86_64 slice (FactorIA's release player is universal).");
            }
        }
        if (options.entitlements.empty())
            if (auto w = write_step("Write the entitlements of the app", storeEntitlements, planned); !w.ok()) return w.error();
        if (needInherit) {
            Json inherit = Json::object();
            inherit[kSandboxKey] = true;
            inherit["com.apple.security.inherit"] = true;
            if (auto w = write_step("Write the entitlements of the helper programs", inheritEntitlements, inherit); !w.ok()) return w.error();
        }
    }
    for (const stdfs::path& code : nested_code(app)) {
        const std::string title = "Sign " + generic(code.lexically_relative(app));
        auto argv = sign_args(code, store && is_helper_program(code) ? inheritEntitlements : stdfs::path());
        auto r = runner.go(title, argv);
        if (!r.ok()) return r.error();
        if (r->exitCode != 0)
            return runner.failed(title, argv, *r, "Check that the identity '" + rep.identity + "' is in a keychain this user can use (`security find-identity -v -p codesigning`) and that the keychain is unlocked.");
    }
    if (!profile.empty()) {
        const stdfs::path embedded = app / "Contents" / "embedded.provisionprofile";
        SignStep step;
        step.title = "Embed the provisioning profile";
        step.command = {"cp", generic(profile), generic(embedded)};
        if (!options.dryRun) {
            stdfs::copy_file(os_path(profile), os_path(embedded), stdfs::copy_options::overwrite_existing, ec);
            if (ec) return err(who + "cannot copy the provisioning profile to " + generic(embedded) + ": " + ec.message());
            step.ran = true;
            step.exitCode = 0;
        }
        rep.steps.push_back(std::move(step));
    }
    {
        const std::string title = "Sign " + app.filename().string();
        auto argv = sign_args(app, entitlements);
        auto r = runner.go(title, argv);
        if (!r.ok()) return r.error();
        if (r->exitCode != 0)
            return runner.failed(title, argv, *r, "Check that the identity '" + rep.identity + "' is in a keychain this user can use (`security find-identity -v -p codesigning`) and that the keychain is unlocked.");
        rep.signedApp = !options.dryRun;
    }
    {
        const std::string title = "Verify the signature";
        const std::vector<std::string> argv = {kCodesign, "--verify", "--deep", "--strict", "--verbose=2", generic(app)};
        auto r = runner.go(title, argv);
        if (!r.ok()) return r.error();
        if (r->exitCode != 0) return runner.failed(title, argv, *r, "The app is not sealed correctly; sign it again, and export again if the files inside were changed after the export.");
        rep.verified = !options.dryRun;
    }

    if (store) {
        {  // What the signature really carries (codesign -d --entitlements :- prints the XML).
            const std::string title = "Read back the entitlements of the signature";
            const std::vector<std::string> argv = {kCodesign, "-d", "--entitlements", ":-", generic(app)};
            auto r = runner.go(title, argv);
            if (!r.ok()) return r.error();
            if (!options.dryRun) {
                if (r->exitCode != 0) return runner.failed(title, argv, *r, "The app is not signed; sign it again.");
                auto got = tooling_detail::parse_xml_plist(r->stdoutText + "\n" + r->stderrText);
                if (!got.ok() || !got->is_object() || !got->value(kSandboxKey, false))
                    return err(who + "the signed app does not carry the App Sandbox entitlement (" + kSandboxKey + ")",
                               "The Mac App Store refuses an app without it. Pass no `entitlements` of your own, or add the key to the file, and sign again.");
                rep.entitlements = *got;
            } else {
                rep.entitlements = planned;
            }
        }
        if (!adHoc || true) {
            std::vector<std::string> argv = {kProductbuild, "--component", generic(app), "/Applications"};
            if (!adHoc) argv.insert(argv.end(), {"--sign", installerIdentity});
            if (!keychain.empty() && !adHoc) argv.insert(argv.end(), {"--keychain", keychain});
            argv.push_back(generic(pkgFile));
            const std::string title = adHoc ? "Build the installer package (unsigned)" : "Build and sign the installer package";
            std::error_code mk;
            if (!options.dryRun) stdfs::create_directories(os_path(pkgFile.parent_path()), mk);
            auto r = runner.go(title, argv);
            if (!r.ok()) return r.error();
            if (r->exitCode != 0)
                return runner.failed(title, argv, *r, adHoc ? "Check the free disk space and that the folder of the .pkg is writable."
                                                            : "Check that the installer identity '" + installerIdentity + "' is in a keychain this user can use (`security find-identity -v`) and that the keychain is unlocked.");
        }
        if (!adHoc) {
            const std::string title = "Check the signature of the installer package";
            const std::vector<std::string> argv = {kPkgutil, "--check-signature", generic(pkgFile)};
            auto r = runner.go(title, argv);
            if (!r.ok()) return r.error();
            if (r->exitCode != 0) return runner.failed(title, argv, *r, "The .pkg is not signed with a valid installer certificate; check `installerIdentity`.");
            rep.pkgSigned = !options.dryRun;
        }
    }

    if (notarize) {
        const stdfs::path submitZip = zip.parent_path() / (zip.stem().string() + "-notarize.zip");
        {
            const std::string title = "Zip the app for notarization";
            const std::vector<std::string> argv = {kDitto, "-c", "-k", "--keepParent", generic(app), generic(submitZip)};
            auto r = runner.go(title, argv);
            if (!r.ok()) return r.error();
            if (r->exitCode != 0) return runner.failed(title, argv, *r, "Check the free disk space and that the folder of the zip is writable.");
        }
        std::vector<std::string> submit = {kXcrun, "notarytool", "submit", generic(submitZip)};
        std::vector<std::string> submitShown = submit;
        submit.insert(submit.end(), credentials.argv.begin(), credentials.argv.end());
        submitShown.insert(submitShown.end(), credentials.shown.begin(), credentials.shown.end());
        for (std::vector<std::string>* v : {&submit, &submitShown}) v->insert(v->end(), {"--wait", "--timeout", "40m", "--output-format", "json"});
        auto sent = runner.go("Notarize (upload to Apple and wait for the verdict)", submit, submitShown, 45 * 60);
        std::error_code rm;
        stdfs::remove(os_path(submitZip), rm);
        if (!sent.ok()) return sent.error();
        if (!options.dryRun) {
            const NotaryAnswer answer = parse_notary(sent->stdoutText.empty() ? sent->stderrText : sent->stdoutText);
            rep.notarizationId = answer.id;
            if (answer.status != "Accepted") {
                std::string detail;
                if (!answer.id.empty()) {  // the log says why Apple refused (an unsigned library, no hardened runtime...)
                    std::vector<std::string> log = {kXcrun, "notarytool", "log", answer.id};
                    std::vector<std::string> logShown = log;
                    log.insert(log.end(), credentials.argv.begin(), credentials.argv.end());
                    logShown.insert(logShown.end(), credentials.shown.begin(), credentials.shown.end());
                    if (auto got = runner.go("Fetch the notarization log", log, logShown, 300); got.ok() && got->exitCode == 0) {
                        detail = got->stdoutText;
                        if (detail.size() > 3000) detail = detail.substr(0, 3000) + "...";
                    }
                }
                const std::string said = last_lines(sent->stderrText.empty() ? sent->stdoutText : sent->stderrText + "\n" + sent->stdoutText, 4);
                return err(who + "Apple did not accept the app" + (answer.status.empty() ? std::string(" (notarytool exited with code ") + std::to_string(sent->exitCode) + ")" : ": status " + answer.status) +
                               (answer.id.empty() ? std::string() : " (submission " + answer.id + ")") +
                               (detail.empty() ? (said.empty() ? std::string() : ". notarytool said: " + said) : ". Apple's log: " + detail),
                           answer.id.empty() ? "Check the credentials (a wrong password, Team ID or key shows up here) and the network, then run it again."
                                             : "Fix what the log lists (typically a library that is not signed with the hardened runtime and a timestamp, or an app that was changed after signing), export again and run sign.macos again.");
            }
            rep.notarized = true;
        }
        {
            const std::string title = "Staple the ticket to the app";
            const std::vector<std::string> argv = {kXcrun, "stapler", "staple", generic(app)};
            auto r = runner.go(title, argv);
            if (!r.ok()) return r.error();
            if (r->exitCode != 0) return runner.failed(title, argv, *r, "Apple accepted the app, so run it again in a few minutes: the ticket may not be published yet.");
            rep.stapled = !options.dryRun;
        }
        {
            const std::string title = "Check the stapled ticket";
            const std::vector<std::string> argv = {kXcrun, "stapler", "validate", generic(app)};
            auto r = runner.go(title, argv);
            if (!r.ok()) return r.error();
            if (r->exitCode != 0) return runner.failed(title, argv, *r, "Staple again.");
        }
        {
            const std::string title = "Ask Gatekeeper (spctl)";
            const std::vector<std::string> argv = {kSpctl, "--assess", "--type", "execute", "--verbose=4", generic(app)};
            auto r = runner.go(title, argv);
            if (!r.ok()) return r.error();
            if (r->exitCode != 0)
                return runner.failed(title, argv, *r, "Gatekeeper rejects an app that was signed and notarized: do not distribute it. Make sure it was not changed after signing, and sign it again.");
        }
    }
    if (!store) {
        const std::string title = "Zip the app to share";
        const std::vector<std::string> argv = {kDitto, "-c", "-k", "--keepParent", generic(app), generic(zip)};
        std::error_code mk;
        if (!options.dryRun) stdfs::create_directories(os_path(zip.parent_path()), mk);
        auto r = runner.go(title, argv);
        if (!r.ok()) return r.error();
        if (r->exitCode != 0) return runner.failed(title, argv, *r, "Check the free disk space and that the folder of the zip is writable.");
    }

    // ---- what to do next
    if (store) {
        if (adHoc)
            rep.nextSteps.push_back("Try the sandboxed app on this Mac: run '" + generic(app / "Contents" / "MacOS" / info.executable) + "'; its files go to ~/Library/Containers/" + info.bundleId +
                                    ". To submit it, sign with an Apple Distribution identity, a Mac App Store Connect provisioning profile and an installer identity.");
        else
            rep.nextSteps.push_back("Upload " + rep.pkg + " to App Store Connect: publish.appstore {\"platforms\":[\"macos\"]} (altool with an App Store Connect API key), or the Transporter app. "
                                    "Create the app record in App Store Connect first (same bundle id " + info.bundleId + ").");
    } else if (notarize)
        rep.nextSteps.push_back("Share " + rep.zip + ": it opens on any Mac without a warning, offline too (the ticket is stapled into the app). publish.steam / publish.itch upload the signed app in " +
                                generic(app.parent_path()) + ".");
    else if (adHoc)
        rep.nextSteps.push_back("Run it on this Mac: open '" + generic(app) + "'. To share the game, sign with a Developer ID Application identity and notarize it.");
    else
        rep.nextSteps.push_back(rep.zip + " holds the signed app. To remove Gatekeeper's warning on other Macs, notarize it: run sign.macos again with notarization credentials.");
    if (options.dryRun) rep.nextSteps.push_back("This was a dry run: nothing was signed. Run it again without dryRun on a Mac.");
    return rep;
}

// ---- the command --------------------------------------------------------------------------------------------------

void register_sign_commands(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "sign.macos";
    info.category = "sign";
    info.readOnly = false;
    info.summary = "Sign, notarize and staple the exported macOS app (Developer ID), or sandbox and sign it as a .pkg for the Mac App Store.";
    info.description =
        "Takes the app `project.export` wrote for macOS (build/export/<game-slug>-macos/<Name>.app) and makes it open on any Mac without Gatekeeper warnings: codesign of every native plugin "
        "library in Contents/Frameworks (deepest first) and then the app, with the hardened runtime and a secure timestamp (the export's <slug>.entitlements when `provisioningProfile` is given; "
        "the profile is embedded), codesign --verify --deep --strict, then `xcrun notarytool submit --wait` on a zip of the app (Apple's notary log is quoted when it refuses the app), "
        "`xcrun stapler staple`, spctl --assess, and finally a zip to share next to the export folder (<game-slug>-macos.zip). Needs a Mac (codesign, notarytool and stapler exist nowhere "
        "else): on another computer only `dryRun` works and a real run is an error that says so. `dryRun: true` checks everything and returns the exact command lines in steps[]. "
        "Identity: `identity` (\"Developer ID Application: Your Name (TEAMID)\"; `security find-identity -v -p codesigning` lists them), else FACTORIA_MACOS_SIGN_IDENTITY, else "
        "sign.macos.identity of ~/.factoria/export.json; \"-\" signs ad hoc (this Mac only, no notarization). Notarization logs in with the first of: a keychain profile (`keychainProfile`, "
        "FACTORIA_NOTARY_PROFILE, sign.macos.notaryProfile; saved once with `xcrun notarytool store-credentials`), an App Store Connect API key (`apiKey` file, `apiKeyId`, `apiIssuer`; or "
        "FACTORIA_NOTARY_API_KEY / _KEY_ID / _ISSUER), or an Apple ID (`appleId` + `teamId` or FACTORIA_APPLE_ID / FACTORIA_APPLE_TEAM_ID, and the app-specific password in "
        "FACTORIA_APPLE_APP_PASSWORD only). `distribution: \"appStore\"` prepares the Mac App Store submission instead: the app is sandboxed "
        "(com.apple.security.app-sandbox + the plugins' entitlements + export.macos.entitlements + the identifiers of the provisioning profile, which is required and embedded), signed with an "
        "\"Apple Distribution\" / \"3rd Party Mac Developer Application\" identity (`identity`, FACTORIA_MACOS_APPSTORE_IDENTITY or sign.macos.appStoreIdentity; \"-\" = a local ad hoc try of the sandbox), "
        "never notarized, wrapped by productbuild in <game-slug>-macos.pkg signed with `installerIdentity` (FACTORIA_MACOS_INSTALLER_IDENTITY or sign.macos.installerIdentity) and checked with "
        "pkgutil --check-signature; the result adds distribution, pkg, pkgSigned, installerIdentity, profile and the entitlements read back from the signature. publish.appstore uploads the .pkg. "
        "No password is ever an argument of this command, in factoria.json, in a result or in a log. `notarize` unset notarizes when there are credentials "
        "and a Developer ID identity (else only signs, with a warning); true makes missing credentials an error; false only signs. Returns {app, dryRun, identity, identityFrom, credentials, "
        "signed, verified, notarized, stapled, notarizationId, zip, distribution, [appStore: pkg, pkgSigned, installerIdentity, profile, entitlements], steps[{title, command, commandLine, ran, exitCode}], warnings[], nextSteps[]}. The export is replaced by the next "
        "project.export: sign again after every export. Details: docs_read {\"name\":\"exporting\"}. Examples: {\"dryRun\":true}, {\"identity\":\"Developer ID Application: Ada Lovelace (ABCDE12345)\","
        "\"keychainProfile\":\"factoria-notary\"}, {\"identity\":\"-\"}.";
    info.inputSchema = Json::parse(R"({
      "type":"object",
      "properties":{
        "app":{"type":"string","description":"The .app to sign, relative to the project. Default: build/export/<game-slug>-macos/<Name>.app (the export of this game)."},
        "out":{"type":"string","description":"Parent folder of the export, relative to the project (the `out` of project.export). Default: build/export."},
        "identity":{"type":"string","description":"The signing identity: the name of a 'Developer ID Application' certificate or its SHA-1 hash; \"-\" = ad hoc. Default: FACTORIA_MACOS_SIGN_IDENTITY, else sign.macos.identity of ~/.factoria/export.json."},
        "distribution":{"type":"string","enum":["developerId","appStore"],"default":"developerId","description":"developerId = sign, notarize and zip for sharing outside the store; appStore = sandbox, sign for the Mac App Store and build the signed .pkg (needs provisioningProfile and installerIdentity, unless identity is \"-\")."},
        "installerIdentity":{"type":"string","description":"appStore: the '3rd Party Mac Developer Installer' / 'Mac Installer Distribution' certificate that signs the .pkg. Default: FACTORIA_MACOS_INSTALLER_IDENTITY, else sign.macos.installerIdentity of ~/.factoria/export.json."},
        "pkg":{"type":"string","description":"appStore: where the .pkg goes, relative to the project. Default: next to the export folder, <game-slug>-macos.pkg."},
        "keychain":{"type":"string","description":"A keychain file that holds the certificate (or the notary profile). Default: FACTORIA_MACOS_KEYCHAIN, else the user's keychains."},
        "provisioningProfile":{"type":"string","description":"A .provisionprofile to embed in the app (needed for the capabilities the plugins ask for: Game Center, iCloud). With it the export's <slug>.entitlements are applied. Absolute path, or relative to the project."},
        "entitlements":{"type":"string","description":"An entitlements file for the app. Default: the export's <slug>.entitlements, used only with a provisioningProfile. Absolute path, or relative to the project."},
        "notarize":{"type":"boolean","description":"true = notarize (an error without a Developer ID identity and credentials); false = only sign; unset = notarize when credentials are found."},
        "keychainProfile":{"type":"string","description":"notarytool keychain profile, saved with `xcrun notarytool store-credentials <name>`. Default: FACTORIA_NOTARY_PROFILE, else sign.macos.notaryProfile of ~/.factoria/export.json."},
        "apiKey":{"type":"string","description":"App Store Connect API key file (AuthKey_<id>.p8), absolute or relative to the project. Default: FACTORIA_NOTARY_API_KEY."},
        "apiKeyId":{"type":"string","description":"Key id of the API key. Default: FACTORIA_NOTARY_API_KEY_ID."},
        "apiIssuer":{"type":"string","description":"Issuer id of a team API key (not needed for an individual key). Default: FACTORIA_NOTARY_API_ISSUER."},
        "appleId":{"type":"string","description":"Apple ID for notarization. Default: FACTORIA_APPLE_ID (or APPLE_ID). The app-specific password is read from FACTORIA_APPLE_APP_PASSWORD only."},
        "teamId":{"type":"string","description":"Apple Team ID (10 characters) for notarization with an Apple ID. Default: FACTORIA_APPLE_TEAM_ID (or APPLE_TEAM_ID)."},
        "zip":{"type":"string","description":"Where the zip to share goes, relative to the project. Default: next to the export folder, <game-slug>-macos.zip."},
        "dryRun":{"type":"boolean","default":false,"description":"Check everything and return the exact command lines in steps[]; sign and send nothing. Works on any computer."}
      }})");
    registry.add(info, [projectDir](const Json& args) {
        SignMacosOptions o;
        o.projectDir = projectDir;
        // The app, the export folder and the zip stay inside the project, like fs.* and project.export: an AI cannot point a
        // certificate at any app of the computer. The inputs (profile, entitlements, key, keychain) may live anywhere.
        auto inside = [&](const std::string& rel, const char* what) {
            auto dir = resolve_project_path(projectDir, rel);
            if (!dir) throw CommandError("invalid_argument", std::string(what) + ": " + dir.error().message, dir.error().hint);
            return dir->string();
        };
        auto anywhere = [&](const std::string& path, const char* what) {
            return stdfs::path(path).is_absolute() ? path : inside(path, what);
        };
        if (std::string v = tooling_detail::arg_string(args, "app", false); !v.empty()) o.app = inside(v, "app");
        if (std::string v = tooling_detail::arg_string(args, "out", false); !v.empty()) o.outDir = inside(v, "out");
        if (std::string v = tooling_detail::arg_string(args, "zip", false); !v.empty()) o.zip = inside(v, "zip");
        if (std::string v = tooling_detail::arg_string(args, "pkg", false); !v.empty()) o.pkg = inside(v, "pkg");
        o.distribution = tooling_detail::arg_string(args, "distribution", false);
        o.installerIdentity = tooling_detail::arg_string(args, "installerIdentity", false);
        o.identity = tooling_detail::arg_string(args, "identity", false);
        o.keychain = tooling_detail::arg_string(args, "keychain", false);
        if (std::string v = tooling_detail::arg_string(args, "provisioningProfile", false); !v.empty()) o.provisioningProfile = anywhere(v, "provisioningProfile");
        if (std::string v = tooling_detail::arg_string(args, "entitlements", false); !v.empty()) o.entitlements = anywhere(v, "entitlements");
        if (auto it = args.find("notarize"); it != args.end() && it->is_boolean()) o.notarize = it->get<bool>();
        o.keychainProfile = tooling_detail::arg_string(args, "keychainProfile", false);
        if (std::string v = tooling_detail::arg_string(args, "apiKey", false); !v.empty()) o.apiKey = anywhere(v, "apiKey");
        o.apiKeyId = tooling_detail::arg_string(args, "apiKeyId", false);
        o.apiIssuer = tooling_detail::arg_string(args, "apiIssuer", false);
        o.appleId = tooling_detail::arg_string(args, "appleId", false);
        o.teamId = tooling_detail::arg_string(args, "teamId", false);
        o.dryRun = tooling_detail::arg_bool(args, "dryRun", false);
        // Commands have no progress channel of their own: each line of codesign / notarytool goes to the log (stderr of
        // `factoria call` and `factoria mcp`, the editor console), already scrubbed of secrets.
        o.progress = [](const std::string& line) { log(LogLevel::Info, "sign.macos", line); };
        auto r = sign_macos(o);
        if (!r.ok()) throw CommandError("failed", r.error().message, r.error().hint);
        return r->to_json();
    });
}

}  // namespace fa
