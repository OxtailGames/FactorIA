// M75-P0: the components and fields of the big worlds (LOD, occlusion, streaming, terrain, foliage). They are reflected,
// validated, saved and loaded here; the packages M75.1 .. M75.6 draw and simulate them. Their defaults keep every older scene
// as it was.
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

// The messages of a scene load, as "severity pointer: message hint" lines.
std::string load_messages(const char* sceneText, LoadReport* out = nullptr) {
    World w;
    const LoadReport report = load_scene(w, Json::parse(sceneText), "world.scene.json");
    std::string text;
    for (const LoadMessage& m : report.messages)
        text += std::string(m.severity == LoadMessage::Severity::Error ? "error " : "warning ") + m.pointer + ": " +
                m.message + " " + m.hint + "\n";
    if (out) *out = report;
    return text;
}
bool has(const std::string& text, const char* needle) { return text.find(needle) != std::string::npos; }
}  // namespace

TEST_CASE("m75 world: every new field and component is reflected with a doc string") {
    ensure_builtin_components();
    const std::vector<std::pair<const char*, std::vector<std::string>>> expected = {
        {"MeshRenderer", {"lodMode", "lodCrossFade", "impostor", "impostorDistance"}},
        {"LodGroup", {"mode", "thresholds", "crossFade", "hlodProxy", "hlodThreshold"}},
        {"Occluder", {"shape", "size", "center", "mesh", "enabled"}},
        {"OcclusionArea", {"size", "areaId"}},
        {"OcclusionPortal", {"size", "areaA", "areaB", "open"}},
        {"StreamingAnchor", {"loadRadius", "unloadRadius", "priority", "enabled"}},
        {"Terrain",
         {"heightmap", "size", "heightScale", "heightOffset", "splatMaps", "layers", "holes", "lodQuality",
          "castShadows", "collision"}},
        {"Foliage",
         {"meshes", "instances", "density", "windStrength", "windFrequency", "lodDistance", "fadeStart", "fadeEnd",
          "castShadows"}},
        {"ScatterRule",
         {"meshes", "density", "minSpacing", "slopeRange", "heightRange", "scaleRange", "alignToNormal", "layerMask",
          "seed", "terrain"}}};
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
    // The components that are new say, in their own text, which package builds them.
    for (const char* type : {"LodGroup", "Occluder", "OcclusionArea", "OcclusionPortal", "StreamingAnchor", "Terrain",
                             "Foliage", "ScatterRule"})
        CHECK_MESSAGE(TypeRegistry::global().find(type)->doc.find("M75.") != std::string::npos, type);
}

TEST_CASE("m75 world: the defaults keep every scene made before M75 as it was") {
    const MeshRenderer mr;
    CHECK(mr.lodMode == LodMode::Distance);
    CHECK(mr.lodCrossFade == 0.0f);
    CHECK(mr.impostor.empty());
    CHECK(mr.impostorDistance == 0.0f);
    const LodGroup lg;
    CHECK(lg.mode == LodMode::Distance);
    CHECK(lg.thresholds.empty());
    CHECK(lg.crossFade == 0.0f);
    CHECK(lg.hlodProxy.empty());
    const Occluder oc;
    CHECK(oc.shape == OccluderShape::Box);
    CHECK(oc.size.x == 1.0f);
    CHECK(oc.enabled);
    const OcclusionArea oa;
    CHECK(oa.size.y == 4.0f);
    CHECK(oa.areaId == 1);
    const OcclusionPortal op;
    CHECK(op.areaA == 0);
    CHECK(op.areaB == 0);
    CHECK(op.open);
    const StreamingAnchor sa;
    CHECK(sa.loadRadius == 256.0f);
    CHECK(sa.unloadRadius == 320.0f);
    CHECK(sa.priority == 0);
    CHECK(sa.enabled);
    const Terrain3D tr;
    CHECK(tr.heightmap.empty());
    CHECK(tr.size.x == 512.0f);
    CHECK(tr.heightScale == 100.0f);
    CHECK(tr.splatMaps.is_array());
    CHECK(tr.layers.is_array());
    CHECK(tr.lodQuality == 1.0f);
    CHECK(tr.collision);
    const Foliage fo;
    REQUIRE(fo.meshes.is_array());
    REQUIRE(fo.meshes.size() == 1);
    CHECK(fo.meshes[0] == "cube");
    CHECK(fo.density == 1.0f);
    CHECK(fo.windStrength == 0.0f);
    CHECK(fo.fadeStart == 80.0f);
    CHECK(fo.fadeEnd == 100.0f);
    CHECK_FALSE(fo.castShadows);
    const ScatterRule sr;
    CHECK(sr.density == 0.1f);
    CHECK(sr.slopeRange.y == 45.0f);
    CHECK(sr.scaleRange.x == 0.8f);
    CHECK(sr.layerMask == -1);
    CHECK(sr.seed == 1);
    CHECK(sr.terrain == kNullEntity);
}

