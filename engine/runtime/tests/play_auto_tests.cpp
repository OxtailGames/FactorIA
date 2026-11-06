// play.auto's engine side (fa/runtime/play_auto.h): the bot hook and the explorer, the session it writes, determinism, replay,
// and the stuck / broken detection. Every run here is a few game seconds and no GPU, far below any time cap.
#include <filesystem>
#include <set>

#include "doctest.h"
#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/play_auto.h"
#include "fa/runtime/play_session.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

constexpr const char* kPlayerScript = R"(
import { Behaviour, input } from "factoria";
export default class P extends Behaviour {
  onStart() { this.body = this.entity.get("RigidBody2D"); }
  onUpdate() {
    this.body.velocity.x = input.axis("move_left", "move_right") * 100;
    if (input.pressed("jump") && this.entity.isGrounded()) this.body.velocity.y = 300;
  }
}
)";

// Walks right; ends the run "won" at x > 150 and says where it stopped (the replay must end at the same place).
constexpr const char* kWalkHook = R"(
import { game, world } from "factoria";
game.autoplay((bot) => {
  const p = world.find("p");
  if (p.position.x > 150) return { end: "won", score: 5, note: "x=" + p.position.x.toFixed(3) };
  return bot.rng.chance(0.02) ? ["move_right", "jump"] : ["move_right"];
});
)";

struct AutoProject {
    stdfs::path dir = fs::make_temp_dir("fa_play_auto");
    // groundY: where the ground is; a ground "none" leaves the player to fall.
    explicit AutoProject(bool ground = true, const char* hook = nullptr) {
        stdfs::create_directories(dir / "scenes");
        stdfs::create_directories(dir / "scripts");
        write("factoria.json", R"({"format":"factoria.project/1","name":"Auto","id":"com.example.auto","mainScene":"scenes/main.scene.json",
            "display":{"width":128,"height":128},"physics":{"fixedHz":60,"pixelsPerMeter":100},
            "input":{"actions":{"move_left":["A"],"move_right":["D"],"jump":["Space"]}}})");
        std::string entities = R"({"id":"cam","components":{"Camera":{}}},
            {"id":"p","name":"Player","tags":["player"],"components":{"Transform":{"position":[0,20,0]},
              "RigidBody2D":{"type":"dynamic","fixedRotation":true},"Collider2D":{"shape":"box","size":[20,20],"friction":0},
              "Script":{"path":"scripts/player.js"}}})";
        if (ground)
            entities += R"(,{"id":"g","components":{"Transform":{"position":[0,-10,0]},"RigidBody2D":{"type":"static"},
              "Collider2D":{"shape":"box","size":[4000,20]}}})";
        write("scenes/main.scene.json", std::string(R"({"format":"factoria.scene/1","settings":{"gravity2D":[0,-980]},"entities":[)") + entities + "]}");
        write("scripts/player.js", kPlayerScript);
        if (hook) write("scripts/autoplay.js", hook);
    }
    ~AutoProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    void write(const char* rel, const std::string& text) const { REQUIRE(fs::write_text((dir / rel).generic_string(), text).ok()); }
    EngineConfig config(bool graphics = false) const {
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.graphics = graphics;
        return c;
    }
    Json read_session(const Json& result) const {
        auto j = load_json_file((dir / ".factoria" / "sessions" / result["session"].get<std::string>() / "session.json").generic_string());
        REQUIRE(j.ok());
        return j.value();
    }
    Json read_input(const Json& result) const {
        auto j = load_json_file((dir / ".factoria" / "sessions" / result["session"].get<std::string>() / "input.json").generic_string());
        REQUIRE(j.ok());
        return j.value();
    }
};

Json run(const AutoProject& p, PlayAutoOptions o = {}) {
    o.screenshots = false;
    auto r = play_auto(p.config(), o);
    const bool ok = r.ok();
    const std::string why = ok ? std::string() : r.error().message;
    REQUIRE_MESSAGE(ok, why);
    return r.value();
}

