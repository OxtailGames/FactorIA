// Measuring the uvs a mesh has: texel density, stretch, seams, mirrored triangles, and (for an atlas) how full the texture is and whether
// triangles lie on top of each other. All in doubles and in the triangles' order, so the numbers are the same on every platform.
#include <algorithm>
#include <cmath>
#include <format>
#include <map>

#include "model_uv_internal.h"

namespace fa::uv {

namespace {

struct TriMetrics {
    double area3 = 0;     // m^2
    double areaUv = 0;    // uv units^2, unsigned
    double signedUv = 0;  // twice the signed area
    double density = 0;   // texels per metre
    double stretch = 1;   // sigma max / sigma min
    bool valid = false;   // the triangle has area in space
    bool flat = false;    // ... but none in the texture
};

TriMetrics measure_triangle(const Vec3 (&p)[3], const Vec2 (&t)[3], double textureSize) {
    TriMetrics m;
    const double q1x = double(p[1].x) - double(p[0].x), q1y = double(p[1].y) - double(p[0].y), q1z = double(p[1].z) - double(p[0].z);
    const double q2x = double(p[2].x) - double(p[0].x), q2y = double(p[2].y) - double(p[0].y), q2z = double(p[2].z) - double(p[0].z);
    const double cx = q1y * q2z - q1z * q2y, cy = q1z * q2x - q1x * q2z, cz = q1x * q2y - q1y * q2x;
    m.area3 = 0.5 * std::sqrt(cx * cx + cy * cy + cz * cz);
    if (m.area3 < 1e-12) return m;
    m.valid = true;
    const double s1x = double(t[1].x) - double(t[0].x), s1y = double(t[1].y) - double(t[0].y);
    const double s2x = double(t[2].x) - double(t[0].x), s2y = double(t[2].y) - double(t[0].y);
    const double det = s1x * s2y - s2x * s1y;
    m.signedUv = det;
    m.areaUv = 0.5 * std::fabs(det);
    m.density = std::sqrt(m.areaUv / m.area3) * textureSize;
    if (m.areaUv < 1e-18) {
        m.flat = true;
        m.stretch = 1e6;
        return m;
    }
    // Sander et al.: the derivatives of the position by u and by v
    const double sux = (q1x * s2y - q2x * s1y) / det, suy = (q1y * s2y - q2y * s1y) / det, suz = (q1z * s2y - q2z * s1y) / det;
    const double svx = (q2x * s1x - q1x * s2x) / det, svy = (q2y * s1x - q1y * s2x) / det, svz = (q2z * s1x - q1z * s2x) / det;
    const double a = sux * sux + suy * suy + suz * suz, b = sux * svx + suy * svy + suz * svz, c = svx * svx + svy * svy + svz * svz;
    const double root = std::sqrt((a - c) * (a - c) + 4 * b * b);
    const double big = 0.5 * ((a + c) + root), small = 0.5 * ((a + c) - root);
    m.stretch = small > 1e-30 ? std::sqrt(big / small) : 1e6;
    if (m.stretch > 1e6) m.stretch = 1e6;
    return m;
}

// Counts how many triangles cover each texel centre of an R x R grid (top-left fill rule: a centre on a shared edge belongs to one side).
void rasterize(std::vector<std::uint16_t>& grid, int R, const Vec2 (&t)[3]) {
    double x[3], y[3];
    for (int k = 0; k < 3; ++k) {
        x[k] = double(t[k].x) * R;
        y[k] = double(t[k].y) * R;
    }
    double area = (x[1] - x[0]) * (y[2] - y[0]) - (x[2] - x[0]) * (y[1] - y[0]);
    if (area == 0) return;
    if (area < 0) {
        std::swap(x[1], x[2]);
        std::swap(y[1], y[2]);
    }
    const int x0 = std::max(0, int(std::floor(std::min({x[0], x[1], x[2]}) - 0.5))), x1 = std::min(R - 1, int(std::ceil(std::max({x[0], x[1], x[2]}) - 0.5)));
    const int y0 = std::max(0, int(std::floor(std::min({y[0], y[1], y[2]}) - 0.5))), y1 = std::min(R - 1, int(std::ceil(std::max({y[0], y[1], y[2]}) - 0.5)));
    for (int j = y0; j <= y1; ++j)
        for (int i = x0; i <= x1; ++i) {
            const double px = i + 0.5, py = j + 0.5;
            bool inside = true;
            for (int k = 0; k < 3 && inside; ++k) {
                const int n = (k + 1) % 3;
                const double dx = x[n] - x[k], dy = y[n] - y[k];
                const double e = dx * (py - y[k]) - dy * (px - x[k]);
                if (e < 0) inside = false;
                else if (e == 0 && !(dy > 0 || (dy == 0 && dx > 0))) inside = false;
            }
            if (inside && grid[std::size_t(j) * std::size_t(R) + std::size_t(i)] < 65535) ++grid[std::size_t(j) * std::size_t(R) + std::size_t(i)];
        }
}

}  // namespace
}  // namespace fa::uv

