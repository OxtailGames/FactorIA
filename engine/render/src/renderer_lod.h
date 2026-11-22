// The levels of detail the cameras picked this frame and the cross-fades running between them (M75.1). Render-only state: it is never
// saved and never read by a script or the simulation; a fade advances once per frame by the renderer's frame delta.
#pragma once

#include <cstddef>
#include <cstdint>
#include <unordered_map>

#include "fa/scene/lod.h"

namespace fa::render {

// What a camera drew of one entity (a MeshRenderer with lods, or a LodGroup) this frame.
struct LodPick {
    int level = 0;        // the level drawn (fading in, or settled)
    int from = -1;        // the level fading out, -1 = no fade
    float amount = 0.0f;  // lod_fade_amount: 0 when not fading
    bool fading() const { return from >= 0 && amount > 0.0f; }
};

// Whether the HLOD proxy mesh of a LodGroup (M75 P1d) is drawn this frame, given the pick of its group, and how: `fade` gets the item's lodFade
// (0 = settled, +a = the proxy fading in, -a = fading out). The proxy is shown when it is the group's level, or the level that is fading out
// (only where `canFade`: a draw with no dither program switches at once, like the children).
inline bool hlod_proxy_shown(const LodPick& group, bool canFade, float& fade) {
    fade = 0.0f;
    if (group.level == kHlodLevel) {
        if (group.fading() && canFade) fade = group.amount;
        return true;
    }
    if (group.fading() && group.from == kHlodLevel && canFade) {
        fade = -group.amount;
        return true;
    }
    return false;
}

enum class LodKind : std::uint32_t { Mesh = 0, Group = 1 };

class LodFades {
public:
    // One frame starts: the picks of the main camera of the last frame are forgotten. `world` and `sceneGeneration` name what is drawn
    // (World::scene_generation): another world, or another scene loaded into it, drops every fade (entity ids repeat from one scene to
    // the next, so a fade of the last scene would show on a stranger).
    void begin_frame(const void* world = nullptr, std::uint64_t sceneGeneration = 0);
    // One frame ends: the fades of entities nobody asked about this frame (destroyed, hidden, out of every camera's list) are dropped.
    void end_frame();
    // The pick of `entity` (Entity::bits) for the camera `camera` (any number that tells the camera's jobs apart): the level the metric
    // chose (`target`), cross-fading over `crossFade` seconds; the first time an entity is seen it starts settled at `target`.
    // Call once per entity per camera per frame. `farTarget` is the level the metric picks when pushed kLodHysteresis farther (fa/scene/lod.h): an
    // entity already on a farther level than `target` keeps it unless `farTarget` is nearer too (-1: no hysteresis). The level held is kept for
    // every entity asked about, also with crossFade 0 (a hard switch).
    LodPick step(std::uint64_t camera, std::uint64_t entity, LodKind kind, int target, float crossFade, float dt,
                 int farTarget = -1);
    // The picks the first main camera of the frame made: probe and GI captures, which have no camera of their own, draw the levels that
    // camera sees. `remember` stores one (the first writer of the frame wins), `main_pick` reads it.
    void remember(std::uint64_t entity, LodKind kind, const LodPick& p);
    const LodPick* main_pick(std::uint64_t entity, LodKind kind) const;
    bool main_set() const { return mainSet_; }
    void set_main() { mainSet_ = true; }
    std::size_t size() const { return slots_.size(); }  // fades kept (a test checks they are dropped)

private:
    struct Slot {
        LodFadeState s;
        std::uint64_t seen = 0;
    };
    std::unordered_map<std::uint64_t, Slot> slots_;
    std::unordered_map<std::uint64_t, LodPick> main_[2];
    std::uint64_t frame_ = 0;
    const void* world_ = nullptr;
    std::uint64_t sceneGeneration_ = 0;
    bool mainSet_ = false;
};

}  // namespace fa::render
