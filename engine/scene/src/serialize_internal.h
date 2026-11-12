// What serialize.cpp and prefab_instance.cpp share. Not a public header.
#pragma once

#include "fa/scene/serialize.h"

namespace fa::detail {

// One field as JSON: an Entity field is the target's id (null for an empty or dead target), anything else field_to_json.
Json field_json(const World& world, const FieldInfo& field, const void* object);
// Puts the rest value of every posed field of component `type` of `e` in `component` (see PoseRest).
void apply_pose_rest_values(const PoseRest& pose, Entity e, const TypeInfo& type, bool includeDefaults, Json& component);
// True when `e` was spawned by a script and opts.skipSpawned asks to leave it out; records it in opts.skipped.
bool skip_spawned_entity(const World& world, Entity e, const EntityJsonOptions& opts);
// The node of a prefab's entity JSON that a key of a scene entry's "overrides" names (an id, a name or a path like
// "Panel/Title"); null when no node matches. The same lookup the loader uses.
Json* find_override_target(Json& prefabEntity, const std::string& key);

}  // namespace fa::detail
