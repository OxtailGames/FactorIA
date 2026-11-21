// M73-P3e: the sky's diffuse ambient is nine spherical-harmonics coefficients (src/renderer_env.h, shaders/env.glsl fs_sh,
// shaders/mesh_common.glsl fa_ambient_light), no irradiance cube. The tests draw a sphere with a material whose ambient() returns the
// ambient light toward the normal as it is (data/materials/ambprobe), and compare it with the sky as the camera sees it:
//   - the truth: the sky seen from the origin through 24 views, every pixel one direction with its solid angle (so the same sky the
//     environment was baked from, 8-bit like every picture of these tests);
//   - the brute force: the cosine-weighted sum of that truth toward the normal, divided by pi, which is what the 8 x 8 irradiance cube
//     of the earlier milestones held;
//   - the CPU reference: the same truth projected onto the nine coefficients with sh_basis (fa/scene/lightmap_bake.h) and evaluated
//     with sh_irradiance, the math the shader uses.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <fstream>
#include <functional>
#include <iterator>
#include <string>
#include <vector>

#include "fa/core/engine_version.h"
#include "fa/core/image_float.h"
#include "fa/scene/lightmap_bake.h"
#include "render_internal.h"
#include "renderer_env.h"

using namespace fa;
using namespace fa::test;
using namespace fa::render;

