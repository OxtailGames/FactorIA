// DirectStorage, Microsoft's runtime the Windows game reads the gdeflate blocks of game.pak with
// (docs/design/ARCHITECTURE_FILES.md, "DirectStorage"), and `setup directstorage`, which fetches its two redistributable
// DLLs. The pinned package and its hash are in fa/tooling/setup.h.
//
//   <home>/tools/directstorage/<version>/dstorage.dll, dstoragecore.dll (+ LICENSE.txt and NOTICES.txt, the package's
//   license and third-party notices)
//
// The download is the NuGet package Microsoft.Direct3D.DirectStorage at the pinned version (a .nupkg is a zip), checked
// against the SHA-256 kept in setup.h and unpacked; only native/bin/x64/dstorage.dll and dstoragecore.dll are kept (the
// package's distributable_files.txt lists them as redistributable). Any host can install it: the DLLs are data a Windows
// export copies next to the game (export.pack.directStorage), not programs this computer runs. Off Windows the component
// is "unsupported" (nothing here needs it; `setup` installs it only when asked by name). Folders of older versions are
// removed once the new one is in place.
#include "fa/core/fs.h"
#include "setup_internal.h"

namespace fa {

std::string directstorage_install_dir(const SetupContext& context) {
    return fs::path_to_utf8(fs::path_from_utf8(context.home_dir()) / "tools" / "directstorage" /
                            kSetupDirectStorage.version);
}

std::string installed_directstorage_dir(const SetupContext& context) {
    const std::filesystem::path dir = fs::path_from_utf8(directstorage_install_dir(context));
    for (const char* file : kSetupDirectStorageFiles)
        if (!setup_detail::is_file(dir / file)) return {};
    return fs::path_to_utf8(dir);
}

}  // namespace fa

