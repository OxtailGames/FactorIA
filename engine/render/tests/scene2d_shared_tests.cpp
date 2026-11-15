// Scene2D (scene2d.h): the camera-independent part of the 2D gather is done once per frame and every camera, render target and
// CameraView takes its quad lists from it. The oracle is the old path: a fresh Scene2D for every camera (nothing to copy from, so
// each camera builds all it draws, as gather_2d / gather_particles always did). The shared run must give the same lists, item
// by item and vertex by vertex, and must build each entity once.
#include "test_util.h"

#include <cstring>
#include <string>
#include <vector>

#include "fa/core/jobs.h"
#include "fa/scene/components.h"
#include "fa/scene/tilemap.h"
#include "render_internal.h"
#include "scene2d.h"

using namespace fa;
using namespace fa::test;
using namespace fa::render;

namespace {

// What a gather needs besides the world: the caches and the once-per-scene warning flags the renderer owns.
struct Rig {
    Assets assets;
    Fonts fonts;
    GradientRamps ramps;
    ShadowCache shadowCache;
    bool warnedLights = false, warnedShadows = false, warnedMesh = false, warnedStops = false;
    explicit Rig(Gfx& g) : assets(*renderer_gpu(g.renderer)), fonts(*renderer_gpu(g.renderer), assets) {}
};

struct Cam {
    CameraInfo info;
    bool world = true, screen = true;
};

Cam ortho(Entity entity, Vec2 centre, float halfW = 160, float halfH = 90, bool screen = true,
          Rect viewport = Rect{0, 0, 1, 1}) {
    Cam c;
    CameraInfo& ci = c.info;
    ci.entity = entity;
    ci.viewport = viewport;
    ci.position = Vec3{centre.x, centre.y, 0};
    ci.halfW = halfW;
    ci.halfH = halfH;
    ci.pixelsPerUnit = 1.0f;
    ci.view = Mat4::identity();
    ci.view.at(3, 0) = -centre.x;
    ci.view.at(3, 1) = -centre.y;
    ci.proj = Mat4::ortho(-halfW, halfW, -halfH, halfH, -1000.0f, 1000.0f, true);
    ci.viewProj = ci.proj * ci.view;
    ci.invViewProj = ci.viewProj.inverse();
    ci.queryViewProj = ci.viewProj;
    ci.queryInvViewProj = ci.invViewProj;
    ci.visible = Rect{centre.x - halfW, centre.y - halfH, halfW * 2, halfH * 2};
    c.screen = screen;
    return c;
}

Cam perspective(Entity entity, Vec3 at) {
    Cam c = ortho(entity, at.xy(), 160, 90);
    c.info.perspective = true;
    c.info.position = at;
    c.info.proj = Mat4::perspective(60.0f, 320.0f / 180.0f, 1.0f, 5000.0f, true);
    c.info.view = Mat4::identity();
    c.info.view.at(3, 0) = -at.x;
    c.info.view.at(3, 1) = -at.y;
    c.info.view.at(3, 2) = -at.z;
    c.info.viewProj = c.info.proj * c.info.view;
    c.info.invViewProj = c.info.viewProj.inverse();
    c.info.queryViewProj = c.info.viewProj;
    c.info.queryInvViewProj = c.info.invViewProj;
    c.screen = false;
    return c;
}

struct Run {
    std::vector<Frame> frames;
    RenderStats stats;
    Scene2D::Work work;
};

// Gathers every camera of `cams` the way Renderer::Impl::render does: `shared` = one Scene2D and apply_sprite_frames once; else
// the old path, a fresh Scene2D (and apply_sprite_frames) for each camera. The Frames of a round are reserved, never moved.
void gather_all(World& w, Rig& rig, const std::vector<Cam>& cams, bool shared, Run& out, bool single = false) {
    out.frames.reserve(cams.size());
    rig.ramps.begin_frame();
    Scene2D one;
    one.set_single_destination(single);
    for (std::size_t i = 0; i < cams.size(); ++i) {
        Frame& f = out.frames.emplace_back();
        f.cam = cams[i].info;
        f.wantWorld = cams[i].world;
        f.wantScreen = cams[i].screen;
        f.targetW = 320;
        f.targetH = 180;
        f.stats = &out.stats;
        f.assets = &rig.assets;
        f.fonts = &rig.fonts;
        f.warnedLights2d = &rig.warnedLights;
        f.warnedShadows2d = &rig.warnedShadows;
        f.warnedSpriteMesh = &rig.warnedMesh;
        f.warnedGradientStops = &rig.warnedStops;
        f.shadowCache = &rig.shadowCache;
        f.ramps = &rig.ramps;
        f.mask = CameraMask::of(w, f.cam.entity);
        if (!shared || i == 0) apply_sprite_frames(w, f);
        Scene2D fresh;
        Scene2D& scene = shared ? one : fresh;
        scene.gather(w, f);
        scene.gather_particles(w, f);
        if (!shared) {
            const Scene2D::Work& k = fresh.work();
            out.work.spritesBuilt += k.spritesBuilt;
            out.work.shapesBuilt += k.shapesBuilt;
            out.work.emittersBuilt += k.emittersBuilt;
        }
    }
    if (shared) out.work = one.work();
}

// The same items in the same order with the same vertices. `seq` only has to grow: a copy leaves other gaps than a build does (an
// item without quads consumes one), and what flatten reads is the order.
void expect_same_list(const QuadList& a, const QuadList& b, const std::string& what) {
    INFO(what);
    REQUIRE(a.items.size() == b.items.size());
    REQUIRE(a.raw.size() == b.raw.size());
    if (!a.raw.empty()) CHECK(std::memcmp(a.raw.data(), b.raw.data(), a.raw.size() * sizeof(Vertex2D)) == 0);
    for (std::size_t i = 0; i < a.items.size(); ++i) {
        INFO("item " << i);
        const QuadItem &x = a.items[i], &y = b.items[i];
        if (i > 0) {
            CHECK(a.items[i - 1].seq < x.seq);
            CHECK(b.items[i - 1].seq < y.seq);
        }
        CHECK(x.layer == y.layer);
        CHECK(x.secondary == y.secondary);
        CHECK(x.firstVert == y.firstVert);
        CHECK(x.quadCount == y.quadCount);
        CHECK(x.tex == y.tex);
        CHECK(x.smp == y.smp);
        CHECK(x.blend == y.blend);
        CHECK(x.clip.x == y.clip.x);
        CHECK(x.clip.y == y.clip.y);
        CHECK(x.clip.w == y.clip.w);
        CHECK(x.clip.h == y.clip.h);
        CHECK(x.lit == y.lit);
        CHECK(x.normal == y.normal);
        CHECK(x.plain == y.plain);
        CHECK(x.opaque == y.opaque);
        CHECK(x.flash == y.flash);
        if (i > 0) {
            CHECK(a.items[i - 1].seq < x.seq);
            CHECK(b.items[i - 1].seq < y.seq);
        }
    }
}

// Runs both paths on `w` and compares every frame. Returns the shared run for the checks of the work counts.
void compare(World& w, Rig& rig, const std::vector<Cam>& cams, Run& shared) {
    // The first gather may bring glyphs into the atlas; compare two settled rounds.
    {
        Run warm;
        gather_all(w, rig, cams, false, warm);
    }
    const unsigned epoch = rig.fonts.atlas_epoch();
    Run oracle;
    gather_all(w, rig, cams, false, oracle);
    gather_all(w, rig, cams, true, shared);
    REQUIRE(rig.fonts.atlas_epoch() == epoch);
    REQUIRE(oracle.frames.size() == shared.frames.size());
    for (std::size_t i = 0; i < cams.size(); ++i) {
        const std::string tag = "camera " + std::to_string(i);
        expect_same_list(oracle.frames[i].world, shared.frames[i].world, tag + " world");
        expect_same_list(oracle.frames[i].screen, shared.frames[i].screen, tag + " screen");
        CHECK(oracle.frames[i].lights2d.size() == shared.frames[i].lights2d.size());
        CHECK(oracle.frames[i].shadowRows == shared.frames[i].shadowRows);
        CHECK(oracle.frames[i].shadowKey == shared.frames[i].shadowKey);
    }
    CHECK(oracle.stats.sprites == shared.stats.sprites);
    CHECK(oracle.stats.shapes == shared.stats.shapes);
    CHECK(oracle.stats.textGlyphs == shared.stats.textGlyphs);
    CHECK(oracle.stats.particles == shared.stats.particles);
    CHECK(oracle.stats.lights2d == shared.stats.lights2d);
    CHECK(oracle.stats.lights2dDropped == shared.stats.lights2dDropped);
    CHECK(oracle.stats.lights2dShadowed == shared.stats.lights2dShadowed);
}

std::string write_checker(const std::string& name, Color a, Color b) {
    Image img;
    img.width = 32;
    img.height = 32;
    img.rgba.resize(std::size_t(32) * 32 * 4);
    for (int y = 0; y < 32; ++y)
        for (int x = 0; x < 32; ++x) img.set_pixel(x, y, (((x / 4) + (y / 4)) % 2 == 0) ? a : b);
    const std::string path = "assets/" + name;
    REQUIRE(save_png(img, path).ok());
    return path;
}

Entity camera_entity(World& w, const char* name, Vec3 pos, const char* showJson = "[]", const char* hideJson = "[]") {
    Entity e = make(w, name, pos);
    auto& c = w.add<Camera>(e);
    c.showTags = Json::parse(showJson);
    c.hideTags = Json::parse(hideJson);
    return e;
}

Entity sprite(World& w, const std::string& tex, Vec3 pos, Vec2 size, int layer = 0, const char* tag = nullptr) {
    Entity e = make(w, "sprite", pos);
    auto& s = w.add<Sprite>(e);
    s.texture = tex;
    s.size = size;
    s.layer = layer;
    if (tag) w.info(e).tags = {tag};
    return e;
}

Entity shape(World& w, Vec3 pos, Vec2 size, Color c, int layer = 0, const char* tag = nullptr) {
    Entity e = make(w, "shape", pos);
    auto& s = w.add<Shape2D>(e);
    s.size = size;
    s.color = c;
    s.layer = layer;
    if (tag) w.info(e).tags = {tag};
    return e;
}

// Sprites (plain, lit, ySorted by position), shapes (one with a gradient ramp), a tilemap, text, an emitter of each space, a 2D
// light. Returns the number of Sprites / Shape2D / ParticleEmitters that every camera draws (the ones with no tag).
struct SceneCounts {
    int sprites = 0, shapes = 0, emitters = 0;
};
SceneCounts build_scene(World& w) {
    SceneCounts n;
    const std::string checker = write_checker("s2d_checker.png", Color::hex(0xffffff), Color::hex(0x404040));
    const std::string tiles = write_checker("s2d_tiles.png", Color::hex(0x3b7d3b), Color::hex(0x8b5a2b));
    for (int i = 0; i < 12; ++i) {
        sprite(w, checker, Vec3{float(i * 23 - 120), float((i * 37) % 120 - 60), 0}, {20, 20}, i % 3);
        ++n.sprites;
    }
    {
        Entity e = sprite(w, "", {-60, 20, 0}, {30, 30}, 1);
        w.get<Sprite>(e)->lit = true;
        w.get<Sprite>(e)->color = Color{1, 0.5f, 0.5f, 0.9f};
        ++n.sprites;
    }
    {
        Entity e =
            sprite(w, checker, {40, -20, 0}, {30, 10}, 2);  // a screen-space Sprite: the frame that wants the screen
        w.get<Sprite>(e)->space = RenderSpace::Screen;
    }
    for (int i = 0; i < 6; ++i) {
        shape(w, Vec3{float(i * 40 - 100), float(i * 11 - 30), 0}, {30, 20}, Color::hex(0xe02020), i % 2);
        ++n.shapes;
    }
    {
        Entity e = shape(w, {0, 0, 0}, {60, 40}, Color{1, 0, 0, 1}, 1);
        Shape2D& s = *w.get<Shape2D>(e);
        s.gradient = ShapeGradient::Linear;
        s.color2 = Color{0, 0, 1, 1};
        s.gradientStops = Json::parse(R"([[0, "#ff0000"], [0.5, "#00ff00"], [1, "#0000ff"]])");
        ++n.shapes;
    }
    {
        Entity map = make(w, "map", {-80, -40, 0});
        auto& tm = w.add<Tilemap>(map);
        tm.tileset = tiles;
        tm.tileSize = {8, 8};
        tm.columns = 4;
        set_tilemap_grid(tm, 20, 10, std::vector<int>(200, 1));
    }
    {
        Entity t = make(w, "label", {-100, 70, 0});
        auto& tx = w.add<Text>(t);
        tx.text = "Scene2D shared";
        tx.fontSize = 14;
    }
    {
        Entity light = make(w, "lamp", {20, 10, 0});
        auto& l = w.add<Light2D>(light);
        l.radius = 200;
    }
    {
        Entity em = make(w, "sparks", {30, 30, 0});
        auto& p = w.add<ParticleEmitter>(em);
        p.rate = 0;
        p.burst = 20;
        p.seed = 3;
        p.lifetime = 2.0f;
        p.speed = 30;
        p.spread = 360;
        p.startSize = 6;
        ++n.emitters;
    }
    {
        Entity em = make(w, "hud-sparks", {20, 20, 0});
        auto& p = w.add<ParticleEmitter>(em);
        p.space = RenderSpace::Screen;
        p.rate = 0;
        p.burst = 8;
        p.seed = 5;
        p.lifetime = 2.0f;
        p.speed = 20;
        p.spread = 360;
        p.startSize = 5;
    }
    Gfx::simulate(w, 0.5f);
    return n;
}

}  // namespace

TEST_CASE("Scene2D: one camera gives the lists of the old path and builds each entity once") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity cam = camera_entity(w, "cam", {0, 0, 0});
    const SceneCounts n = build_scene(w);
    Rig rig(g);
    Run run;
    compare(w, rig, {ortho(cam, {0, 0})}, run);
    CHECK(run.frames[0].world.items.size() > 20);
    CHECK_FALSE(run.frames[0].screen.items.empty());
    CHECK(run.work.spritesBuilt == n.sprites + 1);  // the screen-space Sprite too
    CHECK(run.work.spritesCopied == 0);
    CHECK(run.work.shapesCopied == 0);
    CHECK(run.work.emittersCopied == 0);
    CHECK(run.work.emittersBuilt == n.emitters + 1);
}

