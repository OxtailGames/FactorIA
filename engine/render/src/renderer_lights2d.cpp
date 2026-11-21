// Renderer::Impl: the cookie atlas of the 2D lights (M74, Light2D.cookie). The light buffer pass and the per-pixel lit path read the
// atlas through light_cookie.glsl; docs/rendering/RENDERING_2D_EMISSION.md explains the design.
#include <algorithm>

#include "light_layers.h"
#include "renderer_impl.h"

namespace fa {

// Makes (or keeps) the atlas: kCookieGrid x kCookieGrid cells of kCookieCell texels, RGBA8 (the values of the cookie files as they are).
// False when the GPU cannot make it (one logged error): lights then shine without their cookies.
bool Renderer::Impl::ensure_cookie_target() {
    if (cookieTargetFailed) return false;
    if (cookieTarget.color.id) return true;
    TargetDesc d;
    d.label = "light-cookies";
    d.width = kCookieGrid * kCookieCell;
    d.height = kCookieGrid * kCookieCell;
    d.colorFormat = SG_PIXELFORMAT_RGBA8;
    cookieTarget = make_target(d);
    if (!cookieTarget.valid()) {
        FA_ERROR("render",
                 "Cannot create the {}x{} atlas of the 2D light cookies; the lights shine without their cookies",
                 d.width, d.height);
        destroy_target(cookieTarget);
        cookieTargetFailed = true;
        return false;
    }
    return true;
}

std::vector<TextureAsset*> Renderer::Impl::plan_cookies(Frame& fr) {
    int dropped = 0;
    std::vector<TextureAsset*> cells = assign_cookie_cells(fr.lights2d, &dropped);
    if (dropped > 0 && !warnedCookies2d) {
        warnedCookies2d = true;
        FA_WARN("render",
                "{} more distinct Light2D.cookie textures than the {} the 2D lights can use in one frame: those lights "
                "shine without their "
                "cookie. Hint: give lights that share a shape the same cookie file (a cookie is one atlas cell per "
                "distinct texture), or "
                "pack several shapes in one picture and use cookieScale.",
                dropped, kMaxCookies2D);
    }
    // A cookie whose picture is not on the GPU yet (still loading) is no cookie for now.
    for (Light2DData& l : fr.lights2d) {
        if (l.cookieCell < 0) continue;
        const TextureAsset* t = cells[std::size_t(l.cookieCell)];
        if (!t || !t->gpu_view().id) l.cookieCell = -1;
    }
    if (cells.empty() || !ensure_cookie_target()) {
        for (Light2DData& l : fr.lights2d) l.cookieCell = -1;
        return {};
    }
    return cells;
}

// Copies each cookie of the frame into its cell. The pass runs before the light buffer pass and the main pass of the job.
void Renderer::Impl::cookie_pass(const std::vector<TextureAsset*>& cells) {
    PassDesc p = pass_into(cookieTarget, "light-cookies");
    p.colorLoad = SG_LOADACTION_CLEAR;
    p.clearColor = {0, 0, 0, 0};  // an empty cell lets no light through
    p.colorStore = SG_STOREACTION_STORE;
    gpu.begin_pass(p);
    sg_apply_pipeline(gpu.blit_keep_pipeline(p.format));
    for (std::size_t i = 0; i < cells.size(); ++i) {
        const TextureAsset* t = cells[i];
        if (!t || !t->gpu_view().id) continue;
        const int cx = int(i) % kCookieGrid, cy = int(i) / kCookieGrid;
        sg_apply_viewport(cx * kCookieCell, cy * kCookieCell, kCookieCell, kCookieCell, true);
        sg_apply_scissor_rect(cx * kCookieCell, cy * kCookieCell, kCookieCell, kCookieCell, true);
        sg_bindings b{};
        b.vertex_buffers[0] = gpu.fullscreen_triangle();
        b.views[VIEW_blit_tex] = t->gpu_view();
        b.samplers[SMP_blit_smp] = gpu.sampler(SamplerKind::LinearClamp);
        sg_apply_bindings(&b);
        blit_blit_vs_params_t u{};
        if (t->atlas) {  // packed into an atlas by an export: only its own part
            const float aw = float(std::max(1, t->atlas->width)), ah = float(std::max(1, t->atlas->height));
            u.region[0] = float(t->atlasX) / aw;
            u.region[1] = float(t->atlasY) / ah;
            u.region[2] = float(t->width) / aw;
            u.region[3] = float(t->height) / ah;
        }
        apply_uniforms(UB_blit_blit_vs_params, u);
        blit_blit_fs_params_t fu{};
        // The atlas holds the file's own values: a texture the GPU decodes from sRGB is encoded back (blit_keep's encode).
        fu.encode[0] = t->tex_fix(false, false) == 2 ? 1.0f : 0.0f;
        apply_uniforms(UB_blit_blit_fs_params, fu);
        sg_draw(0, 3, 1);
        ++stats.drawCalls;
    }
    gpu.end_pass();
    ++stats.drawCalls;
}

}  // namespace fa