// The numbers a second run must reproduce (everything but the session name and the frame times).
Json stable(const Json& r) {
    Json phases = Json::array();
    for (const Json& ph : r["phases"]) phases.push_back(Json::object({{"name", ph["name"]}, {"kind", ph["kind"]}, {"time", ph["time"]}}));
    Json problems = Json::array();
    for (const Json& m : r["problems"]) problems.push_back(Json::object({{"kind", m["kind"]}, {"step", m["step"]}, {"time", m["time"]}, {"note", m["note"]}}));
    return Json::object({{"ended", r["ended"]}, {"endedWhy", r["endedWhy"]}, {"score", r["score"]}, {"gameSeconds", r["gameSeconds"]},
                         {"steps", r["steps"]}, {"frames", r["frames"]}, {"bot", r["bot"]}, {"phases", phases}, {"problems", problems}});
}

bool notes_contain(const Json& r, const std::string& text) {
    for (const Json& n : r["notes"])
        if (n.get<std::string>().find(text) != std::string::npos) return true;
    return false;
}

}  // namespace

TEST_CASE("play.auto: the hook plays and ends the run, and the session is a play session") {
    AutoProject p(true, kWalkHook);
    const Json r = run(p, {.seconds = 30});
    CHECK(r["ended"] == "won");
    CHECK(r["score"] == 5);
    CHECK(r["bot"] == "hook");
    CHECK(r["gameSeconds"].get<double>() > 0.5);
    CHECK(r["gameSeconds"].get<double>() < 10.0);
    REQUIRE(r["phases"].size() == 1);
    CHECK(r["phases"][0]["name"] == "scenes/main.scene.json");
    CHECK(r["phases"][0]["kind"] == "scene");
    CHECK(r["problems"].size() == 0);
    CHECK(notes_contain(r, "bot: x="));
    CHECK(r["replay"].get<std::string>().find("--input") != std::string::npos);

    const Json s = p.read_session(r);
    CHECK(s["source"] == "auto");
    CHECK(s["ended"] == "won");
    CHECK(s["phases"].size() == 1);
    CHECK(s["auto"]["bot"] == "hook");

    // play.report and play.sessions read it unchanged.
    Engine e;
    EngineConfig c = p.config();
    c.headless = true;
    c.hotReload = false;
    std::string err;
    REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
    auto rep = e.commands().call("play.report", Json{{"session", r["session"]}});
    REQUIRE(rep.ok);
    CHECK(rep.result["source"] == "auto");
    CHECK(rep.result["ended"] == "won");
    CHECK(rep.result["phases"].size() == 1);
    auto list = e.commands().call("play.sessions", Json::object());
    REQUIRE(list.ok);
    CHECK(list.result["sessions"][0]["source"] == "auto");
    CHECK(list.result["sessions"][0]["ended"] == "won");
    e.shutdown();
}

TEST_CASE("play.auto: the same seed plays the same game, another seed another one") {
    AutoProject p(true, kWalkHook);
    const Json a = run(p, {.seconds = 30, .seed = 7});
    const Json b = run(p, {.seconds = 30, .seed = 7});
    CHECK(a["session"] != b["session"]);  // two sessions, not one overwritten
    CHECK(stable(a) == stable(b));
    CHECK(p.read_input(a) == p.read_input(b));

    // The explorer: the same seed presses the same things.
    AutoProject q;
    const Json c = run(q, {.seconds = 4, .seed = 3});
    const Json d = run(q, {.seconds = 4, .seed = 3});
    const Json e = run(q, {.seconds = 4, .seed = 4});
    CHECK(c["bot"] == "explorer");
    CHECK(stable(c) == stable(d));
    CHECK(q.read_input(c) == q.read_input(d));
    CHECK(q.read_input(c) != q.read_input(e));
}

TEST_CASE("play.auto: without a hook the explorer plays and says so") {
    AutoProject p;
    const Json r = run(p, {.seconds = 3});
    CHECK(r["bot"] == "explorer");
    CHECK(r["ended"] == "timeout");
    CHECK(r["gameSeconds"].get<double>() == doctest::Approx(3.0).epsilon(0.02));
    CHECK(notes_contain(r, "no scripts/autoplay.js"));
    CHECK(p.read_input(r)["frames"].size() > 0);  // it pressed something

    const Json forced = run(AutoProject(true, kWalkHook), {.seconds = 2});  // bot "explorer" asks to ignore a hook that exists
    CHECK(forced["bot"] == "hook");
    AutoProject h(true, kWalkHook);
    PlayAutoOptions o;
    o.seconds = 2;
    o.useHook = false;
    const Json ex = run(h, o);
    CHECK(ex["bot"] == "explorer");
    CHECK(notes_contain(ex, "switched off"));
}

