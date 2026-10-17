// platform.add_backend {"backend": "steam"}: the Steamworks backend (docs/PLATFORM.md, "Steam"). It creates the plugin from
// platforms/plugins/steam, builds it for this computer, copies Valve's redistributable libraries from the Steamworks SDK next to
// it (for Windows, macOS and Linux), and writes steam_appid.txt for development (Valve's test app 480 unless told otherwise).
// The plugin itself holds no Valve code (platforms/plugins/steam/README.md).
#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <optional>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/runtime/plugins.h"
#include "platform_setup.h"
#include "setup_internal.h"

namespace fa::platform_setup {

namespace stdfs = std::filesystem;

namespace {

constexpr const char* kSdkPage = "partner.steamgames.com/downloads/list";
constexpr unsigned kTestAppId = 480;  // Valve's Spacewar: any Steam account can run it

// Where each platform's redistributable is in the SDK, and where it goes next to the plugin.
struct Redistributable {
    const char* platform;
    const char* inSdk;  // under redistributable_bin/
    const char* file;   // the file name next to the plugin (what the plugin looks for)
};
const Redistributable kRedistributables[] = {{"windows", "win64/steam_api64.dll", "steam_api64.dll"},
                                             {"macos", "osx/libsteam_api.dylib", "libsteam_api.dylib"},
                                             {"linux", "linux64/libsteam_api.so", "libsteam_api.so"}};

bool is_dir(const stdfs::path& p) {
    std::error_code ec;
    return stdfs::is_directory(p, ec);
}
bool is_file(const stdfs::path& p) {
    std::error_code ec;
    return stdfs::is_regular_file(p, ec);
}

stdfs::path expand_path(const std::string& text, const std::string& projectDir) {
    std::string t = text;
    if (t.rfind("~/", 0) == 0 || t == "~") {
        const char* home = std::getenv("HOME");
        if (!home || !*home) home = std::getenv("USERPROFILE");
        if (home && *home) t = std::string(home) + t.substr(1);
    }
    stdfs::path p(t);
    return p.is_absolute() ? p : stdfs::path(projectDir) / p;
}

// The app id as a number; 0 when it is not one.
unsigned parse_app_id(const Json& v) {
    if (v.is_number_integer() || v.is_number_unsigned()) {
        const long long n = v.get<long long>();
        return n >= 1 && n <= 4294967295LL ? static_cast<unsigned>(n) : 0;
    }
    if (v.is_string()) {
        const std::string s = v.get<std::string>();
        if (s.empty() || s.size() > 10 || !std::all_of(s.begin(), s.end(), [](char c) { return c >= '0' && c <= '9'; })) return 0;
        const long long n = std::stoll(s);
        return n >= 1 && n <= 4294967295LL ? static_cast<unsigned>(n) : 0;
    }
    return 0;
}

// The number in a steam_appid.txt, or "".
std::string read_app_id(const stdfs::path& file) {
    std::ifstream in(file, std::ios::binary);
    const std::string text((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    std::string number;
    for (char c : text) {
        if (c >= '0' && c <= '9') number += c;
        else if (!number.empty()) break;
    }
    return number;
}

// The unpacked SDK's redistributable_bin folder: `base` may be the SDK folder (the one with redistributable_bin/ and public/),
// the folder that holds it (steamworks_sdk_162.zip unpacks to sdk/), or redistributable_bin itself.
std::optional<stdfs::path> find_redistributable_bin(const stdfs::path& base) {
    const stdfs::path child = setup_detail::single_child_dir(base);
    for (const stdfs::path& c : {base, base / "sdk", child, child / "sdk"})
        if (is_dir(c / "redistributable_bin")) return c / "redistributable_bin";
    if (is_dir(base / "win64") || is_dir(base / "osx") || is_dir(base / "linux64")) return base;
    return std::nullopt;
}

// A temporary folder the SDK zip is unpacked into, removed at the end.
struct Scratch {
    stdfs::path dir;
    ~Scratch() {
        if (dir.empty()) return;
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
};

std::string lower(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    return s;
}

const std::string kSdkHelp = std::string("The Steamworks SDK is a download of Valve's (") + kSdkPage + ", needs a free Steamworks account); "
                             "its license does not let FactorIA ship the files. Pass the .zip or the unpacked folder as \"sdk\".";

// Resolves the "sdk" argument to the redistributable_bin folder (unpacking a zip into `scratch`), or throws a teaching error.
stdfs::path resolve_sdk(const std::string& sdk, const std::string& projectDir, Scratch& scratch) {
    const stdfs::path path = expand_path(sdk, projectDir);
    std::error_code ec;
    if (!stdfs::exists(path, ec))
        throw CommandError("not_found", "the Steamworks SDK '" + path.generic_string() + "' does not exist", kSdkHelp);
    stdfs::path base = path;
    if (is_file(path)) {
        if (lower(path.extension().string()) != ".zip")
            throw CommandError("invalid_argument", "the Steamworks SDK '" + path.generic_string() + "' is a file, but not a .zip", kSdkHelp);
        scratch.dir = fs::make_temp_dir("fa_steam_sdk");
        if (auto fail = setup_detail::extract_archive(fa::SetupContext{}, path, scratch.dir))
            throw CommandError(fail->code, "cannot unpack the Steamworks SDK " + path.generic_string() + ": " + fail->error.message,
                               fail->error.hint.empty() ? "Unpack the .zip yourself and pass the folder as \"sdk\"." : fail->error.hint);
        base = scratch.dir;
    }
    if (auto bin = find_redistributable_bin(base)) return *bin;
    throw CommandError("invalid_argument",
                       "'" + path.generic_string() + "' is not a Steamworks SDK: it has no redistributable_bin/ folder (with win64/, osx/ and linux64/)",
                       kSdkHelp + " The SDK folder holds public/, redistributable_bin/ and sdk_licenses/.");
}

// Writes steam_appid.txt unless the project has one (and `appId` was not asked for): returns the id the file holds.
unsigned write_app_id(Context& ctx, unsigned wanted, bool asked) {
    const stdfs::path file = stdfs::path(ctx.projectDir) / "steam_appid.txt";
    if (is_file(file)) {
        const std::string current = read_app_id(file);
        if (!asked && !current.empty()) {
            ctx.done.push_back("kept steam_appid.txt (app id " + current + ")");
            return static_cast<unsigned>(std::stoul(current));
        }
        if (current == std::to_string(wanted)) {
            ctx.done.push_back("kept steam_appid.txt (app id " + current + ")");
            return wanted;
        }
    }
    std::ofstream out(file, std::ios::binary | std::ios::trunc);
    out << wanted << "\n";
    out.close();
    if (!out)
        throw CommandError("failed", "cannot write " + file.generic_string(), "Check that the project folder can be written to.");
    ctx.done.push_back("wrote steam_appid.txt with app id " + std::to_string(wanted) +
                       (wanted == kTestAppId ? " (Valve's test app Spacewar): for development only, `factoria export` never ships it" :
                                               ": for development only, `factoria export` never ships it"));
    return wanted;
}

}  // namespace

Backend steam_backend() {
    Backend b;
    b.name = "steam";
    b.summary = "the Steamworks plugin (achievements, stats, leaderboards, Cloud saves, DLC purchases, overlay, rich presence): "
                "writes it, builds it for this computer, copies Valve's redistributable libraries from the Steamworks SDK (\"sdk\": "
                "its folder or .zip) next to it for Windows, macOS and Linux, and writes steam_appid.txt (\"appId\", default "
                "Valve's test app 480) for development.";
    b.properties = Json::object({
        {"sdk", Json::object({{"type", "string"},
                              {"description", "(steam) The Steamworks SDK: its folder, or the steamworks_sdk_*.zip from partner.steamgames.com/downloads/"
                                              "list (a free Steamworks account). Valve's redistributable libraries are copied from it next to the plugin. "
                                              "Without it they are not copied: nextSteps says where to put them. Relative paths start in the project folder."}})},
        {"appId", Json::object({{"type", "integer"}, {"minimum", 1},
                                {"description", "(steam) Your game's Steam app id, written to steam_appid.txt for development. Without it "
                                                "an existing steam_appid.txt is kept, else the file gets 480, Valve's test app "
                                                "(Spacewar), which any Steam account can run."}})}});
    b.run = [](Context& ctx) {
        // Check everything that can be wrong before anything is written.
        const bool askedAppId = ctx.args.contains("appId") && !ctx.args["appId"].is_null();
        unsigned appId = kTestAppId;
        if (askedAppId) {
            appId = parse_app_id(ctx.args["appId"]);
            if (!appId)
                throw CommandError("invalid_argument", "\"appId\" " + ctx.args["appId"].dump() + " is not a Steam app id",
                                   "Use the number of your game from the Steamworks partner site, or 480 (Valve's test app) to try it.");
        }
        Scratch scratch;
        std::optional<stdfs::path> redistributableBin;
        if (ctx.args.contains("sdk") && ctx.args["sdk"].is_string() && !ctx.args["sdk"].get<std::string>().empty())
            redistributableBin = resolve_sdk(ctx.args["sdk"].get<std::string>(), ctx.projectDir, scratch);
        const std::string host = runtime_platform();
        if (redistributableBin)
            for (const Redistributable& r : kRedistributables)
                if (host == r.platform && !is_file(*redistributableBin / r.inSdk))
                    throw CommandError("not_found",
                                       "the Steamworks SDK (" + redistributableBin->parent_path().generic_string() + ") has no redistributable_bin/" +
                                           r.inSdk + ", the library this computer (" + host + ") needs",
                                       "Use the complete SDK download (this plugin was checked against Steamworks SDK 1.58 to 1.64): " + kSdkHelp);

        const std::string folder = ctx.ensure_plugin({"windows", "macos", "linux"});
        ctx.build_plugin(folder);

        // Valve's libraries next to the plugin, for every platform the SDK has: the export copies each platform's folder.
        std::vector<std::string> copied, absent;
        if (redistributableBin) {
            for (const Redistributable& r : kRedistributables) {
                const stdfs::path source = *redistributableBin / r.inSdk;
                if (!is_file(source)) {
                    absent.push_back(std::string("redistributable_bin/") + r.inSdk);
                    continue;
                }
                const stdfs::path destination = stdfs::path(folder) / r.platform / r.file;
                std::error_code ec;
                stdfs::create_directories(destination.parent_path(), ec);
                stdfs::copy_file(source, destination, stdfs::copy_options::overwrite_existing, ec);
                if (ec)
                    throw CommandError("failed", "cannot copy " + source.generic_string() + " to " + destination.generic_string() + ": " + ec.message(),
                                       "Check that the plugin's folder can be written to, and run platform.add_backend again.");
                copied.push_back(std::string(r.platform) + "/" + r.file);
            }
            ctx.done.push_back("copied Valve's redistributable libraries next to the plugin (" + join(copied, ", ") + ")");
        }
        bool hostLibrary = false;  // Valve's library for this computer is next to the plugin (copied now, or already there)
        for (const Redistributable& r : kRedistributables)
            if (host == r.platform) hostLibrary = is_file(stdfs::path(folder) / r.platform / r.file);

        appId = write_app_id(ctx, appId, askedAppId);

        ctx.extra["appId"] = appId;
        ctx.extra["steamAppIdFile"] = (stdfs::path(ctx.projectDir) / "steam_appid.txt").generic_string();
        ctx.extra["redistributables"] = Json(copied);

        // What only a person can do.
        if (!hostLibrary)
            ctx.nextSteps.push_back("Copy Valve's library for this computer next to the plugin: redistributable_bin/" +
                                    std::string(host == "windows" ? "win64/steam_api64.dll to " + folder + "/windows/"
                                                : host == "macos" ? "osx/libsteam_api.dylib to " + folder + "/macos/"
                                                                  : "linux64/libsteam_api.so to " + folder + "/linux/") +
                                    " from the Steamworks SDK (" + kSdkPage + ", a free Steamworks account), or run this command again with "
                                    "\"sdk\": \"<the SDK folder or .zip>\". Without it the game uses the fake store in development.");
        else if (!absent.empty())
            ctx.nextSteps.push_back("The SDK has no " + join(absent, ", ") + ": copy that library next to the plugin for that platform before exporting for it.");
        ctx.nextSteps.push_back(
            "Build the plugin on the other computers you export on (Windows, macOS, Linux): the same command there, or `cmake -S \"" + folder +
            "\" -B \"" + folder + "/build\" -DCMAKE_BUILD_TYPE=Release && cmake --build \"" + folder + "/build\" --config Release`. " +
            (copied.size() == 3 ? "Valve's libraries for all three are in place already." : "Put Valve's library for each platform next to it too."));
        if (appId == kTestAppId)
            ctx.nextSteps.push_back(
                "Try it with Valve's test app 480: start the Steam client and sign in, then `factoria run`. Map your catalog to what Spacewar has "
                "in factoria.json platform: achievement ids.steam \"ACH_WIN_ONE_GAME\", int stat ids.steam \"NumWins\", float stat \"FeetTraveled\", "
                "leaderboard \"Feet Traveled\". `factoria call steam.status` shows what the plugin found. The manual check is in docs/PLATFORM.md "
                "(\"Steam\").");
        else
            ctx.nextSteps.push_back(
                "Create your game's achievements, stats, leaderboards and DLC in the Steamworks partner site (partner.steamgames.com, App Admin) "
                "and publish them, then set ids.steam on each entry of factoria.json platform: the API name of the achievement, stat or "
                "leaderboard, and for a product the app id of its DLC. Start the Steam client with an account that owns app " +
                std::to_string(appId) + ", then `factoria run`.");
        ctx.nextSteps.push_back(
            "Ship it: `factoria export` copies the plugin and Valve's library next to the game and never copies steam_appid.txt. Upload the "
            "export with Steamworks' SteamPipe; a game started from the Steam client gets its app id from Steam. Consumables and "
            "subscriptions are not available on Steam (docs/PLATFORM.md, \"Steam\").");
    };
    return b;
}

}  // namespace fa::platform_setup
