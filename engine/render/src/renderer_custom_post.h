// Custom post-process passes (M72, "Post-process materials"): the full-screen passes of the entries of PostProcess.customPasses, each
// drawn by a kind "post" material (shaders/post_common.glsl; docs/shaders/SHADERS_POST.md). The entries come out of
// resolve_post_stack (PostStack::custom, fa/render/post_custom.h); this file turns them into passes of the frame graph.
//
// Where a pass goes: every entry names a PostSlot (a place between two built-in passes, post_custom.h). build_graph calls
// CustomPost::add_passes once per slot and per camera, at that place; the entries of the slot run in the order of the stack. The
// places after the tonemap (post_slot_is_ldr) work on the picture the final pass made so far: build_graph cuts the final pass in
// pieces there (PostSlice, postprocess.h) and calls add_passes on the image between two pieces; places with nothing drawn between
// them share one call. Each pass
// reads the picture the one before wrote and, when its program declares it (the snippet calls fa_depth or fa_normal), the camera's
// prepass. A pass cannot read what it writes, so a chain draws into two scratch images of the picture's format and the camera's size,
// and the last pass draws back into the camera's rectangle of the picture:
//   1 pass:  picture -> scratch, then scratch -> picture (a copy)
//   2 passes: picture -> scratch, scratch -> picture
//   n passes: picture -> A, A -> B, B -> A, ... -> picture
//
// History (docs/shaders/SHADERS_POST.md, "History"): a pass whose snippet calls fa_history(uv) reads its OWN output of the frame before. The
// renderer keeps it in two images of the camera's rectangle size and the picture's format, one pair per camera and per pass (a CustomHistory
// slot), and the pass draws into one of them while it reads the other (ping-pong: no copy, and the image the pass writes is the one the
// next pass of the chain reads, so it costs nothing extra; the only extra draw is the copy into the picture when it is the last pass of the
// chain, which a chain of one pass does anyway). The slot is made when a frame plans a pass that asks, and freed kHistoryIdleFrames frames
// after the last frame that did. The history is not valid (fa_history_valid is false and fa_history gives the picture) in the first frame of a
// slot, when the images were made again (a resize, a scale or format change), when the camera was not drawn in the frame before or the
// scene changed or its clock jumped (CustomHistoryFrame::continuous), after reset_history, and in a frame that is not one of the game's.
//
// A pass that cannot be drawn (the material did not build or is not a post material, its prepass is missing, the intermediate images
// cannot be made) is SKIPPED, never drawn wrong: the picture stays as the pass before left it, the material's path goes to
// RenderStats::materialFallbacks and the log says why once.
#pragma once

#include <algorithm>
#include <cstdint>
#include <map>
#include <memory>
#include <string>
#include <tuple>
#include <unordered_set>
#include <vector>

#include "fa/render/post_custom.h"

#include "bloom.h"
#include "frame_graph.h"
#include "render_internal.h"
#include "transient_targets.h"

namespace fa::render {

struct PostStack;
struct PostRect;
struct PrepassRef;
class SceneFx;

// One pass of the plan: a material that built, with what the frame draws it with (copied, so the pass never reads the asset's own
// records).
struct CustomPostEntry {
    std::string name;  // the entry's name, or its material's path
    std::string path;  // the material
    PostSlot slot = PostSlot::AfterBloom;
    MaterialProgram program;  // the material's one program ("post")
    bool readsPrepass = false;
    bool usesHistory = false;  // the snippet calls fa_history: the program declares the history view
    int ordinal =
        0;  // how many entries before it in the plan use the same material: with the material, which history slot it is
    float params[kMaxMaterialParams][4]{};
    int textureCount = 0;
    sg_view views[kMaxMaterialTextures]{};
    SamplerKind samplers[kMaxMaterialTextures]{};
};

// What a camera tells the passes that keep a history about this frame (plan_job fills it).
struct CustomHistoryFrame {
    std::uint64_t camera =
        0;        // Entity::bits() of the camera: its passes' histories are its own, so a camera never reads another's
    int job = 0;  // which job of that camera in this frame (0 = the first): two views of one camera keep two histories
    std::uint64_t serial = 0;  // Renderer::Impl::postSerial: the frames of the game (a capture_world does not count)
    std::uint64_t frame = 0;   // Renderer::Impl::frameSerial: the idle count of the slots
    std::uint64_t scene =
        0;  // a hash of the scene's path and load count: another scene (or a reload) starts the histories again
    bool continuous =
        false;  // the camera was drawn in the frame before and the world's clock did not jump (PostPlan::prevValid)
    bool game =
        false;  // a frame of the game; false (capture_world, a frame the plan did not set up): no history is read or written
};

// The passes of a camera. Empty (any() false) when it has none.
struct CustomPostPlan {
    std::vector<CustomPostEntry> entries;
    CustomHistoryFrame history;
    bool any() const { return !entries.empty(); }
    bool any_in(PostSlot slot) const {
        for (const CustomPostEntry& e : entries)
            if (e.slot == slot) return true;
        return false;
    }
    // Some entry is at one of the places of `slots` (bit `int(slot)` each).
    bool any_in_mask(std::uint32_t slots) const {
        for (const CustomPostEntry& e : entries)
            if (((slots >> int(e.slot)) & 1u) != 0) return true;
        return false;
    }
    // Some entry works on the display-referred picture (post_slot_is_ldr): the final pass is cut for it.
    bool any_ldr() const {
        for (const CustomPostEntry& e : entries)
            if (post_slot_is_ldr(e.slot)) return true;
        return false;
    }
    // Some entry works on the scene-linear picture (before the final pass).
    bool any_hdr() const {
        for (const CustomPostEntry& e : entries)
            if (!post_slot_is_ldr(e.slot)) return true;
        return false;
    }
    // Takes the display-referred entries away (the images the final pass is cut with could not be made).
    void drop_ldr() {
        entries.erase(std::remove_if(entries.begin(), entries.end(),
                                     [](const CustomPostEntry& e) { return post_slot_is_ldr(e.slot); }),
                      entries.end());
    }
    // Some pass reads the depth or the normals: the camera must make the prepass (renderer_draw.cpp, plan_prepass).
    bool reads_prepass() const {
        for (const CustomPostEntry& e : entries)
            if (e.readsPrepass) return true;
        return false;
    }
};

// The plan of a camera: asks `assets` for the material of every enabled entry of `stack` (builds it on the first use; render thread). An
// entry whose material is missing, broken or of another kind is left out: its path goes to `fallbacks` (once) and `warned` keeps one log
// line per problem.
CustomPostPlan make_custom_post_plan(const PostStack& stack, Assets& assets, std::vector<std::string>& fallbacks,
                                     std::unordered_set<std::string>& warned);

class CustomPost {
public:
    CustomPost() = default;
    CustomPost(const CustomPost&) = delete;
    CustomPost& operator=(const CustomPost&) = delete;

