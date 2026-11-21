#include "fa/scene/lightmap_uv.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <format>
#include <vector>

#include "fa/scene/model_kernel.h"
#include "fa/scene/model_uv.h"

namespace fa {

Result<LightmapUvResult> generate_lightmap_uv(const std::vector<Vec3>& positions, const std::vector<Vec3>& normals,
                                              const std::vector<std::uint32_t>& indices) {
    if (indices.empty() || indices.size() % 3 != 0 || positions.empty())
        return make_error("the mesh has no triangles to unwrap for a lightmap",
                          "A lightmapped mesh needs positions and three indices per triangle.");
    if (!normals.empty() && normals.size() != positions.size())
        return make_error(std::format("the mesh has {} normals for {} positions", normals.size(), positions.size()),
                          "Give one normal per position, or none.");
    if (indices.size() / 3 > kLightmapUvMaxTriangles)
        return make_error(
            std::format("the mesh has {} triangles: a lightmap UV set is made for at most {}", indices.size() / 3,
                        kLightmapUvMaxTriangles),
            "Lightmap a simpler mesh (the model's lods or a decimated copy), or give the glTF its own TEXCOORD_1 "
            "(then nothing is unwrapped).");
    for (std::uint32_t i : indices)
        if (i >= positions.size())
            return make_error(std::format("an index ({}) is past the last of the {} vertices", i, positions.size()),
                              "The mesh's indices must point at its vertices.");
    for (const Vec3& p : positions)
        if (!std::isfinite(p.x) || !std::isfinite(p.y) || !std::isfinite(p.z))
            return make_error("the mesh has a vertex position that is not a finite number",
                              "Fix the mesh: a lightmap cannot be unwrapped from NaN or infinite positions.");

    ModelMesh m;
    m.positions = positions;
    m.indices = indices;
    m.uvs.assign(positions.size(), Vec2{0, 0});
    m.triParts.assign(indices.size() / 3, 0);
    m.colors.resize(positions.size());
    for (std::size_t i = 0; i < positions.size();
         ++i)  // model_uv_apply keeps the colours: they say which vertex each one came from
        m.colors[i] = Vec4{float(i & 0xFFFu), float(i >> 12), 0, 1};
    if (normals.empty()) {
        m.normals.assign(positions.size(), Vec3{0, 1, 0});
    } else {
        m.normals = normals;
    }

    double area = 0;
    for (std::size_t t = 0; t < indices.size(); t += 3) {
        const Vec3 a = positions[indices[t]], b = positions[indices[t + 1]], c = positions[indices[t + 2]];
        const Vec3 n = cross(b - a, c - a);
        area += 0.5 * double(std::sqrt(dot(n, n)));
    }

    ModelUvSettings s;
    s.layout = "atlas";
    s.method = ModelUvMethod::Unwrap;
    s.textureSize = kLightmapUvReferenceSize;
    s.padding = kLightmapUvPadding;
    s.seams = "balanced";
    s.rotate = true;
    // A density a little above the one that fills the square: the packer lowers it until the charts fit, so they use the whole texture.
    const double side = std::sqrt(std::max(area, 1e-12));
    s.texelsPerUnit = float(std::min(1e6, 1.6 * double(kLightmapUvReferenceSize) / side));
    auto r = model_uv_apply(m, {}, s);
    if (!r)
        return make_error("the lightmap UVs could not be made: " + r.error().message,
                          r.error().hint.empty() ? "Check the mesh for zero-area triangles and non-finite positions."
                                                 : r.error().hint);
    const ModelMesh& out = r->mesh;
    LightmapUvResult res;
    res.surfaceArea = area;
    res.utilization = r->report.utilization;
    res.indices = out.indices;
    res.uv.resize(out.positions.size());
    res.source.resize(out.positions.size());
    for (std::size_t i = 0; i < out.positions.size(); ++i) {
        // A triangle with no area (a sphere's pole) is not packed: its uvs are the unwrap's own units, possibly far outside the square. It draws
        // and bakes nothing, so they are only brought inside the square for the "every uv is in 0..1" promise.
        res.uv[i] = {std::clamp(out.uvs[i].x, 0.0f, 1.0f), std::clamp(out.uvs[i].y, 0.0f, 1.0f)};
        if (out.colors.size() != out.positions.size())
            return make_error("the unwrap lost the vertex origin it needs", "This is a bug in generate_lightmap_uv.");
        const std::uint32_t src = std::uint32_t(out.colors[i].x + 0.5f) | (std::uint32_t(out.colors[i].y + 0.5f) << 12);
        if (src >= positions.size())
            return make_error("the unwrap returned a vertex of no input vertex",
                              "This is a bug in generate_lightmap_uv.");
        res.source[i] = src;
    }
    return res;
}

}  // namespace fa
