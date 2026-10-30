// Procedural meshes ("mesh:N" ids of MeshRenderer.mesh, fa/scene/mesh_store.h) on whatever GPU backend the machine has:
// the upload, the submesh materials, updates that reuse the buffers, bounds and culling, shadows, and the release of a
// mesh that was destroyed or whose scene was cleared.
#include "test_util.h"

#include <cmath>

#include "fa/scene/mesh_store.h"

using namespace fa;
using namespace fa::test;

namespace {

// A quad in the XY plane facing +Z, `half` wide, centred on `centre`.
MeshInput quad_input(float half, Vec3 centre = {0, 0, 0}) {
    MeshInput in;
    const float x0 = centre.x - half, x1 = centre.x + half, y0 = centre.y - half, y1 = centre.y + half, z = centre.z;
    in.positions = {x0, y0, z, x1, y0, z, x1, y1, z, x0, y1, z};
    in.uvs = {0, 1, 1, 1, 1, 0, 0, 0};
    in.indices = {0, 1, 2, 0, 2, 3};
    in.hasIndices = true;
    return in;
}

void camera_at_z(World& w, float z = 4.0f) {
    Entity cam = make(w, "cam", {0, 0, z});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    c.clearColor = Color{0, 0, 0, 1};
}

Entity show(World& w, const std::string& mesh, Vec3 pos = {0, 0, 0}) {
    Entity e = make(w, "shape", pos);
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = mesh;
    m.unlit = true;
    m.color = Color{1, 1, 1, 1};
    return e;
}

bool is_color(Color c, float r, float g, float b, float tol = 0.12f) {
    return std::fabs(c.r - r) < tol && std::fabs(c.g - g) < tol && std::fabs(c.b - b) < tol;
}

Json mesh_entry(Gfx& g, const std::string& id) {
    const Json report = g.renderer.asset_report();
    for (const Json& m : report["meshes"])
        if (m["mesh"] == id) return m;
    return Json();
}

bool has_failure(Gfx& g, const std::string& id) {
    const Json report = g.renderer.asset_report();
    for (const Json& f : report["failures"])
        if (f["path"] == id) return true;
    return false;
}

}  // namespace

TEST_CASE("procedural mesh: a mesh made from arrays is drawn with its submesh materials") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    camera_at_z(w);
    MeshInput in;
    // Two quads side by side, the left one green and the right one blue, as two submeshes.
    in.positions = {-2, -1, 0, 0, -1, 0, 0, 1, 0, -2, 1, 0,  //
                    0, -1, 0, 2, -1, 0, 2, 1, 0, 0, 1, 0};
    in.indices = {0, 1, 2, 0, 2, 3, 4, 5, 6, 4, 6, 7};
    in.hasIndices = true;
    MeshMaterial green, blue;
    green.name = "green";
    green.color = Color{0, 1, 0, 1};
    blue.name = "blue";
    blue.color = Color{0, 0, 1, 1};
    in.submeshes = {{green, 0, 6}, {blue, 6, 6}};
    auto id = w.meshes().create(in);
    REQUIRE(id.ok());
    show(w, *id);
    Image img = g.render(w);
    CHECK(g.renderer.stats().meshes == 1);
    CHECK(g.renderer.stats().drawCalls >= 2);
    CHECK(is_color(img.pixel(100, 90), 0, 1, 0));
    CHECK(is_color(img.pixel(220, 90), 0, 0, 1));
    CHECK_FALSE(is_color(img.pixel(160, 3), 0, 1, 0));  // above the quads: the sky
    const Json entry = mesh_entry(g, *id);
    REQUIRE(entry.is_object());
    CHECK(entry["triangles"] == 4);
    CHECK(entry["parts"] == 2);
    CHECK(entry["procedural"] == true);
}

TEST_CASE("procedural mesh: MeshRenderer.materialColors recolors a submesh by its material name") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    camera_at_z(w);
    MeshInput in = quad_input(1.5f);
    MeshMaterial m;
    m.name = "skin";
    m.color = Color{1, 0, 0, 1};
    in.submeshes = {{m, 0, 6}};
    auto id = w.meshes().create(in);
    REQUIRE(id.ok());
    Entity e = show(w, *id);
    CHECK(is_color(g.render(w).pixel(160, 90), 1, 0, 0));
    w.get<MeshRenderer>(e)->materialColors = Json::object({{"skin", Json::array({0.0, 1.0, 1.0, 1.0})}});
    CHECK(is_color(g.render(w).pixel(160, 90), 0, 1, 1));
}

