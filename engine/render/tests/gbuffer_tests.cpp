// M79-P0c: the thin G-buffer (src/renderer_draw.cpp plan_prepass / gbuffer_pass, mesh_common.glsl gbuffer programs, docs/design/
// ARCHITECTURE_RENDERING_GBUFFER.md). Two RGBA8 images the renderer draws after the prepass only when something asks for them (the debug
// views albedo / material, DLSS Ray Reconstruction, the test hook force_gbuffer):
//   albedo   rgb = the albedo of the surface, a = 1 where a mesh was drawn
//   material r = roughness, g = metalness, b = 0, a = 1 where a mesh was drawn
// The tests read them through RendererTestAccess::read_gbuffer (a copy as floats, forced on with force_gbuffer):
//   - the plan: nothing asked -> no pass, no image and the same picture, bit for bit; asked -> the pass sits after the prepass;
//   - the values of two cubes of known materials, within the rounding of an 8-bit image; the sky stays at alpha 0;
//   - the debug views show the same images; a cutout (alphaMode clip) leaves its holes; a custom material writes the documented default.
// The tolerances are far above 8-bit rounding and far below the differences the cases make, so they hold on llvmpipe and WARP too.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <string>
#include <vector>

#include "fa/core/engine_version.h"

#include "frame_graph.h"
#include "postprocess.h"
#include "render_internal.h"
#include "renderer_test_access.h"

using namespace fa;
using namespace fa::test;
using namespace fa::render;

