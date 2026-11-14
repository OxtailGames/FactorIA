#include "fa/scene/world.h"

#include <algorithm>
#include <atomic>
#include <cmath>
#include <format>
#include <mutex>
#include <thread>
#include <unordered_map>

#include "component_pool.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/scene/particle_store.h"

namespace fa {

namespace {

// Euler angles (pitch, yaw, roll degrees) of a rotation matrix built as Ry * Rx * Rz.
Vec3 euler_from_rotation(const Mat4& m) {
    auto r = [&](int row, int col) { return m.at(col, row); };
    float sinPitch = clamp(-r(1, 2), -1.0f, 1.0f);
    float pitch = det::asin(sinPitch), yaw, roll;
    if (std::fabs(sinPitch) < 0.9999f) {
        yaw = det::atan2(r(0, 2), r(2, 2));
        roll = det::atan2(r(1, 0), r(1, 1));
    } else {  // gimbal lock: fold roll into yaw
        yaw = det::atan2(-r(2, 0), r(0, 0));
        roll = 0.0f;
    }
    return {degrees(pitch), degrees(yaw), degrees(roll)};
}

// Splits a TRS matrix into position / euler degrees / scale. Exact for TRS matrices;
// shear (from non-uniform parent scale combined with rotation) is dropped.
void decompose(const Mat4& m, Vec3& position, Vec3& euler, Vec3& scale) {
    position = m.translation();
    Vec3 cx{m.at(0, 0), m.at(0, 1), m.at(0, 2)};
    Vec3 cy{m.at(1, 0), m.at(1, 1), m.at(1, 2)};
    Vec3 cz{m.at(2, 0), m.at(2, 1), m.at(2, 2)};
    scale = {length(cx), length(cy), length(cz)};
    // A negative determinant means a mirror: attribute it to the x scale.
    if (dot(cross(cx, cy), cz) < 0) scale.x = -scale.x;
    Mat4 rot;
    auto put = [&](int col, Vec3 v, float s) {
        if (std::fabs(s) < kEpsilon) return;
        rot.at(col, 0) = v.x / s;
        rot.at(col, 1) = v.y / s;
        rot.at(col, 2) = v.z / s;
    };
    put(0, cx, scale.x);
    put(1, cy, scale.y);
    put(2, cz, scale.z);
    euler = euler_from_rotation(rot);
}

}  // namespace

struct World::Impl {
    struct Slot {
        std::uint32_t generation = 0;
        bool alive = false;
        bool pending = false;
        bool pendingTree = false;  // pending, or an ancestor is: what pending_destroy() answers (set by destroy())
        Entity parent;
        std::vector<Entity> children;
    };

    // The hierarchy cache (docs/ARCHITECTURE.md, "The hierarchy cache"): per entity index, the world matrix and the
    // "active in hierarchy" answer, each with a valid bit. Invariant: a valid entry has valid ancestors, so an
    // invalidation stops at the first entry that is already invalid. Writers (a mutable access to Transform or
    // EntityInfo, set_parent, set_active, create) run on one thread at a time and never while jobs read the world;
    // readers may be on several threads: a valid entry is read without a lock (acquire), a missing one is filled under
    // `hlock` and published with a release store.
    static constexpr std::uint8_t kWorldValid = 1;
    static constexpr std::uint8_t kActiveValid = 2;
    static constexpr std::uint8_t kActiveValue = 4;
    struct HState {
        std::atomic<std::uint8_t> v{0};
        HState() = default;
        HState(const HState& o) : v(o.v.load(std::memory_order_relaxed)) {}
    };
    struct SpinLock {
        std::atomic_flag flag;
        void lock() {
            while (flag.test_and_set(std::memory_order_acquire)) std::this_thread::yield();
        }
        void unlock() { flag.clear(std::memory_order_release); }
    };
    mutable std::vector<HState> hstate;  // same size as `slots`
    mutable std::vector<Mat4> hworld;    // same size as `slots`
    mutable SpinLock hlock;
    mutable std::vector<Entity> hchain;  // scratch of the fill, under hlock
    std::atomic<std::uint64_t> hversion{0};

