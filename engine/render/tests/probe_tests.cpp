// M73-P3b: the CPU side of the reflection probes (include/fa/render/probe.h): the octahedral mapping, the layout of a tile, the atlas
// allocator, the scheduler, the manifest and the page of a baked probe. No GPU: the same file runs where `ctest -LE gpu` does
// (render_postprocess_core). probe_render_tests.cpp checks that the shaders draw what these functions lay out.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <set>

#include "fa/core/image_float.h"
#include "fa/render/probe.h"

using namespace fa;
using namespace fa::render;

namespace {

std::vector<Vec3> sample_directions() {
    std::vector<Vec3> d;
    for (int i = -4; i <= 4; ++i)
        for (int j = -4; j <= 4; ++j)
            for (int k = -4; k <= 4; ++k) {
                if (i == 0 && j == 0 && k == 0) continue;
                d.push_back(normalize(Vec3{float(i), float(j), float(k)}));
            }
    return d;
}

}  // namespace

TEST_CASE("probe octahedral map: encode and decode are inverses over the whole sphere") {
    for (Vec3 d : sample_directions()) {
        const Vec2 e = oct_encode(d);
        CHECK(e.x >= -1.0f);
        CHECK(e.x <= 1.0f);
        CHECK(e.y >= -1.0f);
        CHECK(e.y <= 1.0f);
        const Vec3 back = oct_decode(e);
        CHECK(length(back - d) < 1e-5f);
    }
    // The poles and the centre of the map.
    CHECK(length(oct_decode(Vec2{0.0f, 0.0f}) - Vec3{0.0f, 1.0f, 0.0f}) < 1e-6f);
    CHECK(length(oct_decode(Vec2{1.0f, 1.0f}) - Vec3{0.0f, -1.0f, 0.0f}) < 1e-6f);
    CHECK(length(oct_decode(Vec2{1.0f, 0.0f}) - Vec3{1.0f, 0.0f, 0.0f}) < 1e-6f);
    CHECK(length(oct_decode(Vec2{0.0f, -1.0f}) - Vec3{0.0f, 0.0f, -1.0f}) < 1e-6f);
    // The zero vector is the centre, not NaN.
    const Vec2 z = oct_encode(Vec3{0.0f, 0.0f, 0.0f});
    CHECK(z.x == 0.0f);
    CHECK(z.y == 0.0f);
}

TEST_CASE("probe capture camera: six right-handed orthonormal faces that look along the six axes") {
    const Vec3 axes[6] = {{1, 0, 0}, {-1, 0, 0}, {0, 1, 0}, {0, -1, 0}, {0, 0, 1}, {0, 0, -1}};
    for (int f = 0; f < 6; ++f) {
        const ProbeFace c = probe_face(f);
        CHECK(dot(c.fwd, axes[f]) == doctest::Approx(1.0));
        CHECK(dot(c.fwd, c.up) == doctest::Approx(0.0));
        CHECK(dot(c.right, c.fwd) == doctest::Approx(0.0));
        CHECK(length(c.right) == doctest::Approx(1.0));
        // right x up = -fwd: the camera's third axis points backwards, as every camera of the engine's does
        const Vec3 back = cross(c.right, c.up);
        CHECK(dot(back, c.fwd) == doctest::Approx(-1.0));
    }
    CHECK(probe_face(-3).fwd.x == 1.0f);
    CHECK(probe_face(99).fwd.z == -1.0f);
}

TEST_CASE("probe octahedral map: the border texel is the texel across the edge, so a clamped tap is continuous") {
    // A texel one step beyond the edge decodes to the direction of its neighbour across the fold: the border of a tile computed
    // from the direction equals the mirrored interior texel, so the bilinear tap between the edge and its border is continuous.
    const int size = 32;
    for (int i = 0; i < size; ++i) {
        const float c = (float(i) + 0.5f) / float(size) * 2.0f - 1.0f;
        // Beyond the right edge: the fold mirrors it back, with the other coordinate negated.
        const Vec3 over = oct_decode(
            Vec2{1.0f + (1.0f - (float(size - 1) + 0.5f) / float(size) * 2.0f + 1.0f) * 0.0f + 1.0f / size, c});
        const Vec3 mirrored = oct_decode(Vec2{1.0f - 1.0f / size, -c});
        CHECK(length(over - mirrored) < 1e-5f);
        const Vec3 under = oct_decode(Vec2{c, -1.0f - 1.0f / size});
        const Vec3 mirrored2 = oct_decode(Vec2{-c, -1.0f + 1.0f / size});
        CHECK(length(under - mirrored2) < 1e-5f);
    }
    // The map is continuous across the fold: neighbouring texels across an edge are close on the sphere.
    for (int i = 0; i < size; ++i) {
        const float c = (float(i) + 0.5f) / float(size) * 2.0f - 1.0f;
        const Vec3 a = oct_decode(Vec2{1.0f - 0.5f / size, c});
        const Vec3 b = oct_decode(Vec2{1.0f + 0.5f / size, c});
        CHECK(length(a - b) < 4.0f / float(size));
    }
}

