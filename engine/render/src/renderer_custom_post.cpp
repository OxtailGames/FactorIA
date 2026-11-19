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
    // x = 1 on OpenGL (render targets are bottom-up), y = 1 in a linear scene, z = 1 when the history holds the frame
    // before
    float a[4];
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

// One full-screen triangle with the material's program into `pd`. `src`: the picture so far; `prepass`: bound only when
// the program declares it. `history`: the pass's own output of the frame before (bound only when the program declares
// it; when there is none, the picture stands in: fa_history_valid is false then and the shader does not read it).
// `part`: the rectangle of the destination the pass covers (null: all of it). False (nothing drawn) when the target is
// gone or the program has no pipeline for this format.
bool draw_post(Gpu& gpu, const PassDesc& pd, const PassData& d, sg_view src, sg_view prepass, sg_view history,
               const PixelRect* part) {
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
    b.views[kMaterialPostHistoryView] = history.id ? history : src;
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
        case PostSlot::AfterTonemap: return "tonemap";
        case PostSlot::AfterGrading: return "grading";
        case PostSlot::AfterVignette: return "vignette";
        case PostSlot::AfterSharpen: return "sharpen";
        case PostSlot::AfterOutline: return "outline";
        case PostSlot::AfterPosterize: return "posterize";
        case PostSlot::AfterGrain: return "grain";
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
        e.usesHistory = ((prog->viewMask >> kMaterialPostHistoryView) & 1u) != 0;
        for (const CustomPostEntry& before : plan.entries)
            if (before.path == e.path) ++e.ordinal;
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
    historyRefused_.clear();
    warnedTargets_ = false;
    release_history();
}

namespace {

// What the history images of all the slots may take (an estimate: a float format is eight bytes a pixel). A wasm32
// build has a quarter.
constexpr std::uint64_t kHistoryBudgetBytes =
    sizeof(void*) >= 8 ? (std::uint64_t(1) << 30) : (std::uint64_t(256) << 20);

std::uint64_t history_bytes(int w, int h, sg_pixel_format format) {
    const std::uint64_t perPixel = format == SG_PIXELFORMAT_RGBA32F ? 16 : format == SG_PIXELFORMAT_RGBA16F ? 8 : 4;
    return 2 * perPixel * std::uint64_t(std::max(w, 0)) * std::uint64_t(std::max(h, 0));
}

}  // namespace

std::uint64_t CustomPost::history_budget() const { return historyBudget_ ? historyBudget_ : kHistoryBudgetBytes; }

void CustomPost::release_history() {
    for (auto& entry : history_)
        for (Target& t : entry.second->img) destroy_target(t);
    history_.clear();
}

void CustomPost::sweep_history(std::uint64_t frame) {
    for (auto it = history_.begin(); it != history_.end();) {
        if (frame >= it->second->planned && frame - it->second->planned >= kHistoryIdleFrames) {
            for (Target& t : it->second->img) destroy_target(t);
            it = history_.erase(it);
        } else {
            ++it;
        }
    }
}

void CustomPost::release_history_of(std::uint64_t camera) {
    for (auto it = history_.begin(); it != history_.end();) {
        if (it->second->camera == camera) {
            for (Target& t : it->second->img) destroy_target(t);
            it = history_.erase(it);
        } else {
            ++it;
        }
    }
}

void CustomPost::reset_history(std::uint64_t camera) {
    for (auto& entry : history_)
        if (camera == 0 || entry.second->camera == camera) entry.second->wrote = false;
}

int CustomPost::history_image_count() const {
    int count = 0;
    for (const auto& entry : history_)
        for (const Target& t : entry.second->img)
            if (t.valid()) ++count;
    return count;
}

