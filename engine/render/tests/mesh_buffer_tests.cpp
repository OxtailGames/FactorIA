// Meshes drawn from compute buffers (M72.4, docs/shaders/SHADERS_COMPUTE.md "Drawing from a compute buffer"): a compute
// material writes the instances, a mesh material with "buffers" reads them in vertex() and surface(),
// MeshRenderer.instances is the count. The fixtures are tests/data/materials/materials/meshbuf*.material.json (twins
// made by tools/common/tests/shaders_fixtures_test.cpp). What needs storage buffers in a vertex shader (Metal, D3D11,
// GL 4.3+) says "SKIPPED, no compute here" elsewhere (FA_REQUIRE_COMPUTE=1 turns that into a failure on a runner that
// must have it).
#include "fa/core/engine_version.h"
#include "fa/render/compute.h"
#include "test_util.h"

#include <cmath>
#include <cstdlib>
#include <fstream>
#include <iterator>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "fa/scene/animation.h"

#include "compute_internal.h"
#include "render_features.h"
#include "renderer_test_access.h"

using namespace fa;
using namespace fa::test;

namespace {

const char* const kFill = "materials/meshbuf_fill.material.json";
const char* const kMesh = "materials/meshbuf.material.json";
const char* const kFull = "materials/full_meshbuf.material.json";
const char* const kScale = "materials/scale.material.json";

struct Scope {
    Gfx& g = gfx();
    Scope() {
        REQUIRE(g.ok);
        g.renderer.clear_asset_cache();
        install_materials();
    }
    ~Scope() {
        for (const Json& b : g.renderer.compute().list()) (void)g.renderer.compute().destroy_buffer(b["id"].get<int>());
        ComputeTestAccess::set_backend(g.renderer.compute(), -1);
        ComputeTestAccess::set_compute_capable(g.renderer.compute(), -1);
        ComputeTestAccess::set_binding_limit(g.renderer.compute(), -1);
        g.renderer.clear_asset_cache();
    }
    Compute& compute() { return g.renderer.compute(); }
};

struct ErrorLog {
    struct Lines {
        std::mutex mu;
        std::vector<std::string> lines;
    };
    std::shared_ptr<Lines> shared = std::make_shared<Lines>();
    int id;
    ErrorLog()
        : id(add_log_sink([l = shared](const LogEntry& e) {
              if (e.level < LogLevel::Error) return;
              std::lock_guard<std::mutex> lk(l->mu);
              l->lines.push_back(e.message);
          })) {}
    ~ErrorLog() { remove_log_sink(id); }
    ErrorLog(const ErrorLog&) = delete;
    ErrorLog& operator=(const ErrorLog&) = delete;
    int count(const std::string& needle) const {
        std::lock_guard<std::mutex> lk(shared->mu);
        int n = 0;
        for (const std::string& l : shared->lines)
            if (l.find(needle) != std::string::npos) ++n;
        return n;
    }
    int total() const {
        std::lock_guard<std::mutex> lk(shared->mu);
        return int(shared->lines.size());
    }
};

void skip_without_compute(const char* what, const std::string& why) {
    const char* v = std::getenv("FA_REQUIRE_COMPUTE");
    if (v && *v && std::string(v) != "0")
        FAIL("FA_REQUIRE_COMPUTE=1 but this backend has no compute (" << why << "): " << what);
    MESSAGE("SKIPPED, no compute here (" << why << "): " << what << " (FA_REQUIRE_COMPUTE=1 fails instead)");
}

void add_camera(World& w, Vec3 pos) {
    Entity cam = make(w, "cam", pos);
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
}

// One cube (half a unit wide, black: the instance colour is all the light it gets) at `pos` drawn with `material`.
Entity add_instanced(World& w, const char* material, Json params, int instances, Vec3 pos = {0, 0, 0}) {
    Entity e = make(w, "points", pos);
    w.get<Transform>(e)->scale = {0.5f, 0.5f, 0.5f};
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = "cube";
    m.color = Color::black();
    m.material = material;
    m.materialParams = std::move(params);
    m.instances = instances;
    return e;
}

bool is_red(const Color& c) { return c.r > 0.5f && c.g < 0.3f && c.b < 0.3f; }

// The number of red runs along the picture's middle row (one per instance drawn there, 1 unit = ~40 px apart, ~20 px
// wide).
int count_runs(const Image& img) {
    int runs = 0;
    bool in = false;
    for (int x = 0; x < img.width; ++x) {
        const bool red = is_red(img.pixel(x, img.height / 2));
        if (red && !in) ++runs;
        in = red;
    }
    return runs;
}

// Writes `count` instances into a buffer of `size` elements, in a row 1 unit apart centred on element 2; element `hide`
// hidden.
void fill(Compute& c, int id, int count, int hide = -1) {
    ComputeDispatch d;
    d.material = kFill;
    d.buffers["points"] = id;
    d.params = Json::object({{"count", count}, {"spacing", 1.0}, {"hide", hide}});
    d.groups[0] = 1;
    auto ran = c.dispatch(d);
    REQUIRE_MESSAGE(ran.ok(), ran.error().to_string());
}

int make_buffer(Compute& c, int elements) {
    auto id = c.create_buffer(kFill, "points", std::uint64_t(elements));
    REQUIRE_MESSAGE(id.ok(), id.error().to_string());
    return *id;
}

}  // namespace

