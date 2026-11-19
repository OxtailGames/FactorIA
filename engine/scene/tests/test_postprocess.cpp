// M71: SceneSettings.colorSpace / hdrOutput / paperWhiteNits and the PostProcess component: defaults, reflection and the scene file
// round trip.
#include <doctest.h>

#include <set>
#include <string>

#include "fa/core/reflect.h"
#include "fa/scene/components.h"
#include "fa/scene/postprocess.h"
#include "fa/scene/serialize.h"
#include "fa/scene/world.h"

using namespace fa;

namespace {
template <class T>
const TypeInfo* info_of() {
    ensure_builtin_components();
    return TypeRegistry::global().of<T>();
}
}  // namespace

TEST_CASE("scene settings: the M71 fields default to today's look") {
    SceneSettings s;
    CHECK(s.colorSpace == ColorSpace::Gamma);
    CHECK(s.hdrOutput == HdrOutput::Off);
    CHECK(s.paperWhiteNits == 200.0f);
    const TypeInfo* t = info_of<SceneSettings>();
    REQUIRE(t);
    for (const char* name : {"colorSpace", "hdrOutput", "paperWhiteNits"}) {
        CAPTURE(name);
        const FieldInfo* f = t->field(name);
        REQUIRE(f);
        CHECK_FALSE(f->doc.empty());
    }
    CHECK(t->field("colorSpace")->kind == FieldKind::Enum);
    CHECK(t->field("colorSpace")->enumNames == std::vector<std::string>{"gamma", "linear"});
    CHECK(t->field("hdrOutput")->enumNames == std::vector<std::string>{"off", "auto"});
}

TEST_CASE("scene settings: a scene without the new fields loads as gamma and saves without them") {
    World w;
    const Json scene =
        Json::parse(R"({"format": "factoria.scene/1", "settings": {"gravity2D": [0, -500]}, "entities": []})");
    LoadReport report = load_scene(w, scene, "<test>");
    CHECK(report.ok());
    CHECK(w.settings().colorSpace == ColorSpace::Gamma);
    CHECK(w.settings().hdrOutput == HdrOutput::Off);
    CHECK(w.settings().paperWhiteNits == 200.0f);
    const Json saved = save_scene(w);
    CHECK_FALSE(saved["settings"].contains("colorSpace"));
    CHECK_FALSE(saved["settings"].contains("hdrOutput"));
    CHECK_FALSE(saved["settings"].contains("paperWhiteNits"));
}

TEST_CASE("scene settings: the M71 fields round trip through the scene file") {
    World w;
    w.settings().colorSpace = ColorSpace::Linear;
    w.settings().hdrOutput = HdrOutput::Auto;
    w.settings().paperWhiteNits = 350.0f;
    const Json saved = save_scene(w);
    CHECK(saved["settings"]["colorSpace"] == "linear");
    CHECK(saved["settings"]["hdrOutput"] == "auto");
    CHECK(saved["settings"]["paperWhiteNits"] == 350.0);
    World w2;
    LoadReport report = load_scene(w2, saved, "<test>");
    CHECK(report.ok());
    CHECK(w2.settings().colorSpace == ColorSpace::Linear);
    CHECK(w2.settings().hdrOutput == HdrOutput::Auto);
    CHECK(w2.settings().paperWhiteNits == 350.0f);
    CHECK(save_scene(w2) == saved);
}

TEST_CASE("scene settings: a bad colorSpace teaches the allowed names") {
    World w;
    const Json scene =
        Json::parse(R"({"format": "factoria.scene/1", "settings": {"colorSpace": "lineal"}, "entities": []})");
    LoadReport report = load_scene(w, scene, "<test>");
    CHECK_FALSE(report.ok());
    CHECK(report.summary().find("linear") != std::string::npos);
    CHECK(w.settings().colorSpace == ColorSpace::Gamma);
}

TEST_CASE("PostProcess: everything is off by default") {
    PostProcess p;
    CHECK(p.enabled);
    CHECK(p.shape == PostShape::Global);
    CHECK(p.weight == 1.0f);
    CHECK(p.priority == 0);
    const TypeInfo* t = info_of<PostProcess>();
    REQUIRE(t);
    for (const std::string_view effect : kPostEffectOrder) {
        const FieldInfo* f = t->field(std::string(effect) + "Enabled");
        CAPTURE(effect);
        REQUIRE(f);
        CHECK(f->kind == FieldKind::Bool);
        CHECK(*static_cast<const bool*>(f->ptr(&p)) == false);
    }
}

TEST_CASE("PostProcess: every field is documented and belongs to the metadata or to one effect") {
    const TypeInfo* t = info_of<PostProcess>();
    REQUIRE(t);
    CHECK(t->category == "Camera");
    CHECK_FALSE(t->doc.empty());
    const std::set<std::string> meta = {"enabled",  "shape",  "size",        "blendDistance",
                                        "priority", "weight", "customPasses"};
    for (const FieldInfo& f : t->fields) {
        CAPTURE(f.name);
        CHECK_FALSE(f.doc.empty());
        if (meta.count(f.name)) {
            CHECK(post_field_effect(f.name) == -1);
        } else {
            CHECK(post_field_effect(f.name) >= 0);
        }
    }
}

