// One 64-bit number for the whole simulation state of a World: the `game.state_hash` command, determinism tests
// (the same game with 0, 1 or N job threads must give the same hash every frame) and replay checks.
//
// What goes in: every alive entity in creation order (its id, its parent's id), each of its components sorted by type
// name (not registration order, which depends on what code registered its components first) with every reflected
// field (runtime-only fields too, unless excluded), the World's frame, time and random generator state. Floats go in by their bits, so the hash sees any difference, even in the last digit.
// It is FNV-1a 64: fast and the same on every platform, not a cryptographic hash.
#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/types.h"

namespace fa {

class World;
struct TypeInfo;

struct StateHashOptions {
    bool includeRuntime = true;  // also hash fields that are not saved to scenes (velocities, timers, caches)
    bool perEntity = false;      // also return one hash per entity (find which entity differs)
};

struct EntityHash {
    Entity entity;
    std::string id;
    std::uint64_t hash = 0;
};

struct StateHash {
    std::uint64_t hash = 0;
    int entities = 0;
    int components = 0;
    std::vector<EntityHash> perEntity;  // filled when StateHashOptions::perEntity
};

StateHash world_state_hash(const World& world, const StateHashOptions& options = {});

// One component of an entity for entity_state_hash: its type and the object.
struct ComponentRef {
    const TypeInfo* type = nullptr;
    const void* object = nullptr;
};

// The hash of one entity, as world_state_hash computes it: `components` may come in any order (they are sorted by
// type name first). `id` and `parentId` are the entities' string ids ("" for no parent).
std::uint64_t entity_state_hash(Entity entity, const std::string& id, const std::string& parentId,
                                std::vector<ComponentRef> components, const StateHashOptions& options = {});
std::string state_hash_hex(std::uint64_t hash);  // 16 lowercase hex digits

}  // namespace fa
