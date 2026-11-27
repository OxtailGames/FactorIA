// The Vulkan backend's resources: formats, buffers, images, views, samplers, their states and native objects
// (docs/design/ARCHITECTURE_RENDERING_VULKAN.md).
#include "gpu/vulkan_device.h"

#if defined(FA_VULKAN_BACKEND)

#include <algorithm>
#include <cstring>
#include <memory>
#include <string>
#include <utility>

#include "fa/core/log.h"

namespace fa::gpu::vk {

namespace {

std::string label_of(const char* label) { return label && *label ? std::string(label) : std::string("(no label)"); }

int max_mips(int w, int h, int d) {
    int largest = std::max(w, std::max(h, d));
    int n = 1;
    while (largest > 1) {
        largest >>= 1;
        ++n;
    }
    return n;
}

const char* image_type_name(ImageType t) {
    switch (t) {
        case ImageType::Cube: return "cube";
        case ImageType::Tex3d: return "3D";
        case ImageType::Array: return "array";
        default: return "2D";
    }
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// Formats
// ---------------------------------------------------------------------------------------------------------------------

FormatInfo format_info(PixelFormat f) {
    auto color = [](VkFormat x) {
        FormatInfo i;
        i.format = x;
        i.aspects = VK_IMAGE_ASPECT_COLOR_BIT;
        return i;
    };
    auto block = [](VkFormat x, std::uint32_t bytes) {
        FormatInfo i;
        i.format = x;
        i.blockBytes = bytes;
        i.aspects = VK_IMAGE_ASPECT_COLOR_BIT;
        return i;
    };
    switch (f) {
        case PixelFormat::R8: return color(VK_FORMAT_R8_UNORM);
        case PixelFormat::R8Sn: return color(VK_FORMAT_R8_SNORM);
        case PixelFormat::R8Ui: return color(VK_FORMAT_R8_UINT);
        case PixelFormat::R8Si: return color(VK_FORMAT_R8_SINT);
        case PixelFormat::R16: return color(VK_FORMAT_R16_UNORM);
        case PixelFormat::R16Sn: return color(VK_FORMAT_R16_SNORM);
        case PixelFormat::R16Ui: return color(VK_FORMAT_R16_UINT);
        case PixelFormat::R16Si: return color(VK_FORMAT_R16_SINT);
        case PixelFormat::R16F: return color(VK_FORMAT_R16_SFLOAT);
        case PixelFormat::Rg8: return color(VK_FORMAT_R8G8_UNORM);
        case PixelFormat::Rg8Sn: return color(VK_FORMAT_R8G8_SNORM);
        case PixelFormat::Rg8Ui: return color(VK_FORMAT_R8G8_UINT);
        case PixelFormat::Rg8Si: return color(VK_FORMAT_R8G8_SINT);
        case PixelFormat::R32Ui: return color(VK_FORMAT_R32_UINT);
        case PixelFormat::R32Si: return color(VK_FORMAT_R32_SINT);
        case PixelFormat::R32F: return color(VK_FORMAT_R32_SFLOAT);
        case PixelFormat::Rg16: return color(VK_FORMAT_R16G16_UNORM);
        case PixelFormat::Rg16Sn: return color(VK_FORMAT_R16G16_SNORM);
        case PixelFormat::Rg16Ui: return color(VK_FORMAT_R16G16_UINT);
        case PixelFormat::Rg16Si: return color(VK_FORMAT_R16G16_SINT);
        case PixelFormat::Rg16F: return color(VK_FORMAT_R16G16_SFLOAT);
        case PixelFormat::Rgba8: return color(VK_FORMAT_R8G8B8A8_UNORM);
        case PixelFormat::Srgb8A8: return color(VK_FORMAT_R8G8B8A8_SRGB);
        case PixelFormat::Rgba8Sn: return color(VK_FORMAT_R8G8B8A8_SNORM);
        case PixelFormat::Rgba8Ui: return color(VK_FORMAT_R8G8B8A8_UINT);
        case PixelFormat::Rgba8Si: return color(VK_FORMAT_R8G8B8A8_SINT);
        case PixelFormat::Bgra8: return color(VK_FORMAT_B8G8R8A8_UNORM);
        case PixelFormat::Sbgr8A8: return color(VK_FORMAT_B8G8R8A8_SRGB);
        // the packed formats name their bits from the most significant one: R in the low bits, as on the other APIs
        case PixelFormat::Rgb10A2: return color(VK_FORMAT_A2B10G10R10_UNORM_PACK32);
        case PixelFormat::Rg11B10F: return color(VK_FORMAT_B10G11R11_UFLOAT_PACK32);
        case PixelFormat::Rgb9E5: return color(VK_FORMAT_E5B9G9R9_UFLOAT_PACK32);
        case PixelFormat::Rg32Ui: return color(VK_FORMAT_R32G32_UINT);
        case PixelFormat::Rg32Si: return color(VK_FORMAT_R32G32_SINT);
        case PixelFormat::Rg32F: return color(VK_FORMAT_R32G32_SFLOAT);
        case PixelFormat::Rgba16: return color(VK_FORMAT_R16G16B16A16_UNORM);
        case PixelFormat::Rgba16Sn: return color(VK_FORMAT_R16G16B16A16_SNORM);
        case PixelFormat::Rgba16Ui: return color(VK_FORMAT_R16G16B16A16_UINT);
        case PixelFormat::Rgba16Si: return color(VK_FORMAT_R16G16B16A16_SINT);
        case PixelFormat::Rgba16F: return color(VK_FORMAT_R16G16B16A16_SFLOAT);
        case PixelFormat::Rgba32Ui: return color(VK_FORMAT_R32G32B32A32_UINT);
        case PixelFormat::Rgba32Si: return color(VK_FORMAT_R32G32B32A32_SINT);
        case PixelFormat::Rgba32F: return color(VK_FORMAT_R32G32B32A32_SFLOAT);
        case PixelFormat::Depth: {
            FormatInfo i;
            i.format = VK_FORMAT_D32_SFLOAT;
            i.aspects = VK_IMAGE_ASPECT_DEPTH_BIT;
            return i;
        }
        case PixelFormat::DepthStencil: {
            FormatInfo i;
            i.format = VK_FORMAT_D24_UNORM_S8_UINT;  // the device may take D32S8 instead (VulkanDevice::vk_format)
            i.aspects = VK_IMAGE_ASPECT_DEPTH_BIT | VK_IMAGE_ASPECT_STENCIL_BIT;
            return i;
        }
        case PixelFormat::Bc1Rgba: return block(VK_FORMAT_BC1_RGBA_UNORM_BLOCK, 8);
        case PixelFormat::Bc2Rgba: return block(VK_FORMAT_BC2_UNORM_BLOCK, 16);
        case PixelFormat::Bc3Rgba: return block(VK_FORMAT_BC3_UNORM_BLOCK, 16);
        case PixelFormat::Bc3Srgba: return block(VK_FORMAT_BC3_SRGB_BLOCK, 16);
        case PixelFormat::Bc4R: return block(VK_FORMAT_BC4_UNORM_BLOCK, 8);
        case PixelFormat::Bc4RSn: return block(VK_FORMAT_BC4_SNORM_BLOCK, 8);
        case PixelFormat::Bc5Rg: return block(VK_FORMAT_BC5_UNORM_BLOCK, 16);
        case PixelFormat::Bc5RgSn: return block(VK_FORMAT_BC5_SNORM_BLOCK, 16);
        case PixelFormat::Bc6hRgbF: return block(VK_FORMAT_BC6H_SFLOAT_BLOCK, 16);
        case PixelFormat::Bc6hRgbUf: return block(VK_FORMAT_BC6H_UFLOAT_BLOCK, 16);
        case PixelFormat::Bc7Rgba: return block(VK_FORMAT_BC7_UNORM_BLOCK, 16);
        case PixelFormat::Bc7Srgba: return block(VK_FORMAT_BC7_SRGB_BLOCK, 16);
        case PixelFormat::Etc2Rgb8: return block(VK_FORMAT_ETC2_R8G8B8_UNORM_BLOCK, 8);
        case PixelFormat::Etc2Srgb8: return block(VK_FORMAT_ETC2_R8G8B8_SRGB_BLOCK, 8);
        case PixelFormat::Etc2Rgb8A1: return block(VK_FORMAT_ETC2_R8G8B8A1_UNORM_BLOCK, 8);
        case PixelFormat::Etc2Rgba8: return block(VK_FORMAT_ETC2_R8G8B8A8_UNORM_BLOCK, 16);
        case PixelFormat::Etc2Srgb8A8: return block(VK_FORMAT_ETC2_R8G8B8A8_SRGB_BLOCK, 16);
        case PixelFormat::EacR11: return block(VK_FORMAT_EAC_R11_UNORM_BLOCK, 8);
        case PixelFormat::EacR11Sn: return block(VK_FORMAT_EAC_R11_SNORM_BLOCK, 8);
        case PixelFormat::EacRg11: return block(VK_FORMAT_EAC_R11G11_UNORM_BLOCK, 16);
        case PixelFormat::EacRg11Sn: return block(VK_FORMAT_EAC_R11G11_SNORM_BLOCK, 16);
        case PixelFormat::Astc4x4Rgba: return block(VK_FORMAT_ASTC_4x4_UNORM_BLOCK, 16);
        case PixelFormat::Astc4x4Srgba: return block(VK_FORMAT_ASTC_4x4_SRGB_BLOCK, 16);
        default: return {};  // Default, None
    }
}

std::uint32_t texel_row_bytes(PixelFormat f, std::uint32_t width) {
    const FormatInfo fi = format_info(f);
    if (fi.blockBytes) return (width + 3) / 4 * fi.blockBytes;
    return width * std::uint32_t(pixel_format_bytes(f));
}

std::uint32_t texel_rows(PixelFormat f, std::uint32_t height) {
    return format_info(f).blockBytes ? (height + 3) / 4 : height;
}

std::uint32_t texel_block_bytes(PixelFormat f) {
    const FormatInfo fi = format_info(f);
    return fi.blockBytes ? fi.blockBytes : std::uint32_t(pixel_format_bytes(f));
}

// ---------------------------------------------------------------------------------------------------------------------
// Buffers
// ---------------------------------------------------------------------------------------------------------------------

Buffer VulkanDevice::make_buffer(const BufferDesc& desc) {
    const std::string label = label_of(desc.label);
    BufferRecord rec;
    rec.size = desc.size;
    rec.usage = desc.usage;
    rec.label = label;
    std::string error;
    bool poolFull = false;  // no Vulkan object and no upload then (reported when the record does not go in)
    {
        std::lock_guard<std::mutex> lock(resMutex_);
        poolFull = buffers_.alive() >= buffers_.capacity();
    }
    const bool accelUsage = desc.usage.accelBuildInput || desc.usage.accelStorage || desc.usage.accelScratch;
    if (desc.size == 0)
        error = "size is 0 (hint: give BufferDesc::size the buffer's bytes)";
    else if (accelUsage && !rayTracing_)
        error = std::string("usage ") +
                (desc.usage.accelStorage   ? "accelStorage"
                 : desc.usage.accelScratch ? "accelScratch"
                                           : "accelBuildInput") +
                " on a device without acceleration structures (Features::accelerationStructure is false: " + rtWhy_ +
                ") (hint: check Device::features().accelerationStructure before making ray tracing buffers)";
    else if (desc.data.ptr && desc.data.size > desc.size)
        error = "its initial data has " + std::to_string(desc.data.size) + " bytes, more than its size " +
                std::to_string(desc.size) + " (hint: BufferDesc::size is the buffer's bytes, at least data.size)";
    if (error.empty() && !poolFull) {
        const BufferUsage& u = desc.usage;
        VkBufferUsageFlags usage = VK_BUFFER_USAGE_TRANSFER_SRC_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT;
        if (u.vertexBuffer ||
            !(u.indexBuffer || u.storageBuffer || u.stagingBuffer || u.stagingIndexBuffer || accelUsage))
            usage |= VK_BUFFER_USAGE_VERTEX_BUFFER_BIT;
        if (u.indexBuffer || u.stagingIndexBuffer) usage |= VK_BUFFER_USAGE_INDEX_BUFFER_BIT;
        if (u.storageBuffer) usage |= VK_BUFFER_USAGE_STORAGE_BUFFER_BIT;
        // Ray tracing: what a build reads, where a structure lives, its scratch; each is named by its device address
        // (make_raw_buffer then takes memory with VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_BIT).
        if (u.accelBuildInput) usage |= VK_BUFFER_USAGE_ACCELERATION_STRUCTURE_BUILD_INPUT_READ_ONLY_BIT_KHR;
        if (u.accelStorage) usage |= VK_BUFFER_USAGE_ACCELERATION_STRUCTURE_STORAGE_BIT_KHR;
        if (u.accelScratch) usage |= VK_BUFFER_USAGE_STORAGE_BUFFER_BIT;  // build scratch is a storage buffer
        if (accelUsage) usage |= VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT;
        // whole 16-byte words, so a storage view's last word and a fill of the whole buffer stay inside it
        rec.tracked = make_raw_buffer(align_up(desc.size, 16), usage, MemoryUse::GpuOnly, false, label.c_str(), error);
    }
    if (!error.empty()) report("gpu vulkan: make_buffer '" + label + "': " + error);
    if (rec.tracked && desc.data.ptr && desc.data.size > 0) {
        std::shared_ptr<TrackedResource> t = rec.tracked;
        std::lock_guard<std::mutex> lock(queueMutex_);
        VulkanCommandList& p = prelude();
        if (p.open_) {
            const UploadAlloc a = upload(desc.data.size, 16, &p);
            if (a.ok()) {
                std::memcpy(a.cpu, desc.data.ptr, desc.data.size);
                p.require(t, 0, transfer_write_state(false));
                p.flush_barriers();
                VkBufferCopy c{};
                c.srcOffset = a.offset;
                c.dstOffset = 0;
                c.size = desc.data.size;
                fn_.vkCmdCopyBuffer(p.cmd_, a.buffer, t->buffer, 1, &c);
                p.empty_ = false;
            }
        }
    }
    std::unique_lock<std::mutex> lock(resMutex_);
    const std::shared_ptr<TrackedResource> made = rec.tracked;  // still ours when the record does not go in
    const bool ok = made != nullptr;
    // Full at the check at the top: nothing was made, so the record does not go in even when a slot was freed since
    // (it would be a failed buffer with no error reported for it).
    const std::uint32_t id = poolFull ? 0 : buffers_.add(std::move(rec));
    if (id == 0) {  // full (the check at the top, or another thread took the last slot since)
        const int capacity = buffers_.capacity();
        lock.unlock();
        report("gpu vulkan: make_buffer '" + label + "': the buffer pool is full (" + std::to_string(capacity) +
               " buffers) (hint: destroy buffers you no longer use, or raise DeviceInit::bufferPoolSize)");
        if (made) {  // the prelude may already copy into it: released once that frame is done
            Deferred d;
            d.tracked = made;
            defer(std::move(d));
        }
        return {};
    }
    count_make(stats_.buffers, ok);
    return Buffer{id};
}

void VulkanDevice::destroy_buffer(Buffer buffer) {
    if (!buffer.valid()) return;
    BufferRecord rec;
    {
        std::lock_guard<std::mutex> lock(resMutex_);
        if (!buffers_.remove(buffer.id, rec)) {
            report("gpu vulkan: destroy_buffer: buffer " + std::to_string(buffer.id) +
                   " names nothing (hint: it was destroyed already, or another device made it)");
            return;
        }
        count_destroy(stats_.buffers);
    }
    if (rec.tracked) {
        Deferred d;
        d.tracked = std::move(rec.tracked);
        defer(std::move(d));
    }
}

ResourceState VulkanDevice::state(Buffer buffer) const {
    std::lock_guard<std::mutex> lock(resMutex_);
    const BufferRecord* r = buffers_.get(buffer.id);
    if (!r) return ResourceState::Invalid;
    return r->tracked ? ResourceState::Valid : ResourceState::Failed;
}

std::shared_ptr<TrackedResource> VulkanDevice::buffer_tracked(Buffer b, std::size_t* size, std::string* label) const {
    std::lock_guard<std::mutex> lock(resMutex_);
    const BufferRecord* r = buffers_.get(b.id);
    if (!r) return nullptr;
    if (size) *size = r->size;
    if (label) *label = r->label;
    return r->tracked;
}

NativeBuffer VulkanDevice::native_buffer(Buffer buffer) const {
    NativeBuffer n;
    if (auto t = buffer_tracked(buffer, nullptr, nullptr)) {
        n.vkBuffer = handle_bits(t->buffer);
#if VK_USE_64_BIT_PTR_DEFINES == 1
        n.buffer = t->buffer;  // VkBuffer (a 32-bit target's handles are numbers, not pointers: vkBuffer only)
#endif
    }
    return n;
}

// ---------------------------------------------------------------------------------------------------------------------
// Images
// ---------------------------------------------------------------------------------------------------------------------

Image VulkanDevice::make_image(const ImageDesc& desc) {
    const std::string label = label_of(desc.label);
    const ImageUsage& u = desc.usage;
    const bool attachment = u.colorAttachment || u.resolveAttachment || u.depthStencilAttachment;
    ImageRecord rec;
    rec.type = desc.type == ImageType::Default ? ImageType::Tex2d : desc.type;
    rec.usage = u;
    rec.label = label;
    rec.format = desc.pixelFormat;
    if (rec.format == PixelFormat::Default) {
        if (!u.depthStencilAttachment && (u.colorAttachment || u.resolveAttachment)) note_default_color_used();
        rec.format = u.depthStencilAttachment                     ? defaults_.depthFormat
                     : (u.colorAttachment || u.resolveAttachment) ? defaults_.colorFormat
                                                                  : PixelFormat::Rgba8;
    }
    rec.width = desc.width;
    rec.height = desc.height;
    rec.slices = desc.numSlices > 0 ? desc.numSlices : (rec.type == ImageType::Cube ? 6 : 1);
    rec.mips = desc.numMipmaps > 0 ? desc.numMipmaps : 1;
    rec.samples = desc.sampleCount > 0 ? desc.sampleCount : (attachment ? defaults_.sampleCount : 1);
    const FormatInfo fi = format_info(rec.format);
    const VkFormat format = vk_format(rec.format);
    const bool depth = pixel_format_depth(rec.format);
    const bool is3d = rec.type == ImageType::Tex3d;
    const int maxSize = is3d                          ? limits_.maxImageSize3d
                        : rec.type == ImageType::Cube ? limits_.maxImageSizeCube
                                                      : limits_.maxImageSize2d;

    std::string error;
    if (rec.width < 1 || rec.height < 1 || rec.width > maxSize || rec.height > maxSize)
        error = "its size " + std::to_string(rec.width) + "x" + std::to_string(rec.height) + " is outside 1.." +
                std::to_string(maxSize) + " (hint: give ImageDesc::width and height)";
    else if (format == VK_FORMAT_UNDEFINED)
        error = std::string("pixel format ") + pixel_format_name(rec.format) +
                " is not an image format (hint: give ImageDesc::pixelFormat a format, or Default)";
    else if (rec.type == ImageType::Cube && (rec.slices != 6 || rec.width != rec.height))
        error = "a cube image needs 6 slices and square faces (it has " + std::to_string(rec.slices) + " slices of " +
                std::to_string(rec.width) + "x" + std::to_string(rec.height) + ")";
    else if (rec.slices < 1 || (is3d ? rec.slices > limits_.maxImageSize3d : rec.slices > limits_.maxImageArrayLayers))
        error = "numSlices " + std::to_string(rec.slices) + " is out of range (hint: 3D images up to " +
                std::to_string(limits_.maxImageSize3d) + " deep, arrays up to " +
                std::to_string(limits_.maxImageArrayLayers) + " layers)";
    else if (rec.type == ImageType::Tex2d && rec.slices != 1)
        error =
            "a 2D image has 1 slice, not " + std::to_string(rec.slices) + " (hint: make it an ImageType::Array image)";
    else if (rec.mips > max_mips(rec.width, rec.height, is3d ? rec.slices : 1) || rec.mips > kMaxMipmaps)
        error = std::to_string(rec.mips) + " mip levels is more than a " + std::to_string(rec.width) + "x" +
                std::to_string(rec.height) + " image has (" +
                std::to_string(max_mips(rec.width, rec.height, is3d ? rec.slices : 1)) + ")";
    else if (rec.samples != 1 && rec.samples != 2 && rec.samples != 4 && rec.samples != 8)
        error = "sampleCount " + std::to_string(rec.samples) + " is not 1, 2, 4 or 8";
    else if (rec.samples > 1 && (is3d || rec.mips > 1 || u.storageImage || !(u.colorAttachment || depth)))
        error = "a multisampled image is a 2D (or array) colour or depth attachment with 1 mip level and no storage "
                "usage";
    else if (fi.blockBytes && (attachment || u.storageImage))
        error = "a compressed image cannot be an attachment or a storage image";
    else if (depth && (u.storageImage || u.colorAttachment || u.resolveAttachment || is3d))
        error = "a depth image is a 2D, cube or array depth attachment (not storage, colour or 3D)";
    else if (u.depthStencilAttachment && !depth)
        error = std::string("a depth attachment needs a depth format, not ") + pixel_format_name(rec.format);

    VkImageCreateInfo ci{};
    if (error.empty()) {
        VkFormatProperties fp{};
        fn_.vkGetPhysicalDeviceFormatProperties(physical_, format, &fp);
        VkImageUsageFlags usage = VK_IMAGE_USAGE_TRANSFER_SRC_BIT | VK_IMAGE_USAGE_TRANSFER_DST_BIT;
        if (fp.optimalTilingFeatures & VK_FORMAT_FEATURE_SAMPLED_IMAGE_BIT) usage |= VK_IMAGE_USAGE_SAMPLED_BIT;
        if (u.colorAttachment || u.resolveAttachment) usage |= VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
        if (u.depthStencilAttachment) usage |= VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT;
        if (u.storageImage) usage |= VK_IMAGE_USAGE_STORAGE_BIT;
        ci.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
        if (rec.type == ImageType::Cube) ci.flags |= VK_IMAGE_CREATE_CUBE_COMPATIBLE_BIT;
        // a colour attachment view is a 2D view of one depth slice of a 3D image (not on every portability device)
        if (is3d && u.colorAttachment && imageView2DOn3D_) ci.flags |= VK_IMAGE_CREATE_2D_ARRAY_COMPATIBLE_BIT;
        ci.imageType = is3d ? VK_IMAGE_TYPE_3D : VK_IMAGE_TYPE_2D;
        ci.format = format;
        ci.extent = {std::uint32_t(rec.width), std::uint32_t(rec.height), is3d ? std::uint32_t(rec.slices) : 1u};
        ci.mipLevels = std::uint32_t(rec.mips);
        ci.arrayLayers = is3d ? 1u : std::uint32_t(rec.slices);
        ci.samples = VkSampleCountFlagBits(rec.samples);
        ci.tiling = VK_IMAGE_TILING_OPTIMAL;
        ci.usage = usage;
        ci.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
        ci.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
        VkImageFormatProperties ip{};
        const VkResult r = fn_.vkGetPhysicalDeviceImageFormatProperties(physical_, format, ci.imageType, ci.tiling,
                                                                        ci.usage, ci.flags, &ip);
        const std::string what = std::string("a ") + image_type_name(rec.type) + " " + pixel_format_name(rec.format) +
                                 " image" + (u.storageImage ? " with storage usage" : "") +
                                 (u.colorAttachment || u.resolveAttachment ? " to render to" : "");
        const char* hint = "check pixel_format_caps(format) first; compressed textures: BC1-BC7 on desktop GPUs, "
                           "ETC2/EAC and ASTC on mobile ones";
        if (r != VK_SUCCESS)
            error = deviceName_ + " cannot make " + what +
                    " (vkGetPhysicalDeviceImageFormatProperties: " + result_text(r) + ") (hint: " + hint + ")";
        else if (ci.extent.width > ip.maxExtent.width || ci.extent.height > ip.maxExtent.height ||
                 ci.extent.depth > ip.maxExtent.depth)
            error = deviceName_ + " makes " + what + " up to " + std::to_string(ip.maxExtent.width) + "x" +
                    std::to_string(ip.maxExtent.height) + "x" + std::to_string(ip.maxExtent.depth) +
                    " (hint: make it " + "smaller)";
        else if (ci.mipLevels > ip.maxMipLevels || ci.arrayLayers > ip.maxArrayLayers)
            error = deviceName_ + " makes " + what + " with up to " + std::to_string(ip.maxMipLevels) +
                    " mip levels and " + std::to_string(ip.maxArrayLayers) + " layers (hint: use fewer)";
        else if ((ip.sampleCounts & ci.samples) == 0)
            error = deviceName_ + " cannot make " + what + " with " + std::to_string(rec.samples) +
                    " samples (hint: pixel_format_caps(format).msaa says whether 4x works; use 1 sample otherwise)";
    }
    if (!error.empty()) report("gpu vulkan: make_image '" + label + "': " + error);

    bool poolFull = false;  // no Vulkan image and no upload then (reported when the record does not go in)
    {
        std::lock_guard<std::mutex> lock(resMutex_);
        poolFull = images_.alive() >= images_.capacity();
    }
    if (error.empty() && !poolFull) {
        auto t = std::make_shared<TrackedResource>();
        t->device = this;
        VkResult r = fn_.vkCreateImage(device_, &ci, nullptr, &t->image);
        if (r != VK_SUCCESS) {
            t->image = VK_NULL_HANDLE;
            report("gpu vulkan: make_image '" + label + "': vkCreateImage failed with " + result_text(r) + " (hint: " +
                   (r == VK_ERROR_OUT_OF_DEVICE_MEMORY || r == VK_ERROR_OUT_OF_HOST_MEMORY
                        ? "the GPU is out of memory: free resources or make them smaller"
                        : "the validation layer (VulkanOptions::validation) says which field is wrong") +
                   ")");
        } else {
            VkMemoryRequirements req{};
            fn_.vkGetImageMemoryRequirements(device_, t->image, &req);
            auto mem = memory_.alloc(req, MemoryUse::GpuOnly, false, false);
            if (!mem) {
                report("gpu vulkan: make_image '" + label + "': " + mem.error().to_string());
            } else {
                t->memory = mem.value();
                r = fn_.vkBindImageMemory(device_, t->image, t->memory.memory, t->memory.offset);
                if (r != VK_SUCCESS) {
                    report("gpu vulkan: make_image '" + label + "': vkBindImageMemory failed with " + result_text(r) +
                           " (hint: the device was lost or is out of memory)");
                } else {
                    t->aspects = fi.aspects;
                    t->usage = ci.usage;
                    t->format = ci.format;
                    t->mips = std::uint32_t(rec.mips);
                    t->layers = is3d ? 1u : std::uint32_t(rec.slices);
                    t->states.assign(t->subresource_count(), SubState{});
                    set_name(VK_OBJECT_TYPE_IMAGE, handle_bits(t->image), label.c_str());
                    rec.tracked = std::move(t);
                }
            }
        }
    }
    if (rec.tracked) upload_initial_image(rec, desc);

    std::unique_lock<std::mutex> lock(resMutex_);
    const std::shared_ptr<TrackedResource> made = rec.tracked;  // still ours when the record does not go in
    const bool ok = made != nullptr;
    // Full at the check at the top: nothing was made, so the record does not go in even when a slot was freed since
    // (it would be a failed image with no error reported for it).
    const std::uint32_t id = poolFull ? 0 : images_.add(std::move(rec));
    if (id == 0) {  // full (the check at the top, or another thread took the last slot since)
        const int capacity = images_.capacity();
        lock.unlock();
        report("gpu vulkan: make_image '" + label + "': the image pool is full (" + std::to_string(capacity) +
               " images) (hint: destroy images you no longer use, or raise DeviceInit::imagePoolSize)");
        if (made) {  // the prelude may already copy into it: released once that frame is done
            Deferred d;
            d.tracked = made;
            defer(std::move(d));
        }
        return {};
    }
    count_make(stats_.images, ok);
    return Image{id};
}

void VulkanDevice::upload_initial_image(const ImageRecord& rec, const ImageDesc& desc) {
    bool any = false;
    for (int m = 0; m < rec.mips; ++m)
        if (desc.data.mipLevels[m].ptr) any = true;
    if (!any) return;
    if (pixel_format_depth(rec.format) || rec.samples > 1) {
        report("gpu vulkan: make_image '" + rec.label +
               "': a depth or multisampled image has no initial data (hint: draw into it instead)");
        return;
    }
    const bool is3d = rec.type == ImageType::Tex3d;
    std::lock_guard<std::mutex> lock(queueMutex_);
    VulkanCommandList& p = prelude();
    if (!p.open_) return;
    for (int m = 0; m < rec.mips; ++m) {
        const Range& data = desc.data.mipLevels[m];
        if (!data.ptr) continue;
        const std::uint32_t w = mip_extent(rec.width, m), h = mip_extent(rec.height, m);
        const std::uint32_t count = is3d ? mip_extent(rec.slices, m) : std::uint32_t(rec.slices);
        const std::size_t rowPitch = texel_row_bytes(rec.format, w);
        const std::size_t slicePitch = rowPitch * texel_rows(rec.format, h);
        if (data.size < slicePitch * count) {
            report("gpu vulkan: make_image '" + rec.label + "': mip " + std::to_string(m) + " has " +
                   std::to_string(data.size) + " bytes of initial data, it needs " +
                   std::to_string(slicePitch * count) + " (" + std::to_string(count) + " slices of " +
                   std::to_string(w) + "x" + std::to_string(h) + " " + pixel_format_name(rec.format) +
                   ", tightly packed) (hint: ImageData::mipLevels[m] holds every slice of mip m)");
            continue;
        }
        p.upload_region(rec.tracked, rec.format, is3d, std::uint32_t(m), 0, count, 0, 0, w, h,
                        static_cast<const std::uint8_t*>(data.ptr), rowPitch, slicePitch);
    }
}

void VulkanDevice::destroy_image(Image image) {
    if (!image.valid()) return;
    ImageRecord rec;
    {
        std::lock_guard<std::mutex> lock(resMutex_);
        if (!images_.remove(image.id, rec)) {
            report("gpu vulkan: destroy_image: image " + std::to_string(image.id) +
                   " names nothing (hint: it was destroyed already, or another device made it)");
            return;
        }
        count_destroy(stats_.images);
    }
    if (rec.tracked) {
        Deferred d;
        d.tracked = std::move(rec.tracked);
        defer(std::move(d));
    }
}

ResourceState VulkanDevice::state(Image image) const {
    std::lock_guard<std::mutex> lock(resMutex_);
    const ImageRecord* r = images_.get(image.id);
    if (!r) return ResourceState::Invalid;
    return r->tracked ? ResourceState::Valid : ResourceState::Failed;
}

bool VulkanDevice::image_info(Image image, ImageRecord& out) const {
    std::lock_guard<std::mutex> lock(resMutex_);
    const ImageRecord* r = images_.get(image.id);
    if (!r || !r->tracked) return false;
    out = *r;
    return true;
}

NativeImage VulkanDevice::native_image(Image image) const {
    NativeImage n;
    std::lock_guard<std::mutex> lock(resMutex_);
    const ImageRecord* r = images_.get(image.id);
    if (!r || !r->tracked) return n;
    const TrackedResource& t = *r->tracked;
#if VK_USE_64_BIT_PTR_DEFINES == 1
    n.texture = t.image;  // a 32-bit target's handles are 64-bit numbers, not pointers: vkImage only
#endif
    n.vkImage = handle_bits(t.image);
    n.nativeFormat = std::uint32_t(t.format);
    n.vkUsage = t.usage;
    n.vkAspects = t.aspects;
    return n;
}

NativeView VulkanDevice::native_view(View view) const {
    NativeView n;
    std::lock_guard<std::mutex> lock(resMutex_);
    const ViewRecord* v = views_.get(view.id);
    if (!v || !v->tracked) return n;
    n.vkImageView = handle_bits(v->view);
    n.image = v->image;
    n.mip = v->mip;
    n.mipCount = v->mipCount;
    n.slice = v->slice;
    n.sliceCount = v->sliceCount;
    if (const ImageRecord* im = v->image.id ? images_.get(v->image.id) : nullptr)
        n.nativeFormat = vk_format(im->format);
    return n;
}

// ---------------------------------------------------------------------------------------------------------------------
// Views
// ---------------------------------------------------------------------------------------------------------------------

View VulkanDevice::make_view(const ViewDesc& desc) {
    const std::string label = label_of(desc.label);
    ViewRecord rec;
    rec.type = desc.type();
    std::string error;
    auto fail = [&](const std::string& e) {
        if (error.empty()) error = e;
    };

    std::lock_guard<std::mutex> lock(resMutex_);
    const int resources = desc.resource_count();
    if (resources != 1)
        fail("a ViewDesc names exactly one resource (this one names " + std::to_string(resources) +
             ") (hint: set one of texture, storageBuffer, storageImage, colorAttachment, resolveAttachment, "
             "depthStencilAttachment)");

    if (error.empty() && rec.type == ViewType::StorageBuffer) {
        const BufferRecord* b = buffers_.get(desc.storageBuffer.buffer.id);
        const int offset = desc.storageBuffer.offset;
        if (!b || !b->tracked)
            fail("its buffer " + std::to_string(desc.storageBuffer.buffer.id) + " is not a live buffer");
        else if (!b->usage.storageBuffer)
            fail("buffer '" + b->label + "' was not made with BufferUsage::storageBuffer");
        else if (offset < 0 || offset % 16 != 0 || std::size_t(offset) + 4 > b->size)
            fail("offset " + std::to_string(offset) + " is not a multiple of 16 inside the buffer's " +
                 std::to_string(b->size) + " bytes (hint: 256 suits every backend)");
        if (error.empty()) {
            // a storage buffer view is a descriptor's buffer and offset (minStorageBufferOffsetAlignment is checked
            // when M77-P8c binds it): no Vulkan object
            rec.buffer = desc.storageBuffer.buffer;
            rec.tracked = b->tracked;
            rec.offset = std::size_t(offset);
        }
    } else if (error.empty()) {
        // The image views: find the image and the mip / slice range first.
        Image image{};
        int mip = 0, mipCount = 1, slice = 0, sliceCount = 1;
        switch (rec.type) {
            case ViewType::Texture:
                image = desc.texture.image;
                mip = desc.texture.mipLevels.base;
                mipCount = desc.texture.mipLevels.count;
                slice = desc.texture.slices.base;
                sliceCount = desc.texture.slices.count;
                break;
            case ViewType::StorageImage:
                image = desc.storageImage.image;
                mip = desc.storageImage.mipLevel;
                slice = desc.storageImage.slice;
                break;
            case ViewType::ColorAttachment:
                image = desc.colorAttachment.image;
                mip = desc.colorAttachment.mipLevel;
                slice = desc.colorAttachment.slice;
                break;
            case ViewType::ResolveAttachment:
                image = desc.resolveAttachment.image;
                mip = desc.resolveAttachment.mipLevel;
                slice = desc.resolveAttachment.slice;
                break;
            default:
                image = desc.depthStencilAttachment.image;
                mip = desc.depthStencilAttachment.mipLevel;
                slice = desc.depthStencilAttachment.slice;
                break;
        }
        const ImageRecord* im = images_.get(image.id);
        if (!im || !im->tracked) {
            fail("its image " + std::to_string(image.id) + " is not a live image");
        } else {
            const bool is3d = im->type == ImageType::Tex3d;
            const int slices = is3d ? int(mip_extent(im->slices, std::clamp(mip, 0, im->mips - 1))) : im->slices;
            if (rec.type == ViewType::Texture) {
                if (mipCount == 0) mipCount = im->mips - mip;
                if (sliceCount == 0) sliceCount = slices - slice;
                if (is3d) {  // a 3D texture view sees every depth slice
                    slice = 0;
                    sliceCount = 1;
                }
            }
            if (mip < 0 || mipCount < 1 || mip + mipCount > im->mips)
                fail("mip levels " + std::to_string(mip) + ".." + std::to_string(mip + mipCount - 1) +
                     " are outside image '" + im->label + "''s " + std::to_string(im->mips) + " levels");
            else if (slice < 0 || sliceCount < 1 || slice + sliceCount > slices)
                fail("slices " + std::to_string(slice) + ".." + std::to_string(slice + sliceCount - 1) +
                     " are outside image '" + im->label + "''s " + std::to_string(slices) + " slices");
            const ImageUsage& u = im->usage;
            if (rec.type == ViewType::StorageImage && !u.storageImage)
                fail("image '" + im->label + "' was not made with ImageUsage::storageImage");
            if (rec.type == ViewType::ColorAttachment && !u.colorAttachment)
                fail("image '" + im->label + "' was not made with ImageUsage::colorAttachment");
            if (rec.type == ViewType::ResolveAttachment && (!u.resolveAttachment || im->samples > 1))
                fail("image '" + im->label + "' is not a single-sampled ImageUsage::resolveAttachment image");
            if (rec.type == ViewType::DepthStencilAttachment && (!u.depthStencilAttachment || is3d))
                fail("image '" + im->label + "' was not made with ImageUsage::depthStencilAttachment");
            if (rec.type == ViewType::ColorAttachment && is3d && !imageView2DOn3D_)
                fail(deviceName_ +
                     " has no 2D views of a 3D image (VK_KHR_portability_subset: imageView2DOn3DImage "
                     "is false), so a slice of 3D image '" +
                     im->label + "' cannot be a colour attachment (hint: draw into a 2D array image instead)");
            rec.image = image;
            rec.tracked = im->tracked;
            rec.mip = mip;
            rec.mipCount = mipCount;
            rec.slice = slice;
            rec.sliceCount = sliceCount;
            if (error.empty()) {
                const bool layered = im->type == ImageType::Array || im->type == ImageType::Cube;
                VkImageViewCreateInfo vi{};
                vi.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
                vi.image = im->tracked->image;
                vi.format = vk_format(im->format);
                vi.components = {VK_COMPONENT_SWIZZLE_IDENTITY, VK_COMPONENT_SWIZZLE_IDENTITY,
                                 VK_COMPONENT_SWIZZLE_IDENTITY, VK_COMPONENT_SWIZZLE_IDENTITY};
                vi.subresourceRange.aspectMask = im->tracked->aspects;
                vi.subresourceRange.baseMipLevel = std::uint32_t(mip);
                vi.subresourceRange.levelCount = 1;
                vi.subresourceRange.baseArrayLayer = std::uint32_t(slice);
                vi.subresourceRange.layerCount = 1;
                switch (rec.type) {
                    case ViewType::Texture:
                        vi.subresourceRange.levelCount = std::uint32_t(mipCount);
                        // a shader samples the depth of a depth-stencil image
                        if (pixel_format_depth(im->format)) vi.subresourceRange.aspectMask = VK_IMAGE_ASPECT_DEPTH_BIT;
                        if (is3d) {
                            vi.viewType = VK_IMAGE_VIEW_TYPE_3D;
                            vi.subresourceRange.baseArrayLayer = 0;
                        } else if (im->type == ImageType::Cube && slice == 0 && sliceCount == 6) {
                            vi.viewType = VK_IMAGE_VIEW_TYPE_CUBE;
                            vi.subresourceRange.layerCount = 6;
                        } else if (layered) {
                            vi.viewType = VK_IMAGE_VIEW_TYPE_2D_ARRAY;
                            vi.subresourceRange.layerCount = std::uint32_t(sliceCount);
                        } else {
                            vi.viewType = VK_IMAGE_VIEW_TYPE_2D;
                        }
                        break;
                    case ViewType::StorageImage:
                        if (is3d) {  // a storage view of a 3D image sees every depth slice of its mip
                            vi.viewType = VK_IMAGE_VIEW_TYPE_3D;
                            vi.subresourceRange.baseArrayLayer = 0;
                        } else {
                            vi.viewType = layered ? VK_IMAGE_VIEW_TYPE_2D_ARRAY : VK_IMAGE_VIEW_TYPE_2D;
                        }
                        break;
                    default:  // colour, resolve and depth attachments: one mip of one slice (a 3D image's depth slice)
                        vi.viewType = VK_IMAGE_VIEW_TYPE_2D;
                        break;
                }
                rec.viewType = vi.viewType;
                const VkResult r = fn_.vkCreateImageView(device_, &vi, nullptr, &rec.view);
                if (r != VK_SUCCESS) {
                    rec.view = VK_NULL_HANDLE;
                    fail("vkCreateImageView failed with " + result_text(r) +
                         " (hint: the validation layer (VulkanOptions::validation) says which field is wrong)");
                } else {
                    set_name(VK_OBJECT_TYPE_IMAGE_VIEW, handle_bits(rec.view), label.c_str());
                }
            }
        }
    }

    if (!error.empty()) {
        report("gpu vulkan: make_view '" + label + "': " + error);
        if (rec.view) fn_.vkDestroyImageView(device_, rec.view, nullptr);
        rec.view = VK_NULL_HANDLE;
        rec.tracked = nullptr;
    }
    // A texture view takes a slot of the bindless table (bindless_index()); a full table leaves it without one.
    if (rec.view && rec.type == ViewType::Texture && descriptors_.bindless_capacity() > 0) {
        rec.bindlessSlot = descriptors_.bindless_alloc();
        if (rec.bindlessSlot != kNoSlot) {
            descriptors_.bindless_write(rec.bindlessSlot, rec.view, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);
        } else {
            const std::string w = "gpu vulkan: make_view '" + label + "': the bindless table is full (" +
                                  std::to_string(descriptors_.bindless_capacity()) +
                                  " slots), so this texture view and the next ones have no bindless index (hint: "
                                  "raise VulkanOptions::bindlessDescriptors, or destroy texture views no longer drawn)";
            std::lock_guard<std::mutex> msgLock(msgMutex_);
            if (std::find(notYetReported_.begin(), notYetReported_.end(), "bindless-full") == notYetReported_.end()) {
                notYetReported_.push_back("bindless-full");
                FA_WARN("render", "{}", w);
                warnings_.push_back(w);
            }
        }
    }
    const bool ok = rec.tracked != nullptr;
    const VkImageView made = rec.view;
    const std::uint32_t slot = rec.bindlessSlot;
    rec.serial = ++viewSerial_;  // what the framebuffer cache knows the view by (a handle can be reused)
    const std::uint32_t id = views_.add(std::move(rec));
    if (id == 0) {
        if (slot != kNoSlot) descriptors_.bindless_free(slot);  // no command named it yet
        if (made) fn_.vkDestroyImageView(device_, made, nullptr);
        report("gpu vulkan: make_view '" + label + "': the view pool is full (" + std::to_string(views_.capacity()) +
               " views) (hint: destroy views you no longer use, or raise DeviceInit::viewPoolSize)");
        return {};
    }
    count_make(stats_.views, ok);
    return View{id};
}

void VulkanDevice::destroy_view(View view) {
    if (!view.valid()) return;
    ViewRecord rec;
    {
        std::lock_guard<std::mutex> lock(resMutex_);
        if (!views_.remove(view.id, rec)) {
            report("gpu vulkan: destroy_view: view " + std::to_string(view.id) +
                   " names nothing (hint: it was destroyed already, or another device made it)");
            return;
        }
        count_destroy(stats_.views);
    }
    // The framebuffers made with it go first (deferred like the view: a frame in flight may draw into them).
    if (rec.view && (rec.type == ViewType::ColorAttachment || rec.type == ViewType::ResolveAttachment ||
                     rec.type == ViewType::DepthStencilAttachment))
        forget_framebuffers(rec.serial);
    if (rec.tracked || rec.view || rec.bindlessSlot != kNoSlot) {
        // The VkImageView and its bindless slot go once the frames whose descriptors may name them are finished.
        Deferred d;
        d.tracked = std::move(rec.tracked);
        d.view = rec.view;
        d.bindlessSlot = rec.bindlessSlot;
        defer(std::move(d));
    }
}

ResourceState VulkanDevice::state(View view) const {
    std::lock_guard<std::mutex> lock(resMutex_);
    const ViewRecord* r = views_.get(view.id);
    if (!r) return ResourceState::Invalid;
    return r->tracked ? ResourceState::Valid : ResourceState::Failed;
}

// ---------------------------------------------------------------------------------------------------------------------
// Samplers
// ---------------------------------------------------------------------------------------------------------------------

Sampler VulkanDevice::make_sampler(const SamplerDesc& desc) {
    const std::string label = label_of(desc.label);
    auto filter = [](Filter f) { return f == Filter::Linear ? VK_FILTER_LINEAR : VK_FILTER_NEAREST; };
    auto wrap = [](Wrap w) {
        switch (w) {
            case Wrap::ClampToEdge: return VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
            case Wrap::ClampToBorder: return VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER;
            case Wrap::MirroredRepeat: return VK_SAMPLER_ADDRESS_MODE_MIRRORED_REPEAT;
            default: return VK_SAMPLER_ADDRESS_MODE_REPEAT;
        }
    };
    const bool comparison = desc.compare != CompareFunc::Default && desc.compare != CompareFunc::Never;
    const float most = std::clamp(props_.limits.maxSamplerAnisotropy, 1.0f, 16.0f);
    const float anisotropy = std::clamp(float(std::clamp<std::uint32_t>(desc.maxAnisotropy, 1u, 16u)), 1.0f, most);
    VkSamplerCreateInfo s{};
    s.sType = VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO;
    s.magFilter = filter(desc.magFilter);
    s.minFilter = filter(desc.minFilter);
    s.mipmapMode = desc.mipmapFilter == Filter::Linear ? VK_SAMPLER_MIPMAP_MODE_LINEAR : VK_SAMPLER_MIPMAP_MODE_NEAREST;
    s.addressModeU = wrap(desc.wrapU);
    s.addressModeV = wrap(desc.wrapV);
    s.addressModeW = wrap(desc.wrapW);
    s.mipLodBias = 0.0f;
    s.anisotropyEnable = anisotropy_ && anisotropy > 1.0f ? VK_TRUE : VK_FALSE;
    s.maxAnisotropy = s.anisotropyEnable ? anisotropy : 1.0f;
    s.compareEnable = comparison ? VK_TRUE : VK_FALSE;
    // CompareFunc's values are VkCompareOp's plus one (Never = 1 .. Always = 8)
    s.compareOp = comparison ? VkCompareOp(std::uint32_t(desc.compare) - 1u) : VK_COMPARE_OP_NEVER;
    s.minLod = desc.minLod;
    s.maxLod = desc.maxLod == 0.0f ? VK_LOD_CLAMP_NONE : desc.maxLod;
    switch (desc.borderColor) {
        case BorderColor::TransparentBlack: s.borderColor = VK_BORDER_COLOR_FLOAT_TRANSPARENT_BLACK; break;
        case BorderColor::OpaqueWhite: s.borderColor = VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE; break;
        default: s.borderColor = VK_BORDER_COLOR_FLOAT_OPAQUE_BLACK; break;
    }
    s.unnormalizedCoordinates = VK_FALSE;

    SamplerRecord rec;
    std::string error;
    if (desc.maxLod != 0.0f && desc.maxLod < desc.minLod)
        error = "maxLod " + std::to_string(desc.maxLod) + " is below minLod " + std::to_string(desc.minLod) +
                " (hint: 0 = no limit)";
    if (error.empty()) {
        const VkResult r = fn_.vkCreateSampler(device_, &s, nullptr, &rec.sampler);
        if (r != VK_SUCCESS) {
            rec.sampler = VK_NULL_HANDLE;
            error = "vkCreateSampler failed with " + result_text(r) +
                    (r == VK_ERROR_TOO_MANY_OBJECTS
                         ? " (hint: the device has maxSamplerAllocationCount samplers already: share samplers)"
                         : " (hint: the validation layer (VulkanOptions::validation) says which field is wrong)");
        } else {
            set_name(VK_OBJECT_TYPE_SAMPLER, handle_bits(rec.sampler), label.c_str());
        }
    }
    if (!error.empty()) report("gpu vulkan: make_sampler '" + label + "': " + error);
    const VkSampler made = rec.sampler;
    std::lock_guard<std::mutex> lock(resMutex_);
    const std::uint32_t id = samplers_.add(std::move(rec));
    if (id == 0) {
        if (made) fn_.vkDestroySampler(device_, made, nullptr);
        report("gpu vulkan: make_sampler '" + label + "': the sampler pool is full (" +
               std::to_string(samplers_.capacity()) +
               " samplers) (hint: share samplers, or raise DeviceInit::samplerPoolSize)");
        return {};
    }
    count_make(stats_.samplers, made != VK_NULL_HANDLE);
    return Sampler{id};
}

void VulkanDevice::destroy_sampler(Sampler sampler) {
    if (!sampler.valid()) return;
    SamplerRecord rec;
    {
        std::lock_guard<std::mutex> lock(resMutex_);
        if (!samplers_.remove(sampler.id, rec)) {
            report("gpu vulkan: destroy_sampler: sampler " + std::to_string(sampler.id) +
                   " names nothing (hint: it was destroyed already, or another device made it)");
            return;
        }
        count_destroy(stats_.samplers);
    }
    if (rec.sampler) {
        Deferred d;
        d.sampler = rec.sampler;
        defer(std::move(d));
    }
}

ResourceState VulkanDevice::state(Sampler sampler) const {
    std::lock_guard<std::mutex> lock(resMutex_);
    const SamplerRecord* r = samplers_.get(sampler.id);
    if (!r) return ResourceState::Invalid;
    return r->sampler ? ResourceState::Valid : ResourceState::Failed;
}

}  // namespace fa::gpu::vk

#endif  // FA_VULKAN_BACKEND
