#include "postprocess.h"

#include <algorithm>
#include <cmath>

#include "fa/core/log.h"

#include "shaders/exposure.glsl.h"
#include "shaders/post.glsl.h"

namespace fa::render {

namespace {

float finite_or(float v, float fallback) { return std::isfinite(v) ? v : fallback; }

template <class T>
void apply_uniforms(int slot, const T& u) {
    sg_range r{&u, sizeof(T)};
    sg_apply_uniforms(slot, &r);
}

constexpr float kMaxEv = 16.0f;      // +-16 stops: far beyond anything a display or a float target keeps
constexpr int kLumaSize = 32;        // the exposure measures the frame at 32x32 (exposure.glsl)
constexpr float kMaxSpeed = 100.0f;  // per second: 100 is "at once" at 60 fps

}  // namespace

BloomSettings bloom_from_stack(const PostStack& stack) {
    if (!stack.has(PostEffect::Bloom)) return {};
    const PostProcess& f = stack.fx;
    BloomSettings b = sanitize_bloom(true, f.bloomThreshold, f.bloomIntensity, f.bloomRadius, f.bloomScreenSpace);
    b.threshold =
        std::clamp(finite_or(f.bloomThreshold, b.threshold), 0.0f, 20.0f);  // above 1: HDR light of a linear scene
    b.knee = std::clamp(finite_or(f.bloomKnee, 0.0f), 0.0f, 1.0f);
    b.dirtIntensity = std::clamp(finite_or(f.bloomLensDirtIntensity, 1.0f), 0.0f, 10.0f);
    b.dirt = f.bloomLensDirt;
    return b;
}

PostPlan make_post_plan(const CameraInfo& cam, bool linear, std::uint64_t frame) {
    PostPlan p;
    p.bloom = cam.bloom;
    p.colorFilter = std::clamp(cam.colorFilter, 0, 5);
    if (!cam.postStack) return p;  // no stack: only what the bloom and the colour filter above say (both off then)
    const PostStack& s = *cam.postStack;
    const PostProcess& f = s.fx;
    if (s.has(PostEffect::Exposure)) {
        p.exposure = true;
        p.autoExposure = f.exposureMode == ExposureMode::Auto;
        p.exposureEv = std::clamp(finite_or(f.exposureEv, 0.0f), -kMaxEv, kMaxEv);
        float lo = std::clamp(finite_or(f.exposureMinEv, -4.0f), -kMaxEv, kMaxEv);
        float hi = std::clamp(finite_or(f.exposureMaxEv, 4.0f), -kMaxEv, kMaxEv);
        if (lo > hi) std::swap(lo, hi);
        p.minEv = lo;
        p.maxEv = hi;
        p.adaptationSpeed = std::clamp(finite_or(f.exposureAdaptationSpeed, 2.0f), 0.0f, kMaxSpeed);
    }
    if (s.has(PostEffect::Tonemap)) {
        p.tonemap = true;
        p.tonemapMode = std::clamp(int(f.tonemapMode), 0, 4);
    }
    p.fx = make_post_fx(s, frame);
    p.lut = p.fx.lut ? f.colorGradingLut : std::string();
    // A linear scene is converted (and encoded) by the final pass only when something needs it; otherwise the present copy encodes it.
    p.linear = linear && (p.exposure || p.tonemap || p.colorFilter != 0 || p.fx.any());
    return p;
}

namespace {

// The effects' uniforms (post.glsl, post_fx_params): the plan's PostFx laid out as the shader reads it.
post_post_fx_params_t fx_uniforms(const PostFx& fx, const LutInfo& lut, bool gl, int w, int h) {
    post_post_fx_params_t u{};
    const int mask = fx.mask();
    u.ex[0] = float(mask);
    u.ex[1] = gl ? 1.0f : 0.0f;
    u.ex[2] = float(w) / float(std::max(h, 1));
    u.ex[3] = float(fx.grainSeed);
    u.ln[0] = fx.lensK;
    u.ln[1] = fx.lensZoom;
    u.ln[2] = fx.lensCenter.x;
    u.ln[3] = fx.lensCenter.y;
    u.ab[0] = fx.aberrationAmount;
    u.ab[1] = fx.sharpenWeight;
    u.ab[2] = fx.lutContribution;
    u.ab[3] = fx.contrast;
    auto set = [](float* dst, Vec3 v, float w4) {
        dst[0] = v.x;
        dst[1] = v.y;
        dst[2] = v.z;
        dst[3] = w4;
    };
    set(u.wb, fx.whiteBalance, fx.saturation);
    set(u.lf, fx.lift, fx.hueA);
    set(u.gn, fx.gain, fx.hueB);
    set(u.ig, fx.invGamma, fx.hueC);
    u.vg[0] = fx.vignetteIntensity;
    u.vg[1] = fx.vignetteSmoothness;
    u.vg[2] = fx.vignetteRoundness;
    u.vg[3] = fx.grainIntensity * kGrainStrength;
    u.vc[0] = fx.vignetteCenter.x;
    u.vc[1] = fx.vignetteCenter.y;
    u.vc[2] = fx.grainSize;
    u.vc[3] = fx.grainResponse;
    set(u.vk, fx.vignetteColor, 0.0f);
    u.lt[0] = float(lut.size);
    u.lt[1] = float(lut.cols);
    u.lt[2] = float(lut.rows);
    return u;
}

}  // namespace

void run_post_pass(Gpu& gpu, const PostPlan& plan, bool finalPass, int filter, bool autoExposure, const PassDesc& pass,
                   sg_view src, sg_view expo, sg_view white, int w, int h, const OutputTarget& output) {
    // finalPass: the pass that converts and draws the effects; the colour-filter-only pass has neither.
    const bool convert = finalPass && plan.convert();
    PostFx fx = finalPass ? plan.fx : PostFx{};
    fx.lut = fx.lut && plan.lutInfo.view.id != 0;  // the table the renderer found (none: the effect is skipped)
    const bool lut = fx.lut;
    gpu.begin_pass(pass);
    sg_apply_pipeline(gpu.post_pipeline(pass.format));
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_post_tex] = src;
    b.views[VIEW_post_expo_tex] = expo;
    b.views[VIEW_post_lut_tex] = lut ? plan.lutInfo.view : white;
    b.samplers[SMP_post_smp] =
        gpu.sampler(SamplerKind::Nearest);  // the source has the size of the destination: texel for texel
    b.samplers[SMP_post_lin_smp] = gpu.sampler(SamplerKind::LinearClamp);  // the lens and the LUT
    sg_apply_bindings(&b);
    post_post_vs_params_t vu{};
    vu.flip[0] = gpu.is_gl() ? 1.0f : 0.0f;
    apply_uniforms(UB_post_post_vs_params, vu);
    post_post_params_t u{};
    u.p[0] = plan.linear ? 1.0f : 0.0f;
    u.p[1] = convert ? 1.0f : 0.0f;
    // The HDR tonemap only for a picture that stays as it is: a colour filter works on what an SDR screen shows (and clamps).
    const bool hdr = convert && filter == 0 && output.extended();
    u.p[2] = hdr ? 1.0f : 0.0f;
    u.p[3] = float(filter);
    u.q[0] = convert && plan.tonemap ? float(plan.tonemapMode) : 0.0f;
    u.q[1] = convert && plan.exposure ? std::exp2(plan.exposureEv) : 1.0f;
    u.q[2] = convert && plan.exposure && autoExposure ? 1.0f : 0.0f;
    u.q[3] = convert || fx.any() ? 1.0f / 255.0f : 0.0f;  // the dither: one 8-bit step of the display
    u.r[0] = float(w);
    u.r[1] = float(h);
    if (hdr) {
        const int mode = plan.tonemap ? plan.tonemapMode : 0;
        const HdrShoulder sh = hdr_shoulder(mode);
        u.h[0] = output.headroom;
        u.h[1] = sh.input;
        u.h[2] = sh.slope;
        u.h[3] = sh.start;
    }
    apply_uniforms(UB_post_post_params, u);
    apply_uniforms(UB_post_post_fx_params, fx_uniforms(fx, plan.lutInfo, gpu.is_gl(), w, h));
    sg_draw(0, 3, 1);
    gpu.end_pass();
}

