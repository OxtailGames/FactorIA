#include "local_shadows.h"

#include <algorithm>
#include <cmath>

namespace fa::render {

CubeFace cube_face_basis(int face) {
    switch (face) {
        case 0: return {{1, 0, 0}, {0, 1, 0}};
        case 1: return {{-1, 0, 0}, {0, 1, 0}};
        case 2: return {{0, 1, 0}, {0, 0, 1}};
        case 3: return {{0, -1, 0}, {0, 0, -1}};
        case 4: return {{0, 0, 1}, {0, 1, 0}};
        default: return {{0, 0, -1}, {0, 1, 0}};
    }
}

int cube_face_of(Vec3 d) {
    const float ax = std::fabs(d.x), ay = std::fabs(d.y), az = std::fabs(d.z);
    if (ax >= ay && ax >= az) return d.x > 0.0f ? 0 : 1;
    if (ay >= az) return d.y > 0.0f ? 2 : 3;
    return d.z > 0.0f ? 4 : 5;
}

bool local_light_is_cube(const LocalShadowInput& in) {
    return in.spotAngle <= 0.0f || in.spotAngle > kMaxSpotTileAngle;
}

float local_shadow_importance(float brightness, float range, float distanceToCamera) {
    const float r2 = std::max(range * range, 1e-6f);
    const float d = std::max(distanceToCamera, 0.0f);
    return std::max(brightness, 0.0f) * r2 / (r2 + d * d);
}

int local_shadow_wanted_tile(const LocalShadowInput& in, float distanceToCamera) {
    if (in.resolution > 0)
        return std::clamp(pow2_floor(std::min(in.resolution, kLocalShadowMaxTile)), kLocalShadowMinTile,
                          kLocalShadowMaxTile);
    const int base = local_light_is_cube(in) ? 512 : 1024;
    const float ratio = std::min(1.0f, std::max(in.range, 1e-3f) / std::max(distanceToCamera, 1e-3f));
    return std::clamp(pow2_floor(int(float(base) * ratio)), kLocalShadowMinTile, base);
}

LocalShadowPlan plan_local_shadows(int atlasMax, const std::vector<ShadowTileRequest>& sunTiles,
                                   const std::vector<LocalShadowInput>& inputs, Vec3 camera, int maxViews) {
    LocalShadowPlan plan;
    struct Ranked {
        std::size_t input;
        float importance;
        int wanted;
        bool cube;
    };
    std::vector<Ranked> ranked;
    ranked.reserve(inputs.size());
    for (std::size_t i = 0; i < inputs.size(); ++i) {
        const LocalShadowInput& in = inputs[i];
        const float dist = length(in.position - camera);
        ranked.push_back({i, local_shadow_importance(in.brightness, in.range, dist), local_shadow_wanted_tile(in, dist),
                          local_light_is_cube(in)});
    }
    // Most important first; equal scores by the light's place in the table.
    std::stable_sort(ranked.begin(), ranked.end(), [&](const Ranked& a, const Ranked& b) {
        if (a.importance != b.importance) return a.importance > b.importance;
        return inputs[a.input].light < inputs[b.input].light;
    });
    // The tiles the views allow: a light that would pass the limit is lost.
    std::vector<Ranked> kept;
    int views = int(sunTiles.size());
    for (const Ranked& r : ranked) {
        const int tiles = r.cube ? kCubeFaces : 1;
        if (views + tiles > maxViews) {
            plan.lost.push_back(inputs[r.input].light);
            continue;
        }
        views += tiles;
        kept.push_back(r);
    }
    // Pack, and while a light has a tile that did not fit drop the lights that have one: a light has all its faces or none.
    for (;;) {
        std::vector<ShadowTileRequest> requests = sunTiles;
        for (std::size_t k = 0; k < kept.size(); ++k) {
            const int tiles = kept[k].cube ? kCubeFaces : 1;
            for (int f = 0; f < tiles; ++f)
                requests.push_back({kept[k].wanted, kLocalShadowMinTile, kLocalShadowPriority + int(k)});
        }
        plan.atlas = layout_shadow_atlas(atlasMax, requests);
        std::vector<Ranked> next;
        std::size_t tile = sunTiles.size();
        bool lostAny = false;
        for (const Ranked& r : kept) {
            const int tiles = r.cube ? kCubeFaces : 1;
            bool all = true;
            for (int f = 0; f < tiles; ++f) all = all && plan.atlas.tiles[tile + std::size_t(f)].placed();
            tile += std::size_t(tiles);
            if (all) {
                next.push_back(r);
            } else {
                plan.lost.push_back(inputs[r.input].light);
                lostAny = true;
            }
        }
        if (!lostAny) break;
        kept.swap(next);
    }
    std::size_t tile = sunTiles.size();
    for (const Ranked& r : kept) {
        LocalShadowLight l;
        l.light = inputs[r.input].light;
        l.cube = r.cube;
        l.firstTile = int(tile);
        l.tiles = r.cube ? kCubeFaces : 1;
        l.wanted = r.wanted;
        for (int f = 0; f < l.tiles; ++f)
            if (plan.atlas.tiles[tile + std::size_t(f)].size < r.wanted) l.shrunk = true;
        if (l.shrunk) ++plan.shrunkLights;
        tile += std::size_t(l.tiles);
        plan.lights.push_back(l);
    }
    std::sort(plan.lost.begin(), plan.lost.end());
    return plan;
}

void spot_tile_basis(Vec3 axis, Vec3& forward, Vec3& up) {
    forward = normalize(axis);
    up = std::fabs(forward.y) > 0.99f ? Vec3{0, 0, 1} : Vec3{0, 1, 0};
}

LocalTileFit fit_local_tile(Vec3 position, Vec3 forward, Vec3 up, float tanHalf, int tile, float range,
                            bool zeroToOne) {
    LocalTileFit out;
    const float half = 0.5f * float(std::max(tile, 4 * kLocalShadowGuard));
    const float guard = float(std::min(kLocalShadowGuard, std::max(tile, 4) / 4));
    // The region the tile is chosen for takes the middle (tile - 2 * guard) texels of it.
    const float t = std::max(tanHalf, 1e-3f) * half / std::max(half - guard, 1.0f);
    out.farPlane = std::max(range, 0.1f);
    out.nearPlane = std::min(std::max(0.05f, out.farPlane / 200.0f), out.farPlane * 0.5f);
    out.texelCoef = 2.0f * t / float(std::max(tile, 4));
    const Mat4 view = Mat4::look_at(position, position + forward, up);
    const Mat4 proj = Mat4::perspective(degrees(2.0f * std::atan(t)), 1.0f, out.nearPlane, out.farPlane, zeroToOne);
    out.viewProj = proj * view;
    return out;
}

Mat4 local_sample_matrix(const LocalTileFit& fit, const ShadowTile& tile, int atlasW, int atlasH, bool isGl) {
    const float w = float(atlasW), h = float(atlasH), size = float(tile.size);
    Mat4 t;  // clip x, y, z, w -> (u * w, v * w, -, w)
    t.at(0, 0) = 0.5f * size / w;
    t.at(3, 0) = (float(tile.x) + 0.5f * size) / w;
    if (isGl) {
        t.at(1, 1) = 0.5f * size / h;
        t.at(3, 1) = (h - float(tile.y) - size + 0.5f * size) / h;
    } else {
        t.at(1, 1) = -0.5f * size / h;
        t.at(3, 1) = (float(tile.y) + 0.5f * size) / h;
    }
    t.at(2, 2) = 0.0f;
    return t * fit.viewProj;
}

std::size_t local_shadow_region_texels(int lights, const std::vector<LocalShadowRecord>& records) {
    if (records.empty() || lights <= 0) return 0;
    std::size_t n = std::size_t(lights);
    for (const LocalShadowRecord& r : records)
        n += std::size_t(kLocalShadowHeaderTexels) + r.tiles.size() * std::size_t(kLocalShadowTileTexels);
    return n;
}

void pack_local_shadow_region(int lights, const std::vector<LocalShadowRecord>& records, std::size_t base,
                              float* texels) {
    if (records.empty() || lights <= 0) return;
    for (int i = 0; i < lights; ++i) texels[(base + std::size_t(i)) * 4] = -1.0f;
    std::size_t at = base + std::size_t(lights);
    for (const LocalShadowRecord& r : records) {
        if (r.light < 0 || r.light >= lights) continue;
        texels[(base + std::size_t(r.light)) * 4] = float(at);
        float* h = texels + at * 4;
        h[0] = float(r.kind);
        h[1] = r.fade;
        h[2] = float(r.filter);
        h[3] = r.softness;
        h[4] = r.bias;
        h[5] = r.normalBias;
        at += kLocalShadowHeaderTexels;
        for (const LocalShadowTileRecord& t : r.tiles) {
            float* p = texels + at * 4;
            for (int row = 0; row < 4; ++row)
                for (int c = 0; c < 4; ++c) p[row * 4 + c] = t.sample.at(c, row);  // the row `row` of the matrix
            p[16] = t.rect.x;
            p[17] = t.rect.y;
            p[18] = t.rect.z;
            p[19] = t.rect.w;
            p[20] = t.texelCoef;
            p[21] = t.nearPlane;
            p[22] = t.farPlane;
            at += kLocalShadowTileTexels;
        }
    }
}

}  // namespace fa::render
