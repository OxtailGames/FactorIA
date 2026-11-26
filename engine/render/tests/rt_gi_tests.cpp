// M79-P4a: the realtime GI probes updated by rays (src/rt_gi.h, shaders/rt/rt_gi.{hlsl,metal}; docs/design/ARCHITECTURE_RT_GI.md). Here, on every
// host: the constants block and the binding contract shared by the HLSL and the MSL, the CPU twin of the kernel's ray set, and the renderer's
// frame on the RecordingDevice (nothing with the setting off, the budget of probes a frame, the probes blended into the atlas, the raster
// captures on a device that cannot trace). The kernel runs for real in rt_gi_metal_tests.cpp.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <fstream>
#include <iterator>
#include <set>
#include <sstream>
#include <string>
#include <vector>

#include "fa/render/gi.h"
#include "fa/render/raytracing.h"
#include "gpu/recording_device.h"
#include "renderer_test_access.h"
#include "rt_effect.h"
#include "rt_gi.h"
#include "rt_kernels.h"

using namespace fa;
using namespace fa::test;
using fa::render::RtGiParams;

namespace {

std::string read_repo_file(const std::string& relative) {
    std::ifstream in(std::string(FA_REPO_ROOT) + "/" + relative, std::ios::binary);
    return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
}

// The field names between `// BEGIN RtGiParams` and `// END RtGiParams` of a kernel source, in order.
std::vector<std::string> gi_struct_fields(const std::string& source) {
    const std::string name = "RtGiParams";
    const std::size_t b = source.find("// BEGIN " + name);
    const std::size_t e = source.find("// END " + name);
    std::vector<std::string> out;
    if (b == std::string::npos || e == std::string::npos || e < b) return out;
    std::string body = source.substr(b, e - b);
    body.erase(0, body.find('\n') + 1);
    std::string clean;
    for (std::size_t i = 0; i < body.size(); ++i) {
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
        // `float4 probe[64]`: the array's size is not a name
        const std::size_t bracket = tok.find('[');
        out.push_back(bracket == std::string::npos ? tok : tok.substr(0, bracket));
    }
    return out;
}

}  // namespace

// ---- the contract shared by the HLSL, the MSL and the renderer -------------------------------------------------------------------------

TEST_CASE("rt gi: RtGiParams is the same struct in C++, HLSL and MSL") {
    const std::vector<std::string> expected(std::begin(render::kRtGiParamNames), std::end(render::kRtGiParamNames));
    REQUIRE(expected.size() == 7);
    const std::string hlsl = read_repo_file("engine/render/shaders/rt/rt_gi.hlsl");
    REQUIRE_FALSE(hlsl.empty());
    CHECK(gi_struct_fields(hlsl) == expected);
    const rt_kernels::RtKernel* k = rt_kernels::find_rt_kernel("rt_gi");
    REQUIRE(k != nullptr);
    CHECK(gi_struct_fields(std::string(k->msl)) == expected);
    CHECK(sizeof(RtGiParams) == 70 * 16);
    CHECK(sizeof(RtGiParams) <= 4096);  // Metal's limit for a uniform block set by bytes
    CHECK(offsetof(RtGiParams, grid0) == 0);
    CHECK(offsetof(RtGiParams, frame) == 4 * 16);
    CHECK(offsetof(RtGiParams, flags) == 5 * 16);
    CHECK(offsetof(RtGiParams, probe) == 6 * 16);
    CHECK(render::kRtGiMaxJobs == render::kGiRtMaxFrameProbes);
}

