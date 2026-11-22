// M75-P5a: the heights of a Terrain: the loaders (16-bit PNG, raw .r16, 8-bit PNG with a warning, teaching errors), the size and
// budget rules, sampling on the triangles the surface and the collider share, the dirty-rectangle history and the store.
#include <doctest.h>

#include <algorithm>
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

namespace {
TerrainPatch height_patch(const TerrainHeights& h, int x0, int y0, int w, int hh, std::uint16_t value) {
    TerrainPatch p;
    p.plane = TerrainPlane::Heights;
    p.x0 = x0;
    p.y0 = y0;
    p.w = w;
    p.h = hh;
    for (int r = y0; r < y0 + hh; ++r)
        for (int c = x0; c < x0 + w; ++c) {
            const std::uint16_t before = h.at(c, r);
            p.before.push_back(std::uint8_t(before & 0xff));
            p.before.push_back(std::uint8_t(before >> 8));
            p.after.push_back(std::uint8_t(value & 0xff));
            p.after.push_back(std::uint8_t(value >> 8));
        }
    return p;
}
}  // namespace

TEST_CASE(
    "TerrainHeights: a step changes the planes, undo and redo give them back bit for bit, one dirty rectangle each") {
    auto h = TerrainHeights::flat(33, 1000);
    const std::vector<std::uint16_t> start = h->data;
    TerrainStep s1;
    s1.label = "terrain.sculpt";
    s1.patches.push_back(height_patch(*h, 4, 6, 5, 3, 4242));
    TerrainPatch holes;
    holes.plane = TerrainPlane::Holes;
    holes.x0 = 2;
    holes.y0 = 2;
    holes.w = 3;
    holes.h = 2;
    holes.before.assign(6, 0);
    holes.after.assign(6, 1);
    s1.patches.push_back(holes);
    const std::uint64_t v0 = h->version;
    std::string problem;
    REQUIRE_MESSAGE(h->apply_step(s1, &problem), problem);
    CHECK(h->at(4, 6) == 4242);
    CHECK(h->at(8, 8) == 4242);
    CHECK(h->at(9, 6) == 1000);
    CHECK(h->version == v0 + 1);  // one mark_dirty for the plane of the step
    REQUIRE(h->holes.size() == 32u * 32u);
    CHECK(h->holes[2 * 32 + 2] == 1);
    CHECK(h->holes[1 * 32 + 2] == 0);
    CHECK(h->heightsUnsaved);
    CHECK(h->holesUnsaved);
    CHECK(h->holesVersion > 0);
    TerrainRect r;
    REQUIRE(h->dirty_since(v0, r));
    CHECK(r.c0 == 4);
    CHECK(r.c1 == 8);
    CHECK(r.r0 == 6);
    CHECK(r.r1 == 8);
    const std::vector<std::uint16_t> after = h->data;
    const std::vector<std::uint8_t> holesAfter = h->holes;
    std::string label;
    REQUIRE(h->undo(&label));
    CHECK(label == "terrain.sculpt");
    CHECK(h->data == start);
    CHECK(std::count(h->holes.begin(), h->holes.end(), std::uint8_t(1)) == 0);
    CHECK(h->undo_depth() == 0);
    CHECK(h->redo_depth() == 1);
    CHECK_FALSE(h->undo());
    REQUIRE(h->redo());
    CHECK(h->data == after);
    CHECK(h->holes == holesAfter);
    CHECK_FALSE(h->redo());
    // a new step clears the redo list
    REQUIRE(h->undo());
    TerrainStep s2;
    s2.label = "terrain.sculpt";
    s2.patches.push_back(height_patch(*h, 0, 0, 1, 1, 7));
    REQUIRE(h->apply_step(s2));
    CHECK(h->redo_depth() == 0);
    // a patch that does not fit changes nothing and says which
    TerrainStep bad;
    bad.patches.push_back(height_patch(*h, 30, 30, 3, 3, 1));
    bad.patches[0].x0 = 31;  // 31 + 3 > 33
    const std::vector<std::uint16_t> keep = h->data;
    CHECK_FALSE(h->apply_step(bad, &problem));
    CHECK_FALSE(problem.empty());
    CHECK(h->data == keep);
    CHECK(h->undo_depth() == 1);
}

