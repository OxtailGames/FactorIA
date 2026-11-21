// Lightmap UVs (fa/scene/lightmap_uv.h), the manifest of a bake (fa/scene/lightmap_manifest.h) and the orientation of a lightmap page.
#include <doctest.h>

#include <cmath>
#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/image_float.h"
#include "fa/scene/lightmap_bake.h"
#include "fa/scene/lightmap_manifest.h"
#include "fa/scene/lightmap_uv.h"
#include "fa/scene/model_kernel.h"

using namespace fa;

namespace {

ModelMesh make_cube() {
    ModelBoxParams p;
    p.size = {1, 1, 1};
    return model_box(p);
}

ModelMesh make_sphere() {
    ModelSphereParams p;
    p.radius = 0.5f;
    p.segments = 16;
    p.rings = 8;
    return model_sphere(p);
}

// How many triangles cover each texel centre of an n x n grid (strictly inside).
std::vector<int> coverage(const LightmapUvResult& r, int n) {
    std::vector<int> cov(std::size_t(n) * n, 0);
    for (std::size_t t = 0; t + 2 < r.indices.size(); t += 3) {
        const Vec2 a = r.uv[r.indices[t]], b = r.uv[r.indices[t + 1]], c = r.uv[r.indices[t + 2]];
        const float minx = std::min({a.x, b.x, c.x}), maxx = std::max({a.x, b.x, c.x});
        const float miny = std::min({a.y, b.y, c.y}), maxy = std::max({a.y, b.y, c.y});
        const float area = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
        if (std::fabs(area) < 1e-9f) continue;
        for (int y = std::max(0, int(miny * n) - 1); y <= std::min(n - 1, int(maxy * n) + 1); ++y)
            for (int x = std::max(0, int(minx * n) - 1); x <= std::min(n - 1, int(maxx * n) + 1); ++x) {
                const float px = (float(x) + 0.5f) / float(n), py = (float(y) + 0.5f) / float(n);
                if (px < minx || px > maxx || py < miny || py > maxy) continue;
                const float w0 = ((b.x - px) * (c.y - py) - (b.y - py) * (c.x - px)) / area;
                const float w1 = ((c.x - px) * (a.y - py) - (c.y - py) * (a.x - px)) / area;
                const float w2 = 1.0f - w0 - w1;
                const float eps = 1e-4f;
                if (w0 > eps && w1 > eps && w2 > eps) ++cov[std::size_t(y) * n + x];
            }
    }
    return cov;
}

}  // namespace

TEST_CASE("lightmap uv: the cube is unwrapped into the unit square without overlap") {
    const ModelMesh cube = make_cube();
    auto r = generate_lightmap_uv(cube.positions, cube.normals, cube.indices);
    REQUIRE(r.ok());
    CHECK(r->indices.size() == cube.indices.size());
    CHECK(r->uv.size() == r->source.size());
    CHECK(r->utilization > 0.3);
    for (std::size_t i = 0; i < r->uv.size(); ++i) {
        CHECK(r->uv[i].x >= -1e-5f);
        CHECK(r->uv[i].x <= 1.00001f);
        CHECK(r->uv[i].y >= -1e-5f);
        CHECK(r->uv[i].y <= 1.00001f);
        CHECK(r->source[i] < cube.positions.size());
    }
    // Every output triangle is the input triangle (same corners in the same order), the vertices only split.
    for (std::size_t k = 0; k < cube.indices.size(); ++k) {
        const Vec3 want = cube.positions[cube.indices[k]];
        const Vec3 got = cube.positions[r->source[r->indices[k]]];
        CHECK(want.x == got.x);
        CHECK(want.y == got.y);
        CHECK(want.z == got.z);
    }
    for (int c : coverage(*r, 256)) CHECK(c <= 1);
}

TEST_CASE("lightmap uv: a sphere has no overlap and keeps a gutter between charts") {
    const ModelMesh s = make_sphere();
    auto r = generate_lightmap_uv(s.positions, s.normals, s.indices);
    REQUIRE(r.ok());
    int covered = 0, over = 0;
    for (int c : coverage(*r, 256)) {
        covered += c > 0 ? 1 : 0;
        over += c > 1 ? 1 : 0;
    }
    CHECK(over == 0);
    CHECK(covered > 256 * 256 / 6);  // the charts use a good part of the square
}

