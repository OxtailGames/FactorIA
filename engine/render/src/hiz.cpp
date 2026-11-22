// The Hi-Z pyramid and the box test (hiz.h).
#include "hiz.h"

#include <algorithm>
#include <cmath>

namespace fa::render {

void hiz_size_for(float aspect, int& width, int& height) {
    width = kHizWidth;
    const float a = std::isfinite(aspect) && aspect > 0.01f ? aspect : 1.0f;
    height = std::clamp(int(std::lround(float(kHizWidth) / a)), kHizMinHeight, kHizMaxHeight);
}

bool HizPyramid::build(int width, int height, const float* cells, std::size_t floatCount) {
    levels_.clear();
    if (width < 1 || height < 1 || width > 4096 || height > 4096 || !cells ||
        floatCount != std::size_t(width) * std::size_t(height) * 2)
        return false;
    Level base;
    base.w = width;
    base.h = height;
    base.data.assign(cells, cells + floatCount);
    for (float& v : base.data)
        if (std::isnan(v)) v = kHizNoDepth;  // a value that proves nothing
    levels_.push_back(std::move(base));
    while (levels_.back().w > 1 || levels_.back().h > 1) {
        const Level& src = levels_.back();
        Level dst;
        dst.w = std::max(1, (src.w + 1) / 2);
        dst.h = std::max(1, (src.h + 1) / 2);
        dst.data.resize(std::size_t(dst.w) * std::size_t(dst.h) * 2);
        for (int y = 0; y < dst.h; ++y)
            for (int x = 0; x < dst.w; ++x) {
                float nearest = kHizNoDepth, farthest = -1.0f;
                for (int dy = 0; dy < 2; ++dy)
                    for (int dx = 0; dx < 2; ++dx) {
                        // The odd last row or column has no second child: its own cell stands for it (never a made-up value).
                        const int sx = std::min(x * 2 + dx, src.w - 1), sy = std::min(y * 2 + dy, src.h - 1);
                        const float* c = &src.data[(std::size_t(sy) * std::size_t(src.w) + std::size_t(sx)) * 2];
                        nearest = std::min(nearest, c[0]);
                        farthest = std::max(farthest, c[1]);
                    }
                float* d = &dst.data[(std::size_t(y) * std::size_t(dst.w) + std::size_t(x)) * 2];
                d[0] = nearest;
                d[1] = farthest;
            }
        levels_.push_back(std::move(dst));
    }
    return true;
}

HizCell HizPyramid::cell(int level, int x, int y) const {
    const Level& l = levels_[std::size_t(level)];
    const float* c = &l.data[(std::size_t(y) * std::size_t(l.w) + std::size_t(x)) * 2];
    return {c[0], c[1]};
}

std::vector<std::uint8_t> HizPyramid::grey(int level) const {
    std::vector<std::uint8_t> out;
    if (!ready() || level < 0 || level >= levels()) return out;
    const Level& l = levels_[std::size_t(level)];
    out.resize(std::size_t(l.w) * std::size_t(l.h));
    for (std::size_t i = 0; i < out.size(); ++i) {
        const float far = l.data[i * 2 + 1];
        out[i] = far >= kHizNoDepth * 0.5f ? 0 : std::uint8_t(55.0f + 200.0f * (10.0f / (10.0f + std::max(far, 0.0f))));
    }
    return out;
}

std::size_t HizPyramid::covered_cells() const {
    std::size_t n = 0;
    if (!ready()) return n;
    const Level& l = levels_.front();
    for (std::size_t i = 0; i < std::size_t(l.w) * std::size_t(l.h); ++i)
        n += l.data[i * 2 + 1] < kHizNoDepth * 0.5f ? 1 : 0;
    return n;
}

HizPose hiz_pose(const Mat4& proj, const Mat4& viewProj, Vec3 position) {
    HizPose p;
    p.viewProj = viewProj;
    p.position = position;
    p.p00 = std::fabs(proj.at(0, 0));
    p.p11 = std::fabs(proj.at(1, 1));
    p.valid = std::isfinite(p.p00 + p.p11) && p.p00 > 1e-6f && p.p11 > 1e-6f &&
              std::isfinite(position.x + position.y + position.z);
    return p;
}

bool hiz_hidden(const HizPyramid& pyramid, const HizPose& hist, const HizPose& now, Vec3 bmin, Vec3 bmax,
                const Mat4& model, HizTestInfo* info) {
    using Why = HizTestInfo::Why;
    HizTestInfo local;
    HizTestInfo& out = info ? *info : local;
    out = HizTestInfo{};
    auto verdict = [&](Why why) {
        out.why = why;
        return why == Why::Hidden;
    };
    if (!pyramid.ready() || !hist.valid || !now.valid) return verdict(Why::NoPyramid);
    // A different field of view or aspect is a cut: the parallax below is for a camera that only moved.
    if (std::fabs(now.p00 - hist.p00) > 1e-3f * hist.p00 || std::fabs(now.p11 - hist.p11) > 1e-3f * hist.p11)
        return verdict(Why::Cut);
    const float s = length(now.position - hist.position);
    if (!std::isfinite(s)) return verdict(Why::Cut);

    const int cw = pyramid.width(0), ch = pyramid.height(0);
    float minX = 1e30f, maxX = -1e30f, minY = 1e30f, maxY = -1e30f, zBox = 1e30f;
    for (int k = 0; k < 8; ++k) {
        const Vec3 local3{(k & 1) ? bmax.x : bmin.x, (k & 2) ? bmax.y : bmin.y, (k & 4) ? bmax.z : bmin.z};
        const Vec3 world = model.transform_point(local3);
        const Vec4 c = hist.viewProj * Vec4{world, 1.0f};
        if (!(c.w > kHizMinW)) return verdict(Why::BehindNear);  // also a NaN
        const float nx = c.x / c.w, ny = c.y / c.w;
        const float cx = (nx * 0.5f + 0.5f) * float(cw), cy = (0.5f - ny * 0.5f) * float(ch);
        if (!std::isfinite(cx + cy)) return verdict(Why::OutsideView);
        minX = std::min(minX, cx);
        maxX = std::max(maxX, cx);
        minY = std::min(minY, cy);
        maxY = std::max(maxY, cy);
        zBox = std::min(zBox, c.w);
    }
    out.boxNear = zBox;
    // Cells a point moves on the picture per unit of sideways move over its depth. At the centre of the view that is 0.5 * cells * p;
    // towards the border a point also swings with its own angle, so the bound is sqrt(p^2 + 1) (the derivative of the projection of
    // x / z at its largest on a field of view the matrix allows), which never underestimates it.
    const float kx = 0.5f * float(cw) * std::sqrt(hist.p00 * hist.p00 + 1.0f);
    const float ky = 0.5f * float(ch) * std::sqrt(hist.p11 * hist.p11 + 1.0f);
    const float k = std::max(kx, ky);
    constexpr float kPad = 0.002f;  // a hair of a cell: the matrices are floats
    const int fx0 = int(std::floor(minX - kPad)), fx1 = int(std::ceil(maxX + kPad)) - 1;
    const int fy0 = int(std::floor(minY - kPad)), fy1 = int(std::ceil(maxY + kPad)) - 1;
    if (fx1 < fx0 || fy1 < fy0 || fx0 < -cw || fy0 < -ch || fx1 > 2 * cw || fy1 > 2 * ch)
        return verdict(Why::OutsideView);

    int dilate = 0;
    float farthest = 0, nearestOccluder = kHizNoDepth;
    bool settled = false;
    for (int pass = 0; pass < 4 && !settled; ++pass) {
        const int x0 = fx0 - dilate, x1 = fx1 + dilate, y0 = fy0 - dilate, y1 = fy1 + dilate;
        if (x0 < 0 || y0 < 0 || x1 >= cw || y1 >= ch) return verdict(Why::OutsideView);
        // The coarsest level whose cells under the rectangle are at most 2 across (3 when it straddles).
        const int extent = std::max(x1 - x0 + 1, y1 - y0 + 1);
        int level = 0;
        while (level + 1 < pyramid.levels() && (extent >> level) > 2) ++level;
        out.x0 = x0;
        out.x1 = x1;
        out.y0 = y0;
        out.y1 = y1;
        out.level = level;
        out.dilate = dilate;
        farthest = 0;
        nearestOccluder = kHizNoDepth;
        for (int y = y0 >> level; y <= (y1 >> level); ++y)
            for (int x = x0 >> level; x <= (x1 >> level); ++x) {
                const HizCell c =
                    pyramid.cell(level, std::min(x, pyramid.width(level) - 1), std::min(y, pyramid.height(level) - 1));
                farthest = std::max(farthest, c.farthest);
                nearestOccluder = std::min(nearestOccluder, c.nearest);
            }
        if (farthest >= kHizNoDepth * 0.5f) return verdict(Why::NoOccluder);  // a cell shows no mesh in some pixel
        // The parallax between the box and what is in front of it, as the camera moves by s: bigger for a nearer occluder.
        // The occluder may now be s nearer than it was: its depth minus s, never closer to zero than the near-plane guard.
        const float zOcc = std::max(nearestOccluder - s, kHizMinW);
        const float shift = s > 0.0f ? k * s * std::max(0.0f, 1.0f / zOcc - 1.0f / zBox) : 0.0f;
        const int need = s > 0.0f ? int(std::ceil(std::min(shift, 1.0e6f))) : 0;
        if (need > kHizMaxDilate) return verdict(Why::TooMuchMotion);
        if (need <= dilate)
            settled = true;
        else
            dilate = need;
    }
    out.occluderFar = farthest;
    if (!settled) return verdict(Why::TooMuchMotion);
    // The box must be behind the farthest of what covers its cells, with the camera's move to spare along the view axis.
    // (The slack is for a prepass image of halves, where a depth is rounded by up to 1/2048 of itself.)
    return verdict(zBox - s > farthest * (1.0f + kHizDepthSlack) ? Why::Hidden : Why::Visible);
}

}  // namespace fa::render
