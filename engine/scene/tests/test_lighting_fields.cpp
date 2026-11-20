// M73-P0: the fields the lighting of M73 reads (Light, SceneSettings, MeshRenderer). They are reflected, validated, saved and loaded
// today; the packages M73.1 .. M73.6 draw them. Their defaults keep the look of every older scene, so an old scene loads and saves
// byte for byte as before.
#include <doctest.h>

#include <algorithm>
#include <string>
#include <vector>

#include "fa/core/reflect.h"
#include "fa/scene/serialize.h"

using namespace fa;

namespace {
const FieldInfo* field_of(const char* type, const std::string& name) {
    const TypeInfo* t = TypeRegistry::global().find(type);
    if (!t) return nullptr;
    for (const FieldInfo& f : t->fields)
        if (f.name == name) return &f;
    return nullptr;
}
const std::vector<std::string> kLightFields = {
    "innerAngle",       "shape",        "size",           "cookie",         "ies",  "shadowResolution", "shadowBias",
    "shadowNormalBias", "shadowFilter", "shadowSoftness", "shadowDistance", "mode", "volumetric"};
const std::vector<std::string> kSettingsFields = {
    "shadowCascades", "shadowCascadeSplit", "shadowCascadeBlend",   "shadowDistance",      "shadowAtlasSize",
    "contactShadows", "environmentMap",     "environmentIntensity", "environmentRotation", "skyModel"};
const std::vector<std::string> kMeshFields = {
    "lightmapScale", "contributeGI",   "receiveGI",  "clearcoat",          "clearcoatRoughness",
    "sheenColor",    "sheenRoughness", "anisotropy", "anisotropyRotation", "specular",
    "ior",           "transmission",   "thickness",  "attenuationColor",   "attenuationDistance",
    "subsurface"};
// The fields a package has made work: their doc string no longer says "No effect yet" (M73.1a: innerAngle; M73.2a: the cascaded shadows of the sun).
const std::vector<std::string> kDrawn = {"innerAngle",         "shadowResolution", "shadowBias",
                                         "shadowNormalBias",   "shadowFilter",     "shadowSoftness",
                                         "shadowDistance",     "shadowCascades",   "shadowCascadeSplit",
                                         "shadowCascadeBlend", "shadowAtlasSize"};
}  // namespace

TEST_CASE("lighting fields: every new field is reflected and its doc says what it does and which package brings it") {
    for (const auto& [type, names] : {std::pair<const char*, const std::vector<std::string>*>{"Light", &kLightFields},
                                      {"SceneSettings", &kSettingsFields},
                                      {"MeshRenderer", &kMeshFields}}) {
        for (const std::string& n : *names) {
            CAPTURE(type);
            CAPTURE(n);
            const FieldInfo* f = field_of(type, n);
            REQUIRE(f != nullptr);
            CHECK(f->doc.size() > 40);
            const bool drawn = std::find(kDrawn.begin(), kDrawn.end(), n) != kDrawn.end();
            CHECK((f->doc.find("No effect yet: M73.") == std::string::npos) == drawn);
            CHECK(f->serialized);
        }
    }
    const FieldInfo* cast = field_of("Light", "castShadows");
    REQUIRE(cast != nullptr);
    CHECK(cast->doc.find("M73.2") != std::string::npos);
    const FieldInfo* type = field_of("Light", "type");
    REQUIRE(type != nullptr);
    CHECK(type->enumNames.size() == 4);
    CHECK(type->enumNames[3] == "area");
}

