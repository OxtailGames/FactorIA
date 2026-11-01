// Camera.renderTarget: a camera draws into a texture ("target:<name>") that Sprites, meshes and materials sample, drawn before
// the cameras that show it. These run on whatever backend the machine has (Metal, GL, D3D11).
#include "test_util.h"

#include <cmath>
#include <cstring>
#include <filesystem>
#include <string>

#include <algorithm>
#include <array>
#include <fstream>
#include <vector>

#include "fa/scene/camera_query.h"
#include "fa/scene/mesh_surface.h"
#include "render_internal.h"

using namespace fa;
using namespace fa::test;

namespace {

const Color kPage{0.1f, 0.2f, 0.7f, 1};   // what the page camera clears to
const Color kRed = Color::hex(0xe02020);
const Color kGreen = Color::hex(0x20c040);

bool near(const Color& a, const Color& b, float tol = 0.06f) {
    return std::fabs(a.r - b.r) <= tol && std::fabs(a.g - b.g) <= tol && std::fabs(a.b - b.b) <= tol;
}

// The game camera: orthographic, one world unit per design pixel (320 x 180), at the origin.
Entity game_camera(World& w) {
    Entity e = make(w, "game");
    w.add<Camera>(e).clearColor = Color{0, 0, 0, 1};
    return e;
}

// An orthographic camera at `at` that draws into "target:<name>" and sees `width` x `height` world units.
Camera& target_camera(World& w, const char* name, Vec3 at, int width, int height) {
    Entity e = make(w, (std::string("cam-") + name).c_str(), at);
    Camera& c = w.add<Camera>(e);
    c.renderTarget = name;
    c.renderTargetSize = Vec2{float(width), float(height)};
    c.orthoSize = float(height) / 2;
    c.clearColor = kPage;
    return c;
}

Entity shape(World& w, const char* name, Vec3 pos, Vec2 size, Color color) {
    Entity e = make(w, name, pos);
    auto& s = w.add<Shape2D>(e);
    s.size = size;
    s.color = color;
    return e;
}

Entity sprite_showing(World& w, const char* name, Vec3 pos, Vec2 size, const std::string& texture) {
    Entity e = make(w, name, pos);
    auto& s = w.add<Sprite>(e);
    s.texture = texture;
    s.size = size;
    s.pixelArt = true;
    return e;
}

// Red in the top-left corner of the 64 x 32 page seen by a camera at `at`, green in the bottom-right.
void page_content(World& w, Vec3 at) {
    shape(w, "red", at + Vec3{-22, 11, 0}, {20, 10}, kRed);
    shape(w, "green", at + Vec3{22, -11, 0}, {20, 10}, kGreen);
}

}  // namespace

TEST_CASE("render target: a Sprite shows what the camera drew, the right way up, in the first frame") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    game_camera(w);
    target_camera(w, "page", {1000, 0, 0}, 64, 32);
    page_content(w, {1000, 0, 0});
    sprite_showing(w, "screen", {0, 0, 0}, {128, 64}, "target:page");
    Image img = g.render(w);
    CHECK(g.renderer.stats().renderTargets == 1);
    // The sprite covers x 96..224, y 58..122; the page is shown twice as big as it is.
    CHECK(near(img.pixel(110, 66), kRed));       // top-left of the page
    CHECK(near(img.pixel(210, 114), kGreen));    // bottom-right
    CHECK(near(img.pixel(210, 66), kPage));      // top-right: nothing
    CHECK(near(img.pixel(110, 114), kPage));     // bottom-left: nothing
    CHECK(near(img.pixel(160, 90), kPage));
    CHECK(near(img.pixel(50, 90), Color{0, 0, 0, 1}));  // outside the sprite: the game camera's clear
}

TEST_CASE("render target: the camera is not drawn to the screen and is not a rendering camera") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    game_camera(w);
    Camera& page = target_camera(w, "page", {0, 0, 0}, 64, 32);  // right where the game camera looks
    page.primary = true;
    page.depth = -5;
    shape(w, "box", {0, 0, 0}, {40, 40}, kRed);
    Image img = g.render(w);
    CHECK(near(img.pixel(160, 90), kRed));       // the game camera draws the box
    CHECK(near(img.pixel(10, 10), Color{0, 0, 0, 1}));  // not the page camera's blue clear
    CHECK(rendering_cameras(w).size() == 1);
    CHECK(g.renderer.cameras().size() == 1);
}

