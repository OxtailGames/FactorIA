// The particles of one World, without a GPU: one ParticleSim per ParticleEmitter entity (particles.h), stepped by the runtime in
// the fixed simulation step (spawn, motion, lifetimes, sub-emitters, `autoDestroy`), whether or not the game has a renderer. The
// renderer only reads what the store holds and draws it (fa_render particles.cpp).
//
// The store belongs to its World (World::particles()): the editor's scene and its Play session are two worlds whose entities may
// have the same handle, and each has its own emitters. clear() runs with World::clear() and on every scene load.
//
// Deterministic: each emitter's Rng is seeded from its stable entity id (and ParticleEmitter.seed), nothing reads a clock, and the
// emitters are stepped in the order the world iterates them, so a run gives the same particles with 0, 1 or N job threads.
#pragma once

#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/particles.h"

namespace fa {

class World;

// What the store keeps for one emitter entity.
struct ParticleEmitterState {
    ParticleSim sim;
    bool seen = false;  // the last update() met the emitter (a state whose emitter is gone or inactive is dropped)
    // shape = mesh: the surface being sampled and the name it was loaded for.
    std::shared_ptr<const MeshSurface> mesh;
    std::string meshName;
    bool meshWarned = false;
    // Pixel mode: the palette of each group (ParticleEmitter.palette of the emitter, or of its sub-emitter), parsed from `src`.
    // Only the renderer reads it (own_palette); it lives here because the state is per emitter.
    struct GroupPalette {
        Json src;
        std::vector<Color> colors;
        bool valid = false;
    };
    std::vector<GroupPalette> palettes;
};

class ParticleStore {
public:
    // The state of the emitter on `e`; null when it has none yet (it is made by its first update, flush or burst).
    ParticleEmitterState* find(Entity e);
    const ParticleEmitterState* find(Entity e) const;
    std::size_t size() const { return states_.size(); }

    // Queues `count` particles for the emitter on `e`; spawned by the next update() or flush(), also when the emitter has emitting =
    // false. Not an emitter or count <= 0: nothing.
    void queue_burst(World& world, Entity e, int count);

    // One step of `dt` seconds of every active emitter of `world`: queued bursts, the start burst, continuous emission, motion,
    // collision, sub-emitters, deaths; then it destroys (World::destroy, deferred to the end of the frame) the emitters with
    // `autoDestroy` that stopped emitting and have no particle left, and forgets the state of emitters that are gone. dt = 0 only
    // spawns. Large scenes are stepped as jobs (`scene.particles`): the result is the same with any number of threads.
    void update(World& world, float dt);

    // Spawns the queued bursts without simulating, so an emitter a script just burst shows its particles in the next draw.
    void flush(World& world);

    // Forgets every emitter's particles and random sequence: the emitters of the scene that is loaded next start from nothing, so
    // the start burst and `seed` behave the same on every run. Queued bursts are dropped with it.
    void clear() { states_.clear(); }

    // Live particles over all emitters (what the stats of a draw count, for tests).
    std::size_t particle_count() const;

private:
    ParticleEmitterState& state_for(World& world, Entity e, const ParticleEmitter& em);

    std::unordered_map<std::uint64_t, ParticleEmitterState>
        states_;  // by Entity::bits(); elements never move while update() runs
};

// Whether the emitter `em` simulates in screen space: space "screen" and not 3D (is3D has no screen space, so it wins). The sim
// runs +Y up on the screen position and the renderer flips it onto the y-down screen when it draws.
bool particle_screen_space(const ParticleEmitter& em);

}  // namespace fa
