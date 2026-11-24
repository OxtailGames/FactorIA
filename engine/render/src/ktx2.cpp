// KTX2 textures (Basis Universal): the compressed twin an export writes for a texture, transcoded to the format the GPU
// samples. See docs/ASSETS.md, "Textures".
#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <mutex>

#include <transcoder/basisu_transcoder.h>

#include "fa/core/image.h"
#include "fa/core/strings.h"
#include "fa/render/ktx2.h"
#include "gpu/device.h"
#include "render_internal.h"

namespace fa::render {

namespace {

struct TranscodeTarget {
    gpu::PixelFormat format;
    basist::transcoder_texture_format basis;
    const char* name;  // what FA_TEXTURE_FORMAT calls it
};

// Best first: ASTC 4x4 is what mobile GPUs sample, BC7 what desktop GPUs sample, and every GLES3 device samples ETC2.
constexpr TranscodeTarget kTargets[] = {
    {gpu::PixelFormat::Astc4x4Rgba, basist::transcoder_texture_format::cTFASTC_4x4_RGBA, "astc"},
    {gpu::PixelFormat::Bc7Rgba, basist::transcoder_texture_format::cTFBC7_RGBA, "bc7"},
    {gpu::PixelFormat::Etc2Rgba8, basist::transcoder_texture_format::cTFETC2_RGBA, "etc2"},
};

std::uint32_t readle32(const std::uint8_t* p) {
    return std::uint32_t(p[0]) | std::uint32_t(p[1]) << 8 | std::uint32_t(p[2]) << 16 | std::uint32_t(p[3]) << 24;
}

// basisu builds a Huffman table whose code has a single symbol even when the code is incomplete, and grows its tree array only as
// far as the nodes that symbol's code reaches: when that code is longer than the fast lookup's 10 bits, the last node's sibling
// slot is missing and decode_huffman reads past the array (the fuzz target `ktx2` found it). A table is sound when every node it
// can reach (a negative entry ~i names the pair tree[i], tree[i + 1]) lies inside the tree.
bool huffman_table_sound(const basist::huffman_decoding_table& table) {
    const std::size_t nodes = table.get_tree().size();
    auto inside = [&](int entry) { return entry >= 0 || std::size_t(~entry) + 1 < nodes; };
    for (const int entry : table.get_lookup())
        if (!inside(entry)) return false;
    for (const std::int16_t entry : table.get_tree())
        if (!inside(entry)) return false;
    return true;
}

// Reads `count` Huffman tables from the front of a stream the way basisu does and checks each. A stream basisu cannot read is
// left for basisu to refuse.
bool huffman_stream_sound(const std::uint8_t* data, std::uint32_t size, int count) {
    basist::bitwise_decoder bits;
    if (!bits.init(data, size)) return true;
    for (int i = 0; i < count; ++i) {
        basist::huffman_decoding_table table;
        if (!bits.read_huffman_table(table)) return true;
        if (!huffman_table_sound(table)) return false;
    }
    return true;
}

// The Huffman tables of an ETC1S file's supercompression global data, checked before basisu decodes with them: the four of the
// tables stream, the four of the endpoints stream and the selector table (basist::ktx2_transcoder::decompress_etc1s_global_data,
// decode_tables and decode_palettes read them in that layout). Returns false for a table that would read outside its tree.
bool etc1s_tables_sound(const basist::ktx2_transcoder& ktx, const std::uint8_t* data, std::size_t size) {
    const basist::ktx2_header& h = ktx.get_header();
    const std::uint64_t offset = h.m_sgd_byte_offset.get_uint64(), length = h.m_sgd_byte_length.get_uint64();
    if (offset > size || length > size - offset || length < 20) return true;  // ktx2_transcoder refuses these
    const std::uint8_t* sgd = data + offset;
    const std::uint64_t images =
        std::uint64_t(std::max<std::uint32_t>(h.m_layer_count, 1)) * h.m_face_count * h.m_level_count;
    const std::uint32_t endpoints = readle32(sgd + 4), selectors = readle32(sgd + 8), tables = readle32(sgd + 12);
    const std::uint64_t front = 20 + 20 * images;
    if (front + endpoints + selectors + tables + readle32(sgd + 16) > length)
        return true;  // so does decompress_etc1s_global_data
    const std::uint8_t* endpointData = sgd + front;
    const std::uint8_t* selectorData = endpointData + endpoints;
    if (!huffman_stream_sound(selectorData + selectors, tables, 4)) return false;
    if (!huffman_stream_sound(endpointData, endpoints, 4)) return false;
    basist::bitwise_decoder bits;  // selectors: global codebook bit, hybrid bit, raw bit, then the table unless raw
    if (!bits.init(selectorData, selectors) || bits.get_bits(1) || bits.get_bits(1) || bits.get_bits(1)) return true;
    basist::huffman_decoding_table table;
    return !bits.read_huffman_table(table) || huffman_table_sound(table);
}

const TranscodeTarget* pick_target(gpu::Device& device) {
    const char* forced = std::getenv("FA_TEXTURE_FORMAT");
    const std::string only = forced ? to_lower(forced) : std::string();
    for (const TranscodeTarget& t : kTargets) {
        if (!only.empty() && only != t.name) continue;
        const gpu::PixelFormatCaps info = device.pixel_format_caps(t.format);
        if (info.sample && info.filter) return &t;
    }
    return nullptr;
}

}  // namespace

const char* texture_format_name(gpu::PixelFormat format) {
    switch (format) {
        case gpu::PixelFormat::Astc4x4Rgba: return "ASTC_4x4";
        case gpu::PixelFormat::Bc7Rgba: return "BC7";
        case gpu::PixelFormat::Etc2Rgba8: return "ETC2_RGBA8";
        case gpu::PixelFormat::Srgb8A8: return "SRGB8A8";
        case gpu::PixelFormat::Bc7Srgba: return "BC7_SRGB";
        case gpu::PixelFormat::Astc4x4Srgba: return "ASTC_4x4_SRGB";
        case gpu::PixelFormat::Etc2Srgb8A8: return "ETC2_SRGB8A8";
        case gpu::PixelFormat::Rgba16F: return "RGBA16F";
        case gpu::PixelFormat::Rg11B10F: return "R11G11B10";
        default: return "RGBA8";
    }
}

gpu::PixelFormat ktx2_target_format(gpu::Device& device) {
    const TranscodeTarget* t = pick_target(device);
    return t ? t->gpu : gpu::PixelFormat::Rgba8;
}

Result<TranscodedTexture> transcode_ktx2(gpu::Device& device, const std::uint8_t* data, std::size_t size,
                                         bool allowCompressed) {
    return transcode_ktx2_as(data, size, allowCompressed ? ktx2_target_format(device) : gpu::PixelFormat::Rgba8);
}

Result<TranscodedTexture> transcode_ktx2_as(const std::uint8_t* data, std::size_t size, gpu::PixelFormat format) {
    static std::once_flag once;
    std::call_once(once, [] { basist::basisu_transcoder_init(); });

    basist::ktx2_transcoder ktx;
    if (!data || size > std::size_t(0xFFFFFFFFu) || !ktx.init(data, std::uint32_t(size)))
        return make_error("not a valid KTX2 file", "Export the project again: `factoria export` writes these files.");
    if (!ktx.is_uastc() && !ktx.is_etc1s())
        return make_error("the KTX2 file does not hold UASTC or ETC1S data",
                          "Set the texture's `compression` in assets.json to uastc or etc1s and export again.");
    if (ktx.get_faces() != 1 || ktx.get_layers() > 1)
        return make_error("the KTX2 file is not a single 2D texture", "Export the project again.");
    // The header's sizes decide how much memory the transcode asks for: refuse what no texture of this engine is before it.
    const std::uint64_t width = ktx.get_width(), height = ktx.get_height();
    if (width == 0 || height == 0 || width > std::uint64_t(kMaxImageSide) || height > std::uint64_t(kMaxImageSide) ||
        width * height > kMaxImagePixels || ktx.get_levels() > 16)
        return make_error("the KTX2 file claims " + std::to_string(width) + " x " + std::to_string(height) +
                              " pixels and " + std::to_string(ktx.get_levels()) + " mip levels, beyond the " +
                              std::to_string(kMaxImageSide) + " x " + std::to_string(kMaxImageSide) +
                              " and 16 levels the engine reads",
                          "Export the project again: `factoria export` writes these files.");
    // Without a supercompression scheme a level's stored and uncompressed lengths are the same number (KTX2 spec, "Level Index");
    // the transcoder only asserts it, so a file that disagrees is refused here (the fuzz target `ktx2` found one).
    if (size >= 80 && readle32(data + 44) == 0) {
        const std::uint32_t levels = std::max<std::uint32_t>(1, readle32(data + 40));
        for (std::uint32_t level = 0; level < levels && 80 + 24 * std::uint64_t(level + 1) <= size; ++level) {
            const std::uint8_t* entry = data + 80 + 24 * std::size_t(level);
            if (readle32(entry + 8) != readle32(entry + 16) || readle32(entry + 12) != readle32(entry + 20))
                return make_error("mip level " + std::to_string(level) +
                                      " of the KTX2 file stores a different number of bytes than it unpacks to",
                                  "Export the project again: `factoria export` writes these files.");
        }
    }
    if (ktx.is_etc1s() && !etc1s_tables_sound(ktx, data, size))
        return make_error("the KTX2 file is damaged: a Huffman table of its ETC1S global data is not a valid code",
                          "Export the project again: `factoria export` writes these files.");
    if (!ktx.start_transcoding()) return make_error("the KTX2 file is damaged", "Export the project again.");

    // D3D11 and WebGPU create block-compressed textures only when the size is a multiple of the block, so any other size
    // is transcoded to RGBA8 (the export leaves such textures as PNG: tools/common/src/export_textures.cpp).
    const bool blockAligned = ktx.get_width() % 4 == 0 && ktx.get_height() % 4 == 0;
    const TranscodeTarget* target = nullptr;
    if (blockAligned)
        for (const TranscodeTarget& t : kTargets)
            if (t.format == format) target = &t;
    TranscodedTexture out;
    out.width = int(ktx.get_width());
    out.height = int(ktx.get_height());
    out.format = target ? target->gpu : gpu::PixelFormat::Rgba8;
    for (std::uint32_t level = 0; level < ktx.get_levels(); ++level) {
        basist::ktx2_image_level_info info{};
        if (!ktx.get_image_level_info(info, level, 0, 0))
            return make_error("the KTX2 file is damaged", "Export the project again.");
        const std::uint32_t units = target ? info.m_total_blocks : info.m_orig_width * info.m_orig_height;
        const auto blockFormat = target ? target->basis : basist::transcoder_texture_format::cTFRGBA32;
        std::vector<std::uint8_t> bytes(std::size_t(units) * basist::basis_get_bytes_per_block_or_pixel(blockFormat));
        if (!ktx.transcode_image_level(level, 0, 0, bytes.data(), units, blockFormat))
            return make_error("mip level " + std::to_string(level) + " of the KTX2 file cannot be transcoded",
                              "Export the project again.");
        out.levels.push_back(std::move(bytes));
    }
    return out;
}

}  // namespace fa::render

namespace fa {

Result<Image> decode_ktx2(const std::uint8_t* data, std::size_t size) {
    auto tex = render::transcode_ktx2_as(data, size, gpu::PixelFormat::Rgba8);
    if (!tex) return tex.error();
    if (tex->levels.empty() || tex->levels.front().size() != std::size_t(tex->width) * std::size_t(tex->height) * 4)
        return make_error("the KTX2 file has no base level",
                          "Export the project again: `factoria export` writes these files.");
    Image img;
    img.width = tex->width;
    img.height = tex->height;
    img.rgba = std::move(tex->levels.front());
    return img;
}

}  // namespace fa
