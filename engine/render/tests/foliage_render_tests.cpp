// M75-P6a on a GPU: the Foliage component drawn by the mesh pipeline (src/renderer_foliage.h). The counts are units of instances, never
// times: what is drawn, what the chunk culling, the fade distance and the density leave out, the load of the file off the main thread,
// and a missing or damaged file. The CPU side (chunks, thinning, fade steps, sway) is in foliage_chunk_tests.cpp.
#include "test_util.h"

#include <cmath>
#include <filesystem>

#include "foliage_chunks.h"
#include "render_internal.h"
#include "renderer_foliage.h"
#include "renderer_test_access.h"
#include "fa/scene/foliage.h"

using namespace fa;
using namespace fa::test;

namespace {

std::string foliage_path(const char* name) { return fs::path_to_utf8(gfx().projectDir / fs::path_from_utf8(name)); }

void write_instances(const std::string& file, const std::vector<FoliageInstance>& in, std::uint32_t meshes = 1) {
    const auto r = write_foliage(file, in, meshes);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().message));
}

// A rows x cols block of instances `step` metres apart, centred on x = 0, its nearest row at z = zNear (going to -z).
std::vector<FoliageInstance> block(int cols, int rows, float step, float zNear, float scale = 0.6f) {
    std::vector<FoliageInstance> v;
    for (int j = 0; j < rows; ++j)
        for (int i = 0; i < cols; ++i) {
            FoliageInstance f;
            f.position = {(float(i) - float(cols - 1) * 0.5f) * step, 0.0f, zNear - float(j) * step};
            f.scale = scale;
            f.yaw = float(i + j) * 0.7f;
            v.push_back(f);
        }
    return v;
}

// A camera 2 m above the ground at the origin looking down -z (a 60 degree vertical field), a sun and an ambient light.
Entity add_camera(World& w) {
    Entity cam = make(w, "cam", {0, 2, 0});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    c.farPlane = 500.0f;
    w.settings().ambientLight = Color{0.35f, 0.35f, 0.35f, 1};
    return cam;
}

Entity add_sun(World& w, bool shadows) {
    Entity sun = make(w, "sun", {0, 50, 0});
    w.get<Transform>(sun)->rotation = {-55, 30, 0};
    auto& l = w.add<Light>(sun);
    l.type = LightType::Directional;
    l.intensity = 1.4f;
    l.castShadows = shadows;
    return sun;
}

Entity add_foliage(World& w, const std::string& file, Vec3 at = {0, 0, 0}) {
    Entity e = make(w, "forest", at);
    auto& f = w.add<Foliage>(e);
    f.instances = file;
    return e;
}

// One frame, with the file read waited for (the next frame adopts what the job made), so the stats are of the loaded foliage.
Image render_loaded(Gfx& g, World& w) {
    g.render(w);
    g.renderer.wait_foliage_loaded();
    return g.render(w);
}

// Pixels that are not exactly the same in the two pictures.
int differing(const Image& a, const Image& b) {
    int n = 0;
    for (int y = 0; y < a.height; ++y)
        for (int x = 0; x < a.width; ++x) {
            const Color p = a.pixel(x, y), q = b.pixel(x, y);
            if (p.r != q.r || p.g != q.g || p.b != q.b) ++n;
        }
    return n;
}

int pixels_unlike(const Image& img, Color sky, float tol = 0.04f) {
    int n = 0;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) {
            const Color p = img.pixel(x, y);
            if (std::max({std::fabs(p.r - sky.r), std::fabs(p.g - sky.g), std::fabs(p.b - sky.b)}) > tol) ++n;
        }
    return n;
}

}  // namespace

TEST_CASE("foliage: the instances are drawn instanced, counted as foliage and not as meshes") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    REQUIRE(g.renderer.supports("foliage"));
    const std::string file = foliage_path("foliage_basic.foliage");
    write_instances(file, block(10, 10, 2.0f, -16.0f));
    World w;
    add_camera(w);
    add_sun(w, false);
    add_foliage(w, file);
    const Image empty = [&] {
        World e;
        add_camera(e);
        add_sun(e, false);
        return g.render(e);
    }();
    const std::uint64_t loadsBefore = g.renderer.foliage_loads();
    const Image img = render_loaded(g, w);
    const RenderStats st = g.renderer.stats();
    CHECK(st.foliageInstances == 100);
    CHECK(st.foliageInstancesCulled == 0);
    CHECK(st.meshes == 0);  // the instances are not meshes of the scene
    CHECK(st.lodCrossFades == 0);
    CHECK(st.drawCalls < 12);  // one instanced draw per pass, not a hundred
    CHECK(st.triangles >= 100 * 12);
    CHECK(pixels_unlike(img, empty.pixel(1, 1)) > 200);
    CHECK(g.renderer.foliage_loads() == loadsBefore + 1);  // read once, not once per frame
    g.render(w);
    g.render(w);
    CHECK(g.renderer.foliage_loads() == loadsBefore + 1);
    CHECK(g.renderer.stats().foliageInstances == 100);
}

