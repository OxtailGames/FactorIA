// M73-P5d-1: the CPU side of the realtime GI grid (include/fa/render/gi.h): the layout and the validation of a RealtimeGI, the blocks of the
// atlas band, the eight probes around a point, the order the probes are captured in and the record of a grid. No GPU: the same file runs
// where `ctest -LE gpu` does (render_postprocess_core). gi_render_tests.cpp checks that the GPU fills the blocks this file lays out.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <set>

#include "fa/render/gi.h"
#include "fa/scene/components.h"

using namespace fa;
using namespace fa::render;

TEST_CASE("RealtimeGI layout: the grid is centred on the box and counts floor(size / spacing) + 1 per axis") {
    RealtimeGI c;
    c.size = {6.0f, 4.0f, 0.0f};
    c.spacing = 2.0f;
    const Result<GiLayout> r = gi_layout(c, {10.0f, 0.0f, 0.0f}, "room");
    REQUIRE(r.ok());
    const GiLayout& g = r.value();
    CHECK(g.nx == 4);
    CHECK(g.ny == 3);
    CHECK(g.nz == 1);  // size 0: one layer
    CHECK(g.count == 12);
    CHECK(g.origin.x == doctest::Approx(7.0f));  // 10 - 0.5 * 3 * 2
    CHECK(g.origin.y == doctest::Approx(-2.0f));
    CHECK(g.origin.z == doctest::Approx(0.0f));
    const Vec3 last = gi_probe_position(g, g.count - 1);
    CHECK(last.x == doctest::Approx(13.0f));
    CHECK(last.y == doctest::Approx(2.0f));
    // The same component and position give the same key; another position another key.
    CHECK(gi_layout(c, {10.0f, 0.0f, 0.0f}, "room").value().key == g.key);
    // The origin is not in the key (a moving entity must not restart the grid): gi_layout_moved says when it moved enough.
    CHECK(gi_layout(c, {11.0f, 0.0f, 0.0f}, "room").value().key == g.key);
    CHECK(gi_layout(c, {10.0f, 0.0f, -0.0f}, "room").value().key == g.key);
    // The settings that do not move a probe do not change the key (no new capture for them).
    c.intensity = 3.0f;
    c.hysteresis = 0.5f;
    c.bounce = 0.0f;
    CHECK(gi_layout(c, {10.0f, 0.0f, 0.0f}, "room").value().key == g.key);
    c.resolution = 32;
    CHECK(gi_layout(c, {10.0f, 0.0f, 0.0f}, "room").value().key != g.key);
}

TEST_CASE("RealtimeGI layout: errors name the entity and the field and say how to fix it") {
    const auto message = [](const RealtimeGI& c) {
        const Result<GiLayout> r = gi_layout(c, {}, "hall");
        REQUIRE_FALSE(r.ok());
        return r.error().to_string();
    };
    RealtimeGI c;
    c.spacing = 0.1f;
    std::string m = message(c);
    CHECK(m.find("RealtimeGI of entity 'hall'") != std::string::npos);
    CHECK(m.find("/spacing") != std::string::npos);
    CHECK(m.find("hint:") != std::string::npos);
    c = RealtimeGI{};
    c.resolution = 24;
    CHECK(message(c).find("/resolution") != std::string::npos);
    c = RealtimeGI{};
    c.size = {-1.0f, 1.0f, 1.0f};
    CHECK(message(c).find("/size") != std::string::npos);
    c = RealtimeGI{};
    c.size = {std::nanf(""), 1.0f, 1.0f};
    CHECK(message(c).find("/size") != std::string::npos);
    c = RealtimeGI{};
    c.probesPerFrame = 0;
    CHECK(message(c).find("/probesPerFrame") != std::string::npos);
    c = RealtimeGI{};
    c.hysteresis = 1.0f;
    CHECK(message(c).find("/hysteresis") != std::string::npos);
    c = RealtimeGI{};
    c.maxDistance = 0.5f;
    CHECK(message(c).find("/maxDistance") != std::string::npos);
    c = RealtimeGI{};
    c.nearExclusion = 5.0f;
    c.maxDistance = 4.0f;
    CHECK(message(c).find("/nearExclusion") != std::string::npos);
    // Too many probes: the message gives the counts and the limit.
    c = RealtimeGI{};
    c.size = {100.0f, 100.0f, 100.0f};
    c.spacing = 1.0f;
    m = message(c);
    CHECK(m.find("101 x 101 x 101") != std::string::npos);
    CHECK(m.find("1224") != std::string::npos);
    // The largest grid that fits is accepted.
    c = RealtimeGI{};
    c.size = {32.0f, 0.0f, 32.0f};
    c.spacing = 1.0f;  // 33 x 1 x 33 = 1089
    CHECK(gi_layout(c, {}, "ok").ok());
}

