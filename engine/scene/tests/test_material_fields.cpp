// Custom materials on the renderers that are not meshes: Sprite, Shape2D, Tilemap, Text, ParticleEmitter, the UI widgets
// (UiBox) and SceneSettings.skyMaterial. The fields save and load, default to empty and merge in prefab overrides.
#include <doctest.h>

#include <chrono>
#include <filesystem>

#include "fa/core/fs.h"
#include "fa/core/reflect.h"
#include "fa/scene/serialize.h"

using namespace fa;

TEST_CASE("material fields: empty by default, documented on every non-mesh renderer") {
    CHECK(Sprite{}.material.empty());
    CHECK(Shape2D{}.material.empty());
    CHECK(Tilemap{}.material.empty());
    CHECK(Text{}.material.empty());
    CHECK(ParticleEmitter{}.material.empty());
    CHECK(Panel{}.material.empty());
    CHECK(Button{}.material.empty());
    CHECK(SceneSettings{}.skyMaterial.empty());
    CHECK(Sprite{}.materialParams.is_object());
    CHECK(Sprite{}.materialParams.empty());
    CHECK(SceneSettings{}.skyMaterialParams.empty());
    for (const char* type : {"Sprite", "Shape2D", "Tilemap", "Text", "ParticleEmitter", "Panel", "Button", "Video"}) {
        const TypeInfo* t = TypeRegistry::global().find(type);
        REQUIRE(t != nullptr);
        bool material = false, params = false;
        for (const FieldInfo& f : t->fields) {
            if (f.name == "material") {
                material = true;
                CHECK(f.kind == FieldKind::Asset);
                CHECK(f.assetType == "material");
                CHECK_FALSE(f.doc.empty());
            }
            if (f.name == "materialParams") {
                params = true;
                CHECK_FALSE(f.doc.empty());
            }
        }
        CHECK_MESSAGE(material, type);
        CHECK_MESSAGE(params, type);
    }
    const TypeInfo* settings = TypeRegistry::global().find("SceneSettings");
    REQUIRE(settings != nullptr);
    int found = 0;
    for (const FieldInfo& f : settings->fields) {
        if (f.name == "skyMaterial") {
            ++found;
            CHECK(f.assetType == "material");
        }
        if (f.name == "skyMaterialParams") ++found;
    }
    CHECK(found == 2);
}

TEST_CASE("material fields: a scene saves and loads them, and an old scene without them loads empty") {
    World w;
    const Json scene = Json::parse(R"({"format":"factoria.scene/1",
      "settings":{"skyMaterial":"materials/sky.material.json","skyMaterialParams":{"sun":[1,0.8,0.5,1]}},
      "entities":[
        {"id":"s","components":{"Sprite":{"material":"materials/a.material.json","materialParams":{"glow":0.5}}}},
        {"id":"h","components":{"Shape2D":{"material":"materials/b.material.json","materialParams":{"k":[1,0,0,1]}}}},
        {"id":"m","components":{"Tilemap":{"material":"materials/c.material.json","materialParams":{"t":2}}}},
        {"id":"t","components":{"Text":{"material":"materials/d.material.json","materialParams":{"w":1}}}},
        {"id":"p","components":{"ParticleEmitter":{"material":"materials/e.material.json","materialParams":{"f":3}}}},
        {"id":"u","components":{"Panel":{"material":"materials/f.material.json","materialParams":{"g":4}}}},
        {"id":"old","components":{"Sprite":{"texture":"assets/x.png"},"Panel":{}}}]})");
    const LoadReport report = load_scene(w, scene, "main.scene.json");
    INFO(report.summary());
    REQUIRE(report.ok());
    CHECK(w.settings().skyMaterial == "materials/sky.material.json");
    CHECK(w.settings().skyMaterialParams["sun"].size() == 4);
    CHECK(w.get<Sprite>(w.find("s"))->material == "materials/a.material.json");
    CHECK(w.get<Sprite>(w.find("s"))->materialParams["glow"] == 0.5);
    CHECK(w.get<Shape2D>(w.find("h"))->material == "materials/b.material.json");
    CHECK(w.get<Tilemap>(w.find("m"))->material == "materials/c.material.json");
    CHECK(w.get<Text>(w.find("t"))->materialParams["w"] == 1);
    CHECK(w.get<ParticleEmitter>(w.find("p"))->material == "materials/e.material.json");
    CHECK(w.get<Panel>(w.find("u"))->material == "materials/f.material.json");
    CHECK(w.get<Panel>(w.find("u"))->materialParams["g"] == 4);
    CHECK(w.get<Sprite>(w.find("old"))->material.empty());
    CHECK(w.get<Panel>(w.find("old"))->material.empty());

    const Json saved = save_scene(w);
    World again;
    REQUIRE(load_scene(again, saved, "main.scene.json").ok());
    CHECK(again.settings().skyMaterial == "materials/sky.material.json");
    CHECK(again.settings().skyMaterialParams == w.settings().skyMaterialParams);
    CHECK(again.get<Sprite>(again.find("s"))->materialParams == w.get<Sprite>(w.find("s"))->materialParams);
    CHECK(again.get<ParticleEmitter>(again.find("p"))->material == "materials/e.material.json");
    CHECK(again.get<Panel>(again.find("u"))->materialParams["g"] == 4);
    // Defaults are not written: the old entity's Sprite has no material keys.
    for (const Json& e : saved["entities"])
        if (e["id"] == "old") CHECK_FALSE(e["components"]["Sprite"].contains("material"));
}

TEST_CASE("material fields: a prefab instance overrides material and merges its params") {
    const std::filesystem::path oldRoot = fs::project_root();
    const std::filesystem::path dir =
        std::filesystem::temp_directory_path() /
        ("fa_test_material_fields_" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    std::filesystem::create_directories(dir);
    fs::set_project_root(dir);
    REQUIRE(fs::write_text("prefabs/fx.prefab.json", R"({"format":"factoria.prefab/1","entity":{"id":"fx","components":{
        "Sprite":{"material":"materials/a.material.json","materialParams":{"glow":0.5,"speed":2}}}}})")
                .ok());
    World w;
    LoadReport report;
    Entity e = instantiate_prefab(
        w, "prefabs/fx.prefab.json", kNullEntity, report,
        Json::parse(R"({"components":{"Sprite":{"material":"materials/b.material.json","materialParams":{"glow":1}}}})"));
    REQUIRE(!e.is_null());
    CHECK(w.get<Sprite>(e)->material == "materials/b.material.json");
    CHECK(w.get<Sprite>(e)->materialParams["glow"] == 1);
    CHECK(w.get<Sprite>(e)->materialParams["speed"] == 2);  // the prefab's other param survives the deep merge
    fs::set_project_root(oldRoot);
    std::error_code ec;
    std::filesystem::remove_all(dir, ec);
}
