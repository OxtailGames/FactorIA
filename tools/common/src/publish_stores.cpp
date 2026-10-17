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
//   GOG       https://docs.gog.com/pb-build-game/  (GOGGalaxyPipelineBuilder build-game <project.json> [--ignore_list F]
//             [--version V] [--branch B] [--username U --password P]; the project file format is the page's example)
#include <algorithm>
#include <regex>

#include "fa/core/strings.h"
#include "publish_internal.h"

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

std::string pointer_hint(const std::string& what, const std::string& example) {
    return "Add " + what + " to factoria.json, e.g. " + example + " (docs/EXPORTING.md, \"Uploading to stores\").";
}

// ---- Steam -------------------------------------------------------------------------------------------------

constexpr unsigned kSteamTestApp = 480;  // Valve's Spacewar

// The app id: the `appId` argument, else the number in steam_appid.txt, the one place the project keeps it (docs/PLATFORM.md).
Result<std::string> steam_app_id(const Context& c) {
    std::string text = c.options.appId, from = "the appId argument";
    if (text.empty()) {
        const stdfs::path file = c.projectDir / "steam_appid.txt";
        if (!is_file(file))
            return err("steam: the game has no Steam app id: there is no steam_appid.txt in " + generic(c.projectDir) + " and no appId argument",
                       "Your app id is the number in the Steamworks partner site (App Admin). Write it to steam_appid.txt with "
                       "platform.add_backend {\"backend\":\"steam\",\"appId\":<your id>} (the file is for development and never shipped), or pass \"appId\".");
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
    const std::string account = !c.options.account.empty() ? c.options.account : s.account;
    if (account.empty())
        return err("steam: no Steam account to upload with (factoria.json#/publish/steam/account is not set and there is no account argument)",
                   pointer_hint("the name of your Steam build account", "\"publish\": {\"steam\": {\"account\": \"mystudio_build\"}}") +
                       " Its password is never stored: run `steamcmd +login <account>` once to enter it (and the Steam Guard code); steamcmd keeps the login.");
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
    const ItchPublishSettings& s = c.settings.itch;
    if (s.game.empty())
        return err("itch: factoria.json#/publish/itch/game is not set",
                   pointer_hint("your itch.io page", "\"publish\": {\"itch\": {\"game\": \"mystudio/space-dodge\"}}") +
                       " That is the user and the page name of your game's address (mystudio.itch.io/space-dodge), in lower case. Create the page on itch.io first.");
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
    const EpicPublishSettings& s = c.settings.epic;
    std::vector<std::string> missing;
    if (s.organizationId.empty()) missing.push_back("organizationId");
    if (s.productId.empty()) missing.push_back("productId");
    if (s.clientId.empty()) missing.push_back("clientId");
    if (!missing.empty())
        return err("epic: factoria.json#/publish/epic has no " + join(missing, ", "),
                   pointer_hint("the ids of the Epic Games Dev Portal", "\"publish\": {\"epic\": {\"organizationId\": \"o-...\", \"productId\": \"...\", \"clientId\": \"...\", "
                                "\"artifacts\": {\"windows\": \"<artifact id>\"}}}") +
                       " The client is the Build Patch Tool credential of Product Settings; its secret goes in " + kEpicSecretVar + ".");
    const std::string secret = env_of(c, kEpicSecretVar);
    if (secret.empty())
        return err(std::string("epic: the client secret is not set: ") + kEpicSecretVar + " is empty",
                   std::string("Set the environment variable ") + kEpicSecretVar + " to the client secret of your Build Patch Tool credential (Dev Portal > Product Settings > General). "
                   "It is passed to the tool by name (-ClientSecretEnvVar), so it never appears on a command line or in a log.");
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
    const GogPublishSettings& s = c.settings.gog;
    if (s.productId.empty())
        return err("gog: factoria.json#/publish/gog/productId is not set",
                   pointer_hint("the product id of your game", "\"publish\": {\"gog\": {\"productId\": \"1234567890\"}}") +
                       " It is in the GOG Developer Portal (your game > Product details).");
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
        return v;
    }();
    for (const Store& s : stores)
        if (s.name == name) return &s;
    return nullptr;
}

}  // namespace fa::publish_detail
