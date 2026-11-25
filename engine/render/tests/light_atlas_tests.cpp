// The light atlas (src/light_atlas.h): the layout of the LTC block, the cookies and the IES profiles, the tiles it bakes, the light
// table that carries their rects (light_clusters.h), and the precision of the generated GLES3 fragment shader. All CPU: the image
// itself is made on the GPU and drawn in area_light_render_tests.cpp.
#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdlib>
#include <fstream>
#include <iterator>
#include <set>
#include <string>
#include <vector>

#include <doctest.h>

#include "fa/render/ies.h"
#include "glsl_source.h"
#include "fa_test_paths.h"
#include "light_atlas.h"
#include "light_clusters.h"
#include "local_shadows.h"
#include "ltc_tables.h"
#include "mesh_batch.h"

using namespace fa;
using namespace fa::render;

namespace {

std::vector<LightAtlasKey> cookies(int n) {
    std::vector<LightAtlasKey> keys;
    for (int i = 0; i < n; ++i) keys.push_back({LightAtlasKind::Cookie, "assets/cookie" + std::to_string(i) + ".png"});
    return keys;
}

bool overlap(const LightAtlasRect& a, const LightAtlasRect& b) {
    return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;
}

IesProfile tiny_profile() {
    IesProfile p;
    p.vertical = {0, 90, 180};
    p.horizontal = {0};
    p.candela = {100, 50, 0};
    p.maxCandela = 100;
    return p;
}

Image gradient(int w, int h) {
    Image img;
    img.width = w;
    img.height = h;
    img.rgba.resize(std::size_t(w) * std::size_t(h) * 4);
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x) {
            std::uint8_t* p = &img.rgba[(std::size_t(y) * std::size_t(w) + std::size_t(x)) * 4];
            p[0] = std::uint8_t(x * 255 / std::max(w - 1, 1));
            p[1] = std::uint8_t(y * 255 / std::max(h - 1, 1));
            p[2] = 40;
            p[3] = 255;
        }
    return img;
}

}  // namespace

TEST_CASE("light atlas: the layout is the same for the same set of tiles in any order") {
    std::vector<LightAtlasKey> keys = cookies(7);
    keys.push_back({LightAtlasKind::Ies, "assets/a.ies"});
    keys.push_back({LightAtlasKind::Ies, "assets/b.ies"});
    const LightAtlasLayout a = layout_light_atlas(keys);
    std::vector<LightAtlasKey> reversed(keys.rbegin(), keys.rend());
    reversed.push_back(keys.front());  // a duplicate counts once
    const LightAtlasLayout b = layout_light_atlas(reversed);
    REQUIRE(a.entries.size() == 9);
    REQUIRE(b.entries.size() == a.entries.size());
    CHECK(a.height == b.height);
    for (std::size_t i = 0; i < a.entries.size(); ++i) {
        CHECK(a.entries[i].first == b.entries[i].first);
        CHECK(a.entries[i].second.x == b.entries[i].second.x);
        CHECK(a.entries[i].second.y == b.entries[i].second.y);
    }
    CHECK(a.dropped == 0);
    // A set of other keys does not move what is there when it is a prefix of the sorted keys; the layout depends on the set only.
    CHECK(layout_light_atlas({}).entries.empty());
}

TEST_CASE("light atlas: tiles do not overlap each other or the LTC block, and the height is a power of two") {
    std::vector<LightAtlasKey> keys = cookies(11);
    for (int i = 0; i < 9; ++i) keys.push_back({LightAtlasKind::Ies, "assets/lamp" + std::to_string(i) + ".ies"});
    const LightAtlasLayout l = layout_light_atlas(keys);
    CHECK(l.dropped == 0);
    CHECK(l.height >= kLtcTile);
    CHECK((l.height & (l.height - 1)) == 0);
    const LightAtlasRect ltc{0, 0, 2 * kLtcTile, kLtcTile};
    for (std::size_t i = 0; i < l.entries.size(); ++i) {
        const LightAtlasRect& r = l.entries[i].second;
        CHECK(r.x >= 0);
        CHECK(r.y >= 0);
        CHECK(r.x + r.w <= kLightAtlasWidth);
        CHECK(r.y + r.h <= l.height);
        CHECK_FALSE(overlap(r, ltc));
        for (std::size_t j = i + 1; j < l.entries.size(); ++j) CHECK_FALSE(overlap(r, l.entries[j].second));
    }
    // The LTC tables alone: one shelf.
    CHECK(layout_light_atlas({}).height == kLtcTile);
    CHECK(ltc_matrix_rect().x == 0);
    CHECK(ltc_brdf_rect().x == kLtcTile);
}

