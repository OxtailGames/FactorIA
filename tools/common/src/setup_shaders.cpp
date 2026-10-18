// sokol-shdc, the shader cross-compiler custom materials are compiled with (docs/design/CUSTOM_SHADERS.md): where it is
// looked for, and `setup shaders`, which installs the pinned binary. The pinned binaries and their hashes are in
// fa/tooling/setup.h.
//
//   <home>/tools/sokol-shdc/<commit>/sokol-shdc[.exe]
//
// The download is the one file of github.com/floooh/sokol-tools-bin at the pinned commit (no archive), checked against the
// SHA-256 kept in setup.h. Folders of older commits are removed once the new one is in place.
#include "setup_internal.h"

namespace fa {

const SokolShdcBinary* sokol_shdc_binary(const SetupContext& context) {
    const std::string os = context.host_os(), arch = context.host_architecture();
    for (const SokolShdcBinary& b : kSetupSokolShdcBinaries)
        if (os == b.host && (*b.arch == '\0' || arch == b.arch)) return &b;
    return nullptr;
}

std::string sokol_shdc_install_dir(const SetupContext& context) {
    return (std::filesystem::path(context.home_dir()) / "tools" / "sokol-shdc" / kSetupSokolShdcCommit).string();
}

std::string find_sokol_shdc(const SetupContext& context) {
    if (std::string env = context.env ? context.env("SOKOL_SHDC") : std::string(); !env.empty()) return env;
    const std::string exe = "sokol-shdc" + setup_detail::exe_suffix(context.host_os());
    const std::filesystem::path next = setup_detail::exe_dir(context) / exe;
    if (setup_detail::is_file(next)) return next.string();
    const std::filesystem::path installed = std::filesystem::path(sokol_shdc_install_dir(context)) / exe;
    if (setup_detail::is_file(installed)) return installed.string();
    return {};
}

}  // namespace fa

namespace fa::setup_detail {

namespace {

std::string shdc_file(const SetupContext& ctx) { return "sokol-shdc" + exe_suffix(ctx.host_os()); }

std::string shdc_url(const SokolShdcBinary& b, const SetupContext& ctx) {
    return std::string("https://raw.githubusercontent.com/floooh/sokol-tools-bin/") + kSetupSokolShdcCommit + "/bin/" + b.dir +
           "/" + shdc_file(ctx);
}

int shdc_size_mb(const std::string& host) { return host == "windows" ? 8 : 12; }

const char* const kUnsupportedHint =
    "Compile on Windows, Linux or macOS (x64 or arm64), or point SOKOL_SHDC at a sokol-shdc built for this computer "
    "(github.com/floooh/sokol-tools).";

}  // namespace

SetupComponent shaders_status(const SetupContext& ctx) {
    SetupComponent c;
    c.id = "shaders";
    c.title = "sokol-shdc (shader compiler of custom materials)";
    const SokolShdcBinary* bin = sokol_shdc_binary(ctx);
    if (!bin) {
        c.state = "unsupported";
        c.details = "There is no sokol-shdc build for " + ctx.host_os() + "-" + ctx.host_architecture() + ". " +
                    kUnsupportedHint;
        return c;
    }
    c.canInstall = true;
    const std::string envPath = ctx.env ? ctx.env("SOKOL_SHDC") : std::string();
    const std::string found = find_sokol_shdc(ctx);
    if (!found.empty() && is_file(found)) {
        c.state = "installed";
        c.paths.emplace_back("sokol-shdc", found);
        c.details = "sokol-shdc found" + std::string(found == envPath ? " (named by $SOKOL_SHDC)" : "") + ": " + found +
                    ".";
        return c;
    }
    c.state = "missing";
    c.installSizeMb = shdc_size_mb(ctx.host_os());
    c.details = std::string("The install downloads sokol-shdc (sokol-tools-bin commit ") +
                std::string(kSetupSokolShdcCommit).substr(0, 7) + ", SHA-256 checked) into " + sokol_shdc_install_dir(ctx) + ".";
    if (!envPath.empty())
        c.problems.push_back("$SOKOL_SHDC names " + envPath + ", which is not a file: fix the path or unset the variable.");
    c.problems.push_back("Custom materials (*.material.json) are compiled with sokol-shdc: run `factoria setup shaders`.");
    return c;
}

SetupResult shaders_install(const SetupContext& ctx, const SetupInstallOptions& opt) {
    return shaders_install_binary(ctx, opt, sokol_shdc_binary(ctx));
}

SetupResult shaders_install_binary(const SetupContext& ctx, const SetupInstallOptions& opt, const SokolShdcBinary* bin) {
    Installer in(ctx, "shaders");
    if (!bin)
        return in.fail("unsupported",
                       make_error("There is no sokol-shdc build for " + ctx.host_os() + "-" + ctx.host_architecture() + ".",
                                  kUnsupportedHint));
    StepTimer timer;
    SetupStep s;
    s.id = "sokol-shdc";
    s.title = "sokol-shdc";
    const stdfs::path dir = sokol_shdc_install_dir(ctx);
    const stdfs::path dest = dir / shdc_file(ctx);
    if (const std::string found = find_sokol_shdc(ctx); !opt.force && !found.empty() && is_file(found)) {
        s.outcome = "skipped";
        s.detail = "already available: " + found;
        s.path = found;
        in.add_step(s);
        in.report.paths = {{"sokol-shdc", found}};
        return in.finish();
    }
    const stdfs::path file = in.staging() / shdc_file(ctx);
    std::uint64_t bytes = 0;
    const std::uint64_t expected = std::uint64_t(shdc_size_mb(ctx.host_os())) << 20;
    if (auto f = download_file(ctx, shdc_url(*bin, ctx), file, "sokol-shdc", expected, &bytes)) return in.fail(*f);
    if (auto f = verify_checksum(file, "sha256", bin->sha256, "sokol-shdc")) return in.fail(*f);
    std::error_code ec;
    stdfs::create_directories(dir, ec);
    const char* const writable = "Check that the folder is writable and the disk is not full.";
    if (ec) return in.fail("failed", make_error("Cannot create " + dir.string() + ": " + ec.message(), writable));
    stdfs::remove(dest, ec);
    stdfs::rename(file, dest, ec);
    if (ec) {  // another volume
        stdfs::copy_file(file, dest, stdfs::copy_options::overwrite_existing, ec);
        if (ec) return in.fail("failed", make_error("Cannot write " + dest.string() + ": " + ec.message(), writable));
    }
    make_executable(dest);
    in.report.changed = true;
    s.outcome = "installed";
    s.detail = "from github.com/floooh/sokol-tools-bin (SHA-256 checked)";
    s.path = dest.string();
    s.downloadedBytes = bytes;
    s.seconds = timer.seconds();
    in.add_step(s);
    // The folders of older pinned commits are no longer used.
    const std::string keep = kSetupSokolShdcCommit;
    for (stdfs::directory_iterator it(dir.parent_path(), ec), end; !ec && it != end; it.increment(ec))
        if (it->is_directory() && it->path().filename().string() != keep) {
            std::error_code rm;
            stdfs::remove_all(it->path(), rm);
        }
    in.report.paths = {{"sokol-shdc", dest.string()}};
    in.report.nextSteps.push_back("`factoria validate` and `factoria run` compile the custom materials (*.material.json) of a game with it.");
    return in.finish();
}

}  // namespace fa::setup_detail
