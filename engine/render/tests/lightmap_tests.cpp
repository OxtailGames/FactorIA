// M73.4a: the lightmap geometry (UVs) and the runtime that draws a baked lightmap
// (docs/design/ARCHITECTURE_RENDERING_LIGHTING.md, "Lightmaps"): the page and the manifest next to a scene, the lightmap
// UV, the lights of mode baked, the files read again on change.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "fa/core/image_float.h"
#include "fa/render/lightmap_geometry.h"
#include "fa/scene/lightmap_manifest.h"
#include "fa/scene/lightmap_uv.h"

using namespace fa;
using namespace fa::test;

namespace {

// Errors logged while alive (the sink may run on a job worker thread: a locked shared buffer).
struct LmErrorLog {
    struct Lines {
        std::mutex mu;
        std::vector<std::string> lines;
    };
    std::shared_ptr<Lines> shared = std::make_shared<Lines>();
    int id;
    LmErrorLog()
        : id(add_log_sink([l = shared](const LogEntry& e) {
              if (e.level != LogLevel::Error) return;
              std::lock_guard<std::mutex> lk(l->mu);
              l->lines.push_back(e.message);
          })) {}
    ~LmErrorLog() { remove_log_sink(id); }
    LmErrorLog(const LmErrorLog&) = delete;
    LmErrorLog& operator=(const LmErrorLog&) = delete;
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
Entity add_light(World& w, LightMode mode, float intensity = 1.0f) {
    Entity e = make(w, "light", {0, 5, 0});
    w.get<Transform>(e)->rotation = {-50, 30, 0};
    auto& l = w.add<Light>(e);
    l.type = LightType::Directional;
    l.intensity = intensity;
    l.mode = mode;
    return e;
}

// A quad facing +Z (x and y from -1.5 to 1.5) whose second UV set is the whole unit square: v = 0 at its bottom edge,
// v = 1 at its top.
void write_uv1_quad(const char* name) {
    const float pos[12] = {-1.5f, -1.5f, 0, 1.5f, -1.5f, 0, 1.5f, 1.5f, 0, -1.5f, 1.5f, 0};
    const float uv1[8] = {0, 0, 1, 0, 1, 1, 0, 1};
    const std::uint16_t ix[6] = {0, 1, 2, 0, 2, 3};
    std::vector<std::uint8_t> bytes(48 + 12 + 32);
    std::memcpy(bytes.data(), pos, 48);
    std::memcpy(bytes.data() + 48, ix, 12);
    std::memcpy(bytes.data() + 60, uv1, 32);
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
    const Json gltf = Json::parse(
        R"({"asset":{"version":"2.0"},"scene":0,"scenes":[{"nodes":[0]}],"nodes":[{"mesh":0}],
        "meshes":[{"primitives":[{"attributes":{"POSITION":0,"TEXCOORD_1":2},"indices":1}]}],
        "buffers":[{"byteLength":)" +
        std::to_string(bytes.size()) + R"(,"uri":"data:application/octet-stream;base64,)" + b64 + R"("}],
        "bufferViews":[{"buffer":0,"byteOffset":0,"byteLength":48},{"buffer":0,"byteOffset":48,"byteLength":12},
                       {"buffer":0,"byteOffset":60,"byteLength":32}],
        "accessors":[{"bufferView":0,"componentType":5126,"count":4,"type":"VEC3","min":[-1.5,-1.5,0],"max":[1.5,1.5,0]},
                     {"bufferView":1,"componentType":5123,"count":6,"type":"SCALAR"},
                     {"bufferView":2,"componentType":5126,"count":4,"type":"VEC2"}]})");
    REQUIRE(fs::write_text(name, gltf.dump()).ok());
}

// A page of `size` x `size` texels: `fill(x, y)` is the texel (row y = 0 is the first row of the file).
template <typename F>
void write_page(const char* file, int size, F fill) {
    auto img = ImageF::create(size, size, 3);
    REQUIRE(img.ok());
    for (int y = 0; y < size; ++y)
        for (int x = 0; x < size; ++x) {
            const Vec3 c = fill(x, y);
            float* p = img->at(x, y);
            p[0] = c.x;
            p[1] = c.y;
            p[2] = c.z;
        }
    REQUIRE(save_hdr(*img, file).ok());
}

struct Placed {
    Entity entity;
    const char* mesh;
    int page = 0;
    float so[4] = {1, 1, 0, 0};
    std::string hash =
        "geometry";  // "geometry": the real hash of the mesh's lightmap geometry; "": not checked; else as given
};

// Writes scenes/<name>.lightmap.json for the placed entities and sets SceneSettings.lightmaps.
void write_manifest(World& w, const char* name, const std::vector<std::pair<const char*, int>>& pages,
                    const std::vector<Placed>& placed) {
    LightmapManifest m;
    m.uvVersion = kLightmapUvVersion;
    m.settingsHash = "0123456789abcdef";
    for (const auto& [file, size] : pages) m.pages.push_back({file, size, size});
    for (const Placed& p : placed) {
        LightmapEntry e;
        e.id = w.id_of(p.entity);
        e.mesh = p.mesh;
        e.page = p.page;
        for (int i = 0; i < 4; ++i) e.scaleOffset[i] = p.so[i];
        auto geo = render::lightmap_mesh_geometry(p.mesh);
        REQUIRE(geo.ok());
        e.uv = geo->uvKind;
        e.meshHash = p.hash == "geometry" ? lightmap_hash_hex(geo->hash) : p.hash;
        m.entities.push_back(e);
    }
    const std::string path = std::string("scenes/") + name + ".lightmap.json";
    REQUIRE(fs::write_text(path, lightmap_manifest_to_json(m).dump(2)).ok());
    w.settings().lightmaps = path;
}

float red_minus_blue(const Color& c) { return c.r - c.b; }

}  // namespace

TEST_CASE("lightmap geometry: the primitives unwrap the same way on every call, inside the unit square, with every "
          "triangle kept") {
    for (const char* name : {"cube", "sphere", "plane", "cylinder", "capsule", "cone", "quad"}) {
        CAPTURE(std::string(name));
        auto a = render::lightmap_mesh_geometry(name);
        auto b = render::lightmap_mesh_geometry(name);
        REQUIRE(a.ok());
        REQUIRE(b.ok());
        CHECK(a->uvKind == "generated");
        CHECK(a->hash == b->hash);
        CHECK(a->hash != 0);
        CHECK(a->uv.size() == a->positions.size());
        CHECK(a->normals.size() == a->positions.size());
        CHECK(a->indices.size() >= 6);
        CHECK(a->indices.size() % 3 == 0);
        CHECK(a->partFirstIndex.size() == 2);
        CHECK(a->partFirstIndex.back() == a->indices.size());
        CHECK(a->surfaceArea > 0.0);
        for (const Vec2& t : a->uv) {
            CHECK(t.x >= -1e-4f);
            CHECK(t.x <= 1.0001f);
            CHECK(t.y >= -1e-4f);
            CHECK(t.y <= 1.0001f);
        }
        for (std::uint32_t i : a->indices) CHECK(i < a->positions.size());
    }
    // The cube has 12 triangles however its vertices are split along the charts' seams.
    CHECK(render::lightmap_mesh_geometry("cube")->indices.size() == 36);
    // Different meshes have different geometry hashes.
    CHECK(render::lightmap_mesh_geometry("cube")->hash != render::lightmap_mesh_geometry("sphere")->hash);
    CHECK(render::lightmap_mesh_geometry("")->uvKind == "generated");
}

TEST_CASE("lightmap geometry: a model with TEXCOORD_1 keeps it, a missing file and a script mesh are refused with a "
          "way out") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    write_uv1_quad("assets/lm_quad.gltf");
    auto geo = render::lightmap_mesh_geometry("assets/lm_quad.gltf");
    REQUIRE(geo.ok());
    CHECK(geo->uvKind == "gltf");
    REQUIRE(geo->uv.size() == 4);
    CHECK(geo->uv[0].x == 0.0f);
    CHECK(geo->uv[0].y == 0.0f);
    CHECK(geo->uv[2].x == 1.0f);
    CHECK(geo->uv[2].y == 1.0f);
    CHECK(geo->indices.size() == 6);
    CHECK(geo->surfaceArea == doctest::Approx(9.0));

