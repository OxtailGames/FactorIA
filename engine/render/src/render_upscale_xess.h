// The XeSS Super Resolution provider of M78 (docs/design/ARCHITECTURE_RENDERING.md, "Upscale stage (M76)", "Vendor providers"; docs/UPSCALING_VENDORS.md,
// "Intel XeSS"): Intel's temporal upscaler behind the `xess` upscaler mode. Private to fa_render.
//
// No Intel header or binary is in the engine (decision D2 of M78): this file declares the C ABI of XeSS 3.x the engine calls, written from the
// SDK's documentation (the structures and enums with the values the library was built with), and every function is taken from the loaded
// library through VendorLibrary::symbol into XessApi. A test puts a fake library in with set_vendor_loader_for_test.
#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include "fa/core/types.h"

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
using VkCreateContextFn = std::int32_t (*)(void* instance, void* physicalDevice, void* device, Context*);
using VkInitFn = std::int32_t (*)(Context, const VkInitParams*);
using VkExecuteFn = std::int32_t (*)(Context, void* commandBuffer, const VkExecuteParams*);

}  // namespace xess_abi

// The functions one backend uses, taken from the library (xess_load_api). Null members are the functions another backend uses.
struct XessApi {
    xess_abi::GetVersionFn getVersion = nullptr;
    xess_abi::DestroyContextFn destroyContext = nullptr;
    xess_abi::SetVelocityScaleFn setVelocityScale = nullptr;
    xess_abi::D3d12CreateContextFn d3d12Create = nullptr;
    xess_abi::D3d12InitFn d3d12Init = nullptr;
    xess_abi::D3d12ExecuteFn d3d12Execute = nullptr;
    xess_abi::D3d11CreateContextFn d3d11Create = nullptr;
    xess_abi::D3d11InitFn d3d11Init = nullptr;
    xess_abi::D3d11ExecuteFn d3d11Execute = nullptr;
    xess_abi::VkGetRequiredInstanceExtensionsFn vkInstanceExtensions = nullptr;
    xess_abi::VkGetRequiredDeviceExtensionsFn vkDeviceExtensions = nullptr;
    xess_abi::VkCreateContextFn vkCreate = nullptr;
    xess_abi::VkInitFn vkInit = nullptr;
    xess_abi::VkExecuteFn vkExecute = nullptr;
};

// The library `backend` loads: libxess.dll (D3D12, Vulkan) or libxess_dx11.dll (Direct3D 11, Intel Arc only; the SDK ships it apart).
VendorLibrarySpec xess_library_spec(gpu::Backend backend);

// Takes the functions `backend` needs from `lib`. "" when all are there, else a sentence that names the first missing one.
std::string xess_load_api(VendorLibrary& lib, gpu::Backend backend, XessApi& api);

// What XeSS needs of a Vulkan device: the instance and device extensions to enable, and the lowest API version.
struct XessVulkanRequirements {
    std::vector<std::string> instanceExtensions, deviceExtensions;
    std::uint32_t minApiVersion = 0;  // VK_MAKE_API_VERSION, 0 = no demand
};
// Asks the library on `api` (loaded for Vulkan). The device extensions need the instance and the physical device: with a null `instance`
// or `physicalDevice` only the instance extensions and the API version are asked.
Result<XessVulkanRequirements> xess_vulkan_requirements(const XessApi& api, void* instance, void* physicalDevice);
// The same, finding and loading the library through vendor_loader() first.
// M78-P2b: the Vulkan device creation calls this (instance null: the instance extensions to enable; then with the picked physical device:
// the device extensions) and enables them, and vendor_env_of fills VendorEnv's extension lists from what it enabled.
Result<XessVulkanRequirements> xess_vulkan_requirements(void* instance = nullptr, void* physicalDevice = nullptr);

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
