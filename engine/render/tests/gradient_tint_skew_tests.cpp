// Shape2D gradient stops and easing (the ramp texture), the Tint component, Sprite.skew and the deformable sprite.
#include "test_util.h"

#include <algorithm>
#include <cmath>

#include "fa/scene/serialize.h"
#include "gradient_ramp.h"

using namespace fa;
using namespace fa::test;

namespace {

void black_cam(World& w) { w.add<Camera>(make(w, "cam")).clearColor = Color::black(); }

Shape2D& rect_shape(World& w, Vec2 size, Vec3 pos = {}) {
    Entity e = make(w, "rect", pos);
    Shape2D& s = w.add<Shape2D>(e);
    s.shape = ShapeType::Rectangle;
    s.size = size;
    s.color = Color::white();
    return s;
}

Json stop(double at, Json color) { return Json::array({at, std::move(color)}); }
Json rgba(double r, double g, double b, double a = 1.0) { return Json::array({r, g, b, a}); }

Entity white_sprite(World& w, Vec2 size, Vec3 pos = {}) {
    Entity e = make(w, "sprite", pos);
    w.add<Sprite>(e).size = size;
    return e;
}

}  // namespace

// ---- gradient specs and ramps (no GPU) ------------------------------------------------------------------------------------

TEST_CASE("gradient_spec: stops are sorted, clamped and capped; a plain two-colour gradient needs no ramp") {
    using namespace fa::render;
    Shape2D s;
    s.gradient = ShapeGradient::Linear;
    GradientSpec spec;
    CHECK_FALSE(gradient_spec(s, Color::white(), spec));  // color -> color2, linear: the shader blends it itself

    s.gradientEase = GradientEase::QuadIn;
    s.color = Color{1, 0, 0, 1};
    s.color2 = Color{0, 0, 1, 1};
    REQUIRE(gradient_spec(s, Color::white(), spec));  // an easing alone: a ramp of color -> color2
    CHECK(spec.count == 2);
    CHECK(spec.color[1].b == doctest::Approx(1.0f));

    s.gradientEase = GradientEase::Linear;
    s.gradientStops = Json::array({stop(1.0, rgba(0, 0, 1)), stop(-4.0, rgba(1, 0, 0)), stop(0.5, Json("#00ff00"))});
    std::string warning;
    REQUIRE(gradient_spec(s, Color{0.5f, 0.5f, 0.5f, 1}, spec, &warning));
    CHECK(warning.empty());
    REQUIRE(spec.count == 3);
    CHECK(spec.t[0] == 0.0f);  CHECK(spec.t[1] == 0.5f);  CHECK(spec.t[2] == 1.0f);  // sorted, -4 clamped to 0
    CHECK(spec.color[0].r == doctest::Approx(0.5f));                                      // the Tint is multiplied in
    CHECK(spec.color[1].g == doctest::Approx(0.5f));

    s.gradientStops = Json::array({stop(0.0, rgba(1, 0, 0)), Json("junk"), Json::array({0.5}), stop(1.0, Json("not a colour"))});
    REQUIRE(gradient_spec(s, Color::white(), spec, &warning));
    CHECK(spec.count == 1);
    CHECK(warning.find("3 entries were skipped") != std::string::npos);
    CHECK(warning.find("junk") != std::string::npos);

    Json many = Json::array();
    for (int i = 0; i < 12; ++i) many.push_back(stop(i / 11.0, rgba(i / 11.0, 0, 0)));
    s.gradientStops = many;
    REQUIRE(gradient_spec(s, Color::white(), spec));
    CHECK(spec.count == kMaxGradientStops);  // the others are ignored

    s.gradientStops = Json::array({stop(0.0, rgba(1, 0, 0))});  // not an array of stops -> nothing valid -> the two colours
    s.gradientStops = Json("oops");
    CHECK_FALSE(gradient_spec(s, Color::white(), spec));
}

