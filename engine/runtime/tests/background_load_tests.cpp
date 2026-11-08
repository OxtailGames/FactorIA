// Background loading through the whole engine (docs/PERFORMANCE.md, "Background loading"): scene.preload,
// assets.preload and scene.load {async: true} from scripts and commands, the same world and load order as a sync load
// with the pool stopped, inline, 0, 1 and 8 workers, progress, cancel, errors that teach, the upload budget, a recorded
// session that replays the same, shutdown in the middle of a load, and two engines loading at once.
// No sleeps and no wall-clock asserts: every wait is a frame loop with a generous cap.
#include <doctest.h>

#include <cstdint>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

#include "../src/background_loader.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/jobs.h"
#include "fa/runtime/engine.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct ScopedEnv {
    std::string name;
    std::string old;
    bool had = false;
    ScopedEnv(const char* n, const char* value) : name(n) {
        if (const char* v = std::getenv(n)) {
            had = true;
            old = v;
        }
        set(value);
    }
    ~ScopedEnv() { set(had ? old.c_str() : nullptr); }
    void set(const char* value) const {
#ifdef _WIN32
        _putenv_s(name.c_str(), value ? value : "");
#else
        if (value) setenv(name.c_str(), value, 1);
        else unsetenv(name.c_str());
#endif
    }
};

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Background Load Test",
  "id": "com.example.bgload",
  "mainScene": "scenes/menu.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" }
})";

const char* kMenu = R"({"format":"factoria.scene/1","entities":[
  {"id":"cam","components":{"Camera":{}}},
  {"id":"title","components":{"Transform":{},"Shape2D":{"size":[40,8]}}}]})";

// Six real textures, three models that are not glTF (their load fails the same way sync or async), a sound, a prefab
// and a behaviour that imports a module.
const char* kLevel = R"({"format":"factoria.scene/1","entities":[
  {"id":"cam","components":{"Camera":{}}},
  {"id":"t1","components":{"Transform":{"position":[-100,0,0]},"Sprite":{"texture":"assets/t1.png"}}},
  {"id":"t2","components":{"Transform":{"position":[-60,0,0]},"Sprite":{"texture":"assets/t2.png"}}},
  {"id":"t3","components":{"Transform":{"position":[-20,0,0]},"Sprite":{"texture":"assets/t3.png"}}},
  {"id":"t4","components":{"Transform":{"position":[20,0,0]},"Sprite":{"texture":"assets/t4.png"}}},
  {"id":"t5","components":{"Transform":{"position":[60,0,0]},"Sprite":{"texture":"assets/t5.png"}}},
  {"id":"t6","components":{"Transform":{"position":[100,0,0]},"Sprite":{"texture":"assets/t6.png"}}},
  {"id":"m1","components":{"Transform":{},"MeshRenderer":{"mesh":"assets/m1.glb"}}},
  {"id":"m2","components":{"Transform":{},"MeshRenderer":{"mesh":"assets/m2.glb"}}},
  {"id":"m3","components":{"Transform":{},"MeshRenderer":{"mesh":"assets/m3.glb"}}},
  {"id":"boss","components":{"Transform":{},"Script":{"path":"scripts/boss.js","props":{"crate":"prefabs/crate.prefab.json","hit":"sounds/hit.wav"}}}}]})";

const char* kOther = R"({"format":"factoria.scene/1","entities":[
  {"id":"cam","components":{"Camera":{}}},
  {"id":"o1","components":{"Transform":{},"Sprite":{"texture":"assets/o1.png"}}}]})";

const char* kBoss = R"JS(
import { Behaviour } from "factoria";
import { hp } from "./stats.js";
export default class Boss extends Behaviour {
  crate = "";
  hit = "";
  onStart() { this.entity.get("Transform").position = [0, hp, 0]; }
}
)JS";

