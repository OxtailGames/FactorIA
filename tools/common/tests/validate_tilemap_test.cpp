// factoria validate: Tilemap data in scene files (structure via the scene loader, tile indices vs the tileset image).
#include <doctest.h>

#include <filesystem>

#include "fa/core/image.h"
#include "fa/scene/serialize.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

void write_tileset(const stdfs::path& file) {
    Image img;
    img.width = 128;  // 4 tiles of 32x32
    img.height = 32;
    img.rgba.assign(std::size_t(128) * 32 * 4, 255);
    std::vector<std::uint8_t> png = encode_png(img);
    stdfs::create_directories(file.parent_path());
    std::ofstream(file, std::ios::binary).write(reinterpret_cast<const char*>(png.data()), std::streamsize(png.size()));
}

// Adds a Tilemap with the given component JSON to the 2d-empty template's scene.
ValidationReport validate_with_tilemap(testing::TempDir& tmp, const char* tilemapJson) {
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    write_tileset(tmp.path / "game/assets/tiles.png");
    auto scene = load_json_file(tmp.sub("game/scenes/main.scene.json"));
    REQUIRE(scene.ok());
    (*scene)["entities"].push_back(Json::object({{"id", "map"}, {"components", Json::object({{"Tilemap", Json::parse(tilemapJson)}})}}));
    REQUIRE(save_scene_json_file(tmp.sub("game/scenes/main.scene.json"), *scene).ok());  // canonical: validate warns about other layouts
    return validate_project(tmp.sub("game"));
}

const ValidationIssue* find_issue(const std::vector<ValidationIssue>& list, const std::string& pointerSuffix) {
    for (const ValidationIssue& i : list)
        if (i.file == "scenes/main.scene.json" && i.pointer.size() >= pointerSuffix.size() &&
            i.pointer.compare(i.pointer.size() - pointerSuffix.size(), pointerSuffix.size(), pointerSuffix) == 0)
            return &i;
    return nullptr;
}

}  // namespace

TEST_CASE("validate: a consistent tilemap passes") {
    testing::TempDir tmp;
    auto r = validate_with_tilemap(tmp, R"({"tileset":"assets/tiles.png","tileSize":[32,32],"columns":4,"width":3,"height":2,
                                           "tiles":[0,1,2, 3,-1,0],"solidTiles":[0,1]})");
    for (auto& e : r.errors) MESSAGE(e.to_string());
    CHECK(r.ok);
}

TEST_CASE("validate: tiles that do not match width*height are an error at the tiles pointer") {
    testing::TempDir tmp;
    auto r = validate_with_tilemap(tmp, R"({"tileset":"assets/tiles.png","tileSize":[32,32],"columns":4,"width":3,"height":3,
                                           "tiles":[0,1,2, 3,3,3],"solidTiles":[0]})");
    REQUIRE_FALSE(r.ok);
    const ValidationIssue* i = find_issue(r.errors, "/components/Tilemap/tiles");
    REQUIRE(i != nullptr);
    CHECK(i->message.find("6 entries") != std::string::npos);
    CHECK(i->message.find("3 x 3 = 9") != std::string::npos);
    CHECK_FALSE(i->hint.empty());
}

