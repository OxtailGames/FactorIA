// The 3D world gathered once per frame (RenderScene) and shared by every camera, render target and CameraView; the hash of
// the material overrides kept while they do not change (MaterialHashCache). docs/design/ARCHITECTURE_RENDERING.md, "Rendering".
#include "test_util.h"

#include <algorithm>
#include <chrono>
#include <cstdio>
#include <vector>

#include "fa/core/jobs.h"
#include "render_internal.h"
#include "render_scene.h"

using namespace fa;
using namespace fa::test;

namespace {

float frac(int i, int salt) { return float((i * 2654435761u + salt * 40503u) % 10007u) / 10007.0f; }

// A perspective camera at the origin's side looking down -Z, drawn into the whole target (several of them draw one over
// the other: the frame is then one job per camera, each gathering the world on its own).
Entity perspective_camera(World& w, const char* name, int depth) {
    Entity e = make(w, name, {0, 3, 18});
    auto& c = w.add<Camera>(e);
    c.projection = Projection::Perspective;
    c.fov = 60;
    c.depth = depth;
    c.clear = depth == 0;
    c.clearColor = Color::hex(0x202830);
    return e;
}

// `count` cubes and spheres spread over (and beyond) the view, some translucent, some with per-material colours.
void scatter_meshes(World& w, int count) {
    const char* shapes[] = {"cube", "sphere"};
    for (int i = 0; i < count; ++i) {
        Entity e = make(w, "m", {frac(i, 1) * 60 - 30, frac(i, 2) * 12 - 3, frac(i, 3) * 40 - 30});
        w.get<Transform>(e)->scale = {0.6f, 0.6f, 0.6f};
        auto& m = w.add<MeshRenderer>(e);
        m.mesh = shapes[i % 2];
        m.color = Color{float(i % 5) / 4.0f, float(i % 3) / 2.0f, float(i % 7) / 6.0f, i % 9 == 0 ? 0.5f : 1.0f};
        if (i % 4 == 0) m.materialColors = Json{{"body", Json::array({0.2f, 0.4f + float(i % 3) * 0.1f, 0.9f, 1.0f})}};
    }
}

struct Counts {
    int meshes = 0, culled = 0, batches = 0, drawCalls = 0, triangles = 0;
    bool operator==(const Counts&) const = default;
};

Counts counts_of(const RenderStats& s) { return {s.meshes, s.meshesCulled, s.meshBatches, s.drawCalls, s.triangles}; }

Counts frame_counts(World& w) {
    Gfx& g = gfx();
    g.render(w);
    return counts_of(g.renderer.stats());
}

}  // namespace

TEST_CASE("render scene: N cameras on one frame draw N times what one camera draws") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Counts one;
    {
        World w;
        perspective_camera(w, "cam0", 0);
        scatter_meshes(w, 500);
        one = frame_counts(w);
    }
    CHECK(one.meshes > 50);
    CHECK(one.culled > 50);  // the scatter reaches beyond the frustum
    for (int n : {2, 4}) {
        INFO("cameras: " << n);
        World w;
        for (int c = 0; c < n; ++c) perspective_camera(w, ("cam" + std::to_string(c)).c_str(), c);
        scatter_meshes(w, 500);
        const Counts many = frame_counts(w);
        CHECK(many.meshes == n * one.meshes);
        CHECK(many.culled == n * one.culled);
        CHECK(many.batches == n * one.batches);
        CHECK(many.triangles == n * one.triangles);
        CHECK(many.drawCalls >= n * one.batches);
    }
    g.renderer.clear_asset_cache();
}

TEST_CASE("render scene: a camera hiding a tag draws fewer meshes, the others are not affected") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity cam = perspective_camera(w, "cam0", 0);
    scatter_meshes(w, 300);
    const Counts all = frame_counts(w);
    int tagged = 0;
    w.each<MeshRenderer>([&](Entity e, MeshRenderer&) {
        if (tagged % 3 == 0) w.info(e).tags.push_back("hidden");
        ++tagged;
    });
    w.get<Camera>(cam)->hideTags = Json::array({"hidden"});
    const Counts hidden = frame_counts(w);
    CHECK(hidden.meshes + hidden.culled < all.meshes + all.culled);
    CHECK(hidden.meshes < all.meshes);
    w.get<Camera>(cam)->hideTags = Json::array();
    CHECK(frame_counts(w) == all);
    g.renderer.clear_asset_cache();
}

