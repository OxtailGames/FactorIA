// lightmap.bake, lightmap.bake_start / bake_status / bake_cancel (M73.4c): the jobs, the mapping of the scene to the bake, the files, the
// determinism across thread counts. The numbers of the bake itself are tested in engine/scene/tests/test_lightmap_bake.cpp; the render of a
// baked scene in engine/render/tests/lightmap_tests.cpp and tools/cli/tests/lightmap_bake_test.cpp.
#include <doctest.h>

#include <array>
#include <chrono>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <map>
#include <set>
#include <thread>

#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/core/image_float.h"
#include "fa/render/hdri.h"
#include "fa/render/lightmap_geometry.h"
#include "fa/runtime/engine.h"
#include "fa/scene/components.h"
#include "fa/scene/light_probes.h"
#include "fa/scene/lightmap_manifest.h"
#include "fa/scene/lightmap_uv.h"
#include "lightmap_bake_job.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Lightmap Commands Test",
  "id": "com.example.lightmapcommands",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

// A floor, a box, a baked sun and an ambient sky: small enough to bake in a fraction of a second at 4 texels per meter.
std::string scene_text(const std::string& extra = "", const std::string& settings = R"("ambientLight": "#404060")") {
    return R"({
  "format": "factoria.scene/1",
  "settings": { )" +
           settings + R"( },
  "entities": [
    { "id": "cam", "name": "Camera", "components": { "Transform": { "position": [0, 2, 6] }, "Camera": { "clearColor": "#202020" } } },
    { "id": "floor", "name": "floor", "components": { "Transform": { "position": [0, -0.1, 0], "scale": [6, 0.2, 6] }, "MeshRenderer": { "mesh": "cube" } } },
    { "id": "box", "name": "box", "components": { "Transform": { "position": [0, 0.5, 0] }, "MeshRenderer": { "mesh": "cube", "color": "#c08040" } } },
    { "id": "sun", "name": "sun", "components": { "Transform": { "rotation": [-50, 30, 0] }, "Light": { "type": "directional", "intensity": 2, "mode": "baked" } } })" +
           extra + R"(
  ]
})";
}

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const std::string& name, const std::string& scene = scene_text()) {
        dir = fs::make_temp_dir("fa_lightmapcmd_test_" + name).value();
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary) << kProject;
        std::ofstream(dir / "scenes/main.scene.json", std::ios::binary) << scene;
        std::ofstream(dir / "scenes/other.scene.json", std::ios::binary) << scene_text();
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    // The files of the scenes folder, sorted.
    std::vector<std::string> files() const {
        std::vector<std::string> out;
        for (const auto& f : stdfs::directory_iterator(dir / "scenes")) out.push_back(f.path().filename().string());
        std::sort(out.begin(), out.end());
        return out;
    }
    std::string read(const std::string& rel) const {
        std::ifstream in(dir / rel, std::ios::binary);
        return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    }
};

EngineConfig cfg(const TempProject& p, const char* threads = "2") {
    EngineConfig c;
    c.projectDir = p.dir.generic_string();
    c.headless = true;
    c.hotReload = false;
    c.jobThreads = threads;
    return c;
}

// A cheap bake: 4 texels per meter, 8 samples, no denoiser.
Json small(Json more = Json::object()) {
    Json a = Json::object(
        {{"texelsPerMeter", 4}, {"samples", 8}, {"shadowSamples", 2}, {"denoiseRadius", 0}, {"maxPageSize", 256}});
    for (auto it = more.begin(); it != more.end(); ++it) a[it.key()] = it.value();
    return a;
}

// bake_status until the job leaves "running" (a deadline far above what the tiny bake needs).
Json wait_done(Engine& e, const std::string& job) {
    const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(120);
    for (;;) {
        auto r = e.commands().call("lightmap.bake_status", Json::object({{"job", job}}));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        if (r.result["state"] != "running") return r.result;
        REQUIRE(std::chrono::steady_clock::now() < deadline);
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
}

}  // namespace

TEST_CASE("lightmap.bake: bakes the scene, writes the pages and the manifest, and sets SceneSettings.lightmaps") {
    TempProject p("sync");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto r = e.commands().call("lightmap.bake", small());
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["manifest"] == "scenes/main.lightmap.json");
    CHECK(r.result["applied"] == true);
    CHECK(r.result["entities"] == 2);  // the floor and the box; the sun and the camera have no mesh
    CHECK(r.result["texels"].get<double>() > 100);
    CHECK(r.result["rays"].get<double>() > 1000);
    CHECK(e.world().settings().lightmaps == "scenes/main.lightmap.json");

    auto manifest = load_lightmap_manifest("scenes/main.lightmap.json");
    REQUIRE_MESSAGE(manifest.ok(), manifest.error().message);
    CHECK(manifest->version == kLightmapManifestVersion);
    CHECK(manifest->uvVersion == kLightmapUvVersion);
    REQUIRE(manifest->pages.size() >= 1);
    CHECK(manifest->pages.size() == r.result["pages"].size());
    CHECK(manifest->find(e.world().id_of(e.world().find("floor"))) != nullptr);
    for (const LightmapEntry& en : manifest->entities) {
        CHECK(en.mesh == "cube");
        CHECK(en.uv == "generated");
        CHECK(en.page >= 0);
        CHECK(en.page < int(manifest->pages.size()));
        CHECK(en.scaleOffset[0] > 0);
        CHECK(en.scaleOffset[0] + en.scaleOffset[2] <= 1.0001f);  // the square is inside the page
        CHECK(en.scaleOffset[1] + en.scaleOffset[3] <= 1.0001f);
    }
    // The pages hold light: the floor is lit by the baked sun (a page that is all black is a bake that lost its light).
    double sum = 0;
    for (const LightmapPage& pg : manifest->pages) {
        auto img = load_hdr(pg.file);
        REQUIRE_MESSAGE(img.ok(), img.error().message);
        CHECK(img->width == pg.width);
        CHECK(img->height == pg.height);
        for (float v : img->data) {
            CHECK(std::isfinite(v));
            sum += v;
        }
    }
    CHECK(sum > 10.0);
}

