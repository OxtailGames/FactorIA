// Private to fa_render: the engine's own Vulkan backend of the GPU interface (M77.3,
// docs/design/ARCHITECTURE_RENDERING_GPU.md, "Vulkan backend").
//
// The first part of this header compiles everywhere: the options and make_vulkan_device(), which returns a teaching
// error where the backend is not built (the web and iOS builds, FA_VULKAN_BACKEND off). The second part declares
// VulkanDevice and its helpers; the code is in vulkan_*.cpp. The backend is built on Linux, Windows and Android, and
// on macOS for its tests only (through MoltenVK): it is never a macOS product backend.
//
// No Vulkan library is linked: the sources are compiled with VK_NO_PROTOTYPES against the vendored Khronos headers
// (external/vulkan_headers) and vulkan_loader.cpp opens the system's loader at run time (libvulkan.so.1, vulkan-1.dll,
// libvulkan.1.dylib) and takes every function from it.
//
// What M77-P8a built: the loader, the instance (the validation layer and debug utils when asked for and present), the
// physical device (a hardware GPU, or a CPU device such as lavapipe on request), the logical device with a graphics +
// compute queue (and a transfer queue when the GPU has a separate family), a timeline semaphore for the frames in
// flight, the deferred release of destroyed resources, the engine's own memory suballocator, the upload ring, buffers,
// images, views, samplers, image layouts and access tracked per subresource with automatic barriers (synchronization2
// where the device has it, the Vulkan 1.0 barriers otherwise), the transfers of a command list, debug labels, the
// per-frame descriptor pools and the bindless reservation, the blocking readbacks, statistics and commit listeners.
// Shaders, pipelines, passes, draws, dispatches, bindings, uniforms, GPU timers and asynchronous reads come in
// M77-P8c: until then they report a "not built yet (M77-P8c)" error (errors()) and do nothing.
#pragma once

#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>

#include "fa/core/types.h"
#include "gpu/device.h"

namespace fa::gpu {

// How make_vulkan_device() makes its device.
struct VulkanOptions {
    // A CPU device (VK_PHYSICAL_DEVICE_TYPE_CPU: Mesa's lavapipe) instead of the best GPU (tests, CI machines without a
    // GPU). Fails when the system has no CPU device.
    bool cpuDevice = false;
    // The Khronos validation layer (VK_LAYER_KHRONOS_validation) with a debug messenger: every API misuse becomes a
    // message, the ERROR ones go to VulkanDevice::errors() (and the log), the WARNING ones to warnings(). Without the
    // layer installed the device is made without it (a warning says so) and validation_active() is false.
    bool validation = false;
    // Frames the CPU may record ahead of the GPU: 1 to 3.
    int framesInFlight = kInflightFrames;
    // Pool sizes (buffers, images, views, samplers, shaders, pipelines) and the environment defaults (the default
    // colour and depth formats and the sample count of a swapchain pass).
    DeviceInit init{};
    // Bytes of the upload ring that write_buffer, write_image and the initial data of make_buffer / make_image copy
    // through (shared by the frames in flight): 64 KiB to 1 GiB. An upload that does not fit takes a buffer of its own.
    std::size_t uploadRingBytes = 32u * 1024u * 1024u;
    // Bytes of each memory block the suballocator places buffers and images in (one pool of blocks per memory type):
    // 1 MiB to 1 GiB. A resource of dedicatedThreshold bytes or more takes an allocation of its own (1 KiB up to
    // memoryBlockBytes).
    std::size_t memoryBlockBytes = 64u * 1024u * 1024u;
    std::size_t dedicatedThreshold = 16u * 1024u * 1024u;
    // The per-frame descriptor pools (one per frame in flight, reset when that frame comes round again): sets, and
    // descriptors of each kind (sampled image, sampler, storage image, storage buffer, dynamic uniform buffer,
    // combined image-sampler). 1 to 1048576 each.
    int frameDescriptorSets = 4096;
    int frameDescriptors = 32768;
    // The bindless table: sampled images in one update-after-bind set (descriptor indexing). 0 = none; 0 to 1048576,
    // and at most what the device binds in one stage (maxPerStageDescriptorUpdateAfterBindSampledImages) and puts in
    // one set (a count over maxPerSetDescriptors that vkGetDescriptorSetLayoutSupport refuses is lowered to
    // maxPerSetDescriptors: 1212 on MoltenVK). A lowered count and a device without descriptor indexing (no table)
    // are warnings.
    int bindlessDescriptors = 32768;
    // Barriers through VK_KHR_synchronization2 (core in Vulkan 1.3) where the device has it. False = the Vulkan 1.0
    // barriers everywhere (tests of that path).
    bool synchronization2 = true;
    // The Vulkan loader to open (a UTF-8 path); empty = the platform's search (libvulkan.so.1, vulkan-1.dll,
    // libvulkan.1.dylib with the Homebrew prefixes on macOS).
    std::string loaderPath;
};

// Makes a Vulkan device. Fails with a teaching error where the backend is not built (web, iOS), when an option is out of
// range (before any Vulkan call), when no Vulkan loader is found, or when no device has Vulkan 1.2 with timeline
// semaphores and a graphics + compute queue.
Result<std::unique_ptr<Device>> make_vulkan_device(const VulkanOptions& options = {});

}  // namespace fa::gpu

#if defined(FA_VULKAN_BACKEND)

#ifndef VK_NO_PROTOTYPES
#define VK_NO_PROTOTYPES
#endif
#ifndef VK_ENABLE_BETA_EXTENSIONS
#define VK_ENABLE_BETA_EXTENSIONS  // VK_KHR_portability_subset (MoltenVK) is a provisional extension
#endif
#include <vulkan/vulkan.h>

#include <array>
#include <atomic>
#include <deque>
#include <mutex>
#include <type_traits>
#include <unordered_map>
#include <utility>
#include <vector>

