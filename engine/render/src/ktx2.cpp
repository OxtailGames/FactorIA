// KTX2 textures (Basis Universal): the compressed twin an export writes for a texture, transcoded to the format the GPU
// samples. See docs/ASSETS.md, "Textures".
#include <cstdlib>
#include <mutex>

#include <transcoder/basisu_transcoder.h>

#include "fa/core/strings.h"
#include "render_internal.h"

namespace fa::render {

namespace {

struct Target {
    sg_pixel_format gpu;
    basist::transcoder_texture_format basis;
    const char* name;  // what FA_TEXTURE_FORMAT calls it
};

// Best first: ASTC 4x4 is what mobile GPUs sample, BC7 what desktop GPUs sample, and every GLES3 device samples ETC2.
constexpr Target kTargets[] = {
    {SG_PIXELFORMAT_ASTC_4x4_RGBA, basist::transcoder_texture_format::cTFASTC_4x4_RGBA, "astc"},
    {SG_PIXELFORMAT_BC7_RGBA, basist::transcoder_texture_format::cTFBC7_RGBA, "bc7"},
    {SG_PIXELFORMAT_ETC2_RGBA8, basist::transcoder_texture_format::cTFETC2_RGBA, "etc2"},
};

const Target* pick_target() {
    const char* forced = std::getenv("FA_TEXTURE_FORMAT");
    const std::string only = forced ? to_lower(forced) : std::string();
    for (const Target& t : kTargets) {
        if (!only.empty() && only != t.name) continue;
        const sg_pixelformat_info info = sg_query_pixelformat(t.gpu);
        if (info.sample && info.filter) return &t;
    }
    return nullptr;
}

}  // namespace

const char* pixel_format_name(sg_pixel_format format) {
    switch (format) {
        case SG_PIXELFORMAT_ASTC_4x4_RGBA: return "ASTC_4x4";
        case SG_PIXELFORMAT_BC7_RGBA: return "BC7";
        case SG_PIXELFORMAT_ETC2_RGBA8: return "ETC2_RGBA8";
        default: return "RGBA8";
    }
}

Result<TranscodedTexture> transcode_ktx2(const std::uint8_t* data, std::size_t size, bool allowCompressed) {
    static std::once_flag once;
    std::call_once(once, [] { basist::basisu_transcoder_init(); });

    basist::ktx2_transcoder ktx;
    if (!ktx.init(data, std::uint32_t(size)))
        return make_error("not a valid KTX2 file", "Export the project again: `factoria export` writes these files.");
    if (!ktx.is_uastc() && !ktx.is_etc1s())
        return make_error("the KTX2 file does not hold UASTC or ETC1S data",
                          "Set the texture's `compression` in assets.json to uastc or etc1s and export again.");
    if (ktx.get_faces() != 1 || ktx.get_layers() > 1)
        return make_error("the KTX2 file is not a single 2D texture", "Export the project again.");
    if (!ktx.start_transcoding()) return make_error("the KTX2 file is damaged", "Export the project again.");

    // D3D11 and WebGPU create block-compressed textures only when the size is a multiple of the block, so any other size
    // is transcoded to RGBA8 (the export leaves such textures as PNG: tools/common/src/export_textures.cpp).
    const bool blockAligned = ktx.get_width() % 4 == 0 && ktx.get_height() % 4 == 0;
    const Target* target = allowCompressed && blockAligned ? pick_target() : nullptr;
    TranscodedTexture out;
    out.width = int(ktx.get_width());
    out.height = int(ktx.get_height());
    out.format = target ? target->gpu : SG_PIXELFORMAT_RGBA8;
    for (std::uint32_t level = 0; level < ktx.get_levels(); ++level) {
        basist::ktx2_image_level_info info{};
        if (!ktx.get_image_level_info(info, level, 0, 0)) return make_error("the KTX2 file is damaged", "Export the project again.");
        const std::uint32_t units = target ? info.m_total_blocks : info.m_orig_width * info.m_orig_height;
        const auto format = target ? target->basis : basist::transcoder_texture_format::cTFRGBA32;
        std::vector<std::uint8_t> bytes(std::size_t(units) * basist::basis_get_bytes_per_block_or_pixel(format));
        if (!ktx.transcode_image_level(level, 0, 0, bytes.data(), units, format))
            return make_error("mip level " + std::to_string(level) + " of the KTX2 file cannot be transcoded", "Export the project again.");
        out.levels.push_back(std::move(bytes));
    }
    return out;
}

}  // namespace fa::render
