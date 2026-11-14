// Array fields (FieldKind::ArrayI32 / ArrayF32 / ArrayU8) in a scene: the state hash, save and load.
#include <doctest.h>

#include <vector>

#include "fa/core/reflect.h"
#include "fa/scene/components.h"
#include "fa/scene/serialize.h"
#include "fa/scene/state_hash.h"
#include "fa/scene/world.h"

using namespace fa;

namespace {
struct SceneArrays {
    ArrayI32 cells;
    ArrayF32 weights;
    ArrayU8 flags;
};

// A test-only component (the real components do not use array fields yet).
const TypeInfo& scene_arrays_type() {
    static const TypeInfo* t = [] {
        ensure_builtin_components();
        auto& reg = TypeRegistry::global();
        if (!reg.of<SceneArrays>()) {
            reg.add<SceneArrays>("TestSceneArrays", "A test component with array fields.", "Test")
                .field("cells", &SceneArrays::cells, "Cells.")
                .field("weights", &SceneArrays::weights, "Weights.")
                .field("flags", &SceneArrays::flags, "Flags.");
        }
        return reg.of<SceneArrays>();
    }();
    return *t;
}

void fill_world(World& w, const std::vector<std::int32_t>& cells, const std::vector<std::uint8_t>& flags) {
    scene_arrays_type();
    const Entity e = w.create("map", "map");
    auto& a = w.add<SceneArrays>(e);
    a.cells.assign(cells.data(), cells.size());
    a.flags.assign(flags.data(), flags.size());
}

SceneArrays& arrays_of(World& w) { return *w.get<SceneArrays>(w.find_by_id("map")); }
}  // namespace

TEST_CASE("typed arrays: the state hash covers every element and the length") {
    World a, b, shorter, bytes;
    fill_world(a, {1, 2, 3}, {4, 5});
    fill_world(b, {1, 2, 3}, {4, 5});
    CHECK(world_state_hash(a).hash == world_state_hash(b).hash);

    arrays_of(b).cells.set(2, 4);
    CHECK(world_state_hash(a).hash != world_state_hash(b).hash);
    arrays_of(b).cells.set(2, 3);
    CHECK(world_state_hash(a).hash == world_state_hash(b).hash);

    fill_world(shorter, {1, 2}, {4, 5});
    CHECK(world_state_hash(a).hash != world_state_hash(shorter).hash);
    fill_world(bytes, {1, 2, 3}, {4, 6});
    CHECK(world_state_hash(a).hash != world_state_hash(bytes).hash);
    arrays_of(b).weights.push_back(0.25f);  // a float element
    CHECK(world_state_hash(a).hash != world_state_hash(b).hash);
}

TEST_CASE("typed arrays: save_scene writes a flat array and load_scene reads it back") {
    World a;
    fill_world(a, {7, -1, 300}, {0, 255});
    arrays_of(a).weights.push_back(1.5f);
    const Json scene = save_scene(a);
    bool found = false;
    for (const Json& e : scene["entities"])
        if (e.value("id", "") == "map") {
            found = true;
            CHECK(e["components"]["TestSceneArrays"]["cells"] == Json::parse("[7, -1, 300]"));
            CHECK(e["components"]["TestSceneArrays"]["flags"] == Json::parse("[0, 255]"));
            CHECK(e["components"]["TestSceneArrays"]["weights"] == Json::parse("[1.5]"));
        }
    REQUIRE(found);

    World b;
    const LoadReport r = load_scene(b, scene, "test");
    CHECK(r.ok());
    REQUIRE(b.get<SceneArrays>(b.find_by_id("map")));
    CHECK(arrays_of(b).cells == arrays_of(a).cells);
    CHECK(arrays_of(b).flags == arrays_of(a).flags);
    CHECK(world_state_hash(a).hash == world_state_hash(b).hash);
}

TEST_CASE("typed arrays: a bad element in a scene file is reported with its element") {
    scene_arrays_type();
    World w;
    const Json scene = Json::parse(R"({"format":"factoria.scene/1","entities":[
        {"id":"map","components":{"TestSceneArrays":{"flags":[1, 2, 300]}}}]})");
    const LoadReport r = load_scene(w, scene, "test");
    bool named = false;
    for (const auto& m : r.messages)
        if (m.message.find("element 2 is 300") != std::string::npos) named = true;
    CHECK(named);
}