namespace fa::gpu::vk {

// ---------------------------------------------------------------------------------------------------------------------
// The loader and the function tables
// ---------------------------------------------------------------------------------------------------------------------

// The Vulkan loader, opened at run time.
struct VulkanLibrary {
    void* handle = nullptr;
    std::string path;  // UTF-8: what was opened
    PFN_vkGetInstanceProcAddr getInstanceProcAddr = nullptr;
};
// Opens `path` (UTF-8) when it is not empty, else the platform's loader. The error names every place it looked and how
// to install a loader.
Result<VulkanLibrary> open_vulkan_library(const std::string& path);
void close_vulkan_library(VulkanLibrary& library);
// macOS: makes Homebrew's validation layer loadable when dyld cannot find its library by the bare name its manifest
// gives (a copy of the manifest with the absolute path, added through VK_ADD_LAYER_PATH unless the user set the loader's
// layer variables). Once per process; returns what it did the first time ("" = nothing, or a later call). Nothing
// elsewhere.
std::string prepare_validation_layer();

// Functions taken with vkGetInstanceProcAddr(nullptr, ...).
#define FA_VK_GLOBAL_FUNCTIONS(X)                                                                                      \
    X(vkCreateInstance)                                                                                                \
    X(vkEnumerateInstanceExtensionProperties)                                                                          \
    X(vkEnumerateInstanceLayerProperties)                                                                              \
    X(vkEnumerateInstanceVersion)
// Functions of the instance.
#define FA_VK_INSTANCE_FUNCTIONS(X)                                                                                    \
    X(vkDestroyInstance)                                                                                               \
    X(vkEnumeratePhysicalDevices)                                                                                      \
    X(vkGetPhysicalDeviceProperties)                                                                                   \
    X(vkGetPhysicalDeviceProperties2)                                                                                  \
    X(vkGetPhysicalDeviceFeatures2)                                                                                    \
    X(vkGetPhysicalDeviceQueueFamilyProperties)                                                                        \
    X(vkGetPhysicalDeviceMemoryProperties)                                                                             \
    X(vkGetPhysicalDeviceFormatProperties)                                                                             \
    X(vkGetPhysicalDeviceImageFormatProperties)                                                                        \
    X(vkEnumerateDeviceExtensionProperties)                                                                            \
    X(vkCreateDevice)                                                                                                  \
    X(vkGetDeviceProcAddr)
// VK_EXT_debug_utils (null when the instance does not have it).
#define FA_VK_DEBUG_FUNCTIONS(X)                                                                                       \
    X(vkCreateDebugUtilsMessengerEXT)                                                                                  \
    X(vkDestroyDebugUtilsMessengerEXT)                                                                                 \
    X(vkSetDebugUtilsObjectNameEXT)                                                                                    \
    X(vkCmdBeginDebugUtilsLabelEXT)                                                                                    \
    X(vkCmdEndDebugUtilsLabelEXT)
// Functions of the device.
#define FA_VK_DEVICE_FUNCTIONS(X)                                                                                      \
    X(vkDestroyDevice)                                                                                                 \
    X(vkGetDeviceQueue)                                                                                                \
    X(vkDeviceWaitIdle)                                                                                                \
    X(vkQueueSubmit)                                                                                                   \
    X(vkCreateCommandPool)                                                                                             \
    X(vkDestroyCommandPool)                                                                                            \
    X(vkResetCommandPool)                                                                                              \
    X(vkAllocateCommandBuffers)                                                                                        \
    X(vkBeginCommandBuffer)                                                                                            \
    X(vkEndCommandBuffer)                                                                                              \
    X(vkCreateSemaphore)                                                                                               \
    X(vkDestroySemaphore)                                                                                              \
    X(vkWaitSemaphores)                                                                                                \
    X(vkGetSemaphoreCounterValue)                                                                                      \
    X(vkAllocateMemory)                                                                                                \
    X(vkFreeMemory)                                                                                                    \
    X(vkMapMemory)                                                                                                     \
    X(vkUnmapMemory)                                                                                                   \
    X(vkInvalidateMappedMemoryRanges)                                                                                  \
    X(vkCreateBuffer)                                                                                                  \
    X(vkDestroyBuffer)                                                                                                 \
    X(vkGetBufferMemoryRequirements)                                                                                   \
    X(vkBindBufferMemory)                                                                                              \
    X(vkCreateImage)                                                                                                   \
    X(vkDestroyImage)                                                                                                  \
    X(vkGetImageMemoryRequirements)                                                                                    \
    X(vkBindImageMemory)                                                                                               \
    X(vkCreateImageView)                                                                                               \
    X(vkDestroyImageView)                                                                                              \
    X(vkCreateSampler)                                                                                                 \
    X(vkDestroySampler)                                                                                                \
    X(vkCreateDescriptorPool)                                                                                          \
    X(vkDestroyDescriptorPool)                                                                                         \
    X(vkResetDescriptorPool)                                                                                           \
    X(vkCreateDescriptorSetLayout)                                                                                     \
    X(vkDestroyDescriptorSetLayout)                                                                                    \
    X(vkGetDescriptorSetLayoutSupport)                                                                                 \
    X(vkAllocateDescriptorSets)                                                                                        \
    X(vkUpdateDescriptorSets)                                                                                          \
    X(vkCmdPipelineBarrier)                                                                                            \
    X(vkCmdCopyBuffer)                                                                                                 \
    X(vkCmdCopyBufferToImage)                                                                                          \
    X(vkCmdCopyImageToBuffer)

// Every function the backend calls (VK_NO_PROTOTYPES: there are no others).
struct VkFunctions {
#define FA_VK_MEMBER(name) PFN_##name name = nullptr;
    FA_VK_GLOBAL_FUNCTIONS(FA_VK_MEMBER)
    FA_VK_INSTANCE_FUNCTIONS(FA_VK_MEMBER)
    FA_VK_DEBUG_FUNCTIONS(FA_VK_MEMBER)
    FA_VK_DEVICE_FUNCTIONS(FA_VK_MEMBER)
#undef FA_VK_MEMBER
    // vkCmdPipelineBarrier2 (Vulkan 1.3) or vkCmdPipelineBarrier2KHR; null = the Vulkan 1.0 barriers.
    PFN_vkCmdPipelineBarrier2 vkCmdPipelineBarrier2 = nullptr;
};

// "VK_ERROR_DEVICE_LOST (-4)": a VkResult's name and value, for the error messages.
std::string result_text(VkResult r);

// A non-dispatchable handle as the 64-bit number debug utils names it by (a pointer on 64-bit targets).
template <class H>
std::uint64_t handle_bits(H h) {
    if constexpr (std::is_pointer_v<H>)
        return std::uint64_t(reinterpret_cast<std::uintptr_t>(h));
    else
        return std::uint64_t(h);
}

// ---------------------------------------------------------------------------------------------------------------------
// Formats
// ---------------------------------------------------------------------------------------------------------------------

// How the backend makes one PixelFormat (DepthStencil's format is the device's: VulkanDevice::vk_format).
struct FormatInfo {
    VkFormat format = VK_FORMAT_UNDEFINED;  // UNDEFINED = no Vulkan format
    std::uint32_t blockBytes = 0;           // compressed: bytes of one 4x4 block
    VkImageAspectFlags aspects = 0;         // COLOR, DEPTH or DEPTH|STENCIL
};
FormatInfo format_info(PixelFormat f);
// Bytes of one row of `width` texels (a row of 4x4 blocks for a compressed format) and the number of such rows in
// `height` texels.
std::uint32_t texel_row_bytes(PixelFormat f, std::uint32_t width);
std::uint32_t texel_rows(PixelFormat f, std::uint32_t height);
// Bytes of one texel (of one 4x4 block for a compressed format): what buffer offsets of a copy are multiples of.
std::uint32_t texel_block_bytes(PixelFormat f);
inline std::uint64_t align_up(std::uint64_t v, std::uint64_t a) { return (v + a - 1) / a * a; }
inline std::uint32_t mip_extent(int v, int mip) {
    const int e = v >> mip;
    return std::uint32_t(e < 1 ? 1 : e);
}

// ---------------------------------------------------------------------------------------------------------------------
// Memory
// ---------------------------------------------------------------------------------------------------------------------

// What a piece of memory is for: GPU-only (device-local), CPU-written and GPU-read (host-visible and coherent), or
// GPU-written and CPU-read (host-visible, cached where the device has it).
enum class MemoryUse : std::uint8_t { GpuOnly, Upload, Readback };

// A piece of device memory: `size` bytes at `offset` of `memory`.
struct Allocation {
    VkDeviceMemory memory = VK_NULL_HANDLE;
    VkDeviceSize offset = 0;
    VkDeviceSize size = 0;
    std::uint8_t* mapped = nullptr;  // host-visible memory: the CPU address of `offset`
    std::uint32_t memoryType = 0;
    int pool = -1;  // the block pool it came from; -1 = an allocation of its own
    int block = -1;
    bool coherent = true;
    bool ok() const { return memory != VK_NULL_HANDLE; }
};

struct MemoryCounters {
    std::uint32_t blocks = 0;                // memory blocks of the pools
    std::uint32_t dedicatedAllocations = 0;  // resources with an allocation of their own
    std::uint32_t liveAllocations = 0;       // pieces handed out and not freed (pooled and dedicated)
    std::uint64_t bytesAllocated = 0;        // VkDeviceMemory bytes (blocks + dedicated)
    std::uint64_t bytesInUse = 0;            // bytes of the live pieces
};

class VulkanDevice;

// The engine's suballocator: a pool of blocks per (memory type, linear or optimal resource), first fit with coalescing
// free ranges, and allocations of their own for large resources. Host-visible blocks stay mapped. Its own lock, the
// innermost one: resources are freed while the device holds its queue lock (deferred releases).
class MemoryAllocator {
public:
    void init(VulkanDevice* device, const VkPhysicalDeviceMemoryProperties& properties, VkDeviceSize blockBytes,
              VkDeviceSize dedicatedThreshold);
    // Memory for `req` (a buffer, or an image: linear = false). `dedicated` forces an allocation of its own.
    Result<Allocation> alloc(const VkMemoryRequirements& req, MemoryUse use, bool linear, bool dedicated);
    void free(Allocation& a);
    // Frees every block (device teardown, after every resource was destroyed).
    void destroy();
    MemoryCounters counters() const;
    // The memory type `use` takes among `typeBits`; -1 when none fits.
    int find_type(std::uint32_t typeBits, MemoryUse use) const;

private:
    struct Block {
        VkDeviceMemory memory = VK_NULL_HANDLE;
        VkDeviceSize size = 0;
        std::uint8_t* mapped = nullptr;
        std::vector<std::pair<VkDeviceSize, VkDeviceSize>> free;  // (offset, size), sorted by offset
        std::uint32_t live = 0;
    };
    struct BlockPool {
        std::uint32_t type = 0;
        bool linear = false;
        std::vector<std::unique_ptr<Block>> blocks;  // null = a freed block (indices stay)
    };
    Result<VkDeviceMemory> allocate_memory(VkDeviceSize size, std::uint32_t type, std::uint8_t** mapped);
    void free_memory(VkDeviceMemory memory, VkDeviceSize size, bool mapped);