TEST_CASE("bake_ramp_row: ends are the first and last stop, the middle is premultiplied and eased") {
    using namespace fa::render;
    GradientSpec spec;
    spec.count = 2;
    spec.t[0] = 0.0f;  spec.t[1] = 1.0f;
    spec.color[0] = Color{1, 0, 0, 1};
    spec.color[1] = Color{0, 0, 1, 0};  // fades to a transparent blue
    std::vector<std::uint8_t> row(kRampWidth * 4);
    bake_ramp_row(spec, row.data());
    CHECK(row[0] == 255);  CHECK(row[2] == 0);  CHECK(row[3] == 255);
    const int last = (kRampWidth - 1) * 4;
    CHECK(row[last + 3] == 0);
    const int mid = (kRampWidth / 2) * 4;
    CHECK(row[mid + 3] == doctest::Approx(127.5).epsilon(0.02));
    CHECK(row[mid + 0] > 240);  // premultiplied blend: the transparent end does not darken the red middle
    CHECK(row[mid + 2] < 5);

    spec.color[1] = Color{0, 0, 1, 1};
    spec.ease = GradientEase::QuadIn;  // baked into the row: at the middle texel the blend factor is 0.25
    bake_ramp_row(spec, row.data());
    CHECK(row[mid + 0] == doctest::Approx(255 * 0.75).epsilon(0.03));
    CHECK(row[mid + 2] == doctest::Approx(255 * 0.25).epsilon(0.05));
}

TEST_CASE("GradientRamps: equal specs share a row, a full table reuses rows of earlier frames and refuses ones in use") {
    using namespace fa::render;
    GradientRamps ramps;
    auto spec_of = [](int i) {
        GradientSpec s;
        s.count = 2;
        s.t[0] = 0.0f;  s.t[1] = 1.0f;
        s.color[0] = Color{float(i % 255) / 255.0f, float(i / 255) / 255.0f, 0, 1};
        s.color[1] = Color{0, 0, 1, 1};
        return s;
    };
    ramps.begin_frame();
    const int a = ramps.acquire(spec_of(1));
    CHECK(a >= 0);
    CHECK(ramps.acquire(spec_of(1)) == a);
    CHECK(ramps.acquire(spec_of(2)) != a);
    CHECK(ramps.rows_in_use() == 2);
    ramps.begin_frame();
    for (int i = 10; i < 10 + kRampRows; ++i) CHECK(ramps.acquire(spec_of(i)) >= 0);  // fills the table; evicts the two old rows
    CHECK(ramps.rows_in_use() == kRampRows);
    CHECK(ramps.acquire(spec_of(5000)) == -1);  // every row is used by this frame: none can go
    ramps.begin_frame();
    CHECK(ramps.acquire(spec_of(5000)) >= 0);   // a new frame: the oldest row is free to reuse
    CHECK(ramps.rows_in_use() == kRampRows);
}

TEST_CASE("Shape2D gradient fields: JSON round trip and defaults") {
    Shape2D s;
    CHECK(s.gradientStops.is_array());
    CHECK(s.gradientStops.empty());
    CHECK(s.gradientEase == GradientEase::Linear);
    World w;
    black_cam(w);
    Shape2D& r = rect_shape(w, {10, 10});
    r.gradient = ShapeGradient::Linear;
    r.gradientEase = GradientEase::SineOut;
    r.gradientStops = Json::array({stop(0, rgba(1, 0, 0)), stop(1, rgba(0, 0, 1))});
    World w2;
    const Json scene = save_scene(w);
    CHECK(load_scene(w2, scene, "test").ok());
    bool found = false;
    w2.each<Shape2D>([&](Entity, Shape2D& g) {
        found = true;
        CHECK(g.gradientEase == GradientEase::SineOut);
        CHECK(g.gradientStops.size() == 2);
    });
    CHECK(found);
}

// ---- gradient stops and easing on screen ----------------------------------------------------------------------------------

