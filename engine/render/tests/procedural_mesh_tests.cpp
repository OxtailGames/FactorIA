// Procedural meshes ("mesh:N" ids of MeshRenderer.mesh, fa/scene/mesh_store.h) on whatever GPU backend the machine has:
// the upload, the submesh materials, updates that reuse the buffers, bounds and culling, shadows, and the release of a
// mesh that was destroyed or whose scene was cleared.
#include "test_util.h"

#include <cmath>
#include <cstring>
#include <filesystem>
#include <fstream>

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

// ---------------------------------------------------------------------------------------------------- vertex colors

namespace {

// quad_input(half) with one rgba color per vertex (the corners are bottom-left, bottom-right, top-right, top-left).
MeshInput colored_quad(float half, const std::vector<Color>& corners) {
    MeshInput in = quad_input(half);
    for (const Color& c : corners) in.colors.insert(in.colors.end(), {c.r, c.g, c.b, c.a});
    return in;
}

Image draw_quad(Gfx& g, const MeshInput& in, const MeshMaterial* material = nullptr, bool unlit = true) {
    World w;
    camera_at_z(w);
    MeshInput withMaterial = in;
    if (material) withMaterial.submeshes = {{*material, 0, 6}};
    auto id = w.meshes().create(withMaterial);
    REQUIRE(id.ok());
    Entity e = show(w, *id);
    w.get<MeshRenderer>(e)->unlit = unlit;
    return g.render(w);
}

}  // namespace

TEST_CASE("procedural mesh vertex colors: they tint the mesh and blend between vertices, as glTF COLOR_0") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Color red{1, 0, 0, 1}, blue{0, 0, 1, 1};
    // The left corners red, the right ones blue: the quad (about x 102..218 on screen) goes from red to blue.
    Image img = draw_quad(g, colored_quad(1.5f, {red, blue, blue, red}));
    CHECK(is_color(img.pixel(106, 90), 0.95f, 0, 0.05f));
    CHECK(is_color(img.pixel(214, 90), 0.05f, 0, 0.95f));
    CHECK(is_color(img.pixel(160, 90), 0.5f, 0, 0.5f));
    CHECK(is_color(img.pixel(160, 40), 0.5f, 0, 0.5f));  // a column is one color: only x changes it
}

TEST_CASE("procedural mesh vertex colors: they multiply the material's base color and the entity color") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MeshMaterial m;
    m.name = "tinted";
    m.color = Color{0.5f, 1, 1, 1};
    const Color c{1, 0.5f, 1, 1};
    CHECK(is_color(draw_quad(g, colored_quad(1.5f, {c, c, c, c}), &m).pixel(160, 90), 0.5f, 0.5f, 1));
    // Three numbers per vertex (rgb) mean an alpha of 1: same picture.
    MeshInput rgb = quad_input(1.5f);
    for (int i = 0; i < 4; ++i) rgb.colors.insert(rgb.colors.end(), {1, 0.5f, 1});
    CHECK(is_color(draw_quad(g, rgb, &m).pixel(160, 90), 0.5f, 0.5f, 1));
    // MeshRenderer.color multiplies on top.
    World w;
    camera_at_z(w);
    MeshInput in = colored_quad(1.5f, {c, c, c, c});
    in.submeshes = {{m, 0, 6}};
    auto id = w.meshes().create(in);
    REQUIRE(id.ok());
    Entity e = show(w, *id);
    w.get<MeshRenderer>(e)->color = Color{1, 1, 0.5f, 1};
    CHECK(is_color(g.render(w).pixel(160, 90), 0.5f, 0.5f, 0.5f));
}

TEST_CASE("procedural mesh vertex colors: a mesh without colors, or with white ones, draws exactly the same") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Color white{1, 1, 1, 1};
    const Image plain = draw_quad(g, quad_input(1.5f), nullptr, false);
    const Image whites = draw_quad(g, colored_quad(1.5f, {white, white, white, white}), nullptr, false);
    CHECK(diff_images(plain, whites, 0.0f).differingPixels == 0);
}