std::string wav(int samples) {  // 16-bit mono PCM at 22050 Hz
    auto u32 = [](std::uint32_t v) { return std::string{char(v & 255), char((v >> 8) & 255), char((v >> 16) & 255), char(v >> 24)}; };
    auto u16 = [](std::uint16_t v) { return std::string{char(v & 255), char(v >> 8)}; };
    const std::uint32_t data = std::uint32_t(samples) * 2;
    std::string s = "RIFF" + u32(36 + data) + "WAVEfmt " + u32(16) + u16(1) + u16(1) + u32(22050) + u32(44100) + u16(2) + u16(16) +
                    "data" + u32(data);
    for (int i = 0; i < samples; ++i) s += u16(std::uint16_t((i * 977) & 0x3fff));
    return s;
}

std::string png(int size, std::uint8_t shade) {
    Image img;
    img.width = img.height = size;
    img.rgba.assign(std::size_t(size) * std::size_t(size) * 4, shade);
    for (std::size_t i = 3; i < img.rgba.size(); i += 4) img.rgba[i] = 255;
    const std::vector<std::uint8_t> bytes = encode_png(img);
    return std::string(bytes.begin(), bytes.end());
}

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const char* name, const std::string& project = kProject) {
        dir = fs::make_temp_dir(std::string("fa_bgload_") + name);
        write("factoria.json", project);
        write("scenes/menu.scene.json", kMenu);
        write("scenes/level.scene.json", kLevel);
        write("scenes/other.scene.json", kOther);
        write("scripts/boss.js", kBoss);
        write("scripts/stats.js", "export const hp = 7;\n");
        write("prefabs/crate.prefab.json", R"({"format":"factoria.prefab/1","entities":[{"id":"crate","components":{
            "Transform":{},"Sprite":{"texture":"assets/crate.png"}}}]})");
        for (int i = 1; i <= 6; ++i) write("assets/t" + std::to_string(i) + ".png", png(64, std::uint8_t(30 * i)));
        write("assets/crate.png", png(16, 200));
        write("assets/o1.png", png(32, 99));
        for (int i = 1; i <= 3; ++i) write("assets/m" + std::to_string(i) + ".glb", std::string(800, char('a' + i)));
        write("sounds/hit.wav", wav(2000));
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    void write(const std::string& rel, const std::string& text) const {
        stdfs::create_directories((dir / rel).parent_path());
        std::ofstream(dir / rel, std::ios::binary) << text;
    }
    EngineConfig config(const std::string& jobThreads = "0", bool graphics = false) const {
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.graphics = graphics;
        c.hotReload = false;
        c.jobThreads = jobThreads;
        return c;
    }
};

Json call(Engine& e, const std::string& name, const Json& args = Json::object()) {
    auto r = e.commands().call(name, args);
    INFO(name << " " << args.dump() << " -> " << r.error.dump());
    REQUIRE(r.ok);
    return r.result;
}

Json eval(Engine& e, const std::string& code) {
    auto r = e.commands().call("script.eval", Json::object({{"code", code}}));
    INFO(code << " -> " << r.error.dump());
    REQUIRE(r.ok);
    return r.result["value"];
}

const std::vector<std::string> kModes = {"0", "1", "8", "inline"};

struct LoadRun {
    std::vector<double> progress;  // load.status progress after each frame until the scene switched
    int frames = 0;
    Json hash;                     // game.state_hash {perEntity} three frames after the switch
    LoadOrder order;
};

const SceneFiles* scene_files(const LoadOrder& order, const std::string& scene) {
    for (const SceneFiles& s : order)
        if (s.scene == scene) return &s;
    return nullptr;
}

// The level loaded sync (scene.load outside a frame) or async (scene.load {async: true}), then three frames.
LoadRun run_load(const TempProject& p, const std::string& jobThreads, bool async, bool graphics = false) {
    LoadRun out;
    EngineConfig c = p.config(jobThreads, graphics);
    c.traceLoads = true;
    c.loadOrderSink = [&out](const LoadOrder& o) { out.order = o; };
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
    e.step(1);
    if (async) {
        const Json r = call(e, "scene.load", Json::object({{"path", "scenes/level.scene.json"}, {"async", true}}));
        CHECK(r["async"].get<bool>());
        const int id = r["loadId"].get<int>();
        while (e.world().scene_path() != "scenes/level.scene.json" && out.frames < 500) {
            e.step(1);
            ++out.frames;
            out.progress.push_back(call(e, "load.status", Json::object({{"id", id}}))["progress"].get<double>());
        }
        CHECK(call(e, "load.status", Json::object({{"id", id}}))["state"] == "done");
    } else {
        call(e, "scene.load", Json::object({{"path", "scenes/level.scene.json"}}));
    }
    REQUIRE(e.world().scene_path() == "scenes/level.scene.json");
    e.step(3);
    out.hash = call(e, "game.state_hash", Json::object({{"perEntity", true}}));
    e.shutdown();
    return out;
}

}  // namespace

