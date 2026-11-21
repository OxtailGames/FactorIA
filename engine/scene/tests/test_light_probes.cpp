// Light probes (M73.4d, fa/scene/light_probes.h): the layout of a LightProbeGroup, the file, the CPU interpolation a moving object reads, and the
// bake's validity test (a probe inside geometry), with the same bits on any number of threads.
#include <doctest.h>

#include <cmath>
#include <cstdint>
#include <cstring>
#include <string>
#include <vector>

#include "fa/core/jobs.h"
#include "fa/scene/components.h"
#include "fa/scene/light_probes.h"
#include "fa/scene/lightmap_bake.h"

using namespace fa;

namespace {

// A 3 x 1 x 1 grid along x (probes at x = -2, 0, 2; y = z = 0; spacing 2), every probe a constant sky of the given radiance.
ProbeSet strip(float a, float b, float c) {
    ProbeSet set;
    LightProbeGroup g;
    g.size = {4, 0, 0};
    g.spacing = 2;
    REQUIRE(add_probe_group(set, "strip", g, {0, 0, 0}).ok());
    REQUIRE(set.size() == 3);
    const float v[3] = {a, b, c};
    set.sh.resize(3);
    set.valid.assign(3, 1);
    for (int i = 0; i < 3; ++i) set.sh[std::size_t(i)].c[0] = {v[i], v[i], v[i]};
    return set;
}

BakeMesh quad_of(Vec3 o, Vec3 eu, Vec3 ev, Vec3 n, bool flip) {
    BakeMesh m;
    m.name = "q";
    m.positions = {o, o + eu, o + eu + ev, o + ev};
    const Vec3 nn = flip ? -n : n;
    m.normals = {nn, nn, nn, nn};
    m.indices = flip ? std::vector<std::uint32_t>{0, 2, 1, 0, 3, 2} : std::vector<std::uint32_t>{0, 1, 2, 0, 2, 3};
    m.materials = {0, 0};
    m.atlas = -1;
    return m;
}

// A closed unit-ish room [0,4]^3: normals point inside (flip = false) or outside (a solid block, flip = true).
BakeScene room(bool solid) {
    BakeScene sc;
    sc.sky.zenith = sc.sky.horizon = sc.sky.ground = {1, 1, 1};
    const float s = 4;
    sc.meshes.push_back(quad_of({0, 0, 0}, {s, 0, 0}, {0, s, 0}, {0, 0, 1}, solid));
    sc.meshes.push_back(quad_of({0, 0, s}, {s, 0, 0}, {0, s, 0}, {0, 0, -1}, solid));
    sc.meshes.push_back(quad_of({0, 0, 0}, {s, 0, 0}, {0, 0, s}, {0, 1, 0}, solid));
    sc.meshes.push_back(quad_of({0, s, 0}, {s, 0, 0}, {0, 0, s}, {0, -1, 0}, solid));
    sc.meshes.push_back(quad_of({0, 0, 0}, {0, s, 0}, {0, 0, s}, {1, 0, 0}, solid));
    sc.meshes.push_back(quad_of({s, 0, 0}, {0, s, 0}, {0, 0, s}, {-1, 0, 0}, solid));
    BakeLight l;
    l.kind = BakeLightKind::Point;
    l.position = {2, 3, 2};
    l.range = 8;
    l.intensity = 3;
    sc.lights = {l};
    sc.materials = {{{0.7f, 0.7f, 0.7f}, {}}};
    return sc;
}

}  // namespace

