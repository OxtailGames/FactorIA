#include "fa/runtime/audio_occlusion.h"

#include <algorithm>

namespace fa {

bool audio_occlusion_blocked(Physics& physics, World& world, const AudioOcclusionRay& ray) {
    const Vec3 d = ray.to - ray.from;
    const float dist = length(d);
    if (!(dist > 1e-4f)) return false;
    RaycastOptions options;
    options.mask = ray.mask;
    options.ignore = ray.source;
    options.ignoreTriggers = true;
    options.maxHits = 8;  // the listener's own colliders may take some of them
    const auto belongs_to_listener = [&](Entity e) {
        return !ray.listener.is_null() && (e == ray.listener || world.is_ancestor(ray.listener, e));
    };
    // A hit at the very end of the segment is the source's surroundings, not something in between.
    const auto short_of_end = [](float hitDistance, float length) {
        return hitDistance < length - std::max(length * 1e-3f, 1e-3f);
    };
    // 2D colliders: the segment in x and y (2D queries ignore z).
    const float dist2d = length(Vec2{d.x, d.y});
    if (dist2d > 1e-4f)
        for (const RaycastHit& hit :
             physics.raycast2d_all(world, {ray.from.x, ray.from.y}, {ray.to.x, ray.to.y}, options))
            if (!belongs_to_listener(hit.entity) && short_of_end(hit.distance, dist2d)) return true;
    // 3D colliders.
    for (const RaycastHit& hit : physics.raycast3d_all(world, ray.from, d * (1.0f / dist), dist, options))
        if (!belongs_to_listener(hit.entity) && short_of_end(hit.distance, dist)) return true;
    return false;
}

}  // namespace fa