TEST_CASE("RealtimeGI blocks: the band holds 1224 blocks inside the atlas and they never overlap") {
    CHECK(kGiBlocksPerRow * kGiBlockW <= kProbeAtlasSize);
    CHECK(kGiAtlasHeight == kProbeAtlasSize + kGiBandHeight);
    std::set<std::pair<int, int>> seen;
    for (int b = 0; b < kGiMaxProbes; ++b) {
        const GiTexel t = gi_block_origin(b);
        CHECK(t.x >= 0);
        CHECK(t.x + kGiBlockW <= kProbeAtlasSize);
        CHECK(t.y >= kProbeAtlasSize);
        CHECK(t.y + kGiBlockH <= kGiAtlasHeight);
        seen.insert({t.x, t.y});
    }
    CHECK(seen.size() == std::size_t(kGiMaxProbes));
    CHECK(gi_block_origin(0).x == 0);
    CHECK(gi_block_origin(0).y == 1024);
    CHECK(gi_block_origin(102).y == 1024 + 11);
    CHECK(gi_block_origin(103).x == 10);
}

TEST_CASE("RealtimeGI allocator: first fit, a grid keeps its run, a run that does not fit is refused") {
    GiBlockAllocator a;
    CHECK(a.acquire(1, 100).value() == 0);
    CHECK(a.acquire(2, 50).value() == 100);
    CHECK(a.acquire(1, 100).value() == 0);  // the same size: the same run
    CHECK(a.used() == 150);
    a.release(1);
    CHECK(a.used() == 50);
    CHECK(a.acquire(3, 60).value() == 0);  // the first run that holds it: the one 1 gave back
    CHECK(a.acquire(4, 2000).has_value() == false);
    CHECK_FALSE(a.acquire(5, kGiMaxProbes).has_value());  // everything else is taken
    a.release(2);
    a.release(3);
    CHECK(a.acquire(5, kGiMaxProbes).value() == 0);
    CHECK(a.find(5).value() == 0);
    CHECK_FALSE(a.find(2).has_value());
    // A grid that grows moves to a run that holds it.
    a.clear();
    CHECK(a.acquire(1, 10).value() == 0);
    CHECK(a.acquire(2, 10).value() == 10);
    CHECK(a.acquire(1, 20).value() == 20);
}

