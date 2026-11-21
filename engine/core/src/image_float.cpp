#include "fa/core/image_float.h"

#include <algorithm>
#include <cmath>
#include <format>
#include <limits>
#include <new>

namespace fa {

std::uint64_t image_float_bytes(std::int64_t width, std::int64_t height, int channels) {
    if (width <= 0 || height <= 0 || channels <= 0) return 0;
    constexpr std::uint64_t kMax = std::numeric_limits<std::uint64_t>::max();
    const std::uint64_t w = std::uint64_t(width), h = std::uint64_t(height);
    if (w > kMax / h) return kMax;
    const std::uint64_t pixels = w * h;
    const std::uint64_t perPixel = std::uint64_t(channels) * sizeof(float);
    if (pixels > kMax / perPixel) return kMax;
    return pixels * perPixel;
}

float srgb_to_linear(float encoded) {
    if (!(encoded > 0.0f)) return 0.0f;  // also NaN
    if (encoded >= 1.0f) return 1.0f;
    return encoded <= 0.04045f ? encoded / 12.92f : std::pow((encoded + 0.055f) / 1.055f, 2.4f);
}

float linear_to_srgb(float linear) {
    if (!(linear > 0.0f)) return 0.0f;
    if (linear >= 1.0f) return 1.0f;
    return linear <= 0.0031308f ? linear * 12.92f : 1.055f * std::pow(linear, 1.0f / 2.4f) - 0.055f;
}

Result<ImageF> ImageF::create(int newWidth, int newHeight, int channelCount) {
    if (newWidth < 1 || newHeight < 1)
        return make_error(std::format("Cannot create a float image of {} x {} pixels: both sides must be at least 1",
                                      newWidth, newHeight),
                          "Give a positive width and height.");
    if (newWidth > kMaxImageFloatSide || newHeight > kMaxImageFloatSide)
        return make_error(std::format("Cannot create a float image of {} x {} pixels: the longest side the engine "
                                      "handles is {}",
                                      newWidth, newHeight, kMaxImageFloatSide),
                          "Scale the image down (an 8192 x 4096 panorama is enough for an environment map).");
    if (channelCount != 3 && channelCount != 4)
        return make_error(
            std::format("Cannot create a float image with {} channels: only 3 (RGB) or 4 (RGBA)", channelCount),
            "Use 3 for colour only or 4 for colour and alpha.");
    const std::uint64_t bytes = image_float_bytes(newWidth, newHeight, channelCount);
    if (bytes > kMaxImageFloatBytes)
        return make_error(std::format("Cannot create a float image of {} x {} pixels with {} channels: it needs {} MB, "
                                      "more than the {} MB the engine allows",
                                      newWidth, newHeight, channelCount, bytes / (1024 * 1024),
                                      kMaxImageFloatBytes / (1024 * 1024)),
                          "Scale the image down: halving both sides takes a quarter of the memory.");
    ImageF img;
    img.width = newWidth;
    img.height = newHeight;
    img.channels = channelCount;
    try {
        img.data.assign(std::size_t(bytes / sizeof(float)), 0.0f);
    } catch (const std::bad_alloc&) {
        return make_error(
            std::format("Cannot create a float image of {} x {} pixels: out of memory", newWidth, newHeight),
            "Close other programs or scale the image down.");
    }
    return img;
}

Color ImageF::pixel(int x, int y) const {
    if (x < 0 || y < 0 || x >= width || y >= height || data.empty()) return Color{0, 0, 0, 0};
    const float* p = at(x, y);
    return Color{p[0], p[1], p[2], channels == 4 ? p[3] : 1.0f};
}

void ImageF::set_pixel(int x, int y, Color c) {
    if (x < 0 || y < 0 || x >= width || y >= height || data.empty()) return;
    float* p = at(x, y);
    p[0] = c.r;
    p[1] = c.g;
    p[2] = c.b;
    if (channels == 4) p[3] = c.a;
}

namespace {

int wrap_index(int i, int n, ImageWrap mode) {
    if (mode == ImageWrap::Repeat) {
        const int m = i % n;
        return m < 0 ? m + n : m;
    }
    return std::clamp(i, 0, n - 1);
}

}  // namespace

Color ImageF::sample(float u, float v, ImageWrap wrapU, ImageWrap wrapV) const {
    if (empty()) return Color{0, 0, 0, 0};
    // A non-finite or huge coordinate must not reach the float -> int conversion.
    auto texel = [](float coord, int size) {
        if (!std::isfinite(coord)) coord = 0.0f;
        return std::clamp(coord * float(size) - 0.5f, -1.0e9f, 1.0e9f);
    };
    const float x = texel(u, width), y = texel(v, height);
    const float fx0 = std::floor(x), fy0 = std::floor(y);
    const float tx = x - fx0, ty = y - fy0;
    const int x0 = int(fx0), y0 = int(fy0);
    const int xa = wrap_index(x0, width, wrapU), xb = wrap_index(x0 + 1, width, wrapU);
    const int ya = wrap_index(y0, height, wrapV), yb = wrap_index(y0 + 1, height, wrapV);
    const Color c00 = pixel(xa, ya), c10 = pixel(xb, ya), c01 = pixel(xa, yb), c11 = pixel(xb, yb);
    auto mix = [&](float a, float b, float c, float d) {
        return (a * (1 - tx) + b * tx) * (1 - ty) + (c * (1 - tx) + d * tx) * ty;
    };
    return Color{mix(c00.r, c10.r, c01.r, c11.r), mix(c00.g, c10.g, c01.g, c11.g), mix(c00.b, c10.b, c01.b, c11.b),
                 mix(c00.a, c10.a, c01.a, c11.a)};
}

namespace {

struct Tap {
    int index;
    float weight;
};

// One axis of a separable resample: for each destination index, the source indices and weights (summing to 1).
std::vector<std::vector<Tap>> make_taps(int srcN, int dstN) {
    std::vector<std::vector<Tap>> taps(static_cast<std::size_t>(dstN));
    const double scale = double(srcN) / double(dstN);  // source pixels per destination pixel
    for (int i = 0; i < dstN; ++i) {
        std::vector<Tap>& t = taps[std::size_t(i)];
        if (dstN < srcN) {
            const double lo = double(i) * scale, hi = double(i + 1) * scale;
            const int first = int(std::floor(lo)), last = std::min(srcN - 1, int(std::ceil(hi)) - 1);
            double sum = 0;
            for (int s = first; s <= last; ++s) {
                const double overlap = std::min(hi, double(s + 1)) - std::max(lo, double(s));
                if (overlap <= 0) continue;
                t.push_back({s, float(overlap)});
                sum += overlap;
            }
            for (Tap& tap : t) tap.weight = float(double(tap.weight) / sum);
        } else {
            const double pos = (double(i) + 0.5) * scale - 0.5;
            const int p0 = int(std::floor(pos));
            const float f = float(pos - double(p0));
            t.push_back({std::clamp(p0, 0, srcN - 1), 1.0f - f});
            if (f > 0.0f) t.push_back({std::clamp(p0 + 1, 0, srcN - 1), f});
        }
    }
    return taps;
}

}  // namespace

Result<ImageF> ImageF::resized(int newWidth, int newHeight) const {
    if (empty()) return make_error("Cannot resize an empty float image", "Load or create the image first.");
    auto out = ImageF::create(newWidth, newHeight, channels);
    if (!out) return out.error();
    out->exposure = exposure;
    if (newWidth == width && newHeight == height) {
        out->data = data;
        return out;
    }
    const auto xTaps = make_taps(width, newWidth), yTaps = make_taps(height, newHeight);
    const std::size_t ch = std::size_t(channels);
    // Horizontal pass into a width' x height strip, then the vertical pass: two passes keep the cost linear in the
    // taps.
    auto tmp = ImageF::create(newWidth, height, channels);
    if (!tmp) return tmp.error();
    for (int y = 0; y < height; ++y)
        for (int x = 0; x < newWidth; ++x) {
            float* d = tmp->at(x, y);
            for (const Tap& t : xTaps[std::size_t(x)]) {
                const float* s = at(t.index, y);
                for (std::size_t c = 0; c < ch; ++c) d[c] += s[c] * t.weight;
            }
        }
    for (int y = 0; y < newHeight; ++y)
        for (int x = 0; x < newWidth; ++x) {
            float* d = out->at(x, y);
            for (const Tap& t : yTaps[std::size_t(y)]) {
                const float* s = tmp->at(x, t.index);
                for (std::size_t c = 0; c < ch; ++c) d[c] += s[c] * t.weight;
            }
        }
    return out;
}

Result<ImageF> ImageF::from_image(const Image& image, bool srgb, float gain, int channelCount) {
    if (image.empty() || image.rgba.size() < std::size_t(image.width) * std::size_t(image.height) * 4)
        return make_error("Cannot convert an empty image to float", "Load or create the image first.");
    auto out = ImageF::create(image.width, image.height, channelCount);
    if (!out) return out.error();
    float lut[256];
    for (int i = 0; i < 256; ++i) lut[i] = srgb ? srgb_to_linear(float(i) / 255.0f) : float(i) / 255.0f;
    const std::size_t count = std::size_t(image.width) * std::size_t(image.height);
    const std::size_t ch = std::size_t(channelCount);
    for (std::size_t i = 0; i < count; ++i) {
        const std::uint8_t* s = &image.rgba[i * 4];
        float* d = &out->data[i * ch];
        d[0] = lut[s[0]] * gain;
        d[1] = lut[s[1]] * gain;
        d[2] = lut[s[2]] * gain;
        if (ch == 4) d[3] = float(s[3]) / 255.0f;
    }
    return out;
}

Image ImageF::to_image(bool srgb, float gain) const {
    Image img;
    if (empty()) return img;
    img.width = width;
    img.height = height;
    img.rgba.resize(std::size_t(width) * std::size_t(height) * 4);
    const std::size_t count = std::size_t(width) * std::size_t(height);
    const std::size_t ch = std::size_t(channels);
    auto byte = [&](float v) {
        float c = v * gain;
        if (!(c > 0.0f)) c = 0.0f;  // also NaN
        if (c > 1.0f) c = 1.0f;
        if (srgb) c = linear_to_srgb(c);
        return std::uint8_t(c * 255.0f + 0.5f);
    };
    for (std::size_t i = 0; i < count; ++i) {
        const float* s = &data[i * ch];
        std::uint8_t* d = &img.rgba[i * 4];
        d[0] = byte(s[0]);
        d[1] = byte(s[1]);
        d[2] = byte(s[2]);
        if (ch == 4) {
            const float a = s[3];
            d[3] = std::uint8_t((a > 0.0f ? (a < 1.0f ? a : 1.0f) : 0.0f) * 255.0f + 0.5f);
        } else {
            d[3] = 255;
        }
    }
    return img;
}

}  // namespace fa
