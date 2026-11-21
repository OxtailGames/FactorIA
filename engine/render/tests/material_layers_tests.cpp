// The material layers of M73.6: clear coat, sheen, anisotropy and the dielectric specular (ior, specular) of the standard mesh
// shading, and the import of the glTF extensions that carry them (KHR_materials_clearcoat, _sheen, _anisotropy, _specular, _ior).
// The packing of the layers' textures into the maps a part already binds is tested without a GPU; the shading runs on the
// backend of the machine, and a layer that is off must draw the pixels it drew before the layers existed.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <string>
#include <vector>

#include "fa/core/fs.h"
#include "render_internal.h"

using namespace fa;
using namespace fa::test;
using fa::render::kMaxLayerPackPixels;
using fa::render::LayerTextureRefs;
using fa::render::PreparedMesh;
using fa::render::PreparedTextureRef;
using Kind = fa::render::PreparedTextureRef::Kind;

namespace {

// ---------------------------------------------------------------------------------------------------------------------
// Packing
// ---------------------------------------------------------------------------------------------------------------------
Image solid(int w, int h, std::uint8_t r, std::uint8_t g, std::uint8_t b, std::uint8_t a) {
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

PreparedTextureRef image_ref(Image img, const char* name) {
    PreparedTextureRef r;
    r.kind = Kind::Image;
    r.name = name;
    r.image = std::make_shared<const Image>(std::move(img));
    return r;
}

bool has(const std::vector<std::string>& w, const std::string& text) {
    return std::any_of(w.begin(), w.end(), [&](const std::string& s) { return s.find(text) != std::string::npos; });
}

// ---------------------------------------------------------------------------------------------------------------------
// glTF fixtures: one triangle, the buffer embedded as a data URI, the layer textures as PNGs in the test project.
// ---------------------------------------------------------------------------------------------------------------------
std::string base64(const std::uint8_t* d, std::size_t n) {
    static const char* t = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    std::string out;
    for (std::size_t i = 0; i < n; i += 3) {
        const std::uint32_t v = (std::uint32_t(d[i]) << 16) | (i + 1 < n ? std::uint32_t(d[i + 1]) << 8 : 0) |
                                (i + 2 < n ? std::uint32_t(d[i + 2]) : 0);
        out += t[(v >> 18) & 63];
        out += t[(v >> 12) & 63];
        out += i + 1 < n ? t[(v >> 6) & 63] : '=';
        out += i + 2 < n ? t[v & 63] : '=';
    }
    return out;
}

std::string triangle_gltf(const Json& materials, const Json& images, const Json& textures) {
    const float tri[9] = {0, 0, 0, 1, 0, 0, 0, 1, 0};
    std::uint8_t bin[36];
    std::memcpy(bin, tri, 36);
    Json doc;
    doc["asset"] = {{"version", "2.0"}};
    doc["buffers"] =
        Json::array({Json{{"byteLength", 36}, {"uri", "data:application/octet-stream;base64," + base64(bin, 36)}}});
    doc["bufferViews"] = Json::array({Json{{"buffer", 0}, {"byteOffset", 0}, {"byteLength", 36}}});
    doc["accessors"] = Json::array({Json{{"bufferView", 0},
                                         {"componentType", 5126},
                                         {"count", 3},
                                         {"type", "VEC3"},
                                         {"min", Json::array({0, 0, 0})},
                                         {"max", Json::array({1, 1, 0})}}});
    doc["meshes"] =
        Json::array({Json{{"primitives", Json::array({Json{{"attributes", {{"POSITION", 0}}}, {"material", 0}}})}}});
    doc["nodes"] = Json::array({Json{{"mesh", 0}}});
    doc["scenes"] = Json::array({Json{{"nodes", Json::array({0})}}});
    doc["materials"] = materials;
    if (!images.empty()) doc["images"] = images;
    if (!textures.empty()) doc["textures"] = textures;
    return doc.dump();
}

bool decode(const std::string& gltfPath, const std::string& text, PreparedMesh& out, std::string& error) {
    return fa::render::decode_gltf(gltfPath, reinterpret_cast<const std::uint8_t*>(text.data()), text.size(), out,
                                   error);
}

// ---------------------------------------------------------------------------------------------------------------------
// Shading
// ---------------------------------------------------------------------------------------------------------------------
// A sphere lit by one directional light along -Z (from the camera), over a black sky and no ambient light.
struct Ball {
    World world;
    Entity cam, ball, sun;

    explicit Ball(Color albedo = Color{0, 0, 0, 1}, float metallic = 0.0f, float roughness = 0.6f, float light = 4.0f) {
        cam = make(world, "cam", {0, 0, 4});
        auto& c = world.add<Camera>(cam);
        c.projection = Projection::Perspective;
        c.fov = 40;
        world.settings().ambientLight = Color{0, 0, 0, 1};
        world.settings().skyColor = Color{0, 0, 0, 1};
        world.settings().horizonColor = Color{0, 0, 0, 1};
        ball = make(world, "ball", {0, 0, 0});
        auto& m = world.add<MeshRenderer>(ball);
        m.mesh = "sphere";
        m.color = albedo;
        m.metallic = metallic;
        m.roughness = roughness;
        sun = make(world, "sun", {0, 0, 4});
        auto& l = world.add<Light>(sun);
        l.type = LightType::Directional;
        l.intensity = light;
        l.castShadows = false;
    }
    MeshRenderer& mesh() { return *world.get<MeshRenderer>(ball); }
    Light& light() { return *world.get<Light>(sun); }
};

double mean_abs_diff(const Image& a, const Image& b) {
    REQUIRE(a.width == b.width);
    REQUIRE(a.height == b.height);
    double sum = 0;
    for (std::size_t i = 0; i < a.rgba.size(); ++i) sum += std::abs(int(a.rgba[i]) - int(b.rgba[i])) / 255.0;
    return sum / double(a.rgba.size());
}

double brightness(const Image& img) {
    double sum = 0;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) {
            const Color c = img.pixel(x, y);
            sum += double(c.r) + double(c.g) + double(c.b);
        }
    return sum;
}

float centre_red(Image img) { return img.pixel(img.width / 2, img.height / 2).r; }

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------

TEST_CASE("layer textures: the clear coat and the sheen roughness go into the occlusion map, deterministically") {
    LayerTextureRefs refs;
    PreparedTextureRef occlusion = image_ref(solid(2, 2, 100, 7, 7, 255), "occ");
    PreparedTextureRef metalRough;
    refs.clearcoat = image_ref(solid(4, 4, 200, 1, 1, 255), "coat");
    refs.clearcoatRoughness = image_ref(solid(2, 2, 1, 50, 1, 255), "coatRough");
    refs.sheenRoughness = image_ref(solid(1, 1, 1, 1, 1, 30), "sheenRough");
    std::vector<std::string> warnings;
    const int packed = fa::render::pack_layer_textures(refs, "assets/car.glb: material 'paint'", "<gltf-layers:t>",
                                                       occlusion, metalRough, warnings);
    CHECK(packed == 1);
    REQUIRE(occlusion.kind == Kind::Image);
    CHECK(occlusion.image->width == 4);  // the largest of the sources
    CHECK(occlusion.image->height == 4);
    const Color px = occlusion.image->pixel(1, 2);
    CHECK(std::lround(px.r * 255) == 100);  // R: the occlusion the map had
    CHECK(std::lround(px.g * 255) == 200);  // G: clearcoatTexture.R
    CHECK(std::lround(px.b * 255) == 50);   // B: clearcoatRoughnessTexture.G
    CHECK(std::lround(px.a * 255) == 30);   // A: sheenRoughnessTexture.A
    CHECK(metalRough.kind == Kind::None);   // untouched
    CHECK(warnings.empty());

    // The same inputs give the same bytes.
    PreparedTextureRef occ2 = image_ref(solid(2, 2, 100, 7, 7, 255), "occ");
    PreparedTextureRef mr2;
    fa::render::pack_layer_textures(refs, "x", "<gltf-layers:t>", occ2, mr2, warnings);
    CHECK(occ2.image->rgba == occlusion.image->rgba);
}

TEST_CASE("layer textures: the anisotropy strength and the specular go into the metallic-roughness map") {
    LayerTextureRefs refs;
    PreparedTextureRef occlusion;
    PreparedTextureRef metalRough = image_ref(solid(2, 2, 9, 120, 33, 77), "mr");
    refs.anisotropy = image_ref(solid(2, 2, 10, 20, 180, 255), "aniso");
    refs.specular = image_ref(solid(2, 2, 1, 1, 1, 64), "spec");
    std::vector<std::string> warnings;
    const int packed = fa::render::pack_layer_textures(refs, "assets/brushed.glb: material 'steel'", "<gltf-layers:m>",
                                                       occlusion, metalRough, warnings);
    CHECK(packed == 2);
    REQUIRE(metalRough.kind == Kind::Image);
    const Color px = metalRough.image->pixel(0, 0);
    CHECK(std::lround(px.r * 255) == 180);  // R: anisotropyTexture.B, the strength
    CHECK(std::lround(px.g * 255) == 120);  // G, B: roughness and metallic of the map
    CHECK(std::lround(px.b * 255) == 33);
    CHECK(std::lround(px.a * 255) == 64);  // A: specularTexture.A
    // The direction of the anisotropy texture has no channel: said, with what is used instead.
    CHECK(has(warnings, "assets/brushed.glb: material 'steel': the direction of anisotropyTexture is not used"));
    CHECK(has(warnings, "tangent turned by anisotropyRotation"));

    // No metallic-roughness map: roughness and metallic channels are 255 (the factors alone decide).
    PreparedTextureRef none;
    PreparedTextureRef mr2;
    LayerTextureRefs only;
    only.specular = image_ref(solid(1, 1, 0, 0, 0, 10), "spec");
    fa::render::pack_layer_textures(only, "x", "<gltf-layers:n>", none, mr2, warnings);
    REQUIRE(mr2.kind == Kind::Image);
    const Color q = mr2.image->pixel(0, 0);
    CHECK(std::lround(q.r * 255) == 255);
    CHECK(std::lround(q.g * 255) == 255);
    CHECK(std::lround(q.b * 255) == 255);
    CHECK(std::lround(q.a * 255) == 10);
}

TEST_CASE("layer textures: the resampling is bilinear in fixed point, the same bytes everywhere") {
    // A 2x1 source (red 0 then 255) spread over four pixels: the source coordinate of pixel x is x / 2 - 0.25.
    Image strip;
    strip.width = 2;
    strip.height = 1;
    strip.rgba = {0, 0, 0, 255, 255, 0, 0, 255};
    LayerTextureRefs refs;
    refs.clearcoat = image_ref(strip, "strip");
    refs.clearcoatRoughness = image_ref(solid(4, 1, 0, 0, 0, 255), "wide");
    PreparedTextureRef occlusion, metalRough;
    std::vector<std::string> warnings;
    fa::render::pack_layer_textures(refs, "x", "<gltf-layers:r>", occlusion, metalRough, warnings);
    REQUIRE(occlusion.kind == Kind::Image);
    REQUIRE(occlusion.image->width == 4);
    const int expected[4] = {0, 64, 191, 255};
    for (int x = 0; x < 4; ++x) CHECK(int(occlusion.image->rgba[std::size_t(x) * 4 + 1]) == expected[x]);
}

TEST_CASE(
    "layer textures: what is not packed or cannot be read is named with the file and the material, never dropped") {
    LayerTextureRefs refs;
    refs.clearcoatNormal = image_ref(solid(1, 1, 128, 128, 255, 255), "coat-normal");
    refs.sheenColor = image_ref(solid(1, 1, 255, 0, 0, 255), "sheen-colour");
    refs.specularColor = image_ref(solid(1, 1, 255, 0, 0, 255), "spec-colour");
    refs.clearcoat.kind = Kind::Missing;
    refs.clearcoat.name = "assets/missing.png";
    refs.clearcoat.error = "the file does not exist";
    PreparedTextureRef occlusion, metalRough;
    std::vector<std::string> warnings;
    const int packed = fa::render::pack_layer_textures(refs, "assets/a.glb: material 'm'", "<gltf-layers:w>", occlusion,
                                                       metalRough, warnings);
    CHECK(packed == 0);  // nothing readable to pack: the maps stay the model's own
    CHECK(occlusion.kind == Kind::None);
    CHECK(has(warnings, "assets/a.glb: material 'm': clearcoatNormalTexture 'coat-normal' is not used"));
    CHECK(has(warnings, "follows the geometric normal"));
    CHECK(has(warnings, "sheenColorTexture 'sheen-colour' is not used (sheenColorFactor is used"));
    CHECK(has(warnings, "specularColorTexture 'spec-colour' is not used (specularColorFactor is used"));
    CHECK(has(
        warnings,
        "clearcoatTexture 'assets/missing.png' cannot be used (the file does not exist); its factor alone is used"));
    CHECK(kMaxLayerPackPixels == 4096ull * 4096ull);
}

TEST_CASE("layer textures: a glTF model's extensions are read with its textures packed, and the leftovers reported") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    REQUIRE(save_png(solid(2, 2, 40, 0, 0, 255), "assets/layer_occ.png").ok());
    REQUIRE(save_png(solid(4, 4, 220, 0, 0, 255), "assets/layer_coat.png").ok());
    REQUIRE(save_png(solid(2, 2, 0, 0, 200, 255), "assets/layer_aniso.png").ok());
    Json mat = {
        {"name", "lacquer"},
        {"pbrMetallicRoughness", {{"metallicFactor", 0.0}, {"roughnessFactor", 0.4}}},
        {"occlusionTexture", {{"index", 0}}},
        {"extensions",
         {{"KHR_materials_clearcoat",
           {{"clearcoatFactor", 1.0},
            {"clearcoatRoughnessFactor", 0.1},
            {"clearcoatTexture", {{"index", 1}}},
            {"clearcoatNormalTexture", {{"index", 1}}}}},
          {"KHR_materials_anisotropy", {{"anisotropyStrength", 0.5}, {"anisotropyTexture", {{"index", 2}}}}},
          {"KHR_materials_sheen", {{"sheenColorFactor", Json::array({1, 0, 0})}, {"sheenRoughnessFactor", 0.3}}},
          {"KHR_materials_ior", {{"ior", 2.0}}}}}};
    const std::string text =
        triangle_gltf(Json::array({mat}),
                      Json::array({Json{{"uri", "layer_occ.png"}}, Json{{"uri", "layer_coat.png"}},
                                   Json{{"uri", "layer_aniso.png"}}}),
                      Json::array({Json{{"source", 0}}, Json{{"source", 1}}, Json{{"source", 2}}}));
    PreparedMesh mesh;
    std::string error;
    REQUIRE(decode("assets/layered.gltf", text, mesh, error));
    REQUIRE(mesh.parts.size() == 1);
    const auto& part = mesh.parts[0];
    const MaterialLayers& L = part.material.layers;
    CHECK(L.clearcoat == 1.0f);
    CHECK(L.clearcoatRoughness == doctest::Approx(0.1f));
    CHECK(L.sheenColor[0] == 1.0f);
    CHECK(L.sheenRoughness == doctest::Approx(0.3f));
    CHECK(L.anisotropy == doctest::Approx(0.5f));
    CHECK(L.ior == 2.0f);
    CHECK(part.material.layersPacked == 3);
    // The occlusion map is now the composite: R = the model's occlusion, G = the clear coat texture, 255 elsewhere.
    REQUIRE(part.occlusion.kind == Kind::Image);
    CHECK(part.occlusion.image->width == 4);
    const Color o = part.occlusion.image->pixel(3, 3);
    CHECK(std::lround(o.r * 255) == 40);
    CHECK(std::lround(o.g * 255) == 220);
    CHECK(std::lround(o.b * 255) == 255);
    // The metallic-roughness map did not exist: the anisotropy strength (blue) is in R, the rest 255.
    REQUIRE(part.metalRough.kind == Kind::Image);
    const Color m = part.metalRough.image->pixel(0, 0);
    CHECK(std::lround(m.r * 255) == 200);
    CHECK(std::lround(m.g * 255) == 255);
    // The report: file and material, what is not used and what is used instead.
    CHECK(has(mesh.warnings, "assets/layered.gltf: material 'lacquer': clearcoatNormalTexture"));
    CHECK(has(mesh.warnings, "the direction of anisotropyTexture is not used"));
}

