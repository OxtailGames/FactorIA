// Private: the vocabulary the renderer's GPU code shares (sokol types stay in src/, never in include/).
//
//  * TargetFormat: what a render pass writes into. A pipeline is only valid for passes with the same formats and
//    sample count, so it is the key of the pipelines made for a pass (a map keyed by TargetFormat, in gpu.cpp).
//  * PassDesc: one render pass as data: where it draws, what it does with the old contents and how it ends. Every pass
//    of the renderer (the game and view passes, shadow, 2D light buffer, colour filter, flip copy, RGBA8 readback,
//    present, bloom stages) builds one and begins it with Gpu::begin_pass (render_internal.h), the only caller of
//    sg_begin_pass in engine/.
#pragma once

#include <cstddef>
#include <cstdint>
#include <functional>
#include <initializer_list>

#include "sokol_gfx.h"

namespace fa::render {

// The formats and sample count of the attachments a pass writes, which a pipeline drawn in that pass must match.
struct TargetFormat {
    sg_pixel_format color = SG_PIXELFORMAT_NONE;  // the colour attachment's format; NONE for a depth-only pass
    // The depth(-stencil) attachment's format; NONE for a pass without one.
    sg_pixel_format depth = SG_PIXELFORMAT_NONE;
    int samples = 1;  // the sample count of the attachments (1 = no multisampling)
    // The second colour attachment's format (multiple render targets); NONE for every pass but the subsurface draw. Last,
    // so the aggregate initialisers {color, depth, samples} of the other passes keep working.
    sg_pixel_format color1 = SG_PIXELFORMAT_NONE;

    bool operator==(const TargetFormat& o) const {
        return color == o.color && color1 == o.color1 && depth == o.depth && samples == o.samples;
    }
    bool operator!=(const TargetFormat& o) const { return !(*this == o); }

    // A hash of the four fields (std::hash<TargetFormat> uses it): the same on every run, never a pointer or an id.
    std::size_t hash() const {
        std::uint64_t h = 1469598103934665603ull;  // FNV-1a over the four values
        for (std::uint64_t v :
             {std::uint64_t(color), std::uint64_t(color1), std::uint64_t(depth), std::uint64_t(samples)}) {
            h ^= v;
            h *= 1099511628211ull;
        }
        return std::size_t(h);
    }
};

// One render pass. A pass draws either into the views below or into a swapchain (present), never both.
//
// The defaults of the load/store actions are NOT sokol's: a zero sg_pass means "clear to grey" (SG_LOADACTION_DEFAULT
// is CLEAR for colour, depth and stencil), while a PassDesc says DONTCARE for what it does not set, so a pass that
// forgets a field is cheap rather than clearing. Every site that begins a pass sets colorLoad, colorStore and, when it
// has a depth or stencil attachment (a swapchain has them), depthLoad and stencilLoad explicitly, to what its sg_pass
// did.
struct PassDesc {
    const char* label = "";  // the debug label of the pass (GPU captures, validation messages): a string literal

    // Where the pass draws. With `swapchain` set the three views are ignored and the pass draws into the window.
    sg_view color{};    // colour attachment 0; an invalid view (id 0) for a depth-only pass (the shadow map has both)
    sg_view color1{};   // colour attachment 1 (the subsurface draw's second target); id 0 for every other pass
    sg_view resolve{};  // MSAA only: the view `color` is resolved into at the end of the pass; id 0 when not resolving
    sg_view depth{};    // the depth-stencil attachment; id 0 when the pass has none
    const sg_swapchain* swapchain = nullptr;  // present(): the window's swapchain (not owned, valid for the call)

    TargetFormat format{};  // the formats and sample count of the attachments, for the pipelines drawn in this pass

    // What the pass does with the old contents of the colour attachment: LOAD to keep them (a second camera, the HUD
    // over the bloom), CLEAR to fill with `clearColor`, DONTCARE when every pixel is drawn.
    sg_load_action colorLoad = SG_LOADACTION_DONTCARE;
    // DONTCARE when the pass resolves and nobody reads the MSAA image.
    sg_store_action colorStore = SG_STOREACTION_STORE;
    sg_color clearColor{0.0f, 0.0f, 0.0f, 0.0f};
    sg_color clearColor1{0.0f, 0.0f, 0.0f,
                         0.0f};  // what a CLEAR of colour attachment 1 fills it with (the velocity image: the sentinel)
    sg_load_action depthLoad = SG_LOADACTION_DONTCARE;  // CLEAR to `clearDepth`; the depth is never read after the pass
    float clearDepth = 1.0f;
    sg_load_action stencilLoad = SG_LOADACTION_DONTCARE;  // the main passes CLEAR it (to 0)
    // What the pass does with the depth and the stencil afterwards: the sokol default (DONTCARE) unless a later pass loads them (the main pass,
    // split in two by a transmissive draw, STOREs them, renderer_xmit.h).
    sg_store_action depthStore = _SG_STOREACTION_DEFAULT;
    sg_store_action stencilStore = _SG_STOREACTION_DEFAULT;

    // A pass into the window: `swapchain` (not owned: it must outlive the pass) and the formats it really has. sokol
    // accepts 0 for the colour format, the depth format and the sample count of an sg_swapchain and uses the defaults
    // of the environment (sg_desc.environment.defaults) then; `defaults` is that environment, so `format` is what a
    // pipeline drawn in the pass has to match (Gpu::blit_pipeline(format)). The load/store actions are the ones of a
    // pass that fills the window: the caller sets them.
    static PassDesc for_swapchain(const sg_swapchain& sc, const sg_environment_defaults& defaults) {
        PassDesc p;
        p.swapchain = &sc;
        p.format.color = sc.color_format != _SG_PIXELFORMAT_DEFAULT ? sc.color_format : defaults.color_format;
        p.format.depth = sc.depth_format != _SG_PIXELFORMAT_DEFAULT ? sc.depth_format : defaults.depth_format;
        p.format.samples =
            sc.sample_count > 0 ? sc.sample_count : (defaults.sample_count > 0 ? defaults.sample_count : 1);
        return p;
    }
    // The same with the defaults of the open sokol context (sg_query_desc); the raw values of `sc` when there is none.
    static PassDesc for_swapchain(const sg_swapchain& sc) {
        sg_environment_defaults d{};
        if (sg_isvalid()) d = sg_query_desc().environment.defaults;
        return for_swapchain(sc, d);
    }

    // The sokol description of the pass, for sg_begin_pass.
    sg_pass to_sg() const {
        sg_pass p{};
        p.action.colors[0].load_action = colorLoad;
        p.action.colors[0].store_action = colorStore;
        p.action.colors[0].clear_value = clearColor;
        if (color1.id) {
            p.action.colors[1].load_action = colorLoad;
            p.action.colors[1].store_action = colorStore;
            p.action.colors[1].clear_value = clearColor1;
        }
        p.action.depth.load_action = depthLoad;
        p.action.depth.clear_value = clearDepth;
        p.action.depth.store_action = depthStore;
        p.action.stencil.store_action = stencilStore;
        p.action.stencil.load_action = stencilLoad;
        if (swapchain) {
            p.swapchain = *swapchain;
        } else {
            p.attachments.colors[0] = color;
            p.attachments.colors[1] = color1;
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
