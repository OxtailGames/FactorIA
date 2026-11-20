// Test accessors of the renderer (never a public header: engine code and games do not call them). A test that has to
// look inside the renderer (its GPU objects, the frame graph of the last frame, the counts of its pools, the history
// images of the custom post passes) includes this header and calls the free functions below; they go through
// RendererTestAccess, the one friend of Renderer, so Impl stays closed. RendererTestAccess is defined in renderer.cpp.
#pragma once

#include <cstdint>
#include <functional>
#include <string>
#include <vector>

#include "fa/platform/hdr_output.h"
#include "fa/render/probe.h"
#include "fa/render/renderer.h"

namespace fa {
namespace render {

class Gpu;
class FrameGraph;

// The targets the frame graph's transients are made of (target_pool.h's TargetPoolStats).
struct TransientPoolStats {
    int live = 0, inUse = 0, created = 0, reused = 0, destroyed = 0;
};
// The ring of images that hold the shadow rows of the 2D lights: how many it holds now and how many images were made
// since the renderer was.
struct ShadowRowsStats {
    int slots = 0, uploads = 0;
};

// How many times the physical sky drew its tables (renderer_sky_phys.h): the air's, the picture's view and the environment's.
struct SkyBuilds {
    int air = 0, view = 0, envView = 0;
};

}  // namespace render

struct RendererTestAccess {
    static render::Gpu* gpu(Renderer& r);
    static const render::FrameGraph* frame_graph(Renderer& r);
    static render::TransientPoolStats transient_stats(Renderer& r);
    static render::ShadowRowsStats shadow_rows_stats(Renderer& r);
    static int post_history_images(Renderer& r);
    static int ldr_cut_format(Renderer& r);
    static void set_post_history_budget(Renderer& r, std::uint64_t bytes);
    static void refuse_post_history(Renderer& r, bool refuse);
    static int post_history_attempts(Renderer& r);
    static void force_post_effects(Renderer& r, std::uint32_t effects);
    static void force_output(Renderer& r, const HdrOutputInfo* info);
    static void last_cluster_info(Renderer& r, float out[4]);
    static bool read_floats(Renderer& r, bool present, std::vector<float>& out, std::string* error);
    static void set_before_frame_graph(Renderer& r, std::function<void()> hook);
    static render::SkyBuilds sky_builds(Renderer& r);
    static bool read_probe_atlas(Renderer& r, int x, int y, int w, int h, std::vector<float>& out, std::string* error);
    static bool probe_tile(Renderer& r, std::uint64_t id, render::ProbeTile& out);
    static void probe_force_rgba8(bool force);
};

namespace render {

// The renderer's GPU objects (engine/render/src/render_internal.h); null before init.
inline Gpu* renderer_gpu(Renderer& r) { return RendererTestAccess::gpu(r); }
// The frame graph of the last frame the renderer drew (frame_graph.h; every job of the frame is in it, its passes named
// "<job>/<pass>"); null before init.
inline const FrameGraph* renderer_frame_graph(Renderer& r) { return RendererTestAccess::frame_graph(r); }
inline TransientPoolStats renderer_transient_stats(Renderer& r) { return RendererTestAccess::transient_stats(r); }
inline ShadowRowsStats renderer_shadow_rows_stats(Renderer& r) { return RendererTestAccess::shadow_rows_stats(r); }
inline SkyBuilds renderer_sky_builds(Renderer& r) { return RendererTestAccess::sky_builds(r); }
// The images the post passes that read their own output of the frame before (fa_history) hold now.
inline int renderer_post_history_images(Renderer& r) { return RendererTestAccess::post_history_images(r); }
// The pixel format (sg_pixel_format as an int) of the images the final pass goes through when display-referred custom
// passes cut it, or 0 while none exists.
inline int renderer_ldr_cut_format(Renderer& r) { return RendererTestAccess::ldr_cut_format(r); }
// Tests of the history images (renderer_custom_post.h): the budget in bytes (0 = the default); the GPU refusing them (a
// slot it refused is not asked again every frame); and how many slots were asked of the GPU since the renderer was
// made.
inline void renderer_set_post_history_budget(Renderer& r, std::uint64_t bytes) {
    RendererTestAccess::set_post_history_budget(r, bytes);
}
inline void renderer_refuse_post_history(Renderer& r, bool refuse) {
    RendererTestAccess::refuse_post_history(r, refuse);
}
inline int renderer_post_history_attempts(Renderer& r) { return RendererTestAccess::post_history_attempts(r); }
// Draws the depth and normal prepass as if the camera's stack switched on the effects of `effects` (a mask like
// PostStack::mask, bit i = PostEffect(i); 0 = as the stack says).
inline void renderer_force_post_effects(Renderer& r, std::uint32_t effects) {
    RendererTestAccess::force_post_effects(r, effects);
}
// The HDR output: the next frames are drawn and presented as if update_output() had answered `info` (null: back to what
// it answers), for the render tests of the encodes without an HDR display.
// fa_cl_info of the last job the renderer drew: x is the first texel of the cluster table or -1 when the view has no
// clusters, y the depth slices, z the directional lights, w the clusters.
inline void renderer_last_cluster_info(Renderer& r, float out[4]) { RendererTestAccess::last_cluster_info(r, out); }
inline void renderer_force_output(Renderer& r, const HdrOutputInfo* info) { RendererTestAccess::force_output(r, info); }
// The last frame's finished picture as floats (RGBA, top row first): as the final target holds it (`present` false), or
// through present()'s encode for the output (scRGB, PQ, EDR or sRGB values). False with `error` where the GPU cannot
// draw or read back an RGBA16F image.
inline bool renderer_read_floats(Renderer& r, bool present, std::vector<float>& out, std::string* error) {
    return RendererTestAccess::read_floats(r, present, out, error);
}
// `hook` runs once per frame after everything is gathered and before the passes run (empty = none): the place to
// destroy a resource the gathered frame refers to. Clear it before the Renderer is used by another test.
inline void renderer_set_before_frame_graph(Renderer& r, std::function<void()> hook) {
    RendererTestAccess::set_before_frame_graph(r, std::move(hook));
}

// The probe atlas (renderer_probes.h): a rectangle of its texels as RGBA floats, top row first (RGBA8 atlas: bytes / 255); the tile of a probe
// (`id`: the entity's bits; render::kProbeSkyId for the sky's entry); and the next probe GPU objects as an RGBA8 GPU would make them (call before
// the first probe is drawn, undo with false).
inline bool renderer_read_probe_atlas(Renderer& r, int x, int y, int w, int h, std::vector<float>& out, std::string* error) {
    return RendererTestAccess::read_probe_atlas(r, x, y, w, h, out, error);
}
inline bool renderer_probe_tile(Renderer& r, std::uint64_t id, ProbeTile& out) { return RendererTestAccess::probe_tile(r, id, out); }
inline void renderer_probe_force_rgba8(bool force) { RendererTestAccess::probe_force_rgba8(force); }

}  // namespace render
}  // namespace fa
