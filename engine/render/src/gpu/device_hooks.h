// Private to fa_render: device hooks, the way a vendor SDK takes part in making the engine's D3D12 and Vulkan devices
// and their swapchains (M78-P2b, docs/design/ARCHITECTURE_RENDERING_HOOKS.md).
//
// NVIDIA Streamline (DLSS, DLSS frame generation, Reflex), AMD FidelityFX (FSR 3.1 and its frame generation, Anti-Lag 2)
// and Intel XeSS (XeSS, XeSS frame generation, XeLL) need more than the native handles of a finished device
// (NativeDevice, begin_native): Vulkan instance and device extensions, feature bits and queues of their own asked for
// before the device is made; a D3D12 factory, device or queue they wrap ("upgrade"); the swapchain they make themselves
// (a proxy swapchain that inserts generated frames) or wrap; a call around every present. A provider implements
// DeviceHook (each callback has a default that does nothing) and hands it to DeviceInit::hooks, or registers it for
// every device the process makes (register_device_hook). The engine never includes a vendor header: the objects cross
// this interface as void* (COM pointers, dispatchable Vulkan handles) or 64-bit numbers (non-dispatchable Vulkan
// handles), with the Vulkan and DXGI structs they point at named in each comment.
//
// What a backend does with them:
//  * D3D12 (d3d12_device_win32.cpp, d3d12_swapchain_win32.cpp) and Vulkan (vulkan_device.cpp, vulkan_swapchain.cpp)
//    call every callback below at the moment it names, on the thread that makes the device, or that presents.
//  * D3D11, GL, Metal and the RecordingDevice call none: make_device() marks each hook unavailable there, with the
//    reason, unless a live D3D12 or Vulkan device holds it (HookAttachment): availability is one state per hook,
//    shared by the devices that use it.
//
// Degrading, never failing: whatever a hook asks that the machine lacks (a missing required extension, a feature bit
// the GPU does not have, a queue family with no queue left, a Vulkan 1.3 struct on a 1.2 device) marks that hook
// unavailable with a sentence that says what is missing and what to do; the device is made without anything that hook
// asked, and the hook gets no later callback. When vkCreateDevice fails with the hooks' additions, the device is made
// again without them and every hook that added something is marked unavailable. A hook that reports an error of its own
// (an `error` field) is marked unavailable the same way, and the engine goes on as if it were not there. The reason is
// in DeviceHook::unavailable_reason() and in the log (a warning).
//
// No hook installed: no callback, no extra work per frame (the backends test an empty list).
#pragma once

#include <atomic>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <mutex>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include "gpu/types.h"

