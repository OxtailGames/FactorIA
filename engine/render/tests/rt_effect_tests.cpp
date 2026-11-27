// M79-P2a-1: the shared pass of the ray traced effects and the hard shadows (src/rt_effect.h, shaders/rt/rt_shadow.{hlsl,metal};
// docs/design/ARCHITECTURE_RT_EFFECTS.md). Here, on every host: the camera as rays (the formula the kernels rebuild a pixel's world position
// with, against the projection), the constants block and the binding contract shared by the HLSL and the MSL, and the renderer's frame on the
// RecordingDevice (nothing when off, one compute pass when on, one message and the raster frame on a device that cannot trace). The kernel
// itself runs for real in rt_shadow_metal_tests.cpp.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <fstream>
#include <iterator>
#include <memory>
#include <mutex>
#include <set>
#include <sstream>
#include <string>
#include <vector>

#include "fa/core/log.h"
#include "fa/scene/camera_geometry.h"
#include "fa/scene/components.h"
#include "gpu/recording_device.h"
#include "renderer_test_access.h"
#include "rt_denoise.h"
#include "rt_effect.h"
#include "rt_scene.h"

using namespace fa;
using namespace fa::test;
using fa::render::RtEffectParams;
using fa::render::RtEffects;

namespace {

struct Logs {
    struct Lines {
        std::mutex mu;
        std::vector<std::string> lines;
    };
    std::shared_ptr<Lines> shared = std::make_shared<Lines>();
    int id;
    Logs()
        : id(add_log_sink([l = shared](const LogEntry& e) {
              if (e.level < LogLevel::Info) return;
              std::lock_guard<std::mutex> lk(l->mu);
              l->lines.push_back(e.message);
          })) {}
    ~Logs() { remove_log_sink(id); }
    Logs(const Logs&) = delete;
    Logs& operator=(const Logs&) = delete;
    int count(const std::string& needle) const {
        std::lock_guard<std::mutex> lk(shared->mu);
        return int(std::count_if(shared->lines.begin(), shared->lines.end(),
                                 [&](const std::string& x) { return x.find(needle) != std::string::npos; }));
    }
};

std::string read_repo_file(const std::string& relative) {
    std::ifstream in(std::string(FA_REPO_ROOT) + "/" + relative, std::ios::binary);
    return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
}

// ---- the camera as rays ------------------------------------------------------------------------------------------------------------

CameraGeometry make_camera(bool perspective, bool zeroToOne) {
    World w;
    Entity cam = make(w, "cam", {1.5f, 2.0f, 9.0f});
    w.get<Transform>(cam)->rotation = {-12.0f, 17.0f, 0.0f};
    auto& c = w.add<Camera>(cam);
    c.projection = perspective ? Projection::Perspective : Projection::Orthographic;
    c.fov = 63.0f;
    c.nearPlane = 0.2f;
    c.farPlane = 400.0f;
    c.orthoSize = 6.0f;
    CameraTarget target;
    target.width = target.designWidth = 160;
    target.height = target.designHeight = 96;
    target.zeroToOne = zeroToOne;
    std::string warned;
    CameraGeometry g = camera_geometry(w, cam, target, warned);
    REQUIRE(g.entity == cam);
    return g;
}

// The world position the kernels rebuild for pixel (x, y) at linear view depth `depth` (the formula of RtEffectParams).
Vec3 rebuild(const float* o0, const float* ox, const float* oy, const float* d0, const float* dx, const float* dy,
             int w, int h, int x, int y, float depth) {
    const double nx = (double(x) + 0.5) * 2.0 / w - 1.0, ny = 1.0 - (double(y) + 0.5) * 2.0 / h;
    Vec3 p;
    p.x = float(o0[0] + nx * ox[0] + ny * oy[0] + (d0[0] + nx * dx[0] + ny * dy[0]) * depth);
    p.y = float(o0[1] + nx * ox[1] + ny * oy[1] + (d0[1] + nx * dx[1] + ny * dy[1]) * depth);
    p.z = float(o0[2] + nx * ox[2] + ny * oy[2] + (d0[2] + nx * dx[2] + ny * dy[2]) * depth);
    return p;
}

void check_rays(const CameraGeometry& cam, const Mat4& viewProj, const float* o0, const float* ox, const float* oy,
                const float* d0, const float* dx, const float* dy, int w, int h, bool zeroToOne) {
    const int xs[] = {0, w - 1, w / 2, w / 3, 5};
    const int ys[] = {0, h - 1, h / 2, h / 4, 70};
    for (int i = 0; i < 5; ++i) {
        for (float depth : {0.5f, 7.0f, 120.0f}) {
            CAPTURE(xs[i]);
            CAPTURE(ys[i]);
            CAPTURE(depth);
            const Vec3 p = rebuild(o0, ox, oy, d0, dx, dy, w, h, xs[i], ys[i], depth);
            // The linear view depth along the camera's forward axis is the depth we put in.
            CHECK(dot(cam.forward, p - cam.position) == doctest::Approx(depth).epsilon(1e-4));
            // Projecting the point lands on the pixel's centre (and inside the depth range of the backend).
            const Vec4 clip = viewProj * Vec4{p, 1.0f};
            REQUIRE(clip.w > 0.0f);
            const double ndcX = double(clip.x) / clip.w, ndcY = double(clip.y) / clip.w;
            CHECK(std::fabs(ndcX - ((double(xs[i]) + 0.5) * 2.0 / w - 1.0)) < 2e-4);
            CHECK(std::fabs(ndcY - (1.0 - (double(ys[i]) + 0.5) * 2.0 / h)) < 2e-4);
            const double z = double(clip.z) / clip.w;
            CHECK(z >= (zeroToOne ? -1e-4 : -1.0001));
            CHECK(z <= 1.0001);
        }
    }
}

}  // namespace

TEST_CASE("rt effect: the rays rebuild a pixel's world position from the linear depth, perspective and orthographic, "
          "both depth ranges") {
    for (bool perspective : {true, false}) {
        for (bool zeroToOne : {false, true}) {
            INFO("perspective " << perspective << " zeroToOne " << zeroToOne);
            const CameraGeometry cam = make_camera(perspective, zeroToOne);
            RtEffectParams p{};
            fill_rt_effect_camera(p, cam, 160, 96, zeroToOne);
            CHECK(p.camera[0] == doctest::Approx(1.5f));
            CHECK(p.camera[3] == (perspective ? 0.0f : 1.0f));
            CHECK(p.image[0] == 160.0f);
            CHECK(p.image[1] == 96.0f);
            CHECK(p.image[2] == doctest::Approx(1.0f / 160.0f));
            CHECK(p.image[3] == doctest::Approx(1.0f / 96.0f));
            check_rays(cam, cam.viewProj, p.rayO0, p.rayOX, p.rayOY, p.rayD0, p.rayDX, p.rayDY, 160, 96, zeroToOne);
            check_rays(cam, cam.viewProj, p.uRayO0, p.uRayOX, p.uRayOY, p.uRayD0, p.uRayDX, p.uRayDY, 160, 96,
                       zeroToOne);
            // The view's axes: a view-space normal (x, y, z) is right x + up y + back z.
            CHECK(p.viewBack[0] == doctest::Approx(-cam.forward.x));
            CHECK(p.viewRight[1] == doctest::Approx(cam.right.y));
            CHECK(p.viewUp[2] == doctest::Approx(cam.up.z));
            // The rows of the unjittered view-projection matrix.
            CHECK(p.viewProj3[2] == doctest::Approx(cam.viewProj.at(2, 3)));
            CHECK(p.viewProj0[0] == doctest::Approx(cam.viewProj.at(0, 0)));
        }
    }
}

TEST_CASE(
    "rt effect: a jittered camera's rays follow the matrix the prepass was drawn with; the unjittered ones stay") {
    for (bool zeroToOne : {false, true}) {
        CameraGeometry cam = make_camera(true, zeroToOne);
        cam.apply_jitter({0.31f, -0.22f}, 160.0f, 96.0f);
        RtEffectParams p{};
        fill_rt_effect_camera(p, cam, 160, 96, zeroToOne);
        check_rays(cam, cam.drawViewProj, p.rayO0, p.rayOX, p.rayOY, p.rayD0, p.rayDX, p.rayDY, 160, 96, zeroToOne);
        check_rays(cam, cam.viewProj, p.uRayO0, p.uRayOX, p.uRayOY, p.uRayD0, p.uRayDX, p.uRayDY, 160, 96, zeroToOne);
        // The two differ (the jitter moved the image by a third of a pixel).
        CHECK(std::fabs(p.rayD0[0] - p.uRayD0[0]) + std::fabs(p.rayD0[1] - p.uRayD0[1]) +
                  std::fabs(p.rayD0[2] - p.uRayD0[2]) >
              1e-6f);
    }
}

TEST_CASE("rt effect: the seed of a frame is a pure function of the frame serial") {
    CHECK(fa::render::rt_effect_seed(7) == fa::render::rt_effect_seed(7));
    std::set<std::uint32_t> seen;
    for (std::uint64_t serial = 0; serial < 64; ++serial) seen.insert(fa::render::rt_effect_seed(serial));
    CHECK(seen.size() == 64);
}

// ---- the contract shared by the HLSL, the MSL and the renderer -------------------------------------------------------------------------

namespace {

// The field names between `// BEGIN <name>` and `// END <name>` of a kernel source, in order.
std::vector<std::string> struct_fields(const std::string& source, const std::string& name = "RtEffectParams") {
    const std::size_t b = source.find("// BEGIN " + name);
    const std::size_t e = source.find("// END " + name);
    std::vector<std::string> out;
    if (b == std::string::npos || e == std::string::npos || e < b) return out;
    std::string body = source.substr(b, e - b);
    body.erase(0, body.find('\n') + 1);
    std::string clean;
    for (std::size_t i = 0; i < body.size(); ++i) {  // drop the // comments
        if (body[i] == '/' && i + 1 < body.size() && body[i + 1] == '/') {
            while (i < body.size() && body[i] != '\n') ++i;
        }
        if (i < body.size()) clean.push_back(body[i]);
    }
    for (char& c : clean)
        if (c == '{' || c == '}' || c == ',' || c == ';') c = ' ';
    std::istringstream in(clean);
    std::string tok;
    while (in >> tok) {
        if (tok == "struct" || tok == name || tok == "float4" || tok == "uint4") continue;
        out.push_back(tok);
    }
    return out;
}

}  // namespace

TEST_CASE("rt effect: RtEffectParams is the same struct in C++, HLSL and MSL") {
    const std::vector<std::string> expected(std::begin(fa::render::kRtEffectParamNames),
                                            std::end(fa::render::kRtEffectParamNames));
    REQUIRE(expected.size() == 25);
    const std::string hlsl = read_repo_file("engine/render/shaders/rt/rt_shadow.hlsl");
    REQUIRE_FALSE(hlsl.empty());
    CHECK(struct_fields(hlsl) == expected);
    const rt_kernels::RtKernel* k = rt_kernels::find_rt_kernel("rt_shadow");
    REQUIRE(k != nullptr);
    CHECK(struct_fields(std::string(k->msl)) == expected);
    // Each name sits at its float4 (checkpoints across the struct).
    CHECK(offsetof(RtEffectParams, camera) == 0);
    CHECK(offsetof(RtEffectParams, frame) == 3 * 16);
    CHECK(offsetof(RtEffectParams, rayO0) == 4 * 16);
    CHECK(offsetof(RtEffectParams, uRayO0) == 10 * 16);
    CHECK(offsetof(RtEffectParams, viewRight) == 16 * 16);
    CHECK(offsetof(RtEffectParams, viewProj0) == 19 * 16);
    CHECK(offsetof(RtEffectParams, user0) == 23 * 16);
    CHECK(offsetof(RtEffectParams, user1) == 24 * 16);
}

