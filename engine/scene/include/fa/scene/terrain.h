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

#include <array>
#include <cstdint>
#include <memory>
#include <mutex>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

#include "fa/core/image.h"
#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/components_world.h"

namespace fa {

class World;

inline constexpr int kTerrainMinSamples = 33;  // samples per side: one tile (32 cells) of the drawn grid
inline constexpr int kTerrainMaxSamples =
    4097;                                     // 16.8 million samples: 33.6 MB of heights on the CPU, 33.6 MB on the GPU
inline constexpr int kTerrainTileCells = 32;  // cells along one side of a drawn tile (one shared 33 x 33 grid patch)
inline constexpr float kTerrainRawMax = 65535.0f;  // a white sample
inline constexpr int kTerrainSplatMaps = 2;        // RGBA splat maps of a terrain: 4 layers each, 8 layers in all
inline constexpr int kTerrainMaxSplatSide = 4096;  // texels per side of a splat map (64 MB of RGBA8 each)
inline constexpr int kTerrainHoleThreshold = 128;  // a holes-image pixel of 128 (of 255) or more is a hole
inline constexpr int kTerrainMaxLayerSide = 4096;  // pixels per side of a layer texture
// The most GPU memory (with mips) the albedo textures of all layers may take, and the same for the normal maps: a limit checked from
// the file headers before any pixel is decoded (8 layers of 2048 x 2048 are 179 MB).
inline constexpr std::uint64_t kTerrainMaxLayerBytes = std::uint64_t(256) << 20;
// The undo history of one terrain keeps at most this many steps and this many bytes of before/after samples (the oldest go first;
// the newest step is always kept).
inline constexpr std::size_t kTerrainHistorySteps = 64;
inline constexpr std::size_t kTerrainHistoryBytes = std::size_t(256) << 20;

// A rectangle of samples (inclusive). c = column (x), r = row (z).
struct TerrainRect {
    int c0 = 0, r0 = 0, c1 = -1, r1 = -1;
    bool empty() const { return c1 < c0 || r1 < r0; }
    void join(const TerrainRect& o);
};

// The grids a terrain edit can change: the heights (samples x samples, 2 bytes: the raw 16-bit value), the holes mask (cells x cells,
// 1 byte: 0 or 1) and the two splat maps (their own size x size, 4 bytes: RGBA8, channel c of map m weights layer 4 * m + c).
enum class TerrainPlane : std::uint8_t { Heights, Holes, Splat0, Splat1 };

// One rectangle of one plane before and after an edit (`before` and `after` hold w x h elements, row by row, as the plane stores
// them). A TerrainStep is one undo step: the patches of one command.
struct TerrainPatch {
    TerrainPlane plane = TerrainPlane::Heights;
    int x0 = 0, y0 = 0, w = 0, h = 0;
    std::vector<std::uint8_t> before, after;
};
struct TerrainStep {
    std::string label;  // the command that made it ("terrain.sculpt")
    std::vector<TerrainPatch> patches;
    std::size_t bytes() const;
};

// One RGBA8 splat map (weights, linear: NOT sRGB), see docs/BIG_WORLDS.md "Terrain data formats".
struct TerrainSplat {
    int size = 0;                    // texels per side (0 = no such map)
    std::vector<std::uint8_t> rgba;  // size * size * 4, row 0 = the -Z edge
    std::string source;              // the project path it was loaded from or written to
    std::uint64_t version = 0;       // grows with every edit
    bool unsaved = false;            // edited since it was loaded or written
    bool valid() const { return size > 0 && rgba.size() == std::size_t(size) * std::size_t(size) * 4; }
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
    // Is cell (c, r) (the square between samples c .. c + 1 and r .. r + 1) a hole.
    bool hole(int c, int r) const {
        return !holes.empty() && holes[std::size_t(r) * std::size_t(samples - 1) + std::size_t(c)] != 0;
    }
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

    // ---- the other planes (M75.5 P5b): the holes mask and the splat maps, edited live like the heights ----
    // Holes: cells x cells bytes, row by row (row 0 = the -Z edge), 1 = the cell between samples (c, r) and (c + 1, r + 1) is a hole
    // (neither drawn nor collided). Empty = no holes. The collider follows `holesVersion`.
    std::vector<std::uint8_t> holes;
    std::string holesSource;         // the Terrain.holes path loaded from or written to ("" = none)
    std::uint64_t holesVersion = 0;  // grows with every holes edit
    std::array<TerrainSplat, kTerrainSplatMaps> splat;
    bool heightsUnsaved = false;  // edited since loaded or written (the files are written by save_terrain_files)
    bool holesUnsaved = false;
    std::string planesProblem;  // why the holes or the splat maps could not be loaded ("" = fine)

