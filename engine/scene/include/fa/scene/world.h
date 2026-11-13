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
#include <set>
#include <string>
#include <string_view>
#include <tuple>
#include <type_traits>
#include <utility>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/reflect.h"
#include "fa/scene/components.h"
#include "fa/scene/feel.h"
#include "fa/scene/mesh_store.h"
#include "fa/scene/ui_tooltip.h"

namespace fa {

// Physics (and later others) push events here; the script system dispatches
// them to behaviours (onCollisionEnter, onTriggerEnter...) and clears them.
struct CollisionEvent {
    enum class Phase : std::int32_t { Begin, End };
    Phase phase = Phase::Begin;
    Entity a, b;
    bool trigger = false;  // true if either collider is a trigger/sensor
    Vec3 point{};          // contact point (world), Begin only
    Vec3 normal{};         // from a to b, Begin only
    float impulse = 0.0f;  // approximate impact strength, Begin only
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
    void clear() {
        collisions.clear();
        game.clear();
    }
};

class ComponentPool;  // defined in src/component_pool.h
class ParticleStore;  // scene/particle_store.h

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

    // Active = EntityInfo.active and all ancestors active. Answered from the hierarchy cache (see world_matrix).
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
    // Renames the stable id (fails if taken, or if the entity is being destroyed: its id is already free). Updates lookup tables.
    Result<void> set_id(Entity e, std::string_view newId);

    // ------------------------------------------------------- typed components
    template <class T>
    T& add(Entity e) {
        return *static_cast<T*>(add(e, type_of<T>()));
    }
    template <class T>
    T& set(Entity e, T value) {
        T& c = add<T>(e);
        c = std::move(value);
        return c;
    }
    template <class T>
    T* get(Entity e) {
        return static_cast<T*>(get(e, type_of<T>()));
    }
    template <class T>
    const T* get(Entity e) const {
        return static_cast<const T*>(get(e, type_of<T>()));
    }
    template <class T>
    bool has(Entity e) const {
        return get(e, type_of<T>()) != nullptr;
    }
    template <class T>
    void remove(Entity e) {
        remove(e, type_of<T>());
    }

    // Calls fn(Entity, Ts&...) for every alive entity having all Ts (active or
    // not — systems check active_in_hierarchy themselves).
    //
    //  * The walk is in place (no copy of the owner list) and starts from the pool with the FEWEST owners among the
    //    Ts (the first one on a tie), so each<Sprite, Collider2D> costs what the colliders cost, not what the sprites
    //    cost. The order is therefore that pool's insertion order: with several Ts it is NOT always the first type's.
    //    Use entities_with(type) and get<T>() when the order of one given type matters.
    //  * Safe inside fn: add or remove components of any type (the driving one too), destroy() (deferred), and start
    //    another each over the same types. An entity that loses a component of the Ts before its turn is skipped. An
    //    entity that gains the driving component during the walk is not visited (the walk stops at the owners it had
    //    when it began); one that gains a component of the other Ts is visited if it reaches its turn with all of them.
    //  * Not safe: clear() (the walk ends, and the references given to fn dangle).
    template <class... Ts, class Fn>
    void each(Fn&& fn) {
        static_assert(sizeof...(Ts) > 0, "World::each needs at least one component type");
        const TypeInfo* types[] = {&type_of<Ts>()...};
        std::size_t driver = 0;
        std::size_t fewest = count(types[0]);
        for (std::size_t i = 1; i < sizeof...(Ts); ++i) {
            const std::size_t n = count(types[i]);
            if (n < fewest) {
                fewest = n;
                driver = i;
            }
        }
        if (fewest == 0) return;
        struct Ctx {
            World* world;
            std::remove_reference_t<Fn>* fn;
            std::size_t driver;
        } ctx{this, &fn, driver};
        walk_owners(*types[driver], &ctx, [](void* p, Entity e, void* driving) {
            Ctx& c = *static_cast<Ctx*>(p);
            if (!c.world->alive(e)) return;
            [&]<std::size_t... I>(std::index_sequence<I...>) {
                // The driving pool already gave its component; the others are looked up.
                const std::tuple<Ts*...> ptrs{
                    (I == c.driver ? static_cast<Ts*>(driving) : c.world->template get<Ts>(e))...};
                if ((!std::get<I>(ptrs) || ...)) return;
                (*c.fn)(e, *std::get<I>(ptrs)...);
            }(std::index_sequence_for<Ts...>{});
        });
    }