TEST_CASE("rt effect: the kernel table has rt_shadow and a spec for it") {
    const rt_kernels::RtKernel* k = rt_kernels::find_rt_kernel("rt_shadow");
    REQUIRE(k != nullptr);
    const fa::render::RtEffectKernelSpec* spec = fa::render::find_rt_effect_spec("rt_shadow");
    REQUIRE(spec != nullptr);
    CHECK_FALSE(spec->usesRecords);
    CHECK_FALSE(spec->usesGbuffer);
    CHECK(fa::render::find_rt_effect_spec("rt_probe") == nullptr);  // the probe of the tests is not an effect
    CHECK(fa::render::find_rt_effect_spec("nope") == nullptr);
    CHECK(k->msl.find("kernel void rt_shadow") != std::string_view::npos);
    CHECK(k->msl.find("accept_any_intersection(true)") != std::string_view::npos);
    CHECK_FALSE(k->dxil.empty());
    CHECK_FALSE(k->spirv.empty());
}

TEST_CASE("rt effect: the shader of a kernel declares the bindings of the contract in every backend's numbering") {
    const rt_kernels::RtKernel* k = rt_kernels::find_rt_kernel("rt_shadow");
    REQUIRE(k != nullptr);
    const fa::render::RtEffectKernelSpec all{"rt_shadow", true, true};
    for (gpu::Backend backend :
         {gpu::Backend::Metal, gpu::Backend::Recording, gpu::Backend::D3d12, gpu::Backend::Vulkan}) {
        INFO("backend " << int(backend));
        const gpu::ShaderDesc d = fa::render::rt_effect_shader_desc(*k, all, backend);
        REQUIRE(d.compute());
        CHECK(d.usesRayQuery);
        CHECK(d.accelStructures[0].stage == gpu::ShaderStage::Compute);
        CHECK(d.accelStructures[0].binding.hlslRegister == 0);
        CHECK(d.accelStructures[0].binding.mslIndex == 0);
        CHECK(d.accelStructures[0].binding.spirvBinding == 0);
        CHECK(d.uniformBlocks[0].size == sizeof(RtEffectParams));
        CHECK(d.uniformBlocks[0].binding.hlslRegister == 0);
        CHECK(d.uniformBlocks[0].binding.mslIndex == 1);
        CHECK(d.uniformBlocks[0].binding.spirvBinding == 2);
        const gpu::ShaderStorageImageView& out = d.views[0].storageImage;
        CHECK(out.stage == gpu::ShaderStage::Compute);
        CHECK(out.accessFormat == gpu::PixelFormat::Rgba32F);
        CHECK(out.binding.hlslRegister == 0);
        CHECK(out.binding.mslIndex == 0);
        CHECK(out.binding.spirvBinding == 1);
        const gpu::ShaderTextureView& pre = d.views[1].texture;
        CHECK(pre.stage == gpu::ShaderStage::Compute);
        CHECK(pre.binding.hlslRegister == 1);
        CHECK(pre.binding.mslIndex == 1);
        CHECK(pre.binding.spirvBinding == 3);
        // The sampler Sokol wants for each texture view: Metal and the recording device that stands for it, not D3D12 or Vulkan.
        const bool sampler = backend == gpu::Backend::Metal || backend == gpu::Backend::Recording;
        CHECK(fa::render::rt_effect_needs_sampler(backend) == sampler);
        CHECK((d.samplers[0].stage == gpu::ShaderStage::Compute) == sampler);
        CHECK((d.textureSamplerPairs[0].stage == gpu::ShaderStage::Compute) == sampler);
        if (sampler) {
            CHECK(d.textureSamplerPairs[0].viewSlot == 1);
            CHECK(d.textureSamplerPairs[0].samplerSlot == 0);
            CHECK(d.textureSamplerPairs[1].viewSlot == 3);  // the prepass, the albedo and the material, in slot order
            CHECK(d.textureSamplerPairs[2].viewSlot == 4);
        }
        const gpu::ShaderStorageBufferView& rec = d.views[2].storageBuffer;
        CHECK(rec.stage == gpu::ShaderStage::Compute);
        CHECK(rec.binding.hlslRegister == 2);
        CHECK(rec.binding.mslIndex == 8);
        CHECK(rec.binding.spirvBinding == 4);
        CHECK(d.views[3].texture.binding.hlslRegister == 3);
        CHECK(d.views[3].texture.binding.mslIndex == 2);
        CHECK(d.views[3].texture.binding.spirvBinding == 5);
        CHECK(d.views[4].texture.binding.hlslRegister == 4);
        CHECK(d.views[4].texture.binding.mslIndex == 3);
        CHECK(d.views[4].texture.binding.spirvBinding == 6);
        if (backend == gpu::Backend::D3d12) CHECK(d.computeFunc.bytecode.size == k->dxil.size());
        if (backend == gpu::Backend::Vulkan) CHECK(d.computeFunc.bytecode.size == k->spirv.size());
        if (backend == gpu::Backend::Metal) CHECK(std::string(d.computeFunc.entry) == "rt_shadow");
    }
    // The kernel the renderer runs asks for neither records nor the G-buffer: those slots stay empty.
    const fa::render::RtEffectKernelSpec* spec = fa::render::find_rt_effect_spec("rt_shadow");
    REQUIRE(spec != nullptr);
    const gpu::ShaderDesc d = fa::render::rt_effect_shader_desc(*k, *spec, gpu::Backend::Metal);
    CHECK(d.views[2].stage() == gpu::ShaderStage::None);
    CHECK(d.views[3].stage() == gpu::ShaderStage::None);
    CHECK(d.views[4].stage() == gpu::ShaderStage::None);
    // The backends that cannot trace get no shader.
    CHECK_FALSE(fa::render::rt_effect_shader_desc(*k, *spec, gpu::Backend::D3d11).compute());
    CHECK_FALSE(fa::render::rt_effect_shader_desc(*k, *spec, gpu::Backend::Gl).compute());
}

TEST_CASE("rt effect: only the sun's shadow factor of the lit shader reads the mask") {
    const std::string glsl = read_repo_file("engine/render/shaders/mesh_common.glsl");
    REQUIRE_FALSE(glsl.empty());
    // fa_ct_b.y (the draw takes the sun's shadow from view 28) is read in fa_shadow_factor and nowhere else; the local lights call
    // fa_shadow_local and never see it.
    int reads = 0;
    std::size_t last = 0;
    std::size_t at = 0;
    while ((at = glsl.find("fa_ct_b.y", at)) != std::string::npos) {
        const std::size_t lineStart = glsl.rfind('\n', at) + 1;
        const std::string line = glsl.substr(lineStart, glsl.find('\n', at) - lineStart);
        const std::size_t comment = line.find("//");
        if (comment == std::string::npos || comment > line.find("fa_ct_b.y")) {
            ++reads;
            last = at;
        }
        at += 9;
    }
    CHECK(reads == 1);
    const std::size_t fn = glsl.find("float fa_shadow_factor(");
    REQUIRE(fn != std::string::npos);
    CHECK(last > fn);
    CHECK(last < glsl.find("\n}\n", fn));
}

// ---- the renderer's frame on the RecordingDevice ---------------------------------------------------------------------------------------

namespace {

struct Rig {
    Renderer renderer;
    gpu::RecordingDevice* dev = nullptr;
    bool ok = true;  // false only for a rig with a pipeline pool of its own that could not even start
    explicit Rig(bool deviceTraces = true, int pipelinePool = 0) {
        gfx();  // the project root of the process
        gpu::DeviceInit init;
        init.recordingRayTracing = deviceTraces;
        if (pipelinePool > 0) init.pipelinePoolSize = pipelinePool;
        auto made = gpu::make_device(gpu::Backend::Recording, init);
        REQUIRE_MESSAGE(made.ok(), (made.ok() ? "" : made.error().message));
        dev = dynamic_cast<gpu::RecordingDevice*>(made.value().get());
        RendererDeviceAccess::set_next_device(std::move(made.value()));
        RendererDesc d;
        d.designWidth = 160;
        d.designHeight = 96;
        d.headless = true;
        d.backend = GpuBackend::Recording;
        std::string error;
        const bool ok = renderer.init(d, gfx().gpu.environment(), &error);
        RendererDeviceAccess::set_next_device(nullptr);
        if (pipelinePool > 0) {
            this->ok = ok;
        } else {
            REQUIRE_MESSAGE(ok, error);
        }
    }
    ~Rig() {
        if (ok) renderer.shutdown();
    }
    Rig(const Rig&) = delete;
    Rig& operator=(const Rig&) = delete;

    void rays(render::RtShadows shadows) {
        render::RayTracingSettings s;
        s.enabled = true;
        s.shadows = shadows;
        renderer.set_ray_tracing(s);
    }
    void frame(World& w) {
        renderer.update(w);
        renderer.begin_frame();
        renderer.render_world(w, 0.0f);
        renderer.end_frame();
    }
    RtEffects& effects() { return *RendererTestAccess::rt_effects(renderer); }
    int count(gpu::CommandKind kind) const {
        int n = 0;
        for (const gpu::RecordedCommand& c : dev->commands()) n += c.kind == kind ? 1 : 0;
        return n;
    }
    // The labels of the compute passes of the recorded frame.
    std::vector<std::string> compute_passes() const {
        std::vector<std::string> out;
        for (const gpu::RecordedCommand& c : dev->commands())
            if (c.kind == gpu::CommandKind::BeginComputePass) out.push_back(c.text);
        return out;
    }
    std::vector<std::string> lines() const {
        std::vector<std::string> out;
        for (const gpu::RecordedCommand& c : dev->commands()) out.push_back(c.list + ": " + c.text);
        return out;
    }
    std::string errors() const {
        std::string s;
        for (const std::string& e : dev->errors()) s += e + "\n";
        return s;
    }
};

// A camera, a box on a plane and a sun; `sunShadow` = the sun casts (Light.castShadows).
void make_scene(World& w, bool sunShadow = true, bool sun = true) {
    Entity cam = make(w, "cam", {0, 3, 12});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    Entity floor = make(w, "floor", {0, 0, 0});
    w.get<Transform>(floor)->scale = {16, 1, 16};
    w.add<MeshRenderer>(floor).mesh = "plane";
    Entity box = make(w, "box", {0, 1, 0});
    w.add<MeshRenderer>(box).mesh = "cube";
    if (sun) {
        Entity s = make(w, "sun", {0, 5, 0});
        w.get<Transform>(s)->rotation = {-50, 30, 0};
        auto& l = w.add<Light>(s);
        l.type = LightType::Directional;
        l.castShadows = sunShadow;
    }
}

int index_of(const std::vector<std::string>& lines, const std::string& needle) {
    for (std::size_t i = 0; i < lines.size(); ++i)
        if (lines[i].find(needle) != std::string::npos) return int(i);
    return -1;
}

}  // namespace

TEST_CASE("rt effect: with the shadows setting off nothing is declared, made or kept, with ray tracing on") {
    Rig r;
    render::RayTracingSettings s;
    s.enabled = true;
    s.shadows = render::RtShadows::Off;
    s.ao = false;
    r.renderer.set_ray_tracing(s);
    World w;
    make_scene(w);
    for (int i = 0; i < 3; ++i) {
        r.dev->clear_commands();
        r.frame(w);
        CHECK(r.errors().empty());
        CHECK(r.compute_passes().empty());
    }
    CHECK(r.effects().empty());
    CHECK(r.effects().image_count() == 0);
    CHECK(r.effects().kernel_count() == 0);
}

