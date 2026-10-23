// NavMesh3D: rasterises the static 3D colliders into the navigation grid (nav_grid.cpp), keeps it up to date with the
// moving obstacles, and answers path queries. See fa/physics/nav.h and docs/NAVIGATION.md.
#include <algorithm>
#include <cmath>
#include <cstring>
#include <format>
#include <set>

#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "physics_internal.h"

namespace fa {

namespace {
Json vec_json(Vec3 v) { return Json::array({v.x, v.y, v.z}); }
}  // namespace

Json NavBakeStats::to_json() const {
    Json j = Json::object();
    j["mesh"] = mesh;
    j["cellsX"] = cellsX;
    j["cellsZ"] = cellsZ;
    j["cells"] = cells;
    j["spans"] = spans;
    j["walkableCells"] = walkableCells;
    j["regions"] = regions;
    j["obstacles"] = obstacles;
    return j;
}

Json NavPath::to_json() const {
    Json j = Json::object();
    j["found"] = found;
    if (found) {
        j["complete"] = complete;
        Json pts = Json::array();
        for (const Vec3& p : points) pts.push_back(vec_json(p));
        j["points"] = pts;
        j["length"] = length;
        j["from"] = vec_json(from);
        j["to"] = vec_json(to);
    } else {
        j["reason"] = reason;
        j["message"] = message;
        j["hint"] = hint;
        if (nearestDistance >= 0.0f) {
            j["nearest"] = vec_json(nearest);
            j["nearestDistance"] = nearestDistance;
        }
    }
    j["mesh"] = mesh;
    return j;
}

}  // namespace fa

