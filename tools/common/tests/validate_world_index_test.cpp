// project.validate: the world indexes (*.world.json, docs/BIG_WORLDS.md "Streaming") of the project.
#include <doctest.h>

#include <string>

#include "asset_test_helpers.h"
#include "fa/tooling/validate.h"

using namespace fa;
using namespace fa::testing;

namespace {

std::string index_text(const std::string& cells) {
    return R"({"format":"factoria.world/1","version":1,"dimension":"3d","cellSize":100,"origin":[0,0],"cells":[)" + cells + "]}";
}

const char* kCell00 = R"({"coord":[0,0],"scene":"cells/0_0.scene.json","bounds":{"min":[0,0,0],"max":[100,10,100]}})";
const char* kCell10 = R"({"coord":[1,0],"scene":"cells/1_0.scene.json","bounds":{"min":[100,0,0],"max":[200,10,100]}})";

std::vector<ValidationIssue> issues_of(const ValidationReport& r, const std::string& file) {
    std::vector<ValidationIssue> out;
    for (const ValidationIssue& e : r.errors)
        if (e.file == file) out.push_back(e);
    return out;
}

}  // namespace

TEST_CASE("project.validate: a world index with a missing cell file, a duplicate coordinate and bounds outside their cell is an error "
          "with the file and pointers") {
    AssetsProject p;
    write_all(p.file("cells/0_0.scene.json"), R"({"format":"factoria.scene/1","entities":[]})");
    const std::string bad = std::string(kCell00) + "," + kCell10 + "," + kCell00;
    write_all(p.file("worlds/bad.world.json"), index_text(bad));
    ValidationReport report = validate_project(p.dir);
    const auto found = issues_of(report, "worlds/bad.world.json");
    REQUIRE(found.size() >= 2);
    std::string all;
    for (const ValidationIssue& e : found) all += e.pointer + " | " + e.message + " | " + e.hint + "\n";
    INFO(all);
    CHECK(all.find("/cells/1/scene") != std::string::npos);  // cells/1_0.scene.json does not exist
    CHECK(all.find("cells/0_0.scene.json") != std::string::npos);  // the "did you mean" names the file that exists
    CHECK(all.find("/cells/2/coord") != std::string::npos);  // the duplicate

    // a good index (every file there) has no error of its own
    write_all(p.file("cells/1_0.scene.json"), R"({"format":"factoria.scene/1","entities":[]})");
    write_all(p.file("worlds/bad.world.json"), index_text(std::string(kCell00) + "," + kCell10));
    report = validate_project(p.dir);
    CHECK(issues_of(report, "worlds/bad.world.json").empty());

    // an index that is not JSON is one error
    write_all(p.file("worlds/broken.world.json"), "{ not json");
    report = validate_project(p.dir);
    CHECK(issues_of(report, "worlds/broken.world.json").size() == 1);
}

TEST_CASE("project.validate: every cell file of a big index is checked, with no cap") {
    AssetsProject p;
    std::string cells;
    for (int i = 0; i < 5000; ++i) {  // more than the runtime's eager check (4096 cells)
        if (i) cells += ",";
        const std::string n = std::to_string(i);
        cells += R"({"coord":[)" + n + R"(,0],"scene":"cells/c)" + n + R"(.scene.json","bounds":{"min":[)" + std::to_string(i * 100) +
                 R"(,0,0],"max":[)" + std::to_string(i * 100 + 50) + R"(,1,50]}})";
    }
    write_all(p.file("worlds/big.world.json"), index_text(cells));
    const ValidationReport report = validate_project(p.dir);
    const auto found = issues_of(report, "worlds/big.world.json");
    REQUIRE_FALSE(found.empty());
    bool pointer = false;
    for (const ValidationIssue& e : found) pointer = pointer || e.pointer.rfind("/cells/", 0) == 0;
    CHECK(pointer);
}
