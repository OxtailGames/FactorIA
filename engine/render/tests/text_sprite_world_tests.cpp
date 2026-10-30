// M44.4: world Text sized in meters (and lit by the 3D lights), Sprite.vertexColors, and an entity that is destroyed during a
// frame is not drawn in that frame (FB-0027, FB-0033, FB-0034).
#include "test_util.h"

#include <algorithm>
#include <cmath>

#include "fa/scene/bounds.h"
#include "fa/scene/serialize.h"

using namespace fa;
using namespace fa::test;

namespace {

void black_cam(World& w) { w.add<Camera>(make(w, "cam")).clearColor = Color::black(); }

// A perspective camera at (0, 0, dist) looking down -Z: the world plane z = 0 is `dist` meters away.
void persp_cam(World& w, float dist) {
    Entity cam = make(w, "cam", {0, 0, dist});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    c.clearColor = Color::black();
    w.settings().skyColor = Color::black();      // the 3D background gradient would be the brightest pixel
    w.settings().horizonColor = Color::black();
    w.settings().fogDensity = 0.0f;
}

Entity world_text(World& w, const char* text, float fontSize, Vec3 pos = {}) {
    Entity e = make(w, "text", pos);
    Text& t = w.add<Text>(e);
    t.text = text;
    t.fontSize = fontSize;
    t.pivot = {0.5f, 0.5f};
    t.align = Align::Center;
    t.color = Color::white();
    return e;
}

float brightest(const Image& img) {
    float best = 0;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) best = std::max(best, img.pixel(x, y).r);
    return best;
}

int lit_pixels(const Image& img, float over = 0.2f) {
    int n = 0;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) n += img.pixel(x, y).r > over ? 1 : 0;
    return n;
}

}  // namespace

TEST_CASE("Text.fontSize accepts meters: 0.07 is a registered value and the smallest allowed is 0.001") {
    ensure_builtin_components();
    const TypeInfo* t = TypeRegistry::global().find("Text");
    REQUIRE(t);
    const FieldInfo* f = nullptr;
    for (const FieldInfo& fi : t->fields)
        if (fi.name == "fontSize") f = &fi;
    REQUIRE(f);
    CHECK(f->minValue == doctest::Approx(0.001f));
    CHECK(f->maxValue == doctest::Approx(4096.0f));
    f = nullptr;
    for (const FieldInfo& fi : t->fields)
        if (fi.name == "lit") f = &fi;
    CHECK(f);
}

TEST_CASE("a world Text of fontSize 0.07 in a perspective scene is as sharp as fontSize 70 at scale 0.001") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World a;
    persp_cam(a, 0.5f);
    world_text(a, "Title", 0.07f);
    Image small = g.render(a);
    CHECK(g.renderer.stats().textGlyphs == 5);

    World b;
    persp_cam(b, 0.5f);
    Entity e = world_text(b, "Title", 70.0f);
    b.get<Transform>(e)->scale = {0.001f, 0.001f, 0.001f};
    Image scaled = g.render(b);

    CHECK(lit_pixels(small) > 30);                 // drawn, not a speck of 1 px
    CHECK(brightest(small) > 0.9f);                // glyph cores are solid white: rasterized for the screen size, not 0.07
    CHECK(diff_images(small, scaled, 8.0f / 255.0f).meanError < 0.01);
}

TEST_CASE("Text.lit: the text is shaded by the 3D lights, unlit text ignores them") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    auto shot = [&](bool lit, float intensity, float ambient, Vec3 lightRot) {
        World w;
        persp_cam(w, 0.5f);
        w.settings().ambientLight = Color{ambient, ambient, ambient, 1};
        Entity t = world_text(w, "Title", 0.1f);
        w.get<Text>(t)->lit = lit;
        if (intensity > 0) {
            Entity l = make(w, "sun");
            w.get<Transform>(l)->rotation = lightRot;
            auto& li = w.add<Light>(l);
            li.type = LightType::Directional;
            li.intensity = intensity;
        }
        return brightest(g.render(w));
    };
    const float unlit = shot(false, 0.0f, 0.0f, {});
    CHECK(unlit > 0.95f);                                    // unlit: exactly the colour
    CHECK(shot(true, 0.0f, 0.0f, {}) < 0.05f);               // lit, no light, no ambient: black
    CHECK(shot(true, 0.0f, 0.4f, {}) == doctest::Approx(0.4f).epsilon(0.1));      // ambient only
    CHECK(shot(true, 0.5f, 0.0f, {0, 0, 0}) == doctest::Approx(0.5f).epsilon(0.1)); // light along -Z hits the +Z face head on
    CHECK(shot(true, 1.0f, 0.0f, {0, 90, 0}) < 0.05f);       // light along the text plane: lights nothing
    CHECK(shot(true, 1.0f, 0.0f, {0, 0, 0}) > 0.95f);
    CHECK(shot(false, 0.0f, 0.0f, {0, 90, 0}) > 0.95f);      // unlit ignores it all
}

