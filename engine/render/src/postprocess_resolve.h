// The CPU side of the post-processing stack (M71): which PostProcess components apply to a camera, and what the one stack of the
// frame is once they are blended. Pure CPU and deterministic (no GPU, no clock): the passes that draw the effects read the PostStack
// this builds and never look at the components. The data (the component, the canonical effect order, the neutral values) is in
// fa/scene/postprocess.h; the blending rules are documented in docs/design/ARCHITECTURE_RENDERING.md ("PostProcess").
#pragma once

#include <cstdint>

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
PostStack resolve_post_stack(World& world, const CameraGeometry& cam, const PostProcess* implicitOwn = nullptr);

}  // namespace fa::render
