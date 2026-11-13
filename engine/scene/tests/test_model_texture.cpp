// Texturing of engine-made models (model_texture.h): the `vertexColors` and `texturing` sections (reading, errors, schema), low-poly palettes,
// the baked maps (occlusion, thickness, curvature) with measured values, triplanar textures, wear and decals in the layers, determinism.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <set>

#include "fa/scene/model_doc.h"
#include "fa/scene/model_texture.h"

using namespace fa;

namespace {

Json J(const char* text) { return parse_json(text, "test").value(); }

ModelDoc parse_ok(const char* text) {
    std::vector<ModelIssue> issues;
    auto doc = parse_model_doc(J(text), "test.model.json", &issues);
    std::string all;
    for (const ModelIssue& i : issues) all += i.pointer + ": " + i.message + "\n";
    REQUIRE_MESSAGE(doc.ok(), all);
    return std::move(*doc);
}

std::vector<ModelIssue> issues_of(const char* text) {
    std::vector<ModelIssue> issues;
    (void)parse_model_doc(J(text), "test.model.json", &issues);
    return issues;
}

bool has_issue(const std::vector<ModelIssue>& issues, const std::string& pointer, const std::string& contains) {
    for (const ModelIssue& i : issues)
        if (i.pointer == pointer &&
            (i.message.find(contains) != std::string::npos || i.hint.find(contains) != std::string::npos))
            return true;
    return false;
}

ModelBuild build_ok(const ModelDoc& doc, std::vector<Vec4> palette = {}) {
    ModelEvalOptions o;
    o.stylePalette = std::move(palette);
    auto b = evaluate_model(doc, o);
    REQUIRE_MESSAGE(b.ok(), (b.ok() ? std::string() : b.error().message));
    return std::move(*b);
}

Image solid(int w, int h, std::uint8_t r, std::uint8_t g, std::uint8_t b, std::uint8_t a = 255) {
    Image img;
    img.width = w;
    img.height = h;
    img.rgba.resize(std::size_t(w) * std::size_t(h) * 4);
    for (std::size_t i = 0; i < img.rgba.size(); i += 4) {
        img.rgba[i] = r;
        img.rgba[i + 1] = g;
        img.rgba[i + 2] = b;
        img.rgba[i + 3] = a;
    }
    return img;
}
// left half red, right half blue
Image halves() {
    Image img = solid(8, 8, 255, 0, 0);
    for (int y = 0; y < 8; ++y)
        for (int x = 4; x < 8; ++x) {
            const std::size_t i = (std::size_t(y) * 8 + std::size_t(x)) * 4;
            img.rgba[i] = 0;
            img.rgba[i + 2] = 255;
        }
    return img;
}

struct Baked {
    ModelDoc doc;
    ModelBuild build;
    ModelTextureLayers layers;
};

Baked bake(const char* text, ModelImageSource images = nullptr, std::vector<Vec4> palette = {}) {
    Baked b;
    b.doc = parse_ok(text);
    b.build = build_ok(b.doc, std::move(palette));
    ModelTextureInput in;
    in.mesh = &b.build.data;
    REQUIRE(b.doc.texturing.has_value());
    in.settings = &*b.doc.texturing;
    for (const auto& [n, m] : b.doc.materialTexturing) in.mappings.emplace_back(n, m);
    in.images = images;
    if (b.doc.uv) {
        in.uvTextureSize = b.build.uv ? b.build.uv->textureSize : 0;
        in.uvPadding = b.doc.uv->padding;
    }
    auto r = bake_model_textures(in);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : r.error().message + " " + r.error().hint));
    b.layers = std::move(*r);
    return b;
}

// The texel index of the point `p` on the surface of part `part`, through the model's own uvs (-1 when no triangle of the part holds it).
long locate(const MeshData& m, const std::string& part, Vec3 p, int size) {
    for (const MeshSubmesh& sm : m.submeshes) {
        if (part != "*" && sm.part != part) continue;
        for (std::uint32_t k = sm.start; k + 3 <= sm.start + sm.count; k += 3) {
            Vec3 v[3];
            Vec2 uv[3];
            for (int c = 0; c < 3; ++c) {
                const std::uint32_t i = m.indices[k + std::uint32_t(c)];
                v[c] = {m.positions[i * 3], m.positions[i * 3 + 1], m.positions[i * 3 + 2]};
                uv[c] = {m.uvs[i * 2], m.uvs[i * 2 + 1]};
            }
            const Vec3 n = cross(v[1] - v[0], v[2] - v[0]);
            const float nl = length(n);
            if (nl < 1e-9f || std::fabs(dot(n / nl, p - v[0])) > 1e-4f) continue;
            const float a0 = dot(cross(v[1] - p, v[2] - p), n), a1 = dot(cross(v[2] - p, v[0] - p), n),
                        a2 = dot(cross(v[0] - p, v[1] - p), n);
            const float sum = a0 + a1 + a2;
            if (a0 < -1e-6f * sum || a1 < -1e-6f * sum || a2 < -1e-6f * sum) continue;
            const Vec2 q = uv[0] * (a0 / sum) + uv[1] * (a1 / sum) + uv[2] * (a2 / sum);
            const int x = std::clamp(int(std::floor(q.x * float(size))), 0, size - 1),
                      y = std::clamp(int(std::floor(q.y * float(size))), 0, size - 1);
            return long(y) * size + x;
        }
    }
    return -1;
}