TEST_CASE("lightmap.bake: arguments are checked with a JSON pointer and a hint before anything is baked") {
    TempProject p("args");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto bad = [&](Json args, const std::string& needle) {
        auto r = c.call("lightmap.bake", std::move(args));
        CHECK_FALSE(r.ok);
        CHECK_MESSAGE(r.error.dump().find(needle) != std::string::npos, r.error.dump());
        CHECK(p.files().size() == 2);  // nothing was written
    };
    bad(Json::object({{"samples", 0}}), "/samples");
    bad(Json::object({{"samples", 2.5}}), "/samples");
    bad(Json::object({{"maxPageSize", 99999}}), "/maxPageSize");
    bad(Json::object({{"texelsPerMeter", -1}}), "/texelsPerMeter");
    bad(Json::object({{"texelsPerMeter", "lots"}}), "/texelsPerMeter");
    bad(Json::object({{"sky", "gradiant"}}), "gradient");
    bad(Json::object({{"path", "scenes/main.json"}}), ".lightmap.json");
    bad(Json::object({{"path", "../outside.lightmap.json"}}), "outside");
    bad(Json::object({{"apply", "yes"}}), "/apply");
    bad(Json::object({{"sky", "environment"}}), "environmentMap");
    // A scene with nothing that receives light.
    CHECK(c.call("scene.set_component", Json::object({{"id", "floor"},
                                                      {"component", "MeshRenderer"},
                                                      {"fields", Json::object({{"receiveGI", false}})}}))
              .ok);
    CHECK(c.call("scene.set_component",
                 Json::object(
                     {{"id", "box"}, {"component", "MeshRenderer"}, {"fields", Json::object({{"lightmapScale", 0}})}}))
              .ok);
    bad(Json::object(), "nothing to bake");
}

TEST_CASE("lightmap jobs: start, poll, finish, and the result is handed to the scene once") {
    TempProject p("job");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto started = c.call("lightmap.bake_start", small());
    REQUIRE_MESSAGE(started.ok, started.error.dump());
    const std::string job = started.result["job"];
    CHECK(job.rfind("bake:", 0) == 0);
    CHECK(started.result["manifest"] == "scenes/main.lightmap.json");
    const Json done = wait_done(e, job);
    CHECK_MESSAGE(done["state"] == "done", done.dump());
    CHECK(done["progress"] == 1);
    CHECK(done["result"]["entities"] == 2);
    CHECK(done["handOver"]["applied"] == true);
    CHECK(done["handOver"]["settingsChanged"] == true);
    CHECK(e.world().settings().lightmaps == "scenes/main.lightmap.json");
    // Asked again: the same answer, the hand-over is not repeated.
    auto again = c.call("lightmap.bake_status", Json::object({{"job", job}}));
    REQUIRE(again.ok);
    CHECK(again.result["state"] == "done");
    CHECK(again.result["handOver"] == done["handOver"]);
    // A finished job is not an error to cancel.
    auto late = c.call("lightmap.bake_cancel", Json::object({{"job", job}}));
    REQUIRE_MESSAGE(late.ok, late.error.dump());
    CHECK(late.result["state"] == "done");
    CHECK(late.result["note"].get<std::string>().find("already ended") != std::string::npos);
}

TEST_CASE(
    "lightmap jobs: an unknown job, a missing job and a second bake of the same manifest are refused with a hint") {
    TempProject p("unknown");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    for (const char* name : {"lightmap.bake_status", "lightmap.bake_cancel"}) {
        auto none = c.call(name, Json::object({{"job", "bake:99"}}));
        CHECK_FALSE(none.ok);
        CHECK(none.error.dump().find("unknown_job") != std::string::npos);
        CHECK(none.error.dump().find("no bake job exists") != std::string::npos);
        auto missing = c.call(name, Json::object());
        CHECK_FALSE(missing.ok);
        CHECK(missing.error.dump().find("job") != std::string::npos);
    }
    // A slow bake that is still running refuses a second one for the same manifest, and does not refuse another file.
    auto first =
        c.call("lightmap.bake_start", Json::object({{"texelsPerMeter", 64}, {"samples", 3000}, {"maxPageSize", 1024}}));
    REQUIRE_MESSAGE(first.ok, first.error.dump());
    const std::string job = first.result["job"];
    auto second = c.call("lightmap.bake_start", small());
    CHECK_FALSE(second.ok);
    CHECK(second.error.dump().find("already running") != std::string::npos);
    auto named = c.call("lightmap.bake_status", Json::object({{"job", "bake:98"}}));
    CHECK(named.error.dump().find(job) != std::string::npos);  // the hint lists the live jobs
    auto cancel = c.call("lightmap.bake_cancel", Json::object({{"job", job}}));
    REQUIRE_MESSAGE(cancel.ok, cancel.error.dump());
    const Json end = wait_done(e, job);
    CHECK(end["state"] == "cancelled");
}