TEST_CASE("layer textures: a texture file that is missing is reported and its factor is used; no extension, no layer") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Json mat = {{"name", "gone"},
                {"extensions",
                 {{"KHR_materials_clearcoat", {{"clearcoatFactor", 0.8}, {"clearcoatTexture", {{"index", 0}}}}}}}};
    const std::string text = triangle_gltf(Json::array({mat}), Json::array({Json{{"uri", "no_such_layer.png"}}}),
                                           Json::array({Json{{"source", 0}}}));
    PreparedMesh mesh;
    std::string error;
    REQUIRE(decode("assets/gone.gltf", text, mesh, error));
    CHECK(mesh.parts[0].material.layers.clearcoat == doctest::Approx(0.8f));
    CHECK(mesh.parts[0].material.layersPacked == 0);
    CHECK(mesh.parts[0].occlusion.kind == Kind::None);
    CHECK(has(mesh.warnings,
              "assets/gone.gltf: material 'gone': clearcoatTexture 'assets/no_such_layer.png' cannot be used"));
    CHECK(has(mesh.warnings, "its factor alone is used"));

    PreparedMesh plain;
    REQUIRE(decode("assets/plain.gltf",
                   triangle_gltf(Json::array({Json{{"name", "plain"}}}), Json::array(), Json::array()), plain, error));
    CHECK(plain.parts[0].material.layers == MaterialLayers{});
    CHECK(plain.parts[0].material.layersPacked == 0);
    CHECK(plain.warnings.empty());
}

