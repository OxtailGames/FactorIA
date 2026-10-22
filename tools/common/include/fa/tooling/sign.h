// Signing and notarizing the exported macOS app: the command sign.macos.
//
// `project.export` leaves <out>/<slug>-macos/<Name>.app sealed with an ad hoc signature: it runs on the Mac that exported it,
// and a copy somebody else downloads is stopped by Gatekeeper. sign.macos turns it into an app anyone can open, with the
// steps Apple asks for (scripts/sign-macos.sh does the same for FactorIA's own release):
//   1. codesign every native plugin library (Contents/Frameworks), deepest first, then the app: --options runtime
//      --timestamp, the export's <slug>.entitlements when a provisioning profile is given, the profile embedded in
//      Contents/embedded.provisionprofile;
//   2. codesign --verify --deep --strict;
//   3. notarize: ditto -> zip, xcrun notarytool submit --wait (the notary log is quoted when Apple refuses the app);
//   4. xcrun stapler staple, spctl --assess (Gatekeeper's own verdict), and the distributable zip.
// `dryRun` lists the exact command lines on any computer; a real run needs a Mac (codesign, notarytool and stapler exist
// nowhere else) and says so otherwise.
//
// Where things live (docs/EXPORTING.md, "Signing and notarizing for macOS"):
//   * the identity: the `identity` argument, else $FACTORIA_MACOS_SIGN_IDENTITY, else "sign.macos.identity" of
//     ~/.factoria/export.json; "-" is the ad hoc identity (no certificate, no notarization).
//   * the notary credentials, in this order: a notarytool keychain profile (`keychainProfile`, $FACTORIA_NOTARY_PROFILE,
//     "sign.macos.notaryProfile"), an App Store Connect API key (`apiKey` + `apiKeyId` [+ `apiIssuer`], or
//     $FACTORIA_NOTARY_API_KEY / _KEY_ID / _ISSUER), or an Apple ID (`appleId` + `teamId`, or $FACTORIA_APPLE_ID /
//     $FACTORIA_APPLE_TEAM_ID; the app-specific password only from $FACTORIA_APPLE_APP_PASSWORD). Nothing secret is ever
//     in factoria.json, in the arguments, in a report or in a log.
#pragma once

#include <functional>
#include <optional>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/process.h"
#include "fa/core/types.h"
#include "fa/tooling/export_settings.h"
#include "fa/tooling/setup.h"