TEST_CASE("m75 world: an old scene loads unchanged and saves without any of the new keys") {
    World w;
    const Json scene = Json::parse(R"({"format":"factoria.scene/1","entities":[
      {"id":"lamp","components":{"MeshRenderer":{"mesh":"assets/lamp.glb","lods":[{"mesh":"assets/lamp.lod1.glb","distance":12}]}}}]})");
    const LoadReport report = load_scene(w, scene, "old.scene.json");
    INFO(report.summary());
    REQUIRE(report.ok());
    CHECK(report.messages.empty());
    const Json saved = save_scene(w);
    for (const Json& e : saved["entities"])
        for (const char* n : {"lodMode", "lodCrossFade", "impostor", "impostorDistance"}) {
            CAPTURE(n);
            CHECK_FALSE(e["components"]["MeshRenderer"].contains(n));
        }
}

TEST_CASE("m75 world: a scene with every new component saves, loads again and keeps the values") {
    World w;
    const Json scene = Json::parse(R"({"format":"factoria.scene/1","entities":[
      {"id":"tree","components":{"MeshRenderer":{"mesh":"assets/tree.glb","lodMode":"screenSize","lodCrossFade":0.5,
          "lods":[{"mesh":"assets/tree.lod1.glb","screenSize":0.4},{"mesh":"assets/tree.lod2.glb","screenSize":0.1}],
          "impostor":"assets/tree.impostor.json","impostorDistance":0.03}}},
      {"id":"group","components":{"LodGroup":{"mode":"screenSize","thresholds":[0.5,0.2,0.05],"crossFade":0.25,
          "hlodProxy":"assets/cell.glb","hlodThreshold":0.01}}},
      {"id":"wall","components":{"Occluder":{"shape":"box","size":[10,6,0.5],"center":[0,3,0],"enabled":false}}},
      {"id":"hill","components":{"MeshRenderer":{"mesh":"assets/hill.glb"},"Occluder":{"shape":"mesh"}}},
      {"id":"room","components":{"OcclusionArea":{"size":[8,3,6],"areaId":7}}},
      {"id":"door","components":{"OcclusionPortal":{"size":[1,2,0.3],"areaA":7,"areaB":0,"open":false}}},
      {"id":"hero","components":{"StreamingAnchor":{"loadRadius":500,"unloadRadius":700,"priority":5,"enabled":false}}},
      {"id":"ground","components":{"Terrain":{"heightmap":"terrain/h.png","size":[2048,1024],"heightScale":250,"heightOffset":-10,
          "splatMaps":["terrain/s0.png"],"layers":[{"albedo":"terrain/grass.png","tileSize":3,"roughness":0.8},{"albedo":"terrain/rock.png"}],
          "holes":"terrain/holes.png","lodQuality":2,"castShadows":false,"collision":false}}},
      {"id":"grass","components":{"Foliage":{"meshes":["assets/grass.glb","assets/flower.glb"],"instances":"terrain/grass.foliage","density":0.5,
          "windStrength":0.2,"windFrequency":1.5,"lodDistance":20,"fadeStart":50,"fadeEnd":60,"castShadows":true},
          "ScatterRule":{"meshes":[{"mesh":"assets/grass.glb","weight":3},{"mesh":"assets/flower.glb"}],"density":2,
          "minSpacing":0.2,"slopeRange":[0,30],"heightRange":[0,500],"scaleRange":[0.5,1.5],"alignToNormal":0.5,
          "layerMask":3,"seed":42,"terrain":"ground"}}}]})");
    const LoadReport report = load_scene(w, scene, "new.scene.json");
    INFO(report.summary());
    REQUIRE(report.ok());
    CHECK(report.messages.empty());
    const Json saved = save_scene(w);
    World again;
    REQUIRE(load_scene(again, saved, "again.scene.json").ok());
    CHECK(save_scene(again) == saved);
    const MeshRenderer* mr = again.get<MeshRenderer>(again.find("tree"));
    REQUIRE(mr != nullptr);
    CHECK(mr->lodMode == LodMode::ScreenSize);
    CHECK(mr->lodCrossFade == 0.5f);
    CHECK(mr->impostor == "assets/tree.impostor.json");
    CHECK(mr->impostorDistance == doctest::Approx(0.03f));
    CHECK(mr->lods[1]["screenSize"] == 0.1);
    const LodGroup* lg = again.get<LodGroup>(again.find("group"));
    REQUIRE(lg != nullptr);
    CHECK(lg->mode == LodMode::ScreenSize);
    REQUIRE(lg->thresholds.size() == 3);
    CHECK(lg->thresholds[2] == doctest::Approx(0.05f));
    CHECK(lg->hlodProxy == "assets/cell.glb");
    const Occluder* oc = again.get<Occluder>(again.find("wall"));
    REQUIRE(oc != nullptr);
    CHECK(oc->size.x == 10.0f);
    CHECK(oc->center.y == 3.0f);
    CHECK_FALSE(oc->enabled);
    CHECK(again.get<Occluder>(again.find("hill"))->shape == OccluderShape::Mesh);
    CHECK(again.get<OcclusionArea>(again.find("room"))->areaId == 7);
    const OcclusionPortal* op = again.get<OcclusionPortal>(again.find("door"));
    REQUIRE(op != nullptr);
    CHECK(op->areaA == 7);
    CHECK_FALSE(op->open);
    const StreamingAnchor* sa = again.get<StreamingAnchor>(again.find("hero"));
    REQUIRE(sa != nullptr);
    CHECK(sa->loadRadius == 500.0f);
    CHECK(sa->priority == 5);
    CHECK_FALSE(sa->enabled);
    const Terrain3D* tr = again.get<Terrain3D>(again.find("ground"));
    REQUIRE(tr != nullptr);
    CHECK(tr->size.x == 2048.0f);
    CHECK(tr->heightOffset == -10.0f);
    CHECK(tr->layers.size() == 2);
    CHECK(tr->layers[0]["tileSize"] == 3);
    CHECK(tr->holes == "terrain/holes.png");
    CHECK_FALSE(tr->collision);
    const Foliage* fo = again.get<Foliage>(again.find("grass"));
    REQUIRE(fo != nullptr);
    CHECK(fo->fadeEnd == 60.0f);
    REQUIRE(fo->meshes.size() == 2);
    CHECK(fo->meshes[1] == "assets/flower.glb");
    CHECK(fo->castShadows);
    const ScatterRule* sr = again.get<ScatterRule>(again.find("grass"));
    REQUIRE(sr != nullptr);
    CHECK(sr->meshes.size() == 2);
    CHECK(sr->seed == 42);
    CHECK(sr->layerMask == 3);
    CHECK(sr->slopeRange.y == 30.0f);
    CHECK(sr->terrain == again.find("ground"));
}