    mutable std::mutex mutex_;
    VulkanDevice* device_ = nullptr;
    VkPhysicalDeviceMemoryProperties props_{};
    VkDeviceSize blockBytes_ = 0;
    VkDeviceSize dedicatedThreshold_ = 0;
    std::vector<BlockPool> pools_;
    MemoryCounters counters_{};
};

// ---------------------------------------------------------------------------------------------------------------------
// Resources and their states
// ---------------------------------------------------------------------------------------------------------------------

// The state one subresource is in: its image layout (UNDEFINED for buffers) and the stages and accesses of the last
// commands that used it (synchronization2's bits; the Vulkan 1.0 path keeps to the bits both share).
struct SubState {
    VkImageLayout layout = VK_IMAGE_LAYOUT_UNDEFINED;
    VkPipelineStageFlags2 stages = 0;
    VkAccessFlags2 access = 0;
    bool operator==(const SubState& o) const { return layout == o.layout && stages == o.stages && access == o.access; }
    bool operator!=(const SubState& o) const { return !(*this == o); }
};
// "Not used yet in this list" (a layout no command uses).
inline constexpr VkImageLayout kUnknownLayout = VK_IMAGE_LAYOUT_MAX_ENUM;
// The accesses that write memory: a state with one of them needs a barrier before the next use, even in its layout.
inline constexpr VkAccessFlags2 kWriteAccess = VK_ACCESS_2_SHADER_WRITE_BIT | VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT |
                                               VK_ACCESS_2_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT |
                                               VK_ACCESS_2_TRANSFER_WRITE_BIT | VK_ACCESS_2_HOST_WRITE_BIT |
                                               VK_ACCESS_2_MEMORY_WRITE_BIT | VK_ACCESS_2_SHADER_STORAGE_WRITE_BIT;
inline bool access_writes(VkAccessFlags2 a) { return (a & kWriteAccess) != 0; }
// A copy writes it / reads it (buffers keep the layout UNDEFINED, which nothing reads).
inline SubState transfer_write_state(bool image) {
    return {image ? VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL : VK_IMAGE_LAYOUT_UNDEFINED, VK_PIPELINE_STAGE_2_TRANSFER_BIT,
            VK_ACCESS_2_TRANSFER_WRITE_BIT};
}
inline SubState transfer_read_state(bool image) {
    return {image ? VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL : VK_IMAGE_LAYOUT_UNDEFINED, VK_PIPELINE_STAGE_2_TRANSFER_BIT,
            VK_ACCESS_2_TRANSFER_READ_BIT};
}

// A buffer or an image whose state the backend tracks: one SubState per (mip, layer), the state the queue leaves it in
// after the lists submitted so far. Shared by the buffer or image record, its views, the command lists that use it and
// the deferred-release queue, so a resource destroyed while a list still holds it stays alive. The destructor destroys
// the Vulkan object and frees its memory (it takes no device lock but the allocator's).
struct TrackedResource {
    VulkanDevice* device = nullptr;
    VkBuffer buffer = VK_NULL_HANDLE;
    VkImage image = VK_NULL_HANDLE;
    Allocation memory{};
    VkImageAspectFlags aspects = 0;  // images: what a barrier names
    std::vector<SubState> states;
    std::uint32_t mips = 1;
    std::uint32_t layers = 1;  // array layers or cube faces (1 for buffers and 3D images)
    std::uint32_t subresource(std::uint32_t mip, std::uint32_t layer) const { return mip + layer * mips; }
    std::uint32_t subresource_count() const { return mips * layers; }
    TrackedResource() = default;
    TrackedResource(const TrackedResource&) = delete;
    TrackedResource& operator=(const TrackedResource&) = delete;
    ~TrackedResource();
};

// One barrier before a command: a buffer, or a range of mips and layers of an image, from one state to another.
struct Barrier {
    VkBuffer buffer = VK_NULL_HANDLE;
    VkImage image = VK_NULL_HANDLE;
    VkImageAspectFlags aspects = 0;
    std::uint32_t mip = 0, mipCount = 1, layer = 0, layerCount = 1;
    SubState from{}, to{};
};

// A fixed-size table of records with generation-counted 32-bit ids (sokol's scheme): id = generation << 16 | (index +
// 1), so a destroyed id never names the next record of its slot.
template <class T>
class Pool {
public:
    void init(int capacity) {
        const int cap = capacity < 1 ? 1 : (capacity > 65534 ? 65534 : capacity);
        slots_.assign(std::size_t(cap), Slot{});
        free_.clear();
        for (int i = cap - 1; i >= 0; --i) free_.push_back(std::uint32_t(i));
    }
    // 0 when the pool is full.
    std::uint32_t add(T&& item) {
        if (free_.empty()) return 0;
        const std::uint32_t index = free_.back();
        free_.pop_back();
        Slot& s = slots_[index];
        s.generation = std::uint16_t(s.generation == 0xFFFF ? 1 : s.generation + 1);
        s.used = true;
        s.item = std::move(item);
        return (std::uint32_t(s.generation) << 16) | (index + 1);
    }
    T* get(std::uint32_t id) {
        Slot* s = slot(id);
        return s ? &s->item : nullptr;
    }
    const T* get(std::uint32_t id) const { return const_cast<Pool*>(this)->get(id); }
    // Moves the record out and frees its slot; false when `id` names nothing.
    bool remove(std::uint32_t id, T& out) {
        Slot* s = slot(id);
        if (!s) return false;
        out = std::move(s->item);
        s->item = T{};
        s->used = false;
        free_.push_back((id & 0xFFFFu) - 1);
        return true;
    }
    // Calls f(record) for every live record.
    template <class F>
    void for_each(F&& f) {
        for (Slot& s : slots_)
            if (s.used) f(s.item);
    }
    // Drops every record (device teardown).
    void clear() {
        for (Slot& s : slots_) {
            s.item = T{};
            s.used = false;
        }
        slots_.clear();
        free_.clear();
    }
    int capacity() const { return int(slots_.size()); }
    int alive() const { return int(slots_.size() - free_.size()); }

private:
    struct Slot {
        T item{};
        std::uint16_t generation = 0;
        bool used = false;
    };
    Slot* slot(std::uint32_t id) {
        const std::uint32_t index = id & 0xFFFFu;
        if (index == 0 || index > slots_.size()) return nullptr;
        Slot& s = slots_[index - 1];
        if (!s.used || s.generation != std::uint16_t(id >> 16)) return nullptr;
        return &s;
    }
    std::vector<Slot> slots_;
    std::vector<std::uint32_t> free_;
};

// ---------------------------------------------------------------------------------------------------------------------
// Uploads and descriptors
// ---------------------------------------------------------------------------------------------------------------------

// Room in an upload (CPU-written, GPU-read) buffer: write `cpu`, copy from `buffer` at `offset`.
struct UploadAlloc {
    VkBuffer buffer = VK_NULL_HANDLE;
    VkDeviceSize offset = 0;
    std::uint8_t* cpu = nullptr;
    bool ok() const { return buffer != VK_NULL_HANDLE; }
};

// The upload ring: one persistently mapped buffer shared by the frames in flight. Allocations move a head forward
// (wrapping to the start when the end has no room); a frame's room comes back once the GPU finished it.
class UploadRing {
public:
    void init(VkBuffer buffer, std::uint8_t* cpu, std::size_t bytes);
    // False when `size` does not fit: bigger than the ring, or the frames in flight still hold the room.
    bool alloc(std::size_t size, std::size_t align, UploadAlloc& out);
    // The recording of `frame` ended: what it took up to now belongs to it.
    void end_frame(std::uint64_t frame);
    // The GPU finished `frame` (and every frame before it).
    void frame_done(std::uint64_t frame);
    std::size_t size() const { return size_; }
    std::uint64_t wraps() const;
    std::size_t in_use() const;

private:
    mutable std::mutex mutex_;
    VkBuffer buffer_ = VK_NULL_HANDLE;
    std::uint8_t* cpu_ = nullptr;
    std::size_t size_ = 0;
    std::uint64_t head_ = 0;  // bytes ever taken (position = head_ % size_)
    std::uint64_t tail_ = 0;  // bytes ever given back
    std::uint64_t wraps_ = 0;
    std::deque<std::pair<std::uint64_t, std::uint64_t>> frames_;  // (frame, head at its end)
};

// The kinds of descriptor the per-frame pools hold.
enum DescriptorKind : int {
    kDescSampledImage = 0,
    kDescSampler,
    kDescStorageImage,
    kDescStorageBuffer,
    kDescUniformBufferDynamic,
    kDescCombinedImageSampler,
    kDescKinds,
};
// How many descriptors of each kind one set holds.
struct DescriptorCounts {
    std::array<std::uint32_t, kDescKinds> n{};
};
inline constexpr std::uint32_t kNoSlot = 0xFFFFFFFFu;

// The descriptor pools: one per frame in flight that the sets of that frame's draws come from (reset when the frame
// comes round again), and the bindless table (sampled images in one update-after-bind set, slots from a free list).
// Its own lock, taken inside the device's.
class DescriptorPools {
public:
    Result<void> init(VulkanDevice& device, int frames, std::uint32_t sets, std::uint32_t perKind,
                      std::uint32_t bindless);
    void destroy();
    // Whether the driver can make a bindless table of `count` sampled images (vkGetDescriptorSetLayoutSupport: a layout
    // over maxPerSetDescriptors may or may not be supported, and only this query says).
    static bool bindless_supported(const VulkanDevice& device, std::uint32_t count);
    // A set of `layout` from this frame's pool; `counts` = the descriptors the layout holds. The pool's room is counted
    // here, so a full pool is refused the same way on every driver.
    Result<VkDescriptorSet> alloc(VkDescriptorSetLayout layout, const DescriptorCounts& counts);
    // The frame in slot `slot` starts (the GPU finished the frame that used its pool last): its pool is empty again.
    void begin_frame(int slot);
    std::uint32_t frame_sets_used() const;
    std::uint32_t frame_descriptors_used() const;
    // The bindless table: its layout and its one set (null without one), its size, a free slot (kNoSlot when full) and
    // writing a sampled-image view into a slot. A freed slot is handed out again (the device frees it once the frames
    // that may read it are finished).
    VkDescriptorSetLayout bindless_layout() const { return bindlessLayout_; }
    VkDescriptorSet bindless_set() const { return bindlessSet_; }
    std::uint32_t bindless_capacity() const { return bindlessCapacity_; }
    std::uint32_t bindless_alloc();
    void bindless_free(std::uint32_t slot);
    void bindless_write(std::uint32_t slot, VkImageView view, VkImageLayout layout);
    std::uint32_t bindless_used() const;

private:
    mutable std::mutex mutex_;
    VulkanDevice* device_ = nullptr;
    std::vector<VkDescriptorPool> pools_;
    int slot_ = 0;
    std::uint32_t maxSets_ = 0;
    std::uint32_t perKind_ = 0;
    std::uint32_t setsUsed_ = 0;
    DescriptorCounts used_{};
    VkDescriptorPool bindlessPool_ = VK_NULL_HANDLE;
    VkDescriptorSetLayout bindlessLayout_ = VK_NULL_HANDLE;
    VkDescriptorSet bindlessSet_ = VK_NULL_HANDLE;
    std::uint32_t bindlessCapacity_ = 0;
    std::uint32_t bindlessNext_ = 0;  // slots never handed out start here
    std::vector<std::uint32_t> bindlessFree_;
};

// ---------------------------------------------------------------------------------------------------------------------
// Command lists
// ---------------------------------------------------------------------------------------------------------------------

// One command list of a frame: a VkCommandBuffer from a pool of its own (so lists can be recorded on several threads),
// reused once the GPU finished it. It tracks the state each subresource must be in at its start (`first`) and is in at
// its end (`current`); submit() records the barriers from the queue's states to `first` into a fix-up command buffer
// submitted just before it, so lists recorded in any order still meet the layouts the queue really has.
class VulkanCommandList final : public CommandList {
public:
    explicit VulkanCommandList(VulkanDevice& device) : device_(device) {}
    ~VulkanCommandList() override;
    VulkanCommandList(const VulkanCommandList&) = delete;
    VulkanCommandList& operator=(const VulkanCommandList&) = delete;

