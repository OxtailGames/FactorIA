// Camera bloom: glow around bright pixels, applied INTO the game target so screenshots, the editor viewport and
// present() all show it. Pipeline (see shaders/bloom.glsl):
//
//   game target --bright--> 1/2 or 1/4 res --down--> ... --> 1/D res (D = 2 .. 32 by radius)
//        ^                                              |  blur H, blur V (separable gaussian)
//        '------------------- composite (add) ----------'
//
// The stages are passes of the frame's graph (frame_graph.h) and every intermediate target is a transient of it (a
// TargetPool target, kept across frames) in the game target's format (Gpu::scene_format(): RGBA16F where the GPU can, so a
// colour above white keeps its strength through the blur). The stages are deterministic (no randomness, fixed tap
// pattern), so headless runs are reproducible.
#pragma once

#include <cstdint>
#include <vector>

#include "frame_graph.h"
#include "render_internal.h"
#include "transient_targets.h"

namespace fa::render {

// Camera.bloom* -> supported ranges. NaN and infinities fall back to the defaults.
BloomSettings sanitize_bloom(bool enabled, float threshold, float intensity, float radius, bool screenSpace = true);

// Where the glow is added. `att` is a color-attachment view of the game target. With MSAA the glow can go either
// into the single-sample RESOLVED image (att = the resolve image's own attachment view, the default flow) or into the
// multisampled image itself (att = the MSAA view, `resolve` = the resolve attachment view, `samples` = its sample
// count): the pass then resolves at its end, and the multisampled image keeps the glow so that a later pass (the HUD
// of Camera.bloomScreenSpace = false) can draw on top of it with MSAA and resolve again.
struct BloomTarget {
    sg_view att{};
    sg_view resolve{};
    int samples = 1;
};

class Bloom {
public:
    Bloom() = default;
    Bloom(const Bloom&) = delete;
    Bloom& operator=(const Bloom&) = delete;

    // Declares the passes that add the glow of `srcTex` (a texture view of the finished game target, the imported
    // resource `game` of `graph`) into `dst` (see BloomTarget: a color-attachment view of the same image, or of its
    // multisampled twin): bright, down (0 to 4), blur-h, blur-v, composite, in that order. The intermediate levels are
    // transients of the graph (the pool of `targets`, in the game target's format) and each pass adds one to
    // *drawCalls when it runs. Returns the number of passes declared, 0 when bloom is skipped (disabled, unsupported
    // shaders, degenerate size, an intermediate target the GPU cannot make: logged once, and not tried again until the
    // size or the format changes). Call before graph.compile(), after the passes that draw the scene. The passes are
    // named "<job>/bloom-bright" and so on when `job` is not empty (the frame graph holds the passes of every job).
    int add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, const BloomSettings& s, int targetW,
                   int targetH, ResourceId game, sg_view srcTex, const BloomTarget& dst, int* drawCalls,
                   const std::string& job = {});

    // Forgets that creating the intermediate targets failed (the game target was resized or recreated).
    void release();

private:
    static constexpr int kLevels = 5;  // 1/2, 1/4, 1/8, 1/16, 1/32 of the game target
    bool warned_ = false;
    // The shapes (size + format) whose intermediate targets could not be made: one entry per shape, so two views of
    // different sizes where one fails do not make each other try again every frame. Bounded (kMaxFailed, the oldest go).
    struct Shape {
        int w = 0, h = 0;
        sg_pixel_format fmt = SG_PIXELFORMAT_NONE;
        bool operator==(const Shape& o) const { return w == o.w && h == o.h && fmt == o.fmt; }
    };
    static constexpr std::size_t kMaxFailed = 16;
    std::vector<Shape> failed_;
    // Scratch of add_passes, kept so a frame does not allocate them again.
    std::vector<TransientDesc> descs_;
    std::vector<std::uint64_t> held_;
};

}  // namespace fa::render
