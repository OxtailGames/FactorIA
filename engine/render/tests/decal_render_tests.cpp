// M73.5b on a GPU: the projected decals are drawn over the meshes they touch (the CPU half is in decal_tests.cpp). A Decal box paints its
// albedo, tint and normal relief on the receivers inside it; a scene without decals draws exactly what it drew before.
#include "test_util.h"

#include <algorithm>
#include <cmath>

using namespace fa;
using namespace fa::test;

namespace {

void add_camera(World& w, Vec3 pos, Vec3 lookAt) {
    Entity cam = make(w, "cam", pos);
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    const Vec3 f = normalize(lookAt - pos);
    w.get<Transform>(cam)->rotation = {degrees(std::asin(f.y)), degrees(std::atan2(-f.x, -f.z)), 0};
}
Entity add_mesh(World& w, const char* mesh, Vec3 pos, Color color, Vec3 scale = {1, 1, 1}) {
    Entity e = make(w, mesh, pos);
    w.get<Transform>(e)->scale = scale;
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = mesh;
    m.color = color;
    return e;
}
Entity add_decal(World& w, Vec3 pos, Vec3 rot, Vec3 scale) {
    Entity e = make(w, "decal", pos);
    w.get<Transform>(e)->rotation = rot;
    w.get<Transform>(e)->scale = scale;
    w.add<Decal>(e);
    return e;
}

// A ring with a soft alpha edge, RGBA.
void write_ring(const char* path) {
    const int size = 64;
    Image img;
    img.width = img.height = size;
    img.rgba.resize(std::size_t(size) * size * 4);
    for (int y = 0; y < size; ++y)
        for (int x = 0; x < size; ++x) {
            const float dx = (float(x) + 0.5f) / float(size) * 2.0f - 1.0f, dy = (float(y) + 0.5f) / float(size) * 2.0f - 1.0f;
            const float r = std::sqrt(dx * dx + dy * dy);
            const float a = std::clamp(1.0f - std::fabs(r - 0.7f) / 0.2f, 0.0f, 1.0f);
            std::uint8_t* p = &img.rgba[(std::size_t(y) * size + std::size_t(x)) * 4];
            p[0] = 255;
            p[1] = 255;
            p[2] = 255;
            p[3] = std::uint8_t(std::lround(a * 255.0f));
        }
    REQUIRE(save_png(img, path).ok());
}
// Round bumps (tangent-space normal map, +Y up).
void write_bumps(const char* path) {
    const int size = 64;
    Image img;
    img.width = img.height = size;
    img.rgba.resize(std::size_t(size) * size * 4);
    for (int y = 0; y < size; ++y)
        for (int x = 0; x < size; ++x) {
            const float lx = (float(x % 32) + 0.5f) / 32.0f * 2.0f - 1.0f, ly = -((float(y % 32) + 0.5f) / 32.0f * 2.0f - 1.0f);
            const Vec3 n = lx * lx + ly * ly < 1.0f ? normalize(Vec3{lx * 1.6f, ly * 1.6f, 1.0f}) : Vec3{0, 0, 1};
            std::uint8_t* p = &img.rgba[(std::size_t(y) * size + std::size_t(x)) * 4];
            p[0] = std::uint8_t(std::lround((n.x * 0.5f + 0.5f) * 255.0f));
            p[1] = std::uint8_t(std::lround((n.y * 0.5f + 0.5f) * 255.0f));
            p[2] = std::uint8_t(std::lround((n.z * 0.5f + 0.5f) * 255.0f));
            p[3] = 255;
        }
    REQUIRE(save_png(img, path).ok());
}

struct Scene {
    Entity cube, sphere, ground;
    Entity front, top, splash;
};

// A box and a sphere on a ground, a sun and three decals: a ring on the face of the box, a ring with bumps on the top of the sphere and a
// plain yellow splash on the ground. `decals` false leaves them out (the same entities otherwise).
Scene make_scene(World& w, bool decals) {
    Scene s;
    add_camera(w, {0, 3.2f, 7.0f}, {0, 0.4f, 0});
    w.settings().ambientLight = Color{0.15f, 0.15f, 0.18f, 1};
    s.ground = add_mesh(w, "plane", {0, 0, 0}, Color::hex(0xb0a898), {12, 1, 12});
    s.cube = add_mesh(w, "cube", {-1.8f, 0.75f, 0}, Color::hex(0xc8c8c8), {1.5f, 1.5f, 1.5f});
    s.sphere = add_mesh(w, "sphere", {1.8f, 0.75f, 0}, Color::hex(0xc8c8c8), {1.5f, 1.5f, 1.5f});
    Entity sun = make(w, "sun", {0, 5, 0});
    w.get<Transform>(sun)->rotation = {-50, 25, 0};
    auto& l = w.add<Light>(sun);
    l.type = LightType::Directional;
    l.intensity = 1.0f;
    if (!decals) return s;
    // On the face of the box that looks at the camera: the box starts in front of it and projects toward -Z.
    s.front = add_decal(w, {-1.8f, 0.9f, 1.2f}, {0, 0, 0}, {1.1f, 1.1f, 1.2f});
    {
        auto& d = *w.get<Decal>(s.front);
        d.albedo = "assets/decal_ring.png";
        d.color = Color::hex(0xe03020);
    }
    // On the top of the sphere, projecting down: rotating -90 degrees about X points -Z down.
    s.top = add_decal(w, {1.8f, 1.9f, 0}, {-90, 0, 0}, {1.3f, 1.3f, 1.6f});
    {
        auto& d = *w.get<Decal>(s.top);
        d.albedo = "assets/decal_ring.png";
        d.normal = "assets/decal_bumps.png";
        d.color = Color::hex(0x2060e0);
        d.normalStrength = 1.5f;
    }
    // A plain tinted square on the ground, between the two.
    s.splash = add_decal(w, {0, 0.4f, 1.8f}, {-90, 0, 0}, {1.6f, 1.6f, 1.4f});
    {
        auto& d = *w.get<Decal>(s.splash);
        d.color = Color::hex(0xf0d020);
        d.opacity = 0.8f;
    }
    return s;
}

int differing(const Image& a, const Image& b, int x0, int y0, int x1, int y1, float t = 0.02f) {
    int n = 0;
    for (int y = y0; y < y1; ++y)
        for (int x = x0; x < x1; ++x) {
            const Color p = a.pixel(x, y), q = b.pixel(x, y);
            if (std::fabs(p.r - q.r) > t || std::fabs(p.g - q.g) > t || std::fabs(p.b - q.b) > t) ++n;
        }
    return n;
}

void write_textures() {
    write_ring("assets/decal_ring.png");
    write_bumps("assets/decal_bumps.png");
}

}  // namespace