namespace fa::gpu {

using HookProcAddr = NativeDevice::ProcAddr;  // any function pointer, as void (*)(); cast back to its PFN_ type

// ---- Vulkan ----------------------------------------------------------------------------------------------------------

// What a hook asks of the VkInstance (DeviceHook::vulkan_instance_request).
struct VulkanInstanceRequest {
    std::vector<std::string> extensions;          // required: one the loader lacks marks the hook unavailable
    std::vector<std::string> optionalExtensions;  // turned on where the loader has them; skipped silently otherwise
};

// The physical device the engine chose, as a hook sees it before the VkDevice is made.
struct VulkanPhysicalDevice {
    const void* instance = nullptr;              // VkInstance
    const void* physicalDevice = nullptr;        // VkPhysicalDevice
    HookProcAddr getInstanceProcAddr = nullptr;  // the loader's vkGetInstanceProcAddr
    std::uint32_t apiVersion = 0;                // the version the device will be made with (VK_MAKE_API_VERSION)
    std::uint32_t vendorId = 0, deviceId = 0;
    std::string name;  // VkPhysicalDeviceProperties::deviceName
};

// Extra queues a hook asks for: `count` queues of a family whose VkQueueFlags hold every bit of `flags` (Streamline's
// numGraphicsQueuesRequired: VK_QUEUE_GRAPHICS_BIT; numComputeQueuesRequired: VK_QUEUE_COMPUTE_BIT; the optical flow
// queue: VK_QUEUE_OPTICAL_FLOW_BIT_NV). A graphics request takes the engine's graphics family first; any other request
// takes, first, a family that does not draw. The hook's queues come after the engine's in their family (indices after
// the engine's own).
struct VulkanQueueRequest {
    std::uint32_t flags = 0;
    std::uint32_t count = 1;
};

// What a hook asks of the VkDevice (DeviceHook::vulkan_device_request).
struct VulkanDeviceRequest {
    std::vector<std::string> extensions;          // required: one the device lacks marks the hook unavailable
    std::vector<std::string> optionalExtensions;  // turned on where the device has them
    // Feature structs, each the bytes of a whole Vk*Features struct (sType, then pNext, ignored, then its VkBool32
    // members) with VK_TRUE in the members the hook needs: VkPhysicalDeviceFeatures2 for the core 1.0 features,
    // VkPhysicalDeviceVulkan11Features / 12 / 13 for the core ones (never the older per-feature structs a Vulkan 1.2
    // struct covers: Vulkan forbids both in one chain), an extension's struct for that extension (only of a required
    // extension). A struct of a type the engine chains already (Features2, Vulkan12, Vulkan13, the portability subset)
    // is merged into the engine's; any other is chained into VkDeviceCreateInfo::pNext. A bit the GPU lacks marks the
    // hook unavailable, naming the struct and the member's index, and so does a struct that cannot go in the device's
    // chain: one a core struct covers (the older per-feature structs of Vulkan 1.2; synchronization2's own on Vulkan
    // 1.3, where Vulkan13Features has it), an extension's struct without that extension in `extensions`.
    std::vector<std::vector<std::uint8_t>> features;
    // Per entry of `features`: how many VkBool32 members a struct the engine does not know has (0 or no entry = every
    // 4 bytes after the header, padding included: zero the struct first). A struct the engine knows (Features2,
    // Vulkan11/12/13, synchronization2, the portability subset) is read member by member, never its trailing padding.
    std::vector<std::uint32_t> featureMembers;
    std::vector<VulkanQueueRequest> queues;