    auto missing = render::lightmap_mesh_geometry("assets/no_such_model.gltf");
    REQUIRE_FALSE(missing.ok());
    CHECK_FALSE(missing.error().hint.empty());
    auto script = render::lightmap_mesh_geometry("mesh:3");
    REQUIRE_FALSE(script.ok());
    CHECK(script.error().message.find("script") != std::string::npos);
    CHECK_FALSE(script.error().hint.empty());
    auto notModel = render::lightmap_mesh_geometry("assets/readme.txt");
    REQUIRE_FALSE(notModel.ok());
    CHECK(notModel.error().message.find("primitive") != std::string::npos);
}

TEST_CASE("lightmap: the page is read with row 0 at v = 0 (the bottom edge of a model whose second UV set is the unit "
          "square)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    g.renderer.clear_asset_cache();
    std::filesystem::create_directories(g.projectDir / "scenes");
    write_uv1_quad("assets/lm_quad.gltf");
    // The first rows of the file are red, the last ones blue.
    write_page("scenes/orient.lightmap.0.hdr", 8,
               [](int, int y) { return y < 4 ? Vec3{0.8f, 0, 0} : Vec3{0, 0, 0.8f}; });
    World w;
    add_camera(w, {0, 0, 4}, {0, 0, 0});
    w.settings().ambientLight = Color{0, 0, 0, 1};
    Entity quad = add_mesh(w, "assets/lm_quad.gltf", {0, 0, 0}, Color::white());
    write_manifest(w, "orient", {{"scenes/orient.lightmap.0.hdr", 8}}, {{quad, "assets/lm_quad.gltf"}});
    LmErrorLog log;
    const Image img = g.render(w);
    CHECK(log.messages().empty());
    // v = 0 is the bottom of the quad (the lower half of the picture): the file's first rows.
    CHECK(red_minus_blue(img.pixel(160, 130)) > 0.2f);
    CHECK(red_minus_blue(img.pixel(160, 50)) < -0.2f);
    // Without the lightmap the quad has only the (black) ambient light.
    w.settings().lightmaps.clear();
    const Image plain = g.render(w);
    CHECK(plain.pixel(160, 130).r < 0.05f);
    CHECK(plain.pixel(160, 50).b < 0.05f);
}