// ---------------------------------------------------------------------------------------------------------------------

TEST_CASE("layers: ior 1.5 and specular 1 are the 4% the engine always had, to the last pixel") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    Ball plain(Color{0.6f, 0.2f, 0.2f, 1}, 0.0f, 0.5f);
    plain.world.settings().skyColor = Color{0.2f, 0.4f, 0.8f, 1};
    plain.world.settings().horizonColor = Color{0.8f, 0.7f, 0.6f, 1};
    const Image before = g.render(plain.world);
    plain.mesh().ior = 1.5f;
    plain.mesh().specular = 1.0f;
    const Image same = g.render(plain.world);
    CHECK(before.rgba == same.rgba);
    // A model that carries the engine's own values (the extensions with ior 1.5, specular 1) is not a layer either: no shader branch.
    CHECK_FALSE(MaterialLayers{}.any());
}

TEST_CASE(
    "layers: ior and specular set the reflectance at normal incidence, ((ior - 1) / (ior + 1))^2 times specular") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // A black dielectric under a light behind the camera shows only its specular: the middle pixel is proportional to F0.
    auto centre = [&](float ior, float specular) {
        Ball b;
        b.mesh().ior = ior;
        b.mesh().specular = specular;
        return centre_red(g.render(b.world));
    };
    const float base = centre(1.5f, 1.0f);  // F0 = 0.04
    REQUIRE(base > 0.05f);
    CHECK(centre(2.0f, 1.0f) / base == doctest::Approx((1.0 / 9.0) / 0.04).epsilon(0.06));  // F0 = 0.1111
    CHECK(centre(1.5f, 0.5f) / base == doctest::Approx(0.5).epsilon(0.06));
    CHECK(centre(1.0f, 1.0f) < base * 0.1f);  // ior 1: no reflection
    CHECK(centre(1.5f, 0.0f) < base * 0.1f);  // specular 0: none either
    // A metal's reflectance is its colour whatever the ior says.
    Ball metal(Color{0.9f, 0.9f, 0.9f, 1}, 1.0f, 0.5f);
    const float m1 = centre_red(g.render(metal.world));
    metal.mesh().ior = 2.4f;
    metal.mesh().specular = 0.3f;
    CHECK(centre_red(g.render(metal.world)) == doctest::Approx(m1).epsilon(0.02));
}

