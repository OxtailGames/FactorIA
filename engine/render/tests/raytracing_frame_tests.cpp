// M79-P0a: with ray tracing off (the default, and the only state this version has a use for) a frame adds nothing to the frame graph: no
// pass and no resource that has to do with rays, whatever render.rayTracing says. The renderer does not read the settings yet; this keeps
// the promise "free when off" checked from the first package, so a later package that adds a pass has to gate it.
#include "test_util.h"

#include <algorithm>
#include <string>
#include <vector>

#include "fa/render/raytracing.h"
#include "frame_graph.h"
#include "renderer_test_access.h"

using namespace fa;
using namespace fa::test;

namespace {

bool is_ray_tracing_name(const std::string& n) {
    for (const char* word : {"ray", "accel", "tlas", "blas", "rt-"})
        if (n.find(word) != std::string::npos) return true;
    return false;
}

}  // namespace

TEST_CASE("ray tracing: with the settings off a frame has no ray tracing pass or resource in its frame graph") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World world;
    Entity cam = make(world, "cam");
    world.add<Camera>(cam).clearColor = Color{0.1f, 0.1f, 0.2f, 1.0f};
    Entity box = make(world, "box");
    auto& s = world.add<Shape2D>(box);
    s.shape = ShapeType::Rectangle;
    s.size = {40, 20};
    s.color = Color::white();

    CHECK_FALSE(render::rt_any_effect(render::RayTracingSettings{}));
    g.render(world);
    const render::FrameGraph* graph = render::renderer_frame_graph(g.renderer);
    REQUIRE(graph != nullptr);
    const std::vector<std::string> before = graph->order_names();
    CHECK(before == std::vector<std::string>{"camera:0/game"});
    for (const std::string& n : before) CHECK_FALSE(is_ray_tracing_name(n));
    const Json j = graph->to_json();
    for (const Json& r : j["resources"]) CHECK_FALSE(is_ray_tracing_name(r["name"].get<std::string>()));

    // The same frame again: the same passes (nothing grows or appears from frame to frame).
    g.render(world);
    CHECK(graph->order_names() == before);
}
