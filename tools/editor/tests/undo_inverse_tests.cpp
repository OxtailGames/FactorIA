// The inverse builders of the editor's Command undo entries (undo_inverse.h), against a real headless Engine in a temporary
// project: the forward call, then the inverse, gives back the scene JSON exactly. GPU-free.
#include <filesystem>
#include <fstream>

#include "doctest.h"
#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/scene/serialize.h"
#include "undo_inverse.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Undo Inverse Test",
  "id": "com.example.undoinverse",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "hero", "name": "Hero", "tags": ["player"],
      "components": { "Transform": { "position": [10, 20, 0] }, "Shape2D": { "size": [30, 20], "color": "#cc3030" },
                      "Script": { "props": { "speed": 3, "label": "x" } } } },
    { "id": "target", "name": "Target", "components": { "Transform": { "position": [50, 0, 0] } } }
  ]
})";

struct Session {
    stdfs::path dir;
    Engine engine;
    Session() {
        dir = fs::make_temp_dir("fa_undo_inverse").value();
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
    Json scene() { return snapshot_scene(world()); }
    bool run(const std::vector<UndoCommand>& cmds) {
        for (const UndoCommand& c : cmds)
            if (!engine.commands().call(c.cmd, c.args).ok) return false;
        return true;
    }
    // Plans `name(args)`, applies the forward commands, and checks that the inverse gives the scene back and the forward
    // again gives the edited scene.
    void round_trip(const std::string& name, const Json& args, bool expectChange = true) {
        INFO(name << " " << args.dump());
        const Json before = scene();
        const std::optional<UndoPlan> plan = plan_undo(world(), name, args);
        REQUIRE(plan.has_value());
        REQUIRE(run(plan->forward));
        const Json after = scene();
        if (expectChange) CHECK(after != before);
        REQUIRE(run(plan->inverse));
        CHECK(scene() == before);
        REQUIRE(run(plan->forward));
        CHECK(scene() == after);
        REQUIRE(run(plan->inverse));
        CHECK(scene() == before);
    }
};

Json set_args(const std::string& id, const std::string& component, Json fields, bool merge = false) {
    Json a = Json::object({{"id", id}, {"component", component}, {"fields", std::move(fields)}});
    if (merge) a["merge"] = true;
    return a;
}

}  // namespace

TEST_CASE("undo inverse: set_component of a field gives the old value back") {
    Session s;
    s.round_trip("scene.set_component", set_args("hero", "Transform", Json::object({{"position", Json::array({1, 2, 3})}})));
    s.round_trip("scene.set_component", set_args("hero", "Shape2D", Json::object({{"color", "#00ff00"}, {"shape", "circle"}})));
    s.round_trip("scene.set_component", set_args("hero", "EntityInfo", Json::object({{"name", "Renamed"}, {"active", false}})));
    s.round_trip("scene.set_component", set_args("hero", "EntityInfo", Json::object({{"tags", Json::array({"a", "b"})}})));
    // the entity named by its display name: the plan spells the id out
    const auto plan = plan_undo(s.world(), "scene.set_component",
                                set_args("Hero", "Transform", Json::object({{"position", Json::array({1, 1, 1})}})));
    REQUIRE(plan.has_value());
    CHECK(plan->forward[0].args["id"] == "hero");
    CHECK(plan->inverse[0].args["id"] == "hero");
    // the inverse holds exactly the fields the call names
    CHECK(plan->inverse[0].args["fields"].size() == 1);
    CHECK(plan->inverse[0].args["fields"]["position"] == Json::array({10, 20, 0}));
}

TEST_CASE("undo inverse: set_component with merge restores a Json field as a whole") {
    Session s;
    s.round_trip("scene.set_component",
                 set_args("hero", "Script", Json::object({{"props", Json::object({{"speed", 9}, {"label", nullptr}})}}), true));
    s.round_trip("scene.set_component", set_args("hero", "Script", Json::object({{"props", Json::object({{"extra", 1}})}})));
}

