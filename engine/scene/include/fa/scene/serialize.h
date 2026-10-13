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
// Loading is LENIENT and EXPLAINS itself: unknown components/fields and bad
// values produce messages with a JSON pointer and a "did you mean" hint;
// bad entries are skipped and everything else still loads.
#pragma once

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

struct LoadReport {
    std::vector<LoadMessage> messages;
    std::vector<Entity> created;  // all entities created, in order
    bool ok() const;              // no Error-severity messages
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
// Canonical JSON: nested children, only non-default fields, stable key order.
Json save_scene(const World& world);
// Writes the scene with the reviewable layout of dump_scene_json (below).
Result<void> save_scene_file(const World& world, std::string_view path);

// Text of a scene or prefab document as written to disk: 2-space indent, with the short arrays of scalars on one line
// (vectors, colors, rects, tags, solidTiles; long ones wrap at about 100 columns) and a Tilemap's flat `tiles` array
// written one map row per line (`width` numbers per line, columns aligned, row 0 first), so the file shows the shape of
// the map. It is standard JSON: load_scene reads it like any other layout.
// Use it (or save_scene_json_file) for every scene and prefab file the engine writes.
std::string dump_scene_json(const Json& sceneOrPrefab);
Result<void> save_scene_json_file(std::string_view path, const Json& sceneOrPrefab);

// Entities
struct EntityJsonOptions {
    bool includeChildren = true;
    bool includeDefaults = false;   // true = every field (useful for AI inspection)
    bool includeRuntime = false;    // include runtime-only fields (velocity mirrors, animator time...)
};
Json entity_to_json(const World& world, Entity e, const EntityJsonOptions& opts = {});
// Creates an entity (and children) from entity JSON. Errors go to `report`.
Entity entity_from_json(World& world, const Json& entity, Entity parent, LoadReport& report,
                        std::string_view sourceName = "<memory>", std::string_view pointer = "");

// Components
Json component_to_json(const World& world, Entity e, const TypeInfo& type, bool includeDefaults = false,
                       bool includeRuntime = false);
// Adds the component if missing, then applies the partial field object.
Result<void> patch_component(World& world, Entity e, const TypeInfo& type, const Json& fields);

// Prefabs
Entity instantiate_prefab(World& world, std::string_view prefabPath, Entity parent, LoadReport& report,
                          const Json& overrides = Json::object());
Json make_prefab(const World& world, Entity root);

// Schemas (generated from the TypeRegistry) — used by validation and docs.
Json scene_json_schema();
Json prefab_json_schema();

}  // namespace fa
