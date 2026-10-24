// The navigation grid of NavMesh3D: spans, links, erosion, regions, A*, string pulling and moving obstacles.
#include "nav_grid.h"

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <iterator>
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

template <class F>
void NavGrid::each_in_cell(int c, F&& f) const {
    for (int s = cellFirst_[std::size_t(c)]; s < cellFirst_[std::size_t(c) + 1]; ++s) f(s);
    if (!dynHead_.empty())
        for (int s = dynHead_[std::size_t(c)]; s >= 0; s = dyn_[std::size_t(s) - spans_.size()].next) f(s);
}

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
    const Span& a = sp(s);
    return {p_.origin.x + (float(cell_x(a.cell)) + 0.5f) * p_.cell, a.y,
            p_.origin.z + (float(cell_z(a.cell)) + 0.5f) * p_.cell};
}

// ------------------------------------------------------------------ build ----
void NavGrid::build(const NavParams& params, std::vector<NavEntry>& entries) {
    p_ = params;
    spans_.clear();
    links_.clear();
    obstacles_.clear();
    walk_.clear();
    dyn_.clear();
    dynFree_.clear();
    dynHead_.clear();
    dirty_.clear();
    dynLive_ = 0;
    links_edges_.clear();
    linkFirst_.clear();
    cellMark_.clear();
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
    parentLink_.assign(spans_.size(), -1);
    stamp_.assign(spans_.size(), 0);
    closed_.assign(spans_.size(), 0);
    edist_.assign(spans_.size(), 0.0f);
    edistStamp_.assign(spans_.size(), 0);
    stampNow_ = 0;
    edistNow_ = 0;
}

void NavGrid::scratch_resize() {
    const std::size_t n = spans_.size() + dyn_.size();
    g_.resize(n, 0.0f);
    parent_.resize(n, -1);
    parentLink_.resize(n, -1);
    stamp_.resize(n, 0);
    closed_.resize(n, 0);
    edist_.resize(n, 0.0f);
    edistStamp_.resize(n, 0);
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
    for (std::size_t s = 0; s < spans_.size(); ++s) {
        spans_[s].eroded = dist[s] < p_.radius - 1e-5f;
        spans_[s].erodedBase = spans_[s].eroded;
    }
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
    auto join = [&](int a, int b) {
        const std::int32_t ra = find(a), rb = find(b);
        if (ra != rb) parent[std::size_t(std::max(ra, rb))] = std::min(ra, rb);
    };
    for (int s = 0; s < int(spans_.size()); ++s) {
        if (spans_[std::size_t(s)].erodedBase) continue;
        ++walkable_;
        for (int k = 0; k < 8; ++k) {
            const int n = link(s, k);
            if (n < 0 || spans_[std::size_t(n)].erodedBase) continue;
            join(s, n);
        }
    }
    for (const LinkEdge& e : links_edges_)  // an off-mesh link joins two areas (even a one-way one: it is a way across)
        if (!spans_[std::size_t(e.from)].erodedBase && !spans_[std::size_t(e.to)].erodedBase) join(e.from, e.to);
    regions_ = 0;
    std::vector<std::int32_t> ids(spans_.size(), 0);
    for (int s = 0; s < int(spans_.size()); ++s) {
        Span& a = spans_[std::size_t(s)];
        if (a.erodedBase) {
            a.region = 0;
            continue;
        }
        const std::int32_t r = find(s);
        if (ids[std::size_t(r)] == 0) ids[std::size_t(r)] = ++regions_;
        a.region = ids[std::size_t(r)];
    }
}

// -------------------------------------------------------------- neighbours ----
// The span of cell `c` that `s` can walk onto: the nearest in height within the step, with room to pass. `dynOnly` /
// `staticOnly` limit the candidates to one kind.
int NavGrid::pick_in_cell(int s, int c, bool dynOnly, bool staticOnly) const {
    const Span& a = sp(s);
    int best = -1;
    float bestDy = kInf;
    each_in_cell(c, [&](int n) {
        const bool isDyn = std::size_t(n) >= spans_.size();
        if ((dynOnly && !isDyn) || (staticOnly && isDyn) || n == s) return;
        const Span& b = sp(n);
        if (!b.alive) return;
        const float dy = std::fabs(b.y - a.y);
        if (dy > p_.step + kEps) return;
        if (std::min(a.ceil, b.ceil) - std::max(a.y, b.y) < p_.height - kEps) return;
        if (dy < bestDy) {
            bestDy = dy;
            best = n;
        }
    });
    return best;
}