    void begin_pass(const PassDesc& pass) override;
    void begin_compute_pass(const char* label) override;
    void end_pass() override;
    PassState pass_state() const override { return PassState::None; }
    void set_pipeline(Pipeline pipeline) override;
    void set_bindings(const Bindings& bindings) override;
    void set_uniforms(int slot, Range data) override;
    void set_viewport(int x, int y, int width, int height, bool originTopLeft) override;
    void set_viewport_f(float x, float y, float width, float height, bool originTopLeft) override;
    void set_scissor(int x, int y, int width, int height, bool originTopLeft) override;
    void draw(int base, int count, int instances) override;
    void draw_ex(int base, int count, int instances, int baseVertex, int baseInstance) override;
    void dispatch(int x, int y, int z) override;
    void write_buffer(const BufferWrite& write) override;
    void write_image(const ImageWrite& write) override;
    void copy_buffer_to_buffer(const BufferCopy& copy) override;
    void copy_buffer_to_image(const BufferImageCopy& copy) override;
    void push_debug_group(const char* name) override;
    void pop_debug_group() override;
    void begin_timed_scope(const char* name) override;
    void end_timed_scope() override;

    // ---- the backend's side ------------------------------------------------------------------------------------------
    // Resource `t`'s subresource `sub` (or every one, kAllSubresources) must be in `state` for the next command.
    static constexpr std::uint32_t kAllSubresources = 0xFFFFFFFFu;
    void require(const std::shared_ptr<TrackedResource>& t, std::uint32_t sub, const SubState& state);
    // The same for mips [mip, mip + mipCount) of layers [layer, layer + layerCount).
    void require_range(const std::shared_ptr<TrackedResource>& t, std::uint32_t mip, std::uint32_t mipCount,
                       std::uint32_t layer, std::uint32_t layerCount, const SubState& state);
    // Records the barriers require() collected (before every command that needs them).
    void flush_barriers();
    VkCommandBuffer native() const { return cmd_; }
    const std::string& label() const { return label_; }
    // A buffer this list copies from or into that nothing else holds (a dedicated upload, a repack scratch buffer):
    // released with the frame.
    void keep_until_done(std::shared_ptr<TrackedResource> r);

private:
    friend class VulkanDevice;
    struct Use {
        std::shared_ptr<TrackedResource> res;
        std::vector<SubState> first;    // the state the list needs at its start; kUnknownLayout = not used
        std::vector<SubState> current;  // the state the list leaves it in; kUnknownLayout = not used
    };
    Result<void> create(const char* what);
    // Opens the list for recording (its previous commands must be finished).
    Result<void> open(const char* label);
    void not_yet(const char* what);
    void transition(Use& u, std::uint32_t sub, const SubState& state);
    // Copies texels from CPU memory into an image through the upload ring: a width x height region at (x, y) of mip
    // `mip`, `count` layers from `layer` (2D, cube, array) or `count` depth slices from `layer` (3D). Source rows are
    // `srcRowPitch` apart, slices `srcSlicePitch`. False (and errors()) when no upload room could be had.
    bool upload_region(const std::shared_ptr<TrackedResource>& t, PixelFormat format, bool is3d, std::uint32_t mip,
                       std::uint32_t layer, std::uint32_t count, std::uint32_t x, std::uint32_t y, std::uint32_t width,
                       std::uint32_t height, const std::uint8_t* src, std::size_t srcRowPitch,
                       std::size_t srcSlicePitch);
    // Records the barriers and the copy of a texel region from a buffer at `offset` (a multiple of the texel size), rows
    // of `rowTexels` texels and slices of `sliceRows` texel rows (0 = tightly packed).
    void copy_to_image(VkBuffer src, VkDeviceSize offset, std::uint32_t rowTexels, std::uint32_t sliceRows,
                       const std::shared_ptr<TrackedResource>& t, bool is3d, std::uint32_t mip, std::uint32_t layer,
                       std::uint32_t count, std::uint32_t x, std::uint32_t y, std::uint32_t width,
                       std::uint32_t height);