std::uint8_t px(const Image& img, long texel, int channel) {
    return img.rgba[std::size_t(texel) * 4 + std::size_t(channel)];
}

std::uint64_t hash_image(const Image& img) {
    std::uint64_t h = 1469598103934665603ull;
    for (std::uint8_t b : img.rgba) h = (h ^ b) * 1099511628211ull;
    return h;
}

}  // namespace

// ---- the sections ------------------------------------------------------------------------------------------------------------

TEST_CASE("texturing: the section is read with its defaults and written back") {
    const ModelDoc doc = parse_ok(R"({"format":"factoria.model/1","uv":{"method":"unwrap"},
      "texturing":{"size":512,"ao":{"strength":0.5,"parts":["a"]},"maps":{"samples":8,"write":["curvature","ao","ao"]},
        "wear":[{"mask":"cavity","color":"#102030","amount":0.5}],
        "decals":[{"image":"d.png","position":[0,1,0],"normal":"top","size":0.5,"rotation":90}]},
      "nodes":[{"op":"box","part":"a"}]})");
    REQUIRE(doc.texturing.has_value());
    const ModelTexturing& t = *doc.texturing;
    CHECK(t.size == 512);
    CHECK(t.bleed == -1);
    CHECK(t.vertexColors == "bake");
    REQUIRE(t.aoStrength.has_value());
    CHECK(*t.aoStrength == doctest::Approx(0.5f));
    CHECK(t.aoParts == std::vector<std::string>{"a"});
    CHECK(t.maps.samples == 8);
    CHECK(t.maps.write == std::vector<std::string>{"curvature", "ao"});  // a name once
    REQUIRE(t.wear.size() == 1);
    CHECK(t.wear[0].name == "wear1");
    CHECK(t.wear[0].mask == "cavity");
    CHECK(t.wear[0].threshold == doctest::Approx(0.1f));
    REQUIRE(t.wear[0].color.has_value());
    CHECK(t.wear[0].color->x == doctest::Approx(16 / 255.0f));
    REQUIRE(t.decals.size() == 1);
    CHECK(t.decals[0].normal.y == doctest::Approx(1));  // "top"
    CHECK(t.decals[0].size.x == doctest::Approx(0.5f));
    CHECK(t.decals[0].size.y == doctest::Approx(0.5f));
    const Json j = model_texturing_json(t);
    CHECK(j["size"] == 512);
    CHECK(j["wear"][0]["name"] == "wear1");
    CHECK(j["maps"]["samples"] == 8);
    // the written form reads back to the same section
    std::vector<ModelIssue> issues;
    auto again = parse_model_texturing(j, issues);
    REQUIRE(again.has_value());
    CHECK(model_texturing_json(*again) == j);
}