TEST_CASE("probe octahedral map: the texels' solid angles sum to 4 pi") {
    for (int size : {16, 32, 64}) {
        double sum = 0.0;
        float lo = 1e9f, hi = 0.0f;
        for (int y = 0; y < size; ++y)
            for (int x = 0; x < size; ++x) {
                const float w = oct_texel_weight(oct_texel_coordinate(x, y, size), size);
                CHECK(w > 0.0f);
                sum += double(w);
                lo = std::min(lo, w);
                hi = std::max(hi, w);
            }
        CHECK(std::fabs(sum - 4.0 * 3.14159265358979323846) < 4.0 * 3.14159265358979323846 * 0.02);
        CHECK(hi / lo < 6.0f);  // the octahedron is fairly even
    }
}

TEST_CASE("probe tile: resolution classes, levels and layout") {
    CHECK(probe_resolution(1) == 32);
    CHECK(probe_resolution(32) == 32);
    CHECK(probe_resolution(47) == 32);
    CHECK(probe_resolution(48) == 64);  // a tie goes up
    CHECK(probe_resolution(100) == 128);
    CHECK(probe_resolution(200) == 256);
    CHECK(probe_resolution(100000) == 256);
    CHECK(probe_resolution(-5) == 32);
    CHECK(probe_levels(32) == 3);
    CHECK(probe_levels(64) == 4);
    CHECK(probe_levels(128) == 5);
    CHECK(probe_levels(256) == 5);
    CHECK(probe_level_roughness(5, 0) == 0.0f);
    CHECK(probe_level_roughness(5, 4) == 1.0f);
    CHECK(probe_level_roughness(5, 2) == doctest::Approx(0.5f));
    CHECK(probe_sh_source(128) == 3);
    CHECK(probe_sh_source(32) == 1);
    CHECK(probe_sh_source(256) == 4);

    for (int r : {32, 64, 128, 256}) {
        const ProbeLayout l = probe_layout(r);
        CHECK(l.resolution == r);
        CHECK(l.levels == probe_levels(r));
        CHECK(l.levelSize[0] == r);
        CHECK(l.levelX[0] == 0);
        CHECK(l.levelY[0] == 0);
        // No two level regions (with their borders) overlap, none leaves the tile, and the SH row is below them all.
        struct Rect {
            int x0, y0, x1, y1;
        };
        std::vector<Rect> rects;
        for (int k = 0; k < l.levels; ++k) {
            CHECK(l.levelSize[k] == (r >> k));
            const Rect q{l.levelX[k], l.levelY[k], l.levelX[k] + l.levelSize[k] + 2 * kProbeBorder,
                         l.levelY[k] + l.levelSize[k] + 2 * kProbeBorder};
            CHECK(q.x1 <= l.tileW);
            CHECK(q.y1 <= l.shY);
            for (const Rect& o : rects) CHECK((q.x1 <= o.x0 || o.x1 <= q.x0 || q.y1 <= o.y0 || o.y1 <= q.y0));
            rects.push_back(q);
        }
        CHECK(l.shY == l.tileH - 1);
        CHECK(l.tileW >= kProbeShCoefficients);
        CHECK(probe_page_width(r) == l.tileW);
        CHECK(probe_page_height(r) == l.tileH - 1);
    }
}

