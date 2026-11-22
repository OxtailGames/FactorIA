#include "shadow_cascades.h"

#include <algorithm>
#include <cmath>

namespace fa::render {

int pow2_floor(int v) {
    if (v < 1) return 0;
    int p = 1;
    while (p <= v / 2) p *= 2;
    return p;
}

int pow2_ceil(int v) {
    if (v <= 1) return 1;
    int p = 1;
    while (p < v && p < (1 << 30)) p *= 2;
    return p;
}

namespace {
struct Square {
    int x, y, s;
};

// Places the maps whose `sizes` entry is > 0 (biggest first, then the more important, then the earlier request): the free square
// that fits best, split into quarters down to the size wanted. Fills `tiles` (size 0 = no room) and returns how many did not fit.
int pack_tiles(int maxSize, const std::vector<int>& sizes, const std::vector<int>& priorities,
               std::vector<ShadowTile>& tiles) {
    tiles.assign(sizes.size(), ShadowTile{});
    std::vector<std::size_t> order;
    for (std::size_t i = 0; i < sizes.size(); ++i)
        if (sizes[i] > 0) order.push_back(i);
    std::stable_sort(order.begin(), order.end(), [&](std::size_t a, std::size_t b) {
        if (sizes[a] != sizes[b]) return sizes[a] > sizes[b];
        return priorities[a] < priorities[b];
    });
    std::vector<Square> freeList{{0, 0, maxSize}};
    int unplaced = 0;
    for (std::size_t i : order) {
        const int want = sizes[i];
        int best = -1;
        for (std::size_t k = 0; k < freeList.size(); ++k) {
            const Square& q = freeList[k];
            if (q.s < want) continue;
            if (best < 0) {
                best = int(k);
                continue;
            }
            const Square& b = freeList[std::size_t(best)];
            if (q.s < b.s || (q.s == b.s && (q.y < b.y || (q.y == b.y && q.x < b.x)))) best = int(k);
        }
        if (best < 0) {
            ++unplaced;
            continue;
        }
        Square q = freeList[std::size_t(best)];
        freeList.erase(freeList.begin() + best);
        while (q.s > want) {
            const int h = q.s / 2;
            freeList.push_back({q.x + h, q.y, h});
            freeList.push_back({q.x, q.y + h, h});
            freeList.push_back({q.x + h, q.y + h, h});
            q.s = h;
        }
        tiles[i] = ShadowTile{q.x, q.y, want};
    }
    return unplaced;
}
}  // namespace

ShadowAtlasLayout layout_shadow_atlas(int maxSize, const std::vector<ShadowTileRequest>& requests) {
    ShadowAtlasLayout out;
    maxSize = std::max(64, pow2_floor(maxSize));
    const std::size_t n = requests.size();
    std::vector<int> sizes(n), mins(n), prio(n), tiers(n);
    std::vector<bool> alive(n, true);
    for (std::size_t i = 0; i < n; ++i) {
        sizes[i] = std::min(pow2_floor(requests[i].size), maxSize);
        mins[i] = std::min(std::max(1, pow2_floor(requests[i].minSize)), std::max(sizes[i], 1));
        prio[i] = requests[i].priority;
        tiers[i] = requests[i].tier;
        if (sizes[i] <= 0) {
            alive[i] = false;
            ++out.dropped;
        }
    }
    for (;;) {
        std::vector<int> live(n, 0);
        for (std::size_t i = 0; i < n; ++i) live[i] = alive[i] ? sizes[i] : 0;
        const int unplaced = pack_tiles(maxSize, live, prio, out.tiles);
        if (unplaced == 0) break;
        // The budget, on the highest tier that has a map alive (the local lights before the sun): halve its largest map that can still
        // shrink (the least important of equally large ones), else drop its least important one. Every round shrinks or drops
        // something, so the loop ends.
        int top = -1;
        for (std::size_t i = 0; i < n; ++i)
            if (alive[i]) top = std::max(top, tiers[i]);
        int victim = -1;
        for (std::size_t i = 0; i < n; ++i) {
            if (!alive[i] || tiers[i] != top || sizes[i] <= mins[i]) continue;
            if (victim < 0 || sizes[i] > sizes[std::size_t(victim)] ||
                (sizes[i] == sizes[std::size_t(victim)] && prio[i] >= prio[std::size_t(victim)]))
                victim = int(i);
        }
        if (victim >= 0) {
            sizes[std::size_t(victim)] /= 2;
            ++out.shrunk;
            continue;
        }
        for (std::size_t i = 0; i < n; ++i)
            if (alive[i] && tiers[i] == top && (victim < 0 || prio[i] >= prio[std::size_t(victim)])) victim = int(i);
        alive[std::size_t(victim)] = false;
        ++out.dropped;
    }
    if (out.tiles.size() != n) out.tiles.assign(n, ShadowTile{});
    int right = 0, bottom = 0;
    for (const ShadowTile& t : out.tiles) {
        if (!t.placed()) continue;
        right = std::max(right, t.x + t.size);
        bottom = std::max(bottom, t.y + t.size);
    }
    out.width = right > 0 ? pow2_ceil(right) : 0;
    out.height = bottom > 0 ? pow2_ceil(bottom) : 0;
    return out;
}

std::array<float, kMaxShadowCascades + 1> cascade_splits(float nearD, float farD, int count, float lambda) {
    std::array<float, kMaxShadowCascades + 1> s;
    s.fill(farD);
    count = std::clamp(count, 1, kMaxShadowCascades);
    lambda = std::clamp(lambda, 0.0f, 1.0f);
    s[0] = nearD;
    const bool logOk = nearD > 1e-4f && farD > nearD;
    for (int i = 1; i < count; ++i) {
        const float t = float(i) / float(count);
        const float linear = nearD + (farD - nearD) * t;
        const float logarithmic = logOk ? nearD * std::pow(farD / nearD, t) : linear;
        s[std::size_t(i)] = linear + (logarithmic - linear) * (logOk ? lambda : 0.0f);
    }
    s[std::size_t(count)] = farD;
    return s;
}

float quantize_up(float v, int bits) {
    if (!(v > 0.0f) || !std::isfinite(v)) return v;
    int e = 0;
    const float m = std::frexp(v, &e);  // v = m * 2^e, m in [0.5, 1)
    const float steps = float(1 << std::clamp(bits, 1, 20));
    return std::ldexp(std::ceil(m * steps) / steps, e);
}

CameraFrustum camera_frustum(const Mat4& invViewProj, bool zeroToOne, Vec3 position, Vec3 forward) {
    CameraFrustum f;
    f.position = position;
    f.forward = forward;
    const float xs[4] = {-1, 1, 1, -1}, ys[4] = {-1, -1, 1, 1};
    const float zn = zeroToOne ? 0.0f : -1.0f;
    float dn = 0, df = 0;
    for (int i = 0; i < 4; ++i) {
        const Vec4 a = invViewProj * Vec4{xs[i], ys[i], zn, 1.0f};
        const Vec4 b = invViewProj * Vec4{xs[i], ys[i], 1.0f, 1.0f};
        f.nearCorner[i] = Vec3{a.x, a.y, a.z} / a.w;
        f.farCorner[i] = Vec3{b.x, b.y, b.z} / b.w;
        dn += dot(f.nearCorner[i] - position, forward);
        df += dot(f.farCorner[i] - position, forward);
    }
    f.nearDist = dn * 0.25f;
    f.farDist = df * 0.25f;
    return f;
}

SliceSphere slice_sphere(const CameraFrustum& f, float d0, float d1) {
    const float span = f.farDist - f.nearDist;
    auto radial = [&](float d) {  // the largest distance of a corner of the slice at distance d from the camera's axis
        const float t = span > 1e-6f ? std::clamp((d - f.nearDist) / span, 0.0f, 1.0f) : 0.0f;
        float r = 0;
        for (int i = 0; i < 4; ++i) {
            const Vec3 c = f.nearCorner[i] + (f.farCorner[i] - f.nearCorner[i]) * t - f.position;
            const Vec3 off = c - f.forward * dot(c, f.forward);
            r = std::max(r, length(off));
        }
        return r;
    };
    d1 = std::max(d1, d0);
    const float r0 = radial(d0), r1 = radial(d1);
    float c = d0;
    if (d1 - d0 > 1e-5f) c = (d1 * d1 - d0 * d0 + r1 * r1 - r0 * r0) / (2.0f * (d1 - d0));
    c = std::clamp(c, d0, d1);
    SliceSphere s;
    s.centreDist = c;
    s.radius = std::max(std::sqrt((d0 - c) * (d0 - c) + r0 * r0), std::sqrt((d1 - c) * (d1 - c) + r1 * r1));
    return s;
}

CascadeFit fit_cascade(Vec3 centre, float radius, Vec3 lightDir, int tile, float casterMin, bool zeroToOne,
                       const DVec3& origin) {
    CascadeFit out;
    const Vec3 f = normalize(lightDir);
    const Vec3 upRef = std::fabs(f.y) > 0.99f ? Vec3{0, 0, 1} : Vec3{0, 1, 0};
    const Vec3 s = normalize(cross(f, upRef));  // the same basis Mat4::look_at builds
    const Vec3 u = cross(s, f);
    const float texel = 2.0f * radius / float(std::max(tile, 4));
    const float cz = dot(centre, f);
    // The centre moves in whole texels of the map along the light's x and y: the texel grid is fixed in the world, so a still shadow
    // lands on the same texels whatever the camera does between two steps.
    // With a floating origin the grid is fixed in absolute space: the same snap on origin + centre, in double.
    const bool shifted = origin.x != 0.0 || origin.y != 0.0 || origin.z != 0.0;
    auto snap = [&](Vec3 axis) {
        const float c = dot(centre, axis);
        if (!shifted) return std::floor(c / texel + 0.5f) * texel;
        const double a = origin.x * double(axis.x) + origin.y * double(axis.y) + origin.z * double(axis.z);
        return float(std::floor((a + double(c)) / double(texel) + 0.5) * double(texel) - a);
    };
    const float cx = snap(s);
    const float cy = snap(u);
    const float margin = std::max(radius * 0.05f, 0.25f);
    const float front = std::min(cz - radius, casterMin) - margin;
    const float back = cz + radius;
    const Vec3 eye = s * cx + u * cy + f * front;
    out.view = Mat4::look_at(eye, eye + f, upRef);
    const Mat4 proj = Mat4::ortho(-radius, radius, -radius, radius, 0.0f, back - front, zeroToOne);
    out.viewProj = proj * out.view;
    out.centre = s * cx + u * cy + f * cz;
    out.radius = radius;
    out.texel = texel;
    out.depthRange = back - front;
    return out;
}

Mat4 shadow_sample_matrix(const CascadeFit& fit, const ShadowTile& tile, int atlasW, int atlasH, bool zeroToOne,
                          bool isGl) {
    const float w = float(atlasW), h = float(atlasH), size = float(tile.size);
    Mat4 t;  // clip x, y, z -> atlas u, v, depth 0..1
    t.at(0, 0) = 0.5f * size / w;
    t.at(3, 0) = (float(tile.x) + 0.5f * size) / w;
    if (isGl) {
        t.at(1, 1) = 0.5f * size / h;
        t.at(3, 1) = (h - float(tile.y) - size + 0.5f * size) / h;
    } else {
        t.at(1, 1) = -0.5f * size / h;
        t.at(3, 1) = (float(tile.y) + 0.5f * size) / h;
    }
    if (!zeroToOne) {
        t.at(2, 2) = 0.5f;
        t.at(3, 2) = 0.5f;
    }
    return t * fit.viewProj;
}

Vec4 shadow_tile_rect(const ShadowTile& tile, int atlasW, int atlasH, bool isGl) {
    const float w = float(atlasW), h = float(atlasH);
    const float u0 = float(tile.x) / w, u1 = float(tile.x + tile.size) / w;
    const float v0 = isGl ? (h - float(tile.y + tile.size)) / h : float(tile.y) / h;
    const float v1 = isGl ? (h - float(tile.y)) / h : float(tile.y + tile.size) / h;
    return Vec4{u0, v0, u1, v1};
}

float auto_shadow_far(Vec3 cameraPosition, Vec3 casterMin, Vec3 casterMax) {
    float far2 = 0.0f;
    for (int c = 0; c < 8; ++c) {
        const Vec3 corner{(c & 1) ? casterMax.x : casterMin.x, (c & 2) ? casterMax.y : casterMin.y,
                          (c & 4) ? casterMax.z : casterMin.z};
        far2 = std::max(far2, length_sq(corner - cameraPosition));
    }
    return quantize_up(std::sqrt(far2) + length(casterMax - casterMin), 3);
}

CascadePlan plan_cascades(const CameraFrustum& cf, Vec3 casterMin, Vec3 casterMax, Vec3 lightDir, float shadowDistance,
                          float lambda, float blend, const std::vector<int>& tileSizes, bool zeroToOne,
                          const DVec3& origin) {
    CascadePlan out;
    const int count = std::min(int(tileSizes.size()), kMaxShadowCascades);
    if (count < 1) return out;
    const float nearD = std::max(cf.nearDist, 0.0f);  // an orthographic camera's near plane may be behind it
    float farD = shadowDistance > 0.0f ? std::min(shadowDistance, cf.farDist)
                                       : std::min(cf.farDist, auto_shadow_far(cf.position, casterMin, casterMax));
    if (!(farD > nearD + 0.1f)) farD = std::min(cf.farDist, nearD + 0.1f);
    if (!(farD > nearD)) return out;
    out.splits = cascade_splits(nearD, farD, count, lambda);
    // The sun's casters in front of the first plane still shade the view, so every map's near plane goes back to the nearest caster
    // along the light.
    const Vec3 ld = normalize(lightDir);
    float nearestCaster = 1e30f;
    for (int c = 0; c < 8; ++c) {
        const Vec3 corner{(c & 1) ? casterMax.x : casterMin.x, (c & 2) ? casterMax.y : casterMin.y,
                          (c & 4) ? casterMax.z : casterMin.z};
        nearestCaster = std::min(nearestCaster, dot(corner, ld));
    }
    blend = std::clamp(blend, 0.0f, 0.5f);
    float prevStart = nearD;
    for (int c = 0; c < count; ++c) {
        // A cascade also covers the band before its first plane in which the cascade before it blends into it.
        float d0 = out.splits[std::size_t(c)];
        if (c > 0) d0 -= blend * (out.splits[std::size_t(c)] - prevStart);
        d0 = std::max(d0, nearD);
        prevStart = out.splits[std::size_t(c)];
        const SliceSphere sp = slice_sphere(cf, d0, out.splits[std::size_t(c) + 1]);
        const int px = tileSizes[std::size_t(c)];
        // Rounded up to 6 bits so float noise in the camera does not change the map's size, and two texels of margin for the snapping.
        const float radius = std::max(0.5f, quantize_up(sp.radius, 6)) * float(px) / float(px - 4);
        const Vec3 centre = cf.position + cf.forward * sp.centreDist;
        out.fits[std::size_t(c)] = fit_cascade(centre, radius, ld, px, nearestCaster, zeroToOne, origin);
    }
    out.ok = true;
    return out;
}

}  // namespace fa::render
