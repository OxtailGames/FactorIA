// M75-P5a: the heights of a Terrain: the loaders (16-bit PNG, raw .r16, 8-bit PNG with a warning, teaching errors), the size and
// budget rules, sampling on the triangles the surface and the collider share, the dirty-rectangle history and the store.
#include <doctest.h>

#include <cmath>
#include <filesystem>

#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/scene/components.h"
#include "fa/scene/terrain.h"
#include "fa/scene/world.h"

using namespace fa;

namespace {

GrayImage16 ramp(int n) {
    GrayImage16 g;
    g.width = g.height = n;
    g.sixteenBit = true;
    g.samples.resize(std::size_t(n) * std::size_t(n));
    for (int r = 0; r < n; ++r)
        for (int c = 0; c < n; ++c)
            g.samples[std::size_t(r) * std::size_t(n) + std::size_t(c)] = std::uint16_t((c * 1000 + r * 7) % 65536);
    return g;
}

bool contains(const std::string& text, const char* needle) { return text.find(needle) != std::string::npos; }

std::string error_text(const Error& e) { return e.message + " | " + e.hint; }

}  // namespace

TEST_CASE("terrain_grid_samples: 2^n + 1 as it is, 2^n padded, everything else a teaching error") {
    for (int n : {33, 65, 129, 513, 1025, 4097}) {
        auto r = terrain_grid_samples(n, n, "h.png");
        REQUIRE(r.ok());
        CHECK(*r == n);
    }
    for (int n : {32, 64, 1024, 4096}) {
        auto r = terrain_grid_samples(n, n, "h.png");
        REQUIRE(r.ok());
        CHECK(*r == n + 1);
    }
    auto wide = terrain_grid_samples(129, 65, "h.png");
    REQUIRE_FALSE(wide.ok());
    CHECK(contains(wide.error().message, "129 x 65"));
    CHECK(contains(wide.error().message, "square"));
    CHECK(contains(wide.error().hint, "4097"));
    auto odd = terrain_grid_samples(100, 100, "h.png");
    REQUIRE_FALSE(odd.ok());
    CHECK(contains(odd.error().message, "100 x 100"));
    CHECK(contains(odd.error().hint, "1025"));
    auto big = terrain_grid_samples(8193, 8193, "huge.png");
    REQUIRE_FALSE(big.ok());
    CHECK(contains(big.error().message, "huge.png"));
    CHECK(contains(big.error().message, "4097"));
    CHECK_FALSE(terrain_grid_samples(17, 17, "tiny.png").ok());  // below one tile
}

TEST_CASE("decode_terrain_heightmap: a 16-bit PNG keeps every sample") {
    const GrayImage16 g = ramp(33);
    const auto png = encode_png_gray16(g);
    auto load = decode_terrain_heightmap(png.data(), png.size(), "terrain/h.png");
    REQUIRE(load.ok());
    REQUIRE(load->heights);
    CHECK(load->warning.empty());
    CHECK(load->heights->samples == 33);
    CHECK(load->heights->data == g.samples);
    CHECK_FALSE(load->heights->eightBit);
    CHECK(load->heights->source == "terrain/h.png");
}

TEST_CASE("decode_terrain_heightmap: an 8-bit PNG is accepted with a warning about steps") {
    Image img;
    img.width = img.height = 33;
    img.rgba.assign(33 * 33 * 4, 255);
    for (int i = 0; i < 33 * 33; ++i)
        img.rgba[std::size_t(i) * 4] = img.rgba[std::size_t(i) * 4 + 1] = img.rgba[std::size_t(i) * 4 + 2] =
            std::uint8_t(i % 256);
    const auto png = encode_png(img);
    auto load = decode_terrain_heightmap(png.data(), png.size(), "terrain/h8.png");
    REQUIRE(load.ok());
    CHECK(load->heights->eightBit);
    CHECK(contains(load->warning, "8 bits"));
    CHECK(contains(load->warning, "steps"));
    CHECK(load->heights->at(5, 0) == 5 * 257);
}