    VulkanDevice& device_;
    VkCommandPool pool_ = VK_NULL_HANDLE;
    VkCommandBuffer cmd_ = VK_NULL_HANDLE;
    VkCommandBuffer fixup_ = VK_NULL_HANDLE;  // the barriers submit() records before this list
    std::string label_;
    bool open_ = false;
    bool internal_ = false;    // the device's own list (initial uploads, readbacks), never handed out
    bool empty_ = true;        // no command recorded yet
    std::uint64_t fence_ = 0;  // the timeline value its last submission signals
    int debugDepth_ = 0;
    std::vector<Use> uses_;
    std::unordered_map<TrackedResource*, std::size_t> useIndex_;
    std::vector<Barrier> pending_;
    std::vector<std::shared_ptr<TrackedResource>> keep_;
};

// ---------------------------------------------------------------------------------------------------------------------
// The device
// ---------------------------------------------------------------------------------------------------------------------

// What the backend counted (tests, the profiler).
struct VulkanCounters {
    std::uint64_t uploadRingWraps = 0;         // times the ring's head went back to its start
    std::uint64_t dedicatedUploads = 0;        // uploads that took a buffer of their own (too big, or ring full)
    std::size_t uploadRingBytes = 0;           // the ring's size
    std::size_t uploadRingInUse = 0;           // bytes the frames in flight still hold
    std::size_t pendingReleases = 0;           // destroyed objects waiting for their frame to finish
    std::uint64_t barriers = 0;                // buffer and image barriers recorded (lists and fix-ups)
    std::uint64_t timelineValue = 0;           // the last value signalled
    std::uint64_t completedTimelineValue = 0;  // the last value the GPU reached
    MemoryCounters memory{};                   // the suballocator
    std::uint32_t frameDescriptorSets = 0;     // descriptor sets this frame took from its pool
    std::uint32_t frameDescriptors = 0;        // descriptors of every kind in them
    std::uint32_t bindlessUsed = 0;      // bindless slots handed out (freed ones waiting for their frame included)
    std::uint32_t bindlessCapacity = 0;  // the bindless table's size (0 = none)
};

// The Vulkan Device. Made, used for resources and destroyed on one thread (the render thread); command lists may be
// recorded on other threads (mutexes guard the queue, the pools, the ring, the allocator and the descriptor pools).
class VulkanDevice final : public Device {
public:
    static Result<std::unique_ptr<VulkanDevice>> create(const VulkanOptions& options);
    ~VulkanDevice() override;
    VulkanDevice(const VulkanDevice&) = delete;
    VulkanDevice& operator=(const VulkanDevice&) = delete;