TEST_CASE("rt effect: hard shadows declare one compute pass after the TLAS and the prepass, with the bindings of the "
          "contract") {
    Rig r;
    r.rays(render::RtShadows::Hard);
    World w;
    make_scene(w);
    r.frame(w);  // the first frame builds the BLASes
    r.dev->clear_commands();
    r.frame(w);
    INFO(r.errors());
    CHECK(r.errors().empty());
    const std::vector<std::string> passes = r.compute_passes();
    REQUIRE(passes.size() == 1);
    CHECK(passes[0].find("rt-shadows") != std::string::npos);
    const std::vector<std::string> lines = r.lines();
    const int tlas = index_of(lines, "build_tlas");
    const int prepass = index_of(lines, "begin_pass 'prepass'");
    const int shadows = index_of(lines, "rt-shadows");
    const int game = index_of(lines, "begin_pass 'game'");
    REQUIRE(tlas >= 0);
    REQUIRE(prepass >= 0);
    REQUIRE(shadows >= 0);
    REQUIRE(game >= 0);
    CHECK(tlas < shadows);
    CHECK(prepass < shadows);
    CHECK(shadows < game);
    // One pipeline, the output and the prepass as views (and the nearest sampler Metal's Sokol wants beside the texture view), one 400-byte constants block, one dispatch of the camera's rectangle in 8 x 8
    // groups (160 x 96 pixels).
    REQUIRE(std::size_t(shadows) + 4 < lines.size());
    CHECK(lines[std::size_t(shadows) + 1].find("set_pipeline") != std::string::npos);
    CHECK(lines[std::size_t(shadows) + 2].find("views=2 samplers=1") != std::string::npos);
    CHECK(lines[std::size_t(shadows) + 3].find("set_uniforms 0 400B") != std::string::npos);
    CHECK(lines[std::size_t(shadows) + 4].find("dispatch 20 12 1") != std::string::npos);
    CHECK(r.count(gpu::CommandKind::Dispatch) == 1);
    CHECK(r.effects().image_count() == 1);
    CHECK(r.effects().kernel_count() == 1);
}

TEST_CASE("rt effect: the recorded frame is the same every frame (no clock, no random number)") {
    Rig r;
    r.rays(render::RtShadows::Hard);
    World w;
    make_scene(w);
    r.frame(w);
    r.frame(w);
    r.dev->clear_commands();
    r.frame(w);
    const std::vector<std::string> a = r.lines();
    r.dev->clear_commands();
    r.frame(w);
    const std::vector<std::string> b = r.lines();
    REQUIRE(a.size() > 10);
    CHECK(a == b);
}

TEST_CASE("rt effect: no pass without a sun that casts, and none without a light") {
    {
        Rig r;
        r.rays(render::RtShadows::Hard);
        World w;
        make_scene(w, false);  // the sun casts no shadow
        r.frame(w);
        r.dev->clear_commands();
        r.frame(w);
        CHECK(r.compute_passes().empty());
        CHECK(r.effects().empty());
    }
    {
        Rig r;
        r.rays(render::RtShadows::Hard);
        World w;
        make_scene(w, true, false);  // no light at all
        r.frame(w);
        r.dev->clear_commands();
        r.frame(w);
        CHECK(r.compute_passes().empty());
        CHECK(r.effects().empty());
    }
}

TEST_CASE("rt effect: turning the setting off frees the kernel and the image, and ray tracing off frees all") {
    Rig r;
    r.rays(render::RtShadows::Hard);
    World w;
    make_scene(w);
    r.frame(w);
    r.frame(w);
    CHECK(r.effects().image_count() == 1);
    r.rays(render::RtShadows::Off);
    for (int i = 0; i < 6; ++i) r.frame(w);  // the image is kept two frames after its last use, then swept
    CHECK(r.effects().image_count() == 0);
    CHECK(r.effects().kernel_count() == 0);
    r.dev->clear_commands();
    r.frame(w);
    CHECK(r.compute_passes().empty());
    r.rays(render::RtShadows::Hard);
    r.frame(w);
    r.frame(w);
    CHECK(r.effects().image_count() == 1);
    render::RayTracingSettings off;
    off.enabled = false;
    r.renderer.set_ray_tracing(off);
    r.frame(w);
    CHECK(r.effects().empty());
    CHECK(r.errors().empty());
}

namespace {

int count_of(const std::vector<std::string>& lines, const std::string& needle) {
    int n = 0;
    for (const std::string& l : lines) n += l.find(needle) != std::string::npos ? 1 : 0;
    return n;
}

// Frames until the BLASes are built and the history is warm.
void warm(Rig& r, World& w, int frames = 4) {
    for (int i = 0; i < frames; ++i) r.frame(w);
}

}  // namespace

TEST_CASE(
    "rt effect: soft shadows trace into a noisy image, denoise it and pack it; hard has one pass and no denoiser") {
    Logs log;
    Rig hard;
    hard.rays(render::RtShadows::Hard);
    World wa;
    make_scene(wa);
    warm(hard, wa);
    hard.dev->clear_commands();
    hard.frame(wa);
    REQUIRE(hard.compute_passes().size() == 1);
    CHECK(hard.compute_passes()[0].find("camera:0/rt-shadows") != std::string::npos);
    CHECK(count_of(hard.lines(), "rtd-") == 0);
    CHECK(RendererTestAccess::rt_denoiser(hard.renderer)->history_image_count() == 0);
    CHECK_FALSE(RendererTestAccess::rt_denoiser(hard.renderer)->shaders_made());

    Rig soft;
    soft.rays(render::RtShadows::Soft);
    World wb;
    make_scene(wb);
    warm(soft, wb);
    soft.dev->clear_commands();
    soft.frame(wb);
    INFO(soft.errors());
    CHECK(soft.errors().empty());
    // Two compute passes: the trace (raysPerPixel rays at the sun's disc into a noisy image) and the pack (the denoised visibility into the
    // layout the lit pass reads); the denoiser's fragment passes (guide, temporal, a-trous) are between them.
    REQUIRE(soft.compute_passes().size() == 2);
    CHECK(soft.compute_passes()[0].find("camera:0/rt-shadows-trace") != std::string::npos);
    CHECK(soft.compute_passes()[1].find("camera:0/rt-shadows-trace") == std::string::npos);
    CHECK(soft.compute_passes()[1].find("camera:0/rt-shadows") != std::string::npos);
    const std::vector<std::string> lines = soft.lines();
    CHECK(soft.count(gpu::CommandKind::Dispatch) == 2);
    CHECK(count_of(lines, "begin_pass 'rtd-guide'") == 1);
    CHECK(count_of(lines, "begin_pass 'rtd-temporal'") == 1);
    CHECK(count_of(lines, "begin_pass 'rtd-atrous'") >= 1);
    const int tlas = index_of(lines, "build_tlas");
    const int prepass = index_of(lines, "begin_pass 'prepass'");
    const int trace = index_of(lines, "rt-shadows-trace");
    const int guide = index_of(lines, "begin_pass 'rtd-guide'");
    const int pack = index_of(lines, "begin_compute_pass 'camera:0/rt-shadows'");
    const int game = index_of(lines, "begin_pass 'game'");
    REQUIRE(tlas >= 0);
    REQUIRE(prepass >= 0);
    REQUIRE(trace >= 0);
    REQUIRE(guide >= 0);
    REQUIRE(pack >= 0);
    REQUIRE(game >= 0);
    CHECK(tlas < trace);
    CHECK(prepass < trace);
    CHECK(trace < guide);
    CHECK(guide < pack);
    CHECK(pack < game);
    int lastAtrous = -1;
    for (std::size_t i = 0; i < lines.size(); ++i)
        if (lines[i].find("begin_pass 'rtd-atrous'") != std::string::npos) lastAtrous = int(i);
    CHECK(lastAtrous < pack);
    // The pack pass has no ray query: no TLAS bound, the trace image and the denoised image as views (output, trace image, denoised image).
    CHECK(lines[std::size_t(pack) + 2].find("views=3") != std::string::npos);
    CHECK(lines[std::size_t(trace) + 2].find("views=2") != std::string::npos);
    CHECK(soft.effects().image_count() == 2);  // the trace image and the packed one
    CHECK(soft.effects().kernel_count() == 2);
    CHECK(RendererTestAccess::rt_denoiser(soft.renderer)->history_image_count() > 0);
    // The old message ("soft draws the hard one for now") is gone.
    CHECK(log.count("\"soft\"") == 0);
    // The lit pass reads the packed image.
    CHECK(RendererTestAccess::rt_shadow_draws(soft.renderer).mask > 0);
    CHECK(RendererTestAccess::rt_effect_failure(soft.renderer).empty());
}

TEST_CASE("rt effect: a soft frame is the same every frame, and leaving soft frees the denoiser and the trace image") {
    Rig r;
    r.rays(render::RtShadows::Soft);
    World w;
    make_scene(w);
    warm(r, w, 6);
    r.dev->clear_commands();
    r.frame(w);
    const std::vector<std::string> a = r.lines();
    r.dev->clear_commands();
    r.frame(w);
    const std::vector<std::string> b = r.lines();
    REQUIRE(a.size() > 30);
    CHECK(a == b);
    // Back to hard: the trace image, the soft kernels and the denoiser's history go (the images are swept after two frames).
    r.rays(render::RtShadows::Hard);
    for (int i = 0; i < 6; ++i) r.frame(w);
    CHECK(r.effects().image_count() == 1);
    CHECK(r.effects().kernel_count() == 1);
    CHECK(RendererTestAccess::rt_denoiser(r.renderer)->history_image_count() == 0);
    r.dev->clear_commands();
    r.frame(w);
    REQUIRE(r.compute_passes().size() == 1);
    CHECK(r.compute_passes()[0].find("rt-shadows-trace") == std::string::npos);
    CHECK(count_of(r.lines(), "rtd-") == 0);
    // Ray tracing off: nothing is kept.
    render::RayTracingSettings off;
    off.enabled = false;
    r.renderer.set_ray_tracing(off);
    r.frame(w);
    CHECK(r.effects().empty());
    CHECK_FALSE(RendererTestAccess::rt_denoiser(r.renderer)->shaders_made());
    CHECK(r.errors().empty());
}

TEST_CASE("rt effect: a sun that casts onto meshes that cast nothing asks for no rays, hard or soft") {
    for (render::RtShadows mode : {render::RtShadows::Hard, render::RtShadows::Soft}) {
        Rig r;
        r.rays(mode);
        World w;
        make_scene(w);
        w.each<MeshRenderer>([](Entity, MeshRenderer& m) { m.castShadows = false; });
        warm(r, w);
        r.dev->clear_commands();
        r.frame(w);
        CHECK(r.compute_passes().empty());
        CHECK(r.effects().empty());
        CHECK_FALSE(RendererTestAccess::rt_denoiser(r.renderer)->shaders_made());
    }
}

TEST_CASE("rt effect: a second camera draws no rays of its own, and a render scale remakes the image at the new size") {
    Logs log;
    Rig r;
    r.rays(render::RtShadows::Soft);
    World w;
    make_scene(w);
    Entity second = make(w, "second", {6, 3, 8});
    auto& c2 = w.add<Camera>(second);
    c2.projection = Projection::Perspective;
    c2.renderTarget = "second-view";
    c2.renderTargetSize = {64, 48};
    warm(r, w, 5);
    r.dev->clear_commands();
    r.frame(w);
    INFO(r.errors());
    CHECK(r.errors().empty());
    // The ray tracing scene is the main camera's: one trace and one pack, one pair of images; the other camera keeps the cascades.
    CHECK(r.compute_passes().size() == 2);
    CHECK(r.effects().image_count() == 2);
    CHECK(RendererTestAccess::rt_effect_failure(r.renderer).empty());
    // A render scale below 1 draws the camera in fewer pixels: the images are made again at that size (the old ones destroyed, none left
    // behind), the denoiser's history follows, and the effect never skips a frame on a size mismatch.
    r.renderer.set_render_scale(0.5f, 1.0f);
    r.frame(w);
    r.frame(w);
    r.dev->clear_commands();
    r.frame(w);
    CHECK(r.errors().empty());
    CHECK(r.compute_passes().size() == 2);
    CHECK(r.effects().image_count() == 2);
    CHECK(count_of(r.lines(), "dispatch 10 6 1") == 2);  // 80 x 48 in groups of 8 x 8, the trace and the pack
    r.renderer.set_render_scale(1.0f, 1.0f);
    r.frame(w);
    r.frame(w);
    r.dev->clear_commands();
    r.frame(w);
    CHECK(r.errors().empty());
    CHECK(count_of(r.lines(), "dispatch 20 12 1") == 2);
    CHECK(r.effects().image_count() == 2);
    CHECK(RendererTestAccess::rt_effect_failure(r.renderer).empty());
    CHECK(log.count("could not run") == 0);
    CHECK(RendererTestAccess::rt_shadow_draws(r.renderer).mask > 0);
}

