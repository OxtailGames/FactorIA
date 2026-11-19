// Meshes drawn from compute buffers (M72.4, docs/shaders/SHADERS_COMPUTE.md "Drawing from a compute buffer"): a compute material writes
// the instances, a mesh material with "buffers" reads them in vertex() and surface(), MeshRenderer.instances is the count. The
// fixtures are tests/data/materials/materials/meshbuf*.material.json (twins made by tools/common/tests/shaders_fixtures_test.cpp).
// What needs storage buffers in a vertex shader (Metal, D3D11, GL 4.3+) says "SKIPPED, no compute here" elsewhere
// (FA_REQUIRE_COMPUTE=1 turns that into a failure on a runner that must have it).
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

#include "compute_internal.h"
#include "render_features.h"

using namespace fa;
using namespace fa::test;

namespace {

const char* const kFill = "materials/meshbuf_fill.material.json";
const char* const kMesh = "materials/meshbuf.material.json";
const char* const kFull = "materials/full_meshbuf.material.json";
const char* const kScale = "materials/scale.material.json";

void install_materials() {
    namespace sfs = std::filesystem;
    const sfs::path src = fs::path_from_utf8(FA_RENDER_DATA_DIR) / "materials";
    for (const auto& e : sfs::recursive_directory_iterator(src)) {
        if (!e.is_regular_file()) continue;
        std::ifstream in(e.path(), std::ios::binary);
        std::string bytes((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
        if (e.path().extension() == ".shader") {
            Json twin = Json::parse(bytes);
            twin["engine"] = FA_ENGINE_VERSION;
            bytes = twin.dump();
        }
        REQUIRE(fs::write_bytes(sfs::relative(e.path(), src).generic_string(), bytes.data(), bytes.size()).ok());
    }
}

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

// The number of red runs along the picture's middle row (one per instance drawn there, 1 unit = ~40 px apart, ~20 px wide).
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

// Writes `count` instances into a buffer of `size` elements, in a row 1 unit apart centred on element 2; element `hide` hidden.
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
