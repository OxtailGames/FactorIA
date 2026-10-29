// fa/scene/bounds.h: the footprint of an entity's 2D visuals, shared by entity.bounds() and the editor's picking.
#include <doctest.h>

#include <cmath>

#include "fa/scene/bounds.h"
#include "fa/scene/serialize.h"
#include "fa/scene/world.h"

using namespace fa;

namespace {

struct Fixture {
    World w;
    Entity make(const char* id, Vec3 pos = {0, 0, 0}, float rotationZ = 0, float scale = 1) {
        Entity e = w.create(id, id);
        Transform* t = w.get<Transform>(e);
        t->position = pos;
        t->rotation = {0, 0, rotationZ};
        t->scale = {scale, scale, 1};
        return e;
    }
    Shape2D& shape(Entity e, ShapeType type, Vec2 size, Vec2 pivot = {0.5f, 0.5f}) {
        Shape2D& s = w.add<Shape2D>(e);
        s.shape = type;
        s.size = size;
        s.pivot = pivot;
        return s;
    }
};

void check_rect(const std::optional<Rect>& r, float x, float y, float w, float h) {
    REQUIRE(r.has_value());
    CHECK(r->x == doctest::Approx(x).epsilon(1e-4));
    CHECK(r->y == doctest::Approx(y).epsilon(1e-4));
    CHECK(r->w == doctest::Approx(w).epsilon(1e-4));
    CHECK(r->h == doctest::Approx(h).epsilon(1e-4));
}

Rect box_of(const VisualFootprint& v) {
    float x0 = v.box[0].x, y0 = v.box[0].y, x1 = x0, y1 = y0;
    for (const Vec2& p : v.box) {
        x0 = std::min(x0, p.x);
        y0 = std::min(y0, p.y);
        x1 = std::max(x1, p.x);
        y1 = std::max(y1, p.y);
    }
    return Rect{x0, y0, x1 - x0, y1 - y0};
}

}  // namespace

TEST_CASE("bounds: a triangle with the centroid pivot [0.5, 0.3333] keeps the whole size box around the origin") {
    Fixture f;
    Entity e = f.make("tri", {100, 50, 0});
    f.shape(e, ShapeType::Triangle, {30, 60}, {0.5f, 0.3333f});
    const auto parts = visual_footprints(f.w, e);
    REQUIRE(parts.size() == 1);
    CHECK(std::string(parts[0].component) == "Shape2D");
    const Rect local = box_of(parts[0]);
    CHECK(local.x == doctest::Approx(-15.0f));
    CHECK(local.y == doctest::Approx(-0.3333f * 60.0f));
    CHECK(local.w == doctest::Approx(30.0f));
    CHECK(local.h == doctest::Approx(60.0f));
    check_rect(entity_world_rect(f.w, e), 85.0f, 50.0f - 0.3333f * 60.0f, 30.0f, 60.0f);
}

TEST_CASE("bounds: a rotated triangle has an oriented box and a bigger world rectangle") {
    Fixture f;
    Entity e = f.make("tri", {0, 0, 0}, 90.0f);
    f.shape(e, ShapeType::Triangle, {40, 20}, {0.5f, 0.3333f});
    // Local box x -20..20, y -6.666..13.334; turned by 90 degrees (x, y) -> (-y, x): x -13.334..6.666, y -20..20.
    check_rect(entity_world_rect(f.w, e), -13.334f, -20.0f, 20.0f, 40.0f);
    // The oriented box (what the editor outlines and hit-tests) is the local box: points are tested in local space.
    const auto parts = visual_footprints(f.w, e);
    REQUIRE(parts.size() == 1);
    CHECK(point_in_quad({0, 0}, parts[0].box));
    CHECK(point_in_quad({19.9f, 12.0f}, parts[0].box));
    CHECK_FALSE(point_in_quad({0, 14.0f}, parts[0].box));
    CHECK_FALSE(point_in_quad({21.0f, 0}, parts[0].box));
}