TEST_CASE("texturing: problems are listed with the pointer and the fix") {
    {
        auto i = issues_of(R"({"format":"factoria.model/1","nodes":[{"op":"box"}],"texturing":{"ao":true}})");
        CHECK(has_issue(i, "/texturing", "no `uv` section"));
    }
    {
        auto i =
            issues_of(R"({"format":"factoria.model/1","uv":{"layout":"tile"},"nodes":[{"op":"box"}],"texturing":{}})");
        CHECK(has_issue(i, "/texturing", "tile"));
    }
    {
        auto i = issues_of(
            R"({"format":"factoria.model/1","uv":{},"nodes":[{"op":"box"}],"texturing":{"wear":[{"mask":"edgs"}],"decals":[{"position":[0,0,0]}],"sise":3}})");
        CHECK(has_issue(i, "/texturing/wear/0/mask", "edges"));  // did you mean
        CHECK(has_issue(i, "/texturing/decals/0/image", "needs an \"image\""));
        CHECK(has_issue(i, "/texturing/decals/0/size", "needs a \"size\""));
        CHECK(has_issue(i, "/texturing/sise", "size"));
    }
    {
        auto i = issues_of(
            R"({"format":"factoria.model/1","uv":{},"nodes":[{"op":"box"}],"texturing":{"size":1000000,"maps":{"samples":1,"write":["aoo"]}}})");
        CHECK(has_issue(i, "/texturing/size", "size must be"));
        CHECK(has_issue(i, "/texturing/maps/samples", "samples must be"));
        CHECK(has_issue(i, "/texturing/maps/write/0", "ao"));
    }
    {
        auto i = issues_of(
            R"({"format":"factoria.model/1","uv":{},"materials":{"m":{"texture":"a.png","mapping":"uv"}},"nodes":[{"op":"box","material":"m"}],"texturing":{}})");
        CHECK(has_issue(i, "/materials/m/mapping", "triplanar"));
    }
    {
        auto i =
            issues_of(R"({"format":"factoria.model/1","nodes":[{"op":"box"}],"vertexColors":{"palette":["nope"]}})");
        CHECK(has_issue(i, "/vertexColors/palette/0", "colour"));
        auto k = issues_of(
            R"({"format":"factoria.model/1","nodes":[{"op":"box"}],"vertexColors":{"palette":["#ffffff","#ff0000"],"parts":{"a":{"color":1,"gradient":{"from":0,"to":1}}}}})");
        CHECK(has_issue(k, "/vertexColors/parts/a", "both"));
    }
    {
        auto i = issues_of(R"({"format":"factoria.model/1","nodes":[{"op":"box"}],"vertexColors":{"color":3}})");
        CHECK(has_issue(i, "/vertexColors/color", "needs a palette"));
        auto k = issues_of(
            R"({"format":"factoria.model/1","nodes":[{"op":"box"}],"vertexColors":{"palette":["#ffffff"],"color":3}})");
        CHECK(has_issue(k, "/vertexColors/color", "outside the palette"));
    }
}

TEST_CASE("texturing: the material fields stay out of the glTF material") {
    const ModelDoc doc = parse_ok(R"({"format":"factoria.model/1","uv":{},"texturing":{},
      "materials":{"stone":{"color":[0.5,0.5,0.5],"texture":"t.png","textureScale":2,"textureOffset":[1,0,0],"sharpness":8,"tint":"#ff8000"}},
      "nodes":[{"op":"box","material":"stone"}]})");
    const ModelMaterialTexturing* m = doc.texturing_of("stone");
    REQUIRE(m != nullptr);
    CHECK(m->scale == doctest::Approx(2));
    CHECK(m->offset.x == doctest::Approx(1));
    CHECK(m->sharpness == 8);
    CHECK(m->tint.x == doctest::Approx(1));
    CHECK(m->tint.y == doctest::Approx(128 / 255.0f));
    CHECK(doc.texturing_of("") == nullptr);
    CHECK(doc.materials[0].second.texture == "t.png");
}

TEST_CASE("texturing: the schema lists the new sections and material fields") {
    const Json s = model_doc_schema();
    CHECK(s["properties"].contains("texturing"));
    CHECK(s["properties"].contains("vertexColors"));
    CHECK(s["properties"]["texturing"]["properties"].contains("wear"));
    CHECK(s["properties"]["texturing"]["properties"]["decals"]["items"]["properties"]["faces"]["$ref"] ==
          "#/$defs/face_selection");
    const Json& mat = s["properties"]["materials"]["additionalProperties"]["properties"];
    for (const char* k : {"mapping", "textureScale", "textureOffset", "sharpness", "tint"}) CHECK(mat.contains(k));
}

// ---- vertex colour palettes --------------------------------------------------------------------------------------------------

TEST_CASE("vertexColors: part colours snap to the palette and the glb keeps one colour per vertex") {
    const ModelDoc doc = parse_ok(R"({"format":"factoria.model/1",
      "vertexColors":{"palette":["#204020","#c0a060","#a03030"],"parts":{"wall":{"color":"#b09050"},"roof":{"color":2}}},
      "nodes":[{"op":"box","part":"wall"},{"op":"cone","part":"roof","position":[0,1,0]}]})");
    const ModelBuild b = build_ok(doc);
    REQUIRE(b.vertexColors.has_value());
    CHECK(b.vertexColors->paletteSize == 3);
    CHECK(b.vertexColors->distinctColors == 2);  // the wall snapped to #c0a060, the roof is #a03030
    CHECK(b.data.colors.size() == b.data.vertex_count() * 4);
    // every wall vertex is the palette colour #c0a060
    for (const MeshSubmesh& sm : b.data.submeshes) {
        const float expect[3] = {sm.part == "wall" ? 0xc0 / 255.0f : 0xa0 / 255.0f,
                                 sm.part == "wall" ? 0xa0 / 255.0f : 0x30 / 255.0f,
                                 sm.part == "wall" ? 0x60 / 255.0f : 0x30 / 255.0f};
        for (std::uint32_t k = sm.start; k < sm.start + sm.count; ++k) {
            const std::uint32_t v = b.data.indices[k];
            REQUIRE(b.data.colors[v * 4] == doctest::Approx(expect[0]).epsilon(0.002));
            REQUIRE(b.data.colors[v * 4 + 1] == doctest::Approx(expect[1]).epsilon(0.002));
            REQUIRE(b.data.colors[v * 4 + 2] == doctest::Approx(expect[2]).epsilon(0.002));
        }
    }
}