TEST_CASE("probe atlas: shelf allocation is deterministic, disjoint and inside the atlas") {
    const auto run = [] {
        ProbeAtlasAllocator a;
        std::vector<ProbeTile> tiles;
        std::vector<std::uint64_t> evicted;
        std::uint64_t id = 1;
        for (int i = 0; i < 12; ++i) {
            const int res = (i % 3 == 0) ? 256 : (i % 3 == 1 ? 64 : 128);
            auto t = a.acquire(id++, res, 0, 1, &evicted);
            REQUIRE(t.has_value());
            tiles.push_back(*t);
        }
        CHECK(evicted.empty());
        return tiles;
    };
    const std::vector<ProbeTile> a = run(), b = run();
    REQUIRE(a.size() == b.size());
    for (std::size_t i = 0; i < a.size(); ++i) {
        CHECK(a[i].x == b[i].x);
        CHECK(a[i].y == b[i].y);
        CHECK(a[i].resolution == b[i].resolution);
        const ProbeLayout l = probe_layout(a[i].resolution);
        CHECK(a[i].x >= 0);
        CHECK(a[i].y >= 0);
        CHECK(a[i].x + l.tileW <= kProbeAtlasSize);
        CHECK(a[i].y + l.tileH <= kProbeAtlasSize);
        for (std::size_t j = 0; j < i; ++j) {
            const ProbeLayout m = probe_layout(a[j].resolution);
            const bool apart = a[i].x + l.tileW <= a[j].x || a[j].x + m.tileW <= a[i].x || a[i].y + l.tileH <= a[j].y ||
                               a[j].y + m.tileH <= a[i].y;
            CHECK(apart);
        }
    }
}

TEST_CASE("probe atlas: the same id keeps its tile, a new resolution moves it, release gives the room back") {
    ProbeAtlasAllocator a;
    auto t1 = a.acquire(7, 128, 0, 1, nullptr);
    REQUIRE(t1.has_value());
    auto t2 = a.acquire(7, 128, 0, 2, nullptr);
    REQUIRE(t2.has_value());
    CHECK(t2->x == t1->x);
    CHECK(t2->y == t1->y);
    CHECK(a.count() == 1);
    auto t3 = a.acquire(7, 64, 0, 3, nullptr);
    REQUIRE(t3.has_value());
    CHECK(t3->resolution == 64);
    CHECK(a.count() == 1);
    CHECK(a.find(7)->resolution == 64);
    a.release(7);
    CHECK(a.count() == 0);
    CHECK_FALSE(a.find(7).has_value());
    CHECK(a.used_texels() == 0);
    CHECK(a.reserved_texels() == 0);  // the empty shelf was given back
    // A tile bigger than the atlas finds no room.
    ProbeAtlasAllocator small(128);
    CHECK_FALSE(small.acquire(1, 256, 0, 1, nullptr).has_value());
}

TEST_CASE(
    "probe atlas: the budget is the atlas; a full one evicts the least important, then the oldest, never an equal") {
    ProbeAtlasAllocator a;
    std::vector<std::uint64_t> evicted;
    // Fill the atlas with 256 probes of importance 0 until it says no.
    std::uint64_t id = 1;
    while (a.acquire(id, 256, 0, id, &evicted).has_value() && id < 100) ++id;
    const int held = a.count();
    CHECK(held >= 1);
    CHECK(held < 100);
    CHECK(evicted.empty());  // equal importance never evicts
    CHECK(a.used_texels() <= std::uint64_t(kProbeAtlasSize) * kProbeAtlasSize);
    // A more important probe takes the place of the oldest of the least important.
    evicted.clear();
    auto t = a.acquire(1000, 256, 5, 500, &evicted);
    REQUIRE(t.has_value());
    REQUIRE(evicted.size() == 1);
    CHECK(evicted[0] == 1);  // the oldest (frame 1)
    CHECK(a.count() == held);
    CHECK_FALSE(a.find(1).has_value());
    CHECK(a.find(1000).has_value());
    // A touched probe is no longer the oldest.
    a.touch(2, 900);
    evicted.clear();
    REQUIRE(a.acquire(1001, 256, 5, 501, &evicted).has_value());
    REQUIRE(evicted.size() == 1);
    CHECK(evicted[0] == 3);
    // Equal importance (5) does not evict the two new ones.
    evicted.clear();
    // The remaining probes of importance 0 are evicted before one of 5; when none is left, there is no room.
    int placed = 0;
    for (std::uint64_t k = 2000; k < 2000 + 200; ++k) {
        if (!a.acquire(k, 256, 5, 600 + k, &evicted)) break;
        ++placed;
    }
    CHECK(placed < 200);
    for (std::uint64_t e : evicted) CHECK((e <= std::uint64_t(held)));  // only the importance-0 ones were evicted
    CHECK(a.find(1000).has_value());
    CHECK(a.find(1001).has_value());
}

