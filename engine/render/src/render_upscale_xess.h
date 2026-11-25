// The XeSS Super Resolution provider of M78 (docs/design/ARCHITECTURE_RENDERING.md, "Upscale stage (M76)", "Vendor providers"; docs/UPSCALING_VENDORS.md,
// "Intel XeSS"): Intel's temporal upscaler behind the `xess` upscaler mode. Private to fa_render.
//
// No Intel header or binary is in the engine (decision D2 of M78): this file declares the C ABI of XeSS 3.x the engine calls, written from the
// SDK's documentation (the structures and enums with the values the library was built with), and every function is taken from the loaded
// library through VendorLibrary::symbol into XessApi. A test puts a fake library in with set_vendor_loader_for_test.
#pragma once

#include <cstdint>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "fa/core/types.h"

#include "gpu/device_hooks.h"
#include "render_upscale_vendor.h"

namespace fa::render {

// ---- the engine's declarations of the XeSS C ABI ---------------------------------------------------------------------------------------
// The names follow the SDK's (xess.h, xess_d3d12.h, xess_d3d11.h, xess_vk.h) without the xess_ prefix. The library is 64-bit only, and its
// structures are packed to 8 bytes (every member is naturally aligned, so the packing changes nothing but the end padding).
namespace xess_abi {

#pragma pack(push, 8)
struct Version {
    std::uint16_t major, minor, patch, reserved;
};
struct Coord {
    std::uint32_t x, y;
};
// xess_2d_t: a size in pixels (the same two numbers as Coord).
using Size2d = Coord;
// A D3D12 execution (xess_d3d12_execute_params_t); the D3D11 one is the same without the last two members. The resources are
// ID3D12Resource* / ID3D11Resource*.
struct D3d12ExecuteParams {
    void *color, *velocity, *depth, *exposureTexture, *responsiveMask, *output;
    float jitterX, jitterY, exposureScale;
    std::uint32_t resetHistory, inputWidth, inputHeight;
    Coord inputColorBase, inputMotionVectorBase, inputDepthBase, inputResponsiveMaskBase, reserved0, outputColorBase;
    void* descriptorHeap;  // null: XeSS keeps its own (XESS_INIT_FLAG_EXTERNAL_DESCRIPTOR_HEAP is not set)
    std::uint32_t descriptorHeapOffset;
};
struct D3d11ExecuteParams {
    void *color, *velocity, *depth, *exposureTexture, *responsiveMask, *output;
    float jitterX, jitterY, exposureScale;
    std::uint32_t resetHistory, inputWidth, inputHeight;
    Coord inputColorBase, inputMotionVectorBase, inputDepthBase, inputResponsiveMaskBase, reserved0, outputColorBase;
};
// An image of the Vulkan execution (xess_vk_image_view_info); the handles are VkImageView and VkImage as 64-bit numbers.
struct VkImageViewInfo {
    std::uint64_t imageView, image;
    std::uint32_t aspectMask, baseMipLevel, levelCount, baseArrayLayer, layerCount;  // VkImageSubresourceRange
    std::uint32_t format;                                                            // VkFormat
    std::uint32_t width, height;
};
struct VkExecuteParams {
    VkImageViewInfo color, velocity, depth, exposureTexture, responsiveMask, output;
    float jitterX, jitterY, exposureScale;
    std::uint32_t resetHistory, inputWidth, inputHeight;
    Coord inputColorBase, inputMotionVectorBase, inputDepthBase, inputResponsiveMaskBase, reserved0, outputColorBase;
};
// The initialisation of a context (xess_d3d12_init_params_t, xess_vk_init_params_t; the D3D11 one stops after initFlags).
struct D3d12InitParams {
    Coord outputResolution;
    std::int32_t quality;
    std::uint32_t initFlags, creationNodeMask, visibleNodeMask;
    void* tempBufferHeap;
    std::uint64_t bufferHeapOffset;
    void* tempTextureHeap;
    std::uint64_t textureHeapOffset;
    void* pipelineLibrary;
};
struct D3d11InitParams {
    Coord outputResolution;
    std::int32_t quality;
    std::uint32_t initFlags;
};
struct VkInitParams {
    Coord outputResolution;
    std::int32_t quality;
    std::uint32_t initFlags, creationNodeMask, visibleNodeMask;
    std::uint64_t tempBufferHeap, bufferHeapOffset, tempTextureHeap, textureHeapOffset, pipelineCache;
};
#pragma pack(pop)

// xess_quality_settings_t
inline constexpr std::int32_t kQualityUltraPerformance = 100, kQualityPerformance = 101, kQualityBalanced = 102,
                              kQualityQuality = 103, kQualityUltraQuality = 104, kQualityUltraQualityPlus = 105,
                              kQualityAa = 106;
// xess_init_flags_t
inline constexpr std::uint32_t kInitResponsivePixelMask = 1u << 3, kInitLdrInputColor = 1u << 6;
// xess_result_t: success is 0, a warning is positive, an error negative.
inline constexpr std::int32_t kResultSuccess = 0, kResultWarningOldDriver = 2;

using Context = struct ContextTag*;  // xess_context_handle_t

// The functions of the library, as the SDK declares them (XESS_API is the C calling convention).
using GetVersionFn = std::int32_t (*)(Version*);
using DestroyContextFn = std::int32_t (*)(Context);
using SetVelocityScaleFn = std::int32_t (*)(Context, float, float);
// xessGetOptimalInputResolution: for an output size and a quality setting, the render size XeSS likes best and the smallest and largest it
// accepts (what a dynamic resolution may move between without initialising the context again). The context needs no init for it.
using GetOptimalInputResolutionFn = std::int32_t (*)(Context, const Size2d* output, std::int32_t quality,
                                                     Size2d* optimal, Size2d* minimum, Size2d* maximum);
using D3d12CreateContextFn = std::int32_t (*)(void* device, Context*);
using D3d12InitFn = std::int32_t (*)(Context, const D3d12InitParams*);
using D3d12ExecuteFn = std::int32_t (*)(Context, void* commandList, const D3d12ExecuteParams*);
using D3d11CreateContextFn = std::int32_t (*)(void* device, Context*);
using D3d11InitFn = std::int32_t (*)(Context, const D3d11InitParams*);
using D3d11ExecuteFn = std::int32_t (*)(Context, const D3d11ExecuteParams*);
using VkGetRequiredInstanceExtensionsFn = std::int32_t (*)(std::uint32_t* count, const char* const** names,
                                                           std::uint32_t* minApiVersion);
using VkGetRequiredDeviceExtensionsFn = std::int32_t (*)(void* instance, void* physicalDevice, std::uint32_t* count,
                                                         const char* const** names);
// xessVKGetRequiredDeviceFeatures: the chain of Vulkan feature structs (VkPhysicalDeviceFeatures2, Vulkan11/12/13Features; each begins
// with sType and pNext) the library owns and XeSS needs enabled. Unverified against a real library: docs/UPSCALING_VENDORS.md, "Hardware check list".
using VkGetRequiredDeviceFeaturesFn = std::int32_t (*)(void* instance, void* physicalDevice, void** featureChain);
using VkCreateContextFn = std::int32_t (*)(void* instance, void* physicalDevice, void* device, Context*);
using VkInitFn = std::int32_t (*)(Context, const VkInitParams*);
using VkExecuteFn = std::int32_t (*)(Context, void* commandBuffer, const VkExecuteParams*);

}  // namespace xess_abi

// The functions one backend uses, taken from the library (xess_load_api). Null members are the functions another backend uses.
struct XessApi {
    xess_abi::GetVersionFn getVersion = nullptr;
    xess_abi::DestroyContextFn destroyContext = nullptr;
    xess_abi::SetVelocityScaleFn setVelocityScale = nullptr;
    // Optional: without it (a library that predates it) the context is initialised again at every render size.
    xess_abi::GetOptimalInputResolutionFn getOptimalInputResolution = nullptr;
    xess_abi::D3d12CreateContextFn d3d12Create = nullptr;
    xess_abi::D3d12InitFn d3d12Init = nullptr;
    xess_abi::D3d12ExecuteFn d3d12Execute = nullptr;
    xess_abi::D3d11CreateContextFn d3d11Create = nullptr;
    xess_abi::D3d11InitFn d3d11Init = nullptr;
    xess_abi::D3d11ExecuteFn d3d11Execute = nullptr;
    xess_abi::VkGetRequiredInstanceExtensionsFn vkInstanceExtensions = nullptr;
    xess_abi::VkGetRequiredDeviceExtensionsFn vkDeviceExtensions = nullptr;
    xess_abi::VkGetRequiredDeviceFeaturesFn vkDeviceFeatures =
        nullptr;  // optional: a library without it asks for no feature
    xess_abi::VkCreateContextFn vkCreate = nullptr;
    xess_abi::VkInitFn vkInit = nullptr;
    xess_abi::VkExecuteFn vkExecute = nullptr;
};

// The library `backend` loads: libxess.dll (D3D12, Vulkan) or libxess_dx11.dll (Direct3D 11, Intel Arc only; the SDK ships it apart).
VendorLibrarySpec xess_library_spec(gpu::Backend backend);

// Takes the functions `backend` needs from `lib`. "" when all are there, else a sentence that names the first missing one.
std::string xess_load_api(VendorLibrary& lib, gpu::Backend backend, XessApi& api);

// What XeSS needs of a Vulkan device: the instance and device extensions to enable, the device features, and the lowest API version.
struct XessVulkanRequirements {
    std::vector<std::string> instanceExtensions, deviceExtensions;
    // The feature structs XeSS asked for, each the bytes of a whole Vk*Features struct as gpu::VulkanDeviceRequest::features takes them
    // (copied out of the library's own memory). Only with an instance and a physical device.
    std::vector<std::vector<std::uint8_t>> features;
    std::uint32_t minApiVersion = 0;  // VK_MAKE_API_VERSION, 0 = no demand
};
// Asks the library on `api` (loaded for Vulkan). The device extensions need the instance and the physical device: with a null `instance`
// or `physicalDevice` only the instance extensions and the API version are asked.
Result<XessVulkanRequirements> xess_vulkan_requirements(const XessApi& api, void* instance, void* physicalDevice);
// The same, finding and loading the library through vendor_loader() first.
Result<XessVulkanRequirements> xess_vulkan_requirements(void* instance = nullptr, void* physicalDevice = nullptr);

// What the device made last enabled for XeSS (empty lists when the hook was not available there), and why XeSS's hook is not available ("" when
// it is): vendor_env_of puts the lists in VendorEnv, and the probe quotes the reason.
struct XessVulkanGrant {
    std::vector<std::string> instanceExtensions, deviceExtensions;
    std::string unavailableReason;
};

// The device hook of XeSS on Vulkan (docs/UPSCALING_VENDORS.md, "Intel XeSS"): it asks the library what it needs and the Vulkan device enables
// it (the instance extensions before vkCreateInstance, the device extensions and feature structs before vkCreateDevice). It asks for nothing
// where XeSS is not installed (the probe says so), and it is unavailable on a device that lacks what XeSS asks for (the reason is quoted by
// the probe). D3D12 and D3D11 devices do not call it.
class XessDeviceHook final : public gpu::DeviceHook {
public:
    std::string_view name() const override { return "XeSS"; }
    void vulkan_instance_request(gpu::VulkanInstanceRequest& request) override;
    void vulkan_device_request(const gpu::VulkanPhysicalDevice& physical, gpu::VulkanDeviceRequest& request) override;
    void vulkan_device_created(const gpu::VulkanDeviceCreated& made) override;
    void device_destroying() override;
    XessVulkanGrant grant() const;

private:
    mutable std::mutex mutex_;
    bool installed_ = false;                                // the library answered the instance request
    std::vector<std::string> askedInstance_, askedDevice_;  // what the last request asked
    XessVulkanGrant granted_;                               // what the device made last enabled
    int live_ = 0;  // the devices made and not yet destroyed (device_destroying names none)
};
std::shared_ptr<XessDeviceHook> make_xess_device_hook();
// Registers the process's hook once (the renderer calls it before it makes a Vulkan device); xess_vulkan_grant() is that hook's grant.
void register_xess_device_hook();
XessVulkanGrant xess_vulkan_grant();

// The XeSS quality setting (xess_abi::kQuality...) that draws at an upscale ratio (output size / render size, the larger of the two axes), and
// the ratio a setting stands for (XeSS 3.x: AA 1.0, UltraQualityPlus 1.3, UltraQuality 1.5, Quality 1.7, Balanced 2.0, Performance 2.3,
// UltraPerformance 3.0; M76's quality names are 1.0, 1.5, 1.7, 2.0, 3.0 and so land on a setting exactly). The nearest setting wins, and
// `current` (0 = none) is kept while the ratio is within 0.15 of it, so a dynamic resolution that wobbles around a boundary does not
// initialise the context again every few frames.
std::int32_t xess_quality_for_ratio(float ratio, std::int32_t current = 0);
float xess_quality_ratio(std::int32_t setting);
// "success", "unsupported device", ... for an xess_result_t; "result -12" for a code this build does not know.
std::string xess_result_text(std::int32_t result);

// A new XeSS provider (index 1 of vendor_provider()). It is a process-wide object: one context, for the device that drew last.
std::unique_ptr<VendorUpscaler> make_xess_provider();

}  // namespace fa::render
