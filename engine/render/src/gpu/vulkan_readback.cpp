// The Vulkan backend's blocking readbacks: a copy into a host-visible buffer, a timeline wait, a read of the mapped
// memory (docs/design/ARCHITECTURE_RENDERING_VULKAN.md).
#include "gpu/vulkan_device.h"

#if defined(FA_VULKAN_BACKEND)

#include <cstring>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "hdr_encode.h"

namespace fa::gpu::vk {

namespace {

// The copy's writes become visible to the host once the timeline wait returns.
void host_read_barrier(const VkFunctions& f, VkCommandBuffer cmd) {
    VkMemoryBarrier mb{};
    mb.sType = VK_STRUCTURE_TYPE_MEMORY_BARRIER;
    mb.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
    mb.dstAccessMask = VK_ACCESS_HOST_READ_BIT;
    f.vkCmdPipelineBarrier(cmd, VK_PIPELINE_STAGE_TRANSFER_BIT, VK_PIPELINE_STAGE_HOST_BIT, 0, 1, &mb, 0, nullptr, 0,
                           nullptr);
}

// Readback memory that is not host-coherent is invalidated before the CPU reads it (the buffer has a memory of its own,
// so the whole of it is one range).
Result<void> invalidate(const VkFunctions& f, VkDevice device, const Allocation& a, const std::string& where) {
    if (a.coherent) return {};
    VkMappedMemoryRange range{};
    range.sType = VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE;
    range.memory = a.memory;
    range.offset = 0;
    range.size = VK_WHOLE_SIZE;
    const VkResult r = f.vkInvalidateMappedMemoryRanges(device, 1, &range);
    if (r != VK_SUCCESS)
        return make_error(where + ": vkInvalidateMappedMemoryRanges failed with " + result_text(r),
                          "the device was lost or the process ran out of memory");
    return {};
}

}  // namespace

Result<void> VulkanDevice::read_texture(const ImageRecord& rec, std::uint32_t mip, std::uint32_t layer, int x, int y,
                                        int width, int height, std::vector<std::uint8_t>& out, const char* what) {
    const std::string where = std::string("gpu vulkan: ") + what + " of image '" + rec.label + "'";
    if (rec.samples > 1)
        return make_error(where + ": the image is multisampled",
                          "resolve it into a single-sampled image (PassDesc::resolve) and read that");
    if (pixel_format_depth(rec.format) || pixel_format_compressed(rec.format))
        return make_error(where + ": " + pixel_format_name(rec.format) + " images are not read back",
                          "copy the values into a colour or storage image with a shader and read that");
    const bool is3d = rec.type == ImageType::Tex3d;
    if (mip >= std::uint32_t(rec.mips))
        return make_error(where + ": mip " + std::to_string(mip) + " is outside its " + std::to_string(rec.mips) +
                              " levels",
                          "read a mip level from 0 to numMipmaps - 1");
    const std::uint32_t mw = mip_extent(rec.width, int(mip)), mh = mip_extent(rec.height, int(mip));
    const std::uint32_t layers = is3d ? mip_extent(rec.slices, int(mip)) : std::uint32_t(rec.slices);
    if (layer >= layers)
        return make_error(where + ": slice " + std::to_string(layer) + " is outside its " + std::to_string(layers) +
                              " slices at mip " + std::to_string(mip),
                          "read a slice from 0 to the image's slice count - 1");
    if (x < 0 || y < 0 || width < 1 || height < 1 || std::uint64_t(x) + std::uint64_t(width) > mw ||
        std::uint64_t(y) + std::uint64_t(height) > mh)
        return make_error(where + ": the rectangle (" + std::to_string(x) + ", " + std::to_string(y) + ", " +
                              std::to_string(width) + "x" + std::to_string(height) + ") is empty or outside its " +
                              std::to_string(mw) + "x" + std::to_string(mh) + " mip " + std::to_string(mip),
                          "read inside the image's size");
    if (!rec.tracked) return make_error(where + ": the image has no Vulkan image", "make_image failed: see errors()");
    const std::uint32_t rowBytes = texel_row_bytes(rec.format, std::uint32_t(width));
    const std::uint64_t total = std::uint64_t(rowBytes) * std::uint32_t(height);
    std::string error;
    std::shared_ptr<TrackedResource> rb = make_raw_buffer(total, VK_BUFFER_USAGE_TRANSFER_DST_BIT, MemoryUse::Readback,
                                                          true, "fa-vulkan-readback", error);
    if (!rb) return make_error(where + ": the readback buffer could not be made: " + error, "see errors()");
    if (!rb->memory.mapped)
        return make_error(where + ": the readback buffer is not mapped", "the device has no host-visible memory");
    {
        std::lock_guard<std::mutex> lock(queueMutex_);
        flush_prelude();  // the image's initial data goes first
        VulkanCommandList* list = acquire_list("fa-vulkan-readback", true);
        if (!list) return make_error(where + ": no command list", "see errors() for Vulkan's reason");
        list->require(rec.tracked, rec.tracked->subresource(mip, is3d ? 0 : layer), transfer_read_state(true));
        list->require(rb, 0, transfer_write_state(false));
        list->flush_barriers();
        VkBufferImageCopy c{};
        c.bufferOffset = 0;
        c.bufferRowLength = 0;  // tightly packed
        c.bufferImageHeight = 0;
        c.imageSubresource.aspectMask = rec.tracked->aspects;
        c.imageSubresource.mipLevel = mip;
        c.imageSubresource.baseArrayLayer = is3d ? 0 : layer;
        c.imageSubresource.layerCount = 1;
        c.imageOffset = {x, y, is3d ? std::int32_t(layer) : 0};
        c.imageExtent = {std::uint32_t(width), std::uint32_t(height), 1};
        fn_.vkCmdCopyImageToBuffer(list->cmd_, rec.tracked->image, VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, rb->buffer, 1,
                                   &c);
        host_read_barrier(fn_, list->cmd_);
        list->empty_ = false;
        execute(*list);
        auto r = wait_timeline(list->fence_, what);
        collect();
        if (!r) return r;
    }
    if (auto r = invalidate(fn_, device_, rb->memory, where); !r) return r;
    out.assign(rb->memory.mapped, rb->memory.mapped + total);
    return {};
}

Result<void> VulkanDevice::read_image_region(Image image, int mip, int layer, int x, int y, int width, int height,
                                             std::vector<std::uint8_t>& out) {
    ImageRecord rec;
    if (!image_info(image, rec))
        return make_error("gpu vulkan: read_image_region: image " + std::to_string(image.id) +
                              " is not a live image (destroyed, failed, or another device's)",
                          "read an image this device made, before destroy_image()");
    if (mip < 0 || layer < 0)
        return make_error("gpu vulkan: read_image_region of image '" + rec.label + "': a negative mip or slice",
                          "mip and slice count from 0");
    return read_texture(rec, std::uint32_t(mip), std::uint32_t(layer), x, y, width, height, out, "read_image_region");
}

Result<void> VulkanDevice::read_image_rgba8(Image image, int width, int height, std::vector<std::uint8_t>& out) {
    ImageRecord rec;
    if (!image_info(image, rec))
        return make_error("gpu vulkan: read_image_rgba8: image " + std::to_string(image.id) + " is not a live image",
                          "read an image this device made, before destroy_image()");
    const PixelFormat f = rec.format;
    if (f != PixelFormat::Rgba8 && f != PixelFormat::Srgb8A8 && f != PixelFormat::Bgra8 && f != PixelFormat::Sbgr8A8)
        return make_error(std::string("gpu vulkan: read_image_rgba8 of image '") + rec.label + "': its format is " +
                              pixel_format_name(f) + ", not an 8-bit RGBA or BGRA one",
                          "read an RGBA16F image with read_image_rgba16f, other formats with read_storage_image");
    if (auto r = read_texture(rec, 0, 0, 0, 0, width, height, out, "read_image_rgba8"); !r) return r;
    if (f == PixelFormat::Bgra8 || f == PixelFormat::Sbgr8A8)
        for (std::size_t i = 0; i + 3 < out.size(); i += 4) std::swap(out[i], out[i + 2]);  // BGRA -> RGBA
    return {};
}

Result<void> VulkanDevice::read_image_rgba16f(Image image, int width, int height, std::vector<float>& out) {
    ImageRecord rec;
    if (!image_info(image, rec))
        return make_error("gpu vulkan: read_image_rgba16f: image " + std::to_string(image.id) + " is not a live image",
                          "read an image this device made, before destroy_image()");
    if (rec.format != PixelFormat::Rgba16F)
        return make_error(std::string("gpu vulkan: read_image_rgba16f of image '") + rec.label + "': its format is " +
                              pixel_format_name(rec.format) + ", not RGBA16F",
                          "read 8-bit images with read_image_rgba8, other formats with read_storage_image");
    std::vector<std::uint8_t> bytes;
    if (auto r = read_texture(rec, 0, 0, 0, 0, width, height, bytes, "read_image_rgba16f"); !r) return r;
    out.resize(bytes.size() / 2);
    for (std::size_t i = 0; i < out.size(); ++i) {
        std::uint16_t h = 0;
        std::memcpy(&h, bytes.data() + i * 2, 2);
        out[i] = render::half_to_float(h);
    }
    return {};
}

Result<void> VulkanDevice::read_storage_image(Image image, PixelFormat format, int x, int y, int width, int height,
                                              std::vector<std::uint8_t>& out) {
    ImageRecord rec;
    if (!image_info(image, rec))
        return make_error("gpu vulkan: read_storage_image: image " + std::to_string(image.id) + " is not a live image",
                          "read an image this device made, before destroy_image()");
    if (format != rec.format)
        return make_error(std::string("gpu vulkan: read_storage_image of image '") + rec.label + "': asked for " +
                              pixel_format_name(format) + ", the image is " + pixel_format_name(rec.format),
                          "pass the image's own format: the bytes come back in it, tightly packed");
    return read_texture(rec, 0, 0, x, y, width, height, out, "read_storage_image");
}

Result<void> VulkanDevice::read_buffer(Buffer buffer, std::size_t offset, std::size_t bytes,
                                       std::vector<std::uint8_t>& out) {
    std::size_t size = 0;
    std::string label;
    std::shared_ptr<TrackedResource> t = buffer_tracked(buffer, &size, &label);
    if (!t)
        return make_error("gpu vulkan: read_buffer: buffer " + std::to_string(buffer.id) +
                              " is not a live buffer (destroyed, failed, or another device's)",
                          "read a buffer this device made, before destroy_buffer()");
    if (offset > size || bytes > size - offset)
        return make_error("gpu vulkan: read_buffer of buffer '" + label + "': " + std::to_string(bytes) +
                              " bytes from offset " + std::to_string(offset) + " go past its " + std::to_string(size) +
                              " bytes",
                          "read inside the buffer");
    out.clear();
    if (bytes == 0) return {};
    const std::string where = "gpu vulkan: read_buffer of buffer '" + label + "'";
    std::string error;
    std::shared_ptr<TrackedResource> rb = make_raw_buffer(bytes, VK_BUFFER_USAGE_TRANSFER_DST_BIT, MemoryUse::Readback,
                                                          true, "fa-vulkan-readback", error);
    if (!rb) return make_error(where + ": the readback buffer could not be made: " + error, "see errors()");
    if (!rb->memory.mapped)
        return make_error(where + ": the readback buffer is not mapped", "the device has no host-visible memory");
    {
        std::lock_guard<std::mutex> lock(queueMutex_);
        flush_prelude();
        VulkanCommandList* list = acquire_list("fa-vulkan-readback", true);
        if (!list) return make_error("gpu vulkan: read_buffer: no command list", "see errors() for Vulkan's reason");
        list->require(t, 0, transfer_read_state(false));
        list->require(rb, 0, transfer_write_state(false));
        list->flush_barriers();
        VkBufferCopy c{};
        c.srcOffset = offset;
        c.dstOffset = 0;
        c.size = bytes;
        fn_.vkCmdCopyBuffer(list->cmd_, t->buffer, rb->buffer, 1, &c);
        host_read_barrier(fn_, list->cmd_);
        list->empty_ = false;
        execute(*list);
        auto r = wait_timeline(list->fence_, "read_buffer");
        collect();
        if (!r) return r;
    }
    if (auto r = invalidate(fn_, device_, rb->memory, where); !r) return r;
    out.assign(rb->memory.mapped, rb->memory.mapped + bytes);
    return {};
}

}  // namespace fa::gpu::vk

#endif  // FA_VULKAN_BACKEND