TEST_CASE("probe atlas: a more important small probe clears a shelf of lesser ones of another size") {
    ProbeAtlasAllocator a(520);  // two shelves of 256 (one tile each) and not 35 texels more
    std::uint64_t id = 1;
    while (a.acquire(id, 256, 0, id, nullptr).has_value() && id < 100) ++id;
    CHECK(a.count() == 2);
    std::vector<std::uint64_t> evicted;
    auto t = a.acquire(500, 32, 3, 1000, &evicted);
    REQUIRE(t.has_value());
    CHECK(t->resolution == 32);
    CHECK(evicted == std::vector<std::uint64_t>{2});
    CHECK(a.count() == 2);
    CHECK(std::is_sorted(evicted.begin(), evicted.end()));
    for (std::uint64_t e : evicted) CHECK_FALSE(a.find(e).has_value());
}

TEST_CASE("probe scheduler: the face budget of a frame holds, every probe completes, in a stable order") {
    ProbeScheduler s;
    std::vector<ProbeSpec> probes;
    for (std::uint64_t id = 1; id <= 5; ++id) probes.push_back(ProbeSpec{id, ProbeUpdateKind::TimeSliced, 0, 128});
    s.set_probes(probes);
    std::set<std::uint64_t> done;
    for (std::uint64_t frame = 1; frame <= 40; ++frame) {
        const auto work = s.plan(frame);
        CHECK(int(work.size()) <= s.budget());
        for (const auto& w : work) {
            CHECK(w.slot >= 0);
            CHECK(w.slot < kProbeSlots);
            CHECK(w.face >= 0);
            CHECK(w.face < kProbeFaces);
            if (w.last) done.insert(w.id);
        }
    }
    CHECK(done.size() == 5);
    for (std::uint64_t id = 1; id <= 5; ++id) CHECK(s.info(id).captures >= 1);
    // The same input gives the same plan.
    ProbeScheduler s2;
    s2.set_probes(probes);
    ProbeScheduler s3;
    s3.set_probes(probes);
    for (std::uint64_t frame = 1; frame <= 10; ++frame) {
        const auto a = s2.plan(frame), b = s3.plan(frame);
        REQUIRE(a.size() == b.size());
        for (std::size_t i = 0; i < a.size(); ++i) {
            CHECK(a[i].id == b[i].id);
            CHECK(a[i].face == b[i].face);
            CHECK(a[i].slot == b[i].slot);
        }
    }
}

TEST_CASE("probe scheduler: a capture's faces come in order, one probe at a time per slot, and the last face says so") {
    ProbeScheduler s;
    s.set_budget(1);
    s.set_probes({ProbeSpec{3, ProbeUpdateKind::TimeSliced, 0, 64}});
    std::vector<int> faces;
    for (std::uint64_t frame = 1; frame <= 6; ++frame) {
        const auto w = s.plan(frame);
        REQUIRE(w.size() == 1);
        faces.push_back(w[0].face);
        CHECK(w[0].last == (w[0].face == 5));
    }
    CHECK(faces == std::vector<int>{0, 1, 2, 3, 4, 5});
    CHECK(s.info(3).captures == 1);
    CHECK(s.info(3).lastFrame == 6);
}

