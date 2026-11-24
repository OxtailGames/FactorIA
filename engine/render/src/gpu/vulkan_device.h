// Private to fa_render: the engine's own Vulkan backend of the GPU interface (M77.3,
// docs/design/ARCHITECTURE_RENDERING_VULKAN.md).
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
// What M77-P8c built (vulkan_pipelines.cpp, vulkan_commands.cpp): shaders from SPIR-V with sokol-shdc's descriptor
// layout, cached descriptor set layouts, pipeline layouts, render passes and pipelines (a VkPipelineCache under them),
// render passes recorded into secondary command buffers, compute passes, bindings, uniforms through dynamic uniform
// buffers, viewports, scissors, draws and dispatches. What M77-P8b1 built: GPU timers (timestamp query pools,
// vulkan_timers.cpp), asynchronous buffer and image reads (vulkan_readback.cpp) and storage_image_loadable. A pass into
// the window comes in M77-P9 (until then begin_pass reports an error naming it).
#pragma once

#include <cstddef>
#include <cstdint>
#include <filesystem>
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
    // With validation: the layer's synchronization validation too (VK_EXT_validation_features), so a missing or wrong
    // barrier between two commands is an error in errors(). Slow: for tests. Without the extension (an old layer) a
    // warning says so and synchronization_validation_active() is false.
    bool synchronizationValidation = false;
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
    // The per-frame descriptor pools (a chain per frame in flight, reset when that frame comes round again): the sets,
    // and the descriptors of each kind (sampled image, sampler, storage image, storage buffer, dynamic uniform buffer,
    // combined image-sampler), of ONE pool of the chain, 1 to 1048576 each; and the pools a frame may chain when one
    // is full, 1 to 64 (a frame takes the next pool only when the one before is full, so a light frame holds one).
    int frameDescriptorSets = 4096;
    int frameDescriptors = 32768;
    int frameDescriptorPools = 8;
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
    // The VkPipelineCache's data on disk: read when the device is made (a file of another GPU, driver or pipeline
    // cache layout, a cut or corrupt one, is thrown away with a warning), written when the device is destroyed if it
    // gained pipelines (or VulkanDevice::save_pipeline_cache() at a point of the caller's choice). The write is atomic
    // (a temporary file renamed over the old one); one that fails (a directory that cannot be written, a file another
    // process holds open on Windows) is a warning and keeps the old file. Empty = in memory only. The renderer gives
    // vulkan_pipeline_cache_file().
    std::filesystem::path pipelineCacheFile;
};

// Makes a Vulkan device. Fails with a teaching error where the backend is not built (web, iOS), when an option is out of
// range (before any Vulkan call), when no Vulkan loader is found, or when no device has Vulkan 1.2 with timeline
// semaphores and a graphics + compute queue.
Result<std::unique_ptr<Device>> make_vulkan_device(const VulkanOptions& options = {});

// Where the engine keeps the Vulkan pipeline cache: shaders/vulkan-pipelines.bin in the user's cache directory
// (fa::fs::cache_dir()), next to the D3D12 one.
std::filesystem::path vulkan_pipeline_cache_file();

// The range of a storage buffer descriptor of the buffer's `bufferBytes` from `offset`: VK_WHOLE_SIZE (~0) when the
// rest of the buffer fits the device's maxStorageBufferRange, else that limit rounded down to whole 32-bit words (a
// shader reads no further; a bigger buffer is viewed in pieces).
std::uint64_t storage_buffer_range(std::uint64_t bufferBytes, std::uint64_t offset, std::uint64_t maxRange);

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
#include <map>
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
    X(vkCmdCopyImageToBuffer)                                                                                          \
    X(vkCreateShaderModule)                                                                                            \
    X(vkDestroyShaderModule)                                                                                           \
    X(vkCreatePipelineLayout)                                                                                          \
    X(vkDestroyPipelineLayout)                                                                                         \
    X(vkCreateGraphicsPipelines)                                                                                       \
    X(vkCreateComputePipelines)                                                                                        \
    X(vkDestroyPipeline)                                                                                               \
    X(vkCreatePipelineCache)                                                                                           \
    X(vkDestroyPipelineCache)                                                                                          \
    X(vkGetPipelineCacheData)                                                                                          \
    X(vkCreateRenderPass)                                                                                              \
    X(vkDestroyRenderPass)                                                                                             \
    X(vkCreateFramebuffer)                                                                                             \
    X(vkDestroyFramebuffer)                                                                                            \
    X(vkCmdBeginRenderPass)                                                                                            \
    X(vkCmdEndRenderPass)                                                                                              \
    X(vkCmdExecuteCommands)                                                                                            \
    X(vkCmdBindPipeline)                                                                                               \
    X(vkCmdBindDescriptorSets)                                                                                         \
    X(vkCmdBindVertexBuffers)                                                                                          \
    X(vkCmdBindIndexBuffer)                                                                                            \
    X(vkCmdSetViewport)                                                                                                \
    X(vkCmdSetScissor)                                                                                                 \
    X(vkCmdSetBlendConstants)                                                                                          \
    X(vkCmdSetStencilReference)                                                                                        \
    X(vkCmdDraw)                                                                                                       \
    X(vkCmdDrawIndexed)                                                                                                \
    X(vkCmdDispatch)                                                                                                   \
    X(vkCreateQueryPool)                                                                                               \
    X(vkDestroyQueryPool)                                                                                              \
    X(vkCmdResetQueryPool)                                                                                             \
    X(vkCmdWriteTimestamp)                                                                                             \
    X(vkGetQueryPoolResults)

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

