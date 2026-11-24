// The Vulkan backend's command lists: opening and reusing them, layout and access tracking with automatic barriers, the
// transfers (write_buffer, write_image, the copies) and debug labels (docs/design/ARCHITECTURE_RENDERING_GPU.md,
// "Vulkan backend"). Passes, pipelines, bindings, uniforms, draws and dispatches come in M77-P8c.
#include "gpu/vulkan_device.h"

#if defined(FA_VULKAN_BACKEND)

#include <algorithm>
#include <cstring>
#include <memory>
#include <string>
#include <utility>
#include <vector>

namespace fa::gpu::vk {

namespace {

// The rest of a level from `at` when `size` is 0 (sokol's ImageExtent rule).
std::uint32_t extent_or_rest(int size, int at, std::uint32_t level) {
    if (size > 0) return std::uint32_t(size);
    return at < 0 || std::uint32_t(at) >= level ? 0u : level - std::uint32_t(at);
}

constexpr SubState kUnused{kUnknownLayout, 0, 0};

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// Life
// ---------------------------------------------------------------------------------------------------------------------

VulkanCommandList::~VulkanCommandList() {
    if (pool_) device_.fn_.vkDestroyCommandPool(device_.device_, pool_, nullptr);  // frees its command buffers
}

Result<void> VulkanCommandList::create(const char* what) {
    const VkFunctions& f = device_.fn_;
    VkCommandPoolCreateInfo pi{};
    pi.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
    pi.flags = VK_COMMAND_POOL_CREATE_TRANSIENT_BIT;
    pi.queueFamilyIndex = device_.queueFamily_;
    VkResult r = f.vkCreateCommandPool(device_.device_, &pi, nullptr, &pool_);
    if (r != VK_SUCCESS) {
        pool_ = VK_NULL_HANDLE;
        return make_error(std::string("gpu vulkan: begin_commands('") + what + "'): vkCreateCommandPool failed with " +
                              result_text(r),
                          "the GPU ran out of memory or the device was lost");
    }
    VkCommandBufferAllocateInfo ai{};
    ai.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
    ai.commandPool = pool_;
    ai.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    ai.commandBufferCount = 2;
    VkCommandBuffer cmds[2] = {};
    r = f.vkAllocateCommandBuffers(device_.device_, &ai, cmds);
    if (r != VK_SUCCESS)
        return make_error(std::string("gpu vulkan: begin_commands('") + what +
                              "'): vkAllocateCommandBuffers failed with " + result_text(r),
                          "the GPU ran out of memory or the device was lost");
    cmd_ = cmds[0];
    fixup_ = cmds[1];
    device_.set_name(VK_OBJECT_TYPE_COMMAND_BUFFER, handle_bits(fixup_), "fa-vulkan-fixup");
    return {};
}

Result<void> VulkanCommandList::open(const char* label) {
    const VkFunctions& f = device_.fn_;
    VkResult r = f.vkResetCommandPool(device_.device_, pool_, 0);
    if (r == VK_SUCCESS) {
        VkCommandBufferBeginInfo bi{};
        bi.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
        bi.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
        r = f.vkBeginCommandBuffer(cmd_, &bi);
    }
    if (r != VK_SUCCESS)
        return make_error(std::string("gpu vulkan: begin_commands('") + label +
                              "'): resetting a command list failed with " + result_text(r),
                          "the device was lost; the validation layer (VulkanOptions::validation) says why");
    label_ = label;
    if (!label_.empty()) device_.set_name(VK_OBJECT_TYPE_COMMAND_BUFFER, handle_bits(cmd_), label);
    open_ = true;
    internal_ = false;
    empty_ = true;
    debugDepth_ = 0;
    uses_.clear();
    useIndex_.clear();
    pending_.clear();
    keep_.clear();
    return {};
}

// A call on a list that is not recording: report it (the dead list of a failed begin_commands() was reported then).
#define FA_VK_REQUIRE_OPEN(what)                                                                                       \
    do {                                                                                                               \
        if (!open_ || !cmd_) {                                                                                         \
            if (cmd_)                                                                                                  \
                device_.report(std::string("gpu vulkan: CommandList::") + what + " on list '" + label_ +               \
                               "', which was submitted (hint: take a new list with begin_commands() each frame)");     \
            return;                                                                                                    \
        }                                                                                                              \
    } while (false)

void VulkanCommandList::not_yet(const char* what) {
    device_.report_once(what, std::string("gpu vulkan: CommandList::") + what +
                                  " is not built yet (M77-P8c) (hint: the Vulkan backend records transfers and debug "
                                  "groups for now; draw with the sokol backend until M77-P8c)");
}

void VulkanCommandList::begin_pass(const PassDesc&) { not_yet("begin_pass"); }
void VulkanCommandList::begin_compute_pass(const char*) { not_yet("begin_compute_pass"); }
void VulkanCommandList::end_pass() { not_yet("end_pass"); }
void VulkanCommandList::set_pipeline(Pipeline) { not_yet("set_pipeline"); }
void VulkanCommandList::set_bindings(const Bindings&) { not_yet("set_bindings"); }
void VulkanCommandList::set_uniforms(int, Range) { not_yet("set_uniforms"); }
void VulkanCommandList::set_viewport(int, int, int, int, bool) { not_yet("set_viewport"); }
void VulkanCommandList::set_viewport_f(float, float, float, float, bool) { not_yet("set_viewport_f"); }
void VulkanCommandList::set_scissor(int, int, int, int, bool) { not_yet("set_scissor"); }
void VulkanCommandList::draw(int, int, int) { not_yet("draw"); }
void VulkanCommandList::draw_ex(int, int, int, int, int) { not_yet("draw_ex"); }
void VulkanCommandList::dispatch(int, int, int) { not_yet("dispatch"); }
// The device cannot time yet (timer_supported() is false): a timed scope does nothing, as the interface says.
void VulkanCommandList::begin_timed_scope(const char*) {}
void VulkanCommandList::end_timed_scope() {}

// ---------------------------------------------------------------------------------------------------------------------
// States and barriers
// ---------------------------------------------------------------------------------------------------------------------

void VulkanCommandList::transition(Use& u, std::uint32_t sub, const SubState& want) {
    SubState& cur = u.current[sub];
    if (cur.layout == kUnknownLayout) {
        // First use in this list: submit() moves the resource from the queue's state to this one (fix-up barriers).
        u.first[sub] = want;
        cur = want;
        return;
    }
    if (cur.layout == want.layout && !access_writes(cur.access) && !access_writes(want.access)) {
        // Read after read in the same layout: no barrier; the next write waits for every stage that read.
        const bool untouched = u.first[sub] == cur;  // no barrier yet: the list's first reads grow too
        cur.stages |= want.stages;
        cur.access |= want.access;
        if (untouched) u.first[sub] = cur;
        return;
    }
    const TrackedResource& t = *u.res;
    Barrier b;
    b.buffer = t.buffer;
    b.image = t.image;
    b.aspects = t.aspects;
    b.mip = sub % t.mips;
    b.layer = sub / t.mips;
    b.from = cur;
    b.to = want;
    pending_.push_back(b);
    cur = want;
}

void VulkanCommandList::require(const std::shared_ptr<TrackedResource>& t, std::uint32_t sub, const SubState& state) {
    if (!t) return;
    auto [it, added] = useIndex_.try_emplace(t.get(), uses_.size());
    if (added) {
        Use u;
        u.res = t;
        u.first.assign(t->subresource_count(), kUnused);
        u.current.assign(t->subresource_count(), kUnused);
        uses_.push_back(std::move(u));
    }
    Use& u = uses_[it->second];
    if (sub == kAllSubresources) {
        for (std::uint32_t s = 0; s < t->subresource_count(); ++s) transition(u, s, state);
    } else if (sub < t->subresource_count()) {
        transition(u, sub, state);
    }
}

void VulkanCommandList::require_range(const std::shared_ptr<TrackedResource>& t, std::uint32_t mip,
                                      std::uint32_t mipCount, std::uint32_t layer, std::uint32_t layerCount,
                                      const SubState& state) {
    if (!t) return;
    for (std::uint32_t l = layer; l < layer + layerCount && l < t->layers; ++l)
        for (std::uint32_t m = mip; m < mip + mipCount && m < t->mips; ++m) require(t, t->subresource(m, l), state);
}

void VulkanCommandList::flush_barriers() {
    if (pending_.empty() || !cmd_) return;
    device_.record_barriers(cmd_, pending_);
    pending_.clear();
}

void VulkanCommandList::keep_until_done(std::shared_ptr<TrackedResource> r) { keep_.push_back(std::move(r)); }

void VulkanDevice::record_barriers(VkCommandBuffer cmd, std::vector<Barrier>& barriers) {
    if (barriers.empty()) return;
    // Merge the barriers of one image that go the same way: adjacent mips first, then adjacent layers of equal mip
    // ranges (require() walks mips inside layers, so a whole image becomes one barrier).
    auto same = [](const Barrier& a, const Barrier& b) {
        return a.image && a.image == b.image && a.aspects == b.aspects && a.from == b.from && a.to == b.to;
    };
    std::vector<Barrier> mips;
    for (const Barrier& b : barriers) {
        if (!mips.empty()) {
            Barrier& last = mips.back();
            if (same(last, b) && last.layer == b.layer && last.layerCount == b.layerCount &&
                last.mip + last.mipCount == b.mip) {
                last.mipCount += b.mipCount;
                continue;
            }
        }
        mips.push_back(b);
    }
    std::vector<Barrier> merged;
    for (const Barrier& b : mips) {
        if (!merged.empty()) {
            Barrier& last = merged.back();
            if (same(last, b) && last.mip == b.mip && last.mipCount == b.mipCount &&
                last.layer + last.layerCount == b.layer) {
                last.layerCount += b.layerCount;
                continue;
            }
        }
        merged.push_back(b);
    }

    if (fn_.vkCmdPipelineBarrier2) {
        std::vector<VkImageMemoryBarrier2> images;
        std::vector<VkBufferMemoryBarrier2> buffers;
        for (const Barrier& b : merged) {
            if (b.image) {
                VkImageMemoryBarrier2 x{};
                x.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER_2;
                x.srcStageMask = b.from.stages;
                x.srcAccessMask = b.from.access;
                x.dstStageMask = b.to.stages;
                x.dstAccessMask = b.to.access;
                x.oldLayout = b.from.layout;
                x.newLayout = b.to.layout;
                x.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
                x.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
                x.image = b.image;
                x.subresourceRange = {b.aspects, b.mip, b.mipCount, b.layer, b.layerCount};
                images.push_back(x);
            } else {
                VkBufferMemoryBarrier2 x{};
                x.sType = VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER_2;
                x.srcStageMask = b.from.stages;
                x.srcAccessMask = b.from.access;
                x.dstStageMask = b.to.stages;
                x.dstAccessMask = b.to.access;
                x.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
                x.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
                x.buffer = b.buffer;
                x.offset = 0;
                x.size = VK_WHOLE_SIZE;
                buffers.push_back(x);
            }
        }
        VkDependencyInfo di{};
        di.sType = VK_STRUCTURE_TYPE_DEPENDENCY_INFO;
        di.bufferMemoryBarrierCount = std::uint32_t(buffers.size());
        di.pBufferMemoryBarriers = buffers.data();
        di.imageMemoryBarrierCount = std::uint32_t(images.size());
        di.pImageMemoryBarriers = images.data();
        fn_.vkCmdPipelineBarrier2(cmd, &di);
    } else {
        // Vulkan 1.0: one stage mask for every barrier; the stage and access bits used here all fit in 32 bits.
        VkPipelineStageFlags src = 0, dst = 0;
        std::vector<VkImageMemoryBarrier> images;
        std::vector<VkBufferMemoryBarrier> buffers;
        for (const Barrier& b : merged) {
            src |= VkPipelineStageFlags(b.from.stages & 0xFFFFFFFFull);
            dst |= VkPipelineStageFlags(b.to.stages & 0xFFFFFFFFull);
            const auto srcAccess = VkAccessFlags(b.from.access & 0xFFFFFFFFull);
            const auto dstAccess = VkAccessFlags(b.to.access & 0xFFFFFFFFull);
            if (b.image) {
                VkImageMemoryBarrier x{};
                x.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
                x.srcAccessMask = srcAccess;
                x.dstAccessMask = dstAccess;
                x.oldLayout = b.from.layout;
                x.newLayout = b.to.layout;
                x.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
                x.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
                x.image = b.image;
                x.subresourceRange = {b.aspects, b.mip, b.mipCount, b.layer, b.layerCount};
                images.push_back(x);
            } else {
                VkBufferMemoryBarrier x{};
                x.sType = VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER;
                x.srcAccessMask = srcAccess;
                x.dstAccessMask = dstAccess;
                x.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
                x.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
                x.buffer = b.buffer;
                x.offset = 0;
                x.size = VK_WHOLE_SIZE;
                buffers.push_back(x);
            }
        }
        if (src == 0) src = VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;
        if (dst == 0) dst = VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT;
        fn_.vkCmdPipelineBarrier(cmd, src, dst, 0, 0, nullptr, std::uint32_t(buffers.size()), buffers.data(),
                                 std::uint32_t(images.size()), images.data());
    }
    barriers_ += merged.size();
}

// ---------------------------------------------------------------------------------------------------------------------
// Transfers
// ---------------------------------------------------------------------------------------------------------------------

void VulkanCommandList::write_buffer(const BufferWrite& w) {
    FA_VK_REQUIRE_OPEN("write_buffer");
    std::size_t bufferSize = 0;
    std::string label;
    std::shared_ptr<TrackedResource> t = device_.buffer_tracked(w.buffer, &bufferSize, &label);
    const std::size_t size = w.size > 0 ? w.size : (w.data.size > w.srcOffset ? w.data.size - w.srcOffset : 0);
    std::string error;
    if (!t)
        error = "buffer " + std::to_string(w.buffer.id) + " is not a live buffer";
    else if (!w.data.ptr || size == 0 || w.srcOffset > w.data.size || size > w.data.size - w.srcOffset)
        error = "the source range (offset " + std::to_string(w.srcOffset) + ", " + std::to_string(size) +
                " bytes) is empty or past the data's " + std::to_string(w.data.size) + " bytes";
    else if (w.dstOffset > bufferSize || size > bufferSize - w.dstOffset)
        error = std::to_string(size) + " bytes at offset " + std::to_string(w.dstOffset) + " go past buffer '" + label +
                "''s " + std::to_string(bufferSize) + " bytes";
    if (!error.empty()) {
        device_.report("gpu vulkan: CommandList::write_buffer in list '" + label_ + "': " + error);
        return;
    }
    const UploadAlloc a = device_.upload(size, 16, this);
    if (!a.ok()) return;  // reported
    std::memcpy(a.cpu, static_cast<const std::uint8_t*>(w.data.ptr) + w.srcOffset, size);
    require(t, 0, transfer_write_state(false));
    flush_barriers();
    VkBufferCopy c{};
    c.srcOffset = a.offset;
    c.dstOffset = w.dstOffset;
    c.size = size;
    device_.fn_.vkCmdCopyBuffer(cmd_, a.buffer, t->buffer, 1, &c);
    empty_ = false;
}

void VulkanCommandList::copy_buffer_to_buffer(const BufferCopy& c) {
    FA_VK_REQUIRE_OPEN("copy_buffer_to_buffer");
    std::size_t srcSize = 0, dstSize = 0;
    std::string srcLabel, dstLabel;
    std::shared_ptr<TrackedResource> src = device_.buffer_tracked(c.src, &srcSize, &srcLabel);
    std::shared_ptr<TrackedResource> dst = device_.buffer_tracked(c.dst, &dstSize, &dstLabel);
    std::string error;
    if (!src || !dst)
        error = std::string("the ") + (!src ? "source" : "destination") + " is not a live buffer";
    else if (src == dst)
        error = "the source and the destination are the same buffer '" + srcLabel +
                "' (hint: copy through a second buffer)";
    else if (c.size == 0 || c.srcOffset % 4 || c.dstOffset % 4)
        error = "the size is 0 or an offset is not a multiple of 4";
    else if (c.srcOffset > srcSize || c.size > srcSize - c.srcOffset || c.dstOffset > dstSize ||
             c.size > dstSize - c.dstOffset)
        error = std::to_string(c.size) + " bytes from offset " + std::to_string(c.srcOffset) + " of '" + srcLabel +
                "' (" + std::to_string(srcSize) + " bytes) to offset " + std::to_string(c.dstOffset) + " of '" +
                dstLabel + "' (" + std::to_string(dstSize) + " bytes) go past a buffer's end";
    if (!error.empty()) {
        device_.report("gpu vulkan: CommandList::copy_buffer_to_buffer in list '" + label_ + "': " + error);
        return;
    }
    require(src, 0, transfer_read_state(false));
    require(dst, 0, transfer_write_state(false));
    flush_barriers();
    VkBufferCopy region{};
    region.srcOffset = c.srcOffset;
    region.dstOffset = c.dstOffset;
    region.size = c.size;
    device_.fn_.vkCmdCopyBuffer(cmd_, src->buffer, dst->buffer, 1, &region);
    empty_ = false;
}

void VulkanCommandList::copy_to_image(VkBuffer src, VkDeviceSize offset, std::uint32_t rowTexels,
                                      std::uint32_t sliceRows, const std::shared_ptr<TrackedResource>& t, bool is3d,
                                      std::uint32_t mip, std::uint32_t layer, std::uint32_t count, std::uint32_t x,
                                      std::uint32_t y, std::uint32_t width, std::uint32_t height) {
    if (is3d)
        require(t, t->subresource(mip, 0), transfer_write_state(true));
    else
        require_range(t, mip, 1, layer, count, transfer_write_state(true));
    flush_barriers();
    VkBufferImageCopy c{};
    c.bufferOffset = offset;
    c.bufferRowLength = rowTexels;
    c.bufferImageHeight = sliceRows;
    c.imageSubresource.aspectMask = t->aspects;
    c.imageSubresource.mipLevel = mip;
    c.imageSubresource.baseArrayLayer = is3d ? 0 : layer;
    c.imageSubresource.layerCount = is3d ? 1 : count;
    // a compressed region that ends at the mip's edge may end inside a 4x4 block: the copy takes the texels it covers
    c.imageOffset = {std::int32_t(x), std::int32_t(y), is3d ? std::int32_t(layer) : 0};
    c.imageExtent = {width, height, is3d ? count : 1u};
    device_.fn_.vkCmdCopyBufferToImage(cmd_, src, t->image, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &c);
    empty_ = false;
}

bool VulkanCommandList::upload_region(const std::shared_ptr<TrackedResource>& t, PixelFormat format, bool is3d,
                                      std::uint32_t mip, std::uint32_t layer, std::uint32_t count, std::uint32_t x,
                                      std::uint32_t y, std::uint32_t width, std::uint32_t height,
                                      const std::uint8_t* src, std::size_t srcRowPitch, std::size_t srcSlicePitch) {
    const std::uint32_t rowBytes = texel_row_bytes(format, width);
    const std::uint32_t rows = texel_rows(format, height);
    const std::uint64_t slice = std::uint64_t(rowBytes) * rows;  // tightly packed in the upload buffer
    // the copy's offset is a multiple of the texel (block) size and of the device's preferred alignment, both powers
    // of two
    const std::size_t align = std::max<std::size_t>(device_.imageUploadAlign_, texel_block_bytes(format));
    const UploadAlloc a = device_.upload(std::size_t(slice * count), align, this);
    if (!a.ok()) return false;
    if (srcRowPitch == rowBytes && srcSlicePitch == slice) {
        std::memcpy(a.cpu, src, std::size_t(slice * count));
    } else {
        for (std::uint32_t i = 0; i < count; ++i)
            for (std::uint32_t r = 0; r < rows; ++r)
                std::memcpy(a.cpu + slice * i + std::uint64_t(rowBytes) * r, src + srcSlicePitch * i + srcRowPitch * r,
                            rowBytes);
    }
    copy_to_image(a.buffer, a.offset, 0, 0, t, is3d, mip, layer, count, x, y, width, height);
    return true;
}

namespace {

// The region of a write_image / copy_buffer_to_image, checked against the image, with sokol's defaults.
struct Region {
    std::uint32_t mip = 0, x = 0, y = 0, layer = 0, width = 0, height = 0, count = 0;
    std::size_t rowPitch = 0, slicePitch = 0;  // of the source
    std::uint32_t rowBytes = 0, rows = 0;      // of the region
    std::string error;
};

template <class Record>
Region image_region(const Record& im, const ImageLocation& at, const ImageExtent& size, int bytesPerRow,
                    int bytesPerSlice) {
    Region r;
    const bool is3d = im.type == ImageType::Tex3d;
    if (at.mipLevel < 0 || at.mipLevel >= im.mips) {
        r.error = "mip level " + std::to_string(at.mipLevel) + " is outside image '" + im.label + "''s " +
                  std::to_string(im.mips) + " levels";
        return r;
    }
    if (pixel_format_depth(im.format) || im.samples > 1) {
        r.error = "image '" + im.label + "' is a depth or multisampled image (hint: draw into it instead)";
        return r;
    }
    r.mip = std::uint32_t(at.mipLevel);
    const std::uint32_t mw = mip_extent(im.width, at.mipLevel), mh = mip_extent(im.height, at.mipLevel);
    const std::uint32_t md = is3d ? mip_extent(im.slices, at.mipLevel) : std::uint32_t(im.slices);
    r.width = extent_or_rest(size.width, at.x, mw);
    r.height = extent_or_rest(size.height, at.y, mh);
    r.count = extent_or_rest(size.numSlices, at.slice, md);
    if (at.x < 0 || at.y < 0 || at.slice < 0 || r.width == 0 || r.height == 0 || r.count == 0 ||
        std::uint64_t(at.x) + r.width > mw || std::uint64_t(at.y) + r.height > mh ||
        std::uint64_t(at.slice) + r.count > md) {
        r.error = "the region at (" + std::to_string(at.x) + ", " + std::to_string(at.y) + ", slice " +
                  std::to_string(at.slice) + ") of " + std::to_string(r.width) + "x" + std::to_string(r.height) + "x" +
                  std::to_string(r.count) + " is empty or outside mip " + std::to_string(at.mipLevel) + " (" +
                  std::to_string(mw) + "x" + std::to_string(mh) + "x" + std::to_string(md) + ") of image '" + im.label +
                  "'";
        return r;
    }
    r.x = std::uint32_t(at.x);
    r.y = std::uint32_t(at.y);
    r.layer = std::uint32_t(at.slice);
    if (format_info(im.format).blockBytes &&
        (r.x % 4 || r.y % 4 || (r.width % 4 && r.x + r.width != mw) || (r.height % 4 && r.y + r.height != mh))) {
        r.error = "a compressed image is written in whole 4x4 blocks (hint: align the region to 4 texels)";
        return r;
    }
    r.rowBytes = texel_row_bytes(im.format, r.width);
    r.rows = texel_rows(im.format, r.height);
    // sokol's defaults: the pitches of the whole mip level, not of the region.
    r.rowPitch = bytesPerRow > 0 ? std::size_t(bytesPerRow) : texel_row_bytes(im.format, mw);
    r.slicePitch = bytesPerSlice > 0 ? std::size_t(bytesPerSlice) : r.rowPitch * texel_rows(im.format, mh);
    if (r.rowPitch < r.rowBytes || r.slicePitch < r.rowPitch * r.rows) {
        r.error = "bytesPerRow " + std::to_string(r.rowPitch) + " / bytesPerSlice " + std::to_string(r.slicePitch) +
                  " are smaller than a row (" + std::to_string(r.rowBytes) + ") / a slice of the region";
        return r;
    }
    return r;
}

std::size_t region_bytes(const Region& r) {
    return r.slicePitch * (r.count - 1) + r.rowPitch * (r.rows - 1) + r.rowBytes;
}

}  // namespace

void VulkanCommandList::write_image(const ImageWrite& w) {
    FA_VK_REQUIRE_OPEN("write_image");
    VulkanDevice::ImageRecord im;
    if (!device_.image_info(w.dst.image, im)) {
        device_.report("gpu vulkan: CommandList::write_image in list '" + label_ + "': image " +
                       std::to_string(w.dst.image.id) + " is not a live image");
        return;
    }
    Region r = image_region(im, w.dst, w.size, w.bytesPerRow, w.bytesPerSlice);
    if (r.error.empty() && (!w.data.ptr || w.srcOffset > w.data.size || region_bytes(r) > w.data.size - w.srcOffset))
        r.error = "the region needs " + std::to_string(region_bytes(r)) + " bytes from offset " +
                  std::to_string(w.srcOffset) + ", the data has " + std::to_string(w.data.size);
    if (!r.error.empty()) {
        device_.report("gpu vulkan: CommandList::write_image in list '" + label_ + "': " + r.error);
        return;
    }
    upload_region(im.tracked, im.format, im.type == ImageType::Tex3d, r.mip, r.layer, r.count, r.x, r.y, r.width,
                  r.height, static_cast<const std::uint8_t*>(w.data.ptr) + w.srcOffset, r.rowPitch, r.slicePitch);
}

void VulkanCommandList::copy_buffer_to_image(const BufferImageCopy& c) {
    FA_VK_REQUIRE_OPEN("copy_buffer_to_image");
    std::size_t srcSize = 0;
    std::string srcLabel;
    std::shared_ptr<TrackedResource> src = device_.buffer_tracked(c.src, &srcSize, &srcLabel);
    VulkanDevice::ImageRecord im;
    Region r;
    if (!src)
        r.error = "the source " + std::to_string(c.src.id) + " is not a live buffer";
    else if (!device_.image_info(c.dst.image, im))
        r.error = "the destination " + std::to_string(c.dst.image.id) + " is not a live image";
    else
        r = image_region(im, c.dst, c.size, c.bytesPerRow, c.bytesPerSlice);
    if (r.error.empty() && (c.srcOffset > srcSize || region_bytes(r) > srcSize - c.srcOffset))
        r.error = "the region needs " + std::to_string(region_bytes(r)) + " bytes from offset " +
                  std::to_string(c.srcOffset) + " of buffer '" + srcLabel + "', which has " + std::to_string(srcSize);
    if (!r.error.empty()) {
        device_.report("gpu vulkan: CommandList::copy_buffer_to_image in list '" + label_ + "': " + r.error);
        return;
    }
    const bool is3d = im.type == ImageType::Tex3d;
    const bool compressed = format_info(im.format).blockBytes != 0;
    const std::uint32_t texel = texel_block_bytes(im.format);
    require(src, 0, transfer_read_state(false));
    // Vulkan reads texels from any offset that is a multiple of the texel (block) size, with rows a whole number of
    // texels long and slices a whole number of rows: other layouts are repacked on the GPU first.
    if (c.srcOffset % texel == 0 && r.rowPitch % texel == 0 && r.slicePitch % r.rowPitch == 0) {
        const auto rowTexels = std::uint32_t(r.rowPitch / texel * (compressed ? 4u : 1u));
        const auto sliceRows = std::uint32_t(r.slicePitch / r.rowPitch * (compressed ? 4u : 1u));
        copy_to_image(src->buffer, c.srcOffset, rowTexels, sliceRows, im.tracked, is3d, r.mip, r.layer, r.count, r.x,
                      r.y, r.width, r.height);
        return;
    }
    const std::uint64_t slice = std::uint64_t(r.rowBytes) * r.rows;
    std::string error;
    std::shared_ptr<TrackedResource> scratch =
        device_.make_raw_buffer(slice * r.count, VK_BUFFER_USAGE_TRANSFER_SRC_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT,
                                MemoryUse::GpuOnly, false, "fa-vulkan-repack", error);
    if (!scratch) {
        device_.report("gpu vulkan: CommandList::copy_buffer_to_image in list '" + label_ +
                       "': the buffer that repacks the rows could not be made: " + error);
        return;
    }
    require(scratch, 0, transfer_write_state(false));
    flush_barriers();
    std::vector<VkBufferCopy> rows;
    rows.reserve(std::size_t(r.count) * r.rows);
    for (std::uint32_t i = 0; i < r.count; ++i)
        for (std::uint32_t row = 0; row < r.rows; ++row) {
            VkBufferCopy b{};
            b.srcOffset = c.srcOffset + r.slicePitch * i + r.rowPitch * row;
            b.dstOffset = slice * i + std::uint64_t(r.rowBytes) * row;
            b.size = r.rowBytes;
            rows.push_back(b);
        }
    device_.fn_.vkCmdCopyBuffer(cmd_, src->buffer, scratch->buffer, std::uint32_t(rows.size()), rows.data());
    require(scratch, 0, transfer_read_state(false));
    copy_to_image(scratch->buffer, 0, 0, 0, im.tracked, is3d, r.mip, r.layer, r.count, r.x, r.y, r.width, r.height);
    keep_until_done(std::move(scratch));
}

// ---------------------------------------------------------------------------------------------------------------------
// Debug groups (debug utils labels)
// ---------------------------------------------------------------------------------------------------------------------

void VulkanCommandList::push_debug_group(const char* name) {
    FA_VK_REQUIRE_OPEN("push_debug_group");
    if (device_.fn_.vkCmdBeginDebugUtilsLabelEXT) {
        VkDebugUtilsLabelEXT l{};
        l.sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_LABEL_EXT;
        l.pLabelName = name ? name : "";
        device_.fn_.vkCmdBeginDebugUtilsLabelEXT(cmd_, &l);
    }
    ++debugDepth_;
}

void VulkanCommandList::pop_debug_group() {
    FA_VK_REQUIRE_OPEN("pop_debug_group");
    if (debugDepth_ == 0) {
        device_.report("gpu vulkan: CommandList::pop_debug_group in list '" + label_ +
                       "' without an open group (hint: one pop_debug_group() per push_debug_group())");
        return;
    }
    if (device_.fn_.vkCmdEndDebugUtilsLabelEXT) device_.fn_.vkCmdEndDebugUtilsLabelEXT(cmd_);
    --debugDepth_;
}

#undef FA_VK_REQUIRE_OPEN

}  // namespace fa::gpu::vk

#endif  // FA_VULKAN_BACKEND
