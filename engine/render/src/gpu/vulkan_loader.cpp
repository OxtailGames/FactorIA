// The Vulkan loader, opened at run time (docs/design/ARCHITECTURE_RENDERING_VULKAN.md): no Vulkan
// library is linked, so a binary without a Vulkan driver still starts and the error says what to install.
#include "gpu/vulkan_device.h"

#if defined(FA_VULKAN_BACKEND)

#include <string>
#include <vector>

#if defined(_WIN32)
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#else
#include <dlfcn.h>
#endif
#if defined(__APPLE__)
#include <unistd.h>

#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <mutex>
#endif

namespace fa::gpu::vk {

namespace {

#if defined(_WIN32)
std::wstring widen(const std::string& utf8) {
    if (utf8.empty()) return {};
    const int n = MultiByteToWideChar(CP_UTF8, 0, utf8.data(), int(utf8.size()), nullptr, 0);
    if (n <= 0) return {};
    std::wstring w(std::size_t(n), L'\0');
    MultiByteToWideChar(CP_UTF8, 0, utf8.data(), int(utf8.size()), w.data(), n);
    return w;
}

void* open_one(const std::string& path, std::string& why) {
    const std::wstring w = widen(path);
    // A bare name (vulkan-1.dll) only from System32, where the loader is installed, never from the current or the
    // game's directory (DLL planting); an absolute path from its own directory (its dependencies next to it) and the
    // default ones. A relative path with a directory keeps the classic search (LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR
    // refuses it).
    const bool bare = w.find_first_of(L"\\/:") == std::wstring::npos;
    const bool absolute =
        w.size() > 2 && ((w[1] == L':' && (w[2] == L'\\' || w[2] == L'/')) || (w[0] == L'\\' && w[1] == L'\\'));
    const DWORD flags = bare       ? LOAD_LIBRARY_SEARCH_SYSTEM32
                        : absolute ? LOAD_LIBRARY_SEARCH_DEFAULT_DIRS | LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR
                                   : 0;
    HMODULE m = w.empty() ? nullptr : LoadLibraryExW(w.c_str(), nullptr, flags);
    if (!m) why = "Windows error " + std::to_string(GetLastError());
    return reinterpret_cast<void*>(m);
}

void* symbol(void* handle, const char* name) {
    FARPROC p = GetProcAddress(reinterpret_cast<HMODULE>(handle), name);
    return reinterpret_cast<void*>(reinterpret_cast<void (*)()>(p));
}

void close_one(void* handle) { FreeLibrary(reinterpret_cast<HMODULE>(handle)); }
#else
void* open_one(const std::string& path, std::string& why) {
    void* h = dlopen(path.c_str(), RTLD_NOW | RTLD_LOCAL);
    if (!h) {
        const char* e = dlerror();
        why = e ? e : "dlopen failed";
    }
    return h;
}

void* symbol(void* handle, const char* name) { return dlsym(handle, name); }

void close_one(void* handle) { dlclose(handle); }
#endif

// Where the platform's loader is, in the order tried.
std::vector<std::string> search_list() {
#if defined(_WIN32)
    return {"vulkan-1.dll"};
#elif defined(__APPLE__)
    // The Homebrew prefixes are not on dyld's default search path; Vulkan on macOS is the tests' (MoltenVK) only.
    return {"libvulkan.1.dylib", "/opt/homebrew/lib/libvulkan.1.dylib", "/usr/local/lib/libvulkan.1.dylib",
            "libvulkan.dylib", "libMoltenVK.dylib"};
#else
    return {"libvulkan.so.1", "libvulkan.so"};
#endif
}

const char* install_hint() {
#if defined(_WIN32)
    return "install or update the GPU driver (it brings vulkan-1.dll), or set VulkanOptions::loaderPath";
#elif defined(__APPLE__)
    return "brew install vulkan-loader molten-vk vulkan-validationlayers (Vulkan on macOS is for the backend's tests "
           "only; games use Metal), or set VulkanOptions::loaderPath";
#elif defined(__ANDROID__)
    return "Vulkan needs Android 7 (API 24) or later with a Vulkan driver; use the sokol backend (GLES3) elsewhere";
#else
    return "install the loader and a driver (Debian/Ubuntu: sudo apt install libvulkan1 mesa-vulkan-drivers; the "
           "CPU driver lavapipe is in mesa-vulkan-drivers), or set VulkanOptions::loaderPath";
#endif
}

}  // namespace

Result<VulkanLibrary> open_vulkan_library(const std::string& path) {
    const std::vector<std::string> candidates = path.empty() ? search_list() : std::vector<std::string>{path};
    std::string tried;
    for (const std::string& c : candidates) {
        std::string why;
        void* h = open_one(c, why);
        if (!h) {
            tried += (tried.empty() ? "" : "; ") + c + ": " + why;
            continue;
        }
        auto gipa = reinterpret_cast<PFN_vkGetInstanceProcAddr>(symbol(h, "vkGetInstanceProcAddr"));
        if (!gipa) {
            close_one(h);
            tried += (tried.empty() ? "" : "; ") + c + ": has no vkGetInstanceProcAddr (not a Vulkan loader)";
            continue;
        }
        VulkanLibrary lib;
        lib.handle = h;
        lib.path = c;
        lib.getInstanceProcAddr = gipa;
        return lib;
    }
    return make_error("gpu vulkan: no Vulkan loader found (tried " + tried + ")", install_hint());
}

void close_vulkan_library(VulkanLibrary& library) {
    if (library.handle) close_one(library.handle);
    library = VulkanLibrary{};
}

std::string prepare_validation_layer() {
#if defined(__APPLE__)
    // Homebrew's manifest names the layer's library by its bare file name, which dyld only finds in the current
    // directory or on DYLD_FALLBACK_LIBRARY_PATH (read at launch), and /opt/homebrew/lib is on neither: the loader lists
    // the layer and then fails to open it. A copy of the manifest with the library's absolute path, added through
    // VK_ADD_LAYER_PATH (read by the loader on every call), fixes that without the user setting anything. A user who set
    // the loader's own variables keeps them.
    static std::mutex mutex;
    static bool tried = false;
    std::lock_guard<std::mutex> lock(mutex);
    if (tried) return {};  // said once per process
    tried = true;
    if (std::getenv("VK_LAYER_PATH") || std::getenv("VK_ADD_LAYER_PATH")) return {};
    const char* leaf = "libVkLayer_khronos_validation.dylib";
    if (void* h = dlopen(leaf, RTLD_LAZY | RTLD_LOCAL)) {
        dlclose(h);  // dyld finds it as it is
        return {};
    }
    namespace fs = std::filesystem;
    for (const char* prefix : {"/opt/homebrew", "/usr/local"}) {
        const fs::path manifest = fs::path(prefix) / "share/vulkan/explicit_layer.d/VkLayer_khronos_validation.json";
        const fs::path library = fs::path(prefix) / "lib" / leaf;
        std::error_code ec;
        if (!fs::is_regular_file(manifest, ec) || !fs::exists(library, ec)) continue;
        std::ifstream in(manifest, std::ios::binary);
        std::string text((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
        const std::string bare = std::string("\"") + leaf + "\"";
        const std::size_t at = text.find(bare);
        if (at == std::string::npos) continue;  // not a bare name: the loader resolves it itself
        text.replace(at, bare.size(), "\"" + library.string() + "\"");
        // One directory per user, the file replaced by a rename: test processes running side by side never read half
        // a manifest.
        const fs::path dir = fs::temp_directory_path(ec) / ("factoria-vulkan-layers-" + std::to_string(getuid()));
        if (ec) return {};
        fs::create_directories(dir, ec);
        const fs::path tmp = dir / ("VkLayer_khronos_validation.json." + std::to_string(getpid()));
        {
            std::ofstream out(tmp, std::ios::binary | std::ios::trunc);
            out << text;
            if (!out) return {};
        }
        fs::rename(tmp, dir / "VkLayer_khronos_validation.json", ec);
        if (ec) {
            fs::remove(tmp, ec);
            return {};
        }
        setenv("VK_ADD_LAYER_PATH", dir.c_str(), 0);
        return "the validation layer of " + std::string(prefix) + " through a manifest with its absolute path in " +
               dir.string();
    }
#endif
    return {};
}

}  // namespace fa::gpu::vk

#endif  // FA_VULKAN_BACKEND
