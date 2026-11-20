// CPU-side float32 images (RGB or RGBA, linear light, values above 1 allowed) and the Radiance RGBE (.hdr) codec: HDRI
// environments are read with it and baked lightmaps are written with it (the engine's own code; stb_image's HDR reader
// is switched off).
#pragma once

#include <cstddef>
#include <cstdint>
#include <string_view>
#include <vector>

#include "fa/core/image.h"
#include "fa/core/math.h"
#include "fa/core/types.h"

namespace fa {

// The longest side of a float image and the most memory its pixels take. A request above either is an error that says
// so (never an allocation attempt): 8192 x 4096 RGBA is 512 MB, so an 8K panorama passes and a 16K x 8K one is
// refused.
inline constexpr int kMaxImageFloatSide = kMaxImageSide;
inline constexpr std::uint64_t kMaxImageFloatBytes = std::uint64_t(1) << 30;

// Bytes of width x height x channels float32 values, in 64 bits and saturating (a non-positive size gives 0; an
// overflowing size gives UINT64_MAX), so a caller compares it with kMaxImageFloatBytes on a 32-bit target too.
std::uint64_t image_float_bytes(std::int64_t width, std::int64_t height, int channels);

// sRGB transfer function on one value: sRGB-encoded 0..1 to linear light and back (the IEC 61966-2-1 curve the GPU uses
// for an sRGB texture). Both clamp their input to 0..1 first (NaN gives 0).
float srgb_to_linear(float encoded);
float linear_to_srgb(float linear);

enum class ImageWrap { Clamp, Repeat };

struct ImageF {
    int width = 0;
    int height = 0;
    int channels = 3;  // 3 (RGB) or 4 (RGBA)
    // The EXPOSURE of a .hdr header (product of its lines), 1 when none. Metadata only: the pixels are NOT divided by
    // it (as stb_image, Blender and Godot do) and it is up to the consumer to decide whether to apply it. encode_hdr
    // writes it (clamped to 1e-30..1e30, what decode_hdr accepts).
    float exposure = 1.0f;
    std::vector<float> data;  // width * height * channels, row 0 = TOP row, linear light

    // A zero-filled width x height image. Errors (with a hint) for a size below 1, a side above kMaxImageFloatSide, a
    // channel count other than 3 or 4, or more than kMaxImageFloatBytes of pixels; the size is checked before any
    // memory is asked for.
    static Result<ImageF> create(int newWidth, int newHeight, int channelCount);

    bool empty() const { return width <= 0 || height <= 0 || data.empty(); }
    float* at(int x, int y) {
        return &data[(std::size_t(y) * std::size_t(width) + std::size_t(x)) * std::size_t(channels)];
    }
    const float* at(int x, int y) const {
        return &data[(std::size_t(y) * std::size_t(width) + std::size_t(x)) * std::size_t(channels)];
    }

    // The pixel at (x, y); transparent black (0, 0, 0, 0) outside the image. An RGB image answers alpha 1.
    Color pixel(int x, int y) const;
    // Stores the colour (alpha only when the image has 4 channels); ignored outside the image.
    void set_pixel(int x, int y, Color c);

    // Bilinear sample at the normalised coordinate (u, v) (0..1 across and down the image; texel centres are at
    // (i + 0.5) / size, as on the GPU). Outside 0..1 the coordinate is clamped to the edge or wraps, per axis.
    Color sample(float u, float v, ImageWrap wrapU = ImageWrap::Clamp, ImageWrap wrapV = ImageWrap::Clamp) const;

    // Resamples to width x height (both >= 1, within the limits of `create`). Shrinking averages every source pixel
    // under a destination pixel by the area it covers (a box filter: 2x2 for half the size); enlarging is bilinear.
    // Every channel averages as it is (no alpha weighting). The same size returns a copy.
    Result<ImageF> resized(int newWidth, int newHeight) const;
    // Half the size on both sides (never below 1): the next level of a mip chain.
    Result<ImageF> half_size() const { return resized(width > 1 ? width / 2 : 1, height > 1 ? height / 2 : 1); }

    // A float image from an RGBA8 one (alpha as 0..1). `srgb`: the colour bytes are sRGB-encoded and become linear
    // light (alpha always stays linear); false: bytes / 255 as they are. `gain` multiplies the colour (not the alpha).
    // `channelCount` 3 drops the alpha. Errors for an empty image or one above the limits.
    static Result<ImageF> from_image(const Image& image, bool srgb, float gain = 1.0f, int channelCount = 4);
    // An RGBA8 image: colour * `gain`, clamped to 0..1 (no tone mapping: a value above 1 is white), then sRGB-encoded
    // when `srgb` (otherwise written as it is). An RGB image gets alpha 255. NaN becomes 0.
    Image to_image(bool srgb, float gain = 1.0f) const;
};

// ---- Radiance RGBE (.hdr) --------------------------------------------------------------------------------------
// What decode_hdr reads: the "#?RADIANCE" / "#?RGBE" header (any "#?" program name), FORMAT=32-bit_rle_rgbe (or no
// FORMAT), EXPOSURE lines, and the resolution line "-Y <height> +X <width>" (rows from the top, left to right: what
// every exporter writes). Pixels as new-style run-length scanlines (width 8..32767), flat scanlines, and the old-style repeat marker
// (1, 1, 1, n). Any other orientation ("+Y", "-X"...) and FORMAT=32-bit_rle_xyze are refused with an error that says
// what to do. The result has 3 channels, linear light. A truncated or corrupt file is an error that names the byte
// offset; a size above kMaxImageFloatSide or kMaxImageFloatBytes is refused from the header, before pixel memory is
// allocated.
Result<ImageF> decode_hdr(const std::uint8_t* data, std::size_t size);
// Reads and decodes a .hdr through the engine's file layer (fs::read_bytes: project paths, packs); the error names the
// file.
Result<ImageF> load_hdr(std::string_view path);

// A .hdr file: header with the EXPOSURE (when not 1) and "-Y h +X w", pixels as new-style RLE scanlines when the width
// is 8..32767 and flat otherwise. The alpha of an RGBA image is dropped. Each pixel is stored as shared-exponent RGBE
// (8 bit mantissas), so a value is kept to about 0.4% of the largest channel of its pixel; negative and NaN values are
// written as 0, infinity and values above 2^127 as the largest value. Deterministic: the same pixels give the same
// bytes. Empty for an empty image.
std::vector<std::uint8_t> encode_hdr(const ImageF& image);
// encode_hdr through the file layer (fs::write_bytes: creates folders).
Result<void> save_hdr(const ImageF& image, std::string_view path);

}  // namespace fa
