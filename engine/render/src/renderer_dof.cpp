#include "renderer_dof.h"

#include <algorithm>
#include <cmath>
#include <memory>

#include "fa/core/log.h"

#include "postprocess.h"
#include "postprocess_resolve.h"
#include "fullscreen_gpu.h"
#include "shader_cache.h"
#include "shaders/dof.glsl.h"
#include "shaders/motion_blur.glsl.h"
#include "shaders/motion_object.glsl.h"

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
static_assert(UB_motion_object_mobj_vs_params == 0 && UB_motion_object_mobj_params == 1,
              "the per-object blur uniform slots");
static_assert(VIEW_motion_object_tex_c == 0 && VIEW_motion_object_tex_v == 1 && VIEW_motion_object_tex_p == 2 &&
                  VIEW_motion_object_tex_t == 3,
              "the per-object blur view slots");
static_assert(SMP_motion_object_smp_lin == 0 && SMP_motion_object_smp_pt == 1, "the per-object blur sampler slots");

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
bool draw_fullscreen(gpu::CommandList& list, SceneFx& fx, Gpu& gpu, SceneFx::Prog prog, const PassDesc& pd,
                     gpu::View tc, gpu::View tp, gpu::View tg, const void* fu, std::size_t fuSize, const Rect* part) {
    if (!pd.color.id) return false;
    const gpu::Pipeline pipe = fx.pipeline(prog, pd.format);  // made before the pass opens
    list.begin_pass(pd);
    if (part) {
        list.set_viewport(part->x, part->y, part->w, part->h, true);
        list.set_scissor(part->x, part->y, part->w, part->h, true);
    }
    list.set_pipeline(pipe);
    gpu::Bindings b;
    b.vertexBuffers[0] = gpu.fullscreen_triangle();
    const bool useC = prog != SceneFx::Prog::Gather;
    const bool useP = prog == SceneFx::Prog::Down || prog == SceneFx::Prog::Composite || prog == SceneFx::Prog::Motion;
    const bool useG = prog == SceneFx::Prog::Gather || prog == SceneFx::Prog::Composite;
    if (useC) b.views[0] = tc;
    if (useP) b.views[1] = tp;
    if (useG) b.views[2] = tg;
    b.samplers[0] = gpu.sampler(SamplerKind::LinearClamp);
    if (useP) b.samplers[1] = gpu.sampler(SamplerKind::Nearest);
    list.set_bindings(b);
    float flip[4] = {gpu.is_gl() ? 1.0f : 0.0f, 0.0f, 0.0f, 0.0f};
    list.set_uniforms(0, gpu::Range{flip, sizeof(flip)});
    if (fu) list.set_uniforms(1, gpu::Range{fu, fuSize});
    list.draw(0, 3, 1);
    list.end_pass();
    return true;
}

