// M75.2 on a GPU: area and portal culling in the renderer (src/renderer_portals.cpp; docs/BIG_WORLDS_LOD.md, "Areas and portals"). Two
// rooms with a door between them: an open door shows the second room, a closed one hides it, the picture is the one a scene without the
// hidden meshes draws, shadows are not culled, and a scene with no enabled OcclusionArea takes the old path with the old numbers.
#include "test_util.h"

#include <cmath>

using namespace fa;
using namespace fa::test;

namespace {

Entity add_cube(World& w, const char* name, Vec3 pos, Color color) {
    Entity e = make(w, name, pos);
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = "cube";
    m.color = color;
    return e;
}

struct Rooms {
    Entity door, roomA, roomB, outside, inA, inB1, inB2;
};

// A camera at (0, 1.6, 3) looking down -Z through room A (area 1, z -5..5) and the door at z = -5 into room B (area 2, z -17..-5). One cube
// in A, two in B, one far outside every area. `areas` false leaves out the OcclusionArea and OcclusionPortal components (the same meshes).
Rooms make_rooms(World& w, bool areas, bool open, bool withB = true, bool withOutside = true, bool sunShadows = false) {
    Rooms r;
    Entity cam = make(w, "cam", {0, 1.6f, 3});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    w.settings().ambientLight = Color{0.2f, 0.2f, 0.25f, 1};
    Entity sun = make(w, "sun", {0, 5, 0});
    w.get<Transform>(sun)->rotation = {-50, 25, 0};
    auto& l = w.add<Light>(sun);
    l.type = LightType::Directional;
    l.castShadows = sunShadows;
    r.inA = add_cube(w, "inA", {-2, 1, -1}, Color::hex(0x20e060));
    if (withB) {
        r.inB1 = add_cube(w, "inB1", {0, 1, -10}, Color::hex(0xe03020));
        r.inB2 = add_cube(w, "inB2", {2, 1, -12}, Color::hex(0x2060e0));
    }
    if (withOutside) r.outside = add_cube(w, "outside", {3, 1, -40}, Color::hex(0xe0e020));
    if (areas) {
        r.roomA = make(w, "roomA", {0, 2, 0});
        auto& a = w.add<OcclusionArea>(r.roomA);
        a.size = {10, 4, 10};
        a.areaId = 1;
        r.roomB = make(w, "roomB", {0, 2, -11});
        auto& b = w.add<OcclusionArea>(r.roomB);
        b.size = {10, 4, 12};
        b.areaId = 2;
        r.door = make(w, "door", {0, 1.5f, -5});
        auto& p = w.add<OcclusionPortal>(r.door);
        p.size = {2, 3, 0.2f};
        p.areaA = 2;
        p.areaB = 1;
        p.open = open;
    }
    return r;
}

int differing(const Image& a, const Image& b) {
    int n = 0;
    for (int y = 0; y < a.height; ++y)
        for (int x = 0; x < a.width; ++x) {
            const Color p = a.pixel(x, y), q = b.pixel(x, y);
            if (std::fabs(p.r - q.r) > 0.0f || std::fabs(p.g - q.g) > 0.0f || std::fabs(p.b - q.b) > 0.0f) ++n;
        }
    return n;
}

}  // namespace

TEST_CASE(
    "portals on a GPU: an open door shows the next room, a closed one hides it, the stats and the picture say so") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CHECK(g.renderer.supports("occlusionPortals"));
    World none, open, shut, onlyA, onlyAB;
    make_rooms(none, false, true);
    make_rooms(open, true, true);
    make_rooms(shut, true, false);
    make_rooms(onlyA, false, true, false, false);
    make_rooms(onlyAB, false, true, true, false);

    g.render(none);
    const RenderStats base = g.renderer.stats();
    CHECK(base.portalsVisited == 0);
    CHECK(base.meshesCulledByArea == 0);

    // Open: room A and room B are drawn, the cube outside every area (area 0, which no portal reaches) is not.
    const Image openPicture = g.render(open);
    const RenderStats o = g.renderer.stats();
    CHECK(o.portalsVisited == 1);
    CHECK(o.meshesCulledByArea == 1);
    CHECK(o.meshes == base.meshes - 1);  // `meshes` counts the meshes drawn: the cube outside every area is gone
    CHECK(o.meshesCulled == base.meshesCulled + 1);
    CHECK(differing(openPicture, g.render(onlyAB)) == 0);

    // Shut: only room A is drawn, and the picture is the one of a scene with nothing in B.
    const Image shutPicture = g.render(shut);
    const RenderStats s = g.renderer.stats();
    CHECK(s.portalsVisited == 0);
    CHECK(s.meshesCulledByArea == 3);
    CHECK(s.drawCalls < o.drawCalls);
    CHECK(differing(shutPicture, g.render(onlyA)) == 0);
    CHECK(differing(shutPicture, openPicture) > 0);

    // A script opens the door between two frames: the same world, the next frame shows the room.
    shut.get<OcclusionPortal>(shut.find("door"))->open = true;
    g.render(shut);
    CHECK(g.renderer.stats().meshesCulledByArea == 1);
}

