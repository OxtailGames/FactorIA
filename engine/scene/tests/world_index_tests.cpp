// M75.3: the index of a streamed world (<name>.world.json): reading, the geometry helpers and the errors that teach.
#include <doctest.h>

#include <string>
#include <vector>

#include "fa/scene/components.h"
#include "fa/scene/serialize.h"
#include "fa/scene/world.h"
#include "fa/scene/world_index.h"

using namespace fa;

namespace {

Json index_json(const std::string& cells, const std::string& extra = "") {
    const std::string text =
        R"({"format":"factoria.world/1","version":1,"dimension":"3d","cellSize":100,"origin":[-100,0],)" + extra +
        R"("cells":[)" + cells + "]}";
    return parse_json(text, "test").value();
}

const char* kCellA =
    R"({"coord":[0,0],"scene":"cells/0_0.scene.json","bounds":{"min":[-100,0,0],"max":[0,10,100]},"sizeBytes":1234})";
const char* kCellB = R"({"coord":[1,0],"scene":"cells/1_0.scene.json","bounds":{"min":[0,0,0],"max":[100,10,100]}})";
const char* kCellC = R"({"coord":[0,-1],"scene":"cells/0_-1.scene.json","bounds":{"min":[-100,0,-100],"max":[0,5,0]}})";

WorldIndexOptions no_files() {
    WorldIndexOptions o;
    o.checkFiles = false;
    return o;
}

std::string all_text(const Result<WorldIndex>& r) { return r.error().message + "\n" + r.error().hint; }

}  // namespace

TEST_CASE("world index: a valid index is read, sorted by (j, i), and answers distances on the plane") {
    const std::string cells = std::string(kCellB) + "," + kCellA + "," + kCellC;
    auto r = parse_world_index(index_json(cells), "worlds/test.world.json", no_files());
    REQUIRE_MESSAGE(r.ok(), all_text(r));
    const WorldIndex& w = *r;
    CHECK(w.path == "worlds/test.world.json");
    CHECK(w.dimension == WorldDimension::D3);
    CHECK(w.cellSize == 100.0);
    CHECK(w.originA == -100.0);
    REQUIRE(w.cells.size() == 3);
    CHECK(w.cells[0].id() == "0,-1");  // sorted by (j, i): j -1 first
    CHECK(w.cells[1].id() == "0,0");
    CHECK(w.cells[2].id() == "1,0");
    CHECK(w.cells[1].sizeBytes == 1234);
    CHECK(w.cells[2].sizeBytes == -1);
    REQUIRE(w.find(1, 0) != nullptr);
    CHECK(w.find(5, 5) == nullptr);
    // cell [0, 0] covers x in [-100, 0], z in [0, 100]
    const WorldCell& c = *w.find(0, 0);
    CHECK(w.distance_to(c, -50, 50) == 0.0);
    CHECK(w.distance_to(c, 30, 50) == doctest::Approx(30.0));
    CHECK(w.distance_to(c, 30, 140) == doctest::Approx(50.0));  // 30 along x and 40 along z
    std::int64_t i = 99, j = 99;
    w.cell_of(-50, 50, i, j);
    CHECK(i == 0);
    CHECK(j == 0);
    w.cell_of(0.0, -0.5, i, j);
    CHECK(i == 1);
    CHECK(j == -1);
    // written back and read again: the same index
    auto again = parse_world_index(world_index_to_json(w), "again", no_files());
    REQUIRE_MESSAGE(again.ok(), all_text(again));
    REQUIRE(again->cells.size() == 3);
    CHECK(again->cells[2].scene == "cells/1_0.scene.json");
    CHECK(again->originA == -100.0);
}

