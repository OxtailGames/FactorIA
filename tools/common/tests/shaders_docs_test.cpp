// docs/SHADERS.md: every worked example is a real material. A fenced block that follows a line "File `path`:" is written to
// that path in a scratch project; the blocks that hold a material (`"format": "factoria.material/1"`) must pass the schema
// and the material checks, and compile for every dialect with the real sokol-shdc (SOKOL_SHDC or `factoria setup shaders`;
// skipped with a message where it is not installed, run in CI on Linux).
#include <doctest.h>

#include <filesystem>
#include <regex>
#include <sstream>

#include "fa/core/json_schema.h"
#include "fa/tooling/bundle.h"
#include "fa/tooling/shaders.h"
#include "fa_test_paths.h"  // FA_REPO_ROOT
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct DocFile {
    std::string path, lang, text;
};

// The fenced blocks of SHADERS.md that are preceded by a line "File `path`:".
std::vector<DocFile> docs_files() {
    std::istringstream in(testing::read_all(stdfs::path(FA_REPO_ROOT) / "docs" / "SHADERS.md"));
    static const std::regex label(R"(^File `([^`]+)`:\s*$)");
    std::vector<DocFile> out;
    std::string line, pending;
    bool inFence = false;
    DocFile cur;
    while (std::getline(in, line)) {
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (!inFence) {
            std::smatch m;
            if (line.rfind("```", 0) == 0) {
                inFence = true;
                cur = {pending, line.substr(3), ""};
                pending.clear();
            } else if (std::regex_match(line, m, label)) {
                pending = m[1];
            } else if (!line.empty()) {
                pending.clear();
            }
        } else if (line.rfind("```", 0) == 0) {
            inFence = false;
            if (!cur.path.empty()) out.push_back(cur);
        } else {
            cur.text += line + "\n";
        }
    }
    return out;
}

}  // namespace

TEST_CASE("docs/SHADERS.md: the worked examples pass the schema and the material checks") {
    const std::vector<DocFile> files = docs_files();
    auto schema = bundled_read("schemas/material.schema.json");
    REQUIRE(schema.has_value());
    testing::TempDir dir;
    std::vector<std::string> materials;
    for (const DocFile& f : files) {
        CAPTURE(f.path);
        testing::write_all(dir.path / f.path, f.text);
        if (f.lang != "json") continue;
        Json doc = Json::parse(f.text);
        const auto issues = validate_json(Json::parse(*schema), doc);
        CHECK(issues.empty());
        materials.push_back(f.path);
        if (doc.contains("textures"))
            for (auto it = doc["textures"].begin(); it != doc["textures"].end(); ++it)
                if (it->contains("default")) testing::write_all(dir.path / (*it)["default"].get<std::string>(), "x");
    }
    REQUIRE(materials.size() == 5);  // pulse, dissolve, water, grass, rim
    for (const std::string& m : materials) {
        CAPTURE(m);
        MaterialParse parsed = read_material(dir.str(), m);
        CHECK(parsed.errors.empty());
        if (!parsed.errors.empty()) INFO(parsed.errors.front().to_string());
        CHECK(stdfs::exists(dir.path / parsed.material.shader));
    }
}

TEST_CASE("docs/SHADERS.md: the worked examples compile for every dialect with the real sokol-shdc") {
    ShaderCompileOptions options;
    options.setup = SetupContext{};
    if (find_sokol_shdc(options.setup).empty()) {
        MESSAGE("sokol-shdc is not installed (SOKOL_SHDC, next to factoria, or `factoria setup shaders`): the documentation examples are not compiled here and are in CI on Linux");
        return;
    }
    options.useCache = false;
    testing::TempDir dir;
    std::vector<std::string> materials;
    for (const DocFile& f : docs_files()) {
        testing::write_all(dir.path / f.path, f.text);
        if (f.lang != "json") continue;
        materials.push_back(f.path);
        Json doc = Json::parse(f.text);
        if (doc.contains("textures"))
            for (auto it = doc["textures"].begin(); it != doc["textures"].end(); ++it)
                if (it->contains("default")) testing::write_all(dir.path / (*it)["default"].get<std::string>(), "x");
    }
    REQUIRE(materials.size() == 5);
    for (const std::string& m : materials) {
        CAPTURE(m);
        auto result = compile_material(dir.str(), m, options);
        REQUIRE(result.ok());
        std::string why;
        for (const ShaderIssue& e : result->errors) why += e.to_string() + "\n";
        INFO(why);
        CHECK(result->ok);
        CHECK(result->twins.size() == 6);
    }
}
