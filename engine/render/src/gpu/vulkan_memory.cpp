// The Vulkan backend's memory: the engine's own suballocator, the upload ring, the per-frame descriptor pools and the
// bindless table (docs/design/ARCHITECTURE_RENDERING_VULKAN.md).
#include "gpu/vulkan_device.h"

#if defined(FA_VULKAN_BACKEND)

#include <algorithm>
#include <string>

namespace fa::gpu::vk {

namespace {

const char* use_name(MemoryUse use) {
    switch (use) {
        case MemoryUse::GpuOnly: return "GPU-only";
        case MemoryUse::Upload: return "upload";
        case MemoryUse::Readback: return "readback";
    }
    return "?";
}

std::string hex(std::uint32_t v) {
    static const char* digits = "0123456789abcdef";
    std::string s = "0x";
    for (int shift = 28; shift >= 0; shift -= 4) s += digits[(v >> shift) & 0xFu];
    return s;
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// TrackedResource
// ---------------------------------------------------------------------------------------------------------------------

TrackedResource::~TrackedResource() {
    if (!device || !device->device_) return;
    const VkFunctions& f = device->fn_;
    if (buffer) f.vkDestroyBuffer(device->device_, buffer, nullptr);
    if (image && !external) f.vkDestroyImage(device->device_, image, nullptr);
    if (memory.ok()) device->memory_.free(memory);
}

// ---------------------------------------------------------------------------------------------------------------------
// MemoryAllocator
// ---------------------------------------------------------------------------------------------------------------------

void MemoryAllocator::init(VulkanDevice* device, const VkPhysicalDeviceMemoryProperties& properties,
                           VkDeviceSize blockBytes, VkDeviceSize dedicatedThreshold) {
    device_ = device;
    props_ = properties;
    blockBytes_ = blockBytes;
    dedicatedThreshold_ = dedicatedThreshold;
}

int MemoryAllocator::find_type(std::uint32_t typeBits, MemoryUse use) const {
    VkMemoryPropertyFlags required = 0, preferred = 0;
    switch (use) {
        case MemoryUse::GpuOnly: preferred = VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT; break;
        case MemoryUse::Upload:
            required = VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT;
            break;
        case MemoryUse::Readback:
            required = VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT;
            preferred = VK_MEMORY_PROPERTY_HOST_CACHED_BIT;
            break;
    }
    for (int pass = 0; pass < 2; ++pass) {
        const VkMemoryPropertyFlags want = pass == 0 ? (required | preferred) : required;
        for (std::uint32_t i = 0; i < props_.memoryTypeCount && i < VK_MAX_MEMORY_TYPES; ++i)
            if ((typeBits & (1u << i)) && (props_.memoryTypes[i].propertyFlags & want) == want) return int(i);
    }
    return -1;
}

Result<VkDeviceMemory> MemoryAllocator::allocate_memory(VkDeviceSize size, std::uint32_t type, std::uint8_t** mapped) {
    const VkFunctions& f = device_->fn();
    VkMemoryAllocateInfo ai{};
    ai.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
    ai.allocationSize = size;
    ai.memoryTypeIndex = type;
    VkDeviceMemory memory = VK_NULL_HANDLE;
    VkResult r = f.vkAllocateMemory(device_->vk_device(), &ai, nullptr, &memory);
    if (r != VK_SUCCESS)
        return make_error("gpu vulkan: vkAllocateMemory (" + std::to_string(size) + " bytes, memory type " +
                              std::to_string(type) + ") failed with " + result_text(r),
                          r == VK_ERROR_OUT_OF_DEVICE_MEMORY || r == VK_ERROR_OUT_OF_HOST_MEMORY
                              ? "the GPU is out of memory: free resources or make them smaller"
                              : "the device was lost or the driver refused the allocation");
    if (mapped) {
        void* p = nullptr;
        r = f.vkMapMemory(device_->vk_device(), memory, 0, VK_WHOLE_SIZE, 0, &p);
        if (r != VK_SUCCESS || !p) {
            f.vkFreeMemory(device_->vk_device(), memory, nullptr);
            return make_error("gpu vulkan: vkMapMemory (" + std::to_string(size) + " bytes) failed with " +
                                  result_text(r),
                              "the process ran out of address space or the device was lost");
        }
        *mapped = static_cast<std::uint8_t*>(p);
    }
    return memory;
}

void MemoryAllocator::free_memory(VkDeviceMemory memory, VkDeviceSize, bool mapped) {
    const VkFunctions& f = device_->fn();
    if (mapped) f.vkUnmapMemory(device_->vk_device(), memory);
    f.vkFreeMemory(device_->vk_device(), memory, nullptr);
}

Result<Allocation> MemoryAllocator::alloc(const VkMemoryRequirements& req, MemoryUse use, bool linear, bool dedicated) {
    const int type = find_type(req.memoryTypeBits, use);
    if (type < 0)
        return make_error("gpu vulkan: no memory type of " + device_->device_name() + " fits a " + use_name(use) +
                              " resource (memoryTypeBits " + hex(req.memoryTypeBits) + ")",
                          "the driver offers no host-visible memory for this resource: report the device");
    const VkMemoryPropertyFlags flags = props_.memoryTypes[type].propertyFlags;
    const bool host = (flags & VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) != 0;
    const VkDeviceSize alignment = req.alignment > 0 ? req.alignment : 1;
    Allocation a;
    a.memoryType = std::uint32_t(type);
    a.coherent = (flags & VK_MEMORY_PROPERTY_HOST_COHERENT_BIT) != 0;
    a.size = req.size;

    if (dedicated || req.size >= dedicatedThreshold_ || req.size > blockBytes_) {
        std::uint8_t* mapped = nullptr;
        auto m = allocate_memory(req.size, std::uint32_t(type), host ? &mapped : nullptr);
        if (!m) return m.error();
        a.memory = m.value();
        a.offset = 0;
        a.mapped = mapped;
        std::lock_guard<std::mutex> lock(mutex_);
        ++counters_.dedicatedAllocations;
        ++counters_.liveAllocations;
        counters_.bytesAllocated += req.size;
        counters_.bytesInUse += req.size;
        return a;
    }

    std::lock_guard<std::mutex> lock(mutex_);
    int poolIndex = -1;
    for (std::size_t i = 0; i < pools_.size(); ++i)
        if (pools_[i].type == std::uint32_t(type) && pools_[i].linear == linear) poolIndex = int(i);
    if (poolIndex < 0) {
        BlockPool p;
        p.type = std::uint32_t(type);
        p.linear = linear;
        pools_.push_back(std::move(p));
        poolIndex = int(pools_.size() - 1);
    }
    BlockPool& pool = pools_[std::size_t(poolIndex)];
    // First fit: the first free range of any block that holds the aligned size.
    auto carve = [&](Block& b, int blockIndex) -> bool {
        for (std::size_t i = 0; i < b.free.size(); ++i) {
            const VkDeviceSize off = b.free[i].first, sz = b.free[i].second;
            const VkDeviceSize start = align_up(off, alignment);
            if (start + req.size > off + sz) continue;
            const VkDeviceSize before = start - off, after = off + sz - (start + req.size);
            b.free.erase(b.free.begin() + std::ptrdiff_t(i));
            if (after > 0) b.free.insert(b.free.begin() + std::ptrdiff_t(i), {start + req.size, after});
            if (before > 0) b.free.insert(b.free.begin() + std::ptrdiff_t(i), {off, before});
            ++b.live;
            a.memory = b.memory;
            a.offset = start;
            a.mapped = b.mapped ? b.mapped + start : nullptr;
            a.pool = poolIndex;
            a.block = blockIndex;
            return true;
        }
        return false;
    };
    bool placed = false;
    for (std::size_t i = 0; i < pool.blocks.size() && !placed; ++i)
        if (pool.blocks[i]) placed = carve(*pool.blocks[i], int(i));
    if (!placed) {
        std::uint8_t* mapped = nullptr;
        auto m = allocate_memory(blockBytes_, std::uint32_t(type), host ? &mapped : nullptr);
        if (!m) return m.error();
        auto b = std::make_unique<Block>();
        b->memory = m.value();
        b->size = blockBytes_;
        b->mapped = mapped;
        b->free.push_back({0, blockBytes_});
        int index = -1;
        for (std::size_t i = 0; i < pool.blocks.size(); ++i)
            if (!pool.blocks[i]) {
                index = int(i);
                break;
            }
        if (index < 0) {
            pool.blocks.push_back(nullptr);
            index = int(pool.blocks.size() - 1);
        }
        pool.blocks[std::size_t(index)] = std::move(b);
        ++counters_.blocks;
        counters_.bytesAllocated += blockBytes_;
        placed = carve(*pool.blocks[std::size_t(index)], index);
    }
    if (!placed)  // cannot happen: the size fits an empty block
        return make_error("gpu vulkan: the memory suballocator could not place " + std::to_string(req.size) +
                              " bytes in a new block of " + std::to_string(blockBytes_),
                          "raise VulkanOptions::memoryBlockBytes");
    ++counters_.liveAllocations;
    counters_.bytesInUse += req.size;
    return a;
}

void MemoryAllocator::free(Allocation& a) {
    if (!a.ok() || !device_) return;
    if (a.pool < 0) {
        free_memory(a.memory, a.size, a.mapped != nullptr);
        std::lock_guard<std::mutex> lock(mutex_);
        --counters_.dedicatedAllocations;
        --counters_.liveAllocations;
        counters_.bytesAllocated -= a.size;
        counters_.bytesInUse -= a.size;
        a = Allocation{};
        return;
    }
    std::lock_guard<std::mutex> lock(mutex_);
    if (std::size_t(a.pool) >= pools_.size()) return;
    BlockPool& pool = pools_[std::size_t(a.pool)];
    if (a.block < 0 || std::size_t(a.block) >= pool.blocks.size() || !pool.blocks[std::size_t(a.block)]) return;
    Block& b = *pool.blocks[std::size_t(a.block)];
    // Back into the sorted free list, merged with its neighbours.
    auto it = std::lower_bound(b.free.begin(), b.free.end(), std::make_pair(a.offset, VkDeviceSize(0)));
    it = b.free.insert(it, {a.offset, a.size});
    if (it + 1 != b.free.end() && it->first + it->second == (it + 1)->first) {
        it->second += (it + 1)->second;
        b.free.erase(it + 1);
    }
    if (it != b.free.begin() && (it - 1)->first + (it - 1)->second == it->first) {
        (it - 1)->second += it->second;
        b.free.erase(it);
    }
    --b.live;
    --counters_.liveAllocations;
    counters_.bytesInUse -= a.size;
    if (b.live == 0) {
        // An empty block goes back to the driver unless it is the pool's only one (the next resource reuses it).
        int others = 0;
        for (const auto& other : pool.blocks)
            if (other && other.get() != &b) ++others;
        if (others > 0) {
            free_memory(b.memory, b.size, b.mapped != nullptr);
            --counters_.blocks;
            counters_.bytesAllocated -= b.size;
            pool.blocks[std::size_t(a.block)].reset();
        }
    }
    a = Allocation{};
}

void MemoryAllocator::destroy() {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!device_) return;
    for (BlockPool& p : pools_)
        for (auto& b : p.blocks)
            if (b) free_memory(b->memory, b->size, b->mapped != nullptr);
    pools_.clear();
    counters_.blocks = 0;
}

MemoryCounters MemoryAllocator::counters() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return counters_;
}

// ---------------------------------------------------------------------------------------------------------------------
// UploadRing
// ---------------------------------------------------------------------------------------------------------------------

void UploadRing::init(VkBuffer buffer, std::uint8_t* cpu, std::size_t bytes) {
    std::lock_guard<std::mutex> lock(mutex_);
    buffer_ = buffer;
    cpu_ = cpu;
    size_ = bytes;
    head_ = tail_ = wraps_ = 0;
    frames_.clear();
}

bool UploadRing::alloc(std::size_t size, std::size_t align, UploadAlloc& out) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!buffer_ || !cpu_ || size == 0 || size > size_ || align == 0) return false;
    const std::uint64_t ring = size_;
    const std::uint64_t pos = head_ % ring;
    std::uint64_t start = head_ + ((align - pos % align) % align);
    if (start % ring + size > ring || start % ring < pos) {
        // No room before the end (or the alignment ran past it): start again at the ring's beginning.
        start = head_ + (ring - pos);
        if (start + size - tail_ > ring) return false;
        ++wraps_;
    }
    if (start + size - tail_ > ring) return false;
    head_ = start + size;
    out.buffer = buffer_;
    out.offset = start % ring;
    out.cpu = cpu_ + out.offset;
    return true;
}