TEST_CASE("render scene: a render target and a CameraView gather the same world as a camera of their own") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // The game camera alone, then with a render target camera (its texture on a quad nobody sees) and a CameraView.
    Counts game;
    {
        World w;
        perspective_camera(w, "cam0", 0);
        scatter_meshes(w, 400);
        game = frame_counts(w);
    }
    {
        World w;
        perspective_camera(w, "cam0", 0);
        scatter_meshes(w, 400);
        Entity tc = perspective_camera(w, "mirror", 5);
        Camera* c = w.get<Camera>(tc);
        c->renderTarget = "mirror";
        c->renderTargetSize = Vec2{320, 180};  // the aspect of the game camera: the same frustum
        // A mesh that shows the target, in front of the game camera.
        Entity screen = make(w, "screen", {0, 3, 10});
        auto& m = w.add<MeshRenderer>(screen);
        m.mesh = "cube";
        m.texture = "target:mirror";
        const Counts withTarget = frame_counts(w);
        CHECK(g.renderer.stats().renderTargets == 1);
        // The game camera draws what it drew (plus the screen mesh), the target's camera draws the same world again (the
        // target's own screen mesh included: it is the checker there).
        CHECK(withTarget.meshes == 2 * (game.meshes + 1));
        CHECK(withTarget.culled == 2 * game.culled);
    }
    {
        World w;
        perspective_camera(w, "cam0", 0);
        scatter_meshes(w, 400);
        Entity stage = make(w, "stage", {0, 3, 18});
        auto& c = w.add<Camera>(stage);
        c.projection = Projection::Perspective;
        c.fov = 60;
        c.primary = false;
        Entity viewE = make(w, "view", {20, 20, 0});
        CameraView& v = w.add<CameraView>(viewE);
        v.camera = "stage";
        v.size = {120, 100};
        v.pivot = {0, 1};
        const Counts withView = frame_counts(w);
        CHECK(g.renderer.stats().views == 1);
        CHECK(withView.meshes + withView.culled == 2 * (game.meshes + game.culled));
        CHECK(withView.meshes >= game.meshes);
    }
    g.renderer.clear_asset_cache();
}

TEST_CASE("render scene: frame cost with 1 and 4 cameras over 2000 meshes (reported, never asserted)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (int n : {1, 4}) {
        World w;
        for (int c = 0; c < n; ++c) perspective_camera(w, ("cam" + std::to_string(c)).c_str(), c);
        scatter_meshes(w, 2000);
        g.render(w);
        std::vector<double> ms;
        for (int f = 0; f < 5; ++f) {
            g.render(w);
            ms.push_back(g.renderer.stats().cpuMs);
        }
        std::sort(ms.begin(), ms.end());
        char line[160];
        std::snprintf(line, sizeof line, "2000 meshes, %d camera(s): render cpu median %.2f ms (min %.2f, max %.2f)", n,
                      ms[ms.size() / 2], ms.front(), ms.back());
        MESSAGE(line);
        CHECK(g.renderer.stats().meshes + g.renderer.stats().meshesCulled == 2000 * n);
    }
    g.renderer.clear_asset_cache();
}

TEST_CASE("render scene: a camera re-keys the meshes its lods swap in (the batches are those of the swapped meshes)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // 60 items of two colours at two distances from the camera (0,3,18): within and beyond the 30 of the lod level. Every
    // item has the same mesh name in the scene, so a key not made again would sort cube and sphere items interleaved.
    auto scene = [&](bool lods, World& w) {
        perspective_camera(w, "cam0", 0);
        for (int i = 0; i < 60; ++i) {
            const bool far = (i / 2) % 2 == 1;
            Entity e = make(w, "m", {float(i % 10) - 5.0f, 2.0f, far ? -20.0f : 0.0f});
            auto& m = w.add<MeshRenderer>(e);
            m.color = i % 2 ? Color{1, 0, 0, 1} : Color{0, 0, 1, 1};
            if (lods) {
                m.mesh = "cube";
                m.lods = Json::array({Json{{"mesh", "sphere"}, {"distance", 30}}});
            } else {
                m.mesh = far ? "sphere" : "cube";
            }
        }
    };
    World withLods, direct;
    scene(true, withLods);
    scene(false, direct);
    const Counts a = frame_counts(withLods);
    const Counts b = frame_counts(direct);
    CHECK(a.meshes > 0);
    CHECK(a == b);
    CHECK(a.batches == 4);  // two meshes x two colours
    g.renderer.clear_asset_cache();
}