TEST_CASE("mesh buffers: a compute material writes N positions and the mesh draws N instances") {
    Scope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("instances from a compute buffer are not drawn", why);
        return;
    }
    const int id = make_buffer(s.compute(), 8);
    fill(s.compute(), id, 5);
    ErrorLog log;
    auto frame = [&](int instances) {
        World w;
        add_camera(w, {0, 0, 4});
        add_instanced(w, kMesh, Json::object({{"points", id}}), instances);
        return s.g.render(w);
    };
    CHECK(count_runs(frame(5)) == 5);
    CHECK(count_runs(frame(3)) == 3);  // fewer instances than elements: the first three
    // Elements the compute pass did not write (all zero, flag 0) collapse, so 8 instances show the 5 written ones.
    CHECK(count_runs(frame(8)) == 5);
    // 0 = a normal draw of one mesh: vertex() still runs once, with fa_instance_index 0.
    CHECK(count_runs(frame(0)) == 1);
    CHECK(log.total() == 0);
    CHECK(s.g.renderer.stats().materialFallbacks.empty());
}

TEST_CASE("mesh buffers: the instance count and positions follow the buffer, with no CPU round trip (GPU culling by a "
          "flag)") {
    Scope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("GPU culling by a flag is not drawn", why);
        return;
    }
    const int id = make_buffer(s.compute(), 8);
    ErrorLog log;
    World w;
    add_camera(w, {0, 0, 4});
    add_instanced(w, kMesh, Json::object({{"points", id}}), 5);
    fill(s.compute(), id, 5);
    CHECK(count_runs(s.g.render(w)) == 5);
    fill(s.compute(), id, 5, 2);  // the compute pass clears the flag of instance 2: it is collapsed by vertex()
    CHECK(count_runs(s.g.render(w)) == 4);
    fill(s.compute(), id, 5, 4);  // another flag, the same entity and the same draw call
    CHECK(count_runs(s.g.render(w)) == 4);
    CHECK(log.total() == 0);
}

TEST_CASE(
    "mesh buffers: a full shader reads the buffer in its vertex and fragment stage, with its own shadow program") {
    Scope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the full shader is not drawn", why);
        return;
    }
    const int id = make_buffer(s.compute(), 8);
    fill(s.compute(), id, 4);
    ErrorLog log;
    World w;
    add_camera(w, {0, 0, 4});
    Entity light = make(w, "light", {0, 5, 0});
    w.get<Transform>(light)->rotation = {-50, 30, 0};
    auto& l = w.add<Light>(light);
    l.type = LightType::Directional;
    l.castShadows = true;
    add_instanced(w, kFull, Json::object({{"points", id}}), 4);
    CHECK(count_runs(s.g.render(w)) == 4);
    CHECK(s.g.renderer.stats().shadowCasters == 1);  // the instances are in the shadow pass (one draw, 4 instances)
    CHECK(log.total() == 0);
}