int NavGrid::neighbours(int s, int dir, int out[2]) const {
    int n = 0;
    const bool isStatic = std::size_t(s) < spans_.size();
    if (isStatic) {
        const int l = link(s, dir);
        if (l >= 0) out[n++] = l;
        if (dynLive_ == 0) return n;
    }
    const Span& a = sp(s);
    const int ix = cell_x(a.cell) + kDx[dir], iz = cell_z(a.cell) + kDz[dir];
    if (ix < 0 || iz < 0 || ix >= p_.nx || iz >= p_.nz) return n;
    const int c = iz * p_.nx + ix;
    const int bakedCount = n;
    if (!isStatic) {
        const int b = pick_in_cell(s, c, false, true);
        if (b >= 0) out[n++] = b;
    }
    if (!dynHead_.empty() && dynHead_[std::size_t(c)] >= 0) {
        const int d = pick_in_cell(s, c, true, false);
        if (d >= 0) out[n++] = d;
    }
    if (dir >= 4 && n > bakedCount) {  // a diagonal step needs both sides to be walkable too: a path never cuts a corner
        int tmp[2];
        if (neighbours(s, kDiagA[dir - 4], tmp) == 0 || neighbours(s, kDiagB[dir - 4], tmp) == 0) n = bakedCount;
    }
    return n;
}

// ---------------------------------------------------------------- queries ----
int NavGrid::find_span(Vec3 p, float reachDown, float reachUp, bool staticOnly) const {
    const int c = cell_at(p.x, p.z);
    if (c < 0) return -1;
    int best = -1;
    each_in_cell(c, [&](int s) {
        if (staticOnly ? (std::size_t(s) >= spans_.size() || spans_[std::size_t(s)].erodedBase) : !usable(s)) return;
        const float y = sp(s).y;
        if (y < p.y - reachDown - kEps || y > p.y + reachUp + kEps) return;
        if (best < 0 || y > sp(best).y) best = s;
    });
    return best;
}

int NavGrid::nearest_span(Vec3 p, float reachDown, float reachUp, float maxDist, float* dist, bool staticOnly) const {
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
            each_in_cell(c, [&](int s) {
                if (staticOnly ? (std::size_t(s) >= spans_.size() || spans_[std::size_t(s)].erodedBase) : !usable(s)) return;
                const Vec3 q = center(s);
                if (q.y < p.y - reachDown - kEps || q.y > p.y + reachUp + kEps) return;
                const float d = std::sqrt((q.x - p.x) * (q.x - p.x) + (q.z - p.z) * (q.z - p.z));
                if (d > maxDist + kEps) return;
                if (d < bestD - 1e-6f) {
                    bestD = d;
                    best = s;
                }
            });
        }
    }
    if (best >= 0 && dist) *dist = bestD;
    return best;
}

