#include "material_cost.h"

#include <algorithm>
#include <cmath>
#include <string>

#include "mesh_batch.h"
#include "render_scene.h"
#include "renderer_xmit.h"

namespace fa::render {

namespace {

bool positive(float v) { return std::isfinite(v) && v > 0.0f; }

// True when the MeshRenderer or any part of the model has the layer (a MeshRenderer field that is not at its default replaces the model's, so
// either one switches it on; the renderer reads both, renderer_draw.cpp fill_layers).
template <class Pred>
bool any_part(const MeshAsset* mesh, Pred&& pred) {
    if (!mesh) return false;
    for (const SubMesh& p : mesh->parts)
        if (pred(p.layers)) return true;
    return false;
}

Json feature(const char* name, const char* field, bool active, const char* cost, int extraPasses,
             const std::string& note) {
    return Json::object({{"name", name},
                         {"field", field},
                         {"active", active},
                         {"cost", cost},
                         {"extraPasses", extraPasses},
                         {"note", note}});
}

}  // namespace

Json material_cost_report(const MeshRenderer& mr, const MeshAsset* mesh, const MaterialAsset* material, int targetW,
                          int targetH) {
    const bool full = material && material->full;
    const bool transmissive = mesh ? mesh_is_transmissive(mr, *mesh, material) : (!full && positive(mr.transmission));
    const bool blended = mesh ? mesh_is_blended(mr, *mesh, material)
                              : (transmissive || (material ? material->alphaMode == "blend" : mr.color.a < 0.999f));
    // The copy: a pass for each reduced half (levels - 1), one that writes the atlas, and the second half of the main pass.
    int levels = kXmitMaxLevels;
    if (targetW > 0 && targetH > 0) levels = std::max(xmit_layout(targetW, targetH).levels, 1);
    const int copyPasses = levels + 1;
    const int materialPasses = full ? std::max(int(material->passes.size()), 1) : 1;

    Json features = Json::array();
    features.push_back(
        feature("transmission", "transmission", transmissive, "extraPass", transmissive ? copyPasses : 0,
                transmissive ? "Copies the opaque picture once per camera (" + std::to_string(levels - 1) +
                                   " reduced halves and the atlas, and the main pass "
                                   "is split in two), however many transmissive meshes there are; the mesh is then "
                                   "drawn with the blended ones, far to near, "
                                   "without writing depth. A frame with no visible transmissive mesh pays nothing."
                             : "Off: no copy of the picture. transmission above 0 (or a glTF transmission factor) "
                               "makes the mesh look through the opaque "
                               "picture, at the price of a copy of it."));
    features.push_back(
        feature("blended", "color", blended && !transmissive, "phase", 0,
                blended && !transmissive
                    ? "Drawn after the opaque meshes, far to near, without writing depth (a translucent colour, "
                      "alphaMode blend or a blended "
                      "glTF part): no extra pass, but it does not take part in the depth effects of the opaque phase."
                    : "Off (opaque, or transmissive: see transmission)."));
    features.push_back(feature("multiPass", "material", materialPasses > 1, "extraPass", materialPasses - 1,
                               materialPasses > 1 ? "A full-shader material draws the mesh once per pass (" +
                                                        std::to_string(materialPasses) +
                                                        " passes): each one draws all its triangles again."
                                                  : "Off: one draw per part."));
    const bool coat = !full && (positive(mr.clearcoat) ||
                                any_part(mesh, [](const MaterialLayers& l) { return positive(l.clearcoat); }));
    const bool sheen = !full && (mr.sheenColor.r > 0.0f || mr.sheenColor.g > 0.0f || mr.sheenColor.b > 0.0f ||
                                 any_part(mesh, [](const MaterialLayers& l) {
                                     return l.sheenColor[0] > 0.0f || l.sheenColor[1] > 0.0f || l.sheenColor[2] > 0.0f;
                                 }));
    const bool aniso = !full && ((std::isfinite(mr.anisotropy) && mr.anisotropy != 0.0f) ||
                                 any_part(mesh, [](const MaterialLayers& l) { return l.anisotropy != 0.0f; }));
    features.push_back(
        feature("clearCoat", "clearcoat", coat, "shader", 0,
                coat ? "A second specular lobe in the fragment shader: more work per pixel, no extra pass."
                     : "Off (clearcoat 0)."));
    features.push_back(feature("sheen", "sheenColor", sheen, "shader", 0,
                               sheen ? "A cloth lobe in the fragment shader: more work per pixel, no extra pass."
                                     : "Off (sheenColor black)."));
    features.push_back(feature("anisotropy", "anisotropy", aniso, "shader", 0,
                               aniso
                                   ? "A stretched highlight in the fragment shader: more work per pixel, no extra pass."
                                   : "Off (anisotropy 0)."));

    // The subsurface scattering (M73.5, renderer_subsurface.h): the same test as sss_scatters in renderer_draw.cpp (a mesh with the engine's own
    // lighting, lit, with a strength above 0). It draws the mesh again (sss-draw) and blurs its light (sss-blur-h, sss-blur-v, sss-add), once per
    // camera that sees such a mesh, on a GPU with RGBA16F targets (render.supports "subsurface").
    const bool scatters = !material && !mr.unlit && subsurface_of(mr)[0] > 0.0f;
    features.push_back(
        feature("subsurface", "subsurface", scatters, "extraPass", scatters ? 4 : 0,
                scatters ? "Draws the mesh again into a light image and blurs it: sss-draw, sss-blur-h, sss-blur-v and "
                           "sss-add, once per camera that sees such a mesh (only on a GPU with RGBA16F targets)."
                         : "Off (subsurface 0, an unlit mesh, or a material of its own)."));

    int extra = 0;
    std::string summary;
    int active = 0;
    for (const Json& f : features) {
        if (!f["active"].get<bool>()) continue;
        ++active;
        extra += f["extraPasses"].get<int>();
        if (!summary.empty()) summary += ", ";
        summary += f["name"].get<std::string>();
        if (f["extraPasses"].get<int>() > 0)
            summary += " (+" + std::to_string(f["extraPasses"].get<int>()) + " passes)";
    }
    summary = active == 0 ? "No extra passes: one draw of the opaque phase."
                          : summary + (extra > 0 ? "" : ": no extra passes");
    if (extra > 0) summary += "; " + std::to_string(extra) + " extra passes in all";
    return Json::object({{"extraPasses", extra},
                         {"phase", blended ? "blended" : "opaque"},
                         {"summary", summary},
                         {"features", features}});
}

}  // namespace fa::render
