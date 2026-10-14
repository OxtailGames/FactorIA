#include "bloom.h"

#include <algorithm>
#include <cmath>

#include "fa/core/log.h"

#include "shaders/bloom.glsl.h"

namespace fa::render {

namespace {

constexpr float kMaxHalfWidthTexels = 5.0f;  // blur half-width at the working resolution (<= 16 supported by the shader)
constexpr float kMinHalfWidthTexels = 2.5f;  // below this the low-resolution glow would just look like blocks
constexpr int kMaxLevel = 4;                 // 1/32 resolution: radius 128 -> half-width 4 texels
constexpr float kSigmaPerHalfWidth = 1.0f / 2.5f;  // gaussian sigma = half-width / 2.5 (the kernel stops at 2.5 sigma)

float finite_or(float v, float fallback) { return std::isfinite(v) ? v : fallback; }

struct Plan {
    int level = 0;           // working resolution: 0 = 1/2, 1 = 1/4, 2 = 1/8, 3 = 1/16, 4 = 1/32
    int first = 0;           // level the bright pass writes: 0 (2x2 pixels per texel) or 1 (4x4 pixels per texel)
    float halfWidth = 2.5f;  // blur half-width in texels of the working level
};

// The bigger the radius, the lower the resolution the blur runs at, so the kernel never exceeds 5 texels per
// side (cost stays flat: the pixel count drops 4x per level while the radius doubles). Only radii up to ~10 px
// work at 1/2 resolution; everything else skips it and the bright pass writes 1/4 resolution directly.
Plan plan_for(float radius) {
    Plan p;
    float div = 2.0f;
    while (p.level < kMaxLevel && radius / div > kMaxHalfWidthTexels) {
        ++p.level;
        div *= 2.0f;
    }
    p.halfWidth = std::max(radius / div, kMinHalfWidthTexels);
    p.first = p.level == 0 ? 0 : 1;
    return p;
}

template <class T>
void apply_uniforms(int slot, const T& u) {
    sg_range r{&u, sizeof(T)};
    sg_apply_uniforms(slot, &r);
}

// One full-screen-triangle pass: samples `srcTex`, writes `dstAtt`. `fsParams` (optional) goes to slot `fsSlot`.
template <class U>
void run_pass(Gpu& gpu, BloomStage stage, sg_view srcTex, const BloomTarget& dst, bool additive, const U* fsParams, int fsSlot,
              const char* label) {
    sg_pass p{};
    p.action.colors[0].load_action = additive ? SG_LOADACTION_LOAD : SG_LOADACTION_DONTCARE;
    p.action.colors[0].store_action = SG_STOREACTION_STORE;
    p.attachments.colors[0] = dst.att;
    if (dst.resolve.id) p.attachments.resolves[0] = dst.resolve;
    p.label = label;
    sg_begin_pass(&p);
    sg_apply_pipeline(gpu.bloom_pipeline(stage, dst.samples));
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_bloom_tex] = srcTex;
    b.samplers[SMP_bloom_smp] = gpu.sampler(SamplerKind::LinearClamp);
    sg_apply_bindings(&b);
    bloom_bloom_vs_params_t vu{};
    vu.flip[0] = gpu.is_gl() ? 1.0f : 0.0f;
    apply_uniforms(UB_bloom_bloom_vs_params, vu);
    if (fsParams) apply_uniforms(fsSlot, *fsParams);
    sg_draw(0, 3, 1);
    sg_end_pass();
}

}  // namespace

BloomSettings sanitize_bloom(bool enabled, float threshold, float intensity, float radius, bool screenSpace) {
    BloomSettings b;
    b.enabled = enabled;
    b.screenSpace = screenSpace;
    b.threshold = std::clamp(finite_or(threshold, b.threshold), 0.0f, 0.99f);
    b.intensity = std::clamp(finite_or(intensity, b.intensity), 0.0f, 10.0f);
    b.radius = std::clamp(finite_or(radius, b.radius), 1.0f, 128.0f);
    return b;
}

void Bloom::release() {
    for (Level& l : levels_) {
        for (sg_view* v : {&l.att[0], &l.att[1], &l.tex[0], &l.tex[1]}) {
            if (v->id) sg_destroy_view(*v);
            *v = {};
        }
        for (sg_image& i : l.img) {
            if (i.id) sg_destroy_image(i);
            i = {};
        }
        l.w = l.h = 0;
    }
    targetW_ = targetH_ = 0;
}

