// world.bake_hlod and world.bake_cell_hlods (docs/BIG_WORLDS_LOD.md, "HLOD proxy"; docs/BIG_WORLDS_STREAMING.md, "HLOD proxies").
//
// world.bake_hlod: merges every mesh under an entity into ONE mesh in the entity's local space,
// simplifies it with the engine's own simplifier (model_make_lod: the one `model.generate_lods` and the game-ready bake use) and writes
// it as a .glb, ready for LodGroup.hlodProxy. With `apply` it sets LodGroup.hlodProxy (and a default hlodThreshold) on the entity, through
// the same set_component the scene.set_component command uses, so the editor makes it one undo step.
//
// Deterministic: the entities are visited in hierarchy order, every step is serial float arithmetic and the .glb writer is deterministic,
// so the same scene and arguments give the same bytes.
#include <algorithm>
#include <cctype>
#include <climits>
#include <cmath>
#include <cstdint>
#include <map>
#include <utility>
#include <vector>

#include "authoring_internal.h"
#include "fa/core/capability.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/scene/components.h"
#include "fa/scene/components_world.h"
#include "fa/scene/gltf_mesh.h"
#include "fa/scene/mesh_store.h"
#include "fa/scene/model_game_ready.h"
#include "fa/scene/world_index.h"
#include "fa/scene/serialize.h"
#include "fa/scene/world.h"

