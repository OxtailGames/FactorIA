// M74-P0: the components and fields of the ambitious 2D lighting and effects (soft shadows, shadow casters, emission, light layers,
// cookies, rim light, generated normals, 2D global illumination, water, distortion). They are reflected, validated, saved and loaded
// here; the packages M74.1 .. M74.4 draw them. Their defaults keep the look of every older scene.
#include <doctest.h>

#include <string>
#include <vector>

#include "fa/core/reflect.h"
#include "fa/scene/serialize.h"

using namespace fa;

namespace {
const FieldInfo* field_of(const char* type, const std::string& name) {
    ensure_builtin_components();
    const TypeInfo* t = TypeRegistry::global().find(type);
    if (!t) return nullptr;
    for (const FieldInfo& f : t->fields)
        if (f.name == name) return &f;
    return nullptr;
}
std::string error_text(const Result<void>& r) { return r.error().message + " " + r.error().hint; }
}  // namespace

TEST_CASE("m74 2d fields: every new field and component is reflected with a doc string") {
    ensure_builtin_components();
    const std::vector<std::pair<const char*, std::vector<std::string>>> expected = {
        {"Light2D", {"size", "lightLayers", "cookie", "cookieRotationDeg", "cookieScale"}},
        {"ShadowCaster2D", {"shape", "points", "size", "alphaThreshold", "selfShadow", "lightLayers", "enabled"}},
        {"Sprite",
         {"emissive", "emissiveIntensity", "emissiveMap", "lightLayers", "rimColor", "rimIntensity", "rimWidth",
          "normalFrom", "heightMap", "normalStrength"}},
        {"Shape2D", {"lightLayers"}},
        {"Tilemap", {"lightLayers", "emissive", "emissiveIntensity"}},
        {"GlobalIllumination2D", {"enabled", "quality", "intensity", "bounce", "range", "resolutionScale"}},
        {"Water2D",
         {"size", "tint", "reflection", "refraction", "waveAmplitude", "waveLength", "waveSpeed", "material"}},
        {"DistortionZone2D", {"size", "strength", "material"}}};
    for (const auto& [type, names] : expected) {
        const TypeInfo* t = TypeRegistry::global().find(type);
        REQUIRE_MESSAGE(t != nullptr, type);
        CHECK(t->doc.size() > 40);
        for (const std::string& n : names) {
            CAPTURE(type);
            CAPTURE(n);
            const FieldInfo* f = field_of(type, n);
            REQUIRE(f != nullptr);
            CHECK(f->doc.size() > 30);
            CHECK(f->serialized);
        }
    }
}

TEST_CASE("m74 2d fields: the defaults keep the look of a scene made before M74") {
    const Light2D l;
    CHECK(l.size == 0.0f);
    CHECK(l.lightLayers == -1);
    CHECK(l.cookie.empty());
    CHECK(l.cookieRotationDeg == 0.0f);
    CHECK(l.cookieScale == 1.0f);
    const Sprite s;
    CHECK(s.emissive.r == 0.0f);
    CHECK(s.emissive.g == 0.0f);
    CHECK(s.emissive.b == 0.0f);
    CHECK(s.emissiveIntensity == 1.0f);
    CHECK(s.lightLayers == 1);
    CHECK(s.rimIntensity == 0.0f);
    CHECK(s.normalFrom == SpriteNormalFrom::File);
    CHECK(s.normalStrength == 1.0f);
    CHECK(Shape2D().lightLayers == 1);
    const Tilemap tm;
    CHECK(tm.lightLayers == 1);
    CHECK(tm.emissive.r == 0.0f);
    const ShadowCaster2D sc;
    CHECK(sc.shape == ShadowCaster2DShape::SpriteAlpha);
    CHECK(sc.alphaThreshold == 0.5f);
    CHECK_FALSE(sc.selfShadow);
    CHECK(sc.lightLayers == -1);
    CHECK(sc.enabled);
    const GlobalIllumination2D gi;
    CHECK(gi.enabled);
    CHECK(gi.quality == GI2DQuality::Medium);
    CHECK(gi.resolutionScale == 0.5f);
}