    // Copies a Vk*Features struct into `features`; `members` = its VkBool32 members, for a struct of an extension.
    template <class T>
    void add_features(const T& s, std::uint32_t members = 0) {
        const auto* p = reinterpret_cast<const std::uint8_t*>(&s);
        featureMembers.resize(features.size(), 0);
        features.emplace_back(p, p + sizeof(T));
        featureMembers.push_back(members);
    }
};

// One queue a hook got, in the order of its VulkanDeviceRequest::queues (a request of count 2 gives two entries).
struct VulkanQueueGrant {
    std::uint32_t family = 0;
    std::uint32_t index = 0;
    const void* queue = nullptr;  // VkQueue
};

// The device made, handed to each available hook before the device is returned to the caller.
struct VulkanDeviceCreated {
    NativeDevice native;  // instance, physicalDevice, device, the queues and their families, the proc addresses
    std::vector<VulkanQueueGrant> queues;                // this hook's queues
    std::vector<std::string> enabledOptionalExtensions;  // this hook's optional device extensions that the device has
};

// The functions the engine calls on a swapchain (PFN_vkCreateSwapchainKHR, PFN_vkDestroySwapchainKHR,
// PFN_vkGetSwapchainImagesKHR, PFN_vkAcquireNextImageKHR, PFN_vkQueuePresentKHR, PFN_vkSetHdrMetadataEXT, as
// HookProcAddr). Null = the engine's own.
struct VulkanSwapchainFunctions {
    HookProcAddr createSwapchain = nullptr;
    HookProcAddr destroySwapchain = nullptr;
    HookProcAddr getSwapchainImages = nullptr;
    HookProcAddr acquireNextImage = nullptr;
    HookProcAddr queuePresent = nullptr;
    HookProcAddr setHdrMetadata = nullptr;
};

// A swapchain about to be made (create_swapchain, a resize, a swapchain out of date made again): DeviceHook::
// vulkan_create_swapchain.
struct VulkanSwapchainCreate {
    const void* device = nullptr;  // VkDevice
    const void* queue = nullptr;   // the VkQueue the engine presents on (the graphics queue)
    // VkSwapchainCreateInfoKHR*: the hook may change it (more images, more usage bits, a pNext of its own; not the
    // format, the colour space or the extent, which the engine's images are made for) and keeps what it points at alive
    // until the swapchain is made (a member of the hook, not its stack). oldSwapchain is the swapchain being replaced
    // (0 = none). A hook that fails has its changes undone.
    void* createInfo = nullptr;
    // In: the functions the engine would call; out: the ones it calls on this swapchain from now on (a hook that wraps
    // one keeps the pointer it replaces and calls it). Each hook sees what the hooks before it left.
    VulkanSwapchainFunctions functions;
    // A hook that makes the swapchain itself returns true from vulkan_create_swapchain and sets `swapchain`
    // (VkSwapchainKHR) and `result` (VK_SUCCESS); the hooks after it are not asked. One that fails sets `error`: it is
    // marked unavailable and the engine makes the swapchain without it.
    std::uint64_t swapchain = 0;
    std::int32_t result = 0;
    std::string error;
};

// ---- D3D12 -----------------------------------------------------------------------------------------------------------

// Before D3D12CreateDevice, once per adapter the engine tries (the last call names the device's adapter).
struct D3d12BeforeDevice {
    const void* factory = nullptr;  // IDXGIFactory4*
    const void* adapter = nullptr;  // IDXGIAdapter1*
    bool warp = false;
};

// The device made, with its direct queue, before anything else is made on it. A hook may replace `factory`, `device`
// or `queue` with an object that wraps it (Streamline's slUpgradeInterface): the new pointer carries one reference the
// engine takes over, and the engine drops its own reference to the old one (a wrapper that needs the old one AddRefs
// it). The engine uses the replacements for everything after: the device for every resource, the queue for every
// submit and the swapchain, the factory for the swapchain. A pointer left as the engine gave it is no replacement and
// carries no reference. One that fails sets `error` and changes nothing (a replacement it handed anyway is released).
struct D3d12DeviceCreated {
    void* factory = nullptr;        // IDXGIFactory4*
    void* device = nullptr;         // ID3D12Device*
    void* queue = nullptr;          // ID3D12CommandQueue* (the direct queue)
    const void* adapter = nullptr;  // IDXGIAdapter1*
    std::string error;
};

// A swapchain about to be made (create_swapchain): DeviceHook::d3d12_create_swapchain. Resizes go through
// IDXGISwapChain::ResizeBuffers on whatever swapchain the hooks gave (a proxy swapchain implements it).
struct D3d12SwapchainCreate {
    const void* factory = nullptr;  // IDXGIFactory4* (a hook's replacement, D3d12DeviceCreated)
    const void* queue = nullptr;    // ID3D12CommandQueue*
    const void* hwnd = nullptr;     // HWND
    // DXGI_SWAP_CHAIN_DESC1*: the hook may change it before the engine or the hook makes the swapchain; the engine
    // sets its BufferCount and Flags back after each hook. A hook that makes the swapchain keeps
    // DXGI_SWAP_CHAIN_FLAG_FRAME_LATENCY_WAITABLE_OBJECT (the engine waits on it); the engine reads the buffer count
    // of the swapchain it gets (GetDesc1).
    void* desc = nullptr;
    // A hook that makes the swapchain itself (FSR 3's ffxCreateSwapchainDX12, XeSS frame generation's) returns true and
    // sets `swapchain` (an IDXGISwapChain1* with one reference the engine takes over); the hooks after it are not
    // asked. One that fails sets `error`: it is marked unavailable and the engine makes the swapchain without it.
    void* swapchain = nullptr;
    std::string error;
};

// ---- both ------------------------------------------------------------------------------------------------------------

// One present, around the backend's present call (IDXGISwapChain::Present, vkQueuePresentKHR).
struct PresentEvent {
    Backend backend = Backend::Recording;
    std::uint64_t frame = 0;          // the presents of this device so far, this one included (1 for the first)
    const void* swapchain = nullptr;  // IDXGISwapChain3* (D3D12); null on Vulkan
    std::uint64_t vkSwapchain = 0;    // VkSwapchainKHR (Vulkan)
    const void* queue = nullptr;      // ID3D12CommandQueue* / VkQueue the present goes on
    std::uint32_t imageIndex = 0;     // the back buffer or swapchain image presented
    std::int32_t result = 0;          // present_end: the HRESULT / VkResult of the present call
};

// The swapchain the device is about to destroy (destroy_swapchain, the device's destructor; on Vulkan also the old
// swapchain a new one replaces), before the engine releases it.
struct SwapchainEvent {
    Backend backend = Backend::Recording;
    const void* swapchain = nullptr;  // IDXGISwapChain3* (D3D12)
    std::uint64_t vkSwapchain = 0;    // VkSwapchainKHR (Vulkan)
};

// One vendor SDK's part in making a device. Every callback has a default that does nothing; the backends call them in
// the order of DeviceInit::hooks, only on a hook that is still available.
class DeviceHook {
public:
    virtual ~DeviceHook() = default;
    // Who it is, in the reasons the engine writes ("DLSS", "FSR 3 frame generation").
    virtual std::string_view name() const = 0;