TEST_CASE("Scene2D: a single destination keeps no tables and gives the lists of the old path") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity cam = camera_entity(w, "cam", {0, 0, 0});
    build_scene(w);
    Rig rig(g);
    const std::vector<Cam> cams{ortho(cam, {0, 0})};
    {
        Run warm;
        gather_all(w, rig, cams, false, warm);
    }
    Run oracle, single;
    gather_all(w, rig, cams, false, oracle);
    gather_all(w, rig, cams, true, single, true);
    expect_same_list(oracle.frames[0].world, single.frames[0].world, "world");
    expect_same_list(oracle.frames[0].screen, single.frames[0].screen, "screen");
    CHECK(oracle.stats.sprites == single.stats.sprites);
    CHECK(oracle.stats.shapes == single.stats.shapes);
    CHECK(single.work.spritesCopied == 0);
}

TEST_CASE("Scene2D: split screen, render target and view cameras share what they draw, and each builds only what is "
          "its own") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity left = camera_entity(w, "left", {0, 0, 0});
    Entity right = camera_entity(w, "right", {120, 20, 0});
    Entity view = camera_entity(w, "view", {-30, 10, 0});
    const SceneCounts n = build_scene(w);
    Rig rig(g);
    std::vector<Cam> cams;
    cams.push_back(ortho(left, {0, 0}, 80, 90, false, Rect{0, 0, 0.5f, 1}));
    cams.push_back(ortho(right, {120, 20}, 80, 90, true, Rect{0.5f, 0, 0.5f, 1}));
    cams.push_back(ortho(view, {-30, 10}, 40, 22, false));  // a render target / CameraView: world only, another zoom
    Run run;
    compare(w, rig, cams, run);
    // The world is gathered once: the 2nd and 3rd camera copy every Sprite, Shape2D and emitter the first one built (the
    // screen-space ones are built by the frame that wants the screen, the 2nd).
    CHECK(run.work.spritesBuilt == n.sprites + 1);
    CHECK(run.work.spritesCopied == 2 * n.sprites);
    CHECK(run.work.shapesBuilt == n.shapes);
    CHECK(run.work.shapesCopied == 2 * n.shapes);
    CHECK(run.work.emittersBuilt == n.emitters + 1);
    CHECK(run.work.emittersCopied == 2 * n.emitters);
}

