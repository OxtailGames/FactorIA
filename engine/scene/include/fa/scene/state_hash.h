// One 64-bit number for the whole simulation state of a World: the `game.state_hash` command, determinism tests
// (the same game with 0, 1 or N job threads must give the same hash every frame) and replay checks.
//
// What goes in: every alive entity in creation order (its id, its parent's id), each of its components in
// registration order with every reflected field (runtime-only fields too, unless excluded), the World's frame, time
// and random generator state. Floats go in by their bits, so the hash sees any difference, even in the last digit.
// It is FNV-1a 64: fast and the same on every platform, not a cryptographic hash.
#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/types.h"

namespace fa {

class World;

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
std::string state_hash_hex(std::uint64_t hash);  // 16 lowercase hex digits

}  // namespace fa
