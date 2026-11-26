// The FSR 3 frame generation provider of M78 (docs/FRAME_GENERATION.md, "AMD FSR 3 frame generation"; docs/design/ARCHITECTURE_RENDERING_HOOKS.md,
// "Frame generation (M78)"): AMD FidelityFX's frame interpolation behind the `fsr` frame generation mode. Private to fa_render.
//
// No AMD header or binary is in the engine (decision D2 of M78): this file declares the C ABI of the parts of the FidelityFX API the provider
// calls (the frame generation effect, and its swapchain on Direct3D 12 and Vulkan), written from the public SDK headers (FidelityFX SDK 2.4:
// ffx_framegeneration.h, dx12/ffx_api_framegeneration_dx12.h, vk/ffx_api_framegeneration_vk.h), and every function is taken from the loaded library
// through VendorLibrary::symbol into FsrFgApi. The library is the one FSR 3.1 uses (render_upscale_fsr.h: amd_fidelityfx_loader_dx12.dll or
// _vk.dll, installed by `factoria setup fidelityfx`). A test puts a fake library in with set_vendor_loader_for_test.
//
// How it takes part: the provider's DeviceHook makes the window's swapchain (FidelityFX's frame interpolation swapchain: a proxy that
// implements IDXGISwapChain4 on Direct3D 12 and replaces the VkSwapchainKHR functions on Vulkan) when the device is made. Then, on the first frame
// it is given, the provider makes the frame generation context, and each frame it configures it (enable, the picture without the screen-space
// items, the frame number) and prepares it (the depth, the motion, the camera). The proxy swapchain calls back into the context at present time
// to dispatch the interpolation and composites the screen-space items from the two pictures.
#pragma once

#include <cstdint>
#include <memory>
#include <string>

#include "render_framegen.h"
#include "render_upscale_fsr.h"

