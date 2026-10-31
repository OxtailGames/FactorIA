// Procedural meshes from scripts (mesh.create / update / destroy / save, docs/SCRIPTING.md, "Procedural meshes").
#include <doctest.h>

#include "fa/scene/mesh_geometry.h"
#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {
Json eval_ok(TestHost& h, const char* code) {
    auto r = h.scripts.eval(code);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    return r.value();
}
std::string eval_error(TestHost& h, const char* code) {
    auto r = h.scripts.eval(code);
    return r.ok() ? std::string() : r.error().message;
}
void scene_with_cube(TestHost& h, const char* name) {
    h.file(name, Json::object({{"format", "factoria.scene/1"}, {"entities", Json::array({
        Json::parse(R"({"id":"thing","components":{"Transform":{"position":[0,0,0]},"MeshRenderer":{"mesh":"cube"}}})")})}}).dump());
}
const char* kQuad = "{ positions: [0,0,0, 1,0,0, 1,1,0, 0,1,0], indices: [0,1,2, 0,2,3] }";
}  // namespace

TEST_CASE("mesh script: create, show on an entity, update, destroy") {
    TestHost h("mesh_script");
    scene_with_cube(h, "scenes/main.scene.json");
    REQUIRE(h.start());
    CHECK(h.load_scene_now("scenes/main.scene.json").empty());
    h.step_frames(1);

    CHECK(eval_ok(h, (std::string("globalThis.m = mesh.create(") + kQuad + "); m.id").c_str()).get<std::string>().rfind("mesh:", 0) == 0);
    CHECK(eval_ok(h, "m.vertexCount").get<int>() == 4);
    CHECK(eval_ok(h, "m.triangleCount").get<int>() == 2);
    CHECK(eval_ok(h, "m.bounds.max.x").get<double>() == doctest::Approx(1.0));
    CHECK(eval_ok(h, "mesh.exists(m)").get<bool>());
    CHECK(h.w.meshes().size() == 1);

    // MeshRenderer.mesh takes the id
    CHECK(eval_ok(h, "const e = world.find('thing'); e.get('MeshRenderer').mesh = m.id; e.get('MeshRenderer').mesh").get<std::string>() == eval_ok(h, "m.id").get<std::string>());
    h.step_frames(1);

    // update keeps what is not given and refreshes the handle; the version grows
    CHECK(eval_ok(h, "m.update({ positions: [0,0,0, 4,0,0, 4,2,0, 0,2,0] }); m.bounds.max.x").get<double>() == doctest::Approx(4.0));
    CHECK(eval_ok(h, "m.triangleCount").get<int>() == 2);
    CHECK(eval_ok(h, "mesh.list()[0].version").get<int>() == 2);
    // typed arrays and nested arrays are accepted
    CHECK(eval_ok(h, "m.update({ positions: new Float32Array([0,0,0, 1,0,0, 0,1,0]), indices: new Uint16Array([0,1,2]) }); m.vertexCount").get<int>() == 3);
    CHECK(eval_ok(h, "m.update({ positions: [[0,0,0],[1,0,0],[0,1,0],[1,1,0]], indices: [[0,1,2],[1,3,2]] }); m.triangleCount").get<int>() == 2);

    CHECK(eval_ok(h, "m.destroy(); [m.destroyed, m.alive, mesh.exists(m.id)]") == Json::parse("[true,false,false]"));
    CHECK(h.w.meshes().size() == 0);
    CHECK(eval_ok(h, "m.destroy(); 1").get<int>() == 1);  // twice is fine
    CHECK(eval_error(h, "m.update({ positions: [0,0,0] })").find("destroyed") != std::string::npos);
    h.step_frames(1);  // the entity still names it: a placeholder is drawn, nothing crashes
}

