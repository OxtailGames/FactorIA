// How scene and prefab files are laid out on disk: short scalar arrays on one line, Tilemap tiles one map row per line.
#include <doctest.h>

#include <chrono>
#include <filesystem>
#include <string>
#include <vector>

#include "fa/core/fs.h"
#include "fa/scene/components.h"
#include "fa/scene/serialize.h"

using namespace fa;

namespace {

struct TempProject {
    std::filesystem::path dir, oldRoot;
    TempProject() {
        oldRoot = fs::project_root();
        dir = std::filesystem::temp_directory_path() /
              ("fa_test_layout_" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
        std::filesystem::create_directories(dir);
        fs::set_project_root(dir);
    }
    ~TempProject() {
        fs::set_project_root(oldRoot);
        std::error_code ec;
        std::filesystem::remove_all(dir, ec);
    }
};

const char* kLevelScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "level", "name": "Level", "tags": ["terrain", "solid"], "components": {
        "Transform": { "position": [10.5, -20, 0] },
        "Tilemap": { "tileset": "assets/tiles.png", "tileSize": [32, 32], "columns": 8, "width": 4, "height": 3,
                     "tiles": [-1, -1, -1, -1, -1, 2, 10, -1, 0, 1, 1, 0], "solidTiles": [0, 1, 2, 10] } } }
  ]
})";

const char* kLevelText =
    "{\n"
    "  \"format\": \"factoria.scene/1\",\n"
    "  \"settings\": {},\n"
    "  \"entities\": [\n"
    "    {\n"
    "      \"id\": \"level\",\n"
    "      \"name\": \"Level\",\n"
    "      \"tags\": [\"terrain\", \"solid\"],\n"
    "      \"components\": {\n"
    "        \"Transform\": {\n"
    "          \"position\": [10.5, -20.0, 0.0]\n"
    "        },\n"
    "        \"Tilemap\": {\n"
    "          \"tileset\": \"assets/tiles.png\",\n"
    "          \"tileSize\": [32.0, 32.0],\n"
    "          \"columns\": 8,\n"
    "          \"width\": 4,\n"
    "          \"height\": 3,\n"
    "          \"tiles\": [\n"
    "            -1, -1, -1, -1,\n"
    "            -1,  2, 10, -1,\n"
    "             0,  1,  1,  0\n"
    "          ],\n"
    "          \"solidTiles\": [0, 1, 2, 10]\n"
    "        }\n"
    "      }\n"
    "    }\n"
    "  ]\n"
    "}\n";

}  // namespace

TEST_CASE("scene layout: vectors on one line and Tilemap tiles one map row per line") {
    World w;
    LoadReport r = load_scene(w, Json::parse(kLevelScene), "level.scene.json");
    REQUIRE(r.ok());
    Json saved = save_scene(w);

    CHECK(dump_scene_json(saved) == kLevelText);

    // Round trip: the text is plain JSON that loads back into identical component data.
    Json reparsed = Json::parse(kLevelText);
    CHECK(reparsed == saved);
    World w2;
    LoadReport r2 = load_scene(w2, reparsed, "level.scene.json");
    REQUIRE(r2.ok());
    CHECK(save_scene(w2) == saved);
    Entity level = w2.find_by_id("level");
    REQUIRE(level != kNullEntity);
    const Tilemap* tm = w2.get<Tilemap>(level);
    REQUIRE(tm != nullptr);
    CHECK(tm->width == 4);
    CHECK(tm->height == 3);
    CHECK(tm->tiles == Json::parse("[-1,-1,-1,-1,-1,2,10,-1,0,1,1,0]"));
    CHECK(tm->solidTiles == Json::parse("[0,1,2,10]"));
}

