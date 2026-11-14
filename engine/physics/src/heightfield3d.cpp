// The grid behind a 3D heightfield collider: validating and copying the component's arrays (a changed sample costs what it
// touches), the per-block height bounds, and the ray walk. See heightfield3d.h.
#include "heightfield3d.h"

#include <algorithm>
#include <format>
#include <limits>

namespace fa::detail {

namespace {

constexpr int kMaxSide = 4096;  // samples per side (the range of Heightfield3D.rows / columns)

void note_cells(HeightfieldEdit& e, int r0, int r1, int c0, int c1) {
    if (e.r1 < e.r0) {
        e.r0 = r0;
        e.r1 = r1;
        e.c0 = c0;
        e.c1 = c1;
    } else {
        e.r0 = std::min(e.r0, r0);
        e.r1 = std::max(e.r1, r1);
        e.c0 = std::min(e.c0, c0);
        e.c1 = std::max(e.c1, c1);
    }
}

// Recomputes the lowest and highest sample of block (bi, bj), including the samples on its far edges (shared with the next block).
void recompute_block(HeightfieldShape& f, int bi, int bj) {
    const int r0 = bi * HeightfieldShape::kBlock, r1 = std::min(r0 + HeightfieldShape::kBlock, f.rows - 1);
    const int c0 = bj * HeightfieldShape::kBlock, c1 = std::min(c0 + HeightfieldShape::kBlock, f.cols - 1);
    float lo = std::numeric_limits<float>::infinity(), hi = -lo;
    for (int r = r0; r <= r1; ++r) {
        const float* row = f.h.data() + std::size_t(r) * std::size_t(f.cols);
        for (int c = c0; c <= c1; ++c) {
            lo = std::fmin(lo, row[c]);
            hi = std::fmax(hi, row[c]);
        }
    }
    const std::size_t b = std::size_t(bi) * std::size_t(f.bcols) + std::size_t(bj);
    f.bmin[b] = lo;
    f.bmax[b] = hi;
}

void recompute_bounds(HeightfieldShape& f) {
    float lo = std::numeric_limits<float>::infinity(), hi = -lo;
    for (std::size_t b = 0; b < f.bmin.size(); ++b) {
        lo = std::fmin(lo, f.bmin[b]);
        hi = std::fmax(hi, f.bmax[b]);
    }
    f.minH = lo;
    f.maxH = hi;
}

void mark_blocks(HeightfieldShape& f, int ra, int rb, int ca, int cb) {
    for (int bi = ra / HeightfieldShape::kBlock; bi <= rb / HeightfieldShape::kBlock; ++bi)
        for (int bj = ca / HeightfieldShape::kBlock; bj <= cb / HeightfieldShape::kBlock; ++bj) {
            const std::size_t b = std::size_t(bi) * std::size_t(f.bcols) + std::size_t(bj);
            if (f.bflag[b]) continue;
            f.bflag[b] = 1;
            f.blist.push_back(std::uint32_t(b));
        }
}

std::string sample_text(int r, int c, int cols) {
    return std::format("heights[{}] (row {}, column {})", std::size_t(r) * std::size_t(cols) + std::size_t(c), r, c);
}

}  // namespace

std::string update_heightfield(HeightfieldShape& f, const std::string& who, Heightfield3D& c, HeightfieldEdit& edit) {
    edit = HeightfieldEdit{};
    const HeightfieldShape::Source now{c.rows,        c.columns,        c.cellSize.x,   c.cellSize.y,
                                       c.heightScale, c.heightOffset,   c.heights.id(), c.heights.version(),
                                       c.holes.id(),  c.holes.version()};
    if (f.attempted && now == f.tried) return f.problem;
    f.attempted = true;
    f.tried = now;
    auto fail = [&](std::string message) -> std::string {
        f.valid = false;
        f.problem = std::move(message);
        return f.problem;
    };
    // ---- the numbers and the array lengths: wrong ones are reported with where they are and what to write
    if (c.rows < 2 || c.columns < 2 || c.rows > kMaxSide || c.columns > kMaxSide)
        return fail(std::format(
            "entity '{}': Heightfield3D.rows = {} and columns = {}: both are numbers of samples and must be between 2 "
            "(one cell) and {}. Set them to the size of the grid in `heights` (rows * columns numbers, row by row).",
            who, c.rows, c.columns, kMaxSide));
    if (!(c.cellSize.x > 0.0f) || !(c.cellSize.y > 0.0f) || !std::isfinite(c.cellSize.x) ||
        !std::isfinite(c.cellSize.y))
        return fail(std::format("entity '{}': Heightfield3D.cellSize = [{}, {}] must be two finite numbers above 0 "
                                "(meters between neighbouring "
                                "samples along x and z). Set e.g. [1, 1].",
                                who, c.cellSize.x, c.cellSize.y));
    if (!std::isfinite(c.heightScale) || !std::isfinite(c.heightOffset))
        return fail(
            std::format("entity '{}': Heightfield3D.heightScale = {} and heightOffset = {} must be finite numbers. "
                        "Set heightScale 1 and heightOffset 0 to use `heights` as meters.",
                        who, c.heightScale, c.heightOffset));
    const std::size_t rows = std::size_t(c.rows), cols = std::size_t(c.columns);
    const std::size_t samples = rows * cols, cells = (rows - 1) * (cols - 1);
    if (c.heights.size() != samples)
        return fail(
            std::format("entity '{}': Heightfield3D.heights has {} numbers but rows * columns = {} * {} = {}. "
                        "Give it exactly one number per sample, row by row (or change rows and columns to match).",
                        who, c.heights.size(), rows, cols, samples));
    if (!c.holes.empty() && c.holes.size() != cells)
        return fail(
            std::format("entity '{}': Heightfield3D.holes has {} numbers but the grid has (rows - 1) * (columns - 1) = "
                        "{} * {} = {} cells. Give it one 0 or 1 per cell, or leave it empty for no holes.",
                        who, c.holes.size(), rows - 1, cols - 1, cells));

    const float* raw = c.heights.cdata();
    const float scale = c.heightScale, offset = c.heightOffset;
    const bool sameShape = !f.h.empty() && f.built.rows == now.rows && f.built.cols == now.cols &&
                           f.built.dx == now.dx && f.built.dz == now.dz && f.built.scale == now.scale &&
                           f.built.offset == now.offset;
    auto non_finite = [&](std::size_t i) {
        return fail(
            std::format("entity '{}': Heightfield3D.{} is {}: every height must be a finite number. Set it to a "
                        "number (0 is flat ground); the field has no collider until all are numbers.",
                        who, sample_text(int(i / cols), int(i % cols), c.columns), raw[i]));
    };

    if (!sameShape) {
        // ---- first time, or another size / spacing / scale: read everything
        for (std::size_t i = 0; i < samples; ++i)
            if (!std::isfinite(raw[i] * scale + offset)) return non_finite(i);
        f.rows = c.rows;
        f.cols = c.columns;
        f.dx = c.cellSize.x;
        f.dz = c.cellSize.y;
        f.scale = scale;
        f.offset = offset;
        f.x0 = -0.5f * float(f.cols - 1) * f.dx;
        f.z0 = -0.5f * float(f.rows - 1) * f.dz;
        f.h.resize(samples);
        for (std::size_t i = 0; i < samples; ++i) f.h[i] = raw[i] * scale + offset;
        f.holes.clear();
        if (!c.holes.empty()) {
            f.holes.resize(cells);
            for (std::size_t i = 0; i < cells; ++i) f.holes[i] = c.holes.cdata()[i] != 0 ? 1 : 0;
        }
        f.brows = (f.rows - 1 + HeightfieldShape::kBlock - 1) / HeightfieldShape::kBlock;
        f.bcols = (f.cols - 1 + HeightfieldShape::kBlock - 1) / HeightfieldShape::kBlock;
        f.bmin.assign(std::size_t(f.brows) * std::size_t(f.bcols), 0.0f);
        f.bmax = f.bmin;
        f.bflag.assign(f.bmin.size(), 0);
        f.blist.clear();
        for (int bi = 0; bi < f.brows; ++bi)
            for (int bj = 0; bj < f.bcols; ++bj) recompute_block(f, bi, bj);
        recompute_bounds(f);
        edit.rebuilt = edit.changed = edit.boundsChanged = true;
        edit.r0 = 0;
        edit.r1 = f.rows - 2;
        edit.c0 = 0;
        edit.c1 = f.cols - 2;
        edit.yLo = f.minH;
        edit.yHi = f.maxH;
    } else {
        // ---- the same grid: only what the arrays say was written, and only the samples whose value differs
        std::size_t hb = 0, he = 0;
        if (f.built.hId != now.hId) {
            he = samples;
        } else if (f.built.hVer != now.hVer) {
            // What was written since the version this copy was taken from. Physics has its own last-seen version
            // (f.built), so another reader of the array can neither hide an edit from it nor lose one.
            if (c.heights.dirty_since(f.built.hVer, hb, he))
                he = std::min(he, samples);
            else
                hb = 0, he = samples;  // more writes than the array remembers: compare everything
        }
        const int icols = c.columns, irows = c.rows;
        std::size_t changedSamples = 0;
        float oldLo = std::numeric_limits<float>::infinity(), oldHi = -oldLo;
        for (std::size_t i = hb; i < he; ++i) {
            const float v = raw[i] * scale + offset;
            if (!std::isfinite(v)) return non_finite(i);
            if (v == f.h[i]) continue;
            ++changedSamples;
            const int r = int(i / cols), col = int(i % cols);
            const int ra = std::max(r - 1, 0), rb = std::min(r, irows - 2), ca = std::max(col - 1, 0),
                      cb = std::min(col, icols - 2);
            for (int rr = ra; rr <= rb; ++rr)
                for (int cc = ca; cc <= cb; ++cc) {
                    float lo, hi;
                    f.cell_range(rr, cc, lo, hi);
                    oldLo = std::fmin(oldLo, lo);
                    oldHi = std::fmax(oldHi, hi);
                }
            note_cells(edit, ra, rb, ca, cb);
        }
        const float oldMin = f.minH, oldMax = f.maxH;
        if (changedSamples > 0) {
            f.blist.clear();
            for (std::size_t i = hb; i < he; ++i) {
                const float v = raw[i] * scale + offset;
                if (v == f.h[i]) continue;
                f.h[i] = v;
                const int r = int(i / cols), col = int(i % cols);
                mark_blocks(f, std::max(r - 1, 0), std::min(r, irows - 2), std::max(col - 1, 0),
                            std::min(col, icols - 2));
            }
            for (const std::uint32_t b : f.blist) {
                recompute_block(f, int(b) / f.bcols, int(b) % f.bcols);
                f.bflag[b] = 0;
            }
            f.blist.clear();
            recompute_bounds(f);
            float newLo = std::numeric_limits<float>::infinity(), newHi = -newLo;
            for (int rr = edit.r0; rr <= edit.r1; ++rr)
                for (int cc = edit.c0; cc <= edit.c1; ++cc) {
                    float lo, hi;
                    f.cell_range(rr, cc, lo, hi);
                    newLo = std::fmin(newLo, lo);
                    newHi = std::fmax(newHi, hi);
                }
            edit.changed = true;
            edit.boundsChanged = f.minH != oldMin || f.maxH != oldMax;
            edit.yLo = std::fmin(oldLo, newLo);
            edit.yHi = std::fmax(oldHi, newHi);
        }
        // holes: the same, over the cells the array says were written
        std::size_t ob = 0, oe = 0;
        const bool holesNow = !c.holes.empty(), holesBefore = !f.holes.empty();
        if (holesNow != holesBefore || f.built.oId != now.oId) {
            oe = cells;
        } else if (f.built.oVer != now.oVer) {
            if (c.holes.dirty_since(f.built.oVer, ob, oe))
                oe = std::min(oe, cells);
            else
                ob = 0, oe = cells;
        }
        if (oe > ob) {
            const std::uint8_t* src = c.holes.cdata();
            const std::size_t ccols = cols - 1;
            if (holesNow && f.holes.empty()) f.holes.assign(cells, 0);
            bool any = false;
            for (std::size_t i = ob; i < oe; ++i) {
                const std::uint8_t before = f.holes.empty() ? 0 : f.holes[i], after = holesNow && src[i] != 0 ? 1 : 0;
                if (before == after) continue;
                const int r = int(i / ccols), col = int(i % ccols);
                float lo, hi;
                f.cell_range(r, col, lo, hi);
                edit.yLo = any || edit.changed ? std::fmin(edit.yLo, lo) : lo;
                edit.yHi = any || edit.changed ? std::fmax(edit.yHi, hi) : hi;
                note_cells(edit, r, r, col, col);
                any = true;
                f.holes[i] = after;  // (a difference means the vector is not empty here)
            }
            if (!holesNow) f.holes.clear();
            if (any) edit.changed = true;
        }
    }
    if (edit.changed) ++f.revision;
    f.built = now;
    f.valid = true;
    f.problem.clear();
    return {};
}

bool ray_triangle(Vec3 origin, Vec3 d, const Vec3 v[3], float maxT, float& t) {
    constexpr float kEps = 1e-6f;
    const Vec3 e1 = v[1] - v[0], e2 = v[2] - v[0], pv = cross(d, e2);
    const float det = dot(e1, pv);
    if (std::fabs(det) < 1e-12f) return false;
    const float invDet = 1.0f / det;
    const Vec3 tv = origin - v[0];
    const float u = dot(tv, pv) * invDet;
    if (u < -kEps || u > 1.0f + kEps) return false;
    const Vec3 qv = cross(tv, e1);
    const float w = dot(d, qv) * invDet;
    if (w < -kEps || u + w > 1.0f + kEps) return false;
    const float hit = dot(e2, qv) * invDet;
    if (hit < 0.0f || hit > maxT) return false;
    t = hit;
    return true;
}

namespace {

Vec3 triangle_normal(const Vec3 v[3], Vec3 d) {
    const Vec3 n = normalize(cross(v[1] - v[0], v[2] - v[0]));
    return dot(n, d) > 0.0f ? -n : n;
}

// The nearer hit of the two triangles of cell (r, c); false when there is none within maxT.
bool ray_cell(const HeightfieldShape& f, int r, int c, Vec3 origin, Vec3 d, float maxT, float& t, Vec3& normal) {
    bool found = false;
    for (int which = 0; which < 2; ++which) {
        Vec3 v[3];
        f.triangle(r, c, which, v);
        float hit = 0.0f;
        if (ray_triangle(origin, d, v, found ? t : maxT, hit)) {
            t = hit;
            normal = triangle_normal(v, d);
            found = true;
        }
    }
    return found;
}

}  // namespace

bool ray_heightfield_brute(const HeightfieldShape& f, Vec3 origin, Vec3 d, float maxT, float& t, Vec3& normal) {
    if (!f.valid) return false;
    bool found = false;
    float best = maxT;
    for (int r = 0; r < f.rows - 1; ++r)
        for (int c = 0; c < f.cols - 1; ++c) {
            if (f.hole(r, c)) continue;
            float hit;
            Vec3 n;
            if (ray_cell(f, r, c, origin, d, best, hit, n) && hit <= best) {
                best = hit;
                t = hit;
                normal = n;
                found = true;
            }
        }
    return found;
}

bool ray_heightfield(const HeightfieldShape& f, Vec3 origin, Vec3 d, float maxT, float& tOut, Vec3& normal) {
    if (!f.valid || !(maxT >= 0.0f)) return false;
    // The part of the ray inside the field's box.
    float t0 = 0.0f, t1 = maxT;
    const float lo[3] = {f.x0, f.minH, f.z0}, hi[3] = {f.x_end(), f.maxH, f.z_end()};
    for (int i = 0; i < 3; ++i) {
        if (std::fabs(d[i]) < 1e-12f) {
            if (origin[i] < lo[i] || origin[i] > hi[i]) return false;
            continue;
        }
        float a = (lo[i] - origin[i]) / d[i], b = (hi[i] - origin[i]) / d[i];
        if (a > b) std::swap(a, b);
        t0 = std::max(t0, a);
        t1 = std::min(t1, b);
        if (t0 > t1) return false;
    }
    // Cell walk (Amanatides and Woo) in units of cells.
    const float u0 = (origin.x - f.x0) / f.dx, v0 = (origin.z - f.z0) / f.dz;
    const float du = d.x / f.dx, dv = d.z / f.dz;
    const float tStart = t0;
    int c = int(std::floor(std::fmin(std::fmax(u0 + du * tStart, 0.0f), float(f.cols - 2))));
    int r = int(std::floor(std::fmin(std::fmax(v0 + dv * tStart, 0.0f), float(f.rows - 2))));
    const float inf = std::numeric_limits<float>::infinity();
    const int stepC = du > 0.0f ? 1 : -1, stepR = dv > 0.0f ? 1 : -1;
    float tMaxC = std::fabs(du) < 1e-12f ? inf : (float(du > 0.0f ? c + 1 : c) - u0) / du;
    float tMaxR = std::fabs(dv) < 1e-12f ? inf : (float(dv > 0.0f ? r + 1 : r) - v0) / dv;
    const float tDeltaC = std::fabs(du) < 1e-12f ? inf : 1.0f / std::fabs(du);
    const float tDeltaR = std::fabs(dv) < 1e-12f ? inf : 1.0f / std::fabs(dv);
    float tIn = tStart;
    const float slack = 1e-4f * std::max(1.0f, std::fabs(f.maxH - f.minH));
    for (int guard = f.rows + f.cols + 8; guard > 0; --guard) {
        const float tOutCell = std::min({tMaxC, tMaxR, t1});
        if (!f.hole(r, c)) {
            const float ya = origin.y + d.y * tIn, yb = origin.y + d.y * tOutCell;
            float cl, ch;
            f.cell_range(r, c, cl, ch);
            if (!(std::fmax(ya, yb) < cl - slack || std::fmin(ya, yb) > ch + slack)) {
                float hit;
                Vec3 n;
                if (ray_cell(f, r, c, origin, d, maxT, hit, n)) {
                    tOut = hit;
                    normal = n;
                    return true;
                }
            }
        }
        if (tOutCell >= t1) return false;
        if (tMaxC < tMaxR) {
            c += stepC;
            tIn = tMaxC;
            tMaxC += tDeltaC;
        } else {
            r += stepR;
            tIn = tMaxR;
            tMaxR += tDeltaR;
        }
        if (c < 0 || c > f.cols - 2 || r < 0 || r > f.rows - 2) return false;
    }
    return false;
}

}  // namespace fa::detail
