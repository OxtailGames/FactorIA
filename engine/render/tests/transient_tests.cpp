// The per-frame vertex stream is written once into a write-transient buffer; sokol validates that no buffer is
// written after it was bound in the same frame (FB-0003). These tests render busy frames and fail on any sokol error.
#include "test_util.h"

#include <mutex>
#include <string>
#include <vector>

using namespace fa;
using namespace fa::test;

namespace {

struct SokolErrors {
    std::vector<std::string> errors;
    int id;
    SokolErrors() {
        id = add_log_sink([this](const LogEntry& e) {
            if (e.level >= LogLevel::Warn && e.category == "sg") errors.push_back(e.message);
        });
    }
    ~SokolErrors() { remove_log_sink(id); }
};

// A few hundred additive shapes, bloom with the HUD drawn after it (second pass), screen-space text.
void build_busy_scene(World& w) {
    Entity cam = make(w, "cam");
    auto& c = w.add<Camera>(cam);
    c.clearColor = Color{0.02f, 0.02f, 0.04f, 1.0f};
    c.bloom = true;
    c.bloomThreshold = 0.4f;
    c.bloomIntensity = 0.8f;
    c.bloomScreenSpace = false;
    for (int i = 0; i < 300; ++i) {
        Entity e = make(w, "s", {float(i % 20) * 14 - 130, float(i / 20) * 9 - 60, 0});
        auto& s = w.add<Shape2D>(e);
        s.shape = (i % 2) ? ShapeType::Circle : ShapeType::Rectangle;
        s.size = {8, 8};
        s.color = Color{1.0f, 0.4f, 0.8f, 0.6f};
        s.blend = BlendMode::Additive;
    }
    Entity hud = make(w, "hud", {6, 6, 0});
    auto& t = w.add<Text>(hud);
    t.text = "SCORE 1234";
    t.fontSize = 14;
    t.pivot = {0, 1};
    t.space = RenderSpace::Screen;
}

}  // namespace

TEST_CASE("render: many frames of a busy 2D scene log no sokol validation errors") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    build_busy_scene(w);
    SokolErrors log;
    for (int i = 0; i < 4; ++i) g.render(w);
    for (const std::string& m : log.errors) MESSAGE("sokol: " << m);
    CHECK(log.errors.empty());
}

TEST_CASE("render: two draws before one commit write the vertex stream to different buffers") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    build_busy_scene(w);
    SokolErrors log;
    // Engine::screenshot / render_now can draw again inside the same sokol frame (the editor commits once per UI frame).
    g.renderer.begin_frame();
    g.renderer.render_world(w, 0.0f);
    g.renderer.begin_frame();
    g.renderer.render_world(w, 0.0f);
    g.renderer.end_frame();
    g.gpu.end_frame();
    for (const std::string& m : log.errors) MESSAGE("sokol: " << m);
    CHECK(log.errors.empty());
}
