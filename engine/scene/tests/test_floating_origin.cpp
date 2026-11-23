// M75-P4a: the floating origin in the scene module (fa/scene/floating_origin.h, World::rebase, docs/BIG_WORLDS_STREAMING.md "Floating origin"):
// what moves with a rebase, what does not, and that the origin is exact, reversible and saved.
#include <doctest.h>

#include <cmath>

#include "fa/scene/camera_geometry.h"
#include "fa/scene/feel.h"
#include "fa/scene/floating_origin.h"
#include "fa/scene/interpolation.h"
#include "fa/scene/particles.h"
#include "fa/scene/serialize.h"
#include "fa/scene/world.h"

using namespace fa;

namespace {

Entity make_at(World& w, const char* id, Vec3 p) {
    Entity e = w.create(id, id);
    w.get<Transform>(e)->position = p;
    return e;
}

}  // namespace

TEST_CASE("floating origin: the arithmetic (snap, automatic offset, offset check)") {
    ensure_builtin_components();
    CHECK(snap_to_step({300, -300, 100}, 256.0) == Vec3{256, -256, 0});
    CHECK(snap_to_step({384, 127, -128}, 256.0) == Vec3{512, 0, -256});  // ties away from 0
    CHECK(auto_rebase_offset({2000, 100, -2000}, 2048.0, 256.0) == Vec3{});
    // Any axis past the threshold rebases, y included: the other axes are snapped too.
    CHECK(auto_rebase_offset({0, 3000, 0}, 2048.0, 256.0) == Vec3{0, 3072, 0});
    CHECK(auto_rebase_offset({-5000, 10, 3000}, 2048.0, 256.0) == Vec3{-5120, 0, 3072});

    CHECK(check_rebase_offset({256, -512, 0}, 256.0, "/offset").ok());
    const auto bad = check_rebase_offset({300, 0, 0}, 256.0, "/offset");
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("/offset") != std::string::npos);
    CHECK(bad.error().message.find("multiple") != std::string::npos);
    CHECK(bad.error().hint.find("256") != std::string::npos);  // the nearest multiple
    const auto huge = check_rebase_offset({256.0 * 33554432.0, 0, 0}, 256.0, "/offset");
    REQUIRE_FALSE(huge.ok());
    CHECK(huge.error().message.find("precision") != std::string::npos);
    CHECK_FALSE(check_rebase_offset({std::nan(""), 0, 0}, 256.0, "/offset").ok());
}

TEST_CASE("floating origin: a rebase shifts the roots, the children follow, the absolute position does not change") {
    ensure_builtin_components();
    World w;
    Entity root = make_at(w, "root", {5000, 10, -3000});
    Entity child = make_at(w, "child", {1, 2, 3});
    w.set_parent(child, root);
    Entity other = make_at(w, "other", {0, 0, 0});
    CHECK(w.origin() == DVec3{});
    const DVec3 rootAbs = w.absolute_position(root);
    const DVec3 childAbs = w.absolute_position(child);
    (void)w.world_position(child);  // fills the hierarchy cache: the rebase must invalidate it

    w.rebase({4864, 0, -3072});
    CHECK(w.get<Transform>(root)->position == Vec3{136, 10, 72});
    CHECK(w.get<Transform>(child)->position == Vec3{1, 2, 3});  // local to its parent: untouched
    CHECK(w.world_position(child) == Vec3{137, 12, 75});
    CHECK(w.get<Transform>(other)->position == Vec3{-4864, 0, 3072});
    CHECK(w.origin() == DVec3{4864, 0, -3072});
    CHECK(w.absolute_position(root) == rootAbs);
    CHECK(w.absolute_position(child) == childAbs);
    CHECK(w.to_local(rootAbs) == Vec3{136, 10, 72});
    CHECK(w.to_absolute({136, 10, 72}) == rootAbs);
    CHECK(w.rebase_count() == 1);

    // Reversible bit for bit.
    w.rebase({-4864, 0, 3072});
    CHECK(w.get<Transform>(root)->position == Vec3{5000, 10, -3000});
    CHECK(w.origin() == DVec3{});
    CHECK(w.rebase_count() == 2);
    w.clear();
    CHECK(w.rebase_count() == 0);
}