TEST_CASE("foliage: no Foliage in the world costs nothing: no counts, no file, no memory") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    add_camera(w);
    add_sun(w, false);
    Entity cube = make(w, "cube", {0, 0, -5});
    w.add<MeshRenderer>(cube).mesh = "cube";
    const std::uint64_t loads = g.renderer.foliage_loads();
    g.render(w);
    const RenderStats st = g.renderer.stats();
    CHECK(st.foliageInstances == 0);
    CHECK(st.foliageInstancesCulled == 0);
    CHECK(st.meshes == 1);
    CHECK(g.renderer.foliage_loads() == loads);
    CHECK_FALSE(g.renderer.foliage_loading());
}

TEST_CASE("foliage: chunks outside the view are culled whole and counted") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string file = foliage_path("foliage_cull.foliage");
    std::vector<FoliageInstance> in = block(6, 6, 2.0f, -8.0f);            // 36 in front of the camera
    const std::vector<FoliageInstance> behind = block(6, 6, 2.0f, 60.0f);  // 36 well behind it, in other chunks
    in.insert(in.end(), behind.begin(), behind.end());
    write_instances(file, in);
    World w;
    add_camera(w);
    add_sun(w, false);
    add_foliage(w, file);
    render_loaded(g, w);
    const RenderStats st = g.renderer.stats();
    CHECK(st.foliageInstances == 36);
    CHECK(st.foliageInstancesCulled == 36);
}

TEST_CASE("foliage: instances fade out between fadeStart and fadeEnd and are not drawn beyond it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string file = foliage_path("foliage_fade.foliage");
    std::vector<FoliageInstance> in;
    for (float z : {-10.0f, -20.0f, -45.0f, -55.0f, -65.0f, -75.0f}) {  // 4 each, at x = -3..3
        for (int i = 0; i < 4; ++i) {
            FoliageInstance f;
            f.position = {float(i) * 2.0f - 3.0f, 0.0f, z};
            f.scale = 1.0f;
            in.push_back(f);
        }
    }
    write_instances(file, in);
    World w;
    add_camera(w);
    add_sun(w, false);
    Entity e = add_foliage(w, file);
    auto& f = *w.get<Foliage>(e);
    f.fadeStart = 40.0f;
    f.fadeEnd = 60.0f;
    f.lodDistance = 1000.0f;
    render_loaded(g, w);
    RenderStats st = g.renderer.stats();
    // z = -10, -20 solid, -45 and -55 fading (distance 45 and 55), -65 and -75 beyond fadeEnd
    CHECK(st.foliageInstances == 16);
    CHECK(st.foliageInstancesCulled == 8);
    CHECK(st.lodCrossFades == 0);  // the fade is not a LOD cross-fade
    f.fadeEnd = 100.0f;
    g.render(w);
    st = g.renderer.stats();
    CHECK(st.foliageInstances == 24);
    CHECK(st.foliageInstancesCulled == 0);
}

TEST_CASE("foliage: density thins the instances evenly and always the same ones") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string file = foliage_path("foliage_density.foliage");
    const auto in = block(20, 20, 1.5f, -28.0f, 0.4f);
    write_instances(file, in);
    World w;
    add_camera(w);
    add_sun(w, false);
    Entity e = add_foliage(w, file);
    render_loaded(g, w);
    CHECK(g.renderer.stats().foliageInstances == 400);
    for (float density : {0.5f, 0.25f, 0.0f}) {
        CAPTURE(density);
        w.get<Foliage>(e)->density = density;
        int expect = 0;
        for (std::uint32_t i = 0; i < in.size(); ++i)
            expect += render::foliage_thin_rank(i) < render::foliage_keep_below(density) ? 1 : 0;
        const Image a = g.render(w);
        CHECK(g.renderer.stats().foliageInstances == expect);
        const Image b = g.render(w);
        CHECK(g.renderer.stats().foliageInstances == expect);
        CHECK(differing(a, b) == 0);  // the same instances every frame
    }
    w.get<Foliage>(e)->density = 0.5f;
    CHECK(g.render(w).width > 0);
    const int half = g.renderer.stats().foliageInstances;
    CHECK(half > 160);
    CHECK(half < 240);
}