TEST_CASE("light probes: a grid is centred on its box, a point group follows it, and the counts are capped") {
    ProbeSet set;
    LightProbeGroup g;
    g.size = {4, 2, 0};
    g.spacing = 2;
    g.offset = {0, 1, 0};
    g.points = Json::array({Json::array({1.0, 2.0, 3.0})});
    REQUIRE(add_probe_group(set, "a", g, {10, 0, 0}).ok());
    REQUIRE(set.groups.size() == 2);
    CHECK(set.groups[0].nx == 3);
    CHECK(set.groups[0].ny == 2);
    CHECK(set.groups[0].nz == 1);
    CHECK(set.groups[0].count == 6);
    CHECK(set.groups[1].kind == ProbeGroupKind::Points);
    CHECK(set.size() == 7);
    CHECK(set.positions[0].x == doctest::Approx(8.0f));  // centre 10, three probes 2 apart
    CHECK(set.positions[0].y == doctest::Approx(0.0f));  // offset 1, two layers 2 apart: 0 and 2, centred on 1
    CHECK(set.positions[6].z == doctest::Approx(3.0f));
    ProbeSet none;
    g.grid = false;
    REQUIRE(add_probe_group(none, "b", g, {0, 0, 0}).ok());
    CHECK(none.size() == 1);

    LightProbeGroup big;
    big.size = {200, 200, 200};
    big.spacing = 1;
    auto bad = add_probe_group(none, "huge", big, {0, 0, 0});
    REQUIRE(!bad.ok());
    CHECK(bad.error().message.find("/spacing") != std::string::npos);
    CHECK(none.size() == 1);  // nothing was added
    LightProbeGroup wrong;
    wrong.grid = false;
    wrong.points = Json::array({Json::array({1.0, 2.0})});
    auto badPoint = add_probe_group(none, "p", wrong, {0, 0, 0});
    REQUIRE(!badPoint.ok());
    CHECK(badPoint.error().message.find("/points/0") != std::string::npos);
}

TEST_CASE("light probes: the file round-trips and a damaged one is refused before it allocates") {
    ProbeSet set = strip(1, 2, 3);
    set.valid[1] = 0;
    set.sh[1] = ShL2{};
    const std::vector<std::uint8_t> bytes = encode_probe_set(set);
    auto back = decode_probe_set(bytes.data(), bytes.size(), "x.probes");
    REQUIRE(back.ok());
    CHECK(back->size() == 3);
    CHECK(back->invalid_count() == 1);
    CHECK(back->groups[0].id == "strip");
    CHECK(back->sh[2].c[0].x == 3.0f);
    CHECK(back->positions[2].x == doctest::Approx(2.0f));
    CHECK(encode_probe_set(*back) == bytes);
    for (std::size_t cut : {std::size_t(0), std::size_t(3), std::size_t(20), bytes.size() - 1}) {
        auto r = decode_probe_set(bytes.data(), cut, "x.probes");
        CHECK(!r.ok());
    }
    std::vector<std::uint8_t> lie = bytes;
    lie[12] = 0xff;  // probe count 255 (+ the rest of the word as it was): the groups no longer cover it
    CHECK(!decode_probe_set(lie.data(), lie.size(), "x.probes").ok());
}

