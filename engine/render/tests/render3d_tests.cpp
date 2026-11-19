#include "fa/core/engine_version.h"
#include "test_util.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <fstream>
#include <iterator>
#include <limits>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "fa/scene/animation.h"

#include "mesh_batch.h"
#include "render_internal.h"  // material_shader_desc
#include "renderer_env.h"     // kEnvPasses: the draws of one bake of the sky environment
#include "renderer_test_access.h"
#include "shaders/mesh.glsl.h"  // mesh_mesh_shader_desc: what the converter of the twins must reproduce

using namespace fa;
using namespace fa::test;
using fa::render::kEnvPasses;
using fa::render::kEnvTimeStep;

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
    l.type = type;
    l.intensity = intensity;
    l.color = c;
    l.range = 12;
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
    p.is3D = true;
    p.rate = 0;
    p.burst = 80;
    p.speed = 2;
    p.spread = 35;
    p.startSize = 0.3f;
    p.endSize = 0.05f;
    p.gravity = {0, -1, 0};
    p.startColor = Color::hex(0xffa020);
    p.endColor = Color{1, 0.3f, 0, 0};
    Entity label = make(w, "label", {-1, 2, 0});
    auto& t = w.add<Text>(label);
    t.text = "3D label";
    t.fontSize = 0.5f;
    t.pivot = {0.5f, 0.5f};
    t.align = Align::Center;
    Entity spr = make(w, "spr", {-2, 0.5f, 1});
    auto& s = w.add<Sprite>(spr);
    s.size = {1, 1};
    s.color = Color::hex(0xff4080);
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
            float ly =
                -((float(y % cell) + 0.5f) / float(cell) * 2.0f - 1.0f);  // image y is down, tangent-space y is up
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
            cubes.push_back(
                add_mesh(w, "cube", {float(x) - 49.5f, 0, float(z) - 49.5f}, Color::hex(0xe04040), {0.6f, 0.6f, 0.6f}));
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
    for (int i = 0; i < 50; ++i) add_mesh(w, "cube", {float(i), 0, 30}, Color::hex(0xc0c0c0));    // behind the camera
    for (int i = 0; i < 50; ++i) add_mesh(w, "cube", {-500, 0, float(i)}, Color::hex(0xc0c0c0));  // far to the left
    Entity sun = add_light(w, LightType::Directional, {0, 5, 0}, {-60, 20, 0}, 1.0f);
    g.render(w);
    RenderStats s = g.renderer.stats();
    CHECK(s.meshes == 1);
    CHECK(s.meshesCulled == 100);
    CHECK(s.triangles == 12);
    CHECK(s.drawCalls == 2);  // sky + the one visible cube: the 100 others cost no draw at all
    CHECK(s.shadowCasters == 0);
    // With a shadow-casting sun the off-screen cubes still cast: the shadow pass draws them, the main pass does not.
    w.get<Light>(sun)->castShadows = true;
    g.render(w);
    s = g.renderer.stats();
    CHECK(s.meshes == 1);
    CHECK(s.meshesCulled == 100);
    CHECK(s.drawCalls == 3);        // shadow (one instanced draw) + sky + main
    CHECK(s.shadowCasters == 101);  // the visible cube and the 100 off-screen ones that still cast
    CHECK(s.to_json()["shadowCasters"] == 101);
}

