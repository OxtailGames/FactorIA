// Occlusion culling on the GPU with a hierarchical depth image (M75.2, docs/BIG_WORLDS_LOD.md, "Occlusion"): the pure part, the pyramid the
// CPU keeps and the test of a mesh's box against it. Private to fa_render; renderer_hiz.cpp drives it.
//
// Where the depth comes from. The depth and normal prepass of the camera (r = linear view depth in world units, a = 1 where an opaque mesh
// was drawn; mesh_common.glsl, prepass_fs), which the camera draws every frame while this culling is on. A compute pass (hiz.glsl) reduces
// it to kHizWidth x (kHizWidth / aspect) cells of two floats, (nearest, farthest) depth of the pixels under the cell, with +infinity for
// both where a pixel of the cell shows no mesh (so only a cell that is covered everywhere can hide something). The renderer reads that
// array back without waiting (a ring of staging buffers) and builds the mip chain here: each level is half the one before, `nearest` the
// minimum and `farthest` the maximum of its four children, so a coarse cell never claims more than the cells below it.
//
// What "hidden" means. The pyramid is the picture of the frame before (or older: the GPU may need a frame to answer), so the test is made
// in THAT frame's camera, `hist`, not the current one: the 8 corners of the mesh's box are projected with the old matrix, the cells they
// cover are read at the coarsest level where the footprint is about 2 x 2 cells (3 x 3 at most), and the box is hidden when its nearest
// corner is farther than the farthest depth of all those cells. Three things keep that true for the picture being drawn now:
//  1. The camera moved by `s` since the pyramid was made. The box's footprint is dilated by the parallax the move can cause between the
//     box and the nearest thing in front of it, 0.5 * width * proj00 * s * (1 / zOccluder - 1 / zBox) cells (zOccluder is the smallest
//     `nearest` in the dilated footprint, which the loop below finds by repeating the read with the new size, at most 3 times), and its
//     nearest depth must clear the occluder by `s` too. A footprint that would need more than kHizMaxDilate cells (a camera cut, a fast
//     move, a box close to the camera) is not culled: a cut draws everything for a frame.
//  2. A footprint that is not inside the old picture (its dilated rectangle crosses the border), or a corner at or behind the old near
//     plane (the camera inside the box, or the box in front of it), is not culled: the old picture knows nothing there.
//  3. A different field of view or aspect (zoom, a window resize) is a cut: nothing is culled.
// What it cannot know: an occluder that moved or was destroyed since the pyramid was made (what it hid shows one frame late, never
// wrong for longer), and a mesh that was not drawn in that frame, for any reason, does not occlude.
//
// Determinism: the result depends on the floats of the pyramid and the poses only. Perspective cameras only (an orthographic camera keeps
// the CPU culling of the Occluders): the depth of a cell is the clip w of the old matrix.
#pragma once

#include <cstddef>
#include <cstdint>
#include <vector>

#include "fa/core/math.h"

namespace fa::render {

inline constexpr int kHizWidth = 256;     // cells across (the CPU occlusion buffer's width too)
inline constexpr int kHizMinHeight = 16;  // the height is kHizWidth / aspect, clamped to this and the next
inline constexpr int kHizMaxHeight = 512;
inline constexpr float kHizNoDepth = 3.0e38f;  // the value of a cell (or a pixel) that shows no mesh
inline constexpr int kHizMaxDilate =
    12;  // cells; a box that needs more is not culled (a deterministic count, never time)
inline constexpr float kHizDepthSlack =
    1.0f / 256.0f;  // the box must clear the farthest occluder by this fraction of its depth
inline constexpr float kHizMinW =
    0.02f;  // a corner closer than this to the old camera's plane is "behind the near plane"
// How many cameras keep a pyramid (and a compute buffer), in the order their jobs are declared; the others are not culled by it.
inline constexpr int kHizMaxCameras = 8;
// The frames a pyramid stays usable without a newer one (the camera was not drawn, or the GPU did not answer): past it the camera is
// not culled until one arrives.
inline constexpr int kHizMaxAgeFrames = 8;
// The world clock counts FIXED steps (World::advance_clock), and a render frame runs 0..5 of them: a pyramid older than this many
// ticks (kHizMaxAgeFrames frames of 6 steps) was made before a scene load or a seek, whatever the project's fixedHz. A counter of 8 steps
// called every frame a jump at 60 Hz fixed with a slow render, and at 240 Hz.
inline constexpr int kHizMaxWorldTicks = kHizMaxAgeFrames * 6;

// The cells a camera of this aspect (width / height) has: kHizWidth across, kHizWidth / aspect down (16 .. 512).
void hiz_size_for(float aspect, int& width, int& height);

struct HizCell {
    float nearest = kHizNoDepth, farthest = kHizNoDepth;
};

class HizPyramid {
public:
    // Builds the chain from `cells` = width * height (nearest, farthest) pairs, row 0 = the top of the picture. False (and not ready)
    // when the size is wrong or a value is NaN.
    bool build(int width, int height, const float* cells, std::size_t floatCount);
    bool ready() const { return !levels_.empty(); }
    int levels() const { return int(levels_.size()); }
    int width(int level = 0) const { return levels_[std::size_t(level)].w; }
    int height(int level = 0) const { return levels_[std::size_t(level)].h; }
    HizCell cell(int level, int x, int y) const;
    // Grey picture of one level, width x height bytes, row 0 = the top: 0 where a cell shows no mesh, else 55..255, the nearer the
    // brighter (10 / (10 + farthest depth) mapped to it), like OcclusionBuffer::grey.
    std::vector<std::uint8_t> grey(int level) const;
    // How many cells of the base level show a mesh in every pixel (what the stats say about the pyramid).
    std::size_t covered_cells() const;

private:
    struct Level {
        int w = 0, h = 0;
        std::vector<float> data;  // 2 floats a cell
    };
    std::vector<Level> levels_;
};

// The camera of the frame a pyramid was made in (or of the frame being drawn): the matrix its picture was projected with, where it was,
// and the two numbers that say how wide its field of view is.
struct HizPose {
    Mat4 viewProj;
    Vec3 position{0, 0, 0};
    float p00 = 0, p11 = 0;  // projection(0,0) and (1,1): the field of view and the aspect
    bool valid = false;
};

// The pose of a perspective camera (proj and viewProj as the renderer's CameraInfo has them).
HizPose hiz_pose(const Mat4& proj, const Mat4& viewProj, Vec3 position);

// What a test saw, for the tests of the maths and the debug view.
struct HizTestInfo {
    int x0 = 0, y0 = 0, x1 = 0, y1 = 0;  // the cells read, inclusive, at level 0, with the dilation
    int level = 0;                       // the level the cells were read at
    int dilate = 0;                      // cells added on every side
    float boxNear = 0, occluderFar = 0;  // the nearest depth of the box and the farthest depth of the cells
    enum class Why : std::uint8_t {
        Hidden,
        Visible,
        NoPyramid,
        Cut,
        BehindNear,
        OutsideView,
        TooMuchMotion,
        NoOccluder
    } why = Why::NoPyramid;
};

// True when the box bmin..bmax of an object drawn with `model` (world space) is proven hidden in the picture `now` will draw, by the
// pyramid of `hist`. Thread-safe (reads only).
bool hiz_hidden(const HizPyramid& pyramid, const HizPose& hist, const HizPose& now, Vec3 bmin, Vec3 bmax,
                const Mat4& model, HizTestInfo* info = nullptr);

}  // namespace fa::render