int NavGrid::nearest_anywhere(Vec3 p, float* dist) const {
    int best = -1;
    float bestD = kInf;
    for (int s = 0; s < total_count(); ++s) {
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

std::vector<int> NavGrid::search(int start, int goal, int* closest, std::vector<int>* viaLink) const {
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
    parentLink_[std::size_t(start)] = -1;
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
        auto relax = [&](int n, float stepLen, int via) {
            if (n < 0 || !usable(n) || closed_[std::size_t(n)] == stampNow_) return;
            const Vec3 b = center(n);
            const float dy = b.y - a.y;
            const float ng = it.g + std::sqrt(stepLen * stepLen + dy * dy);
            const std::size_t ni = std::size_t(n);
            if (stamp_[ni] == stampNow_ && ng >= g_[ni]) return;
            stamp_[ni] = stampNow_;
            g_[ni] = ng;
            parent_[ni] = it.idx;
            parentLink_[ni] = via;
            const float h = heuristic(n);
            open.push({ng + h, h, ng, n});
        };
        for (int k = 0; k < 8; ++k) {
            const float hd = k < 4 ? p_.cell : p_.cell * kSqrt2;
            int nb[2];
            const int cnt = neighbours(it.idx, k, nb);
            for (int i = 0; i < cnt; ++i) relax(nb[i], hd, -1);
        }
        if (s < spans_.size() && !linkFirst_.empty()) {
            for (std::int32_t e = linkFirst_[s]; e < linkFirst_[s + 1]; ++e) {
                const LinkEdge& le = links_edges_[std::size_t(e)];
                const Vec3 b = center(le.to);
                const float flat = std::sqrt((b.x - a.x) * (b.x - a.x) + (b.z - a.z) * (b.z - a.z));
                relax(le.to, flat + le.cost, le.id);
            }
        }
    }
    std::vector<int> chain;
    if (!reached) {
        if (closest) *closest = nearest;
        return chain;
    }
    for (int s = goal; s >= 0; s = parent_[std::size_t(s)]) chain.push_back(s);
    std::reverse(chain.begin(), chain.end());
    if (viaLink) {
        viaLink->assign(chain.size(), -1);
        for (std::size_t i = 1; i < chain.size(); ++i) (*viaLink)[i] = parentLink_[std::size_t(chain[i])];
    }
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
        each_in_cell(c, [&](int s) {
            if (!usable(s)) return;
            const float dy = std::fabs(sp(s).y - y);
            if (dy <= tol && dy < bestDy) {
                bestDy = dy;
                best = s;
            }
        });
        return best;
    };
    int px = cell_x(sp(a).cell), pz = cell_z(sp(a).cell);
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
        if (s < 0 || std::fabs(sp(s).y - prevY) > p_.step + kEps) return false;
        prevY = sp(s).y;
        px = ix;
        pz = iz;
    }
    return true;
}

std::vector<int> NavGrid::pull(const std::vector<int>& chain, const std::vector<int>* viaLink,
                               std::vector<int>* cornerLink) const {
    std::vector<int> out;
    if (cornerLink) cornerLink->clear();
    // Pull each stretch between two links on its own: a link is a jump, not a straight walk.
    std::size_t begin = 0;
    while (begin < chain.size()) {
        std::size_t end = begin + 1;
        while (end < chain.size() && !(viaLink && (*viaLink)[end] >= 0)) ++end;
        std::vector<int> part(chain.begin() + std::ptrdiff_t(begin), chain.begin() + std::ptrdiff_t(end));
        std::vector<int> kept;
        if (part.size() <= 2) {
            kept = part;
        } else {
            kept.push_back(part.front());
            std::size_t i = 0;
            while (i + 1 < part.size()) {
                std::size_t j = part.size() - 1;
                while (j > i + 1 && !line_clear(part[i], part[j])) --j;
                kept.push_back(part[j]);
                i = j;
            }
        }
        for (std::size_t k = 0; k < kept.size(); ++k) {
            out.push_back(kept[k]);
            if (cornerLink) cornerLink->push_back(k == 0 && viaLink ? (*viaLink)[begin] : -1);
        }
        begin = end;
    }
    return out;
}

// -------------------------------------------------------------- obstacles ----
void NavGrid::clear_obstacle(std::uint64_t key) {
    auto it = obstacles_.find(key);
    if (it == obstacles_.end()) return;
    for (const Ref& r : it->second) {
        Span& a = sp(r.span);
        if (a.gen == r.gen && a.alive) --a.block;
    }
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
                each_in_cell(c, [&](int s) {
                    const Span& a = sp(s);
                    if (a.eroded || !a.alive) return;
                    if (f.bottom < a.y + p_.height && f.top > a.y + 0.5f * p_.cellHeight) hit.push_back(s);
                });
            }
        }
    }
    std::sort(hit.begin(), hit.end());
    hit.erase(std::unique(hit.begin(), hit.end()), hit.end());
    std::vector<Ref> refs;
    refs.reserve(hit.size());
    for (std::int32_t s : hit) {
        ++sp(s).block;
        refs.push_back({s, sp(s).gen});
    }
    obstacles_[key] = std::move(refs);
}