namespace {

constexpr int kW = 320, kH = 180;

struct Own {
    Gfx& g;
    Renderer r;
    bool ok = false;
    std::string error;
    explicit Own(Gfx& gx, bool gbuffer = true) : g(gx) {
        RendererDesc d;
        d.designWidth = kW;
        d.designHeight = kH;
        d.sampleCount = 1;
        d.headless = true;
        d.adoptContext = true;
        ok = r.init(d, g.gpu.environment(), &error);
        if (ok) RendererTestAccess::force_gbuffer(r, gbuffer);
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
    Image draw(World& w) {
        frame(w);
        Image img;
        std::string err;
        const bool captured = r.capture(img, &err);
        INFO("capture error: " << err);
        REQUIRE(captured);
        return img;
    }
};

struct GImage {
    std::vector<float> px;
    int w = 0, h = 0;
    const float* at(int x, int y) const { return &px[(std::size_t(y) * std::size_t(w) + std::size_t(x)) * 4]; }
};
GImage read(Own& o, int which) {
    GImage v;
    std::string err;
    const bool ok = RendererTestAccess::read_gbuffer(o.r, which, v.px, v.w, v.h, &err);
    INFO("read_gbuffer: " << err);
    REQUIRE(ok);
    REQUIRE(v.w == kW);
    REQUIRE(v.h == kH);
    REQUIRE(v.px.size() == std::size_t(kW) * std::size_t(kH) * 4);
    return v;
}

void add_camera(World& w, Vec3 pos) {
    Entity cam = make(w, "cam", pos);
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    c.clearColor = Color{0, 0, 0, 1};
    w.settings().skyColor = w.settings().horizonColor = Color{0, 0, 0, 1};
}
Entity add_cube(World& w, const char* name, Vec3 pos, Color color, float roughness, float metallic) {
    Entity e = make(w, name, pos);
    w.get<Transform>(e)->scale = {2, 2, 2};
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = "cube";
    m.color = color;
    m.roughness = roughness;
    m.metallic = metallic;
    return e;
}
// Two cubes side by side in front of a camera at (0, 0, 10): a white rough one on the left (pixel x 117), a red metal one on the right.
void two_cubes(World& w) {
    add_camera(w, {0, 0, 10});
    add_cube(w, "white", {-2.5f, 0, 0}, Color::white(), 0.3f, 0.0f);
    add_cube(w, "red", {2.5f, 0, 0}, Color{1, 0, 0, 1}, 0.8f, 1.0f);
}
constexpr int kLeftX = 117, kRightX = 203, kMidY = 90, kSkyX = 160;

// The place of the pass `name` of the camera's graph (the graph names them "camera:<n>/<name>"); -1 when there is none.
int index_of(const std::vector<std::string>& names, const std::string& name) {
    const std::string tail = "/" + name;
    for (std::size_t i = 0; i < names.size(); ++i)
        if (names[i].size() >= tail.size() && names[i].compare(names[i].size() - tail.size(), tail.size(), tail) == 0)
            return int(i);
    return -1;
}

bool near_f(float v, float want, float tol) { return std::fabs(v - want) <= tol; }

void install_gbuffer_materials() {
    namespace sfs = std::filesystem;
    const sfs::path src = sfs::path(FA_RENDER_DATA_DIR) / "materials";
    for (const auto& e : sfs::recursive_directory_iterator(src)) {
        if (!e.is_regular_file()) continue;
        std::ifstream in(e.path(), std::ios::binary);
        std::string bytes((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
        if (e.path().extension() == ".shader") {
            Json twin = Json::parse(bytes);
            twin["engine"] = FA_ENGINE_VERSION;
            bytes = twin.dump();
        }
        REQUIRE(fs::write_bytes(sfs::relative(e.path(), src).generic_string(), bytes.data(), bytes.size()).ok());
    }
}

int covered(const GImage& g) {
    int n = 0;
    for (int y = 0; y < g.h; ++y)
        for (int x = 0; x < g.w; ++x) n += g.at(x, y)[3] > 0.5f ? 1 : 0;
    return n;
}

}  // namespace

TEST_CASE(
    "gbuffer: nothing asks by default - the plan has no request, no image and the formats are the documented ones") {
    PostPlan plan;
    CHECK_FALSE(plan.needsGbuffer);
    CHECK_FALSE(plan.gbufferAlbedo.valid());
    CHECK_FALSE(plan.gbufferMaterial.valid());
    plan.request_gbuffer();
    CHECK(plan.needsGbuffer);
    const TargetFormat f = Gpu::gbuffer_target_format();
    CHECK(f.color == gpu::PixelFormat::Rgba8);
    CHECK(f.color1 == gpu::PixelFormat::Rgba8);
    CHECK(f.depth == gpu::PixelFormat::Depth);
    CHECK(Gpu::gbuffer_format() == gpu::PixelFormat::Rgba8);
}

TEST_CASE(
    "gbuffer: off - no pass in the frame graph and the same picture, bit for bit; on - the pass follows the prepass") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    two_cubes(w);
    Own off(g, false);
    REQUIRE(off.ok);
    const Image a = off.draw(w);
    CHECK(index_of(renderer_frame_graph(off.r)->order_names(), "gbuffer") < 0);
    std::vector<float> none;
    int rw = 0, rh = 0;
    CHECK_FALSE(RendererTestAccess::read_gbuffer(off.r, 0, none, rw, rh, nullptr));

    Own on(g, true);
    REQUIRE(on.ok);
    const Image b = on.draw(w);
    const std::vector<std::string> onOrder = renderer_frame_graph(on.r)->order_names();
    REQUIRE(index_of(onOrder, "gbuffer") >= 0);
    REQUIRE(index_of(onOrder, "prepass") >= 0);
    CHECK(index_of(onOrder, "gbuffer") > index_of(onOrder, "prepass"));
    // the images change nothing the picture shows
    REQUIRE(a.width == b.width);
    REQUIRE(a.height == b.height);
    CHECK(a.rgba == b.rgba);
}

TEST_CASE("gbuffer: two cubes of known materials read back as their albedo, roughness and metalness; the sky is not "
          "covered") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    two_cubes(w);
    Own o(g);
    REQUIRE(o.ok);
    o.frame(w);
    const GImage alb = read(o, 0), mat = read(o, 1);
    const float* wa = alb.at(kLeftX, kMidY);
    const float* wm = mat.at(kLeftX, kMidY);
    INFO("white cube albedo " << wa[0] << " " << wa[1] << " " << wa[2] << " " << wa[3] << ", material " << wm[0] << " "
                              << wm[1] << " " << wm[2] << " " << wm[3] << "; covered " << covered(alb));
    CHECK(near_f(wa[0], 1.0f, 0.02f));
    CHECK(near_f(wa[1], 1.0f, 0.02f));
    CHECK(near_f(wa[2], 1.0f, 0.02f));
    CHECK(near_f(wa[3], 1.0f, 0.01f));
    CHECK(near_f(wm[0], 0.3f, 0.02f));
    CHECK(near_f(wm[1], 0.0f, 0.02f));
    CHECK(near_f(wm[2], 0.0f, 0.01f));
    CHECK(near_f(wm[3], 1.0f, 0.01f));
    const float* ra = alb.at(kRightX, kMidY);
    const float* rm = mat.at(kRightX, kMidY);
    CHECK(near_f(ra[0], 1.0f, 0.02f));
    CHECK(near_f(ra[1], 0.0f, 0.02f));
    CHECK(near_f(ra[2], 0.0f, 0.02f));
    CHECK(near_f(ra[3], 1.0f, 0.01f));
    CHECK(near_f(rm[0], 0.8f, 0.02f));
    CHECK(near_f(rm[1], 1.0f, 0.02f));
    CHECK(near_f(rm[3], 1.0f, 0.01f));
    // the sky between the cubes: nothing was drawn
    const float* sa = alb.at(kSkyX, kMidY);
    const float* sm = mat.at(kSkyX, kMidY);
    CHECK(near_f(sa[3], 0.0f, 0.01f));
    CHECK(near_f(sm[3], 0.0f, 0.01f));
    // both cubes together cover a good part of the picture, and the two images cover the same pixels
    CHECK(covered(alb) > 1500);
    CHECK(covered(alb) == covered(mat));
}

TEST_CASE("gbuffer: the debug views albedo and material show the images") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    two_cubes(w);
    Own o(g, false);  // nothing forces it: the debug view is the request
    REQUIRE(o.ok);
    o.r.set_debug_view(DebugView::Albedo);
    const Image alb = o.draw(w);
    const Color wa = alb.pixel(kLeftX, kMidY), ra = alb.pixel(kRightX, kMidY), sa = alb.pixel(kSkyX, kMidY);
    CHECK(wa.r > 0.9f);
    CHECK(wa.g > 0.9f);
    CHECK(wa.b > 0.9f);
    CHECK(ra.r > 0.9f);
    CHECK(ra.g < 0.1f);
    CHECK(ra.b < 0.1f);
    CHECK(std::max({sa.r, sa.g, sa.b}) < 0.05f);
    o.r.set_debug_view(DebugView::Material);
    const Image mat = o.draw(w);
    const Color wm = mat.pixel(kLeftX, kMidY), rm = mat.pixel(kRightX, kMidY);
    CHECK(std::fabs(wm.r - 0.3f) < 0.06f);
    CHECK(wm.g < 0.06f);
    CHECK(std::fabs(rm.r - 0.8f) < 0.06f);
    CHECK(rm.g > 0.9f);
    o.r.set_debug_view(DebugView::None);
}

