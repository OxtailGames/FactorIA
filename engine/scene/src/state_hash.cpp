#include "fa/scene/state_hash.h"

#include <algorithm>
#include <cstdio>
#include <cstring>

#include "fa/core/json.h"
#include "fa/core/reflect.h"
#include "fa/scene/particle_store.h"
#include "fa/scene/world.h"

namespace fa {

namespace {

struct Fnv {
    std::uint64_t h = 0xcbf29ce484222325ULL;
    void bytes(const void* data, std::size_t n) {
        const auto* p = static_cast<const unsigned char*>(data);
        for (std::size_t i = 0; i < n; ++i) {
            h ^= p[i];
            h *= 0x100000001b3ULL;
        }
    }
    void u8(std::uint8_t v) { bytes(&v, 1); }
    void u32(std::uint32_t v) {
        unsigned char b[4] = {static_cast<unsigned char>(v), static_cast<unsigned char>(v >> 8),
                              static_cast<unsigned char>(v >> 16), static_cast<unsigned char>(v >> 24)};
        bytes(b, 4);
    }
    void u64(std::uint64_t v) {
        u32(std::uint32_t(v));
        u32(std::uint32_t(v >> 32));
    }
    void f32(float v) {
        std::uint32_t u = 0;
        std::memcpy(&u, &v, sizeof u);
        u32(u);
    }
    void f64(double v) {
        std::uint64_t u = 0;
        std::memcpy(&u, &v, sizeof u);
        u64(u);
    }
    void str(const std::string& s) {
        u64(std::uint64_t(s.size()));
        bytes(s.data(), s.size());
    }
};

template <class T>
const T& field_as(const FieldInfo& f, const void* object) {
    return *static_cast<const T*>(f.ptr(object));
}

void hash_field(Fnv& h, const FieldInfo& f, const void* o) {
    h.u8(std::uint8_t(f.kind));
    switch (f.kind) {
        case FieldKind::Bool: h.u8(field_as<bool>(f, o) ? 1 : 0); break;
        case FieldKind::Int:
        case FieldKind::Enum: h.u32(std::uint32_t(field_as<std::int32_t>(f, o))); break;
        case FieldKind::Float: h.f32(field_as<float>(f, o)); break;
        case FieldKind::String:
        case FieldKind::Asset: h.str(field_as<std::string>(f, o)); break;
        case FieldKind::Vec2: {
            const Vec2& v = field_as<Vec2>(f, o);
            h.f32(v.x);
            h.f32(v.y);
            break;
        }
        case FieldKind::Vec3: {
            const Vec3& v = field_as<Vec3>(f, o);
            h.f32(v.x);
            h.f32(v.y);
            h.f32(v.z);
            break;
        }
        case FieldKind::Vec4: {
            const Vec4& v = field_as<Vec4>(f, o);
            h.f32(v.x);
            h.f32(v.y);
            h.f32(v.z);
            h.f32(v.w);
            break;
        }
        case FieldKind::Color: {
            const Color& c = field_as<Color>(f, o);
            h.f32(c.r);
            h.f32(c.g);
            h.f32(c.b);
            h.f32(c.a);
            break;
        }
        case FieldKind::Rect: {
            const Rect& r = field_as<Rect>(f, o);
            h.f32(r.x);
            h.f32(r.y);
            h.f32(r.w);
            h.f32(r.h);
            break;
        }
        case FieldKind::Entity: h.u64(field_as<Entity>(f, o).bits()); break;
        case FieldKind::Json: h.str(field_as<Json>(f, o).dump()); break;
    }
}

}  // namespace

std::uint64_t entity_state_hash(Entity entity, const std::string& id, const std::string& parentId,
                                std::vector<ComponentRef> components, const StateHashOptions& options) {
    // Sorted by type name: registration order depends on which code registered its components first (a module, a
    // script, a test), and the hash must not.
    std::sort(components.begin(), components.end(), [](const ComponentRef& a, const ComponentRef& b) {
        if (!a.type || !b.type) return a.type == nullptr && b.type != nullptr;
        return a.type->name < b.type->name;
    });
    Fnv h;
    h.u64(entity.bits());
    h.str(id);
    h.str(parentId);
    for (const ComponentRef& c : components) {
        if (!c.type || !c.object) continue;
        h.str(c.type->name);
        for (const FieldInfo& f : c.type->fields) {
            if (!f.serialized && !options.includeRuntime) continue;
            h.str(f.name);
            hash_field(h, f, c.object);
        }
    }
    return h.h;
}

StateHash world_state_hash(const World& world, const StateHashOptions& options) {
    StateHash out;
    Fnv all;
    const bool filtered = !options.onlyComponents.empty();
    if (!filtered) {
        all.u64(world.frame());
        all.f64(world.time());
        all.u64(world.rng().state());
    }
    std::vector<ComponentRef> components;
    for (Entity e : world.entities()) {
        components.clear();
        for (const TypeInfo* t : world.components_of(e)) {
            if (filtered && std::find(options.onlyComponents.begin(), options.onlyComponents.end(), t->name) == options.onlyComponents.end())
                continue;
            if (const void* obj = world.get(e, *t)) components.push_back(ComponentRef{t, obj});
        }
        out.components += int(components.size());
        const Entity parent = world.parent(e);
        const std::uint64_t h =
            entity_state_hash(e, world.id_of(e), parent ? world.id_of(parent) : std::string(), components, options);
        all.u64(h);
        ++out.entities;
        if (options.perEntity) out.perEntity.push_back(EntityHash{e, world.id_of(e), h});
    }
    if (!filtered) {
        // The particles are simulation state too (they live in the world's ParticleStore, not in a component): each emitter's live
        // particles, in birth order, and what the next step depends on (the clock, the random sequence, the emission accumulator). trailSlot is left out: it names a slot of a pool, not a value.
        const ParticleStore& store = world.particles();
        for (Entity e : world.entities()) {
            const ParticleEmitterState* st = store.find(e);
            if (!st) continue;
            const ParticleSim& sim = st->sim;
            all.u64(e.bits());
            all.u64(std::uint64_t(sim.particles.size()));
            all.u8(sim.everSpawned ? 1 : 0);
            all.u32(std::uint32_t(sim.pending_burst()));
            all.f64(sim.clock());
            all.u64(sim.rng_state());         // the next particle's random draws depend on it
            all.f32(sim.emission_accumulator());  // ...and when the next one is born
            for (const Particle& p : sim.particles) {
                all.f32(p.pos.x); all.f32(p.pos.y); all.f32(p.pos.z);
                all.f32(p.vel.x); all.f32(p.vel.y); all.f32(p.vel.z);
                all.f32(p.age); all.f32(p.life); all.f32(p.rotation); all.f32(p.spin); all.f32(p.sizeScale); all.f32(p.random);
                all.u8(p.group);
            }
        }
    }
    out.hash = all.h;
    return out;
}

std::string state_hash_hex(std::uint64_t hash) {
    char buf[17];
    std::snprintf(buf, sizeof buf, "%016llx", static_cast<unsigned long long>(hash));
    return buf;
}

}  // namespace fa