TEST_CASE("lightmap uv: the same triangles give the same bits twice") {
    const ModelMesh s = make_sphere();
    auto a = generate_lightmap_uv(s.positions, s.normals, s.indices);
    auto b = generate_lightmap_uv(s.positions, s.normals, s.indices);
    REQUIRE(a.ok());
    REQUIRE(b.ok());
    REQUIRE(a->uv.size() == b->uv.size());
    CHECK(a->indices == b->indices);
    CHECK(a->source == b->source);
    for (std::size_t i = 0; i < a->uv.size(); ++i) {
        CHECK(a->uv[i].x == b->uv[i].x);
        CHECK(a->uv[i].y == b->uv[i].y);
    }
}

TEST_CASE("lightmap uv: errors say what to change") {
    CHECK_FALSE(generate_lightmap_uv({}, {}, {}).ok());
    const ModelMesh cube = make_cube();
    auto bad = cube.indices;
    bad[1] = 9999;
    auto e = generate_lightmap_uv(cube.positions, cube.normals, bad);
    REQUIRE_FALSE(e.ok());
    CHECK(e.error().message.find("9999") != std::string::npos);
    auto few = cube.normals;
    few.pop_back();
    CHECK_FALSE(generate_lightmap_uv(cube.positions, few, cube.indices).ok());
}

// ---- the manifest ---------------------------------------------------------------------------------------------------------------------

namespace {
Json good_manifest() {
    return Json::parse(R"({
      "version": 1, "uvVersion": 1, "settingsHash": "abc",
      "pages": [{"file": "scenes/a.lightmap.0.hdr", "width": 64, "height": 64}],
      "entities": [
        {"id": "e1", "mesh": "cube", "uv": "generated", "meshHash": "0123456789abcdef", "page": 0, "scaleOffset": [0.5, 0.5, 0.5, 0.0]},
        {"id": "e2", "page": 0, "scaleOffset": [0.5, 0.5, 0.0, 0.0]}
      ]})");
}
std::string error_of(const Json& j) {
    auto r = parse_lightmap_manifest(j, "scenes/a.lightmap.json");
    REQUIRE_FALSE(r.ok());
    return r.error().to_string();
}
}  // namespace

TEST_CASE("lightmap manifest: a good manifest is read, found by entity id and written back the same") {
    auto r = parse_lightmap_manifest(good_manifest(), "x.json");
    REQUIRE(r.ok());
    CHECK(r->pages.size() == 1);
    REQUIRE(r->find("e1") != nullptr);
    CHECK(r->find("e1")->uv == "generated");
    CHECK(r->find("e1")->scaleOffset[2] == doctest::Approx(0.5f));
    CHECK(r->find("missing") == nullptr);
    auto again = parse_lightmap_manifest(lightmap_manifest_to_json(*r), "x.json");
    REQUIRE(again.ok());
    CHECK(lightmap_manifest_to_json(*again) == lightmap_manifest_to_json(*r));
}

TEST_CASE("lightmap manifest: errors name the file, the JSON pointer and the fix") {
    {
        Json j = good_manifest();
        j["entities"][1]["page"] = 3;
        const std::string e = error_of(j);
        CHECK(e.find("scenes/a.lightmap.json") != std::string::npos);
        CHECK(e.find("/entities/1/page") != std::string::npos);
        CHECK(e.find("1 page") != std::string::npos);
    }
    {
        Json j = good_manifest();
        j["entities"][0]["scaleOfset"] = 1;
        const std::string e = error_of(j);
        CHECK(e.find("/entities/0/scaleOfset") != std::string::npos);
        CHECK(e.find("scaleOffset") != std::string::npos);  // did you mean
    }
    {
        Json j = good_manifest();
        j["entities"][1]["id"] = "e1";
        CHECK(error_of(j).find("/entities/1/id") != std::string::npos);
    }
    {
        Json j = good_manifest();
        j["entities"][0]["scaleOffset"] = Json::array({0.75, 0.5, 0.5, 0.0});
        const std::string e = error_of(j);
        CHECK(e.find("/entities/0/scaleOffset") != std::string::npos);
        CHECK(e.find("inside the page") != std::string::npos);
    }
    {
        Json j = good_manifest();
        j["version"] = 2;
        CHECK(error_of(j).find("/version") != std::string::npos);
    }
    {
        Json j = good_manifest();
        j["uvVersion"] = 99;
        CHECK(error_of(j).find("bake the lightmaps again") != std::string::npos);
    }
    {
        Json j = good_manifest();
        j["pages"][0]["file"] = "a.png";
        CHECK(error_of(j).find("/pages/0/file") != std::string::npos);
    }
    {
        Json j = good_manifest();
        j["entities"][0]["meshHash"] = "XYZ";
        CHECK(error_of(j).find("/entities/0/meshHash") != std::string::npos);
    }
    CHECK_FALSE(parse_lightmap_manifest(Json::array(), "x.json").ok());
}

