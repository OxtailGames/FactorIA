// M75-P0: the authoring commands of the big worlds (not the terrain ones: terrain_commands_tests.cpp) exist, are documented and classified, and fail with `not_built` (changing nothing)
// until their package lands (docs/BIG_WORLDS.md).
#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <string>

#include "fa/authoring/authoring.h"
#include "fa/core/fs.h"
#include "fa/runtime/engine.h"

using namespace fa;
namespace stdfs = std::filesystem;

TEST_CASE("big world commands: registered with their category, schema and package, and fail with not_built") {
    authoring::install();
    stdfs::path dir = fs::make_temp_dir("fa_bigworld_cmd").value();
    stdfs::create_directories(dir / "scenes");
    std::ofstream(dir / "factoria.json", std::ios::binary)
        << R"({"format":"factoria.project/1","name":"Big","id":"com.example.big","mainScene":"scenes/main.scene.json",
               "display":{"width":320,"height":180}})";
    std::ofstream(dir / "scenes/main.scene.json", std::ios::binary)
        << R"({"format": "factoria.scene/1", "entities": []})";
    EngineConfig c;
    c.projectDir = dir.generic_string();
    c.headless = true;
    c.hotReload = false;
    c.memoryStorage = true;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);

    struct Row {
        const char* name;
        const char* package;
        const char* category;
        const char* args;  // the least that satisfies the schema
    };
    const Row rows[] = {
        {"world.split_cells", "M75.3", "world", R"({"scene":"scenes/main.scene.json"})"},
        {"world.merge_cells", "M75.3", "world", R"({"manifest":"scenes/main.world.json"})"},
        {"model.generate_lods", "M75.1", "assets", R"({"model":"models/rock.glb"})"},
        {"model.bake_impostor", "M75.1", "assets", R"({"model":"models/tree.glb"})"},
        {"foliage.scatter", "M75.6", "world", R"({"entity":"grass"})"},
        {"foliage.paint", "M75.6", "world", R"({"entity":"grass","center":[0,0],"radius":5})"},
        {"foliage.clear", "M75.6", "world", R"({"entity":"grass"})"},
    };
    for (const Row& row : rows) {
        INFO(row.name);
        const CommandInfo* info = e.commands().info(row.name);
        REQUIRE(info != nullptr);
        CHECK(info->category == row.category);
        CHECK_FALSE(info->readOnly);
        CHECK(info->description.find("Example") != std::string::npos);
        CHECK(info->description.find(row.package) != std::string::npos);
        CHECK(info->description.size() < 1500);
        auto r = e.commands().call(row.name, Json::parse(row.args));
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "not_built");
        CHECK(r.error.dump().find(row.package) != std::string::npos);
    }
    // Nothing was written: the project has only the two files it started with.
    int files = 0;
    for (auto& entry : stdfs::recursive_directory_iterator(dir))
        if (entry.is_regular_file()) ++files;
    CHECK(files == 2);
    e.shutdown();
    std::error_code ec;
    stdfs::remove_all(dir, ec);
}