TEST_CASE("layers: a layer with nothing to add draws what the plain shading draws") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // An anisotropy of nearly 0 goes through the layers' code: it must land on the plain Cook-Torrance picture.
    Ball a(Color{0.5f, 0.3f, 0.2f, 1}, 0.0f, 0.5f, 2.0f);
    const Image plain = g.render(a.world);
    a.mesh().anisotropy = 1e-5f;
    const Image layered = g.render(a.world);
    CHECK(mean_abs_diff(plain, layered) < 0.002);
    // A sheen colour of black, a clear coat of 0: off.
    a.mesh().anisotropy = 0.0f;
    a.mesh().sheenColor = Color{0, 0, 0, 1};
    a.mesh().clearcoat = 0.0f;
    CHECK(g.render(a.world).rgba == plain.rgba);
}

TEST_CASE("layers: the clear coat adds a sharp highlight and the sheen a glow at grazing angles") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // Clear coat over a dark rough base: a mirror-like lobe appears.
    Ball coat(Color{0.3f, 0.02f, 0.02f, 1}, 0.0f, 0.8f, 2.0f);
    const Image bare = g.render(coat.world);
    coat.mesh().clearcoat = 1.0f;
    coat.mesh().clearcoatRoughness = 0.05f;
    const Image coated = g.render(coat.world);
    CHECK(centre_red(coated) > centre_red(bare) + 0.05f);
    CHECK(mean_abs_diff(bare, coated) > 0.0002);
    // The base is dimmed under the coat away from the highlight: a pixel near the rim is not brighter.
    const int rx = coated.width / 2 + coated.height / 4;
    CHECK(coated.pixel(rx, coated.height / 2).r <= bare.pixel(rx, bare.height / 2).r + 0.01f);

    // Sheen over a dark base: the rim gets lighter.
    Ball cloth(Color{0.05f, 0.05f, 0.05f, 1}, 0.0f, 0.9f, 2.0f);
    const Image dull = g.render(cloth.world);
    cloth.mesh().sheenColor = Color{1, 1, 1, 1};
    cloth.mesh().sheenRoughness = 0.5f;
    const Image sheen = g.render(cloth.world);
    CHECK(brightness(sheen) > brightness(dull) * 1.05);

    // Anisotropy stretches the highlight of a brushed metal: the picture changes, in both directions of the stretch.
    Ball metal(Color{0.8f, 0.8f, 0.8f, 1}, 1.0f, 0.4f, 2.0f);
    metal.light().intensity = 2.0f;
    metal.world.get<Transform>(metal.sun)->rotation = {-30, -30, 0};
    const Image round = g.render(metal.world);
    metal.mesh().anisotropy = 0.9f;
    const Image along = g.render(metal.world);
    metal.mesh().anisotropy = -0.9f;
    const Image across = g.render(metal.world);
    CHECK(mean_abs_diff(round, along) > 0.002);
    CHECK(mean_abs_diff(along, across) > 0.002);
    metal.mesh().anisotropy = 0.9f;
    metal.mesh().anisotropyRotation = 90.0f;  // a turn of 90 degrees swaps the two
    CHECK(mean_abs_diff(g.render(metal.world), across) < 0.01);
}