TEST_CASE("render target: a target drawn after another sees it without lag, whatever the order of creation") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    game_camera(w);
    // "outer" is created first but shows "inner": inner must be drawn first or outer would show last frame's (empty) picture.
    Camera& outer = target_camera(w, "outer", {1000, 0, 0}, 64, 32);
    outer.clearColor = Color{0, 0, 0, 1};
    sprite_showing(w, "frame", {1000, 0, 0}, {64, 32}, "target:inner");
    target_camera(w, "inner", {2000, 0, 0}, 64, 32);
    page_content(w, {2000, 0, 0});
    sprite_showing(w, "screen", {0, 0, 0}, {128, 64}, "target:outer");
    Image img = g.render(w);
    CHECK(g.renderer.stats().renderTargets == 2);
    CHECK(near(img.pixel(110, 66), kRed));
    CHECK(near(img.pixel(210, 114), kGreen));
    CHECK(near(img.pixel(160, 90), kPage));
}

TEST_CASE("render target: a camera that shows its own target gets the checker and the frame survives") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    game_camera(w);
    target_camera(w, "mirror", {1000, 0, 0}, 64, 32);
    sprite_showing(w, "self", {1000, 0, 0}, {64, 32}, "target:mirror");
    sprite_showing(w, "screen", {0, 0, 0}, {128, 64}, "target:mirror");
    Image img = g.render(w);
    CHECK(g.renderer.stats().renderTargets == 1);
    // The target is the checker (magenta/black), not the clear colour it would have if the sprite were dropped.
    int checker = 0;
    for (int y = 60; y < 120; y += 3)
        for (int x = 100; x < 220; x += 3)
            if (!near(img.pixel(x, y), kPage, 0.2f)) ++checker;
    CHECK(checker > 100);
}

TEST_CASE("render target: a name nobody renders into draws the checker and does not crash") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    game_camera(w);
    sprite_showing(w, "screen", {0, 0, 0}, {128, 64}, "target:ghost");
    Image img = g.render(w);
    CHECK(g.renderer.stats().renderTargets == 0);
    CHECK(!near(img.pixel(160, 90), Color{0, 0, 0, 1}, 0.2f));
    // The failure names what to do.
    bool listed = false;
    const Json before = g.renderer.asset_report();
    for (const Json& f : before["failures"])
        if (f["path"] == "target:ghost") listed = f["hint"].get<std::string>().find("renderTarget") != std::string::npos;
    CHECK(listed);
    // Once a camera renders into it, the sprite shows it and the stale failure is gone.
    target_camera(w, "ghost", {1000, 0, 0}, 64, 32);
    img = g.render(w);
    CHECK(near(img.pixel(160, 90), kPage));
    const Json after = g.renderer.asset_report();
    for (const Json& f : after["failures"]) CHECK(f["path"] != "target:ghost");
}

TEST_CASE("render target: two cameras with the same name draw one of them, an inactive camera none") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    game_camera(w);
    target_camera(w, "page", {1000, 0, 0}, 64, 32);
    Camera& second = target_camera(w, "page", {2000, 0, 0}, 64, 32);
    second.clearColor = kRed;
    Entity off = make(w, "cam-off", {3000, 0, 0});
    w.add<Camera>(off).renderTarget = "off";
    w.set_active(off, false);
    sprite_showing(w, "screen", {0, 0, 0}, {128, 64}, "target:page");
    Image img = g.render(w);
    CHECK(g.renderer.stats().renderTargets == 1);
    CHECK(near(img.pixel(160, 90), kPage));  // the first one in creation order
}

TEST_CASE("render target: the size can change live and the target keeps working") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    game_camera(w);
    Camera& page = target_camera(w, "page", {1000, 0, 0}, 64, 32);
    page_content(w, {1000, 0, 0});
    sprite_showing(w, "screen", {0, 0, 0}, {128, 64}, "target:page");
    Image img = g.render(w);
    CHECK(near(img.pixel(110, 66), kRed));
    page.renderTargetSize = Vec2{256, 128};
    img = g.render(w);
    CHECK(near(img.pixel(110, 66), kRed));
    CHECK(near(img.pixel(210, 114), kGreen));
    // An impossible size is clamped, not fatal.
    page.renderTargetSize = Vec2{100000, -4};
    img = g.render(w);
    CHECK(g.renderer.stats().renderTargets == 1);
}

