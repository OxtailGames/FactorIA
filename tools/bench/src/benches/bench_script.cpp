// Script benchmarks: the JS -> C++ bridge of QuickJS (native calls, component access) and behaviours that run every frame.
#include <filesystem>
#include <fstream>
#include <memory>
#include <string>
#include <utility>

#include "benches.h"
#include "fa/audio/audio.h"
#include "fa/core/fs.h"
#include "fa/physics/physics.h"
#include "fa/platform/input.h"
#include "fa/scene/components.h"
#include "fa/scene/serialize.h"
#include "fa/script/script.h"

namespace fa::bench {

namespace {

// The smallest ScriptHost that runs scripts: a world, input, the null audio device and physics, no renderer.
struct BenchHost : ScriptHost {
    std::filesystem::path root;
    World w;
    Input in;
    Audio au;
    Physics ph;
    CommandRegistry cmds;
    ScriptSystem scripts;
    double fdt = 1.0 / 60.0;
    std::string error;
    bool ready = false;

    BenchHost() {
        ensure_builtin_components();
        auto made = fs::make_temp_dir("fa_bench_script");
        if (!made.ok()) {
            error = made.error().message;
            return;
        }
        root = made.value();
        fs::set_project_root(root);
        au.init(false, nullptr);
        au.set_clock(&w);
        ph.init(PhysicsSettings{});
    }
    ~BenchHost() override {
        scripts.shutdown();
        au.shutdown();
        std::error_code ec;
        std::filesystem::remove_all(root, ec);
    }
    void file(const std::string& rel, const std::string& text) {
        const std::filesystem::path p = root / rel;
        std::filesystem::create_directories(p.parent_path());
        std::ofstream(p, std::ios::binary) << text;
    }
    // Starts the scripts and loads "scenes/main.scene.json" (written by the caller).
    bool start() {
        if (!error.empty()) return false;
        fs::set_project_root(root);
        if (!scripts.init(*this, &error)) return false;
        error = load_scene_now("scenes/main.scene.json");
        ready = error.empty();
        return ready;
    }
    // Runs `code` once; the answer must be a number, which is the benchmark's checksum.
    double call_number(const char* code) {
        auto r = scripts.eval(code);
        if (!r.ok()) {
            error = r.error().to_string();
            return -1.0;
        }
        return r->is_number() ? r->get<double>() : -2.0;
    }
    void frame() {
        const float dt = float(fdt);
        scripts.fixed_update(dt);
        scripts.update(dt);
        scripts.late_update(dt);
        w.advance_clock(fdt);
        w.flush();
        in.begin_frame();
    }

