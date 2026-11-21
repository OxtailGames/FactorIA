// M73.4d: baked light probes at runtime (docs/design/ARCHITECTURE_BAKING.md, "Light probes and mixed lights"): a mesh without a lightmap receives the
// probes' SH in place of the sky's ambient, a Baked light lights it only through them, and a scene without probes is drawn as before.
#include "test_util.h"

#include <cmath>
#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/image_float.h"
#include "fa/render/lightmap_geometry.h"
#include "fa/scene/light_probes.h"
#include "fa/scene/lightmap_manifest.h"
#include "fa/scene/lightmap_uv.h"

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
Entity add_light(World& w, LightMode mode, float intensity = 1.0f) {
    Entity e = make(w, "light", {0, 5, 0});
    w.get<Transform>(e)->rotation = {-50, 30, 0};
    auto& l = w.add<Light>(e);
    l.type = LightType::Directional;
    l.intensity = intensity;
    l.mode = mode;
    return e;
}

// The SH of a radiance that is `base` all around plus `xTerm` along x (the real SH of band 1: c[3] is the x term): +x sees base + xTerm * 0.33
// (0.3257 per unit of c[3] after the cosine lobe), -x base - xTerm * 0.33.
ShL2 sh_gray_with_x(float base, Vec3 xTerm) {
    ShL2 s;
    for (Vec3& c : s.c) c = {0, 0, 0};
    s.c[0] = {base * 3.5449077f, base * 3.5449077f, base * 3.5449077f};
    s.c[3] = xTerm;
    return s;
}

// Writes scenes/<name>.lightmap.json with a probe file (one grid group of `size` at the origin, every probe holding `sh`) and, when `page`
// is not empty, one lightmapped entity. Sets SceneSettings.lightmaps.
void write_probe_manifest(World& w, const char* name, const ShL2& sh, Vec3 size = {6, 4, 6},
                          const std::vector<Entity>& lightmapped = {}, const char* pageFile = nullptr) {
    ProbeSet set;
    LightProbeGroup comp;
    comp.size = size;
    comp.spacing = 2.0f;
    REQUIRE(add_probe_group(set, "group", comp, {0, 0, 0}).ok());
    set.sh.assign(set.size(), sh);
    set.valid.assign(set.size(), 1);
    const std::string probesFile = std::string("scenes/") + name + ".lightmap.probes";
    const std::vector<std::uint8_t> bytes = encode_probe_set(set);
    REQUIRE(fs::write_bytes(probesFile, bytes.data(), bytes.size()).ok());
    LightmapManifest m;
    m.uvVersion = kLightmapUvVersion;
    m.settingsHash = "0123456789abcdef";
    if (pageFile) m.pages.push_back({pageFile, 4, 4});
    for (Entity e : lightmapped) {
        LightmapEntry en;
        en.id = w.id_of(e);
        en.mesh = "cube";
        en.page = 0;
        auto geo = render::lightmap_mesh_geometry("cube");
        REQUIRE(geo.ok());
        en.uv = geo->uvKind;
        en.meshHash = lightmap_hash_hex(geo->hash);
        m.entities.push_back(en);
    }
    m.probes.file = probesFile;
    m.probes.count = int(set.size());
    m.probes.invalid = 0;
    const std::string path = std::string("scenes/") + name + ".lightmap.json";
    REQUIRE(fs::write_text(path, lightmap_manifest_to_json(m).dump(2)).ok());
    w.settings().lightmaps = path;
}

float red_minus_blue(const Color& c) { return c.r - c.b; }

}  // namespace