TEST_CASE("play.auto: the recorded input replays to the same state, at any speed") {
    for (int speed : {1, 4}) {
        CAPTURE(speed);
        AutoProject p(true, kWalkHook);
        PlayAutoOptions o;
        o.seconds = 30;
        o.speed = speed;
        const Json r = run(p, o);
        REQUIRE(r["ended"] == "won");
        std::string noted;
        for (const Json& n : r["notes"])
            if (n.get<std::string>().rfind("bot: x=", 0) == 0) noted = n.get<std::string>().substr(7);
        REQUIRE_FALSE(noted.empty());

        HeadlessRunOptions h;
        h.frames = r["frames"].get<int>();
        h.inputReplayPath = (p.dir / ".factoria" / "sessions" / r["session"].get<std::string>() / "input.json").generic_string();
        h.stateOutPath = (p.dir / "state.json").generic_string();
        EngineConfig c = p.config();
        c.seed = 1;
        Json report;
        CHECK(run_headless(c, h, &report) == 0);
        auto st = load_json_file(h.stateOutPath);
        REQUIRE(st.ok());
        double x = -1e9;
        for (const Json& e : st.value()["entities"])
            if (e["id"] == "p") x = e["components"]["Transform"]["position"][0].get<double>();
        char buf[64];
        std::snprintf(buf, sizeof buf, "%.3f", x);
        CHECK(std::string(buf) == noted);
    }
}

TEST_CASE("play.auto: speed runs more fixed steps per frame") {
    AutoProject p(true, kWalkHook);
    PlayAutoOptions o;
    o.seconds = 30;
    o.speed = 4;
    const Json r = run(p, o);
    CHECK(r["speed"] == 4);
    CHECK(r["steps"].get<int>() >= 3 * r["frames"].get<int>());
    CHECK(p.read_input(r).contains("timing"));
}

TEST_CASE("play.auto: nothing moving for stuckSeconds is a stuck mark with the step") {
    AutoProject p(true, "import { game } from \"factoria\";\ngame.autoplay(() => []);\n");
    PlayAutoOptions o;
    o.seconds = 30;
    o.stuckSeconds = 1;
    const Json r = run(p, o);
    CHECK(r["ended"] == "stuck");
    CHECK(r["gameSeconds"].get<double>() < 5.0);
    REQUIRE(r["problems"].size() == 1);
    CHECK(r["problems"][0]["kind"] == "stuck");
    CHECK(r["problems"][0]["step"].get<int>() > 0);
    CHECK(r["problems"][0]["note"].get<std::string>().find("nothing moved") != std::string::npos);
    const Json s = p.read_session(r);
    CHECK(s["marks"].size() == 1);
    CHECK(s["marks"][0]["kind"] == "stuck");
}

TEST_CASE("play.auto: a player that falls out of the world is a fall") {
    AutoProject p(false, "import { game } from \"factoria\";\ngame.autoplay(() => [\"move_right\"]);\n");
    PlayAutoOptions o;
    o.seconds = 20;
    o.stuckSeconds = 15;
    const Json r = run(p, o);
    CHECK(r["ended"] == "broken");
    REQUIRE(r["problems"].size() == 1);
    CHECK(r["problems"][0]["kind"] == "fall");
    CHECK(r["gameSeconds"].get<double>() < 10.0);
}

TEST_CASE("play.auto: a script that throws every frame is an exception loop") {
    AutoProject p(true, "import { game } from \"factoria\";\ngame.autoplay(() => [\"move_right\"]);\n");
    p.write("scripts/player.js", R"(
import { Behaviour } from "factoria";
export default class P extends Behaviour { onUpdate() { throw new Error("boom"); } }
)");
    PlayAutoOptions o;
    o.seconds = 30;
    o.stuckSeconds = 25;
    const Json r = run(p, o);
    CHECK(r["ended"] == "broken");
    REQUIRE(r["problems"].size() == 1);
    CHECK(r["problems"][0]["kind"] == "exception loop");
    CHECK(r["problems"][0]["note"].get<std::string>().find("boom") != std::string::npos);
    CHECK(r["scriptErrors"].size() >= 1);
}

