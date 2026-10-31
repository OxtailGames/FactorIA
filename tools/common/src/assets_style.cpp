// Painterly post-processing of a rasterized picture (assets.rasterize_svg `style`): watercolour, ink, ink and wash, paper
// grain. nanosvg draws flat vector shapes, so the "hand made" look is added to the pixels afterwards: the edges wobble, the
// pigment pools darker along the borders of a shape and varies from blotch to blotch, granulates, and an ink line follows
// the borders. Every random choice is an integer hash of (lattice cell, seed), never rand() or the clock, so the same
// picture, style, strength and seed give the same pixels. All the sizes scale with the picture, so a 128 px icon and a
// 1024 px illustration look alike.
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <string>
#include <vector>

#include "assets_internal.h"

namespace fa::assets_detail {

namespace {

using u32 = std::uint32_t;

u32 mix_bits(u32 h) {
    h ^= h >> 16;
    h *= 0x7feb352du;
    h ^= h >> 15;
    h *= 0x846ca68bu;
    h ^= h >> 16;
    return h;
}
double lattice(int x, int y, u32 seed) {  // [-1, 1)
    const u32 h = mix_bits(u32(x) * 0x9E3779B1u ^ mix_bits(u32(y) * 0x85EBCA77u + seed));
    return double(h >> 8) * (2.0 / 16777216.0) - 1.0;
}
// Smooth value noise in [-1, 1] whose features are `period` pixels wide.
double noise(double px, double py, double period, u32 seed) {
    const double x = px / period, y = py / period;
    const int ix = int(std::floor(x)), iy = int(std::floor(y));
    const double fx = x - ix, fy = y - iy;
    const double sx = fx * fx * (3 - 2 * fx), sy = fy * fy * (3 - 2 * fy);
    const double a = lattice(ix, iy, seed), b = lattice(ix + 1, iy, seed), c = lattice(ix, iy + 1, seed), d = lattice(ix + 1, iy + 1, seed);
    return (a + (b - a) * sx) + ((c + (d - c) * sx) - (a + (b - a) * sx)) * sy;
}
double fbm(double px, double py, double period, int octaves, u32 seed) {
    double sum = 0, amp = 1, norm = 0;
    for (int i = 0; i < octaves; ++i) {
        sum += amp * noise(px, py, period, seed + u32(i) * 101u);
        norm += amp;
        amp *= 0.5;
        period *= 0.5;
    }
    return sum / norm;
}
double smoothstep(double e0, double e1, double x) {
    const double t = std::clamp((x - e0) / (e1 - e0), 0.0, 1.0);
    return t * t * (3 - 2 * t);
}

// Premultiplied float pixels, 0..1.
struct Px {
    float r = 0, g = 0, b = 0, a = 0;
};
struct Pic {
    int w = 0, h = 0;
    std::vector<Px> px;
    Px& at(int x, int y) { return px[std::size_t(y) * w + x]; }
    const Px& at(int x, int y) const { return px[std::size_t(y) * w + x]; }
    Px clamped(int x, int y) const { return at(std::clamp(x, 0, w - 1), std::clamp(y, 0, h - 1)); }
};

Pic from_image(const Image& img) {
    Pic p;
    p.w = img.width;
    p.h = img.height;
    p.px.resize(std::size_t(p.w) * p.h);
    for (std::size_t i = 0; i < p.px.size(); ++i) {
        const float a = img.rgba[i * 4 + 3] / 255.0f;
        p.px[i] = {img.rgba[i * 4] / 255.0f * a, img.rgba[i * 4 + 1] / 255.0f * a, img.rgba[i * 4 + 2] / 255.0f * a, a};
    }
    return p;
}
void to_image(const Pic& p, Image& img) {
    for (std::size_t i = 0; i < p.px.size(); ++i) {
        const Px& q = p.px[i];
        const float a = std::clamp(q.a, 0.0f, 1.0f);
        auto byte = [](double v) { return std::uint8_t(std::clamp(std::lround(v * 255.0), 0L, 255L)); };
        img.rgba[i * 4] = a > 0 ? byte(q.r / a) : 0;
        img.rgba[i * 4 + 1] = a > 0 ? byte(q.g / a) : 0;
        img.rgba[i * 4 + 2] = a > 0 ? byte(q.b / a) : 0;
        img.rgba[i * 4 + 3] = byte(a);
    }
}

// Box blur (two separable passes, edge clamped) of radius `r` pixels.
Pic box_blur(const Pic& in, int r) {
    if (r < 1) return in;
    Pic tmp = in, out = in;
    const float k = 1.0f / float(2 * r + 1);
    for (int y = 0; y < in.h; ++y) {
        for (int x = 0; x < in.w; ++x) {
            Px s;
            for (int d = -r; d <= r; ++d) {
                const Px& q = in.clamped(x + d, y);
                s.r += q.r; s.g += q.g; s.b += q.b; s.a += q.a;
            }
            tmp.at(x, y) = {s.r * k, s.g * k, s.b * k, s.a * k};
        }
    }
    for (int y = 0; y < in.h; ++y) {
        for (int x = 0; x < in.w; ++x) {
            Px s;
            for (int d = -r; d <= r; ++d) {
                const Px& q = tmp.clamped(x, y + d);
                s.r += q.r; s.g += q.g; s.b += q.b; s.a += q.a;
            }
            out.at(x, y) = {s.r * k, s.g * k, s.b * k, s.a * k};
        }
    }
    return out;
}

// Moves every pixel by a smooth random offset of up to `amp` pixels: straight edges become hand-drawn.
Pic wobble(const Pic& in, double amp, double period, u32 seed) {
    Pic out = in;
    for (int y = 0; y < in.h; ++y) {
        for (int x = 0; x < in.w; ++x) {
            const double sx = x + amp * (fbm(x + 0.5, y + 0.5, period, 2, seed + 1u)) + amp * 0.35 * noise(x, y, period * 0.3, seed + 7u);
            const double sy = y + amp * (fbm(x + 0.5, y + 0.5, period, 2, seed + 2u)) + amp * 0.35 * noise(x, y, period * 0.3, seed + 8u);
            const double fx = sx - 0.5, fy = sy - 0.5;  // pixel centres
            const int ix = int(std::floor(fx)), iy = int(std::floor(fy));
            const double tx = fx - ix, ty = fy - iy;
            const Px a = in.clamped(ix, iy), b = in.clamped(ix + 1, iy), c = in.clamped(ix, iy + 1), d = in.clamped(ix + 1, iy + 1);
            auto bil = [&](float Px::*m) {
                return float((a.*m * (1 - tx) + b.*m * tx) * (1 - ty) + (c.*m * (1 - tx) + d.*m * tx) * ty);
            };
            out.at(x, y) = {bil(&Px::r), bil(&Px::g), bil(&Px::b), bil(&Px::a)};
        }
    }
    return out;
}

// How different a pixel is from its neighbourhood (premultiplied colour and alpha): high on a border, 0 in a flat area.
double border_strength(const Px& p, const Px& blurred) {
    return std::fabs(p.r - blurred.r) + std::fabs(p.g - blurred.g) + std::fabs(p.b - blurred.b) + 1.5 * std::fabs(p.a - blurred.a);
}

void scale_colour(Px& p, double k) {
    p.r = float(p.r * k);
    p.g = float(p.g * k);
    p.b = float(p.b * k);
}

void watercolour(Pic& pic, double s, u32 seed, double ref) {
    const Pic soft = box_blur(pic, std::max(1, int(std::lround(ref * 0.0035))));
    const Pic wide = box_blur(pic, std::max(2, int(std::lround(ref * 0.011))));
    const double grainPeriod = std::max(2.0, ref / 190.0);
    for (int y = 0; y < pic.h; ++y) {
        for (int x = 0; x < pic.w; ++x) {
            Px p = pic.at(x, y);
            const Px& sp = soft.at(x, y);
            // pigment bleeds a little into its surroundings
            const float bleed = float(0.55 * s);
            p = {p.r + (sp.r - p.r) * bleed, p.g + (sp.g - p.g) * bleed, p.b + (sp.b - p.b) * bleed, p.a + (sp.a - p.a) * bleed};
            if (p.a <= 0.002f) { pic.at(x, y) = p; continue; }
            // pigment pools along the borders of a shape (the dark rim of a wash)
            const double rim = smoothstep(0.02, 0.30, border_strength(pic.at(x, y), wide.at(x, y)));
            scale_colour(p, 1.0 - 0.42 * s * rim);
            // a wash is never even: paler and stronger blotches, a few of them large
            const double wash = fbm(x + 0.5, y + 0.5, ref / 4.0, 3, seed + 21u);
            const double blotch = 1.0 + 0.16 * s * wash;
            scale_colour(p, blotch);
            if (wash > 0.15) {  // pale patches: less pigment, so the paper shows through
                const double pale = 0.45 * s * smoothstep(0.15, 0.55, wash);
                p.r = float(p.r + (p.a - p.r) * pale * 0.35);
                p.g = float(p.g + (p.a - p.g) * pale * 0.35);
                p.b = float(p.b + (p.a - p.b) * pale * 0.35);
            }
            // granulation: pigment settling in the tooth of the paper
            const double g = 0.5 + 0.5 * noise(x + 0.5, y + 0.5, grainPeriod, seed + 33u);
            const double g2 = 0.5 + 0.5 * noise(x + 0.5, y + 0.5, grainPeriod * 3.0, seed + 34u);
            scale_colour(p, 1.0 - 0.07 * s * std::pow(g, 2.0) - 0.04 * s * g2);
            // the edges of the wash are ragged: a little of the alpha is eaten where the paper's tooth is high
            if (rim > 0.05) p.a = float(p.a * (1.0 - 0.12 * s * rim * g));
            pic.at(x, y) = p;
        }
    }
}

// The pen line along the borders of `pic`: how much ink (0..1) each pixel gets.
std::vector<float> ink_line(const Pic& pic, double s, u32 seed, double ref) {
    const int r = std::max(1, int(std::lround(ref * 0.0045)));
    const Pic around = box_blur(pic, r);
    std::vector<float> line(pic.px.size(), 0.0f);
    for (int y = 0; y < pic.h; ++y) {
        for (int x = 0; x < pic.w; ++x) {
            // the pen presses harder in places: the line thickens and thins along the border
            const double press = 0.75 + 0.5 * (0.5 + 0.5 * noise(x + 0.5, y + 0.5, ref / 14.0, seed + 41u));
            line[std::size_t(y) * pic.w + x] = float(s * smoothstep(0.10, 0.34, border_strength(pic.at(x, y), around.at(x, y)) * press * 2.2));
        }
    }
    return line;
}

// Lays dark brown ink over the picture where `line` says so (and makes those pixels opaque).
void ink_apply(Pic& pic, const std::vector<float>& line) {
    const double inkR = 0.14, inkG = 0.10, inkB = 0.08;
    for (std::size_t i = 0; i < pic.px.size(); ++i) {
        const double l = line[i];
        if (l <= 0) continue;
        Px& p = pic.px[i];
        p.r = float(p.r * (1 - l) + inkR * l);
        p.g = float(p.g * (1 - l) + inkG * l);
        p.b = float(p.b * (1 - l) + inkB * l);
        p.a = float(std::max<double>(p.a, l));
    }
}

void paper_grain(Pic& pic, double s, u32 seed, double ref) {
    const double tooth = std::max(1.4, ref / 320.0);
    for (int y = 0; y < pic.h; ++y) {
        for (int x = 0; x < pic.w; ++x) {
            Px p = pic.at(x, y);
            if (p.a <= 0.002f) continue;
            const double fine = noise(x + 0.5, y + 0.5, tooth, seed + 51u);
            const double fibre = noise(x * 0.35 + 0.5, y + 0.5, tooth * 2.5, seed + 52u);  // short horizontal fibres
            const double mottle = fbm(x + 0.5, y + 0.5, ref / 3.0, 2, seed + 53u);
            scale_colour(p, 1.0 + s * (0.09 * fine + 0.05 * fibre + 0.07 * mottle));
            pic.at(x, y) = p;
        }
    }
}

}  // namespace

const std::vector<std::string>& image_style_names() {
    static const std::vector<std::string> names = {"none", "watercolor", "ink", "inkwash", "paper"};
    return names;
}

void apply_image_style(Image& image, const std::string& style, double strength, std::uint32_t seed) {
    const double s = std::clamp(strength, 0.0, 1.0);
    if (style == "none" || s <= 0.0 || image.width < 1 || image.height < 1) return;  // strength 0: the picture as drawn
    const double ref = std::min(image.width, image.height);
    const u32 sd = mix_bits(seed ^ 0x5bd1e995u);
    Pic pic = from_image(image);
    if (style == "watercolor") {
        pic = wobble(pic, ref * 0.0045 * s + 0.4, ref / 9.0, sd);
        watercolour(pic, s, sd, ref);
    } else if (style == "ink") {
        pic = wobble(pic, ref * 0.0035 * s + 0.3, ref / 10.0, sd + 5u);
        ink_apply(pic, ink_line(pic, s, sd, ref));
    } else if (style == "inkwash") {
        pic = wobble(pic, ref * 0.0040 * s + 0.4, ref / 9.0, sd);
        const std::vector<float> line = ink_line(pic, s, sd, ref);  // from the clean shapes, not from the grain
        watercolour(pic, s, sd, ref);
        paper_grain(pic, s * 0.6, sd, ref);
        ink_apply(pic, line);
    } else if (style == "paper") {
        paper_grain(pic, s, sd, ref);
    }
    to_image(pic, image);
}

}  // namespace fa::assets_detail