    // The walk behind each(): calls visit(ctx, entity, component) for every owner of `type`, in insertion order, in
    // place. Same rules as each (an owner added during the walk is not visited; removing is safe); it does not check
    // alive(). Nothing happens for a type nobody owns.
    void walk_owners(const TypeInfo& type, void* ctx, void (*visit)(void* ctx, Entity e, void* component));

    // -------------------------------------------------- reflected components
    void* add(Entity e, const TypeInfo& type);  // default-constructs, or returns the existing one
    void* get(Entity e, const TypeInfo& type);
    const void* get(Entity e, const TypeInfo& type) const;
    void remove(Entity e, const TypeInfo& type);                    // EntityInfo/Transform cannot be removed
    std::vector<const TypeInfo*> components_of(Entity e) const;     // registration order
    std::vector<Entity> entities_with(const TypeInfo* type) const;  // insertion order snapshot

    // How many entities own a component of `type`, in O(1) (the pool's live count; no copy like entities_with). It is
    // exactly entities_with(type).size(): an entity with a deferred destroy() still counts until flush() removes it.
    // 0 for a null type. Prefer these to entities_with(...).empty() / .size().
    std::size_t count(const TypeInfo* type) const;
    // True when at least one entity owns `type`: count(type) > 0.
    bool any(const TypeInfo* type) const { return count(type) > 0; }
    template <class T>
    std::size_t count() const {
        return count(&type_of<T>());
    }
    template <class T>
    bool any() const {
        return count(&type_of<T>()) > 0;
    }

    // ------------------------------------------------------------- hierarchy
    // keepWorldTransform: recompute the local Transform so the world pose is unchanged.
    // `index` is the place among the new parent's children (0 = first, after removing `child` from its old place when the
    // parent does not change); negative or past the end = last (clamped, never an error here: commands and scripts check
    // the range first). It is ignored for a null parent: top-level entities stay in creation order.
    // An entity being destroyed (destroy() ran, flush() has not; itself or an ancestor) is not moved and takes no new child:
    // its subtree is already unregistered and goes away at the flush. A refused move logs a warning and changes nothing;
    // call check_set_parent first to get the teaching error.
    void set_parent(Entity child, Entity parent, bool keepWorldTransform = false, int index = -1);
    // The error set_parent would refuse with (child dead, parent dead, child or parent being destroyed, a cycle), or ok.
    Result<void> check_set_parent(Entity child, Entity parent) const;
    // "" when `index` is a valid place for `moving` (or a new entity: kNullEntity) among `parent`'s children, else a sentence
    // that says what is wrong and the valid range. Valid: 0 .. number of other children; a null parent takes no index.
    std::string check_child_index(Entity parent, Entity moving, double index) const;
    Entity parent(Entity e) const;  // kNullEntity for roots
    const std::vector<Entity>& children(Entity e) const;
    std::vector<Entity> roots() const;  // creation order
    bool is_ancestor(Entity ancestor, Entity e) const;

