#include "rt_local_shadows.h"

#include <algorithm>
#include <cmath>
#include <vector>

namespace fa::render {

namespace {
constexpr float kRtLocalShorter =
    0.02f;  // the ray stops this fraction short of its target: a light inside a mesh's skin does not shadow itself

bool usable(float v) { return v == v && v > 0.0f; }
}  // namespace

RtLocalPick pick_rt_local_lights(RtLocalSlots& slots, std::span<const RtLocalCandidate> candidates) {
    RtLocalPick pick;
    pick.candidates = int(candidates.size());
    // The usable candidates, best first (ties by the light table index: the order never depends on anything but the scene).
    std::vector<RtLocalCandidate> ranked;
    ranked.reserve(candidates.size());
    for (const RtLocalCandidate& c : candidates)
        if (usable(c.importance)) ranked.push_back(c);
    std::sort(ranked.begin(), ranked.end(), [](const RtLocalCandidate& a, const RtLocalCandidate& b) {
        return a.importance != b.importance ? a.importance > b.importance : a.light < b.light;
    });
    const RtLocalSlots before = slots;
    std::array<float, kRtLocalMaxLights> held{};  // the importance of each holder this frame
    std::vector<bool> inSlot(ranked.size(), false);
    // 1. keep
    for (int s = 0; s < kRtLocalMaxLights; ++s) {
        if (!slots.used[std::size_t(s)]) continue;
        bool found = false;
        for (std::size_t r = 0; r < ranked.size(); ++r) {
            if (ranked[r].id != slots.id[std::size_t(s)] || inSlot[r]) continue;
            inSlot[r] = true;
            held[std::size_t(s)] = ranked[r].importance;
            pick.light[std::size_t(s)] = ranked[r].light;
            found = true;
            break;
        }
        if (!found) slots.used[std::size_t(s)] = false;
    }
    // 2 and 3. fill the free slots, then swap in the clearly better
    for (std::size_t r = 0; r < ranked.size(); ++r) {
        if (inSlot[r]) continue;
        int target = -1;
        for (int s = 0; s < kRtLocalMaxLights && target < 0; ++s)
            if (!slots.used[std::size_t(s)]) target = s;
        if (target < 0) {
            int weakest = 0;
            for (int s = 1; s < kRtLocalMaxLights; ++s)
                if (held[std::size_t(s)] < held[std::size_t(weakest)]) weakest = s;
            if (!(ranked[r].importance > kRtLocalSwapFactor * held[std::size_t(weakest)]))
                break;  // the rest are weaker
            target = weakest;
        }
        slots.used[std::size_t(target)] = true;
        slots.id[std::size_t(target)] = ranked[r].id;
        held[std::size_t(target)] = ranked[r].importance;
        pick.light[std::size_t(target)] = ranked[r].light;
        inSlot[r] = true;
    }
    for (int s = 0; s < kRtLocalMaxLights; ++s) {
        const bool now = slots.used[std::size_t(s)];
        if (now) {
            ++pick.traced;
            pick.count = s + 1;
        } else {
            pick.light[std::size_t(s)] = -1;
        }
        if (now != before.used[std::size_t(s)] || (now && slots.id[std::size_t(s)] != before.id[std::size_t(s)]))
            pick.changed = true;
    }
    return pick;
}

RtLocalLight make_rt_local_light(const LightData& l) {
    RtLocalLight out{};
    out.posReach[0] = l.pos.x;
    out.posReach[1] = l.pos.y;
    out.posReach[2] = l.pos.z;
    out.posReach[3] = std::max(l.pos.w + l.extent, 0.0f);
    const bool area = l.color.w > 2.5f;
    const bool spot = !area && l.color.w > 1.5f;
    const float softness = l.shadow.filter == 1
                               ? 0.0f
                               : std::clamp(std::isfinite(l.shadow.softness) ? l.shadow.softness : 0.0f, 0.0f, 10.0f);
    out.axisCos[3] = -2.0f;
    if (area) {
        const int shape = int(l.ext[2].w + 0.5f);  // 0 rectangle, 1 disc, 2 tube
        out.kind[0] = float(3 + std::clamp(shape, 0, 2));
        out.kind[2] = softness;
        out.axisCos[0] = l.dir.x;
        out.axisCos[1] = l.dir.y;
        out.axisCos[2] = l.dir.z;
        for (int c = 0; c < 3; ++c) {
            out.right[c] = l.ext[0][c] * l.ext[0].w;
            out.up[c] = l.ext[1][c] * l.ext[1].w;
        }
    } else {
        out.kind[0] = spot ? 2.0f : 1.0f;
        // The tangent of the cone of the light's angular size, the same the PCSS filter of the shadow map takes (renderer_draw.cpp, the record's softness).
        out.kind[1] = std::tan(0.05f * softness);
        if (spot) {
            out.axisCos[0] = l.dir.x;
            out.axisCos[1] = l.dir.y;
            out.axisCos[2] = l.dir.z;
            out.axisCos[3] = l.dir.w;
        }
    }
    return out;
}

RtLocalParams make_rt_local_params(std::span<const LightData> table, const RtLocalPick& pick) {
    RtLocalParams p{};
    p.header[0] = float(pick.count);
    p.header[1] = kRtLocalShorter;
    for (int s = 0; s < kRtLocalMaxLights; ++s) {
        const int i = pick.light[std::size_t(s)];
        if (i >= 0 && std::size_t(i) < table.size()) p.lights[s] = make_rt_local_light(table[std::size_t(i)]);
    }
    return p;
}

}  // namespace fa::render