namespace {

constexpr double kPi = 3.14159265358979323846;

// The fixture materials of tests/data/materials are copied into the test project (as the other material tests do).
void install_materials() {
    namespace sfs = std::filesystem;
    const sfs::path src = sfs::path(FA_RENDER_DATA_DIR) / "materials";
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

struct MaterialScope {
    MaterialScope() {
        gfx().renderer.clear_asset_cache();
        install_materials();
    }
    ~MaterialScope() {
        gfx().renderer.set_shader_compiler({});
        gfx().renderer.clear_asset_cache();
    }
};

// A renderer of its own (an Environment of its own), sharing the GPU of the fixture.
struct OwnRenderer {
    Gfx& g;
    Renderer r;
    bool ok = false;
    std::string error;
    explicit OwnRenderer(Gfx& gx) : g(gx) {
        RendererDesc d;
        d.designWidth = 320;
        d.designHeight = 180;
        d.sampleCount = 1;
        d.headless = true;
        d.adoptContext = true;
        ok = r.init(d, g.gpu.environment(), &error);
    }
    ~OwnRenderer() { r.shutdown(); }
    OwnRenderer(const OwnRenderer&) = delete;
    OwnRenderer& operator=(const OwnRenderer&) = delete;
    Image draw(World& w) {
        r.begin_frame();
        r.render_world(w, 0.0f);
        r.end_frame();
        g.gpu.end_frame();
        Image img;
        std::string err;
        const bool captured = r.capture(img, &err);
        INFO("capture error: " << err);
        REQUIRE(captured);
        return img;
    }
};

struct Basis {
    Vec3 f, r, u;
};

// The camera frame of Transform.rotation = {pitch, yaw, 0}: forward is -Z turned by the pitch, then by the yaw about Y.
Basis frame_of(float pitchDeg, float yawDeg) {
    const double p = pitchDeg * kPi / 180.0, y = yawDeg * kPi / 180.0;
    Basis b;
    b.f = {float(-std::sin(y) * std::cos(p)), float(std::sin(p)), float(-std::cos(y) * std::cos(p))};
    b.r = {float(std::cos(y)), 0.0f, float(-std::sin(y))};
    b.u = cross(b.r, b.f);
    return b;
}

Entity add_camera_at(World& w, Vec3 pos, float pitchDeg, float yawDeg, float fov) {
    Entity cam = make(w, "cam", pos);
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = fov;
    w.get<Transform>(cam)->rotation = {pitchDeg, yawDeg, 0};
    return cam;
}

// The sky the environment is baked from, sampled from the picture: directions, linear-in-the-scene colours, solid angles.
struct SkySamples {
    std::vector<Vec3> dir;
    std::vector<Vec3> rgb;
    std::vector<double> weight;
    double total = 0.0;
};

using Setup = std::function<void(World&)>;

SkySamples sample_sky(Gfx& g, const Setup& setup) {
    struct View {
        float pitch, yaw;
    };
    std::vector<View> views;
    for (float pitch : {0.0f, 60.0f, -60.0f})
        for (int k = 0; k < 8; ++k) views.push_back({pitch, 45.0f * float(k)});
    std::vector<Basis> bases;
    for (const View& v : views) bases.push_back(frame_of(v.pitch, v.yaw));
    const float fov = 90.0f;
    const int stride = 2;
    SkySamples out;
    for (std::size_t vi = 0; vi < views.size(); ++vi) {
        World w;
        add_camera_at(w, {0, 0, 0}, views[vi].pitch, views[vi].yaw, fov);
        setup(w);
        const Image img = g.render(w);
        const double aspect = double(img.width) / img.height;
        const double dx = 2.0 * aspect * stride / img.width, dy = 2.0 * stride / img.height;
        for (int py = 0; py < img.height; py += stride)
            for (int px = 0; px < img.width; px += stride) {
                const double x = (2.0 * (px + 0.5) / img.width - 1.0) * aspect, y = 1.0 - 2.0 * (py + 0.5) / img.height;
                const Basis& b = bases[vi];
                Vec3 d{float(b.f.x + x * b.r.x + y * b.u.x), float(b.f.y + x * b.r.y + y * b.u.y),
                       float(b.f.z + x * b.r.z + y * b.u.z)};
                d = normalize(d);
                // How many views see this direction (the views overlap): each takes its share.
                int seen = 0;
                for (const Basis& o : bases) {
                    const double depth = d.x * o.f.x + d.y * o.f.y + d.z * o.f.z;
                    if (depth <= 1e-6) continue;
                    const double ox = (d.x * o.r.x + d.y * o.r.y + d.z * o.r.z) / depth;
                    const double oy = (d.x * o.u.x + d.y * o.u.y + d.z * o.u.z) / depth;
                    if (std::fabs(ox) <= aspect && std::fabs(oy) <= 1.0) ++seen;
                }
                const double solid = dx * dy / std::pow(1.0 + x * x + y * y, 1.5);
                const Color c = img.pixel(px, py);
                out.dir.push_back(d);
                out.rgb.push_back({c.r, c.g, c.b});
                out.weight.push_back(solid / std::max(1, seen));
                out.total += out.weight.back();
            }
    }
    return out;
}

// The irradiance toward n divided by pi, summed over the picture: what the 8 x 8 irradiance cube held.
Vec3 brute_force(const SkySamples& s, Vec3 n) {
    double sum[3] = {};
    for (std::size_t i = 0; i < s.dir.size(); ++i) {
        const double cosine = std::max(0.0, double(s.dir[i].x * n.x + s.dir[i].y * n.y + s.dir[i].z * n.z));
        if (cosine <= 0.0) continue;
        sum[0] += s.rgb[i].x * cosine * s.weight[i];
        sum[1] += s.rgb[i].y * cosine * s.weight[i];
        sum[2] += s.rgb[i].z * cosine * s.weight[i];
    }
    return {float(sum[0] / kPi), float(sum[1] / kPi), float(sum[2] / kPi)};
}

// The nine coefficients of the picture (the CPU twin of the pass in env.glsl) and what they give toward n, never below 0 like the shader.
ShL2 project(const SkySamples& s) {
    double sum[9][3] = {};
    for (std::size_t i = 0; i < s.dir.size(); ++i) {
        float y[9];
        sh_basis(s.dir[i], y);
        for (int k = 0; k < 9; ++k) {
            sum[k][0] += s.rgb[i].x * y[k] * s.weight[i];
            sum[k][1] += s.rgb[i].y * y[k] * s.weight[i];
            sum[k][2] += s.rgb[i].z * y[k] * s.weight[i];
        }
    }
    ShL2 sh;
    for (int k = 0; k < 9; ++k) sh.c[k] = {float(sum[k][0]), float(sum[k][1]), float(sum[k][2])};
    return sh;
}

Vec3 sh_clamped(const ShL2& sh, Vec3 n) {
    const Vec3 e = sh_irradiance(sh, n);
    return {std::max(e.x, 0.0f), std::max(e.y, 0.0f), std::max(e.z, 0.0f)};
}

// The six axes and the eight corners of a cube.
std::vector<Vec3> probe_normals() {
    std::vector<Vec3> out = {{1, 0, 0}, {-1, 0, 0}, {0, 1, 0}, {0, -1, 0}, {0, 0, 1}, {0, 0, -1}};
    for (int x = -1; x <= 1; x += 2)
        for (int y = -1; y <= 1; y += 2)
            for (int z = -1; z <= 1; z += 2) {
                const float l = std::sqrt(3.0f);
                out.push_back({x / l, y / l, z / l});
            }
    return out;
}

// What the GPU gives for a surface that faces n: the centre pixel of a sphere seen from the direction n with the probe material.
Vec3 gpu_ambient(const std::function<Image(World&)>& draw, const Setup& setup, Vec3 n) {
    World w;
    const float pitch = float(std::asin(std::clamp(double(-n.y), -1.0, 1.0)) * 180.0 / kPi);
    const float yaw = float(std::atan2(double(n.x), double(n.z)) * 180.0 / kPi);
    add_camera_at(w, {4 * n.x, 4 * n.y, 4 * n.z}, pitch, yaw, 40.0f);
    setup(w);
    Entity s = make(w, "probe", {0, 0, 0});
    w.get<Transform>(s)->scale = {2.4f, 2.4f, 2.4f};
    auto& m = w.add<MeshRenderer>(s);
    m.mesh = "sphere";
    m.material = "materials/ambprobe.material.json";
    const Image img = draw(w);
    const Color c = img.pixel(img.width / 2, img.height / 2);
    return {c.r, c.g, c.b};
}

struct Errors {
    double mean = 0.0, worst = 0.0;
};

double mean_abs(Vec3 a, Vec3 b) { return (std::fabs(a.x - b.x) + std::fabs(a.y - b.y) + std::fabs(a.z - b.z)) / 3.0; }

struct Report {
    Errors gpuVsBrute, gpuVsCpu, cpuVsBrute;
    SkySamples sky;
};

// Draws the sky of `setup`, the sphere toward each probe normal, and measures the three differences.
Report compare(Gfx& g, const Setup& setup) {
    Report r;
    r.sky = sample_sky(g, setup);
    const ShL2 sh = project(r.sky);
    const std::vector<Vec3> normals = probe_normals();
    for (const Vec3& n : normals) {
        const Vec3 gpu = gpu_ambient([&](World& w) { return g.render(w); }, setup, n);
        const Vec3 brute = brute_force(r.sky, n), cpu = sh_clamped(sh, n);
        const double a = mean_abs(gpu, brute), b = mean_abs(gpu, cpu), c = mean_abs(cpu, brute);
        r.gpuVsBrute.mean += a / normals.size();
        r.gpuVsCpu.mean += b / normals.size();
        r.cpuVsBrute.mean += c / normals.size();
        r.gpuVsBrute.worst = std::max(r.gpuVsBrute.worst, a);
        r.gpuVsCpu.worst = std::max(r.gpuVsCpu.worst, b);
        r.cpuVsBrute.worst = std::max(r.cpuVsBrute.worst, c);
    }
    return r;
}

void report_and_check(const char* name, const Report& r, double bruteMean, double bruteWorst, double cpuMean,
                      double cpuWorst) {
    MESSAGE(std::string(name) << ": GPU vs brute force mean " << r.gpuVsBrute.mean << " worst " << r.gpuVsBrute.worst
                              << "; GPU vs CPU SH mean " << r.gpuVsCpu.mean << " worst " << r.gpuVsCpu.worst
                              << "; CPU SH vs brute force mean " << r.cpuVsBrute.mean << " worst " << r.cpuVsBrute.worst
                              << " (colour 0..1)");
    CHECK(std::fabs(r.sky.total - 4.0 * kPi) <
          0.04 * 4.0 * kPi);  // the 24 views cover the sphere once, the weights add up to 4 pi
    CHECK(r.gpuVsBrute.mean < bruteMean);
    CHECK(r.gpuVsBrute.worst < bruteWorst);
    CHECK(r.gpuVsCpu.mean < cpuMean);
    CHECK(r.gpuVsCpu.worst < cpuWorst);
}

Setup gradient_sky() {
    return [](World& w) {
        w.settings().ambientLight = Color{0, 0, 0, 1};
        w.settings().skyMaterial = "materials/skygrad.material.json";
        w.settings().skyMaterialParams = Json::object(
            {{"zenith", Json::array({0.15, 0.35, 0.9, 1.0})}, {"ground", Json::array({0.7, 0.45, 0.2, 1.0})}});
    };
}

Setup physical_sky() {
    return [](World& w) {
        w.settings().ambientLight = Color{0, 0, 0, 1};
        w.settings().skyModel = SkyModel::Physical;
        Entity sun = make(w, "sun", {0, 5, 0});
        auto& l = w.add<Light>(sun);
        l.type = LightType::Directional;
        l.intensity = 1.0f;
        l.castShadows = false;
        w.get<Transform>(sun)->rotation = {-35.0f, 200.0f, 0};
    };
}

// A small equirect picture, nothing above 1 (the pictures of these tests are 8-bit): blue above, brown below, a green quarter and
// a bright patch of sun.
std::vector<std::uint8_t> test_hdri() {
    ImageF img = ImageF::create(32, 16, 3).value();
    for (int y = 0; y < 16; ++y)
        for (int x = 0; x < 32; ++x) {
            Vec3 c = y < 8 ? Vec3{0.15f, 0.35f, 0.9f} : Vec3{0.3f, 0.2f, 0.1f};
            if (x >= 16 && x < 24 && y >= 4 && y < 12) c = {0.1f, 0.6f, 0.15f};
            if (x >= 6 && x < 9 && y >= 2 && y < 5) c = {0.95f, 0.85f, 0.6f};
            float* p = img.at(x, y);
            p[0] = c.x;
            p[1] = c.y;
            p[2] = c.z;
        }
    return encode_hdr(img);
}

Setup hdri_sky() {
    return [](World& w) {
        w.settings().ambientLight = Color{0, 0, 0, 1};
        w.settings().environmentMap = "assets/env_sh_sky.hdr";
    };
}

}  // namespace

TEST_CASE("sky SH on the GPU: a gradient sky material lights a diffuse surface like the cosine integral of the sky") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    const Report r = compare(g, gradient_sky());
    report_and_check("gradient", r, 0.006, 0.012, 0.006, 0.012);
}