TEST_CASE("floating origin: screen-space roots do not move") {
    ensure_builtin_components();
    World w;
    Entity hud = make_at(w, "hud", {100, 50, 0});
    w.add<Panel>(hud);
    Entity sprite = make_at(w, "sprite", {100, 50, 0});
    w.add<Sprite>(sprite).space = RenderSpace::Screen;
    Entity plain = make_at(w, "plain", {100, 50, 0});
    w.add<Sprite>(plain);
    CHECK_FALSE(follows_floating_origin(w, hud));
    CHECK_FALSE(follows_floating_origin(w, sprite));
    CHECK(follows_floating_origin(w, plain));
    w.rebase({256, 0, 0});
    CHECK(w.get<Transform>(hud)->position == Vec3{100, 50, 0});
    CHECK(w.get<Transform>(sprite)->position == Vec3{100, 50, 0});
    CHECK(w.get<Transform>(plain)->position == Vec3{-156, 50, 0});
}

TEST_CASE("floating origin: the observers are called once per rebase with the offset, and can be removed") {
    ensure_builtin_components();
    World w;
    int calls = 0;
    DVec3 seen{};
    const int id = w.on_origin_shifted([&](const DVec3& o) {
        ++calls;
        seen = o;
    });
    w.rebase({512, 0, 0});
    CHECK(calls == 1);
    CHECK(seen == DVec3{512, 0, 0});
    w.rebase({0, 0, 0});  // nothing to shift: no notification, no count
    CHECK(calls == 1);
    CHECK(w.rebase_count() == 1);
    w.remove_origin_observer(id);
    w.rebase({256, 0, 0});
    CHECK(calls == 1);
}

TEST_CASE(
    "floating origin: set_origin and clear tell the observers how the origin changed, so what they keep follows it") {
    ensure_builtin_components();
    World w;
    int calls = 0;
    DVec3 total{};  // what an observer that keeps a point in world space would add up
    w.on_origin_shifted([&](const DVec3& o) {
        ++calls;
        total = total + o;
    });
    w.set_origin({1024, 0, -2048});  // a scene load that carries an origin
    CHECK(calls == 1);
    CHECK(total == DVec3{1024, 0, -2048});
    CHECK(w.origin() == DVec3{1024, 0, -2048});
    w.set_origin({1024, 0, -2048});  // the same origin: nothing changed, nobody is told
    CHECK(calls == 1);
    w.rebase({0, 0, 512});
    CHECK(calls == 2);
    w.clear();  // the origin goes back to zero: observers get the change that undoes all of it
    CHECK(calls == 3);
    CHECK(total == DVec3{0, 0, 0});
    CHECK(w.origin() == DVec3{0, 0, 0});
    w.clear();  // already at zero: no call
    CHECK(calls == 3);
}

TEST_CASE("floating origin: the interpolation records shift with the transform (no jump at the next frame)") {
    ensure_builtin_components();
    World w;
    w.interp().enabled = true;
    Entity box = w.create("box", "box");
    w.add<Sprite>(box);
    w.get<Transform>(box)->position = {5000, 0, 0};
    interp_update(w, 1.0, true);
    interp_begin_step(w);
    w.get<Transform>(box)->position.x += 10.0f;
    interp_update(w, 0.5, true);
    interp_update(w, 0.5, false);
    CHECK(w.drawn_matrix(box).translation().x == doctest::Approx(5005.0f));
    w.rebase({4864, 0, 0});
    interp_update(w, 0.5, false);
    CHECK(w.get<Transform>(box)->position.x == doctest::Approx(146.0f));
    CHECK(w.drawn_matrix(box).translation().x == doctest::Approx(141.0f));  // 5005 - 4864: still halfway, no snap
}