TEST_CASE(
    "light probes: a mesh without a lightmap receives the probes' SH, directionally, in place of the ambient light") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    g.renderer.clear_asset_cache();
    std::filesystem::create_directories(g.projectDir / "scenes");
    World w;
    add_camera(w, {0, 0, 5}, {0, 0, 0});
    w.settings().ambientLight = Color{0, 0, 0, 1};
    add_mesh(w, "sphere", {0, 0, 0}, Color::white(), {2, 2, 2});
    const Image plain = g.render(w);
    CHECK(plain.pixel(160 + 18, 90).r < 0.05f);
    // A sphere beside a red wall: red light comes from +x (the x term of the SH), nothing from -x.
    write_probe_manifest(w, "dyn", sh_gray_with_x(0.5f, {2.5f, 0, 0}));
    const Image img = g.render(w);
    const Color right = img.pixel(160 + 18, 90), left = img.pixel(160 - 18, 90);
    CHECK(red_minus_blue(right) > 0.2f);
    CHECK(red_minus_blue(left) < -0.2f);
    // A mesh that opts out of global illumination keeps the sky's ambient, a lightmapScale does not matter without a lightmap.
    World w2;
    add_camera(w2, {0, 0, 5}, {0, 0, 0});
    w2.settings().ambientLight = Color{0, 0, 0, 1};
    Entity noGi = add_mesh(w2, "sphere", {0, 0, 0}, Color::white(), {2, 2, 2});
    w2.get<MeshRenderer>(noGi)->receiveGI = false;
    write_probe_manifest(w2, "dyn", sh_gray_with_x(0.5f, {2.5f, 0, 0}));
    CHECK(diff_images(g.render(w2), plain, 0.0f).maxError == 0.0);
}

TEST_CASE(
    "light probes: outside the grid the sky's ambient stays, a probeAnchor inside brings the probes to a mesh outside, "
    "and a lightmapped mesh keeps its page") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    g.renderer.clear_asset_cache();
    std::filesystem::create_directories(g.projectDir / "scenes");
    // The sphere is 12 m from the origin, 9 m outside the grid's edge: the sky's ambient (black) and the probes' SH is not read.
    World w;
    add_camera(w, {12, 0, 5}, {12, 0, 0});
    w.settings().ambientLight = Color{0, 0, 0, 1};
    Entity sphere = add_mesh(w, "sphere", {12, 0, 0}, Color::white(), {2, 2, 2});
    const Image none = g.render(w);
    write_probe_manifest(w, "far", sh_gray_with_x(0.5f, {2.5f, 0, 0}));
    CHECK(diff_images(g.render(w), none, 0.0f).maxError == 0.0);
    // An anchor at the centre of the grid: the sphere is lit as if it stood there.
    Entity anchor = make(w, "anchor", {0, 0, 0});
    w.get<MeshRenderer>(sphere)->probeAnchor = anchor;
    const Image anchored = g.render(w);
    CHECK(red_minus_blue(anchored.pixel(160 + 18, 90)) > 0.2f);
    CHECK(red_minus_blue(anchored.pixel(160 - 18, 90)) < -0.2f);
    // A lightmapped cube inside the grid reads its (red) page, never the probes' (blue) SH.
    {
        auto img = ImageF::create(4, 4, 3);
        REQUIRE(img.ok());
        for (int y = 0; y < 4; ++y)
            for (int x = 0; x < 4; ++x) {
                float* p = img->at(x, y);
                p[0] = 0.6f;
                p[1] = 0.0f;
                p[2] = 0.0f;
            }
        REQUIRE(save_hdr(*img, "scenes/probe_page.lightmap.0.hdr").ok());
    }
    World w3;
    add_camera(w3, {0, 0, 6}, {0, 0, 0});
    w3.settings().ambientLight = Color{0, 0, 0, 1};
    Entity cube = add_mesh(w3, "cube", {0, 0, 0}, Color::white(), {1.5f, 1.5f, 1.5f});
    write_probe_manifest(w3, "mixedmap", sh_gray_with_x(0.5f, {0, 0, 0}), {6, 4, 6}, {cube},
                         "scenes/probe_page.lightmap.0.hdr");
    const Color c = g.render(w3).pixel(160, 90);
    CHECK(red_minus_blue(c) > 0.15f);
}

TEST_CASE("light probes: a scene without probes is drawn exactly as before, with or without a manifest") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    g.renderer.clear_asset_cache();
    std::filesystem::create_directories(g.projectDir / "scenes");
    World w;
    add_camera(w, {0, 1, 5}, {0, 0, 0});
    w.settings().ambientLight = Color{0.1f, 0.2f, 0.3f, 1};
    add_mesh(w, "sphere", {0, 0, 0}, Color::hex(0xc08040), {2, 2, 2});
    add_light(w, LightMode::Realtime);
    const Image plain = g.render(w);
    LightmapManifest m;
    m.uvVersion = kLightmapUvVersion;
    m.settingsHash = "0123456789abcdef";
    REQUIRE(fs::write_text("scenes/noprobes.lightmap.json", lightmap_manifest_to_json(m).dump(2)).ok());
    w.settings().lightmaps = "scenes/noprobes.lightmap.json";
    CHECK(diff_images(g.render(w), plain, 0.0f).maxError == 0.0);
}