TEST_CASE("procedural mesh vertex colors: lit surfaces take them too") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Color red{1, 0.1f, 0.1f, 1};
    auto lit = [&](const MeshInput& in) {
        World w;
        camera_at_z(w);
        w.settings().ambientLight = Color{0.2f, 0.2f, 0.2f, 1};
        Entity sun = make(w, "sun", {0, 5, 0});  // no rotation: the light travels towards -Z, onto the front of the quad
        auto& l = w.add<Light>(sun);
        l.type = LightType::Directional;
        l.intensity = 1.0f;
        auto id = w.meshes().create(in);
        REQUIRE(id.ok());
        Entity e = show(w, *id);
        w.get<MeshRenderer>(e)->unlit = false;
        w.get<MeshRenderer>(e)->roughness = 1.0f;
        return g.render(w).pixel(160, 90);
    };
    const Color white = lit(quad_input(1.5f)), tinted = lit(colored_quad(1.5f, {red, red, red, red}));
    INFO("white " << white.r << " " << white.g << " " << white.b << " tinted " << tinted.r << " " << tinted.g << " " << tinted.b);
    CHECK(white.r > 0.2f);
    CHECK(std::fabs(white.r - white.b) < 0.05f);   // a white surface: grey
    CHECK(tinted.r > 0.2f);
    CHECK(tinted.g < tinted.r * 0.3f);
    CHECK(tinted.b < tinted.r * 0.3f);
}

TEST_CASE("procedural mesh vertex colors: the alpha shows with a blended material and not with an opaque one") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const Color half{0, 0, 1, 0.5f};
    MeshMaterial blend, opaque;
    blend.name = "glass";
    blend.blend = true;
    opaque.name = "solid";
    const MeshInput in = colored_quad(1.5f, {half, half, half, half});
    const Image glass = draw_quad(g, in, &blend);
    const Color behind = glass.pixel(10, 90);  // the sky, beside the quad
    CHECK(is_color(glass.pixel(160, 90), behind.r * 0.5f, behind.g * 0.5f, 0.5f + behind.b * 0.5f));
    CHECK(is_color(draw_quad(g, in, &opaque).pixel(160, 90), 0, 0, 1));
}

TEST_CASE("procedural mesh vertex colors: update changes them, leaving them out keeps them, and a bigger mesh keeps working") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    camera_at_z(w);
    const Color red{1, 0, 0, 1}, green{0, 1, 0, 1};
    auto id = w.meshes().create(colored_quad(1.5f, {red, red, red, red}));
    REQUIRE(id.ok());
    show(w, *id);
    CHECK(is_color(g.render(w).pixel(160, 90), 1, 0, 0));
    MeshInput upd;
    upd.positions = quad_input(1.2f).positions;  // geometry only: the colors stay
    REQUIRE(w.meshes().update(*id, upd).ok());
    CHECK(is_color(g.render(w).pixel(160, 90), 1, 0, 0));
    upd = MeshInput();
    for (int i = 0; i < 4; ++i) upd.colors.insert(upd.colors.end(), {green.r, green.g, green.b, 1.0f});
    REQUIRE(w.meshes().update(*id, upd).ok());
    CHECK(is_color(g.render(w).pixel(160, 90), 0, 1, 0));
    // A mesh made without colors that gets some later.
    auto plain = w.meshes().create(quad_input(1.0f));
    REQUIRE(plain.ok());
    w.get<MeshRenderer>(w.find("shape"))->mesh = *plain;
    CHECK(is_color(g.render(w).pixel(160, 90), 1, 1, 1));
    upd = MeshInput();
    for (int i = 0; i < 4; ++i) upd.colors.insert(upd.colors.end(), {0, 0, 1});
    REQUIRE(w.meshes().update(*plain, upd).ok());
    CHECK(is_color(g.render(w).pixel(160, 90), 0, 0, 1));
}

TEST_CASE("procedural mesh vertex colors: entities sharing a mesh are one instanced batch and each keeps the mesh's colors") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    camera_at_z(w, 8.0f);
    const Color c{1, 0.2f, 0.2f, 1};
    auto id = w.meshes().create(colored_quad(1.0f, {c, c, c, c}));
    REQUIRE(id.ok());
    show(w, *id, {-1.5f, 0, 0});
    show(w, *id, {1.5f, 0, 0});
    Image img = g.render(w);
    CHECK(g.renderer.stats().meshBatches >= 1);
    CHECK(g.renderer.stats().drawCalls < 4);
    CHECK(is_color(img.pixel(160 - 29, 90), 1, 0.2f, 0.2f));  // camera 8 away: 1 px is 0.051 m, the quads are centred 1.5 m aside
    CHECK(is_color(img.pixel(160 + 29, 90), 1, 0.2f, 0.2f));
}