TEST_CASE(
    "lightmap: a lightmapped entity is lit by its page instead of the ambient light, the others are drawn as before") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    g.renderer.clear_asset_cache();
    std::filesystem::create_directories(g.projectDir / "scenes");
    write_page("scenes/amb.lightmap.0.hdr", 4, [](int, int) { return Vec3{0.6f, 0.3f, 0.0f}; });
    World w;
    add_camera(w, {0, 0, 7}, {0, 0, 0});
    w.settings().ambientLight = Color{0, 0, 0.7f, 1};
    Entity lit = add_mesh(w, "cube", {-1.6f, 0, 0}, Color::white(), {1.5f, 1.5f, 1.5f});
    Entity other = add_mesh(w, "cube", {1.6f, 0, 0}, Color::white(), {1.5f, 1.5f, 1.5f});
    (void)other;
    write_manifest(w, "amb", {{"scenes/amb.lightmap.0.hdr", 4}}, {{lit, "cube"}});
    LmErrorLog log;
    const Image img = g.render(w);
    CHECK(log.messages().empty());
    const Color left = img.pixel(160 - 38, 90), right = img.pixel(160 + 38, 90);
    CHECK(red_minus_blue(left) > 0.15f);   // the page: warm
    CHECK(red_minus_blue(right) < -0.1f);  // the ambient light: blue
    // The lightmap is one input of the picture, not a tint: the same cube without an entry is the blue one.
    w.settings().lightmaps.clear();
    const Image plain = g.render(w);
    CHECK(red_minus_blue(plain.pixel(160 - 38, 90)) < -0.1f);
}