TEST_CASE("lightmap jobs: cancel stops a running bake, writes nothing and a second cancel is not an error") {
    TempProject p("cancel");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    // About a thousand million rays: minutes. It is cancelled as soon as it traces.
    auto started =
        c.call("lightmap.bake_start", Json::object({{"texelsPerMeter", 64}, {"samples", 3000}, {"maxPageSize", 1024}}));
    REQUIRE_MESSAGE(started.ok, started.error.dump());
    const std::string job = started.result["job"];
    const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(120);
    for (;;) {
        auto s = c.call("lightmap.bake_status", Json::object({{"job", job}}));
        REQUIRE(s.ok);
        REQUIRE(s.result["state"] == "running");
        if (s.result["phase"] == "trace") {
            CHECK(s.result["progress"].get<double>() >= 0.1);
            CHECK(s.result["progress"].get<double>() < 1.0);
            break;
        }
        REQUIRE(std::chrono::steady_clock::now() < deadline);
        std::this_thread::sleep_for(std::chrono::milliseconds(2));
    }
    auto first = c.call("lightmap.bake_cancel", Json::object({{"job", job}}));
    REQUIRE_MESSAGE(first.ok, first.error.dump());
    auto second = c.call("lightmap.bake_cancel", Json::object({{"job", job}}));
    REQUIRE_MESSAGE(second.ok, second.error.dump());
    const Json end = wait_done(e, job);
    CHECK(end["state"] == "cancelled");
    CHECK(end["error"].get<std::string>().find("no file was changed") != std::string::npos);
    CHECK(p.files().size() == 2);  // main and other, nothing else: no page, no manifest
    CHECK(e.world().settings().lightmaps.empty());
    // The same bake can start again once the first one ended.
    auto again = c.call("lightmap.bake_start", small());
    REQUIRE_MESSAGE(again.ok, again.error.dump());
    CHECK(wait_done(e, again.result["job"])["state"] == "done");
}

TEST_CASE("lightmap.bake: a cancel in any phase ends the bake with the code cancelled and leaves no file") {
    for (const char* phase : {"starting", "geometry", "layout", "prepare", "rasterize", "trace", "denoise", "dilate"}) {
        CAPTURE(phase);
        TempProject p(std::string("phase_") + phase);
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
        std::atomic<bool> flag{false};
        bool seen = false;
        CommandCancelScope cancelScope(&flag);
        CommandProgressScope progressScope([&](std::string_view message) {
            if (message.find(std::string(": ") + phase) != std::string_view::npos) {
                seen = true;
                flag.store(true);
            }
            return true;
        });
        Json args = small();
        args["denoiseRadius"] = 1;  // the denoise phase exists
        auto r = e.commands().call("lightmap.bake", args);
        CHECK(seen);
        CHECK_FALSE(r.ok);
        CHECK_MESSAGE(r.error.dump().find("cancelled") != std::string::npos, r.error.dump());
        CHECK(p.files().size() == 2);
        CHECK(e.world().settings().lightmaps.empty());
    }
}

TEST_CASE("lightmap jobs: a result is not given to a scene it was not made for") {
    TempProject p("scene");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto started = c.call("lightmap.bake_start", small());
    REQUIRE_MESSAGE(started.ok, started.error.dump());
    REQUIRE_MESSAGE(e.load_scene("scenes/other.scene.json", &err), err);
    const Json done = wait_done(e, started.result["job"]);
    CHECK(done["state"] == "done");
    CHECK(done["handOver"]["applied"] == false);
    CHECK(done["handOver"]["note"].get<std::string>().find("no longer 'scenes/main.scene.json'") != std::string::npos);
    CHECK(e.world().settings().lightmaps.empty());
    CHECK(stdfs::exists(p.dir / "scenes/main.lightmap.json"));  // the files are there for the scene they belong to
}

TEST_CASE("lightmap.bake: the same scene gives the same bytes on one thread and on four") {
    std::string manifestA, manifestB;
    std::vector<std::string> pagesA, pagesB;
    for (const char* threads : {"inline", "4"}) {
        CAPTURE(threads);
        TempProject p(std::string("det_") + threads);
        Engine e;
        std::string err;
        REQUIRE_MESSAGE(e.init(cfg(p, threads), nullptr, &err), err);
        Json args = small();
        args["denoiseRadius"] = 2;
        auto r = e.commands().call("lightmap.bake", args);
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        auto& manifest = std::string(threads) == "inline" ? manifestA : manifestB;
        auto& pages = std::string(threads) == "inline" ? pagesA : pagesB;
        manifest = p.read("scenes/main.lightmap.json");
        for (const std::string& f : p.files())
            if (f.size() > 4 && f.substr(f.size() - 4) == ".hdr") pages.push_back(f + "|" + p.read("scenes/" + f));
    }
    CHECK(!manifestA.empty());
    CHECK(manifestA == manifestB);
    REQUIRE(!pagesA.empty());
    CHECK(pagesA == pagesB);  // names (they carry the hash of the pixels) and bytes
}