TEST_CASE("rt gi: the kernel table has rt_gi, a spec that asks for the records, and the binding contract of every backend") {
    const rt_kernels::RtKernel* k = rt_kernels::find_rt_kernel("rt_gi");
    REQUIRE(k != nullptr);
    const render::RtEffectKernelSpec* spec = render::find_rt_effect_spec("rt_gi");
    REQUIRE(spec != nullptr);
    CHECK(spec->usesTlas);
    CHECK(spec->usesRecords);
    CHECK_FALSE(spec->usesGbuffer);
    CHECK(spec->paramsSize == sizeof(RtGiParams));
    CHECK(spec->outHalf);
    CHECK(k->msl.find("kernel void rt_gi") != std::string_view::npos);
    // One query site: Metal's compiler unrolls a kernel that has several (docs/design/ARCHITECTURE_RT_EFFECTS.md).
    std::size_t sites = 0;
    for (std::size_t at = k->msl.find("intersection_query<"); at != std::string_view::npos;
         at = k->msl.find("intersection_query<", at + 1))
        ++sites;
    CHECK(sites == 1);
    for (gpu::Backend backend :
         {gpu::Backend::Metal, gpu::Backend::Recording, gpu::Backend::D3d12, gpu::Backend::Vulkan}) {
        INFO("backend " << int(backend));
        const gpu::ShaderDesc d = render::rt_effect_shader_desc(*k, *spec, backend);
        REQUIRE(d.compute());
        CHECK(d.usesRayQuery);
        CHECK(d.uniformBlocks[0].size == sizeof(RtGiParams));
        CHECK(d.uniformBlocks[0].binding.hlslRegister == 0);
        CHECK(d.uniformBlocks[0].binding.mslIndex == 1);
        CHECK(d.uniformBlocks[0].binding.spirvBinding == 2);
        const gpu::ShaderStorageImageView& out = d.views[0].storageImage;
        CHECK(out.stage == gpu::ShaderStage::Compute);
        CHECK(out.accessFormat == gpu::PixelFormat::Rgba16F);  // the band image the atlas is blended from
        CHECK(out.binding.spirvBinding == 1);
        // The atlas the multi-bounce reads is the "prepass" slot of the contract.
        CHECK(d.views[1].texture.stage == gpu::ShaderStage::Compute);
        CHECK(d.views[1].texture.binding.hlslRegister == 1);
        CHECK(d.views[1].texture.binding.mslIndex == 1);
        CHECK(d.views[1].texture.binding.spirvBinding == 3);
        CHECK(d.views[2].storageBuffer.binding.mslIndex == 8);  // the records
        CHECK(d.views[2].storageBuffer.binding.spirvBinding == 4);
        CHECK(d.views[3].stage() == gpu::ShaderStage::None);
        if (backend == gpu::Backend::D3d12) CHECK(d.computeFunc.bytecode.size == k->dxil.size());
        if (backend == gpu::Backend::Vulkan) CHECK(d.computeFunc.bytecode.size == k->spirv.size());
        if (backend == gpu::Backend::Metal) CHECK(std::string(d.computeFunc.entry) == "rt_gi");
    }
}

// ---- the kernel's ray set, on the CPU ------------------------------------------------------------------------------------------------

