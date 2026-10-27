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

#include "fa/core/asset_manifest.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"

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

std::vector<Image> mip_chain(Image base) {
    constexpr int kMaxMipLevels = 16;
    std::vector<Image> chain;
    chain.push_back(std::move(base));
    while ((chain.back().width > 1 || chain.back().height > 1) && int(chain.size()) < kMaxMipLevels) {
        const Image& prev = chain.back();
        const int w = prev.width, h = prev.height;
        Image next;
        next.width = std::max(1, w / 2);
        next.height = std::max(1, h / 2);
        next.rgba.resize(std::size_t(next.width) * next.height * 4);
        for (int y = 0; y < next.height; ++y) {
            for (int x = 0; x < next.width; ++x) {
                const int x0 = std::min(x * 2, w - 1), x1 = std::min(x * 2 + 1, w - 1);
                const int y0 = std::min(y * 2, h - 1), y1 = std::min(y * 2 + 1, h - 1);
                for (int c = 0; c < 4; ++c) {
                    const int sum = prev.rgba[(std::size_t(y0) * w + x0) * 4 + c] + prev.rgba[(std::size_t(y0) * w + x1) * 4 + c] +
                                    prev.rgba[(std::size_t(y1) * w + x0) * 4 + c] + prev.rgba[(std::size_t(y1) * w + x1) * 4 + c];
                    next.rgba[(std::size_t(y) * next.width + x) * 4 + c] = std::uint8_t((sum + 2) / 4);
                }
            }
        }
        chain.push_back(std::move(next));
    }
    return chain;
}

Result<ImageSize> ktx2_size(const std::uint8_t* data, std::size_t size) {
    // KTX2 header: the 12-byte identifier, then vkFormat, typeSize, pixelWidth, pixelHeight (little-endian u32).
    static const std::uint8_t magic[12] = {0xAB, 'K', 'T', 'X', ' ', '2', '0', 0xBB, 0x0D, 0x0A, 0x1A, 0x0A};
    if (size < 28 || std::memcmp(data, magic, sizeof(magic)) != 0)
        return make_error("Not a KTX2 file", "A .ktx2 twin is written by `factoria export`; delete it and export again.");
    auto u32 = [&](std::size_t at) {
        return std::uint32_t(data[at]) | std::uint32_t(data[at + 1]) << 8 | std::uint32_t(data[at + 2]) << 16 | std::uint32_t(data[at + 3]) << 24;
    };
    const std::uint32_t w = u32(20), h = u32(24);
    if (w == 0 || h == 0 || w > 16384 || h > 16384) return make_error("The KTX2 file has an invalid size", "Export the texture again.");
    return ImageSize{int(w), int(h)};
}