TEST_CASE("RealtimeGI neighbours: the eight probes around a point weigh 1 and the nearest weighs most") {
    RealtimeGI c;
    c.size = {4.0f, 4.0f, 4.0f};
    c.spacing = 2.0f;
    const GiLayout g = gi_layout(c, {}, "e").value();  // 3 x 3 x 3 probes at -2, 0, 2
    REQUIRE(g.count == 27);
    for (Vec3 p :
         {Vec3{0.3f, -1.2f, 0.7f}, Vec3{-2.0f, -2.0f, -2.0f}, Vec3{5.0f, 5.0f, 5.0f}, Vec3{0.0f, 0.0f, 0.0f}}) {
        const GiNeighbours n = gi_neighbours(g, p);
        float sum = 0.0f;
        for (int i = 0; i < 8; ++i) {
            CHECK(n.index[i] >= 0);
            CHECK(n.index[i] < g.count);
            CHECK(n.weight[i] >= 0.0f);
            sum += n.weight[i];
        }
        CHECK(sum == doctest::Approx(1.0f));
        // The weighted positions give the point back (trilinear), for a point inside the box.
        if (std::fabs(p.x) <= 2.0f && std::fabs(p.y) <= 2.0f && std::fabs(p.z) <= 2.0f) {
            Vec3 at{};
            for (int i = 0; i < 8; ++i) at = at + gi_probe_position(g, n.index[i]) * n.weight[i];
            CHECK(at.x == doctest::Approx(p.x).epsilon(1e-4));
            CHECK(at.y == doctest::Approx(p.y).epsilon(1e-4));
            CHECK(at.z == doctest::Approx(p.z).epsilon(1e-4));
        }
    }
    // On a probe, that probe has all the weight.
    const GiNeighbours on = gi_neighbours(g, gi_probe_position(g, 13));
    float w13 = 0.0f;
    for (int i = 0; i < 8; ++i)
        if (on.index[i] == 13) w13 += on.weight[i];
    CHECK(w13 == doctest::Approx(1.0f));
    // A point outside the box is clamped to its edge.
    const GiNeighbours out = gi_neighbours(g, {100.0f, 0.0f, 0.0f});
    for (int i = 0; i < 8; ++i)
        if (out.weight[i] > 0.0f) CHECK(gi_probe_position(g, out.index[i]).x == doctest::Approx(2.0f));
    // One layer on an axis: only that layer is read.
    c.size = {4.0f, 0.0f, 4.0f};
    const GiLayout flat = gi_layout(c, {}, "e").value();
    const GiNeighbours f = gi_neighbours(flat, {0.5f, 9.0f, 0.5f});
    float sum = 0.0f;
    for (int i = 0; i < 8; ++i) {
        CHECK(f.index[i] < flat.count);
        sum += f.weight[i];
    }
    CHECK(sum == doctest::Approx(1.0f));
}

TEST_CASE("RealtimeGI order: the never captured first, then the longest ago, the same on every run") {
    std::vector<std::uint64_t> last = {0, 5, 0, 3, 9, 0};
    const std::vector<int> first = gi_pick(last, {}, 10, 2);
    REQUIRE(first.size() == 2);
    CHECK(first[0] == 0);
    CHECK(first[1] == 2);
    CHECK(gi_pick(last, {}, 10, 2) == first);
    CHECK(gi_pick(last, {}, 10, 4) == std::vector<int>{0, 2, 5, 3});
    CHECK(gi_pick(last, {}, 10, 100).size() == 6);
    CHECK(gi_pick(last, {}, 10, 0).empty());
    // A probe in its retry wait is skipped until its frame.
    const std::vector<std::uint64_t> retry = {20, 0, 0, 0, 0, 0};
    CHECK(gi_pick(last, retry, 10, 1) == std::vector<int>{2});
    CHECK(gi_pick(last, retry, 20, 1) == std::vector<int>{0});
    // Round robin: the probe just captured goes to the back.
    std::vector<std::uint64_t> state(5, 0);
    std::vector<int> order;
    std::uint64_t serial = 0;  // the ordinal of the capture: what the renderer keeps per probe
    for (std::uint64_t frame = 1; frame <= 12; ++frame)
        for (int i : gi_pick(state, {}, frame, 1)) {
            state[std::size_t(i)] = ++serial;
            order.push_back(i);
        }
    CHECK(order == std::vector<int>{0, 1, 2, 3, 4, 0, 1, 2, 3, 4, 0, 1});
    // Two a frame: every probe is captured as often as the others (10 frames, 20 captures, 4 each).
    std::vector<std::uint64_t> state2(5, 0);
    std::vector<int> count(5, 0);
    serial = 0;
    for (std::uint64_t frame = 1; frame <= 10; ++frame)
        for (int i : gi_pick(state2, {}, frame, 2)) {
            state2[std::size_t(i)] = ++serial;
            ++count[std::size_t(i)];
        }
    CHECK(count == std::vector<int>{4, 4, 4, 4, 4});
}