TEST_CASE("background load: async scene.load gives the world and load order of a sync load, with any pool") {
    ScopedEnv env("FA_JOB_THREADS", nullptr);
    TempProject p("same");
    const LoadRun sync = run_load(p, "0", false);
    const LoadRun base = run_load(p, "0", true);
    CHECK(base.frames >= 3);  // the scan, then 11 files at 4 a frame: the load spans frames
    CHECK(base.hash["perEntity"] == sync.hash["perEntity"]);
    CHECK(base.hash["entities"] == sync.hash["entities"]);
    // The same files of the level in the same first-use order (what `factoria export` packs game.pak by).
    const SceneFiles* syncLevel = scene_files(sync.order, "scenes/level.scene.json");
    const SceneFiles* asyncLevel = scene_files(base.order, "scenes/level.scene.json");
    REQUIRE(syncLevel);
    REQUIRE(asyncLevel);
    CHECK(asyncLevel->files == syncLevel->files);
    CHECK(syncLevel->files.front() == "scenes/level.scene.json");
    const SceneFiles* menu = scene_files(base.order, "scenes/menu.scene.json");
    REQUIRE(menu);
    for (const std::string& f : menu->files) CHECK(f.rfind("assets/", 0) != 0);  // read ahead, never the menu's
    // Progress never goes down and reaches 1.
    for (std::size_t i = 1; i < base.progress.size(); ++i) CHECK(base.progress[i] >= base.progress[i - 1]);
    REQUIRE_FALSE(base.progress.empty());
    CHECK(base.progress.back() == 1.0);
    // Pool stopped is covered below (a loader without a pool); here 0, 1 and 8 workers and inline: the same frames.
    for (const std::string& mode : kModes) {
        CAPTURE(mode);
        const LoadRun r = run_load(p, mode, true);
        CHECK(r.frames == base.frames);
        CHECK(r.progress == base.progress);
        CHECK(r.hash == base.hash);
        const SceneFiles* level = scene_files(r.order, "scenes/level.scene.json");
        REQUIRE(level);
        CHECK(level->files == syncLevel->files);
    }
    CHECK_FALSE(jobs::running());
    CHECK_FALSE(IoQueue::io_thread_running());
    CHECK(fs::warm_bytes() == 0);
}

TEST_CASE("background load: with a GPU the async load uploads the textures and draws what the sync load draws") {
    ScopedEnv env("FA_JOB_THREADS", nullptr);
    TempProject p("gpu");
    {
        Engine probe;
        std::string err;
        REQUIRE_MESSAGE(probe.init(p.config("0", true), nullptr, &err), err);
        const bool gpu = probe.renderer() != nullptr;
        probe.shutdown();
        if (!gpu) {
            MESSAGE("no GPU here: the upload paths are covered by the CI runners that have one");
            return;
        }
    }
    const LoadRun sync = run_load(p, "0", false, true);
    for (const std::string& mode : {std::string("0"), std::string("8")}) {
        CAPTURE(mode);
        const LoadRun r = run_load(p, mode, true, true);
        CHECK(r.hash["perEntity"] == sync.hash["perEntity"]);
        const SceneFiles* a = scene_files(r.order, "scenes/level.scene.json");
        const SceneFiles* s = scene_files(sync.order, "scenes/level.scene.json");
        REQUIRE(a);
        REQUIRE(s);
        CHECK(a->files == s->files);
    }
    CHECK(fs::warm_bytes() == 0);
}

