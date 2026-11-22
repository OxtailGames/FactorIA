// The level of detail of a Terrain (M75-P5a, CDLOD: "Continuous Distance-Dependent Level of Detail for Rendering Heightmaps"): the CPU
// side, free of any GPU call so tests can look at it.
//
// The terrain is a quadtree of square nodes. A node of level l covers 32 * 2^l cells of the grid and is drawn as ONE shared patch of
// 33 x 33 vertices (kTerrainPatch), instanced, each instance placed over its cells; level 0 has a vertex on every sample, level l one
// on every 2^l-th. The vertex shader (shaders/terrain.glsl) reads each height from the height texture and, for the vertices of an odd
// row or column, blends it toward the height of the coarser level (the vertex "morphs") as the camera moves away, so a node that
// changes level never pops, and two neighbours of different levels share their edge exactly (no cracks): terrain_vertex_raw() is the
// same formula on the CPU, which the tests use to prove it.
//
// Everything here is in the terrain's LOCAL space (before Transform): x = -sizeX / 2 + column * cellX, z the same with the row, y =
// heightOffset + heightScale * raw / 65535.
#pragma once

#include <cstdint>
#include <functional>
#include <vector>

#include "fa/core/math.h"
#include "fa/scene/terrain.h"

namespace fa::render {

inline constexpr int kTerrainPatch = 33;                      // vertices per side of the shared patch (32 cells)
inline constexpr int kTerrainPatchCells = kTerrainTileCells;  // 32
inline constexpr int kTerrainTrianglesPerNode = kTerrainPatchCells * kTerrainPatchCells * 2;

// The shape of a terrain in local space.
struct TerrainGrid {
    int samples = 0;  // per side, 2^k + 1
    float cellX = 1.0f, cellZ = 1.0f;
    float heightScale = 1.0f, heightOffset = 0.0f;

    int cells() const { return samples - 1; }
    // Levels of the quadtree: the root node covers the whole grid.
    int levels() const;
    float x_of(float column) const { return (column - 0.5f * float(cells())) * cellX; }
    float z_of(float row) const { return (row - 0.5f * float(cells())) * cellZ; }
    float y_of(float raw) const { return heightOffset + heightScale * raw * (1.0f / kTerrainRawMax); }
};
TerrainGrid terrain_grid_of(const Terrain3D& t, int samples);

// The lowest and highest sample of every node (so its box in local space), for every level. Level 0 tiles are 32 cells; a tile at level l
// covers 32 * 2^l cells and is made from its four children.
class TerrainTileBounds {
public:
    void build(const fa::TerrainHeights& h);
    // Recomputes what changed in `rect` (samples) of the same grid.
    void update(const fa::TerrainHeights& h, fa::TerrainRect rect);
    int levels() const { return int(levelDims_.size()); }
    int tiles_per_side(int level) const { return levelDims_[std::size_t(level)]; }
    std::uint16_t min_raw(int level, int tx, int ty) const { return min_[std::size_t(level)][index(level, tx, ty)]; }
    std::uint16_t max_raw(int level, int tx, int ty) const { return max_[std::size_t(level)][index(level, tx, ty)]; }
    bool built() const { return !levelDims_.empty(); }
    int samples() const { return samples_; }

private:
    std::size_t index(int level, int tx, int ty) const {
        return std::size_t(ty) * std::size_t(levelDims_[std::size_t(level)]) + std::size_t(tx);
    }
    void recompute_tile0(const fa::TerrainHeights& h, int tx, int ty);
    void recompute_parent(int level, int tx, int ty);  // level >= 1: from its four children
    int samples_ = 0;
    std::vector<int> levelDims_;  // tiles per side of each level
    std::vector<std::vector<std::uint16_t>> min_, max_;
};

// The distances of the levels: level l is drawn from range[l - 1] to range[l] (level 0 from the camera to range[0]); its vertices morph
// toward level l + 1 between morph_start(l) and range[l].
struct TerrainLodRanges {
    std::vector<float> range;  // one per level; the last is where the root node's vertices are fully coarse
    static TerrainLodRanges make(const TerrainGrid& g, int levels, float lodQuality);
    float morph_start(int level) const;
    float morph_end(int level) const { return range[std::size_t(level)]; }
    // The morph factor 0..1 of a vertex of a node of `level` at `distance` from the camera.
    float morph(int level, float distance) const;
};

// One node of the selection.
struct TerrainNode {
    std::uint8_t level = 0;
    std::uint16_t tx = 0, ty = 0;  // tile index at its level
    std::uint16_t minRaw = 0, maxRaw = 0;
    int first_column() const { return int(tx) * (kTerrainPatchCells << level); }
    int first_row() const { return int(ty) * (kTerrainPatchCells << level); }
    int step() const { return 1 << level; }  // samples between two vertices of the patch
};

struct TerrainSelection {
    std::vector<TerrainNode> nodes;
    std::uint32_t visited = 0;  // nodes looked at (the work of the selection)
};

// The local-space box of a node.
void terrain_node_box(const TerrainGrid& g, const TerrainNode& n, Vec3& bmin, Vec3& bmax);

// Picks the nodes that draw the terrain for a camera at `cameraLocal`: from the root, a node splits into its four children while the
// camera is nearer (on the ground plane: the heights do not count) than the range of the next finer level; a node whose box `visible` rejects (the frustum test, in local space; null =
// all visible) is dropped with everything under it. The order is deterministic (depth first, row by row).
void select_terrain_nodes(const TerrainGrid& g, const TerrainTileBounds& bounds, const TerrainLodRanges& ranges,
                          Vec3 cameraLocal, const std::function<bool(Vec3, Vec3)>& visible, TerrainSelection& out);

// The height (raw sample units, fractional once morphed) of vertex (gx, gz) (0..32) of `node` for a camera at `cameraLocal`: the CPU
// twin of the vertex shader. gx and gz of a vertex of the node's edge name the same point as the neighbour's vertex there.
float terrain_vertex_raw(const fa::TerrainHeights& h, const TerrainGrid& g, const TerrainLodRanges& ranges,
                         const TerrainNode& node, int gx, int gz, Vec3 cameraLocal);
// The local position of that vertex.
Vec3 terrain_vertex_position(const fa::TerrainHeights& h, const TerrainGrid& g, const TerrainLodRanges& ranges,
                             const TerrainNode& node, int gx, int gz, Vec3 cameraLocal);

}  // namespace fa::render
