// The material layers of a glTF (M73.6): KHR_materials_clearcoat, _sheen, _anisotropy, _specular and _ior are read into
// MaterialLayers by the editable-mesh importer (read_gltf_mesh_bytes), saved again by mesh_to_glb, and what an editable mesh
// cannot carry (the layers' textures) is reported with the file and the material. The renderer's model loader reads the same
// extensions with the same function (engine/render/tests/material_layers_tests.cpp).
#include <doctest.h>

#include <algorithm>
#include <cstring>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/scene/gltf_mesh.h"
#include "fa/scene/material_layers.h"
#include "fa/scene/mesh_store.h"

using namespace fa;

namespace {

void put32(std::vector<std::uint8_t>& out, std::uint32_t v) {
    for (int i = 0; i < 4; ++i) out.push_back(std::uint8_t(v >> (8 * i)));
}

// A .glb of one triangle (three positions) with the given `material` JSON as its only material.
std::vector<std::uint8_t> triangle_glb(const Json& material, bool withImage) {
    Json doc;
    doc["asset"] = {{"version", "2.0"}};
    doc["buffers"] = Json::array({Json{{"byteLength", 36}}});
    doc["bufferViews"] = Json::array({Json{{"buffer", 0}, {"byteOffset", 0}, {"byteLength", 36}}});
    doc["accessors"] = Json::array({Json{{"bufferView", 0},
                                         {"componentType", 5126},
                                         {"count", 3},
                                         {"type", "VEC3"},
                                         {"min", Json::array({0, 0, 0})},
                                         {"max", Json::array({1, 1, 0})}}});
    doc["meshes"] = Json::array(
        {Json{{"primitives", Json::array({Json{{"attributes", {{"POSITION", 0}}}, {"material", 0}}})}}});
    doc["nodes"] = Json::array({Json{{"mesh", 0}}});
    doc["scenes"] = Json::array({Json{{"nodes", Json::array({0})}}});
    doc["materials"] = Json::array({material});
    if (withImage) {
        doc["images"] = Json::array({Json{{"uri", "layer.png"}}});
        doc["textures"] = Json::array({Json{{"source", 0}}});
    }
    std::string json = doc.dump();
    while (json.size() % 4) json.push_back(' ');
    std::vector<std::uint8_t> bin(36, 0);
    const float tri[9] = {0, 0, 0, 1, 0, 0, 0, 1, 0};
    std::memcpy(bin.data(), tri, 36);
    std::vector<std::uint8_t> out = {'g', 'l', 'T', 'F'};
    put32(out, 2);
    put32(out, std::uint32_t(12 + 8 + json.size() + 8 + bin.size()));
    put32(out, std::uint32_t(json.size()));
    put32(out, 0x4E4F534Au);
    out.insert(out.end(), json.begin(), json.end());
    put32(out, std::uint32_t(bin.size()));
    put32(out, 0x004E4942u);
    out.insert(out.end(), bin.begin(), bin.end());
    return out;
}

bool any_warning_has(const std::vector<std::string>& w, const std::string& text) {
    return std::any_of(w.begin(), w.end(), [&](const std::string& s) { return s.find(text) != std::string::npos; });
}

}  // namespace

