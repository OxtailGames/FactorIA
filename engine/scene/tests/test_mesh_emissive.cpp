#include <doctest.h>

#include "fa/scene/serialize.h"

using namespace fa;

namespace {
bool has_message(const LoadReport& r, LoadMessage::Severity sev, const std::string& needle) {
    for (const auto& m : r.messages)
        if (m.severity == sev && m.to_string().find(needle) != std::string::npos) return true;
    return false;
}
}  // namespace

TEST_CASE("scene: MeshRenderer.emissiveStrength defaults to 1, round trips and is range-checked") {
    World w;
    LoadReport r = load_scene(w, Json::parse(R"({
      "format": "factoria.scene/1",
      "entities": [
        { "id": "lamp", "components": { "MeshRenderer": { "mesh": "sphere", "emissive": [1, 0.8, 0.3, 1], "emissiveStrength": 4.5 } } },
        { "id": "plain", "components": { "MeshRenderer": { "emissive": [0.2, 0.2, 0.2, 1] } } },
        { "id": "bad", "components": { "MeshRenderer": { "emissiveStrength": -1 } } }
      ]})"),
                              "emissive.scene.json");
    CHECK(r.error_count() == 1);
    CHECK(has_message(r, LoadMessage::Severity::Error,
                      "#/entities/2/components/MeshRenderer/emissiveStrength: Field 'emissiveStrength': value -1 is "
                      "outside the allowed range 0..100"));
    CHECK(MeshRenderer{}.emissiveStrength == 1.0f);
    CHECK(w.get<MeshRenderer>(w.find_by_id("lamp"))->emissiveStrength == 4.5f);
    CHECK(w.get<MeshRenderer>(w.find_by_id("plain"))->emissiveStrength == 1.0f);
    CHECK(w.get<MeshRenderer>(w.find_by_id("bad"))->emissiveStrength == 1.0f);  // a bad value keeps the default

    Json saved = save_scene(w);
    CHECK(saved["entities"][0]["components"]["MeshRenderer"]["emissiveStrength"] == 4.5);
    CHECK(!saved["entities"][1]["components"]["MeshRenderer"].contains(
        "emissiveStrength"));  // the default is not written
    World again;
    CHECK(load_scene(again, saved, "again").ok());
    CHECK(again.get<MeshRenderer>(again.find_by_id("lamp"))->emissiveStrength == 4.5f);
}