// ---- automatic exposure ------------------------------------------------------------------------------------------------------

bool AutoExposure::ensure_targets(Gpu& gpu) {
    if (failed_) return false;
    if (ev_[0].valid() && ev_[1].valid()) return true;
    for (Target& t : ev_) destroy_target(t);
    TargetDesc d;
    d.label = "exposure-ev";
    d.width = d.height = 1;
    // 32-bit float where it renders and filters: a 16-bit EV stalls once prev + (target - prev) * k is under half a step of it (up to
    // ~0.06 EV short at a slow speed, and the more frames a second the shorter), so the adaptation would depend on the frame rate.
    const sg_pixelformat_info r32 = sg_query_pixelformat(SG_PIXELFORMAT_R32F);
    d.colorFormat = r32.render && r32.filter ? SG_PIXELFORMAT_R32F : gpu.scene_format();
    for (Target& t : ev_) t = make_target(d);
    if (!ev_[0].valid() || !ev_[1].valid()) {
        for (Target& t : ev_) destroy_target(t);
        failed_ = true;
        if (!warned_) {
            warned_ = true;
            FA_ERROR("render", "PostProcess.exposureMode auto: cannot create the 1x1 exposure target; the exposure "
                               "stays at exposureEv. "
                               "Hint: set exposureMode to manual.");
        }
        return false;
    }
    fresh_ = true;
    return true;
}