    Backend backend() const override { return Backend::Vulkan; }
    const DeviceInfo& info() const override { return info_; }
    const Features& features() const override { return features_; }
    const Limits& limits() const override { return limits_; }
    PixelFormatCaps pixel_format_caps(PixelFormat format) const override;
    EnvironmentDefaults environment_defaults() const override { return defaults_; }

    NativeDevice native() const override;
    NativeImage native_image(Image image) const override;
    NativeBuffer native_buffer(Buffer buffer) const override;
    MetalNative* native_metal() override { return nullptr; }

    Buffer make_buffer(const BufferDesc& desc) override;
    Image make_image(const ImageDesc& desc) override;
    View make_view(const ViewDesc& desc) override;
    Sampler make_sampler(const SamplerDesc& desc) override;
    Shader make_shader(const ShaderDesc& desc) override;
    Pipeline make_pipeline(const PipelineDesc& desc) override;
    void destroy_buffer(Buffer buffer) override;
    void destroy_image(Image image) override;
    void destroy_view(View view) override;
    void destroy_sampler(Sampler sampler) override;
    void destroy_shader(Shader shader) override;
    void destroy_pipeline(Pipeline pipeline) override;
    ResourceState state(Buffer buffer) const override;
    ResourceState state(Image image) const override;
    ResourceState state(View view) const override;
    ResourceState state(Sampler sampler) const override;
    ResourceState state(Shader shader) const override;
    ResourceState state(Pipeline pipeline) const override;

