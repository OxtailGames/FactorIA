// sign.macos: Developer ID signing, notarization and stapling of the exported .app. Behaviour: fa/tooling/sign.h and
// docs/EXPORTING.md ("Signing and notarizing for macOS"). The shell version FactorIA's own release uses is scripts/sign-macos.sh.
#include "fa/tooling/sign.h"

#include <algorithm>
#include <cstdint>
#include <deque>
#include <filesystem>
#include <fstream>

#include "export_internal.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/tooling/project_fs.h"
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
    std::string identity, keychain, notaryProfile;
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
    const std::pair<const char*, std::string*> fields[] = {{"identity", &m.identity}, {"keychain", &m.keychain}, {"notaryProfile", &m.notaryProfile}};
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
    } else if (const std::string v = env("FACTORIA_MACOS_SIGN_IDENTITY"); !v.empty()) {
        rep.identity = v;
        rep.identityFrom = "FACTORIA_MACOS_SIGN_IDENTITY";
    } else if (!machine->identity.empty()) {
        rep.identity = machine->identity;
        rep.identityFrom = "export.json";
    }
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

    // ---- the provisioning profile and the entitlements
    stdfs::path profile;
    if (!options.provisioningProfile.empty()) {
        profile = stdfs::absolute(stdfs::path(options.provisioningProfile), ec);
        if (!is_file(profile))
            return err(who + "the provisioning profile " + generic(profile) + " does not exist",
                       "Download the macOS provisioning profile for the app's App ID from the Apple Developer portal (Certificates, Identifiers & Profiles > Profiles) and pass its path.");
        if (adHoc) return err(who + "a provisioning profile needs a real certificate, and the identity is \"-\" (ad hoc)", "Sign with your Developer ID Application identity, or leave the profile out.");
    }
    stdfs::path entitlements;
    if (!options.entitlements.empty()) {
        entitlements = stdfs::absolute(stdfs::path(options.entitlements), ec);
        if (!is_file(entitlements)) return err(who + "the entitlements file " + generic(entitlements) + " does not exist", "Pass the path of a .entitlements property list, or leave it out.");
    } else {
        // The export writes <slug>.entitlements next to the app when the plugins ask for capabilities (Game Center, iCloud). They are
        // restricted: macOS kills an app that claims one without a provisioning profile, so they are applied only with a profile.
        std::vector<stdfs::path> found;
        for (stdfs::directory_iterator it(os_path(app.parent_path()), ec), end; !ec && it != end; it.increment(ec))
            if (it->is_regular_file(ec) && it->path().extension() == ".entitlements") found.push_back(it->path());
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
    if (!entitlements.empty()) {
        auto text = tooling_detail::read_file(entitlements);
        if (text && text->find("TEAMID") != std::string::npos)
            return err(who + generic(entitlements) + " still has the placeholder TEAMID",
                       "Replace TEAMID with your 10-character Apple Team ID (developer.apple.com > Membership), or set export.ios.teamId in factoria.json and export again.");
    }

    // ---- notarization: whether, and with which credentials
    Credentials credentials = resolve_credentials(options, env, *machine, keychain);
    bool notarize = false;
    if (options.notarize.value_or(true)) {
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
    if (adHoc) rep.warnings.push_back("Signed ad hoc: the app runs on this Mac only. A Mac that downloads it calls it damaged or unidentified; use a Developer ID Application identity to share it.");
    if (host != "macos") rep.warnings.push_back("This computer is not a Mac (" + host + "), so this is a dry run: the command lines are the ones a Mac would run, with this computer's paths.");

    const stdfs::path zip = options.zip.empty() ? default_zip(app) : stdfs::absolute(stdfs::path(options.zip), ec).lexically_normal();
    rep.zip = generic(zip);

    // ---- the steps
    Runner runner(options, rep, {credentials.secret});
    auto sign_args = [&](const stdfs::path& what, const stdfs::path& withEntitlements) {
        std::vector<std::string> a = {kCodesign, "--force"};
        if (adHoc) a.push_back("--timestamp=none");
        else a.insert(a.end(), {"--options", "runtime", "--timestamp"});
        if (!withEntitlements.empty()) a.insert(a.end(), {"--entitlements", generic(withEntitlements)});
        a.insert(a.end(), {"--sign", rep.identity});
        if (!keychain.empty()) a.insert(a.end(), {"--keychain", keychain});
        a.push_back(generic(what));
        return a;
    };

    for (const stdfs::path& code : nested_code(app)) {
        const std::string title = "Sign " + generic(code.lexically_relative(app));
        auto argv = sign_args(code, {});
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
    {
        const std::string title = "Zip the app to share";
        const std::vector<std::string> argv = {kDitto, "-c", "-k", "--keepParent", generic(app), generic(zip)};
        std::error_code mk;
        if (!options.dryRun) stdfs::create_directories(os_path(zip.parent_path()), mk);
        auto r = runner.go(title, argv);
        if (!r.ok()) return r.error();
        if (r->exitCode != 0) return runner.failed(title, argv, *r, "Check the free disk space and that the folder of the zip is writable.");
    }

    // ---- what to do next
    if (notarize)
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
    info.summary = "Sign, notarize and staple the exported macOS app (Developer ID), and zip it for sharing.";
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
        "FACTORIA_APPLE_APP_PASSWORD only). No password is ever an argument of this command, in factoria.json, in a result or in a log. `notarize` unset notarizes when there are credentials "
        "and a Developer ID identity (else only signs, with a warning); true makes missing credentials an error; false only signs. Returns {app, dryRun, identity, identityFrom, credentials, "
        "signed, verified, notarized, stapled, notarizationId, zip, steps[{title, command, commandLine, ran, exitCode}], warnings[], nextSteps[]}. The export is replaced by the next "
        "project.export: sign again after every export. Details: docs_read {\"name\":\"exporting\"}. Examples: {\"dryRun\":true}, {\"identity\":\"Developer ID Application: Ada Lovelace (ABCDE12345)\","
        "\"keychainProfile\":\"factoria-notary\"}, {\"identity\":\"-\"}.";
    info.inputSchema = Json::parse(R"({
      "type":"object",
      "properties":{
        "app":{"type":"string","description":"The .app to sign, relative to the project. Default: build/export/<game-slug>-macos/<Name>.app (the export of this game)."},
        "out":{"type":"string","description":"Parent folder of the export, relative to the project (the `out` of project.export). Default: build/export."},
        "identity":{"type":"string","description":"The signing identity: the name of a 'Developer ID Application' certificate or its SHA-1 hash; \"-\" = ad hoc. Default: FACTORIA_MACOS_SIGN_IDENTITY, else sign.macos.identity of ~/.factoria/export.json."},
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
    register_sign_windows_command(registry, projectDir);
}

}  // namespace fa
