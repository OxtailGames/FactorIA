// The `vertexColors` section of a model document: low-poly colour with no texture. Style palette (or a list of colours), per-part colours,
// gradients along an axis, one colour per triangle for the faceted look, and a hash-based brightness variation. Deterministic: the only
// "random" input is an integer hash of the seed and the triangle or vertex number.
#include <algorithm>
#include <cmath>
#include <format>
#include <map>
#include <set>

#include "fa/core/strings.h"
#include "fa/scene/model_texture.h"

namespace fa {

namespace {

std::uint32_t mix32(std::uint64_t x) {
    x += 0x9e3779b97f4a7c15ull;
    x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9ull;
    x = (x ^ (x >> 27)) * 0x94d049bb133111ebull;
    x ^= x >> 31;
    return std::uint32_t(x >> 32);
}
// -1..1 from (seed, key)
float hash_signed(int seed, std::uint64_t key) {
    const std::uint32_t h = mix32((std::uint64_t(std::uint32_t(seed)) << 32) ^ key);
    return float(h) / 2147483648.0f - 1.0f;
}

struct Extent {
    float lo = 0, hi = 0;
    bool any = false;
};

}  // namespace

ModelVertexColorReport model_apply_vertex_colors(ModelMesh& mesh, const std::vector<std::string>& partNames,
                                                 const ModelVertexColors& settings,
                                                 const std::vector<Vec4>& stylePalette) {
    ModelVertexColorReport rep;
    rep.verticesBefore = rep.verticesAfter = mesh.vertex_count();
    const std::vector<Vec4>& palette = settings.style ? stylePalette : settings.palette;
    rep.paletteSize = palette.size();
    if (settings.style && stylePalette.empty())
        rep.warnings.push_back(
            "vertexColors.palette is \"style\" but the project's style guide has no palette (assets.json "
            "style.palette): colours are used as written. Run `style.set` with a palette, or list the colours here.");

    auto part_name = [&](std::uint32_t group) -> const std::string& {
        static const std::string none;
        return group < partNames.size() ? partNames[group] : none;
    };
    auto spec_of = [&](const std::string& name) -> const ModelPartColors* {
        for (const auto& [n, pc] : settings.parts)
            if (n == name) return &pc;
        return nullptr;
    };
    // parts the section names that no triangle has
    {
        std::set<std::string> present;
        for (std::uint32_t g : mesh.triParts) present.insert(part_name(g));
        for (const auto& [n, pc] : settings.parts)
            if (!present.count(n)) {
                std::vector<std::string> named;
                for (const std::string& p : present)
                    if (!p.empty()) named.push_back(p);
                rep.warnings.push_back(std::format(
                    "vertexColors.parts names \"{}\", which no node makes: it has no effect. {}", n,
                    named.empty() ? "No node names a part (set `part` on a node)." : did_you_mean(n, named)));
            }
    }
    bool anyWork = settings.color.has_value() || settings.variation > 0;
    for (const auto& [n, pc] : settings.parts)
        anyWork = anyWork || pc.color || pc.gradient || (pc.variation && *pc.variation > 0);
    if (!anyWork || mesh.empty()) return rep;

    auto resolve = [&](const ModelColorRef& c) -> Vec4 {
        if (!c.isIndex) return c.rgba;
        if (palette.empty()) return Vec4{1, 1, 1, 1};
        return palette[std::size_t(c.index) % palette.size()];
    };
    auto snap = [&](Vec4 c) -> Vec4 {
        if (!settings.snap || palette.empty()) return c;
        float best = 1e30f;
        Vec4 pick = palette[0];
        for (const Vec4& p : palette) {
            const float d = (p.x - c.x) * (p.x - c.x) + (p.y - c.y) * (p.y - c.y) + (p.z - c.z) * (p.z - c.z);
            if (d < best) {
                best = d;
                pick = p;
            }
        }
        return Vec4{pick.x, pick.y, pick.z, c.w};
    };
    auto lerp4 = [](Vec4 a, Vec4 b, float t) { return a + (b - a) * t; };

    // the extent of each part along the axes (gradients default to it)
    std::map<std::string, Extent[3]> extents;
    for (std::size_t t = 0; t < mesh.triangle_count(); ++t) {
        const std::string& name = part_name(mesh.triParts[t]);
        const ModelPartColors* sp = spec_of(name);
        if (!sp || !sp->gradient) continue;
        auto& e = extents[name];
        for (int k = 0; k < 3; ++k) {
            const Vec3 p = mesh.positions[mesh.indices[t * 3 + k]];
            for (int a = 0; a < 3; ++a) {
                Extent& ex = e[a];
                if (!ex.any) {
                    ex.lo = ex.hi = p[a];
                    ex.any = true;
                } else {
                    ex.lo = std::min(ex.lo, p[a]);
                    ex.hi = std::max(ex.hi, p[a]);
                }
            }
        }
    }

    // the colour a spot of a part gets from the section (before the node colour and the variation)
    auto spec_color = [&](const std::string& name, Vec3 at, bool& has) -> Vec4 {
        has = false;
        const ModelPartColors* sp = spec_of(name);
        if (sp && sp->gradient) {
            const ModelColorGradient& g = *sp->gradient;
            const int a = g.axis - 'x';
            float lo = 0, hi = 1;
            if (g.range) {
                lo = g.range->first;
                hi = g.range->second;
            } else {
                const Extent& ex = extents[name][a];
                lo = ex.lo;
                hi = ex.hi;
            }
            float t = hi - lo > 1e-9f ? (at[a] - lo) / (hi - lo) : 0.0f;
            t = std::clamp(t, 0.0f, 1.0f);
            Vec4 c;
            if (g.via) {
                const Vec4 v = resolve(*g.via);
                c = t < 0.5f ? lerp4(resolve(g.from), v, t * 2) : lerp4(v, resolve(g.to), (t - 0.5f) * 2);
            } else
                c = lerp4(resolve(g.from), resolve(g.to), t);
            has = true;
            return snap(c);
        }
        if (sp && sp->color) {
            has = true;
            return snap(resolve(*sp->color));
        }
        if (!sp && settings.color) {
            has = true;
            return snap(resolve(*settings.color));
        }
        return Vec4{1, 1, 1, 1};
    };
    auto variation_of = [&](const std::string& name) {
        const ModelPartColors* sp = spec_of(name);
        return sp && sp->variation ? *sp->variation : settings.variation;
    };

    ModelMesh out;
    out.triParts = mesh.triParts;
    const bool hadColors = !mesh.colors.empty();
    std::map<std::pair<std::uint32_t, std::uint32_t>, std::uint32_t> remap;  // (old vertex, group) -> new vertex
    out.indices.reserve(mesh.indices.size());
    std::set<std::uint32_t> distinct;
    auto push_vertex = [&](std::uint32_t old, Vec4 color) {
        out.positions.push_back(mesh.positions[old]);
        if (!mesh.normals.empty()) out.normals.push_back(mesh.normals[old]);
        if (!mesh.uvs.empty()) out.uvs.push_back(mesh.uvs[old]);
        out.colors.push_back(color);
        auto q = [](float v) { return std::uint32_t(std::lround(std::clamp(v, 0.0f, 1.0f) * 255.0f)); };
        distinct.insert(q(color.x) | (q(color.y) << 8) | (q(color.z) << 16) | (q(color.w) << 24));
        return std::uint32_t(out.positions.size() - 1);
    };
    auto finish_color = [&](Vec4 base, Vec4 spec, float variation, float j) {
        const float f = 1.0f + j * variation;
        return Vec4{std::clamp(base.x * spec.x * f, 0.0f, 1.0f), std::clamp(base.y * spec.y * f, 0.0f, 1.0f),
                    std::clamp(base.z * spec.z * f, 0.0f, 1.0f), std::clamp(base.w * spec.w, 0.0f, 1.0f)};
    };
    for (std::size_t t = 0; t < mesh.triangle_count(); ++t) {
        const std::uint32_t group = mesh.triParts[t];
        const std::string& name = part_name(group);
        const float variation = variation_of(name);
        bool has = false;
        if (settings.flat) {
            const Vec3 centre = (mesh.positions[mesh.indices[t * 3]] + mesh.positions[mesh.indices[t * 3 + 1]] +
                                 mesh.positions[mesh.indices[t * 3 + 2]]) /
                                3.0f;
            const Vec4 spec = spec_color(name, centre, has);
            if (has) ++rep.coloredTriangles;
            const float j = variation > 0 ? hash_signed(settings.seed, t) : 0.0f;
            for (int k = 0; k < 3; ++k) {
                const std::uint32_t old = mesh.indices[t * 3 + k];
                const Vec4 base = hadColors ? mesh.colors[old] : Vec4{1, 1, 1, 1};
                out.indices.push_back(push_vertex(old, finish_color(base, spec, variation, j)));
            }
        } else {
            bool anyHas = false;
            for (int k = 0; k < 3; ++k) {
                const std::uint32_t old = mesh.indices[t * 3 + k];
                auto key = std::make_pair(old, group);
                auto it = remap.find(key);
                if (it == remap.end()) {
                    const Vec4 spec = spec_color(name, mesh.positions[old], has);
                    anyHas = anyHas || has;
                    const float j =
                        variation > 0 ? hash_signed(settings.seed, (std::uint64_t(old) << 20) ^ group) : 0.0f;
                    const Vec4 base = hadColors ? mesh.colors[old] : Vec4{1, 1, 1, 1};
                    it = remap.emplace(key, push_vertex(old, finish_color(base, spec, variation, j))).first;
                } else
                    spec_color(name, mesh.positions[old], has), anyHas = anyHas || has;
                out.indices.push_back(it->second);
            }
            if (anyHas) ++rep.coloredTriangles;
        }
    }
    rep.verticesAfter = out.vertex_count();
    rep.distinctColors = distinct.size();
    mesh = std::move(out);
    return rep;
}

}  // namespace fa