TEST_CASE("floating origin: world-space particles stay in the world, an emitter's own-space ones are left alone") {
    ensure_builtin_components();
    ParticleEmitter em;
    em.rate = 0.0f;
    em.burst = 4;
    em.speed = 0.0f;
    em.speedVariance = 0.0f;
    em.lifetime = 10.0f;
    em.gravity = {0, 0, 0};
    ParticleSim s;
    s.seed(1);
    ParticleEnv env;
    env.emitter = Mat4::translate({6000, 0, 0});
    s.step(em, env, 1.0f / 60.0f);
    REQUIRE(s.particles.size() == 4);
    double before = 0;
    for (const Particle& p : s.particles) before += p.pos.x;
    s.shift({4864, 0, 0});
    double after = 0;
    for (const Particle& p : s.particles) after += p.pos.x;
    CHECK(after == doctest::Approx(before - 4.0 * 4864.0).epsilon(1e-5));
}

TEST_CASE("floating origin: a scene saves its origin only when it is not zero, and loads it back") {
    ensure_builtin_components();
    World a;
    make_at(a, "e", {10, 0, 0});
    CHECK_FALSE(save_scene(a).contains("origin"));  // an old scene is saved as it was

    a.rebase({256 * 3000.0f, 0, -256});
    const Json saved = save_scene(a);
    REQUIRE(saved.contains("origin"));
    CHECK(saved["origin"][0].get<double>() == 768000.0);
    CHECK(saved["origin"][2].get<double>() == -256.0);

    World b;
    const LoadReport r = load_scene(b, saved, "origin.scene.json");
    INFO(r.summary());
    REQUIRE(r.ok());
    CHECK(b.origin() == a.origin());
    const Entity e = b.find_by_id("e");
    REQUIRE_FALSE(e.is_null());
    CHECK(b.absolute_position(e) == a.absolute_position(a.find_by_id("e")));  // 768010: the same place in the world

    // A zero origin loads as zero (a scene that never had one), and a mistake names the pointer.
    World c;
    c.rebase({256, 0, 0});
    REQUIRE(load_scene(c, save_scene(World{}), "plain").ok());
    CHECK(c.origin() == DVec3{});
    Json broken = saved;
    broken["origin"] = Json::parse("[1, 2]");
    World d;
    const LoadReport bad = load_scene(d, broken, "broken.scene.json");
    CHECK_FALSE(bad.ok());
    CHECK(bad.summary().find("/origin") != std::string::npos);
}

TEST_CASE("floating origin: 200 km out a float loses millimetres, with the origin they stay") {
    ensure_builtin_components();
    // A body moving 1 mm a step, 1000 steps, at x = 200 000 m. A float there is a multiple of 1/64 m (15.6 mm): x + 0.001 rounds back
    // to x and the body does not move at all.
    World outWorld;
    Entity a = make_at(outWorld, "a", {200000.0f, 0, 0});
    for (int i = 0; i < 1000; ++i) outWorld.get<Transform>(a)->position.x += 0.001f;
    const double errorWithout = std::fabs(double(outWorld.get<Transform>(a)->position.x) - 200001.0);
    CHECK(errorWithout > 0.5);

    // The same body with the origin on: the engine rebased by 199936 (781 steps of 256) while the anchor was near it, so the body is
    // 64 m from the local origin, where a float resolves under 0.01 mm, and its absolute position is a double.
    World rebased;
    Entity b = make_at(rebased, "b", {200000.0f, 0, 0});
    rebased.rebase({199936.0f, 0, 0});
    REQUIRE(rebased.get<Transform>(b)->position.x == 64.0f);
    for (int i = 0; i < 1000; ++i) rebased.get<Transform>(b)->position.x += 0.001f;
    const double errorWith = std::fabs(rebased.absolute_position(b).x - 200001.0);
    CHECK(errorWith < 0.002);
    CHECK(errorWith * 100 < errorWithout);
}

