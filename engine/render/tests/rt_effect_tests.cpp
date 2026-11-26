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

// The field names between `// BEGIN RtEffectParams` and `// END RtEffectParams` of a kernel source, in order.
std::vector<std::string> struct_fields(const std::string& source) {
    const std::size_t b = source.find("// BEGIN RtEffectParams");
    const std::size_t e = source.find("// END RtEffectParams");
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
        if (tok == "struct" || tok == "RtEffectParams" || tok == "float4" || tok == "uint4") continue;
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
        CHECK(rec.binding.mslIndex == 2);
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
    // Whatever the first frame had in the TLAS, a caster without a BLAS (skippedNoBlas) is counted as untraced, so the two always agree.
    if (RendererTestAccess::rt_scene(r.renderer)->stats().skippedNoBlas > 0) {
        CHECK(firstUntraced > 0);
        CHECK(first.withCascades == first.mask);
    }
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
    CHECK(body.find("fwidth(") != std::string::npos);
    // fa_ct_b.z is read in that function and nowhere else: the local lights never see the mask or the min.
    CHECK(glsl.find("fa_ct_b.z", fn + body.size()) == std::string::npos);
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
