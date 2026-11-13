// UVs for engine-made models (model_uv.h): automatic unwrapping, the four projections, packing, texel density, the measurements, the `uv`
// section of a model document (including sdf results) and determinism.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <numbers>

#include "fa/scene/model_doc.h"
#include "fa/scene/model_uv.h"

using namespace fa;

namespace {

Json J(const char* text) { return parse_json(text, "test").value(); }

// Signed area of a triangle's uvs (cross of two edges, halved): negative for a triangle drawn counter-clockwise on the image with v down, which is
// what a counter-clockwise (seen from outside) triangle must be for the texture to read upright, not mirrored.
double signed_uv_area(const ModelMesh& m, std::size_t t) {
    const Vec2 a = m.uvs[m.indices[t * 3]], b = m.uvs[m.indices[t * 3 + 1]], c = m.uvs[m.indices[t * 3 + 2]];
    return 0.5 * (double(b.x - a.x) * double(c.y - a.y) - double(c.x - a.x) * double(b.y - a.y));
}

// The same triangles as before: the corners keep their position, normal and colour, and the triangles their part.
void check_same_geometry(const ModelMesh& before, const ModelMesh& after) {
    REQUIRE(before.triangle_count() == after.triangle_count());
    REQUIRE(after.uvs.size() == after.positions.size());
    CHECK(after.triParts.size() == before.triangle_count());
    bool same = true;
    for (std::size_t t = 0; t < before.triangle_count() && same; ++t) {
        if (!before.triParts.empty() && before.triParts[t] != after.triParts[t]) same = false;
        for (int k = 0; k < 3; ++k) {
            const std::uint32_t a = before.indices[t * 3 + std::size_t(k)], b = after.indices[t * 3 + std::size_t(k)];
            if (std::memcmp(&before.positions[a], &after.positions[b], sizeof(Vec3)) != 0) same = false;
            if (std::memcmp(&before.normals[a], &after.normals[b], sizeof(Vec3)) != 0) same = false;
            if (!before.colors.empty() && std::memcmp(&before.colors[a], &after.colors[b], sizeof(Vec4)) != 0)
                same = false;
        }
    }
    CHECK(same);
}

ModelUvSettings with_method(ModelUvMethod m, const char* layout = "atlas") {
    ModelUvSettings s;
    s.method = m;
    s.layout = layout;
    return s;
}

ModelUvResult apply_ok(const ModelMesh& mesh, const ModelUvSettings& s, const std::vector<std::string>& parts = {"a"},
                       ModelUvOptions o = {}) {
    auto r = model_uv_apply(mesh, parts, s, o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : r.error().to_string()));
    return std::move(*r);
}

std::uint64_t hash_uvs(const ModelMesh& m, float scale) {
    std::uint64_t h = 1469598103934665603ull;
    auto mix = [&](std::uint64_t v) { h = (h ^ v) * 1099511628211ull; };
    mix(m.vertex_count());
    mix(m.triangle_count());
    for (const Vec2& uv : m.uvs) {
        mix(std::uint64_t(std::int64_t(std::lround(uv.x * scale))));
        mix(std::uint64_t(std::int64_t(std::lround(uv.y * scale))));
    }
    return h;
}

ModelMesh moved(ModelMesh m, Vec3 by) {
    m.transform(Mat4::translate(by));
    return m;
}

bool same_bits(const ModelMesh& a, const ModelMesh& b) {
    return a.indices == b.indices && a.uvs.size() == b.uvs.size() &&
           std::memcmp(a.uvs.data(), b.uvs.data(), a.uvs.size() * sizeof(Vec2)) == 0 &&
           std::memcmp(a.positions.data(), b.positions.data(), a.positions.size() * sizeof(Vec3)) == 0;
}

// A mesh of three parts: a box, a cylinder and a sphere side by side (triParts 0, 1, 2).
ModelMesh three_parts(std::vector<std::string>& names) {
    ModelMesh box = model_box({});
    ModelMesh cyl = moved(model_cylinder({}), {2, 0, 0});
    cyl.set_part(1);
    ModelMesh sph = moved(model_sphere({}), {4, 0, 0});
    sph.set_part(2);
    box.append(cyl);
    box.append(sph);
    names = {"box", "cylinder", "sphere"};
    return box;
}

}  // namespace