TEST_CASE(
    "lightmap: a light of mode baked is left out of lightmapped entities only, a mixed or realtime light is not") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    g.renderer.clear_asset_cache();
    std::filesystem::create_directories(g.projectDir / "scenes");
    write_page("scenes/dark.lightmap.0.hdr", 4, [](int, int) { return Vec3{0, 0, 0}; });
    auto frame = [&](bool withLight, LightMode mode, bool lightmapped) {
        World w;
        add_camera(w, {0, 2.5f, 6}, {0, 0, 0});
        w.settings().ambientLight = Color{0, 0, 0, 1};
        Entity cube = add_mesh(w, "cube", {0, 0, 0}, Color::hex(0xc08040), {1.5f, 1.5f, 1.5f});
        if (withLight) add_light(w, mode);
        if (lightmapped) write_manifest(w, "dark", {{"scenes/dark.lightmap.0.hdr", 4}}, {{cube, "cube"}});
        return g.render(w);
    };
    const Image noLight = frame(false, LightMode::Realtime, true);
    const Image baked = frame(true, LightMode::Baked, true);
    const Image realtime = frame(true, LightMode::Realtime, true);
    const Image mixed = frame(true, LightMode::Mixed, true);
    CHECK(diff_images(noLight, baked, 0.0f).maxError == 0.0);  // the baked light is in the (dark) page, not drawn again
    CHECK(diff_images(noLight, realtime, 0.0f).maxError > 0.1);
    CHECK(diff_images(noLight, mixed, 0.0f).maxError > 0.1);
    // Without a lightmap entry a baked light still lights the entity as a realtime one: nothing else would, and the
    // golden pictures of scenes without a bake stay the same.
    const Image bakedNoMap = frame(true, LightMode::Baked, false);
    const Image realtimeNoMap = frame(true, LightMode::Realtime, false);
    CHECK(diff_images(bakedNoMap, realtimeNoMap, 0.0f).maxError == 0.0);
    CHECK(diff_images(noLight, bakedNoMap, 0.0f).maxError > 0.1);
}

TEST_CASE("lightmap: a manifest that does not load, a mesh that changed and a page that is gone are reported once and "
          "the scene is drawn without") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    g.renderer.clear_asset_cache();
    std::filesystem::create_directories(g.projectDir / "scenes");
    write_page("scenes/bad.lightmap.0.hdr", 4, [](int, int) { return Vec3{0.8f, 0, 0}; });
    auto failures = [&](const char* kind) {
        int n = 0;
        const Json report = g.renderer.asset_report();
        for (const Json& f : report["failures"])
            if (f["kind"].get<std::string>() == kind) ++n;
        return n;
    };
    auto frame = [&](World& w) { return g.render(w); };
    World w;
    add_camera(w, {0, 0, 5}, {0, 0, 0});
    w.settings().ambientLight = Color{0, 0, 0, 1};
    Entity cube = add_mesh(w, "cube", {0, 0, 0}, Color::white(), {1.5f, 1.5f, 1.5f});
    // 1. a manifest with a key that does not exist
    REQUIRE(
        fs::write_text("scenes/broken.lightmap.json", R"({"version":1,"uvVersion":1,"pagez":[],"entities":[]})").ok());
    w.settings().lightmaps = "scenes/broken.lightmap.json";
    {
        LmErrorLog log;
        const Image img = frame(w);
        frame(w);
        CHECK(log.count("scenes/broken.lightmap.json") == 1);  // once, not per frame
        CHECK(log.count("/pagez") >= 1);
        CHECK(log.count("pages") >= 1);  // the did-you-mean
        CHECK(img.pixel(160, 90).r < 0.05f);
        CHECK(failures("lightmap") == 1);
    }
    // 2. an entry whose mesh hash is not the mesh's now
    write_manifest(w, "stale", {{"scenes/bad.lightmap.0.hdr", 4}},
                   {{cube, "cube", 0, {1, 1, 0, 0}, "00000000deadbeef"}});
    {
        LmErrorLog log;
        const Image img = frame(w);
        frame(w);
        CHECK(log.count("different version of the mesh") == 1);
        CHECK(img.pixel(160, 90).r < 0.05f);
        CHECK(failures("lightmap-stale") == 1);
    }
    // 3. the page file is missing
    write_manifest(w, "gone", {{"scenes/not_baked.lightmap.0.hdr", 4}}, {{cube, "cube"}});
    {
        LmErrorLog log;
        const Image img = frame(w);
        frame(w);
        CHECK(log.count("scenes/not_baked.lightmap.0.hdr") == 1);
        CHECK(img.pixel(160, 90).r < 0.05f);
        CHECK(failures("lightmap-page") == 1);
    }
}

