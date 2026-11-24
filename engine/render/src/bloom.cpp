#include "bloom.h"

#include <algorithm>
#include <cmath>

#include "fa/core/log.h"

#include "shaders/bloom.glsl.h"

namespace fa::render {

namespace {

constexpr float kMaxHalfWidthTexels =
    5.0f;  // blur half-width at the working resolution (<= 16 supported by the shader)
constexpr float kMinHalfWidthTexels = 2.5f;        // below this the low-resolution glow would just look like blocks
constexpr int kMaxLevel = 4;                       // 1/32 resolution: radius 128 -> half-width 4 texels
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
void apply_uniforms(gpu::CommandList& list, int slot, const T& u) {
    list.set_uniforms(slot, gpu::Range{&u, sizeof(T)});
}

// One full-screen-triangle pass: samples `srcTex`, writes `dst`, whose colour format is `fmt` (no depth). `fsParams`
// (optional) goes to slot `fsSlot`.
template <class U>
void run_pass(const PassContext& c, Gpu& gpu, gpu::PixelFormat fmt, BloomStage stage, gpu::View srcTex,
              const BloomTarget& dst, bool additive, const U* fsParams, int fsSlot, const char* label,
              gpu::View dirt = {}) {
    PassDesc p;
    p.label = label;
    p.color = dst.att;
    p.resolve = dst.resolve;  // id 0 when the pass does not resolve
    p.format = TargetFormat{fmt, gpu::PixelFormat::None, dst.samples};
    p.colorLoad = additive ? gpu::LoadAction::Load : gpu::LoadAction::DontCare;
    p.colorStore = gpu::StoreAction::Store;
    gpu::CommandList& list = c.commands() ? *c.commands() : gpu.commands();
    list.begin_pass(p);
    list.set_pipeline(gpu.bloom_pipeline(stage, p.format));
    gpu::Bindings b;
    b.vertexBuffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_bloom_tex] = srcTex;
    if (dirt.id) b.views[VIEW_bloom_dirt_tex] = dirt;  // the composite program only
    b.samplers[SMP_bloom_smp] = gpu.sampler(SamplerKind::LinearClamp);
    list.set_bindings(b);
    bloom_bloom_vs_params_t vu{};
    vu.flip[0] = gpu.is_gl() ? 1.0f : 0.0f;
    apply_uniforms(list, UB_bloom_bloom_vs_params, vu);
    if (fsParams) apply_uniforms(list, fsSlot, *fsParams);
    list.draw(0, 3, 1);
    list.end_pass();
}

}  // namespace

// The bloom settings with every number finite and clamped: threshold 0..0.99, intensity 0..10, radius 1..128.
// bloom_from_stack (postprocess.cpp) is what the renderer calls: it takes the threshold again from the PostProcess
// and clamps it to 0..20 (above 1 is HDR light of a linear scene), so the 0.99 cap only holds for a caller of this one.
BloomSettings sanitize_bloom(bool enabled, float threshold, float intensity, float radius, bool screenSpace) {
    BloomSettings b;
    b.enabled = enabled;
    b.screenSpace = screenSpace;
    b.threshold = std::clamp(finite_or(threshold, b.threshold), 0.0f, 0.99f);
    b.intensity = std::clamp(finite_or(intensity, b.intensity), 0.0f, 10.0f);
    b.radius = std::clamp(finite_or(radius, b.radius), 1.0f, 128.0f);
    return b;
}

void Bloom::release() { failed_.clear(); }

