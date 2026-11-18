#include "renderer_dof.h"

#include <algorithm>
#include <cmath>
#include <memory>

#include "fa/core/log.h"

#include "postprocess.h"
#include "postprocess_resolve.h"
#include "shader_cache.h"
#include "shaders/dof.glsl.h"
#include "shaders/motion_blur.glsl.h"

namespace fa::render {

namespace {

float finite_or(float v, float fallback) { return std::isfinite(v) ? v : fallback; }

constexpr float kMaxBlurDesignPx = 32.0f;  // the range of depthOfFieldNearBlur / FarBlur
constexpr float kMinFocus = 0.01f;
constexpr float kMaxFocus = 100000.0f;
constexpr std::size_t kMaxFailed = 16;

// The slots every program of the two modules uses: the shaders declare them in the same order (a static_assert keeps the two in step).
static_assert(UB_dof_dof_vs_params == 0 && UB_dof_dof_params == 1, "the dof program uniform slots");
static_assert(UB_motion_blur_motion_vs_params == 0, "the motion blur program uniform slots (vertex)");
static_assert(UB_motion_blur_motion_params == 1, "the motion blur program uniform slots (fragment)");
static_assert(VIEW_dof_tex_c == 0 && VIEW_dof_tex_p == 1 && VIEW_dof_tex_g == 2, "the dof program view slots");
static_assert(VIEW_motion_blur_tex_c == 0, "the motion blur program first view slot");
static_assert(VIEW_motion_blur_tex_p == 1, "the motion blur program second view slot");
static_assert(SMP_dof_smp_lin == 0 && SMP_dof_smp_pt == 1, "the dof program sampler slots");
static_assert(SMP_motion_blur_smp_lin == 0, "the motion blur program linear sampler slot");
static_assert(SMP_motion_blur_smp_pt == 1, "the motion blur program point sampler slot");

template <class T>
void apply_uniforms(int slot, const T& u) {
    sg_range r{&u, sizeof(T)};
    sg_apply_uniforms(slot, &r);
}

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

// One full-screen triangle with `prog` into the pass `pd`. `tc`, `tp`, `tg`: the colour, prepass and blur images the program declares
// (the others are not bound: a binding a program does not use is a validation error). `fu`: the program's uniform block (null: none).
// `part`: the rectangle of the destination the pass covers (null: all of it).
// Returns false (nothing drawn) when the target of the pass is gone.
bool draw_fullscreen(SceneFx& fx, Gpu& gpu, SceneFx::Prog prog, const PassDesc& pd, sg_view tc, sg_view tp, sg_view tg,
                     const void* fu, std::size_t fuSize, const Rect* part) {
    if (!pd.color.id) return false;
    Gpu::begin_pass(pd);
    if (part) {
        sg_apply_viewport(part->x, part->y, part->w, part->h, true);
        sg_apply_scissor_rect(part->x, part->y, part->w, part->h, true);
    }
    sg_apply_pipeline(fx.pipeline(prog, pd.format));
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    const bool useC = prog != SceneFx::Prog::Gather;
    const bool useP = prog == SceneFx::Prog::Down || prog == SceneFx::Prog::Composite || prog == SceneFx::Prog::Motion;
    const bool useG = prog == SceneFx::Prog::Gather || prog == SceneFx::Prog::Composite;
    if (useC) b.views[0] = tc;
    if (useP) b.views[1] = tp;
    if (useG) b.views[2] = tg;
    b.samplers[0] = gpu.sampler(SamplerKind::LinearClamp);
    if (useP) b.samplers[1] = gpu.sampler(SamplerKind::Nearest);
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
    return true;
}

}  // namespace

float smooth_focus(float current, float target, float speed, float dt) {
    if (!std::isfinite(target)) return current;
    if (!std::isfinite(current)) return target;
    if (!(speed > 0.0f) || !(dt > 0.0f) || !std::isfinite(speed) || !std::isfinite(dt)) return current;
    const float k = 1.0f - std::exp(-std::min(speed * dt, 50.0f));
    return current + (target - current) * k;
}

int dof_gather_taps(float radiusHalfPx) {
    const float r = std::clamp(finite_or(radiusHalfPx, 0.0f), 0.0f, 64.0f);
    return std::clamp(int(std::ceil(4.0f * r + 8.0f)), 8, 64);
}

SceneFxPlan SceneFx::plan(World& world, const CameraInfo& cam, const PostStack& stack, std::uint64_t camKey,
                          std::uint64_t serial, float dt, float designScale, const Mat4& prevViewProj, bool prevValid) {
    // A camera that did not ask for two frames is forgotten: it focuses from its target again when it comes back.
    for (auto it = focus_.begin(); it != focus_.end();)
        it = it->second.frame + 1 < serial ? focus_.erase(it) : std::next(it);
    SceneFxPlan p;
    const PostProcess& f = stack.fx;
    const float scale = std::clamp(finite_or(designScale, 1.0f), 0.01f, 64.0f);
    if (stack.has(PostEffect::DepthOfField)) {
        p.nearPx = std::clamp(finite_or(f.depthOfFieldNearBlur, 0.0f), 0.0f, kMaxBlurDesignPx) * scale;
        p.farPx = std::clamp(finite_or(f.depthOfFieldFarBlur, 0.0f), 0.0f, kMaxBlurDesignPx) * scale;
        const float base = std::clamp(finite_or(f.depthOfFieldFocusDistance, 10.0f), kMinFocus, kMaxFocus);
        // The autofocus: the view depth of the target, when it is in front of the camera.
        float wanted = base;
        bool follow = false;
        if (f.depthOfFieldTarget != kNullEntity && world.alive(f.depthOfFieldTarget)) {
            const Vec3 v = cam.view.transform_point(world.world_position(f.depthOfFieldTarget));
            const float depth = -v.z;
            if (std::isfinite(depth) && depth > kMinFocus) {
                wanted = std::min(depth, kMaxFocus);
                follow = true;
            }
        }
        Focus& st = focus_[camKey];
        if (follow && st.frame != 0 && st.frame + 1 == serial)
            st.distance = smooth_focus(st.distance, wanted,
                                       std::clamp(finite_or(f.depthOfFieldFocusSpeed, 5.0f), 0.0f, 100.0f), dt);
        else
            st.distance =
                wanted;  // no target (or a first frame, or a gap): the focus is where it is asked to be at once
        st.frame = serial;
        p.focus = st.distance;
        p.halfRange = std::clamp(finite_or(f.depthOfFieldFocusRange, 5.0f), 0.0f, 100000.0f) * 0.5f;
        p.nearRamp = std::max(p.focus - p.halfRange, 0.25f);
        p.farRamp = std::max(p.focus, 0.5f);
        p.bokeh = f.depthOfFieldBokeh;
        p.dof = std::max(p.nearPx, p.farPx) >= 0.25f;
    }
    if (stack.has(PostEffect::MotionBlur) && prevValid) {
        p.shutter = std::clamp(finite_or(f.motionBlurIntensity, 0.5f), 0.0f, 1.0f);
        p.motionTaps = std::clamp(int(f.motionBlurSamples), 4, 32);
        // A view-space position of this frame -> the clip position of the frame before. (viewProj)^-1 * proj = view^-1, whatever the
        // depth range of the matrices (a backend's), which only the z row of the clip position sees.
        const Mat4 invView = cam.view.inverse();
        p.prevFromView = prevViewProj * invView;
        const Mat4& P = cam.proj;
        const float terms[8] = {P.at(0, 0), P.at(1, 1), P.at(2, 0), P.at(2, 1),
                                P.at(3, 0), P.at(3, 1), P.at(2, 3), P.at(3, 3)};
        bool finite = std::isfinite(P.at(0, 0)) && std::fabs(P.at(0, 0)) > 1e-12f && std::fabs(P.at(1, 1)) > 1e-12f;
        for (float t : terms) finite = finite && std::isfinite(t);
        for (int i = 0; i < 16; ++i) finite = finite && std::isfinite(p.prevFromView.m[i]);
        for (int i = 0; i < 8; ++i) p.proj[i] = terms[i];
        p.motion = finite && p.shutter > 0.0f;
    }
    return p;
}

float SceneFx::focus_of(std::uint64_t camKey) const {
    const auto it = focus_.find(camKey);
    return it == focus_.end() ? std::nanf("") : it->second.distance;
}

bool SceneFx::ready() {
    if (state_ != 0) return state_ > 0;
    const sg_backend backend = sg_query_backend();
    shaders_[int(Prog::Down)] = make_shader(dof_down_shader_desc(backend), "dof_down");
    shaders_[int(Prog::Gather)] = make_shader(dof_gather_shader_desc(backend), "dof_gather");
    shaders_[int(Prog::Composite)] = make_shader(dof_composite_shader_desc(backend), "dof_composite");
    shaders_[int(Prog::Copy)] = make_shader(dof_copy_shader_desc(backend), "dof_copy");
    shaders_[int(Prog::Motion)] = make_shader(motion_blur_motion_shader_desc(backend), "motion_blur_motion");
    bool ok = true;
    for (sg_shader s : shaders_) ok = ok && sg_query_shader_state(s) == SG_RESOURCESTATE_VALID;
    if (!ok) {
        for (sg_shader& s : shaders_) {
            if (s.id) sg_destroy_shader(s);
            s = {};
        }
        state_ = -1;
        FA_ERROR("render",
                 "Depth of field and motion blur are unavailable: their shaders failed to compile for this graphics "
                 "backend (see the "
                 "sokol log lines above). The game renders without them. Hint: update the graphics driver (Mesa: try "
                 "LIBGL_ALWAYS_SOFTWARE=1) or turn depthOfFieldEnabled and motionBlurEnabled off.");
        return false;
    }
    state_ = 1;
    return true;
}

sg_pipeline SceneFx::pipeline(Prog prog, const TargetFormat& format) {
    for (const PipelineEntry& e : pipelines_)
        if (e.prog == prog && e.format == format) return e.pipeline;
    if (state_ <= 0) return {};
    sg_pipeline_desc d{};
    d.shader = shaders_[int(prog)];
    d.layout.attrs[0].format = SG_VERTEXFORMAT_FLOAT2;  // `pos`, location 0 in every program
    d.depth.compare = SG_COMPAREFUNC_ALWAYS;
    d.depth.write_enabled = false;
    d.depth.pixel_format = format.depth;
    d.colors[0].pixel_format = format.color;
    d.sample_count = format.samples;
    d.face_winding = SG_FACEWINDING_CCW;
    d.label = prog == Prog::Down        ? "dof-down"
              : prog == Prog::Gather    ? "dof-gather"
              : prog == Prog::Composite ? "dof-composite"
              : prog == Prog::Copy      ? "dof-copy"
                                        : "motion-blur";
    const sg_pipeline p = sg_make_pipeline(&d);
    if (sg_query_pipeline_state(p) != SG_RESOURCESTATE_VALID)
        FA_ERROR("render", "failed to create pipeline '{}'", d.label);
    pipelines_.push_back({prog, format, p});
    return p;
}

void SceneFx::forget_targets() {
    failed_.clear();
    probed_.clear();
    warnedTargets_ = false;
}

void SceneFx::release() {
    for (PipelineEntry& e : pipelines_)
        if (e.pipeline.id) sg_destroy_pipeline(e.pipeline);
    pipelines_.clear();
    for (sg_shader& s : shaders_) {
        if (s.id) sg_destroy_shader(s);
        s = {};
    }
    state_ = 0;
    focus_.clear();
    failed_.clear();
    probed_.clear();
    warnedTargets_ = false;
}

// The pass callbacks capture uniform blocks by value, which are alignas(16): MSVC warns (C4324, an error under /WX) that each closure is
// padded, which is what alignas asks for.
#if defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable : 4324)
#endif
int SceneFx::add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, const SceneFxPlan& plan,
                        const PostRect& rectIn, int picW, int picH, ResourceId game, sg_view srcTex,
                        const BloomTarget& dst, const PrepassRef& prepass, int* drawCalls, const std::string& job) {
    if (!plan.any() || !prepass.valid()) return 0;
    const Rect rect = rect_of(rectIn, picW, picH);
    if (rect.w < 1 || rect.h < 1) return 0;
    if (!ready()) return 0;
    const sg_pixel_format fmt = gpu.scene_format();
    const int rw = rect.w, rh = rect.h;
    // Half size rounded up: with an odd size the last half-size texel covers one picture pixel and a half-texel offset of the linear
    // read is below the blur's own radius (the gather runs in this image only).
    const int hw = std::max(1, (rw + 1) / 2), hh = std::max(1, (rh + 1) / 2);
    // The size, the format and whether the two half-size images are part of it: a motion-blur-only frame must not hide (or be hidden
    // by) the failure of the depth-of-field images of the same size.
    const std::uint64_t shapeKey =
        (std::uint64_t(rw) << 40) ^ (std::uint64_t(rh) << 16) ^ std::uint64_t(fmt) ^ (plan.dof ? (1ull << 63) : 0ull);

    // The scratch image of the picture's format and, for the blur, two RGBA16F images of half the size (the circle of confusion is signed:
    // it needs a float alpha). Make sure the GPU can have them all at once, so a failure is one warning here and not a pass that cannot run
    // halfway through the frame. The pool keeps what it made.
    TransientDesc sd;
    sd.width = rw;
    sd.height = rh;
    sd.format = TargetFormat{fmt, SG_PIXELFORMAT_NONE, 1};
    sd.label = job + "/fx-scratch";
    TransientDesc ha;
    ha.width = hw;
    ha.height = hh;
    ha.format = TargetFormat{SG_PIXELFORMAT_RGBA16F, SG_PIXELFORMAT_NONE, 1};
    ha.label = job + "/dof-half-a";
    TransientDesc hb = ha;
    hb.label = job + "/dof-half-b";
    const bool alreadyFailed = std::find(failed_.begin(), failed_.end(), shapeKey) != failed_.end();
    if (alreadyFailed) return 0;
    if (std::find(probed_.begin(), probed_.end(), shapeKey) == probed_.end()) {  // once per shape, not every frame
        std::vector<std::uint64_t> held;
        bool ok = true;
        for (const TransientDesc* d : {&sd, &ha, &hb}) {
            if (d != &sd && !plan.dof) break;
            const std::uint64_t h = targets.pool.acquire(*d);
            if (h == 0) {
                ok = false;
                break;
            }
            held.push_back(h);
        }
        for (std::uint64_t h : held) targets.pool.release(h);
        if (!ok) {
            if (failed_.size() >= kMaxFailed) failed_.erase(failed_.begin());
            failed_.push_back(shapeKey);
            if (!warnedTargets_) {
                warnedTargets_ = true;
                FA_ERROR("render",
                         "Depth of field and motion blur: cannot create the intermediate targets for a {}x{} camera; "
                         "they are skipped. "
                         "Hint: turn them off, or lower the render scale.",
                         rw, rh);
            }
            return 0;
        }
        if (probed_.size() >= kMaxFailed) probed_.erase(probed_.begin());
        probed_.push_back(shapeKey);
    }

    const ResourceId scratch = graph.create_transient(sd);
    ResourceId halfA, halfB;
    if (plan.dof) {
        halfA = graph.create_transient(ha);
        halfB = graph.create_transient(hb);
    }
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
    SceneFx* self = this;
    const ResourceId pre = prepass.res;
    const PrepassRef prepassRef = prepass;
    const PostRectUv ruv = post_rect_uv(rectIn, picW, picH);
    const float gl = gpu.is_gl() ? 1.0f : 0.0f;
    // What a pass that draws a whole transient does (every pixel, no load), and what the one that writes into the picture does.
    auto into_scratch = [tt](const PassContext& c, ResourceId r, const char* label) {
        const Target* t = tt->get(c.handle(r));
        PassDesc pd = t ? pass_into(*t, label) : PassDesc{};
        pd.colorLoad = SG_LOADACTION_DONTCARE;
        return pd;
    };
    const TargetFormat dstFormat{fmt, SG_PIXELFORMAT_NONE, dst.samples};
    auto into_picture = [dst, dstFormat, rect](const char* label) {
        PassDesc pd;
        pd.label = label;
        pd.color = dst.att;
        pd.resolve = dst.resolve;  // id 0 when the pass does not resolve
        pd.format = dstFormat;
        pd.colorLoad = rect.whole && dst.samples <= 1 ? SG_LOADACTION_DONTCARE : SG_LOADACTION_LOAD;
        pd.colorStore = SG_STOREACTION_STORE;
        return pd;
    };
    // The chain's state: the scratch holds a finished result only when the pass before the copy ran.
    auto scratchReady = std::make_shared<bool>(false);

    if (plan.dof) {
        const float radius = std::max(plan.nearPx, plan.farPx) * 0.5f;  // in pixels of the half-resolution image
        dof_dof_params_t u{};
        u.a[0] = gl;
        u.a[1] = float(rw);
        u.a[2] = float(rh);
        u.rc[0] = ruv.x;
        u.rc[1] = ruv.y;
        u.rc[2] = ruv.w;
        u.rc[3] = ruv.h;
        u.c[0] = plan.focus;
        u.c[1] = plan.halfRange;
        u.c[2] = plan.nearPx;
        u.c[3] = plan.farPx;
        u.r[0] = plan.nearRamp;
        u.r[1] = plan.farRamp;
        u.r[2] = plan.bokeh ? 1.0f : 0.0f;
        u.r[3] = float(dof_gather_taps(radius));
        u.g[0] = std::max(radius, 0.5f);
        u.g[1] = float(hw);
        u.g[2] = float(hh);
        add("dof-down", {game, pre}, {halfA}, [=](const PassContext& c) {
            const Target* pt = prepassRef.target(c);
            if (!pt || !srcTex.id) return;
            if (draw_fullscreen(*self, *g, Prog::Down, into_scratch(c, halfA, "dof-down"), srcTex, pt->texView,
                                sg_view{}, &u, sizeof(u), nullptr))
                ++*drawCalls;
        });
        add("dof-gather", {halfA}, {halfB}, [=](const PassContext& c) {
            if (draw_fullscreen(*self, *g, Prog::Gather, into_scratch(c, halfB, "dof-gather"), sg_view{}, sg_view{},
                                tex(c, halfA), &u, sizeof(u), nullptr))
                ++*drawCalls;
        });
        add("dof-composite", {game, pre, halfB}, {scratch}, [=](const PassContext& c) {
            const Target* pt = prepassRef.target(c);
            if (!pt || !srcTex.id) return;
            if (!draw_fullscreen(*self, *g, Prog::Composite, into_scratch(c, scratch, "dof-composite"), srcTex,
                                 pt->texView, tex(c, halfB), &u, sizeof(u), nullptr))
                return;
            *scratchReady = true;
            ++*drawCalls;
        });
    }
    if (plan.motion) {
        const bool fromScratch = plan.dof;  // the blur drew its result into the scratch: the streaks read that
        motion_blur_motion_params_t u{};
        u.a[0] = gl;
        u.a[1] = float(rw);
        u.a[2] = float(rh);
        if (fromScratch) {
            u.rc[2] = u.rc[3] = 1.0f;  // the whole scratch
        } else {
            u.rc[0] = ruv.x;
            u.rc[1] = ruv.y;
            u.rc[2] = ruv.w;
            u.rc[3] = ruv.h;
        }
        u.b[0] = plan.shutter;
        u.b[1] = std::clamp(0.08f * float(std::max(rw, rh)), 8.0f, 128.0f);  // the longest streak, in pixels
        u.b[2] = float(plan.motionTaps);
        for (int i = 0; i < 4; ++i) u.pa[i] = plan.proj[i];
        for (int i = 0; i < 4; ++i) u.pb[i] = plan.proj[4 + i];
        for (int i = 0; i < 16; ++i) u.m[i] = plan.prevFromView.m[i];
        if (fromScratch) {
            // Reads the scratch the blur finished and draws straight into the picture: no copy after it.
            add("motion-blur", {scratch, pre, game}, {game}, [=](const PassContext& c) {
                const Target* pt = prepassRef.target(c);
                if (!pt || !*scratchReady) return;
                if (draw_fullscreen(*self, *g, Prog::Motion, into_picture("motion-blur"), tex(c, scratch), pt->texView,
                                    sg_view{}, &u, sizeof(u), rect.whole ? nullptr : &rect))
                    ++*drawCalls;
            });
        } else {
            add("motion-blur", {game, pre}, {scratch}, [=](const PassContext& c) {
                const Target* pt = prepassRef.target(c);
                if (!pt || !srcTex.id) return;
                if (!draw_fullscreen(*self, *g, Prog::Motion, into_scratch(c, scratch, "motion-blur"), srcTex,
                                     pt->texView, sg_view{}, &u, sizeof(u), nullptr))
                    return;
                *scratchReady = true;
                ++*drawCalls;
            });
        }
    }
    if (!(plan.motion && plan.dof)) {
        // The result is in the scratch: copy it into the camera's rectangle of the picture.
        add(plan.dof ? "dof-copy" : "motion-copy", {scratch, game}, {game}, [=](const PassContext& c) {
            if (!*scratchReady) return;
            if (draw_fullscreen(*self, *g, Prog::Copy, into_picture(plan.dof ? "dof-copy" : "motion-copy"),
                                tex(c, scratch), sg_view{}, sg_view{}, nullptr, 0, rect.whole ? nullptr : &rect))
                ++*drawCalls;
        });
    }
    return declared;
}
#if defined(_MSC_VER)
#pragma warning(pop)
#endif

}  // namespace fa::render