void UploadRing::end_frame(std::uint64_t frame) {
    std::lock_guard<std::mutex> lock(mutex_);
    frames_.emplace_back(frame, head_);
}

void UploadRing::frame_done(std::uint64_t frame) {
    std::lock_guard<std::mutex> lock(mutex_);
    while (!frames_.empty() && frames_.front().first <= frame) {
        tail_ = frames_.front().second;
        frames_.pop_front();
    }
}

std::uint64_t UploadRing::wraps() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return wraps_;
}

std::size_t UploadRing::in_use() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return std::size_t(head_ - tail_);
}

// ---------------------------------------------------------------------------------------------------------------------
// DescriptorPools
// ---------------------------------------------------------------------------------------------------------------------

namespace {

const VkDescriptorType kKindTypes[kDescKinds] = {
    VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE,          VK_DESCRIPTOR_TYPE_SAMPLER,
    VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,          VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
    VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
};
const char* const kKindNames[kDescKinds] = {
    "sampled image", "sampler", "storage image", "storage buffer", "dynamic uniform buffer", "combined image-sampler",
};

// The bindless table's layout: `count` sampled images in binding 0, partially bound and updated after bind. The
// pointers of `li` point into this struct, so it is filled in place and never copied.
struct BindlessLayout {
    VkDescriptorSetLayoutBinding binding{};
    VkDescriptorBindingFlags bindingFlags = 0;
    VkDescriptorSetLayoutBindingFlagsCreateInfo flagsInfo{};
    VkDescriptorSetLayoutCreateInfo li{};

