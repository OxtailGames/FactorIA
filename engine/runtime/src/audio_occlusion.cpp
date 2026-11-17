#include "fa/runtime/audio_occlusion.h"

#include <algorithm>
#include <vector>

namespace fa {

bool audio_occlusion_blocked(Physics& physics, World& world, const AudioOcclusionRay& ray) {
    const Vec3 d = ray.to - ray.from;
    const float dist = length(d);
    if (!(dist > 1e-4f)) return false;
    RaycastOptions options;
    options.mask = ray.mask;
    options.ignore = ray.source;
    options.ignoreTriggers = true;
    options.maxHits = 16;  // the nearest ones come first, and the listener's own colliders may take some of them
    const auto belongs_to_listener = [&](Entity e) {
        return !ray.listener.is_null() && (e == ray.listener || world.is_ancestor(ray.listener, e));
    };
    // A hit at the very end of the segment is the source's surroundings, not something in between.
    const auto short_of_end = [](float hitDistance, float length) {
        return hitDistance < length - std::max(length * 1e-3f, 1e-3f);
    };
    // Walks one segment of `total` long. cast(offset, rest) returns the hits of the part that starts `offset` along it
    // (their distances count from there). A full answer (maxHits) of which nothing blocks means the next hits were cut
    // off (a listener with many colliders in its hierarchy would hide a wall behind them): ask again from the last hit
    // on, up to kRounds times, so the work stays bounded.
    constexpr int kRounds = 8;
    const auto blocked_along = [&](float total, const auto& cast) {
        float offset = 0.0f;
        const float step = std::max(total * 1e-4f, 1e-3f);
        for (int round = 0; round < kRounds; ++round) {
            const std::vector<RaycastHit> hits = cast(offset, total - offset);
            float last = 0.0f;
            for (const RaycastHit& hit : hits) {
                if (!belongs_to_listener(hit.entity) && short_of_end(offset + hit.distance, total)) return true;
                last = std::max(last, hit.distance);
            }
            if (int(hits.size()) < options.maxHits) return false;
            offset += last + step;
            if (offset >= total) return false;
        }
        return false;
    };
    // 2D colliders: the segment in x and y (2D queries ignore z).
    const float dist2d = length(Vec2{d.x, d.y});
    if (dist2d > 1e-4f) {
        const Vec2 from2{ray.from.x, ray.from.y};
        const Vec2 dir2{d.x / dist2d, d.y / dist2d};
        if (blocked_along(dist2d, [&](float offset, float) {
                return physics.raycast2d_all(world, from2 + dir2 * offset, {ray.to.x, ray.to.y}, options);
            }))
            return true;
    }
    // 3D colliders.
    const Vec3 dir = d * (1.0f / dist);
    return blocked_along(dist, [&](float offset, float rest) {
        return physics.raycast3d_all(world, ray.from + dir * offset, dir, rest, options);
    });
}

}  // namespace fa