TEST_CASE("vertexColors: the style palette comes from the project and a missing one is a warning") {
    const char* text =
        R"({"format":"factoria.model/1","vertexColors":{"palette":"style","color":"#ff0000"},"nodes":[{"op":"box"}]})";
    const ModelDoc doc = parse_ok(text);
    const ModelBuild with = build_ok(doc, {Vec4{0, 1, 0, 1}, Vec4{0, 0, 1, 1}});
    CHECK(with.data.colors[0] == doctest::Approx(0));
    CHECK(with.data.colors[1] ==
          doctest::Approx(1));  // red is as far from green as from blue: the first palette colour wins
    const ModelBuild without = build_ok(doc);
    CHECK(without.data.colors[0] == doctest::Approx(1));  // used as written
    bool warned = false;
    for (const std::string& w : without.warnings) warned = warned || w.find("has no palette") != std::string::npos;
    CHECK(warned);
}

TEST_CASE("vertexColors: flat gives each triangle its own vertices and a gradient follows the axis") {
    const ModelDoc flat = parse_ok(
        R"({"format":"factoria.model/1","vertexColors":{"flat":true,"variation":0.2,"seed":3,"color":"#808080"},"nodes":[{"op":"box"}]})");
    const ModelBuild b = build_ok(flat);
    CHECK(b.stats.triangles == 12);
    CHECK(b.data.vertex_count() == 36);
    CHECK(b.vertexColors->verticesBefore == 24);
    CHECK(b.vertexColors->verticesAfter == 36);
    // one colour per triangle, within +-20% of the base grey, and not all the same
    std::set<std::uint32_t> seen;
    for (std::size_t t = 0; t < 12; ++t) {
        const std::uint32_t v0 = b.data.indices[t * 3], v1 = b.data.indices[t * 3 + 1], v2 = b.data.indices[t * 3 + 2];
        CHECK(b.data.colors[v0 * 4] == b.data.colors[v1 * 4]);
        CHECK(b.data.colors[v0 * 4] == b.data.colors[v2 * 4]);
        CHECK(b.data.colors[v0 * 4] >= doctest::Approx(0.502f * 0.8f - 0.01f));
        CHECK(b.data.colors[v0 * 4] <= doctest::Approx(0.502f * 1.2f + 0.01f));
        seen.insert(std::uint32_t(b.data.colors[v0 * 4] * 1000));
    }
    CHECK(seen.size() > 6);
    // the same document gives the same colours; another seed changes them
    const ModelBuild again = build_ok(flat);
    CHECK(again.data.colors == b.data.colors);
    ModelDoc other = flat;
    other.vertexColors->seed = 4;
    CHECK(build_ok(other).data.colors != b.data.colors);

    const ModelDoc grad = parse_ok(
        R"({"format":"factoria.model/1","vertexColors":{"parts":{"":{"gradient":{"axis":"y","from":"#000000","to":"#ffffff"}}}},"nodes":[{"op":"box","size":[1,2,1]}]})");
    const ModelBuild g = build_ok(grad);
    for (std::size_t v = 0; v < g.data.vertex_count(); ++v) {
        const float y = g.data.positions[v * 3 + 1];
        CHECK(g.data.colors[v * 4] == doctest::Approx((y + 1) / 2).epsilon(0.01));
    }
}

TEST_CASE("vertexColors: a part the nodes do not make is a warning with a suggestion") {
    const ModelDoc doc = parse_ok(
        R"({"format":"factoria.model/1","vertexColors":{"parts":{"rof":{"color":"#ff0000"}}},"nodes":[{"op":"box","part":"roof"}]})");
    const ModelBuild b = build_ok(doc);
    bool warned = false;
    for (const std::string& w : b.warnings)
        warned = warned || (w.find("rof") != std::string::npos && w.find("roof") != std::string::npos);
    CHECK(warned);
}

// ---- the baked maps ----------------------------------------------------------------------------------------------------------

TEST_CASE("maps: occlusion darkens the corner between a floor and a wall and nothing else") {
    const char* text = R"({"format":"factoria.model/1","uv":{"method":"unwrap","textureSize":512,"texelsPerUnit":64},
      "texturing":{"maps":{"samples":32},"ao":{"strength":1}},
      "nodes":[{"op":"box","size":[2,0.1,2],"part":"floor"},{"op":"box","size":[2,1,0.1],"position":[0,0.55,-0.95],"part":"wall"}]})";
    const Baked b = bake(text);
    const int size = b.layers.size;
    REQUIRE(size == 512);
    const long near = locate(b.build.data, "floor", Vec3{0, 0.05f, -0.8f}, size);
    const long far = locate(b.build.data, "floor", Vec3{0, 0.05f, 0.8f}, size);
    const long wall = locate(b.build.data, "wall", Vec3{0, 0.2f, -0.9f},
                             size);  // the wall's face towards the room, just above the floor
    REQUIRE(near >= 0);
    REQUIRE(far >= 0);
    REQUIRE(wall >= 0);
    REQUIRE_FALSE(b.layers.occlusion.empty());
    CHECK(px(b.layers.occlusion, far, 0) == 255);
    CHECK(px(b.layers.occlusion, near, 0) < 235);  // occluded by the wall
    CHECK(px(b.layers.occlusion, near, 0) > 90);
    CHECK(px(b.layers.occlusion, wall, 0) < 255);  // the floor is 15 cm away from it
    // the report says the same
    REQUIRE(b.layers.report.maps.size() == 1);
    CHECK(b.layers.report.maps[0].name == "ao");
    CHECK(b.layers.report.maps[0].max == doctest::Approx(1.0).epsilon(0.001));
    CHECK(b.layers.report.maps[0].min < 0.6);
    CHECK(b.layers.report.maps[0].mean > 0.8);
    CHECK(b.layers.report.maps[0].mean < 0.99);

    // a more distant wall occludes less; more samples change the value only a little
    const MeshData& mesh = b.build.data;
    ModelMapSettings ms;
    ms.samples = 32;
    auto field = compute_model_map(mesh, 512, ms, "ao");
    REQUIRE(field.ok());
    ModelMapSettings ms64 = ms;
    ms64.samples = 64;
    auto field64 = compute_model_map(mesh, 512, ms64, "ao");
    REQUIRE(field64.ok());
    CHECK(std::fabs(field->values[std::size_t(near)] - field64->values[std::size_t(near)]) < 0.06f);
    CHECK(field->values[std::size_t(far)] == doctest::Approx(1.0f));
    CHECK(field->values[std::size_t(near)] < field->values[std::size_t(far)] - 0.05f);
}

TEST_CASE("maps: a thin plate is thin and a cube is thick") {
    const char* text = R"({"format":"factoria.model/1","uv":{"method":"unwrap","textureSize":256,"texelsPerUnit":64},
      "texturing":{"maps":{"samples":24,"write":["thickness"]}},
      "nodes":[{"op":"box","size":[1,0.05,1],"part":"plate"},{"op":"box","size":[1,1,1],"position":[3,0,0],"part":"cube"}]})";
    const Baked b = bake(text);
    REQUIRE_FALSE(b.layers.thickness.empty());
    const int size = b.layers.size;
    const long plate = locate(b.build.data, "plate", Vec3{0.1f, 0.025f, 0.1f}, size);
    const long cube = locate(b.build.data, "cube", Vec3{3.1f, 0.5f, 0.1f}, size);
    REQUIRE(plate >= 0);
    REQUIRE(cube >= 0);
    // the diagonal is about 4.1 m; the thickness is measured up to half of it
    CHECK(px(b.layers.thickness, plate, 0) < 20);  // 0.05..0.07 m of 2 m
    CHECK(px(b.layers.thickness, cube, 0) > 100);  // the cube is 1 m deep: half of the range
    CHECK(px(b.layers.thickness, cube, 0) < 160);
}