TEST_CASE(
    "Scene2D: showTags and hideTags are per camera, an entity another camera hid is built when the next one draws it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity noHud = camera_entity(w, "noHud", {0, 0, 0}, "[]", R"(["hud"])");
    Entity onlyHud = camera_entity(w, "onlyHud", {0, 0, 0}, R"(["hud"])");
    Entity all = camera_entity(w, "all", {0, 0, 0});
    build_scene(w);
    const std::string checker = "assets/s2d_checker.png";
    for (int i = 0; i < 5; ++i) {
        sprite(w, checker, Vec3{float(i * 30 - 60), 40, 0}, {16, 16}, 1, "hud");
        shape(w, Vec3{float(i * 30 - 60), -40, 0}, {16, 16}, Color::hex(0x2040e0), 1, "hud");
        sprite(w, checker, Vec3{float(i * 30 - 50), 0, 0}, {16, 16},
               1);  // between the hud ones, in the order of the Sprites
    }
    Rig rig(g);
    std::vector<Cam> cams;
    cams.push_back(ortho(noHud, {0, 0}));
    cams.push_back(ortho(onlyHud, {0, 0}));
    cams.push_back(ortho(all, {0, 0}));
    Run run;
    compare(w, rig, cams, run);
    // The second camera built the "hud" sprites (the first hid them); the third copied them with the rest.
    CHECK(run.work.spritesBuilt > 0);
    CHECK(run.work.spritesCopied > 0);
    CHECK(run.work.shapesCopied > 0);
}

