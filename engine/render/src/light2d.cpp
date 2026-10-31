// Shadows of the 2D lights: the CPU side. A point light with castShadows gets one row of a data texture that says, for
// each of kShadowAngles directions around it, how far its light travels before it meets a solid tile of a Tilemap with
// occludesLight. light.glsl (the light buffer) and quad.glsl (lit visuals with a normal map) read the row to darken what
// lies behind the wall. The rays are cast here, by a grid walk through the tile cells, because the tiles are data of the
// scene (a Json array) and not something the GPU has: a ray costs a handful of cell lookups.
#include <algorithm>
#include <cmath>
#include <cstring>

#include "fa/core/log.h"
#include "fa/scene/bounds.h"
#include "fa/scene/tilemap.h"
#include "frame.h"

namespace fa::render {

namespace {

constexpr float kInf = 1e30f;

struct Hasher {
    std::uint64_t h = 1469598103934665603ull;  // FNV-1a
    void bytes(const void* p, std::size_t n) {
        const auto* b = static_cast<const std::uint8_t*>(p);
        for (std::size_t i = 0; i < n; ++i) h = (h ^ b[i]) * 1099511628211ull;
    }
    template <class T>
    void add(T v) { bytes(&v, sizeof v); }
};

// A rectangle of tile cells, both corners included.
struct CellRect {
    int c0 = 0, r0 = 0, c1 = -1, r1 = -1;
    bool empty() const { return c1 < c0 || r1 < r0; }
};

// One Tilemap with occludesLight: the tiles that stop light, as a grid of flags over the cells some light can reach.
struct Occluder {
    const Tilemap* tm = nullptr;
    TilemapSize size;
    Mat4 inv;                // world -> the tilemap's local space (Parallax included: it is drawn there)
    Vec3 axisX, axisY;       // the world axes in local space: inv applied to (1,0,0) and (0,1,0)
    float m[4] = {1, 0, 0, -1};  // local -> cell space (tilemap_local_to_cell): the same walk for squares and diamonds
    std::vector<int> solid;  // tile indices that block light, sorted
    CellRect area;           // the cells `flags` covers
    std::vector<std::uint8_t> flags;

