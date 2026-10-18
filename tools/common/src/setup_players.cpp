// `setup players`: the factoria_player of the other desktop OSes and the prebuilt mobile libraries, from the GitHub
// release of this factoria's version (the same packages the editor's updater downloads).
//
//   <home>/players/<version>/<windows|linux|macos>/factoria_player[.exe]
//   <home>/players/<version>/mobile/   android/jniLibs/<abi>/libfactoria_player.so; ios/<sdk>/*.a
//   <home>/players/<version>/web/      factoria_player.js + factoria_player.wasm (the player of the web export)
//
// web/ is in every release package (next to factoria, like the Android libraries), so it is installed only when asked for
// (`--platforms web`), from the package of this machine's own OS.
//
// Both halves of mobile/ come from the macOS package, the only one that carries the iOS libraries (the Android ones are in
// every package): so an iOS project can be exported from Windows and Linux too, without --mobile-dir.
//
// A player must match the factoria that copies it into a game, which is why the folder carries the version.
#include <algorithm>
#include <fstream>

#include "fa/core/json.h"
#include "fa/core/strings.h"
#include "fa/tooling/export.h"
#include "setup_internal.h"
#include "util.h"

namespace fa::setup_detail {

namespace {

constexpr const char* kDesktopOses[] = {"windows", "linux", "macos"};
constexpr const char* kAndroidAbis[] = {"arm64-v8a", "x86_64"};
constexpr const char* kIosSlices[] = {"iphoneos", "iphonesimulator"};

std::string package_name(const std::string& os) {
    if (os == "windows") return "FactorIA-windows-x64.zip";
    if (os == "macos") return "FactorIA-macos-universal.tar.gz";
    return "FactorIA-linux-x64.tar.gz";
}

stdfs::path players_root(const SetupContext& ctx) { return stdfs::path(ctx.home_dir()) / "players" / ctx.version(); }

std::string player_file_name(const std::string& os) { return os == "windows" ? "factoria_player.exe" : "factoria_player"; }

stdfs::path player_path(const SetupContext& ctx, const std::string& os) { return players_root(ctx) / os / player_file_name(os); }

bool web_complete(const stdfs::path& web) { return is_file(web / "factoria_player.js") && is_file(web / "factoria_player.wasm"); }

bool android_libs_complete(const stdfs::path& mobile) {
    for (const char* abi : kAndroidAbis)
        if (!is_file(mobile / "android" / "jniLibs" / abi / "libfactoria_player.so")) return false;
    return true;
}

bool ios_libs_complete(const stdfs::path& mobile) {
    for (const char* sdk : kIosSlices)
        if (!is_file(mobile / "ios" / sdk / "libfactoria_player_main.a")) return false;
    return true;
}

// A mobile/ folder with the libraries of both mobile platforms.
bool mobile_complete(const stdfs::path& mobile) { return android_libs_complete(mobile) && ios_libs_complete(mobile); }

stdfs::path exe_mobile_dir(const SetupContext& ctx) {
    return (ctx.executableDir.empty() ? executable_dir() : stdfs::path(ctx.executableDir)) / "mobile";
}

struct Selection {
    std::vector<std::string> desktop;  // OSes whose player is wanted
    bool mobile = false;
    bool web = false;  // only when asked for: the download carries web/ next to factoria
};

// An export looks for the Android and the iOS libraries separately (in the folder next to factoria, then in the installed
// one), so the Android-only mobile/ of a Windows or Linux download plus an installed iOS half is enough.
bool mobile_covered(const SetupContext& ctx) {
    const stdfs::path next = exe_mobile_dir(ctx), installed = players_root(ctx) / "mobile";
    return (android_libs_complete(next) || android_libs_complete(installed)) && (ios_libs_complete(next) || ios_libs_complete(installed));
}

Selection default_selection(const SetupContext& ctx) {
    Selection s;
    const std::string host = ctx.host_os();
    for (const char* os : kDesktopOses)
        if (host != os) s.desktop.push_back(os);
    s.mobile = !mobile_covered(ctx);
    return s;
}

int package_size_mb(const std::string& os) { return os == "windows" ? 13 : (os == "linux" ? 15 : 33); }

}  // namespace

std::string installed_player_path(const SetupContext& ctx, const std::string& platform) {
    const std::string os = to_lower(platform);
    if (os == "web") {  // the path of factoria_player.js; factoria_player.wasm is next to it
        const stdfs::path dir = players_root(ctx) / "web";
        return web_complete(dir) ? (dir / "factoria_player.js").string() : std::string();
    }
    if (os != "windows" && os != "linux" && os != "macos") return {};
    const stdfs::path p = player_path(ctx, os);
    return is_file(p) ? p.string() : std::string();
}

std::string installed_mobile_path(const SetupContext& ctx) {
    const stdfs::path dir = players_root(ctx) / "mobile";
    return android_libs_complete(dir) || ios_libs_complete(dir) ? dir.string() : std::string();
}

SetupComponent players_status(const SetupContext& ctx) {
    SetupComponent c;
    c.id = "players";
    c.title = "Players of the other platforms";
    c.canInstall = true;
    const std::string host = ctx.host_os();
    const Selection sel = default_selection(ctx);
    const stdfs::path mobileNext = exe_mobile_dir(ctx);
    const stdfs::path mobileInstalled = players_root(ctx) / "mobile";

    int present = 0, wanted = 0;
    std::string have, lack;
    auto add = [&](std::string& list, const std::string& what) { list += (list.empty() ? "" : ", ") + what; };
    for (const std::string& os : sel.desktop) {
        ++wanted;
        const stdfs::path p = player_path(ctx, os);
        if (is_file(p)) {
            ++present;
            add(have, os);
            c.paths.emplace_back("player-" + os, p.string());
        } else {
            add(lack, os);
            c.installSizeMb += package_size_mb(os);
        }
    }
    // The mobile libraries: the folder next to factoria (the download), else the installed one.
    const bool nextOk = mobile_complete(mobileNext);
    const bool installedOk = mobile_complete(mobileInstalled);
    if (nextOk) c.paths.emplace_back("mobile", mobileNext.string());
    else if (installedOk) c.paths.emplace_back("mobile", mobileInstalled.string());
    if (!nextOk) {
        ++wanted;
        if (mobile_covered(ctx)) {
            ++present;
            add(have, "mobile libraries");
        } else {
            const bool androidOk = android_libs_complete(mobileNext) || android_libs_complete(mobileInstalled);
            add(lack, androidOk ? "iOS libraries" : "mobile libraries (Android + iOS)");
            // They come from the macOS package: no extra download when the macOS player is being fetched anyway.
            const bool macosCounted = host != "macos" && !is_file(player_path(ctx, "macos"));
            if (!macosCounted) c.installSizeMb += package_size_mb("macos");
        }
    } else {
        add(have, "mobile libraries (next to factoria)");
    }

    c.state = lack.empty() ? "installed" : (present > 0 || nextOk ? "partial" : "missing");
    if (wanted == 0 && lack.empty()) c.state = "installed";
    c.details = (have.empty() ? std::string() : "Have: " + have + ". ") +
                (lack.empty() ? std::string("Nothing else is needed to export for the other platforms.")
                              : "Missing: " + lack + ". The install downloads them from the GitHub release v" + ctx.version() + " of " + kSetupReleaseRepo + ".");
    if (!lack.empty()) c.problems.push_back("Exporting for another operating system, or Android/iOS without the engine source, needs: " + lack + ".");
    return c;
}

SetupResult players_install(const SetupContext& ctx, const SetupInstallOptions& opt) {
    Installer in(ctx, "players");
    const std::string version = ctx.version();
    const stdfs::path root = players_root(ctx);

    // ---- what to install
    Selection sel;
    if (opt.platforms.empty()) {
        sel = default_selection(ctx);
    } else {
        const std::vector<std::string> valid = {"windows", "linux", "macos", "mobile", "web"};
        for (const std::string& raw : opt.platforms) {
            std::string p = to_lower(raw);
            if (p == "win" || p == "win32") p = "windows";
            if (p == "mac" || p == "osx") p = "macos";
            if (std::find(valid.begin(), valid.end(), p) == valid.end())
                return in.fail("invalid_argument", make_error("Unknown platform '" + raw + "' for the players.", did_you_mean(raw, valid)));
            if (p == "mobile") sel.mobile = true;
            else if (p == "web") sel.web = true;
            else if (std::find(sel.desktop.begin(), sel.desktop.end(), p) == sel.desktop.end()) sel.desktop.push_back(p);
        }
    }
    std::vector<std::string> needDesktop;
    for (const std::string& os : sel.desktop) {
        if (!opt.force && !installed_player_path(ctx, os).empty()) {
            SetupStep s;
            s.id = "player-" + os;
            s.title = "factoria_player for " + os;
            s.outcome = "skipped";
            s.detail = "already installed: " + player_path(ctx, os).string();
            s.path = player_path(ctx, os).string();
            in.add_step(s);
        } else {
            needDesktop.push_back(os);
        }
    }
    bool needMobile = sel.mobile;
    if (needMobile && !opt.force && mobile_complete(root / "mobile")) {
        SetupStep s;
        s.id = "mobile";
        s.title = "Mobile libraries";
        s.outcome = "skipped";
        s.detail = "already installed: " + (root / "mobile").string();
        s.path = (root / "mobile").string();
        in.add_step(s);
        needMobile = false;
    }
    bool needWeb = sel.web;
    if (needWeb && !opt.force && web_complete(root / "web")) {
        SetupStep s;
        s.id = "web";
        s.title = "Web player";
        s.outcome = "skipped";
        s.detail = "already installed: " + (root / "web").string();
        s.path = (root / "web").string();
        in.add_step(s);
        needWeb = false;
    }
    if (needDesktop.empty() && !needMobile && !needWeb) {
        if (in.report.steps.empty()) {
            SetupStep s;
            s.id = "players";
            s.title = "Players";
            s.outcome = "skipped";
            s.detail = "nothing to install: the players this machine needs are there (the mobile libraries come with the download, next to factoria)";
            in.add_step(s);
        }
        in.report.paths = {{"players", root.string()}};
        return in.finish();
    }

    // ---- the release of this version
    const std::string tag = "v" + version;
    const std::string api = std::string("https://api.github.com/repos/") + kSetupReleaseRepo;
    const std::vector<std::string> headers = {"Accept: application/vnd.github+json", "X-GitHub-Api-Version: 2022-11-28"};
    ctx.say("Looking up the release " + tag + " of " + kSetupReleaseRepo + "...");
    std::string text;
    int status = 0;
    if (auto f = fetch_text(ctx, api + "/releases/tags/" + tag, "the release " + tag, in.staging(), text, &status, headers)) {
        if (status == 404) {
            std::string latest, newestTag;
            if (!fetch_text(ctx, api + "/releases/latest", "the newest release", in.staging(), latest, nullptr, headers)) {
                if (auto j = parse_json(latest, "latest release"); j.ok()) {
                    if (auto r = parse_github_release(*j); r.ok()) newestTag = r->tag;
                }
            }
            return in.fail("no_release",
                           make_error("This factoria (" + version + ") has no release " + tag + " on GitHub (a development build ahead of the last release), so there are no players to download for it." +
                                          (newestTag.empty() ? std::string() : " The newest published release is " + newestTag + "."),
                                      "Build the player on the other OS (see docs/BUILDING.md) and pass it with `factoria export --player <path>`, or use a factoria downloaded from https://github.com/" +
                                          std::string(kSetupReleaseRepo) + "/releases."));
        }
        return in.fail(*f);
    }
    auto json = parse_json(text, api);
    if (!json.ok()) return in.fail("failed", make_error("GitHub's answer for " + tag + " is not JSON: " + json.error().message, "Try again later."));
    auto release = parse_github_release(*json);
    if (!release.ok()) return in.fail("failed", release.error());

    // ---- one package per OS: the OSes asked for, plus the macOS one for the mobile libraries (the only package with the iOS ones)
    std::vector<std::string> packages = needDesktop;
    if (needMobile && std::find(packages.begin(), packages.end(), "macos") == packages.end()) packages.push_back("macos");
    // The web player is in every package: this machine's own is the one to take it from.
    if (needWeb && std::find(packages.begin(), packages.end(), ctx.host_os()) == packages.end()) packages.push_back(ctx.host_os());
    for (const std::string& os : packages) {
        StepTimer timer;
        const std::string name = package_name(os);
        const ReleaseAsset* asset = release->find(name);
        if (!asset)
            return in.fail("no_release", make_error("The release " + release->tag + " has no " + name + " package (yet).",
                                                     "Its packages may still be uploading: try again in a few minutes."));
        const stdfs::path archive = in.staging() / name;
        std::uint64_t bytes = 0;
        if (auto f = download_file(ctx, asset->url, archive, "FactorIA " + release->tag + " for " + os, asset->size, &bytes)) return in.fail(*f);
        if (!asset->sha256.empty()) {
            if (auto f = verify_checksum(archive, "sha256", asset->sha256, name)) return in.fail(*f);
        } else {
            in.report.warnings.push_back("GitHub lists no checksum for " + name + ", so only its size was compared.");
            if (asset->size && bytes != asset->size)
                return in.fail("checksum_mismatch", make_error("The download of " + name + " has " + std::to_string(bytes) + " bytes but the release lists " + std::to_string(asset->size) + ".", "Run it again."));
        }
        const stdfs::path unpacked = in.make_staging_subdir("pkg-" + os);
        if (auto f = extract_archive(ctx, archive, unpacked)) return in.fail(*f);
        std::error_code ec;
        stdfs::remove(archive, ec);
        stdfs::path top = unpacked / "FactorIA";
        if (!is_dir(top)) top = single_child_dir(unpacked);

        if (std::find(needDesktop.begin(), needDesktop.end(), os) != needDesktop.end()) {
            const stdfs::path src = top / player_file_name(os);
            if (!is_file(src))
                return in.fail("failed", make_error("The package " + name + " has no " + player_file_name(os) + " inside.", "Report this: the release " + release->tag + " is broken."));
            const stdfs::path tmp = root / (".tmp-" + os);
            stdfs::remove_all(tmp, ec);
            stdfs::create_directories(tmp, ec);
            stdfs::copy_file(src, tmp / player_file_name(os), stdfs::copy_options::overwrite_existing, ec);
            if (ec) return in.fail("failed", make_error("Cannot copy " + src.string() + " into " + tmp.string() + ": " + ec.message(), "Check the free disk space."));
            make_executable(tmp / player_file_name(os));
            if (auto f = replace_dir(tmp, root / os)) return in.fail(*f);
            SetupStep s;
            s.id = "player-" + os;
            s.title = "factoria_player for " + os;
            s.outcome = "installed";
            s.detail = "from " + name + " of the release " + release->tag;
            s.path = player_path(ctx, os).string();
            s.downloadedBytes = bytes;
            s.seconds = timer.seconds();
            in.add_step(s);
        }
        if (needMobile && os == "macos") {
            const stdfs::path src = top / "mobile";
            if (!is_dir(src) || !mobile_complete(src))
                return in.fail("failed", make_error("The package " + name + " has no mobile/android/jniLibs and mobile/ios libraries inside.",
                                                     "Report this: the release " + release->tag + " is broken."));
            if (auto f = replace_dir(src, root / "mobile")) return in.fail(*f);
            SetupStep s;
            s.id = "mobile";
            s.title = "Mobile libraries";
            s.outcome = "installed";
            s.detail = "Android and iOS libraries from " + name;
            s.path = (root / "mobile").string();
            s.downloadedBytes = (std::find(needDesktop.begin(), needDesktop.end(), os) != needDesktop.end()) ? 0 : bytes;
            s.seconds = timer.seconds();
            in.add_step(s);
        }
        if (needWeb && os == ctx.host_os()) {
            const stdfs::path src = top / "web";
            if (!web_complete(src))
                return in.fail("failed", make_error("The package " + name + " has no web/factoria_player.js and web/factoria_player.wasm inside.",
                                                     "Report this: the release " + release->tag + " is broken, or too old to carry the web player (use a newer FactorIA, or build the "
                                                     "web player yourself, see docs/BUILDING.md, and pass it with `factoria export --platform web --player <folder>`)."));
            if (auto f = replace_dir(src, root / "web")) return in.fail(*f);
            SetupStep s;
            s.id = "web";
            s.title = "Web player";
            s.outcome = "installed";
            s.detail = "from " + name + " of the release " + release->tag;
            s.path = (root / "web").string();
            const bool shared = std::find(needDesktop.begin(), needDesktop.end(), os) != needDesktop.end() || (needMobile && os == "macos");
            s.downloadedBytes = shared ? 0 : bytes;  // the step that owns the download reports its size
            s.seconds = timer.seconds();
            in.add_step(s);
        }
    }
    in.report.paths = {{"players", root.string()}};
    if (needMobile) in.report.paths.emplace_back("mobile", (root / "mobile").string());
    if (needWeb) in.report.paths.emplace_back("web", (root / "web").string());
    in.report.nextSteps.push_back("`factoria export --platform <windows|linux|macos|android|ios>` now finds these players without --player or --mobile-dir.");
    return in.finish();
}

}  // namespace fa::setup_detail
