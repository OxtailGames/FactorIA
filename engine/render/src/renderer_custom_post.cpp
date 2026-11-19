#include "renderer_custom_post.h"

#include <algorithm>
#include <cstring>
#include <memory>

#include "fa/core/log.h"

#include "postprocess.h"
#include "postprocess_resolve.h"
#include "renderer_dof.h"

namespace fa::render {

namespace {

constexpr std::size_t kMaxProbed = 16;

void note_fallback(std::vector<std::string>& fallbacks, const std::string& path) {
    if (std::find(fallbacks.begin(), fallbacks.end(), path) == fallbacks.end()) fallbacks.push_back(path);
}

// The fragment block of post_common.glsl (fa_post_params, binding 1).
struct PostParamsBlock {
    float a[4];     // x = 1 on OpenGL (render targets are bottom-up), y = 1 in a linear scene
    float rc[4];    // the rectangle of the source image the pass reads, as fractions: xy corner, zw size
    float size[4];  // xy = the camera's rectangle in pixels, zw = 1 / that
    float time[4];  // x = seconds of game time
};
static_assert(sizeof(PostParamsBlock) == 64, "fa_post_params is four vec4");

// What a pass draws with, copied out of the plan (the closures of the passes own it).
struct PassData {
    MaterialProgram program;
    float params[kMaxMaterialParams][4]{};
    int textureCount = 0;
    sg_view views[kMaxMaterialTextures]{};
    SamplerKind samplers[kMaxMaterialTextures]{};
    PostParamsBlock block{};
};

struct PixelRect {
    int x = 0, y = 0, w = 0, h = 0;
    bool whole = true;
};

// One full-screen triangle with the material's program into `pd`. `src`: the picture so far; `prepass`: bound only when the program
// declares it. `part`: the rectangle of the destination the pass covers (null: all of it). False (nothing drawn) when the target is gone or
// the program has no pipeline for this format.
bool draw_post(Gpu& gpu, const PassDesc& pd, const PassData& d, sg_view src, sg_view prepass, const PixelRect* part) {
    if (!pd.color.id || !src.id) return false;
    const bool usesPrepass = ((d.program.viewMask >> 1) & 1u) != 0;
    if (usesPrepass && !prepass.id) return false;
    const sg_pipeline pip = gpu.post_material_pipeline(pd.format, d.program.shader);
    if (!pip.id) return false;
    Gpu::begin_pass(pd);
    if (part) {
        sg_apply_viewport(part->x, part->y, part->w, part->h, true);
        sg_apply_scissor_rect(part->x, part->y, part->w, part->h, true);
    }
    sg_apply_pipeline(pip);
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[0] = src;
    b.samplers[0] = gpu.sampler(SamplerKind::LinearClamp);
    if (usesPrepass) {
        b.views[1] = prepass;
        b.samplers[1] = gpu.sampler(SamplerKind::Nearest);
    }
    for (int i = 0; i < d.textureCount; ++i) {
        b.views[kMaterialPostFirstView + i] = d.views[i];
        b.samplers[kMaterialPostFirstSampler + i] = gpu.sampler(d.samplers[i]);
    }
    // Only what the program declares: sokol rejects a binding the shader does not have.
    for (int i = 0; i < SG_MAX_VIEW_BINDSLOTS; ++i)
        if (!((d.program.viewMask >> i) & 1u)) b.views[i] = {};
    for (int i = 0; i < SG_MAX_SAMPLER_BINDSLOTS; ++i)
        if (!((d.program.samplerMask >> i) & 1u)) b.samplers[i] = {};
    sg_apply_bindings(&b);
    const float flip[4] = {d.block.a[0], 0.0f, 0.0f, 0.0f};
    const sg_range vr{flip, sizeof(flip)};
    sg_apply_uniforms(0, &vr);
    const sg_range fr{&d.block, sizeof(d.block)};
    sg_apply_uniforms(1, &fr);
    if (d.program.has_ub(kMaterialUbFragment)) {
        const std::size_t size = std::min<std::size_t>(d.program.ubSize[kMaterialUbFragment], sizeof(d.params));
        const sg_range mr{d.params, size};
        sg_apply_uniforms(kMaterialUbFragment, &mr);
    }
    sg_draw(0, 3, 1);
    Gpu::end_pass();
    return true;
}

const char* slot_name(PostSlot slot) {
    switch (slot) {
        case PostSlot::Main: return "main";
        case PostSlot::AfterSsr: return "ssr";
        case PostSlot::AfterShafts: return "shafts";
        case PostSlot::AfterDof: return "dof";
        case PostSlot::AfterBloom: return "bloom";
        default: break;
    }
    return "slot";
}

}  // namespace

CustomPostPlan make_custom_post_plan(const PostStack& stack, Assets& assets, std::vector<std::string>& fallbacks,
                                     std::unordered_set<std::string>& warned) {
    CustomPostPlan plan;
    for (const CustomPostPass& p : stack.custom) {
        if (!p.enabled) continue;
        const std::string label = p.name.empty() ? p.material : p.name;
        const MaterialUse* use = assets.post_material(p.material, p.params).use;
        std::string why;
        const MaterialProgram* prog = nullptr;
        if (!use || !use->material) {
            why = "the entry names no material";
        } else if (use->error) {
            why = use->material->ok
                      ? "its kind is \"" + std::string(material_kind_name(use->material->kind)) + "\", not \"post\""
                  : use->material->error.empty() ? "it did not build"
                                                 : use->material->error;
        } else if (use->material->programs[0].shader.id == 0) {
            why = "the material has no \"post\" program (regenerate it: factoria call material.generate)";
        } else {
            prog = &use->material->programs[0];
        }
        if (!prog) {
            note_fallback(fallbacks, p.material);
            const std::string key = p.material + "|" + why;
            if (warned.insert(key).second)
                FA_WARN("render",
                        "Custom post pass '{}' (material '{}') is skipped: {}. Hint: fix the material (factoria call "
                        "material.validate) or remove the entry from PostProcess.customPasses; the picture is drawn "
                        "without it.",
                        label, p.material, why);
            continue;
        }
        CustomPostEntry e;
        e.name = label;
        e.path = p.material;
        e.slot = p.slot;
        e.program = *prog;
        e.readsPrepass = ((prog->viewMask >> 1) & 1u) != 0;
        std::memcpy(e.params, use->params, sizeof(e.params));
        const MaterialAsset& m = *use->material;
        e.textureCount = int(std::min<std::size_t>(m.textures.size(), std::size_t(kMaxMaterialTextures)));
        for (int i = 0; i < e.textureCount; ++i) {
            e.views[i] = use->textures[i] ? use->textures[i]->gpu_view() : sg_view{};
            e.samplers[i] = m.textures[std::size_t(i)].sampler;
        }
        plan.entries.push_back(std::move(e));
    }
    return plan;
}

void CustomPost::forget_targets() {
    failed_.clear();
    probed_.clear();
    warnedTargets_ = false;
}

int CustomPost::add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, SceneFx& copier,
                           const CustomPostPlan& plan, PostSlot slot, const PostRect& rectIn, int picW, int picH,
                           ResourceId game, sg_view srcTex, const BloomTarget& dst, const PrepassRef& prepass,
                           bool linear, float time, int* drawCalls, std::vector<std::string>& fallbacks,
                           const std::string& job) {
    if (!plan.any_in(slot)) return 0;
    PixelRect rect;
    rect.whole = rectIn.whole(picW, picH);
    rect.x = rect.whole ? 0 : rectIn.x;
    rect.y = rect.whole ? 0 : rectIn.y;
    rect.w = rect.whole ? picW : rectIn.w;
    rect.h = rect.whole ? picH : rectIn.h;
    const sg_pixel_format fmt = gpu.scene_format();

    // The passes that can be drawn: one that reads the prepass of a camera without one, or that has no pipeline for the format of
    // the picture, is left out (the picture stays as the pass before left it).
    const TargetFormat scratchFormat{fmt, SG_PIXELFORMAT_NONE, 1};
    const TargetFormat dstFormat{fmt, SG_PIXELFORMAT_NONE, dst.samples};
    std::vector<const CustomPostEntry*> chain;
    for (const CustomPostEntry& e : plan.entries) {
        if (e.slot != slot) continue;
        std::string why;
        if (e.readsPrepass && !prepass.valid())
            why = "it reads the depth or the normals (fa_depth, fa_normal) and this camera has no depth and normal "
                  "prepass";
        else if (rect.w < 1 || rect.h < 1)
            why = "the camera's rectangle is empty";
        else if (!gpu.post_material_pipeline(scratchFormat, e.program.shader).id ||
                 !gpu.post_material_pipeline(dstFormat, e.program.shader).id)
            why = "the graphics backend could not make its pipeline";
        if (why.empty()) {
            chain.push_back(&e);
            continue;
        }
        note_fallback(fallbacks, e.path);
        if (warned_.insert(e.path + "|" + why).second)
            FA_WARN("render", "Custom post pass '{}' (material '{}') is skipped: {}. Hint: {}", e.name, e.path, why,
                    e.readsPrepass && !prepass.valid()
                        ? "the prepass exists for a camera that draws meshes; a 2D-only camera has no depth to read."
                        : "check the log above for the graphics backend's message.");
    }
    if (chain.empty()) return 0;
    const int n = int(chain.size());

    // The intermediate images: one for every result but the last (one more than that for a single pass, whose result is copied back).
    // The graph aliases the ones whose lifetimes do not overlap, so a long chain needs two. Make sure the GPU can have them, so a
    // failure is one warning here and not a pass that cannot run halfway through the frame.
    const int results = n == 1 ? 1 : n - 1;
    const int need = std::min(results, 2);
    TransientDesc sd;
    sd.width = rect.w;
    sd.height = rect.h;
    sd.format = scratchFormat;
    const std::uint64_t shapeKey = (std::uint64_t(rect.w) << 40) ^ (std::uint64_t(rect.h) << 16) ^ std::uint64_t(fmt) ^
                                   (std::uint64_t(need) << 62);
    if (std::find(failed_.begin(), failed_.end(), shapeKey) != failed_.end()) {
        for (const CustomPostEntry* e : chain) note_fallback(fallbacks, e->path);
        return 0;
    }
    if (std::find(probed_.begin(), probed_.end(), shapeKey) == probed_.end()) {  // once per shape, not every frame
        std::vector<std::uint64_t> held;
        bool ok = true;
        for (int i = 0; i < need && ok; ++i) {
            TransientDesc d = sd;
            d.label = job + "/custom-probe";
            const std::uint64_t h = targets.pool.acquire(d);
            if (h == 0)
                ok = false;
            else
                held.push_back(h);
        }
        for (std::uint64_t h : held) targets.pool.release(h);
        if (!ok) {
            if (failed_.size() >= kMaxProbed) failed_.erase(failed_.begin());
            failed_.push_back(shapeKey);
            for (const CustomPostEntry* e : chain) note_fallback(fallbacks, e->path);
            if (!warnedTargets_) {
                warnedTargets_ = true;
                FA_ERROR(
                    "render",
                    "Custom post passes: cannot create the intermediate images for a {}x{} camera; they are skipped. "
                    "Hint: lower the render scale, or remove the entries of PostProcess.customPasses.",
                    rect.w, rect.h);
            }
            return 0;
        }
        if (probed_.size() >= kMaxProbed) probed_.erase(probed_.begin());
        probed_.push_back(shapeKey);
    }

    std::vector<ResourceId> images;
    const std::string prefix = job + "/custom-" + slot_name(slot);
    for (int i = 0; i < results; ++i) {
        TransientDesc d = sd;
        d.label = prefix + "-image" + std::to_string(i);
        images.push_back(graph.create_transient(d));
    }

    int declared = 0;
    TransientTargets* tt = &targets;
    Gpu* g = &gpu;
    SceneFx* fx = &copier;
    const PostRectUv ruv = post_rect_uv(rectIn, picW, picH);
    const float gl = gpu.is_gl() ? 1.0f : 0.0f;
    const ResourceId pre = prepass.res;
    const PrepassRef prepassRef = prepass;
    auto add = [&](const std::string& name, std::vector<ResourceId> reads, std::vector<ResourceId> writes, auto&& fn) {
        GraphPass gp;
        gp.name = name;
        gp.reads = std::move(reads);
        gp.writes = std::move(writes);
        gp.execute = std::forward<decltype(fn)>(fn);
        graph.add_pass(std::move(gp));
        ++declared;
    };
    auto into_image = [tt](const PassContext& c, ResourceId r, const char* label) {
        const Target* t = tt->get(c.handle(r));
        PassDesc pd = t ? pass_into(*t, label) : PassDesc{};
        pd.colorLoad = SG_LOADACTION_DONTCARE;
        return pd;
    };
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
    auto view_of = [tt](const PassContext& c, ResourceId r) {
        const Target* t = tt->get(c.handle(r));
        return t ? t->texView : sg_view{};
    };

    for (int k = 0; k < n; ++k) {
        const CustomPostEntry& e = *chain[std::size_t(k)];
        auto data = std::make_shared<PassData>();
        data->program = e.program;
        std::memcpy(data->params, e.params, sizeof(data->params));
        data->textureCount = e.textureCount;
        for (int i = 0; i < e.textureCount; ++i) {
            data->views[i] = e.views[i];
            data->samplers[i] = e.samplers[i];
        }
        PostParamsBlock& u = data->block;
        u.a[0] = gl;
        u.a[1] = linear ? 1.0f : 0.0f;
        u.size[0] = float(rect.w);
        u.size[1] = float(rect.h);
        u.size[2] = 1.0f / float(rect.w);
        u.size[3] = 1.0f / float(rect.h);
        u.time[0] = time;
        const bool first = k == 0;
        const bool last = k == n - 1 && n > 1;  // a single pass draws into an image and is copied back
        if (first) {                            // reads the picture's rectangle
            u.rc[0] = ruv.x;
            u.rc[1] = ruv.y;
            u.rc[2] = ruv.w;
            u.rc[3] = ruv.h;
        } else {  // reads a whole image
            u.rc[2] = u.rc[3] = 1.0f;
        }
        std::vector<ResourceId> reads;
        reads.push_back(first ? game : images[std::size_t(k - 1)]);
        if (e.readsPrepass) reads.push_back(pre);
        if (last) {
            reads.push_back(game);
            add(prefix + "-pass" + std::to_string(k), std::move(reads), {game}, [=](const PassContext& c) {
                const Target* pt = prepassRef.target(c);
                const sg_view src = view_of(c, images[std::size_t(k - 1)]);
                if (draw_post(*g, into_picture("custom-post"), *data, src, pt ? pt->texView : sg_view{},
                              rect.whole ? nullptr : &rect))
                    ++*drawCalls;
            });
        } else {
            add(prefix + "-pass" + std::to_string(k), std::move(reads), {images[std::size_t(k)]},
                [=](const PassContext& c) {
                    const Target* pt = prepassRef.target(c);
                    const sg_view src = first ? srcTex : view_of(c, images[std::size_t(k - 1)]);
                    if (draw_post(*g, into_image(c, images[std::size_t(k)], "custom-post"), *data, src,
                                  pt ? pt->texView : sg_view{}, nullptr))
                        ++*drawCalls;
                });
        }
    }
    if (n == 1) {  // the result is in the image: copy it into the camera's rectangle of the picture
        const ResourceId image = images[0];
        add(prefix + "-copy", {image, game}, {game}, [=](const PassContext& c) {
            const int part[4] = {rect.x, rect.y, rect.w, rect.h};
            if (fx->copy_into(*g, into_picture("custom-post-copy"), view_of(c, image), rect.whole ? nullptr : part))
                ++*drawCalls;
        });
    }
    return declared;
}

}  // namespace fa::render
