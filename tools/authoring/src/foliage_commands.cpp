// The foliage commands (M75-P6b / P6c-a, docs/BIG_WORLDS_TERRAIN.md "Foliage"): foliage.scatter, foliage.paint, foliage.clear and
// their undo and redo, foliage.undo and foliage.redo (an in-memory history of diffs of the instances file, see "the undo
// history" below). They write the instances file of a Foliage (fa/scene/foliage.h) and set the fields of the component that
// name it.
//
// Determinism: the same rule, seed and terrain give the same file byte for byte. The candidates are the points of a jittered grid
// anchored at the world origin (one candidate per cell of 1 / sqrt(density) metres, visited row by row), each one drawn from an
// integer hash (splitmix64) of the seed and its cell, so nothing depends on where the area starts, on the order of calls or on a
// clock. The numbers are IEEE double operations (+ - * / sqrt, floor, round) and are quantised before they are stored, so a
// last-digit difference of the terrain's float math between x86 and ARM does not reach the file. The one exception is std::tan
// (tan2_of_degrees, the bounds of slopeRange): its last digit may differ between C libraries, so a candidate whose slope lies
// within a few ULP of a bound could be kept on one platform and rejected on another; the bounds are compared once per candidate and
// never stored.
#include <algorithm>
#include <cmath>
#include <cstring>
#include <format>
#include <limits>
#include <map>
#include <memory>
#include <numeric>
#include <optional>

#include "authoring_internal.h"
#include "fa/core/capability.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/scene/foliage.h"
#include "fa/scene/terrain.h"