// ------------------------------------------------------------------ links ----
void NavGrid::set_links(std::vector<LinkEdge> edges) {
    std::stable_sort(edges.begin(), edges.end(), [](const LinkEdge& a, const LinkEdge& b) {
        if (a.from != b.from) return a.from < b.from;
        return a.id < b.id;
    });
    links_edges_ = std::move(edges);
    linkFirst_.assign(spans_.size() + 1, 0);
    for (const LinkEdge& e : links_edges_) ++linkFirst_[std::size_t(e.from) + 1];
    for (std::size_t i = 1; i < linkFirst_.size(); ++i) linkFirst_[i] += linkFirst_[i - 1];
    make_regions();
}

// --------------------------------------------------------- walkable bodies ----
int NavGrid::alloc_dyn() {
    int id;
    if (!dynFree_.empty()) {
        auto low = std::min_element(dynFree_.begin(), dynFree_.end());
        id = *low;
        dynFree_.erase(low);
        Span& old = sp(id);
        const std::int32_t gen = old.gen + 1;
        old = Span{};
        old.gen = gen;
    } else {
        id = int(spans_.size() + dyn_.size());
        dyn_.push_back(Span{});
        scratch_resize();
    }
    Span& a = sp(id);
    a.dynamic = true;
    a.alive = true;
    a.region = 0;
    ++dynLive_;
    return id;
}

void NavGrid::free_dyn(int id) {
    Span& a = sp(id);
    if (!dynHead_.empty()) {  // unlink from its cell
        std::int32_t* at = &dynHead_[std::size_t(a.cell)];
        while (*at >= 0 && *at != id) at = &dyn_[std::size_t(*at) - spans_.size()].next;
        if (*at == id) *at = a.next;
    }
    dirty_.push_back(a.cell);
    a.alive = false;
    a.eroded = true;
    a.next = -1;
    dynFree_.push_back(id);
    --dynLive_;
}