TEST_CASE("light atlas: tiles past the height cap are dropped, never placed outside the image") {
    const LightAtlasLayout l =
        layout_light_atlas(cookies(200));  // 4 per row of 256: 16 rows of 4096 hold 64 minus the shelf
    CHECK(l.dropped > 0);
    CHECK(l.dropped + int(l.entries.size()) == 200);
    CHECK(l.height <= kLightAtlasMaxHeight);
    for (const auto& e : l.entries) CHECK(e.second.y + e.second.h <= l.height);
    CHECK(int(l.entries.size()) >= 48);                  // a project with dozens of cookies is fine
    CHECK(layout_light_atlas(cookies(8)).dropped == 0);  // 10x under the cap in a test
}

TEST_CASE("light atlas: half floats round to nearest, keep sign and saturate") {
    for (float f : {0.0f, 1.0f, -1.0f, 0.5f, 0.25f, 2.0f, 1024.0f, -3.5f, 65504.0f})
        CHECK(light_atlas_half_to_float(light_atlas_half(f)) == f);
    CHECK(light_atlas_half_to_float(light_atlas_half(1.0f / 3.0f)) == doctest::Approx(1.0f / 3.0f).epsilon(1e-3));
    CHECK(light_atlas_half_to_float(light_atlas_half(1e9f)) == 65504.0f);
    CHECK(light_atlas_half_to_float(light_atlas_half(-1e9f)) == -65504.0f);
    CHECK(light_atlas_half_to_float(light_atlas_half(1e-9f)) == 0.0f);
    CHECK(light_atlas_half_to_float(light_atlas_half(6e-5f)) ==
          doctest::Approx(6e-5f).epsilon(0.02));                                // a subnormal-range value
    CHECK(light_atlas_half_to_float(light_atlas_half(std::nanf(""))) == 0.0f);  // never NaN into the image
}

TEST_CASE("light atlas: the LTC tables are baked into the reserved block, texel for texel") {
    const LightAtlasLayout l = layout_light_atlas({});
    std::vector<std::uint16_t> atlas = assemble_light_atlas(l, {});
    REQUIRE(atlas.size() == std::size_t(kLightAtlasWidth) * std::size_t(l.height) * 4);
    for (int y : {0, 17, 63})
        for (int x : {0, 5, 40, 63}) {
            const std::size_t cell = std::size_t(y) * 64 + std::size_t(x);
            const std::uint16_t* m = &atlas[(std::size_t(y) * kLightAtlasWidth + std::size_t(x)) * 4];
            const std::uint16_t* b = &atlas[(std::size_t(y) * kLightAtlasWidth + std::size_t(kLtcTile + x)) * 4];
            for (int k = 0; k < 4; ++k) {
                const float want = ltc_tables::kMatrix[cell * 4 + std::size_t(k)];
                CHECK(light_atlas_half_to_float(m[k]) == doctest::Approx(want).epsilon(2e-3).scale(1.0));
            }
            CHECK(light_atlas_half_to_float(b[0]) ==
                  doctest::Approx(ltc_tables::kBrdf[cell * 2]).epsilon(2e-3).scale(1.0));
            CHECK(light_atlas_half_to_float(b[1]) ==
                  doctest::Approx(ltc_tables::kBrdf[cell * 2 + 1]).epsilon(2e-3).scale(1.0));
        }
}