TEST_CASE("m74 2d fields: an old scene loads unchanged and saves without any of the new keys") {
    World w;
    const Json scene = Json::parse(R"({"format":"factoria.scene/1",
      "entities":[{"id":"lamp","components":{"Light2D":{"radius":200,"castShadows":true}}},
                  {"id":"hero","components":{"Sprite":{"lit":true,"color":[1,0,0,1]},"Tilemap":{"lit":true}}}]})");
    const LoadReport report = load_scene(w, scene, "old.scene.json");
    INFO(report.summary());
    REQUIRE(report.ok());
    CHECK(w.get<Light2D>(w.find("lamp"))->lightLayers == -1);
    CHECK(w.get<Sprite>(w.find("hero"))->lightLayers == 1);
    const Json saved = save_scene(w);
    const std::vector<std::string> newKeys = {"size",        "lightLayers", "cookie",       "cookieRotationDeg",
                                              "cookieScale", "emissive",    "emissiveIntensity", "emissiveMap",
                                              "rimColor",    "rimIntensity", "rimWidth",    "normalFrom",
                                              "heightMap",   "normalStrength"};
    for (const Json& e : saved["entities"]) {
        for (const char* comp : {"Light2D", "Sprite", "Tilemap"}) {
            if (!e["components"].contains(comp)) continue;
            for (const std::string& n : newKeys) {
                CAPTURE(comp);
                CAPTURE(n);
                CHECK_FALSE(e["components"][comp].contains(n));
            }
        }
    }
}

TEST_CASE("m74 2d fields: a scene with every new field and component saves, loads again and keeps the values") {
    World w;
    const Json scene = Json::parse(R"({"format":"factoria.scene/1","entities":[
      {"id":"lamp","components":{"Light2D":{"size":12,"lightLayers":6,"cookie":"assets/cookie.png",
                                            "cookieRotationDeg":45,"cookieScale":0.5,"castShadows":true}}},
      {"id":"crate","components":{"Sprite":{"lit":true,"emissive":[1,0.5,0.25,1],"emissiveIntensity":4,
                       "emissiveMap":"assets/glow.png","lightLayers":3,"rimColor":[0,1,1,1],"rimIntensity":1.5,
                       "rimWidth":0.2,"normalFrom":"height","heightMap":"assets/h.png","normalStrength":2},
                       "ShadowCaster2D":{"shape":"polygon","points":[-16,-16,16,-16,0,16],"alphaThreshold":0.25,
                                         "selfShadow":true,"lightLayers":2,"enabled":false}}},
      {"id":"wall","components":{"Shape2D":{"lit":true,"lightLayers":4},
                                 "ShadowCaster2D":{"shape":"box","size":[64,32]}}},
      {"id":"gi","components":{"GlobalIllumination2D":{"quality":"high","intensity":2,"bounce":0.8,"range":300,
                                                       "resolutionScale":0.25}}},
      {"id":"sea","components":{"Water2D":{"size":[400,100],"tint":[0,0,1,0.5],"reflection":0.7,"refraction":6,
                                           "waveAmplitude":3,"waveLength":50,"waveSpeed":-2}}},
      {"id":"haze","components":{"DistortionZone2D":{"size":[100,50],"strength":3}}}]})");
    const LoadReport report = load_scene(w, scene, "new.scene.json");
    INFO(report.summary());
    REQUIRE(report.ok());
    const Json saved = save_scene(w);
    World again;
    REQUIRE(load_scene(again, saved, "again.scene.json").ok());
    CHECK(save_scene(again) == saved);
    const Light2D* l = again.get<Light2D>(again.find("lamp"));
    REQUIRE(l != nullptr);
    CHECK(l->size == 12.0f);
    CHECK(l->lightLayers == 6);
    CHECK(l->cookie == "assets/cookie.png");
    CHECK(l->cookieScale == 0.5f);
    const Sprite* sp = again.get<Sprite>(again.find("crate"));
    REQUIRE(sp != nullptr);
    CHECK(sp->emissive.r == 1.0f);
    CHECK(sp->emissiveIntensity == 4.0f);  // HDR strength
    CHECK(sp->normalFrom == SpriteNormalFrom::Height);
    CHECK(sp->heightMap == "assets/h.png");
    CHECK(sp->lightLayers == 3);
    const ShadowCaster2D* sc = again.get<ShadowCaster2D>(again.find("crate"));
    REQUIRE(sc != nullptr);
    CHECK(sc->shape == ShadowCaster2DShape::Polygon);
    CHECK(sc->points.size() == 6);
    CHECK(sc->selfShadow);
    CHECK_FALSE(sc->enabled);
    CHECK(again.get<ShadowCaster2D>(again.find("wall"))->size.x == 64.0f);
    CHECK(again.get<Shape2D>(again.find("wall"))->lightLayers == 4);
    const GlobalIllumination2D* gi = again.get<GlobalIllumination2D>(again.find("gi"));
    REQUIRE(gi != nullptr);
    CHECK(gi->quality == GI2DQuality::High);
    CHECK(gi->bounce == doctest::Approx(0.8f));
    const Water2D* wa = again.get<Water2D>(again.find("sea"));
    REQUIRE(wa != nullptr);
    CHECK(wa->waveSpeed == -2.0f);
    CHECK(again.get<DistortionZone2D>(again.find("haze"))->strength == 3.0f);
}

