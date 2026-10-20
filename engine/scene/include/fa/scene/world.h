// World: the entity-component store for one running scene.
//
// Design (simple on purpose — predictable for AIs and humans):
//   * Entities are handles (index + generation). Every entity always has
//     EntityInfo (id, name, tags, active) and Transform.
//   * Components are reflected structs (see components.h / reflect.h) stored in
//     one type-erased pool per type.
//   * POINTER STABILITY: a component pointer/reference stays valid until that
//     component or its entity is removed — adding other components or entities
//     never invalidates it.
//   * destroy() is DEFERRED until flush() (the engine flushes at the end of
//     every frame) so systems can destroy while iterating. Children are
//     destroyed with their parent.
//   * Iteration order is deterministic (component insertion order), which keeps
//     headless runs reproducible.
#pragma once

#include <functional>
#include <memory>
#include <string>
#include <string_view>
#include <tuple>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/reflect.h"
#include "fa/scene/components.h"

namespace fa {

// Physics (and later others) push events here; the script system dispatches
// them to behaviours (onCollisionEnter, onTriggerEnter...) and clears them.
struct CollisionEvent {
    enum class Phase : std::int32_t { Begin, End };
    Phase phase = Phase::Begin;
    Entity a, b;
    bool trigger = false;   // true if either collider is a trigger/sensor
    Vec3 point{};           // contact point (world), Begin only
    Vec3 normal{};          // from a to b, Begin only
    float impulse = 0.0f;   // approximate impact strength, Begin only
};

// Free-form gameplay events (scripts: world.emit("coin_collected", {...})).
struct GameEvent {
    std::string name;
    Json data;
    Entity source;
};

struct WorldEvents {
    std::vector<CollisionEvent> collisions;
    std::vector<GameEvent> game;
    void clear() { collisions.clear(); game.clear(); }
};

class ComponentPool;  // defined in src/component_pool.h

class World {
public:
    World();
    ~World();
    World(const World&) = delete;
    World& operator=(const World&) = delete;

    // ------------------------------------------------------------ entities
    // id: stable string id; "" -> auto ("e" + counter). If the id is already
    // taken a numeric suffix is appended ("enemy" -> "enemy_2").
    Entity create(std::string_view name = {}, std::string_view id = {});
    // Deferred (see flush): the entity (and its children) stay in memory until flush(), but are
    // unregistered at once — find/find_by_id/find_by_tag no longer return them and their ids are
    // immediately reusable. Check pending_destroy() if you hold a handle.
    void destroy(Entity e);
    void destroy_immediate(Entity e);  // also destroys children; avoid during iteration
    void flush();                      // apply deferred destroys
    bool alive(Entity e) const;
    bool pending_destroy(Entity e) const;
    std::size_t entity_count() const;
    std::vector<Entity> entities() const;  // alive entities, creation order
    void clear();                          // destroy everything immediately, reset settings

    // Active = EntityInfo.active and all ancestors active.
    bool active_in_hierarchy(Entity e) const;
    void set_active(Entity e, bool active);

    // ------------------------------------------------------ identity/lookup
    EntityInfo& info(Entity e);
    const EntityInfo& info(Entity e) const;
    const std::string& id_of(Entity e) const;
    Entity find_by_id(std::string_view id) const;
    Entity find(std::string_view idOrName) const;  // id first, then first entity with that name
    std::vector<Entity> find_all_by_name(std::string_view name) const;
    std::vector<Entity> find_by_tag(std::string_view tag) const;
    bool has_tag(Entity e, std::string_view tag) const;
    // Renames the stable id (fails if taken). Updates lookup tables.
    Result<void> set_id(Entity e, std::string_view newId);

    // ------------------------------------------------------- typed components
    template <class T> T& add(Entity e) { return *static_cast<T*>(add(e, type_of<T>())); }
    template <class T> T& set(Entity e, T value) { T& c = add<T>(e); c = std::move(value); return c; }
    template <class T> T* get(Entity e) { return static_cast<T*>(get(e, type_of<T>())); }
    template <class T> const T* get(Entity e) const { return static_cast<const T*>(get(e, type_of<T>())); }
    template <class T> bool has(Entity e) const { return get(e, type_of<T>()) != nullptr; }
    template <class T> void remove(Entity e) { remove(e, type_of<T>()); }

