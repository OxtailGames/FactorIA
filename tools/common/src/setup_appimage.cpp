// `setup appimage`: appimagetool and the AppImage runtime, the two files `factoria export --platform linux --format appimage`
// builds an AppImage with. Pinned releases of github.com/AppImage, each checked against the SHA-256 listed here (the same files
// and hashes scripts/package-appimage.sh uses for FactorIA's own AppImage: a test keeps them equal):
//
//   <home>/tools/appimage/appimagetool-<version>-x86_64.AppImage
//   <home>/tools/appimage/runtime-<version>-x86_64
//
// Both are x86_64 programs, so only a Linux x86_64 computer can use them (appimagetool runs here, with APPIMAGE_EXTRACT_AND_RUN
// so that no FUSE is needed). Elsewhere the component is "unsupported" and the export says to export on Linux or in WSL.
#include <algorithm>

#include "fa/core/strings.h"
#include "setup_internal.h"

namespace fa::setup_detail {

namespace {

struct Download {
    const char* id;
    const char* title;
    std::string file;  // the name it is kept under
    std::string url;
    const char* sha256;
    int sizeMb;
};

std::vector<Download> downloads() {
    const std::string tool = kSetupAppimagetoolVersion, runtime = kSetupAppImageRuntimeVersion;
    return {{"appimagetool", "appimagetool", "appimagetool-" + tool + "-x86_64.AppImage",
             "https://github.com/AppImage/appimagetool/releases/download/" + tool + "/appimagetool-x86_64.AppImage", kSetupAppimagetoolSha256, 4},
            {"runtime", "AppImage runtime", "runtime-" + runtime + "-x86_64",
             "https://github.com/AppImage/type2-runtime/releases/download/" + runtime + "/runtime-x86_64", kSetupAppImageRuntimeSha256, 1}};
}

stdfs::path tools_dir(const SetupContext& ctx) { return stdfs::path(ctx.home_dir()) / "tools" / "appimage"; }

bool supported_host(const SetupContext& ctx) { return ctx.host_os() == "linux" && ctx.host_architecture() == "x64"; }

}  // namespace

AppImageTools installed_appimage_path(const SetupContext& ctx) {
    const std::vector<Download> all = downloads();
    AppImageTools t;
    if (is_file(tools_dir(ctx) / all[0].file) && is_file(tools_dir(ctx) / all[1].file)) {
        t.tool = (tools_dir(ctx) / all[0].file).string();
        t.runtime = (tools_dir(ctx) / all[1].file).string();
    }
    return t;
}

SetupComponent appimage_status(const SetupContext& ctx) {
    SetupComponent c;
    c.id = "appimage";
    c.title = "AppImage tools (Linux export as an AppImage)";
    if (!supported_host(ctx)) {
        c.state = "unsupported";
        c.details = "appimagetool is an x86_64 Linux program, so an AppImage is built on Linux x86_64 only (in WSL on Windows). Nothing to install on " +
                    ctx.host_os() + "-" + ctx.host_architecture() + ".";
        return c;
    }
    c.canInstall = true;
    const AppImageTools have = installed_appimage_path(ctx);
    if (!have.tool.empty()) {
        c.state = "installed";
        c.paths.emplace_back("appimagetool", have.tool);
        c.paths.emplace_back("runtime", have.runtime);
        c.details = std::string("appimagetool ") + kSetupAppimagetoolVersion + " and the AppImage runtime " + kSetupAppImageRuntimeVersion + " in " + tools_dir(ctx).string() + ".";
        return c;
    }
    c.state = "missing";
    for (const Download& d : downloads()) c.installSizeMb += d.sizeMb;
    c.details = std::string("The install downloads appimagetool ") + kSetupAppimagetoolVersion + " and the AppImage runtime " + kSetupAppImageRuntimeVersion +
                " from github.com/AppImage (SHA-256 checked) into " + tools_dir(ctx).string() + ".";
    c.problems.push_back("`factoria export --platform linux --format appimage` needs appimagetool and the AppImage runtime.");
    return c;
}

SetupResult appimage_install(const SetupContext& ctx, const SetupInstallOptions& opt) {
    Installer in(ctx, "appimage");
    if (!supported_host(ctx))
        return in.fail("unsupported", make_error("An AppImage is built on Linux x86_64 only (appimagetool is an x86_64 Linux program), and this computer is " + ctx.host_os() + "-" + ctx.host_architecture() + ".",
                                                  "Export the game on a Linux x86_64 computer, or in WSL (Ubuntu) on Windows; `factoria setup appimage` there installs the tools."));
    const stdfs::path dir = tools_dir(ctx);
    std::error_code ec;
    for (const Download& d : downloads()) {
        StepTimer timer;
        SetupStep s;
        s.id = d.id;
        s.title = d.title;
        const stdfs::path dest = dir / d.file;
        if (!opt.force && is_file(dest)) {
            s.outcome = "skipped";
            s.detail = "already installed: " + dest.string();
            s.path = dest.string();
            in.add_step(s);
            continue;
        }
        const stdfs::path file = in.staging() / d.file;
        std::uint64_t bytes = 0;
        if (auto f = download_file(ctx, d.url, file, std::string(d.title) + " (" + (d.id == std::string("runtime") ? kSetupAppImageRuntimeVersion : kSetupAppimagetoolVersion) + ")", 0, &bytes))
            return in.fail(*f);
        if (auto f = verify_checksum(file, "sha256", d.sha256, d.file)) return in.fail(*f);
        stdfs::create_directories(dir, ec);
        if (ec) return in.fail("failed", make_error("Cannot create " + dir.string() + ": " + ec.message(), "Check that the folder is writable and the disk is not full."));
        stdfs::remove(dest, ec);
        stdfs::rename(file, dest, ec);
        if (ec) {  // another volume
            stdfs::copy_file(file, dest, stdfs::copy_options::overwrite_existing, ec);
            if (ec) return in.fail("failed", make_error("Cannot write " + dest.string() + ": " + ec.message(), "Check that the folder is writable and the disk is not full."));
        }
        make_executable(dest);
        in.report.changed = true;
        s.outcome = "installed";
        s.detail = "from github.com/AppImage (SHA-256 checked)";
        s.path = dest.string();
        s.downloadedBytes = bytes;
        s.seconds = timer.seconds();
        in.add_step(s);
    }
    // An older version of either file is no longer used.
    const std::vector<Download> all = downloads();
    for (stdfs::directory_iterator it(dir, ec), end; !ec && it != end; it.increment(ec)) {
        const std::string name = it->path().filename().string();
        const bool ours = name == all[0].file || name == all[1].file;
        if ((starts_with(name, "appimagetool-") || starts_with(name, "runtime-")) && !ours) {
            std::error_code rm;
            stdfs::remove(it->path(), rm);
        }
    }
    in.report.paths = {{"appimagetool", (dir / all[0].file).string()}, {"runtime", (dir / all[1].file).string()}};
    in.report.nextSteps.push_back("`factoria export --platform linux --format appimage` builds the AppImage of a game with them.");
    return in.finish();
}

}  // namespace fa::setup_detail