TEST_CASE("unwrap: a box becomes six rectangles at the asked density, nothing stretched, mirrored or overlapping") {
    const ModelMesh box = model_box({});
    const ModelUvResult r = apply_ok(box, with_method(ModelUvMethod::Unwrap));
    check_same_geometry(box, r.mesh);
    CHECK(r.report.charts == 6);
    CHECK(r.report.texelsPerMeter == doctest::Approx(128).epsilon(0.03));
    CHECK(r.report.stretchMax < 1.05);
    CHECK(r.report.flippedTriangles == 0);
    CHECK(r.report.overlap == 0);
    CHECK(r.report.outsideTriangles == 0);
    CHECK(r.report.utilization > 0.2);
    CHECK(r.report.layout == "atlas");
    CHECK((r.report.textureSize & (r.report.textureSize - 1)) == 0);
    CHECK(r.report.parts.size() == 1);
    CHECK(r.report.parts[0].method == "unwrap");
    for (const Vec2& uv : r.mesh.uvs) {
        CHECK(uv.x >= 0);
        CHECK(uv.x <= 1);
        CHECK(uv.y >= 0);
        CHECK(uv.y <= 1);
    }
    for (std::size_t t = 0; t < r.mesh.triangle_count(); ++t) CHECK(signed_uv_area(r.mesh, t) < 0);
}

TEST_CASE("unwrap: curved surfaces keep their stretch low, with seams, and are never mirrored") {
    for (const ModelMesh& m : {model_sphere({}), model_cylinder({}), model_torus({}), model_capsule({})}) {
        const ModelUvResult r = apply_ok(m, with_method(ModelUvMethod::Unwrap));
        check_same_geometry(m, r.mesh);
        CHECK(r.report.stretchMean < 1.2);
        CHECK(r.report.flippedTriangles == 0);
        CHECK(r.report.overlap == 0);
        CHECK(r.report.outsideTriangles == 0);
        CHECK(r.report.seamEdges > 0);
        CHECK(r.report.texelsPerMeter == doctest::Approx(128).epsilon(0.1));
        CHECK(r.mesh.vertex_count() >= m.vertex_count());  // vertices are split along the seams
    }
}

TEST_CASE("unwrap: the seams option trades piece count for cut length") {
    for (const ModelMesh& m : {model_torus({}), model_sphere({}), model_capsule({})}) {
        ModelUvSettings few = with_method(ModelUvMethod::Unwrap), many = few;
        few.seams = "few";
        many.seams = "many";
        const ModelUvResult a = apply_ok(m, few), b = apply_ok(m, many);
        CHECK(a.report.charts <= b.report.charts);
        CHECK(a.report.seamLength <= b.report.seamLength + 1e-6);
    }
}

TEST_CASE("unwrap: a mesh with a degenerate triangle still gets finite uvs") {
    ModelMesh m = model_box({});
    // a triangle whose three corners are the same point
    m.positions.push_back({0.5f, 0.5f, 0.5f});
    m.normals.push_back({0, 0, 1});
    m.uvs.push_back({0, 0});
    const std::uint32_t v = std::uint32_t(m.positions.size() - 1);
    m.indices.insert(m.indices.end(), {v, v, v});
    m.triParts.push_back(0);
    const ModelUvResult r = apply_ok(m, with_method(ModelUvMethod::Unwrap));
    for (const Vec2& uv : r.mesh.uvs) {
        CHECK(std::isfinite(uv.x));
        CHECK(std::isfinite(uv.y));
    }
    CHECK(r.mesh.triangle_count() == m.triangle_count());
}

TEST_CASE("box projection: world scale, upright, one chart per connected face") {
    ModelBoxParams p;
    p.size = {2, 1, 0.5f};
    const ModelMesh box = model_box(p);
    ModelUvSettings s = with_method(ModelUvMethod::Box, "tile");
    s.texelsPerUnit = 100.0f;
    s.textureSize = 1024;  // one metre is 100/1024 of the uv range
    const ModelUvResult r = apply_ok(box, s);
    check_same_geometry(box, r.mesh);
    CHECK(r.report.charts == 6);
    CHECK(r.report.stretchMax < 1.0001);
    CHECK(r.report.flippedTriangles == 0);
    CHECK(r.report.texelsPerMeter == doctest::Approx(100).epsilon(0.001));
    for (std::size_t t = 0; t < r.mesh.triangle_count(); ++t) CHECK(signed_uv_area(r.mesh, t) < 0);
    // the +z face: u grows with x, v shrinks as y grows, one metre is 100 texels
    for (std::size_t t = 0; t < r.mesh.triangle_count(); ++t) {
        const Vec3 n = r.mesh.normals[r.mesh.indices[t * 3]];
        if (n.z < 0.99f) continue;
        const std::uint32_t a = r.mesh.indices[t * 3], b = r.mesh.indices[t * 3 + 1], c = r.mesh.indices[t * 3 + 2];
        for (std::uint32_t i : {b, c}) {
            const Vec3 dp = r.mesh.positions[i] - r.mesh.positions[a];
            const Vec2 du = r.mesh.uvs[i] - r.mesh.uvs[a];
            CHECK(du.x == doctest::Approx(dp.x * 100 / 1024).epsilon(1e-3).scale(0.01));
            CHECK(du.y == doctest::Approx(-dp.y * 100 / 1024).epsilon(1e-3).scale(0.01));
        }
    }
}

