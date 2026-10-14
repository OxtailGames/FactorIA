// CPU particle simulation. Deterministic: each emitter owns an Rng seeded from
// its stable entity id, so gameplay randomness (world.rng()) is never consumed
// by rendering and headless/windowed runs produce identical particles.
#include <algorithm>
#include <cmath>
#include <unordered_map>

#include "frame.h"

namespace fa::render {

namespace {

struct P {
    Vec3 pos, vel;
    float age = 0, life = 1;
};

struct EmitterState {
    std::vector<P> particles;
    float acc = 0;
    bool wasEmitting = false;
    bool fresh = true;        // the emitter has not run its first update yet (initial burst pending)
    bool seeded = false;
    bool everSpawned = false; // at least one particle was ever born (guards autoDestroy)
    bool seen = false;
    int pendingBurst = 0;     // from Renderer::emit_burst, spawned by the next update/draw
    Rng rng;
};

std::unordered_map<std::uint64_t, EmitterState>& states() {
    // Intentionally leaked: Renderer::shutdown() may run during static destruction.
    static auto* s = new std::unordered_map<std::uint64_t, EmitterState>();
    return *s;
}

std::uint64_t hash_id(const std::string& id) {
    std::uint64_t h = 1469598103934665603ULL;
    for (unsigned char c : id) { h ^= c; h *= 1099511628211ULL; }
    return h;
}

EmitterState& state_for(World& world, Entity e) {
    EmitterState& st = states()[e.bits()];
    if (!st.seeded) {
        st.seeded = true;
        st.rng.reseed(hash_id(world.id_of(e)));
    }
    return st;
}

// A screen-space emitter is simulated exactly like a world one (+Y up: direction 90 = up, negative gravity falls) and
// only flipped onto the y-down screen when drawn. is3D has no screen space, so it wins.
bool screen_space(const ParticleEmitter& em) { return em.space == RenderSpace::Screen && !em.is3D; }

void spawn(EmitterState& st, const ParticleEmitter& em, const Mat4& m) {
    if (int(st.particles.size()) >= em.maxParticles) return;
    Rng& rng = st.rng;
    P p;
    p.life = std::max(0.01f, em.lifetime * (1.0f + rng.range(-em.lifetimeVariance, em.lifetimeVariance)));
    float speed = em.speed * (1.0f + rng.range(-em.speedVariance, em.speedVariance));
    Vec3 origin = em.worldSpace ? m.translation() : Vec3{0, 0, 0};
    const bool screen = screen_space(em);
    if (screen) origin.y = -origin.y;  // the screen position, seen +Y up (flipped back when drawn)
    if (!em.is3D) {
        float rotZ = em.worldSpace ? degrees(std::atan2(m.at(0, 1), m.at(0, 0))) : 0.0f;
        if (screen) rotZ = -rotZ;      // a rotation turns clockwise on the +Y down screen, as it does for sprites
        float ang = em.direction + rotZ + rng.range(-em.spread, em.spread);
        Vec2 d = from_angle_deg(ang);
        p.vel = {d.x * speed, d.y * speed, 0};
    } else {
        Vec2 d0 = from_angle_deg(em.direction);
        Vec3 axis{d0.x, d0.y, 0};
        if (em.worldSpace) axis = normalize(m.transform_dir(axis));
        Vec3 helper = std::fabs(axis.y) < 0.9f ? Vec3{0, 1, 0} : Vec3{1, 0, 0};
        Vec3 u = normalize(cross(axis, helper)), v = cross(axis, u);
        float cosT = lerp(1.0f, std::cos(radians(std::clamp(em.spread, 0.0f, 180.0f))), rng.next_float());
        float sinT = std::sqrt(std::max(0.0f, 1.0f - cosT * cosT));
        float phi = rng.range(0.0f, kTau);
        Vec3 dir = axis * cosT + (u * std::cos(phi) + v * std::sin(phi)) * sinT;
        p.vel = dir * speed;
    }
    p.pos = origin;
    st.particles.push_back(p);
    st.everSpawned = true;
}

}  // namespace

void clear_particles() { states().clear(); }

void queue_particle_burst(std::uint64_t entityBits, int count) {
    if (count <= 0) return;
    states()[entityBits].pendingBurst += count;
}

void flush_particle_bursts(World& world) {
    auto& all = states();
    bool any = false;
    for (auto& [k, s] : all) any = any || s.pendingBurst > 0;
    if (!any) return;
    world.each<ParticleEmitter>([&](Entity e, ParticleEmitter& em) {
        if (!entity_active(world, e)) return;
        auto it = all.find(e.bits());
        if (it == all.end() || it->second.pendingBurst <= 0) return;
        EmitterState& st = state_for(world, e);
        Mat4 m = world.world_matrix(e);
        for (int i = 0; i < st.pendingBurst; ++i) spawn(st, em, m);
        st.pendingBurst = 0;
    });
}

void update_particles(World& world, float dt) {
    auto& all = states();
    for (auto& [k, s] : all) s.seen = false;

    world.each<ParticleEmitter>([&](Entity e, ParticleEmitter& em) {
        if (!entity_active(world, e)) return;
        Mat4 m = world.world_matrix(e);
        EmitterState& st = state_for(world, e);
        st.seen = true;

        for (int i = 0; i < st.pendingBurst; ++i) spawn(st, em, m);
        st.pendingBurst = 0;

        // The configured burst fires once when the emitter first appears (even with emitting = false) and again
        // each time `emitting` goes from false to true.
        bool startBurst = st.fresh || (em.emitting && !st.wasEmitting);
        st.fresh = false;
        st.wasEmitting = em.emitting;
        if (startBurst) for (int i = 0; i < em.burst; ++i) spawn(st, em, m);
        if (em.emitting && dt > 0 && em.rate > 0) {
            st.acc += em.rate * dt;
            while (st.acc >= 1.0f) { st.acc -= 1.0f; spawn(st, em, m); }
        }
        if (dt > 0) {
            for (auto& p : st.particles) {
                p.age += dt;
                p.vel += em.gravity * dt;
                p.pos += p.vel * dt;
            }
            st.particles.erase(std::remove_if(st.particles.begin(), st.particles.end(),
                                              [](const P& p) { return p.age >= p.life; }),
                               st.particles.end());
        }
        if (em.autoDestroy && !em.emitting && st.everSpawned && st.particles.empty() && st.pendingBurst == 0 &&
            !world.pending_destroy(e))
            world.destroy(e);
    });

    for (auto it = all.begin(); it != all.end();) {
        if (!it->second.seen) it = all.erase(it);
        else ++it;
    }
}

void gather_particles(World& world, Frame& f) {
    auto& all = states();
    world.each<ParticleEmitter>([&](Entity e, ParticleEmitter& em) {
        if (!entity_active(world, e)) return;
        auto it = all.find(e.bits());
        if (it == all.end()) return;
        EmitterState& st = it->second;
        if (st.particles.empty()) return;
        Mat4 m = world.world_matrix(e);
        const bool screen = screen_space(em);
        const Vec3 anchor = screen ? Vec3{em.anchor.x * float(f.targetW), em.anchor.y * float(f.targetH), 0.0f} : Vec3{};

        TextureAsset* tex = em.texture.empty() ? f.assets->white() : f.assets->texture(em.texture);
        QuadList& list = screen ? f.screen : f.world;
        list.begin_item(em.layer, f.cam.perspective && !screen ? length(m.translation() - f.cam.position) : 0.0f, tex,
                        SamplerKind::Linear, em.blend);
        for (const auto& p : st.particles) {
            float t = p.age / p.life;
            float size = lerp(em.startSize, em.endSize, t);
            if (size <= 0.0f) continue;
            Color c = lerp(em.startColor, em.endColor, t);
            if (c.a <= 0.0f) continue;
            Vec3 q = p.pos;
            if (screen) q.y = -q.y;  // flip the +Y up simulation onto the y-down screen
            Vec3 pos = (em.worldSpace ? q : m.transform_point(q)) + anchor;
            Vec3 r{1, 0, 0}, u{0, screen ? -1.0f : 1.0f, 0};
            if (em.is3D) { r = f.cam.right; u = f.cam.up; }
            float h = size * 0.5f;
            std::uint32_t col = pack_color(c);
            float mode = em.texture.empty() ? float(kModeSoft) : float(kModeTextured);
            float u0 = em.texture.empty() ? -1.0f : 0.0f, u1 = 1.0f, v0 = em.texture.empty() ? -1.0f : 0.0f, v1 = 1.0f;
            auto v = [&](float sx, float sy, float uu, float vv) {
                Vec3 q = pos + r * (sx * h) + u * (sy * h);
                return Vertex2D{q.x, q.y, q.z, uu, vv, col, mode, 0};
            };
            list.quad(v(-1, 1, u0, v0), v(-1, -1, u0, v1), v(1, -1, u1, v1), v(1, 1, u1, v0));
        }
        list.end_item();
        f.stats->particles += int(st.particles.size());
    });
}

}  // namespace fa::render
