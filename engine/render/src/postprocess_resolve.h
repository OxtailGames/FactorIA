// The CPU side of the post-processing stack (M71): which PostProcess components apply to a camera, and what the one stack of the
// frame is once they are blended. Pure CPU and deterministic (no GPU, no clock): the passes that draw the effects read the PostStack
// this builds and never look at the components. The data (the component, the canonical effect order, the neutral values) is in
// fa/scene/postprocess.h; the blending rules are documented in docs/design/ARCHITECTURE_RENDERING.md ("PostProcess").
#pragma once

#include <array>
#include <cstdint>
#include <string>
#include <unordered_map>
#include <vector>

#include "fa/scene/camera_geometry.h"
#include "fa/scene/postprocess.h"
#include "fa/scene/world.h"

namespace fa::render {

// The stack a camera draws a frame with. `fx` is a plain PostProcess whose values are already blended: `fx.<effect>Enabled` says
// which effects run (they run in kPostEffectOrder), the other fields of an effect are its parameters, the meta fields (shape, size,
// blendDistance, priority, weight) are meaningless in it. A passes reads `fx` and `mask`, nothing else.
struct PostStack {
    PostProcess fx = postprocess_neutral();
    std::uint32_t mask = 0;  // bit i is set when the effect PostEffect(i) runs (the same as fx.<effect>Enabled)
    int sources =
        0;  // how many components contributed: the camera's own (if any) plus the volumes with an influence above 0

    bool has(PostEffect e) const { return (mask >> int(e)) & 1u; }
    bool any() const { return mask != 0; }
    int effect_count() const;  // how many effects run
};

// Where the values of a PostStack came from, filled by resolve_post_stack when the caller passes one (the postprocess.get command and
// the editor's panel show it; the renderer never asks, so a frame pays nothing).
struct PostLayer {
    enum class Kind {
        Own,
        Volume,
        Legacy
    };  // the camera's own PostProcess, a volume, the deprecated Camera.bloom* / colorFilter
    Kind kind = Kind::Own;
    Entity entity = kNullEntity;  // the entity that holds it (the camera for Own and Legacy)
    float weight = 1.0f;          // PostProcess.weight, clamped to 0..1
    float influence = 1.0f;  // how deep the camera is inside the volume (1 for the camera's own and for global volumes)
    float strength() const { return weight * influence; }  // what the layer was applied with
};
struct PostTrace {
    std::vector<PostLayer> layers;  // in the order they were applied: own first, then ascending priority
    std::array<std::vector<int>, kPostEffectCount>
        effectLayers{};  // per effect: the indices into `layers` that switch it on
    // Per parameter field (its name): the index into `layers` of the layer whose value it is (the last one that wrote it; for a
    // number blended by several, the last of them), -1 for the neutral default (no layer switched its effect on, or a switch
    // such as a mode that the layers were too weak to change).
    std::unordered_map<std::string, int> fieldLayer;
};

// The PostProcess standing in for the deprecated Camera.bloom* and Camera.colorFilter fields of `cam` (hard knee, the same picture as
// before the stack existed): false (and `out` left alone) when the camera uses neither. Shared by Renderer::Impl::build_camera and
// post_stack_report, so both see the same stack.
bool legacy_post_of_camera(const Camera& cam, PostProcess& out);

// What an effect reads from the prepass (renderer_draw.cpp, "prepass"; ARCHITECTURE_RENDERING.md, "PostProcess"): the linear view-space
// depth of the opaque 3D meshes, and their view-space normals. Pure tables, so the gating of the prepass is testable without a GPU. The
// outline needs both (depth and normal edges), fog and sun shafts and depth of field and motion blur the depth, ssao and ssr both.
constexpr bool post_effect_needs_depth(PostEffect e) {
    return e == PostEffect::Ssao || e == PostEffect::Ssr || e == PostEffect::Fog || e == PostEffect::SunShafts ||
           e == PostEffect::DepthOfField || e == PostEffect::MotionBlur || e == PostEffect::Outline;
}
constexpr bool post_effect_needs_normals(PostEffect e) {
    return e == PostEffect::Ssao || e == PostEffect::Ssr || e == PostEffect::Outline;
}
// The same for a mask of effects (bit i = PostEffect(i), PostStack::mask).
constexpr bool post_mask_needs(std::uint32_t mask, bool (*needs)(PostEffect)) {
    for (int i = 0; i < kPostEffectCount; ++i)
        if (((mask >> i) & 1u) && needs(PostEffect(i))) return true;
    return false;
}
constexpr bool post_mask_needs_depth(std::uint32_t mask) { return post_mask_needs(mask, post_effect_needs_depth); }
constexpr bool post_mask_needs_normals(std::uint32_t mask) { return post_mask_needs(mask, post_effect_needs_normals); }

// How much the volume `vol` (a PostProcess on an entity without a Camera, whose world matrix is `world`) applies at `point`, 0..1:
// 1 inside the shape (or always for shape global), falling linearly to 0 over blendDistance outside it, and 0 beyond. The shape is
// turned and scaled with the entity (the box by its rotation and scale, the circle and the sphere by the largest scale of the axes
// they use). A camera that is not perspective is tested in x and y only (the z of a 2D camera is only its draw order): the box
// becomes a rectangle, the sphere a circle. NaN and infinite sizes give 0. Does not include `vol.weight`.
float post_volume_influence(const PostProcess& vol, const Mat4& world, Vec3 point, bool perspective);

// The stack of `cam`: starts from the neutral stack (every effect off), applies the camera's own PostProcess (when its entity has
// one and it is enabled), then every enabled volume in ascending priority (equal priorities by the entity ids, ascending, so the
// last one wins), each with the strength weight * post_volume_influence at the camera's position (volumes of strength 0 are
// skipped). Applying a component with strength s:
//  - an effect the component switches on and the stack has off is first set to its neutral values (postprocess_neutral()), then
//    blended like the others, so it fades in from nothing; an effect the component leaves off changes nothing;
//  - numbers, vectors and colours of an effect it has on are interpolated: stack = stack * (1 - s) + component * s (integers
//    rounded);
//  - everything else (switches, modes, textures and LUTs, curves, the autofocus entity, strings) switches to the component's value
//    when s >= 0.5 and stays when below.
// Entities that are not active in the hierarchy contribute nothing. Costs one count when the world has no PostProcess.
// `implicitOwn` (optional) stands in for the camera's own component when it has none (or it is disabled): the renderer passes one made
// of the deprecated Camera.bloom* and Camera.colorFilter fields, so a camera that uses them still gets its bloom and filter.
// `trace` (optional) records which layer every value came from.
PostStack resolve_post_stack(World& world, const CameraGeometry& cam, const PostProcess* implicitOwn = nullptr,
                             PostTrace* trace = nullptr);

}  // namespace fa::render
