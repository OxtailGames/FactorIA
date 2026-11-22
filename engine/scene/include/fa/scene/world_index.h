// The index of a streamed world (docs/BIG_WORLDS_STREAMING.md, "Streaming"): `<name>.world.json`, the list of the cells of a big world, each
// one a scene file that the engine loads and unloads around the StreamingAnchor entities (engine/runtime world_streamer.h).
//
//   {
//     "format": "factoria.world/1",
//     "version": 1,
//     "dimension": "3d",              // "3d": the cells are laid out on the XZ plane; "2d": on the XY plane
//     "cellSize": 128,                // metres (units of the world) along each side of a cell
//     "origin": [0, 0],               // where cell [0, 0] starts on the plane (absolute: world origin + local position)
//     "cells": [
//       { "coord": [0, 0], "scene": "cells/0_0.scene.json",
//         "bounds": { "min": [0, 0, 0], "max": [128, 20, 128] },   // what the cell's entities cover (3 numbers in 3d, 2 in 2d)
//         "sizeBytes": 18234 }                                      // optional: a hint for the debug view
//     ]
//   }
//
// Cell [i, j] covers [origin + (i, j) * cellSize, origin + (i + 1, j + 1) * cellSize) on the plane. The bounds of a cell must lie inside
// it. Distances to a cell (what StreamingAnchor.loadRadius measures) are taken to its bounds, on the plane only: the height of an
// anchor never matters. Positions and bounds are absolute: with a floating origin the world origin is added to the local position
// before the comparison, so shifting the origin never changes which cells are loaded.
#pragma once

#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"

namespace fa {

inline constexpr const char* kWorldIndexFormat = "factoria.world/1";
inline constexpr std::int64_t kMaxWorldCells = 262144;   // cells in one index (512 x 512)
inline constexpr std::int64_t kMaxWorldCoord = 1000000;  // |i| and |j| of a cell coordinate
inline constexpr double kMaxWorldCellSize = 1.0e6;       // metres
inline constexpr double kMinWorldCellSize = 0.5;         // metres

enum class WorldDimension : std::int32_t { D3, D2 };

struct WorldCell {
    std::int32_t
        i = 0,
        j = 0;  // the coordinate: i along the first axis of the plane (x), j along the second (z in 3d, y in 2d)
    std::string scene;              // project-relative scene file
    Vec3 boundsMin{}, boundsMax{};  // 3d: [x, y, z]; 2d: [x, y] with z 0. Absolute.
    std::int64_t sizeBytes = -1;    // -1 = not given
    std::string id() const { return std::to_string(i) + "," + std::to_string(j); }  // "3,-2"
};

struct WorldIndex {
    std::string path;  // where it was read from ("" for one built in memory)
    std::int32_t version = 1;
    WorldDimension dimension = WorldDimension::D3;
    double cellSize = 128.0;
    double originA = 0.0, originB = 0.0;  // the corner of cell [0, 0] on the plane
    std::vector<WorldCell> cells;         // sorted by (j, i): the order every list and every tie-break uses
    // The cell with this coordinate, or null.
    const WorldCell* find(std::int32_t i, std::int32_t j) const;
    // The distance (on the plane) from the point (a, b) to the bounds of `cell`: 0 inside them.
    double distance_to(const WorldCell& cell, double a, double b) const;
    // The coordinate of the cell the plane point (a, b) is in (it may have no entry in the index).
    void cell_of(double a, double b, std::int64_t& i, std::int64_t& j) const;
};

// One thing wrong in an index: a JSON pointer ("/cells/3/bounds/max"), what is wrong and how to fix it.
struct WorldIndexIssue {
    bool error = true;  // false: a warning (the index still works)
    std::string pointer;
    std::string message;
    std::string hint;
};

struct WorldIndexOptions {
    bool checkFiles = true;  // every scene file exists (through fa::fs; the paths are project-relative)
    std::int64_t maxFileChecks =
        -1;  // with more cells than this the files are not checked (a warning says so); -1 = always check
};

// Checks and reads an index. `issues` (may be null) gets every problem found, errors and warnings. The result is an error when there
// is at least one error: its message lists them (at most 8, then "and N more"), its hint is the first one's. Teaches: the pointer of
// each problem, the duplicate coordinates with both places, the missing files with "did you mean" against the files that exist, the
// bounds that stick out of their cell.
Result<WorldIndex> parse_world_index(const Json& json, std::string_view source, const WorldIndexOptions& options = {},
                                     std::vector<WorldIndexIssue>* issues = nullptr);
// Reads `path` through fa::fs (project-relative) and parses it.
Result<WorldIndex> load_world_index(std::string_view path, const WorldIndexOptions& options = {},
                                    std::vector<WorldIndexIssue>* issues = nullptr);
// The JSON of an index (the canonical key order), for the tools that write one.
Json world_index_to_json(const WorldIndex& index);

}  // namespace fa
