// The vendor upscaler seam of M78 (render_upscale_vendor.h): the library finder and loader, the provider table, the GPU's maker.
#include "render_upscale_vendor.h"

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <system_error>
#include <vector>

#include "fa/core/fs.h"

#include "render_upscale_dlss.h"
#include "render_upscale_fsr.h"
#include "render_upscale_xess.h"

#if defined(_WIN32)
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#elif defined(__APPLE__)
#include <mach-o/dyld.h>
#endif

namespace fa::render {

namespace {

namespace stdfs = std::filesystem;

// ---- the folders of this process --------------------------------------------------------------------------------------------------

// A variable of the environment as a path. On Windows it is read wide, so a user name with accents survives (getenv goes through the
// ANSI code page).
stdfs::path env_path(const char* name) {
    if (!name || !*name) return {};
#if defined(_WIN32)
    std::wstring w;
    for (const char* c = name; *c; ++c) w.push_back(wchar_t(static_cast<unsigned char>(*c)));  // names are ASCII
    std::wstring buf(2048, L'\0');
    const DWORD n = GetEnvironmentVariableW(w.c_str(), buf.data(), DWORD(buf.size()));
    if (n == 0 || n >= buf.size()) return {};
    buf.resize(n);
    return stdfs::path(buf);
#else
    const char* v = std::getenv(name);
    return v && *v ? fs::path_from_utf8(v) : stdfs::path();
#endif
}

stdfs::path executable_folder() {
#if defined(_WIN32)
    std::wstring buf(32768, L'\0');
    const DWORD n = GetModuleFileNameW(nullptr, buf.data(), DWORD(buf.size()));
    if (n == 0 || n >= buf.size()) return {};
    buf.resize(n);
    return stdfs::path(buf).parent_path();
#elif defined(__APPLE__)
    char buf[4096];
    std::uint32_t size = sizeof(buf);
    std::error_code ec;
    if (_NSGetExecutablePath(buf, &size) != 0) return {};
    return stdfs::weakly_canonical(fs::path_from_utf8(buf), ec).parent_path();
#elif defined(__linux__)
    std::error_code ec;
    const stdfs::path self = stdfs::read_symlink("/proc/self/exe", ec);
    return ec ? stdfs::path() : self.parent_path();
#else
    return {};
#endif
}

// factoria_home: $FACTORIA_HOME, else <home>/.factoria (the folder `factoria setup` installs into).
stdfs::path factoria_home() {
    if (stdfs::path h = env_path("FACTORIA_HOME"); !h.empty()) return h;
#if defined(_WIN32)
    stdfs::path user = env_path("USERPROFILE");
#else
    stdfs::path user = env_path("HOME");
#endif
    return user.empty() ? stdfs::path() : user / ".factoria";
}

// ---- finding a library ------------------------------------------------------------------------------------------------------------

// A version folder name as dotted numbers: "2.10.0" -> {2, 10, 0}; a part that is not a number is kept as text.
struct VersionPart {
    bool number = false;
    unsigned long long value = 0;
    std::string text;
};
std::vector<VersionPart> version_parts(const std::string& name) {
    std::vector<VersionPart> out;
    std::size_t i = 0;
    while (i <= name.size()) {
        std::size_t j = name.find_first_of(".-_", i);
        if (j == std::string::npos) j = name.size();
        const std::string piece = name.substr(i, j - i);
        VersionPart p;
        p.text = piece;
        const bool digits = !piece.empty() && piece.size() <= 18 && std::all_of(piece.begin(), piece.end(), [](char c) {
            return std::isdigit(static_cast<unsigned char>(c)) != 0;
        });
        if (digits) {
            p.number = true;
            p.value = std::stoull(piece);
        }
        out.push_back(std::move(p));
        i = j + 1;
    }
    return out;
}
bool version_less(const std::string& a, const std::string& b) {
    const std::vector<VersionPart> pa = version_parts(a), pb = version_parts(b);
    const std::size_t n = std::min(pa.size(), pb.size());
    for (std::size_t i = 0; i < n; ++i) {
        if (pa[i].number != pb[i].number) return !pa[i].number;  // a number is newer than a word
        if (pa[i].number ? pa[i].value != pb[i].value : pa[i].text != pb[i].text)
            return pa[i].number ? pa[i].value < pb[i].value : pa[i].text < pb[i].text;
    }
    if (pa.size() != pb.size()) return pa.size() < pb.size();
    return a < b;
}

bool is_file(const stdfs::path& p) {
    std::error_code ec;
    return stdfs::is_regular_file(p, ec);
}

class DiskLibrary final : public VendorLibrary {
public:
#if defined(_WIN32)
    DiskLibrary(HMODULE handle, std::string path) : handle_(handle), path_(std::move(path)) {}
    void* symbol(const char* name) override {
        return reinterpret_cast<void*>(GetProcAddress(handle_, name));  // NOLINT: the export's address
    }
#else
    explicit DiskLibrary(std::string path) : path_(std::move(path)) {}
    void* symbol(const char*) override { return nullptr; }
#endif
    const std::string& path() const override { return path_; }

private:
#if defined(_WIN32)
    HMODULE handle_ = nullptr;  // never freed: see VendorLibrary
#endif
    std::string path_;
};

class DiskLoader final : public VendorLoader {
public:
    stdfs::path find(const VendorLibrarySpec& spec, std::string* why) override {
        return find_vendor_library(spec, vendor_search_roots(spec), why);
    }
    std::unique_ptr<VendorLibrary> load(const stdfs::path& path, std::string* why) override {
#if defined(_WIN32)
        std::error_code ec;
        stdfs::path full = path.is_relative() ? stdfs::absolute(path, ec) : path;  // the flag below needs a full path
        if (ec) full = path;
        // The library's own folder and the system's satisfy its imports; the current folder never does.
        constexpr DWORD kFlags = LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR | LOAD_LIBRARY_SEARCH_DEFAULT_DIRS;
        HMODULE h = LoadLibraryExW(full.c_str(), nullptr, kFlags);
        if (!h) {
            if (why)
                *why = "Windows could not load " + fs::path_to_utf8(full) + " (error " +
                       std::to_string(GetLastError()) +
                       "; an x64 game needs the x64 library and its own dependencies next to it)";
            return nullptr;
        }
        return std::make_unique<DiskLibrary>(h, fs::path_to_utf8(full));
#else
        (void)path;
        if (why) *why = "the vendor upscaler libraries are loaded on Windows only";
        return nullptr;
#endif
    }
};

VendorLoader* g_loader_override = nullptr;

// ---- the providers ----------------------------------------------------------------------------------------------------------------

constexpr unsigned backend_bit(gpu::Backend b) { return 1u << unsigned(b); }

const char* backend_label(gpu::Backend b) {
    switch (b) {
        case gpu::Backend::Gl: return "OpenGL";
        case gpu::Backend::Gles3: return "OpenGL ES";
        case gpu::Backend::WebGl2: return "WebGL2";
        case gpu::Backend::D3d11: return "D3D11";
        case gpu::Backend::Metal: return "Metal";
        case gpu::Backend::D3d12: return "D3D12";
        case gpu::Backend::Vulkan: return "Vulkan";
        case gpu::Backend::Recording: return "no GPU (a recording device)";
    }
    return "an unknown backend";
}

// "D3D12, Vulkan or D3D11": the backends of `mask`, the engine's first choices first.
std::string backend_list(unsigned mask) {
    std::vector<const char*> names;
    for (gpu::Backend b : {gpu::Backend::D3d12, gpu::Backend::Vulkan, gpu::Backend::D3d11})
        if (mask & backend_bit(b)) names.push_back(backend_label(b));
    std::string out;
    for (std::size_t i = 0; i < names.size(); ++i)
        out += (i == 0 ? "" : i + 1 == names.size() ? " or " : ", ") + std::string(names[i]);
    return out;
}

std::string describe_gpu(GpuVendor v) {
    switch (v) {
        case GpuVendor::Nvidia: return "an NVIDIA GPU";
        case GpuVendor::Amd: return "an AMD GPU";
        case GpuVendor::Intel: return "an Intel GPU";
        case GpuVendor::Apple: return "an Apple GPU";
        case GpuVendor::Other: return "not recognised as NVIDIA";
        case GpuVendor::None: break;
    }
    return "not known (no GPU is open)";
}

std::array<std::unique_ptr<VendorUpscaler>, kVendorUpscalerCount> make_providers() {
    std::array<std::unique_ptr<VendorUpscaler>, kVendorUpscalerCount> t;
    t[0] = make_dlss_provider();
    t[1] = make_xess_provider();
    t[2] = make_fsr_provider();
    return t;
}

VendorUpscaler* g_provider_override[kVendorUpscalerCount] = {};

}  // namespace

stdfs::path find_vendor_library(const VendorLibrarySpec& spec, const VendorSearchRoots& roots, std::string* why) {
    std::string tried;
    const auto note = [&](const std::string& place) { tried += (tried.empty() ? "" : "; ") + place; };
    if (!roots.envDir.empty()) {
        // An explicit choice: the folder $FA_..._DIR names, and no other when it does not hold the library.
        const stdfs::path p = roots.envDir / spec.fileName;
        if (is_file(p)) return p;
        if (why)
            *why = std::string(spec.fileName) + " is not in " + fs::path_to_utf8(roots.envDir) + ", the folder $" +
                   spec.dirEnv + " names";
        return {};
    }
    note(std::string("$") + spec.dirEnv + " is not set");
    if (!roots.exeDir.empty()) {
        const stdfs::path p = roots.exeDir / spec.fileName;
        if (is_file(p)) return p;
        note(std::string("not next to the game in ") + fs::path_to_utf8(roots.exeDir));
    }
    if (!roots.home.empty()) {
        const stdfs::path base = roots.home / "tools" / spec.setupId;
        std::error_code ec;
        std::string newest;
        stdfs::path newestPath;
        for (stdfs::directory_iterator it(base, ec), end; !ec && it != end; it.increment(ec)) {
            std::error_code e2;
            if (!it->is_directory(e2)) continue;
            const std::string name = fs::path_to_utf8(it->path().filename());
            const stdfs::path p = it->path() / spec.fileName;
            if (!is_file(p) || (!newest.empty() && !version_less(newest, name))) continue;
            newest = name;
            newestPath = p;
        }
        if (!newestPath.empty()) return newestPath;
        note("no version of it in " + fs::path_to_utf8(base));
    }
    if (why) *why = std::string(spec.fileName) + " was not found: " + tried;
    return {};
}

VendorSearchRoots vendor_search_roots(const VendorLibrarySpec& spec) {
    VendorSearchRoots r;
    r.envDir = env_path(spec.dirEnv);
    if (!r.envDir.empty() && r.envDir.is_relative()) {
        std::error_code ec;
        const stdfs::path abs = stdfs::absolute(r.envDir, ec);
        if (!ec) r.envDir = abs;
    }
    r.exeDir = executable_folder();
    r.home = factoria_home();
    return r;
}

VendorLoader& vendor_loader() {
    if (g_loader_override) return *g_loader_override;
    static DiskLoader loader;
    return loader;
}
void set_vendor_loader_for_test(VendorLoader* fake) { g_loader_override = fake; }

VendorUpscaler& vendor_provider(int index) {
    // Never destroyed: a Renderer that a static object holds (a test's shared one) shuts down during the static destruction of the
    // process, and may be the first to ask for a provider then; a static that is made that late would already be gone.
    static auto* const providers =
        new std::array<std::unique_ptr<VendorUpscaler>, kVendorUpscalerCount>(make_providers());
    const int i = std::clamp(index, 0, kVendorUpscalerCount - 1);
    return g_provider_override[i] ? *g_provider_override[i] : *(*providers)[std::size_t(i)];
}
void set_vendor_provider_for_test(int index, VendorUpscaler* fake) {
    if (index >= 0 && index < kVendorUpscalerCount) g_provider_override[index] = fake;
}

GpuVendor gpu_vendor_from_identity(const gpu::GpuIdentity& identity) {
    gpu::GpuVendor v = identity.vendor;
    if (v == gpu::GpuVendor::Unknown && identity.vendorId != 0) v = gpu::gpu_vendor_from_pci(identity.vendorId);
    switch (v) {
        case gpu::GpuVendor::Nvidia: return GpuVendor::Nvidia;
        case gpu::GpuVendor::Amd: return GpuVendor::Amd;
        case gpu::GpuVendor::Intel: return GpuVendor::Intel;
        case gpu::GpuVendor::Apple: return GpuVendor::Apple;
        case gpu::GpuVendor::Microsoft:
        case gpu::GpuVendor::Other: return GpuVendor::Other;
        case gpu::GpuVendor::Unknown: break;
    }
    return GpuVendor::None;
}

GpuVendor gpu_vendor_of(const gpu::Device& device) {
    switch (device.backend()) {
        case gpu::Backend::Metal: return GpuVendor::Apple;
        case gpu::Backend::Recording: return GpuVendor::None;
        default: break;
    }
    // A GL driver whose vendor string is not known, or an API that gave no id: some other maker (the SDKs of NVIDIA and Intel are not for it).
    const GpuVendor v = gpu_vendor_from_identity(device.info().gpu);
    return v == GpuVendor::None ? GpuVendor::Other : v;
}

VendorEnv vendor_env_of(const gpu::Device& device) {
    VendorEnv e;
    e.backend = device.backend();
    e.vendor = gpu_vendor_of(device);
    e.device = &device;  // borrowed for the probe: the providers read its native objects
    // M78-P2b: the extension lists the creation hooks enabled go into e.vulkanInstanceExtensions / e.vulkanDeviceExtensions.
    return e;
}

const char* vendor_backend_label(gpu::Backend backend) { return backend_label(backend); }
std::string vendor_describe_gpu(GpuVendor vendor) { return describe_gpu(vendor); }

std::string vendor_environment_problem(const VendorUpscaler& provider, const VendorEnv& env) {
    const std::string name(provider.name());
    if (!(provider.backends() & backend_bit(env.backend)))
        return name + " needs " + backend_list(provider.backends()) + "; this game runs on " +
               backend_label(env.backend) + ".";
    if (!env.windows) return name + " works on Windows only; this system is not Windows.";
    return {};
}

}  // namespace fa::render
