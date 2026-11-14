// Heightfield3D (the grid of heights of a 3D terrain collider) as a component: its fields, the scene file (plain arrays),
// and the state hash.
#include <doctest.h>

#include <string>
#include <vector>

#include "fa/core/reflect.h"
#include "fa/scene/components.h"
#include "fa/scene/serialize.h"
#include "fa/scene/state_hash.h"
#include "fa/scene/world.h"

using namespace fa;

namespace {
Entity add_grid(World& w) {
    ensure_builtin_components();
    const Entity e = w.create("terrain", "terrain");
    w.add<Collider3D>(e).shape = ColliderShape3D::Heightfield;
    Heightfield3D& g = w.add<Heightfield3D>(e);
    g.rows = 3;
    g.columns = 4;
    g.cellSize = {0.5f, 2.0f};
    g.heightScale = 2.0f;
    g.heightOffset = -1.0f;
    const std::vector<float> h = {0, 1, 2, 3, 0.5f, 1.5f, 2.5f, 3.5f, 1, 0, 1, 0};
    g.heights.assign(h.data(), h.size());
    const std::vector<std::uint8_t> holes = {0, 0, 1, 0, 1, 0};  // (3 - 1) * (4 - 1) = 6 cells
    g.holes.assign(holes.data(), holes.size());
    return e;
}
}  // namespace

TEST_CASE("Heightfield3D: every field is documented and the shape enum names the heightfield") {
    ensure_builtin_components();
    const TypeInfo* t = TypeRegistry::global().find("Heightfield3D");
    REQUIRE(t);
    CHECK(t->fields.size() == 7);
    for (const auto& f : t->fields) CHECK(!f.doc.empty());
    const TypeInfo* c = TypeRegistry::global().find("Collider3D");
    REQUIRE(c);
    bool listed = false;
    for (const auto& f : c->fields)
        if (f.name == "shape")
            for (const std::string& o : f.enumNames)
                if (o == "heightfield") listed = true;
    CHECK(listed);
}

TEST_CASE("Heightfield3D: save_scene writes plain arrays and load_scene reads the same field back") {
    World a;
    add_grid(a);
    const Json scene = save_scene(a);
    bool found = false;
    for (const Json& e : scene["entities"])
        if (e.value("id", "") == "terrain") {
            found = true;
            const Json& g = e["components"]["Heightfield3D"];
            CHECK(g["rows"] == 3);
            CHECK(g["columns"] == 4);
            CHECK(g["heights"].is_array());
            CHECK(g["heights"].size() == 12);
            CHECK(g["holes"] == Json::parse("[0, 0, 1, 0, 1, 0]"));
            CHECK(g["heights"][5] == 1.5);
        }
    REQUIRE(found);

    World b;
    const LoadReport r = load_scene(b, scene, "test");
    CHECK(r.ok());
    const Heightfield3D* g = b.get<Heightfield3D>(b.find_by_id("terrain"));
    REQUIRE(g);
    CHECK(g->rows == 3);
    CHECK(g->columns == 4);
    CHECK(g->cellSize.x == 0.5f);
    CHECK(g->cellSize.y == 2.0f);
    CHECK(g->heightScale == 2.0f);
    CHECK(g->heightOffset == -1.0f);
    CHECK(g->heights.size() == 12);
    CHECK(g->heights[11] == 0.0f);
    CHECK(g->holes.size() == 6);
    CHECK(world_state_hash(a).hash == world_state_hash(b).hash);
}

TEST_CASE("Heightfield3D: one changed height changes the state hash") {
    World a, b;
    const Entity ea = add_grid(a);
    add_grid(b);
    CHECK(world_state_hash(a).hash == world_state_hash(b).hash);
    a.get<Heightfield3D>(ea)->heights.set(7, 9.0f);
    CHECK(world_state_hash(a).hash != world_state_hash(b).hash);
}

TEST_CASE("Heightfield3D: a bad height or a bad hole in a scene file is reported with its element") {
    ensure_builtin_components();
    World w;
    const Json scene = Json::parse(R"({"format":"factoria.scene/1","entities":[
        {"id":"terrain","components":{"Heightfield3D":{"rows":2,"columns":2,"heights":[0, 0, "high", 0]}}}]})");
    const LoadReport r = load_scene(w, scene, "test");
    bool named = false;
    for (const auto& m : r.messages)
        if (m.message.find("element 2") != std::string::npos) named = true;
    CHECK(named);
}
