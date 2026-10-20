// What each store's uploader is given: the build files FactorIA writes and the command line. One planner per store; the
// shared work (finding the exports and the tool, running, the report) is in publish.cpp. The command lines follow the
// stores' own documentation:
//   steamcmd  https://partner.steamgames.com/doc/sdk/uploading  (app build script AppBuild, depot script DepotBuild,
//             "+login <account> +run_app_build <script> +quit", a cached login lets the password be left out)
//   butler    https://itch.io/docs/butler/pushing.html  (butler push <directory> <user>/<game>:<channel> --userversion
//             <version> --ignore <pattern>) and https://itch.io/docs/butler/login.html (BUTLER_API_KEY, butler login)
//   Epic      https://dev.epicgames.com/docs/epic-games-store/publishing-tools/uploading-binaries/bpt-instructions-160
//             (-mode=UploadBinary with OrganizationId, ProductId, ArtifactId, ClientId, ClientSecretEnvVar, BuildRoot,
//             CloudDir, BuildVersion, AppLaunch, AppArgs, FileIgnoreList)
//   altool    `xcrun altool --help` (App Store Connect API key): --upload-package <ipa> --type ios --apple-id --bundle-id --bundle-version
//             --bundle-short-version-string --apiKey --apiIssuer; the key is found as AuthKey_<KeyID>.p8 in API_PRIVATE_KEYS_DIR
//             (else ./private_keys, ~/private_keys, ~/.private_keys, ~/.appstoreconnect/private_keys)
//   supply    https://docs.fastlane.tools/actions/supply/  (--aab --track --release_status --package_name --json_key --metadata_path;
//             release notes are <metadata_path>/<locale>/changelogs/default.txt)
//   GOG       https://docs.gog.com/pb-build-game/  (GOGGalaxyPipelineBuilder build-game <project.json> [--ignore_list F]
//             [--version V] [--branch B] [--username U --password P]; the project file format is the page's example)
#include <algorithm>
#include <regex>

#include "fa/core/strings.h"
#include "fa/core/utf8.h"
#include "fa/tooling/project_fs.h"
#include "publish_internal.h"
#include "util.h"