    bool any_unsaved() const { return heightsUnsaved || holesUnsaved || splat[0].unsaved || splat[1].unsaved; }
    // Applies the patches of `step` (their `after` data) and keeps the step for undo, clearing the redo list. False, changing
    // nothing, when a patch does not fit its plane (`problem` says which).
    bool apply_step(TerrainStep step, std::string* problem = nullptr);
    // Puts the `before` data of the newest step back (and keeps it for redo) / applies the newest undone step again. False when
    // there is none; `label` gets the step's label.
    bool undo(std::string* label = nullptr);
    bool redo(std::string* label = nullptr);
    std::size_t undo_depth() const { return undo_.size(); }
    std::size_t redo_depth() const { return redo_.size(); }
    std::size_t history_bytes() const { return historyBytes_; }
    // Writes one patch (its `after` or its `before` data) and marks the plane dirty. False when it does not fit.
    bool write_patch(const TerrainPatch& patch, bool useAfter);

private:
    struct Edit {
        std::uint64_t version = 0;
        TerrainRect rect;
    };
    std::vector<Edit> edits_;       // the last kEditHistory edits, oldest first
    std::uint64_t oldestKept_ = 0;  // the version before the oldest edit kept: readers at or after it can be answered
    static constexpr std::size_t kEditHistory = 64;
    std::vector<TerrainStep> undo_, redo_;  // oldest first
    std::size_t historyBytes_ = 0;
    void trim_history();
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

// ---- writing the files back ----

// The bytes of the heightmap file of `h` for `path`: a raw little-endian `.r16` when it ends in that, else a 16-bit greyscale PNG.
// Empty when the grid is empty.
std::vector<std::uint8_t> encode_terrain_heightmap(const TerrainHeights& h, std::string_view path);
// Writes the files of the planes of `terrain` that were edited since they were loaded or written: the heightmap (a 16-bit
// greyscale PNG, or a raw `.r16` when Terrain.heightmap ends in it), the holes mask (an 8-bit greyscale PNG, 255 = hole, at the
// terrain's cells x cells), and each splat map (an RGBA8 PNG). Each file is replaced atomically (fs::write_bytes). `written` gets
// the project paths. An error names the file and the fix, and the planes it did not reach stay unsaved. Nothing to write is ok.
Result<void> save_terrain_files(const World& world, Entity terrain, std::vector<std::string>* written = nullptr);
// The same for every Terrain of the world that has edits (what save_scene_file does after it writes the scene).
Result<void> save_all_terrain_files(const World& world, std::vector<std::string>* written = nullptr);

// ---- the splat weights ----

// The weight of each of the first `layerCount` layers at (u, v) in 0..1 across the terrain (u along x from the -X edge, v along z from the
// -Z edge), read from the splat planes of `h` (null: none) bilinearly as the GPU samples them, and normalised to add up to 1. Without a
// splat map, or where every channel of the layers is 0, layer 0 gets all of it. Writes `layerCount` numbers (at most kMaxTerrainLayers).
void terrain_splat_weights(const TerrainHeights* h, int layerCount, float u, float v, float* out);
// The same where the terrain is at world (x, z): the number of layers (`Terrain.layers`, at most 8) and their weights; false when the
// entity has no Terrain or the point is outside it (a hole is still painted: the layers under it are answered).
struct TerrainLayerWeights {
    int count = 0;
    float weight[kMaxTerrainLayers]{};
};
bool terrain_layer_weights(const World& world, Entity terrain, float worldX, float worldZ, TerrainLayerWeights& out);

// ---- the layer textures (Terrain.layers[i].albedo / .normal) ----

// The pictures of one kind of texture of every layer. They become one texture array on the GPU, so they must all have the same size.
struct TerrainLayerImages {
    int width = 0, height = 0;  // of every picture present
    std::vector<Image>
        images;  // one per layer; empty (Image::empty()) where the layer names none or the file cannot be read
    std::vector<std::string>
        problems;     // a file that could not be read (that layer is neutral), each with its JSON pointer
    int present = 0;  // how many pictures there are
};
// Decodes the `kind` ("albedo" or "normal") of every layer of `t`. An error (the pointer /layers/3/albedo, both sizes, the limits, what to
// do) when two pictures differ in size or the textures would take more than kTerrainMaxLayerBytes of GPU memory; a file that is missing
// or cannot be decoded is listed in `problems` and leaves its layer neutral.
Result<TerrainLayerImages> load_terrain_layer_images(const Terrain3D& t, std::string_view kind);

// ---- sampling ----

// What terrain_sample() answers at one world (x, z).
struct TerrainSample {
    float height = 0.0f;   // world y of the surface
    Vec3 normal{0, 1, 0};  // unit, world space (the normal of the triangle under the point)
};

// Height in the terrain's local metres (before Transform) at local (x, z), and the slope of the triangle there in metres per
// metre: false when the point is outside the grid or in a hole (TerrainHeights::hole: no ground there).
bool terrain_local_sample(const TerrainHeights& h, const Terrain3D& t, float localX, float localZ, float& height,
                          float& dhdx, float& dhdz);

// The surface of the Terrain on `terrain` at world (x, z), through the entity's transform (a terrain that is turned about Y and
// scaled is handled; one tilted about X or Z is sampled as if upright). False when the entity has no Terrain, its heightmap does
// not load, the point is outside it or in a hole (no ground there, so a ray, a foliage scatter and a script see through it; before holes
// existed this was true everywhere inside the grid). Exactly the height of the drawn surface at its finest level of detail and of the collider.
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
    // The entities that have an entry (loaded or not), sorted by entity.
    std::vector<Entity> entities() const;
    // Makes `heights` the heights of `e` for Terrain.heightmap == `key`, so setting that field does not load the file (a
    // command that fills a terrain that had no heightmap and has not written the file yet).
    void adopt(Entity e, const std::string& key, std::shared_ptr<TerrainHeights> heights);

private:
    mutable std::mutex mutex_;
    mutable std::unordered_map<std::uint64_t, Entry> entries_;  // by Entity::bits()
};

}  // namespace fa
