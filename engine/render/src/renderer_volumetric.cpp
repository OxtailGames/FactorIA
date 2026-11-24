#include "renderer_volumetric.h"

#include <algorithm>
#include <cmath>
#include <cstring>

#include "fa/core/log.h"

#include "color_space.h"
#include "mesh_batch.h"
#include "postprocess.h"
#include "shader_cache.h"
#include "shaders/mesh.glsl.h"
#include "shaders/volumetric.glsl.h"

namespace fa::render {

namespace {

float finite_or(float v, float fallback) { return std::isfinite(v) ? v : fallback; }
bool finite3(float x, float y, float z) { return std::isfinite(x) && std::isfinite(y) && std::isfinite(z); }

constexpr std::size_t kMaxFailed = 16;

// The pass callbacks capture uniform blocks by value, which are alignas(16): MSVC warns (C4324, an error under /WX) that each closure is
// padded, which is what alignas asks for.
#if defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable : 4324)
#endif

static_assert(UB_volumetric_vol_vs_params == 0, "the volumetric vertex shader uses uniform slot 0");
static_assert(UB_volumetric_vol_params == 1, "the march's parameters are uniform slot 1");
static_assert(UB_volumetric_vol_lights == 2, "the march's lights are uniform slot 2");
static_assert(UB_volumetric_apply_params == 1, "the apply's parameters are uniform slot 1");
static_assert(VIEW_volumetric_tex_p == 0, "the march reads the prepass at view 0");
static_assert(VIEW_volumetric_fa_shadow_tex == 1, "the march reads the shadow atlas at view 1");
static_assert(VIEW_volumetric_fa_light_tex == 2, "the march reads the light data at view 2");
static_assert(VIEW_volumetric_tex_av == 0, "the apply reads the march image at view 0");
static_assert(VIEW_volumetric_tex_ap == 1, "the apply reads the prepass at view 1");
static_assert(SMP_volumetric_smp_pt == 0, "the march's sampler is 0");
static_assert(SMP_volumetric_smp_ap == 0, "the apply's sampler is 0");
static_assert(sizeof(volumetric_fa_shadows_t) == sizeof(mesh_fa_shadows_t) &&
                  UB_volumetric_fa_shadows == UB_mesh_fa_shadows,
              "the shadow block of the volumetric march is the one of the mesh shaders");
static_assert(sizeof(volumetric_vol_lights_t) == sizeof(float) * 4 * (kVolMaxDirectional * 2 + kVolMaxLocal * 4),
              "the light block of the volumetric march holds kVolMaxDirectional + kVolMaxLocal lights");

float fract(float x) { return x - std::floor(x); }

// A directional light that shines in the fog: on, with a finite colour.
bool shines(const LightData& l) {
    return std::isfinite(l.volumetric) && l.volumetric > 0.0f && finite3(l.color.x, l.color.y, l.color.z) &&
           l.color.x + l.color.y + l.color.z > 0.0f && finite3(l.pos.x, l.pos.y, l.pos.z);
}
// Area lights (color.w 3) have no shafts: only directional (0), point (1) and spot (2) lights are listed.
bool is_directional(const LightData& l) { return l.color.w == 0.0f && l.pos.w == 0.0f; }

}  // namespace

VolQuality vol_quality(VolumetricQuality q) {
    switch (q) {
        case VolumetricQuality::Low: return VolQuality{4, 16, 4, 6};
        case VolumetricQuality::High: return VolQuality{2, 48, 16, 16};
        default: return VolQuality{2, 32, 8, 10};
    }
}

void vol_grid_size(int rectW, int rectH, int divisor, int* w, int* h) {
    const int d = std::max(divisor, 1);
    if (w) *w = std::max(1, (std::max(rectW, 1) + d - 1) / d);
    if (h) *h = std::max(1, (std::max(rectH, 1) + d - 1) / d);
}

float vol_phase(float g, float cosTheta) {
    const float d = 1.0f + g * g - 2.0f * g * cosTheta;
    return (1.0f - g * g) / (d * std::sqrt(d));
}

float vol_jitter(int x, int y) { return fract(52.9829189f * fract(float(x) * 0.06711056f + float(y) * 0.00583715f)); }

float vol_density(float density, float base, float falloff, float y) {
    const float u = y - base;
    if (u <= 0.0f || falloff < 1e-5f) return density;
    return density * std::exp(-std::min(falloff * u, 80.0f));
}

namespace {
// The integral of the density from the base up to y (negative below it, the density being constant there).
float density_integral(float density, float base, float falloff, float y) {
    const float u = y - base;
    if (u <= 0.0f || falloff < 1e-5f) return density * u;
    return density * (1.0f - std::exp(-std::min(falloff * u, 80.0f))) / falloff;
}
}  // namespace

float vol_optical_depth(float density, float base, float falloff, float y0, float ry, float t) {
    if (falloff < 1e-5f) return density * t;
    const float dy = ry * t;
    if (std::fabs(dy) < 1e-3f || std::fabs(dy) * falloff < 2e-3f)
        return vol_density(density, base, falloff, y0 + 0.5f * dy) * t;
    return (density_integral(density, base, falloff, y0 + dy) - density_integral(density, base, falloff, y0)) / ry;
}

VolLightPick pick_volumetric_lights(const std::vector<LightData>& lights, int maxLocal) {
    VolLightPick pick;
    struct Cand {
        int index;
        float rank;
    };
    std::vector<Cand> local;
    for (int i = 0; i < int(lights.size()); ++i) {
        const LightData& l = lights[std::size_t(i)];
        if (!shines(l)) continue;
        if (is_directional(l)) {
            if (int(pick.directional.size()) < kVolMaxDirectional)
                pick.directional.push_back(i);
            else
                ++pick.dropped;
        } else if ((l.color.w == 1.0f || l.color.w == 2.0f) && l.pos.w > 0.0f && std::isfinite(l.pos.w) &&
                   std::isfinite(l.dir.w)) {
            const float score = std::isfinite(l.score) ? std::max(l.score, 0.0f) : 0.0f;
            local.push_back({i, score * l.volumetric});
        }
    }
    const int cap = std::clamp(maxLocal, 0, kVolMaxLocal);
    if (int(local.size()) > cap) {
        std::stable_sort(local.begin(), local.end(), [](const Cand& a, const Cand& b) { return a.rank > b.rank; });
        pick.dropped += int(local.size()) - cap;
        local.resize(std::size_t(cap));
        std::sort(local.begin(), local.end(), [](const Cand& a, const Cand& b) { return a.index < b.index; });
    }
    for (const Cand& c : local) pick.local.push_back(c.index);
    return pick;
}

VolPlan make_vol_plan(const SceneSettings& ss, const CameraGeometry& cam, const std::vector<LightData>& lights,
                      bool linear, int rectW, int rectH, bool shadowsDrawn, bool sunCasts) {
    VolPlan p;
    if (!ss.volumetricFog || !cam.perspective || rectW < 1 || rectH < 1) return p;
    p.density = std::clamp(finite_or(ss.volumetricDensity, 0.0f), 0.0f, 10.0f);
    if (!(p.density > 0.0f)) return p;
    p.heightBase = std::clamp(finite_or(ss.volumetricHeightBase, 0.0f), -10000.0f, 10000.0f);
    p.heightFalloff = std::clamp(finite_or(ss.volumetricHeightFalloff, 0.0f), 0.0f, 10.0f);
    p.anisotropy = std::clamp(finite_or(ss.volumetricAnisotropy, 0.0f), -0.99f, 0.99f);
    p.distance = std::clamp(finite_or(ss.volumetricDistance, 100.0f), 1.0f, 10000.0f);
    const float ambientK = std::clamp(finite_or(ss.volumetricAmbient, 1.0f), 0.0f, 10.0f);
    const Color fog = to_scene(ss.fogColor, linear);
    const Color amb = to_scene(ss.ambientLight, linear);
    p.albedo[0] = std::clamp(finite_or(fog.r, 0.0f), 0.0f, 100.0f);
    p.albedo[1] = std::clamp(finite_or(fog.g, 0.0f), 0.0f, 100.0f);
    p.albedo[2] = std::clamp(finite_or(fog.b, 0.0f), 0.0f, 100.0f);
    p.ambient[0] = std::clamp(finite_or(amb.r, 0.0f), 0.0f, 1000.0f) * ambientK;
    p.ambient[1] = std::clamp(finite_or(amb.g, 0.0f), 0.0f, 1000.0f) * ambientK;
    p.ambient[2] = std::clamp(finite_or(amb.b, 0.0f), 0.0f, 1000.0f) * ambientK;

    p.quality = vol_quality(ss.volumetricQuality);
    p.quality.steps = std::clamp(p.quality.steps, 1, kVolMaxSteps);
    p.quality.samples = std::clamp(p.quality.samples, 1, kVolMaxSamples);
    p.rectW = rectW;
    p.rectH = rectH;
    vol_grid_size(rectW, rectH, p.quality.divisor, &p.width, &p.height);

    const Mat4& P = cam.proj;
    const float terms[8] = {P.at(0, 0), P.at(1, 1), P.at(2, 0), P.at(2, 1),
                            P.at(3, 0), P.at(3, 1), P.at(2, 3), P.at(3, 3)};
    bool ok = std::fabs(terms[0]) > 1e-12f && std::fabs(terms[1]) > 1e-12f;
    for (int i = 0; i < 8; ++i) {
        ok = ok && std::isfinite(terms[i]);
        p.proj[i] = terms[i];
    }
    p.eye = cam.position;
    p.right = cam.right;
    p.up = cam.up;
    p.forward = cam.forward;
    ok = ok && finite3(p.eye.x, p.eye.y, p.eye.z) && finite3(p.right.x, p.right.y, p.right.z) &&
         finite3(p.up.x, p.up.y, p.up.z) && finite3(p.forward.x, p.forward.y, p.forward.z);
    if (!ok) return p;

    const VolLightPick pick = pick_volumetric_lights(lights, p.quality.maxLights);
    for (int idx : pick.directional) {
        const LightData& l = lights[std::size_t(idx)];
        const int k = p.directionalCount++;
        p.directional[2 * k][0] = l.pos.x;  // pos = the direction toward the light
        p.directional[2 * k][1] = l.pos.y;
        p.directional[2 * k][2] = l.pos.z;
        p.directional[2 * k][3] = (idx == 0 && sunCasts && l.rank == 0) ? 1.0f : 0.0f;
        p.directional[2 * k + 1][0] = l.color.x * l.volumetric;
        p.directional[2 * k + 1][1] = l.color.y * l.volumetric;
        p.directional[2 * k + 1][2] = l.color.z * l.volumetric;
    }
    for (int idx : pick.local) {
        const LightData& l = lights[std::size_t(idx)];
        const int k = p.localCount++;
        float* a = p.local[4 * k];
        float* b = p.local[4 * k + 1];
        float* c = p.local[4 * k + 2];
        float* d = p.local[4 * k + 3];
        a[0] = l.pos.x;
        a[1] = l.pos.y;
        a[2] = l.pos.z;
        a[3] = l.pos.w;
        b[0] = l.color.x * l.volumetric;
        b[1] = l.color.y * l.volumetric;
        b[2] = l.color.z * l.volumetric;
        if (l.color.w == 2.0f) {  // a spot: the cone of fa_light_sample (light_data.glsl)
            const float cosOuter = l.dir.w;
            b[3] = l.cosInner > 1.5f ? cosOuter + 0.25f * (1.0f - cosOuter) : l.cosInner;
            c[0] = l.dir.x;
            c[1] = l.dir.y;
            c[2] = l.dir.z;
            c[3] = cosOuter;
        } else {
            b[3] = 1.0f;
            c[3] = -2.0f;  // a point light: no cone
        }
        d[0] = float(idx);
        d[1] = (shadowsDrawn && l.shadow.casts) ? 1.0f : 0.0f;
    }
    p.lightsUsed = p.directionalCount + p.localCount;
    p.lightsDropped = pick.dropped;
    p.on = true;
    return p;
}

// ---------------------------------------------------------------------------
// The GPU side
// ---------------------------------------------------------------------------

bool VolumetricFx::gpu_supported(gpu::Device& device) {
    const gpu::PixelFormatCaps f = device.pixel_format_caps(gpu::PixelFormat::Rgba16F);
    // The rule of the `half` word of the feature rows (render_features.cpp, FeatureEnv::halfTargets), so render.supports("volumetricFog") and the
    // renderer never disagree.
    return f.render && f.blend && f.filter;
}

TransientDesc VolumetricFx::image_desc(const VolPlan& plan, const std::string& job) {
    TransientDesc d;
    d.width = plan.width;
    d.height = plan.height;
    d.format = TargetFormat{gpu::PixelFormat::Rgba16F, gpu::PixelFormat::None, 1};
    d.label = job + "/vol-image";
    return d;
}

bool VolumetricFx::ready(Gpu& gpu, Prog prog) { return ready(gpu.device(), prog); }

bool VolumetricFx::ready(gpu::Device& device, Prog prog) {
    int& st = state_[int(prog)];
    if (st != 0) return st > 0;
    device_ = &device;
    const gpu::Shader s =
        prog == Prog::March
            ? make_shader(device, gpu::generated_shader_desc(volumetric_march_shader_desc), "volumetric_march")
            : make_shader(device, gpu::generated_shader_desc(volumetric_apply_shader_desc), "volumetric_apply");
    if (device.state(s) != gpu::ResourceState::Valid) {
        if (s.id) device.destroy_shader(s);
        st = -1;
        FA_ERROR(
            "render",
            "The volumetric fog is unavailable: its shader failed to compile for this graphics backend (see the sokol "
            "log lines above). The game renders without it. Hint: update the graphics driver (Mesa: try "
            "LIBGL_ALWAYS_SOFTWARE=1) or turn SceneSettings.volumetricFog off.");
        return false;
    }
    shaders_[int(prog)] = s;
    st = 1;
    return true;
}

gpu::Pipeline VolumetricFx::pipeline(gpu::Device& device, Prog prog, const TargetFormat& format) {
    for (const PipelineEntry& e : pipelines_)
        if (e.prog == prog && e.format == format) return e.pipeline;
    if (state_[int(prog)] <= 0) return {};
    gpu::PipelineDesc d;
    d.shader = shaders_[int(prog)];
    d.layout.attrs[0].format = gpu::VertexFormat::Float2;  // `pos`, location 0 in both programs
    d.depth.compare = gpu::CompareFunc::Always;
    d.depth.writeEnabled = false;
    d.depth.pixelFormat = format.depth;
    d.colors[0].pixelFormat = format.color;
    d.sampleCount = format.samples;
    d.faceWinding = gpu::FaceWinding::Ccw;
    if (prog == Prog::Apply) {
        // picture * a + rgb: the fragment's alpha is what the picture keeps of its light, its rgb what the fog adds. The alpha of the picture is kept.
        d.colors[0].blend.enabled = true;
        d.colors[0].blend.srcFactorRgb = gpu::BlendFactor::One;
        d.colors[0].blend.dstFactorRgb = gpu::BlendFactor::SrcAlpha;
        d.colors[0].blend.srcFactorAlpha = gpu::BlendFactor::Zero;
        d.colors[0].blend.dstFactorAlpha = gpu::BlendFactor::One;
    }
    d.label = prog == Prog::March ? "vol-march" : "vol-apply";
    const gpu::Pipeline p = device.make_pipeline(d);
    if (device.state(p) != gpu::ResourceState::Valid) FA_ERROR("render", "failed to create pipeline '{}'", d.label);
    pipelines_.push_back({prog, format, p});
    return p;
}

void VolumetricFx::forget_targets() {
    failed_.clear();
    probed_.clear();
    warnedTargets_ = false;
}

void VolumetricFx::release() {
    for (PipelineEntry& e : pipelines_)
        if (e.pipeline.id && device_) device_->destroy_pipeline(e.pipeline);
    pipelines_.clear();
    for (gpu::Shader& s : shaders_) {
        if (s.id && device_) device_->destroy_shader(s);
        s = {};
    }
    for (int& s : state_) s = 0;
    failed_.clear();
    probed_.clear();
    warnedTargets_ = false;
    warnedGpu_ = false;
}

bool VolumetricFx::can_draw(TransientTargets& targets, Gpu& gpu, const VolPlan& plan) {
    return can_draw(targets, gpu.device(), plan);
}

bool VolumetricFx::can_draw(TransientTargets& targets, gpu::Device& device, const VolPlan& plan) {
    if (!plan.on) return false;
    if (!gpu_supported(device)) {
        if (!warnedGpu_) {
            warnedGpu_ = true;
            FA_WARN("render", "The volumetric fog needs RGBA16F render targets and this GPU has none: the scene keeps "
                              "its analytic fog. "
                              "Hint: render.supports {{\"feature\": \"volumetricFog\"}} tells which GPUs draw it.");
        }
        return false;
    }
    if (!ready(device, Prog::March) || !ready(device, Prog::Apply)) return false;
    const std::uint64_t key = (std::uint64_t(std::uint32_t(plan.width)) << 32) | std::uint32_t(plan.height);
    if (std::find(failed_.begin(), failed_.end(), key) != failed_.end()) return false;
    if (std::find(probed_.begin(), probed_.end(), key) != probed_.end()) return true;
    // Made now (and given back to the pool) so that a GPU that refuses the image is one warning here, not a pass that cannot run.
    const std::uint64_t h = targets.pool.acquire(image_desc(plan, "vol"));
    if (h == 0) {
        if (failed_.size() >= kMaxFailed) failed_.erase(failed_.begin());
        failed_.push_back(key);
        if (!warnedTargets_) {
            warnedTargets_ = true;
            FA_ERROR("render",
                     "Volumetric fog: cannot create the {}x{} image it marches into; the scene keeps its analytic fog. "
                     "Hint: "
                     "lower SceneSettings.volumetricQuality or the render scale.",
                     plan.width, plan.height);
        }
        return false;
    }
    targets.pool.release(h);
    if (probed_.size() >= kMaxFailed) probed_.erase(probed_.begin());
    probed_.push_back(key);
    return true;
}

void VolumetricFx::march(Gpu& gpu, const VolPlan& plan, const Target& dst, gpu::bridged::View prepass,
                         gpu::bridged::View shadowTex, gpu::bridged::View lightTex, const mesh_fa_shadows_t& shadows,
                         int* drawCalls) {
    if (!dst.colorAtt.id || !prepass.id || !shadowTex.id || !lightTex.id || !ready(gpu, Prog::March)) return;
    PassDesc pd = pass_into(dst, "vol-march");
    pd.colorLoad = gpu::LoadAction::DontCare;
    gpu::CommandList& list = gpu.commands();
    list.begin_pass(pd);
    list.set_pipeline(pipeline(gpu.device(), Prog::March, pd.format));
    gpu::Bindings b;
    b.vertexBuffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_volumetric_tex_p] = prepass;
    b.views[VIEW_volumetric_fa_shadow_tex] = shadowTex;
    b.views[VIEW_volumetric_fa_light_tex] = lightTex;
    b.samplers[SMP_volumetric_smp_pt] = gpu.sampler(SamplerKind::Nearest);
    list.set_bindings(b);