    World& world() override { return w; }
    Input& input() override { return in; }
    Audio& audio() override { return au; }
    Physics& physics() override { return ph; }
    Renderer* renderer() override { return nullptr; }
    CommandRegistry& commands() override { return cmds; }
    Json project_settings() const override { return Json::object(); }
    double fixed_dt() const override { return fdt; }
    void request_scene_change(std::string_view) override {}
    void request_quit() override {}
    bool screenshot(std::string_view, std::string* e) override {
        if (e) *e = "no renderer";
        return false;
    }
    void step_frames(int n) override {
        for (int i = 0; i < n; ++i) frame();
    }
    std::string load_scene_now(std::string_view path) override {
        LoadReport r = load_scene_file(w, path);
        ph.reset();
        w.reset_clock();
        scripts.on_scene_loaded();
        return r.ok() ? "" : r.summary();
    }
};

// A scene with `count` entities named e0, e1...; with a behaviour from `script` on each when it is not empty.
std::string scene_text(int count, const std::string& script) {
    Json entities = Json::array();
    for (int i = 0; i < count; ++i) {
        Json components = Json::object({{"Sprite", Json::object()}, {"Collider2D", Json::object()}});
        if (!script.empty())
            components["Script"] = Json::object({{"path", script}, {"props", Json::object({{"speed", 10 + i % 7}})}});
        entities.push_back(Json::object({{"id", "e" + std::to_string(i)}, {"components", components}}));
    }
    return Json::object({{"format", "factoria.scene/1"}, {"entities", entities}}).dump();
}

// A benchmark that calls a global JS function `bench()` (defined by `code`) and uses its number as the checksum.
Bench script_function(const char* name, const char* summary, std::int64_t items, const char* unit, std::string code) {
    Bench b;
    b.name = name;
    b.summary = summary;
    b.make = [items, unit, code = std::move(code)] {
        auto host = std::make_shared<BenchHost>();
        Prepared p;
        host->file("scenes/main.scene.json", scene_text(100, ""));
        if (!host->start()) {
            p.skip = "the script host did not start: " + host->error;
            return p;
        }
        host->call_number(code.c_str());
        const double probe = host->call_number("bench()");
        if (probe < 0) {
            p.skip = "the benchmark script failed: " + host->error;
            return p;
        }
        p.items = items;
        p.unit = unit;
        p.run = [host] { return host->call_number("bench()"); };
        return p;
    };
    return b;
}

Bench script_behaviours() {
    Bench b;
    b.name = "script.behaviours";
    b.summary =
        "30 frames of 300 behaviours: onFixedUpdate, onUpdate and onLateUpdate, each reading and writing the entity";
    b.make = [] {
        auto host = std::make_shared<BenchHost>();
        Prepared p;
        host->file("scripts/mover.js", R"(
import { Behaviour } from "factoria";
export default class Mover extends Behaviour {
  speed = 1;
  onStart() { this.t = 0; }
  onFixedUpdate(dt) { this.t += dt; }
  onUpdate(dt) {
    const e = this.entity;
    e.position.x += this.speed * dt;
    if (e.position.x > 500) e.position.x = 0;
    e.get('Sprite').color.a = 0.5 + 0.5 * (e.position.x / 500);
  }
  onLateUpdate(dt) { this.t += e2(this.speed); }
}
function e2(x) { return x * 0.5; }
)");
        host->file("scenes/main.scene.json", scene_text(300, "scripts/mover.js"));
        if (!host->start()) {
            p.skip = "the script host did not start: " + host->error;
            return p;
        }
        host->step_frames(2);  // the behaviours are created and started before the clock starts
        if (!host->scripts.errors().empty()) {
            p.skip = "a behaviour failed: " + host->scripts.errors().front().message;
            return p;
        }
        p.items = 300 * 30;
        p.unit = "behaviour frames";
        p.run = [host] {
            host->step_frames(30);
            return double(host->scripts.errors().size());  // 0: the positions move on from one run to the next
        };
        return p;
    };
    return b;
}

}  // namespace

void add_script_benches(std::vector<Bench>& out) {
    out.push_back(script_function("script.native_calls",
                                  "JS -> C++ calls: world.find, entity.alive and entity.id, 60000 times", 60000,
                                  "calls", R"(
globalThis.bench = function () {
  let n = 0;
  for (let i = 0; i < 20000; i++) {
    const e = world.find('e' + (i % 100));
    if (e.alive) n += e.id.length;
  }
  return n;
};)"));
    out.push_back(script_function(
        "script.component_access",
        "Component fields from JS: 100 entities x 100 passes of position, a Sprite colour and a Collider2D size",
        100 * 100, "entity passes", R"(
globalThis.entities = [];
for (let i = 0; i < 100; i++) globalThis.entities.push(world.find('e' + i));
globalThis.bench = function () {
  let sum = 0;
  for (let pass = 0; pass < 100; pass++) {
    for (const e of globalThis.entities) {
      e.position.x = pass + 1;
      const s = e.get('Sprite');
      s.color.a = 0.5 + (pass % 2) * 0.25;
      sum += s.color.a + e.position.x + e.get('Collider2D').size.x;
    }
  }
  return sum;
};)"));
    out.push_back(script_behaviours());
}

}  // namespace fa::bench