TEST_CASE("bounds: a diamond fills its size box, but its rectangle follows the tips when it is turned") {
    Fixture f;
    Entity e = f.make("dia");
    f.shape(e, ShapeType::Diamond, {20, 20});
    const auto parts = visual_footprints(f.w, e);
    REQUIRE(parts.size() == 1);
    const Rect box = box_of(parts[0]);
    CHECK(box.x == doctest::Approx(-10.0f));
    CHECK(box.w == doctest::Approx(20.0f));
    // The hull is the four tips, on the middles of the box edges.
    CHECK(parts[0].hull[0].x == doctest::Approx(0.0f));
    CHECK(parts[0].hull[0].y == doctest::Approx(-10.0f));
    CHECK(parts[0].hull[1].x == doctest::Approx(10.0f));
    check_rect(entity_world_rect(f.w, e), -10, -10, 20, 20);

    Entity r = f.make("diaRot", {0, 0, 0}, 45.0f);
    f.shape(r, ShapeType::Diamond, {20, 20});
    check_rect(entity_world_rect(f.w, r), -7.0710678f, -7.0710678f, 14.1421356f, 14.1421356f);
    // The oriented box (what the editor outlines) is still the 20 x 20 square, turned: its corner reaches 14.14 from the origin.
    const auto rp = visual_footprints(f.w, r);
    REQUIRE(rp.size() == 1);
    CHECK(rp[0].box[0].x == doctest::Approx(-10.0f));
}

TEST_CASE("bounds: Tilemap in rows form, flat form and empty") {
    Fixture f;
    Entity rows = f.make("rows", {100, 300, 0});
    Tilemap& t = f.w.add<Tilemap>(rows);
    t.tileSize = {32, 16};
    t.tiles = Json::parse("[[0,0,-1,0],[-1,1,1,1],[2,2,2,2]]");
    // Top-left corner at the entity, local y down: x 100..228, y 252..300.
    check_rect(entity_world_rect(f.w, rows), 100, 252, 128, 48);
    const auto parts = visual_footprints(f.w, rows);
    REQUIRE(parts.size() == 1);
    CHECK(std::string(parts[0].component) == "Tilemap");
    CHECK(parts[0].layer == t.layer);

    Entity flat = f.make("flat", {-50, 20, 0});
    Tilemap& tf = f.w.add<Tilemap>(flat);
    tf.tileSize = {10, 8};
    tf.width = 5;
    tf.height = 2;
    tf.tiles = Json::parse("[0,0,0,0,0,1,1,1,1,1]");
    check_rect(entity_world_rect(f.w, flat), -50, 4, 50, 16);

    Entity empty = f.make("empty");
    f.w.add<Tilemap>(empty).tileSize = {16, 16};
    CHECK_FALSE(entity_world_rect(f.w, empty).has_value());
    CHECK(visual_footprints(f.w, empty).empty());
}

TEST_CASE("bounds: Text uses the measurer it is given, the pivot places it and an empty text has none") {
    Fixture f;
    Entity e = f.make("text", {5, 5, 0});
    Text& t = f.w.add<Text>(e);
    t.text = "abcd";
    t.fontSize = 10;
    // No renderer: 0.6 em per character, 1.2 em per line; the default pivot (0, 1) is the top-left corner.
    check_rect(entity_world_rect(f.w, e), 5, -7, 24, 12);
    VisualMeasure wide;
    wide.textSize = [](const Text&) { return Vec2{100, 20}; };
    check_rect(entity_world_rect(f.w, e, wide), 5, -15, 100, 20);
    t.pivot = {0.5f, 0.5f};
    check_rect(entity_world_rect(f.w, e, wide), -45, -5, 100, 20);
    t.text.clear();
    CHECK_FALSE(entity_world_rect(f.w, e).has_value());
    CHECK(approx_text_size("abcdefgh", 10, 30).y > 12.0f);  // wraps
}

TEST_CASE("bounds: a Text with maxWidth is as wide as the box it is drawn in unless it is left-aligned") {
    Fixture f;
    Entity e = f.make("note", {0, 0, 0});
    Text& t = f.w.add<Text>(e);
    t.text = "short";
    t.fontSize = 10;
    t.maxWidth = 200;
    VisualMeasure tight;
    tight.textSize = [](const Text&) { return Vec2{30, 12}; };  // the widest line
    check_rect(entity_world_rect(f.w, e, tight), 0, -12, 30, 12);  // left: the box is the text
    t.align = Align::Right;
    check_rect(entity_world_rect(f.w, e, tight), 0, -12, 200, 12);  // the renderer aligns inside the maxWidth box
    t.align = Align::Start;
    check_rect(entity_world_rect(f.w, e, tight), 0, -12, 30, 12);  // start is left in a left-to-right language...
    f.w.set_rtl(true);
    check_rect(entity_world_rect(f.w, e, tight), 0, -12, 200, 12);  // ...and right in a right-to-left one
}

