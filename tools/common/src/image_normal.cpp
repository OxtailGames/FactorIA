// Normal maps as pictures you can edit (fa/tooling/image_normal.h): the generator on the engine's kernel, the edits that keep a map unit
// length, and the CPU lighting the Image panel previews with.
#include "fa/tooling/image_normal.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <vector>

#include "fa/core/image_tools.h"

namespace fa {

namespace {

constexpr double kDegToRadD = 3.14159265358979323846 / 180.0;

std::uint8_t encode_byte(double n) {
    return std::uint8_t(std::clamp(std::floor((n * 0.5 + 0.5) * 255.0 + 0.5), 0.0, 255.0));
}
double decode_byte(std::uint8_t b) { return double(b) / 127.5 - 1.0; }

struct Vec {
    double x = 0, y = 0, z = 1;
};

Vec decode(const std::uint8_t* p) { return {decode_byte(p[0]), decode_byte(p[1]), decode_byte(p[2])}; }

// Unit length, z never negative; a vector with no length is the flat normal.
Vec unit(Vec v) {
    v.z = std::max(v.z, 0.0);
    const double len = std::sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
    if (len < 1e-6) return {0, 0, 1};
    return {v.x / len, v.y / len, v.z / len};
}

void encode(std::uint8_t* p, const Vec& v) {
    p[0] = encode_byte(v.x);
    p[1] = encode_byte(v.y);
    p[2] = encode_byte(v.z);
}

bool usable(const Image& img) {
    return !img.empty() && img.rgba.size() >= std::size_t(img.width) * std::size_t(img.height) * 4;
}

}  // namespace

Image make_normal_map(const Image& src, const std::string& from, double strength, bool tile) {
    if (!usable(src)) return Image{};
    if (from == "sprite")
        return normal_map_from_height(sprite_height_field(src), src.width, src.height, tile, strength);
    if (from == "height") {
        std::vector<double> hf(std::size_t(src.width) * std::size_t(src.height));
        for (std::size_t i = 0; i < hf.size(); ++i) {
            hf[i] = luminance01(&src.rgba[i * 4]);
        }
        return normal_map_from_height(hf, src.width, src.height, tile, strength);
    }
    return Image{};
}

Color normal_direction_color(double azimuthDegrees, double tiltDegrees) {
    const double tilt = std::clamp(tiltDegrees, 0.0, 89.0) * kDegToRadD, az = azimuthDegrees * kDegToRadD;
    const double s = std::sin(tilt);
    std::uint8_t px[3];
    encode(px, {s * std::cos(az), s * std::sin(az), std::cos(tilt)});
    return Color(float(px[0]) / 255.0f, float(px[1]) / 255.0f, float(px[2]) / 255.0f, 1.0f);
}

void normal_map_flip(Image& map, bool flipX, bool flipY) {
    if (!usable(map)) return;
    const std::size_t n = std::size_t(map.width) * std::size_t(map.height);
    for (std::size_t i = 0; i < n; ++i) {
        std::uint8_t* p = &map.rgba[i * 4];
        if (p[3] == 0) continue;
        if (flipX) p[0] = std::uint8_t(255 - p[0]);
        if (flipY) p[1] = std::uint8_t(255 - p[1]);
    }
}

void normal_map_smooth(Image& map, double sigma, bool tile) {
    if (!usable(map) || !(sigma > 0.0)) return;
    sigma = std::min(sigma, 64.0);
    const int w = map.width, h = map.height, radius = std::max(1, int(std::ceil(sigma * 3.0)));
    std::vector<double> kernel(std::size_t(radius) * 2 + 1);
    double sum = 0;
    for (int i = -radius; i <= radius; ++i) {
        const double v = std::exp(-double(i) * double(i) / (2.0 * sigma * sigma));
        kernel[std::size_t(i + radius)] = v;
        sum += v;
    }
    for (double& v : kernel) v /= sum;
    const std::size_t count = std::size_t(w) * std::size_t(h);
    // three planes: a transparent pixel counts as flat so it pulls its neighbours towards the plane, not towards black
    std::vector<double> plane[3], tmp[3];
    for (int c = 0; c < 3; ++c) plane[c].resize(count), tmp[c].resize(count);
    for (std::size_t i = 0; i < count; ++i) {
        const std::uint8_t* p = &map.rgba[i * 4];
        const Vec v = p[3] == 0 ? Vec{0, 0, 1} : decode(p);
        plane[0][i] = v.x;
        plane[1][i] = v.y;
        plane[2][i] = v.z;
    }
    auto wrap = [&](int i, int n) { return tile ? ((i % n) + n) % n : std::clamp(i, 0, n - 1); };
    for (int c = 0; c < 3; ++c) {
        for (int y = 0; y < h; ++y)
            for (int x = 0; x < w; ++x) {
                double acc = 0;
                for (int k = -radius; k <= radius; ++k)
                    acc += kernel[std::size_t(k + radius)] *
                           plane[c][std::size_t(y) * std::size_t(w) + std::size_t(wrap(x + k, w))];
                tmp[c][std::size_t(y) * std::size_t(w) + std::size_t(x)] = acc;
            }
        for (int y = 0; y < h; ++y)
            for (int x = 0; x < w; ++x) {
                double acc = 0;
                for (int k = -radius; k <= radius; ++k)
                    acc += kernel[std::size_t(k + radius)] *
                           tmp[c][std::size_t(wrap(y + k, h)) * std::size_t(w) + std::size_t(x)];
                plane[c][std::size_t(y) * std::size_t(w) + std::size_t(x)] = acc;
            }
    }
    for (std::size_t i = 0; i < count; ++i) {
        std::uint8_t* p = &map.rgba[i * 4];
        if (p[3] == 0) continue;
        encode(p, unit({plane[0][i], plane[1][i], plane[2][i]}));
    }
}

void normal_map_scale(Image& map, double amount) {
    if (!usable(map)) return;
    amount = std::clamp(amount, 0.0, 64.0);
    const std::size_t n = std::size_t(map.width) * std::size_t(map.height);
    for (std::size_t i = 0; i < n; ++i) {
        std::uint8_t* p = &map.rgba[i * 4];
        if (p[3] == 0) continue;
        const Vec v = unit(decode(p));
        // the slope is (x / z, y / z); scaling it and putting z back to 1 is (x k, y k, z) before the normalization
        encode(p, unit({v.x * amount, v.y * amount, v.z}));
    }
}

void normal_map_normalize(Image& map, bool flatten) {
    if (!usable(map)) return;
    const std::size_t n = std::size_t(map.width) * std::size_t(map.height);
    for (std::size_t i = 0; i < n; ++i) {
        std::uint8_t* p = &map.rgba[i * 4];
        if (p[3] == 0) {
            if (flatten) encode(p, {0, 0, 1}), p[3] = 255;
            continue;
        }
        Vec v = unit(decode(p));
        if (flatten && p[3] < 255) {
            const double a = double(p[3]) / 255.0;
            v = unit({v.x * a, v.y * a, v.z * a + (1.0 - a)});
        }
        encode(p, v);
        if (flatten) p[3] = 255;
    }
}

Image light_with_normal_map(const Image& base, const Image& normal, const NormalLight& light, int maxSide) {
    if (!usable(base)) return Image{};
    const int longSide = std::max(base.width, base.height);
    const double scale = maxSide > 0 && longSide > maxSide ? double(maxSide) / double(longSide) : 1.0;
    Image out;
    out.width = std::max(1, int(std::lround(double(base.width) * scale)));
    out.height = std::max(1, int(std::lround(double(base.height) * scale)));
    out.rgba.resize(std::size_t(out.width) * std::size_t(out.height) * 4);
    const bool haveNormal = usable(normal);
    const double theta = light.azimuth * kDegToRadD, elev = std::clamp(light.elevation, 1.0, 90.0) * kDegToRadD;
    const double dlx = std::cos(theta) * std::cos(elev), dly = std::sin(theta) * std::cos(elev), dlz = std::sin(elev);
    const double intensity = std::clamp(light.intensity, 0.0, 4.0);
    const double lampZ = std::max(light.height, 1.0);
    for (int oy = 0; oy < out.height; ++oy) {
        const int sy = std::min(base.height - 1, int(std::floor((double(oy) + 0.5) / scale)));
        for (int ox = 0; ox < out.width; ++ox) {
            const int sx = std::min(base.width - 1, int(std::floor((double(ox) + 0.5) / scale)));
            const std::uint8_t* b = &base.rgba[(std::size_t(sy) * std::size_t(base.width) + std::size_t(sx)) * 4];
            std::uint8_t* o = &out.rgba[(std::size_t(oy) * std::size_t(out.width) + std::size_t(ox)) * 4];
            o[0] = b[0];
            o[1] = b[1];
            o[2] = b[2];
            o[3] = b[3];
            if (b[3] == 0) continue;
            Vec n{0, 0, 1};
            if (haveNormal && sx < normal.width && sy < normal.height) {
                const std::uint8_t* t =
                    &normal.rgba[(std::size_t(sy) * std::size_t(normal.width) + std::size_t(sx)) * 4];
                if (t[3] > 0) {
                    n = decode(t);
                    if (light.flipGreen) n.y = -n.y;
                }
            }
            const double len = std::sqrt(n.x * n.x + n.y * n.y + n.z * n.z);
            if (len <= 1e-6) continue;
            double lx = dlx, ly = dly, lz = dlz;
            if (light.point) {
                // the lamp is above the picture: up the picture is -y of the pixel grid
                const double vx = light.x - (double(sx) + 0.5), vy = (double(sy) + 0.5) - light.y, vz = lampZ;
                const double vl = std::sqrt(vx * vx + vy * vy + vz * vz);
                lx = vx / vl;
                ly = vy / vl;
                lz = vz / vl;
            }
            const double lit = (n.x * lx + n.y * ly + n.z * lz) / len;
            const double f = std::max(0.0, 1.0 + 2.0 * intensity * (lit - lz));
            for (int c = 0; c < 3; ++c) o[c] = std::uint8_t(std::clamp(std::floor(double(b[c]) * f + 0.5), 0.0, 255.0));
        }
    }
    return out;
}

}  // namespace fa
