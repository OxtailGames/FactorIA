// Picking and selection outline: the editor uses the engine's own footprint of 2D visuals (fa/scene/bounds.h, the code behind
// `entity.bounds()` in scripts), so what the editor outlines is what a script measures. GPU-free: only a World is needed.
#include <algorithm>
#include <array>

#include "doctest.h"
#include "editor_internal.h"

using namespace fa;
using namespace fa::editor;

namespace {

Entity make_entity(World& w, const char* id, Vec3 pos = {0, 0, 0}, float rotationZ = 0, float scale = 1) {
    Entity e = w.create(id, id);
    Transform* t = w.get<Transform>(e);
    t->position = pos;
    t->rotation = {0, 0, rotationZ};
    t->scale = {scale, scale, 1};
    return e;
}

Shape2D& add_shape(World& w, Entity e, ShapeType type, Vec2 size, Vec2 pivot = {0.5f, 0.5f}) {
    Shape2D& s = w.add<Shape2D>(e);
    s.shape = type;
    s.size = size;
    s.pivot = pivot;
    return s;
}

// Axis-aligned rectangle around 4 points.
Rect around(const std::array<Vec2, 4>& pts) {
    float x0 = pts[0].x, y0 = pts[0].y, x1 = x0, y1 = y0;
    for (const Vec2& p : pts) {
        x0 = std::min(x0, p.x);
        y0 = std::min(y0, p.y);
        x1 = std::max(x1, p.x);
        y1 = std::max(y1, p.y);
    }
    return Rect{x0, y0, x1 - x0, y1 - y0};
}

void check_same_rect(const Rect& a, const Rect& b) {
    CHECK(a.x == doctest::Approx(b.x).epsilon(1e-4).scale(100));
    CHECK(a.y == doctest::Approx(b.y).epsilon(1e-4).scale(100));
    CHECK(a.w == doctest::Approx(b.w).epsilon(1e-4).scale(100));
    CHECK(a.h == doctest::Approx(b.h).epsilon(1e-4).scale(100));
}

constexpr Vec2 kDesign{1280, 720};

}  // namespace

TEST_CASE("pick bounds: the outline of every kind of 2D entity matches entity.bounds()") {
    World w;
    const Entity dia = make_entity(w, "dia", {200, 100, 0}, 30.0f);
    add_shape(w, dia, ShapeType::Diamond, {80, 40});
    const Entity tri = make_entity(w, "tri", {-200, 100, 0}, 90.0f);
    add_shape(w, tri, ShapeType::Triangle, {60, 90}, {0.5f, 0.3333f});
    const Entity scaled = make_entity(w, "scaled", {10, -50, 0}, 17.0f, 2.0f);
    add_shape(w, scaled, ShapeType::Rectangle, {20, 10}, {0, 1});
    const Entity circle = make_entity(w, "circle", {0, 0, 0}, 0.0f);
    add_shape(w, circle, ShapeType::Circle, {30, 99}, {0, 0});
    const Entity line = make_entity(w, "line", {5, 5, 0}, 40.0f);
    add_shape(w, line, ShapeType::Line, {60, 20}).thickness = 6;
    const Entity sprite = make_entity(w, "sprite", {-30, 70, 0}, 12.0f);
    Sprite& sp = w.add<Sprite>(sprite);
    sp.size = {64, 32};
    sp.pivot = {0.25f, 0.75f};
    const Entity text = make_entity(w, "text", {60, -80, 0}, 8.0f);
    Text& tx = w.add<Text>(text);
    tx.text = "Score: 100";
    tx.fontSize = 20;
    const Entity map = make_entity(w, "map", {-300, 200, 0}, 0.0f);
    Tilemap& tm = w.add<Tilemap>(map);
    tm.tileSize = {32, 16};
    tm.tiles = Json::parse("[[0,0,-1,0],[-1,1,1,1],[2,2,2,2]]");  // rows form: 4 x 3 tiles, no width/height fields

    const VisualMeasure measure;
    for (Entity e : {dia, tri, scaled, circle, line, sprite, text, map}) {
        CAPTURE(w.id_of(e));
        const std::optional<Rect> engine = entity_world_rect(w, e, measure);
        REQUIRE(engine.has_value());
        const PickBounds b = pick_bounds(w, e, measure);
        REQUIRE(b.valid);
        CHECK_FALSE(b.screenSpace);
        const std::vector<PickOutline> outlines = pick_outlines(w, e, b, kDesign);
        REQUIRE(outlines.size() == 1);
        // The rectangle around the silhouette points is what entity.bounds() reports; the box is what is drawn around it.
        check_same_rect(around(outlines[0].hull), *engine);
        if (!outlines[0].hasHull) check_same_rect(around(outlines[0].box), *engine);
    }
    // Only the diamond has a silhouette that differs from its box.
    CHECK(pick_outlines(w, dia, pick_bounds(w, dia, measure), kDesign)[0].hasHull);
    CHECK_FALSE(pick_outlines(w, tri, pick_bounds(w, tri, measure), kDesign)[0].hasHull);
    // Tilemap rows form: 4 x 3 tiles of 32 x 16 from the top-left corner, local y down.
    check_same_rect(*entity_world_rect(w, map, measure), Rect{-300, 152, 128, 48});
}