TEST_CASE("rt effect: no caster loses its shadow, the lit pass takes the cascades too wherever the rays do not see a "
          "caster") {
    for (render::RtShadows mode : {render::RtShadows::Hard, render::RtShadows::Soft}) {
        INFO("mode " << int(mode));
        // Every caster traced: the mask alone.
        {
            Rig r;
            r.rays(mode);
            World w;
            make_scene(w);
            warm(r, w, 5);
            CHECK(RendererTestAccess::rt_scene(r.renderer)->stats().untracedCasters == 0);
            const auto d = RendererTestAccess::rt_shadow_draws(r.renderer);
            CHECK(d.mask > 0);
            CHECK(d.withCascades == 0);
        }
        // A terrain casts too and the rays do not see it: min(mask, cascades) in every draw that takes the mask.
        {
            Rig r;
            r.rays(mode);
            World w;
            make_scene(w);
            Entity ground = make(w, "terrain", {0, -1, 0});
            auto& t = w.add<Terrain3D>(ground);
            t.size = {16, 16};
            warm(r, w, 5);
            const render::RtSceneStats st = RendererTestAccess::rt_scene(r.renderer)->stats();
            CHECK(st.skippedTerrain > 0);
            CHECK(st.untracedCasters > 0);
            const auto d = RendererTestAccess::rt_shadow_draws(r.renderer);
            CHECK(d.mask > 0);
            CHECK(d.withCascades == d.mask);
            CHECK(r.errors().empty());
        }
        // More casters than render.rayTracing.maxInstances: the ones over the cap keep the cascades' shadow.
        {
            Rig r;
            render::RayTracingSettings s;
            s.enabled = true;
            s.shadows = mode;
            s.maxInstances = 1;
            r.renderer.set_ray_tracing(s);
            World w;
            make_scene(w);
            warm(r, w, 5);
            const render::RtSceneStats st = RendererTestAccess::rt_scene(r.renderer)->stats();
            CHECK(st.droppedOverCap > 0);
            CHECK(st.untracedCasters > 0);
            const auto d = RendererTestAccess::rt_shadow_draws(r.renderer);
            CHECK(d.mask > 0);
            CHECK(d.withCascades == d.mask);
        }
    }
}

TEST_CASE("rt effect: a caster whose BLAS is not built yet keeps the cascades' shadow, and the mask alone takes over "
          "once it is") {
    Rig r;
    r.rays(render::RtShadows::Hard);
    World w;
    make_scene(w);
    r.frame(w);
    const auto first = RendererTestAccess::rt_shadow_draws(r.renderer);
    const std::uint32_t firstUntraced = RendererTestAccess::rt_scene(r.renderer)->stats().untracedCasters;
    // Whatever the first frame had in the TLAS (the renderer's scene builds every BLAS of the first frame: the build budget and the failed BLAS
    // are forced in rt_scene_tests.cpp, where the scene is driven by hand), the cascades are in the lit pass's mask draws exactly when the scene
    // counted an untraced caster, and a caster without a BLAS (skippedNoBlas) is one of them.
    CHECK(first.withCascades == (firstUntraced > 0 ? first.mask : 0));
    if (RendererTestAccess::rt_scene(r.renderer)->stats().skippedNoBlas > 0) CHECK(firstUntraced > 0);
    warm(r, w, 5);
    CHECK(RendererTestAccess::rt_scene(r.renderer)->stats().untracedCasters == 0);
    CHECK(RendererTestAccess::rt_shadow_draws(r.renderer).withCascades == 0);
}

TEST_CASE("rt effect: only the sun's shadow factor of the lit shader takes the cascades with the mask, and with a "
          "slope tolerance") {
    const std::string glsl = read_repo_file("engine/render/shaders/mesh_common.glsl");
    REQUIRE_FALSE(glsl.empty());
    const std::size_t fn = glsl.find("float fa_shadow_factor(");
    REQUIRE(fn != std::string::npos);
    const std::string body = glsl.substr(fn, glsl.find("\n}\n", fn) - fn);
    CHECK(body.find("fa_ct_b.z > 0.5") != std::string::npos);
    CHECK(body.find("min(rt.g, fa_shadow_sun(") != std::string::npos);
    // The depth match between the mask's pixel and the fragment follows the surface's slope (MSAA grazing angles): no pixel flips between
    // the mask and the cascades.
    // The slope is taken once per fragment, at the start of main (fa_cluster_begin), never inside a light's branch (a derivative of a lane that left).
    CHECK(body.find("fa_rt_slope") != std::string::npos);
    CHECK(body.find("fwidth(") == std::string::npos);
    const std::string loopText = read_repo_file("engine/render/shaders/light_loop.glsl");
    const std::size_t begin = loopText.find("void fa_cluster_begin(");
    REQUIRE(begin != std::string::npos);
    const std::size_t beginEnd = loopText.find("\n}\n", begin);
    const std::string beginBody = loopText.substr(begin, beginEnd - begin);
    CHECK(beginBody.find("fwidth(") != std::string::npos);
    CHECK(beginBody.find("fa_rt_slope =") != std::string::npos);
    CHECK(glsl.find("fwidth(") == std::string::npos);  // no other derivative of the shadow code in this file
    // fa_ct_b.z is read in that function and in the local lights' fa_shadow_local_rt (M79-P2a-3) and nowhere else: the maps' factor of a local
    // light (fa_shadow_local) and the full shaders never see the mask or the min.
    const std::size_t local = glsl.find("float fa_shadow_local_rt(");
    REQUIRE(local != std::string::npos);
    const std::size_t localEnd = glsl.find("\n}\n", local);
    for (std::size_t at = glsl.find("fa_ct_b.z", fn + body.size()); at != std::string::npos;
         at = glsl.find("fa_ct_b.z", at + 1)) {
        const std::size_t lineStart = glsl.rfind('\n', at) + 1;
        const std::size_t comment = glsl.substr(lineStart, at - lineStart).find("//");
        if (comment != std::string::npos) continue;  // a comment
        CHECK(at > local);
        CHECK(at < localEnd);
    }
}

TEST_CASE("rt effect: a compute pipeline the driver refuses is said once, shown by the status, and the cascades stay") {
    // A pipeline pool that holds the frame's raster pipelines but not the kernel's: the RecordingDevice refuses the compute pipeline the way a
    // driver that cannot compile the kernel would. Some size of the pool does that; every size that does must say so once.
    bool found = false;
    for (int pool = 1; pool <= 40 && !found; ++pool) {
        Logs log;
        Rig r(true, pool);
        if (!r.ok) continue;
        r.rays(render::RtShadows::Hard);
        World w;
        make_scene(w);
        for (int i = 0; i < 4; ++i) r.frame(w);
        const std::string failure = RendererTestAccess::rt_effect_failure(r.renderer);
        if (failure.empty()) continue;
        found = true;
        INFO("pool " << pool << ": " << failure);
        CHECK(failure.find("camera:0/shadows") != std::string::npos);
        CHECK(failure.find("refused the compute pipeline") != std::string::npos);
        CHECK(r.renderer.ray_tracing_failure() == failure);
        for (int i = 0; i < 3; ++i) r.frame(w);  // said once however many frames
        CHECK(log.count("could not run") == 1);
        // The lit pass does not take a mask that did not come: the cascades alone.
        CHECK(RendererTestAccess::rt_shadow_draws(r.renderer).mask == 0);
        CHECK(r.compute_passes().empty());
    }
    CHECK(found);
}

namespace fa::render {
// The friend of RtEffects that lets a test report a failure without a driver that fails.
struct RtEffectsTestAccess {
    static void note(RtEffects& e, const std::string& key, const std::string& why,
                     const std::string& said = std::string()) {
        e.note_failure(key, why, said);
    }
};
}  // namespace fa::render

TEST_CASE("rt effect: a failure whose text only changes in its sizes is warned once (dynamic resolution), another "
          "cause again") {
    Logs log;
    Rig r;
    using Access = fa::render::RtEffectsTestAccess;
    const std::string said = "the prepass and the effect's image have different sizes";
    Access::note(r.effects(), "camera:0/shadows", "the prepass is 160 x 96 but the effect's image is 120 x 72", said);
    Access::note(r.effects(), "camera:0/shadows", "the prepass is 170 x 102 but the effect's image is 120 x 72", said);
    Access::note(r.effects(), "camera:0/shadows", "the prepass is 180 x 108 but the effect's image is 120 x 72", said);
    CHECK(log.count("could not run") == 1);
    // A text without a `said` is its own key: a different cause is said, the same one is not said twice.
    Access::note(r.effects(), "camera:0/shadows", "the graphics driver refused the compute pipeline");
    Access::note(r.effects(), "camera:0/shadows", "the graphics driver refused the compute pipeline");
    CHECK(log.count("could not run") == 2);
    // Another effect has its own once.
    Access::note(r.effects(), "camera:0/ao", "the prepass is 160 x 96 but the effect's image is 120 x 72", said);
    CHECK(log.count("could not run") == 3);
}

TEST_CASE("rt effect: a device that cannot trace says so once and draws the frame it would draw with ray tracing off") {
    Logs log;
    auto stream = [&](bool deviceTraces, bool setting) {
        Rig r(deviceTraces);
        if (setting) r.rays(render::RtShadows::Hard);
        World w;
        make_scene(w);
        r.frame(w);
        r.frame(w);
        r.dev->clear_commands();
        r.frame(w);
        CHECK(r.errors().empty());
        CHECK(r.compute_passes().empty());
        CHECK(r.effects().empty());
        return r.lines();
    };
    const std::vector<std::string> off = stream(true, false);
    CHECK(log.count("cannot trace rays") == 0);
    const std::vector<std::string> unsupported = stream(false, true);
    REQUIRE(off.size() > 5);
    CHECK(off == unsupported);
    // The renderer's one teaching message of rt_begin_frame; the effect adds none of its own.
    CHECK(log.count("cannot trace rays") == 1);
    CHECK(log.count("cannot run on this device") == 0);
}

// M79-P6b: the cost budget that a runner without ray tracing can check. Every effect asked for at once and the most rays, on a
// device that cannot trace: the frame is the frame of ray tracing off, command for command (so its cost stays inside
// the raster budget), and no kernel, image or acceleration structure is made. What the effects cost on a GPU that traces is a number of
// docs/RAY_TRACING.md, "What it costs", measured by hand.
TEST_CASE("rt effect: every effect on, on a device that cannot trace, draws exactly the frame of ray tracing off and "
          "makes nothing") {
    Logs log;
    auto stream = [&](bool setting) {
        Rig r(false);
        if (setting) {
            render::RayTracingSettings all;
            all.enabled = true;
            all.shadows = render::RtShadows::Soft;
            all.ao = true;
            all.reflections = true;
            all.translucency = true;
            all.gi = render::RtGi::PerPixel;
            all.raysPerPixel = 16;
            r.renderer.set_ray_tracing(all);
        }
        World w;
        make_scene(w);
        r.frame(w);
        r.frame(w);
        r.dev->clear_commands();
        r.frame(w);
        CHECK(r.errors().empty());
        CHECK(r.compute_passes().empty());
        CHECK(r.effects().empty());
        return r.lines();
    };
    const std::vector<std::string> off = stream(false);
    const std::vector<std::string> allOn = stream(true);
    REQUIRE(off.size() > 5);
    CHECK(off == allOn);
    CHECK(log.count("cannot trace rays") == 1);
}

// ---- M79-P2b: ray traced ambient occlusion (shaders/rt/rt_ao.{hlsl,metal}, docs/design/ARCHITECTURE_RT_EFFECTS.md "The second effect: ambient occlusion (M79-P2b)") ---------

namespace {

void ao_rays(Rig& r, bool ao, render::RtShadows shadows = render::RtShadows::Off, int raysPerPixel = 1) {
    render::RayTracingSettings s;
    s.enabled = true;
    s.shadows = shadows;
    s.ao = ao;
    s.raysPerPixel = raysPerPixel;
    r.renderer.set_ray_tracing(s);
}

// The camera of make_scene with the screen-space occlusion on (PostProcess.ssao*).
void add_ssao_to_camera(World& w) {
    PostProcess& p = w.add<PostProcess>(w.find("cam"));
    p.ssaoEnabled = true;
    p.ssaoIntensity = 1.5f;
    p.ssaoRadius = 0.8f;
}

int count_labels(const std::vector<std::string>& lines, const std::string& needle) {
    int n = 0;
    for (const std::string& l : lines) n += l.find(needle) != std::string::npos ? 1 : 0;
    return n;
}

}  // namespace

