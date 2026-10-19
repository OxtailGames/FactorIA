// Export: the shaders of custom materials (tools/common/src/export_shaders.cpp). Every target ships
// <material>.json.<slang>.shader for exactly its dialects and none of the GLSL snippets, in a folder, a game.pak, the APK
// assets and the web pack; a snippet that does not compile fails the export with the errors `factoria validate` lists.
// sokol-shdc is a stand-in that writes the reflection of the dialects it is asked for, so these run on every host; the last
// case uses the real one where it is installed.
#include <doctest.h>

#include <algorithm>
#include <filesystem>

#include "fa/core/pack.h"
#include "fa/core/strings.h"
#include "fa/tooling/export.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/setup.h"
#include "fa/tooling/shaders.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kMaterial = R"({
  "format": "factoria.material/1",
  "doc": "A pulsing gem.",
  "shader": "shaders/gem.surface.glsl",
  "params": { "tint": { "type": "color", "default": [0.2, 0.6, 1.0, 1.0], "doc": "Base color." } }
})";
const char* kSnippet = R"(void surface(in SurfaceInput i, inout Surface s) {
    s.albedo = tint.rgb;
}
)";
// Line 2 uses a name that does not exist.
const char* kBrokenSnippet = R"(void surface(in SurfaceInput i, inout Surface s) {
    s.albedo = tnt.rgb;
}
)";

bool has(const std::vector<std::string>& v, const std::string& s) { return std::find(v.begin(), v.end(), s) != v.end(); }

// The shader files among `files`, by name only.
std::vector<std::string> shader_files(const std::vector<std::string>& files) {
    std::vector<std::string> out;
    for (const std::string& f : files)
        if (f.ends_with(".shader") || f.ends_with(".glsl")) out.push_back(stdfs::path(f).filename().string());
    std::sort(out.begin(), out.end());
    return out;
}

std::vector<std::string> files_below(const stdfs::path& root) {
    std::vector<std::string> out;
    for (const auto& e : stdfs::recursive_directory_iterator(root))
        if (e.is_regular_file()) out.push_back(stdfs::relative(e.path(), root).generic_string());
    return out;
}

// sokol-shdc as a stand-in: writes a reflection with mesh and mesh_skin for every dialect of --slang, or fails with `stderrText`.
struct FakeShdc {
    int calls = 0;
    std::string stderrText;
    SetupContext context(const std::string& home) {
        SetupContext c;
        c.env = [](const std::string& n) { return n == "SOKOL_SHDC" ? std::string("/fake/sokol-shdc") : std::string(); };
        c.home = home;
        c.host = "linux";
        c.run = [this](const ProcessOptions& o) -> Result<ProcessResult> {
            ++calls;
            ProcessResult r;
            if (!stderrText.empty()) {
                r.exitCode = 10;
                r.stderrText = stderrText;
                return r;
            }
            const auto at = std::find(o.argv.begin(), o.argv.end(), "--slang");
            if (at == o.argv.end() || at + 1 == o.argv.end()) return Error{"no --slang", ""};
            const stdfs::path work(o.workingDir);
            std::string yaml = "shaders:\n";
            for (const std::string& slang : split(*(at + 1), ':')) {
                yaml += "  -\n    slang: " + slang + "\n    programs:\n";
                for (const char* program : {"mesh", "mesh_skin"}) {
                    yaml += std::string("      -\n        name: ") + program + "\n";
                    for (const char* stage : {"vertex", "fragment"}) {
                        const std::string file = "out/" + slang + "_" + program + "_" + stage + ".src";
                        yaml += std::string("        ") + stage + "_func:\n          path: " + file + "\n          entry_point: main\n";
                        testing::write_all(work / file, "// " + slang + " " + program + " " + stage + "\n");
                    }
                }
            }
            testing::write_all(work / "out/m_fa_mat_reflection.yaml", yaml);
            r.exitCode = 0;
            return r;
        };
        return c;
    }
};