    // Vulkan, before vkCreateInstance: the instance extensions it needs.
    virtual void vulkan_instance_request(VulkanInstanceRequest&) {}
    // Vulkan, right after vkCreateInstance (VkInstance, the loader's vkGetInstanceProcAddr).
    virtual void vulkan_instance_created(const void* /*instance*/, HookProcAddr /*getInstanceProcAddr*/) {}
    // Vulkan, after the physical device is chosen and before vkCreateDevice: what it needs of the device.
    virtual void vulkan_device_request(const VulkanPhysicalDevice&, VulkanDeviceRequest&) {}
    // Vulkan: each instance function (with `device` null) and device function (VkDevice) the engine loads and the
    // loader gave (a function the loader does not give stays absent). A non-null answer replaces it (Streamline's
    // manual hooking hands its interposer's vkCreateSwapchainKHR, vkQueuePresentKHR, ... this way); the next hook sees
    // the replacement.
    virtual HookProcAddr vulkan_resolve(const char* /*name*/, const void* /*device*/, HookProcAddr /*resolved*/) {
        return nullptr;
    }
    // Vulkan: the device made, every engine object ready, before the device is returned (slSetVulkanInfo).
    virtual void vulkan_device_created(const VulkanDeviceCreated&) {}
    // Vulkan: a swapchain about to be made. True = the hook made it (VulkanSwapchainCreate::swapchain).
    virtual bool vulkan_create_swapchain(VulkanSwapchainCreate&) { return false; }

    // D3D12: before D3D12CreateDevice on an adapter.
    virtual void d3d12_before_device(const D3d12BeforeDevice&) {}
    // D3D12: the device and its direct queue made (Reflex, Anti-Lag 2 and XeLL start here; Streamline upgrades).
    virtual void d3d12_device_created(D3d12DeviceCreated&) {}
    // D3D12: a swapchain about to be made. True = the hook made it (D3d12SwapchainCreate::swapchain).
    virtual bool d3d12_create_swapchain(D3d12SwapchainCreate&) { return false; }
    // D3D12: the swapchain made (by the engine or a hook). `swapchain` (IDXGISwapChain1*) may be replaced as in
    // D3d12DeviceCreated (a new reference; the engine drops its own to the old one).
    virtual void d3d12_swapchain_created(void*& /*swapchain*/) {}

