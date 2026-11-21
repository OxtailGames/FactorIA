// M73-P5d-1: the realtime GI's grid on the GPU (docs/design/ARCHITECTURE_PROBES.md, "Realtime GI: the data side"). The shading is tested in
// gi_shading_tests.cpp; these tests read the blocks of the probes in the atlas's band back and look at what a capture left in them:
//   - a red wall on one side and a green one on the other: the probes near a wall are tinted by it, the one in the middle is not;
//   - the depth map holds the distance of the wall and maxDistance where nothing is;
//   - the budget of probes a frame is respected and every probe is captured in the end;
//   - two renderers given the same scene leave the same bytes in the blocks;
//   - a probe inside a closed box is reported invalid, the one outside it is not;
//   - a scene without a RealtimeGI costs nothing (no atlas, no grid), and one with it draws the same picture when it has no lit mesh.
// The tolerances hold on llvmpipe and WARP as well as on a real GPU; no golden image is compared.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <string>
#include <vector>

#include "fa/render/gi.h"
#include "fa/render/probe.h"
#include "render_internal.h"
#include "renderer_test_access.h"

using namespace fa;
using namespace fa::test;
using namespace fa::render;

namespace {

struct Own {
    Gfx& g;
    Renderer r;
    bool ok = false;
    std::string error;
    explicit Own(Gfx& gx) : g(gx) {
        RendererDesc d;
        d.designWidth = 320;
        d.designHeight = 180;
        d.sampleCount = 1;
        d.headless = true;
        d.adoptContext = true;
        ok = r.init(d, g.gpu.environment(), &error);
    }
    ~Own() { r.shutdown(); }
    Own(const Own&) = delete;
    Own& operator=(const Own&) = delete;
    void frame(World& w) {
        r.begin_frame();
        r.render_world(w, 0.0f);
        r.end_frame();
        g.gpu.end_frame();
    }
    Image picture(World& w) {
        frame(w);
        Image img;
        std::string err;
        INFO("capture error: " << err);
        REQUIRE(r.capture(img, &err));
        return img;
    }
};

struct ForceRgba8 {
    ForceRgba8() { renderer_probe_force_rgba8(true); }
    ~ForceRgba8() { renderer_probe_force_rgba8(false); }
};

void add_box(World& w, const char* name, Vec3 pos, Vec3 scale, Color emissive) {
    Entity e = make(w, name, pos);
    w.get<Transform>(e)->scale = scale;
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = "cube";
    m.color = Color{0, 0, 0, 1};
    m.unlit = true;
    m.emissive = emissive;
    m.castShadows = false;
}

void dark_world(World& w) {
    Entity cam = make(w, "cam", {0, 0, 0});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    w.settings().ambientLight = Color{0, 0, 0, 1};
    w.settings().skyColor = Color{0, 0, 0, 1};
    w.settings().horizonColor = Color{0, 0, 0, 1};
}

Entity add_gi(World& w, Vec3 size, float spacing, int perFrame, Vec3 pos = {0, 0, 0}) {
    Entity e = make(w, "gi", pos);
    auto& gi = w.add<RealtimeGI>(e);
    gi.size = size;
    gi.spacing = spacing;
    gi.probesPerFrame = perFrame;
    gi.resolution = 16;
    gi.maxDistance = 30.0f;
    return e;
}

bool half_float_gi(Gfx& g) { return g.renderer.supports("floatTargets"); }

// A red wall at x = +6 and a green one at x = -6, 12 m on a side, seen by a line of three probes at x = -4, 0, 4.
Entity build_walls(World& w) {
    dark_world(w);
    add_box(w, "red", {6, 0, 0}, {0.2f, 12, 12}, Color{1, 0, 0, 1});
    add_box(w, "green", {-6, 0, 0}, {0.2f, 12, 12}, Color{0, 1, 0, 1});
    return add_gi(w, {8, 0, 0}, 4.0f, 3);
}

const Json* grid_json(const Json& report, const std::string& name) {
    if (!report.contains("grids")) return nullptr;
    for (const Json& p : report["grids"])
        if (p.value("entity", std::string()) == name) return &p;
    return nullptr;
}

// What the blocks of a grid hold (read back from the band of the atlas).
struct Block {
    std::vector<float> rgba;  // the block's 10 x 11 texels, RGBA floats, row 0 = the first depth row
    bool ok = false;
};

Block read_block(Own& o, int block) {
    Block b;
    const GiTexel t = gi_block_origin(block);
    std::string error;
    b.ok = renderer_read_probe_atlas(o.r, t.x, t.y, kGiBlockW, kGiBlockH, b.rgba, &error);
    INFO("read error: " << error);
    return b;
}

float dc(const Block& b, int channel) {  // coefficient 0 of the SH row
    return b.rgba[(std::size_t(kGiShRow) * kGiBlockW + 0) * 4 + std::size_t(channel)];
}
float meta(const Block& b, int channel) {
    return b.rgba[(std::size_t(kGiShRow) * kGiBlockW + kGiMetaX) * 4 + std::size_t(channel)];
}
// The mean distance in metres the depth map holds toward `d`: the map stores d / maxDistance (0..1).
float depth_toward(const Block& b, Vec3 d, float maxDistance) {
    const Vec2 uv = gi_depth_uv(normalize(d));
    const int x = std::clamp(int(std::lround(uv.x)), 1, kGiDepthTexels);
    const int y = std::clamp(int(std::lround(uv.y)), 1, kGiDepthTexels);
    return b.rgba[(std::size_t(y) * kGiBlockW + std::size_t(x)) * 4] * maxDistance;
}

int first_block(const Json& grid) { return grid["firstBlock"].get<int>(); }

void run_frames(Own& o, World& w, int n) {
    for (int i = 0; i < n; ++i) o.frame(w);
}

}  // namespace

