// The brush the viewport tools share (brush.h): the stamps of a stroke, the cursor ring and the ray that finds the ground. Pure code: no
// window, no renderer.
#include <cmath>

#include "brush.h"
#include "fa/scene/foliage.h"
#include "foliage_ui.h"
#include "terrain_ui.h"
#include "doctest.h"

using namespace fa;
using namespace fa::editor;

namespace {
float dist(Vec2 a, Vec2 b) { return std::hypot(a.x - b.x, a.y - b.y); }
}  // namespace

TEST_CASE("brush: settings stay in range and the keys step them") {
    BrushSettings b;
    b.radius = -3;
    b.strength = 7;
    b.falloff = std::nanf("");
    brush_clamp(b, 100.0f);
    CHECK(b.radius == doctest::Approx(kBrushMinRadius));
    CHECK(b.strength == 1.0f);
    CHECK(b.falloff == 1.0f);
    b.radius = 10;
    brush_step_radius(b, 1, 100.0f);
    CHECK(b.radius == doctest::Approx(12.5f));
    brush_step_radius(b, -1, 100.0f);
    CHECK(b.radius == doctest::Approx(10.0f));
    brush_step_radius(b, 50, 100.0f);
    CHECK(b.radius == 100.0f);
    brush_step_radius(b, -200, 100.0f);
    CHECK(b.radius == doctest::Approx(kBrushMinRadius));
    b.strength = 0.5f;
    brush_step_strength(b, 1);
    CHECK(b.strength == doctest::Approx(0.55f));
    brush_step_strength(b, -100);
    CHECK(b.strength == 0.0f);
    b.radius = 20;
    b.falloff = 0.25f;
    CHECK(brush_inner_radius(b) == doctest::Approx(15.0f));
    CHECK(brush_spacing(20.0f) == doctest::Approx(5.0f));
}

TEST_CASE("brush: a stroke stamps every radius/4 along the path, however the frames fall") {
    // One long move, and the same line in many small moves, give the same stamps.
    BrushStroke one, many;
    one.begin({0, 0}, 8.0f);  // spacing 2
    many.begin({0, 0}, 8.0f);
    CHECK(one.points().size() == 1);
    CHECK(one.add({10, 0}) == 5);  // stamps at 2, 4, 6, 8, 10
    int sum = 0;
    for (int i = 1; i <= 80; ++i) sum += many.add({0.125f * float(i), 0});  // 0.125 is exact in binary
    CHECK(sum == 5);
    REQUIRE(one.points().size() == 6);
    REQUIRE(many.points().size() == 6);
    for (std::size_t i = 0; i < 6; ++i) {
        CHECK(one.points()[i].x == doctest::Approx(2.0f * float(i)).epsilon(1e-4));
        CHECK(dist(one.points()[i], many.points()[i]) < 1e-3f);
    }
    // A move shorter than the spacing adds nothing, and the rest is kept for the next one.
    BrushStroke s;
    s.begin({0, 0}, 8.0f);
    CHECK(s.add({1.9f, 0}) == 0);
    CHECK(s.add({2.1f, 0}) == 1);
    // A bend: stamps follow the mouse positions, spacing apart from the last STAMP (a chord), never twice at one place.
    BrushStroke bend;
    bend.begin({0, 0}, 4.0f);  // spacing 1
    bend.add({3, 0});
    bend.add({3, 3});
    CHECK(bend.points().size() == 7);
    for (std::size_t i = 1; i < bend.points().size(); ++i) CHECK(dist(bend.points()[i - 1], bend.points()[i]) > 0.99f);
}

TEST_CASE("brush: points are taken in order, in chunks, once") {
    BrushStroke s;
    CHECK(s.add({5, 5}) == 0);  // outside a stroke nothing is collected
    s.begin({0, 0}, 4.0f);
    CHECK(s.pending() == 1);
    s.add({10, 0});
    CHECK(s.pending() == 11);
    std::vector<Vec2> out;
    CHECK(s.take_pending(out, 4) == 4);
    CHECK(s.take_pending(out, 100) == 7);
    CHECK(s.take_pending(out, 100) == 0);
    REQUIRE(out.size() == 11);
    CHECK(out[0].x == 0.0f);
    CHECK(out[10].x == doctest::Approx(10.0f));
    CHECK(s.active());
    s.end();
    CHECK(!s.active());
    CHECK(s.points().empty());
    CHECK(s.add({20, 0}) == 0);
}