TEST_CASE("decode_terrain_heightmap: raw .r16 is little endian and its size gives the side") {
    const int n = 65;
    std::vector<std::uint8_t> raw(std::size_t(n) * n * 2);
    for (int i = 0; i < n * n; ++i) {
        const std::uint16_t v = std::uint16_t(i * 3 + 1);
        raw[std::size_t(i) * 2] = std::uint8_t(v & 0xFF);
        raw[std::size_t(i) * 2 + 1] = std::uint8_t(v >> 8);
    }
    auto load = decode_terrain_heightmap(raw.data(), raw.size(), "terrain/h.r16");
    REQUIRE(load.ok());
    CHECK(load->heights->samples == n);
    CHECK(load->heights->at(0, 0) == 1);
    CHECK(load->heights->at(2, 1) == std::uint16_t((1 * n + 2) * 3 + 1));
    CHECK(load->warning.empty());

    // a power-of-two side repeats the last row and column
    std::vector<std::uint8_t> p(std::size_t(64) * 64 * 2, 0);
    p[(63 * 64 + 63) * 2] = 9;
    auto padded = decode_terrain_heightmap(p.data(), p.size(), "h.R16");  // the extension is case-insensitive
    REQUIRE(padded.ok());
    CHECK(padded->heights->samples == 65);
    CHECK(padded->heights->at(63, 63) == 9);
    CHECK(padded->heights->at(64, 64) == 9);
    CHECK(padded->heights->at(64, 10) == padded->heights->at(63, 10));

    // not a square, odd byte count, empty
    std::vector<std::uint8_t> bad(65 * 66 * 2, 0);
    auto notSquare = decode_terrain_heightmap(bad.data(), bad.size(), "h.r16");
    REQUIRE_FALSE(notSquare.ok());
    CHECK(contains(notSquare.error().message, "not a square"));
    auto odd = decode_terrain_heightmap(bad.data(), 7, "h.r16");
    REQUIRE_FALSE(odd.ok());
    CHECK(contains(odd.error().message, "2 bytes per sample"));
    CHECK_FALSE(decode_terrain_heightmap(bad.data(), 0, "h.r16").ok());
}

TEST_CASE("decode_terrain_heightmap: a size the budget refuses is refused from the header, before any sample is made") {
    GrayImage16 g;
    g.width = g.height = 33;
    g.samples.assign(33 * 33, 1);
    auto png = encode_png_gray16(g);
    // Patch the IHDR to claim 8193 x 8193 (width at byte 16..19, height 20..23): the pixels are not there, the size alone says no.
    auto claim = [&](std::uint32_t side) {
        auto bytes = png;
        for (int i = 0; i < 4; ++i) {
            bytes[16 + std::size_t(i)] = std::uint8_t(side >> (24 - 8 * i));
            bytes[20 + std::size_t(i)] = std::uint8_t(side >> (24 - 8 * i));
        }
        return bytes;
    };
    const auto huge = claim(8193);
    auto r = decode_terrain_heightmap(huge.data(), huge.size(), "huge.png");
    REQUIRE_FALSE(r.ok());
    CHECK(contains(r.error().message, "8193 x 8193"));
    CHECK(contains(error_text(r.error()), "4097"));
}

TEST_CASE("load_terrain_heightmap: a missing file says where to put it") {
    auto r = load_terrain_heightmap("definitely/not/here.png");
    REQUIRE_FALSE(r.ok());
    CHECK(contains(r.error().message, "definitely/not/here.png"));
    CHECK(contains(r.error().hint, "Terrain.heightmap"));
    CHECK_FALSE(load_terrain_heightmap("").ok());
}

TEST_CASE("terrain_local_sample: the triangles of the collider (diagonal from (r, c) to (r + 1, c + 1))") {
    TerrainHeights h;
    h.samples = 33;
    h.data.assign(33 * 33, 0);
    h.set(1, 0, 65535);  // one high sample at column 1, row 0
    Terrain3D t;
    t.size = {32.0f, 32.0f};  // 1 m cells
    t.heightScale = 10.0f;
    t.heightOffset = 2.0f;
    float y, dx, dz;
    // the sample itself: x = -16 + 1, z = -16
    REQUIRE(terrain_local_sample(h, t, -15.0f, -16.0f, y, dx, dz));
    CHECK(y == doctest::Approx(12.0f));
    // cell (0, 0) is split along (0,0)-(1,1): the point (u = 0.9, v = 0.1) is in the triangle (0,0), (1,1), (0,1) = columns, which
    // holds the high sample at u = 1, v = 0: height = h00 + v * (h11 - h00) + (u - v) * (h01 - h00) = 0.8 * 10 + 2
    REQUIRE(terrain_local_sample(h, t, -16.0f + 0.9f, -16.0f + 0.1f, y, dx, dz));
    CHECK(y == doctest::Approx(2.0f + 0.8f * 10.0f).epsilon(1e-4));
    CHECK(dx == doctest::Approx(10.0f));  // metres per metre along x in that triangle
    CHECK(dz == doctest::Approx(-10.0f));
    // the same cell, the other triangle (u = 0.1, v = 0.9): no high corner in it, flat at the offset
    REQUIRE(terrain_local_sample(h, t, -16.0f + 0.1f, -16.0f + 0.9f, y, dx, dz));
    CHECK(y == doctest::Approx(2.0f));
    // outside the grid
    CHECK_FALSE(terrain_local_sample(h, t, 16.5f, 0.0f, y, dx, dz));
    CHECK_FALSE(terrain_local_sample(h, t, std::nanf(""), 0.0f, y, dx, dz));
    // the edges are inside
    CHECK(terrain_local_sample(h, t, 16.0f, 16.0f, y, dx, dz));
    CHECK(terrain_local_sample(h, t, -16.0f, -16.0f, y, dx, dz));
}