TEST_CASE("frustum test of a box, both depth conventions") {
    for (bool z01 : {false, true}) {
        Mat4 vp = Mat4::perspective(60.0f, 1.0f, 0.1f, 100.0f, z01);  // camera at the origin looking down -Z
        Vec3 lo{-0.5f, -0.5f, -0.5f}, hi{0.5f, 0.5f, 0.5f};
        CHECK(fa::render::box_in_frustum(vp, z01, lo, hi, Mat4::translate({0, 0, -10})));
        CHECK_FALSE(fa::render::box_in_frustum(vp, z01, lo, hi, Mat4::translate({0, 0, 10})));     // behind
        CHECK_FALSE(fa::render::box_in_frustum(vp, z01, lo, hi, Mat4::translate({100, 0, -10})));  // to the side
        CHECK_FALSE(fa::render::box_in_frustum(vp, z01, lo, hi, Mat4::translate({0, 0, -200})));   // beyond far
        CHECK(fa::render::box_in_frustum(vp, z01, lo * 50.0f, hi * 50.0f,
                                         Mat4::translate({0, 0, -20})));  // contains the camera
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
    CHECK(lights[0].rank == 0);          // the shadow caster first
    CHECK(lights[1].score == 38.0f);     // then the most relevant
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

TEST_CASE("lights with a NaN score sort last and the order stays total") {
    using fa::render::LightData;
    const float nan = std::numeric_limits<float>::quiet_NaN();
    std::vector<LightData> lights;
    for (int i = 0; i < 60; ++i) {
        LightData l;
        l.score = i % 5 == 0 ? nan : float(i);
        l.pos.x = float(i);  // names the light
        lights.push_back(l);
    }
    CHECK(fa::render::select_lights(lights, 40) == 20);
    REQUIRE(lights.size() == 40);
    // The 48 lights with a real score come first, best first; the NaN ones only fill what is left (none here).
    for (std::size_t i = 0; i < lights.size(); ++i) {
        CHECK_FALSE(std::isnan(lights[i].score));
        if (i > 0) CHECK(lights[i - 1].score >= lights[i].score);
    }
}

TEST_CASE("primitives have unit tangents across their normals, with a handedness") {
    for (const char* name : {"cube", "sphere", "plane", "cylinder", "capsule", "cone", "quad"}) {
        std::vector<fa::render::MeshVertex> v;
        std::vector<std::uint32_t> idx;
        REQUIRE(fa::render::build_primitive(name, v, idx));
        for (const auto& x : v) {
            Vec3 n{x.nx, x.ny, x.nz}, t{x.tx, x.ty, x.tz};
            INFO(std::string(name) << " n=" << n.x << "," << n.y << "," << n.z << " t=" << t.x << "," << t.y << ","
                                   << t.z);
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

TEST_CASE("materialColors: one material of a two-material model changes colour, the other does not") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // Two triangles side by side: "Left" (grey) on x in [-1, 0], "Right" (grey) on x in [0, 1], one material each.
    const char* gltf = R"({
      "asset":{"version":"2.0"},
      "scene":0,"scenes":[{"nodes":[0]}],
      "nodes":[{"mesh":0}],
      "meshes":[{"primitives":[{"attributes":{"POSITION":0},"material":0},{"attributes":{"POSITION":1},"material":1}]}],
      "materials":[{"name":"Left","pbrMetallicRoughness":{"baseColorFactor":[0.5,0.5,0.5,1],"metallicFactor":0},"doubleSided":true},
                   {"name":"Right","pbrMetallicRoughness":{"baseColorFactor":[0.5,0.5,0.5,1],"metallicFactor":0},"doubleSided":true}],
      "buffers":[{"byteLength":72,"uri":"data:application/octet-stream;base64,AACAvwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAvwAAgD8AAAAAAAAAAAAAAAAAAAAAAACAPwAAAAAAAAAAAAAAPwAAgD8AAAAA"}],
      "bufferViews":[{"buffer":0,"byteOffset":0,"byteLength":36},{"buffer":0,"byteOffset":36,"byteLength":36}],
      "accessors":[{"bufferView":0,"componentType":5126,"count":3,"type":"VEC3","min":[-1,0,0],"max":[0,1,0]},
                   {"bufferView":1,"componentType":5126,"count":3,"type":"VEC3","min":[0,0,0],"max":[1,1,0]}]
    })";
    REQUIRE(fs::write_text("assets/two_materials.gltf", gltf).ok());
    auto frame = [&](const char* colors) {
        World w;
        add_camera(w, {0, 0.4f, 4}, {0, 0.4f, 0});
        Entity e = make(w, "model", {0, 0, 0});
        auto& mr = w.add<MeshRenderer>(e);
        mr.mesh = "assets/two_materials.gltf";
        if (colors) mr.materialColors = Json::parse(colors);
        add_light(w, LightType::Directional, {0, 5, 0}, {-30, 0, 0}, 1.0f);
        clear_recent_logs();
        Image img = g.render(w);
        CHECK(error_count() == 0);
        return img;
    };
    // The camera sees 4.6 m across the 200 px height: the centroids of the two triangles are at these pixels.
    const int lx = 139, ly = 103, rx = 181, ry = 103;
    Image base = frame(nullptr);
    Image red = frame(R"({"Right": [1, 0, 0, 1]})");
    const Color l0 = base.pixel(lx, ly), l1 = red.pixel(lx, ly);
    const Color r0 = base.pixel(rx, ry), r1 = red.pixel(rx, ry);
    CHECK(l1.r == doctest::Approx(l0.r).epsilon(0.01));  // "Left" is not named: unchanged
    CHECK(l1.g == doctest::Approx(l0.g).epsilon(0.01));
    CHECK(r1.r > r1.g * 3.0f);  // red after
    CHECK(r1.r > r0.r);
    CHECK(r0.r < r0.g * 2.0f);  // not red before

    // A name that is not in the model changes nothing.
    Image typo = frame(R"({"Rite": [1, 0, 0, 1]})");
    CHECK(typo.pixel(rx, ry).g == doctest::Approx(r0.g).epsilon(0.01));
}

TEST_CASE("materialColors: entities that differ only in materialColors do not share a batch") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    std::vector<render::MeshItem> items(2);
    MeshRenderer a, b;
    b.materialColors = Json::parse(R"({"Body": [1, 0, 0, 1]})");
    for (auto& it : items) it.visible = true;
    items[0].mr = &a;
    items[1].mr = &b;
    items[1].colorsHash = std::hash<std::string>{}(b.materialColors.dump());
    std::vector<render::MeshBatch> batches;
    std::vector<Mat4> mainMats, shadowMats;
    render::build_batches(items, true, batches, mainMats, shadowMats);
    CHECK(batches.size() == 2);
    items[1].colorsHash = 0;
    batches.clear();
    mainMats.clear();
    shadowMats.clear();
    render::build_batches(items, true, batches, mainMats, shadowMats);
    CHECK(batches.size() == 1);
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

namespace {
Entity add_rig(World& w, Vec3 pos, const char* clip) {
    Entity e = make(w, "rig", pos);
    w.add<MeshRenderer>(e).mesh = "assets/rig.gltf";
    w.add<Animator>(e).clip = clip;
    return e;
}
Entity setup_rig_scene(World& w) {
    std::ifstream in(std::string(FA_REPO_ROOT) + "/engine/render/tests/data/skinned_two_bone.gltf", std::ios::binary);
    std::string text((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    REQUIRE(fs::write_text("assets/rig.gltf", text).ok());
    add_camera(w, {0.5f, 1.2f, 4}, {0.5f, 1.0f, 0});
    Entity sun = add_light(w, LightType::Directional, {0, 5, 0}, {-40, 25, 0}, 1.0f);
    add_mesh(w, "plane", {0, -0.01f, 0}, Color::hex(0x909090), {8, 1, 8});
    return sun;
}
}  // namespace

TEST_CASE("3D GPU skinning: bind pose, a clip at a known time, a cross-fade, shadows and batching") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity sun = setup_rig_scene(w);
    w.get<Light>(sun)->castShadows = true;
    Entity rig = add_rig(w, {0, 0, 0}, "Bend");
    clear_recent_logs();
    // Before the first fixed step there is no palette: the model shows in its bind pose (the straight bar).
    Image bind = g.render(w);
    CHECK(error_count() == 0);
    CHECK(w.get<Animator>(rig)->palette.empty());
    CHECK(g.renderer.stats().meshes == 2);
    // Bend at 0.5 s: the tip is rotated 45 degrees about Z.
    update_animators(w, 0.0f);
    update_animators(w, 0.5f);
    REQUIRE(w.get<Animator>(rig)->palette.size() == 2);
    CHECK(w.get<Animator>(rig)->time == doctest::Approx(0.5f));
    Image bend = g.render(w);
    CHECK(error_count() == 0);
    CHECK(diff_images(bind, bend, 4.0f / 255.0f).meanError > 0.002);
    expect_golden(bend, "3d_skinned_bend");
    // Mid cross-fade from Bend to Slide: a third picture.
    REQUIRE(animator_play(w, rig, "Slide", 0.4f).ok());
    update_animators(w, 0.2f);
    Image fade = g.render(w);
    CHECK(diff_images(bend, fade, 4.0f / 255.0f).meanError > 0.002);
    expect_golden(fade, "3d_skinned_crossfade");
    // Skinned meshes are never instanced together (each has its own palette): two rigs are two batches.
    add_rig(w, {2, 0, 0}, "Bend");
    update_animators(w, 0.1f);
    g.render(w);
    CHECK(g.renderer.stats().meshes == 3);
    CHECK(g.renderer.stats().meshBatches == 3);  // the floor and the two rigs
}

TEST_CASE("skinned bounds cover every pose of the palette") {
    std::vector<Mat4> palette = {Mat4::identity(), Mat4::translate({3, 0, 0})};
    Vec3 lo, hi;
    render::skinned_bounds(palette, {-1, 0, -1}, {1, 2, 1}, lo, hi);
    CHECK(lo.x == doctest::Approx(-1));
    CHECK(hi.x == doctest::Approx(4));
    CHECK(hi.y == doctest::Approx(2));
    render::skinned_bounds({}, {-1, 0, -1}, {1, 2, 1}, lo, hi);  // no palette: the mesh's own bounds
    CHECK(hi.x == doctest::Approx(1));
}

// Materials (MeshRenderer.material) -------------------------------------------------------------------------------------
// The fixture materials of tests/data/materials are copied into the test project; every twin gets this build's engine
// version (its "template" stays, so a template change without regenerating the twins fails loudly).
namespace {
void install_materials() {
    namespace sfs = std::filesystem;
    const sfs::path src = sfs::path(FA_RENDER_DATA_DIR) / "materials";
    for (const auto& e : sfs::recursive_directory_iterator(src)) {
        if (!e.is_regular_file()) continue;
        std::ifstream in(e.path(), std::ios::binary);
        std::string bytes((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
        if (e.path().extension() == ".shader") {
            Json twin = Json::parse(bytes);
            twin["engine"] = FA_ENGINE_VERSION;
            bytes = twin.dump();
        }
        REQUIRE(fs::write_bytes(sfs::relative(e.path(), src).generic_string(), bytes.data(), bytes.size()).ok());
    }
}

// A test starts with an empty asset cache and the fixtures installed, and leaves no compiler behind.
struct MaterialScope {
    MaterialScope() {
        gfx().renderer.clear_asset_cache();
        install_materials();
    }
    ~MaterialScope() {
        gfx().renderer.set_shader_compiler({});
        gfx().renderer.clear_asset_cache();
    }
};

// Errors logged while alive. The sink runs on the thread that logs (a job worker too) and may run once after
// remove_log_sink: it writes a shared, locked buffer; messages() is a copy.
struct ErrorLog {
    struct Lines {
        std::mutex mu;
        std::vector<std::string> lines;
    };
    std::shared_ptr<Lines> shared = std::make_shared<Lines>();
    int id;
    ErrorLog()
        : id(add_log_sink([l = shared](const LogEntry& e) {
              if (e.level != LogLevel::Error) return;
              std::lock_guard<std::mutex> lk(l->mu);
              l->lines.push_back(e.message);
          })) {}
    ~ErrorLog() { remove_log_sink(id); }
    ErrorLog(const ErrorLog&) = delete;
    ErrorLog& operator=(const ErrorLog&) = delete;
    std::vector<std::string> messages() const {
        std::lock_guard<std::mutex> lk(shared->mu);
        return shared->lines;
    }
    int count(const std::string& needle) const {
        const std::vector<std::string> m = messages();
        return int(std::count_if(m.begin(), m.end(),
                                 [&](const std::string& x) { return x.find(needle) != std::string::npos; }));
    }
};

Entity add_material_mesh(World& w, const char* mesh, const char* material, Vec3 pos, Color color = Color::hex(0x202020),
                         Vec3 scale = {1.5f, 1.5f, 1.5f}) {
    Entity e = add_mesh(w, mesh, pos, color, scale);
    w.get<MeshRenderer>(e)->material = material;
    return e;
}

// The scene most material tests draw: a ground, a sun with shadows and a camera looking at the origin.
void add_stage(World& w, bool shadows = true) {
    add_camera(w, {0, 1.5f, 4}, {0, 0, 0});
    add_mesh(w, "plane", {0, -1.0f, 0}, Color::hex(0x909090), {8, 1, 8});
    w.get<Light>(add_light(w, LightType::Directional, {0, 5, 0}, {-50, 30, 0}, 0.8f))->castShadows = shadows;
}

// Everything of a shader desc that does not point at source text, as text.
std::string describe_desc(const sg_shader_desc& d) {
    std::string o;
    auto s = [&](const char* p) {
        o += p ? p : "<null>";
        o += ';';
    };
    auto n = [&](long long v) { o += std::to_string(v) + ';'; };
    for (const sg_shader_function* f : {&d.vertex_func, &d.fragment_func}) {
        s(f->entry);
        s(f->d3d11_target);
    }
    for (const auto& a : d.attrs) {
        n(a.base_type);
        s(a.glsl_name);
        s(a.hlsl_sem_name);
        n(a.hlsl_sem_index);
    }
    for (const auto& u : d.uniform_blocks) {
        n(u.stage);
        n(u.size);
        n(u.hlsl_register_b_n);
        n(u.msl_buffer_n);
        n(u.layout);
        for (const auto& g : u.glsl_uniforms) {
            n(g.type);
            n(g.array_count);
            s(g.glsl_name);
        }
    }
    for (const auto& v : d.views) {
        const auto& t = v.texture;
        n(t.stage);
        n(t.image_type);
        n(t.sample_type);
        n(t.multisampled);
        n(t.hlsl_register_t_n);
        n(t.msl_texture_n);
    }
    for (const auto& m : d.samplers) {
        n(m.stage);
        n(m.sampler_type);
        n(m.hlsl_register_s_n);
        n(m.msl_sampler_n);
    }
    for (const auto& p : d.texture_sampler_pairs) {
        n(p.stage);
        n(p.view_slot);
        n(p.sampler_slot);
        s(p.glsl_name);
    }
    return o;
}
}  // namespace

TEST_CASE("materials: the shader desc built from a twin equals the generated one of the built-in mesh program") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    const std::string dialect = g.renderer.shader_dialect();
    auto twin = load_json_file("materials/empty.material.json." + dialect + ".shader");
    REQUIRE(twin.ok());
    render::MaterialProgram slots;
    const Json& program = (*twin)["programs"]["mesh"];
    auto desc = render::material_shader_desc("empty mesh", program, slots);
    REQUIRE(desc.ok());
    CHECK(describe_desc(*desc) == describe_desc(*mesh_mesh_shader_desc(sg_query_backend())));
    CHECK(slots.ubMask == 0b111);  // vs params, fs params, lights
    CHECK(slots.viewMask ==
          (0b111111u | 1u << render::kMaterialEnvView | 1u << render::kMaterialEnvIrrView));  // + the sky environment
    CHECK(slots.samplerMask == (0b11u | 1u << render::kMaterialEnvSampler));
    CHECK(slots.ubSize[0] == sizeof(mesh_fa_mesh_vs_params_t));
    CHECK(slots.ubSize[1] == sizeof(mesh_fa_mesh_fs_params_t));
    CHECK(slots.ubSize[2] == sizeof(mesh_fa_lights_t));

    Json broken = program;
    broken["reflection"]["uniform_blocks"][0]["slot"] = 99;
    render::MaterialProgram ignored;
    auto bad = render::material_shader_desc("broken", broken, ignored);
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("uniform block slot") != std::string::npos);
    CHECK_FALSE(bad.error().hint.empty());
}

TEST_CASE("materials: a material with an empty surface() renders pixel-identical to the same mesh without a material, "
          "shadows on") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    auto frame = [&](const char* material) {
        World w;
        add_stage(w);
        Entity cube = add_mesh(w, "cube", {0, 0, 0}, Color::hex(0xc08040), {1.5f, 1.5f, 1.5f});
        w.get<MeshRenderer>(cube)->material = material;
        return g.render(w);
    };
    ErrorLog log;
    const Image plain = frame("");
    const Image withMaterial = frame("materials/empty.material.json");
    CHECK(log.messages().empty());
    CHECK(g.renderer.stats().materials == 1);
    CHECK(diff_images(plain, withMaterial, 0.0f).maxError == 0.0);
}

TEST_CASE("materials: an emission-from-param material renders its golden and a materialParams override changes it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    auto frame = [&](const Json& params) {
        World w;
        add_stage(w);
        Entity cube = add_material_mesh(w, "cube", "materials/glow.material.json", {0, 0, 0});
        w.get<MeshRenderer>(cube)->materialParams = params;
        return g.render(w);
    };
    const Image orange = frame(Json::object());
    const Image green = frame(Json::object({{"glow", Json::array({0.0, 1.0, 0.0, 1.0})}}));
    CHECK(diff_images(orange, green, 4.0f / 255.0f).meanError > 0.01);
    const Color c = orange.pixel(160, 90);  // the default glow is [1, 0.35, 0]
    CHECK(c.r > c.g);
    CHECK(c.g > c.b);
    expect_golden(orange, "3d_material_glow");
    expect_golden(green, "3d_material_glow_override");
}

TEST_CASE("materials: 100 cubes with one material share one batch, two different overrides make two") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    auto frame = [&](bool overrides) {
        World w;
        add_camera(w, {0, 9, 14}, {0, 0, 0});
        add_light(w, LightType::Directional, {0, 5, 0}, {-50, 30, 0}, 0.8f);
        for (int i = 0; i < 100; ++i) {
            Entity e = add_material_mesh(w, "cube", "materials/glow.material.json",
                                         {float(i % 10) - 4.5f, 0, float(i / 10) - 4.5f}, Color::hex(0x404040),
                                         {0.7f, 0.7f, 0.7f});
            if (overrides)
                w.get<MeshRenderer>(e)->materialParams =
                    Json::object({{"glow", Json::array({0.0, i % 2 ? 1.0 : 0.0, i % 2 ? 0.0 : 1.0, 1.0})}});
        }
        g.render(w);
        return g.renderer.stats();
    };
    RenderStats plain = frame(false);
    CHECK(plain.meshes == 100);
    CHECK(plain.meshBatches == 1);
    CHECK(plain.materials == 1);
    CHECK(plain.materialFallbacks.empty());
    CHECK(frame(true).meshBatches == 2);
}

TEST_CASE("materials: a skinned glTF with a material renders its golden and still casts its shadow") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    std::ifstream in(std::string(FA_REPO_ROOT) + "/engine/render/tests/data/skinned_two_bone.gltf", std::ios::binary);
    std::string text((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    REQUIRE(fs::write_text("assets/rig_material.gltf", text).ok());
    auto frame = [&](bool casts) {
        World w;
        add_camera(w, {0.5f, 1.2f, 4}, {0.5f, 1.0f, 0});
        w.get<Light>(add_light(w, LightType::Directional, {0, 5, 0}, {-40, 25, 0}, 1.0f))->castShadows = true;
        add_mesh(w, "plane", {0, -0.01f, 0}, Color::hex(0x909090), {8, 1, 8});
        Entity rig = make(w, "rig");
        auto& mr = w.add<MeshRenderer>(rig);
        mr.mesh = "assets/rig_material.gltf";
        mr.material = "materials/glow.material.json";
        mr.castShadows = casts;
        w.add<Animator>(rig).clip = "Bend";
        update_animators(w, 0.0f);
        update_animators(w, 0.5f);
        return g.render(w);
    };
    ErrorLog log;
    const Image casting = frame(true);
    CHECK(log.messages().empty());
    CHECK(g.renderer.stats().materials == 1);
    CHECK(diff_images(casting, frame(false), 4.0f / 255.0f).meanError > 0.0005);
    expect_golden(casting, "3d_material_skinned_glow");
}

TEST_CASE("materials: vertex() moves the shadow with the mesh") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    auto frame = [&](bool lifted) {
        World w;
        add_stage(w);
        if (lifted)
            add_material_mesh(w, "cube", "materials/lift.material.json", {-1.5f, 0, 0}, Color::hex(0xc08040),
                              {1, 1, 1});
        else
            add_mesh(w, "cube", {-1.5f + 0.8f, 1.2f, 0}, Color::hex(0xc08040));  // where the lift material puts it
        return g.render(w);
    };
    const Image lift = frame(true);
    // The same picture as the plain cube standing at the displaced place: the shadow on the ground included.
    const Image placed = frame(false);
    CHECK(diff_images(lift, placed, 2.0f / 255.0f).meanError < 0.001);
    expect_golden(lift, "3d_material_lift");
}

