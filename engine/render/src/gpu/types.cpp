// The backend-neutral helpers of gpu/types.h (no sokol here: RecordingDevice and the later backends use them too).
#include "gpu/types.h"

namespace fa::gpu {

namespace {

// Indexed by PixelFormat's value (sokol's order); the names are sokol's without the SG_PIXELFORMAT_ prefix.
constexpr const char* kPixelFormatNames[] = {
    "DEFAULT",   "NONE",      "R8",        "R8SN",          "R8UI",          "R8SI",           "R16",
    "R16SN",     "R16UI",     "R16SI",     "R16F",          "RG8",           "RG8SN",          "RG8UI",
    "RG8SI",     "R32UI",     "R32SI",     "R32F",          "RG16",          "RG16SN",         "RG16UI",
    "RG16SI",    "RG16F",     "RGBA8",     "SRGB8A8",       "RGBA8SN",       "RGBA8UI",        "RGBA8SI",
    "BGRA8",     "SBGR8A8",   "RGB10A2",   "RG11B10F",      "RGB9E5",        "RG32UI",         "RG32SI",
    "RG32F",     "RGBA16",    "RGBA16SN",  "RGBA16UI",      "RGBA16SI",      "RGBA16F",        "RGBA32UI",
    "RGBA32SI",  "RGBA32F",   "DEPTH",     "DEPTH_STENCIL", "BC1_RGBA",      "BC2_RGBA",       "BC3_RGBA",
    "BC3_SRGBA", "BC4_R",     "BC4_RSN",   "BC5_RG",        "BC5_RGSN",      "BC6H_RGBF",      "BC6H_RGBUF",
    "BC7_RGBA",  "BC7_SRGBA", "ETC2_RGB8", "ETC2_SRGB8",    "ETC2_RGB8A1",   "ETC2_RGBA8",     "ETC2_SRGB8A8",
    "EAC_R11",   "EAC_R11SN", "EAC_RG11",  "EAC_RG11SN",    "ASTC_4x4_RGBA", "ASTC_4x4_SRGBA",
};
static_assert(sizeof(kPixelFormatNames) / sizeof(kPixelFormatNames[0]) == std::size_t(PixelFormat::Count),
              "one name per PixelFormat");

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

const char* pixel_format_name(PixelFormat f) {
    const auto i = std::size_t(f);
    return i < std::size_t(PixelFormat::Count) ? kPixelFormatNames[i] : "?";
}

int pixel_format_bytes(PixelFormat f) {
    switch (f) {
        case PixelFormat::R8:
        case PixelFormat::R8Sn:
        case PixelFormat::R8Ui:
        case PixelFormat::R8Si: return 1;
        case PixelFormat::R16:
        case PixelFormat::R16Sn:
        case PixelFormat::R16Ui:
        case PixelFormat::R16Si:
        case PixelFormat::R16F:
        case PixelFormat::Rg8:
        case PixelFormat::Rg8Sn:
        case PixelFormat::Rg8Ui:
        case PixelFormat::Rg8Si: return 2;
        case PixelFormat::R32Ui:
        case PixelFormat::R32Si:
        case PixelFormat::R32F:
        case PixelFormat::Rg16:
        case PixelFormat::Rg16Sn:
        case PixelFormat::Rg16Ui:
        case PixelFormat::Rg16Si:
        case PixelFormat::Rg16F:
        case PixelFormat::Rgba8:
        case PixelFormat::Srgb8A8:
        case PixelFormat::Rgba8Sn:
        case PixelFormat::Rgba8Ui:
        case PixelFormat::Rgba8Si:
        case PixelFormat::Bgra8:
        case PixelFormat::Sbgr8A8:
        case PixelFormat::Rgb10A2:
        case PixelFormat::Rg11B10F:
        case PixelFormat::Rgb9E5: return 4;
        case PixelFormat::Rg32Ui:
        case PixelFormat::Rg32Si:
        case PixelFormat::Rg32F:
        case PixelFormat::Rgba16:
        case PixelFormat::Rgba16Sn:
        case PixelFormat::Rgba16Ui:
        case PixelFormat::Rgba16Si:
        case PixelFormat::Rgba16F: return 8;
        case PixelFormat::Rgba32Ui:
        case PixelFormat::Rgba32Si:
        case PixelFormat::Rgba32F: return 16;
        case PixelFormat::Depth:
        case PixelFormat::DepthStencil: return 4;
        default: return 0;
    }
}

bool pixel_format_compressed(PixelFormat f) {
    return std::uint32_t(f) >= std::uint32_t(PixelFormat::Bc1Rgba) &&
           std::uint32_t(f) < std::uint32_t(PixelFormat::Count);
}

bool pixel_format_depth(PixelFormat f) { return f == PixelFormat::Depth || f == PixelFormat::DepthStencil; }

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