TEST_CASE("bounds: Sprite size, region, texture size and animator frames") {
    Fixture f;
    VisualMeasure m;
    m.textureSize = [](const std::string&) { return Vec2{40, 20}; };
    Entity a = f.make("tex");
    Sprite& s = f.w.add<Sprite>(a);
    s.texture = "assets/tex.png";
    s.pivot = {0, 0};
    check_rect(entity_world_rect(f.w, a, m), 0, 0, 40, 20);
    s.size = {100, 0};
    check_rect(entity_world_rect(f.w, a, m), 0, 0, 100, 20);
    s.size = {0, 0};
    s.region = Rect{0, 0, 10, 5};
    check_rect(entity_world_rect(f.w, a, m), 0, 0, 10, 5);
    s.region = Rect{};
    SpriteAnimator& an = f.w.add<SpriteAnimator>(a);
    an.columns = 4;
    an.rows = 2;
    check_rect(entity_world_rect(f.w, a, m), 0, 0, 10, 10);
    // No texture: a 32 x 32 colour quad. A measurer-less call treats every texture as 32 x 32.
    Entity q = f.make("quad");
    f.w.add<Sprite>(q).pivot = {0, 0};
    check_rect(entity_world_rect(f.w, q, m), 0, 0, 32, 32);
    Entity n = f.make("nomeasure");
    Sprite& sn = f.w.add<Sprite>(n);
    sn.texture = "assets/x.png";
    sn.pivot = {0, 0};
    check_rect(entity_world_rect(f.w, n), 0, 0, 32, 32);
}

TEST_CASE("bounds: lines, circles, unions and screen space") {
    Fixture f;
    Entity line = f.make("line");
    f.shape(line, ShapeType::Line, {30, 40}).thickness = 2;
    check_rect(entity_world_rect(f.w, line), -0.8f, -0.6f, 31.6f, 41.2f);
    // The line's box is the stroke, not the axis-aligned rectangle: a point near the empty corner of the rectangle is outside.
    const auto lp = visual_footprints(f.w, line);
    REQUIRE(lp.size() == 1);
    CHECK(point_in_quad({15, 20}, lp[0].box));
    CHECK_FALSE(point_in_quad({28, 2}, lp[0].box));

    Entity zero = f.make("zero");
    f.shape(zero, ShapeType::Line, {0, 0});
    CHECK_FALSE(entity_world_rect(f.w, zero).has_value());

    Entity circle = f.make("circle", {5, 5, 0});
    f.shape(circle, ShapeType::Circle, {20, 99}, {0, 0});
    check_rect(entity_world_rect(f.w, circle), 5, 5, 20, 20);

    Entity both = f.make("both");
    Sprite& sp = f.w.add<Sprite>(both);
    sp.size = {10, 10};
    sp.pivot = {0, 0};
    f.shape(both, ShapeType::Rectangle, {10, 10}, {1, 1});
    check_rect(entity_world_rect(f.w, both), -10, -10, 20, 20);
    CHECK(visual_footprints(f.w, both).size() == 2);

    // Screen-space visuals are listed on request and never counted by the world rectangle.
    Entity hud = f.make("hud", {24, 16, 0});
    Shape2D& panel = f.shape(hud, ShapeType::Rectangle, {100, 40});
    panel.space = RenderSpace::Screen;
    CHECK_FALSE(entity_world_rect(f.w, hud).has_value());
    CHECK(visual_footprints(f.w, hud, {}, false).empty());
    const auto hp = visual_footprints(f.w, hud);
    REQUIRE(hp.size() == 1);
    CHECK(hp[0].space == RenderSpace::Screen);
}

TEST_CASE("bounds: point_in_quad handles either winding, borders and empty quads") {
    const std::array<Vec2, 4> ccw = {Vec2{0, 0}, Vec2{10, 0}, Vec2{10, 5}, Vec2{0, 5}};
    const std::array<Vec2, 4> cw = {Vec2{0, 0}, Vec2{0, 5}, Vec2{10, 5}, Vec2{10, 0}};
    for (const auto& q : {ccw, cw}) {
        CHECK(point_in_quad({5, 2}, q));
        CHECK(point_in_quad({0, 0}, q));
        CHECK(point_in_quad({10, 5}, q));
        CHECK_FALSE(point_in_quad({10.1f, 2}, q));
        CHECK_FALSE(point_in_quad({5, -0.1f}, q));
    }
    const std::array<Vec2, 4> flat = {Vec2{0, 0}, Vec2{10, 0}, Vec2{10, 0}, Vec2{0, 0}};
    CHECK_FALSE(point_in_quad({5, 0}, flat));
}

