// nav.findPath from scripts: a guard walks around a wall to the player; the errors teach.
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {
Json eval_ok(TestHost& h, const char* code) {
    auto r = h.scripts.eval(code);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    return r.value();
}
std::string eval_err(TestHost& h, const char* code) {
    auto r = h.scripts.eval(code);
    REQUIRE_FALSE(r.ok());
    return r.error().to_string();
}
}  // namespace

TEST_CASE("nav.findPath: a guard reaches the player around a wall") {
    TestHost h("nav_guard");
    h.file("scripts/guard.js", R"(
import { Behaviour, nav, world, vec3 } from "factoria";
globalThis.NAV = { maxZ: 0, calls: 0, found: 0, crossed: false };
export default class Guard extends Behaviour {
  onUpdate(dt) {
    const player = world.find("player");
    const p = nav.findPath(this.entity.position, player.position);
    NAV.calls++;
    if (!p.found) return;
    NAV.found++;
    // walk towards the first corner after the one we stand on
    const pos = this.entity.position;
    let target = p.points[p.points.length > 1 ? 1 : 0];
    const dx = target.x - pos.x, dz = target.z - pos.z, d = Math.hypot(dx, dz);
    const step = Math.min(d, 6 * dt);
    if (d > 1e-4) this.entity.position = vec3(pos.x + dx / d * step, pos.y, pos.z + dz / d * step);
    const q = this.entity.position;
    NAV.maxZ = Math.max(NAV.maxZ, Math.abs(q.z));
    if (Math.abs(q.x) < 0.2 && Math.abs(q.z) < 6) NAV.crossed = true;
  }
}
)");
    Json ents = Json::array();
    ents.push_back(Json::parse(R"({"id":"floor","components":{"Transform":{"position":[0,-0.5,0]},"Collider3D":{"size":[40,1,40]}}})"));
    ents.push_back(Json::parse(R"({"id":"wall","components":{"Transform":{"position":[0,1.5,0]},"Collider3D":{"size":[0.4,3,12]}}})"));
    ents.push_back(Json::parse(R"({"id":"navmesh","components":{"Transform":{"position":[0,2,0]},"NavMesh3D":{"size":[40,6,40]}}})"));
    ents.push_back(Json::parse(R"({"id":"player","components":{"Transform":{"position":[5,0,0]}}})"));
    ents.push_back(Json::parse(R"({"id":"guard","components":{"Transform":{"position":[-5,0,0]},"Script":{"path":"scripts/guard.js"}}})"));
    h.file("scenes/main.scene.json", Json::object({{"format", "factoria.scene/1"}, {"entities", ents}}).dump());
    REQUIRE(h.start());
    CHECK(h.load_scene_now("scenes/main.scene.json").empty());
    h.step_frames(600);
    CHECK(h.scripts.errors().empty());
    CHECK(eval_ok(h, "NAV.found").get<int>() > 100);
    CHECK(eval_ok(h, "NAV.crossed") == false);
    CHECK(eval_ok(h, "NAV.maxZ").get<double>() > 5.5);  // went round the end of the wall at z = 6
    CHECK(eval_ok(h, "world.find('guard').position.x").get<double>() > 4.0);
}

TEST_CASE("nav.findPath: results and errors explain themselves") {
    TestHost h("nav_errors");
    h.file("scenes/main.scene.json", Json::object({{"format", "factoria.scene/1"}, {"entities", Json::array({
        Json::parse(R"({"id":"floor","components":{"Transform":{"position":[0,-0.5,0]},"Collider3D":{"size":[20,1,20]}}})"),
        Json::parse(R"({"id":"navmesh","components":{"Transform":{"position":[0,2,0]},"NavMesh3D":{"size":[20,6,20]}}})")})}}).dump());
    REQUIRE(h.start());
    CHECK(h.load_scene_now("scenes/main.scene.json").empty());
    h.step_frames(2);
    CHECK(eval_ok(h, "nav.findPath([-5, 0, 0], [5, 0, 0]).found") == true);
    CHECK(eval_ok(h, "nav.findPath([-5, 0, 0], vec3(5, 0, 0)).points.length").get<int>() >= 1);
    CHECK(eval_ok(h, "nav.findPath([-5, 0, 0], [5, 0, 0]).length").get<double>() == doctest::Approx(10.0).epsilon(0.01));
    CHECK(eval_ok(h, "nav.findPath([-5, 0, 0], [50, 0, 0]).reason") == "goal_off_mesh");
    CHECK(eval_ok(h, "nav.findPath([-5, 0, 0], [50, 0, 0]).message").get<std::string>().find("outside the bounds") != std::string::npos);
    const std::string m = eval_err(h, "nav.findPath([-5, 0, 0], [5, 0, 0], { radius: 2 })");
    CHECK(m.find("larger than") != std::string::npos);
    CHECK(m.find("agentRadius") != std::string::npos);
    CHECK(eval_ok(h, "nav.bake()[0].mesh") == "navmesh");
}