TEST_CASE("rt gi: the rays of a probe are a pure function of the seed and the probe, unit, spread over the sphere") {
    float q[4], again[4], other[4], otherProbe[4];
    render::rt_gi_rotation(77u, 5u, q);
    render::rt_gi_rotation(77u, 5u, again);
    render::rt_gi_rotation(78u, 5u, other);
    render::rt_gi_rotation(77u, 6u, otherProbe);
    for (int i = 0; i < 4; ++i) CHECK(q[i] == again[i]);
    CHECK(std::fabs(q[0] - other[0]) + std::fabs(q[1] - other[1]) + std::fabs(q[2] - other[2]) > 1e-3f);
    CHECK(std::fabs(q[0] - otherProbe[0]) + std::fabs(q[1] - otherProbe[1]) + std::fabs(q[2] - otherProbe[2]) > 1e-3f);
    CHECK(q[0] * q[0] + q[1] * q[1] + q[2] * q[2] + q[3] * q[3] == doctest::Approx(1.0f).epsilon(1e-4));
    for (int n : {16, 64, 256}) {
        Vec3 sum{};
        double xx = 0, yy = 0, zz = 0;
        for (int i = 0; i < n; ++i) {
            const Vec3 d = render::rt_gi_direction(q, std::uint32_t(i), std::uint32_t(n));
            CHECK(length(d) == doctest::Approx(1.0f).epsilon(1e-4));
            sum = sum + d;
            xx += double(d.x) * d.x;
            yy += double(d.y) * d.y;
            zz += double(d.z) * d.z;
        }
        // A Fibonacci set has (almost) no net direction and equal second moments on the three axes: the sky is sampled evenly.
        CHECK(length(sum) / float(n) < 0.08f);
        CHECK(xx / n == doctest::Approx(1.0 / 3.0).epsilon(0.15));
        CHECK(yy / n == doctest::Approx(1.0 / 3.0).epsilon(0.15));
        CHECK(zz / n == doctest::Approx(1.0 / 3.0).epsilon(0.15));
    }
    // Two updates of the same probe trace different directions, so the updates add up to more of the sphere than one.
    float q2[4];
    render::rt_gi_rotation(78u, 5u, q2);
    std::set<std::int64_t> seen;
    for (const float* r : {q, q2}) {
        for (int i = 0; i < 64; ++i) {
            const Vec3 d = render::rt_gi_direction(r, std::uint32_t(i), 64);
            seen.insert(std::int64_t(std::llround(d.x * 1000)) * 4000000 + std::llround(d.y * 1000) * 2000 +
                        std::llround(d.z * 1000));
        }
    }
    CHECK(seen.size() == 128);
}

// ---- the renderer's frame on the RecordingDevice ---------------------------------------------------------------------------------------

namespace {

struct Rig {
    Renderer renderer;
    gpu::RecordingDevice* dev = nullptr;
    explicit Rig(bool deviceTraces = true) {
        gfx();  // the project root of the process
        gpu::DeviceInit init;
        init.recordingRayTracing = deviceTraces;
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
        REQUIRE_MESSAGE(ok, error);
    }
    ~Rig() { renderer.shutdown(); }
    Rig(const Rig&) = delete;
    Rig& operator=(const Rig&) = delete;

    void gi(render::RtGi mode) {
        render::RayTracingSettings s;
        s.enabled = true;
        s.gi = mode;
        renderer.set_ray_tracing(s);
    }
    void frame(World& w) {
        renderer.update(w);
        renderer.begin_frame();
        renderer.render_world(w, 0.0f);
        renderer.end_frame();
    }
    int count(gpu::CommandKind kind) const {
        int n = 0;
        for (const gpu::RecordedCommand& c : dev->commands()) n += c.kind == kind ? 1 : 0;
        return n;
    }
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
    int passes_named(const std::string& label) const {
        int n = 0;
        for (const gpu::RecordedCommand& c : dev->commands())
            if (c.kind == gpu::CommandKind::BeginPass && c.text.find(label) != std::string::npos) ++n;
        return n;
    }
    std::string errors() const {
        std::string s;
        for (const std::string& e : dev->errors()) s += e + "\n";
        return s;
    }
};

// A camera, a floor, a box and a sun, and one grid of 3 x 3 x 1 = 9 probes (a 4 m spacing over 8 x 0 x 8) with `perFrame` rays budget.
void make_scene(World& w, int rtPerFrame = 4, bool withGrid = true) {
    Entity cam = make(w, "cam", {0, 3, 12});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    Entity floor = make(w, "floor", {0, 0, 0});
    w.get<Transform>(floor)->scale = {16, 1, 16};
    w.add<MeshRenderer>(floor).mesh = "plane";
    Entity box = make(w, "box", {0, 1, 0});
    w.add<MeshRenderer>(box).mesh = "cube";
    Entity sun = make(w, "sun", {0, 5, 0});
    w.get<Transform>(sun)->rotation = {-50, 30, 0};
    auto& l = w.add<Light>(sun);
    l.type = LightType::Directional;
    if (withGrid) {
        Entity g = make(w, "gi", {0, 2, 0});
        auto& gi = w.add<RealtimeGI>(g);
        gi.size = {8, 0, 8};
        gi.spacing = 4.0f;
        gi.rtProbesPerFrame = rtPerFrame;
        gi.raysPerProbe = 32;
    }
}

// The report's only grid (the scene has one).
const Json* grid_json(const Json& report, const std::string&) {
    if (!report.contains("grids") || report["grids"].size() != 1) return nullptr;
    return &report["grids"][0];
}

int index_of(const std::vector<std::string>& lines, const std::string& needle) {
    for (std::size_t i = 0; i < lines.size(); ++i)
        if (lines[i].find(needle) != std::string::npos) return int(i);
    return -1;
}

}  // namespace