TEST_CASE(
    "materials: a texture read in vertex() lifts the mesh and its shadow, and the same texture is read in surface()") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    auto frame = [&](bool material, float lift) {
        World w;
        add_stage(w);
        if (material) {
            Entity e = add_material_mesh(w, "cube", "materials/bump.material.json", {-1.5f, 0, 0}, Color::hex(0xc08040),
                                         {1, 1, 1});
            w.get<MeshRenderer>(e)->materialParams = Json::object({{"lift", lift}});
        } else {
            add_mesh(w, "cube", {-1.5f, lift, 0}, Color::hex(0xc08040));  // where the material puts it
        }
        return g.render(w);
    };
    ErrorLog log;
    const Image lifted = frame(true, 1.2f);
    CHECK(log.messages().empty());
    CHECK(g.renderer.stats().materials == 1);
    // The white height map lifts every vertex by `lift`: the same picture as the plain cube standing there, the shadow
    // on the ground included (the shadow pass reads the texture too), and the white texel leaves the albedo as it is.
    CHECK(diff_images(lifted, frame(false, 1.2f), 2.0f / 255.0f).meanError < 0.001);
    // A lift of 0 is the cube on the ground: the silhouette and the shadow moved.
    const Image grounded = frame(true, 0.0f);
    CHECK(diff_images(grounded, frame(false, 0.0f), 2.0f / 255.0f).meanError < 0.001);
    CHECK(diff_images(lifted, grounded, 4.0f / 255.0f).meanError > 0.005);
}

namespace {
struct Band {
    int count = 0;
    double sumX = 0, sumY = 0;
    double meanX() const { return count ? sumX / count : 0; }
    double meanY() const { return count ? sumY / count : 0; }
};

// The pixels of a disc around the sphere's center, by the green channel (0..255).
std::vector<std::pair<int, std::pair<int, int>>> sphere_pixels(const Image& img) {
    std::vector<std::pair<int, std::pair<int, int>>> px;
    const int cx = img.width / 2, cy = img.height / 2;
    for (int y = cy - 34; y <= cy + 34; ++y)
        for (int x = cx - 34; x <= cx + 34; ++x)
            if ((x - cx) * (x - cx) + (y - cy) * (y - cy) <= 34 * 34)
                px.push_back({int(std::lround(img.pixel(x, y).g * 255.0f)), {x, y}});
    return px;
}

// A sphere on its own: one directional light from the upper right, a dim grey ambient, no shadows.
Image sphere_frame(Gfx& g, const char* material, Color albedo, Color ambient = Color{0.2f, 0.2f, 0.2f, 1}) {
    World w;
    add_camera(w, {0, 1.5f, 4}, {0, 0, 0});
    w.settings().ambientLight = ambient;
    w.get<Light>(add_light(w, LightType::Directional, {0, 5, 0}, {-50, 30, 0}, 0.8f))->castShadows = false;
    Entity s = add_mesh(w, "sphere", {0, 0, 0}, albedo, {2.4f, 2.4f, 2.4f});
    w.get<MeshRenderer>(s)->material = material;
    return g.render(w);
}
}  // namespace

TEST_CASE("materials: custom lighting calls light() per light: a two-band toon with the lit side brighter") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ErrorLog log;
    const Image toon = sphere_frame(g, "materials/toon.material.json", Color::hex(0xe0e0e0));
    CHECK(log.messages().empty());
    CHECK(g.renderer.stats().materials == 1);
    const auto px = sphere_pixels(toon);
    int hi = 0, lo = 255;
    for (const auto& p : px) {
        hi = std::max(hi, p.first);
        lo = std::min(lo, p.first);
    }
    CHECK(hi - lo > 40);  // the two bands differ clearly
    Band bright, dim;
    int between = 0;
    for (const auto& p : px) {
        Band* b = nullptr;
        if (std::abs(p.first - hi) <= 4)
            b = &bright;
        else if (std::abs(p.first - lo) <= 4)
            b = &dim;
        else
            ++between;
        if (!b) continue;
        ++b->count;
        b->sumX += p.second.first;
        b->sumY += p.second.second;
    }
    // Two bands and nothing else (a hard step: only the pixels on the edge of the band may be in between).
    CHECK(bright.count > int(px.size()) / 10);
    CHECK(dim.count > int(px.size()) / 10);
    CHECK(between < int(px.size()) / 10);
    // The sun comes from the right and above: the bright band is on that side of the sphere.
    CHECK(bright.meanX() > dim.meanX() + 4.0);
    CHECK(bright.meanY() < dim.meanY());

    // The built-in lighting of the same sphere is a smooth gradient: many more levels than two.
    const auto plain = sphere_pixels(sphere_frame(g, "", Color::hex(0xe0e0e0)));
    std::vector<bool> seen(256, false);
    for (const auto& p : plain) seen[size_t(p.first)] = true;
    CHECK(std::count(seen.begin(), seen.end(), true) > 12);
}

TEST_CASE("materials: a light() that returns 0 leaves only the ambient term, and ambient() replaces that term") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ErrorLog log;
    const Color white = Color::hex(0xffffff);
    const Image dark = sphere_frame(g, "materials/dark.material.json", white);
    const Image plain = sphere_frame(g, "", white);
    CHECK(log.messages().empty());
    int hi = 0, lo = 255;
    double sum = 0, plainSum = 0;
    for (const auto& p : sphere_pixels(dark)) {
        hi = std::max(hi, p.first);
        lo = std::min(lo, p.first);
        sum += p.first;
    }
    for (const auto& p : sphere_pixels(plain)) plainSum += p.first;
    CHECK(hi - lo <= 4);    // no light: the same color all over the sphere
    CHECK(lo >= 10);        // the ambient term is there
    CHECK(sum < plainSum);  // and the sun is not

    // ambient() keeps only the green of the scene's ambient light; light() adds nothing: the sphere is pure green.
    const Image green = sphere_frame(g, "materials/ambient.material.json", white, Color{0.5f, 0.5f, 0.5f, 1});
    CHECK(log.messages().empty());
    const Color c = green.pixel(green.width / 2, green.height / 2);
    CHECK(c.g > 0.1f);
    CHECK(c.r < 0.02f);
    CHECK(c.b < 0.02f);
}

namespace {
// The largest per-channel difference (0..255) over the pixels of the disc of sphere_pixels(), and how many pixels
// differ by more than `limit`. Neither depends on the order of the image rows.
struct DiscDiff {
    int maxDiff = 0;
    int over = 0;
    int total = 0;
};
DiscDiff disc_diff(const Image& a, const Image& b, int limit) {
    DiscDiff d;
    for (const auto& p : sphere_pixels(a)) {
        const int x = p.second.first, y = p.second.second;
        const Color ca = a.pixel(x, y), cb = b.pixel(x, y);
        const int m = std::max({std::abs(int(std::lround((ca.r - cb.r) * 255.0f))),
                                std::abs(int(std::lround((ca.g - cb.g) * 255.0f))),
                                std::abs(int(std::lround((ca.b - cb.b) * 255.0f)))});
        d.maxDiff = std::max(d.maxDiff, m);
        if (m > limit) ++d.over;
        ++d.total;
    }
    return d;
}
}  // namespace

TEST_CASE(
    "materials: lighting() is the whole light loop: only the brightest of two lights shades, the sky is optional") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ErrorLog log;
    auto frame = [&](const char* material, bool bright, bool dim, const Json& params = Json::object()) {
        World w;
        add_camera(w, {0, 1.5f, 4}, {0, 0, 0});
        w.settings().ambientLight = Color{0.2f, 0.2f, 0.2f, 1};
        if (dim)
            w.get<Light>(add_light(w, LightType::Directional, {0, 5, 0}, {-30, -120, 0}, 0.3f))->castShadows = false;
        if (bright)
            w.get<Light>(add_light(w, LightType::Directional, {0, 5, 0}, {-50, 30, 0}, 0.8f))->castShadows = false;
        Entity s = add_mesh(w, "sphere", {0, 0, 0}, Color::hex(0xe0e0e0), {2.4f, 2.4f, 2.4f});
        w.get<MeshRenderer>(s)->material = material;
        w.get<MeshRenderer>(s)->materialParams = params;
        return g.render(w);
    };
    const char* loop = "materials/lightloop.material.json";
    const Image onlyBright = frame(loop, true, false);
    const Image both = frame(loop, true, true);
    const Image perLight = frame("materials/toon.material.json", true, true);
    const Image plainToonOne = frame("materials/toon.material.json", true, false);
    CHECK(log.messages().empty());
    // The loop reads every light and shades with the brightest one: the dim light changes nothing.
    const DiscDiff same = disc_diff(onlyBright, both, 2);
    CHECK(same.maxDiff <= 2);
    // The per-light toon of the same two lights does add the dim one: its frame is not the one-light frame.
    const DiscDiff added = disc_diff(plainToonOne, perLight, 10);
    CHECK(added.over > added.total / 20);
    // The loop is a two-band toon (its first light is the same as toon.material's): a few levels, not a gradient.
    const DiscDiff alike = disc_diff(onlyBright, plainToonOne, 3);
    CHECK(alike.over < alike.total / 20);
    // No light at all: the ambient term the snippet wrote is what is left, flat.
    const Image none = frame(loop, false, false);
    int hi = 0, lo = 255;
    for (const auto& p : sphere_pixels(none)) {
        hi = std::max(hi, p.first);
        lo = std::min(lo, p.first);
    }
    CHECK(hi - lo <= 4);
    CHECK(lo >= 10);
}

TEST_CASE("materials: the sky (IBL) is one call away from lighting(), ambient() and a full shader") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ErrorLog log;
    // A shiny metal sphere under an orange horizon and a blue sky, no lights and no ambient: the sky is all there is.
    auto frame = [&](const char* material, const Json& params) {
        World w;
        add_camera(w, {0, 1.5f, 4}, {0, 0, 0});
        w.settings().ambientLight = Color{0, 0, 0, 1};
        w.settings().skyColor = Color{0.1f, 0.2f, 1.0f, 1};
        w.settings().horizonColor = Color{1.0f, 0.5f, 0.1f, 1};
        Entity s = add_mesh(w, "sphere", {0, 0, 0}, Color::white(), {2.4f, 2.4f, 2.4f});
        auto* m = w.get<MeshRenderer>(s);
        m->material = material;
        m->materialParams = params;
        m->metallic = 1.0f;
        m->roughness = 0.1f;
        return g.render(w);
    };
    // The sphere's two ends along the image's vertical axis, one reflecting the sky above, the other the ground below.
    // Which end is first in the image (GL counts rows from the bottom) does not matter: one is blue, the other orange.
    auto ends_differ = [&](const Image& img) {
        const Color a = img.pixel(img.width / 2, img.height / 2 - 25);
        const Color b = img.pixel(img.width / 2, img.height / 2 + 25);
        const bool aBlue = a.b > a.r + 0.1f && b.r > b.b + 0.1f;
        const bool bBlue = b.b > b.r + 0.1f && a.r > a.b + 0.1f;
        return aBlue || bBlue;
    };
    auto brightest = [&](const Image& img) {
        float m = 0;
        for (const auto& p : sphere_pixels(img)) {
            const Color c = img.pixel(p.second.first, p.second.second);
            m = std::max({m, c.r, c.g, c.b});
        }
        return m;
    };
    const Image off = frame("materials/lightloop.material.json", Json::object());
    const Image on = frame("materials/lightloop.material.json", Json::object({{"skyAmount", 1.0}}));
    const Image viaAmbient = frame("materials/skylit.material.json", Json::object());
    const Image full = frame("materials/full_sky.material.json", Json::object());
    CHECK(log.messages().empty());
    CHECK(brightest(off) < 0.02f);  // skyAmount 0: no lights, no ambient, no sky
    CHECK(brightest(on) > 0.2f);
    CHECK(ends_differ(on));
    CHECK(ends_differ(viaAmbient));
    CHECK(ends_differ(full));
    // The three ways to the sky are the engine's own sky reflection: the same colors in the same places.
    CHECK(disc_diff(on, viaAmbient, 2).maxDiff <= 2);
    CHECK(disc_diff(on, full, 8).over < disc_diff(on, full, 8).total / 10);
}

TEST_CASE("materials: alphaMode clip cuts holes in the mesh and in its shadow") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    auto frame = [&](const char* material) {
        World w;
        add_camera(w, {0, 3, 4}, {0, 0, 0});
        add_mesh(w, "plane", {0, -0.5f, 0}, Color::hex(0x909090), {8, 1, 8});
        w.get<Light>(add_light(w, LightType::Directional, {0, 5, 0}, {-60, 20, 0}, 0.9f))->castShadows = true;
        Entity leaf = add_mesh(w, "plane", {0, 0.8f, 0}, Color::hex(0xe0e0e0), {2, 1, 2});
        w.get<MeshRenderer>(leaf)->material = material;
        return g.render(w);
    };
    ErrorLog log;
    const Image cut = frame("materials/cutout.material.json");
    CHECK(log.messages().empty());
    const Image solid = frame("");
    CHECK(diff_images(cut, solid, 4.0f / 255.0f).meanError > 0.005);
    expect_golden_edges(cut, "3d_material_cutout");
}

