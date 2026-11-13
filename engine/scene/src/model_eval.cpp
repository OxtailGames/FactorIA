// Evaluating a model document: the tree in document order, to one mesh with a submesh per (part, material).
#include <algorithm>
#include <cstdio>
#include <format>
#include <map>
#include <set>

#include "fa/core/strings.h"
#include "fa/core/fs.h"
#include "fa/scene/gltf_mesh.h"
#include "fa/scene/model_doc.h"
#include "fa/scene/model_modifiers.h"
#include "fa/scene/model_select.h"
#include "fa/scene/model_sdf.h"

namespace fa {

namespace {

struct Inherited {
    std::optional<std::string> part, material;
    std::optional<Vec4> color;
    Mat4 world =
        Mat4::identity();  // this node's space to the model's: the transforms of the nodes above, this node's included
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
    for (std::size_t k = 0; k < cps.size() && k < 8; ++k)
        s += (k ? ", " : "") + std::format("U+{:04X}", static_cast<unsigned>(cps[k]));
    if (cps.size() > 8) s += ", ...";
    return s;
}

// Records why a node cannot be evaluated: its pointer, what is wrong and the fix.
void fail(Eval& eval, const ModelNode& n, const std::string& message, const std::string& hint) {
    eval.error = n.pointer + ": " + message + (hint.empty() ? "" : " (hint: " + hint + ")");
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
        mesh = model_cone({f(p, "radius"), f(p, "radiusTop"), f(p, "height"), i(p, "segments"), i(p, "heightSegments"),
                           p["cap"].get<bool>()});
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
        mesh = model_arch({f(p, "width"), f(p, "height"), f(p, "depth"), f(p, "openingWidth"), f(p, "openingHeight"),
                           i(p, "segments")});
    } else if (n.op == "pipe") {
        mesh = model_pipe({f(p, "radius"), f(p, "innerRadius"), f(p, "height"), i(p, "segments")});
    } else if (n.op == "lathe") {
        ModelLatheParams q;
        for (const Json& pt : p["profile"]) q.profile.push_back({pt[0].get<float>(), pt[1].get<float>()});
        q.segments = i(p, "segments");
        q.angle = f(p, "angle");
        q.cap = p["cap"].get<bool>();
        q.creaseAngle = f(p, "creaseAngle");
        mesh = model_lathe(q);
        if (mesh.empty()) {
            fail(eval, n, "the lathe profile makes no surface",
                 "Give the profile at least two different points, one of them off the axis.");
            return false;
        }
    } else if (n.op == "sweep") {
        ModelSweepParams q;
        for (const Json& pt : p["profile"]) q.profile.push_back({pt[0].get<float>(), pt[1].get<float>()});
        for (const Json& pt : p["path"]) q.path.push_back(v3(pt));
        q.smooth = p["smooth"].get<bool>();
        q.pathSegments = i(p, "pathSegments");
        q.closed = p["closed"].get<bool>();
        q.scaleStart = f(p, "scaleStart");
        q.scaleEnd = f(p, "scaleEnd");
        q.twist = f(p, "twist");
        q.cap = p["cap"].get<bool>();
        q.creaseAngle = f(p, "creaseAngle");
        auto made = model_sweep(q);
        if (!made) {
            fail(eval, n, made.error().message, made.error().hint);
            return false;
        }
        mesh = std::move(*made);
    } else if (n.op == "loft") {
        ModelLoftParams q;
        for (const Json& section : p["sections"]) {
            std::vector<Vec3> pts;
            for (const Json& pt : section) pts.push_back(v3(pt));
            q.sections.push_back(std::move(pts));
        }
        q.closed = p["closed"].get<bool>();
        q.smooth = p["smooth"].get<bool>();
        q.steps = i(p, "steps");
        q.cap = p["cap"].get<bool>();
        q.creaseAngle = f(p, "creaseAngle");
        auto made = model_loft(q);
        if (!made) {
            fail(eval, n, made.error().message, made.error().hint);
            return false;
        }
        mesh = std::move(*made);
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
            eval.error = n.pointer + ": " + outline.error().message +
                         (outline.error().hint.empty() ? "" : " (hint: " + outline.error().hint + ")");
            return false;
        }
        if (is_file_font(req.font)) eval.inputs.insert(req.font);
        if (!outline->missing.empty())
            eval.out.warnings.push_back(std::format("{}: the font has no glyph for {} (they are left out)", n.pointer,
                                                    codepoint_list(outline->missing)));
        mesh = model_text(*outline, {f(p, "size"), f(p, "depth"), i(p, "curveSegments")});
        if (mesh.empty())
            eval.out.warnings.push_back(n.pointer + ": the text has no ink (only spaces?), nothing was made");
    } else {
        eval.error = n.pointer + ": internal: operation " + n.op + " has no builder";
        return false;
    }
    return true;
}

