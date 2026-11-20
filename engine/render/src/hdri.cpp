#include "fa/render/hdri.h"

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <format>

#include "fa/core/fs.h"
#include "fa/core/image_float.h"

#include "render_internal.h"

namespace fa {

namespace {

constexpr double kHdriPi = 3.14159265358979323846;

// Bytes of an RGBA16F image with its whole mip chain, in 64 bits (a width of at most kHdriMaxWidth, so no overflow).
std::uint64_t chain_bytes(int w, int h) {
    std::uint64_t total = 0;
    while (true) {
        total += std::uint64_t(w) * std::uint64_t(h) * 8u;
        if (w == 1 && h == 1) break;
        w = std::max(1, w / 2);
        h = std::max(1, h / 2);
    }
    return total;
}

}  // namespace

std::uint64_t hdri_decode_pixel_budget() {
    return sizeof(void*) >= 8 ? std::uint64_t(8192) * 4096u : std::uint64_t(4096) * 2048u;
}

std::string hdri_layout_problem(int width, int height, std::string_view name) {
    const std::string who = name.empty() ? std::string("the image") : std::string(name);
    if (width < kHdriMinWidth || height < kHdriMinWidth / 2)
        return std::format(
            "{} is {} x {}, smaller than the {} x {} an environment map may have. Hint: use a panorama of at least "
            "{} x {} (a flat sky colour is better set with SceneSettings.skyColor).",
            who, width, height, kHdriMinWidth, kHdriMinWidth / 2, kHdriMinWidth, kHdriMinWidth / 2);
    const std::int64_t w = width, h = height;
    // Within 1 % of 2:1 counts as equirectangular (exporters round odd heights).
    if (std::abs(w - 2 * h) * 100 <= w) return {};
    std::string what;
    if (std::abs(w - h) * 100 <= w)
        what = "square: a light probe (a mirror ball or an angular map)";
    else if (std::abs(w * 3 - h * 4) * 100 <= w * 3 || std::abs(w * 4 - h * 3) * 100 <= w * 4)
        what = "4:3 or 3:4: a cube cross";
    else if (std::abs(w - 6 * h) * 100 <= w || std::abs(h - 6 * w) * 100 <= h)
        what = "6:1 or 1:6: a strip of six cube faces";
    else
        what = std::format("{:.2f}:1, not 2:1", double(width) / double(height));
    return std::format(
        "{} is {} x {} ({}), but only equirectangular (latitude-longitude) panoramas are read, which are twice as wide "
        "as "
        "they are tall. Hint: convert it to an equirectangular .hdr (for example 2048 x 1024 or 4096 x 2048) in the "
        "program that made it, or set SceneSettings.environmentMap to a different file.",
        who, width, height, what);
}

Result<HdriCheck> hdri_check(const std::uint8_t* data, std::size_t size, std::string_view name) {
    const std::string who(name);
    auto info = hdr_info(data, size);
    if (!info) return make_error(who + ": " + info.error().message, info.error().hint);
    if (const std::string problem = hdri_layout_problem(info->width, info->height, name); !problem.empty())
        return make_error(problem);
    const std::uint64_t pixels = std::uint64_t(info->width) * std::uint64_t(info->height);
    if (pixels > hdri_decode_pixel_budget())
        return make_error(
            std::format("{} is {} x {}: more pixels than this platform decodes ({} million).", who, info->width,
                        info->height, hdri_decode_pixel_budget() / 1000000u),
            "Shrink the panorama (2048 x 1024 is enough for lighting, 4096 x 2048 for a sharp sky) and import it "
            "again.");
    HdriCheck c;
    c.width = info->width;
    c.height = info->height;
    c.gpuWidth = std::min(c.width, kHdriMaxWidth);
    c.gpuHeight = c.gpuWidth == c.width ? c.height : std::max(1, c.gpuWidth / 2);
    c.gpuBytes = chain_bytes(c.gpuWidth, c.gpuHeight);
    return c;
}

Result<HdriImage> hdri_from_bytes(const std::uint8_t* data, std::size_t size, std::string_view name) {
    auto check = hdri_check(data, size, name);
    if (!check) return check.error();
    auto decoded = decode_hdr(data, size);
    if (!decoded) return make_error(std::string(name) + ": " + decoded.error().message, decoded.error().hint);
    ImageF level = std::move(*decoded);
    // NaN and negative values are 0; a huge value keeps its place but cannot overflow the filter.
    for (float& v : level.data) v = v > 0.0f ? std::min(v, 1.0e30f) : 0.0f;
    if (check->shrunk()) {
        auto smaller = level.resized(check->gpuWidth, check->gpuHeight);
        if (!smaller) return make_error(std::string(name) + ": " + smaller.error().message, smaller.error().hint);
        level = std::move(*smaller);
    }
    // A texel above the largest value is scaled to it with its colour (all three channels by one factor).
    for (std::size_t i = 0; i + 2 < level.data.size(); i += 3) {
        const float m = std::max({level.data[i], level.data[i + 1], level.data[i + 2]});
        if (m > kHdriMaxValue) {
            const float k = kHdriMaxValue / m;
            level.data[i] *= k;
            level.data[i + 1] *= k;
            level.data[i + 2] *= k;
        }
    }
    HdriImage out;
    out.width = level.width;
    out.height = level.height;
    out.sourceWidth = check->width;
    out.sourceHeight = check->height;
    while (true) {
        std::vector<std::uint16_t> texels(std::size_t(level.width) * std::size_t(level.height) * 4u);
        const float* s = level.data.data();
        for (std::size_t i = 0; i < std::size_t(level.width) * std::size_t(level.height); ++i) {
            texels[i * 4] = render::float_to_half_bits(s[i * 3]);
            texels[i * 4 + 1] = render::float_to_half_bits(s[i * 3 + 1]);
            texels[i * 4 + 2] = render::float_to_half_bits(s[i * 3 + 2]);
            texels[i * 4 + 3] = 0x3C00;  // 1.0
        }
        out.mips.push_back(std::move(texels));
        if (level.width == 1 && level.height == 1) break;
        auto next = level.half_size();
        if (!next) return make_error(std::string(name) + ": " + next.error().message, next.error().hint);
        level = std::move(*next);
    }
    return out;
}

Result<HdriImage> hdri_load(std::string_view path) {
    auto bytes = fs::read_bytes(path);
    if (!bytes) return bytes.error();
    return hdri_from_bytes(bytes->data(), bytes->size(), path);
}

void hdri_uv(float x, float y, float z, float rotationDegrees, float& u, float& v) {
    const double len = std::sqrt(double(x) * x + double(y) * y + double(z) * z);
    if (!(len > 0.0)) {
        u = 0.5f;
        v = 0.5f;
        return;
    }
    const double theta = double(rotationDegrees) * kHdriPi / 180.0;
    const double c = std::cos(theta), s = std::sin(theta);
    const double dx = double(x) / len, dy = double(y) / len, dz = double(z) / len;
    // The environment is turned by theta, so the direction is turned by -theta before the lookup.
    const double rx = dx * c - dz * s, rz = dx * s + dz * c;
    double uu = std::atan2(rx, -rz) / (2.0 * kHdriPi) + 0.5;
    uu -= std::floor(uu);
    u = float(uu);
    v = float(0.5 - std::asin(std::clamp(dy, -1.0, 1.0)) / kHdriPi);
}

}  // namespace fa
