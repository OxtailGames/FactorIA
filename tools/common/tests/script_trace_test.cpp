// script.trace (fa/tooling/script_trace.h) end to end: the real instrumenter and the real script runtime on a project made
// from the 2d-platformer template (scripts/player.js: line 16 `onUpdate(dt) {`, line 17 its first statement).
#include <doctest.h>

#include <filesystem>

#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/tooling.h"
#include "test_helpers.h"

using namespace fa;
using fa::testing::TempDir;

namespace {

struct Platformer {
    TempDir dir;
    CommandRegistry reg;
    Platformer() {
        REQUIRE(create_project(dir.str(), "2d-platformer").ok());
        register_tooling_commands(reg, dir.str());
    }
    CommandResult trace(const Json& args) { return reg.call("script.trace", args); }
};

Json point(int line, const Json& extra = Json::object()) {
    Json p = Json::object({{"file", "scripts/player.js"}, {"line", line}});
    for (auto it = extra.begin(); it != extra.end(); ++it) p[it.key()] = it.value();
    return p;
}

Json args(const Json& points, int frames = 10, int maxHits = 20, int depth = 1) {
    return Json::object({{"points", points}, {"frames", frames}, {"maxHits", maxHits}, {"depth", depth}});
}

}  // namespace

TEST_CASE("script.trace: a hit at player.js:17 records the function, the stack, the locals and a watch") {
    Platformer p;
    CHECK(p.reg.has("script.trace"));
    CommandResult r = p.trace(args(Json::array({point(17, Json::object({{"watch", Json::array({"this.speed", "dt", "nope.x"})}}))}), 10));
    REQUIRE(r.ok);
    const Json& out = r.result;
    CHECK(out["framesRun"] == 10);
    CHECK(out["truncated"] == false);
    CHECK(out["errors"].empty());
    REQUIRE(out["hits"].size() == 10);  // onUpdate runs once per frame
    const Json& h = out["hits"][0];
    CHECK(h["point"] == 0);
    CHECK(h["frame"] == 0);
    CHECK(h["file"] == "scripts/player.js");
    CHECK(h["line"] == 17);
    CHECK(h["function"] == "Player.onUpdate");
    CHECK(h["stack"][0] == "Player.onUpdate scripts/player.js:17");
    CHECK(h["locals"].contains("dt"));
    CHECK(h["locals"]["dt"].is_number());
    CHECK(h["locals"].contains("this"));
    CHECK(h["locals"]["this"].is_object());  // depth 1: one level of fields
    CHECK(h["locals"]["this"]["speed"] == 300);
    CHECK(h["locals"]["this"]["jumpSpeed"] == 620);
    CHECK(h["watch"]["this.speed"] == 300);
    CHECK(h["watch"]["dt"].is_number());
    CHECK(h["watch"]["nope.x"].get<std::string>().starts_with("<error"));
    CHECK(out["hits"][9]["frame"] == 9);
}

TEST_CASE("script.trace: depth 0 gives previews, depth 1 expands one level") {
    Platformer p;
    Json d0 = p.trace(args(Json::array({point(17)}), 2, 1, 0)).result;
    REQUIRE(d0["hits"].size() == 1);
    CHECK(d0["hits"][0]["locals"]["this"].is_string());  // "Player {speed: 300, ...}"
    CHECK(d0["hits"][0]["locals"]["this"].get<std::string>().find("speed: 300") != std::string::npos);
    CHECK(d0["hits"][0]["locals"]["dt"].is_number());  // numbers stay numbers at every depth

    Json d1 = p.trace(args(Json::array({point(17, Json::object({{"watch", Json::array({"this"})}}))}), 2, 1, 1)).result;
    CHECK(d1["hits"][0]["locals"]["this"].is_object());
    CHECK(d1["hits"][0]["watch"]["this"]["speed"] == 300);
    CHECK(d1["hits"][0]["locals"]["this"]["entity"].is_string());  // below the depth: a preview
}