TEST_CASE("rt gi: with gi off nothing is declared, made or kept, the grids are captured by the raster and ray tracing on") {
    Rig r;
    r.gi(render::RtGi::Off);
    World w;
    make_scene(w);
    for (int i = 0; i < 3; ++i) {
        r.dev->clear_commands();
        r.frame(w);
        CHECK(r.errors().empty());
        CHECK(r.compute_passes().empty());
    }
    CHECK(RendererTestAccess::rt_gi(r.renderer)->empty());
    const render::RtGiStatus st = r.renderer.ray_tracing_gi_status();
    CHECK_FALSE(st.wanted);
    CHECK_FALSE(st.active);
    CHECK(st.probesPerFrame == 0);
}

TEST_CASE("rt gi: gi probes declare one compute pass after the TLAS and blend the probes' blocks into the atlas, up to the budget") {
    Rig r;
    r.gi(render::RtGi::Probes);
    World w;
    make_scene(w, 4);
    r.frame(w);  // the first frames build the BLASes
    r.frame(w);
    r.dev->clear_commands();
    r.frame(w);
    INFO(r.errors());
    CHECK(r.errors().empty());
    const std::vector<std::string> passes = r.compute_passes();
    REQUIRE(passes.size() == 1);
    CHECK(passes[0].find("gi-probes") != std::string::npos);
    const std::vector<std::string> lines = r.lines();
    const int tlas = index_of(lines, "build_tlas");
    const int gi = index_of(lines, "gi-probes");
    const int game = index_of(lines, "begin_pass 'game'");
    REQUIRE(tlas >= 0);
    REQUIRE(gi >= 0);
    CHECK(tlas < gi);
    // The kernel's constants block (1120 bytes) then the hit constants (96 bytes), then one dispatch of one group per probe: 4 probes.
    bool block = false, dispatch = false;
    for (std::size_t i = std::size_t(gi); i < lines.size() && i < std::size_t(gi) + 8; ++i) {
        block = block || lines[i].find("set_uniforms 0 1120B") != std::string::npos;
        dispatch = dispatch || lines[i].find("dispatch 4 1 1") != std::string::npos;
    }
    CHECK(block);
    CHECK(dispatch);
    CHECK(r.count(gpu::CommandKind::Dispatch) == 1);
    // Four probes blended into the atlas, after the graph: one draw each, no raster capture of the grid.
    CHECK(r.passes_named("probe-atlas") >= 4);
    CHECK(r.passes_named("gi:") == 0);
    const render::RtGiStatus st = r.renderer.ray_tracing_gi_status();
    CHECK(st.wanted);
    CHECK(st.active);
    CHECK(st.probesPerFrame == 4);
    CHECK(st.budget == 4);
    CHECK(st.grids == 1);
    // All nine probes have a value after three frames of four.
    r.frame(w);
    const Json report = r.renderer.gi_report();
    INFO(report.dump());
    const Json* grid = grid_json(report, "gi");
    REQUIRE(grid != nullptr);
    CHECK((*grid)["probes"].get<int>() == 9);
    CHECK((*grid)["updatedBy"].get<std::string>() == "rays");
    CHECK((*grid)["raysPerProbe"].get<int>() == 32);
    CHECK((*grid)["rtProbesPerFrame"].get<int>() == 4);
    CHECK((*grid)["captured"].get<int>() == 9);
    CHECK((*grid)["state"].get<std::string>() == "ready");
    CHECK(report["rtUpdates"].get<double>() >= 9.0);
    (void)game;
}

