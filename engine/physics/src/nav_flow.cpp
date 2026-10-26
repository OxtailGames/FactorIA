// A cost grid that a script keeps and flow fields over it (docs/NAVIGATION.md, "Reusable grids and flow fields").
// A flow field is Dijkstra run backwards from the goal cells: the cost of ENTERING a cell is paid by the step that leaves its
// neighbour, so distance(cell) is exactly the `cost` nav_find_tile_path reports for the cheapest route to the nearest goal.
// No clock, no randomness: ties are broken by cell index in the queue and by a fixed direction order when stepping.
#include <algorithm>
#include <cmath>
#include <limits>
#include <queue>

#include "fa/physics/nav.h"

namespace fa {

namespace {

constexpr float kSqrt2 = 1.41421356f;
constexpr float kInf = std::numeric_limits<float>::infinity();
// East, south, west, north, then the diagonals: the order Tidewater Market's distance fields stepped in.
constexpr int kDx[8] = {1, 0, -1, 0, 1, -1, -1, 1};
constexpr int kDy[8] = {0, 1, 0, -1, 1, 1, -1, -1};

float sanitize(float c) { return (std::isfinite(c) && c >= 0.0f) ? c : -1.0f; }

}  // namespace

NavCostGrid::NavCostGrid(int width, int height, Vec2 origin, Vec2 cellSize, float fill) {
    grid_.width = std::max(width, 0);
    grid_.height = std::max(height, 0);
    grid_.origin = origin;
    grid_.cellSize = cellSize;
    grid_.cost.assign(std::size_t(grid_.width) * std::size_t(grid_.height), sanitize(fill));
    grid_.minOpenCost = nav_tile_min_open_cost(grid_);
}

const NavTileGrid& NavCostGrid::grid() const {
    if (!(grid_.minOpenCost >= 0.0f)) grid_.minOpenCost = nav_tile_min_open_cost(grid_);
    return grid_;
}

float NavCostGrid::cost(int col, int row) const {
    if (!inside(col, row)) return -1.0f;
    return grid_.cost[std::size_t(row) * std::size_t(grid_.width) + std::size_t(col)];
}

bool NavCostGrid::set_cost(int col, int row, float cost) {
    if (!inside(col, row)) return false;
    const float v = sanitize(cost);
    float& cell = grid_.cost[std::size_t(row) * std::size_t(grid_.width) + std::size_t(col)];
    if (cell == v) return true;
    const float old = cell;
    cell = v;
    ++version_;
    // Keep the cheapest open cost current without sweeping, unless the cell that held it got dearer or blocked.
    if (grid_.minOpenCost >= 0.0f) {
        if (v >= 0.0f && v < grid_.minOpenCost) grid_.minOpenCost = v;
        else if (old >= 0.0f && old <= grid_.minOpenCost) grid_.minOpenCost = -1.0f;  // the next query sweeps once
    }
    return true;
}

void NavCostGrid::assign(const std::vector<float>& costs) {
    if (costs.size() != grid_.cost.size()) return;
    for (std::size_t i = 0; i < costs.size(); ++i) grid_.cost[i] = sanitize(costs[i]);
    grid_.minOpenCost = nav_tile_min_open_cost(grid_);
    ++version_;
}

NavFlowField::NavFlowField(std::shared_ptr<NavCostGrid> grid, std::vector<std::pair<int, int>> goals, bool diagonals)
    : grid_(std::move(grid)), goals_(std::move(goals)), diagonals_(diagonals) {
    std::erase_if(goals_, [&](const std::pair<int, int>& g) { return !grid_->inside(g.first, g.second); });
}

float NavFlowField::enter_cost(std::int32_t i) const {
    const float c = grid_->grid().cost[std::size_t(i)];
    return c >= 0.0f ? c : 1.0f;  // only a blocked GOAL is ever asked: it is entered at cost 1, as allowBlockedGoal does
}

void NavFlowField::refresh() {
    if (built_ && builtAt_ == grid_->version()) return;
    built_ = true;
    builtAt_ = grid_->version();
    ++rebuilds_;
    const NavTileGrid& g = grid_->grid();
    const int W = g.width, H = g.height;
    const std::size_t total = std::size_t(W) * std::size_t(H);
    dist_.assign(total, kInf);
    goal_.assign(total, 0);
    struct Item {
        float d;
        std::int32_t idx;
    };
    struct Later {
        bool operator()(const Item& a, const Item& b) const { return a.d != b.d ? a.d > b.d : a.idx > b.idx; }
    };
    std::priority_queue<Item, std::vector<Item>, Later> open;
    for (const auto& goal : goals_) {
        const std::int32_t i = std::int32_t(std::size_t(goal.second) * std::size_t(W) + std::size_t(goal.first));
        if (goal_[std::size_t(i)]) continue;
        dist_[std::size_t(i)] = 0.0f;
        goal_[std::size_t(i)] = 1;
        open.push({0.0f, i});
    }
    auto blocked = [&](std::int32_t i) { return !(g.cost[std::size_t(i)] >= 0.0f); };
    const int dirs = diagonals_ ? 8 : 4;
    while (!open.empty()) {
        const Item it = open.top();
        open.pop();
        if (it.d > dist_[std::size_t(it.idx)]) continue;
        const int c = int(it.idx % W), r = int(it.idx / W);
        const float enter = enter_cost(it.idx);
        for (int k = 0; k < dirs; ++k) {
            const int nc = c + kDx[k], nr = r + kDy[k];
            if (nc < 0 || nr < 0 || nc >= W || nr >= H) continue;
            const std::int32_t n = std::int32_t(std::size_t(nr) * std::size_t(W) + std::size_t(nc));
            if (blocked(n)) continue;
            if (k >= 4 && (blocked(std::int32_t(std::size_t(r) * std::size_t(W) + std::size_t(nc))) ||
                           blocked(std::int32_t(std::size_t(nr) * std::size_t(W) + std::size_t(c)))))
                continue;  // no corner cutting
            const float nd = it.d + enter * (k >= 4 ? kSqrt2 : 1.0f);
            if (nd < dist_[std::size_t(n)]) {
                dist_[std::size_t(n)] = nd;
                open.push({nd, n});
            }
        }
    }
}

float NavFlowField::distance(int col, int row) {
    if (!grid_->inside(col, row)) return kInf;
    refresh();
    return dist_[std::size_t(row) * std::size_t(grid_->width()) + std::size_t(col)];
}

bool NavFlowField::is_goal(int col, int row) {
    if (!grid_->inside(col, row)) return false;
    refresh();
    return goal_[std::size_t(row) * std::size_t(grid_->width()) + std::size_t(col)] != 0;
}

bool NavFlowField::step_toward(int col, int row, int& nextCol, int& nextRow) {
    if (!grid_->inside(col, row)) return false;
    refresh();
    const NavTileGrid& g = grid_->grid();
    const int W = g.width, H = g.height;
    const std::size_t here = std::size_t(row) * std::size_t(W) + std::size_t(col);
    if (goal_[here] || !std::isfinite(dist_[here])) return false;
    auto blocked = [&](int c, int r) { return !(g.cost[std::size_t(r) * std::size_t(W) + std::size_t(c)] >= 0.0f); };
    float best = kInf;
    int bk = -1;
    const int dirs = diagonals_ ? 8 : 4;
    for (int k = 0; k < dirs; ++k) {
        const int nc = col + kDx[k], nr = row + kDy[k];
        if (nc < 0 || nr < 0 || nc >= W || nr >= H) continue;
        const std::size_t n = std::size_t(nr) * std::size_t(W) + std::size_t(nc);
        if (!std::isfinite(dist_[n])) continue;
        if (k >= 4 && (blocked(nc, row) || blocked(col, nr))) continue;
        // Going to n costs entering n (a blocked goal: 1) plus what is left from n; the dearest-first rounding of the
        // build makes the best of these equal to dist_[here].
        const float enter = g.cost[n] >= 0.0f ? g.cost[n] : 1.0f;
        const float total = enter * (k >= 4 ? kSqrt2 : 1.0f) + dist_[n];
        if (total < best) {
            best = total;
            bk = k;
        }
    }
    if (bk < 0) return false;
    nextCol = col + kDx[bk];
    nextRow = row + kDy[bk];
    return true;
}

std::vector<std::pair<int, int>> NavFlowField::path_from(int col, int row) {
    std::vector<std::pair<int, int>> out;
    if (!std::isfinite(distance(col, row))) return out;
    out.push_back({col, row});
    int guard = grid_->width() * grid_->height();
    int c = col, r = row, nc = 0, nr = 0;
    while (guard-- > 0 && step_toward(c, r, nc, nr)) {
        out.push_back({nc, nr});
        c = nc;
        r = nr;
    }
    return out;
}

}  // namespace fa
