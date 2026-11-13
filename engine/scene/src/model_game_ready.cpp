// Game-ready models (model_game_ready.h): the settings of a document, origin, merge, LODs, the budget report. The collider is model_collider.cpp.
#include "fa/scene/model_game_ready.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <format>
#include <map>

#include "fa/core/strings.h"
#include "fa/scene/model_decimate.h"
#include "meshoptimizer.h"

namespace fa {

namespace {

const std::vector<std::string>& origin_names() {
    static const std::vector<std::string> v = {"keep", "center", "bottom", "bottom_center"};
    return v;
}
const std::vector<std::string>& shape_names() {
    static const std::vector<std::string> v = {"none", "box", "sphere", "capsule", "convex", "decomposed"};
    return v;
}

struct Reader {
    std::vector<ModelIssue>& issues;
    void err(const std::string& pointer, const std::string& message, const std::string& hint) {
        issues.push_back({pointer, message, hint});
    }
};

bool read_number(Reader& r, const Json& obj, const std::string& at, const char* key, double lo, double hi, bool integer,
                 double& out, const char* hint) {
    auto it = obj.find(key);
    if (it == obj.end()) return false;
    const std::string where = at + "/" + key;
    if (!it->is_number() || (integer && !it->is_number_integer())) {
        r.err(where,
              std::string(key) + " must be " + (integer ? "a whole number" : "a number") + ", got " +
                  describe_json_value(*it),
              hint);
        return false;
    }
    const double v = it->get<double>();
    if (!(v >= lo && v <= hi)) {
        r.err(where, std::format("{} must be between {} and {}, got {}", key, lo, hi, v), hint);
        return false;
    }
    out = v;
    return true;
}

void unknown_keys(Reader& r, const Json& obj, const std::string& at, const std::vector<std::string>& known) {
    for (auto it = obj.begin(); it != obj.end(); ++it)
        if (std::find(known.begin(), known.end(), it.key()) == known.end())
            r.err(at + "/" + it.key(), "\"" + it.key() + "\" is not a field here", did_you_mean(it.key(), known));
}

bool same_material(const MeshMaterial& a, const MeshMaterial& b) {
    return a.name == b.name && a.color.r == b.color.r && a.color.g == b.color.g && a.color.b == b.color.b &&
           a.color.a == b.color.a && a.texture == b.texture && a.metallic == b.metallic && a.roughness == b.roughness &&
           a.emissive.r == b.emissive.r && a.emissive.g == b.emissive.g && a.emissive.b == b.emissive.b &&
           a.doubleSided == b.doubleSided && a.blend == b.blend;
}

// The triangles of a mesh that are drawn, with the submesh each belongs to.
struct Drawn {
    std::vector<std::uint32_t> indices, sub;
};
Drawn drawn_triangles(const MeshData& m) {
    Drawn d;
    for (std::size_t s = 0; s < m.submeshes.size(); ++s) {
        const MeshSubmesh& sm = m.submeshes[s];
        const std::size_t end = std::min<std::size_t>(std::size_t(sm.start) + sm.count, m.indices.size());
        for (std::size_t i = sm.start; i + 2 < end + 0 && i + 3 <= end; i += 3) {
            for (int k = 0; k < 3; ++k) d.indices.push_back(m.indices[i + std::size_t(k)]);
            d.sub.push_back(std::uint32_t(s));
        }
    }
    return d;
}

// A MeshInput for a vertex set and triangles grouped by submesh (ascending). `sub` per triangle; submeshes without triangles are left out.
Result<MeshData> assemble(const MeshData& like, std::vector<float> positions, std::vector<float> normals,
                          std::vector<float> uvs, std::vector<float> colors, const std::vector<std::uint32_t>& indices,
                          const std::vector<std::uint32_t>& sub, const std::vector<std::string>* partNames) {
    MeshInput in;
    in.positions = std::move(positions);
    in.normals = std::move(normals);
    if (like.hasUvs) in.uvs = std::move(uvs);
    in.colors = std::move(colors);
    in.indices = indices;
    in.hasIndices = true;
    std::size_t t = 0;
    while (t < sub.size()) {
        std::size_t e = t;
        while (e < sub.size() && sub[e] == sub[t]) ++e;
        MeshSubmesh s = like.submeshes[sub[t]];
        if (partNames) s.part = (*partNames)[sub[t]];
        s.start = std::uint32_t(t * 3);
        s.count = std::uint32_t((e - t) * 3);
        in.submeshes.push_back(s);
        t = e;
    }
    if (in.submeshes.empty())
        return make_error("the mesh has no triangles left", "Check the settings that removed them.");
    return build_mesh_data(in);
}

double largest_dimension(const MeshData& m) {
    const Vec3 s = m.bmax - m.bmin;
    return std::max({double(s.x), double(s.y), double(s.z)});
}

}  // namespace

// ---- settings ----------------------------------------------------------------------------------------------------------------

bool ModelGameReady::is_default() const {
    return origin == "keep" && !merge && lods.empty() && collider.shape == "none";
}

Result<ModelGameReady> parse_game_ready(const Json& json, const std::string& at, std::vector<ModelIssue>* issuesOut) {
    std::vector<ModelIssue> local;
    std::vector<ModelIssue>& issues = issuesOut ? *issuesOut : local;
    const std::size_t before = issues.size();
    Reader r{issues};
    ModelGameReady g;
    if (!json.is_object()) {
        r.err(at, "gameReady must be an object, got " + describe_json_value(json),
              "Example: {\"origin\": \"bottom_center\", \"merge\": true, \"lods\": [{\"ratio\": 0.5}], \"collider\": "
              "{\"shape\": \"convex\"}}.");
    } else {
        unknown_keys(r, json, at, {"origin", "merge", "lods", "collider", "platforms"});
        if (auto it = json.find("origin"); it != json.end()) {
            if (!it->is_string() ||
                std::find(origin_names().begin(), origin_names().end(), it->get<std::string>()) == origin_names().end())
                r.err(at + "/origin",
                      "origin must be one of " + join(origin_names(), ", ") + ", got " + describe_json_value(*it),
                      it->is_string()
                          ? did_you_mean(it->get<std::string>(), origin_names())
                          : "\"bottom_center\" puts the lowest point at y = 0 and the middle at x = z = 0.");
            else
                g.origin = it->get<std::string>();
        }
        if (auto it = json.find("merge"); it != json.end()) {
            if (!it->is_boolean())
                r.err(at + "/merge", "merge must be true or false, got " + describe_json_value(*it),
                      "true joins the submeshes that share a material.");
            else
                g.merge = it->get<bool>();
        }
        if (auto it = json.find("lods"); it != json.end()) {
            if (!it->is_array() || it->size() > kGameReadyMaxLods)
                r.err(at + "/lods",
                      std::format("lods must be a list of at most {} levels, got {}", kGameReadyMaxLods,
                                  describe_json_value(*it)),
                      "Each level is {\"ratio\": 0.5} (a fraction of the triangles), {\"triangles\": 800} or "
                      "{\"error\": 0.02} (metres); the first is LOD1.");
            else
                for (std::size_t i = 0; i < it->size(); ++i) {
                    const Json& l = (*it)[i];
                    const std::string lat = at + "/lods/" + std::to_string(i);
                    if (!l.is_object()) {
                        r.err(lat, "a LOD must be an object, got " + describe_json_value(l),
                              "Example: {\"ratio\": 0.5}.");
                        continue;
                    }
                    unknown_keys(r, l, lat, {"ratio", "triangles", "error", "distance"});
                    ModelLodSpec s;
                    double v = 0;
                    if (read_number(r, l, lat, "ratio", 0.001, 1.0, false, v,
                                    "A fraction of the full mesh's triangles, e.g. 0.5."))
                        s.ratio = v;
                    if (read_number(r, l, lat, "triangles", 1, 10000000, true, v, "A triangle count, e.g. 800."))
                        s.triangles = std::size_t(v);
                    if (read_number(r, l, lat, "error", 0.000001, 1000, false, v,
                                    "Metres the surface may move, e.g. 0.02."))
                        s.error = v;
                    if (read_number(r, l, lat, "distance", 0.01, 100000, false, v,
                                    "Camera distance in metres from which the game draws this LOD, e.g. 15."))
                        s.distance = v;
                    if (s.ratio == 0 && s.triangles == 0 && s.error == 0)
                        r.err(lat, "a LOD must say how far to reduce: give ratio, triangles or error",
                              "Example: {\"ratio\": 0.5}.");
                    if (!g.lods.empty() && s.distance > 0 && g.lods.back().distance > 0 &&
                        s.distance <= g.lods.back().distance)
                        r.err(lat + "/distance", "distances must grow from one LOD to the next",
                              "Each LOD takes over farther away than the one before.");
                    g.lods.push_back(s);
                }
        }
        if (auto it = json.find("collider"); it != json.end()) {
            const std::string cat = at + "/collider";
            if (!it->is_object())
                r.err(cat, "collider must be an object, got " + describe_json_value(*it),
                      "Example: {\"shape\": \"convex\", \"maxVertices\": 32}.");
            else {
                unknown_keys(r, *it, cat,
                             {"shape", "maxHulls", "maxVertices", "resolution", "part", "radius", "height"});
                if (auto s = it->find("shape"); s != it->end()) {
                    if (!s->is_string() || std::find(shape_names().begin(), shape_names().end(),
                                                     s->get<std::string>()) == shape_names().end())
                        r.err(cat + "/shape",
                              "shape must be one of " + join(shape_names(), ", ") + ", got " + describe_json_value(*s),
                              s->is_string() ? did_you_mean(s->get<std::string>(), shape_names())
                                             : "\"decomposed\" splits a concave model into convex pieces.");
                    else
                        g.collider.shape = s->get<std::string>();
                }
                double v = 0;
                if (read_number(r, *it, cat, "maxHulls", 1, 64, true, v,
                                "How many convex pieces a decomposition may use, 1..64."))
                    g.collider.maxHulls = int(v);
                if (read_number(r, *it, cat, "maxVertices", 4, kGameReadyMaxHullVertices, true, v,
                                "Points per hull, 4..256 (the physics takes at most 256)."))
                    g.collider.maxVertices = int(v);
                if (read_number(r, *it, cat, "resolution", 10000, 4000000, true, v,
                                "Voxels the decomposition splits the volume into, 10000..4000000."))
                    g.collider.resolution = int(v);
                if (auto p = it->find("part"); p != it->end()) {
                    if (!p->is_string() || p->get<std::string>().empty())
                        r.err(cat + "/part",
                              "part must be the name of a part of the model, got " + describe_json_value(*p),
                              "Example: \"trunk\". model.info lists the parts.");
                    else
                        g.collider.part = p->get<std::string>();
                }
                if (read_number(r, *it, cat, "radius", 0.001, 10000, false, v, "The radius in metres, e.g. 0.35."))
                    g.collider.radius = v;
                if (read_number(r, *it, cat, "height", 0.001, 10000, false, v,
                                "The total height in metres (caps included), e.g. 4."))
                    g.collider.height = v;
                if (g.collider.radius > 0 && g.collider.shape != "sphere" && g.collider.shape != "capsule")
                    r.err(cat + "/radius",
                          "radius only applies to a sphere or capsule collider, not '" + g.collider.shape + "'",
                          "Set shape to \"sphere\" or \"capsule\", or remove radius.");
                if (g.collider.height > 0 && g.collider.shape != "capsule")
                    r.err(cat + "/height", "height only applies to a capsule collider, not '" + g.collider.shape + "'",
                          "Set shape to \"capsule\", or remove height.");
            }
        }
        if (auto it = json.find("platforms"); it != json.end()) {
            std::vector<std::string> names;
            for (const ModelPlatformBudget& b : model_platform_budgets()) names.push_back(b.platform);
            if (!it->is_array() || it->empty())
                r.err(at + "/platforms",
                      "platforms must be a non-empty list of " + join(names, ", ") + ", got " +
                          describe_json_value(*it),
                      "Example: [\"desktop\", \"mobile\"].");
            else {
                g.platforms.clear();
                for (std::size_t i = 0; i < it->size(); ++i) {
                    const Json& p = (*it)[i];
                    if (!p.is_string() || std::find(names.begin(), names.end(), p.get<std::string>()) == names.end())
                        r.err(at + "/platforms/" + std::to_string(i), "unknown platform " + describe_json_value(p),
                              p.is_string() ? did_you_mean(p.get<std::string>(), names)
                                            : "Use " + join(names, ", ") + ".");
                    else if (std::find(g.platforms.begin(), g.platforms.end(), p.get<std::string>()) ==
                             g.platforms.end())
                        g.platforms.push_back(p.get<std::string>());
                }
            }
        }
    }
    if (issues.size() > before) {
        const ModelIssue& first = issues[before];
        return make_error(first.pointer + ": " + first.message, first.hint);
    }
    return g;
}

Json game_ready_to_json(const ModelGameReady& g) {
    Json lods = Json::array();
    for (const ModelLodSpec& l : g.lods) {
        Json o = Json::object();
        if (l.ratio > 0) o["ratio"] = l.ratio;
        if (l.triangles > 0) o["triangles"] = l.triangles;
        if (l.error > 0) o["error"] = l.error;
        if (l.distance > 0) o["distance"] = l.distance;
        lods.push_back(o);
    }
    Json collider = Json::object({{"shape", g.collider.shape},
                                  {"maxHulls", g.collider.maxHulls},
                                  {"maxVertices", g.collider.maxVertices},
                                  {"resolution", g.collider.resolution}});
    if (!g.collider.part.empty()) collider["part"] = g.collider.part;
    if (g.collider.radius > 0) collider["radius"] = g.collider.radius;
    if (g.collider.height > 0) collider["height"] = g.collider.height;
    return Json::object(
        {{"origin", g.origin}, {"merge", g.merge}, {"lods", lods}, {"collider", collider}, {"platforms", g.platforms}});
}

Json game_ready_schema() {
    auto num = [](const char* type, double lo, double hi, const char* doc) {
        return Json::object({{"type", type}, {"minimum", lo}, {"maximum", hi}, {"description", doc}});
    };
    Json lod = Json::object(
        {{"type", "object"},
         {"additionalProperties", false},
         {"description", "One lower-detail copy of the mesh. Give ratio, triangles or error (or several: the first "
                         "limit reached stops the reduction)."},
         {"properties",
          Json::object(
              {{"ratio", num("number", 0.001, 1, "Keep this fraction of the full mesh's triangles (0.5 = half).")},
               {"triangles", num("integer", 1, 10000000, "Keep at most this many triangles.")},
               {"error", num("number", 0.000001, 1000, "The most any collapse may move the surface, in metres.")},
               {"distance", num("number", 0.01, 100000,
                                "Camera distance in metres from which the game draws this LOD. Left out: the model's "
                                "largest dimension times 4, 8, 16, 32 for LOD1..4.")}})}});
    return Json::object(
        {{"type", "object"},
         {"additionalProperties", false},
         {"description", "What `model.bake` derives besides the .glb: the origin, merged submeshes, LOD files "
                         "(<name>.lodN.glb), a collider (<name>.collider.glb for hulls) and <name>.prefab.json that "
                         "wires them. Works on `sdf` results too."},
         {"properties",
          Json::object(
              {{"origin", Json::object({{"enum", origin_names()},
                                        {"default", "keep"},
                                        {"description", "Where the model's origin goes: keep, center (middle of the "
                                                        "box), bottom (lowest point at y = 0) or bottom_center."}})},
               {"merge",
                Json::object({{"type", "boolean"},
                              {"default", false},
                              {"description", "Join the submeshes that share a material (fewer draw calls) and weld "
                                              "identical vertices. The parts of the .glb are then joined too."}})},
               {"lods", Json::object({{"type", "array"},
                                      {"maxItems", int(kGameReadyMaxLods)},
                                      {"items", lod},
                                      {"description", "LOD1, LOD2... in order, each simpler than the last. Every "
                                                      "submesh keeps its borders, so parts do not come apart."}})},
               {"collider",
                Json::object(
                    {{"type", "object"},
                     {"additionalProperties", false},
                     {"description", "The collider fitted to the mesh. box, sphere and capsule are primitives of "
                                     "Collider3D; convex is the hull of the mesh; decomposed is several convex pieces "
                                     "for a concave model (static colliders)."},
                     {"properties",
                      Json::object(
                          {{"shape",
                            Json::object({{"enum", shape_names()},
                                          {"default", "none"},
                                          {"description", "none, box, sphere, capsule, convex or decomposed."}})},
                           {"maxHulls",
                            num("integer", 1, 64, "decomposed: at most this many convex pieces. Default 8.")},
                           {"maxVertices", num("integer", 4, kGameReadyMaxHullVertices,
                                               "convex, decomposed: at most this many points per hull. Default 32.")},
                           {"resolution", num("integer", 10000, 4000000,
                                              "decomposed: voxels the volume is split into. Default 100000.")},
                           {"part",
                            Json::object(
                                {{"type", "string"},
                                 {"description",
                                  "Fit the collider to this part of the model only (the `part` of a node, e.g. a "
                                  "pine's \"trunk\" so the canopy does not block). Default: the whole model."}})},
                           {"radius", num("number", 0.001, 10000,
                                          "sphere, capsule: this radius in metres instead of the fitted one.")},
                           {"height", num("number", 0.001, 10000,
                                          "capsule: this total height in metres (caps included) instead of the fitted "
                                          "one.")}})}})},
               {"platforms",
                Json::object(
                    {{"type", "array"},
                     {"items", Json::object({{"enum", Json::array({"desktop", "mobile", "web"})}})},
                     {"description",
                      "The platforms whose triangle and draw-call budget the report checks. Default all."}})}})}});
}

// ---- budgets -----------------------------------------------------------------------------------------------------------------

const std::vector<ModelPlatformBudget>& model_platform_budgets() {
    static const std::vector<ModelPlatformBudget> v = {
        {"desktop", 100000, 16, "A hero object on a desktop GPU."},
        {"mobile", 20000, 8, "A phone or tablet: tile GPUs pay for every triangle and draw call."},
        {"web", 40000, 10, "A browser tab: WebGL2 and a shared GPU."}};
    return v;
}

// ---- origin and ground -------------------------------------------------------------------------------------------------------

Vec3 model_origin_offset(const MeshData& m, const std::string& origin) {
    if (m.positions.empty() || origin == "keep") return {};
    Vec3 lo{m.positions[0], m.positions[1], m.positions[2]}, hi = lo;
    for (std::size_t i = 0; i + 2 < m.positions.size(); i += 3) {
        const Vec3 p{m.positions[i], m.positions[i + 1], m.positions[i + 2]};
        lo = min(lo, p);
        hi = max(hi, p);
    }
    const Vec3 c = (lo + hi) * 0.5f;
    if (origin == "center") return {-c.x, -c.y, -c.z};
    if (origin == "bottom") return {0, -lo.y, 0};
    if (origin == "bottom_center") return {-c.x, -lo.y, -c.z};
    return {};
}

MeshData model_translated(const MeshData& m, Vec3 offset) {
    MeshData out = m;
    for (std::size_t i = 0; i + 2 < out.positions.size(); i += 3) {
        out.positions[i] += offset.x;
        out.positions[i + 1] += offset.y;
        out.positions[i + 2] += offset.z;
    }
    out.bmin = out.bmin + offset;
    out.bmax = out.bmax + offset;
    return out;
}

// ---- merging -----------------------------------------------------------------------------------------------------------------

Result<MeshData> model_merge_by_material(const MeshData& m, ModelMergeInfo* info) {
    if (m.indices.empty() || m.submeshes.empty())
        return make_error("the mesh has no triangles to merge", "Merge a mesh that has triangles.");
    const Drawn d = drawn_triangles(m);
    if (d.indices.empty()) return make_error("the mesh has no drawn triangles to merge", "Check its submeshes.");
    // groups of submeshes by material, in order of first appearance
    std::vector<std::uint32_t> groupOf(m.submeshes.size());
    std::vector<std::uint32_t> firstSub;
    std::vector<std::string> partNames;
    for (std::size_t s = 0; s < m.submeshes.size(); ++s) {
        std::size_t g = 0;
        for (; g < firstSub.size(); ++g)
            if (same_material(m.submeshes[firstSub[g]].material, m.submeshes[s].material)) break;
        if (g == firstSub.size()) {
            firstSub.push_back(std::uint32_t(s));
            partNames.emplace_back();
        }
        groupOf[s] = std::uint32_t(g);
        const std::string& part = m.submeshes[s].part;
        if (!part.empty()) {
            std::string& names = partNames[g];
            bool seen = false;
            std::size_t from = 0;
            while (from <= names.size()) {  // "a+b": look for part as one of the joined names
                const std::size_t plus = names.find('+', from);
                const std::string one = names.substr(from, plus == std::string::npos ? std::string::npos : plus - from);
                if (one == part) seen = true;
                if (plus == std::string::npos) break;
                from = plus + 1;
            }
            if (!seen) names += (names.empty() ? "" : "+") + part;
        }
    }
    // triangles ordered by group (stable: the order inside a group is kept)
    std::vector<std::uint32_t> order(d.sub.size());
    for (std::size_t t = 0; t < order.size(); ++t) order[t] = std::uint32_t(t);
    std::stable_sort(order.begin(), order.end(),
                     [&](std::uint32_t a, std::uint32_t b) { return groupOf[d.sub[a]] < groupOf[d.sub[b]]; });
    std::vector<std::uint32_t> idx, grp;
    for (std::uint32_t t : order) {
        for (int k = 0; k < 3; ++k) idx.push_back(d.indices[t * 3 + std::uint32_t(k)]);
        grp.push_back(groupOf[d.sub[t]]);
    }

    // weld identical vertices: the interleaved vertex is position, normal, uv and colour
    const std::size_t n = m.vertex_count();
    const bool hasColor = m.colors.size() == n * 4;
    const std::size_t stride = 8 + (hasColor ? 4 : 0);
    std::vector<float> packed(n * stride);
    for (std::size_t v = 0; v < n; ++v) {
        float* p = &packed[v * stride];
        std::memcpy(p, &m.positions[v * 3], 12);
        std::memcpy(p + 3, &m.normals[v * 3], 12);
        std::memcpy(p + 6, &m.uvs[v * 2], 8);
        if (hasColor) std::memcpy(p + 8, &m.colors[v * 4], 16);
    }
    std::vector<unsigned int> remap(n);
    const std::size_t unique =
        meshopt_generateVertexRemap(remap.data(), idx.data(), idx.size(), packed.data(), n, stride * sizeof(float));
    std::vector<std::uint32_t> welded(idx.size());
    meshopt_remapIndexBuffer(welded.data(), idx.data(), idx.size(), remap.data());
    std::vector<float> vertices(unique * stride);
    meshopt_remapVertexBuffer(vertices.data(), packed.data(), n, stride * sizeof(float), remap.data());
    // GPU order: triangles inside each group for the vertex cache, then vertices in the order of first use
    std::size_t at = 0;
    while (at < grp.size()) {
        std::size_t e = at;
        while (e < grp.size() && grp[e] == grp[at]) ++e;
        meshopt_optimizeVertexCache(&welded[at * 3], &welded[at * 3], (e - at) * 3, unique);
        at = e;
    }
    std::vector<float> fetched(unique * stride);
    const std::size_t used = meshopt_optimizeVertexFetch(fetched.data(), welded.data(), welded.size(), vertices.data(),
                                                         unique, stride * sizeof(float));
    fetched.resize(used * stride);

    std::vector<float> pos(used * 3), nrm(used * 3), uv(used * 2), col(hasColor ? used * 4 : 0);
    for (std::size_t v = 0; v < used; ++v) {
        const float* p = &fetched[v * stride];
        std::memcpy(&pos[v * 3], p, 12);
        std::memcpy(&nrm[v * 3], p + 3, 12);
        std::memcpy(&uv[v * 2], p + 6, 8);
        if (hasColor) std::memcpy(&col[v * 4], p + 8, 16);
    }
    MeshData like = m;
    like.submeshes.clear();
    for (std::size_t g = 0; g < firstSub.size(); ++g) like.submeshes.push_back(m.submeshes[firstSub[g]]);
    auto out = assemble(like, std::move(pos), std::move(nrm), std::move(uv), std::move(col), welded, grp, &partNames);
    if (out.ok() && info) {
        info->submeshesBefore = m.submeshes.size();
        info->submeshesAfter = out->submeshes.size();
        info->verticesBefore = n;
        info->verticesAfter = out->vertex_count();
    }
    return out;
}

// ---- LODs ----------------------------------------------------------------------------------------------------------------------

double model_lod_distance(const MeshData& m, std::size_t index, const ModelLodSpec& spec) {
    if (spec.distance > 0) return spec.distance;
    return largest_dimension(m) * 4.0 * double(1u << std::min<std::size_t>(index > 0 ? index - 1 : 0, 8));
}

Result<MeshData> model_make_lod(const MeshData& m, const ModelLodSpec& spec, ModelLodInfo* info) {
    if (m.indices.empty() || m.submeshes.empty())
        return make_error("the mesh has no triangles to reduce", "Make a LOD of a mesh that has triangles.");
    if (spec.ratio <= 0 && spec.triangles == 0 && spec.error <= 0)
        return make_error("a LOD needs ratio, triangles or error", "Example: {\"ratio\": 0.5}.");
    const Drawn d = drawn_triangles(m);
    const std::size_t n = m.vertex_count();
    const bool hasColor = m.colors.size() == n * 4;
    // attributes per vertex: normal (3), uv (2 when the mesh has them), colour (4 when it has them)
    const std::size_t stride = 3 + (m.hasUvs ? 2 : 0) + (hasColor ? 4 : 0);
    std::vector<float> attr(n * stride), weights;
    weights.insert(weights.end(), 3, 1.0f);
    if (m.hasUvs) weights.insert(weights.end(), 2, 0.5f);
    if (hasColor) weights.insert(weights.end(), 4, 0.25f);
    for (std::size_t v = 0; v < n; ++v) {
        float* a = &attr[v * stride];
        std::memcpy(a, &m.normals[v * 3], 12);
        a += 3;
        if (m.hasUvs) {
            std::memcpy(a, &m.uvs[v * 2], 8);
            a += 2;
        }
        if (hasColor) std::memcpy(a, &m.colors[v * 4], 16);
    }
    std::vector<Vec3> pos(n);
    for (std::size_t v = 0; v < n; ++v) pos[v] = {m.positions[v * 3], m.positions[v * 3 + 1], m.positions[v * 3 + 2]};

    const std::size_t total = d.sub.size();
    ModelSimplifyParams sp;
    sp.maxError = spec.error;
    sp.lockBorder = true;  // an open edge of a submesh (and the border between parts) stays where it is
    if (spec.ratio > 0)
        sp.targetTriangles = std::max<std::size_t>(1, std::size_t(std::ceil(double(total) * spec.ratio)));
    if (spec.triangles > 0)
        sp.targetTriangles = sp.targetTriangles > 0 ? std::min(sp.targetTriangles, spec.triangles) : spec.triangles;
    const ModelSimplifyResult r = model_simplify(pos, attr, stride, weights, d.indices, d.sub, sp);
    if (r.indices.empty())
        return make_error("the reduction removed every triangle", "Raise ratio or triangles, or lower error.");

    const std::size_t vn = r.positions.size();
    std::vector<float> opos(vn * 3), onrm(vn * 3), ouv(vn * 2, 0.0f), ocol(hasColor ? vn * 4 : 0);
    for (std::size_t v = 0; v < vn; ++v) {
        std::memcpy(&opos[v * 3], &r.positions[v], 12);
        const float* a = &r.attributes[v * stride];
        Vec3 nrm = normalize(Vec3{a[0], a[1], a[2]});
        if (length_sq(nrm) < 0.5f)
            nrm = {m.normals[r.keep[v] * 3], m.normals[r.keep[v] * 3 + 1], m.normals[r.keep[v] * 3 + 2]};
        std::memcpy(&onrm[v * 3], &nrm, 12);
        a += 3;
        if (m.hasUvs) {
            std::memcpy(&ouv[v * 2], a, 8);
            a += 2;
        }
        if (hasColor) {
            for (int k = 0; k < 4; ++k) ocol[v * 4 + std::size_t(k)] = std::clamp(a[k], 0.0f, 1.0f);
        }
    }
    auto out =
        assemble(m, std::move(opos), std::move(onrm), std::move(ouv), std::move(ocol), r.indices, r.triParts, nullptr);
    if (out.ok() && info) {
        info->triangles = out->triangle_count();
        info->vertices = out->vertex_count();
        info->submeshes = out->submeshes.size();
        info->error = r.error;
        info->reachedTarget =
            sp.targetTriangles == 0 || out->triangle_count() <= sp.targetTriangles + sp.targetTriangles / 20 + 2;
    }
    return out;
}

// ---- the whole thing -----------------------------------------------------------------------------------------------------------

Result<ModelGameReadyResult> make_game_ready(const MeshData& input, const ModelGameReady& s) {
    if (input.indices.empty() || input.submeshes.empty())
        return make_error("the mesh has no triangles", "Game-ready settings work on a mesh that has triangles.");
    ModelGameReadyResult out;
    out.offset = model_origin_offset(input, s.origin);
    MeshData mesh =
        (out.offset.x == 0 && out.offset.y == 0 && out.offset.z == 0) ? input : model_translated(input, out.offset);
    MeshData unmerged;  // merging joins part names, so a collider fitted to one part reads the mesh as it was before
    const bool keepUnmerged = s.merge && !s.collider.part.empty() && s.collider.shape != "none";
    if (keepUnmerged) unmerged = mesh;
    out.merge.submeshesBefore = out.merge.submeshesAfter = mesh.submeshes.size();
    out.merge.verticesBefore = out.merge.verticesAfter = mesh.vertex_count();
    if (s.merge) {
        auto merged = model_merge_by_material(mesh, &out.merge);
        if (!merged.ok()) return merged.error();
        mesh = std::move(*merged);
    }
    out.mesh = std::move(mesh);
    ModelLodInfo base;
    base.triangles = out.mesh.triangle_count();
    base.vertices = out.mesh.vertex_count();
    base.submeshes = out.mesh.submeshes.size();
    out.lodInfo.push_back(base);
    std::size_t previous = base.triangles;
    for (std::size_t i = 0; i < s.lods.size(); ++i) {
        ModelLodInfo li;
        auto lod = model_make_lod(out.mesh, s.lods[i], &li);
        if (!lod.ok()) return make_error(std::format("LOD{}: {}", i + 1, lod.error().message), lod.error().hint);
        li.distance = model_lod_distance(out.mesh, i + 1, s.lods[i]);
        if (i > 0 && s.lods[i].distance == 0 && s.lods[i - 1].distance > 0 &&
            li.distance <= out.lodInfo.back().distance)
            li.distance = out.lodInfo.back().distance * 2;  // an automatic distance never lands before a given one
        if (li.triangles >= previous)
            out.warnings.push_back(
                std::format("LOD{} has {} triangles, no fewer than LOD{} ({}): the surface has nothing left to "
                            "collapse at that error. Lower ratio/triangles or raise error.",
                            i + 1, li.triangles, i, previous));
        else if (!li.reachedTarget)
            out.warnings.push_back(std::format("LOD{} stopped at {} triangles, above its target: the borders between "
                                               "parts and open edges stay fixed (or error is too low).",
                                               i + 1, li.triangles));
        previous = std::min(previous, li.triangles);
        out.lodInfo.push_back(li);
        out.lods.push_back(std::move(*lod));
    }
    if (s.collider.shape != "none") {
        auto c = model_fit_collider(keepUnmerged ? unmerged : out.mesh, s.collider);
        if (!c.ok()) return make_error("collider: " + c.error().message, c.error().hint);
        for (const std::string& w : c->warnings) out.warnings.push_back("collider: " + w);
        out.collider = std::move(*c);
    }
    for (const ModelPlatformBudget& b : model_platform_budgets()) {
        if (std::find(s.platforms.begin(), s.platforms.end(), b.platform) == s.platforms.end()) continue;
        ModelBudgetRow row;
        row.platform = b.platform;
        row.budgetTriangles = b.triangles;
        row.budgetSubmeshes = b.submeshes;
        for (std::size_t i = 0; i < out.lodInfo.size() && row.firstFittingLod < 0; ++i)
            if (out.lodInfo[i].triangles <= b.triangles) row.firstFittingLod = int(i);
        row.fullMeshFits = out.lodInfo[0].triangles <= b.triangles;
        row.submeshesFit = out.lodInfo[0].submeshes <= b.submeshes;
        if (!row.fullMeshFits) {
            if (row.firstFittingLod > 0)
                out.warnings.push_back(
                    std::format("{}: the full mesh has {} triangles, over the {} budget of {}; LOD{} ({}) fits, so the "
                                "game should show LOD{} or lower there.",
                                b.platform, out.lodInfo[0].triangles, b.platform, b.triangles, row.firstFittingLod,
                                out.lodInfo[size_t(row.firstFittingLod)].triangles, row.firstFittingLod));
            else
                out.warnings.push_back(std::format("{}: no LOD fits the {} budget of {} triangles (the smallest has "
                                                   "{}). Add a LOD with a lower ratio or triangles.",
                                                   b.platform, b.platform, b.triangles,
                                                   std::min_element(out.lodInfo.begin(), out.lodInfo.end(),
                                                                    [](const ModelLodInfo& a, const ModelLodInfo& c) {
                                                                        return a.triangles < c.triangles;
                                                                    })
                                                       ->triangles));
        }
        if (!row.submeshesFit)
            out.warnings.push_back(std::format("{}: {} submeshes (draw calls) over the budget of {}. Set \"merge\": "
                                               "true to join the submeshes that share a material.",
                                               b.platform, out.lodInfo[0].submeshes, b.submeshes));
        out.budget.push_back(row);
    }
    return out;
}

Json game_ready_report_json(const ModelGameReadyResult& r, const ModelGameReady& s) {
    Json lods = Json::array();
    for (std::size_t i = 0; i < r.lodInfo.size(); ++i) {
        const ModelLodInfo& l = r.lodInfo[i];
        Json o = Json::object(
            {{"lod", i}, {"triangles", l.triangles}, {"vertices", l.vertices}, {"submeshes", l.submeshes}});
        if (i > 0) {
            o["error"] = std::round(l.error * 1e5) / 1e5;
            o["distance"] = std::round(l.distance * 100) / 100;
            o["ratio"] = r.lodInfo[0].triangles
                             ? std::round(double(l.triangles) / double(r.lodInfo[0].triangles) * 1000) / 1000
                             : 0;
        }
        lods.push_back(o);
    }
    Json budget = Json::array();
    for (const ModelBudgetRow& b : r.budget) {
        Json per = Json::array();
        for (const ModelLodInfo& l : r.lodInfo) per.push_back(l.triangles <= b.budgetTriangles);
        budget.push_back(Json::object({{"platform", b.platform},
                                       {"budgetTriangles", b.budgetTriangles},
                                       {"budgetSubmeshes", b.budgetSubmeshes},
                                       {"fullMeshFits", b.fullMeshFits},
                                       {"submeshesFit", b.submeshesFit},
                                       {"firstFittingLod", b.firstFittingLod},
                                       {"lodFits", per}}));
    }
    Json out = Json::object({{"settings", game_ready_to_json(s)},
                             {"offset", Json::array({r.offset.x, r.offset.y, r.offset.z})},
                             {"lods", lods},
                             {"budget", budget},
                             {"merge", Json::object({{"submeshesBefore", r.merge.submeshesBefore},
                                                     {"submeshesAfter", r.merge.submeshesAfter},
                                                     {"verticesBefore", r.merge.verticesBefore},
                                                     {"verticesAfter", r.merge.verticesAfter}})}});
    if (r.collider.shape != "none") {
        const ModelCollider& c = r.collider;
        Json cj = Json::object(
            {{"shape", c.shape}, {"volume", c.volume}, {"meshVolume", c.meshVolume}, {"volumeRatio", c.volumeRatio}});
        if (c.shape == "box") {
            cj["center"] = Json::array({c.center.x, c.center.y, c.center.z});
            cj["size"] = Json::array({c.size.x, c.size.y, c.size.z});
        } else if (c.shape == "sphere" || c.shape == "capsule") {
            cj["center"] = Json::array({c.center.x, c.center.y, c.center.z});
            cj["radius"] = c.radius;
            if (c.shape == "capsule") cj["height"] = c.height;
        } else {
            Json hulls = Json::array();
            for (const ModelHull& h : c.hulls)
                hulls.push_back(Json::object(
                    {{"vertices", h.points.size()}, {"triangles", h.indices.size() / 3}, {"volume", h.volume}}));
            cj["hulls"] = hulls;
        }
        out["collider"] = cj;
    }
    if (!r.warnings.empty()) out["warnings"] = r.warnings;
    return out;
}

}  // namespace fa
