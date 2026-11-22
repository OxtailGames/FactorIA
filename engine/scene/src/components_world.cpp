// The components of the big worlds of M75: reflection (the doc strings are the documentation AIs read) and the validators the
// scene loader calls. The data is in fa/scene/components_world.h; nothing here draws or simulates anything yet.
#include "fa/scene/components_world.h"

#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/reflect.h"
#include "fa/core/strings.h"

namespace fa {

namespace {

std::string num(double v) { return std::format("{:g}", v); }

// Pushes an error or a warning (the arguments after `pointer` are the message and the hint).
void problem(std::vector<WorldProblem>& out, bool error, std::string pointer, std::string message, std::string hint) {
    out.push_back({error, std::move(pointer), std::move(message), std::move(hint)});
}

// The keys of `entry` that are not in `known`, each as a warning with a "did you mean".
void unknown_keys(std::vector<WorldProblem>& out, const Json& entry, const std::string& pointer,
                  const std::vector<std::string>& known, const std::string& what) {
    for (auto it = entry.begin(); it != entry.end(); ++it) {
        if (std::find(known.begin(), known.end(), it.key()) != known.end()) continue;
        problem(out, false, pointer + "/" + it.key(), what + " has an unknown key \"" + it.key() + "\", which is ignored",
                did_you_mean(it.key(), known));
    }
}

// A number in [lo, hi] at `entry[key]`, when it is present; pushes an error when it has another type or is out of range.
void check_number(std::vector<WorldProblem>& out, const Json& entry, const char* key, const std::string& pointer,
                  double lo, double hi, const std::string& what) {
    if (!entry.contains(key)) return;
    const Json& v = entry[key];
    if (!v.is_number()) {
        problem(out, true, pointer + "/" + key, what + " \"" + key + "\" must be a number, got " + describe_json_value(v),
                std::string("Write ") + key + " as a number between " + num(lo) + " and " + num(hi) + ".");
        return;
    }
    const double d = v.get<double>();
    if (!(d >= lo && d <= hi))
        problem(out, true, pointer + "/" + key, what + " \"" + key + "\" is " + num(d) + ", outside " + num(lo) + ".." + num(hi),
                std::string("Use a ") + key + " between " + num(lo) + " and " + num(hi) + ".");
}

void check_path(std::vector<WorldProblem>& out, const Json& entry, const char* key, const std::string& pointer,
                bool required, const std::string& what, const char* example) {
    if (!entry.contains(key)) {
        if (required)
            problem(out, true, pointer, what + " has no \"" + key + "\"", std::string("Add it, for example ") + example + ".");
        return;
    }
    if (!entry[key].is_string())
        problem(out, true, pointer + "/" + key, what + " \"" + key + "\" must be a path string, got " + describe_json_value(entry[key]),
                std::string("Write a project-relative path, for example ") + example + ".");
    else if (required && entry[key].get<std::string>().empty())
        problem(out, true, pointer + "/" + key, what + " \"" + key + "\" is empty",
                std::string("Write a project-relative path, for example ") + example + ".");
}

void check_ordered_pair(std::vector<WorldProblem>& out, const Vec2& v, const char* field, const char* component) {
    if (v.x > v.y)
        problem(out, true, std::string("/") + field,
                std::string(component) + "." + field + " is [" + num(v.x) + ", " + num(v.y) + "], but the minimum is above the maximum",
                "Write [min, max] with min <= max.");
}

}  // namespace

// ---------------------------------------------------------------- validators ----
std::vector<WorldProblem> lod_group_problems(const LodGroup& g) {
    std::vector<WorldProblem> out;
    const bool screen = g.mode == LodMode::ScreenSize;
    if (g.thresholds.size() > std::size_t(kMaxLodThresholds))
        problem(out, true, "/thresholds",
                "LodGroup.thresholds has " + std::to_string(g.thresholds.size()) + " numbers, but a group has at most " +
                    std::to_string(kMaxLodThresholds) + " (so " + std::to_string(kMaxLodThresholds + 1) + " levels)",
                "Merge the last levels, or split the group in two.");
    for (std::size_t i = 0; i < g.thresholds.size(); ++i) {
        const float t = g.thresholds[i];
        const std::string at = "/thresholds/" + std::to_string(i);
        if (!(t > 0.0f)) {
            problem(out, true, at, "LodGroup.thresholds[" + std::to_string(i) + "] is " + num(t) + ", but a threshold is above 0",
                    screen ? "Write the screen fraction 0..1 where the next level takes over, for example 0.3."
                           : "Write the distance in metres where the next level takes over, for example 25.");
            continue;
        }
        if (screen && t > 1.0f)
            problem(out, true, at,
                    "LodGroup.thresholds[" + std::to_string(i) + "] is " + num(t) + " in mode \"screenSize\", where a threshold is a screen fraction 0..1",
                    "Use a fraction such as 0.3 (the level changes when the group covers 30% of the screen's height), or set \"mode\": \"distance\".");
        if (i > 0) {
            const float prev = g.thresholds[i - 1];
            if (screen ? !(t < prev) : !(t > prev))
                problem(out, true, at,
                        "LodGroup.thresholds[" + std::to_string(i) + "] is " + num(t) + ", not " + (screen ? "below " : "above ") +
                            "the one before it (" + num(prev) + ")",
                        screen ? "Screen sizes shrink with each level: write them from the largest to the smallest, for example [0.5, 0.2, 0.05]."
                               : "Distances grow with each level: write them from the nearest to the farthest, for example [15, 40, 90].");
        }
    }
    if (!g.hlodProxy.empty() && !(g.hlodThreshold > 0.0f))
        problem(out, true, "/hlodThreshold", "LodGroup.hlodProxy is \"" + g.hlodProxy + "\" but hlodThreshold is " + num(g.hlodThreshold) + ", so the proxy never takes over",
                screen ? "Set hlodThreshold to the screen fraction 0..1 below which the proxy is drawn, for example 0.02."
                       : "Set hlodThreshold to the distance in metres from which the proxy is drawn, for example 300.");
    else if (g.hlodProxy.empty() && g.hlodThreshold > 0.0f)
        problem(out, false, "/hlodThreshold", "LodGroup.hlodThreshold is " + num(g.hlodThreshold) + " but hlodProxy is empty, so it has no effect",
                "Set hlodProxy to the mesh that stands for the whole group from far away, or set hlodThreshold to 0.");
    if (!g.hlodProxy.empty() && screen && g.hlodThreshold > 1.0f)
        problem(out, true, "/hlodThreshold", "LodGroup.hlodThreshold is " + num(g.hlodThreshold) + " in mode \"screenSize\", where it is a screen fraction 0..1",
                "Use a fraction such as 0.02, or set \"mode\": \"distance\".");
    if (!g.hlodProxy.empty() && !g.thresholds.empty() && g.hlodThreshold > 0.0f) {
        const float last = g.thresholds[g.thresholds.size() - 1];
        if (screen ? !(g.hlodThreshold < last) : !(g.hlodThreshold > last))
            problem(out, false, "/hlodThreshold",
                    "LodGroup.hlodThreshold " + num(g.hlodThreshold) + " is not " + (screen ? "below" : "above") + " the last threshold (" + num(last) +
                        "), so the proxy would replace levels that were never drawn",
                    screen ? "Make hlodThreshold smaller than the last threshold." : "Make hlodThreshold larger than the last threshold.");
    }
    return out;
}

std::vector<WorldProblem> mesh_lod_problems(const std::string& mesh, const Json& lods, LodMode mode, float impostorAt,
                                            const std::string& impostor) {
    (void)mesh;
    std::vector<WorldProblem> out;
    const bool screen = mode == LodMode::ScreenSize;
    if (lods.is_array()) {
        float previous = -1.0f;
        for (std::size_t i = 0; i < lods.size(); ++i) {
            const Json& e = lods[i];
            const std::string at = "/lods/" + std::to_string(i);
            if (!e.is_object()) {
                problem(out, false, at, "MeshRenderer.lods[" + std::to_string(i) + "] is " + describe_json_value(e) + ", not an object, so it is ignored",
                        "Write {\"mesh\": \"assets/lamp.lod1.glb\", \"distance\": 12} (or \"screenSize\": 0.25 with lodMode \"screenSize\").");
                continue;
            }
            const bool hasScreen = e.contains("screenSize"), hasDistance = e.contains("distance");
            if (screen && hasScreen) {
                check_number(out, e, "screenSize", at, 0.0, 1.0, "MeshRenderer.lods[" + std::to_string(i) + "]");
                if (e["screenSize"].is_number()) {
                    const float s = e["screenSize"].get<float>();
                    if (previous >= 0.0f && !(s < previous))
                        problem(out, false, at + "/screenSize",
                                "MeshRenderer.lods[" + std::to_string(i) + "].screenSize " + num(s) + " is not below the entry before it (" + num(previous) + ")",
                                "List the screen sizes from the largest to the smallest: the nearest LOD first.");
                    previous = s;
                }
            } else if (screen && !hasScreen) {
                problem(out, false, at,
                        "MeshRenderer.lodMode is \"screenSize\" but lods[" + std::to_string(i) + "] has no \"screenSize\"" +
                            (hasDistance ? ", so its \"distance\" is not used" : ""),
                        "Write \"screenSize\": 0.25 (a fraction 0..1 of the screen's height), or set lodMode to \"distance\".");
            } else if (!screen && hasScreen && !hasDistance) {
                problem(out, false, at,
                        "MeshRenderer.lods[" + std::to_string(i) + "] has \"screenSize\" but lodMode is \"distance\", so the entry is ignored",
                        "Set \"lodMode\": \"screenSize\", or write \"distance\": 12 (metres) instead.");
            }
            if (hasScreen && !e["screenSize"].is_number() && !screen)
                check_number(out, e, "screenSize", at, 0.0, 1.0, "MeshRenderer.lods[" + std::to_string(i) + "]");
        }
    }
    if (!impostor.empty() && !(impostorAt > 0.0f))
        problem(out, false, "/impostorDistance", "MeshRenderer.impostor is \"" + impostor + "\" but impostorDistance is 0, so the impostor is never drawn",
                screen ? "Set impostorDistance to the screen fraction 0..1 below which the impostor takes over, for example 0.05."
                       : "Set impostorDistance to the distance in metres from which the impostor is drawn, for example 120.");
    else if (impostor.empty() && impostorAt > 0.0f)
        problem(out, false, "/impostorDistance", "MeshRenderer.impostorDistance is " + num(impostorAt) + " but impostor is empty, so it has no effect",
                "Bake one with `model.bake_impostor` and set impostor to its *.impostor.json, or set impostorDistance to 0.");
    if (screen && impostorAt > 1.0f)
        problem(out, true, "/impostorDistance", "MeshRenderer.impostorDistance is " + num(impostorAt) + " in lodMode \"screenSize\", where it is a screen fraction 0..1",
                "Use a fraction such as 0.05, or set lodMode to \"distance\".");
    return out;
}

std::vector<WorldProblem> occluder_problems(const Occluder& o, bool hasMeshRenderer) {
    std::vector<WorldProblem> out;
    if (o.shape == OccluderShape::Box) {
        if (!(o.size.x > 0.0f) || !(o.size.y > 0.0f) || !(o.size.z > 0.0f))
            problem(out, true, "/size", "Occluder.size is [" + num(o.size.x) + ", " + num(o.size.y) + ", " + num(o.size.z) + "], but every side must be above 0",
                    "Write the box in metres, for example \"size\": [10, 6, 0.5] for a wall, or remove the component.");
        if (!o.mesh.empty())
            problem(out, false, "/mesh", "Occluder.mesh is \"" + o.mesh + "\" but shape is \"box\", so the mesh is ignored",
                    "Set \"shape\": \"mesh\" to rasterise the mesh, or remove mesh.");
    } else if (o.mesh.empty() && !hasMeshRenderer) {
        problem(out, true, "/mesh", "Occluder.shape is \"mesh\" but mesh is empty and the entity has no MeshRenderer to take one from",
                "Set mesh to a model path (a low-poly stand-in is best), add a MeshRenderer, or use \"shape\": \"box\".");
    }
    return out;
}

std::vector<WorldProblem> occlusion_area_problems(const OcclusionArea& a) {
    std::vector<WorldProblem> out;
    if (!(a.size.x > 0.0f) || !(a.size.y > 0.0f) || !(a.size.z > 0.0f))
        problem(out, true, "/size", "OcclusionArea.size is [" + num(a.size.x) + ", " + num(a.size.y) + ", " + num(a.size.z) + "], but every side must be above 0",
                "Write the room's box in metres, for example \"size\": [10, 4, 10], or remove the component.");
    return out;
}

std::vector<WorldProblem> occlusion_portal_problems(const OcclusionPortal& p) {
    std::vector<WorldProblem> out;
    if (!(p.size.x > 0.0f) || !(p.size.y > 0.0f) || !(p.size.z > 0.0f))
        problem(out, true, "/size", "OcclusionPortal.size is [" + num(p.size.x) + ", " + num(p.size.y) + ", " + num(p.size.z) + "], but every side must be above 0",
                "Write the opening in metres, for example \"size\": [2, 2.5, 0.2] for a door, or remove the component.");
    if (p.areaA == p.areaB)
        problem(out, false, "/areaB", "OcclusionPortal.areaA and areaB are both " + std::to_string(p.areaA) + ", so the portal connects an area to itself and does nothing",
                "Set areaA and areaB to the areaId of the OcclusionArea on each side (0 = outside every area).");
    return out;
}

std::vector<WorldProblem> streaming_anchor_problems(const StreamingAnchor& a) {
    std::vector<WorldProblem> out;
    if (!(a.unloadRadius > a.loadRadius))
        problem(out, true, "/unloadRadius",
                "StreamingAnchor.unloadRadius is " + num(a.unloadRadius) + ", not above loadRadius (" + num(a.loadRadius) +
                    "), so a cell on the border would load and unload every frame",
                "Keep a margin: unloadRadius at least about 25% above loadRadius, for example loadRadius 256 and unloadRadius 320.");
    return out;
}

std::vector<WorldProblem> terrain_problems(const Terrain3D& t) {
    std::vector<WorldProblem> out;
    if (!(t.size.x > 0.0f) || !(t.size.y > 0.0f))
        problem(out, true, "/size", "Terrain.size is [" + num(t.size.x) + ", " + num(t.size.y) + "], but both sides must be above 0",
                "Write the area in metres, for example \"size\": [512, 512].");
    if (!(t.heightScale > 0.0f) && !t.heightmap.empty())
        problem(out, false, "/heightScale", "Terrain.heightScale is " + num(t.heightScale) + ", so the heightmap " + "\"" + t.heightmap + "\" gives a flat terrain",
                "Set heightScale to the metres of height of a white sample, for example 100.");
    if (!t.splatMaps.is_array()) {
        problem(out, true, "/splatMaps", "Terrain.splatMaps must be an array of image paths, got " + describe_json_value(t.splatMaps),
                "Example: [\"terrain/splat0.png\"]; each RGBA map weights 4 layers.");
    } else {
        if (t.splatMaps.size() > std::size_t(kMaxTerrainSplatMaps))
            problem(out, true, "/splatMaps", "Terrain.splatMaps has " + std::to_string(t.splatMaps.size()) + " maps, but the most is " + std::to_string(kMaxTerrainSplatMaps) + " (8 layers)",
                    "Keep two maps at most; paint fewer layers.");
        for (std::size_t i = 0; i < t.splatMaps.size(); ++i)
            if (!t.splatMaps[i].is_string() || t.splatMaps[i].get<std::string>().empty())
                problem(out, true, "/splatMaps/" + std::to_string(i), "Terrain.splatMaps[" + std::to_string(i) + "] must be an image path, got " + describe_json_value(t.splatMaps[i]),
                        "Write a project-relative RGBA PNG, for example \"terrain/splat0.png\".");
    }
    if (!t.layers.is_array()) {
        problem(out, true, "/layers", "Terrain.layers must be an array of layer objects, got " + describe_json_value(t.layers),
                "Example: [{\"albedo\": \"terrain/grass.png\", \"tileSize\": 4}].");
    } else {
        if (t.layers.size() > std::size_t(kMaxTerrainLayers))
            problem(out, true, "/layers", "Terrain.layers has " + std::to_string(t.layers.size()) + " layers, but the most is " + std::to_string(kMaxTerrainLayers),
                    "Merge layers: a terrain paints up to 8, 4 per splat map.");
        const std::vector<std::string> known = {"albedo", "normal", "tileSize", "roughness", "metallic", "normalScale"};
        for (std::size_t i = 0; i < t.layers.size(); ++i) {
            const Json& l = t.layers[i];
            const std::string at = "/layers/" + std::to_string(i), what = "Terrain.layers[" + std::to_string(i) + "]";
            if (!l.is_object()) {
                problem(out, true, at, what + " must be an object, got " + describe_json_value(l),
                        "Write {\"albedo\": \"terrain/grass.png\", \"tileSize\": 4}.");
                continue;
            }
            check_path(out, l, "albedo", at, true, what, "\"terrain/grass.png\"");
            check_path(out, l, "normal", at, false, what, "\"terrain/grass_n.png\"");
            if (l.contains("tileSize") && l["tileSize"].is_number() && !(l["tileSize"].get<double>() > 0.0))
                problem(out, true, at + "/tileSize", what + " \"tileSize\" is " + num(l["tileSize"].get<double>()) + ", but it is the metres one repeat of the textures covers and must be above 0",
                        "Write for example \"tileSize\": 4 (a texture repeat every 4 metres).");
            else
                check_number(out, l, "tileSize", at, 0.01, 100000.0, what);
            check_number(out, l, "roughness", at, 0.0, 1.0, what);
            check_number(out, l, "metallic", at, 0.0, 1.0, what);
            check_number(out, l, "normalScale", at, 0.0, 4.0, what);
            unknown_keys(out, l, at, known, what);
        }
        if (t.splatMaps.is_array() && !t.splatMaps.empty() && t.layers.size() > 4 * t.splatMaps.size())
            problem(out, false, "/layers", "Terrain.layers has " + std::to_string(t.layers.size()) + " layers but " + std::to_string(t.splatMaps.size()) +
                        " splat map(s) weight only " + std::to_string(4 * t.splatMaps.size()) + ", so the last layers are never painted",
                    "Add a second splat map to Terrain.splatMaps, or remove the extra layers.");
        if (t.splatMaps.is_array() && !t.splatMaps.empty() && t.layers.empty())
            problem(out, false, "/splatMaps", "Terrain.splatMaps is set but layers is empty, so the splat maps weight nothing",
                    "Add the layers the map channels paint: layers[0] is the red channel of the first map, layers[1] the green.");
    }
    return out;
}

std::vector<WorldProblem> foliage_problems(const Foliage& f) {
    std::vector<WorldProblem> out;
    if (f.mesh.empty())
        problem(out, true, "/mesh", "Foliage.mesh is empty, so there is nothing to draw at the instances",
                "Set mesh to a primitive (\"cube\") or a model path such as \"assets/models/grass.glb\".");
    if (!(f.fadeEnd > f.fadeStart))
        problem(out, true, "/fadeEnd", "Foliage.fadeEnd is " + num(f.fadeEnd) + ", not above fadeStart (" + num(f.fadeStart) + ")",
                "Instances fade out between fadeStart and fadeEnd metres, so fadeEnd is the larger, for example 80 and 100.");
    if (f.lodDistance > f.fadeEnd)
        problem(out, false, "/lodDistance", "Foliage.lodDistance " + num(f.lodDistance) + " is beyond fadeEnd (" + num(f.fadeEnd) + "), where the instances are no longer drawn, so the next LOD is never used",
                "Make lodDistance smaller than fadeEnd.");
    return out;
}

std::vector<WorldProblem> scatter_rule_problems(const ScatterRule& r) {
    std::vector<WorldProblem> out;
    if (!r.meshes.is_array()) {
        problem(out, true, "/meshes", "ScatterRule.meshes must be an array, got " + describe_json_value(r.meshes),
                "Example: [{\"mesh\": \"assets/models/pine.glb\", \"weight\": 3}, {\"mesh\": \"assets/models/bush.glb\"}].");
    } else {
        if (r.meshes.empty())
            problem(out, false, "/meshes", "ScatterRule.meshes is empty, so foliage.scatter has nothing to place",
                    "Add at least one {\"mesh\": path, \"weight\": 1}.");
        if (r.meshes.size() > std::size_t(kMaxScatterMeshes))
            problem(out, true, "/meshes", "ScatterRule.meshes has " + std::to_string(r.meshes.size()) + " entries, but the most is " + std::to_string(kMaxScatterMeshes),
                    "Keep the 16 that matter, or use two ScatterRule entities.");
        const std::vector<std::string> known = {"mesh", "weight"};
        for (std::size_t i = 0; i < r.meshes.size(); ++i) {
            const Json& m = r.meshes[i];
            const std::string at = "/meshes/" + std::to_string(i), what = "ScatterRule.meshes[" + std::to_string(i) + "]";
            if (!m.is_object()) {
                problem(out, true, at, what + " must be an object, got " + describe_json_value(m), "Write {\"mesh\": \"assets/models/pine.glb\", \"weight\": 1}.");
                continue;
            }
            check_path(out, m, "mesh", at, true, what, "\"assets/models/pine.glb\"");
            if (m.contains("weight") && m["weight"].is_number() && !(m["weight"].get<double>() > 0.0))
                problem(out, true, at + "/weight", what + " \"weight\" is " + num(m["weight"].get<double>()) + ", but a weight is the relative chance of the mesh and must be above 0",
                        "Write \"weight\": 1, or remove the entry to never use that mesh.");
            else
                check_number(out, m, "weight", at, 0.0, 1000000.0, what);
            unknown_keys(out, m, at, known, what);
        }
    }
    check_ordered_pair(out, r.slopeRange, "slopeRange", "ScatterRule");
    check_ordered_pair(out, r.heightRange, "heightRange", "ScatterRule");
    check_ordered_pair(out, r.scaleRange, "scaleRange", "ScatterRule");
    if (!(r.scaleRange.x > 0.0f))
        problem(out, true, "/scaleRange", "ScatterRule.scaleRange starts at " + num(r.scaleRange.x) + ", but a scale must be above 0",
                "Write [min, max] above 0, for example [0.8, 1.2].");
    return out;
}

// ------------------------------------------------------------- reflection ----
void register_world_components(TypeRegistry& r) {
    r.add<LodGroup>(
         "LodGroup",
         "The levels of detail of a model made of several meshes, and the far-away stand-in of a whole area. The "
         "entity's CHILDREN are the levels: child 0 is the most detailed and child i + 1 replaces child i from "
         "thresholds[i] on; only the child of the current level is drawn. With hlodProxy set, the whole group is drawn "
         "as that one mesh beyond hlodThreshold (a hierarchical LOD: one draw for a cell of a streamed world). The "
         "units of every threshold are set by `mode`. No effect yet: M75.1 draws it (docs/BIG_WORLDS.md, \"Levels of detail\"); the "
         "fields are saved and checked today.",
         "3D")
        .enum_field("mode", &LodGroup::mode, {"distance", "screenSize"},
                    "What thresholds and hlodThreshold measure. distance (default): metres between the camera and the "
                    "entity's origin. screenSize: the fraction 0..1 of the screen's height that the group's bounding "
                    "sphere covers (1 = it fills the screen); it does not depend on the field of view or on the size "
                    "of the object.")
        .field("thresholds", &LodGroup::thresholds,
               "One number for each child but the first: thresholds[i] is where child i + 1 replaces child i. In mode "
               "distance they grow (metres, nearest first: [15, 40, 90]); in mode screenSize they shrink (fractions "
               "0..1: [0.5, 0.2, 0.05]). At most 8 numbers, each above 0. Fewer numbers than children leave the "
               "last children unused. [] (default) = the first child is always drawn.")
        .range(0, 100000)
        .field("crossFade", &LodGroup::crossFade,
               "Seconds a switch between two levels fades over (a dithered cross-fade, no pop). 0 (default) = a hard "
               "switch. 0..5.")
        .range(0, 5)
        .asset_field("hlodProxy", &LodGroup::hlodProxy, "mesh",
                     "Project-relative path of the one mesh (a baked low-poly merge of the group) drawn instead of "
                     "every child beyond hlodThreshold. \"\" (default) = no proxy. The children stop being drawn "
                     "and their draw calls with them.")
        .field("hlodThreshold", &LodGroup::hlodThreshold,
               "Where the proxy takes over, in the unit of `mode`: metres from the camera in mode distance, a screen "
               "fraction 0..1 below which the proxy is drawn in mode screenSize. Beyond the last threshold. Needs "
               "hlodProxy; 0 (default) with a proxy is an error.")
        .range(0, 100000);

    r.add<Occluder>(
         "Occluder",
         "A solid that hides what is behind it from the camera, for the occlusion culling of dense scenes (a wall, a "
         "hill, the body of a building): the renderer rasterises it into a small depth buffer and does not draw the "
         "objects that the depth proves hidden. A cheap box is best; a mesh costs more. It hides, it is not drawn: "
         "give the entity a MeshRenderer to see it. No effect yet: M75.2 builds the culling (docs/BIG_WORLDS.md, "
         "\"Occlusion\"); the fields are saved and checked today.",
         "3D")
        .enum_field("shape", &Occluder::shape, {"box", "mesh"},
                    "box (default): the box `size` and `center`. mesh: the triangles of `mesh` (or of the entity's "
                    "MeshRenderer.mesh when `mesh` is empty); keep it low-poly, under about 200 triangles.")
        .field("size", &Occluder::size,
               "Box shape: metres along the entity's local axes before Transform.scale, each above 0. Default [1, 1, "
               "1]. Make it a little smaller than the visible solid, so nothing visible is ever hidden.")
        .range(0, 100000)
        .field("center", &Occluder::center,
               "Box shape: where the box's centre is, in metres from the entity's origin along its local axes. "
               "Default [0, 0, 0].")
        .range(-100000, 100000)
        .asset_field("mesh", &Occluder::mesh, "mesh",
                     "Mesh shape: the mesh that is rasterised, a primitive name or a model path. \"\" (default) = the "
                     "entity's MeshRenderer.mesh. Ignored by the box shape.")
        .field("enabled", &Occluder::enabled, "false = this occluder hides nothing. Default true.");

    r.add<OcclusionArea>(
         "OcclusionArea",
         "A room of an interior, for portal culling: the objects inside this box are drawn only when the camera is in "
         "the same area, or when a chain of open OcclusionPortal entities leads from the camera's area to it. Outside "
         "every area (areaId 0) everything is drawn as usual. No effect yet: M75.2 builds it (docs/BIG_WORLDS.md, "
         "\"Occlusion\").",
         "3D")
        .field("size", &OcclusionArea::size,
               "Metres along the entity's local axes before Transform.scale, each above 0. Default [10, 4, 10].")
        .range(0, 100000)
        .field("areaId", &OcclusionArea::areaId,
               "1..65535: the id that OcclusionPortal.areaA and areaB name. Two areas of one scene must not share "
               "an id. Default 1.")
        .range(1, 65535);

    r.add<OcclusionPortal>(
         "OcclusionPortal",
         "An opening between two OcclusionArea rooms (a door, a window, an archway): what is seen through it from "
         "the first room is drawn in the second. The opening is a box of `size` centred on the entity; its -Z side "
         "faces areaA and its +Z side areaB. A portal with open false (a shut door) lets nothing through. No effect "
         "yet: M75.2 builds it (docs/BIG_WORLDS.md, \"Occlusion\").",
         "3D")
        .field("size", &OcclusionPortal::size,
               "Metres along the entity's local axes before Transform.scale: width, height and depth of the opening's "
               "box, each above 0. Default [2, 2, 0.2].")
        .range(0, 100000)
        .field("areaA", &OcclusionPortal::areaA,
               "The OcclusionArea.areaId on the entity's -Z side; 0 (default) = outside every area.")
        .range(0, 65535)
        .field("areaB", &OcclusionPortal::areaB,
               "The OcclusionArea.areaId on the entity's +Z side; 0 (default) = outside every area. A portal with "
               "areaA equal to areaB does nothing.")
        .range(0, 65535)
        .field("open", &OcclusionPortal::open,
               "true (default) = the portal lets the view through. false = shut (a closed door): the areas behind it "
               "are hidden. A script opens and closes it at run time.");

    r.add<StreamingAnchor>(
         "StreamingAnchor",
         "Makes the world around this entity load and unload as it moves: a streamed scene is cut into cells (the "
         "`world.cells` command lists them), and the cells nearer than loadRadius to any enabled anchor are loaded, "
         "those farther than unloadRadius from all of them are unloaded. Put it on the player or on the camera. A "
         "scene with no anchor loads every cell. No effect yet: M75.3 builds the streaming (docs/BIG_WORLDS.md, "
         "\"Streaming\").",
         "World")
        .field("loadRadius", &StreamingAnchor::loadRadius,
               "Metres: a cell whose bounds are nearer than this to the anchor (on the ground plane, x and z) is "
               "loaded. 1..1000000. Default 256.")
        .range(1, 1000000)
        .field("unloadRadius", &StreamingAnchor::unloadRadius,
               "Metres: a loaded cell whose bounds are farther than this from every anchor is unloaded. Must be above "
               "loadRadius (the gap keeps a cell on the border from flickering). 1..1000000. Default 320.")
        .range(1, 1000000)
        .field("priority", &StreamingAnchor::priority,
               "-100..100: when two anchors want cells loaded, the anchor with the higher priority gets its cells "
               "first. Default 0.")
        .range(-100, 100)
        .field("enabled", &StreamingAnchor::enabled, "false = this anchor loads nothing and keeps nothing loaded.");

    r.add<Terrain3D>(
         "Terrain",
         "A large landscape: a heightmap drawn as a mesh that coarsens with distance, painted with up to 8 material "
         "layers weighted by splat maps, with holes (caves, wells) and an automatic collider. It covers `size` metres "
         "centred on the entity. `terrain.create` makes one with its files, `terrain.sculpt`, `terrain.paint` and "
         "`terrain.holes` edit them. No effect yet: M75.5 draws it (docs/BIG_WORLDS.md, \"Terrain\"); the fields are "
         "saved and checked today.",
         "3D")
        .asset_field("heightmap", &Terrain3D::heightmap, "any",
                     "Project-relative 16-bit greyscale PNG or .r16 file (raw little-endian 16-bit): black is the "
                     "lowest sample, white (65535) is heightScale metres higher. \"\" (default) = a flat terrain at "
                     "heightOffset.")
        .field("size", &Terrain3D::size,
               "[x, z] metres the heightmap covers, centred on the entity, before Transform.scale; each above 0 and "
               "at most 100000. Default [512, 512].")
        .range(0, kMaxTerrainSize)
        .field("heightScale", &Terrain3D::heightScale,
               "Metres of height of a white heightmap sample, 0..100000. Default 100.")
        .range(0, 100000)
        .field("heightOffset", &Terrain3D::heightOffset,
               "Metres added to every height after the scale (the height of a black sample), -100000..100000. "
               "Default 0.")
        .range(-100000, 100000)
        .field("splatMaps", &Terrain3D::splatMaps,
               "Array of at most 2 project-relative RGBA PNG paths, each the size of the terrain's paint: channel c "
               "(r, g, b, a) of map m weights layers[4 * m + c]. [] (default) = no painting, layer 0 covers the whole "
               "terrain.")
        .field("layers", &Terrain3D::layers,
               "Array of at most 8 material layers: {\"albedo\": \"terrain/grass.png\", \"normal\": "
               "\"terrain/grass_n.png\", \"tileSize\": 4, \"roughness\": 0.9, \"metallic\": 0, \"normalScale\": 1}. "
               "`albedo` (required) and `normal` are project-relative textures; `tileSize` is the metres one repeat of "
               "the textures covers (default 4, above 0); roughness and metallic 0..1 (defaults 0.9 and 0); "
               "normalScale 0..4 (default 1). [] (default) = a plain grey terrain.")
        .asset_field("holes", &Terrain3D::holes, "texture",
                     "Project-relative greyscale PNG the size of the terrain's paint: where a pixel is 128 or more the "
                     "terrain is cut open (no surface, no collider): a cave mouth, a well. \"\" (default) = no holes.")
        .field("lodQuality", &Terrain3D::lodQuality,
               "Multiplier of the mesh density and of the distances where the terrain coarsens: 2 = twice as dense and "
               "coarsening twice as far, 0.5 = half. 0.1..4. Default 1.")
        .range(0.1f, 4)
        .field("castShadows", &Terrain3D::castShadows, "Cast shadows from shadow-casting lights. Default true.")
        .field("collision", &Terrain3D::collision,
               "true (default) = the terrain is a static physics body: it follows the heightmap and its holes. false "
               "= visual only.");

    r.add<Foliage>(
         "Foliage",
         "Thousands of copies of one mesh (grass, trees, rocks) drawn with GPU instancing from a data file of "
         "positions, rotations and scales, with wind, a fade-out and LODs. `foliage.paint` and `foliage.scatter` "
         "write the file, `foliage.clear` empties it. One entity holds one mesh: use several for several kinds. No "
         "effect yet: M75.6 draws it (docs/BIG_WORLDS.md, \"Foliage\"); the fields are saved and checked today.",
         "3D")
        .asset_field("mesh", &Foliage::mesh, "mesh",
                     "The mesh drawn at every instance: a primitive name or a model path (its LODs are used). Default "
                     "\"cube\".")
        .asset_field("instances", &Foliage::instances, "any",
                     "Project-relative data file with the instances; `foliage.paint` and `foliage.scatter` create and "
                     "write it. \"\" (default) = no instances, nothing drawn.")
        .field("density", &Foliage::density,
               "0..1: the share of the instances that are drawn, thinned out evenly (a quality setting: 0.5 draws "
               "every second instance). Default 1.")
        .range(0, 1)
        .field("windStrength", &Foliage::windStrength,
               "Metres the top of an instance sways in the wind, 0..10; the base stays put. 0 (default) = no wind.")
        .range(0, 10)
        .field("windFrequency", &Foliage::windFrequency, "Swings per second of the wind sway, 0..20. Default 0.5.")
        .range(0, 20)
        .field("lodDistance", &Foliage::lodDistance,
               "Metres from the camera beyond which an instance uses the next LOD of its mesh (a model with LODs). "
               "0.1..100000. Default 40.")
        .range(0.1f, 100000)
        .field("fadeStart", &Foliage::fadeStart,
               "Metres from the camera where instances start to fade out (a dithered fade), 0..100000. Default 80.")
        .range(0, 100000)
        .field("fadeEnd", &Foliage::fadeEnd,
               "Metres from the camera beyond which instances are not drawn at all; above fadeStart. 0..100000. "
               "Default 100.")
        .range(0, 100000)
        .field("castShadows", &Foliage::castShadows,
               "Whether the instances cast shadows. false (default): grass seldom needs them and they cost a lot.");

    r.add<ScatterRule>(
         "ScatterRule",
         "The recipe `foliage.scatter` follows to fill the Foliage of this entity (or of the entity named by "
         "`terrain`'s) with instances: which meshes, how dense, on which slopes, heights and painted layers. The "
         "result depends only on the rule, the seed and the terrain, so the same rule scatters the same instances. "
         "The rule does nothing by itself; the command runs it. No effect yet: M75.6 builds it (docs/BIG_WORLDS.md, "
         "\"Foliage\").",
         "3D")
        .field("meshes", &ScatterRule::meshes,
               "Array of at most 16 {\"mesh\": path, \"weight\": number}: the meshes to scatter and their relative "
               "chances (weight above 0, default 1). The path is a primitive name or a model path. [] (default) = "
               "nothing to scatter.")
        .field("density", &ScatterRule::density,
               "Instances per square metre of ground, 0..100. Default 0.1 (one per 10 square metres).")
        .range(0, 100)
        .field("minSpacing", &ScatterRule::minSpacing,
               "Metres kept between two instances (a tree's crown); 0 (default) = they may touch. 0..1000.")
        .range(0, 1000)
        .field("slopeRange", &ScatterRule::slopeRange,
               "[min, max] degrees of the ground's slope where instances grow (0 is flat, 90 a wall), 0..90, min at "
               "most max. Default [0, 45].")
        .range(0, 90)
        .field("heightRange", &ScatterRule::heightRange,
               "[min, max] metres of the ground's height (world y) where instances grow, min at most max. Default "
               "[-100000, 100000] (everywhere).")
        .range(-100000, 100000)
        .field("scaleRange", &ScatterRule::scaleRange,
               "[min, max] of the random uniform scale of an instance, each above 0, min at most max. Default [0.8, "
               "1.2].")
        .range(0, 1000)
        .field("alignToNormal", &ScatterRule::alignToNormal,
               "0..1: how far an instance leans to the ground's normal. 0 (default) = upright, 1 = its up is the "
               "normal (moss on a cliff).")
        .range(0, 1)
        .field("layerMask", &ScatterRule::layerMask,
               "Bit mask of the Terrain.layers the ground must be painted with for an instance to grow (bit 0 = layer "
               "0 ... bit 7 = layer 7); -1 (default) = anywhere. -1..255.")
        .range(-1, 255)
        .field("seed", &ScatterRule::seed, "The random seed: the same rule and seed give the same instances. Default 1.")
        .field("terrain", &ScatterRule::terrain,
               "The entity with the Terrain to scatter on. Empty (default) = this entity's Terrain, or its parent's.");
}

}  // namespace fa