TEST_CASE("box projection: a part with many faces is cut only where the dominant axis changes") {
    const ModelMesh sphere = model_sphere({});
    const ModelUvResult r = apply_ok(sphere, with_method(ModelUvMethod::Box, "tile"));
    CHECK(r.report.charts >= 6);
    CHECK(r.report.charts <= 12);
    CHECK(r.report.flippedTriangles == 0);
    CHECK(r.report.stretchMax < 2.0);
}

TEST_CASE("cylinder projection: u is the arc length around the axis, v the height, caps are flat") {
    ModelCylinderParams cp;
    cp.radius = 0.5f;
    cp.height = 2;
    cp.segments = 32;
    const ModelMesh cyl = model_cylinder(cp);
    ModelUvSettings s = with_method(ModelUvMethod::Cylinder, "tile");
    s.texelsPerUnit = 128.0f;
    s.textureSize = 1024;
    const ModelUvResult r = apply_ok(cyl, s);
    check_same_geometry(cyl, r.mesh);
    CHECK(r.report.charts == 3);  // the side and the two caps
    CHECK(r.report.flippedTriangles == 0);
    CHECK(r.report.stretchMax < 1.02);
    CHECK(r.report.texelsPerMeter == doctest::Approx(128).epsilon(0.01));
    // the side wraps once around: its u span is the circumference (a polygon's perimeter is a hair shorter)
    float lo = 1e9f, hi = -1e9f;
    for (std::size_t t = 0; t < r.mesh.triangle_count(); ++t) {
        const Vec3 n = r.mesh.normals[r.mesh.indices[t * 3]];
        if (std::fabs(n.y) > 0.5f) continue;
        for (int k = 0; k < 3; ++k) {
            lo = std::min(lo, r.mesh.uvs[r.mesh.indices[t * 3 + std::size_t(k)]].x);
            hi = std::max(hi, r.mesh.uvs[r.mesh.indices[t * 3 + std::size_t(k)]].x);
        }
    }
    CHECK((hi - lo) * 1024 / 128 == doctest::Approx(2 * std::numbers::pi * 0.5).epsilon(0.01));
    for (std::size_t t = 0; t < r.mesh.triangle_count(); ++t) CHECK(signed_uv_area(r.mesh, t) < 0);
}

TEST_CASE("cylinder projection: the axis can be x or z") {
    ModelMesh cyl = model_cylinder({});
    cyl.transform(Mat4::rotate_z_deg(90));  // lies along x
    ModelUvSettings s = with_method(ModelUvMethod::Cylinder, "tile");
    s.axis = 'x';
    const ModelUvResult r = apply_ok(cyl, s);
    CHECK(r.report.charts == 3);
    CHECK(r.report.stretchMax < 1.05);
    CHECK(r.report.flippedTriangles == 0);
}

TEST_CASE("sphere projection: longitude and latitude, one seam, nothing mirrored") {
    const ModelMesh sphere = model_sphere({});
    ModelUvSettings s = with_method(ModelUvMethod::Sphere, "tile");
    s.textureSize = 1024;
    const ModelUvResult r = apply_ok(sphere, s);
    check_same_geometry(sphere, r.mesh);
    CHECK(r.report.charts == 1);
    CHECK(r.report.flippedTriangles == 0);
    float vlo = 1e9f, vhi = -1e9f;
    for (const Vec2& uv : r.mesh.uvs) {
        vlo = std::min(vlo, uv.y);
        vhi = std::max(vhi, uv.y);
    }
    // pole to pole is half a turn of the sphere's radius
    CHECK((vhi - vlo) * 1024 / 128 == doctest::Approx(std::numbers::pi * 0.5).epsilon(0.01));
    // the equator band is not stretched (poles are: that is a sphere's projection)
    CHECK(r.report.texelsPerMeterMin == doctest::Approx(128).epsilon(0.05));
}