TEST_CASE("lightmap.bake: a rebake replaces the old pages, and an unchanged scene rewrites nothing") {
    TempProject p("rebake");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    REQUIRE(c.call("lightmap.bake", small()).ok);
    const std::vector<std::string> first = p.files();
    const std::string manifest = p.read("scenes/main.lightmap.json");
    REQUIRE(c.call("lightmap.bake", small()).ok);
    CHECK(p.files() == first);
    CHECK(p.read("scenes/main.lightmap.json") == manifest);
    // Another seed is another noise: other pages, and the old ones are gone.
    auto r = c.call("lightmap.bake", small(Json::object({{"seed", 7}})));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const std::vector<std::string> second = p.files();
    CHECK(second.size() == first.size());
    CHECK(second != first);
    std::size_t hdr = 0;
    for (const std::string& f : second) hdr += f.size() > 4 && f.substr(f.size() - 4) == ".hdr";
    CHECK(hdr == r.result["pages"].size());
    CHECK(p.read("scenes/main.lightmap.json") != manifest);
}

TEST_CASE("lightmap.bake: a manifest that cannot be replaced keeps the old bake whole and says how to go on (Windows "
          "file rules)") {
    const bool before = fs::windows_rules();
    fs::set_windows_rules(true);
    TempProject p("locked");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    REQUIRE(c.call("lightmap.bake", small()).ok);
    const std::vector<std::string> files = p.files();
    const std::string manifest = p.read("scenes/main.lightmap.json");
    {
        // The editor's image viewer, an antivirus scan: the manifest is open, so it cannot be replaced.
        fs::ReadStream hold(p.dir / "scenes/main.lightmap.json", std::ios::binary);
        REQUIRE(hold.is_open());
        auto r = c.call("lightmap.bake", small(Json::object({{"seed", 3}})));
        CHECK_FALSE(r.ok);
        const std::string text = r.error.dump();
        CHECK_MESSAGE(text.find("main.lightmap.json") != std::string::npos, text);
        CHECK_MESSAGE(text.find("close it") != std::string::npos, text);
        CHECK_MESSAGE(text.find("`path`") != std::string::npos, text);
    }
    CHECK(p.read("scenes/main.lightmap.json") == manifest);  // the old manifest is whole
    CHECK(p.files() == files);                               // and the pages of the failed bake are not left behind
    // The suggested way out works: another manifest name.
    auto other = c.call("lightmap.bake", small(Json::object({{"seed", 3}, {"path", "scenes/second.lightmap.json"}})));
    CHECK_MESSAGE(other.ok, other.error.dump());
    fs::set_windows_rules(before);
}