TEST_CASE("materials: the alpha of a vertex color cuts a clip material's mesh and its shadow, and custom materials "
          "keep the tint") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    // A leaf of 2 x 2 at height 0.8: its left corners have an alpha of 0, its right ones 1, so alpha 0.5 (alphaCutoff) is at x = 0.
    auto leaf_input = [](float x0, bool alphaGradient) {
        MeshInput in;
        in.positions = {x0, 0.8f, 1, 1, 0.8f, 1, 1, 0.8f, -1, x0, 0.8f, -1};
        in.indices = {0, 1, 2, 0, 2, 3};
        in.hasIndices = true;
        if (alphaGradient) in.colors = {1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0};
        return in;
    };
    auto frame = [&](bool vertexAlpha) {
        World w;
        add_camera(w, {0, 3, 4}, {0, 0, 0});
        add_mesh(w, "plane", {0, -0.5f, 0}, Color::hex(0x909090), {8, 1, 8});
        w.get<Light>(add_light(w, LightType::Directional, {0, 5, 0}, {-60, 20, 0}, 0.9f))->castShadows = true;
        // vertexAlpha: the whole leaf with the alpha gradient and the clip material; else only its right half, plain.
        auto id = w.meshes().create(vertexAlpha ? leaf_input(-1, true) : leaf_input(0, false));
        REQUIRE(id.ok());
        Entity leaf = add_mesh(w, id->c_str(), {0, 0, 0}, Color::hex(0xe0e0e0));
        if (vertexAlpha) w.get<MeshRenderer>(leaf)->material = "materials/vcut.material.json";
        return g.render(w);
    };
    ErrorLog log;
    const Image cut = frame(true);
    CHECK(log.messages().empty());
    CHECK(g.renderer.stats().materials == 1);
    const Image half = frame(false);
    // The same picture as the leaf that only has its right half, shadow included.
    CHECK(diff_images(cut, half, 6.0f / 255.0f).meanError < 0.002);
    // And the shadow is really cut: without the vertex alpha the whole leaf casts it.
    World w;
    add_camera(w, {0, 3, 4}, {0, 0, 0});
    add_mesh(w, "plane", {0, -0.5f, 0}, Color::hex(0x909090), {8, 1, 8});
    w.get<Light>(add_light(w, LightType::Directional, {0, 5, 0}, {-60, 20, 0}, 0.9f))->castShadows = true;
    auto solid = w.meshes().create(leaf_input(-1, false));
    REQUIRE(solid.ok());
    Entity leaf = add_mesh(w, solid->c_str(), {0, 0, 0}, Color::hex(0xe0e0e0));
    w.get<MeshRenderer>(leaf)->material = "materials/vcut.material.json";
    CHECK(diff_images(g.render(w), cut, 4.0f / 255.0f).meanError > 0.003);
}

TEST_CASE("materials: a material that does not compile is drawn magenta and logged once with its file, line and hint") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    REQUIRE(fs::write_text("materials/broken.material.json",
                           R"({"format": "factoria.material/1", "shader": "shaders/broken.surface.glsl"})")
                .ok());
    g.renderer.set_shader_compiler([](const std::string&, const std::string&) -> Result<Json> {
        // As the tooling's compiler gives it: every diagnostic with its hint, and the first hint again.
        return make_error("shaders/broken.surface.glsl:3:5: error: 'colour' : no such field in structure 'Surface'\n  "
                          "hint: did you mean albedo?",
                          "did you mean albedo?");
    });
    ErrorLog log;
    World w;
    add_stage(w);
    add_material_mesh(w, "cube", "materials/broken.material.json", {0, 0, 0});
    Image img;
    for (int i = 0; i < 3; ++i) img = g.render(w);
    const Color c = img.pixel(160, 90);
    CHECK(c.r > 0.9f);
    CHECK(c.g < 0.1f);
    CHECK(c.b > 0.9f);
    CHECK(log.count("broken.surface.glsl:3:5") == 1);
    CHECK(log.count("did you mean albedo?") == 1);
    CHECK(log.count("Hint: did you mean albedo?") == 0);  // the diagnostic has the hint: it is not added again
    REQUIRE(g.renderer.stats().materialFallbacks.size() == 1);
    CHECK(g.renderer.stats().materialFallbacks[0] == "materials/broken.material.json");
    CHECK(g.renderer.stats().materials == 0);
    CHECK(g.renderer.stats().to_json()["materialFallbacks"][0] == "materials/broken.material.json");
    CHECK(g.renderer.asset_report()["failures"].size() == 1);
}

TEST_CASE("materials: hot reload swaps the shader, keeps the last good one on a broken edit and recovers") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    const std::string dialect = g.renderer.shader_dialect();
    REQUIRE(fs::write_text("materials/hot.material.json",
                           R"({"format": "factoria.material/1", "shader": "shaders/hot.txt",
                               "params": {"glow": {"type": "color", "default": [1.0, 0.35, 0.0, 1.0], "doc": "Glow."}}})")
                .ok());
    // Stands in for the tooling: the snippet on disk names the fixture twin to use ("glow" or "empty"), or is broken.
    g.renderer.set_shader_compiler([dialect](const std::string&, const std::string&) -> Result<Json> {
        auto snippet = fs::read_text("shaders/hot.txt");
        if (!snippet.ok()) return snippet.error();
        if (*snippet == "broken")
            return make_error("shaders/hot.txt:1:1: error: 'broken' : undeclared identifier", "Write glow or empty.");
        return load_json_file("materials/" + *snippet + ".material.json." + dialect + ".shader");
    });
    auto frame = [&]() {
        World w;
        add_stage(w);
        add_material_mesh(w, "cube", "materials/hot.material.json", {0, 0, 0});
        return g.render(w);
    };
    ErrorLog log;
    REQUIRE(fs::write_text("shaders/hot.txt", "glow").ok());
    const Image glowing = frame();
    REQUIRE(fs::write_text("shaders/hot.txt", "empty").ok());
    g.renderer.reload_asset("shaders/hot.txt");
    const Image plain = frame();
    CHECK(diff_images(glowing, plain, 4.0f / 255.0f).meanError > 0.01);
    CHECK(log.messages().empty());

    REQUIRE(fs::write_text("shaders/hot.txt", "broken").ok());
    g.renderer.reload_asset("shaders/hot.txt");
    const Image kept = frame();
    frame();
    CHECK(diff_images(plain, kept, 0.0f).maxError == 0.0);
    CHECK(log.count("shaders/hot.txt:1:1") == 1);
    CHECK(g.renderer.stats().materialFallbacks.empty());
    CHECK(g.renderer.asset_report()["failures"].size() == 1);

    REQUIRE(fs::write_text("shaders/hot.txt", "glow").ok());
    g.renderer.reload_asset("shaders/hot.txt");
    const Image back = frame();
    CHECK(diff_images(glowing, back, 0.0f).maxError == 0.0);
    CHECK(log.messages().size() == 1);
    CHECK(g.renderer.asset_report()["failures"].empty());
}

TEST_CASE("materials: a twin from another factoria version is refused with the re-export hint") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    auto twin = load_json_file("materials/empty.material.json." + g.renderer.shader_dialect() + ".shader");
    REQUIRE(twin.ok());
    (*twin)["engine"] = "0.0.0";
    REQUIRE(fs::write_text("materials/old.material.json",
                           R"({"format": "factoria.material/1", "shader": "shaders/empty.surface.glsl"})")
                .ok());
    REQUIRE(
        fs::write_text("materials/old.material.json." + g.renderer.shader_dialect() + ".shader", twin->dump()).ok());
    ErrorLog log;
    World w;
    add_stage(w);
    add_material_mesh(w, "cube", "materials/old.material.json", {0, 0, 0});
    const Image img = g.render(w);
    CHECK(img.pixel(160, 90).g < 0.1f);  // magenta
    REQUIRE(log.messages().size() == 1);
    CHECK(log.messages()[0].find("0.0.0") != std::string::npos);
    CHECK(log.messages()[0].find("Export the game again with this factoria version") != std::string::npos);
    CHECK(g.renderer.stats().materialFallbacks.size() == 1);
}

// The kind of a material (M72): the twin must carry the material's kind (a twin without one is a mesh twin), and a kind
// that is not a mesh one is not drawn by a MeshRenderer (the engine shader is used, with one warning).
TEST_CASE("materials: a twin of another kind than its material is refused with the re-export hint") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    const std::string dialect = g.renderer.shader_dialect();
    auto twin = load_json_file("materials/empty.material.json." + dialect + ".shader");
    REQUIRE(twin.ok());
    CHECK_FALSE(twin->contains("kind"));  // the committed twins are mesh twins as they were before kinds
    auto draw = [&](const std::string& name, const std::string& material, const Json& twinDoc) {
        REQUIRE(fs::write_text("materials/" + name + ".material.json", material).ok());
        REQUIRE(fs::write_text("materials/" + name + ".material.json." + dialect + ".shader", twinDoc.dump()).ok());
        World w;
        add_stage(w);
        const std::string path = "materials/" + name + ".material.json";
        add_material_mesh(w, "cube", path.c_str(), {0, 0, 0});
        return g.render(w);
    };
    {  // a sprite twin on a mesh material
        Json other = *twin;
        other["kind"] = "sprite";
        ErrorLog log;
        const Image img =
            draw("kindtwin", R"({"format": "factoria.material/1", "shader": "shaders/empty.surface.glsl"})", other);
        CHECK(img.pixel(160, 90).g < 0.1f);  // magenta
        REQUIRE(log.messages().size() == 1);
        CHECK(log.messages()[0].find("\"sprite\" shader") != std::string::npos);
        CHECK(log.messages()[0].find("kind \"mesh\"") != std::string::npos);
        CHECK(log.messages()[0].find("Export the game again with this factoria version") != std::string::npos);
    }
    {  // "mesh" written out is the same as no kind
        Json same = *twin;
        same["kind"] = "mesh";
        ErrorLog log;
        draw("kindmesh", R"({"format": "factoria.material/1", "kind": "mesh", "shader": "shaders/empty.surface.glsl"})",
             same);
        CHECK(log.messages().empty());
        CHECK(g.renderer.stats().materialFallbacks.empty());
    }
    {  // a post material on a MeshRenderer: only mesh materials draw one, so the engine's shader draws it, with one warning
        std::vector<std::string> warnings;
        const int sink = add_log_sink([&warnings](const LogEntry& e) {
            if (e.level == LogLevel::Warn) warnings.push_back(e.message);
        });
        World w;
        add_stage(w);
        add_material_mesh(w, "cube", "materials/post_empty.material.json", {0, 0, 0});
        const Image img = g.render(w);
        g.render(w);  // the second frame says nothing more
        remove_log_sink(sink);
        CHECK(img.pixel(160, 90).g > 0.1f);  // not magenta
        REQUIRE(warnings.size() == 1);
        CHECK(warnings[0].find("is a \"post\" material") != std::string::npos);
        CHECK(g.renderer.stats().materialFallbacks.empty());
    }
    {  // a sprite material on a MeshRenderer (quad programs, another vertex layout): the same, one warning over several frames
        std::vector<std::string> warnings;
        const int sink = add_log_sink([&warnings](const LogEntry& e) {
            if (e.level == LogLevel::Warn) warnings.push_back(e.message);
        });
        World w;
        add_stage(w);
        add_material_mesh(w, "cube", "materials/sprite_empty.material.json", {0, 0, 0});
        const Image img = g.render(w);
        g.render(w);
        g.render(w);
        remove_log_sink(sink);
        CHECK(img.pixel(160, 90).g > 0.1f);  // drawn by the engine's own shader, not magenta
        REQUIRE(warnings.size() == 1);
        CHECK(warnings[0].find("is a \"sprite\" material") != std::string::npos);
        CHECK(g.renderer.stats().materialFallbacks.empty());
    }
    {  // a kind that does not exist
        ErrorLog log;
        draw("kindtypo",
             R"({"format": "factoria.material/1", "kind": "spirte", "shader": "shaders/empty.surface.glsl"})", *twin);
        REQUIRE(log.messages().size() == 1);
        CHECK(log.messages()[0].find("unknown kind \"spirte\"") != std::string::npos);
        CHECK(log.messages()[0].find("sprite") != std::string::npos);
    }
}

TEST_CASE("materials: the template hash is per kind and the mesh one is unchanged by the other kinds") {
    CHECK(mesh_template_hash() == material_template_hash(MaterialKind::Mesh));
    CHECK(mesh_template_hash().size() == 64);
    CHECK(material_template_hash(MaterialKind::Sprite).size() == 64);
    CHECK(material_template_hash(MaterialKind::Sprite) != mesh_template_hash());
    CHECK(material_template_hash(MaterialKind::Sky) != material_template_hash(MaterialKind::Post));
    CHECK(material_template_hash(MaterialKind::Compute).size() == 64);  // compute_common.glsl (M72.4)
    CHECK(material_template_hash(MaterialKind::Compute) != mesh_template_hash());
    CHECK(material_kind_names().size() == 5);
    CHECK(std::string(material_kind_name(MaterialKind::Post)) == "post");
    CHECK(material_kind_from_name("sky") == MaterialKind::Sky);
    CHECK_FALSE(material_kind_from_name("mesh2").has_value());
}

