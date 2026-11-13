// The 18 blend modes of an image document and the compositing formula (W3C "Compositing and Blending Level 1", which is
// what Photoshop, GIMP and the browsers agree on). Everything is float32, straight alpha, on the stored (sRGB-encoded)
// values: see the header of fa/tooling/image_doc.h.
#include <algorithm>
#include <cmath>

#include "fa/core/strings.h"
#include "image_doc_internal.h"

namespace fa {

namespace {

constexpr const char* kBlendNames[] = {
    "normal",    "multiply",   "screen",    "overlay", "darken",   "lighten", "colorDodge", "colorBurn", "hardLight",
    "softLight", "difference", "exclusion", "add",     "subtract", "hue",     "saturation", "color",     "luminosity"};
constexpr int kBlendCount = int(sizeof(kBlendNames) / sizeof(kBlendNames[0]));

constexpr const char* kKindNames[] = {"pixels",   "fill",  "gradient",   "procedural", "svg",    "text",
                                      "provider", "group", "adjustment", "indexed",    "tileset"};

}  // namespace

const char* image_blend_name(ImageBlend mode) {
    const int i = int(mode);
    return i >= 0 && i < kBlendCount ? kBlendNames[i] : "";
}

std::optional<ImageBlend> parse_image_blend(std::string_view name) {
    for (int i = 0; i < kBlendCount; ++i)
        if (name == kBlendNames[i]) return ImageBlend(i);
    return std::nullopt;
}

std::vector<std::string> image_blend_names() {
    return std::vector<std::string>(kBlendNames, kBlendNames + kBlendCount);
}

const char* image_layer_kind_name(ImageLayerKind kind) { return kKindNames[int(kind)]; }

std::vector<std::string> image_layer_kind_names() {
    return std::vector<std::string>(std::begin(kKindNames), std::end(kKindNames));
}

}  // namespace fa

