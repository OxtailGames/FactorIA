// The lit meshes shaded with the RealtimeGI grid (docs/design/ARCHITECTURE_PROBES.md, "Realtime GI: the shading"):
//   - a white floor beside a red wall picks up the wall's red light once the grid is ready, and not a frame before;
//   - a thin divider between a lit probe and the surface it shades: the visibility test keeps the light on its side, in all six axis
//     directions (so a vertical or octahedral flip of the depth moments would fail), and a grid that cannot see the divider leaks;
//   - the order of the diffuse light: a lightmapped mesh and a mesh the baked light probes reach never read the grid;
//   - `bounce` scales the grid's light inside the captures only;
//   - a mesh the grid's box does not hold is drawn as in a world without a RealtimeGI.
// The values hold on llvmpipe and WARP as well as on a real GPU; no golden image is compared.
#include "test_util.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <string>
#include <vector>

#include "fa/core/image_float.h"
#include "fa/render/gi.h"
#include "fa/render/lightmap_geometry.h"
#include "fa/scene/light_probes.h"
#include "fa/scene/lightmap_bake.h"
#include "fa/scene/lightmap_manifest.h"
#include "fa/scene/lightmap_uv.h"
#include "render_internal.h"
#include "renderer_test_access.h"

using namespace fa;
using namespace fa::test;
using namespace fa::render;

