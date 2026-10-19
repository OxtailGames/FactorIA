// The fixture materials of the renderer tests (engine/render/tests/data/materials) ship with their compiled twins for
// every backend the renderer tests run on (D3D11, GL, Metal on macOS), so the renderer tests need no sokol-shdc. This
// test recompiles each fixture with the real sokol-shdc (skipped where none is installed, failed with FA_REQUIRE_SHDC=1)
// and fails when a committed twin differs, i.e. when the mesh template or a fixture changed without regenerating.
// FA_UPDATE_FIXTURES=1 rewrites the twins instead.
#include <doctest.h>
#include <cstdlib>
#include <filesystem>
#include "fa/tooling/setup.h"
#include "fa/tooling/shaders.h"
#include "fa_test_paths.h"  // FA_REPO_ROOT
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

TEST_CASE("real sokol-shdc: the committed twins of the renderer's fixture materials are up to date") {
    SetupContext context;
    FA_SKIP_WITHOUT_SHDC(context, "sokol-shdc is not installed: the fixture twins are not checked here (CI does)");
    const stdfs::path root = stdfs::path(FA_REPO_ROOT) / "engine/render/tests/data/materials";
    const char* update = std::getenv("FA_UPDATE_FIXTURES");
    const bool rewrite = update && std::string(update) == "1";

    const std::vector<std::string> dialects = {"hlsl5", "glsl430", "metal_macos"};
    for (const char* name : {"empty", "glow", "time", "lift", "cutout"}) {
        const std::string material = std::string("materials/") + name + ".material.json";
        ShaderCompileOptions options;
        options.setup = context;
        options.dialects = dialects;
        options.useCache = false;
        auto r = compile_material(root.string(), material, options);
        REQUIRE(r.ok());
        const std::string why = r->errors.empty() ? std::string() : r->errors[0].to_string();
        INFO(why);
        REQUIRE(r->ok);
        for (const std::string& slang : dialects) {
            CAPTURE(material);
            CAPTURE(slang);
            const stdfs::path file = root / (material + "." + slang + ".shader");
            Json fresh = r->twins.at(slang);
            if (rewrite) {
                testing::write_all(file, fresh.dump(2) + "\n");
                continue;
            }
            INFO("regenerate with: FA_UPDATE_FIXTURES=1 ctest -R fixture (fa_test_tooling) against a real sokol-shdc");
            REQUIRE_MESSAGE(stdfs::exists(file), "missing twin " << file.string());
            Json committed = Json::parse(testing::read_all(file));
            committed.erase("engine");
            fresh.erase("engine");
            CHECK_MESSAGE(committed == fresh, "the committed twin differs from a fresh compile: " << file.string()
                          << " (run fa_test_tooling with FA_UPDATE_FIXTURES=1 and SOKOL_SHDC set to rewrite the twins)");
        }
    }
}