TEST_CASE("maps: curvature is high along convex edges and low in concave corners") {
    const char* text = R"({"format":"factoria.model/1","uv":{"method":"unwrap","textureSize":512,"texelsPerUnit":64},
      "texturing":{"maps":{"edgeWidth":0.1,"write":["curvature"]}},
      "nodes":[{"op":"boolean","mode":"union","children":[{"op":"box","size":[2,0.1,2]},{"op":"box","size":[2,1,0.1],"position":[0,0.5,-0.95]}]}]})";
    const Baked b = bake(text);
    REQUIRE_FALSE(b.layers.curvature.empty());
    const int size = b.layers.size;
    const long flat = locate(b.build.data, "*", Vec3{0, 0.05f, 0.5f}, size);
    const long rim =
        locate(b.build.data, "*", Vec3{0, 0.05f, 0.97f}, size);  // 3 cm from the floor's front edge (convex)
    const long corner = locate(b.build.data, "*", Vec3{0, 0.05f, -0.85f}, size);  // 5 cm from the wall (concave)
    const long top = locate(b.build.data, "*", Vec3{0, 1.0f, -0.93f}, size);      // the wall's top edge (convex)
    REQUIRE(flat >= 0);
    REQUIRE(rim >= 0);
    REQUIRE(corner >= 0);
    REQUIRE(top >= 0);
    CHECK(px(b.layers.curvature, flat, 0) == 128);
    CHECK(px(b.layers.curvature, rim, 0) > 190);
    CHECK(px(b.layers.curvature, corner, 0) < 80);
    CHECK(px(b.layers.curvature, top, 0) > 190);
}

