// M71-D1: ambient occlusion (src/renderer_ssao.cpp, shaders/ssao.glsl, PostProcess.ssao*). A white unlit floor and a wall that meet at
// a right angle: the floor next to the wall darkens, the open floor and the high wall do not; the passes and the sizes of their images
// follow the quality; off (or an intensity of 0) is the picture and the graph of a frame without the effect; each camera of a split
// screen darkens its own rectangle.
#include "fa/core/engine_version.h"
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <memory>
#include <string>
#include <vector>

#include "frame_graph.h"
#include "postprocess.h"
#include "postprocess_resolve.h"
#include "render_internal.h"

using namespace fa;
using namespace fa::test;

namespace {

void add_camera(World& w, const char* name, Vec3 pos, Rect viewport = Rect{0, 0, 1, 1}, int depth = 0) {
    Entity cam = make(w, name, pos);
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60.0f;
    c.viewport = viewport;
    c.depth = depth;
    c.clearColor = Color{0, 0, 0, 1};
    w.settings().skyColor = w.settings().horizonColor = Color{0, 0, 0, 1};
}
Entity add_mesh(World& w, const char* mesh, Vec3 pos, Vec3 scale) {
    Entity e = make(w, mesh, pos);
    w.get<Transform>(e)->scale = scale;
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = mesh;
    m.color = Color::white();
    m.unlit = true;  // the picture is the mesh's colour times the occlusion: nothing else changes a pixel
    return e;
}
// A camera at (0, 0, 10) looking down -Z; a floor at y = -2 and a wall whose front face is at z = -2.5 (the crease is at 12.5 m from the
// camera, on row 115 of a 320 x 180 picture; the floor 5 m from the camera is on row 152, the wall 5 m above the floor on row 55).
void floor_and_wall(World& w) {
    add_camera(w, "cam", {0, 0, 10});
    add_mesh(w, "plane", {0, -2, 0}, {40, 1, 40});
    add_mesh(w, "cube", {0, 3, -3}, {40, 10, 1});
}
PostProcess& add_ssao(World& w, const char* camera = "cam", float intensity = 2.2f, float radius = 1.0f,
                      SsaoQuality quality = SsaoQuality::Medium) {
    PostProcess& p = w.add<PostProcess>(w.find(camera));
    p.ssaoEnabled = true;
    p.ssaoIntensity = intensity;
    p.ssaoRadius = radius;
    p.ssaoQuality = quality;
    return p;
}

struct DebugViewScope {
    Renderer& r;
    DebugViewScope(Renderer& rr, DebugView v) : r(rr) { r.set_debug_view(v); }
    ~DebugViewScope() { r.set_debug_view(DebugView::None); }
    DebugViewScope(const DebugViewScope&) = delete;
    DebugViewScope& operator=(const DebugViewScope&) = delete;
};

std::vector<std::string> order_of(Renderer& r) {
    const render::FrameGraph* graph = render::renderer_frame_graph(r);
    REQUIRE(graph != nullptr);
    return graph->order_names();
}
int count_prefix_of(const std::vector<std::string>& names, const std::string& part) {
    int n = 0;
    for (const std::string& s : names)
        if (s.find(part) != std::string::npos) ++n;
    return n;
}
int index_of(const std::vector<std::string>& names, const std::string& name) {
    const auto it = std::find(names.begin(), names.end(), name);
    return it == names.end() ? -1 : int(it - names.begin());
}
std::string joined(const std::vector<std::string>& names) {
    std::string o;
    for (const std::string& s : names) o += s + " ";
    return o;
}
int c8(float v) { return int(std::lround(v * 255.0f)); }
int grey(const Image& img, int x, int y) {
    const Color c = img.pixel(x, y);
    return (c8(c.r) + c8(c.g) + c8(c.b)) / 3;
}
// The darkest grey of a column between two rows (the crease is a few rows wide, and where it is depends on the resolution).
int darkest(const Image& img, int x, int y0, int y1) {
    int d = 255;
    for (int y = y0; y <= y1; ++y) d = std::min(d, grey(img, x, y));
    return d;
}
// The largest difference of a channel between two pictures of the same size.
int max_diff(const Image& a, const Image& b, int x0 = 0, int y0 = 0, int x1 = 320, int y1 = 180) {
    int d = 0;
    for (int y = y0; y < y1; ++y)
        for (int x = x0; x < x1; ++x) {
            const Color p = a.pixel(x, y), q = b.pixel(x, y);
            d = std::max({d, std::abs(c8(p.r) - c8(q.r)), std::abs(c8(p.g) - c8(q.g)), std::abs(c8(p.b) - c8(q.b))});
        }
    return d;
}
// The size of a transient of the graph, by name; false when there is none.
bool resource_size(Renderer& r, const std::string& name, int& w, int& h) {
    const Json report = r.frame_graph_report();
    if (!report.is_object()) return false;
    const Json graph = report["graph"];
    for (std::size_t i = 0; i < graph["resources"].size(); ++i) {
        const Json res = graph["resources"][i];
        if (res["name"] == name) {
            w = int(res["width"].get<double>());
            h = int(res["height"].get<double>());
            return true;
        }
    }
    return false;
}

}  // namespace