TEST_CASE(
    "light probes: light mode against receiver, a Baked light lights a probe-covered mesh only through its probes") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    g.renderer.clear_asset_cache();
    std::filesystem::create_directories(g.projectDir / "scenes");
    // The probes hold black light: every pixel difference below is a light drawn in real time.
    const ShL2 black = sh_gray_with_x(0.0f, {0, 0, 0});
    auto frame = [&](bool withLight, LightMode mode, float x) {
        World w;
        add_camera(w, {x, 2.5f, 6}, {x, 0, 0});
        w.settings().ambientLight = Color{0, 0, 0, 1};
        add_mesh(w, "sphere", {x, 0, 0}, Color::hex(0xc08040), {2, 2, 2});
        if (withLight) add_light(w, mode);
        write_probe_manifest(w, "modes", black);
        return g.render(w);
    };
    // A covered receiver (x = 0): the Baked light is in its probes, so it is not drawn again; Realtime and Mixed light it.
    const Image dark = frame(false, LightMode::Realtime, 0.0f);
    const Image baked = frame(true, LightMode::Baked, 0.0f);
    const Image realtime = frame(true, LightMode::Realtime, 0.0f);
    const Image mixed = frame(true, LightMode::Mixed, 0.0f);
    CHECK(diff_images(dark, baked, 0.0f).maxError == 0.0);
    CHECK(diff_images(dark, realtime, 0.0f).maxError > 0.1);
    CHECK(diff_images(realtime, mixed, 0.0f).maxError ==
          0.0);  // Mixed lights everything in real time, its bounce is baked
    // An uncovered receiver (x = 20): no probe reaches it, so nothing holds the Baked light and it is drawn as a realtime one.
    const Image farBaked = frame(true, LightMode::Baked, 20.0f);
    const Image farRealtime = frame(true, LightMode::Realtime, 20.0f);
    const Image farDark = frame(false, LightMode::Realtime, 20.0f);
    CHECK(diff_images(farBaked, farRealtime, 0.0f).maxError == 0.0);
    CHECK(diff_images(farDark, farBaked, 0.0f).maxError > 0.1);
}

TEST_CASE("light probes: a disabled probeAnchor is the same as none (the bounds centre is used)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    g.renderer.clear_asset_cache();
    std::filesystem::create_directories(g.projectDir / "scenes");
    World w;
    add_camera(w, {12, 0, 5}, {12, 0, 0});
    w.settings().ambientLight = Color{0, 0, 0, 1};
    Entity sphere = add_mesh(w, "sphere", {12, 0, 0}, Color::white(), {2, 2, 2});
    write_probe_manifest(w, "anchoroff", sh_gray_with_x(0.5f, {2.5f, 0, 0}));
    const Image none = g.render(w);  // 9 m outside the grid and no anchor: the sky's ambient (black)
    Entity anchor = make(w, "anchor", {0, 0, 0});
    w.get<MeshRenderer>(sphere)->probeAnchor = anchor;
    CHECK(red_minus_blue(g.render(w).pixel(160 + 18, 90)) > 0.2f);  // enabled: lit by the probes at the anchor
    w.set_active(anchor, false);
    CHECK(diff_images(g.render(w), none, 0.0f).maxError == 0.0);  // disabled: as without an anchor
}