// A `mesh` node: the triangles of a project glTF, one group per submesh of the file. The file's materials are matched by name to the document's
// `materials` (a node's own `material` or `part` replaces them), a primitive's part comes from its extras.
bool build_mesh_node(Eval& eval, const ModelNode& n, const Inherited& in, ModelMesh& mesh) {
    const std::string source = n.params["source"].get<std::string>();
    auto read = read_gltf_mesh(source);
    if (!read) {
        fail(eval, n, read.error().message,
             read.error().hint.empty() ? "Check the path; the file must be inside the project." : read.error().hint);
        return false;
    }
    eval.inputs.insert(fs::normalize(source));
    for (const std::string& w : read->warnings)
        eval.out.warnings.push_back(std::format("{}: {}: {}", n.pointer, source, w));
    const MeshData& d = read->data;
    if (d.triangle_count() > kModelMaxTriangles) {
        fail(eval, n,
             std::format("'{}' has {} triangles, more than the {} a node may make", source, d.triangle_count(),
                         kModelMaxTriangles),
             "Clean and decimate it first: model.import_clean {\"source\":\"" + source +
                 "\"} brings it to a platform's triangle budget.");
        return false;
    }
    const std::size_t verts = d.vertex_count();
    mesh.positions.resize(verts);
    mesh.normals.resize(verts);
    mesh.uvs.resize(verts);
    for (std::size_t v = 0; v < verts; ++v) {
        mesh.positions[v] = {d.positions[v * 3], d.positions[v * 3 + 1], d.positions[v * 3 + 2]};
        mesh.normals[v] = {d.normals[v * 3], d.normals[v * 3 + 1], d.normals[v * 3 + 2]};
        mesh.uvs[v] = {d.uvs[v * 2], d.uvs[v * 2 + 1]};
    }
    if (!d.colors.empty()) {
        mesh.colors.resize(verts);
        for (std::size_t v = 0; v < verts; ++v)
            mesh.colors[v] = {d.colors[v * 4], d.colors[v * 4 + 1], d.colors[v * 4 + 2], d.colors[v * 4 + 3]};
    }
    std::set<std::string> unknown;
    for (const MeshSubmesh& sm : d.submeshes) {
        Inherited g = in;
        if (!n.part && !sm.part.empty()) g.part = sm.part;
        if (!n.material && !sm.material.name.empty()) {
            const bool known = std::any_of(eval.doc.materials.begin(), eval.doc.materials.end(),
                                           [&](const auto& m) { return m.first == sm.material.name; });
            if (known)
                g.material = sm.material.name;
            else
                unknown.insert(sm.material.name);
        }
        const std::uint32_t group = eval.group_of(g);
        for (std::uint32_t k = sm.start; k < sm.start + sm.count; ++k) mesh.indices.push_back(d.indices[k]);
        mesh.triParts.insert(mesh.triParts.end(), sm.count / 3, group);
    }
    if (!unknown.empty()) {
        std::string names;
        for (const std::string& u : unknown) names += (names.empty() ? "" : ", ") + u;
        eval.out.warnings.push_back(
            std::format("{}: the materials {} of '{}' are not in the document's `materials`, so those triangles have "
                        "the default material (add entries with these names, or set `material` on the node)",
                        n.pointer, names, source));
    }
    return true;
}

bool eval_nodes(Eval& eval, const std::vector<ModelNode>& nodes, const Inherited& in, ModelMesh& into);
bool eval_node(Eval& eval, const ModelNode& n, const Inherited& parent, ModelMesh& into);

bool is_modifier(const std::string& op) {
    for (const ModelOpInfo& o : model_ops())
        if (o.op == op) return o.kind == "modifier";
    return false;
}

int axis_of(const Json& p, const char* key) {
    const std::string a = p[key].get<std::string>();
    return a == "x" ? 0 : a == "y" ? 1 : 2;
}