TEST_CASE("rt effect: the kernel table has rt_ao, with the same constants block and bindings as the shadows") {
    const rt_kernels::RtKernel* k = rt_kernels::find_rt_kernel("rt_ao");
    REQUIRE(k != nullptr);
    const fa::render::RtEffectKernelSpec* spec = fa::render::find_rt_effect_spec("rt_ao");
    REQUIRE(spec != nullptr);
    CHECK_FALSE(spec->usesRecords);
    CHECK_FALSE(spec->usesGbuffer);
    CHECK(k->msl.find("kernel void rt_ao") != std::string_view::npos);
    CHECK(k->msl.find("accept_any_intersection(true)") != std::string_view::npos);
    CHECK_FALSE(k->dxil.empty());
    CHECK_FALSE(k->spirv.empty());
    const std::vector<std::string> expected(std::begin(fa::render::kRtEffectParamNames),
                                            std::end(fa::render::kRtEffectParamNames));
    const std::string hlsl = read_repo_file("engine/render/shaders/rt/rt_ao.hlsl");
    REQUIRE_FALSE(hlsl.empty());
    CHECK(struct_fields(hlsl) == expected);
    CHECK(struct_fields(std::string(k->msl)) == expected);
    for (gpu::Backend backend :
         {gpu::Backend::Metal, gpu::Backend::Recording, gpu::Backend::D3d12, gpu::Backend::Vulkan}) {
        INFO("backend " << int(backend));
        const gpu::ShaderDesc d = fa::render::rt_effect_shader_desc(*k, *spec, backend);
        REQUIRE(d.compute());
        CHECK(d.usesRayQuery);
        CHECK(d.uniformBlocks[0].size == sizeof(RtEffectParams));
        CHECK(d.views[0].storageImage.accessFormat == gpu::PixelFormat::Rgba32F);
        CHECK(d.views[1].texture.binding.mslIndex == 1);  // the prepass
        if (backend == gpu::Backend::Metal) CHECK(std::string(d.computeFunc.entry) == "rt_ao");
    }
}

TEST_CASE("rt effect: ambient occlusion adds the kernel and the denoiser's passes and not the screen-space ones") {
    Rig r;
    ao_rays(r, true);
    World w;
    make_scene(w, true, false);
    add_ssao_to_camera(w);
    r.frame(w);  // the first frame builds the BLASes
    r.dev->clear_commands();
    r.frame(w);
    INFO(r.errors());
    CHECK(r.errors().empty());
    const std::vector<std::string> passes = r.compute_passes();
    REQUIRE(passes.size() == 1);
    CHECK(passes[0].find("rt-ao") != std::string::npos);
    const std::vector<std::string> lines = r.lines();
    // The kernel after the TLAS and the prepass; the denoiser's passes after the kernel and before the main pass, which applies the result.
    const int tlas = index_of(lines, "build_tlas");
    const int prepass = index_of(lines, "begin_pass 'prepass'");
    const int kernel = index_of(lines, "rt-ao");
    const int temporal = index_of(lines, "rtd-temporal");
    const int atrous = index_of(lines, "rtd-atrous");
    const int game = index_of(lines, "begin_pass 'game'");
    REQUIRE(tlas >= 0);
    REQUIRE(prepass >= 0);
    REQUIRE(kernel >= 0);
    REQUIRE(temporal >= 0);
    REQUIRE(atrous >= 0);
    REQUIRE(game >= 0);
    CHECK(tlas < kernel);
    CHECK(prepass < kernel);
    CHECK(kernel < temporal);
    CHECK(temporal < atrous);
    CHECK(atrous < game);
    CHECK(count_labels(lines, "rtd-guide") >= 1);
    // The SSAO's passes are gone: the traced result replaces them.
    CHECK(count_labels(lines, "begin_pass 'ssao-") == 0);
    CHECK(count_labels(lines, "set_pipeline 'ssao-apply'") ==
          1);  // the apply of the screen-space occlusion draws the traced one
    CHECK(r.count(gpu::CommandKind::Dispatch) == 1);
    CHECK(r.effects().image_count() == 1);
    CHECK(r.effects().kernel_count() == 1);
    // One kernel pipeline, the output and the prepass as views, one 400-byte block, one dispatch over 160 x 96 pixels.
    REQUIRE(std::size_t(kernel) + 4 < lines.size());
    CHECK(lines[std::size_t(kernel) + 2].find("views=2 samplers=1") != std::string::npos);
    CHECK(lines[std::size_t(kernel) + 3].find("set_uniforms 0 400B") != std::string::npos);
    CHECK(lines[std::size_t(kernel) + 4].find("dispatch 20 12 1") != std::string::npos);
}

TEST_CASE("rt effect: ambient occlusion works without a PostProcess too (the component's defaults) and is the same "
          "every frame") {
    Rig r;
    ao_rays(r, true);
    World w;
    make_scene(w, true, false);
    r.frame(w);
    r.frame(w);
    r.dev->clear_commands();
    r.frame(w);
    const std::vector<std::string> a = r.lines();
    CHECK(r.compute_passes().size() == 1);
    CHECK(count_labels(a, "begin_pass 'rtd-temporal'") == 1);
    r.dev->clear_commands();
    r.frame(w);
    const std::vector<std::string> b = r.lines();
    REQUIRE(a.size() > 10);
    CHECK(a == b);
}

TEST_CASE("rt effect: with ambient occlusion off nothing is declared, made or kept, and the screen-space passes stay") {
    Rig r;
    ao_rays(r, false, render::RtShadows::Hard);  // another effect on: ray tracing is on, ao is not
    World w;
    make_scene(w, true, true);
    add_ssao_to_camera(w);
    r.frame(w);
    r.dev->clear_commands();
    r.frame(w);
    const std::vector<std::string> lines = r.lines();
    CHECK(count_labels(lines, "rtd-") == 0);
    CHECK(count_labels(lines, "rt-ao") == 0);
    CHECK(count_labels(lines, "begin_pass 'ssao-ao'") == 1);
    const auto* denoiser = RendererTestAccess::rt_denoiser(r.renderer);
    REQUIRE(denoiser != nullptr);
    CHECK_FALSE(denoiser->shaders_made());
    CHECK(denoiser->history_image_count() == 0);
}

TEST_CASE("rt effect: ambient occlusion together with the sun's shadow makes two compute passes") {
    Rig r;
    ao_rays(r, true, render::RtShadows::Hard);
    World w;
    make_scene(w);
    r.frame(w);
    r.dev->clear_commands();
    r.frame(w);
    CHECK(r.errors().empty());
    const std::vector<std::string> passes = r.compute_passes();
    REQUIRE(passes.size() == 2);
    CHECK(count_labels(passes, "rt-shadows") == 1);
    CHECK(count_labels(passes, "rt-ao") == 1);
    CHECK(r.effects().image_count() == 2);
}

TEST_CASE("rt effect: ambient occlusion turned off frees the kernel, the image and the denoiser, and ray tracing off "
          "frees all") {
    Rig r;
    ao_rays(r, true);
    World w;
    make_scene(w, true, false);
    r.frame(w);
    r.frame(w);
    r.frame(w);
    CHECK(r.effects().image_count() == 1);
    const auto* denoiser = RendererTestAccess::rt_denoiser(r.renderer);
    REQUIRE(denoiser != nullptr);
    CHECK(denoiser->shaders_made());
    CHECK(denoiser->history_image_count() > 0);
    ao_rays(r, false, render::RtShadows::Hard);  // ray tracing stays on (the shadows), the occlusion goes
    for (int i = 0; i < 6; ++i) r.frame(w);
    CHECK(r.effects().image_count() <=
          1);  // the shadows' image, if the scene has a sun that casts (it has no light here)
    CHECK(denoiser->history_image_count() == 0);  // swept: no camera asked for the signal
    ao_rays(r, true);
    r.frame(w);
    r.frame(w);
    CHECK(r.effects().image_count() == 1);
    render::RayTracingSettings off;
    off.enabled = false;
    r.renderer.set_ray_tracing(off);
    r.frame(w);
    CHECK(r.effects().empty());
    CHECK_FALSE(denoiser->shaders_made());
    CHECK(denoiser->history_image_count() == 0);
    CHECK(r.errors().empty());
}

TEST_CASE(
    "rt effect: ambient occlusion on a device that cannot trace keeps the screen-space occlusion and says so once") {
    Logs log;
    Rig r(false);
    ao_rays(r, true);
    World w;
    make_scene(w, true, false);
    add_ssao_to_camera(w);
    r.frame(w);
    r.frame(w);
    r.dev->clear_commands();
    r.frame(w);
    const std::vector<std::string> lines = r.lines();
    CHECK(r.compute_passes().empty());
    CHECK(count_labels(lines, "begin_pass 'ssao-ao'") == 1);
    CHECK(count_labels(lines, "rtd-") == 0);
    CHECK(r.effects().empty());
    CHECK(log.count("cannot trace rays") == 1);
    CHECK(log.count("cannot run on this device") == 0);
}

TEST_CASE("rt effect: a resize makes the ambient occlusion image again at the new size, and the dispatch covers it") {
    Rig r;
    ao_rays(r, true);
    World w;
    make_scene(w, true, false);
    r.frame(w);
    r.frame(w);
    REQUIRE(r.effects().image_count() == 1);
    r.dev->clear_commands();
    r.frame(w);
    auto dispatched = [&](const char* groups) {
        for (const std::string& l : r.lines())
            if (l.find(groups) != std::string::npos) return true;
        return false;
    };
    CHECK(dispatched("dispatch 20 12 1"));  // 160 x 96 pixels in 8 x 8 groups
    r.renderer.set_render_scale(0.5f);
    r.frame(w);
    r.dev->clear_commands();
    r.frame(w);
    r.frame(w);
    r.dev->clear_commands();
    r.frame(w);
    CHECK(dispatched("dispatch 10 6 1"));  // 80 x 48 pixels
    CHECK_FALSE(dispatched("dispatch 20 12 1"));
    // The image the kernel writes is the new size, and the old one goes after its two frames.
    for (int i = 0; i < 4; ++i) r.frame(w);
    CHECK(r.effects().image_count() == 1);
    CHECK(r.errors().empty());
}

// ---- M79-P3a-1: the hit shading include and the sharp reflections ------------------------------------------------------------------------

TEST_CASE("rt reflect: RtHitParams is the same struct in C++, rt_hit.hlsli and rt_hit.msli, and RtEffectParams the "
          "same in rt_reflect") {
    const std::vector<std::string> hit(std::begin(fa::render::kRtHitParamNames),
                                       std::end(fa::render::kRtHitParamNames));
    REQUIRE(hit.size() == 6);
    CHECK(sizeof(fa::render::RtHitParams) == 96);
    const std::string hlsli = read_repo_file("engine/render/shaders/rt/rt_hit.hlsli");
    const std::string msli = read_repo_file("engine/render/shaders/rt/rt_hit.msli");
    REQUIRE_FALSE(hlsli.empty());
    REQUIRE_FALSE(msli.empty());
    CHECK(struct_fields(hlsli, "RtHitParams") == hit);
    CHECK(struct_fields(msli, "RtHitParams") == hit);
    // The kernel's embedded MSL carries the include's text (the library is compiled from one string).
    const rt_kernels::RtKernel* k = rt_kernels::find_rt_kernel("rt_reflect");
    REQUIRE(k != nullptr);
    CHECK(struct_fields(std::string(k->msl), "RtHitParams") == hit);
    const std::vector<std::string> params(std::begin(fa::render::kRtEffectParamNames),
                                          std::end(fa::render::kRtEffectParamNames));
    CHECK(struct_fields(read_repo_file("engine/render/shaders/rt/rt_reflect.hlsl")) == params);
    CHECK(struct_fields(std::string(k->msl)) == params);
    CHECK(offsetof(fa::render::RtHitParams, ambient) == 2 * 16);
    CHECK(offsetof(fa::render::RtHitParams, limits) == 5 * 16);
}