TEST_CASE("play.auto: a screen nobody can leave is a menu soft lock") {
    AutoProject p(true, "import { game } from \"factoria\";\ngame.autoplay(() => []);\n");
    p.write("scenes/main.scene.json", R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}},
        {"id":"title","components":{"Transform":{"position":[0,0,0]},"Script":{"path":"scripts/title.js"}}}]})");
    p.write("scripts/title.js", "import { Behaviour } from \"factoria\";\nexport default class T extends Behaviour {}\n");
    PlayAutoOptions o;
    o.seconds = 30;
    o.stuckSeconds = 2;
    const Json r = run(p, o);
    CHECK(r["ended"] == "stuck");
    REQUIRE(r["problems"].size() == 1);
    CHECK(r["problems"][0]["kind"] == "menu");
}

TEST_CASE("play.auto: game.phase marks a stage and can end the run") {
    AutoProject p(true, "import { game } from \"factoria\";\ngame.autoplay((bot) => { if (bot.time > 0.5) game.phase(\"victory\", { ends: \"won\" }); return [\"move_right\"]; });\n");
    PlayAutoOptions o;
    o.seconds = 30;
    const Json r = run(p, o);
    CHECK(r["ended"] == "won");
    REQUIRE(r["phases"].size() == 2);
    CHECK(r["phases"][1]["name"] == "victory");
    CHECK(r["phases"][1]["kind"] == "mark");
}

TEST_CASE("play.auto: a hook that answers a name that is not an action is a script error with a hint") {
    AutoProject p(true, "import { game } from \"factoria\";\ngame.autoplay(() => [\"move_rigth\"]);\n");
    PlayAutoOptions o;
    o.seconds = 2;
    const Json r = run(p, o);
    CHECK(r["scriptErrors"].size() >= 1);
    CHECK(r["scriptErrors"][0].get<std::string>().find("did you mean \"move_right\"") != std::string::npos);
    CHECK(notes_contain(r, "The hook threw"));
}

TEST_CASE("play.auto: without a GPU the run happens and the notes say there are no pictures") {
    AutoProject p(true, kWalkHook);
    PlayAutoOptions o;
    o.seconds = 30;
    auto r = play_auto(p.config(false), o);  // graphics off, screenshots wanted
    REQUIRE(r.ok());
    CHECK(r.value()["ended"] == "won");
    CHECK(r.value()["screenshots"] == 0);
    CHECK(notes_contain(r.value(), "No screenshots"));
}

TEST_CASE("play.auto: bad arguments and a project that does not start are errors that say what to do") {
    AutoProject p(true, kWalkHook);
    PlayAutoOptions o;
    o.seconds = 0;
    auto a = play_auto(p.config(), o);
    REQUIRE_FALSE(a.ok());
    CHECK(a.error().message.find("seconds") != std::string::npos);
    o = {};
    o.speed = 99;
    auto b = play_auto(p.config(), o);
    REQUIRE_FALSE(b.ok());
    CHECK(b.error().message.find("speed") != std::string::npos);
    o = {};
    EngineConfig c = p.config();
    c.scene = "scenes/nope.scene.json";
    auto d = play_auto(c, o);
    REQUIRE_FALSE(d.ok());
    CHECK_FALSE(d.error().hint.empty());
}

TEST_CASE("play.report: an automatic session lists its marks and phases, and phase and mark are not combined") {
    AutoProject p(true, "import { game } from \"factoria\";\ngame.autoplay(() => []);\n");
    PlayAutoOptions o;
    o.seconds = 30;
    o.stuckSeconds = 1;
    const Json r = run(p, o);
    REQUIRE(r["ended"] == "stuck");
    Engine e;
    EngineConfig c = p.config();
    c.headless = true;
    c.hotReload = false;
    std::string err;
    REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
    auto rep = e.commands().call("play.report", Json{{"session", r["session"]}});
    REQUIRE(rep.ok);
    CHECK(rep.result["marks"].size() == 1);
    CHECK(rep.result["marks"][0]["kind"] == "stuck");
    CHECK(rep.result["marks"][0]["step"] == r["problems"][0]["step"]);
    CHECK(rep.result["ended"] == "stuck");
    CHECK(rep.result["replayHow"].get<std::string>().find("--input") != std::string::npos);
    auto both = e.commands().call("play.report", Json{{"session", r["session"]}, {"mark", 1}, {"phase", 1}});
    CHECK_FALSE(both.ok);
    auto far = e.commands().call("play.report", Json{{"session", r["session"]}, {"phase", 9}});
    CHECK_FALSE(far.ok);
    e.shutdown();
}
