// This translation unit owns the stb_image / stb_image_write implementations for the
// whole engine. Other modules must include the stb headers WITHOUT *_IMPLEMENTATION.
#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION
#define STBI_NO_STDIO
#define STBI_WRITE_NO_STDIO
#define STBI_NO_HDR
#include <stb_image.h>
#include <stb_image_write.h>

#include "fa/core/image.h"

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <cstring>

#include "fa/core/fs.h"

namespace fa {

Color Image::pixel(int x, int y) const {
    if (x < 0 || y < 0 || x >= width || y >= height) return Color{0, 0, 0, 0};
    const std::uint8_t* p = &rgba[(std::size_t(y) * width + x) * 4];
    return Color::rgba8(p[0], p[1], p[2], p[3]);
}

void Image::set_pixel(int x, int y, Color c) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    std::uint8_t* p = &rgba[(std::size_t(y) * width + x) * 4];
    auto q = [](float v) { return std::uint8_t(saturate(v) * 255.0f + 0.5f); };
    p[0] = q(c.r); p[1] = q(c.g); p[2] = q(c.b); p[3] = q(c.a);
}

void Image::flip_vertical() {
    std::size_t stride = std::size_t(width) * 4;
    for (int y = 0; y < height / 2; ++y)
        std::swap_ranges(rgba.begin() + y * stride, rgba.begin() + (y + 1) * stride,
                         rgba.begin() + std::size_t(height - 1 - y) * stride);
}

Result<Image> decode_image(const std::uint8_t* data, std::size_t size) {
    int w = 0, h = 0, comp = 0;
    unsigned char* px = stbi_load_from_memory(data, int(size), &w, &h, &comp, 4);
    if (!px) {
        const char* why = stbi_failure_reason();
        return make_error(std::string("Cannot decode image: ") + (why ? why : "unknown format"),
                          "Supported formats: PNG, JPG, TGA, BMP (also GIF/PSD first frame). Re-export the file from your image editor.");
    }
    Image img;
    img.width = w;
    img.height = h;
    img.rgba.assign(px, px + std::size_t(w) * h * 4);
    stbi_image_free(px);
    return img;
}

Result<Image> load_image(std::string_view path) {
    auto bytes = fs::read_bytes(path);
    if (!bytes) return bytes.error();
    auto img = decode_image(bytes->data(), bytes->size());
    if (!img) return make_error("'" + std::string(path) + "': " + img.error().message, img.error().hint);
    return img;
}

std::vector<std::uint8_t> encode_png(const Image& img) {
    std::vector<std::uint8_t> out;
    if (img.empty()) return out;
    auto write = [](void* ctx, void* data, int size) {
        auto* v = static_cast<std::vector<std::uint8_t>*>(ctx);
        const auto* p = static_cast<const std::uint8_t*>(data);
        v->insert(v->end(), p, p + size);
    };
    stbi_write_png_to_func(write, &out, img.width, img.height, 4, img.rgba.data(), img.width * 4);
    return out;
}

Result<void> save_png(const Image& img, std::string_view path) {
    if (img.empty()) return make_error("Cannot save an empty image to '" + std::string(path) + "'");
    std::vector<std::uint8_t> png = encode_png(img);
    if (png.empty()) return make_error("PNG encoding failed for '" + std::string(path) + "'");
    return fs::write_bytes(path, png.data(), png.size());
}

ImageDiff diff_images(const Image& a, const Image& b, float tolerance) {
    ImageDiff d;
    d.sameSize = a.width == b.width && a.height == b.height;
    if (!d.sameSize) {
        d.meanError = 1.0;
        d.maxError = 1.0;
        d.differingPixels = std::max(std::size_t(std::max(a.width, 0)) * std::size_t(std::max(a.height, 0)),
                                     std::size_t(std::max(b.width, 0)) * std::size_t(std::max(b.height, 0)));
        return d;
    }
    std::size_t pixels = std::size_t(a.width) * a.height;
    if (pixels == 0) return d;
    double sum = 0.0;
    for (std::size_t i = 0; i < pixels; ++i) {
        bool differs = false;
        for (int c = 0; c < 4; ++c) {
            double e = std::abs(int(a.rgba[i * 4 + c]) - int(b.rgba[i * 4 + c])) / 255.0;
            sum += e;
            d.maxError = std::max(d.maxError, e);
            if (e > double(tolerance) + 1e-9) differs = true;
        }
        if (differs) ++d.differingPixels;
    }
    d.meanError = sum / double(pixels * 4);
    return d;
}

}  // namespace fa