TEST_CASE("scene layout: save_scene_file and prefab files use the same layout and load back") {
    TempProject p;
    World w;
    REQUIRE(load_scene(w, Json::parse(kLevelScene), "level.scene.json").ok());

    REQUIRE(save_scene_file(w, "scenes/level.scene.json").ok());
    auto text = fs::read_text("scenes/level.scene.json");
    REQUIRE(text.ok());
    CHECK(text.value() == kLevelText);
    World w2;
    CHECK(load_scene_file(w2, "scenes/level.scene.json").ok());
    CHECK(save_scene(w2) == save_scene(w));

    // A prefab holds the entity under "entity": same rows, found through the same component path.
    Json prefab = make_prefab(w, w.find_by_id("level"));
    REQUIRE(save_scene_json_file("prefabs/level.prefab.json", prefab).ok());
    auto prefabText = fs::read_text("prefabs/level.prefab.json");
    REQUIRE(prefabText.ok());
    CHECK(prefabText.value().find("\"tiles\": [\n          -1, -1, -1, -1,\n          -1,  2, 10, -1,\n"
                                  "           0,  1,  1,  0\n        ],") != std::string::npos);
    CHECK(prefabText.value().find("\"position\": [10.5, -20.0, 0.0]") != std::string::npos);
    CHECK(Json::parse(prefabText.value()) == prefab);
    World w3;
    LoadReport r3;
    Entity copy = instantiate_prefab(w3, "prefabs/level.prefab.json", kNullEntity, r3);
    CHECK(r3.ok());
    CHECK(entity_to_json(w3, copy) == entity_to_json(w, w.find_by_id("level")));
}

TEST_CASE("scene layout: tiles without a usable width keep the wrapped scalar layout, rows of rows stay as rows") {
    // No width: nothing says where a row ends, so the array is filled up to the line limit.
    Json noWidth = Json::parse(R"({"format":"factoria.scene/1","entities":[{"id":"m","components":{
        "Tilemap":{"tiles":[0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,
                            0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1]}}}]})");
    std::string text = dump_scene_json(noWidth);
    CHECK(text.find("\"tiles\": [\n") != std::string::npos);
    std::size_t lineStart = 0;
    while (lineStart < text.size()) {
        std::size_t lineEnd = text.find('\n', lineStart);
        if (lineEnd == std::string::npos) lineEnd = text.size();
        CHECK(lineEnd - lineStart <= 100);
        lineStart = lineEnd + 1;
    }
    CHECK(Json::parse(text) == noWidth);

    // Rows already given as arrays: one row per line, each row on one line.
    Json rowsJson = Json::parse(R"({"format":"factoria.scene/1","entities":[{"id":"m","components":{
        "Tilemap":{"width":3,"height":2,"tiles":[[0,1,2],[3,4,5]]}}}]})");
    std::string rowsText = dump_scene_json(rowsJson);
    CHECK(rowsText.find("\"tiles\": [\n            [0, 1, 2],\n            [3, 4, 5]\n          ]") != std::string::npos);
    CHECK(Json::parse(rowsText) == rowsJson);
}

TEST_CASE("scene layout: long scalar arrays in other fields wrap instead of making one giant line") {
    Json values = Json::array();
    for (int i = 0; i < 200; ++i) values.push_back(i * 3 - 100);
    Json scene = Json::object({{"format", "factoria.scene/1"},
                               {"entities", Json::array({Json::object({{"id", "e"},
                                                                       {"components",
                                                                        Json::object({{"Script",
                                                                                       Json::object({{"props", Json::object({{"data", values}})}})}})}})})}});
    std::string text = dump_scene_json(scene);
    std::size_t lineStart = 0;
    std::size_t lines = 0;
    while (lineStart < text.size()) {
        std::size_t lineEnd = text.find('\n', lineStart);
        if (lineEnd == std::string::npos) lineEnd = text.size();
        CHECK(lineEnd - lineStart <= 100);
        ++lines;
        lineStart = lineEnd + 1;
    }
    CHECK(lines > 10);   // wrapped over several lines
    CHECK(lines < 80);   // but not one number per line
    CHECK(Json::parse(text) == scene);
}
