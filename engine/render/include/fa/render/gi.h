// Realtime global illumination without ray tracing, the CPU side (M73-P5d-1; docs/design/ARCHITECTURE_PROBES.md, "Realtime GI: the data
// side"): the grid of a RealtimeGI component, where each probe's block lives in the probe atlas, which probes are captured this frame,
// how the shading finds the eight probes around a point, and the record the shading reads for a grid. No GPU here: the renderer
// (src/renderer_gi.cpp) draws into the blocks this file lays out, and the tests check every function on the CPU.
//
// The atlas of the reflection probes (probe.h) grows a BAND of probe blocks below its 1024 x 1024 square when a scene has a RealtimeGI:
// 1024 x 1156 texels in all, no texture unit more. A probe's BLOCK is 10 x 11 texels:
//
//   rows 0..9    the depth map: 8 x 8 octahedral texels with the one-texel border of probe.h (so 10 x 10), texel = (r, g) = (the mean
//                distance, the mean squared distance) of the directions the texel covers, NORMALISED: the distances are d / maxDistance
//                (clamped to 0..1), so r and g are in 0..1 and a half float holds them at any maxDistance; metres = r * maxDistance, and
//                the variance in metres squared = (g - r * r) * maxDistance * maxDistance
//   row 10       texels 0..8: the nine coefficients of the SH of the light that reaches the probe (the radiance projection of probe.h's
//                SH row, RGB; no gain applied); texel 9: (back-face fraction, 1 once the probe has been captured, 0, 0)
//
// Block b of the band is at texel (b % 102 * 10, 1024 + b / 102 * 11); 102 x 12 = 1224 blocks. A grid owns a run of blocks, probe i of the
// grid is block baseBlock + i, and i = x + nx * (y + ny * z) with x along the world X axis.
#pragma once

#include <cstdint>
#include <optional>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/render/probe.h"

namespace fa {
struct RealtimeGI;
}

namespace fa::render {

inline constexpr int kGiDepthTexels = 8;                             // interior texels per side of a probe's depth map
inline constexpr int kGiBlockW = kGiDepthTexels + 2 * kProbeBorder;  // 10
inline constexpr int kGiBlockH = kGiBlockW + 1;                      // 11: the depth map and the row of SH texels
inline constexpr int kGiShRow = kGiBlockW;                           // the block row of the SH texels
inline constexpr int kGiMetaX = kProbeShCoefficients;                // the block column of the meta texel
inline constexpr int kGiBlocksPerRow = kProbeAtlasSize / kGiBlockW;  // 102
inline constexpr int kGiBlockRows = 12;
inline constexpr int kGiMaxProbes = kGiBlocksPerRow * kGiBlockRows;  // 1224: the probes of all grids together
inline constexpr int kGiBandHeight = kGiBlockRows * kGiBlockH;       // 132
inline constexpr int kGiAtlasHeight = kProbeAtlasSize + kGiBandHeight;
inline constexpr int kGiMaxGrids = 8;         // RealtimeGI components the renderer keeps
inline constexpr int kGiMaxFrameProbes = 32;  // probes captured a frame, all grids together
inline constexpr int kGiRecordFloats = 16;    // the record of a grid: four vec4
inline constexpr int kGiRetryFrames = 30;     // frames a probe whose capture could not be drawn waits

// ---- the grid ------------------------------------------------------------------------------------------------------------------

struct GiLayout {
    Vec3 origin{};  // world position of probe (0, 0, 0)
    float spacing = 2.0f;
    int nx = 1, ny = 1, nz = 1;
    int count = 1;
    int resolution = 16;  // texels per side of a capture face
    float maxDistance = 30.0f, nearPlane = 0.1f;
    float intensity = 1.0f, bounce = 1.0f, hysteresis = 0.9f, backfaceTolerance = 0.25f;
    // The part of the layout that decides what the probes are (spacing, counts, resolution, distances, tags; NOT the origin: see
    // gi_layout_moved): when it changes every probe is captured again.
    std::uint64_t key = 0;
};
// Checks the component and lays the grid out (the box centred on `worldPosition` + offset, probes spacing apart, the grid centred in the
// box). An error names the entity, the JSON pointer of the field, what is wrong and how to fix it.
Result<GiLayout> gi_layout(const RealtimeGI& component, Vec3 worldPosition, const std::string& entityId);
// True when the grid's origin is half a spacing or more from `anchor` (the origin it was last laid out at) on any axis: the grid is laid out
// again and every probe captured again. A smaller move only carries the origin along: the probes are captured at the new place in turn.
bool gi_layout_moved(const GiLayout& grid, Vec3 anchor);
int gi_axis_count(double extent, double spacing);  // floor(extent / spacing) + 1, 1 for an extent of 0
Vec3 gi_probe_position(const GiLayout& grid, int index);

// The eight probes around `p` (trilinear: the cell that holds p, p clamped to the box), their indices and weights (they sum to 1).
// Where the grid has one layer on an axis the two probes of that axis are the same one.
struct GiNeighbours {
    int index[8]{};
    float weight[8]{};
};
GiNeighbours gi_neighbours(const GiLayout& grid, Vec3 p);

// Block b of the band: the texel of its first (top-left) texel.
struct GiTexel {
    int x = 0, y = 0;
};
GiTexel gi_block_origin(int block);
// The texel (relative to the block's origin) the depth map holds for the direction `d` from the probe: bilinear taps are at
// 1 + (e * 0.5 + 0.5) * 8 - 0.5 in texel units, e = oct_encode(d).
Vec2 gi_depth_uv(Vec3 d);

// The record the shading reads for a grid (kGiRecordFloats floats, four RGBA32F texels or vec4 uniforms):
//   [0]  origin.xyz, spacing
//   [1]  nx, ny, nz, count
//   [2]  baseBlock, blocksPerRow (102), maxDistance, intensity
//   [3]  bounce, backfaceTolerance, ready (1 when every probe has been captured once), 0
void gi_pack_record(const GiLayout& grid, int baseBlock, bool ready, float out[kGiRecordFloats]);

// ---- the blocks ----------------------------------------------------------------------------------------------------------------

// First fit over the kGiMaxProbes blocks of the band: a grid owns a run of consecutive blocks.
class GiBlockAllocator {
public:
    // The first block of the run of `count` blocks of `id` (it keeps its run while the count is the same). Nullopt: no run is free.
    std::optional<int> acquire(std::uint64_t id, int count);
    void release(std::uint64_t id);
    std::optional<int> find(std::uint64_t id) const;
    int used() const;
    void clear();

private:
    struct Run {
        std::uint64_t id = 0;
        int first = 0, count = 0;
    };
    std::vector<Run> runs_;  // by first block
};

// ---- the order ----------------------------------------------------------------------------------------------------------------

// The probes to capture now: up to `budget` of them, the ones never captured first (lowest index first), then the ones captured longest
// ago. `lastCapture[i]` is the ordinal of the last capture of probe i (a counter of the grid that grows by one a capture, so no two are
// equal; 0 = never); `retryFrame[i]` (may be empty) is a frame before which probe i is skipped. The same state gives the same list on
// every machine, and the probes take turns: a grid of n probes at b a frame is refreshed in ceil(n / b) frames.
std::vector<int> gi_pick(const std::vector<std::uint64_t>& lastCapture, const std::vector<std::uint64_t>& retryFrame,
                         std::uint64_t frame, int budget);

}  // namespace fa::render