TEST_CASE("planar projection: everything along one axis, the same uv for the same point") {
    ModelGridParams gp;
    gp.width = 2;
    gp.depth = 1;
    gp.segX = 4;
    gp.segZ = 2;
    const ModelMesh grid = model_grid(gp);
    ModelUvSettings s = with_method(ModelUvMethod::Planar, "tile");
    s.axis = 'y';
    s.textureSize = 1024;
    const ModelUvResult r = apply_ok(grid, s);
    CHECK(r.report.charts == 1);
    CHECK(r.report.stretchMax < 1.0001);
    CHECK(r.report.seamEdges == 0);
    // looked at from above (+y), x grows to the right and z towards the viewer, which is down the image
    for (std::size_t i = 0; i < r.mesh.vertex_count(); ++i) {
        CHECK(r.mesh.uvs[i].x == doctest::Approx(r.mesh.positions[i].x * 128 / 1024).epsilon(1e-4).scale(0.01));
        CHECK(r.mesh.uvs[i].y == doctest::Approx(r.mesh.positions[i].z * 128 / 1024).epsilon(1e-4).scale(0.01));
    }
}

TEST_CASE("per-part methods and density: each part gets its own projection and its own texels per metre") {
    std::vector<std::string> names;
    const ModelMesh mesh = three_parts(names);
    ModelUvSettings s;
    s.method = ModelUvMethod::Box;
    s.texelsPerUnit = 64.0f;
    ModelUvPartSettings cyl;
    cyl.method = ModelUvMethod::Cylinder;
    ModelUvPartSettings sph;
    sph.method = ModelUvMethod::Sphere;
    sph.texelsPerUnit = 256.0f;
    s.parts.emplace_back("cylinder", cyl);
    s.parts.emplace_back("sphere", sph);
    const ModelUvResult r = apply_ok(mesh, s, names);
    check_same_geometry(mesh, r.mesh);
    REQUIRE(r.report.parts.size() == 3);
    CHECK(r.report.parts[0].method == "box");
    CHECK(r.report.parts[1].method == "cylinder");
    CHECK(r.report.parts[2].method == "sphere");
    CHECK(r.report.parts[0].texelsPerMeter == doctest::Approx(64).epsilon(0.05));
    CHECK(r.report.parts[1].texelsPerMeter == doctest::Approx(64).epsilon(0.1));
    CHECK(r.report.parts[2].texelsPerMeter > 200);
    CHECK(r.report.overlap == 0);
    CHECK(r.report.outsideTriangles == 0);
}

TEST_CASE("a part can unwrap while another is projected, in one atlas") {
    std::vector<std::string> names;
    const ModelMesh mesh = three_parts(names);
    ModelUvSettings s;
    s.method = ModelUvMethod::Unwrap;
    ModelUvPartSettings box;
    box.method = ModelUvMethod::Box;
    s.parts.emplace_back("box", box);
    const ModelUvResult r = apply_ok(mesh, s, names);
    CHECK(r.report.parts[0].method == "box");
    CHECK(r.report.parts[1].method == "unwrap");
    CHECK(r.report.overlap == 0);
    CHECK(r.report.outsideTriangles == 0);
    CHECK(r.report.flippedTriangles == 0);
}

