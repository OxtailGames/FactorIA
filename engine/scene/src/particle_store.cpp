#include "fa/scene/particle_store.h"

#include <algorithm>
#include <exception>
#include <string_view>
#include <utility>

#include "fa/core/jobs.h"
#include "fa/core/log.h"
#include "fa/scene/mesh_surface.h"
#include "fa/scene/tilemap.h"
#include "fa/scene/world.h"

namespace fa {

namespace {

std::uint64_t hash_id(const std::string& id) {
    std::uint64_t h = 1469598103934665603ULL;
    for (unsigned char c : id) { h ^= c; h *= 1099511628211ULL; }
    return h;
}

// An entity the simulation moves: active in its hierarchy and not about to be destroyed.
bool entity_active(const World& w, Entity e) { return w.active_in_hierarchy(e) && !w.pending_destroy(e); }

// The Tilemap particles bounce on: the one `collisionTilemap` names, else the first active one with solid tiles.
const Tilemap* find_tilemap(World& world, const ParticleEmitter& em, Mat4& matrix) {
    if (!em.collisionTilemap.is_null() && world.alive(em.collisionTilemap)) {
        if (const Tilemap* tm = world.get<Tilemap>(em.collisionTilemap)) {
            matrix = world.world_matrix(em.collisionTilemap);
            return tm;
        }
    }
    const Tilemap* found = nullptr;
    world.each<Tilemap>([&](Entity t, Tilemap& tm) {
        if (found || !entity_active(world, t)) return;
        if (!tm.solidTiles.is_array() || tm.solidTiles.empty()) return;
        found = &tm;
        matrix = world.world_matrix(t);
    });
    return found;
}

ParticleEnv make_env(World& world, Entity e, const ParticleEmitter& em, ParticleEmitterState& st) {
    ParticleEnv env;
    env.emitter = world.world_matrix(e);
    env.is3D = em.is3D;
    env.screen = particle_screen_space(em);
    // The sim asks for the map of every group whose collision is "tilemap": the emitter's and its sub-emitters'.
    env.findTilemap = [&world](const ParticleEmitter& c, Mat4& matrix) { return find_tilemap(world, c, matrix); };
    if (em.shape == ParticleShape::Mesh && !em.shapeMesh.empty()) {
        // A procedural "mesh:N" is asked every time (the store answers from its cache and notices a mesh.update); the others once.
        const bool procedural = em.shapeMesh.rfind("mesh:", 0) == 0;
        if (st.meshName != em.shapeMesh || procedural || (!st.mesh && !st.meshWarned)) {
            auto r = load_mesh_surface(world.meshes(), em.shapeMesh);
            if (r) {
                st.mesh = *r;
                st.meshWarned = false;
            } else {
                st.mesh.reset();
                if (!st.meshWarned)
                    FA_WARN("particles", "{}: shapeMesh '{}' cannot be read, so particles are born at the point: {}", world.id_of(e),
                            em.shapeMesh, r.error().to_string());
                st.meshWarned = true;
            }
            st.meshName = em.shapeMesh;
        }
        env.mesh = st.mesh.get();
    }
    env.findEmitter = [&world](std::string_view id) -> const ParticleEmitter* {
        const Entity t = world.find_by_id(id);
        return t.is_null() ? nullptr : world.get<ParticleEmitter>(t);
    };
    return env;
}

void log_problems(World& world, Entity e, ParticleEmitterState& st) {
    for (const std::string& p : st.sim.take_problems()) FA_WARN("particles", "{}: ParticleEmitter: {}", world.id_of(e), p);
}

// The emitters are stepped as jobs once the scene holds kParallelParticles live particles: moving one costs ~50 ns, handing out a
// chunk a few microseconds. A chunk is a run of whole emitters of about kParticleChunk particles (each emitter's sim is its own:
// ParticleSim owns its particles and its Rng), counting kEmitterWeight for the emitter's own work (spawning, its trail). The chunk
// bounds depend only on the particle counts, never on the thread count or a clock.
constexpr std::size_t kParallelParticles = 2048;
constexpr std::size_t kParticleChunk = 1024;
constexpr std::size_t kEmitterWeight = 16;

struct StepItem {
    Entity e;
    ParticleEmitter* em = nullptr;
    ParticleEmitterState* st = nullptr;
    ParticleEnv env;
};

}  // namespace

bool particle_screen_space(const ParticleEmitter& em) { return em.space == RenderSpace::Screen && !em.is3D; }

ParticleEmitterState* ParticleStore::find(Entity e) {
    auto it = states_.find(e.bits());
    return it == states_.end() ? nullptr : &it->second;
}

const ParticleEmitterState* ParticleStore::find(Entity e) const {
    auto it = states_.find(e.bits());
    return it == states_.end() ? nullptr : &it->second;
}

ParticleEmitterState& ParticleStore::state_for(World& world, Entity e, const ParticleEmitter& em) {
    ParticleEmitterState& st = states_[e.bits()];
    if (!st.sim.seeded()) {
        std::uint64_t s = hash_id(world.id_of(e));
        // A non-zero `seed` gives another run of the same emitter; 0 keeps the run derived from the id alone.
        if (em.seed != 0) s ^= std::uint64_t(std::uint32_t(em.seed)) * 0x9E3779B97F4A7C15ULL;
        st.sim.seed(s);
    }
    return st;
}

void ParticleStore::queue_burst(World& world, Entity e, int count) {
    if (count <= 0 || e.is_null() || !world.alive(e) || !world.get<ParticleEmitter>(e)) return;
    // The emitter's own budgets cap what is born; this only keeps the queued count from overflowing an int.
    constexpr int kMaxQueuedBurst = 1'000'000;
    ParticleEmitterState& st = states_[e.bits()];
    const int room = kMaxQueuedBurst - st.sim.pending_burst();
    if (room > 0) st.sim.queue_burst(std::min(count, room));
}

void ParticleStore::flush(World& world) {
    bool any = false;
    for (auto& [k, s] : states_) any = any || s.sim.pending_burst() > 0;
    if (!any) return;
    world.each<ParticleEmitter>([&](Entity e, ParticleEmitter& em) {
        if (!entity_active(world, e)) return;
        auto it = states_.find(e.bits());
        if (it == states_.end() || it->second.sim.pending_burst() <= 0) return;
        ParticleEmitterState& st = state_for(world, e, em);
        const ParticleEnv env = make_env(world, e, em, st);
        st.sim.flush(em, env);
        log_problems(world, e, st);
    });
}

void ParticleStore::update(World& world, float dt) {
    for (auto& [k, s] : states_) s.seen = false;

    // On this thread: the states (the map only grows here, and its elements never move), the shape mesh each emitter is born on
    // (it may be loaded) and how many particles there are.
    std::vector<StepItem> steps;
    std::vector<std::size_t> weights;
    world.each<ParticleEmitter>([&](Entity e, ParticleEmitter& em) {
        if (!entity_active(world, e)) return;
        ParticleEmitterState& st = state_for(world, e, em);
        st.seen = true;
        steps.push_back({e, &em, &st, make_env(world, e, em, st)});
        weights.push_back(st.sim.particles.size() + kEmitterWeight);
    });
    // The steps only read the World (a Tilemap to bounce on, the emitter a sub-emitter names) and write their own sim.
    const auto ranges = jobs::weighted_ranges(weights, kParticleChunk, kParallelParticles);
    auto run_range = [&](std::size_t r) {
        for (std::size_t i = ranges[r].first; i < ranges[r].second; ++i) steps[i].st->sim.step(*steps[i].em, steps[i].env, dt);
    };
    if (ranges.size() <= 1) {
        if (!ranges.empty()) {
            try {  // as a chunk of a job would: the error is logged and the other emitters of the scene go on next step
                run_range(0);
            } catch (const std::exception& ex) {
                FA_ERROR("particles", "stepping the emitters failed: exception: {}", ex.what());
            } catch (...) {
                FA_ERROR("particles", "stepping the emitters failed: an exception that is not a std::exception");
            }
        }
    } else {
        auto result = jobs::parallel_for("scene.particles", ranges.size(), 1, [&](const jobs::Chunk& c) {
            for (std::size_t r = c.begin; r < c.end; ++r) run_range(r);
        });
        if (!result) FA_ERROR("particles", "stepping the emitters failed: {}", result.error().message);
    }
    // Back on this thread, in the order of the emitters: what the sims had to say, and the emitters that are done.
    for (StepItem& it : steps) {
        ParticleEmitterState& st = *it.st;
        log_problems(world, it.e, st);
        if (it.em->autoDestroy && !it.em->emitting && st.sim.everSpawned && st.sim.empty() && st.sim.emitterTrail.empty() &&
            st.sim.pending_burst() == 0 && !world.pending_destroy(it.e))
            world.destroy(it.e);
    }

    for (auto it = states_.begin(); it != states_.end();) {
        if (!it->second.seen) it = states_.erase(it);
        else ++it;
    }
}

std::size_t ParticleStore::particle_count() const {
    std::size_t n = 0;
    for (const auto& [k, s] : states_) n += s.sim.particles.size();
    return n;
}

}  // namespace fa