TEST_CASE("pick bounds: a rotated triangle with pivot [0.5, 0.3333] is hit inside its oriented box only") {
    World w;
    const Entity tri = make_entity(w, "tri", {-200, 100, 0}, 90.0f);
    add_shape(w, tri, ShapeType::Triangle, {60, 90}, {0.5f, 0.3333f});
    const PickBounds b = pick_bounds(w, tri, {});
    auto hit = [&](float dx, float dy) { return pick_hit(w, tri, b, Vec2{-200 + dx, 100 + dy}, kDesign); };
    // Local box: x -30..30, y -29.997..60.003. Turned 90 degrees, (lx, ly) -> (-ly, lx): world x -60..30, y -30..30 around (-200, 100).
    CHECK(hit(0, 0));
    CHECK(hit(-55, 0));        // local (0, 55): inside along the long side
    CHECK(hit(25, 25));        // local (25, -25): inside
    CHECK_FALSE(hit(0, 55));   // the UNROTATED box would contain this point; here local (55, 0) is outside x -30..30
    CHECK_FALSE(hit(-65, 0));  // beyond the apex side
    CHECK_FALSE(hit(35, 0));   // beyond the base side
    CHECK_FALSE(hit(0, 35));
    int layer = 99;
    CHECK(pick_hit(w, tri, b, Vec2{-200, 100}, kDesign, &layer));
    CHECK(layer == 0);
}

TEST_CASE("pick bounds: a diamond is picked by its size box and outlined with its tips") {
    World w;
    const Entity dia = make_entity(w, "dia", {50, 50, 0});
    add_shape(w, dia, ShapeType::Diamond, {100, 40});
    const PickBounds b = pick_bounds(w, dia, {});
    CHECK(pick_hit(w, dia, b, Vec2{50, 50}, kDesign));
    CHECK(pick_hit(w, dia, b, Vec2{99, 69}, kDesign));  // the corner of the size box
    CHECK_FALSE(pick_hit(w, dia, b, Vec2{101, 50}, kDesign));
    CHECK_FALSE(pick_hit(w, dia, b, Vec2{50, 71}, kDesign));
    const PickOutline o = pick_outlines(w, dia, b, kDesign)[0];
    CHECK(o.hasHull);
    CHECK(o.hull[0].x == doctest::Approx(50.0f));  // bottom tip
    CHECK(o.hull[0].y == doctest::Approx(30.0f));
    CHECK(o.hull[1].x == doctest::Approx(100.0f));  // right tip
    CHECK(o.box[0].x == doctest::Approx(0.0f));     // the box corner
    CHECK(o.box[0].y == doctest::Approx(30.0f));
}