void NavGrid::set_walkable(std::uint64_t key, const std::vector<NavEntry>& solids) {
    if (dynHead_.empty()) dynHead_.assign(std::size_t(p_.nx) * std::size_t(p_.nz), -1);
    // New top surfaces, per cell (the same merging and tests as the bake).
    std::vector<NavEntry> sorted = solids;
    std::sort(sorted.begin(), sorted.end(), [](const NavEntry& a, const NavEntry& b) {
        if (a.cell != b.cell) return a.cell < b.cell;
        if (a.solid.bottom != b.solid.bottom) return a.solid.bottom < b.solid.bottom;
        if (a.solid.top != b.solid.top) return a.solid.top < b.solid.top;
        return a.solid.topNormalY < b.solid.topNormalY;
    });
    const float minNormalY = det::cos(p_.maxSlopeDeg * 3.14159265f / 180.0f) - kEps;
    std::vector<DynSpec> specs;
    std::vector<NavSolid> merged;
    for (std::size_t at = 0; at < sorted.size();) {
        const std::int32_t c = sorted[at].cell;
        merged.clear();
        for (; at < sorted.size() && sorted[at].cell == c; ++at) {
            const NavSolid& sol = sorted[at].solid;
            if (!merged.empty() && sol.bottom <= merged.back().top + kEps) {
                NavSolid& m = merged.back();
                if (sol.top > m.top + kEps) {
                    m.top = sol.top;
                    m.topNormalY = sol.topNormalY;
                } else if (sol.top >= m.top - kEps) {
                    m.topNormalY = std::max(m.topNormalY, sol.topNormalY);
                }
            } else {
                merged.push_back(sol);
            }
        }
        for (std::size_t i = 0; i < merged.size(); ++i) {
            const NavSolid& m = merged[i];
            if (m.top > p_.yMax + kEps || m.top < p_.yMin - kEps || m.topNormalY < minNormalY) continue;
            const float ceil = i + 1 < merged.size() ? merged[i + 1].bottom : kInf;
            if (ceil - m.top < p_.height - kEps) continue;
            DynSpec d;
            d.cell = c;
            d.y = quantize(m.top);
            d.ceil = ceil;
            specs.push_back(d);
        }
    }
    // Static spans the body covers (it stands on them or over them): not walkable while it is there.
    std::vector<std::int32_t> blocked;
    for (const NavEntry& e : sorted) {
        for (int s = cellFirst_[std::size_t(e.cell)]; s < cellFirst_[std::size_t(e.cell) + 1]; ++s) {
            const Span& a = spans_[std::size_t(s)];
            if (a.erodedBase) continue;
            if (e.solid.bottom < a.y + p_.height && e.solid.top > a.y + 0.5f * p_.cellHeight) blocked.push_back(s);
        }
    }
    std::sort(blocked.begin(), blocked.end());
    blocked.erase(std::unique(blocked.begin(), blocked.end()), blocked.end());

    Walk& w = walk_[key];
    // Diff against the previous state: keep the spans that stay, free those that left, add those that entered.
    std::vector<DynSpec> next;
    next.reserve(specs.size());
    std::size_t oi = 0;
    auto before = [](const DynSpec& a, const DynSpec& b) { return a.cell != b.cell ? a.cell < b.cell : a.y < b.y; };
    std::vector<DynSpec> entered;
    for (std::size_t ni = 0; ni < specs.size();) {
        while (oi < w.specs.size() && before(w.specs[oi], specs[ni])) {
            free_dyn(w.specs[oi].span);
            ++oi;
        }
        if (oi < w.specs.size() && !before(specs[ni], w.specs[oi])) {  // same cell and height
            DynSpec keep = w.specs[oi];
            if (keep.ceil != specs[ni].ceil) {
                keep.ceil = specs[ni].ceil;
                sp(keep.span).ceil = keep.ceil;
                dirty_.push_back(keep.cell);
            }
            next.push_back(keep);
            ++oi;
            ++ni;
            continue;
        }
        entered.push_back(specs[ni]);
        ++ni;
    }
    for (; oi < w.specs.size(); ++oi) free_dyn(w.specs[oi].span);
    for (DynSpec d : entered) {
        const int id = alloc_dyn();
        Span& a = sp(id);
        a.y = d.y;
        a.ceil = d.ceil;
        a.cell = d.cell;
        // keep each cell's list ordered by (height, id)
        std::int32_t* at = &dynHead_[std::size_t(d.cell)];
        while (*at >= 0 && (dyn_[std::size_t(*at) - spans_.size()].y < a.y ||
                            (dyn_[std::size_t(*at) - spans_.size()].y == a.y && *at < id)))
            at = &dyn_[std::size_t(*at) - spans_.size()].next;
        a.next = *at;
        *at = id;
        d.span = id;
        dirty_.push_back(d.cell);
        next.push_back(d);
    }
    std::sort(next.begin(), next.end(), before);
    w.specs = std::move(next);
    // blocked statics: only the difference
    std::vector<std::int32_t> gone, added;
    std::set_difference(w.blocked.begin(), w.blocked.end(), blocked.begin(), blocked.end(), std::back_inserter(gone));
    std::set_difference(blocked.begin(), blocked.end(), w.blocked.begin(), w.blocked.end(), std::back_inserter(added));
    for (std::int32_t s : gone) --spans_[std::size_t(s)].block;
    for (std::int32_t s : added) ++spans_[std::size_t(s)].block;
    w.blocked = std::move(blocked);
}

void NavGrid::clear_walkable(std::uint64_t key) {
    auto it = walk_.find(key);
    if (it == walk_.end()) return;
    for (const DynSpec& d : it->second.specs) free_dyn(d.span);
    for (std::int32_t s : it->second.blocked) --spans_[std::size_t(s)].block;
    walk_.erase(it);
}

