// scene.set_parent: the command the editor's entity tree uses to reparent by drag and drop.
#include <doctest.h>

#include <filesystem>
#include <fstream>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Set Parent Test",
  "id": "com.example.setparent",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "box", "components": { "Transform": { "position": [100, 0, 0] } } },
    { "id": "kid", "components": { "Transform": { "position": [130, 0, 0] } } }
  ]
})";

struct Session {
    stdfs::path dir;
    Engine engine;
    Session() {
        dir = fs::make_temp_dir("fa_setparent_test");
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary) << kProject;
        std::ofstream(dir / "scenes/main.scene.json", std::ios::binary) << kScene;
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        std::string err;
        REQUIRE_MESSAGE(engine.init(c, nullptr, &err), err);
    }
    ~Session() {
        engine.shutdown();
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    CommandResult call(const std::string& cmd, const char* args) { return engine.commands().call(cmd, Json::parse(args)); }
};

}  // namespace

TEST_CASE("scene.set_parent: keeps the world position by default, or the local Transform on request") {
    Session s;
    auto r = s.call("scene.set_parent", R"({"id":"kid","parent":"box"})");
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["parent"] == "box");
    r = s.call("scene.get_entity", R"({"id":"kid"})");
    CHECK(r.result["parent"] == "box");
    CHECK(r.result["components"]["Transform"]["position"][0].get<double>() == doctest::Approx(30));  // world x stays 130

    REQUIRE(s.call("scene.set_parent", R"({"id":"kid","parent":""})").ok);  // "" = top level
    r = s.call("scene.get_entity", R"({"id":"kid"})");
    CHECK_FALSE(r.result.contains("parent"));
    CHECK(r.result["components"]["Transform"]["position"][0].get<double>() == doctest::Approx(130));

    REQUIRE(s.call("scene.set_parent", R"({"id":"kid","parent":"box","keepWorldTransform":false})").ok);
    r = s.call("scene.get_entity", R"({"id":"kid"})");
    CHECK(r.result["components"]["Transform"]["position"][0].get<double>() == doctest::Approx(130));  // local kept

    r = s.call("scene.set_parent", R"({"id":"kid","parent":null})");
    REQUIRE(r.ok);
    CHECK(r.result["parent"].is_null());
}

TEST_CASE("scene.set_parent: refuses cycles and unknown ids with a hint") {
    Session s;
    REQUIRE(s.call("scene.set_parent", R"({"id":"kid","parent":"box"})").ok);
    auto r = s.call("scene.set_parent", R"({"id":"box","parent":"kid"})");
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find("cycle") != std::string::npos);
    CHECK_FALSE(r.error["hint"].get<std::string>().empty());
    CHECK_FALSE(s.call("scene.set_parent", R"({"id":"box","parent":"box"})").ok);

    r = s.call("scene.set_parent", R"({"id":"kid","parent":"bxo"})");  // a typo suggests the real id
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find("box") != std::string::npos);
    CHECK_FALSE(s.call("scene.set_parent", R"({"id":"nobody"})").ok);
    r = s.call("scene.get_entity", R"({"id":"kid"})");
    CHECK(r.result["parent"] == "box");  // refused calls changed nothing
}

TEST_CASE("scene.set_parent: index places the child among its siblings and bad indexes teach") {
    Session s;
    REQUIRE(s.call("scene.spawn", R"({"id":"x","parent":"box"})").ok);
    REQUIRE(s.call("scene.spawn", R"({"id":"y","parent":"box"})").ok);
    auto order = [&] {
        std::string out;
        const auto got = s.call("scene.get_entity", R"({"id":"box"})");
        for (const auto& c : got.result["children"]) out += (out.empty() ? "" : ",") + c["id"].get<std::string>();
        return out;
    };
    auto r = s.call("scene.spawn", R"({"id":"z","parent":"box","index":0})");
    REQUIRE(r.ok);
    CHECK(order() == "z,x,y");
    r = s.call("scene.set_parent", R"({"id":"kid","parent":"box","index":1})");
    REQUIRE(r.ok);
    CHECK(r.result["index"] == 1);
    CHECK(order() == "z,kid,x,y");
    r = s.call("scene.set_parent", R"({"id":"z","parent":"box","index":3})");  // within the same parent: 3 others
    REQUIRE(r.ok);
    CHECK(order() == "kid,x,y,z");
    r = s.call("scene.set_parent", R"({"id":"z","parent":"box","index":4})");
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find("0 to 3") != std::string::npos);
    CHECK_FALSE(s.call("scene.set_parent", R"({"id":"z","parent":"box","index":-1})").ok);
    CHECK_FALSE(s.call("scene.set_parent", R"({"id":"z","parent":null,"index":0})").ok);
    CHECK_FALSE(s.call("scene.spawn", R"({"id":"w","parent":"box","index":9})").ok);
    CHECK(order() == "kid,x,y,z");
}
