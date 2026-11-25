// The Intel XeSS frame generation provider of M78 (render_framegen.h; docs/FRAME_GENERATION.md, "XeSS Frame Generation"). Private to fa_render.
//
// No Intel header or binary is in the engine (decision D2 of M78): this file declares the C ABI of XeSS-FG's swapchain library the engine
// calls, written from the public headers of github.com/intel/xess (inc/xess_fg/xefg_swapchain.h and xefg_swapchain_d3d12.h, XeSS 3.0.2, MIT).
// Every function is taken from libxess_fg.dll (installed by `factoria setup xess`, next to libxess.dll and libxell.dll) through
// VendorLibrary::symbol into XefgApi. Direct3D 12 on Windows only, 64-bit only: the structs below are the SDK's with its 8-byte packing.
//
// XeSS-FG is a PROXY swapchain: it makes the window's swapchain itself and presents the rendered and the generated frames in order, so this
// provider is also the device hook that makes the swapchain (DeviceHook::d3d12_create_swapchain). It needs Intel XeLL (xell_share(): the
// context XeLL's provider owns) and tells it to the swapchain before the swapchain exists. The seam (render_framegen.h) starts the provider
// on the device afterwards; the provider then only enables and disables the generation and tags each frame.
#pragma once

#include <cstdint>
#include <memory>
#include <string>

#include "render_framegen.h"

