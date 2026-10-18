// sokol-shdc, the shader cross-compiler custom materials are compiled with (docs/design/CUSTOM_SHADERS.md): where it is
// looked for. The pinned binaries and their hashes are in fa/tooling/setup.h.
#include "fa/tooling/export.h"
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
    const std::filesystem::path next = (context.executableDir.empty() ? executable_dir() : std::filesystem::path(context.executableDir)) / exe;
    if (setup_detail::is_file(next)) return next.string();
    const std::filesystem::path installed = std::filesystem::path(sokol_shdc_install_dir(context)) / exe;
    if (setup_detail::is_file(installed)) return installed.string();
    return {};
}

}  // namespace fa
