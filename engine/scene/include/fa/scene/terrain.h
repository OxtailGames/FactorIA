// The CPU side of the Terrain component (components_world.h, Terrain3D; M75.5, docs/BIG_WORLDS.md "Terrain"): the heights of a
// heightmap, loaded once and shared by everything that needs them. The renderer uploads them to a texture and picks the tiles to
// draw (fa_render renderer_terrain.cpp), physics builds a heightfield collider from them (fa_physics), the sculpt commands of the
// editor write into them, and foliage scattering and scripts sample them: nobody reads the heightmap file a second time.
//
// The heights live in the World's TerrainStore (World::terrain()), GPU-free. A scene load (World::clear) releases them all.
//
// Conventions
//   * The grid has `samples` x `samples` points, samples = 2^k + 1 (33 ... 4097): 2^k cells per side, so the drawn tiles (32 cells)
//     divide it evenly. Row r is at z = -size.y / 2 + r * cell, column c at x = -size.x / 2 + c * cell, in the entity's local space
//     (the grid is centred on the entity, as Heightfield3D); the first row of the image (its top) is the -Z edge.
//   * A sample is a 16-bit integer: its height is heightOffset + heightScale * raw / 65535 metres, before Transform.scale.
//   * A cell is two triangles along the diagonal from its (r, c) corner to its (r + 1, c + 1) one: the drawn surface (at the
//     finest level of detail) and the collider are the same triangles, and terrain_sample() interpolates on them, so a height read
//     here is the height both of them have.
#pragma once

#include <cstdint>
#include <memory>
#include <mutex>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/components_world.h"

namespace fa {

class World;

inline constexpr int kTerrainMinSamples = 33;     // samples per side: one tile (32 cells) of the drawn grid
inline constexpr int kTerrainMaxSamples = 4097;   // 16.8 million samples: 33.6 MB of heights on the CPU, 33.6 MB on the GPU
inline constexpr int kTerrainTileCells = 32;      // cells along one side of a drawn tile (one shared 33 x 33 grid patch)
inline constexpr float kTerrainRawMax = 65535.0f;  // a white sample

// A rectangle of samples (inclusive). c = column (x), r = row (z).
struct TerrainRect {
    int c0 = 0, r0 = 0, c1 = -1, r1 = -1;
    bool empty() const { return c1 < c0 || r1 < r0; }
    void join(const TerrainRect& o);
};

// The samples of one terrain.
struct TerrainHeights {
    int samples = 0;                  // per side (2^k + 1)
    std::vector<std::uint16_t> data;  // samples * samples, row by row (row 0 = the -Z edge)
    bool eightBit = false;            // the file had 8 bits per sample: only 256 distinct heights
    std::string source;               // the project path it was loaded from ("" = a flat terrain)
    std::uint64_t id = 0;             // never the same for two TerrainHeights of a process (a reload is a new object)
    std::uint64_t version = 0;        // grows with every mark_dirty()