TEST_CASE("foliage: the instances belong to the entity: moving it moves them, a rotated one still draws them") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string file = foliage_path("foliage_local.foliage");
    write_instances(file, block(5, 5, 2.0f, 0.0f));  // in front of the entity's origin: z 0 to -8
    World w;
    add_camera(w);
    add_sun(w, false);
    Entity e = add_foliage(w, file, {0, 0, -20});
    render_loaded(g, w);
    CHECK(g.renderer.stats().foliageInstances == 25);
    w.get<Transform>(e)->position = {0, 0, 80};  // behind the camera now
    g.render(w);
    CHECK(g.renderer.stats().foliageInstances == 0);
    CHECK(g.renderer.stats().foliageInstancesCulled == 25);
    w.get<Transform>(e)->position = {0, 0, -20};
    w.get<Transform>(e)->rotation = {0, 90, 0};
    g.render(w);
    CHECK(g.renderer.stats().foliageInstances == 25);
}

TEST_CASE("foliage: castShadows keeps the casters just outside the picture for the shadow maps") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string file = foliage_path("foliage_shadow.foliage");
    // 6 x 6 metres of instances to the left of the picture: out of the frustum, but near it
    std::vector<FoliageInstance> in = block(4, 4, 1.5f, -12.0f, 1.0f);
    for (FoliageInstance& f : in) f.position.x -= 22.0f;
    write_instances(file, in);
    World w;
    add_camera(w);
    add_sun(w, true);
    Entity e = add_foliage(w, file);
    w.get<Foliage>(e)->castShadows = true;
    render_loaded(g, w);
    RenderStats st = g.renderer.stats();
    CHECK(st.foliageInstances == 0);
    CHECK(st.foliageInstancesCulled == 16);
    CHECK(st.meshesCulled ==
          0);  // the instances kept for the shadows are counted in foliageInstancesCulled, not as culled meshes
    CHECK(st.shadowCasters > 0);
    w.get<Foliage>(e)->castShadows = false;
    g.render(w);
    st = g.renderer.stats();
    CHECK(st.shadowCasters == 0);
    CHECK(st.foliageInstances == 0);
}

TEST_CASE(
    "foliage: a missing file draws nothing and says so; the file appearing, or Foliage.instances changing, loads it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string file = foliage_path("foliage_late.foliage");
    std::error_code ec;
    std::filesystem::remove(fs::path_from_utf8(file), ec);
    World w;
    add_camera(w);
    add_sun(w, false);
    Entity e = add_foliage(w, file);
    render_loaded(g, w);
    CHECK(g.renderer.stats().foliageInstances == 0);
    const std::uint64_t loads = g.renderer.foliage_loads();
    for (int i = 0; i < 5; ++i) g.render(w);
    CHECK(g.renderer.foliage_loads() == loads);  // a failed read is not repeated every frame
    // pointing the component at another file loads it at once
    const std::string other = foliage_path("foliage_other.foliage");
    write_instances(other, block(3, 3, 2.0f, -6.0f));
    w.get<Foliage>(e)->instances = other;
    render_loaded(g, w);
    CHECK(g.renderer.stats().foliageInstances == 9);
    // a rewrite of the file (another size) is found within the polling interval and read again
    write_instances(other, block(4, 4, 2.0f, -6.0f));
    int frames = 0;
    while (g.renderer.stats().foliageInstances != 16 && frames < 90) {
        g.render(w);
        g.renderer.wait_foliage_loaded();
        ++frames;
    }
    CHECK(g.renderer.stats().foliageInstances == 16);
    CHECK(frames <= 70);
}

