// assets.import of FBX: converted by FBX2glTF or Blender, which are not part of FactorIA.
#include <doctest.h>

#include <cgltf.h>

#include "asset_test_helpers.h"
#include "fa/core/process.h"

using namespace fa;
using namespace fa::testing;

namespace {

// Puts the converter lookup back to the real machine when the test ends.
struct ConverterOverride {
    explicit ConverterOverride(const FbxConverters& converters) { set_fbx_converters(&converters); }
    ~ConverterOverride() { set_fbx_converters(nullptr); }
};

}  // namespace

TEST_CASE("assets.import: FBX without FBX2glTF or Blender says how to install one") {
    AssetsProject p;
    write_all(p.tmp.path / "art/ship.fbx", "Kaydara FBX Binary  ");
    const FbxConverters none;
    ConverterOverride override(none);
    CommandResult r = p.call("assets.import", {{"source", (p.tmp.path / "art/ship.fbx").string()}});
    REQUIRE_FALSE(r.ok);
    const std::string message = r.error["message"].get<std::string>(), hint = r.error["hint"].get<std::string>();
    CHECK(message.find("closed format") != std::string::npos);
    CHECK(hint.find("https://www.blender.org/download/") != std::string::npos);
    CHECK(hint.find("https://github.com/godotengine/FBX2glTF/releases") != std::string::npos);
    CHECK(hint.find("FACTORIA_FBX2GLTF") != std::string::npos);
    CHECK(hint.find("glTF 2.0") != std::string::npos);  // or convert it yourself
    CHECK_FALSE(p.exists("assets/models/ship.glb"));
    CHECK_FALSE(p.exists("assets.json"));
}

TEST_CASE("assets.import: a converter that does not work is an error, not a half-written file") {
    AssetsProject p;
    write_all(p.tmp.path / "art/ship.fbx", "Kaydara FBX Binary  ");
    FbxConverters broken;
    broken.fbx2gltf = (p.tmp.path / "no_such_converter").string();
    ConverterOverride override(broken);
    CommandResult r = p.call("assets.import", {{"source", (p.tmp.path / "art/ship.fbx").string()}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["message"].get<std::string>().find("ship.fbx") != std::string::npos);
    CHECK(r.error["message"].get<std::string>().find("failed") != std::string::npos);
    CHECK(r.error["hint"].get<std::string>().find("Blender") != std::string::npos);
    CHECK_FALSE(p.exists("assets/models/ship.glb"));
}

// Needs Blender (or FBX2glTF plus a way to make an FBX, which only Blender gives us here): skipped when it is not installed.
TEST_CASE("assets.import: FBX is converted to glb with Blender") {
    const FbxConverters found = find_fbx_converters();
    if (found.blender.empty()) {
        MESSAGE("Blender was not found: the real FBX conversion is not tested on this machine");
        return;
    }
    AssetsProject p;
    const auto art = p.tmp.path / "art";
    std::filesystem::create_directories(art);
    const std::string fbx = (art / "cube.fbx").string();
    write_all(art / "make_cube.py",
              "import bpy\n"
              "for o in list(bpy.data.objects):\n"
              "    bpy.data.objects.remove(o, do_unlink=True)\n"
              "bpy.ops.mesh.primitive_cube_add(size=2)\n"
              "bpy.ops.export_scene.fbx(filepath=r'" + fbx + "')\n");
    ProcessOptions make;
    make.argv = {found.blender, "-b", "--factory-startup", "--python-exit-code", "1", "--python", (art / "make_cube.py").string()};
    make.timeoutSeconds = 120;
    auto made = run_process(make);
    if (!made.ok() || made->exitCode != 0 || !std::filesystem::exists(fbx)) {
        MESSAGE("Blender could not write a test FBX: the real FBX conversion is not tested on this machine");
        return;
    }

    const Json r = p.ok("assets.import", {{"source", fbx}, {"license", "CC0"}});
    CHECK(r["importer"] == "fbx");
    CHECK(r["path"] == "assets/models/cube.glb");
    CHECK(has_warning(r, "Converted with"));
    CHECK(r["details"]["converter"].is_string());
    CHECK(p.manifest()["assets"]["assets/models/cube.glb"]["provenance"]["origin"] == "imported");

    cgltf_options options{};
    cgltf_data* data = nullptr;
    const std::string glb = p.file("assets/models/cube.glb").string();
    REQUIRE(cgltf_parse_file(&options, glb.c_str(), &data) == cgltf_result_success);
    REQUIRE(cgltf_load_buffers(&options, data, glb.c_str()) == cgltf_result_success);
    CHECK(cgltf_validate(data) == cgltf_result_success);
    REQUIRE(data->meshes_count >= 1);
    cgltf_size triangles = 0;
    for (cgltf_size m = 0; m < data->meshes_count; ++m)
        for (cgltf_size i = 0; i < data->meshes[m].primitives_count; ++i) {
            const cgltf_primitive& prim = data->meshes[m].primitives[i];
            triangles += (prim.indices ? prim.indices->count : prim.attributes[0].data->count) / 3;
        }
    CHECK(triangles == 12);  // the default cube is 6 quads
    cgltf_free(data);
}