Result<ImageSize> texture_size(std::string_view path) {
    std::string key = fs::normalize(path);
    if (key.empty()) key = path;
    auto of_file = [](const std::string& file) -> Result<ImageSize> {
        auto bytes = fs::read_bytes(file);
        if (!bytes) return bytes.error();
        if (fs::extension(file) == kTextureTwinExtension) return ktx2_size(bytes->data(), bytes->size());
        int w = 0, h = 0, comp = 0;
        if (!stbi_info_from_memory(bytes->data(), int(bytes->size()), &w, &h, &comp) || w <= 0 || h <= 0)
            return make_error("'" + file + "': cannot read the image size", "Supported formats: PNG, JPG, TGA, BMP. Re-export the file from your image editor.");
        return ImageSize{w, h};
    };
    if (fs::exists(key)) return of_file(key);
    if (const assets::PackedTexture packed = assets::packed_texture(key); !packed.atlas.empty()) return ImageSize{packed.w, packed.h};
    const std::string twin = key + kTextureTwinExtension;
    if (fs::exists(twin)) return of_file(twin);
    return make_error("file not found: " + key);
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

std::vector<std::uint8_t> encode_png_rgb(const Image& img) {
    std::vector<std::uint8_t> out;
    if (img.empty()) return out;
    std::vector<std::uint8_t> rgb(std::size_t(img.width) * img.height * 3);
    for (std::size_t i = 0, n = std::size_t(img.width) * img.height; i < n; ++i) {
        rgb[i * 3 + 0] = img.rgba[i * 4 + 0];
        rgb[i * 3 + 1] = img.rgba[i * 4 + 1];
        rgb[i * 3 + 2] = img.rgba[i * 4 + 2];
    }
    auto write = [](void* ctx, void* data, int size) {
        auto* v = static_cast<std::vector<std::uint8_t>*>(ctx);
        const auto* p = static_cast<const std::uint8_t*>(data);
        v->insert(v->end(), p, p + size);
    };
    stbi_write_png_to_func(write, &out, img.width, img.height, 3, rgb.data(), img.width * 3);
    return out;
}

std::vector<std::uint8_t> encode_jpeg(const Image& img, int quality) {
    std::vector<std::uint8_t> out;
    if (img.empty()) return out;
    auto write = [](void* ctx, void* data, int size) {
        auto* v = static_cast<std::vector<std::uint8_t>*>(ctx);
        const auto* p = static_cast<const std::uint8_t*>(data);
        v->insert(v->end(), p, p + size);
    };
    stbi_write_jpg_to_func(write, &out, img.width, img.height, 4, img.rgba.data(), std::clamp(quality, 1, 100));  // alpha ignored
    return out;
}

Result<void> save_png(const Image& img, std::string_view path) {
    if (img.empty()) return make_error("Cannot save an empty image to '" + std::string(path) + "'");
    std::vector<std::uint8_t> png = encode_png(img);
    if (png.empty()) return make_error("PNG encoding failed for '" + std::string(path) + "'");
    return fs::write_bytes(path, png.data(), png.size());
}

namespace {

// One axis of a separable resample: for every destination index, the source indices and their weights (summing to 1).
struct Tap {
    int index;
    float weight;
};

std::vector<std::vector<Tap>> make_taps(int srcN, int dstN) {
    std::vector<std::vector<Tap>> taps;
    taps.resize(std::size_t(dstN));
    const double scale = double(srcN) / double(dstN);  // source pixels per destination pixel
    for (int i = 0; i < dstN; ++i) {
        std::vector<Tap>& t = taps[std::size_t(i)];
        if (dstN < srcN) {
            // Area average: destination pixel i covers the source interval [i * scale, (i + 1) * scale).
            const double lo = double(i) * scale, hi = double(i + 1) * scale;
            const int first = int(std::floor(lo)), last = std::min(srcN - 1, int(std::ceil(hi)) - 1);
            for (int s = first; s <= last; ++s) {
                const double overlap = std::min(hi, double(s + 1)) - std::max(lo, double(s));
                if (overlap > 0.0) t.push_back({s, float(overlap / scale)});
            }
        } else if (dstN == srcN) {
            t.push_back({i, 1.0f});
        } else {
            // Bilinear between the two source pixel centers around the destination pixel center.
            const double c = (double(i) + 0.5) * scale - 0.5;
            const int s0 = int(std::floor(c));
            const float f = float(c - double(s0));
            const int a = std::clamp(s0, 0, srcN - 1), b = std::clamp(s0 + 1, 0, srcN - 1);
            if (a == b) {
                t.push_back({a, 1.0f});
            } else {
                t.push_back({a, 1.0f - f});
                t.push_back({b, f});
            }
        }
    }
    return taps;
}

}  // namespace

Image resize_image(const Image& src, int width, int height) {
    Image out;
    if (src.empty() || width < 1 || height < 1) return out;
    if (src.width == width && src.height == height) return src;

    const auto xTaps = make_taps(src.width, width);
    const auto yTaps = make_taps(src.height, height);

    // Premultiplied RGBA as floats: colour channels are c * a / 255 (0..255), alpha is a (0..255).
    std::vector<float> pre(std::size_t(src.width) * src.height * 4);
    for (std::size_t i = 0, n = std::size_t(src.width) * src.height; i < n; ++i) {
        const float a = src.rgba[i * 4 + 3];
        const float k = a / 255.0f;
        pre[i * 4 + 0] = src.rgba[i * 4 + 0] * k;
        pre[i * 4 + 1] = src.rgba[i * 4 + 1] * k;
        pre[i * 4 + 2] = src.rgba[i * 4 + 2] * k;
        pre[i * 4 + 3] = a;
    }

    // Horizontal pass: width x src.height.
    std::vector<float> mid(std::size_t(width) * src.height * 4, 0.0f);
    for (int y = 0; y < src.height; ++y) {
        const float* row = &pre[std::size_t(y) * src.width * 4];
        float* dst = &mid[std::size_t(y) * width * 4];
        for (int x = 0; x < width; ++x)
            for (const Tap& t : xTaps[std::size_t(x)])
                for (int c = 0; c < 4; ++c) dst[x * 4 + c] += row[t.index * 4 + c] * t.weight;
    }
    pre = {};

    // Vertical pass, straight into bytes (un-premultiplied).
    out.width = width;
    out.height = height;
    out.rgba.assign(std::size_t(width) * height * 4, 0);
    std::vector<float> acc(std::size_t(width) * 4);
    for (int y = 0; y < height; ++y) {
        std::fill(acc.begin(), acc.end(), 0.0f);
        for (const Tap& t : yTaps[std::size_t(y)]) {
            const float* row = &mid[std::size_t(t.index) * width * 4];
            for (std::size_t i = 0; i < acc.size(); ++i) acc[i] += row[i] * t.weight;
        }
        std::uint8_t* dst = &out.rgba[std::size_t(y) * width * 4];
        for (int x = 0; x < width; ++x) {
            const float a = std::clamp(acc[std::size_t(x) * 4 + 3], 0.0f, 255.0f);
            if (a <= 0.0f) continue;  // fully transparent: black (0, 0, 0, 0)
            const float inv = 255.0f / a;
            for (int c = 0; c < 3; ++c)
                dst[x * 4 + c] = std::uint8_t(std::clamp(acc[std::size_t(x) * 4 + std::size_t(c)] * inv, 0.0f, 255.0f) + 0.5f);
            dst[x * 4 + 3] = std::uint8_t(a + 0.5f);
        }
    }
    return out;
}

Image fit_image(const Image& src, int size, float scale, Color background) {
    Image out;
    if (size < 1) return out;
    out.width = size;
    out.height = size;
    out.rgba.resize(std::size_t(size) * size * 4);
    const Color bg = background;
    const auto q = [](float v) { return std::uint8_t(saturate(v) * 255.0f + 0.5f); };
    for (std::size_t i = 0, n = std::size_t(size) * size; i < n; ++i) {
        out.rgba[i * 4 + 0] = q(bg.r);
        out.rgba[i * 4 + 1] = q(bg.g);
        out.rgba[i * 4 + 2] = q(bg.b);
        out.rgba[i * 4 + 3] = q(bg.a);
    }
    if (src.empty() || !(scale > 0.0f)) return out;

    const double target = double(size) * double(scale);  // length of the longer side, in pixels
    const double longest = double(std::max(src.width, src.height));
    const int tw = std::max(1, int(std::lround(double(src.width) * target / longest)));
    const int th = std::max(1, int(std::lround(double(src.height) * target / longest)));
    const Image scaled = resize_image(src, tw, th);
    const int ox = (size - tw) / 2, oy = (size - th) / 2;  // truncates toward zero: a crop is centered within a pixel

    for (int y = 0; y < th; ++y) {
        const int dy = oy + y;
        if (dy < 0 || dy >= size) continue;
        for (int x = 0; x < tw; ++x) {
            const int dx = ox + x;
            if (dx < 0 || dx >= size) continue;
            const std::uint8_t* s = &scaled.rgba[(std::size_t(y) * tw + x) * 4];
            std::uint8_t* d = &out.rgba[(std::size_t(dy) * size + dx) * 4];
            const float sa = s[3] / 255.0f, ba = d[3] / 255.0f;
            const float oa = sa + ba * (1.0f - sa);
            if (oa <= 0.0f) {
                d[0] = d[1] = d[2] = d[3] = 0;
                continue;
            }
            for (int c = 0; c < 3; ++c) {
                const float v = (s[c] * sa + d[c] * ba * (1.0f - sa)) / oa;
                d[c] = std::uint8_t(std::clamp(v, 0.0f, 255.0f) + 0.5f);
            }
            d[3] = std::uint8_t(oa * 255.0f + 0.5f);
        }
    }
    return out;
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

namespace {

float srgb_to_linear(float v) { return v <= 0.04045f ? v / 12.92f : std::pow((v + 0.055f) / 1.055f, 2.4f); }
float linear_to_srgb(float v) {
    v = saturate(v);
    return v <= 0.0031308f ? v * 12.92f : 1.055f * std::pow(v, 1.0f / 2.4f) - 0.055f;
}

// Machado, Oliveira, Fernandes 2009, "A Physiologically-based Model for Simulation of Color Vision Deficiency", severity
// 1.0 (the cone is missing), rows of the 3x3 matrix applied to linear RGB. The shader (colorfilter.glsl) uses the same numbers.
constexpr float kProtanopia[9] = {0.152286f, 1.052583f, -0.204868f, 0.114503f, 0.786281f, 0.099216f, -0.003882f, -0.048116f, 1.051998f};
constexpr float kDeuteranopia[9] = {0.367322f, 0.860646f, -0.227968f, 0.280085f, 0.672501f, 0.047413f, -0.011820f, 0.042940f, 0.968881f};
constexpr float kTritanopia[9] = {1.255528f, -0.076749f, -0.178779f, -0.078411f, 0.930809f, 0.147602f, 0.004733f, 0.691367f, 0.303900f};

}  // namespace

Result<ColorSimulation> parse_color_simulation(std::string_view name) {
    static const std::pair<const char*, ColorSimulation> kModes[] = {{"none", ColorSimulation::None},
                                                                      {"greyscale", ColorSimulation::Greyscale},
                                                                      {"protanopia", ColorSimulation::Protanopia},
                                                                      {"deuteranopia", ColorSimulation::Deuteranopia},
                                                                      {"tritanopia", ColorSimulation::Tritanopia}};
    std::vector<std::string> names;
    for (const auto& [n, m] : kModes) {
        if (name == n) return m;
        names.push_back(n);
    }
    return make_error("Unknown colour simulation '" + std::string(name) + "'.",
                      did_you_mean(name, names));
}

Color simulate_color_vision(Color c, ColorSimulation mode) {
    if (mode == ColorSimulation::None) return c;
    const float r = srgb_to_linear(saturate(c.r)), g = srgb_to_linear(saturate(c.g)), b = srgb_to_linear(saturate(c.b));
    float o[3];
    if (mode == ColorSimulation::Greyscale) {
        o[0] = o[1] = o[2] = 0.2126f * r + 0.7152f * g + 0.0722f * b;
    } else {
        const float* m = mode == ColorSimulation::Protanopia ? kProtanopia : mode == ColorSimulation::Deuteranopia ? kDeuteranopia : kTritanopia;
        for (int i = 0; i < 3; ++i) o[i] = m[i * 3] * r + m[i * 3 + 1] * g + m[i * 3 + 2] * b;
    }
    return Color{linear_to_srgb(o[0]), linear_to_srgb(o[1]), linear_to_srgb(o[2]), c.a};
}

void simulate_color_vision(Image& img, ColorSimulation mode) {
    if (mode == ColorSimulation::None) return;
    for (std::size_t i = 0; i + 3 < img.rgba.size(); i += 4) {
        std::uint8_t* p = &img.rgba[i];
        const Color o = simulate_color_vision(Color::rgba8(p[0], p[1], p[2], p[3]), mode);
        auto q = [](float v) { return std::uint8_t(saturate(v) * 255.0f + 0.5f); };
        p[0] = q(o.r);
        p[1] = q(o.g);
        p[2] = q(o.b);
    }
}

}  // namespace fa

// ---- zlib helpers (fa/core/compress.h): they live here because this unit owns the stb implementations ----
#include "fa/core/compress.h"

namespace fa {

std::string zlib_compress(std::string_view data) {
    int outLen = 0;
    unsigned char* z = stbi_zlib_compress(reinterpret_cast<unsigned char*>(const_cast<char*>(data.data())),
                                          static_cast<int>(data.size()), &outLen, 8);
    if (!z) return {};
    std::string out(reinterpret_cast<const char*>(z), static_cast<std::size_t>(outLen));
    STBIW_FREE(z);
    return out;
}

Result<std::string> zlib_decompress(std::string_view stream, std::size_t expectedSize) {
    int outLen = 0;
    char* p = stbi_zlib_decode_malloc_guesssize_headerflag(stream.data(), static_cast<int>(stream.size()),
                                                           static_cast<int>(expectedSize > 0 ? expectedSize : stream.size() * 4 + 64), &outLen, 1);
    if (!p) return Error{"the compressed data is damaged or cut short", "Write the value again with storage.set."};
    std::string out(p, static_cast<std::size_t>(outLen));
    STBI_FREE(p);
    return out;
}

}  // namespace fa