void AutoExposure::release() {
    for (Target& t : ev_) destroy_target(t);
    fresh_ = true;
    failed_ = false;
    declaredBefore_ = false;
    cur_ = 0;
}

#if defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable : 4324)  // the closures hold alignas(16) uniform blocks
#endif
ResourceId AutoExposure::add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, const PostPlan& plan,
                                    ResourceId game, sg_view srcTex, float dt, std::uint64_t serial, int* drawCalls,
                                    const std::string& job) {
    if (!plan.exposure || !plan.autoExposure) return {};
    const sg_pixel_format fmt = gpu.scene_format();
    if (fmt != SG_PIXELFORMAT_RGBA16F) {
        if (!warned_) {
            warned_ = true;
            FA_WARN("render",
                    "PostProcess.exposureMode auto needs a float render target and this GPU draws the game in {}: the "
                    "exposure "
                    "stays at exposureEv. Hint: set exposureMode to manual",
                    fmt == SG_PIXELFORMAT_RGBA8 ? "RGBA8" : "a format without it");
        }
        return {};
    }
    if (!gpu.exposure_ready() || !ensure_targets(gpu)) return {};
    // The 32x32 level of the measure: made here once, so that a GPU that cannot is one warning and the exposure stays manual.
    TransientDesc ld;
    ld.width = ld.height = kLumaSize;
    ld.format = TargetFormat{fmt, SG_PIXELFORMAT_NONE, 1};
    ld.label = "exposure-luma";
    {
        const std::uint64_t h = targets.pool.acquire(ld);
        if (h == 0) {
            failed_ = true;
            if (!warned_) {
                warned_ = true;
                FA_ERROR(
                    "render",
                    "PostProcess.exposureMode auto: cannot create the 32x32 measuring target; the exposure stays at "
                    "exposureEv. Hint: set exposureMode to manual.");
            }
            return {};
        }
        targets.pool.release(h);
    }

    // First frame, new targets or a gap (the exposure was off for a frame): take the measured value at once.
    const bool reset = fresh_ || !declaredBefore_ || lastSerial_ + 1 != serial;
    fresh_ = false;
    declaredBefore_ = true;
    lastSerial_ = serial;

    const int prev = cur_, next = 1 - cur_;
    const ResourceId prevRes = graph.import_target(job + "/exposure-ev-" + std::to_string(prev), ev_[prev].color.id,
                                                   TransientDesc{1, 1, ev_[prev].format, "exposure-ev"});
    const ResourceId nextRes = graph.import_target(job + "/exposure-ev-" + std::to_string(next), ev_[next].color.id,
                                                   TransientDesc{1, 1, ev_[next].format, "exposure-ev"});
    const ResourceId luma = graph.create_transient(ld);
    TransientTargets* tt = &targets;
    Gpu* g = &gpu;
    AutoExposure* self = this;
    const std::string prefix = job.empty() ? std::string() : job + "/";

    {
        GraphPass p;
        p.name = prefix + "exposure-luma";
        p.reads = {game};
        p.writes = {luma};
        exposure_exposure_luma_params_t u{};
        u.p[0] = plan.linear ? 1.0f : 0.0f;
        u.p[1] = 1.0f / float(kLumaSize);
        u.p[2] = 1.0f / float(kLumaSize);
        p.execute = [=](const PassContext& c) {
            const Target* t = tt->get(c.handle(luma));
            if (!t) return;
            PassDesc pd = pass_into(*t, "exposure-luma");
            pd.colorLoad = SG_LOADACTION_DONTCARE;  // every texel is drawn
            g->begin_pass(pd);
            sg_apply_pipeline(g->exposure_pipeline(ExposureStage::Luma, pd.format));
            sg_bindings b{};
            b.vertex_buffers[0] = g->fullscreen_triangle();
            b.views[VIEW_exposure_tex] = srcTex;
            b.samplers[SMP_exposure_smp] = g->sampler(SamplerKind::LinearClamp);
            sg_apply_bindings(&b);
            exposure_exposure_vs_params_t vu{};
            vu.flip[0] = g->is_gl() ? 1.0f : 0.0f;
            apply_uniforms(UB_exposure_exposure_vs_params, vu);
            apply_uniforms(UB_exposure_exposure_luma_params, u);
            sg_draw(0, 3, 1);
            g->end_pass();
            ++*drawCalls;
        };
        graph.add_pass(std::move(p));
    }
    {
        GraphPass p;
        p.name = prefix + "exposure-adapt";
        p.reads = {luma, prevRes};
        p.writes = {nextRes};
        exposure_exposure_adapt_params_t u{};
        u.p[0] = std::clamp(finite_or(dt, 0.0f), 0.0f, 1.0f);
        u.p[1] = plan.adaptationSpeed;
        u.p[2] = plan.minEv;
        u.p[3] = plan.maxEv;
        u.q[0] = reset ? 1.0f : 0.0f;
        p.execute = [=](const PassContext& c) {
            const Target* lt = tt->get(c.handle(luma));
            if (!lt) return;
            Target& dst = self->ev_[next];
            PassDesc pd = pass_into(dst, "exposure-adapt");
            pd.colorLoad = SG_LOADACTION_DONTCARE;
            g->begin_pass(pd);
            sg_apply_pipeline(g->exposure_pipeline(ExposureStage::Adapt, pd.format));
            sg_bindings b{};
            b.vertex_buffers[0] = g->fullscreen_triangle();
            b.views[VIEW_exposure_luma_tex] = lt->texView;
            b.views[VIEW_exposure_prev_tex] = self->ev_[prev].texView;
            b.samplers[SMP_exposure_smp] = g->sampler(SamplerKind::LinearClamp);
            sg_apply_bindings(&b);
            exposure_exposure_vs_params_t vu{};
            vu.flip[0] = g->is_gl() ? 1.0f : 0.0f;
            apply_uniforms(UB_exposure_exposure_vs_params, vu);
            apply_uniforms(UB_exposure_exposure_adapt_params, u);
            sg_draw(0, 3, 1);
            g->end_pass();
            ++*drawCalls;
            self->cur_ = next;  // the next frame reads what this one wrote
        };
        graph.add_pass(std::move(p));
    }
    return nextRes;
}
#if defined(_MSC_VER)
#pragma warning(pop)
#endif

}  // namespace fa::render