// The descriptor pools: a chain per frame in flight that the sets of that frame's draws come from (reset when the
// frame comes round again; a frame whose pool is full takes the next one, made on first use, up to `chain` pools), and
// the bindless table (sampled images in one update-after-bind set, slots from a free list). Its own lock, taken inside
// the device's.
class DescriptorPools {
public:
    Result<void> init(VulkanDevice& device, int frames, std::uint32_t sets, std::uint32_t perKind, std::uint32_t chain,
                      std::uint32_t bindless);
    void destroy();
    // Whether the driver can make a bindless table of `count` sampled images (vkGetDescriptorSetLayoutSupport: a layout
    // over maxPerSetDescriptors may or may not be supported, and only this query says).
    static bool bindless_supported(const VulkanDevice& device, std::uint32_t count);
    // A set of `layout` from this frame's pools; `counts` = the descriptors the layout holds. Each pool's room is
    // counted here, so a full pool (and a full chain) is refused the same way on every driver.
    Result<VkDescriptorSet> alloc(VkDescriptorSetLayout layout, const DescriptorCounts& counts);
    // The frame in slot `slot` starts (the GPU finished the frame that used its pools last): they are empty again.
    void begin_frame(int slot);
    // This frame's sets and descriptors (every pool of its chain), and the pools of the chain it took.
    std::uint32_t frame_sets_used() const;
    std::uint32_t frame_descriptors_used() const;
    std::uint32_t frame_pools_used() const;
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
    // A pool of a frame's chain, and what this frame took from it.
    struct FramePool {
        VkDescriptorPool pool = VK_NULL_HANDLE;
        std::uint32_t setsUsed = 0;
        DescriptorCounts used{};
    };
    Result<VkDescriptorPool> make_pool() const;

    VulkanDevice* device_ = nullptr;
    std::vector<std::vector<FramePool>> pools_;  // [frame slot]: the chain, made as far as a frame needed it
    int slot_ = 0;
    std::size_t active_ = 0;  // the pool of this frame's chain the sets come from
    std::uint32_t maxSets_ = 0;
    std::uint32_t perKind_ = 0;
    std::uint32_t chain_ = 1;
    VkDescriptorPool bindlessPool_ = VK_NULL_HANDLE;
    VkDescriptorSetLayout bindlessLayout_ = VK_NULL_HANDLE;
    VkDescriptorSet bindlessSet_ = VK_NULL_HANDLE;
    std::uint32_t bindlessCapacity_ = 0;
    std::uint32_t bindlessNext_ = 0;  // slots never handed out start here
    std::vector<std::uint32_t> bindlessFree_;
};

// ---------------------------------------------------------------------------------------------------------------------
// Shaders, layouts, pipelines, render passes (vulkan_pipelines.cpp)
// ---------------------------------------------------------------------------------------------------------------------

// A shader's modules and the reflection the command lists bind by. Shared by the shader record and every pipeline made
// from it, so destroy_shader() never pulls the modules from under a pipeline being made. The destructor destroys the
// modules.
struct ShaderInfo {
    VulkanDevice* device = nullptr;
    bool compute = false;
    std::string label;
    VkShaderModule vs = VK_NULL_HANDLE, fs = VK_NULL_HANDLE, cs = VK_NULL_HANDLE;
    std::string vsEntry = "main", fsEntry = "main", csEntry = "main";
    std::uint32_t uniformSize[kMaxUniformBlocks]{};  // 0 = the slot is unused
    ViewType viewType[kMaxViews]{};                  // Invalid = the slot is unused
    bool viewWritable[kMaxViews]{};                  // a storage image, or a storage buffer that is not readonly
    ImageType viewImageType[kMaxViews]{};            // textures and storage images: what the view must be
    std::string codeKey;                             // SHA-256 of the SPIR-V and the entries (the pipeline cache key)
    bool pointSize = false;  // the vertex stage writes its PointSize output (what a point-list pipeline needs)
    ShaderInfo() = default;
    ShaderInfo(const ShaderInfo&) = delete;
    ShaderInfo& operator=(const ShaderInfo&) = delete;
    ~ShaderInfo();
};

// A descriptor set layout, shared by every pipeline layout with the same set. The last holder's destructor hands the
// VkDescriptorSetLayout to the device, which destroys it once the frames that may use it are finished.
struct SetLayoutObject {
    VulkanDevice* device = nullptr;
    VkDescriptorSetLayout layout = VK_NULL_HANDLE;
    SetLayoutObject() = default;
    SetLayoutObject(const SetLayoutObject&) = delete;
    SetLayoutObject& operator=(const SetLayoutObject&) = delete;
    ~SetLayoutObject();
};