TEST_CASE("lightmap bake plan: lights, the sky and the meshes of the scene are mapped as documented") {
    const std::string extra = R"(,
    { "id": "lamp", "components": { "Transform": { "position": [1, 3, 0] }, "Light": { "type": "point", "intensity": 5, "range": 10, "mode": "mixed", "color": "#ffff00" } } },
    { "id": "spot", "components": { "Transform": { "position": [0, 4, 0], "rotation": [-90, 0, 0] }, "Light": { "type": "spot", "intensity": 3, "range": 5, "spotAngle": 80, "innerAngle": 85, "mode": "baked" } } },
    { "id": "live", "components": { "Light": { "type": "point", "mode": "realtime" } } },
    { "id": "panel", "components": { "Transform": { "position": [0, 3, 2] }, "Light": { "type": "area", "shape": "disc", "size": [2, 1], "intensity": 4, "mode": "baked" } } },
    { "id": "ghost", "active": false, "components": { "MeshRenderer": { "mesh": "cube" }, "Light": { "type": "point", "mode": "baked" } } },
    { "id": "emitter", "components": { "Transform": { "position": [3, 1, 0] }, "MeshRenderer": { "mesh": "cube", "color": "#ff0000", "emissive": "#00ff00", "emissiveStrength": 2, "receiveGI": false, "castShadows": false } } }
)";
    TempProject p("plan", scene_text(extra));
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    lightmap_job::Options opt;
    auto plan =
        lightmap_job::make_plan(e.world(), std::string("scenes/main.scene.json"), opt,
                                (p.dir / "scenes/main.lightmap.json").generic_string(), "scenes/main.lightmap.json");
    REQUIRE_MESSAGE(plan.ok(), plan.error().message);
    // sun (baked), lamp (mixed), spot, panel: the realtime light and the inactive entity are left out.
    REQUIRE(plan->lights.size() == 4);
    std::map<BakeLightKind, int> kinds;
    for (const BakeLight& l : plan->lights) ++kinds[l.kind];
    CHECK(kinds[BakeLightKind::Directional] == 1);
    CHECK(kinds[BakeLightKind::Point] == 1);
    CHECK(kinds[BakeLightKind::Spot] == 1);
    CHECK(kinds[BakeLightKind::Area] == 1);
    for (const BakeLight& l : plan->lights) {
        if (l.kind == BakeLightKind::Directional) {
            CHECK(l.mode == BakeLightMode::Baked);
            CHECK(l.intensity == doctest::Approx(2));
            CHECK(l.direction.y < 0);  // pitched down
        } else if (l.kind == BakeLightKind::Point) {
            CHECK(l.mode == BakeLightMode::IndirectOnly);  // mixed: the direct light stays realtime
            CHECK(l.falloff == BakeFalloff::Engine);
            CHECK(l.range == doctest::Approx(10));
            CHECK(l.color.z == doctest::Approx(0).epsilon(0.01));
            CHECK(l.position.y == doctest::Approx(3));
        } else if (l.kind == BakeLightKind::Spot) {
            CHECK(l.falloff == BakeFalloff::Engine);
            CHECK(l.spotAngleDeg == doctest::Approx(80));
            CHECK(l.spotInnerDeg == doctest::Approx(80));  // never wider than the outer cone
            CHECK(l.direction.y == doctest::Approx(-1).epsilon(0.001));
        } else {
            CHECK(l.width == doctest::Approx(2 * 0.8862)
                                 .epsilon(0.001));  // a disc of diameter 2 becomes the square of the same area
            CHECK(l.height == doctest::Approx(2 * 0.8862).epsilon(0.001));
        }
    }
    bool disc = false;
    for (const std::string& w : plan->warnings) disc = disc || w.find("ghost") != std::string::npos;
    CHECK_FALSE(disc);  // an inactive entity is not mentioned
    // Meshes sorted by id; the emitter is geometry that shadows and lights but receives nothing.
    REQUIRE(plan->meshes.size() == 3);
    CHECK(plan->meshes[0].id == "box");
    CHECK(plan->meshes[1].id == "emitter");
    CHECK(plan->meshes[2].id == "floor");
    CHECK(plan->meshes[0].receiver);
    CHECK_FALSE(plan->meshes[1].receiver);
    CHECK_FALSE(plan->meshes[1].castsShadow);
    CHECK(plan->meshes[1].emissive.y == doctest::Approx(2.0f));
    CHECK(plan->meshes[1].emissive.x == doctest::Approx(0.0f));
    CHECK(plan->meshes[0].texelsPerMeter == doctest::Approx(16));
    // The ambient sky is the constant sky; the same scene gives the same settings hash, another seed another one.
    CHECK(plan->options.sky == lightmap_job::SkyChoice::Ambient);
    CHECK(plan->sky.zenith.x == doctest::Approx(plan->sky.horizon.x));
    CHECK(plan->sky.zenith.z > plan->sky.zenith.x);  // #404060 is bluish
    auto again =
        lightmap_job::make_plan(e.world(), std::string("scenes/main.scene.json"), opt,
                                (p.dir / "scenes/main.lightmap.json").generic_string(), "scenes/main.lightmap.json");
    REQUIRE(again.ok());
    CHECK(again->settingsHash == plan->settingsHash);
    opt.settings.seed = 5;
    auto seeded =
        lightmap_job::make_plan(e.world(), std::string("scenes/main.scene.json"), opt,
                                (p.dir / "scenes/main.lightmap.json").generic_string(), "scenes/main.lightmap.json");
    REQUIRE(seeded.ok());
    CHECK(seeded->settingsHash != plan->settingsHash);
    // Gradient sky takes skyColor and horizonColor.
    opt.settings.seed = 0;
    opt.sky = lightmap_job::SkyChoice::Gradient;
    e.world().settings().skyColor = Color{0, 0, 1, 1};
    e.world().settings().horizonColor = Color{1, 0, 0, 1};
    auto grad =
        lightmap_job::make_plan(e.world(), std::string("scenes/main.scene.json"), opt,
                                (p.dir / "scenes/main.lightmap.json").generic_string(), "scenes/main.lightmap.json");
    REQUIRE(grad.ok());
    CHECK(grad->sky.zenith.z == doctest::Approx(1));
    CHECK(grad->sky.horizon.x == doctest::Approx(1));
    CHECK(grad->sky.ground.x == doctest::Approx(0.55));
    // A physical sky cannot be evaluated: the plan says so instead of baking something else silently.
    e.world().settings().skyModel = SkyModel::Physical;
    opt.sky = lightmap_job::SkyChoice::Auto;
    auto phys =
        lightmap_job::make_plan(e.world(), std::string("scenes/main.scene.json"), opt,
                                (p.dir / "scenes/main.lightmap.json").generic_string(), "scenes/main.lightmap.json");
    REQUIRE(phys.ok());
    bool said = false;
    for (const std::string& w : phys->warnings) said = said || w.find("physical sky") != std::string::npos;
    CHECK(said);
}