TEST_CASE("gbuffer: an alphaMode clip material leaves its holes in both images, and writes the mesh's own values") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    gfx().renderer.clear_asset_cache();
    install_gbuffer_materials();
    World plain, cut;
    for (World* w : {&plain, &cut}) {
        add_camera(*w, {0, 0, 4});
        Entity e = make(*w, "plane", {0, 0, 0});
        w->get<Transform>(e)->scale = {3, 1, 3};
        w->get<Transform>(e)->rotation = {90, 0, 0};  // faces the camera
        auto& m = w->add<MeshRenderer>(e);
        m.mesh = "plane";
        m.color = Color{1, 0, 0, 1};
        m.roughness = 0.6f;
        m.metallic = 0.0f;
        if (w == &cut) m.material = "materials/cutout.material.json";
    }
    Own o(g);
    REQUIRE(o.ok);
    o.frame(plain);
    const GImage fullAlb = read(o, 0);
    const int full = covered(fullAlb);
    o.frame(cut);
    const GImage alb = read(o, 0), mat = read(o, 1);
    const int holes = covered(alb);
    CHECK(full > 2000);
    CHECK(holes < full * 9 / 10);  // the checkerboard really cut holes
    CHECK(holes > full / 10);
    CHECK(covered(mat) == holes);
    // where it is drawn, the custom material has the documented default: the mesh's own values
    int checked = 0;
    for (int y = 0; y < kH; y += 5)
        for (int x = 0; x < kW; x += 5) {
            if (alb.at(x, y)[3] < 0.5f) continue;
            ++checked;
            CHECK(near_f(alb.at(x, y)[0], 1.0f, 0.03f));
            CHECK(near_f(alb.at(x, y)[1], 0.0f, 0.03f));
            CHECK(near_f(mat.at(x, y)[0], 0.6f, 0.03f));
            CHECK(near_f(mat.at(x, y)[1], 0.0f, 0.03f));
        }
    CHECK(checked > 20);
    gfx().renderer.set_shader_compiler({});
    gfx().renderer.clear_asset_cache();
}

TEST_CASE("gbuffer: a scene with no opaque mesh makes no G-buffer, the request is not an error") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    add_camera(w, {0, 0, 10});
    Own o(g);
    REQUIRE(o.ok);
    o.frame(w);
    CHECK(index_of(renderer_frame_graph(o.r)->order_names(), "gbuffer") < 0);
    std::vector<float> none;
    int rw = 0, rh = 0;
    CHECK_FALSE(RendererTestAccess::read_gbuffer(o.r, 0, none, rw, rh, nullptr));
}

TEST_CASE("gbuffer: the Ray Reconstruction guide programs, the albedo one that reads the G-buffer included, build on "
          "this GPU") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Own o(g, false);
    REQUIRE(o.ok);
    CHECK(RendererTestAccess::rr_guide_programs(o.r));
}