TEST_CASE("light atlas: a cookie tile is premultiplied, resampled, and its border wraps") {
    const std::vector<std::uint16_t> t = bake_cookie_tile(gradient(8, 8));
    REQUIRE(t.size() == std::size_t(kCookieTile) * kCookieTile * 4);
    auto px = [&](int x, int y, int c) {
        return light_atlas_half_to_float(t[(std::size_t(y) * kCookieTile + std::size_t(x)) * 4 + std::size_t(c)]);
    };
    // The left border is the last inner column, the right border the first (a directional cookie tiles).
    for (int y : {1, 100, 254})
        for (int c = 0; c < 4; ++c) {
            CHECK(px(0, y, c) == px(kCookieInner, y, c));
            CHECK(px(kCookieTile - 1, y, c) == px(1, y, c));
        }
    // The picture grows from dark red to bright red across and dark green to bright green down.
    CHECK(px(2, 128, 0) < px(250, 128, 0));
    CHECK(px(128, 2, 1) < px(128, 250, 1));
    // Alpha premultiplies: a half transparent white pixel has rgb 0.5 and alpha 0.5.
    Image half;
    half.width = half.height = 1;
    half.rgba = {255, 255, 255, 128};
    const std::vector<std::uint16_t> h = bake_cookie_tile(half);
    CHECK(light_atlas_half_to_float(h[(std::size_t(100) * kCookieTile + 100) * 4]) ==
          doctest::Approx(0.5).epsilon(0.01));
    // The same bytes twice.
    CHECK(bake_cookie_tile(gradient(8, 8)) == t);
}

TEST_CASE("light atlas: an IES tile holds candela over the peak, the border wraps across and clamps down") {
    const std::vector<std::uint16_t> t = bake_ies_tile(tiny_profile());
    REQUIRE(t.size() == std::size_t(kIesTileW) * kIesTileH * 4);
    auto px = [&](int x, int y) {
        return light_atlas_half_to_float(t[(std::size_t(y) * kIesTileW + std::size_t(x)) * 4]);
    };
    CHECK(px(0, 5) == px(kIesBakeWidth, 5));
    CHECK(px(kIesTileW - 1, 5) == px(1, 5));
    CHECK(px(10, 0) == px(10, 1));
    CHECK(px(10, kIesTileH - 1) == px(10, kIesTileH - 2));
    CHECK(px(10, 1) > 0.95f);              // near the nadir: close to the peak
    CHECK(px(10, kIesTileH - 2) < 0.05f);  // near the zenith: close to 0
    CHECK(light_atlas_half_to_float(t[3]) == 1.0f);
}

TEST_CASE("light table: lights without extension texels keep the 4 texel layout; one with them makes it 8 for the "
          "whole view") {
    std::vector<LightData> lights(2);
    lights[0].pos = Vec4{0, 5, 0, 10};
    lights[0].color = Vec4{1, 0.5f, 0.25f, 1};
    lights[0].dir = Vec4{0, -1, 0, 0.8f};
    lights[1] = lights[0];
    lights[1].pos = Vec4{3, 5, 0, 10};
    ClusterCamera cam;
    LightTexture plain;
    pack_light_texture(lights, 0, cam, nullptr, plain);
    CHECK(plain.stride == 4);
    CHECK(plain.usedTexels == 8);
    CHECK(plain.texels[16] == 3.0f);  // light 1 starts at texel 4 = float 16

    lights[1].hasExt = true;
    lights[1].ext[0] = Vec4{1, 0, 0, 2.0f};
    lights[1].ext[1] = Vec4{0, 1, 0, 1.0f};
    lights[1].ext[2] = Vec4{128, 64, 1, 0};
    lights[1].ext[3] = Vec4{0, 0, 0, 2.2f};
    LightTexture ext;
    pack_light_texture(lights, 0, cam, nullptr, ext);
    CHECK(ext.stride == 8);
    CHECK(ext.usedTexels == 16);
    CHECK(ext.texels[32] == 3.0f);       // light 1 starts at texel 8
    CHECK(ext.texels[32 + 16] == 1.0f);  // its +4 texel: the right axis
    CHECK(ext.texels[32 + 19] == 2.0f);
    CHECK(ext.texels[32 + 24] == 128.0f);
    CHECK(ext.texels[32 + 31] == 2.2f);
    // Light 0 is the same data as before, only further apart; its extension texels are zero.
    for (int c = 0; c < 16; ++c) CHECK(ext.texels[std::size_t(c)] == plain.texels[std::size_t(c)]);
    for (int c = 16; c < 32; ++c) CHECK(ext.texels[std::size_t(c)] == 0.0f);
}