TEST_CASE("Scene2D: a perspective camera sorts by distance, its copies carry its own key") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity cam = camera_entity(w, "cam", {0, 0, 0});
    Entity cam3d = camera_entity(w, "cam3d", {0, 0, 300});
    for (int i = 0; i < 8; ++i) {
        sprite(w, "", Vec3{float(i * 20 - 70), float(i * 9 - 30), float(i * 5)}, {18, 18}, 0);
        shape(w, Vec3{float(i * 20 - 70), float(i * 7 - 20), float(-i * 5)}, {18, 18}, Color::hex(0x20c040), 0);
    }
    Rig rig(g);
    std::vector<Cam> cams{ortho(cam, {0, 0}), perspective(cam3d, {0, 0, 300})};
    Run run;
    compare(w, rig, cams, run);
    bool differs = false;
    for (const QuadItem& it : run.frames[1].world.items)
        if (it.secondary != 0.0f) differs = true;
    CHECK(differs);  // the distances, not the y or 0 of the orthographic camera
    CHECK(run.work.spritesCopied == 8);
    CHECK(run.work.shapesCopied == 8);
}

TEST_CASE("Scene2D: what depends on the camera (Parallax, render target textures, billboards, screen space) is built "
          "for each") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity a = camera_entity(w, "a", {0, 0, 0});
    Entity b = camera_entity(w, "b", {200, 50, 0});
    const std::string checker = write_checker("s2d_checker.png", Color::hex(0xffffff), Color::hex(0x404040));
    for (int i = 0; i < 6; ++i) sprite(w, checker, Vec3{float(i * 25 - 60), float(i * 7 - 20), 0}, {16, 16}, 0);
    int parallax = 0;
    for (int i = 0; i < 3; ++i) {
        Entity e = sprite(w, checker, Vec3{float(i * 40 - 40), 20, 0}, {30, 30}, -1);
        w.add<Parallax>(e).factor = {0.5f, 0.5f};
        ++parallax;
        sprite(w, "target:elsewhere", Vec3{float(i * 40 - 40), -30, 0}, {20, 20}, 1);  // a texture of a render target
        ++parallax;
    }
    for (int i = 0; i < 6; ++i) sprite(w, checker, Vec3{float(i * 25 - 60), float(i * 5), 0}, {16, 16}, 0);
    {
        Entity em = make(w, "billboards", {0, 0, 0});
        auto& p = w.add<ParticleEmitter>(em);
        p.is3D = true;
        p.rate = 0;
        p.burst = 10;
        p.seed = 1;
        p.lifetime = 2.0f;
        p.speed = 20;
        p.startSize = 5;
    }
    Gfx::simulate(w, 0.5f);
    Rig rig(g);
    std::vector<Cam> cams{ortho(a, {0, 0}), ortho(b, {200, 50}, 80, 45, false)};
    Run run;
    compare(w, rig, cams, run);
    // 12 plain Sprites are built once and copied once; the Parallax and target ones are built by both cameras, interleaved with
    // the copies in the order of the Sprites.
    CHECK(run.work.spritesBuilt == 12 + 2 * parallax);
    CHECK(run.work.spritesCopied == 12);
    CHECK(run.work.emittersCopied == 0);
    // Each camera has its own shift of the layer: the 2nd frame must not hold the first's vertices.
    bool moved = false;
    const QuadList& l0 = run.frames[0].world;
    const QuadList& l1 = run.frames[1].world;
    for (std::size_t i = 0; i < std::min(l0.raw.size(), l1.raw.size()); ++i)
        if (l0.raw[i].x != l1.raw[i].x) moved = true;
    CHECK(moved);
}