TEST_CASE("pick bounds: Text uses the measurer it is given, otherwise the headless approximation") {
    World w;
    const Entity text = make_entity(w, "text", {0, 0, 0});
    Text& t = w.add<Text>(text);
    t.text = "Hello";
    t.fontSize = 10;
    VisualMeasure wide;
    wide.textSize = [](const Text&) { return Vec2{200, 30}; };
    const PickBounds b = pick_bounds(w, text, wide);
    // Default pivot (0, 1): the box hangs below-right of the origin: x 0..200, y -30..0.
    CHECK(pick_hit(w, text, b, Vec2{150, -20}, kDesign));
    CHECK_FALSE(pick_hit(w, text, b, Vec2{150, 5}, kDesign));
    CHECK_FALSE(pick_hit(w, text, b, Vec2{210, -20}, kDesign));
    // Without a measurer: the same 0.6 em approximation as headless entity.bounds() (5 chars x 6 = 30 wide, 12 high).
    const PickBounds approx = pick_bounds(w, text, {});
    CHECK(pick_hit(w, text, approx, Vec2{25, -5}, kDesign));
    CHECK_FALSE(pick_hit(w, text, approx, Vec2{35, -5}, kDesign));
}

TEST_CASE("pick bounds: a Tilemap in rows form is picked by its rows, from its top-left corner") {
    World w;
    const Entity map = make_entity(w, "map", {-300, 200, 0});
    Tilemap& tm = w.add<Tilemap>(map);
    tm.tileSize = {32, 16};
    tm.tiles = Json::parse("[[0,0,-1,0],[-1,1,1,1],[2,2,2,2]]");  // 4 x 3 tiles; no width/height fields
    const PickBounds b = pick_bounds(w, map, {});
    REQUIRE(b.valid);
    CHECK(std::string(b.parts[0].component) == "Tilemap");
    // x -300..-172, y 152..200 (local y goes DOWN from the corner).
    CHECK(pick_hit(w, map, b, Vec2{-250, 180}, kDesign));
    CHECK(pick_hit(w, map, b, Vec2{-173, 153}, kDesign));
    CHECK_FALSE(pick_hit(w, map, b, Vec2{-250, 205}, kDesign));  // above the corner: the UNdone mirror image would be here
    CHECK_FALSE(pick_hit(w, map, b, Vec2{-250, 150}, kDesign));
    CHECK_FALSE(pick_hit(w, map, b, Vec2{-170, 180}, kDesign));
    // The flat form with width/height gives the same kind of box; an empty map has no footprint, only the marker.
    Tilemap& flat = w.add<Tilemap>(make_entity(w, "flat", {0, 0, 0}));
    flat.tileSize = {10, 10};
    flat.width = 5;
    flat.height = 2;
    flat.tiles = Json::parse("[0,0,0,0,0,1,1,1,1,1]");
    const Entity flatE = w.find_by_id("flat");
    CHECK(pick_hit(w, flatE, pick_bounds(w, flatE, {}), Vec2{25, -10}, kDesign));
    CHECK_FALSE(pick_hit(w, flatE, pick_bounds(w, flatE, {}), Vec2{25, 5}, kDesign));
    w.add<Tilemap>(make_entity(w, "empty", {0, 0, 0}));
    const Entity emptyE = w.find_by_id("empty");
    CHECK(std::string(pick_bounds(w, emptyE, {}).parts[0].component).empty());
}

