// Occlusion culling on the CPU (M75.2, docs/BIG_WORLDS_LOD.md, "Occlusion"): a small depth buffer that the Occluder entities are
// rasterised into, and the test of a mesh's box against it. Private to fa_render; Renderer::Impl::occlude_meshes drives it.
//
// What the buffer holds. kOcclusionWidth (256) cells across and 256 / aspect down (144 for a 16:9 camera, at most 512), with
// a guard ring of one cell on every side (so the buffer is 258 x 146 for 16:9). A cell holds the "nearness" of the nearest
// occluder that covers its centre: 1 / w of the clip space for a perspective camera (affine in screen space, so the interpolation
// is exact), 1 - depth for an orthographic one; bigger = nearer; kOcclusionEmpty where no occluder covers the cell. The value
// stored is the FARTHEST the occluder can be inside the cell (the plane's value at the centre minus half the cell's gradient), so
// "everything behind this value is hidden" holds over the whole cell.
//
// Why it never hides what is visible. (1) Coverage is the centre-sample rule with integer edge functions (1/16 cell snapping,
// top-left tie break): two triangles that share an edge cover every cell exactly once, so a box has no seam. (2) The test of a
// box reads the cells it touches AND one more ring around them; for a convex occluder (every box) the cells' centres then
// enclose the touched cells, so no part of the box's picture lies outside the occluder. (A mesh occluder with a crack narrower
// than a cell hides what shows through the crack: use closed, simple meshes. Likewise two neighbouring occluders with a gap
// narrower than a cell, about 1/256 of the view: overlap them or let them touch.) (3) A box that crosses the near plane, or has a
// corner behind the camera, is visible, and so is one that holds the camera. (4) Only the faces that look at the camera are
// rasterised: a camera inside an occluder sees no occlusion from it.
//
// Determinism. The triangles are set up per occluder in the given order and rasterised per band of rows of the buffer; a cell is
// the maximum over the triangles that cover it, so the result is the same with 0, 1 or 16 job threads.
#pragma once

#include <cstddef>
#include <cstdint>
#include <memory>
#include <vector>

#include "fa/core/math.h"
#include "fa/scene/mesh_geometry.h"

namespace fa::render {

inline constexpr int kOcclusionWidth = 256;     // cells across the camera's picture (without the guard ring)
inline constexpr int kOcclusionMinHeight = 16;  // the height is kOcclusionWidth / aspect, clamped to this and the next
inline constexpr int kOcclusionMaxHeight = 512;
inline constexpr int kOcclusionGuard = 1;  // cells of guard on every side
inline constexpr int kOcclusionBand = 16;  // rows of one raster job
inline constexpr float kOcclusionEmpty = -1.0e30f;

// The caps, counted in triangles of the source geometry (never time): the same scene gives the same result on every machine.
inline constexpr std::size_t kMaxOccluderTriangles = 4096;    // one Occluder: its mesh's first triangles, no more
inline constexpr std::size_t kMaxOcclusionTriangles = 65536;  // all the occluders of one camera
// From this many source triangles the setup and the raster run as jobs (a job costs more than a few hundred triangles save).
inline constexpr std::size_t kParallelOcclusionTriangles = 1024;

struct OcclusionLimits {
    std::size_t perOccluder = kMaxOccluderTriangles;
    std::size_t perFrame = kMaxOcclusionTriangles;
};

// One Occluder, ready to rasterise: a box (local corners boxMin..boxMax) or the triangles of a mesh, and the matrix that takes
// them to world space (the entity's drawn matrix; a negative determinant, a mirrored object, is handled).
struct OccluderSource {
    Mat4 model;
    Vec3 boxMin{-0.5f, -0.5f, -0.5f}, boxMax{0.5f, 0.5f, 0.5f};
    std::shared_ptr<const MeshGeometry> mesh;  // null = a box
    std::uint64_t entity = 0;                  // Entity::bits(), for the reports
};

// One triangle ready for the cells: vertices in 1/16 cells of the guarded grid, counter-clockwise (positive area), the plane of the
// nearness, and the cells its box touches. (Here only so the buffer can keep its lists from frame to frame.)
struct RasterTri {
    std::int32_t x[3], y[3];
    float n0, a, b;  // nearness at (ox, oy) and its change per cell along x and y
    float ox, oy;
    std::int32_t minX, maxX, minY, maxY;
};

// The camera as the buffer needs it. viewProj has the depth range of `zeroToOne` (0..1 or -1..1).
struct OcclusionCamera {
    Mat4 viewProj;
    Vec3 position{0, 0, 0};
    Vec3 forward{0, 0, -1};
    bool perspective = true;
    bool zeroToOne = false;
};

struct OcclusionRasterStats {
    int occluders = 0;                // rasterised (at least one triangle submitted)
    std::size_t sourceTriangles = 0;  // submitted, after the caps
    std::size_t frontTriangles = 0;   // of them facing the camera (the ones drawn)
    int occludersCapped = 0;          // occluders whose mesh was cut at the per-occluder cap
    int occludersDropped = 0;         // occluders left out whole or cut by the cap of the camera
    std::size_t coveredCells = 0;
    std::vector<std::uint64_t> cappedEntities, droppedEntities;  // who, in order (at most 8 each)
};

// The size the buffer has for a camera of this aspect (width / height), without the guard ring.
void occlusion_size_for(float aspect, int& width, int& height);

class OcclusionBuffer {
public:
    // Sizes and clears the buffer for `cam` (width x height cells: occlusion_size_for).
    void reset(const OcclusionCamera& cam, int width, int height);
    // Draws the occluders, in the order given (the caller sorts them: the caps keep the first).
    OcclusionRasterStats rasterize(const std::vector<OccluderSource>& occluders, const OcclusionLimits& limits = {});
    // True when the box bmin..bmax of an object drawn with `model` is proven hidden by the occluders. Thread-safe (reads only).
    bool hidden(Vec3 bmin, Vec3 bmax, const Mat4& model) const;

    bool ready() const { return ready_; }
    int width() const { return w_; }
    int height() const { return h_; }
    // The cell (x, y) of the picture, 0 <= x < width (the guard ring is not addressable); kOcclusionEmpty when nothing covers it.
    float nearness(int x, int y) const;
    // Grey picture of the buffer, width x height bytes, row 0 = the top of the picture: 0 where nothing covers the cell, else
    // 55..255, the nearer the brighter (a perspective camera: 10 / (10 + distance) mapped to it).
    std::vector<std::uint8_t> grey() const;

private:
    Mat4 viewProj_;
    Vec3 pos_{0, 0, 0}, fwd_{0, 0, -1};
    bool perspective_ = true, z01_ = false, ready_ = false;
    int w_ = 0, h_ = 0;    // the picture
    int gw_ = 0, gh_ = 0;  // with the guard ring
    std::vector<float> buf_;
    // Scratch of rasterize(), kept so a frame does not allocate again.
    std::vector<std::size_t> counts_, facing_;
    std::vector<std::vector<RasterTri>> slots_;
};

}  // namespace fa::render
