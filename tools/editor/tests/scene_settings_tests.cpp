// The Scene settings panel's rules (scene_settings_model.h) and the command it edits through (scene.set_component on
// "SceneSettings", with its undo plan), against a real headless Engine in a temporary project. No window, no GPU.
#include <algorithm>
#include <filesystem>
#include <fstream>

#include "doctest.h"
#include "fa/authoring/authoring.h"
#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/scene/serialize.h"
#include "scene_settings_model.h"
#include "undo_inverse.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Scene Settings Test",
  "id": "com.example.scenesettings",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [ { "id": "hero", "name": "Hero", "components": { "Transform": { "position": [10, 20, 0] } } } ]
})";

struct Session {
    stdfs::path dir;
    Engine engine;
    Session() {
        static const bool installed = (fa::authoring::install(), true);
        (void)installed;
        dir = fs::make_temp_dir("fa_scene_settings").value();
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary) << kProject;
        std::ofstream(dir / "scenes/main.scene.json", std::ios::binary) << kScene;
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        c.editorMode = true;
        std::string err;
        REQUIRE_MESSAGE(engine.init(c, nullptr, &err), err);
    }
    ~Session() {
        engine.shutdown();
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    World& world() { return engine.world(); }
    CommandResult call(const std::string& name, const Json& args) { return engine.commands().call(name, args); }
    Json values() { return settings_values(*TypeRegistry::global().find("SceneSettings"), &world().settings()); }
};

const TypeInfo& settings_type() {
    const TypeInfo* t = TypeRegistry::global().find("SceneSettings");
    REQUIRE(t != nullptr);
    return *t;
}

}  // namespace

TEST_CASE("scene settings model: the groups place every serialized field once, the sky first") {
    Session s;
    const std::vector<SettingsGroup> groups = settings_groups(settings_type());
    REQUIRE(!groups.empty());
    CHECK(groups.front().title == "Sky");
    std::vector<std::string> names;
    for (const SettingsGroup& g : groups) {
        CHECK(!g.hint.empty());
        CHECK(!g.fields.empty());
        for (const FieldInfo* f : g.fields) names.push_back(f->name);
    }
    for (const FieldInfo& f : settings_type().fields) {
        const auto n = std::count(names.begin(), names.end(), f.name);
        CHECK_MESSAGE(n == (f.serialized ? 1 : 0), f.name);
    }
    // The sky group names the four sky fields in the order of the panel.
    REQUIRE(groups.front().fields.size() == 4);
    CHECK(groups.front().fields[0]->name == "skyColor");
    CHECK(groups.front().fields[2]->name == "skyMaterial");
    CHECK(groups.front().fields[3]->name == "skyMaterialParams");
}

TEST_CASE("scene settings model: values and defaults are JSON of the serialized fields") {
    Session s;
    const Json defaults = settings_defaults(settings_type());
    REQUIRE(defaults.is_object());
    CHECK(defaults.contains("skyColor"));
    CHECK(defaults.value("skyMaterial", std::string("x")).empty());
    CHECK(s.values() == defaults);  // a fresh scene is at its defaults
    REQUIRE(s.call("scene.set_component", settings_edit_args("fogDensity", 0.25)).ok);
    CHECK(s.values() != defaults);
    CHECK(s.values()["fogDensity"].get<double>() == doctest::Approx(0.25));
}

TEST_CASE("scene settings model: edit and reset arguments") {
    const Json e = settings_edit_args("skyMaterial", "materials/a.material.json");
    CHECK(e["component"] == "SceneSettings");
    CHECK(!e.contains("id"));
    CHECK(!e.contains("merge"));
    CHECK(e["fields"]["skyMaterial"] == "materials/a.material.json");
    const Json m = settings_edit_args("skyMaterialParams", Json::object({{"strength", 2}}), true);
    CHECK(m["merge"] == true);
    const Json r = settings_reset_args("skyMaterialParams");
    CHECK(r["merge"] == true);
    CHECK(r["fields"]["skyMaterialParams"].is_null());
}

