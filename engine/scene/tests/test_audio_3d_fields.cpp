// The 3D audio fields of AudioSource and AudioListener (M98.8a): defaults, and the scene file round trip.
#include <doctest.h>

#include "fa/core/reflect.h"
#include "fa/scene/components.h"
#include "fa/scene/serialize.h"
#include "fa/scene/world.h"

using namespace fa;

TEST_CASE("audio 3d fields: defaults leave a plain spatial source as it was") {
    AudioSource s;
    CHECK(s.rolloff == AudioRolloff::Linear);
    CHECK(s.rolloffCurve.is_array());
    CHECK(s.rolloffCurve.empty());
    CHECK(s.coneInnerAngle == 360.0f);
    CHECK(s.coneOuterAngle == 360.0f);
    CHECK(s.coneOuterGain == 0.0f);
    CHECK(s.dopplerLevel == 0.0f);
    CHECK_FALSE(s.occlusion);
    CHECK(s.occlusionMask == -1);
    AudioListener l;
    CHECK(l.spatialization == AudioSpatialization::Pan);
    CHECK(l.speedOfSound == 343.0f);
}

TEST_CASE("audio 3d fields: the scene file round trip") {
    World w;
    Entity e = w.create("src", "src");
    AudioSource& s = w.add<AudioSource>(e);
    s.spatial = true;
    s.rolloff = AudioRolloff::Curve;
    s.rolloffCurve = Json::parse("[[0, 1], [0.3, 0.8], [1, 0]]");
    s.coneInnerAngle = 40;
    s.coneOuterAngle = 100;
    s.coneOuterGain = 0.25f;
    s.coneAxis = {1, 0, 0};
    s.dopplerLevel = 1.5f;
    s.occlusion = true;
    s.occlusionMask = 6;
    s.occlusionGain = 0.5f;
    s.occlusionLowpass = 800;
    AudioListener& l = w.add<AudioListener>(e);
    l.spatialization = AudioSpatialization::Hrtf;
    l.headRadius = 0.09f;
    l.speedOfSound = 100;
    const Json j = entity_to_json(w, e);
    CHECK(j["components"]["AudioSource"]["rolloff"] == "curve");
    CHECK(j["components"]["AudioListener"]["spatialization"] == "hrtf");
    World w2;
    LoadReport report;
    Entity copy = entity_from_json(w2, j, kNullEntity, report);
    CHECK(report.ok());
    const AudioSource* c = w2.get<AudioSource>(copy);
    REQUIRE(c);
    CHECK(c->rolloff == AudioRolloff::Curve);
    CHECK(c->rolloffCurve == s.rolloffCurve);
    CHECK(c->coneInnerAngle == 40.0f);
    CHECK(c->coneOuterAngle == 100.0f);
    CHECK(c->coneOuterGain == 0.25f);
    CHECK(c->coneAxis.x == 1.0f);
    CHECK(c->dopplerLevel == 1.5f);
    CHECK(c->occlusion);
    CHECK(c->occlusionMask == 6);
    CHECK(c->occlusionGain == 0.5f);
    CHECK(c->occlusionLowpass == 800.0f);
    const AudioListener* cl = w2.get<AudioListener>(copy);
    REQUIRE(cl);
    CHECK(cl->spatialization == AudioSpatialization::Hrtf);
    CHECK(cl->headRadius == 0.09f);
    CHECK(cl->speedOfSound == 100.0f);
    CHECK(entity_to_json(w2, copy) == j);
    // a default source writes none of the new fields
    World w3;
    Entity plain = w3.create("p", "p");
    w3.add<AudioSource>(plain);
    CHECK(entity_to_json(w3, plain).dump().find("cone") == std::string::npos);
}