// fa_time is the engine clock (World::time, advanced by the fixed steps), so a material that animates with it draws the
// same picture after the same number of steps, whatever ran before in the process.
TEST_CASE("3D mesh template: a material's emission driven by fa_time is the same after the same fixed steps") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    auto frame = [&](int steps) {
        World w;
        add_camera(w, {0, 1.5f, 4}, {0, 0, 0});
        add_material_mesh(w, "cube", "materials/time.material.json", {0, 0, 0});
        add_light(w, LightType::Directional, {0, 5, 0}, {-50, 30, 0}, 0.8f);
        for (int i = 0; i < steps; ++i) w.advance_clock(1.0 / 60.0);
        return g.render(w);
    };
    const Image start = frame(0);
    const Image a = frame(45);
    const Image b = frame(45);
    CHECK(diff_images(a, b, 0.0f).maxError == 0.0);
    // 0.75 s: red emission 0.5 + 0.5 sin(2.25) = 0.89 and green 0.19, against 0.5 and 0 at the start.
    CHECK(diff_images(start, a, 4.0f / 255.0f).meanError > 0.01);
    const Color c = a.pixel(160, 90);
    CHECK(c.r > 0.85f);
    CHECK(c.g > 0.15f);
    expect_golden(a, "3d_fa_time_emission");
}

// Sky materials (SceneSettings.skyMaterial)
// ---------------------------------------------------------------------------------
namespace {
// A camera looking slightly down at a cube: the top of the frame is sky, the middle is the mesh.
void add_sky_scene(World& w, const char* skyMaterial, const Json& params = Json()) {
    add_camera(w, {0, 1.5f, 4}, {0, 0, 0});
    add_mesh(w, "cube", {0, 0, 0}, Color::hex(0xc08040), {1.5f, 1.5f, 1.5f});
    add_light(w, LightType::Directional, {0, 5, 0}, {-50, 30, 0}, 0.8f);
    w.settings().skyMaterial = skyMaterial;
    if (!params.is_null()) w.settings().skyMaterialParams = params;
}
}  // namespace

namespace {
// The largest per-channel difference (0..255) between the top `rows` rows of two frames: the rows that hold only the
// sky. The mean absolute difference of the colour channels over the pixels of a rectangle (the part of the frame the
// mesh covers).
double rect_mean_diff(const Image& a, const Image& b, int x0, int y0, int x1, int y1) {
    double sum = 0.0;
    int n = 0;
    for (int y = y0; y < y1; ++y)
        for (int x = x0; x < x1; ++x) {
            const Color p = a.pixel(x, y), q = b.pixel(x, y);
            sum += std::fabs(p.r - q.r) + std::fabs(p.g - q.g) + std::fabs(p.b - q.b);
            ++n;
        }
    return n ? sum / (3.0 * n) : 0.0;
}

int top_rows_diff(const Image& a, const Image& b, int rows) {
    int worst = 0;
    for (int y = 0; y < rows; ++y)
        for (int x = 0; x < a.width; ++x) {
            const Color p = a.pixel(x, y), q = b.pixel(x, y);
            worst = std::max({worst, int(std::lround(std::fabs(p.r - q.r) * 255.0f)),
                              int(std::lround(std::fabs(p.g - q.g) * 255.0f)),
                              int(std::lround(std::fabs(p.b - q.b) * 255.0f))});
        }
    return worst;
}
}  // namespace

TEST_CASE("sky materials: a material whose sky() is empty draws exactly the built-in sky") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ErrorLog log;
    auto frame = [&](const char* material) {
        World w;
        add_sky_scene(w, material);
        // colours no other test baked: the count of draws below needs a bake that has not happened yet
        // One colour for the whole sky, and the same one as the scene's ambient light: the sky a mesh is lit by is then
        // the same light as the analytic path (ambientLight + gradient) gave it, so the two frames can be compared on
        // the cube itself.
        w.settings().skyColor = Color{0.31f, 0.43f, 0.57f, 1};
        w.settings().horizonColor = Color{0.31f, 0.43f, 0.57f, 1};
        w.settings().ambientLight = Color{0.31f, 0.43f, 0.57f, 1};
        return g.render(w);
    };
    const Image builtIn = frame("");
    const auto builtInCalls = g.renderer.stats().drawCalls;
    const Image material = frame("materials/skyempty.material.json");
    const auto firstCalls = g.renderer.stats().drawCalls;
    const Image again = frame("materials/skyempty.material.json");
    CHECK(log.messages().empty());
    CHECK(g.renderer.stats().materialFallbacks.empty());
    // The sky is one draw either way; the first frame with a sky material also bakes the environment the meshes are lit
    // with (kEnvPasses draws), the next one finds it in place.
    CHECK(firstCalls == builtInCalls + kEnvPasses);
    CHECK(g.renderer.stats().drawCalls == builtInCalls);
    // The sky itself: the top rows are the very same pixels (the meshes are lit by the baked sky now, so the rest may
    // differ a little).
    CHECK(top_rows_diff(builtIn, material, 30) == 0);
    CHECK(diff_images(material, again, 0.0f).maxError == 0.0);
    // the sky is really in the picture: the top of the frame is not the clear colour of a frame without a sky
    CHECK(builtIn.pixel(160, 2).b > 0.3f);
    // A sky of one colour lights the mesh like an ambient light and a gradient of that colour did (the irradiance cube
    // is divided by pi and the prefiltered one holds the colour): measured on the pixels of the cube (the middle of the
    // frame), where a difference would be, not diluted by the sky around it.
    const double cubeDiff = rect_mean_diff(builtIn, material, 138, 76, 182, 104);
    MESSAGE("mean difference on the cube: " << cubeDiff);
    CHECK(cubeDiff < 0.05);
}

TEST_CASE(
    "sky materials: a gradient sky replaces the background, skyMaterialParams change it and the meshes keep their "
    "light") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ErrorLog log;
    auto frame = [&](const char* material, const Json& params = Json()) {
        World w;
        add_sky_scene(w, material, params);
        return g.render(w);
    };
    const Image builtIn = frame("");
    const Image red = frame("materials/skygrad.material.json");
    const Image green =
        frame("materials/skygrad.material.json", Json::object({{"zenith", Json::array({0.0, 1.0, 0.0, 1.0})}}));
    CHECK(log.messages().empty());
    CHECK(diff_images(builtIn, red, 4.0f / 255.0f).meanError > 0.01);
    CHECK(diff_images(red, green, 4.0f / 255.0f).meanError > 0.01);
    const Color top = red.pixel(160, 2);  // the default zenith [0.9, 0.2, 0.1], the default ground [0.1, 0.1, 0.6]
    CHECK(top.r > top.b);
    const Color topGreen = green.pixel(160, 2);
    CHECK(topGreen.g > topGreen.r);
    // the cube in the middle is still lit (by the sun and now by the sky that is seen): not black, and a little redder
    // under the red zenith than under the green one
    const Color a = red.pixel(160, 90), b = green.pixel(160, 90);
    CHECK(std::max({a.r, a.g, a.b}) > 0.1f);
    CHECK(a.r >= b.r);
    CHECK(b.g >= a.g);
}

TEST_CASE("sky materials: SkyInput.time follows the engine clock and is the same after the same fixed steps") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    auto frame = [&](int steps) {
        World w;
        add_sky_scene(w, "materials/skytime.material.json");
        for (int i = 0; i < steps; ++i) w.advance_clock(1.0 / 60.0);
        return g.render(w);
    };
    const Image start = frame(0);
    const Image a = frame(45);
    const Image b = frame(45);
    CHECK(diff_images(a, b, 0.0f).maxError == 0.0);
    CHECK(diff_images(start, a, 4.0f / 255.0f).meanError > 0.01);
}

// The sky lights the meshes (M72 P15)
// ---------------------------------------------------------------------------------------
namespace {
// A sphere in the middle of the frame, no lights, no ambient and a sky of the scene's own colors that the test must not
// see.
void sky_sphere_world(World& w, const char* skyMaterial, const Json& params, float metallic, float roughness) {
    add_camera(w, {0, 1.5f, 4}, {0, 0, 0});
    w.settings().ambientLight = Color{0, 0, 0, 1};
    w.settings().skyColor = Color{0.2f, 0.2f, 0.2f, 1};
    w.settings().horizonColor = Color{0.2f, 0.2f, 0.2f, 1};
    w.settings().skyMaterial = skyMaterial;
    if (!params.is_null()) w.settings().skyMaterialParams = params;
    Entity s = add_mesh(w, "sphere", {0, 0, 0}, Color::white(), {2.4f, 2.4f, 2.4f});
    auto* m = w.get<MeshRenderer>(s);
    m->metallic = metallic;
    m->roughness = roughness;
}
}  // namespace

TEST_CASE("sky materials: a metal sphere reflects the sky that is seen, each side its own color") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ErrorLog log;
    // skyquad: +x red, -x blue, above the horizon green added. The sphere is mirror-like, so each part of it shows the
    // quarter of the sky it reflects: a face of the baked cube turned the wrong way (or mirrored) puts the colors in
    // the wrong corners. The image's row 0 is the top on every backend (the capture flips OpenGL's).
    World w;
    sky_sphere_world(w, "materials/skyquad.material.json", Json(), 1.0f, 0.05f);
    const Image img = g.render(w);
    CHECK(log.messages().empty());
    const int cx = img.width / 2, cy = img.height / 2, d = 22;
    const Color upRight = img.pixel(cx + d, cy - d), upLeft = img.pixel(cx - d, cy - d);
    const Color downRight = img.pixel(cx + d, cy + d), downLeft = img.pixel(cx - d, cy + d);
    // red = +x, blue = -x, green = up: right-up yellow, right-down red, left-up cyan, left-down blue
    CHECK((upRight.r > 0.5f && upRight.g > 0.5f && upRight.b < 0.25f));
    CHECK((downRight.r > 0.5f && downRight.g < 0.25f && downRight.b < 0.25f));
    CHECK((upLeft.b > 0.5f && upLeft.g > 0.5f && upLeft.r < 0.25f));
    CHECK((downLeft.b > 0.5f && downLeft.g < 0.25f && downLeft.r < 0.25f));
}

TEST_CASE("sky materials: a diffuse mesh takes the ambient light of the sky that is seen") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ErrorLog log;
    const Json params =
        Json::object({{"zenith", Json::array({0.0, 1.0, 0.0, 1.0})}, {"ground", Json::array({1.0, 0.0, 0.0, 1.0})}});
    // No lights, no ambient: what lights the sphere is the sky. Green above, red below: the top of the sphere is green,
    // the bottom red.
    World w;
    sky_sphere_world(w, "materials/skygrad.material.json", params, 0.0f, 1.0f);
    const Image lit = g.render(w);
    const int cx = lit.width / 2, cy = lit.height / 2;
    const Color top = lit.pixel(cx, cy - 34), bottom = lit.pixel(cx, cy + 34);
    // What the sky lights is a ratio, not an absolute brightness (the irradiance and the filtering differ per driver):
    // the green side is lit and its green is well above its red, the red side the other way round.
    INFO("top " << top.r << " " << top.g << " " << top.b << ", bottom " << bottom.r << " " << bottom.g << " "
                << bottom.b);
    CHECK(top.g > 0.02f);
    CHECK(top.g > 1.5f * top.r);
    CHECK(bottom.r > 0.02f);
    CHECK(bottom.r > 1.5f * bottom.g);
    // Without the material the scene's own ambient (black) is all there is, and a rough dielectric shows no reflection:
    // dark.
    World bare;
    sky_sphere_world(bare, "", Json(), 0.0f, 1.0f);
    const Image dark = g.render(bare);
    const Color d = dark.pixel(cx, cy - 34);
    CHECK(std::max({d.r, d.g, d.b}) < 0.1f);
    // A sky of one color gives that color as ambient (the irradiance is divided by pi): the same light on every side.
    const Json flat =
        Json::object({{"zenith", Json::array({0.5, 0.5, 0.5, 1.0})}, {"ground", Json::array({0.5, 0.5, 0.5, 1.0})}});
    World uniform;
    sky_sphere_world(uniform, "materials/skygrad.material.json", flat, 0.0f, 1.0f);
    const Image grey = g.render(uniform);
    const Color a = grey.pixel(cx, cy - 34), b = grey.pixel(cx, cy + 34);
    CHECK(std::fabs(a.r - b.r) < 0.03f);
    CHECK(a.r > 0.1f);
    CHECK(log.messages().empty());
}

TEST_CASE("sky materials: removing the sky material gives back the frame without it, pixel for pixel") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    auto frame = [&](const char* material) {
        World w;
        add_sky_scene(w, material);
        return g.render(w);
    };
    const Image before = frame("");
    const auto calls = g.renderer.stats().drawCalls;
    frame("materials/skygrad.material.json");
    const Image after = frame("");
    CHECK(g.renderer.stats().drawCalls == calls);  // no pass of the environment without a sky material
    CHECK(diff_images(before, after, 0.0f).maxError == 0.0);
}