    explicit BindlessLayout(std::uint32_t count) {
        binding.binding = 0;
        binding.descriptorType = VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
        binding.descriptorCount = count;
        binding.stageFlags = VK_SHADER_STAGE_ALL;
        bindingFlags = VK_DESCRIPTOR_BINDING_PARTIALLY_BOUND_BIT | VK_DESCRIPTOR_BINDING_UPDATE_AFTER_BIND_BIT;
        flagsInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_BINDING_FLAGS_CREATE_INFO;
        flagsInfo.bindingCount = 1;
        flagsInfo.pBindingFlags = &bindingFlags;
        li.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
        li.pNext = &flagsInfo;
        li.flags = VK_DESCRIPTOR_SET_LAYOUT_CREATE_UPDATE_AFTER_BIND_POOL_BIT;
        li.bindingCount = 1;
        li.pBindings = &binding;
    }
    BindlessLayout(const BindlessLayout&) = delete;
    BindlessLayout& operator=(const BindlessLayout&) = delete;
};

}  // namespace

bool DescriptorPools::bindless_supported(const VulkanDevice& device, std::uint32_t count) {
    const BindlessLayout layout(count);
    VkDescriptorSetLayoutSupport support{};
    support.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_SUPPORT;
    device.fn().vkGetDescriptorSetLayoutSupport(device.vk_device(), &layout.li, &support);
    return support.supported == VK_TRUE;
}

