// `setup webplayer`: builds the web player (factoria_player.js + .wasm) from the engine source this factoria was built
// from, for a development build whose version has no release (so `setup players --platforms web` has nothing that matches).
//
//   <checkout>/build/web-release/player/factoria_player.{js,wasm}     what the web export prefers (find_web_player)
//   <checkout>/.cache/emsdk                                            the Emscripten SDK, only when none is found
//
// The steps: find the checkout (CMakePresets.json + engine/), find an Emscripten SDK ($EMSDK, an emcc on PATH, the checkout's
// .cache/emsdk, ~/emsdk) or fetch the pinned one (kSetupEmscriptenVersion, the CI version) into .cache/, then run the
// `web-release` preset through a shell that sources the SDK's emsdk_env, so the SDK's own Python and Node are used.
#include <algorithm>
#include <fstream>
#include <thread>

#include "fa/core/build_info.h"
#include "fa/core/strings.h"
#include "setup_internal.h"

#ifndef FA_SOURCE_ROOT
#define FA_SOURCE_ROOT ""
#endif

namespace fa::setup_detail {

namespace {

bool is_checkout(const stdfs::path& dir) { return !dir.empty() && is_file(dir / "CMakePresets.json") && is_dir(dir / "engine"); }

stdfs::path source_root(const SetupContext& ctx) { return stdfs::path(ctx.sourceRoot.empty() ? std::string(FA_SOURCE_ROOT) : ctx.sourceRoot); }

stdfs::path player_dir(const stdfs::path& root) { return root / "build" / "web-release" / "player"; }

stdfs::path toolchain_file(const stdfs::path& emsdk) {
    return emsdk / "upstream" / "emscripten" / "cmake" / "Modules" / "Platform" / "Emscripten.cmake";
}

bool emsdk_usable(const stdfs::path& emsdk) { return !emsdk.empty() && is_file(toolchain_file(emsdk)); }

std::string env_script(const SetupContext& ctx) { return ctx.host_os() == "windows" ? "emsdk_env.bat" : "emsdk_env.sh"; }

// An Emscripten SDK folder: $EMSDK, the SDK that an emcc on PATH belongs to, the checkout's .cache/emsdk, ~/emsdk.
stdfs::path find_emsdk(const SetupContext& ctx, const stdfs::path& root, std::string* from = nullptr) {
    auto found = [&](const stdfs::path& p, const char* why) {
        if (from) *from = why;
        return p;
    };
    if (const std::string e = ctx.env("EMSDK"); emsdk_usable(e) && is_file(stdfs::path(e) / env_script(ctx))) return found(e, "$EMSDK");
    const char sep = ctx.host_os() == "windows" ? ';' : ':';
    const std::string emcc = ctx.host_os() == "windows" ? "emcc.bat" : "emcc";
    for (const std::string& dir : split(ctx.env("PATH"), sep)) {
        if (dir.empty() || !is_file(stdfs::path(dir) / emcc)) continue;
        std::error_code ec;
        const stdfs::path real = stdfs::weakly_canonical(stdfs::path(dir) / emcc, ec);  // <emsdk>/upstream/emscripten/emcc
        if (ec) continue;
        const stdfs::path emsdk = real.parent_path().parent_path().parent_path();
        if (emsdk_usable(emsdk) && is_file(emsdk / env_script(ctx))) return found(emsdk, "emcc on PATH");
    }
    if (const stdfs::path cached = root / ".cache" / "emsdk"; emsdk_usable(cached)) return found(cached, "the checkout's .cache/emsdk");
    const std::string home = ctx.host_os() == "windows" ? ctx.env("USERPROFILE") : ctx.env("HOME");
    if (!home.empty())
        if (const stdfs::path dflt = stdfs::path(home) / "emsdk"; emsdk_usable(dflt)) return found(dflt, "~/emsdk");
    return {};
}

std::string read_first_line(const stdfs::path& file) {
    std::ifstream in(file);
    std::string line;
    std::getline(in, line);
    return std::string(trim(line));
}

std::string sdk_version(const stdfs::path& emsdk) { return read_first_line(emsdk / "upstream" / "emscripten" / "emscripten-version.txt"); }

std::uint64_t file_bytes(const stdfs::path& p) {
    std::error_code ec;
    const auto n = stdfs::file_size(p, ec);
    return ec ? 0 : static_cast<std::uint64_t>(n);
}

bool player_complete(const stdfs::path& dir) { return is_file(dir / "factoria_player.js") && is_file(dir / "factoria_player.wasm"); }

// The fingerprint inside the player's wasm: "" when it has none.
std::string player_fingerprint(const stdfs::path& dir) {
    std::ifstream in(dir / "factoria_player.wasm", std::ios::binary);
    const std::string bytes((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    return find_build_fingerprint(bytes);
}

// True when the player at `dir` is of this factoria's build (or when this factoria has no fingerprint to compare).
bool player_matches(const stdfs::path& dir) {
    const std::string mine = build_fingerprint();
    return mine == "unknown" || player_fingerprint(dir) == mine;
}

std::string tail_of(const std::vector<std::string>& lines, std::size_t n) {
    std::string out;
    for (std::size_t i = lines.size() > n ? lines.size() - n : 0; i < lines.size(); ++i) out += "  " + lines[i] + "\n";
    return out;
}

// Runs `argv` in `dir`, relaying a progress line now and then; returns the last lines of its output on failure.
std::optional<Fail> run_step(const SetupContext& ctx, const std::vector<std::string>& argv, const stdfs::path& dir,
                             const std::map<std::string, std::string>& env, const std::string& what, const std::string& hint) {
    ProcessOptions po;
    po.argv = argv;
    po.workingDir = dir.string();
    po.env = env;
    po.cancel = ctx.cancel;
    po.captureStdout = false;
    auto lines = std::make_shared<std::vector<std::string>>();
    auto lastTenth = std::make_shared<int>(-1);
    auto onLine = [&ctx, lines, lastTenth](std::string_view line) {
        lines->emplace_back(std::string(line));
        if (lines->size() > 60) lines->erase(lines->begin());
        // ninja's "[123/456] ..." lines: one progress line per tenth of the build
        if (line.size() > 5 && line[0] == '[') {
            const std::size_t slash = line.find('/'), close = line.find(']');
            if (slash != std::string_view::npos && close != std::string_view::npos && slash < close) {
                const int done = std::atoi(std::string(line.substr(1, slash - 1)).c_str());
                const int total = std::atoi(std::string(line.substr(slash + 1, close - slash - 1)).c_str());
                if (total > 0 && done * 10 / total != *lastTenth) {
                    *lastTenth = done * 10 / total;
                    ctx.say("Building the web player: " + std::to_string(done) + "/" + std::to_string(total) + " steps");
                }
            }
        }
    };
    po.onStdoutLine = onLine;
    po.onStderrLine = onLine;
    ctx.say(what + "...");
    auto r = ctx.run_process_with(po);
    if (!r.ok()) return Fail{"failed", make_error(what + " could not start: " + r.error().message, hint)};
    if (r->cancelled || is_cancelled(ctx.cancel)) return Fail{"cancelled", make_error(what + " was cancelled.")};
    if (r->exitCode != 0) {
        for (const std::string& l : split(r->stderrText, '\n'))
            if (!l.empty() && std::find(lines->begin(), lines->end(), l) == lines->end()) lines->push_back(l);
        return Fail{"failed", make_error(what + " failed (exit code " + std::to_string(r->exitCode) + "). The last lines:\n" + tail_of(*lines, 25), hint)};
    }
    return std::nullopt;
}

const char* const kBuildHint =
    "Needs CMake 3.24+, Ninja, Python 3.10+ and a C++ toolchain on PATH next to the Emscripten SDK (docs/BUILDING.md, \"Web\"). "
    "On a Mac with an older system Python, point EMSDK_PYTHON at a newer one (`brew install python@3.13`).";

}  // namespace

SetupComponent webplayer_status(const SetupContext& ctx) {
    SetupComponent c;
    c.id = "webplayer";
    c.title = "Web player built from this checkout (development builds)";
    const stdfs::path root = source_root(ctx);
    if (!is_checkout(root)) {
        c.state = "unsupported";
        c.details = "This factoria was not built from a source checkout here (" + (root.empty() ? std::string("no source folder is recorded") : root.string()) +
                    " has no CMakePresets.json and engine/). A download of FactorIA carries the web player in web/; `factoria setup players --platforms web` installs the one of a release.";
        return c;
    }
    c.canInstall = true;
    const stdfs::path dir = player_dir(root);
    if (player_complete(dir)) {
        c.paths.emplace_back("player", dir.string());
        if (player_matches(dir)) {
            c.state = "installed";
            c.details = "A web player of this factoria's build is in " + dir.string() + "; `factoria export --platform web` uses it.";
            return c;
        }
        c.state = "partial";
        c.details = "The web player in " + dir.string() + " was built from another commit than this factoria (" + build_fingerprint() + "); the install builds it again.";
        c.problems.push_back("A web export would stop on the fingerprint mismatch: run `factoria setup webplayer`.");
        return c;
    }
    c.state = "missing";
    const std::string how = find_emsdk(ctx, root).empty()
                                ? std::string("it fetches Emscripten ") + kSetupEmscriptenVersion + " into " + (root / ".cache" / "emsdk").string() + " (about 1 GB), then "
                                : std::string("it uses the Emscripten SDK it found, then ");
    c.details = "The install " + how + "builds the `web-release` preset into " + dir.string() + " (several minutes).";
    c.problems.push_back("A development build has no release whose web player matches it: run `factoria setup webplayer` (or `factoria setup players --platforms web` for the newest release's, with allowPlayerMismatch).");
    return c;
}

SetupResult webplayer_install(const SetupContext& ctx, const SetupInstallOptions& opt) {
    Installer in(ctx, "webplayer");
    const stdfs::path root = source_root(ctx);
    if (!is_checkout(root))
        return in.fail("unsupported",
                       make_error("This factoria was not built from a source checkout that is still here (" + (root.empty() ? std::string("no source folder is recorded") : root.string()) +
                                      " has no CMakePresets.json and engine/), so it cannot build a web player.",
                                  "Use the web player of a release: `factoria setup players --platforms web` (a download of FactorIA carries it in web/), or build in a checkout of the engine (docs/BUILDING.md, \"Web\")."));
    const stdfs::path dir = player_dir(root);
    if (!opt.force && player_complete(dir) && player_matches(dir)) {
        SetupStep s;
        s.id = "web-player";
        s.title = "Web player";
        s.outcome = "skipped";
        s.detail = "already built from this factoria's commit: " + dir.string();
        s.path = dir.string();
        in.add_step(s);
        in.report.paths = {{"player", dir.string()}};
        return in.finish();
    }

    // ---- CMake
    const std::string cmake = find_cmake_path(ctx);
    if (cmake.empty())
        return in.fail("failed", make_error("No CMake " + std::string(kSetupCmakeMinimum) + " or newer was found, and the web player is built with the `web-release` CMake preset.",
                                            "Install CMake (https://cmake.org/download/, `brew install cmake`, `factoria setup cmake` on a Mac) and Ninja, then run this again."));

    // ---- Emscripten: found, or the pinned one fetched into <checkout>/.cache/emsdk
    std::string from;
    stdfs::path emsdk = find_emsdk(ctx, root, &from);
    if (emsdk.empty()) {
        StepTimer timer;
        const stdfs::path target = root / ".cache" / "emsdk";
        const std::string url = "https://github.com/emscripten-core/emsdk/archive/refs/heads/main.tar.gz";
        const stdfs::path archive = in.staging() / "emsdk.tar.gz";
        std::uint64_t bytes = 0;
        if (auto f = download_file(ctx, url, archive, "the Emscripten SDK installer (emsdk)", 0, &bytes)) return in.fail(*f);
        const stdfs::path unpacked = in.make_staging_subdir("emsdk");
        if (auto f = extract_archive(ctx, archive, unpacked)) return in.fail(*f);
        const stdfs::path top = single_child_dir(unpacked);
        if (auto f = replace_dir(top, target)) return in.fail(*f);
        const std::string script = ctx.host_os() == "windows" ? "emsdk.bat" : "emsdk";
        make_executable(target / script);
        for (const char* verb : {"install", "activate"})
            if (auto f = run_step(ctx, {(target / script).string(), verb, kSetupEmscriptenVersion}, target, {},
                                  std::string("`emsdk ") + verb + " " + kSetupEmscriptenVersion + "`",
                                  "emsdk needs Python 3.10+ and network access; set EMSDK_PYTHON to a Python 3.10+ if the system one is older, or install the SDK yourself (docs/BUILDING.md, \"Web\") and set EMSDK."))
                return in.fail(*f);
        if (!emsdk_usable(target))
            return in.fail("failed", make_error("`emsdk install " + std::string(kSetupEmscriptenVersion) + "` finished but " + toolchain_file(target).string() + " is not there.",
                                                 "Delete " + target.string() + " and run this again, or install the SDK yourself (docs/BUILDING.md, \"Web\") and set EMSDK."));
        emsdk = target;
        in.report.changed = true;
        SetupStep s;
        s.id = "emsdk";
        s.title = "Emscripten SDK " + std::string(kSetupEmscriptenVersion);
        s.outcome = "installed";
        s.detail = "fetched into the checkout's .cache/ (the pinned version, the one CI uses)";
        s.path = target.string();
        s.downloadedBytes = bytes;
        s.seconds = timer.seconds();
        in.add_step(s);
    } else {
        SetupStep s;
        s.id = "emsdk";
        s.title = "Emscripten SDK";
        s.outcome = "skipped";
        s.detail = "found (" + from + "): " + emsdk.string();
        s.path = emsdk.string();
        in.add_step(s);
        if (const std::string v = sdk_version(emsdk); !v.empty() && v != kSetupEmscriptenVersion)
            in.report.warnings.push_back("This Emscripten SDK is " + v + "; CI and the releases use " + kSetupEmscriptenVersion + " (newer ones are likely fine but untested).");
    }

    // ---- configure + build through a shell that loads the SDK's environment
    {
        StepTimer timer;
        const bool windows = ctx.host_os() == "windows";
        const unsigned jobs = std::max(1u, std::thread::hardware_concurrency());
        const std::string cmakeDir = stdfs::path(cmake).parent_path().string();
        std::map<std::string, std::string> env;
        env["EMSDK_QUIET"] = "1";
        env["EMSDK"] = emsdk.string();
        const char sep = windows ? ';' : ':';
        env["PATH"] = cmakeDir + sep + ctx.env("PATH");
        std::vector<std::string> argv;
        if (windows) {
            argv = {"cmd.exe", "/d", "/c",
                    "call \"" + (emsdk / env_script(ctx)).string() + "\" >nul && \"" + cmake + "\" --preset web-release && \"" + cmake + "\" --build --preset web-release --parallel " + std::to_string(jobs)};
        } else {
            argv = {"bash", "-c",
                    ". \"$EMSDK/emsdk_env.sh\" >/dev/null 2>&1; \"" + cmake + "\" --preset web-release && \"" + cmake + "\" --build --preset web-release --parallel " + std::to_string(jobs)};
        }
        ctx.say("Building the web player from " + root.string() + " (the `web-release` preset; a first build takes several minutes)");
        if (auto f = run_step(ctx, argv, root, env, "Building the web player", kBuildHint)) return in.fail(*f);
        if (!player_complete(dir))
            return in.fail("failed", make_error("The `web-release` build finished but " + (dir / "factoria_player.js").string() + " and factoria_player.wasm are not there.",
                                                 "Run `cmake --build --preset web-release` in " + root.string() + " and read its output."));
        SetupStep s;
        s.id = "web-player";
        s.title = "Web player";
        s.outcome = "installed";
        s.detail = "built from this checkout: " + dir.string() + " (factoria_player.wasm " + format_bytes(file_bytes(dir / "factoria_player.wasm")) + ")";
        s.path = dir.string();
        s.seconds = timer.seconds();
        in.add_step(s);
    }
    in.report.paths = {{"player", dir.string()}, {"emsdk", emsdk.string()}};
    if (!player_matches(dir))
        in.report.warnings.push_back("The web player was built from the commit " + player_fingerprint(dir) + " but this factoria is " + build_fingerprint() +
                                     " (uncommitted changes, or factoria was built before the last commit): rebuild factoria too, or pass allowPlayerMismatch to the export.");
    in.report.nextSteps.push_back("`factoria export --platform web` now uses " + dir.string() + " (the checkout's build/web-release comes before an installed player).");
    return in.finish();
}

}  // namespace fa::setup_detail
