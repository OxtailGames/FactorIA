// The foliage commands (M75-P6b, docs/BIG_WORLDS_TERRAIN.md "Foliage"): foliage.scatter, foliage.paint, foliage.clear and
// foliage.restore (the undo of the three). They write the instances file of a Foliage (fa/scene/foliage.h) and set the fields
// of the component that name it.
//
// Determinism: the same rule, seed and terrain give the same file byte for byte. The candidates are the points of a jittered grid
// anchored at the world origin (one candidate per cell of 1 / sqrt(density) metres, visited row by row), each one drawn from an
// integer hash (splitmix64) of the seed and its cell, so nothing depends on where the area starts, on the order of calls or on a
// clock. The numbers are IEEE double operations (+ - * / sqrt, floor, round) and are quantised before they are stored, so a
// last-digit difference of the terrain's float math between x86 and ARM does not reach the file.
#include <algorithm>
#include <cmath>
#include <cstring>
#include <format>
#include <limits>
#include <unordered_map>

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
    World* world = nullptr;
    Entity terrain = kNullEntity;
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

// What the heap-light spatial hash of the accepted points holds: world (x, z) of each.
struct Spacing {
    double cell = 0;
    std::vector<std::pair<double, double>> pts;
    std::unordered_map<std::uint64_t, std::vector<std::uint32_t>> grid;
    static std::uint64_t key(std::int64_t cx, std::int64_t cz) {
        return (std::uint64_t(std::uint32_t(cx)) << 32) | std::uint64_t(std::uint32_t(cz));
    }
    void add(double x, double z) {
        pts.emplace_back(x, z);
        grid[key(std::int64_t(std::floor(x / cell)), std::int64_t(std::floor(z / cell)))].push_back(
            std::uint32_t(pts.size() - 1));
    }
    bool blocked(double x, double z, double dist) const {
        const std::int64_t cx = std::int64_t(std::floor(x / cell)), cz = std::int64_t(std::floor(z / cell));
        for (std::int64_t i = cx - 1; i <= cx + 1; ++i)
            for (std::int64_t j = cz - 1; j <= cz + 1; ++j) {
                auto it = grid.find(key(i, j));
                if (it == grid.end()) continue;
                for (std::uint32_t k : it->second) {
                    const double dx = pts[k].first - x, dz = pts[k].second - z;
                    if (dx * dx + dz * dz < dist * dist) return true;
                }
            }
        return false;
    }
};

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
        sp.cell = g.spacing;
        for (const auto& p : existing) sp.add(p.first, p.second);
    }
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
            if (!terrain_sample(*g.world, g.terrain, float(wx), float(wz), ts)) {
                TerrainSample ignore;
                if (terrain_sample(*g.world, g.terrain, float(wx), float(wz), ignore, true))
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
            const double slope = std::atan2(std::sqrt(double(ts.normal.x) * double(ts.normal.x) +
                                                      double(ts.normal.z) * double(ts.normal.z)),
                                            double(ts.normal.y)) *
                                 (180.0 / kPi);
            if (slope < g.slopeMin || slope > g.slopeMax) {
                ++c.slope;
                continue;
            }
            if (g.layerMask != -1) {
                TerrainLayerWeights lw;
                bool ok = false;
                if (terrain_layer_weights(*g.world, g.terrain, float(wx), float(wz), lw)) {
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

// ------------------------------------------------------------------------------------------------ files and undo

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

struct Previous {
    Json meshes;
    std::string instances;
    bool existed = false;
    std::vector<std::uint8_t> bytes;
};

Json undo_json(const std::string& entityId, const std::string& file, const Previous& p) {
    Json args =
        Json::object({{"entity", entityId},
                      {"file", file},
                      {"instances", p.instances},
                      {"meshes", p.meshes},
                      {"data", p.existed ? Json(base64_encode(p.bytes.data(), p.bytes.size())) : Json(nullptr)}});
    return Json::object({{"command", "foliage.restore"}, {"args", args}});
}

Previous capture(const Field& f, const std::string& file) {
    Previous p;
    p.meshes = f.foliage->meshes;
    p.instances = f.foliage->instances;
    if (fs::exists(file)) {
        auto b = fs::read_bytes(file);
        if (!b.ok())
            throw CommandError("failed", file + ": " + b.error().message,
                               b.error().hint.empty() ? "Check that the file can be read." : b.error().hint);
        p.existed = true;
        p.bytes = std::move(*b);
    }
    return p;
}

// Writes `instances` to `file`, sets Foliage.meshes (when `meshes` is not null) and Foliage.instances, and returns the result
// fields every command shares (file, instances, undo). Nothing changes when the encoding or the write fails.
Json commit(Field& f, const std::string& file, const std::vector<FoliageInstance>& instances, const Json& meshes) {
    const Json newMeshes = meshes.is_null() ? f.foliage->meshes : meshes;
    const std::uint32_t meshCount = std::uint32_t(newMeshes.is_array() ? newMeshes.size() : 0);
    auto bytes = encode_foliage(instances, meshCount);
    if (!bytes.ok()) throw CommandError("invalid_argument", bytes.error().message, bytes.error().hint);
    Previous prev = capture(f, file);
    if (auto w = fs::write_bytes(file, bytes->data(), bytes->size()); !w.ok())
        throw CommandError("write_failed", file + ": " + w.error().message,
                           w.error().hint.empty()
                               ? "Check that the folder is writable and the file is not open elsewhere."
                               : w.error().hint);
    f.foliage->meshes = newMeshes;
    f.foliage->instances = file;
    Json out =
        Json::object({{"entity", f.id}, {"file", file}, {"instances", instances.size()}, {"bytes", bytes->size()}});
    out["undo"] = undo_json(f.id, file, prev);
    return out;
}

// The instances the file holds now (none when the field is empty or the file is missing).
std::vector<FoliageInstance> load_instances(const Field& f, std::string& file) {
    file = f.foliage->instances;
    if (file.empty() || !fs::exists(file)) return {};
    auto r = read_foliage(file, f.meshes.size());
    if (!r.ok())
        throw CommandError("invalid_argument", r.error().message,
                           (r.error().hint.empty() ? std::string() : r.error().hint + " ") +
                               "The file was not changed. Restore it, or run foliage.scatter to write a new one.");
    return std::move(*r);
}

std::vector<std::pair<double, double>> world_xz(const Mat4& toWorld, const std::vector<FoliageInstance>& v) {
    std::vector<std::pair<double, double>> out;
    out.reserve(v.size());
    for (const FoliageInstance& in : v) {
        const Vec3 w = toWorld.transform_point(in.position);
        out.emplace_back(double(w.x), double(w.z));
    }
    return out;
}

// ------------------------------------------------------------------------------------------------ the shared setup

struct Setup {
    Field field;
    Entity ruleEntity = kNullEntity;
    ScatterRule rule;
    Entity terrain = kNullEntity;
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

Gen make_gen(Engine::Impl& I, const Setup& s) {
    Gen g;
    g.world = &I.world;
    g.terrain = s.terrain;
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

Setup open_setup(Engine::Impl& I, const Json& a, bool requireRule, const char* command) {
    Setup s;
    s.field = open_field(I, a);
    s.ruleEntity = find_rule_entity(I, a, s.field, requireRule, command);
    if (s.ruleEntity) {
        s.rule = *I.world.get<ScatterRule>(s.ruleEntity);
        if (requireRule) check_rule(I, s.ruleEntity, s.rule);
    }
    s.terrain = find_terrain(I, s.ruleEntity, s.ruleEntity ? &s.rule : nullptr, s.field);
    need_ground(I, s.terrain, s.field.id);
    s.toWorld = I.world.world_matrix(s.field.entity);
    s.toLocal = s.toWorld.inverse();
    return s;
}

// ------------------------------------------------------------------------------------------------ foliage.scatter

Json do_scatter(Engine::Impl& I, const Json& a) {
    Setup s = open_setup(I, a, true, "foliage.scatter");
    const bool dry = a.contains("dryRun") && a["dryRun"].is_boolean() && a["dryRun"].get<bool>();
    if (s.rule.meshes.empty())
        throw CommandError(
            "invalid_argument",
            "ScatterRule of '" + I.world.id_of(s.ruleEntity) +
                "' has no meshes, so there is nothing to place (at /meshes).",
            "Add at least one {\"mesh\": path, \"weight\": 1} to ScatterRule.meshes (scene.set_component).");
    Gen g = make_gen(I, s);
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
    std::string file = s.field.foliage->instances;
    if (file.empty())
        file = default_file(I, s.field.id);
    else
        file = write_target("Foliage.instances", file);
    Json res;
    if (dry) {
        res = Json::object({{"entity", s.field.id},
                            {"file", file},
                            {"instances", out.size()},
                            {"bytes", foliage_file_bytes(out.size())}});
    } else {
        res = commit(s.field, file, out, meshes);
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

double need_number(const Json& a, const char* key, const char* what, double lo, double hi) {
    const std::string p = std::string("/") + key;
    if (!a.contains(key) || !a[key].is_number())
        bad(p, std::string("Missing number '") + key + "' (" + what + ")", "Write a plain number such as 5.");
    const double d = a[key].get<double>();
    if (!std::isfinite(d) || d < lo || d > hi)
        bad(p, std::format("{} is outside {} .. {}", d, lo, hi), "Use a value inside that range.");
    return d;
}

Json do_paint(Engine::Impl& I, const Json& a) {
    Setup s = open_setup(I, a, false, "foliage.paint");
    Field& f = s.field;
    const std::string mode = a.contains("mode") && a["mode"].is_string() ? a["mode"].get<std::string>() : "add";
    if (mode != "add" && mode != "remove") bad("/mode", "mode is '" + mode + "'", "Use \"add\" or \"remove\".");
    if (!a.contains("center") || !a["center"].is_array() || a["center"].size() != 2 || !a["center"][0].is_number() ||
        !a["center"][1].is_number())
        bad("/center", "center must be [x, z] in world metres", "Example: [10, 20].");
    const double cx = need_number(Json::object({{"v", a["center"][0]}}), "v", "center x", -1e7, 1e7);
    const double cz = need_number(Json::object({{"v", a["center"][1]}}), "v", "center z", -1e7, 1e7);
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
    std::string file;
    std::vector<FoliageInstance> all = load_instances(f, file);
    const Mat4 toWorld = s.toWorld;
    std::vector<FoliageInstance> out = all;
    Json res;
    if (mode == "remove") {
        std::vector<FoliageInstance> kept;
        kept.reserve(all.size());
        std::uint64_t removed = 0;
        for (const FoliageInstance& in : all) {
            const Vec3 w = toWorld.transform_point(in.position);
            const double dx = double(w.x) - cx, dz = double(w.z) - cz;
            if (dx * dx + dz * dz <= radius * radius && (only < 0 || in.mesh == only))
                ++removed;
            else
                kept.push_back(in);
        }
        if (removed == 0 || file.empty()) {
            return Json::object({{"entity", f.id},
                                 {"added", 0},
                                 {"removed", 0},
                                 {"instances", all.size()},
                                 {"file", file},
                                 {"note", "No instance lies inside the brush: nothing changed."}});
        }
        res = commit(f, file, kept, Json(nullptr));
        res["added"] = 0;
        res["removed"] = removed;
        return res;
    }
    // add: the same placement rules as foliage.scatter, with a spacing against the instances already there
    Gen g = make_gen(I, s);
    if (a.contains("density")) g.density = need_number(a, "density", "instances per square metre", 1e-6, 1e6);
    // A repeated stroke must not stack instances on the same spot: never closer than half the average gap.
    g.spacing = std::max(g.spacing, 0.5 / std::sqrt(g.density));
    if (a.contains("seed"))
        g.seed =
            std::uint64_t(std::uint32_t(std::int32_t(need_number(a, "seed", "the seed", -2147483648.0, 2147483647.0))));
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
    g.circle = true;
    g.cx = cx, g.cz = cz, g.r = radius;
    g.x0 = cx - radius, g.x1 = cx + radius, g.z0 = cz - radius, g.z1 = cz + radius;
    std::vector<std::pair<double, double>> near;
    for (const auto& p : world_xz(toWorld, all)) {
        const double dx = p.first - cx, dz = p.second - cz, reach = radius + g.spacing;
        if (dx * dx + dz * dz <= reach * reach) near.push_back(p);
    }
    std::vector<FoliageInstance> added;
    Counts c;
    run_generator(g, near, all.size(), added, c);
    out.insert(out.end(), added.begin(), added.end());
    if (added.empty())
        return Json::object(
            {{"entity", f.id},
             {"added", 0},
             {"removed", 0},
             {"instances", all.size()},
             {"file", file},
             {"counts", counts_json(c)},
             {"note", "No instance could be placed in the brush (see counts.rejected): nothing changed."}});
    if (file.empty()) file = default_file(I, f.id);
    res = commit(f, file, out, Json(nullptr));
    res["added"] = added.size();
    res["removed"] = 0;
    res["counts"] = counts_json(c);
    return res;
}

// ------------------------------------------------------------------------------------------------ foliage.clear

Json do_clear(Engine::Impl& I, const Json& a) {
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
    std::string file;
    std::vector<FoliageInstance> all = load_instances(f, file);
    const Mat4 toWorld = I.world.world_matrix(f.entity);
    std::vector<FoliageInstance> kept;
    std::uint64_t removed = 0;
    for (const FoliageInstance& in : all) {
        bool inside = true;
        if (hasRegion) {
            const Vec3 w = toWorld.transform_point(in.position);
            inside = double(w.x) >= r[0] && double(w.x) <= r[2] && double(w.z) >= r[1] && double(w.z) <= r[3];
        }
        if (inside)
            ++removed;
        else
            kept.push_back(in);
    }
    if (removed == 0)
        return Json::object({{"entity", f.id},
                             {"removed", 0},
                             {"instances", all.size()},
                             {"file", file},
                             {"note", "There was nothing to remove: nothing changed."}});
    Json res = commit(f, file, kept, Json(nullptr));
    res["removed"] = removed;
    return res;
}

// ------------------------------------------------------------------------------------------------ foliage.restore

Json do_restore(Engine::Impl& I, const Json& a) {
    Field f = open_field(I, a);
    if (!a.contains("file") || !a["file"].is_string() || a["file"].get<std::string>().empty())
        bad("/file", "Missing `file`", "Pass the `undo` of a foliage command as it was returned.");
    const std::string file = write_target("/file", a["file"].get<std::string>());
    if (!a.contains("data") || !(a["data"].is_null() || a["data"].is_string()))
        bad("/data", "`data` must be the base64 of the file, or null to delete it", "Pass the `undo` as returned.");
    if (!a.contains("meshes") || !a["meshes"].is_array())
        bad("/meshes", "`meshes` must be an array", "Pass the `undo` as returned.");
    const std::string instances =
        a.contains("instances") && a["instances"].is_string() ? a["instances"].get<std::string>() : std::string();
    std::vector<std::uint8_t> bytes;
    if (a["data"].is_string()) {
        const std::vector<unsigned char> raw = base64_decode(a["data"].get<std::string>());
        bytes.assign(raw.begin(), raw.end());
        auto check = decode_foliage(bytes.data(), bytes.size(), a["meshes"].size(), file);
        if (!check.ok()) throw CommandError("invalid_argument", check.error().message, check.error().hint);
    }
    Previous prev = capture(f, file);
    if (a["data"].is_string()) {
        if (auto w = fs::write_bytes(file, bytes.data(), bytes.size()); !w.ok())
            throw CommandError("write_failed", file + ": " + w.error().message,
                               "Check that the file is not open elsewhere.");
    } else if (prev.existed) {
        std::error_code ec;
        fs::remove_file(fs::resolve(file), ec);
        if (ec)
            throw CommandError("write_failed", file + ": " + ec.message(),
                               "Check that the file is not open elsewhere.");
    }
    f.foliage->meshes = a["meshes"];
    f.foliage->instances = instances;
    Json out = Json::object({{"entity", f.id}, {"file", file}, {"restored", true}, {"deleted", a["data"].is_null()}});
    out["undo"] = undo_json(f.id, file, prev);
    return out;
}

}  // namespace

void register_foliage_commands(Engine&, Engine::Impl& I) {
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
                    "{outside, hole, height, slope, layer, spacing}, meshes, undo}. Example: foliage.scatter "
                    "{\"entity\":\"grass\"}",
                    parse_schema(R"({"type":"object","properties":{
               "entity":{"type":"string","description":"Entity id of the Foliage."},
               "rule":{"type":"string","description":"Entity id with the ScatterRule (default: the Foliage entity)."},
               "dryRun":{"type":"boolean","default":false,"description":"Only count the instances: nothing is written or changed."}},"required":["entity"]})"),
                    false, "world",
                    "More than 2,000,000 instances (the most one file holds) or more than 16.7 million grid cells is "
                    "refused before "
                    "anything changes, with the knobs to turn. `undo` is {command: \"foliage.restore\", args} carrying "
                    "the previous file "
                    "(base64) and the previous Foliage.meshes and Foliage.instances: calling it puts them back and "
                    "returns the redo. "
                    "The editor's brush is a later package (M75 P6c)."},
                   [&I](const Json& a) { return do_scatter(I, a); });
    I.commands.add(
        {"foliage.paint", "Add or remove foliage instances by hand in a circle on the ground.",
         "Adds instances (mode \"add\") within `radius` metres of `center` (world [x, z]) with the placement rules of "
         "the "
         "ScatterRule (`rule` or the Foliage entity's own; without one: the ScatterRule defaults, equal mesh weights) "
         "and a spacing against the instances already there; `density` per m2 (default: the rule's), `mesh` limits the "
         "brush "
         "to one of Foliage.meshes, `seed` changes the draw. Mode \"remove\" deletes the instances in the circle (of "
         "`mesh` "
         "when given). Deterministic. Result: {added, removed, instances, file, undo}. Example: foliage.paint "
         "{\"entity\":\"grass\",\"center\":[10,20],\"radius\":5}",
         parse_schema(R"({"type":"object","properties":{
               "entity":{"type":"string","description":"Entity id of the Foliage."},
               "rule":{"type":"string","description":"Entity id with the ScatterRule whose placement rules apply (default: the Foliage entity, if it has one)."},
               "mode":{"type":"string","enum":["add","remove"],"default":"add","description":"Add instances or remove them."},
               "center":{"type":"array","items":{"type":"number"},"minItems":2,"maxItems":2,"description":"World metres [x, z]."},
               "radius":{"type":"number","exclusiveMinimum":0,"description":"Brush radius in metres."},
               "density":{"type":"number","exclusiveMinimum":0,"description":"Instances per square metre when adding (default: the rule's density, 0.1 without a rule)."},
               "mesh":{"type":"string","description":"Limit the brush to this mesh of Foliage.meshes."},
               "seed":{"type":"integer","description":"Seed of the draw (default: the rule's seed). The same arguments always give the same instances."}},"required":["entity","center","radius"]})"),
         false, "world",
         "A stroke never puts two instances closer than half the average gap of `density` (or minSpacing when larger), "
         "so "
         "painting the same spot twice does not stack them. Instances of an added stroke are appended after the "
         "existing "
         "ones. An empty result changes nothing and says why in `counts.rejected`. The file is created next to the "
         "scene "
         "when Foliage.instances is empty. `undo` as foliage.scatter. The editor's brush tool is a later package (M75 "
         "P6c)."},
        [&I](const Json& a) { return do_paint(I, a); });
    I.commands.add(
        {"foliage.clear", "Remove every instance of a Foliage, or those in a rectangle.",
         "Empties the Foliage's instances file (the file stays, with 0 instances), or removes only the instances "
         "inside "
         "`region` ([minX, minZ, maxX, maxZ] in world metres, edges included). Result: {removed, instances, file, "
         "undo}. "
         "Example: foliage.clear {\"entity\":\"grass\",\"region\":[0,0,50,50]}",
         parse_schema(R"({"type":"object","properties":{
               "entity":{"type":"string","description":"Entity id of the Foliage."},
               "region":{"type":"array","items":{"type":"number"},"minItems":4,"maxItems":4,"description":"[minX, minZ, maxX, maxZ] in world metres; omit for all."}},"required":["entity"]})"),
         false, "world",
         "A Foliage with no file, or a file with nothing in the region, changes nothing. `undo` as foliage.scatter."},
        [&I](const Json& a) { return do_clear(I, a); });
    I.commands.add(
        {"foliage.restore", "Put a Foliage's instances file back: the undo and redo of the foliage.* edits.",
         "Every foliage.scatter, foliage.paint and foliage.clear returns `undo` = {command: \"foliage.restore\", "
         "args}; "
         "calling it writes the previous file (base64 `data`, or deletes it when null) and sets Foliage.meshes and "
         "Foliage.instances back. Its own result carries the `undo` that goes forward again (redo). Example: pass the "
         "`undo` "
         "of the last edit as it was returned.",
         parse_schema(R"({"type":"object","properties":{
               "entity":{"type":"string","description":"Entity id of the Foliage."},
               "file":{"type":"string","x-fa-path":"write","description":"The instances file that was written."},
               "instances":{"type":"string","description":"The value of Foliage.instances to set (\"\" = none)."},
               "meshes":{"type":"array","description":"The value of Foliage.meshes to set."},
               "data":{"type":["string","null"],"description":"Base64 of the whole file to write, or null to delete it."}},"required":["entity","file","meshes","data"]})"),
         false, "world"},
        [&I](const Json& a) { return do_restore(I, a); });
    declare_command_capabilities(I.commands, {{"foliage.scatter", capability_sets::edits_project()},
                                              {"foliage.paint", capability_sets::edits_project()},
                                              {"foliage.clear", capability_sets::edits_project()},
                                              {"foliage.restore", capability_sets::edits_project()}});
}

}  // namespace fa