namespace fa::publish_detail {

namespace {

const char* const kEpicSecretVar = "FACTORIA_EPIC_CLIENT_SECRET";
const char* const kGogUserVar = "FACTORIA_GOG_USERNAME";
const char* const kGogPasswordVar = "FACTORIA_GOG_PASSWORD";

std::string tab_value(std::string v) {  // a VDF string: quotes would end it
    std::replace(v.begin(), v.end(), '"', '\'');
    return v;
}

std::string env_of(const Context& c, const char* name) { return c.options.env ? c.options.env(name) : std::string(); }

// A dry run lists what is missing (the app id, an account, a secret...) as a warning and plans on with a placeholder, so it still
// returns the steps; a real run stops with the error. Use: `if (auto e = dry_missing(c, err(...))) return *e;`.
std::optional<Error> dry_missing(Context& c, Error e) {
    if (!c.options.dryRun) return e;
    c.warnings.push_back("Missing, a placeholder is used in this dry run: " + e.message + (e.hint.empty() ? std::string() : ". " + e.hint));
    return std::nullopt;
}

std::string pointer_hint(const std::string& what, const std::string& example) {
    return "Add " + what + " to factoria.json, e.g. " + example + " (docs/EXPORTING.md, \"Uploading to stores\").";
}

// ---- Steam -------------------------------------------------------------------------------------------------

constexpr unsigned kSteamTestApp = 480;  // Valve's Spacewar

// The app id: the `appId` argument, else the number in steam_appid.txt, the one place the project keeps it (docs/PLATFORM.md).
Result<std::string> steam_app_id(Context& c) {
    std::string text = c.options.appId, from = "the appId argument";
    if (text.empty()) {
        const stdfs::path file = c.projectDir / "steam_appid.txt";
        if (!is_file(file)) {
            if (auto e = dry_missing(c, err("steam: the game has no Steam app id: there is no steam_appid.txt in " + generic(c.projectDir) + " and no appId argument",
                       "Your app id is the number in the Steamworks partner site (App Admin). Write it to steam_appid.txt with "
                       "platform.add_backend {\"backend\":\"steam\",\"appId\":<your id>} (the file is for development and never shipped), or pass \"appId\".")))
                return *e;
            return std::string("MISSING_APP_ID");
        }
        text = std::string(trim(tooling_detail::read_file(file).value_or("")));
        from = "steam_appid.txt";
    }
    const bool digits = !text.empty() && text.size() <= 10 && std::all_of(text.begin(), text.end(), [](char ch) { return ch >= '0' && ch <= '9'; });
    const long long n = digits ? std::stoll(text) : 0;
    if (n < 1 || n > 4294967295LL)
        return err("steam: the app id from " + from + " is not a Steam app id (it says '" + text.substr(0, 40) + "')",
                   "Use the number of your game from the Steamworks partner site, e.g. 1234560.");
    if (n == kSteamTestApp)
        return err("steam: the app id from " + from + " is 480, Valve's test app (Spacewar): a build cannot be uploaded to it",
                   "Put your own app id in steam_appid.txt (platform.add_backend {\"backend\":\"steam\",\"appId\":<your id>}) or pass \"appId\".");
    return std::to_string(n);
}

bool steam_configured(const PublishSettings& s, const std::string& platform) { return s.steam.depots.count(platform) > 0; }

Result<std::vector<Job>> plan_steam(Context& c) {
    const SteamPublishSettings& s = c.settings.steam;
    auto appId = steam_app_id(c);
    if (!appId.ok()) return appId.error();
    std::string account = !c.options.account.empty() ? c.options.account : s.account;
    if (account.empty()) {
        if (auto e = dry_missing(c, err("steam: no Steam account to upload with (factoria.json#/publish/steam/account is not set and there is no account argument)",
                   pointer_hint("the name of your Steam build account", "\"publish\": {\"steam\": {\"account\": \"mystudio_build\"}}") +
                       " Its password is never stored: run `steamcmd +login <account>` once to enter it (and the Steam Guard code); steamcmd keeps the login.")))
            return *e;
        account = "MISSING_ACCOUNT";
    }
    const std::string branch = !c.options.branch.empty() ? c.options.branch : s.branch;
    if (to_lower(branch) == "default")
        return err("steam: 'default' cannot be set live from an upload",
                   "Use a beta branch (\"branch\": \"beta\"), then make the build default in the Steamworks partner site (App Admin > SteamPipe > Builds).");

    std::string launchText;
    std::vector<std::pair<stdfs::path, std::string>> depotFiles;  // after the app script
    Job job;
    job.title = "steamcmd +run_app_build (app " + *appId + ")";
    const std::string appVdf = generic(c.workDir / ("app_build_" + *appId + ".vdf"));
    std::string depotLines;
    for (const Folder& f : c.folders) {
        auto depot = s.depots.find(f.platform);
        if (depot == s.depots.end())
            return err("steam: no depot id for " + f.platform + " (factoria.json#/publish/steam/depots/" + f.platform + " is not set)",
                       pointer_hint("a depot per platform", "\"depots\": {\"windows\": 1234561, \"macos\": 1234562, \"linux\": 1234563}") +
                           " Depots are created in the Steamworks partner site (App Admin > SteamPipe > Depots).");
        const std::string depotId = std::to_string(depot->second);
        const std::string file = "depot_build_" + depotId + ".vdf";
        depotLines += "\t\t\"" + depotId + "\" \"" + file + "\"\n";
        std::string vdf = "\"DepotBuild\"\n{\n\t\"DepotID\" \"" + depotId + "\"\n\t\"ContentRoot\" \"" + tab_value(generic(f.path)) + "\"\n"
                          "\t\"FileMapping\"\n\t{\n\t\t\"LocalPath\" \"*\"\n\t\t\"DepotPath\" \".\"\n\t\t\"Recursive\" \"1\"\n\t}\n";
        for (const std::string& x : excluded_files()) vdf += "\t\"FileExclusion\" \"" + x + "\"\n";
        vdf += "}\n";
        depotFiles.push_back({c.workDir / file, vdf});
        job.uploads.push_back({f.platform, "Steam app " + *appId + ", depot " + depotId + " (" + f.platform + ")"});
        launchText += (launchText.empty() ? "" : "; ") + f.platform + ": " + (f.platform == "macos" ? c.safeName + ".app" : f.launch);
    }
    std::string app = "\"AppBuild\"\n{\n\t\"AppID\" \"" + *appId + "\"\n\t\"Desc\" \"" + tab_value(c.name + " " + c.version) + "\"\n"
                      "\t\"ContentRoot\" \"" + generic(c.workDir) + "\"\n\t\"BuildOutput\" \"" + generic(c.workDir / "output") + "\"\n";
    if (!branch.empty()) app += "\t\"SetLive\" \"" + tab_value(branch) + "\"\n";
    app += "\t\"Depots\"\n\t{\n" + depotLines + "\t}\n}\n";
    job.files.push_back({c.workDir / ("app_build_" + *appId + ".vdf"), app});
    job.files.insert(job.files.end(), depotFiles.begin(), depotFiles.end());

    job.argv = {"", "+login", account, "+run_app_build", appVdf, "+quit"};
    job.shown = job.argv;
    job.failureHint = "steamcmd keeps its login: if it says the login was denied or asks for a Steam Guard code, run `steamcmd +login " + account +
                      "` once in a terminal, enter the password and the code (set_steam_guard_code <code>), then publish again. The build log is in " +
                      generic(c.workDir / "output") + ".";
    if (branch.empty())
        c.nextSteps.push_back("The build is uploaded but not live: in the Steamworks partner site (App Admin > SteamPipe > Builds) put it on a branch, or pass \"branch\": \"beta\" next time to set it live on that beta branch.");
    else
        c.nextSteps.push_back("The build is live on the '" + branch + "' beta branch. Making it the default branch is done by hand in the Steamworks partner site (App Admin > SteamPipe > Builds).");
    c.nextSteps.push_back("First upload of a depot? Set the launch options in the Steamworks partner site (App Admin > Installation > General): " + launchText +
                          ". Steam keeps a file's executable bit only from a macOS or Linux machine: upload those depots from that OS (an export made on Windows has no executable bit to keep).");
    return std::vector<Job>{std::move(job)};
}

// ---- itch.io -----------------------------------------------------------------------------------------------

bool always_configured(const PublishSettings&, const std::string&) { return true; }

// butler's saved login (https://itch.io/docs/butler/login.html).
bool butler_login_exists(const Context& c) {
    const std::string profile = !env_of(c, "USERPROFILE").empty() ? env_of(c, "USERPROFILE") : env_of(c, "HOME");
    if (profile.empty()) return false;
#if defined(__APPLE__)
    return is_file(stdfs::path(profile) / "Library" / "Application Support" / "itch" / "butler_creds");
#else
    return is_file(stdfs::path(profile) / ".config" / "itch" / "butler_creds");
#endif
}

Result<std::vector<Job>> plan_itch(Context& c) {
    ItchPublishSettings s = c.settings.itch;
    if (s.game.empty()) {
        if (auto e = dry_missing(c, err("itch: factoria.json#/publish/itch/game is not set",
                   pointer_hint("your itch.io page", "\"publish\": {\"itch\": {\"game\": \"mystudio/space-dodge\"}}") +
                       " That is the user and the page name of your game's address (mystudio.itch.io/space-dodge), in lower case. Create the page on itch.io first.")))
            return *e;
        s.game = "MISSING_USER/MISSING_GAME";
    }
    std::vector<std::string> secrets;
    if (const std::string key = env_of(c, "BUTLER_API_KEY"); !key.empty()) secrets.push_back(key);
    else if (!butler_login_exists(c))
        c.warnings.push_back("Neither BUTLER_API_KEY is set nor a butler login was found: butler cannot sign in and the upload will fail. Run `butler login` once, or set BUTLER_API_KEY "
                             "(an API key from itch.io > Settings > API keys, which is secret).");
    std::vector<Job> jobs;
    for (const Folder& f : c.folders) {
        const std::string target = s.game + ":" + itch_channel_for(s, f.platform);
        Job job;
        job.title = "butler push " + f.platform;
        job.argv = {"", "push", generic(f.path), target, "--userversion", c.version};
        for (const std::string& x : excluded_files()) job.argv.insert(job.argv.end(), {"--ignore", x});
        job.shown = job.argv;
        job.uploads.push_back({f.platform, "itch.io " + target + " (version " + c.version + ")"});
        job.secrets = secrets;
        job.failureHint = "butler needs a login: run `butler login` once, or set BUTLER_API_KEY (itch.io > Settings > API keys). A 'game not found' error means the page " + s.game +
                          " does not exist or belongs to another account.";
        jobs.push_back(std::move(job));
    }
    c.nextSteps.push_back("A channel makes a download file on the game's page the first time; check them (and tick the platform tags) on the page's Edit game screen at itch.io.");
    return jobs;
}

// ---- Epic Games Store ----------------------------------------------------------------------------------------

bool epic_configured(const PublishSettings& s, const std::string& platform) { return s.epic.artifacts.count(platform) > 0; }

Result<std::vector<Job>> plan_epic(Context& c) {
    EpicPublishSettings s = c.settings.epic;
    std::vector<std::string> missing;
    if (s.organizationId.empty()) missing.push_back("organizationId");
    if (s.productId.empty()) missing.push_back("productId");
    if (s.clientId.empty()) missing.push_back("clientId");
    if (!missing.empty()) {
        if (auto e = dry_missing(c, err("epic: factoria.json#/publish/epic has no " + join(missing, ", "),
                   pointer_hint("the ids of the Epic Games Dev Portal", "\"publish\": {\"epic\": {\"organizationId\": \"o-...\", \"productId\": \"...\", \"clientId\": \"...\", "
                                "\"artifacts\": {\"windows\": \"<artifact id>\"}}}") +
                       " The client is the Build Patch Tool credential of Product Settings; its secret goes in " + kEpicSecretVar + ".")))
            return *e;
        if (s.organizationId.empty()) s.organizationId = "MISSING_ORGANIZATION_ID";
        if (s.productId.empty()) s.productId = "MISSING_PRODUCT_ID";
        if (s.clientId.empty()) s.clientId = "MISSING_CLIENT_ID";
    }
    std::string secret = env_of(c, kEpicSecretVar);
    if (secret.empty()) {
        if (auto e = dry_missing(c, err(std::string("epic: the client secret is not set: ") + kEpicSecretVar + " is empty",
                   std::string("Set the environment variable ") + kEpicSecretVar + " to the client secret of your Build Patch Tool credential (Dev Portal > Product Settings > General). "
                   "It is passed to the tool by name (-ClientSecretEnvVar), so it never appears on a command line or in a log.")))
            return *e;
        secret = "MISSING_CLIENT_SECRET";
    }
    static const std::regex versionRe("^[A-Za-z0-9.+_-]{1,100}$");
    if (!std::regex_match(c.version, versionRe))
        return err("epic: the version '" + c.version + "' of factoria.json cannot be an Epic BuildVersion",
                   "Epic accepts 1 to 100 characters from a-z, A-Z, 0-9 and . + - _ (no spaces), and each version can be uploaded once per artifact: change \"version\" to e.g. \"1.0.1\".");

    const stdfs::path ignoreFile = c.workDir / "ignore.txt";
    std::string ignore;
    for (const std::string& x : excluded_files()) ignore += x + "\n";
    std::vector<Job> jobs;
    for (const Folder& f : c.folders) {
        auto artifact = s.artifacts.find(f.platform);
        if (artifact == s.artifacts.end())
            return err("epic: no artifact id for " + f.platform + " (factoria.json#/publish/epic/artifacts/" + f.platform + " is not set)",
                       pointer_hint("an artifact per platform", "\"artifacts\": {\"windows\": \"<artifact id>\"}") +
                           " Artifacts are made in the Dev Portal (Artifacts and Binaries); each platform has its own.");
        Job job;
        job.title = "BuildPatchTool UploadBinary " + f.platform;
        job.argv = {"",
                    "-OrganizationId=" + s.organizationId,
                    "-ProductId=" + s.productId,
                    "-ArtifactId=" + artifact->second,
                    "-ClientId=" + s.clientId,
                    std::string("-ClientSecretEnvVar=") + kEpicSecretVar,
                    "-mode=UploadBinary",
                    "-BuildRoot=" + generic(f.path),
                    "-CloudDir=" + generic(c.workDir / "cloud" / f.platform),
                    "-BuildVersion=" + c.version,
                    "-AppLaunch=" + f.launch,
                    "-AppArgs=",
                    "-FileIgnoreList=" + generic(ignoreFile)};
        job.shown = job.argv;
        job.env[kEpicSecretVar] = secret;
        job.secrets = {secret};
        job.dirs.push_back(c.workDir / "cloud" / f.platform);
        job.files.push_back({ignoreFile, ignore});
        job.uploads.push_back({f.platform, "Epic artifact " + artifact->second + " (build " + c.version + ")"});
        job.failureHint = "Check the client id and that " + std::string(kEpicSecretVar) + " is the secret of the same Build Patch Tool credential (not an SDK credential). Each BuildVersion can be "
                          "uploaded once per artifact: raise \"version\" in factoria.json after an upload. -BuildRoot and -CloudDir must be different folders.";
        jobs.push_back(std::move(job));
    }
    c.nextSteps.push_back("An uploaded build is not on sale yet: in the Dev Portal assign it to the artifact's platform label and publish the product (Epic's review applies).");
    return jobs;
}

// ---- GOG --------------------------------------------------------------------------------------------------

Result<std::vector<Job>> plan_gog(Context& c) {
    GogPublishSettings s = c.settings.gog;
    if (s.productId.empty()) {
        if (auto e = dry_missing(c, err("gog: factoria.json#/publish/gog/productId is not set",
                   pointer_hint("the product id of your game", "\"publish\": {\"gog\": {\"productId\": \"1234567890\"}}") +
                       " It is in the GOG Developer Portal (your game > Product details).")))
            return *e;
        s.productId = "MISSING_PRODUCT_ID";
    }
    if (to_lower(c.options.branch) == "master")
        return err("gog: Pipeline Builder cannot publish to the Master branch",
                   "Upload to a private branch (\"branch\": \"<name>\"), or none, and publish the build from the GOG Developer Portal (Builds & Branches).");
    const std::string user = env_of(c, kGogUserVar), password = env_of(c, kGogPasswordVar);
    if (user.empty() != password.empty())
        return err(std::string("gog: ") + (user.empty() ? kGogPasswordVar : kGogUserVar) + " is set but " + (user.empty() ? kGogUserVar : kGogPasswordVar) + " is not",
                   std::string("Set both, or neither to use the credentials Pipeline Builder cached when you last signed in (run GOGGalaxyPipelineBuilder once, interactively, to cache them)."));
    if (user.empty())
        c.warnings.push_back(std::string("Neither ") + kGogUserVar + " nor " + kGogPasswordVar + " is set: Pipeline Builder uses the credentials it cached from an earlier sign-in, "
                             "and fails when there are none. Sign in once by running it by hand, or set both variables (the password then shows on the command line of the process while it runs).");

    const stdfs::path ignoreFile = c.workDir / "ignore.txt";
    std::string ignore;
    for (const std::string& x : excluded_files()) ignore += x + "\n";
    std::vector<Job> jobs;
    for (const Folder& f : c.folders) {
        const std::string platform = f.platform == "macos" ? "osx" : f.platform;
        Json task = Json::object({{"category", "game"}, {"isPrimary", true}, {"languages", s.languages}, {"name", c.name},
                                  {"path", f.platform == "macos" ? c.safeName + ".app" : f.launch}, {"type", "FileTask"}});
        if (f.platform == "windows") task["osBitness"] = Json::array({"64"});
        Json depot = Json::object({{"folder", generic(f.path)}, {"languages", s.languages}, {"name", c.slug + "-" + c.version + "-" + f.platform}});
        Json product = Json::object({{"name", c.name}, {"productId", s.productId}, {"depots", Json::array({depot})}, {"tasks", Json::array({task})}});
        Json project = Json::object({{"baseProductId", s.productId}, {"clientId", s.clientId}, {"clientSecret", ""}, {"installDirectory", c.safeName},
                                     {"name", c.name}, {"platform", platform}, {"version", ""}, {"scriptInterpreter", true},
                                     {"dependencies", Json::array()}, {"products", Json::array({product})}});
        const stdfs::path projectFile = c.workDir / ("gog-" + f.platform + ".json");

        Job job;
        job.title = "GOGGalaxyPipelineBuilder build-game " + f.platform;
        job.argv = {"", "build-game", generic(projectFile), "--ignore_list", generic(ignoreFile), "--version", c.version};
        if (!c.options.branch.empty()) job.argv.insert(job.argv.end(), {"--branch", c.options.branch});
        job.shown = job.argv;
        if (!user.empty()) {
            job.argv.insert(job.argv.end(), {"--username", user, "--password", password});
            job.shown.insert(job.shown.end(), {"--username", user, "--password", kRedacted});
            job.secrets = {password};
        }
        job.files.push_back({projectFile, dump_json(Json::object({{"project", project}}))});
        job.files.push_back({ignoreFile, ignore});
        job.uploads.push_back({f.platform, "GOG product " + s.productId + " (" + platform + ", version " + c.version + (c.options.branch.empty() ? "" : ", branch " + c.options.branch) + ")"});
        job.failureHint = "Pipeline Builder signs in with the cached credentials, or with " + std::string(kGogUserVar) + " and " + kGogPasswordVar + ". Its own log: run it again with --log_level=debug "
                          "(logs go to the __gog/logs folder of your temp folder).";
        jobs.push_back(std::move(job));
    }
    c.nextSteps.push_back("An uploaded build is not live yet: publish it from the GOG Developer Portal (your game > Builds & Branches), or with GOGGalaxyPipelineBuilder publish-build.");
    return jobs;
}

// ---- App Store Connect (TestFlight) ----------------------------------------------------------------------------

// The App Store Connect API key (a Team Key with the App Manager role): the .p8 file and its two ids. The notarization
// variables of sign.macos work too, so a Mac set up for one is set up for both.
const char* const kAppStoreKeyVar = "FACTORIA_APPSTORE_API_KEY";
const char* const kAppStoreKeyIdVar = "FACTORIA_APPSTORE_API_KEY_ID";
const char* const kAppStoreIssuerVar = "FACTORIA_APPSTORE_API_ISSUER";

std::string env_first(const Context& c, const char* a, const char* b) {
    const std::string v = env_of(c, a);
    return v.empty() ? env_of(c, b) : v;
}

Result<std::vector<Job>> plan_appstore(Context& c) {
    AppStorePublishSettings s = c.settings.appstore;
    if (s.appleId.empty()) {
        if (auto e = dry_missing(c, err("appstore: factoria.json#/publish/appstore/appleId is not set",
                   pointer_hint("the Apple ID of your app", "\"publish\": {\"appstore\": {\"appleId\": \"6448277777\"}}") +
                       " It is the number under App Store Connect > your app > App Information > General Information > Apple ID. Create the app there first (My Apps > +) "
                       "with the bundle id " + (c.bundleId.empty() ? std::string("of your game") : c.bundleId) + ".")))
            return *e;
        s.appleId = "MISSING_APPLE_ID";
    }
    if (c.bundleId.empty()) {
        if (auto e = dry_missing(c, err("appstore: factoria.json#/id is not set", "Add \"id\": \"com.mystudio.mygame\" (the bundle id of the app in App Store Connect) to factoria.json.")))
            return *e;
        c.bundleId = "MISSING.BUNDLE.ID";
    }
    static const std::regex versionRe("^[0-9]+(\\.[0-9]+){0,2}$");
    if (!std::regex_match(c.version, versionRe))
        return err("appstore: the version '" + c.version + "' of factoria.json cannot be an iOS version (CFBundleShortVersionString)",
                   "Apple takes one to three numbers separated by dots, e.g. \"1.2.3\": change \"version\" in factoria.json and export the game for iOS again.");

    std::string keyPath = env_first(c, kAppStoreKeyVar, "FACTORIA_NOTARY_API_KEY");
    std::string keyId = env_first(c, kAppStoreKeyIdVar, "FACTORIA_NOTARY_API_KEY_ID");
    std::string issuer = env_first(c, kAppStoreIssuerVar, "FACTORIA_NOTARY_API_ISSUER");
    std::vector<std::string> missing;
    if (keyPath.empty()) missing.push_back(std::string(kAppStoreKeyVar) + " (the path of the .p8 file)");
    if (keyId.empty()) missing.push_back(std::string(kAppStoreKeyIdVar) + " (the Key ID)");
    if (issuer.empty()) missing.push_back(std::string(kAppStoreIssuerVar) + " (the Issuer ID)");
    const bool keyMissing = !missing.empty();
    if (keyMissing) {
        if (auto e = dry_missing(c, err("appstore: the App Store Connect API key is not set: " + join(missing, ", "),
                   "Create a key in App Store Connect > Users and Access > Integrations > App Store Connect API (Team Keys, role App Manager), download the AuthKey_<KeyID>.p8 "
                   "(Apple lets you download it once) and set these variables. The Issuer ID is on the same page. The key is a file outside the project; nothing of it is written to the project or shown.")))
            return *e;
        if (keyPath.empty()) keyPath = "MISSING_KEY_PATH/AuthKey_MISSING.p8";
        if (keyId.empty()) keyId = "MISSING";
        if (issuer.empty()) issuer = "MISSING_ISSUER_ID";
    }
    const stdfs::path key(tooling_detail::expand_home(keyPath, c.options.env));
    if (!keyMissing && !is_file(key))
        return err("appstore: " + std::string(kAppStoreKeyVar) + " is '" + keyPath + "', which is not a file", "Set it to the path of the AuthKey_" + keyId + ".p8 you downloaded from App Store Connect.");
    if (!keyMissing && key.filename().string() != "AuthKey_" + keyId + ".p8")
        return err("appstore: the key file is named '" + key.filename().string() + "', but altool finds a key by the name AuthKey_" + keyId + ".p8",
                   "Keep the name Apple gave the file (AuthKey_<KeyID>.p8) or rename it to AuthKey_" + keyId + ".p8; " + kAppStoreKeyIdVar + " is its Key ID.");

    Job job;
    job.title = "xcrun altool --upload-package (app " + s.appleId + ")";
    job.argv = {"", "altool", "--upload-package", generic(c.artifact), "--type", "ios", "--apple-id", s.appleId, "--bundle-id", c.bundleId,
                "--bundle-version", c.iosBuild, "--bundle-short-version-string", c.version, "--apiKey", keyId, "--apiIssuer", issuer};
    job.shown = job.argv;
    job.env["API_PRIVATE_KEYS_DIR"] = generic(key.parent_path());  // where altool looks for AuthKey_<KeyID>.p8
    job.uploads.push_back({"ios", "App Store Connect app " + s.appleId + " (" + c.bundleId + "), version " + c.version + " build " + c.iosBuild});
    job.failureHint = "altool reports the reason in its output: 'Unable to authenticate' means a wrong Key ID/Issuer ID or a key without the App Manager role; a bundle id or version that does not match "
                      "the .ipa means the .ipa was built from other settings (export again and archive again); 'build number already used' means raise export.ios.buildNumber, export, archive and upload again.";
    c.warnings.push_back("altool checks --bundle-id, --bundle-version and --bundle-short-version-string against the .ipa: they are read from factoria.json (id " + c.bundleId + ", version " + c.version +
                         ", export.ios.buildNumber " + c.iosBuild + "), so the .ipa must come from an iOS export made with the same factoria.json.");
    c.nextSteps.push_back("App Store Connect now processes the build (a few minutes to an hour; it e-mails you if it is rejected). When it shows under App Store Connect > your app > TestFlight, add it to a "
                          "tester group; to submit it for review pick it on the version page of the App Store tab.");
    c.nextSteps.push_back("App Store Connect takes each build number once per version: raise export.ios.buildNumber in factoria.json before the next export and archive.");
    return std::vector<Job>{std::move(job)};
}

// ---- Google Play -------------------------------------------------------------------------------------------------

const char* const kPlayKeyVar = "FACTORIA_GOOGLEPLAY_JSON_KEY";

Result<std::vector<Job>> plan_googleplay(Context& c) {
    const GooglePlayPublishSettings& s = c.settings.googleplay;
    if (c.bundleId.empty()) {
        if (auto e = dry_missing(c, err("googleplay: factoria.json#/id is not set", "Add \"id\": \"com.mystudio.mygame\" (the package name of the app in the Play Console) to factoria.json.")))
            return *e;
        c.bundleId = "MISSING.PACKAGE.NAME";
    }
    const std::string track = !c.options.track.empty() ? c.options.track : s.track;
    static const std::regex trackRe("^[A-Za-z0-9_.-]{1,64}$");
    if (!std::regex_match(track, trackRe))
        return err("googleplay: '" + track + "' is not a track name", "Use internal, alpha, beta or production, or the name of a closed testing track (letters, digits and . _ - only).");
    const std::string status = !c.options.releaseStatus.empty() ? c.options.releaseStatus : s.releaseStatus;
    if (status != "draft" && status != "completed")
        return err("googleplay: '" + status + "' is not a release status",
                   did_you_mean(status, std::vector<std::string>{"draft", "completed"}) + " draft waits in the Play Console until you roll it out; completed rolls out right away.");

    // The bundle must be signed with an upload key of yours: a debug-signed one is refused by Google Play.
    const std::string file = c.artifact.filename().string();
    if (file.ends_with("-debug.aab"))
        return err("googleplay: " + file + " is a debug build, signed with the debug key, which Google Play rejects",
                   "Create a keystore (the editor's Platform settings > Android > Create keystore..., or keytool -genkeypair), set export.android.signing.keystore and .alias in factoria.json, "
                   "and build the release bundle: factoria export --platform android --format aab --release. See docs/MOBILE.md, \"Signing and release\".");
    if (!c.androidKeystore) {
        if (!c.artifactGiven)
            return err("googleplay: factoria.json#/export/android/signing/keystore is not set, so " + file + " is signed with the debug key, which Google Play rejects",
                       "Create a keystore (the editor's Platform settings > Android > Create keystore..., or keytool -genkeypair), set export.android.signing.keystore and .alias in factoria.json, "
                       "and build the release bundle again: factoria export --platform android --format aab --release. (A bundle you signed yourself: pass it as `artifact`.)");
        c.warnings.push_back("export.android.signing has no keystore in factoria.json, so FactorIA cannot tell how " + file + " was signed: Google Play rejects a bundle signed with the debug key.");
    }

    std::string keyValue = env_first(c, kPlayKeyVar, "SUPPLY_JSON_KEY");
    const bool keyMissing = keyValue.empty();
    if (keyMissing) {
        if (auto e = dry_missing(c, err(std::string("googleplay: the service account key is not set: ") + kPlayKeyVar + " is empty",
                   std::string("Create a service account in Google Cloud, give it access in the Play Console (Users and permissions > Invite new users, with permission to release to the track), "
                               "create a JSON key for it, and set ") + kPlayKeyVar + " to the path of that file (outside the project; it is a secret and is never written or shown).")))
            return *e;
        keyValue = "MISSING_KEY.json";
    }
    const stdfs::path key(tooling_detail::expand_home(keyValue, c.options.env));
    if (!keyMissing && !is_file(key))
        return err(std::string("googleplay: ") + kPlayKeyVar + " is '" + keyValue + "', which is not a file", "Set it to the path of the service account's JSON key.");
    auto keyJson = keyMissing ? Result<Json>(Json::object({{"type", "service_account"}})) : parse_json(tooling_detail::read_file(key).value_or(""), generic(key));
    if (!keyJson.ok() || !keyJson->is_object() || keyJson->value("type", std::string()) != "service_account")
        return err("googleplay: " + generic(key) + " is not a service account key (its \"type\" must be \"service_account\")",
                   "Google Cloud console > IAM > Service accounts > your account > Keys > Add key > JSON. A client secret or an OAuth file does not work.");

    Job job;
    job.title = "fastlane supply (" + c.bundleId + ", track " + track + ")";
    job.argv = {"", "supply", "--aab", generic(c.artifact), "--track", track, "--release_status", status, "--package_name", c.bundleId, "--json_key", generic(key),
                "--skip_upload_apk", "true", "--skip_upload_metadata", "true", "--skip_upload_images", "true", "--skip_upload_screenshots", "true"};
    if (s.changelogs.empty()) {
        job.argv.insert(job.argv.end(), {"--skip_upload_changelogs", "true"});
    } else {
        // supply reads <metadata_path>/<locale>/changelogs/default.txt. Rewritten (and emptied first) on every call.
        const stdfs::path metadata = c.workDir / "metadata";
        job.clearDirs.push_back(metadata);
        for (const auto& [locale, rel] : s.changelogs) {
            auto path = resolve_project_path(generic(c.projectDir), rel);
            const std::string where = "factoria.json#/publish/googleplay/changelogs/" + locale;
            if (!path.ok()) return err("googleplay: " + where + ": " + path.error().message, path.error().hint);
            auto text = tooling_detail::read_file(*path);
            if (!text) return err("googleplay: " + where + ": the file '" + rel + "' does not exist", "Write the release notes for " + locale + " in that file (up to 500 characters, plain text).");
            const std::string notes(trim(*text));
            if (notes.empty() || utf8_length(notes) > 500)
                return err("googleplay: " + where + ": '" + rel + "' has " + std::to_string(utf8_length(notes)) + " characters",
                           "Google Play takes release notes of 1 to 500 characters per language: shorten the text of that file.");
            job.files.push_back({metadata / locale / "changelogs" / "default.txt", notes});
        }
        job.argv.insert(job.argv.end(), {"--metadata_path", generic(metadata)});
    }
    job.shown = job.argv;
    job.uploads.push_back({"android", "Google Play " + c.bundleId + ", track " + track + " (" + status + ", version code " + std::to_string(c.androidVersionCode) + ")"});
    job.failureHint = "Typical causes: 'Package not found' - the first bundle of an app must be uploaded by hand in the Play Console; 'The caller does not have permission' - the service account needs access "
                      "to the app (Play Console > Users and permissions) and the Google Play Android Developer API enabled in its Google Cloud project; 'Version code N has already been used' - raise "
                      "version (or export.android.versionCode) in factoria.json and export the bundle again; 'Only releases with status draft may be created on draft app' - use releaseStatus draft until the app is published.";
    if (track == "production" && status == "completed")
        c.warnings.push_back("This puts the bundle on the production track and rolls it out to everyone right away. Use releaseStatus draft to review it in the Play Console first.");
    c.nextSteps.push_back(status == "draft"
                              ? "The release is a draft: open Play Console > your app > Testing/Release > " + track + ", check it and roll it out."
                              : "The release is rolling out on the '" + track + "' track; follow it in Play Console > your app > Release.");
    c.nextSteps.push_back("Google Play takes each version code once: raise \"version\" (or export.android.versionCode) in factoria.json before the next release export.");
    return std::vector<Job>{std::move(job)};
}

}  // namespace

const Store* find_store(const std::string& name) {
    static const std::vector<Store> stores = [] {
        std::vector<Store> v;
        v.push_back({"steam", "steamcmd", "FACTORIA_STEAMCMD", "steamcmd", {"steamcmd", "steamcmd.sh"},
                     "https://developer.valvesoftware.com/wiki/SteamCMD (Steamworks: https://partner.steamgames.com/doc/sdk/uploading)", false, steam_configured, plan_steam});
        v.push_back({"itch", "butler", "FACTORIA_BUTLER", "butler", {"butler"}, "https://itch.io/docs/butler/installing.html", false, always_configured, plan_itch});
        v.push_back({"epic", "BuildPatchTool", "FACTORIA_BUILDPATCHTOOL", "buildPatchTool", {"BuildPatchTool"},
                     "https://dev.epicgames.com/docs/epic-games-store/publishing-tools/uploading-binaries/bpt-instructions-160 (the zip is "
                     "https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/BuildPatchTool.zip)",
                     true, epic_configured, plan_epic});
        v.push_back({"gog", "GOGGalaxyPipelineBuilder", "FACTORIA_GOG_PIPELINE_BUILDER", "galaxyPipelineBuilder", {"GOGGalaxyPipelineBuilder"},
                     "https://docs.gog.com/pb-quick-start/ (the GOG Developer Portal > GALAXY Components > Pipeline Builder)", true, always_configured, plan_gog});
        Store appstore{"appstore", "xcrun", "FACTORIA_XCRUN", "xcrun", {"xcrun"},
                       "Xcode: install it from the Mac App Store, then run `xcode-select --install` (https://developer.apple.com/xcode/); xcrun and altool come with it",
                       false, always_configured, plan_appstore};
        appstore.mobile = "ios";
        appstore.macOnly = true;
        v.push_back(appstore);
        Store googleplay{"googleplay", "fastlane", "FACTORIA_FASTLANE", "fastlane", {"fastlane"},
                         "https://docs.fastlane.tools/getting-started/android/setup/ (gem install fastlane, or brew install fastlane)", false, always_configured, plan_googleplay};
        googleplay.mobile = "android";
        v.push_back(googleplay);
        return v;
    }();
    for (const Store& s : stores)
        if (s.name == name) return &s;
    return nullptr;
}

}  // namespace fa::publish_detail
