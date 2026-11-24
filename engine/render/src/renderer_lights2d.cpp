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
    cookieTarget = make_target(gpu.device(), d);
    if (!cookieTarget.valid(gpu.device())) {
        FA_ERROR("render",
                 "Cannot create the {}x{} atlas of the 2D light cookies; the lights shine without their cookies",
                 d.width, d.height);
        destroy_target(gpu.device(), cookieTarget);
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

// Copies each cookie of the frame into its cell. The pass runs before the light buffer pass and the main pass of the job. The atlas keeps
// its content from frame to frame (the copy is the same on every backend, the upside-down render target of OpenGL is undone by the cell's
// negative v step in cookie_shader_data), so a frame whose cells hold the same textures as the last copy does nothing.
void Renderer::Impl::cookie_pass(const std::vector<TextureAsset*>& cells) {
    // A live cookie (a camera's render target, a compute image) changes under the same view id: copy it every frame, and keep no stamp
    // (none is even built) so the frame after the cookie is swapped for a file copies too.
    bool live = false;
    for (const TextureAsset* t : cells) live = live || (t && t->live);
    if (live) {
        cookieStamp.clear();
    } else {
        std::vector<std::uint64_t> stamp;
        stamp.reserve(2 + cells.size() * 6);
        stamp.push_back(cookieTarget.color.id);
        stamp.push_back(assets ? assets->reload_generation() : 0);
        for (const TextureAsset* t : cells) {
            stamp.push_back(t ? t->gpu_view().id : 0);
            stamp.push_back(t ? std::uint64_t(std::max(t->width, 0)) : 0);
            stamp.push_back(t ? std::uint64_t(std::max(t->height, 0)) : 0);
            stamp.push_back(t && t->atlas ? std::uint64_t(t->atlasX) : 0);
            stamp.push_back(t && t->atlas ? std::uint64_t(t->atlasY) : 0);
            stamp.push_back(t ? std::uint64_t(t->tex_fix(false, false)) : 0);
        }
        if (stamp == cookieStamp) return;
        cookieStamp = std::move(stamp);
    }
    PassDesc p = pass_into(cookieTarget, "light-cookies");
    p.colorLoad = SG_LOADACTION_CLEAR;
    p.clearColor = {0, 0, 0, 0};  // an empty cell lets no light through
    p.colorStore = SG_STOREACTION_STORE;
    gpu::CommandList& list = gpu.commands();
    gpu::Swapchain swapchain;
    list.begin_pass(gpu::from_render(p, swapchain));
    list.set_pipeline(gpu.blit_keep_pipeline(p.format));
    for (std::size_t i = 0; i < cells.size(); ++i) {
        const TextureAsset* t = cells[i];
        if (!t || !t->gpu_view().id) continue;
        const int cx = int(i) % kCookieGrid, cy = int(i) / kCookieGrid;
        list.set_viewport(cx * kCookieCell, cy * kCookieCell, kCookieCell, kCookieCell, true);
        list.set_scissor(cx * kCookieCell, cy * kCookieCell, kCookieCell, kCookieCell, true);
        gpu::Bindings b;
        b.vertexBuffers[0] = gpu.fullscreen_triangle();
        b.views[VIEW_blit_tex] = gpu::from_sg(t->gpu_view());
        b.samplers[SMP_blit_smp] = gpu.sampler(SamplerKind::LinearClamp);
        list.set_bindings(b);
        blit_blit_vs_params_t u{};
        if (t->atlas) {  // packed into an atlas by an export: only its own part
            const float aw = float(std::max(1, t->atlas->width)), ah = float(std::max(1, t->atlas->height));
            u.region[0] = float(t->atlasX) / aw;
            u.region[1] = float(t->atlasY) / ah;
            u.region[2] = float(t->width) / aw;
            u.region[3] = float(t->height) / ah;
        }
        list.set_uniforms(UB_blit_blit_vs_params, gpu::Range{&u, sizeof(u)});
        blit_blit_fs_params_t fu{};
        // The atlas holds the file's own values: a texture the GPU decodes from sRGB is encoded back (blit_keep's encode).
        fu.encode[0] = t->tex_fix(false, false) == 2 ? 1.0f : 0.0f;
        list.set_uniforms(UB_blit_blit_fs_params, gpu::Range{&fu, sizeof(fu)});
        list.draw(0, 3, 1);
        ++stats.drawCalls;
    }
    list.end_pass();
    ++stats.drawCalls;
}

}  // namespace fa