TEST_CASE("mesh buffers: a snippet material casts the shadow of its instances") {
    Scope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the shadow of the instances is not drawn", why);
        return;
    }
    const int id = make_buffer(s.compute(), 8);
    fill(s.compute(), id, 5);
    ErrorLog log;
    World w;
    add_camera(w, {0, 3, 6});
    w.settings().ambientLight = Color{0.2f, 0.2f, 0.2f, 1};
    Entity light = make(w, "light", {0, 5, 0});
    w.get<Transform>(light)->rotation = {-90, 0, 0};  // straight down
    auto& l = w.add<Light>(light);
    l.type = LightType::Directional;
    l.intensity = 1.0f;
    l.castShadows = true;
    Entity ground = make(w, "ground", {0, -1, 0});
    w.get<Transform>(ground)->scale = {10, 1, 10};
    auto& gm = w.add<MeshRenderer>(ground);
    gm.mesh = "plane";
    gm.color = Color::white();
    add_instanced(w, kMesh, Json::object({{"points", id}}), 5, {0, 1, 0});
    const Image lit = s.g.render(w);
    CHECK(s.g.renderer.stats().shadowCasters == 2);  // the ground and the instanced mesh
    // Without the instances the ground is lit all over; with them, five cubes' shadows darken it: not all one value.
    float lo = 1, hi = 0;
    for (int x = 0; x < lit.width; x += 4) {
        const float v = lit.pixel(x, lit.height - 20).r;
        lo = std::min(lo, v);
        hi = std::max(hi, v);
    }
    CHECK(hi - lo > 0.05f);
    CHECK(log.total() == 0);
}

TEST_CASE("mesh buffers: instanceBounds culls by the camera, 0 never culls") {
    Scope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("culling by instanceBounds is not run", why);
        return;
    }
    const int id = make_buffer(s.compute(), 8);
    fill(s.compute(), id, 5);
    auto frame = [&](float bounds, Vec3 pos) {
        World w;
        add_camera(w, {0, 0, 4});
        Entity e = add_instanced(w, kMesh, Json::object({{"points", id}}), 5, pos);
        w.get<MeshRenderer>(e)->instanceBounds = bounds;
        s.g.render(w);
        return s.g.renderer.stats();
    };
    const auto off = frame(3.0f, {60, 0, 0});  // far off to the side, a box of 3 m
    CHECK(off.meshesCulled == 1);
    CHECK(off.meshes == 0);
    const auto never = frame(0.0f, {60, 0, 0});  // no bounds: never culled by the camera
    CHECK(never.meshesCulled == 0);
    CHECK(never.meshes == 1);
    const auto seen = frame(3.0f, {0, 0, 0});
    CHECK(seen.meshesCulled == 0);
    CHECK(seen.meshes == 1);
}

TEST_CASE("mesh buffers: a missing, destroyed or wrong buffer is a teaching error once, and the mesh is not drawn") {
    Scope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the buffer errors are not run", why);
        return;
    }
    const int id = make_buffer(s.compute(), 8);
    fill(s.compute(), id, 5);
    auto scale = s.compute().create_buffer(kScale, "items", 8);
    REQUIRE_MESSAGE(scale.ok(), scale.error().to_string());
    auto frame = [&](Json params, int instances) {
        World w;
        add_camera(w, {0, 0, 4});
        add_instanced(w, kMesh, std::move(params), instances);
        return s.g.render(w);
    };
    ErrorLog log;
    // No id at all.
    CHECK(count_runs(frame(Json::object(), 5)) == 0);
    CHECK(count_runs(frame(Json::object(), 5)) == 0);
    CHECK(log.count("/materialParams/points") == 1);  // reported once, not every frame
    CHECK(log.count("does not give its compute buffer id") == 1);
    // Not an integer.
    CHECK(count_runs(frame(Json::object({{"points", "oops"}}), 5)) == 0);
    CHECK(log.count("an integer") == 1);
    // A buffer of another shape.
    CHECK(count_runs(frame(Json::object({{"points", *scale}}), 5)) == 0);
    CHECK(log.count("another layout") == 1);
    // More instances than the buffer holds.
    CHECK(count_runs(frame(Json::object({{"points", id}}), 20)) == 0);
    CHECK(log.count("/instances") == 1);
    CHECK(log.count("holds 8 elements") == 1);
    // A destroyed buffer.
    REQUIRE(s.compute().destroy_buffer(id).ok());
    CHECK(count_runs(frame(Json::object({{"points", id}}), 5)) == 0);
    CHECK(log.count("no compute buffer") == 1);
    CHECK(s.g.renderer.stats().materialFallbacks.empty());  // the material itself is fine
}