TEST_CASE("packing: pieces stay apart by the padding and inside the texture") {
    std::vector<std::string> names;
    const ModelMesh mesh = three_parts(names);
    ModelUvSettings s = with_method(ModelUvMethod::Box);
    s.padding = 4;
    s.textureSize = 512;
    s.texelsPerUnit = 64.0f;
    const ModelUvResult r = apply_ok(mesh, s, names);
    CHECK(r.report.textureSize == 512);
    CHECK(r.report.overlap == 0);
    CHECK(r.report.outsideTriangles == 0);
    // rectangles of the box part's six faces: their bounding boxes (the charts are rectangles) are at least `padding` texels apart
    struct Rect {
        float x0, y0, x1, y1;
    };
    std::vector<Rect> rects;
    for (std::size_t face = 0; face < 6; ++face) {
        Rect rc{1e9f, 1e9f, -1e9f, -1e9f};
        for (std::size_t t = face * 2; t < face * 2 + 2; ++t)
            for (int k = 0; k < 3; ++k) {
                const Vec2 uv = r.mesh.uvs[r.mesh.indices[t * 3 + std::size_t(k)]];
                rc = {std::min(rc.x0, uv.x), std::min(rc.y0, uv.y), std::max(rc.x1, uv.x), std::max(rc.y1, uv.y)};
            }
        rects.push_back(rc);
    }
    const float pad = 3.9f / 512;
    for (std::size_t i = 0; i < rects.size(); ++i)
        for (std::size_t j = i + 1; j < rects.size(); ++j) {
            const bool apart = rects[i].x1 + pad <= rects[j].x0 || rects[j].x1 + pad <= rects[i].x0 ||
                               rects[i].y1 + pad <= rects[j].y0 || rects[j].y1 + pad <= rects[i].y0;
            CHECK(apart);
        }
}

TEST_CASE("packing: the texture size is the smallest power of two the pieces fit in, and a bigger density needs a "
          "bigger one") {
    const ModelMesh sphere = model_sphere({});
    ModelUvSettings s = with_method(ModelUvMethod::Unwrap);
    s.texelsPerUnit = 32.0f;
    const ModelUvResult small = apply_ok(sphere, s);
    s.texelsPerUnit = 512.0f;
    const ModelUvResult big = apply_ok(sphere, s);
    CHECK(small.report.textureSize < big.report.textureSize);
    CHECK((big.report.textureSize & (big.report.textureSize - 1)) == 0);
    CHECK(big.report.utilization > 0.1);
    CHECK(small.report.texelsPerUnitUsed == doctest::Approx(32));
    CHECK(big.report.texelsPerUnitUsed == doctest::Approx(512));
}

TEST_CASE(
    "density: the style's density is the default, the document's wins, a texture too small lowers it with a warning") {
    const ModelMesh sphere = model_sphere({});
    ModelUvOptions style;
    style.defaultTexelsPerMeter = 256;
    ModelUvSettings s = with_method(ModelUvMethod::Unwrap);
    const ModelUvResult fromStyle = apply_ok(sphere, s, {"a"}, style);
    CHECK(fromStyle.report.texelsPerUnit == doctest::Approx(256));
    CHECK(fromStyle.report.texelsPerMeter == doctest::Approx(256).epsilon(0.1));
    s.texelsPerUnit = 64.0f;
    const ModelUvResult own = apply_ok(sphere, s, {"a"}, style);
    CHECK(own.report.texelsPerUnit == doctest::Approx(64));
    const ModelUvResult none = apply_ok(sphere, with_method(ModelUvMethod::Unwrap));
    CHECK(none.report.texelsPerUnit == doctest::Approx(kModelUvDefaultTexelsPerMeter));

    ModelUvSettings tight = with_method(ModelUvMethod::Unwrap);
    tight.texelsPerUnit = 1024.0f;
    tight.textureSize = 128;
    const ModelUvResult shrunk = apply_ok(sphere, tight);
    CHECK(shrunk.report.textureSize == 128);
    CHECK(shrunk.report.texelsPerUnitUsed < 1024);
    CHECK(shrunk.report.texelsPerUnitUsed > 25);
    CHECK(shrunk.report.outsideTriangles == 0);
    CHECK(shrunk.report.overlap == 0);
    bool warned = false;
    for (const std::string& w : shrunk.report.warnings) warned = warned || w.find("lowered") != std::string::npos;
    CHECK(warned);
}

TEST_CASE("tile layout: uvs continue across parts and cannot unwrap") {
    std::vector<std::string> names;
    const ModelMesh mesh = three_parts(names);
    ModelUvSettings s;
    s.layout = "tile";
    const ModelUvResult r = apply_ok(mesh, s, names);  // default method for tile: box
    CHECK(r.report.layout == "tile");
    CHECK(r.report.parts[0].method == "box");
    CHECK(r.report.texelsPerMeter == doctest::Approx(128).epsilon(0.1));
    s.method = ModelUvMethod::Unwrap;
    auto bad = model_uv_apply(mesh, names, s);
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("unwrap") != std::string::npos);
    CHECK_FALSE(bad.error().hint.empty());
}