TEST_CASE("background load: uploads stop at the budget and finish over the next frames") {
    ScopedEnv env("FA_JOB_THREADS", nullptr);
    // 64x64 textures are 16 KB each: a budget of 0.01 MB lets one upload through per frame.
    TempProject p("budget", R"({"format":"factoria.project/1","name":"Budget","id":"com.example.budget",
        "mainScene":"scenes/menu.scene.json","display":{"width":320,"height":180},
        "runtime":{"loadBudgetMs":100,"uploadBudgetMB":0.01}})");
    EngineConfig c = p.config("0", true);
    c.timedLoads = true;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
    if (!e.renderer()) {
        MESSAGE("no GPU here: nothing is uploaded");
        e.shutdown();
        return;
    }
    e.step(1);
    const int id = call(e, "scene.preload", Json::object({{"path", "scenes/level.scene.json"}}))["loadId"].get<int>();
    std::uint64_t last = 0;
    int framesWithUploads = 0, frames = 0;
    std::string state = "scanning";
    while (state != "done" && frames < 2000) {
        e.step(1);
        ++frames;
        const Json s = call(e, "load.status", Json::object({{"id", id}}));
        state = s["state"].get<std::string>();
        const std::uint64_t up = s["uploadedBytes"].get<std::uint64_t>();
        CHECK(up - last <= 64u * 64u * 4u * 2u);  // at most one texture (and its mips) a frame
        if (up > last) ++framesWithUploads;
        last = up;
    }
    CHECK(state == "done");
    CHECK(framesWithUploads >= 6);  // six textures, one frame each
    e.shutdown();
}

TEST_CASE("background load: cancel in the middle, a newer scene.load wins, and the files go") {
    ScopedEnv env("FA_JOB_THREADS", nullptr);
    TempProject p("cancel");
    for (const std::string& mode : kModes) {
        CAPTURE(mode);
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(p.config(mode), nullptr, &err), err);
        e.step(1);
        // A command's load, cancelled after one frame.
        const int id = call(e, "scene.load", Json::object({{"path", "scenes/level.scene.json"}, {"async", true}}))["loadId"].get<int>();
        e.step(1);
        CHECK(call(e, "load.status", Json::object({{"id", id}}))["state"] == "loading");
        CHECK(call(e, "load.cancel", Json::object({{"id", id}}))["cancelled"].get<bool>());
        e.step(20);
        CHECK(e.world().scene_path() == "scenes/menu.scene.json");
        CHECK(call(e, "load.status", Json::object({{"id", id}}))["state"] == "cancelled");
        CHECK(fs::warm_bytes() == 0);
        // A script's load: cancel() rejects its promise and the scene stays.
        eval(e, "globalThis.h = scene.load('scenes/level.scene.json', {n: 1}, {async: true});"
                "globalThis.why = ''; h.promise.catch((x) => { globalThis.why = x.message; });");
        e.step(1);
        eval(e, "h.cancel()");
        e.step(5);
        CHECK(eval(e, "h.cancelled").get<bool>());
        CHECK(eval(e, "h.done").get<bool>());
        CHECK(eval(e, "globalThis.why").get<std::string>().find("cancelled") != std::string::npos);
        CHECK(e.world().scene_path() == "scenes/menu.scene.json");
        // A sync scene.load after an async one: the last request wins, the async one never switches.
        eval(e, "globalThis.h2 = scene.load('scenes/level.scene.json', null, {async: true});");
        e.step(1);
        call(e, "scene.load", Json::object({{"path", "scenes/other.scene.json"}}));
        e.step(30);
        CHECK(e.world().scene_path() == "scenes/other.scene.json");
        CHECK(eval(e, "h2.cancelled").get<bool>());
        // Two async loads: the second wins.
        eval(e, "globalThis.a = scene.load('scenes/level.scene.json', null, {async: true});"
                "globalThis.b = scene.load('scenes/menu.scene.json', null, {async: true});");
        int frames = 0;
        while (e.world().scene_path() != "scenes/menu.scene.json" && frames < 200) {
            e.step(1);
            ++frames;
        }
        CHECK(e.world().scene_path() == "scenes/menu.scene.json");
        CHECK(eval(e, "a.cancelled").get<bool>());
        e.step(1);
        CHECK(eval(e, "b.done && !b.cancelled && b.progress === 1").get<bool>());
        e.shutdown();
        CHECK(fs::warm_bytes() == 0);
    }
}