TEST_CASE("floating origin: a Parallax layer moves by offset * factor so what the player sees does not change") {
    ensure_builtin_components();
    const float factors[] = {0.5f, 0.0f, 1.0f, 0.25f};
    for (float f : factors) {
        CAPTURE(f);
        World w;
        Entity layer = make_at(w, "layer", {40000.0f, 300.0f, 2.0f});
        w.add<Parallax>(layer).factor = {f, f};
        Entity cam = make_at(w, "cam", {40100.0f, 310.0f, 0});
        auto seen = [&]() {  // drawn - camera: what the player sees of the layer
            const Vec3 c = w.world_position(cam);
            update_parallax(w, {c.x, c.y});
            const Vec3 p = w.world_position(layer);
            const Parallax* par = w.get<Parallax>(layer);
            return Vec2{p.x + par->offset.x - c.x, p.y + par->offset.y - c.y};
        };
        const Vec2 before = seen();
        w.rebase({39936.0f, 256.0f, 64.0f});  // 624 * 64 on x
        const Vec2 after = seen();
        CHECK(after.x == before.x);
        CHECK(after.y == before.y);
        // The layer's absolute position moved by factor * offset (it is glued to the camera by 1 - factor).
        CHECK(w.absolute_position(layer).x == doctest::Approx(40000.0 + (1.0 - f) * 39936.0).epsilon(1e-9));
        CHECK(w.absolute_position(layer).z == 2.0);  // z has no parallax: it moved with the world
        w.rebase({-39936.0f, -256.0f, -64.0f});      // back: bit for bit
        CHECK(w.get<Transform>(layer)->position.x == 40000.0f);
        CHECK(w.get<Transform>(layer)->position.y == 300.0f);
    }
}

TEST_CASE("floating origin: the world points components hold move with a rebase") {
    ensure_builtin_components();
    World w;
    Entity link = make_at(w, "link", {5000, 0, 0});
    w.add<NavLink3D>(link).end = {5100, 0, 30};
    Entity probes = make_at(w, "probes", {5000, 0, 0});
    w.add<LightProbeGroup>(probes).points = Json::parse("[[5001, 2, 3], [5002.5, 1, 0], \"not a point\"]");
    Entity j2 = make_at(w, "j2", {5000, 0, 0});
    w.add<Joint2D>(j2).connectedAnchor = {5000, 20};  // `connected` empty: a world position
    Entity j2b = make_at(w, "j2b", {5000, 0, 0});
    Joint2D& pinned = w.add<Joint2D>(j2b);
    pinned.connected = j2;  // joined to a body: connectedAnchor is local to it and does not move
    pinned.connectedAnchor = {7, 8};
    Entity j3 = make_at(w, "j3", {5000, 0, 0});
    w.add<Joint3D>(j3).connectedAnchor = {5000, 1, 2};

    w.rebase({4096, 0, -64});
    CHECK(w.get<NavLink3D>(link)->end == Vec3{1004, 0, 94});
    const Json& pts = w.get<LightProbeGroup>(probes)->points;
    CHECK(pts[0] == Json::parse("[905, 2, 67]"));
    CHECK(pts[1] == Json::parse("[906.5, 1, 64]"));
    CHECK(pts[2] == "not a point");  // anything that is not [x, y, z] stays
    CHECK(w.get<Joint2D>(j2)->connectedAnchor == Vec2{904, 20});
    CHECK(w.get<Joint2D>(j2b)->connectedAnchor == Vec2{7, 8});
    CHECK(w.get<Joint3D>(j3)->connectedAnchor == Vec3{904, 1, 66});
    // The absolute point (local + origin) is what it was.
    CHECK(double(w.get<NavLink3D>(link)->end.x) + w.origin().x == 5100.0);
}