TEST_CASE("procedural mesh: an update changes what is drawn and reuses the GPU buffers while the data fits") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    camera_at_z(w);
    auto id = w.meshes().create(quad_input(1.0f));
    REQUIRE(id.ok());
    show(w, *id);
    Image a = g.render(w);
    CHECK(a.pixel(160, 90).r > 0.8f);                  // the unlit white quad
    CHECK_FALSE(is_color(a.pixel(160 + 70, 90), 1, 1, 1, 0.05f));  // 70 px right of the middle is outside a quad of half 1
    const std::size_t bytes = mesh_entry(g, *id)["bytes"].get<std::size_t>();
    CHECK(bytes > 0);

    for (int frame = 0; frame < 4; ++frame) {  // a mesh deformed every frame
        MeshInput upd;
        upd.positions = quad_input(1.0f + 0.5f * float(frame + 1)).positions;
        REQUIRE(w.meshes().update(*id, upd).ok());
        Image img = g.render(w);
        const float half = 1.0f + 0.5f * float(frame + 1);
        const float edgePx = 90.0f * half / (4.0f * std::tan(radians(30.0f)));  // the vertical half-size on screen: height 180 px, fov 60
        CHECK(img.pixel(160, 90).r > 0.8f);
        CHECK(img.pixel(160, int(90 - edgePx * 0.5f)).r > 0.8f);
        CHECK(mesh_entry(g, *id)["version"].get<std::uint64_t>() == w.meshes().find(*id)->version);
        CHECK(mesh_entry(g, *id)["bytes"].get<std::size_t>() == bytes);  // same size: the same buffers
    }

    // More triangles than the buffers hold: new buffers, still right.
    MeshInput bigger = quad_input(1.0f);
    bigger.positions.insert(bigger.positions.end(), {-1, -1, 0.5f, 1, -1, 0.5f, 1, 1, 0.5f, -1, 1, 0.5f});
    bigger.indices = {0, 1, 2, 0, 2, 3, 4, 5, 6, 4, 6, 7};
    bigger.uvs.insert(bigger.uvs.end(), {0, 1, 1, 1, 1, 0, 0, 0});
    REQUIRE(w.meshes().update(*id, bigger).ok());
    Image img = g.render(w);
    CHECK(img.pixel(160, 90).r > 0.8f);
    CHECK(mesh_entry(g, *id)["triangles"] == 4);
}

TEST_CASE("procedural mesh: two updates in one GPU frame draw the latest data each time") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    camera_at_z(w);
    auto id = w.meshes().create(quad_input(1.0f));
    REQUIRE(id.ok());
    show(w, *id);
    (void)g.render(w);  // the first upload
    MeshInput upd;
    upd.positions = quad_input(1.0f, {-1.5f, 0, 0}).positions;
    REQUIRE(w.meshes().update(*id, upd).ok());
    g.renderer.begin_frame();
    g.renderer.render_world(w, 0.0f);
    upd.positions = quad_input(1.0f, {1.5f, 0, 0}).positions;
    REQUIRE(w.meshes().update(*id, upd).ok());
    g.renderer.render_world(w, 0.0f);  // the same sokol frame: new buffers, not a second staging write
    g.renderer.end_frame();
    g.gpu.end_frame();
    Image img;
    std::string err;
    REQUIRE(g.renderer.capture(img, &err));
    CHECK(img.pixel(160 + 60, 90).r > 0.8f);
    CHECK_FALSE(is_color(img.pixel(160 - 60, 90), 1, 1, 1, 0.05f));
}

TEST_CASE("procedural mesh: bounds follow the data, so culling sees a mesh that moves out of the view") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    camera_at_z(w);
    auto id = w.meshes().create(quad_input(0.5f, {0, 0, 0}));
    REQUIRE(id.ok());
    show(w, *id);
    (void)g.render(w);
    CHECK(g.renderer.stats().meshes == 1);
    MeshInput upd;
    upd.positions = quad_input(0.5f, {40, 0, 0}).positions;  // far to the right of a 60 degree view at distance 4
    REQUIRE(w.meshes().update(*id, upd).ok());
    (void)g.render(w);
    CHECK(g.renderer.stats().meshes == 0);
    upd.positions = quad_input(0.5f, {0, 0, 0}).positions;
    REQUIRE(w.meshes().update(*id, upd).ok());
    (void)g.render(w);
    CHECK(g.renderer.stats().meshes == 1);
}