    // Both: around each present, and before a swapchain goes. On Vulkan the present callbacks run under the lock of the
    // device's queues (other threads' submits wait): they call the SDK (Reflex markers, frame pacing), never the
    // engine's device.
    virtual void present_begin(const PresentEvent&) {}
    virtual void present_end(const PresentEvent&) {}
    virtual void swapchain_destroying(const SwapchainEvent&) {}
    // Both: the device is about to go: the GPU is idle, the window's swapchain gone already (swapchain_destroying came
    // first) and every other device object still there (slShutdown and the SDK's own contexts go here).
    virtual void device_destroying() {}

    // Whether the device took the hook, and why not. Thread safe: a hook registered for the process is read by every
    // device's threads and written by the one that starts or fails.
    bool available() const { return available_.load(std::memory_order_acquire); }
    std::string unavailable_reason() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return reason_;
    }
    // Called by the device (and by make_device on a backend without hooks).
    void mark_unavailable(std::string reason) {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!available_.load(std::memory_order_relaxed)) return;  // the first reason stays
        reason_ = std::move(reason);
        available_.store(false, std::memory_order_release);
    }
    void mark_available() {
        std::lock_guard<std::mutex> lock(mutex_);
        reason_.clear();
        available_.store(true, std::memory_order_release);
    }
    // The devices that hold the hook now (HookAttachment). A hook a live D3D12 or Vulkan device uses is never marked
    // unsupported by another device that calls no hooks (make_device of a D3D11, GL, Metal or Recording device).
    bool in_use() const { return users_.load(std::memory_order_acquire) > 0; }

private:
    friend class HookAttachment;
    // A device starts to use the hook: the first user starts it available; a second device made while the first lives
    // shares the first's state (it never turns the hook on again under the first device's feet).
    void begin_use() {
        std::lock_guard<std::mutex> lock(mutex_);
        if (users_.fetch_add(1, std::memory_order_acq_rel) == 0) {
            reason_.clear();
            available_.store(true, std::memory_order_release);
        }
    }
    void end_use() { users_.fetch_sub(1, std::memory_order_acq_rel); }

    mutable std::mutex mutex_;
    std::atomic<bool> available_{true};
    std::atomic<int> users_{0};
    std::string reason_;
};

using DeviceHooks = std::vector<std::shared_ptr<DeviceHook>>;

// What a D3D12 or Vulkan device holds for as long as it lives: each hook counts the device as a user (DeviceHook::
// in_use), so a device made for another backend meanwhile does not mark it unsupported, and a second device does not
// make it available again under the first. Detaches in its destructor (a member declared after the hooks, destroyed
// after the device's own destructor body, where device_destroying runs).
class HookAttachment {
public:
    HookAttachment() = default;
    HookAttachment(const HookAttachment&) = delete;
    HookAttachment& operator=(const HookAttachment&) = delete;
    ~HookAttachment() { release(); }
    void attach(const DeviceHooks& hooks) {
        release();
        hooks_ = hooks;
        for (const auto& h : hooks_)
            if (h) h->begin_use();
    }
    void release() {
        for (const auto& h : hooks_)
            if (h) h->end_use();
        hooks_.clear();
    }

private:
    DeviceHooks hooks_;
};

// The process's hooks: make_device() appends them to DeviceInit::hooks (after the caller's, once each) for every D3D12
// and Vulkan device it makes. A provider registers before the renderer makes its device; a hook registered later
// takes part from the next device on. Thread safe.
void register_device_hook(std::shared_ptr<DeviceHook> hook);
void unregister_device_hook(const DeviceHook* hook);
DeviceHooks registered_device_hooks();

// `hooks` with every registered hook added once (make_device).
DeviceHooks with_registered_hooks(const DeviceHooks& hooks);
// Marks every hook of `hooks` unavailable on a backend that calls none (D3D11, GL, Metal, Recording).
void mark_hooks_unsupported(const DeviceHooks& hooks, Backend backend);
// The warning a backend logs when it marks `hook` unavailable: "gpu <backend>: device hook '<name>' is unavailable:
// <reason>" (the reason as given, which carries its own hint).
std::string device_hook_warning(Backend backend, const DeviceHook& hook);

}  // namespace fa::gpu