TEST_CASE("maps: bake_model_maps writes the requested maps and the same input gives the same bytes") {
    const ModelDoc doc = parse_ok(
        R"({"format":"factoria.model/1","uv":{"method":"unwrap","textureSize":128,"texelsPerUnit":64},"nodes":[{"op":"rounded_box","size":[1,1,1],"radius":0.2}]})");
    const ModelBuild built = build_ok(doc);
    ModelMapSettings ms;
    ms.samples = 8;
    auto a = bake_model_maps(built.data, 128, 2, ms, {"ao", "curvature"});
    auto b = bake_model_maps(built.data, 128, 2, ms, {"ao", "curvature"});
    REQUIRE(a.ok());
    REQUIRE(b.ok());
    CHECK_FALSE(a->ao.empty());
    CHECK_FALSE(a->curvature.empty());
    CHECK(a->thickness.empty());
    CHECK(hash_image(a->ao) == hash_image(b->ao));
    CHECK(hash_image(a->curvature) == hash_image(b->curvature));
    REQUIRE(a->report.maps.size() == 2);
    // a convex shape is open to the sky
    CHECK(a->report.maps[0].mean > 0.97);
    // the rounded box is smooth: its curvature is above neutral
    CHECK(a->report.maps[1].mean > 0.5);
    CHECK(a->report.maps[1].max > 0.55);
    CHECK(a->report.texels > 1000);
    CHECK(a->report.utilization > 0.1);
    auto bad = bake_model_maps(built.data, 8, 2, ms, {"ao"});
    CHECK_FALSE(bad.ok());
}

// ---- the layers --------------------------------------------------------------------------------------------------------------

TEST_CASE("texturing: a triplanar texture is projected at the texture scale") {
    // one quad facing up: the projection along y, u = x / scale, v = z / scale; the texture is red on its left half, blue on its right half
    const char* text =
        R"({"format":"factoria.model/1","uv":{"method":"unwrap","textureSize":256,"texelsPerUnit":128},"texturing":{"bleed":2},
      "materials":{"m":{"texture":"halves.png","textureScale":2,"color":"#ffffff"}},
      "nodes":[{"op":"grid","width":1,"depth":1,"material":"m","part":"p"}]})";
    int loads = 0;
    const Baked b = bake(text, [&](const std::string& path) -> Result<Image> {
        ++loads;
        if (path != "halves.png") return make_error("no such image: " + path, "test");
        return halves();
    });
    CHECK(loads == 1);  // read once for the whole bake
    REQUIRE(b.layers.inputs == std::vector<std::string>{"halves.png"});
    const int size = b.layers.size;
    const MeshData& m = b.build.data;
    // the quad's y is 0; texture x/2 wraps: x in [0, 1] is u in [0, .5] = red, x in [-1, 0] would be blue
    float lo = 1e9f, hi = -1e9f;
    for (std::size_t v = 0; v < m.vertex_count(); ++v) {
        lo = std::min(lo, m.positions[v * 3]);
        hi = std::max(hi, m.positions[v * 3]);
    }
    const float xm = (lo + hi) / 2;
    const long left = locate(m, "p", Vec3{xm - 0.25f, 0, 0.1f}, size);
    const long right = locate(m, "p", Vec3{xm + 0.25f, 0, 0.1f}, size);
    REQUIRE(left >= 0);
    REQUIRE(right >= 0);
    // with the quad centred on x = 0: x -0.25 -> u -0.125 -> wraps to 0.875 (blue); x +0.25 -> u 0.125 (red)
    CHECK(std::fabs(xm) < 1e-4f);
    CHECK(px(b.layers.base, left, 2) == 255);
    CHECK(px(b.layers.base, left, 0) == 0);
    CHECK(px(b.layers.base, right, 0) == 255);
    CHECK(px(b.layers.base, right, 2) == 0);
    REQUIRE(b.layers.report.parts.size() == 1);
    CHECK(b.layers.report.parts[0].mapping == "triplanar");
    CHECK(b.layers.report.parts[0].texture == "halves.png");
    CHECK(b.layers.report.parts[0].texels > 10000);
    // a missing image is an error that names the material and the fix
    ModelTextureInput in;
    in.mesh = &b.build.data;
    in.settings = &*b.doc.texturing;
    in.images = [](const std::string& path) -> Result<Image> {
        return make_error("cannot read " + path, "Check the path.");
    };
    auto r = bake_model_textures(in);
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("material \"m\"") != std::string::npos);
}

TEST_CASE("texturing: vertex colours are baked into the base layer") {
    const Baked baked = bake(
        R"({"format":"factoria.model/1","uv":{"method":"unwrap","textureSize":128,"texelsPerUnit":100},"texturing":{},
      "vertexColors":{"color":"#ff0000"},"nodes":[{"op":"box","part":"cube","color":"#808080"}]})");
    const int size = baked.layers.size;
    const long top = locate(baked.build.data, "cube", Vec3{0, 0.5f, 0}, size);
    REQUIRE(top >= 0);
    CHECK(px(baked.layers.base, top, 0) == doctest::Approx(0.502f * 255).epsilon(0.02));  // 0x80 grey times red
    CHECK(px(baked.layers.base, top, 1) == 0);
    CHECK(px(baked.layers.base, top, 3) == 255);
    // "keep" leaves the colours to the mesh: the base layer is the material colour only
    const Baked kept = bake(
        R"({"format":"factoria.model/1","uv":{"method":"unwrap","textureSize":128,"texelsPerUnit":100},"texturing":{"vertexColors":"keep"},
      "vertexColors":{"color":"#ff0000"},"nodes":[{"op":"box","part":"cube"}]})");
    const long t2 = locate(kept.build.data, "cube", Vec3{0, 0.5f, 0}, kept.layers.size);
    REQUIRE(t2 >= 0);
    CHECK(px(kept.layers.base, t2, 1) == px(kept.layers.base, t2, 0));
}