TEST_CASE("rt gi: a bigger budget updates more probes a frame, never more than 64, and the grids share it") {
    Rig r;
    r.gi(render::RtGi::Probes);
    World w;
    make_scene(w, 64);  // asks for 64, the grid has 9
    r.frame(w);
    r.frame(w);
    r.dev->clear_commands();
    r.frame(w);
    CHECK(r.errors().empty());
    render::RtGiStatus st = r.renderer.ray_tracing_gi_status();
    CHECK(st.probesPerFrame == 9);
    // The grid's own budget of 3 is what a frame updates, the longest ago updated first.
    World w2;
    make_scene(w2, 3);
    Rig r2;
    r2.gi(render::RtGi::Probes);
    for (int i = 0; i < 4; ++i) r2.frame(w2);
    st = r2.renderer.ray_tracing_gi_status();
    CHECK(st.probesPerFrame == 3);
    CHECK(st.budget == 3);
}

TEST_CASE("rt gi: the recorded frame is the same every run (the seed is the frame's, no clock, no random number)") {
    std::vector<std::string> first;
    for (int run = 0; run < 2; ++run) {
        Rig r;
        r.gi(render::RtGi::Probes);
        World w;
        make_scene(w, 4);
        r.frame(w);
        r.frame(w);
        r.dev->clear_commands();
        r.frame(w);
        const std::vector<std::string> lines = r.lines();
        if (run == 0)
            first = lines;
        else
            CHECK(lines == first);
    }
    CHECK_FALSE(first.empty());
}

TEST_CASE("rt gi: a device that cannot trace keeps the raster captures and says why, and spends nothing on rays") {
    Rig r(false);
    r.gi(render::RtGi::Probes);
    World w;
    make_scene(w, 4);
    for (int i = 0; i < 3; ++i) {
        r.dev->clear_commands();
        r.frame(w);
        CHECK(r.errors().empty());
        CHECK(r.compute_passes().empty());
    }
    CHECK(RendererTestAccess::rt_gi(r.renderer)->empty());
    const render::RtGiStatus st = r.renderer.ray_tracing_gi_status();
    CHECK(st.wanted);
    CHECK_FALSE(st.active);
    CHECK_FALSE(st.reason.empty());
    // The grid is updated the way it always was.
    const Json report = r.renderer.gi_report();
    INFO(report.dump());
    const Json* grid = grid_json(report, "gi");
    REQUIRE(grid != nullptr);
    CHECK((*grid)["updatedBy"].get<std::string>() == "captures");
}

TEST_CASE("rt gi: turning the setting off frees the band image and the kernel, and a scene without a grid asks for nothing") {
    Rig r;
    r.gi(render::RtGi::Probes);
    World w;
    make_scene(w, 4);
    for (int i = 0; i < 3; ++i) r.frame(w);
    CHECK_FALSE(RendererTestAccess::rt_gi(r.renderer)->empty());
    r.gi(render::RtGi::Off);
    r.frame(w);
    CHECK(RendererTestAccess::rt_gi(r.renderer)->empty());
    r.dev->clear_commands();
    r.frame(w);
    CHECK(r.compute_passes().empty());
    // On again, without a RealtimeGI in the scene: nothing is declared and the status says there is no grid.
    World none;
    make_scene(none, 4, false);
    r.gi(render::RtGi::Probes);
    for (int i = 0; i < 3; ++i) {
        r.dev->clear_commands();
        r.frame(none);
        CHECK(r.compute_passes().empty());
    }
    const render::RtGiStatus st = r.renderer.ray_tracing_gi_status();
    CHECK(st.wanted);
    CHECK_FALSE(st.active);
    CHECK(st.reason.find("RealtimeGI") != std::string::npos);
    CHECK(RendererTestAccess::rt_gi(r.renderer)->empty());
}