struct Fixture {
    testing::TempDir tmp;
    std::string proj = tmp.sub("proj");
    FakeShdc shdc;
    SetupContext setup = shdc.context(tmp.sub("home"));
    Fixture() {
        ScaffoldOptions so;
        so.name = "Shader Test";
        so.id = "com.example.shadertest";
        auto r = create_project(proj, "2d-platformer", so);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        testing::write_all(stdfs::path(proj) / "materials/gem.material.json", kMaterial);
        testing::write_all(stdfs::path(proj) / "shaders/gem.surface.glsl", kSnippet);
    }
    ExportOptions options(const std::string& platform, bool release = false) {
        ExportOptions o;
        o.projectDir = proj;
        o.platform = platform;
        o.outDir = tmp.sub("out");
        o.release = release;
        o.setup = &setup;
        if (platform == "web") {
            const stdfs::path dir = tmp.sub("web-player");
            testing::write_all(dir / "factoria_player.js", "// fake emscripten glue\n");
            testing::write_all(dir / "factoria_player.wasm", std::string("\0asm\1\0\0\0", 8));
            o.playerBinary = dir.string();
        } else if (platform == "android") {
            const stdfs::path mobile = tmp.sub("download/mobile");
            for (const char* abi : {"arm64-v8a", "x86_64"})
                testing::write_all(mobile / "android/jniLibs" / abi / "libfactoria_player.so", "fake");
            o.mobileDir = mobile.string();
            o.format = "gradle";
        } else {
            o.playerBinary = tmp.sub("fake_player/factoria_player");
            testing::write_all(o.playerBinary, "#!/bin/sh\nexit 0\n");
        }
        return o;
    }
};

std::vector<std::string> twins_of(const std::string& dialect) { return {"gem.material.json." + dialect + ".shader"}; }

}  // namespace

TEST_CASE("export shaders: a folder holds the twins of the platform's dialects and no snippet") {
    Fixture f;
    auto r = export_project(f.options("linux"));
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    const stdfs::path game = f.tmp.sub("out/shader-test-linux/game");
    const std::vector<std::string> shipped = files_below(game);
    CHECK(shader_files(shipped) == twins_of("glsl430"));
    CHECK(has(shipped, "materials/gem.material.json"));
    CHECK_FALSE(stdfs::exists(game / "shaders"));
    CHECK(r->materials == std::vector<std::string>{"materials/gem.material.json"});
    CHECK(r->to_json()["materials"] == Json::parse(R"(["materials/gem.material.json"])"));

    auto twin = parse_json(testing::read_all(game / "materials/gem.material.json.glsl430.shader"));
    REQUIRE(twin.ok());
    CHECK((*twin)["format"] == kShaderTwinFormat);
    CHECK((*twin)["slang"] == "glsl430");
    CHECK((*twin)["programs"]["mesh"]["vs"] == "// glsl430 mesh vertex\n");
    // The project keeps its snippet; a second export of the unchanged material starts no process.
    CHECK(stdfs::exists(stdfs::path(f.proj) / "shaders/gem.surface.glsl"));
    CHECK(f.shdc.calls == 1);
    REQUIRE(export_project(f.options("linux")).ok());
    CHECK(f.shdc.calls == 1);
}

TEST_CASE("export shaders: game.pak of a release, the APK assets and the web pack hold exactly their dialects") {
    Fixture f;
    SUBCASE("windows game.pak") {
        auto r = export_project(f.options("windows", true));
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        CHECK(shader_files(r->packed) == twins_of("hlsl5"));
        auto pack = PackReader::open(f.tmp.sub("out/shader-test-windows/game.pak"));
        REQUIRE(pack.ok());
        CHECK((*pack)->contains("materials/gem.material.json.hlsl5.shader"));
        CHECK_FALSE((*pack)->contains("shaders/gem.surface.glsl"));
    }
    SUBCASE("android assets") {
        auto r = export_project(f.options("android"));
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        const stdfs::path assets = f.tmp.sub("out/shader-test-android/app/src/main/assets");
        CHECK(shader_files(files_below(assets)) == twins_of("glsl300es"));
        const std::string index = testing::read_all(assets / "assets_index.txt");
        CHECK(index.find("materials/gem.material.json.glsl300es.shader") != std::string::npos);
        CHECK(index.find("gem.surface.glsl") == std::string::npos);
    }
    SUBCASE("web pack") {
        auto r = export_project(f.options("web"));
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        auto pack = PackReader::open(f.tmp.sub("out/shader-test-web/game.pak"));
        REQUIRE(pack.ok());
        CHECK(shader_files((*pack)->list("", true)) == twins_of("glsl300es"));
    }
}