TEST_CASE("ssao: the floor next to a wall darkens, the open floor and the high wall do not") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    floor_and_wall(w);
    const Image plain = g.draw(w);
    const std::vector<std::string> plainOrder = order_of(g.renderer);
    CHECK(count_prefix_of(plainOrder, "ssao") == 0);
    CHECK(count_prefix_of(plainOrder, "/prepass") == 0);  // nothing asked for the depth: not even the prepass
    CHECK(grey(plain, 160, 116) > 240);
    add_ssao(w);
    const Image img = g.draw(w);
    const std::vector<std::string> order = order_of(g.renderer);
    INFO(joined(order));
    REQUIRE(count_prefix_of(order, "ssao-ao") == 1);
    CHECK(count_prefix_of(order, "ssao-apply") ==
          0);  // the apply is a draw inside the main pass, not a pass of its own
    // The occlusion is made from the prepass BEFORE the main pass, which applies it after the opaque meshes.
    CHECK(index_of(order, "camera:0/prepass") < index_of(order, "camera:0/ssao-ao"));
    CHECK(index_of(order, "camera:0/ssao-ao") < index_of(order, "camera:0/ssao-blur-h"));
    CHECK(index_of(order, "camera:0/ssao-blur-h") < index_of(order, "camera:0/ssao-blur-v"));
    CHECK(index_of(order, "camera:0/ssao-blur-v") < index_of(order, "camera:0/game"));
    // The crease: the floor 0.1 to 0.5 m from the wall and the wall just above it.
    const int floorNear = grey(img, 160, 117), wallNear = grey(img, 160, 111);
    INFO("floor near the wall " << floorNear << ", wall near the floor " << wallNear);
    CHECK(floorNear < grey(plain, 160, 117) - 20);
    CHECK(wallNear < grey(plain, 160, 111) - 8);
    // Flat and open: nearly unchanged (a flat floor seen at a grazing angle keeps a few percent of the estimate's error, far less than
    // the crease), the high wall and the wall off the crease not at all.
    CHECK(std::abs(grey(img, 160, 152) - grey(plain, 160, 152)) <= 12);
    CHECK(std::abs(grey(img, 160, 170) - grey(plain, 160, 170)) <= 14);
    CHECK(std::abs(grey(img, 160, 55) - grey(plain, 160, 55)) <= 2);
    CHECK(std::abs(grey(img, 40, 55) - grey(plain, 40, 55)) <= 2);
    // The same scene draws the same picture again (no noise that depends on the frame).
    const Image again = g.draw(w);
    CHECK(max_diff(img, again) == 0);
    // The debug view paints the occlusion alone: dark in the crease, white on the open floor.
    {
        DebugViewScope view(g.renderer, DebugView::Ao);
        const Image ao = g.draw(w);
        INFO(joined(order_of(g.renderer)));
        CHECK(count_prefix_of(order_of(g.renderer), "ssao-ao") == 1);  // the view is drawn by the main pass too
        CHECK(count_prefix_of(order_of(g.renderer), "ssao-view") == 0);
        CHECK(count_prefix_of(order_of(g.renderer), "ssao-apply") == 0);
        CHECK(darkest(ao, 160, 108, 120) < 215);
        CHECK(grey(ao, 160, 152) > 243);
        CHECK(grey(ao, 160, 55) > 250);
    }
}

