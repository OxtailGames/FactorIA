// The renderer's passes of a frame run through the frame graph (engine/render/src/frame_graph.h): the order the graph
// compiles, the transients it takes from the pool, and the RGBA8 fall-back of the scene format.
#include "test_util.h"

#include <algorithm>
#include <cstdlib>
#include <string>
#include <vector>

#include "frame_graph.h"

using namespace fa;
using namespace fa::test;

namespace {

constexpr float kBloomDimmed = 0.02f;

// A camera, a bright additive rectangle (bloom) and a HUD of screen-space items.
struct BloomHudScene {
    World world;
    Entity cam;
    BloomHudScene() {
        cam = make(world, "cam");
        Camera& c = world.add<Camera>(cam);
        c.clearColor = Color{kBloomDimmed, kBloomDimmed, 0.04f, 1.0f};
        c.bloom = true;
        c.bloomThreshold = 0.5f;
        c.bloomIntensity = 1.0f;
        c.bloomRadius = 40.0f;  // a wide glow: the pyramid has downsample passes
        c.bloomScreenSpace = false;  // the HUD is drawn after the bloom: the "hud-over-bloom" pass
        Entity neon = make(world, "neon");
        auto& s = world.add<Shape2D>(neon);
        s.shape = ShapeType::Rectangle;
        s.size = {40, 20};
        s.color = Color{1.0f, 0.3f, 0.9f, 1.0f};
        s.blend = BlendMode::Additive;
        Entity box = make(world, "hud-box", {20, 10, 0});
        auto& b = world.add<Shape2D>(box);
        b.shape = ShapeType::Rectangle;
        b.size = {40, 20};
        b.color = Color::white();
        b.space = RenderSpace::Screen;
        b.pivot = {0, 1};
    }
    Camera& camera() { return *world.get<Camera>(cam); }
};

struct EnvGuard {
    std::string name, old;
    bool had = false;
    EnvGuard(const char* n, const char* value) : name(n) {
        if (const char* cur = std::getenv(n)) {
            had = true;
            old = cur;
        }
        set(value);
    }
    ~EnvGuard() { set(had ? old.c_str() : nullptr); }
    void set(const char* value) const {
#if defined(_WIN32)
        _putenv_s(name.c_str(), value ? value : "");  // an empty value removes the variable
#else
        if (value)
            setenv(name.c_str(), value, 1);
        else
            unsetenv(name.c_str());
#endif
    }
};

// A second renderer on the test GPU (the first one stays as it is).
struct OwnRenderer {
    Gfx& g;
    Renderer r;
    bool ok = false;
    std::string error;
    OwnRenderer(Gfx& gx, int samples) : g(gx) {
        RendererDesc d;
        d.designWidth = 320;
        d.designHeight = 180;
        d.sampleCount = samples;
        d.headless = true;
        d.adoptContext = true;
        ok = r.init(d, g.gpu.environment(), &error);
    }
    ~OwnRenderer() { r.shutdown(); }
    Image draw(World& w) {
        r.begin_frame();
        r.render_world(w, 0.0f);
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

bool starts_with(const std::string& s, const char* prefix) { return s.rfind(prefix, 0) == 0; }

int count_prefix(const std::vector<std::string>& names, const char* prefix) {
    int n = 0;
    for (const std::string& s : names)
        if (starts_with(s, prefix)) ++n;
    return n;
}

int index_of(const std::vector<std::string>& names, const std::string& name) {
    const auto it = std::find(names.begin(), names.end(), name);
    return it == names.end() ? -1 : int(it - names.begin());
}

// The order of a bloom frame: the world, the bloom stages one after another, then the HUD over the glow.
void check_bloom_hud_order(const std::vector<std::string>& order) {
    REQUIRE(order.size() >= 7);
    CHECK(order.front() == "game");
    CHECK(order.back() == "hud-over-bloom");
    const int bright = index_of(order, "bloom-bright"), h = index_of(order, "bloom-blur-h"),
              v = index_of(order, "bloom-blur-v"), comp = index_of(order, "bloom-composite");
    CHECK(bright == 1);
    CHECK(count_prefix(order, "bloom-down-") >= 1);
    CHECK(h > bright);
    CHECK(v == h + 1);
    CHECK(comp == v + 1);
    CHECK(comp + 1 == int(order.size()) - 1);
    for (std::size_t i = 2; i < std::size_t(h); ++i) CHECK(starts_with(order[i], "bloom-down-"));
}

int resource_count(const Json& graph, const char* kind) {
    int n = 0;
    for (const Json& r : graph["resources"])
        if (r["kind"].get<std::string>() == kind) ++n;
    return n;
}

}  // namespace

TEST_CASE("frame graph: a bloom frame with the HUD after the bloom compiles in the order it is drawn") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    BloomHudScene s;
    g.render(s.world);
    const render::FrameGraph* graph = render::renderer_frame_graph(g.renderer);
    REQUIRE(graph != nullptr);
    const std::vector<std::string> order = graph->order_names();
    check_bloom_hud_order(order);
    const Json j = graph->to_json();
    CHECK(j["culled"].empty());  // every pass writes the game image or feeds a pass that does
    CHECK(resource_count(j, "imported") == 1);
    CHECK(resource_count(j, "transient") >= 3);  // a level of the pyramid, its blur partner and the working level
}

TEST_CASE("frame graph: bloom with MSAA and the HUD after the bloom keeps the same passes") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const sg_pixelformat_info info = sg_query_pixelformat(SG_PIXELFORMAT_RGBA8);
    if (!info.msaa) return;  // no multisampling on this GPU
    OwnRenderer own(g, 4);
    REQUIRE_MESSAGE(own.ok, own.error);
    BloomHudScene s;
    own.draw(s.world);
    const render::FrameGraph* graph = render::renderer_frame_graph(own.r);
    REQUIRE(graph != nullptr);
    check_bloom_hud_order(graph->order_names());
    // The glow goes into the multisampled game image: the transients are single-sampled, the game image is not.
    const Json j = graph->to_json();
    for (const Json& r : j["resources"]) {
        if (r["kind"].get<std::string>() == "transient") CHECK(r["format"]["samples"].get<int>() == 1);
        else CHECK(r["format"]["samples"].get<int>() == 4);
    }
}