// False (with the error recorded) when `triangles` is more than a node may make.
bool within_limit(Eval& eval, const ModelNode& n, const char* what, std::size_t triangles, const char* hint) {
    if (triangles <= kModelMaxTriangles) return true;
    fail(eval, n,
         std::format("{} would make {} triangles, more than the {} a node may make", what, triangles,
                     kModelMaxTriangles),
         hint);
    return false;
}

// What the edit operations and model.select need to know about the place of a node in the tree.
ModelEditContext make_context(Eval& eval, const Inherited& in) {
    ModelEditContext ctx;
    for (const Group& g : eval.groups) ctx.partNames.push_back(g.part);
    for (const auto& m : eval.doc.materials) ctx.materialNames.push_back(m.first);
    ctx.toModel = in.world;
    ctx.group_with = [&eval](std::uint32_t source, const std::optional<std::string>& part,
                             const std::optional<std::string>& material) {
        Inherited tmp;
        tmp.part = part ? *part : eval.groups[source].part;
        tmp.material = material ? *material : eval.groups[source].material;
        return eval.group_of(tmp);
    };
    return ctx;
}

void probe(Eval& eval, const ModelNode& n, const ModelMesh& mesh, const Inherited& in) {
    if (eval.options.probe && !mesh.empty()) eval.options.probe(n, mesh, make_context(eval, in));
}

// An edit operation (model_select.h): the selection is evaluated on the merged children.
bool eval_edit(Eval& eval, const ModelNode& n, const Inherited& in, const ModelMesh& m, ModelMesh& out) {
    const ModelEditContext ctx = make_context(eval, in);
    auto edited = model_apply_edit(n, m, ctx);
    if (!edited) {
        fail(eval, n, edited.error().message, edited.error().hint);
        return false;
    }
    for (const std::string& w : edited->warnings) eval.out.warnings.push_back(n.pointer + ": " + w);
    edited->report.pointer = n.pointer;
    edited->report.op = n.op;
    eval.out.edits.push_back(edited->report);
    if (!within_limit(eval, n, ("the " + n.op).c_str(), edited->mesh.triangle_count(),
                      "Select fewer faces, or use fewer segments on the model below."))
        return false;
    out.append(edited->mesh);
    return true;
}

// The booleans: every enabled child that makes geometry is an operand.
bool eval_boolean(Eval& eval, const ModelNode& n, const Inherited& in, ModelMesh& out) {
    std::vector<ModelMesh> operands;
    std::vector<std::string> names;
    for (const ModelNode& child : n.children) {
        ModelMesh operand;
        if (!eval_node(eval, child, in, operand)) return false;
        if (operand.empty()) continue;
        operands.push_back(std::move(operand));
        names.push_back(child.pointer);
    }
    const std::string mode = n.params["mode"].get<std::string>();
    if (operands.empty()) {
        eval.out.warnings.push_back(n.pointer + ": the boolean has no child that makes geometry, nothing was made");
        return true;
    }
    if (operands.size() == 1)
        eval.out.warnings.push_back(n.pointer + ": a boolean needs two or more children to combine; with one it only "
                                                "checks that the solid is closed and passes it on");
    auto result = model_boolean(operands,
                                mode == "union"        ? ModelBooleanMode::Union
                                : mode == "difference" ? ModelBooleanMode::Difference
                                                       : ModelBooleanMode::Intersection,
                                names);
    if (!result) {
        fail(eval, n, result.error().message, result.error().hint);
        return false;
    }
    out = std::move(*result);
    if (out.empty())
        eval.out.warnings.push_back(n.pointer + ": the " + mode + " is empty (the solids " +
                                    (mode == "intersection" ? "do not overlap" : "cancel out") + ")");
    return true;
}