// The distance from a span to the nearest thing missing beside it (a wall or a drop), as the bake measures it.
float NavGrid::edge_distance(int s) const {
    float d = kInf;
    int tmp[2];
    for (int k = 0; k < 4; ++k)
        if (neighbours(s, k, tmp) == 0) d = std::min(d, 0.5f * p_.cell);
    for (int k = 4; k < 8; ++k)
        if (neighbours(s, k, tmp) == 0) d = std::min(d, 0.70710678f * p_.cell);
    return d;
}

// Redoes the erosion of every span that a change of the dynamic spans in `cells` can touch, and nothing else. The result
// is what a full erosion of the same grid would give: a span is affected when a neighbour of the changed cells is within
// the agent's radius of it, and the sources that reach it lie at most another radius away.
void NavGrid::erode_around(const std::vector<std::int32_t>& cells) {
    if (cells.empty()) return;
    const int rc = int(std::ceil(p_.radius / p_.cell));
    const int wide = 1 + 2 * rc, inner = 1 + rc;
    if (cellMark_.empty()) cellMark_.assign(std::size_t(p_.nx) * std::size_t(p_.nz), 0);
    std::vector<std::int32_t> big;
    for (std::int32_t c : cells) {
        const int cx = cell_x(c), cz = cell_z(c);
        for (int dz = -wide; dz <= wide; ++dz) {
            for (int dx = -wide; dx <= wide; ++dx) {
                const int ix = cx + dx, iz = cz + dz;
                if (ix < 0 || iz < 0 || ix >= p_.nx || iz >= p_.nz) continue;
                std::uint8_t& m = cellMark_[std::size_t(iz) * std::size_t(p_.nx) + std::size_t(ix)];
                if (m == 0) {
                    m = 1;
                    big.push_back(iz * p_.nx + ix);
                }
                if (std::abs(dx) <= inner && std::abs(dz) <= inner) m = 2;
            }
        }
    }
    std::sort(big.begin(), big.end());
    std::vector<std::int32_t> all;
    for (std::int32_t c : big) each_in_cell(c, [&](int s) { all.push_back(s); });
    ++edistNow_;
    using Item = std::pair<float, std::int32_t>;
    std::priority_queue<Item, std::vector<Item>, std::greater<Item>> open;
    std::vector<std::int32_t> touched;
    const float limit = p_.radius - 1e-5f;
    for (std::int32_t s : all) {
        if (!sp(s).alive) continue;
        const float d = edge_distance(s);
        if (d < limit) {
            edist_[std::size_t(s)] = d;
            edistStamp_[std::size_t(s)] = edistNow_;
            touched.push_back(s);
            open.push({d, s});
        }
    }
    while (!open.empty()) {
        const auto [d, s] = open.top();
        open.pop();
        if (d > edist_[std::size_t(s)]) continue;
        for (int k = 0; k < 8; ++k) {
            int nb[2];
            const int cnt = neighbours(s, k, nb);
            for (int i = 0; i < cnt; ++i) {
                const int n = nb[i];
                const float nd = d + (k < 4 ? p_.cell : p_.cell * kSqrt2);
                if (nd >= limit) continue;
                if (edistStamp_[std::size_t(n)] != edistNow_) {
                    edistStamp_[std::size_t(n)] = edistNow_;
                    touched.push_back(n);
                } else if (nd >= edist_[std::size_t(n)]) {
                    continue;
                }
                edist_[std::size_t(n)] = nd;
                open.push({nd, n});
            }
        }
    }
    for (std::int32_t s : all) {
        if (!sp(s).alive) continue;
        if (cellMark_[std::size_t(sp(s).cell)] == 2) sp(s).eroded = edistStamp_[std::size_t(s)] == edistNow_;
    }
    for (std::int32_t s : touched)
        if (sp(s).alive) sp(s).eroded = true;
    for (std::int32_t c : big) cellMark_[std::size_t(c)] = 0;
}

void NavGrid::refresh() {
    if (dirty_.empty()) return;
    std::sort(dirty_.begin(), dirty_.end());
    dirty_.erase(std::unique(dirty_.begin(), dirty_.end()), dirty_.end());
    erode_around(dirty_);
    dirty_.clear();
}

}  // namespace fa::detail
