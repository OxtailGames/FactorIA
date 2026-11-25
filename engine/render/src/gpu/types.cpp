// The backend-neutral helpers of gpu/types.h (no sokol here: RecordingDevice and the later backends use them too).
#include "gpu/types.h"

#include <cstddef>
#include <cstdint>

namespace fa::gpu {

namespace {

// What kind of values a format holds.
enum class Kind : std::uint8_t { None, Unorm, Snorm, Uint, Sint, Float, Depth, Compressed };

struct FormatInfo {
    PixelFormat format;  // the row's own format: the table is checked to be in PixelFormat's order
    const char* name;    // sokol's name without the SG_PIXELFORMAT_ prefix
    Kind kind;
    int bytes;  // of one pixel; 0 for None, Default and the compressed formats
};

// One row per PixelFormat, in its order (sokol's).
constexpr FormatInfo kFormats[] = {
    {PixelFormat::Default, "DEFAULT", Kind::None, 0},
    {PixelFormat::None, "NONE", Kind::None, 0},
    {PixelFormat::R8, "R8", Kind::Unorm, 1},
    {PixelFormat::R8Sn, "R8SN", Kind::Snorm, 1},
    {PixelFormat::R8Ui, "R8UI", Kind::Uint, 1},
    {PixelFormat::R8Si, "R8SI", Kind::Sint, 1},
    {PixelFormat::R16, "R16", Kind::Unorm, 2},
    {PixelFormat::R16Sn, "R16SN", Kind::Snorm, 2},
    {PixelFormat::R16Ui, "R16UI", Kind::Uint, 2},
    {PixelFormat::R16Si, "R16SI", Kind::Sint, 2},
    {PixelFormat::R16F, "R16F", Kind::Float, 2},
    {PixelFormat::Rg8, "RG8", Kind::Unorm, 2},
    {PixelFormat::Rg8Sn, "RG8SN", Kind::Snorm, 2},
    {PixelFormat::Rg8Ui, "RG8UI", Kind::Uint, 2},
    {PixelFormat::Rg8Si, "RG8SI", Kind::Sint, 2},
    {PixelFormat::R32Ui, "R32UI", Kind::Uint, 4},
    {PixelFormat::R32Si, "R32SI", Kind::Sint, 4},
    {PixelFormat::R32F, "R32F", Kind::Float, 4},
    {PixelFormat::Rg16, "RG16", Kind::Unorm, 4},
    {PixelFormat::Rg16Sn, "RG16SN", Kind::Snorm, 4},
    {PixelFormat::Rg16Ui, "RG16UI", Kind::Uint, 4},
    {PixelFormat::Rg16Si, "RG16SI", Kind::Sint, 4},
    {PixelFormat::Rg16F, "RG16F", Kind::Float, 4},
    {PixelFormat::Rgba8, "RGBA8", Kind::Unorm, 4},
    {PixelFormat::Srgb8A8, "SRGB8A8", Kind::Unorm, 4},
    {PixelFormat::Rgba8Sn, "RGBA8SN", Kind::Snorm, 4},
    {PixelFormat::Rgba8Ui, "RGBA8UI", Kind::Uint, 4},
    {PixelFormat::Rgba8Si, "RGBA8SI", Kind::Sint, 4},
    {PixelFormat::Bgra8, "BGRA8", Kind::Unorm, 4},
    {PixelFormat::Sbgr8A8, "SBGR8A8", Kind::Unorm, 4},
    {PixelFormat::Rgb10A2, "RGB10A2", Kind::Unorm, 4},
    {PixelFormat::Rg11B10F, "RG11B10F", Kind::Float, 4},
    {PixelFormat::Rgb9E5, "RGB9E5", Kind::Float, 4},
    {PixelFormat::Rg32Ui, "RG32UI", Kind::Uint, 8},
    {PixelFormat::Rg32Si, "RG32SI", Kind::Sint, 8},
    {PixelFormat::Rg32F, "RG32F", Kind::Float, 8},
    {PixelFormat::Rgba16, "RGBA16", Kind::Unorm, 8},
    {PixelFormat::Rgba16Sn, "RGBA16SN", Kind::Snorm, 8},
    {PixelFormat::Rgba16Ui, "RGBA16UI", Kind::Uint, 8},
    {PixelFormat::Rgba16Si, "RGBA16SI", Kind::Sint, 8},
    {PixelFormat::Rgba16F, "RGBA16F", Kind::Float, 8},
    {PixelFormat::Rgba32Ui, "RGBA32UI", Kind::Uint, 16},
    {PixelFormat::Rgba32Si, "RGBA32SI", Kind::Sint, 16},
    {PixelFormat::Rgba32F, "RGBA32F", Kind::Float, 16},
    {PixelFormat::Depth, "DEPTH", Kind::Depth, 4},
    {PixelFormat::DepthStencil, "DEPTH_STENCIL", Kind::Depth, 4},
    {PixelFormat::Bc1Rgba, "BC1_RGBA", Kind::Compressed, 0},
    {PixelFormat::Bc2Rgba, "BC2_RGBA", Kind::Compressed, 0},
    {PixelFormat::Bc3Rgba, "BC3_RGBA", Kind::Compressed, 0},
    {PixelFormat::Bc3Srgba, "BC3_SRGBA", Kind::Compressed, 0},
    {PixelFormat::Bc4R, "BC4_R", Kind::Compressed, 0},
    {PixelFormat::Bc4RSn, "BC4_RSN", Kind::Compressed, 0},
    {PixelFormat::Bc5Rg, "BC5_RG", Kind::Compressed, 0},
    {PixelFormat::Bc5RgSn, "BC5_RGSN", Kind::Compressed, 0},
    {PixelFormat::Bc6hRgbF, "BC6H_RGBF", Kind::Compressed, 0},
    {PixelFormat::Bc6hRgbUf, "BC6H_RGBUF", Kind::Compressed, 0},
    {PixelFormat::Bc7Rgba, "BC7_RGBA", Kind::Compressed, 0},
    {PixelFormat::Bc7Srgba, "BC7_SRGBA", Kind::Compressed, 0},
    {PixelFormat::Etc2Rgb8, "ETC2_RGB8", Kind::Compressed, 0},
    {PixelFormat::Etc2Srgb8, "ETC2_SRGB8", Kind::Compressed, 0},
    {PixelFormat::Etc2Rgb8A1, "ETC2_RGB8A1", Kind::Compressed, 0},
    {PixelFormat::Etc2Rgba8, "ETC2_RGBA8", Kind::Compressed, 0},
    {PixelFormat::Etc2Srgb8A8, "ETC2_SRGB8A8", Kind::Compressed, 0},
    {PixelFormat::EacR11, "EAC_R11", Kind::Compressed, 0},
    {PixelFormat::EacR11Sn, "EAC_R11SN", Kind::Compressed, 0},
    {PixelFormat::EacRg11, "EAC_RG11", Kind::Compressed, 0},
    {PixelFormat::EacRg11Sn, "EAC_RG11SN", Kind::Compressed, 0},
    {PixelFormat::Astc4x4Rgba, "ASTC_4x4_RGBA", Kind::Compressed, 0},
    {PixelFormat::Astc4x4Srgba, "ASTC_4x4_SRGBA", Kind::Compressed, 0},
};
static_assert(sizeof(kFormats) / sizeof(kFormats[0]) == std::size_t(PixelFormat::Count), "one row per PixelFormat");

constexpr bool rows_in_order() {
    for (std::size_t i = 0; i < sizeof(kFormats) / sizeof(kFormats[0]); ++i)
        if (std::size_t(kFormats[i].format) != i) return false;
    return true;
}
static_assert(rows_in_order(), "kFormats[i] describes PixelFormat(i)");

// The row of `f`, or the None row past Count.
const FormatInfo& info(PixelFormat f) {
    const auto i = std::size_t(f);
    return i < std::size_t(PixelFormat::Count) ? kFormats[i] : kFormats[std::size_t(PixelFormat::None)];
}

}  // namespace

const char* backend_name(Backend b) {
    switch (b) {
        case Backend::Gl: return "glcore";
        case Backend::Gles3: return "gles3";
        case Backend::WebGl2: return "webgl2";
        case Backend::D3d11: return "d3d11";
        case Backend::Metal: return "metal";
        case Backend::D3d12: return "d3d12";
        case Backend::Vulkan: return "vulkan";
        case Backend::Recording: return "recording";
    }
    return "?";
}

const char* queue_name(QueueKind queue) {
    switch (queue) {
        case QueueKind::Graphics: return "graphics";
        case QueueKind::Compute: return "compute";
        case QueueKind::Transfer: return "transfer";
        case QueueKind::Count: break;
    }
    return "?";
}

GpuVendor gpu_vendor_from_pci(std::uint32_t vendorId) {
    switch (vendorId) {
        case 0: return GpuVendor::Unknown;
        case kPciVendorNvidia: return GpuVendor::Nvidia;
        case kPciVendorAmd: return GpuVendor::Amd;
        case kPciVendorIntel: return GpuVendor::Intel;
        case kPciVendorApple: return GpuVendor::Apple;
        case kPciVendorMicrosoft: return GpuVendor::Microsoft;
        default: return GpuVendor::Other;
    }
}

const char* gpu_vendor_name(GpuVendor vendor) {
    switch (vendor) {
        case GpuVendor::Unknown: return "unknown";
        case GpuVendor::Nvidia: return "nvidia";
        case GpuVendor::Amd: return "amd";
        case GpuVendor::Intel: return "intel";
        case GpuVendor::Apple: return "apple";
        case GpuVendor::Microsoft: return "microsoft";
        case GpuVendor::Other: return "other";
    }
    return "unknown";
}

const char* native_state_name(NativeState state) {
    switch (state) {
        case NativeState::Common: return "Common";
        case NativeState::ShaderRead: return "ShaderRead";
        case NativeState::UnorderedAccess: return "UnorderedAccess";
        case NativeState::RenderTarget: return "RenderTarget";
        case NativeState::DepthWrite: return "DepthWrite";
        case NativeState::DepthRead: return "DepthRead";
        case NativeState::CopySource: return "CopySource";
        case NativeState::CopyDest: return "CopyDest";
        case NativeState::Count: break;
    }
    return "?";
}

const char* pixel_format_name(PixelFormat f) {
    return std::size_t(f) < std::size_t(PixelFormat::Count) ? kFormats[std::size_t(f)].name : "?";
}

int pixel_format_bytes(PixelFormat f) { return info(f).bytes; }

bool pixel_format_compressed(PixelFormat f) { return info(f).kind == Kind::Compressed; }

bool pixel_format_depth(PixelFormat f) { return info(f).kind == Kind::Depth; }

bool pixel_format_integer(PixelFormat f) { return info(f).kind == Kind::Uint || info(f).kind == Kind::Sint; }

bool pixel_format_signed_normalized(PixelFormat f) { return info(f).kind == Kind::Snorm; }

ViewType ViewDesc::type() const {
    if (texture.image.valid()) return ViewType::Texture;
    if (storageBuffer.buffer.valid()) return ViewType::StorageBuffer;
    if (storageImage.image.valid()) return ViewType::StorageImage;
    if (colorAttachment.image.valid()) return ViewType::ColorAttachment;
    if (resolveAttachment.image.valid()) return ViewType::ResolveAttachment;
    if (depthStencilAttachment.image.valid()) return ViewType::DepthStencilAttachment;
    return ViewType::Invalid;
}

int ViewDesc::resource_count() const {
    return int(texture.image.valid()) + int(storageBuffer.buffer.valid()) + int(storageImage.image.valid()) +
           int(colorAttachment.image.valid()) + int(resolveAttachment.image.valid()) +
           int(depthStencilAttachment.image.valid());
}

ViewType ShaderView::type() const {
    if (texture.stage != ShaderStage::None) return ViewType::Texture;
    if (storageBuffer.stage != ShaderStage::None) return ViewType::StorageBuffer;
    if (storageImage.stage != ShaderStage::None) return ViewType::StorageImage;
    return ViewType::Invalid;
}

ShaderStage ShaderView::stage() const {
    if (texture.stage != ShaderStage::None) return texture.stage;
    if (storageBuffer.stage != ShaderStage::None) return storageBuffer.stage;
    return storageImage.stage;
}

}  // namespace fa::gpu

