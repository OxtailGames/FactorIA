// `factoria call lightmap.bake` end to end (M73.4c): a tiny 3D project is baked through the CLI, the manifest and the pages are checked, and where
// there is a GPU the same engine draws the baked scene (a batch: bake, then game.screenshot) and the shadow of the box is in the picture.
#include <doctest.h>

#include <chrono>
#include <cstdlib>
#include <filesystem>
#include <sstream>
#include <thread>

#include "common.h"  // tools/cli/src: Session
#include "fa/cli/cli.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/image_float.h"
#include "fa/core/json.h"
#include "fa/core/process.h"
#include "fa/scene/lightmap_manifest.h"
#include "fa/tooling/scaffold.h"

#if defined(_WIN32)
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#else
#include <unistd.h>
#endif

namespace stdfs = std::filesystem;

namespace {

struct CliResult {
    int code;
    std::string out, err;
};
CliResult run(std::vector<std::string> args) {
    std::ostringstream out, err;
    std::istringstream in;
    const int code = fa::cli::cli_main(args, out, err, in);
    return {code, out.str(), err.str()};
}

// A floor, a 1 m box and a baked sun pitched 45 degrees towards -Z, seen from straight above: the shadow of the box is the strip above it in
// the picture. Almost no ambient light, so the shadow is dark.
const char* kScene = R"({
  "format": "factoria.scene/1",
  "settings": { "ambientLight": "#101010" },
  "entities": [
    { "id": "cam", "name": "Camera", "components": { "Transform": { "position": [0, 10, 0], "rotation": [-90, 0, 0] },
        "Camera": { "projection": "perspective", "fov": 60, "clearColor": "#000000" } } },
    { "id": "floor", "name": "floor", "components": { "Transform": { "position": [0, -0.1, 0], "scale": [8, 0.2, 8] }, "MeshRenderer": { "mesh": "cube", "color": "#808080" } } },
    { "id": "box", "name": "box", "components": { "Transform": { "position": [0, 0.5, 0] }, "MeshRenderer": { "mesh": "cube", "color": "#808080" } } },
    { "id": "sun", "name": "sun", "components": { "Transform": { "rotation": [-45, 0, 0] }, "Light": { "type": "directional", "intensity": 1, "mode": "baked" } } }
  ]
})";

float luma(const fa::Image& img, int x, int y) {
    const std::size_t i = (std::size_t(y) * std::size_t(img.width) + std::size_t(x)) * 4;
    return (0.2126f * img.rgba[i] + 0.7152f * img.rgba[i + 1] + 0.0722f * img.rgba[i + 2]) / 255.0f;
}

}  // namespace