TEST_CASE("background load: a script's async scene.load hands its props over, with monotonic progress") {
    ScopedEnv env("FA_JOB_THREADS", nullptr);
    TempProject p("script");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config("2"), nullptr, &err), err);
    e.step(1);
    eval(e, "globalThis.h = scene.load('scenes/level.scene.json', {level: 2}, {async: true}); globalThis.seen = [];"
            "globalThis.result = null; h.promise.then((r) => { globalThis.result = r; });");
    CHECK(eval(e, "h.progress").get<double>() == 0.0);
    CHECK(eval(e, "h.total").get<int>() == 1);
    int frames = 0;
    while (e.world().scene_path() != "scenes/level.scene.json" && frames < 500) {
        eval(e, "seen.push(h.progress)");
        e.step(1);
        ++frames;
    }
    REQUIRE(e.world().scene_path() == "scenes/level.scene.json");
    const Json seen = eval(e, "seen");
    for (std::size_t i = 1; i < seen.size(); ++i) CHECK(seen[i].get<double>() >= seen[i - 1].get<double>());
    CHECK(eval(e, "h.progress").get<double>() == 1.0);
    CHECK(eval(e, "h.files === h.total && h.total === 12").get<bool>());  // the scan + 11 files
    CHECK(eval(e, "game.sceneProps().level").get<int>() == 2);
    CHECK(eval(e, "result !== null && result.files === 12 && result.bytes > 1000").get<bool>());
    e.step(2);
    CHECK(e.world().get<Transform>(e.world().find("boss"))->position.y == doctest::Approx(7.0));
    e.shutdown();
}

TEST_CASE("background load: a missing file is an error with did-you-mean and a hint") {
    ScopedEnv env("FA_JOB_THREADS", nullptr);
    TempProject p("missing");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config("0"), nullptr, &err), err);
    e.step(1);
    auto r = e.commands().call("scene.load", Json::object({{"path", "scenes/levl.scene.json"}, {"async", true}}));
    CHECK_FALSE(r.ok);
    CHECK(r.error.dump().find("scenes/level.scene.json") != std::string::npos);
    r = e.commands().call("scene.preload", Json::object({{"path", "scenes/levle.scene.json"}}));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find("does not exist") != std::string::npos);
    CHECK(r.error["message"].get<std::string>().find("scenes/level.scene.json") != std::string::npos);
    CHECK_FALSE(r.error["hint"].get<std::string>().empty());
    r = e.commands().call("assets.preload", Json::parse(R"({"paths":["assets/t1.pgn"]})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find("assets/t1.png") != std::string::npos);
    r = e.commands().call("assets.preload", Json::parse(R"({"paths":["assets"]})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find("folder") != std::string::npos);
    r = e.commands().call("load.cancel", Json::object({{"id", 99}}));
    CHECK_FALSE(r.ok);
    r = e.commands().call("load.status", Json::object({{"id", 99}}));
    CHECK_FALSE(r.ok);
    // Scripts: the same errors, thrown; options are checked.
    const Json thrown = eval(e, R"JS(
      const out = [];
      for (const f of [() => scene.load("scenes/levl.scene.json", null, {async: true}),
                       () => scene.load("scenes/level.scene.json", null, {asinc: true}),
                       () => scene.load("scenes/level.scene.json", [1], {async: true}),
                       () => scene.preload("scenes/main.scene.jsn"),
                       () => assets.preload(["sounds/hti.wav"])]) {
        try { f(); out.push("no error"); } catch (x) { out.push(x.message + " | " + (x.hint || "")); }
      }
      out)JS");
    REQUIRE(thrown.size() == 5);
    CHECK(thrown[0].get<std::string>().find("scenes/level.scene.json") != std::string::npos);
    CHECK(thrown[1].get<std::string>().find("Did you mean `async`") != std::string::npos);
    CHECK(thrown[2].get<std::string>().find("plain object") != std::string::npos);
    CHECK(thrown[3].get<std::string>().find("does not exist") != std::string::npos);
    INFO(thrown.dump());
    CHECK(thrown[4].get<std::string>().find("sounds/hit.wav") != std::string::npos);
    CHECK(e.world().scene_path() == "scenes/menu.scene.json");
    e.shutdown();
}

TEST_CASE("background load: a broken scene fails the load with the parse error; the scene stays") {
    ScopedEnv env("FA_JOB_THREADS", nullptr);
    TempProject p("broken");
    p.write("scenes/broken.scene.json", "{ not json");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config("1"), nullptr, &err), err);
    e.step(1);
    eval(e, "globalThis.h = scene.load('scenes/broken.scene.json', null, {async: true}); globalThis.why = null;"
            "h.promise.catch((x) => { globalThis.why = x.message; });");
    e.step(5);
    CHECK(eval(e, "h.done && h.progress < 1").get<bool>());
    CHECK(eval(e, "h.error").get<std::string>().find("invalid JSON") != std::string::npos);
    CHECK(eval(e, "why").get<std::string>().find("scene.load") != std::string::npos);
    CHECK(e.world().scene_path() == "scenes/menu.scene.json");
    e.shutdown();
}

TEST_CASE("background load: scene.preload in a script, then scene.load reads nothing; the files go at the second load") {
    ScopedEnv env("FA_JOB_THREADS", nullptr);
    TempProject p("preload");
    for (const std::string& mode : kModes) {
        CAPTURE(mode);
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(p.config(mode), nullptr, &err), err);
        e.step(1);
        eval(e, "globalThis.job = scene.preload('scenes/level.scene.json'); globalThis.seen = [];");
        int frames = 0;
        while (!eval(e, "job.done").get<bool>() && frames < 50) {
            e.step(1);
            ++frames;
            eval(e, "seen.push(job.progress)");
        }
        // The same on every machine: the scan reads the scene, the script, its module and the prefab (one unit), then
        // one unit per file: 6 textures, the prefab's texture, the sound and 3 models. 12 units, 4 per frame: 3 frames.
        CHECK(frames == 3);
        CHECK(eval(e, "seen[0]").get<double>() == doctest::Approx(4.0 / 12.0));
        CHECK(eval(e, "job.files").get<int>() == 12);
        const std::uint64_t before = fs::disk_reads();
        REQUIRE(e.load_scene("scenes/level.scene.json", &err));
        e.step(1);
        CHECK(fs::disk_reads() == before);
        e.reload_scene();  // the second load after the preload: its files go
        e.step(1);
        CHECK(fs::warm_bytes() == 0);
        e.shutdown();
    }
}

