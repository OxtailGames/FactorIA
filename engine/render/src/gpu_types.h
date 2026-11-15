// Private: the vocabulary the renderer's GPU code shares (sokol types stay in src/, never in include/).
//
//  * TargetFormat: what a render pass writes into. A pipeline is only valid for passes with the same formats and
//    sample count, so it is the key of the pipelines made for a pass (a map keyed by TargetFormat, in gpu.cpp).
//  * PassDesc: one render pass as data: where it draws, what it does with the old contents and how it ends. The
//    sg_begin_pass call sites of the renderer (the game and view passes, shadow, 2D light buffer, colour filter, flip copy,
//    RGBA8 readback, present, bloom stages) are to build one and begin it with sg_begin_pass(&desc.to_sg()) instead of each
//    filling an sg_pass. Nothing uses these types yet.
#pragma once

#include <cstddef>
#include <cstdint>
#include <functional>

#include "sokol_gfx.h"

namespace fa::render {

// The formats and sample count of the attachments a pass writes, which a pipeline drawn in that pass must match.
struct TargetFormat {
    sg_pixel_format color = SG_PIXELFORMAT_NONE;  // the colour attachment's format; NONE for a depth-only pass
    sg_pixel_format depth = SG_PIXELFORMAT_NONE;  // the depth(-stencil) attachment's format; NONE for a pass without one
    int samples = 1;                              // the sample count of the attachments (1 = no multisampling)

    bool operator==(const TargetFormat& o) const {
        return color == o.color && depth == o.depth && samples == o.samples;
    }
    bool operator!=(const TargetFormat& o) const { return !(*this == o); }

    // A hash of the three fields (std::hash<TargetFormat> uses it): the same on every run, never a pointer or an id.
    std::size_t hash() const {
        std::uint64_t h = 1469598103934665603ull;  // FNV-1a over the three values
        for (std::uint64_t v : {std::uint64_t(color), std::uint64_t(depth), std::uint64_t(samples)}) {
            h ^= v;
            h *= 1099511628211ull;
        }
        return std::size_t(h);
    }
};

// One render pass. A pass draws either into the views below or into a swapchain (present), never both.
struct PassDesc {
    const char* label = "";  // the debug label of the pass (GPU captures, validation messages): a string literal

    // Where the pass draws. With `swapchain` set the three views are ignored and the pass draws into the window.
    sg_view color{};    // colour attachment 0; an invalid view (id 0) for a depth-only pass (the shadow map has both)
    sg_view resolve{};  // MSAA only: the view `color` is resolved into at the end of the pass; id 0 when not resolving
    sg_view depth{};    // the depth-stencil attachment; id 0 when the pass has none
    const sg_swapchain* swapchain = nullptr;  // present(): the window's swapchain (not owned, valid for the call)

    TargetFormat format{};  // the formats and sample count of the attachments, for the pipelines drawn in this pass

    // What the pass does with the old contents of the colour attachment: LOAD to keep them (a second camera, the HUD over
    // the bloom), CLEAR to fill with `clearColor`, DONTCARE when every pixel is drawn.
    sg_load_action colorLoad = SG_LOADACTION_DONTCARE;
    sg_store_action colorStore = SG_STOREACTION_STORE;  // DONTCARE when the pass resolves and nobody reads the MSAA image
    sg_color clearColor{0.0f, 0.0f, 0.0f, 0.0f};
    sg_load_action depthLoad = SG_LOADACTION_DONTCARE;  // CLEAR to `clearDepth`; the depth is never read after the pass
    float clearDepth = 1.0f;
    sg_load_action stencilLoad = SG_LOADACTION_DONTCARE;  // the main passes CLEAR it (to 0)

    // The sokol description of the pass, for sg_begin_pass.
    sg_pass to_sg() const {
        sg_pass p{};
        p.action.colors[0].load_action = colorLoad;
        p.action.colors[0].store_action = colorStore;
        p.action.colors[0].clear_value = clearColor;
        p.action.depth.load_action = depthLoad;
        p.action.depth.clear_value = clearDepth;
        p.action.stencil.load_action = stencilLoad;
        if (swapchain) {
            p.swapchain = *swapchain;
        } else {
            p.attachments.colors[0] = color;
            p.attachments.resolves[0] = resolve;
            p.attachments.depth_stencil = depth;
        }
        p.label = label;
        return p;
    }
};

}  // namespace fa::render

template <>
struct std::hash<fa::render::TargetFormat> {
    std::size_t operator()(const fa::render::TargetFormat& f) const noexcept { return f.hash(); }
};