// A VkPipeline, shared by the device's cache (while a live shader has its code) and every pipeline state made with it.
// The last holder's destructor hands it to the device (destroyed once the frames that may use it are finished).
struct PipelineObject {
    VulkanDevice* device = nullptr;
    VkPipeline pipeline = VK_NULL_HANDLE;
    PipelineObject() = default;
    PipelineObject(const PipelineObject&) = delete;
    PipelineObject& operator=(const PipelineObject&) = delete;
    ~PipelineObject();
};

// A pipeline layout as sokol-shdc lays the descriptors out: set 0 holds the uniform blocks (dynamic uniform buffers),
// set 1 the views and samplers, set 2 the bindless table (every layout has it when the device has one). Cached by its
// key while a shader or pipeline holds it: every shader with the same bindings shares one. The destructor hands the
// VkPipelineLayout to the device (destroyed once the frames that may use it are finished).
struct PipelineLayoutInfo {
    VulkanDevice* device = nullptr;
    std::shared_ptr<const SetLayoutObject> setObjects[2];  // what sets[] are (kept while the layout lives)
    VkPipelineLayout layout = VK_NULL_HANDLE;
    VkDescriptorSetLayout sets[2] = {VK_NULL_HANDLE, VK_NULL_HANDLE};  // an empty layout where a set is unused
    DescriptorCounts counts[2]{};                                      // what one set of each holds
    bool hasSet[2] = {false, false};
    std::uint32_t uniformBinding[kMaxUniformBlocks]{};
    std::uint8_t uniformOrder[kMaxUniformBlocks]{};  // the used slots by binding (the order of the dynamic offsets)
    int uniformCount = 0;
    std::uint32_t viewBinding[kMaxViews]{};
    VkPipelineStageFlags2 viewStage[kMaxViews]{};  // the stage that reads the view (what its barriers wait for)
    std::uint32_t samplerBinding[kMaxSamplers]{};
    std::uint32_t samplerUsed = 0;  // bit i = sampler slot i
    bool bindless = false;          // set 2 is the bindless table
    std::string key;
    PipelineLayoutInfo() = default;
    PipelineLayoutInfo(const PipelineLayoutInfo&) = delete;
    PipelineLayoutInfo& operator=(const PipelineLayoutInfo&) = delete;
    ~PipelineLayoutInfo();
};

// What a pipeline draws with: its VkPipeline (`object`, shared with the device's cache), its layout and shader, and the
// state the command list sets with it.
struct PipelineState {
    std::shared_ptr<const PipelineObject> object;
    VkPipeline pipeline = VK_NULL_HANDLE;  // object's
    std::shared_ptr<const PipelineLayoutInfo> layout;
    std::shared_ptr<const ShaderInfo> shader;
    bool compute = false;
    IndexType indexType = IndexType::None;
    std::uint32_t buffersUsed = 0;  // bit i = vertex buffer slot i
    float blendColor[4]{};
    std::uint32_t stencilRef = 0;
    TargetFormat format{};
    int colorCount = 0;
    std::string label;
};