TEST_CASE("pick bounds: screen-space entities are picked on the screen, with their anchor and the flipped y") {
    World w;
    // A 100 x 40 HUD panel anchored to the top-right corner, pivot at its own bottom-right: position [-20, 60].
    const Entity hud = make_entity(w, "hud", {-20, 60, 0});
    Shape2D& panel = add_shape(w, hud, ShapeType::Rectangle, {100, 40}, {1, 0});
    panel.space = RenderSpace::Screen;
    panel.anchor = {1, 0};
    const PickBounds b = pick_bounds(w, hud, {});
    REQUIRE(b.valid);
    CHECK(b.screenSpace);
    // Local box x -100..0, y 0..40 (up). On screen: x = 1280 - 20 + (-100..0) = 1160..1260, y = 60 - (0..40) = 20..60 (down).
    CHECK(pick_hit(w, hud, b, Vec2{1200, 40}, kDesign));
    CHECK(pick_hit(w, hud, b, Vec2{1161, 21}, kDesign));
    CHECK_FALSE(pick_hit(w, hud, b, Vec2{1200, 70}, kDesign));
    CHECK_FALSE(pick_hit(w, hud, b, Vec2{1100, 40}, kDesign));
    CHECK_FALSE(pick_hit(w, hud, b, Vec2{1200, 10}, kDesign));
    // A different design size moves the anchor.
    CHECK(pick_hit(w, hud, b, Vec2{860, 40}, Vec2{960, 540}));
    const PickOutline o = pick_outlines(w, hud, b, kDesign)[0];
    CHECK(o.screenSpace);
    check_same_rect(around(o.box), Rect{1160, 20, 100, 40});
    const Vec2 origin = pick_origin(w, hud, b, kDesign);
    CHECK(origin.x == doctest::Approx(1260.0f));
    CHECK(origin.y == doctest::Approx(60.0f));
    // The engine's world rectangle skips it, as documented: the editor has its own path here.
    CHECK_FALSE(entity_world_rect(w, hud).has_value());
    // A turned, centred screen-space sprite is hit inside its turned box.
    const Entity badge = make_entity(w, "badge", {640, 360, 0}, 90.0f);
    Sprite& sp = w.add<Sprite>(badge);
    sp.size = {100, 20};
    sp.space = RenderSpace::Screen;
    const PickBounds bb = pick_bounds(w, badge, {});
    CHECK(pick_hit(w, badge, bb, Vec2{640, 400}, kDesign));  // along the turned long side
    CHECK_FALSE(pick_hit(w, badge, bb, Vec2{690, 360}, kDesign));
}

TEST_CASE("pick bounds: entities that draw nothing get a marker, colliders their collider box") {
    World w;
    const Entity lone = make_entity(w, "lone", {10, 10, 0});
    const PickBounds m = pick_bounds(w, lone, {});
    REQUIRE(m.parts.size() == 1);
    CHECK(m.layer < -1500);  // behind everything that is drawn
    CHECK(pick_hit(w, lone, m, Vec2{15, 15}, kDesign));
    CHECK_FALSE(pick_hit(w, lone, m, Vec2{40, 10}, kDesign));
    const Entity box = make_entity(w, "box", {0, 0, 0});
    Collider2D& c = w.add<Collider2D>(box);
    c.shape = ColliderShape::Box;
    c.size = {40, 20};
    c.offset = {100, 0};
    const PickBounds cb = pick_bounds(w, box, {});
    CHECK(std::string(cb.parts[0].component) == "Collider2D");
    CHECK(pick_hit(w, box, cb, Vec2{115, 5}, kDesign));
    CHECK_FALSE(pick_hit(w, box, cb, Vec2{0, 0}, kDesign));
    // A visual wins over the collider.
    add_shape(w, box, ShapeType::Rectangle, {10, 10});
    CHECK(std::string(pick_bounds(w, box, {}).parts[0].component) == "Shape2D");
}

TEST_CASE("pick bounds: an entity with several visuals is hit on any of them, the highest layer wins") {
    World w;
    const Entity e = make_entity(w, "multi", {0, 0, 0});
    Sprite& sp = w.add<Sprite>(e);
    sp.size = {20, 20};
    sp.layer = 2;
    Shape2D& sh = add_shape(w, e, ShapeType::Rectangle, {20, 20}, {0, 0});  // x 0..20, y 0..20 (overlaps the sprite's quarter)
    sh.layer = 7;
    const PickBounds b = pick_bounds(w, e, {});
    REQUIRE(b.parts.size() == 2);
    CHECK(b.layer == 7);
    int layer = 0;
    CHECK(pick_hit(w, e, b, Vec2{-5, -5}, kDesign, &layer));  // only the sprite
    CHECK(layer == 2);
    CHECK(pick_hit(w, e, b, Vec2{5, 5}, kDesign, &layer));  // both
    CHECK(layer == 7);
    CHECK(pick_hit(w, e, b, Vec2{15, 15}, kDesign, &layer));  // only the shape
    CHECK(layer == 7);
    CHECK_FALSE(pick_hit(w, e, b, Vec2{-15, 15}, kDesign));
}