    const float gl = gpu.is_gl() ? 1.0f : 0.0f;
    const float flip[4] = {gl, 0.0f, 0.0f, 0.0f};
    list.set_uniforms(UB_volumetric_vol_vs_params, gpu::Range{flip, sizeof(flip)});

    volumetric_vol_params_t u{};
    u.a[0] = gl;
    u.a[1] = float(plan.quality.steps);
    u.a[2] = float(plan.localCount);
    u.a[3] = float(plan.quality.samples);
    u.b[0] = float(plan.width);
    u.b[1] = float(plan.height);
    u.b[2] = float(plan.directionalCount);
    u.b[3] = plan.distance;
    for (int i = 0; i < 4; ++i) {
        u.pa[i] = plan.proj[i];
        u.pb[i] = plan.proj[4 + i];
    }
    u.eye[0] = plan.eye.x;
    u.eye[1] = plan.eye.y;
    u.eye[2] = plan.eye.z;
    u.right[0] = plan.right.x;
    u.right[1] = plan.right.y;
    u.right[2] = plan.right.z;
    u.up[0] = plan.up.x;
    u.up[1] = plan.up.y;
    u.up[2] = plan.up.z;
    u.fwd[0] = plan.forward.x;
    u.fwd[1] = plan.forward.y;
    u.fwd[2] = plan.forward.z;
    u.m[0] = plan.density;
    u.m[1] = plan.heightBase;
    u.m[2] = plan.heightFalloff;
    u.m[3] = plan.anisotropy;
    for (int i = 0; i < 3; ++i) {
        u.albedo[i] = plan.albedo[i];
        u.amb[i] = plan.ambient[i];
    }
    list.set_uniforms(UB_volumetric_vol_params, gpu::Range{&u, sizeof(u)});

