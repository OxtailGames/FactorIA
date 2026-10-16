// assets.import of Wavefront OBJ: the glTF it writes is read back with cgltf, the loader the engine uses.
#include <doctest.h>

#include <cgltf.h>

#include <array>
#include <cmath>

#include "asset_test_helpers.h"

using namespace fa;
using namespace fa::testing;

namespace {

// A glTF file parsed with its buffers loaded and validated.
struct Gltf {
    cgltf_data* data = nullptr;
    explicit Gltf(const std::filesystem::path& file) {
        cgltf_options options{};
        const std::string path = file.string();
        REQUIRE_MESSAGE(cgltf_parse_file(&options, path.c_str(), &data) == cgltf_result_success, path);
        REQUIRE(cgltf_load_buffers(&options, data, path.c_str()) == cgltf_result_success);
        CHECK(cgltf_validate(data) == cgltf_result_success);
    }
    ~Gltf() { cgltf_free(data); }
    Gltf(const Gltf&) = delete;
    Gltf& operator=(const Gltf&) = delete;
};

const cgltf_accessor* attribute(const cgltf_primitive& prim, cgltf_attribute_type type) {
    for (cgltf_size i = 0; i < prim.attributes_count; ++i)
        if (prim.attributes[i].type == type) return prim.attributes[i].data;
    return nullptr;
}

std::array<float, 3> vec3(const cgltf_accessor* a, cgltf_size i) {
    std::array<float, 3> v{};
    cgltf_accessor_read_float(a, i, v.data(), 3);
    return v;
}

const char* kQuad =
    "v 0 0 0\nv 2 0 0\nv 2 2 0\nv 0 2 0\n"
    "vt 0 0\nvt 1 0\nvt 1 1\nvt 0 1\n"
    "vn 0 0 1\n"
    "f 1/1/1 2/2/1 3/3/1 4/4/1\n";

}  // namespace

TEST_CASE("assets.import: an OBJ quad becomes two triangles in a glTF the engine loader reads") {
    AssetsProject p;
    write_all(p.tmp.path / "art/quad.obj", kQuad);
    const Json r = p.ok("assets.import", {{"source", (p.tmp.path / "art/quad.obj").string()}, {"license", "CC0"}});
    CHECK(r["importer"] == "obj");
    CHECK(r["path"] == "assets/models/quad.gltf");
    CHECK(r["details"]["objects"] == 1);
    CHECK(r["details"]["vertices"] == 4);
    CHECK(r["details"]["triangles"] == 2);
    CHECK(r["details"]["size"] == Json::array({2.0, 2.0, 0.0}));
    CHECK(r["details"]["boundsMax"] == Json::array({2.0, 2.0, 0.0}));
    CHECK_FALSE(r.contains("warnings"));
    CHECK(p.manifest()["assets"]["assets/models/quad.gltf"]["provenance"]["origin"] == "imported");

    Gltf g(p.file("assets/models/quad.gltf"));
    REQUIRE(g.data->meshes_count == 1);
    const cgltf_primitive& prim = g.data->meshes[0].primitives[0];
    CHECK(prim.type == cgltf_primitive_type_triangles);
    REQUIRE(prim.indices != nullptr);
    CHECK(prim.indices->count == 6);
    const cgltf_accessor* position = attribute(prim, cgltf_attribute_type_position);
    const cgltf_accessor* normal = attribute(prim, cgltf_attribute_type_normal);
    const cgltf_accessor* uv = attribute(prim, cgltf_attribute_type_texcoord);
    REQUIRE((position && normal && uv));
    CHECK(position->count == 4);
    CHECK(vec3(position, 2) == std::array<float, 3>{2, 2, 0});
    CHECK(vec3(normal, 0) == std::array<float, 3>{0, 0, 1});
    float st[2];
    cgltf_accessor_read_float(uv, 2, st, 2);  // OBJ's vt (1, 1) is glTF's (1, 0): v is flipped
    CHECK(st[0] == doctest::Approx(1.0f));
    CHECK(st[1] == doctest::Approx(0.0f));
    cgltf_accessor_read_float(uv, 0, st, 2);
    CHECK(st[1] == doctest::Approx(1.0f));
}

TEST_CASE("assets.import: an OBJ without normals gets flat ones; negative indices and missing UVs are fine") {
    AssetsProject p;
    write_all(p.tmp.path / "art/flat.obj", "# no vt, no vn\nv 0 0 0\nv 1 0 0\nv 1 1 0\nv 0 1 0\nf -4 -3 -2 -1\n");
    const Json r = p.ok("assets.import", {{"source", (p.tmp.path / "art/flat.obj").string()}});
    CHECK(r["details"]["triangles"] == 2);
    CHECK(r["details"]["vertices"] == 6);  // flat shading: a vertex per triangle corner
    Gltf g(p.file("assets/models/flat.gltf"));
    const cgltf_primitive& prim = g.data->meshes[0].primitives[0];
    const cgltf_accessor* normal = attribute(prim, cgltf_attribute_type_normal);
    REQUIRE(normal != nullptr);
    for (cgltf_size i = 0; i < normal->count; ++i) CHECK(vec3(normal, i) == std::array<float, 3>{0, 0, 1});
    CHECK(attribute(prim, cgltf_attribute_type_texcoord) == nullptr);
}

