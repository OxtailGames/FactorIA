#include "fa/scene/state_hash.h"

#include <cstdio>
#include <cstring>

#include "fa/core/json.h"
#include "fa/core/reflect.h"
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

StateHash world_state_hash(const World& world, const StateHashOptions& options) {
    StateHash out;
    Fnv all;
    all.u64(world.frame());
    all.f64(world.time());
    all.u64(world.rng().state());
    for (Entity e : world.entities()) {
        Fnv h;
        h.u64(e.bits());
        h.str(world.id_of(e));
        const Entity parent = world.parent(e);
        h.str(parent ? world.id_of(parent) : std::string());
        for (const TypeInfo* t : world.components_of(e)) {
            const void* obj = world.get(e, *t);
            if (!obj) continue;
            h.str(t->name);
            for (const FieldInfo& f : t->fields) {
                if (!f.serialized && !options.includeRuntime) continue;
                h.str(f.name);
                hash_field(h, f, obj);
            }
            ++out.components;
        }
        all.u64(h.h);
        ++out.entities;
        if (options.perEntity) out.perEntity.push_back(EntityHash{e, world.id_of(e), h.h});
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