TEST_CASE("mesh buffers: every buffer the material reads must hold one element per instance") {
    Scope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the short second buffer is not run", why);
        return;
    }
    const int points = make_buffer(s.compute(), 8);
    const int shortOne = make_buffer(s.compute(), 3);
    const int extra = make_buffer(s.compute(), 8);
    fill(s.compute(), points, 5);
    fill(s.compute(), shortOne, 3);
    fill(s.compute(), extra, 5);
    auto frame = [&](int second, int instances) {
        World w;
        add_camera(w, {0, 0, 4});
        add_instanced(w, "materials/meshbuf2.material.json", Json::object({{"points", points}, {"extra", second}}),
                      instances);
        return s.g.render(w);
    };
    ErrorLog log;
    // `points` holds 8 elements, `extra` only 3: five instances would read `extra` past its end.
    CHECK(count_runs(frame(shortOne, 5)) == 0);
    CHECK(count_runs(frame(shortOne, 5)) == 0);
    CHECK(log.count("/instances") == 1);
    CHECK(log.count("the buffer 'extra'") == 1);
    CHECK(log.count("holds 3 elements") == 1);
    CHECK(s.g.renderer.stats().meshes == 0);
    CHECK(s.g.renderer.stats().triangles == 0);
    // Three instances fit both, and so do five with a second buffer of 8.
    CHECK(count_runs(frame(shortOne, 3)) == 3);
    CHECK(count_runs(frame(extra, 5)) == 5);
    CHECK(log.count("/instances") == 1);
}

TEST_CASE("mesh buffers: two entities with the same buffer and the same params are two draws, never one batch") {
    Scope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the batch isolation is not run", why);
        return;
    }
    const int id = make_buffer(s.compute(), 8);
    fill(s.compute(), id, 3);
    World w;
    add_camera(w, {0, 0, 6});
    add_instanced(w, kMesh, Json::object({{"points", id}}), 3, {0, 1, 0});
    add_instanced(w, kMesh, Json::object({{"points", id}}), 3, {0, -1, 0});
    s.g.render(w);
    const RenderStats& st = s.g.renderer.stats();
    CHECK(st.meshes == 2);
    CHECK(st.meshBatches == 2);
    CHECK(st.drawCalls >= 2);
    CHECK(st.triangles == 2 * 3 * 12);  // two entities, three instances of a 12-triangle cube
}

TEST_CASE("mesh buffers: a driver with too few storage buffer bindings refuses the material at load and says so") {
    Scope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the binding limit is not run", why);
        return;
    }
    const int points = make_buffer(s.compute(), 8);
    const int extra = make_buffer(s.compute(), 8);
    fill(s.compute(), points, 5);
    auto draw = [&](const char* material, Json params) {
        s.g.renderer.clear_asset_cache();
        install_materials();
        World w;
        add_camera(w, {0, 0, 4});
        add_instanced(w, material, std::move(params), 5);
        return count_runs(s.g.render(w));
    };
    // A driver that offers 2 bindings: one buffer takes 2 (vertex and fragment copy), two take 4.
    ComputeTestAccess::set_binding_limit(s.compute(), 2);
    {
        ErrorLog log;
        CHECK(draw(kMesh, Json::object({{"points", points}})) == 5);
        CHECK(log.count("storage buffer bindings") == 0);
    }
    {
        ErrorLog log;
        CHECK(draw("materials/meshbuf2.material.json", Json::object({{"points", points}, {"extra", extra}})) == 0);
        CHECK(log.count("takes 4 storage buffer bindings") >= 1);
        CHECK(log.count("offers 2") >= 1);
        CHECK(log.count("Declare at most 1 buffers") >= 1);
        CHECK(s.g.renderer.stats().materialFallbacks.size() == 1);  // the error material, never a crash
    }
    ComputeTestAccess::set_binding_limit(s.compute(), 4);  // 2 buffers need 4: fine
    CHECK(draw("materials/meshbuf2.material.json", Json::object({{"points", points}, {"extra", extra}})) == 5);
    ComputeTestAccess::set_binding_limit(s.compute(), -1);
    s.g.renderer.clear_asset_cache();
}

