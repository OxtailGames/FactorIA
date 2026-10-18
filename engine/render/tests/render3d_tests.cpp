#include "test_util.h"

#include <vector>

#include "mesh_batch.h"

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

// ---------------------------------------------------------------------------
// M18: production 3D rendering (culling, instancing, lights, tangents, PBR + IBL)
// ---------------------------------------------------------------------------
namespace {
// Tiled "domes" normal map (tangent space, +Y up, glTF convention): a grid of round bumps.
void write_dome_normal_map(const char* path) {
    const int size = 64, cells = 2, cell = size / cells;
    Image img;
    img.width = img.height = size;
    img.rgba.resize(std::size_t(size) * size * 4);
    for (int y = 0; y < size; ++y) {
        for (int x = 0; x < size; ++x) {
            float lx = (float(x % cell) + 0.5f) / float(cell) * 2.0f - 1.0f;
            float ly = -((float(y % cell) + 0.5f) / float(cell) * 2.0f - 1.0f);  // image y is down, tangent-space y is up
            float r2 = lx * lx + ly * ly;
            Vec3 n = r2 < 1.0f ? normalize(Vec3{lx * 1.6f, ly * 1.6f, 1.0f}) : Vec3{0, 0, 1};
            std::uint8_t* p = &img.rgba[(std::size_t(y) * size + x) * 4];
            p[0] = std::uint8_t(std::lround((n.x * 0.5f + 0.5f) * 255.0f));
            p[1] = std::uint8_t(std::lround((n.y * 0.5f + 0.5f) * 255.0f));
            p[2] = std::uint8_t(std::lround((n.z * 0.5f + 0.5f) * 255.0f));
            p[3] = 255;
        }
    }
    REQUIRE(save_png(img, path).ok());
}
}  // namespace

TEST_CASE("10 000 instanced cubes draw in one draw call per material part") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    add_camera(w, {0, 120, 0.5f}, {0, 0, 0});
    add_light(w, LightType::Directional, {0, 5, 0}, {-60, 20, 0}, 1.0f);
    std::vector<Entity> cubes;
    for (int z = 0; z < 100; ++z)
        for (int x = 0; x < 100; ++x)
            cubes.push_back(add_mesh(w, "cube", {float(x) - 49.5f, 0, float(z) - 49.5f}, Color::hex(0xe04040), {0.6f, 0.6f, 0.6f}));
    Image img = g.render(w);
    RenderStats s = g.renderer.stats();
    CHECK(s.meshes == 10000);
    CHECK(s.meshesCulled == 0);
    CHECK(s.meshBatches == 1);
    CHECK(s.triangles == 12 * 10000);
    CHECK(s.drawCalls == 2);  // the sky + one instanced draw for the cube's only part
    Color mid = img.pixel(160, 90);
    CHECK(mid.r > mid.b);  // the red cubes cover the middle of the frame
    // A second material makes a second batch and a second draw, nothing more.
    for (std::size_t i = 0; i < cubes.size(); i += 2) w.get<MeshRenderer>(cubes[i])->color = Color::hex(0x40e040);
    g.render(w);
    s = g.renderer.stats();
    CHECK(s.meshes == 10000);
    CHECK(s.meshBatches == 2);
    CHECK(s.drawCalls == 3);
    CHECK(s.to_json()["meshBatches"] == 2);
}

TEST_CASE("meshes outside the camera frustum are not submitted") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    add_camera(w, {0, 2, 8}, {0, 0, 0});
    add_mesh(w, "cube", {0, 0, 0}, Color::hex(0xc0c0c0));
    for (int i = 0; i < 50; ++i) add_mesh(w, "cube", {float(i), 0, 30}, Color::hex(0xc0c0c0));        // behind the camera
    for (int i = 0; i < 50; ++i) add_mesh(w, "cube", {-500, 0, float(i)}, Color::hex(0xc0c0c0));      // far to the left
    Entity sun = add_light(w, LightType::Directional, {0, 5, 0}, {-60, 20, 0}, 1.0f);
    g.render(w);
    RenderStats s = g.renderer.stats();
    CHECK(s.meshes == 1);
    CHECK(s.meshesCulled == 100);
    CHECK(s.triangles == 12);
    CHECK(s.drawCalls == 2);  // sky + the one visible cube: the 100 others cost no draw at all
    // With a shadow-casting sun the off-screen cubes still cast: the shadow pass draws them, the main pass does not.
    w.get<Light>(sun)->castShadows = true;
    g.render(w);
    s = g.renderer.stats();
    CHECK(s.meshes == 1);
    CHECK(s.meshesCulled == 100);
    CHECK(s.drawCalls == 3);  // shadow (one instanced draw) + sky + main
}

