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
Result<void> save_png(const Image& img, std::string_view path);        // via fs (creates dirs)
std::vector<std::uint8_t> encode_png(const Image& img);

struct ImageDiff {
    bool sameSize = false;
    double meanError = 0.0;      // average absolute channel difference, 0..1
    double maxError = 0.0;       // worst channel difference, 0..1
    std::size_t differingPixels = 0;  // pixels with any channel diff > tolerance
};
// Compare two images; `tolerance` is per-channel (0..1). Used by golden tests.
ImageDiff diff_images(const Image& a, const Image& b, float tolerance = 2.0f / 255.0f);

}  // namespace fa