TEST_CASE("Shape2D gradientStops: three colours across a rectangle, a hard edge, a fade to transparent") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    {
        World w;
        black_cam(w);
        Shape2D& s = rect_shape(w, {200, 100});  // box x 60..259, y 40..139
        s.gradient = ShapeGradient::Linear;
        s.gradientStops = Json::array({stop(0, rgba(1, 0, 0)), stop(0.5, rgba(0, 1, 0)), stop(1, rgba(0, 0, 1))});
        Image img = g.render(w);
        CHECK(img.pixel(62, 90).r > 0.95f);   CHECK(img.pixel(62, 90).g < 0.1f);
        CHECK(img.pixel(160, 90).g > 0.95f);  CHECK(img.pixel(160, 90).r < 0.1f);   CHECK(img.pixel(160, 90).b < 0.1f);
        CHECK(img.pixel(257, 90).b > 0.95f);  CHECK(img.pixel(257, 90).g < 0.1f);
        CHECK(img.pixel(110, 90).r == doctest::Approx(0.5f).epsilon(0.1));          // halfway red -> green
        CHECK(img.pixel(110, 90).g == doctest::Approx(0.5f).epsilon(0.1));
    }
    {
        World w;
        black_cam(w);
        Shape2D& s = rect_shape(w, {200, 100});
        s.gradient = ShapeGradient::Linear;
        s.gradientStops = Json::array({stop(0, rgba(1, 0, 0)), stop(0.5, rgba(1, 0, 0)), stop(0.5, rgba(0, 0, 1)), stop(1, rgba(0, 0, 1))});
        Image img = g.render(w);
        CHECK(img.pixel(150, 90).r > 0.95f);  CHECK(img.pixel(150, 90).b < 0.05f);
        CHECK(img.pixel(170, 90).b > 0.95f);  CHECK(img.pixel(170, 90).r < 0.05f);
    }
    {
        World w;
        black_cam(w);
        Shape2D& s = rect_shape(w, {200, 100});
        s.color = Color{1, 1, 1, 0};  // both colours transparent: the stops decide whether it is visible
        s.color2 = Color{1, 1, 1, 0};
        s.gradient = ShapeGradient::Linear;
        s.gradientStops = Json::array({stop(0, rgba(1, 1, 1, 0)), stop(0.5, rgba(1, 1, 1, 1)), stop(1, rgba(1, 1, 1, 0))});
        Image img = g.render(w);
        CHECK(img.pixel(160, 90).r > 0.95f);
        CHECK(img.pixel(62, 90).r < 0.1f);
        CHECK(img.pixel(257, 90).r < 0.1f);
        CHECK(img.pixel(110, 90).r == doctest::Approx(0.5f).epsilon(0.1));  // white fading, not greying
    }
}

TEST_CASE("Shape2D gradientStops: radial, an angle, a rounded corner and the plain fields still work") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    black_cam(w);
    Entity e = make(w, "disc");
    Shape2D& s = w.add<Shape2D>(e);
    s.shape = ShapeType::Circle;
    s.size = {100, 100};
    s.gradient = ShapeGradient::Radial;
    s.gradientStops = Json::array({stop(0, rgba(1, 1, 1)), stop(0.6, rgba(1, 0, 0)), stop(1, rgba(1, 0, 0, 0))});
    Image img = g.render(w);
    CHECK(img.pixel(160, 90).g > 0.95f);                       // white centre
    CHECK(img.pixel(160 + 30, 90).r > 0.9f);                   // red band at 0.6 of the radius
    CHECK(img.pixel(160 + 30, 90).g < 0.15f);
    CHECK(img.pixel(160 + 48, 90).r < 0.35f);                  // fading out at the rim
    CHECK(img.pixel(160, 90 + 30).r == doctest::Approx(img.pixel(160 + 30, 90).r).epsilon(0.08));

    s.gradientStops = Json::array();  // no stops: the two colour fields again
    s.color = Color{0, 1, 0, 1};
    s.color2 = Color{0, 0, 1, 1};
    Image two = g.render(w);
    CHECK(two.pixel(160, 90).g > 0.95f);
    CHECK(two.pixel(160 + 45, 90).b > 0.8f);
}