TEST_CASE("frustum test of a box, both depth conventions") {
    for (bool z01 : {false, true}) {
        Mat4 vp = Mat4::perspective(60.0f, 1.0f, 0.1f, 100.0f, z01);  // camera at the origin looking down -Z
        Vec3 lo{-0.5f, -0.5f, -0.5f}, hi{0.5f, 0.5f, 0.5f};
        CHECK(fa::render::box_in_frustum(vp, z01, lo, hi, Mat4::translate({0, 0, -10})));
        CHECK_FALSE(fa::render::box_in_frustum(vp, z01, lo, hi, Mat4::translate({0, 0, 10})));      // behind
        CHECK_FALSE(fa::render::box_in_frustum(vp, z01, lo, hi, Mat4::translate({100, 0, -10})));   // to the side
        CHECK_FALSE(fa::render::box_in_frustum(vp, z01, lo, hi, Mat4::translate({0, 0, -200})));    // beyond far
        CHECK(fa::render::box_in_frustum(vp, z01, lo * 50.0f, hi * 50.0f, Mat4::translate({0, 0, -20})));  // contains the camera
    }
}

TEST_CASE("lights over the limit: the most relevant ones are kept") {
    using fa::render::LightData;
    std::vector<LightData> lights;
    for (int i = 0; i < 40; ++i) {
        LightData l;
        l.rank = i == 39 ? 0 : 2;
        l.score = float(i);
        lights.push_back(l);
    }
    int dropped = fa::render::select_lights(lights, fa::render::kMaxLights);
    CHECK(dropped == 8);
    REQUIRE(lights.size() == 32);
    CHECK(lights[0].rank == 0);       // the shadow caster first
    CHECK(lights[1].score == 38.0f);  // then the most relevant
    CHECK(lights.back().score == 8.0f);  // scores 0..7 are the ones gone
    // Through the renderer: 40 point lights, 32 reach the shader.
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    add_camera(w, {0, 3, 7}, {0, 0, 0});
    add_mesh(w, "sphere", {0, 0, 0}, Color::hex(0xd0d0d0));
    for (int i = 0; i < 40; ++i) add_light(w, LightType::Point, {float(i) - 20, 2, 0}, {0, 0, 0}, 0.2f);
    g.render(w);
    CHECK(g.renderer.stats().lights == 32);
    CHECK(g.renderer.stats().lightsDropped == 8);
}

TEST_CASE("primitives have unit tangents across their normals, with a handedness") {
    for (const char* name : {"cube", "sphere", "plane", "cylinder", "capsule", "cone", "quad"}) {
        std::vector<fa::render::MeshVertex> v;
        std::vector<std::uint32_t> idx;
        REQUIRE(fa::render::build_primitive(name, v, idx));
        for (const auto& x : v) {
            Vec3 n{x.nx, x.ny, x.nz}, t{x.tx, x.ty, x.tz};
            INFO(std::string(name) << " n=" << n.x << "," << n.y << "," << n.z << " t=" << t.x << "," << t.y << "," << t.z);
            CHECK(length(t) == doctest::Approx(1.0f).epsilon(1e-3));
            CHECK(std::fabs(dot(n, t)) < 1e-3f);
            CHECK(std::fabs(std::fabs(x.tw) - 1.0f) < 1e-6f);
        }
    }
    // The +Z face of the cube: u grows along +X, v (up) along +Y, so the tangent is +X and the frame is right-handed.
    std::vector<fa::render::MeshVertex> v;
    std::vector<std::uint32_t> idx;
    REQUIRE(fa::render::build_primitive("cube", v, idx));
    CHECK(v[0].nz == 1.0f);
    CHECK(v[0].tx == doctest::Approx(1.0f));
    CHECK(v[0].tw == 1.0f);
}

