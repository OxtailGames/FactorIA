// Private: the grid behind a 3D heightfield collider (Collider3D shape "heightfield" + Heightfield3D).
//
// The shape keeps its own copy of the heights (already scaled: model y = raw * heightScale + heightOffset) so the solver and
// the queries never read the component, which gameplay may be writing. update_heightfield() brings the copy in line with the
// component: a typed array that did not change costs two integer compares, one that changed is read only where its dirty
// range says (fa/core/typed_array.h) and only the samples whose value differs are copied, so a brush stroke costs what it
// touches. Blocks of kBlock x kBlock cells keep the min and max height, which gives the field's bounds incrementally and lets
// a body or a ray skip whole blocks.
//
// Model space: sample (row r, column c) is at x = x0 + c * dx, z = z0 + r * dz, y = h[r * cols + c], with the grid centred
// on the model origin. Cell (r, c) is two triangles, both facing up:
//     T0 = (r, c), (r + 1, c), (r + 1, c + 1)        T1 = (r, c), (r + 1, c + 1), (r, c + 1)
// (they share the diagonal from sample (r, c) to (r + 1, c + 1)). A hole cell has neither.
#pragma once

#include <cmath>
#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/math.h"
#include "fa/scene/components.h"

namespace fa::detail {

struct HeightfieldEdit {
    bool rebuilt = false;        // the whole grid was read again (first time, a changed size or array object)
    bool changed = false;        // some height or hole differs from before
    bool boundsChanged = false;  // the lowest or highest height of the field differs from before
    // What changed, in cells (inclusive; empty when r1 < r0) and the heights it spans in the model's y, old and new values
    // both (a body resting on the old surface or standing on the new one overlaps this box).
    int r0 = 0, r1 = -1, c0 = 0, c1 = -1;
    float yLo = 0.0f, yHi = 0.0f;
};

struct HeightfieldShape {
    static constexpr int kBlock = 16;  // cells per block side

    bool valid = false;  // the copy below is a usable field
    std::string problem;  // why not ("" = valid): the answer of the last attempt, reused while the component is unchanged
    int rows = 0, cols = 0;
    float dx = 1.0f, dz = 1.0f, scale = 1.0f, offset = 0.0f;
    float x0 = 0.0f, z0 = 0.0f;  // model x and z of sample (0, 0)
    std::vector<float> h;        // rows * cols, model y
    std::vector<std::uint8_t> holes;  // (rows - 1) * (cols - 1) or empty: 1 = no collision
    int brows = 0, bcols = 0;    // blocks
    std::vector<float> bmin, bmax;
    std::vector<std::uint8_t> bflag;   // scratch of update_heightfield: blocks to recompute
    std::vector<std::uint32_t> blist;  // the same, as a list
    float minH = 0.0f, maxH = 0.0f;
    std::uint64_t revision = 0;  // grows with every change (signatures of what was baked from the field)

    // What the arrays and numbers were when the copy was last brought in line (or the last attempt failed).
    struct Source {
        std::int32_t rows = 0, cols = 0;
        float dx = 0.0f, dz = 0.0f, scale = 0.0f, offset = 0.0f;
        std::uint64_t hId = 0, hVer = 0, oId = 0, oVer = 0;
        bool operator==(const Source&) const = default;
    };
    Source built, tried;
    bool attempted = false;