TEST_CASE("realtime GI: the probes near a coloured wall are tinted by it and the depth map holds the wall's distance") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_gi(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    Own o(g);
    REQUIRE(o.ok);
    World w;
    const Entity gi = build_walls(w);
    run_frames(o, w, 4);
    const Json report = o.r.gi_report();
    INFO("report: " << report.dump(2));
    const Json* grid = grid_json(report, w.id_of(gi));
    REQUIRE(grid != nullptr);
    if ((*grid)["state"] == "unsupported") {
        MESSAGE("this GPU cannot blend into RGBA16F: not run");
        return;
    }
    CHECK((*grid)["state"] == "ready");
    CHECK((*grid)["probes"].get<int>() == 3);
    const int base = first_block(*grid);
    const Block west = read_block(o, base + 0), mid = read_block(o, base + 1), east = read_block(o, base + 2);
    REQUIRE(west.ok);
    REQUIRE(mid.ok);
    REQUIRE(east.ok);
    for (const Block* b : {&west, &mid, &east}) {
        CHECK(meta(*b, 1) > 0.5f);   // captured
        CHECK(meta(*b, 0) < 0.05f);  // no back face
        for (int c = 0; c < 3; ++c) CHECK(std::isfinite(dc(*b, c)));
    }
    // The probe at x = +4 is 2 m from the red wall and 10 m from the green one: red, and clearly more than green.
    CHECK(dc(east, 0) > 0.05f);
    CHECK(dc(east, 0) > 3.0f * dc(east, 1));
    CHECK(dc(west, 1) > 3.0f * dc(west, 0));
    // The one in the middle is lit by both about the same.
    CHECK(std::fabs(dc(mid, 0) - dc(mid, 1)) < 0.25f * std::max(dc(mid, 0), dc(mid, 1)));
    // The wall that is near gives more light than the same wall seen from the middle, and the far wall less than from the middle.
    CHECK(dc(east, 0) > dc(mid, 0));
    CHECK(dc(west, 1) > dc(mid, 1));
    // Distances: the red wall's face is at x = 5.9, so 1.9 m from the probe at x = 4 toward +X; nothing above: maxDistance.
    const float toWall = depth_toward(east, {1, 0.1f, 0.1f}, 30.0f);
    CHECK(toWall > 1.4f);
    CHECK(toWall < 2.6f);
    CHECK(depth_toward(east, {-1, 0.1f, 0.1f}, 30.0f) > 8.0f);  // the green wall, 9.9 m away
    CHECK(depth_toward(east, {0.1f, 1, 0.1f}, 30.0f) > 25.0f);  // the sky: maxDistance (30)
    // The moments are normalised (d / maxDistance): both in 0..1, and the second is at least the square of the first (a variance
    // cannot be negative), up to the half floats' rounding.
    for (int y = 1; y <= kGiDepthTexels; ++y)
        for (int x = 1; x <= kGiDepthTexels; ++x) {
            const std::size_t i = (std::size_t(y) * kGiBlockW + std::size_t(x)) * 4;
            CHECK(east.rgba[i] >= 0.0f);
            CHECK(east.rgba[i] <= 1.002f);
            CHECK(east.rgba[i + 1] <= 1.002f);
            CHECK(east.rgba[i + 1] >= east.rgba[i] * east.rgba[i] * 0.97f - 0.002f);
        }
}

