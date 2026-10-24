#include "fa/scene/world.h"

#include <algorithm>
#include <cmath>
#include <format>
#include <unordered_map>

#include "component_pool.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"

namespace fa {

namespace {

// Euler angles (pitch, yaw, roll degrees) of a rotation matrix built as Ry * Rx * Rz.
Vec3 euler_from_rotation(const Mat4& m) {
    auto r = [&](int row, int col) { return m.at(col, row); };
    float sinPitch = clamp(-r(1, 2), -1.0f, 1.0f);
    float pitch = std::asin(sinPitch), yaw, roll;
    if (std::fabs(sinPitch) < 0.9999f) {
        yaw = std::atan2(r(0, 2), r(2, 2));
        roll = std::atan2(r(1, 0), r(1, 1));
    } else {  // gimbal lock: fold roll into yaw
        yaw = std::atan2(-r(2, 0), r(0, 0));
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
        rot.at(col, 0) = v.x / s; rot.at(col, 1) = v.y / s; rot.at(col, 2) = v.z / s;
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
        Entity parent;
        std::vector<Entity> children;
    };

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
    bool pending_destroy(Entity e) const {
        if (!alive(e)) return false;
        for (Entity cur = e; !cur.is_null(); cur = slots[cur.index].parent)
            if (slots[cur.index].pending) return true;
        return false;
    }
};

World::World() : impl_(std::make_unique<Impl>()) {
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
    }
    Impl::Slot& slot = d.slots[e.index];
    slot.alive = true;
    slot.pending = false;
    slot.parent = kNullEntity;
    slot.children.clear();
    ++d.aliveCount;

    std::string finalId;
    if (id.empty()) {
        do { finalId = "e" + std::to_string(d.autoId++); } while (d.ids.count(finalId));
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
    for (Entity x : subtree) impl_->unregister_id(x);
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
}

bool World::active_in_hierarchy(Entity e) const {
    if (!alive(e)) return false;
    for (Entity cur = e; !cur.is_null(); cur = impl_->slots[cur.index].parent)
        if (!impl_->info(cur).active) return false;
    return true;
}

void World::set_active(Entity e, bool active) {
    if (alive(e)) impl_->info(e).active = active;
}

// ------------------------------------------------------ identity/lookup --
EntityInfo& World::info(Entity e) {
    FA_ASSERT(alive(e), "World::info on a dead or null entity");
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
    if (newId.empty()) return make_error("Entity id must not be empty", "Use a short unique string such as \"player\" or \"enemy_1\".");
    EntityInfo& inf = impl_->info(e);
    if (inf.id == newId) return {};
    if (auto it = impl_->ids.find(std::string(newId)); it != impl_->ids.end())
        return make_error("Entity id '" + std::string(newId) + "' is already used by another entity",
                          "Choose a different id, e.g. '" + std::string(newId) + "_2'.");
    if (!impl_->pending_destroy(e)) impl_->unregister_id(e);
    inf.id = std::string(newId);
    if (!impl_->pending_destroy(e)) impl_->ids[inf.id] = e;
    return {};
}

// ------------------------------------------------------------ components --
void* World::add(Entity e, const TypeInfo& type) {
    FA_ASSERT(alive(e), "World::add on a dead or null entity");
    return impl_->pool(type).add(e);
}

void* World::get(Entity e, const TypeInfo& type) {
    if (!alive(e)) return nullptr;
    const ComponentPool* p = impl_->find_pool(type);
    return p ? p->get(e) : nullptr;
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

// ------------------------------------------------------------- hierarchy --
void World::set_parent(Entity child, Entity parent, bool keepWorldTransform, int index) {
    Impl& d = *impl_;
    if (!alive(child)) return;
    if (!parent.is_null() && !alive(parent)) {
        FA_WARN("scene", "set_parent: parent entity is not alive; ignoring");
        return;
    }
    if (parent == child || (!parent.is_null() && is_ancestor(child, parent))) {
        FA_ERROR("scene", "set_parent: making '{}' a child of '{}' would create a cycle; ignoring", id_of(child), id_of(parent));
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
        if (index < 0 || static_cast<std::size_t>(index) >= sib.size()) sib.push_back(child);
        else sib.insert(sib.begin() + index, child);
    }

    if (keepWorldTransform) {
        Mat4 parentWorld = parent.is_null() ? Mat4::identity() : world_matrix(parent);
        Mat4 local = parentWorld.inverse() * oldWorld;
        auto* t = static_cast<Transform*>(d.transformPool->get(child));
        decompose(local, t->position, t->rotation, t->scale);
    }
}

std::string World::check_child_index(Entity parent, Entity moving, double index) const {
    if (parent.is_null() || !alive(parent))
        return "An index needs a parent: top-level entities stay in creation order. Pass a parent, or leave the index out.";
    if (index != std::floor(index) || index < 0)
        return std::format("The index must be a whole number from 0, got {}.", index);
    const auto& sib = impl_->slots[parent.index].children;
    long long n = static_cast<long long>(sib.size());
    if (!moving.is_null() && std::find(sib.begin(), sib.end(), moving) != sib.end()) --n;
    if (index > static_cast<double>(n))
        return std::format("The index {} is past the end: '", index) + id_of(parent) + "' has " +
               std::to_string(n) + " other child" + (n == 1 ? "" : "ren") + ", so the index goes from 0 to " + std::to_string(n) +
               " (" + std::to_string(n) + " = last). Leave the index out to append.";
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
    Mat4 m = Mat4::identity();
    for (Entity cur = e; !cur.is_null(); cur = impl_->slots[cur.index].parent) {
        const auto* t = static_cast<const Transform*>(impl_->transformPool->get(cur));
        m = Mat4::trs(t->position, t->rotation, t->scale) * m;
    }
    return m;
}

Vec3 World::world_position(Entity e) const { return world_matrix(e).translation(); }

void World::set_world_position(Entity e, Vec3 p) {
    if (!alive(e)) return;
    Entity par = impl_->slots[e.index].parent;
    Vec3 local = par.is_null() ? p : world_matrix(par).inverse().transform_point(p);
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