TEST_CASE("Scene2D: more Sprites and particles than the jobs split join in order, with copies between them, on any "
          "thread count") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity a = camera_entity(w, "a", {0, 0, 0});
    Entity b = camera_entity(w, "b", {10, 0, 0});
    const std::string checker = write_checker("s2d_checker.png", Color::hex(0xffffff), Color::hex(0x404040));
    for (int i = 0; i < 1500; ++i) {
        const bool own = i % 7 == 0;
        Entity e = sprite(w, checker, Vec3{float(i % 50) * 6 - 150, float(i / 50) * 5 - 80, 0}, {5, 5}, i % 4);
        if (own) w.add<Parallax>(e).factor = {0.9f, 0.9f};  // built by both cameras, among the copies
    }
    for (int i = 0; i < 3; ++i) {
        Entity em = make(w, "swarm", Vec3{float(i * 40 - 40), 0, 0});
        auto& p = w.add<ParticleEmitter>(em);
        p.rate = 0;
        p.burst = 2000;  // 6000 live particles: over the 2048 from which they are drawn as jobs
        p.seed = unsigned(i + 1);
        p.lifetime = 3.0f;
        p.speed = 40;
        p.spread = 360;
        p.startSize = 2;
    }
    Gfx::simulate(w, 0.25f);
    struct Mode {
        const char* name;
        bool start;
        jobs::Settings settings;
    };
    std::vector<Mode> modes{{"stopped", false, {}}, {"inline", true, jobs::Settings::inline_jobs()}};
    if (jobs::threads_supported()) {
        modes.push_back({"2 workers", true, jobs::Settings::threads(2)});
        modes.push_back({"8 workers", true, jobs::Settings::threads(8)});
    }
    for (const Mode& m : modes) {
        INFO("jobs: " << m.name);
        // Stops the workers also when a REQUIRE below throws.
        struct JobsGuard {
            bool started = false;
            JobsGuard() = default;
            JobsGuard(const JobsGuard&) = delete;
            JobsGuard& operator=(const JobsGuard&) = delete;
            ~JobsGuard() {
                if (started) jobs::stop();
            }
        } jobsGuard;
        if (m.start) {
            auto r = jobs::start(m.settings);
            REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : r.error().to_string()));
            jobsGuard.started = true;
            // start() on a running pool only counts a reference: a pool left by an earlier case would hide this mode.
            REQUIRE(jobs::worker_count() == jobs::resolve_workers(m.settings));
        }
        Rig rig(g);
        Run run;
        compare(w, rig, {ortho(a, {0, 0}), ortho(b, {10, 0})}, run);
        CHECK(run.work.spritesCopied == 1500 - 215);  // 215 = the sprites with i % 7 == 0
        CHECK(run.work.spritesBuilt == 1500 + 215);
        CHECK(run.work.emittersBuilt == 3);
        CHECK(run.work.emittersCopied == 3);
    }
}

