// Scene and prefab JSON <-> World.
//
// Scene file (scenes/*.scene.json):
// {
//   "format": "factoria.scene/1",
//   "settings": { "ambientLight": [..], "gravity2D": [0, -980], ... },   // SceneSettings fields
//   "entities": [
//     {
//       "id": "player",                    // optional, stable, unique; auto if omitted
//       "name": "Player",                  // optional
//       "tags": ["player"],                // optional
//       "active": true,                    // optional
//       "prefab": "prefabs/hero.prefab.json",  // optional: start from a prefab, then apply overrides below
//       "components": {                    // component name -> (partial) field object
//         "Transform": { "position": [0, 0, 0] },
//         "Sprite": { "texture": "assets/hero.png" }
//       },
//       "children": [ { ...entity... } ]   // optional nested children
//     }
//   ]
// }
// Entity-typed fields reference other entities by their string id.
// Prefab file (prefabs/*.prefab.json): { "format": "factoria.prefab/1", "entity": { ...entity... } }
//
// Prefab instances are remembered: EntityInfo::prefab / fromPrefab say which entities a prefab made, and saving with
// PrefabSave::Keep (the file form) writes such an entity as { id, prefab, only what differs from the prefab } with
// "overrides" for the prefab's descendants and "children" for the ones added to the instance root
// (diff_entity_with_prefab, below). What that form cannot say is written inline and reported.
//
// Loading is LENIENT and EXPLAINS itself: unknown components/fields and bad
// values produce messages with a JSON pointer and a "did you mean" hint;
// bad entries are skipped and everything else still loads.
#pragma once

#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/scene/world.h"