    std::vector<Slot> slots;
    std::vector<std::uint32_t> freeIndices;
    std::size_t aliveCount = 0;
    std::vector<std::unique_ptr<ComponentPool>> pools;  // indexed by TypeId
    ComponentPool* infoPool = nullptr;
    ComponentPool* transformPool = nullptr;
    std::unordered_map<std::string, Entity> ids;
    std::uint64_t autoId = 1;
    std::vector<Entity> pending;
    std::vector<std::pair<int, EntityCallback>> observers;
    int nextObserver = 1;
    bool flushing = false;

    ComponentPool& pool(const TypeInfo& t) {
        if (pools.size() <= t.id) pools.resize(std::size_t(t.id) + 1);
        if (!pools[t.id]) pools[t.id] = std::make_unique<ComponentPool>(t);
        return *pools[t.id];
    }
    const ComponentPool* find_pool(const TypeInfo& t) const {
        return t.id < pools.size() ? pools[t.id].get() : nullptr;
    }
    bool alive(Entity e) const {
        return e.index < slots.size() && slots[e.index].alive && slots[e.index].generation == e.generation;
    }
    EntityInfo& info(Entity e) const { return *static_cast<EntityInfo*>(infoPool->get(e)); }
    // Removes the id from the lookup table, but only if it still maps to `e` (a destroyed entity's id may already
    // belong to a newer entity).
    void unregister_id(Entity e) {
        auto it = ids.find(info(e).id);
        if (it != ids.end() && it->second == e) ids.erase(it);
    }
    bool pending_destroy(Entity e) const { return alive(e) && slots[e.index].pendingTree; }

    // Clears `bit` of the entry of `idx` and of every descendant whose entry has it (the others have it clear already).
    void invalidate(std::uint32_t idx, std::uint8_t bit) {
        if (idx >= hstate.size()) return;
        const std::uint8_t clearMask = bit == kActiveValid ? std::uint8_t(kActiveValid | kActiveValue) : bit;
        if (!(hstate[idx].v.load(std::memory_order_relaxed) & bit))
            return;  // dropped already, and so is what hangs below it
        if (!(hstate[idx].v.fetch_and(std::uint8_t(~clearMask), std::memory_order_relaxed) & bit)) return;
        hversion.fetch_add(1, std::memory_order_relaxed);
        thread_local std::vector<std::uint32_t> stack;  // scratch: no allocation per call
        stack.clear();
        auto visit_children = [&](std::uint32_t i) {
            for (Entity c : slots[i].children)
                if (hstate[c.index].v.load(std::memory_order_relaxed) & bit) stack.push_back(c.index);
        };
        visit_children(idx);
        while (!stack.empty()) {
            std::uint32_t i = stack.back();
            stack.pop_back();
            hstate[i].v.fetch_and(std::uint8_t(~clearMask), std::memory_order_relaxed);
            visit_children(i);
        }
    }
    void dirty_world(Entity e) { invalidate(e.index, kWorldValid); }
    void dirty_active(Entity e) { invalidate(e.index, kActiveValid); }

    Mat4 local_matrix(Entity e) const {
        const auto* t = static_cast<const Transform*>(transformPool->get(e));
        return Mat4::trs(t->position, t->rotation, t->scale);
    }

    // parent's world matrix * local TRS, down from the root (the one definition of world_matrix).
    Mat4 world_cached(Entity e) const {
        if (hstate[e.index].v.load(std::memory_order_acquire) & kWorldValid) return hworld[e.index];
        std::lock_guard<SpinLock> lock(hlock);
        hchain.clear();
        Entity cur = e;
        for (; !cur.is_null(); cur = slots[cur.index].parent) {
            if (hstate[cur.index].v.load(std::memory_order_acquire) & kWorldValid) break;
            hchain.push_back(cur);
        }
        const Mat4* base = cur.is_null() ? nullptr : &hworld[cur.index];
        for (auto it = hchain.rbegin(); it != hchain.rend(); ++it) {
            Mat4 local = local_matrix(*it);
            hworld[it->index] = base ? *base * local : local;
            hstate[it->index].v.fetch_or(kWorldValid, std::memory_order_release);
            base = &hworld[it->index];
        }
        return hworld[e.index];
    }