// A render pass by its attachments: the formats and sample count, and what it does with each at its start and end.
// Pipelines are made with a compatible pass (every load and store DONT_CARE); begin_pass uses the real one.
struct RenderPassKey {
    VkFormat color[2] = {VK_FORMAT_UNDEFINED, VK_FORMAT_UNDEFINED};
    int colorCount = 0;
    VkFormat depth = VK_FORMAT_UNDEFINED;    // UNDEFINED = no depth attachment
    VkFormat resolve = VK_FORMAT_UNDEFINED;  // UNDEFINED = no resolve of colour attachment 0
    VkSampleCountFlagBits samples = VK_SAMPLE_COUNT_1_BIT;
    VkAttachmentLoadOp colorLoad = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
    VkAttachmentStoreOp colorStore = VK_ATTACHMENT_STORE_OP_DONT_CARE;
    VkAttachmentLoadOp depthLoad = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
    VkAttachmentStoreOp depthStore = VK_ATTACHMENT_STORE_OP_DONT_CARE;
    VkAttachmentLoadOp stencilLoad = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
    VkAttachmentStoreOp stencilStore = VK_ATTACHMENT_STORE_OP_DONT_CARE;
    std::string text() const;
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
    PassState pass_state() const override { return passState_; }
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
    // Where draws, bindings and debug labels go now: the pass's secondary command buffer inside a render pass, the list's
    // own command buffer elsewhere.
    VkCommandBuffer recording() const { return rec_ ? rec_ : cmd_; }
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
        // The source of the last barrier the list recorded for the subresource (kUnknownLayout = none yet): a read in a
        // stage that barrier did not reach waits for it again.
        std::vector<SubState> since;
    };
    Result<void> create(const char* what);
    // Opens the list for recording (its previous commands must be finished).
    Result<void> open(const char* label);
    // Reports "CommandList::<what> in list '<label>': <error>".
    void fail(const char* what, const std::string& error);
    // Forgets the pipeline, uniforms and bindings (a new pass or pipeline).
    void reset_bind_state();
    // A command of the open pass needs mips [mip, mip + mipCount) of layers [layer, layer + layerCount) of `t` in
    // `state`. In a render pass the needs are merged and applied before the pass begins (no barrier can go inside
    // one); in a compute pass they are kept for every dispatch. False with `error` set when the render pass already
    // uses a subresource in another layout.
    bool need(const std::shared_ptr<TrackedResource>& t, std::uint32_t mip, std::uint32_t mipCount, std::uint32_t layer,
              std::uint32_t layerCount, const SubState& state, std::string& error);
    // A secondary command buffer for the next render pass (reset with the list); null with `error` set.
    VkCommandBuffer next_secondary(std::string& error);
    // Forgets the pass (end_pass, open).
    void clear_pass_state();
    // Checks that a draw or dispatch can run and binds what changed (the uniform set).
    bool ready_to_run(const char* what, bool compute);
    void record_draw(const char* what, int base, int count, int instances, int baseVertex, int baseInstance);
    void apply_viewport(const char* what, float x, float y, float width, float height, bool originTopLeft);
    void transition(Use& u, std::uint32_t sub, const SubState& state);
    // Writes the end timestamp of the open timed scope.
    void close_scope();
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
    std::uint64_t openFrame_ = 0;  // the frame it was opened in (its uniforms and descriptors are that frame's)
    // The timed scopes recorded in this list (reset by open()); the last one is still open when scopeOpen_.
    struct ScopeRef {
        int slot = -1;             // the timed frame's slot
        std::uint64_t serial = 0;  // the timed frame
        std::uint32_t scope = 0;   // the scope's index in it
        VkQueryPool pool = VK_NULL_HANDLE;
    };
    std::vector<ScopeRef> scopes_;
    bool scopeOpen_ = false;

    // The pass
    struct Need {
        std::shared_ptr<TrackedResource> res;
        std::uint32_t sub = 0;
        SubState state{};
    };
    PassState passState_ = PassState::None;
    bool passFailed_ = false;   // begin_pass failed: the pass's commands are skipped
    bool drawsFailed_ = false;  // a pipeline, bindings or uniforms failed: draws are skipped until the next pipeline
    TargetFormat passFormat_{};
    int passColors_ = 0;
    std::uint32_t passWidth_ = 0, passHeight_ = 0;
    bool viewportEmpty_ = false;            // the viewport has no area: draws are skipped
    VkCommandBuffer rec_ = VK_NULL_HANDLE;  // the render pass's secondary command buffer (null outside one)
    VkRenderPass passHandle_ = VK_NULL_HANDLE;
    VkFramebuffer passFramebuffer_ = VK_NULL_HANDLE;
    std::vector<VkClearValue> passClears_;
    std::vector<Need> passNeeds_;  // render pass: the states its attachments and draws need, merged
    std::map<std::pair<const TrackedResource*, std::uint32_t>, std::size_t> passNeedIndex_;  // -> passNeeds_
    std::vector<Need> boundNeeds_;  // compute pass: what the bound views need before each dispatch, merged
    std::map<std::pair<const TrackedResource*, std::uint32_t>, std::size_t> boundNeedIndex_;  // -> boundNeeds_
    std::vector<VkCommandBuffer> secondaries_;
    std::size_t secondaryNext_ = 0;
    std::vector<std::string> passGroups_;  // debug groups pushed inside the render pass and still open
    int passOuterPops_ = 0;                // pops inside the render pass of groups pushed before it

    // Pipeline, bindings, uniforms
    std::shared_ptr<const PipelineState> pipeline_;
    std::uint32_t uniformsSet_ = 0;  // bit i = uniform slot i was set since set_pipeline
    bool bindingsSet_ = false;
    // Bit n = descriptor set n (0 uniforms, 1 views and samplers, 2 bindless) must be bound again before the next draw
    // or dispatch: set_pipeline marks all three (its layout may differ), set_uniforms set 0, set_bindings set 1. Sets
    // bound with the same pipeline layout do not disturb each other.
    std::uint32_t setsDirty_ = 0;
    VkDescriptorSet viewSet_ = VK_NULL_HANDLE;  // set 1 of the last set_bindings (this frame's pool)
    VkBuffer uniformBuffer_[kMaxUniformBlocks]{};
    std::uint32_t uniformOffset_[kMaxUniformBlocks]{};
    std::unordered_map<std::string, VkDescriptorSet> uniformSets_;  // set 0 by (layout, buffers): reset with the list
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
    std::uint32_t frameDescriptorSets = 0;     // descriptor sets this frame took from its pools
    std::uint32_t frameDescriptors = 0;        // descriptors of every kind in them
    std::uint32_t frameDescriptorPools = 0;    // the pools of its chain this frame took (1 until one was full)
    std::uint32_t bindlessUsed = 0;        // bindless slots handed out (freed ones waiting for their frame included)
    std::uint32_t bindlessCapacity = 0;    // the bindless table's size (0 = none)
    std::uint64_t descriptorSetBinds = 0;  // vkCmdBindDescriptorSets calls of every list (one per set bound)
    // The caches of pipelines (VkPipeline by shader code, layout and state), layouts (descriptor set and pipeline
    // layouts), render passes and framebuffers (by render pass, attachments and size): hits, misses (objects made) and
    // the objects they hold now (a destroyed shader's pipelines and layouts, a destroyed view's framebuffers leave).
    std::uint64_t pipelineCacheHits = 0, pipelineCacheMisses = 0;
    std::uint64_t layoutCacheHits = 0, layoutCacheMisses = 0;
    std::uint64_t renderPassCacheHits = 0, renderPassCacheMisses = 0;
    std::uint64_t framebufferCacheHits = 0, framebufferCacheMisses = 0;
    std::size_t pipelinesCached = 0, pipelineLayoutsCached = 0, setLayoutsCached = 0, framebuffersCached = 0;
    // The pipeline cache file (VulkanOptions::pipelineCacheFile): whether the device was made with its data, the
    // file's bytes then, the saves that wrote it, the files thrown away (another GPU or driver, cut, corrupt) and the
    // saves that failed (the old file kept).
    bool pipelineCacheLoaded = false;
    std::uint64_t pipelineCacheFileBytes = 0;
    std::uint64_t pipelineCacheStored = 0, pipelineCacheDiscarded = 0, pipelineCacheStoreFailed = 0;
};

