// docs/SHADERS.md and docs/shaders/SHADERS_FULL.md: every worked example is a real material. A fenced block that follows a line "File `path`:" is written to
// that path in a scratch project; the blocks that hold a material (`"format": "factoria.material/1"`) must pass the schema
// and the material checks, and compile for every dialect with the real sokol-shdc (SOKOL_SHDC or `factoria setup shaders`;
// skipped with a message where it is not installed, failed instead with FA_REQUIRE_SHDC=1 as in CI).
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

// The pages whose worked examples are built here, relative to docs/.
constexpr const char* kPages[] = {"SHADERS.md", "shaders/SHADERS_FULL.md", "shaders/SHADERS_LIGHTING.md"};

struct DocFile {
    std::string path, lang, text;
};

// The fenced blocks of a page that are preceded by a line "File `path`:".
std::vector<DocFile> docs_files(const char* page) {
    std::istringstream in(testing::read_all(stdfs::path(FA_REPO_ROOT) / "docs" / page));
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

// Writes the labelled blocks into `root` (and an empty file for every default texture); returns the material files.
std::vector<std::string> write_doc_project(const stdfs::path& root) {
    std::vector<std::string> materials;
    for (const char* page : kPages)
        for (const DocFile& f : docs_files(page)) {
            testing::write_all(root / f.path, f.text);
            if (f.lang != "json") continue;
            materials.push_back(f.path);
            Json doc = Json::parse(f.text);
            if (doc.contains("textures"))
                for (auto it = doc["textures"].begin(); it != doc["textures"].end(); ++it)
                    if (it->contains("default")) testing::write_all(root / (*it)["default"].get<std::string>(), "x");
        }
    return materials;
}

// How many materials the pages say they hold, counted from their text (a block that names the material format), so that
// adding an example needs no edit here and a block that lost its "File `path`:" label is not dropped without a word.
size_t material_blocks_in_pages() {
    size_t n = 0;
    for (const char* page : kPages) {
        const std::string text = testing::read_all(stdfs::path(FA_REPO_ROOT) / "docs" / page);
        static const std::string needle = "\"format\": \"factoria.material/1\"";
        for (size_t at = text.find(needle); at != std::string::npos; at = text.find(needle, at + 1)) ++n;
    }
    return n;
}

}  // namespace

TEST_CASE("docs/SHADERS.md and SHADERS_FULL.md: the worked examples pass the schema and the material checks") {
    auto schema = bundled_read("schemas/material.schema.json");
    REQUIRE(schema.has_value());
    testing::TempDir dir;
    const std::vector<std::string> materials = write_doc_project(dir.path);
    REQUIRE(materials.size() == material_blocks_in_pages());
    for (const std::string& m : materials) {
        CAPTURE(m);
        CHECK(validate_json(Json::parse(*schema), Json::parse(testing::read_all(dir.path / m))).empty());
        MaterialParse parsed = read_material(dir.str(), m);
        CHECK_MESSAGE(parsed.errors.empty(), (parsed.errors.empty() ? "" : parsed.errors.front().to_string()));
        CHECK(stdfs::exists(dir.path / parsed.material.shader));
    }
}

TEST_CASE(
    "docs/SHADERS.md and SHADERS_FULL.md: the worked examples compile for every dialect with the real sokol-shdc") {
    ShaderCompileOptions options;
    options.setup = SetupContext{};
    FA_SKIP_WITHOUT_SHDC(options.setup, "sokol-shdc is not installed (SOKOL_SHDC, next to factoria, or `factoria setup "
                                        "shaders`): the documentation examples are not compiled here and are in CI");
    options.useCache = false;
    testing::TempDir dir;
    const std::vector<std::string> materials = write_doc_project(dir.path);
    REQUIRE(materials.size() == material_blocks_in_pages());
    for (const std::string& m : materials) {
        CAPTURE(m);
        auto result = compile_material(dir.str(), m, options);
        REQUIRE(result.ok());
        CHECK_MESSAGE(result->ok, (result->errors.empty() ? "" : result->errors.front().to_string()));
        CHECK(result->twins.size() == 6);
    }
}
