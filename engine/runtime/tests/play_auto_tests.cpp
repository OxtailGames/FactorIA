// play.auto's engine side (fa/runtime/play_auto.h): the bot hook and the explorer, the session it writes, determinism, replay,
// and the stuck / broken detection. Every run here is a few game seconds and no GPU, far below any time cap.
#include <chrono>
#include <cstdio>
#include <filesystem>
#include <set>

#include "doctest.h"
#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/play_auto.h"
#include "fa/runtime/play_session.h"

#if defined(_WIN32)
#include <process.h>
#else
#include <unistd.h>
#endif

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
    stdfs::path root = fs::make_temp_dir("fa_play_auto").value();
    stdfs::path dir = root;
    // ground false leaves the player to fall; `folder` names the project folder inside the temp one (accents: the project of a user).
    explicit AutoProject(bool ground = true, const char* hook = nullptr, const stdfs::path& folder = {}) {
        if (!folder.empty()) dir /= folder;
        stdfs::create_directories(dir / "scenes");
        stdfs::create_directories(dir / "scripts");
        write(
            "factoria.json",
            R"({"format":"factoria.project/1","name":"Auto","id":"com.example.auto","mainScene":"scenes/main.scene.json",
            "display":{"width":128,"height":128},"physics":{"fixedHz":60,"pixelsPerMeter":100},
            "input":{"actions":{"move_left":["A"],"move_right":["D"],"jump":["Space"]}}})");
        std::string entities = R"({"id":"cam","components":{"Camera":{}}},
            {"id":"p","name":"Player","tags":["player"],"components":{"Transform":{"position":[0,20,0]},
              "RigidBody2D":{"type":"dynamic","fixedRotation":true},"Collider2D":{"shape":"box","size":[20,20],"friction":0},
              "Script":{"path":"scripts/player.js"}}})";
        if (ground)
            entities += R"(,{"id":"g","components":{"Transform":{"position":[0,-10,0]},"RigidBody2D":{"type":"static"},
              "Collider2D":{"shape":"box","size":[4000,20]}}})";
        write("scenes/main.scene.json",
              std::string(R"({"format":"factoria.scene/1","settings":{"gravity2D":[0,-980]},"entities":[)") + entities +
                  "]}");
        write("scripts/player.js", kPlayerScript);
        if (hook) write("scripts/autoplay.js", hook);
    }
    ~AutoProject() {
        std::error_code ec;
        stdfs::remove_all(root, ec);
    }
    void write(const char* rel, const std::string& text) const {
        REQUIRE(fs::write_text((dir / rel).generic_string(), text).ok());
    }
    EngineConfig config(bool graphics = false) const {
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.graphics = graphics;
        return c;
    }
    Json read_session(const Json& result) const {
        auto j = load_json_file(
            (dir / ".factoria" / "sessions" / result["session"].get<std::string>() / "session.json").generic_string());
        REQUIRE(j.ok());
        return j.value();
    }
    Json read_input(const Json& result) const {
        auto j = load_json_file(
            (dir / ".factoria" / "sessions" / result["session"].get<std::string>() / "input.json").generic_string());
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
    for (const Json& ph : r["phases"])
        phases.push_back(Json::object({{"name", ph["name"]}, {"kind", ph["kind"]}, {"time", ph["time"]}}));
    Json problems = Json::array();
    for (const Json& m : r["problems"])
        problems.push_back(
            Json::object({{"kind", m["kind"]}, {"step", m["step"]}, {"time", m["time"]}, {"note", m["note"]}}));
    return Json::object({{"ended", r["ended"]},
                         {"endedWhy", r["endedWhy"]},
                         {"score", r["score"]},
                         {"gameSeconds", r["gameSeconds"]},
                         {"steps", r["steps"]},
                         {"frames", r["frames"]},
                         {"bot", r["bot"]},
                         {"phases", phases},
                         {"problems", problems}});
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

    const Json withHook =
        run(AutoProject(true, kWalkHook), {.seconds = 2});  // the default (useHook) plays a hook that exists
    CHECK(withHook["bot"] == "hook");
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
        h.inputReplayPath =
            (p.dir / ".factoria" / "sessions" / r["session"].get<std::string>() / "input.json").generic_string();
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
    p.write("scenes/main.scene.json",
            R"({"format":"factoria.scene/1","entities":[{"id":"cam","components":{"Camera":{}}},
        {"id":"title","components":{"Transform":{"position":[0,0,0]},"Script":{"path":"scripts/title.js"}}}]})");
    p.write("scripts/title.js",
            "import { Behaviour } from \"factoria\";\nexport default class T extends Behaviour {}\n");
    PlayAutoOptions o;
    o.seconds = 30;
    o.stuckSeconds = 2;
    const Json r = run(p, o);
    CHECK(r["ended"] == "stuck");
    REQUIRE(r["problems"].size() == 1);
    CHECK(r["problems"][0]["kind"] == "menu");
}