TEST_CASE("bounds: a polygon or star is measured by its size box, placed by the pivot") {
    Fixture f;
    Entity hex = f.make("hex", {10, 20, 0});
    f.shape(hex, ShapeType::Polygon, {40, 30});
    Entity star = f.make("star", {-50, 0, 0});
    f.shape(star, ShapeType::Star, {60, 60}, {0, 0});
    for (Entity e : {hex, star}) {
        const auto parts = visual_footprints(f.w, e);
        REQUIRE(parts.size() == 1);
        CHECK(std::string(parts[0].component) == "Shape2D");
    }
    check_rect(entity_world_rect(f.w, hex), -10.0f, 5.0f, 40.0f, 30.0f);
    check_rect(entity_world_rect(f.w, star), -50.0f, 0.0f, 60.0f, 60.0f);
}

TEST_CASE("bounds: Sprite.skew shears the box about the pivot; the world rectangle grows with it") {
    Fixture f;
    Entity e = f.make("sk");
    Sprite& s = f.w.add<Sprite>(e);
    s.size = {20, 40};
    check_rect(entity_world_rect(f.w, e), -10, -20, 20, 40);
    s.skew = {45.0f, 0.0f};  // the top edge (y = +20) moves +20 right, the bottom edge 20 left: tan(45) = 1
    check_rect(entity_world_rect(f.w, e), -30, -20, 60, 40);
    s.skew = {0.0f, 45.0f};  // the right edge (x = +10) moves +10 up, the left edge 10 down
    check_rect(entity_world_rect(f.w, e), -10, -30, 20, 60);
    s.skew = {500.0f, 0.0f};  // clamped to 80 degrees: tan(80) = 5.67, not tan(500)
    const auto parts = visual_footprints(f.w, e);
    REQUIRE(parts.size() == 1);
    CHECK(box_of(parts[0]).w == doctest::Approx(20.0f + 2.0f * 20.0f * std::tan(80.0f * 3.14159265f / 180.0f)).epsilon(1e-3));
    CHECK(sprite_shear_point({0, 10}, {45.0f, 0.0f}).x == doctest::Approx(10.0f));
    CHECK(sprite_shear_point({10, 0}, {0.0f, 45.0f}).y == doctest::Approx(10.0f));
    const Mat4 m = sprite_shear_matrix({45.0f, 0.0f});
    CHECK(m.transform_point({0, 10, 0}).x == doctest::Approx(10.0f));
}

TEST_CASE("bounds: a deformable Sprite is bounded by its moved vertices") {
    Fixture f;
    Entity e = f.make("mesh");
    Sprite& s = f.w.add<Sprite>(e);
    s.size = {20, 20};
    s.meshColumns = 2;
    s.meshRows = 1;
    check_rect(entity_world_rect(f.w, e), -10, -10, 20, 20);  // no offsets: the plain box
    // 3 x 2 vertices, row by row from the TOP row: the top-middle vertex (index 1) moves 5 up and 3 right.
    s.vertexOffsets = Json::array({0, 0, 3, 5, 0, 0, 0, 0, 0, 0, 0, 0});
    check_rect(entity_world_rect(f.w, e), -10, -10, 20, 25);
    s.vertexOffsets = Json::array({0, 0, 0, 0, 0, 0, -4, 0, 0, 0, 0, 0});  // the bottom-left vertex moves 4 left
    check_rect(entity_world_rect(f.w, e), -14, -10, 24, 20);
    s.vertexOffsets = Json::array({0, 0, 0, 0});  // shorter than the grid: the rest stays in place, no crash
    check_rect(entity_world_rect(f.w, e), -10, -10, 20, 20);

    int cols = 0, rows = 0;
    CHECK(sprite_mesh_grid(s, cols, rows));
    CHECK(cols == 2);  CHECK(rows == 1);
    s.meshColumns = 200;  // a side above 128 is clamped
    s.meshRows = 1;
    CHECK(sprite_mesh_grid(s, cols, rows));
    CHECK(cols == kMaxSpriteMeshSide);
    s.meshColumns = 100;
    s.meshRows = 100;  // 10000 cells: more than the budget, a plain quad
    CHECK_FALSE(sprite_mesh_grid(s, cols, rows));
    s.meshColumns = 0;
    CHECK_FALSE(sprite_mesh_grid(s, cols, rows));
    // Offsets that are not numbers count as 0; extra numbers are ignored.
    s.meshColumns = 1;
    s.meshRows = 1;
    s.vertexOffsets = Json::array({"x", 2, 1, 1, 1, 1, 1, 1, 9, 9, 9});
    const std::vector<float> o = sprite_vertex_offsets(s, 1, 1);
    REQUIRE(o.size() == 8);
    CHECK(o[0] == 0.0f);
    CHECK(o[1] == 2.0f);
}