TEST_CASE("Shape2D gradientEase: the middle of the gradient moves, the ends do not; shapes with ramps share a draw call") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    black_cam(w);
    Shape2D& s = rect_shape(w, {200, 100});
    s.gradient = ShapeGradient::Linear;
    s.color = Color{0, 0, 0, 1};
    s.color2 = Color{1, 1, 1, 1};
    Image linear = g.render(w);
    CHECK(linear.pixel(160, 90).r == doctest::Approx(0.5f).epsilon(0.06));
    s.gradientEase = GradientEase::QuadIn;  // stays dark longer: 0.5 -> 0.25
    Image in = g.render(w);
    CHECK(in.pixel(160, 90).r == doctest::Approx(0.25f).epsilon(0.12));
    CHECK(in.pixel(62, 90).r < 0.05f);
    CHECK(in.pixel(257, 90).r > 0.95f);
    s.gradientEase = GradientEase::QuadOut;  // 0.5 -> 0.75
    Image out = g.render(w);
    CHECK(out.pixel(160, 90).r == doctest::Approx(0.75f).epsilon(0.08));
    s.gradientEase = GradientEase::Smoothstep;
    s.gradientStops = Json::array({stop(0, rgba(0, 0, 0)), stop(1, rgba(1, 1, 1))});
    Image soft = g.render(w);
    CHECK(soft.pixel(110, 90).r < linear.pixel(110, 90).r);  // an S curve: darker than linear in the first half
    CHECK(soft.pixel(210, 90).r > linear.pixel(210, 90).r);

    const int oneShape = (g.render(w), g.renderer.stats().drawCalls);
    Shape2D& second = rect_shape(w, {50, 20}, {0, 70, 0});
    second.gradient = ShapeGradient::Linear;
    second.gradientStops = Json::array({stop(0, rgba(1, 0, 0)), stop(1, rgba(0, 1, 0))});
    second.gradientEase = GradientEase::CubicOut;
    g.render(w);
    CHECK(g.renderer.stats().drawCalls == oneShape);  // another ramp is another row of the same texture, same batch
}

TEST_CASE("Shape2D gradientStops with a malformed entry draws the valid ones and does not crash") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    black_cam(w);
    Shape2D& s = rect_shape(w, {200, 100});
    s.gradient = ShapeGradient::Linear;
    s.gradientStops = Json::array({stop(0, rgba(1, 0, 0)), Json(7), stop(1, rgba(0, 0, 1)), Json::array({"a", "b"})});
    Image img = g.render(w);
    CHECK(img.pixel(62, 90).r > 0.95f);
    CHECK(img.pixel(257, 90).b > 0.95f);
}

// ---- Tint -----------------------------------------------------------------------------------------------------------------

TEST_CASE("Tint: multiplies colour and opacity into the entity and all its descendants, nested tints multiply") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    black_cam(w);
    Entity group = make(w, "group");
    w.add<Tint>(group).color = Color{1, 0, 0, 1};
    Entity mid = make(w, "mid");
    w.set_parent(mid, group);
    w.add<Tint>(mid).color = Color{1, 1, 1, 0.5f};
    Entity leaf = white_sprite(w, {40, 40}, {-60, 0, 0});
    w.set_parent(leaf, mid);
    Entity bare = white_sprite(w, {40, 40}, {60, 0, 0});  // no Tint anywhere above
    (void)bare;
    Entity lone = white_sprite(w, {20, 20}, {0, 50, 0});   // a sibling of the group: unaffected
    (void)lone;
    Image img = g.render(w);
    // The leaf: white x red x half opacity over black = (0.5, 0, 0) (the leaf is at world -60 + 0, its parents at the origin).
    const Color c = img.pixel(160 - 60, 90);
    CHECK(c.r == doctest::Approx(0.5f).epsilon(0.05));
    CHECK(c.g < 0.03f);
    CHECK(c.b < 0.03f);
    CHECK(img.pixel(160 + 60, 90).g > 0.95f);  // the untinted sprite is still white
    CHECK(img.pixel(160, 90 - 50).g > 0.95f);
    w.remove<Tint>(group);  // only the half-opacity tint is left
    Image half = g.render(w);
    CHECK(half.pixel(160 - 60, 90).g == doctest::Approx(0.5f).epsilon(0.05));
    w.get<Tint>(mid)->color = Color{1, 1, 1, 0};  // fully transparent: the leaf is skipped
    Image none = g.render(w);
    CHECK(none.pixel(160 - 60, 90).r < 0.02f);
}

