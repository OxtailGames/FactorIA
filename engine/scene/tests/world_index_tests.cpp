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

TEST_CASE("world index: `persistent` names the scene of what stays loaded, is written back and is checked") {
    auto r = parse_world_index(index_json(kCellA, R"("persistent":"worlds/town_persistent.scene.json",)"),
                               "worlds/test.world.json", no_files());
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : all_text(r)));
    CHECK(r.value().persistent == "worlds/town_persistent.scene.json");
    const Json back = world_index_to_json(r.value());
    CHECK(back["persistent"] == "worlds/town_persistent.scene.json");
    CHECK(back.dump().find("persistent") < back.dump().find("cells"));
    // without it the key is not written
    auto none = parse_world_index(index_json(kCellA), "worlds/test.world.json", no_files());
    REQUIRE(none.ok());
    CHECK(none.value().persistent.empty());
    CHECK_FALSE(world_index_to_json(none.value()).contains("persistent"));
    // a wrong value has a pointer
    auto bad = parse_world_index(index_json(kCellA, R"("persistent":5,)"), "worlds/test.world.json", no_files());
    REQUIRE_FALSE(bad.ok());
    CHECK(all_text(bad).find("/persistent") != std::string::npos);
    auto escape = parse_world_index(index_json(kCellA, R"("persistent":"../x.scene.json",)"), "worlds/test.world.json",
                                    no_files());
    REQUIRE_FALSE(escape.ok());
    CHECK(all_text(escape).find("/persistent") != std::string::npos);
}

namespace {

std::string cell_with_hlod(const std::string& hlod) {
    return R"({"coord":[1,0],"scene":"cells/1_0.scene.json","bounds":{"min":[0,0,0],"max":[100,10,100]},"hlod":)" +
           hlod + "}";
}

}  // namespace

TEST_CASE("world index: a cell's hlod proxy is read, written back in the canonical order and found by its corner") {
    auto r = parse_world_index(index_json(cell_with_hlod(R"({"mesh":"hlod/1_0.glb","maxDistance":900})")),
                               "worlds/test.world.json", no_files());
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : all_text(r)));
    const WorldCell& c = r.value().cells.at(0);
    CHECK(c.hlod == "hlod/1_0.glb");
    CHECK(c.hlodMaxDistance == 900.0);
    // the corner of cell [1, 0] of an index with origin [-100, 0] and cells of 100: x 0, z 0, height 0
    const DVec3 corner = world_cell_corner(r.value(), c);
    CHECK(corner.x == 0.0);
    CHECK(corner.y == 0.0);
    CHECK(corner.z == 0.0);
    // a round trip keeps the proxy; maxDistance is written only when above 0
    const Json back = world_index_to_json(r.value());
    CHECK(back["cells"][0]["hlod"]["mesh"] == "hlod/1_0.glb");
    CHECK(back["cells"][0]["hlod"]["maxDistance"] == 900.0);
    CHECK(back["cells"][0].dump().find("hlod") > back["cells"][0].dump().find("bounds"));
    auto again = parse_world_index(back, "worlds/test.world.json", no_files());
    REQUIRE(again.ok());
    CHECK(world_index_to_json(again.value()) == back);
    auto plain = parse_world_index(index_json(cell_with_hlod(R"({"mesh":"hlod/1_0.glb"})")), "worlds/test.world.json",
                                   no_files());
    REQUIRE(plain.ok());
    CHECK(plain.value().cells[0].hlodMaxDistance == 0.0);
    CHECK_FALSE(world_index_to_json(plain.value())["cells"][0]["hlod"].contains("maxDistance"));
    // a cell without one writes no "hlod" key
    auto none = parse_world_index(index_json(kCellB), "worlds/test.world.json", no_files());
    REQUIRE(none.ok());
    CHECK(none.value().cells[0].hlod.empty());
    CHECK_FALSE(world_index_to_json(none.value())["cells"][0].contains("hlod"));
    // the corner of a 2d cell is on XY
    auto flat = parse_json(
        R"({"format":"factoria.world/1","version":1,"dimension":"2d","cellSize":64,"origin":[10,20],"cells":[
            {"coord":[2,3],"scene":"c.scene.json","bounds":{"min":[138,212],"max":[190,260]}}]})",
        "test");
    auto flatIndex = parse_world_index(flat.value(), "w.world.json", no_files());
    REQUIRE_MESSAGE(flatIndex.ok(), (flatIndex.ok() ? std::string() : all_text(flatIndex)));
    const DVec3 c2 = world_cell_corner(flatIndex.value(), flatIndex.value().cells[0]);
    CHECK(c2.x == 138.0);
    CHECK(c2.y == 212.0);
    CHECK(c2.z == 0.0);
}

TEST_CASE("world index: a wrong hlod entry is an error with its JSON pointer and a hint") {
    struct Bad {
        const char* hlod;
        const char* pointer;
    };
    const Bad bad[] = {{R"("hlod/1_0.glb")", "/cells/0/hlod"},
                       {R"({})", "/cells/0/hlod/mesh"},
                       {R"({"mesh":5})", "/cells/0/hlod/mesh"},
                       {R"({"mesh":""})", "/cells/0/hlod/mesh"},
                       {R"({"mesh":"hlod/1_0.png"})", "/cells/0/hlod/mesh"},
                       {R"({"mesh":"../outside.glb"})", "/cells/0/hlod/mesh"},
                       {R"({"mesh":"a.glb","maxDistance":-1})", "/cells/0/hlod/maxDistance"},
                       {R"({"mesh":"a.glb","maxDistance":"far"})", "/cells/0/hlod/maxDistance"}};
    for (const Bad& b : bad) {
        INFO(b.hlod);
        auto r = parse_world_index(index_json(cell_with_hlod(b.hlod)), "worlds/test.world.json", no_files());
        REQUIRE_FALSE(r.ok());
        CHECK(all_text(r).find(b.pointer) != std::string::npos);
        CHECK_FALSE(r.error().hint.empty());
    }
    // an unknown key is a warning with a suggestion, not an error
    std::vector<WorldIndexIssue> issues;
    auto typo = parse_world_index(index_json(cell_with_hlod(R"({"mesh":"a.glb","maxDistence":5})")),
                                  "worlds/test.world.json", no_files(), &issues);
    REQUIRE(typo.ok());
    bool warned = false;
    for (const WorldIndexIssue& i : issues)
        if (!i.error && i.pointer == "/cells/0/hlod/maxDistence" && i.hint.find("maxDistance") != std::string::npos)
            warned = true;
    CHECK(warned);
}

TEST_CASE("world index: a missing proxy file is a warning that names the cell and suggests the files that exist") {
    // Only the shape of the message is checked: the files of the process's project are not the ones the index names.
    std::vector<WorldIndexIssue> issues;
    WorldIndexOptions files;
    files.checkFiles = true;
    auto r = parse_world_index(index_json(cell_with_hlod(R"({"mesh":"no_such_folder/1_0.glb"})")),
                               "worlds/test.world.json", files, &issues);
    bool proxyWarning = false;
    for (const WorldIndexIssue& i : issues)
        if (i.pointer == "/cells/0/hlod/mesh") {
            proxyWarning = true;
            CHECK_FALSE(i.error);
            CHECK(i.message.find("[1,0]") != std::string::npos);
            CHECK(i.message.find("no_such_folder/1_0.glb") != std::string::npos);
        }
    CHECK(proxyWarning);  // the scene file is missing too (an error), but the proxy is reported on its own
    (void)r;
}