TEST_CASE("background load: assets.preload brings a glTF's buffer and texture; release gives the files back") {
    ScopedEnv env("FA_JOB_THREADS", nullptr);
    TempProject p("assets");
    p.write("assets/boss.gltf", R"({"asset":{"version":"2.0"},"buffers":[{"uri":"boss.bin","byteLength":4}],"images":[{"uri":"boss.png"}]})");
    p.write("assets/boss.bin", "1234");
    p.write("assets/boss.png", png(8, 10));
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config("0"), nullptr, &err), err);
    e.step(1);
    eval(e, "globalThis.job = assets.preload(['assets/boss.gltf', 'sounds/hit.wav'])");
    e.step(10);
    CHECK(eval(e, "job.done && job.error === ''").get<bool>());
    CHECK(eval(e, "job.files").get<int>() == 5);  // the scan + the model, its buffer, its texture and the sound
    CHECK(fs::warm_bytes() > 0);
    eval(e, "job.release()");
    CHECK(fs::warm_bytes() == 0);
    const Json st = call(e, "load.status");
    CHECK(st["jobs"].size() == 1);
    CHECK(st["jobs"][0]["kind"] == "assets.preload");
    CHECK(st["jobs"][0]["origin"] == "script");
    e.shutdown();
}

TEST_CASE("background load: shutdown in the middle of loads does not crash, hang or keep files") {
    ScopedEnv env("FA_JOB_THREADS", nullptr);
    TempProject p("shutdown");
    for (const std::string& mode : kModes) {
        for (int framesBefore : {0, 1, 2}) {
            CAPTURE(mode);
            CAPTURE(framesBefore);
            Engine e;
            std::string err;
            REQUIRE_MESSAGE(e.init(p.config(mode), nullptr, &err), err);
            e.step(1);
            call(e, "scene.load", Json::object({{"path", "scenes/level.scene.json"}, {"async", true}}));
            call(e, "scene.preload", Json::object({{"path", "scenes/other.scene.json"}}));
            call(e, "assets.preload", Json::parse(R"({"paths":["sounds/hit.wav","assets/t1.png"]})"));
            e.step(framesBefore);
            e.shutdown();
            CHECK(fs::warm_bytes() == 0);
            CHECK_FALSE(IoQueue::io_thread_running());
        }
    }
    CHECK_FALSE(jobs::running());
}

