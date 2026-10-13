// Unit tests for the editor's GPU-free pieces. The windowed end-to-end test is
// fa_editor_autotest (ctest label "gpu").
#include <atomic>
#include <chrono>
#include <thread>

#include "doctest.h"
#include "editor_internal.h"

using namespace fa;
using namespace fa::editor;

TEST_CASE("asset type matching") {
    CHECK(asset_matches("texture", "assets/hero.PNG"));
    CHECK_FALSE(asset_matches("texture", "assets/hero.wav"));
    CHECK(asset_matches("audio", "sfx/jump.ogg"));
    CHECK(asset_matches("scene", "scenes/main.scene.json"));
    CHECK_FALSE(asset_matches("scene", "factoria.json"));
    CHECK(asset_matches("prefab", "prefabs/a.prefab.json"));
    CHECK(asset_matches("any", "whatever.bin"));
}

TEST_CASE("case-insensitive filter") {
    CHECK(contains_ci("Main Camera", "cam"));
    CHECK(contains_ci("Main Camera", ""));
    CHECK_FALSE(contains_ci("Player", "enemy"));
}

TEST_CASE("MainThreadQueue runs worker-thread calls on the pumping thread") {
    MainThreadQueue q;
    std::atomic<bool> done{false};
    CommandResult result;
    std::thread::id workerId, runId;
    std::thread worker([&] {
        workerId = std::this_thread::get_id();
        result = q.call("x.y", Json::object({{"a", 1}}), nullptr);
        done = true;
    });
    int ran = 0;
    for (int i = 0; i < 400 && !done; ++i) {
        ran += q.pump([&](const std::string& name, const Json& args) {
            runId = std::this_thread::get_id();
            CommandResult r;
            r.ok = true;
            r.result = Json::object({{"name", name}, {"a", args.value("a", 0)}});
            return r;
        });
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
    worker.join();
    CHECK(ran == 1);
    CHECK(result.ok);
    CHECK(result.result["name"] == "x.y");
    CHECK(result.result["a"] == 1);
    CHECK(runId == std::this_thread::get_id());
    CHECK(runId != workerId);
}

TEST_CASE("MainThreadQueue fails pending calls when closed or cancelled") {
    MainThreadQueue q;
    std::atomic<bool> cancel{false};
    CommandResult r1, r2;
    std::thread t1([&] { r1 = q.call("a.b", Json::object(), &cancel); });
    std::this_thread::sleep_for(std::chrono::milliseconds(60));
    cancel = true;
    t1.join();
    CHECK_FALSE(r1.ok);
    std::thread t2([&] { r2 = q.call("a.b", Json::object(), nullptr); });
    std::this_thread::sleep_for(std::chrono::milliseconds(60));
    q.close();
    t2.join();
    CHECK_FALSE(r2.ok);
    CommandResult r3 = q.call("a.b", Json::object(), nullptr);  // closed queue rejects immediately
    CHECK_FALSE(r3.ok);
    CHECK(r3.error["code"] == "unavailable");
}

TEST_CASE("commands that only write files do not count as scene edits") {
    Editor ed{EditorOptions{}};
    CHECK_FALSE(ed.command_edits_scene("prefab.save", Json::object()));
    CHECK_FALSE(ed.command_edits_scene("scene.format", Json::object()));
    CHECK_FALSE(ed.command_edits_scene("scene.import_ascii", Json::parse(R"({"path":"scenes/x.scene.json","rows":["#"],"legend":{"#":0}})")));
    CHECK(ed.command_edits_scene("scene.import_ascii", Json::parse(R"({"rows":["#"],"legend":{"#":0}})")));  // the running world
    CHECK(ed.command_edits_scene("scene.spawn", Json::object()));
    CHECK(ed.command_edits_scene("scene.set_component", Json::object()));
}

// The inspector is reflection-driven: what it shows and allows is what these registrations declare.
TEST_CASE("inspector fields: Camera bloom, Shape2D diamond and Tilemap columns have docs, ranges and defaults the editor can use") {
    World w;  // registers the built-in components
    const TypeInfo* cam = TypeRegistry::global().find("Camera");
    REQUIRE(cam);
    auto field = [](const TypeInfo& t, const char* name) -> const FieldInfo& {
        for (const FieldInfo& f : t.fields)
            if (f.name == name) return f;
        FAIL("no field " << name << " on " << t.name);
        return t.fields.front();
    };
    CHECK(field(*cam, "bloom").kind == FieldKind::Bool);
    const FieldInfo& threshold = field(*cam, "bloomThreshold");
    const FieldInfo& intensity = field(*cam, "bloomIntensity");
    const FieldInfo& radius = field(*cam, "bloomRadius");
    CHECK(threshold.kind == FieldKind::Float);
    CHECK(threshold.minValue == 0.0f);
    CHECK(threshold.maxValue == 1.0f);
    CHECK(intensity.minValue == 0.0f);
    CHECK(intensity.maxValue == 10.0f);
    CHECK(radius.minValue == 1.0f);
    CHECK(radius.maxValue == 128.0f);
    CHECK(field(*cam, "bloomScreenSpace").kind == FieldKind::Bool);
    for (const char* n : {"bloom", "bloomThreshold", "bloomIntensity", "bloomRadius", "bloomScreenSpace"}) {
        CAPTURE(n);
        CHECK(field(*cam, n).doc.size() > 40);  // the doc string is the tooltip
    }
    // The fields that only matter while bloom is on know their switch; the switch and unrelated fields do not.
    CHECK(inspector_switch_field(*cam, threshold) == &field(*cam, "bloom"));
    CHECK(inspector_switch_field(*cam, intensity) == &field(*cam, "bloom"));
    CHECK(inspector_switch_field(*cam, radius) == &field(*cam, "bloom"));
    CHECK(inspector_switch_field(*cam, field(*cam, "bloomScreenSpace")) == &field(*cam, "bloom"));
    CHECK(inspector_switch_field(*cam, field(*cam, "bloom")) == nullptr);
    CHECK(inspector_switch_field(*cam, field(*cam, "fov")) == nullptr);

    const TypeInfo* shape = TypeRegistry::global().find("Shape2D");
    REQUIRE(shape);
    const FieldInfo& kind = field(*shape, "shape");
    CHECK(kind.kind == FieldKind::Enum);
    CHECK(std::find(kind.enumNames.begin(), kind.enumNames.end(), "diamond") != kind.enumNames.end());

    const TypeInfo* tilemap = TypeRegistry::global().find("Tilemap");
    REQUIRE(tilemap);
    const FieldInfo& columns = field(*tilemap, "columns");
    CHECK(columns.kind == FieldKind::Int);
    CHECK(columns.minValue == 0.0f);  // 0 = derived from the tileset image
    CHECK(columns.maxValue == 4096.0f);
    CHECK(columns.doc.find("0 (the default) derives") != std::string::npos);

    // Writing through the same call every inspector widget uses: in range works, out of range is refused with a teaching message
    // and leaves the value alone.
    Entity e = w.create("cam", "cam");
    REQUIRE(patch_component(w, e, *cam, Json::object({{"bloom", true}, {"bloomIntensity", 3.5}})).ok());
    CHECK(w.get<Camera>(e)->bloom);
    CHECK(w.get<Camera>(e)->bloomIntensity == doctest::Approx(3.5f));
    auto bad = patch_component(w, e, *cam, Json::object({{"bloomRadius", 500}}));
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().to_string().find("128") != std::string::npos);
    CHECK(w.get<Camera>(e)->bloomRadius == doctest::Approx(20.0f));
    REQUIRE(patch_component(w, e, *shape, Json::object({{"shape", "diamond"}})).ok());
    CHECK(w.get<Shape2D>(e)->shape == ShapeType::Diamond);
    REQUIRE(patch_component(w, e, *tilemap, Json::object({{"columns", 0}})).ok());
    CHECK_FALSE(patch_component(w, e, *tilemap, Json::object({{"columns", 5000}})).ok());
    CHECK(w.get<Tilemap>(e)->columns == 0);
}
