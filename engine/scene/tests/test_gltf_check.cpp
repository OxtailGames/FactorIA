// glTF files that lie about themselves (M93.2b): an accessor that reaches past its buffer, nodes that share one big mesh. The
// readers must refuse them with a message that names the file, never read outside the buffer or grow a mesh without bound.
// The fixtures are tiny .glb files built here.
#include <doctest.h>

#include <cstring>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/scene/gltf_file.h"
#include "fa/scene/gltf_mesh.h"
#include "fa/scene/mesh_store.h"
#include "fa/scene/skeleton.h"

using namespace fa;

namespace {

void put32(std::vector<std::uint8_t>& out, std::uint32_t v) {
    for (int i = 0; i < 4; ++i) out.push_back(std::uint8_t(v >> (8 * i)));
}

// A binary glTF: the JSON chunk (padded with spaces) and a BIN chunk of `binBytes` zero bytes (all positions at the origin).
std::vector<std::uint8_t> make_glb(const Json& doc, std::size_t binBytes) {
    std::string json = doc.dump();
    while (json.size() % 4) json.push_back(' ');
    const std::size_t binPadded = (binBytes + 3) / 4 * 4;
    std::vector<std::uint8_t> out = {'g', 'l', 'T', 'F'};
    put32(out, 2);
    put32(out, std::uint32_t(12 + 8 + json.size() + 8 + binPadded));
    put32(out, std::uint32_t(json.size()));
    put32(out, 0x4E4F534Au);  // "JSON"
    out.insert(out.end(), json.begin(), json.end());
    put32(out, std::uint32_t(binPadded));
    put32(out, 0x004E4942u);  // "BIN"
    out.resize(out.size() + binPadded, 0);
    return out;
}

// `nodes` nodes that all use mesh 0: one triangle list of `vertices` POSITION vertices; the buffer holds `bufferVertices` of them.
Json mesh_doc(std::size_t vertices, std::size_t bufferVertices, int nodes) {
    Json doc;
    doc["asset"] = {{"version", "2.0"}};
    doc["buffers"] = Json::array({Json{{"byteLength", bufferVertices * 12}}});
    doc["bufferViews"] = Json::array({Json{{"buffer", 0}, {"byteOffset", 0}, {"byteLength", bufferVertices * 12}}});
    doc["accessors"] = Json::array({Json{{"bufferView", 0}, {"componentType", 5126}, {"count", vertices}, {"type", "VEC3"}}});
    doc["meshes"] = Json::array({Json{{"primitives", Json::array({Json{{"attributes", {{"POSITION", 0}}}}})}}});
    Json list = Json::array();
    Json roots = Json::array();
    for (int i = 0; i < nodes; ++i) {
        list.push_back(Json{{"mesh", 0}});
        roots.push_back(i);
    }
    doc["nodes"] = list;
    doc["scenes"] = Json::array({Json{{"nodes", roots}}});
    return doc;
}

}  // namespace

TEST_CASE("gltf: a consistent file reads, and the same file with an accessor past its buffer is refused by every reader") {
    const auto good = make_glb(mesh_doc(3, 3, 1), 36);
    auto mesh = read_gltf_mesh_bytes(good, "tri.glb");
    std::string err = mesh.ok() ? std::string() : mesh.error().to_string();
    INFO(err);
    REQUIRE(mesh.ok());
    CHECK(mesh->data.vertex_count() == 3);

    // The accessor says 1000 vertices; the buffer holds 3. Without the check, 12000 bytes are read from a 36-byte buffer.
    const auto lying = make_glb(mesh_doc(1000, 3, 1), 36);
    auto refused = read_gltf_mesh_bytes(lying, "lying.glb");
    REQUIRE_FALSE(refused.ok());
    CHECK(refused.error().message.find("lying.glb") != std::string::npos);
    CHECK(refused.error().message.find("consistent glTF") != std::string::npos);
    CHECK_FALSE(refused.error().hint.empty());

    auto skeleton = parse_skeleton(lying, "lying.glb");
    REQUIRE_FALSE(skeleton.ok());
    CHECK(skeleton.error().message.find("consistent glTF") != std::string::npos);
}

TEST_CASE("gltf: nodes that share one big mesh cannot place more vertices than a mesh holds") {
    // 200000 vertices (2.4 MB of zeros) used by 8 nodes: 1.6 million vertices from a 2.4 MB file.
    const std::size_t each = 200000;
    static_assert(kMaxProceduralVertices < 8 * each, "the fixture must go over the limit");
    const auto glb = make_glb(mesh_doc(each, each, 8), each * 12);
    auto mesh = read_gltf_mesh_bytes(glb, "shared.glb");
    REQUIRE_FALSE(mesh.ok());
    CHECK(mesh.error().message.find("shared.glb") != std::string::npos);
    CHECK(mesh.error().message.find("vertices") != std::string::npos);
    CHECK_FALSE(mesh.error().hint.empty());

    // The same mesh used twice is fine.
    CHECK(read_gltf_mesh_bytes(make_glb(mesh_doc(each, each, 2), each * 12), "twice.glb").ok());
}

TEST_CASE("gltf: bytes that are not a glTF are an error that names the file") {
    const std::vector<std::uint8_t> junk = {1, 2, 3, 4, 5, 6, 7, 8};
    auto mesh = read_gltf_mesh_bytes(junk, "junk.glb");
    REQUIRE_FALSE(mesh.ok());
    CHECK(mesh.error().message.find("junk.glb") != std::string::npos);
    CHECK_FALSE(read_gltf_mesh_bytes({}, "empty.glb").ok());
    CHECK_FALSE(parse_skeleton(junk, "junk.glb").ok());
}