// The modifiers: the children are merged like a group's, then the operation changes that mesh.
bool eval_modifier(Eval& eval, const ModelNode& n, const Inherited& in, ModelMesh& out) {
    if (n.op == "boolean") return eval_boolean(eval, n, in, out);
    ModelMesh m;
    if (!eval_nodes(eval, n.children, in, m)) return false;
    if (m.empty()) {
        eval.out.warnings.push_back(n.pointer + ": the " + n.op +
                                    " has no child that makes geometry, nothing was made");
        return true;
    }
    probe(eval, n, m, in);
    if (model_is_edit_op(n.op)) return eval_edit(eval, n, in, m, out);
    const Json& p = n.params;
    const std::size_t tris = m.triangle_count();
    if (n.op == "mirror") {
        if (!within_limit(eval, n, "the mirror", tris * 2, "Use fewer segments on the children.")) return false;
        ModelMirrorParams q;
        q.axis = axis_of(p, "axis");
        q.offset = f(p, "offset");
        q.merge = p["merge"].get<bool>();
        q.mergeDistance = f(p, "mergeDistance");
        out.append(model_mirror(m, q));
        return true;
    }
    if (n.op == "array") {
        const std::size_t count = std::size_t(i(p, "count"));
        if (!within_limit(eval, n, std::format("an array of {} copies of {} triangles", count, tris).c_str(),
                          tris * count, "Lower `count`, or use fewer segments on the children."))
            return false;
        ModelArrayParams q;
        q.count = int(count);
        q.offset = v3(p["offset"]);
        q.relative = p["relative"].get<bool>();
        q.stepRotation = v3(p["stepRotation"]);
        q.stepScale = v3(p["stepScale"]);
        q.merge = p["merge"].get<bool>();
        q.mergeDistance = f(p, "mergeDistance");
        out.append(model_array(m, q));
        return true;
    }
    if (n.op == "radial_array") {
        const std::size_t count = std::size_t(i(p, "count"));
        if (!within_limit(eval, n, std::format("a radial array of {} copies of {} triangles", count, tris).c_str(),
                          tris * count, "Lower `count`, or use fewer segments on the children."))
            return false;
        ModelRadialArrayParams q;
        q.count = int(count);
        q.axis = axis_of(p, "axis");
        q.angle = f(p, "angle");
        q.center = v3(p["center"]);
        q.faceCenter = p["faceCenter"].get<bool>();
        q.merge = p["merge"].get<bool>();
        q.mergeDistance = f(p, "mergeDistance");
        out.append(model_radial_array(m, q));
        return true;
    }
    if (n.op == "bevel") {
        ModelBevelParams q;
        q.width = f(p, "width");
        q.segments = i(p, "segments");
        q.angle = f(p, "angle");
        q.roundness = f(p, "roundness");
        std::size_t edges = 0;
        auto made = model_bevel(m, q, &edges);
        if (!made) {
            fail(eval, n, made.error().message, made.error().hint);
            return false;
        }
        if (edges == 0)
            eval.out.warnings.push_back(std::format("{}: no edge turns by more than {:g} degrees, so nothing was "
                                                    "bevelled (lower `angle` to bevel gentler edges)",
                                                    n.pointer, q.angle));
        if (!within_limit(eval, n, "the bevel", made->triangle_count(),
                          "Lower `segments`, raise `angle` so fewer edges are bevelled, or bevel a simpler mesh."))
            return false;
        out.append(*made);
        return true;
    }
    if (n.op == "subdivide") {
        const int levels = i(p, "levels");
        const std::size_t bound = model_subdivide_triangle_bound(m, levels);
        if (!within_limit(
                eval, n, std::format("subdividing {} triangles {} time(s)", tris, levels).c_str(), bound,
                "Lower `levels`, or subdivide a mesh with fewer triangles (each level multiplies them by 4)."))
            return false;
        ModelSubdivideParams q;
        q.levels = levels;
        q.creaseAngle = f(p, "creaseAngle");
        out.append(model_subdivide(m, q));
        return true;
    }
    if (n.op == "solidify") {
        if (!within_limit(eval, n, "the solidify", tris * 2, "Use fewer segments on the children.")) return false;
        ModelSolidifyParams q;
        q.thickness = f(p, "thickness");
        q.offset = f(p, "offset");
        q.even = p["even"].get<bool>();
        ModelMesh made = model_solidify(m, q);
        if (!within_limit(eval, n, "the solidify", made.triangle_count(), "Use fewer segments on the children."))
            return false;
        out.append(made);
        return true;
    }
    if (n.op == "bend") {
        ModelBendParams q;
        q.axis = axis_of(p, "axis");
        q.angle = f(p, "angle");
        q.direction = f(p, "direction");
        if ((q.hasFrom = p.contains("from"))) q.from = f(p, "from");
        if ((q.hasTo = p.contains("to"))) q.to = f(p, "to");
        out.append(model_bend(m, q));
        return true;
    }
    if (n.op == "twist") {
        ModelTwistParams q;
        q.axis = axis_of(p, "axis");
        q.angle = f(p, "angle");
        if ((q.hasFrom = p.contains("from"))) q.from = f(p, "from");
        if ((q.hasTo = p.contains("to"))) q.to = f(p, "to");
        out.append(model_twist(m, q));
        return true;
    }
    if (n.op == "taper") {
        ModelTaperParams q;
        q.axis = axis_of(p, "axis");
        q.startScale = f(p, "startScale");
        q.endScale = f(p, "endScale");
        if ((q.hasFrom = p.contains("from"))) q.from = f(p, "from");
        if ((q.hasTo = p.contains("to"))) q.to = f(p, "to");
        out.append(model_taper(m, q));
        return true;
    }
    if (n.op == "noise") {
        ModelNoiseParams q;
        q.amplitude = f(p, "amplitude");
        q.frequency = f(p, "frequency");
        q.octaves = i(p, "octaves");
        q.seed = i(p, "seed");
        q.alongNormal = p["alongNormal"].get<bool>();
        out.append(model_noise(m, q));
        return true;
    }
    if (n.op == "smooth") {
        ModelSmoothParams q;
        q.iterations = i(p, "iterations");
        q.factor = f(p, "factor");
        q.taubin = p["taubin"].get<bool>();
        q.lockBoundary = p["lockBoundary"].get<bool>();
        q.sharpAngle = f(p, "sharpAngle");
        out.append(model_smooth(m, q));
        return true;
    }
    if (n.op == "weld") {
        ModelWeldParams q;
        q.distance = f(p, "distance");
        out.append(model_weld(m, q));
        return true;
    }
    if (n.op == "shade") {
        ModelShadeParams q;
        const std::string mode = p["mode"].get<std::string>();
        q.mode = mode == "flat"     ? ModelShadeMode::Flat
                 : mode == "smooth" ? ModelShadeMode::Smooth
                                    : ModelShadeMode::Auto;
        q.angle = f(p, "angle");
        out.append(model_shade(m, q));
        return true;
    }
    fail(eval, n, "internal: modifier " + n.op + " has no implementation", "");
    return false;
}

