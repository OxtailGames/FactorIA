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
// Canonical JSON: nested children, only non-default fields, stable key order. The one exception is the gravity: `settings`
// always carries gravity2D and gravity3D, even at their defaults, so a reader of the file sees what the level uses.
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
struct EntityJsonOptions {
    bool includeChildren = true;
    bool includeDefaults = false;   // true = every field (useful for AI inspection)
    bool includeRuntime = false;    // include runtime-only fields (velocity mirrors, animator time...)
};
Json entity_to_json(const World& world, Entity e, const EntityJsonOptions& opts = {});
// Creates an entity (and children) from entity JSON. Errors go to `report`.
Entity entity_from_json(World& world, const Json& entity, Entity parent, LoadReport& report,
                        std::string_view sourceName = "<memory>", std::string_view pointer = "",
                        int index = -1);

// Components
Json component_to_json(const World& world, Entity e, const TypeInfo& type, bool includeDefaults = false,
                       bool includeRuntime = false);
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
