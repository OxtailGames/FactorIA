// probe.bake (M73-P3b): the files it writes (a page and a manifest, in that order, named by the hash of the page), the same scene giving the
// same bytes, a changed scene giving a new page and removing the old one, the .hdr round trip of the page, and the errors that teach.
// The capture itself is tested in engine/render/tests/probe_render_tests.cpp; a machine without graphics runs only the argument checks.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <string>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/image_float.h"
#include "fa/render/probe.h"
#include "fa/runtime/engine.h"
#include "fa/scene/components.h"

using namespace fa;
using namespace fa::render;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Probe Bake Test",
  "id": "com.example.probebake",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

std::string wall(const char* id, const char* position, const char* scale, const char* emissive) {
    return std::string(R"(    { "id": ")") + id + R"(", "components": { "Transform": { "position": )" + position +
           R"(, "scale": )" + scale +
           R"( }, "MeshRenderer": { "mesh": "cube", "color": "#000000", "unlit": true, "castShadows": false, "emissive": ")" +
           emissive +
           R"(" } } },
)";
}

// A room around the origin: red on +X, cyan on -X, green on +Y, magenta on -Y, blue on +Z, yellow on -Z, and a probe in the middle.
std::string scene_text(const char* plusX = "#ff0000") {
    return std::string(R"({
  "format": "factoria.scene/1",
  "settings": { "ambientLight": "#000000" },
  "entities": [
    { "id": "cam", "components": { "Camera": {} } },
)") + wall("px", "[3, 0, 0]", "[0.2, 6.4, 6.4]", plusX) +
           wall("nx", "[-3, 0, 0]", "[0.2, 6.4, 6.4]", "#00ffff") +
           wall("py", "[0, 3, 0]", "[6.4, 0.2, 6.4]", "#00ff00") +
           wall("ny", "[0, -3, 0]", "[6.4, 0.2, 6.4]", "#ff00ff") +
           wall("pz", "[0, 0, 3]", "[6.4, 6.4, 0.2]", "#0000ff") +
           wall("nz", "[0, 0, -3]", "[6.4, 6.4, 0.2]", "#ffff00") +
           R"(    { "id": "lobby", "components": { "Transform": {}, "ReflectionProbe": { "mode": "baked", "resolution": 64, "clear": "color", "clearColor": "#000000", "boxSize": [6, 6, 6] } } },
    { "id": "plain", "components": { "Transform": {} } }
  ]
})";
}

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const std::string& name, const std::string& scene = scene_text()) {
        dir = fs::make_temp_dir("fa_probebake_test_" + name).value();
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary) << kProject;
        std::ofstream(dir / "scenes/main.scene.json", std::ios::binary) << scene;
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    std::vector<std::string> files() const {
        std::vector<std::string> out;
        for (const auto& f : stdfs::directory_iterator(dir / "scenes"))
            out.push_back(f.path().filename().generic_string());
        std::sort(out.begin(), out.end());
        return out;
    }
    std::string read(const std::string& rel) const {
        std::ifstream in(dir / stdfs::path(rel), std::ios::binary);
        return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    }
};

EngineConfig cfg(const TempProject& p) {
    EngineConfig c;
    c.projectDir = p.dir.generic_string();
    c.headless = true;
    c.hotReload = false;
    return c;
}

bool no_graphics(const CommandResult& r) { return !r.ok && r.error.dump().find("unavailable") != std::string::npos; }

}  // namespace