// ---- sdf: the children are signed-distance shapes, meshed together ---------------------------------------------------------------

ModelSdfBlend sdf_blend_of(const Json& p) {
    const std::string b = p["blend"].get<std::string>();
    return b == "subtract"    ? ModelSdfBlend::Subtract
           : b == "intersect" ? ModelSdfBlend::Intersect
                              : ModelSdfBlend::Union;
}

ModelSdfShapeParams sdf_shape_of(const ModelNode& n) {
    const Json& p = n.params;
    ModelSdfShapeParams s;
    if (n.op == "sdf_sphere") {
        s.shape = ModelSdfShape::Sphere;
        s.radius = f(p, "radius");
    } else if (n.op == "sdf_capsule") {
        s.shape = ModelSdfShape::Capsule;
        s.radius = f(p, "radius");
        s.radiusTop = p.contains("radiusTop") ? f(p, "radiusTop") : -1.0f;
        s.height = f(p, "height");
    } else if (n.op == "sdf_ellipsoid") {
        s.shape = ModelSdfShape::Ellipsoid;
        s.size = v3(p["radii"]);
    } else if (n.op == "sdf_box") {
        s.shape = ModelSdfShape::Box;
        s.size = v3(p["size"]);
        s.round = f(p, "round");
    } else if (n.op == "sdf_cylinder") {
        s.shape = ModelSdfShape::Cylinder;
        s.radius = f(p, "radius");
        s.height = f(p, "height");
        s.round = f(p, "round");
    } else if (n.op == "sdf_cone") {
        s.shape = ModelSdfShape::Cone;
        s.radius = f(p, "radius");
        s.radiusTop = f(p, "radiusTop");
        s.height = f(p, "height");
    } else {  // sdf_torus
        s.shape = ModelSdfShape::Torus;
        s.radius = f(p, "radius");
        s.tube = f(p, "tube");
    }
    return s;
}