namespace {

std::string base64_of(const std::vector<std::uint8_t>& d) {
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

TEST_CASE("vertex colors: a glTF model with COLOR_0 is drawn with it (normalized bytes and floats)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // One quad (-1.5..1.5, facing +Z): positions, then the colors as 4 normalized bytes each (red left, blue right) and the indices.
    std::vector<float> pos = {-1.5f, -1.5f, 0, 1.5f, -1.5f, 0, 1.5f, 1.5f, 0, -1.5f, 1.5f, 0};
    const std::uint8_t cols[16] = {255, 0, 0, 255, 0, 0, 255, 255, 0, 0, 255, 255, 255, 0, 0, 255};
    const std::uint16_t ix[6] = {0, 1, 2, 0, 2, 3};
    std::vector<std::uint8_t> bytes(48 + 16 + 12);
    std::memcpy(bytes.data(), pos.data(), 48);
    std::memcpy(bytes.data() + 48, cols, 16);
    std::memcpy(bytes.data() + 64, ix, 12);
    // The float variant: COLOR_0 as VEC3 floats (0.5, 1, 0.5) for every vertex.
    std::vector<std::uint8_t> bytes2 = bytes;
    const float fcol[12] = {0.5f, 1, 0.5f, 0.5f, 1, 0.5f, 0.5f, 1, 0.5f, 0.5f, 1, 0.5f};
    bytes2.resize(bytes.size() + 48);
    std::memcpy(bytes2.data() + 76, fcol, 48);
    auto write = [&](const char* name, const std::vector<std::uint8_t>& data, const std::string& colorAccessor) {
        const std::string uri = "data:application/octet-stream;base64," + base64_of(data);
        const Json gltf = Json::parse(R"({"asset":{"version":"2.0"},"scene":0,"scenes":[{"nodes":[0]}],"nodes":[{"mesh":0}],
            "meshes":[{"primitives":[{"attributes":{"POSITION":0,"COLOR_0":1},"indices":2}]}],
            "buffers":[{"byteLength":)" + std::to_string(data.size()) + R"(,"uri":")" + uri + R"("}],
            "bufferViews":[{"buffer":0,"byteOffset":0,"byteLength":48},{"buffer":0,"byteOffset":48,"byteLength":16},
                           {"buffer":0,"byteOffset":64,"byteLength":12},{"buffer":0,"byteOffset":76,"byteLength":48}],
            "accessors":[{"bufferView":0,"componentType":5126,"count":4,"type":"VEC3","min":[-1.5,-1.5,0],"max":[1.5,1.5,0]},
                         )" + colorAccessor + R"(,
                         {"bufferView":2,"componentType":5123,"count":6,"type":"SCALAR"}]})");
        std::filesystem::create_directories(g.projectDir / "assets");
        std::ofstream(g.projectDir / name, std::ios::binary) << gltf.dump();
    };
    write("assets/vc_bytes.gltf", bytes, R"({"bufferView":1,"componentType":5121,"normalized":true,"count":4,"type":"VEC4"})");
    write("assets/vc_floats.gltf", bytes2, R"({"bufferView":3,"componentType":5126,"count":4,"type":"VEC3"})");
    auto draw = [&](const char* path) {
        World w;
        camera_at_z(w);
        Entity e = show(w, path);
        (void)e;
        return g.render(w);
    };
    Image a = draw("assets/vc_bytes.gltf");
    CHECK(is_color(a.pixel(106, 90), 0.95f, 0, 0.05f));
    CHECK(is_color(a.pixel(214, 90), 0.05f, 0, 0.95f));
    Image b = draw("assets/vc_floats.gltf");
    CHECK(is_color(b.pixel(160, 90), 0.5f, 1, 0.5f));
}
