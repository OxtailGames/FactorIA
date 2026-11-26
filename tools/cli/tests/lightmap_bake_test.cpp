// `factoria call lightmap.bake` end to end (M73.4c): a tiny 3D project is baked through the CLI, the manifest and the pages are checked, and where
// there is a GPU the same engine draws the baked scene (a batch: bake, then game.screenshot) and the shadow of the box is in the picture.
#include <doctest.h>

#include <filesystem>
#include <sstream>

#include "common.h"  // tools/cli/src: Session
#include "fa/cli/cli.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/image_float.h"
#include "fa/core/json.h"
#include "fa/scene/lightmap_manifest.h"
#include "fa/tooling/scaffold.h"

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
