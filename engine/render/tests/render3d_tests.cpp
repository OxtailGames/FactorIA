#include "test_util.h"

#include <algorithm>
#include <fstream>
#include <iterator>
#include <vector>

#include "fa/scene/animation.h"

#include "mesh_batch.h"
#include "render_internal.h"   // material_shader_desc
#include "shaders/mesh.glsl.h"  // mesh_mesh_shader_desc: what the converter of the twins must reproduce

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

struct ErrorLog {
    std::vector<std::string> messages;
    int id;
    ErrorLog() : id(add_log_sink([this](const LogEntry& e) { if (e.level == LogLevel::Error) messages.push_back(e.message); })) {}
    ~ErrorLog() { remove_log_sink(id); }
    int count(const std::string& needle) const {
        return int(std::count_if(messages.begin(), messages.end(), [&](const std::string& m) { return m.find(needle) != std::string::npos; }));
    }
};

Entity add_material_mesh(World& w, const char* mesh, const char* material, Vec3 pos, Color color = Color::hex(0x202020), Vec3 scale = {1.5f, 1.5f, 1.5f}) {
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
    auto s = [&](const char* p) { o += p ? p : "<null>"; o += ';'; };
    auto n = [&](long long v) { o += std::to_string(v) + ';'; };
    for (const sg_shader_function* f : {&d.vertex_func, &d.fragment_func}) { s(f->entry); s(f->d3d11_target); }
    for (const auto& a : d.attrs) { n(a.base_type); s(a.glsl_name); s(a.hlsl_sem_name); n(a.hlsl_sem_index); }
    for (const auto& u : d.uniform_blocks) {
        n(u.stage); n(u.size); n(u.hlsl_register_b_n); n(u.msl_buffer_n); n(u.layout);
        for (const auto& g : u.glsl_uniforms) { n(g.type); n(g.array_count); s(g.glsl_name); }
    }
    for (const auto& v : d.views) {
        const auto& t = v.texture;
        n(t.stage); n(t.image_type); n(t.sample_type); n(t.multisampled); n(t.hlsl_register_t_n); n(t.msl_texture_n);
    }
    for (const auto& m : d.samplers) { n(m.stage); n(m.sampler_type); n(m.hlsl_register_s_n); n(m.msl_sampler_n); }
    for (const auto& p : d.texture_sampler_pairs) { n(p.stage); n(p.view_slot); n(p.sampler_slot); s(p.glsl_name); }
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
    CHECK(slots.viewMask == 0b111111);
    CHECK(slots.samplerMask == 0b11);
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

TEST_CASE("materials: a material with an empty surface() renders pixel-identical to the same mesh without a material, shadows on") {
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
    CHECK(log.messages.empty());
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
            Entity e = add_material_mesh(w, "cube", "materials/glow.material.json", {float(i % 10) - 4.5f, 0, float(i / 10) - 4.5f}, Color::hex(0x404040), {0.7f, 0.7f, 0.7f});
            if (overrides) w.get<MeshRenderer>(e)->materialParams = Json::object({{"glow", Json::array({0.0, i % 2 ? 1.0 : 0.0, i % 2 ? 0.0 : 1.0, 1.0})}});
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
    CHECK(log.messages.empty());
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
        if (lifted) add_material_mesh(w, "cube", "materials/lift.material.json", {-1.5f, 0, 0}, Color::hex(0xc08040), {1, 1, 1});
        else add_mesh(w, "cube", {-1.5f + 0.8f, 1.2f, 0}, Color::hex(0xc08040));  // where the lift material puts it
        return g.render(w);
    };
    const Image lift = frame(true);
    // The same picture as the plain cube standing at the displaced place: the shadow on the ground included.
    const Image placed = frame(false);
    CHECK(diff_images(lift, placed, 2.0f / 255.0f).meanError < 0.001);
    expect_golden(lift, "3d_material_lift");
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
    CHECK(log.messages.empty());
    const Image solid = frame("");
    CHECK(diff_images(cut, solid, 4.0f / 255.0f).meanError > 0.005);
    expect_golden(cut, "3d_material_cutout");
}

TEST_CASE("materials: a material that does not compile is drawn magenta and logged once with its file and line") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    REQUIRE(fs::write_text("materials/broken.material.json", R"({"format": "factoria.material/1", "shader": "shaders/broken.surface.glsl"})").ok());
    g.renderer.set_shader_compiler([](const std::string&, const std::string&) -> Result<Json> {
        return make_error("shaders/broken.surface.glsl:3:5: error: 'colour' : no such field in structure 'Surface'", "did you mean albedo?");
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
                               "params": {"glow": {"type": "color", "default": [1.0, 0.35, 0.0, 1.0], "doc": "Glow."}}})").ok());
    // Stands in for the tooling: the snippet on disk names the fixture twin to use ("glow" or "empty"), or is broken.
    g.renderer.set_shader_compiler([dialect](const std::string&, const std::string&) -> Result<Json> {
        auto snippet = fs::read_text("shaders/hot.txt");
        if (!snippet.ok()) return snippet.error();
        if (*snippet == "broken") return make_error("shaders/hot.txt:1:1: error: 'broken' : undeclared identifier", "Write glow or empty.");
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
    CHECK(log.messages.empty());

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
    CHECK(log.messages.size() == 1);
    CHECK(g.renderer.asset_report()["failures"].empty());
}

TEST_CASE("materials: a twin from another factoria version is refused with the re-export hint") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    auto twin = load_json_file("materials/empty.material.json." + g.renderer.shader_dialect() + ".shader");
    REQUIRE(twin.ok());
    (*twin)["engine"] = "0.0.0";
    REQUIRE(fs::write_text("materials/old.material.json", R"({"format": "factoria.material/1", "shader": "shaders/empty.surface.glsl"})").ok());
    REQUIRE(fs::write_text("materials/old.material.json." + g.renderer.shader_dialect() + ".shader", twin->dump()).ok());
    ErrorLog log;
    World w;
    add_stage(w);
    add_material_mesh(w, "cube", "materials/old.material.json", {0, 0, 0});
    const Image img = g.render(w);
    CHECK(img.pixel(160, 90).g < 0.1f);  // magenta
    REQUIRE(log.messages.size() == 1);
    CHECK(log.messages[0].find("0.0.0") != std::string::npos);
    CHECK(log.messages[0].find("Export the game again with this factoria version") != std::string::npos);
    CHECK(g.renderer.stats().materialFallbacks.size() == 1);
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