namespace fa::gpu {

int vertex_format_bytes(VertexFormat f) {
    switch (f) {
        case VertexFormat::Invalid: return 0;
        case VertexFormat::Float:
        case VertexFormat::Int:
        case VertexFormat::Uint:
        case VertexFormat::Byte4:
        case VertexFormat::Byte4N:
        case VertexFormat::Ubyte4:
        case VertexFormat::Ubyte4N:
        case VertexFormat::Short2:
        case VertexFormat::Short2N:
        case VertexFormat::Ushort2:
        case VertexFormat::Ushort2N:
        case VertexFormat::Int10N2:
        case VertexFormat::Uint10N2:
        case VertexFormat::Half2: return 4;
        case VertexFormat::Float2:
        case VertexFormat::Int2:
        case VertexFormat::Uint2:
        case VertexFormat::Short4:
        case VertexFormat::Short4N:
        case VertexFormat::Ushort4:
        case VertexFormat::Ushort4N:
        case VertexFormat::Half4: return 8;
        case VertexFormat::Float3:
        case VertexFormat::Int3:
        case VertexFormat::Uint3: return 12;
        case VertexFormat::Float4:
        case VertexFormat::Int4:
        case VertexFormat::Uint4: return 16;
    }
    return 0;
}

void resolve_vertex_offsets(VertexLayout& layout) {
    bool packed[kMaxVertexBuffers];
    int size[kMaxVertexBuffers]{};
    for (bool& p : packed) p = true;
    for (const VertexAttr& a : layout.attrs) {
        if (a.format == VertexFormat::Invalid) break;
        if (a.bufferIndex < 0 || a.bufferIndex >= kMaxVertexBuffers) return;  // the backend reports the slot
        if (a.offset != 0) packed[a.bufferIndex] = false;
    }
    for (VertexAttr& a : layout.attrs) {
        if (a.format == VertexFormat::Invalid) break;
        if (packed[a.bufferIndex]) a.offset = size[a.bufferIndex];
        size[a.bufferIndex] += vertex_format_bytes(a.format);
    }
    for (int b = 0; b < kMaxVertexBuffers; ++b)
        if (layout.buffers[b].stride == 0) layout.buffers[b].stride = size[b];
}

}  // namespace fa::gpu