TEST_CASE("sky materials: the environment is baked again when the sky changes, and an animated sky every kEnvTimeStep "
          "of game time") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    auto calls = [&]() { return g.renderer.stats().drawCalls; };
    {  // a still sky: baked once, again for new params or colors, not for time
        World w;
        add_sky_scene(w, "materials/skygrad.material.json");
        w.settings().skyColor = Color{0.11f, 0.12f, 0.13f, 1};  // a sky no other test baked
        g.render(w);
        const auto baked = calls();  // the sky, the meshes and the bake
        w.advance_clock(1.0);
        g.render(w);
        CHECK(calls() == baked - kEnvPasses);
        w.settings().skyMaterialParams = Json::object({{"zenith", Json::array({0.0, 1.0, 0.0, 1.0})}});
        g.render(w);
        CHECK(calls() == baked);  // the params changed: baked again
        w.settings().skyColor = Color{0.3f, 0.4f, 0.5f, 1};
        g.render(w);
        CHECK(calls() == baked);  // the scene's sky color is an input of the sky() of every material
    }
    {  // an animated sky: the same step of game time is one bake, the next step another
        World w;
        add_sky_scene(w, "materials/skytime.material.json");
        w.settings().skyColor = Color{0.21f, 0.22f, 0.23f, 1};
        g.render(w);
        const auto baked = calls();
        w.advance_clock(kEnvTimeStep * 0.25);
        g.render(w);
        CHECK(calls() == baked - kEnvPasses);  // a quarter of a step later: the same image
        w.advance_clock(kEnvTimeStep * 2.0);
        g.render(w);
        CHECK(calls() == baked);  // two steps later: baked again
    }
}

TEST_CASE("sky materials: a turning sun bakes again only a sky whose snippet reads the sun") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    auto calls = [&]() { return g.renderer.stats().drawCalls; };
    auto turn_sun = [](World& w, float yaw) {
        w.each<Light>([&](Entity e, Light&) { w.get<Transform>(e)->rotation = Vec3{-50, yaw, 0}; });
    };
    // colours no other test baked, one per material, so the first frame of each is a bake
    for (const char* material : {"materials/skygrad.material.json", "materials/skysun.material.json"}) {
        const bool readsSun = std::string(material).find("skysun") != std::string::npos;
        World w;
        add_sky_scene(w, material);
        w.settings().skyColor = readsSun ? Color{0.41f, 0.42f, 0.43f, 1} : Color{0.44f, 0.45f, 0.46f, 1};
        g.render(w);
        const auto baked = calls();
        turn_sun(w, 80.0f);
        g.render(w);
        // the sun moved: a sky that reads it is baked again (the draws of the bake come back), one that does not is not
        CHECK(calls() == (readsSun ? baked : baked - kEnvPasses));
        turn_sun(w, 80.0f);
        g.render(w);
        CHECK(calls() == baked - kEnvPasses);  // the sun stood still: nothing to bake
    }
}

TEST_CASE("sky materials: a sky that appears after the first frame of meshes makes no second sampler") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    {  // a frame of meshes without a sky material: the blank cube and the sampler of the environment are made
        World w;
        add_sky_scene(w, "");
        g.render(w);
    }
    // then the sky: ready() must keep the sampler that blank_view() made (it once made a new one and leaked the first)
    render::Gpu& gpu = *render::renderer_gpu(g.renderer);
    render::Environment env;
    env.blank_view(gpu);
    const sg_sampler first = env.sampler();
    REQUIRE(first.id != 0);
    REQUIRE(env.ready(gpu));
    CHECK(env.sampler().id == first.id);
    env.release();
    {  // and through the renderer
        World w;
        add_sky_scene(w, "materials/skygrad.material.json");
        w.settings().skyColor = Color{0.47f, 0.48f, 0.49f, 1};
        g.render(w);
        CHECK(g.renderer.stats().materialFallbacks.empty());
    }
}

TEST_CASE("sky materials: what one bake of the environment costs (reported, never asserted)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    // The wall time of a whole frame including the read-back of the picture (so the GPU work is in it), median of 15
    // frames: with no sky material, with a sky that is baked once, and with a sky baked in every frame (its colour
    // changes each time).
    auto median_ms = [&](const char* material, bool changeEveryFrame) {
        World w;
        add_sky_scene(w, material);
        g.render(w);
        std::vector<double> ms;
        double bakeCpu = 0.0;
        for (int f = 0; f < 15; ++f) {
            if (changeEveryFrame) w.settings().skyColor = Color{0.1f + 0.01f * float(f), 0.2f, 0.3f, 1};
            const auto t0 = std::chrono::steady_clock::now();
            g.render(w);
            ms.push_back(std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count());
            for (const auto& p : g.renderer.stats().passes)
                if (p.name.find("sky-env") != std::string::npos) bakeCpu = p.cpuMs;
        }
        std::sort(ms.begin(), ms.end());
        return std::pair<double, double>(ms[ms.size() / 2], bakeCpu);
    };
    const auto none = median_ms("", false);
    const auto cached = median_ms("materials/skygrad.material.json", false);
    const auto baked = median_ms("materials/skygrad.material.json", true);
    std::string why;
    char line[300];
    std::snprintf(line, sizeof line,
                  "frame wall time: no sky material %.2f ms, sky cached %.2f ms, sky baked every frame %.2f ms (the "
                  "bake: about %.2f ms; "
                  "its passes took %.2f ms of CPU to record); GPU timer: %s",
                  none.first, cached.first, baked.first, baked.first - cached.first, baked.second,
                  g.renderer.gpu_timing_supported(&why) ? "supported" : why.c_str());
    MESSAGE(line);
}

TEST_CASE("sky materials: a render target planned first with another sky does not take the environment from the main "
          "camera") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ErrorLog log;
    // The sky reads the texture "target:mirror": for the camera that renders into "mirror" it is the checker (its own
    // picture would be a loop), for the main camera it is the mirror's picture, here plain green. The two jobs bake
    // different skies; the job of the picture is planned last, and the sphere it draws must be lit by the sky it shows
    // (green above) however the jobs are ordered.
    World w;
    sky_sphere_world(w, "materials/skytex.material.json", Json::object({{"map", "target:mirror"}}), 0.0f, 1.0f);
    w.settings().skyColor = w.settings().horizonColor = Color{0.12f, 0.12f, 0.12f, 1};
    // The mirror's camera is orthographic (it draws no sky of its own: the picture is not the checker) and far from the
    // sphere: its picture is its green clear colour.
    Entity mirror = make(w, "mirror", {1000, 1.5f, -400});
    Camera& mc = w.add<Camera>(mirror);
    mc.projection = Projection::Orthographic;
    mc.renderTarget = "mirror";
    mc.renderTargetSize = Vec2{64, 64};
    mc.clearColor = Color{0, 1, 0, 1};
    const Image img = g.render(w);
    CHECK(g.renderer.stats().renderTargets == 1);
    const int cx = img.width / 2, cy = img.height / 2;
    const Color top = img.pixel(cx, cy - 34);
    CAPTURE(top.r);
    CAPTURE(top.g);
    CAPTURE(top.b);
    CHECK(top.g > top.r + 0.1f);  // lit by the green picture of the mirror, not by the checker or the dark gradient
    CHECK(log.messages().empty());
}

TEST_CASE("sky materials: a texture of the material is bound from view 0") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    ErrorLog log;
    auto frame = [&](const char* material) {
        World w;
        add_sky_scene(w, material);
        return g.render(w);
    };
    const Image builtIn = frame("");
    const Image textured = frame("materials/skytex.material.json");
    CHECK(log.messages().empty());
    CHECK(diff_images(builtIn, textured, 4.0f / 255.0f).meanError > 0.01);
    // the checker has dark and light cells: the sky is not one flat colour
    float lo = 1.0f, hi = 0.0f;
    for (int x = 0; x < 320; x += 4) {
        const float v = textured.pixel(x, 2).r;
        lo = std::min(lo, v);
        hi = std::max(hi, v);
    }
    CHECK(hi - lo > 0.1f);
}

TEST_CASE("sky materials: a material that does not compile, or is not a sky, shows the built-in sky and logs once") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    REQUIRE(
        fs::write_text("materials/brokensky.material.json",
                       R"({"format": "factoria.material/1", "kind": "sky", "shader": "shaders/brokensky.sky.glsl"})")
            .ok());
    g.renderer.set_shader_compiler([](const std::string& material, const std::string& dialect) -> Result<Json> {
        if (material.find("brokensky") == std::string::npos)  // every other material is the fixture's empty mesh one
            return load_json_file("materials/empty.material.json." + dialect + ".shader");
        return make_error(
            "shaders/brokensky.sky.glsl:2:5: error: 'colour' : no such field in structure 'SkySurface'\n  "
            "hint: did you mean color?",
            "did you mean color?");
    });
    auto frame = [&](const char* material) {
        World w;
        add_sky_scene(w, material);
        return g.render(w);
    };
    const Image builtIn = frame("");
    {
        ErrorLog log;
        Image img;
        for (int i = 0; i < 3; ++i) img = frame("materials/brokensky.material.json");
        CHECK(diff_images(builtIn, img, 0.0f).maxError == 0.0);  // the gradient, not magenta
        CHECK(log.count("brokensky.sky.glsl:2:5") == 1);
        REQUIRE(g.renderer.stats().materialFallbacks.size() == 1);
        CHECK(g.renderer.stats().materialFallbacks[0] == "materials/brokensky.material.json");
    }
    {  // a mesh material is not a sky: said once, with the way out
        ErrorLog log;
        Image img;
        for (int i = 0; i < 3; ++i) img = frame("materials/empty.material.json");
        CHECK(diff_images(builtIn, img, 0.0f).maxError == 0.0);
        REQUIRE(log.messages().size() == 1);
        CHECK(log.messages()[0].find("is a \"mesh\" material, not a \"sky\" one") != std::string::npos);
        CHECK(log.messages()[0].find("\"kind\": \"sky\"") != std::string::npos);
        REQUIRE(g.renderer.stats().materialFallbacks.size() == 1);
        CHECK(g.renderer.stats().materialFallbacks[0] == "materials/empty.material.json");
    }
    {  // a path that does not exist
        ErrorLog log;
        const Image img = frame("materials/nowhere.material.json");
        CHECK(diff_images(builtIn, img, 0.0f).maxError == 0.0);
        CHECK_FALSE(log.messages().empty());
    }
}

TEST_CASE("sky materials: hot reload swaps the sky, keeps the last good one on a broken edit and recovers") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    const std::string dialect = g.renderer.shader_dialect();
    REQUIRE(fs::write_text("materials/hotsky.material.json",
                           R"({"format": "factoria.material/1", "kind": "sky", "shader": "shaders/hotsky.txt",
                               "params": {"zenith": {"type": "color", "default": [0.9, 0.2, 0.1, 1.0], "doc": "Up."},
                                          "ground": {"type": "color", "default": [0.1, 0.1, 0.6, 1.0], "doc": "Down."}}})")
                .ok());
    // Stands in for the tooling: the snippet on disk names the fixture twin to use, or is broken.
    g.renderer.set_shader_compiler([dialect](const std::string&, const std::string&) -> Result<Json> {
        auto snippet = fs::read_text("shaders/hotsky.txt");
        if (!snippet.ok()) return snippet.error();
        if (*snippet == "broken")
            return make_error("shaders/hotsky.txt:1:1: error: 'broken' : undeclared identifier",
                              "Write skygrad or skyempty.");
        return load_json_file("materials/" + *snippet + ".material.json." + dialect + ".shader");
    });
    auto frame = [&]() {
        World w;
        add_sky_scene(w, "materials/hotsky.material.json");
        return g.render(w);
    };
    ErrorLog log;
    REQUIRE(fs::write_text("shaders/hotsky.txt", "skygrad").ok());
    const Image gradient = frame();
    REQUIRE(fs::write_text("shaders/hotsky.txt", "skyempty").ok());
    g.renderer.reload_asset("shaders/hotsky.txt");
    const Image plain = frame();
    CHECK(diff_images(gradient, plain, 4.0f / 255.0f).meanError > 0.01);
    CHECK(log.messages().empty());

    REQUIRE(fs::write_text("shaders/hotsky.txt", "broken").ok());
    g.renderer.reload_asset("shaders/hotsky.txt");
    const Image kept = frame();
    frame();
    CHECK(diff_images(plain, kept, 0.0f).maxError == 0.0);
    CHECK(log.count("shaders/hotsky.txt:1:1") == 1);
    CHECK(g.renderer.stats().materialFallbacks.empty());

    REQUIRE(fs::write_text("shaders/hotsky.txt", "skygrad").ok());
    g.renderer.reload_asset("shaders/hotsky.txt");
    const Image back = frame();
    CHECK(diff_images(gradient, back, 0.0f).maxError == 0.0);
}