TEST_CASE("lightmap manifest: the texel density follows lightmapScale") {
    CHECK(lightmap_texels_per_meter(16, 1) == doctest::Approx(16));
    CHECK(lightmap_texels_per_meter(16, 0.5f) == doctest::Approx(8));
    CHECK(lightmap_texels_per_meter(16, 0) == 0);
    CHECK(lightmap_texels_per_meter(16, -1) == 0);
    CHECK(lightmap_texels_per_meter(16, 1000) == doctest::Approx(1600));
    CHECK(lightmap_texels_per_meter(16, std::nanf("")) == 0);
}

// ---- the page orientation -------------------------------------------------------------------------------------------------------------

TEST_CASE("lightmap page orientation: v = 0 of the bake is the first row of the .hdr and of the image") {
    // A floor quad whose v runs along +z (v = 0 at z = 0, v = 1 at z = 1). A box over the far half (z > 0.5) shades it from a light straight
    // above, so the rows of v < 0.5 are lit and those of v > 0.5 are dark.
    BakeScene sc;
    sc.atlases = {{16, 16}};
    BakeMesh floor;
    floor.name = "floor";
    floor.positions = {{0, 0, 0}, {1, 0, 0}, {1, 0, 1}, {0, 0, 1}};
    floor.normals = {{0, 1, 0}, {0, 1, 0}, {0, 1, 0}, {0, 1, 0}};
    floor.indices = {0, 2, 1, 0, 3, 2};
    floor.lightmapUv = {{0, 0}, {1, 0}, {1, 1}, {0, 1}};
    floor.atlas = 0;
    sc.meshes.push_back(floor);
    BakeMesh roof;  // a big plate at y = 0.5 above z in 0.5..1
    roof.name = "roof";
    roof.positions = {{-1, 0.5f, 0.5f}, {2, 0.5f, 0.5f}, {2, 0.5f, 2}, {-1, 0.5f, 2}};
    roof.indices = {0, 1, 2, 0, 2, 3};
    roof.atlas = -1;
    sc.meshes.push_back(roof);
    BakeLight sun;
    sun.kind = BakeLightKind::Directional;
    sun.direction = {0, -1, 0};
    sc.lights = {sun};
    BakeSettings st;
    st.samples = 4;
    st.bounces = 0;
    st.shadowSamples = 1;
    st.dilatePasses = 0;
    st.denoiseRadius = 0;
    auto baked = bake_lightmap(sc, st);
    REQUIRE(baked.ok());
    const BakedAtlas& a = baked->atlases[0];

    auto img = ImageF::create(a.width, a.height, 3);
    REQUIRE(img.ok());
    img->data = a.rgb;  // row 0 first: the atlas is written into the image as it is
    const std::vector<std::uint8_t> bytes = encode_hdr(*img);
    auto back = decode_hdr(bytes.data(), bytes.size());
    REQUIRE(back.ok());
    REQUIRE(back->width == 16);
    // The first row of the file (the top of the image, page v = 0) is lit; the last (v = 1) is in shadow.
    CHECK(back->at(8, 1)[0] > 0.5f);
    CHECK(back->at(8, 14)[0] < 0.05f);
}