TEST_CASE("portals on a GPU: a culled mesh still casts its shadow, and a camera outside sees through the front door") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World plain, shut;
    make_rooms(plain, false, true, true, true, true);
    make_rooms(shut, true, false, true, true, true);
    g.render(plain);
    const int casters = g.renderer.stats().shadowCasters;
    CHECK(casters > 0);
    g.render(shut);
    CHECK(g.renderer.stats().meshesCulledByArea == 3);
    CHECK(g.renderer.stats().shadowCasters == casters);

    // The camera moves outside (area 0) and a front door joins 0 and 1: the walk goes outside -> A -> B through two open portals.
    World w;
    const Rooms r = make_rooms(w, true, true, true, false);
    w.get<Transform>(w.find("cam"))->position = {0, 1.6f, 12};
    Entity front = make(w, "front", {0, 1.5f, 5});
    auto& p = w.add<OcclusionPortal>(front);
    p.size = {2, 3, 0.2f};
    p.areaA = 1;
    p.areaB = 0;
    g.render(w);
    CHECK(g.renderer.stats().portalsVisited == 2);
    CHECK(g.renderer.stats().meshesCulledByArea == 0);
    w.get<OcclusionPortal>(front)->open = false;
    g.render(w);
    CHECK(g.renderer.stats().portalsVisited == 0);
    CHECK(g.renderer.stats().meshesCulledByArea ==
          3);  // the cube of A and the two of B: the camera in area 0 reaches nothing else
    (void)r;
}

TEST_CASE("portals on a GPU: a scene with no enabled OcclusionArea draws and counts exactly as before") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World none, portalOnly, zeroId, off;
    make_rooms(none, false, true);
    make_rooms(portalOnly, false, true);
    // A portal with no area at all, an area with the invalid id 0, and an area on an inactive entity: nothing of that is a scene with areas.
    Entity d = make(portalOnly, "door", {0, 1.5f, -5});
    portalOnly.add<OcclusionPortal>(d).areaB = 1;
    make_rooms(zeroId, true, false);
    zeroId.get<OcclusionArea>(zeroId.find("roomA"))->areaId = 0;
    zeroId.get<OcclusionArea>(zeroId.find("roomB"))->areaId = 0;
    make_rooms(off, true, false);
    off.get<EntityInfo>(off.find("roomA"))->active = false;
    off.get<EntityInfo>(off.find("roomB"))->active = false;

    const Image ref = g.render(none);
    const RenderStats a = g.renderer.stats();
    for (World* w : {&portalOnly, &zeroId, &off}) {
        const Image img = g.render(*w);
        const RenderStats b = g.renderer.stats();
        CHECK(differing(ref, img) == 0);
        CHECK(b.meshes == a.meshes);
        CHECK(b.meshesCulled == a.meshesCulled);
        CHECK(b.drawCalls == a.drawCalls);
        CHECK(b.triangles == a.triangles);
        CHECK(b.portalsVisited == 0);
        CHECK(b.meshesCulledByArea == 0);
    }
}

TEST_CASE("portals on a GPU: a portal that names a missing area, joins an area to itself, or an area with id 0 is "
          "reported once") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    make_rooms(w, true, true);
    auto* door = w.get<OcclusionPortal>(w.find("door"));
    door->areaA = 3;  // no area has the id 3; 1 and 2 exist: the hint names them
    Entity self = make(w, "self", {5, 1.5f, 0});
    auto& sp = w.add<OcclusionPortal>(self);
    sp.areaA = 1;
    sp.areaB = 1;
    Entity zero = make(w, "zeroRoom", {40, 2, 0});
    w.add<OcclusionArea>(zero).areaId = 0;
    const std::uint64_t before = log_last_seq();
    g.render(w);
    g.render(w);
    std::string text;
    int count = 0;
    for (const LogEntry& e : recent_logs(500, LogLevel::Warn, before))
        if (e.category == "render" && (e.message.find("OcclusionPortal") != std::string::npos ||
                                       e.message.find("OcclusionArea") != std::string::npos)) {
            text += e.message + "\n";
            ++count;
        }
    INFO(text);
    CHECK(count == 3);  // once each, although two frames were drawn
    CHECK(text.find("names area 3") != std::string::npos);
    CHECK(text.find("'" + w.id_of(w.find("door")) + "'") != std::string::npos);
    CHECK(text.find("Did you mean") != std::string::npos);
    CHECK(text.find("both 1") != std::string::npos);
    CHECK(text.find("areaId is 0") != std::string::npos);
    // The portal that names nothing connects nothing: with the door unusable the second room is not reached.
    CHECK(g.renderer.stats().portalsVisited == 0);
}