TEST_CASE("floating origin: an additive load places what it loads at its absolute position") {
    ensure_builtin_components();
    // A cell saved at origin 0: a root with a child, a nav link, a world-pinned joint and probe points.
    World cell;
    Entity root = make_at(cell, "root", {100, 5, 7});
    Entity child = make_at(cell, "child", {1, 2, 3});
    cell.set_parent(child, root);
    Entity link = make_at(cell, "link", {300, 0, 0});
    cell.add<NavLink3D>(link).end = {310, 0, 0};
    Entity pin = make_at(cell, "pin", {200, 0, 0});
    cell.add<Joint2D>(pin).connectedAnchor = {200, 10};
    Entity probes = make_at(cell, "probes", {400, 0, 0});
    cell.add<LightProbeGroup>(probes).points = Json::parse("[[401, 1, 1]]");
    const Json file = save_scene(cell);
    REQUIRE_FALSE(file.contains("origin"));

    // Loaded into a world whose origin moved to 4096: the roots land at 4096 less locally, the absolute position is the saved one.
    World w;
    w.rebase({4096, 0, 0});
    REQUIRE(w.origin() == DVec3{4096, 0, 0});
    SceneLoadOptions add;
    add.additive = true;
    const LoadReport r = load_scene(w, file, "cell.scene.json", add);
    INFO(r.summary());
    REQUIRE(r.ok());
    CHECK(w.origin() == DVec3{4096, 0, 0});  // an additive load never moves the origin
    const Entity lr = w.find_by_id("root"), lc = w.find_by_id("child");
    REQUIRE_FALSE(lr.is_null());
    CHECK(w.absolute_position(lr) == DVec3{100, 5, 7});
    CHECK(w.get<Transform>(lr)->position == Vec3{100 - 4096, 5, 7});
    CHECK(w.get<Transform>(lc)->position == Vec3{1, 2, 3});  // a child stays local to its parent
    CHECK(w.absolute_position(lc) == DVec3{101, 7, 10});
    CHECK(double(w.get<NavLink3D>(w.find_by_id("link"))->end.x) + w.origin().x == 310.0);
    CHECK(double(w.get<Joint2D>(w.find_by_id("pin"))->connectedAnchor.x) + w.origin().x == 200.0);
    CHECK(w.get<LightProbeGroup>(w.find_by_id("probes"))->points[0] == Json::parse("[-3695, 1, 1]"));

    // A file with its own origin: positions are local to THAT origin, so they land at file origin - world origin more.
    World farWorld;
    farWorld.rebase({8192, 0, 0});
    make_at(farWorld, "far", {10, 0, 0});  // absolute 8202
    const Json farFile = save_scene(farWorld);
    REQUIRE(farFile["origin"][0].get<double>() == 8192.0);
    World w2;
    w2.rebase({4096, 0, 0});
    const LoadReport r2 = load_scene(w2, farFile, "far.scene.json", add);
    REQUIRE(r2.ok());
    CHECK(w2.origin() == DVec3{4096, 0, 0});
    CHECK(w2.absolute_position(w2.find_by_id("far")) == DVec3{8202, 0, 0});
    CHECK(w2.get<Transform>(w2.find_by_id("far"))->position.x == 4106.0f);

    // A non-additive load still restores the file's origin and leaves the positions as written.
    World w3;
    w3.rebase({4096, 0, 0});
    REQUIRE(load_scene(w3, farFile, "far.scene.json").ok());
    CHECK(w3.origin() == DVec3{8192, 0, 0});
    CHECK(w3.get<Transform>(w3.find_by_id("far"))->position.x == 10.0f);

    // Under a parent the roots are relative to it: nothing moves.
    World w4;
    w4.rebase({4096, 0, 0});
    Entity holder = make_at(w4, "holder", {5, 0, 0});
    SceneLoadOptions under = add;
    under.parent = holder;
    REQUIRE(load_scene(w4, farFile, "far.scene.json", under).ok());
    CHECK(w4.get<Transform>(w4.find_by_id("far"))->position.x == 10.0f);
}
