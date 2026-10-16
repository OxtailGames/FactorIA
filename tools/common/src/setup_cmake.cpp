// `setup cmake`: CMake 3.24+ for the iOS export's build_ios.sh (macOS), from Kitware's official release into
// <home>/tools/cmake. find_cmake() is what the export (and the status) uses to locate one.
#include <algorithm>

#include "fa/core/strings.h"
#include "setup_internal.h"

namespace fa::setup_detail {

namespace {

std::string archive_name(const std::string& host, const std::string& arch) {
    const std::string v = kSetupCmakeVersion;
    if (host == "macos") return "cmake-" + v + "-macos-universal.tar.gz";
    if (host == "windows") return "cmake-" + v + (arch == "aarch64" ? "-windows-arm64.zip" : "-windows-x86_64.zip");
    return "cmake-" + v + (arch == "aarch64" ? "-linux-aarch64.tar.gz" : "-linux-x86_64.tar.gz");
}

stdfs::path installed_cmake(const SetupContext& ctx) {
    const stdfs::path root = stdfs::path(ctx.home_dir()) / "tools" / "cmake";
    if (ctx.host_os() == "macos") return root / "CMake.app" / "Contents" / "bin" / "cmake";
    return root / "bin" / ("cmake" + exe_suffix(ctx.host_os()));
}

std::vector<std::string> path_entries(const SetupContext& ctx) {
    const std::string path = ctx.env("PATH");
    const char sep = ctx.host_os() == "windows" ? ';' : ':';
    std::vector<std::string> out;
    for (std::string& entry : split(path, sep))
        if (!entry.empty()) out.push_back(std::move(entry));  // an empty entry would mean the current folder
    return out;
}

// Every place a CMake may be, in the order they are tried.
std::vector<stdfs::path> candidates(const SetupContext& ctx) {
    const std::string host = ctx.host_os();
    const std::string exe = "cmake" + exe_suffix(host);
    std::vector<stdfs::path> out;
    for (const std::string& dir : path_entries(ctx)) out.push_back(stdfs::path(dir) / exe);
    if (host == "macos") {
        out.push_back("/opt/homebrew/bin/cmake");
        out.push_back("/usr/local/bin/cmake");
        out.push_back("/Applications/CMake.app/Contents/bin/cmake");
    } else if (host == "windows") {
        std::string pf = ctx.env("ProgramFiles");
        if (pf.empty()) pf = "C:\\Program Files";
        out.push_back(stdfs::path(pf) / "CMake" / "bin" / "cmake.exe");
    }
    out.push_back(installed_cmake(ctx));
    return out;
}

// The version `cmake --version` reports, empty when it does not run or is not CMake.
std::vector<int> probe_version(const SetupContext& ctx, const stdfs::path& cmake) {
    ProcessOptions po;
    po.argv = {cmake.string(), "--version"};
    po.timeoutSeconds = 20;
    auto r = ctx.run_process_with(po);
    if (!r.ok() || r->exitCode != 0) return {};
    return parse_cmake_version(r->stdoutText);
}

std::string version_text(const std::vector<int>& v) {
    std::string s;
    for (int n : v) s += (s.empty() ? "" : ".") + std::to_string(n);
    return s;
}

struct Found {
    stdfs::path path;
    std::vector<int> version;
    stdfs::path tooOldPath;  // the first CMake that runs but is older than the minimum
    std::vector<int> tooOldVersion;
};

Found look_for_cmake(const SetupContext& ctx) {
    Found f;
    std::vector<stdfs::path> seen;
    for (const stdfs::path& c : candidates(ctx)) {
        if (std::find(seen.begin(), seen.end(), c) != seen.end() || !is_file(c)) continue;
        seen.push_back(c);
        const std::vector<int> v = probe_version(ctx, c);
        if (v.empty()) continue;
        if (version_at_least(v, kSetupCmakeMinimum)) {
            f.path = c;
            f.version = v;
            return f;
        }
        if (f.tooOldPath.empty()) f.tooOldPath = c, f.tooOldVersion = v;
    }
    return f;
}

}  // namespace

std::string find_cmake_path(const SetupContext& ctx) { return look_for_cmake(ctx).path.string(); }

SetupComponent cmake_status(const SetupContext& ctx) {
    SetupComponent c;
    c.id = "cmake";
    c.title = "CMake (iOS export)";
    if (ctx.host_os() != "macos") {
        c.state = "unsupported";
        c.details = "Only the iOS export needs CMake (build_ios.sh), and iOS exports run on a Mac: nothing to install on this computer.";
        return c;
    }
    c.canInstall = true;
    const Found f = look_for_cmake(ctx);
    if (!f.path.empty()) {
        c.state = "installed";
        c.paths.emplace_back("cmake", f.path.string());
        c.details = "CMake " + version_text(f.version) + " at " + f.path.string() + ".";
        return c;
    }
    c.state = "missing";
    c.installSizeMb = 75;
    c.details = "CMake " + std::string(kSetupCmakeMinimum) + " or newer is needed by build_ios.sh; the install downloads CMake " + kSetupCmakeVersion +
                " from Kitware into " + (stdfs::path(ctx.home_dir()) / "tools" / "cmake").string() + ".";
    c.problems.push_back(f.tooOldPath.empty() ? "No CMake " + std::string(kSetupCmakeMinimum) + " or newer was found (PATH, Homebrew, /Applications/CMake.app)."
                                              : "CMake " + version_text(f.tooOldVersion) + " at " + f.tooOldPath.string() + " is older than " + kSetupCmakeMinimum + ".");
    return c;
}

SetupResult cmake_install(const SetupContext& ctx, const SetupInstallOptions& opt) {
    Installer in(ctx, "cmake");
    const std::string host = ctx.host_os();
    if (host != "macos" && !opt.force)
        return in.fail("unsupported", make_error("Only the iOS export needs CMake, and iOS exports run on a Mac, so there is nothing to install on " + host + ".",
                                                  "Pass force (factoria setup cmake --force) to install CMake into " + (stdfs::path(ctx.home_dir()) / "tools" / "cmake").string() + " anyway."));
    if (!opt.force) {
        const Found found = look_for_cmake(ctx);
        if (!found.path.empty()) {
            SetupStep s;
            s.id = "cmake";
            s.title = "CMake";
            s.outcome = "skipped";
            s.detail = "already installed: CMake " + version_text(found.version) + " at " + found.path.string();
            s.path = found.path.string();
            in.add_step(s);
            in.report.paths = {{"cmake", found.path.string()}};
            return in.finish();
        }
    }
    StepTimer timer;
    const std::string version = kSetupCmakeVersion;
    const std::string base = "https://github.com/Kitware/CMake/releases/download/v" + version + "/";
    const std::string name = archive_name(host, ctx.host_architecture());

    ctx.say("Looking up the checksum of " + name + "...");
    std::string sums;
    if (auto f = fetch_text(ctx, base + "cmake-" + version + "-SHA-256.txt", "the CMake " + version + " checksums", in.staging(), sums)) return in.fail(*f);
    const auto table = parse_sha256_sums(sums);
    const auto expected = table.find(name);
    if (expected == table.end())
        return in.fail("failed", make_error("Kitware's checksum list for CMake " + version + " has no entry for " + name + ".",
                                            "Update FactorIA, or install CMake yourself (https://cmake.org/download)."));

    const stdfs::path archive = in.staging() / name;
    std::uint64_t bytes = 0;
    if (auto f = download_file(ctx, base + name, archive, "CMake " + version, 0, &bytes)) return in.fail(*f);
    if (auto f = verify_checksum(archive, "sha256", expected->second, name)) return in.fail(*f);
    const stdfs::path unpacked = in.make_staging_subdir("cmake");
    if (auto f = extract_archive(ctx, archive, unpacked)) return in.fail(*f);
    std::error_code ec;
    stdfs::remove(archive, ec);
    const stdfs::path top = single_child_dir(unpacked);
    const stdfs::path root = stdfs::path(ctx.home_dir()) / "tools" / "cmake";
    const stdfs::path relExe = installed_cmake(ctx).lexically_relative(root);
    if (!is_file(top / relExe))
        return in.fail("failed", make_error("The CMake archive " + name + " has no " + relExe.generic_string() + " inside.", "Update FactorIA, or install CMake yourself (https://cmake.org/download)."));
    if (auto f = replace_dir(top, root)) return in.fail(*f);
    const stdfs::path exe = installed_cmake(ctx);
    make_executable(exe);
    const std::vector<int> v = probe_version(ctx, exe);
    if (!version_at_least(v, kSetupCmakeMinimum))
        return in.fail("failed", make_error("The CMake installed at " + exe.string() + " does not run (`cmake --version` gave " + (v.empty() ? std::string("nothing usable") : version_text(v)) + ").",
                                            "On macOS check System Settings > Privacy & Security for a blocked program, then run it again."));
    SetupStep s;
    s.id = "cmake";
    s.title = "CMake " + version;
    s.outcome = "installed";
    s.detail = "from Kitware (checksum verified)";
    s.path = exe.string();
    s.downloadedBytes = bytes;
    s.seconds = timer.seconds();
    in.add_step(s);
    in.report.paths = {{"cmake", exe.string()}};
    if (const Found first = look_for_cmake(ctx); !first.path.empty() && first.path != exe)
        in.report.warnings.push_back("Another CMake (" + first.path.string() + ") comes first in the search; both work.");
    in.report.nextSteps.push_back("`factoria export --platform ios` uses the CMake it finds (find_cmake): PATH first, then this one.");
    return in.finish();
}

}  // namespace fa::setup_detail
