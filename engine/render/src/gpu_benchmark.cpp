// The short GPU benchmark and the preset it suggests (fa/render/gpu_info.h).
#include <algorithm>
#include <chrono>
#include <cmath>
#include <format>
#include <vector>

#include "fa/render/gpu_info.h"
#include "fa/render/renderer.h"
#include "fa/scene/world.h"

namespace fa::render {

namespace {

constexpr int kBenchWidth = 960;
constexpr int kBenchHeight = 540;

double round1(double v) { return std::round(v * 10.0) / 10.0; }

// The fixed scene: a ground, a 13 x 11 field of spheres and cubes with a spread of metals and roughnesses, a sun with cascaded shadows
// and two point lights. Nothing of it comes from the game, so every GPU draws the same work.
Entity build_scene(World& w) {
    SceneSettings& ss = w.settings();
    ss.ambientLight = Color{0.2f, 0.2f, 0.25f, 1.0f};
    ss.shadowCascades = 3;
    ss.shadowAtlasSize = 2048;
    Entity cam = w.create("bench-camera");
    w.get<Transform>(cam)->position = {0.0f, 14.0f, 30.0f};
    w.get<Transform>(cam)->rotation = {-24.0f, 0.0f, 0.0f};
    Camera& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60.0f;
    Entity ground = w.create("bench-ground");
    w.get<Transform>(ground)->scale = {80.0f, 1.0f, 80.0f};
    MeshRenderer& g = w.add<MeshRenderer>(ground);
    g.mesh = "plane";
    g.color = Color{0.55f, 0.55f, 0.5f, 1.0f};
    for (int z = 0; z < 11; ++z) {
        for (int x = 0; x < 13; ++x) {
            Entity e = w.create("bench-mesh");
            w.get<Transform>(e)->position = {float(x - 6) * 3.0f, 1.0f, float(z - 8) * 3.0f};
            MeshRenderer& m = w.add<MeshRenderer>(e);
            m.mesh = (x + z) % 2 == 0 ? "sphere" : "cube";
            m.color =
                Color{0.3f + 0.05f * float(x % 8), 0.4f + 0.04f * float(z % 10), 0.8f - 0.04f * float(x % 10), 1.0f};
            m.metallic = float(x % 4) * 0.3f;
            m.roughness = 0.2f + float(z % 4) * 0.2f;
        }
    }
    Entity sun = w.create("bench-sun");
    w.get<Transform>(sun)->rotation = {-50.0f, 25.0f, 0.0f};
    Light& l = w.add<Light>(sun);
    l.type = LightType::Directional;
    l.intensity = 1.2f;
    l.castShadows = true;
    for (int i = 0; i < 2; ++i) {
        Entity p = w.create("bench-point");
        w.get<Transform>(p)->position = {i == 0 ? -8.0f : 8.0f, 5.0f, -6.0f};
        Light& pl = w.add<Light>(p);
        pl.type = LightType::Point;
        pl.range = 22.0f;
        pl.intensity = 6.0f;
    }
    return cam;
}

}  // namespace

Json GpuBenchmark::to_json() const {
    Json j = Json::object();
    j["ran"] = ran;
    if (!ran) j["why"] = why;
    j["samples"] = samples;
    j["frameMs"] = round1(frameMs);
    j["totalMs"] = round1(totalMs);
    j["width"] = width;
    j["height"] = height;
    return j;
}

GpuBenchmark run_gpu_benchmark(Renderer& renderer, const GpuInfo& info) {
    GpuBenchmark b;
    if (!renderer.initialized() || info.backend == "none" || info.backend == "dummy") {
        b.why = "there is no GPU to draw on (a headless run)";
        return b;
    }
    if (info.software) {
        b.why = "the renderer is the CPU (" + info.name + "): a benchmark would only measure the CPU";
        return b;
    }
    using Clock = std::chrono::steady_clock;
    const auto ms = [](Clock::time_point a, Clock::time_point z) {
        return std::chrono::duration<double, std::milli>(z - a).count();
    };
    const QualityLimits previous = renderer.quality();
    renderer.set_quality(QualityLimits{});  // every GPU draws the same work, whatever preset the game is on
    World world;
    const Entity cam = build_scene(world);
    Renderer::CameraCapture spec;
    spec.camera = cam;
    spec.width = kBenchWidth;
    spec.height = kBenchHeight;
    b.width = kBenchWidth;
    b.height = kBenchHeight;
    std::vector<double> times;
    std::string error;
    Image shot;
    const auto start = Clock::now();
    // The first capture makes the pipelines and the buffers: it is not timed.
    bool ok = renderer.capture_camera(world, spec, shot, &error);
    for (int i = 0; ok && i < kBenchmarkSamples; ++i) {
        if (!times.empty() && ms(start, Clock::now()) > kBenchmarkBudgetMs) break;  // the safety net
        const auto t0 = Clock::now();
        ok = renderer.capture_camera(world, spec, shot, &error);
        if (ok) times.push_back(ms(t0, Clock::now()));
    }
    b.totalMs = round1(ms(start, Clock::now()));
    renderer.set_quality(previous);
    if (!ok || times.empty()) {
        b.why = "the benchmark could not draw its scene: " + (error.empty() ? std::string("unknown reason") : error);
        return b;
    }
    std::sort(times.begin(), times.end());
    b.ran = true;
    b.samples = int(times.size());
    b.frameMs = round1(times[times.size() / 2]);
    return b;
}

namespace {
int rank_of(GraphicsPreset p) { return int(p); }  // Low 0 .. Ultra 3
}  // namespace

PresetSuggestion suggest_graphics_preset(const GpuInfo& gpu, const GpuBenchmark& bench, const DeviceClass& device) {
    PresetSuggestion out;
    std::string reason;
    GraphicsPreset p;
    if (gpu.software) {
        out.preset = GraphicsPreset::Low;
        out.reason = "the renderer is the CPU (" + gpu.name + "): Low keeps the frame rate up";
        return out;
    }
    if (bench.ran) {
        // The fixed scene (960x540, 150 lit meshes, cascaded shadows) with the picture read back: a discrete or recent GPU draws it in a
        // few ms, an integrated one in ten or more.
        if (bench.frameMs <= 4.0)
            p = GraphicsPreset::Ultra;
        else if (bench.frameMs <= 8.0)
            p = GraphicsPreset::High;
        else if (bench.frameMs <= 16.0)
            p = GraphicsPreset::Medium;
        else
            p = GraphicsPreset::Low;
        reason = std::format("the benchmark scene took {:.1f} ms per picture", bench.frameMs);
    } else {
        // Nothing was drawn (no GPU to measure, or the benchmark could not run): the class of the machine decides.
        p = device.tier == "high" ? GraphicsPreset::High
                                  : (device.tier == "low" ? GraphicsPreset::Low : GraphicsPreset::Medium);
        reason = "no benchmark (" + bench.why + "); the device tier is " + device.tier;
    }
    const auto cap = [&](GraphicsPreset most, const std::string& why) {
        if (rank_of(p) > rank_of(most)) {
            p = most;
            reason += "; capped at " + std::string(graphics_preset_name(most)) + " because " + why;
        }
    };
    if (device.formFactor != "desktop")
        cap(GraphicsPreset::Medium, "a " + device.formFactor + " has little thermal headroom");
    else if (device.handheld)
        cap(GraphicsPreset::High, "a handheld has little thermal headroom");
    if (device.tier == "low") cap(GraphicsPreset::Medium, "the device tier is low");
    if (gpu.memoryMB > 0 && gpu.memoryMB < 2048 && !gpu.unifiedMemory)
        cap(GraphicsPreset::Medium, "the GPU has " + std::to_string(gpu.memoryMB) + " MB of memory");
    out.preset = p;
    out.reason = reason;
    return out;
}

}  // namespace fa::render