TEST_CASE("model_uv_apply: bad settings say what to change") {
    const ModelMesh box = model_box({});
    ModelUvSettings s;
    s.layout = "grid";
    auto a = model_uv_apply(box, {"a"}, s);
    REQUIRE_FALSE(a.ok());
    CHECK(a.error().message.find("layout") != std::string::npos);
    s = ModelUvSettings{};
    s.textureSize = 8;
    CHECK_FALSE(model_uv_apply(box, {"a"}, s).ok());
    s = ModelUvSettings{};
    s.padding = 99;
    CHECK_FALSE(model_uv_apply(box, {"a"}, s).ok());
    CHECK_FALSE(model_uv_apply(ModelMesh{}, {"a"}, ModelUvSettings{}).ok());
}

TEST_CASE("model_uv_measure: reads the uvs a mesh already has") {
    const ModelMesh box = model_box({});
    const ModelUvReport r = model_uv_measure(box, {"a"});
    CHECK(r.triangles == 12);
    CHECK(r.charts >= 1);
    // a unit cube's faces each have the uvs of a unit square: 1 uv unit per metre (1024 texels at the default 1024)
    CHECK(r.texelsPerMeter == doctest::Approx(1024).epsilon(0.01));
    CHECK(r.stretchMax < 1.001);
    ModelMesh none = box;
    none.uvs.clear();
    const ModelUvReport empty = model_uv_measure(none, {"a"});
    CHECK_FALSE(empty.warnings.empty());
}

TEST_CASE("model_uv_measure: overlap, mirroring and out-of-range uvs are reported") {
    ModelMesh m;
    m.positions = {{0, 0, 0}, {1, 0, 0}, {0, 1, 0}, {0, 0, 0}, {1, 0, 0}, {0, 1, 0}};
    m.normals.assign(6, Vec3{0, 0, 1});
    m.uvs = {{0.1f, 0.1f}, {0.5f, 0.1f}, {0.1f, 0.5f}, {0.1f, 0.1f}, {0.5f, 0.1f}, {0.1f, 0.5f}};
    m.indices = {0, 1, 2, 3, 4, 5};
    m.triParts = {0, 0};
    const ModelUvReport r = model_uv_measure(m, {"a"}, "atlas", 256);
    CHECK(r.overlap > 0.9);
    ModelMesh out = m;
    out.uvs[1] = {1.5f, 0.1f};
    CHECK(model_uv_measure(out, {"a"}, "atlas", 256).outsideTriangles >= 1);
}

TEST_CASE("determinism: the same mesh and settings give the same bits, and the same layout") {
    std::vector<std::string> names;
    const ModelMesh mesh = three_parts(names);
    for (ModelUvMethod m :
         {ModelUvMethod::Unwrap, ModelUvMethod::Box, ModelUvMethod::Cylinder, ModelUvMethod::Sphere}) {
        const ModelUvResult a = apply_ok(mesh, with_method(m), names);
        const ModelUvResult b = apply_ok(mesh, with_method(m), names);
        CHECK(same_bits(a.mesh, b.mesh));
        CHECK(a.report.textureSize == b.report.textureSize);
    }
}

TEST_CASE("determinism: the layout of a fixed model has a known fingerprint (the same on every platform)") {
    std::vector<std::string> names;
    const ModelMesh mesh = three_parts(names);
    ModelUvSettings s;  // unwrap everything
    const ModelUvResult r = apply_ok(mesh, s, names);
    // Counts and a hash of the uvs rounded to 1/64: a platform whose trigonometry or float rules differ would cut or place pieces differently.
    CHECK(r.report.charts == 18);
    CHECK(r.mesh.vertex_count() == 581);
    CHECK(r.report.textureSize == 1024);
    CHECK(hash_uvs(r.mesh, 64) == 1336127245979059713ull);
}