TEST_CASE("brush: a stroke has a ceiling and ignores a mouse that is not a number") {
    BrushStroke s;
    s.begin({0, 0}, 4.0f);
    CHECK(s.add({std::nanf(""), 0}) == 0);
    CHECK(s.add({std::numeric_limits<float>::infinity(), 0}) == 0);
    s.add({1e6f, 0});
    CHECK(s.full());
    CHECK(s.points().size() == kBrushMaxStrokePoints);
    CHECK(s.add({2e6f, 0}) == 0);
}

TEST_CASE("brush: the ring has the radius, goes round once and starts on +x") {
    const std::vector<Vec2> ring = brush_ring({10, -5}, 3.0f, 32);
    REQUIRE(ring.size() == 32);
    CHECK(ring[0].x == doctest::Approx(13.0f));
    CHECK(ring[0].y == doctest::Approx(-5.0f));
    CHECK(ring[8].x == doctest::Approx(10.0f).epsilon(1e-4));
    CHECK(ring[8].y == doctest::Approx(-2.0f));
    for (const Vec2& p : ring) CHECK(dist(p, {10, -5}) == doctest::Approx(3.0f));
    CHECK(brush_ring({0, 0}, 1.0f, 1).size() == 8);  // never fewer than 8 points
}

TEST_CASE("brush: a ray finds the ground, from above only") {
    // A slope: y = 0.5 x, only for x in [0, 100].
    const BrushSurface slope = [](float x, float, float& y) {
        if (x < 0.0f || x > 100.0f) return false;
        y = 0.5f * x;
        return true;
    };
    Vec3 hit;
    // Straight down at x = 40: the ground is at y = 20.
    CHECK(brush_ray_ground({40, 100, 7}, {0, -1, 0}, 0.0f, 200.0f, 400, slope, hit));
    CHECK(hit.x == doctest::Approx(40.0f));
    CHECK(hit.y == doctest::Approx(20.0f));
    CHECK(hit.z == doctest::Approx(7.0f));
    // A slanted ray from the left: meets the slope where 100 - t = 0.5 * (t), t = 66.67 (x = 66.67 / sqrt2 ... use a plain line).
    CHECK(brush_ray_ground({0, 60, 0}, {1, -0.5f, 0}, 0.0f, 150.0f, 300, slope, hit));
    CHECK(hit.y == doctest::Approx(0.5f * hit.x).epsilon(1e-3));
    CHECK(hit.x == doctest::Approx(60.0f).epsilon(1e-3));  // 60 - 0.5 x = 0.5 x
    // Where there is no ground the ray does not hit.
    CHECK(!brush_ray_ground({-50, 100, 0}, {0, -1, 0}, 0.0f, 200.0f, 400, slope, hit));
    // A ray that starts under the ground does not "hit" it from below.
    CHECK(!brush_ray_ground({40, -10, 0}, {0, -1, 0}, 0.0f, 200.0f, 400, slope, hit));
    // A ray that goes up never crosses it.
    CHECK(!brush_ray_ground({40, 100, 0}, {0, 1, 0}, 0.0f, 200.0f, 400, slope, hit));
    // The count of steps is what decides, not the length: a ray that ends above the ground does not hit.
    CHECK(!brush_ray_ground({40, 100, 0}, {0, -1, 0}, 0.0f, 50.0f, 100, slope, hit));
}

TEST_CASE("brush: a ray is cut to the box that holds the ground") {
    float t0 = 0, t1 = 0;
    CHECK(brush_ray_box({0, 10, 0}, {0, -1, 0}, {-5, 0, -5}, {5, 4, 5}, t0, t1));
    CHECK(t0 == doctest::Approx(6.0f));
    CHECK(t1 == doctest::Approx(10.0f));
    CHECK(!brush_ray_box({20, 10, 0}, {0, -1, 0}, {-5, 0, -5}, {5, 4, 5}, t0, t1));
    CHECK(!brush_ray_box({0, 10, 0}, {1, 0, 0}, {-5, 0, -5}, {5, 4, 5}, t0, t1));  // parallel and outside
    // Inside the box the ray starts at 0.
    CHECK(brush_ray_box({0, 2, 0}, {1, 0, 0}, {-5, 0, -5}, {5, 4, 5}, t0, t1));
    CHECK(t0 == 0.0f);
    CHECK(t1 == doctest::Approx(5.0f));
}