TEST_CASE("QuadList::append_items copies a range of items with its vertices and continues the sequence") {
    QuadList src;
    const Vertex2D v{1, 2, 0, 0, 0, 0xffffffffu, 0, 0};
    for (int i = 0; i < 4; ++i) {
        src.begin_item(i, float(i), nullptr, SamplerKind::Nearest);
        Vertex2D a = v;
        a.x = float(10 * i);
        src.quad(a, a, a, a);
        src.quad(a, a, a, a);
        src.end_item();
    }
    QuadList dst;
    dst.begin_item(9, 0, nullptr, SamplerKind::Nearest);
    dst.quad(v, v, v, v);
    dst.end_item();
    const float key = 42;
    const std::size_t first = dst.append_items(src, 1, 2, &key);
    CHECK(first == 1);
    REQUIRE(dst.items.size() == 3);
    CHECK(dst.raw.size() == 4 + 2 * 8);
    CHECK(dst.items[1].layer == 1);
    CHECK(dst.items[2].layer == 2);
    CHECK(dst.items[1].secondary == 42.0f);
    CHECK(dst.items[2].secondary == 42.0f);
    CHECK(dst.items[1].firstVert == 4);
    CHECK(dst.items[2].firstVert == 12);
    CHECK(dst.items[1].quadCount == 2);
    CHECK(dst.raw[4].x == 10.0f);
    CHECK(dst.raw[12].x == 20.0f);
    CHECK(dst.items[0].seq < dst.items[1].seq);
    CHECK(dst.items[1].seq < dst.items[2].seq);
    // Without a key the secondary of the source stays.
    QuadList other;
    other.append_items(src, 3, 1);
    CHECK(other.items[0].secondary == 3.0f);
    CHECK(other.raw.size() == 8);
    // An empty range changes nothing and answers the end of the list.
    CHECK(other.append_items(src, 0, 0) == 1);
    CHECK(other.items.size() == 1);
}