TEST_CASE(
    "factoria call lightmap.bake: bakes a project, writes the manifest and the pages, and the runtime loads them") {
    const stdfs::path oldRoot = fa::fs::project_root();
    const stdfs::path tmp = fa::fs::make_temp_dir("fa_cli_lightmap_bake").value();
    const std::string project = (tmp / "game").string();
    fa::ScaffoldOptions opt;
    opt.writeTypings = false;
    REQUIRE(fa::create_project(project, "3d-empty", opt).ok());
    REQUIRE(fa::fs::write_text((tmp / "game" / "scenes" / "main.scene.json").generic_string(), kScene).ok());

    // The CLI, one process per call: no GPU needed.
    const std::string args = R"({"texelsPerMeter":8,"samples":16,"shadowSamples":4,"maxPageSize":512})";
    const CliResult r = run({"call", "lightmap.bake", args, "--project", project, "--no-graphics"});
    REQUIRE_MESSAGE(r.code == 0, r.err << r.out);
    const fa::Json result = fa::Json::parse(r.out);
    CHECK(result["manifest"] == "scenes/main.lightmap.json");
    CHECK(result["entities"] == 2);
    CHECK(result["pages"].size() >= 1);
    CHECK(result["applied"] == true);

    // What the player reads: the manifest, then every page it names, with the entity ids of the scene.
    fa::fs::set_project_root(tmp / "game");
    auto manifest = fa::load_lightmap_manifest("scenes/main.lightmap.json");
    REQUIRE_MESSAGE(manifest.ok(), manifest.error().message);
    CHECK(manifest->entities.size() == 2);
    CHECK(manifest->find("floor") != nullptr);
    CHECK(manifest->find("box") != nullptr);
    CHECK(manifest->find("sun") == nullptr);
    for (const fa::LightmapPage& page : manifest->pages) {
        auto img = fa::load_hdr(page.file);
        REQUIRE_MESSAGE(img.ok(), img.error().message);
        CHECK(img->width == page.width);
        CHECK(img->height == page.height);
    }

    // A bad argument exits 1 with the pointer and the hint, and changes nothing.
    const CliResult bad = run({"call", "lightmap.bake", R"({"samples":0})", "--project", project, "--no-graphics"});
    CHECK(bad.code == 1);
    CHECK(bad.err.find("/samples") != std::string::npos);

    // Where there is a GPU: bake and draw in one engine (a batch). The sun's shadow of the box is darker than the lit floor beside it.
    fa::cli::SessionOptions so;
    so.gfx = fa::cli::Gfx::Auto;
    so.width = 320;
    so.height = 180;
    auto probe = fa::cli::Session::open(project, so);
    const bool gpu = probe->has_graphics();
    probe.reset();
    if (gpu) {
        const std::string batch = R"([{"command":"lightmap.bake","args":)" + args +
                                  R"(},{"command":"game.screenshot","args":{"path":"shots/baked.png"}}])";
        const CliResult b = run({"call", "--batch", batch, "--project", project});
        REQUIRE_MESSAGE(b.code == 0, b.err << b.out);
        auto img = fa::load_image((tmp / "game" / "shots" / "baked.png").generic_string());
        REQUIRE(img.ok());
        // The floor (8 m) fills 0.69 of the picture's height: 0.086 of the height per meter. The box top is the middle of the picture, its
        // shadow lies 0.5-1.5 m towards -Z (up in the picture), so its middle is 1 m above the centre; the lit floor is to the left, 0.1 of the width from the centre (still inside the floor).
        const int w = img->width, h = img->height;
        const float shadow = luma(*img, w / 2, h / 2 - int(0.086f * float(h)));
        const float lit = luma(*img, w / 2 - int(0.1f * float(w)), h / 2);
        CHECK_MESSAGE(lit > 0.15f, "the floor is lit: " << lit);
        CHECK_MESSAGE(lit - shadow > 0.05f,
                      "the lit floor (" << lit << ") is clearly brighter than the shadow (" << shadow << ")");
        CHECK_MESSAGE(shadow < lit * 0.6f,
                      "the box shadow (" << shadow << ") is darker than the lit floor (" << lit << ")");
    } else {
        MESSAGE("no GPU on this machine: the render part of the test is skipped");
    }

    fa::fs::set_project_root(oldRoot);
    std::error_code ec;
    stdfs::remove_all(tmp, ec);
}

namespace {

// The sum of the light on the pages of the manifest a bake of the project at `tmpGame` wrote.
double pages_sum(const stdfs::path& tmpGame) {
    fa::fs::set_project_root(tmpGame);
    auto manifest = fa::load_lightmap_manifest("scenes/main.lightmap.json");
    REQUIRE_MESSAGE(manifest.ok(), manifest.error().message);
    double sum = 0;
    for (const fa::LightmapPage& page : manifest->pages) {
        auto img = fa::load_hdr(page.file);
        REQUIRE_MESSAGE(img.ok(), img.error().message);
        for (float v : img->data) sum += v;
    }
    return sum;
}

}  // namespace

TEST_CASE(
    "factoria call lightmap.bake device: auto bakes on the GPU where one traces rays and says which device baked") {
    const stdfs::path oldRoot = fa::fs::project_root();
    const stdfs::path tmp = fa::fs::make_temp_dir("fa_cli_lightmap_gpu").value();
    const std::string project = (tmp / "game").string();
    fa::ScaffoldOptions opt;
    opt.writeTypings = false;
    REQUIRE(fa::create_project(project, "3d-empty", opt).ok());
    REQUIRE(fa::fs::write_text((tmp / "game" / "scenes" / "main.scene.json").generic_string(), kScene).ok());

    const std::string args = R"({"texelsPerMeter":8,"samples":16,"shadowSamples":4,"maxPageSize":512)";
    const CliResult cpu = run({"call", "lightmap.bake", args + "}", "--project", project, "--no-graphics"});
    REQUIRE_MESSAGE(cpu.code == 0, cpu.err << cpu.out);
    CHECK(fa::Json::parse(cpu.out)["device"]["used"] == "cpu");
    const double cpuSum = pages_sum(tmp / "game");

    const CliResult autoRun =
        run({"call", "lightmap.bake", args + R"(,"device":"auto"})", "--project", project, "--no-graphics"});
    REQUIRE_MESSAGE(autoRun.code == 0, autoRun.err << autoRun.out);
    const fa::Json result = fa::Json::parse(autoRun.out);
    const std::string used = result["device"]["used"].get<std::string>();
    MESSAGE("device: " << result["device"].dump());
    if (used == "gpu") {
        CHECK(result["device"]["name"].get<std::string>().size() > 0);
        CHECK(pages_sum(tmp / "game") ==
              doctest::Approx(cpuSum).epsilon(0.01));  // the same light up to the GPU's rounding
    } else {
        CHECK(used == "cpu");
        CHECK(result["device"]["note"].get<std::string>().find("baked on the CPU") != std::string::npos);
    }

    fa::fs::set_project_root(oldRoot);
    std::error_code ec;
    stdfs::remove_all(tmp, ec);
}