TEST_CASE("mesh buffers: instances on a material without buffers draws nothing and says why") {
    Scope s;
    ErrorLog log;
    World w;
    add_camera(w, {0, 0, 4});
    Entity e = make(w, "plain", {0, 0, 0});
    auto& m = w.add<MeshRenderer>(e);
    m.mesh = "cube";
    m.instances = 4;
    s.g.render(w);
    s.g.render(w);
    CHECK(log.count("/instances") == 1);
    CHECK(s.g.renderer.stats().meshes == 0);
}

TEST_CASE("mesh buffers: a backend that cannot read storage buffers in a vertex shader refuses the material at load") {
    Scope s;
    using FB = render::FeatureBackend;
    for (FB backend : {FB::Gles3, FB::WebGl2}) {
        s.g.renderer.clear_asset_cache();
        install_materials();
        ComputeTestAccess::set_backend(s.compute(), int(backend));
        ErrorLog log;
        World w;
        add_camera(w, {0, 0, 4});
        add_instanced(w, kMesh, Json::object({{"points", 1}}), 4);
        s.g.render(w);
        s.g.render(w);
        CHECK(log.count(render::feature_backend_label(backend)) >= 1);
        CHECK(log.count("storage buffers") >= 1);
        CHECK(log.count("CPU path") >= 1);
        REQUIRE(s.g.renderer.stats().materialFallbacks.size() == 1);  // drawn with the error material, never a crash
        CHECK(s.g.renderer.stats().materialFallbacks[0] == kMesh);
    }
}

TEST_CASE("mesh buffers: OpenGL 4.1 (macOS: no storage buffers, no compute) refuses the material at load and says what "
          "to do") {
    Scope s;
    // The GL backend of a Linux or Windows machine has compute; the one of macOS stops at 4.1 and has none: the same
    // backend, answered as a GPU without compute (the gate of the load reads what Compute answers, ComputeTestAccess).
    ComputeTestAccess::set_backend(s.compute(), int(render::FeatureBackend::Gl));
    ComputeTestAccess::set_compute_capable(s.compute(), 0);
    s.g.renderer.clear_asset_cache();
    install_materials();
    ErrorLog log;
    World w;
    add_camera(w, {0, 0, 4});
    add_instanced(w, kMesh, Json::object({{"points", 1}}), 4);
    s.g.render(w);
    s.g.render(w);
    CHECK(log.count("the GL graphics backend") >= 1);
    CHECK(log.count("lacks compute") >= 1);
    CHECK(log.count("macOS OpenGL (4.1)") >= 1);  // the hint names it, and the CPU path
    CHECK(log.count("CPU path") >= 1);
    REQUIRE(s.g.renderer.stats().materialFallbacks.size() == 1);  // drawn with the error material, never a crash
    CHECK(s.g.renderer.stats().materialFallbacks[0] == kMesh);
    CHECK(count_runs(s.g.render(w)) == 0);
    // The same backend with compute (GL 4.3+) loads it.
    ComputeTestAccess::set_compute_capable(s.compute(), 1);
    s.g.renderer.clear_asset_cache();
    install_materials();
    s.g.render(w);
    CHECK(s.g.renderer.stats().materialFallbacks.empty());
}