namespace {

// The declarations of float, vector and matrix type in a GLSL ES 3.00 source that have no `highp` before them (as in physical_sky_tests.cpp).
std::vector<std::string> unqualified_floats(const std::string& src) {
    std::vector<std::string> bad;
    static const char* const kTypes[] = {"float", "vec2", "vec3", "vec4", "mat2", "mat3", "mat4"};
    auto is_word = [](char c) { return std::isalnum(static_cast<unsigned char>(c)) || c == '_'; };
    for (const char* type : kTypes) {
        const std::string t = type;
        for (std::size_t at = src.find(t); at != std::string::npos; at = src.find(t, at + 1)) {
            if (at > 0 && is_word(src[at - 1])) continue;
            const std::size_t lineStart = src.rfind('\n', at) == std::string::npos ? 0 : src.rfind('\n', at) + 1;
            if (src.compare(lineStart, 9, "precision") == 0) continue;
            if (src.compare(lineStart, 13, "const float _") == 0)
                continue;  // a literal table of the material layers (brdf_layers.glsl)
            std::size_t after = at + t.size();
            if (after < src.size() && is_word(src[after])) continue;
            while (after < src.size() && src[after] == ' ') ++after;
            if (after < src.size() && src[after] == '(') continue;  // a constructor
            std::size_t before = at;
            while (before > 0 && src[before - 1] == ' ') --before;
            const bool highp = before >= 5 && src.compare(before - 5, 5, "highp") == 0;
            if (!highp) bad.push_back(src.substr(lineStart, 80));
        }
    }
    return bad;
}

}  // namespace

TEST_CASE(
    "light atlas: the area-light path of the GLES3 fragment shader stays highp (an fp16 GPU would flush its guards)") {
    // ltc.glsl's guards (1e-24, 1e-10, 1e-7) and dot(a, a) of a vector a few hundred metres long do not survive fp16. sokol-shdc writes
    // `precision mediump float;` as the default of a GLSL ES 3.00 fragment shader and qualifies every declaration with highp; this reads
    // the generated header and checks that the shader the area lights run in has no declaration without it and no explicit lower one.
    const std::string src = glsl_source_from_header("mesh.glsl.h", "mesh_fs_source_glsl300es");
    REQUIRE(!src.empty());
    CHECK(src.find("precision mediump float;") != std::string::npos);
    CHECK(src.find("fa_ltc_quad") != std::string::npos);  // the area path is in this source
    CHECK(src.find("fa_area_shade") != std::string::npos);
    CHECK(src.find("1e-24") != std::string::npos);  // its guards are in it
    CHECK(src.find("mediump float fa_") == std::string::npos);
    CHECK(src.find("lowp") == std::string::npos);
    const std::vector<std::string> bad = unqualified_floats(src);
    for (const std::string& l : bad) MESSAGE("not highp: " << l);
    CHECK(bad.empty());
    // The atlas texture is read with a highp sampler too.
    CHECK(src.find("highp sampler2D fa_light_atlas_fa_env_smp") != std::string::npos);
}

TEST_CASE("2D light cookies: cookie_coord of the light buffer and quad programs stays highp on GLES3 and WebGL2") {
    // The 16 cells of the cookie atlas are 256 texels wide, 1024 in all: an fp16 coordinate has about 11 bits of mantissa, so a lookup at
    // the far side of the atlas would land half a texel off and blend the neighbouring cell. sokol-shdc qualifies every declaration of the
    // GLSL ES 3.00 source highp (the same reason as the area-light test above); this reads the generated sources and checks the function.
    for (const char* file : {"light", "quad"}) {
        CAPTURE(file);
        const std::string src =
            glsl_source_from_header(std::string(file) + ".glsl.h", std::string(file) + "_fs_source_glsl300es");
        REQUIRE(!src.empty());
        const std::size_t at = src.find("cookie_coord(highp vec4 cell, highp vec4 xf, highp vec2 off)");
        REQUIRE(at != std::string::npos);
        const std::size_t end = src.find("\n    }\n", at);
        REQUIRE(end != std::string::npos);
        const std::size_t lineStart = src.rfind('\n', at) + 1;
        const std::string body = src.substr(lineStart, end - lineStart);
        const std::vector<std::string> bad = unqualified_floats(body);
        for (const std::string& l : bad) MESSAGE("not highp: " << l);
        CHECK(bad.empty());
        CHECK(body.find("mediump") == std::string::npos);
    }
}