    bool valid() const { return samples >= 2 && data.size() == std::size_t(samples) * std::size_t(samples); }
    int cells() const { return samples - 1; }
    std::uint16_t at(int c, int r) const { return data[std::size_t(r) * std::size_t(samples) + std::size_t(c)]; }
    // Writes one sample (clamped to the grid; does not mark anything dirty: call mark_dirty once for the whole edit).
    void set(int c, int r, std::uint16_t v);
    // Says that the samples of `rect` (clamped to the grid) were written: bumps `version` and remembers the rectangle for
    // the readers (the GPU texture, the collider), so each updates only what changed.
    void mark_dirty(TerrainRect rect);
    // The rectangle written since `sinceVersion` (the version a reader last saw): false when the history is too short to know
    // (the reader must take everything); true with `out` empty when nothing changed.
    bool dirty_since(std::uint64_t sinceVersion, TerrainRect& out) const;
    // The whole grid of `n` x `n` samples, all set to `raw` (a flat terrain).
    static std::shared_ptr<TerrainHeights> flat(int n, std::uint16_t raw = 0);

private:
    struct Edit {
        std::uint64_t version = 0;
        TerrainRect rect;
    };
    std::vector<Edit> edits_;      // the last kEditHistory edits, oldest first
    std::uint64_t oldestKept_ = 0;  // the version before the oldest edit kept: readers at or after it can be answered
    static constexpr std::size_t kEditHistory = 64;
};

// ---- loading the heightmap file (the file layer of fa::fs: project paths and packs) ----

// What a loaded heightmap came with.
struct TerrainLoad {
    std::shared_ptr<TerrainHeights> heights;
    std::string warning;  // "" or what the author should know (an 8-bit image gives terraces)
};

// The samples per side a heightmap of `width` x `height` pixels makes: 2^k + 1 as it is, 2^k padded by one row and column that
// repeat the last. An error that names the size, the sizes that work and the budget otherwise. `what` is the file named in it.
Result<int> terrain_grid_samples(int width, int height, std::string_view what);
// Reads a 16-bit greyscale PNG (an 8-bit one, JPG... is accepted with a `warning`) or a raw little-endian `.r16` file (16-bit
// samples, square, no header; the size comes from the file size) into the heights of a terrain. The budget is checked from the
// header (or the file size) before any sample is allocated.
Result<TerrainLoad> load_terrain_heightmap(std::string_view path);
// The same from bytes already in memory (`name` is the path the errors name; ".r16" in it selects the raw format).
Result<TerrainLoad> decode_terrain_heightmap(const std::uint8_t* data, std::size_t size, std::string_view name);

// ---- sampling ----

// What terrain_sample() answers at one world (x, z).
struct TerrainSample {
    float height = 0.0f;  // world y of the surface
    Vec3 normal{0, 1, 0};  // unit, world space (the normal of the triangle under the point)
};

// Height in the terrain's local metres (before Transform) at local (x, z), and the slope of the triangle there in metres per
// metre: false when the point is outside the grid.
bool terrain_local_sample(const TerrainHeights& h, const Terrain3D& t, float localX, float localZ, float& height,
                          float& dhdx, float& dhdz);

// The surface of the Terrain on `terrain` at world (x, z), through the entity's transform (a terrain that is turned about Y and
// scaled is handled; one tilted about X or Z is sampled as if upright). False when the entity has no Terrain, its heightmap does
// not load, or the point is outside it. Exactly the height of the drawn surface at its finest level of detail and of the collider.
bool terrain_sample(const World& world, Entity terrain, float worldX, float worldZ, TerrainSample& out);
// The height only (world y); false as terrain_sample.
bool terrain_height_at(const World& world, Entity terrain, float worldX, float worldZ, float& height);

// ---- the store ----

// The heights of every Terrain of a World, by entity. Loaded the first time something asks (a missing or wrong file is reported
// once with the entity and the fix, and the terrain then draws and collides with nothing, until its `heightmap` changes).
class TerrainStore {
public:
    struct Entry {
        std::shared_ptr<TerrainHeights> heights;
        std::string key;      // the Terrain.heightmap the heights were loaded for
        std::string problem;  // why they could not be ("" = loaded)
        bool loaded = false;  // an attempt was made for `key` (heights is null when it failed)
    };
    // The heights of the Terrain on `e` (loading them first, or again when Terrain.heightmap changed); null when `e` has no
    // Terrain or the file cannot be used (`problem`, when given, says why). The pointer stays valid while the caller holds it.
    std::shared_ptr<TerrainHeights> heights(const World& world, Entity e, std::string* problem = nullptr) const;
    // The heights of `e` if they are loaded, without loading anything.
    std::shared_ptr<TerrainHeights> find(Entity e) const;
    // Forgets the entries of entities that are gone or no longer have a Terrain.
    void prune(const World& world);
    void clear();
    std::size_t size() const;

private:
    mutable std::mutex mutex_;
    mutable std::unordered_map<std::uint64_t, Entry> entries_;  // by Entity::bits()
};

}  // namespace fa