// Adds the enabled `nodes` to `sdf` and returns their indices in order. Each leaf names its group the way a primitive does (its own part, material
// and colour over the inherited ones).
std::vector<int> add_sdf_nodes(Eval& eval, ModelSdf& sdf, const std::vector<ModelNode>& nodes,
                               const Inherited& parent) {
    std::vector<int> indices;
    for (const ModelNode& c : nodes) {
        if (!c.enabled) continue;
        Inherited in = parent;
        if (c.part) in.part = c.part;
        if (c.material) in.material = c.material;
        if (c.color) in.color = c.color;
        const Mat4 local = Mat4::trs(c.position, c.rotation, c.scale);
        const ModelSdfBlend blend = sdf_blend_of(c.params);
        const float smooth = f(c.params, "smooth");
        if (c.op == "sdf_group") {
            const std::vector<int> kids = add_sdf_nodes(eval, sdf, c.children, in);
            if (kids.empty()) continue;  // a group with nothing enabled in it is left out
            const std::string m = c.params["mirror"].get<std::string>();
            indices.push_back(sdf.add_group(kids, local, blend, smooth,
                                            m == "x"   ? 0
                                            : m == "y" ? 1
                                            : m == "z" ? 2
                                                       : -1));
        } else {
            indices.push_back(sdf.add_shape(sdf_shape_of(c), local, blend, smooth, eval.group_of(in), in.color));
        }
    }
    return indices;
}

bool eval_sdf(Eval& eval, const ModelNode& n, const Inherited& in, ModelMesh& mesh) {
    ModelSdf sdf;
    const std::vector<int> roots = add_sdf_nodes(eval, sdf, n.children, in);
    if (roots.empty()) {
        fail(eval, n, "an sdf needs at least one enabled shape in its `children`",
             "Add one, e.g. {\"op\": \"sdf_sphere\", \"radius\": 0.5}; the shape list is in model.info.");
        return false;
    }
    sdf.set_root(roots.size() == 1 ? roots[0] : sdf.add_group(roots, Mat4::identity(), ModelSdfBlend::Union, 0, -1));
    const Json& p = n.params;
    ModelSdfMeshParams q;
    if (p.contains("voxelSize"))
        q.voxelSize = f(p, "voxelSize");
    else {
        const std::string quality = p["quality"].get<std::string>();
        q.cells = quality == "draft" ? 40 : quality == "fine" ? 160 : quality == "ultra" ? 200 : 96;
    }
    q.noiseAmplitude = f(p, "noiseAmplitude");
    q.noiseFrequency = f(p, "noiseFrequency");
    q.noiseOctaves = i(p, "noiseOctaves");
    q.noiseSeed = i(p, "noiseSeed");
    if (p.contains("targetTriangles")) q.targetTriangles = static_cast<std::size_t>(i(p, "targetTriangles"));
    if (p.contains("maxError")) q.maxError = f(p, "maxError");
    ModelSdfMeshInfo info;
    auto made = model_sdf_mesh(sdf, q, &info);
    if (!made) {
        fail(eval, n, made.error().message, made.error().hint);
        return false;
    }
    if (made->empty()) {
        eval.out.warnings.push_back(
            n.pointer +
            ": the sdf has no surface (everything was subtracted away, or the shapes are smaller than a cell of " +
            std::format("{:g}", info.voxelSize) + " m): lower `voxelSize` or check the subtractions");
        return true;
    }
    if (info.touchedEdge)
        eval.out.warnings.push_back(n.pointer + ": the sdf surface reached the edge of its sampling box and was cut "
                                                "there; lower `noiseAmplitude` or report this");
    if (!within_limit(eval, n, "the sdf", made->triangle_count(),
                      "Raise `voxelSize`, lower `quality` or set `targetTriangles`."))
        return false;
    mesh = std::move(*made);
    return true;
}