namespace fa::render {

namespace xefg_abi {

// xefg_swapchain_result_t: success is 0, a warning positive, an error negative.
inline constexpr std::int32_t kResultSuccess = 0;
using Handle = struct SwapChainTag*;  // xefg_swapchain_handle_t

// xefg_swapchain_resource_type_t, xefg_swapchain_resource_validity_t, xefg_swapchain_ui_mode_t
inline constexpr std::int32_t kResourceDepth = 1, kResourceMotionVector = 2;
inline constexpr std::int32_t kValidityOnlyNow = 1;
inline constexpr std::int32_t kUiModeNone = 1;
// D3D12_RESOURCE_STATE_COPY_SOURCE: the state a resource tagged ONLY_NOW is handed over in.
inline constexpr std::uint32_t kStateCopySource = 0x800;

#pragma pack(push, 8)
struct Version {  // xefg_swapchain_version_t
    std::uint16_t major, minor, patch, reserved;
};
struct Dim2 {  // xefg_swapchain_2d_t
    std::uint32_t x, y;
};
// xefg_swapchain_frame_constant_data_t: the matrices are row-major with the row-vector convention (the memory of a column-major Mat4).
struct FrameConstants {
    float viewMatrix[16];
    float projectionMatrix[16];
    float jitterOffsetX, jitterOffsetY;
    float motionVectorScaleX, motionVectorScaleY;
    std::uint32_t resetHistory;
    float frameRenderTime;
};
// xefg_swapchain_present_status_t
struct PresentStatus {
    std::uint32_t framesPresented;
    std::int32_t frameGenResult;
    std::uint32_t isFrameGenEnabled;
};
// xefg_swapchain_d3d12_init_params_t
struct D3d12InitParams {
    void* applicationSwapChain;  // IDXGISwapChain*: null (the library makes the swapchain from the description)
    std::uint32_t initFlags;
    std::uint32_t maxInterpolatedFrames;
    std::uint32_t creationNodeMask;
    std::uint32_t visibleNodeMask;
    void* tempBufferHeap;  // ID3D12Heap*: null (the library allocates)
    std::uint64_t bufferHeapOffset;
    void* tempTextureHeap;  // ID3D12Heap*
    std::uint64_t textureHeapOffset;
    void* pipelineLibrary;  // ID3D12PipelineLibrary*
    std::int32_t uiMode;    // xefg_swapchain_ui_mode_t
};
// xefg_swapchain_d3d12_resource_data_t
struct D3d12ResourceData {
    std::int32_t type;      // xefg_swapchain_resource_type_t
    std::int32_t validity;  // xefg_swapchain_resource_validity_t
    Dim2 resourceBase;
    Dim2 resourceSize;
    void* resource;  // ID3D12Resource*
    std::uint32_t incomingState;
};
#pragma pack(pop)
// A GUID (the IID the swapchain is asked for).
struct Guid {
    std::uint32_t data1;
    std::uint16_t data2, data3;
    std::uint8_t data4[8];
};

using GetVersionFn = std::int32_t (*)(Version*);
using D3d12CreateContextFn = std::int32_t (*)(void* device, Handle*);
using DestroyFn = std::int32_t (*)(Handle);
// (Handle, HWND, const DXGI_SWAP_CHAIN_DESC1*, const DXGI_SWAP_CHAIN_FULLSCREEN_DESC*, ID3D12CommandQueue*, IDXGIFactory2*, params)
using D3d12InitFromSwapChainDescFn = std::int32_t (*)(Handle, void* hwnd, const void* desc, const void* fullscreen,
                                                      void* queue, void* factory, const D3d12InitParams*);
using D3d12GetSwapChainPtrFn = std::int32_t (*)(Handle, const Guid* riid, void** swapChain);
using SetLatencyReductionFn = std::int32_t (*)(Handle, void* xellContext);
using SetEnabledFn = std::int32_t (*)(Handle, std::uint32_t enable);
using SetPresentIdFn = std::int32_t (*)(Handle, std::uint32_t presentId);
using TagFrameConstantsFn = std::int32_t (*)(Handle, std::uint32_t presentId, const FrameConstants*);
using D3d12TagFrameResourceFn = std::int32_t (*)(Handle, void* commandList, std::uint32_t presentId,
                                                 const D3d12ResourceData*);
using GetLastPresentStatusFn = std::int32_t (*)(Handle, PresentStatus*);

}  // namespace xefg_abi

struct XefgApi {
    xefg_abi::GetVersionFn getVersion = nullptr;
    xefg_abi::D3d12CreateContextFn d3d12Create = nullptr;
    xefg_abi::DestroyFn destroy = nullptr;
    xefg_abi::D3d12InitFromSwapChainDescFn d3d12InitFromDesc = nullptr;
    xefg_abi::D3d12GetSwapChainPtrFn d3d12GetSwapChainPtr = nullptr;
    xefg_abi::SetLatencyReductionFn setLatencyReduction = nullptr;
    xefg_abi::SetEnabledFn setEnabled = nullptr;
    xefg_abi::SetPresentIdFn setPresentId = nullptr;
    xefg_abi::TagFrameConstantsFn tagFrameConstants = nullptr;
    xefg_abi::D3d12TagFrameResourceFn d3d12TagFrameResource = nullptr;
    xefg_abi::GetLastPresentStatusFn getLastPresentStatus = nullptr;  // optional: a library without it counts no generated frames
};

VendorLibrarySpec xefg_library_spec();
// Takes the functions from `lib`. "" when the required ones are all there, else the name of the first missing one.
std::string xefg_load_api(VendorLibrary& lib, XefgApi& api);
// "success", "unsupported device", ... for an xefg_swapchain_result_t; "result -12" for a code this build does not know.
std::string xefg_result_text(std::int32_t result);

// The projection matrix XeSS-FG is told, from the unjittered projection of the frame (FrameGenFrame::proj: P00, P11, P02, P12, P03, P13, P32,
// P33) and the planes: the depth row is the Direct3D one (z from 0 at the near plane to 1 at the far one; an orthographic camera when P32 is
// 0). Row-major with the row-vector convention, which is the memory of the column-major Mat4 the engine's own matrices use.
void xefg_projection(const float proj[8], float nearPlane, float farPlane, float out[16]);

// The provider and the device hook that makes its swapchain: one object (FrameGenProvider::device_hook() returns it). Registered in the slot
// of Xess by the provider table.
std::shared_ptr<FrameGenProvider> make_xess_framegen_provider();

}  // namespace fa::render
