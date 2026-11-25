// The window of the Vulkan backend (M77-P9d; vulkan_device.h, "The window"; docs/design/ARCHITECTURE_RENDERING_VULKAN.md,
// "Swapchain"): a VkSurfaceKHR on the native window (vulkan_surface.cpp) and its VkSwapchainKHR, presented on the
// graphics queue. The swapchain's images are images of the device's pool (their states tracked like any other image's,
// `external` so the swapchain keeps them), so a PassDesc::for_swapchain pass is a pass into views. The first graphics
// submission that uses the acquired image waits for its acquire semaphore; present() is one barrier to PRESENT_SRC on
// an internal list whose submission signals the image's render-finished semaphore, which vkQueuePresentKHR waits for.
#include "gpu/vulkan_device.h"

#if defined(FA_VULKAN_BACKEND)

#include <algorithm>
#include <limits>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/log.h"

namespace fa::gpu::vk {
namespace {

// How long acquire_swapchain waits for an image: past a few frames (the render thread does not hang on a window whose
// display stopped presenting, or that is hidden); the frame is then skipped (an error the caller answers by drawing
// nothing), and the first one is logged.
constexpr std::uint64_t kAcquireTimeoutNs = 100ull * 1000ull * 1000ull;

Error vk_fail(const std::string& where, const char* call, VkResult r, const std::string& hint) {
    return make_error(where + ": " + call + " failed with " + result_text(r), hint);
}

// An error text "what (hint: how)" (vulkan_surface.cpp's) as an Error with its hint apart.
Error split_hint(const std::string& text) {
    const std::size_t at = text.find(" (hint: ");
    if (at == std::string::npos || text.back() != ')')
        return make_error(text, "pass a live window's native handle in SwapchainDesc::nativeWindow");
    return make_error(text.substr(0, at), text.substr(at + 8, text.size() - at - 9));
}

// A swapchain colour format: the images' VkFormat and the colour space the presentation engine shows them in.
struct SwapFormat {
    VkFormat format = VK_FORMAT_UNDEFINED;
    VkColorSpaceKHR space = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR;
    const char* name = "";
};

// The VkFormat is the device's format table's (format_info), so a swapchain image and an image of the same PixelFormat
// are one VkFormat; only the formats a window can show have an entry.
SwapFormat swap_format(PixelFormat f) {
    SwapFormat s;
    switch (f) {
        case PixelFormat::Bgra8:
        case PixelFormat::Sbgr8A8:
        case PixelFormat::Rgba8:
        case PixelFormat::Srgb8A8: s.space = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR, s.name = "sRGB"; break;
        case PixelFormat::Rgba16F: s.space = VK_COLOR_SPACE_EXTENDED_SRGB_LINEAR_EXT, s.name = "scRGB"; break;
        case PixelFormat::Rgb10A2: s.space = VK_COLOR_SPACE_HDR10_ST2084_EXT, s.name = "HDR10"; break;
        default: return {};
    }
    s.format = format_info(f).format;
    return s;
}

bool hdr_space(VkColorSpaceKHR s) { return s != VK_COLOR_SPACE_SRGB_NONLINEAR_KHR; }

const char* present_mode_name(VkPresentModeKHR m) {
    switch (m) {
        case VK_PRESENT_MODE_IMMEDIATE_KHR: return "IMMEDIATE";
        case VK_PRESENT_MODE_MAILBOX_KHR: return "MAILBOX";
        case VK_PRESENT_MODE_FIFO_RELAXED_KHR: return "FIFO_RELAXED";
        default: return "FIFO";
    }
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// Formats
// ---------------------------------------------------------------------------------------------------------------------

bool VulkanDevice::swapchain_format_supported(PixelFormat format, std::string* why) const {
    if (!surfaceExtension_ || !swapchainExtension_) {
        if (why)
            *why = "the Vulkan device " + deviceName_ +
                   " has no window path (the loader or driver lacks VK_KHR_surface, " +
                   std::string(platform_surface_extension() ? platform_surface_extension() : "a platform surface") +
                   " or VK_KHR_swapchain)";
        return false;
    }
    if (format == PixelFormat::Default) return true;
    const SwapFormat sf = swap_format(format);
    if (sf.format == VK_FORMAT_UNDEFINED) {
        if (why)
            *why =
                std::string("the Vulkan backend's swapchain takes Bgra8, Sbgr8A8, Rgba8, Srgb8A8, Rgba16F (scRGB) or "
                            "Rgb10A2 (HDR10), not ") +
                pixel_format_name(format);
        return false;
    }
    if (hdr_space(sf.space) && !colorspaceExtension_) {
        if (why)
            *why = std::string("the Vulkan loader has no VK_EXT_swapchain_colorspace, so the swapchain cannot show ") +
                   pixel_format_name(format) + " (" + sf.name + ")";
        return false;
    }
    if (!surface_) return true;  // before the window's surface exists: what the instance can ask for
    // With a surface, what it offers: the list loaded from vkGetPhysicalDeviceSurfaceFormatsKHR once per surface and
    // per swapchain made. A copy of it, because the render thread may load it again while another thread asks.
    for (const VkSurfaceFormatKHR& f : surface_formats_snapshot())
        if (f.format == sf.format && f.colorSpace == sf.space) return true;
    if (why)
        *why = "the window's surface on " + deviceName_ + " does not offer " + pixel_format_name(format) + " (" +
               sf.name + ") images (vkGetPhysicalDeviceSurfaceFormatsKHR)" +
               (hdr_space(sf.space) ? "; the display may not show HDR, or HDR is off in the system settings" : "");
    return false;
}

// The surface's formats, asked again from the driver (a new surface, a surface recreated on Android, a swapchain made
// again after the window or the monitor changed: a display's HDR setting changes the list). The list is built aside
// and swapped in under surfaceFormatsMutex_, which guards it, the known flag and the hidden formats:
// swapchain_format_supported() is const and any thread may call it (it reads the loaded list; the driver is asked here,
// outside the lock, on the render thread). `out`, when given, gets a copy of the list that was loaded.
VkResult VulkanDevice::load_surface_formats(std::vector<VkSurfaceFormatKHR>* out) const {
    std::vector<VkSurfaceFormatKHR> formats;
    std::uint32_t n = 0;
    VkResult r = fn_.vkGetPhysicalDeviceSurfaceFormatsKHR(physical_, surface_, &n, nullptr);
    if (r == VK_SUCCESS && n > 0) {
        formats.resize(n);
        r = fn_.vkGetPhysicalDeviceSurfaceFormatsKHR(physical_, surface_, &n, formats.data());
        formats.resize(r >= VK_SUCCESS ? n : 0);
    }
    std::lock_guard<std::mutex> lock(surfaceFormatsMutex_);
    // A format a test pretends the surface lacks (hide_surface_format_for_tests).
    for (VkFormat hidden : hiddenSurfaceFormats_)
        formats.erase(std::remove_if(formats.begin(), formats.end(),
                                     [&](const VkSurfaceFormatKHR& s) { return s.format == hidden; }),
                      formats.end());
    if (out) *out = formats;
    surfaceFormats_ = std::move(formats);
    surfaceFormatsKnown_ = r >= VK_SUCCESS;
    return r;
}

// A copy of the surface's formats, asked from the driver first when they are not known yet.
std::vector<VkSurfaceFormatKHR> VulkanDevice::surface_formats_snapshot() const {
    bool known = false;
    {
        std::lock_guard<std::mutex> lock(surfaceFormatsMutex_);
        known = surfaceFormatsKnown_;
    }
    if (!known) (void)load_surface_formats();
    std::lock_guard<std::mutex> lock(surfaceFormatsMutex_);
    return surfaceFormats_;
}

void VulkanDevice::hide_surface_format_for_tests(PixelFormat format) {
    const VkFormat hidden = swap_format(format).format;
    std::lock_guard<std::mutex> lock(surfaceFormatsMutex_);
    hiddenSurfaceFormats_.push_back(hidden);
    surfaceFormatsKnown_ = false;
}

// ---------------------------------------------------------------------------------------------------------------------
// The swapchain
// ---------------------------------------------------------------------------------------------------------------------

Result<void> VulkanDevice::create_swapchain(const SwapchainDesc& desc) {
    const std::string label = desc.label && *desc.label ? desc.label : "window";
    const std::string where = "gpu vulkan: create_swapchain '" + label + "'";
    if (swapchain_)
        return make_error(where + ": the device has a swapchain already",
                          "call destroy_swapchain() first, or resize_swapchain() for a new size");
    if (!desc.nativeWindow)
        return make_error(where + ": SwapchainDesc::nativeWindow is null; the Vulkan backend makes its own swapchain "
                                  "on the native window",
                          "pass the window's native handle in SwapchainDesc::nativeWindow (an HWND, an X11 Window "
                          "with its Display* in nativeDisplay, an ANativeWindow*, a CAMetalLayer* on macOS), or draw "
                          "offscreen (RendererDesc::headless true, then Renderer::capture)");
    if (!surfaceExtension_ || !swapchainExtension_) {
        std::string why;
        (void)swapchain_format_supported(PixelFormat::Default, &why);
        return make_error(where + ": " + why,
                          "update the GPU driver or install one with window support (WSI), or draw offscreen "
                          "(RendererDesc::headless true, then Renderer::capture)");
    }
    if (desc.width < 0 || desc.height < 0)
        return make_error(where + ": a size of " + std::to_string(desc.width) + "x" + std::to_string(desc.height),
                          "the size is 0 (the window's size) or more");
    const int samples = desc.sampleCount;
    if (samples != 1 && samples != 2 && samples != 4 && samples != 8)
        return make_error(where + ": sampleCount " + std::to_string(samples) + " is not 1, 2, 4 or 8",
                          "1 is no MSAA; 4 multisamples on every Vulkan GPU");
    std::string why;
    const PixelFormat asked = desc.colorFormat == PixelFormat::Default ? defaults_.colorFormat : desc.colorFormat;
    if (!swapchain_format_supported(asked, &why))
        return make_error(where + ": " + why,
                          "ask for PixelFormat::Default (the SDR format); swapchain_format_supported() says which "
                          "formats it takes");
    if (samples > 1 && !caps_[std::size_t(asked)].msaa)
        return make_error(where + ": " + pixel_format_name(asked) + " cannot be multisampled on " + deviceName_,
                          "sampleCount 1, or an SDR format");

    // A surface left without a swapchain (a swapchain that could not be made again at an acquire or a resize) goes
    // first: a second surface on the same window would fail on Android (VK_ERROR_NATIVE_WINDOW_IN_USE_KHR) and the
    // first would leak.
    if (surface_) destroy_swapchain();
    std::string error;
    surface_ = make_platform_surface(library_.getInstanceProcAddr, instance_, desc, error);
    if (!surface_) return split_hint(where + ": " + error);
    auto fail = [&](Error e) -> Result<void> {
        destroy_swapchain();
        return e;
    };
    const std::uint32_t family = queues_[int(QueueKind::Graphics)].family;
    VkBool32 presents = VK_FALSE;
    VkResult r = fn_.vkGetPhysicalDeviceSurfaceSupportKHR(physical_, family, surface_, &presents);
    if (r != VK_SUCCESS)
        return fail(vk_fail(where, "vkGetPhysicalDeviceSurfaceSupportKHR", r, "the window or the device was lost"));
    if (!presents)
        return fail(make_error(where + ": the graphics queue family " + std::to_string(family) + " of " + deviceName_ +
                                   " cannot present to this window",
                               "pick the GPU the display is connected to (VulkanOptions::deviceIndex), or draw "
                               "offscreen"));

    // The colour format: what was asked, from the surface's list. Default takes the device's SDR format, or the other
    // 8-bit order of the same kind (the sRGB twin of an sRGB default) when the surface has only that one (Android
    // offers RGBA).
    SwapFormat sf = swap_format(asked);
    std::vector<VkSurfaceFormatKHR> formats;
    r = load_surface_formats(&formats);  // a new surface: its list is asked again
    if (r < VK_SUCCESS || formats.empty())
        return fail(vk_fail(where, "vkGetPhysicalDeviceSurfaceFormatsKHR", r, "the window or the device was lost"));
    auto offered = [&](const SwapFormat& f) {
        for (const VkSurfaceFormatKHR& s : formats)
            if (s.format == f.format && s.colorSpace == f.space) return true;
        return false;
    };
    PixelFormat format = asked;
    if (!offered(sf) && desc.colorFormat == PixelFormat::Default) {
        const bool srgb = asked == PixelFormat::Sbgr8A8 || asked == PixelFormat::Srgb8A8;
        const PixelFormat others[2] = {srgb ? PixelFormat::Sbgr8A8 : PixelFormat::Bgra8,
                                       srgb ? PixelFormat::Srgb8A8 : PixelFormat::Rgba8};
        for (PixelFormat other : others)
            if (offered(swap_format(other))) {
                format = other;
                sf = swap_format(other);
                break;
            }
    }
    if (!offered(sf)) {
        std::string list;
        for (const VkSurfaceFormatKHR& s : formats)
            list +=
                (list.empty() ? "" : ", ") + std::to_string(int(s.format)) + "/" + std::to_string(int(s.colorSpace));
        return fail(make_error(where + ": the window's surface does not offer " + pixel_format_name(format) + " (" +
                                   sf.name + ") images (it offers VkFormat/VkColorSpaceKHR " + list + ")",
                               "ask for PixelFormat::Default; swapchain_format_supported() says which formats it "
                               "takes"));
    }
    if (format != asked) {
        if (samples > 1 && !caps_[std::size_t(format)].msaa)
            return fail(make_error(where + ": the window's surface offers " + pixel_format_name(format) + " and not " +
                                       pixel_format_name(asked) + ", and " + deviceName_ + " cannot multisample it",
                                   "sampleCount 1"));
        // Pipelines and passes into the window name the device's default colour format (EnvironmentDefaults, what
        // PassDesc::for_swapchain and a pipeline's Default colour target mean), so it becomes the window's. Pipelines
        // or images already made with the old one would not fit the window's passes: that is an error, not a silent
        // mismatch at the first set_pipeline().
        if (defaultColorUsed_)
            return fail(make_error(where + ": the window's surface offers " + pixel_format_name(format) +
                                       " images and not " + pixel_format_name(asked) +
                                       ", the device's default colour format, and pipelines or images made with that "
                                       "default exist already, so they would not fit a pass into the window",
                                   std::string("make the device with DeviceInit::environment.defaults.colorFormat = ") +
                                       pixel_format_name(format) +
                                       " (where the window's surface offers only that one: Android), or create the "
                                       "swapchain before the first pipeline"));
    }

    // The present mode: FIFO (every GPU has it) with vsync; else MAILBOX (no tearing), IMMEDIATE, then FIFO.
    std::vector<VkPresentModeKHR> modes;
    std::uint32_t n = 0;
    if (fn_.vkGetPhysicalDeviceSurfacePresentModesKHR(physical_, surface_, &n, nullptr) == VK_SUCCESS && n > 0) {
        modes.resize(n);
        if (fn_.vkGetPhysicalDeviceSurfacePresentModesKHR(physical_, surface_, &n, modes.data()) < VK_SUCCESS) n = 0;
        modes.resize(n);
    }
    auto has_mode = [&](VkPresentModeKHR m) { return std::find(modes.begin(), modes.end(), m) != modes.end(); };
    VkPresentModeKHR mode = VK_PRESENT_MODE_FIFO_KHR;
    if (!desc.vsync) {
        if (has_mode(VK_PRESENT_MODE_MAILBOX_KHR))
            mode = VK_PRESENT_MODE_MAILBOX_KHR;
        else if (has_mode(VK_PRESENT_MODE_IMMEDIATE_KHR))
            mode = VK_PRESENT_MODE_IMMEDIATE_KHR;
    }

    swapLabel_ = label;
    swapFormat_ = format;
    swapVkFormat_ = sf.format;
    swapColorSpace_ = sf.space;
    swapPresentMode_ = mode;
    swapVsync_ = desc.vsync;
    swapRecreations_ = 0;
    swapStale_ = false;
    {
        std::lock_guard<std::mutex> lock(swapMutex_);
        swapWidth_ = desc.width;  // 0: the surface's size (make_swapchain)
        swapHeight_ = desc.height;
        swapSamples_ = samples;
        swapDepthFormat_ = defaults_.depthFormat;
        swapAcquired_ = false;
        swapIndex_ = 0;
    }
    if (auto made = make_swapchain(where, false); !made) return fail(made.error());
    if (format != asked) {
        // Only now, with the swapchain made: a failed one leaves the device's default colour format as it was.
        defaults_.colorFormat = format;
        FA_INFO("render",
                "gpu vulkan: the window's surface offers {} and not {}: the device's default colour format is now {}",
                pixel_format_name(format), pixel_format_name(asked), pixel_format_name(format));
    }
    int width = 0, height = 0;
    {
        std::lock_guard<std::mutex> lock(swapMutex_);
        width = swapWidth_;
        height = swapHeight_;
    }
    FA_INFO("render", "gpu vulkan: swapchain '{}' {}x{} {} ({}), {} images, {} sample(s), present mode {}", swapLabel_,
            width, height, pixel_format_name(format), sf.name, swapImages_.size(), samples, present_mode_name(mode));
    return {};
}

Result<void> VulkanDevice::make_swapchain(const std::string& where, bool windowSize) {
    if (failNextSwapchain_) {
        failNextSwapchain_ = false;
        return make_error(where + ": a swapchain failure injected by a test", "tests only");
    }
    rotationOnlyAnswer_ = -1;  // the surface changed or is asked again: the next suboptimal asks again
    VkSurfaceCapabilitiesKHR caps{};
    VkResult r = fn_.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(physical_, surface_, &caps);
    if (r != VK_SUCCESS)
        return vk_fail(where, "vkGetPhysicalDeviceSurfaceCapabilitiesKHR", r, "the window or the device was lost");
    // The surface's formats again: a surface recreated (Android) or a monitor change (HDR on or off) changes the list,
    // and a swapchain asks for a format the surface offers now.
    {
        std::vector<VkSurfaceFormatKHR> formats;
        const VkResult fr = load_surface_formats(&formats);
        if (fr < VK_SUCCESS)
            return vk_fail(where, "vkGetPhysicalDeviceSurfaceFormatsKHR", fr, "the window or the device was lost");
        bool offered = false;
        for (const VkSurfaceFormatKHR& f : formats)
            if (f.format == swapVkFormat_ && f.colorSpace == swapColorSpace_) offered = true;
        if (!offered)
            return make_error(where + ": the window's surface no longer offers " + pixel_format_name(swapFormat_) +
                                  " images (the window or the display changed)",
                              "destroy_swapchain() and create_swapchain() again: the new swapchain takes a format the "
                              "surface offers now");
    }
    // 0 = the surface's size (currentExtent; 0xFFFFFFFF when the swapchain sets it, as on Wayland): a swapchain made
    // again because the window changed takes the window's size where the surface has one.
    const bool undefined = caps.currentExtent.width == 0xFFFFFFFFu;
    int width = 0, height = 0;
    {
        std::lock_guard<std::mutex> lock(swapMutex_);
        width = windowSize && !undefined ? 0 : swapWidth_;
        height = windowSize && !undefined ? 0 : swapHeight_;
    }
    if ((width == 0 || height == 0) && undefined)
        return make_error(where + ": the surface has no size of its own, so the swapchain needs one",
                          "give SwapchainDesc::width and height (resize_swapchain(w, h) after)");
    if (width == 0) width = int(caps.currentExtent.width);
    if (height == 0) height = int(caps.currentExtent.height);
    if (caps.maxImageExtent.width == 0 || caps.maxImageExtent.height == 0)
        return make_error(where + ": the window has no area (minimised, or 0 pixels wide or high)",
                          "draw nothing while the window is minimised; resize_swapchain() when it comes back");
    // Clamped as unsigned (a driver's maxImageExtent of 0xFFFFFFFF would be -1 as an int), then narrowed: the GPU's
    // largest image bounds both below.
    auto clamp_extent = [&](int wanted, std::uint32_t lo, std::uint32_t hi) {
        const std::uint32_t w = wanted > 0 ? std::uint32_t(wanted) : 1u;
        const std::uint32_t c = std::clamp(w, std::max(1u, lo), std::max(1u, hi));
        return int(std::min<std::uint32_t>(c, std::uint32_t(std::numeric_limits<int>::max())));
    };
    width = clamp_extent(width, caps.minImageExtent.width, caps.maxImageExtent.width);
    height = clamp_extent(height, caps.minImageExtent.height, caps.maxImageExtent.height);
    if (width > limits_.maxImageSize2d || height > limits_.maxImageSize2d)
        return make_error(where + ": " + std::to_string(width) + "x" + std::to_string(height) +
                              " is more than the GPU's largest image (" + std::to_string(limits_.maxImageSize2d) + ")",
                          "a smaller window or framebuffer");
    // Frames in flight + 1 images: the GPU draws into one while the others wait to be shown.
    std::uint32_t count = std::max(caps.minImageCount, std::uint32_t(std::max(1, framesInFlight_) + 1));
    if (caps.maxImageCount > 0) count = std::min(count, caps.maxImageCount);
    VkCompositeAlphaFlagBitsKHR alpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
    for (VkCompositeAlphaFlagBitsKHR a :
         {VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR, VK_COMPOSITE_ALPHA_INHERIT_BIT_KHR,
          VK_COMPOSITE_ALPHA_PRE_MULTIPLIED_BIT_KHR, VK_COMPOSITE_ALPHA_POST_MULTIPLIED_BIT_KHR})
        if (caps.supportedCompositeAlpha & a) {
            alpha = a;
            break;
        }
    // A readback of the window (tests, screenshots) copies out of the image: transfer source where the surface allows.
    VkImageUsageFlags usage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
    if (caps.supportedUsageFlags & VK_IMAGE_USAGE_TRANSFER_SRC_BIT) usage |= VK_IMAGE_USAGE_TRANSFER_SRC_BIT;

    // Every list that uses the old images finishes and their records go first; the old swapchain is retired by the new
    // one (and destroyed even when the new one fails).
    release_swap_images();
    const VkSwapchainKHR old = swapchain_;
    VkSwapchainCreateInfoKHR ci{};
    ci.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
    ci.surface = surface_;
    ci.minImageCount = count;
    ci.imageFormat = swapVkFormat_;
    ci.imageColorSpace = swapColorSpace_;
    ci.imageExtent = {std::uint32_t(width), std::uint32_t(height)};
    ci.imageArrayLayers = 1;
    ci.imageUsage = usage;
    ci.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE;
    // The renderer does not draw pre-rotated, so the swapchain's images are upright: IDENTITY wherever the surface
    // offers it, and the presentation engine turns them as the display is turned (on Android, with currentTransform
    // ROTATE_90 or ROTATE_270, SurfaceFlinger rotates them as it does OpenGL ES's: a composition pass, where a renderer
    // that draws pre-rotated would save it). currentExtent is then the upright size. A surface without IDENTITY keeps
    // its currentTransform, and the picture comes out turned (warned once).
    const VkSurfaceTransformFlagBitsKHR transform = (caps.supportedTransforms & VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR)
                                                        ? VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR
                                                        : caps.currentTransform;
    ci.preTransform = transform;
    swapPresenterRotates_ = transform != caps.currentTransform;
    swapPreRotation_ = transform == VK_SURFACE_TRANSFORM_ROTATE_90_BIT_KHR    ? 90
                       : transform == VK_SURFACE_TRANSFORM_ROTATE_180_BIT_KHR ? 180
                       : transform == VK_SURFACE_TRANSFORM_ROTATE_270_BIT_KHR ? 270
                                                                              : 0;
    if (swapPreRotation_ != 0 && !swapRotationWarned_) {
        swapRotationWarned_ = true;
        FA_WARN("render",
                "gpu vulkan: the window's surface offers no IDENTITY transform and is rotated {} degrees against the "
                "display's orientation; the swapchain does not pre-rotate its drawing, so the picture appears rotated "
                "(a renderer that draws pre-rotated reads swapchain_pre_rotation_degrees())",
                swapPreRotation_);
    }
    ci.compositeAlpha = alpha;
    ci.presentMode = swapPresentMode_;
    ci.clipped = VK_TRUE;
    ci.oldSwapchain = old;
    VkSwapchainKHR made = VK_NULL_HANDLE;
    r = fn_.vkCreateSwapchainKHR(device_, &ci, nullptr, &made);
    if (old) {
        fn_.vkDestroySwapchainKHR(device_, old, nullptr);
        ++swapRecreations_;
    }
    swapchain_ = r == VK_SUCCESS ? made : VK_NULL_HANDLE;
    if (!swapchain_)
        return vk_fail(where, "vkCreateSwapchainKHR", r,
                       r == VK_ERROR_NATIVE_WINDOW_IN_USE_KHR
                           ? "the window holds another API's swapchain already (OpenGL, D3D11 or sokol_app's own)"
                           : "the validation layer (VulkanOptions::validation) says which field is wrong");
#if !defined(__ANDROID__)
    // Not on Android: there the swapchain is the platform loader's object (libvulkan.so implements VK_KHR_swapchain over
    // the driver), and vkSetDebugUtilsObjectNameEXT reaches the driver with a handle that is not its own: Mesa's
    // vk_common_SetDebugUtilsObjectNameEXT (the emulator's driver) frees a name it reads from it and aborts the process.
    // Its images are the driver's own and keep their names below.
    set_name(VK_OBJECT_TYPE_SWAPCHAIN_KHR, handle_bits(swapchain_), swapLabel_.c_str());
#endif
    swapUsage_ = usage;
    swapStale_ = false;
    {
        std::lock_guard<std::mutex> lock(swapMutex_);
        swapWidth_ = width;
        swapHeight_ = height;
    }
    set_hdr_metadata();
    auto images = make_swap_images(where);
    // Images that were not all made (or an MSAA or depth image that failed) leave a swapchain no frame can use: the
    // next acquire_swapchain() makes it again instead of acquiring into the half it has.
    if (!images) swapStale_ = true;
    return images;
}

// HDR10 asks for its mastering metadata (VK_EXT_hdr_metadata): Rec. 2020 primaries, a D65 white point and the 1000-nit
// range the engine's HDR10 output is tone mapped to. A device without the extension, and the other colour spaces
// (scRGB carries its own scale), set nothing.
void VulkanDevice::set_hdr_metadata() {
    if (!fn_.vkSetHdrMetadataEXT || swapColorSpace_ != VK_COLOR_SPACE_HDR10_ST2084_EXT || !swapchain_) return;
    VkHdrMetadataEXT m{};
    m.sType = VK_STRUCTURE_TYPE_HDR_METADATA_EXT;
    m.displayPrimaryRed = {0.708f, 0.292f};
    m.displayPrimaryGreen = {0.170f, 0.797f};
    m.displayPrimaryBlue = {0.131f, 0.046f};
    m.whitePoint = {0.3127f, 0.3290f};
    m.maxLuminance = 1000.0f;
    m.minLuminance = 0.001f;
    m.maxContentLightLevel = 1000.0f;
    m.maxFrameAverageLightLevel = 400.0f;
    fn_.vkSetHdrMetadataEXT(device_, 1, &swapchain_, &m);
}

Result<void> VulkanDevice::make_swap_images(const std::string& where) {
    std::uint32_t count = 0;
    std::vector<VkImage> handles;
    VkResult r = fn_.vkGetSwapchainImagesKHR(device_, swapchain_, &count, nullptr);
    if (r == VK_SUCCESS && count > 0) {
        handles.resize(count);
        r = fn_.vkGetSwapchainImagesKHR(device_, swapchain_, &count, handles.data());
        handles.resize(count);
    }
    if (r < VK_SUCCESS || handles.empty())
        return vk_fail(where, "vkGetSwapchainImagesKHR", r, "the window or the device was lost");
    int width = 0, height = 0, samples = 1;
    PixelFormat depthFormat = PixelFormat::None;
    {
        std::lock_guard<std::mutex> lock(swapMutex_);
        width = swapWidth_;
        height = swapHeight_;
        samples = swapSamples_;
        depthFormat = swapDepthFormat_;
    }
    VkSemaphoreCreateInfo sci{};
    sci.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;
    std::string error;
    std::string hint = "the GPU ran out of memory, or the image pool is full";
    std::vector<SwapImage> images;
    for (std::uint32_t i = 0; i < count && error.empty(); ++i) {
        const std::string name = swapLabel_ + " image " + std::to_string(i);
        set_name(VK_OBJECT_TYPE_IMAGE, handle_bits(handles[i]), name.c_str());
        auto t = std::make_shared<TrackedResource>();
        t->device = this;
        t->image = handles[i];
        t->external = true;  // the swapchain's: vkDestroySwapchainKHR frees it
        t->aspects = VK_IMAGE_ASPECT_COLOR_BIT;
        t->states.assign(1, SubState{});
        ImageRecord rec;
        rec.tracked = t;
        rec.type = ImageType::Tex2d;
        rec.usage.colorAttachment = true;
        rec.usage.resolveAttachment = true;
        rec.format = swapFormat_;
        rec.width = width;
        rec.height = height;
        rec.label = name;
        SwapImage s;
        s.tracked = std::move(t);
        int capacity = 0;
        {
            std::lock_guard<std::mutex> lock(resMutex_);
            const std::uint32_t id = images_.add(std::move(rec));
            if (id != 0) {
                count_make(stats_.images, true);
                s.image = Image{id};
            }
            capacity = images_.capacity();
        }
        if (s.image.id == 0) {
            error = "the image pool is full (" + std::to_string(capacity) + " images)";
            hint = "destroy images you no longer use, or raise DeviceInit::imagePoolSize";
        } else {
            ViewDesc vd;
            if (samples > 1)
                vd.resolveAttachment.image = s.image;
            else
                vd.colorAttachment.image = s.image;
            vd.label = name.c_str();
            s.view = make_view(vd);
            if (state(s.view) != ResourceState::Valid)
                error = "the view of image " + std::to_string(i) + " could not be made (see errors())";
        }
        if (error.empty()) {
            r = fn_.vkCreateSemaphore(device_, &sci, nullptr, &s.renderFinished);
            if (r != VK_SUCCESS) {
                s.renderFinished = VK_NULL_HANDLE;
                error = "vkCreateSemaphore failed with " + result_text(r);
            } else {
                set_name(VK_OBJECT_TYPE_SEMAPHORE, handle_bits(s.renderFinished), (name + " render-finished").c_str());
            }
        }
        images.push_back(std::move(s));
    }
    // One acquire semaphore more than images: the next acquire never takes one a submission may still wait for.
    std::vector<AcquireSemaphore> acquires(error.empty() ? count + 1 : 0);
    for (std::size_t i = 0; i < acquires.size() && error.empty(); ++i) {
        r = fn_.vkCreateSemaphore(device_, &sci, nullptr, &acquires[i].semaphore);
        if (r != VK_SUCCESS) {
            acquires[i].semaphore = VK_NULL_HANDLE;
            error = "vkCreateSemaphore failed with " + result_text(r);
        } else {
            set_name(VK_OBJECT_TYPE_SEMAPHORE, handle_bits(acquires[i].semaphore),
                     (swapLabel_ + " acquire " + std::to_string(i)).c_str());
        }
    }
    Image msaa{}, depth{};
    View msaaView{}, depthView{};
    if (error.empty() && samples > 1) {
        const std::string name = swapLabel_ + " msaa";
        ImageDesc id;
        id.usage.colorAttachment = true;
        id.width = width;
        id.height = height;
        id.pixelFormat = swapFormat_;
        id.sampleCount = samples;
        id.label = name.c_str();
        msaa = make_image(id);
        ViewDesc vd;
        vd.colorAttachment.image = msaa;
        vd.label = name.c_str();
        msaaView = make_view(vd);
        if (state(msaaView) != ResourceState::Valid)
            error = "its " + std::to_string(samples) + "x MSAA colour image could not be made (see errors())";
    }
    if (error.empty() && depthFormat != PixelFormat::None) {
        const std::string name = swapLabel_ + " depth";
        ImageDesc id;
        id.usage.depthStencilAttachment = true;
        id.width = width;
        id.height = height;
        id.pixelFormat = depthFormat;
        id.sampleCount = samples;
        id.label = name.c_str();
        depth = make_image(id);
        ViewDesc vd;
        vd.depthStencilAttachment.image = depth;
        vd.label = name.c_str();
        depthView = make_view(vd);
        if (state(depthView) != ResourceState::Valid)
            error =
                std::string("its ") + pixel_format_name(depthFormat) + " depth image could not be made (see errors())";
    }
    // Kept even when something failed: release_swap_images() destroys what was made.
    acquireSemaphores_ = std::move(acquires);
    acquireNext_ = 0;
    {
        std::lock_guard<std::mutex> lock(swapMutex_);
        swapImages_ = std::move(images);
        swapMsaa_ = msaa;
        swapMsaaView_ = msaaView;
        swapDepth_ = depth;
        swapDepthView_ = depthView;
    }
    if (!error.empty())
        return make_error(where + ": the swapchain '" + swapLabel_ + "' (" + std::to_string(width) + "x" +
                              std::to_string(height) + "): " + error,
                          hint);
    return {};
}

void VulkanDevice::release_swap_images() {
    std::vector<SwapImage> images;
    Image msaa{}, depth{};
    View msaaView{}, depthView{};
    {
        std::lock_guard<std::mutex> lock(swapMutex_);
        images = std::move(swapImages_);
        swapImages_.clear();
        msaa = std::exchange(swapMsaa_, Image{});
        depth = std::exchange(swapDepth_, Image{});
        msaaView = std::exchange(swapMsaaView_, View{});
        depthView = std::exchange(swapDepthView_, View{});
        swapAcquired_ = false;
    }
    for (const SwapImage& s : images) {
        if (s.view.id != 0) destroy_view(s.view);
        if (s.image.id != 0) destroy_image(s.image);
    }
    for (View v : {msaaView, depthView})
        if (v.id != 0) destroy_view(v);
    for (Image i : {msaa, depth})
        if (i.id != 0) destroy_image(i);
    if (images.empty() && acquireSemaphores_.empty()) return;
    {
        // An image acquired and never used: a submission of nothing waits for its acquire semaphore, so the semaphore
        // is not destroyed while signalled with a wait pending.
        std::lock_guard<std::mutex> lock(queueMutex_);
        if (swapWait_) {
            (void)submit_signal(QueueKind::Graphics, nullptr, 0, "fa-vulkan-swapchain-release", nullptr, swapWait_);
            swapWait_ = VK_NULL_HANDLE;
            swapWaitImage_ = nullptr;
        }
    }
    // The semaphores and the swapchain go once the GPU and the presentation engine are done with them: every timeline
    // reaches its last value, then the device is idle (a present's wait is not on a timeline).
    if (auto r = wait_idle(); !r) report(r.error().to_string());
    (void)fn_.vkDeviceWaitIdle(device_);
    for (SwapImage& s : images)
        if (s.renderFinished) fn_.vkDestroySemaphore(device_, s.renderFinished, nullptr);
    for (AcquireSemaphore& a : acquireSemaphores_)
        if (a.semaphore) fn_.vkDestroySemaphore(device_, a.semaphore, nullptr);
    acquireSemaphores_.clear();
    acquireNext_ = 0;
}

Result<void> VulkanDevice::resize_swapchain(int width, int height) {
    if (!swapchain_)
        return make_error("gpu vulkan: resize_swapchain without a swapchain", "call create_swapchain() first");
    const std::string where = "gpu vulkan: resize_swapchain '" + swapLabel_ + "'";
    if (width < 0 || height < 0)
        return make_error(where + " to " + std::to_string(width) + "x" + std::to_string(height),
                          "the size is 0 (the window's size) or more");
    bool whole = false;
    {
        std::lock_guard<std::mutex> lock(swapMutex_);
        if (swapAcquired_)
            return make_error(where + " between acquire_swapchain() and present()",
                              "resize before the frame's acquire_swapchain() (the passes of this frame draw into the "
                              "image it acquired)");
        whole = !swapImages_.empty() && !swapStale_;
        if (whole && width == swapWidth_ && height == swapHeight_) return {};
        swapWidth_ = width;
        swapHeight_ = height;
    }
    return make_swapchain(where + " to " + std::to_string(width) + "x" + std::to_string(height), false);
}

Result<Swapchain> VulkanDevice::acquire_swapchain(const Swapchain&) {
    if (!swapchain_ && !surface_)
        return make_error("gpu vulkan: acquire_swapchain without a swapchain",
                          "call create_swapchain() with the window's native handle first");
    const std::string where = "gpu vulkan: acquire_swapchain '" + swapLabel_ + "'";
    auto current = [&]() {
        std::lock_guard<std::mutex> lock(swapMutex_);
        Swapchain sc;
        sc.width = swapWidth_;
        sc.height = swapHeight_;
        sc.sampleCount = swapSamples_;
        sc.colorFormat = swapFormat_;
        sc.depthFormat = swapDepthFormat_;
        return sc;
    };
    bool acquired = false;
    {
        std::lock_guard<std::mutex> lock(swapMutex_);
        acquired = swapAcquired_;
    }
    if (acquired) return current();  // a second acquire of the frame hands back the same image
    rotationOnlyAnswer_ = -1;        // a new frame asks the surface again (suboptimal_only_by_rotation)
    for (int attempt = 0; attempt < 2; ++attempt) {
        // An out-of-date or suboptimal swapchain (the window changed), or one an earlier failure left without images,
        // is made again at the window's size first.
        bool remake = swapStale_ || !swapchain_;
        {
            std::lock_guard<std::mutex> lock(swapMutex_);
            remake = remake || swapImages_.empty();
        }
        if (remake)
            if (auto made = make_swapchain(where, true); !made) return made.error();
        if (acquireSemaphores_.empty())
            return make_error(where + ": its images were not made (an earlier failure)",
                              "resize_swapchain() again, or destroy_swapchain() and create_swapchain()");
        const std::size_t slot = acquireNext_;
        // The semaphore was waited for by a submission at least one image ago: it is free once that one finished.
        if (auto w = wait_timeline(acquireSemaphores_[slot].waitedAt, "acquire_swapchain"); !w) return w.error();
        const VkSemaphore semaphore = acquireSemaphores_[slot].semaphore;
        std::uint32_t index = 0;
        VkResult r = VK_SUCCESS;
        if (injectedAcquires_ > 0) {  // a test's answer: nothing was signalled, as with a timeout
            --injectedAcquires_;
            r = injectedAcquire_;
        } else {
            r = fn_.vkAcquireNextImageKHR(device_, swapchain_, kAcquireTimeoutNs, semaphore, VK_NULL_HANDLE, &index);
        }
        if (r == VK_ERROR_OUT_OF_DATE_KHR) {  // nothing was signalled: made again, then one more try
            swapStale_ = true;
            continue;
        }
        if (r == VK_TIMEOUT || r == VK_NOT_READY) {
            if (!swapTimeoutLogged_) {
                swapTimeoutLogged_ = true;
                FA_WARN("render",
                        "gpu vulkan: the presentation engine of the window '{}' gave no image in {} ms: the frame is "
                        "skipped (logged once; the window may be hidden, or its display stopped presenting)",
                        swapLabel_, kAcquireTimeoutNs / 1000000ull);
            }
            return make_error(where + ": the presentation engine gave no image in " +
                                  std::to_string(kAcquireTimeoutNs / 1000000ull) + " ms",
                              "skip this frame (draw nothing) and acquire again next frame; the window may be hidden "
                              "on a display that stopped presenting");
        }
        if (r == VK_ERROR_SURFACE_LOST_KHR) {
            // The window went under the swapchain (nothing was signalled): it and its surface go now, so the caller
            // makes them again on the window it has (Renderer::present does, on the window it was last given).
            const Error lost = vk_fail(where, "vkAcquireNextImageKHR", r,
                                       "the window was destroyed: its swapchain is destroyed too; create_swapchain() "
                                       "on the new one");
            destroy_swapchain();
            return lost;
        }
        if (r != VK_SUCCESS && r != VK_SUBOPTIMAL_KHR)
            return vk_fail(where, "vkAcquireNextImageKHR", r,
                           "the device was lost: run with VulkanOptions::validation for the cause");
        // Drawn and shown, then made again at the next acquire (not for the rotation the presentation engine does).
        if (r == VK_SUBOPTIMAL_KHR && !suboptimal_only_by_rotation()) swapStale_ = true;
        acquireNext_ = (slot + 1) % acquireSemaphores_.size();
        std::shared_ptr<TrackedResource> tracked;
        {
            std::lock_guard<std::mutex> lock(swapMutex_);
            if (index < swapImages_.size()) tracked = swapImages_[index].tracked;
            swapIndex_ = index;
            swapAcquired_ = true;
        }
        {
            // The image's contents are gone (UNDEFINED) and its first use waits for the acquire semaphore at the colour
            // attachment output stage, which the fix-up barrier of that use then waits for.
            std::lock_guard<std::mutex> lock(queueMutex_);
            acquireSemaphores_[slot].waitedAt = 0;
            if (tracked) {
                tracked->states.assign(1,
                                       {VK_IMAGE_LAYOUT_UNDEFINED, VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT, 0});
                swapWait_ = semaphore;
                swapWaitImage_ = tracked.get();
                swapWaitSlot_ = slot;
            }
        }
        return current();
    }
    return make_error(where + ": the swapchain was out of date again right after it was made",
                      "the window is changing size: try again next frame");
}

std::string VulkanDevice::swapchain_pass(const PassDesc& pass, PassDesc& into) const {
    std::lock_guard<std::mutex> lock(swapMutex_);
    if (swapImages_.empty())
        return "a pass into the window (PassDesc::swapchain) without a swapchain (hint: create_swapchain() with the "
               "window's native handle first, or draw into views)";
    if (!swapAcquired_ || swapIndex_ >= swapImages_.size())
        return "a pass into the window before this frame's acquire_swapchain() (hint: acquire_swapchain() once per "
               "frame before the passes into the window; present() ends the frame)";
    const Swapchain& sc = *pass.swapchain;
    if (sc.width != swapWidth_ || sc.height != swapHeight_)
        return "PassDesc::swapchain is " + std::to_string(sc.width) + "x" + std::to_string(sc.height) +
               ", the window's swapchain " + std::to_string(swapWidth_) + "x" + std::to_string(swapHeight_) +
               " (hint: begin the pass with the Swapchain acquire_swapchain() returned this frame)";
    into = pass;
    into.swapchain = nullptr;
    into.color1 = {};
    const SwapImage& s = swapImages_[swapIndex_];
    if (swapSamples_ > 1) {
        into.color = swapMsaaView_;
        into.resolve = s.view;
    } else {
        into.color = s.view;
        into.resolve = {};
    }
    into.depth = pass.format.depth == PixelFormat::None ? View{} : swapDepthView_;
    return {};
}

Result<void> VulkanDevice::present() {
    if (!swapchain_)
        return make_error("gpu vulkan: present without a swapchain",
                          "call create_swapchain() with the window's native handle first");
    const std::string where = "gpu vulkan: present of the swapchain '" + swapLabel_ + "'";
    std::shared_ptr<TrackedResource> tracked;
    VkSemaphore finished = VK_NULL_HANDLE;
    std::uint32_t index = 0;
    {
        std::lock_guard<std::mutex> lock(swapMutex_);
        if (!swapAcquired_ || swapIndex_ >= swapImages_.size())
            return make_error(where + " without this frame's acquire_swapchain()",
                              "acquire_swapchain(), draw, commit(), then present() once");
        index = swapIndex_;
        tracked = swapImages_[index].tracked;
        finished = swapImages_[index].renderFinished;
    }
    VkResult r = VK_SUCCESS;
    bool submitted = false;
    {
        // The image goes to PRESENT_SRC on the graphics queue, behind the frame's lists: the fix-up barrier of an
        // internal list that only requires that layout, whose submission signals the render-finished semaphore (and
        // waits for the acquire semaphore when nothing drew into the image). The barrier's second scope is ALL_COMMANDS,
        // not NONE: with NONE nothing is ordered after the layout transition, so the semaphore signal (whose first
        // scope is ALL_COMMANDS) does not chain with it and synchronization validation reports the present as a
        // PRESENT_AFTER_WRITE hazard.
        std::lock_guard<std::mutex> lock(queueMutex_);
        flush_prelude();
        if (VulkanCommandList* list = acquire_list("fa-vulkan-present", true)) {
            list->require(tracked, 0, {VK_IMAGE_LAYOUT_PRESENT_SRC_KHR, VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT, 0});
            submitted = execute(*list, {}, finished);
        }
        if (submitted) {
            VkPresentInfoKHR pi{};
            pi.sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
            pi.waitSemaphoreCount = 1;
            pi.pWaitSemaphores = &finished;
            pi.swapchainCount = 1;
            pi.pSwapchains = &swapchain_;
            pi.pImageIndices = &index;
            r = fn_.vkQueuePresentKHR(queues_[int(QueueKind::Graphics)].queue, &pi);
        }
    }
    {
        std::lock_guard<std::mutex> lock(swapMutex_);
        swapAcquired_ = false;
    }
    if (!submitted) {
        // The image stays the presentation engine's debt: the swapchain is made again at the next acquire.
        swapStale_ = true;
        return make_error(where + ": the barrier to PRESENT_SRC could not be submitted", "see errors() for the cause");
    }
    // Out of date or suboptimal (the window changed): shown or not, the swapchain is made again at the next acquire.
    // Android's loader answers suboptimal at every present while the presentation engine rotates (preTransform
    // IDENTITY against a rotated currentTransform): that one alone keeps the swapchain.
    if (r == VK_SUBOPTIMAL_KHR && suboptimal_only_by_rotation()) return {};
    if (r == VK_ERROR_OUT_OF_DATE_KHR || r == VK_SUBOPTIMAL_KHR) {
        swapStale_ = true;
        return {};
    }
    if (r == VK_ERROR_SURFACE_LOST_KHR) {
        // As at the acquire: the swapchain and its surface go now (destroy_swapchain waits for the GPU first).
        const Error lost = vk_fail(where, "vkQueuePresentKHR", r,
                                   "the window was destroyed: its swapchain is destroyed too; create_swapchain() on "
                                   "the new one");
        destroy_swapchain();
        return lost;
    }
    if (r != VK_SUCCESS)
        return vk_fail(where, "vkQueuePresentKHR", r,
                       "the device was lost: run with VulkanOptions::validation for the cause");
    return {};
}

void VulkanDevice::destroy_swapchain() {
    if (!swapchain_ && !surface_) return;
    release_swap_images();
    if (swapchain_) fn_.vkDestroySwapchainKHR(device_, swapchain_, nullptr);
    swapchain_ = VK_NULL_HANDLE;
    if (surface_) fn_.vkDestroySurfaceKHR(instance_, surface_, nullptr);
    surface_ = VK_NULL_HANDLE;
    swapLabel_.clear();
    swapFormat_ = PixelFormat::None;
    swapVkFormat_ = VK_FORMAT_UNDEFINED;
    swapColorSpace_ = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR;
    swapPresentMode_ = VK_PRESENT_MODE_FIFO_KHR;
    swapUsage_ = 0;
    swapStale_ = false;
    {
        std::lock_guard<std::mutex> lock(surfaceFormatsMutex_);
        surfaceFormats_.clear();
        surfaceFormatsKnown_ = false;
    }
    swapPreRotation_ = 0;
    swapPresenterRotates_ = false;
    std::lock_guard<std::mutex> lock(swapMutex_);
    swapWidth_ = swapHeight_ = 0;
    swapSamples_ = 1;
    swapDepthFormat_ = PixelFormat::None;
    swapIndex_ = 0;
    swapAcquired_ = false;
}

bool VulkanDevice::has_swapchain() const { return swapchain_ != VK_NULL_HANDLE; }

Image VulkanDevice::swapchain_image() const {
    std::lock_guard<std::mutex> lock(swapMutex_);
    if (!swapAcquired_ || swapIndex_ >= swapImages_.size()) return {};
    return swapImages_[swapIndex_].image;
}

int VulkanDevice::swapchain_image_count() const {
    std::lock_guard<std::mutex> lock(swapMutex_);
    return int(swapImages_.size());
}

VkPresentModeKHR VulkanDevice::swapchain_present_mode() const { return swapPresentMode_; }
std::uint64_t VulkanDevice::swapchain_recreations() const { return swapRecreations_; }
int VulkanDevice::swapchain_pre_rotation_degrees() const { return swapPreRotation_; }

// The surface is asked once per frame (the acquire and the present of a frame share the answer), not at every
// suboptimal result: while Android rotates the presentation, every present is suboptimal.
bool VulkanDevice::suboptimal_only_by_rotation() {
    if (!swapPresenterRotates_ || !surface_) return false;
    if (rotationOnlyAnswer_ >= 0) return rotationOnlyAnswer_ != 0;
    VkSurfaceCapabilitiesKHR caps{};
    if (fn_.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(physical_, surface_, &caps) != VK_SUCCESS) return false;
    bool only = true;  // the swapchain sets the size (0xFFFFFFFF): nothing else changed
    if (caps.currentExtent.width != 0xFFFFFFFFu) {
        std::lock_guard<std::mutex> lock(swapMutex_);
        only = int(caps.currentExtent.width) == swapWidth_ && int(caps.currentExtent.height) == swapHeight_;
    }
    rotationOnlyAnswer_ = only ? 1 : 0;
    return only;
}
void VulkanDevice::lose_swapchain_keep_surface_for_tests() {
    if (!swapchain_) return;
    release_swap_images();
    fn_.vkDestroySwapchainKHR(device_, swapchain_, nullptr);
    swapchain_ = VK_NULL_HANDLE;
}
void VulkanDevice::mark_swapchain_out_of_date_for_tests() { swapStale_ = true; }

}  // namespace fa::gpu::vk

#endif  // FA_VULKAN_BACKEND