TEST_CASE("lightmap: a page or manifest that changes on disk is read again (hot reload)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    g.renderer.clear_asset_cache();
    std::filesystem::create_directories(g.projectDir / "scenes");
    write_page("scenes/hot.lightmap.0.hdr", 4, [](int, int) { return Vec3{0.8f, 0, 0}; });
    World w;
    add_camera(w, {0, 0, 5}, {0, 0, 0});
    w.settings().ambientLight = Color{0, 0, 0, 1};
    Entity cube = add_mesh(w, "cube", {0, 0, 0}, Color::white(), {1.5f, 1.5f, 1.5f});
    write_manifest(w, "hot", {{"scenes/hot.lightmap.0.hdr", 4}}, {{cube, "cube"}});
    LmErrorLog log;
    const Image red = g.render(w);
    CHECK(red_minus_blue(red.pixel(160, 90)) > 0.2f);
    // Another bake: the same file now holds blue light.
    write_page("scenes/hot.lightmap.0.hdr", 4, [](int, int) { return Vec3{0, 0, 0.8f}; });
    const Image stale = g.render(w);
    CHECK(red_minus_blue(stale.pixel(160, 90)) > 0.2f);  // the renderer keeps what it read until it is told
    g.renderer.reload_asset("scenes/hot.lightmap.0.hdr");
    const Image blue = g.render(w);
    CHECK(red_minus_blue(blue.pixel(160, 90)) < -0.2f);
    // The manifest too: an entity that is no longer listed is drawn without a lightmap.
    write_manifest(w, "hot", {{"scenes/hot.lightmap.0.hdr", 4}}, {});
    g.renderer.reload_asset("scenes/hot.lightmap.json");
    g.renderer.reload_asset("scenes/hot.lightmap.json");
    const Image none = g.render(w);
    CHECK(none.pixel(160, 90).b < 0.05f);
    CHECK(log.messages().empty());
}