TEST_CASE("sky SH on the GPU: the physical sky lights a diffuse surface like the cosine integral of the sky") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("physicalSky")) {
        MESSAGE("physicalSky is not supported on this GPU: not run");
        return;
    }
    MaterialScope scope;
    const Report r = compare(g, physical_sky());
    report_and_check("physical sky", r, 0.01, 0.02, 0.01, 0.02);
}

TEST_CASE("sky SH on the GPU: an HDRI lights a diffuse surface like the cosine integral of the sky") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("environmentMap")) {
        MESSAGE("environmentMap is not supported on this GPU: not run");
        return;
    }
    MaterialScope scope;
    const std::vector<std::uint8_t> bytes = test_hdri();
    REQUIRE(fs::write_bytes("assets/env_sh_sky.hdr", bytes.data(), bytes.size()).ok());
    const Report r = compare(g, hdri_sky());
    report_and_check("HDRI", r, 0.01, 0.02, 0.01, 0.02);
}

TEST_CASE("sky SH on the GPU: the baked SH is the same on an RGBA8 environment, and the sky is baked once") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    const Setup setup = gradient_sky();
    struct Force {
        Force() { Environment::force_rgba8_for_tests(true); }
        ~Force() { Environment::force_rgba8_for_tests(false); }
    };
    // The reference: the half-float environment of the fixture's renderer. A frame of the probe, three times: the first bakes the
    // sky (kEnvPasses draws), the next two are the same frame without them.
    auto frame_calls = [&](World& w) {
        g.render(w);
        return g.renderer.stats().drawCalls;
    };
    World probe;
    add_camera_at(probe, {0, 0, 4}, 0, 0, 40.0f);
    setup(probe);
    Entity s = make(probe, "probe", {0, 0, 0});
    probe.get<Transform>(s)->scale = {2.4f, 2.4f, 2.4f};
    auto& m = probe.add<MeshRenderer>(s);
    m.mesh = "sphere";
    m.material = "materials/ambprobe.material.json";
    const int first = frame_calls(probe), second = frame_calls(probe), third = frame_calls(probe);
    CHECK(first >= second + kEnvPasses);  // the first frame baked the sky, kEnvPasses draws of it
    CHECK(second == third);               // the SH is not baked again while the sky stays what it was

    std::vector<Vec3> reference;
    for (const Vec3& n : probe_normals())
        reference.push_back(gpu_ambient([&](World& w) { return g.render(w); }, setup, n));
    Force force;
    OwnRenderer own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    double worst = 0.0;
    std::size_t i = 0;
    for (const Vec3& n : probe_normals()) {
        const Vec3 rgba8 = gpu_ambient([&](World& w) { return own.draw(w); }, setup, n);
        worst = std::max(worst, mean_abs(rgba8, reference[i++]));
    }
    MESSAGE("RGBA8 environment against half-float, worst mean difference " << worst << " (colour 0..1)");
    CHECK(worst < 0.03);
}

