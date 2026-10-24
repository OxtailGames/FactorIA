// The navigation grid of NavMesh3D: spans, links, erosion, regions, A*, string pulling and moving obstacles.
#include "nav_grid.h"

#include <algorithm>
#include <cmath>
#include <numeric>
#include <queue>

namespace fa::detail {

namespace {

constexpr float kEps = 1e-4f;
constexpr float kInf = 1e30f;
constexpr float kSqrt2 = 1.41421356f;
// Directions 0..3 are orthogonal (+x, +z, -x, -z), 4..7 diagonal ((+,+), (-,+), (-,-), (+,-)).
constexpr int kDx[8] = {1, 0, -1, 0, 1, -1, -1, 1};
constexpr int kDz[8] = {0, 1, 0, -1, 1, 1, -1, -1};
// The two orthogonal directions a diagonal one is made of.
constexpr int kDiagA[4] = {0, 2, 2, 0};  // along x
constexpr int kDiagB[4] = {1, 1, 3, 3};  // along z

}  // namespace

float NavGrid::quantize(float y) const { return std::round(y / p_.cellHeight) * p_.cellHeight; }

int NavGrid::cell_at(float x, float z) const {
    const int ix = int(std::floor((x - p_.origin.x) / p_.cell));
    const int iz = int(std::floor((z - p_.origin.z) / p_.cell));
    if (ix < 0 || iz < 0 || ix >= p_.nx || iz >= p_.nz) return -1;
    return iz * p_.nx + ix;
}

bool NavGrid::inside(Vec3 p) const {
    return p.x >= p_.origin.x && p.x <= p_.origin.x + float(p_.nx) * p_.cell && p.z >= p_.origin.z &&
           p.z <= p_.origin.z + float(p_.nz) * p_.cell && p.y >= p_.yMin && p.y <= p_.yMax;
}

Vec3 NavGrid::center(int s) const {
    const Span& sp = spans_[std::size_t(s)];
    return {p_.origin.x + (float(cell_x(sp.cell)) + 0.5f) * p_.cell, sp.y,
            p_.origin.z + (float(cell_z(sp.cell)) + 0.5f) * p_.cell};
}

// ------------------------------------------------------------------ build ----
void NavGrid::build(const NavParams& params, std::vector<NavEntry>& entries) {
    p_ = params;
    spans_.clear();
    links_.clear();
    obstacles_.clear();
    const std::size_t ncell = std::size_t(p_.nx) * std::size_t(p_.nz);
    cellFirst_.assign(ncell + 1, 0);
    std::sort(entries.begin(), entries.end(), [](const NavEntry& a, const NavEntry& b) {
        if (a.cell != b.cell) return a.cell < b.cell;
        if (a.solid.bottom != b.solid.bottom) return a.solid.bottom < b.solid.bottom;
        if (a.solid.top != b.solid.top) return a.solid.top < b.solid.top;
        return a.solid.topNormalY < b.solid.topNormalY;
    });
    const float minNormalY = det::cos(p_.maxSlopeDeg * 3.14159265f / 180.0f) - kEps;
    std::size_t at = 0;
    std::vector<NavSolid> merged;
    for (std::size_t c = 0; c < ncell; ++c) {
        cellFirst_[c] = std::int32_t(spans_.size());
        merged.clear();
        for (; at < entries.size() && std::size_t(entries[at].cell) == c; ++at) {
            const NavSolid& s = entries[at].solid;
            if (!merged.empty() && s.bottom <= merged.back().top + kEps) {
                NavSolid& m = merged.back();
                if (s.top > m.top + kEps) {
                    m.top = s.top;
                    m.topNormalY = s.topNormalY;
                } else if (s.top >= m.top - kEps) {
                    m.topNormalY = std::max(m.topNormalY, s.topNormalY);
                }
            } else {
                merged.push_back(s);
            }
        }
        for (std::size_t i = 0; i < merged.size(); ++i) {
            const NavSolid& m = merged[i];
            if (m.top > p_.yMax + kEps || m.top < p_.yMin - kEps || m.topNormalY < minNormalY) continue;
            const float ceil = i + 1 < merged.size() ? merged[i + 1].bottom : kInf;
            if (ceil - m.top < p_.height - kEps) continue;
            Span sp;
            sp.y = quantize(m.top);
            sp.ceil = ceil;
            sp.cell = std::int32_t(c);
            spans_.push_back(sp);
        }
    }
    cellFirst_[ncell] = std::int32_t(spans_.size());
    entries.clear();
    entries.shrink_to_fit();
    make_links();
    erode();
    make_regions();
    g_.assign(spans_.size(), 0.0f);
    parent_.assign(spans_.size(), -1);
    stamp_.assign(spans_.size(), 0);
    closed_.assign(spans_.size(), 0);
    stampNow_ = 0;
}

// The span of cell (nx, nz) that `s` can walk onto: the nearest in height within the step, with room to pass.
int NavGrid::pick_neighbour(int s, int nx, int nz) const {
    if (nx < 0 || nz < 0 || nx >= p_.nx || nz >= p_.nz) return -1;
    const Span& a = spans_[std::size_t(s)];
    const int c = nz * p_.nx + nx;
    int best = -1;
    float bestDy = kInf;
    for (int n = cellFirst_[std::size_t(c)]; n < cellFirst_[std::size_t(c) + 1]; ++n) {
        const Span& b = spans_[std::size_t(n)];
        const float dy = std::fabs(b.y - a.y);
        if (dy > p_.step + kEps) continue;
        if (std::min(a.ceil, b.ceil) - std::max(a.y, b.y) < p_.height - kEps) continue;
        if (dy < bestDy) {
            bestDy = dy;
            best = n;
        }
    }
    return best;
}

void NavGrid::make_links() {
    links_.assign(spans_.size() * 8, -1);
    for (int s = 0; s < int(spans_.size()); ++s) {
        const int ix = cell_x(spans_[std::size_t(s)].cell), iz = cell_z(spans_[std::size_t(s)].cell);
        for (int d = 0; d < 4; ++d) links_[std::size_t(s) * 8 + std::size_t(d)] = pick_neighbour(s, ix + kDx[d], iz + kDz[d]);
    }
    // Diagonals only when both sides are walkable too: a path never cuts a corner.
    for (int s = 0; s < int(spans_.size()); ++s) {
        const int ix = cell_x(spans_[std::size_t(s)].cell), iz = cell_z(spans_[std::size_t(s)].cell);
        for (int k = 0; k < 4; ++k) {
            const int d = 4 + k;
            const int pa = link(s, kDiagA[k]), pb = link(s, kDiagB[k]);
            if (pa < 0 || pb < 0) continue;
            if (link(pa, kDiagB[k]) < 0 || link(pb, kDiagA[k]) < 0) continue;
            links_[std::size_t(s) * 8 + std::size_t(d)] = pick_neighbour(s, ix + kDx[d], iz + kDz[d]);
        }
    }
}

// Erosion: distance (over the links) from every span to the nearest missing neighbour, which is a wall or a drop; spans
// closer than the agent's radius cannot be stood on. A span at the edge is half a cell from what is missing.
void NavGrid::erode() {
    std::vector<float> dist(spans_.size(), kInf);
    using Item = std::pair<float, std::int32_t>;
    std::priority_queue<Item, std::vector<Item>, std::greater<Item>> open;
    for (int s = 0; s < int(spans_.size()); ++s) {
        float d = kInf;
        for (int k = 0; k < 4; ++k)
            if (link(s, k) < 0) d = std::min(d, 0.5f * p_.cell);
        for (int k = 4; k < 8; ++k)
            if (link(s, k) < 0) d = std::min(d, 0.70710678f * p_.cell);
        if (d < kInf) {
            dist[std::size_t(s)] = d;
            open.push({d, s});
        }
    }
    while (!open.empty()) {
        const auto [d, s] = open.top();
        open.pop();
        if (d > dist[std::size_t(s)]) continue;
        for (int k = 0; k < 8; ++k) {
            const int n = link(s, k);
            if (n < 0) continue;
            const float nd = d + (k < 4 ? p_.cell : p_.cell * kSqrt2);
            if (nd < dist[std::size_t(n)]) {
                dist[std::size_t(n)] = nd;
                open.push({nd, n});
            }
        }
    }
    for (std::size_t s = 0; s < spans_.size(); ++s) spans_[s].eroded = dist[s] < p_.radius - 1e-5f;
}

void NavGrid::make_regions() {
    std::vector<std::int32_t> parent(spans_.size());
    std::iota(parent.begin(), parent.end(), 0);
    auto find = [&](std::int32_t x) {
        while (parent[std::size_t(x)] != x) {
            parent[std::size_t(x)] = parent[std::size_t(parent[std::size_t(x)])];
            x = parent[std::size_t(x)];
        }
        return x;
    };
    walkable_ = 0;
    for (int s = 0; s < int(spans_.size()); ++s) {
        if (spans_[std::size_t(s)].eroded) continue;
        ++walkable_;
        for (int k = 0; k < 8; ++k) {
            const int n = link(s, k);
            if (n < 0 || spans_[std::size_t(n)].eroded) continue;
            const std::int32_t ra = find(s), rb = find(n);
            if (ra != rb) parent[std::size_t(std::max(ra, rb))] = std::min(ra, rb);
        }
    }
    regions_ = 0;
    std::vector<std::int32_t> ids(spans_.size(), 0);
    for (int s = 0; s < int(spans_.size()); ++s) {
        Span& sp = spans_[std::size_t(s)];
        if (sp.eroded) {
            sp.region = 0;
            continue;
        }
        const std::int32_t r = find(s);
        if (ids[std::size_t(r)] == 0) ids[std::size_t(r)] = ++regions_;
        sp.region = ids[std::size_t(r)];
    }
}

// ---------------------------------------------------------------- queries ----
int NavGrid::find_span(Vec3 p, float reachDown, float reachUp) const {
    const int c = cell_at(p.x, p.z);
    if (c < 0) return -1;
    int best = -1;
    for (int s = cellFirst_[std::size_t(c)]; s < cellFirst_[std::size_t(c) + 1]; ++s) {
        if (!usable(s)) continue;
        const float y = spans_[std::size_t(s)].y;
        if (y < p.y - reachDown - kEps || y > p.y + reachUp + kEps) continue;
        if (best < 0 || y > spans_[std::size_t(best)].y) best = s;
    }
    return best;
}

int NavGrid::nearest_span(Vec3 p, float reachDown, float reachUp, float maxDist, float* dist) const {
    const int R = int(std::ceil(maxDist / p_.cell)) + 1;
    const int cx = int(std::floor((p.x - p_.origin.x) / p_.cell));
    const int cz = int(std::floor((p.z - p_.origin.z) / p_.cell));
    int best = -1;
    float bestD = kInf;
    for (int dz = -R; dz <= R; ++dz) {
        for (int dx = -R; dx <= R; ++dx) {
            const int ix = cx + dx, iz = cz + dz;
            if (ix < 0 || iz < 0 || ix >= p_.nx || iz >= p_.nz) continue;
            const int c = iz * p_.nx + ix;
            for (int s = cellFirst_[std::size_t(c)]; s < cellFirst_[std::size_t(c) + 1]; ++s) {
                if (!usable(s)) continue;
                const Vec3 q = center(s);
                if (q.y < p.y - reachDown - kEps || q.y > p.y + reachUp + kEps) continue;
                const float d = std::sqrt((q.x - p.x) * (q.x - p.x) + (q.z - p.z) * (q.z - p.z));
                if (d > maxDist + kEps) continue;
                if (d < bestD - 1e-6f) {
                    bestD = d;
                    best = s;
                }
            }
        }
    }
    if (best >= 0 && dist) *dist = bestD;
    return best;
}

int NavGrid::nearest_anywhere(Vec3 p, float* dist) const {
    int best = -1;
    float bestD = kInf;
    for (int s = 0; s < int(spans_.size()); ++s) {
        if (!usable(s)) continue;
        const float d = length_sq(center(s) - p);
        if (d < bestD) {
            bestD = d;
            best = s;
        }
    }
    if (best >= 0 && dist) *dist = std::sqrt(bestD);
    return best;
}

std::vector<int> NavGrid::search(int start, int goal, int* closest) const {
    struct Item {
        float f, h, g;
        std::int32_t idx;
    };
    struct Later {
        bool operator()(const Item& a, const Item& b) const {
            if (a.f != b.f) return a.f > b.f;
            if (a.h != b.h) return a.h > b.h;
            return a.idx > b.idx;
        }
    };
    ++stampNow_;
    const Vec3 gc = center(goal);
    auto heuristic = [&](int s) {
        const Vec3 c = center(s);
        const float dx = std::fabs(c.x - gc.x), dz = std::fabs(c.z - gc.z);
        return (dx + dz) + (kSqrt2 - 2.0f) * std::min(dx, dz);
    };
    std::priority_queue<Item, std::vector<Item>, Later> open;
    g_[std::size_t(start)] = 0.0f;
    parent_[std::size_t(start)] = -1;
    stamp_[std::size_t(start)] = stampNow_;
    open.push({heuristic(start), heuristic(start), 0.0f, start});
    int nearest = start;
    float nearestH = heuristic(start);
    bool reached = false;
    while (!open.empty()) {
        const Item it = open.top();
        open.pop();
        const std::size_t s = std::size_t(it.idx);
        if (closed_[s] == stampNow_ || it.g > g_[s]) continue;
        closed_[s] = stampNow_;
        if (it.idx == goal) {
            reached = true;
            break;
        }
        if (it.h < nearestH - 1e-6f) {
            nearestH = it.h;
            nearest = it.idx;
        }
        const Vec3 a = center(it.idx);
        for (int k = 0; k < 8; ++k) {
            const int n = link(it.idx, k);
            if (n < 0 || !usable(n) || closed_[std::size_t(n)] == stampNow_) continue;
            const Vec3 b = center(n);
            const float hd = k < 4 ? p_.cell : p_.cell * kSqrt2;
            const float dy = b.y - a.y;
            const float ng = it.g + std::sqrt(hd * hd + dy * dy);
            const std::size_t ni = std::size_t(n);
            if (stamp_[ni] == stampNow_ && ng >= g_[ni]) continue;
            stamp_[ni] = stampNow_;
            g_[ni] = ng;
            parent_[ni] = it.idx;
            const float h = heuristic(n);
            open.push({ng + h, h, ng, n});
        }
    }
    std::vector<int> chain;
    if (!reached) {
        if (closest) *closest = nearest;
        return chain;
    }
    for (int s = goal; s >= 0; s = parent_[std::size_t(s)]) chain.push_back(s);
    std::reverse(chain.begin(), chain.end());
    return chain;
}

bool NavGrid::line_clear(int a, int b) const {
    const Vec3 A = center(a), B = center(b);
    const float len = std::sqrt((B.x - A.x) * (B.x - A.x) + (B.z - A.z) * (B.z - A.z));
    const int n = std::max(1, int(std::ceil(len / (p_.cell * 0.25f))));
    const float tol = p_.step * 0.5f + p_.cellHeight;
    // The usable span of cell (ix, iz) nearest in height to `y`, or -1 when none is within the tolerance.
    auto near_span = [&](int ix, int iz, float y) {
        if (ix < 0 || iz < 0 || ix >= p_.nx || iz >= p_.nz) return -1;
        const int c = iz * p_.nx + ix;
        int best = -1;
        float bestDy = kInf;
        for (int s = cellFirst_[std::size_t(c)]; s < cellFirst_[std::size_t(c) + 1]; ++s) {
            if (!usable(s)) continue;
            const float dy = std::fabs(spans_[std::size_t(s)].y - y);
            if (dy <= tol && dy < bestDy) {
                bestDy = dy;
                best = s;
            }
        }
        return best;
    };
    int px = cell_x(spans_[std::size_t(a)].cell), pz = cell_z(spans_[std::size_t(a)].cell);
    float prevY = A.y;
    for (int i = 1; i <= n; ++i) {
        const float t = float(i) / float(n);
        const float x = A.x + (B.x - A.x) * t, z = A.z + (B.z - A.z) * t, want = A.y + (B.y - A.y) * t;
        const int ix = int(std::floor((x - p_.origin.x) / p_.cell)), iz = int(std::floor((z - p_.origin.z) / p_.cell));
        if (ix == px && iz == pz) continue;
        if (ix != px && iz != pz) {  // crossing a corner: the two cells beside it must be walkable too
            if (near_span(ix, pz, want) < 0 || near_span(px, iz, want) < 0) return false;
        }
        const int s = near_span(ix, iz, want);
        if (s < 0 || std::fabs(spans_[std::size_t(s)].y - prevY) > p_.step + kEps) return false;
        prevY = spans_[std::size_t(s)].y;
        px = ix;
        pz = iz;
    }
    return true;
}

std::vector<int> NavGrid::pull(const std::vector<int>& chain) const {
    if (chain.size() <= 2) return chain;
    std::vector<int> out{chain.front()};
    std::size_t i = 0;
    while (i + 1 < chain.size()) {
        std::size_t j = chain.size() - 1;
        while (j > i + 1 && !line_clear(chain[i], chain[j])) --j;
        out.push_back(chain[j]);
        i = j;
    }
    return out;
}

// -------------------------------------------------------------- obstacles ----
void NavGrid::clear_obstacle(std::uint64_t key) {
    auto it = obstacles_.find(key);
    if (it == obstacles_.end()) return;
    for (std::int32_t s : it->second) --spans_[std::size_t(s)].block;
    obstacles_.erase(it);
}

void NavGrid::set_obstacle(std::uint64_t key, const std::vector<Footprint>& footprint) {
    clear_obstacle(key);
    const float reach = p_.radius + 0.5f * p_.cell;
    const int R = int(std::ceil(reach / p_.cell));
    std::vector<std::int32_t> hit;
    for (const Footprint& f : footprint) {
        const int fx = cell_x(f.cell), fz = cell_z(f.cell);
        for (int dz = -R; dz <= R; ++dz) {
            for (int dx = -R; dx <= R; ++dx) {
                if (std::sqrt(float(dx * dx + dz * dz)) * p_.cell >= reach + kEps && (dx != 0 || dz != 0)) continue;
                const int ix = fx + dx, iz = fz + dz;
                if (ix < 0 || iz < 0 || ix >= p_.nx || iz >= p_.nz) continue;
                const int c = iz * p_.nx + ix;
                for (int s = cellFirst_[std::size_t(c)]; s < cellFirst_[std::size_t(c) + 1]; ++s) {
                    const Span& sp = spans_[std::size_t(s)];
                    if (sp.eroded) continue;
                    if (f.bottom < sp.y + p_.height && f.top > sp.y + 0.5f * p_.cellHeight) hit.push_back(s);
                }
            }
        }
    }
    std::sort(hit.begin(), hit.end());
    hit.erase(std::unique(hit.begin(), hit.end()), hit.end());
    for (std::int32_t s : hit) ++spans_[std::size_t(s)].block;
    obstacles_[key] = std::move(hit);
}

}  // namespace fa::detail