TEST_CASE("render target: a mesh shows the target on its texture, the right way up") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity cam = make(w, "game", {0, 0, 3});
    auto& gc = w.add<Camera>(cam);
    gc.projection = Projection::Perspective;
    gc.clearColor = Color{0, 0, 0, 1};
    target_camera(w, "page", {1000, 0, 0}, 128, 64);
    page_content(w, {1000, 0, 0});
    Entity quad = make(w, "screen", {0, 0, 0});
    auto& m = w.add<MeshRenderer>(quad);
    m.mesh = "quad";
    m.texture = "target:page";
    m.unlit = true;
    w.get<Transform>(quad)->scale = {2, 1, 1};
    Image img = g.render(w);
    // The quad is 2 x 1 at distance 3, fov 60: about 1.1 / 3.5 of the height. Find where it is by its colours.
    int redX = -1, redY = -1, greenX = -1, greenY = -1;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) {
            Color c = img.pixel(x, y);
            if (near(c, kRed, 0.12f) && redX < 0) { redX = x; redY = y; }
            if (near(c, kGreen, 0.12f)) { greenX = x; greenY = y; }
        }
    REQUIRE(redX >= 0);
    REQUIRE(greenX >= 0);
    CHECK(redX < 160);
    CHECK(redY < 90);      // top-left
    CHECK(greenX > 160);
    CHECK(greenY > 90);    // bottom-right
}

TEST_CASE("render target: a 3D camera renders its scene into the texture") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    game_camera(w);
    Entity pc = make(w, "cam-room", {1000, 0, 4});
    auto& c = w.add<Camera>(pc);
    c.projection = Projection::Perspective;
    c.renderTarget = "room";
    c.renderTargetSize = Vec2{128, 128};
    c.lighting = CameraLighting::Studio;
    c.clearColor = kPage;
    Entity cube = make(w, "cube", {1000, 0, 0});
    auto& m = w.add<MeshRenderer>(cube);
    m.mesh = "cube";
    m.color = kRed;
    sprite_showing(w, "screen", {0, 0, 0}, {128, 128}, "target:room");
    Image img = g.render(w);
    CHECK(near(img.pixel(160, 90), kRed, 0.5f));
    CHECK(img.pixel(160, 90).r > img.pixel(160, 90).b * 2.0f);
    CHECK(near(img.pixel(100, 40), kPage));   // the target's own clear colour around the cube
}

// The pointer finds a texture coordinate on the surface the renderer draws, so the two must agree vertex by vertex.
TEST_CASE("render target: the mesh surface the pointer uses is the mesh the renderer draws, UVs included") {
    for (const char* name : {"cube", "plane", "quad", "sphere", "cylinder", "capsule", "cone"}) {
        INFO(name);
        std::vector<render::MeshVertex> v;
        std::vector<std::uint32_t> idx;
        REQUIRE(render::build_primitive(name, v, idx));
        auto surface = load_mesh_surface(name);
        REQUIRE(surface.ok());
        const MeshSurface& s = **surface;
        REQUIRE(s.positions.size() == v.size());
        REQUIRE(s.uvs.size() == v.size());
        bool same = true;
        for (std::size_t i = 0; i < v.size(); ++i)
            same = same && std::fabs(s.positions[i].x - v[i].px) < 1e-5f && std::fabs(s.positions[i].y - v[i].py) < 1e-5f &&
                   std::fabs(s.positions[i].z - v[i].pz) < 1e-5f && std::fabs(s.uvs[i].x - v[i].u) < 1e-5f &&
                   std::fabs(s.uvs[i].y - v[i].v) < 1e-5f;
        CHECK(same);
        // The same triangles (the renderer may wind them the other way round).
        REQUIRE(s.indices.size() == idx.size());
        auto triples = [](const std::vector<std::uint32_t>& ix) {
            std::vector<std::array<std::uint32_t, 3>> t;
            for (std::size_t i = 0; i + 2 < ix.size(); i += 3) {
                std::array<std::uint32_t, 3> a{ix[i], ix[i + 1], ix[i + 2]};
                std::sort(a.begin(), a.end());
                t.push_back(a);
            }
            std::sort(t.begin(), t.end());
            return t;
        };
        CHECK(triples(s.indices) == triples(idx));
    }
}

namespace {

std::string base64(const std::vector<std::uint8_t>& d) {
    static const char* t = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    std::string out;
    for (std::size_t i = 0; i < d.size(); i += 3) {
        const std::uint32_t n = (d[i] << 16) | (i + 1 < d.size() ? d[i + 1] << 8 : 0) | (i + 2 < d.size() ? d[i + 2] : 0);
        out += t[(n >> 18) & 63];
        out += t[(n >> 12) & 63];
        out += i + 1 < d.size() ? t[(n >> 6) & 63] : '=';
        out += i + 2 < d.size() ? t[n & 63] : '=';
    }
    return out;
}

}  // namespace