Result<VkDescriptorPool> DescriptorPools::make_pool() const {
    VkDescriptorPoolSize sizes[kDescKinds]{};
    for (int k = 0; k < kDescKinds; ++k) sizes[k] = {kKindTypes[k], perKind_};
    VkDescriptorPoolCreateInfo ci{};
    ci.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
    ci.maxSets = maxSets_;
    ci.poolSizeCount = kDescKinds;
    ci.pPoolSizes = sizes;
    VkDescriptorPool pool = VK_NULL_HANDLE;
    const VkResult r = device_->fn().vkCreateDescriptorPool(device_->vk_device(), &ci, nullptr, &pool);
    if (r != VK_SUCCESS)
        return make_error("gpu vulkan: vkCreateDescriptorPool (" + std::to_string(maxSets_) + " sets, " +
                              std::to_string(perKind_) + " descriptors of each kind) failed with " + result_text(r),
                          "lower VulkanOptions::frameDescriptorSets or frameDescriptors");
    device_->set_name(VK_OBJECT_TYPE_DESCRIPTOR_POOL, handle_bits(pool), "fa-vulkan-frame-descriptors");
    return pool;
}

Result<void> DescriptorPools::init(VulkanDevice& device, int frames, std::uint32_t sets, std::uint32_t perKind,
                                   std::uint32_t chain, std::uint32_t bindless) {
    std::lock_guard<std::mutex> lock(mutex_);
    device_ = &device;
    const VkFunctions& f = device.fn();
    const VkDevice dev = device.vk_device();
    maxSets_ = sets;
    perKind_ = perKind;
    chain_ = std::max<std::uint32_t>(1u, chain);
    // Each frame slot starts with one pool; a frame that fills it takes the next of its chain (made then, kept for the
    // frames after), up to `chain` pools.
    pools_.assign(std::size_t(frames), {});
    for (int i = 0; i < frames; ++i) {
        auto pool = make_pool();
        if (!pool) return pool.error();
        pools_[std::size_t(i)].push_back(FramePool{*pool, 0, {}});
    }
    if (bindless == 0) return {};

    const BindlessLayout layout(bindless);
    VkResult r = f.vkCreateDescriptorSetLayout(dev, &layout.li, nullptr, &bindlessLayout_);
    if (r != VK_SUCCESS)
        return make_error("gpu vulkan: vkCreateDescriptorSetLayout (the bindless table, " + std::to_string(bindless) +
                              " sampled images) failed with " + result_text(r),
                          "lower VulkanOptions::bindlessDescriptors (0 = no bindless table)");
    const VkDescriptorPoolSize size{VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE, bindless};
    VkDescriptorPoolCreateInfo pi{};
    pi.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
    pi.flags = VK_DESCRIPTOR_POOL_CREATE_UPDATE_AFTER_BIND_BIT;
    pi.maxSets = 1;
    pi.poolSizeCount = 1;
    pi.pPoolSizes = &size;
    r = f.vkCreateDescriptorPool(dev, &pi, nullptr, &bindlessPool_);
    if (r != VK_SUCCESS)
        return make_error("gpu vulkan: vkCreateDescriptorPool (the bindless table, " + std::to_string(bindless) +
                              " sampled images) failed with " + result_text(r),
                          "lower VulkanOptions::bindlessDescriptors (0 = no bindless table)");
    VkDescriptorSetAllocateInfo ai{};
    ai.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
    ai.descriptorPool = bindlessPool_;
    ai.descriptorSetCount = 1;
    ai.pSetLayouts = &bindlessLayout_;
    r = f.vkAllocateDescriptorSets(dev, &ai, &bindlessSet_);
    if (r != VK_SUCCESS)
        return make_error("gpu vulkan: vkAllocateDescriptorSets (the bindless table) failed with " + result_text(r),
                          "lower VulkanOptions::bindlessDescriptors (0 = no bindless table)");
    device.set_name(VK_OBJECT_TYPE_DESCRIPTOR_SET, handle_bits(bindlessSet_), "fa-vulkan-bindless");
    bindlessCapacity_ = bindless;
    return {};
}

