#include "occlusion.h"

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <limits>

#include "render_jobs.h"

namespace fa::render {

namespace {

constexpr float kMinW = 1.0e-6f;
constexpr int kSub = 16;  // sub-cell steps of the snapped coordinates (the edge functions are integers)
constexpr std::size_t kMaxReported = 8;

struct ClipV {
    float x, y, z, w;
};

// One triangle ready for the cells: vertices in 1/kSub cells of the guarded grid, counter-clockwise (positive area), the plane of the
// nearness, and the cells its box touches.
struct RasterTri {
    std::int32_t x[3], y[3];
    float n0, a, b;  // nearness at (ox, oy) and its change per cell along x and y
    float ox, oy;
    std::int32_t minX, maxX, minY, maxY;
};

// The faces of a box as quads of corner indices (bit 0 = x, 1 = y, 2 = z of the corner; +x, -x, +y, -y, +z, -z), counter-clockwise
// seen from outside, so every face's normal points out.
constexpr int kBoxQuads[6][4] = {{1, 3, 7, 5}, {0, 4, 6, 2}, {2, 6, 7, 3}, {0, 1, 5, 4}, {4, 5, 7, 6}, {0, 2, 3, 1}};

std::size_t triangle_count(const OccluderSource& s) { return s.mesh ? s.mesh->indices.size() / 3 : 12; }

// The i-th triangle of the source in local space. False for a triangle that names a vertex the mesh does not have.
bool local_triangle(const OccluderSource& s, std::size_t i, Vec3 out[3]) {
    if (s.mesh) {
        const std::size_t n = s.mesh->positions.size();
        for (int k = 0; k < 3; ++k) {
            const std::size_t ix = s.mesh->indices[3 * i + std::size_t(k)];
            if (ix >= n) return false;
            out[k] = s.mesh->positions[ix];
        }
        return true;
    }
    const Vec3 lo = min(s.boxMin, s.boxMax), hi = max(s.boxMin, s.boxMax);
    const int* q = kBoxQuads[i / 2];
    const int ids[3] = {q[0], q[1 + int(i % 2)], q[2 + int(i % 2)]};
    for (int k = 0; k < 3; ++k) {
        const int c = ids[k];
        out[k] = {(c & 1) ? hi.x : lo.x, (c & 2) ? hi.y : lo.y, (c & 4) ? hi.z : lo.z};
    }
    return true;
}

// Signed distance of `v` to the plane `which` of the clip volume (>= 0 inside): near, then the four sides widened by the guard ring.
float plane_distance(int which, const ClipV& v, float gx, float gy, bool z01) {
    switch (which) {
        case 0: return z01 ? v.z : v.z + v.w;
        case 1: return v.x + gx * v.w;
        case 2: return gx * v.w - v.x;
        case 3: return v.y + gy * v.w;
        default: return gy * v.w - v.y;
    }
}

// Sutherland-Hodgman against one plane. `out` holds up to n + 1 vertices.
int clip_against(int which, const ClipV* in, int n, ClipV* out, float gx, float gy, bool z01) {
    int m = 0;
    for (int i = 0; i < n; ++i) {
        const ClipV& a = in[i];
        const ClipV& b = in[(i + 1) % n];
        const float da = plane_distance(which, a, gx, gy, z01), db = plane_distance(which, b, gx, gy, z01);
        if (da >= 0.0f) out[m++] = a;
        if ((da >= 0.0f) != (db >= 0.0f)) {
            const float t = da / (da - db);
            out[m++] = {a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t, a.w + (b.w - a.w) * t};
        }
    }
    return m;
}

struct SetupCtx {
    const OcclusionCamera* cam;
    int w, h, gw, gh;
};

// The triangles of one occluder that face the camera, clipped, projected and snapped. Returns how many source triangles faced it.
std::size_t setup_occluder(const SetupCtx& sc, const OccluderSource& src, std::size_t count,
                           std::vector<RasterTri>& out) {
    const OcclusionCamera& cam = *sc.cam;
    const float gx = float(sc.gw) / float(sc.w), gy = float(sc.gh) / float(sc.h);
    const float det =
        src.model.at(0, 0) * (src.model.at(1, 1) * src.model.at(2, 2) - src.model.at(2, 1) * src.model.at(1, 2)) -
        src.model.at(1, 0) * (src.model.at(0, 1) * src.model.at(2, 2) - src.model.at(2, 1) * src.model.at(0, 2)) +
        src.model.at(2, 0) * (src.model.at(0, 1) * src.model.at(1, 2) - src.model.at(1, 1) * src.model.at(0, 2));
    const float mirror = det < 0.0f ? -1.0f : 1.0f;
    std::size_t facing = 0;
    for (std::size_t t = 0; t < count; ++t) {
        Vec3 l[3];
        if (!local_triangle(src, t, l)) continue;
        Vec3 wv[3];
        for (int k = 0; k < 3; ++k) wv[k] = (src.model * Vec4{l[k], 1.0f}).xyz();
        const Vec3 n = cross(wv[1] - wv[0], wv[2] - wv[0]) * mirror;
        const Vec3 toCamera = cam.perspective ? cam.position - wv[0] : cam.forward * -1.0f;
        if (!(dot(n, toCamera) > 0.0f)) continue;  // back-facing, edge-on, degenerate or NaN
        ++facing;
        ClipV poly[10], tmp[10];
        for (int k = 0; k < 3; ++k) {
            const Vec4 c = cam.viewProj * Vec4{wv[k], 1.0f};
            poly[k] = {c.x, c.y, c.z, c.w};
        }
        int np = 3;
        for (int plane = 0; plane < 5 && np >= 3; ++plane) {
            np = clip_against(plane, poly, np, tmp, gx, gy, cam.zeroToOne);
            std::copy(tmp, tmp + np, poly);
        }
        if (np < 3) continue;
        float sx[10], sy[10], nn[10];
        bool ok = true;
        for (int k = 0; k < np; ++k) {
            if (!(poly[k].w > kMinW)) {
                ok = false;
                break;
            }
            const float iw = 1.0f / poly[k].w;
            sx[k] = (poly[k].x * iw * 0.5f + 0.5f) * float(sc.w) + float(kOcclusionGuard);
            sy[k] = (poly[k].y * iw * 0.5f + 0.5f) * float(sc.h) + float(kOcclusionGuard);
            const float d01 = cam.zeroToOne ? poly[k].z * iw : (poly[k].z * iw + 1.0f) * 0.5f;
            nn[k] = cam.perspective ? iw : 1.0f - d01;
            if (!std::isfinite(sx[k]) || !std::isfinite(sy[k]) || !std::isfinite(nn[k])) ok = false;
        }
        if (!ok) continue;
        const float maxX = float(sc.gw) * float(kSub), maxY = float(sc.gh) * float(kSub);
        std::int32_t fx[10], fy[10];
        for (int k = 0; k < np; ++k) {
            fx[k] = std::int32_t(std::lround(std::clamp(sx[k] * float(kSub), 0.0f, maxX)));
            fy[k] = std::int32_t(std::lround(std::clamp(sy[k] * float(kSub), 0.0f, maxY)));
        }
        for (int k = 1; k + 1 < np; ++k) {
            int i0 = 0, i1 = k, i2 = k + 1;
            std::int64_t area =
                std::int64_t(fx[i1] - fx[i0]) * (fy[i2] - fy[i0]) - std::int64_t(fx[i2] - fx[i0]) * (fy[i1] - fy[i0]);
            if (area < 0) {
                std::swap(i1, i2);
                area = -area;
            }
            if (area == 0) continue;
            RasterTri rt;
            const int ids[3] = {i0, i1, i2};
            for (int v = 0; v < 3; ++v) {
                rt.x[v] = fx[ids[v]];
                rt.y[v] = fy[ids[v]];
            }
            rt.ox = float(rt.x[0]) / float(kSub);
            rt.oy = float(rt.y[0]) / float(kSub);
            const float dx1 = float(rt.x[1] - rt.x[0]) / float(kSub), dy1 = float(rt.y[1] - rt.y[0]) / float(kSub);
            const float dx2 = float(rt.x[2] - rt.x[0]) / float(kSub), dy2 = float(rt.y[2] - rt.y[0]) / float(kSub);
            const float dn1 = nn[ids[1]] - nn[ids[0]], dn2 = nn[ids[2]] - nn[ids[0]];
            const float d = dx1 * dy2 - dx2 * dy1;
            rt.n0 = nn[ids[0]];
            rt.a = (dn1 * dy2 - dn2 * dy1) / d;
            rt.b = (dn2 * dx1 - dn1 * dx2) / d;
            if (!std::isfinite(rt.a) || !std::isfinite(rt.b)) continue;
            const std::int32_t lox = std::min({rt.x[0], rt.x[1], rt.x[2]}), hix = std::max({rt.x[0], rt.x[1], rt.x[2]});
            const std::int32_t loy = std::min({rt.y[0], rt.y[1], rt.y[2]}), hiy = std::max({rt.y[0], rt.y[1], rt.y[2]});
            // A cell centre at i + 0.5 is inside the bounding box when lox <= (i + 0.5) * kSub <= hix.
            rt.minX = std::max<std::int32_t>(0, (lox - kSub / 2 + kSub - 1) / kSub);
            rt.maxX = std::min<std::int32_t>(sc.gw - 1, (hix - kSub / 2) / kSub);
            rt.minY = std::max<std::int32_t>(0, (loy - kSub / 2 + kSub - 1) / kSub);
            rt.maxY = std::min<std::int32_t>(sc.gh - 1, (hiy - kSub / 2) / kSub);
            if (rt.minX > rt.maxX || rt.minY > rt.maxY) continue;
            out.push_back(rt);
        }
    }
    return facing;
}

// Writes the cells of rows [r0, r1) that `t` covers.
void raster_rows(const RasterTri& t, int r0, int r1, int gw, float* buf) {
    bool include[3];
    std::int32_t ex[3], ey[3];
    for (int e = 0; e < 3; ++e) {
        const int j = (e + 1) % 3;
        ex[e] = t.x[j] - t.x[e];
        ey[e] = t.y[j] - t.y[e];
        include[e] = ey[e] > 0 ||
                     (ey[e] == 0 && ex[e] > 0);  // the tie break of an edge two triangles share: one of them keeps it
    }
    const float half = 0.5f * (std::fabs(t.a) + std::fabs(t.b));
    const int y0 = std::max(t.minY, r0), y1 = std::min(t.maxY, r1 - 1);
    for (int y = y0; y <= y1; ++y) {
        const std::int64_t py = std::int64_t(y) * kSub + kSub / 2;
        for (int x = t.minX; x <= t.maxX; ++x) {
            const std::int64_t px = std::int64_t(x) * kSub + kSub / 2;
            bool in = true;
            for (int e = 0; e < 3 && in; ++e) {
                const std::int64_t v = std::int64_t(ex[e]) * (py - t.y[e]) - std::int64_t(ey[e]) * (px - t.x[e]);
                in = v > 0 || (v == 0 && include[e]);
            }
            if (!in) continue;
            const float n = t.n0 + t.a * (float(x) + 0.5f - t.ox) + t.b * (float(y) + 0.5f - t.oy) - half;
            float& cell = buf[std::size_t(y) * std::size_t(gw) + std::size_t(x)];
            if (n > cell) cell = n;
        }
    }
}

}  // namespace

void occlusion_size_for(float aspect, int& width, int& height) {
    width = kOcclusionWidth;
    const float a = std::isfinite(aspect) && aspect > 0.01f ? aspect : 1.0f;
    height = std::clamp(int(std::lround(float(kOcclusionWidth) / a)), kOcclusionMinHeight, kOcclusionMaxHeight);
}

void OcclusionBuffer::reset(const OcclusionCamera& cam, int width, int height) {
    viewProj_ = cam.viewProj;
    pos_ = cam.position;
    fwd_ = cam.forward;
    perspective_ = cam.perspective;
    z01_ = cam.zeroToOne;
    w_ = std::max(width, 1);
    h_ = std::max(height, 1);
    gw_ = w_ + 2 * kOcclusionGuard;
    gh_ = h_ + 2 * kOcclusionGuard;
    buf_.assign(std::size_t(gw_) * std::size_t(gh_), kOcclusionEmpty);
    ready_ = true;
}

OcclusionRasterStats OcclusionBuffer::rasterize(const std::vector<OccluderSource>& occluders,
                                                const OcclusionLimits& limits) {
    OcclusionRasterStats st;
    if (!ready_) return st;
    // The caps first, serially and in the given order: how many triangles of each occluder go on.
    std::vector<std::size_t> counts(occluders.size(), 0);
    std::size_t budget = limits.perFrame, total = 0;
    for (std::size_t i = 0; i < occluders.size(); ++i) {
        std::size_t n = triangle_count(occluders[i]);
        if (n > limits.perOccluder) {
            n = limits.perOccluder;
            ++st.occludersCapped;
            if (st.cappedEntities.size() < kMaxReported) st.cappedEntities.push_back(occluders[i].entity);
        }
        if (n > budget) {
            n = budget;
            ++st.occludersDropped;
            if (st.droppedEntities.size() < kMaxReported) st.droppedEntities.push_back(occluders[i].entity);
        }
        budget -= n;
        counts[i] = n;
        total += n;
        if (n > 0) ++st.occluders;
    }
    st.sourceTriangles = total;
    const bool parallel = total >= kParallelOcclusionTriangles;
    std::vector<std::vector<RasterTri>> slots(occluders.size());
    std::vector<std::size_t> facing(occluders.size(), 0);
    const OcclusionCamera cam{viewProj_, pos_, fwd_, perspective_, z01_};
    const SetupCtx ctx{&cam, w_, h_, gw_, gh_};
    const rjobs::Split setup = parallel ? rjobs::split(occluders.size(), 1, 2) : rjobs::whole(occluders.size());
    rjobs::run("render.occlusion_setup", setup, [&](const jobs::Chunk& c) {
        for (std::size_t i = c.begin; i < c.end; ++i)
            if (counts[i] > 0) facing[i] = setup_occluder(ctx, occluders[i], counts[i], slots[i]);
    });
    for (std::size_t f : facing) st.frontTriangles += f;
    const std::size_t bands = std::size_t((gh_ + kOcclusionBand - 1) / kOcclusionBand);
    const rjobs::Split raster = parallel ? rjobs::split(bands, 1, 2) : rjobs::whole(bands);
    float* buf = buf_.data();
    rjobs::run("render.occlusion_raster", raster, [&](const jobs::Chunk& c) {
        for (std::size_t b = c.begin; b < c.end; ++b) {
            const int r0 = int(b) * kOcclusionBand, r1 = std::min(gh_, r0 + kOcclusionBand);
            for (const std::vector<RasterTri>& slot : slots)
                for (const RasterTri& t : slot)
                    if (t.maxY >= r0 && t.minY < r1) raster_rows(t, r0, r1, gw_, buf);
        }
    });
    for (float v : buf_)
        if (v > kOcclusionEmpty) ++st.coveredCells;
    return st;
}

bool OcclusionBuffer::hidden(Vec3 bmin, Vec3 bmax, const Mat4& model) const {
    if (!ready_) return false;
    const Mat4 m = viewProj_ * model;
    float lox = std::numeric_limits<float>::max(), hix = -lox, loy = lox, hiy = -lox, nearest = -lox;
    for (int c = 0; c < 8; ++c) {
        const Vec4 p = m * Vec4{(c & 1) ? bmax.x : bmin.x, (c & 2) ? bmax.y : bmin.y, (c & 4) ? bmax.z : bmin.z, 1.0f};
        // Behind the camera, or on the near plane's side of it: the box crosses the near plane (or holds the camera): visible.
        if (!(p.w > kMinW) || p.z < (z01_ ? 0.0f : -p.w)) return false;
        const float iw = 1.0f / p.w;
        const float sx = (p.x * iw * 0.5f + 0.5f) * float(w_) + float(kOcclusionGuard);
        const float sy = (p.y * iw * 0.5f + 0.5f) * float(h_) + float(kOcclusionGuard);
        const float d01 = z01_ ? p.z * iw : (p.z * iw + 1.0f) * 0.5f;
        const float n = perspective_ ? iw : 1.0f - d01;
        if (!std::isfinite(sx) || !std::isfinite(sy) || !std::isfinite(n)) return false;
        lox = std::min(lox, sx);
        hix = std::max(hix, sx);
        loy = std::min(loy, sy);
        hiy = std::max(hiy, sy);
        nearest = std::max(nearest, n);
    }
    // Wholly outside the picture: the frustum test's business, not ours.
    if (hix < float(kOcclusionGuard) || lox > float(w_ + kOcclusionGuard) || hiy < float(kOcclusionGuard) ||
        loy > float(h_ + kOcclusionGuard))
        return false;
    const int cx0 = std::clamp(int(std::floor(lox)), kOcclusionGuard, w_),
              cx1 = std::clamp(int(std::floor(hix)), kOcclusionGuard, w_);
    const int cy0 = std::clamp(int(std::floor(loy)), kOcclusionGuard, h_),
              cy1 = std::clamp(int(std::floor(hiy)), kOcclusionGuard, h_);
    // Every cell the box touches and the ring around them must hold an occluder nearer than the box's nearest corner (with a margin
    // for the rounding of the snapped triangle planes).
    const float need = nearest + 1.0e-5f * std::fabs(nearest) + 1.0e-7f;
    for (int y = cy0 - 1; y <= cy1 + 1; ++y) {
        const float* row = buf_.data() + std::size_t(y) * std::size_t(gw_);
        for (int x = cx0 - 1; x <= cx1 + 1; ++x)
            if (!(row[x] > need)) return false;
    }
    return true;
}

float OcclusionBuffer::nearness(int x, int y) const {
    if (!ready_ || x < 0 || y < 0 || x >= w_ || y >= h_) return kOcclusionEmpty;
    return buf_[std::size_t(y + kOcclusionGuard) * std::size_t(gw_) + std::size_t(x + kOcclusionGuard)];
}

std::vector<std::uint8_t> OcclusionBuffer::grey() const {
    std::vector<std::uint8_t> g(std::size_t(w_) * std::size_t(h_), 0);
    for (int y = 0; y < h_; ++y)
        for (int x = 0; x < w_; ++x) {
            const float n = nearness(x, y);
            if (!(n > kOcclusionEmpty)) continue;
            const float k =
                perspective_ ? 10.0f / (10.0f + (n > 1.0e-9f ? 1.0f / n : 1.0e9f)) : std::clamp(n, 0.0f, 1.0f);
            // Row 0 of the picture is the top: the grid's y grows upwards.
            g[std::size_t(h_ - 1 - y) * std::size_t(w_) + std::size_t(x)] =
                std::uint8_t(55 + int(std::lround(200.0f * k)));
        }
    return g;
}

}  // namespace fa::render