TEST_CASE("play.auto: game.phase marks a stage and can end the run") {
    AutoProject p(true, "import { game } from \"factoria\";\ngame.autoplay((bot) => { if (bot.time > 0.5) "
                        "game.phase(\"victory\", { ends: \"won\" }); return [\"move_right\"]; });\n");
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

// ---- the review round: paths, false falls, a hook that does not load, signs of progress, pictures --------------------------------------

namespace {
constexpr const char* kNoHook = "import { game } from \"factoria\";\ngame.autoplay(() => []);\n";
const char* kEmptyScene = R"({"format":"factoria.scene/1","settings":{"gravity2D":[0,0]},"entities":[)";
}  // namespace

TEST_CASE("play.auto: a project folder with accents gives UTF-8 paths that exist and a result that dumps") {
    AutoProject p(true, kWalkHook, stdfs::path(u8"Cañón niño"));
    const Json r = run(p, {.seconds = 30});
    CHECK(r["ended"] == "won");
    const std::string dump = r.dump();  // throws on a byte sequence that is not UTF-8
    CHECK_FALSE(dump.empty());
    const std::string dir = r["dir"].get<std::string>();
    CHECK(dir.find("Ca\xC3\xB1\xC3\xB3n ni\xC3\xB1o") !=
          std::string::npos);  // the folder's name as UTF-8, not the code page's version
    std::error_code ec;
    CHECK(stdfs::exists(fs::os_path(fs::path_from_utf8(dir)) / "session.json", ec));
    CHECK(stdfs::exists(fs::os_path(fs::path_from_utf8(dir)) / "input.json", ec));
    CHECK_FALSE(p.read_session(r).dump().empty());

    Engine e;
    EngineConfig c = p.config();
    c.headless = true;
    c.hotReload = false;
    std::string err;
    REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
    auto rep = e.commands().call("play.report", Json{{"session", r["session"]}});
    REQUIRE(rep.ok);
    CHECK_FALSE(rep.result.dump().empty());
    CHECK(rep.result["replay"].get<std::string>().find("Ca\xC3\xB1\xC3\xB3n ni\xC3\xB1o") != std::string::npos);
    CHECK(stdfs::exists(fs::os_path(fs::path_from_utf8(rep.result["replay"].get<std::string>())), ec));
}

TEST_CASE("play.auto: a top-down game without gravity never falls out of the world") {
    AutoProject p(false, kNoHook);
    p.write("scenes/main.scene.json", std::string(kEmptyScene) + R"({"id":"cam","components":{"Camera":{}}},
        {"id":"p","name":"Player","tags":["player"],"components":{"Transform":{"position":[0,0,0]},
          "RigidBody2D":{"type":"dynamic","fixedRotation":true},"Collider2D":{"shape":"box","size":[20,20]},"Script":{"path":"scripts/player.js"}}}]})");
    p.write("scripts/player.js", R"(
import { Behaviour } from "factoria";
export default class P extends Behaviour {
  onStart() { this.body = this.entity.get("RigidBody2D"); }
  onUpdate() { this.body.velocity.y = -400; }   // walks down for ever: 4 pixels a step, far below the start in 5 seconds
}
)");
    PlayAutoOptions o;
    o.seconds = 6;
    o.stuckSeconds = 5;
    const Json r = run(p, o);
    CHECK(r["ended"] == "timeout");
    CHECK(r["problems"].size() == 0);
}

