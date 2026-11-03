// Evaluating a model document: the tree in document order, to one mesh with a submesh per (part, material).
#include <algorithm>
#include <cstdio>
#include <format>
#include <map>
#include <set>

#include "fa/core/strings.h"
#include "fa/scene/model_doc.h"

namespace fa {

namespace {

struct Inherited {
    std::optional<std::string> part, material;
    std::optional<Vec4> color;
};

struct Group {
    std::string part, material;
};

struct Eval {
    const ModelDoc& doc;
    const ModelEvalOptions& options;
    ModelBuild& out;
    std::vector<Group> groups;
    std::map<std::pair<std::string, std::string>, std::uint32_t> groupIds;
    std::set<std::string> inputs;
    std::string error;

    std::uint32_t group_of(const Inherited& in) {
        const std::string part = in.part.value_or(""), material = in.material.value_or("");
        auto [it, fresh] = groupIds.emplace(std::make_pair(part, material), static_cast<std::uint32_t>(groups.size()));
        if (fresh) groups.push_back({part, material});
        return it->second;
    }
};

Vec3 v3(const Json& a) { return {a[0].get<float>(), a[1].get<float>(), a[2].get<float>()}; }
float f(const Json& p, const char* k) { return p[k].get<float>(); }
int i(const Json& p, const char* k) { return p[k].get<int>(); }

bool is_file_font(const std::string& font) { return !font.empty() && font.rfind("builtin:", 0) != 0; }

std::string codepoint_list(const std::vector<char32_t>& cps) {
    std::string s;
    for (std::size_t k = 0; k < cps.size() && k < 8; ++k) s += (k ? ", " : "") + std::format("U+{:04X}", static_cast<unsigned>(cps[k]));
    if (cps.size() > 8) s += ", ...";
    return s;
}

// The mesh of one primitive node, before align and transform. False with eval.error set when it cannot be made.
bool build_primitive(Eval& eval, const ModelNode& n, ModelMesh& mesh) {
    const Json& p = n.params;
    if (n.op == "box") {
        ModelBoxParams q;
        q.size = v3(p["size"]);
        q.segX = p["segments"][0].get<int>();
        q.segY = p["segments"][1].get<int>();
        q.segZ = p["segments"][2].get<int>();
        mesh = model_box(q);
    } else if (n.op == "rounded_box") {
        mesh = model_rounded_box({v3(p["size"]), f(p, "radius"), i(p, "segments")});
    } else if (n.op == "cylinder") {
        ModelCylinderParams q;
        q.radius = f(p, "radius");
        if (p.contains("radiusTop")) q.radiusTop = f(p, "radiusTop");
        q.height = f(p, "height");
        q.segments = i(p, "segments");
        q.heightSegments = i(p, "heightSegments");
        q.capBottom = p["capBottom"].get<bool>();
        q.capTop = p["capTop"].get<bool>();
        mesh = model_cylinder(q);
    } else if (n.op == "cone") {
        mesh = model_cone({f(p, "radius"), f(p, "radiusTop"), f(p, "height"), i(p, "segments"), i(p, "heightSegments"), p["cap"].get<bool>()});
    } else if (n.op == "sphere") {
        mesh = model_sphere({f(p, "radius"), i(p, "segments"), p.contains("rings") ? i(p, "rings") : 0});
    } else if (n.op == "capsule") {
        mesh = model_capsule({f(p, "radius"), f(p, "height"), i(p, "segments"), i(p, "rings"), i(p, "heightSegments")});
    } else if (n.op == "torus") {
        mesh = model_torus({f(p, "radius"), f(p, "tube"), i(p, "segments"), i(p, "sides")});
    } else if (n.op == "grid") {
        mesh = model_grid({f(p, "width"), f(p, "depth"), p["segments"][0].get<int>(), p["segments"][1].get<int>()});
    } else if (n.op == "stairs") {
        mesh = model_stairs({i(p, "steps"), f(p, "width"), f(p, "height"), f(p, "depth")});
    } else if (n.op == "arch") {
        mesh = model_arch({f(p, "width"), f(p, "height"), f(p, "depth"), f(p, "openingWidth"), f(p, "openingHeight"), i(p, "segments")});
    } else if (n.op == "pipe") {
        mesh = model_pipe({f(p, "radius"), f(p, "innerRadius"), f(p, "height"), i(p, "segments")});
    } else if (n.op == "text") {
        if (!eval.options.text) {
            eval.error = n.pointer + ": a text node needs a font, and this evaluation was given no font source";
            return false;
        }
        ModelTextRequest req;
        req.text = p["text"].get<std::string>();
        req.font = p["font"].get<std::string>();
        req.anchor = p["anchor"].get<std::string>();
        req.letterSpacing = f(p, "letterSpacing");
        req.lineSpacing = f(p, "lineSpacing");
        auto outline = eval.options.text(req);
        if (!outline) {
            eval.error = n.pointer + ": " + outline.error().message + (outline.error().hint.empty() ? "" : " (hint: " + outline.error().hint + ")");
            return false;
        }
        if (is_file_font(req.font)) eval.inputs.insert(req.font);
        if (!outline->missing.empty())
            eval.out.warnings.push_back(std::format("{}: the font has no glyph for {} (they are left out)", n.pointer, codepoint_list(outline->missing)));
        mesh = model_text(*outline, {f(p, "size"), f(p, "depth"), i(p, "curveSegments")});
        if (mesh.empty()) eval.out.warnings.push_back(n.pointer + ": the text has no ink (only spaces?), nothing was made");
    } else {
        eval.error = n.pointer + ": internal: operation " + n.op + " has no builder";
        return false;
    }
    return true;
}

bool eval_nodes(Eval& eval, const std::vector<ModelNode>& nodes, const Inherited& in, ModelMesh& into);

bool eval_node(Eval& eval, const ModelNode& n, const Inherited& parent, ModelMesh& into) {
    if (!n.enabled) return true;
    Inherited in = parent;
    if (n.part) in.part = n.part;
    if (n.material) in.material = n.material;
    if (n.color) in.color = n.color;
    ModelMesh mesh;
    if (n.op == "group") {
        if (!eval_nodes(eval, n.children, in, mesh)) return false;
    } else {
        if (!build_primitive(eval, n, mesh)) return false;
        if (mesh.empty()) return true;
        Vec3 bmin, bmax;
        mesh.bounds(bmin, bmax);
        if (n.align == "bottom") mesh.transform(Mat4::translate({0, -bmin.y, 0}));
        else if (n.align == "top") mesh.transform(Mat4::translate({0, -bmax.y, 0}));
        if (in.color) mesh.set_color(*in.color);
        mesh.set_part(eval.group_of(in));
    }
    if (mesh.empty()) return true;
    mesh.transform(Mat4::trs(n.position, n.rotation, n.scale));
    into.append(mesh);
    return true;
}

bool eval_nodes(Eval& eval, const std::vector<ModelNode>& nodes, const Inherited& in, ModelMesh& into) {
    for (const ModelNode& n : nodes)
        if (!eval_node(eval, n, in, into)) return false;
    return true;
}

}  // namespace

Result<ModelBuild> evaluate_model(const ModelDoc& doc, const ModelEvalOptions& options) {
    ModelBuild build;
    Eval eval{doc, options, build, {}, {}, {}, {}};
    ModelMesh mesh;
    if (!eval_nodes(eval, doc.nodes, {}, mesh)) return make_error(eval.error, "Fix the node, or set `enabled: false` on it to leave it out.");
    if (mesh.empty())
        return make_error("the model has no triangles: no node made any geometry",
                          doc.nodes.empty() ? "Add a node, e.g. model.edit {\"add\": {\"op\": \"box\"}}." : "Every node is disabled, or a text has no ink. Enable a node or give it something to draw.");
    if (mesh.vertex_count() > (1u << 20) || mesh.indices.size() > (6u << 20))
        return make_error(std::format("the model has {} vertices and {} triangles, more than a mesh can hold ({} vertices)", mesh.vertex_count(), mesh.triangle_count(), 1u << 20),
                          "Lower `segments` on the round primitives, or use fewer nodes.");
    build.stats = model_mesh_stats(mesh);

    // The triangles of each (part, material) next to each other, in the order the groups were first used; the order inside a group is the
    // document's.
    const std::size_t groupCount = eval.groups.size();
    std::vector<std::uint32_t> counts(groupCount, 0);
    for (std::uint32_t part : mesh.triParts) ++counts[part];
    std::vector<std::uint32_t> start(groupCount, 0);
    for (std::size_t g = 1; g < groupCount; ++g) start[g] = start[g - 1] + counts[g - 1] * 3;
    std::vector<std::uint32_t> sorted(mesh.indices.size());
    std::vector<std::uint32_t> cursor = start;
    for (std::size_t t = 0; t < mesh.triParts.size(); ++t) {
        std::uint32_t& c = cursor[mesh.triParts[t]];
        for (std::size_t k = 0; k < 3; ++k) sorted[c + k] = mesh.indices[t * 3 + k];
        c += 3;
    }

    MeshInput in;
    in.positions.reserve(mesh.vertex_count() * 3);
    for (const Vec3& p : mesh.positions) in.positions.insert(in.positions.end(), {p.x, p.y, p.z});
    for (const Vec3& n : mesh.normals) in.normals.insert(in.normals.end(), {n.x, n.y, n.z});
    for (const Vec2& t : mesh.uvs) in.uvs.insert(in.uvs.end(), {t.x, t.y});
    for (const Vec4& c : mesh.colors) in.colors.insert(in.colors.end(), {c.x, c.y, c.z, c.w});
    in.indices = std::move(sorted);
    in.hasIndices = true;
    for (std::size_t g = 0; g < groupCount; ++g) {
        if (counts[g] == 0) continue;
        MeshSubmesh sm;
        sm.start = start[g];
        sm.count = counts[g] * 3;
        sm.part = eval.groups[g].part;
        if (!eval.groups[g].material.empty()) {
            for (const auto& [name, mat] : doc.materials)
                if (name == eval.groups[g].material) {
                    sm.material = mat;
                    if (!mat.texture.empty()) eval.inputs.insert(mat.texture);
                }
        }
        in.submeshes.push_back(sm);
        ModelPartInfo info;
        info.part = eval.groups[g].part;
        info.material = eval.groups[g].material;
        info.triangles = counts[g];
        bool first = true;
        for (std::uint32_t k = start[g]; k < start[g] + counts[g] * 3; ++k) {
            const Vec3 p = mesh.positions[in.indices[k]];
            if (first) info.bmin = info.bmax = p;
            first = false;
            info.bmin = {std::min(info.bmin.x, p.x), std::min(info.bmin.y, p.y), std::min(info.bmin.z, p.z)};
            info.bmax = {std::max(info.bmax.x, p.x), std::max(info.bmax.y, p.y), std::max(info.bmax.z, p.z)};
        }
        build.parts.push_back(info);
    }
    auto data = build_mesh_data(in);
    if (!data) return data.error();
    build.data = std::move(*data);
    build.inputs.assign(eval.inputs.begin(), eval.inputs.end());
    if (build.stats.degenerateTriangles > 0)
        build.warnings.push_back(std::format("{} triangle(s) have no area", build.stats.degenerateTriangles));
    if (build.stats.triangles > 200000)
        build.warnings.push_back(std::format("the model has {} triangles, heavy for a game asset: lower `segments`", build.stats.triangles));
    return build;
}

}  // namespace fa
