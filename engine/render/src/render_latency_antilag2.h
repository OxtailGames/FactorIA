// The AMD Anti-Lag 2 provider of M78 (render_latency.h; docs/LATENCY.md, "AMD Anti-Lag 2"). Private to fa_render.
//
// No AMD header or binary is in the engine (decision D2 of M78): this file declares the C ABI the engine calls, written from AMD's
// AntiLag2-SDK (GPUOpen-LibrariesAndSDKs/AntiLag2-SDK, ffx_antilag2_dx12.h, v2.0.0a, MIT) and from the Vulkan registry's VK_AMD_anti_lag
// (spec version 1; vulkan_core.h of the Vulkan headers 1.4.x).
//   - Direct3D 12: the extension interface of the driver's own module amdxc64.dll (a COM-like object: IUnknown plus one method, slot 3,
//     UpdateAntiLagState). The SDK's header-only helper does nothing else.
//   - Vulkan: vkAntiLagUpdateAMD of the device extension VK_AMD_anti_lag, enabled by AntiLag2Hook when the device is made.
//   - Direct3D 11 (amdxx64.dll's AmdDxExtCreate11 interface) is not implemented: the mode says so and the engine's own pacing runs.
// Anti-Lag 2 is part of the Radeon driver: nothing is installed with `factoria setup`.
#pragma once

#include <cstdint>
#include <memory>
#include <mutex>
#include <string>

#include "render_latency.h"

namespace fa::render {

namespace antilag2_abi {

#pragma pack(push, 8)
// A GUID as Windows lays it out.
struct Guid {
    std::uint32_t data1;
    std::uint16_t data2, data3;
    std::uint8_t data4[8];
};
// IAmdExtAntiLagApi's id, {44085fbe-e839-40c5-bf38-0ebc5ab4d0a6}.
inline constexpr Guid kAntiLagApiIid = {0x44085fbe, 0xe839, 0x40c5, {0xbf, 0x38, 0x0e, 0xbc, 0x5a, 0xb4, 0xd0, 0xa6}};

// AMD::AntiLag2DX12 APIData_v1: what UpdateAntiLagState takes (the SDK calls it with eMode 2 first).
struct ApiDataV1 {
    std::uint32_t size;     // sizeof(ApiDataV1)
    std::uint32_t version;  // 1
    std::uint32_t mode;     // kModeOn, kModeOff
    char* controlStr;       // null
    std::uint32_t controlStrLength;
    std::uint32_t maxFps;  // 0 = not limited
};
#pragma pack(pop)
inline constexpr std::uint32_t kApiVersion1 = 1, kModeOn = 1, kModeOff = 2;

// The object AmdExtD3DCreateInterface makes: a pointer to a table of functions (IUnknown's three, then UpdateAntiLagState).
struct Interface;
struct InterfaceVtbl {
    std::int32_t (*queryInterface)(Interface* self, const Guid* iid, void** out);
    std::uint32_t (*addRef)(Interface* self);
    std::uint32_t (*release)(Interface* self);
    std::int32_t (*updateAntiLagState)(Interface* self, void* data);  // an ApiDataV1*, or null: insert the delay
};
struct Interface {
    const InterfaceVtbl* vtbl;
};
// HRESULT AmdExtD3DCreateInterface(IUnknown* device, REFIID iid, void** out): a success code is >= 0.
using CreateInterfaceFn = std::int32_t (*)(void* device, const Guid* iid, void** out);

// ---- VK_AMD_anti_lag (vulkan_core.h) ----
inline constexpr std::int32_t kStructPhysicalDeviceFeatures = 1000476000, kStructData = 1000476001,
                              kStructPresentationInfo = 1000476002;
inline constexpr std::int32_t kVkModeDriverControl = 0, kVkModeOn = 1, kVkModeOff = 2;  // VkAntiLagModeAMD
inline constexpr std::int32_t kStageInput = 0, kStagePresent = 1;                       // VkAntiLagStageAMD
inline constexpr const char* kVulkanExtension = "VK_AMD_anti_lag";
inline constexpr std::uint32_t kAmdVendorId = 0x1002;

struct VkPresentationInfo {  // VkAntiLagPresentationInfoAMD
    std::int32_t sType;
    const void* next;
    std::int32_t stage;
    std::uint64_t frameIndex;
};
struct VkData {  // VkAntiLagDataAMD
    std::int32_t sType;
    const void* next;
    std::int32_t mode;
    std::uint32_t maxFps;
    const VkPresentationInfo* presentationInfo;
};
struct VkFeatures {  // VkPhysicalDeviceAntiLagFeaturesAMD
    std::int32_t sType;
    void* next;
    std::uint32_t antiLag;  // VkBool32
};
using VkUpdateFn = void (*)(const void* device, const VkData* data);  // PFN_vkAntiLagUpdateAMD
}  // namespace antilag2_abi

// The Vulkan half of Anti-Lag 2: on an AMD GPU it asks the device for VK_AMD_anti_lag and its feature when the device is made, and keeps the
// device and the resolved vkAntiLagUpdateAMD for the provider. A Direct3D 12 or non-AMD device is not touched.
// The renderer registers one on Windows before it makes its device (register_latency_device_hooks).
class AntiLag2Hook final : public gpu::DeviceHook {
public:
    std::string_view name() const override { return "AMD Anti-Lag 2"; }
    void vulkan_device_request(const gpu::VulkanPhysicalDevice& gpu, gpu::VulkanDeviceRequest& request) override;
    void vulkan_device_created(const gpu::VulkanDeviceCreated& created) override;
    void device_destroying() override;

    // What the device was made with: false until vulkan_device_created.
    bool granted() const;
    const void* vk_device() const;
    antilag2_abi::VkUpdateFn update_function() const;
    // Whether this GPU was asked at all (an AMD GPU on Vulkan), for the reason a probe gives.
    bool requested() const;

private:
    mutable std::mutex mutex_;
    bool requested_ = false;
    bool granted_ = false;
    const void* device_ = nullptr;
    antilag2_abi::VkUpdateFn update_ = nullptr;
};

// The hook the Anti-Lag 2 provider reads (the one register_latency_device_hooks registers).
std::shared_ptr<AntiLag2Hook> antilag2_hook();
// Registers the hooks of the low-latency providers with the device (once per process); Windows only: elsewhere there is no SDK to ask the
// device for anything.
void register_latency_device_hooks();

}  // namespace fa::render
