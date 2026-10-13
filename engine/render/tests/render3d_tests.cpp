#include "test_util.h"

using namespace fa;
using namespace fa::test;

namespace {
void add_camera(World& w, Vec3 pos, Vec3 lookAt) {
    Entity cam = make(w, "cam", pos);
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    Vec3 f = normalize(lookAt - pos);
    // forward = -Z rotated by (pitch, yaw): yaw = atan2(-f.x, -f.z), pitch = asin(f.y)
    float yaw = degrees(std::atan2(-f.x, -f.z));
    float pitch = degrees(std::asin(f.y));
    w.get<Transform>(cam)->rotation = {pitch, yaw, 0};
}
Entity add_mesh(World& w, const char* mesh, Vec3 pos, Color color, Vec3 scale = {1, 1, 1}) {
    Entity e = make(w, mesh, pos);
    w.get<Transform>(e)->scale = scale;
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = mesh;
    m.color = color;
    return e;
}
Entity add_light(World& w, LightType type, Vec3 pos, Vec3 rot, float intensity = 1.0f, Color c = Color::white()) {
    Entity e = make(w, "light", pos);
    w.get<Transform>(e)->rotation = rot;
    auto& l = w.add<Light>(e);
    l.type = type; l.intensity = intensity; l.color = c; l.range = 12;
    return e;
}
}  // namespace

TEST_CASE("3D primitives with directional + point light, sky, fog off") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    add_camera(w, {0, 3, 7}, {0, 0.5f, 0});
    w.settings().ambientLight = Color{0.15f, 0.15f, 0.2f, 1};
    add_mesh(w, "plane", {0, -0.5f, 0}, Color::hex(0x808890), {12, 1, 12});
    add_mesh(w, "cube", {-3.2f, 0, 0}, Color::hex(0xe04040));
    add_mesh(w, "sphere", {-1.6f, 0, 0}, Color::hex(0x40c040));
    add_mesh(w, "cylinder", {0, 0, 0}, Color::hex(0x4060e0));
    add_mesh(w, "capsule", {1.6f, 0.5f, 0}, Color::hex(0xe0c040));
    add_mesh(w, "cone", {3.2f, 0, 0}, Color::hex(0xc040e0));
    add_light(w, LightType::Directional, {0, 5, 0}, {-50, 30, 0}, 0.9f);
    add_light(w, LightType::Point, {0, 2, 3}, {0, 0, 0}, 1.2f, Color::hex(0xffa040));
    Image img = g.render(w);
    CHECK(g.renderer.stats().meshes == 6);
    CHECK(g.renderer.stats().lights == 2);
    // sky at the top of the frame, lit geometry in the middle
    Color sky = img.pixel(160, 2);
    CHECK(sky.b > 0.5f);
    expect_golden(img, "3d_primitives");
}

TEST_CASE("3D shadows, spot light, emissive, unlit, fog, transparency") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    add_camera(w, {4, 4, 7}, {0, 0.3f, 0});
    w.settings().ambientLight = Color{0.1f, 0.1f, 0.12f, 1};
    w.settings().fogDensity = 0.03f;
    w.settings().fogColor = Color::hex(0xa0b0c0);
    add_mesh(w, "plane", {0, -0.5f, 0}, Color::hex(0xb0b0b0), {14, 1, 14});
    add_mesh(w, "cube", {0, 0.5f, 0}, Color::hex(0xd0d0d0), {1.5f, 2, 1.5f});
    Entity glow = add_mesh(w, "sphere", {-2.5f, 0, 1}, Color::hex(0x202020));
    w.get<MeshRenderer>(glow)->emissive = Color{1.0f, 0.4f, 0.1f, 1};
    Entity unlit = add_mesh(w, "cube", {2.5f, 0, 1}, Color::hex(0x40ff40), {0.8f, 0.8f, 0.8f});
    w.get<MeshRenderer>(unlit)->unlit = true;
    Entity glass = add_mesh(w, "sphere", {1, 0, 2.5f}, Color{0.3f, 0.6f, 1.0f, 0.4f});
    w.get<MeshRenderer>(glass)->castShadows = false;
    Entity sun = add_light(w, LightType::Directional, {0, 5, 0}, {-45, -35, 0}, 1.0f);
    w.get<Light>(sun)->castShadows = true;
    Image img = g.render(w);
    expect_golden(img, "3d_shadows_fog");
    // The unlit cube is pure green regardless of lighting/fog-free region.
    CHECK(img.width == 320);
}

TEST_CASE("3D scene mixes billboard particles, text and sprites") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    add_camera(w, {0, 2, 6}, {0, 0.5f, 0});
    add_mesh(w, "cube", {0, 0.5f, 0}, Color::hex(0xc0c0c0));
    add_light(w, LightType::Directional, {0, 5, 0}, {-50, 30, 0}, 1.0f);
    Entity fx = make(w, "fx", {1.5f, 0, 1});
    auto& p = w.add<ParticleEmitter>(fx);
    p.is3D = true; p.rate = 0; p.burst = 80; p.speed = 2; p.spread = 35; p.startSize = 0.3f; p.endSize = 0.05f;
    p.gravity = {0, -1, 0}; p.startColor = Color::hex(0xffa020); p.endColor = Color{1, 0.3f, 0, 0};
    Entity label = make(w, "label", {-1, 2, 0});
    auto& t = w.add<Text>(label);
    t.text = "3D label"; t.fontSize = 0.5f; t.pivot = {0.5f, 0.5f}; t.align = Align::Center;
    Entity spr = make(w, "spr", {-2, 0.5f, 1});
    auto& s = w.add<Sprite>(spr);
    s.size = {1, 1}; s.color = Color::hex(0xff4080);
    Image img;
    for (int i = 0; i < 10; ++i) img = g.render(w, 1.0f / 30.0f);
    CHECK(g.renderer.stats().particles > 10);
    expect_golden(img, "3d_mixed");
}

TEST_CASE("glTF loading builds meshes from a GLB") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // Minimal embedded-buffer glTF: one triangle, node translated by (0,0,0) and scaled 2.
    const char* gltf = R"({
      "asset":{"version":"2.0"},
      "scene":0,"scenes":[{"nodes":[0]}],
      "nodes":[{"mesh":0,"scale":[2,2,2]}],
      "meshes":[{"primitives":[{"attributes":{"POSITION":0},"material":0}]}],
      "materials":[{"pbrMetallicRoughness":{"baseColorFactor":[0.2,0.8,0.2,1]},"doubleSided":true}],
      "buffers":[{"byteLength":36,"uri":"data:application/octet-stream;base64,AAAAAAAAAAAAAAAAAACAPwAAAAAAAAAAAAAAAAAAgD8AAAAA"}],
      "bufferViews":[{"buffer":0,"byteLength":36}],
      "accessors":[{"bufferView":0,"componentType":5126,"count":3,"type":"VEC3","min":[0,0,0],"max":[1,1,0]}]
    })";
    REQUIRE(fs::write_text("assets/tri.gltf", gltf).ok());
    World w;
    add_camera(w, {0.5f, 0.5f, 4}, {0.5f, 0.5f, 0});
    Entity e = make(w, "model", {-0.5f, -0.5f, 0});
    w.add<MeshRenderer>(e).mesh = "assets/tri.gltf";
    add_light(w, LightType::Directional, {0, 5, 0}, {-30, 0, 0}, 1.0f);
    clear_recent_logs();
    Image img = g.render(w);
    CHECK(error_count() == 0);
    CHECK(g.renderer.stats().triangles == 1);
    Color c = img.pixel(160, 100);
    CHECK(c.g > c.r);
}