TEST_CASE("probe.bake: the arguments are checked before anything is drawn") {
    TempProject p("args");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto r = c.call("probe.bake", Json{{"entity", "plain"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.dump().find("ReflectionProbe") != std::string::npos);
    r = c.call("probe.bake", Json{{"entity", "lobby"}, {"path", "scenes/room.json"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.dump().find(".probe.json") != std::string::npos);
    r = c.call("probe.bake", Json{{"entity", "lobby"}, {"apply", "yes"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.dump().find("/apply") != std::string::npos);
    r = c.call("probe.bake", Json{{"entity", "lobby"}, {"pth", "scenes/room.probe.json"}});
    REQUIRE_FALSE(r.ok);
    r = c.call("probe.bake", Json{{"entity", "no_such_entity"}});
    REQUIRE_FALSE(r.ok);
    // Nothing was written by any of them.
    CHECK(p.files() == std::vector<std::string>{"main.scene.json"});
}

TEST_CASE("probe.bake: while the editor plays it is refused and writes nothing") {
    TempProject p("play");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    e.set_play_world(true);
    auto r = c.call("probe.bake", Json{{"entity", "lobby"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.dump().find("game_running") != std::string::npos);
    CHECK(r.error.dump().find("Stop") != std::string::npos);
    CHECK(p.files() == std::vector<std::string>{"main.scene.json"});
    e.set_play_world(false);
    e.shutdown();
}

TEST_CASE("probe.bake: ids that differ only in characters a file name cannot hold get two manifests") {
    std::string scene = scene_text();
    const std::string plain = R"({ "id": "plain")";
    const std::size_t at = scene.find(plain);
    REQUIRE(at != std::string::npos);
    const std::string probe =
        R"( "components": { "Transform": {}, "ReflectionProbe": { "mode": "baked", "resolution": 32 } } },
    )";
    scene.insert(at, R"({ "id": "a.b",)" + probe + R"({ "id": "a_b",)" + probe);
    TempProject p("names", scene);
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto first = c.call("probe.bake", Json{{"entity", "a.b"}});
    if (no_graphics(first) || (!first.ok && first.error.dump().find("RGBA16F") != std::string::npos)) {
        MESSAGE("no GPU with RGBA16F targets on this machine: the bake was not run");
        return;
    }
    REQUIRE_MESSAGE(first.ok, first.error.dump());
    auto second = c.call("probe.bake", Json{{"entity", "a_b"}});
    REQUIRE_MESSAGE(second.ok, second.error.dump());
    CHECK(first.result["manifest"] != second.result["manifest"]);
    CHECK(second.result["manifest"] ==
          "scenes/main.a_b.probe.json");  // an id that is a file name already keeps its name
    CHECK(first.result["manifest"].get<std::string>().rfind("scenes/main.a_b-", 0) == 0);
    e.shutdown();
}

TEST_CASE("probe.bake: writes the page and the manifest, is deterministic, and a changed scene replaces the page") {
    TempProject p("bake");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto r = c.call("probe.bake", Json{{"entity", "lobby"}});
    if (no_graphics(r)) {
        MESSAGE("no GPU on this machine: the bake was not run");
        return;
    }
    if (!r.ok && r.error.dump().find("RGBA16F") != std::string::npos) {
        MESSAGE("this GPU has no RGBA16F targets: the bake was not run");
        return;
    }
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const Json first = r.result;
    CHECK(first["manifest"] == "scenes/main.lobby.probe.json");
    CHECK(first["applied"] == true);
    CHECK(first["resolution"] == 64);
    const std::string hash = first["hash"].get<std::string>();
    REQUIRE(hash.size() == 16);
    CHECK(first["page"] == "scenes/main.lobby.probe." + hash + ".hdr");
    CHECK(e.world().get<ReflectionProbe>(e.world().find("lobby"))->bakedMap == "scenes/main.lobby.probe.json");
    CHECK(p.files() ==
          std::vector<std::string>{"main.lobby.probe." + hash + ".hdr", "main.lobby.probe.json", "main.scene.json"});

    // The manifest reads back, and its page is the .hdr of the right size with the hash of its bytes.
    const std::string manifestText = p.read("scenes/main.lobby.probe.json");
    auto json = parse_json(manifestText, "main.lobby.probe.json");
    REQUIRE(json.ok());
    auto manifest = probe_manifest_from_json(*json, "main.lobby.probe.json");
    REQUIRE_MESSAGE(manifest.ok(), manifest.error().message);
    CHECK(manifest->resolution == 64);
    CHECK(manifest->hash == hash);
    CHECK(manifest->page == first["page"].get<std::string>());
    const std::string pageText = p.read(manifest->page);
    const std::vector<std::uint8_t> pageBytes(pageText.begin(), pageText.end());
    CHECK(probe_hash_hex(pageBytes) == hash);
    auto page = decode_hdr(pageBytes.data(), pageBytes.size());
    REQUIRE_MESSAGE(page.ok(), page.error().message);
    CHECK(page->width == probe_page_width(64));
    CHECK(page->height == probe_page_height(64));
    // The round trip: encoding what was read gives the page's bytes again.
    CHECK(encode_hdr(*page) == pageBytes);

    // Read by direction: +X is red, -X is cyan, +Z is blue.
    auto at = [&](Vec3 d) {
        const Vec2 oct = oct_encode(d);
        const int x = std::clamp(int((oct.x * 0.5f + 0.5f) * 64.0f), 0, 63) + kProbeBorder;
        const int y = std::clamp(int((oct.y * 0.5f + 0.5f) * 64.0f), 0, 63) + kProbeBorder;
        const float* px = page->at(x, y);
        return Vec3{px[0], px[1], px[2]};
    };
    CHECK(at({1, 0, 0}).x > 0.9f);
    CHECK(at({1, 0, 0}).y < 0.1f);
    CHECK(at({-1, 0, 0}).x < 0.1f);
    CHECK(at({-1, 0, 0}).y > 0.9f);
    CHECK(at({0, 0, 1}).z > 0.9f);
    CHECK(at({0, 0, 1}).x < 0.1f);
    // The stored coefficients are what the page projects to (up to what the 16 x 16 image the GPU projected from loses).
    const ShL2 cpu = probe_sh_from_page(*page, 64);
    for (int k = 0; k < kProbeShCoefficients; ++k) {
        CHECK(std::fabs(cpu.c[k].x - manifest->sh[k][0]) < 0.1f);
        CHECK(std::fabs(cpu.c[k].y - manifest->sh[k][1]) < 0.1f);
        CHECK(std::fabs(cpu.c[k].z - manifest->sh[k][2]) < 0.1f);
    }

    // The same scene again: the same hash, the same bytes, the same files.
    r = c.call("probe.bake", Json{{"entity", "lobby"}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["hash"] == hash);
    CHECK(p.read("scenes/main.lobby.probe.json") == manifestText);
    CHECK(p.read(manifest->page) == pageText);
    CHECK(p.files().size() == 3);

    // Another scene (the +X wall is white now): another page, and the old one is gone once the manifest names the new one.
    e.world().get<MeshRenderer>(e.world().find("px"))->emissive = Color{1, 1, 1, 1};
    r = c.call("probe.bake", Json{{"entity", "lobby"}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const std::string hash2 = r.result["hash"].get<std::string>();
    CHECK(hash2 != hash);
    CHECK(p.files() ==
          std::vector<std::string>{"main.lobby.probe." + hash2 + ".hdr", "main.lobby.probe.json", "main.scene.json"});

    // `path` and `apply`: another manifest, the component left alone.
    e.world().get<ReflectionProbe>(e.world().find("lobby"))->bakedMap.clear();
    r = c.call("probe.bake", Json{{"entity", "lobby"}, {"path", "scenes/other.probe.json"}, {"apply", false}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["applied"] == false);
    CHECK(e.world().get<ReflectionProbe>(e.world().find("lobby"))->bakedMap.empty());
    CHECK(r.result["hash"] == hash2);  // the same picture: the same page bytes under the other manifest's name
    CHECK(stdfs::exists(p.dir / "scenes/other.probe.json"));
}