std::shared_ptr<CustomPost::HistorySlot> CustomPost::plan_history(const CustomHistoryFrame& hf, const HistoryKey& key,
                                                                  int w, int h, sg_pixel_format format,
                                                                  const std::string& label) {
    // The GPU refused the images of this pass in this shape before: not asked again every frame (a resize or a format
    // change, or forget_targets, lets it try again). The budget is not remembered: it is a sum of what the other slots
    // hold now.
    if (const auto it = historyRefused_.find(key); it != historyRefused_.end()) {
        if (it->second.w == w && it->second.h == h && it->second.format == format) return nullptr;
        historyRefused_.erase(it);
    }
    std::shared_ptr<HistorySlot> slot;
    if (const auto it = history_.find(key); it != history_.end()) slot = it->second;
    const bool fits =
        slot && slot->w == w && slot->h == h && slot->format == format && slot->img[0].valid() && slot->img[1].valid();
    if (!fits) {
        // The budget counts every other slot's images (this one, if it exists, is made again).
        std::uint64_t used = 0;
        for (const auto& entry : history_)
            if (entry.second != slot) used += history_bytes(entry.second->w, entry.second->h, entry.second->format);
        const std::uint64_t wanted = history_bytes(w, h, format);
        if (!slot) slot = std::make_shared<HistorySlot>();
        for (Target& t : slot->img) destroy_target(t);
        slot->wrote = false;
        const std::uint64_t budget = history_budget();
        const bool inBudget = used + wanted <= budget;
        bool ok = inBudget;
        if (ok) ++historyAttempts_;
        for (int i = 0; i < 2 && ok; ++i) {
            TargetDesc d;
            d.label = i == 0 ? "post-history-0" : "post-history-1";
            d.width = w;
            d.height = h;
            d.colorFormat = format;
            if (refuseHistory_) {  // a GPU that says no (tests): checked before a target is allocated
                ok = false;
                break;
            }
            slot->img[i] = make_target(d);
            ok = slot->img[i].valid();
        }
        if (!ok) {
            for (Target& t : slot->img) destroy_target(t);
            history_.erase(key);
            if (inBudget) {  // the GPU said no
                if (historyRefused_.size() >= kMaxProbed && !historyRefused_.contains(key)) {
                    // The oldest refusal goes (the smallest sequence number), not whichever key sorts first.
                    auto oldest = historyRefused_.begin();
                    for (auto it = historyRefused_.begin(); it != historyRefused_.end(); ++it)
                        if (it->second.seq < oldest->second.seq) oldest = it;
                    historyRefused_.erase(oldest);
                }
                historyRefused_[key] = RefusedShape{w, h, format, ++refusedSeq_};
            }
            if (!warnedHistory_) {
                warnedHistory_ = true;
                FA_ERROR("render",
                         "Custom post pass '{}' keeps a history of {}x{} and the renderer cannot hold it (the history "
                         "images take at "
                         "most {} MB, or the GPU refused them); it is drawn without its history (fa_history_valid is "
                         "false). Hint: "
                         "lower the render scale or the number of passes that call fa_history.",
                         label, w, h, budget >> 20);
            }
            return nullptr;
        }
        slot->w = w;
        slot->h = h;
        slot->format = format;
        slot->camera = std::get<0>(key);
        history_[key] = slot;
    }
    slot->valid = slot->wrote && slot->serial + 1 == hf.serial && slot->scene == hf.scene && hf.continuous;
    slot->read = slot->last;
    slot->write = 1 - slot->last;
    slot->planned = hf.frame;
    return slot;
}

