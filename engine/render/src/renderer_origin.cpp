// The renderer and the floating origin (M75.4b; docs/BIG_WORLDS_STREAMING.md "Floating origin", docs/design/ARCHITECTURE_RENDERING_BIGWORLDS.md "The floating
// origin"). World::rebase moves every local position by -offset and calls the observers of the world; the renderer's observer moves what
// the renderer keeps in world space across frames by the same offset, so the frame after a rebase is the frame it would have drawn with no
// rebase. The callback runs on the main thread between frames (after a fixed tick, a command or a script): no render job exists then.
#include "renderer_impl.h"

namespace fa {

void Renderer::Impl::unwatch_world() {
    if (originObserver != 0 && originWorld && !originWorldAlive.expired())
        originWorld->remove_origin_observer(originObserver);
    // A world that was destroyed took its observers with it (they are never called after that): nothing to remove.
    originWorld = nullptr;
    originWorldAlive.reset();
    originObserver = 0;
}

void Renderer::Impl::watch_world(World& world) {
    if (originWorld == &world && originObserver != 0 && !originWorldAlive.expired())
        return;       // the common frame: one compare
    unwatch_world();  // another world (or a world made at the address of one that died): leave the old one
    originWorld = &world;
    originWorldAlive = world.lifetime();
    originObserver = world.on_origin_shifted([this, w = &world](const DVec3& offset) { origin_shifted(*w, offset); });
}

void Renderer::Impl::watch_world_if_free(World& world) {
    // A capture of another world (a preview, a graph's) must not take the observer from the world the game draws: that world could
    // rebase before the next update() found it again. A renderer that watches nothing (only captures so far), or a world that died,
    // takes this one.
    if (originWorld && originWorld != &world && !originWorldAlive.expired()) return;
    watch_world(world);
}

void Renderer::Impl::origin_shifted(World& world, const DVec3& offset) {
    if (!initialized) return;  // nothing is kept yet, and the counter is of the rebases the renderer followed
    ++originShifts;
    // A rebase moves by a multiple of the step (exact in float); set_origin's offset is any double, rounded here.
    const Vec3 off{float(offset.x), float(offset.y), float(offset.z)};
    // The cameras the effects reproject from: the previous camera is where the current one would have been, `offset` farther away. A
    // point that did not move now has the coordinates q' = q - offset, and the matrix of the frame before knew it as q' + offset.
    const Mat4 back = Mat4::translate(off);
    for (auto& [key, prev] : prevViewProj) {
        prev.viewProj = prev.viewProj * back;
        prev.before = prev.before * back;
        prev.jittered =
            prev.jittered * back;  // the jitter is in clip space: it moves with the matrix, not with the world
        prev.beforeJittered = prev.beforeJittered * back;
    }
    // The 2D GI field and its irradiance history (units of the Transform: 2D pixels).
    gi2d.shift(offset.x, offset.y);
    // The realtime GI grids: the entity moved with the world, so the grid is laid out `offset` closer to 0, and the anchor that decides
    // whether it moved by half a spacing moves with it: no probe is captured again.
    for (auto& [id, grid] : probes.gi.grids) {
        grid.anchor -= off;
        grid.layout.origin -= off;
    }
    // The boxes the occlusion debug view draws from the frame before are world positions too.
    for (OcclusionShown* shown : {&occlusionShown, &occlusionPrev})
        for (OcclusionShown::Box& box : shown->boxes)
            for (Vec3& corner : box.corners) corner -= off;
    // The depth pyramids' cameras and the boxes the GPU culling's debug view draws are world positions too.
    hiz_shift(off);
    for (HizShown* shown : {&hizShown, &hizPrev})
        for (OcclusionShown::Box& box : shown->boxes)
            for (Vec3& corner : box.corners) corner -= off;
    // The cameras of the last frame answer world_to_screen, entity.bounds() and picking until the next update(): they are the ones of the
    // world as it is now.
    if (!lastCams.empty()) {
        lastCams = collect_cameras(world);
        refresh_logic_cameras(world);
    }
}

}  // namespace fa
