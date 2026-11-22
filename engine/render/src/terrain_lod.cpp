#include "terrain_lod.h"

#include <algorithm>
#include <cmath>

namespace fa::render {

namespace {

// Nodes of a terrain whose distances are made from the larger of its two cell sizes.
float node_size(const TerrainGrid& g, int level) {
    return float(kTerrainPatchCells << level) * std::max(g.cellX, g.cellZ);
}

// The distance on the ground plane (x, z) from `p` to the footprint of a box: the height of the camera and of the node play no part, so
// the diagonal of a node that two neighbours of different levels must stay within is its horizontal one, whatever the terrain's relief.
float footprint_distance(Vec3 bmin, Vec3 bmax, Vec3 p) {
    const float dx = std::max({bmin.x - p.x, 0.0f, p.x - bmax.x});
    const float dz = std::max({bmin.z - p.z, 0.0f, p.z - bmax.z});
    return std::sqrt(dx * dx + dz * dz);
}

}  // namespace

int TerrainGrid::levels() const {
    if (samples < kTerrainMinSamples) return 0;
    int tiles = std::max(cells() / kTerrainPatchCells, 1), n = 1;
    while (tiles > 1) {
        tiles >>= 1;
        ++n;
    }
    return n;
}

TerrainGrid terrain_grid_of(const Terrain3D& t, int samples) {
    TerrainGrid g;
    g.samples = samples;
    const float cells = float(std::max(samples - 1, 1));
    g.cellX = std::max(t.size.x, 0.001f) / cells;
    g.cellZ = std::max(t.size.y, 0.001f) / cells;
    g.heightScale = t.heightScale;
    g.heightOffset = t.heightOffset;
    return g;
}

// ---- the box of every node ----

void TerrainTileBounds::recompute_tile0(const fa::TerrainHeights& h, int tx, int ty) {
    std::uint16_t lo = 65535, hi = 0;
    const int c0 = tx * kTerrainPatchCells, r0 = ty * kTerrainPatchCells;
    for (int r = r0; r <= r0 + kTerrainPatchCells; ++r) {
        const std::uint16_t* row = h.data.data() + std::size_t(r) * std::size_t(h.samples);
        for (int c = c0; c <= c0 + kTerrainPatchCells; ++c) {
            lo = std::min(lo, row[c]);
            hi = std::max(hi, row[c]);
        }
    }
    min_[0][index(0, tx, ty)] = lo;
    max_[0][index(0, tx, ty)] = hi;
}

void TerrainTileBounds::recompute_parent(int level, int tx, int ty) {
    std::uint16_t lo = 65535, hi = 0;
    for (int dy = 0; dy < 2; ++dy)
        for (int dx = 0; dx < 2; ++dx) {
            lo = std::min(lo, min_raw(level - 1, tx * 2 + dx, ty * 2 + dy));
            hi = std::max(hi, max_raw(level - 1, tx * 2 + dx, ty * 2 + dy));
        }
    min_[std::size_t(level)][index(level, tx, ty)] = lo;
    max_[std::size_t(level)][index(level, tx, ty)] = hi;
}

void TerrainTileBounds::build(const fa::TerrainHeights& h) {
    levelDims_.clear();
    min_.clear();
    max_.clear();
    samples_ = 0;
    TerrainGrid g;
    g.samples = h.samples;
    if (!h.valid() || g.levels() == 0) return;
    samples_ = h.samples;
    int tiles = h.cells() / kTerrainPatchCells;
    for (int l = 0; l < g.levels(); ++l) {
        levelDims_.push_back(tiles);
        min_.emplace_back(std::size_t(tiles) * std::size_t(tiles), std::uint16_t(0));
        max_.emplace_back(std::size_t(tiles) * std::size_t(tiles), std::uint16_t(0));
        tiles = std::max(tiles / 2, 1);
    }
    for (int ty = 0; ty < levelDims_[0]; ++ty)
        for (int tx = 0; tx < levelDims_[0]; ++tx) recompute_tile0(h, tx, ty);
    for (int l = 1; l < levels(); ++l)
        for (int ty = 0; ty < levelDims_[std::size_t(l)]; ++ty)
            for (int tx = 0; tx < levelDims_[std::size_t(l)]; ++tx) recompute_parent(l, tx, ty);
}

void TerrainTileBounds::update(const fa::TerrainHeights& h, fa::TerrainRect rect) {
    if (!built() || h.samples != samples_) {
        build(h);
        return;
    }
    rect.c0 = std::max(rect.c0, 0);
    rect.r0 = std::max(rect.r0, 0);
    rect.c1 = std::min(rect.c1, samples_ - 1);
    rect.r1 = std::min(rect.r1, samples_ - 1);
    if (rect.empty()) return;
    const int tiles0 = levelDims_[0];
    // A sample on the border of two tiles belongs to both.
    int x0 = rect.c0 > 0 ? (rect.c0 - 1) / kTerrainPatchCells : 0, x1 = std::min(rect.c1 / kTerrainPatchCells, tiles0 - 1);
    int y0 = rect.r0 > 0 ? (rect.r0 - 1) / kTerrainPatchCells : 0, y1 = std::min(rect.r1 / kTerrainPatchCells, tiles0 - 1);
    for (int ty = y0; ty <= y1; ++ty)
        for (int tx = x0; tx <= x1; ++tx) recompute_tile0(h, tx, ty);
    for (int l = 1; l < levels(); ++l) {
        x0 >>= 1;
        x1 >>= 1;
        y0 >>= 1;
        y1 >>= 1;
        for (int ty = y0; ty <= y1; ++ty)
            for (int tx = x0; tx <= x1; ++tx) recompute_parent(l, tx, ty);
    }
}

// ---- ranges and morph ----

TerrainLodRanges TerrainLodRanges::make(const TerrainGrid& g, int levels, float lodQuality) {
    TerrainLodRanges r;
    const float q = std::isfinite(lodQuality) ? std::clamp(lodQuality, 0.1f, 4.0f) : 1.0f;
    const int count = std::max(levels, 1);
    // Below 1 the finest levels are not drawn at all (each halving of the quality drops one: nodes of twice the size, so half the
    // detail); from 1 up the ranges grow with the quality.
    const int skipped = q >= 1.0f ? 0 : std::clamp(int(std::lround(std::log2(1.0f / q))), 0, count - 1);
    const float qEff = q * float(1 << skipped);
    float prev = 0.0f;
    for (int l = 0; l < count; ++l) {
        if (l < skipped) {
            r.range.push_back(0.0f);
            continue;
        }
        const float s = node_size(g, l);
        // Three node sizes of the level, scaled by the quality; and never less than three node sizes more than the level below. Then
        // two neighbours in the selection are never more than one level apart, and where a node of level l + 1 meets one of level l
        // the vertices of the coarse node's shared edge have not started to morph (their distance is below its morph start: the
        // finer node's parent was within range[l], and its diagonal is 1.42 node sizes, less than half of the gap), so the finer
        // node's fully morphed edge is the coarse node's edge exactly.
        const float range = std::max(3.0f * s * qEff, prev + 3.0f * s);
        r.range.push_back(range);
        prev = range;
    }
    return r;
}

float TerrainLodRanges::morph_start(int level) const {
    const float before = level > 0 ? range[std::size_t(level - 1)] : 0.0f;
    return before + 0.5f * (range[std::size_t(level)] - before);
}

float TerrainLodRanges::morph(int level, float distance) const {
    const float a = morph_start(level), b = morph_end(level);
    if (!(b > a)) return distance >= b ? 1.0f : 0.0f;
    return std::clamp((distance - a) / (b - a), 0.0f, 1.0f);
}

// ---- selection ----

void terrain_node_box(const TerrainGrid& g, const TerrainNode& n, Vec3& bmin, Vec3& bmax) {
    const int span = kTerrainPatchCells << n.level;
    bmin = {g.x_of(float(n.first_column())), g.y_of(float(n.minRaw)), g.z_of(float(n.first_row()))};
    bmax = {g.x_of(float(n.first_column() + span)), g.y_of(float(n.maxRaw)), g.z_of(float(n.first_row() + span))};
    if (bmax.y < bmin.y) std::swap(bmin.y, bmax.y);  // a negative heightScale cannot happen (0..100000) but the box must stay valid
}

void select_terrain_nodes(const TerrainGrid& g, const TerrainTileBounds& bounds, const TerrainLodRanges& ranges, Vec3 cameraLocal,
                          const std::function<bool(Vec3, Vec3)>& visible, TerrainSelection& out) {
    out.nodes.clear();
    out.visited = 0;
    if (!bounds.built() || ranges.range.size() < std::size_t(bounds.levels())) return;
    struct Walker {
        const TerrainGrid& g;
        const TerrainTileBounds& b;
        const TerrainLodRanges& r;
        Vec3 cam;
        const std::function<bool(Vec3, Vec3)>& visible;
        TerrainSelection& out;
        void visit(int level, int tx, int ty) {
            ++out.visited;
            TerrainNode n;
            n.level = std::uint8_t(level);
            n.tx = std::uint16_t(tx);
            n.ty = std::uint16_t(ty);
            n.minRaw = b.min_raw(level, tx, ty);
            n.maxRaw = b.max_raw(level, tx, ty);
            Vec3 lo, hi;
            terrain_node_box(g, n, lo, hi);
            if (visible && !visible(lo, hi)) return;
            if (level > 0 && footprint_distance(lo, hi, cam) < r.range[std::size_t(level - 1)]) {
                for (int dy = 0; dy < 2; ++dy)
                    for (int dx = 0; dx < 2; ++dx) visit(level - 1, tx * 2 + dx, ty * 2 + dy);
                return;
            }
            out.nodes.push_back(n);
        }
    } walker{g, bounds, ranges, cameraLocal, visible, out};
    walker.visit(bounds.levels() - 1, 0, 0);
}

// ---- the vertex formula (the CPU twin of shaders/terrain.glsl) ----

namespace {
float raw_at(const fa::TerrainHeights& h, int c, int r) {
    c = std::clamp(c, 0, h.samples - 1);
    r = std::clamp(r, 0, h.samples - 1);
    return float(h.data[std::size_t(r) * std::size_t(h.samples) + std::size_t(c)]);
}
}  // namespace

float terrain_vertex_raw(const fa::TerrainHeights& h, const TerrainGrid& g, const TerrainLodRanges& ranges, const TerrainNode& node,
                         int gx, int gz, Vec3 cameraLocal) {
    const int st = node.step();
    const int c = node.first_column() + gx * st, r = node.first_row() + gz * st;
    const float fine = raw_at(h, c, r);
    const bool oddX = (gx & 1) != 0, oddZ = (gz & 1) != 0;
    if (!oddX && !oddZ) return fine;
    float coarse;
    if (oddX && oddZ)  // the middle of a coarse cell: on its diagonal (r, c) - (r + 1, c + 1), as the triangles of the grid
        coarse = 0.5f * (raw_at(h, c - st, r - st) + raw_at(h, c + st, r + st));
    else if (oddX)
        coarse = 0.5f * (raw_at(h, c - st, r) + raw_at(h, c + st, r));
    else
        coarse = 0.5f * (raw_at(h, c, r - st) + raw_at(h, c, r + st));
    const float dx = g.x_of(float(c)) - cameraLocal.x, dz = g.z_of(float(r)) - cameraLocal.z;
    const float m = ranges.morph(int(node.level), std::sqrt(dx * dx + dz * dz));
    return fine + (coarse - fine) * m;
}

Vec3 terrain_vertex_position(const fa::TerrainHeights& h, const TerrainGrid& g, const TerrainLodRanges& ranges,
                             const TerrainNode& node, int gx, int gz, Vec3 cameraLocal) {
    const int st = node.step();
    const int c = node.first_column() + gx * st, r = node.first_row() + gz * st;
    return {g.x_of(float(c)), g.y_of(terrain_vertex_raw(h, g, ranges, node, gx, gz, cameraLocal)), g.z_of(float(r))};
}

}  // namespace fa::render