// One full-screen triangle with a program of the per-object blur: `views` are its texture slots (colour, V or the velocity, the prepass, the
// tiles; an empty one is not bound), `u` its uniforms. `part`: as draw_fullscreen. False (nothing drawn) when the target of the pass is gone.
bool draw_object_pass(gpu::CommandList& list, SceneFx& fx, Gpu& gpu, SceneFx::Prog prog, const PassDesc& pd,
                      const gpu::View (&views)[4], const motion_object_mobj_params_t& u, const Rect* part) {
    if (!pd.color.id) return false;
    const gpu::Pipeline pipe = fx.pipeline(prog, pd.format);  // made before the pass opens
    list.begin_pass(pd);
    if (part) {
        list.set_viewport(part->x, part->y, part->w, part->h, true);
        list.set_scissor(part->x, part->y, part->w, part->h, true);
    }
    list.set_pipeline(pipe);
    gpu::Bindings b;
    b.vertexBuffers[0] = gpu.fullscreen_triangle();
    for (int i = 0; i < 4; ++i) b.views[i] = views[i];
    b.samplers[SMP_motion_object_smp_lin] = gpu.sampler(SamplerKind::LinearClamp);
    b.samplers[SMP_motion_object_smp_pt] = gpu.sampler(SamplerKind::Nearest);
    list.set_bindings(b);
    float flip[4] = {gpu.is_gl() ? 1.0f : 0.0f, 0.0f, 0.0f, 0.0f};
    list.set_uniforms(0, gpu::Range{flip, sizeof(flip)});
    list.set_uniforms(1, gpu::Range{&u, sizeof(u)});
    list.draw(0, 3, 1);
    list.end_pass();
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
        p.objects = f.motionBlurMode == MotionBlurMode::Object;
        p.maxRadiusPx = std::clamp(finite_or(f.motionBlurMaxRadius, 24.0f), 1.0f, 64.0f) * scale;
        p.maxRadiusPx = std::clamp(p.maxRadiusPx, 1.0f, 128.0f);
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

bool SceneFx::ready(Gpu& gpu) {
    if (state_ != 0) return state_ > 0;
    device_ = &gpu.device();
    gpu::Device& dev = *device_;
    shaders_[int(Prog::Down)] = make_shader(dev, gpu::generated_shader_desc(dof_down_shader_desc), "dof_down");
    shaders_[int(Prog::Gather)] = make_shader(dev, gpu::generated_shader_desc(dof_gather_shader_desc), "dof_gather");
    shaders_[int(Prog::Composite)] =
        make_shader(dev, gpu::generated_shader_desc(dof_composite_shader_desc), "dof_composite");
    shaders_[int(Prog::Copy)] = make_shader(dev, gpu::generated_shader_desc(dof_copy_shader_desc), "dof_copy");
    shaders_[int(Prog::Motion)] =
        make_shader(dev, gpu::generated_shader_desc(motion_blur_motion_shader_desc), "motion_blur_motion");
    bool ok = true;
    for (int i = 0; i < int(Prog::ObjVel); ++i) ok = ok && dev.state(shaders_[i]) == gpu::ResourceState::Valid;
    if (!ok) {
        for (gpu::Shader& sh : shaders_) {
            if (sh.id) dev.destroy_shader(sh);
            sh = {};
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

bool SceneFx::ready_objects(Gpu& gpu) {
    if (objState_ != 0) return objState_ > 0;
    if (!ready(gpu)) {
        objState_ = -1;
        return false;
    }
    gpu::Device& dev = *device_;
    shaders_[int(Prog::ObjVel)] =
        make_shader(dev, gpu::generated_shader_desc(motion_object_vel_shader_desc), "motion_object_vel");
    shaders_[int(Prog::ObjTile)] =
        make_shader(dev, gpu::generated_shader_desc(motion_object_tile_shader_desc), "motion_object_tile");
    shaders_[int(Prog::ObjGather)] =
        make_shader(dev, gpu::generated_shader_desc(motion_object_gather_shader_desc), "motion_object_gather");
    bool ok = true;
    for (int i = int(Prog::ObjVel); i < int(Prog::Count); ++i)
        ok = ok && dev.state(shaders_[i]) == gpu::ResourceState::Valid;
    if (!ok) {
        for (int i = int(Prog::ObjVel); i < int(Prog::Count); ++i) {
            if (shaders_[i].id) dev.destroy_shader(shaders_[i]);
            shaders_[i] = {};
        }
        objState_ = -1;
        FA_ERROR(
            "render",
            "The per-object motion blur is unavailable: its shaders failed to compile for this graphics backend (see "
            "the sokol log lines above). The motion blur follows the camera's movement only. Hint: update the "
            "graphics driver, or set motionBlurMode to \"camera\".");
        return false;
    }
    objState_ = 1;
    return true;
}

gpu::Pipeline SceneFx::pipeline(Prog prog, const TargetFormat& format) {
    for (const PipelineEntry& e : pipelines_)
        if (e.prog == prog && e.format == format) return e.pipeline;
    if (state_ <= 0 || (prog >= Prog::ObjVel && objState_ <= 0) || !device_) return {};
    // `pos`, location 0 in every program.
    const char* label = prog == Prog::Down        ? "dof-down"
                        : prog == Prog::Gather    ? "dof-gather"
                        : prog == Prog::Composite ? "dof-composite"
                        : prog == Prog::Copy      ? "dof-copy"
                        : prog == Prog::ObjVel    ? "motion-velocity"
                        : prog == Prog::ObjTile   ? "motion-tile"
                                                  : "motion-blur";  // Prog::ObjGather
    const gpu::Pipeline p = make_triangle_pipeline(*device_, shaders_[int(prog)], format, label);
    if (device_->state(p) != gpu::ResourceState::Valid) FA_ERROR("render", "failed to create pipeline '{}'", label);
    pipelines_.push_back({prog, format, p});
    return p;
}

bool SceneFx::copy_into(gpu::CommandList& list, Gpu& gpu, const PassDesc& pd, gpu::View src, const int* part) {
    if (!ready(gpu) || !src.id) return false;
    Rect r;
    if (part) {
        r.x = part[0];
        r.y = part[1];
        r.w = part[2];
        r.h = part[3];
        r.whole = false;
    }
    return draw_fullscreen(list, *this, gpu, Prog::Copy, pd, src, gpu::View{}, gpu::View{}, nullptr, 0,
                           part ? &r : nullptr);
}

void SceneFx::forget_targets() {
    failed_.clear();
    probed_.clear();
    warnedTargets_ = false;
}

void SceneFx::release() {
    if (device_) {
        for (PipelineEntry& e : pipelines_)
            if (e.pipeline.id) device_->destroy_pipeline(e.pipeline);
        for (gpu::Shader& sh : shaders_)
            if (sh.id) device_->destroy_shader(sh);
    }
    pipelines_.clear();
    for (gpu::Shader& sh : shaders_) sh = {};
    state_ = 0;
    objState_ = 0;
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
                        const PostRect& rectIn, int picW, int picH, ResourceId game, gpu::View srcTex,
                        const BloomTarget& dst, const PrepassRef& prepass, const VelocityRef& velocity, int* drawCalls,
                        const std::string& job) {
    if (!plan.any() || !prepass.valid()) return 0;
    const Rect rect = rect_of(rectIn, picW, picH);
    if (rect.w < 1 || rect.h < 1) return 0;
    if (!ready(gpu)) return 0;
    const gpu::PixelFormat fmt = gpu.scene_format();
    const int rw = rect.w, rh = rect.h;
    // Half size rounded up: with an odd size the last half-size texel covers one picture pixel and a half-texel offset of the linear
    // read is below the blur's own radius (the gather runs in this image only).
    const int hw = std::max(1, (rw + 1) / 2), hh = std::max(1, (rh + 1) / 2);
    // The per-object blur needs the velocity image of the camera and its three programs; else the camera-only blur draws.
    bool objects = plan.motion && plan.objects && velocity.valid() && ready_objects(gpu);
    // The tiles: blocks of K x K pixels, K at least the farthest a pixel's blur reaches (the radius), so the 3 x 3 blocks around a pixel hold
    // every streak that can reach it.
    const int tileK = std::clamp(int(std::ceil(plan.maxRadiusPx)), 4, 128);
    const int ntx = (rw + tileK - 1) / tileK, nty = (rh + tileK - 1) / tileK;

    // The scratch image of the picture's format and, for the blur, two RGBA16F images of half the size (the circle of confusion is signed:
    // it needs a float alpha); for the per-object blur an RGBA16F image of the camera's size (the blur vector and the depth) and the two
    // images of blocks. Make sure the GPU can have them all at once, so a failure is one warning here and not a pass that cannot run
    // halfway through the frame. The pool keeps what it made.
    TransientDesc sd;
    sd.width = rw;
    sd.height = rh;
    sd.format = TargetFormat{fmt, gpu::PixelFormat::None, 1};
    sd.label = job + "/fx-scratch";
    TransientDesc ha;
    ha.width = hw;
    ha.height = hh;
    ha.format = TargetFormat{gpu::PixelFormat::Rgba16F, gpu::PixelFormat::None, 1};
    ha.label = job + "/dof-half-a";
    TransientDesc hb = ha;
    hb.label = job + "/dof-half-b";
    TransientDesc vd = ha;
    vd.width = rw;
    vd.height = rh;
    vd.label = job + "/motion-v";
    TransientDesc ta = ha;
    ta.width = ntx;
    ta.height = rh;
    ta.label = job + "/motion-tile-a";
    TransientDesc tb = ha;
    tb.width = ntx;
    tb.height = nty;
    tb.label = job + "/motion-tile-b";
    // The size, the format and whether the half-size images and the blur's images are part of it: a motion-blur-only frame must not hide (or
    // be hidden by) the failure of the depth-of-field images of the same size, nor the camera-only blur by the failure of the tiles.
    const auto shape_of = [&](bool obj) {
        return (std::uint64_t(rw) << 40) ^ (std::uint64_t(rh) << 16) ^ std::uint64_t(fmt) ^
               (plan.dof ? (1ull << 63) : 0ull) ^ (obj ? (1ull << 62) ^ (std::uint64_t(tileK) << 32) : 0ull);
    };
    // True when the images of the frame can be made (probed once per shape, not every frame).
    const auto probe = [&](bool obj) {
        const std::uint64_t shapeKey = shape_of(obj);
        if (std::find(failed_.begin(), failed_.end(), shapeKey) != failed_.end()) return false;
        if (std::find(probed_.begin(), probed_.end(), shapeKey) != probed_.end()) return true;
        std::vector<const TransientDesc*> wanted{&sd};
        if (plan.dof) wanted.insert(wanted.end(), {&ha, &hb});
        if (obj) wanted.insert(wanted.end(), {&vd, &ta, &tb});
        std::vector<std::uint64_t> held;
        bool ok = true;
        for (const TransientDesc* d : wanted) {
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
                         "{}. Hint: turn them off, or lower the render scale.",
                         rw, rh, obj ? "the motion blur follows the camera's movement only" : "they are skipped");
            }
            return false;
        }
        if (probed_.size() >= kMaxFailed) probed_.erase(probed_.begin());
        probed_.push_back(shapeKey);
        return true;
    };
    if (objects && !probe(true)) objects = false;
    if (!objects && !probe(false)) return 0;

    const ResourceId scratch = graph.create_transient(sd);
    ResourceId halfA, halfB, vImg, tileA, tileB;
    if (plan.dof) {
        halfA = graph.create_transient(ha);
        halfB = graph.create_transient(hb);
    }
    if (objects) {
        vImg = graph.create_transient(vd);
        tileA = graph.create_transient(ta);
        tileB = graph.create_transient(tb);
    }
    int declared = 0;
    TransientTargets* tt = &targets;
    auto tex = [tt](const PassContext& c, ResourceId r) {
        const Target* t = tt->get(c.handle(r));
        return t ? t->texView : gpu::View{};
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
    const VelocityRef velRef = velocity;
    const PostRectUv ruv = post_rect_uv(rectIn, picW, picH);
    const float gl = gpu.is_gl() ? 1.0f : 0.0f;
    // What a pass that draws a whole transient does (every pixel, no load), and what the one that writes into the picture does.
    auto into_scratch = [tt](const PassContext& c, ResourceId r, const char* label) {
        const Target* t = tt->get(c.handle(r));
        PassDesc pd = t ? pass_into(*t, label) : PassDesc{};
        pd.colorLoad = gpu::LoadAction::DontCare;
        return pd;
    };
    const TargetFormat dstFormat{fmt, gpu::PixelFormat::None, dst.samples};
    auto into_picture = [dst, dstFormat, rect](const char* label) {
        PassDesc pd;
        pd.label = label;
        pd.color = dst.att;
        pd.resolve = dst.resolve;  // id 0 when the pass does not resolve
        pd.format = dstFormat;
        pd.colorLoad = rect.whole && dst.samples <= 1 ? gpu::LoadAction::DontCare : gpu::LoadAction::Load;
        pd.colorStore = gpu::StoreAction::Store;
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
            if (draw_fullscreen(pass_list(c, *g), *self, *g, Prog::Down, into_scratch(c, halfA, "dof-down"), srcTex,
                                pt->texView, gpu::View{}, &u, sizeof(u), nullptr))
                ++*drawCalls;
        });
        add("dof-gather", {halfA}, {halfB}, [=](const PassContext& c) {
            if (draw_fullscreen(pass_list(c, *g), *self, *g, Prog::Gather, into_scratch(c, halfB, "dof-gather"),
                                gpu::View{}, gpu::View{}, tex(c, halfA), &u, sizeof(u), nullptr))
                ++*drawCalls;
        });
        add("dof-composite", {game, pre, halfB}, {scratch}, [=](const PassContext& c) {
            const Target* pt = prepassRef.target(c);
            if (!pt || !srcTex.id) return;
            if (!draw_fullscreen(pass_list(c, *g), *self, *g, Prog::Composite,
                                 into_scratch(c, scratch, "dof-composite"), srcTex, pt->texView, tex(c, halfB), &u,
                                 sizeof(u), nullptr))
                return;
            *scratchReady = true;
            ++*drawCalls;
        });
    }
    if (plan.motion && objects) {
        const bool fromScratch =
            plan.dof;  // the depth of field drew its result into the scratch: the gather reads that
        motion_object_mobj_params_t u{};
        u.a[0] = gl;
        u.a[1] = float(rw);
        u.a[2] = float(rh);
        u.a[3] = float(tileK);
        if (fromScratch) {
            u.rc[2] = u.rc[3] = 1.0f;  // the whole scratch
        } else {
            u.rc[0] = ruv.x;
            u.rc[1] = ruv.y;
            u.rc[2] = ruv.w;
            u.rc[3] = ruv.h;
        }
        u.b[0] = plan.shutter;
        u.b[1] = 2.0f * plan.maxRadiusPx;  // the longest streak (its blur reaches half of it on each side)
        u.b[2] = float(plan.motionTaps);
        u.e[1] = float(ntx);
        u.e[2] = float(nty);
        for (int i = 0; i < 4; ++i) u.pa[i] = plan.proj[i];
        for (int i = 0; i < 4; ++i) u.pb[i] = plan.proj[4 + i];
        for (int i = 0; i < 16; ++i) u.m[i] = plan.prevFromView.m[i];
        const auto velReady = std::make_shared<bool>(false);  // the blur vectors were drawn this frame
        add("motion-velocity", {velocity.res, pre}, {vImg}, [=](const PassContext& c) {
            const Target* vt = velRef.target(c);
            const Target* pt = prepassRef.target(c);
            if (!vt || !pt) return;
            const gpu::View views[4] = {gpu::View{}, vt->texView, pt->texView, gpu::View{}};
            if (!draw_object_pass(pass_list(c, *g), *self, *g, Prog::ObjVel, into_scratch(c, vImg, "motion-velocity"),
                                  views, u, nullptr))
                return;
            *velReady = true;
            ++*drawCalls;
        });
        add("motion-tile-x", {vImg}, {tileA}, [=](const PassContext& c) {
            if (!*velReady) return;
            motion_object_mobj_params_t ux = u;
            ux.e[0] = 0.0f;
            const gpu::View views[4] = {gpu::View{}, tex(c, vImg), gpu::View{}, gpu::View{}};
            if (draw_object_pass(pass_list(c, *g), *self, *g, Prog::ObjTile, into_scratch(c, tileA, "motion-tile-x"),
                                 views, ux, nullptr))
                ++*drawCalls;
        });
        add("motion-tile-y", {tileA}, {tileB}, [=](const PassContext& c) {
            if (!*velReady) return;
            motion_object_mobj_params_t uy = u;
            uy.e[0] = 1.0f;
            const gpu::View views[4] = {gpu::View{}, tex(c, tileA), gpu::View{}, gpu::View{}};
            if (draw_object_pass(pass_list(c, *g), *self, *g, Prog::ObjTile, into_scratch(c, tileB, "motion-tile-y"),
                                 views, uy, nullptr))
                ++*drawCalls;
        });
        if (fromScratch) {
            // Reads the scratch the depth of field finished and draws straight into the picture: no copy after it.
            add("motion-blur", {scratch, vImg, tileB, game}, {game}, [=](const PassContext& c) {
                if (!*velReady || !*scratchReady) return;
                const gpu::View views[4] = {tex(c, scratch), tex(c, vImg), gpu::View{}, tex(c, tileB)};
                if (draw_object_pass(pass_list(c, *g), *self, *g, Prog::ObjGather, into_picture("motion-blur"), views,
                                     u, rect.whole ? nullptr : &rect))
                    ++*drawCalls;
            });
        } else {
            add("motion-blur", {game, vImg, tileB}, {scratch}, [=](const PassContext& c) {
                if (!*velReady || !srcTex.id) return;
                const gpu::View views[4] = {srcTex, tex(c, vImg), gpu::View{}, tex(c, tileB)};
                if (!draw_object_pass(pass_list(c, *g), *self, *g, Prog::ObjGather,
                                      into_scratch(c, scratch, "motion-blur"), views, u, nullptr))
                    return;
                *scratchReady = true;
                ++*drawCalls;
            });
        }
    } else if (plan.motion) {
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
                if (draw_fullscreen(pass_list(c, *g), *self, *g, Prog::Motion, into_picture("motion-blur"),
                                    tex(c, scratch), pt->texView, gpu::View{}, &u, sizeof(u),
                                    rect.whole ? nullptr : &rect))
                    ++*drawCalls;
            });
        } else {
            add("motion-blur", {game, pre}, {scratch}, [=](const PassContext& c) {
                const Target* pt = prepassRef.target(c);
                if (!pt || !srcTex.id) return;
                if (!draw_fullscreen(pass_list(c, *g), *self, *g, Prog::Motion, into_scratch(c, scratch, "motion-blur"),
                                     srcTex, pt->texView, gpu::View{}, &u, sizeof(u), nullptr))
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
            if (draw_fullscreen(pass_list(c, *g), *self, *g, Prog::Copy,
                                into_picture(plan.dof ? "dof-copy" : "motion-copy"), tex(c, scratch), gpu::View{},
                                gpu::View{}, nullptr, 0, rect.whole ? nullptr : &rect))
                ++*drawCalls;
        });
    }
    return declared;
}
#if defined(_MSC_VER)
#pragma warning(pop)
#endif

}  // namespace fa::render