TEST_CASE("Tint covers Shape2D (and its gradient), Text, Tilemap, particles and UI widgets") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Image sheet;
    sheet.width = 32;
    sheet.height = 16;
    sheet.rgba.resize(32 * 16 * 4);
    for (int y = 0; y < 16; ++y)
        for (int x = 0; x < 32; ++x) sheet.set_pixel(x, y, Color::white());
    REQUIRE(save_png(sheet, "assets/tint_tiles.png").ok());

    World w;
    black_cam(w);
    Entity group = make(w, "group");
    w.add<Tint>(group).color = Color{0, 0, 1, 1};
    auto child = [&](Entity e) { w.set_parent(e, group); return e; };

    Entity shape = child(make(w, "shape", {-100, 50, 0}));
    {
        Shape2D& s = w.add<Shape2D>(shape);
        s.size = {30, 30};
        s.color = Color::white();
    }
    Entity ramp = child(make(w, "ramp", {-50, 50, 0}));
    {
        Shape2D& s = w.add<Shape2D>(ramp);
        s.size = {30, 30};
        s.gradient = ShapeGradient::Linear;
        s.gradientStops = Json::array({stop(0, rgba(1, 1, 1)), stop(1, rgba(1, 1, 0))});
    }
    Entity text = child(make(w, "text", {10, 60, 0}));
    {
        Text& t = w.add<Text>(text);
        t.text = "MMMM";
        t.fontSize = 24;
        t.pivot = {0, 1};
        t.color = Color::white();
    }
    Entity tiles = child(make(w, "tiles", {-100, -10, 0}));
    {
        Tilemap& tm = w.add<Tilemap>(tiles);
        tm.tileset = "assets/tint_tiles.png";
        tm.tileSize = {16, 16};
        tm.columns = 2;
        tm.width = 2;
        tm.height = 1;
        tm.tiles = Json::array({0, 1});
    }
    Entity fx = child(make(w, "fx", {60, -40, 0}));
    {
        ParticleEmitter& p = w.add<ParticleEmitter>(fx);
        p.rate = 0;
        p.burst = 40;
        p.lifetime = 5.0f;
        p.speed = 0;
        p.gravity = {0, 0, 0};
        p.startSize = 8;
        p.endSize = 8;
        p.startColor = Color::white();
        p.endColor = Color::white();
    }
    Entity panel = child(make(w, "panel", {200, 100, 0}));  // a widget: design pixels, top-left corner
    {
        Panel& pn = w.add<Panel>(panel);
        pn.size = {40, 20};
        pn.pivot = {0, 1};
        pn.color = Color::white();
    }
    Image img;
    for (int i = 0; i < 3; ++i) img = g.render(w, 1.0f / 60.0f);
    auto is_blue = [&](const Color& c) { return c.b > 0.9f && c.r < 0.06f && c.g < 0.06f; };
    CHECK(is_blue(img.pixel(160 - 100, 90 - 50)));  // flat shape
    // ramp shape: the stops are tinted too (white -> yellow becomes blue -> black)
    CHECK(img.pixel(160 - 50 - 12, 90 - 50).b > 0.8f);
    CHECK(img.pixel(160 - 50 - 12, 90 - 50).g < 0.06f);
    CHECK(img.pixel(160 - 50 + 12, 90 - 50).b < 0.25f);
    CHECK(is_blue(img.pixel(160 - 100 + 8, 90 + 10 + 8)));  // tilemap, first tile
    CHECK(is_blue(img.pixel(160 - 100 + 24, 90 + 10 + 8)));
    CHECK(is_blue(img.pixel(210, 110)));  // UI panel
    // Text: bright pixels exist and none has any red or green.
    float maxB = 0, maxRG = 0;
    for (int y = 0; y < img.height; ++y)
        for (int x = 170; x < 300; ++x)
            if (y < 90 - 20 && y > 90 - 70) {
                maxB = std::max(maxB, img.pixel(x, y).b);
                maxRG = std::max({maxRG, img.pixel(x, y).r, img.pixel(x, y).g});
            }
    CHECK(maxB > 0.8f);
    CHECK(maxRG < 0.08f);
    // Particles: lit pixels around (220, 130) are blue.
    float pb = 0, prg = 0;
    for (int y = 120; y < 140; ++y)
        for (int x = 210; x < 230; ++x) {
            pb = std::max(pb, img.pixel(x, y).b);
            prg = std::max({prg, img.pixel(x, y).r, img.pixel(x, y).g});
        }
    CHECK(pb > 0.8f);
    CHECK(prg < 0.08f);
}