TEST_CASE("lighting fields: the defaults keep the look of a scene made before M73") {
    const Light l;
    CHECK(l.type == LightType::Directional);
    CHECK(l.innerAngle == 0.0f);
    CHECK(l.shadowResolution == 0);
    CHECK(l.shadowBias == 0.0f);
    CHECK(l.shadowFilter == ShadowFilter::Pcf);
    CHECK(l.mode == LightMode::Realtime);
    CHECK(l.volumetric == 0.0f);
    CHECK(l.cookie.empty());
    CHECK(l.ies.empty());
    const SceneSettings s;
    CHECK(s.shadowCascades == 1);
    CHECK(s.shadowDistance == 0.0f);
    CHECK_FALSE(s.contactShadows);
    CHECK(s.environmentMap.empty());
    CHECK(s.environmentIntensity == 1.0f);
    CHECK(s.skyModel == SkyModel::Gradient);
    const MeshRenderer m;
    CHECK(m.contributeGI);
    CHECK(m.receiveGI);
    CHECK(m.clearcoat == 0.0f);
    CHECK(m.transmission == 0.0f);
    CHECK(m.subsurface == 0.0f);
    CHECK(m.specular == 1.0f);
    CHECK(m.ior == 1.5f);
    CHECK(m.sheenColor.r == 0.0f);
}

TEST_CASE("lighting fields: an old scene loads unchanged and saves without any of the new keys") {
    World w;
    const Json scene = Json::parse(R"({"format":"factoria.scene/1","settings":{"fogDensity":0.5},
      "entities":[{"id":"sun","components":{"Light":{"type":"spot","spotAngle":40,"castShadows":true}}},
                  {"id":"box","components":{"MeshRenderer":{"mesh":"cube","metallic":0.5}}}]})");
    const LoadReport report = load_scene(w, scene, "old.scene.json");
    INFO(report.summary());
    REQUIRE(report.ok());
    CHECK(w.get<Light>(w.find("sun"))->type == LightType::Spot);
    CHECK(w.get<Light>(w.find("sun"))->innerAngle == 0.0f);
    CHECK(w.get<MeshRenderer>(w.find("box"))->receiveGI);
    const Json saved = save_scene(w);
    for (const Json& e : saved["entities"]) {
        for (const char* comp : {"Light", "MeshRenderer"}) {
            if (!e["components"].contains(comp)) continue;
            for (const auto& names : {&kLightFields, &kMeshFields})
                for (const std::string& n : *names) CHECK_FALSE(e["components"][comp].contains(n));
        }
    }
    for (const std::string& n : kSettingsFields) CHECK_FALSE(saved["settings"].contains(n));
}

TEST_CASE("lighting fields: a scene with every new field saves, loads again and keeps the values") {
    World w;
    const Json scene = Json::parse(R"({"format":"factoria.scene/1",
      "settings":{"shadowCascades":3,"shadowCascadeSplit":0.7,"shadowCascadeBlend":0.2,"shadowDistance":150,
                  "shadowAtlasSize":2048,"contactShadows":true,"environmentIntensity":2,
                  "environmentRotation":90,"skyModel":"physical"},
      "entities":[{"id":"lamp","components":{"Light":{"type":"area","shape":"disc","size":[2,3],"innerAngle":10,
                     "shadowResolution":1024,"shadowBias":0.01,"shadowNormalBias":0.02,"shadowFilter":"pcss",
                     "shadowSoftness":2.5,"shadowDistance":40,"mode":"mixed","volumetric":1.5}}},
                  {"id":"glass","components":{"MeshRenderer":{"mesh":"sphere","lightmapScale":2,"contributeGI":false,
                     "receiveGI":false,"clearcoat":0.8,"clearcoatRoughness":0.1,"sheenColor":[1,0,0,1],
                     "sheenRoughness":0.3,"anisotropy":-0.5,"anisotropyRotation":45,"specular":0.5,"ior":1.33,
                     "transmission":0.9,"thickness":0.2,"attenuationColor":[0,1,0,1],"attenuationDistance":3,
                     "subsurface":0.4}}}]})");
    const LoadReport report = load_scene(w, scene, "new.scene.json");
    INFO(report.summary());
    REQUIRE(report.ok());
    const Json saved = save_scene(w);
    World again;
    REQUIRE(load_scene(again, saved, "again.scene.json").ok());
    CHECK(save_scene(again) == saved);
    const Light* l = again.get<Light>(again.find("lamp"));
    REQUIRE(l != nullptr);
    CHECK(l->type == LightType::Area);
    CHECK(l->shape == LightShape::Disc);
    CHECK(l->size.x == 2.0f);
    CHECK(l->size.y == 3.0f);
    CHECK(l->shadowFilter == ShadowFilter::Pcss);
    CHECK(l->mode == LightMode::Mixed);
    CHECK(l->shadowResolution == 1024);
    CHECK(l->volumetric == 1.5f);
    const MeshRenderer* m = again.get<MeshRenderer>(again.find("glass"));
    REQUIRE(m != nullptr);
    CHECK_FALSE(m->contributeGI);
    CHECK(m->transmission == 0.9f);
    CHECK(m->anisotropy == -0.5f);
    CHECK(m->sheenColor.r == 1.0f);
    CHECK(m->attenuationColor.g == 1.0f);
    CHECK(again.settings().shadowCascades == 3);
    CHECK(again.settings().skyModel == SkyModel::Physical);
    CHECK(again.settings().contactShadows);
}