TEST_CASE("procedural mesh: a destroyed mesh is released and draws the placeholder with a teaching failure") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    camera_at_z(w);
    auto id = w.meshes().create(quad_input(1.0f));
    REQUIRE(id.ok());
    show(w, *id);
    (void)g.render(w);
    REQUIRE(mesh_entry(g, *id).is_object());
    REQUIRE(w.meshes().destroy(*id).ok());
    Image img = g.render(w);
    CHECK(mesh_entry(g, *id).is_null());  // the GPU copy is gone
    CHECK(has_failure(g, *id));
    CHECK(g.renderer.stats().meshes == 1);  // the placeholder cube is drawn, so the mistake shows
    CHECK(img.pixel(160, 90).r > 0.1f);
    bool hint = false;
    const Json report = g.renderer.asset_report();
    for (const Json& f : report["failures"])
        if (f["path"] == *id) hint = f["message"].get<std::string>().find("does not exist") != std::string::npos;
    CHECK(hint);
}

TEST_CASE("procedural mesh: clearing the world releases the meshes, and another world never sees their GPU copies") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    std::string first;
    {
        World a;
        camera_at_z(a);
        auto id = a.meshes().create(quad_input(1.0f));
        REQUIRE(id.ok());
        first = *id;
        show(a, *id);
        Image img = g.render(a);
        CHECK(img.pixel(160, 90).r > 0.8f);
        REQUIRE(mesh_entry(g, first).is_object());
    }
    World b;  // its own store: "mesh:1" here is another mesh
    camera_at_z(b);
    MeshInput in = quad_input(1.0f);
    MeshMaterial red;
    red.color = Color{1, 0, 0, 1};
    in.submeshes = {{red, 0, 6}};
    auto id = b.meshes().create(in);
    REQUIRE(id.ok());
    CHECK(*id == "mesh:1");
    show(b, *id);
    CHECK(is_color(g.render(b).pixel(160, 90), 1, 0, 0));
    b.clear();
    camera_at_z(b);
    show(b, "cube");
    (void)g.render(b);
    CHECK(mesh_entry(g, *id).is_null());
}

TEST_CASE("procedural mesh: it casts a shadow like any mesh, unless castShadows is off") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    auto build = [&](World& w, bool cast) {
        Entity cam = make(w, "cam", {0, 8, 0});
        auto& c = w.add<Camera>(cam);
        c.projection = Projection::Perspective;
        c.fov = 50;
        w.get<Transform>(cam)->rotation = {-90, 0, 0};  // looking straight down, the top of the frame is -Z
        Entity ground = make(w, "ground", {0, 0, 0});
        w.get<Transform>(ground)->scale = {20, 1, 20};
        auto& gm = w.add<MeshRenderer>(ground);
        gm.mesh = "plane";
        gm.color = Color{0.8f, 0.8f, 0.8f, 1};
        Entity sun = make(w, "sun", {0, 5, 0});
        w.get<Transform>(sun)->rotation = {-45, 0, 0};  // the light travels towards -Z and down: shadows fall towards -Z
        auto& l = w.add<Light>(sun);
        l.type = LightType::Directional;
        l.castShadows = true;
        l.intensity = 1.0f;
        w.settings().ambientLight = Color{0.02f, 0.02f, 0.02f, 1};
        // A horizontal slab of 2 x 2 at height 2, double sided: its shadow is the 2 x 2 patch of ground around z = -2.
        MeshInput in;
        in.positions = {-1, 2, -1, 1, 2, -1, 1, 2, 1, -1, 2, 1};
        in.indices = {0, 2, 1, 0, 3, 2};
        in.hasIndices = true;
        MeshMaterial mat;
        mat.doubleSided = true;
        in.submeshes = {{mat, 0, 6}};
        auto id = w.meshes().create(in);
        REQUIRE(id.ok());
        Entity slab = make(w, "slab");
        auto& m = w.add<MeshRenderer>(slab);
        m.mesh = *id;
        m.castShadows = cast;
    };
    World noShadow, shadowed;
    build(noShadow, false);
    build(shadowed, true);
    const Image a = g.render(noShadow);
    const Image b = g.render(shadowed);
    // (160, 40) is ground the slab does not hide (the slab covers about y = 58..122): lit without the shadow, dark with it.
    const float lit = a.pixel(160, 40).r, dark = b.pixel(160, 40).r;
    INFO("lit " << lit << " dark " << dark);
    CHECK(lit > 0.3f);
    CHECK(dark < lit * 0.5f);
}