namespace fa {

namespace {

constexpr std::uint64_t kMaxCandidates = std::uint64_t(1)
                                         << 24;  // grid cells one command visits (8 x the instance cap)
constexpr double kPi = 3.14159265358979323846;

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

[[noreturn]] void bad(const std::string& pointer, const std::string& what, const std::string& hint) {
    throw CommandError("invalid_argument", what + " (at " + pointer + ")", hint);
}

double quantise(double v, double steps) { return std::floor(v * steps + 0.5) / steps; }

std::uint64_t mix64(std::uint64_t x) {  // splitmix64 finaliser
    x += 0x9E3779B97F4A7C15ull;
    x = (x ^ (x >> 30)) * 0xBF58476D1CE4E5B9ull;
    x = (x ^ (x >> 27)) * 0x94D049BB133111EBull;
    return x ^ (x >> 31);
}
double unit(std::uint64_t h) { return double(h >> 11) * (1.0 / 9007199254740992.0); }  // [0, 1)

std::string lower_ascii(std::string s) {
    for (char& c : s)
        if (c >= 'A' && c <= 'Z') c = char(c - 'A' + 'a');
    return s;
}

std::string stem_of(const std::string& id) {
    std::string out;
    for (char ch : id) {
        const bool ok =
            (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9') || ch == '_' || ch == '-';
        out.push_back(ok ? ch : '_');
    }
    return out.empty() ? std::string("foliage") : out;
}

// The spelling of a project path a command is about to write, judged by the project write rules.
std::string write_target(const std::string& where, const std::string& path) {
    auto r = fs::resolve_for_write(path, fs::WriteRoot::Project, caller_capabilities().has(Capability::WriteAnywhere));
    if (!r.ok()) {
        const std::string code(fs::path_error_code(r.error()));
        throw CommandError(code.empty() ? "invalid_argument" : code,
                           "'" + path + "' (" + where + ") cannot be written: " + r.error().message,
                           "Use a path inside the project, such as scenes/main.grass.foliage. " + r.error().hint);
    }
    return fs::project_spelling(r.value());
}

// ------------------------------------------------------------------------------------------------ the entities

struct Field {
    Entity entity = kNullEntity;
    std::string id;
    Foliage* foliage = nullptr;
    std::vector<std::string> meshes;  // Foliage.meshes as strings
};

std::vector<std::string> mesh_names(const Json& meshes) {
    std::vector<std::string> out;
    if (meshes.is_array())
        for (const Json& m : meshes) out.push_back(m.is_string() ? m.get<std::string>() : std::string());
    return out;
}

Field open_field(Engine::Impl& I, const Json& a) {
    Field f;
    f.entity = need_entity(I.world, a, "entity");
    f.id = I.world.id_of(f.entity);
    f.foliage = I.world.get<Foliage>(f.entity);
    if (!f.foliage)
        throw CommandError("invalid_argument", "Entity '" + f.id + "' has no Foliage component (at /entity).",
                           "Add it: scene.set_component {\"id\":\"" + f.id +
                               "\",\"component\":\"Foliage\"}. Then foliage.scatter fills it.");
    f.meshes = mesh_names(f.foliage->meshes);
    return f;
}

// The entity with the ScatterRule: `rule` or the Foliage entity itself. Null when `required` is false and there is none.
Entity find_rule_entity(Engine::Impl& I, const Json& a, const Field& f, bool required, const char* command) {
    Entity e = f.entity;
    if (a.contains("rule")) {
        e = need_entity(I.world, a, "rule");
        if (!I.world.get<ScatterRule>(e))
            throw CommandError("invalid_argument",
                               "Entity '" + I.world.id_of(e) + "' has no ScatterRule component (at /rule).",
                               "Add it: scene.set_component {\"id\":\"" + I.world.id_of(e) +
                                   "\",\"component\":\"ScatterRule\",\"value\":{\"meshes\":[{\"mesh\":\"assets/models/"
                                   "pine.glb\",\"weight\":1}],\"density\":0.2}}.");
        return e;
    }
    if (I.world.get<ScatterRule>(e)) return e;
    if (!required) return kNullEntity;
    throw CommandError(
        "invalid_argument",
        std::string(command) + ": entity '" + f.id + "' has no ScatterRule component, and no `rule` was given.",
        "Add the component to the Foliage entity: scene.set_component {\"id\":\"" + f.id +
            "\",\"component\":\"ScatterRule\",\"value\":{\"meshes\":[{\"mesh\":\"assets/models/pine.glb\","
            "\"weight\":1}],\"density\":0.2}}, or pass `rule` (the id of an entity that has one).");
}

void check_rule(Engine::Impl& I, Entity re, const ScatterRule& r) {
    for (const WorldProblem& p : scatter_rule_problems(r))
        if (p.error)
            throw CommandError("invalid_argument",
                               "ScatterRule of '" + I.world.id_of(re) + "' (at " + p.pointer + "): " + p.message,
                               p.hint);
    if (!(r.density > 0.0f) || !std::isfinite(r.density))
        bad("/density", "ScatterRule.density is " + std::to_string(r.density) + ", but it must be above 0",
            "Write instances per square metre, for example 0.2.");
    if (!(r.minSpacing >= 0.0f) || !std::isfinite(r.minSpacing))
        bad("/minSpacing", "ScatterRule.minSpacing must be 0 or more",
            "Write metres, for example 1.5 (0 = no spacing).");
}

Entity find_terrain(Engine::Impl& I, Entity ruleEntity, const ScatterRule* r, const Field& f) {
    Entity t = r ? r->terrain : kNullEntity;
    if (t) {
        if (!I.world.alive(t) || !I.world.get<Terrain3D>(t))
            throw CommandError("invalid_argument",
                               "ScatterRule.terrain of '" + I.world.id_of(ruleEntity) +
                                   "' is not an entity with a Terrain component.",
                               "Set ScatterRule.terrain to the id of the entity with the Terrain, or clear it to use "
                               "the rule entity or its parent.");
        return t;
    }
    for (Entity e : {ruleEntity ? ruleEntity : f.entity, f.entity}) {
        if (I.world.get<Terrain3D>(e)) return e;
        Entity p = I.world.parent(e);
        if (p && I.world.get<Terrain3D>(p)) return p;
    }
    throw CommandError(
        "invalid_argument",
        "No Terrain to place instances on for '" + f.id +
            "': ScatterRule.terrain is empty and neither the entity nor its parent has a Terrain.",
        "Set ScatterRule.terrain to the Terrain entity (scene.set_component), or make the Foliage a child "
        "of the terrain. Make a terrain with terrain.create.");
}

// ------------------------------------------------------------------------------------------------ the generator

struct Counts {
    std::uint64_t candidates = 0, placed = 0, outside = 0, hole = 0, height = 0, slope = 0, layer = 0, spacing = 0;
};

struct Gen {
    const TerrainSampler* ground = nullptr;
    double density = 1, spacing = 0;
    double slopeMin = 0, slopeMax = 90, heightMin = -1e9, heightMax = 1e9, scaleMin = 1, scaleMax = 1, align = 0;
    std::int32_t layerMask = -1;
    std::uint64_t seed = 1;
    std::vector<double> cum;                // cumulative weight of each slot
    std::vector<std::uint16_t> slotMesh;    // slot -> index into Foliage.meshes
    Mat4 toLocal;                           // world -> the Foliage entity's local space
    double x0 = 0, z0 = 0, x1 = 0, z1 = 0;  // the world rectangle to fill
    bool circle = false;                    // only inside (cx, cz, r)
    double cx = 0, cz = 0, r = 0;
};

// The accepted points (world x, z) in one flat grid of square cells: `head[cell]` is the newest point of a cell and `next[point]` the
// one before it (-1 = none), so no cell owns an allocation. The cell is at least the spacing, so the points that can block a
// candidate lie in its own cell and the eight around it. A grid of more than kMaxCells cells (a tiny spacing over a big area)
// gets larger cells: still correct, the cells just hold more points.
struct Spacing {
    static constexpr double kMaxCells = 4.0e6;
    double cell = 1, ox = 0, oz = 0;
    std::int64_t nx = 1, nz = 1;
    std::vector<std::int32_t> head, next;
    std::vector<std::pair<double, double>> pts;
    void init(double spacing, double x0, double z0, double x1, double z1) {
        cell = std::max(spacing, 1e-9);
        const double w = std::max(0.0, x1 - x0), h = std::max(0.0, z1 - z0);
        while ((w / cell + 3.0) * (h / cell + 3.0) > kMaxCells) cell *= 2.0;
        ox = x0 - cell, oz = z0 - cell;
        nx = std::int64_t(w / cell) + 3, nz = std::int64_t(h / cell) + 3;
        head.assign(std::size_t(nx) * std::size_t(nz), -1);
    }
    bool inside(std::int64_t i, std::int64_t j) const { return i >= 0 && j >= 0 && i < nx && j < nz; }
    void add(double x, double z) {  // a point outside the grid cannot block any candidate of the area: not kept
        const std::int64_t i = std::int64_t(std::floor((x - ox) / cell)), j = std::int64_t(std::floor((z - oz) / cell));
        if (!inside(i, j)) return;
        pts.emplace_back(x, z);
        std::int32_t& hd = head[std::size_t(j) * std::size_t(nx) + std::size_t(i)];
        next.push_back(hd);
        hd = std::int32_t(pts.size() - 1);
    }
    bool blocked(double x, double z, double dist) const {
        const std::int64_t ci = std::int64_t(std::floor((x - ox) / cell)),
                           cj = std::int64_t(std::floor((z - oz) / cell));
        for (std::int64_t j = cj - 1; j <= cj + 1; ++j)
            for (std::int64_t i = ci - 1; i <= ci + 1; ++i) {
                if (!inside(i, j)) continue;
                for (std::int32_t k = head[std::size_t(j) * std::size_t(nx) + std::size_t(i)]; k >= 0;
                     k = next[std::size_t(k)]) {
                    const double dx = pts[std::size_t(k)].first - x, dz = pts[std::size_t(k)].second - z;
                    if (dx * dx + dz * dz < dist * dist) return true;
                }
            }
        return false;
    }
};

// tan(deg)^2 for comparing a slope with the normal's components (no atan2): infinite from 90 degrees up.
double tan2_of_degrees(double deg) {
    if (deg >= 90.0) return std::numeric_limits<double>::infinity();
    if (deg <= 0.0) return 0.0;
    const double t = std::tan(deg * (kPi / 180.0));
    return t * t;
}

// Fills `out` (appending) and `counts`. `existing`: the world (x, z) of instances the new ones keep their spacing from.
// `already`: how many instances the file holds besides `out` (for the cap).
void run_generator(const Gen& g, const std::vector<std::pair<double, double>>& existing, std::size_t already,
                   std::vector<FoliageInstance>& out, Counts& c) {
    const double s = 1.0 / std::sqrt(g.density);
    const std::int64_t ix0 = std::int64_t(std::floor(g.x0 / s)), ix1 = std::int64_t(std::floor(g.x1 / s));
    const std::int64_t iz0 = std::int64_t(std::floor(g.z0 / s)), iz1 = std::int64_t(std::floor(g.z1 / s));
    const double cells = double(ix1 - ix0 + 1) * double(iz1 - iz0 + 1);
    if (!(cells <= double(kMaxCandidates)))
        throw CommandError(
            "too_many_candidates",
            std::format("The area at density {} has about {:.0f} grid cells, but one command visits at most {}.",
                        g.density, cells, kMaxCandidates),
            "Lower `density`, or fill a smaller area (foliage.paint takes a radius; a terrain can be split in several "
            "Foliage entities).");
    Spacing sp;
    const bool useSpacing = g.spacing > 0.0;
    if (useSpacing) {
        sp.init(g.spacing, g.x0, g.z0, g.x1, g.z1);
        for (const auto& p : existing) sp.add(p.first, p.second);
    }
    const double minTan2 = tan2_of_degrees(g.slopeMin), maxTan2 = tan2_of_degrees(g.slopeMax);
    const double total = g.cum.empty() ? 0.0 : g.cum.back();
    for (std::int64_t iz = iz0; iz <= iz1; ++iz)
        for (std::int64_t ix = ix0; ix <= ix1; ++ix) {
            std::uint64_t h = mix64(g.seed ^ 0xA24BAED4963EE407ull);
            h = mix64(h ^ std::uint64_t(ix));
            h = mix64(h ^ (std::uint64_t(iz) * 0x9FB21C651E98DF25ull));
            const double wx = quantise((double(ix) + unit(mix64(h + 1))) * s, 4096.0);
            const double wz = quantise((double(iz) + unit(mix64(h + 2))) * s, 4096.0);
            if (g.circle) {
                const double dx = wx - g.cx, dz = wz - g.cz;
                if (dx * dx + dz * dz > g.r * g.r) continue;
            }
            ++c.candidates;
            TerrainSample ts;
            if (!g.ground->sample(float(wx), float(wz), ts)) {
                TerrainSample ignore;
                if (g.ground->sample(float(wx), float(wz), ignore, true))
                    ++c.hole;
                else
                    ++c.outside;
                continue;
            }
            const double wy = quantise(double(ts.height), 1024.0);
            if (wy < g.heightMin || wy > g.heightMax) {
                ++c.height;
                continue;
            }
            // The slope against the range as tan^2 on the normal's components: slope < min  <=>  flat^2 < tan2(min) * ny^2.
            // A normal that points down (a mirrored terrain) is steeper than 90 degrees.
            const double nx = double(ts.normal.x), ny = double(ts.normal.y), nz = double(ts.normal.z);
            const double flat2 = nx * nx + nz * nz, ny2 = ny * ny;
            const bool tooFlat = ny > 0.0 ? flat2 < minTan2 * ny2 : g.slopeMin > 90.0;
            const bool tooSteep =
                ny > 0.0 ? flat2 > maxTan2 * ny2 : (ny < 0.0 ? g.slopeMax < 180.0 : g.slopeMax < 90.0);
            if (tooFlat || tooSteep) {
                ++c.slope;
                continue;
            }
            if (g.layerMask != -1) {
                TerrainLayerWeights lw;
                bool ok = false;
                if (g.ground->layer_weights(float(wx), float(wz), lw)) {
                    if (lw.count == 0)
                        ok = (g.layerMask & 1) != 0;
                    else
                        for (int i = 0; i < lw.count && !ok; ++i)
                            ok = ((g.layerMask >> i) & 1) != 0 && lw.weight[i] >= 0.5f;
                }
                if (!ok) {
                    ++c.layer;
                    continue;
                }
            }
            if (useSpacing && sp.blocked(wx, wz, g.spacing)) {
                ++c.spacing;
                continue;
            }
            if (already + out.size() >= kMaxFoliageInstances)
                throw CommandError(
                    "too_many_instances",
                    std::format("The result would hold more than {} instances, the most one instances file holds.",
                                kMaxFoliageInstances),
                    "Lower `density`, raise `minSpacing`, narrow the rule (slopeRange, heightRange, layerMask), or "
                    "fill "
                    "the terrain with several Foliage entities (each one has its own file and culls and fades on its "
                    "own).");
            if (useSpacing) sp.add(wx, wz);
            // the mesh, scale and yaw come from the same hash
            const double pick = unit(mix64(h + 3)) * total;
            std::size_t slot = 0;
            while (slot + 1 < g.cum.size() && !(pick < g.cum[slot])) ++slot;
            FoliageInstance in;
            in.mesh = g.slotMesh[slot];
            in.scale = float(quantise(g.scaleMin + (g.scaleMax - g.scaleMin) * unit(mix64(h + 4)), 4096.0));
            in.yaw = float(quantise(unit(mix64(h + 5)) * 2.0 * kPi, 65536.0));
            const Vec3 lp = g.toLocal.transform_point(Vec3{float(wx), float(wy), float(wz)});
            in.position = Vec3{float(quantise(double(lp.x), 4096.0)), float(quantise(double(lp.y), 1024.0)),
                               float(quantise(double(lp.z), 4096.0))};
            in.up = Vec3{0, 1, 0};
            if (g.align > 0.0) {
                const Vec3 n = g.toLocal.transform_dir(ts.normal);
                double ux = g.align * double(n.x), uy = (1.0 - g.align) + g.align * double(n.y),
                       uz = g.align * double(n.z);
                const double len = std::sqrt(ux * ux + uy * uy + uz * uz);
                if (len > 1e-9) in.up = Vec3{float(ux / len), float(uy / len), float(uz / len)};
            }
            out.push_back(in);
            ++c.placed;
        }
}

// ------------------------------------------------------------------------------------------------ files

Json counts_json(const Counts& c) {
    return Json::object({{"candidates", c.candidates},
                         {"placed", c.placed},
                         {"rejected", Json::object({{"outside", c.outside},
                                                    {"hole", c.hole},
                                                    {"height", c.height},
                                                    {"slope", c.slope},
                                                    {"layer", c.layer},
                                                    {"spacing", c.spacing}})}});
}

// The file a Foliage with no `instances` gets: next to the scene (scenes/main.scene.json -> scenes/main.<id>.foliage), or
// assets/foliage/<id>.foliage when no scene is loaded from a file; _2, _3... until no file and no other Foliage has that name.
std::string default_file(Engine::Impl& I, const std::string& id) {
    std::string dir = "assets/foliage", base = stem_of(id);
    if (!I.currentScene.empty()) {
        const std::string& sc = I.currentScene;
        const std::size_t slash = sc.find_last_of('/');
        dir = slash == std::string::npos ? std::string() : sc.substr(0, slash);
        std::string name = slash == std::string::npos ? sc : sc.substr(slash + 1);
        const std::size_t dot = name.find('.');
        if (dot != std::string::npos && dot > 0) name = name.substr(0, dot);
        base = name + "." + base;
    }
    for (int n = 1; n < 100000; ++n) {
        const std::string name = n == 1 ? base : base + "_" + std::to_string(n);
        const std::string path = (dir.empty() ? std::string() : dir + "/") + name + ".foliage";
        bool taken = fs::exists(path);
        const std::string want = lower_ascii(path);
        I.world.each<Foliage>([&](Entity, Foliage& f) {
            if (lower_ascii(f.instances) == want) taken = true;
        });
        if (!taken) return write_target("Foliage.instances", path);
    }
    throw CommandError("invalid_argument", "No free file name was found for the instances of '" + id + "'.",
                       "Set Foliage.instances to a path of your own.");
}

// ------------------------------------------------------------------------------------------------ the undo history
//
// Every foliage edit is one step of an in-memory history kept for each Foliage entity (the way TerrainHeights keeps its steps).
// A step is a diff of the instances file: the records it removed (their index in the file before, and their 26 bytes) and the
// records it appended; the file after an edit is "the records kept, in order, then the appended ones", so undo drops the appended
// tail and puts the removed records back at their indices, and redo does the opposite. The records are the file's own bytes, so
// an undo gives the previous file byte for byte. A step costs what it changed (a paint stamp a few hundred bytes; a scatter over
// a full file about the size of both files), never the whole file.
//
// The history is bounded: kFoliageHistorySteps steps and kFoliageHistoryBytes bytes per entity (the newest step stays even when it
// alone is over budget); the oldest steps go first and the result of the command that made them go says how many (`historyDropped`).
// All the histories together keep at most kFoliageHistoryTotalBytes: over it, the whole history of the Foliage edited longest ago is
// cleared and the result names it (`historiesEvicted`). The history of an entity that no longer exists is dropped at the next
// foliage command.
//
// What survives: the history lives in this process, with the engine. A scene save changes nothing in it (the file and the fields
// are what they were), and neither does a scene reload that gives the same entity the same file and fields. An edit of the file or
// of Foliage.meshes / Foliage.instances by anything but the foliage commands, or a reload that changes them, makes the state differ
// from the one the history recorded, and the history of that Foliage is cleared (a stale history is never applied to bytes it was
// not made for); a restart starts with none.

constexpr std::size_t kHistorySteps = kFoliageHistorySteps;
constexpr std::size_t kHistoryBytes = kFoliageHistoryBytes;

struct Step {
    std::string label;       // the command that made it: "foliage.scatter", "foliage.paint" or "foliage.clear"
    std::string file;        // the instances file the step wrote
    std::string instBefore;  // Foliage.instances before ("" = none)
    Json meshesBefore, meshesAfter;
    bool existedBefore = false;             // the file existed before (undo deletes it otherwise)
    std::uint32_t beforeCount = 0;          // records of the file before
    std::vector<std::uint32_t> removed;     // indices into the file before, ascending
    std::vector<std::uint8_t> removedRecs;  // 26 bytes of each removed record, in the same order
    std::vector<std::uint8_t> addedRecs;    // the records appended after the kept ones
    std::size_t bytes() const { return 512 + 4 * removed.size() + removedRecs.size() + addedRecs.size(); }
};

struct History {
    std::vector<Step> undo, redo;  // oldest first
    std::uint64_t state = 0;       // the hash of the file and fields the newest edit left (see state_hash)
    std::uint64_t touched =
        0;  // Histories::clock at the last foliage command on this Foliage (the least recent goes first)
    std::uint64_t id =
        0;  // which history this is (Histories::serial): a new one after the entity was pruned and came back
    std::uint64_t lost =
        0;  // the steps this history let go of (trimmed off the oldest end) since it was made, never reset
    std::size_t bytes() const {
        std::size_t n = 0;
        for (const Step& s : undo) n += s.bytes();
        for (const Step& s : redo) n += s.bytes();
        return n;
    }
    void clear() {
        undo.clear();
        redo.clear();
    }
};

struct Histories {
    std::map<std::string, History> byEntity;  // by entity id
    std::uint64_t clock = 0;                  // counts the foliage commands: History::touched
    std::uint64_t serial = 0;                 // counts the histories made: History::id
};

// The history of a Foliage entity (made empty when it has none yet).
History& history_for(Histories& H, const std::string& id) {
    History& h = H.byEntity[id];
    if (h.id == 0) h.id = ++H.serial;
    return h;
}

// Drops the history of every entity that is gone (destroyed, or the scene it belonged to was replaced), so a long session of
// scenes and entities does not keep their undo steps (up to 128 MB each) for ever. Runs at the start of every foliage command.
void prune_histories(const Engine::Impl& I, Histories& H) {
    for (auto it = H.byEntity.begin(); it != H.byEntity.end();) {
        if (I.world.find_by_id(it->first).is_null())
            it = H.byEntity.erase(it);
        else
            ++it;
    }
}

// Keeps all the histories together within kFoliageHistoryTotalBytes: clears the whole history of the Foliage edited longest ago
// (never `keep`, the one being edited) until they fit. Returns the ids it cleared.
std::vector<std::string> enforce_total_budget(Histories& H, const std::string& keep) {
    std::vector<std::string> cleared;
    for (;;) {
        std::size_t total = 0;
        for (const auto& [id, h] : H.byEntity) total += h.bytes();
        if (total <= kFoliageHistoryTotalBytes) break;
        History* oldest = nullptr;
        const std::string* oldestId = nullptr;
        for (auto& [id, h] : H.byEntity) {
            if (id == keep || (h.undo.empty() && h.redo.empty())) continue;
            if (!oldest || h.touched < oldest->touched) {
                oldest = &h;
                oldestId = &id;
            }
        }
        if (!oldest) break;
        cleared.push_back(*oldestId);
        oldest->clear();
    }
    return cleared;
}

// A hash of the state a history is about: the field Foliage.instances, Foliage.meshes and the bytes of that file (none when it does not
// exist). Eight bytes at a time through splitmix64: fast on a 50 MB file; it only has to tell "the same" from "changed".
std::uint64_t state_hash(const std::string& instances, const Json& meshes, bool existed, const std::uint8_t* data,
                         std::size_t size) {
    std::uint64_t h = mix64(0x464F4C49ull);
    auto word = [&](std::uint64_t w) { h = mix64(h ^ w); };
    for (char ch : instances) word(std::uint8_t(ch));
    word(0xFF);
    const std::string m = meshes.dump();
    for (char ch : m) word(std::uint8_t(ch));
    word(existed ? 1 : 2);
    word(size);
    std::size_t i = 0;
    for (; i + 8 <= size; i += 8) {
        std::uint64_t w;
        std::memcpy(&w, data + i, 8);
        word(w);
    }
    std::uint64_t tail = 0;
    for (std::size_t k = 0; i + k < size; ++k) tail |= std::uint64_t(data[i + k]) << (8 * k);
    word(tail);
    return h;
}

// What the Foliage is now: the field, the meshes, and the bytes of its file.
struct Snapshot {
    std::string instances;
    Json meshes;
    bool existed = false;
    std::vector<std::uint8_t> bytes;
    std::uint64_t hash = 0;
};

Snapshot take_snapshot(const Field& f) {
    Snapshot s;
    s.instances = f.foliage->instances;
    s.meshes = f.foliage->meshes;
    if (!s.instances.empty() && fs::exists(s.instances)) {
        auto b = fs::read_bytes(s.instances);
        if (!b.ok())
            throw CommandError("failed", s.instances + ": " + b.error().message,
                               b.error().hint.empty() ? "Check that the file can be read." : b.error().hint);
        s.existed = true;
        s.bytes = std::move(*b);
    }
    s.hash = state_hash(s.instances, s.meshes, s.existed, s.bytes.data(), s.bytes.size());
    return s;
}

std::uint32_t get32(const std::uint8_t* p) {
    return std::uint32_t(p[0]) | (std::uint32_t(p[1]) << 8) | (std::uint32_t(p[2]) << 16) | (std::uint32_t(p[3]) << 24);
}
void put32(std::uint8_t* p, std::uint32_t v) {
    for (int i = 0; i < 4; ++i) p[i] = std::uint8_t(v >> (8 * i));
}

// How many records an instances file holds, judged by its header and size only (not the numbers inside); nothing when it is not
// a file of this engine's format.
std::optional<std::size_t> record_count(const std::vector<std::uint8_t>& b) {
    if (b.size() < kFoliageHeaderBytes || std::memcmp(b.data(), "FAFO", 4) != 0) return std::nullopt;
    if ((b[4] | (b[5] << 8)) != int(kFoliageVersion) || (b[6] | (b[7] << 8)) != 0) return std::nullopt;
    const std::size_t n = get32(b.data() + 8);
    if (n > kMaxFoliageInstances || b.size() != foliage_file_bytes(n)) return std::nullopt;
    return n;
}

const std::uint8_t* record_at(const std::vector<std::uint8_t>& b, std::size_t i) {
    return b.data() + kFoliageHeaderBytes + i * kFoliageRecordBytes;
}

// The header of a file of `count` records written for `meshes` meshes.
std::vector<std::uint8_t> header_for(std::size_t count, const Json& meshes) {
    auto h = encode_foliage({}, std::uint32_t(meshes.is_array() ? meshes.size() : 0));
    if (!h.ok()) throw CommandError("invalid_argument", h.error().message, h.error().hint);
    put32(h->data() + 8, std::uint32_t(count));
    return std::move(*h);
}

// The file after `s` from the file before it (`cur` holds s.beforeCount records, or is empty when there was none).
std::vector<std::uint8_t> apply_forward(const std::vector<std::uint8_t>& cur, const Step& s) {
    const std::size_t added = s.addedRecs.size() / kFoliageRecordBytes;
    const std::size_t kept = s.beforeCount - s.removed.size();
    std::vector<std::uint8_t> out = header_for(kept + added, s.meshesAfter);
    out.reserve(foliage_file_bytes(kept + added));
    std::size_t ri = 0;
    for (std::size_t o = 0; o < s.beforeCount; ++o) {
        if (ri < s.removed.size() && s.removed[ri] == o) {
            ++ri;
            continue;
        }
        const std::uint8_t* r = record_at(cur, o);
        out.insert(out.end(), r, r + kFoliageRecordBytes);
    }
    out.insert(out.end(), s.addedRecs.begin(), s.addedRecs.end());
    return out;
}

// The file before `s` from the file after it (`cur` holds the kept records, then the added ones).
std::vector<std::uint8_t> apply_backward(const std::vector<std::uint8_t>& cur, const Step& s) {
    const std::size_t kept = s.beforeCount - s.removed.size();
    std::vector<std::uint8_t> out = header_for(s.beforeCount, s.meshesBefore);
    out.reserve(foliage_file_bytes(s.beforeCount));
    std::size_t ri = 0, ki = 0;
    for (std::size_t o = 0; o < s.beforeCount; ++o) {
        const std::uint8_t* r;
        if (ri < s.removed.size() && s.removed[ri] == o)
            r = s.removedRecs.data() + (ri++) * kFoliageRecordBytes;
        else
            r = record_at(cur, ki++);
        out.insert(out.end(), r, r + kFoliageRecordBytes);
    }
    (void)kept;
    return out;
}

// Adds `b` (an edit made right after `a`, against the file `a` left) to `a`: one step with a's file before and b's file after.
void merge_into(Step& a, Step&& b) {
    const std::size_t K = a.beforeCount - a.removed.size();  // records of a's file that come from the file before it
    std::vector<std::uint32_t> origIdx;                      // b's removals of those, as indices of the file before a
    std::vector<std::uint8_t> origRecs;
    std::vector<std::size_t> addedGone;  // b's removals of records a appended (indices into a.addedRecs)
    std::size_t rp = 0, o = 0, seen = 0;
    for (std::size_t i = 0; i < b.removed.size(); ++i) {
        const std::size_t idx = b.removed[i];
        const std::uint8_t* rec = b.removedRecs.data() + i * kFoliageRecordBytes;
        if (idx < K) {
            for (;;) {  // the idx-th record of the file before a that a did not remove
                while (rp < a.removed.size() && a.removed[rp] == o) {
                    ++rp;
                    ++o;
                }
                if (seen == idx) break;
                ++seen;
                ++o;
            }
            origIdx.push_back(std::uint32_t(o));
            origRecs.insert(origRecs.end(), rec, rec + kFoliageRecordBytes);
            ++seen;
            ++o;
        } else {
            addedGone.push_back(idx - K);
        }
    }
    if (!origIdx.empty()) {  // merge the two ascending lists of removed indices
        std::vector<std::uint32_t> idxs;
        std::vector<std::uint8_t> recs;
        std::size_t x = 0, y = 0;
        while (x < a.removed.size() || y < origIdx.size()) {
            const bool takeA = y >= origIdx.size() || (x < a.removed.size() && a.removed[x] < origIdx[y]);
            if (takeA) {
                idxs.push_back(a.removed[x]);
                const std::uint8_t* r = a.removedRecs.data() + x * kFoliageRecordBytes;
                recs.insert(recs.end(), r, r + kFoliageRecordBytes);
                ++x;
            } else {
                idxs.push_back(origIdx[y]);
                const std::uint8_t* r = origRecs.data() + y * kFoliageRecordBytes;
                recs.insert(recs.end(), r, r + kFoliageRecordBytes);
                ++y;
            }
        }
        a.removed = std::move(idxs);
        a.removedRecs = std::move(recs);
    }
    if (!addedGone.empty()) {
        std::vector<std::uint8_t> kept;
        std::size_t g = 0;
        for (std::size_t i = 0; i < a.addedRecs.size() / kFoliageRecordBytes; ++i) {
            if (g < addedGone.size() && addedGone[g] == i) {
                ++g;
                continue;
            }
            const std::uint8_t* r = a.addedRecs.data() + i * kFoliageRecordBytes;
            kept.insert(kept.end(), r, r + kFoliageRecordBytes);
        }
        a.addedRecs = std::move(kept);
    }
    a.addedRecs.insert(a.addedRecs.end(), b.addedRecs.begin(), b.addedRecs.end());
    a.meshesAfter = std::move(b.meshesAfter);
    a.file = std::move(b.file);
}

// One command's view of its Foliage: what the field and its file hold now, and its history, cleared first when it does not
// describe that state any more.
struct Session {
    History* h = nullptr;
    Histories* all = nullptr;  // every history of the engine (the total budget)
    Snapshot before;
    std::string resetNote;  // why the history was cleared ("" = it was not)
    bool cont = false;      // the call continues the newest step (`continueStroke`)
};

Session begin_session(Histories& H, const Field& f, const Json& a, const char* label) {
    Session s;
    s.before = take_snapshot(f);
    s.h = &history_for(H, f.id);
    s.all = &H;
    s.h->touched = ++H.clock;
    if ((!s.h->undo.empty() || !s.h->redo.empty()) && s.h->state != s.before.hash) {
        s.h->clear();
        s.resetNote =
            "Foliage.instances, Foliage.meshes or the instances file changed outside the foliage commands (a scene "
            "reload, an edit by hand, a restore from version control), so the undo history of '" +
            f.id + "' was cleared.";
    }
    s.cont =
        label && a.contains("continueStroke") && a["continueStroke"].is_boolean() && a["continueStroke"].get<bool>();
    if (s.cont) {
        const char* why = s.h->undo.empty() ? "this Foliage has no edit to continue"
                          : !s.h->redo.empty()
                              ? "an edit was undone since, so the newest edit is not the one to continue"
                          : s.h->undo.back().label != label ? "the newest edit of this Foliage is another command"
                                                            : nullptr;
        if (why)
            bad("/continueStroke",
                std::string("Cannot continue the stroke: ") + why +
                    (s.resetNote.empty() ? std::string() : " (" + s.resetNote + ")"),
                "Send the first piece of a stroke without continueStroke, and the following pieces right after it "
                "with continueStroke true (no other foliage edit and no foliage.undo in between).");
    }
    return s;
}

Json undo_command(const std::string& id) {
    return Json::object({{"command", "foliage.undo"}, {"args", Json::object({{"entity", id}})}});
}

void add_history_fields(Json& res, const History& h) {
    res["undoDepth"] = h.undo.size();
    res["redoDepth"] = h.redo.size();
    // The editor numbers its undo rows with these: the step now on top of the undo list is number historyLost + undoDepth, and a
    // `historyId` that changed means the history is another one (the entity was destroyed and came back).
    res["historyId"] = h.id;
    res["historyLost"] = h.lost;
}

// Writes the file of an edit of `f`: the records of the file before except `removed` (ascending indices; every one when
// `removeAll`), then `added`; sets Foliage.meshes (when `meshes` is not null) and Foliage.instances, records the step and returns
// the result fields every editing command shares (file, instances, bytes, undo, undoDepth, redoDepth). Nothing changes when the
// encoding or the write fails.
Json commit(Session& ses, Field& f, const std::string& file, std::vector<std::uint32_t> removed, bool removeAll,
            const std::vector<FoliageInstance>& added, const Json& meshes, const char* label) {
    const Snapshot& before = ses.before;
    const Json newMeshes = meshes.is_null() ? f.foliage->meshes : meshes;
    const std::uint32_t meshCount = std::uint32_t(newMeshes.is_array() ? newMeshes.size() : 0);
    auto head = encode_foliage(added, meshCount);
    if (!head.ok()) throw CommandError("invalid_argument", head.error().message, head.error().hint);
    // The records of the file before. A file this engine cannot read as records (damaged by hand) is replaced whole, with no undo.
    const std::optional<std::size_t> n0 = before.existed ? record_count(before.bytes) : std::optional<std::size_t>(0);
    if (removeAll && n0) {
        removed.resize(*n0);
        std::iota(removed.begin(), removed.end(), std::uint32_t(0));
    }
    const std::size_t kept = n0 ? *n0 - removed.size() : 0;
    const std::size_t total = kept + added.size();
    if (total > kMaxFoliageInstances)
        throw CommandError("too_many_instances",
                           std::format("The result would hold {} instances, more than the {} one instances file holds.",
                                       total, kMaxFoliageInstances),
                           "Lower `density`, or fill the terrain with several Foliage entities.");
    std::vector<std::uint8_t> out(head->begin(), head->begin() + kFoliageHeaderBytes);
    out.reserve(foliage_file_bytes(total));
    put32(out.data() + 8, std::uint32_t(total));
    if (n0) {
        std::size_t ri = 0;
        for (std::size_t o = 0; o < *n0; ++o) {
            if (ri < removed.size() && removed[ri] == o) {
                ++ri;
                continue;
            }
            const std::uint8_t* r = record_at(before.bytes, o);
            out.insert(out.end(), r, r + kFoliageRecordBytes);
        }
    }
    out.insert(out.end(), head->begin() + kFoliageHeaderBytes, head->end());
    if (auto w = fs::write_bytes(file, out.data(), out.size()); !w.ok())
        throw CommandError("write_failed", file + ": " + w.error().message,
                           w.error().hint.empty()
                               ? "Check that the folder is writable and the file is not open elsewhere."
                               : w.error().hint);
    f.foliage->meshes = newMeshes;
    f.foliage->instances = file;
    History& h = *ses.h;
    Json res = Json::object({{"entity", f.id}, {"file", file}, {"instances", total}, {"bytes", out.size()}});
    std::size_t dropped = 0;
    if (n0) {
        Step st;
        st.label = label;
        st.file = file;
        st.instBefore = before.instances;
        st.meshesBefore = before.meshes;
        st.meshesAfter = newMeshes;
        st.existedBefore = before.existed;
        st.beforeCount = std::uint32_t(*n0);
        st.removed = std::move(removed);
        st.removedRecs.reserve(st.removed.size() * kFoliageRecordBytes);
        for (std::uint32_t idx : st.removed) {
            const std::uint8_t* r = record_at(before.bytes, idx);
            st.removedRecs.insert(st.removedRecs.end(), r, r + kFoliageRecordBytes);
        }
        st.addedRecs.assign(head->begin() + kFoliageHeaderBytes, head->end());
        if (ses.cont && !h.undo.empty()) {
            merge_into(h.undo.back(), std::move(st));
            res["continued"] = true;
        } else {
            h.redo.clear();
            h.undo.push_back(std::move(st));
        }
        while (!h.undo.empty() && (h.undo.size() > kHistorySteps || (h.bytes() > kHistoryBytes && h.undo.size() > 1))) {
            h.undo.erase(h.undo.begin());
            ++dropped;
        }
        h.lost += dropped;
    } else {
        h.clear();
        ses.resetNote =
            "The previous instances file was not a readable instances file, so this edit replaced it and has no undo.";
    }
    h.state = state_hash(file, newMeshes, true, out.data(), out.size());
    if (n0) res["undo"] = undo_command(f.id);
    add_history_fields(res, h);
    if (dropped) {
        res["historyDropped"] = dropped;
        res["historyNote"] = std::format(
            "The undo history of '{}' keeps its last {} edits (and {} MB): the {} oldest {} can no longer be undone.",
            f.id, kHistorySteps, kHistoryBytes >> 20, dropped, dropped == 1 ? "edit" : "edits");
    }
    if (!ses.resetNote.empty()) res["historyReset"] = ses.resetNote;
    if (const std::vector<std::string> evicted = enforce_total_budget(*ses.all, f.id); !evicted.empty()) {
        res["historiesEvicted"] = evicted;
        res["historiesEvictedNote"] = std::format(
            "All the foliage undo histories together keep {} MB: the history of {} other Foliage {} was cleared (their "
            "edits can no longer be undone).",
            kFoliageHistoryTotalBytes >> 20, evicted.size(), evicted.size() == 1 ? "entity" : "entities");
    }
    return res;
}

// The instances the file of `snap` holds (none when the field is empty or the file is missing).
std::vector<FoliageInstance> load_instances(const Field& f, const Snapshot& snap) {
    if (!snap.existed) return {};
    auto r = decode_foliage(snap.bytes.data(), snap.bytes.size(), f.meshes.size(), snap.instances);
    if (!r.ok())
        throw CommandError("invalid_argument", r.error().message,
                           (r.error().hint.empty() ? std::string() : r.error().hint + " ") +
                               "The file was not changed. Restore it, or run foliage.scatter to write a new one.");
    return std::move(*r);
}

// Points of the ground plane in a grid of square cells of `cell` metres, for the ones within a distance (at most `cell`) of a place.
class PointGrid {
public:
    explicit PointGrid(double cell) : cell_(std::max(cell, 1e-6)) {}
    void add(double x, double z) {
        pts_.emplace_back(x, z);
        cells_[key(x, z)].push_back(std::uint32_t(pts_.size() - 1));
    }
    // Calls `f(index)` for every point within `r` (<= the cell size) of (x, z).
    template <class F>
    void each_within(double x, double z, double r, F f) const {
        const auto [ci, cj] = key(x, z);
        for (std::int64_t j = cj - 1; j <= cj + 1; ++j)
            for (std::int64_t i = ci - 1; i <= ci + 1; ++i) {
                const auto it = cells_.find({i, j});
                if (it == cells_.end()) continue;
                for (std::uint32_t k : it->second) {
                    const double dx = pts_[k].first - x, dz = pts_[k].second - z;
                    if (dx * dx + dz * dz <= r * r) f(k);
                }
            }
    }
    bool any_within(double x, double z, double r) const {
        bool found = false;
        each_within(x, z, r, [&](std::uint32_t) { found = true; });
        return found;
    }
    const std::pair<double, double>& at(std::uint32_t k) const { return pts_[k]; }

private:
    std::pair<std::int64_t, std::int64_t> key(double x, double z) const {
        return {std::int64_t(std::floor(x / cell_)), std::int64_t(std::floor(z / cell_))};
    }
    double cell_;
    std::vector<std::pair<double, double>> pts_;
    std::map<std::pair<std::int64_t, std::int64_t>, std::vector<std::uint32_t>> cells_;
};

// The result of a call that changed nothing.
Json unchanged(const Session& ses, Json res) {
    add_history_fields(res, *ses.h);
    if (!ses.resetNote.empty()) res["historyReset"] = ses.resetNote;
    return res;
}

// ------------------------------------------------------------------------------------------------ the shared setup

struct Setup {
    Entity ruleEntity = kNullEntity;
    ScatterRule rule;
    Entity terrain = kNullEntity;
    std::optional<TerrainSampler> ground;
    Mat4 toWorld, toLocal;
};

void need_ground(Engine::Impl& I, Entity terrain, const std::string& id) {
    std::string problem;
    auto h = I.world.terrain().heights(I.world, terrain, &problem);
    if (!h)
        throw CommandError("invalid_argument",
                           "The Terrain '" + I.world.id_of(terrain) + "' for '" + id + "' has no usable heights" +
                               (problem.empty() ? std::string(".") : ": " + problem),
                           "Fix Terrain.heightmap (terrain.create / terrain.generate), then repeat the call.");
}

void terrain_footprint(Engine::Impl& I, Entity terrain, Gen& g) {
    const Terrain3D* t = I.world.get<Terrain3D>(terrain);
    const Mat4 m = I.world.world_matrix(terrain);
    double mnx = 1e300, mnz = 1e300, mxx = -1e300, mxz = -1e300;
    for (int i = 0; i < 4; ++i) {
        const Vec3 p =
            m.transform_point(Vec3{(i & 1 ? 0.5f : -0.5f) * t->size.x, 0.0f, (i & 2 ? 0.5f : -0.5f) * t->size.y});
        mnx = std::min(mnx, double(p.x));
        mxx = std::max(mxx, double(p.x));
        mnz = std::min(mnz, double(p.z));
        mxz = std::max(mxz, double(p.z));
    }
    g.x0 = mnx, g.x1 = mxx, g.z0 = mnz, g.z1 = mxz;
}

Gen make_gen(const Setup& s) {
    Gen g;
    g.ground = &*s.ground;
    g.density = double(s.rule.density);
    g.spacing = double(s.rule.minSpacing);
    g.slopeMin = double(s.rule.slopeRange.x), g.slopeMax = double(s.rule.slopeRange.y);
    g.heightMin = double(s.rule.heightRange.x), g.heightMax = double(s.rule.heightRange.y);
    g.scaleMin = double(s.rule.scaleRange.x), g.scaleMax = double(s.rule.scaleRange.y);
    g.align = std::clamp(double(s.rule.alignToNormal), 0.0, 1.0);
    g.layerMask = s.rule.layerMask;
    g.seed = std::uint64_t(std::uint32_t(s.rule.seed));
    g.toLocal = s.toLocal;
    return g;
}

double weight_of(const Json& entry) {
    return entry.contains("weight") && entry["weight"].is_number() ? entry["weight"].get<double>() : 1.0;
}

// The rule, the terrain and the ground of an edit that places instances. `validateRule`: refuse a rule whose own numbers are not
// usable (density 0...); a call that gives its own density skips it.
Setup open_setup(Engine::Impl& I, const Json& a, const Field& field, bool requireRule, bool validateRule,
                 const char* command) {
    Setup s;
    s.ruleEntity = find_rule_entity(I, a, field, requireRule, command);
    if (s.ruleEntity) {
        s.rule = *I.world.get<ScatterRule>(s.ruleEntity);
        if (validateRule) check_rule(I, s.ruleEntity, s.rule);
    }
    s.terrain = find_terrain(I, s.ruleEntity, s.ruleEntity ? &s.rule : nullptr, field);
    need_ground(I, s.terrain, field.id);
    s.ground.emplace(I.world, s.terrain);
    s.toWorld = I.world.world_matrix(field.entity);
    s.toLocal = s.toWorld.inverse();
    return s;
}

// ------------------------------------------------------------------------------------------------ foliage.scatter

// (foliage.scatter and foliage.clear have no continueStroke: their schemas refuse it as an unknown property, so only a
// foliage.paint call can join a stroke.)
Json do_scatter(Engine::Impl& I, Histories& H, const Json& a) {
    prune_histories(I, H);
    Field field = open_field(I, a);
    Setup s = open_setup(I, a, field, true, true, "foliage.scatter");
    const bool dry = a.contains("dryRun") && a["dryRun"].is_boolean() && a["dryRun"].get<bool>();
    if (s.rule.meshes.empty())
        throw CommandError(
            "invalid_argument",
            "ScatterRule of '" + I.world.id_of(s.ruleEntity) +
                "' has no meshes, so there is nothing to place (at /meshes).",
            "Add at least one {\"mesh\": path, \"weight\": 1} to ScatterRule.meshes (scene.set_component).");
    Gen g = make_gen(s);
    Json meshes = Json::array();
    double total = 0.0;
    for (std::size_t i = 0; i < s.rule.meshes.size(); ++i) {
        meshes.push_back(s.rule.meshes[i]["mesh"]);
        total += weight_of(s.rule.meshes[i]);
        g.cum.push_back(total);
        g.slotMesh.push_back(std::uint16_t(i));
    }
    terrain_footprint(I, s.terrain, g);
    std::vector<FoliageInstance> out;
    Counts c;
    run_generator(g, {}, 0, out, c);
    std::vector<std::uint64_t> perMesh(s.rule.meshes.size(), 0);
    for (const FoliageInstance& in : out) ++perMesh[in.mesh];
    Json by = Json::array();
    for (std::size_t i = 0; i < perMesh.size(); ++i)
        by.push_back(Json::object({{"mesh", meshes[i]}, {"count", perMesh[i]}}));
    std::string file = field.foliage->instances;
    if (file.empty())
        file = default_file(I, field.id);
    else
        file = write_target("Foliage.instances", file);
    Json res;
    if (dry) {
        res = Json::object({{"entity", field.id},
                            {"file", file},
                            {"instances", out.size()},
                            {"bytes", foliage_file_bytes(out.size())}});
    } else {
        Session ses = begin_session(H, field, a, nullptr);
        res = commit(ses, field, file, {}, true, out, meshes, "foliage.scatter");
    }
    const Json cj = counts_json(c);
    for (auto it = cj.begin(); it != cj.end(); ++it) res[it.key()] = *it;
    res["rule"] = I.world.id_of(s.ruleEntity);
    res["terrain"] = I.world.id_of(s.terrain);
    res["meshes"] = by;
    res["dryRun"] = dry;
    return res;
}

// ------------------------------------------------------------------------------------------------ foliage.paint

// The number `v` (at JSON pointer `pointer`) as a double inside lo .. hi.
double number_at(const Json& v, const std::string& pointer, const char* what, double lo, double hi) {
    if (!v.is_number())
        bad(pointer, std::string("Expected a number (") + what + ")", "Write a plain number such as 5.");
    const double d = v.get<double>();
    if (!std::isfinite(d) || d < lo || d > hi)
        bad(pointer, std::format("{} is outside {} .. {}", d, lo, hi), "Use a value inside that range.");
    return d;
}

double need_number(const Json& a, const char* key, const char* what, double lo, double hi) {
    if (!a.contains(key))
        bad(std::string("/") + key, std::string("Missing number '") + key + "' (" + what + ")",
            "Write a plain number such as 5.");
    return number_at(a[key], std::string("/") + key, what, lo, hi);
}

Json do_paint(Engine::Impl& I, Histories& H, const Json& a) {
    prune_histories(I, H);
    Field f = open_field(I, a);
    const std::string mode = a.contains("mode") && a["mode"].is_string() ? a["mode"].get<std::string>() : "add";
    if (mode != "add" && mode != "remove") bad("/mode", "mode is '" + mode + "'", "Use \"add\" or \"remove\".");
    // The places of the brush: `center` is one, `points` several (a stroke sent in one call, one rewrite of the file).
    std::vector<std::pair<double, double>> centers;
    if (a.contains("center") && a.contains("points"))
        bad("/points", "center and points are both given: they say the same thing",
            "Give center for one stamp, or points for several (a list of [x, z]), not both.");
    if (a.contains("points")) {
        if (!a["points"].is_array() || a["points"].empty() || a["points"].size() > kMaxFoliagePaintPoints)
            bad("/points",
                "points must be a list of 1 to " + std::to_string(kMaxFoliagePaintPoints) +
                    " [x, z] pairs in world metres",
                "Example: [[10, 20], [12, 20]]. Send a longer stroke in several calls with continueStroke.");
        for (std::size_t i = 0; i < a["points"].size(); ++i) {
            const Json& p = a["points"][i];
            const std::string at = "/points/" + std::to_string(i);
            if (!p.is_array() || p.size() != 2) bad(at, "A point must be [x, z] in world metres", "Example: [10, 20].");
            centers.emplace_back(number_at(p[0], at + "/0", "point x in metres", -1e7, 1e7),
                                 number_at(p[1], at + "/1", "point z in metres", -1e7, 1e7));
        }
    } else {
        if (!a.contains("center") || !a["center"].is_array() || a["center"].size() != 2)
            bad("/center", "center must be [x, z] in world metres (or give `points`)", "Example: [10, 20].");
        centers.emplace_back(number_at(a["center"][0], "/center/0", "center x in metres", -1e7, 1e7),
                             number_at(a["center"][1], "/center/1", "center z in metres", -1e7, 1e7));
    }
    const double radius = need_number(a, "radius", "brush radius in metres", 1e-3, 1e5);
    int only = -1;  // the mesh index the brush is limited to
    if (a.contains("mesh")) {
        if (!a["mesh"].is_string()) bad("/mesh", "mesh must be a string", "Use a path of Foliage.meshes.");
        const std::string m = a["mesh"].get<std::string>();
        for (std::size_t i = 0; i < f.meshes.size(); ++i)
            if (f.meshes[i] == m) only = int(i);
        if (only < 0)
            throw CommandError("not_found",
                               "Foliage '" + f.id + "' has no mesh '" + m + "' in its meshes (at /mesh). " +
                                   did_you_mean(m, f.meshes),
                               "Use one of Foliage.meshes, or run foliage.scatter to set them from the rule.");
    }
    const bool hasDensity = a.contains("density");
    const double density = hasDensity ? need_number(a, "density", "instances per square metre", 1e-6, 1e6) : 0.0;
    std::optional<std::uint64_t> seed;
    if (a.contains("seed"))
        seed =
            std::uint64_t(std::uint32_t(std::int32_t(need_number(a, "seed", "the seed", -2147483648.0, 2147483647.0))));
    // The box of the whole stroke.
    double bx0 = 1e300, bz0 = 1e300, bx1 = -1e300, bz1 = -1e300;
    for (const auto& c : centers) {
        bx0 = std::min(bx0, c.first - radius), bx1 = std::max(bx1, c.first + radius);
        bz0 = std::min(bz0, c.second - radius), bz1 = std::max(bz1, c.second + radius);
    }
    Session ses = begin_session(H, f, a, "foliage.paint");
    std::vector<FoliageInstance> all = load_instances(f, ses.before);
    const Mat4 toWorld = I.world.world_matrix(f.entity);
    if (mode == "remove") {  // removing needs neither a terrain nor a rule
        PointGrid brush(radius);
        for (const auto& c : centers) brush.add(c.first, c.second);
        std::vector<std::uint32_t> removed;
        for (std::size_t i = 0; i < all.size(); ++i) {
            const Vec3 w = toWorld.transform_point(all[i].position);
            const double x = double(w.x), z = double(w.z);
            if (x < bx0 || x > bx1 || z < bz0 || z > bz1) continue;
            if ((only < 0 || all[i].mesh == only) && brush.any_within(x, z, radius))
                removed.push_back(std::uint32_t(i));
        }
        if (removed.empty())
            return unchanged(ses, Json::object({{"entity", f.id},
                                                {"added", 0},
                                                {"removed", 0},
                                                {"instances", all.size()},
                                                {"file", ses.before.instances},
                                                {"note", "No instance lies inside the brush: nothing changed."}}));
        const std::size_t n = removed.size();
        Json res = commit(ses, f, write_target("Foliage.instances", ses.before.instances), std::move(removed), false,
                          {}, Json(nullptr), "foliage.paint");
        res["added"] = 0;
        res["removed"] = n;
        return res;
    }
    // add: the same placement rules as foliage.scatter, with a spacing against the instances already there
    Setup s = open_setup(I, a, f, false, !hasDensity, "foliage.paint");
    Gen g = make_gen(s);
    if (hasDensity) g.density = density;
    // A repeated stroke must not stack instances on the same spot: never closer than half the average gap.
    g.spacing = std::max(g.spacing, 0.5 / std::sqrt(g.density));
    if (seed) g.seed = *seed;
    g.seed = mix64(g.seed ^ 0x5041494E54ull);  // a stroke has its own stream, apart from foliage.scatter
    // the mesh weights: the rule's entry of the same mesh, else 1
    double total = 0.0;
    for (std::size_t i = 0; i < f.meshes.size(); ++i) {
        if (only >= 0 && int(i) != only) continue;
        double w = 1.0;
        for (const Json& m : s.rule.meshes)
            if (m.is_object() && m.contains("mesh") && m["mesh"] == Json(f.meshes[i])) w = weight_of(m);
        total += w;
        g.cum.push_back(total);
        g.slotMesh.push_back(std::uint16_t(i));
    }
    if (g.cum.empty())
        throw CommandError("invalid_argument", "Foliage '" + f.id + "' has no meshes to paint with.",
                           "Set Foliage.meshes, or run foliage.scatter first.");
    // The work of the whole call is bounded like one scatter: the grid cells of every stamp together.
    {
        const double side = 2.0 * radius * std::sqrt(g.density) + 2.0;
        if (side * side * double(centers.size()) > double(kMaxCandidates))
            throw CommandError(
                "too_many_candidates",
                std::format(
                    "{} stamps of radius {} m at density {} visit about {:.0f} grid cells, but one command visits "
                    "at most {}.",
                    centers.size(), radius, g.density, side * side * double(centers.size()), kMaxCandidates),
                "Lower `density` or `radius`, or send fewer `points` per call.");
    }
    g.circle = true;
    g.r = radius;
    // The instances that can block a new one: those near the stroke, in a grid (the stamps are placed one after the other, each
    // one against everything placed before it, the earlier stamps of this call included).
    const double reach = radius + g.spacing;
    PointGrid pool(reach);
    for (const FoliageInstance& in : all) {
        const Vec3 w = toWorld.transform_point(in.position);
        const double x = double(w.x), z = double(w.z);
        if (x >= bx0 - g.spacing && x <= bx1 + g.spacing && z >= bz0 - g.spacing && z <= bz1 + g.spacing)
            pool.add(x, z);
    }
    std::vector<FoliageInstance> added;
    Counts c;
    for (const auto& ctr : centers) {
        g.cx = ctr.first, g.cz = ctr.second;
        g.x0 = g.cx - radius, g.x1 = g.cx + radius, g.z0 = g.cz - radius, g.z1 = g.cz + radius;
        std::vector<std::pair<double, double>> nearby;
        pool.each_within(g.cx, g.cz, reach, [&](std::uint32_t k) { nearby.push_back(pool.at(k)); });
        std::vector<FoliageInstance> piece;
        run_generator(g, nearby, all.size() + added.size(), piece, c);
        for (const FoliageInstance& in : piece) {
            const Vec3 w = toWorld.transform_point(in.position);
            pool.add(double(w.x), double(w.z));
            added.push_back(in);
        }
    }
    if (added.empty())
        return unchanged(
            ses, Json::object(
                     {{"entity", f.id},
                      {"added", 0},
                      {"removed", 0},
                      {"instances", all.size()},
                      {"file", ses.before.instances},
                      {"counts", counts_json(c)},
                      {"note", "No instance could be placed in the brush (see counts.rejected): nothing changed."}}));
    const std::string file =
        ses.before.instances.empty() ? default_file(I, f.id) : write_target("Foliage.instances", ses.before.instances);
    Json res = commit(ses, f, file, {}, false, added, Json(nullptr), "foliage.paint");
    res["added"] = added.size();
    res["removed"] = 0;
    res["counts"] = counts_json(c);
    return res;
}

// ------------------------------------------------------------------------------------------------ foliage.clear

Json do_clear(Engine::Impl& I, Histories& H, const Json& a) {
    prune_histories(I, H);
    Field f = open_field(I, a);
    double r[4] = {0, 0, 0, 0};
    const bool hasRegion = a.contains("region");
    if (hasRegion) {
        if (!a["region"].is_array() || a["region"].size() != 4)
            bad("/region", "region must be [minX, minZ, maxX, maxZ] in world metres", "Example: [0, 0, 50, 50].");
        for (int i = 0; i < 4; ++i) {
            const std::string p = "/region/" + std::to_string(i);
            if (!a["region"][std::size_t(i)].is_number()) bad(p, "Expected a number", "Write metres, such as 12.5.");
            r[i] = a["region"][std::size_t(i)].get<double>();
            if (!std::isfinite(r[i]) || std::abs(r[i]) > 1e9)
                bad(p, "The number is not a usable coordinate", "Use metres below 1e9.");
        }
        if (r[0] > r[2] || r[1] > r[3])
            bad("/region", "region has min above max", "Write [minX, minZ, maxX, maxZ] with each min below its max.");
    }
    Session ses = begin_session(H, f, a, nullptr);
    std::vector<FoliageInstance> all = load_instances(f, ses.before);
    const Mat4 toWorld = I.world.world_matrix(f.entity);
    std::vector<std::uint32_t> removed;
    for (std::size_t i = 0; i < all.size(); ++i) {
        bool inside = true;
        if (hasRegion) {
            const Vec3 w = toWorld.transform_point(all[i].position);
            inside = double(w.x) >= r[0] && double(w.x) <= r[2] && double(w.z) >= r[1] && double(w.z) <= r[3];
        }
        if (inside) removed.push_back(std::uint32_t(i));
    }
    if (removed.empty())
        return unchanged(ses, Json::object({{"entity", f.id},
                                            {"removed", 0},
                                            {"instances", all.size()},
                                            {"file", ses.before.instances},
                                            {"note", "There was nothing to remove: nothing changed."}}));
    const std::size_t n = removed.size();
    Json res = commit(ses, f, write_target("Foliage.instances", ses.before.instances), std::move(removed), false, {},
                      Json(nullptr), "foliage.clear");
    res["removed"] = n;
    return res;
}

// ------------------------------------------------------------------------------------------------ foliage.undo, foliage.redo

[[noreturn]] void stale_history(History& h, const std::string& id) {
    h.clear();
    throw CommandError(
        "stale_history",
        "The undo history of '" + id +
            "' does not describe its instances file any more: Foliage.instances, Foliage.meshes or the file "
            "changed outside the foliage commands (a scene reload, an edit by hand, a restore from version "
            "control). The history was cleared and nothing changed.",
        "Run foliage.scatter to write the file again, or restore the file from version control.");
}

Json do_undo_redo(Engine::Impl& I, Histories& H, const Json& a, bool undo) {
    prune_histories(I, H);
    Field f = open_field(I, a);
    History& h = history_for(H, f.id);
    h.touched = ++H.clock;
    std::vector<Step>& from = undo ? h.undo : h.redo;
    if (from.empty())
        throw CommandError(
            undo ? "nothing_to_undo" : "nothing_to_redo",
            std::string("Foliage '") + f.id + "' has no edit to " + (undo ? "undo" : "redo") + ".",
            undo ? "The history holds the last " + std::to_string(kHistorySteps) +
                       " foliage edits of this session (foliage.scatter, paint and clear); a scene reload or a restart "
                       "clears it. foliage.redo brings back an undone one."
                 : "Redo only follows an undo; a new edit clears the redo list.");
    const Snapshot cur = take_snapshot(f);
    if (cur.hash != h.state) stale_history(h, f.id);
    const Step& step = from.back();
    const std::size_t addedCount = step.addedRecs.size() / kFoliageRecordBytes;
    const std::size_t keptCount = step.beforeCount - step.removed.size();
    const std::optional<std::size_t> have = cur.existed ? record_count(cur.bytes) : std::optional<std::size_t>(0);
    if (!have || *have != (undo ? keptCount + addedCount : std::size_t(step.beforeCount))) stale_history(h, f.id);
    const std::string file = write_target("Foliage.instances", step.file);
    std::vector<std::uint8_t> out;
    const bool deleteFile = undo && !step.existedBefore;
    if (!deleteFile) out = undo ? apply_backward(cur.bytes, step) : apply_forward(cur.bytes, step);
    if (deleteFile) {
        if (cur.existed) {
            std::error_code ec;
            fs::remove_file(fs::resolve(file), ec);
            if (ec)
                throw CommandError("write_failed", file + ": " + ec.message(),
                                   "Check that the file is not open elsewhere. Nothing changed.");
        }
    } else if (auto w = fs::write_bytes(file, out.data(), out.size()); !w.ok()) {
        throw CommandError("write_failed", file + ": " + w.error().message,
                           "Check that the folder is writable and the file is not open elsewhere. Nothing changed.");
    }
    const Json meshes = undo ? step.meshesBefore : step.meshesAfter;
    const std::string field = undo ? step.instBefore : step.file;
    f.foliage->meshes = meshes;
    f.foliage->instances = field;
    const std::string label = step.label;
    const std::size_t count = deleteFile ? 0 : (out.size() - kFoliageHeaderBytes) / kFoliageRecordBytes;
    std::vector<Step>& to = undo ? h.redo : h.undo;
    to.push_back(std::move(from.back()));
    from.pop_back();
    h.state = state_hash(field, meshes, !deleteFile, out.data(), out.size());
    Json res = Json::object({{"entity", f.id},
                             {undo ? "undone" : "redone", label},
                             {"file", file},
                             {"instances", count},
                             {"deleted", deleteFile}});
    add_history_fields(res, h);
    return res;
}

}  // namespace

void register_foliage_commands(Engine&, Engine::Impl& I) {
    auto H = std::make_shared<Histories>();  // the undo histories of this engine, by Foliage entity id
    I.commands.add({"foliage.scatter", "Fill a Foliage's instances by a ScatterRule over a terrain, deterministically.",
                    "Reads the ScatterRule of `rule` (an entity id; default: the Foliage entity itself), places "
                    "instances on its Terrain "
                    "(one jittered candidate per 1/sqrt(density) m cell, hashed from `seed`) and keeps those that pass "
                    "slopeRange, "
                    "heightRange, layerMask (a layer counts at weight >= 0.5), holes and minSpacing. Picks mesh by "
                    "weight, scale in "
                    "scaleRange, yaw at random, lean by alignToNormal, then writes the instances file (a new one next "
                    "to the scene when "
                    "Foliage.instances is empty) and sets Foliage.meshes to the rule's meshes. The same rule, seed and "
                    "terrain give the "
                    "same file byte for byte. `dryRun` only counts. Result: {file, instances, bytes, candidates, "
                    "placed, rejected: "
                    "{outside, hole, height, slope, layer, spacing}, meshes, undo, undoDepth, redoDepth, historyId, "
                    "historyLost}. Example: "
                    "foliage.scatter {\"entity\":\"grass\"}",
                    parse_schema(R"({"type":"object","properties":{
               "entity":{"type":"string","description":"Entity id of the Foliage."},
               "rule":{"type":"string","description":"Entity id with the ScatterRule (default: the Foliage entity)."},
               "dryRun":{"type":"boolean","default":false,"description":"Only count the instances: nothing is written or changed."}},"required":["entity"]})"),
                    false, "world",
                    "More than 2,000,000 instances (the most one file holds) or more than 16.7 million grid cells is "
                    "refused before anything changes, with the knobs to turn. The edit is one step of the Foliage's "
                    "undo history (foliage.undo, foliage.redo; in memory, the last 64 steps): `undo` is {command: "
                    "\"foliage.undo\", args: {entity}}. A scatter over a filled file costs a history step about the "
                    "size of both files."},
                   [&I, H](const Json& a) { return do_scatter(I, *H, a); });
    I.commands.add(
        {"foliage.paint", "Add or remove foliage instances by hand in a circle on the ground.",
         "Adds instances (mode \"add\") within `radius` metres of `center` (world [x, z]) or of every one of `points` "
         "(a "
         "stroke of up to 512 stamps in ONE call and one rewrite of the file; the stamps are placed in order, each one "
         "against everything placed before it) with the placement rules of "
         "the "
         "ScatterRule (`rule` or the Foliage entity's own; without one: the ScatterRule defaults, equal mesh weights) "
         "and a spacing against the instances already there; `density` per m2 (default: the rule's), `mesh` limits the "
         "brush "
         "to one of Foliage.meshes, `seed` changes the draw. Mode \"remove\" deletes the instances in the circle (of "
         "`mesh` "
         "when given); it needs no Terrain and no rule. Deterministic. `continueStroke` adds the call to the newest "
         "undo step (a brush that "
         "stamps while the mouse is down is ONE undo step). Result: {added, removed, instances, file, undo, undoDepth, "
         "redoDepth, historyId, historyLost, continued?, historyDropped?, historyReset?, historiesEvicted?}. Each call "
         "rewrites the whole instances file "
         "(a file of 2,000,000 instances is 52 MB): send a stroke as `points` in pieces a few times a second, not one "
         "call "
         "per stamp. Example: foliage.paint "
         "{\"entity\":\"grass\",\"center\":[10,20],\"radius\":5}",
         parse_schema(R"({"type":"object","properties":{
               "entity":{"type":"string","description":"Entity id of the Foliage."},
               "rule":{"type":"string","description":"Entity id with the ScatterRule whose placement rules apply (default: the Foliage entity, if it has one)."},
               "mode":{"type":"string","enum":["add","remove"],"default":"add","description":"Add instances or remove them."},
               "center":{"type":"array","items":{"type":"number"},"minItems":2,"maxItems":2,"description":"World metres [x, z]. Give center or points, not both."},
               "points":{"type":"array","items":{"type":"array","items":{"type":"number"},"minItems":2,"maxItems":2},"minItems":1,"maxItems":512,"description":"Several stamps as world metres [[x, z], ...], at most 512: a brush stroke in one call (one file rewrite and one history step). Give center or points, not both."},
               "radius":{"type":"number","exclusiveMinimum":0,"description":"Brush radius in metres (the same for every point)."},
               "density":{"type":"number","exclusiveMinimum":0,"description":"Instances per square metre when adding (default: the rule's density, 0.1 without a rule)."},
               "mesh":{"type":"string","description":"Limit the brush to this mesh of Foliage.meshes."},
               "seed":{"type":"integer","description":"Seed of the draw (default: the rule's seed). The same arguments always give the same instances."},
               "continueStroke":{"type":"boolean","default":false,"description":"Add this call to the Foliage's newest undo step instead of making a new one: a stroke sent in pieces is still ONE undo step. The newest step must be a foliage.paint and nothing may have been undone since; otherwise an error (foliage.scatter and foliage.clear refuse it). The first piece is sent without it."}},"required":["entity","radius"]})"),
         false, "world",
         "A stroke never puts two instances closer than half the average gap of `density` (or minSpacing when larger), "
         "so "
         "painting the same spot twice does not stack them. Instances of an added stroke are appended after the "
         "existing "
         "ones. An empty result changes nothing (no undo step) and says why in `counts.rejected`. The file is created "
         "next to the "
         "scene when Foliage.instances is empty. One undo step per call (foliage.undo); a continued stroke joins the "
         "newest step."},
        [&I, H](const Json& a) { return do_paint(I, *H, a); });
    I.commands.add(
        {"foliage.clear", "Remove every instance of a Foliage, or those in a rectangle.",
         "Empties the Foliage's instances file (the file stays, with 0 instances), or removes only the instances "
         "inside "
         "`region` ([minX, minZ, maxX, maxZ] in world metres, edges included). Result: {removed, instances, file, "
         "undo, undoDepth, redoDepth, historyId, historyLost}. "
         "Example: foliage.clear {\"entity\":\"grass\",\"region\":[0,0,50,50]}",
         parse_schema(R"({"type":"object","properties":{
               "entity":{"type":"string","description":"Entity id of the Foliage."},
               "region":{"type":"array","items":{"type":"number"},"minItems":4,"maxItems":4,"description":"[minX, minZ, maxX, maxZ] in world metres; omit for all."}},"required":["entity"]})"),
         false, "world",
         "A Foliage with no file, or a file with nothing in the region, changes nothing (no undo step). One undo "
         "step (foliage.undo)."},
        [&I, H](const Json& a) { return do_clear(I, *H, a); });
    for (bool undo : {true, false}) {
        I.commands.add(
            {undo ? "foliage.undo" : "foliage.redo",
             undo ? "Undo the last foliage.scatter, foliage.paint or foliage.clear of a Foliage."
                  : "Redo the foliage edit the last foliage.undo took back.",
             std::string(
                 undo ? "Puts the instances file, Foliage.meshes and Foliage.instances back as they were before "
                        "the newest edit of this Foliage (one command's worth; a continued paint stroke is one). "
                      : "Applies the undone edit again. ") +
                 "The history is in memory (the last 64 edits or 128 MB per Foliage, since the engine started): a "
                 "scene "
                 "reload, a restart, or a change of the file or of the Foliage fields by anything but the foliage "
                 "commands clears it (error stale_history, nothing changes). A new edit clears the redo list. A scene "
                 "save does not touch the history. Result: {undone|redone, file, instances, deleted, undoDepth, "
                 "redoDepth, historyId, historyLost}. Example: " +
                 std::string(undo ? "foliage.undo" : "foliage.redo") + " {\"entity\":\"grass\"}",
             parse_schema(R"({"type":"object","properties":{
               "entity":{"type":"string","description":"Entity id of the Foliage."}},"required":["entity"]})"),
             false, "world"},
            [&I, H, undo](const Json& a) { return do_undo_redo(I, *H, a, undo); });
    }
    declare_command_capabilities(I.commands, {{"foliage.scatter", capability_sets::edits_project()},
                                              {"foliage.paint", capability_sets::edits_project()},
                                              {"foliage.clear", capability_sets::edits_project()},
                                              {"foliage.undo", capability_sets::edits_project()},
                                              {"foliage.redo", capability_sets::edits_project()}});
}

}  // namespace fa