TEST_CASE("texturing: bleed spreads the colours past the pieces and the background fills the rest") {
    auto count_background = [](const Image& img) {
        std::size_t n = 0;
        for (std::size_t i = 0; i < img.rgba.size(); i += 4)
            n += (img.rgba[i] == 255 && img.rgba[i + 1] == 0 && img.rgba[i + 2] == 255) ? 1 : 0;
        return n;
    };
    auto text = [](int bleed) {
        return std::string(
                   R"({"format":"factoria.model/1","uv":{"method":"unwrap","textureSize":128,"texelsPerUnit":60},"texturing":{"background":"#ff00ff","bleed":)") +
               std::to_string(bleed) + R"(},"nodes":[{"op":"box","color":"#00ff00"}]})";
    };
    const Baked none = bake(text(0).c_str());
    const Baked some = bake(text(4).c_str());
    CHECK(none.layers.report.bleed == 0);
    CHECK(some.layers.report.bleed == 4);
    CHECK(none.layers.report.texels == some.layers.report.texels);
    CHECK(none.layers.report.texels > 3000);
    const std::size_t free0 = count_background(none.layers.base), free4 = count_background(some.layers.base);
    CHECK(free0 == 128 * 128 - none.layers.report.texels);
    CHECK(free4 < free0);
    // a piece is a green square, never magenta, and the texels next to it are green too
    CHECK(free0 - free4 > 500);
    CHECK(some.layers.report.utilization == doctest::Approx(double(some.layers.report.texels) / (128.0 * 128.0)));
}

TEST_CASE("texturing: a decal paints the texels it reaches and no others") {
    const char* text = R"({"format":"factoria.model/1","uv":{"method":"unwrap","textureSize":256,"texelsPerUnit":128},
      "texturing":{"decals":[{"name":"logo","image":"logo.png","position":[0,0,0],"normal":[0,1,0],"size":[0.5,0.5],"opacity":0.5,"tint":"#ffffff"}]},
      "nodes":[{"op":"grid","width":1,"depth":1,"part":"floor"}]})";
    const Baked b = bake(text, [](const std::string& path) -> Result<Image> {
        if (path != "logo.png") return make_error("no such image: " + path);
        return solid(4, 4, 255, 0, 0);
    });
    REQUIRE(b.layers.hasDecals);
    REQUIRE(b.layers.report.decals.size() == 1);
    CHECK(b.layers.report.decals[0].name == "logo");
    CHECK(b.layers.report.decals[0].triangles == 2);
    // 0.5 x 0.5 m of a surface drawn at 128 texels per metre: 64 x 64 texels (give or take the border ones)
    CHECK(b.layers.report.decals[0].texels > 3900);
    CHECK(b.layers.report.decals[0].texels < 4300);
    const int size = b.layers.size;
    const long centre = locate(b.build.data, "floor", Vec3{0, 0, 0}, size);
    const long outside = locate(b.build.data, "floor", Vec3{0.4f, 0, 0.4f}, size);
    REQUIRE(centre >= 0);
    REQUIRE(outside >= 0);
    CHECK(px(b.layers.decals, centre, 0) == 255);
    CHECK(px(b.layers.decals, centre, 1) == 0);
    CHECK(px(b.layers.decals, centre, 3) == doctest::Approx(128).epsilon(0.02));
    CHECK(px(b.layers.decals, outside, 3) == 0);
    REQUIRE(b.layers.inputs == std::vector<std::string>{"logo.png"});
}

