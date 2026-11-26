// The picture a transmissive mesh looks through (M73-P6b): glass and liquids (MeshRenderer.transmission, KHR_materials_transmission) show what is
// behind them. The blended phase of the main pass cannot read the image it draws into, so when a visible draw is transmissive the main pass ends
// after the opaque phase (sky, opaque meshes, ambient occlusion, fog), the opaque picture is copied into a "refraction atlas", and the pass goes
// on (colour and depth loaded) with the blended draws, which sample the atlas at the mesh shader's view 28 (fa_screen_tex).
//
// The atlas is one image of the picture's colour format, in IMAGE ROWS (row 0 is the first row of the image's memory on every backend):
//
//   level 0  the camera's rectangle of the picture, at (0,0), size W x H (with the ray traced translucency, M79-P3b: the traced pixels replaced)
//   level 1  half size (each pixel a smooth 4x4 weighting of level 0), at (W, 0)
//   level k  half of level k-1, stacked under level 1 at x = W (y = the heights of levels 1..k-1)
//
// at most kXmitMaxLevels levels (fewer while the picture is small). A rough surface reads a higher level, so roughness blurs the refraction;
// the filtering is done by hand in the shader (brdf_layers.glsl, fa_transmission: texelFetch, a bilinear tap per level and a blend between two
// levels), because view 28 is declared unfilterable (it is the contact shadows' depth image in the opaque phase) and the mesh program has no
// free texture slot for a second sampler. The levels are made with one draw each (shaders/xmit.glsl): the copy and the reductions go through
// small transient images of the pool, one per level above 0, then one pass writes every level into the atlas.
//
// A frame with no visible transmissive draw copies nothing and is bit-identical to a frame without the feature. When the shader or one of the
// images cannot be made, the draws fall back to a plain blend without refraction (fa_tr_a.w = 2 in the mesh shader) and render.supports says so.
//
// The layout is pure arithmetic (no GPU): the tests check it. Xmit owns its shader and pipelines (made on first use, destroyed by release()).
#pragma once

#include <cstdint>
#include <vector>

#include "render_internal.h"
#include "transient_targets.h"

namespace fa::render {

constexpr int kXmitMaxLevels = 5;

// Where each level is in the atlas (image rows) and how big the atlas is, for a camera rectangle of w x h pixels.
struct XmitLayout {
    struct Level {
        int x = 0, y = 0, w = 0, h = 0;
    };
    int levels = 0;  // 0 when w or h is below 1
    int atlasW = 0, atlasH = 0;
    Level level[kXmitMaxLevels];
};
XmitLayout xmit_layout(int w, int h);

// The images of one frame's copy, from Xmit::build to Xmit::finish.
struct XmitImages {
    std::uint64_t atlas = 0;
    std::uint64_t reduced[kXmitMaxLevels]{};  // the images of levels 1.., index = level
    gpu::View atlasView{};
    int levels = 0;
    bool traced =
        false;  // level 0 holds the ray traced translucency (alpha 1 where it traced a pixel, 0 elsewhere): the glass shader reads it (mode 3)
};

class Xmit {
public:
    Xmit() = default;
    Xmit(const Xmit&) = delete;
    Xmit& operator=(const Xmit&) = delete;

    // True when the shader compiled and the pool can make the atlas and the level images of a camera rectangle of w x h pixels. Checked at
    // planning time (and remembered per shape), so a GPU that refuses an image is one warning there and not a failed pass in the middle of the
    // frame.
    bool can_make(TransientTargets& targets, Gpu& gpu, int w, int h);

    // Copies the camera's rectangle of `game` (its texture view, resolved when multisampled) into the atlas: (x, row, w, h) in image rows of
    // the game image. Must be called outside any pass. False (and nothing held) when an image or the shader is missing.
    // `traced`: the image of the ray traced translucency (rt_refract.hlsl; RGBA32F, w x h) or none. Level 0 of the atlas is then the picture with
    // the traced pixels replaced by what the glass shows (shaders/xmit.glsl, mode 2) and alpha 1 there; the reduced levels stay the picture's.
    bool build(TransientTargets& targets, Gpu& gpu, const Target& game, int x, int row, int w, int h, XmitImages& out,
               gpu::View traced = {});
    // Gives the images back to the pool (after the blended draws).
    void finish(TransientTargets& targets, XmitImages& images);

    // Destroys the shader and the pipelines; call while the graphics context is open.
    void release();
    // Forgets the shapes that failed (the game target was resized or recreated).
    void forget_targets();

    bool ready(gpu::Device& device);
    gpu::Pipeline pipeline(gpu::Device& device, const TargetFormat& format);

private:
    struct PipelineEntry {
        TargetFormat format;
        gpu::Pipeline pipeline;
    };
    gpu::Device* device_ = nullptr;  // what ready() made the shader on: release() has no Gpu at hand
    gpu::Shader shader_{};
    std::vector<PipelineEntry> pipelines_;
    int state_ = 0;  // 0 = shader not made yet, 1 = ready, -1 = failed (logged)
    bool warnedTargets_ = false;
    std::vector<std::uint64_t> failed_;  // shapes whose images could not be made
    std::vector<std::uint64_t> probed_;  // shapes whose images were made once
};

}  // namespace fa::render