TEST_CASE("frame graph: with the bloom off or the HUD in the bloom there is no pass for them") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    BloomHudScene s;
    s.camera().bloom = false;
    g.render(s.world);
    const render::FrameGraph* graph = render::renderer_frame_graph(g.renderer);
    REQUIRE(graph != nullptr);
    CHECK(graph->order_names() == std::vector<std::string>{"game"});
    CHECK(resource_count(graph->to_json(), "transient") == 0);

    s.camera().bloom = true;
    s.camera().bloomScreenSpace = true;  // the HUD is in the picture the bloom reads
    g.render(s.world);
    const std::vector<std::string> order = graph->order_names();
    CHECK(order.front() == "game");
    CHECK(order.back() == "bloom-composite");
    CHECK(index_of(order, "hud-over-bloom") == -1);
}

TEST_CASE("frame graph: the colour filter is the last pass of the frame") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    BloomHudScene s;
    s.camera().colorFilter = ColorFilter::Greyscale;
    g.render(s.world);
    const render::FrameGraph* graph = render::renderer_frame_graph(g.renderer);
    REQUIRE(graph != nullptr);
    const std::vector<std::string> order = graph->order_names();
    CHECK(order.back() == "color-filter");
    CHECK(order[order.size() - 2] == "hud-over-bloom");
}

TEST_CASE("frame graph: the transients of the bloom come from the pool and do not grow from frame to frame") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    BloomHudScene s;
    g.render(s.world);  // the first frame creates them
    const render::TransientPoolStats first = render::renderer_transient_stats(g.renderer);
    CHECK(first.live > 0);
    CHECK(first.inUse == 0);  // all of them are back in the pool after the frame
    for (int i = 0; i < 3; ++i) {
        g.render(s.world);
        const render::TransientPoolStats now = render::renderer_transient_stats(g.renderer);
        CHECK(now.created == first.created);  // nothing new was made
        CHECK(now.live == first.live);
        CHECK(now.inUse == 0);
        CHECK(now.destroyed == first.destroyed);
    }
    const render::TransientPoolStats later = render::renderer_transient_stats(g.renderer);
    CHECK(later.reused > first.reused);
}

TEST_CASE("frame graph: the transients follow the RGBA8 fall-back of the scene format") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    EnvGuard hook("FA_SCENE_FORMAT", "rgba16f_invalid");
    OwnRenderer own(g, 1);
    REQUIRE_MESSAGE(own.ok, own.error);
    CHECK_FALSE(own.r.hdr_scene());
    BloomHudScene s;
    const Image img = own.draw(s.world);
    CHECK(img.pixel(160, 90).r > 0.5f);  // the rectangle and its glow are drawn
    const render::FrameGraph* graph = render::renderer_frame_graph(own.r);
    REQUIRE(graph != nullptr);
    check_bloom_hud_order(graph->order_names());
    const Json j = graph->to_json();
    Json gameFormat;
    for (const Json& r : j["resources"])
        if (r["name"].get<std::string>() == "game") gameFormat = r["format"];
    REQUIRE(gameFormat.is_object());
    int transients = 0;
    for (const Json& r : j["resources"]) {
        if (r["kind"].get<std::string>() != "transient") continue;
        ++transients;
        CHECK(r["format"]["color"] == gameFormat["color"]);  // the format the game image really has
    }
    CHECK(transients >= 3);
    // The same frames again make nothing new.
    const render::TransientPoolStats first = render::renderer_transient_stats(own.r);
    own.draw(s.world);
    own.draw(s.world);
    CHECK(render::renderer_transient_stats(own.r).created == first.created);
    CHECK(render::renderer_transient_stats(own.r).inUse == 0);
}
