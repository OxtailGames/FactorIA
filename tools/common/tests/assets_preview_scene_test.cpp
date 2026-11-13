// assets.preview_in_scene: an asset placed in a private run of a scene and captured at phone and desktop sizes. The capture
// uses the GPU, so those tests skip (with a message) where the engine finds no graphics device.
#include <doctest.h>

#include "asset_test_helpers.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/tooling.h"

using namespace fa;
using namespace fa::testing;
namespace stdfs = std::filesystem;

namespace {

struct SceneProject {
    TempDir tmp;
    std::string dir;
    CommandRegistry reg;
    SceneProject() {
        dir = tmp.str();
        REQUIRE(create_project(dir, "2d-empty").ok());
        register_tooling_commands(reg, dir);
        write_all(file("scenes/level.scene.json"), R"({"format":"factoria.scene/1","entities":[
          {"id":"cam","components":{"Transform":{},"Camera":{"orthoSize":100,"clearColor":[0,0,0,1]}}},
          {"id":"hero","components":{"Transform":{"position":[-50,0,0]},"Shape2D":{"shape":"rectangle","size":[20,20],"color":[0,0,1,1]}}}]})");
        write_png(file("assets/red.png"), make_image(16, 16, {255, 0, 0, 255}));
    }
    stdfs::path file(const std::string& rel) const { return stdfs::path(dir) / rel; }
};

bool no_gpu(const CommandResult& r) {
    if (r.ok || r.error.value("code", std::string()) != "no_gpu") return false;
    MESSAGE("skipped: no graphics device on this machine (" << r.error.value("message", std::string()) << ")");
    return true;
}

std::string message(const CommandResult& r) {
    return r.error.value("message", std::string()) + " " + r.error.value("hint", std::string());
}

int count_red(const Image& img) {
    int n = 0;
    for (std::size_t i = 0; i + 3 < img.rgba.size(); i += 4)
        if (img.rgba[i] > 240 && img.rgba[i + 1] < 15 && img.rgba[i + 2] < 15) ++n;
    return n;
}

}  // namespace

TEST_CASE("assets.preview_in_scene: argument errors teach (no GPU needed)") {
    SceneProject p;
    auto call = [&](Json extra) {
        Json a = Json{{"path", "assets/red.png"}, {"scene", "scenes/level.scene.json"}};
        for (auto it = extra.begin(); it != extra.end(); ++it) a[it.key()] = it.value();
        return p.reg.call("assets.preview_in_scene", a);
    };
    CommandResult r = call(Json{{"at", Json::array({0, 0})}, {"entity", "hero"}});
    CHECK_FALSE(r.ok);
    CHECK(message(r).find("not both") != std::string::npos);
    r = call(Json{{"resolutions", Json::array({"fone"})}});
    CHECK(message(r).find("phone") != std::string::npos);
    r = call(Json{{"placement", "replace"}});
    CHECK(message(r).find("needs `entity`") != std::string::npos);
    r = p.reg.call("assets.preview_in_scene", Json{{"path", "assets/red.png"}, {"scene", "scenes/nope.scene.json"}});
    CHECK(r.error["code"] == "not_found");
    write_all(p.file("assets/x.wav"), "RIFF");
    r = p.reg.call("assets.preview_in_scene", Json{{"path", "assets/x.wav"}, {"scene", "scenes/level.scene.json"}});
    CHECK(message(r).find("assets.spectrogram") != std::string::npos);
    r = call(Json{{"size", Json::array({1, 2, 3})}});
    CHECK_FALSE(r.ok);
}

TEST_CASE("assets.preview_in_scene: a sprite at a position shows at phone and desktop, the scene file is untouched, "
          "same pixels twice") {
    SceneProject p;
    const std::string before = read_all(p.file("scenes/level.scene.json"));
    const Json args = Json{{"path", "assets/red.png"},
                           {"scene", "scenes/level.scene.json"},
                           {"at", Json::array({40, 0})},
                           {"size", Json::array({32, 32})}};
    CommandResult r = p.reg.call("assets.preview_in_scene", args);
    if (no_gpu(r)) return;
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    REQUIRE(r.result["screens"].size() == 2);
    CHECK(r.result["screens"][0]["name"] == "phone");
    CHECK(r.result["screens"][1]["name"] == "desktop");
    CHECK(r.result["screens"][0]["onScreen"] == true);
    CHECK(r.result["sceneFileChanged"] == false);
    CHECK(read_all(p.file("scenes/level.scene.json")) == before);
    CHECK(r.result["warnings"].empty());
    const Image pic = read_png(r.result["$image"]["path"].get<std::string>());
    CHECK(pic.width == r.result["picture"]["width"].get<int>());
    CHECK(count_red(pic) > 400);  // two sprites of 32x32 world units, drawn at one pixel per unit or more

    const CommandResult again = p.reg.call("assets.preview_in_scene", args);
    REQUIRE(again.ok);
    CHECK(read_all(again.result["$image"]["path"].get<std::string>()) ==
          read_all(r.result["$image"]["path"].get<std::string>()));
}

TEST_CASE("assets.preview_in_scene: beside and in place of an entity, an unknown entity, an off-screen position") {
    SceneProject p;
    CommandResult r = p.reg.call("assets.preview_in_scene", Json{{"path", "assets/red.png"},
                                                                 {"scene", "scenes/level.scene.json"},
                                                                 {"entity", "hero"},
                                                                 {"resolutions", Json::array({"desktop"})}});
    if (no_gpu(r)) return;
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["screens"].size() == 1);
    // beside: -50 + half the hero (10) + half the sprite (8) + 8 of air
    CHECK(r.result["screens"][0]["position"][0].get<double>() == doctest::Approx(-24.0));
    r = p.reg.call("assets.preview_in_scene", Json{{"path", "assets/red.png"},
                                                   {"scene", "scenes/level.scene.json"},
                                                   {"entity", "hero"},
                                                   {"placement", "replace"},
                                                   {"resolutions", Json::array({"desktop"})}});
    REQUIRE(r.ok);
    CHECK(r.result["screens"][0]["position"][0].get<double>() == doctest::Approx(-50.0));
    const Image pic = read_png(r.result["$image"]["path"].get<std::string>());
    int blue = 0;
    for (std::size_t i = 0; i + 3 < pic.rgba.size(); i += 4)
        if (pic.rgba[i] < 10 && pic.rgba[i + 1] < 10 && pic.rgba[i + 2] > 240) ++blue;
    CHECK(blue == 0);  // the hero is hidden in the picture
    r = p.reg.call("assets.preview_in_scene",
                   Json{{"path", "assets/red.png"}, {"scene", "scenes/level.scene.json"}, {"entity", "heroo"}});
    CHECK_FALSE(r.ok);
    CHECK(message(r).find("hero") != std::string::npos);
    r = p.reg.call("assets.preview_in_scene", Json{{"path", "assets/red.png"},
                                                   {"scene", "scenes/level.scene.json"},
                                                   {"at", Json::array({5000, 0})},
                                                   {"resolutions", Json::array({"desktop"})}});
    REQUIRE(r.ok);
    CHECK(r.result["screens"][0]["onScreen"] == false);
    CHECK(has_warning(r.result, "outside the view"));
    r = p.reg.call("assets.preview_in_scene", Json{{"path", "assets/red.png"},
                                                   {"scene", "scenes/level.scene.json"},
                                                   {"at", Json::array({5000, 0})},
                                                   {"center", true},
                                                   {"resolutions", Json::array({"desktop"})}});
    REQUIRE(r.ok);
    CHECK(r.result["screens"][0]["onScreen"] == true);
}