namespace fa::render {

// ---- the engine's declarations of the FidelityFX frame generation C ABI ----------------------------------------------------------------
// Laid out for a 64-bit process, like the upscale ABI (render_upscale_fsr.h), whose Header, Resource, Dimensions2D and FloatCoords2D these use.
namespace ffx_abi {

struct Rect2D {  // FfxApiRect2D
    std::int32_t left, top, width, height;
};

// The descriptor types (FFX_API_MAKE_EFFECT_SUB_ID / FFX_API_MAKE_BACKEND_EFFECT_SUB_ID of the SDK's headers).
inline constexpr std::uint64_t kCreateFrameGeneration = 0x00020001, kConfigureFrameGeneration = 0x00020002,
                               kCreateFrameGenerationHudless = 0x00020009,
                               kDispatchFrameGenerationPrepareV2 = 0x0002000c,
                               kCreateFrameGenerationVersion = 0x0002000e;
inline constexpr std::uint64_t kCreateSwapchainForHwndDx12 = 0x00030006, kCreateSwapchainVersionDx12 = 0x0003000b,
                               kDispatchSwapchainWaitDx12 = 0x00030007;
inline constexpr std::uint64_t kCreateSwapchainVk = 0x00040001, kCreateSwapchainVersionVk = 0x0004000a,
                               kQuerySwapchainFunctionsVk = 0x00040005, kDispatchSwapchainWaitVk = 0x00040007;
// The API versions the engine was written against (FFX_FRAMEGENERATION_VERSION 4.0.2; the swapchains' 4.0.0): (major << 22) | (minor << 12) | patch.
inline constexpr std::uint32_t kFrameGenerationVersion = (4u << 22) | 2u, kSwapchainVersion = 4u << 22;

// FfxApiCreateContextFramegenerationFlags.
inline constexpr std::uint32_t kFgJitterCancellation = 1u << 2, kFgDepthInverted = 1u << 3, kFgDepthInfinite = 1u << 4,
                               kFgHdr = 1u << 5;

struct CreateFrameGenerationDesc {  // ffxCreateContextDescFrameGeneration
    Header header;
    std::uint32_t flags;
    Dimensions2D displaySize;
    Dimensions2D maxRenderSize;
    std::uint32_t backBufferFormat;
};
struct CreateHudlessDesc {  // ffxCreateContextDescFrameGenerationHudless
    Header header;
    std::uint32_t hudlessBackBufferFormat;
};
struct CreateVersionDesc {  // ffxCreateContextDescFrameGeneration[SwapChain]Version[DX12|VK]
    Header header;
    std::uint32_t version;
};
// The callbacks the swapchain calls: only a pointer to the descriptor is read, whose first member is the header.
using PresentCallback = ReturnCode (*)(void* params,
                                       void* userContext);  // FfxApiPresentCallbackFunc (the engine passes none)
using DispatchCallback = ReturnCode (*)(void* params, void* userContext);  // FfxApiFrameGenerationDispatchFunc
struct ConfigureFrameGenerationDesc {                                      // ffxConfigureDescFrameGeneration
    Header header;
    void* swapChain;  // IDXGISwapChain4* or the VkSwapchainKHR
    PresentCallback presentCallback;
    void* presentCallbackUserContext;
    DispatchCallback frameGenerationCallback;
    void* frameGenerationCallbackUserContext;
    bool frameGenerationEnabled;
    bool allowAsyncWorkloads;
    Resource hudlessColor;
    std::uint32_t flags;
    bool onlyPresentGenerated;
    Rect2D generationRect;
    std::uint64_t frameId;
};
struct PrepareV2Desc {  // ffxDispatchDescFrameGenerationPrepareV2
    Header header;
    std::uint64_t frameId;
    std::uint32_t flags;
    void* commandList;
    Dimensions2D renderSize;
    FloatCoords2D jitterOffset;
    FloatCoords2D motionVectorScale;
    float frameTimeDelta;  // milliseconds
    bool reset;
    float cameraNear, cameraFar, cameraFovAngleVertical, viewSpaceToMetersFactor;
    Resource depth, motionVectors;
    float cameraPosition[3], cameraUp[3], cameraRight[3], cameraForward[3];
};

struct SwapchainForHwndDx12Desc {  // ffxCreateContextDescFrameGenerationSwapChainForHwndDX12
    Header header;
    void** swapchain;  // IDXGISwapChain4** out
    const void* hwnd;
    void* desc;            // DXGI_SWAP_CHAIN_DESC1*
    void* fullscreenDesc;  // DXGI_SWAP_CHAIN_FULLSCREEN_DESC*, null
    void* dxgiFactory;     // IDXGIFactory*
    void* gameQueue;       // ID3D12CommandQueue*
};
struct QueueInfo {  // VkQueueInfoFFXAPI
    void* queue;
    std::uint32_t familyIndex;
    void* submitFunc;  // PFN_vkQueueSubmitFFXAPI: none (the engine's queues are not shared with other threads' submits)
};
inline constexpr std::size_t kVkSwapchainCreateInfoSize = 104;  // sizeof(VkSwapchainCreateInfoKHR) on a 64-bit target
struct SwapchainVkDesc {                                        // ffxCreateContextDescFrameGenerationSwapChainVK
    Header header;
    void* physicalDevice;
    void* device;
    std::uint64_t* swapchain;  // VkSwapchainKHR*: in the one to replace (destroyed by the call), out the new one
    const void* allocator;
    alignas(8) std::uint8_t createInfo[kVkSwapchainCreateInfoSize];  // VkSwapchainCreateInfoKHR
    QueueInfo gameQueue, asyncComputeQueue, presentQueue, imageAcquireQueue;
};
// The functions that replace the vkXxxSwapchainKHR ones (ffxQueryDescSwapchainReplacementFunctionsVK).
struct SwapchainFunctionsVk {
    Header header;
    void* createSwapchain;  // with an extra void* pContext
    void* destroySwapchain;
    void* getSwapchainImages;
    void* acquireNextImage;
    void* queuePresent;
    void* setHdrMetadata;
    void* getLastPresentCount;
};
struct WaitForPresentsDesc {  // ffxDispatchDescFrameGenerationSwapChainWaitForPresents[DX12|VK]
    Header header;
};

using ConfigureFn = ReturnCode (*)(Context* context, const Header* desc);

}  // namespace ffx_abi

// The functions the provider calls, taken from the library (fsr_fg_load_api): the five of the FidelityFX API.
struct FsrFgApi {
    ffx_abi::CreateContextFn createContext = nullptr;
    ffx_abi::DestroyContextFn destroyContext = nullptr;
    ffx_abi::ConfigureFn configure = nullptr;
    ffx_abi::QueryFn query = nullptr;
    ffx_abi::DispatchFn dispatch = nullptr;
};
// Takes the functions from `lib`. "" when all are there, else the name of the first missing one.
std::string fsr_fg_load_api(VendorLibrary& lib, FsrFgApi& api);

// The flags of the frame generation context (FfxApiCreateContextFramegenerationFlags) a frame asks for: the depth the frame carries, whether
// the motion vectors have the jitter in them, and an HDR picture.
std::uint32_t fsr_fg_create_flags(const FrameGenFrame& frame);

// The FFX surface format of a swapchain's DXGI_FORMAT or VkFormat (ffx_abi::kFormat..., kFormatUnknown for a format FSR has no name for).
std::uint32_t fsr_fg_dxgi_format(std::uint32_t dxgiFormat);
std::uint32_t fsr_fg_vulkan_format(std::uint32_t vkFormat);

// The FSR 3 frame generation provider (slot Fsr), registered by the provider table (render_framegen.cpp).
std::shared_ptr<FrameGenProvider> make_fsr_framegen_provider();

// Test seam: the call that gives back one reference of a COM object the provider holds (the proxy swapchain of a failed create): IUnknown::Release
// on Windows, nothing elsewhere (no COM there). A test puts its own in to see which pointer is released; nullptr puts the default back.
using FsrComReleaseFn = void (*)(void* object);
void set_fsr_com_release_for_test(FsrComReleaseFn fn);

}  // namespace fa::render