TEST_CASE("background load: two engines loading at once keep their loads apart") {
    ScopedEnv env("FA_JOB_THREADS", nullptr);
    TempProject p("two");
    LoadOrder orderA, orderB;
    EngineConfig ca = p.config("2"), cb = p.config("2");
    ca.traceLoads = cb.traceLoads = true;
    ca.loadOrderSink = [&](const LoadOrder& o) { orderA = o; };
    cb.loadOrderSink = [&](const LoadOrder& o) { orderB = o; };
    {
        Engine a, b;
        std::string err;
        REQUIRE_MESSAGE(a.init(ca, nullptr, &err), err);
        REQUIRE_MESSAGE(b.init(cb, nullptr, &err), err);
        a.step(1);
        b.step(1);
        call(a, "scene.load", Json::object({{"path", "scenes/level.scene.json"}, {"async", true}}));
        call(b, "scene.load", Json::object({{"path", "scenes/other.scene.json"}, {"async", true}}));
        CHECK(call(a, "load.status")["jobs"].size() == 1);
        CHECK(call(b, "load.status")["jobs"][0]["paths"][0] == "scenes/other.scene.json");
        int frames = 0;
        while ((a.world().scene_path() != "scenes/level.scene.json" || b.world().scene_path() != "scenes/other.scene.json") &&
               frames < 500) {
            a.step(1);
            b.step(1);
            ++frames;
        }
        CHECK(a.world().scene_path() == "scenes/level.scene.json");
        CHECK(b.world().scene_path() == "scenes/other.scene.json");
        a.step(1);
        b.step(1);
        a.shutdown();
        b.shutdown();
    }
    const SceneFiles* la = scene_files(orderA, "scenes/level.scene.json");
    const SceneFiles* lb = scene_files(orderB, "scenes/other.scene.json");
    REQUIRE(la);
    REQUIRE(lb);
    CHECK_FALSE(scene_files(orderA, "scenes/other.scene.json"));
    CHECK_FALSE(scene_files(orderB, "scenes/level.scene.json"));
    for (const std::string& f : la->files) CHECK(f != "scenes/other.scene.json");
    CHECK(fs::warm_bytes() == 0);
}