    // The parent's world matrix * the local TRS, from the root down (identity for a dead entity). It comes from a cache that
    // is filled on demand and kept until something that can change it is written, so reading the same entities again costs
    // a copy of 16 floats. THE RULES (docs/ARCHITECTURE.md, "The hierarchy cache"):
    //  * Every MUTABLE access to a Transform or an EntityInfo invalidates: World::get<T>(e) / get(e, type) / add / info(e) on a
    //    non-const World, a callback of each<Transform>, set_parent, set_world_position and set_active. So any way of writing
    //    (C++, reflection, scripts, commands, the inspector, animation) is seen, and a reader that only reads should hold a
    //    `const World&` (or call get through a const reference): reading through a mutable World counts as a write.
    //  * A Transform or EntityInfo reference KEPT from an earlier get and written to AFTER a world_matrix / active_in_hierarchy
    //    call is not seen (nothing marks that write): get it again after the read, or write before it.
    //  * Several threads may read (world_matrix, world_position, active_in_hierarchy, drawn_matrix) at once, a missing entry
    //    is filled under a small lock; none may write meanwhile (the usual rule for jobs: they read, the main thread writes).
    // hierarchy_version() counts the invalidations (it grows when a cached value is dropped), so a system can tell that
    // nothing moved since it last looked.
    Mat4 world_matrix(Entity e) const;
    Vec3 world_position(Entity e) const;
    // world_matrix() with the visual poses of the game feel effects (shake, squash; feel.h) multiplied into each entity of the
    // chain: what is DRAWN. Equal to world_matrix() while no such effect runs. Only drawing uses it; picking, bounds, physics, audio
    // and scripts read world_matrix() / the Transform, which an effect never changes.
    Mat4 drawn_matrix(Entity e) const;
    void set_world_position(Entity e, Vec3 p);  // converts into the parent's space
    // How many times a cached world matrix or active-in-hierarchy answer was dropped because something that can change it was
    // written (see world_matrix). It never goes down; reading through a const World does not move it.
    std::uint64_t hierarchy_version() const;

    // --------------------------------------------------------------- misc
    SceneSettings& settings() { return settings_; }
    const SceneSettings& settings() const { return settings_; }
    WorldEvents& events() { return events_; }
    Rng& rng() { return rng_; }
    const Rng& rng() const { return rng_; }
    // Game feel (feel.h): the running camera shakes, flashes, squashes, knockbacks and hit-stops, and the player's reduce motion /
    // reduced effects choices. clear() drops the effects and keeps the choices.
    FeelState& feel() { return feel_; }
    const FeelState& feel() const { return feel_; }
    // The part of the screen covered by a notch, rounded corners or system bars, in DESIGN pixels (the renderer's target
    // size, origin top-left). The windowed runtime sets it every frame from the device; a headless run or a test sets
    // it to try a "notched device". Anchored items with `safeArea` stay inside what is left (anchor_point, ui_rect.h).
    // Survives clear() and scene loads: it describes the device, not the scene.
    const EdgeInsets& safe_insets() const { return safeInsets_; }
    void set_safe_insets(const EdgeInsets& insets) { safeInsets_ = insets; }

    // The interface scale `ui.scale` (1 = as written; ui_rect.h explains what it multiplies). The runtime sets it from the
    // project default and from `ui.scale = ...`; a test sets it directly. Survives clear() and scene loads, like the safe
    // insets: it is a setting of the player, not of the scene.
    float ui_scale() const { return uiScale_; }
    void set_ui_scale(float scale) { uiScale_ = scale; }

    // Tooltips (ui_tooltip.h): the project's delay and style (a setting of the game, so it survives clear() and scene loads like
    // ui_scale()) and the tooltip on screen now, which fa_ui writes every frame, fa_render draws and a scene load removes.
    const UiTooltipSettings& ui_tooltip_settings() const { return tooltipSettings_; }
    void set_ui_tooltip_settings(const UiTooltipSettings& s) { tooltipSettings_ = s; }
    const UiTooltipView& ui_tooltip() const { return tooltip_; }
    UiTooltipView& ui_tooltip() { return tooltip_; }

    // True when the game's current language is written right to left. The runtime sets it with the language (localization
    // pass); Text align start / end and Panel direction auto read it; a test sets it to try a right-to-left language. Survives
    // clear() and scene loads, like the safe insets.
    bool rtl() const { return rtl_; }
    void set_rtl(bool rtl) { rtl_ = rtl; }
    // `ui.mirrorRtl` (factoria.json "ui": {"mirrorRtl"}, default true): in a right-to-left language the screen-space UI is drawn
    // mirrored (ui_rect.h, ui_mirrored). The runtime sets it from the project and from `ui.mirrorRtl = ...`; survives clear()
    // and scene loads, like rtl().
    bool ui_mirror_rtl() const { return uiMirrorRtl_; }
    void set_ui_mirror_rtl(bool on) { uiMirrorRtl_ = on; }
    // True when the UI is mirrored right now: ui_mirror_rtl() and rtl().
    bool ui_mirror() const { return uiMirrorRtl_ && rtl_; }
    // The game's current language tag ("" = English / localization off): what a Chart writes its axis labels in. Set by the
    // runtime with the language, like rtl(); survives clear() and scene loads.
    const std::string& language() const { return language_; }
    void set_language(std::string language) { language_ = std::move(language); }