// The pipeline cache file: a header of its own (what the data was made for, its size and SHA-256), then the
// VkPipelineCache data, which starts with Vulkan's VkPipelineCacheHeaderVersionOne. Little-endian.
struct PipelineCacheFile {
    static constexpr char kMagic[8] = {'F', 'A', 'V', 'K', 'P', 'S', 'O', '\0'};
    static constexpr std::uint32_t kVersion = 1;
    static constexpr std::size_t kMagicAt = 0;           // 8 bytes
    static constexpr std::size_t kVersionAt = 8;         // u32
    static constexpr std::size_t kHeaderBytesAt = 12;    // u32: kHeaderBytes
    static constexpr std::size_t kVendorAt = 16;         // u32 VkPhysicalDeviceProperties::vendorID
    static constexpr std::size_t kDeviceAt = 20;         // u32 deviceID
    static constexpr std::size_t kDriverAt = 24;         // u32 driverVersion
    static constexpr std::size_t kUuidAt = 32;           // 16 bytes pipelineCacheUUID
    static constexpr std::size_t kPayloadBytesAt = 48;   // u64: the bytes after the header
    static constexpr std::size_t kPayloadSha256At = 56;  // 64 hex digits
    static constexpr std::size_t kHeaderBytes = 120;
    // Vulkan's own header at the start of the data (VkPipelineCacheHeaderVersionOne).
    static constexpr std::size_t kVkHeaderBytes = 32;  // headerSize, headerVersion, vendorID, deviceID, UUID
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

    // GPU timers (vulkan_timers.cpp): timestamp queries on the graphics queue, a ring of kTimerSlots timed frames each
    // with its own query pool, read once the frame's timeline value passed (never waited for).
    bool timer_supported(std::string* why) const override;
    void timer_begin_frame() override;
    void timer_end_frame() override;
    void timer_poll(std::vector<double>& frameMs) override;
    std::vector<ScopeTime> timer_last_scopes() const override;
    void timer_forget() override;
    // Rgba8, Rgba16F, R32F and Rgba32F where the format's optimal tiling has STORAGE_IMAGE (sokol-shdc's SPIR-V names
    // the image's format, so no shaderStorageImageReadWithoutFormat is needed).
    bool storage_image_loadable(PixelFormat format, std::string* why) const override;

    Result<void> read_image_rgba8(Image image, int width, int height, std::vector<std::uint8_t>& out) override;
    Result<void> read_image_rgba16f(Image image, int width, int height, std::vector<float>& out) override;
    Result<void> read_storage_image(Image image, PixelFormat format, int x, int y, int width, int height,
                                    std::vector<std::uint8_t>& out) override;
    Result<void> read_buffer(Buffer buffer, std::size_t offset, std::size_t bytes,
                             std::vector<std::uint8_t>& out) override;
    // Asynchronous reads (vulkan_readback.cpp): kAsyncReads slots, each with a host-visible buffer it keeps while it is
    // big enough. A request records the copy on an internal list and submits it at once (no wait); the slot's timeline
    // value says when the bytes are there. A released slot is reused only once its copy finished.
    bool async_read_supported() const override { return true; }
    Result<ReadTicket> request_buffer_read(Buffer buffer, std::size_t offset, std::size_t bytes) override;
    bool poll_buffer_read(ReadTicket ticket, std::vector<std::uint8_t>& out, bool wait) override;
    void release_buffer_read(ReadTicket ticket) override;

