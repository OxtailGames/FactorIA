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
    bool seen = false;
    Rng rng;
};

std::unordered_map<std::uint64_t, EmitterState>& states() {
    static std::unordered_map<std::uint64_t, EmitterState> s;
    return s;
}

std::uint64_t hash_id(const std::string& id) {
    std::uint64_t h = 1469598103934665603ULL;
    for (unsigned char c : id) { h ^= c; h *= 1099511628211ULL; }
    return h;
}

}  // namespace

void clear_particles() { states().clear(); }

void gather_particles(World& world, Frame& f) {
    auto& all = states();
    for (auto& [k, s] : all) s.seen = false;

    world.each<ParticleEmitter>([&](Entity e, ParticleEmitter& em) {
        if (!entity_active(world, e)) return;
        Mat4 m = world.world_matrix(e);
        auto it = all.find(e.bits());
        if (it == all.end()) {
            it = all.emplace(e.bits(), EmitterState{}).first;
            it->second.rng.reseed(hash_id(world.id_of(e)));
        }
        EmitterState& st = it->second;
        st.seen = true;
        Rng& rng = st.rng;

        auto spawn = [&]() {
            if (int(st.particles.size()) >= em.maxParticles) return;
            P p;
            p.life = std::max(0.01f, em.lifetime * (1.0f + rng.range(-em.lifetimeVariance, em.lifetimeVariance)));
            float speed = em.speed * (1.0f + rng.range(-em.speedVariance, em.speedVariance));
            Vec3 origin = em.worldSpace ? m.translation() : Vec3{0, 0, 0};
            if (!em.is3D) {
                float rotZ = em.worldSpace ? degrees(std::atan2(m.at(0, 1), m.at(0, 0))) : 0.0f;
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
        };

        bool starting = em.emitting && !st.wasEmitting;
        st.wasEmitting = em.emitting;
        if (starting) for (int i = 0; i < em.burst; ++i) spawn();
        if (em.emitting && f.dt > 0 && em.rate > 0) {
            st.acc += em.rate * f.dt;
            while (st.acc >= 1.0f) { st.acc -= 1.0f; spawn(); }
        }
        // integrate
        if (f.dt > 0) {
            for (auto& p : st.particles) {
                p.age += f.dt;
                p.vel += em.gravity * f.dt;
                p.pos += p.vel * f.dt;
            }
            st.particles.erase(std::remove_if(st.particles.begin(), st.particles.end(),
                                              [](const P& p) { return p.age >= p.life; }),
                               st.particles.end());
        }
        if (st.particles.empty()) return;

        // draw
        TextureAsset* tex = em.texture.empty() ? f.assets->white() : f.assets->texture(em.texture);
        Mat4 id = Mat4::identity();
        f.world.begin_item(em.layer, f.cam.perspective ? length(m.translation() - f.cam.position) : 0.0f, tex,
                           SamplerKind::Linear);
        QuadList& list = f.world;
        for (const auto& p : st.particles) {
            float t = p.age / p.life;
            float size = lerp(em.startSize, em.endSize, t);
            if (size <= 0.0f) continue;
            Color c = lerp(em.startColor, em.endColor, t);
            if (c.a <= 0.0f) continue;
            Vec3 pos = em.worldSpace ? p.pos : m.transform_point(p.pos);
            Vec3 r{1, 0, 0}, u{0, 1, 0};
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
        (void)id;
    });

    for (auto it = all.begin(); it != all.end();) {
        if (!it->second.seen) it = all.erase(it);
        else ++it;
    }
}

}  // namespace fa::render