    CommandList& begin_commands(const char* label) override;
    void submit(CommandList& list) override;
    void commit() override;
    std::uint64_t frame_index() const override { return frame_; }
    bool add_commit_listener(void (*func)(void* user), void* user) override;
    bool remove_commit_listener(void (*func)(void* user), void* user) override;
    void reset_state_cache() override {}

    void enable_stats(bool on) override { statsEnabled_ = on; }
    bool stats_enabled() const override { return statsEnabled_; }
    TotalStats total_stats() const override;

    bool timer_supported(std::string* why) const override;
    void timer_begin_frame() override {}
    void timer_end_frame() override {}
    void timer_poll(std::vector<double>&) override {}
    std::vector<ScopeTime> timer_last_scopes() const override { return {}; }
    void timer_forget() override {}

    Result<void> read_image_rgba8(Image image, int width, int height, std::vector<std::uint8_t>& out) override;
    Result<void> read_image_rgba16f(Image image, int width, int height, std::vector<float>& out) override;
    Result<void> read_storage_image(Image image, PixelFormat format, int x, int y, int width, int height,
                                    std::vector<std::uint8_t>& out) override;
    Result<void> read_buffer(Buffer buffer, std::size_t offset, std::size_t bytes,
                             std::vector<std::uint8_t>& out) override;
    bool async_read_supported() const override { return false; }
    Result<ReadTicket> request_buffer_read(Buffer buffer, std::size_t offset, std::size_t bytes) override;
    bool poll_buffer_read(ReadTicket ticket, std::vector<std::uint8_t>& out, bool wait) override;
    void release_buffer_read(ReadTicket) override {}

    // ---- Vulkan only (tests, M77-P8c) ---------------------------------------------------------------------------------
    const VkFunctions& fn() const { return fn_; }
    VkInstance vk_instance() const { return instance_; }
    VkPhysicalDevice physical_device() const { return physical_; }
    VkDevice vk_device() const { return device_; }
    VkQueue queue() const { return queue_; }
    std::uint32_t queue_family() const { return queueFamily_; }
    // The queue of a transfer-only family (null when the GPU has none; the graphics queue copies then).
    VkQueue transfer_queue() const { return transferQueue_; }
    std::uint32_t transfer_queue_family() const { return transferFamily_; }
    // The physical device's name ("Apple M5", "llvmpipe (LLVM 18.1.3, 256 bits)").
    const std::string& device_name() const { return deviceName_; }
    // The loader that was opened (a UTF-8 path or library name).
    const std::string& loader_path() const { return library_.path; }
    // VK_API_VERSION_MAJOR/MINOR of what the device was made with (at least 1.2).
    std::uint32_t api_version() const { return apiVersion_; }
    bool cpu_device() const { return cpuDevice_; }
    bool validation_active() const { return validation_; }
    bool synchronization2_active() const { return fn_.vkCmdPipelineBarrier2 != nullptr; }
    // VK_KHR_portability_subset is on (MoltenVK).
    bool portability_subset() const { return portability_; }
    int frames_in_flight() const { return framesInFlight_; }
    // The errors so far: the validation layer's ERROR messages, failed Vulkan calls, calls not built yet. Each also went
    // to the log.
    std::vector<std::string> errors();
    // The validation layer's WARNING messages so far.
    std::vector<std::string> warnings();
    void clear_messages();
    // Waits until the GPU finished everything submitted, then releases everything pending, the current frame's
    // destroyed objects included (their upload ring room is freed by the frame's commit, as lists may still be open).
    Result<void> wait_idle();
    VulkanCounters counters() const;
    // Mip `mip` of layer `layer` (array layer, cube face or 3D slice), the rectangle (x, y, w, h), tightly packed rows
    // top first, in the image's own format. Waits for the GPU.
    Result<void> read_image_region(Image image, int mip, int layer, int x, int y, int width, int height,
                                   std::vector<std::uint8_t>& out);
    // Upload room for this frame: from the ring, else a buffer of its own (kept by `keeper` until its frame is done).
    // !ok() only when Vulkan could not make that buffer (reported in errors()).
    UploadAlloc upload(std::size_t size, std::size_t align, VulkanCommandList* keeper);
    DescriptorPools& descriptors() { return descriptors_; }
    // Puts a Texture view into a free slot of the bindless table and returns the slot; the slot goes back to the free
    // list once the frames that may read it are finished (bindless_remove).
    Result<std::uint32_t> bindless_add(View textureView);
    void bindless_remove(std::uint32_t slot);
    MemoryAllocator& memory() { return memory_; }
    // The VkFormat of `f` on this device (DepthStencil: D24S8 where it is a depth attachment, else D32S8).
    VkFormat vk_format(PixelFormat f) const;
    // Names a Vulkan object in captures and validation messages (with debug utils; nothing otherwise).
    void set_name(VkObjectType type, std::uint64_t handle, const char* label) const;
    // Records `barriers` (merged where adjacent mips and layers go the same way) with synchronization2 or the 1.0
    // barriers.
    void record_barriers(VkCommandBuffer cmd, std::vector<Barrier>& barriers);
    // A buffer with memory for `use` (null with `error` set when Vulkan refused).
    std::shared_ptr<TrackedResource> make_raw_buffer(VkDeviceSize size, VkBufferUsageFlags usage, MemoryUse use,
                                                     bool dedicated, const char* label, std::string& error);
    // Reports an error: errors() and the log.
    void report(const std::string& message);
    // Reports `message` the first time `what` is reported (a call not built yet, made every frame).
    void report_once(const std::string& what, const std::string& message);
    // Called by the validation layer's messenger (any thread).
    void on_validation_message(VkDebugUtilsMessageSeverityFlagBitsEXT severity, const char* id, const char* text);

private:
    friend class VulkanCommandList;
    friend struct TrackedResource;
    VulkanDevice() = default;