namespace {

struct Own {
    Gfx& g;
    Renderer r;
    bool ok = false;
    std::string error;
    explicit Own(Gfx& gx) : g(gx) {
        RendererDesc d;
        d.designWidth = 320;
        d.designHeight = 180;
        d.sampleCount = 1;
        d.headless = true;
        d.adoptContext = true;
        ok = r.init(d, g.gpu.environment(), &error);
    }
    ~Own() { r.shutdown(); }
    Own(const Own&) = delete;
    Own& operator=(const Own&) = delete;
    void frame(World& w) {
        r.begin_frame();
        r.render_world(w, 0.0f);
        r.end_frame();
        g.gpu.end_frame();
    }
    Image picture(World& w) {
        frame(w);
        Image img;
        std::string err;
        const bool captured = r.capture(img, &err);
        INFO("capture error: " << err);
        REQUIRE(captured);
        return img;
    }
};

bool half_float_gi(Gfx& g) { return g.renderer.supports("floatTargets"); }

void add_camera(World& w, Vec3 pos, Vec3 lookAt) {
    Entity cam = make(w, "cam", pos);
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    const Vec3 f = normalize(lookAt - pos);
    w.get<Transform>(cam)->rotation = {degrees(std::asin(f.y)), degrees(std::atan2(-f.x, -f.z)), 0};
}

void dark_sky(World& w) {
    w.settings().ambientLight = Color{0, 0, 0, 1};
    w.settings().skyColor = Color{0, 0, 0, 1};
    w.settings().horizonColor = Color{0, 0, 0, 1};
}

// A light box that every probe sees as a bright surface (unlit, emissive).
Entity add_glow(World& w, const char* name, Vec3 pos, Vec3 scale, Color emissive) {
    Entity e = make(w, name, pos);
    w.get<Transform>(e)->scale = scale;
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = "cube";
    m.color = Color{0, 0, 0, 1};
    m.unlit = true;
    m.emissive = emissive;
    m.castShadows = false;
    return e;
}

// A lit white (or coloured) box: it takes its light from the sun and the grid.
Entity add_solid(World& w, const char* name, Vec3 pos, Vec3 scale, Color color) {
    Entity e = make(w, name, pos);
    w.get<Transform>(e)->scale = scale;
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = "cube";
    m.color = color;
    m.castShadows = false;
    return e;
}

Entity add_gi(World& w, Vec3 pos, Vec3 size, float spacing, int perFrame, float bounce = 1.0f) {
    Entity e = make(w, "gi", pos);
    auto& gi = w.add<RealtimeGI>(e);
    gi.size = size;
    gi.spacing = spacing;
    gi.probesPerFrame = perFrame;
    gi.resolution = 16;
    gi.maxDistance = 30.0f;
    gi.hysteresis = 0.0f;  // a capture replaces the probe: the tests do not wait for a blend to settle
    gi.bounce = bounce;
    return e;
}

const Json* grid_of(const Json& report, const std::string& id) {
    if (!report.contains("grids")) return nullptr;
    for (const Json& p : report["grids"])
        if (p.value("entity", std::string()) == id) return &p;
    return nullptr;
}

std::string grid_state(Own& o, World& w, Entity gi) {
    const Json report = o.r.gi_report();
    const Json* grid = grid_of(report, w.id_of(gi));
    return grid ? grid->value("state", std::string()) : std::string("none");
}

// Frames until the grid is ready (every probe captured once), then `extra` more so the meshes read it and the captures that follow have
// seen the grid's own light. False when the grid never got ready (a GPU that cannot blend into RGBA16F: "unsupported").
bool settle(Own& o, World& w, Entity gi, int extra = 4, int maxFrames = 60) {
    for (int i = 0; i < maxFrames; ++i) {
        o.frame(w);
        const std::string state = grid_state(o, w, gi);
        if (state == "unsupported") return false;
        if (state == "ready") {
            for (int k = 0; k < extra; ++k) o.frame(w);
            return true;
        }
    }
    MESSAGE("the grid never got ready: " << o.r.gi_report().dump(2));
    return false;
}

// The mean colour of a small patch in the middle of the picture.
Color middle(const Image& img, int radius = 3) {
    float r = 0, g = 0, b = 0;
    int n = 0;
    for (int dy = -radius; dy <= radius; ++dy)
        for (int dx = -radius; dx <= radius; ++dx) {
            const Color c = img.pixel(img.width / 2 + dx, img.height / 2 + dy);
            r += c.r;
            g += c.g;
            b += c.b;
            ++n;
        }
    return Color{r / float(n), g / float(n), b / float(n), 1};
}
float grey(const Color& c) { return (c.r + c.g + c.b) / 3.0f; }

Vec3 at(int a, float t, int b, float u) {
    float c[3] = {0, 0, 0};
    c[a] = t;
    c[b] = u;
    return {c[0], c[1], c[2]};
}

// ---------------------------------------------------------------------------------------------------- a red wall beside a white floor

// A grey floor, a red wall at x = 3 and a sun that lights both: the floor near the wall can only turn red through the grid.
Entity build_red_room(World& w, bool withGi, int perFrame) {
    add_camera(w, {0.0f, 3.0f, 3.0f}, {2.0f, 0.0f, 0.0f});
    dark_sky(w);
    Entity sun = make(w, "sun", {0, 5, 0});
    w.get<Transform>(sun)->rotation = {-45, -60, 0};  // travels toward +x and down
    auto& l = w.add<Light>(sun);
    l.type = LightType::Directional;
    l.intensity = 0.5f;
    add_solid(w, "floor", {0, -0.1f, 0}, {14, 0.2f, 14}, Color{0.6f, 0.6f, 0.6f, 1});
    add_solid(w, "wall", {3.05f, 3, 0}, {0.2f, 6, 14}, Color{0.9f, 0.05f, 0.05f, 1});
    if (!withGi) return Entity{};
    // Probes at x = -1.5 .. 2.5, y = 0.2 and 1.2 (the floor's top is 0: the grid answers for points inside its probes), z = -1 .. 1.
    return add_gi(w, {0.5f, 0.7f, 0}, {4, 1, 2}, 1.0f, perFrame);
}

}  // namespace