// The pass callbacks capture the shader's uniform blocks by value, which are alignas(16): MSVC warns (C4324, an error
// under /WX) that each closure is padded, which is what alignas asks for.
#if defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable : 4324)
#endif
int Bloom::add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, const BloomSettings& s, int targetW,
                      int targetH, ResourceId game, gpu::View srcTex, const BloomTarget& dst, gpu::View dirtView,
                      int* drawCalls, const std::string& job) {
    if (!s.enabled || s.intensity <= 0.0f || targetW < 1 || targetH < 1) return 0;
    if (!gpu.bloom_ready()) return 0;
    const gpu::PixelFormat fmt = gpu.scene_format();  // the game target's format, and the one of every level
    const Shape shape{targetW, targetH, fmt};
    if (std::find(failed_.begin(), failed_.end(), shape) != failed_.end()) return 0;  // not tried again every frame
    const Plan plan = plan_for(s.radius);

    // The transients: `a` of every level from the first to the working one, and `b` of the working level (the blur's
    // second image). Sizes as the level divides the game target.
    ResourceId a[kLevels], b;
    int lw[kLevels]{}, lh[kLevels]{};
    std::vector<TransientDesc>& descs = descs_;
    descs.clear();
    auto level_desc = [&](int l, const char* suffix) {
        const int div = 2 << l;
        TransientDesc d;
        d.width = lw[l] = std::max(1, (targetW + div - 1) / div);
        d.height = lh[l] = std::max(1, (targetH + div - 1) / div);
        d.format = TargetFormat{fmt, gpu::PixelFormat::None, 1};
        d.label = "bloom-1/" + std::to_string(div) + suffix;
        return d;
    };
    for (int l = plan.first; l <= plan.level; ++l) descs.push_back(level_desc(l, ""));
    descs.push_back(level_desc(plan.level, "-b"));
    // Make sure the GPU can have them all at once (the worst case: aliasing only needs fewer), so that a failure is one
    // warning here and not a pass that cannot run halfway through the frame. The pool keeps what it made.
    {
        std::vector<std::uint64_t>& held = held_;
        held.clear();
        bool ok = true;
        for (const TransientDesc& d : descs) {
            const std::uint64_t h = targets.pool.acquire(d);
            if (h == 0) {
                ok = false;
                break;
            }
            held.push_back(h);
        }
        for (std::uint64_t h : held) targets.pool.release(h);
        if (!ok) {
            if (failed_.size() >= kMaxFailed) failed_.erase(failed_.begin());
            failed_.push_back(shape);
            if (!warned_) {
                warned_ = true;
                FA_ERROR("render",
                         "PostProcess bloom: cannot create the intermediate targets for a {}x{} game target; "
                         "bloom is skipped",
                         targetW, targetH);
            }
            return 0;
        }
    }
    for (int l = plan.first; l <= plan.level; ++l) a[l] = graph.create_transient(descs[std::size_t(l - plan.first)]);
    b = graph.create_transient(descs.back());

    int declared = 0;
    // The pool's target a pass was given -> its views. Every first writer below draws each of its pixels with DONTCARE
    // (run_pass: additive = false), as the contents of a transient are undefined when its first pass starts.
    TransientTargets* tt = &targets;
    auto att = [tt](const PassContext& c, ResourceId r) {
        const Target* t = tt->get(c.handle(r));
        return t ? t->colorAtt : gpu::View{};
    };
    auto tex = [tt](const PassContext& c, ResourceId r) {
        const Target* t = tt->get(c.handle(r));
        return t ? t->texView : gpu::View{};
    };
    auto add = [&](const std::string& name, std::vector<ResourceId> reads, std::vector<ResourceId> writes, auto&& fn) {
        GraphPass p;
        p.name = job.empty() ? name : job + "/" + name;
        p.reads = std::move(reads);
        p.writes = std::move(writes);
        p.execute = std::forward<decltype(fn)>(fn);
        graph.add_pass(std::move(p));
        ++declared;
    };
    Gpu* g = &gpu;

    // 1. bright pass: game target -> 1/2 res (2x2 source pixels per texel) or 1/4 res (4x4 per texel).
    {
        bloom_bloom_bright_params_t u{};
        u.p[0] = 1.0f / float(targetW);
        u.p[1] = 1.0f / float(targetH);
        u.p[2] = s.threshold;
        u.p[3] =
            1.0f / std::max(1.0f - s.threshold, 0.01f);  // a threshold above 0.99 (a linear scene) is a cut 0.01 wide
        u.q[0] = plan.first == 0 ? 2.0f : 4.0f;
        u.q[1] = s.knee * 0.5f;  // the half-width of the soft knee
        const ResourceId out = a[plan.first];
        add("bloom-bright", {game}, {out}, [=](const PassContext& c) {
            run_pass(c, *g, fmt, BloomStage::Bright, srcTex, BloomTarget{att(c, out)}, false, &u,
                     UB_bloom_bloom_bright_params, "bloom-bright");
            ++*drawCalls;
        });
    }
    // 2. downsample to the working level.
    for (int l = plan.first + 1; l <= plan.level; ++l) {
        const ResourceId from = a[l - 1], out = a[l];
        add("bloom-down-" + std::to_string(l), {from}, {out}, [=](const PassContext& c) {
            run_pass<bloom_bloom_bright_params_t>(c, *g, fmt, BloomStage::Down, tex(c, from), BloomTarget{att(c, out)},
                                                  false, nullptr, 0, "bloom-down");
            ++*drawCalls;
        });
    }
    // 3. separable gaussian at the working level: A -> B (horizontal), B -> A (vertical).
    {
        const float sigma = plan.halfWidth * kSigmaPerHalfWidth;
        bloom_bloom_blur_params_t uh{};
        uh.p[2] = 1.0f / (2.0f * sigma * sigma);
        uh.p[3] = std::ceil(plan.halfWidth);
        uh.p[0] = 1.0f / float(lw[plan.level]);
        uh.p[1] = 0.0f;
        bloom_bloom_blur_params_t uv = uh;
        uv.p[0] = 0.0f;
        uv.p[1] = 1.0f / float(lh[plan.level]);
        const ResourceId wa = a[plan.level], wb = b;
        add("bloom-blur-h", {wa}, {wb}, [=](const PassContext& c) {
            run_pass(c, *g, fmt, BloomStage::Blur, tex(c, wa), BloomTarget{att(c, wb)}, false, &uh,
                     UB_bloom_bloom_blur_params, "bloom-blur-h");
            ++*drawCalls;
        });
        add("bloom-blur-v", {wb}, {wa}, [=](const PassContext& c) {
            run_pass(c, *g, fmt, BloomStage::Blur, tex(c, wb), BloomTarget{att(c, wa)}, false, &uv,
                     UB_bloom_bloom_blur_params, "bloom-blur-v");
            ++*drawCalls;
        });
    }
    // 4. composite: game target += glow * intensity (bilinear upsample from the working level).
    {
        bloom_bloom_composite_params_t u{};
        u.p[0] = s.intensity;
        u.p[1] = s.dirt.empty()
                     ? 0.0f
                     : s.dirtIntensity;  // no lens dirt: the glow is added as it is (the dirt image is a dummy)
        const ResourceId wa = a[plan.level];
        add("bloom-composite", {wa, game}, {game}, [=](const PassContext& c) {
            run_pass(c, *g, fmt, BloomStage::Composite, tex(c, wa), dst, true, &u, UB_bloom_bloom_composite_params,
                     "bloom-composite", dirtView);
            ++*drawCalls;
        });
    }
    return declared;
}
#if defined(_MSC_VER)
#pragma warning(pop)
#endif

}  // namespace fa::render