TEST_CASE("terrain_sample: through the transform of the entity, with the normal of the surface") {
    const std::filesystem::path dir = fs::make_temp_dir("fa_terrain_scene").value();
    GrayImage16 g;
    g.width = g.height = 33;
    g.sixteenBit = true;
    g.samples.resize(33 * 33);
    for (int r = 0; r < 33; ++r)
        for (int c = 0; c < 33; ++c)
            g.samples[std::size_t(r) * 33 + std::size_t(c)] = std::uint16_t(c * 2000);  // rises along +x
    const auto png = encode_png_gray16(g);
    const std::string file = fs::path_to_utf8(dir / "h.png");
    REQUIRE(fs::write_bytes(file, png.data(), png.size()).ok());

    World w;
    ensure_builtin_components();
    Entity e = w.create("ground");
    Transform tr;
    tr.position = {100.0f, 5.0f, -50.0f};
    w.add<Transform>(e) = tr;
    Terrain3D t;
    t.heightmap = file;
    t.size = {64.0f, 64.0f};                    // 2 m cells
    t.heightScale = 65535.0f / 2000.0f * 4.0f;  // a sample step of 2000 is 4 m
    w.add<Terrain3D>(e) = t;

    TerrainSample s;
    // x = 100 + (c - 16) * 2: column 20 -> 108, z = -50: row 16
    REQUIRE(terrain_sample(w, e, 108.0f, -50.0f, s));
    CHECK(s.height == doctest::Approx(5.0f + 20.0f * 4.0f).epsilon(1e-4));
    // slope 4 m per 2 m along +x: the normal leans toward -x
    CHECK(s.normal.x == doctest::Approx(-2.0f / std::sqrt(5.0f)).epsilon(1e-4));
    CHECK(s.normal.y == doctest::Approx(1.0f / std::sqrt(5.0f)).epsilon(1e-4));
    CHECK(s.normal.z == doctest::Approx(0.0f).epsilon(1e-4));
    float h = 0;
    CHECK(terrain_height_at(w, e, 109.0f, -49.0f, h));
    CHECK(h == doctest::Approx(5.0f + 20.5f * 4.0f).epsilon(1e-4));
    CHECK_FALSE(terrain_height_at(w, e, 140.0f, -50.0f, h));  // beyond the +32 m edge

    // a missing heightmap: no answer, a problem the store keeps
    w.get<Terrain3D>(e)->heightmap = "nope/missing.png";
    CHECK_FALSE(terrain_height_at(w, e, 100.0f, -50.0f, h));
    std::string problem;
    CHECK(w.terrain().heights(w, e, &problem) == nullptr);
    CHECK(contains(problem, "Terrain.heightmap"));
    CHECK(contains(problem, "entity '"));
    // an empty heightmap is a flat terrain at heightOffset
    w.get<Terrain3D>(e)->heightmap.clear();
    w.get<Terrain3D>(e)->heightOffset = 7.0f;
    CHECK(terrain_height_at(w, e, 100.0f, -50.0f, h));
    CHECK(h == doctest::Approx(12.0f));
    std::error_code ec;
    fs::remove_tree(dir, ec);
}

TEST_CASE("TerrainHeights: the dirty history tells each reader what changed since the version it saw") {
    auto h = TerrainHeights::flat(65);
    REQUIRE(h->valid());
    CHECK(h->version == 0);
    TerrainRect r;
    CHECK(h->dirty_since(0, r));
    CHECK(r.empty());
    h->set(10, 20, 500);
    h->mark_dirty({10, 20, 12, 22});
    CHECK(h->version == 1);
    h->set(40, 5, 9);
    h->mark_dirty({40, 5, 41, 5});
    CHECK(h->version == 2);
    REQUIRE(h->dirty_since(0, r));
    CHECK(r.c0 == 10);
    CHECK(r.r0 == 5);
    CHECK(r.c1 == 41);
    CHECK(r.r1 == 22);
    REQUIRE(h->dirty_since(1, r));  // only the second edit
    CHECK(r.c0 == 40);
    CHECK(r.r1 == 5);
    REQUIRE(h->dirty_since(2, r));
    CHECK(r.empty());
    h->mark_dirty({-5, -5, 1000, 1000});  // clamped to the grid
    REQUIRE(h->dirty_since(2, r));
    CHECK(r.c0 == 0);
    CHECK(r.c1 == 64);
    h->mark_dirty({5, 5, 1, 1});  // empty: nothing
    CHECK(h->version == 3);
    // more edits than the history keeps: an old reader must take everything
    for (int i = 0; i < 100; ++i) h->mark_dirty({i % 60, 0, i % 60, 0});
    CHECK_FALSE(h->dirty_since(0, r));
    CHECK(h->dirty_since(h->version - 5, r));
    CHECK(r.c1 - r.c0 <= 4);
    // two loads are two objects
    CHECK(TerrainHeights::flat(33)->id != TerrainHeights::flat(33)->id);
}