TEST_CASE(
    "mesh buffers: a very large instance count reads only its buffer, never the one-matrix instance vertex buffer") {
    Scope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the large instance count is not drawn", why);
        return;
    }
    // 1 << 14 instances: with a per-instance step the attributes fa_inst_m0..3 would read 1 MB past the one matrix the
    // draw binds (any count above one already reads past it). The model is a uniform and the attributes read the first
    // 16 bytes of each vertex (Gpu set_instance_layout), so only the first five elements, the ones the compute pass
    // wrote, show; the rest are zero and collapse.
    const int big = 1 << 14;
    const int id = make_buffer(s.compute(), big);
    fill(s.compute(), id, 5);
    ErrorLog log;
    World w;
    add_camera(w, {0, 0, 4});
    add_instanced(w, kMesh, Json::object({{"points", id}}), big);
    Entity light = make(w, "light", {0, 5, 0});
    w.get<Transform>(light)->rotation = {-50, 30, 0};
    auto& l = w.add<Light>(light);
    l.type = LightType::Directional;
    l.castShadows = true;  // the same draw in the shadow pass
    CHECK(count_runs(s.g.render(w)) == 5);
    CHECK(count_runs(s.g.render(w)) == 5);
    CHECK(log.total() == 0);
}

TEST_CASE(
    "mesh buffers: an entity skipped by a buffer error is left out of the shadow pass, the prepass and the main pass") {
    Scope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the skipped entity is not run", why);
        return;
    }
    // The prepass is made when an effect that reads depth is on (forced here, as the tests of the prepass do).
    struct Force {
        Renderer& r;
        explicit Force(Renderer& rr) : r(rr) { render::renderer_force_post_effects(r, 1u << int(PostEffect::Ssao)); }
        ~Force() { render::renderer_force_post_effects(r, 0); }
    } force(s.g.renderer);
    auto build = [&](World& w, bool withBroken) {
        add_camera(w, {0, 0, 4});
        Entity light = make(w, "light", {0, 5, 0});
        w.get<Transform>(light)->rotation = {-50, 30, 0};
        auto& l = w.add<Light>(light);
        l.type = LightType::Directional;
        l.castShadows = true;
        Entity cube = make(w, "cube", {0, 1.2f, 0});
        auto& m = w.add<MeshRenderer>(cube);
        m.mesh = "cube";
        if (withBroken) add_instanced(w, kMesh, Json::object(), 5);  // no buffer id: the entity cannot be drawn
    };
    ErrorLog log;
    World plain;
    build(plain, false);
    s.g.render(plain);
    const RenderStats base = s.g.renderer.stats();
    World broken;
    build(broken, true);
    const Image img = s.g.render(broken);
    s.g.render(broken);
    const RenderStats stats = s.g.renderer.stats();
    CHECK(count_runs(img) == 0);
    CHECK(stats.drawCalls == base.drawCalls);              // not one draw in any pass for the broken entity
    CHECK(stats.shadowCasters == base.shadowCasters + 1);  // counted as a caster, but skipped by the draw
    CHECK(log.count("/materialParams/points") == 1);  // the three passes report it once, not once per pass or frame
    CHECK(stats.materialFallbacks.empty());
}