TEST_CASE("validate: ASCII strings or ragged rows in tiles are errors that point at scene.import_ascii") {
    testing::TempDir tmp;
    auto r = validate_with_tilemap(tmp, R"({"width":3,"height":2,"tiles":["#..","###"]})");
    REQUIRE_FALSE(r.ok);
    const ValidationIssue* i = find_issue(r.errors, "/components/Tilemap/tiles/0");
    REQUIRE(i != nullptr);
    CHECK(i->message.find("string") != std::string::npos);
    CHECK(i->hint.find("scene.import_ascii") != std::string::npos);

    testing::TempDir tmp2;
    auto r2 = validate_with_tilemap(tmp2, R"({"width":3,"height":2,"tiles":[[0,0,0],[1,1]]})");
    REQUIRE_FALSE(r2.ok);
    const ValidationIssue* j = find_issue(r2.errors, "/components/Tilemap/tiles/1");
    REQUIRE(j != nullptr);
    CHECK(j->message.find("row 1") != std::string::npos);
}

TEST_CASE("validate: a tile index outside the tileset image is an error, with the columns fix") {
    testing::TempDir tmp;
    // 128x32 image of 32x32 tiles = 4 tiles; index 7 does not exist.
    auto r = validate_with_tilemap(tmp, R"({"tileset":"assets/tiles.png","tileSize":[32,32],"columns":4,"width":2,"height":2,
                                           "tiles":[0,1,7,9],"solidTiles":[0]})");
    REQUIRE_FALSE(r.ok);
    const ValidationIssue* i = find_issue(r.errors, "/components/Tilemap/tiles/2");
    REQUIRE(i != nullptr);
    CHECK(i->message.find("Tile index 7") != std::string::npos);
    CHECK(i->message.find("assets/tiles.png") != std::string::npos);
    CHECK(i->message.find("1 more tile") != std::string::npos);
    CHECK(i->hint.find("0..3") != std::string::npos);

    // "columns": 1 on a 4 tile wide tileset is a mistake: the hint says to remove it or set 4.
    testing::TempDir tmp2;
    auto r2 = validate_with_tilemap(tmp2, R"({"tileset":"assets/tiles.png","tileSize":[32,32],"columns":1,"width":2,"height":1,"tiles":[0,3]})");
    REQUIRE_FALSE(r2.ok);
    const ValidationIssue* j = find_issue(r2.errors, "/components/Tilemap/tiles/1");
    REQUIRE(j != nullptr);
    CHECK(j->hint.find("\"columns\": 4") != std::string::npos);
    CHECK(j->message.find("columns 1") != std::string::npos);
}

TEST_CASE("validate: without columns the tileset width decides, so tile 3 of a 4 tile wide image is fine") {
    testing::TempDir tmp;
    // 128x32 image of 32x32 tiles: columns unset = 4, tiles 0..3 exist.
    auto r = validate_with_tilemap(tmp, R"({"tileset":"assets/tiles.png","tileSize":[32,32],"width":4,"height":1,"tiles":[0,1,2,3]})");
    CHECK(r.ok);
    CHECK(r.errors.empty());
    CHECK(r.warnings.empty());

    // Tile 4 is outside; the message shows the derived columns and there is no "set columns" advice.
    testing::TempDir tmp2;
    auto r2 = validate_with_tilemap(tmp2, R"({"tileset":"assets/tiles.png","tileSize":[32,32],"width":5,"height":1,"tiles":[0,1,2,3,4]})");
    REQUIRE_FALSE(r2.ok);
    const ValidationIssue* i = find_issue(r2.errors, "/components/Tilemap/tiles/4");
    REQUIRE(i != nullptr);
    CHECK(i->message.find("columns 4 = 4 tiles") != std::string::npos);
    CHECK(i->hint.find("0..3") != std::string::npos);
    CHECK(i->hint.find("remove") == std::string::npos);
}

TEST_CASE("validate: margin and spacing change how many tiles the tileset image holds") {
    // 128x32 image of 14x14 tiles with margin 1 and spacing 2: (128 - 2 + 2) / 16 = 8 columns, (32 - 2 + 2) / 16 = 2 rows
    // = 16 tiles. Packed it would hold 9 x 2 = 18, so tile 16 is only wrong because margin and spacing are read.
    testing::TempDir tmp;
    auto ok = validate_with_tilemap(tmp, R"({"tileset":"assets/tiles.png","tileSize":[14,14],"margin":1,"spacing":2,"width":2,"height":1,"tiles":[0,15]})");
    CHECK(ok.ok);
    testing::TempDir tmp2;
    auto r = validate_with_tilemap(tmp2, R"({"tileset":"assets/tiles.png","tileSize":[14,14],"margin":1,"spacing":2,"width":2,"height":1,"tiles":[0,16]})");
    REQUIRE_FALSE(r.ok);
    const ValidationIssue* i = find_issue(r.errors, "/components/Tilemap/tiles/1");
    REQUIRE(i != nullptr);
    CHECK(i->message.find("16 tiles") != std::string::npos);
    CHECK(i->hint.find("0..15") != std::string::npos);
}