namespace fa {

namespace {

constexpr std::size_t kMaxSkippedListed = 20;

[[noreturn]] void fail(const std::string& message, const std::string& hint, const char* code = "invalid_argument") {
    throw CommandError(code, message, hint);
}

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

double round4(double v) { return std::round(v * 10000.0) / 10000.0; }

std::string lower(std::string s) {
    for (char& c : s) c = char(std::tolower(static_cast<unsigned char>(c)));
    return s;
}

bool ends_with(const std::string& s, const char* suffix) {
    const std::string x = suffix;
    return s.size() >= x.size() && s.compare(s.size() - x.size(), x.size(), x) == 0;
}

// The geometry of one MeshRenderer.mesh value, in the mesh's own space: a procedural mesh of this World, a .glb/.gltf file, or a built-in
// primitive (white, tinted by MeshRenderer.color and textured by MeshRenderer.texture).
Result<MeshData> mesh_data_of(const World& w, const MeshRenderer& mr) {
    const std::string& mesh = mr.mesh;
    if (MeshStore::is_id(mesh)) {
        auto got = w.meshes().get(mesh);
        if (!got.ok()) return got.error();
        return (*got)->data;
    }
    const std::string low = lower(mesh);
    if (ends_with(low, ".glb") || ends_with(low, ".gltf")) {
        auto g = read_gltf_mesh(mesh);
        if (!g.ok()) return g.error();
        return std::move(g.value().data);
    }
    auto geo = load_mesh_geometry(mesh);
    if (!geo.ok()) return geo.error();
    MeshInput in;
    in.hasIndices = true;
    in.positions.reserve((*geo)->positions.size() * 3);
    for (const Vec3& p : (*geo)->positions) {
        in.positions.push_back(p.x);
        in.positions.push_back(p.y);
        in.positions.push_back(p.z);
    }
    in.indices = (*geo)->indices;
    MeshSubmesh sm;
    sm.material.name = mesh_key(mesh);
    sm.material.color = mr.color;
    sm.material.texture = mr.texture;
    sm.start = 0;
    sm.count = std::uint32_t(in.indices.size());
    in.submeshes.push_back(sm);
    return build_mesh_data(in);
}

float det3(const Mat4& m) {
    const Vec3 a{m.at(0, 0), m.at(0, 1), m.at(0, 2)};
    const Vec3 b{m.at(1, 0), m.at(1, 1), m.at(1, 2)};
    const Vec3 c{m.at(2, 0), m.at(2, 1), m.at(2, 2)};
    return a.x * (b.y * c.z - b.z * c.y) - a.y * (b.x * c.z - b.z * c.x) + a.z * (b.x * c.y - b.y * c.x);
}

Vec3 unit_or(Vec3 v, Vec3 fallback) {
    const float len = std::sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
    return len > 1e-12f ? Vec3{v.x / len, v.y / len, v.z / len} : fallback;
}

// What the merge collects: the arrays MeshInput takes, in the root's local space.
struct Merged {
    MeshInput in;
    std::size_t meshes = 0;
    std::size_t sourceTriangles = 0;
};

// Adds `src` moved by `m` (a mirrored transform flips the winding so the faces keep facing out). Only the indices inside a submesh are
// taken (the rest are not drawn). Sizes are checked in 64 bits against the procedural-mesh limits before anything is allocated.
void append_mesh(Merged& out, const MeshData& src, const Mat4& m, const std::string& entityId) {
    std::uint64_t addIndices = 0;
    for (const MeshSubmesh& s : src.submeshes) {
        const std::uint64_t end = std::min<std::uint64_t>(std::uint64_t(s.start) + s.count, src.indices.size());
        if (end > s.start) addIndices += (end - s.start) / 3 * 3;
    }
    const std::uint64_t vertices = std::uint64_t(out.in.positions.size() / 3) + src.vertex_count();
    const std::uint64_t indices = std::uint64_t(out.in.indices.size()) + addIndices;
    if (vertices > kMaxProceduralVertices || indices > kMaxProceduralIndices)
        fail("The meshes under the root add up to more than " + std::to_string(kMaxProceduralVertices) +
                 " vertices or " + std::to_string(kMaxProceduralIndices) + " indices (stopped at '" + entityId + "').",
             "Bake a smaller subtree (one cell, one building), or give each part its own proxy and merge those "
             "with a second world.bake_hlod over a parent that holds the proxies.");
    const std::size_t base = out.in.positions.size() / 3;
    const std::size_t n = src.vertex_count();
    const bool mirrored = det3(m) < 0.0f;
    const Mat4 inv = m.inverse();
    out.in.positions.reserve(out.in.positions.size() + n * 3);
    out.in.normals.reserve(out.in.normals.size() + n * 3);
    for (std::size_t i = 0; i < n; ++i) {
        const Vec3 p = m.transform_point({src.positions[i * 3], src.positions[i * 3 + 1], src.positions[i * 3 + 2]});
        out.in.positions.insert(out.in.positions.end(), {p.x, p.y, p.z});
        Vec3 nrm{0, 1, 0};
        if (src.normals.size() >= (i + 1) * 3) {
            const float x = src.normals[i * 3], y = src.normals[i * 3 + 1], z = src.normals[i * 3 + 2];
            // the inverse transpose keeps normals perpendicular under a non-uniform scale
            nrm = unit_or({inv.at(0, 0) * x + inv.at(0, 1) * y + inv.at(0, 2) * z,
                           inv.at(1, 0) * x + inv.at(1, 1) * y + inv.at(1, 2) * z,
                           inv.at(2, 0) * x + inv.at(2, 1) * y + inv.at(2, 2) * z},
                          {0, 1, 0});
        }
        out.in.normals.insert(out.in.normals.end(), {nrm.x, nrm.y, nrm.z});
    }
    if (src.hasUvs && src.uvs.size() >= n * 2) {
        if (out.in.uvs.size() < base * 2) out.in.uvs.resize(base * 2, 0.0f);
        out.in.uvs.insert(out.in.uvs.end(), src.uvs.begin(), src.uvs.begin() + std::ptrdiff_t(n * 2));
    }
    const bool srcColors = src.colors.size() >= n * 4;
    if (srcColors || !out.in.colors.empty()) {
        if (out.in.colors.size() < base * 4) out.in.colors.resize(base * 4, 1.0f);
        if (srcColors)
            out.in.colors.insert(out.in.colors.end(), src.colors.begin(), src.colors.begin() + std::ptrdiff_t(n * 4));
        else
            out.in.colors.resize(out.in.colors.size() + n * 4, 1.0f);
    }
    for (const MeshSubmesh& s : src.submeshes) {
        const std::uint64_t end = std::min<std::uint64_t>(std::uint64_t(s.start) + s.count, src.indices.size());
        if (end <= s.start) continue;
        const std::uint64_t count = (end - s.start) / 3 * 3;
        if (count == 0) continue;
        MeshSubmesh o = s;
        o.start = std::uint32_t(out.in.indices.size());
        o.count = std::uint32_t(count);
        for (std::uint64_t k = 0; k < count; k += 3) {
            const std::uint32_t a = src.indices[s.start + k], b = src.indices[s.start + k + 1],
                                c = src.indices[s.start + k + 2];
            out.in.indices.push_back(std::uint32_t(base) + a);
            out.in.indices.push_back(std::uint32_t(base) + (mirrored ? c : b));
            out.in.indices.push_back(std::uint32_t(base) + (mirrored ? b : c));
        }
        out.in.submeshes.push_back(o);
        out.sourceTriangles += std::size_t(count / 3);
    }
    out.in.hasIndices = true;
    ++out.meshes;
}

// `ratio` and `maxError` of the bake commands: checked (with their JSON pointer) before anything is read; the default is a tenth of the
// triangles when neither is given.
ModelLodSpec parse_lod_spec(const Json& args) {
    if (args.contains("ratio") && !args["ratio"].is_null() && !args["ratio"].is_number())
        fail("`ratio` (/ratio) is " + args["ratio"].dump() + ": it must be a number.",
             "Pass the share of triangles to keep, 0 < ratio <= 1, e.g. 0.1.");
    if (args.contains("maxError") && !args["maxError"].is_null() && !args["maxError"].is_number())
        fail("`maxError` (/maxError) is " + args["maxError"].dump() + ": it must be a number of metres.",
             "Pass how far the simplified surface may move, e.g. 0.25.");
    ModelLodSpec spec;
    const bool hasRatio = args.contains("ratio") && args["ratio"].is_number();
    const bool hasError = args.contains("maxError") && args["maxError"].is_number();
    if (hasRatio) {
        const double r = args["ratio"].get<double>();
        if (!(r > 0.0 && r <= 1.0))
            fail("`ratio` (/ratio) is " + args["ratio"].dump() + ": it must be above 0 and at most 1.",
                 "Pass the share of triangles to keep: 0.1 keeps a tenth, 1 keeps them all (only merges and welds).");
        spec.ratio = r;
    }
    if (hasError) {
        const double e = args["maxError"].get<double>();
        if (!(e > 0.0 && e <= 1.0e6))
            fail("`maxError` (/maxError) is " + args["maxError"].dump() + ": it must be above 0 metres.",
                 "Pass how far the simplified surface may move, e.g. 0.25 for a building seen from far away.");
        spec.error = e;
    }
    if (!hasRatio && !hasError) spec.ratio = 0.1;
    return spec;
}

// What a merge collects besides the geometry: the entities it left out (with why; the first kMaxSkippedListed are listed) and the
// meshes already read (one per mesh + texture + colour).
struct MergeRun {
    Merged merged;
    Json skipped = Json::array();
    std::size_t skippedCount = 0;
    std::map<std::string, MeshData> cache;
    void skip(const std::string& id, const std::string& why) {
        ++skippedCount;
        if (skipped.size() < kMaxSkippedListed) skipped.push_back(Json::object({{"entity", id}, {"reason", why}}));
    }
};

// Merges the meshes of the entities on `stack` and of everything under them (hierarchy order: the stack's LAST entry first, children in
// order) into `run.merged`, each moved by `toLocal * world matrix`. Inactive entities, GPU-instanced renderers and meshes that cannot be
// read are skipped and listed.
void merge_walk(World& world, std::vector<Entity> stack, const Mat4& toLocal, MergeRun& run) {
    while (!stack.empty()) {
        const Entity e = stack.back();
        stack.pop_back();
        const std::vector<Entity>& kids = std::as_const(world).children(e);
        for (auto it = kids.rbegin(); it != kids.rend(); ++it) stack.push_back(*it);
        const MeshRenderer* mr = std::as_const(world).get<MeshRenderer>(e);
        if (!mr) continue;
        const std::string id = world.id_of(e);
        if (!world.active_in_hierarchy(e)) {
            run.skip(id, "inactive");
            continue;
        }
        if (mr->instances > 0) {
            run.skip(id, "GPU instances (MeshRenderer.instances) are drawn by their material, not from the mesh");
            continue;
        }
        const std::string key = mr->mesh + "\n" + mr->texture + "\n" + std::to_string(mr->color.r) + "," +
                                std::to_string(mr->color.g) + "," + std::to_string(mr->color.b) + "," +
                                std::to_string(mr->color.a);
        auto cached = run.cache.find(key);
        if (cached == run.cache.end()) {
            auto data = mesh_data_of(world, *mr);
            if (!data.ok()) {
                run.skip(id, data.error().message);
                continue;
            }
            cached = run.cache.emplace(key, std::move(data.value())).first;
        }
        if (cached->second.triangle_count() == 0) {
            run.skip(id, "no triangles");
            continue;
        }
        append_mesh(run.merged, cached->second, toLocal * world.world_matrix(e), id);
    }
}

// The merged arrays as one mesh: built, welded by material and simplified by `spec`. `label` names the entity or cell in the errors.
MeshData simplify_merged(const Merged& merged, const ModelLodSpec& spec, const std::string& label, ModelLodInfo* info) {
    auto built = build_mesh_data(merged.in);
    if (!built.ok()) fail("The merged mesh is not valid: " + built.error().message, built.error().hint, "internal");
    auto welded = model_merge_by_material(built.value());
    if (!welded.ok())
        fail("Cannot merge the meshes under '" + label + "': " + welded.error().message, welded.error().hint);
    auto simplified = model_make_lod(welded.value(), spec, info);
    if (!simplified.ok())
        fail("Cannot simplify the merged mesh of '" + label + "': " + simplified.error().message,
             simplified.error().hint);
    return std::move(simplified.value());
}

Json bake_hlod(Engine::Impl& I, const Json& args) {
    const char* kCommand = "world.bake_hlod";
    for (auto it = args.begin(); it != args.end(); ++it) {
        const std::string& k = it.key();
        if (k != "entity" && k != "scene" && k != "root" && k != "out" && k != "ratio" && k != "maxError" &&
            k != "apply")
            fail("Unknown argument `" + k + "` at /" + k + ".",
                 "The arguments are entity (or scene + root), out, ratio, maxError and apply." +
                     (k == "id" || k == "path" ? std::string(" Use `entity` for the entity and `out` for the file.")
                                               : std::string()));
    }
    // Contradictions first, before any file is read.
    const bool hasEntity = args.contains("entity") && !args["entity"].is_null();
    const bool hasScene = args.contains("scene") && !args["scene"].is_null();
    const bool hasRoot = args.contains("root") && !args["root"].is_null();
    const bool apply = args.value("apply", false);
    if (hasEntity && (hasScene || hasRoot))
        fail("Both `entity` (/entity) and `" + std::string(hasScene ? "scene" : "root") + "` (/" +
                 (hasScene ? "scene" : "root") + ") are given.",
             "Pass `entity` for an entity of the open scene, or `scene` + `root` for an entity of a scene file, not "
             "both.");
    if (!hasEntity && !hasScene)
        fail("Neither `entity` nor `scene` is given (/entity).",
             "Pass the group's entity id, e.g. {\"entity\":\"town_block\",\"out\":\"assets/hlod/block.glb\"}, or a "
             "scene file and "
             "the id of a root in it: {\"scene\":\"scenes/town.scene.json\",\"root\":\"town_block\",\"out\":\"...\"}.");
    if (hasScene && !hasRoot)
        fail("`scene` is given but `root` is not (/root).",
             "Pass the id of the entity of that scene whose subtree is merged, e.g. \"root\":\"town_block\".");
    if (hasRoot && !hasScene)
        fail(
            "`root` is given without `scene` (/scene).",
            "`root` names an entity inside a scene file: add \"scene\":\"scenes/town.scene.json\", or use `entity` for "
            "the open scene.");
    if (hasScene && apply)
        fail("`apply` (/apply) works on the open scene, not on a scene file.",
             "Use `entity` with `apply`, or bake from the scene file without `apply` and set LodGroup.hlodProxy "
             "yourself.");
    for (const char* key : {"entity", "scene", "root", "out"})
        if (args.contains(key) && !args[key].is_null() &&
            (!args[key].is_string() || args[key].get<std::string>().empty()))
            fail(std::string("`") + key + "` (/" + key + ") is " + args[key].dump() +
                     ": it must be a non-empty string.",
                 std::string(key) == "out" ? "Pass the file to write, e.g. \"assets/hlod/block.glb\"."
                                           : "Pass an entity id or a project-relative scene path.");
    if (!args.contains("out") || !args["out"].is_string())
        fail("`out` is missing (/out).", "Pass the .glb to write, e.g. \"out\":\"assets/hlod/block.glb\".");
    const ModelLodSpec spec = parse_lod_spec(args);

    // The file is judged before the meshes are read and merged (the capability, then the path rules).
    require_capability(Capability::WriteProject, kCommand, "writing the proxy mesh to `out`");
    auto outPath = mesh_glb_path(args["out"].get<std::string>(), caller_capabilities().has(Capability::WriteAnywhere));
    if (!outPath.ok()) {
        const std::string code(fs::path_error_code(outPath.error()));
        throw CommandError(code.empty() ? "invalid_argument" : code, "`out` (/out): " + outPath.error().message,
                           outPath.error().hint);
    }

    // The World the entity is in: the open scene, or a scratch one loaded from the scene file.
    World scratch;
    World* world = &I.world;
    Entity root = kNullEntity;
    if (hasEntity) {
        root = need_entity(I.world, Json::object({{"id", args["entity"]}}));
    } else {
        auto scenePath = fs::normalize_checked(args["scene"].get<std::string>());
        if (!scenePath.ok() || fs::is_absolute(scenePath.value()))
            fail("`scene` (/scene) '" + args["scene"].get<std::string>() + "' is not a project-relative path.",
                 "Use a path such as scenes/town.scene.json.");
        auto text = fs::read_text(scenePath.value());
        if (!text.ok())
            fail("Cannot read scene '" + scenePath.value() + "' (/scene): " + text.error().message, text.error().hint,
                 "not_found");
        auto parsed = parse_json(text.value(), scenePath.value());
        if (!parsed.ok()) fail(parsed.error().message, parsed.error().hint);
        LoadReport report = load_scene(scratch, parsed.value(), scenePath.value());
        if (report.error_count() > 0) {
            std::string detail;
            std::size_t shown = 0;
            for (const LoadMessage& m : report.messages)
                if (m.severity == LoadMessage::Severity::Error && ++shown <= 5) detail += "\n  " + m.to_string();
            fail("Cannot bake from '" + scenePath.value() + "': it has " + std::to_string(report.error_count()) +
                     " load error(s):" + detail,
                 "Fix the file first (project.validate lists every problem with its JSON pointer). Nothing was "
                 "written.");
        }
        world = &scratch;
        root = scratch.find_by_id(args["root"].get<std::string>());
        if (root == kNullEntity)
            fail("`root` (/root) '" + args["root"].get<std::string>() + "' is not an entity of " + scenePath.value() +
                     ".",
                 "Use the id of an entity of that scene (scene.query lists them).");
    }

    // Every MeshRenderer under the root, in hierarchy order, moved into the root's local space.
    const Mat4 toLocal = world->world_matrix(root).inverse();
    MergeRun run;
    Merged& merged = run.merged;
    const Json& skipped = run.skipped;
    const std::size_t& skippedCount = run.skippedCount;
    // What is merged: the subtrees of the root's children (the children ARE the levels of a LodGroup, so under one only child 0, the
    // full-detail level, is merged). The root's own MeshRenderer is not: a LodGroup does not hide it, so it would stay drawn next to
    // the proxy, and the proxy is meant to stand for what is under the root.
    const std::vector<Entity>& rootKids = std::as_const(*world).children(root);
    const LodGroup* rootGroup = std::as_const(*world).get<LodGroup>(root);
    // Refused before any mesh is read: LodGroup.hlodProxy on an entity that is not a group yet would make its children LOD levels.
    if (apply && !rootGroup && rootKids.size() > 1)
        fail("`apply` (/apply): '" + world->id_of(root) + "' has " + std::to_string(rootKids.size()) +
                 " children and no LodGroup, and a LodGroup turns its children into LOD levels (child 0 is drawn up "
                 "close, "
                 "the others only past thresholds): applying would hide all but the first child.",
             "Wrap the children in ONE child entity (it becomes LOD 0 of the group) and bake the entity again, or bake "
             "without `apply` and set LodGroup.hlodProxy yourself on an entity whose children are the levels.");
    if (std::as_const(*world).get<MeshRenderer>(root))
        run.skip(world->id_of(root), "the entity's own MeshRenderer is not merged");
    std::size_t levelsIgnored = 0;
    std::vector<Entity> stack;
    if (rootGroup && !rootKids.empty()) {
        stack.push_back(rootKids[0]);
        levelsIgnored = rootKids.size() - 1;
    } else {
        for (auto it = rootKids.rbegin(); it != rootKids.rend(); ++it) stack.push_back(*it);
    }
    merge_walk(*world, std::move(stack), toLocal, run);
    const std::string rootId = world->id_of(root);
    if (merged.meshes == 0 || merged.in.indices.empty()) {
        std::string why;
        for (const Json& s : skipped)
            why += "\n  " + s["entity"].get<std::string>() + ": " + s["reason"].get<std::string>();
        fail("No meshes to merge under '" + rootId +
                 "': it and its children have no active MeshRenderer with triangles." +
                 (why.empty() ? std::string() : " Skipped:" + why),
             "Pass the entity that holds the group (the LodGroup entity, or a cell root); its children must have "
             "MeshRenderer components. scene.query {\"component\":\"MeshRenderer\"} lists them.");
    }

    ModelLodInfo info;
    const MeshData proxy = simplify_merged(merged, spec, rootId, &info);
    auto saved = save_mesh_glb_at(proxy, *outPath);
    if (!saved.ok()) {
        const std::string code(fs::path_error_code(saved.error()));
        throw CommandError(
            code.empty() ? "invalid_argument" : code, "Cannot write `out` (/out): " + saved.error().message,
            saved.error().hint.empty() ? "Check that the folder is writable and the file is not open elsewhere."
                                       : saved.error().hint);
    }

    // The default threshold: the proxy takes over at 8 times the group's size (Distance) or below 3% of the screen (ScreenSize), and never
    // before the group's own last threshold: 1.5 times the farthest one in Distance mode, a third less than the smallest in ScreenSize mode.
    const float dx = proxy.bmax.x - proxy.bmin.x, dy = proxy.bmax.y - proxy.bmin.y, dz = proxy.bmax.z - proxy.bmin.z;
    const float diameter = std::sqrt(dx * dx + dy * dy + dz * dz);
    Json result = Json::object({{"saved", *saved},
                                {"entity", rootId},
                                {"meshes", merged.meshes},
                                {"trianglesBefore", merged.sourceTriangles},
                                {"triangles", proxy.triangle_count()},
                                {"vertices", proxy.vertex_count()},
                                {"submeshes", proxy.submeshes.size()},
                                {"error", round4(info.error)},
                                {"diameter", round4(diameter)},
                                {"skipped", skippedCount},
                                {"levelsIgnored", levelsIgnored},
                                {"applied", false}});
    if (skippedCount > 0) result["skippedList"] = skipped;
    if (apply) {
        const LodGroup* existing = std::as_const(I.world).get<LodGroup>(root);
        const LodMode mode = existing ? existing->mode : LodMode::Distance;
        float threshold = existing ? existing->hlodThreshold : 0.0f;
        if (!(threshold > 0.0f)) {
            float last =
                0.0f;  // the farthest threshold (Distance), the smallest above 0 (ScreenSize); 0 = the group has none
            if (existing)
                for (std::size_t k = 0; k < existing->thresholds.size() && k < std::size_t(kMaxLodThresholds); ++k) {
                    const float t = existing->thresholds[k];
                    if (!(t > 0.0f) || !std::isfinite(t)) continue;
                    last = last == 0.0f ? t : (mode == LodMode::Distance ? std::max(last, t) : std::min(last, t));
                }
            if (mode == LodMode::Distance)
                threshold = std::max({8.0f * diameter, 1.0f, last * 1.5f});
            else
                threshold = last > 0.0f ? std::min(0.03f, last / 1.5f) : 0.03f;
        }
        Json fields = Json::object({{"hlodProxy", *saved}, {"hlodThreshold", round4(threshold)}});
        set_component(I.world,
                      Json::object({{"id", rootId}, {"component", "LodGroup"}, {"fields", fields}, {"merge", true}}));
        result["applied"] = true;
        result["hlodThreshold"] = round4(threshold);
    }
    return result;
}

// The cells `world.bake_cell_hlods` is asked for: `cells` is a list of [i, j] pairs or {"i", "j"} objects; absent = every cell of the
// index. Every entry is checked against the index before anything is read (JSON pointer /cells/N).
std::vector<const WorldCell*> select_cells(const WorldIndex& index, const Json& args) {
    std::vector<const WorldCell*> out;
    if (!args.contains("cells") || args["cells"].is_null()) {
        for (const WorldCell& c : index.cells) out.push_back(&c);
        return out;
    }
    if (!args["cells"].is_array())
        fail("`cells` (/cells) is " + args["cells"].dump() + ": it must be a list of cell coordinates.",
             "Pass [[0,0],[1,0]] or [{\"i\":0,\"j\":0}], or leave `cells` out to bake every cell.");
    std::size_t n = 0;
    for (const Json& e : args["cells"]) {
        const std::string ptr = "/cells/" + std::to_string(n);
        ++n;
        std::int64_t i = 0, j = 0;
        bool good = false;
        const auto whole = [](const Json& v, std::int64_t& r) {
            if (!v.is_number()) return false;
            const double d = v.get<double>();
            if (!(d >= -1.0e9 && d <= 1.0e9) || d != std::floor(d)) return false;
            r = std::int64_t(d);
            return true;
        };
        if (e.is_array() && e.size() == 2)
            good = whole(e[0], i) && whole(e[1], j);
        else if (e.is_object() && e.contains("i") && e.contains("j"))
            good = whole(e["i"], i) && whole(e["j"], j);
        if (!good)
            fail("`cells` entry " + ptr + " is " + e.dump() + ": it must be a coordinate [i, j] of two whole numbers.",
                 "Write each cell as [0,0] or {\"i\":0,\"j\":0}; `world.cells` lists the coordinates of the index.");
        const WorldCell* found = i >= INT32_MIN && i <= INT32_MAX && j >= INT32_MIN && j <= INT32_MAX
                                     ? index.find(std::int32_t(i), std::int32_t(j))
                                     : nullptr;
        if (!found) {
            std::vector<std::string> names;
            for (const WorldCell& c : index.cells)
                names.push_back("[" + std::to_string(c.i) + "," + std::to_string(c.j) + "]");
            fail("`cells` entry " + ptr + " names the cell [" + std::to_string(i) + "," + std::to_string(j) +
                     "], which is not in '" + index.path + "'.",
                 did_you_mean("[" + std::to_string(i) + "," + std::to_string(j) + "]", names).empty()
                     ? "world.cells lists the cells of the index."
                     : did_you_mean("[" + std::to_string(i) + "," + std::to_string(j) + "]", names));
        }
        for (const WorldCell* c : out)
            if (c == found)
                fail("`cells` entry " + ptr + " repeats the cell [" + std::to_string(i) + "," + std::to_string(j) +
                         "].",
                     "List every cell once.");
        out.push_back(found);
    }
    std::sort(out.begin(), out.end(),
              [](const WorldCell* a, const WorldCell* b) { return a->j != b->j ? a->j < b->j : a->i < b->i; });
    return out;
}

// One baked cell, kept in memory until every cell is done (a failure writes nothing).
struct CellBake {
    const WorldCell* cell = nullptr;
    std::string file;  // project-relative .glb
    MeshData mesh;
    std::size_t meshes = 0, trianglesBefore = 0;
    double error = 0.0;
    std::size_t skipped = 0;
};

Json bake_cell_hlods(Engine::Impl& I, const Json& args) {
    (void)I;
    const char* kCommand = "world.bake_cell_hlods";
    for (auto it = args.begin(); it != args.end(); ++it) {
        const std::string& k = it.key();
        if (k != "world" && k != "outDir" && k != "cells" && k != "ratio" && k != "maxError" && k != "maxDistance" &&
            k != "dryRun")
            fail("Unknown argument `" + k + "` at /" + k + ".",
                 "The arguments are world, outDir, cells, ratio, maxError, maxDistance and dryRun.");
    }
    if (!args.contains("world") || !args["world"].is_string() || args["world"].get<std::string>().empty())
        fail(
            "`world` is missing (/world).",
            "Pass the index file to bake, e.g. {\"world\":\"worlds/town.world.json\"} (world.split_cells writes one).");
    for (const char* key : {"outDir", "maxDistance", "dryRun"}) {
        if (!args.contains(key) || args[key].is_null()) continue;
        const bool good = std::string(key) == "outDir" ? args[key].is_string() && !args[key].get<std::string>().empty()
                          : std::string(key) == "dryRun" ? args[key].is_boolean()
                                                         : args[key].is_number();
        if (!good)
            fail(std::string("`") + key + "` (/" + key + ") is " + args[key].dump() + ": it must be " +
                     (std::string(key) == "outDir"   ? "a non-empty folder path."
                      : std::string(key) == "dryRun" ? "true or false."
                                                     : "a number of metres."),
                 std::string(key) == "outDir" ? "Pass a project folder, e.g. \"worlds/town_hlod\"."
                 : std::string(key) == "dryRun"
                     ? "Pass true to bake and report without writing anything."
                     : "Pass the farthest distance the proxies are drawn at, e.g. 900; 0 clears it.");
    }
    const bool dryRun = args.value("dryRun", false);
    const ModelLodSpec spec = parse_lod_spec(args);
    bool setDistance = false;
    double maxDistance = 0.0;
    if (args.contains("maxDistance") && args["maxDistance"].is_number()) {
        maxDistance = args["maxDistance"].get<double>();
        if (!(maxDistance >= 0.0 && maxDistance <= 1.0e9))
            fail("`maxDistance` (/maxDistance) is " + args["maxDistance"].dump() +
                     ": it must be between 0 and 1e9 metres.",
                 "Pass the farthest distance from an anchor the proxies are drawn at, e.g. 900; 0 means "
                 "StreamedWorld.hlodDistance.");
        setDistance = true;
    }

    auto indexNorm = fs::normalize_checked(args["world"].get<std::string>());
    if (!indexNorm.ok() || fs::is_absolute(indexNorm.value()))
        fail("`world` (/world) '" + args["world"].get<std::string>() + "' is not a project-relative path.",
             "Use a path such as worlds/town.world.json.");
    const std::string indexPath = indexNorm.value();
    // The folder: the index path without its .world.json, plus _hlod. The path rules are judged before the index or any scene is read.
    std::string outDir =
        args.contains("outDir") && args["outDir"].is_string() ? args["outDir"].get<std::string>() : indexPath;
    if (!(args.contains("outDir") && args["outDir"].is_string())) {
        for (const char* ext : {".world.json", ".json"})
            if (ends_with(lower(outDir), ext)) {
                outDir.resize(outDir.size() - std::string(ext).size());
                break;
            }
        outDir += "_hlod";
    }
    while (outDir.size() > 1 && (outDir.back() == '/' || outDir.back() == '\\')) outDir.pop_back();
    if (!dryRun) require_capability(Capability::WriteProject, kCommand, "writing the proxy meshes and the index");
    const bool anywhere = caller_capabilities().has(Capability::WriteAnywhere);
    const auto cell_file = [&](std::int32_t i, std::int32_t j) {
        auto file = mesh_glb_path(outDir + "/" + std::to_string(i) + "_" + std::to_string(j) + ".glb", anywhere);
        if (!file.ok()) {
            const std::string code(fs::path_error_code(file.error()));
            throw CommandError(code.empty() ? "invalid_argument" : code, "`outDir` (/outDir): " + file.error().message,
                               file.error().hint);
        }
        return file.value();
    };
    (void)cell_file(0, 0);
    std::string indexWrite;
    if (!dryRun) indexWrite = resolve_caller_project_path(indexPath, kCommand);

    WorldIndexOptions options;
    options.checkFiles = false;
    auto loaded = load_world_index(indexPath, options);
    if (!loaded.ok())
        fail("Cannot read the index '" + indexPath + "' (/world): " + loaded.error().message, loaded.error().hint,
             "not_found");
    const WorldIndex index = std::move(loaded.value());
    const std::vector<const WorldCell*> chosen = select_cells(index, args);
    std::vector<CellBake> bakes;
    for (const WorldCell* c : chosen) {
        CellBake b;
        b.cell = c;
        b.file = cell_file(c->i, c->j);
        bakes.push_back(std::move(b));
    }

    // Merge and simplify every cell in memory. A cell that cannot be read stops the command: nothing has been written yet.
    Json skippedCells = Json::array();
    std::vector<CellBake> done;
    for (CellBake& b : bakes) {
        const WorldCell& c = *b.cell;
        auto text = fs::read_text(c.scene);
        if (!text.ok())
            fail("Cannot read the scene '" + c.scene + "' of cell [" + c.id() + "]: " + text.error().message,
                 text.error().hint, "not_found");
        auto parsed = parse_json(text.value(), c.scene);
        if (!parsed.ok()) fail(parsed.error().message, parsed.error().hint);
        World scratch;
        LoadReport report = load_scene(scratch, parsed.value(), c.scene);
        if (report.error_count() > 0) {
            std::string detail;
            std::size_t shown = 0;
            for (const LoadMessage& m : report.messages)
                if (m.severity == LoadMessage::Severity::Error && ++shown <= 5) detail += "\n  " + m.to_string();
            fail("Cannot bake cell [" + c.id() + "]: '" + c.scene + "' has " + std::to_string(report.error_count()) +
                     " load error(s):" + detail,
                 "Fix the file first (project.validate lists every problem with its JSON pointer). Nothing was "
                 "written.");
        }
        const DVec3 corner = world_cell_corner(index, c);
        const Mat4 toLocal = Mat4::translate(Vec3{-float(corner.x), -float(corner.y), -float(corner.z)});
        MergeRun run;
        std::vector<Entity> stack = scratch.roots();
        std::reverse(stack.begin(), stack.end());
        merge_walk(scratch, std::move(stack), toLocal, run);
        if (run.merged.meshes == 0 || run.merged.in.indices.empty()) {
            skippedCells.push_back(
                Json::object({{"coord", Json::array({c.i, c.j})},
                              {"reason", "no active MeshRenderer with triangles in '" + c.scene + "' (" +
                                             std::to_string(run.skippedCount) +
                                             " skipped): the cell keeps its current proxy, if any"}}));
            continue;
        }
        ModelLodInfo info;
        b.mesh = simplify_merged(run.merged, spec, "cell [" + c.id() + "]", &info);
        b.meshes = run.merged.meshes;
        b.trianglesBefore = run.merged.sourceTriangles;
        b.error = info.error;
        b.skipped = run.skippedCount;
        done.push_back(std::move(b));
    }
    if (done.empty() && !chosen.empty() && !dryRun)
        fail("No cell has a mesh to bake (" + std::to_string(skippedCells.size()) +
                 " cells skipped, first: " + skippedCells[0]["reason"].get<std::string>() + ").",
             "Check the cell scenes with scene.query {\"component\":\"MeshRenderer\"}; a cell without meshes needs no "
             "proxy.");

    Json baked = Json::array();
    std::size_t trianglesBefore = 0, triangles = 0;
    for (const CellBake& b : done) {
        trianglesBefore += b.trianglesBefore;
        triangles += b.mesh.triangle_count();
        baked.push_back(Json::object({{"coord", Json::array({b.cell->i, b.cell->j})},
                                      {"mesh", b.file},
                                      {"meshes", b.meshes},
                                      {"trianglesBefore", b.trianglesBefore},
                                      {"triangles", b.mesh.triangle_count()},
                                      {"vertices", b.mesh.vertex_count()},
                                      {"error", round4(b.error)},
                                      {"skipped", b.skipped}}));
    }
    Json result = Json::object({{"world", indexPath},
                                {"outDir", outDir},
                                {"baked", baked},
                                {"cellsBaked", done.size()},
                                {"cellsSkipped", skippedCells},
                                {"trianglesBefore", trianglesBefore},
                                {"triangles", triangles},
                                {"dryRun", dryRun},
                                {"written", Json::array()}});
    if (dryRun || done.empty()) return result;

    // The files first, then the index that names them: an index never points at a file that is not there. A failure says what was
    // written; the index is changed only when every file is in place, by one atomic write of the index read again just before.
    Json written = Json::array();
    for (const CellBake& b : done) {
        auto saved = save_mesh_glb_at(b.mesh, b.file);
        if (!saved.ok()) {
            const std::string code(fs::path_error_code(saved.error()));
            throw CommandError(
                code.empty() ? "write_failed" : code,
                "Cannot write '" + b.file + "': " + saved.error().message + " (" + std::to_string(written.size()) +
                    " proxy files were written; the index is unchanged).",
                saved.error().hint.empty() ? "Check that the folder is writable and the file is not open elsewhere."
                                           : saved.error().hint);
        }
        written.push_back(*saved);
    }
    auto fresh = load_world_index(indexPath, options);
    if (!fresh.ok())
        fail("The index '" + indexPath + "' changed while baking and cannot be read now: " + fresh.error().message +
                 " (" + std::to_string(written.size()) + " proxy files were written; the index is unchanged).",
             fresh.error().hint, "write_failed");
    WorldIndex next = std::move(fresh.value());
    for (const CellBake& b : done) {
        WorldCell* target = nullptr;
        for (WorldCell& c : next.cells)
            if (c.i == b.cell->i && c.j == b.cell->j) target = &c;
        if (!target)
            fail("Cell [" + b.cell->id() + "] is no longer in '" + indexPath + "': the index changed while baking (" +
                     std::to_string(written.size()) + " proxy files were written; the index is unchanged).",
                 "Run world.bake_cell_hlods again.", "write_failed");
        target->hlod = b.file;
        if (setDistance) target->hlodMaxDistance = maxDistance;
    }
    const Json nextJson = world_index_to_json(next);
    {
        auto check = parse_world_index(nextJson, indexPath, options);
        if (!check.ok())
            fail("The index this bake would write is not valid: " + check.error().message, check.error().hint,
                 "internal");
    }
    auto w = fs::write_text(indexWrite, dump_json(nextJson));
    if (!w.ok())
        fail("Cannot write '" + indexPath + "': " + w.error().message + " (" + std::to_string(written.size()) +
                 " proxy files were written; the index is unchanged).",
             w.error().hint, "write_failed");
    result["written"] = written;
    result["indexWritten"] = indexPath;
    return result;
}

}  // namespace

void register_hlod_commands(Engine& engine, Engine::Impl& I) {
    (void)engine;
    I.commands.add(
        {"world.bake_hlod",
         "Bake the HLOD proxy of an entity: one simplified mesh that stands for everything under it.",
         "Merges every active MeshRenderer under the entity's children (under a LodGroup: child 0 only; not the "
         "entity's own) into ONE mesh in the entity's local "
         "space, "
         "keeping the materials as submeshes, simplifies it with the simplifier of model.generate_lods (`ratio` keeps "
         "that "
         "share of the triangles, default 0.1; `maxError` limits how far the surface may move, metres) and writes it "
         "as a "
         ".glb at `out`. With `apply` it also sets LodGroup.hlodProxy (adding the LodGroup) and a default "
         "hlodThreshold "
         "on the entity (refused when it has several children and no LodGroup: they would become LOD levels), one undo "
         "step in the editor. Pass `entity` (of the open scene) or `scene` + `root` (an entity "
         "of "
         "a scene file; no `apply`). Deterministic: the same scene and arguments write the same bytes. Result: {saved, "
         "entity, meshes, trianglesBefore, triangles, vertices, submeshes, error, diameter, skipped, applied, "
         "hlodThreshold?}. Example: world.bake_hlod {\"entity\":\"town_block\",\"out\":\"assets/hlod/town_block.glb\","
         "\"apply\":true}. Details: docs.read BIG_WORLDS_LOD, \"Levels of detail\", the HLOD proxy." FA_COMMAND_DETAILS
         "A LodGroup's children are its levels, so wrap the children of a plain cell in ONE child entity (LOD 0) "
         "before `apply`; "
         "`levelsIgnored` counts the other children of an existing group. The default hlodThreshold, when none is set: "
         "8 times the proxy's size in Distance mode (at least 1.5 times the group's farthest `thresholds` entry), 0.03 "
         "in "
         "ScreenSize mode (at most the smallest entry divided by 1.5), so the proxy never takes over before a child "
         "level; "
         "an existing threshold is kept. Both given, `ratio` and `maxError` give the smaller mesh. Skipped, and listed "
         "in "
         "`skippedList`: inactive entities, MeshRenderers with GPU instances, meshes that cannot be read. Materials "
         "come from "
         "the model files and the primitives' MeshRenderer.color and texture; custom material files, per-entity "
         "overrides "
         "and textures embedded in a .glb are not carried. A scene file is loaded on the side, so its procedural "
         "meshes "
         "do not exist there. Errors: no meshes under the root, `out` that is not a writable project .glb, ratio "
         "outside "
         "(0, 1], `entity` together with `scene`; each names its JSON pointer and nothing is written.",
         parse_schema(R"({"type":"object","required":["out"],"properties":{
               "entity":{"type":"string","description":"Entity id in the open scene: the group whose subtree is merged."},
               "scene":{"type":"string","x-fa-path":"read","description":"Alternative to entity: a project scene file; with `root`."},
               "root":{"type":"string","description":"With scene: the id of the entity of that file to bake."},
               "out":{"type":"string","x-fa-path":"write","description":"Project-relative .glb to write, e.g. assets/hlod/block.glb."},
               "ratio":{"type":"number","exclusiveMinimum":0,"maximum":1,"description":"Share of the triangles to keep (0.1 = a tenth). Default 0.1 when maxError is not given."},
               "maxError":{"type":"number","exclusiveMinimum":0,"description":"The most the simplified surface may move from the merged one, in metres."},
               "apply":{"type":"boolean","default":false,"description":"Also set LodGroup.hlodProxy (and a default hlodThreshold) on `entity`. Not with `scene`."}}})"),
         false, "world"},
        [&I](const Json& a) { return bake_hlod(I, a); });
    I.commands.add({"world.bake_cell_hlods",
                    "Bake the HLOD proxy of every cell of a streamed world and name it in the world index.",
                    "For each cell of the index (or the `cells` you list) loads the cell's scene on the side, merges "
                    "every active MeshRenderer in it "
                    "into ONE mesh in the space of the cell's corner (the cell's minimum corner on the plane, height "
                    "0), simplifies it with the "
                    "simplifier of world.bake_hlod (`ratio`, default 0.1; `maxError`, metres) and writes "
                    "<outDir>/<i>_<j>.glb, then sets "
                    "`hlod.mesh` of those cells in the index (with `hlod.maxDistance` when you pass `maxDistance`), "
                    "one atomic write of the index "
                    "after every file is in place. The streamer draws the proxy while the cell is not loaded and "
                    "StreamedWorld.hlodDistance is above "
                    "0 (docs.read BIG_WORLDS_STREAMING, \"HLOD proxies\"). Example: world.bake_cell_hlods "
                    "{\"world\":\"worlds/town.world.json\",\"maxDistance\":900}." FA_COMMAND_DETAILS
                    "Deterministic: the same scenes and arguments write the same bytes. A cell with no mesh is listed "
                    "in `cellsSkipped` and keeps "
                    "its current proxy. The cell scenes are loaded on the side, so their procedural meshes do not "
                    "exist there and custom material "
                    "files, per-entity overrides and textures embedded in a .glb are not carried (as in "
                    "world.bake_hlod). The index is rewritten in "
                    "its canonical key order. `dryRun` bakes and reports (triangles, errors) without writing a file. A "
                    "cell scene that cannot be "
                    "read or has load errors stops the command before anything is written. Result: {world, outDir, "
                    "baked: [{coord, mesh, meshes, "
                    "trianglesBefore, triangles, vertices, error, skipped}], cellsBaked, cellsSkipped, "
                    "trianglesBefore, triangles, dryRun, "
                    "written, indexWritten?}.",
                    parse_schema(R"({"type":"object","required":["world"],"properties":{
               "world":{"type":"string","x-fa-path":"read","description":"Project-relative world index (<name>.world.json) whose cells are baked; it is rewritten with the hlod entries."},
               "outDir":{"type":"string","x-fa-path":"write","description":"Project folder for the proxy files <i>_<j>.glb. Default: the index path without .world.json plus _hlod (worlds/town_hlod)."},
               "cells":{"type":"array","items":{},"description":"Cells to bake, as [i, j] pairs or {i, j} objects. Default: every cell of the index."},
               "ratio":{"type":"number","exclusiveMinimum":0,"maximum":1,"description":"Share of the triangles to keep (0.1 = a tenth). Default 0.1 when maxError is not given."},
               "maxError":{"type":"number","exclusiveMinimum":0,"description":"The most the simplified surface may move from the merged one, in metres."},
               "maxDistance":{"type":"number","minimum":0,"description":"Sets hlod.maxDistance of the baked cells: the farthest distance from an anchor their proxy is drawn at (0 = StreamedWorld.hlodDistance). Without it the cells keep their current value."},
               "dryRun":{"type":"boolean","default":false,"description":"Bake and report without writing the files or the index."}}})"),
                    false, "world"},
                   [&I](const Json& a) { return bake_cell_hlods(I, a); });
    declare_command_capabilities(I.commands, {{"world.bake_hlod", capability_sets::edits_project()},
                                              {"world.bake_cell_hlods", capability_sets::edits_project()}});
}

}  // namespace fa
