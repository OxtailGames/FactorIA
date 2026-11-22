// The instances file of a Foliage component (components_world.h; M75.6, docs/BIG_WORLDS_TERRAIN.md "Foliage"): a small versioned
// binary that holds the position, turn, size, mesh and lean of every instance. This is the ONE writer and reader: the renderer
// reads it to draw, `foliage.scatter` and `foliage.paint` write it, tests and tools read it back.
//
// Layout (little endian, no padding), version 1:
//   header, 16 bytes: "FAFO" (4 bytes), version u16 (1), flags u16 (0: nothing is defined yet, a reader refuses any other value),
//                     count u32 (instances), meshCount u32 (how many meshes the writer's Foliage.meshes had; a mesh index of an
//                     instance is below it).
//   record, 26 bytes, `count` times: x f32, y f32, z f32 (metres, in the LOCAL space of the Foliage entity, so the instances
//                     move with it and follow the floating origin), yaw f32 (radians about the instance's own up axis), scale f32
//                     (uniform; above 0), mesh u16 (index into Foliage.meshes), nx i8, ny i8, nz i8 (the up axis of the instance
//                     in 1/127 units, a lean towards the ground's normal; 0, 0, 0 = upright), reserved u8 (0).
//   The file is exactly 16 + 26 * count bytes: a shorter one is cut off, a longer one has bytes nobody wrote.
#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/math.h"
#include "fa/core/types.h"

namespace fa {

inline constexpr std::uint16_t kFoliageVersion = 1;
inline constexpr std::size_t kFoliageHeaderBytes = 16;
inline constexpr std::size_t kFoliageRecordBytes = 26;
// One file holds at most this many instances (52 MB on disk, 72 MB decoded; the renderer's load peaks at about 170 MB while it sorts them into
// chunks, then keeps 72 MB): beyond it use several Foliage entities, which also lets the renderer cull and fade each of them on its own.
inline constexpr std::uint32_t kMaxFoliageInstances = 2000000;

struct FoliageInstance {
    Vec3 position{0, 0, 0};  // metres, in the local space of the Foliage entity
    float yaw = 0.0f;        // radians about the instance's up axis
    float scale = 1.0f;      // uniform, above 0
    std::uint16_t mesh = 0;  // index into Foliage.meshes
    Vec3 up{0, 1, 0};        // the instance's up axis (unit length): upright, or leaning to the ground's normal
};

// Bytes of a file with `count` instances.
inline std::size_t foliage_file_bytes(std::size_t count) { return kFoliageHeaderBytes + kFoliageRecordBytes * count; }

// The bytes of the file for `instances`; `meshCount` is the number of meshes of the Foliage they are for (every `mesh` must be below
// it, at most 65535). Errors (with the index of the instance, as a JSON-pointer-like path) for a non-finite number, a scale that is
// not above 0, a mesh index past meshCount or more than kMaxFoliageInstances instances.
Result<std::vector<std::uint8_t>> encode_foliage(const std::vector<FoliageInstance>& instances,
                                                 std::uint32_t meshCount);

// The instances of a file's bytes. `meshes` = Foliage.meshes.size(): an instance whose mesh index is not below it is an error. `file` is
// only used in the messages ("" = the bytes are not from a file). Every error names the byte offset, what is wrong and how to fix it:
// a truncated file, bytes after the last record, a wrong magic, a version this engine does not read, a count past the maximum, a
// non-finite number, a scale that is not above 0, a mesh index past `meshes`. Nothing is returned for a damaged file (no partial result).
Result<std::vector<FoliageInstance>> decode_foliage(const std::uint8_t* data, std::size_t size, std::size_t meshes,
                                                    std::string_view file = {});

// Reads `path` (through fa::fs: the project, a pack) and decodes it.
Result<std::vector<FoliageInstance>> read_foliage(std::string_view path, std::size_t meshes);
// Encodes and writes `path` (creates the folders; the caller checks that the path may be written, fs::check_writable).
Result<void> write_foliage(std::string_view path, const std::vector<FoliageInstance>& instances,
                           std::uint32_t meshCount);

}  // namespace fa