TEST_CASE("background load: a session recorded with the timed budget replays the same frames") {
    ScopedEnv env("FA_JOB_THREADS", nullptr);
    TempProject p("replay");
    p.write("scripts/go.js", R"JS(
import { Behaviour, scene } from "factoria";
export default class Go extends Behaviour {
  onStart() { this.n = 0; globalThis.trail = []; }
  onUpdate() {
    this.n++;
    if (this.n === 3) globalThis.h = scene.load("scenes/level.scene.json", {from: "menu"}, {async: true});
    if (globalThis.h) globalThis.trail.push(globalThis.h.progress);
  }
}
)JS");
    p.write("scenes/menu.scene.json", R"({"format":"factoria.scene/1","entities":[
      {"id":"cam","components":{"Camera":{}}},{"id":"go","components":{"Transform":{},"Script":{"path":"scripts/go.js"}}}]})");
    struct Run {
        int switchFrame = -1;
        std::vector<double> trail;
        std::string hash;
    };
    auto finish = [](Engine& e, Run& r, int f) {
        if (r.switchFrame < 0 && e.world().scene_path() == "scenes/level.scene.json") {
            r.switchFrame = f;
            for (const Json& v : eval(e, "trail")) r.trail.push_back(v.get<double>());
        }
    };
    // Recorded: a timed budget with worker threads takes only the files that are ready (any count per frame).
    Run rec;
    Json replay;
    {
        EngineConfig c = p.config("4");
        c.timedLoads = true;
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(c, nullptr, &err), err);
        e.start_input_recording();
        int f = 0;
        for (; f < 20000 && rec.switchFrame < 0; ++f) {
            e.step(1);
            finish(e, rec, f);
        }
        REQUIRE(rec.switchFrame > 0);
        e.step(2);
        rec.hash = call(e, "game.state_hash")["hash"].get<std::string>();
        replay = e.stop_input_recording();
        e.shutdown();
    }
    REQUIRE(replay.contains("frames"));
    int withUnits = 0;
    for (auto it = replay["frames"].begin(); it != replay["frames"].end(); ++it) withUnits += it->contains("loadUnits") ? 1 : 0;
    CHECK(withUnits >= 1);
    // Replayed with the exact budget and another pool: each frame takes the recorded count of files.
    for (const std::string& mode : {std::string("0"), std::string("inline"), std::string("8")}) {
        CAPTURE(mode);
        Run rep;
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(p.config(mode), nullptr, &err), err);
        int f = 0;
        for (; f <= rec.switchFrame; ++f) {
            const std::string key = std::to_string(f);
            if (replay["frames"].contains(key)) {
                std::vector<std::string> problems;
                e.apply_input_entry(replay["frames"][key], problems, f);
                CHECK(problems.empty());
            }
            e.step(1);
            finish(e, rep, f);
        }
        e.step(2);
        rep.hash = call(e, "game.state_hash")["hash"].get<std::string>();
        CHECK(rep.switchFrame == rec.switchFrame);
        CHECK(rep.trail == rec.trail);
        CHECK(rep.hash == rec.hash);
        e.shutdown();
    }
    // A bad entry teaches.
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config("0"), nullptr, &err), err);
    std::vector<std::string> problems;
    e.apply_input_entry(Json::parse(R"({"loadUnits":"three"})"), problems, 4);
    e.apply_input_entry(Json::parse(R"({"loadUnit":3})"), problems, 5);
    e.apply_input_entry(Json::parse(R"({"loadUnits":-2})"), problems, 6);
    REQUIRE(problems.size() == 3);
    CHECK(problems[0].find("whole number") != std::string::npos);
    CHECK(problems[1].find("loadUnits") != std::string::npos);
    CHECK(problems[2].find("clamped") != std::string::npos);
    e.shutdown();
}

TEST_CASE("background load: a loader without a job pool gives the same frames as one with workers") {
    // The pool stopped: no IO thread, every read and decode runs in tick() on this thread.
    TempProject p("nopool");
    const stdfs::path oldRoot = fs::project_root();
    fs::set_project_root(p.dir);
    auto frames_of = [](jobs::Owner* owner) {
        std::vector<int> done;
        BackgroundLoader loader(owner, LoadTrace::kNoOwner);
        auto id = loader.start(BackgroundLoader::Kind::ScenePreload, {"scenes/level.scene.json"}, std::nullopt,
                               BackgroundLoader::Origin::Tool, nullptr);
        REQUIRE(id.ok());
        for (int f = 0; f < 50 && loader.loading(); ++f) {
            const BackgroundLoader::Frame fr = loader.tick(nullptr, nullptr, BackgroundLoader::Budget{});
            for (const BackgroundLoader::Update& u : fr.updates) done.push_back(u.done);
        }
        CHECK(loader.status(id.value())["state"] == "done");
        loader.stop(nullptr);
        if (owner) REQUIRE(owner->wait().ok());
        return done;
    };
    std::vector<int> stopped;
    {
        CHECK_FALSE(jobs::running());
        stopped = frames_of(nullptr);
    }
    CHECK(stopped == std::vector<int>{4, 8, 12});  // the scan + 11 files, 4 a frame
    {
        REQUIRE(jobs::start(jobs::Settings::threads(8)).ok());
        jobs::Owner owner("bg test");
        CHECK(frames_of(&owner) == stopped);
        jobs::stop();
    }
    fs::unwarm_all();
    fs::set_project_root(oldRoot);
}
