#include "renderer_fog.h"

#include <algorithm>
#include <cmath>
#include <memory>

#include "fa/core/log.h"

#include "color_space.h"
#include "postprocess.h"
#include "postprocess_resolve.h"
#include "shader_cache.h"
#include "shaders/fog.glsl.h"
#include "shaders/sun_shafts.glsl.h"

namespace fa::render {

namespace {

float finite_or(float v, float fallback) { return std::isfinite(v) ? v : fallback; }

constexpr std::size_t kMaxFailed = 16;
constexpr float kMaxWorld = 1.0e6f;  // the farthest world y the height fog's base may name
// The glow of the sky around the sun, per screen height (shaders/sun_shafts.glsl): the scattering is strongest near the sun.
constexpr float kGlowRate = 2.5f;

// The camera's rectangle of the picture in pixels.
struct Rect {
    int x = 0, y = 0, w = 0, h = 0;
    bool whole = true;
};
Rect rect_of(const PostRect& r, int picW, int picH) {
    Rect o;
    o.whole = r.whole(picW, picH);
    o.x = o.whole ? 0 : r.x;
    o.y = o.whole ? 0 : r.y;
    o.w = o.whole ? picW : r.w;
    o.h = o.whole ? picH : r.h;
    return o;
}

// One full-screen triangle with `prog` into the pass `pd`. `tc`, `tp`: the picture and prepass (or, for Add, the rays image in `tc`) the
// program declares; a binding a program does not use is not made (it would be a validation error). `fu`: the program's uniform block.
// `part`: the rectangle of the destination the pass covers (null: all of it).
void draw_fullscreen(FogFx& fx, Gpu& gpu, FogFx::Prog prog, const PassDesc& pd, sg_view tc, sg_view tp, const void* fu,
                     std::size_t fuSize, const Rect* part) {
    if (!pd.color.id) return;  // the target of the pass is gone
    Gpu::begin_pass(pd);
    if (part) {
        sg_apply_viewport(part->x, part->y, part->w, part->h, true);
        sg_apply_scissor_rect(part->x, part->y, part->w, part->h, true);
    }
    sg_apply_pipeline(fx.pipeline(prog, pd.format));
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    switch (prog) {
        case FogFx::Prog::Fog:
            b.views[0] = tp;
            b.samplers[0] = gpu.sampler(SamplerKind::Nearest);
            break;
        case FogFx::Prog::Rays:
            b.views[0] = tc;
            b.views[1] = tp;
            b.samplers[0] = gpu.sampler(SamplerKind::LinearClamp);
            b.samplers[1] = gpu.sampler(SamplerKind::Nearest);
            break;
        default:
            b.views[0] = tc;
            b.samplers[0] = gpu.sampler(SamplerKind::LinearClamp);
            break;
    }
    sg_apply_bindings(&b);
    float flip[4] = {gpu.is_gl() ? 1.0f : 0.0f, 0.0f, 0.0f, 0.0f};
    sg_range vr{flip, sizeof(flip)};
    sg_apply_uniforms(0, &vr);
    if (fu) {
        sg_range fr{fu, fuSize};
        sg_apply_uniforms(1, &fr);
    }
    sg_draw(0, 3, 1);
    Gpu::end_pass();
}

void to_array(const Color& c, float out[3]) {
    out[0] = finite_or(c.r, 0.0f);
    out[1] = finite_or(c.g, 0.0f);
    out[2] = finite_or(c.b, 0.0f);
}

}  // namespace

static_assert(UB_fog_fog_vs_params == 0 && UB_fog_fog_params == 1 && UB_sun_shafts_shafts_vs_params == 0 &&
                  UB_sun_shafts_rays_params == 1 && UB_sun_shafts_add_params == 1,
              "the fog and sun shafts programs use uniform slots 0 (vertex) and 1 (fragment)");
static_assert(VIEW_fog_tex_p == 0 && VIEW_sun_shafts_tex_c == 0 && VIEW_sun_shafts_tex_p == 1 &&
                  VIEW_sun_shafts_tex_r == 0 && SMP_fog_smp_pt == 0 && SMP_sun_shafts_smp_lin == 0 &&
                  SMP_sun_shafts_smp_pt == 1,
              "draw_fullscreen binds the images and samplers at these slots");

bool fog_has_effect(const PostStack& stack) {
    if (!stack.has(PostEffect::Fog)) return false;
    const PostProcess& f = stack.fx;
    return (std::isfinite(f.fogDensity) && f.fogDensity > 0.0f) ||
           (std::isfinite(f.fogHeightDensity) && f.fogHeightDensity > 0.0f);
}

bool shafts_has_effect(const PostStack& stack) {
    if (!stack.has(PostEffect::SunShafts)) return false;
    const PostProcess& f = stack.fx;
    return std::isfinite(f.sunShaftsIntensity) && f.sunShaftsIntensity > 0.0f && std::isfinite(f.sunShaftsLength) &&
           f.sunShaftsLength > 0.0f;
}

bool sun_screen_position(const CameraGeometry& cam, Vec3 towardSun, Vec2* uv, float* fade) {
    if (!cam.perspective) return false;
    if (!std::isfinite(towardSun.x) || !std::isfinite(towardSun.y) || !std::isfinite(towardSun.z)) return false;
    const float len = std::sqrt(towardSun.x * towardSun.x + towardSun.y * towardSun.y + towardSun.z * towardSun.z);
    if (!(len > 1e-6f)) return false;
    const Vec3 v = cam.view.transform_dir(Vec3{towardSun.x / len, towardSun.y / len, towardSun.z / len});
    const Mat4& P = cam.proj;
    // A direction (w = 0) through the projection: the clip position of a point at infinity in that direction.
    const float cx = P.at(0, 0) * v.x + P.at(1, 0) * v.y + P.at(2, 0) * v.z;
    const float cy = P.at(0, 1) * v.x + P.at(1, 1) * v.y + P.at(2, 1) * v.z;
    const float cw = P.at(0, 3) * v.x + P.at(1, 3) * v.y + P.at(2, 3) * v.z;
    if (!std::isfinite(cx) || !std::isfinite(cy) || !std::isfinite(cw)) return false;
    auto smooth = [](float e0, float e1, float x) {
        const float t = std::clamp((x - e0) / (e1 - e0), 0.0f, 1.0f);
        return t * t * (3.0f - 2.0f * t);
    };
    // Behind the camera (cw <= 0) the sun has no place; just in front of it the place is far outside the screen. `front` is the cosine of
    // the angle to the viewing direction when the projection is symmetric, so it fades the sun out as it passes the camera's side.
    if (!(cw > 1e-5f)) {
        if (uv) *uv = Vec2{0.5f, 0.5f};
        if (fade) *fade = 0.0f;
        return true;
    }
    const float nx = cx / cw, ny = cy / cw;
    if (uv) *uv = Vec2{nx * 0.5f + 0.5f, 0.5f - ny * 0.5f};
    if (fade) {
        const float edge = std::max(std::fabs(nx), std::fabs(ny));
        const float onScreen = 1.0f - smooth(1.0f, 1.6f, edge);  // full on the screen, gone a little way outside it
        const float front = smooth(0.0f, 0.15f, cw / std::max(std::fabs(P.at(2, 3)), 1e-6f));
        *fade = onScreen * front;
    }
    return true;
}

FogFxPlan make_fog_plan(const CameraGeometry& cam, const PostStack& stack, bool linear, const Vec3* towardSun) {
    FogFxPlan p;
    const PostProcess& f = stack.fx;
    p.linearScene = linear;
    if (fog_has_effect(stack)) {
        const Color c = to_scene(f.fogColor, linear);
        to_array(c, p.color);
        p.density = std::clamp(finite_or(f.fogDensity, 0.0f), 0.0f, 10.0f);
        p.start = std::clamp(finite_or(f.fogStart, 0.0f), 0.0f, 100000.0f);
        p.heightDensity = std::clamp(finite_or(f.fogHeightDensity, 0.0f), 0.0f, 10.0f);
        p.heightBase = std::clamp(finite_or(f.fogHeightBase, 0.0f), -kMaxWorld, kMaxWorld);
        p.heightFalloff = std::clamp(finite_or(f.fogHeightFalloff, 0.1f), 0.0f, 10.0f);
        p.ortho = !cam.perspective;
        const Mat4& P = cam.proj;
        const float terms[8] = {P.at(0, 0), P.at(1, 1), P.at(2, 0), P.at(2, 1),
                                P.at(3, 0), P.at(3, 1), P.at(2, 3), P.at(3, 3)};
        bool ok = std::fabs(terms[0]) > 1e-12f && std::fabs(terms[1]) > 1e-12f;
        for (int i = 0; i < 8; ++i) {
            ok = ok && std::isfinite(terms[i]);
            p.proj[i] = terms[i];
        }
        p.eye = cam.position;
        p.axisY[0] = cam.right.y;
        p.axisY[1] = cam.up.y;
        p.axisY[2] = cam.forward.y;
        for (float a : p.axisY) ok = ok && std::isfinite(a);
        ok = ok && std::isfinite(p.eye.y);
        p.fog = ok && (p.density > 0.0f || p.heightDensity > 0.0f);
    }
    if (towardSun && shafts_has_effect(stack)) {
        Vec2 uv{0.5f, 0.5f};
        float fade = 0.0f;
        if (sun_screen_position(cam, *towardSun, &uv, &fade) && fade > 0.0f) {
            p.sunUv[0] = uv.x;
            p.sunUv[1] = uv.y;
            p.intensity = std::clamp(finite_or(f.sunShaftsIntensity, 0.0f), 0.0f, 2.0f) * fade;
            p.threshold = std::clamp(finite_or(f.sunShaftsThreshold, 0.8f), 0.0f, 20.0f);
            p.reach = std::clamp(finite_or(f.sunShaftsLength, 0.5f), 0.0f, 1.0f);
            to_array(to_scene(f.sunShaftsColor, linear), p.tint);
            p.shafts = p.intensity > 0.0f && p.reach > 0.0f;
        }
    }
    return p;
}

bool FogFx::ready(Prog prog) {
    int& st = state_[int(prog)];
    if (st != 0) return st > 0;
    const sg_backend backend = sg_query_backend();
    sg_shader s{};
    const char* what = "fog";
    switch (prog) {
        case Prog::Fog: s = make_shader(fog_fog_shader_desc(backend), "fog_fog"); break;
        case Prog::Rays:
            what = "sun shafts";
            s = make_shader(sun_shafts_rays_shader_desc(backend), "sun_shafts_rays");
            break;
        default:
            what = "sun shafts";
            s = make_shader(sun_shafts_add_shader_desc(backend), "sun_shafts_add");
            break;
    }
    if (sg_query_shader_state(s) != SG_RESOURCESTATE_VALID) {
        if (s.id) sg_destroy_shader(s);
        st = -1;
        FA_ERROR("render",
                 "The {} effect is unavailable: its shader failed to compile for this graphics backend (see the sokol "
                 "log lines "
                 "above). The game renders without it. Hint: update the graphics driver (Mesa: try "
                 "LIBGL_ALWAYS_SOFTWARE=1) or turn "
                 "fogEnabled and sunShaftsEnabled off.",
                 what);
        return false;
    }
    shaders_[int(prog)] = s;
    st = 1;
    return true;
}

sg_pipeline FogFx::pipeline(Prog prog, const TargetFormat& format) {
    for (const PipelineEntry& e : pipelines_)
        if (e.prog == prog && e.format == format) return e.pipeline;
    if (state_[int(prog)] <= 0) return {};
    sg_pipeline_desc d{};
    d.shader = shaders_[int(prog)];
    d.layout.attrs[0].format = SG_VERTEXFORMAT_FLOAT2;  // `pos`, location 0 in every program
    d.depth.compare = SG_COMPAREFUNC_ALWAYS;
    d.depth.write_enabled = false;
    d.depth.pixel_format = format.depth;
    d.colors[0].pixel_format = format.color;
    d.sample_count = format.samples;
    d.face_winding = SG_FACEWINDING_CCW;
    if (prog == Prog::Fog || prog == Prog::Add) {
        // Fog: the premultiplied "over" (fogColor * f + scene * (1 - f)); the shafts: scene + rays. Neither touches the alpha of the picture.
        d.colors[0].blend.enabled = true;
        d.colors[0].blend.src_factor_rgb = SG_BLENDFACTOR_ONE;
        d.colors[0].blend.dst_factor_rgb = prog == Prog::Fog ? SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA : SG_BLENDFACTOR_ONE;
        d.colors[0].blend.src_factor_alpha = SG_BLENDFACTOR_ZERO;
        d.colors[0].blend.dst_factor_alpha = SG_BLENDFACTOR_ONE;
    }
    d.label = prog == Prog::Fog ? "fog-blend" : prog == Prog::Rays ? "shafts-rays" : "shafts-add";
    const sg_pipeline p = sg_make_pipeline(&d);
    if (sg_query_pipeline_state(p) != SG_RESOURCESTATE_VALID)
        FA_ERROR("render", "failed to create pipeline '{}'", d.label);
    pipelines_.push_back({prog, format, p});
    return p;
}

void FogFx::forget_targets() {
    failed_.clear();
    warnedTargets_ = false;
}

void FogFx::release() {
    for (PipelineEntry& e : pipelines_)
        if (e.pipeline.id) sg_destroy_pipeline(e.pipeline);
    pipelines_.clear();
    for (sg_shader& s : shaders_) {
        if (s.id) sg_destroy_shader(s);
        s = {};
    }
    for (int& s : state_) s = 0;
    failed_.clear();
    warnedTargets_ = false;
}

// The pass callbacks capture uniform blocks by value, which are alignas(16): MSVC warns (C4324, an error under /WX) that each closure is
// padded, which is what alignas asks for.
#if defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable : 4324)
#endif
int FogFx::add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, const FogFxPlan& plan,
                      const PostRect& rectIn, int picW, int picH, ResourceId game, sg_view srcTex,
                      const BloomTarget& dst, const PrepassRef& prepass, int* drawCalls, const std::string& job) {
    if (!plan.any() || !prepass.valid()) return 0;
    const Rect rect = rect_of(rectIn, picW, picH);
    if (rect.w < 1 || rect.h < 1) return 0;
    const sg_pixel_format fmt = gpu.scene_format();
    const int rw = rect.w, rh = rect.h;
    const int hw = std::max(1, (rw + 1) / 2), hh = std::max(1, (rh + 1) / 2);
    const std::uint64_t shapeKey = (std::uint64_t(rw) << 40) ^ (std::uint64_t(rh) << 16) ^ std::uint64_t(fmt);
    bool doFog = plan.fog && ready(Prog::Fog);
    bool doShafts = plan.shafts && ready(Prog::Rays) && ready(Prog::Add);
    if (!doFog && !doShafts) return 0;

    // The half-resolution image of the rays: made now (and given back to the pool) so that a GPU that refuses it is one warning here, not a
    // pass that cannot run halfway through the frame.
    TransientDesc ha;
    ha.width = hw;
    ha.height = hh;
    ha.format = TargetFormat{SG_PIXELFORMAT_RGBA16F, SG_PIXELFORMAT_NONE, 1};
    ha.label = job + "/shafts-half";
    if (doShafts) {
        if (std::find(failed_.begin(), failed_.end(), shapeKey) != failed_.end()) {
            doShafts = false;
        } else {
            const std::uint64_t h = targets.pool.acquire(ha);
            if (h == 0) {
                if (failed_.size() >= kMaxFailed) failed_.erase(failed_.begin());
                failed_.push_back(shapeKey);
                doShafts = false;
                if (!warnedTargets_) {
                    warnedTargets_ = true;
                    FA_ERROR("render",
                             "Sun shafts: cannot create the intermediate image for a {}x{} camera; they are skipped. "
                             "Hint: turn them off, or "
                             "lower the render scale.",
                             rw, rh);
                }
            } else {
                targets.pool.release(h);
            }
        }
    }
    if (!doFog && !doShafts) return 0;

    int declared = 0;
    TransientTargets* tt = &targets;
    auto tex = [tt](const PassContext& c, ResourceId r) {
        const Target* t = tt->get(c.handle(r));
        return t ? t->texView : sg_view{};
    };
    auto add = [&](const char* name, std::vector<ResourceId> reads, std::vector<ResourceId> writes, auto&& fn) {
        GraphPass gp;
        gp.name = job + "/" + name;
        gp.reads = std::move(reads);
        gp.writes = std::move(writes);
        gp.execute = std::forward<decltype(fn)>(fn);
        graph.add_pass(std::move(gp));
        ++declared;
    };
    Gpu* g = &gpu;
    FogFx* self = this;
    const ResourceId pre = prepass.res;
    const PrepassRef prepassRef = prepass;
    const PostRectUv ruv = post_rect_uv(rectIn, picW, picH);
    const float gl = gpu.is_gl() ? 1.0f : 0.0f;
    // The pass that draws into the camera's rectangle of the picture, keeping what is there (both effects blend over it).
    const TargetFormat dstFormat{fmt, SG_PIXELFORMAT_NONE, dst.samples};
    auto into_picture = [dst, dstFormat](const char* label) {
        PassDesc pd;
        pd.label = label;
        pd.color = dst.att;
        pd.resolve = dst.resolve;  // id 0 when the pass does not resolve
        pd.format = dstFormat;
        pd.colorLoad = SG_LOADACTION_LOAD;
        pd.colorStore = SG_STOREACTION_STORE;
        return pd;
    };

    if (doFog) {
        fog_fog_params_t u{};
        u.a[0] = gl;
        u.a[1] = plan.ortho ? 1.0f : 0.0f;
        for (int i = 0; i < 3; ++i) u.col[i] = plan.color[i];
        u.col[3] = plan.density;
        u.d[0] = plan.start;
        u.d[1] = plan.heightDensity;
        u.d[2] = plan.heightBase;
        u.d[3] = plan.heightFalloff;
        for (int i = 0; i < 4; ++i) u.pa[i] = plan.proj[i];
        for (int i = 0; i < 4; ++i) u.pb[i] = plan.proj[4 + i];
        u.eye[0] = plan.eye.x;
        u.eye[1] = plan.eye.y;
        u.eye[2] = plan.eye.z;
        for (int i = 0; i < 3; ++i) u.ax[i] = plan.axisY[i];
        add("fog-blend", {pre, game}, {game}, [=](const PassContext& c) {
            const Target* pt = prepassRef.target(c);
            if (!pt) return;
            draw_fullscreen(*self, *g, Prog::Fog, into_picture("fog-blend"), sg_view{}, pt->texView, &u, sizeof(u),
                            rect.whole ? nullptr : &rect);
            ++*drawCalls;
        });
    }
    if (doShafts) {
        const ResourceId half = graph.create_transient(ha);
        sun_shafts_rays_params_t u{};
        u.a[0] = gl;
        u.a[1] = float(rw);
        u.a[2] = float(rh);
        u.a[3] = float(rw) / float(rh);
        u.rc[0] = ruv.x;
        u.rc[1] = ruv.y;
        u.rc[2] = ruv.w;
        u.rc[3] = ruv.h;
        u.b[0] = plan.sunUv[0];
        u.b[1] = plan.sunUv[1];
        u.b[2] = plan.reach;
        u.b[3] = plan.threshold;
        u.c[0] = 1.0f / std::max(1.0f - plan.threshold, 0.05f);
        u.c[1] = plan.linearScene ? 1.0f : 0.0f;
        u.c[2] = kGlowRate;
        sun_shafts_add_params_t ua{};
        for (int i = 0; i < 3; ++i) ua.tint[i] = plan.tint[i] * plan.intensity;
        add("shafts-rays", {game, pre}, {half}, [=](const PassContext& c) {
            const Target* pt = prepassRef.target(c);
            const Target* ht = tt->get(c.handle(half));
            if (!pt || !ht || !srcTex.id) return;
            PassDesc pd = pass_into(*ht, "shafts-rays");
            pd.colorLoad = SG_LOADACTION_DONTCARE;
            draw_fullscreen(*self, *g, Prog::Rays, pd, srcTex, pt->texView, &u, sizeof(u), nullptr);
            ++*drawCalls;
        });
        add("shafts-add", {half, game}, {game}, [=](const PassContext& c) {
            const sg_view rays = tex(c, half);
            if (!rays.id) return;
            draw_fullscreen(*self, *g, Prog::Add, into_picture("shafts-add"), rays, sg_view{}, &ua, sizeof(ua),
                            rect.whole ? nullptr : &rect);
            ++*drawCalls;
        });
    }
    return declared;
}
#if defined(_MSC_VER)
#pragma warning(pop)
#endif

}  // namespace fa::render
