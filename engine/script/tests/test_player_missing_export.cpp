// A script that imports or calls something the running player lacks (a player older than the game's engine, M31.2).
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

TEST_CASE("an import the player lacks names the module and the export") {
    TestHost h("missing_export");
    h.file("scripts/needs.js",
           "import { Behaviour, analytics_from_the_future } from \"factoria\";\n"
           "export default class Needs extends Behaviour {}\n");
    h.file("scenes/main.scene.json",
           R"({"format":"factoria.scene/1","entities":[{"id":"p","components":{"Script":{"path":"scripts/needs.js"}}}]})");
    REQUIRE(h.start());
    h.load_scene_now("scenes/main.scene.json");
    h.step_frames(2);
    REQUIRE_FALSE(h.scripts.errors().empty());
    const std::string text = h.scripts.errors().front().to_string();
    MESSAGE(text);
    CHECK(text.find("module 'factoria' has no export 'analytics_from_the_future'") != std::string::npos);
    CHECK(text.find("older than the game's engine") != std::string::npos);
}

TEST_CASE("a call the player lacks names the object and the method") {
    TestHost h("missing_call");
    h.file("scripts/calls.js",
           "import { Behaviour, scene } from \"factoria\";\n"
           "export default class Calls extends Behaviour { onStart() { scene.method_from_the_future(); } }\n");
    h.file("scenes/main.scene.json",
           R"({"format":"factoria.scene/1","entities":[{"id":"p","components":{"Script":{"path":"scripts/calls.js"}}}]})");
    REQUIRE(h.start());
    h.load_scene_now("scenes/main.scene.json");
    h.step_frames(2);
    REQUIRE_FALSE(h.scripts.errors().empty());
    const std::string text = h.scripts.errors().front().to_string();
    MESSAGE(text);
    CHECK(text.find("the engine's 'scene' from \"factoria\" has no 'method_from_the_future'") != std::string::npos);
    CHECK(text.find("older than the game's engine") != std::string::npos);
}

TEST_CASE("a method of an object that is not the engine's is not blamed on the player") {
    TestHost h("own_call");
    h.file("scripts/calls.js",
           "import { Behaviour } from \"factoria\";\n"
           "export default class Calls extends Behaviour { onStart() { const mine = {}; mine.nothing(); } }\n");
    h.file("scenes/main.scene.json",
           R"({"format":"factoria.scene/1","entities":[{"id":"p","components":{"Script":{"path":"scripts/calls.js"}}}]})");
    REQUIRE(h.start());
    h.load_scene_now("scenes/main.scene.json");
    h.step_frames(2);
    REQUIRE_FALSE(h.scripts.errors().empty());
    CHECK(h.scripts.errors().front().to_string().find("older than") == std::string::npos);
}