TEST_CASE(
    "realtime GI shading: a white floor beside a red wall turns red once the grid is ready, and not a frame before") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_gi(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    Image without;
    {
        Own o(g);
        REQUIRE(o.ok);
        World w;
        build_red_room(w, false, 0);
        without = o.picture(w);
    }
    const Color base = middle(without);
    INFO("without a grid: " << base.r << " " << base.g << " " << base.b);
    CHECK(base.r > 0.05f);  // the sun lights the floor
    CHECK(std::fabs(base.r - base.g) < 0.01f);

    Own o(g);
    REQUIRE(o.ok);
    World w;
    const Entity gi = build_red_room(w, true, 2);  // 30 probes, two a frame: fifteen frames before it is ready
    // While the grid is not ready nothing of it reaches the meshes: the frames are the frames of a world without the component.
    for (int i = 0; i < 5; ++i) {
        const Image img = o.picture(w);
        INFO("frame " << i);
        const std::string state = grid_state(o, w, gi);
        if (state == "unsupported") {
            MESSAGE("this GPU cannot blend into RGBA16F: not run");
            return;
        }
        REQUIRE(state != "ready");
        CHECK(img.rgba == without.rgba);
    }
    REQUIRE(settle(o, w, gi));
    const Image after = o.picture(w);
    const Color c = middle(after);
    INFO("with the grid ready: " << c.r << " " << c.g << " " << c.b);
    // The red wall's light is on the floor now: red grew, green and blue hardly.
    CHECK(c.r > base.r + 0.02f);
    CHECK(c.r - c.g > 0.02f);
    CHECK(c.g < base.g + 0.5f * (c.r - base.r));
    // render.gi_grid says the meshes read this grid.
    const Json report = o.r.gi_report();
    const Json* grid = grid_of(report, w.id_of(gi));
    REQUIRE(grid != nullptr);
    CHECK(grid->value("meshesRead", false));
}

// ---------------------------------------------------------------------------------------------------- a thin divider

namespace {

struct Divider {
    Entity gi;
    Vec3 darkPoint, brightPoint, darkCamera, brightCamera;
};

// Along the axis `a` (mirrored for s = -1): a glow panel at t = -3, a thin white divider at t = 0.5 and a grid of probes at t = -2 .. 2; the
// surface they light is a white floor (its normal is the next axis, b) with its top at 0, under two rows of probes at 0.2 and 1.2. The
// probes before the divider see the panel, the ones behind it see the divider's far face only. With `hide`, the divider is not in the
// captures: the grid cannot see it, so nothing stops the light of the probes before it (a leaky grid). The rows start 0.2 m over the floor:
// the grid answers for a point inside its probes and fades over half a spacing outside them.
Divider build_divider(World& w, int a, float s, bool hide, float bounce = 1.0f) {
    dark_sky(w);
    const int b = (a + 1) % 3;
    float ext[3] = {12, 12, 12};
    ext[a] = 0.2f;
    add_glow(w, "panel", at(a, -3.0f * s, b, 0), {ext[0], ext[1], ext[2]}, Color{1, 1, 1, 1});
    ext[a] = 0.1f;
    Entity slab = add_solid(w, "divider", at(a, 0.5f * s, b, 0), {ext[0], ext[1], ext[2]}, Color{1, 1, 1, 1});
    ext[a] = 12;
    ext[b] = 0.1f;
    add_solid(w, "floor", at(a, 0, b, -0.05f), {ext[0], ext[1], ext[2]}, Color{1, 1, 1, 1});
    float size[3] = {2, 2, 2};
    size[a] = 4;
    size[b] = 1;
    float pos[3] = {0, 0, 0};
    pos[b] = 0.7f;
    Divider d;
    d.gi = add_gi(w, {pos[0], pos[1], pos[2]}, {size[0], size[1], size[2]}, 1.0f, 32, bounce);
    if (hide) {
        w.get<EntityInfo>(slab)->tags.push_back("divider");
        w.get<RealtimeGI>(d.gi)->hideTags = Json::array({"divider"});
    }
    d.darkPoint = at(a, 0.7f * s, b, 0);
    d.brightPoint = at(a, -0.5f * s, b, 0);
    d.darkCamera = at(a, 2.2f * s, b, 3);
    d.brightCamera = at(a, -2.0f * s, b, 3);
    return d;
}

// The brightness of one point of the floor as the grid lights it: the camera looks at it from a few metres away.
float face_light(Own& o, World& w, const Vec3& camera, const Vec3& target) {
    w.get<Transform>(w.find("cam"))->position = camera;
    const Vec3 f = normalize(target - camera);
    w.get<Transform>(w.find("cam"))->rotation = {degrees(std::asin(f.y)), degrees(std::atan2(-f.x, -f.z)), 0};
    return grey(middle(o.picture(w)));
}

float dark_face_light(Own& o, World& w, const Divider& d) { return face_light(o, w, d.darkCamera, d.darkPoint); }

}  // namespace