TEST_CASE("light atlas: a point light's cookie cube has six face tiles that continue into each other") {
    // The cube takes 3 x 2 tiles of kCookieTile, one key, and the layout keeps it clear of the LTC block.
    std::vector<LightAtlasKey> keys{{LightAtlasKind::CookieCube, "assets/c.png"},
                                    {LightAtlasKind::Cookie, "assets/a.png"}};
    const LightAtlasLayout l = layout_light_atlas(keys);
    REQUIRE(l.entries.size() == 2);
    const LightAtlasRect* cube = l.find(keys[0]);
    REQUIRE(cube);
    CHECK(cube->w == kCookieCubeW);
    CHECK(cube->h == kCookieCubeH);
    CHECK(cube->x + cube->w <= kLightAtlasWidth);
    // The face tile of every direction is the one cube_face_of picks, for the points inside a face.
    for (int f = 0; f < kCubeFaces; ++f)
        for (float s : {-0.9f, 0.0f, 0.9f})
            for (float t : {-0.9f, 0.0f, 0.9f}) CHECK(cube_face_of(cookie_cube_dir(f, s, t)) == f);
    // A picture whose left half is white and right half black: the centre column of the picture is straight ahead (-Z, face 5), the
    // light's +X (face 0) sees the right half and -X (face 1) the left.
    Image img;
    img.width = 64;
    img.height = 32;
    img.rgba.resize(std::size_t(64) * 32 * 4, 255);
    for (int y = 0; y < 32; ++y)
        for (int x = 32; x < 64; ++x)
            for (int c = 0; c < 3; ++c) img.rgba[(std::size_t(y) * 64 + std::size_t(x)) * 4 + std::size_t(c)] = 0;
    const std::vector<std::uint16_t> t = bake_cookie_cube_tile(img);
    REQUIRE(t.size() == std::size_t(kCookieCubeW) * kCookieCubeH * 4);
    auto at = [&](int face, int x, int y) {
        const int ox = (face % 3) * kCookieTile, oy = (face / 3) * kCookieTile;
        return light_atlas_half_to_float(t[(std::size_t(oy + y) * kCookieCubeW + std::size_t(ox + x)) * 4]);
    };
    CHECK(at(0, 128, 128) < 0.1f);  // +X: the right of the picture, black
    CHECK(at(1, 128, 128) > 0.9f);  // -X: the left, white
    // A face tile's border continues into the next face instead of wrapping: the +Z face (behind) is the seam of the picture, its left
    // half white and its right half black, and the border column beyond its right edge is black too.
    CHECK(std::abs(at(4, 0, 128) - at(4, 1, 128)) < 0.2f);
    CHECK(std::abs(at(4, kCookieTile - 1, 128) - at(4, kCookieTile - 2, 128)) < 0.2f);
    CHECK(bake_cookie_cube_tile(img) == t);  // deterministic
}

TEST_CASE("light atlas: a key nobody asked for in a long while is forgotten, one asked for again is kept") {
    LightAtlas atlas;
    atlas.request(LightAtlasKind::Cookie, "a.png");
    atlas.request(LightAtlasKind::Cookie, "b.png");
    CHECK(atlas.key_count() == 2);
    for (std::uint64_t i = 0; i < LightAtlas::kKeyIdleTicks / 2; ++i) atlas.end_requests();
    atlas.request(LightAtlasKind::Cookie, "b.png");  // b is still in use, a is not
    for (std::uint64_t i = 0; i < LightAtlas::kKeyIdleTicks / 2 + 64; ++i) atlas.end_requests();
    CHECK(atlas.key_count() == 1);
    for (std::uint64_t i = 0; i < 2 * LightAtlas::kKeyIdleTicks; ++i) atlas.end_requests();
    CHECK(atlas.key_count() == 0);
}