TEST_CASE("m75 world: enum names suggest the right one and numbers are range-checked") {
    MeshRenderer mr;
    const FieldInfo* mode = field_of("MeshRenderer", "lodMode");
    REQUIRE(mode != nullptr);
    const Result<void> typo = field_from_json(*mode, &mr, Json("screensize2"));
    REQUIRE_FALSE(typo.ok());
    CHECK(has(error_text(typo), "screenSize"));
    CHECK(mr.lodMode == LodMode::Distance);
    CHECK(field_from_json(*mode, &mr, Json("screenSize")).ok());
    CHECK(mr.lodMode == LodMode::ScreenSize);

    Occluder oc;
    const FieldInfo* shape = field_of("Occluder", "shape");
    REQUIRE(shape != nullptr);
    CHECK(has(error_text(field_from_json(*shape, &oc, Json("mehs"))), "mesh"));

    const FieldInfo* fade = field_of("MeshRenderer", "lodCrossFade");
    REQUIRE(fade != nullptr);
    CHECK_FALSE(field_from_json(*fade, &mr, Json(-1)).ok());
    CHECK_FALSE(field_from_json(*fade, &mr, Json(60)).ok());
    CHECK(field_from_json(*fade, &mr, Json(0.3)).ok());

    OcclusionArea oa;
    const FieldInfo* id = field_of("OcclusionArea", "areaId");
    REQUIRE(id != nullptr);
    const Result<void> zero = field_from_json(*id, &oa, Json(0));
    REQUIRE_FALSE(zero.ok());
    CHECK(has(zero.error().message, "areaId"));
    CHECK_FALSE(field_from_json(*id, &oa, Json(70000)).ok());
    CHECK(oa.areaId == 1);

    LodGroup lg;
    const FieldInfo* th = field_of("LodGroup", "thresholds");
    REQUIRE(th != nullptr);
    CHECK_FALSE(field_from_json(*th, &lg, Json::parse("[10, -3]")).ok());
    CHECK(field_from_json(*th, &lg, Json::parse("[10, 30]")).ok());
    CHECK(lg.thresholds.size() == 2);

    ScatterRule sr;
    const FieldInfo* dens = field_of("ScatterRule", "density");
    REQUIRE(dens != nullptr);
    CHECK_FALSE(field_from_json(*dens, &sr, Json(1000)).ok());
}