TEST_CASE(
    "probe scheduler: every-frame probes first, the more important before the less, on-demand ones only on request") {
    ProbeScheduler s;
    s.set_budget(6);
    s.set_probes({ProbeSpec{1, ProbeUpdateKind::TimeSliced, 0, 64}, ProbeSpec{2, ProbeUpdateKind::TimeSliced, 9, 64},
                  ProbeSpec{3, ProbeUpdateKind::EveryFrame, 0, 64}, ProbeSpec{4, ProbeUpdateKind::OnDemand, 0, 64}});
    // The first capture of each probe happens once, whatever its policy; the order is: never captured first (ties:
    // every-frame, importance, id).
    const auto first = s.plan(1);
    REQUIRE(first.size() == 6);
    CHECK(first[0].id == 3);
    const auto second = s.plan(2);
    REQUIRE(second.size() == 6);
    CHECK(second[0].id == 2);
    // The on-demand probe captured its first time and then waits.
    for (std::uint64_t f = 3; f <= 6; ++f) s.plan(f);
    CHECK(s.info(4).captures == 1);
    const std::uint64_t before = s.info(4).captures;
    for (std::uint64_t f = 7; f <= 20; ++f) s.plan(f);
    CHECK(s.info(4).captures == before);
    CHECK_FALSE(s.info(4).pending);
    s.refresh(4);
    CHECK(s.info(4).pending);
    for (std::uint64_t f = 21; f <= 30; ++f) s.plan(f);
    CHECK(s.info(4).captures == before + 1);
    CHECK_FALSE(s.info(4).pending);
}

TEST_CASE("probe scheduler: a probe that goes away frees its slot, one that changes resolution starts over") {
    ProbeScheduler s;
    s.set_budget(1);
    s.set_probes({ProbeSpec{1, ProbeUpdateKind::TimeSliced, 0, 64}, ProbeSpec{2, ProbeUpdateKind::TimeSliced, 0, 64},
                  ProbeSpec{3, ProbeUpdateKind::TimeSliced, 0, 64}});
    s.plan(1);
    s.plan(2);
    s.set_probes({ProbeSpec{2, ProbeUpdateKind::TimeSliced, 0, 64}, ProbeSpec{3, ProbeUpdateKind::TimeSliced, 0, 64}});
    int done = 0;
    for (std::uint64_t f = 3; f < 40; ++f)
        for (const auto& w : s.plan(f)) done += w.last ? 1 : 0;
    CHECK(done >= 2);
    CHECK(s.info(1).captures == 0);  // forgotten
    s.set_probes({ProbeSpec{2, ProbeUpdateKind::TimeSliced, 0, 128}});
    CHECK(s.info(2).facesDone == 0);
}

TEST_CASE("probe manifest: JSON round trip, and an error that names the pointer and the fix") {
    ProbeManifest m;
    m.resolution = 64;
    m.levels = probe_levels(64);
    m.page = "probes/room.probe.0123456789abcdef.hdr";
    m.entity = "e12";
    m.hash = "0123456789abcdef";
    for (int i = 0; i < kProbeShCoefficients; ++i)
        for (int k = 0; k < 3; ++k) m.sh[i][k] = 0.25f * float(i) - 0.5f * float(k);
    const Json j = probe_manifest_to_json(m);
    auto back = probe_manifest_from_json(j, "room.probe.json");
    REQUIRE(back.ok());
    CHECK(back->resolution == 64);
    CHECK(back->levels == 4);
    CHECK(back->page == m.page);
    CHECK(back->entity == "e12");
    CHECK(back->hash == m.hash);
    for (int i = 0; i < kProbeShCoefficients; ++i)
        for (int k = 0; k < 3; ++k) CHECK(back->sh[i][k] == doctest::Approx(m.sh[i][k]));
    // The text of the JSON round trips as well (what the file holds).
    auto parsed = parse_json(dump_json(j), "room.probe.json");
    REQUIRE(parsed.ok());
    CHECK(dump_json(*parsed) == dump_json(j));

    Json bad = j;
    bad["resolution"] = 100;
    auto r1 = probe_manifest_from_json(bad, "room.probe.json");
    REQUIRE_FALSE(r1.ok());
    CHECK(r1.error().message.find("room.probe.json/resolution") != std::string::npos);
    CHECK_FALSE(r1.error().hint.empty());
    bad = j;
    bad["sh"][3] = Json::array({1.0, 2.0});
    auto r2 = probe_manifest_from_json(bad, "room.probe.json");
    REQUIRE_FALSE(r2.ok());
    CHECK(r2.error().message.find("/sh/3") != std::string::npos);
    bad = j;
    bad["version"] = 99;
    CHECK_FALSE(probe_manifest_from_json(bad, "x").ok());
    bad = j;
    bad.erase("page");
    CHECK_FALSE(probe_manifest_from_json(bad, "x").ok());
    CHECK_FALSE(probe_manifest_from_json(Json::array(), "x").ok());
}

