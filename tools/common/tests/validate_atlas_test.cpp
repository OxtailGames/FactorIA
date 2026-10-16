// factoria validate: a texture of an atlas group used by a component that cannot draw from an atlas.
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

void write_png(const stdfs::path& file, int w, int h) {
    Image img;
    img.width = w;
    img.height = h;
    img.rgba.assign(std::size_t(w) * h * 4, 255);
    const std::vector<std::uint8_t> png = encode_png(img);
    testing::write_all(file, std::string(png.begin(), png.end()));
}

const ValidationIssue* find_warning(const ValidationReport& r, const std::string& pointer) {
    for (const ValidationIssue& i : r.warnings)
        if (i.file == "scenes/main.scene.json" && i.pointer == pointer) return &i;
    return nullptr;
}

}  // namespace

TEST_CASE("validate: textures of an atlas group are fine for sprites and particles, a warning for anything else") {
    testing::TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const stdfs::path dir = tmp.path / "game";
    write_png(dir / "assets/tiles.png", 128, 32);
    write_png(dir / "assets/hero.png", 16, 16);
    write_png(dir / "assets/free.png", 16, 16);
    testing::write_all(dir / "assets.json", R"({"format": "factoria.assets/1", "assets": {
        "assets/tiles.png": {"import": {"atlas": "world"}},
        "assets/hero.png": {"import": {"atlas": "world"}}}})");

    auto scene = load_json_file((dir / "scenes/main.scene.json").string());
    REQUIRE(scene.ok());
    auto add = [&](const char* id, const char* type, const char* fields) {
        (*scene)["entities"].push_back(Json::object({{"id", id}, {"components", Json::object({{type, Json::parse(fields)}})}}));
    };
    add("hero", "Sprite", R"({"texture": "assets/hero.png"})");
    add("sparks", "ParticleEmitter", R"({"texture": "assets/hero.png"})");
    add("map", "Tilemap", R"({"tileset": "assets/tiles.png", "tileSize": [32, 32], "width": 1, "height": 1, "tiles": [0]})");
    add("box", "MeshRenderer", R"({"mesh": "cube", "texture": "assets/hero.png"})");
    add("free-map", "Tilemap", R"({"tileset": "assets/free.png", "tileSize": [8, 8], "width": 1, "height": 1, "tiles": [0]})");
    REQUIRE(save_scene_json_file((dir / "scenes/main.scene.json").string(), *scene).ok());

    const ValidationReport r = validate_project(dir.string());
    for (const auto& e : r.errors) MESSAGE(e.to_string());
    CHECK(r.ok);  // a warning, not an error: the game works, only that texture draws wrong once exported

    const ValidationIssue* tileset = find_warning(r, "/entities/3/components/Tilemap/tileset");
    REQUIRE(tileset != nullptr);
    CHECK(tileset->message.find("atlas group \"world\"") != std::string::npos);
    CHECK(tileset->message.find("Tilemap.tileset") != std::string::npos);
    CHECK(tileset->hint.find("\"atlas\"") != std::string::npos);
    CHECK(find_warning(r, "/entities/4/components/MeshRenderer/texture") != nullptr);
    // Sprite and ParticleEmitter are what atlases are for; a texture outside every group is not asked about.
    CHECK(find_warning(r, "/entities/1/components/Sprite/texture") == nullptr);
    CHECK(find_warning(r, "/entities/2/components/ParticleEmitter/texture") == nullptr);
    CHECK(find_warning(r, "/entities/5/components/Tilemap/tileset") == nullptr);
}