TEST_CASE("lightmap bake plan: the environment map is rotated like the renderer rotates it") {
    // The renderer looks the picture up with hdri_uv; the baker with u = 0.5 + atan2(z, x) / 2pi + rotationDeg / 360. The plan's rotation makes
    // them the same lookup for every direction and every SceneSettings.environmentRotation.
    for (float rotation : {0.0f, 37.0f, 90.0f, 180.0f, -75.0f, 400.0f}) {
        CAPTURE(rotation);
        const float baker = lightmap_job::baker_rotation_for_environment(rotation);
        for (int i = 0; i < 16; ++i) {
            for (int j = 1; j < 8; ++j) {
                const float az = float(i) / 16.0f * 6.2831853f, el = (float(j) / 8.0f - 0.5f) * 3.14159f;
                const float x = std::cos(el) * std::cos(az), y = std::sin(el), z = std::cos(el) * std::sin(az);
                float u = 0, v = 0;
                hdri_uv(x, y, z, rotation, u, v);
                double bu = 0.5 + std::atan2(double(z), double(x)) / 6.283185307179586 + double(baker) / 360.0;
                bu -= std::floor(bu);
                double diff = std::fabs(bu - double(u));
                diff = std::min(diff, 1.0 - diff);
                CHECK(diff < 1e-4);
            }
        }
    }
}

TEST_CASE("lightmap bake plan: an environment map is used, a missing or malformed one is refused with what to do") {
    TempProject p(
        "hdri",
        scene_text("",
                   R"("environmentMap": "assets/sky.hdr", "environmentIntensity": 1.5, "environmentRotation": 30)"));
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    lightmap_job::Options opt;
    auto plan =
        lightmap_job::make_plan(e.world(), std::string("scenes/main.scene.json"), opt,
                                (p.dir / "scenes/main.lightmap.json").generic_string(), "scenes/main.lightmap.json");
    REQUIRE_MESSAGE(plan.ok(), plan.error().message);
    CHECK(plan->options.sky == lightmap_job::SkyChoice::Environment);
    CHECK(plan->environmentMap == "assets/sky.hdr");
    CHECK(plan->environmentScale == doctest::Approx(1.5));
    CHECK(plan->environmentRotation == doctest::Approx(120));
    // The file is missing: the bake says so (and writes nothing).
    auto r = e.commands().call("lightmap.bake", small());
    CHECK_FALSE(r.ok);
    CHECK(r.error.dump().find("sky.hdr") != std::string::npos);
    CHECK(p.files().size() == 2);
    // A picture with the wrong shape.
    auto img = ImageF::create(8, 8, 3);
    REQUIRE(img.ok());
    REQUIRE(save_hdr(*img, (p.dir / "assets/sky.hdr").generic_string()).ok());
    auto wrong = e.commands().call("lightmap.bake", small());
    CHECK_FALSE(wrong.ok);
    CHECK(wrong.error.dump().find("equirectangular") != std::string::npos);
    // A good one lights the scene: compared with no sky at all, the gain is the sky's colour (the sun adds the same to every channel).
    auto sums = [&](Json args) {
        auto baked = e.commands().call("lightmap.bake", args);
        REQUIRE_MESSAGE(baked.ok, baked.error.dump());
        auto manifest = load_lightmap_manifest("scenes/main.lightmap.json");
        REQUIRE(manifest.ok());
        std::array<double, 3> total{};
        for (const LightmapPage& pg : manifest->pages) {
            auto page = load_hdr(pg.file);
            REQUIRE(page.ok());
            for (std::size_t i = 0; i + 2 < page->data.size(); i += 3)
                for (std::size_t k = 0; k < 3; ++k) total[k] += page->data[i + k];
        }
        return total;
    };
    auto sky = ImageF::create(32, 16, 3);
    REQUIRE(sky.ok());
    for (int y = 0; y < 16; ++y)
        for (int x = 0; x < 32; ++x) {
            float* px = sky->at(x, y);
            px[0] = 0.2f;
            px[1] = 0.3f;
            px[2] = 1.0f;
        }
    REQUIRE(save_hdr(*sky, (p.dir / "assets/sky.hdr").generic_string()).ok());
    const auto without = sums(small(Json::object({{"bounces", 0}, {"sky", "none"}})));
    const auto with = sums(small(Json::object({{"bounces", 0}})));
    CHECK(with[0] - without[0] > 1.0);
    CHECK(with[2] - without[2] > 3.0 * (with[0] - without[0]));
}

TEST_CASE("lightmap.bake: a LightProbeGroup is baked in the same job, listed in the result and the manifest") {
    const std::string group =
        R"(, { "id": "probes", "name": "probes", "components": { "Transform": { "position": [0, 1, 0] }, "LightProbeGroup": { "size": [4, 2, 4], "spacing": 2, "points": [[0, 0.5, 0]] } } })";
    TempProject p("probes", scene_text(group));
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto r = e.commands().call("lightmap.bake", small());
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    REQUIRE(r.result.contains("probes"));
    const Json& pr = r.result["probes"];
    CHECK(pr["count"] == 3 * 2 * 3 + 1);   // the grid (4 x 2 x 4 m at 2 m: 3 x 2 x 3) and the point
    CHECK(pr["invalid"].get<int>() >= 1);  // the point sits in the box (a unit cube at y = 0.5)
    REQUIRE(pr["groups"].size() == 2);     // the grid and the points are two groups of the same entity
    CHECK(pr["groups"][0]["id"] == "probes");

    auto manifest = load_lightmap_manifest("scenes/main.lightmap.json");
    REQUIRE_MESSAGE(manifest.ok(), manifest.error().message);
    CHECK(manifest->probes.file == pr["file"].get<std::string>());
    CHECK(manifest->probes.count == pr["count"].get<int>());
    CHECK(manifest->probes.invalid == pr["invalid"].get<int>());
    auto set = load_probe_set(manifest->probes.file);
    REQUIRE_MESSAGE(set.ok(), set.error().message);
    CHECK(int(set->size()) == manifest->probes.count);
    CHECK(set->baked());
    CHECK(int(set->invalid_count()) == manifest->probes.invalid);
    // A rebake of the unchanged scene keeps one probe file next to the pages.
    auto again = e.commands().call("lightmap.bake", small());
    REQUIRE_MESSAGE(again.ok, again.error.dump());
    CHECK(again.result["probes"]["file"] == pr["file"]);
    int probeFiles = 0;
    for (const std::string& f : p.files())
        if (f.size() > 7 && f.substr(f.size() - 7) == ".probes") ++probeFiles;
    CHECK(probeFiles == 1);
    e.shutdown();
}