TEST_CASE("assets.import: OBJ objects, materials, and their texture") {
    AssetsProject p;
    const auto art = p.tmp.path / "art";
    write_png(art / "textures/wood.png", make_image(2, 2, {200, 100, 50, 255}));
    write_all(art / "crate.mtl",
              "newmtl Wood\nKd 0.5 0.25 0.125\nmap_Kd -s 1 1 1 textures/wood.png\n\n"
              "newmtl Glass\nKd 0 1 0\nd 0.5\n");
    write_all(art / "crate.obj",
              "mtllib crate.mtl\nv 0 0 0\nv 1 0 0\nv 1 1 0\nv 0 1 0\nvt 0 0\nvt 1 0\nvt 1 1\n"
              "o Box\nusemtl Wood\nf 1/1 2/2 3/3\n"
              "o Lid\nusemtl Glass\nf 1 3 4\nusemtl Missing\nf 1 2 4\n");
    const Json r = p.ok("assets.import", {{"source", (art / "crate.obj").string()}, {"path", "assets/models/crate/"}});
    CHECK(r["path"] == "assets/models/crate/crate.gltf");
    CHECK(r["details"]["objects"] == 2);
    CHECK(r["details"]["materials"] == 2);
    CHECK(r["details"]["textures"] == 1);
    CHECK(r["written"].size() == 2);
    CHECK(p.exists("assets/models/crate/wood.png"));
    CHECK(has_warning(r, "Material 'Missing' is not defined"));

    Gltf g(p.file("assets/models/crate/crate.gltf"));
    REQUIRE(g.data->meshes_count == 2);
    CHECK(std::string(g.data->meshes[0].name) == "Box");
    CHECK(g.data->meshes[1].primitives_count == 2);  // Glass faces and the faces of the unknown material
    REQUIRE(g.data->materials_count == 2);
    const cgltf_pbr_metallic_roughness& wood = g.data->materials[0].pbr_metallic_roughness;
    CHECK(wood.base_color_factor[0] == doctest::Approx(0.5f));
    CHECK(wood.base_color_factor[2] == doctest::Approx(0.125f));
    REQUIRE(wood.base_color_texture.texture != nullptr);
    CHECK(std::string(wood.base_color_texture.texture->image->uri) == "wood.png");
    CHECK(g.data->materials[1].pbr_metallic_roughness.base_color_texture.texture == nullptr);
    CHECK(g.data->materials[1].pbr_metallic_roughness.base_color_factor[3] == doctest::Approx(0.5f));
    CHECK(g.data->materials[1].alpha_mode == cgltf_alpha_mode_blend);
}

TEST_CASE("assets.import: an OBJ whose material library or texture is missing still imports, with warnings") {
    AssetsProject p;
    const auto art = p.tmp.path / "art";
    write_all(art / "a.obj", "mtllib nope.mtl\nv 0 0 0\nv 1 0 0\nv 0 1 0\nusemtl Red\nf 1 2 3\n");
    const Json a = p.ok("assets.import", {{"source", (art / "a.obj").string()}});
    CHECK(has_warning(a, "nope.mtl"));
    CHECK(has_warning(a, "'Red'"));

    write_all(art / "b.mtl", "newmtl Red\nKd 1 0 0\nmap_Kd gone.png\n");
    write_all(art / "b.obj", "mtllib b.mtl\nv 0 0 0\nv 1 0 0\nv 0 1 0\nusemtl Red\nf 1 2 3\n");
    const Json b = p.ok("assets.import", {{"source", (art / "b.obj").string()}});
    CHECK(has_warning(b, "gone.png"));
    CHECK(b["details"]["textures"] == 0);
}

TEST_CASE("assets.import: broken OBJ files are errors with the line") {
    AssetsProject p;
    const auto art = p.tmp.path / "art";
    write_all(art / "range.obj", "v 0 0 0\nv 1 0 0\nv 0 1 0\nf 1 2 7\n");
    CommandResult range = p.call("assets.import", {{"source", (art / "range.obj").string()}});
    REQUIRE_FALSE(range.ok);
    CHECK(range.error["message"].get<std::string>().find("range.obj:4") != std::string::npos);
    CHECK(range.error["message"].get<std::string>().find("vertex 7") != std::string::npos);

    write_all(art / "nan.obj", "v 0 zero 0\n");
    CommandResult nan = p.call("assets.import", {{"source", (art / "nan.obj").string()}});
    REQUIRE_FALSE(nan.ok);
    CHECK(nan.error["message"].get<std::string>().find("nan.obj:1") != std::string::npos);

    write_all(art / "points.obj", "v 0 0 0\nv 1 0 0\nl 1 2\n");
    CommandResult points = p.call("assets.import", {{"source", (art / "points.obj").string()}});
    REQUIRE_FALSE(points.ok);
    CHECK(points.error["message"].get<std::string>().find("no faces") != std::string::npos);
    CHECK_FALSE(p.exists("assets/models/points.gltf"));
}

TEST_CASE("assets.import: a big OBJ uses 32-bit indices") {
    AssetsProject p;
    // A strip of 40000 quads with flat shading: 240000 vertices, over what 16-bit indices hold.
    std::string obj;
    const int quads = 40000;
    for (int i = 0; i <= quads; ++i) obj += "v " + std::to_string(i) + " 0 0\nv " + std::to_string(i) + " 1 0\n";
    for (int i = 0; i < quads; ++i) {
        const int a = 2 * i + 1;
        obj += "f " + std::to_string(a) + " " + std::to_string(a + 2) + " " + std::to_string(a + 3) + " " + std::to_string(a + 1) + "\n";
    }
    write_all(p.tmp.path / "art/strip.obj", obj);
    const Json r = p.ok("assets.import", {{"source", (p.tmp.path / "art/strip.obj").string()}});
    CHECK(r["details"]["triangles"] == 2 * quads);
    Gltf g(p.file("assets/models/strip.gltf"));
    const cgltf_primitive& prim = g.data->meshes[0].primitives[0];
    CHECK(prim.indices->component_type == cgltf_component_type_r_32u);
    CHECK(attribute(prim, cgltf_attribute_type_position)->count == 6 * quads);
}