TEST_CASE("lighting fields: a wrong value is refused with the field, the range and a way out") {
    Light l;
    const FieldInfo* shape = field_of("Light", "shape");
    REQUIRE(shape != nullptr);
    const Result<void> typo = field_from_json(*shape, &l, Json("rectagle"));
    REQUIRE_FALSE(typo.ok());
    const std::string typoText = typo.error().message + " " + typo.error().hint;
    CHECK(typoText.find("rectangle") != std::string::npos);  // did you mean
    CHECK(l.shape == LightShape::Rectangle);

    const FieldInfo* type = field_of("Light", "type");
    REQUIRE(type != nullptr);
    const Result<void> area = field_from_json(*type, &l, Json("aera"));
    REQUIRE_FALSE(area.ok());
    CHECK((area.error().message + " " + area.error().hint).find("area") != std::string::npos);

    const FieldInfo* cascades = field_of("SceneSettings", "shadowCascades");
    REQUIRE(cascades != nullptr);
    SceneSettings s;
    const Result<void> many = field_from_json(*cascades, &s, Json(9));
    REQUIRE_FALSE(many.ok());
    CHECK(many.error().message.find("shadowCascades") != std::string::npos);
    CHECK(many.error().message.find("4") != std::string::npos);
    CHECK(s.shadowCascades == 1);
    CHECK(field_from_json(*cascades, &s, Json(4)).ok());

    const FieldInfo* sky = field_of("SceneSettings", "skyModel");
    REQUIRE(sky != nullptr);
    const Result<void> phys = field_from_json(*sky, &s, Json("physcal"));
    REQUIRE_FALSE(phys.ok());
    CHECK((phys.error().message + " " + phys.error().hint).find("physical") != std::string::npos);

    const FieldInfo* ior = field_of("MeshRenderer", "ior");
    REQUIRE(ior != nullptr);
    MeshRenderer m;
    CHECK_FALSE(field_from_json(*ior, &m, Json(0.5)).ok());
    CHECK(m.ior == 1.5f);
    CHECK(field_from_json(*ior, &m, Json(2.4)).ok());
}

TEST_CASE("lighting fields: a scene with a bad value reports where, and loads nothing of that entity's field") {
    World w;
    const Json scene = Json::parse(R"({"format":"factoria.scene/1","entities":[
      {"id":"lamp","components":{"Light":{"type":"area","shadowFilter":"pcs"}}}]})");
    const LoadReport report = load_scene(w, scene, "bad.scene.json");
    CHECK_FALSE(report.ok());
    const std::string text = report.summary();
    CHECK(text.find("shadowFilter") != std::string::npos);
    CHECK(text.find("pcss") != std::string::npos);
}