TEST_CASE("ssao: a stronger intensity and a wider radius darken more; intensity 0 and the switch off draw nothing") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    floor_and_wall(w);
    const Image plain = g.draw(w);
    PostProcess& p = add_ssao(w, "cam", 2.2f, 1.0f);
    const int base = grey(g.draw(w), 160, 117);
    p.ssaoIntensity = 4.0f;
    const int strong = grey(g.draw(w), 160, 117);
    CHECK(strong < base - 5);
    p.ssaoIntensity = 2.2f;
    p.ssaoRadius = 0.1f;  // only the floor within 0.1 m of the wall: the pixel at 0.5 m is out
    const int narrow = grey(g.draw(w), 160, 120);
    p.ssaoRadius = 2.0f;
    const int wide = grey(g.draw(w), 160, 120);
    INFO("narrow " << narrow << ", wide " << wide);
    CHECK(wide < narrow - 5);
    // Intensity 0, the effect off, and the radius 0: the picture and the graph of a frame without the effect.
    p.ssaoRadius = 0.5f;
    p.ssaoIntensity = 0.0f;
    Image off = g.draw(w);
    CHECK(max_diff(plain, off) == 0);
    CHECK(count_prefix_of(order_of(g.renderer), "ssao") == 0);
    CHECK(count_prefix_of(order_of(g.renderer), "/prepass") == 0);
    const int plainCalls = [&] {
        World w2;
        floor_and_wall(w2);
        g.draw(w2);
        return g.renderer.stats().drawCalls;
    }();
    g.draw(w);
    CHECK(g.renderer.stats().drawCalls == plainCalls);
    p.ssaoIntensity = 2.2f;
    p.ssaoRadius = 0.0f;
    off = g.draw(w);
    CHECK(max_diff(plain, off) == 0);
    CHECK(count_prefix_of(order_of(g.renderer), "ssao") == 0);
    p.ssaoRadius = 0.5f;
    p.ssaoEnabled = false;
    off = g.draw(w);
    CHECK(max_diff(plain, off) == 0);
    CHECK(count_prefix_of(order_of(g.renderer), "ssao") == 0);
    // And on again: the passes come back, four of them and one draw each.
    p.ssaoEnabled = true;
    g.draw(w);
    CHECK(g.renderer.stats().drawCalls == plainCalls + 2 /* prepass: one per opaque batch */ + 4);
}

TEST_CASE("ssao: the quality sets the size of the occlusion images (half at low and medium, full at high and ultra)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    floor_and_wall(w);
    PostProcess& p = add_ssao(w);
    struct Row {
        SsaoQuality q;
        int w, h;
    };
    for (const Row row : {Row{SsaoQuality::Low, 160, 90}, Row{SsaoQuality::Medium, 160, 90},
                          Row{SsaoQuality::High, 320, 180}, Row{SsaoQuality::Ultra, 320, 180}}) {
        p.ssaoQuality = row.q;
        const Image img = g.draw(w);
        int rw = 0, rh = 0;
        REQUIRE(resource_size(g.renderer, "camera:0/ssao-a", rw, rh));
        CHECK(rw == row.w);
        CHECK(rh == row.h);
        CHECK(darkest(img, 160, 108, 120) < 238);  // every level shows the crease
        CHECK(grey(img, 160, 152) >= 243);
    }
}

TEST_CASE("ssao: each camera of a split screen darkens its own rectangle, with images of its own size") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    add_camera(w, "cam", {0, 0, 10}, Rect{0, 0, 0.5f, 1}, 0);
    add_camera(w, "cam2", {0, 0, 10}, Rect{0.5f, 0, 0.5f, 1}, 1);
    add_mesh(w, "plane", {0, -2, 0}, {40, 1, 40});
    add_mesh(w, "cube", {0, 3, -3}, {40, 10, 1});
    const Image plain = g.draw(w);
    add_ssao(w, "cam");  // the left camera only
    const Image img = g.draw(w);
    const std::vector<std::string> order = order_of(g.renderer);
    INFO(joined(order));
    CHECK(count_prefix_of(order, "camera:0/ssao-ao") == 1);
    CHECK(count_prefix_of(order, "camera:1/ssao") == 0);
    int rw = 0, rh = 0;
    REQUIRE(resource_size(g.renderer, "camera:0/ssao-a", rw, rh));
    CHECK(rw == 80);  // half of the left camera's 160 x 180
    CHECK(rh == 90);
    CHECK(grey(img, 80, 117) < grey(plain, 80, 117) - 20);  // the crease of the left half
    CHECK(max_diff(img, plain, 160, 0, 320, 180) == 0);     // the right half is the picture without the effect
    CHECK(std::abs(grey(img, 80, 152) - grey(plain, 80, 152)) <= 12);
    // Both cameras: each half has its crease and its own images.
    add_ssao(w, "cam2");
    const Image both = g.draw(w);
    CHECK(count_prefix_of(order_of(g.renderer), "camera:1/ssao-ao") == 1);
    CHECK(grey(both, 240, 117) < grey(plain, 240, 117) - 20);
    CHECK(max_diff(both, img, 0, 0, 160, 180) == 0);  // the left half did not change
}