// ---- the GPU bake in a helper process (M79-P5c) ----------------------------------------------------------------------------------------------------
// A process that already has a graphics context (the editor, a window, `factoria call` with graphics) cannot open the GPU tracer's own context on a
// Mac, so it runs the bake in a child `factoria session --no-graphics --no-scene`. FA_LIGHTMAP_HELPER=always makes any process do so, which is how these cases
// run the helper path on a machine that does not need it. They need the real `factoria` (ctest gives it in FA_FACTORIA_EXE).

namespace {

void set_env(const char* name, const char* value) {
#if defined(_WIN32)
    _putenv_s(name, value ? value : "");
#else
    if (value)
        setenv(name, value, 1);
    else
        unsetenv(name);
#endif
}

struct EnvScope {
    const char* name;
    explicit EnvScope(const char* n, const char* value) : name(n) { set_env(name, value); }
    ~EnvScope() { set_env(name, nullptr); }
};

// The processes this test process started that still run (a leftover helper would be one).
std::size_t child_processes() {
#if defined(_WIN32)
    const long long self = static_cast<long long>(GetCurrentProcessId());
#else
    const long long self = static_cast<long long>(getpid());
#endif
    const std::vector<fa::ProcessEntry> tree = fa::process_tree(self);
    return tree.empty() ? 0 : tree.size() - 1;
}

// True once no more processes run under this one than at `baseline` (the count when the case began: another test of this binary, or the
// machine's own helper of a framework, may have a child of its own).
bool no_children_soon(std::size_t baseline) {
    for (int i = 0; i < 200; ++i) {
        if (child_processes() <= baseline) return true;
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
    return false;
}

bool have_factoria() {
    const char* exe = std::getenv("FA_FACTORIA_EXE");
    return exe != nullptr && *exe != 0;
}

}  // namespace

TEST_CASE("factoria call lightmap.bake device: the GPU bake in a helper process gives the same device report and "
          "leaves no process behind") {
    if (!have_factoria()) {
        MESSAGE("FA_FACTORIA_EXE is not set (run this through ctest): the helper process cases are skipped");
        return;
    }
    const std::size_t baseline = child_processes();
    const stdfs::path oldRoot = fa::fs::project_root();
    const stdfs::path tmp = fa::fs::make_temp_dir("fa_cli_lightmap_helper").value();
    const std::string project = (tmp / "game").string();
    fa::ScaffoldOptions opt;
    opt.writeTypings = false;
    REQUIRE(fa::create_project(project, "3d-empty", opt).ok());
    REQUIRE(fa::fs::write_text((tmp / "game" / "scenes" / "main.scene.json").generic_string(), kScene).ok());
    const EnvScope helper("FA_LIGHTMAP_HELPER", "always");

    const std::string args = R"({"texelsPerMeter":8,"samples":16,"shadowSamples":4,"maxPageSize":512)";
    const CliResult cpu = run({"call", "lightmap.bake", args + "}", "--project", project, "--no-graphics"});
    REQUIRE_MESSAGE(cpu.code == 0, cpu.err << cpu.out);
    const fa::Json cpuResult = fa::Json::parse(cpu.out);
    CHECK(cpuResult["device"]["process"] == "here");  // the CPU never asks for a helper
    const double cpuSum = pages_sum(tmp / "game");

    // auto: the helper's own choice (a GPU where one traces rays, else the CPU with its reason); the pages are valid either way.
    const CliResult autoRun =
        run({"call", "lightmap.bake", args + R"(,"device":"auto"})", "--project", project, "--no-graphics"});
    REQUIRE_MESSAGE(autoRun.code == 0, autoRun.err << autoRun.out);
    const fa::Json result = fa::Json::parse(autoRun.out);
    MESSAGE("auto in a helper: " << result["device"].dump());
    CHECK(result["device"]["requested"] == "auto");
    CHECK(result["device"]["process"] == "helper");
    const std::string used = result["device"]["used"].get<std::string>();
    if (used == "gpu") {
        CHECK(result["device"]["name"].get<std::string>().size() > 0);
        CHECK(pages_sum(tmp / "game") == doctest::Approx(cpuSum).epsilon(0.01));
    } else {
        CHECK(used == "cpu");
        CHECK(result["device"]["note"].get<std::string>().find("baked on the CPU") != std::string::npos);
        CHECK(pages_sum(tmp / "game") == cpuSum);  // the CPU baked: the same bytes as the direct bake
    }
    CHECK(result["pages"].size() >= 1);
    CHECK(no_children_soon(baseline));

    // gpu by name: a GPU result, or the error with the helper's own reason (no GPU that traces rays here).
    const CliResult gpu =
        run({"call", "lightmap.bake", args + R"(,"device":"gpu"})", "--project", project, "--no-graphics"});
    if (gpu.code == 0) {
        const fa::Json r = fa::Json::parse(gpu.out);
        CHECK(r["device"]["used"] == "gpu");
        CHECK(r["device"]["process"] == "helper");
    } else {
        CHECK(gpu.code == 1);
        CHECK(gpu.err.find("device \"gpu\"") != std::string::npos);
    }
    CHECK(no_children_soon(baseline));

    // A mistake in the arguments is refused by this process, before any helper starts.
    const CliResult bad =
        run({"call", "lightmap.bake", args + R"(,"device":"gpu","samples":0})", "--project", project, "--no-graphics"});
    CHECK(bad.code == 1);
    CHECK(bad.err.find("/samples") != std::string::npos);

    fa::fs::set_project_root(oldRoot);
    std::error_code ec;
    stdfs::remove_all(tmp, ec);
}

TEST_CASE("factoria call lightmap.bake_start device: a bake in a helper process reports progress, is cancelled, and "
          "the helper ends") {
    if (!have_factoria()) {
        MESSAGE("FA_FACTORIA_EXE is not set (run this through ctest): the helper process cases are skipped");
        return;
    }
    const std::size_t baseline = child_processes();
    const stdfs::path oldRoot = fa::fs::project_root();
    const stdfs::path tmp = fa::fs::make_temp_dir("fa_cli_lightmap_helper_cancel").value();
    const std::string project = (tmp / "game").string();
    fa::ScaffoldOptions opt;
    opt.writeTypings = false;
    REQUIRE(fa::create_project(project, "3d-empty", opt).ok());
    REQUIRE(fa::fs::write_text((tmp / "game" / "scenes" / "main.scene.json").generic_string(), kScene).ok());
    const EnvScope helper("FA_LIGHTMAP_HELPER", "always");

    fa::cli::SessionOptions so;
    so.gfx = fa::cli::Gfx::None;
    {
        auto session = fa::cli::Session::open(project, so);
        fa::CommandRegistry& reg = session->registry();
        // A bake that takes a long time on any machine, so the cancel lands while the helper traces.
        auto start = reg.call(
            "lightmap.bake_start",
            fa::Json::object({{"device", "auto"},
                              {"texelsPerMeter", 48},
                              {"samples", 16384},
                              {"shadowSamples", 64},
                              {"maxPageSize", 1024},
                              {"maxRays", std::uint64_t(1000000000000ULL)},  // far above the budget of any packing
                              {"apply", false}}));
        REQUIRE_MESSAGE(start.ok, start.error.dump());
        const std::string job = start.result["job"].get<std::string>();
        // 600 s, as lightmap_commands_tests.cpp's cancel case (0.35.2): Coverage's instrumented helper went past 180 s
        // before "trace" (M79 CI round 4).
        const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(600);
        fa::Json seen;
        for (;;) {
            auto s = reg.call("lightmap.bake_status", fa::Json::object({{"job", job}}));
            REQUIRE_MESSAGE(s.ok, s.error.dump());
            seen = s.result;
            if (seen["state"] != "running" || seen["phase"] == "trace") break;
            INFO("last status: " << seen.dump());
            REQUIRE(std::chrono::steady_clock::now() < deadline);
            std::this_thread::sleep_for(std::chrono::milliseconds(20));
        }
        MESSAGE("seen before the cancel: " << seen.dump());
        auto cancel = reg.call("lightmap.bake_cancel", fa::Json::object({{"job", job}}));
        REQUIRE_MESSAGE(cancel.ok, cancel.error.dump());
        fa::Json end;
        for (;;) {
            auto s = reg.call("lightmap.bake_status", fa::Json::object({{"job", job}}));
            REQUIRE_MESSAGE(s.ok, s.error.dump());
            end = s.result;
            if (end["state"] != "running") break;
            INFO("last status: " << end.dump());
            REQUIRE(std::chrono::steady_clock::now() < deadline + std::chrono::seconds(600));
            std::this_thread::sleep_for(std::chrono::milliseconds(20));
        }
        // Cancelled; a machine fast enough to finish before the cancel got there ends done, and then the pages are whole.
        MESSAGE("ended: " << end["state"].get<std::string>());
        CHECK((end["state"] == "cancelled" || end["state"] == "done"));
        if (end["state"] == "cancelled") CHECK_FALSE(stdfs::exists(tmp / "game" / "scenes" / "main.lightmap.json"));
    }
    CHECK(no_children_soon(baseline));

    fa::fs::set_project_root(oldRoot);
    std::error_code ec;
    stdfs::remove_all(tmp, ec);
}