namespace fa {

using namespace uv;

ModelUvReport model_uv_measure(const ModelMesh& mesh, const std::vector<std::string>& partNames, const std::string& layout, int textureSize) {
    ModelUvReport r;
    r.layout = layout;
    r.textureSize = textureSize;
    r.triangles = mesh.triangle_count();
    if (mesh.uvs.size() != mesh.positions.size()) {
        r.warnings.push_back("the mesh has no uvs");
        return r;
    }
    const double texSize = textureSize > 0 ? double(textureSize) : 1024.0;
    Work w = make_work(mesh, partNames);
    const std::size_t tris = mesh.triangle_count();
    std::vector<Vec2> cornerUv(tris * 3);
    for (std::size_t t = 0; t < tris; ++t)
        for (int k = 0; k < 3; ++k) cornerUv[t * 3 + std::size_t(k)] = mesh.uvs[w.corner_vertex(t, k)];
    std::int32_t chartCount = 0;
    const std::vector<std::int32_t> chart = charts_by_uv(w, cornerUv, chartCount);
    r.charts = std::size_t(chartCount);

    std::vector<TriMetrics> tm(tris);
    std::vector<double> chartSign(std::size_t(chartCount), 0.0);
    r.parts.resize(w.names.size());
    std::vector<double> partArea(w.names.size(), 0), partDensity(w.names.size(), 0), partStretch(w.names.size(), 0);
    std::vector<std::vector<char>> partCharts(w.names.size(), std::vector<char>(std::size_t(chartCount), 0));
    double density = 0, stretch = 0, area = 0;
    std::size_t flat = 0;
    r.texelsPerMeterMin = 1e30;
    for (std::size_t t = 0; t < tris; ++t) {
        Vec3 p[3];
        Vec2 uv[3];
        for (int k = 0; k < 3; ++k) {
            p[k] = mesh.positions[w.corner_vertex(t, k)];
            uv[k] = cornerUv[t * 3 + std::size_t(k)];
        }
        tm[t] = measure_triangle(p, uv, texSize);
        const std::uint32_t part = w.part[t];
        r.parts[part].triangles++;
        partCharts[part][std::size_t(chart[t])] = 1;
        if (!tm[t].valid) continue;
        chartSign[std::size_t(chart[t])] += tm[t].signedUv > 0 ? tm[t].areaUv : tm[t].signedUv < 0 ? -tm[t].areaUv : 0.0;
        const double a = tm[t].area3;
        area += a;
        if (tm[t].flat) {
            ++flat;
            r.stretchMax = std::max(r.stretchMax, tm[t].stretch);
            r.parts[part].stretchMax = std::max(r.parts[part].stretchMax, tm[t].stretch);
            continue;
        }
        density += tm[t].density * a;
        stretch += tm[t].stretch * a;
        partArea[part] += a;
        partDensity[part] += tm[t].density * a;
        partStretch[part] += tm[t].stretch * a;
        r.texelsPerMeterMin = std::min(r.texelsPerMeterMin, tm[t].density);
        r.texelsPerMeterMax = std::max(r.texelsPerMeterMax, tm[t].density);
        r.stretchMax = std::max(r.stretchMax, tm[t].stretch);
        r.parts[part].stretchMax = std::max(r.parts[part].stretchMax, tm[t].stretch);
    }
    r.surfaceArea = area;
    const double mapped = area;  // triangles with no uv area are counted in `flat`
    if (mapped > 0) {
        r.texelsPerMeter = density / mapped;
        r.stretchMean = stretch / mapped;
    }
    if (r.texelsPerMeterMin > r.texelsPerMeterMax) r.texelsPerMeterMin = 0;
    for (std::size_t p = 0; p < r.parts.size(); ++p) {
        ModelUvPartReport& pr = r.parts[p];
        pr.part = w.names[p];
        pr.method = "none";
        for (char c : partCharts[p]) pr.charts += c ? 1 : 0;
        if (partArea[p] > 0) {
            pr.texelsPerMeter = partDensity[p] / partArea[p];
            pr.stretchMean = partStretch[p] / partArea[p];
        }
    }
    for (std::size_t t = 0; t < tris; ++t) {
        if (!tm[t].valid || tm[t].flat) continue;
        const double s = chartSign[std::size_t(chart[t])];
        if ((tm[t].signedUv > 0) != (s > 0)) ++r.flippedTriangles;  // a tie goes to the expected side (negative: counter-clockwise from outside)
    }

    // seams: an inner edge whose two triangles do not agree on the uvs of its two ends
    struct Use {
        std::uint32_t lo, hi, tri;
        Vec2 uvLo, uvHi;
    };
    std::vector<Use> uses;
    uses.reserve(tris * 3);
    for (std::size_t t = 0; t < tris; ++t)
        for (int k = 0; k < 3; ++k) {
            const int n = (k + 1) % 3;
            std::uint32_t a = w.corner_weld(t, k), b = w.corner_weld(t, n);
            Vec2 ua = cornerUv[t * 3 + std::size_t(k)], ub = cornerUv[t * 3 + std::size_t(n)];
            if (a == b) continue;
            if (a > b) {
                std::swap(a, b);
                std::swap(ua, ub);
            }
            uses.push_back({a, b, std::uint32_t(t), ua, ub});
        }
    std::stable_sort(uses.begin(), uses.end(), [](const Use& x, const Use& y) { return x.lo != y.lo ? x.lo < y.lo : x.hi < y.hi; });
    auto same = [](Vec2 a, Vec2 b) {
        const float tol = 1e-6f * std::max({1.0f, std::fabs(a.x), std::fabs(a.y)});
        return std::fabs(a.x - b.x) <= tol && std::fabs(a.y - b.y) <= tol;
    };
    for (std::size_t i = 0; i + 1 < uses.size();) {
        std::size_t j = i + 1;
        while (j < uses.size() && uses[j].lo == uses[i].lo && uses[j].hi == uses[i].hi) ++j;
        if (j - i == 2 && !(same(uses[i].uvLo, uses[i + 1].uvLo) && same(uses[i].uvHi, uses[i + 1].uvHi))) {
            ++r.seamEdges;
            r.seamLength += double(length(w.wpos[uses[i].hi] - w.wpos[uses[i].lo]));
        }
        i = j;
    }

    if (layout == "atlas") {
        const int R = std::clamp(textureSize > 0 ? textureSize : 1024, 16, 1024);
        std::vector<std::uint16_t> grid(std::size_t(R) * std::size_t(R), 0);
        for (std::size_t t = 0; t < tris; ++t) {
            bool outside = false;
            for (int k = 0; k < 3; ++k) {
                const Vec2 c = cornerUv[t * 3 + std::size_t(k)];
                if (c.x < -1e-5f || c.x > 1 + 1e-5f || c.y < -1e-5f || c.y > 1 + 1e-5f) outside = true;
            }
            if (outside) ++r.outsideTriangles;
            if (!tm[t].valid || tm[t].flat) continue;
            rasterize(grid, R, {cornerUv[t * 3], cornerUv[t * 3 + 1], cornerUv[t * 3 + 2]});
        }
        std::size_t covered = 0, shared = 0;
        for (std::uint16_t c : grid) {
            if (c > 0) ++covered;
            if (c > 1) ++shared;
        }
        r.utilization = double(covered) / (double(R) * double(R));
        r.overlap = covered ? double(shared) / double(covered) : 0.0;
    }

    if (flat > 0) r.warnings.push_back(std::format("{} triangle(s) have area in space but none in the texture: they will draw one stripe of texels", flat));
    if (r.stretchMax > 4 && flat == 0)
        r.warnings.push_back(std::format("the worst triangle is stretched {:.1f}:1 (mean {:.2f}): textures will smear there; use more seams (`seams`: \"many\"), or another method for that part", r.stretchMax, r.stretchMean));
    if (r.overlap > 0.005) r.warnings.push_back(std::format("{:.1f}% of the used texels are shared by two or more triangles: a texture painted there shows on both", r.overlap * 100));
    if (r.outsideTriangles > 0 && layout == "atlas") r.warnings.push_back(std::format("{} triangle(s) have uvs outside the 0..1 texture", r.outsideTriangles));
    return r;
}

}  // namespace fa