TEST_CASE("TerrainHeights: the history keeps at most kTerrainHistorySteps steps") {
    auto h = TerrainHeights::flat(33, 0);
    for (int i = 0; i < int(kTerrainHistorySteps) + 10; ++i) {
        TerrainStep s;
        s.label = "terrain.sculpt";
        s.patches.push_back(height_patch(*h, i % 30, 0, 1, 1, std::uint16_t(i + 1)));
        REQUIRE(h->apply_step(s));
    }
    CHECK(h->undo_depth() == kTerrainHistorySteps);
    CHECK(h->history_bytes() > 0);
    CHECK(h->history_bytes() < std::size_t(1) << 20);
}

TEST_CASE("encode_terrain_heightmap and save_terrain_files: the files hold the planes and read back the same") {
    const std::filesystem::path dir = fs::make_temp_dir("fa_terrain_save").value();
    {
        World w;
        ensure_builtin_components();
        Entity e = w.create("ground");
        Terrain3D& t = w.add<Terrain3D>(e);
        t.size = {32.0f, 32.0f};
        t.heightmap = fs::path_to_utf8(dir / "g.height.png");
        t.holes = fs::path_to_utf8(dir / "g.holes.png");
        t.splatMaps = Json::array({fs::path_to_utf8(dir / "g.splat0.png")});
        auto h = TerrainHeights::flat(33, 30000);
        w.terrain().adopt(e, t.heightmap, h);
        h->splat[0].size = 4;  // a splat map must exist before a step can edit it
        h->splat[0].rgba.assign(4 * 4 * 4, 0);
        h->splat[0].source = fs::path_to_utf8(dir / "g.splat0.png");
        // a grid that was never edited writes nothing
        std::vector<std::string> written;
        REQUIRE(save_terrain_files(w, e, &written).ok());
        CHECK(written.empty());
        TerrainStep step;
        step.label = "terrain.sculpt";
        step.patches.push_back(height_patch(*h, 3, 3, 4, 4, 55555));
        TerrainPatch holes;
        holes.plane = TerrainPlane::Holes;
        holes.x0 = 10;
        holes.y0 = 10;
        holes.w = 2;
        holes.h = 2;
        holes.before.assign(4, 0);
        holes.after.assign(4, 1);
        step.patches.push_back(holes);
        TerrainPatch sp;
        sp.plane = TerrainPlane::Splat0;
        sp.x0 = 0;
        sp.y0 = 0;
        sp.w = 2;
        sp.h = 1;
        sp.before.assign(8, 0);
        sp.after = {0, 0, 0, 0, 10, 20, 30, 0};  // the second texel has alpha 0 and colour: it must survive
        step.patches.push_back(sp);
        std::string problem;
        REQUIRE_MESSAGE(h->apply_step(step, &problem), problem);
        CHECK(h->any_unsaved());
        REQUIRE(save_terrain_files(w, e, &written).ok());
        CHECK(written.size() == 3);
        CHECK_FALSE(h->any_unsaved());
        auto loaded = load_terrain_heightmap(t.heightmap);
        REQUIRE(loaded.ok());
        CHECK(loaded.value().heights->data == h->data);
        // the splat map, even with alpha 0
        auto bytes = fs::read_bytes(fs::path_to_utf8(dir / "g.splat0.png"));
        REQUIRE(bytes.ok());
        auto dec = decode_image(bytes.value().data(), bytes.value().size());
        REQUIRE(dec.ok());
        const Image& img = dec.value();
        CHECK(img.rgba[4] == 10);
        CHECK(img.rgba[5] == 20);
        CHECK(img.rgba[6] == 30);
        CHECK(img.rgba[7] == 0);
        // a store that loads from the files finds the same planes
        w.terrain().clear();
        auto reread = w.terrain().heights(w, e);
        REQUIRE(reread);
        CHECK(reread->data == h->data);
        CHECK(reread->holes[10 * 32 + 10] == 1);
        CHECK(reread->holes[9 * 32 + 10] == 0);
        REQUIRE(reread->splat[0].valid());
        CHECK(reread->splat[0].rgba[6] == 30);
        CHECK(reread->splat[0].rgba[7] == 0);
        CHECK_FALSE(reread->any_unsaved());
        // the raw .r16 form is little endian
        TerrainHeights tiny = *TerrainHeights::flat(33, 0x1234);
        const auto raw = encode_terrain_heightmap(tiny, "x.r16");
        REQUIRE(raw.size() == 33u * 33u * 2u);
        CHECK(raw[0] == 0x34);
        CHECK(raw[1] == 0x12);
        CHECK(encode_terrain_heightmap(tiny, "x.png").size() > 8);
    }
    std::error_code ec;
    fs::remove_tree(dir, ec);
}