namespace fa::imgdoc {

namespace {

float hard_light(float cb, float cs) {
    if (cs <= 0.5f) return cb * (2.0f * cs);  // multiply(cb, 2 cs)
    const float s = 2.0f * cs - 1.0f;         // screen(cb, 2 cs - 1)
    return cb + s - cb * s;
}

float blend_channel(ImageBlend mode, float cb, float cs) {
    switch (mode) {
        case ImageBlend::Normal: return cs;
        case ImageBlend::Multiply: return cb * cs;
        case ImageBlend::Screen: return cb + cs - cb * cs;
        case ImageBlend::Overlay: return hard_light(cs, cb);
        case ImageBlend::Darken: return std::min(cb, cs);
        case ImageBlend::Lighten: return std::max(cb, cs);
        case ImageBlend::ColorDodge:
            if (cb == 0.0f) return 0.0f;
            if (cs >= 1.0f) return 1.0f;
            return std::min(1.0f, cb / (1.0f - cs));
        case ImageBlend::ColorBurn:
            if (cb >= 1.0f) return 1.0f;
            if (cs <= 0.0f) return 0.0f;
            return 1.0f - std::min(1.0f, (1.0f - cb) / cs);
        case ImageBlend::HardLight: return hard_light(cb, cs);
        case ImageBlend::SoftLight: {
            if (cs <= 0.5f) return cb - (1.0f - 2.0f * cs) * cb * (1.0f - cb);
            const float d = cb <= 0.25f ? ((16.0f * cb - 12.0f) * cb + 4.0f) * cb : std::sqrt(cb);
            return cb + (2.0f * cs - 1.0f) * (d - cb);
        }
        case ImageBlend::Difference: return std::fabs(cb - cs);
        case ImageBlend::Exclusion: return cb + cs - 2.0f * cb * cs;
        case ImageBlend::Add: return std::min(1.0f, cb + cs);
        case ImageBlend::Subtract: return std::max(0.0f, cb - cs);
        default: return cs;
    }
}

float lum(const float* c) { return 0.3f * c[0] + 0.59f * c[1] + 0.11f * c[2]; }
float sat(const float* c) { return std::max({c[0], c[1], c[2]}) - std::min({c[0], c[1], c[2]}); }

void clip_color(float* c) {
    const float l = lum(c);
    const float n = std::min({c[0], c[1], c[2]});
    const float x = std::max({c[0], c[1], c[2]});
    if (n < 0.0f)
        for (int i = 0; i < 3; ++i) c[i] = l + (c[i] - l) * l / (l - n);
    if (x > 1.0f)
        for (int i = 0; i < 3; ++i) c[i] = l + (c[i] - l) * (1.0f - l) / (x - l);
}

void set_lum(const float* c, float l, float* out) {
    const float d = l - lum(c);
    for (int i = 0; i < 3; ++i) out[i] = c[i] + d;
    clip_color(out);
}

void set_sat(const float* c, float s, float* out) {
    int mx = 0, mn = 0;
    for (int i = 1; i < 3; ++i) {
        if (c[i] > c[mx]) mx = i;
        if (c[i] < c[mn]) mn = i;
    }
    if (mx == mn) {  // all three equal: no hue to keep
        out[0] = out[1] = out[2] = 0.0f;
        return;
    }
    const int mid = 3 - mx - mn;
    const float range = c[mx] - c[mn];
    const float mv = (c[mid] - c[mn]) * s / range;
    out[mn] = 0.0f;
    out[mid] = mv;
    out[mx] = s;
}

void blend_rgb(ImageBlend mode, const float* cb, const float* cs, float* out) {
    switch (mode) {
        case ImageBlend::Hue: {
            float t[3];
            set_sat(cs, sat(cb), t);
            set_lum(t, lum(cb), out);
            return;
        }
        case ImageBlend::Saturation: {
            float t[3];
            set_sat(cb, sat(cs), t);
            set_lum(t, lum(cb), out);
            return;
        }
        case ImageBlend::Color: set_lum(cs, lum(cb), out); return;
        case ImageBlend::Luminosity: set_lum(cb, lum(cs), out); return;
        default:
            for (int i = 0; i < 3; ++i) out[i] = blend_channel(mode, cb[i], cs[i]);
    }
}

}  // namespace

void composite_pixel(ImageBlend mode, const float* b, const float* s, float* out) {
    const float ab = b[3], as = s[3];
    if (as <= 0.0f) {
        for (int i = 0; i < 4; ++i) out[i] = b[i];
        return;
    }
    const float ar = as + ab * (1.0f - as);
    float mixed[3];
    if (ab <= 0.0f || mode == ImageBlend::Normal) {
        for (int i = 0; i < 3; ++i) mixed[i] = s[i];
    } else {
        blend_rgb(mode, b, s, mixed);
    }
    float r[3];
    for (int i = 0; i < 3; ++i) {
        // ((1 - as) ab Cb + as ((1 - ab) Cs + ab B(Cb, Cs))) / ar
        const float num = (1.0f - as) * ab * b[i] + as * ((1.0f - ab) * s[i] + ab * mixed[i]);
        r[i] = std::clamp(num / ar, 0.0f, 1.0f);
    }
    out[0] = r[0];
    out[1] = r[1];
    out[2] = r[2];
    out[3] = ar;
}

Raster from_image(const Image& image) {
    Raster r(image.width, image.height);
    for (std::size_t i = 0; i < r.px.size(); ++i) r.px[i] = image.rgba[i] / 255.0f;
    return r;
}

Image to_image(const Raster& raster) {
    Image img;
    img.width = raster.w;
    img.height = raster.h;
    img.rgba.assign(raster.px.size(), 0);
    for (std::size_t i = 0; i < raster.px.size(); i += 4) {
        const long a = std::lround(std::clamp(raster.px[i + 3], 0.0f, 1.0f) * 255.0f);
        if (a == 0) continue;
        for (int c = 0; c < 3; ++c)
            img.rgba[i + c] = std::uint8_t(std::lround(std::clamp(raster.px[i + c], 0.0f, 1.0f) * 255.0f));
        img.rgba[i + 3] = std::uint8_t(a);
    }
    return img;
}

}  // namespace fa::imgdoc

namespace fa {

Color blend_pixel(ImageBlend mode, Color backdrop, Color source) {
    const float b[4] = {backdrop.r, backdrop.g, backdrop.b, backdrop.a};
    const float s[4] = {source.r, source.g, source.b, source.a};
    float o[4];
    imgdoc::composite_pixel(mode, b, s, o);
    return {o[0], o[1], o[2], o[3]};
}

}  // namespace fa
