// The D3D12 backend's resources: formats, buffers, images, views, samplers, their states and native objects
// (docs/design/ARCHITECTURE_RENDERING_GPU.md, "D3D12 backend").
#include <algorithm>
#include <cstring>
#include <memory>
#include <string>
#include <utility>

#include "gpu/d3d12_device.h"

namespace fa::gpu::d3d12 {

namespace {

// D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING (r, g, b, a in order): not every SDK's headers define the macro.
constexpr UINT kDefaultMapping = 0x1688;
// D3D12_ENCODE_BASIC_FILTER and D3D12_FILTER_ANISOTROPIC with a reduction (1 = comparison), for the same reason.
constexpr UINT basic_filter(UINT min, UINT mag, UINT mip, UINT reduction) {
    return (min << 4) | (mag << 2) | mip | (reduction << 7);
}
constexpr UINT anisotropic_filter(UINT reduction) { return 0x55u | (reduction << 7); }

std::string label_of(const char* label) { return label && *label ? std::string(label) : std::string("(no label)"); }

D3D12_RESOURCE_DESC buffer_desc(std::uint64_t bytes, D3D12_RESOURCE_FLAGS flags) {
    D3D12_RESOURCE_DESC d{};
    d.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
    d.Width = bytes;
    d.Height = 1;
    d.DepthOrArraySize = 1;
    d.MipLevels = 1;
    d.Format = DXGI_FORMAT_UNKNOWN;
    d.SampleDesc.Count = 1;
    d.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
    d.Flags = flags;
    return d;
}

int max_mips(int w, int h, int d) {
    int largest = std::max(w, std::max(h, d));
    int n = 1;
    while (largest > 1) {
        largest >>= 1;
        ++n;
    }
    return n;
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// Formats
// ---------------------------------------------------------------------------------------------------------------------

FormatInfo format_info(PixelFormat f) {
    auto same = [](DXGI_FORMAT x) {
        FormatInfo i;
        i.resource = i.srv = i.rtv = x;
        return i;
    };
    auto bc = [](DXGI_FORMAT x, std::uint32_t bytes) {
        FormatInfo i;
        i.resource = i.srv = x;
        i.blockBytes = bytes;
        return i;
    };
    switch (f) {
        case PixelFormat::R8: return same(DXGI_FORMAT_R8_UNORM);
        case PixelFormat::R8Sn: return same(DXGI_FORMAT_R8_SNORM);
        case PixelFormat::R8Ui: return same(DXGI_FORMAT_R8_UINT);
        case PixelFormat::R8Si: return same(DXGI_FORMAT_R8_SINT);
        case PixelFormat::R16: return same(DXGI_FORMAT_R16_UNORM);
        case PixelFormat::R16Sn: return same(DXGI_FORMAT_R16_SNORM);
        case PixelFormat::R16Ui: return same(DXGI_FORMAT_R16_UINT);
        case PixelFormat::R16Si: return same(DXGI_FORMAT_R16_SINT);
        case PixelFormat::R16F: return same(DXGI_FORMAT_R16_FLOAT);
        case PixelFormat::Rg8: return same(DXGI_FORMAT_R8G8_UNORM);
        case PixelFormat::Rg8Sn: return same(DXGI_FORMAT_R8G8_SNORM);
        case PixelFormat::Rg8Ui: return same(DXGI_FORMAT_R8G8_UINT);
        case PixelFormat::Rg8Si: return same(DXGI_FORMAT_R8G8_SINT);
        case PixelFormat::R32Ui: return same(DXGI_FORMAT_R32_UINT);
        case PixelFormat::R32Si: return same(DXGI_FORMAT_R32_SINT);
        case PixelFormat::R32F: return same(DXGI_FORMAT_R32_FLOAT);
        case PixelFormat::Rg16: return same(DXGI_FORMAT_R16G16_UNORM);
        case PixelFormat::Rg16Sn: return same(DXGI_FORMAT_R16G16_SNORM);
        case PixelFormat::Rg16Ui: return same(DXGI_FORMAT_R16G16_UINT);
        case PixelFormat::Rg16Si: return same(DXGI_FORMAT_R16G16_SINT);
        case PixelFormat::Rg16F: return same(DXGI_FORMAT_R16G16_FLOAT);
        case PixelFormat::Rgba8: return same(DXGI_FORMAT_R8G8B8A8_UNORM);
        case PixelFormat::Srgb8A8: return same(DXGI_FORMAT_R8G8B8A8_UNORM_SRGB);
        case PixelFormat::Rgba8Sn: return same(DXGI_FORMAT_R8G8B8A8_SNORM);
        case PixelFormat::Rgba8Ui: return same(DXGI_FORMAT_R8G8B8A8_UINT);
        case PixelFormat::Rgba8Si: return same(DXGI_FORMAT_R8G8B8A8_SINT);
        case PixelFormat::Bgra8: return same(DXGI_FORMAT_B8G8R8A8_UNORM);
        case PixelFormat::Sbgr8A8: return same(DXGI_FORMAT_B8G8R8A8_UNORM_SRGB);
        case PixelFormat::Rgb10A2: return same(DXGI_FORMAT_R10G10B10A2_UNORM);
        case PixelFormat::Rg11B10F: return same(DXGI_FORMAT_R11G11B10_FLOAT);
        case PixelFormat::Rgb9E5: return same(DXGI_FORMAT_R9G9B9E5_SHAREDEXP);
        case PixelFormat::Rg32Ui: return same(DXGI_FORMAT_R32G32_UINT);
        case PixelFormat::Rg32Si: return same(DXGI_FORMAT_R32G32_SINT);
        case PixelFormat::Rg32F: return same(DXGI_FORMAT_R32G32_FLOAT);
        case PixelFormat::Rgba16: return same(DXGI_FORMAT_R16G16B16A16_UNORM);
        case PixelFormat::Rgba16Sn: return same(DXGI_FORMAT_R16G16B16A16_SNORM);
        case PixelFormat::Rgba16Ui: return same(DXGI_FORMAT_R16G16B16A16_UINT);
        case PixelFormat::Rgba16Si: return same(DXGI_FORMAT_R16G16B16A16_SINT);
        case PixelFormat::Rgba16F: return same(DXGI_FORMAT_R16G16B16A16_FLOAT);
        case PixelFormat::Rgba32Ui: return same(DXGI_FORMAT_R32G32B32A32_UINT);
        case PixelFormat::Rgba32Si: return same(DXGI_FORMAT_R32G32B32A32_SINT);
        case PixelFormat::Rgba32F: return same(DXGI_FORMAT_R32G32B32A32_FLOAT);
        case PixelFormat::Depth: {
            FormatInfo i;
            i.resource = DXGI_FORMAT_R32_TYPELESS;  // typeless, so a shader can sample it as R32_FLOAT
            i.srv = DXGI_FORMAT_R32_FLOAT;
            i.rtv = DXGI_FORMAT_D32_FLOAT;
            return i;
        }
        case PixelFormat::DepthStencil: {
            FormatInfo i;
            i.resource = DXGI_FORMAT_R24G8_TYPELESS;
            i.srv = DXGI_FORMAT_R24_UNORM_X8_TYPELESS;
            i.rtv = DXGI_FORMAT_D24_UNORM_S8_UINT;
            i.planes = 2;
            return i;
        }
        case PixelFormat::Bc1Rgba: return bc(DXGI_FORMAT_BC1_UNORM, 8);
        case PixelFormat::Bc2Rgba: return bc(DXGI_FORMAT_BC2_UNORM, 16);
        case PixelFormat::Bc3Rgba: return bc(DXGI_FORMAT_BC3_UNORM, 16);
        case PixelFormat::Bc3Srgba: return bc(DXGI_FORMAT_BC3_UNORM_SRGB, 16);
        case PixelFormat::Bc4R: return bc(DXGI_FORMAT_BC4_UNORM, 8);
        case PixelFormat::Bc4RSn: return bc(DXGI_FORMAT_BC4_SNORM, 8);
        case PixelFormat::Bc5Rg: return bc(DXGI_FORMAT_BC5_UNORM, 16);
        case PixelFormat::Bc5RgSn: return bc(DXGI_FORMAT_BC5_SNORM, 16);
        case PixelFormat::Bc6hRgbF: return bc(DXGI_FORMAT_BC6H_SF16, 16);
        case PixelFormat::Bc6hRgbUf: return bc(DXGI_FORMAT_BC6H_UF16, 16);
        case PixelFormat::Bc7Rgba: return bc(DXGI_FORMAT_BC7_UNORM, 16);
        case PixelFormat::Bc7Srgba: return bc(DXGI_FORMAT_BC7_UNORM_SRGB, 16);
        default: return {};  // ETC2, EAC and ASTC do not exist on D3D12
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

// ---------------------------------------------------------------------------------------------------------------------
// Buffers
// ---------------------------------------------------------------------------------------------------------------------

Buffer D3d12Device::make_buffer(const BufferDesc& desc) {
    const std::string label = label_of(desc.label);
    BufferRecord rec;
    rec.size = desc.size;
    rec.usage = desc.usage;
    rec.label = label;
    std::string error;
    if (desc.size == 0)
        error = "size is 0 (hint: give BufferDesc::size the buffer's bytes)";
    else if (desc.data.ptr && desc.data.size > desc.size)
        error = "its initial data has " + std::to_string(desc.data.size) + " bytes, more than its size " +
                std::to_string(desc.size) + " (hint: BufferDesc::size is the buffer's bytes, at least data.size)";
    const BufferUsage& u = desc.usage;
    const bool accelUsage = u.accelBuildInput || u.accelStorage || u.accelScratch;
    if (error.empty() && accelUsage && !features_.accelerationStructure) {
        error = "usage.accelBuildInput, accelStorage or accelScratch on a device without acceleration structures "
                "(Features::accelerationStructure is false: " +
                (rtWhy_.empty() ? std::string("this device has no ray query") : rtWhy_) +
                ") (hint: check Device::features().accelerationStructure first)";
    } else if (error.empty() && u.accelStorage) {
        // D3D12 makes an acceleration structure's buffer in its own state and never moves it out of it.
        const bool other = u.vertexBuffer || u.indexBuffer || u.storageBuffer || u.stagingBuffer ||
                           u.stagingIndexBuffer || u.writeUnsealed || u.writeTransient || u.copySrc || u.copyDst ||
                           u.accelBuildInput || u.accelScratch;
        if (other || desc.data.ptr)
            error = std::string("usage.accelStorage with ") + (other ? "another usage" : "initial data") +
                    ": D3D12 keeps an acceleration structure's buffer in the acceleration structure state, which "
                    "nothing else may use (hint: make the storage buffer with usage.accelStorage only and no data; "
                    "builds write it)";
    }
    if (error.empty()) {
        const bool uav = u.storageBuffer || u.accelStorage || u.accelScratch;
        const D3D12_RESOURCE_DESC d = buffer_desc(
            align_up(desc.size, 256), uav ? D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS : D3D12_RESOURCE_FLAG_NONE);
        const D3D12_RESOURCE_STATES initial =
            u.accelStorage ? D3D12_RESOURCE_STATE_RAYTRACING_ACCELERATION_STRUCTURE : D3D12_RESOURCE_STATE_COMMON;
        Com<ID3D12Resource> r = make_committed(d, D3D12_HEAP_TYPE_DEFAULT, initial, "make_buffer", label.c_str());
        if (r) {
            auto t = std::make_shared<TrackedResource>();
            t->resource = std::move(r);
            t->states.assign(1, StateBits(initial));
            t->buffer = true;
            t->accel = u.accelStorage;
            // Unnamed: empty, so the ownership errors say "an unnamed buffer" (TrackedResource::display_name).
            t->label = desc.label && *desc.label ? "buffer '" + label + "'" : std::string();
            rec.tracked = std::move(t);
        }
    } else {
        report("gpu d3d12: make_buffer '" + label + "': " + error);
    }
    if (rec.tracked && desc.data.ptr && desc.data.size > 0) {
        std::shared_ptr<TrackedResource> t = rec.tracked;
        std::lock_guard<std::mutex> lock(queueMutex_);
        D3d12CommandList& p = prelude();
        if (p.open_) {
            const UploadAlloc a = upload(desc.data.size, 16, &p);
            if (a.ok()) {
                std::memcpy(a.cpu, desc.data.ptr, desc.data.size);
                if (p.require(
                        t, 0,
                        D3D12_RESOURCE_STATE_COPY_DEST)) {  // false: reported, no copy into acceleration structures
                    p.flush_barriers();
                    p.list_->CopyBufferRegion(t->resource.get(), 0, a.resource, a.offset, desc.data.size);
                    p.empty_ = false;
                }
            }
        }
    }
    std::lock_guard<std::mutex> lock(resMutex_);
    const bool ok = rec.tracked != nullptr;
    const std::uint32_t id = buffers_.add(std::move(rec));
    if (id == 0) {
        report("gpu d3d12: make_buffer '" + label + "': the buffer pool is full (" +
               std::to_string(buffers_.capacity()) +
               " buffers) (hint: destroy buffers you no longer use, or raise DeviceInit::bufferPoolSize)");
        return {};
    }
    count_make(stats_.buffers, ok);
    return Buffer{id};
}

void D3d12Device::destroy_buffer(Buffer buffer) {
    if (!buffer.valid()) return;
    BufferRecord rec;
    {
        std::lock_guard<std::mutex> lock(resMutex_);
        if (!buffers_.remove(buffer.id, rec)) {
            report("gpu d3d12: destroy_buffer: buffer " + std::to_string(buffer.id) +
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

ResourceState D3d12Device::state(Buffer buffer) const {
    std::lock_guard<std::mutex> lock(resMutex_);
    const BufferRecord* r = buffers_.get(buffer.id);
    if (!r) return ResourceState::Invalid;
    return r->tracked ? ResourceState::Valid : ResourceState::Failed;
}

std::shared_ptr<TrackedResource> D3d12Device::buffer_tracked(Buffer b, std::size_t* size, std::string* label) const {
    std::lock_guard<std::mutex> lock(resMutex_);
    const BufferRecord* r = buffers_.get(b.id);
    if (!r) return nullptr;
    if (size) *size = r->size;
    if (label) *label = r->label;
    return r->tracked;
}

NativeBuffer D3d12Device::native_buffer(Buffer buffer) const {
    NativeBuffer n;
    if (auto t = buffer_tracked(buffer, nullptr, nullptr)) n.buffer = t->resource.get();  // ID3D12Resource*
    return n;
}

// ---------------------------------------------------------------------------------------------------------------------
// Images
// ---------------------------------------------------------------------------------------------------------------------

Image D3d12Device::make_image(const ImageDesc& desc) {
    const std::string label = label_of(desc.label);
    const ImageUsage& u = desc.usage;
    const bool attachment = u.colorAttachment || u.resolveAttachment || u.depthStencilAttachment;
    ImageRecord rec;
    rec.type = desc.type == ImageType::Default ? ImageType::Tex2d : desc.type;
    rec.usage = u;
    rec.label = label;
    rec.format = desc.pixelFormat;
    if (rec.format == PixelFormat::Default)
        rec.format = u.depthStencilAttachment                     ? defaults_.depthFormat
                     : (u.colorAttachment || u.resolveAttachment) ? defaults_.colorFormat
                                                                  : PixelFormat::Rgba8;
    rec.width = desc.width;
    rec.height = desc.height;
    rec.slices = desc.numSlices > 0 ? desc.numSlices : (rec.type == ImageType::Cube ? 6 : 1);
    rec.mips = desc.numMipmaps > 0 ? desc.numMipmaps : 1;
    rec.samples = desc.sampleCount > 0 ? desc.sampleCount : (attachment ? defaults_.sampleCount : 1);
    const FormatInfo fi = format_info(rec.format);
    const bool depth = pixel_format_depth(rec.format);
    const bool is3d = rec.type == ImageType::Tex3d;
    const int maxSize = is3d ? limits_.maxImageSize3d : limits_.maxImageSize2d;

    std::string error;
    if (rec.width < 1 || rec.height < 1 || rec.width > maxSize || rec.height > maxSize)
        error = "its size " + std::to_string(rec.width) + "x" + std::to_string(rec.height) + " is outside 1.." +
                std::to_string(maxSize) + " (hint: give ImageDesc::width and height)";
    else if (fi.resource == DXGI_FORMAT_UNKNOWN)
        error = std::string("pixel format ") + pixel_format_name(rec.format) +
                " does not exist on Direct3D 12 (hint: ETC2, EAC and ASTC are mobile formats: ship BC1-BC7 for "
                "Windows)";
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
    else if (u.storageImage && !caps_[std::size_t(rec.format)].write)
        error = std::string("pixel format ") + pixel_format_name(rec.format) +
                " cannot be a storage image on this GPU (usage storageImage needs typed UAV stores) (hint: " +
                (rec.format == PixelFormat::Srgb8A8 || rec.format == PixelFormat::Sbgr8A8
                     ? std::string("write the UNORM format Rgba8 and encode sRGB in the shader")
                     : std::string("use Rgba8, Rgba16F or R32F, which every D3D12 GPU writes")) +
                "; pixel_format_caps(format).write says which formats can)";
    if (!error.empty()) report("gpu d3d12: make_image '" + label + "': " + error);

    if (error.empty()) {
        D3D12_RESOURCE_DESC d{};
        d.Dimension = is3d ? D3D12_RESOURCE_DIMENSION_TEXTURE3D : D3D12_RESOURCE_DIMENSION_TEXTURE2D;
        d.Width = UINT64(rec.width);
        d.Height = UINT(rec.height);
        d.DepthOrArraySize = UINT16(rec.slices);
        d.MipLevels = UINT16(rec.mips);
        d.Format = fi.resource;
        d.SampleDesc.Count = UINT(rec.samples);
        d.Layout = D3D12_TEXTURE_LAYOUT_UNKNOWN;
        if (u.colorAttachment || u.resolveAttachment) d.Flags |= D3D12_RESOURCE_FLAG_ALLOW_RENDER_TARGET;
        if (u.depthStencilAttachment) d.Flags |= D3D12_RESOURCE_FLAG_ALLOW_DEPTH_STENCIL;
        if (u.storageImage) d.Flags |= D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;
        Com<ID3D12Resource> r =
            make_committed(d, D3D12_HEAP_TYPE_DEFAULT, D3D12_RESOURCE_STATE_COMMON, "make_image", label.c_str());
        if (r) {
            auto t = std::make_shared<TrackedResource>();
            t->resource = std::move(r);
            t->mips = std::uint32_t(rec.mips);
            t->layers = is3d ? 1u : std::uint32_t(rec.slices);
            t->planes = fi.planes;
            t->states.assign(t->subresource_count(), StateBits(D3D12_RESOURCE_STATE_COMMON));
            t->label =
                desc.label && *desc.label ? "image '" + label + "'" : std::string();  // empty: "an unnamed image"
            rec.tracked = std::move(t);
        }
    }
    if (rec.tracked) upload_initial_image(rec, desc);

    std::lock_guard<std::mutex> lock(resMutex_);
    const bool ok = rec.tracked != nullptr;
    const std::uint32_t id = images_.add(std::move(rec));
    if (id == 0) {
        report("gpu d3d12: make_image '" + label + "': the image pool is full (" + std::to_string(images_.capacity()) +
               " images) (hint: destroy images you no longer use, or raise DeviceInit::imagePoolSize)");
        return {};
    }
    count_make(stats_.images, ok);
    return Image{id};
}

void D3d12Device::upload_initial_image(const ImageRecord& rec, const ImageDesc& desc) {
    bool any = false;
    for (int m = 0; m < rec.mips; ++m)
        if (desc.data.mipLevels[m].ptr) any = true;
    if (!any) return;
    if (pixel_format_depth(rec.format) || rec.samples > 1) {
        report("gpu d3d12: make_image '" + rec.label +
               "': a depth or multisampled image has no initial data (hint: draw into it instead)");
        return;
    }
    const bool is3d = rec.type == ImageType::Tex3d;
    std::lock_guard<std::mutex> lock(queueMutex_);
    D3d12CommandList& p = prelude();
    if (!p.open_) return;
    for (int m = 0; m < rec.mips; ++m) {
        const Range& data = desc.data.mipLevels[m];
        if (!data.ptr) continue;
        const std::uint32_t w = mip_extent(rec.width, m), h = mip_extent(rec.height, m);
        const std::uint32_t count = is3d ? mip_extent(rec.slices, m) : std::uint32_t(rec.slices);
        const std::size_t rowPitch = texel_row_bytes(rec.format, w);
        const std::size_t slicePitch = rowPitch * texel_rows(rec.format, h);
        if (data.size < slicePitch * count) {
            report("gpu d3d12: make_image '" + rec.label + "': mip " + std::to_string(m) + " has " +
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

void D3d12Device::destroy_image(Image image) {
    if (!image.valid()) return;
    ImageRecord rec;
    {
        std::lock_guard<std::mutex> lock(resMutex_);
        if (!images_.remove(image.id, rec)) {
            report("gpu d3d12: destroy_image: image " + std::to_string(image.id) +
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

ResourceState D3d12Device::state(Image image) const {
    std::lock_guard<std::mutex> lock(resMutex_);
    const ImageRecord* r = images_.get(image.id);
    if (!r) return ResourceState::Invalid;
    return r->tracked ? ResourceState::Valid : ResourceState::Failed;
}

bool D3d12Device::image_info(Image image, ImageRecord& out) const {
    std::lock_guard<std::mutex> lock(resMutex_);
    const ImageRecord* r = images_.get(image.id);
    if (!r || !r->tracked) return false;
    out = *r;
    return true;
}

NativeImage D3d12Device::native_image(Image image) const {
    NativeImage n;
    std::lock_guard<std::mutex> lock(resMutex_);
    const ImageRecord* r = images_.get(image.id);
    if (r && r->tracked) {
        n.texture = n.resource = r->tracked->resource.get();  // ID3D12Resource*
        n.nativeFormat = std::uint32_t(format_info(r->format).resource);
    }
    return n;
}

NativeView D3d12Device::native_view(View view) const {
    NativeView n;
    std::lock_guard<std::mutex> lock(resMutex_);
    const ViewRecord* v = views_.get(view.id);
    if (!v || !v->tracked) return n;
    if (v->heap >= 0 && v->descriptor != kNoDescriptor)
        n.d3d12Descriptor = std::uint64_t(cpuHeaps_[std::size_t(v->heap)].cpu(v->descriptor).ptr);
    n.image = v->image;
    n.mip = v->mip;
    n.mipCount = v->mipCount;
    n.slice = v->slice;
    n.sliceCount = v->sliceCount;
    if (v->type == ViewType::StorageBuffer) {
        n.nativeFormat = std::uint32_t(DXGI_FORMAT_R32_TYPELESS);  // the raw SRV
    } else if (const ImageRecord* im = v->image.id ? images_.get(v->image.id) : nullptr) {
        const FormatInfo fi = format_info(im->format);
        const bool attachment = v->type == ViewType::ColorAttachment || v->type == ViewType::ResolveAttachment ||
                                v->type == ViewType::DepthStencilAttachment;
        n.nativeFormat = std::uint32_t(attachment ? fi.rtv : fi.srv);
    }
    return n;
}

// ---------------------------------------------------------------------------------------------------------------------
// Views
// ---------------------------------------------------------------------------------------------------------------------

View D3d12Device::make_view(const ViewDesc& desc) {
    const std::string label = label_of(desc.label);
    ViewRecord rec;
    rec.type = desc.type();
    std::string error;
    auto fail = [&](const std::string& e) {
        if (error.empty()) error = e;
    };
    auto take = [&](HeapIndex heap) -> std::uint32_t {
        const std::uint32_t i = cpuHeaps_[heap].alloc();
        if (i == kNoDescriptor)
            fail(std::string("the CPU ") + cpuHeaps_[heap].name() + " descriptor heap is full (" +
                 std::to_string(cpuHeaps_[heap].capacity()) +
                 " descriptors) (hint: destroy views you do not use, or raise D3d12Options::cpu" +
                 (heap == kHeapView  ? "View"
                  : heap == kHeapRtv ? "Rtv"
                                     : "Dsv") +
                 "Descriptors)");
        return i;
    };

    std::lock_guard<std::mutex> lock(resMutex_);
    const int resources = desc.resource_count();
    if (resources != 1)
        fail("a ViewDesc names exactly one resource (this one names " + std::to_string(resources) +
             ") (hint: set one of texture, storageBuffer, storageImage, colorAttachment, resolveAttachment, "
             "depthStencilAttachment)");

    ID3D12Device* dev = device_.get();
    if (error.empty() && rec.type == ViewType::StorageBuffer) {
        const BufferRecord* b = buffers_.get(desc.storageBuffer.buffer.id);
        const int offset = desc.storageBuffer.offset;
        if (!b || !b->tracked)
            fail("its buffer " + std::to_string(desc.storageBuffer.buffer.id) + " is not a live buffer");
        else if (!b->usage.storageBuffer)
            fail("buffer '" + b->label + "' was not made with BufferUsage::storageBuffer");
        else if (desc.storageBuffer.structureStride > 2048)
            fail("structureStride " + std::to_string(desc.storageBuffer.structureStride) +
                 " is above 2048, the most D3D12 allows for the element of a structured buffer (hint: split the "
                 "element, or use a raw view with structureStride 0 and read the words yourself)");
        else if (desc.storageBuffer.structureStride < 0 || desc.storageBuffer.structureStride % 4 != 0 ||
                 (desc.storageBuffer.structureStride > 0 && offset % desc.storageBuffer.structureStride != 0))
            fail("structureStride " + std::to_string(desc.storageBuffer.structureStride) +
                 " is not 0 (a raw view) or a multiple of 4 that divides the offset " + std::to_string(offset));
        else if (offset < 0 || offset % 16 != 0 || std::size_t(offset) + 4 > b->size)
            fail("offset " + std::to_string(offset) + " is not a multiple of 16 inside the buffer's " +
                 std::to_string(b->size) +
                 " bytes (hint: D3D12 raw views start on 16 bytes; 256 suits every "
                 "backend)");
        if (error.empty()) {
            rec.buffer = desc.storageBuffer.buffer;
            rec.tracked = b->tracked;
            rec.heap = kHeapView;
            // A raw view counts 4 byte words; a structured one (the shader declares StructuredBuffer<T>) counts elements.
            const UINT stride = UINT(desc.storageBuffer.structureStride);
            const UINT unit = stride ? stride : 4u;
            const UINT first = UINT(std::size_t(offset) / unit);
            const UINT count = UINT((b->size - std::size_t(offset)) / unit);
            rec.descriptor = take(kHeapView);
            if (error.empty()) rec.uavDescriptor = take(kHeapView);
            if (error.empty()) {
                D3D12_SHADER_RESOURCE_VIEW_DESC s{};
                s.Format = stride ? DXGI_FORMAT_UNKNOWN : DXGI_FORMAT_R32_TYPELESS;
                s.ViewDimension = D3D12_SRV_DIMENSION_BUFFER;
                s.Shader4ComponentMapping = kDefaultMapping;
                s.Buffer.FirstElement = first;
                s.Buffer.NumElements = count;
                s.Buffer.StructureByteStride = stride;
                s.Buffer.Flags = stride ? D3D12_BUFFER_SRV_FLAG_NONE : D3D12_BUFFER_SRV_FLAG_RAW;
                dev->CreateShaderResourceView(rec.tracked->resource.get(), &s,
                                              cpuHeaps_[kHeapView].cpu(rec.descriptor));
                D3D12_UNORDERED_ACCESS_VIEW_DESC v{};
                v.Format = stride ? DXGI_FORMAT_UNKNOWN : DXGI_FORMAT_R32_TYPELESS;
                v.ViewDimension = D3D12_UAV_DIMENSION_BUFFER;
                v.Buffer.FirstElement = first;
                v.Buffer.NumElements = count;
                v.Buffer.StructureByteStride = stride;
                v.Buffer.Flags = stride ? D3D12_BUFFER_UAV_FLAG_NONE : D3D12_BUFFER_UAV_FLAG_RAW;
                dev->CreateUnorderedAccessView(rec.tracked->resource.get(), nullptr, &v,
                                               cpuHeaps_[kHeapView].cpu(rec.uavDescriptor));
            }
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
            rec.image = image;
            rec.tracked = im->tracked;
            rec.mip = mip;
            rec.mipCount = mipCount;
            rec.slice = slice;
            rec.sliceCount = sliceCount;
            const FormatInfo fi = format_info(im->format);
            const bool ms = im->samples > 1;
            const bool layered = im->type == ImageType::Array || im->type == ImageType::Cube;
            ID3D12Resource* res = im->tracked->resource.get();
            if (error.empty() && rec.type == ViewType::Texture) {
                rec.heap = kHeapView;
                rec.descriptor = take(kHeapView);
                if (error.empty()) {
                    D3D12_SHADER_RESOURCE_VIEW_DESC s{};
                    s.Format = fi.srv;
                    s.Shader4ComponentMapping = kDefaultMapping;
                    if (is3d) {
                        s.ViewDimension = D3D12_SRV_DIMENSION_TEXTURE3D;
                        s.Texture3D.MostDetailedMip = UINT(mip);
                        s.Texture3D.MipLevels = UINT(mipCount);
                    } else if (im->type == ImageType::Cube && slice == 0 && sliceCount == 6) {
                        s.ViewDimension = D3D12_SRV_DIMENSION_TEXTURECUBE;
                        s.TextureCube.MostDetailedMip = UINT(mip);
                        s.TextureCube.MipLevels = UINT(mipCount);
                    } else if (!layered && ms) {
                        s.ViewDimension = D3D12_SRV_DIMENSION_TEXTURE2DMS;
                    } else if (!layered) {
                        s.ViewDimension = D3D12_SRV_DIMENSION_TEXTURE2D;
                        s.Texture2D.MostDetailedMip = UINT(mip);
                        s.Texture2D.MipLevels = UINT(mipCount);
                    } else if (ms) {
                        s.ViewDimension = D3D12_SRV_DIMENSION_TEXTURE2DMSARRAY;
                        s.Texture2DMSArray.FirstArraySlice = UINT(slice);
                        s.Texture2DMSArray.ArraySize = UINT(sliceCount);
                    } else {
                        s.ViewDimension = D3D12_SRV_DIMENSION_TEXTURE2DARRAY;
                        s.Texture2DArray.MostDetailedMip = UINT(mip);
                        s.Texture2DArray.MipLevels = UINT(mipCount);
                        s.Texture2DArray.FirstArraySlice = UINT(slice);
                        s.Texture2DArray.ArraySize = UINT(sliceCount);
                    }
                    dev->CreateShaderResourceView(res, &s, cpuHeaps_[kHeapView].cpu(rec.descriptor));
                    // Its slot in the bindless table (kNoBindlessIndex when there is none or it is full).
                    rec.bindless = take_bindless(cpuHeaps_[kHeapView].cpu(rec.descriptor));
                }
            } else if (error.empty() && rec.type == ViewType::StorageImage) {
                rec.heap = kHeapView;
                rec.descriptor = take(kHeapView);
                if (error.empty()) {
                    D3D12_UNORDERED_ACCESS_VIEW_DESC v{};
                    v.Format = fi.srv;
                    if (is3d) {
                        v.ViewDimension = D3D12_UAV_DIMENSION_TEXTURE3D;
                        v.Texture3D.MipSlice = UINT(mip);
                        v.Texture3D.FirstWSlice = UINT(slice);
                        v.Texture3D.WSize = 1;
                    } else if (layered) {
                        v.ViewDimension = D3D12_UAV_DIMENSION_TEXTURE2DARRAY;
                        v.Texture2DArray.MipSlice = UINT(mip);
                        v.Texture2DArray.FirstArraySlice = UINT(slice);
                        v.Texture2DArray.ArraySize = 1;
                    } else {
                        v.ViewDimension = D3D12_UAV_DIMENSION_TEXTURE2D;
                        v.Texture2D.MipSlice = UINT(mip);
                    }
                    dev->CreateUnorderedAccessView(res, nullptr, &v, cpuHeaps_[kHeapView].cpu(rec.descriptor));
                }
            } else if (error.empty() && rec.type == ViewType::ColorAttachment) {
                rec.heap = kHeapRtv;
                rec.descriptor = take(kHeapRtv);
                if (error.empty()) {
                    D3D12_RENDER_TARGET_VIEW_DESC v{};
                    v.Format = fi.rtv;
                    if (is3d) {
                        v.ViewDimension = D3D12_RTV_DIMENSION_TEXTURE3D;
                        v.Texture3D.MipSlice = UINT(mip);
                        v.Texture3D.FirstWSlice = UINT(slice);
                        v.Texture3D.WSize = 1;
                    } else if (layered && ms) {
                        v.ViewDimension = D3D12_RTV_DIMENSION_TEXTURE2DMSARRAY;
                        v.Texture2DMSArray.FirstArraySlice = UINT(slice);
                        v.Texture2DMSArray.ArraySize = 1;
                    } else if (layered) {
                        v.ViewDimension = D3D12_RTV_DIMENSION_TEXTURE2DARRAY;
                        v.Texture2DArray.MipSlice = UINT(mip);
                        v.Texture2DArray.FirstArraySlice = UINT(slice);
                        v.Texture2DArray.ArraySize = 1;
                    } else if (ms) {
                        v.ViewDimension = D3D12_RTV_DIMENSION_TEXTURE2DMS;
                    } else {
                        v.ViewDimension = D3D12_RTV_DIMENSION_TEXTURE2D;
                        v.Texture2D.MipSlice = UINT(mip);
                    }
                    dev->CreateRenderTargetView(res, &v, cpuHeaps_[kHeapRtv].cpu(rec.descriptor));
                }
            } else if (error.empty() && rec.type == ViewType::DepthStencilAttachment) {
                rec.heap = kHeapDsv;
                rec.descriptor = take(kHeapDsv);
                if (error.empty()) {
                    D3D12_DEPTH_STENCIL_VIEW_DESC v{};
                    v.Format = fi.rtv;
                    if (layered && ms) {
                        v.ViewDimension = D3D12_DSV_DIMENSION_TEXTURE2DMSARRAY;
                        v.Texture2DMSArray.FirstArraySlice = UINT(slice);
                        v.Texture2DMSArray.ArraySize = 1;
                    } else if (layered) {
                        v.ViewDimension = D3D12_DSV_DIMENSION_TEXTURE2DARRAY;
                        v.Texture2DArray.MipSlice = UINT(mip);
                        v.Texture2DArray.FirstArraySlice = UINT(slice);
                        v.Texture2DArray.ArraySize = 1;
                    } else if (ms) {
                        v.ViewDimension = D3D12_DSV_DIMENSION_TEXTURE2DMS;
                    } else {
                        v.ViewDimension = D3D12_DSV_DIMENSION_TEXTURE2D;
                        v.Texture2D.MipSlice = UINT(mip);
                    }
                    dev->CreateDepthStencilView(res, &v, cpuHeaps_[kHeapDsv].cpu(rec.descriptor));
                }
            }
            // A resolve attachment needs no descriptor: end_pass resolves into the resource.
        }
    }

    if (!error.empty()) {
        report("gpu d3d12: make_view '" + label + "': " + error);
        if (rec.heap >= 0) {
            if (rec.descriptor != kNoDescriptor) cpuHeaps_[std::size_t(rec.heap)].free(rec.descriptor);
            if (rec.uavDescriptor != kNoDescriptor) cpuHeaps_[std::size_t(rec.heap)].free(rec.uavDescriptor);
        }
        if (rec.bindless != kNoBindlessIndex) free_bindless(rec.bindless);
        rec.bindless = kNoBindlessIndex;
        rec.tracked = nullptr;
        rec.heap = -1;
        rec.descriptor = rec.uavDescriptor = kNoDescriptor;
    }
    const bool ok = rec.tracked != nullptr;
    const int heap = rec.heap;
    const std::uint32_t descriptor = rec.descriptor, uavDescriptor = rec.uavDescriptor, bindless = rec.bindless;
    const std::uint32_t id = views_.add(std::move(rec));
    if (id == 0) {
        // The descriptors it took go back: no record holds them.
        if (heap >= 0) {
            if (descriptor != kNoDescriptor) cpuHeaps_[std::size_t(heap)].free(descriptor);
            if (uavDescriptor != kNoDescriptor) cpuHeaps_[std::size_t(heap)].free(uavDescriptor);
        }
        if (bindless != kNoBindlessIndex) free_bindless(bindless);
        report("gpu d3d12: make_view '" + label + "': the view pool is full (" + std::to_string(views_.capacity()) +
               " views) (hint: destroy views you no longer use, or raise DeviceInit::viewPoolSize)");
        return {};
    }
    count_make(stats_.views, ok);
    return View{id};
}

void D3d12Device::destroy_view(View view) {
    if (!view.valid()) return;
    ViewRecord rec;
    {
        std::lock_guard<std::mutex> lock(resMutex_);
        if (!views_.remove(view.id, rec)) {
            report("gpu d3d12: destroy_view: view " + std::to_string(view.id) +
                   " names nothing (hint: it was destroyed already, or another device made it)");
            return;
        }
        count_destroy(stats_.views);
    }
    if (rec.tracked || rec.heap >= 0 || rec.bindless != kNoBindlessIndex) {
        // The descriptors (and the bindless slot) go back once the frames that may have read them are finished.
        Deferred d;
        d.tracked = std::move(rec.tracked);
        d.heap = rec.heap;
        d.descriptor = rec.descriptor;
        d.descriptor2 = rec.uavDescriptor;
        d.bindless = rec.bindless;
        defer(std::move(d));
    }
}

std::uint32_t D3d12Device::bindless_index(View view) const {
    std::lock_guard<std::mutex> lock(resMutex_);
    const ViewRecord* r = views_.get(view.id);
    return r && r->tracked ? r->bindless : kNoBindlessIndex;
}

ResourceState D3d12Device::state(View view) const {
    std::lock_guard<std::mutex> lock(resMutex_);
    const ViewRecord* r = views_.get(view.id);
    if (!r) return ResourceState::Invalid;
    return r->tracked ? ResourceState::Valid : ResourceState::Failed;
}

// ---------------------------------------------------------------------------------------------------------------------
// Samplers
// ---------------------------------------------------------------------------------------------------------------------

Sampler D3d12Device::make_sampler(const SamplerDesc& desc) {
    const std::string label = label_of(desc.label);
    auto filter = [](Filter f) -> UINT { return f == Filter::Linear ? 1u : 0u; };
    auto wrap = [](Wrap w) {
        switch (w) {
            case Wrap::ClampToEdge: return D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
            case Wrap::ClampToBorder: return D3D12_TEXTURE_ADDRESS_MODE_BORDER;
            case Wrap::MirroredRepeat: return D3D12_TEXTURE_ADDRESS_MODE_MIRROR;
            default: return D3D12_TEXTURE_ADDRESS_MODE_WRAP;
        }
    };
    const bool comparison = desc.compare != CompareFunc::Default && desc.compare != CompareFunc::Never;
    const UINT reduction = comparison ? 1u : 0u;
    const UINT anisotropy = std::clamp<std::uint32_t>(desc.maxAnisotropy, 1u, 16u);
    SamplerRecord rec;
    D3D12_SAMPLER_DESC& s = rec.desc;
    s.Filter = D3D12_FILTER(anisotropy > 1 ? anisotropic_filter(reduction)
                                           : basic_filter(filter(desc.minFilter), filter(desc.magFilter),
                                                          filter(desc.mipmapFilter), reduction));
    s.AddressU = wrap(desc.wrapU);
    s.AddressV = wrap(desc.wrapV);
    s.AddressW = wrap(desc.wrapW);
    s.MipLODBias = 0.0f;
    s.MaxAnisotropy = anisotropy;
    // CompareFunc's values are D3D12_COMPARISON_FUNC's (Never = 1 .. Always = 8).
    s.ComparisonFunc = comparison ? D3D12_COMPARISON_FUNC(std::uint32_t(desc.compare)) : D3D12_COMPARISON_FUNC_NEVER;
    const float alpha = desc.borderColor == BorderColor::TransparentBlack ? 0.0f : 1.0f;
    const float rgb = desc.borderColor == BorderColor::OpaqueWhite ? 1.0f : 0.0f;
    s.BorderColor[0] = s.BorderColor[1] = s.BorderColor[2] = rgb;
    s.BorderColor[3] = alpha;
    s.MinLOD = desc.minLod;
    s.MaxLOD = desc.maxLod == 0.0f ? D3D12_FLOAT32_MAX : desc.maxLod;

    std::lock_guard<std::mutex> lock(resMutex_);
    std::string error;
    if (desc.maxLod != 0.0f && desc.maxLod < desc.minLod)
        error = "maxLod " + std::to_string(desc.maxLod) + " is below minLod " + std::to_string(desc.minLod) +
                " (hint: 0 = no limit)";
    if (error.empty()) {
        rec.descriptor = cpuHeaps_[kHeapSampler].alloc();
        if (rec.descriptor == kNoDescriptor)
            error = "the CPU sampler descriptor heap is full (" + std::to_string(cpuHeaps_[kHeapSampler].capacity()) +
                    " descriptors) (hint: share samplers, destroy those you do not use, or raise "
                    "D3d12Options::cpuSamplerDescriptors)";
        else
            device_->CreateSampler(&s, cpuHeaps_[kHeapSampler].cpu(rec.descriptor));
    }
    if (!error.empty()) report("gpu d3d12: make_sampler '" + label + "': " + error);
    const bool ok = rec.descriptor != kNoDescriptor;
    const std::uint32_t descriptor = rec.descriptor;
    const std::uint32_t id = samplers_.add(std::move(rec));
    if (id == 0) {
        if (descriptor != kNoDescriptor) cpuHeaps_[kHeapSampler].free(descriptor);
        report("gpu d3d12: make_sampler '" + label + "': the sampler pool is full (" +
               std::to_string(samplers_.capacity()) +
               " samplers) (hint: share samplers, or raise DeviceInit::samplerPoolSize)");
        return {};
    }
    count_make(stats_.samplers, ok);
    return Sampler{id};
}

void D3d12Device::destroy_sampler(Sampler sampler) {
    if (!sampler.valid()) return;
    SamplerRecord rec;
    {
        std::lock_guard<std::mutex> lock(resMutex_);
        if (!samplers_.remove(sampler.id, rec)) {
            report("gpu d3d12: destroy_sampler: sampler " + std::to_string(sampler.id) +
                   " names nothing (hint: it was destroyed already, or another device made it)");
            return;
        }
        count_destroy(stats_.samplers);
    }
    if (rec.descriptor != kNoDescriptor) {
        Deferred d;
        d.heap = kHeapSampler;
        d.descriptor = rec.descriptor;
        defer(std::move(d));
    }
}

ResourceState D3d12Device::state(Sampler sampler) const {
    std::lock_guard<std::mutex> lock(resMutex_);
    const SamplerRecord* r = samplers_.get(sampler.id);
    if (!r) return ResourceState::Invalid;
    return r->descriptor != kNoDescriptor ? ResourceState::Valid : ResourceState::Failed;
}

}  // namespace fa::gpu::d3d12
