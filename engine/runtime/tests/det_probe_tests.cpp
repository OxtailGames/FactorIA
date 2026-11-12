// M91.3: the replay hashes of the simulation scripts can reach, on every desktop CI platform. tools/cli/tests/determinism_probe.js
// runs in a copy of templates/2d-platformer (the game the Android, iOS and web CI jobs run it in) and logs ONE line,
// "FA_DET_HASH math=.. script=.. physics2d=.. physics3d=.. nav=..". The expected values below are committed: the same line is
// printed by the Android emulator, the iOS simulator and the browser (.github/workflows/ci.yml), and each of those jobs compares
// it with the same values: tools/cli/tests/determinism_expected.txt is the one place to update (this test, the jobs and the
// smoke scripts read it).
//
// The particle and feel hashes (which scripts cannot reach) are in engine/scene/tests/test_det_replay.cpp.
//
// When this fails on ONE platform, that platform's arithmetic differs: the section that differs says where (math = Math.* of the
// scripts, physics2d = Box2D, physics3d = the 3D solver, nav = the nav bake and search; docs/ARCHITECTURE.md "Determinism"). When
// it fails everywhere the same way, the simulation changed on purpose: copy the printed line into determinism_expected.txt.
#include <doctest.h>

#include <cstdio>
#include <filesystem>
#include <fstream>
#include <map>
#include <sstream>
#include <string>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/project.h"
#include "fa_test_paths.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

stdfs::path repo_path(const char* rel) {
    const std::string root = FA_REPO_ROOT;
    return stdfs::path(std::u8string(reinterpret_cast<const char8_t*>(root.data()), root.size())) / stdfs::path(std::u8string(reinterpret_cast<const char8_t*>(rel)));
}

std::map<std::string, std::string> parse_line(const std::string& line) {
    std::map<std::string, std::string> out;
    std::istringstream in(line);
    std::string tok;
    while (in >> tok) {
        const auto eq = tok.find('=');
        if (eq != std::string::npos) out[tok.substr(0, eq)] = tok.substr(eq + 1);
    }
    return out;
}

}  // namespace

TEST_CASE("det probe: the scripts' math, 2D and 3D physics and nav give the committed hashes" * doctest::skip()) {
    const stdfs::path dir = fs::make_temp_dir("fa_det_probe").value();
    struct Cleanup {
        stdfs::path dir;
        ~Cleanup() {
            std::error_code ec;
            stdfs::remove_all(dir, ec);
        }
    } cleanup{dir};
    std::error_code ec;
    stdfs::copy(repo_path("templates/2d-platformer"), dir, stdfs::copy_options::recursive | stdfs::copy_options::overwrite_existing, ec);
    REQUIRE_MESSAGE(!ec, "copying templates/2d-platformer: " << ec.message());
    stdfs::create_directories(dir / "scripts");
    stdfs::copy_file(repo_path("tools/cli/tests/determinism_probe.js"), dir / "scripts" / "determinism_probe.js",
                     stdfs::copy_options::overwrite_existing, ec);
    REQUIRE_MESSAGE(!ec, "copying the probe: " << ec.message());

    // The same edit the CI jobs make: one more entity with the probe as its script.
    const stdfs::path scenePath = dir / "scenes" / "main.scene.json";
    Json scene;
    {
        std::ifstream in(scenePath, std::ios::binary);
        std::stringstream ss;
        ss << in.rdbuf();
        scene = Json::parse(ss.str());
    }
    scene["entities"].push_back(Json::object({{"id", "detProbe"}, {"name", "Determinism probe"},
                                              {"components", Json::object({{"Script", Json::object({{"path", "scripts/determinism_probe.js"}})}})}}));
    std::ofstream(scenePath, std::ios::binary) << scene.dump(2);

    EngineConfig cfg;
    cfg.projectDir = fs::path_to_utf8(dir);
    cfg.headless = true;
    cfg.hotReload = false;
    HeadlessRunOptions options;
    options.frames = 90;
    clear_recent_logs();
    Json report;
    const int code = run_headless(cfg, options, &report);
    CHECK_MESSAGE(code == 0, report.dump());
    CHECK(report["replayValid"].get<bool>());

    std::string line;
    for (const LogEntry& e : recent_logs(5000, LogLevel::Info))
        if (e.message.find("FA_DET_HASH ") != std::string::npos) line = e.message.substr(e.message.find("FA_DET_HASH ") + 12);
    REQUIRE_MESSAGE(!line.empty(), "the probe printed no FA_DET_HASH line; errors: " << report["scriptErrors"].dump());
    std::printf("FA_DET_HASH platform=%s %s\n", FA_PLATFORM_NAME, line.c_str());
    std::fflush(stdout);

    const auto got = parse_line(line);
    std::string expected;
    {
        std::ifstream in(repo_path("tools/cli/tests/determinism_expected.txt"), std::ios::binary);
        REQUIRE_MESSAGE(in.good(), "tools/cli/tests/determinism_expected.txt is missing");
        std::getline(in, expected);
        while (!expected.empty() && (expected.back() == '\r' || expected.back() == ' ')) expected.pop_back();
    }
    const auto want = parse_line(expected);
    REQUIRE(!want.empty());
    for (const auto& [key, value] : want) {
        INFO("section " << key << ": this platform prints " << (got.count(key) ? got.at(key) : "(missing)") << ", expected " << value
                        << ". Printed line: " << line);
        CHECK(got.count(key) == 1);
        if (got.count(key)) CHECK(got.at(key) == value);
    }
}
