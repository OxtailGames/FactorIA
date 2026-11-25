// The platform's surfaces of the Vulkan backend (M77-P9d; vulkan_device.h, "The window"; ARCHITECTURE_RENDERING_VULKAN.md,
// "Swapchain"): the instance extension a surface on this platform's windows needs, and the VkSurfaceKHR of a native
// window. The vkCreate*SurfaceKHR function is taken from the instance (VK_NO_PROTOTYPES).
//
// gpu/vulkan_device.h goes first: the platform headers after it define macros (windows.h's) that the engine's types
// must not see. The X11 surface needs no X11 header: its create info is declared here with the layout Khronos gives it
// (a Display* and an XID), so the backend builds where libX11's headers are missing.
#include "gpu/vulkan_device.h"

#if defined(FA_VULKAN_BACKEND)

#include <cstdint>
#include <string>

#if defined(_WIN32)
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#include <vulkan/vulkan_win32.h>
#elif defined(__ANDROID__)
#include <vulkan/vulkan_android.h>
#elif defined(__APPLE__)
#include <vulkan/vulkan_metal.h>
#endif

namespace fa::gpu::vk {
namespace {

// The VkSurfaceKHR a vkCreate*SurfaceKHR call gave, or the error naming it.
VkSurfaceKHR made(VkResult r, VkSurfaceKHR surface, const char* call, std::string& error) {
    if (r == VK_SUCCESS && surface) return surface;
    error = std::string(call) + " failed with " + result_text(r) +
            " (hint: the window must exist and hold no other API's swapchain: OpenGL, D3D11 or sokol_app's own)";
    return VK_NULL_HANDLE;
}

#if defined(__linux__) && !defined(__ANDROID__)
// VkXlibSurfaceCreateInfoKHR (vulkan_xlib.h) without Xlib.h: a Display* and a Window (an XID, unsigned long).
struct XlibSurfaceCreateInfo {
    VkStructureType sType;
    const void* pNext;
    VkFlags flags;
    void* dpy;
    unsigned long window;
};
using CreateXlibSurface = VkResult(VKAPI_PTR*)(VkInstance, const XlibSurfaceCreateInfo*, const VkAllocationCallbacks*,
                                               VkSurfaceKHR*);
#endif

}  // namespace

const char* platform_surface_extension() {
#if defined(_WIN32)
    return VK_KHR_WIN32_SURFACE_EXTENSION_NAME;
#elif defined(__ANDROID__)
    return VK_KHR_ANDROID_SURFACE_EXTENSION_NAME;
#elif defined(__APPLE__)
    return VK_EXT_METAL_SURFACE_EXTENSION_NAME;
#elif defined(__linux__)
    return "VK_KHR_xlib_surface";  // VK_KHR_XLIB_SURFACE_EXTENSION_NAME (vulkan_xlib.h needs Xlib.h)
#else
    return nullptr;
#endif
}

VkSurfaceKHR make_platform_surface(PFN_vkGetInstanceProcAddr gipa, VkInstance instance, const SwapchainDesc& desc,
                                   std::string& error) {
    VkSurfaceKHR surface = VK_NULL_HANDLE;
#if defined(_WIN32)
    auto create = reinterpret_cast<PFN_vkCreateWin32SurfaceKHR>(gipa(instance, "vkCreateWin32SurfaceKHR"));
    if (!create) {
        error = "the Vulkan loader gives no vkCreateWin32SurfaceKHR (hint: update the GPU driver)";
        return VK_NULL_HANDLE;
    }
    HWND hwnd = static_cast<HWND>(const_cast<void*>(desc.nativeWindow));
    if (!IsWindow(hwnd)) {
        error = "SwapchainDesc::nativeWindow is not a window (IsWindow is false) (hint: pass the HWND of a window that "
                "exists; it may have been destroyed)";
        return VK_NULL_HANDLE;
    }
    VkWin32SurfaceCreateInfoKHR ci{};
    ci.sType = VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR;
    ci.hinstance = GetModuleHandleW(nullptr);
    ci.hwnd = hwnd;
    // Two statements: the order a call evaluates its arguments in is unspecified (GCC copied `surface` before create set it).
    const VkResult createResult = create(instance, &ci, nullptr, &surface);
    return made(createResult, surface, "vkCreateWin32SurfaceKHR", error);
#elif defined(__ANDROID__)
    auto create = reinterpret_cast<PFN_vkCreateAndroidSurfaceKHR>(gipa(instance, "vkCreateAndroidSurfaceKHR"));
    if (!create) {
        error = "the Vulkan loader gives no vkCreateAndroidSurfaceKHR (hint: Vulkan needs Android 7 or later)";
        return VK_NULL_HANDLE;
    }
    VkAndroidSurfaceCreateInfoKHR ci{};
    ci.sType = VK_STRUCTURE_TYPE_ANDROID_SURFACE_CREATE_INFO_KHR;
    ci.window = static_cast<ANativeWindow*>(const_cast<void*>(desc.nativeWindow));
    // Two statements: the order a call evaluates its arguments in is unspecified (GCC copied `surface` before create set it).
    const VkResult createResult = create(instance, &ci, nullptr, &surface);
    return made(createResult, surface, "vkCreateAndroidSurfaceKHR", error);
#elif defined(__APPLE__)
    auto create = reinterpret_cast<PFN_vkCreateMetalSurfaceEXT>(gipa(instance, "vkCreateMetalSurfaceEXT"));
    if (!create) {
        error = "the Vulkan loader gives no vkCreateMetalSurfaceEXT (hint: install the Vulkan SDK's MoltenVK, or "
                "Homebrew's molten-vk)";
        return VK_NULL_HANDLE;
    }
    VkMetalSurfaceCreateInfoEXT ci{};
    ci.sType = VK_STRUCTURE_TYPE_METAL_SURFACE_CREATE_INFO_EXT;
    ci.pLayer = static_cast<const CAMetalLayer*>(desc.nativeWindow);
    // Two statements: the order a call evaluates its arguments in is unspecified (GCC copied `surface` before create set it).
    const VkResult createResult = create(instance, &ci, nullptr, &surface);
    return made(createResult, surface, "vkCreateMetalSurfaceEXT", error);
#elif defined(__linux__)
    auto create = reinterpret_cast<CreateXlibSurface>(gipa(instance, "vkCreateXlibSurfaceKHR"));
    if (!create) {
        error = "the Vulkan loader gives no vkCreateXlibSurfaceKHR (hint: update the GPU driver)";
        return VK_NULL_HANDLE;
    }
    if (!desc.nativeDisplay) {
        error = "SwapchainDesc::nativeDisplay is null; an X11 window needs its Display* (hint: pass the X11 Display* "
                "of the window in SwapchainDesc::nativeDisplay)";
        return VK_NULL_HANDLE;
    }
    XlibSurfaceCreateInfo ci{};
    ci.sType = VK_STRUCTURE_TYPE_XLIB_SURFACE_CREATE_INFO_KHR;
    ci.pNext = nullptr;
    ci.flags = 0;
    ci.dpy = const_cast<void*>(desc.nativeDisplay);
    ci.window = static_cast<unsigned long>(reinterpret_cast<std::uintptr_t>(desc.nativeWindow));
    // Two statements: the order a call evaluates its arguments in is unspecified (GCC copied `surface` before create set it).
    const VkResult createResult = create(instance, &ci, nullptr, &surface);
    return made(createResult, surface, "vkCreateXlibSurfaceKHR", error);
#else
    (void)gipa;
    (void)instance;
    (void)desc;
    (void)surface;
    error = "this platform has no Vulkan surface (hint: draw offscreen: RendererDesc::headless true)";
    return VK_NULL_HANDLE;
#endif
}

}  // namespace fa::gpu::vk

#endif  // FA_VULKAN_BACKEND