bool eval_node(Eval& eval, const ModelNode& n, const Inherited& parent, ModelMesh& into) {
    if (!n.enabled) return true;
    Inherited in = parent;
    if (n.part) in.part = n.part;
    if (n.material) in.material = n.material;
    if (n.color) in.color = n.color;
    in.world = parent.world * Mat4::trs(n.position, n.rotation, n.scale);
    ModelMesh mesh;
    if (n.op == "group") {
        if (!eval_nodes(eval, n.children, in, mesh)) return false;
        probe(eval, n, mesh, in);
    } else if (is_modifier(n.op)) {
        if (!eval_modifier(eval, n, in, mesh)) return false;
    } else if (n.op == "sdf") {
        if (!eval_sdf(eval, n, in, mesh)) return false;
        if (mesh.empty()) return true;
        probe(eval, n, mesh, in);
        Vec3 bmin, bmax;
        mesh.bounds(bmin, bmax);
        if (n.align == "bottom")
            mesh.transform(Mat4::translate({0, -bmin.y, 0}));
        else if (n.align == "top")
            mesh.transform(Mat4::translate({0, -bmax.y, 0}));
    } else if (n.op == "mesh") {
        if (!build_mesh_node(eval, n, in, mesh)) return false;
        if (mesh.empty()) return true;
        Vec3 bmin, bmax;
        mesh.bounds(bmin, bmax);
        if (n.align == "bottom")
            mesh.transform(Mat4::translate({0, -bmin.y, 0}));
        else if (n.align == "top")
            mesh.transform(Mat4::translate({0, -bmax.y, 0}));
        if (in.color) mesh.set_color(*in.color);
        probe(eval, n, mesh, in);
    } else {
        if (!build_primitive(eval, n, mesh)) return false;
        if (mesh.empty()) return true;
        Vec3 bmin, bmax;
        mesh.bounds(bmin, bmax);
        if (n.align == "bottom")
            mesh.transform(Mat4::translate({0, -bmin.y, 0}));
        else if (n.align == "top")
            mesh.transform(Mat4::translate({0, -bmax.y, 0}));
        if (in.color) mesh.set_color(*in.color);
        mesh.set_part(eval.group_of(in));
        probe(eval, n, mesh, in);
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
    if (!eval_nodes(eval, doc.nodes, {}, mesh))
        return make_error(eval.error, "Fix the node, or set `enabled: false` on it to leave it out.");
    if (mesh.empty())
        return make_error(
            "the model has no triangles: no node made any geometry",
            doc.nodes.empty()
                ? "Add a node, e.g. model.edit {\"add\": {\"op\": \"box\"}}."
                : "Every node is disabled, or a text has no ink. Enable a node or give it something to draw.");
    if (mesh.vertex_count() > (1u << 20) || mesh.indices.size() > (6u << 20))
        return make_error(
            std::format("the model has {} vertices and {} triangles, more than a mesh can hold ({} vertices)",
                        mesh.vertex_count(), mesh.triangle_count(), 1u << 20),
            "Lower `segments` on the round primitives, or use fewer nodes.");

    // The `uv` section replaces every node's own uvs (a primitive's, an sdf's box default) once the model is complete: the settings see the
    // whole merged mesh and the part of each triangle.
    if (doc.uv) {
        std::vector<std::string> partNames;
        for (const auto& g : eval.groups) partNames.push_back(g.part);
        ModelUvOptions uvOptions;
        uvOptions.defaultTexelsPerMeter = options.defaultTexelsPerMeter;
        auto made = model_uv_apply(mesh, partNames, *doc.uv, uvOptions);
        if (!made) return make_error("uv: " + made.error().message, made.error().hint);
        mesh = std::move(made->mesh);
        for (const auto& [name, settings] : doc.uv->parts) {
            if (std::find(partNames.begin(), partNames.end(), name) == partNames.end()) {
                std::vector<std::string> named;
                for (const std::string& n : partNames)
                    if (!n.empty()) named.push_back(n);
                build.warnings.push_back(std::format(
                    "uv.parts names \"{}\", which no node makes: it has no effect. {}", name,
                    named.empty() ? "No node names a part (set `part` on a node)." : did_you_mean(name, named)));
            }
        }
        for (const std::string& w : made->report.warnings) build.warnings.push_back("uv: " + w);
        build.uv = std::move(made->report);
        if (mesh.vertex_count() > (1u << 20))
            return make_error(
                std::format("uv: cutting the model into uv pieces made {} vertices, more than a mesh can hold ({})",
                            mesh.vertex_count(), 1u << 20),
                "Use fewer cuts (`seams`: \"few\") or lower `segments`.");
    }
    // The `vertexColors` section colours the finished mesh (it may split vertices; triangles keep their order and parts).
    if (doc.vertexColors) {
        std::vector<std::string> partNames;
        for (const auto& g : eval.groups) partNames.push_back(g.part);
        ModelVertexColorReport made =
            model_apply_vertex_colors(mesh, partNames, *doc.vertexColors, options.stylePalette);
        for (const std::string& w : made.warnings) build.warnings.push_back("vertexColors: " + w);
        build.vertexColors = std::move(made);
        if (mesh.vertex_count() > (1u << 20))
            return make_error(std::format("vertexColors: giving each triangle its own colour made {} vertices, more "
                                          "than a mesh can hold ({})",
                                          mesh.vertex_count(), 1u << 20),
                              "Turn `flat` off, or lower `segments`.");
    }
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
        build.warnings.push_back(
            std::format("the model has {} triangles, heavy for a game asset: lower `segments`", build.stats.triangles));
    return build;
}

}  // namespace fa