TEST_CASE("foliage: a damaged file or one for more meshes than Foliage.meshes draws nothing and does not crash") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    add_camera(w);
    add_sun(w, false);
    SUBCASE("garbage") {
        const std::string file = foliage_path("foliage_garbage.foliage");
        const std::string junk = "this is not a foliage file at all";
        REQUIRE(fs::write_bytes(file, junk.data(), junk.size()).ok());
        add_foliage(w, file);
        render_loaded(g, w);
        CHECK(g.renderer.stats().foliageInstances == 0);
        g.render(w);
        CHECK(g.renderer.stats().foliageInstances == 0);
    }
    SUBCASE("truncated") {
        const std::string file = foliage_path("foliage_cut.foliage");
        auto bytes = encode_foliage(block(3, 3, 2.0f, -6.0f), 1);
        REQUIRE(bytes.ok());
        REQUIRE(fs::write_bytes(file, bytes->data(), bytes->size() - 5).ok());
        add_foliage(w, file);
        render_loaded(g, w);
        CHECK(g.renderer.stats().foliageInstances == 0);
    }
    SUBCASE("a mesh index past the list") {
        const std::string file = foliage_path("foliage_meshes.foliage");
        std::vector<FoliageInstance> in = block(3, 3, 2.0f, -6.0f);
        in[4].mesh = 1;
        write_instances(file, in, 2);
        Entity e = add_foliage(w, file);  // Foliage.meshes has one entry
        render_loaded(g, w);
        CHECK(g.renderer.stats().foliageInstances == 0);
        w.get<Foliage>(e)->meshes = Json::array({"cube", "sphere"});  // now both are there: the file loads
        render_loaded(g, w);
        CHECK(g.renderer.stats().foliageInstances == 9);
    }
}

TEST_CASE("foliage: two meshes in one file are drawn as two instanced batches") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string file = foliage_path("foliage_two.foliage");
    std::vector<FoliageInstance> in = block(6, 4, 2.0f, -6.0f);
    for (std::size_t i = 0; i < in.size(); ++i) in[i].mesh = std::uint16_t(i % 2);
    write_instances(file, in, 2);
    World w;
    add_camera(w);
    add_sun(w, false);
    Entity e = add_foliage(w, file);
    w.get<Foliage>(e)->meshes = Json::array({"cube", "sphere"});
    render_loaded(g, w);
    const RenderStats st = g.renderer.stats();
    CHECK(st.foliageInstances == 24);
    CHECK(st.meshBatches >= 2);
    CHECK(st.meshBatches <= 4);
}

TEST_CASE("foliage: a wind moves the tops of the instances, and only then") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string file = foliage_path("foliage_wind.foliage");
    write_instances(file, block(8, 4, 1.5f, -5.0f, 1.0f));
    World w;
    add_camera(w);
    add_sun(w, false);
    Entity e = add_foliage(w, file);
    render_loaded(g, w);
    const Image calm = g.render(w);
    CHECK(differing(calm, g.render(w)) == 0);  // no wind: a frame is a frame
    w.get<Foliage>(e)->windStrength = 0.6f;
    w.get<Foliage>(e)->windFrequency = 1.0f;
    const Image windy = g.render(w);
    CHECK(differing(calm, windy) > 0);
    CHECK(g.renderer.stats().foliageInstances == 32);
}

namespace {

// What gather() takes of `world` for a camera at the origin whose clip volume holds everything within a kilometre (so no instance is
// culled by the view): no draw, so the cap can be tested at its real size without drawing a quarter of a million cubes.
struct Gathered {
    render::FoliageRenderer::Counts counts;
    std::vector<render::MeshItem> items;
};

Gathered gather_all(render::FoliageRenderer& fr, render::Assets& assets, World& world, std::uint64_t serial,
                    std::size_t maxItems = render::kFoliageMaxItems) {
    render::FoliageRenderer::View v;
    v.world = &world;
    v.assets = &assets;
    v.viewProj = Mat4::scale({0.001f, 0.001f, 0.001f});
    v.camera = {0, 0, 0};
    v.serial = serial;
    v.maxItems = maxItems;
    Gathered out;
    std::vector<char> blended;
    out.counts = fr.gather(v, out.items, blended);
    CHECK(blended.size() == out.items.size());
    return out;
}

void set_foliage(World& w, Entity e, const std::string& file, float fadeEnd = 1000.0f) {
    auto& f = w.add<Foliage>(e);
    f.instances = file;
    f.meshes = Json::array({"cube"});
    f.fadeStart = fadeEnd - 100.0f;
    f.fadeEnd = fadeEnd;
}

}  // namespace