TEST_CASE("play.auto: a world a script generates after the start moves the fall limit") {
    AutoProject p(false, kNoHook);
    p.write("scenes/main.scene.json", R"({"format":"factoria.scene/1","settings":{"gravity2D":[0,-980]},"entities":[
        {"id":"cam","components":{"Camera":{},"Script":{"path":"scripts/generator.js"}}},
        {"id":"p","name":"Player","tags":["player"],"components":{"Transform":{"position":[0,20,0]},
          "RigidBody2D":{"type":"dynamic","fixedRotation":true},"Collider2D":{"shape":"box","size":[20,20]}}}]})");
    // The deep floor appears half a second in; the player passes the first guess of the limit (y -1000) on its way down.
    p.write("scripts/generator.js", R"(
import { Behaviour, world } from "factoria";
export default class G extends Behaviour {
  onUpdate() {
    this.n = (this.n || 0) + 1;
    if (this.n === 30) world.spawn({ id: "deep", components: { Transform: { position: [0, -3010, 0] },
      RigidBody2D: { type: "static" }, Collider2D: { shape: "box", size: [4000, 20] } } });
  }
}
)");
    PlayAutoOptions o;
    o.seconds = 6;
    o.stuckSeconds = 5;
    const Json r = run(p, o);
    CHECK(r["problems"].size() == 0);
    CHECK(r["ended"] == "timeout");
}

TEST_CASE("play.auto: a hook that cannot be loaded ends the run broken, and the explorer does not play in its place") {
    AutoProject p(true, "import { game } from \"factoria\";\ngame.autoplay((bot) => { return [ ;\n");  // a syntax error
    PlayAutoOptions o;
    o.seconds = 5;
    const Json r = run(p, o);
    CHECK(r["ended"] == "broken");
    CHECK(r["bot"] == "explorer");
    REQUIRE(r["problems"].size() == 1);
    CHECK(r["problems"][0]["kind"] == "hook");
    CHECK(r["problems"][0]["step"] == 0);
    CHECK(r["gameSeconds"].get<double>() == doctest::Approx(0.0));
    REQUIRE(r["scriptErrors"].size() >= 1);
    CHECK(r["scriptErrors"][0].get<std::string>().find("scripts/autoplay.js could not be loaded") != std::string::npos);
    CHECK_FALSE(r["endedWhy"].get<std::string>().empty());
}

TEST_CASE("play.auto: a hook file that never calls game.autoplay says so; bot hook makes it a problem") {
    AutoProject p(true, "// nothing here\n");
    PlayAutoOptions o;
    o.seconds = 2;
    const Json r = run(p, o);
    CHECK(r["bot"] == "explorer");
    CHECK(r["ended"] == "timeout");
    CHECK(notes_contain(r, "never called game.autoplay"));
    CHECK_FALSE(notes_contain(r, "has no scripts/autoplay.js"));

    o.hookRequired = true;
    const Json strict = run(p, o);
    CHECK(strict["ended"] == "broken");
    REQUIRE(strict["problems"].size() == 1);
    CHECK(strict["problems"][0]["kind"] == "hook");

    AutoProject none;
    PlayAutoOptions req;
    req.seconds = 2;
    req.hookRequired = true;
    const Json missing = run(none, req);
    CHECK(missing["ended"] == "broken");
    CHECK(missing["endedWhy"].get<std::string>().find("no scripts/autoplay.js") != std::string::npos);
}

namespace {
// A screen with no player whose label changes every `every` frames.
void label_project(AutoProject& p, int every) {
    p.write("scenes/main.scene.json", std::string(kEmptyScene) + R"({"id":"cam","components":{"Camera":{}}},
        {"id":"t","components":{"Transform":{"position":[0,0,0]},"Text":{"text":"turn 0"},"Script":{"path":"scripts/turns.js"}}}]})");
    p.write("scripts/turns.js",
            std::string("import { Behaviour } from \"factoria\";\nexport default class T extends Behaviour {\n"
                        "  onUpdate() { this.n = (this.n || 0) + 1; if (this.n % ") +
                std::to_string(every) + " === 0) this.entity.get(\"Text\").text = \"turn \" + this.n; }\n}\n");
}
}  // namespace

TEST_CASE("play.auto: a label that changes is progress, a clock that ticks all the time is not") {
    PlayAutoOptions o;
    o.seconds = 8;
    o.stuckSeconds = 2;
    {
        AutoProject turns(false, kNoHook);
        label_project(turns, 54);  // a turn every 0.9 s
        const Json r = run(turns, o);
        CHECK(r["ended"] == "timeout");
        CHECK(r["problems"].size() == 0);
    }
    {
        AutoProject clock(false, kNoHook);
        label_project(clock, 6);  // ten times a second
        const Json r = run(clock, o);
        CHECK(r["ended"] == "stuck");
        REQUIRE(r["problems"].size() == 1);
        CHECK(r["problems"][0]["kind"] == "menu");
    }
}

