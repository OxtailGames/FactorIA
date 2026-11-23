// What the GPU is and how fast it draws (M76, docs/UPSCALING.md, "Graphics presets"): the data `graphics.detect` answers and the
// graphics preset it suggests.
//
// query_gpu_info() asks the graphics API about the adapter (OpenGL: glGetString; D3D11: the DXGI adapter; Metal: the MTLDevice). The
// benchmark draws a fixed scene a few times off-screen (Renderer::capture_camera on a world of its own) and reads the pictures back,
// which makes the GPU finish, so the wall time of a capture is the GPU time of the scene on every backend. It never touches the world
// of the game, its simulation, its clock or its random numbers. suggest_graphics_preset() is a pure function of what was measured.
#pragma once

#include <cstdint>
#include <string>
#include <string_view>

#include "fa/core/json.h"
#include "fa/render/graphics_preset.h"

namespace fa {
class Renderer;
}

namespace fa::render {

struct GpuInfo {
    std::string backend = "none";  // Renderer::backend_name(): "glcore", "gles3", "d3d11", "metal", "dummy"; "none" = no renderer
    std::string name;              // the adapter or the renderer string the API gives ("" = unknown)
    std::string vendor;            // "nvidia", "amd", "intel", "apple", "arm", "qualcomm", "microsoft", "mesa", "other" ("" = unknown)
    std::string driver;            // GL_VERSION or the like ("" = the API does not say)
    std::int64_t memoryMB = 0;     // video memory in MB where the API gives it (0 = unknown)
    bool unifiedMemory = false;    // the GPU shares the memory of the CPU (Apple silicon)
    bool software = false;         // a CPU rasteriser (llvmpipe, SwiftShader, WARP): never a good sign for a preset

    Json to_json() const;
};

// Fills `vendor` and `software` from the strings the API gave (`name`, and `vendorString` such as GL_VENDOR; either may be empty).
// Case-insensitive; "other" when nothing is known and the name is not empty.
void classify_gpu(GpuInfo& info, std::string_view vendorString = {});

// The GPU the renderer is on. Call it on the thread that draws (OpenGL answers for the context current on the calling thread). Without
// a graphics device (a headless run with no renderer, the dummy backend) it answers backend "none" or "dummy" and nothing else.
GpuInfo query_gpu_info();

struct GpuBenchmark {
    bool ran = false;          // false: nothing was drawn (no GPU, a software renderer, a failed capture); `why` says
    std::string why;           // set when !ran
    int samples = 0;           // timed captures
    double frameMs = 0.0;      // the median of the timed captures, 0.1 ms
    double totalMs = 0.0;      // the whole benchmark including the warm-up (pipelines are made then), 0.1 ms
    int width = 0, height = 0;

    Json to_json() const;
};
// The most captures the benchmark makes (1 warm-up + kBenchmarkSamples timed) and a safety net far above a normal run: past it no
// more samples are taken (at least one is).
inline constexpr int kBenchmarkSamples = 5;
inline constexpr double kBenchmarkBudgetMs = 4000.0;

// Draws the fixed scene (about 150 lit and shadowed meshes at 960x540) and times it. The renderer's graphics preset is lifted while it
// runs and put back, so every GPU is measured on the same work. Skipped (ran false) on a software renderer. Not to be called inside
// a frame.
GpuBenchmark run_gpu_benchmark(Renderer& renderer, const GpuInfo& info);

// The preset a machine suggests: from the benchmark (a time per picture of the fixed scene), capped by what the machine is.
struct DeviceClass {
    std::string tier = "medium";        // game.device().tier: "low", "medium" or "high"
    std::string formFactor = "desktop";  // "desktop", "tablet" or "phone"
    bool handheld = false;               // a phone, a tablet or a Steam Deck
};
struct PresetSuggestion {
    GraphicsPreset preset = GraphicsPreset::Medium;
    std::string reason;  // one or two sentences: what decided
};
PresetSuggestion suggest_graphics_preset(const GpuInfo& gpu, const GpuBenchmark& bench, const DeviceClass& device);

}  // namespace fa::render