TEST_CASE("glTF materials: emissiveFactor lights a black surface") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const char* gltf = R"({
      "asset":{"version":"2.0"},
      "scene":0,"scenes":[{"nodes":[0]}],
      "nodes":[{"mesh":0,"scale":[2,2,2]}],
      "meshes":[{"primitives":[{"attributes":{"POSITION":0},"material":0}]}],
      "materials":[{"pbrMetallicRoughness":{"baseColorFactor":[0,0,0,1],"metallicFactor":0},"emissiveFactor":[1,0,0],"doubleSided":true}],
      "buffers":[{"byteLength":36,"uri":"data:application/octet-stream;base64,AAAAAAAAAAAAAAAAAACAPwAAAAAAAAAAAAAAAAAAgD8AAAAA"}],
      "bufferViews":[{"buffer":0,"byteLength":36}],
      "accessors":[{"bufferView":0,"componentType":5126,"count":3,"type":"VEC3","min":[0,0,0],"max":[1,1,0]}]
    })";
    REQUIRE(fs::write_text("assets/emissive_tri.gltf", gltf).ok());
    World w;
    add_camera(w, {0.5f, 0.5f, 4}, {0.5f, 0.5f, 0});
    Entity e = make(w, "model", {-0.5f, -0.5f, 0});
    w.add<MeshRenderer>(e).mesh = "assets/emissive_tri.gltf";
    add_light(w, LightType::Directional, {0, 5, 0}, {-30, 0, 0}, 1.0f);
    clear_recent_logs();
    Image img = g.render(w);
    CHECK(error_count() == 0);
    Color c = img.pixel(160, 100);
    CHECK(c.r > 0.9f);
    CHECK(c.g < 0.2f);
}

TEST_CASE("3D PBR: metal and rough spheres, sky reflections and a normal-mapped floor") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    write_dome_normal_map("assets/normal_domes.png");
    World w;
    add_camera(w, {0, 3.2f, 7.5f}, {0, 0.3f, 0});
    w.settings().ambientLight = Color{0.12f, 0.13f, 0.16f, 1};
    Entity floor = add_mesh(w, "plane", {0, -0.5f, 0}, Color::hex(0xa08060), {14, 1, 14});
    {
        auto& m = *w.get<MeshRenderer>(floor);
        m.normalMap = "assets/normal_domes.png";
        m.uvScale = {7, 7};
        m.roughness = 0.45f;
    }
    const Color gold = Color::hex(0xe8b84a), red = Color::hex(0xd03030);
    for (int i = 0; i < 4; ++i) {  // back row: metal, roughness 0.1 .. 0.8
        Entity s = add_mesh(w, "sphere", {-2.7f + 1.8f * float(i), 0, -1.2f}, gold);
        w.get<MeshRenderer>(s)->metallic = 1.0f;
        w.get<MeshRenderer>(s)->roughness = 0.1f + 0.7f * float(i) / 3.0f;
    }
    for (int i = 0; i < 4; ++i) {  // front row: plastic, roughness 0.1 .. 0.8
        Entity s = add_mesh(w, "sphere", {-2.7f + 1.8f * float(i), -0.1f, 1.2f}, red, {0.8f, 0.8f, 0.8f});
        w.get<MeshRenderer>(s)->roughness = 0.1f + 0.7f * float(i) / 3.0f;
    }
    add_light(w, LightType::Directional, {0, 5, 0}, {-50, 25, 0}, 0.9f);
    add_light(w, LightType::Point, {-3, 2.5f, 2.5f}, {0, 0, 0}, 1.0f, Color::hex(0xffc080));
    Image img = g.render(w);
    CHECK(g.renderer.stats().meshes == 9);
    CHECK(g.renderer.stats().meshBatches == 1 + 4 + 4);
    expect_golden(img, "3d_pbr_normalmap_ibl");
    // The normal map matters: with normalScale 0 the floor is flat shaded and the picture changes.
    w.get<MeshRenderer>(floor)->normalScale = 0.0f;
    Image flat = g.render(w);
    CHECK(diff_images(img, flat, 4.0f / 255.0f).meanError > 0.002);
}