    bool active_cached(Entity e) const {
        std::uint8_t s = hstate[e.index].v.load(std::memory_order_acquire);
        if (s & kActiveValid) return (s & kActiveValue) != 0;
        std::lock_guard<SpinLock> lock(hlock);
        hchain.clear();
        Entity cur = e;
        for (; !cur.is_null(); cur = slots[cur.index].parent) {
            if (hstate[cur.index].v.load(std::memory_order_acquire) & kActiveValid) break;
            hchain.push_back(cur);
        }
        bool value = cur.is_null() ? true : (hstate[cur.index].v.load(std::memory_order_acquire) & kActiveValue) != 0;
        for (auto it = hchain.rbegin(); it != hchain.rend(); ++it) {
            value = value && info(*it).active;
            hstate[it->index].v.fetch_or(std::uint8_t(kActiveValid | (value ? kActiveValue : 0)),
                                         std::memory_order_release);
        }
        return value;
    }
};

World::World() : impl_(std::make_unique<Impl>()), particles_(std::make_unique<ParticleStore>()) {
    ensure_builtin_components();
    impl_->infoPool = &impl_->pool(type_of<EntityInfo>());
    impl_->transformPool = &impl_->pool(type_of<Transform>());
}

World::~World() {
    impl_->observers.clear();  // don't call observers while the world is torn down
    for (auto& p : impl_->pools)
        if (p) p->clear();
}

// ------------------------------------------------------------- entities --
Entity World::create(std::string_view name, std::string_view id) {
    Impl& d = *impl_;
    Entity e;
    if (!d.freeIndices.empty()) {
        e.index = d.freeIndices.back();
        d.freeIndices.pop_back();
        e.generation = d.slots[e.index].generation;
    } else {
        e.index = std::uint32_t(d.slots.size());
        e.generation = 0;
        d.slots.emplace_back();
        d.hstate.emplace_back();
        d.hworld.emplace_back();
    }
    d.hstate[e.index].v.store(0, std::memory_order_relaxed);  // a reused index starts with nothing cached
    Impl::Slot& slot = d.slots[e.index];
    slot.alive = true;
    slot.pending = false;
    slot.pendingTree = false;
    slot.parent = kNullEntity;
    slot.children.clear();
    ++d.aliveCount;

    std::string finalId;
    if (id.empty()) {
        do {
            finalId = "e" + std::to_string(d.autoId++);
        } while (d.ids.count(finalId));
    } else {
        finalId = std::string(id);
        for (int n = 2; d.ids.count(finalId); ++n) finalId = std::string(id) + "_" + std::to_string(n);
    }
    d.ids[finalId] = e;

    auto* inf = static_cast<EntityInfo*>(d.infoPool->add(e));
    inf->id = std::move(finalId);
    inf->name = std::string(name);
    d.transformPool->add(e);
    return e;
}

bool World::alive(Entity e) const { return impl_->alive(e); }

bool World::pending_destroy(Entity e) const { return impl_->pending_destroy(e); }

std::size_t World::entity_count() const { return impl_->aliveCount; }

std::vector<Entity> World::entities() const { return impl_->infoPool->entities(); }

void World::destroy(Entity e) {
    if (!alive(e)) return;
    Impl::Slot& s = impl_->slots[e.index];
    if (s.pending) return;
    s.pending = true;
    impl_->pending.push_back(e);
    // The entity (and its children) stop being findable right away and their ids become reusable; the memory and
    // components live until flush() so systems can keep iterating.
    std::vector<Entity> subtree{e};
    for (std::size_t i = 0; i < subtree.size(); ++i)
        for (Entity c : impl_->slots[subtree[i].index].children) subtree.push_back(c);
    for (Entity x : subtree) {
        impl_->unregister_id(x);
        // No child enters a pending subtree (check_set_parent refuses it), so the flag stays true until the flush.
        impl_->slots[x.index].pendingTree = true;
    }
}

void World::destroy_immediate(Entity e) {
    Impl& d = *impl_;
    if (!alive(e)) return;

    // Collect the subtree (parents before children).
    std::vector<Entity> subtree{e};
    for (std::size_t i = 0; i < subtree.size(); ++i)
        for (Entity c : d.slots[subtree[i].index].children) subtree.push_back(c);

    // Observers run while everything is still intact.
    std::vector<EntityCallback> observers;
    for (auto& [id, cb] : d.observers) observers.push_back(cb);
    for (Entity x : subtree)
        for (auto& cb : observers)
            if (cb) cb(x);

    // Detach the root of the subtree from its parent.
    Entity parent = d.slots[e.index].parent;
    if (!parent.is_null() && d.alive(parent)) {
        auto& siblings = d.slots[parent.index].children;
        siblings.erase(std::remove(siblings.begin(), siblings.end(), e), siblings.end());
    }

    // Erase children first so a half-destroyed hierarchy is never observable.
    for (auto it = subtree.rbegin(); it != subtree.rend(); ++it) {
        Entity x = *it;
        Impl::Slot& s = d.slots[x.index];
        d.unregister_id(x);
        for (auto& p : d.pools)
            if (p) p->remove(x);
        s.alive = false;
        s.pending = false;
        s.pendingTree = false;
        s.parent = kNullEntity;
        s.children.clear();
        ++s.generation;
        d.freeIndices.push_back(x.index);
        --d.aliveCount;
    }
}

void World::flush() {
    Impl& d = *impl_;
    if (d.flushing) return;
    d.flushing = true;
    // Observers may queue more destroys; keep going until the queue is empty.
    while (!d.pending.empty()) {
        std::vector<Entity> batch = std::move(d.pending);
        d.pending.clear();
        for (Entity e : batch) destroy_immediate(e);
    }
    d.flushing = false;
}

void World::clear() {
    Impl& d = *impl_;
    for (Entity e : roots()) destroy_immediate(e);
    d.pending.clear();
    d.ids.clear();
    d.autoId = 1;
    settings_ = SceneSettings{};
    events_.clear();
    scenePath_.clear();
    tooltip_ = UiTooltipView{};
    meshes_.clear();
    feel_.clear_scene();
    vfxLive_ = 0;
    particles_->clear();
    warnedSpriteClips_.clear();
}

bool World::active_in_hierarchy(Entity e) const { return alive(e) && impl_->active_cached(e); }

void World::set_active(Entity e, bool active) {
    if (!alive(e)) return;
    impl_->info(e).active = active;
    impl_->dirty_active(e);
}

// ------------------------------------------------------ identity/lookup --
EntityInfo& World::info(Entity e) {
    FA_ASSERT(alive(e), "World::info on a dead or null entity");
    impl_->dirty_active(e);  // a mutable reference may write `active`
    return impl_->info(e);
}
const EntityInfo& World::info(Entity e) const {
    FA_ASSERT(alive(e), "World::info on a dead or null entity");
    return impl_->info(e);
}

const std::string& World::id_of(Entity e) const { return info(e).id; }

Entity World::find_by_id(std::string_view id) const {
    auto it = impl_->ids.find(std::string(id));
    if (it == impl_->ids.end() || impl_->pending_destroy(it->second)) return kNullEntity;
    return it->second;
}

Entity World::find(std::string_view idOrName) const {
    if (Entity e = find_by_id(idOrName); !e.is_null()) return e;
    for (Entity e : impl_->infoPool->entities())
        if (impl_->info(e).name == idOrName && !impl_->pending_destroy(e)) return e;
    return kNullEntity;
}

std::vector<Entity> World::find_all_by_name(std::string_view name) const {
    std::vector<Entity> out;
    for (Entity e : impl_->infoPool->entities())
        if (impl_->info(e).name == name && !impl_->pending_destroy(e)) out.push_back(e);
    return out;
}

std::vector<Entity> World::find_by_tag(std::string_view tag) const {
    std::vector<Entity> out;
    for (Entity e : impl_->infoPool->entities())
        if (has_tag(e, tag) && !impl_->pending_destroy(e)) out.push_back(e);
    return out;
}

bool World::has_tag(Entity e, std::string_view tag) const {
    if (!alive(e)) return false;
    const auto& tags = impl_->info(e).tags;
    return std::find(tags.begin(), tags.end(), tag) != tags.end();
}

Result<void> World::set_id(Entity e, std::string_view newId) {
    if (!alive(e)) return make_error("Cannot rename the id of a dead entity", "Check world.alive(entity) first.");
    if (newId.empty())
        return make_error("Entity id must not be empty",
                          "Use a short unique string such as \"player\" or \"enemy_1\".");
    EntityInfo& inf = impl_->info(e);
    if (impl_->pending_destroy(e))
        return make_error("Cannot rename '" + inf.id +
                              "': the entity is being destroyed (destroy() ran this frame and flush() has not yet)",
                          "Its id is already free for a new entity; rename it before destroying it, or create the "
                          "replacement with the id you want.");
    if (inf.id == newId) return {};
    if (auto it = impl_->ids.find(std::string(newId)); it != impl_->ids.end())
        return make_error("Entity id '" + std::string(newId) + "' is already used by another entity",
                          "Choose a different id, e.g. '" + std::string(newId) + "_2'.");
    impl_->unregister_id(e);
    inf.id = std::string(newId);
    impl_->ids[inf.id] = e;
    return {};
}

// ------------------------------------------------------------ components --
void* World::add(Entity e, const TypeInfo& type) {
    FA_ASSERT(alive(e), "World::add on a dead or null entity");
    note_mutable_access(e, type);
    return impl_->pool(type).add(e);
}

void World::note_mutable_access(Entity e, const TypeInfo& type) {
    if (type.id == impl_->transformPool->type().id)
        impl_->dirty_world(e);
    else if (type.id == impl_->infoPool->type().id)
        impl_->dirty_active(e);
}

std::uint64_t World::hierarchy_version() const { return impl_->hversion.load(std::memory_order_relaxed); }

void* World::get(Entity e, const TypeInfo& type) {
    if (!alive(e)) return nullptr;
    const ComponentPool* p = impl_->find_pool(type);
    if (!p) return nullptr;
    note_mutable_access(e, type);
    return p->get(e);
}

const void* World::get(Entity e, const TypeInfo& type) const {
    if (!alive(e)) return nullptr;
    const ComponentPool* p = impl_->find_pool(type);
    return p ? p->get(e) : nullptr;
}

void World::remove(Entity e, const TypeInfo& type) {
    if (!alive(e)) return;
    if (type.id == impl_->infoPool->type().id || type.id == impl_->transformPool->type().id) {
        FA_WARN("scene", "{} cannot be removed from an entity (every entity has one)", type.name);
        return;
    }
    if (ComponentPool* p = type.id < impl_->pools.size() ? impl_->pools[type.id].get() : nullptr) p->remove(e);
}

std::vector<const TypeInfo*> World::components_of(Entity e) const {
    std::vector<const TypeInfo*> out;
    if (!alive(e)) return out;
    for (const auto& p : impl_->pools)
        if (p && p->has(e)) out.push_back(&p->type());
    return out;  // pools are indexed by TypeId, i.e. registration order
}

std::vector<Entity> World::entities_with(const TypeInfo* type) const {
    if (!type) return {};
    const ComponentPool* p = impl_->find_pool(*type);
    return p ? p->entities() : std::vector<Entity>{};
}

void World::walk_owners(const TypeInfo& type, void* ctx, void (*visit)(void*, Entity, void*)) {
    ComponentPool* p = type.id < impl_->pools.size() ? impl_->pools[type.id].get() : nullptr;
    if (!p) return;
    if (type.id != impl_->transformPool->type().id && type.id != impl_->infoPool->type().id) {
        p->walk(visit, ctx);
        return;
    }
    // The callback gets a mutable reference to a Transform or an EntityInfo: it counts as a write, entity by entity.
    struct Wrap {
        Impl* impl;
        void* inner;
        void (*visit)(void*, Entity, void*);
    } wrap{impl_.get(), ctx, visit};
    // A dead handle only drops an entry nobody reads.
    if (type.id == impl_->transformPool->type().id) {
        p->walk(
            [](void* c, Entity e, void* component) {
                Wrap& w = *static_cast<Wrap*>(c);
                w.impl->dirty_world(e);
                w.visit(w.inner, e, component);
            },
            &wrap);
    } else {
        p->walk(
            [](void* c, Entity e, void* component) {
                Wrap& w = *static_cast<Wrap*>(c);
                w.impl->dirty_active(e);
                w.visit(w.inner, e, component);
            },
            &wrap);
    }
}

std::size_t World::count(const TypeInfo* type) const {
    if (!type) return 0;
    const ComponentPool* p = impl_->find_pool(*type);
    return p ? p->size() : 0;
}

// ------------------------------------------------------------- hierarchy --
Result<void> World::check_set_parent(Entity child, Entity parent) const {
    const Impl& d = *impl_;
    if (!alive(child))
        return make_error("Cannot move an entity that was destroyed", "Check world.alive(entity) first.");
    if (!parent.is_null() && !alive(parent))
        return make_error("The new parent entity is not alive",
                          "Check world.alive(parent) first, or pass a null parent for the top level.");
    if (d.pending_destroy(child))
        return make_error(
            "Cannot move '" + id_of(child) +
                "': it is being destroyed (destroy() ran this frame and flush() has not yet)",
            "Move it before destroying it, or leave it: its whole subtree goes away at the end of the frame. "
            "To keep the entity, do not destroy it.");
    if (!parent.is_null() && d.pending_destroy(parent))
        return make_error(
            "Cannot make '" + id_of(child) + "' a child of '" + id_of(parent) + "': '" + id_of(parent) +
                "' is being destroyed (itself or one of its ancestors), so the child would be destroyed with it",
            "Pick a parent that is not being destroyed, or create the child after the frame's flush.");
    if (parent == child || (!parent.is_null() && is_ancestor(child, parent)))
        return make_error("Making '" + id_of(child) + "' a child of '" + id_of(parent) + "' would create a cycle",
                          "Pick a parent that is not the entity or one of its descendants.");
    return {};
}

void World::set_parent(Entity child, Entity parent, bool keepWorldTransform, int index) {
    Impl& d = *impl_;
    if (!alive(child)) return;
    if (auto r = check_set_parent(child, parent); !r) {
        FA_WARN("scene", "set_parent: {}; ignoring. {}", r.error().message, r.error().hint);
        return;
    }
    Mat4 oldWorld;
    if (keepWorldTransform) oldWorld = world_matrix(child);

    Entity oldParent = d.slots[child.index].parent;
    if (!oldParent.is_null()) {
        auto& sib = d.slots[oldParent.index].children;
        sib.erase(std::remove(sib.begin(), sib.end(), child), sib.end());
    }
    d.slots[child.index].parent = parent;
    if (!parent.is_null()) {
        auto& sib = d.slots[parent.index].children;
        if (index < 0 || static_cast<std::size_t>(index) >= sib.size())
            sib.push_back(child);
        else
            sib.insert(sib.begin() + index, child);
    }
    d.dirty_world(child);
    d.dirty_active(child);

    if (keepWorldTransform) {
        Mat4 parentWorld = parent.is_null() ? Mat4::identity() : world_matrix(parent);
        Mat4 local = parentWorld.inverse() * oldWorld;
        auto* t = static_cast<Transform*>(d.transformPool->get(child));
        decompose(local, t->position, t->rotation, t->scale);
    }
}

std::string World::check_child_index(Entity parent, Entity moving, double index) const {
    if (parent.is_null() || !alive(parent))
        return "An index needs a parent: top-level entities stay in creation order. Pass a parent, or leave the index "
               "out.";
    if (index != std::floor(index) || index < 0)
        return std::format("The index must be a whole number from 0, got {}.", index);
    const auto& sib = impl_->slots[parent.index].children;
    long long n = static_cast<long long>(sib.size());
    if (!moving.is_null() && std::find(sib.begin(), sib.end(), moving) != sib.end()) --n;
    if (index > static_cast<double>(n))
        return std::format("The index {} is past the end: '", index) + id_of(parent) + "' has " + std::to_string(n) +
               " other child" + (n == 1 ? "" : "ren") + ", so the index goes from 0 to " + std::to_string(n) + " (" +
               std::to_string(n) + " = last). Leave the index out to append.";
    return {};
}

Entity World::parent(Entity e) const { return alive(e) ? impl_->slots[e.index].parent : kNullEntity; }

const std::vector<Entity>& World::children(Entity e) const {
    static const std::vector<Entity> none;
    return alive(e) ? impl_->slots[e.index].children : none;
}

std::vector<Entity> World::roots() const {
    std::vector<Entity> out;
    for (Entity e : impl_->infoPool->entities())
        if (impl_->slots[e.index].parent.is_null()) out.push_back(e);
    return out;
}

bool World::is_ancestor(Entity ancestor, Entity e) const {
    if (!alive(e)) return false;
    for (Entity cur = impl_->slots[e.index].parent; !cur.is_null(); cur = impl_->slots[cur.index].parent)
        if (cur == ancestor) return true;
    return false;
}

Mat4 World::world_matrix(Entity e) const {
    if (!alive(e)) return Mat4::identity();
    return impl_->world_cached(e);
}

Mat4 World::drawn_matrix(Entity e) const {
    if (feel_.poseCount == 0) return world_matrix(e);
    if (!alive(e)) return Mat4::identity();
    // The same product as world_matrix (down from the root), with the visual pose of each entity of the chain; not cached
    // (the poses change every frame). The chain sits on the stack up to 32 levels; a chain with no pose in it is world_matrix.
    constexpr std::size_t kInline = 32;
    Entity inlineChain[kInline];
    std::vector<Entity> longChain;
    std::size_t n = 0;
    bool anyPose = false;
    for (Entity cur = e; !cur.is_null(); cur = impl_->slots[cur.index].parent) {
        anyPose = anyPose || feel_.pose_of(cur) != nullptr;
        if (n < kInline) {
            inlineChain[n] = cur;
        } else {
            if (longChain.empty()) longChain.assign(inlineChain, inlineChain + kInline);
            longChain.push_back(cur);
        }
        ++n;
    }
    if (!anyPose) return world_matrix(e);
    const Entity* chain = n <= kInline ? inlineChain : longChain.data();
    Mat4 m;
    bool first = true;
    for (std::size_t k = n; k-- > 0;) {
        const auto* t = static_cast<const Transform*>(impl_->transformPool->get(chain[k]));
        Mat4 local;
        if (const FeelPose* p = feel_.pose_of(chain[k]))
            local = Mat4::trs(t->position + p->position, t->rotation + p->rotation,
                              {t->scale.x * p->scale.x, t->scale.y * p->scale.y, t->scale.z * p->scale.z});
        else
            local = Mat4::trs(t->position, t->rotation, t->scale);
        m = first ? local : m * local;
        first = false;
    }
    return m;
}

Vec3 World::world_position(Entity e) const { return world_matrix(e).translation(); }

void World::set_world_position(Entity e, Vec3 p) {
    if (!alive(e)) return;
    Entity par = impl_->slots[e.index].parent;
    Vec3 local = par.is_null() ? p : world_matrix(par).inverse().transform_point(p);
    impl_->dirty_world(e);
    static_cast<Transform*>(impl_->transformPool->get(e))->position = local;
}

// ------------------------------------------------------------- observers --
int World::on_destroy(EntityCallback cb) {
    int id = impl_->nextObserver++;
    impl_->observers.emplace_back(id, std::move(cb));
    return id;
}

void World::remove_observer(int id) {
    auto& o = impl_->observers;
    o.erase(std::remove_if(o.begin(), o.end(), [&](auto& p) { return p.first == id; }), o.end());
}

}  // namespace fa