TEST_CASE("Tint, gradient fields and the new Sprite fields are reflected and round trip as JSON") {
    Fixture f;
    Entity e = f.make("refl");
    f.w.add<Tint>(e).color = Color{1, 0.5f, 0.25f, 0.5f};
    Sprite& sp = f.w.add<Sprite>(e);
    sp.skew = {10, -5};
    sp.meshColumns = 3;
    sp.meshRows = 2;
    sp.vertexOffsets = Json::array({1, 2, 3});
    Shape2D& sh = f.w.add<Shape2D>(e);
    sh.gradientEase = GradientEase::CubicInOut;
    sh.gradientStops = Json::array({Json::array({0, "#ff0000"}), Json::array({1, Json::array({0, 0, 1, 1})})});
    const Json jt = component_to_json(f.w, e, World::type_of<Tint>());
    CHECK(jt["color"].is_array());
    const Json js = component_to_json(f.w, e, World::type_of<Sprite>());
    CHECK(js["skew"][0].get<float>() == doctest::Approx(10.0f));
    CHECK(js["meshColumns"] == 3);
    CHECK(js["vertexOffsets"].size() == 3);
    const Json jh = component_to_json(f.w, e, World::type_of<Shape2D>());
    CHECK(jh["gradientEase"] == "cubicInOut");
    CHECK(jh["gradientStops"].size() == 2);
    // Defaults are not written, so scenes that do not use the features do not change.
    Fixture g;
    Entity d = g.make("plain");
    g.w.add<Sprite>(d);
    g.w.add<Shape2D>(d);
    const Json jd = component_to_json(g.w, d, World::type_of<Sprite>());
    CHECK_FALSE(jd.contains("skew"));
    CHECK_FALSE(jd.contains("meshColumns"));
    CHECK_FALSE(jd.contains("vertexOffsets"));
    const Json jds = component_to_json(g.w, d, World::type_of<Shape2D>());
    CHECK_FALSE(jds.contains("gradientStops"));
    CHECK_FALSE(jds.contains("gradientEase"));
}

TEST_CASE("gradient_ease_apply: endpoints are exact, the curves bend the way their names say") {
    for (int i = 0; i <= int(GradientEase::CircInOut); ++i) {
        const auto ease = GradientEase(i);
        INFO("ease " << i);
        CHECK(gradient_ease_apply(ease, 0.0f) == doctest::Approx(0.0f).epsilon(1e-5));
        CHECK(gradient_ease_apply(ease, 1.0f) == doctest::Approx(1.0f).epsilon(1e-5));
        CHECK(gradient_ease_apply(ease, -3.0f) == doctest::Approx(0.0f).epsilon(1e-5));  // clamped
        CHECK(gradient_ease_apply(ease, 4.0f) == doctest::Approx(1.0f).epsilon(1e-5));
    }
    CHECK(gradient_ease_apply(GradientEase::Linear, 0.3f) == doctest::Approx(0.3f));
    CHECK(gradient_ease_apply(GradientEase::QuadIn, 0.5f) == doctest::Approx(0.25f));
    CHECK(gradient_ease_apply(GradientEase::QuadOut, 0.5f) == doctest::Approx(0.75f));
    CHECK(gradient_ease_apply(GradientEase::CubicIn, 0.5f) == doctest::Approx(0.125f));
    CHECK(gradient_ease_apply(GradientEase::Smoothstep, 0.5f) == doctest::Approx(0.5f));
    CHECK(gradient_ease_apply(GradientEase::Smoothstep, 0.25f) == doctest::Approx(0.15625f));
    for (GradientEase ease : {GradientEase::QuadInOut, GradientEase::CubicInOut, GradientEase::SineInOut, GradientEase::CircInOut,
                              GradientEase::ExpoInOut})
        CHECK(gradient_ease_apply(ease, 0.5f) == doctest::Approx(0.5f).epsilon(1e-4));
    CHECK(gradient_ease_apply(GradientEase::SineIn, 0.5f) < 0.5f);
    CHECK(gradient_ease_apply(GradientEase::ExpoOut, 0.5f) > 0.5f);
    float prev = 0.0f;
    for (int i = 1; i <= 20; ++i) {  // monotone
        const float v = gradient_ease_apply(GradientEase::QuintInOut, float(i) / 20.0f);
        CHECK(v >= prev);
        prev = v;
    }
}