TEST_CASE("terrain tool: a stroke piece becomes the arguments of one command") {
    TerrainUi ui;
    ui.strokeBrush = BrushSettings{6.0f, 0.75f, 0.5f};
    ui.strokeAmount = 0.5f;
    ui.strokeHeight = 12.0f;
    const std::vector<Vec2> pts = {{1.0f, 2.0f}, {2.5f, 2.0f}};

    ui.strokeMode = TerrainMode::Sculpt;
    ui.strokeSculpt = SculptTool::Raise;
    TerrainCall c = terrain_stroke_call(ui, "ground", pts, false);
    CHECK(c.command == "terrain.sculpt");
    CHECK(c.args["entity"] == "ground");
    CHECK(c.args["tool"] == "raise");
    CHECK(c.args["points"].size() == 2);
    CHECK(c.args["radius"].get<double>() == doctest::Approx(6.0));
    CHECK(c.args["falloff"].get<double>() == doctest::Approx(0.5));
    CHECK(c.args["amount"].get<double>() == doctest::Approx(0.5));
    CHECK_FALSE(c.args.contains("continueStroke"));  // the first piece starts the undo step

    c = terrain_stroke_call(ui, "ground", pts, true);
    CHECK(c.args["continueStroke"] == true);  // the next ones join it

    ui.strokeInvert = true;  // Ctrl held: raise lowers
    CHECK(terrain_stroke_call(ui, "ground", pts, false).args["tool"] == "lower");
    ui.strokeInvert = false;

    ui.strokeSculpt = SculptTool::Flatten;
    c = terrain_stroke_call(ui, "ground", pts, false);
    CHECK(c.args["height"].get<double>() == doctest::Approx(12.0));  // one height for every piece of the stroke
    CHECK_FALSE(c.args.contains("amount"));

    ui.strokeMode = TerrainMode::Paint;
    ui.strokeLayer = 3;
    c = terrain_stroke_call(ui, "ground", pts, false);
    CHECK(c.command == "terrain.paint");
    CHECK(c.args["layer"] == 3);

    ui.strokeMode = TerrainMode::Holes;
    ui.strokeCut = true;
    CHECK(terrain_stroke_call(ui, "ground", pts, false).args["mode"] == "cut");
    ui.strokeInvert = true;
    CHECK(terrain_stroke_call(ui, "ground", pts, false).args["mode"] == "fill");
}

TEST_CASE("terrain tool: the largest radius keeps a brush under the commands' 1024 samples") {
    // 512 m, 512 cells (1 m per sample): half the terrain is the limit.
    CHECK(terrain_max_radius({512, 512}, 512) == doctest::Approx(256.0f));
    // 4096 m with 4096 cells: 900 samples of 1 m.
    CHECK(terrain_max_radius({4096, 4096}, 4096) == doctest::Approx(900.0f));
    CHECK(terrain_max_radius({64, 64}, 64) == doctest::Approx(32.0f));
    CHECK(terrain_max_radius({64, 64}, 0) >= kBrushMinRadius);
}

TEST_CASE("terrain tool: the radius limit is measured in the plane the brush edits") {
    // A 4096 m terrain with 1024 cells: 4 m per height sample, but a splat map of 4096 texels is 1 m per texel.
    CHECK(terrain_plane_side(TerrainMode::Sculpt, 1024, 4096) == 1024);
    CHECK(terrain_plane_side(TerrainMode::Holes, 1024, 4096) == 1024);
    CHECK(terrain_plane_side(TerrainMode::Paint, 1024, 4096) == 4096);
    // no splat map yet: terrain.paint makes one min(cells, 1024) wide
    CHECK(terrain_plane_side(TerrainMode::Paint, 4096, 0) == 1024);
    CHECK(terrain_plane_side(TerrainMode::Paint, 256, 0) == 256);
    // 900 texels of the plane, so a finer plane allows a smaller radius in metres
    CHECK(terrain_max_radius({4096, 4096}, terrain_plane_side(TerrainMode::Sculpt, 1024, 4096)) >
          terrain_max_radius({4096, 4096}, terrain_plane_side(TerrainMode::Paint, 1024, 4096)));
    CHECK(terrain_max_radius({4096, 4096}, terrain_plane_side(TerrainMode::Paint, 1024, 4096)) ==
          doctest::Approx(900.0f));
}

