// DXC, Microsoft's DirectX Shader Compiler, and `setup dxc`, which installs the pinned release. The engine's ray tracing kernels
// (engine/render/shaders/rt/*.hlsl, tools/shaders/compile_rt_shaders.sh) are compiled with it into DXIL (D3D12) and SPIR-V
// (Vulkan); the generated headers are committed, so only a contributor who edits a kernel needs it, and a game never ships it
// (docs/design/ARCHITECTURE_RENDERING_RAYTRACING_SHADERS.md). The pinned builds and their hashes are in fa/tooling/setup.h.
//
//   <home>/tools/dxc/<version>/bin/dxc[.exe]  (+ dxv, and the DLLs beside dxc.exe on Windows)
//                              lib/libdxcompiler.so, libdxil.so  (Linux)
//                              LICENSE-LLVM.txt, LICENSE-MS.txt ... (the licence files of the release asset)
//
// The download is one official release asset of github.com/microsoft/DirectXShaderCompiler per host, checked against the
// SHA-256 kept in setup.h. Microsoft ships no macOS build and no Linux Arm build: there the status is "unsupported" and the
// install refuses with where the DXIL comes from instead (the Linux CI job). $FA_DXC_DIR points at a DXC folder of your own.
// Folders of older versions are removed once the new one is in place.
#include <algorithm>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "setup_internal.h"

namespace fa {

const DxcBuild* dxc_build(const SetupContext& context) {
    const std::string os = context.host_os(), arch = context.host_architecture();
    for (const DxcBuild& b : kSetupDxcBuilds)
        if (os == b.host && arch == b.arch) return &b;
    return nullptr;
}

std::string dxc_install_dir(const SetupContext& context) {
    return fs::path_to_utf8(fs::path_from_utf8(context.home_dir()) / "tools" / "dxc" / kSetupDxcVersion);
}

std::string find_dxc(const SetupContext& context) {
    const std::string exe = "dxc" + setup_detail::exe_suffix(context.host_os());
    if (std::string env = context.env ? context.env("FA_DXC_DIR") : std::string(); !env.empty()) {
        const std::filesystem::path dir = fs::path_from_utf8(env);
        for (const std::filesystem::path& candidate : {dir / "bin" / exe, dir / exe})
            if (setup_detail::is_file(candidate)) return fs::path_to_utf8(candidate);
        return {};
    }
    const DxcBuild* build = dxc_build(context);
    if (!build) return {};
    const std::filesystem::path dir = fs::path_from_utf8(dxc_install_dir(context));
    // Without its signer library (dxil.dll, libdxil.so) dxc writes DXIL no driver accepts: not an install.
    if (setup_detail::is_file(dir / "bin" / exe) && setup_detail::is_file(dir / fs::path_from_utf8(build->signer)))
        return fs::path_to_utf8(dir / "bin" / exe);
    return {};
}

}  // namespace fa

