// fa/scene/mesh_store.h: procedural meshes (validation, normals and tangents, the store, the .glb writer).
#include <doctest.h>

#include <chrono>
#include <cmath>
#include <filesystem>
#include <string>

#include "fa/core/fs.h"
#include "fa/scene/mesh_geometry.h"
#include "fa/scene/mesh_store.h"
#include "fa/scene/world.h"

using namespace fa;

namespace {

// A unit quad in XY facing +Z: two triangles, counter-clockwise seen from +Z, uv (0,0) top-left.
MeshInput quad() {
    MeshInput in;
    in.positions = {0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0};
    in.uvs = {0, 1, 1, 1, 1, 0, 0, 0};
    in.indices = {0, 1, 2, 0, 2, 3};
    in.hasIndices = true;
    return in;
}

std::string error_text(const Error& e) { return e.message + " | " + e.hint; }

bool has(const std::string& text, const char* needle) { return text.find(needle) != std::string::npos; }

struct TempProject {
    std::filesystem::path dir, oldRoot;
    TempProject() {
        oldRoot = fs::project_root();
        dir = std::filesystem::temp_directory_path() /
              ("fa_test_meshstore_" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
        std::filesystem::create_directories(dir);
        fs::set_project_root(dir);
    }
    ~TempProject() {
        fs::set_project_root(oldRoot);
        std::error_code ec;
        std::filesystem::remove_all(dir, ec);
    }
};

}  // namespace

TEST_CASE("mesh data: normals and tangents are computed when missing") {
    auto d = build_mesh_data(quad());
    REQUIRE(d.ok());
    CHECK(d->vertex_count() == 4);
    CHECK(d->triangle_count() == 2);
    for (std::size_t i = 0; i < 4; ++i) {  // the quad faces +Z
        CHECK(d->normals[i * 3] == doctest::Approx(0));
        CHECK(d->normals[i * 3 + 1] == doctest::Approx(0));
        CHECK(d->normals[i * 3 + 2] == doctest::Approx(1));
        // u grows along +X, v (down) along -Y: the tangent is +X and the handedness +1
        CHECK(d->tangents[i * 4] == doctest::Approx(1));
        CHECK(d->tangents[i * 4 + 1] == doctest::Approx(0));
        CHECK(d->tangents[i * 4 + 3] == doctest::Approx(1));
    }
    CHECK(d->bmin.x == 0);
    CHECK(d->bmax.y == 1);
    REQUIRE(d->submeshes.size() == 1);
    CHECK(d->submeshes[0].start == 0);
    CHECK(d->submeshes[0].count == 6);
}

TEST_CASE("mesh data: shared vertices get smooth normals, supplied normals are kept and normalised") {
    // A tent: two triangles sharing the ridge vertices 0 and 1.
    MeshInput in;
    in.positions = {0, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, -1, 1, 0, -1};
    in.indices = {0, 2, 1, 1, 2, 3, 0, 1, 4, 1, 5, 4};
    in.hasIndices = true;
    auto d = build_mesh_data(in);
    REQUIRE(d.ok());
    CHECK(std::fabs(d->normals[1]) > 0.7f);  // the ridge normal is the average of two slopes: vertical, not either slope's normal
    CHECK(std::fabs(d->normals[2]) < 0.1f);
    for (std::size_t i = 0; i < d->vertex_count(); ++i) {
        const float l = std::sqrt(d->normals[i * 3] * d->normals[i * 3] + d->normals[i * 3 + 1] * d->normals[i * 3 + 1] +
                                  d->normals[i * 3 + 2] * d->normals[i * 3 + 2]);
        CHECK(l == doctest::Approx(1.0f).epsilon(1e-4));
    }

    MeshInput given = quad();
    given.normals = {0, 0, 5, 0, 0, 5, 0, 0, 5, 0, 0, 5};
    auto g = build_mesh_data(given);
    REQUIRE(g.ok());
    CHECK(g->normals[2] == doctest::Approx(1.0f));
}

TEST_CASE("mesh data: without indices the vertices form a triangle soup; colors may be rgb or rgba") {
    MeshInput in;
    in.positions = {0, 0, 0, 1, 0, 0, 0, 1, 0};
    in.colors = {1, 0, 0, 0, 1, 0, 0, 0, 1};
    auto d = build_mesh_data(in);
    REQUIRE(d.ok());
    REQUIRE(d->indices.size() == 3);
    CHECK(d->indices[2] == 2);
    REQUIRE(d->colors.size() == 12);
    CHECK(d->colors[3] == 1.0f);
    CHECK(d->colors[4] == 0.0f);
    CHECK(d->colors[5] == 1.0f);
}

TEST_CASE("mesh data: errors name the field, the numbers and the fix") {
    {
        MeshInput in;
        auto d = build_mesh_data(in);
        REQUIRE_FALSE(d.ok());
        CHECK(has(error_text(d.error()), "positions"));
    }
    {
        MeshInput in = quad();
        in.positions.pop_back();
        auto d = build_mesh_data(in);
        REQUIRE_FALSE(d.ok());
        CHECK(has(d.error().message, "multiple of 3"));
        CHECK(!d.error().hint.empty());
    }
    {
        MeshInput in = quad();
        in.positions[4] = std::nanf("");
        auto d = build_mesh_data(in);
        REQUIRE_FALSE(d.ok());
        CHECK(has(d.error().message, "NaN"));
        CHECK(has(d.error().message, "vertex 1"));
    }
    {
        MeshInput in = quad();
        in.uvs.pop_back();
        auto d = build_mesh_data(in);
        REQUIRE_FALSE(d.ok());
        CHECK(has(d.error().message, "uvs"));
        CHECK(has(d.error().message, "7 numbers"));
        CHECK(has(d.error().message, "4 vertices"));
        CHECK(has(d.error().message, "expected 8"));
    }
    {
        MeshInput in = quad();
        in.normals = {0, 0, 1};
        auto d = build_mesh_data(in);
        REQUIRE_FALSE(d.ok());
        CHECK(has(d.error().message, "normals"));
    }
    {
        MeshInput in = quad();
        in.indices = {0, 1, 2, 0, 2, 9};
        auto d = build_mesh_data(in);
        REQUIRE_FALSE(d.ok());
        CHECK(has(d.error().message, "entry 5"));
        CHECK(has(d.error().message, "is 9"));
        CHECK(has(d.error().message, "4 vertices"));
        CHECK(has(d.error().message, "0..3"));
    }
    {
        MeshInput in = quad();
        in.indices = {0, 1, 2, 0};
        auto d = build_mesh_data(in);
        REQUIRE_FALSE(d.ok());
        CHECK(has(d.error().message, "multiple of 3"));
    }
    {
        MeshInput in = quad();
        in.submeshes = {{MeshMaterial{}, 0, 3}, {MeshMaterial{}, 3, 6}};
        auto d = build_mesh_data(in);
        REQUIRE_FALSE(d.ok());
        CHECK(has(d.error().message, "submeshes[1]"));
        CHECK(has(d.error().message, "beyond the 6 indices"));
    }
    {
        MeshInput in = quad();
        in.submeshes = {{MeshMaterial{}, 1, 3}};
        auto d = build_mesh_data(in);
        REQUIRE_FALSE(d.ok());
        CHECK(has(d.error().message, "multiples of 3"));
    }
    {
        MeshInput in = quad();
        in.submeshes = {{MeshMaterial{}, 0, 0}};
        REQUIRE_FALSE(build_mesh_data(in).ok());
    }
}

TEST_CASE("mesh data: an update keeps what it does not name and computes normals again") {
    auto first = build_mesh_data(quad());
    REQUIRE(first.ok());
    MeshInput moved;
    moved.positions = {0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1};  // the quad lies down (in the XZ plane)
    auto d = build_mesh_data(moved, &*first);
    REQUIRE(d.ok());
    CHECK(d->uvs == first->uvs);
    CHECK(d->indices == first->indices);
    CHECK(std::fabs(d->normals[1]) == doctest::Approx(1.0f));  // computed from the new positions
    CHECK(std::fabs(d->normals[2]) < 1e-4f);

    MeshInput fewer;
    fewer.positions = {0, 0, 0, 1, 0, 0, 0, 1, 0};
    auto bad = build_mesh_data(fewer, &*first);
    REQUIRE_FALSE(bad.ok());
    CHECK(has(bad.error().message, "kept from the mesh's previous data"));
}

TEST_CASE("mesh data: a mesh made without uvs can change its vertex count; given uvs must follow it") {
    MeshInput in;
    in.positions = {0, 0, 0, 1, 0, 0, 0, 1, 0};
    auto first = build_mesh_data(in);
    REQUIRE(first.ok());
    CHECK_FALSE(first->hasUvs);
    MeshInput grow;
    grow.positions = {0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 1, 0, 2, 0, 0, 2, 1, 0};
    auto bigger = build_mesh_data(grow, &*first);  // indices (a soup of 3) are kept: still valid
    REQUIRE(bigger.ok());
    CHECK(bigger->uvs.size() == 12);

    MeshInput withUv = in;
    withUv.uvs = {0, 0, 1, 0, 0, 1};
    auto uvd = build_mesh_data(withUv);
    REQUIRE(uvd.ok());
    CHECK(uvd->hasUvs);
    auto bad = build_mesh_data(grow, &*uvd);
    REQUIRE_FALSE(bad.ok());
    CHECK(has(bad.error().message, "uvs"));
}

TEST_CASE("mesh data: an update that changes the indices of a mesh with several submeshes asks for submeshes") {
    MeshInput in = quad();
    in.submeshes = {{MeshMaterial{"a"}, 0, 3}, {MeshMaterial{"b"}, 3, 3}};
    auto first = build_mesh_data(in);
    REQUIRE(first.ok());
    MeshInput upd;
    upd.indices = {0, 1, 2};
    upd.hasIndices = true;
    auto d = build_mesh_data(upd, &*first);
    REQUIRE_FALSE(d.ok());
    CHECK(has(d.error().message, "submeshes"));
}

TEST_CASE("mesh store: ids, update versions, destroy and the teaching errors") {
    MeshStore store;
    auto a = store.create(quad());
    auto b = store.create(quad());
    REQUIRE(a.ok());
    REQUIRE(b.ok());
    CHECK(*a == "mesh:1");
    CHECK(*b == "mesh:2");
    CHECK(MeshStore::is_id(*a));
    CHECK_FALSE(MeshStore::is_id("mesh:"));
    CHECK_FALSE(MeshStore::is_id("mesh:x"));
    CHECK_FALSE(MeshStore::is_id("cube"));
    CHECK(store.size() == 2);

    const auto v1 = store.find(*a)->version;
    MeshInput upd;
    upd.positions = {0, 0, 0, 2, 0, 0, 2, 2, 0, 0, 2, 0};
    REQUIRE(store.update(*a, upd).ok());
    CHECK(store.find(*a)->version == v1 + 1);
    CHECK(store.find(*a)->data.bmax.x == 2);

    REQUIRE(store.destroy(*a).ok());
    CHECK(store.find(*a) == nullptr);
    auto gone = store.get(*a);
    REQUIRE_FALSE(gone.ok());
    CHECK(has(gone.error().message, "mesh:1"));
    CHECK(has(gone.error().message, "does not exist"));
    CHECK(!gone.error().hint.empty());
    CHECK_FALSE(store.update(*a, upd).ok());
    CHECK_FALSE(store.destroy(*a).ok());
    auto notId = store.get("cube");
    REQUIRE_FALSE(notId.ok());
    CHECK(has(notId.error().message, "not a procedural mesh id"));

    store.clear();  // a scene load: the ids are not handed out again
    CHECK(store.size() == 0);
    auto c = store.create(quad());
    REQUIRE(c.ok());
    CHECK(*c == "mesh:3");
}

TEST_CASE("mesh store: the world releases its meshes when the scene is cleared") {
    World w;
    auto id = w.meshes().create(quad());
    REQUIRE(id.ok());
    CHECK(w.meshes().find(*id) != nullptr);
    w.clear();
    CHECK(w.meshes().find(*id) == nullptr);
}

TEST_CASE("mesh store: the geometry follows the version, and mesh_geometry_for picks procedural ids and primitives") {
    MeshStore store;
    auto id = store.create(quad());
    REQUIRE(id.ok());
    auto g1 = store.geometry(*id);
    REQUIRE(g1);
    CHECK(g1->positions.size() == 4);
    CHECK(g1->indices.size() == 6);
    CHECK(g1->bmax.x == 1);
    MeshInput upd;
    upd.positions = {0, 0, 0, 3, 0, 0, 3, 1, 0, 0, 1, 0};
    REQUIRE(store.update(*id, upd).ok());
    auto g2 = store.geometry(*id);
    CHECK(g2->bmax.x == 3);
    CHECK(mesh_geometry_for(store, *id));
    auto cube = mesh_geometry_for(store, "cube");
    REQUIRE(cube);
    CHECK(cube->bmax.x == doctest::Approx(0.5f));
    std::string why;
    CHECK_FALSE(mesh_geometry_for(store, "mesh:99", &why));
    CHECK(has(why, "mesh:99"));
}

TEST_CASE("mesh store: a ray hits the triangles of a mesh, not its box") {
    MeshStore store;
    MeshInput tri;  // a triangle in the XY plane whose box is a unit square: the corner (0.9, 0.9) is in the box but not on the triangle
    tri.positions = {0, 0, 0, 1, 0, 0, 0, 1, 0};
    tri.indices = {0, 1, 2};
    tri.hasIndices = true;
    auto id = store.create(tri);
    REQUIRE(id.ok());
    auto g = store.geometry(*id);
    REQUIRE(g);
    float t = -1;
    CHECK(ray_hits_mesh(*g, {0.2f, 0.2f, 5}, {0, 0, -1}, t));
    CHECK(t == doctest::Approx(5.0f));
    CHECK(ray_hits_mesh(*g, {0.2f, 0.2f, -3}, {0, 0, 2}, t));  // from behind, with a direction that is not unit length
    CHECK(t == doctest::Approx(1.5f));
    t = -1;
    CHECK_FALSE(ray_hits_mesh(*g, {0.9f, 0.9f, 5}, {0, 0, -1}, t));
    CHECK(t == -1);
    CHECK_FALSE(ray_hits_mesh(*g, {0.2f, 0.2f, 5}, {0, 0, 1}, t));  // pointing away
}

TEST_CASE("mesh store: the limit of live meshes is a teaching error") {
    MeshStore store;
    for (std::size_t i = 0; i < kMaxProceduralMeshes; ++i) REQUIRE(store.create(quad()).ok());
    auto over = store.create(quad());
    REQUIRE_FALSE(over.ok());
    CHECK(has(over.error().message, "256"));
    CHECK(has(over.error().hint, "mesh.destroy"));
}

TEST_CASE("mesh glb: a saved mesh loads back with its geometry, submesh materials and texture uri") {
    TempProject project;
    MeshInput in;
    in.positions = {0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0,  //
                    0, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1};
    in.uvs = {0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0};
    in.indices = {0, 1, 2, 0, 2, 3, 4, 5, 6, 4, 6, 7};
    in.hasIndices = true;
    in.colors = {1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 1, 1, 1, 1, 1};
    MeshMaterial wood;
    wood.name = "wood";
    wood.texture = "assets/textures/wood plank.png";
    wood.color = Color{0.5f, 0.25f, 0.125f, 1};
    wood.metallic = 0.1f;
    wood.roughness = 0.8f;
    MeshMaterial glass;
    glass.name = "glass";
    glass.blend = true;
    glass.doubleSided = true;
    glass.color = Color{0.2f, 0.4f, 0.8f, 0.5f};
    glass.emissive = Color{0.1f, 0.0f, 0.0f, 1};
    in.submeshes = {{wood, 0, 6}, {glass, 6, 6}};
    auto data = build_mesh_data(in);
    REQUIRE(data.ok());

    auto glb = mesh_to_glb(*data, "assets/models/two.glb");
    REQUIRE(glb.ok());
    REQUIRE(fs::write_bytes("assets/models/two.glb", glb->data(), glb->size()).ok());
    const std::string raw(glb->begin(), glb->end());
    CHECK(has(raw, "\"uri\":\"../textures/wood%20plank.png\""));
    CHECK(has(raw, "COLOR_0"));
    CHECK(has(raw, "\"alphaMode\":\"BLEND\""));

    auto names = gltf_material_names("assets/models/two.glb");
    REQUIRE(names.ok());
    REQUIRE(names->size() == 2);
    CHECK((*names)[0] == "wood");
    CHECK((*names)[1] == "glass");

    auto geo = load_mesh_geometry("assets/models/two.glb");
    REQUIRE(geo.ok());
    CHECK((*geo)->positions.size() == 16);  // the loader reads the shared vertex accessor once per primitive
    CHECK((*geo)->indices.size() == 12);
    CHECK((*geo)->positions[2].x == doctest::Approx(1));
    CHECK((*geo)->positions[2].y == doctest::Approx(1));
    CHECK((*geo)->positions[5].z == doctest::Approx(1));
    CHECK((*geo)->indices[11] == 8 + 7);
    CHECK((*geo)->bmax.y == doctest::Approx(1));
}

TEST_CASE("mesh glb: a run-time texture cannot be saved, and the error says what to use instead") {
    MeshInput in = quad();
    MeshMaterial m;
    m.name = "live";
    m.texture = "runtime:3";
    in.submeshes = {{m, 0, 6}};
    auto data = build_mesh_data(in);
    REQUIRE(data.ok());
    auto glb = mesh_to_glb(*data, "assets/models/x.glb");
    REQUIRE_FALSE(glb.ok());
    CHECK(has(glb.error().message, "runtime:3"));
    CHECK(has(glb.error().hint, "project-relative"));
}