TEST_CASE("world index: a 2d index puts the cells on XY and its bounds have two numbers") {
    const std::string text =
        R"({"format":"factoria.world/1","version":1,"dimension":"2d","cellSize":50,"origin":[0,0],"cells":[
        {"coord":[2,1],"scene":"cells/2_1.scene.json","bounds":{"min":[100,50],"max":[150,100]}}]})";
    auto r = parse_world_index(parse_json(text, "t").value(), "w2d", no_files());
    REQUIRE_MESSAGE(r.ok(), all_text(r));
    CHECK(r->dimension == WorldDimension::D2);
    const WorldCell& c = r->cells[0];
    CHECK(c.boundsMin.x == 100.0f);
    CHECK(c.boundsMin.y == 50.0f);
    CHECK(r->distance_to(c, 90, 50) == doctest::Approx(10.0));
    CHECK(r->distance_to(c, 120, 120) == doctest::Approx(20.0));
    // three numbers in a 2d index is a mistake that says which dimension asked for two
    const std::string bad =
        R"({"format":"factoria.world/1","version":1,"dimension":"2d","cellSize":50,"origin":[0,0],"cells":[
        {"coord":[0,0],"scene":"c.scene.json","bounds":{"min":[0,0,0],"max":[50,50,50]}}]})";
    auto rb = parse_world_index(parse_json(bad, "t").value(), "w2d", no_files());
    REQUIRE_FALSE(rb.ok());
    CHECK(all_text(rb).find("/cells/0/bounds/min") != std::string::npos);
}

TEST_CASE("world index: duplicate coordinates name both entries, with their JSON pointers") {
    const std::string cells = std::string(kCellA) + "," + kCellB + "," + kCellA;
    auto r = parse_world_index(index_json(cells), "worlds/dup.world.json", no_files());
    REQUIRE_FALSE(r.ok());
    const std::string text = all_text(r);
    CHECK(text.find("worlds/dup.world.json#/cells/2/coord") != std::string::npos);
    CHECK(text.find("[0, 0] is listed twice") != std::string::npos);
    CHECK(text.find("/cells/0") != std::string::npos);
    CHECK_FALSE(r.error().hint.empty());
}

TEST_CASE("world index: bounds that stick out of their cell say which axis and what the cell covers") {
    const char* wide =
        R"({"coord":[0,0],"scene":"cells/0_0.scene.json","bounds":{"min":[-100,0,0],"max":[40,10,100]}})";
    auto r = parse_world_index(index_json(wide), "w", no_files());
    REQUIRE_FALSE(r.ok());
    const std::string text = all_text(r);
    CHECK(text.find("#/cells/0/bounds") != std::string::npos);
    CHECK(text.find("outside the cell [0, 0]") != std::string::npos);
    CHECK(text.find("[-100, 0]") != std::string::npos);  // what the cell covers on x
    // a bound that touches the edge exactly is fine
    CHECK(parse_world_index(index_json(kCellA), "w", no_files()).ok());
}

TEST_CASE("world index: every problem has a pointer; the message lists a few and counts the rest") {
    auto notObject = parse_world_index(parse_json("[1,2]", "t").value(), "w", no_files());
    REQUIRE_FALSE(notObject.ok());
    CHECK(all_text(notObject).find("JSON object") != std::string::npos);

    auto badVersion = parse_world_index(
        parse_json(
            R"({"format":"factoria.world/1","version":2,"dimension":"3d","cellSize":100,"origin":[0,0],"cells":[]})",
            "t")
            .value(),
        "w", no_files());
    REQUIRE_FALSE(badVersion.ok());
    CHECK(all_text(badVersion).find("#/version") != std::string::npos);

    auto badDim = parse_world_index(
        parse_json(
            R"({"format":"factoria.world/1","version":1,"dimension":"4d","cellSize":100,"origin":[0,0],"cells":[]})",
            "t")
            .value(),
        "w", no_files());
    REQUIRE_FALSE(badDim.ok());
    CHECK(all_text(badDim).find("\"3d\" or \"2d\"") != std::string::npos);

    auto badSize = parse_world_index(
        parse_json(
            R"({"format":"factoria.world/1","version":1,"dimension":"3d","cellSize":0,"origin":[0,0],"cells":[]})", "t")
            .value(),
        "w", no_files());
    REQUIRE_FALSE(badSize.ok());
    CHECK(all_text(badSize).find("#/cellSize") != std::string::npos);

    // twelve cells without a scene: the first eight are listed, then "and N more"
    std::string many;
    for (int n = 0; n < 12; ++n) {
        if (n) many += ",";
        many += R"({"coord":[)" + std::to_string(n) + R"(,0],"bounds":{"min":[0,0,0],"max":[1,1,1]}})";
    }
    auto r = parse_world_index(index_json(many, ""), "w", no_files());
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("/cells/0/scene") != std::string::npos);
    CHECK(r.error().message.find(" more") != std::string::npos);
}