TEST_CASE("export shaders: a snippet that does not compile fails the export with the errors validate lists") {
    Fixture f;
    testing::write_all(stdfs::path(f.proj) / "shaders/gem.surface.glsl", kBrokenSnippet);
    const MaterialDef material = read_material(f.proj, "materials/gem.material.json").material;
    const GeneratedShader g = generate_material_shader(material, kBrokenSnippet);
    const auto line = std::find(g.snippetLine.begin(), g.snippetLine.end(), 2);
    REQUIRE(line != g.snippetLine.end());
    f.shdc.stderrText = "top.glsl:" + std::to_string(line - g.snippetLine.begin() + 1) + ":0: error: 'tnt' : undeclared identifier\n";

    auto r = export_project(f.options("linux"));
    REQUIRE_FALSE(r.ok());
    CHECK_FALSE(stdfs::exists(f.tmp.sub("out/shader-test-linux")));
    ValidateOptions vo;
    vo.shaderContext = f.setup;
    const ValidationReport report = validate_project(f.proj, vo);
    const auto shaderError = std::find_if(report.errors.begin(), report.errors.end(), [](const ValidationIssue& e) { return e.file == "shaders/gem.surface.glsl"; });
    REQUIRE(shaderError != report.errors.end());
    CHECK(shaderError->message.find("line 2, column 16") != std::string::npos);
    CHECK(r.error().message.find("materials/gem.material.json does not compile") != std::string::npos);
    CHECK(r.error().message.find("error: " + shaderError->to_string()) != std::string::npos);
    CHECK(r.error().hint.find("factoria validate") != std::string::npos);
}

TEST_CASE("export shaders: without sokol-shdc and no cached twin the export says how to get it") {
    Fixture f;
    f.setup.env = [](const std::string&) { return std::string(); };
    auto r = export_project(f.options("linux"));
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("materials/gem.material.json") != std::string::npos);
    CHECK(r.error().hint.find("factoria setup shaders") != std::string::npos);
}

TEST_CASE("export shaders: a project without materials ships what it has and reports none") {
    Fixture f;
    stdfs::remove_all(stdfs::path(f.proj) / "materials");
    auto r = export_project(f.options("linux"));
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    CHECK(r->materials.empty());
    CHECK_FALSE(r->to_json().contains("materials"));
    CHECK(f.shdc.calls == 0);
    // A snippet no material names is game data like any other file.
    CHECK(stdfs::exists(f.tmp.sub("out/shader-test-linux/game/shaders/gem.surface.glsl")));
}

TEST_CASE("real sokol-shdc: an android export ships the glsl300es twin it compiled") {
    FA_SKIP_WITHOUT_SHDC(SetupContext{}, "sokol-shdc is not installed (SOKOL_SHDC, next to factoria, or `factoria setup shaders`): skipped here, runs in CI");
    Fixture f;
    f.setup = SetupContext{};
    auto r = export_project(f.options("android"));
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    const stdfs::path assets = f.tmp.sub("out/shader-test-android/app/src/main/assets");
    CHECK(shader_files(files_below(assets)) == twins_of("glsl300es"));
    auto twin = parse_json(testing::read_all(assets / "materials/gem.material.json.glsl300es.shader"));
    REQUIRE(twin.ok());
    CHECK((*twin)["programs"]["mesh"]["fs"].get<std::string>().find("#version 300 es") != std::string::npos);
}