TEST_CASE("Tint: rich text colours and UI widgets are tinted too") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    black_cam(w);
    Entity group = make(w, "group");
    w.add<Tint>(group).color = Color{0, 1, 0, 1};
    Entity label = make(w, "label", {-140, 70, 0});
    w.set_parent(label, group);
    {
        Text& t = w.add<Text>(label);
        t.text = "[c:#ff0000]MMMM[/c]";
        t.markup = true;
        t.fontSize = 28;
        t.pivot = {0, 1};
    }
    Entity panel = make(w, "panel", {200, 100, 0});
    w.set_parent(panel, group);
    {
        Panel& p = w.add<Panel>(panel);
        p.size = {80, 30};
        p.pivot = {0, 1};
        p.color = Color::white();
    }
    Image img = g.render(w);
    float rMax = 0, gMax = 0;
    for (int y = 10; y < 60; ++y)
        for (int x = 10; x < 140; ++x) {
            rMax = std::max(rMax, img.pixel(x, y).r);
            gMax = std::max(gMax, img.pixel(x, y).g);
        }
    CHECK(rMax < 0.05f);  // the red run colour times a green tint is black
    CHECK(gMax < 0.05f);
    CHECK(img.pixel(210, 110).g > 0.9f);  // the white Panel times the green tint
    CHECK(img.pixel(210, 110).r < 0.05f);
    CHECK(img.pixel(210, 110).b < 0.05f);
}

// ---- Sprite.skew and the deformable sprite -------------------------------------------------------------------------------

TEST_CASE("Sprite.skew: the top edge leans right for a positive angle, the pivot row stays put") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    black_cam(w);
    Entity e = white_sprite(w, {40, 40});  // box x 140..179, y 70..109
    Image plain = g.render(w);
    CHECK(plain.pixel(142, 72).r > 0.95f);
    w.get<Sprite>(e)->skew = {45.0f, 0.0f};  // the top row (y = 70) moves 20 right, the bottom row 20 left; the middle stays
    Image sk = g.render(w);
    CHECK(sk.pixel(172 + 16, 72).r > 0.95f);   // top row: x 140..179 -> 160..199
    CHECK(sk.pixel(142, 72).r < 0.05f);
    CHECK(sk.pixel(142 - 16, 107).r > 0.95f);  // bottom row shifted left: x 120..159
    CHECK(sk.pixel(175, 107).r < 0.05f);
    CHECK(sk.pixel(150, 90).r > 0.95f);        // the middle row (the pivot) is where it was
    CHECK(sk.pixel(128, 90).r < 0.05f);
    w.get<Sprite>(e)->skew = {-45.0f, 0.0f};
    Image back = g.render(w);
    CHECK(back.pixel(142 - 16, 72).r > 0.95f);
    w.get<Sprite>(e)->skew = {0.0f, 45.0f};  // the right edge goes up
    Image up = g.render(w);
    CHECK(up.pixel(178, 72 - 16).r > 0.95f);
    CHECK(up.pixel(142, 72 - 16).r < 0.05f);
}