namespace {
// A renderer of its own with a sample count (the shared one has the one of FA_TEST_SAMPLES).
struct Own {
    Gfx& g;
    Renderer r;
    bool ok = false;
    std::string error;
    explicit Own(Gfx& gx, int samples) : g(gx) {
        RendererDesc d;
        d.designWidth = 320;
        d.designHeight = 180;
        d.sampleCount = samples;
        d.headless = true;
        d.adoptContext = true;
        ok = r.init(d, g.gpu.environment(), &error);
    }
    ~Own() { r.shutdown(); }
    Own(const Own&) = delete;
    Own& operator=(const Own&) = delete;
    Image draw(World& w) {
        r.begin_frame();
        r.render_world(w, 1.0f / 60.0f);
        r.end_frame();
        g.gpu.end_frame();
        Image img;
        std::string err;
        const bool captured = r.capture(img, &err);
        INFO("capture error: " << err);
        REQUIRE(captured);
        return img;
    }
};
}  // namespace

TEST_CASE(
    "ssao: what is drawn after the opaque meshes (a blended mesh, a sprite) is not darkened by the crease behind it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (const int samples : {1, 4}) {
        CAPTURE(samples);
        Own own(g, samples);
        REQUIRE_MESSAGE(own.ok, own.error);
        // A grey (0.8) blended cube (alpha 0.99) 4 m from the camera covers rows 70 .. 148 of the middle columns, the crease (row 115) in
        // it; with the occlusion drawn over it, as before, its grey would drop by the crease's darkening (see the first case: 20+ levels).
        auto scene = [&](bool ssao, bool sprite) {
            auto w = std::make_unique<World>();
            floor_and_wall(*w);
            if (!sprite) {
                Entity e = add_mesh(*w, "cube", {0, -0.5f, 5}, {2, 2, 2});
                w->get<MeshRenderer>(e)->color = Color{0.8f, 0.8f, 0.8f, 0.99f};
            } else {
                Entity e = make(*w, "spr", {0, -0.5f, 5});
                auto& sp = w->add<Sprite>(e);
                sp.size = {3, 3};
                sp.color = Color{0.8f, 0.8f, 0.8f, 1.0f};
            }
            if (ssao) add_ssao(*w);
            return w;
        };
        for (const bool sprite : {false, true}) {
            CAPTURE(sprite);
            auto without = scene(false, sprite);
            auto with = scene(true, sprite);
            const Image a = own.draw(*without);
            const Image b = own.draw(*with);
            INFO(joined(order_of(own.r)));
            // The crease is under the glass: its pixel is the glass's own grey, with or without the effect (to a level of rounding).
            CHECK(max_diff(a, b, 130, 100, 190, 135) <= 2);
            CHECK(grey(b, 160, 117) >= 200);
            // Outside the glass the crease is still darkened.
            CHECK(grey(b, 285, 117) < grey(a, 285, 117) - 20);
        }
    }
}

TEST_CASE("ssao: the settings are clamped, and a scene without an opaque mesh draws no occlusion") {
    render::PostStack stack;
    CHECK_FALSE(render::ssao_from_stack(stack).enabled);  // the effect is not in the stack
    stack.fx.ssaoEnabled = true;
    stack.mask = 1u << int(PostEffect::Ssao);
    stack.fx.ssaoIntensity = 100.0f;
    stack.fx.ssaoRadius = 1e9f;
    render::SsaoSettings s = render::ssao_from_stack(stack);
    CHECK(s.enabled);
    CHECK(s.intensity == 4.0f);
    CHECK(s.radius == 20.0f);
    stack.fx.ssaoIntensity = std::nanf("");
    stack.fx.ssaoRadius = std::nanf("");
    s = render::ssao_from_stack(stack);
    CHECK(s.enabled);  // a number that is not one falls back to the default
    CHECK(s.intensity == 1.0f);
    CHECK(s.radius == 0.5f);
    stack.fx.ssaoIntensity = 0.0f;
    CHECK_FALSE(render::ssao_from_stack(stack).enabled);
    stack.fx.ssaoIntensity = 1.0f;
    stack.fx.ssaoRadius = 0.0f;
    CHECK_FALSE(render::ssao_from_stack(stack).enabled);
    stack.fx.ssaoRadius = 0.5f;
    stack.fx.ssaoQuality = SsaoQuality::Ultra;
    CHECK(render::ssao_from_stack(stack).quality == 3);

    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    add_camera(w, "cam", {0, 0, 10});
    add_ssao(w);
    g.draw(w);
    CHECK(count_prefix_of(order_of(g.renderer), "ssao") == 0);  // nothing to read: no prepass, no occlusion
}