    int cell_rows() const { return rows - 1; }
    int cell_cols() const { return cols - 1; }
    float height(int r, int c) const { return h[std::size_t(r) * std::size_t(cols) + std::size_t(c)]; }
    bool hole(int r, int c) const {
        return !holes.empty() && holes[std::size_t(r) * std::size_t(cols - 1) + std::size_t(c)] != 0;
    }
    Vec3 vertex(int r, int c) const { return {x0 + float(c) * dx, height(r, c), z0 + float(r) * dz}; }
    float x_end() const { return x0 + float(cols - 1) * dx; }
    float z_end() const { return z0 + float(rows - 1) * dz; }
    std::size_t triangles() const { return std::size_t(rows - 1) * std::size_t(cols - 1) * 2; }
    // The corners of triangle `which` (0 or 1) of cell (r, c), in model space.
    void triangle(int r, int c, int which, Vec3 out[3]) const {
        const Vec3 a = vertex(r, c), d = vertex(r + 1, c + 1);
        if (which == 0) {
            out[0] = a;
            out[1] = vertex(r + 1, c);
            out[2] = d;
        } else {
            out[0] = a;
            out[1] = d;
            out[2] = vertex(r, c + 1);
        }
    }
    // The grid index (r * cols + c) of corner k of that triangle.
    void triangle_samples(int r, int c, int which, int out[3][2]) const {
        const int a[2] = {r, c}, d[2] = {r + 1, c + 1};
        const int other[2] = {which == 0 ? r + 1 : r, which == 0 ? c : c + 1};
        for (int i = 0; i < 2; ++i) {
            out[0][i] = a[i];
            out[1][i] = which == 0 ? other[i] : d[i];
            out[2][i] = which == 0 ? d[i] : other[i];
        }
    }
    // Lowest and highest of the four samples of a cell.
    void cell_range(int r, int c, float& lo, float& hi) const {
        const float a = height(r, c), b = height(r, c + 1), d = height(r + 1, c), e = height(r + 1, c + 1);
        lo = std::fmin(std::fmin(a, b), std::fmin(d, e));
        hi = std::fmax(std::fmax(a, b), std::fmax(d, e));
    }

    // Calls fn(r, c) for every solid cell whose x and z lie within [lo, hi] (model space) and whose heights reach into
    // [lo.y, hi.y], in a fixed order (block by block, row by row).
    template <class Fn>
    void for_cells(Vec3 lo, Vec3 hi, Fn&& fn) const {
        if (!valid) return;
        const float fx0 = (lo.x - x0) / dx, fx1 = (hi.x - x0) / dx, fz0 = (lo.z - z0) / dz, fz1 = (hi.z - z0) / dz;
        if (!(fx1 >= 0.0f && fx0 <= float(cols - 1) && fz1 >= 0.0f && fz0 <= float(rows - 1) && hi.y >= minH &&
              lo.y <= maxH))
            return;
        auto clampi = [](float v, int top) { return int(std::floor(std::fmin(std::fmax(v, 0.0f), float(top)))); };
        const int c0 = clampi(fx0, cols - 2), c1 = clampi(fx1, cols - 2);
        const int r0 = clampi(fz0, rows - 2), r1 = clampi(fz1, rows - 2);
        for (int bi = r0 / kBlock; bi <= r1 / kBlock; ++bi) {
            for (int bj = c0 / kBlock; bj <= c1 / kBlock; ++bj) {
                const std::size_t b = std::size_t(bi) * std::size_t(bcols) + std::size_t(bj);
                if (bmax[b] < lo.y || bmin[b] > hi.y) continue;
                const int ra = std::max(r0, bi * kBlock), rb = std::min(r1, bi * kBlock + kBlock - 1);
                const int ca = std::max(c0, bj * kBlock), cb = std::min(c1, bj * kBlock + kBlock - 1);
                for (int r = ra; r <= rb; ++r)
                    for (int c = ca; c <= cb; ++c) {
                        if (hole(r, c)) continue;
                        float cl, ch;
                        cell_range(r, c, cl, ch);
                        if (ch < lo.y || cl > hi.y) continue;
                        fn(r, c);
                    }
            }
        }
    }
};

// Brings `f` in line with the component and reports what changed in `edit`. Returns "" or why the component cannot be used
// (the message names the entity `who`, the field and the fix); the same message is returned again, without scanning the
// arrays, until the component changes. On an error `f` keeps its last good contents but is not valid.
std::string update_heightfield(HeightfieldShape& f, const std::string& who, Heightfield3D& c, HeightfieldEdit& edit);

// First hit of the ray origin + d * t, 0 <= t <= maxT, with the triangles (both sides), in model space. `d` need not be unit:
// t is in its units. The normal is the triangle's, facing the ray origin. The grid is walked cell by cell along the ray
// (a 3D DDA), so the cost follows the length of the ray, not the size of the field.
bool ray_heightfield(const HeightfieldShape& f, Vec3 origin, Vec3 d, float maxT, float& t, Vec3& normal);

// The same answer found the slow way, by testing every triangle (tests compare the two).
bool ray_heightfield_brute(const HeightfieldShape& f, Vec3 origin, Vec3 d, float maxT, float& t, Vec3& normal);

// One triangle of the field against a ray (both sides): t in [0, maxT] of the hit.
bool ray_triangle(Vec3 origin, Vec3 d, const Vec3 v[3], float maxT, float& t);

}  // namespace fa::detail
