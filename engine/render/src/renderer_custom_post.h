// Custom post-process passes (M72, "Post-process materials"): the full-screen passes of the entries of PostProcess.customPasses, each
// drawn by a kind "post" material (shaders/post_common.glsl; docs/SHADERS.md, "Post-process materials"). The entries come out of
// resolve_post_stack (PostStack::custom, fa/render/post_custom.h); this file turns them into passes of the frame graph.
//
// Where a pass goes: every entry names a PostSlot (a place between two built-in passes, post_custom.h). build_graph calls
// CustomPost::add_passes once per slot and per camera, at that place; the entries of the slot run in the order of the stack. Each pass
// reads the picture the one before wrote and, when its program declares it (the snippet calls fa_depth or fa_normal), the camera's
// prepass. A pass cannot read what it writes, so a chain draws into two scratch images of the picture's format and the camera's size,
// and the last pass draws back into the camera's rectangle of the picture:
//   1 pass:  picture -> scratch, then scratch -> picture (a copy)
//   2 passes: picture -> scratch, scratch -> picture
//   n passes: picture -> A, A -> B, B -> A, ... -> picture
//
// A pass that cannot be drawn (the material did not build or is not a post material, its prepass is missing, the intermediate images
// cannot be made) is SKIPPED, never drawn wrong: the picture stays as the pass before left it, the material's path goes to
// RenderStats::materialFallbacks and the log says why once.
#pragma once

#include <cstdint>
#include <string>
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
    float params[kMaxMaterialParams][4]{};
    int textureCount = 0;
    sg_view views[kMaxMaterialTextures]{};
    SamplerKind samplers[kMaxMaterialTextures]{};
};

// The passes of a camera. Empty (any() false) when it has none.
struct CustomPostPlan {
    std::vector<CustomPostEntry> entries;
    bool any() const { return !entries.empty(); }
    bool any_in(PostSlot slot) const {
        for (const CustomPostEntry& e : entries)
            if (e.slot == slot) return true;
        return false;
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

    // Declares the passes of `slot` for one camera in `graph`, after the passes that draw `game` (the imported picture, texture view
    // `srcTex`). `rect`: the camera's rectangle of the picture (picW x picH); `prepass`: its prepass (invalid: the passes that read it
    // are skipped); `dst`: where the result goes, as the bloom's (BloomTarget); `linear`: the picture holds linear light (the scene's
    // colour space); `time`: the game clock; `copier`: draws the copy of a one-pass chain. Each pass adds one to *drawCalls when it
    // runs. Returns the number of passes declared (0: nothing is drawn).
    int add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, SceneFx& copier, const CustomPostPlan& plan,
                   PostSlot slot, const PostRect& rect, int picW, int picH, ResourceId game, sg_view srcTex,
                   const BloomTarget& dst, const PrepassRef& prepass, bool linear, float time, int* drawCalls,
                   std::vector<std::string>& fallbacks, const std::string& job);

    // Forgets that creating the intermediate images failed (the game target was resized or recreated).
    void forget_targets();

private:
    std::vector<std::uint64_t> failed_;  // shapes whose images could not be made
    std::vector<std::uint64_t> probed_;  // shapes whose images were made once
    bool warnedTargets_ = false;
    std::unordered_set<std::string> warned_;  // problems of a pass that cannot be declared, said once
};

}  // namespace fa::render