int CustomPost::add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, SceneFx& copier,
                           const CustomPostPlan& plan, std::uint32_t slots, const PostRect& rectIn, int picW, int picH,
                           ResourceId game, sg_view srcTex, const BloomTarget& dst, sg_pixel_format fmt,
                           const PrepassRef& prepass, bool linear, float time, int* drawCalls,
                           std::vector<std::string>& fallbacks, const std::string& job) {
    if (!plan.any_in_mask(slots)) return 0;
    int firstSlot = 0;  // the first place of the mask: it names the passes
    while (((slots >> firstSlot) & 1u) == 0) ++firstSlot;
    const PostSlot slot = PostSlot(firstSlot);
    PixelRect rect;
    rect.whole = rectIn.whole(picW, picH);
    rect.x = rect.whole ? 0 : rectIn.x;
    rect.y = rect.whole ? 0 : rectIn.y;
    rect.w = rect.whole ? picW : rectIn.w;
    rect.h = rect.whole ? picH : rectIn.h;

    // The passes that can be drawn: one that reads the prepass of a camera without one, or that has no pipeline for the
    // format of the picture, is left out (the picture stays as the pass before left it).
    const TargetFormat scratchFormat{fmt, SG_PIXELFORMAT_NONE, 1};
    const TargetFormat dstFormat{fmt, SG_PIXELFORMAT_NONE, dst.samples};
    std::vector<const CustomPostEntry*> chain;
    std::vector<const CustomPostEntry*> wanted;
    for (const CustomPostEntry& e : plan.entries)
        if (((slots >> int(e.slot)) & 1u) != 0) wanted.push_back(&e);
    std::stable_sort(wanted.begin(), wanted.end(),
                     [](const CustomPostEntry* a, const CustomPostEntry* b) { return int(a->slot) < int(b->slot); });
    for (const CustomPostEntry* ep : wanted) {
        const CustomPostEntry& e = *ep;
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

    // The passes that keep a history draw into an image of their slot (ping-pong: they read the one they wrote the
    // frame before); the others into a scratch image, and the last of a chain with several passes straight into the
    // picture. A slot that cannot be made leaves its pass without history (drawn as any other, fa_history_valid false).
    // A frame that is not one of the game's (a capture_world) reads and writes no history either.
    std::vector<std::shared_ptr<HistorySlot>> hist(static_cast<std::size_t>(n));
    if (plan.history.game) {
        for (int k = 0; k < n; ++k) {
            const CustomPostEntry& e = *chain[std::size_t(k)];
            if (e.usesHistory)
                hist[std::size_t(k)] =
                    plan_history(plan.history, HistoryKey{plan.history.camera, plan.history.job, e.path, e.ordinal},
                                 rect.w, rect.h, fmt, e.name);
        }
    }
    // The number of the scratch image each pass writes; -1 for the pass that writes the picture or an image of its
    // history.
    std::vector<int> scratchOf(static_cast<std::size_t>(n), -1);
    int results = 0;
    for (int k = 0; k < n; ++k)
        if (!hist[std::size_t(k)] && !(k == n - 1 && n > 1)) scratchOf[std::size_t(k)] = results++;

    // The intermediate images: one for every result but the last (one more than that for a single pass, whose result is
    // copied back). The graph aliases the ones whose lifetimes do not overlap, so a long chain needs two. Make sure the
    // GPU can have them, so a failure is one warning here and not a pass that cannot run halfway through the frame.
    const int need = std::min(results, 2);
    TransientDesc sd;
    sd.width = rect.w;
    sd.height = rect.h;
    sd.format = scratchFormat;
    const std::uint64_t shapeKey = (std::uint64_t(rect.w) << 40) ^ (std::uint64_t(rect.h) << 16) ^ std::uint64_t(fmt) ^
                                   (std::uint64_t(need) << 62);
    if (need > 0 && std::find(failed_.begin(), failed_.end(), shapeKey) != failed_.end()) {
        for (const CustomPostEntry* e : chain) note_fallback(fallbacks, e->path);
        return 0;
    }
    if (need > 0 &&
        std::find(probed_.begin(), probed_.end(), shapeKey) == probed_.end()) {  // once per shape, not every frame
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

    // What every pass of the chain writes: a scratch image of the frame, or an image of its history slot (imported: the
    // renderer owns it). The pass that draws into the picture has no `res`.
    struct Out {
        ResourceId res;
        std::shared_ptr<HistorySlot> hs;  // set: the image img[writeIdx] of the slot
        int writeIdx = 0;
    };
    std::vector<Out> out(static_cast<std::size_t>(n));
    std::vector<ResourceId> historyRead(
        static_cast<std::size_t>(n));  // the imported image a valid history is read from
    const std::string prefix = job + "/custom-" + slot_name(slot);
    for (int k = 0; k < n; ++k) {
        Out& o = out[std::size_t(k)];
        if (const auto& hs = hist[std::size_t(k)]) {
            TransientDesc d = sd;
            d.label = prefix + "-history" + std::to_string(k);
            o.hs = hs;
            o.writeIdx = hs->write;
            o.res = graph.import_target(d.label + "-out", hs->img[hs->write].color.id, d);
            if (hs->valid)
                historyRead[std::size_t(k)] = graph.import_target(d.label + "-in", hs->img[hs->read].color.id, d);
        } else if (scratchOf[std::size_t(k)] >= 0) {
            TransientDesc d = sd;
            d.label = prefix + "-image" + std::to_string(scratchOf[std::size_t(k)]);
            o.res = graph.create_transient(d);
        }
    }

    int declared = 0;
    TransientTargets* tt = &targets;
    Gpu* g = &gpu;
    SceneFx* fx = &copier;
    const PostRectUv ruv = post_rect_uv(rectIn, picW, picH);
    const float gl = gpu.is_gl() ? 1.0f : 0.0f;
    const ResourceId pre = prepass.res;
    const PrepassRef prepassRef = prepass;
    const CustomHistoryFrame hf = plan.history;
    auto add = [&](const std::string& name, std::vector<ResourceId> reads, std::vector<ResourceId> writes, auto&& fn) {
        GraphPass gp;
        gp.name = name;
        gp.reads = std::move(reads);
        gp.writes = std::move(writes);
        gp.execute = std::forward<decltype(fn)>(fn);
        graph.add_pass(std::move(gp));
        ++declared;
    };
    auto into_image = [tt](const PassContext& c, const Out& o, const char* label) {
        PassDesc pd;
        if (o.hs) {
            pd = pass_into(o.hs->img[o.writeIdx], label);
        } else {
            const Target* t = tt->get(c.handle(o.res));
            pd = t ? pass_into(*t, label) : PassDesc{};
        }
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
    auto view_of = [tt](const PassContext& c, const Out& o) {
        if (o.hs) return o.hs->img[o.writeIdx].texView;
        const Target* t = tt->get(c.handle(o.res));
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
        const std::shared_ptr<HistorySlot> hs = hist[std::size_t(k)];
        const bool histValid = hs && hs->valid;
        PostParamsBlock& u = data->block;
        u.a[0] = gl;
        u.a[1] = linear ? 1.0f : 0.0f;
        u.a[2] = histValid ? 1.0f : 0.0f;
        u.size[0] = float(rect.w);
        u.size[1] = float(rect.h);
        u.size[2] = 1.0f / float(rect.w);
        u.size[3] = 1.0f / float(rect.h);
        u.time[0] = time;
        const bool first = k == 0;
        const bool direct =
            k == n - 1 && n > 1 && !hs;  // draws into the picture; the others into an image (copied back after)
        if (first) {                     // reads the picture's rectangle
            u.rc[0] = ruv.x;
            u.rc[1] = ruv.y;
            u.rc[2] = ruv.w;
            u.rc[3] = ruv.h;
        } else {  // reads a whole image
            u.rc[2] = u.rc[3] = 1.0f;
        }
        const Out prev = first ? Out{} : out[std::size_t(k - 1)];
        const Out self = out[std::size_t(k)];
        const sg_view histView = histValid ? hs->img[hs->read].texView : sg_view{};
        std::vector<ResourceId> reads;
        reads.push_back(first ? game : prev.res);
        if (e.readsPrepass) reads.push_back(pre);
        if (histValid) reads.push_back(historyRead[std::size_t(k)]);
        if (direct) {
            reads.push_back(game);
            add(prefix + "-pass" + std::to_string(k), std::move(reads), {game}, [=](const PassContext& c) {
                const Target* pt = prepassRef.target(c);
                const sg_view src = view_of(c, prev);
                if (draw_post(*g, into_picture("custom-post"), *data, src, pt ? pt->texView : sg_view{}, histView,
                              rect.whole ? nullptr : &rect))
                    ++*drawCalls;
            });
        } else {
            add(prefix + "-pass" + std::to_string(k), std::move(reads), {self.res}, [=](const PassContext& c) {
                const Target* pt = prepassRef.target(c);
                const sg_view src = first ? srcTex : view_of(c, prev);
                const bool drew = draw_post(*g, into_image(c, self, "custom-post"), *data, src,
                                            pt ? pt->texView : sg_view{}, histView, nullptr);
                if (drew) ++*drawCalls;
                if (drew && hs) {  // what the next frame's pass reads
                    hs->wrote = true;
                    hs->last = self.writeIdx;
                    hs->serial = hf.serial;
                    hs->scene = hf.scene;
                }
            });
        }
    }
    if (n == 1 ||
        hist[std::size_t(n - 1)]) {  // the result is in an image: copy it into the camera's rectangle of the picture
        const Out last = out[std::size_t(n - 1)];
        add(prefix + "-copy", {last.res, game}, {game}, [=](const PassContext& c) {
            const int part[4] = {rect.x, rect.y, rect.w, rect.h};
            if (fx->copy_into(*g, into_picture("custom-post-copy"), view_of(c, last), rect.whole ? nullptr : part))
                ++*drawCalls;
        });
    }
    return declared;
}

}  // namespace fa::render