TEST_CASE("realtime GI: the depth moments stay finite and right with a maxDistance of 500") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_gi(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    Own o(g);
    REQUIRE(o.ok);
    World w;
    dark_world(w);
    add_box(w, "red", {6, 0, 0}, {0.2f, 12, 12}, Color{1, 0, 0, 1});
    const Entity gi = add_gi(w, {0, 0, 0}, 4.0f, 1, {4, 0, 0});
    w.get<RealtimeGI>(gi)->maxDistance = 500.0f;
    run_frames(o, w, 4);
    const Json report = o.r.gi_report();
    INFO("report: " << report.dump(2));
    const Json* grid = grid_json(report, w.id_of(gi));
    REQUIRE(grid != nullptr);
    if ((*grid)["state"] == "unsupported") {
        MESSAGE("this GPU cannot blend into RGBA16F: not run");
        return;
    }
    CHECK((*grid)["state"] == "ready");
    const Block b = read_block(o, first_block(*grid));
    REQUIRE(b.ok);
    CHECK(meta(b, 1) > 0.5f);
    for (int y = 1; y <= kGiDepthTexels; ++y)
        for (int x = 1; x <= kGiDepthTexels; ++x) {
            const std::size_t i = (std::size_t(y) * kGiBlockW + std::size_t(x)) * 4;
            CHECK(std::isfinite(b.rgba[i]));
            CHECK(std::isfinite(b.rgba[i + 1]));
            CHECK(b.rgba[i] <= 1.002f);
            CHECK(b.rgba[i + 1] <= 1.002f);
            CHECK(b.rgba[i + 1] >= b.rgba[i] * b.rgba[i] * 0.97f - 0.002f);
        }
    // The red wall's face is at x = 5.9: 1.9 m from the probe at x = 4; nothing above it: maxDistance (500).
    const float toWall = depth_toward(b, {1, 0.1f, 0.1f}, 500.0f);
    CHECK(toWall > 1.0f);
    CHECK(toWall < 4.0f);
    // The texel of straight up covers about 20 degrees, so a few of its taps still reach the wall's top: the mean is under 500.
    CHECK(depth_toward(b, {0.1f, 1, 0.1f}, 500.0f) > 400.0f);
}