TEST_CASE(
    "lightmap: a scene lit by a lightmap renders its golden (two entities share a page, each with its rectangle)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    g.renderer.clear_asset_cache();
    std::filesystem::create_directories(g.projectDir / "scenes");
    // Left half of the page: red grows with u, green with v; right half: the same in blue and green.
    write_page("scenes/golden.lightmap.0.hdr", 16, [](int x, int y) {
        const float u = float(x % 8) / 7.0f, v = float(y) / 15.0f;
        return x < 8 ? Vec3{0.2f + 0.8f * u, 0.8f * v, 0.05f} : Vec3{0.05f, 0.8f * v, 0.2f + 0.8f * u};
    });
    World w;
    add_camera(w, {0, 3.2f, 6.5f}, {0, 0.2f, 0});
    w.settings().ambientLight = Color{0.05f, 0.05f, 0.05f, 1};
    Entity ground = add_mesh(w, "plane", {0, -0.75f, 0}, Color::hex(0xb0b0b0), {8, 1, 5});
    Entity cube = add_mesh(w, "cube", {-1.4f, 0, 0}, Color::hex(0xe0e0e0), {1.5f, 1.5f, 1.5f});
    Entity sphere = add_mesh(w, "sphere", {1.4f, 0, 0}, Color::hex(0xe0e0e0), {1.5f, 1.5f, 1.5f});
    write_manifest(w, "golden", {{"scenes/golden.lightmap.0.hdr", 16}},
                   {{ground, "plane", 0, {0.5f, 1, 0, 0}},
                    {cube, "cube", 0, {0.5f, 1, 0, 0}},
                    {sphere, "sphere", 0, {0.5f, 1, 0.5f, 0}}});
    LmErrorLog log;
    const Image img = g.render(w);
    CHECK(log.messages().empty());
    CHECK(g.renderer.stats().meshes == 3);
    expect_golden(img, "3d_lightmap");
}

TEST_CASE(
    "lightmap: with an environmentMap a lightmapped entity keeps the picture's reflection, the page replaces only "
    "the diffuse ambient light") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("environmentMap")) {
        MESSAGE("environmentMap is not supported on this GPU: not run");
        return;
    }
    g.renderer.clear_asset_cache();
    std::filesystem::create_directories(g.projectDir / "scenes");
    std::filesystem::create_directories(g.projectDir / "assets");
    {  // a green room: an equirectangular picture is twice as wide as it is tall
        auto room = ImageF::create(16, 8, 3);
        REQUIRE(room.ok());
        for (int y = 0; y < 8; ++y)
            for (int x = 0; x < 16; ++x) {
                float* px = room->at(x, y);
                px[0] = 0.1f;
                px[1] = 1.0f;
                px[2] = 0.1f;
            }
        REQUIRE(save_hdr(*room, "assets/lm_env.hdr").ok());
    }
    write_page("scenes/envlm.lightmap.0.hdr", 4, [](int, int) { return Vec3{0, 0, 0}; });  // a black page
    auto scene = [&](bool lightmapped) {
        World w;
        add_camera(w, {0, 0, 8}, {0, 0, 0});
        w.settings().ambientLight = Color{0, 0, 0, 1};
        w.settings().environmentMap = "assets/lm_env.hdr";
        Entity mirror = add_mesh(w, "sphere", {-1.6f, 0, 0}, Color::white(), {2, 2, 2});
        w.get<MeshRenderer>(mirror)->metallic = 1.0f;
        w.get<MeshRenderer>(mirror)->roughness = 0.1f;
        Entity matte = add_mesh(w, "sphere", {1.6f, 0, 0}, Color::white(), {2, 2, 2});
        w.get<MeshRenderer>(matte)->metallic = 0.0f;
        w.get<MeshRenderer>(matte)->roughness = 1.0f;
        if (lightmapped)
            write_manifest(w, "envlm", {{"scenes/envlm.lightmap.0.hdr", 4}}, {{mirror, "sphere"}, {matte, "sphere"}});
        return g.render(w);
    };
    LmErrorLog log;
    const Image plain = scene(false), baked = scene(true);
    CHECK(log.messages().empty());
    const int y = 90, xMirror = 160 - 38, xMatte = 160 + 38;
    // The mirror reflects the picture the same way with or without the page (the page holds no reflection).
    const Color mp = plain.pixel(xMirror, y), mb = baked.pixel(xMirror, y);
    CHECK(mp.g > 0.3f);
    CHECK(std::fabs(mp.g - mb.g) < 0.03f);
    CHECK(std::fabs(mp.r - mb.r) < 0.03f);
    // The matte one is lit by the picture's irradiance without the page, and by the (black) page with it.
    const Color dp = plain.pixel(xMatte, y), db = baked.pixel(xMatte, y);
    CHECK(dp.g > 0.3f);
    CHECK(db.g < dp.g * 0.4f);
}
