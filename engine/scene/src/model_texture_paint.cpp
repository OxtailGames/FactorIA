// Texturing, the painting half: the layers of a model's texture (base colour with triplanar textures and vertex colours, decals, wear built from
// the baked maps, occlusion, a uv wireframe) and the maps alone. CPU only, serial, deterministic.
#include <algorithm>
#include <cmath>
#include <format>
#include <limits>
#include <map>
#include <set>

#include "fa/core/strings.h"
#include "fa/scene/model_select.h"
#include "model_texture_internal.h"

namespace fa {

namespace {

using namespace mt;

constexpr float kNaN = std::numeric_limits<float>::quiet_NaN();

std::uint8_t to_byte(float v) { return std::uint8_t(std::lround(saturate(v) * 255.0f)); }

Image make_image(int size, std::uint8_t r, std::uint8_t g, std::uint8_t b, std::uint8_t a) {
    Image img;
    img.width = img.height = size;
    img.rgba.resize(std::size_t(size) * std::size_t(size) * 4);
    for (std::size_t i = 0; i < img.rgba.size(); i += 4) {
        img.rgba[i] = r;
        img.rgba[i + 1] = g;
        img.rgba[i + 2] = b;
        img.rgba[i + 3] = a;
    }
    return img;
}
void put(Image& img, std::size_t i, Vec4 c) {
    img.rgba[i * 4] = to_byte(c.x);
    img.rgba[i * 4 + 1] = to_byte(c.y);
    img.rgba[i * 4 + 2] = to_byte(c.z);
    img.rgba[i * 4 + 3] = to_byte(c.w);
}
Vec4 get(const Image& img, std::size_t i) {
    return {img.rgba[i * 4] / 255.0f, img.rgba[i * 4 + 1] / 255.0f, img.rgba[i * 4 + 2] / 255.0f,
            img.rgba[i * 4 + 3] / 255.0f};
}
// `src` over what is in the pixel (straight alpha)
void over(Image& img, std::size_t i, Vec3 rgb, float alpha) {
    if (alpha <= 0) return;
    const Vec4 d = get(img, i);
    const float a = alpha + d.w * (1 - alpha);
    if (a <= 0) return;
    const Vec3 c = (rgb * alpha + d.xyz() * (d.w * (1 - alpha))) / a;
    put(img, i, Vec4(c, a));
}

// Bilinear sample of an image at (u, v) in 0..1 (v down), premultiplied so the colour of transparent pixels does not leak; wrap or clamp.
Vec4 sample_image(const Image& img, float u, float v, bool wrap) {
    const float x = u * float(img.width) - 0.5f, y = v * float(img.height) - 0.5f;
    const float fx = std::floor(x), fy = std::floor(y);
    const float tx = x - fx, ty = y - fy;
    const int x0 = int(fx), y0 = int(fy);
    auto at = [&](int xx, int yy) {
        if (wrap) {
            xx = ((xx % img.width) + img.width) % img.width;
            yy = ((yy % img.height) + img.height) % img.height;
        } else {
            xx = std::clamp(xx, 0, img.width - 1);
            yy = std::clamp(yy, 0, img.height - 1);
        }
        return get(img, std::size_t(yy) * std::size_t(img.width) + std::size_t(xx));
    };
    const Vec4 c00 = at(x0, y0), c10 = at(x0 + 1, y0), c01 = at(x0, y0 + 1), c11 = at(x0 + 1, y0 + 1);
    const float w00 = (1 - tx) * (1 - ty), w10 = tx * (1 - ty), w01 = (1 - tx) * ty, w11 = tx * ty;
    const float a = c00.w * w00 + c10.w * w10 + c01.w * w01 + c11.w * w11;
    if (a <= 1e-6f) return {0, 0, 0, 0};
    const Vec3 rgb = (c00.xyz() * (c00.w * w00) + c10.xyz() * (c10.w * w10) + c01.xyz() * (c01.w * w01) +
                      c11.xyz() * (c11.w * w11)) /
                     a;
    return Vec4(rgb, a);
}

Vec4 mul4(Vec4 a, Vec4 b) { return {a.x * b.x, a.y * b.y, a.z * b.z, a.w * b.w}; }

float pow_int(float v, int k) {
    float r = 1;
    for (int i = 0; i < k; ++i) r *= v;
    return r;
}

Vec4 sample_triplanar(const Image& img, Vec3 p, Vec3 n, const ModelMaterialTexturing& m) {
    float wx = pow_int(std::fabs(n.x), m.sharpness), wy = pow_int(std::fabs(n.y), m.sharpness),
          wz = pow_int(std::fabs(n.z), m.sharpness);
    const float sum = wx + wy + wz;
    if (sum < 1e-9f) {
        wx = wz = 0;
        wy = 1;
    } else {
        wx /= sum;
        wy /= sum;
        wz /= sum;
    }
    const float inv = 1.0f / m.scale;
    const Vec3 q = p + m.offset;
    Vec3 rgb{0, 0, 0};
    float alpha = 0;
    auto add = [&](float w, float u, float v) {
        if (w < 1e-4f) return;
        const Vec4 c = sample_image(img, u * inv, v * inv, true);
        rgb += c.xyz() * (c.w * w);
        alpha += c.w * w;
    };
    add(wx, q.z, -q.y);
    add(wy, q.x, q.z);
    add(wz, q.x, -q.y);
    if (alpha <= 1e-6f) return {0, 0, 0, 0};
    return Vec4(rgb / alpha, alpha);
}

struct MapStats {
    double mean = 0, min = 0, max = 0, coverage = 0;
};
// over the texels a triangle covers itself (not the bleed); `neutral`: the value a map has where it says nothing; `eps`: how far from it counts
MapStats stats_of(const std::vector<float>& v, const Texels& t, float neutral, float eps) {
    MapStats s;
    std::size_t n = 0, off = 0;
    s.min = 1e30;
    s.max = -1e30;
    for (std::size_t i = 0; i < v.size(); ++i) {
        if (!t.has(i) || t.bled[i] || std::isnan(v[i])) continue;
        ++n;
        s.mean += v[i];
        s.min = std::min<double>(s.min, v[i]);
        s.max = std::max<double>(s.max, v[i]);
        if (std::fabs(v[i] - neutral) > eps) ++off;
    }
    if (n == 0) return {};
    s.mean /= double(n);
    s.coverage = double(off) / double(n);
    return s;
}

struct Params {
    float aoDistance, thickDistance, edgeWidth;
};
Params params_of(const ModelMapSettings& m, const Geo& g) {
    Params p;
    p.aoDistance = m.distance > 0 ? m.distance : 0.15f * g.diag;
    p.thickDistance = m.thicknessDistance > 0 ? m.thicknessDistance : 0.5f * g.diag;
    p.edgeWidth = m.edgeWidth > 0 ? m.edgeWidth : 0.03f * g.diag;
    return p;
}

// The curvature map: 0.5 flat, up for convex, down for concave.
std::vector<float> curvature_map(const Geo& g, const EdgeIndex& edges, const Texels& t, float width) {
    std::vector<float> out(t.tri.size(), kNaN);
    for (std::size_t i = 0; i < out.size(); ++i) {
        if (!t.has(i)) continue;
        float cv, cc;
        edges.bands(texel_point(g, t, i), width, cv, cc);
        const float soft = std::clamp(edges.curvature(g, t, i) * width * 0.5f, -1.0f, 1.0f);
        cv = std::max(cv, std::max(0.0f, soft));
        cc = std::max(cc, std::max(0.0f, -soft));
        out[i] = 0.5f + 0.5f * (cv - cc);
    }
    return out;
}

Image grey_image(const std::vector<float>& v, int size, float neutral) {
    Image img = make_image(size, 0, 0, 0, 255);
    for (std::size_t i = 0; i < v.size(); ++i) {
        const std::uint8_t b = to_byte(std::isnan(v[i]) ? neutral : v[i]);
        img.rgba[i * 4] = img.rgba[i * 4 + 1] = img.rgba[i * 4 + 2] = b;
    }
    return img;
}

std::vector<std::string> unknown_names(const std::vector<std::string>& wanted, const std::set<std::string>& have) {
    std::vector<std::string> out;
    for (const std::string& w : wanted)
        if (!have.count(w)) out.push_back(w);
    return out;
}

void line(Image& img, int x0, int y0, int x1, int y1, Vec4 c) {
    const int dx = std::abs(x1 - x0), dy = -std::abs(y1 - y0);
    const int sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1;
    int err = dx + dy;
    for (int guard = 0; guard < 20000; ++guard) {
        if (x0 >= 0 && y0 >= 0 && x0 < img.width && y0 < img.height)
            put(img, std::size_t(y0) * std::size_t(img.width) + std::size_t(x0), c);
        if (x0 == x1 && y0 == y1) break;
        const int e2 = 2 * err;
        if (e2 >= dy) {
            err += dy;
            x0 += sx;
        }
        if (e2 <= dx) {
            err += dx;
            y0 += sy;
        }
    }
}

}  // namespace

Result<ModelTextureLayers> bake_model_textures(const ModelTextureInput& in) {
    if (!in.mesh || !in.settings)
        return make_error("bake_model_textures needs a mesh and the texturing settings",
                          "This is a bug of the caller.");
    const MeshData& mesh = *in.mesh;
    const ModelTexturing& S = *in.settings;
    if (!mesh.hasUvs)
        return make_error("the model has no uvs to bake a texture into",
                          "Add a `uv` section with layout \"atlas\" (model.uv, or model.texture adds one).");
    int size = S.size > 0 ? S.size : (in.uvTextureSize > 0 ? in.uvTextureSize : 1024);
    if (size < kModelTextureMinSize || size > kModelTextureMaxSize)
        return make_error(
            std::format("the texture size {} is outside {} to {}", size, kModelTextureMinSize, kModelTextureMaxSize),
            "Set texturing.size to a power of two such as 1024.");
    const int bleed = S.bleed >= 0 ? S.bleed : in.uvPadding;

    ModelTextureLayers out;
    out.size = size;
    ModelTextureReport& rep = out.report;
    rep.size = size;
    rep.bleed = bleed;
    Geo g = make_geo(mesh);
    const Params prm = params_of(S.maps, g);
    Texels tx = rasterize(g, size, bleed);
    if (tx.covered == 0)
        return make_error("no triangle covers a texel of the atlas: the uvs are empty or outside 0..1",
                          "Check the `uv` section (model.uv check:true measures it).");
    rep.texels = tx.covered;
    rep.utilization = double(tx.covered) / (double(size) * double(size));
    rep.overlap = double(tx.overlapped) / double(tx.covered);
    {
        std::size_t outside = 0;
        for (std::size_t t = 0; t < g.tri.size(); ++t)
            for (int k = 0; k < 3; ++k) {
                const Vec2 uv = g.uv[g.tri[t][std::size_t(k)]];
                if (uv.x < -0.001f || uv.x > 1.001f || uv.y < -0.001f || uv.y > 1.001f) {
                    ++outside;
                    break;
                }
            }
        if (outside)
            rep.warnings.push_back(std::format("{} triangle(s) have uvs outside 0..1 and are cut off in the texture: "
                                               "the atlas layout of the `uv` section is needed (model.uv).",
                                               outside));
        if (rep.overlap > 0.02)
            rep.warnings.push_back(
                std::format("{:.1f}% of the covered texels are claimed by two triangles (overlapping uvs): painting "
                            "there shows on both. Unwrap the model (`uv` method \"unwrap\").",
                            rep.overlap * 100));
    }

    // ---- materials of the submeshes
    struct MatInfo {
        Vec4 color{1, 1, 1, 1};
        ModelMaterialTexturing m;
        const Image* image = nullptr;
        std::string texture;
        std::string part, material;
        std::size_t texels = 0;
    };
    std::map<std::string, Image> loaded;
    std::set<std::string> inputs;
    auto load = [&](const std::string& path, const std::string& what) -> Result<const Image*> {
        auto it = loaded.find(path);
        if (it != loaded.end()) return &it->second;
        if (!in.images)
            return make_error(what + " \"" + path + "\" cannot be read: no image source",
                              "This is a bug of the caller.");
        auto img = in.images(path);
        if (!img.ok())
            return make_error(what + " \"" + path + "\": " + img.error().message,
                              img.error().hint.empty()
                                  ? "Use a png or jpg of the project (assets.generate_texture makes one)."
                                  : img.error().hint);
        inputs.insert(path);
        return &loaded.emplace(path, std::move(*img)).first->second;
    };
    std::vector<MatInfo> mats(mesh.submeshes.size());
    for (std::size_t s = 0; s < mesh.submeshes.size(); ++s) {
        const MeshSubmesh& sm = mesh.submeshes[s];
        MatInfo& mi = mats[s];
        mi.color = {sm.material.color.r, sm.material.color.g, sm.material.color.b, sm.material.color.a};
        mi.part = sm.part;
        mi.material = sm.material.name;
        for (const auto& [name, m] : in.mappings)
            if (name == sm.material.name) mi.m = m;
        if (!sm.material.texture.empty()) {
            auto img = load(sm.material.texture, "the texture of material \"" + sm.material.name + "\"");
            if (!img.ok()) return img.error();
            mi.image = *img;
            mi.texture = sm.material.texture;
        }
        mi.color = mul4(mi.color, mi.m.tint);
    }
    std::set<std::string> partNames, materialNames;
    for (const MeshSubmesh& sm : mesh.submeshes) partNames.insert(sm.part);
    for (const MeshSubmesh& sm : mesh.submeshes) materialNames.insert(sm.material.name);
    auto check_parts = [&](const std::vector<std::string>& wanted, const std::string& where) {
        std::vector<std::string> have;
        for (const std::string& p : partNames)
            if (!p.empty()) have.push_back(p);
        for (const std::string& w : unknown_names(wanted, partNames))
            rep.warnings.push_back(
                std::format("{} names the part \"{}\", which the model does not have: it has no effect. {}", where, w,
                            have.empty() ? "No node names a part." : did_you_mean(w, have)));
    };

    const std::size_t total = tx.tri.size();
    const bool bakeColors = S.vertexColors == "bake" && !g.col.empty();

    // ---- base colour
    out.base = make_image(size, to_byte(S.background.x), to_byte(S.background.y), to_byte(S.background.z),
                          to_byte(S.background.w));
    for (std::size_t i = 0; i < total; ++i) {
        if (!tx.has(i)) continue;
        const std::size_t ti = std::size_t(tx.tri[i]);
        MatInfo& mi = mats[g.sub[ti]];
        if (!tx.bled[i]) ++mi.texels;
        Vec4 c = mi.color;
        if (mi.image) {
            const Vec4 tc = sample_triplanar(*mi.image, texel_point(g, tx, i), texel_normal(g, tx, i), mi.m);
            c = mul4(c, tc);
        }
        if (bakeColors) {
            const float w1 = tx.b1[i], w2 = tx.b2[i], w0 = 1 - w1 - w2;
            const Vec4 vc = g.col[g.tri[ti][0]] * w0 + g.col[g.tri[ti][1]] * w1 + g.col[g.tri[ti][2]] * w2;
            c = mul4(c, vc);
        }
        put(out.base, i, c);
    }
    for (const MatInfo& mi : mats) {
        ModelTextureReport::PartInfo pi;
        pi.part = mi.part;
        pi.material = mi.material;
        pi.mapping = mi.image ? "triplanar" : "color";
        pi.texture = mi.texture;
        pi.texels = mi.texels;
        rep.parts.push_back(pi);
    }

    // ---- maps
    bool wantAo = S.aoStrength.has_value(), wantThick = false, wantEdges = false;
    for (const std::string& w : S.maps.write) {
        wantAo = wantAo || w == "ao";
        wantThick = wantThick || w == "thickness";
        wantEdges = wantEdges || w == "curvature";
    }
    float maxWidth = prm.edgeWidth;
    for (const ModelWearSpec& w : S.wear) {
        wantAo = wantAo || w.mask == "ao" || w.mask == "cavity";
        wantThick = wantThick || w.mask == "thickness";
        wantEdges = wantEdges || w.mask == "edges" || w.mask == "cavity";
        if (w.width) maxWidth = std::max(maxWidth, *w.width);
    }
    Bvh bvh;
    if (wantAo || wantThick) bvh.build(g);
    std::vector<float> ao, thick;
    EdgeIndex edges;
    if (wantAo) ao = compute_ao(g, bvh, tx, S.maps.samples, prm.aoDistance);
    if (wantThick) thick = compute_thickness(g, bvh, tx, S.maps.samples, prm.thickDistance);
    if (wantEdges) edges.build(g, S.maps.edgeAngle, maxWidth);
    auto has_write = [&](const char* n) {
        return std::find(S.maps.write.begin(), S.maps.write.end(), n) != S.maps.write.end();
    };
    if (wantAo) {
        const MapStats s = stats_of(ao, tx, 1.0f, 0.02f);
        rep.maps.push_back({"ao", s.mean, s.min, s.max, s.coverage});
        if (has_write("ao")) out.ao = grey_image(ao, size, 1.0f);
    }
    if (wantThick) {
        const MapStats s = stats_of(thick, tx, 1.0f, 0.02f);
        rep.maps.push_back({"thickness", s.mean, s.min, s.max, s.coverage});
        if (has_write("thickness")) out.thickness = grey_image(thick, size, 1.0f);
    }
    if (has_write("curvature")) {
        const std::vector<float> curv = curvature_map(g, edges, tx, prm.edgeWidth);
        const MapStats s = stats_of(curv, tx, 0.5f, 0.02f);
        rep.maps.push_back({"curvature", s.mean, s.min, s.max, s.coverage});
        out.curvature = grey_image(curv, size, 0.5f);
    }

    // ---- occlusion layer
    if (S.aoStrength) {
        check_parts(S.aoParts, "texturing.ao.parts");
        out.occlusion = make_image(size, 255, 255, 255, 255);
        for (std::size_t i = 0; i < total; ++i) {
            if (!tx.has(i) || std::isnan(ao[i])) continue;
            if (!needs(S.aoParts, mats[g.sub[std::size_t(tx.tri[i])]].part)) continue;
            const std::uint8_t b = to_byte(1 - *S.aoStrength * (1 - ao[i]));
            out.occlusion.rgba[i * 4] = out.occlusion.rgba[i * 4 + 1] = out.occlusion.rgba[i * 4 + 2] = b;
        }
    }

    // ---- wear
    if (!S.wear.empty()) {
        out.wear = make_image(size, 0, 0, 0, 0);
        out.hasWear = true;
        for (const ModelWearSpec& w : S.wear) {
            check_parts(w.parts, "texturing.wear \"" + w.name + "\" parts");
            const float width = w.width ? *w.width : prm.edgeWidth;
            const Vec4 color = w.color ? *w.color
                                       : ((w.mask == "edges" || w.mask == "thickness") ? Vec4{0.85f, 0.82f, 0.75f, 1}
                                                                                       : Vec4{0.10f, 0.08f, 0.06f, 1});
            std::vector<float> alphaOf(total, 0.0f);
            for (std::size_t i = 0; i < total; ++i) {
                if (!tx.has(i)) continue;
                const std::size_t ti = std::size_t(tx.tri[i]);
                if (!needs(w.parts, mats[g.sub[ti]].part)) continue;
                const Vec3 p = texel_point(g, tx, i);
                float m = 0;
                if (w.mask == "edges" || w.mask == "cavity") {
                    float cv, cc;
                    edges.bands(p, width, cv, cc);
                    const float soft = std::clamp(edges.curvature(g, tx, i) * width * 0.5f, -1.0f, 1.0f);
                    m = w.mask == "edges" ? std::max(cv, std::max(0.0f, soft))
                                          : std::max(std::max(cc, std::max(0.0f, -soft)), 1 - ao[i]);
                } else if (w.mask == "ao")
                    m = 1 - ao[i];
                else
                    m = 1 - thick[i];
                if (w.noise > 0) m *= 1 - w.noise * (1 - value_noise(p / w.noiseScale, w.seed));
                m = saturate((m - w.threshold) / (1 - w.threshold));
                if (w.upBias != 0) {
                    const float u01 = 0.5f + 0.5f * texel_normal(g, tx, i).y;
                    const float f = w.upBias > 0 ? 1 + (u01 - 1) * w.upBias : 1 + ((1 - u01) - 1) * -w.upBias;
                    m *= saturate(f);
                }
                const float a = saturate(m * w.amount) * color.w;
                alphaOf[i] = a;
                if (a > 0) over(out.wear, i, color.xyz(), a);
            }
            ModelMapStats ms;
            ms.name = w.name;
            std::size_t n = 0, strong = 0;
            double sum = 0, mx = 0;
            for (std::size_t i = 0; i < total; ++i) {
                if (!tx.has(i) || tx.bled[i]) continue;
                ++n;
                sum += alphaOf[i];
                mx = std::max<double>(mx, alphaOf[i]);
                if (alphaOf[i] >= 0.1f) ++strong;
            }
            ms.mean = n ? sum / double(n) : 0;
            ms.max = mx;
            ms.coverage = n ? double(strong) / double(n) : 0;
            rep.wear.push_back(ms);
            if (strong == 0)
                rep.warnings.push_back(std::format(
                    "wear \"{}\" (mask {}) painted nothing: lower `threshold`, raise `width` or `amount`{}.", w.name,
                    w.mask, w.mask == "edges" ? ", or lower maps.edgeAngle (the model may have no sharp edges)" : ""));
        }
    }

    // ---- decals
    if (!S.decals.empty()) {
        out.decals = make_image(size, 0, 0, 0, 0);
        out.hasDecals = true;
        std::vector<std::vector<char>> faceMasks(S.decals.size());
        bool anyFaces = false;
        for (const ModelDecalSpec& d : S.decals) anyFaces = anyFaces || !d.faces.is_null();
        ModelMesh soupMesh;
        ModelEditContext ctx;
        if (anyFaces) {
            for (std::size_t v = 0; v < g.pos.size(); ++v) {
                soupMesh.positions.push_back(g.pos[v]);
                soupMesh.normals.push_back(g.nrm[v]);
                soupMesh.uvs.push_back(g.uv[v]);
            }
            for (std::size_t t = 0; t < g.tri.size(); ++t) {
                for (int k = 0; k < 3; ++k) soupMesh.indices.push_back(g.tri[t][std::size_t(k)]);
                soupMesh.triParts.push_back(g.sub[t]);
            }
            for (const MeshSubmesh& sm : mesh.submeshes) {
                ctx.partNames.push_back(sm.part);
                ctx.materialNames.push_back(sm.material.name);
            }
            ctx.toModel = Mat4::identity();
        }
        for (std::size_t di = 0; di < S.decals.size(); ++di) {
            const ModelDecalSpec& d = S.decals[di];
            check_parts(d.parts, "texturing.decals \"" + d.name + "\" parts");
            auto img = load(d.image, "the image of decal \"" + d.name + "\"");
            if (!img.ok()) return img.error();
            if (!d.faces.is_null()) faceMasks[di] = model_select_triangles(soupMesh, d.faces, ctx);
            Vec3 n = normalize(d.normal);
            const Vec3 upRef = std::fabs(n.y) > 0.99f ? Vec3{0, 0, -1} : Vec3{0, 1, 0};
            Vec3 right = normalize(cross(upRef, n));
            Vec3 up = cross(n, right);
            float sn, cs;
            det::sin_cos(d.rotation * kDegToRad, sn, cs);
            const Vec3 r2 = right * cs + up * sn, u2 = up * cs - right * sn;
            const float depth = d.depth > 0 ? d.depth : std::min(d.size.x, d.size.y);
            const float cosMax = det::cos(d.maxAngle * kDegToRad);
            std::vector<char> triOk(g.tri.size(), 0);
            for (std::size_t t = 0; t < g.tri.size(); ++t) {
                if (!needs(d.parts, mats[g.sub[t]].part)) continue;
                if (!faceMasks[di].empty() && !faceMasks[di][t]) continue;
                if (dot(g.faceN[t], n) < cosMax) continue;
                triOk[t] = 1;
            }
            ModelTextureReport::DecalInfo info;
            info.name = d.name;
            std::set<std::int32_t> reached;
            for (std::size_t i = 0; i < total; ++i) {
                if (!tx.has(i) || !triOk[std::size_t(tx.tri[i])]) continue;
                const Vec3 rel = texel_point(g, tx, i) - d.position;
                if (std::fabs(dot(rel, n)) > depth) continue;
                const float s = 0.5f + dot(rel, r2) / d.size.x, t = 0.5f - dot(rel, u2) / d.size.y;
                if (s < 0 || s > 1 || t < 0 || t > 1) continue;
                const Vec4 c = sample_image(**img, s, t, false);
                const float a = saturate(c.w * d.opacity * d.tint.w);
                if (a <= 0) continue;
                over(out.decals, i, Vec3{c.x * d.tint.x, c.y * d.tint.y, c.z * d.tint.z}, a);
                if (!tx.bled[i]) {
                    ++info.texels;
                    reached.insert(tx.tri[i]);
                }
            }
            info.triangles = reached.size();
            rep.decals.push_back(info);
            if (info.texels == 0)
                rep.warnings.push_back(
                    std::format("decal \"{}\" painted no texel: nothing lies within {:.3g} m of its plane at the "
                                "position, or the surface there turns more than {:.0f} degrees from its normal"
                                "{}{}. Move `position` onto the surface (model.info lists the bounds of each part), "
                                "check `normal`, or raise `depth` and `maxAngle`.",
                                d.name, depth, d.maxAngle, d.parts.empty() ? "" : ", or the parts do not match",
                                d.faces.is_null() ? "" : ", or the face selection chose none of them"));
        }
    }

    // ---- uv wireframe (a hidden layer to paint by)
    out.uvWire = make_image(size, 0, 0, 0, 0);
    {
        static const Vec4 palette[8] = {{1, 0.3f, 0.3f, 1},  {0.3f, 0.8f, 0.3f, 1}, {0.3f, 0.5f, 1, 1},
                                        {1, 0.8f, 0.2f, 1},  {0.8f, 0.4f, 1, 1},    {0.2f, 0.9f, 0.9f, 1},
                                        {1, 0.55f, 0.1f, 1}, {0.9f, 0.9f, 0.9f, 1}};
        const float S2 = float(size);
        for (std::size_t t = 0; t < g.tri.size(); ++t) {
            const Vec4 c = palette[g.sub[t] % 8];
            for (int k = 0; k < 3; ++k) {
                const Vec2 a = g.uv[g.tri[t][std::size_t(k)]] * S2, b = g.uv[g.tri[t][std::size_t((k + 1) % 3)]] * S2;
                line(out.uvWire, int(std::floor(a.x)), int(std::floor(a.y)), int(std::floor(b.x)), int(std::floor(b.y)),
                     c);
            }
        }
    }
    out.inputs.assign(inputs.begin(), inputs.end());
    return out;
}

// ---- the maps alone ----------------------------------------------------------------------------------------------------------

Result<ModelMapsResult> bake_model_maps(const MeshData& mesh, int size, int bleed, const ModelMapSettings& settings,
                                        const std::vector<std::string>& maps) {
    if (!mesh.hasUvs)
        return make_error("the model has no uvs to bake maps into",
                          "Add a `uv` section with layout \"atlas\" (model.uv).");
    if (size < kModelTextureMinSize || size > kModelTextureMaxSize)
        return make_error(
            std::format("the map size {} is outside {} to {}", size, kModelTextureMinSize, kModelTextureMaxSize),
            "Use a power of two such as 1024.");
    ModelMapsResult out;
    out.size = size;
    Geo g = make_geo(mesh);
    const Params prm = params_of(settings, g);
    Texels tx = rasterize(g, size, bleed);
    if (tx.covered == 0)
        return make_error("no triangle covers a texel of the atlas: the uvs are empty or outside 0..1",
                          "Check the `uv` section (model.uv check:true measures it).");
    out.report.size = size;
    out.report.bleed = bleed;
    out.report.texels = tx.covered;
    out.report.utilization = double(tx.covered) / (double(size) * double(size));
    out.report.overlap = double(tx.overlapped) / double(tx.covered);
    auto wants = [&](const char* n) { return std::find(maps.begin(), maps.end(), n) != maps.end(); };
    Bvh bvh;
    if (wants("ao") || wants("thickness")) bvh.build(g);
    if (wants("ao")) {
        const std::vector<float> v = compute_ao(g, bvh, tx, settings.samples, prm.aoDistance);
        const MapStats s = stats_of(v, tx, 1.0f, 0.02f);
        out.report.maps.push_back({"ao", s.mean, s.min, s.max, s.coverage});
        out.ao = grey_image(v, size, 1.0f);
    }
    if (wants("thickness")) {
        const std::vector<float> v = compute_thickness(g, bvh, tx, settings.samples, prm.thickDistance);
        const MapStats s = stats_of(v, tx, 1.0f, 0.02f);
        out.report.maps.push_back({"thickness", s.mean, s.min, s.max, s.coverage});
        out.thickness = grey_image(v, size, 1.0f);
    }
    if (wants("curvature")) {
        EdgeIndex edges;
        edges.build(g, settings.edgeAngle, prm.edgeWidth);
        const std::vector<float> v = curvature_map(g, edges, tx, prm.edgeWidth);
        const MapStats s = stats_of(v, tx, 0.5f, 0.02f);
        out.report.maps.push_back({"curvature", s.mean, s.min, s.max, s.coverage});
        out.curvature = grey_image(v, size, 0.5f);
    }
    return out;
}

Result<ModelMapField> compute_model_map(const MeshData& mesh, int size, const ModelMapSettings& settings,
                                        const std::string& map) {
    if (!mesh.hasUvs) return make_error("the model has no uvs", "Add a `uv` section with layout \"atlas\".");
    if (map != "ao" && map != "curvature" && map != "thickness")
        return make_error("\"" + map + "\" is not a map", "Use \"ao\", \"curvature\" or \"thickness\".");
    Geo g = make_geo(mesh);
    const Params prm = params_of(settings, g);
    Texels tx = rasterize(g, size, 0);
    ModelMapField f;
    f.size = size;
    Bvh bvh;
    if (map == "curvature") {
        EdgeIndex edges;
        edges.build(g, settings.edgeAngle, prm.edgeWidth);
        f.values = curvature_map(g, edges, tx, prm.edgeWidth);
        return f;
    }
    bvh.build(g);
    f.values = map == "ao" ? compute_ao(g, bvh, tx, settings.samples, prm.aoDistance)
                           : compute_thickness(g, bvh, tx, settings.samples, prm.thickDistance);
    return f;
}

}  // namespace fa