void DescriptorPools::destroy() {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!device_) return;
    const VkFunctions& f = device_->fn();
    const VkDevice dev = device_->vk_device();
    for (const auto& chain : pools_)
        for (const FramePool& p : chain) f.vkDestroyDescriptorPool(dev, p.pool, nullptr);
    pools_.clear();
    active_ = 0;
    if (bindlessPool_) f.vkDestroyDescriptorPool(dev, bindlessPool_, nullptr);  // frees the set
    if (bindlessLayout_) f.vkDestroyDescriptorSetLayout(dev, bindlessLayout_, nullptr);
    bindlessPool_ = VK_NULL_HANDLE;
    bindlessLayout_ = VK_NULL_HANDLE;
    bindlessSet_ = VK_NULL_HANDLE;
    bindlessCapacity_ = 0;
    bindlessNext_ = 0;
    bindlessFree_.clear();
    device_ = nullptr;
}

Result<VkDescriptorSet> DescriptorPools::alloc(VkDescriptorSetLayout layout, const DescriptorCounts& counts) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!device_ || pools_.empty() || pools_[std::size_t(slot_)].empty())
        return make_error("gpu vulkan: the descriptor pools are not made", "make the device with make_vulkan_device");
    // A set larger than a whole pool never fits, whatever the chain.
    for (int k = 0; k < kDescKinds; ++k)
        if (counts.n[std::size_t(k)] > perKind_)
            return make_error("gpu vulkan: a descriptor set needs " + std::to_string(counts.n[std::size_t(k)]) + " " +
                                  kKindNames[k] + " descriptors, more than one descriptor pool holds (" +
                                  "VulkanOptions::frameDescriptors = " + std::to_string(perKind_) + ")",
                              "raise VulkanOptions::frameDescriptors, or give the shader fewer views");
    std::vector<FramePool>& chain = pools_[std::size_t(slot_)];
    auto fits = [&](const FramePool& p) {
        if (p.setsUsed >= maxSets_) return false;
        for (int k = 0; k < kDescKinds; ++k)
            if (std::uint64_t(p.used.n[std::size_t(k)]) + counts.n[std::size_t(k)] > perKind_) return false;
        return true;
    };
    while (!fits(chain[active_])) {
        if (active_ + 1 >= chain_) {
            // The whole chain is full: say what ran out in the last pool.
            const FramePool& p = chain[active_];
            const std::string pools = std::to_string(chain_) + " pool" + (chain_ == 1 ? "" : "s") +
                                      " (VulkanOptions::frameDescriptorPools = " + std::to_string(chain_) + ")";
            if (p.setsUsed >= maxSets_)
                return make_error("gpu vulkan: this frame's descriptor pools have no set left (VulkanOptions::"
                                  "frameDescriptorSets = " +
                                      std::to_string(maxSets_) + " in each of " + pools +
                                      ", every one taken this "
                                      "frame)",
                                  "raise VulkanOptions::frameDescriptorSets or frameDescriptorPools, or bind fewer "
                                  "descriptor sets in one frame");
            for (int k = 0; k < kDescKinds; ++k)
                if (std::uint64_t(p.used.n[std::size_t(k)]) + counts.n[std::size_t(k)] > perKind_)
                    return make_error("gpu vulkan: this frame's descriptor pools have no room for " +
                                          std::to_string(counts.n[std::size_t(k)]) + " more " + kKindNames[k] +
                                          " descriptor(s) (" + std::to_string(p.used.n[std::size_t(k)]) +
                                          " of VulkanOptions::frameDescriptors = " + std::to_string(perKind_) +
                                          " taken in the last of " + pools + " this frame)",
                                      "raise VulkanOptions::frameDescriptors or frameDescriptorPools, or bind fewer "
                                      "descriptors in one frame");
        }
        ++active_;
        if (active_ == chain.size()) {
            auto pool = make_pool();
            if (!pool) {
                --active_;
                return pool.error();
            }
            chain.push_back(FramePool{*pool, 0, {}});
        }
    }
    FramePool& p = chain[active_];
    VkDescriptorSetAllocateInfo ai{};
    ai.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
    ai.descriptorPool = p.pool;
    ai.descriptorSetCount = 1;
    ai.pSetLayouts = &layout;
    VkDescriptorSet set = VK_NULL_HANDLE;
    const VkResult r = device_->fn().vkAllocateDescriptorSets(device_->vk_device(), &ai, &set);
    if (r != VK_SUCCESS)
        return make_error("gpu vulkan: vkAllocateDescriptorSets (frame slot " + std::to_string(slot_) + ", pool " +
                              std::to_string(active_) + ") failed with " + result_text(r),
                          "raise VulkanOptions::frameDescriptorSets or frameDescriptors");
    ++p.setsUsed;
    for (int k = 0; k < kDescKinds; ++k) p.used.n[std::size_t(k)] += counts.n[std::size_t(k)];
    return set;
}