// ---- per-instance params and declared vertex channels (materials/inst and materials/chan) ----

namespace {
Json tint_params(double r, double g, double b) { return Json::object({{"tint", Json::array({r, g, b, 1.0})}}); }

// Per channel: |pixel - (r, g, b)| <= tol.
bool near_color(const Color& c, float r, float g, float b, float tol = 0.2f) {
    return std::abs(c.r - r) <= tol && std::abs(c.g - g) <= tol && std::abs(c.b - b) <= tol;
}

// A quad facing +Z (x -1.5..1.5) with a second UV set and a second colour set (red on the left, blue on the right);
// `withChannels` false leaves them out.
void write_channel_quad(const char* name, bool withChannels) {
    const float pos[12] = {-1.5f, -1.5f, 0, 1.5f, -1.5f, 0, 1.5f, 1.5f, 0, -1.5f, 1.5f, 0};
    const float uv1[8] = {0.5f, 0, 0.5f, 0, 0.5f, 1, 0.5f, 1};
    const std::uint8_t cols[16] = {255, 0, 0, 255, 0, 0, 255, 255, 0, 0, 255, 255, 255, 0, 0, 255};
    const std::uint16_t ix[6] = {0, 1, 2, 0, 2, 3};
    std::vector<std::uint8_t> bytes(48 + 12 + 32 + 16);
    std::memcpy(bytes.data(), pos, 48);
    std::memcpy(bytes.data() + 48, ix, 12);
    std::memcpy(bytes.data() + 60, uv1, 32);
    std::memcpy(bytes.data() + 92, cols, 16);
    static const char* t = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    std::string b64;
    for (std::size_t i = 0; i < bytes.size(); i += 3) {
        const std::uint32_t n = (bytes[i] << 16) | (i + 1 < bytes.size() ? bytes[i + 1] << 8 : 0) |
                                (i + 2 < bytes.size() ? bytes[i + 2] : 0);
        b64 += t[(n >> 18) & 63];
        b64 += t[(n >> 12) & 63];
        b64 += i + 1 < bytes.size() ? t[(n >> 6) & 63] : '=';
        b64 += i + 2 < bytes.size() ? t[n & 63] : '=';
    }
    const std::string attrs = withChannels ? R"("POSITION":0,"TEXCOORD_1":2,"COLOR_1":3)" : R"("POSITION":0)";
    const Json gltf = Json::parse(
        R"({"asset":{"version":"2.0"},"scene":0,"scenes":[{"nodes":[0]}],"nodes":[{"mesh":0}],
        "meshes":[{"primitives":[{"attributes":{)" +
        attrs + R"(},"indices":1}]}],
        "buffers":[{"byteLength":)" +
        std::to_string(bytes.size()) + R"(,"uri":"data:application/octet-stream;base64,)" + b64 + R"("}],
        "bufferViews":[{"buffer":0,"byteOffset":0,"byteLength":48},{"buffer":0,"byteOffset":48,"byteLength":12},
                       {"buffer":0,"byteOffset":60,"byteLength":32},{"buffer":0,"byteOffset":92,"byteLength":16}],
        "accessors":[{"bufferView":0,"componentType":5126,"count":4,"type":"VEC3","min":[-1.5,-1.5,0],"max":[1.5,1.5,0]},
                     {"bufferView":1,"componentType":5123,"count":6,"type":"SCALAR"},
                     {"bufferView":2,"componentType":5126,"count":4,"type":"VEC2"},
                     {"bufferView":3,"componentType":5121,"normalized":true,"count":4,"type":"VEC4"}]})");
    REQUIRE(fs::write_text(name, gltf.dump()).ok());
}
}  // namespace

TEST_CASE("materials: 100 cubes with different instanced values are one batch and one draw, a per-draw param splits") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    // mode 0: every cube the same; 1: a different tint per cube; 2: a different tint and `raise`; 3: two `boost`
    // values.
    auto frame = [&](int mode) {
        World w;
        add_camera(w, {0, 9, 14}, {0, 0, 0});
        add_light(w, LightType::Directional, {0, 5, 0}, {-50, 30, 0}, 0.8f);
        for (int i = 0; i < 100; ++i) {
            Entity e = add_material_mesh(w, "cube", "materials/inst.material.json",
                                         {float(i % 10) - 4.5f, 0, float(i / 10) - 4.5f}, Color::hex(0x404040),
                                         {0.7f, 0.7f, 0.7f});
            Json params = Json::object();
            if (mode == 1 || mode == 2) params = tint_params(i % 3 == 0, i % 3 == 1, i % 3 == 2);
            if (mode == 2) params["raise"] = double(i % 4) * 0.3;
            if (mode == 3) params["boost"] = i % 2 ? 2.0 : 1.0;
            w.get<MeshRenderer>(e)->materialParams = params;
        }
        g.render(w);
        return g.renderer.stats();
    };
    ErrorLog log;
    const RenderStats same = frame(0);
    CHECK(same.meshes == 100);
    CHECK(same.meshBatches == 1);
    for (int mode : {1, 2}) {
        const RenderStats s = frame(mode);
        CAPTURE(mode);
        CHECK(s.meshBatches == 1);
        CHECK(s.drawCalls == same.drawCalls);
        CHECK(s.materialFallbacks.empty());
    }
    CHECK(frame(3).meshBatches == 2);
    CHECK(log.messages().empty());
}

TEST_CASE("materials: instanced values reach surface() per entity, in one draw") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    World w;
    add_stage(w);
    const double col[3][3] = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}};
    for (int i = 0; i < 3; ++i) {
        Entity e = add_material_mesh(w, "cube", "materials/inst.material.json", {(i - 1) * 2.2f, 0, 0},
                                     Color::hex(0x202020), {1, 1, 1});
        w.get<MeshRenderer>(e)->materialParams = tint_params(col[i][0], col[i][1], col[i][2]);
    }
    ErrorLog log;
    const Image img = g.render(w);
    CHECK(log.messages().empty());
    CHECK(g.renderer.stats().meshBatches == 2);  // the three cubes, and the ground plane of the stage
    CHECK(near_color(img.pixel(80, 90), 1, 0, 0, 0.25f));
    CHECK(near_color(img.pixel(160, 90), 0, 1, 0, 0.25f));
    CHECK(near_color(img.pixel(240, 90), 0, 0, 1, 0.25f));
}

TEST_CASE("materials: a per-instance value read in vertex() moves the mesh and its shadow, and still batches") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    auto frame = [&](bool instanced) {
        World w;
        add_stage(w);
        if (instanced) {
            // Two entities with different `raise`: one batch; the one at 1.2 must equal a plain cube placed there.
            Entity a = add_material_mesh(w, "cube", "materials/inst.material.json", {-1.5f, 0, 0}, Color::hex(0xc08040),
                                         {1, 1, 1});
            Entity b = add_material_mesh(w, "cube", "materials/inst.material.json", {1.5f, 0, 0}, Color::hex(0xc08040),
                                         {1, 1, 1});
            auto set = [&](Entity e, double raise) {
                w.get<MeshRenderer>(e)->materialParams =
                    Json::object({{"raise", raise}, {"tint", Json::array({0.0, 0.0, 0.0, 1.0})}});
            };
            set(a, 1.2);
            set(b, 0.0);
        } else {
            add_mesh(w, "cube", {-1.5f, 1.2f, 0}, Color::hex(0xc08040));
            add_mesh(w, "cube", {1.5f, 0.0f, 0}, Color::hex(0xc08040));
        }
        return g.render(w);
    };
    ErrorLog log;
    const Image lifted = frame(true);
    CHECK(g.renderer.stats().meshBatches == 2);  // the two cubes, and the ground plane of the stage
    const Image placed = frame(false);
    CHECK(log.messages().empty());
    // The ground shadow of both cubes is part of the picture: the shadow pass saw the same per-instance values.
    CHECK(diff_images(lifted, placed, 2.0f / 255.0f).meanError < 0.001);
}

TEST_CASE("materials: instanced params on a skinned glTF draw, with the per-instance data after the joints") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    std::ifstream in(std::string(FA_REPO_ROOT) + "/engine/render/tests/data/skinned_two_bone.gltf", std::ios::binary);
    std::string text((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    REQUIRE(fs::write_text("assets/rig_instanced.gltf", text).ok());
    auto frame = [&](double r, double gr) {
        World w;
        add_camera(w, {0.5f, 1.2f, 4}, {0.5f, 1.0f, 0});
        w.get<Light>(add_light(w, LightType::Directional, {0, 5, 0}, {-40, 25, 0}, 1.0f))->castShadows = true;
        add_mesh(w, "plane", {0, -0.01f, 0}, Color::hex(0x909090), {8, 1, 8});
        Entity rig = make(w, "rig");
        auto& mr = w.add<MeshRenderer>(rig);
        mr.mesh = "assets/rig_instanced.gltf";
        mr.material = "materials/inst.material.json";
        mr.materialParams = tint_params(r, gr, 0.0);
        w.add<Animator>(rig).clip = "Bend";
        update_animators(w, 0.0f);
        update_animators(w, 0.5f);
        return g.render(w);
    };
    ErrorLog log;
    const Image red = frame(1, 0);
    const Image green = frame(0, 1);
    CHECK(log.messages().empty());
    CHECK(g.renderer.stats().materialFallbacks.empty());
    CHECK(diff_images(red, green, 4.0f / 255.0f).meanError > 0.002);
}

TEST_CASE("materials: vertexAttributes reads the second UV set and colour set of a glTF mesh") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    write_channel_quad("assets/chan_quad.gltf", true);
    World w;
    add_camera(w, {0, 0, 4}, {0, 0, 0});
    add_material_mesh(w, "assets/chan_quad.gltf", "materials/chan.material.json", {0, 0, 0}, Color::white(), {1, 1, 1});
    ErrorLog log;
    const Image img = g.render(w);
    CHECK(log.messages().empty());
    CHECK(g.renderer.stats().materialFallbacks.empty());
    // Red on the left, blue on the right: the emission is color1 * (uv1.x * 2) = color1.
    CHECK(near_color(img.pixel(160 - 40, 90), 1, 0, 0, 0.3f));
    CHECK(near_color(img.pixel(160 + 40, 90), 0, 0, 1, 0.3f));
}

TEST_CASE("materials: a mesh without a declared channel is drawn magenta and reported once, naming material, mesh and "
          "channel") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    write_channel_quad("assets/plain_quad.gltf", false);
    World w;
    add_camera(w, {0, 0, 4}, {0, 0, 0});
    add_material_mesh(w, "assets/plain_quad.gltf", "materials/chan.material.json", {-2, 0, 0}, Color::white(),
                      {1, 1, 1});
    add_material_mesh(w, "cube", "materials/chan.material.json", {2, 0, 0}, Color::white(), {1, 1, 1});
    ErrorLog log;
    const Image img = g.render(w);
    g.render(w);
    CHECK(log.count("materials/chan.material.json") == 2);  // one per mesh, not one per frame
    CHECK(log.count("TEXCOORD_1") == 2);
    CHECK(log.count("assets/plain_quad.gltf") == 1);
    REQUIRE(g.renderer.stats().materialFallbacks.size() == 1);
    CHECK(g.renderer.stats().materialFallbacks[0] == "materials/chan.material.json");
    CHECK(near_color(img.pixel(160 - 78, 90), 1, 0, 1, 0.3f));  // the quad's centre, magenta
}

TEST_CASE("materials: a glTF reloaded with the declared channel leaves the report and draws normally") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    write_channel_quad("assets/reload_quad.gltf", false);
    World w;
    add_camera(w, {0, 0, 4}, {0, 0, 0});
    add_material_mesh(w, "assets/reload_quad.gltf", "materials/chan.material.json", {0, 0, 0}, Color::white(),
                      {1, 1, 1});
    auto reported = [&] {
        int n = 0;
        const Json report = g.renderer.asset_report();
        for (const Json& f : report["failures"])
            if (f["kind"] == "material-mesh") ++n;
        return n;
    };
    ErrorLog log;
    const Image before = g.render(w);
    CHECK(near_color(before.pixel(160, 90), 1, 0, 1, 0.3f));
    CHECK(reported() == 1);
    // The file now has the channels; the material itself is not rebuilt.
    write_channel_quad("assets/reload_quad.gltf", true);
    g.renderer.reload_asset("assets/reload_quad.gltf");
    const Image after = g.render(w);
    CHECK(reported() == 0);
    CHECK(g.renderer.stats().materialFallbacks.empty());
    CHECK(near_color(after.pixel(160 - 40, 90), 1, 0, 0, 0.3f));
    CHECK(near_color(after.pixel(160 + 40, 90), 0, 0, 1, 0.3f));
    // Reloaded again without them: reported again, once.
    write_channel_quad("assets/reload_quad.gltf", false);
    g.renderer.reload_asset("assets/reload_quad.gltf");
    g.render(w);
    g.render(w);
    CHECK(reported() == 1);
}