TEST_CASE("render scene: a build of a subtree keeps the hash entries of the rest of the world") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    render::Assets assets(*render::renderer_gpu(g.renderer));
    World w;
    Entity root = make(w, "root");
    for (int i = 0; i < 6; ++i) {
        Entity e = make(w, "m");
        if (i < 2) w.set_parent(e, root);
        auto& m = w.add<MeshRenderer>(e);
        m.mesh = "cube";
        m.materialColors = Json{{"body", Json::array({0.1f * float(i), 0.5f, 0.5f, 1.0f})}};
    }
    render::RenderScene scene;
    scene.build(w, assets, kNullEntity, false);
    CHECK(scene.meshes().size() == 6);
    CHECK(scene.hash_cache().size() == 6);
    const std::uint64_t computed = scene.hash_cache().computed();
    scene.build(w, assets, root, false);  // what capture_world does
    CHECK(scene.meshes().size() == 2);
    CHECK(scene.hash_cache().size() == 6);  // nothing dropped
    scene.build(w, assets, kNullEntity, false);
    CHECK(scene.hash_cache().size() == 6);
    CHECK(scene.hash_cache().computed() == computed);  // nothing hashed again either
    CHECK(scene.sort_key_fallbacks() == 0);
    scene.reset();
    assets.clear();
}

// ---- MaterialHashCache: no GPU ----

TEST_CASE("material hash: an entity asked for twice in one frame does not keep a stale entry alive") {
    World w;
    Entity a = make(w, "a"), b = make(w, "b");
    w.add<MeshRenderer>(a);
    w.add<MeshRenderer>(b);
    const Json params{{"k", 1}};
    render::MaterialHashCache cache;
    std::size_t p = 0, c = 0;
    cache.begin_frame();
    cache.hashes(a, &params, nullptr, p, c);
    cache.hashes(b, &params, nullptr, p, c);
    cache.end_frame();
    CHECK(cache.size() == 2);
    cache.begin_frame();  // only `a`, and twice: two touches, one distinct entry
    cache.hashes(a, &params, nullptr, p, c);
    cache.hashes(a, &params, nullptr, p, c);
    cache.end_frame();
    CHECK(cache.size() == 1);  // b's entry went
}

TEST_CASE("material hash: the instanced params of the material are left out, as in the real path") {
    World w;
    Entity a = make(w, "a"), b = make(w, "b");
    render::MaterialAsset material;
    material.instancedNames = {"tint"};
    material.instancedKey = 7;
    const Json pa{{"tint", 1}, {"size", 2}}, pb{{"tint", 5}, {"size", 2}};
    render::MaterialHashCache cache;
    std::size_t ha = 0, hb = 0, c = 0;
    cache.begin_frame();
    cache.hashes(a, &pa, nullptr, ha, c, &material);
    cache.hashes(b, &pb, nullptr, hb, c, &material);
    cache.end_frame();
    CHECK(ha != 0);
    CHECK(ha == hb);  // they differ only in the instanced param: one batch
    cache.begin_frame();
    cache.hashes(a, &pa, nullptr, ha, c);
    cache.hashes(b, &pb, nullptr, hb, c);
    cache.end_frame();
    CHECK(ha != hb);  // without the material the values count
}

TEST_CASE("material hash: computed when the overrides change, never again while they stay") {
    World w;
    Entity a = make(w, "a"), b = make(w, "b");
    MeshRenderer& ma = w.add<MeshRenderer>(a);
    MeshRenderer& mb = w.add<MeshRenderer>(b);
    ma.materialParams = Json{{"tint", Json::array({1.0f, 0.5f, 0.0f, 1.0f})}};
    mb.materialParams = ma.materialParams;
    mb.materialColors = Json{{"body", Json::array({0.1f, 0.2f, 0.3f, 1.0f})}};

    render::MaterialHashCache cache;
    std::size_t pa = 0, ca = 0, pb = 0, cb = 0;
    auto frame = [&]() {
        cache.begin_frame();
        cache.hashes(a, &ma.materialParams, nullptr, pa, ca);
        cache.hashes(b, &mb.materialParams, &mb.materialColors, pb, cb);
        cache.end_frame();
    };
    frame();
    CHECK(cache.computed() == 3);  // a's params, b's params and colours
    CHECK(pa != 0);
    CHECK(pa == pb);  // the same overrides hash alike: such items share a draw
    CHECK(ca == 0);
    CHECK(cb != 0);
    const std::size_t pa0 = pa, pb0 = pb, cb0 = cb;
    for (int f = 0; f < 5; ++f) {
        frame();
        CHECK(pa == pa0);
        CHECK(pb == pb0);
        CHECK(cb == cb0);
    }
    CHECK(cache.computed() == 3);  // five frames without an edit: nothing hashed again

    ma.materialParams["tint"][1] = 0.25f;  // an edit
    frame();
    CHECK(cache.computed() == 4);
    CHECK(pa != pa0);  // the edited entity has a new hash, so it leaves the batch of the other
    CHECK(pb == pb0);
    CHECK(cb == cb0);
    mb.materialColors["body"][0] = 0.9f;
    frame();
    CHECK(cache.computed() == 5);
    CHECK(cb != cb0);
}