    std::uint64_t frame() const { return frame_; }
    double time() const { return time_; }  // simulated seconds since scene start
    void advance_clock(double dt) {
        time_ += dt;
        ++frame_;
    }
    void reset_clock() {
        time_ = 0;
        frame_ = 0;
    }

    // Source scene path this world was loaded from ("" if built in code).
    const std::string& scene_path() const { return scenePath_; }
    void set_scene_path(std::string p) { scenePath_ = std::move(p); }
    // Counts the scene loads of this world: it grows by one on every load, also when the same scene is loaded again, and
    // clear() keeps it. The script API shows it as scene.generation.
    std::uint64_t scene_generation() const { return sceneGeneration_; }
    void bump_scene_generation() { ++sceneGeneration_; }

    // How many effects (Vfx) play or still hold child entities: what the `vfx.play` budget counts (kVfxMaxPlaying). update_vfx
    // recounts it every step and vfx_play adds the effect it starts; clear() sets it back to 0.
    int vfx_live() const { return vfxLive_; }
    void set_vfx_live(int n) { vfxLive_ = n < 0 ? 0 : n; }

    // The procedural meshes (mesh_store.h) scripts built with mesh.create: used as MeshRenderer.mesh by their "mesh:N" id.
    // clear() (every scene load that is not additive) releases them all.
    MeshStore& meshes() { return meshes_; }
    const MeshStore& meshes() const { return meshes_; }

    // The state of this world's ParticleEmitters (particle_store.h): the live particles, their random sequences and what the
    // renderer draws. Owned by the world, so two worlds that have entities with the same handle (the editor's scene and its Play
    // session) never see each other's emitters. clear() empties it.
    ParticleStore& particles() { return *particles_; }
    const ParticleStore& particles() const { return *particles_; }
    // The "entity|clip" pairs update_sprite_animators() already warned about (a SpriteAnimator.clip its sheet does not have), so
    // each is said once per scene. clear() forgets them.
    std::set<std::string>& warned_sprite_clips() { return warnedSpriteClips_; }

    // Observers (physics/audio/script systems release resources, editor refreshes).
    using EntityCallback = std::function<void(Entity)>;
    int on_destroy(EntityCallback cb);  // called right before an entity is erased
    void remove_observer(int id);

    template <class T>
    static const TypeInfo& type_of() {
        const TypeInfo* t = TypeRegistry::global().of<T>();
        FA_ASSERT(t != nullptr,
                  "component type not registered (did you call ensure_builtin_components / register it?)");
        return *t;
    }

private:
    struct Impl;
    // A mutable reference to a component of `type` of `e` is about to be given out: drops what the hierarchy cache keeps
    // when it is a Transform or an EntityInfo.
    void note_mutable_access(Entity e, const TypeInfo& type);
    std::unique_ptr<Impl> impl_;
    SceneSettings settings_;
    WorldEvents events_;
    Rng rng_;
    FeelState feel_;
    EdgeInsets safeInsets_;
    float uiScale_ = 1.0f;
    UiTooltipSettings tooltipSettings_;
    UiTooltipView tooltip_;
    bool rtl_ = false;
    bool uiMirrorRtl_ = true;
    std::string language_;
    std::uint64_t frame_ = 0;
    double time_ = 0.0;
    std::string scenePath_;
    std::uint64_t sceneGeneration_ = 0;
    int vfxLive_ = 0;
    MeshStore meshes_;
    std::unique_ptr<ParticleStore> particles_;
    std::set<std::string> warnedSpriteClips_;
};

}  // namespace fa