TEST_CASE("lightmap.bake: a scene without a LightProbeGroup has no probes key and no probe file") {
    TempProject plain("noprobes");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(plain), nullptr, &err), err);
    auto r = e.commands().call("lightmap.bake", small());
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK_FALSE(r.result.contains("probes"));
    auto m = load_lightmap_manifest("scenes/main.lightmap.json");
    REQUIRE_MESSAGE(m.ok(), m.error().message);
    CHECK(m->probes.file.empty());
    for (const std::string& f : plain.files()) CHECK(f.find(".probes") == std::string::npos);
    e.shutdown();
}

TEST_CASE("lightmap.bake: a LightProbeGroup with a mistake stops the bake with its field and a hint") {
    const std::string group =
        R"(, { "id": "probes", "name": "probes", "components": { "LightProbeGroup": { "size": [400, 400, 400], "spacing": 0.5 } } })";
    TempProject p("probesbad", scene_text(group));
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto r = e.commands().call("lightmap.bake", small());
    REQUIRE_FALSE(r.ok);
    const std::string text = r.error.dump();
    CHECK(text.find("probes") != std::string::npos);
    CHECK(text.find("per group") != std::string::npos);
    CHECK(text.find("spacing") != std::string::npos);
    CHECK(e.world().settings().lightmaps.empty());
    e.shutdown();
}

namespace {
std::size_t count_files(const TempProject& p, const std::string& suffix) {
    std::size_t n = 0;
    for (const std::string& f : p.files())
        if (f.size() > suffix.size() && f.substr(f.size() - suffix.size()) == suffix) ++n;
    return n;
}
}  // namespace

TEST_CASE("lightmap.bake: a page or probe file that could not be deleted (open elsewhere on Windows) is swept by the "
          "next bake") {
    const bool before = fs::windows_rules();
    fs::set_windows_rules(true);
    const std::string group =
        R"(, { "id": "probes", "name": "probes", "components": { "Transform": { "position": [0, 1, 0] }, "LightProbeGroup": { "size": [4, 2, 4], "spacing": 2 } } })";
    TempProject p("sweep", scene_text(group));
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    // Files that look like nothing of this manifest's: never touched.
    std::ofstream(p.dir / "scenes/main.lightmap.v2.0123abcd.0.hdr", std::ios::binary) << "other";
    std::ofstream(p.dir / "scenes/main.lightmap.notes.txt", std::ios::binary) << "notes";
    std::ofstream(p.dir / "scenes/main.lightmap.0123abcd.x.hdr", std::ios::binary) << "not a page";
    REQUIRE(c.call("lightmap.bake", small()).ok);
    std::string heldPage, heldProbes;
    for (const std::string& f : p.files()) {
        if (f.rfind("main.lightmap.", 0) != 0) continue;
        if (f.size() > 4 && f.substr(f.size() - 4) == ".hdr" && f.find("v2") == std::string::npos &&
            f.find(".x.") == std::string::npos && heldPage.empty())
            heldPage = f;
        if (f.size() > 7 && f.substr(f.size() - 7) == ".probes") heldProbes = f;
    }
    REQUIRE_FALSE(heldPage.empty());
    REQUIRE_FALSE(heldProbes.empty());
    {
        // A viewer has both open: the next bake cannot delete them, and leaves them behind.
        fs::ReadStream holdPage(p.dir / "scenes" / heldPage, std::ios::binary);
        fs::ReadStream holdProbes(p.dir / "scenes" / heldProbes, std::ios::binary);
        REQUIRE(holdPage.is_open());
        REQUIRE(holdProbes.is_open());
        auto r = c.call("lightmap.bake", small(Json::object({{"seed", 7}})));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(stdfs::exists(p.dir / "scenes" / heldPage));  // the orphans
        CHECK(stdfs::exists(p.dir / "scenes" / heldProbes));
        CHECK(r.result["probes"]["file"].get<std::string>() != "scenes/" + heldProbes);
    }
    // Closed again: the next bake finds them by their names and deletes them, and keeps what its own manifest lists.
    auto last = c.call("lightmap.bake", small(Json::object({{"seed", 9}})));
    REQUIRE_MESSAGE(last.ok, last.error.dump());
    CHECK_FALSE(stdfs::exists(p.dir / "scenes" / heldPage));
    CHECK_FALSE(stdfs::exists(p.dir / "scenes" / heldProbes));
    CHECK(count_files(p, ".probes") == 1);
    CHECK(count_files(p, ".hdr") ==
          last.result["pages"].size() + 2);  // its pages and the two files that are not its own
    for (const Json& page : last.result["pages"]) {
        const std::string file = page.is_string() ? page.get<std::string>() : page["file"].get<std::string>();
        CHECK(stdfs::exists(p.dir / file));
    }
    CHECK(stdfs::exists(p.dir / "scenes" / "main.lightmap.v2.0123abcd.0.hdr"));
    CHECK(stdfs::exists(p.dir / "scenes" / "main.lightmap.notes.txt"));
    CHECK(stdfs::exists(p.dir / "scenes" / "main.lightmap.0123abcd.x.hdr"));
    CHECK(stdfs::exists(p.dir / "scenes" / "main.lightmap.json"));
    fs::set_windows_rules(before);
    e.shutdown();
}

