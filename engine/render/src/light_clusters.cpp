#include "light_clusters.h"

#include <algorithm>
#include <cmath>
#include <limits>

#include "render_jobs.h"

namespace fa::render {

namespace {

constexpr float kDepthMargin =
    2e-3f;  // relative margin of a sphere's depth range: the GPU's log2 and dot differ in the last digits
constexpr float kDepthPad = 1e-4f;  // and an absolute one, for depths near 0
constexpr float kTileMarginPx =
    2.0f;  // margin of a sphere's tile range, in pixels (a jittered projection, the sample position)
constexpr float kMinW =
    1e-4f;  // a corner of the sphere's box nearer than this to the camera plane makes the range the whole view

bool finite4(float a, float b, float c, float d) {
    return std::isfinite(a) && std::isfinite(b) && std::isfinite(c) && std::isfinite(d);
}

}  // namespace

ClusterGrid make_cluster_grid(int widthPx, int heightPx, float nearDepth, float farDepth) {
    ClusterGrid g;
    const int w = std::max(widthPx, 1), h = std::max(heightPx, 1);
    int tile = kClusterTilePx;
    for (;;) {
        g.tilesX = std::max(1, (w + tile - 1) / tile);
        g.tilesY = std::max(1, (h + tile - 1) / tile);
        if (std::int64_t(g.tilesX) * g.tilesY * g.slices <= kMaxClusters || tile >= (1 << 20)) break;
        tile *= 2;
    }
    const float n = std::isfinite(nearDepth) ? std::max(nearDepth, 1e-3f) : 0.1f;
    float f = std::isfinite(farDepth) ? farDepth : n * 10000.0f;
    f = std::max(f, n * 1.5f);
    g.nearDepth = n;
    g.slicesPerOctave = float(g.slices) / std::log2(f / n);
    return g;
}

int cluster_slice(const ClusterGrid& grid, float depth) {
    if (!(depth > grid.nearDepth)) return 0;
    const float v = std::log2(depth / grid.nearDepth) * grid.slicesPerOctave;
    return int(std::fmin(std::fmax(v, 0.0f), float(grid.slices - 1)));
}

int cluster_tile(float ndc, int tiles) {
    const float v = (ndc * 0.5f + 0.5f) * float(tiles);
    if (!(v > 0.0f)) return 0;
    if (v >= float(tiles)) return tiles - 1;
    return int(v);
}

bool light_cluster_range(const ClusterCamera& cam, const ClusterGrid& grid, const LightSphere& s, ClusterRange& out) {
    if (!finite4(s.x, s.y, s.z, s.radius) || !(s.radius > 0.0f)) return false;
    const float depth = (s.x - cam.position.x) * cam.forward.x + (s.y - cam.position.y) * cam.forward.y +
                        (s.z - cam.position.z) * cam.forward.z;
    const float lo = depth - s.radius, hi = depth + s.radius;
    if (!std::isfinite(depth) || hi * (1.0f + kDepthMargin) + kDepthPad < cam.nearDepth) return false;
    if (lo * (1.0f - kDepthMargin) - kDepthPad > cam.farDepth) return false;
    out.s0 = cluster_slice(grid, lo * (1.0f - kDepthMargin) - kDepthPad);
    out.s1 = cluster_slice(grid, hi * (1.0f + kDepthMargin) + kDepthPad);
    // The box around the sphere, through the same matrix the vertex stage uses. When every corner is in front of the camera plane the
    // projection of the box is the hull of its projected corners; otherwise the whole view is covered.
    float x0 = 1e30f, x1 = -1e30f, y0 = 1e30f, y1 = -1e30f;
    bool whole = false;
    for (int c = 0; c < 8 && !whole; ++c) {
        const Vec4 p =
            cam.viewProj * Vec4{s.x + ((c & 1) ? s.radius : -s.radius), s.y + ((c & 2) ? s.radius : -s.radius),
                                s.z + ((c & 4) ? s.radius : -s.radius), 1.0f};
        if (!(p.w > kMinW) || !finite4(p.x, p.y, p.w, 0.0f)) {
            whole = true;
            break;
        }
        const float nx = p.x / p.w, ny = p.y / p.w;
        x0 = std::min(x0, nx);
        x1 = std::max(x1, nx);
        y0 = std::min(y0, ny);
        y1 = std::max(y1, ny);
    }
    if (whole) {
        out.x0 = 0;
        out.x1 = grid.tilesX - 1;
        out.y0 = 0;
        out.y1 = grid.tilesY - 1;
        return true;
    }
    const float mx = kTileMarginPx * 2.0f / float(std::max(cam.widthPx, 1));
    const float my = kTileMarginPx * 2.0f / float(std::max(cam.heightPx, 1));
    x0 -= mx;
    x1 += mx;
    y0 -= my;
    y1 += my;
    if (x1 < -1.0f || x0 > 1.0f || y1 < -1.0f || y0 > 1.0f) return false;
    out.x0 = cluster_tile(x0, grid.tilesX);
    out.x1 = cluster_tile(x1, grid.tilesX);
    out.y0 = cluster_tile(y0, grid.tilesY);
    out.y1 = cluster_tile(y1, grid.tilesY);
    return true;
}

void build_light_clusters(const ClusterCamera& cam, const ClusterGrid& grid, const std::vector<LightSphere>& spheres,
                          ClusterLists& out) {
    out = ClusterLists{};
    out.grid = grid;
    const std::size_t clusters = std::size_t(grid.clusters());
    const std::size_t lights = spheres.size();
    // 1. The range of every light: independent per light.
    std::vector<ClusterRange> ranges(lights);
    std::vector<std::uint8_t> reaches(lights, 0);
    constexpr std::size_t kRangeGrain = 128, kRangeMin = 512;
    rjobs::run("render.light_ranges", rjobs::split(lights, kRangeGrain, kRangeMin), [&](const jobs::Chunk& c) {
        for (std::size_t i = c.begin; i < c.end; ++i)
            reaches[i] = light_cluster_range(cam, grid, spheres[i], ranges[i]) ? 1 : 0;
    });
    for (std::size_t i = 0; i < lights; ++i) out.lightsAssigned += reaches[i];
    // 2. How many lights reach each cluster. The clusters of a slice are written by the chunk that owns the slice.
    std::vector<std::uint32_t> want(clusters, 0);
    const auto slices = std::size_t(grid.slices);
    const std::size_t sliceMin = lights >= 128 ? 2 : slices + 1;  // below: one chunk
    auto perSlice = [&](const char* name, auto&& fn) {
        rjobs::run(name, rjobs::split(slices, 2, sliceMin), [&](const jobs::Chunk& c) {
            for (std::size_t s = c.begin; s < c.end; ++s) fn(int(s));
        });
    };
    const std::size_t perSliceClusters = std::size_t(grid.tilesX) * std::size_t(grid.tilesY);
    perSlice("render.light_count", [&](int slice) {
        std::uint32_t* w = want.data() + std::size_t(slice) * perSliceClusters;
        for (std::size_t i = 0; i < lights; ++i) {
            if (!reaches[i] || slice < ranges[i].s0 || slice > ranges[i].s1) continue;
            const ClusterRange& r = ranges[i];
            for (int y = r.y0; y <= r.y1; ++y)
                for (int x = r.x0; x <= r.x1; ++x) ++w[std::size_t(y) * std::size_t(grid.tilesX) + std::size_t(x)];
        }
    });
    // 3. The lists, in cluster order: each keeps at most kMaxLightsPerCluster entries and the view at most kMaxClusterIndices.
    out.first.assign(clusters, 0);
    out.count.assign(clusters, 0);
    std::size_t total = 0;
    for (std::size_t c = 0; c < clusters; ++c) {
        const std::size_t room = kMaxClusterIndices - total;
        const std::size_t keep = std::min<std::size_t>({want[c], std::size_t(kMaxLightsPerCluster), room});
        out.first[c] = std::uint32_t(total);
        out.count[c] = std::uint32_t(keep);
        total += keep;
        if (keep < want[c]) {
            out.clippedEntries += want[c] - keep;
            ++out.clippedClusters;
        }
        out.maxPerCluster = std::max(out.maxPerCluster, keep);
    }
    // 4. Fill: ascending light index, so a list is in the order of the light table.
    out.indices.assign(total, 0);
    std::vector<std::uint32_t> filled(clusters, 0);
    perSlice("render.light_fill", [&](int slice) {
        const std::size_t base = std::size_t(slice) * perSliceClusters;
        for (std::size_t i = 0; i < lights; ++i) {
            if (!reaches[i] || slice < ranges[i].s0 || slice > ranges[i].s1) continue;
            const ClusterRange& r = ranges[i];
            for (int y = r.y0; y <= r.y1; ++y)
                for (int x = r.x0; x <= r.x1; ++x) {
                    const std::size_t c = base + std::size_t(y) * std::size_t(grid.tilesX) + std::size_t(x);
                    if (filled[c] < out.count[c]) out.indices[out.first[c] + filled[c]++] = std::uint32_t(i);
                }
        }
    });
}

int light_texture_rows(std::size_t texels) {
    const std::size_t rows = (texels + kLightTextureWidth - 1) / kLightTextureWidth;
    std::size_t r = 1;
    while (r < rows) r *= 2;
    return int(r);
}

void pack_light_texture(const std::vector<LightData>& lights, int directional, const ClusterCamera& camera,
                        const ClusterLists* lists, LightTexture& out) {
    out.width = kLightTextureWidth;
    out.stride = kLightTexels;
    for (const LightData& l : lights)
        if (l.hasExt) out.stride = kLightTexelsExt;
    const std::size_t lightTexels = lights.size() * std::size_t(out.stride);
    const std::size_t clusterTexels = lists ? lists->first.size() : 0;
    const std::size_t indexTexels = lists ? (lists->indices.size() + 3) / 4 : 0;
    out.usedTexels = lightTexels + clusterTexels + indexTexels;
    out.height = light_texture_rows(std::max<std::size_t>(out.usedTexels, 1));
    out.texels.assign(std::size_t(out.width) * std::size_t(out.height) * 4, 0.0f);
    float* t = out.texels.data();
    for (std::size_t i = 0; i < lights.size(); ++i) {
        const LightData& l = lights[i];
        float* p = t + i * std::size_t(out.stride) * 4;
        for (int c = 0; c < 4; ++c) {
            p[c] = l.pos[c];
            p[4 + c] = l.color[c];
            p[8 + c] = l.dir[c];
        }
        p[12] = l.cosInner;
        if (l.hasExt && out.stride == kLightTexelsExt) {
            for (int k = 0; k < 4; ++k)
                for (int c = 0; c < 4; ++c) p[16 + k * 4 + c] = l.ext[k][c];
        }
    }
    out.uniforms = ClusterUniforms{};
    out.uniforms.info[2] = float(directional);
    if (!lists) return;
    const std::size_t clusterBase = lightTexels;
    for (std::size_t c = 0; c < clusterTexels; ++c) {
        t[(clusterBase + c) * 4 + 0] = float(lists->first[c]);
        t[(clusterBase + c) * 4 + 1] = float(lists->count[c]);
    }
    float* idx = t + (clusterBase + clusterTexels) * 4;
    for (std::size_t i = 0; i < lists->indices.size(); ++i) idx[i] = float(lists->indices[i]);
    ClusterUniforms& u = out.uniforms;
    for (int c = 0; c < 4; ++c) {
        u.vpx[c] = camera.viewProj.at(c, 0);
        u.vpy[c] = camera.viewProj.at(c, 1);
        u.vpw[c] = camera.viewProj.at(c, 3);
    }
    u.fwd[0] = camera.forward.x;
    u.fwd[1] = camera.forward.y;
    u.fwd[2] = camera.forward.z;
    u.fwd[3] = -(camera.forward.x * camera.position.x + camera.forward.y * camera.position.y +
                 camera.forward.z * camera.position.z);
    u.grid[0] = float(lists->grid.tilesX);
    u.grid[1] = float(lists->grid.tilesY);
    u.grid[2] = lists->grid.slicesPerOctave;
    u.grid[3] = lists->grid.nearDepth;
    u.info[0] = float(clusterBase);
    u.info[1] = float(lists->grid.slices);
    u.info[3] = float(clusterTexels);
}

}  // namespace fa::render