TEST_CASE("light probes: trilinear at the corners, continuous across a cell, invalid probes skipped, a fade outside") {
    ProbeSet set = strip(1, 5, 9);
    // the corners give the probes
    for (int i = 0; i < 3; ++i) {
        const ProbeLight l = probe_light_at(set, {float(i * 2 - 2), 0, 0});
        CHECK(l.coverage == doctest::Approx(1.0f));
        CHECK(l.sh.c[0].x == doctest::Approx(float(1 + 4 * i)));
    }
    // halfway between two probes: their mean; and no jump where the cell changes (x = 0)
    CHECK(probe_light_at(set, {-1, 0, 0}).sh.c[0].x == doctest::Approx(3.0f));
    CHECK(probe_light_at(set, {1, 0, 0}).sh.c[0].x == doctest::Approx(7.0f));
    const float below = probe_light_at(set, {-1e-4f, 0, 0}).sh.c[0].x,
                above = probe_light_at(set, {1e-4f, 0, 0}).sh.c[0].x;
    CHECK(std::fabs(above - below) < 1e-3f);
    // the layer axes (one probe) do not matter near the probes, and a point far above the layer is out of its reach
    CHECK(probe_light_at(set, {0, 0.5f, 0.5f}).coverage == doctest::Approx(1.0f));
    CHECK(probe_light_at(set, {0, 5, 0}).coverage == 0.0f);
    CHECK(probe_light_at(set, {0, 5, 0}).sh.c[0].x == 0.0f);
    // outside the strip along x: full coverage at the edge, falling to 0 one spacing further, the SH of the border probe
    const ProbeLight edge = probe_light_at(set, {3, 0, 0});
    CHECK(edge.coverage == doctest::Approx(0.5f));
    CHECK(edge.sh.c[0].x == doctest::Approx(9.0f));
    CHECK(probe_light_at(set, {5, 0, 0}).coverage == 0.0f);
    // an invalid probe is skipped: the others are renormalised, not darkened
    set.valid[1] = 0;
    set.sh[1] = ShL2{};
    const ProbeLight skip = probe_light_at(set, {-1, 0, 0});  // between probe 0 (valid) and probe 1 (invalid)
    CHECK(skip.sh.c[0].x == doctest::Approx(1.0f));
    CHECK(skip.coverage == doctest::Approx(1.0f));  // half of the weight is left: above the 0.25 that counts as full
    const ProbeLight nearInvalid =
        probe_light_at(set, {-0.05f, 0, 0});  // almost on the invalid probe: little weight is left
    CHECK(nearInvalid.coverage < skip.coverage);
    CHECK(probe_light_at(set, {0, 0, 0}).coverage ==
          0.0f);  // on the invalid probe and its cell neighbours at weight 0 or 1
    // all invalid: nothing covers
    set.valid.assign(3, 0);
    CHECK(probe_light_at(set, {0, 0, 0}).coverage == 0.0f);
    // an unbaked set covers nothing
    ProbeSet raw;
    LightProbeGroup g;
    REQUIRE(add_probe_group(raw, "r", g, {0, 0, 0}).ok());
    CHECK(probe_light_at(raw, {0, 0, 0}).coverage == 0.0f);
    CHECK(probe_light_key(probe_light_at(raw, {0, 0, 0})) == 0);
}

TEST_CASE("light probes: single points light the objects near them, the nearer the stronger, and equal light has an "
          "equal key") {
    ProbeSet set;
    LightProbeGroup g;
    g.grid = false;
    g.points = Json::array({Json::array({0.0, 0.0, 0.0})});
    REQUIRE(add_probe_group(set, "p", g, {0, 0, 0}).ok());
    set.sh.resize(1);
    set.valid.assign(1, 1);
    set.sh[0].c[0] = {2, 2, 2};
    const ProbeLight at = probe_light_at(set, {0, 0, 0}), mid = probe_light_at(set, {2.5f, 0, 0}),
                     far = probe_light_at(set, {6, 0, 0});
    CHECK(at.coverage == doctest::Approx(1.0f));
    CHECK(mid.coverage == doctest::Approx(0.25f));
    CHECK(mid.sh.c[0].x == doctest::Approx(2.0f));  // a mean of one probe is that probe: the coverage carries the fade
    CHECK(far.coverage == 0.0f);
    CHECK(probe_light_key(at) == probe_light_key(probe_light_at(set, {0, 0, 0})));
    CHECK(probe_light_key(at) != probe_light_key(mid));
    CHECK(probe_light_key(far) == 0);
}

