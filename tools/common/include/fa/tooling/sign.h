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

}  // namespace fa
