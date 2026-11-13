// Voxel binding: the surface is rasterised into a grid (a thin shell of voxels, dilated by one so it is connected), the distance along the shell from
// each bone is measured with Dijkstra, and a node follows the bones that are nearly as close, along the surface, as the closest one. It does not need a
// manifold, closed or consistently oriented mesh, so it is the fallback for what bone heat cannot solve and a choice of the document for meshes
// that are broken in those ways. Deterministic: a fixed grid, ties in the queue broken by voxel index.
#include <algorithm>
#include <cmath>
#include <queue>

#include "rig_skin_internal.h"

namespace fa::rig_skin_detail {

void solve_voxel(const Weld& weld, const std::vector<std::uint64_t>& mask, const std::vector<Seg>& bones,
                 double locality, std::vector<Infl>& out, VoxelStats& stats) {
    const std::size_t nn = weld.nodes();
    out.assign(nn, {});
    if (nn == 0 || bones.empty()) return;
    Vec3 lo = weld.pos[0], hi = weld.pos[0];
    for (const Vec3& p : weld.pos) {
        lo = {std::min(lo.x, p.x), std::min(lo.y, p.y), std::min(lo.z, p.z)};
        hi = {std::max(hi.x, p.x), std::max(hi.y, p.y), std::max(hi.z, p.z)};
    }
    const Vec3 ext = hi - lo;
    const float longest = std::max({ext.x, ext.y, ext.z, 1e-6f});
    const int res = 72;
    stats.resolution = res;
    const float h = longest / float(res);
    const int nx = int(ext.x / h) + 3, ny = int(ext.y / h) + 3, nz = int(ext.z / h) + 3;
    const std::size_t total = std::size_t(nx) * std::size_t(ny) * std::size_t(nz);
    auto cell = [&](Vec3 p, int& x, int& y, int& z) {
        x = std::clamp(int((p.x - lo.x) / h) + 1, 0, nx - 1);
        y = std::clamp(int((p.y - lo.y) / h) + 1, 0, ny - 1);
        z = std::clamp(int((p.z - lo.z) / h) + 1, 0, nz - 1);
    };
    auto index = [&](int x, int y, int z) {
        return (std::size_t(z) * std::size_t(ny) + std::size_t(y)) * std::size_t(nx) + std::size_t(x);
    };
    auto centre = [&](std::size_t i) {
        const int x = int(i % std::size_t(nx)), y = int((i / std::size_t(nx)) % std::size_t(ny)),
                  z = int(i / (std::size_t(nx) * std::size_t(ny)));
        return Vec3{lo.x + (float(x) - 0.5f) * h, lo.y + (float(y) - 0.5f) * h, lo.z + (float(z) - 0.5f) * h};
    };

    // the shell: voxels that hold samples of a triangle, spaced at half a voxel, plus every node
    std::vector<char> shell(total, 0);
    auto mark = [&](Vec3 p) {
        int x, y, z;
        cell(p, x, y, z);
        shell[index(x, y, z)] = 1;
    };
    for (const auto& t : weld.tris) {
        const Vec3 a = weld.pos[t[0]], b = weld.pos[t[1]], c = weld.pos[t[2]];
        const float longestEdge = std::max({length(b - a), length(c - b), length(a - c)});
        const int k = std::clamp(int(std::ceil(longestEdge / (0.5f * h))), 1, 160);
        for (int i = 0; i <= k; ++i)
            for (int j = 0; j <= k - i; ++j) {
                const float u = float(i) / float(k), v = float(j) / float(k);
                mark(a * (1 - u - v) + b * u + c * v);
            }
    }
    for (const Vec3& p : weld.pos) mark(p);
    std::vector<char> walk(total, 0);
    std::uint32_t voxels = 0;
    for (int z = 0; z < nz; ++z)
        for (int y = 0; y < ny; ++y)
            for (int x = 0; x < nx; ++x) {
                if (!shell[index(x, y, z)]) continue;
                for (int dz = -1; dz <= 1; ++dz)
                    for (int dy = -1; dy <= 1; ++dy)
                        for (int dx = -1; dx <= 1; ++dx) {
                            const int X = x + dx, Y = y + dy, Z = z + dz;
                            if (X < 0 || Y < 0 || Z < 0 || X >= nx || Y >= ny || Z >= nz) continue;
                            walk[index(X, Y, Z)] = 1;
                        }
            }
    for (char c : walk) voxels += c ? 1u : 0u;
    stats.voxels = voxels;

    const std::uint64_t allBones = ~std::uint64_t(0) >> (64 - std::min<std::size_t>(64, bones.size()));
    std::vector<std::size_t> nodeVoxel(nn);
    std::vector<std::uint64_t> owner(total, 0);
    for (std::size_t j = 0; j < nn; ++j) {
        int x, y, z;
        cell(weld.pos[j], x, y, z);
        nodeVoxel[j] = index(x, y, z);
        owner[nodeVoxel[j]] |= mask[j] ? mask[j] : allBones;
    }
    std::vector<std::size_t> ownerList;
    for (std::size_t v = 0; v < total; ++v)
        if (owner[v]) ownerList.push_back(v);

    struct Item {
        float d;
        std::size_t v;
        bool operator>(const Item& o) const { return d > o.d || (d == o.d && v > o.v); }
    };
    constexpr float kInf = 1e30f;
    std::vector<std::vector<std::pair<std::uint16_t, float>>> nodeDist(nn);
    std::vector<float> dist(total);
    for (std::size_t bone = 0; bone < bones.size(); ++bone) {
        std::vector<std::size_t> seeds;
        float dmin = kInf;
        std::vector<float> seedD;
        for (std::size_t v : ownerList)
            if (owner[v] >> bone & 1) {
                const float d = std::sqrt(seg_dist2(centre(v), bones[bone]));
                seeds.push_back(v);
                seedD.push_back(d);
                dmin = std::min(dmin, d);
            }
        if (seeds.empty()) continue;
        std::fill(dist.begin(), dist.end(), kInf);
        std::priority_queue<Item, std::vector<Item>, std::greater<Item>> queue;
        for (std::size_t s = 0; s < seeds.size(); ++s)
            if (seedD[s] <= dmin + h) {
                dist[seeds[s]] = seedD[s] - dmin;
                queue.push({dist[seeds[s]], seeds[s]});
            }
        while (!queue.empty()) {
            const Item it = queue.top();
            queue.pop();
            if (it.d > dist[it.v]) continue;
            const int x = int(it.v % std::size_t(nx)), y = int((it.v / std::size_t(nx)) % std::size_t(ny)),
                      z = int(it.v / (std::size_t(nx) * std::size_t(ny)));
            for (int dz = -1; dz <= 1; ++dz)
                for (int dy = -1; dy <= 1; ++dy)
                    for (int dx = -1; dx <= 1; ++dx) {
                        if (!dx && !dy && !dz) continue;
                        const int X = x + dx, Y = y + dy, Z = z + dz;
                        if (X < 0 || Y < 0 || Z < 0 || X >= nx || Y >= ny || Z >= nz) continue;
                        const std::size_t w = index(X, Y, Z);
                        if (!walk[w]) continue;
                        const int axes = std::abs(dx) + std::abs(dy) + std::abs(dz);
                        const float step = h * (axes == 1 ? 1.0f : (axes == 2 ? 1.41421356f : 1.7320508f));
                        const float nd = it.d + step;
                        if (nd < dist[w]) {
                            dist[w] = nd;
                            queue.push({nd, w});
                        }
                    }
        }
        for (std::size_t j = 0; j < nn; ++j) {
            const std::uint64_t m = mask[j] ? mask[j] : allBones;
            if ((m >> bone & 1) && dist[nodeVoxel[j]] < kInf)
                nodeDist[j].push_back({std::uint16_t(bone), dist[nodeVoxel[j]]});
        }
    }
    const double loc = std::sqrt(std::max(locality, 0.01));
    for (std::size_t j = 0; j < nn; ++j) {
        if (nodeDist[j].empty()) continue;
        float dmin = kInf;
        for (const auto& e : nodeDist[j]) dmin = std::min(dmin, e.second);
        const std::uint64_t m = mask[j] ? mask[j] : allBones;
        float eu = kInf;
        for (std::size_t bone = 0; bone < bones.size(); ++bone)
            if (m >> bone & 1) eu = std::min(eu, seg_dist2(weld.pos[j], bones[bone]));
        const float r = std::max(2.5f * h, 1.2f * std::sqrt(eu)) / float(loc);
        for (const auto& e : nodeDist[j]) {
            const float f = std::max(0.0f, 1.0f - (e.second - dmin) / r);
            if (f > 1e-4f) out[j].push_back({e.first, f * f});
        }
        normalize_infl(out[j], 1e-4f);
    }
}

}  // namespace fa::rig_skin_detail
