// Camera bloom: glow around bright pixels, applied INTO the game target so screenshots, the editor viewport and
// present() all show it. Pipeline (see shaders/bloom.glsl):
//
//   game target --bright--> 1/2 or 1/4 res --down--> ... --> 1/D res (D = 2 .. 32 by radius)
//        ^                                              |  blur H, blur V (separable gaussian)
//        '------------------- composite (add) ----------'
//
// Everything is RGBA8 and deterministic (no randomness, fixed tap pattern), so headless runs are reproducible.
#pragma once

#include "render_internal.h"

namespace fa::render {

// Camera.bloom* -> supported ranges. NaN and infinities fall back to the defaults.
BloomSettings sanitize_bloom(bool enabled, float threshold, float intensity, float radius);

class Bloom {
public:
    Bloom() = default;
    Bloom(const Bloom&) = delete;
    Bloom& operator=(const Bloom&) = delete;

    // Adds the glow of `srcTex` (a texture view of the finished game target) into `dstAtt` (a color-attachment
    // view of the same image). Must be called outside a pass, after the scene was drawn. Returns the number of
    // draw calls issued, 0 when bloom was skipped (disabled, unsupported shaders, degenerate size).
    int apply(Gpu& gpu, const BloomSettings& s, int targetW, int targetH, sg_view srcTex, sg_view dstAtt);

    // Frees the intermediate targets (call when the game target is resized or on shutdown).
    void release();

private:
    static constexpr int kLevels = 5;  // 1/2, 1/4, 1/8, 1/16, 1/32 of the game target
    struct Level {
        int w = 0, h = 0;
        sg_image img[2]{};
        sg_view att[2]{};
        sg_view tex[2]{};
    };
    bool ensure(int level, int targetW, int targetH, bool needSecond);

    Level levels_[kLevels];
    int targetW_ = 0, targetH_ = 0;
    bool warned_ = false;
};

}  // namespace fa::render