TEST_CASE("RealtimeGI layout: a move of less than half a spacing keeps the grid, a larger one or other tags lay it out "
          "again") {
    RealtimeGI c;
    c.size = {6.0f, 0.0f, 6.0f};
    c.spacing = 2.0f;
    const GiLayout a = gi_layout(c, {0.0f, 0.0f, 0.0f}, "room").value();
    const Vec3 anchor = a.origin;
    // 0.9 m: under the half spacing (1 m) on every axis.
    const GiLayout near = gi_layout(c, {0.9f, 0.0f, -0.9f}, "room").value();
    CHECK(near.key == a.key);
    CHECK_FALSE(gi_layout_moved(near, anchor));
    // 1 m or more on one axis.
    const GiLayout far = gi_layout(c, {0.0f, 1.0f, 0.0f}, "room").value();
    CHECK(far.key == a.key);
    CHECK(gi_layout_moved(far, anchor));
    CHECK(gi_layout_moved(gi_layout(c, {-1.5f, 0.0f, 0.0f}, "room").value(), anchor));
    // The tags decide what a capture draws.
    RealtimeGI t = c;
    t.hideTags = Json::array({Json("player")});
    CHECK(gi_layout(t, {0.0f, 0.0f, 0.0f}, "room").value().key != a.key);
    RealtimeGI s = c;
    s.showTags = Json::array({Json("player")});
    CHECK(gi_layout(s, {0.0f, 0.0f, 0.0f}, "room").value().key != a.key);
    CHECK(gi_layout(s, {0.0f, 0.0f, 0.0f}, "room").value().key != gi_layout(t, {0.0f, 0.0f, 0.0f}, "room").value().key);
}

TEST_CASE("RealtimeGI record: the four vec4 the shading reads") {
    RealtimeGI c;
    c.size = {4.0f, 2.0f, 0.0f};
    c.spacing = 2.0f;
    c.intensity = 1.5f;
    c.bounce = 0.5f;
    const GiLayout g = gi_layout(c, {1.0f, 2.0f, 3.0f}, "e").value();
    float r[kGiRecordFloats];
    gi_pack_record(g, 40, true, r);
    CHECK(r[0] == doctest::Approx(g.origin.x));
    CHECK(r[3] == doctest::Approx(2.0f));
    CHECK(r[4] == 3.0f);
    CHECK(r[5] == 2.0f);
    CHECK(r[6] == 1.0f);
    CHECK(r[7] == 6.0f);
    CHECK(r[8] == 40.0f);
    CHECK(r[9] == 102.0f);
    CHECK(r[10] == doctest::Approx(30.0f));
    CHECK(r[11] == doctest::Approx(1.5f));
    CHECK(r[12] == doctest::Approx(0.5f));
    CHECK(r[13] == doctest::Approx(0.25f));
    CHECK(r[14] == 1.0f);
    gi_pack_record(g, 40, false, r);
    CHECK(r[14] == 0.0f);
}

TEST_CASE("RealtimeGI depth map: a direction lands inside the interior texels of the block") {
    for (Vec3 d : {Vec3{0, 1, 0}, Vec3{0, -1, 0}, Vec3{1, 0, 0}, Vec3{-1, 0, 0}, Vec3{0, 0, 1}, Vec3{0, 0, -1},
                   normalize(Vec3{1, 1, 1}), normalize(Vec3{-1, -1, 1})}) {
        const Vec2 t = gi_depth_uv(d);
        CHECK(t.x >= float(kProbeBorder));
        CHECK(t.x <= float(kProbeBorder + kGiDepthTexels));
        CHECK(t.y >= float(kProbeBorder));
        CHECK(t.y <= float(kProbeBorder + kGiDepthTexels));
    }
    // +Y is the centre of the map.
    CHECK(gi_depth_uv({0, 1, 0}).x == doctest::Approx(5.0f));
    CHECK(gi_depth_uv({0, 1, 0}).y == doctest::Approx(5.0f));
}