bool Bloom::ensure(int level, int targetW, int targetH, bool needSecond) {
    Level& l = levels_[level];
    const int div = 2 << level;
    l.w = std::max(1, (targetW + div - 1) / div);
    l.h = std::max(1, (targetH + div - 1) / div);
    for (int i = 0; i < (needSecond ? 2 : 1); ++i) {
        if (l.img[i].id) continue;
        sg_image_desc d{};
        d.usage.color_attachment = true;
        d.width = l.w;
        d.height = l.h;
        d.pixel_format = SG_PIXELFORMAT_RGBA8;
        d.sample_count = 1;
        d.label = "bloom-level";
        l.img[i] = sg_make_image(&d);
        sg_view_desc av{};
        av.color_attachment.image = l.img[i];
        av.label = "bloom-level-att";
        l.att[i] = sg_make_view(&av);
        sg_view_desc tv{};
        tv.texture.image = l.img[i];
        tv.label = "bloom-level-tex";
        l.tex[i] = sg_make_view(&tv);
        if (sg_query_image_state(l.img[i]) != SG_RESOURCESTATE_VALID || sg_query_view_state(l.att[i]) != SG_RESOURCESTATE_VALID ||
            sg_query_view_state(l.tex[i]) != SG_RESOURCESTATE_VALID) {
            if (!warned_) {
                warned_ = true;
                FA_ERROR("render", "Camera.bloom: cannot create the {}x{} intermediate target; bloom is skipped", l.w, l.h);
            }
            return false;
        }
    }
    return true;
}

int Bloom::apply(Gpu& gpu, const BloomSettings& s, int targetW, int targetH, sg_view srcTex, const BloomTarget& dst) {
    if (!s.enabled || s.intensity <= 0.0f || targetW < 1 || targetH < 1) return 0;
    if (!gpu.bloom_ready()) return 0;
    if (targetW != targetW_ || targetH != targetH_) {
        release();
        targetW_ = targetW;
        targetH_ = targetH;
    }
    const Plan plan = plan_for(s.radius);
    for (int l = plan.first; l <= plan.level; ++l) {
        if (!ensure(l, targetW, targetH, l == plan.level)) return 0;
    }

    int passes = 0;
    // 1. bright pass: game target -> 1/2 res (2x2 source pixels per texel) or 1/4 res (4x4 per texel).
    {
        bloom_bloom_bright_params_t u{};
        u.p[0] = 1.0f / float(targetW);
        u.p[1] = 1.0f / float(targetH);
        u.p[2] = s.threshold;
        u.p[3] = 1.0f / std::max(1.0f - s.threshold, 1.0f / 255.0f);
        u.q[0] = plan.first == 0 ? 2.0f : 4.0f;
        run_pass(gpu, BloomStage::Bright, srcTex, BloomTarget{levels_[plan.first].att[0]}, false, &u, UB_bloom_bloom_bright_params,
                 "bloom-bright");
        ++passes;
    }
    // 2. downsample to the working level.
    for (int l = plan.first + 1; l <= plan.level; ++l) {
        run_pass<bloom_bloom_bright_params_t>(gpu, BloomStage::Down, levels_[l - 1].tex[0], BloomTarget{levels_[l].att[0]}, false, nullptr, 0,
                                              "bloom-down");
        ++passes;
    }
    // 3. separable gaussian at the working level: A -> B (horizontal), B -> A (vertical).
    {
        Level& w = levels_[plan.level];
        const float sigma = plan.halfWidth * kSigmaPerHalfWidth;
        bloom_bloom_blur_params_t u{};
        u.p[2] = 1.0f / (2.0f * sigma * sigma);
        u.p[3] = std::ceil(plan.halfWidth);
        u.p[0] = 1.0f / float(w.w);
        u.p[1] = 0.0f;
        run_pass(gpu, BloomStage::Blur, w.tex[0], BloomTarget{w.att[1]}, false, &u, UB_bloom_bloom_blur_params, "bloom-blur-h");
        u.p[0] = 0.0f;
        u.p[1] = 1.0f / float(w.h);
        run_pass(gpu, BloomStage::Blur, w.tex[1], BloomTarget{w.att[0]}, false, &u, UB_bloom_bloom_blur_params, "bloom-blur-v");
        passes += 2;
    }
    // 4. composite: game target += glow * intensity (bilinear upsample from the working level).
    {
        bloom_bloom_composite_params_t u{};
        u.p[0] = s.intensity;
        run_pass(gpu, BloomStage::Composite, levels_[plan.level].tex[0], dst, true, &u, UB_bloom_bloom_composite_params,
                 "bloom-composite");
        ++passes;
    }
    return passes;
}

}  // namespace fa::render
