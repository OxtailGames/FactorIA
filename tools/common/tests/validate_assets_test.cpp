// project.validate: the assets.json manifest (schemas/assets.schema.json) and the asset checks.
#include <doctest.h>

#include <filesystem>

#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const ValidationIssue* find_issue(const std::vector<ValidationIssue>& list, const std::string& file, const std::string& pointer = {}) {
    for (const ValidationIssue& i : list)
        if (i.file == file && (pointer.empty() || i.pointer == pointer)) return &i;
    return nullptr;
}

}  // namespace

TEST_CASE("validate: assets.json is checked against its schema, and entries of missing files are reported") {
    testing::TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const std::string dir = tmp.sub("game");
    testing::write_all(stdfs::path(dir) / "assets/hero_v2.png", "not really a png");
    testing::write_all(stdfs::path(dir) / "assets.json", R"({
      "format": "factoria.assets/1",
      "defaults": {"audio": {"stream": "sometimes"}},
      "assets": {
        "assets/hero.png": {"provenance": {"origin": "generated", "date": "2026-10-16", "provider": "fake"}}
      }
    })");

    const ValidationReport r = validate_project(dir);
    CHECK_FALSE(r.ok);
    const ValidationIssue* bad = find_issue(r.errors, "assets.json", "/defaults/audio/stream");
    REQUIRE(bad != nullptr);
    const ValidationIssue* missing = find_issue(r.warnings, "assets.json", "/assets/assets~1hero.png");
    REQUIRE(missing != nullptr);
    CHECK(missing->hint.find("assets/hero_v2.png") != std::string::npos);
}

TEST_CASE("validate: a valid assets.json adds no issue") {
    testing::TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const std::string dir = tmp.sub("game");
    const ValidationReport before = validate_project(dir);
    testing::write_all(stdfs::path(dir) / "assets.json",
                       R"({"format": "factoria.assets/1", "defaults": {"texture": {"compression": "uastc"}}})");
    const ValidationReport r = validate_project(dir);
    CHECK(r.ok);
    CHECK(r.warnings.size() == before.warnings.size());
}