TEST_CASE("the uv section of a model document: unwrap by default, per-part methods, reported in the build") {
    auto doc = parse_model_doc(
        J(R"({"format":"factoria.model/1","uv":{"texelsPerUnit":64,"parts":{"wheel":{"method":"cylinder","axis":"x"}}},
        "nodes":[{"op":"box","part":"body","size":[2,0.5,1]},
                 {"op":"cylinder","part":"wheel","rotation":[0,0,90],"radius":0.3,"height":0.2,"position":[0,-0.3,0.6]}]})"),
        "t.model.json");
    REQUIRE_MESSAGE(doc.ok(), (doc.ok() ? std::string() : doc.error().to_string()));
    REQUIRE(doc->uv.has_value());
    auto built = evaluate_model(*doc);
    REQUIRE_MESSAGE(built.ok(), (built.ok() ? std::string() : built.error().to_string()));
    REQUIRE(built->uv.has_value());
    CHECK(built->uv->texelsPerUnit == doctest::Approx(64));
    CHECK(built->uv->parts.size() == 2);
    CHECK(built->uv->overlap == 0);
    CHECK(built->data.hasUvs);
    CHECK(built->warnings.empty());
    // the style's density flows through the evaluation options
    ModelEvalOptions o;
    o.defaultTexelsPerMeter = 200;
    auto doc2 = parse_model_doc(J(R"({"format":"factoria.model/1","uv":{},"nodes":[{"op":"box"}]})"), "t.model.json");
    REQUIRE(doc2.ok());
    auto built2 = evaluate_model(*doc2, o);
    REQUIRE(built2.ok());
    CHECK(built2->uv->texelsPerUnit == doctest::Approx(200));
    CHECK(built2->uv->texelsPerMeter == doctest::Approx(200).epsilon(0.05));
    // a document without a uv section keeps the primitives' uvs and reports nothing
    auto doc3 = parse_model_doc(J(R"({"format":"factoria.model/1","nodes":[{"op":"box"}]})"), "t.model.json");
    REQUIRE(doc3.ok());
    CHECK_FALSE(evaluate_model(*doc3)->uv.has_value());
}

TEST_CASE("the uv section names a part no node makes: a warning with a suggestion") {
    auto doc = parse_model_doc(J(R"({"format":"factoria.model/1","uv":{"parts":{"whel":{"method":"box"}}},
        "nodes":[{"op":"cylinder","part":"wheel"}]})"),
                               "t.model.json");
    REQUIRE(doc.ok());
    auto built = evaluate_model(*doc);
    REQUIRE(built.ok());
    REQUIRE_FALSE(built->warnings.empty());
    CHECK(built->warnings[0].find("whel") != std::string::npos);
    CHECK(built->warnings[0].find("wheel") != std::string::npos);
}

TEST_CASE("sdf results: the uv section replaces the default box uvs, per part") {
    const char* sdf = R"("nodes":[{"op":"sdf","children":[
        {"op":"sdf_ellipsoid","radii":[0.6,0.45,0.5],"part":"body"},
        {"op":"sdf_sphere","radius":0.3,"position":[0.5,0.2,0],"part":"head","smooth":0.2}]}]})";
    auto plain = parse_model_doc(J((std::string(R"({"format":"factoria.model/1",)") + sdf).c_str()), "t.model.json");
    REQUIRE(plain.ok());
    auto before = evaluate_model(*plain);
    REQUIRE(before.ok());
    auto doc = parse_model_doc(
        J((std::string(
               R"({"format":"factoria.model/1","uv":{"method":"unwrap","parts":{"head":{"method":"sphere"}}},)") +
           sdf)
              .c_str()),
        "t.model.json");
    REQUIRE(doc.ok());
    auto built = evaluate_model(*doc);
    REQUIRE_MESSAGE(built.ok(), (built.ok() ? std::string() : built.error().to_string()));
    REQUIRE(built->uv.has_value());
    CHECK(built->uv->layout == "atlas");
    REQUIRE(built->uv->parts.size() == 2);
    // a lat-long map folds the few triangles that contain the pole itself onto their neighbours; nothing else is mirrored or
    // overlaps (the same model with the head unwrapped instead has no overlap at all)
    CHECK(built->uv->overlap < 0.01);
    CHECK(built->uv->outsideTriangles == 0);
    CHECK(built->uv->flippedTriangles <= built->uv->triangles / 100);
    {
        auto unwrapped =
            parse_model_doc(J((std::string(R"({"format":"factoria.model/1","uv":{"method":"unwrap"},)") + sdf).c_str()),
                            "t.model.json");
        REQUIRE(unwrapped.ok());
        auto all = evaluate_model(*unwrapped);
        REQUIRE(all.ok());
        REQUIRE(all->uv.has_value());
        CHECK(all->uv->overlap == 0);
        CHECK(all->uv->flippedTriangles == 0);
    }
    CHECK(built->data.triangle_count() == before->data.triangle_count());
    // the sdf's own uvs were 1 per metre box uvs, outside [0, 1]; now they are an atlas
    for (float v : built->data.uvs) {
        CHECK(v >= 0);
        CHECK(v <= 1);
    }
    CHECK(built->data.uvs != before->data.uvs);
    std::vector<std::string> parts;
    for (const auto& p : built->uv->parts) parts.push_back(p.part + ":" + p.method);
    CHECK(std::find(parts.begin(), parts.end(), "body:unwrap") != parts.end());
    CHECK(std::find(parts.begin(), parts.end(), "head:sphere") != parts.end());
}

