// The terrain commands (M75.5, docs/BIG_WORLDS.md "Terrain" and "Terrain commands"): terrain.create, terrain.sculpt,
// terrain.paint, terrain.holes, terrain.generate, terrain.save, terrain.undo and terrain.redo.
//
// The edits are live: a command changes the TerrainHeights of the world's TerrainStore (fa/scene/terrain.h) in memory, as ONE
// step of that terrain's undo history, and bumps the versions the renderer and the physics collider follow, so the next frame
// shows and collides with the edit. The files (heightmap, holes mask, splat maps) are written by `save: true`, terrain.save and
// every scene save (save_scene_file), atomically. Everything is deterministic: the same arguments on the same terrain give the
// same bits (floats are only added, multiplied and square-rooted, and every rounding is a floor of x + 0.5).
//
// A brush is a circle in WORLD metres on the ground plane. The terrain's transform is honoured as terrain_sample does: the
// terrain may be moved, turned about Y and scaled; one tilted about X or Z is treated as upright.
#include <algorithm>
#include <cmath>
#include <cstring>
#include <format>
#include <limits>

#include "authoring_internal.h"
#include "fa/core/capability.h"
#include "fa/core/erosion.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/noise.h"
#include "fa/core/strings.h"
#include "fa/scene/serialize.h"
#include "fa/scene/terrain.h"