TEST_CASE("lightmap jobs: only the last 8 finished jobs are kept, whether or not anybody asked for their status "
          "(a bake with nothing to apply)") {
    TempProject p("prune");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p, "inline"), nullptr, &err),
                    err);  // inline: bake_start returns with the job finished, nobody has asked
    auto& c = e.commands();
    std::vector<std::string> ids;
    for (int i = 0; i < 12; ++i) {
        auto started = c.call("lightmap.bake_start", small(Json::object({{"apply", false}})));
        REQUIRE_MESSAGE(started.ok, started.error.dump());
        ids.push_back(started.result["job"]);
    }
    // The oldest are forgotten and say so (no status call has pruned anything: bake_start did); the newest answer.
    for (int i = 0; i < 3; ++i) {
        auto old = c.call("lightmap.bake_status", Json::object({{"job", ids[std::size_t(i)]}}));
        CHECK_FALSE(old.ok);
        CHECK(old.error.dump().find("finished jobs are kept") != std::string::npos);
    }
    for (int i = 10; i < 12; ++i)
        CHECK(c.call("lightmap.bake_status", Json::object({{"job", ids[std::size_t(i)]}})).ok);
    e.shutdown();
}

TEST_CASE("lightmap commands: while the editor plays, a bake is refused and a finished one is not applied to the play "
          "world") {
    TempProject p("play");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    // A bake that started before Play and ends while the game runs.
    auto started = c.call("lightmap.bake_start", small());
    REQUIRE_MESSAGE(started.ok, started.error.dump());
    e.set_play_world(true);
    auto sync = c.call("lightmap.bake", small());
    REQUIRE_FALSE(sync.ok);
    CHECK(sync.error.dump().find("game_running") != std::string::npos);
    CHECK(sync.error.dump().find("Stop") != std::string::npos);
    auto again = c.call("lightmap.bake_start", small());
    REQUIRE_FALSE(again.ok);
    CHECK(again.error.dump().find("game_running") != std::string::npos);
    const Json done = wait_done(e, started.result["job"]);
    CHECK(done["state"] == "done");
    CHECK(done["handOver"]["applied"] == false);
    CHECK(done["handOver"]["note"].get<std::string>().find("Stop the game") != std::string::npos);
    CHECK(e.world().settings().lightmaps.empty());  // the play world was not written
    e.set_play_world(false);
    auto after = c.call("lightmap.bake", small());
    CHECK_MESSAGE(after.ok, after.error.dump());
    CHECK(e.world().settings().lightmaps == "scenes/main.lightmap.json");
    e.shutdown();
}

TEST_CASE("lightmap jobs: a finished bake whose apply nobody handed over yet is not pruned") {
    TempProject p("keepapply");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p, "inline"), nullptr, &err), err);  // inline: bake_start returns with the job finished
    auto& c = e.commands();
    std::vector<std::string> ids;
    for (int i = 0; i < 12; ++i) {  // more than the 8 finished jobs kept, none consulted, all with apply (the default)
        auto started = c.call("lightmap.bake_start", small());
        REQUIRE_MESSAGE(started.ok, started.error.dump());
        ids.push_back(started.result["job"]);
    }
    auto first = c.call("lightmap.bake_status", Json::object({{"job", ids[0]}}));
    REQUIRE_MESSAGE(first.ok, first.error.dump());
    CHECK(first.result["handOver"]["applied"] == true);
    CHECK(e.world().settings().lightmaps == "scenes/main.lightmap.json");
    e.shutdown();
}

TEST_CASE("lightmap jobs: with no worker threads the first status answers a finished job") {
    TempProject p("inline");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p, "0"), nullptr, &err), err);
    auto& c = e.commands();
    auto started = c.call("lightmap.bake_start", small());
    REQUIRE_MESSAGE(started.ok, started.error.dump());
    auto status = c.call("lightmap.bake_status", Json::object({{"job", started.result["job"]}}));
    REQUIRE_MESSAGE(status.ok, status.error.dump());
    CHECK(status.result["state"] == "done");  // never "running": there is nobody to run it while the caller waits
    CHECK(status.result["handOver"]["applied"] == true);
    e.shutdown();
}
