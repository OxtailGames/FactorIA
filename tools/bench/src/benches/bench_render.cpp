// Render benchmarks: a frame of the headless renderer (the gather of the draw items, the batching and the submit), 2D and 3D.
// They need a graphics context (EGL with Mesa on Linux, Metal on a Mac, D3D11 on Windows) and are skipped, with the reason, when
// there is none. The window is small (640x360) so the GPU's own work stays far below the CPU's.
#include <cmath>
#include <filesystem>
#include <memory>
#include <string>

#include "benches.h"
#include "fa/core/fs.h"
#include "fa/core/math.h"
#include "fa/platform/app.h"
#include "fa/render/renderer.h"
#include "fa/scene/components.h"
#include "fa/scene/world.h"

namespace fa::bench {

namespace {

struct RenderEnv {
    HeadlessGpu gpu;
    Renderer renderer;
    std::filesystem::path dir;
    bool ok = false;
    std::string error;
    bool gpuUp = false;

    RenderEnv() {
        auto made = fs::make_temp_dir("fa_bench_render");
        if (!made.ok()) {
            error = made.error().message;
            return;
        }
        dir = made.value();
        std::filesystem::create_directories(dir / "assets");
        fs::set_project_root(dir);
        if (!gpu.init(&error)) {
            error = "no GPU: " + error;
            return;
        }
        gpuUp = true;
        RendererDesc d;
        d.designWidth = 640;
        d.designHeight = 360;
        d.headless = true;
        ok = renderer.init(d, gpu.environment(), &error);
        if (!ok && error.empty()) error = "renderer init failed";
    }
    ~RenderEnv() {
        if (ok) renderer.shutdown();
        if (gpuUp) gpu.shutdown();
        std::error_code ec;
        if (!dir.empty()) std::filesystem::remove_all(dir, ec);
    }
    double frame(World& world) {
        renderer.begin_frame();
        renderer.render_world(world, 0.0f);
        renderer.end_frame();
        gpu.end_frame();
        const RenderStats s = renderer.stats();
        return double(s.drawCalls) * 1000.0 + double(s.sprites) + double(s.meshes) * 7.0 + double(s.triangles) * 0.001;
    }
};

std::unique_ptr<RenderEnv>& env_slot() {
    static std::unique_ptr<RenderEnv> slot;
    return slot;
}
RenderEnv& env() {
    auto& slot = env_slot();
    if (!slot) slot = std::make_unique<RenderEnv>();
    fs::set_project_root(slot->dir);
    return *slot;
}

Entity make(World& w, Vec3 pos) {
    Entity e = w.create();
    w.get<Transform>(e)->position = pos;
    return e;
}

void build_2d(World& w) {
    Entity cam = make(w, {0, 0, 0});
    w.add<Camera>(cam);
    Rng rng(31);
    // 5000 solid sprites in a grid that fills the view, on 8 layers, a third of them tinted and a few rotated.
    for (int row = 0; row < 50; ++row) {
        for (int col = 0; col < 100; ++col) {
            Entity e = make(w, {-316.0f + float(col) * 6.4f, -158.0f + float(row) * 6.4f, 0});
            Sprite& s = w.add<Sprite>(e);
            s.size = {6, 6};
            s.layer = (row + col) % 8;
            if (col % 3 == 0) s.color = Color{0.4f + float(rng.next_u32() % 60) * 0.01f, 0.8f, 0.5f, 1.0f};
            if (col % 17 == 0) w.get<Transform>(e)->rotation = {0, 0, float(rng.next_u32() % 90)};
        }
    }
    // 120 labels of the built-in font.
    for (int i = 0; i < 120; ++i) {
        Entity e = make(w, {-300.0f + float(i % 12) * 50.0f, -150.0f + float(i / 12) * 30.0f, 0});
        Text& t = w.add<Text>(e);
        t.text = "Score " + std::to_string(i * 37);
        t.fontSize = 12.0f;
    }
}

void build_3d(World& w) {
    Entity cam = make(w, {0, 14, 26});
    Camera& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    w.get<Transform>(cam)->rotation = {-24, 0, 0};
    Entity sun = make(w, {0, 20, 0});
    w.get<Transform>(sun)->rotation = {-50, 30, 0};
    w.add<Light>(sun).type = LightType::Directional;
    for (int i = 0; i < 4; ++i) {
        Entity l = make(w, {-12.0f + float(i) * 8.0f, 4, 4});
        Light& light = w.add<Light>(l);
        light.type = LightType::Point;
        light.range = 14;
    }
    Entity ground = make(w, {0, -0.5f, 0});
    w.get<Transform>(ground)->scale = {80, 1, 80};
    w.add<MeshRenderer>(ground).mesh = "plane";
    Rng rng(32);
    // 40 x 40 = 1600 cubes and spheres, a third of them outside the camera's frustum.
    for (int ix = 0; ix < 40; ++ix) {
        for (int iz = 0; iz < 40; ++iz) {
            Entity e = make(
                w, {-30.0f + float(ix) * 1.5f, 0.25f + float(rng.next_u32() % 3) * 0.4f, -50.0f + float(iz) * 2.5f});
            w.get<Transform>(e)->rotation = {0, float(rng.next_u32() % 90), 0};
            MeshRenderer& m = w.add<MeshRenderer>(e);
            m.mesh = (ix + iz) % 2 ? "cube" : "sphere";
            m.color = Color{0.3f + float(rng.next_u32() % 70) * 0.01f, 0.5f, 0.6f, 1.0f};
        }
    }
}

Bench render_bench(const char* name, const char* summary, void (*build)(World&), std::int64_t items, const char* unit) {
    Bench b;
    b.name = name;
    b.summary = summary;
    b.warnRatio = 1.6;  // a GPU driver runs beside the gather, and the software ones run threads
    b.failRatio = 2.5;
    b.make = [build, items, unit] {
        Prepared p;
        RenderEnv& e = env();
        if (!e.ok) {
            p.skip = e.error;
            return p;
        }
        auto world = std::make_shared<World>();
        build(*world);
        e.frame(*world);  // the first frame loads the fonts, makes the pipelines and the glyph atlas
        p.items = items;
        p.unit = unit;
        p.run = [world] {
            RenderEnv& renderEnv = *env_slot();
            double sum = 0;
            for (int i = 0; i < 8; ++i) sum += renderEnv.frame(*world);
            return sum;
        };
        return p;
    };
    return b;
}

}  // namespace

void release_render_env() { env_slot().reset(); }

void add_render_benches(std::vector<Bench>& out) {
    ensure_builtin_components();
    out.push_back(render_bench("render.frame2d", "8 frames of 5000 sprites on 8 layers and 120 texts, headless 640x360",
                               build_2d, 8 * 5120, "visuals"));
    out.push_back(render_bench(
        "render.frame3d", "8 frames of 1600 cubes and spheres, a sun and 4 point lights with shadows, headless 640x360",
        build_3d, 8 * 1600, "meshes"));
}

}  // namespace fa::bench