namespace fa::setup_detail {

namespace {

std::string dxc_url(const DxcBuild& b) {
    return std::string("https://github.com/microsoft/DirectXShaderCompiler/releases/download/") + kSetupDxcRelease +
           "/" + b.asset;
}

std::string dxc_archive_name(const DxcBuild& b) {
    const std::string asset = b.asset;
    return "dxc" + std::string(ends_with(asset, ".zip") ? ".zip" : ".tar.gz");
}

Error unsupported_error(const SetupContext& ctx) {
    return make_error(
        "DXC has no build for " + ctx.host_os() + "-" + ctx.host_architecture() +
            ": Microsoft publishes the DirectX Shader Compiler for Windows (x64, arm64) and Linux x86_64 only.",
        "The engine's DXIL is generated ahead of time and committed: when you change a ray tracing kernel "
        "(engine/render/shaders/rt/*.hlsl) on this computer, commit the change and the Linux CI job regenerates the "
        "DXIL "
        "and SPIR-V headers, fails with the diff and uploads them as the artifact `rt-shader-headers` to commit "
        "(docs/design/ARCHITECTURE_RENDERING_RAYTRACING_SHADERS.md, \"DXC and DXIL\"). To run DXC here anyway, build "
        "it "
        "and set FA_DXC_DIR to its folder.");
}

// Copies every regular file of `from` into `to` (created), keeping the execute bits.
std::optional<Fail> copy_files(const stdfs::path& from, const stdfs::path& to, const std::string& what) {
    std::error_code ec;
    stdfs::create_directories(to, ec);
    for (stdfs::directory_iterator it(from, ec), end; !ec && it != end; it.increment(ec)) {
        if (!it->is_regular_file()) continue;
        std::error_code cp;
        stdfs::copy_file(it->path(), to / it->path().filename(), stdfs::copy_options::overwrite_existing, cp);
        if (cp)
            return Fail{"failed", make_error("Cannot copy " + fs::path_to_utf8(it->path().filename()) + " of " + what +
                                                 " into " + fs::path_to_utf8(to) + ": " + cp.message(),
                                             "Check that the folder is writable and the disk is not full.")};
    }
    return std::nullopt;
}

}  // namespace

SetupComponent dxc_status(const SetupContext& ctx) {
    SetupComponent c;
    c.id = "dxc";
    c.title = "DXC (compiles the engine's ray tracing kernels to DXIL; only to edit them)";
    const DxcBuild* build = dxc_build(ctx);
    const std::string envDir = ctx.env ? ctx.env("FA_DXC_DIR") : std::string();
    if (const std::string found = find_dxc(ctx); !found.empty()) {
        c.state = "installed";
        c.canInstall = build != nullptr;
        c.paths.emplace_back("dxc", found);
        c.details = std::string("DXC ") + (envDir.empty() ? kSetupDxcVersion : "(named by $FA_DXC_DIR)") +
                    " found: " + found +
                    ". tools/shaders/compile_rt_shaders.sh compiles the ray tracing kernels with it.";
        return c;
    }
    if (!build) {
        c.state = "unsupported";
        c.details = unsupported_error(ctx).message + " " + unsupported_error(ctx).hint;
        return c;
    }
    c.canInstall = true;
    c.state = "missing";
    c.installSizeMb = build->sizeMb;
    c.details =
        std::string("The install downloads DXC ") + kSetupDxcVersion + " (" + build->asset +
        " of github.com/microsoft/DirectXShaderCompiler, SHA-256 checked, licence: LLVM and Microsoft's, in the "
        "folder) into " +
        dxc_install_dir(ctx) +
        ". Only a contributor who edits a ray tracing kernel needs it: the generated DXIL is committed and a game "
        "never ships DXC.";
    if (!envDir.empty())
        c.problems.push_back("$FA_DXC_DIR names " + envDir + ", which holds no bin/dxc" + exe_suffix(ctx.host_os()) +
                             ": fix the path or unset the variable.");
    return c;
}

SetupResult dxc_install(const SetupContext& ctx, const SetupInstallOptions& opt) {
    return dxc_install_build(ctx, opt, dxc_build(ctx), {});
}

SetupResult dxc_install_build(const SetupContext& ctx, const SetupInstallOptions& opt, const DxcBuild* build,
                              const std::string& url) {
    Installer in(ctx, "dxc");
    if (!build) return in.fail("unsupported", unsupported_error(ctx));
    StepTimer timer;
    SetupStep s;
    s.id = "dxc";
    s.title = std::string("DXC ") + kSetupDxcVersion;
    const stdfs::path dir = fs::path_from_utf8(dxc_install_dir(ctx));
    if (const std::string found = find_dxc(ctx); !opt.force && !found.empty()) {
        s.outcome = "skipped";
        s.detail = "already available: " + found;
        s.path = found;
        in.add_step(s);
        in.report.paths = {{"dxc", found}};
        return in.finish();
    }
    const stdfs::path file = in.staging() / dxc_archive_name(*build);
    std::uint64_t bytes = 0;
    const std::string what = std::string("DXC ") + kSetupDxcVersion;
    if (auto f = download_file(ctx, url.empty() ? dxc_url(*build) : url, file, what, std::uint64_t(build->sizeMb) << 20,
                               &bytes))
        return in.fail(*f);
    if (auto f = verify_checksum(file, "sha256", build->sha256, what)) return in.fail(*f);
    const stdfs::path unpacked = in.make_staging_subdir("unpacked");
    if (auto f = extract_archive(ctx, file, unpacked)) return in.fail(*f);
    const stdfs::path ready = in.make_staging_subdir("ready");
    const stdfs::path binFrom = unpacked / fs::path_from_utf8(build->binDir);
    const std::string exeName = "dxc" + exe_suffix(ctx.host_os());
    if (!is_file(binFrom / exeName))
        return in.fail("failed", make_error(what + " has no " + std::string(build->binDir) + "/" + exeName +
                                                " (the release's layout changed)",
                                            "This is a bug in FactorIA's pin of the release; please report it."));
    if (auto f = copy_files(binFrom, ready / "bin", what)) return in.fail(*f);
    if (*build->libDir)
        if (auto f = copy_files(unpacked / fs::path_from_utf8(build->libDir), ready / "lib", what)) return in.fail(*f);
    // The licence files of the release (LLVM's, Microsoft's) stay with the compiler.
    std::error_code ec;
    for (stdfs::directory_iterator it(unpacked, ec), end; !ec && it != end; it.increment(ec)) {
        const std::string name = to_lower(fs::path_to_utf8(it->path().filename()));
        if (it->is_regular_file() && (name.rfind("licen", 0) == 0 || name == "releasenotes.md")) {
            std::error_code cp;
            stdfs::copy_file(it->path(), ready / it->path().filename(), stdfs::copy_options::overwrite_existing, cp);
        }
    }
    if (!is_file(ready / fs::path_from_utf8(build->signer)))
        return in.fail("failed", make_error(what + " has no " + std::string(build->signer) +
                                                ", the library that signs DXIL (the release's layout changed)",
                                            "This is a bug in FactorIA's pin of the release; please report it."));
    make_tree_executable(ready / "bin");
    if (auto f = replace_dir(ready, dir)) return in.fail(*f);
    in.report.changed = true;
    s.outcome = "installed";
    s.detail = std::string(build->asset) + " from github.com/microsoft/DirectXShaderCompiler (SHA-256 checked)";
    s.path = fs::path_to_utf8(dir);
    s.downloadedBytes = bytes;
    s.seconds = timer.seconds();
    in.add_step(s);
    // The folders of older pinned versions are no longer used.
    const stdfs::path keep = fs::path_from_utf8(kSetupDxcVersion);
    for (stdfs::directory_iterator it(dir.parent_path(), ec), end; !ec && it != end; it.increment(ec))
        if (it->is_directory() && it->path().filename() != keep) {
            std::error_code rm;
            fs::remove_tree(it->path(), rm);
        }
    in.report.paths = {{"dxc", fs::path_to_utf8(dir / "bin" / exeName)}};
    in.report.nextSteps.push_back(
        "tools/shaders/compile_rt_shaders.sh compiles the ray tracing kernels with it (it also reads $FA_DXC_DIR). "
        "Licences: the LLVM and Microsoft licence files of the release are in " +
        fs::path_to_utf8(dir) + ".");
    return in.finish();
}

}  // namespace fa::setup_detail