TEST_CASE("rt reflect: the kernel has a spec that asks for the records, the G-buffer and the hit constants, with the "
          "bindings of the "
          "contract in every backend's numbering") {
    const rt_kernels::RtKernel* k = rt_kernels::find_rt_kernel("rt_reflect");
    REQUIRE(k != nullptr);
    const fa::render::RtEffectKernelSpec* spec = fa::render::find_rt_effect_spec("rt_reflect");
    REQUIRE(spec != nullptr);
    CHECK(spec->usesRecords);
    CHECK(spec->usesGbuffer);
    CHECK(spec->usesHit);
    CHECK_FALSE(fa::render::find_rt_effect_spec("rt_shadow")->usesHit);
    CHECK(k->msl.find("kernel void rt_reflect") != std::string_view::npos);
    CHECK_FALSE(k->dxil.empty());
    CHECK_FALSE(k->spirv.empty());
    for (gpu::Backend backend :
         {gpu::Backend::Metal, gpu::Backend::Recording, gpu::Backend::D3d12, gpu::Backend::Vulkan}) {
        INFO("backend " << int(backend));
        const gpu::ShaderDesc d = fa::render::rt_effect_shader_desc(*k, *spec, backend);
        REQUIRE(d.compute());
        CHECK(d.usesRayQuery);
        CHECK(d.uniformBlocks[0].size == sizeof(RtEffectParams));
        CHECK(d.uniformBlocks[0].binding.hlslRegister == 0);
        CHECK(d.uniformBlocks[0].binding.mslIndex == 1);
        CHECK(d.uniformBlocks[0].binding.spirvBinding == 2);
        // The second block: b1 / buffer(3) / binding 7 (rt_hit.hlsli, rt_hit.msli).
        CHECK(d.uniformBlocks[fa::render::RtEffectBindings::kUniformHit].stage == gpu::ShaderStage::Compute);
        CHECK(d.uniformBlocks[fa::render::RtEffectBindings::kUniformHit].size == sizeof(fa::render::RtHitParams));
        CHECK(d.uniformBlocks[fa::render::RtEffectBindings::kUniformHit].binding.hlslRegister == 1);
        CHECK(d.uniformBlocks[fa::render::RtEffectBindings::kUniformHit].binding.mslIndex == 3);
        CHECK(d.uniformBlocks[fa::render::RtEffectBindings::kUniformHit].binding.spirvBinding == 7);
        CHECK(d.views[2].storageBuffer.binding.hlslRegister == 2);
        CHECK(d.views[2].storageBuffer.binding.mslIndex == 8);
        CHECK(d.views[2].storageBuffer.binding.spirvBinding == 4);
        CHECK(d.views[3].texture.binding.mslIndex == 2);
        CHECK(d.views[4].texture.binding.mslIndex == 3);
    }
    // A kernel without the hit constants has no second block.
    const gpu::ShaderDesc shadow = fa::render::rt_effect_shader_desc(
        *rt_kernels::find_rt_kernel("rt_shadow"), *fa::render::find_rt_effect_spec("rt_shadow"), gpu::Backend::Metal);
    CHECK(shadow.uniformBlocks[fa::render::RtEffectBindings::kUniformHit].stage == gpu::ShaderStage::None);
    // The sources say the same numbers (the HLSL's registers and Vulkan bindings, the MSL's buffer indices).
    const std::string hlsli = read_repo_file("engine/render/shaders/rt/rt_hit.hlsli");
    CHECK(hlsli.find("[[vk::binding(7, 0)]] ConstantBuffer<RtHitParams> g_hit : register(b1);") != std::string::npos);
    CHECK(hlsli.find("[[vk::binding(4, 0)]] StructuredBuffer<RtInstanceRecord> g_records : register(t2);") !=
          std::string::npos);
    CHECK(hlsli.find("[[vk::binding(0, 0)]] RaytracingAccelerationStructure g_tlas : register(t0);") !=
          std::string::npos);
    CHECK(k->msl.find("constant RtHitParams& hit [[buffer(3)]]") != std::string_view::npos);
    CHECK(k->msl.find("const device RtInstanceRecord* records [[buffer(8)]]") != std::string_view::npos);
}

namespace {

void make_reflect_scene(World& w) {
    make_scene(w);
    // The floor is a mirror (roughness 0), as the lit shader's roughness default is 0.5.
    Entity floor = w.find("floor");
    if (!floor.is_null()) w.get<MeshRenderer>(floor)->roughness = 0.0f;
}

}  // namespace

TEST_CASE("rt reflect: with reflections off nothing is declared, made or kept, with ray tracing on") {
    Rig r;
    render::RayTracingSettings s;
    s.enabled = true;
    s.shadows = render::RtShadows::Off;
    s.reflections = false;
    s.translucency = true;  // another effect keeps ray tracing on
    r.renderer.set_ray_tracing(s);
    World w;
    make_reflect_scene(w);
    for (int i = 0; i < 3; ++i) {
        r.dev->clear_commands();
        r.frame(w);
        CHECK(r.errors().empty());
        CHECK(r.compute_passes().empty());
        const std::vector<std::string> lines = r.lines();
        CHECK(index_of(lines, "gbuffer") < 0);
        CHECK(index_of(lines, "ssr-trace") < 0);
    }
    CHECK(r.effects().empty());
}

TEST_CASE("rt reflect: reflections declare the G-buffer and one compute pass after the TLAS, with the two constants "
          "blocks, and the "
          "reflections' trace pass composites it") {
    Rig r;
    render::RayTracingSettings s;
    s.enabled = true;
    s.shadows = render::RtShadows::Off;
    s.reflections = true;
    r.renderer.set_ray_tracing(s);
    World w;
    make_reflect_scene(w);
    r.frame(w);
    r.dev->clear_commands();
    r.frame(w);
    INFO(r.errors());
    CHECK(r.errors().empty());
    const std::vector<std::string> passes = r.compute_passes();
    REQUIRE(passes.size() == 1);
    CHECK(passes[0].find("rt-reflections") != std::string::npos);
    const std::vector<std::string> lines = r.lines();
    const int tlas = index_of(lines, "build_tlas");
    const int gbuffer = index_of(lines, "begin_pass 'gbuffer'");
    const int refl = index_of(lines, "rt-reflections");
    const int trace = index_of(lines, "begin_pass 'ssr-trace'");
    REQUIRE(tlas >= 0);
    REQUIRE(gbuffer >= 0);
    REQUIRE(refl >= 0);
    REQUIRE(trace >= 0);
    CHECK(tlas < refl);
    CHECK(gbuffer < refl);
    CHECK(refl < trace);
    REQUIRE(std::size_t(refl) + 5 < lines.size());
    CHECK(lines[std::size_t(refl) + 1].find("set_pipeline") != std::string::npos);
    CHECK(lines[std::size_t(refl) + 3].find("set_uniforms 0 400B") != std::string::npos);
    CHECK(lines[std::size_t(refl) + 4].find("set_uniforms 1 96B") != std::string::npos);
    CHECK(lines[std::size_t(refl) + 5].find("dispatch 20 12 1") != std::string::npos);
    CHECK(r.count(gpu::CommandKind::Dispatch) == 1);
    CHECK(r.effects().image_count() == 1);
    CHECK(r.effects().kernel_count() == 1);
    // Free again when it is turned off.
    s.reflections = false;
    s.translucency = true;
    r.renderer.set_ray_tracing(s);
    for (int i = 0; i < 6; ++i) r.frame(w);
    CHECK(r.effects().image_count() == 0);
    CHECK(r.effects().kernel_count() == 0);
    r.dev->clear_commands();
    r.frame(w);
    CHECK(r.compute_passes().empty());
    CHECK(index_of(r.lines(), "ssr-trace") < 0);
}

TEST_CASE("rt reflect: the shadows and the reflections are two effects of the same frame, and the frame is the same "
          "every frame") {
    Rig r;
    render::RayTracingSettings s;
    s.enabled = true;
    s.shadows = render::RtShadows::Hard;
    s.reflections = true;
    r.renderer.set_ray_tracing(s);
    World w;
    make_reflect_scene(w);
    r.frame(w);
    r.frame(w);
    r.dev->clear_commands();
    r.frame(w);
    CHECK(r.compute_passes().size() == 2);
    const std::vector<std::string> a = r.lines();
    CHECK(r.effects().kernel_count() == 2);
    r.dev->clear_commands();
    r.frame(w);
    CHECK(r.lines() == a);
    CHECK(r.errors().empty());
}

TEST_CASE(
    "rt reflect: a device that cannot trace says so once and draws the frame it would draw with ray tracing off") {
    Logs log;
    auto stream = [&](bool deviceTraces, bool setting) {
        Rig r(deviceTraces);
        if (setting) {
            render::RayTracingSettings s;
            s.enabled = true;
            s.reflections = true;
            r.renderer.set_ray_tracing(s);
        }
        World w;
        make_reflect_scene(w);
        r.frame(w);
        r.frame(w);
        r.dev->clear_commands();
        r.frame(w);
        CHECK(r.errors().empty());
        CHECK(r.compute_passes().empty());
        CHECK(r.effects().empty());
        return r.lines();
    };
    const std::vector<std::string> off = stream(true, false);
    const std::vector<std::string> unsupported = stream(false, true);
    REQUIRE(off.size() > 5);
    CHECK(off == unsupported);
    CHECK(log.count("cannot trace rays") == 1);
    CHECK(log.count("ray traced reflections cannot run") == 0);
    CHECK(index_of(off, "gbuffer") < 0);
}

TEST_CASE(
    "rt reflect: the glossy reflections are denoised as two signals between the kernel and the composite, and the "
    "denoiser is free when they are off") {
    Rig r;
    render::RayTracingSettings s;
    s.enabled = true;
    s.shadows = render::RtShadows::Off;
    s.reflections = true;
    s.raysPerPixel = 4;
    r.renderer.set_ray_tracing(s);
    World w;
    make_reflect_scene(w);
    r.frame(w);
    r.dev->clear_commands();
    r.frame(w);
    INFO(r.errors());
    CHECK(r.errors().empty());
    const std::vector<std::string> lines = r.lines();
    const int refl = index_of(lines, "rt-reflections");
    const int temporal = index_of(lines, "rtd-temporal");
    const int trace = index_of(lines, "begin_pass 'ssr-trace'");
    REQUIRE(refl >= 0);
    REQUIRE(temporal >= 0);
    REQUIRE(trace >= 0);
    CHECK(refl < temporal);
    CHECK(temporal < trace);
    // Two signals (the radiance and its coverage): two temporal passes, one camera guide pass, and still one traced dispatch.
    CHECK(count_labels(lines, "begin_pass 'rtd-temporal") == 2);
    CHECK(count_labels(lines, "begin_pass 'rtd-guide") == 1);
    CHECK(r.count(gpu::CommandKind::Dispatch) == 1);
    CHECK(r.compute_passes().size() == 1);
    const auto* denoiser = RendererTestAccess::rt_denoiser(r.renderer);
    REQUIRE(denoiser != nullptr);
    CHECK(denoiser->shaders_made());
    const int historyImages = denoiser->history_image_count();
    CHECK(historyImages >= 8);  // four per signal and the camera's guide
    // The same frame every frame, whatever the number of rays.
    r.dev->clear_commands();
    r.frame(w);
    const std::vector<std::string> a = r.lines();
    r.dev->clear_commands();
    r.frame(w);
    CHECK(r.lines() == a);
    // Off: the denoiser frees its history (swept) and the passes are gone; ray tracing stays on for another effect.
    s.reflections = false;
    s.translucency = true;
    r.renderer.set_ray_tracing(s);
    for (int i = 0; i < 6; ++i) r.frame(w);
    CHECK(denoiser->history_image_count() == 0);
    r.dev->clear_commands();
    r.frame(w);
    CHECK(count_labels(r.lines(), "rtd-") == 0);
    CHECK(index_of(r.lines(), "ssr-trace") < 0);
    // On again: a new history (the first frame of a signal starts from nothing).
    s.reflections = true;
    r.renderer.set_ray_tracing(s);
    r.frame(w);
    r.dev->clear_commands();
    r.frame(w);
    CHECK(count_labels(r.lines(), "begin_pass 'rtd-temporal") == 2);
    CHECK(denoiser->history_image_count() == historyImages);
    CHECK(r.errors().empty());
}

