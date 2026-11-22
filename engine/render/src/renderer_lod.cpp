#include "renderer_lod.h"

#include <algorithm>

namespace fa::render {

namespace {
std::uint64_t slot_key(std::uint64_t camera, std::uint64_t entity, LodKind kind) {
    // splitmix64 over the three numbers: a collision would only give one entity the fade of another for a moment.
    auto mix = [](std::uint64_t x) {
        x += 0x9E3779B97F4A7C15ull;
        x = (x ^ (x >> 30)) * 0xBF58476D1CE4E5B9ull;
        x = (x ^ (x >> 27)) * 0x94D049BB133111EBull;
        return x ^ (x >> 31);
    };
    return mix(mix(camera) ^ mix(entity * 2 + std::uint64_t(kind)));
}
}  // namespace

void LodFades::begin_frame(const void* world, std::uint64_t sceneGeneration) {
    ++frame_;
    if (world != world_ || sceneGeneration != sceneGeneration_) {
        slots_.clear();
        world_ = world;
        sceneGeneration_ = sceneGeneration;
    }
    main_[0].clear();
    main_[1].clear();
    mainSet_ = false;
}

void LodFades::end_frame() {
    for (auto it = slots_.begin(); it != slots_.end();) {
        if (it->second.seen != frame_)
            it = slots_.erase(it);
        else
            ++it;
    }
}

LodPick LodFades::step(std::uint64_t camera, std::uint64_t entity, LodKind kind, int target, float crossFade, float dt,
                       int farTarget) {
    auto [it, fresh] = slots_.try_emplace(slot_key(camera, entity, kind));
    Slot& slot = it->second;
    if (fresh) slot.s = LodFadeState{target, -1, 1.0f};
    slot.seen = frame_;
    // The hysteresis: a farther level that is held stays until the metric pushed farther picks a nearer one too.
    if (farTarget >= 0 && !fresh) target = std::max(target, std::min(slot.s.level, farTarget));
    lod_fade_step(slot.s, target, crossFade, dt);  // a crossFade of 0 or less switches at once
    LodPick p;
    p.level = slot.s.level;
    p.from = slot.s.fading() ? slot.s.from : -1;
    p.amount = lod_fade_amount(slot.s);
    return p;
}

void LodFades::remember(std::uint64_t entity, LodKind kind, const LodPick& p) {
    main_[int(kind)].try_emplace(entity, p);
}

const LodPick* LodFades::main_pick(std::uint64_t entity, LodKind kind) const {
    const auto& m = main_[int(kind)];
    auto it = m.find(entity);
    return it == m.end() ? nullptr : &it->second;
}

}  // namespace fa::render