TEST_CASE("realtime GI: a frame captures at most probesPerFrame probes and every probe is captured in the end") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_gi(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    Own o(g);
    REQUIRE(o.ok);
    World w;
    dark_world(w);
    add_box(w, "floor", {0, -2, 0}, {10, 0.2f, 10}, Color{0.5f, 0.5f, 0.5f, 1});
    const Entity gi = add_gi(w, {6, 0, 6}, 2.0f, 3);  // 4 x 1 x 4 = 16 probes
    int previous = 0;
    bool unsupported = false;
    for (int i = 0; i < 14; ++i) {
        o.frame(w);
        const Json report = o.r.gi_report();
        const Json* grid = grid_json(report, w.id_of(gi));
        REQUIRE(grid != nullptr);
        if ((*grid)["state"] == "unsupported") {
            unsupported = true;
            break;
        }
        INFO("frame " << i << " report: " << report.dump(2));
        REQUIRE((*grid)["probes"].get<int>() == 16);
        const int captured = (*grid)["captured"].get<int>();
        CHECK(captured >= previous);
        CHECK(captured <= 16);
        CHECK(captured - previous <= 3);
        CHECK((*grid)["capturesLastFrame"].get<int>() <= 3);
        previous = captured;
        CHECK(report["capturesPerFrame"].back().get<int>() <= 3);
    }
    if (unsupported) {
        MESSAGE("this GPU cannot blend into RGBA16F: not run");
        return;
    }
    // 14 frames at 3 probes: 16 probes captured by the sixth frame at the latest.
    const Json report = o.r.gi_report();
    const Json* grid = grid_json(report, w.id_of(gi));
    REQUIRE(grid != nullptr);
    CHECK((*grid)["captured"].get<int>() == 16);
    CHECK((*grid)["state"] == "ready");
    CHECK((*grid)["progress"].get<double>() == doctest::Approx(1.0));
    CHECK((*grid)["cycles"].get<double>() >= 1.0);
    // No frame captured more than the budget, and the total is 14 frames of 3 probes at most.
    int sum = 0;
    for (const Json& n : report["capturesPerFrame"]) {
        CHECK(n.get<int>() <= 3);
        sum += n.get<int>();
    }
    CHECK(sum <= 14 * 3);
    CHECK(sum >= 16);
}

TEST_CASE("realtime GI: the same scene leaves the same bytes in the blocks on every run") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_gi(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    std::vector<float> runs[2];
    for (int run = 0; run < 2; ++run) {
        Own o(g);
        REQUIRE(o.ok);
        World w;
        const Entity gi = build_walls(w);
        run_frames(o, w, 6);
        const Json report = o.r.gi_report();
        const Json* grid = grid_json(report, w.id_of(gi));
        REQUIRE(grid != nullptr);
        if ((*grid)["state"] == "unsupported") {
            MESSAGE("this GPU cannot blend into RGBA16F: not run");
            return;
        }
        for (int p = 0; p < 3; ++p) {
            const Block b = read_block(o, first_block(*grid) + p);
            REQUIRE(b.ok);
            runs[run].insert(runs[run].end(), b.rgba.begin(), b.rgba.end());
        }
    }
    REQUIRE(runs[0].size() == runs[1].size());
    REQUIRE(!runs[0].empty());
    float worst = 0.0f;
    for (std::size_t i = 0; i < runs[0].size(); ++i) worst = std::max(worst, std::fabs(runs[0][i] - runs[1][i]));
    CHECK(worst < 1e-4f);
}

TEST_CASE("realtime GI: a probe inside a closed box is reported invalid and the one outside it is not") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_gi(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    Own o(g);
    REQUIRE(o.ok);
    World w;
    dark_world(w);
    add_box(w, "box", {-2, 0, 0}, {3, 3, 3}, Color{1, 1, 1, 1});  // x from -3.5 to -0.5
    const Entity gi = add_gi(w, {4, 0, 0}, 4.0f, 2);              // probes at x = -2 (inside the box) and x = +2
    run_frames(o, w, 4);
    const Json report = o.r.gi_report();
    INFO("report: " << report.dump(2));
    const Json* grid = grid_json(report, w.id_of(gi));
    REQUIRE(grid != nullptr);
    if ((*grid)["state"] == "unsupported") {
        MESSAGE("this GPU cannot blend into RGBA16F: not run");
        return;
    }
    REQUIRE((*grid)["probes"].get<int>() == 2);
    CHECK((*grid)["state"] == "ready");
    CHECK((*grid)["invalidProbes"].get<int>() == 1);
    CHECK((*grid)["notCaptured"].get<int>() == 0);
    REQUIRE((*grid)["invalid"].size() == 1);
    CHECK((*grid)["invalid"][0]["index"].get<int>() == 0);
    const Block inside = read_block(o, first_block(*grid) + 0), outside = read_block(o, first_block(*grid) + 1);
    REQUIRE(inside.ok);
    REQUIRE(outside.ok);
    CHECK(meta(inside, 0) > 0.5f);
    CHECK(meta(outside, 0) < 0.05f);
}