namespace fa::setup_detail {

namespace {

std::string package_url(const DirectStoragePackage& p) {
    return std::string("https://api.nuget.org/v3-flatcontainer/microsoft.direct3d.directstorage/") + p.version +
           "/microsoft.direct3d.directstorage." + p.version + ".nupkg";
}

}  // namespace

SetupComponent directstorage_status(const SetupContext& ctx) {
    SetupComponent c;
    c.id = "directstorage";
    c.title = "DirectStorage runtime (Windows games read game.pak with it)";
    c.canInstall = true;
    if (const std::string dir = installed_directstorage_dir(ctx); !dir.empty()) {
        c.state = "installed";
        c.paths.emplace_back("directstorage", dir);
        c.details = std::string("DirectStorage ") + kSetupDirectStorage.version +
                    " (dstorage.dll, dstoragecore.dll, x64) is in " + dir +
                    ": a Windows release export with export.pack.directStorage copies them next to the game.";
        return c;
    }
    c.installSizeMb = kSetupDirectStorage.sizeMb;
    c.details = std::string("The install downloads the NuGet package Microsoft.Direct3D.DirectStorage ") +
                kSetupDirectStorage.version +
                " (SHA-256 checked) and keeps its x64 dstorage.dll and dstoragecore.dll in " +
                directstorage_install_dir(ctx) + ".";
    if (ctx.host_os() != "windows") {
        // Not needed here: nothing on this computer runs it. `factoria setup directstorage` still installs it, for a
        // Windows release export made on this computer.
        c.state = "unsupported";
        c.details = "Not needed on this computer (DirectStorage is Windows only). " + c.details +
                    " Install it here only to make Windows release exports with export.pack.directStorage on this "
                    "computer: `factoria setup directstorage`.";
        return c;
    }
    c.state = "missing";
    c.problems.push_back(
        "A Windows release export with export.pack.directStorage ships the game without DirectStorage (its gdeflate "
        "blocks are then decompressed on the CPU): run `factoria setup directstorage`.");
    return c;
}

SetupResult directstorage_install(const SetupContext& ctx, const SetupInstallOptions& opt) {
    return directstorage_install_package(ctx, opt, kSetupDirectStorage, {});
}

SetupResult directstorage_install_package(const SetupContext& ctx, const SetupInstallOptions& opt,
                                          const DirectStoragePackage& pkg, const std::string& url) {
    Installer in(ctx, "directstorage");
    StepTimer timer;
    SetupStep s;
    s.id = "directstorage";
    s.title = std::string("DirectStorage ") + pkg.version;
    const stdfs::path dir = fs::path_from_utf8(directstorage_install_dir(ctx));
    if (const std::string found = installed_directstorage_dir(ctx); !opt.force && !found.empty()) {
        s.outcome = "skipped";
        s.detail = "already installed: " + found;
        s.path = found;
        in.add_step(s);
        in.report.paths = {{"directstorage", found}};
        return in.finish();
    }
    const stdfs::path file = in.staging() / "directstorage.zip";  // a .nupkg is a zip; extract_archive goes by the name
    std::uint64_t bytes = 0;
    const std::string what = std::string("DirectStorage ") + pkg.version + " (NuGet)";
    if (auto f = download_file(ctx, url.empty() ? package_url(pkg) : url, file, what, std::uint64_t(pkg.sizeMb) << 20,
                               &bytes))
        return in.fail(*f);
    if (auto f = verify_checksum(file, "sha256", pkg.sha256, what)) return in.fail(*f);
    const stdfs::path unpacked = in.make_staging_subdir("unpacked");
    if (auto f = extract_archive(ctx, file, unpacked)) return in.fail(*f);
    const stdfs::path ready = in.make_staging_subdir("ready");
    const char* const writable = "Check that the folder is writable and the disk is not full.";
    std::error_code ec;
    for (const char* name : kSetupDirectStorageFiles) {
        const stdfs::path from = unpacked / "native" / "bin" / "x64" / name;
        if (!is_file(from))
            return in.fail("failed",
                           make_error(what + " has no native/bin/x64/" + name + " (the package's layout changed)",
                                      "This is a bug in FactorIA's pin of the package; please report it."));
        stdfs::copy_file(from, ready / name, stdfs::copy_options::overwrite_existing, ec);
        if (ec)
            return in.fail("failed", make_error("Cannot copy " + std::string(name) + " into " +
                                                    fs::path_to_utf8(ready) + ": " + ec.message(),
                                                writable));
    }
    // The package's license and its third-party notices go with the DLLs (a game that ships them ships these too).
    for (const char* text : {"LICENSE.txt", "NOTICES.txt"})
        if (is_file(unpacked / text))
            stdfs::copy_file(unpacked / text, ready / text, stdfs::copy_options::overwrite_existing, ec);
    if (auto f = replace_dir(ready, dir)) return in.fail(*f);
    in.report.changed = true;
    s.outcome = "installed";
    s.detail = "x64 dstorage.dll and dstoragecore.dll from the NuGet package Microsoft.Direct3D.DirectStorage (SHA-256 "
               "checked)";
    s.path = fs::path_to_utf8(dir);
    s.downloadedBytes = bytes;
    s.seconds = timer.seconds();
    in.add_step(s);
    // The folders of older pinned versions are no longer used.
    const stdfs::path keep = fs::path_from_utf8(pkg.version);
    for (stdfs::directory_iterator it(dir.parent_path(), ec), end; !ec && it != end; it.increment(ec))
        if (it->is_directory() && it->path().filename() != keep) {
            std::error_code rm;
            fs::remove_tree(it->path(), rm);
        }
    in.report.paths = {{"directstorage", fs::path_to_utf8(dir)}};
    in.report.nextSteps.push_back(
        "A Windows release export (`factoria export --release --platform windows`) with export.pack.directStorage "
        "copies them next to the game, which then reads its gdeflate blocks through DirectStorage.");
    return in.finish();
}

}  // namespace fa::setup_detail