TEST_CASE("play.auto: the replay command quotes a scene path with spaces") {
    AutoProject p(true, kNoHook);
    stdfs::copy_file(p.dir / "scenes/main.scene.json", p.dir / "scenes/my level.scene.json");
    EngineConfig c = p.config();
    c.scene = "scenes/my level.scene.json";
    PlayAutoOptions o;
    o.seconds = 1;
    o.stuckSeconds = 1;
    o.screenshots = false;
    auto r = play_auto(c, o);
    REQUIRE(r.ok());
    CHECK(r.value()["replay"].get<std::string>().find("--scene \"scenes/my level.scene.json\"") != std::string::npos);
}

TEST_CASE("play.auto: pictures per phase and at the end, the cap of 40, and play.report {phase} shows one (needs a "
          "graphics device)") {
    // A folder with accents: the pictures are taken inside the project, with project-relative paths (no code page in between).
    AutoProject p(true,
                  "import { game } from \"factoria\";\n"
                  "let n = 0;\ngame.autoplay((bot) => { if (n < 45) game.phase(\"stage \" + (++n)); return "
                  "[\"move_right\"]; });\n",
                  stdfs::path(u8"proyecto-José ñandú"));
    PlayAutoOptions o;
    o.seconds = 3;
    o.stuckSeconds = 3;
    o.screenshots = true;
    auto result = play_auto(p.config(true), o);
    REQUIRE(result.ok());
    const Json r = result.value();
    if (notes_contain(r, "No screenshots")) {
        MESSAGE("no graphics device on this machine: the picture checks are skipped");
        CHECK(r["screenshots"] == 0);
        return;
    }
    CHECK(r["screenshots"] == kPlayAutoMaxPictures + 1);  // the cap, and the end picture that is always kept
    CHECK(notes_contain(r, "most a session keeps"));
    const stdfs::path folder = p.dir / ".factoria" / "sessions" / r["session"].get<std::string>();
    int files = 0;
    std::error_code ec;
    for (const auto& f : stdfs::directory_iterator(folder, ec))
        if (f.path().extension() == ".png") ++files;
    CHECK(files == kPlayAutoMaxPictures + 1);
    CHECK(stdfs::exists(folder / "end.png"));
    {
        int scratchDirs = 0;  // the pictures' scratch folder is gone once the run is complete
        for (const auto& f : stdfs::directory_iterator(p.dir / ".factoria" / "cache", ec))
            if (f.path().filename().string().rfind("play-auto-", 0) == 0) ++scratchDirs;
        CHECK(scratchDirs == 0);
    }
    CHECK(r["endScreenshot"].get<std::string>().size() > 0);
    REQUIRE(r["phases"].size() == 46);
    CHECK(r["phases"][1]["screenshot"].get<std::string>() == "phase-2.png");

    Engine e;
    EngineConfig c = p.config();
    c.headless = true;
    c.hotReload = false;
    std::string err;
    REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
    auto rep = e.commands().call("play.report", Json{{"session", r["session"]}, {"phase", 2}});
    REQUIRE(rep.ok);
    REQUIRE(rep.result.contains("$image"));
    CHECK(stdfs::exists(fs::path_from_utf8(rep.result["$image"]["path"].get<std::string>()), ec));
}

TEST_CASE("play.auto: the names of automatic sessions, and the pruning keeps the newest and never touches a person's "
          "sessions") {
    CHECK(is_auto_play_session_name("20260131-142500-auto"));
    CHECK(is_auto_play_session_name("20260131-142500-auto-2"));
    CHECK(is_auto_play_session_name("20260131-142500-auto-12"));
    CHECK_FALSE(is_auto_play_session_name("20260131-142500"));
    CHECK_FALSE(is_auto_play_session_name("20260131-142500-auto-"));
    CHECK_FALSE(is_auto_play_session_name("20260131-142500-auto-x"));
    CHECK_FALSE(is_auto_play_session_name("20260131-142500-automatic"));
    CHECK_FALSE(is_auto_play_session_name(""));

    AutoProject p(true);
    const stdfs::path rootBefore = fs::project_root();
    struct Restore {
        stdfs::path before;
        ~Restore() { fs::set_project_root(before); }
    } restore{rootBefore};
    fs::set_project_root(p.dir);
    const stdfs::path sessions = p.dir / ".factoria" / "sessions";
    const std::vector<std::string> names = {"20260101-100000-auto", "20260101-100001-auto",   "20260101-100002",
                                            "20260101-100003-auto", "20260101-100004-auto-2", "20260101-100005-auto"};
    for (const std::string& n : names) {
        stdfs::create_directories(sessions / n);
        REQUIRE(fs::write_text((sessions / n / "session.json").generic_string(), "{}").ok());
    }
    stdfs::create_directories(sessions /
                              "20260101-090000-auto");  // no session.json: not a session, so not pruned either
    CHECK(prune_auto_play_sessions(10) == 0);
    CHECK(play_session_names().size() == names.size());
    CHECK(prune_auto_play_sessions(2) == 3);  // five automatic sessions, the two newest stay
    const std::vector<std::string> left = play_session_names();
    REQUIRE(left.size() == 3);
    CHECK(left[0] == "20260101-100005-auto");
    CHECK(left[1] == "20260101-100004-auto-2");
    CHECK(left[2] == "20260101-100002");  // the person's session survives
    CHECK(stdfs::exists(sessions / "20260101-090000-auto"));
    CHECK(prune_auto_play_sessions(0) == 2);
    CHECK(play_session_names().size() == 1);
}

