// Shared by the tests of assets.import, assets.slice_sheet and the asset checks of project.validate.
#pragma once

#include <doctest.h>

#include <cstdint>
#include <filesystem>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/image.h"
#include "fa/tooling/asset_import.h"
#include "test_helpers.h"

namespace fa::testing {

struct Rgba {
    std::uint8_t r = 0, g = 0, b = 0, a = 0;
    bool operator==(const Rgba& o) const { return r == o.r && g == o.g && b == o.b && a == o.a; }
};

inline Image make_image(int w, int h, Rgba fill = {}) {
    Image img;
    img.width = w;
    img.height = h;
    img.rgba.resize(std::size_t(w) * h * 4);
    for (std::size_t i = 0; i < img.rgba.size(); i += 4) {
        img.rgba[i] = fill.r;
        img.rgba[i + 1] = fill.g;
        img.rgba[i + 2] = fill.b;
        img.rgba[i + 3] = fill.a;
    }
    return img;
}

inline Rgba get(const Image& img, int x, int y) {
    const std::uint8_t* p = &img.rgba[(std::size_t(y) * img.width + x) * 4];
    return {p[0], p[1], p[2], p[3]};
}

inline void fill_rect(Image& img, int x, int y, int w, int h, Rgba c) {
    for (int j = y; j < y + h; ++j)
        for (int i = x; i < x + w; ++i) {
            std::uint8_t* p = &img.rgba[(std::size_t(j) * img.width + i) * 4];
            p[0] = c.r;
            p[1] = c.g;
            p[2] = c.b;
            p[3] = c.a;
        }
}

inline std::string png_string(const Image& img) {
    const auto png = encode_png(img);
    return std::string(png.begin(), png.end());
}

inline void write_png(const std::filesystem::path& p, const Image& img) { write_all(p, png_string(img)); }

inline Image read_png(const std::filesystem::path& p) {
    const std::string bytes = read_all(p);
    auto img = decode_image(reinterpret_cast<const std::uint8_t*>(bytes.data()), bytes.size());
    REQUIRE_MESSAGE(img.ok(), p.string());
    return *img;
}

// True when one of the strings of a JSON array contains `needle` (the `warnings` and `nextSteps` of a result).
inline bool has_text(const Json& list, const std::string& needle) {
    if (!list.is_array()) return false;
    for (const Json& s : list)
        if (s.is_string() && s.get<std::string>().find(needle) != std::string::npos) return true;
    return false;
}

inline bool has_warning(const Json& result, const std::string& needle) { return result.contains("warnings") && has_text(result["warnings"], needle); }

// A temporary project folder with the assets commands registered on it.
struct AssetsProject {
    TempDir tmp;
    std::string dir;
    CommandRegistry registry;
    AssetsProject() {
        dir = tmp.sub("game");
        std::filesystem::create_directories(dir);
        register_asset_commands(registry, dir);
    }
    std::filesystem::path file(const std::string& rel) const { return std::filesystem::path(dir) / rel; }
    bool exists(const std::string& rel) const { return std::filesystem::exists(file(rel)); }
    CommandResult call(const std::string& name, const Json& args) const { return registry.call(name, args); }
    // A call that must succeed.
    Json ok(const std::string& name, const Json& args) const {
        CommandResult r = registry.call(name, args);
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        return r.result;
    }
    Json manifest() const { return parse_json(read_all(file("assets.json")), "assets.json").value(); }
};

}  // namespace fa::testing