namespace fa {

namespace {

constexpr int kMaxBrushCells = 1024;            // the largest brush radius, in samples of the plane it edits
constexpr std::size_t kMaxStrokePoints = 4096;  // stamps of one command
constexpr std::uint64_t kMaxBrushVisits = std::uint64_t(1)
                                          << 26;  // samples looked at by one command, over all its stamps
constexpr std::uint64_t kMaxUnionSamples = std::uint64_t(1) << 25;  // the rectangle one command edits: 33 M samples
constexpr std::uint16_t kFlatRaw = 32768;  // a new flat terrain: half way up, so it can be lowered as well as raised

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

[[noreturn]] void bad(const std::string& pointer, const std::string& what, const std::string& hint) {
    throw CommandError("invalid_argument", what + " (at " + pointer + ")", hint);
}
[[noreturn]] void fail(const Error& e) { throw CommandError("invalid_argument", e.message, e.hint); }

double round3(double v) { return std::round(v * 1000.0) / 1000.0; }

// A finite number in [lo, hi] (the schema has checked the type; this keeps NaN, infinities and huge values out of every
// narrowing).
double number_at(const Json& v, const std::string& pointer, double lo, double hi) {
    if (!v.is_number()) bad(pointer, "Expected a number", "Write a plain number such as 12.5.");
    const double d = v.get<double>();
    if (!std::isfinite(d) || d < lo || d > hi)
        bad(pointer, std::format("{} is outside {} .. {}", d, lo, hi), "Use a value inside that range.");
    return d;
}

std::string file_stem(const std::string& id) {
    std::string out;
    for (char ch : id) {
        const bool ok =
            (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9') || ch == '_' || ch == '-';
        out.push_back(ok ? ch : '_');
    }
    return out.empty() ? std::string("terrain") : out;
}

std::string lower_ascii(std::string s) {
    for (char& c : s)
        if (c >= 'A' && c <= 'Z') c = char(c - 'A' + 'a');
    return s;
}

// The spelling of a project path that a command is about to write, judged by the project write rules: inside the project (an
// absolute path or a '..' that leaves it only for a caller that may write anywhere), and not in a managed folder. `where`
// names the argument ("/path") or the Terrain field ("Terrain.splatMaps[0]") in the error.
std::string write_target(const std::string& where, const std::string& path) {
    auto r = fs::resolve_for_write(path, fs::WriteRoot::Project, caller_capabilities().has(Capability::WriteAnywhere));
    if (!r.ok()) {
        const std::string code(fs::path_error_code(r.error()));
        throw CommandError(code.empty() ? "invalid_argument" : code,
                           "'" + path + "' (" + where + ") cannot be written: " + r.error().message,
                           "Use a path inside the project, such as assets/terrain/ground.height.png. " +
                               r.error().hint);
    }
    return fs::project_spelling(r.value());
}

bool ends_with_ci(const std::string& s, const char* suffix) {
    const std::size_t n = std::strlen(suffix);
    if (s.size() < n) return false;
    for (std::size_t i = 0; i < n; ++i) {
        char a = s[s.size() - n + i], b = suffix[i];
        if (a >= 'A' && a <= 'Z') a = char(a - 'A' + 'a');
        if (a != b) return false;
    }
    return true;
}

// ------------------------------------------------------------------------------------------------ the target terrain

struct Target {
    Entity entity = kNullEntity;
    std::string id;
    Terrain3D* terrain = nullptr;
    std::shared_ptr<TerrainHeights> heights;
    Mat4 m, inv;  // the entity's world matrix and its inverse
    float sizeX = 1, sizeZ = 1;
    float scaleY = 1;   // world metres of one local metre of height
    float groundY = 0;  // world y of the entity (the plane the brushes work on)
};

Entity need_terrain_entity(Engine::Impl& I, const Json& a, Terrain3D*& t) {
    Entity e = need_entity(I.world, a, "entity");
    t = I.world.get<Terrain3D>(e);
    if (!t)
        throw CommandError("invalid_argument",
                           "Entity '" + I.world.id_of(e) + "' has no Terrain component (at /entity).",
                           "Make a terrain with terrain.create, or add the component: scene.set_component {\"id\":\"" +
                               I.world.id_of(e) + "\",\"component\":\"Terrain\"}.");
    return e;
}

Target open_target(Engine::Impl& I, const Json& a) {
    Target tg;
    tg.entity = need_terrain_entity(I, a, tg.terrain);
    tg.id = I.world.id_of(tg.entity);
    Terrain3D& t = *tg.terrain;
    if (t.heightmap.empty())
        throw CommandError(
            "invalid_argument",
            "Terrain '" + tg.id +
                "' has no heightmap file (Terrain.heightmap is empty), so there is nothing to edit (at /entity).",
            "terrain.generate {\"entity\":\"" + tg.id +
                "\"} fills it with noise and sets the file; or set Terrain.heightmap to a 16-bit PNG.");
    if (!(t.size.x > 0.0f) || !(t.size.y > 0.0f) || !std::isfinite(t.size.x) || !std::isfinite(t.size.y))
        throw CommandError("invalid_argument", "Terrain.size of '" + tg.id + "' must be above 0 on both sides.",
                           "Set Terrain.size to metres such as [512, 512].");
    std::string problem;
    tg.heights = I.world.terrain().heights(I.world, tg.entity, &problem);
    if (!tg.heights)
        throw CommandError("invalid_argument",
                           problem.empty() ? "The heightmap of '" + tg.id + "' cannot be used." : problem,
                           "Fix Terrain.heightmap (a square 16-bit PNG or .r16, 33 to 4097 samples per side).");
    tg.m = I.world.world_matrix(tg.entity);
    {  // Mat4::inverse() answers the identity for a singular matrix: a terrain scaled to nothing has no brush space.
        const float* m = tg.m.m;
        const float det = m[0] * (m[5] * m[10] - m[6] * m[9]) - m[1] * (m[4] * m[10] - m[6] * m[8]) +
                          m[2] * (m[4] * m[9] - m[5] * m[8]);
        bool finite = true;
        for (int i = 0; i < 16; ++i) finite = finite && std::isfinite(m[i]);
        if (!finite || !(std::fabs(det) > 1e-12f))
            throw CommandError(
                "invalid_argument",
                "The transform of terrain '" + tg.id +
                    "' cannot be inverted (a scale of 0 on an axis, or a value that is not a number), so "
                    "a brush has no place on it (at /entity).",
                "Give the entity's Transform a scale above 0 on every axis, such as [1, 1, 1].");
    }
    tg.inv = tg.m.inverse();
    tg.sizeX = t.size.x;
    tg.sizeZ = t.size.y;
    tg.scaleY =
        std::sqrt(tg.m.at(1, 0) * tg.m.at(1, 0) + tg.m.at(1, 1) * tg.m.at(1, 1) + tg.m.at(1, 2) * tg.m.at(1, 2));
    tg.groundY = tg.m.translation().y;
    return tg;
}

// ------------------------------------------------------------------------------------------------ lattices and brushes

// The points of one plane of a terrain: index i is at local x = -sizeX / 2 + (i + off) * sizeX / denom (and z the same).
struct Lattice {
    int n = 0;
    float off = 0.0f;
    float denom = 1.0f;
};

Lattice heights_lattice(const Target& tg) { return {tg.heights->samples, 0.0f, float(tg.heights->cells())}; }
Lattice texel_lattice(int n) { return {n, 0.5f, float(n)}; }

struct IRect {
    int x0 = 0, y0 = 0, x1 = -1, y1 = -1;
    bool empty() const { return x1 < x0 || y1 < y0; }
    int w() const { return empty() ? 0 : x1 - x0 + 1; }
    int h() const { return empty() ? 0 : y1 - y0 + 1; }
    std::uint64_t area() const { return std::uint64_t(w()) * std::uint64_t(h()); }
    void join(const IRect& o) {
        if (o.empty()) return;
        if (empty()) {
            *this = o;
            return;
        }
        x0 = std::min(x0, o.x0);
        y0 = std::min(y0, o.y0);
        x1 = std::max(x1, o.x1);
        y1 = std::max(y1, o.y1);
    }
};

float lat_x(const Target& tg, const Lattice& l, int i) {
    return -tg.sizeX * 0.5f + (float(i) + l.off) * (tg.sizeX / l.denom);
}
float lat_z(const Target& tg, const Lattice& l, int j) {
    return -tg.sizeZ * 0.5f + (float(j) + l.off) * (tg.sizeZ / l.denom);
}

// The lattice indices whose world position can lie in the circle (cx, cz, radius): the bounding box of the circle in the
// terrain's local space, clamped to the plane. `span` is the unclamped width in indices.
IRect stamp_rect(const Target& tg, const Lattice& l, float cx, float cz, float radius, int& span) {
    float minX = std::numeric_limits<float>::max(), maxX = -minX, minZ = minX, maxZ = -minX;
    for (int sx = -1; sx <= 1; sx += 2)
        for (int sz = -1; sz <= 1; sz += 2) {
            const Vec3 p = tg.inv.transform_point({cx + float(sx) * radius, tg.groundY, cz + float(sz) * radius});
            minX = std::min(minX, p.x);
            maxX = std::max(maxX, p.x);
            minZ = std::min(minZ, p.z);
            maxZ = std::max(maxZ, p.z);
        }
    if (!std::isfinite(minX) || !std::isfinite(maxX) || !std::isfinite(minZ) || !std::isfinite(maxZ))
        bad("/center", "The brush position maps outside the numbers a terrain can hold",
            "Use a centre and a radius within a few thousand kilometres of the terrain.");
    const float lim = float(l.n) + 2.0f;
    auto range = [&](float lo, float hi, float size, int& i0, int& i1) {
        const float step = size / l.denom;
        const float f0 = std::clamp(std::ceil((lo + size * 0.5f) / step - l.off), -lim, lim);
        const float f1 = std::clamp(std::floor((hi + size * 0.5f) / step - l.off), -lim, lim);
        i0 = std::max(int(f0), 0);
        i1 = std::min(int(f1), l.n - 1);
        return int(f1 - f0) + 1;
    };
    IRect r;
    const int spanX = range(minX, maxX, tg.sizeX, r.x0, r.x1);
    const int spanZ = range(minZ, maxZ, tg.sizeZ, r.y0, r.y1);
    span = std::max(spanX, spanZ);
    return r;
}

struct Stamp {
    float x = 0, z = 0;
    IRect rect;
};
struct Stroke {
    float radius = 0;
    float falloff = 1.0f;  // the share of the radius the brush fades over (1 = from the middle, 0 = a hard edge)
    std::vector<Stamp> stamps;
    IRect all;  // the union of the stamps' rectangles, grown by `margin`
};

Stroke plan_stroke(const Json& a, const Target& tg, const Lattice& l, int margin) {
    Stroke s;
    const bool hasCenter = a.contains("center"), hasPoints = a.contains("points");
    if (hasCenter && hasPoints)
        bad("/points", "Both 'center' and 'points' were given",
            "Give one: 'center' [x, z] for a single stamp, or 'points' [[x, z], ...] for a stroke.");
    if (!hasCenter && !hasPoints)
        bad("/center", "Neither 'center' nor 'points' was given",
            "Give 'center' [x, z] in world metres for one stamp, or 'points' [[x, z], ...] for a stroke.");
    if (!a.contains("radius")) bad("/radius", "Missing 'radius'", "Give the brush radius in world metres, such as 8.");
    s.radius = float(number_at(a["radius"], "/radius", 1e-6, 1e7));
    if (a.contains("falloff")) s.falloff = float(number_at(a["falloff"], "/falloff", 0.0, 1.0));
    std::vector<Vec2> pts;
    auto read_point = [&](const Json& p, const std::string& pointer) {
        if (!p.is_array() || p.size() != 2)
            bad(pointer, "A point must be [x, z] in world metres", "Example: [120.5, -40].");
        pts.push_back(
            {float(number_at(p[0], pointer + "/0", -1e9, 1e9)), float(number_at(p[1], pointer + "/1", -1e9, 1e9))});
    };
    if (hasCenter) {
        read_point(a["center"], "/center");
    } else {
        const Json& arr = a["points"];
        if (!arr.is_array() || arr.empty())
            bad("/points", "'points' must be a list of [x, z] pairs", "Example: [[0,0],[2,0],[4,1]].");
        if (arr.size() > kMaxStrokePoints)
            bad("/points", std::format("{} points is more than the {} one command takes", arr.size(), kMaxStrokePoints),
                "Split the stroke over several commands (each one is one undo step).");
        for (std::size_t i = 0; i < arr.size(); ++i) read_point(arr[i], "/points/" + std::to_string(i));
    }
    std::uint64_t visits = 0;
    for (std::size_t i = 0; i < pts.size(); ++i) {
        int span = 0;
        Stamp st;
        st.x = pts[i].x;
        st.z = pts[i].y;
        st.rect = stamp_rect(tg, l, st.x, st.z, s.radius, span);
        if (span > 2 * kMaxBrushCells + 3)
            bad("/radius",
                std::format("A radius of {} m covers about {} samples across, more than the {} a brush may", s.radius,
                            span, 2 * kMaxBrushCells),
                "Use a smaller radius (at most " + std::to_string(kMaxBrushCells) +
                    " samples) or edit in several steps.");
        visits += st.rect.area();
        if (visits > kMaxBrushVisits)
            bad(hasPoints ? "/points" : "/radius",
                std::format("The stroke visits more than {} samples", kMaxBrushVisits),
                "Use fewer points or a smaller radius, and send the stroke in several commands.");
        IRect grown = st.rect;
        if (!grown.empty()) {
            grown.x0 = std::max(grown.x0 - margin, 0);
            grown.y0 = std::max(grown.y0 - margin, 0);
            grown.x1 = std::min(grown.x1 + margin, l.n - 1);
            grown.y1 = std::min(grown.y1 + margin, l.n - 1);
        }
        s.all.join(grown);
        if (s.all.area() > kMaxUnionSamples)
            bad(hasPoints ? "/points" : "/radius",
                std::format("The stroke edits a rectangle of {} samples, more than the {} one command takes",
                            s.all.area(), kMaxUnionSamples),
                "Send the stroke in several commands, each one over a smaller part of the terrain.");
        s.stamps.push_back(st);
    }
    return s;
}

// Calls fn(i, j, t) for every point of `r` whose world position is within the circle; t is its distance over the radius.
template <class F>
void visit_stamp(const Target& tg, const Lattice& l, const IRect& r, const Stamp& st, float radius, F&& fn) {
    const float r2 = radius * radius;
    for (int j = r.y0; j <= r.y1; ++j) {
        const float lz = lat_z(tg, l, j);
        for (int i = r.x0; i <= r.x1; ++i) {
            const Vec3 p = tg.m.transform_point({lat_x(tg, l, i), 0.0f, lz});
            const float dx = p.x - st.x, dz = p.z - st.z;
            const float d2 = dx * dx + dz * dz;
            if (d2 > r2) continue;
            fn(i, j, std::sqrt(d2) / radius);
        }
    }
}

// 1 at the middle of the brush, 0 at its edge, smooth in between. `width` is the share of the radius the fade covers: 1 fades from
// the middle (the default brush), a smaller one keeps the full effect up to radius * (1 - width) and fades from there, 0 is a hard
// edge.
float falloff(float t, float width) {
    if (width < 1e-4f) return t <= 1.0f ? 1.0f : 0.0f;
    const float inner = 1.0f - width;
    if (t <= inner) return 1.0f;
    const float f = 1.0f - std::min((t - inner) / width, 1.0f);
    return f * f * (3.0f - 2.0f * f);
}

// ------------------------------------------------------------------------------------------------ patches

std::vector<std::uint8_t> read_rect(const std::uint8_t* base, int planeW, const IRect& u, std::size_t elem) {
    std::vector<std::uint8_t> out(std::size_t(u.w()) * std::size_t(u.h()) * elem, 0);
    if (!base) return out;
    for (int r = 0; r < u.h(); ++r)
        std::memcpy(out.data() + std::size_t(r) * std::size_t(u.w()) * elem,
                    base + (std::size_t(u.y0 + r) * std::size_t(planeW) + std::size_t(u.x0)) * elem,
                    std::size_t(u.w()) * elem);
    return out;
}

struct Changes {
    IRect rect;
    std::uint64_t count = 0;
};

Changes diff_rect(const std::vector<std::uint8_t>& before, const std::vector<std::uint8_t>& after, const IRect& u,
                  std::size_t elem) {
    Changes c;
    for (int r = 0; r < u.h(); ++r)
        for (int col = 0; col < u.w(); ++col) {
            const std::size_t at = (std::size_t(r) * std::size_t(u.w()) + std::size_t(col)) * elem;
            if (std::memcmp(before.data() + at, after.data() + at, elem) == 0) continue;
            ++c.count;
            IRect one{u.x0 + col, u.y0 + r, u.x0 + col, u.y0 + r};
            c.rect.join(one);
        }
    return c;
}

TerrainPatch make_patch(TerrainPlane plane, const IRect& rect, const IRect& u, std::size_t elem,
                        const std::vector<std::uint8_t>& before, const std::vector<std::uint8_t>& after) {
    TerrainPatch p;
    p.plane = plane;
    p.x0 = rect.x0;
    p.y0 = rect.y0;
    p.w = rect.w();
    p.h = rect.h();
    const std::size_t rowBytes = std::size_t(p.w) * elem;
    p.before.resize(rowBytes * std::size_t(p.h));
    p.after.resize(rowBytes * std::size_t(p.h));
    for (int r = 0; r < p.h; ++r) {
        const std::size_t at =
            (std::size_t(rect.y0 + r - u.y0) * std::size_t(u.w()) + std::size_t(rect.x0 - u.x0)) * elem;
        std::memcpy(p.before.data() + std::size_t(r) * rowBytes, before.data() + at, rowBytes);
        std::memcpy(p.after.data() + std::size_t(r) * rowBytes, after.data() + at, rowBytes);
    }
    return p;
}

// `continueStroke`: true when the call adds to the newest undo step of the terrain instead of making one.
bool wants_continue(const Json& a) {
    return a.contains("continueStroke") && a["continueStroke"].is_boolean() && a["continueStroke"].get<bool>();
}

// Refuses `continueStroke` early (before anything changes) when the newest undo step of the terrain is not a `label` one.
void check_continue(const Target& tg, const Json& a, const char* label) {
    if (!wants_continue(a)) return;
    // A probe step with no patches would not tell; extend_step with an empty step checks the same rules without changing anything.
    TerrainStep probe;
    probe.label = label;
    std::string why;
    if (!tg.heights->extend_step(std::move(probe), &why))
        bad("/continueStroke", "Cannot continue the stroke: " + why,
            "Send the first piece of a stroke without continueStroke, and the following pieces right after it with "
            "continueStroke true (no other terrain edit and no terrain.undo in between).");
}

void commit(Target& tg, TerrainStep step, bool extend = false) {
    std::string why;
    if (extend ? !tg.heights->extend_step(std::move(step), &why) : !tg.heights->apply_step(std::move(step), &why))
        throw CommandError("internal_error", "The terrain edit did not fit its terrain: " + why,
                           "This is a bug: report it. Nothing was changed.");
}

// The world rectangle [minX, minZ, maxX, maxZ] of a rectangle of lattice indices.
Json world_bounds(const Target& tg, const Lattice& l, const IRect& r) {
    float minX = std::numeric_limits<float>::max(), maxX = -minX, minZ = minX, maxZ = -minX;
    for (int ci = 0; ci < 2; ++ci)
        for (int cj = 0; cj < 2; ++cj) {
            const Vec3 p = tg.m.transform_point({lat_x(tg, l, ci ? r.x1 : r.x0), 0.0f, lat_z(tg, l, cj ? r.y1 : r.y0)});
            minX = std::min(minX, p.x);
            maxX = std::max(maxX, p.x);
            minZ = std::min(minZ, p.z);
            maxZ = std::max(maxZ, p.z);
        }
    return Json::array({round3(minX), round3(minZ), round3(maxX), round3(maxZ)});
}

Json rect_json(const IRect& r) { return Json::object({{"c0", r.x0}, {"r0", r.y0}, {"c1", r.x1}, {"r1", r.y1}}); }

// Writes the files of one terrain; an error keeps the edit in memory and says so.
std::vector<std::string> save_files(Engine::Impl& I, Entity e) {
    std::vector<std::string> written;
    auto r = save_terrain_files(I.world, e, &written, caller_capabilities().has(Capability::WriteAnywhere));
    if (!r.ok())
        throw CommandError("write_failed", r.error().message + " The edit stays in memory (terrain.undo reverts it).",
                           r.error().hint);
    return written;
}

// What every editing command returns besides its own fields, and the optional save.
Json finish(Engine::Impl& I, const Target& tg, const Json& a, Json out) {
    out["entity"] = tg.id;
    if (a.contains("save") && a["save"].is_boolean() && a["save"].get<bool>()) {
        Json files = Json::array();
        for (const std::string& f : save_files(I, tg.entity)) files.push_back(f);
        out["saved"] = files;
    }
    out["unsaved"] = tg.heights->any_unsaved();
    out["undoDepth"] = tg.heights->undo_depth();
    out["redoDepth"] = tg.heights->redo_depth();
    out["undo"] = "terrain.undo {\"entity\":\"" + tg.id + "\"}";
    return out;
}

// ------------------------------------------------------------------------------------------------ terrain.sculpt

Json do_sculpt(Engine::Impl& I, const Json& a) {
    Target tg = open_target(I, a);
    check_continue(tg, a, "terrain.sculpt");
    TerrainHeights& h = *tg.heights;
    const std::string tool = a.contains("tool") ? a["tool"].get<std::string>() : "raise";
    const float strength = float(number_at(a.contains("strength") ? a["strength"] : Json(0.5), "/strength", 0.0, 1.0));
    const float amount = float(number_at(a.contains("amount") ? a["amount"] : Json(1.0), "/amount", 1e-6, 1e6));
    const float metresPerRaw = tg.terrain->heightScale * tg.scaleY / kTerrainRawMax;
    if (!(metresPerRaw > 1e-9f))
        throw CommandError("invalid_argument",
                           "Terrain '" + tg.id + "' has heightScale " + std::to_string(tg.terrain->heightScale) +
                               " (and a vertical scale of " + std::to_string(tg.scaleY) +
                               "), so a sample has no height to edit.",
                           "Set Terrain.heightScale to the metres of height of a white sample, such as 100.");
    const Lattice l = heights_lattice(tg);
    Stroke s = plan_stroke(a, tg, l, tool == "smooth" ? 1 : 0);
    Json out = Json::object({{"tool", tool}, {"stamps", s.stamps.size()}, {"changedSamples", 0}});
    if (s.all.empty()) {
        out["note"] = "The brush is outside the terrain: nothing changed.";
        return finish(I, tg, a, out);
    }
    // The target of "flatten": a world height, or the surface under the first stamp.
    float flatRaw = 0.0f;
    if (tool == "flatten") {
        float worldY = 0.0f;
        if (a.contains("height")) {
            worldY = float(number_at(a["height"], "/height", -1e7, 1e7));
        } else {
            TerrainSample smp;
            if (!terrain_sample(I.world, tg.entity, s.stamps[0].x, s.stamps[0].z, smp))
                bad("/height", "The first stamp is outside the terrain, so there is no surface to flatten to",
                    "Pass 'height' (world metres) or start the stroke on the terrain.");
            worldY = smp.height;
        }
        const float localY = tg.inv.transform_point({s.stamps[0].x, worldY, s.stamps[0].z}).y;
        flatRaw = (localY - tg.terrain->heightOffset) / tg.terrain->heightScale * kTerrainRawMax;
    }
    const IRect u = s.all;
    const std::size_t uw = std::size_t(u.w());
    std::vector<float> work(std::size_t(u.area()));
    for (int r = 0; r < u.h(); ++r)
        for (int c = 0; c < u.w(); ++c) work[std::size_t(r) * uw + std::size_t(c)] = float(h.at(u.x0 + c, u.y0 + r));
    const float deltaRaw = amount * strength / metresPerRaw * (tool == "lower" ? -1.0f : 1.0f);
    for (const Stamp& st : s.stamps) {
        if (st.rect.empty()) continue;
        auto idx = [&](int i, int j) { return std::size_t(j - u.y0) * uw + std::size_t(i - u.x0); };
        if (tool == "raise" || tool == "lower") {
            visit_stamp(tg, l, st.rect, st, s.radius,
                        [&](int i, int j, float t) { work[idx(i, j)] += deltaRaw * falloff(t, s.falloff); });
        } else if (tool == "flatten") {
            visit_stamp(tg, l, st.rect, st, s.radius, [&](int i, int j, float t) {
                float& v = work[idx(i, j)];
                v += (flatRaw - v) * strength * falloff(t, s.falloff);
            });
        } else {  // smooth: toward the mean of the 3 x 3 neighbours as they were before this stamp
            IRect g{std::max(st.rect.x0 - 1, 0), std::max(st.rect.y0 - 1, 0), std::min(st.rect.x1 + 1, l.n - 1),
                    std::min(st.rect.y1 + 1, l.n - 1)};
            std::vector<float> snap(std::size_t(g.area()));
            for (int j = g.y0; j <= g.y1; ++j)
                for (int i = g.x0; i <= g.x1; ++i)
                    snap[std::size_t(j - g.y0) * std::size_t(g.w()) + std::size_t(i - g.x0)] = work[idx(i, j)];
            visit_stamp(tg, l, st.rect, st, s.radius, [&](int i, int j, float t) {
                float sum = 0.0f;
                int count = 0;
                for (int dj = -1; dj <= 1; ++dj)
                    for (int di = -1; di <= 1; ++di) {
                        const int ni = std::clamp(i + di, 0, l.n - 1), nj = std::clamp(j + dj, 0, l.n - 1);
                        sum += snap[std::size_t(nj - g.y0) * std::size_t(g.w()) + std::size_t(ni - g.x0)];
                        ++count;
                    }
                float& v = work[idx(i, j)];
                v += (sum / float(count) - v) * strength * falloff(t, s.falloff);
            });
        }
    }
    std::vector<std::uint16_t> q(work.size());
    for (std::size_t i = 0; i < work.size(); ++i) {
        const float v = std::clamp(work[i], 0.0f, kTerrainRawMax);
        q[i] = std::uint16_t(std::floor(v + 0.5f));
    }
    std::vector<std::uint8_t> after(q.size() * 2);
    std::memcpy(after.data(), q.data(), after.size());
    const std::vector<std::uint8_t> before =
        read_rect(reinterpret_cast<const std::uint8_t*>(h.data.data()), h.samples, u, 2);
    const Changes ch = diff_rect(before, after, u, 2);
    if (ch.count > 0) {
        TerrainStep step;
        step.label = "terrain.sculpt";
        step.patches.push_back(make_patch(TerrainPlane::Heights, ch.rect, u, 2, before, after));
        commit(tg, std::move(step), wants_continue(a));
        if (wants_continue(a)) out["continued"] = true;
        out["changedSamples"] = ch.count;
        out["rect"] = rect_json(ch.rect);
        out["bounds"] = world_bounds(tg, l, ch.rect);
    }
    return finish(I, tg, a, out);
}

// ------------------------------------------------------------------------------------------------ terrain.holes

// True when `path` is a file already, or a Terrain of the world names it (compared without case: a project may be opened
// on a system that does not tell "Ground" from "ground").
bool terrain_path_taken(Engine::Impl& I, const std::string& path) {
    if (fs::exists(path)) return true;
    const std::string want = lower_ascii(path);
    bool taken = false;
    I.world.each<Terrain3D>([&](Entity, Terrain3D& t) {
        if (lower_ascii(t.heightmap) == want || lower_ascii(t.holes) == want) taken = true;
        if (t.splatMaps.is_array())
            for (const Json& m : t.splatMaps)
                if (m.is_string() && lower_ascii(m.get<std::string>()) == want) taken = true;
    });
    return taken;
}

// The file a terrain gets when it names none: assets/terrain/<stem>.<what>.<ext>, with _2, _3... after the stem until nothing
// has that name (file_stem maps "a/b" and "a_b" to one stem, and two ids may differ only in case). Checked by the project
// write rules.
std::string default_path(Engine::Impl& I, const std::string& stem, const std::string& what, const char* ext,
                         const std::string& where) {
    for (int n = 1; n < 100000; ++n) {
        const std::string name = n == 1 ? stem : stem + "_" + std::to_string(n);
        const std::string path = "assets/terrain/" + name + "." + what + "." + ext;
        if (!terrain_path_taken(I, path)) return write_target(where, path);
    }
    throw CommandError("invalid_argument", "No free file name was found for '" + stem + "." + what + "." + ext + "'.",
                       "Delete the unused files in assets/terrain/ or name the file yourself.");
}

Json do_holes(Engine::Impl& I, const Json& a) {
    Target tg = open_target(I, a);
    check_continue(tg, a, "terrain.holes");
    TerrainHeights& h = *tg.heights;
    const bool cut = !a.contains("mode") || a["mode"].get<std::string>() == "cut";
    const Lattice l = texel_lattice(h.cells());
    Stroke s = plan_stroke(a, tg, l, 0);
    Json out = Json::object({{"mode", cut ? "cut" : "fill"}, {"stamps", s.stamps.size()}, {"changedTexels", 0}});
    if (s.all.empty()) {
        out["note"] = "The brush is outside the terrain: nothing changed.";
        return finish(I, tg, a, out);
    }
    const IRect u = s.all;
    const bool haveMask = h.holes.size() == std::size_t(l.n) * std::size_t(l.n);
    const std::vector<std::uint8_t> before = read_rect(haveMask ? h.holes.data() : nullptr, l.n, u, 1);
    std::vector<std::uint8_t> after = before;
    const std::uint8_t value = cut ? 1 : 0;
    for (const Stamp& st : s.stamps) {
        if (st.rect.empty()) continue;
        visit_stamp(tg, l, st.rect, st, s.radius, [&](int i, int j, float) {
            after[std::size_t(j - u.y0) * std::size_t(u.w()) + std::size_t(i - u.x0)] = value;
        });
    }
    const Changes ch = diff_rect(before, after, u, 1);
    if (ch.count > 0) {
        if (tg.terrain->holes.empty()) {  // the mask gets its file name before its first cell
            const std::string path = default_path(I, file_stem(tg.id), "holes", "png", "Terrain.holes");
            h.holesSource = path;
            tg.terrain->holes = path;
            out["holes"] = path;
            out["sceneChanged"] = true;
        }
        TerrainStep step;
        step.label = "terrain.holes";
        step.patches.push_back(make_patch(TerrainPlane::Holes, ch.rect, u, 1, before, after));
        commit(tg, std::move(step), wants_continue(a));
        if (wants_continue(a)) out["continued"] = true;
        out["changedTexels"] = ch.count;
        out["rect"] = rect_json(ch.rect);
        out["bounds"] = world_bounds(tg, l, ch.rect);
    }
    return finish(I, tg, a, out);
}

// ------------------------------------------------------------------------------------------------ terrain.paint

// Whole bytes (sum 255) from `n` non-negative weights that add up to 1: floor, then the remainder to the largest fractions
// (the lower channel on a tie).
void quantize_weights(const float* w, int n, std::uint8_t* out) {
    int sum = 0;
    float frac[8];
    for (int i = 0; i < n; ++i) {
        const float x = std::clamp(w[i], 0.0f, 1.0f) * 255.0f;
        const float f = std::floor(x);
        out[i] = std::uint8_t(f);
        frac[i] = x - f;
        sum += int(out[i]);
    }
    for (int rem = 255 - sum; rem > 0; --rem) {
        int best = 0;
        for (int i = 1; i < n; ++i)
            if (frac[i] > frac[best]) best = i;
        if (out[best] < 255) ++out[best];
        frac[best] = -1.0f;
    }
}

Json do_paint(Engine::Impl& I, const Json& a) {
    Target tg = open_target(I, a);
    check_continue(tg, a, "terrain.paint");
    TerrainHeights& h = *tg.heights;
    Terrain3D& t = *tg.terrain;
    if (!a.contains("layer"))
        bad("/layer", "Missing 'layer'", "Give the layer index 0..7 (an index into Terrain.layers).");
    const int layer = int(number_at(a["layer"], "/layer", 0.0, double(kTerrainSplatMaps * 4 - 1)));
    const int layerCount = t.layers.is_array() ? int(t.layers.size()) : 0;
    if (layerCount > 0 && layer >= layerCount)
        bad("/layer", std::format("Layer {} does not exist: Terrain.layers has {} layer(s)", layer, layerCount),
            "Add the layer to Terrain.layers first (scene.set_component), or paint a layer below " +
                std::to_string(layerCount) + ".");
    const float strength = float(number_at(a.contains("strength") ? a["strength"] : Json(0.5), "/strength", 0.0, 1.0));
    const int mapOfLayer = layer / 4, channel = layer % 4;
    const int wantMaps = (mapOfLayer >= 1 || h.splat[1].valid()) ? 2 : 1;
    // The size of the maps: the one they have, or `splatResolution`, or the terrain's own cells (at most 1024).
    int size = 0;
    for (int k = 0; k < kTerrainSplatMaps; ++k)
        if (h.splat[std::size_t(k)].valid()) {
            if (size != 0 && size != h.splat[std::size_t(k)].size)
                throw CommandError("invalid_argument",
                                   std::format("Splat map 0 is {0} x {0} and splat map 1 is {1} x {1} pixels: they "
                                               "must be the same size to paint (at /splatMaps).",
                                               size, h.splat[std::size_t(k)].size),
                                   "Resize one of the two PNGs so both have the same size.");
            size = h.splat[std::size_t(k)].size;
        }
    if (a.contains("splatResolution")) {
        const int want = int(number_at(a["splatResolution"], "/splatResolution", 16.0, double(kTerrainMaxSplatSide)));
        if (size != 0 && want != size)
            bad("/splatResolution",
                std::format("The splat maps of '{}' already are {} x {} pixels, not {}", tg.id, size, size, want),
                "Leave splatResolution out to keep their size.");
        size = want;
    }
    if (size == 0) size = std::min(h.cells(), 1024);
    const Lattice l = texel_lattice(size);
    Stroke s = plan_stroke(a, tg, l, 0);
    Json out = Json::object({{"layer", layer},
                             {"map", mapOfLayer},
                             {"channel", channel},
                             {"stamps", s.stamps.size()},
                             {"changedTexels", 0}});
    if (s.all.empty()) {
        out["note"] = "The brush is outside the terrain: nothing changed.";
        return finish(I, tg, a, out);
    }
    const IRect u = s.all;
    std::vector<std::uint8_t> before[2], after[2];
    for (int k = 0; k < wantMaps; ++k) {
        // A map that does not exist yet is judged as it will start: map 0 all layer 0, map 1 all zeros. It is made only when the
        // brush changes something.
        const TerrainSplat& m = h.splat[std::size_t(k)];
        before[k] = read_rect(m.valid() ? m.rgba.data() : nullptr, size, u, 4);
        if (!m.valid() && k == 0)
            for (std::size_t p = 0; p < before[k].size(); p += 4) before[k][p] = 255;
        after[k] = before[k];
    }
    const int channels = 4 * wantMaps;
    const int target = layer;
    for (const Stamp& st : s.stamps) {
        if (st.rect.empty()) continue;
        visit_stamp(tg, l, st.rect, st, s.radius, [&](int i, int j, float tt) {
            const std::size_t at = (std::size_t(j - u.y0) * std::size_t(u.w()) + std::size_t(i - u.x0)) * 4;
            float w[8] = {};
            float sum = 0.0f;
            for (int k = 0; k < wantMaps; ++k)
                for (int c = 0; c < 4; ++c) {
                    w[k * 4 + c] = float(after[k][at + std::size_t(c)]);
                    sum += w[k * 4 + c];
                }
            if (sum <= 0.0f) {
                w[0] = 1.0f;
            } else {
                for (int c = 0; c < channels; ++c) w[c] /= sum;
            }
            const float amountHere = strength * falloff(tt, s.falloff);
            for (int c = 0; c < channels; ++c)
                w[c] = (c == target) ? w[c] + (1.0f - w[c]) * amountHere : w[c] * (1.0f - amountHere);
            std::uint8_t bytes[8];
            quantize_weights(w, channels, bytes);
            for (int k = 0; k < wantMaps; ++k)
                for (int c = 0; c < 4; ++c) after[k][at + std::size_t(c)] = bytes[k * 4 + c];
        });
    }
    TerrainStep step;
    step.label = "terrain.paint";
    std::uint64_t changed = 0;
    IRect changedRect;
    for (int k = 0; k < wantMaps; ++k) {
        const Changes ch = diff_rect(before[k], after[k], u, 4);
        if (ch.count == 0) continue;
        step.patches.push_back(
            make_patch(k == 0 ? TerrainPlane::Splat0 : TerrainPlane::Splat1, ch.rect, u, 4, before[k], after[k]));
        changed = std::max(changed, ch.count);
        changedRect.join(ch.rect);
    }
    if (!step.patches.empty()) {
        // Make the maps that do not exist yet. Everything that can be refused is checked first, so a refusal changes nothing.
        struct Fresh {
            int k;
            std::string path;
        };
        std::vector<Fresh> fresh;
        for (int k = 0; k < wantMaps; ++k) {
            if (h.splat[std::size_t(k)].valid()) continue;
            std::string path;
            if (t.splatMaps.is_array() && std::size_t(k) < t.splatMaps.size() &&
                t.splatMaps[std::size_t(k)].is_string())
                path = t.splatMaps[std::size_t(k)].get<std::string>();
            const std::string where = "Terrain.splatMaps[" + std::to_string(k) + "]";
            if (!path.empty() && fs::exists(path))
                throw CommandError(
                    "invalid_argument", where + " '" + path + "' exists but could not be loaded: " + h.planesProblem,
                    "Fix or delete the file, or point Terrain.splatMaps at another path; painting would overwrite it.");
            path = path.empty() ? default_path(I, file_stem(tg.id), "splat" + std::to_string(k), "png", where)
                                : write_target(where, path);
            fresh.push_back({k, path});
        }
        Json created = Json::array();
        for (const Fresh& f : fresh) {
            TerrainSplat& m = h.splat[std::size_t(f.k)];
            m = TerrainSplat{};
            m.size = size;
            m.rgba.assign(std::size_t(size) * std::size_t(size) * 4, 0);
            if (f.k == 0)
                for (std::size_t p = 0; p < m.rgba.size(); p += 4) m.rgba[p] = 255;
            m.source = f.path;
            m.unsaved = true;
            ++m.version;
            if (!t.splatMaps.is_array()) t.splatMaps = Json::array();
            while (t.splatMaps.size() <= std::size_t(f.k)) t.splatMaps.push_back("");
            if (!t.splatMaps[std::size_t(f.k)].is_string() ||
                t.splatMaps[std::size_t(f.k)].get<std::string>() != f.path) {
                t.splatMaps[std::size_t(f.k)] = f.path;
                out["sceneChanged"] = true;
            }
            created.push_back(f.path);
        }
        if (!created.empty()) out["created"] = created;
        commit(tg, std::move(step), wants_continue(a));
        if (wants_continue(a)) out["continued"] = true;
        out["changedTexels"] = changed;
        out["rect"] = rect_json(changedRect);
        out["bounds"] = world_bounds(tg, l, changedRect);
    }
    return finish(I, tg, a, out);
}

// ------------------------------------------------------------------------------------------------ terrain.generate

int checked_samples(const Json& v, const std::string& pointer) {
    const int n = int(number_at(v, pointer, 1.0, 1e7));
    int cells = n - 1;
    const bool pow2 = cells > 0 && (cells & (cells - 1)) == 0;
    if (!pow2 || n < kTerrainMinSamples || n > kTerrainMaxSamples) {
        int near = kTerrainMinSamples - 1;
        while (near + 1 < n && near < kTerrainMaxSamples - 1) near *= 2;
        bad(pointer,
            std::format("{} samples per side is not 2^k + 1 between {} and {}", n, kTerrainMinSamples,
                        kTerrainMaxSamples),
            "Use 33, 65, 129, 257, 513, 1025, 2049 or 4097 (nearest above: " + std::to_string(near + 1) + ").");
    }
    return n;
}

Json do_generate(Engine::Impl& I, const Json& a) {
    Terrain3D* t = nullptr;
    const Entity e = need_terrain_entity(I, a, t);
    const std::string id = I.world.id_of(e);
    if (!(t->size.x > 0.0f) || !(t->size.y > 0.0f))
        throw CommandError("invalid_argument", "Terrain.size of '" + id + "' must be above 0 on both sides.",
                           "Set it to metres such as [512, 512].");
    if (!(t->heightScale > 0.0f))
        throw CommandError("invalid_argument",
                           "Terrain.heightScale of '" + id + "' is " + std::to_string(t->heightScale) +
                               ": heights have no range.",
                           "Set Terrain.heightScale to the metres of height of a white sample, such as 100.");
    // The grid: the terrain's own, or `resolution` when it has no heightmap file yet.
    std::shared_ptr<TerrainHeights> h;
    int n = 0;
    const bool hadFile = !t->heightmap.empty();
    if (hadFile) {
        std::string problem;
        h = I.world.terrain().heights(I.world, e, &problem);
        if (!h)
            throw CommandError("invalid_argument",
                               problem.empty() ? "The heightmap of '" + id + "' cannot be used." : problem,
                               "Fix Terrain.heightmap, or clear it so terrain.generate makes a new one.");
        n = h->samples;
        if (a.contains("resolution") && checked_samples(a["resolution"], "/resolution") != n)
            bad("/resolution", std::format("'{}' already has a {} x {} heightmap", id, n, n),
                "Leave resolution out to keep its size, or clear Terrain.heightmap to make a new grid.");
    } else {
        n = a.contains("resolution") ? checked_samples(a["resolution"], "/resolution") : 513;
    }
    const int cells = n - 1;
    const float cell = t->size.x / float(cells);
    // The noise.
    NoiseParams np;
    np.type = NoiseType::Perlin;
    np.dimension = 2;
    const std::string fractal = a.contains("fractal") ? a["fractal"].get<std::string>() : "fbm";
    np.fractal = fractal == "ridged"   ? NoiseFractal::Ridged
                 : fractal == "billow" ? NoiseFractal::Billow
                                       : NoiseFractal::Fbm;
    np.seed = std::uint64_t(std::int64_t(number_at(a.contains("seed") ? a["seed"] : Json(1), "/seed", -9e15, 9e15)));
    np.frequency = float(number_at(a.contains("frequency") ? a["frequency"] : Json(0.004), "/frequency", 1e-7, 1e4));
    np.octaves =
        int(number_at(a.contains("octaves") ? a["octaves"] : Json(5), "/octaves", 1.0, double(kMaxNoiseOctaves)));
    np.output = NoiseOutput::Unit;
    if (auto r = validate_noise_params(np); !r.ok()) fail(r.error());
    const float amplitude =
        float(number_at(a.contains("amplitude") ? a["amplitude"] : Json(1.0), "/amplitude", 0.0, 1.0));
    // The erosion: hydraulic droplets, then thermal passes.
    HydraulicErosionParams hp;
    hp.seed = np.seed;
    hp.droplets =
        std::int64_t(number_at(a.contains("erosion") ? a["erosion"] : Json(0), "/erosion", 0.0, double(kMaxDroplets)));
    ThermalErosionParams tp;
    tp.iterations =
        int(number_at(a.contains("thermal") ? a["thermal"] : Json(0), "/thermal", 0.0, double(kMaxThermalIterations)));
    if (hp.droplets > 0) {
        if (auto r = validate_hydraulic_params(hp, "/erosion"); !r.ok()) fail(r.error());
        if (hydraulic_work(hp) > kMaxHydraulicSteps)
            bad("/erosion",
                std::format("{} droplets of {} steps is more than the {} steps one command runs", hp.droplets,
                            hp.maxLifetime, kMaxHydraulicSteps),
                "Use at most " + std::to_string(kMaxHydraulicSteps / std::uint64_t(hp.maxLifetime)) +
                    " droplets, and run the command again for more.");
    }
    if (tp.iterations > 0) {
        if (auto r = validate_thermal_params(tp, "/thermal"); !r.ok()) fail(r.error());
        if (thermal_work(n, n, tp) > kMaxThermalWork)
            bad("/thermal",
                std::format("{} passes over {} x {} samples is more than the {} updates one command runs",
                            tp.iterations, n, n, kMaxThermalWork),
                "Use fewer passes.");
    }
    std::vector<float> field(std::size_t(n) * std::size_t(n));
    if (auto r = fill_noise(field, n, n, np, {-t->size.x * 0.5f, -t->size.y * 0.5f}, cell); !r.ok()) fail(r.error());
    float lo = field[0], hi = field[0];
    for (float v : field) {
        lo = std::min(lo, v);
        hi = std::max(hi, v);
    }
    const float range = hi - lo;
    for (float& v : field) v = (range > 1e-12f ? (v - lo) / range : 0.5f) * amplitude * t->heightScale;
    HeightfieldView view{std::span<float>(field), n, n, cell};
    Json erosionInfo = Json::object();
    if (hp.droplets > 0) {
        auto r = erode_hydraulic(view, hp);
        if (!r.ok()) fail(r.error());
        erosionInfo["droplets"] = r.value().droplets;
    }
    if (tp.iterations > 0) {
        auto r = erode_thermal(view, tp);
        if (!r.ok()) fail(r.error());
        erosionInfo["thermalPasses"] = tp.iterations;
    }
    std::vector<std::uint16_t> raw(field.size());
    std::uint16_t minRaw = 65535, maxRaw = 0;
    for (std::size_t i = 0; i < field.size(); ++i) {
        const float v = std::clamp(field[i] / t->heightScale * kTerrainRawMax, 0.0f, kTerrainRawMax);
        raw[i] = std::uint16_t(std::floor(v + 0.5f));
        minRaw = std::min(minRaw, raw[i]);
        maxRaw = std::max(maxRaw, raw[i]);
    }
    // Nothing above can fail any more: bind the grid to the terrain and apply the new heights as one step.
    Json out = Json::object();
    if (!hadFile) {
        const std::string path = default_path(I, file_stem(id), "height", "png", "Terrain.heightmap");
        h = TerrainHeights::flat(n, 0);
        I.world.terrain().adopt(e, path, h);
        t->heightmap = path;
        out["sceneChanged"] = true;
    }
    TerrainStep step;
    step.label = "terrain.generate";
    TerrainPatch p;
    p.plane = TerrainPlane::Heights;
    p.w = p.h = n;
    p.before.resize(raw.size() * 2);
    p.after.resize(raw.size() * 2);
    std::memcpy(p.before.data(), h->data.data(), p.before.size());
    std::memcpy(p.after.data(), raw.data(), p.after.size());
    std::uint64_t changed = 0;
    for (std::size_t i = 0; i < raw.size(); ++i)
        if (h->data[i] != raw[i]) ++changed;
    if (changed > 0 || !hadFile) {
        step.patches.push_back(std::move(p));
        std::string why;
        if (!h->apply_step(std::move(step), &why))
            throw CommandError("internal_error", "The generated heights did not fit the terrain: " + why,
                               "This is a bug: report it.");
    }
    out["heightmap"] = t->heightmap;
    out["samples"] = n;
    out["changedSamples"] = changed;
    out["minHeight"] = round3(double(t->heightOffset) + double(t->heightScale) * double(minRaw) / 65535.0);
    out["maxHeight"] = round3(double(t->heightOffset) + double(t->heightScale) * double(maxRaw) / 65535.0);
    if (!erosionInfo.empty()) out["erosion"] = erosionInfo;
    Target tg;
    tg.entity = e;
    tg.id = id;
    tg.heights = h;
    return finish(I, tg, a, out);
}

// ------------------------------------------------------------------------------------------------ terrain.create

Json do_create(Engine::Impl& I, const Json& a) {
    std::string name = a.contains("name") && a["name"].is_string() ? a["name"].get<std::string>() : std::string();
    if (!name.empty() && I.world.find_by_id(name))
        bad("/name", "An entity with the id '" + name + "' already exists",
            "Pick another name, or edit that terrain with terrain.sculpt.");
    Entity parent = kNullEntity;
    if (a.contains("parent")) parent = need_entity(I.world, a, "parent");
    float size[2] = {512.0f, 512.0f};
    if (a.contains("size")) {
        if (!a["size"].is_array() || a["size"].size() != 2)
            bad("/size", "'size' must be [x, z] in metres", "Example: [1024, 1024].");
        size[0] = float(number_at(a["size"][0], "/size/0", 1e-3, 1e7));
        size[1] = float(number_at(a["size"][1], "/size/1", 1e-3, 1e7));
    }
    const float heightScale =
        float(number_at(a.contains("heightScale") ? a["heightScale"] : Json(100.0), "/heightScale", 1e-3, 1e6));
    const float baseHeight =
        float(number_at(a.contains("baseHeight") ? a["baseHeight"] : Json(0.0), "/baseHeight", -1e7, 1e7));
    Json position = Json::array({0, 0, 0});
    if (a.contains("position")) {
        const Json& p = a["position"];
        if (!p.is_array() || p.size() != 3)
            bad("/position", "'position' must be [x, y, z] in metres", "Example: [0, 0, 0].");
        position = Json::array();
        for (std::size_t i = 0; i < 3; ++i)
            position.push_back(number_at(p[i], "/position/" + std::to_string(i), -1e9, 1e9));
    }
    if (a.contains("heightmap") && a.contains("resolution"))
        bad("/resolution", "'heightmap' (import) and 'resolution' (a new flat grid) were both given",
            "Give one: the imported file brings its own size.");
    if (a.contains("heightmap") && a.contains("path"))
        bad("/path", "'heightmap' (import: nothing is written) and 'path' (where a new file goes) were both given",
            "Give one: 'path' for a new flat heightmap, or 'heightmap' to use an existing file.");
    if (name.empty()) {  // no name: "terrain", "terrain_2"... the first that no entity has and no file of a new heightmap takes
        const bool writesDefault = !a.contains("heightmap") && !a.contains("path");
        for (int n = 1; name.empty(); ++n) {
            const std::string candidate = n == 1 ? "terrain" : "terrain_" + std::to_string(n);
            if (n > 100000) throw CommandError("invalid_argument", "No free terrain name was found.", "Pass a 'name'.");
            if (!I.world.find_by_id(candidate) &&
                !(writesDefault && terrain_path_taken(I, "assets/terrain/" + candidate + ".height.png")))
                name = candidate;
        }
    }
    Json terrain = Json::object({{"size", Json::array({size[0], size[1]})}, {"heightScale", heightScale}});
    Json out = Json::object();
    if (a.contains("heightmap")) {
        const std::string hm = a["heightmap"].get<std::string>();
        auto load = load_terrain_heightmap(hm);
        if (!load) throw CommandError("invalid_argument", load.error().message + " (at /heightmap)", load.error().hint);
        terrain["heightmap"] = hm;
        terrain["heightOffset"] = baseHeight;
        out["heightmap"] = hm;
        out["samples"] = load->heights->samples;
        out["imported"] = true;
    } else {
        const int n = a.contains("resolution") ? checked_samples(a["resolution"], "/resolution") : 513;
        std::string path = a.contains("path") && a["path"].is_string()
                               ? write_target("/path", a["path"].get<std::string>())
                               : default_path(I, file_stem(name), "height", "png", "/name");
        if (!ends_with_ci(path, ".png") && !ends_with_ci(path, ".r16"))
            bad("/path", "The heightmap file '" + path + "' must end in .png or .r16",
                "Example: assets/terrain/ground.height.png.");
        if (fs::exists(path))
            bad(a.contains("path") ? "/path" : "/name",
                "The file '" + path + "' already exists and would be overwritten",
                "Pick another name or path, or import it: terrain.create {\"heightmap\":\"" + path + "\"}.");
        auto flat = TerrainHeights::flat(n, kFlatRaw);
        const std::vector<std::uint8_t> bytes = encode_terrain_heightmap(*flat, path);
        if (bytes.empty())
            throw CommandError("internal_error", "The heightmap could not be encoded.", "This is a bug: report it.");
        if (auto r = fs::write_bytes(path, bytes.data(), bytes.size()); !r.ok())
            throw CommandError(
                "write_failed", "The heightmap '" + path + "' could not be written: " + r.error().message,
                r.error().hint.empty() ? "Check that the folder is writable. Nothing was created." : r.error().hint);
        terrain["heightmap"] = path;
        // The flat surface sits at baseHeight: raw 32768 of 65535 is half way up the scale.
        terrain["heightOffset"] = double(baseHeight) - double(heightScale) * double(kFlatRaw) / 65535.0;
        out["heightmap"] = path;
        out["samples"] = n;
    }
    Json spec = Json::object(
        {{"components", Json::object({{"Terrain", terrain}, {"Transform", Json::object({{"position", position}})}})}});
    spec["name"] = name;
    spec["id"] = name;
    LoadReport report;
    Entity e = entity_from_json(I.world, spec, parent, report, "terrain.create");
    if (!e || !I.world.alive(e) || report.error_count() > 0) {
        for (Entity c : report.created)
            if (I.world.alive(c)) I.world.destroy(c);
        I.world.flush();
        throw CommandError("invalid_argument", "The terrain entity could not be created:\n" + report.summary(),
                           "Fix what is listed. The heightmap file written above stays in the project.");
    }
    out["entity"] = I.world.id_of(e);
    out["size"] = Json::array({size[0], size[1]});
    return out;
}

// ------------------------------------------------------------------------------------------------ undo, redo, save

Json do_undo_redo(Engine::Impl& I, const Json& a, bool undo) {
    Terrain3D* t = nullptr;
    const Entity e = need_terrain_entity(I, a, t);
    const std::string id = I.world.id_of(e);
    std::string problem;
    auto h = I.world.terrain().heights(I.world, e, &problem);
    if (!h)
        throw CommandError("invalid_argument",
                           problem.empty() ? "The heightmap of '" + id + "' cannot be used." : problem,
                           "Fix Terrain.heightmap.");
    std::string label;
    if (!(undo ? h->undo(&label) : h->redo(&label)))
        throw CommandError(undo ? "nothing_to_undo" : "nothing_to_redo",
                           std::string("Terrain '") + id + "' has no edit to " + (undo ? "undo" : "redo") + ".",
                           undo ? "The history holds the last " + std::to_string(kTerrainHistorySteps) +
                                      " terrain edits since the scene loaded; terrain.redo brings back an undone one."
                                : "Redo only follows an undo; a new edit clears the redo list.");
    Json out = Json::object({{"entity", id}, {undo ? "undone" : "redone", label}});
    out["unsaved"] = h->any_unsaved();
    out["undoDepth"] = h->undo_depth();
    out["redoDepth"] = h->redo_depth();
    if (a.contains("save") && a["save"].is_boolean() && a["save"].get<bool>()) {
        Json files = Json::array();
        for (const std::string& f : save_files(I, e)) files.push_back(f);
        out["saved"] = files;
        out["unsaved"] = h->any_unsaved();
    }
    return out;
}

Json do_save(Engine::Impl& I, const Json& a) {
    std::vector<std::string> written;
    const bool anywhere = caller_capabilities().has(Capability::WriteAnywhere);
    if (a.contains("entity")) {
        Terrain3D* t = nullptr;
        const Entity e = need_terrain_entity(I, a, t);
        auto r = save_terrain_files(I.world, e, &written, anywhere);
        if (!r.ok()) throw CommandError("write_failed", r.error().message, r.error().hint);
    } else {
        auto r = save_all_terrain_files(I.world, &written, anywhere);
        if (!r.ok()) throw CommandError("write_failed", r.error().message, r.error().hint);
    }
    Json files = Json::array();
    for (const std::string& f : written) files.push_back(f);
    return Json::object({{"saved", files}});
}

// ------------------------------------------------------------------------------------------------ registration

constexpr char kSaveProp[] =
    R"("save":{"type":"boolean","default":false,"description":"Also write the changed files now (the heightmap PNG, holes PNG, splat map PNGs; atomic). Without it they are written by terrain.save and by every scene save."})";
constexpr char kBrushProps[] =
    R"("center":{"type":"array","items":{"type":"number"},"minItems":2,"maxItems":2,"description":"World metres [x, z] of one stamp. Give center or points, not both."},
       "points":{"type":"array","items":{"type":"array","items":{"type":"number"},"minItems":2,"maxItems":2},"minItems":1,"maxItems":4096,"description":"A stroke: up to 4096 stamps [[x, z], ...] applied in order, each seeing the result of the one before. One undo step."},
       "radius":{"type":"number","exclusiveMinimum":0,"description":"Brush radius in world metres (at most 1024 samples of the edited image)."},
       "continueStroke":{"type":"boolean","default":false,"description":"Add this call to the terrain's newest undo step instead of making a new one: a stroke sent in pieces (a brush that applies live while the mouse is down) is still ONE undo step. The newest step must be an edit of the same command and nothing may have been undone since; otherwise an error. The first piece is sent without it."})";

}  // namespace

void register_terrain3d_commands(Engine& engine, Engine::Impl& I) {
    (void)engine;
    const std::string entityProp = R"("entity":{"type":"string","description":"Entity id of the Terrain."})";
    const std::string brush = std::string(kBrushProps);
    const std::string save = std::string(kSaveProp);

    I.commands.add({"terrain.create",
                    "Create a Terrain entity with a new flat 16-bit heightmap file, or one that imports a heightmap.",
                    "Writes a flat 16-bit greyscale PNG heightmap of `resolution` x `resolution` samples (2^k + 1: 33 "
                    "... 4097; the default 513) to "
                    "`path` (default assets/terrain/<name>.height.png; an existing file is never overwritten) and "
                    "creates an entity with a Terrain "
                    "component that uses it, `size` metres wide, centred on the entity at `position`. The flat surface "
                    "is at `baseHeight` "
                    "(default 0) and sits half way up the `heightScale` range, so terrain.sculpt can lower it as well "
                    "as raise it. With `heightmap` "
                    "the entity uses that existing 16-bit PNG or .r16 file instead and writes nothing. The Terrain has "
                    "no layers: add them with "
                    "scene.set_component (each needs an albedo texture). Result: {entity, heightmap, samples, size}. "
                    "Example: terrain.create {\"name\":\"ground\",\"size\":[1024,1024],\"resolution\":513}",
                    parse_schema(R"({"type":"object","properties":{
               "name":{"type":"string","description":"Entity id and name of the terrain (default: terrain, made unique)."},
               "size":{"type":"array","items":{"type":"number","exclusiveMinimum":0},"minItems":2,"maxItems":2,"description":"Metres [x, z] the terrain covers (default [512, 512])."},
               "resolution":{"type":"integer","minimum":33,"maximum":4097,"description":"Samples per side of a new heightmap: 2^k + 1 (33, 65, 129, 257, 513, 1025, 2049, 4097; default 513). Not with heightmap."},
               "heightmap":{"type":"string","description":"Use this existing 16-bit greyscale PNG or .r16 file (project path) instead of a flat one; nothing is written."},
               "path":{"type":"string","x-fa-path":"write","description":"Project path of the heightmap to write (.png or .r16). Default assets/terrain/<name>.height.png."},
               "heightScale":{"type":"number","exclusiveMinimum":0,"default":100,"description":"Metres of height of a white sample (the height range)."},
               "baseHeight":{"type":"number","default":0,"description":"New flat terrain: the height of its surface in metres. Imported: Terrain.heightOffset."},
               "position":{"type":"array","items":{"type":"number"},"minItems":3,"maxItems":3,"description":"World position [x, y, z] of the terrain's centre (default [0, 0, 0])."},
               "parent":{"type":"string","description":"Parent entity id."}}})"),
                    false, "world"},
                   [&I](const Json& a) { return do_create(I, a); });

    I.commands.add(
        {"terrain.sculpt",
         "Raise, lower, smooth or flatten the heights of a Terrain with a brush (live, one undo step).",
         "Edits the samples of the terrain's heightmap within `radius` world metres of `center` (or of every point of "
         "`points`, a stroke) "
         "with the brush `tool`: raise or lower by `amount` metres x `strength` at the middle of the brush, smooth "
         "toward the mean of the "
         "neighbours, flatten toward `height` (world metres; default the surface under the first stamp) by `strength`. "
         "The effect fades "
         "smoothly to nothing at the edge of the circle (`falloff` makes the fade narrower). The edit is live in "
         "memory (the renderer and the physics "
         "collider follow it) "
         "and is ONE undo step of the terrain (terrain.undo); the file is written by `save` true, terrain.save or a "
         "scene save. "
         "Deterministic. The terrain's transform is honoured (moved, turned about Y, scaled). Result: {changedSamples, "
         "rect (sample "
         "indices), bounds ([minX, minZ, maxX, maxZ] world), continued?, undoDepth, unsaved, undo}. `continueStroke` "
         "adds the call to the newest undo step (a stroke sent in pieces is one step). "
         "Example: terrain.sculpt "
         "{\"entity\":\"ground\",\"tool\":\"raise\",\"center\":[100,50],\"radius\":20,\"amount\":5}",
         parse_schema(
             ("{\"type\":\"object\",\"properties\":{" + entityProp + "," +
              R"("tool":{"type":"string","enum":["raise","lower","smooth","flatten"],"default":"raise","description":"The brush."},)" +
              brush + "," +
              R"("strength":{"type":"number","minimum":0,"maximum":1,"default":0.5,"description":"How much of the brush applies per stamp (0 nothing, 1 all)."},
                          "falloff":{"type":"number","minimum":0,"maximum":1,"default":1,"description":"The share of the radius the brush fades over: 1 fades from the middle to the edge (the default), 0.25 keeps the full effect up to 75% of the radius, 0 is a hard edge."},
                          "amount":{"type":"number","exclusiveMinimum":0,"default":1,"description":"raise and lower: metres a stamp changes the height at the middle of the brush when strength is 1."},
                          "height":{"type":"number","description":"flatten: the world y to flatten to (default: the surface under the first stamp)."},)" +
              save + "}, \"required\":[\"entity\",\"radius\"]}")
                 .c_str()),
         false, "world"},
        [&I](const Json& a) { return do_sculpt(I, a); });

    I.commands.add(
        {"terrain.paint", "Paint a material layer of a Terrain with a brush (splat maps, live, one undo step).",
         "Raises the weight of `layer` (0 ... 7, an index into Terrain.layers) within `radius` world metres of "
         "`center` (or along "
         "`points`) by `strength` with a smooth falloff and lowers the others in proportion, so the 8 weights of every "
         "texel always add "
         "up to 255 (renormalised). Layer L is channel L % 4 (r, g, b, a) of splat map L / 4. The maps are created on "
         "the first paint "
         "(assets/terrain/<name>.splat0.png and .splat1.png, RGBA8 linear, `splatResolution` texels per side, default "
         "the terrain's "
         "cells up to 1024) and Terrain.splatMaps is set; map 0 starts as all layer 0. Live and ONE undo step; written "
         "by `save` true, "
         "terrain.save or a scene save. Result: {changedTexels, layer, map, channel, created?, rect, bounds, "
         "continued?, undoDepth}. `falloff` narrows the fade and `continueStroke` adds the call to the newest undo "
         "step (a stroke sent in pieces is one step). "
         "Example: terrain.paint {\"entity\":\"ground\",\"layer\":1,\"center\":[10,10],\"radius\":8}",
         parse_schema(
             ("{\"type\":\"object\",\"properties\":{" + entityProp + "," +
              R"("layer":{"type":"integer","minimum":0,"maximum":7,"description":"Index into Terrain.layers (map = layer / 4, channel = layer % 4)."},)" +
              brush + "," +
              R"("strength":{"type":"number","minimum":0,"maximum":1,"default":0.5,"description":"How much of the layer's weight a stamp reaches at the middle of the brush."},
                          "falloff":{"type":"number","minimum":0,"maximum":1,"default":1,"description":"The share of the radius the brush fades over: 1 fades from the middle to the edge (the default), 0.25 keeps the full effect up to 75% of the radius, 0 is a hard edge."},
                          "splatResolution":{"type":"integer","minimum":16,"maximum":4096,"description":"Texels per side of splat maps that do not exist yet (default: the terrain's cells, at most 1024). Existing maps keep their size."},)" +
              save + "}, \"required\":[\"entity\",\"layer\",\"radius\"]}")
                 .c_str()),
         false, "world"},
        [&I](const Json& a) { return do_paint(I, a); });

    I.commands.add(
        {"terrain.holes", "Cut or fill holes (caves, tunnels) in a Terrain with a circle brush (live, one undo step).",
         "Sets the cells of the terrain's holes mask whose centre is within `radius` world metres of `center` (or of "
         "the `points` of "
         "a stroke): mode \"cut\" makes them holes, \"fill\" closes them. A hole is neither drawn nor collided: the "
         "physics collider "
         "follows the edit at once. The mask has one byte per CELL (cells x cells, 1 = hole) and is saved as an 8-bit "
         "greyscale PNG "
         "(255 = hole) at assets/terrain/<name>.holes.png, which the first cut sets in Terrain.holes. A brush smaller "
         "than a cell can "
         "miss every cell centre. Live and ONE undo step; written by `save` true, terrain.save or a scene save. "
         "Result: {changedTexels, rect, bounds, continued?, undoDepth}. `continueStroke` adds the call to the newest "
         "undo step (a stroke sent in pieces is one step). "
         "Example: terrain.holes {\"entity\":\"ground\",\"center\":[0,0],\"radius\":3}",
         parse_schema(
             ("{\"type\":\"object\",\"properties\":{" + entityProp + "," +
              R"("mode":{"type":"string","enum":["cut","fill"],"default":"cut","description":"Make a hole or close one."},)" +
              brush + "," + save + "}, \"required\":[\"entity\",\"radius\"]}")
                 .c_str()),
         false, "world"},
        [&I](const Json& a) { return do_holes(I, a); });

    I.commands.add(
        {"terrain.generate",
         "Fill a Terrain's heightmap with seeded procedural noise and optional erosion (one undo step).",
         "Replaces the heights with fractal Perlin noise (`seed`, `frequency` features per metre, `octaves`, "
         "`fractal`) stretched to the "
         "height range (`amplitude` is the share of Terrain.heightScale it uses), then `erosion` droplets of hydraulic "
         "erosion and "
         "`thermal` passes of thermal erosion, all deterministic: the same arguments always give the same heights, on "
         "any machine "
         "and thread count. A terrain with no heightmap gets a new grid of `resolution` samples and the path "
         "assets/terrain/<name>.height.png. The noise follows the X axis: a terrain that is not square is stretched in "
         "z. All checks "
         "(and the work caps) run before anything changes; the replacement is ONE undo step. Result: {heightmap, "
         "samples, "
         "changedSamples, minHeight, maxHeight (metres, before Transform.scale), erosion, undoDepth}. "
         "Example: terrain.generate {\"entity\":\"ground\",\"seed\":7,\"octaves\":5,\"erosion\":50000}",
         parse_schema(("{\"type\":\"object\",\"properties\":{" + entityProp + "," +
                       R"("seed":{"type":"integer","default":1,"description":"The same seed gives the same terrain."},
                          "frequency":{"type":"number","exclusiveMinimum":0,"default":0.004,"description":"Noise features per metre of the first octave."},
                          "octaves":{"type":"integer","minimum":1,"maximum":10,"default":5,"description":"Layers of noise."},
                          "fractal":{"type":"string","enum":["fbm","ridged","billow"],"default":"fbm","description":"How the octaves combine: rolling hills, sharp ridges or puffy mounds."},
                          "amplitude":{"type":"number","minimum":0,"maximum":1,"default":1,"description":"Share of the height range (Terrain.heightScale) the terrain uses."},
                          "erosion":{"type":"integer","minimum":0,"maximum":100000000,"default":0,"description":"Droplets of hydraulic erosion (0 = none; 50000 is a good start for 513 samples). At most 8.9 million with the default droplet life."},
                          "thermal":{"type":"integer","minimum":0,"maximum":100000,"default":0,"description":"Passes of thermal erosion (slopes steeper than 35 degrees slide); 0 = none."},
                          "resolution":{"type":"integer","minimum":33,"maximum":4097,"description":"Only for a terrain without a heightmap: samples per side (2^k + 1, default 513)."},)" +
                       save + "}, \"required\":[\"entity\"]}")
                          .c_str()),
         false, "world"},
        [&I](const Json& a) { return do_generate(I, a); });

    I.commands.add({"terrain.save", "Write the edited files of one Terrain, or of every Terrain, to the project.",
                    "Writes what terrain.sculpt, terrain.paint, terrain.holes and terrain.generate changed since the "
                    "files were loaded or last "
                    "written: the heightmap (16-bit PNG, or raw .r16), the holes mask (8-bit PNG) and the splat maps "
                    "(RGBA PNG), each replaced "
                    "atomically. Nothing to write is fine. A scene save does the same for every terrain. Result: "
                    "{saved: [paths]}. "
                    "Example: terrain.save {\"entity\":\"ground\"}",
                    parse_schema(R"({"type":"object","properties":{
               "entity":{"type":"string","description":"Entity id of the Terrain (default: every Terrain with edits)."}}})"),
                    false, "world"},
                   [&I](const Json& a) { return do_save(I, a); });

    for (bool undo : {true, false}) {
        I.commands.add(
            {undo ? "terrain.undo" : "terrain.redo",
             undo ? "Undo the last terrain edit of a Terrain (one command's worth of heights, holes and splat maps)."
                  : "Redo the terrain edit the last terrain.undo took back.",
             std::string(undo ? "Puts back the samples the newest sculpt, paint, holes or generate command changed, "
                                "bit for bit. "
                              : "Applies the undone edit again. ") +
                 "Each terrain keeps the last 64 edits (and at most 256 MB of before/after samples) since the scene "
                 "loaded; a new "
                 "edit clears the redo list. Only the data changes: components set by a command (a Terrain.holes or "
                 "splatMaps path "
                 "a first edit chose) stay. `save` writes the files afterwards. Result: {undone|redone, undoDepth, "
                 "redoDepth, "
                 "unsaved}. Example: " +
                 std::string(undo ? "terrain.undo" : "terrain.redo") + " {\"entity\":\"ground\"}",
             parse_schema(R"({"type":"object","properties":{
               "entity":{"type":"string","description":"Entity id of the Terrain."},
               "save":{"type":"boolean","default":false,"description":"Also write the changed files now."}},"required":["entity"]})"),
             false, "world"},
            [&I, undo](const Json& a) { return do_undo_redo(I, a, undo); });
    }

    declare_command_capabilities(I.commands, {{"terrain.create", capability_sets::edits_project()},
                                              {"terrain.sculpt", capability_sets::edits_project()},
                                              {"terrain.paint", capability_sets::edits_project()},
                                              {"terrain.holes", capability_sets::edits_project()},
                                              {"terrain.generate", capability_sets::edits_project()},
                                              {"terrain.save", capability_sets::edits_project()},
                                              {"terrain.undo", capability_sets::edits_project()},
                                              {"terrain.redo", capability_sets::edits_project()}});
}

}  // namespace fa