TEST_CASE("render target: a glTF model's UVs are the ones the pointer reads") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // A strip bent into a quarter circle (radius 2, 4 segments), u along the arc and v 0 at the top: a curved screen.
    std::vector<float> floats;
    for (int i = 0; i <= 4; ++i) {
        const float a = float(i) / 4.0f * (kPi * 0.5f);
        floats.insert(floats.end(), {2.0f * std::sin(a), 0.5f, -2.0f * std::cos(a) + 2.0f});   // top row
        floats.insert(floats.end(), {2.0f * std::sin(a), -0.5f, -2.0f * std::cos(a) + 2.0f});  // bottom row
    }
    for (int i = 0; i <= 4; ++i) floats.insert(floats.end(), {float(i) / 4.0f, 0.0f, float(i) / 4.0f, 1.0f});
    std::vector<std::uint8_t> bytes(floats.size() * 4);
    std::memcpy(bytes.data(), floats.data(), bytes.size());
    std::vector<std::uint16_t> ix;
    for (std::uint16_t i = 0; i < 4; ++i) ix.insert(ix.end(), {std::uint16_t(2 * i), std::uint16_t(2 * i + 1), std::uint16_t(2 * i + 2),
                                                               std::uint16_t(2 * i + 2), std::uint16_t(2 * i + 1), std::uint16_t(2 * i + 3)});
    const std::size_t at = bytes.size();
    bytes.resize(at + ix.size() * 2);
    std::memcpy(bytes.data() + at, ix.data(), ix.size() * 2);
    const std::string uri = "data:application/octet-stream;base64," + base64(bytes);
    const Json gltf = Json::parse(R"({"asset":{"version":"2.0"},"scene":0,"scenes":[{"nodes":[0]}],"nodes":[{"mesh":0}],
        "meshes":[{"primitives":[{"attributes":{"POSITION":0,"TEXCOORD_0":1},"indices":2}]}],
        "buffers":[{"byteLength":)" + std::to_string(bytes.size()) + R"(,"uri":")" + uri + R"("}],
        "bufferViews":[{"buffer":0,"byteOffset":0,"byteLength":120},{"buffer":0,"byteOffset":120,"byteLength":80},
                       {"buffer":0,"byteOffset":200,"byteLength":48}],
        "accessors":[{"bufferView":0,"componentType":5126,"count":10,"type":"VEC3","min":[0,-0.5,0],"max":[2,0.5,2]},
                     {"bufferView":1,"componentType":5126,"count":10,"type":"VEC2"},
                     {"bufferView":2,"componentType":5123,"count":24,"type":"SCALAR"}]})");
    std::filesystem::create_directories(g.projectDir / "assets");
    std::ofstream(g.projectDir / "assets/curved.gltf", std::ios::binary) << gltf.dump();
    auto surface = load_mesh_surface("assets/curved.gltf");
    const std::string why = surface.ok() ? std::string() : surface.error().message;
    INFO(why);
    REQUIRE(surface.ok());
    const MeshSurface& s = **surface;
    REQUIRE(s.positions.size() == 10);
    CHECK(s.uvs[4].x == doctest::Approx(0.5f));
    CHECK(s.uvs[5].y == doctest::Approx(1.0f));
    // A ray from the centre of the circle (0, 0, 2) towards the middle of the arc meets the strip at u = 0.5.
    const float a = kPi * 0.25f;
    auto hit = raycast_surface(s, Mat4::identity(), {0, 0.1f, 2}, {std::sin(a), 0, -std::cos(a)});
    REQUIRE(hit.has_value());
    CHECK(hit->uv.x == doctest::Approx(0.5f).epsilon(0.02f));
    CHECK(hit->uv.y == doctest::Approx(0.4f).epsilon(0.02f));
    // The renderer loads the same file: it draws without errors.
    World w;
    game_camera(w);
    Entity e = make(w, "bent", {0, 0, 0});
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = "assets/curved.gltf";
    m.unlit = true;
    g.render(w);
    CHECK(g.renderer.stats().meshes == 1);
}

// On GL the target's flip copy draws with the colour filter's pipeline, and it can run before any Camera.colorFilter has made
// that shader: the pipeline must make it, on a fresh Gpu too, or the failed pipeline stays cached for the whole process.
TEST_CASE("render target: the colour filter pipeline is valid as the first thing a fresh Gpu makes") {
    gfx();  // the sokol context
    render::Gpu fresh;
    std::string error;
    REQUIRE(fresh.init(1, &error));
    CHECK(sg_query_pipeline_state(fresh.colorfilter_pipeline()) == SG_RESOURCESTATE_VALID);
    CHECK(sg_query_pipeline_state(fresh.colorfilter_pipeline()) == SG_RESOURCESTATE_VALID);
    fresh.shutdown();
}