    // Declares the passes of `slots` (a mask, bit int(PostSlot) each; the entries of the stack that sit at any of them, in the order of
    // the places and then of the stack) for one camera in `graph`, after the passes that draw `game` (the picture: the imported game
    // target, or one of the images the final pass is cut with; texture view `srcTex`, pixel format `format`). `rect`: the camera's
    // rectangle of the picture (picW x picH); `prepass`: its prepass (invalid: the passes that read it are skipped); `dst`: where the
    // result goes, as the bloom's (BloomTarget); `linear`: the picture holds linear light (a linear scene before the final pass; false
    // for the display-referred places); `time`: the game clock; `copier`: draws the copy of a one-pass chain. Each pass adds one to
    // *drawCalls when it runs. Returns the number of passes declared (0: nothing is drawn).
    int add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, SceneFx& copier, const CustomPostPlan& plan,
                   std::uint32_t slots, const PostRect& rect, int picW, int picH, ResourceId game, sg_view srcTex,
                   const BloomTarget& dst, sg_pixel_format format, const PrepassRef& prepass, bool linear, float time,
                   int* drawCalls, std::vector<std::string>& fallbacks, const std::string& job);

    // Forgets that creating the intermediate images failed (the game target was resized or recreated) and frees every history image.
    void forget_targets();

    // Frees the history of the slots no frame planned in kHistoryIdleFrames frames (`frame`: the renderer's frameSerial; once per frame).
    void sweep_history(std::uint64_t frame);
    // Frees all the history images (the context is going away, or the game target changed size).
    void release_history();
    // The next frame of the pass(es) of `camera` (Entity::bits(); 0 = every camera) starts its history again.
    void reset_history(std::uint64_t camera);
    // The images the histories hold now (a test).
    int history_image_count() const;

    static constexpr std::uint64_t kHistoryIdleFrames =
        120;  // frames, not seconds: the result does not depend on the CPU

private:
    // The history of one pass of one camera. `read` and `write` are chosen when the frame plans the pass; `wrote` is set by the pass when it
    // really drew, so the next frame reads only what exists. The passes of the frame share the slot, so it outlives a release.
    struct HistorySlot {
        Target img[2];
        int w = 0, h = 0;
        sg_pixel_format format = SG_PIXELFORMAT_NONE;
        std::uint64_t camera = 0, serial = 0, planned = 0, scene = 0;
        int last = 0;        // the image the pass wrote in frame `serial`
        bool wrote = false;  // it did
        int read = 1, write = 0;
        bool valid = false;  // this frame's plan: img[read] holds the pass's output of the frame before
    };
    // The slot of a pass for this frame: made (or made again) when missing or of another size or format; null when the GPU cannot make
    // its images (one warning). `valid` is decided here.
    // camera, job, material path, how many entries before it use the same material
    using HistoryKey = std::tuple<std::uint64_t, int, std::string, int>;
    std::shared_ptr<HistorySlot> plan_history(const CustomHistoryFrame& hf, const HistoryKey& key, int w, int h,
                                              sg_pixel_format format, const std::string& label);
    std::map<HistoryKey, std::shared_ptr<HistorySlot>> history_;
    bool warnedHistory_ = false;

    std::vector<std::uint64_t> failed_;  // shapes whose images could not be made
    std::vector<std::uint64_t> probed_;  // shapes whose images were made once
    bool warnedTargets_ = false;
    std::unordered_set<std::string> warned_;  // problems of a pass that cannot be declared, said once
};

}  // namespace fa::render