    bool solid_at(int c, int r) const {
        if (c < area.c0 || c > area.c1 || r < area.r0 || r > area.r1) return false;
        return flags[std::size_t(r - area.r0) * std::size_t(area.c1 - area.c0 + 1) + std::size_t(c - area.c0)] != 0;
    }
    // The cells of the map that a light at (px, py) with `radius` can reach (the bounding square of its disc).
    CellRect window(float px, float py, float radius) const {
        // Cell space (tilemap_local_to_cell): cell (c, r) is [c, c+1) x [r, r+1) whatever the projection; the cells that
        // touch the square are those of its bounding box in cell space.
        float fc0 = kInf, fc1 = -kInf, fr0 = kInf, fr1 = -kInf;
        for (int k = 0; k < 4; ++k) {
            const Vec3 q = inv.transform_point({px + ((k & 1) ? radius : -radius), py + ((k & 2) ? radius : -radius), 0.0f});
            const float a = m[0] * q.x + m[1] * q.y, b = m[2] * q.x + m[3] * q.y;
            fc0 = std::min(fc0, a); fc1 = std::max(fc1, a);
            fr0 = std::min(fr0, b); fr1 = std::max(fr1, b);
        }
        if (!(fc0 <= fc1) || !(fr0 <= fr1)) return {};
        fc0 = std::floor(fc0); fc1 = std::floor(fc1); fr0 = std::floor(fr0); fr1 = std::floor(fr1);
        CellRect w;
        w.c0 = int(std::clamp(fc0, 0.0f, float(size.width)));
        w.c1 = int(std::clamp(fc1, -1.0f, float(size.width - 1)));
        w.r0 = int(std::clamp(fr0, 0.0f, float(size.height)));
        w.r1 = int(std::clamp(fr1, -1.0f, float(size.height - 1)));
        return w;
    }
    bool any_solid(const CellRect& w) const {
        const int width = area.c1 - area.c0 + 1;
        for (int r = w.r0; r <= w.r1; ++r) {
            const std::uint8_t* row = &flags[std::size_t(r - area.r0) * std::size_t(width) + std::size_t(w.c0 - area.c0)];
            if (std::memchr(row, 1, std::size_t(w.c1 - w.c0 + 1))) return true;
        }
        return false;
    }
    void hash_window(Hasher& h, const CellRect& w) const {
        const int width = area.c1 - area.c0 + 1;
        h.add(w.c0); h.add(w.r0); h.add(w.c1); h.add(w.r1);
        for (int r = w.r0; r <= w.r1; ++r)
            h.bytes(&flags[std::size_t(r - area.r0) * std::size_t(width) + std::size_t(w.c0 - area.c0)],
                    std::size_t(w.c1 - w.c0 + 1));
    }
};

// Distance along a ray from the light to the far side of the first solid cell it enters, at most `radius`. The ray starts
// at (cx, cy) in cell space and goes by (dcx, dcy) per world unit; the cell the light is in never blocks it (a light
// inside a wall tile still lights the tile), the first solid cell after it does. Its own face stays lit: the stored
// distance is where the ray LEAVES that cell.
float cast_ray(const Occluder& o, float cx, float cy, float dcx, float dcy, float radius) {
    int ci = int(std::floor(cx)), cj = int(std::floor(cy));
    const int sx = dcx > 0.0f ? 1 : -1, sy = dcy > 0.0f ? 1 : -1;
    const float tdx = dcx != 0.0f ? 1.0f / std::fabs(dcx) : kInf;
    const float tdy = dcy != 0.0f ? 1.0f / std::fabs(dcy) : kInf;
    float tmx = dcx > 0.0f ? (float(ci + 1) - cx) * tdx : dcx < 0.0f ? (cx - float(ci)) * tdx : kInf;
    float tmy = dcy > 0.0f ? (float(cj + 1) - cy) * tdy : dcy < 0.0f ? (cy - float(cj)) * tdy : kInf;
    for (;;) {
        if (tmx < tmy) {
            if (tmx >= radius) return radius;
            ci += sx;
            tmx += tdx;
        } else {
            if (tmy >= radius) return radius;
            cj += sy;
            tmy += tdy;
        }
        if (o.solid_at(ci, cj)) return std::min(std::min(tmx, tmy), radius);
    }
}

struct Dir { float c, s; };
const std::vector<Dir>& directions() {
    static const std::vector<Dir> d = [] {
        std::vector<Dir> v;
        v.resize(std::size_t(kShadowAngles));
        for (int i = 0; i < kShadowAngles; ++i) {
            const double a = double(i) * 6.283185307179586 / double(kShadowAngles);
            v[std::size_t(i)] = {float(std::cos(a)), float(std::sin(a))};
        }
        return v;
    }();
    return d;
}

// One light that gets a row: where it is and which cells of which occluders it can reach.
struct LightWork {
    std::size_t light = 0;  // index in Frame::lights2d
    float px = 0, py = 0, radius = 0;
    std::vector<std::pair<std::size_t, CellRect>> windows;  // occluder, cells (never empty, with a solid tile in at least one)
};

}  // namespace

void assign_shadow_rows(World& world, Frame& f) {
    f.shadowData.clear();
    f.shadowRows = 0;
    f.shadowKey = 0;
    // The point lights that ask for shadows, in the order gather_lights ranked them.
    std::vector<std::size_t> asking;
    for (std::size_t i = 0; i < f.lights2d.size(); ++i) {
        const Light2DData& l = f.lights2d[i];
        if (l.pos[3] > 0.0f && std::isfinite(l.pos[3]) && l.extra[1] > 0.5f) asking.push_back(i);
    }
    if (asking.empty()) return;

    std::vector<Occluder> occluders;
    world.each<Tilemap>([&](Entity e, Tilemap& tm) {
        if (!tm.occludesLight || !entity_active(world, e) || !(tm.tileSize.x > 0.0f) || !(tm.tileSize.y > 0.0f)) return;
        Occluder o;
        o.size = tilemap_size(tm);
        if (o.size.empty() || !tm.solidTiles.is_array()) return;
        for (const Json& j : tm.solidTiles)
            if (j.is_number()) o.solid.push_back(tile_index(int(j.get<double>())));
        if (o.solid.empty()) return;
        std::sort(o.solid.begin(), o.solid.end());
        o.tm = &tm;
        tilemap_local_to_cell(tm, o.m);
        o.inv = visual_world_matrix(world, e).inverse();
        o.axisX = o.inv.transform_dir({1.0f, 0.0f, 0.0f});
        o.axisY = o.inv.transform_dir({0.0f, 1.0f, 0.0f});
        occluders.push_back(std::move(o));
    });
    if (occluders.empty()) return;

    // The cells every asking light can reach, per occluder: one grid of solid flags is read for all of them.
    for (Occluder& o : occluders) {
        CellRect u;
        for (std::size_t i : asking) {
            const Light2DData& l = f.lights2d[i];
            const CellRect w = o.window(l.pos[0], l.pos[1], l.pos[3]);
            if (w.empty()) continue;
            if (u.empty()) u = w;
            else u = {std::min(u.c0, w.c0), std::min(u.r0, w.r0), std::max(u.c1, w.c1), std::max(u.r1, w.r1)};
        }
        o.area = u;
        if (u.empty()) continue;
        o.flags.assign(std::size_t(u.c1 - u.c0 + 1) * std::size_t(u.r1 - u.r0 + 1), 0);
        std::size_t k = 0;
        for (int r = u.r0; r <= u.r1; ++r)
            for (int c = u.c0; c <= u.c1; ++c, ++k) {
                const int idx = tile_index(tilemap_tile_at(*o.tm, o.size, c, r));
                o.flags[k] = idx >= 0 && std::binary_search(o.solid.begin(), o.solid.end(), idx) ? 1 : 0;
            }
    }

    // A light gets a row when a solid tile lies within its reach: the first kMaxShadowLights2D of them in rank order.
    std::vector<LightWork> work;
    int over = 0;
    for (std::size_t i : asking) {
        const Light2DData& l = f.lights2d[i];
        LightWork w;
        w.light = i;
        w.px = l.pos[0]; w.py = l.pos[1]; w.radius = l.pos[3];
        bool solid = false;
        for (std::size_t k = 0; k < occluders.size(); ++k) {
            const Occluder& o = occluders[k];
            if (o.area.empty()) continue;
            const CellRect win = o.window(w.px, w.py, w.radius);
            if (win.empty()) continue;
            w.windows.push_back({k, win});
            solid = solid || o.any_solid(win);
        }
        if (!solid) continue;
        if (int(work.size()) < kMaxShadowLights2D) work.push_back(std::move(w));
        else ++over;
    }
    if (over > 0 && f.warnedShadows2d && !*f.warnedShadows2d) {
        *f.warnedShadows2d = true;
        FA_WARN("render",
                "{} Light2D with castShadows reach a solid tile of a Tilemap with occludesLight, but a frame gives shadows to at "
                "most {} lights: the {} ranked last shine through walls. Hint: set castShadows on fewer lights (the ones that "
                "light the most of the view come first), or give the others a smaller radius",
                int(work.size()) + over, kMaxShadowLights2D, over);
    }
    if (work.empty()) return;

    ShadowCache local;  // no cache kept: every row is made now
    ShadowCache& cache = f.shadowCache ? *f.shadowCache : local;
    Hasher all;
    const std::vector<Dir>& dirs = directions();
    for (LightWork& w : work) {
        Hasher h;
        h.add(w.px); h.add(w.py); h.add(w.radius);
        for (const auto& [k, win] : w.windows) {
            const Occluder& o = occluders[k];
            h.bytes(o.inv.m, sizeof(float) * 16);
            h.bytes(o.m, sizeof o.m);
            o.hash_window(h, win);
        }
        const std::uint64_t key = h.h;
        auto it = cache.rows.find(key);
        if (it == cache.rows.end()) {
            ShadowCache::Entry e;
            e.row.resize(std::size_t(kShadowAngles) * 4);
            struct Origin { float cx, cy; };
            std::vector<Origin> origin;
            for (const auto& [k, win] : w.windows) {
                const Occluder& o = occluders[k];
                const Vec3 q = o.inv.transform_point({w.px, w.py, 0.0f});
                origin.push_back({o.m[0] * q.x + o.m[1] * q.y, o.m[2] * q.x + o.m[3] * q.y});
            }
            for (int i = 0; i < kShadowAngles; ++i) {
                float best = w.radius;
                for (std::size_t n = 0; n < w.windows.size(); ++n) {
                    const Occluder& o = occluders[w.windows[n].first];
                    const float lx = dirs[std::size_t(i)].c * o.axisX.x + dirs[std::size_t(i)].s * o.axisY.x;
                    const float ly = dirs[std::size_t(i)].c * o.axisX.y + dirs[std::size_t(i)].s * o.axisY.y;
                    best = std::min(best, cast_ray(o, origin[n].cx, origin[n].cy, o.m[0] * lx + o.m[1] * ly, o.m[2] * lx + o.m[3] * ly, best));
                }
                const std::uint32_t v = std::uint32_t(std::lround(std::clamp(best / w.radius, 0.0f, 1.0f) * 65535.0f));
                std::uint8_t* t = &e.row[std::size_t(i) * 4];
                t[0] = std::uint8_t(v >> 8);
                t[1] = std::uint8_t(v & 255u);
                t[2] = 0;
                t[3] = 255;
            }
            it = cache.rows.emplace(key, std::move(e)).first;
        }
        it->second.used = cache.tick;
        f.lights2d[w.light].extra[0] = float(f.shadowRows);
        f.shadowData.insert(f.shadowData.end(), it->second.row.begin(), it->second.row.end());
        ++f.shadowRows;
        all.add(key);
    }
    all.add(f.shadowRows);
    f.shadowKey = all.h | 1u;
    if (f.stats) f.stats->lights2dShadowed += f.shadowRows;
    // Rows nobody asked for this frame (a light that moved) are kept a while, then dropped.
    if (cache.rows.size() > 4 * std::size_t(kMaxShadowLights2D)) {
        for (auto it = cache.rows.begin(); it != cache.rows.end();) {
            if (it->second.used != cache.tick) it = cache.rows.erase(it);
            else ++it;
        }
    }
}

}  // namespace fa::render