TEST_CASE("probe page: the SH of a constant page is its colour, and a .hdr round trip keeps the bytes") {
    const int res = 32;
    auto page = ImageF::create(probe_page_width(res), probe_page_height(res), 3);
    REQUIRE(page.ok());
    for (int y = 0; y < page->height; ++y)
        for (int x = 0; x < page->width; ++x) {
            float* p = page->at(x, y);
            p[0] = 0.5f;
            p[1] = 1.0f;
            p[2] = 2.0f;
        }
    const ShL2 sh = probe_sh_from_page(*page, res);
    // Y00 = 0.282095: a constant radiance L has c0 = L * sqrt(4 pi).
    const float k = std::sqrt(4.0f * 3.14159265f);
    CHECK(sh.c[0].x == doctest::Approx(0.5f * k).epsilon(0.02));
    CHECK(sh.c[0].y == doctest::Approx(1.0f * k).epsilon(0.02));
    CHECK(sh.c[0].z == doctest::Approx(2.0f * k).epsilon(0.02));
    for (int i = 1; i < 9; ++i) CHECK(std::fabs(sh.c[i].y) < 0.03f);
    // Its irradiance is the colour for every normal.
    const Vec3 e = sh_irradiance(sh, normalize(Vec3{0.3f, -0.8f, 0.5f}));
    CHECK(e.y == doctest::Approx(1.0f).epsilon(0.03));

    // A gradient: light only from +Y (the pole) is brighter for an upward normal than a downward one.
    for (int y = 0; y < page->height; ++y)
        for (int x = 0; x < page->width; ++x) {
            const int ix = x - kProbeBorder, iy = y - kProbeBorder;
            const bool inside = ix >= 0 && iy >= 0 && ix < res && iy < res;
            const float up = inside ? oct_decode(oct_texel_coordinate(ix, iy, res)).y : 0.0f;
            float* p = page->at(x, y);
            p[0] = p[1] = p[2] = std::max(up, 0.0f);
        }
    const ShL2 g = probe_sh_from_page(*page, res);
    CHECK(sh_irradiance(g, Vec3{0, 1, 0}).x > sh_irradiance(g, Vec3{0, -1, 0}).x + 0.1f);

    // The page through the codec: encode, decode, encode again gives the same bytes.
    const auto bytes = encode_hdr(*page);
    REQUIRE_FALSE(bytes.empty());
    auto decoded = decode_hdr(bytes.data(), bytes.size());
    REQUIRE(decoded.ok());
    CHECK(decoded->width == page->width);
    CHECK(decoded->height == page->height);
    CHECK(encode_hdr(*decoded) == bytes);
    CHECK(probe_hash_hex(bytes).size() == 16);
    CHECK(probe_hash_hex(bytes) == probe_hash_hex(encode_hdr(*decoded)));
    auto other = bytes;
    other.back() ^= 1;
    CHECK(probe_hash_hex(other) != probe_hash_hex(bytes));
}

TEST_CASE("probe page: RGBE texels become the floats decode_hdr gives") {
    const int res = 32;
    const int w = probe_page_width(res), h = probe_page_height(res);
    std::vector<std::uint8_t> rgbe(std::size_t(w) * std::size_t(h) * 4u, 0);
    // Texel 0: (1, 0.5, 0.25) -> mantissas 128, 64, 32 with exponent 129; texel 1 stays black (exponent 0).
    rgbe[0] = 128;
    rgbe[1] = 64;
    rgbe[2] = 32;
    rgbe[3] = 129;
    auto page = probe_page_from_rgbe(rgbe, res);
    REQUIRE(page.ok());
    CHECK(page->width == w);
    CHECK(page->height == h);
    CHECK(page->at(0, 0)[0] == doctest::Approx(1.0f));
    CHECK(page->at(0, 0)[1] == doctest::Approx(0.5f));
    CHECK(page->at(0, 0)[2] == doctest::Approx(0.25f));
    CHECK(page->at(1, 0)[0] == 0.0f);
    // The same texel through the codec's own decoder.
    const auto bytes = encode_hdr(*page);
    auto viaCodec = decode_hdr(bytes.data(), bytes.size());
    REQUIRE(viaCodec.ok());
    CHECK(viaCodec->at(0, 0)[0] == doctest::Approx(1.0f).epsilon(0.01));
    rgbe.pop_back();
    CHECK_FALSE(probe_page_from_rgbe(rgbe, res).ok());
}