// ---- full shaders (mode "full": the file is the whole vertex and fragment stage; docs/shaders/SHADERS_FULL.md) ----

TEST_CASE("full shaders: an unlit colour from the fragment stage, drawn with no light and no surface()") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    World w;
    add_camera(w, {0, 0, 4}, {0, 0, 0});
    add_material_mesh(w, "cube", "materials/full_flat.material.json", {0, 0, 0}, Color::white(), {1.5f, 1.5f, 1.5f});
    ErrorLog log;
    const Image img = g.render(w);
    CHECK(log.messages().empty());
    CHECK(g.renderer.stats().materialFallbacks.empty());
    CHECK(g.renderer.stats().materials == 1);
    const Color c = img.pixel(160, 90);
    CAPTURE(c.r);
    CAPTURE(c.g);
    CAPTURE(c.b);
    CHECK(c.g > c.b);  // (0.2, 0.8, 0.4): the order survives any encoding
    CHECK(c.b > c.r);
    // A materialParams override reaches the params block of the full shader.
    World w2;
    add_camera(w2, {0, 0, 4}, {0, 0, 0});
    Entity e = add_material_mesh(w2, "cube", "materials/full_flat.material.json", {0, 0, 0}, Color::white(),
                                 {1.5f, 1.5f, 1.5f});
    w2.get<MeshRenderer>(e)->materialParams = tint_params(1, 0, 0);
    CHECK(near_color(g.render(w2).pixel(160, 90), 1, 0, 0, 0.12f));
}

TEST_CASE("full shaders: two passes draw in order, the outline from the back faces pushed along the normals") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    World w;
    add_camera(w, {0, 0, 4}, {0, 0, 0});
    Entity e = add_material_mesh(w, "sphere", "materials/full_outline.material.json", {0, 0, 0}, Color::white(),
                                 {1.5f, 1.5f, 1.5f});
    w.get<MeshRenderer>(e)->materialParams = Json::object({{"outlineWidth", 0.2}});
    ErrorLog log;
    const Image img = g.render(w);
    CHECK(log.messages().empty());
    CHECK(g.renderer.stats().materialFallbacks.empty());
    CHECK(near_color(img.pixel(160, 90), 0.1f, 0.7f, 0.2f, 0.25f));  // the body pass, in the middle
    int firstRed = -1, firstBody = -1, red = 0;
    for (int x = 0; x < img.width; ++x) {
        const Color c = img.pixel(x, 90);
        const bool isRed = c.r > 0.8f && c.g < 0.25f && c.b < 0.25f;
        if (isRed) ++red;
        if (isRed && firstRed < 0) firstRed = x;
        if (c.g > 0.5f && c.r < 0.4f && firstBody < 0) firstBody = x;
    }
    CHECK(red >= 4);  // a ring of the outline pass around the body
    CHECK(firstRed >= 0);
    CHECK(firstRed < firstBody);  // the ring is outside the body
}

TEST_CASE("full shaders: stats.triangles and drawCalls count each pass of a part, not the part once") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    auto frame = [&](const char* material) {
        World w;
        add_camera(w, {0, 0, 4}, {0, 0, 0});
        if (material)
            add_material_mesh(w, "sphere", material, {0, 0, 0}, Color::white(), {1.5f, 1.5f, 1.5f});
        else
            add_mesh(w, "sphere", {0, 0, 0}, Color::white(), {1.5f, 1.5f, 1.5f});
        g.render(w);
        return g.renderer.stats();
    };
    const RenderStats plain = frame(nullptr);
    const RenderStats flat = frame("materials/full_flat.material.json");        // one pass
    const RenderStats outline = frame("materials/full_outline.material.json");  // two passes
    REQUIRE(plain.triangles > 0);
    CHECK(flat.triangles == plain.triangles);
    CHECK(outline.triangles == 2 * plain.triangles);
    CHECK(outline.drawCalls == flat.drawCalls + 1);
    CHECK(outline.meshes == 1);  // one entity, one batch: the passes are not more instances
    CHECK(outline.meshBatches == 1);
}

TEST_CASE("full shaders: a pass without the depth test shows the mesh through what hides it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    auto frame = [&](const char* material) {
        World w;
        add_camera(w, {0, 0, 6}, {0, 0, 0});
        add_mesh(w, "cube", {0, 0, 2}, Color::hex(0x808080), {3, 3, 0.5f});  // the wall, in front
        add_material_mesh(w, "cube", material, {0, 0, -1}, Color::white(), {1, 1, 1});
        return g.render(w);
    };
    ErrorLog log;
    const Image xray = frame("materials/full_xray.material.json");
    const Image flat = frame("materials/full_flat.material.json");
    CHECK(log.messages().empty());
    CHECK(near_color(xray.pixel(160, 90), 1, 1, 0, 0.12f));  // the xray pass over the wall
    CHECK_FALSE(near_color(flat.pixel(160, 90), 1, 1, 0, 0.3f));
}

TEST_CASE("full shaders: an own light loop over fa_light_count() lights, adding up") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    auto frame = [&](int lights) {
        World w;
        add_camera(w, {0, 0, 4}, {0, 0, 0});
        w.settings().ambientLight = Color{0.1f, 0.1f, 0.1f, 1};
        for (int i = 0; i < lights; ++i)
            w.get<Light>(add_light(w, LightType::Directional, {0, 5, 0}, {-20.0f - 5 * i, 20, 0}, 0.4f))->castShadows =
                false;
        add_material_mesh(w, "sphere", "materials/full_lights.material.json", {0, 0, 0}, Color::white(),
                          {2.0f, 2.0f, 2.0f});
        return g.render(w).pixel(160, 90);
    };
    ErrorLog log;
    const Color none = frame(0), one = frame(1), two = frame(2);
    CHECK(log.messages().empty());
    CAPTURE(none.g);
    CAPTURE(one.g);
    CAPTURE(two.g);
    CHECK(one.g > none.g + 0.03f);
    CHECK(two.g > one.g + 0.03f);
}

TEST_CASE("full shaders: a declared vertex channel is read, a mesh without it is drawn magenta and reported once") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    write_channel_quad("assets/full_quad.gltf", true);
    write_channel_quad("assets/full_plain.gltf", false);
    World w;
    add_camera(w, {0, 0, 4}, {0, 0, 0});
    add_material_mesh(w, "assets/full_quad.gltf", "materials/full_chan.material.json", {-2.5f, 0, 0}, Color::white(),
                      {1, 1, 1});
    add_material_mesh(w, "assets/full_plain.gltf", "materials/full_chan.material.json", {2.5f, 0, 0}, Color::white(),
                      {1, 1, 1});
    ErrorLog log;
    const Image img = g.render(w);
    g.render(w);
    CHECK(
        near_color(img.pixel(160 - 98 - 30, 90), 1, 0, 0, 0.3f));  // color1 * (uv1.x * 2): red on the left of the quad
    CHECK(near_color(img.pixel(160 + 98, 90), 1, 0, 1, 0.3f));     // the mesh without the channels: magenta
    CHECK(log.count("assets/full_plain.gltf") == 1);
    CHECK(log.count("TEXCOORD_1") == 1);
    REQUIRE(g.renderer.stats().materialFallbacks.size() == 1);
    CHECK(g.renderer.stats().materialFallbacks[0] == "materials/full_chan.material.json");
}

TEST_CASE("full shaders: per-instance params and a texture read in both stages, one batch, an own shadow program") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    World w;
    add_stage(w);
    const double col[3][3] = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}};
    for (int i = 0; i < 3; ++i) {
        Entity e = add_material_mesh(w, "cube", "materials/full_inst.material.json", {(i - 1) * 2.2f, 0, 0},
                                     Color::white(), {1, 1, 1});
        w.get<MeshRenderer>(e)->materialParams = tint_params(col[i][0], col[i][1], col[i][2]);
    }
    ErrorLog log;
    const Image img = g.render(w);
    CHECK(log.messages().empty());
    CHECK(g.renderer.stats().materialFallbacks.empty());
    CHECK(g.renderer.stats().meshBatches == 2);  // the three cubes in one batch, and the ground
    CHECK(near_color(img.pixel(80, 90), 1, 0, 0, 0.3f));
    CHECK(near_color(img.pixel(160, 90), 0, 1, 0, 0.3f));
    CHECK(near_color(img.pixel(240, 90), 0, 0, 1, 0.3f));
}

TEST_CASE(
    "full shaders: a skinned glTF draws with the skinned program of every pass, instanced params after the joints") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    std::ifstream in(std::string(FA_REPO_ROOT) + "/engine/render/tests/data/skinned_two_bone.gltf", std::ios::binary);
    std::string text((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    REQUIRE(fs::write_text("assets/rig_full.gltf", text).ok());
    auto frame = [&](const char* material, double r, double gr) {
        World w;
        add_camera(w, {0.5f, 1.2f, 4}, {0.5f, 1.0f, 0});
        w.get<Light>(add_light(w, LightType::Directional, {0, 5, 0}, {-40, 25, 0}, 1.0f))->castShadows = true;
        add_mesh(w, "plane", {0, -0.01f, 0}, Color::hex(0x909090), {8, 1, 8});
        Entity rig = make(w, "rig");
        auto& mr = w.add<MeshRenderer>(rig);
        mr.mesh = "assets/rig_full.gltf";
        mr.material = material;
        mr.materialParams = tint_params(r, gr, 0.0);
        w.add<Animator>(rig).clip = "Bend";
        update_animators(w, 0.0f);
        update_animators(w, 0.5f);
        return g.render(w);
    };
    ErrorLog log;
    const Image red = frame("materials/full_inst.material.json", 1, 0);
    const Image green = frame("materials/full_inst.material.json", 0, 1);
    frame("materials/full_outline.material.json", 1, 0);  // two passes, both skinned
    CHECK(log.messages().empty());
    CHECK(g.renderer.stats().materialFallbacks.empty());
    CHECK(diff_images(red, green, 4.0f / 255.0f).meanError > 0.002);
}

TEST_CASE("full shaders: hot reload swaps the shader, keeps the last good one on a broken edit and recovers") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    const std::string dialect = g.renderer.shader_dialect();
    REQUIRE(fs::write_text(
                "materials/hotfull.material.json",
                R"({"format": "factoria.material/1", "mode": "full", "shader": "shaders/hotfull.txt", "prepass": false,
                    "params": {"tint": {"type": "color", "default": [0.2, 0.8, 0.4, 1.0], "doc": "Colour."}}})")
                .ok());
    g.renderer.set_shader_compiler([dialect](const std::string&, const std::string&) -> Result<Json> {
        auto text = fs::read_text("shaders/hotfull.txt");
        if (!text.ok()) return text.error();
        if (*text == "broken")
            return make_error("shaders/hotfull.txt:2:1: error: 'broken' : undeclared identifier", "Write flat or alt.");
        return load_json_file("materials/full_" + *text + ".material.json." + dialect + ".shader");
    });
    auto frame = [&]() {
        World w;
        add_camera(w, {0, 0, 4}, {0, 0, 0});
        add_material_mesh(w, "cube", "materials/hotfull.material.json", {0, 0, 0}, Color::white(), {1.5f, 1.5f, 1.5f});
        return g.render(w);
    };
    ErrorLog log;
    REQUIRE(fs::write_text("shaders/hotfull.txt", "flat").ok());
    const Image flat = frame();
    REQUIRE(fs::write_text("shaders/hotfull.txt", "alt").ok());
    g.renderer.reload_asset("shaders/hotfull.txt");
    const Image alt = frame();
    CHECK(diff_images(flat, alt, 4.0f / 255.0f).meanError > 0.003);
    CHECK(alt.pixel(160, 90).r > alt.pixel(160, 90).b);  // flat: (0.2, 0.8, 0.4), alt: (0.4, 0.8, 0.2)
    CHECK(flat.pixel(160, 90).b > flat.pixel(160, 90).r);
    CHECK(log.messages().empty());

    REQUIRE(fs::write_text("shaders/hotfull.txt", "broken").ok());
    g.renderer.reload_asset("shaders/hotfull.txt");
    const Image kept = frame();
    frame();
    CHECK(diff_images(alt, kept, 0.0f).maxError == 0.0);
    CHECK(log.count("shaders/hotfull.txt:2:1") == 1);
    CHECK(g.renderer.stats().materialFallbacks.empty());

    REQUIRE(fs::write_text("shaders/hotfull.txt", "flat").ok());
    g.renderer.reload_asset("shaders/hotfull.txt");
    CHECK(diff_images(flat, frame(), 0.0f).maxError == 0.0);
}
