// Floating origin, engine side (docs/BIG_WORLDS.md "Floating origin"): when and how a rebase runs. World::rebase, Physics::origin_shifted
// and Audio::origin_shifted do the shifting of what each owns; this file calls them in one step and tells the scripts.
#include "engine_impl.h"
#include "fa/scene/camera_query.h"
#include "fa/scene/floating_origin.h"

namespace fa {

bool Engine::Impl::origin_anchor_position(Vec3& out) {
    const std::string& anchor = project.floatingOrigin.anchor;
    if (anchor.rfind("entity:", 0) == 0) {
        const Entity e = world.find_by_id(std::string_view(anchor).substr(7));
        if (e.is_null() || !world.alive(e)) return false;
        out = world.world_position(e);
        return true;
    }
    const std::vector<Entity> cams = rendering_cameras(world);
    if (cams.empty()) return false;
    out = world.world_position(cams.front());
    return true;
}

void Engine::Impl::auto_rebase_origin() {
    const FloatingOriginSettings& fo = project.floatingOrigin;
    if (!fo.enabled) return;  // the whole cost of the feature when it is off: this branch
    if (!(fo.step >= 1.0) || !(fo.threshold > 0.0)) return;
    Vec3 anchor;
    if (!origin_anchor_position(anchor)) return;
    const Vec3 offset = auto_rebase_offset(anchor, fo.threshold, fo.step);
    if (offset.x == 0.0f && offset.y == 0.0f && offset.z == 0.0f) return;
    rebase_origin(offset);
}

void Engine::Impl::rebase_origin(Vec3 offset) {
    if (offset.x == 0.0f && offset.y == 0.0f && offset.z == 0.0f) return;
    world.rebase(offset);
    physics.origin_shifted(world, offset);
    audio.origin_shifted(offset);
    const DVec3 o = world.origin();
    Json data = Json::object({{"offset", Json::array({double(offset.x), double(offset.y), double(offset.z)})},
                              {"origin", Json::array({o.x, o.y, o.z})}});
    world.events().game.push_back(GameEvent{"app.originShifted", std::move(data), kNullEntity});
}

}  // namespace fa