TEST_CASE("light probes: instances within a probe group share draws, and the shadow pass draws as without probes") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    g.renderer.clear_asset_cache();
    std::filesystem::create_directories(g.projectDir / "scenes");
    constexpr int kCount = 48;
    // 48 cubes 5 cm apart along x (2.4 m): every probe holds another light, so the light changes along the row. The sample
    // points snap to a 0.25 m lattice, so the row has at most ten different keys.
    auto draws = [&](bool probes, bool shadows) {
        World w;
        add_camera(w, {0, 2, 6}, {0, 0, 0});
        w.settings().ambientLight = Color{0.1f, 0.1f, 0.1f, 1};
        for (int i = 0; i < kCount; ++i)
            add_mesh(w, "cube", {-1.2f + 0.05f * float(i), 0, 0}, Color::white(), {0.04f, 0.04f, 0.04f});
        Entity light = add_light(w, LightMode::Realtime);
        w.get<Light>(light)->castShadows = shadows;
        if (probes) {
            ProbeSet set;
            LightProbeGroup comp;
            comp.size = {6, 4, 6};
            comp.spacing = 1.0f;
            REQUIRE(add_probe_group(set, "group", comp, {0, 0, 0}).ok());
            set.sh.resize(set.size());
            for (std::size_t i = 0; i < set.size(); ++i)
                set.sh[i] = sh_gray_with_x(0.1f + 0.2f * (set.positions[i].x + 3.0f), {0, 0, 0});
            set.valid.assign(set.size(), 1);
            const std::vector<std::uint8_t> bytes = encode_probe_set(set);
            REQUIRE(fs::write_bytes("scenes/inst.lightmap.probes", bytes.data(), bytes.size()).ok());
            LightmapManifest m;
            m.uvVersion = kLightmapUvVersion;
            m.settingsHash = "0123456789abcdef";
            m.probes.file = "scenes/inst.lightmap.probes";
            m.probes.count = int(set.size());
            REQUIRE(fs::write_text("scenes/inst.lightmap.json", lightmap_manifest_to_json(m).dump(2)).ok());
            w.settings().lightmaps = "scenes/inst.lightmap.json";
        }
        g.render(w);
        return g.renderer.stats().drawCalls;
    };
    const int plainLit = draws(false, false), plainShadowed = draws(false, true);
    const int probeLit = draws(true, false), probeShadowed = draws(true, true);
    CHECK(plainShadowed > plainLit);                              // the shadow pass does draw
    CHECK(probeLit < kCount / 3);                                 // far fewer than one draw per cube
    CHECK(probeLit > plainLit);                                   // the light does differ along the row
    CHECK(probeShadowed - probeLit == plainShadowed - plainLit);  // shadow draws: as without probes
}

TEST_CASE(
    "light probes: render.light_probes tells a group edited after the bake (stale) and one added since (unbaked)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    g.renderer.clear_asset_cache();
    std::filesystem::create_directories(g.projectDir / "scenes");
    World w;
    Entity probes = make(w, "probes", {0, 0, 0});
    auto& comp = w.add<LightProbeGroup>(probes);
    comp.size = {6, 4, 6};
    comp.spacing = 2.0f;
    // The file holds what the scene asked for at the bake time.
    ProbeSet baked;
    REQUIRE(collect_probe_groups(w, baked).ok());
    REQUIRE(baked.groups.size() == 1);
    baked.sh.assign(baked.size(), sh_gray_with_x(0.5f, {0, 0, 0}));
    baked.valid.assign(baked.size(), 1);
    const std::vector<std::uint8_t> bytes = encode_probe_set(baked);
    REQUIRE(fs::write_bytes("scenes/stale.lightmap.probes", bytes.data(), bytes.size()).ok());
    LightmapManifest m;
    m.uvVersion = kLightmapUvVersion;
    m.settingsHash = "0123456789abcdef";
    m.probes.file = "scenes/stale.lightmap.probes";
    m.probes.count = int(baked.size());
    REQUIRE(fs::write_text("scenes/stale.lightmap.json", lightmap_manifest_to_json(m).dump(2)).ok());
    w.settings().lightmaps = "scenes/stale.lightmap.json";

    Json r = g.renderer.light_probes_report(w, kNullEntity);
    REQUIRE(r["groups"].size() == 1);
    CHECK(r["groups"][0]["stale"].get<bool>() == false);
    CHECK(r["unbaked"].size() == 0);
    // Resized after the bake: the baked group is stale and the scene's one is not in the file.
    w.get<LightProbeGroup>(probes)->size = {8, 4, 6};
    r = g.renderer.light_probes_report(w, kNullEntity);
    CHECK(r["groups"][0]["stale"].get<bool>() == true);
    REQUIRE(r["unbaked"].size() == 1);
    CHECK(r["unbaked"][0].get<std::string>() == w.id_of(probes));
    // Back as baked, plus a second group: the first is fine, the new one is unbaked.
    w.get<LightProbeGroup>(probes)->size = {6, 4, 6};
    Entity extra = make(w, "extra", {20, 0, 0});
    auto& c2 = w.add<LightProbeGroup>(extra);
    c2.size = {4, 4, 4};
    c2.spacing = 2.0f;
    r = g.renderer.light_probes_report(w, kNullEntity);
    CHECK(r["groups"][0]["stale"].get<bool>() == false);
    REQUIRE(r["unbaked"].size() == 1);
    CHECK(r["unbaked"][0].get<std::string>() == w.id_of(extra));
}