TEST_CASE("realtime GI: a scene without a RealtimeGI costs nothing and one with it draws the same picture") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_gi(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    Own o(g);
    REQUIRE(o.ok);
    World w;
    dark_world(w);
    add_box(w, "red", {0, 0, -4}, {2, 2, 0.2f}, Color{1, 0, 0, 1});
    const Image before = o.picture(w);
    REQUIRE(!before.empty());
    CHECK(o.r.gi_report().dump() == "{}");     // no grid
    CHECK(o.r.probe_report().dump() == "{}");  // no atlas: not a pass of the probes ran

    const Entity gi = add_gi(w, {6, 0, 6}, 2.0f, 4, {0, 0, -4});
    run_frames(o, w, 3);
    const Json report = o.r.gi_report();
    const Json* grid = grid_json(report, w.id_of(gi));
    REQUIRE(grid != nullptr);
    if ((*grid)["state"] == "unsupported") {
        MESSAGE("this GPU cannot blend into RGBA16F: only the zero cost was checked");
        return;
    }
    CHECK(report["captures"].get<double>() > 0.0);
    const Image during = o.picture(w);
    CHECK(during.rgba == before.rgba);  // the scene has unlit meshes only: the grid changes nothing of them

    // The component goes: the grid and its blocks go with it, no probe is captured any more, the picture is the same.
    w.destroy_immediate(gi);
    const Image after = o.picture(w);
    CHECK(o.r.gi_report().dump() == "{}");
    CHECK(after.rgba == before.rgba);
    CHECK(o.r.probe_report().dump().find("\"created\":true") == std::string::npos);
}

TEST_CASE("realtime GI: a grid that is wrong says what is wrong, and a GPU without RGBA16F blending says it cannot") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_gi(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    {
        Own o(g);
        REQUIRE(o.ok);
        World w;
        dark_world(w);
        const Entity e = add_gi(w, {1000, 1000, 1000}, 0.5f, 2);  // 2001 x 2001 x 2001 probes
        run_frames(o, w, 2);
        const Json report = o.r.gi_report();
        INFO("report: " << report.dump(2));
        const Json* grid = grid_json(report, w.id_of(e));
        REQUIRE(grid != nullptr);
        if ((*grid)["state"] == "unsupported") {
            MESSAGE("this GPU cannot blend into RGBA16F: the layout errors were not checked");
        } else {
            CHECK((*grid)["state"] == "invalid");
            const std::string message = (*grid)["message"].get<std::string>();
            CHECK(message.find("/spacing") != std::string::npos);  // the field to change, as a JSON pointer
        }
    }
    {
        ForceRgba8 force;
        Own o(g);
        REQUIRE(o.ok);
        World w;
        dark_world(w);
        const Entity e = add_gi(w, {4, 0, 4}, 2.0f, 2);
        run_frames(o, w, 2);
        const Json report = o.r.gi_report();
        INFO("report: " << report.dump(2));
        const Json* grid = grid_json(report, w.id_of(e));
        REQUIRE(grid != nullptr);
        CHECK((*grid)["state"] == "unsupported");
        CHECK((*grid)["message"].get<std::string>().find("RGBA16F") != std::string::npos);
    }
}
