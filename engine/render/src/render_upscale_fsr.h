// The FidelityFX Super Resolution 3.1 provider of M78 (docs/design/ARCHITECTURE_RENDERING.md, "Upscale stage (M76)", "Vendor providers";
// docs/UPSCALING.md, "FSR 3.1"): AMD's temporal upscaler behind the `fsr` upscaler mode. Private to fa_render.
//
// No AMD header or binary is in the engine (decision D2 of M78): this file declares the C ABI of the FidelityFX API (the five-function `ffx`
// entry points and the structures of its upscale effect) the engine calls, written from AMD's documentation, and every function is taken
// from the loaded library through VendorLibrary::symbol into FsrApi. A test puts a fake library in with set_vendor_loader_for_test.
//
// The library is the FidelityFX loader of the backend (amd_fidelityfx_loader_dx12.dll, amd_fidelityfx_loader_vk.dll); it loads the upscaler
// provider DLL that sits next to it (amd_fidelityfx_upscaler_dx12.dll / _vk.dll), which `factoria setup fidelityfx` installs in the same folder.
#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "render_upscale_vendor.h"

namespace fa::render {

// ---- the engine's declarations of the FidelityFX C ABI -----------------------------------------------------------------------------------
// The names follow AMD's (ffx_api.h, ffx_api_types.h, ffx_upscale.h, ffx_api_dx12.h, ffx_api_vk.h) without the ffx prefix. The structures are
// laid out for a 64-bit process (pointers 8 bytes); the provider reports itself unavailable in a 32-bit build.
namespace ffx_abi {

using ReturnCode = std::uint32_t;  // ffxReturnCode_t
inline constexpr ReturnCode kOk = 0, kError = 1, kUnknownDescType = 2, kRuntimeError = 3, kNoProvider = 4, kMemoryError = 5,
                            kParameterError = 6, kNoSupportNewDescType = 7;

using Context = void*;  // ffxContext

// ffxApiHeader: every descriptor starts with it; `next` chains the optional ones.
struct Header {
    std::uint64_t type;
    Header* next;
};
using Message = void (*)(std::uint32_t type, const wchar_t* message);  // ffxApiMessage

// The descriptor types (the effect id of the upscaler is 0x00010000, the Vulkan backend's 0x01000000).
inline constexpr std::uint64_t kCreateBackendDx12 = 0x00000002, kCreateBackendVkDeprecated = 0x00000003,
                               kCreateBackendVk = 0x01000003, kCreateUpscale = 0x00010000, kDispatchUpscale = 0x00010001,
                               kQueryGetVersions = 4;

// The three structures the engine hands to a backend, and what a query answers.
struct Dimensions2D {
    std::uint32_t width, height;
};
struct FloatCoords2D {
    float x, y;
};
struct CreateBackendDx12Desc {  // ffxCreateBackendDX12Desc
    Header header;
    void* device;  // ID3D12Device*
};
struct VkDeviceContext {  // VkDeviceContext: the Vulkan device, its physical device and vkGetDeviceProcAddr
    void* device;
    void* physicalDevice;
    void (*deviceProcAddr)();
};
struct CreateBackendVkDesc {  // ffxCreateBackendVKDesc
    Header header;
    VkDeviceContext deviceContext;
};
struct CreateBackendVkDeprecatedDesc {  // ffxCreateBackendVKDesc_DEPRECATED (FSR 3.1.4's)
    Header header;
    VkDeviceContext deviceContext;
};
struct QueryGetVersions {  // ffxQueryDescGetVersions
    Header header;
    std::uint64_t createDescType;
    void* device;  // D3D12: ID3D12Device*; Vulkan: a VkDeviceContext*
    std::uint64_t* outputCount;
    std::uint64_t* versionIds;
    const char** versionNames;
};

// FfxApiResourceDescription / FfxApiResource: a texture the effect reads or writes, with the state the application left it in.
struct ResourceDescription {
    std::uint32_t type, format, width, height, depth, mipCount, flags, usage;
};
struct Resource {
    void* resource;  // ID3D12Resource* or VkImage
    ResourceDescription description;
    std::uint32_t state;
};
inline constexpr std::uint32_t kResourceTexture2d = 2;  // FFX_API_RESOURCE_TYPE_TEXTURE2D
inline constexpr std::uint32_t kUsageReadOnly = 0, kUsageUav = 1u << 1;
// FFX_API_RESOURCE_STATE_*: the engine declares its inputs in the state of a shader read (NativeState::ShaderRead: D3D12 pixel and non-pixel
// shader resource, Vulkan SHADER_READ_ONLY_OPTIMAL) and the output as an unordered access.
inline constexpr std::uint32_t kStateUnorderedAccess = 1u << 1, kStatePixelComputeRead = (1u << 3) | (1u << 2);

// FFX_API_SURFACE_FORMAT_* (the ones a frame of the engine has).
inline constexpr std::uint32_t kFormatUnknown = 0, kFormatR32G32B32A32Float = 3, kFormatR16G16B16A16Float = 4, kFormatR8G8B8A8Unorm = 10,
                               kFormatR8G8B8A8Srgb = 12, kFormatB8G8R8A8Unorm = 14, kFormatB8G8R8A8Srgb = 15, kFormatR11G11B10Float = 16,
                               kFormatR10G10B10A2Unorm = 17, kFormatR16G16Float = 18, kFormatR8Unorm = 25, kFormatR32Float = 28,
                               kFormatR9G9B9E5SharedExp = 29;

// ffxCreateContextDescUpscale and its flags (FfxApiCreateContextUpscaleFlags).
struct CreateUpscaleDesc {
    Header header;
    std::uint32_t flags;
    Dimensions2D maxRenderSize;
    Dimensions2D maxUpscaleSize;
    Message message;
};
inline constexpr std::uint32_t kEnableHdr = 1u << 0, kEnableDepthInverted = 1u << 3, kEnableDepthInfinite = 1u << 4,
                               kEnableDynamicResolution = 1u << 6, kEnableNonLinearColorSpace = 1u << 8;

// ffxDispatchDescUpscale and its flags (FfxApiDispatchFsrUpscaleFlags).
struct DispatchUpscaleDesc {
    Header header;
    void* commandList;  // ID3D12GraphicsCommandList* or VkCommandBuffer
    Resource color, depth, motionVectors, exposure, reactive, transparencyAndComposition, output;
    FloatCoords2D jitterOffset;
    FloatCoords2D motionVectorScale;
    Dimensions2D renderSize;
    Dimensions2D upscaleSize;
    bool enableSharpening;
    float sharpness;
    float frameTimeDelta;  // milliseconds
    float preExposure;
    bool reset;
    float cameraNear;
    float cameraFar;
    float cameraFovAngleVertical;  // radians
    float viewSpaceToMetersFactor;
    std::uint32_t flags;
};
inline constexpr std::uint32_t kFlagNonLinearColorSrgb = 1u << 1;

// The five functions of the library (ffxCreateContext, ffxDestroyContext, ffxConfigure, ffxQuery, ffxDispatch; the engine does not call
// ffxConfigure). A null allocation callbacks pointer is the library's own allocator.
using CreateContextFn = ReturnCode (*)(Context* context, Header* desc, const void* allocationCallbacks);
using DestroyContextFn = ReturnCode (*)(Context* context, const void* allocationCallbacks);
using QueryFn = ReturnCode (*)(Context* context, Header* desc);
using DispatchFn = ReturnCode (*)(Context* context, const Header* desc);

}  // namespace ffx_abi

// The functions the provider calls, taken from the library (fsr_load_api).
struct FsrApi {
    ffx_abi::CreateContextFn createContext = nullptr;
    ffx_abi::DestroyContextFn destroyContext = nullptr;
    ffx_abi::QueryFn query = nullptr;
    ffx_abi::DispatchFn dispatch = nullptr;
};

// The library `backend` loads: the FidelityFX loader of Direct3D 12 or of Vulkan (any other backend: the Direct3D 12 one, which the probe
// never asks for, because FSR does not draw there).
VendorLibrarySpec fsr_library_spec(gpu::Backend backend);

// Takes the functions from `lib`. "" when all are there, else the name of the first missing one.
std::string fsr_load_api(VendorLibrary& lib, FsrApi& api);

// What FSR needs of a Vulkan device. The FidelityFX Vulkan backend makes its own pipelines and image views from the VkImage handles it is given
// and loads its functions with the vkGetDeviceProcAddr the engine passes, so it needs no instance or device extension of the engine's:
// `instanceExtensions` and `deviceExtensions` (required) are empty. `optionalDeviceExtensions` are the ones it uses when the device has
// them (a faster shader variant); the engine's device does not turn them on today (no device hook of FSR is registered: nothing is required).
// `minApiVersion` is the lowest Vulkan version (VK_MAKE_API_VERSION) of the device.
struct FsrVulkanRequirements {
    std::vector<std::string> instanceExtensions, deviceExtensions, optionalDeviceExtensions;
    std::uint32_t minApiVersion = 0;
};
FsrVulkanRequirements fsr_vulkan_requirements();

// The FSR quality mode of an M76 quality (FFX_UPSCALE_QUALITY_MODE_*): NativeAA 0 (1.0x), Quality 1 (1.5x), Balanced 2 (1.7x), Performance 3
// (2.0x), UltraPerformance 4 (3.0x), which are the five names of `quality` in order. The engine feeds its own render size; the mode only
// keys the context (a change of quality makes a new one).
std::int32_t fsr_quality_mode(UpscalerQuality quality);
// The per-dimension upscale ratio of a mode (1, 1.5, 1.7, 2, 3; 0 for a number that is none).
float fsr_quality_ratio(std::int32_t mode);

// The flags of the context (FfxApiCreateContextUpscaleFlags): the depth is always the reversed infinite one the preparation pass makes; linear
// light above 1 is HDR input, display values are non-linear input; `dynamicResolution` says the render size moves under the maximum.
std::uint32_t fsr_create_flags(bool linear, bool dynamicResolution);
// The flags of a dispatch (FfxApiDispatchFsrUpscaleFlags): display values are sRGB (a PQ output is not told apart).
std::uint32_t fsr_dispatch_flags(bool linear);

// The FFX surface format of an engine format (ffx_abi::kFormat...), kFormatUnknown for a format FSR has no name for.
std::uint32_t fsr_surface_format(gpu::PixelFormat format);

// "ok", "runtime error", ... for an ffxReturnCode_t; "code 12" for a number this build does not know.
std::string fsr_result_text(std::uint32_t code);

// The major and minor numbers at the start of a provider version name ("3.1.4", "FSR 3.1.0"): the first two numbers in it. False when it has
// no digit at all.
bool fsr_parse_version(std::string_view name, int& major, int& minor);

// A new FSR provider (index 2 of vendor_provider()). It is a process-wide object: one context, for the device that drew last.
std::unique_ptr<VendorUpscaler> make_fsr_provider();

}  // namespace fa::render