TEST_CASE("foliage: a camera takes at most 262144 instances, whole nearest chunks first, and counts "
          "the rest as culled") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string file = foliage_path("foliage_cap.foliage");
    write_instances(file, block(600, 600, 0.5f, -10.0f));  // 360000 instances, 4096 to a chunk
    World w;
    set_foliage(w, make(w, "forest"), file);
    render::FoliageRenderer fr;
    render::Assets assets(*render::renderer_gpu(g.renderer));
    gather_all(fr, assets, w, 1);
    fr.wait_loaded();
    const Gathered r = gather_all(fr, assets, w, 2);
    REQUIRE(r.counts.entities == 1);
    CHECK(r.items.size() == std::size_t(r.counts.items));
    CHECK(r.items.size() <= render::kFoliageMaxItems);
    CHECK(r.items.size() + 4096 * 2 >
          render::kFoliageMaxItems);                    // whole chunks only: less than two chunks short of the cap
    CHECK(r.counts.items + r.counts.culled == 360000);  // nothing is lost from the count
    // the nearest are the ones kept: the mean distance of the kept ones is well below the mean of the whole field (about 200 m)
    double sum = 0.0;
    for (const render::MeshItem& mi : r.items) sum += double(mi.dist);
    CHECK(sum / double(r.items.size()) < 170.0);
}

TEST_CASE("foliage: the cap of items is shared by every Foliage entity, the nearest chunks win") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string nearFile = foliage_path("foliage_cap_near.foliage"),
                      farFile = foliage_path("foliage_cap_far.foliage");
    write_instances(nearFile, block(8, 8, 1.0f, -10.0f));  // 64 instances in one chunk, 10 m away
    write_instances(farFile, block(8, 8, 1.0f, -80.0f));   // 64 instances in one chunk, 80 m away
    World w;
    // the far entity comes FIRST in the world: it must not take the budget before the near one
    set_foliage(w, make(w, "far"), farFile);
    set_foliage(w, make(w, "near"), nearFile);
    render::FoliageRenderer fr;
    render::Assets assets(*render::renderer_gpu(g.renderer));
    gather_all(fr, assets, w, 1);
    fr.wait_loaded();
    const Gathered r = gather_all(fr, assets, w, 2, 64);
    CHECK(r.counts.items == 64);
    CHECK(r.counts.culled == 64);
    for (const render::MeshItem& mi : r.items) CHECK(mi.dist < 40.0f);
}

TEST_CASE("foliage: two worlds with the same entity numbers each keep their own instances, nothing is read again every "
          "frame") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string fileA = foliage_path("foliage_wa.foliage"), fileB = foliage_path("foliage_wb.foliage");
    write_instances(fileA, block(3, 3, 1.0f, -10.0f));
    write_instances(fileB, block(5, 5, 1.0f, -10.0f));
    World a, b;
    set_foliage(a, make(a, "forest"), fileA);
    set_foliage(b, make(b, "forest"), fileB);  // the same entity number as in a
    render::FoliageRenderer fr;
    render::Assets assets(*render::renderer_gpu(g.renderer));
    for (std::uint64_t i = 1; i <= 2; ++i) {
        gather_all(fr, assets, a, i);
        gather_all(fr, assets, b, i);
        fr.wait_loaded();
    }
    const std::uint64_t loads = fr.loads();
    for (std::uint64_t i = 3; i < 12; ++i) {
        CHECK(gather_all(fr, assets, a, i).counts.items == 9);
        CHECK(gather_all(fr, assets, b, i).counts.items == 25);
    }
    CHECK(fr.loads() == loads);
    CHECK(fr.size() == 2);
}

TEST_CASE(
    "foliage: fields changed at run time that stop it drawing are reported once, and drawing starts again when fixed") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string file = foliage_path("foliage_fields.foliage");
    write_instances(file, block(3, 3, 1.0f, -10.0f));
    World w;
    Entity e = make(w, "forest");
    set_foliage(w, e, file);
    render::FoliageRenderer fr;
    render::Assets assets(*render::renderer_gpu(g.renderer));
    gather_all(fr, assets, w, 1);
    fr.wait_loaded();
    CHECK(gather_all(fr, assets, w, 2).counts.items == 9);
    auto* f = w.get<Foliage>(e);
    f->fadeEnd = f->fadeStart;  // not above fadeStart
    CHECK(gather_all(fr, assets, w, 3).counts.items == 0);
    f->fadeEnd = f->fadeStart + 100.0f;
    f->meshes = Json::array({"cube", 3});  // not a name
    CHECK(gather_all(fr, assets, w, 4).counts.items == 0);
    f->meshes = Json::array({"cube"});
    CHECK(gather_all(fr, assets, w, 5).counts.items == 9);
}