    // ---- Vulkan only (tests, the backend's own code) ------------------------------------------------------------------
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
    bool synchronization_validation_active() const { return syncValidation_; }
    bool synchronization2_active() const { return fn_.vkCmdPipelineBarrier2 != nullptr; }
    // VK_KHR_portability_subset is on (MoltenVK).
    bool portability_subset() const { return portability_; }
    int frames_in_flight() const { return framesInFlight_; }
    // The errors so far: the validation layer's ERROR messages, failed Vulkan calls, calls not built yet. Each also went
    // to the log.
    std::vector<std::string> errors();
    // The validation layer's WARNING messages so far, and the backend's own warnings (a bindless table cut down to what
    // the GPU binds, a pipeline cache file thrown away or not written).
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
    // The asynchronous read of the same region: poll_buffer_read() hands it over tightly packed, top row first, in the
    // image's own format; release_buffer_read() drops it. An invalid ticket with ok = every slot is busy. Render thread
    // only.
    Result<ReadTicket> request_image_read(Image image, int mip, int layer, int x, int y, int width, int height);
    // The ticks of a timestamp that are valid (the queue family's timestampValidBits; 0 = no timers) and the
    // nanoseconds per tick.
    std::uint32_t timestamp_valid_bits() const { return timestampBits_; }
    float timestamp_period() const { return props_.limits.timestampPeriod; }
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
    // The VkPipelineCache every pipeline is made through (its data loaded from and saved to
    // VulkanOptions::pipelineCacheFile).
    VkPipelineCache pipeline_cache() const { return pipelineCache_; }
    // Writes the pipeline cache's data to VulkanOptions::pipelineCacheFile when pipelines were made since it was read
    // or last written (the destructor calls it too); nothing without a file. The write is atomic: a failure (the
    // directory cannot be written, another process holds the file open on Windows) keeps the old file and returns a
    // teaching error that also goes to warnings(). Render thread.
    Result<void> save_pipeline_cache();
    const std::filesystem::path& pipeline_cache_file() const { return cacheFile_; }
    // Tests of the path of a device without 2D views of 3D images (VK_KHR_portability_subset's imageView2DOn3DImage):
    // false makes the device refuse them as such a device does.
    void set_image_view_2d_on_3d_for_tests(bool on) { imageView2DOn3D_ = on && imageView2DOn3DReal_; }
    // A Vulkan object whose last holder let go (a shader's pipeline, a pipeline or descriptor set layout): destroyed
    // once the frames that may use it are finished. Any thread, any lock held (a leaf lock of its own).
    void retire_pipeline(VkPipeline pipeline);
    void retire_pipeline_layout(VkPipelineLayout layout);
    void retire_set_layout(VkDescriptorSetLayout layout);
    // The framebuffer of `renderPass` with `views` (attachment order) of `width` x `height`, from the cache or made
    // now (null with `error` set when Vulkan refused). `serials` name the views (ViewRecord::serial): a destroyed view
    // takes its framebuffers out of the cache (forget_framebuffers), and a new view with the same handle never finds
    // them.
    VkFramebuffer framebuffer(VkRenderPass renderPass, const std::vector<VkImageView>& views,
                              const std::vector<std::uint64_t>& serials, std::uint32_t width, std::uint32_t height,
                              std::string& error);
    void forget_framebuffers(std::uint64_t viewSerial);
    void count_descriptor_set_bind() { ++descriptorSetBinds_; }
    // A pipeline's state (null when `pipeline` names nothing or failed).
    std::shared_ptr<const PipelineState> pipeline_state(Pipeline pipeline) const;
    // The render pass of `key`, from the cache or made now; null with `error` set when Vulkan refused.
    VkRenderPass render_pass(const RenderPassKey& key, std::string& error);
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
        std::uint64_t serial = 0;  // unique for the device's life (the framebuffer cache's key)
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
        VkPipeline pipeline = VK_NULL_HANDLE;
        VkPipelineLayout pipelineLayout = VK_NULL_HANDLE;
        VkDescriptorSetLayout setLayout = VK_NULL_HANDLE;
        VkFramebuffer framebuffer = VK_NULL_HANDLE;
    };
    struct FramebufferEntry {
        VkFramebuffer framebuffer = VK_NULL_HANDLE;
        std::vector<std::uint64_t> serials;  // the views it was made with
    };
    struct Listener {
        void (*func)(void*) = nullptr;
        void* user = nullptr;
    };
    struct ShaderRecord {
        std::shared_ptr<ShaderInfo> info;  // null when the creation failed
        std::shared_ptr<const PipelineLayoutInfo> layout;
    };
    struct PipelineRecord {
        std::shared_ptr<const PipelineState> state;  // null when the creation failed
    };

    Result<void> init(const VulkanOptions& options);
    Result<void> init_instance(const VulkanOptions& options);
    Result<void> init_device(const VulkanOptions& options);
    void init_caps();
    // A free command list (open for recording), from the pool or new; null with errors() when Vulkan failed.
    VulkanCommandList* acquire_list(const char* label, bool internal);
    // Ends `list`, records its fix-up barriers, submits both and signals the timeline (list.fence_). The resources'
    // tracked states and the list's timed scopes change only when the submission worked; false (reported) otherwise.
    // Under queueMutex_.
    bool execute(VulkanCommandList& list);
    // Submits `count` command buffers and signals ++timelineValue_. Under queueMutex_.
    bool submit_signal(const VkCommandBuffer* cmds, std::uint32_t count, const char* what);
    // The device's own list for initial uploads and readbacks, opened on first use. Under queueMutex_.
    VulkanCommandList& prelude();
    // A list that ignores everything, for when Vulkan could not give one (deadLists_). Under queueMutex_.
    VulkanCommandList& dead_list();
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
    // Checks a read of a region of the image: the error names `what` and the image.
    Result<void> check_texture_read(const ImageRecord& rec, std::uint32_t mip, std::uint32_t layer, int x, int y,
                                    int width, int height, const char* what) const;
    // Records the copy of a checked region into `dst` (tightly packed rows) and the host-read barrier.
    void record_texture_read(VulkanCommandList& list, const ImageRecord& rec, std::uint32_t mip, std::uint32_t layer,
                             int x, int y, int width, int height, const std::shared_ptr<TrackedResource>& dst);
    // Copies a region of the image into a host-visible buffer and waits; the rows come back tightly packed.
    Result<void> read_texture(const ImageRecord& rec, std::uint32_t mip, std::uint32_t layer, int x, int y, int width,
                              int height, std::vector<std::uint8_t>& out, const char* what);
    // GPU timers: the query pools (init), their release (the destructor).
    void init_timer();
    void destroy_timer();
    // Ends the open timed frame: its end timestamp and the prelude's submission. Under queueMutex_ and timerMutex_.
    void end_timer_frame_locked();
    // Asynchronous reads: a slot no ticket holds whose copy finished (-1 = every one is busy); whether a ticket names
    // its slot's current read; the copy recorded by `copy` on an internal list, submitted now.
    int free_async_slot() const;
    bool async_ticket_current(ReadTicket ticket) const;
    template <class Copy>
    Result<ReadTicket> start_async_read(int slot, const char* what, const Copy& copy);
    // A host-visible buffer of at least `bytes` for slot `slot` (kept while big enough).
    Result<void> async_buffer(int slot, std::uint64_t bytes, const std::string& where);
    // A descriptor set layout of `bindings` (cached by `key` while a pipeline layout holds it); null with `error` set
    // when Vulkan refused.
    std::shared_ptr<const SetLayoutObject>
    set_layout(const std::string& key, const std::vector<VkDescriptorSetLayoutBinding>& bindings, std::string& error);
    // The pipeline cache file read and checked: the VkPipelineCache's initial data (init). Empty when there is no file,
    // and when it does not match this device or is cut or corrupt (thrown away with a warning). Under cacheMutex_.
    std::vector<std::uint8_t> load_pipeline_cache_file();
    // A warning of the pipeline cache file: the log and warnings().
    void cache_warning(const std::string& message);
    // Moves the retired objects into the deferred queue (tagged with the current frame). Under queueMutex_.
    void take_retired();
    // The pipeline layout of a shader (cached by its bindings); null with `error` set when it cannot be one.
    std::shared_ptr<const PipelineLayoutInfo> pipeline_layout(const ShaderDesc& desc, const ShaderInfo& info,
                                                              std::string& error);
    // A VkPipeline from the cache, or made now; null with `error` set when Vulkan refused.
    std::shared_ptr<const PipelineObject> pipeline_object(const std::string& key,
                                                          const VkGraphicsPipelineCreateInfo* graphics,
                                                          const VkComputePipelineCreateInfo* compute,
                                                          std::string& error);

    // The Vulkan objects
    VulkanLibrary library_{};
    VkFunctions fn_{};
    VkInstance instance_ = VK_NULL_HANDLE;
    VkDebugUtilsMessengerEXT messenger_ = VK_NULL_HANDLE;
    VkPhysicalDevice physical_ = VK_NULL_HANDLE;
    VkDevice device_ = VK_NULL_HANDLE;
    VkQueue queue_ = VK_NULL_HANDLE;
    std::uint32_t queueFamily_ = 0;
    std::uint32_t timestampBits_ = 0;  // the queue family's timestampValidBits
    VkQueue transferQueue_ = VK_NULL_HANDLE;
    std::uint32_t transferFamily_ = 0;
    VkSemaphore timeline_ = VK_NULL_HANDLE;
    VkPhysicalDeviceProperties props_{};
    std::string deviceName_;
    std::uint32_t apiVersion_ = 0;
    bool cpuDevice_ = false;
    bool validation_ = false;
    bool syncValidation_ = false;
    bool debugUtils_ = false;
    bool portability_ = false;
    bool imageView2DOn3D_ = true;
    bool imageView2DOn3DReal_ = true;  // what the device has (imageView2DOn3D_ may be turned off by a test)
    bool anisotropy_ = false;
    bool descriptorIndexing_ = false;
    int framesInFlight_ = kInflightFrames;
    VkFormat depthStencilFormat_ = VK_FORMAT_D24_UNORM_S8_UINT;
    bool depthBiasClamp_ = false;
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
    Pool<ShaderRecord> shaders_;
    Pool<PipelineRecord> pipelines_;

    // The caches (cacheMutex_). The pipelines stay while a live shader has their code (codeUsers_), the layouts while
    // a shader or pipeline holds them (weak entries), the framebuffers until one of their views is destroyed; render
    // passes (one per set of attachment formats and load / store ops, a small set) for the device's life.
    mutable std::mutex cacheMutex_;
    VkPipelineCache pipelineCache_ = VK_NULL_HANDLE;
    std::unordered_map<std::string, std::weak_ptr<const SetLayoutObject>> setLayouts_;
    std::unordered_map<std::string, std::weak_ptr<const PipelineLayoutInfo>> pipelineLayouts_;
    std::unordered_map<std::string, std::shared_ptr<const PipelineObject>> pipelineObjects_;
    std::unordered_map<std::string, int> codeUsers_;  // ShaderInfo::codeKey -> live shaders with that code
    std::unordered_map<std::string, VkRenderPass> renderPasses_;
    std::unordered_map<std::string, FramebufferEntry> framebuffers_;
    std::uint64_t pipelineHits_ = 0, pipelineMisses_ = 0;
    std::uint64_t layoutHits_ = 0, layoutMisses_ = 0;
    std::uint64_t renderPassHits_ = 0, renderPassMisses_ = 0;
    std::uint64_t framebufferHits_ = 0, framebufferMisses_ = 0;
    std::uint64_t viewSerial_ = 0;  // the last ViewRecord::serial handed out (resMutex_)
    std::atomic<std::uint64_t> descriptorSetBinds_{0};

    // The pipeline cache file (cacheMutex_)
    std::filesystem::path cacheFile_;
    std::string cacheLoadedSha256_;  // of the data read at init ("" = none): a save of the same data is skipped
    bool cacheLoaded_ = false;
    bool cacheDirty_ = false;  // pipelines were made since the data was read or written
    std::uint64_t cacheFileBytes_ = 0, cacheStored_ = 0, cacheDiscarded_ = 0, cacheStoreFailed_ = 0;

    // Objects whose last holder let go, waiting to go into the deferred queue (retireMutex_: a leaf, taken under any
    // other lock, never the other way round).
    std::mutex retireMutex_;
    std::vector<Deferred> retired_;

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
    // The lists handed out when Vulkan could not give one (they ignore everything and hold no state): kept until the
    // device goes, as a caller may still hold one, and handed out again from the next frame on (deadUsed_ of them are
    // this frame's; commit() sets it to 0), so a device lost does not make one more each call.
    std::vector<std::unique_ptr<VulkanCommandList>> deadLists_;
    std::size_t deadUsed_ = 0;

    // GPU timers (timerMutex_; taken after queueMutex_ when both are held). A timed frame takes the next slot of the
    // ring: query 0 is its start, 1 its end, 2 + 2i and 3 + 2i scope i's.
    static constexpr int kTimerSlots = 6;       // timed frames in flight; a full ring skips the frame
    static constexpr int kMaxTimedScopes = 64;  // scopes measured per frame (as GpuTimer::kMaxTimedPasses)
    struct TimerSlot {
        VkQueryPool pool = VK_NULL_HANDLE;
        std::uint64_t serial = 0;  // the timed frame it holds
        std::uint64_t fence = 0;   // the timeline value after its end timestamp
        std::vector<std::string> names;
        std::vector<bool> submitted;  // scope i's list ran before timer_end_frame (else it is not reported)
    };
    mutable std::mutex timerMutex_;
    bool timerOk_ = false;
    std::string timerWhy_;
    std::array<TimerSlot, kTimerSlots> timerSlots_;
    std::deque<int> timerPending_;  // ended frames waiting for their timeline value, oldest first
    int timerCurrent_ = -1;         // the slot of the open timed frame; -1 = none
    std::uint64_t timerSerial_ = 0;
    std::uint64_t timerNext_ = 0;
    std::size_t timerStale_ = 0;  // results still to arrive that timer_forget() dropped
    std::vector<ScopeTime> timerLastScopes_;

    // Asynchronous reads (render thread only; the copy itself under queueMutex_)
    static constexpr int kAsyncReads = 32;  // as SokolDevice and the D3D12 backend
    struct AsyncRead {
        std::shared_ptr<TrackedResource> buffer;  // host-visible (MemoryUse::Readback), kept while big enough
        std::uint64_t capacity = 0;
        std::uint64_t fence = 0;       // the copy is done once the timeline reaches it
        std::uint32_t generation = 0;  // the ticket's; 0 = no ticket (free once the copy finished)
        std::size_t bytes = 0;         // the bytes handed over (tightly packed)
    };
    std::array<AsyncRead, kAsyncReads> asyncReads_;
    std::uint32_t readGeneration_ = 0;

    // Messages (msgMutex_)
    mutable std::mutex msgMutex_;
    std::vector<std::string> errors_;
    std::vector<std::string> warnings_;
    std::vector<std::string> notYetReported_;  // each call not built yet (M77-P9) is reported once

    // Statistics (resMutex_)
    bool statsEnabled_ = false;
    TotalStats stats_{};
};

// Whether a vertex stage's SPIR-V (words checked by make_shader) stores to its PointSize built-in, which Vulkan needs
// to draw a point list: a store to a variable decorated BuiltIn PointSize, to that member of gl_PerVertex or to the whole
// block. A declaration alone does not count (glslang declares the member in every vertex shader). vulkan_pipelines.cpp.
bool spirv_writes_point_size(const std::vector<std::uint32_t>& words);

}  // namespace fa::gpu::vk

#endif  // FA_VULKAN_BACKEND