TEST_CASE("texturing: a decal keeps to the part, the faces and the direction it is asked for") {
    auto make = [](const char* decal) {
        return std::string(
                   R"({"format":"factoria.model/1","uv":{"method":"unwrap","textureSize":256,"texelsPerUnit":96},"texturing":{"decals":[)") +
               decal +
               R"(]},"nodes":[{"op":"box","size":[2,1,2],"part":"a"},{"op":"box","size":[2,1,2],"position":[4,0,0],"part":"b"}]})";
    };
    auto images = [](const std::string&) -> Result<Image> { return solid(2, 2, 0, 0, 255); };
    // the same decal on the top of both boxes, then only the part "b", then only the faces that look up, then the direction turned away
    const std::string base = R"("image":"d.png","size":1.2,"depth":2,"normal":"top")";
    const Baked both =
        bake(make((R"({"position":[0,0.5,0],"parts":[],)" + base + "},{\"position\":[4,0.5,0]," + base + "}").c_str())
                 .c_str(),
             images);
    const Baked onlyB = bake(make((R"({"position":[0,0.5,0],"parts":["b"],)" + base + "}").c_str()).c_str(), images);
    CHECK(both.layers.report.decals[0].texels > 0);
    CHECK(onlyB.layers.report.decals[0].texels == 0);  // b is 4 m away from the projection
    const Baked partB = bake(make((R"({"position":[4,0.5,0],"parts":["b"],)" + base + "}").c_str()).c_str(), images);
    const Baked partA = bake(make((R"({"position":[4,0.5,0],"parts":["a"],)" + base + "}").c_str()).c_str(), images);
    {
        const double used = partB.build.uv ? partB.build.uv->texelsPerUnitUsed : 0;
        CHECK(double(partB.layers.report.decals[0].texels) == doctest::Approx(1.44 * used * used).epsilon(0.1));
    }
    CHECK(partA.layers.report.decals[0].texels == 0);
    const Baked turned =
        bake(make((R"({"position":[0,0.5,0],"normal":"bottom","image":"d.png","size":1.2,"depth":2,"maxAngle":30})"))
                 .c_str(),
             images);
    CHECK(turned.layers.report.decals[0].texels > 0);  // the bottom face is the one it sits on
    const Baked sideways = bake(
        make(
            (R"({"position":[0,0.5,0],"normal":"top","image":"d.png","size":1.2,"depth":2,"maxAngle":10,"faces":{"by":"normal","direction":"right"}})"))
            .c_str(),
        images);
    CHECK(sideways.layers.report.decals[0].texels == 0);  // the faces it may land on do not look up
}

TEST_CASE("texturing: wear marks the edges and the cavities and is the same on every run") {
    const char* text = R"({"format":"factoria.model/1","uv":{"method":"unwrap","textureSize":256,"texelsPerUnit":100},
      "texturing":{"maps":{"samples":16,"edgeWidth":0.1},"wear":[
        {"name":"chips","mask":"edges","color":"#ffffff","amount":1,"noise":0,"threshold":0},
        {"name":"dirt","mask":"cavity","color":"#000000","amount":1,"noise":0}]},
      "nodes":[{"op":"boolean","mode":"union","children":[{"op":"box","size":[2,0.1,2]},{"op":"box","size":[2,1,0.1],"position":[0,0.5,-0.95]}]}]})";
    const Baked a = bake(text);
    const Baked b = bake(text);
    REQUIRE(a.layers.hasWear);
    REQUIRE(a.layers.report.wear.size() == 2);
    CHECK(a.layers.report.wear[0].name == "chips");
    CHECK(a.layers.report.wear[1].name == "dirt");
    CHECK(a.layers.report.wear[0].coverage > 0.02);
    CHECK(a.layers.report.wear[0].coverage < 0.3);
    CHECK(a.layers.report.wear[1].coverage > 0.0);
    const int size = a.layers.size;
    const long mid = locate(a.build.data, "*", Vec3{0, 0.05f, 0.4f}, size);
    const long rim = locate(a.build.data, "*", Vec3{0, 0.05f, 0.98f}, size);
    const long crease = locate(a.build.data, "*", Vec3{0, 0.05f, -0.87f}, size);
    REQUIRE(mid >= 0);
    REQUIRE(rim >= 0);
    REQUIRE(crease >= 0);
    CHECK(px(a.layers.wear, mid, 3) == 0);
    CHECK(px(a.layers.wear, rim, 3) > 200);
    CHECK(px(a.layers.wear, rim, 0) > 200);  // light chips
    CHECK(px(a.layers.wear, crease, 3) > 100);
    CHECK(px(a.layers.wear, crease, 0) < 60);  // dark dirt
    CHECK(hash_image(a.layers.wear) == hash_image(b.layers.wear));
    CHECK(hash_image(a.layers.base) == hash_image(b.layers.base));
    CHECK(hash_image(a.layers.uvWire) == hash_image(b.layers.uvWire));
    // the noise only breaks the mask up: the same document with noise differs, and stays the same on every run
    ModelDoc noisy = a.doc;
    noisy.texturing->wear[0].noise = 0.8f;
    ModelTextureInput in;
    in.mesh = &a.build.data;
    in.settings = &*noisy.texturing;
    in.uvTextureSize = 256;
    auto n1 = bake_model_textures(in);
    auto n2 = bake_model_textures(in);
    REQUIRE(n1.ok());
    REQUIRE(n2.ok());
    CHECK(hash_image(n1->wear) == hash_image(n2->wear));
    CHECK(hash_image(n1->wear) != hash_image(a.layers.wear));
}

TEST_CASE("texturing: a bake with a size out of range fails and says the range") {
    const ModelDoc doc = parse_ok(R"({"format":"factoria.model/1","nodes":[{"op":"box"}]})");
    const ModelBuild built = build_ok(doc);
    ModelTexturing t;
    t.size = 8;
    ModelTextureInput in;
    in.mesh = &built.data;
    in.settings = &t;
    auto r = bake_model_textures(in);
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("16") != std::string::npos);
}