TEST_CASE(
    "sample_probes: a probe inside a solid block is flagged and zeroed, one in a room is not, on any thread count") {
    BakeSettings st;
    st.samples = 48;
    st.bounces = 1;
    st.shadowSamples = 2;
    const std::vector<Vec3> pts = {{2, 2, 2}, {1, 1, 1}, {3, 1.5f, 2.5f}};
    auto inRoom = sample_probes(room(false), pts, st);
    auto inBlock = sample_probes(room(true), pts, st);
    REQUIRE(inRoom.ok());
    REQUIRE(inBlock.ok());
    for (std::size_t i = 0; i < pts.size(); ++i) {
        CHECK((*inRoom)[i].valid);
        CHECK((*inRoom)[i].backFraction == 0.0f);
        CHECK(sh_irradiance((*inRoom)[i].sh, {0, 1, 0}).x > 0.2f);
        CHECK(!(*inBlock)[i].valid);
        CHECK((*inBlock)[i].backFraction > 0.9f);
        CHECK(sh_irradiance((*inBlock)[i].sh, {0, 1, 0}).x == 0.0f);
    }
    // a tolerance of 1 keeps everything
    st.probeBackfaceTolerance = 1.0f;
    auto lenient = sample_probes(room(true), pts, st);
    REQUIRE(lenient.ok());
    CHECK((*lenient)[0].valid);
    st.probeBackfaceTolerance = 0.25f;
    // sample_irradiance_sh gives the same SH as sample_probes for the valid probes
    auto plain = sample_irradiance_sh(room(false), pts, st);
    REQUIRE(plain.ok());
    for (int k = 0; k < 9; ++k) CHECK((*plain)[0].c[k].x == (*inRoom)[0].sh.c[k].x);

    // the same bytes with one thread and with four
    std::vector<ProbeSample> one, four;
    {
        REQUIRE(jobs::start(jobs::Settings::threads(1)).ok());
        auto r = sample_probes(room(false), pts, st);
        jobs::stop();
        REQUIRE(r.ok());
        one = *r;
    }
    {
        REQUIRE(jobs::start(jobs::Settings::threads(4)).ok());
        auto r = sample_probes(room(false), pts, st);
        jobs::stop();
        REQUIRE(r.ok());
        four = *r;
    }
    REQUIRE(one.size() == four.size());
    for (std::size_t i = 0; i < one.size(); ++i) {
        CHECK(one[i].valid == four[i].valid);
        for (int k = 0; k < 9; ++k) {
            CHECK(one[i].sh.c[k].x == four[i].sh.c[k].x);
            CHECK(one[i].sh.c[k].y == four[i].sh.c[k].y);
            CHECK(one[i].sh.c[k].z == four[i].sh.c[k].z);
        }
    }
}

TEST_CASE("sample_probes: progress names the probes phase and ends at the last probe") {
    BakeSettings st;
    st.samples = 8;
    std::vector<BakeProgress> seen;
    auto r = sample_probes(room(false), {{2, 2, 2}, {1, 1, 1}}, st, [&](const BakeProgress& p) { seen.push_back(p); });
    REQUIRE(r.ok());
    REQUIRE(!seen.empty());
    CHECK(seen.back().phase == BakePhase::Probes);
    CHECK(seen.back().done == seen.back().total);
    CHECK(seen.back().total == 2);
}

namespace {
// Two grids (one with a single layer), a group of points and an empty-looking far group, all baked with different light.
ProbeSet many_groups() {
    ProbeSet set;
    LightProbeGroup a;
    a.size = {6, 4, 6};
    a.spacing = 2;
    REQUIRE(add_probe_group(set, "a", a, {0, 0, 0}).ok());
    LightProbeGroup b;
    b.size = {8, 0, 8};
    b.spacing = 2;
    REQUIRE(add_probe_group(set, "b", b, {20, 1, 3}).ok());
    LightProbeGroup c;
    c.grid = false;
    c.points =
        Json::array({Json::array({-9.0, 1.0, 2.0}), Json::array({-12.5, 2.0, 2.5}), Json::array({40.0, 0.0, 0.0})});
    REQUIRE(add_probe_group(set, "c", c, {0, 0, 0}).ok());
    set.sh.resize(set.size());
    set.valid.assign(set.size(), 1);
    for (std::size_t i = 0; i < set.size(); ++i) {
        set.sh[i].c[0] = {1.0f + float(i % 7), 0.5f + float(i % 5), 0.25f + float(i % 3)};
        set.sh[i].c[3] = {0.1f * float(i % 4), 0.0f, 0.0f};
    }
    set.valid[4] = 0;
    return set;
}
}  // namespace