    // Calls fn(Entity, Ts&...) for every alive entity having all Ts (active or
    // not — systems check active_in_hierarchy themselves). Safe to add/remove
    // OTHER components and to destroy() (deferred) inside fn.
    template <class... Ts, class Fn>
    void each(Fn&& fn) {
        const TypeInfo* types[] = {&type_of<Ts>()...};
        for (Entity e : entities_with(types[0])) {
            if (!alive(e)) continue;
            auto ptrs = std::tuple<Ts*...>{get<Ts>(e)...};
            if (((std::get<Ts*>(ptrs) == nullptr) || ...)) continue;
            fn(e, *std::get<Ts*>(ptrs)...);
        }
    }

    // -------------------------------------------------- reflected components
    void* add(Entity e, const TypeInfo& type);  // default-constructs, or returns the existing one
    void* get(Entity e, const TypeInfo& type);
    const void* get(Entity e, const TypeInfo& type) const;
    void remove(Entity e, const TypeInfo& type);  // EntityInfo/Transform cannot be removed
    std::vector<const TypeInfo*> components_of(Entity e) const;  // registration order
    std::vector<Entity> entities_with(const TypeInfo* type) const;  // insertion order snapshot

    // ------------------------------------------------------------- hierarchy
    // keepWorldTransform: recompute the local Transform so the world pose is unchanged.
    void set_parent(Entity child, Entity parent, bool keepWorldTransform = false);
    Entity parent(Entity e) const;  // kNullEntity for roots
    const std::vector<Entity>& children(Entity e) const;
    std::vector<Entity> roots() const;  // creation order
    bool is_ancestor(Entity ancestor, Entity e) const;

    Mat4 world_matrix(Entity e) const;  // parent chain * local TRS
    Vec3 world_position(Entity e) const;
    void set_world_position(Entity e, Vec3 p);  // converts into the parent's space

    // --------------------------------------------------------------- misc
    SceneSettings& settings() { return settings_; }
    const SceneSettings& settings() const { return settings_; }
    WorldEvents& events() { return events_; }
    Rng& rng() { return rng_; }
    // The part of the screen covered by a notch, rounded corners or system bars, in DESIGN pixels (the renderer's target
    // size, origin top-left). The windowed runtime sets it every frame from the device; a headless run or a test sets
    // it to try a "notched device". Anchored items with `safeArea` stay inside what is left (anchor_point, ui_rect.h).
    // Survives clear() and scene loads: it describes the device, not the scene.
    const EdgeInsets& safe_insets() const { return safeInsets_; }
    void set_safe_insets(const EdgeInsets& insets) { safeInsets_ = insets; }

    // True when the game's current language is written right to left. The runtime sets it with the language (localization
    // pass); Text align start / end and Panel direction auto read it; a test sets it to try a right-to-left language. Survives
    // clear() and scene loads, like the safe insets.
    bool rtl() const { return rtl_; }
    void set_rtl(bool rtl) { rtl_ = rtl; }

    std::uint64_t frame() const { return frame_; }
    double time() const { return time_; }  // simulated seconds since scene start
    void advance_clock(double dt) { time_ += dt; ++frame_; }
    void reset_clock() { time_ = 0; frame_ = 0; }

    // Source scene path this world was loaded from ("" if built in code).
    const std::string& scene_path() const { return scenePath_; }
    void set_scene_path(std::string p) { scenePath_ = std::move(p); }

    // Observers (physics/audio/script systems release resources, editor refreshes).
    using EntityCallback = std::function<void(Entity)>;
    int on_destroy(EntityCallback cb);   // called right before an entity is erased
    void remove_observer(int id);

    template <class T>
    static const TypeInfo& type_of() {
        const TypeInfo* t = TypeRegistry::global().of<T>();
        FA_ASSERT(t != nullptr, "component type not registered (did you call ensure_builtin_components / register it?)");
        return *t;
    }

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
    SceneSettings settings_;
    WorldEvents events_;
    Rng rng_;
    EdgeInsets safeInsets_;
    bool rtl_ = false;
    std::uint64_t frame_ = 0;
    double time_ = 0.0;
    std::string scenePath_;
};

}  // namespace fa
