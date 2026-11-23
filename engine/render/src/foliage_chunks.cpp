#include "foliage_chunks.h"

#include <algorithm>
#include <cmath>
#include <numeric>

namespace fa::render {

FoliageChunks build_foliage_chunks(const std::vector<FoliageInstance>& instances, float size) {
    FoliageChunks out;
    const std::size_t n = instances.size();
    if (n == 0) return out;
    const float inv = 1.0f / std::max(size, 1e-3f);
    std::vector<std::int64_t> key(n);
    for (std::size_t i = 0; i < n; ++i) {
        // 32-bit cells in each axis; positions far beyond them (the file holds finite numbers, not sane ones) all share the edge cell
        const double cx = std::clamp(std::floor(double(instances[i].position.x) * inv), -2147483648.0, 2147483647.0);
        const double cz = std::clamp(std::floor(double(instances[i].position.z) * inv), -2147483648.0, 2147483647.0);
        key[i] = (std::int64_t(cx) << 32) | std::int64_t(std::uint32_t(std::int32_t(cz)));
    }
    std::vector<std::uint32_t> order(n);
    std::iota(order.begin(), order.end(), 0u);
    std::stable_sort(order.begin(), order.end(), [&](std::uint32_t a, std::uint32_t b) {
        const std::int32_t ax = std::int32_t(key[a] >> 32), bx = std::int32_t(key[b] >> 32);
        if (ax != bx) return ax < bx;
        return std::int32_t(std::uint32_t(key[a])) < std::int32_t(std::uint32_t(key[b]));
    });
    out.items.resize(n);
    for (std::size_t k = 0; k < n; ++k) {
        const std::uint32_t i = order[k];
        const FoliageInstance& in = instances[i];
        FoliagePacked& p = out.items[k];
        p.position = in.position;
        p.yaw = in.yaw;
        p.scale = in.scale;
        p.up = in.up;
        p.mesh = in.mesh;
        p.rank = foliage_thin_rank(i);
        if (k == 0 || key[order[k - 1]] != key[i]) {
            FoliageChunk c;
            c.first = std::uint32_t(k);
            c.lo = c.hi = in.position;
            c.maxScale = in.scale;
            out.chunks.push_back(c);
        }
        FoliageChunk& c = out.chunks.back();
        ++c.count;
        c.lo = min(c.lo, in.position);
        c.hi = max(c.hi, in.position);
        c.maxScale = std::max(c.maxScale, in.scale);
    }
    return out;
}

std::uint16_t foliage_thin_rank(std::uint32_t index) { return std::uint16_t((index * 2654435769u) >> 16); }

std::uint32_t foliage_keep_below(float density) {
    if (!(density > 0.0f)) return 0;
    if (density >= 1.0f) return 65536u;
    return std::uint32_t(density * 65536.0f);
}

std::uint32_t foliage_kept_count(const FoliageChunks& c, const FoliageChunk& chunk, float density) {
    const std::uint32_t below = foliage_keep_below(density);
    if (below >= 65536u) return chunk.count;
    std::uint32_t kept = 0;
    for (std::uint32_t i = 0; i < chunk.count; ++i) kept += c.items[chunk.first + i].rank < below ? 1u : 0u;
    return kept;
}

int foliage_fade_step(float distance, float fadeStart, float fadeEnd) {
    if (!(distance < fadeEnd)) return -1;  // also a NaN distance: not drawn
    if (!(distance > fadeStart)) return 0;
    const float t = (distance - fadeStart) / std::max(fadeEnd - fadeStart, 1e-6f);  // 0..1
    return std::clamp(int(std::ceil(t * float(kFoliageFadeSteps))), 1, kFoliageFadeSteps);
}

float foliage_fade_amount(int step) {
    if (step <= 0) return 0.0f;
    step = std::min(step, kFoliageFadeSteps);
    return float(kFoliageFadeSteps + 1 - step) / float(kFoliageFadeSteps + 1);
}

Mat4 foliage_local_matrix(const FoliagePacked& p) {
    const float c = std::cos(p.yaw), s = std::sin(p.yaw);
    // The columns of the yaw turn (about +y), then the shortest turn that takes +y to `up` (Rodrigues), when it leans.
    Vec3 cx{c, 0, -s}, cy{0, 1, 0}, cz{s, 0, c};
    if ((p.up.x != 0.0f || p.up.z != 0.0f) && p.up.y > -0.99f) {
        const Vec3 a{p.up.z, 0.0f, -p.up.x};  // cross(+y, up)
        const float k = 1.0f / (1.0f + p.up.y);
        const auto lean = [&](Vec3 v) {
            const Vec3 axv = cross(a, v);
            const Vec3 axaxv = cross(a, axv);
            return Vec3{v.x + axv.x + axaxv.x * k, v.y + axv.y + axaxv.y * k, v.z + axv.z + axaxv.z * k};
        };
        cx = lean(cx);
        cy = lean(cy);
        cz = lean(cz);
    }
    Mat4 m = Mat4::identity();
    const Vec3 cols[3] = {cx, cy, cz};
    for (int i = 0; i < 3; ++i) {
        m.at(i, 0) = cols[i].x * p.scale;
        m.at(i, 1) = cols[i].y * p.scale;
        m.at(i, 2) = cols[i].z * p.scale;
    }
    m.at(3, 0) = p.position.x;
    m.at(3, 1) = p.position.y;
    m.at(3, 2) = p.position.z;
    return m;
}

void foliage_sway(float strength, float frequency, float time, float x, float z, float& dx, float& dz) {
    constexpr float kTwoPi = 6.2831853f;
    const float phase = 0.21f * x + 0.17f * z;
    const float w = kTwoPi * frequency * time;
    const float s = 0.75f * std::sin(w + phase) + 0.25f * std::sin(2.7f * w + 2.3f * phase + 1.0f);  // -1..1
    dx = strength * s * 0.894f;  // the wind blows along (2, 1)
    dz = strength * s * 0.447f;
}

}  // namespace fa::render
