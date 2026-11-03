// The UV maker's front door: the settings, and model_uv_apply, which projects or unwraps each part, packs or tiles the charts and measures
// what came out. The pieces are model_uv_project.cpp (projections), model_uv_pack.cpp (xatlas) and model_uv_measure.cpp.
#include "fa/scene/model_uv.h"

#include <algorithm>
#include <cmath>
#include <format>

#include "model_uv_internal.h"

namespace fa {

const std::vector<std::string>& model_uv_method_names() {
    static const std::vector<std::string> names = {"unwrap", "box", "cylinder", "sphere", "planar"};
    return names;
}

const char* model_uv_method_name(ModelUvMethod method) {
    switch (method) {
        case ModelUvMethod::Unwrap: return "unwrap";
        case ModelUvMethod::Box: return "box";
        case ModelUvMethod::Cylinder: return "cylinder";
        case ModelUvMethod::Sphere: return "sphere";
        case ModelUvMethod::Planar: return "planar";
    }
    return "unwrap";
}

const ModelUvPartSettings* ModelUvSettings::part_settings(const std::string& part) const {
    for (const auto& [name, s] : parts)
        if (name == part) return &s;
    return nullptr;
}

ModelUvMethod ModelUvSettings::method_of(const std::string& part) const {
    if (const ModelUvPartSettings* p = part_settings(part); p && p->method) return *p->method;
    if (method) return *method;
    return layout == "tile" ? ModelUvMethod::Box : ModelUvMethod::Unwrap;
}

char ModelUvSettings::axis_of(const std::string& part) const {
    if (const ModelUvPartSettings* p = part_settings(part); p && p->axis) return *p->axis;
    return axis;
}

Json model_uv_settings_json(const ModelUvSettings& s) {
    Json j = Json::object();
    j["layout"] = s.layout;
    if (s.method) j["method"] = model_uv_method_name(*s.method);
    j["axis"] = std::string(1, s.axis);
    if (s.texelsPerUnit) j["texelsPerUnit"] = *s.texelsPerUnit;
    if (s.textureSize > 0) j["textureSize"] = s.textureSize;
    j["padding"] = s.padding;
    j["seams"] = s.seams;
    if (s.rotate) j["rotate"] = *s.rotate;
    if (!s.parts.empty()) {
        Json parts = Json::object();
        for (const auto& [name, p] : s.parts) {
            Json o = Json::object();
            if (p.method) o["method"] = model_uv_method_name(*p.method);
            if (p.axis) o["axis"] = std::string(1, *p.axis);
            if (p.texelsPerUnit) o["texelsPerUnit"] = *p.texelsPerUnit;
            parts[name] = o;
        }
        j["parts"] = parts;
    }
    return j;
}

Result<ModelUvResult> model_uv_apply(const ModelMesh& mesh, const std::vector<std::string>& partNames, const ModelUvSettings& settings, const ModelUvOptions& options) {
    using namespace uv;
    if (mesh.empty()) return make_error("the mesh has no triangles to give uvs", "Evaluate a model that makes geometry first.");
    if (mesh.triParts.size() != mesh.triangle_count() && !mesh.triParts.empty())
        return make_error("the mesh's triParts does not have one entry per triangle", "This is a bug in the caller of model_uv_apply.");
    const bool tile = settings.layout == "tile";
    if (!tile && settings.layout != "atlas") return make_error("layout must be \"atlas\" or \"tile\", got \"" + settings.layout + "\"", "Use \"atlas\" for a texture painted for this model, \"tile\" for a seamless repeating one.");
    if (settings.textureSize != 0 && (settings.textureSize < kModelUvMinTextureSize || settings.textureSize > kModelUvMaxTextureSize))
        return make_error(std::format("textureSize {} is outside {} to {}", settings.textureSize, kModelUvMinTextureSize, kModelUvMaxTextureSize), "Use a power of two such as 512, 1024 or 2048, or 0 to let it be chosen.");
    if (settings.padding < 0 || settings.padding > kModelUvMaxPadding) return make_error(std::format("padding {} is outside 0 to {}", settings.padding, kModelUvMaxPadding), "2 to 4 texels is usual.");

    ModelMesh source = mesh;
    if (source.triParts.empty()) source.triParts.assign(source.triangle_count(), 0);
    Work w = make_work(source, partNames);
    const float baseDensity = settings.texelsPerUnit ? *settings.texelsPerUnit : options.defaultTexelsPerMeter > 0 ? std::max(1.0f, options.defaultTexelsPerMeter) : kModelUvDefaultTexelsPerMeter;
    if (!(baseDensity > 0)) return make_error("texelsPerUnit must be above 0", "Pixels of texture per metre of surface, e.g. 128.");

    const std::size_t partCount = w.names.size();
    std::vector<std::vector<std::uint32_t>> tris(partCount);
    for (std::size_t t = 0; t < w.triangle_count(); ++t) tris[w.part[t]].push_back(std::uint32_t(t));
    std::vector<ModelUvMethod> methods(partCount);
    std::vector<float> density(partCount);
    bool anyProjection = false;
    std::vector<std::vector<std::uint32_t>> unwrapTris(partCount);
    for (std::size_t p = 0; p < partCount; ++p) {
        const std::string& name = w.names[p];
        methods[p] = settings.method_of(name);
        const ModelUvPartSettings* ps = settings.part_settings(name);
        density[p] = ps && ps->texelsPerUnit ? *ps->texelsPerUnit : baseDensity;
        if (methods[p] == ModelUvMethod::Unwrap) {
            if (tile)
                return make_error("part \"" + name + "\" is set to unwrap, but a tiling texture cannot be cut and packed",
                                  "Give it a projection (\"box\", \"cylinder\", \"sphere\" or \"planar\") in uv.parts, or use layout \"atlas\".");
            unwrapTris[p] = tris[p];
        } else {
            anyProjection = true;
        }
    }
    auto unwrapped = unwrap_parts(w, unwrapTris, baseDensity, settings.seams);
    if (!unwrapped) return unwrapped.error();
    for (std::size_t p = 0; p < partCount; ++p) {
        if (tris[p].empty()) continue;
        const char axis = settings.axis_of(w.names[p]);
        switch (methods[p]) {
            case ModelUvMethod::Unwrap: break;
            case ModelUvMethod::Box: project_box(w, tris[p]); break;
            case ModelUvMethod::Planar: project_planar(w, tris[p], axis); break;
            case ModelUvMethod::Cylinder: project_cylinder(w, tris[p], axis); break;
            case ModelUvMethod::Sphere: project_sphere(w, tris[p], axis); break;
        }
    }

    ModelUvResult result;
    int textureSize = settings.textureSize;
    double shrink = 1;
    if (tile) {
        if (textureSize == 0) textureSize = 1024;
        tile_uvs(w, density, textureSize);
    } else {
        PackRequest request;
        request.texelsPerMeter = density;
        request.textureSize = settings.textureSize;
        request.padding = settings.padding;
        request.rotate = settings.rotate ? *settings.rotate : !anyProjection;
        auto packed = pack_atlas(w, request);
        if (!packed) return packed.error();
        textureSize = packed->textureSize;
        shrink = packed->shrink;
    }
    result.mesh = rebuild_mesh(w);
    result.report = model_uv_measure(result.mesh, partNames, settings.layout, textureSize);
    ModelUvReport& r = result.report;
    r.texelsPerUnit = baseDensity;
    r.texelsPerUnitUsed = baseDensity * shrink;
    for (ModelUvPartReport& pr : r.parts)
        for (std::size_t p = 0; p < partCount; ++p)
            if (w.names[p] == pr.part) pr.method = model_uv_method_name(methods[p]);
    if (shrink < 0.999)
        r.warnings.insert(r.warnings.begin(), std::format("the charts did not fit a {0}x{0} texture at {1:g} texels per metre: the density was lowered to {2:.1f} for every part. Raise `textureSize` or lower `texelsPerUnit`.",
                                                           textureSize, baseDensity, baseDensity * shrink));
    return result;
}

}  // namespace fa