TEST_CASE("scene settings model: what the panel says about the sky material") {
    using Level = SkyMaterialNote::Level;
    CHECK(sky_material_note("", Json(), "", "").level == Level::None);
    const SkyMaterialNote bad = sky_material_note("m.material.json", Json(), "File not found.", "");
    CHECK(bad.level == Level::Error);
    CHECK(bad.text.find("File not found.") != std::string::npos);
    const SkyMaterialNote other = sky_material_note("m.material.json", Json::object({{"kind", "sprite"}}), "", "");
    CHECK(other.level == Level::Warning);
    CHECK(other.text.find("sprite") != std::string::npos);
    CHECK(other.text.find("sky") != std::string::npos);
    const SkyMaterialNote failed =
        sky_material_note("m.material.json", Json::object({{"kind", "sky"}}), "", "line 3: oops");
    CHECK(failed.level == Level::Error);
    CHECK(failed.text.find("line 3: oops") != std::string::npos);
    const SkyMaterialNote ok = sky_material_note("m.material.json", Json::object({{"kind", "sky"}}), "", "");
    CHECK(ok.level == Level::Info);
}

TEST_CASE("scene.set_component on SceneSettings: set, merge, reset, refusals") {
    Session s;
    CommandResult r = s.call("scene.set_component", settings_edit_args("skyColor", Json::array({1.0, 0.0, 0.0, 1.0})));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(s.world().settings().skyColor.r == doctest::Approx(1.0f));
    CHECK(s.world().settings().skyColor.g == doctest::Approx(0.0f));

    REQUIRE(s.call("scene.set_component", settings_edit_args("skyMaterial", "materials/a.material.json")).ok);
    CHECK(s.world().settings().skyMaterial == "materials/a.material.json");

    // skyMaterialParams merges (RFC 7386): the other keys stay, a null removes one.
    REQUIRE(s.call("scene.set_component", settings_edit_args("skyMaterialParams", Json::object({{"a", 1}}), true)).ok);
    REQUIRE(s.call("scene.set_component", settings_edit_args("skyMaterialParams", Json::object({{"b", 2}}), true)).ok);
    CHECK(s.world().settings().skyMaterialParams == Json::object({{"a", 1}, {"b", 2}}));
    REQUIRE(s.call("scene.set_component",
                   settings_edit_args("skyMaterialParams", Json::object({{"a", Json(nullptr)}}), true))
                .ok);
    CHECK(s.world().settings().skyMaterialParams == Json::object({{"b", 2}}));
    REQUIRE(s.call("scene.set_component", settings_reset_args("skyMaterialParams")).ok);
    const bool paramsGone =
        s.world().settings().skyMaterialParams.is_null() || s.world().settings().skyMaterialParams.empty();
    CHECK(paramsGone);

    // An unknown field is refused with a suggestion and changes nothing, also next to a valid one.
    const Json before = s.values();
    r = s.call(
        "scene.set_component",
        Json::object({{"component", "SceneSettings"},
                      {"fields", Json::object({{"fogDensity", 0.5}, {"skyColour", Json::array({0, 0, 0, 1})}})}}));
    CHECK(!r.ok);
    CHECK(r.error.dump().find("skyColour") != std::string::npos);
    CHECK(r.error.dump().find("skyColor") != std::string::npos);  // did you mean
    CHECK(s.values() == before);

    // A value of the wrong type is refused, names the field, and changes nothing (the field before it included).
    r = s.call("scene.set_component",
               Json::object({{"component", "SceneSettings"},
                             {"fields", Json::object({{"fogColor", Json::array({0.1, 0.2, 0.3, 1.0})},
                                                      {"fogDensity", "thick"}})}}));
    CHECK(!r.ok);
    CHECK(r.error.dump().find("fogDensity") != std::string::npos);
    CHECK(s.values() == before);

    // An empty id counts as none (the Inspector's helpers spell the id out, empty for the scene), also for the undo
    // plan.
    const Json emptyId =
        Json::object({{"id", ""}, {"component", "SceneSettings"}, {"fields", Json::object({{"fogDensity", 0.75}})}});
    REQUIRE(plan_undo(s.world(), "scene.set_component", emptyId).has_value());
    r = s.call("scene.set_component", emptyId);
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(s.values()["fogDensity"].get<double>() == doctest::Approx(0.75));
    REQUIRE(s.call("scene.set_component", settings_edit_args("fogDensity", 0.0)).ok);
    CHECK(s.values() == before);  // back to what it was

    // An id names an entity: SceneSettings is not on one.
    r = s.call(
        "scene.set_component",
        Json::object({{"id", "hero"}, {"component", "SceneSettings"}, {"fields", Json::object({{"fogDensity", 1}})}}));
    CHECK(!r.ok);
    CHECK(s.values() == before);
}