TEST_CASE("material layers: each KHR extension is read, clamped with a report, and written back by mesh.save") {
    Json mat = {{"name", "paint"},
                {"extensions",
                 {{"KHR_materials_clearcoat",
                   {{"clearcoatFactor", 0.5},
                    {"clearcoatRoughnessFactor", 0.2},
                    {"clearcoatTexture", {{"index", 0}}},
                    {"clearcoatNormalTexture", {{"index", 0}}}}},
                  {"KHR_materials_sheen",
                   {{"sheenColorFactor", Json::array({0.25, 0.5, 0.75})}, {"sheenRoughnessFactor", 0.625}}},
                  {"KHR_materials_anisotropy", {{"anisotropyStrength", 0.75}, {"anisotropyRotation", 0.5}}},
                  {"KHR_materials_specular",
                   {{"specularFactor", 0.5}, {"specularColorFactor", Json::array({1.0, 0.5, 0.25})}}},
                  {"KHR_materials_ior", {{"ior", 7.0}}}}}};
    auto glb = triangle_glb(mat, true);
    auto mesh = read_gltf_mesh_bytes(glb, "assets/car.glb");
    REQUIRE(mesh.ok());
    REQUIRE(mesh->materials.size() == 1);
    const MaterialLayers& L = mesh->materials[0].layers;
    CHECK(L.clearcoat == doctest::Approx(0.5f));
    CHECK(L.clearcoatRoughness == doctest::Approx(0.2f));
    CHECK(L.sheenColor[0] == doctest::Approx(0.25f));
    CHECK(L.sheenColor[1] == doctest::Approx(0.5f));
    CHECK(L.sheenColor[2] == doctest::Approx(0.75f));
    CHECK(L.sheenRoughness == doctest::Approx(0.625f));
    CHECK(L.anisotropy == doctest::Approx(0.75f));
    CHECK(L.anisotropyRotation == doctest::Approx(0.5f));
    CHECK(L.specular == doctest::Approx(0.5f));
    CHECK(L.specularColor[1] == doctest::Approx(0.5f));
    CHECK(L.specularColor[2] == doctest::Approx(0.25f));
    CHECK(L.ior == doctest::Approx(3.0f));  // 7 is clamped to the engine's 1..3
    CHECK(L.any());
    // Reported, with the file and the material: the clamp, and the textures an editable mesh cannot carry.
    CHECK(any_warning_has(mesh->warnings, "assets/car.glb: material 'paint': ior 7 is outside 1..3, clamped to 3"));
    CHECK(any_warning_has(mesh->warnings, "material 'paint': clearcoatTexture is not carried"));
    CHECK(any_warning_has(mesh->warnings, "material 'paint': clearcoatNormalTexture is not carried"));

    // mesh.save writes only the extensions the material uses, and reading the result gives the same layers.
    auto saved = mesh_to_glb(mesh->data, "assets/models/out.glb");
    REQUIRE(saved.ok());
    auto again = read_gltf_mesh_bytes(*saved, "assets/models/out.glb");
    REQUIRE(again.ok());
    REQUIRE(again->materials.size() == 1);
    CHECK(again->materials[0].layers == L);
}

TEST_CASE("material layers: a material without the extensions, or with the engine's own ior and specular, has no layer") {
    auto none = read_gltf_mesh_bytes(triangle_glb({{"name", "plain"}}, false), "plain.glb");
    REQUIRE(none.ok());
    CHECK(none->materials[0].layers == MaterialLayers{});
    CHECK_FALSE(none->materials[0].layers.any());
    CHECK(none->warnings.empty());

    // ior 1.5 and specular 1 are the 4% reflectance the engine always had: not a layer.
    Json own = {{"name", "own"},
                {"extensions", {{"KHR_materials_ior", {{"ior", 1.5}}}, {"KHR_materials_specular", {{"specularFactor", 1.0}}}}}};
    auto same = read_gltf_mesh_bytes(triangle_glb(own, false), "own.glb");
    REQUIRE(same.ok());
    CHECK_FALSE(same->materials[0].layers.any());
    CHECK(same->warnings.empty());
}

TEST_CASE("material layers: values outside their range are clamped and reported, never passed on") {
    Json mat = {{"name", "bad"},
                {"extensions",
                 {{"KHR_materials_clearcoat", {{"clearcoatFactor", 4.0}, {"clearcoatRoughnessFactor", -1.0}}},
                  {"KHR_materials_anisotropy", {{"anisotropyStrength", 9.0}}},
                  {"KHR_materials_specular", {{"specularFactor", 2.0}, {"specularColorFactor", Json::array({100, 1, 1})}}},
                  {"KHR_materials_ior", {{"ior", 0.5}}}}}};
    auto mesh = read_gltf_mesh_bytes(triangle_glb(mat, false), "bad.glb");
    REQUIRE(mesh.ok());
    const MaterialLayers& L = mesh->materials[0].layers;
    CHECK(L.clearcoat == 1.0f);
    CHECK(L.clearcoatRoughness == 0.0f);
    CHECK(L.anisotropy == 1.0f);
    CHECK(L.specular == 1.0f);
    CHECK(L.specularColor[0] == 16.0f);
    CHECK(L.ior == 1.0f);
    CHECK(any_warning_has(mesh->warnings, "clearcoatFactor 4 is outside 0..1, clamped to 1"));
    CHECK(any_warning_has(mesh->warnings, "ior 0.5 is outside 1..3, clamped to 1"));
}