void DescriptorPools::begin_frame(int slot) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!device_ || slot < 0 || std::size_t(slot) >= pools_.size()) return;
    slot_ = slot;
    active_ = 0;
    // The GPU finished the frame that used this slot's chain last: every pool it took is empty again.
    for (FramePool& p : pools_[std::size_t(slot)]) {
        if (p.setsUsed > 0) device_->fn().vkResetDescriptorPool(device_->vk_device(), p.pool, 0);
        p.setsUsed = 0;
        p.used = DescriptorCounts{};
    }
}

std::uint32_t DescriptorPools::frame_sets_used() const {
    std::lock_guard<std::mutex> lock(mutex_);
    std::uint32_t n = 0;
    if (std::size_t(slot_) < pools_.size())
        for (const FramePool& p : pools_[std::size_t(slot_)]) n += p.setsUsed;
    return n;
}

std::uint32_t DescriptorPools::frame_descriptors_used() const {
    std::lock_guard<std::mutex> lock(mutex_);
    std::uint32_t n = 0;
    if (std::size_t(slot_) < pools_.size())
        for (const FramePool& p : pools_[std::size_t(slot_)])
            for (std::uint32_t v : p.used.n) n += v;
    return n;
}

std::uint32_t DescriptorPools::frame_pools_used() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return pools_.empty() ? 0u : std::uint32_t(active_ + 1);
}