TEST_CASE("layers: a row of spheres per layer (golden)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity cam = make(w, "cam", {0, 0, 7.2f});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 30;
    w.settings().ambientLight = Color{0.08f, 0.08f, 0.1f, 1};
    w.settings().skyColor = Color{0.25f, 0.4f, 0.7f, 1};
    w.settings().horizonColor = Color{0.75f, 0.7f, 0.6f, 1};
    Entity sun = make(w, "sun", {0, 3, 3});
    w.get<Transform>(sun)->rotation = {-25, -55, 0};
    auto& l = w.add<Light>(sun);
    l.type = LightType::Directional;
    l.intensity = 2.2f;
    l.castShadows = false;
    auto ball = [&](int col, int row, auto&& set) {
        Entity e = make(w, "ball", {(float(col) - 2.0f) * 1.3f, (1.5f - float(row)) * 0.92f, 0});
        w.get<Transform>(e)->scale = {0.85f, 0.85f, 0.85f};
        auto& m = w.add<MeshRenderer>(e);
        m.mesh = "sphere";
        m.castShadows = false;
        set(m);
    };
    // Row 0: clear coat 0 .. 1 over a red base (roughness 0.7), the last one smoother.
    const float coat[5] = {0.0f, 0.25f, 0.5f, 1.0f, 1.0f};
    for (int i = 0; i < 5; ++i)
        ball(i, 0, [&](MeshRenderer& m) {
            m.color = Color{0.7f, 0.05f, 0.05f, 1};
            m.roughness = 0.7f;
            m.clearcoat = coat[i];
            m.clearcoatRoughness = i == 4 ? 0.3f : 0.03f;
        });
    // Row 1: sheen on a dark cloth: none, three roughnesses, a coloured one.
    for (int i = 0; i < 5; ++i)
        ball(i, 1, [&](MeshRenderer& m) {
            m.color = Color{0.02f, 0.02f, 0.05f, 1};
            m.roughness = 0.9f;
            m.sheenColor = i == 0 ? Color{0, 0, 0, 1} : (i == 4 ? Color{1.0f, 0.5f, 0.2f, 1} : Color{1, 1, 1, 1});
            m.sheenRoughness = i == 1 ? 0.2f : (i == 3 ? 0.9f : 0.5f);
        });
    // Row 2: anisotropy on a brushed metal: -1, -0.5, 0, 0.5, 1; the last one turned 45 degrees.
    for (int i = 0; i < 5; ++i)
        ball(i, 2, [&](MeshRenderer& m) {
            m.color = Color{0.85f, 0.8f, 0.7f, 1};
            m.metallic = 1.0f;
            m.roughness = 0.35f;
            m.anisotropy = (float(i) - 2.0f) * 0.5f;
            m.anisotropyRotation = i == 4 ? 45.0f : 0.0f;
        });
    // Row 3: the dielectric specular: ior 1, 1.33, 1.5 (the default), 2.4 and specular 0.
    const float iors[5] = {1.0f, 1.33f, 1.5f, 2.4f, 1.5f};
    for (int i = 0; i < 5; ++i)
        ball(i, 3, [&](MeshRenderer& m) {
            m.color = Color{0.1f, 0.35f, 0.15f, 1};
            m.roughness = 0.25f;
            m.ior = iors[i];
            m.specular = i == 4 ? 0.0f : 1.0f;
        });
    const Image img = g.render(w);
    CHECK(expect_golden(img, "3d_material_layers", 0.008).ok());
}