TEST_CASE("realtime GI shading: a thin divider keeps the light of the probes before it from the surface behind it, "
          "along every axis") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_gi(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    const char* axisName[3] = {"x", "y", "z"};
    for (int a = 0; a < 3; ++a) {
        for (const float s : {1.0f, -1.0f}) {
            INFO("axis " << std::string(s > 0 ? "+" : "-") + axisName[a]);
            float clean = 0, leaky = 0, bright = 0;
            {
                Own o(g);
                REQUIRE(o.ok);
                World w;
                add_camera(w, {0, 0, 5}, {0, 0, 0});
                const Divider d = build_divider(w, a, s, false);
                if (!settle(o, w, d.gi)) {
                    MESSAGE("this GPU cannot blend into RGBA16F: not run");
                    return;
                }
                clean = dark_face_light(o, w, d);
                bright = face_light(o, w, d.brightCamera, d.brightPoint);
            }
            {
                Own o(g);
                REQUIRE(o.ok);
                World w;
                add_camera(w, {0, 0, 5}, {0, 0, 0});
                const Divider d = build_divider(w, a, s, true);
                REQUIRE(settle(o, w, d.gi));
                leaky = dark_face_light(o, w, d);
            }
            INFO("near face " << bright << ", far face " << clean << ", far face of a grid that cannot see the divider "
                              << leaky);
            // The near face is lit by the probes before the divider.
            CHECK(bright > 0.08f);
            // The grid that cannot see the divider leaks a large share of that light to the far face...
            CHECK(leaky > 0.25f * bright);
            // ... and the one that sees it keeps it away: what is left is a small fraction of the leak.
            CHECK(clean < 0.15f * leaky);
        }
    }
}

TEST_CASE(
    "realtime GI shading: bounce scales the grid's own light in the captures, the meshes drawn see it unchanged") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_gi(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    // The block of the probe at the grid's centre: the SH of the light that reaches it. Its colour is the divider's near face when the
    // captures carry the grid's light (the face is white and lit only by the grid), black when bounce is 0.
    auto centre_light = [&](float bounce, float* nearFace) {
        Own o(g);
        REQUIRE(o.ok);
        World w;
        add_camera(w, {0, 0, 5}, {0, 0, 0});
        const Divider d = build_divider(w, 1, 1.0f, false, bounce);
        if (!settle(o, w, d.gi, 6)) return -1.0f;
        *nearFace = face_light(o, w, d.brightCamera, d.brightPoint);
        const Json report = o.r.gi_report();
        const Json* grid = grid_of(report, w.id_of(d.gi));
        REQUIRE(grid != nullptr);
        const int probe =
            1 + 3 * (2 + 5 * 0);  // (1, 2, 0) of a 3 x 5 x 2 grid: the middle of the axis the panel lies along
        const GiTexel t = gi_block_origin(grid->value("firstBlock", 0) + probe);
        std::vector<float> texels;
        std::string error;
        REQUIRE(renderer_read_probe_atlas(o.r, t.x, t.y, kGiBlockW, kGiBlockH, texels, &error));
        INFO("read error: " << error);
        const std::size_t dc = (std::size_t(kGiShRow) * kGiBlockW + 0) * 4;
        return (texels[dc] + texels[dc + 1] + texels[dc + 2]) / 3.0f;
    };
    float faceOn = 0, faceOff = 0;
    const float withBounce = centre_light(1.0f, &faceOn);
    if (withBounce < 0.0f) {
        MESSAGE("this GPU cannot blend into RGBA16F: not run");
        return;
    }
    const float noBounce = centre_light(0.0f, &faceOff);
    INFO("probe DC with bounce 1: " << withBounce << ", with bounce 0: " << noBounce);
    INFO("near face of the divider with bounce 1: " << faceOn << ", with bounce 0: " << faceOff);
    CHECK(noBounce >= 0.0f);
    CHECK(withBounce > 1.1f * noBounce);
    CHECK(withBounce > noBounce + 0.02f);
    // The meshes the camera draws are not captures: bounce does not dim them.
    CHECK(faceOn > 0.05f);
    CHECK(faceOff > 0.05f);
}