std::uint32_t DescriptorPools::bindless_alloc() {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!bindlessFree_.empty()) {
        const std::uint32_t slot = bindlessFree_.back();
        bindlessFree_.pop_back();
        return slot;
    }
    if (bindlessNext_ >= bindlessCapacity_) return kNoSlot;
    return bindlessNext_++;
}

void DescriptorPools::bindless_free(std::uint32_t slot) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (slot >= bindlessNext_) return;
    if (std::find(bindlessFree_.begin(), bindlessFree_.end(), slot) != bindlessFree_.end()) return;
    bindlessFree_.push_back(slot);
}

void DescriptorPools::bindless_write(std::uint32_t slot, VkImageView view, VkImageLayout layout) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!device_ || !bindlessSet_ || slot >= bindlessCapacity_) return;
    VkDescriptorImageInfo ii{};
    ii.imageView = view;
    ii.imageLayout = layout;
    VkWriteDescriptorSet w{};
    w.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
    w.dstSet = bindlessSet_;
    w.dstBinding = 0;
    w.dstArrayElement = slot;
    w.descriptorCount = 1;
    w.descriptorType = VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
    w.pImageInfo = &ii;
    device_->fn().vkUpdateDescriptorSets(device_->vk_device(), 1, &w, 0, nullptr);
}

std::uint32_t DescriptorPools::bindless_used() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return bindlessNext_ - std::uint32_t(bindlessFree_.size());
}

}  // namespace fa::gpu::vk

#endif  // FA_VULKAN_BACKEND