TEST_CASE("script.trace: a condition filters, a logpoint writes logs and records no hit") {
    Platformer p;
    CommandResult none = p.trace(args(Json::array({point(17, Json::object({{"condition", "this.speed > 1000"}}))})));
    REQUIRE(none.ok);
    CHECK(none.result["hits"].empty());
    CHECK(none.result["framesRun"] == 10);

    CommandResult some = p.trace(args(Json::array({point(17, Json::object({{"condition", "this.speed == 300"}}))}), 4));
    REQUIRE(some.ok);
    CHECK(some.result["hits"].size() == 4);

    CommandResult logp = p.trace(args(Json::array({point(17, Json::object({{"log", "speed={this.speed} jump={this.jumpSpeed}"}}))}), 3));
    REQUIRE(logp.ok);
    CHECK(logp.result["hits"].empty());
    REQUIRE(logp.result["logs"].size() == 3);
    CHECK(logp.result["logs"][0]["text"] == "speed=300 jump=620");
    CHECK(logp.result["logs"][0]["file"] == "scripts/player.js");
    CHECK(logp.result["logs"][0]["line"] == 17);
    CHECK(logp.result["logs"][2]["frame"] == 2);

    // A condition that throws is reported, not swallowed.
    CommandResult broken = p.trace(args(Json::array({point(17, Json::object({{"condition", "nothing.here > 1"}}))}), 2));
    REQUIRE(broken.ok);
    CHECK_FALSE(broken.result["errors"].empty());
}

TEST_CASE("script.trace: maxHits stops a point and sets truncated, only when there was more") {
    Platformer p;
    CommandResult r = p.trace(args(Json::array({point(17)}), 10, 3));
    REQUIRE(r.ok);
    CHECK(r.result["hits"].size() == 3);
    CHECK(r.result["truncated"] == true);
    CHECK(r.result["framesRun"] == 10);

    CommandResult exact = p.trace(args(Json::array({point(17)}), 3, 3));
    REQUIRE(exact.ok);
    CHECK(exact.result["hits"].size() == 3);
    CHECK(exact.result["truncated"] == false);

    CommandResult logs = p.trace(args(Json::array({point(17, Json::object({{"log", "x"}}))}), 10, 2));
    REQUIRE(logs.ok);
    CHECK(logs.result["logs"].size() == 2);
    CHECK(logs.result["truncated"] == true);
}

TEST_CASE("script.trace: the same input gives the same output") {
    Platformer p;
    const Json a = args(Json::array({point(17, Json::object({{"watch", Json::array({"this.speed", "dt"})}}))}), 20);
    CHECK(p.trace(a).result == p.trace(a).result);
}

TEST_CASE("script.trace: a line without a statement names the nearest breakable lines") {
    Platformer p;
    // Line 15 is blank, between `}` of onStart (14) and `onUpdate(dt) {` (16), which is not a statement either.
    CommandResult r = p.trace(args(Json::array({point(17), point(15)})));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "invalid_argument");
    const std::string msg = r.error["message"].get<std::string>();
    CHECK(msg.starts_with("/points/1/line:"));
    CHECK(msg.find("no statement") != std::string::npos);
    CHECK(msg.find("line 13") != std::string::npos);  // `this.body = ...` in onStart
    CHECK(msg.find("line 17") != std::string::npos);

    CommandResult far = p.trace(args(Json::array({point(999)})));
    REQUIRE_FALSE(far.ok);
    CHECK(far.error["message"].get<std::string>().find("Nearest lines") != std::string::npos);
}

TEST_CASE("script.trace: a file that is not a project script suggests the closest ones") {
    Platformer p;
    Json bad = Json::object({{"file", "scripts/plyer.js"}, {"line", 17}});
    CommandResult r = p.trace(args(Json::array({point(17), bad})));
    REQUIRE_FALSE(r.ok);
    const std::string msg = r.error["message"].get<std::string>();
    CHECK(msg.starts_with("/points/1/file:"));
    CHECK(msg.find("scripts/player.js") != std::string::npos);  // did you mean

    CHECK_FALSE(p.trace(Json::object({{"points", Json::array()}})).ok);
    CommandResult typo = p.trace(Json::object({{"points", Json::array({point(17)})}, {"frame", 5}}));
    REQUIRE_FALSE(typo.ok);
    CHECK(typo.error["hint"].get<std::string>().find("Did you mean 'frames'") != std::string::npos);
}

TEST_CASE("script.trace: a script error raised during the run goes to errors") {
    Platformer p;
    const std::string path = p.dir.sub("scripts/player.js");
    std::string src = fa::testing::read_all(path);
    const std::string from = "this.body.velocity.x = input.axis(\"move_left\", \"move_right\") * this.speed;";
    const auto at = src.find(from);
    REQUIRE(at != std::string::npos);
    src.replace(at, from.size(), "if (this.speed === 300) throw new Error(\"boom\");");
    fa::testing::write_all(path, src);

    CommandResult r = p.trace(args(Json::array({point(17)}), 3));
    REQUIRE(r.ok);
    CHECK(r.result["framesRun"] == 3);
    CHECK(r.result["hits"].size() >= 1);
    REQUIRE_FALSE(r.result["errors"].empty());
    CHECK(r.result["errors"][0].get<std::string>().find("boom") != std::string::npos);
}