namespace {
std::vector<ModelIssue> uv_issues(const char* uvJson) {
    std::vector<ModelIssue> issues;
    (void)parse_model_doc(
        J((std::string(R"({"format":"factoria.model/1","nodes":[{"op":"box"}],"uv":)") + uvJson + "}").c_str()),
        "t.model.json", &issues);
    return issues;
}
}  // namespace

TEST_CASE("uv section errors: pointer, what is wrong, how to fix it, did you mean") {
    auto a = uv_issues(R"({"metod":"box"})");
    REQUIRE(a.size() == 1);
    CHECK(a[0].pointer == "/uv/metod");
    CHECK(a[0].hint.find("method") != std::string::npos);
    auto b = uv_issues(R"({"method":"cylindr"})");
    REQUIRE(b.size() == 1);
    CHECK(b[0].pointer == "/uv/method");
    CHECK(b[0].hint.find("cylinder") != std::string::npos);
    auto c = uv_issues(R"({"texelsPerUnit":0})");
    REQUIRE(c.size() == 1);
    CHECK(c[0].pointer == "/uv/texelsPerUnit");
    auto d = uv_issues(R"({"textureSize":100000,"padding":-1,"seams":"lots","rotate":1,"axis":"w","layout":"grid"})");
    CHECK(d.size() == 6);
    auto e = uv_issues(R"({"parts":{"wheel":{"method":"box","axix":"y"},"door":3}})");
    REQUIRE(e.size() == 2);
    CHECK(e[0].pointer == "/uv/parts/wheel/axix");
    CHECK(e[1].pointer == "/uv/parts/door");
    auto f = uv_issues(R"({"layout":"tile","method":"unwrap"})");
    REQUIRE(f.size() == 1);
    CHECK(f[0].pointer == "/uv/method");
    auto g = uv_issues("7");
    REQUIRE(g.size() == 1);
    CHECK(g[0].pointer == "/uv");
    CHECK(
        uv_issues(
            R"({"layout":"tile","method":"box","parts":{"a":{"method":"sphere"}},"textureSize":2048,"padding":0,"seams":"few","rotate":false})")
            .empty());
}

TEST_CASE("model_doc_schema() lists the uv section") {
    const Json schema = model_doc_schema();
    REQUIRE(schema["properties"].contains("uv"));
    CHECK(schema["properties"]["uv"]["properties"].contains("texelsPerUnit"));
    CHECK(schema["properties"]["uv"]["properties"]["parts"]["additionalProperties"]["properties"].contains("method"));
}

TEST_CASE("model_uv_settings_json round-trips through the reader") {
    ModelUvSettings s;
    s.layout = "tile";
    s.method = ModelUvMethod::Cylinder;
    s.axis = 'z';
    s.texelsPerUnit = 90.0f;
    s.textureSize = 512;
    s.padding = 3;
    s.seams = "many";
    s.rotate = true;
    ModelUvPartSettings p;
    p.method = ModelUvMethod::Sphere;
    p.axis = 'x';
    p.texelsPerUnit = 40.0f;
    s.parts.emplace_back("ball", p);
    std::vector<ModelIssue> issues;
    auto back = parse_model_uv(model_uv_settings_json(s), issues);
    REQUIRE(issues.empty());
    REQUIRE(back.has_value());
    CHECK(model_uv_settings_json(*back) == model_uv_settings_json(s));
}

TEST_CASE("unwrap: a heavy mesh (tens of thousands of triangles) unwraps in bounded time") {
    ModelSphereParams sp;
    sp.segments = 160;
    const ModelMesh sphere = model_sphere(sp);
    REQUIRE(sphere.triangle_count() > 20000);
    ModelUvSettings s = with_method(ModelUvMethod::Unwrap);
    const ModelUvResult r = apply_ok(sphere, s);
    check_same_geometry(sphere, r.mesh);
    CHECK(r.report.overlap == 0);
    CHECK(r.report.outsideTriangles == 0);
    CHECK(r.report.flippedTriangles == 0);
}
