#include "fa/tooling/palette.h"

#include <algorithm>
#include <cmath>
#include <format>
#include <set>
#include <unordered_map>

#include "fa/core/strings.h"

namespace fa {

namespace {

std::uint32_t pack(std::uint8_t r, std::uint8_t g, std::uint8_t b) { return (std::uint32_t(r) << 16) | (std::uint32_t(g) << 8) | b; }

Result<std::array<std::uint8_t, 3>> parse_colour(const std::string& text, std::size_t index) {
    Color c;
    if (!parse_color(text, c)) {
        return make_error(std::format("palette colour {} is '{}', not a colour like \"#1a1c2c\"", index, text),
                          "Write each colour as \"#rrggbb\" or a colour name, or give the path of an image that holds the colours.");
    }
    const auto byte = [](float v) { return std::uint8_t(std::lround(v * 255)); };
    return std::array<std::uint8_t, 3>{byte(c.r), byte(c.g), byte(c.b)};
}

}  // namespace

Result<Palette> load_palette(const Json& spec) {
    Palette palette;
    if (spec.is_array()) {
        for (std::size_t i = 0; i < spec.size(); ++i) {
            if (!spec[i].is_string()) return make_error(std::format("palette colour {} is not a string", i), "Use \"#rrggbb\" strings.");
            auto c = parse_colour(spec[i].get<std::string>(), i);
            if (!c) return c.error();
            palette.push_back(*c);
        }
    } else if (spec.is_string()) {
        const std::string path = spec.get<std::string>();
        auto img = load_image(path);
        if (!img) return make_error("The palette image '" + path + "' cannot be read: " + img.error().message, img.error().hint);
        std::set<std::uint32_t> seen;
        for (std::size_t i = 0; i < img->rgba.size(); i += 4) {
            if (img->rgba[i + 3] < 128) continue;  // transparent pixels are not colours of the palette
            if (seen.insert(pack(img->rgba[i], img->rgba[i + 1], img->rgba[i + 2])).second)
                palette.push_back({img->rgba[i], img->rgba[i + 1], img->rgba[i + 2]});
            if (seen.size() > kMaxPaletteColours) break;
        }
        if (palette.size() > kMaxPaletteColours) {
            return make_error(std::format("The palette image '{}' has more than {} colours, so it is not a palette", path, kMaxPaletteColours),
                              "Point style.palette at an image with at most 256 distinct colours, or list the colours as \"#rrggbb\" strings.");
        }
    } else {
        return make_error("style.palette must be a list of \"#rrggbb\" colours or the path of an image", "See schemas/assets.schema.json.");
    }
    if (palette.size() < 2) return make_error("A palette needs at least 2 colours", "List more colours, or use an image with more distinct colours.");
    return palette;
}

Image quantize_to_palette(const Image& src, const Palette& palette) {
    Image out = src;
    if (palette.empty()) return out;
    std::unordered_map<std::uint32_t, std::size_t> nearest;  // flat areas repeat the same colour thousands of times
    for (std::size_t i = 0; i + 3 < out.rgba.size(); i += 4) {
        const std::uint32_t key = pack(out.rgba[i], out.rgba[i + 1], out.rgba[i + 2]);
        auto [it, fresh] = nearest.try_emplace(key, 0);
        if (fresh) {
            long best = -1;
            for (std::size_t k = 0; k < palette.size(); ++k) {
                long d = 0;
                for (std::size_t c = 0; c < 3; ++c) {
                    const long delta = long(out.rgba[i + c]) - long(palette[k][c]);
                    d += delta * delta;
                }
                if (best < 0 || d < best) {
                    best = d;
                    it->second = k;
                }
            }
        }
        for (std::size_t c = 0; c < 3; ++c) out.rgba[i + c] = palette[it->second][c];
    }
    return out;
}

}  // namespace fa