TEST_CASE(
    "rt reflect: on a device that cannot trace there are no traced reflections and no denoiser, and the screen-space "
    "ones stay") {
    Logs log;
    Rig r(false);
    render::RayTracingSettings s;
    s.enabled = true;
    s.reflections = true;
    s.raysPerPixel = 8;
    r.renderer.set_ray_tracing(s);
    World w;
    make_reflect_scene(w);
    r.frame(w);
    r.frame(w);
    r.dev->clear_commands();
    r.frame(w);
    CHECK(r.errors().empty());
    CHECK(count_labels(r.lines(), "rtd-") == 0);
    CHECK(count_labels(r.lines(), "rt-reflections") == 0);
    const auto* denoiser = RendererTestAccess::rt_denoiser(r.renderer);
    REQUIRE(denoiser != nullptr);
    CHECK_FALSE(denoiser->shaders_made());
    CHECK(denoiser->history_image_count() == 0);
    CHECK(r.effects().empty());
}

// ---- M79-P3b: ray traced translucency (rt_refract) ----------------------------------------------------------------------------------------

namespace {

// The reflect scene plus a glass ball in front of the box: a transmissive mesh with a thickness and a tint.
void make_glass_scene(World& w) {
    make_scene(w);
    Entity glass = make(w, "glass", {0, 1.5f, 4});
    auto& mr = w.add<MeshRenderer>(glass);
    mr.mesh = "sphere";
    mr.transmission = 1.0f;
    mr.thickness = 0.5f;
    mr.roughness = 0.1f;
}

void translucency_rays(Rig& r, bool translucency) {
    render::RayTracingSettings s;
    s.enabled = true;
    s.shadows = render::RtShadows::Off;
    s.translucency = translucency;
    r.renderer.set_ray_tracing(s);
}

}  // namespace

TEST_CASE(
    "rt translucency: the kernel has a spec that asks for the records and the hit constants and not the G-buffer, with "
    "the bindings of the contract in every backend's numbering") {
    const rt_kernels::RtKernel* k = rt_kernels::find_rt_kernel("rt_refract");
    REQUIRE(k != nullptr);
    const fa::render::RtEffectKernelSpec* spec = fa::render::find_rt_effect_spec("rt_refract");
    REQUIRE(spec != nullptr);
    CHECK(spec->usesRecords);
    CHECK_FALSE(spec->usesGbuffer);
    CHECK(spec->usesHit);
    CHECK(spec->usesTlas);
    CHECK_FALSE(spec->usesAux);
    CHECK(k->msl.find("kernel void rt_refract") != std::string_view::npos);
    CHECK_FALSE(k->dxil.empty());
    CHECK_FALSE(k->spirv.empty());
    for (gpu::Backend backend :
         {gpu::Backend::Metal, gpu::Backend::Recording, gpu::Backend::D3d12, gpu::Backend::Vulkan}) {
        INFO("backend " << int(backend));
        const gpu::ShaderDesc d = fa::render::rt_effect_shader_desc(*k, *spec, backend);
        REQUIRE(d.compute());
        CHECK(d.usesRayQuery);
        CHECK(d.uniformBlocks[0].size == sizeof(RtEffectParams));
        CHECK(d.uniformBlocks[0].binding.mslIndex == 1);
        CHECK(d.uniformBlocks[0].binding.spirvBinding == 2);
        CHECK(d.uniformBlocks[fa::render::RtEffectBindings::kUniformHit].size == sizeof(fa::render::RtHitParams));
        CHECK(d.uniformBlocks[fa::render::RtEffectBindings::kUniformHit].binding.mslIndex == 3);
        CHECK(d.uniformBlocks[fa::render::RtEffectBindings::kUniformHit].binding.spirvBinding == 7);
        CHECK(d.views[1].texture.binding.mslIndex == 1);  // the prepass
        CHECK(d.views[2].storageBuffer.binding.mslIndex == 8);
        CHECK(d.views[2].storageBuffer.binding.spirvBinding == 4);
        CHECK(d.views[3].stage() == gpu::ShaderStage::None);  // no G-buffer
        CHECK(d.views[4].stage() == gpu::ShaderStage::None);
    }
    // The sources say the same numbers.
    const std::string hlsl = read_repo_file("engine/render/shaders/rt/rt_refract.hlsl");
    CHECK(hlsl.find(
              "[[vk::binding(1, 0)]] [[vk::image_format(\"rgba32f\")]] RWTexture2D<float4> g_out : register(u0);") !=
          std::string::npos);
    CHECK(hlsl.find("[[vk::binding(3, 0)]] Texture2D<float4> g_prepass : register(t1);") != std::string::npos);
    CHECK(k->msl.find("constant RtHitParams& hit [[buffer(3)]]") != std::string_view::npos);
    CHECK(k->msl.find("const device RtInstanceRecord* records [[buffer(8)]]") != std::string_view::npos);
    CHECK(k->msl.find("texture2d<float, access::read> prepass [[texture(1)]]") != std::string_view::npos);
    // RtEffectParams is the same struct in the kernel's two sources.
    const std::vector<std::string> cpp(std::begin(fa::render::kRtEffectParamNames),
                                       std::end(fa::render::kRtEffectParamNames));
    CHECK(struct_fields(hlsl) == cpp);
    CHECK(struct_fields(std::string(k->msl)) == cpp);
}

TEST_CASE(
    "rt translucency: off, or with no glass in the scene, nothing is declared, made or kept, with ray tracing on") {
    for (bool glass : {true, false}) {
        INFO("glass " << glass);
        Rig r;
        r.renderer.set_ray_tracing([&] {
            render::RayTracingSettings s;
            s.enabled = true;
            s.shadows = render::RtShadows::Off;
            s.ao = glass;  // another effect keeps ray tracing on when the translucency is off
            s.translucency = !glass;
            return s;
        }());
        World w;
        if (glass)
            make_glass_scene(w);
        else
            make_scene(w);
        for (int i = 0; i < 3; ++i) {
            r.dev->clear_commands();
            r.frame(w);
            CHECK(r.errors().empty());
            for (const std::string& p : r.compute_passes()) CHECK(p.find("translucency") == std::string::npos);
        }
        CHECK(index_of(r.lines(), "rt-translucency") < 0);
        if (!glass) {
            CHECK(r.compute_passes().empty());
            CHECK(r.effects().empty());
        }
    }
}

TEST_CASE(
    "rt translucency: glass declares one compute pass after the TLAS and before the refraction copy, which gets its "
    "image, and the frame is the same every frame") {
    Rig r;
    translucency_rays(r, true);
    World w;
    make_glass_scene(w);
    warm(r, w);
    r.dev->clear_commands();
    r.frame(w);
    INFO(r.errors());
    CHECK(r.errors().empty());
    const std::vector<std::string> passes = r.compute_passes();
    REQUIRE(passes.size() == 1);
    CHECK(passes[0].find("rt-translucency") != std::string::npos);
    const std::vector<std::string> lines = r.lines();
    const int tlas = index_of(lines, "build_tlas");
    const int refr = index_of(lines, "rt-translucency");
    const int atlas = index_of(lines, "begin_pass 'xmit-atlas'");
    REQUIRE(tlas >= 0);
    REQUIRE(refr >= 0);
    REQUIRE(atlas >= 0);
    CHECK(tlas < refr);
    CHECK(refr < atlas);
    REQUIRE(std::size_t(refr) + 5 < lines.size());
    CHECK(lines[std::size_t(refr) + 1].find("set_pipeline") != std::string::npos);
    CHECK(lines[std::size_t(refr) + 3].find("set_uniforms 0 400B") != std::string::npos);
    CHECK(lines[std::size_t(refr) + 4].find("set_uniforms 1 96B") != std::string::npos);
    CHECK(lines[std::size_t(refr) + 5].find("dispatch 20 12 1") != std::string::npos);
    CHECK(r.count(gpu::CommandKind::Dispatch) == 1);
    CHECK(r.effects().image_count() == 1);
    CHECK(r.effects().kernel_count() == 1);
    // Deterministic: no clock, no random number.
    r.dev->clear_commands();
    r.frame(w);
    CHECK(r.lines() == lines);
    // Free again when it is turned off, and with ray tracing off.
    translucency_rays(r, false);
    for (int i = 0; i < 6; ++i) r.frame(w);
    CHECK(r.effects().image_count() == 0);
    CHECK(r.effects().kernel_count() == 0);
}

TEST_CASE(
    "rt translucency: a device that cannot trace says so once and draws the frame it would draw with ray tracing off") {
    Logs log;
    auto stream = [&](bool deviceTraces, bool setting) {
        Rig r(deviceTraces);
        if (setting) translucency_rays(r, true);
        World w;
        make_glass_scene(w);
        r.frame(w);
        r.frame(w);
        r.dev->clear_commands();
        r.frame(w);
        CHECK(r.errors().empty());
        CHECK(r.compute_passes().empty());
        CHECK(r.effects().empty());
        return r.lines();
    };
    const std::vector<std::string> off = stream(true, false);
    const std::vector<std::string> unsupported = stream(false, true);
    REQUIRE(off.size() > 5);
    CHECK(off == unsupported);
    CHECK(log.count("cannot trace rays") == 1);
    CHECK(log.count("ray traced translucency cannot run") == 0);
}

// ---- M79-P5a: the path traced reference mode (shaders/rt/rt_pathtrace.{hlsl,metal}, docs/design/ARCHITECTURE_RT_PATHTRACER.md) --------------------------------------

#include "rt_pathtrace.h"

namespace {

void path_rays(Rig& r, bool enabled, int maxBounces = 4, int samplesPerFrame = 1, int maxSamples = 0) {
    render::PathTracerSettings s;
    s.enabled = enabled;
    s.maxBounces = maxBounces;
    s.samplesPerFrame = samplesPerFrame;
    s.maxSamples = maxSamples;
    r.renderer.set_path_tracer(s);
}

}  // namespace

TEST_CASE("rt pathtrace: off declares nothing and costs nothing, with ray tracing on or off") {
    for (bool rayTracingOn : {false, true}) {
        INFO("render.rayTracing.enabled " << rayTracingOn);
        Rig r;
        if (rayTracingOn) {
            render::RayTracingSettings s;
            s.enabled = true;
            s.shadows = render::RtShadows::Off;
            s.ao = false;
            r.renderer.set_ray_tracing(s);
        }
        path_rays(r, false);
        World w;
        make_scene(w);
        for (int i = 0; i < 3; ++i) {
            r.dev->clear_commands();
            r.frame(w);
            CHECK(r.errors().empty());
            CHECK(r.compute_passes().empty());
            CHECK(r.count(gpu::CommandKind::Dispatch) == 0);
        }
        CHECK(r.effects().empty());
        CHECK(r.effects().image_count() == 0);
        CHECK(r.effects().kernel_count() == 0);
        const render::PathTracerStatus st = r.renderer.path_tracer_status();
        CHECK_FALSE(st.active);
        CHECK(st.samples == 0);
        CHECK(st.failure.empty());
    }
}

