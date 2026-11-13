// IK2D ground snapping through the real engine: the fixed step builds the ray callback from the 2D physics world
// (docs/ANIMATION.md, "Bones and IK", "Planted feet").
#include <filesystem>
#include <string>

#include "doctest.h"
#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/scene/bones2d.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

// A static character with its own collider (the ray must ignore it), a two-bone leg of 10 + 10 hanging from it, a marker at
// (0, -15) and a floor whose top is at y = -18.
std::string scene_json(int groundMask) {
    return std::string(R"({"format":"factoria.scene/1","entities":[
      {"id":"cam","components":{"Camera":{}}},
      {"id":"floor","components":{"Transform":{"position":[0,-28,0]},"RigidBody2D":{"type":"static"},
                                  "Collider2D":{"size":[200,20]}}},
      {"id":"marker","components":{"Transform":{"position":[0,-15,0]}}},
      {"id":"hero","components":{"Transform":{},"RigidBody2D":{"type":"static"},"Collider2D":{"size":[10,10]}},
       "children":[{"id":"thigh","components":{"Transform":{"rotation":[0,0,-90]},"Bone2D":{"length":10}},
        "children":[{"id":"shin","components":{"Transform":{"position":[10,0,0]},"Bone2D":{"length":10},
          "IK2D":{"target":"marker","bend":"negative","groundMask":)") +
           std::to_string(groundMask) + R"(,"groundReach":20,"groundOffset":1,"groundRest":-15}}}]}]}]})";
}

}  // namespace

TEST_CASE("ik2d ground: the engine casts the foot ray into the 2D physics world") {
    for (int mask : {0, 1}) {
        const stdfs::path dir = fs::make_temp_dir("fa_ik2d_ground").value();
        REQUIRE(fs::write_text(
                    (dir / "factoria.json").generic_string(),
                    R"({"format":"factoria.project/1","name":"G","id":"com.example.g","mainScene":"main.scene.json",
                                   "display":{"width":64,"height":64},"physics":{"fixedHz":60}})")
                    .ok());
        REQUIRE(fs::write_text((dir / "main.scene.json").generic_string(), scene_json(mask)).ok());
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.hotReload = false;
        c.memoryStorage = true;
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
        for (int i = 0; i < 4; ++i) e.frame(1.0 / 60.0 + 1e-5);
        const Entity shin = e.world().find("shin");
        REQUIRE(!shin.is_null());
        const float tipY = bone_world_segment(e.world(), shin).tip.y;
        // Off: the tip reaches the marker (-15). On: the ray finds the floor top (-18), + offset 1 = -17 (the marker, at its
        // rest height, adds no lift).
        CHECK(tipY == doctest::Approx(mask == 0 ? -15.0f : -17.0f).epsilon(0.01));
        e.shutdown();
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
}