TEST_CASE("m75 world: contradictions between fields are errors with a pointer, a name and a fix") {
    const std::string text = load_messages(R"({"format":"factoria.scene/1","entities":[
      {"id":"g","components":{"LodGroup":{"mode":"distance","thresholds":[40,15]}}},
      {"id":"h","components":{"LodGroup":{"mode":"screenSize","thresholds":[0.2,0.5,2]}}},
      {"id":"p","components":{"LodGroup":{"hlodProxy":"assets/cell.glb"}}},
      {"id":"box","components":{"Occluder":{"size":[1,0,1]}}},
      {"id":"m","components":{"Occluder":{"shape":"mesh"}}},
      {"id":"r","components":{"OcclusionArea":{"size":[0,3,3]}}},
      {"id":"a","components":{"StreamingAnchor":{"loadRadius":300,"unloadRadius":300}}},
      {"id":"t","components":{"Terrain":{"size":[0,512],"splatMaps":[1,"a.png","b.png","c.png"],
            "layers":[{"albedo":""},{"normal":"x.png"},3,{"albedo":"a.png","tileSize":0,"roughnes":1}]}}},
      {"id":"f","components":{"Foliage":{"meshes":[3,""],"fadeStart":90,"fadeEnd":50}}},
      {"id":"s","components":{"ScatterRule":{"meshes":[{"mesh":"a.glb","weight":0},{"weight":1},5],
            "slopeRange":[50,10],"scaleRange":[0,1]}}}]})");
    INFO(text);
    CHECK(has(text, "error /entities/0/components/LodGroup/thresholds/1"));
    CHECK(has(text, "LodGroup.thresholds[1] is 15, not above the one before it (40)"));
    CHECK(has(text, "(entity 'g')"));
    CHECK(has(text, "error /entities/1/components/LodGroup/thresholds/1"));
    CHECK(has(text, "LodGroup/thresholds/2"));
    CHECK(has(text, "LodGroup/hlodThreshold"));
    CHECK(has(text, "Occluder/size"));
    CHECK(has(text, "Occluder/mesh"));
    CHECK(has(text, "OcclusionArea/size"));
    CHECK(has(text, "StreamingAnchor/unloadRadius"));
    CHECK(has(text, "Terrain/size"));
    CHECK(has(text, "Terrain/splatMaps/0"));
    CHECK(has(text, "Terrain/splatMaps"));
    CHECK(has(text, "Terrain/layers/0/albedo"));
    CHECK(has(text, "Terrain/layers/1"));
    CHECK(has(text, "Terrain/layers/2"));
    CHECK(has(text, "Terrain/layers/3/tileSize"));
    CHECK(has(text, "Did you mean 'roughness'"));
    CHECK(has(text, "Foliage/fadeEnd"));
    CHECK(has(text, "Foliage/meshes/0"));
    CHECK(has(text, "Foliage/meshes/1"));
    CHECK(has(text, "ScatterRule/meshes/0/weight"));
    CHECK(has(text, "ScatterRule/meshes/1"));
    CHECK(has(text, "ScatterRule/meshes/2"));
    CHECK(has(text, "ScatterRule/slopeRange"));
    CHECK(has(text, "ScatterRule/scaleRange"));
}