TEST_CASE("realtime GI shading: the capture of a ReflectionProbe sees the grid at full strength, whatever the grid's "
          "bounce") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_gi(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    // The floor is lit by the grid only. A ReflectionProbe just over it captures that floor (the colour of the light below it): `bounce`
    // is for the grid's own probes (Frame::giCapture), so a bounce of 0 must not darken the floor in this capture (the grid's probes hold
    // one bounce less of light, nothing more).
    auto floor_light = [&](float bounce) {
        Own o(g);
        REQUIRE(o.ok);
        World w;
        add_camera(w, {0, 0, 5}, {0, 0, 0});
        const Divider d = build_divider(w, 1, 1.0f, false, bounce);
        if (!settle(o, w, d.gi, 6)) return -1.0f;
        Entity probe = make(w, "reflection", at(1, -0.5f, 2, 0.6f));
        auto& rp = w.add<ReflectionProbe>(probe);
        rp.mode = ProbeMode::Baked;
        rp.resolution = 32;
        rp.boxSize = {4, 4, 4};
        // The glow panel is left out of the capture: what is seen below the probe is the floor, lit by the grid alone.
        w.get<EntityInfo>(w.find("panel"))->tags.push_back("panel");
        rp.hideTags = Json::array({"panel"});
        Renderer::ProbePage page;
        std::string error;
        REQUIRE(o.r.probe_capture(w, probe, page, &error));
        INFO("capture error: " << error);
        ShL2 sh;
        for (int k = 0; k < 9; ++k) sh.c[k] = Vec3{page.sh[k][0], page.sh[k][1], page.sh[k][2]};
        const Vec3 down = sh_irradiance(sh, {0, 0, -1});
        return (down.x + down.y + down.z) / 3.0f;
    };
    const float full = floor_light(1.0f);
    if (full < 0.0f) {
        MESSAGE("this GPU cannot blend into RGBA16F: not run");
        return;
    }
    const float zero = floor_light(0.0f);
    INFO("light of the floor in the capture with bounce 1: " << full << ", with bounce 0: " << zero);
    CHECK(full > 0.02f);
    // The grid itself is brighter with a bounce (its probes hold one more bounce of light), so the two are not equal; a capture that
    // multiplied the grid's light by bounce 0 would see an unlit floor.
    CHECK(zero > 0.5f * full);
}

// ---------------------------------------------------------------------------------------------------- the order of the diffuse light

