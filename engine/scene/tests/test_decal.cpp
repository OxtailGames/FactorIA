// M73.5b: the Decal component and the two MeshRenderer fields that decide which meshes receive it. They are reflected, validated,
// saved and loaded; the renderer draws them (engine/render/tests/decal_*).
#include <doctest.h>

#include <string>

#include "fa/core/reflect.h"
#include "fa/scene/serialize.h"

using namespace fa;

namespace {
const FieldInfo* decal_field(const char* type, const std::string& name) {
    const TypeInfo* t = TypeRegistry::global().find(type);
    if (!t) return nullptr;
    for (const FieldInfo& f : t->fields)
        if (f.name == name) return &f;
    return nullptr;
}
}  // namespace

TEST_CASE("decal: the component is reflected and every field says what it does") {
    const TypeInfo* t = TypeRegistry::global().find("Decal");
    REQUIRE(t != nullptr);
    CHECK(t->doc.size() > 100);
    for (const char* n :
         {"albedo", "normal", "color", "opacity", "normalStrength", "angleFade", "sortOrder", "layers"}) {
        CAPTURE(n);
        const FieldInfo* f = decal_field("Decal", n);
        REQUIRE(f != nullptr);
        CHECK(f->doc.size() > 40);
        CHECK(f->doc.find("No effect yet") == std::string::npos);
        CHECK(f->serialized);
    }
    const FieldInfo* albedo = decal_field("Decal", "albedo");
    REQUIRE(albedo != nullptr);
    CHECK(albedo->assetType == "texture");
    const FieldInfo* normal = decal_field("Decal", "normal");
    REQUIRE(normal != nullptr);
    CHECK(normal->assetType == "texture");
    for (const char* n : {"receiveDecals", "decalLayer"}) {
        CAPTURE(n);
        const FieldInfo* f = decal_field("MeshRenderer", n);
        REQUIRE(f != nullptr);
        CHECK(f->doc.size() > 40);
        CHECK(f->doc.find("No effect yet") == std::string::npos);
    }
}

TEST_CASE("decal: the defaults paint the whole box at full strength on every layer") {
    const Decal d;
    CHECK(d.albedo.empty());
    CHECK(d.normal.empty());
    CHECK(d.color.r == 1.0f);
    CHECK(d.color.a == 1.0f);
    CHECK(d.opacity == 1.0f);
    CHECK(d.normalStrength == 1.0f);
    CHECK(d.angleFade == 60.0f);
    CHECK(d.sortOrder == 0);
    CHECK(d.layers == 0);
    const MeshRenderer m;
    CHECK(m.receiveDecals);
    CHECK(m.decalLayer == 0);
}

TEST_CASE("decal: a scene with decals saves, loads again and keeps the values; defaults are not written") {
    World w;
    const Json scene = Json::parse(R"({"format":"factoria.scene/1",
      "entities":[{"id":"hole","components":{"Decal":{"albedo":"hole.png","normal":"hole_n.png","color":[1,0.5,0.5,1],
                     "opacity":0.5,"normalStrength":2,"angleFade":45,"sortOrder":3,"layers":5}}},
                  {"id":"flat","components":{"Decal":{}}},
                  {"id":"wall","components":{"MeshRenderer":{"mesh":"cube","receiveDecals":false,"decalLayer":2}}},
                  {"id":"floor","components":{"MeshRenderer":{"mesh":"cube"}}}]})");
    const LoadReport report = load_scene(w, scene, "decal.scene.json");
    INFO(report.summary());
    REQUIRE(report.ok());
    const Json saved = save_scene(w);
    World again;
    REQUIRE(load_scene(again, saved, "again.scene.json").ok());
    CHECK(save_scene(again) == saved);
    const Decal* d = again.get<Decal>(again.find("hole"));
    REQUIRE(d != nullptr);
    CHECK(d->albedo == "hole.png");
    CHECK(d->normal == "hole_n.png");
    CHECK(d->opacity == 0.5f);
    CHECK(d->normalStrength == 2.0f);
    CHECK(d->angleFade == 45.0f);
    CHECK(d->sortOrder == 3);
    CHECK(d->layers == 5);
    const MeshRenderer* wall = again.get<MeshRenderer>(again.find("wall"));
    REQUIRE(wall != nullptr);
    CHECK_FALSE(wall->receiveDecals);
    CHECK(wall->decalLayer == 2);
    for (const Json& e : saved["entities"]) {
        if (!e["components"].contains("MeshRenderer")) continue;
        if (e["id"] == "floor") {
            CHECK_FALSE(e["components"]["MeshRenderer"].contains("receiveDecals"));
            CHECK_FALSE(e["components"]["MeshRenderer"].contains("decalLayer"));
        }
    }
}

TEST_CASE("decal: values out of range are reported when the scene loads") {
    World w;
    const Json scene = Json::parse(R"({"format":"factoria.scene/1",
      "entities":[{"id":"bad","components":{"Decal":{"opacity":3,"angleFade":200,"layers":-1}}}]})");
    const LoadReport report = load_scene(w, scene, "bad.scene.json");
    CHECK_FALSE(report.ok());
}
