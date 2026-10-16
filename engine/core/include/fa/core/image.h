// CPU-side RGBA8 images: texture loading, screenshots, golden-image tests.
#pragma once

#include <cstdint>
#include <string_view>
#include <vector>

#include "fa/core/math.h"
#include "fa/core/types.h"

namespace fa {

struct Image {
    int width = 0;
    int height = 0;
    std::vector<std::uint8_t> rgba;  // width * height * 4, row 0 = TOP row

    bool empty() const { return width <= 0 || height <= 0; }
    Color pixel(int x, int y) const;
    void set_pixel(int x, int y, Color c);
    void flip_vertical();
};

Result<Image> load_image(std::string_view path);                       // png/jpg/tga/bmp via fs
Result<Image> decode_image(const std::uint8_t* data, std::size_t size);  // from memory

// The mip chain of a texture: level 0 is `base`, each next level averages 2x2 pixels (edge pixels repeated) and halves
// the size (never below 1), down to 1x1 or 16 levels. The renderer uploads these and the export compresses them, so a
// compressed texture has the same mips as an uncompressed one.
std::vector<Image> mip_chain(Image base);

// GPU-compressed twin of a texture: an export replaces assets/hero.png by assets/hero.png.ktx2 (KTX2, Basis Universal),
// and the engine loads the twin when it exists, so nothing that names the texture changes.
inline constexpr const char* kTextureTwinExtension = ".ktx2";

struct ImageSize {
    int width = 0, height = 0;
};
// Width and height of the first level of a KTX2 file, from its header.
Result<ImageSize> ktx2_size(const std::uint8_t* data, std::size_t size);
// Pixel size of the texture a project path names, without decoding it: the file itself (PNG, JPG... or .ktx2), else the
// size recorded for a texture an export packed into an atlas (assets.json `packed`), else the header of its `.ktx2`
// twin. Scene bounds, scripts and tileset checks all ask this, so an export does not change what they measure.
Result<ImageSize> texture_size(std::string_view path);
Result<void> save_png(const Image& img, std::string_view path);        // via fs (creates dirs)
std::vector<std::uint8_t> encode_png(const Image& img);
// PNG without an alpha channel (colour type 2, RGB): the alpha of `img` is dropped, so compose it over a background
// first (fit_image). For images that must not carry transparency, such as the App Store icon of an iOS app.
std::vector<std::uint8_t> encode_png_rgb(const Image& img);

// Resamples `src` to width x height (both > 0; an empty result for an empty `src` or a size below 1). Colours are
// weighted by alpha (premultiplied), so the transparent pixels around a shape do not darken or tint its edge. Shrinking
// averages every source pixel under a destination pixel by the area it covers (no aliasing); enlarging is bilinear.
// The two axes are resampled independently. The same size returns a copy.
Image resize_image(const Image& src, int width, int height);

// A size x size canvas filled with `background`, with `src` drawn over it (alpha compositing) and centered. `src` keeps
// its aspect ratio and is scaled so that its LONGER side is size * scale pixels: scale 1 fills the canvas, 0.61 leaves
// the margin an Android adaptive icon asks for, and a non-square `src` is centered on the canvas (the background shows
// on its short sides). A scale above 1 crops. A `background` with alpha 0 gives a transparent canvas; with alpha 1 the
// result is opaque. An empty `src` returns just the background; size < 1 returns an empty image.
Image fit_image(const Image& src, int size, float scale, Color background);

struct ImageDiff {
    bool sameSize = false;
    double meanError = 0.0;      // average absolute channel difference, 0..1
    double maxError = 0.0;       // worst channel difference, 0..1
    std::size_t differingPixels = 0;  // pixels with any channel diff > tolerance
};
// Compare two images; `tolerance` is per-channel (0..1). Used by golden tests.
ImageDiff diff_images(const Image& a, const Image& b, float tolerance = 2.0f / 255.0f);

}  // namespace fa