TEST_CASE("m74 2d fields: enum strings suggest the right name and numbers are range-checked") {
    Sprite s;
    const FieldInfo* from = field_of("Sprite", "normalFrom");
    REQUIRE(from != nullptr);
    const Result<void> typo = field_from_json(*from, &s, Json("hieght"));
    REQUIRE_FALSE(typo.ok());
    CHECK(error_text(typo).find("height") != std::string::npos);
    CHECK(s.normalFrom == SpriteNormalFrom::File);

    ShadowCaster2D sc;
    const FieldInfo* shape = field_of("ShadowCaster2D", "shape");
    REQUIRE(shape != nullptr);
    const Result<void> shapeTypo = field_from_json(*shape, &sc, Json("spritealpha2"));
    REQUIRE_FALSE(shapeTypo.ok());
    CHECK(error_text(shapeTypo).find("spriteAlpha") != std::string::npos);
    CHECK(field_from_json(*shape, &sc, Json("polygon")).ok());
    CHECK(sc.shape == ShadowCaster2DShape::Polygon);

    GlobalIllumination2D gi;
    const FieldInfo* quality = field_of("GlobalIllumination2D", "quality");
    REQUIRE(quality != nullptr);
    const Result<void> q = field_from_json(*quality, &gi, Json("hgih"));
    REQUIRE_FALSE(q.ok());
    CHECK(error_text(q).find("high") != std::string::npos);

    Light2D l;
    const FieldInfo* size = field_of("Light2D", "size");
    REQUIRE(size != nullptr);
    const Result<void> neg = field_from_json(*size, &l, Json(-1));
    REQUIRE_FALSE(neg.ok());
    CHECK(neg.error().message.find("size") != std::string::npos);
    CHECK(l.size == 0.0f);
    const FieldInfo* bounce = field_of("GlobalIllumination2D", "bounce");
    REQUIRE(bounce != nullptr);
    CHECK_FALSE(field_from_json(*bounce, &gi, Json(1.5)).ok());
    CHECK(field_from_json(*bounce, &gi, Json(1.0)).ok());
}

TEST_CASE("m74 2d fields: contradictions between fields are reported with a pointer") {
    World w;
    const Json scene = Json::parse(R"({"format":"factoria.scene/1","entities":[
      {"id":"sea","components":{"Water2D":{"size":[0,100]}}},
      {"id":"poly","components":{"ShadowCaster2D":{"shape":"polygon","points":[0,0,1,1]}}}]})");
    const LoadReport report = load_scene(w, scene, "bad.scene.json");
    CHECK_FALSE(report.ok());
    const std::string text = report.summary();
    CHECK(text.find("Water2D/size") != std::string::npos);
    CHECK(text.find("ShadowCaster2D/points") != std::string::npos);
}