namespace fa::detail {

namespace {

constexpr double kMaxCells = 4.0e6;

struct Hasher {
    std::uint64_t h = 1469598103934665603ull;
    void u64(std::uint64_t v) {
        for (int i = 0; i < 8; ++i) {
            h ^= (v >> (8 * i)) & 0xffu;
            h *= 1099511628211ull;
        }
    }
    void f(float v) {
        std::uint32_t bits = 0;
        std::memcpy(&bits, &v, sizeof bits);
        u64(bits);
    }
    void v3(Vec3 v) {
        f(v.x);
        f(v.y);
        f(v.z);
    }
};

std::string fmt3(Vec3 v) { return std::format("({:.2f}, {:.2f}, {:.2f})", v.x, v.y, v.z); }

}  // namespace

NavParams Physics3D::nav_params(const NavMesh3D& cfg, Vec3 position) {
    NavParams p;
    p.cell = std::max(cfg.cellSize, 0.05f);
    p.cellHeight = std::max(cfg.cellHeight, 0.005f);
    p.radius = std::max(cfg.agentRadius, 0.0f);
    p.height = std::max(cfg.agentHeight, 0.1f);
    p.step = std::max(cfg.stepHeight, 0.0f);
    p.maxSlopeDeg = clamp(cfg.maxSlope, 0.0f, 89.0f);
    const Vec3 size{std::max(cfg.size.x, 0.0f), std::max(cfg.size.y, 0.0f), std::max(cfg.size.z, 0.0f)};
    p.origin = position - size * 0.5f;
    p.yMin = p.origin.y;
    p.yMax = p.origin.y + size.y;
    p.nx = std::max(1, int(std::ceil(double(size.x) / double(p.cell) - 1e-4)));
    p.nz = std::max(1, int(std::ceil(double(size.z) / double(p.cell) - 1e-4)));
    return p;
}

// ------------------------------------------------------ rasterisation ----
// The solid intervals of one body along the vertical line through (x, z). Appends [bottom, top] with the up component of
// the normal at the top; false when the line misses the body. Convex shapes give one interval; a mesh gives one per pair
// of crossings (a closed mesh) or a thin plate for a lone surface.
bool Physics3D::nav_column(const Body& b, float x, float z, float yLo, float yHi, float cellHeight, std::vector<NavSolid>& out) {
    if (b.kind == Body::Kind::Sphere) {
        const float dx = x - b.center.x, dz = z - b.center.z;
        const float d2 = dx * dx + dz * dz, r2 = b.radius * b.radius;
        if (d2 >= r2) return false;
        const float h = std::sqrt(r2 - d2);
        out.push_back({b.center.y - h, b.center.y + h, h / b.radius});
        return true;
    }
    if (b.kind == Body::Kind::Box) {
        const Vec3 org = world_to_frame(b.ax, Vec3{x, yHi, z} - b.center);
        const Vec3 dir = world_to_frame(b.ax, Vec3{0, -1, 0});
        float tIn = -1e30f, tOut = 1e30f;
        int axis = -1;
        float sign = 1.0f;
        for (int i = 0; i < 3; ++i) {
            if (std::fabs(dir[i]) < 1e-9f) {
                if (std::fabs(org[i]) > b.half[i]) return false;
                continue;
            }
            float t1 = (-b.half[i] - org[i]) / dir[i], t2 = (b.half[i] - org[i]) / dir[i];
            float sgn = -1.0f;  // entering through the low face: the outward normal is -axis
            if (t1 > t2) {
                std::swap(t1, t2);
                sgn = 1.0f;
            }
            if (t1 > tIn) {
                tIn = t1;
                axis = i;
                sign = sgn;
            }
            tOut = std::min(tOut, t2);
        }
        if (axis < 0 || tIn >= tOut) return false;
        const Vec3 n = b.ax[axis] * sign;
        out.push_back({yHi - tOut, yHi - tIn, n.y});
        return true;
    }
    // Capsule, convex hull, mesh: vertical rays through the generic ray test.
    const Vec3 down{0, -1, 0}, up{0, 1, 0};
    if (b.kind != Body::Kind::Mesh) {
        float t = 0.0f;
        Vec3 n;
        if (!ray_body(b, {x, yHi, z}, down, yHi - yLo, t, n)) return false;
        const float top = yHi - t;
        float bottom = top - cellHeight;
        float t2 = 0.0f;
        Vec3 n2;
        if (ray_body(b, {x, yLo, z}, up, yHi - yLo, t2, n2)) bottom = std::min(yLo + t2, top);
        out.push_back({bottom, top, n.y});
        return true;
    }
    std::vector<std::pair<float, float>> hits;  // (height, normal.y facing the ray)
    float y = yHi;
    for (int i = 0; i < 64; ++i) {
        float t = 0.0f;
        Vec3 n;
        if (!ray_body(b, {x, y, z}, down, y - yLo, t, n)) break;
        const float hy = y - t;
        hits.push_back({hy, n.y});
        y = hy - 1e-3f;
    }
    if (hits.empty()) return false;
    for (std::size_t i = 0; i < hits.size(); i += 2) {
        if (i + 1 < hits.size()) out.push_back({hits[i + 1].first, hits[i].first, hits[i].second});
        else out.push_back({hits[i].first - cellHeight, hits[i].first, hits[i].second});
    }
    return true;
}

void Physics3D::nav_raster(const Body& b, const NavParams& p, std::vector<NavEntry>& out) const {
    Vec3 lo, hi;
    aabb(b, lo, hi);
    if (hi.y < p.yMin || lo.y > p.yMax) return;
    const int i0 = std::max(0, int(std::floor((lo.x - p.origin.x) / p.cell)));
    const int i1 = std::min(p.nx - 1, int(std::floor((hi.x - p.origin.x) / p.cell)));
    const int k0 = std::max(0, int(std::floor((lo.z - p.origin.z) / p.cell)));
    const int k1 = std::min(p.nz - 1, int(std::floor((hi.z - p.origin.z) / p.cell)));
    if (i0 > i1 || k0 > k1) return;
    constexpr float kEdge = 1e-4f;
    if (b.kind == Body::Kind::Box && !b.rotated) {
        // Exact: any overlap of the cell counts, so a wall thinner than a cell is never missed.
        for (int k = k0; k <= k1; ++k) {
            const float z0 = p.origin.z + float(k) * p.cell;
            if (hi.z <= z0 + kEdge || lo.z >= z0 + p.cell - kEdge) continue;
            for (int i = i0; i <= i1; ++i) {
                const float x0 = p.origin.x + float(i) * p.cell;
                if (hi.x <= x0 + kEdge || lo.x >= x0 + p.cell - kEdge) continue;
                out.push_back({k * p.nx + i, {lo.y, hi.y, 1.0f}});
            }
        }
        return;
    }
    std::vector<NavSolid> found;
    for (int k = k0; k <= k1; ++k) {
        for (int i = i0; i <= i1; ++i) {
            found.clear();
            for (int sz = 0; sz < 3; ++sz) {
                for (int sx = 0; sx < 3; ++sx) {
                    const float x = p.origin.x + (float(i) + 0.5f + float(sx - 1) * 0.4f) * p.cell;
                    const float z = p.origin.z + (float(k) + 0.5f + float(sz - 1) * 0.4f) * p.cell;
                    nav_column(b, x, z, lo.y - 0.5f, hi.y + 0.5f, p.cellHeight, found);
                }
            }
            for (const NavSolid& s : found) {
                if (s.bottom > p.yMax || s.top < p.yMin) continue;
                out.push_back({k * p.nx + i, s});
            }
        }
    }
}

// --------------------------------------------------------------- signatures ----
std::uint64_t Physics3D::nav_obstacle_signature(const Body& b) {
    Hasher h;
    h.u64(std::uint64_t(b.kind));
    h.u64(b.enabled ? 1 : 0);
    h.v3(b.center);
    for (int i = 0; i < 3; ++i) h.v3(b.ax[i]);
    h.v3(b.half);
    h.f(b.radius);
    h.f(b.segHalf);
    h.v3(b.lcenter);
    h.v3(b.gscale);
    h.u64(std::uint64_t(reinterpret_cast<std::uintptr_t>(b.data.get())));
    return h.h;
}

std::uint64_t Physics3D::nav_signature(const NavState& n) const {
    Hasher h;
    const NavMesh3D& c = n.cfg;
    h.v3(n.position);
    h.v3(c.size);
    h.f(c.cellSize);
    h.f(c.cellHeight);
    h.f(c.agentRadius);
    h.f(c.agentHeight);
    h.f(c.stepHeight);
    h.f(c.maxSlope);
    const NavParams p = nav_params(c, n.position);
    for (const Body& b : bodies_) {
        if (!nav_static_solid(b)) continue;
        Vec3 lo, hi;
        aabb(b, lo, hi);
        if (hi.y < p.yMin || lo.y > p.yMax || hi.x < p.origin.x || lo.x > p.origin.x + float(p.nx) * p.cell ||
            hi.z < p.origin.z || lo.z > p.origin.z + float(p.nz) * p.cell)
            continue;
        h.u64(b.seq);
        h.u64(nav_obstacle_signature(b));
    }
    return h.h;
}

// ------------------------------------------------------------------- bake ----
bool Physics3D::nav_bake_one(World& world, NavState& n, std::string& error) {
    const NavMesh3D& c = n.cfg;
    if (!(c.size.x > 0.0f && c.size.y > 0.0f && c.size.z > 0.0f)) {
        error = std::format("NavMesh3D on '{}': size {} must be positive on every axis. Set size to the box that covers the "
                            "walkable level, e.g. [40, 10, 40].", n.id, fmt3(c.size));
        return false;
    }
    const double cells = std::ceil(double(c.size.x) / double(std::max(c.cellSize, 0.05f))) *
                         std::ceil(double(c.size.z) / double(std::max(c.cellSize, 0.05f)));
    if (cells > kMaxCells) {
        error = std::format("NavMesh3D on '{}': {} x {} m with cellSize {} makes {:.0f} cells; the limit is 4 million. Use a "
                            "bigger cellSize (a cellSize of {:.2f} fits), or a smaller size, or split the level in several "
                            "NavMesh3D.", n.id, c.size.x, c.size.z, c.cellSize, cells,
                            std::sqrt(double(c.size.x) * double(c.size.z) / kMaxCells) * 1.01);
        return false;
    }
    const NavParams p = nav_params(c, n.position);
    std::vector<NavEntry> entries;
    for (const Body& b : bodies_)
        if (nav_static_solid(b)) nav_raster(b, p, entries);
    n.grid.build(p, entries);
    n.obstacleSig.clear();
    n.baked = true;
    n.stale = false;
    n.stats = NavBakeStats{};
    n.stats.mesh = n.id;
    n.stats.cellsX = p.nx;
    n.stats.cellsZ = p.nz;
    n.stats.cells = p.nx * p.nz;
    n.stats.spans = n.grid.span_count();
    n.stats.walkableCells = n.grid.walkable_count();
    n.stats.regions = n.grid.region_count();
    nav_apply_obstacles(n);
    if (NavMesh3D* m = world.get<NavMesh3D>(n.e)) {
        m->walkableCells = n.stats.walkableCells;
        m->regions = n.stats.regions;
    }
    return true;
}

void Physics3D::nav_apply_obstacles(NavState& n) {
    const NavParams& p = n.grid.params();
    std::set<std::uint64_t> seen;
    std::vector<NavEntry> entries;
    std::vector<NavGrid::Footprint> footprint;
    for (const Body& b : bodies_) {
        if (!b.navObstacle || !b.enabled || !b.hasShape || b.trigger || b.character) continue;
        Vec3 lo, hi;
        aabb(b, lo, hi);
        if (hi.y < p.yMin || lo.y > p.yMax || hi.x < p.origin.x - 1.0f || lo.x > p.origin.x + float(p.nx) * p.cell + 1.0f ||
            hi.z < p.origin.z - 1.0f || lo.z > p.origin.z + float(p.nz) * p.cell + 1.0f)
            continue;
        const std::uint64_t key = b.e.bits(), sig = nav_obstacle_signature(b);
        seen.insert(key);
        auto it = n.obstacleSig.find(key);
        if (it != n.obstacleSig.end() && it->second == sig) continue;
        entries.clear();
        footprint.clear();
        nav_raster(b, p, entries);
        for (const NavEntry& e : entries) footprint.push_back({e.cell, e.solid.bottom, e.solid.top});
        n.grid.set_obstacle(key, footprint);
        n.obstacleSig[key] = sig;
    }
    for (auto it = n.obstacleSig.begin(); it != n.obstacleSig.end();) {
        if (!seen.count(it->first)) {
            n.grid.clear_obstacle(it->first);
            it = n.obstacleSig.erase(it);
        } else {
            ++it;
        }
    }
    n.stats.obstacles = int(n.grid.obstacle_count());
}

void Physics3D::nav_update(World& world, bool allowBake) {
    std::vector<Entity> found;
    world.each<NavMesh3D>([&](Entity e, NavMesh3D&) { found.push_back(e); });
    if (found.empty()) {
        if (!navs_.empty()) {
            navs_.clear();
            navOrder_.clear();
        }
        return;
    }
    navOrder_.clear();
    std::set<std::uint64_t> alive;
    for (Entity e : found) {
        if (world.pending_destroy(e)) continue;
        NavMesh3D* m = world.get<NavMesh3D>(e);
        if (!m) continue;
        const std::uint64_t key = e.bits();
        NavState& n = navs_[key];
        if (!n.id.empty() && n.id != world.id_of(e)) n = NavState{};  // entity slot reused
        n.e = e;
        n.id = world.id_of(e);
        n.cfg = *m;
        n.position = world.world_position(e);
        alive.insert(key);
        navOrder_.push_back(key);
        if (!allowBake || !n.cfg.enabled || !world.active_in_hierarchy(e)) continue;
        const std::uint64_t sig = nav_signature(n);
        if (n.cfg.autoBake && (!n.attempted || sig != n.sig)) {
            n.attempted = true;
            n.sig = sig;
            std::string error;
            if (!nav_bake_one(world, n, error)) {
                n.baked = false;
                if (error != n.error) FA_ERROR("physics", "{}", error);
                n.error = error;
            } else {
                n.error.clear();
            }
        } else if (n.baked) {
            n.stale = sig != n.sig;
        }
        if (n.baked) nav_apply_obstacles(n);
    }
    for (auto it = navs_.begin(); it != navs_.end();) {
        if (!alive.count(it->first)) it = navs_.erase(it);
        else ++it;
    }
}

Result<std::vector<NavBakeStats>> Physics3D::nav_bake(World& world, const std::string& mesh) {
    nav_update(world, false);
    std::vector<std::uint64_t> targets;
    if (!mesh.empty()) {
        const Entity e = world.find_by_id(mesh);
        auto it = e.is_null() ? navs_.end() : navs_.find(e.bits());
        if (it == navs_.end()) {
            std::vector<std::string> ids;
            for (std::uint64_t k : navOrder_) ids.push_back(navs_[k].id);
            if (ids.empty())
                return Error{std::format("nav.bake: no NavMesh3D named '{}': the scene has none.", mesh),
                             "Add the component to an entity: scene.add_component {\"entity\":\"navmesh\",\"component\":\"NavMesh3D\"} "
                             "with its size covering the level."};
            return Error{"nav.bake: no NavMesh3D on entity '" + mesh + "'.", did_you_mean(mesh, ids)};
        }
        if (!it->second.cfg.enabled)
            return Error{std::format("nav.bake: the NavMesh3D on '{}' is disabled.", mesh), "Set NavMesh3D.enabled to true."};
        targets.push_back(it->first);
    } else {
        for (std::uint64_t k : navOrder_)
            if (navs_[k].cfg.enabled && world.active_in_hierarchy(navs_[k].e)) targets.push_back(k);
        if (targets.empty())
            return Error{"nav.bake: the scene has no enabled NavMesh3D.",
                         "Add the component to an entity: scene.add_component {\"entity\":\"navmesh\",\"component\":\"NavMesh3D\"} "
                         "and set its size to cover the walkable level."};
    }
    std::vector<NavBakeStats> out;
    for (std::uint64_t k : targets) {
        NavState& n = navs_[k];
        std::string error;
        n.attempted = true;
        n.sig = nav_signature(n);
        if (!nav_bake_one(world, n, error)) {
            n.baked = false;
            n.error = error;
            return Error{"nav.bake: " + error, "Fix the NavMesh3D fields and bake again."};
        }
        n.error.clear();
        out.push_back(n.stats);
    }
    return out;
}

// ------------------------------------------------------------------ paths ----
Result<NavPath> Physics3D::nav_find_path(World& world, Vec3 from, Vec3 to, const NavPathOptions& options) {
    nav_update(world, true);
    std::vector<NavState*> usable;
    for (std::uint64_t k : navOrder_) {
        NavState& n = navs_[k];
        if (n.cfg.enabled && n.baked && world.active_in_hierarchy(n.e)) usable.push_back(&n);
    }
    NavState* mesh = nullptr;
    if (!options.mesh.empty()) {
        const Entity e = world.find_by_id(options.mesh);
        auto it = e.is_null() ? navs_.end() : navs_.find(e.bits());
        if (it == navs_.end()) {
            std::vector<std::string> ids;
            for (std::uint64_t k : navOrder_) ids.push_back(navs_[k].id);
            return Error{"nav.find_path: no NavMesh3D on entity '" + options.mesh + "'.",
                         ids.empty() ? "The scene has no NavMesh3D: add the component to an entity." : did_you_mean(options.mesh, ids)};
        }
        mesh = &it->second;
        if (!mesh->baked)
            return Error{std::format("nav.find_path: the NavMesh3D on '{}' is not baked{}.", mesh->id,
                                     mesh->error.empty() ? "" : " (" + mesh->error + ")"),
                         "Call nav.bake (autoBake bakes by itself when the scene loads; with autoBake off you bake)."};
    } else {
        if (usable.empty()) {
            std::string why;
            for (std::uint64_t k : navOrder_)
                if (!navs_[k].error.empty()) why = " The bake failed: " + navs_[k].error;
            if (navOrder_.empty())
                return Error{"nav.find_path: the scene has no NavMesh3D.",
                             "Add the component to an entity: scene.add_component {\"entity\":\"navmesh\",\"component\":\"NavMesh3D\"} "
                             "with its size covering the level (docs/NAVIGATION.md)."};
            return Error{"nav.find_path: no NavMesh3D is baked and enabled." + why,
                         "Call nav.bake, or set NavMesh3D.autoBake and enabled to true."};
        }
        const float need = options.radius < 0.0f ? 0.0f : options.radius;
        auto fits = [&](NavState* n) { return n->cfg.agentRadius >= need - 1e-4f; };
        auto holds = [&](NavState* n) {
            const NavParams& p = n->grid.params();
            return from.x >= p.origin.x && from.x <= p.origin.x + float(p.nx) * p.cell && from.z >= p.origin.z &&
                   from.z <= p.origin.z + float(p.nz) * p.cell && from.y >= p.yMin - p.height && from.y <= p.yMax + 1.0f;
        };
        for (NavState* n : usable)
            if (fits(n) && holds(n)) { mesh = n; break; }
        if (!mesh)
            for (NavState* n : usable)
                if (fits(n)) { mesh = n; break; }
        if (!mesh) mesh = usable.front();
    }
    const NavMesh3D& cfg = mesh->cfg;
    const float radius = options.radius < 0.0f ? cfg.agentRadius : options.radius;
    if (radius > cfg.agentRadius + 1e-4f)
        return Error{std::format("nav.find_path: radius {:.2f} m is larger than the {:.2f} m the NavMesh3D on '{}' was baked for: "
                                 "walkable cells keep only agentRadius from walls, so a wider agent would be stuck in them.",
                                 radius, cfg.agentRadius, mesh->id),
                     std::format("Bake for the bigger agent: add a second NavMesh3D with agentRadius {:.2f} (same size and "
                                 "position) and pass its id as the `mesh` option, or raise agentRadius on this one.", radius)};

    const NavGrid& g = mesh->grid;
    const NavParams& p = g.params();
    NavPath res;
    res.mesh = mesh->id;
    const float snap = options.snap >= 0.0f ? options.snap : cfg.agentRadius + 2.0f * p.cell;
    const float reachDown = p.height, reachUp = p.step + p.cellHeight;
    auto resolve = [&](Vec3 pt, const char* what, int& span, float& snapped) {
        span = g.find_span(pt, reachDown, reachUp);
        snapped = 0.0f;
        if (span < 0) span = g.nearest_span(pt, reachDown, reachUp, snap, &snapped);
        if (span >= 0) return true;
        res.found = false;
        res.reason = std::string(what) + "_off_mesh";
        float d = -1.0f;
        const int ns = g.nearest_anywhere(pt, &d);
        if (!g.inside(pt)) {
            res.message = std::format("The {} {} is outside the bounds of the NavMesh3D on '{}' (x {:.1f}..{:.1f}, y {:.1f}..{:.1f}, "
                                      "z {:.1f}..{:.1f}).", what, fmt3(pt), mesh->id, p.origin.x,
                                      p.origin.x + float(p.nx) * p.cell, p.yMin, p.yMax, p.origin.z, p.origin.z + float(p.nz) * p.cell);
            res.hint = "Make the NavMesh3D size cover the whole level, or pick a point inside it.";
        } else {
            res.message = std::format("The {} {} is not on walkable ground (no walkable cell within {:.2f} m horizontally and "
                                      "between {:.2f} m below and {:.2f} m above it)", what, fmt3(pt), snap, reachDown, reachUp);
            res.hint = "Pass a point on the floor (a raycast down finds it), or raise `snap`; the walkable cells keep "
                       "agentRadius away from walls and drops, and exclude ground with less than agentHeight of room above it.";
        }
        if (ns >= 0) {
            res.nearest = g.center(ns);
            res.nearestDistance = d;
            res.message += std::format("; the nearest walkable point is {}, {:.2f} m away.", fmt3(res.nearest), d);
        } else {
            res.message += "; the mesh has no walkable cells at all.";
            res.hint = "Check the colliders under the NavMesh3D (static, not triggers) and its size, agentRadius and maxSlope.";
        }
        return false;
    };
    int ss = -1, gs = -1;
    float sd = 0.0f, gd = 0.0f;
    if (!resolve(from, "start", ss, sd)) return res;
    if (!resolve(to, "goal", gs, gd)) return res;

    int closest = ss;
    std::vector<int> chain;
    if (ss == gs) {
        chain = {ss};
    } else {
        chain = g.search(ss, gs, &closest);
    }
    if (chain.empty()) {
        if (options.closest) {
            chain = closest == ss ? std::vector<int>{ss} : g.search(ss, closest);
            res.complete = false;
        } else {
            const int rs = g.span(ss).region, rg = g.span(gs).region;
            res.found = false;
            res.reason = "disconnected";
            if (rs != rg)
                res.message = std::format("No route from {} to {}: they are in different walkable areas (area {} and area {} of {}). "
                                          "Between them is a wall, a drop, a step higher than stepHeight ({:.2f} m), a slope "
                                          "steeper than maxSlope ({:.0f} degrees) or a gap narrower than 2 x agentRadius ({:.2f} m).",
                                          fmt3(g.center(ss)), fmt3(g.center(gs)), rs, rg, g.region_count(), p.step, p.maxSlopeDeg,
                                          2.0f * p.radius);
            else
                res.message = std::format("No route from {} to {} right now: both are in walkable area {}, but a moving obstacle "
                                          "(Collider3D.navObstacle) blocks the way ({} obstacle(s) active).", fmt3(g.center(ss)),
                                          fmt3(g.center(gs)), rs, int(g.obstacle_count()));
            res.hint = "Look at the walkable cells (the editor's Show navmesh, or nav.info), widen the gap or add a ramp; "
                       "or pass {closest: true} to walk to the reachable point nearest the goal.";
            return res;
        }
    }
    const std::vector<int> corners = g.pull(chain);
    res.found = true;
    for (int s : corners) res.points.push_back(g.center(s));
    // The ends are the points asked for, on the surface, when they were on a walkable cell themselves.
    if (sd == 0.0f) res.points.front() = {from.x, res.points.front().y, from.z};
    if (gd == 0.0f && res.complete) {
        if (res.points.size() == 1) res.points.push_back(res.points.front());
        res.points.back() = {to.x, res.points.back().y, to.z};
    }
    res.from = res.points.front();
    res.to = res.points.back();
    for (std::size_t i = 1; i < res.points.size(); ++i) res.length += distance(res.points[i - 1], res.points[i]);
    return res;
}

// ------------------------------------------------------------------ debug ----
std::vector<NavCell> Physics3D::nav_cells(World& world, std::size_t maxCells) {
    nav_update(world, true);
    std::vector<NavCell> out;
    for (std::uint64_t k : navOrder_) {
        const NavState& n = navs_[k];
        if (!n.baked || !n.cfg.enabled) continue;
        for (int s = 0; s < n.grid.span_count() && out.size() < maxCells; ++s) {
            const NavGrid::Span& sp = n.grid.span(s);
            if (sp.eroded) continue;
            NavCell c;
            c.center = n.grid.center(s);
            c.size = n.grid.params().cell;
            c.blocked = sp.block > 0;
            c.region = sp.region;
            out.push_back(c);
        }
    }
    return out;
}

Json Physics3D::nav_info(World& world) {
    nav_update(world, true);
    Json out = Json::array();
    for (std::uint64_t k : navOrder_) {
        const NavState& n = navs_[k];
        Json j = Json::object();
        j["mesh"] = n.id;
        j["enabled"] = n.cfg.enabled;
        j["autoBake"] = n.cfg.autoBake;
        j["baked"] = n.baked;
        if (!n.error.empty()) j["error"] = n.error;
        const NavParams p = nav_params(n.cfg, n.position);
        j["boundsMin"] = vec_json(p.origin);
        j["boundsMax"] = vec_json(p.origin + Vec3{float(p.nx) * p.cell, p.yMax - p.yMin, float(p.nz) * p.cell});
        j["cellSize"] = p.cell;
        j["cellHeight"] = p.cellHeight;
        j["agentRadius"] = p.radius;
        j["agentHeight"] = p.height;
        j["stepHeight"] = p.step;
        j["maxSlope"] = p.maxSlopeDeg;
        if (n.baked) {
            j["staleSinceBake"] = n.stale;
            j["stats"] = n.stats.to_json();
        }
        out.push_back(j);
    }
    return out;
}

}  // namespace fa::detail