TEST_CASE("sky SH on the GPU: a black sky reads back exactly zero on an RGBA8 environment") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    MaterialScope scope;
    // Zero is the byte 128 of the encoding (clamp(c / 4, -1, 1) * 127 / 255 + 128 / 255), so a sky with no light does not tint the ambient.
    const Setup black = [](World& w) {
        w.settings().ambientLight = Color{0, 0, 0, 1};
        w.settings().skyMaterial = "materials/skygrad.material.json";
        w.settings().skyMaterialParams = Json::object(
            {{"zenith", Json::array({0.0, 0.0, 0.0, 1.0})}, {"ground", Json::array({0.0, 0.0, 0.0, 1.0})}});
    };
    struct Force {
        Force() { Environment::force_rgba8_for_tests(true); }
        ~Force() { Environment::force_rgba8_for_tests(false); }
    };
    Force force;
    OwnRenderer own(g);
    REQUIRE_MESSAGE(own.ok, own.error);
    double worst = 0.0;
    for (const Vec3& n : probe_normals()) {
        const Vec3 c = gpu_ambient([&](World& w) { return own.draw(w); }, black, n);
        worst = std::max({worst, double(c.x), double(c.y), double(c.z)});
    }
    CHECK(worst == 0.0);
}

TEST_CASE("sky SH on the GPU: the shaders hold the nine coefficients in highp on GLES3 and WebGL2") {
    // The environment's own fragment shader: every declaration is highp (a mobile GPU's mediump is fp16, and the sum of a thousand
    // taps of a sky of 60000 overflows it).
    const std::string env = glsl_source_from_header("env.glsl.h", "env_fs_sh_source_glsl300es[");
    REQUIRE(!env.empty());
    CHECK(env.find("highp") != std::string::npos);
    const std::vector<std::string> bad = unqualified_floats(env);
    for (const std::string& l : bad) MESSAGE("not highp: " << l);
    CHECK(bad.empty());
    // The mesh fragment shader's three functions of the ambient: the coefficients read back, the sum and the evaluation.
    const std::string mesh = glsl_source_from_header("mesh.glsl.h", "mesh_fs_source_glsl300es[");
    REQUIRE(!mesh.empty());
    for (const char* fn : {"fa_sh_eval(", "fa_probe_sh_coef(", "fa_ambient_light("}) {
        CAPTURE(fn);
        const std::size_t at = mesh.find(std::string("highp vec3 ") + fn);
        REQUIRE(at != std::string::npos);
        const std::size_t end = mesh.find("\n}\n", at);
        REQUIRE(end != std::string::npos);
        const std::string body = mesh.substr(at, end - at);
        const std::vector<std::string> inside = unqualified_floats(body);
        for (const std::string& l : inside) MESSAGE("not highp: " << l);
        CHECK(inside.empty());
    }
}