TEST_CASE("m75 world: settings that do nothing are warnings, not errors") {
    LoadReport report;
    const std::string text = load_messages(R"({"format":"factoria.scene/1","entities":[
      {"id":"tree","components":{"MeshRenderer":{"mesh":"assets/t.glb","impostor":"assets/t.impostor.json",
          "lods":[{"mesh":"assets/t1.glb","screenSize":0.3}]}}},
      {"id":"bush","components":{"MeshRenderer":{"mesh":"assets/b.glb","lodMode":"screenSize","impostorDistance":0.5,
          "lods":[{"mesh":"assets/b1.glb","distance":10}]}}},
      {"id":"door","components":{"OcclusionPortal":{"areaA":2,"areaB":2}}},
      {"id":"cell","components":{"LodGroup":{"hlodThreshold":100}}}]})",
                                           &report);
    INFO(text);
    CHECK(report.ok());
    CHECK(has(text, "warning /entities/0/components/MeshRenderer/impostorDistance"));
    CHECK(has(text, "warning /entities/0/components/MeshRenderer/lods/0"));
    CHECK(has(text, "warning /entities/1/components/MeshRenderer/lods/0"));
    CHECK(has(text, "warning /entities/1/components/MeshRenderer/impostorDistance"));
    CHECK(has(text, "warning /entities/2/components/OcclusionPortal/areaB"));
    CHECK(has(text, "warning /entities/3/components/LodGroup/hlodThreshold"));
}

TEST_CASE("m75 world: screenSize entries of lods are checked against 0..1") {
    const std::string text = load_messages(R"({"format":"factoria.scene/1","entities":[
      {"id":"tree","components":{"MeshRenderer":{"mesh":"assets/t.glb","lodMode":"screenSize",
          "lods":[{"mesh":"assets/t1.glb","screenSize":3},{"mesh":"assets/t2.glb","screenSize":"small"}]}}}]})");
    INFO(text);
    CHECK(has(text, "error /entities/0/components/MeshRenderer/lods/0/screenSize"));
    CHECK(has(text, "error /entities/0/components/MeshRenderer/lods/1/screenSize"));
}