    volumetric_vol_lights_t lu{};
    std::memcpy(lu.dirs, plan.directional, sizeof(lu.dirs));
    std::memcpy(lu.loc, plan.local, sizeof(lu.loc));
    list.set_uniforms(UB_volumetric_vol_lights, gpu::Range{&lu, sizeof(lu)});

    // The shadow block of the mesh shaders, with the sun's filter set to a single tap: a fog sample is blurred by the jitter and the upsample
    // already, and takes a few of them per pixel.
    volumetric_fa_shadows_t su;
    std::memcpy(&su, &shadows, sizeof(su));
    su.fa_shadow_cfg[2] = 1.0f;
    list.set_uniforms(UB_volumetric_fa_shadows, gpu::Range{&su, sizeof(su)});

    list.draw(0, 3, 1);
    list.end_pass();
    if (drawCalls) ++*drawCalls;
}

int VolumetricFx::add_apply(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, const VolPlan& plan, ResourceId vol,
                            const PostRect& rect, int picW, int picH, ResourceId game, const BloomTarget& dst,
                            const PrepassRef& prepass, int* drawCalls, const std::string& job) {
    if (!plan.on || !prepass.valid() || !vol.valid() || !ready(gpu, Prog::Apply)) return 0;
    const bool whole = rect.whole(picW, picH);
    const int rx = whole ? 0 : rect.x, ry = whole ? 0 : rect.y;
    const int rw = whole ? picW : rect.w, rh = whole ? picH : rect.h;
    if (rw < 1 || rh < 1) return 0;
    TransientTargets* tt = &targets;
    Gpu* g = &gpu;
    VolumetricFx* self = this;
    const PrepassRef prepassRef = prepass;
    const TargetFormat dstFormat{gpu.scene_format(), gpu::PixelFormat::None, dst.samples};
    volumetric_apply_params_t u{};
    u.a[0] = float(plan.width);
    u.a[1] = float(plan.height);
    GraphPass gp;
    gp.name = job + "/vol-apply";
    gp.reads = {vol, prepass.res, game};
    gp.writes = {game};
    gp.execute = [=](const PassContext& c) {
        const Target* vt = tt->get(c.handle(vol));
        const Target* pt = prepassRef.target(c);
        if (!vt || !pt || !vt->texView.id || !pt->texView.id || !dst.att.id) return;
        PassDesc pd;
        pd.label = "vol-apply";
        pd.color = dst.att;
        pd.resolve = dst.resolve;  // id 0 when the pass does not resolve
        pd.format = dstFormat;
        pd.colorLoad = gpu::LoadAction::Load;
        pd.colorStore = gpu::StoreAction::Store;
        gpu::CommandList& list = c.commands() ? *c.commands() : g->commands();
        list.begin_pass(pd);
        if (!whole) {
            list.set_viewport(rx, ry, rw, rh, true);
            list.set_scissor(rx, ry, rw, rh, true);
        }
        list.set_pipeline(self->pipeline(g->device(), Prog::Apply, pd.format));
        gpu::Bindings b;
        b.vertexBuffers[0] = g->fullscreen_triangle();
        b.views[VIEW_volumetric_tex_av] = vt->texView;
        b.views[VIEW_volumetric_tex_ap] = pt->texView;
        b.samplers[SMP_volumetric_smp_ap] = g->sampler(SamplerKind::Nearest);
        list.set_bindings(b);
        const float flip[4] = {g->is_gl() ? 1.0f : 0.0f, 0.0f, 0.0f, 0.0f};
        list.set_uniforms(UB_volumetric_vol_vs_params, gpu::Range{flip, sizeof(flip)});
        list.set_uniforms(UB_volumetric_apply_params, gpu::Range{&u, sizeof(u)});
        list.draw(0, 3, 1);
        list.end_pass();
        if (drawCalls) ++*drawCalls;
    };
    graph.add_pass(std::move(gp));
    return 1;
}

#if defined(_MSC_VER)
#pragma warning(pop)
#endif

}  // namespace fa::render