    struct BufferRecord {
        std::shared_ptr<TrackedResource> tracked;  // null when the creation failed
        std::size_t size = 0;
        BufferUsage usage{};
        std::string label;
    };
    struct ImageRecord {
        std::shared_ptr<TrackedResource> tracked;  // null when the creation failed
        ImageType type = ImageType::Tex2d;
        ImageUsage usage{};
        PixelFormat format = PixelFormat::Rgba8;
        int width = 0, height = 0, slices = 1, mips = 1, samples = 1;
        std::string label;
    };
    struct ViewRecord {
        ViewType type = ViewType::Invalid;
        std::shared_ptr<TrackedResource> tracked;  // null when the creation failed
        Buffer buffer{};
        Image image{};
        int mip = 0, mipCount = 1, slice = 0, sliceCount = 1;
        std::size_t offset = 0;             // a storage buffer view's first byte
        VkImageView view = VK_NULL_HANDLE;  // image views
        VkImageViewType viewType = VK_IMAGE_VIEW_TYPE_2D;
    };
    struct SamplerRecord {
        VkSampler sampler = VK_NULL_HANDLE;  // null when the creation failed
    };
    // Something destroyed while the GPU may still use it: released once `frame` was committed and the GPU finished it.
    struct Deferred {
        std::uint64_t frame = 0;
        std::shared_ptr<TrackedResource> tracked;
        VkImageView view = VK_NULL_HANDLE;
        VkSampler sampler = VK_NULL_HANDLE;
        std::uint32_t bindlessSlot = kNoSlot;
    };
    struct Listener {
        void (*func)(void*) = nullptr;
        void* user = nullptr;
    };

    Result<void> init(const VulkanOptions& options);
    Result<void> init_instance(const VulkanOptions& options);
    Result<void> init_device(const VulkanOptions& options);
    void init_caps();
    // A free command list (open for recording), from the pool or new; null with errors() when Vulkan failed.
    VulkanCommandList* acquire_list(const char* label, bool internal);
    // Ends `list`, records its fix-up barriers, submits both and signals the timeline. Under queueMutex_.
    void execute(VulkanCommandList& list);
    // Submits `count` command buffers and signals ++timelineValue_. Under queueMutex_.
    bool submit_signal(const VkCommandBuffer* cmds, std::uint32_t count, const char* what);
    // The device's own list for initial uploads and readbacks, opened on first use. Under queueMutex_.
    VulkanCommandList& prelude();
    // Executes the prelude if it recorded anything. Under queueMutex_.
    void flush_prelude();
    // Waits (bounded) until the timeline reaches `value`. Under queueMutex_ or not.
    Result<void> wait_timeline(std::uint64_t value, const char* what);
    std::uint64_t completed_value() const;
    // Releases what the GPU is done with and gives the finished frames' ring room back. Under queueMutex_.
    void collect();
    void defer(Deferred d);
    void release(Deferred& d);
    void count_make(ResourceTotals& t, bool ok);
    void count_destroy(ResourceTotals& t);
    std::shared_ptr<TrackedResource> buffer_tracked(Buffer b, std::size_t* size, std::string* label) const;
    // The image's record copied out (under resMutex_): false when `image` names nothing or failed.
    bool image_info(Image image, ImageRecord& out) const;
    void upload_initial_image(const ImageRecord& rec, const ImageDesc& desc);
    // Copies a region of the image into a host-visible buffer and waits; the rows come back tightly packed.
    Result<void> read_texture(const ImageRecord& rec, std::uint32_t mip, std::uint32_t layer, int x, int y, int width,
                              int height, std::vector<std::uint8_t>& out, const char* what);

    // The Vulkan objects
    VulkanLibrary library_{};
    VkFunctions fn_{};
    VkInstance instance_ = VK_NULL_HANDLE;
    VkDebugUtilsMessengerEXT messenger_ = VK_NULL_HANDLE;
    VkPhysicalDevice physical_ = VK_NULL_HANDLE;
    VkDevice device_ = VK_NULL_HANDLE;
    VkQueue queue_ = VK_NULL_HANDLE;
    std::uint32_t queueFamily_ = 0;
    VkQueue transferQueue_ = VK_NULL_HANDLE;
    std::uint32_t transferFamily_ = 0;
    VkSemaphore timeline_ = VK_NULL_HANDLE;
    VkPhysicalDeviceProperties props_{};
    std::string deviceName_;
    std::uint32_t apiVersion_ = 0;
    bool cpuDevice_ = false;
    bool validation_ = false;
    bool debugUtils_ = false;
    bool portability_ = false;
    bool imageView2DOn3D_ = true;
    bool anisotropy_ = false;
    bool descriptorIndexing_ = false;
    int framesInFlight_ = kInflightFrames;
    VkFormat depthStencilFormat_ = VK_FORMAT_D24_UNORM_S8_UINT;
    std::size_t imageUploadAlign_ = 16;

    // What the device can do
    DeviceInfo info_{};
    Features features_{};
    Limits limits_{};
    EnvironmentDefaults defaults_{};
    std::array<PixelFormatCaps, std::size_t(PixelFormat::Count)> caps_{};

    MemoryAllocator memory_;
    DescriptorPools descriptors_;

    // Resources (resMutex_)
    mutable std::mutex resMutex_;
    Pool<BufferRecord> buffers_;
    Pool<ImageRecord> images_;
    Pool<ViewRecord> views_;
    Pool<SamplerRecord> samplers_;

    // The queue, the frames, the lists (queueMutex_)
    mutable std::mutex queueMutex_;
    std::vector<std::unique_ptr<VulkanCommandList>> lists_;
    VulkanCommandList* prelude_ = nullptr;
    std::uint64_t timelineValue_ = 0;
    std::uint64_t frame_ = 0;
    std::uint64_t completedFrames_ = 0;  // frames [0, completedFrames_) are finished on the GPU
    std::deque<std::pair<std::uint64_t, std::uint64_t>> frameValues_;  // (frame, timeline value of its commit)
    std::deque<Deferred> deferred_;
    std::shared_ptr<TrackedResource> ringBuffer_;
    UploadRing ring_;
    std::atomic<std::uint64_t> dedicatedUploads_{0};
    std::atomic<std::uint64_t> barriers_{0};
    std::vector<Listener> listeners_;

    // Messages (msgMutex_)
    mutable std::mutex msgMutex_;
    std::vector<std::string> errors_;
    std::vector<std::string> warnings_;
    std::vector<std::string> notYetReported_;  // each "not yet" call is reported once

    // Statistics (resMutex_)
    bool statsEnabled_ = false;
    TotalStats stats_{};
};

}  // namespace fa::gpu::vk

#endif  // FA_VULKAN_BACKEND