TEST_CASE("material hash: a slot reused with other params gets the new hash, dead entities are dropped") {
    World w;
    Entity first = make(w, "first");
    w.add<MeshRenderer>(first).materialParams = Json{{"k", 1}};
    render::MaterialHashCache cache;
    std::size_t p1 = 0, c1 = 0;
    cache.begin_frame();
    cache.hashes(first, &w.get<MeshRenderer>(first)->materialParams, nullptr, p1, c1);
    cache.end_frame();
    CHECK(cache.size() == 1);
    w.destroy(first);
    w.flush();
    Entity second = make(w, "second");  // a new entity (the slot of the first one when the world reuses slots)
    w.add<MeshRenderer>(second).materialParams = Json{{"k", 2}};
    std::size_t p2 = 0, c2 = 0;
    cache.begin_frame();
    cache.hashes(second, &w.get<MeshRenderer>(second)->materialParams, nullptr, p2, c2);
    cache.end_frame();
    CHECK(p2 != p1);
    CHECK(p2 == std::hash<std::string>{}(w.get<MeshRenderer>(second)->materialParams.dump()));
    CHECK(cache.size() == 1);  // the dead entity's entry went with the frame that did not ask for it

    // The same entity written again is a new hash as well.
    w.get<MeshRenderer>(second)->materialParams = Json{{"k", 3}};
    std::size_t p3 = 0, c3 = 0;
    cache.begin_frame();
    cache.hashes(second, &w.get<MeshRenderer>(second)->materialParams, nullptr, p3, c3);
    cache.end_frame();
    CHECK(p3 != p2);
    // Overrides taken away: hash 0, and the next frame that does not ask for the entity forgets it.
    cache.begin_frame();
    cache.hashes(second, nullptr, nullptr, p3, c3);
    cache.end_frame();
    CHECK(p3 == 0);
    cache.begin_frame();
    cache.end_frame();
    CHECK(cache.size() == 0);
}

// ---- determinism across job settings ----

namespace {

// Draws two frames of a scene with 3 cameras (one with a hide tag), blended meshes and 1500 meshes, with the pool set up as
// `settings` (or stopped), and gives the stats and the picture of the second one.
struct SceneRun {
    std::string stats;
    std::vector<std::uint8_t> pixels;
};

SceneRun run_scene(bool start, const jobs::Settings& settings) {
    Gfx& g = gfx();
    REQUIRE(!jobs::running());
    if (start) {
        auto r = jobs::start(settings);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : r.error().to_string()));
    }
    g.renderer.clear_asset_cache();
    World w;
    perspective_camera(w, "cam0", 0);
    Entity hiding = perspective_camera(w, "cam1", 1);
    Entity side = perspective_camera(w, "cam2", 2);
    w.get<Transform>(side)->position = {10, 3, 12};
    scatter_meshes(w, 1500);
    int n = 0;
    w.each<MeshRenderer>([&](Entity e, MeshRenderer&) {
        if (n++ % 5 == 0) w.info(e).tags.push_back("ghost");
    });
    w.get<Camera>(hiding)->hideTags = Json::array({"ghost"});
    SceneRun out;
    for (int f = 0; f < 2; ++f) {
        Image img = g.render(w);
        jobs::end_frame();
        out.pixels = img.rgba;
    }
    Json st = g.renderer.stats().to_json();
    st.erase("cpuMs");
    out.stats = st.dump();
    g.renderer.clear_asset_cache();
    if (start) jobs::stop();
    return out;
}

}  // namespace

TEST_CASE("render scene: the frame is the same with jobs stopped, inline and with 2 or 8 workers") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const SceneRun base = run_scene(false, {});
    CHECK(!base.stats.empty());
    std::vector<jobs::Settings> others{jobs::Settings::inline_jobs()};
    if (jobs::threads_supported()) {
        others.push_back(jobs::Settings::threads(2));
        others.push_back(jobs::Settings::threads(8));
    }
    for (const jobs::Settings& s : others) {
        const SceneRun run = run_scene(true, s);
        CHECK(run.stats == base.stats);
        CHECK(run.pixels == base.pixels);
    }
}