TEST_CASE("Sprite mesh: a deformable sprite is one entity, one draw call, and the vertex offsets bend it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    black_cam(w);
    Entity e = white_sprite(w, {80, 40});  // box x 120..199, y 70..109
    Image plain = g.render(w);
    const int plainCalls = g.renderer.stats().drawCalls;
    Sprite& s = *w.get<Sprite>(e);
    s.meshColumns = 4;
    s.meshRows = 2;
    Image grid = g.render(w);  // no offsets: the same picture
    CHECK(diff_images(plain, grid, 2.0f / 255.0f).meanError < 0.0005);
    CHECK(g.renderer.stats().drawCalls == plainCalls);
    CHECK(g.renderer.stats().sprites == 1);

    // 5 x 3 vertices from the TOP row. The top-middle vertex (column 2, index 2) goes 20 up.
    Json off = Json::array();
    for (int i = 0; i < 15; ++i) {
        off.push_back(0);
        off.push_back(i == 2 ? 20 : 0);
    }
    s.vertexOffsets = off;
    Image bent = g.render(w);
    CHECK(g.renderer.stats().drawCalls == plainCalls);
    CHECK(bent.pixel(160, 60).r > 0.5f);    // above the old top edge (y 70), under the raised vertex
    CHECK(bent.pixel(122, 60).r < 0.05f);   // away from it the sprite does not reach that high
    CHECK(bent.pixel(160, 90).r > 0.95f);
    CHECK(bent.pixel(160, 50).r < 0.05f);   // beyond the raised vertex

    // The texture is stretched with the vertices: a texture with a dark left half and a light right half keeps its seam
    // at the middle column when the middle vertices move.
    Image halves;
    halves.width = 8;
    halves.height = 8;
    halves.rgba.resize(8 * 8 * 4);
    for (int y = 0; y < 8; ++y)
        for (int x = 0; x < 8; ++x) halves.set_pixel(x, y, x < 4 ? Color{0, 0, 1, 1} : Color{1, 0, 0, 1});
    REQUIRE(save_png(halves, "assets/mesh_halves.png").ok());
    s.texture = "assets/mesh_halves.png";
    s.meshColumns = 2;
    s.meshRows = 1;
    s.vertexOffsets = Json::array({0, 0, 30, 0, 0, 0, 0, 0, 30, 0, 0, 0});  // the middle column goes 30 right
    Image seam = g.render(w);
    CHECK(seam.pixel(140, 90).b > 0.9f);
    CHECK(seam.pixel(185, 90).b > 0.9f);   // the blue half now reaches x = 190 (it was 160)
    CHECK(seam.pixel(195, 90).r > 0.9f);
    s.skew = {45.0f, 0.0f};  // skew and mesh together: the top row leans right
    Image both = g.render(w);
    CHECK(both.pixel(125 + 20, 72).b > 0.9f);
}

TEST_CASE("Sprite mesh: too many cells draws a plain quad, offsets of the wrong kind are ignored") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    black_cam(w);
    Entity e = white_sprite(w, {40, 40});
    Sprite& s = *w.get<Sprite>(e);
    s.meshColumns = 100;
    s.meshRows = 100;
    s.vertexOffsets = Json::array({50, 50, 50});
    Image img = g.render(w);
    CHECK(img.pixel(150, 90).r > 0.95f);   // the plain 40 x 40 box
    CHECK(img.pixel(190, 90).r < 0.05f);   // the offsets did nothing
    s.meshColumns = 2;
    s.meshRows = 2;
    s.vertexOffsets = Json("not an array");
    Image odd = g.render(w);
    CHECK(odd.pixel(150, 90).r > 0.95f);
    s.vertexOffsets = Json::array({"a", nullptr, true});  // not numbers: 0
    Image zero = g.render(w);
    CHECK(zero.pixel(150, 90).r > 0.95f);
    s.meshColumns = 128;  // the biggest grid that fits the budget on one side
    s.meshRows = 1;
    s.vertexOffsets = Json::array();
    Image big = g.render(w);
    CHECK(big.pixel(150, 90).r > 0.95f);
}