namespace {

ShL2 sh_black() {
    ShL2 s;
    for (Vec3& c : s.c) c = {0, 0, 0};
    return s;
}

// Writes scenes/<name>.lightmap.json with a probe file (one grid group of `size` at the origin, every probe black) and, when `pageFile` is
// given, the lightmapped entities. Sets SceneSettings.lightmaps.
void write_manifest(World& w, const char* name, const std::vector<Entity>& lightmapped, const char* pageFile) {
    std::filesystem::create_directories(fs::project_root() / "scenes");
    ProbeSet set;
    LightProbeGroup comp;
    comp.size = {6, 4, 6};
    comp.spacing = 2.0f;
    REQUIRE(add_probe_group(set, "group", comp, {0, 0, 0}).ok());
    set.sh.assign(set.size(), sh_black());
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

void write_red_page(const char* file) {
    auto img = ImageF::create(4, 4, 3);
    REQUIRE(img.ok());
    for (int y = 0; y < 4; ++y)
        for (int x = 0; x < 4; ++x) {
            float* p = img->at(x, y);
            p[0] = 0.6f;
            p[1] = 0.0f;
            p[2] = 0.0f;
        }
    REQUIRE(save_hdr(*img, file).ok());
}

// A white cube under a green ceiling that only the grid brings to it, a camera that sees the cube's top and not the ceiling. The grid's
// probes at y = 1 and 2 are above the cube; the row at y = 0 is inside it.
Entity build_green_ceiling(World& w, bool withGi, Entity* cube) {
    add_camera(w, {0, 2.0f, 3.0f}, {0, 0.75f, 0});
    dark_sky(w);
    add_glow(w, "ceiling", {0, 3.0f, 0}, {8, 0.2f, 8}, Color{0, 1, 0, 1});
    *cube = add_solid(w, "cube", {0, 0, 0}, {1.5f, 1.5f, 1.5f}, Color{1, 1, 1, 1});
    if (!withGi) return Entity{};
    return add_gi(w, {0, 1, 0}, {4, 2, 4}, 1.0f, 32);
}

}  // namespace

TEST_CASE("realtime GI shading: a lightmapped mesh and a mesh the baked light probes reach never read the grid") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_gi(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    std::filesystem::create_directories(g.projectDir / "scenes");
    write_red_page("scenes/gi_page.lightmap.0.hdr");

    // The reference: the cube lit by the grid alone is green.
    {
        Own o(g);
        REQUIRE(o.ok);
        World w;
        Entity cube;
        const Entity gi = build_green_ceiling(w, true, &cube);
        if (!settle(o, w, gi)) {
            MESSAGE("this GPU cannot blend into RGBA16F: not run");
            return;
        }
        const Color c = middle(o.picture(w));
        INFO("a cube lit by the grid: " << c.r << " " << c.g << " " << c.b);
        CHECK(c.g > 0.05f);
        CHECK(c.g > 4.0f * c.r);
    }
    // A lightmapped cube reads its (red) page: the green of the grid does not reach it, and the picture is the one of a world without a grid.
    {
        Color without, with;
        for (const bool withGi : {false, true}) {
            Own o(g);
            REQUIRE(o.ok);
            World w;
            Entity cube;
            const Entity gi = build_green_ceiling(w, withGi, &cube);
            write_manifest(w, "gi_page", {cube}, "scenes/gi_page.lightmap.0.hdr");
            if (withGi) {
                REQUIRE(settle(o, w, gi));
                with = middle(o.picture(w));
            } else {
                without = middle(o.picture(w));
            }
        }
        INFO("lightmapped, no grid: " << without.r << " " << without.g << " " << without.b
                                      << ", with a ready grid: " << with.r << " " << with.g << " " << with.b);
        CHECK(without.r > 0.1f);
        CHECK(without.g < 0.02f);
        CHECK(std::fabs(with.r - without.r) < 0.01f);
        CHECK(std::fabs(with.g - without.g) < 0.01f);
        CHECK(std::fabs(with.b - without.b) < 0.01f);
    }
    // A cube the baked light probes reach (they hold black light) is black: the grid's green is not added.
    {
        Own o(g);
        REQUIRE(o.ok);
        World w;
        Entity cube;
        const Entity gi = build_green_ceiling(w, true, &cube);
        write_manifest(w, "gi_probes", {}, nullptr);
        REQUIRE(settle(o, w, gi));
        const Color c = middle(o.picture(w));
        INFO("covered by baked probes: " << c.r << " " << c.g << " " << c.b);
        CHECK(c.g < 0.01f);
        CHECK(c.r < 0.01f);
    }
}

TEST_CASE("realtime GI shading: a mesh outside the grid's box, or a world whose grid is gone, is drawn as without the "
          "component") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!half_float_gi(g)) {
        MESSAGE("this GPU has no half-float render targets: not run");
        return;
    }
    // The cube stands 30 m from a small grid: the grid does not hold it, whatever the grid holds.
    auto build = [](World& w, bool withGi) {
        add_camera(w, {30.0f, 2.0f, 3.0f}, {30.0f, 0.75f, 0});
        dark_sky(w);
        w.settings().ambientLight = Color{0.1f, 0.2f, 0.3f, 1};
        add_glow(w, "ceiling", {0, 3.0f, 0}, {8, 0.2f, 8}, Color{0, 1, 0, 1});
        add_solid(w, "cube", {30, 0, 0}, {1.5f, 1.5f, 1.5f}, Color{1, 1, 1, 1});
        Entity sun = make(w, "sun", {0, 5, 0});
        w.get<Transform>(sun)->rotation = {-50, 30, 0};
        w.add<Light>(sun).intensity = 0.7f;
        return withGi ? add_gi(w, {0, 1, 0}, {4, 2, 4}, 1.0f, 32) : Entity{};
    };
    Image without;
    {
        Own o(g);
        REQUIRE(o.ok);
        World w;
        build(w, false);
        without = o.picture(w);
    }
    Own o(g);
    REQUIRE(o.ok);
    World w;
    const Entity gi = build(w, true);
    if (!settle(o, w, gi)) {
        MESSAGE("this GPU cannot blend into RGBA16F: not run");
        return;
    }
    const Image during = o.picture(w);
    CHECK(during.rgba == without.rgba);
    // The component goes: the grid goes with it and the picture is the same.
    w.destroy_immediate(gi);
    CHECK(o.picture(w).rgba == without.rgba);
}