TEST_CASE("foliage tool: a stroke piece becomes the arguments of one foliage.paint call") {
    FoliageUi ui;
    ui.strokeBrush = BrushSettings{4.0f, 0.5f, 1.0f};
    ui.strokeMode = FoliageMode::Add;
    ui.strokeRuleDensity = true;
    const std::vector<Vec2> pts = {{1.123456f, 2.0f}, {2.5f, 2.0f}};

    FoliageCall c = foliage_stroke_call(ui, "forest", pts, false);
    CHECK(c.command == "foliage.paint");
    CHECK(c.args["entity"] == "forest");
    CHECK(c.args["mode"] == "add");
    CHECK(c.args["points"].size() == 2);
    CHECK(c.args["points"][0][0].get<double>() == doctest::Approx(1.1235));  // rounded to 4 decimals
    CHECK(c.args["radius"].get<double>() == doctest::Approx(4.0));
    CHECK_FALSE(c.args.contains("density"));  // the rule's density
    CHECK_FALSE(c.args.contains("mesh"));
    CHECK_FALSE(c.args.contains("continueStroke"));  // the first piece starts the undo step
    CHECK(foliage_stroke_call(ui, "forest", pts, true).args["continueStroke"] == true);

    ui.strokeRuleDensity = false;
    ui.strokeDensity = 0.75f;
    ui.strokeMesh = "assets/models/pine.glb";
    c = foliage_stroke_call(ui, "forest", pts, false);
    CHECK(c.args["density"].get<double>() == doctest::Approx(0.75));
    CHECK(c.args["mesh"] == "assets/models/pine.glb");

    ui.strokeInvert = true;  // Ctrl held: add erases, and an erase has no density
    c = foliage_stroke_call(ui, "forest", pts, false);
    CHECK(c.args["mode"] == "remove");
    CHECK_FALSE(c.args.contains("density"));
    ui.strokeMode = FoliageMode::Remove;  // remove with Ctrl adds
    CHECK(foliage_stroke_call(ui, "forest", pts, false).args["mode"] == "add");
}

TEST_CASE("foliage tool: pieces are rate-limited by what the last call cost") {
    CHECK(foliage_piece_interval(0.0) == doctest::Approx(kFoliageMinPieceSeconds));
    CHECK(foliage_piece_interval(0.05) == doctest::Approx(kFoliageMinPieceSeconds));
    CHECK(foliage_piece_interval(0.5) == doctest::Approx(1.0));  // twice the cost
    CHECK(foliage_piece_interval(100.0) == doctest::Approx(kFoliageMaxPieceSeconds));
    CHECK(foliage_piece_interval(-1.0) == doctest::Approx(kFoliageMinPieceSeconds));
    CHECK(foliage_piece_interval(std::nan("")) == doctest::Approx(kFoliageMinPieceSeconds));
}

TEST_CASE("brush: a stroke can use bigger stamps than the default") {
    BrushStroke fine, coarse;
    fine.begin({0, 0}, 4.0f);
    coarse.begin({0, 0}, 4.0f, kFoliageStampsPerRadius);
    CHECK(fine.spacing() == doctest::Approx(1.0f));
    CHECK(coarse.spacing() == doctest::Approx(2.0f));
    fine.add({8, 0});
    coarse.add({8, 0});
    CHECK(fine.points().size() == 9);
    CHECK(coarse.points().size() == 5);
    CHECK(brush_spacing(4.0f, 2.0f) == doctest::Approx(2.0f));
    // A whole stroke of pieces: kMaxFoliagePaintPoints is what one call takes.
    CHECK(kMaxFoliagePaintPoints <= kBrushMaxStrokePoints);
}