namespace fa {

struct SignMacosOptions {
    std::string projectDir;            // folder containing factoria.json
    std::string app;                   // the .app to sign ("" = <out>/<game-slug>-macos/<Name>.app of the project)
    std::string outDir;                // parent folder of the exports ("" = <projectDir>/build/export)
    std::string identity;              // "Developer ID Application: ..." (or its SHA-1), "-" = ad hoc; "" = the environment, export.json
    std::string keychain;              // a keychain file for codesign and notarytool ("" = $FACTORIA_MACOS_KEYCHAIN, else the default ones)
    std::string provisioningProfile;   // a .provisionprofile to embed (restricted entitlements: Game Center, iCloud)
    std::string entitlements;          // an entitlements file ("" = the export's <slug>.entitlements, when a profile is given)
    std::optional<bool> notarize;      // unset = when there are credentials and a Developer ID identity; true = or an error; false = never
    std::string keychainProfile;       // notarytool --keychain-profile
    std::string apiKey, apiKeyId, apiIssuer;  // notarytool --key (an AuthKey_<id>.p8 file), --key-id, --issuer
    std::string appleId, teamId;       // notarytool --apple-id, --team-id (the password comes from the environment only)
    std::string zip;                   // where the distributable zip goes ("" = <export folder>.zip, next to it)
    bool dryRun = false;               // check everything, return the command lines, run nothing and change nothing
    std::function<void(const std::string& line)> progress;  // optional: each line of codesign / notarytool (secrets scrubbed)
    const CancelFlag* cancel = nullptr;
    ExportEnvLookup env = system_export_env();  // environment variables; only tests change it
    std::string toolConfigPath;        // "" = machine_export_config_path(env); only tests change it
    std::string host;                  // "" = this computer ("macos" | "windows" | "linux"); only tests change it
    ProcessRunner run;                 // empty = fa::run_process; only tests change it
};

struct SignStep {
    std::string title;
    std::vector<std::string> command;  // the command line, secrets replaced by <redacted>
    bool ran = false;
    int exitCode = -1;
};

struct SignReport {
    std::string app;                   // absolute path of the .app
    std::string identity;              // what signed it ("-" = ad hoc)
    std::string identityFrom;          // "argument" | "FACTORIA_MACOS_SIGN_IDENTITY" | "export.json"
    std::string credentials;           // how notarytool logs in, without any secret ("keychain profile 'x'", ...); empty = none used
    std::string zip;                   // absolute path of the distributable zip; empty when none was made
    std::string notarizationId;        // Apple's submission id, once notarized
    bool dryRun = false;
    bool signedApp = false;            // the app and its nested code carry the signature
    bool verified = false;             // codesign --verify --deep --strict accepted it
    bool notarized = false;            // Apple accepted it
    bool stapled = false;              // the ticket is in the app (it opens offline)
    std::vector<SignStep> steps;
    std::vector<std::string> warnings;
    std::vector<std::string> nextSteps;
    Json to_json() const;
};

// Signs (and, unless told otherwise, notarizes) the exported app. An Error means it stopped: the message says which step failed
// and quotes what the tool printed; the app may be signed already (signing again is safe).
Result<SignReport> sign_macos(const SignMacosOptions& options);

// Registers sign.macos (-> MCP tool sign_macos, `factoria call`, editor console, fa.call) for the project at `projectDir`.
void register_sign_commands(CommandRegistry& registry, const std::string& projectDir);

// ---- sign.windows -----------------------------------------------------------------------------------------------------------
//
// Signs the MSIX `project.export --platform windows --format msix` wrote (<out>/<slug>-windows.msix) and, with `exe`, the game's
// .exe, with a code-signing certificate in a .pfx. A package for the Microsoft Store is uploaded UNSIGNED (the Store signs it);
// signing is for installing the package on a PC outside the Store, or for a game sold elsewhere. Behaviour and the step by step
// way to try the package on your own PC: docs/EXPORTING.md ("Microsoft Store").
//   * the certificate: `pfx`, else $FACTORIA_WINDOWS_PFX, else "sign.windows.pfx" of ~/.factoria/export.json; its password ONLY
//     from $FACTORIA_WINDOWS_PFX_PASSWORD (never an argument, a file of the game, a report or a log). `testCertificate` makes a
//     self-signed one for the manifest's Publisher instead (Windows only; PowerShell), to try the package on this PC.
//   * the tool: signtool.exe on Windows ($FACTORIA_SIGNTOOL, else the newest Windows SDK, else PATH); osslsigncode elsewhere
//     ($FACTORIA_OSSLSIGNCODE, else PATH; version 2.9 or newer: APPX signing arrived in 2.7 and its zip order was fixed in 2.9).
struct SignWindowsOptions {
    std::string projectDir;            // folder containing factoria.json
    std::string msix;                  // the .msix to sign ("" = <out>/<game-slug>-windows.msix of the project)
    std::string outDir;                // parent folder of the exports ("" = <projectDir>/build/export)
    bool exe = false;                  // also sign the game's .exe in <out>/<game-slug>-windows/ (before the package is built, sign it and export again)
    std::string pfx;                   // the certificate file ("" = $FACTORIA_WINDOWS_PFX, else export.json)
    bool testCertificate = false;      // create a self-signed certificate for the manifest's Publisher (Windows only) and sign with it
    std::string timestampUrl;          // RFC 3161 time-stamp server ("" = http://timestamp.digicert.com)
    bool dryRun = false;               // check everything, return the command lines, run nothing and change nothing
    std::function<void(const std::string& line)> progress;  // optional: each line the tools print (secrets scrubbed)
    const CancelFlag* cancel = nullptr;
    ExportEnvLookup env = system_export_env();  // environment variables; only tests change it
    std::string toolConfigPath;        // "" = machine_export_config_path(env); only tests change it
    std::string host;                  // "" = this computer ("macos" | "windows" | "linux"); only tests change it
    ProcessRunner run;                 // empty = fa::run_process; only tests change it
};

struct SignWindowsReport {
    std::string msix;                  // absolute path of the signed package ("" when only the exe was signed)
    std::string exe;                   // absolute path of the signed exe ("" when not asked)
    std::string publisher;             // the Publisher of the package manifest ("" when there is no package)
    std::string certificate;           // what signs: "pfx C:/x/cert.pfx" or "test certificate"; never the password
    std::string certificateFrom;       // "argument" | "FACTORIA_WINDOWS_PFX" | "export.json" | "testCertificate"
    std::string tool;                  // "signtool" | "osslsigncode"
    std::string toolPath;
    std::string timestampUrl;
    std::string testCertificateFile;   // the .cer to trust on the PC that installs the package (testCertificate only)
    bool dryRun = false;
    bool signedMsix = false;
    bool signedExe = false;
    std::vector<SignStep> steps;
    std::vector<std::string> warnings;
    std::vector<std::string> nextSteps;
    Json to_json() const;
};

// Signs the package (and the exe). An Error means it stopped: the message says which step failed and quotes what the tool printed.
Result<SignWindowsReport> sign_windows(const SignWindowsOptions& options);

// Registers sign.windows for the project at `projectDir` (called by register_sign_commands).
void register_sign_windows_command(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