TEST_CASE("mesh script: errors teach (lengths, indices, submeshes, unknown fields and ids)") {
    TestHost h("mesh_script_errors");
    REQUIRE(h.start());
    const std::string uv = eval_error(h, "mesh.create({ positions: [0,0,0, 1,0,0, 0,1,0], uvs: [0,0, 1,0], indices: [0,1,2] })");
    CHECK(uv.find("uvs") != std::string::npos);
    CHECK(uv.find("expected 6") != std::string::npos);
    const std::string ix = eval_error(h, "mesh.create({ positions: [0,0,0, 1,0,0, 0,1,0], indices: [0,1,7] })");
    CHECK(ix.find("is 7") != std::string::npos);
    CHECK(ix.find("valid: 0..2") != std::string::npos);
    CHECK(eval_error(h, "mesh.create({ positions: [0,0,0, 1,0,0, 0,1,0], indices: [0,1,-1] })").find("whole number from 0") != std::string::npos);
    CHECK(eval_error(h, "mesh.create({ positions: [0,0,0, 1,0,0, 0,1,0], indices: [0,1,2], submeshes: [{ start: 0, count: 6 }] })").find("ends beyond the 3 indices") != std::string::npos);
    CHECK(eval_error(h, "mesh.create({ positions: [0,0,0, 1,0,0, 0], indices: [0,1,2] })").find("multiple of 3") != std::string::npos);
    CHECK(eval_error(h, "mesh.create({ positions: [0,0,0, 1,0,0, 0,NaN,0], indices: [0,1,2] })").find("NaN") != std::string::npos);
    CHECK(eval_error(h, "mesh.create({ position: [0,0,0] })").find("Did you mean 'positions'") != std::string::npos);
    CHECK(eval_error(h, "mesh.create()").find("options object") != std::string::npos);
    CHECK(eval_error(h, "mesh.create({ positions: [0,0,0, 1,0,0, 0,1,0], submeshes: [{ material: { colour: 'red' } }] })").find("Did you mean 'color'") != std::string::npos);
    const std::string stale = eval_error(h, "mesh.update('mesh:99', { positions: [0,0,0] })");
    CHECK(stale.find("does not exist") != std::string::npos);
    CHECK(stale.find("scene") != std::string::npos);
    CHECK(eval_error(h, "mesh.destroy('cube')").find("not a procedural mesh id") != std::string::npos);
    CHECK(eval_error(h, "mesh.save('mesh:99', 'a.glb')").find("does not exist") != std::string::npos);
}

TEST_CASE("mesh script: loading a scene releases the meshes, and a kept handle says so") {
    TestHost h("mesh_script_scene");
    scene_with_cube(h, "scenes/a.scene.json");
    scene_with_cube(h, "scenes/b.scene.json");
    REQUIRE(h.start());
    CHECK(h.load_scene_now("scenes/a.scene.json").empty());
    h.step_frames(1);
    eval_ok(h, (std::string("globalThis.kept = mesh.create(") + kQuad + "); kept.id").c_str());
    CHECK(eval_ok(h, "kept.alive").get<bool>());
    CHECK(h.load_scene_now("scenes/b.scene.json").empty());
    h.step_frames(1);
    CHECK(h.w.meshes().size() == 0);
    CHECK_FALSE(eval_ok(h, "kept.alive").get<bool>());
    const std::string e = eval_error(h, "kept.update({ positions: [0,0,0, 1,0,0, 0,1,0] })");
    CHECK(e.find("does not exist") != std::string::npos);
    CHECK(e.find("scene") != std::string::npos);
    // destroying a handle of an unloaded scene is quiet; a new mesh gets a new id, never the old one
    CHECK(eval_ok(h, "kept.destroy(); kept.destroyed").get<bool>());
    CHECK(eval_ok(h, (std::string("mesh.create(") + kQuad + ").id != kept.id").c_str()).get<bool>());
}

TEST_CASE("mesh script: save writes a .glb that loads back with its submeshes and materials") {
    TestHost h("mesh_script_save");
    REQUIRE(h.start());
    eval_ok(h,
            "globalThis.m = mesh.create({ positions: [0,0,0, 1,0,0, 1,1,0, 0,1,0, 2,0,0, 2,1,0], indices: [0,1,2, 0,2,3, 1,4,5, 1,5,2],"
            " submeshes: [{ material: { name: 'skin', color: '#ff8040', roughness: 0.3 }, start: 0, count: 6 },"
            "             { material: 'cloth' }] }); m.id");
    CHECK(eval_ok(h, "m.submeshes[1].start").get<int>() == 6);
    CHECK(eval_ok(h, "m.save('assets/models/quad.glb')").get<std::string>() == "assets/models/quad.glb");
    auto g = load_mesh_geometry("assets/models/quad.glb");
    REQUIRE(g.ok());
    CHECK((*g)->positions.size() == 12);  // the loader reads the shared vertices once per primitive (submesh)
    CHECK((*g)->indices.size() == 12);
    auto names = gltf_material_names("assets/models/quad.glb");
    REQUIRE(names.ok());
    CHECK(*names == std::vector<std::string>{"skin", "cloth"});
    CHECK(eval_error(h, "m.save('assets/models/quad.png')").find("does not end in .glb") != std::string::npos);
    CHECK(eval_error(h, "m.save('.factoria/cache/x.glb')").find("managed by the engine") != std::string::npos);
    CHECK(eval_error(h, "m.save('')").find("project-relative") != std::string::npos);
}