TEST_CASE("patch_settings is all or nothing") {
    Session s;
    const Json before = s.values();
    Result<void> bad = patch_settings(s.world(), Json::object({{"fogDensity", 0.4}, {"nonsense", 1}}));
    CHECK(!bad.ok());
    CHECK(s.values() == before);
    Result<void> good = patch_settings(s.world(), Json::object({{"fogDensity", 0.4}}));
    CHECK(good.ok());
    CHECK(s.values()["fogDensity"].get<double>() == doctest::Approx(0.4));
    CHECK(!patch_settings(s.world(), Json::array()).ok());
}

TEST_CASE("undo plan of SceneSettings: the inverse puts back exactly the fields the call named") {
    Session s;
    const Json args = settings_edit_args("skyMaterial", "materials/a.material.json");
    const std::optional<UndoPlan> plan = plan_undo(s.world(), "scene.set_component", args);
    REQUIRE(plan.has_value());
    REQUIRE(plan->forward.size() == 1);
    REQUIRE(plan->inverse.size() == 1);
    CHECK(!plan->forward[0].target.empty());
    const Json before = s.values();
    for (const UndoCommand& c : plan->forward) REQUIRE(s.call(c.cmd, c.args).ok);
    const Json after = s.values();
    CHECK(after != before);
    for (const UndoCommand& c : plan->inverse) REQUIRE(s.call(c.cmd, c.args).ok);
    CHECK(s.values() == before);
    for (const UndoCommand& c : plan->forward) REQUIRE(s.call(c.cmd, c.args).ok);
    CHECK(s.values() == after);

    // Two edits of the same field share a target (they coalesce into one step); another field does not.
    const std::optional<UndoPlan> again = plan_undo(s.world(), "scene.set_component", args);
    const std::optional<UndoPlan> other =
        plan_undo(s.world(), "scene.set_component", settings_edit_args("fogDensity", 0.5));
    REQUIRE(again.has_value());
    REQUIRE(other.has_value());
    CHECK(again->forward[0].target == plan->forward[0].target);
    CHECK(other->forward[0].target != plan->forward[0].target);

    // A merged params edit is undone to the whole object it had.
    REQUIRE(s.call("scene.set_component", settings_edit_args("skyMaterialParams", Json::object({{"a", 1}}), true)).ok);
    const Json withA = s.values();
    const std::optional<UndoPlan> merged = plan_undo(
        s.world(), "scene.set_component", settings_edit_args("skyMaterialParams", Json::object({{"b", 2}}), true));
    REQUIRE(merged.has_value());
    for (const UndoCommand& c : merged->forward) REQUIRE(s.call(c.cmd, c.args).ok);
    CHECK(s.world().settings().skyMaterialParams == Json::object({{"a", 1}, {"b", 2}}));
    for (const UndoCommand& c : merged->inverse) REQUIRE(s.call(c.cmd, c.args).ok);
    CHECK(s.values() == withA);

    // Arguments the command would refuse give no plan: the editor then takes a snapshot and the command reports the
    // error.
    CHECK(!plan_undo(s.world(), "scene.set_component", settings_edit_args("nonsense", 1)).has_value());
}