TEST_CASE("Sprite.vertexColors: colour per grid vertex, multiplied with color; a wrong length teaches") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    black_cam(w);
    Entity e = make(w, "page");
    Sprite& s = w.add<Sprite>(e);
    s.size = {100, 40};
    s.meshColumns = 2;
    s.meshRows = 1;
    // 3 x 2 vertices: left column black, middle grey, right white (both rows).
    Json colors = Json::array();
    for (int row = 0; row < 2; ++row)
        for (float v : {0.0f, 0.5f, 1.0f})
            for (float c : {v, v, v, 1.0f}) colors.push_back(c);
    s.vertexColors = colors;
    CHECK(fa::sprite_vertex_colors_problem(s).empty());
    Image img = g.render(w);
    const float left = img.pixel(120, 90).r, mid = img.pixel(160, 90).r, right = img.pixel(198, 90).r;
    CHECK(left < 0.15f);
    CHECK(mid == doctest::Approx(0.5f).epsilon(0.1));
    CHECK(right > 0.85f);
    CHECK(img.pixel(140, 90).r == doctest::Approx(0.25f).epsilon(0.25));  // blended across the cell

    s.color = Color{1, 0, 0, 1};  // multiplied with color
    Image tinted = g.render(w);
    CHECK(tinted.pixel(198, 90).r > 0.85f);
    CHECK(tinted.pixel(198, 90).g < 0.05f);

    // The wrong length: a message with both lengths and what to do.
    s.vertexColors = Json::array({1, 1, 1, 1});
    const std::string problem = fa::sprite_vertex_colors_problem(s);
    CHECK(problem.find("needs 24") != std::string::npos);
    CHECK(problem.find("has 4 numbers") != std::string::npos);
    Image ignored = g.render(w);  // ignored (one warning), drawn with the plain colour
    CHECK(ignored.pixel(120, 90).r > 0.9f);

    // A scene with the wrong length is a load error at the right pointer.
    World loaded;
    Json scene = Json::object({{"entities", Json::array({Json::object({{"name", "p"}, {"components", Json::object({
        {"Sprite", Json::object({{"meshColumns", 2}, {"meshRows", 1}, {"vertexColors", Json::array({1, 1, 1})}})}})}})})}});
    LoadReport report = load_scene(loaded, scene, "<test>");
    INFO(report.summary());
    REQUIRE_FALSE(report.ok());
    bool found = false;
    for (const LoadMessage& m : report.messages)
        if (m.pointer.find("/Sprite/vertexColors") != std::string::npos && m.message.find("needs 24") != std::string::npos) found = true;
    CHECK(found);

    // Without a grid it is an error as well.
    s.meshColumns = 0;
    s.vertexColors = colors;
    CHECK_FALSE(fa::sprite_vertex_colors_problem(s).empty());
}

TEST_CASE("an entity destroyed during a frame is not drawn in that frame, its replacement is (FB-0034)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    black_cam(w);
    auto group = [&](const char* name, Vec3 pos) {
        Entity root = make(w, name, pos);
        Entity child = make(w, "label", {});
        w.set_parent(child, root);
        Text& t = w.add<Text>(child);
        t.text = "MMMM";
        t.fontSize = 40;
        t.pivot = {0.5f, 0.5f};
        t.align = Align::Center;
        Entity box = make(w, "box", {});
        w.set_parent(box, root);
        Sprite& s = w.add<Sprite>(box);
        s.size = {30, 30};
        return root;
    };
    Entity oldGroup = group("old", {-80, 0, 0});
    Image before = g.render(w);
    CHECK(lit_pixels(before) > 100);
    int leftBefore = 0;
    for (int y = 0; y < before.height; ++y)
        for (int x = 0; x < before.width / 2; ++x) leftBefore += before.pixel(x, y).r > 0.5f ? 1 : 0;
    REQUIRE(leftBefore > 100);

    // One frame: a handler destroys the group and spawns its replacement on the other side. The destroy is deferred to the end of
    // the frame, but this frame is drawn first.
    w.destroy(oldGroup);
    group("new", {80, 0, 0});
    const int glyphsExpected = 4;
    Image during = g.render(w);
    CHECK(g.renderer.stats().textGlyphs == glyphsExpected);   // only the replacement's text
    CHECK(g.renderer.stats().sprites == 1);
    int left = 0, right = 0;
    for (int y = 0; y < during.height; ++y)
        for (int x = 0; x < during.width; ++x) (x < during.width / 2 ? left : right) += during.pixel(x, y).r > 0.5f ? 1 : 0;
    CHECK(left == 0);
    CHECK(right > 100);

    w.flush();  // the end of the frame
    Image after = g.render(w);
    CHECK(diff_images(during, after, 2.0f / 255.0f).meanError < 0.0005);
}