TEST_CASE("mesh buffers: a skinned mesh (Animator) with a buffers material draws its instances, posed") {
    Scope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the skinned instances are not drawn", why);
        return;
    }
    std::ifstream in(std::string(FA_REPO_ROOT) + "/engine/render/tests/data/skinned_two_bone.gltf", std::ios::binary);
    std::string text((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    REQUIRE(fs::write_text("assets/rig_buffers.gltf", text).ok());
    const int id = make_buffer(s.compute(), 8);
    fill(s.compute(), id, 3);
    ErrorLog log;
    World w;
    add_camera(w, {1, 1, 6});
    Entity rig = make(w, "rig", {0, 0, 0});
    auto& m = w.add<MeshRenderer>(rig);
    m.mesh = "assets/rig_buffers.gltf";
    m.color = Color::black();
    m.material = kMesh;
    m.materialParams = Json::object({{"points", id}});
    m.instances = 3;
    w.add<Animator>(rig).clip = "Bend";
    Entity light = make(w, "light", {0, 5, 0});  // the skinned instances are also drawn in the shadow pass
    w.get<Transform>(light)->rotation = {-50, 30, 0};
    auto& l = w.add<Light>(light);
    l.type = LightType::Directional;
    l.castShadows = true;
    update_animators(w, 0.0f);
    update_animators(w, 0.5f);
    const Image img = s.g.render(w);
    int red = 0;
    for (int y = 0; y < img.height; y += 2)
        for (int x = 0; x < img.width; x += 2) red += is_red(img.pixel(x, y)) ? 1 : 0;
    CHECK(red > 50);  // the posed rig is drawn in the colour the buffer gives
    CHECK(s.g.renderer.stats().meshes == 1);
    CHECK(log.total() == 0);
    CHECK(s.g.renderer.stats().materialFallbacks.empty());
}

// The layout of the pipelines of a buffers material, with no draw: the instance attributes read the mesh's own vertex
// buffer, so buffer 0 must be laid out as a MeshVertex (stride 52: position 0, normal 12, texcoord0 24, tangent 32,
// color 48) and the four attributes must stay inside it, in the shadow, prepass and main pipelines, skinned or not.
TEST_CASE("mesh buffers: the pipelines of a buffers material lay out the mesh vertex buffer as a MeshVertex") {
    Scope s;
    render::Gpu& gpu = *render::renderer_gpu(s.g.renderer);
    render::TargetFormat format;
    format.color = gpu::PixelFormat::Rgba8;
    format.depth = gpu::PixelFormat::Depth;
    sg_shader custom{};
    custom.id = 1;  // any program: the probe makes no pipeline
    render::MeshExtras extras;
    extras.bufferInst = true;
    struct Probe {
        render::Gpu& g;
        explicit Probe(render::Gpu& gg) : g(gg) { g.set_layout_probe(true); }
        ~Probe() { g.set_layout_probe(false); }
    } probe(gpu);
    // `vertex` = the attributes of buffer 0 that are not the instance matrix, in location order (MeshVertex order).
    auto check = [&](const char* what, int firstInst, const std::vector<int>& vertex) {
        INFO(what);
        const fa::gpu::VertexLayout& lay = gpu.probed_layout();
        CHECK(lay.buffers[0].stride == 52);
        const int expected[5] = {0, 12, 24, 32, 48};
        for (std::size_t i = 0; i < vertex.size(); ++i) {
            CHECK(lay.attrs[vertex[i]].bufferIndex == 0);
            CHECK(lay.attrs[vertex[i]].offset == expected[i]);
        }
        bool anyOffset = false;
        for (int i = 0; i < 4; ++i) {
            const fa::gpu::VertexAttr& a = lay.attrs[firstInst + i];
            CHECK(a.format == fa::gpu::VertexFormat::Float4);
            CHECK(a.bufferIndex == 0);
            CHECK(a.offset + 16 <= lay.buffers[0].stride);  // inside the vertex, so inside the buffer
            anyOffset = anyOffset || a.offset != 0;
        }
        CHECK(anyOffset);  // all zero would make sokol_gfx pack the buffer itself
        CHECK(lay.buffers[1].stride == 0);
    };
    for (bool skinned : {false, true}) {
        INFO((skinned ? "skinned" : "static"));
        (void)gpu.mesh_pipeline(format, false, false, skinned, custom, extras);
        check("main", 5, {0, 1, 2, 3, 4});
        render::MaterialPassState state;
        (void)gpu.full_pipeline(format, state, skinned, custom, extras);
        check("full", 5, {0, 1, 2, 3, 4});
        (void)gpu.prepass_pipeline(format, false, skinned, custom, extras);
        check("prepass", 5, {0, 1, 2, 3, 4});
        // Shadow: position, the matrix at 1..4, then (skinned) joints and weights at 5 and 6, then the rest of the
        // vertex.
        (void)gpu.shadow_pipeline(format, skinned, custom, true, extras);
        check("shadow, full vertex", 1, skinned ? std::vector<int>{0, 7, 8, 9, 10} : std::vector<int>{0, 5, 6, 7, 8});
        (void)gpu.shadow_pipeline(format, skinned, custom, false, extras);
        check("shadow, position only", 1, {0});
    }
    // Without "buffers" the matrix comes from vertex buffer 1, one per instance.
    (void)gpu.mesh_pipeline(format, false, false, false, custom, render::MeshExtras{});
    CHECK(gpu.probed_layout().buffers[1].stride == 64);
    CHECK(gpu.probed_layout().attrs[5].bufferIndex == 1);
}