TEST_CASE("undo inverse: a component that was absent is removed again, and a removed one comes back whole") {
    Session s;
    const Json add = set_args("target", "Shape2D", Json::object({{"size", Json::array({8, 9})}}));
    const auto plan = plan_undo(s.world(), "scene.set_component", add);
    REQUIRE(plan.has_value());
    CHECK(plan->inverse[0].cmd == "scene.remove_component");
    s.round_trip("scene.set_component", add);
    s.round_trip("scene.set_component", set_args("target", "Light", Json::object()));
    const Json remove = Json::object({{"id", "hero"}, {"component", "Shape2D"}});
    s.round_trip("scene.remove_component", remove);
    s.round_trip("scene.remove_component", Json::object({{"id", "hero"}, {"component", "Script"}}));
    const auto rm = plan_undo(s.world(), "scene.remove_component", remove);
    REQUIRE(rm.has_value());
    CHECK(rm->inverse[0].cmd == "scene.set_component");
    CHECK(rm->inverse[0].args["fields"].contains("color"));
}

TEST_CASE("undo inverse: a call that is wrong, or has no builder, gives no plan") {
    Session s;
    CHECK_FALSE(plan_undo(s.world(), "scene.set_component", set_args("nobody", "Transform", Json::object())).has_value());
    CHECK_FALSE(plan_undo(s.world(), "scene.set_component", set_args("hero", "NoSuchComponent", Json::object())).has_value());
    CHECK_FALSE(plan_undo(s.world(), "scene.set_component", set_args("hero", "Transform", Json::object({{"nope", 1}}))).has_value());
    CHECK_FALSE(plan_undo(s.world(), "scene.set_component", set_args("hero", "EntityInfo", Json::object({{"id", "other"}}))).has_value());
    CHECK_FALSE(plan_undo(s.world(), "scene.remove_component", Json::object({{"id", "hero"}, {"component", "Transform"}})).has_value());
    CHECK_FALSE(plan_undo(s.world(), "scene.remove_component", Json::object({{"id", "hero"}, {"component", "Light"}})).has_value());
    CHECK_FALSE(plan_undo(s.world(), "scene.spawn", Json::object()).has_value());
    CHECK(has_undo_builder("scene.set_component"));
    CHECK(has_undo_builder("scene.remove_component"));
    CHECK_FALSE(has_undo_builder("scene.spawn"));
}

TEST_CASE("undo inverse: the forward command carries a target that names what it sets") {
    Session s;
    const auto a = plan_undo(s.world(), "scene.set_component",
                             set_args("hero", "Transform", Json::object({{"position", Json::array({1, 2, 3})}})));
    const auto b = plan_undo(s.world(), "scene.set_component",
                             set_args("Hero", "Transform", Json::object({{"position", Json::array({4, 5, 6})}})));
    const auto c = plan_undo(s.world(), "scene.set_component",
                             set_args("hero", "Transform", Json::object({{"scale", Json::array({2, 2, 2})}})));
    const auto d = plan_undo(s.world(), "scene.set_component",
                             set_args("target", "Transform", Json::object({{"position", Json::array({4, 5, 6})}})));
    REQUIRE((a && b && c && d));
    CHECK_FALSE(a->forward[0].target.empty());
    CHECK(a->forward[0].target == b->forward[0].target);
    CHECK(a->forward[0].target != c->forward[0].target);
    CHECK(a->forward[0].target != d->forward[0].target);
}

TEST_CASE("undo inverse: 100 plans cost far less than one snapshot of a big scene") {
    Session s;
    // a scene as big as a real level: a thousand entities with a few components each
    for (int i = 0; i < 1000; ++i)
        REQUIRE(s.engine.commands()
                    .call("scene.spawn",
                          Json::object({{"name", "e" + std::to_string(i)},
                                        {"components",
                                         Json::object({{"Transform", Json::object({{"position", Json::array({i, 5, 0})}})},
                                                       {"Shape2D", Json::object({{"size", Json::array({8, 9})},
                                                                                 {"color", "#336699"}}) },
                                                       {"Script", Json::object({{"props", Json::object({{"speed", 3},
                                                                                                        {"label", "enemy"}})}})}})}}))
                    .ok);
    const size_t sceneBytes = estimate_json_bytes(s.scene());
    UndoStack st;
    for (int i = 0; i < 100; ++i) {
        const Json args = set_args("e" + std::to_string(i), "Transform", Json::object({{"position", Json::array({i, 0, 0})}}));
        std::optional<UndoPlan> plan = plan_undo(s.world(), "scene.set_component", args);
        REQUIRE(plan.has_value());
        st.push_command(std::move(plan->forward), std::move(plan->inverse), false);
    }
    CHECK(st.size() == 100);
    INFO(st.bytes() << " bytes of 100 entries against " << sceneBytes << " of one snapshot");
    CHECK(st.bytes() * 4 < sceneBytes);
}