TEST_CASE("light probes: the group boxes cull without changing a single result") {
    ProbeSet boxed = many_groups();
    REQUIRE(boxed.bounds.size() == boxed.groups.size());
    ProbeSet plain = boxed;
    plain.bounds.clear();  // a set built by hand has no boxes: read in full
    int covered = 0, empty = 0;
    // A lattice around and well outside every group, including the faces of the boxes themselves.
    for (float x = -16.0f; x <= 44.0f; x += 1.25f)
        for (float y = -3.0f; y <= 6.0f; y += 1.0f)
            for (float z = -8.0f; z <= 12.0f; z += 1.25f) {
                const ProbeLight a = probe_light_at(boxed, {x, y, z}), b = probe_light_at(plain, {x, y, z});
                REQUIRE(a.coverage == b.coverage);
                REQUIRE(a.probesUsed == b.probesUsed);
                REQUIRE(probe_light_key(a) == probe_light_key(b));
                REQUIRE(std::memcmp(&a.sh, &b.sh, sizeof a.sh) == 0);
                (a.coverage > 0 ? covered : empty)++;
            }
    CHECK(covered > 100);
    CHECK(empty > 100);  // the boxes did cull something
    // The faces of one group alone: a grid reaches one spacing past its probes, a point kProbePointRadius, and not further.
    const ProbeSet one = strip(1, 5, 9);  // probes at x = -2, 0, 2, spacing 2
    CHECK(probe_light_at(one, {-2.0f - 2.0f - 0.01f, 0, 0}).coverage == 0.0f);
    CHECK(probe_light_at(one, {-2.0f - 1.9f, 0, 0}).coverage > 0.0f);
    ProbeSet pts;
    LightProbeGroup pg;
    pg.grid = false;
    pg.points = Json::array({Json::array({10.0, 0.0, 0.0})});
    REQUIRE(add_probe_group(pts, "p", pg, {0, 0, 0}).ok());
    pts.sh.assign(1, ShL2{});
    pts.sh[0].c[0] = {1, 1, 1};
    pts.valid.assign(1, 1);
    CHECK(probe_light_at(pts, {10.0f + kProbePointRadius + 0.01f, 0, 0}).coverage == 0.0f);
    CHECK(probe_light_at(pts, {10.0f + kProbePointRadius - 0.5f, 0, 0}).coverage > 0.0f);
}

TEST_CASE("light probes: a baked group is told from one that was edited since (find_same_probe_group)") {
    const ProbeSet baked = many_groups();
    ProbeSet scene = many_groups();
    for (const ProbeGroup& g : scene.groups) CHECK(find_same_probe_group(baked, scene, g) != nullptr);
    CHECK(find_same_probe_group(baked, scene, scene.groups[1])->id == "b");

    ProbeSet edited;
    LightProbeGroup a;
    a.size = {6, 4, 6};
    a.spacing = 1.5f;  // spacing changed
    REQUIRE(add_probe_group(edited, "a", a, {0, 0, 0}).ok());
    CHECK(find_same_probe_group(baked, edited, edited.groups[0]) == nullptr);
    LightProbeGroup moved = a;
    moved.spacing = 2;
    ProbeSet shifted;
    REQUIRE(add_probe_group(shifted, "a", moved, {0.5f, 0, 0}).ok());  // the entity moved
    CHECK(find_same_probe_group(baked, shifted, shifted.groups[0]) == nullptr);
    ProbeSet same;
    REQUIRE(add_probe_group(same, "a", moved, {0, 0, 0}).ok());
    CHECK(find_same_probe_group(baked, same, same.groups[0]) != nullptr);

    // One entity with a grid and points (the same id): each is matched on its own kind, never on the other's.
    ProbeSet both, bothScene;
    LightProbeGroup mixed;
    mixed.size = {2, 0, 0};
    mixed.spacing = 2;
    mixed.points = Json::array({Json::array({5.0, 5.0, 5.0})});
    REQUIRE(add_probe_group(both, "m", mixed, {0, 0, 0}).ok());
    REQUIRE(add_probe_group(bothScene, "m", mixed, {0, 0, 0}).ok());
    REQUIRE(both.groups.size() == 2);
    CHECK(find_same_probe_group(both, bothScene, bothScene.groups[0])->kind == ProbeGroupKind::Grid);
    CHECK(find_same_probe_group(both, bothScene, bothScene.groups[1])->kind == ProbeGroupKind::Points);
    mixed.points = Json::array({Json::array({5.0, 5.0, 6.0})});  // only the point moved
    ProbeSet pointMoved;
    REQUIRE(add_probe_group(pointMoved, "m", mixed, {0, 0, 0}).ok());
    CHECK(find_same_probe_group(both, pointMoved, pointMoved.groups[0]) != nullptr);
    CHECK(find_same_probe_group(both, pointMoved, pointMoved.groups[1]) == nullptr);
}