TEST_CASE("play.auto: prune never deletes the spared session, even when its name sorts as an old one") {
    AutoProject p(true);
    const stdfs::path rootBefore = fs::project_root();
    struct Restore {
        stdfs::path before;
        ~Restore() { fs::set_project_root(before); }
    } restore{rootBefore};
    fs::set_project_root(p.dir);
    const stdfs::path sessions = p.dir / ".factoria" / "sessions";
    for (const char* n : {"20260101-100000-auto", "20260101-100001-auto", "20260101-100002-auto", "aaa-auto"}) {
        stdfs::create_directories(sessions / n);
        REQUIRE(fs::write_text((sessions / n / "session.json").generic_string(), "{}").ok());
    }
    CHECK(is_auto_play_session_name("20260101-100003-auto"));
    CHECK_FALSE(is_auto_play_session_name("aaa-auto"));  // not a name play.auto gives: a person's folder, untouched
    CHECK(prune_auto_play_sessions(2, "20260101-100000-auto") ==
          1);  // the spared one and the newest stay: keep 2 in all
    CHECK(stdfs::exists(sessions / "20260101-100000-auto"));
    CHECK(stdfs::exists(sessions / "20260101-100002-auto"));
    CHECK_FALSE(stdfs::exists(sessions / "20260101-100001-auto"));
    CHECK(prune_auto_play_sessions(1, "20260101-100000-auto") == 1);  // keep 1: only the spared one
    CHECK(stdfs::exists(sessions / "20260101-100000-auto"));
    CHECK_FALSE(stdfs::exists(sessions / "20260101-100002-auto"));
    CHECK(stdfs::exists(sessions / "aaa-auto"));
}

TEST_CASE(
    "play.auto: the scratch folders of a run that was killed are deleted by the next run, and a live run's are not") {
    const std::string own = std::to_string(
#if defined(_WIN32)
        _getpid()
#else
        getpid()
#endif
    );
    AutoProject p(true, nullptr, stdfs::path(u8"proyecto-José ñandú"));
    const stdfs::path cache = p.dir / ".factoria" / "cache";
    const stdfs::path dead = cache / "play-auto-2000000000-0";  // no process has that id
    const stdfs::path mine = cache / ("play-auto-" + own + "-9999");
    const stdfs::path mineOld = cache / ("play-auto-" + own + "-9998");
    const stdfs::path other = cache / "play-auto-notes";  // not ours: left alone
    for (const stdfs::path& d : {dead, mine, mineOld, other}) {
        stdfs::create_directories(d);
        REQUIRE(fs::write_text((d / "end.png").generic_string(), "x").ok());
    }
    std::error_code ec;
    stdfs::last_write_time(mineOld, stdfs::file_time_type::clock::now() - std::chrono::hours(3), ec);
    const bool aged =
        !ec;  // the time of a folder cannot be set everywhere (MinGW under Wine): then that part is skipped
    if (!aged) MESSAGE("last_write_time on a folder failed (" << ec.message() << "): the age rule is not checked");
    (void)run(p);
    CHECK_FALSE(stdfs::exists(dead));
    if (aged) CHECK_FALSE(stdfs::exists(mineOld));  // older than an hour
    CHECK(stdfs::exists(mine));                     // this process, young: another run of it may be using it
    CHECK(stdfs::exists(other));
}