namespace fa {

struct LoadMessage {
    enum class Severity { Warning, Error };
    Severity severity = Severity::Error;
    std::string source;   // file path or "<memory>"
    std::string pointer;  // JSON pointer, e.g. "/entities/2/components/Sprite/color"
    std::string message;
    std::string hint;
    std::string to_string() const;  // "scenes/main.scene.json#/entities/2/...: message (hint: ...)"
};

// An Entity-typed field whose target id did not exist when the entity was loaded with `deferMissingRefs` (see
// entity_from_json): the caller can set `field` of `owner`'s `type` once an entity with `id` exists.
struct DeferredRef {
    Entity owner;
    const TypeInfo* type = nullptr;
    const FieldInfo* field = nullptr;
    std::string id;       // the entity id the field names
    std::string pointer;  // where the value was written, for messages
};

struct LoadReport {
    std::vector<LoadMessage> messages;
    std::vector<DeferredRef> deferred;  // only filled by entity_from_json(..., deferMissingRefs = true)
    std::vector<Entity> created;        // all entities created, in order
    bool ok() const;                    // no Error-severity messages
    std::size_t error_count() const;
    std::string summary() const;  // multi-line, for logs and tool output
};

struct SceneLoadOptions {
    bool additive = false;  // false: world.clear() first and apply settings
    Entity parent;          // additive loads may parent all roots under this entity
};

// Scenes
LoadReport load_scene(World& world, const Json& scene, std::string_view sourceName, const SceneLoadOptions& opts = {});
LoadReport load_scene_file(World& world, std::string_view path, const SceneLoadOptions& opts = {});
// What a save left out because a script spawned it at runtime: every entity of the skipped subtrees, and the label
// ("<id>" or "<id> (<name>)") of the first few subtree roots.
struct SpawnedSkip {
    std::size_t count = 0;
    std::vector<std::string> labels;  // at most 5
};

// How an entity that a prefab made (EntityInfo::prefab, set by a scene entry {"prefab": ...}, scene.spawn and
// instantiate_prefab) is written by entity_to_json and save_scene.
enum class PrefabSave {
    Expand,  // as ordinary inline entities (the default)
    Marks,  // inline too, plus the keys "$prefab" (on the root of an instance) and "$fromPrefab" (on what the prefab made)
            // that load_scene and entity_from_json read back, so an in-memory snapshot (editor undo, Play/Stop) keeps
            // where the entities came from. Never written to a file.
    Keep,  // the file form: {id, prefab, only what differs from the prefab, overrides, children added to the instance}
           // (diff_entity_with_prefab). An instance whose differences that form cannot express is expanded instead.
};
// An instance that PrefabSave::Keep wrote expanded, and why.
struct PrefabExpanded {
    std::string id;      // the instance root
    std::string prefab;  // its prefab file
    std::string reason;  // what the {prefab, differences} form cannot say, e.g. "the prefab's child 'Lid' was removed"
};

struct SaveSceneOptions {
    bool skipSpawned = false;        // leave out what scripts spawned at runtime (see save_scene)
    SpawnedSkip* skipped = nullptr;  // what that left out (may be null)
    PrefabSave prefabs = PrefabSave::Expand;
    std::vector<PrefabExpanded>* prefabsExpanded = nullptr;  // with Keep: the instances written expanded (may be null)
};

// Canonical JSON: nested children, only non-default fields, stable key order. The one exception is the gravity: `settings`
// always carries gravity2D and gravity3D, even at their defaults, so a reader of the file sees what the level uses.
// Includes entities scripts spawned at runtime (the editor's Play/Stop snapshot and undo need them); pass skipSpawned to leave them out.
// Prefab instances are written expanded (PrefabSave::Expand); the overload with options also offers Marks and Keep.
Json save_scene(const World& world, bool skipSpawned = false, SpawnedSkip* skipped = nullptr);
Json save_scene(const World& world, const SaveSceneOptions& options);
// The world as an in-memory snapshot to load_scene back (editor undo and redo, Play/Stop, AI revert): everything, spawned
// entities included, in the PrefabSave::Marks form, so the entities keep the prefab they came from.
Json snapshot_scene(const World& world);
// Writes the scene with the reviewable layout of dump_scene_json (below). Entities a script spawned at runtime
// (world.spawn, world.spawnPrefab) are NOT written unless includeSpawned: the script builds them again on load, so saving
// them duplicates them. `skipped` (may be null) reports what was left out. An entity that a prefab made is written as
// {"id", "prefab", only the differences from the prefab} (PrefabSave::Keep), so a later change of the prefab file still
// reaches the scene; `prefabsExpanded` (may be null) lists the instances that had to be written inline instead.
Result<void> save_scene_file(const World& world, std::string_view path, bool includeSpawned = false,
                             SpawnedSkip* skipped = nullptr, std::vector<PrefabExpanded>* prefabsExpanded = nullptr);

// Text of a scene or prefab document as written to disk: 2-space indent, with the short arrays of scalars on one line
// (vectors, colors, rects, tags, solidTiles; long ones wrap at about 100 columns) and a Tilemap's flat `tiles` array
// written one map row per line (`width` numbers per line, columns aligned, row 0 first), so the file shows the shape of
// the map. It is standard JSON: load_scene reads it like any other layout.
// Use it (or save_scene_json_file) for every scene and prefab file the engine writes.
std::string dump_scene_json(const Json& sceneOrPrefab);
Result<void> save_scene_json_file(std::string_view path, const Json& sceneOrPrefab);

// A scene/prefab file laid out the way dump_scene_json writes it, and whether the file on disk already is that text.
// scene.format writes `text`; project.validate warns when `same` is false. Only whitespace may differ: the new text is read
// back and compared with the data of the file (values and key order).
struct CanonicalScene {
    std::string text;
    bool same = false;
};
// Fails, with the reason, when the file cannot be read, is not valid JSON (message "file:line:column: invalid JSON: ..."),
// is not a JSON object, or its canonical layout would not read back as the same data.
Result<CanonicalScene> canonical_scene_layout(std::string_view file);

// True for a path ending in .scene.json or .prefab.json (case-insensitive).
bool is_scene_or_prefab_file(std::string_view path);
// Every *.scene.json and *.prefab.json below `dir` (project-relative, "" = the whole project), sorted: the files
// scene.format formats and project.validate checks, wherever the project keeps them (scenes/, prefabs/, levels/...).
// Folders that hold copies or tool state are skipped: names starting with '.', node_modules, and build/ at the project
// root (exports go to build/export).
std::vector<std::string> project_scene_files(std::string_view dir = {});

// Entities

// The rest value of every field an Animator that plays 2D clips (docs/ANIMATION.md, "2D clips") drives: what the field held
// before the first clip drove it. The driven fields are a runtime pose, not part of the scene, so the writers of scene
// and prefab files put these values in place of the posed ones.
struct PoseRestEntry {
    Entity entity;
    const TypeInfo* type = nullptr;
    const FieldInfo* field = nullptr;
    Json value;  // the field as JSON (all channels of a vector: the driven ones at rest, the others as they are now)
};
struct PoseRest {
    std::vector<PoseRestEntry> entries;  // sorted by entity (Entity::bits)
    bool empty() const { return entries.empty(); }
};
// Collects it from every Animator of `world`. Empty when no Animator plays 2D clips.
PoseRest collect_pose_rest(const World& world);

// The prefabs a save compares instances with, loaded once each into a scratch World. Give one cache to every call of a
// save (save_scene makes its own); without one every instance loads its prefab again.
class PrefabBaseCache {
public:
    PrefabBaseCache();
    ~PrefabBaseCache();
    PrefabBaseCache(const PrefabBaseCache&) = delete;
    PrefabBaseCache& operator=(const PrefabBaseCache&) = delete;
    // The cache also remembers what the strings of the World being saved say (to find out whether an id is named
    // elsewhere): it serves ONE World. Call this before using the cache with another one (a World's address is no key:
    // the next World often sits at the same place).
    void forget_world();
    struct Impl;
    Impl& impl() { return *impl_; }

private:
    std::unique_ptr<Impl> impl_;
};

struct EntityJsonOptions {
    bool includeChildren = true;
    bool includeDefaults = false;  // true = every field (useful for AI inspection)
    bool includeRuntime = false;   // include runtime-only fields (velocity mirrors, animator time...)
    // Leave out entities a script spawned at runtime (EntityInfo::scriptSpawned) together with their children.
    bool skipSpawned = false;
    // When skipSpawned: filled with what was left out (may be null).
    SpawnedSkip* skipped = nullptr;
    // Write these rest values instead of the posed ones of the fields 2D clips drive (null = write what the fields hold now).
    const PoseRest* poseRest = nullptr;
    // How the entities a prefab made are written (see PrefabSave). Keep only applies with includeChildren and neither
    // includeDefaults nor includeRuntime.
    PrefabSave prefabs = PrefabSave::Expand;
    // With Keep: the cache of loaded prefabs (null = every instance loads its prefab) and where the instances written
    // expanded are listed (null = not reported).
    PrefabBaseCache* prefabCache = nullptr;
    std::vector<PrefabExpanded>* prefabsExpanded = nullptr;
};
Json entity_to_json(const World& world, Entity e, const EntityJsonOptions& opts = {});

// How an entity differs from a prefab: what a scene file has to say about an instance of it. The prefab is loaded into a
// scratch World and compared with `entity` and its descendants (the children in order: the first ones are the prefab's own).
struct PrefabDiffOptions {
    // The entity's descendants carry EntityInfo::fromPrefab marks (it was loaded by this engine, not built by hand): the
    // prefab's own children must be exactly the marked ones. Without it the first children are taken to be the prefab's.
    bool useMarks = false;
    const PoseRest* poseRest = nullptr;  // rest values of posed fields, as in EntityJsonOptions
    PrefabBaseCache* cache = nullptr;    // the loaded prefabs (null = this call loads its own)
    // How the children added under the root are written (skipSpawned, prefabs, ...); null = the defaults.
    const EntityJsonOptions* childOptions = nullptr;
};
struct PrefabDiff {
    // false: the {prefab, differences} form cannot say how the entity differs (a child or component of the prefab removed,
    // a child added under a descendant, a descendant that no override key can name, an id changed, the prefab does not load
    // ...). `reason` says which; `entry` is empty.
    bool expressible = false;
    std::string reason;
    // The scene entry: {"id", "prefab", "name"/"tags"/"active" when they differ, "components": only the fields that differ
    // (a component the prefab lacks is written whole), "overrides": the same for the prefab's descendants keyed by id (or
    // name, or path), "children": the children added to the instance}.
    Json entry;
    // How many things differ: fields, name/tags/active values, components and children added. 0 = the entity is the
    // prefab's content (apart from its id).
    std::size_t changes = 0;
};
PrefabDiff diff_entity_with_prefab(const World& world, Entity entity, std::string_view prefabPath,
                                   const PrefabDiffOptions& opts = {});
// Creates an entity (and children) from entity JSON. Errors go to `report`. References to entities inside the JSON (its
// own children included) always resolve once the whole tree exists. With `deferMissingRefs`, a reference to an id that
// still does not exist then is a warning (not an error) and is listed in `report.deferred` so the caller can resolve it
// later, e.g. when a script spawns the knob of a slider after the slider.
Entity entity_from_json(World& world, const Json& entity, Entity parent, LoadReport& report,
                        std::string_view sourceName = "<memory>", std::string_view pointer = "", int index = -1,
                        bool deferMissingRefs = false);

// Components
// `summarizeArraysOver`: a typed array field (ArrayI32, ArrayF32, ArrayU8) with more elements than this is written as
// {"$elements": <count>} instead of its numbers (a UI that rebuilds this JSON every frame must not copy a 512 x 512
// tile map into a Json each time). The default writes every element.
Json component_to_json(const World& world, Entity e, const TypeInfo& type, bool includeDefaults = false,
                       bool includeRuntime = false, std::size_t summarizeArraysOver = SIZE_MAX);
// Adds the component if missing, then applies the partial field object.
Result<void> patch_component(World& world, Entity e, const TypeInfo& type, const Json& fields);

// Prefabs
// `overrides` is entity JSON applied over the prefab's root; its "overrides" key patches descendants (see docs/MENUS.md).
// `index` is the place among the parent's children (-1 = last).
Entity instantiate_prefab(World& world, std::string_view prefabPath, Entity parent, LoadReport& report,
                          const Json& overrides = Json::object(), int index = -1);
Json make_prefab(const World& world, Entity root);

// Schemas (generated from the TypeRegistry) — used by validation and docs.
Json scene_json_schema();
Json prefab_json_schema();

}  // namespace fa