TEST_CASE("world index: warnings do not fail the read") {
    std::vector<WorldIndexIssue> issues;
    const std::string text =
        R"({"format":"factoria.world/9","version":1,"dimension":"3d","cellSize":100,"origin":[0,0],"colour":1,"cells":[
        {"coord":[0,0],"scene":"a.scene.json","bounds":{"min":[0,0,0],"max":[1,1,1]},"sise":3}]})";
    auto r = parse_world_index(parse_json(text, "t").value(), "w", no_files(), &issues);
    REQUIRE_MESSAGE(r.ok(), all_text(r));
    int warnings = 0;
    for (const WorldIndexIssue& is : issues) {
        CHECK_FALSE(is.error);
        CHECK(is.pointer.rfind("/", 0) == 0);
        ++warnings;
    }
    CHECK(warnings == 3);  // an unknown format, an unknown top-level key, an unknown cell key
}

TEST_CASE("streamed cells: a reference to an entity of another cell is a warning and stays empty; the main scene is "
          "reachable") {
    World world;
    auto load_cell = [&](const char* name, const char* text, LoadReport* out = nullptr) {
        const Entity root = world.create(name, name);
        world.info(root).streamedCell = true;
        SceneLoadOptions opts;
        opts.additive = true;
        opts.parent = root;
        opts.streamedCell = true;
        LoadReport r = load_scene(world, parse_json(text, name).value(), name, opts);
        if (out) *out = r;
        return root;
    };
    // an entity of the main scene (not in any cell)
    world.create("main body", "main_body");
    load_cell("cell_a", R"({"format":"factoria.scene/1","entities":[{"id":"body_a","components":{"Transform":{}}}]})");
    LoadReport report;
    const Entity rootB = load_cell("cell_b", R"({"format":"factoria.scene/1","entities":[
        {"id":"joint_b","components":{"Transform":{},"Joint3D":{"connected":"body_a"}}},
        {"id":"joint_c","components":{"Transform":{},"Joint3D":{"connected":"main_body"}}},
        {"id":"joint_d","components":{"Transform":{},"Joint3D":{"connected":"nobody_anywhere"}}}]})",
                                   &report);
    CHECK(report.ok());  // warnings, never errors: the cell still loads
    int warnings = 0;
    std::string text;
    for (const LoadMessage& m : report.messages) {
        if (m.severity == LoadMessage::Severity::Warning) ++warnings;
        text += m.to_string() + "\n";
    }
    CHECK(warnings == 2);
    CHECK(text.find("another streamed cell") != std::string::npos);
    CHECK(text.find("cellLoaded") != std::string::npos);  // the hint says what to do instead
    const Entity jb = world.find_by_id("joint_b");
    const Entity jc = world.find_by_id("joint_c");
    REQUIRE(world.alive(jb));
    REQUIRE(world.alive(jc));
    CHECK(world.get<Joint3D>(jb)->connected.is_null());
    CHECK(world.get<Joint3D>(jc)->connected == world.find_by_id("main_body"));
    CHECK(world.parent(jb) == rootB);
    // a cell is not part of the scene that is saved
    const Json saved = save_scene(world);
    CHECK(saved.dump().find("joint_b") == std::string::npos);
    CHECK(saved.dump().find("main_body") != std::string::npos);
}