TEST_CASE("rt pathtrace: on, one compute pass after the TLAS and the prepass with the three constants blocks, the same "
          "every frame, "
          "with render.rayTracing off") {
    Rig r;
    path_rays(r, true, 3, 2);
    World w;
    make_scene(w);
    r.frame(w);  // the first frame builds the BLASes
    r.dev->clear_commands();
    r.frame(w);
    INFO(r.errors());
    CHECK(r.errors().empty());
    const std::vector<std::string> passes = r.compute_passes();
    REQUIRE(passes.size() == 1);
    CHECK(passes[0].find("rt-pathtrace") != std::string::npos);
    const std::vector<std::string> lines = r.lines();
    const int tlas = index_of(lines, "build_tlas");
    const int prepass = index_of(lines, "begin_pass 'prepass'");
    const int trace = index_of(lines, "rt-pathtrace");
    const int game = index_of(lines, "begin_pass 'game'");
    REQUIRE(tlas >= 0);
    REQUIRE(prepass >= 0);
    REQUIRE(trace >= 0);
    REQUIRE(game >= 0);
    CHECK(tlas < trace);
    CHECK(prepass < trace);
    CHECK(trace < game);
    // The kernel reads and writes its image (the running mean), reads the records and the prepass, and takes the params (400 B), the hit block
    // (96 B) and the lights block (528 B).
    int params = 0, hit = 0, lightsBlock = 0;
    for (std::size_t i = std::size_t(trace); i < std::size_t(game); ++i) {
        params += lines[i].find("set_uniforms 0 400B") != std::string::npos ? 1 : 0;
        hit += lines[i].find("set_uniforms 1 96B") != std::string::npos ? 1 : 0;
        lightsBlock += lines[i].find("set_uniforms 2 528B") != std::string::npos ? 1 : 0;
    }
    CHECK(params == 1);
    CHECK(hit == 1);
    CHECK(lightsBlock == 1);
    CHECK(r.count(gpu::CommandKind::Dispatch) == 1);
    CHECK(r.effects().image_count() == 1);
    CHECK(r.effects().kernel_count() == 1);
    const render::PathTracerStatus st = r.renderer.path_tracer_status();
    CHECK(st.active);
    CHECK(st.width == 160);
    CHECK(st.height == 96);
    CHECK(st.samples == 4);  // two frames of two samples
    CHECK(st.failure.empty());
    // Nothing moves, so the accumulation goes on: the frame's commands are the same (the sample counter is in the constants, not the commands).
    r.dev->clear_commands();
    r.frame(w);
    const std::vector<std::string> a = r.lines();
    r.dev->clear_commands();
    r.frame(w);
    CHECK(a == r.lines());
    CHECK(r.renderer.path_tracer_status().samples == 8);
    CHECK(r.renderer.path_tracer_status().resets == 0);
}

TEST_CASE("rt pathtrace: turning it off frees the kernel and the image, and the accumulation starts over when it comes "
          "back") {
    Rig r;
    path_rays(r, true);
    World w;
    make_scene(w);
    for (int i = 0; i < 4; ++i) r.frame(w);
    CHECK(r.effects().image_count() == 1);
    CHECK(r.renderer.path_tracer_status().samples >= 2);
    path_rays(r, false);
    for (int i = 0; i < 6; ++i) r.frame(w);
    CHECK(r.effects().image_count() == 0);
    CHECK(r.effects().kernel_count() == 0);
    CHECK(r.renderer.path_tracer_status().samples == 0);
    CHECK_FALSE(r.renderer.path_tracer_status().active);
    path_rays(r, true);
    r.frame(w);
    r.frame(w);
    CHECK(r.renderer.path_tracer_status().samples == 1 + 1);
}

TEST_CASE(
    "rt pathtrace: a device that cannot trace says so once and draws the frame it would draw with the setting off") {
    Logs log;
    auto stream = [&](bool deviceTraces, bool setting) {
        Rig r(deviceTraces);
        if (setting) path_rays(r, true);
        World w;
        make_scene(w);
        r.frame(w);
        r.frame(w);
        r.dev->clear_commands();
        r.frame(w);
        CHECK(r.errors().empty());
        CHECK(r.compute_passes().empty());
        CHECK(r.effects().empty());
        CHECK_FALSE(r.renderer.path_tracer_status().active);
        return r.lines();
    };
    const std::vector<std::string> off = stream(true, false);
    CHECK(log.count("cannot trace rays") == 0);
    const std::vector<std::string> unsupported = stream(false, true);
    REQUIRE(off.size() > 5);
    CHECK(off == unsupported);
    CHECK(log.count("cannot trace rays") == 1);
}

TEST_CASE("rt pathtrace: maxSamples holds the image, and a camera move, a moved mesh or a setting change start it "
          "over with the reason") {
    Rig r;
    path_rays(r, true, 4, 1, 3);
    World w;
    make_scene(w);
    for (int i = 0; i < 8; ++i) r.frame(w);
    CHECK(r.renderer.path_tracer_status().samples == 3);  // held there
    const int resets = r.renderer.path_tracer_status().resets;
    // A camera move.
    w.get<Transform>(w.find("cam"))->position = {0.5f, 3.0f, 12.0f};
    r.frame(w);
    CHECK(r.renderer.path_tracer_status().lastReset == "camera");
    CHECK(r.renderer.path_tracer_status().resets == resets + 1);
    CHECK(r.renderer.path_tracer_status().samples == 1);
    r.frame(w);
    CHECK(r.renderer.path_tracer_status().samples == 2);
    // The scene: a mesh moves.
    w.get<Transform>(w.find("box"))->position = {1.0f, 1.0f, 0.0f};
    r.frame(w);
    r.frame(w);
    CHECK(r.renderer.path_tracer_status().lastReset == "scene");
    CHECK(r.renderer.path_tracer_status().samples <= 2);
    // The settings (maxBounces).
    for (int i = 0; i < 4; ++i) r.frame(w);
    const int before = r.renderer.path_tracer_status().resets;
    path_rays(r, true, 6, 1, 3);
    r.frame(w);
    CHECK(r.renderer.path_tracer_status().lastReset == "settings");
    CHECK(r.renderer.path_tracer_status().resets == before + 1);
    CHECK(r.renderer.path_tracer_status().samples == 1);
}

TEST_CASE("rt pathtrace: path_trace_step starts, holds and resets for the reason that changed, in this order") {
    using fa::render::path_trace_step;
    using fa::render::PathTraceJobState;
    render::PathTracerSettings cfg;
    cfg.samplesPerFrame = 4;
    cfg.maxSamples = 10;
    PathTraceJobState st;
    auto step = [&](std::uint64_t cam, std::uint64_t scene, std::uint64_t settings, std::uint64_t image, int w = 64,
                    int h = 48) { return path_trace_step(st, cfg, cam, scene, settings, image, w, h); };
    auto s = step(1, 2, 3, 7);
    CHECK(s.reset == "start");
    CHECK(s.firstSample == 0);
    CHECK(s.count == 4);
    s = step(1, 2, 3, 7);
    CHECK(s.reset.empty());
    CHECK(s.firstSample == 4);
    CHECK(s.count == 4);
    s = step(1, 2, 3, 7);  // 8 so far: two more, then held
    CHECK(s.firstSample == 8);
    CHECK(s.count == 2);
    s = step(1, 2, 3, 7);
    CHECK(s.what == fa::render::RtPrepare::Hold);
    CHECK(s.count == 0);
    CHECK(st.samples == 10);
    s = step(9, 2, 3, 7);
    CHECK(s.reset == "camera");
    CHECK(s.firstSample == 0);
    CHECK(s.what == fa::render::RtPrepare::Dispatch);
    s = step(9, 5, 3, 7);
    CHECK(s.reset == "scene");
    s = step(9, 5, 4, 7);
    CHECK(s.reset == "settings");
    s = step(9, 5, 4, 8);  // the image was made again
    CHECK(s.reset == "image");
    s = step(9, 5, 4, 8, 80, 48);
    CHECK(s.reset == "image");
    CHECK(st.samples == 4);
    // The sample index is never the wall clock: the same calls give the same steps.
    PathTraceJobState other;
    auto s0 = path_trace_step(other, cfg, 1, 2, 3, 7, 64, 48);
    CHECK(s0.firstSample == 0);
    CHECK(s0.count == 4);
}

TEST_CASE("rt pathtrace: the kernel table has rt_pathtrace, and the lights block, the hit block and the image are "
          "bound in every backend's numbering") {
    const rt_kernels::RtKernel* k = rt_kernels::find_rt_kernel("rt_pathtrace");
    REQUIRE(k != nullptr);
    const fa::render::RtEffectKernelSpec* spec = fa::render::find_rt_effect_spec("rt_pathtrace");
    REQUIRE(spec != nullptr);
    CHECK(spec->usesRecords);
    CHECK(spec->usesHit);
    CHECK(spec->usesTlas);
    CHECK(spec->usesLights);
    CHECK(spec->readsOut);
    CHECK_FALSE(spec->usesGbuffer);
    CHECK_FALSE(spec->usesAux);
    for (gpu::Backend backend :
         {gpu::Backend::Metal, gpu::Backend::Recording, gpu::Backend::D3d12, gpu::Backend::Vulkan}) {
        INFO("backend " << int(backend));
        const gpu::ShaderDesc d = fa::render::rt_effect_shader_desc(*k, *spec, backend);
        REQUIRE(d.compute());
        CHECK(d.usesRayQuery);
        CHECK(d.uniformBlocks[0].size == sizeof(RtEffectParams));
        CHECK(d.uniformBlocks[1].size == sizeof(fa::render::RtHitParams));
        CHECK(d.uniformBlocks[1].binding.hlslRegister == 1);
        CHECK(d.uniformBlocks[1].binding.mslIndex == 3);
        CHECK(d.uniformBlocks[1].binding.spirvBinding == 7);
        CHECK(d.uniformBlocks[2].size == sizeof(fa::render::RtLightParams));
        CHECK(d.uniformBlocks[2].size == 528);
        CHECK(d.uniformBlocks[2].binding.hlslRegister == 2);
        CHECK(d.uniformBlocks[2].binding.mslIndex == 4);
        CHECK(d.uniformBlocks[2].binding.spirvBinding == 8);
        // The image is read as well as written: not a write-only storage image.
        CHECK_FALSE(d.views[0].storageImage.writeonly);
        CHECK(d.views[2].storageBuffer.binding.mslIndex == 8);
        CHECK(d.views[2].storageBuffer.binding.spirvBinding == 4);
    }
    // The three blocks the kernels declare have the field names the C++ struct has.
    const std::string hlsl = read_repo_file("engine/render/shaders/rt/rt_pathtrace.hlsl");
    const std::string msl = read_repo_file("engine/render/shaders/rt/rt_pathtrace.metal");
    REQUIRE_FALSE(hlsl.empty());
    REQUIRE_FALSE(msl.empty());
    for (std::string_view name : fa::render::kRtLightParamNames) {
        CHECK(hlsl.find(std::string(name)) != std::string::npos);
        CHECK(msl.find(std::string(name)) != std::string::npos);
    }
    CHECK(hlsl.find("// BEGIN RtLightParams") != std::string::npos);
    CHECK(msl.find("// BEGIN RtLightParams") != std::string::npos);
}

TEST_CASE("rt pathtrace: the settings parse with a pointer to the wrong key, clamp what is out of range and round trip "
          "through JSON") {
    using namespace fa::render;
    const PathTracerSettings base;
    CHECK_FALSE(base.enabled);
    auto ok = parse_path_tracer_settings(
        Json::parse(
            R"({"enabled":true,"maxBounces":99,"samplesPerFrame":0,"maxSamples":-4,"fireflyClamp":-3,"seed":7})"),
        "/render/pathTracer", base);
    REQUIRE(ok.ok());
    CHECK(ok.value().enabled);
    CHECK(ok.value().maxBounces == kPtMaxMaxBounces);
    CHECK(ok.value().samplesPerFrame == kPtMinSamplesPerFrame);
    CHECK(ok.value().maxSamples == 0);
    CHECK(ok.value().fireflyClamp == 0.0f);
    CHECK(ok.value().seed == 7);
    auto back = parse_path_tracer_settings(path_tracer_to_json(ok.value()), "/x", base);
    REQUIRE(back.ok());
    CHECK(back.value() == ok.value());
    auto typo = parse_path_tracer_settings(Json::parse(R"({"maxBounce":3})"), "/render/pathTracer", base);
    REQUIRE_FALSE(typo.ok());
    CHECK(typo.error().message.find("/render/pathTracer/maxBounce") != std::string::npos);
    CHECK(typo.error().hint.find("maxBounces") != std::string::npos);
    auto wrongType = parse_path_tracer_settings(Json::parse(R"({"enabled":"yes"})"), "/render/pathTracer", base);
    REQUIRE_FALSE(wrongType.ok());
    CHECK(wrongType.error().message.find("/render/pathTracer/enabled") != std::string::npos);
    auto notObject = parse_path_tracer_settings(Json::parse("3"), "/render/pathTracer", base);
    REQUIRE_FALSE(notObject.ok());
}