TEST_CASE("PostProcess: the effect order is complete, unique and none is the prefix of another") {
    CHECK(kPostEffectOrder.size() == std::size_t(kPostEffectCount));
    std::set<std::string_view> seen;
    for (int i = 0; i < kPostEffectCount; ++i) {
        const std::string_view a = kPostEffectOrder[std::size_t(i)];
        CHECK(seen.insert(a).second);
        CHECK(post_effect_from_name(a) == PostEffect(i));
        CHECK(post_effect_name(PostEffect(i)) == a);
        for (int j = 0; j < kPostEffectCount; ++j)
            if (i != j) CHECK(kPostEffectOrder[std::size_t(j)].substr(0, a.size()) != a);
    }
    CHECK(post_effect_from_name("bloomm") == PostEffect::Count);
    CHECK(kPostEffectOrder.front() == "ssao");
    CHECK(kPostEffectOrder.back() == "colorFilter");  // the accessibility filter is the last pass
    CHECK(post_effect_is_hdr(PostEffect::Bloom));
    CHECK_FALSE(post_effect_is_hdr(PostEffect::Tonemap));
}

TEST_CASE("PostProcess: the neutral stack has every effect off and a zero strength") {
    const PostProcess& n = postprocess_neutral();
    CHECK(n.bloomIntensity == 0.0f);
    CHECK(n.vignetteIntensity == 0.0f);
    CHECK(n.posterizeLevels == 256);
    CHECK(n.tonemapMode == TonemapMode::None);
    CHECK(n.colorGradingSaturation == 1.0f);
    for (const std::string_view effect : kPostEffectOrder) {
        const FieldInfo* f = info_of<PostProcess>()->field(std::string(effect) + "Enabled");
        CAPTURE(effect);
        REQUIRE(f);
        CHECK(*static_cast<const bool*>(f->ptr(&n)) == false);
    }
}

TEST_CASE("PostProcess: the scene file round trip, a default component writes nothing but the empty object") {
    World w;
    Entity cam = w.create("cam", "cam");
    w.add<Camera>(cam);
    PostProcess& p = w.add<PostProcess>(cam);
    p.bloomEnabled = true;
    p.bloomIntensity = 2.5f;
    p.tonemapEnabled = true;
    p.tonemapMode = TonemapMode::Agx;
    p.colorGradingEnabled = true;
    p.colorGradingLift = Color{0.1f, 0.0f, 0.2f, 1.0f};
    p.colorGradingCurveMaster = ArrayF32{};
    const float curve[] = {0.0f, 0.0f, 0.5f, 0.4f, 1.0f, 1.0f};
    p.colorGradingCurveMaster.assign(curve, 6);
    p.colorGradingLut = "grades/warm.cube";
    p.colorFilterEnabled = true;
    p.colorFilterMode = ColorFilter::Deuteranopia;
    p.outlineEnabled = true;
    p.outlineMode = OutlineMode::Sprite;
    p.ssaoEnabled = true;
    p.ssaoQuality = SsaoQuality::Ultra;
    p.posterizeEnabled = true;
    p.posterizeLevels = 5;
    Entity vol = w.create("vol", "vol");
    PostProcess& v = w.add<PostProcess>(vol);
    v.shape = PostShape::Sphere;
    v.size = {7, 7, 7};
    v.blendDistance = 3;
    v.priority = 2;
    v.weight = 0.5f;
    p.depthOfFieldEnabled = true;
    p.depthOfFieldTarget = vol;

    const Json saved = save_scene(w);
    const Json& pj = saved["entities"][0]["components"]["PostProcess"];
    CHECK(pj["bloomEnabled"] == true);
    CHECK(pj["tonemapMode"] == "agx");
    CHECK(pj["colorFilterMode"] == "deuteranopia");
    CHECK(pj["outlineMode"] == "sprite");
    CHECK(pj["ssaoQuality"] == "ultra");
    CHECK(pj["colorGradingCurveMaster"] == Json::parse("[0, 0, 0.5, 0.4, 1, 1]"));
    CHECK(pj["depthOfFieldTarget"] == "vol");
    CHECK_FALSE(pj.contains("sharpenEnabled"));
    CHECK(saved["entities"][1]["components"]["PostProcess"]["shape"] == "sphere");

    World w2;
    LoadReport report = load_scene(w2, saved, "<test>");
    CHECK(report.ok());
    CHECK(save_scene(w2) == saved);
    const PostProcess* q = w2.get<PostProcess>(w2.find("cam"));
    REQUIRE(q);
    CHECK(q->bloomIntensity == 2.5f);
    CHECK(q->colorGradingLut == "grades/warm.cube");
    CHECK(q->colorGradingCurveMaster.size() == 6);
    CHECK(q->depthOfFieldTarget == w2.find("vol"));
    const PostProcess* qv = w2.get<PostProcess>(w2.find("vol"));
    REQUIRE(qv);
    CHECK(qv->shape == PostShape::Sphere);
    CHECK(qv->size == Vec3{7, 7, 7});
    CHECK(qv->priority == 2);
}

TEST_CASE("PostProcess: an unknown field is refused with a suggestion") {
    World w;
    const Json scene = Json::parse(
        R"({"format": "factoria.scene/1", "entities": [{"id": "v", "components": {"PostProcess": {"bloomIntensty": 2}}}]})");
    LoadReport report = load_scene(w, scene, "<test>");
    CHECK(report.summary().find("bloomIntensity") != std::string::npos);
}