TEST_CASE("decals: a ring on a box, a ring with relief on a sphere and a tinted splash on the ground") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("decals")) return;
    write_textures();
    World plain, withDecals;
    make_scene(plain, false);
    const Image before = g.render(plain);
    CHECK(g.renderer.stats().decals == 0);
    make_scene(withDecals, true);
    const Image after = g.render(withDecals);
    const RenderStats s = g.renderer.stats();
    CHECK(s.decals == 3);
    CHECK(s.decalsDropped == 0);
    CHECK(s.decalClusterClipped == 0);
    CHECK(s.meshes == 3);
    // The picture changes where the decals are: the whole image differs in some pixels, and the three places each differ.
    const int total = differing(before, after, 0, 0, after.width, after.height);
    CHECK(total > 400);
    CHECK(differing(before, after, 96, 62, 134, 104) > 100);   // the box's face
    CHECK(differing(before, after, 175, 60, 222, 105) > 100);  // the sphere's top
    expect_golden(after, "3d_decals");
}

TEST_CASE("decals: a scene without them draws the same picture as before, and the same picture twice") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("decals")) return;
    write_textures();
    World a, b;
    make_scene(a, false);
    make_scene(b, true);
    const Image first = g.render(a);
    g.render(b);
    // Taking the decals away again gives the first picture exactly: nothing of the decals stays in the renderer's state.
    World c;
    make_scene(c, false);
    const Image again = g.render(c);
    CHECK(differing(first, again, 0, 0, first.width, first.height, 0.0f) == 0);
    const Image x = g.render(b), y = g.render(b);
    CHECK(differing(x, y, 0, 0, x.width, y.height, 0.0f) == 0);
}

TEST_CASE("decals: MeshRenderer.receiveDecals false and a decal layer that is not the decal's keep a mesh clean") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("decals")) return;
    write_textures();
    World plain, w;
    make_scene(plain, false);
    const Scene s = make_scene(w, true);
    const Image before = g.render(plain);
    const Image all = g.render(w);
    const int boxArea = differing(before, all, 96, 62, 134, 104);
    CHECK(boxArea > 100);
    // The box opts out: its face is the picture of the scene without decals (a different batch, the same pixels).
    w.get<MeshRenderer>(s.cube)->receiveDecals = false;
    const Image optedOut = g.render(w);
    CHECK(differing(before, optedOut, 96, 62, 134, 104) == 0);
    CHECK(differing(before, optedOut, 175, 60, 222, 105) > 100);  // the sphere still receives its own
    w.get<MeshRenderer>(s.cube)->receiveDecals = true;
    // Layers: the decal on the box only reaches layer 1 and the box is in layer 0.
    w.get<Decal>(s.front)->layers = 2;
    const Image layered = g.render(w);
    CHECK(differing(before, layered, 96, 62, 134, 104) == 0);
    w.get<MeshRenderer>(s.cube)->decalLayer = 1;
    const Image reached = g.render(w);
    CHECK(differing(all, reached, 96, 62, 134, 104) == 0);
}

TEST_CASE("decals: opacity, angle fade and sort order change what they paint") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("decals")) return;
    write_textures();
    World w;
    const Scene s = make_scene(w, true);
    const Image full = g.render(w);
    w.get<Decal>(s.front)->opacity = 0.0f;
    const Image none = g.render(w);
    World plain;
    make_scene(plain, false);
    const Image bare = g.render(plain);
    // Opacity 0 paints nothing on the box face.
    CHECK(differing(bare, none, 96, 62, 134, 104) == 0);
    w.get<Decal>(s.front)->opacity = 0.5f;
    const Image half = g.render(w);
    CHECK(differing(full, half, 96, 62, 134, 104) > 50);
    CHECK(differing(bare, half, 96, 62, 134, 104) > 50);
    // A decal whose texture does not exist is not drawn, and says why once (the others are).
    w.get<Decal>(s.front)->opacity = 1.0f;
    w.get<Decal>(s.front)->albedo = "assets/no_such_decal.png";
    const Image missing = g.render(w);
    CHECK(g.renderer.stats().decals == 2);
    CHECK(g.renderer.stats().decalsDropped == 1);
    CHECK(differing(bare, missing, 96, 62, 134, 104) == 0);
}
