// M79-P2a-3: ray traced shadows of point, spot and area lights (src/rt_local_shadows.{h,cpp}, shaders/rt/rt_shadow_local{,_pack}.{hlsl,metal};
// docs/design/ARCHITECTURE_RT_SHADOWS.md). Here, on every host: the choice of the traced lights and their constants block (pure CPU), the
// shared structs of the HLSL, the MSL and C++, the bindings of the two kernels, and the renderer's frame on the RecordingDevice (nothing when
// off, the cap and its reason, the fallback of a device that cannot trace, the history of a slot that changes lights). The kernel runs for real
// in rt_shadow_local_metal_tests.cpp.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <fstream>
#include <iterator>
#include <limits>
#include <map>
#include <memory>
#include <mutex>
#include <sstream>
#include <string>
#include <vector>

#include "fa/core/log.h"
#include "fa/render/raytracing.h"
#include "gpu/recording_device.h"
#include "renderer_test_access.h"
#include "rt_denoise.h"
#include "rt_effect.h"
#include "rt_kernels.h"
#include "rt_local_shadows.h"
#include "rt_scene.h"

using namespace fa;
using namespace fa::test;
using fa::render::LightData;
using fa::render::RtEffects;
using fa::render::RtLocalCandidate;
using fa::render::RtLocalLight;
using fa::render::RtLocalParams;
using fa::render::RtLocalPick;
using fa::render::RtLocalSlots;

namespace {

std::string read_repo_file(const std::string& relative) {
    std::ifstream in(std::string(FA_REPO_ROOT) + "/" + relative, std::ios::binary);
    return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
}

// The field names between `// BEGIN <name>` and `// END <name>` of a kernel source, in order.
std::vector<std::string> struct_fields(const std::string& source, const std::string& name) {
    const std::size_t b = source.find("// BEGIN " + name);
    const std::size_t e = source.find("// END " + name);
    std::vector<std::string> out;
    if (b == std::string::npos || e == std::string::npos || e < b) return out;
    std::string body = source.substr(b, e - b);
    body.erase(0, body.find('\n') + 1);
    std::string clean;
    for (std::size_t i = 0; i < body.size(); ++i) {  // drop the // comments
        if (body[i] == '/' && i + 1 < body.size() && body[i + 1] == '/')
            while (i < body.size() && body[i] != '\n') ++i;
        if (i < body.size()) clean.push_back(body[i]);
    }
    body = clean;
    for (char& c : body)
        if (c == '{' || c == '}' || c == ',' || c == ';') c = ' ';
    std::istringstream in(body);
    std::string tok;
    while (in >> tok) {
        if (tok == "struct" || tok == name || tok == "float4" || tok == "uint4") continue;
        out.push_back(tok);
    }
    return out;
}

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

}  // namespace

// ---- the choice of the traced lights ------------------------------------------------------------------------------------------------------

namespace {

std::vector<RtLocalCandidate> candidates_of(std::initializer_list<float> importance, std::uint64_t firstId = 100) {
    std::vector<RtLocalCandidate> out;
    int i = 0;
    for (float v : importance) {
        out.push_back({firstId + std::uint64_t(i), i, v});
        ++i;
    }
    return out;
}

}  // namespace

TEST_CASE("rt local shadows: the three most important lights are traced, ties go to the lower light index") {
    CHECK(render::kRtLocalMaxLights == 3);
    CHECK(render::kRtLocalMaxLights == render::kRtLocalShadowMaxLights);
    RtLocalSlots slots;
    const RtLocalPick p = render::pick_rt_local_lights(slots, candidates_of({4.0f, 10.0f, 2.0f, 8.0f, 6.0f}));
    CHECK(p.candidates == 5);
    CHECK(p.traced == 3);
    CHECK(p.count == 3);
    CHECK(p.changed);
    // The free slots are filled best first: 10 (light 1), 8 (light 3), 6 (light 4).
    CHECK(p.light[0] == 1);
    CHECK(p.light[1] == 3);
    CHECK(p.light[2] == 4);
    // Equal importance: the lower light index first.
    RtLocalSlots tie;
    const RtLocalPick t = render::pick_rt_local_lights(tie, candidates_of({5.0f, 5.0f, 5.0f, 5.0f}));
    CHECK(t.light[0] == 0);
    CHECK(t.light[1] == 1);
    CHECK(t.light[2] == 2);
    // No candidate, no slot.
    RtLocalSlots none;
    const RtLocalPick e = render::pick_rt_local_lights(none, {});
    CHECK(e.count == 0);
    CHECK(e.traced == 0);
    CHECK_FALSE(e.changed);
    CHECK(e.light[0] == -1);
}

TEST_CASE("rt local shadows: a light that is not usable (importance 0, negative or not a number) is never traced") {
    RtLocalSlots slots;
    const float nan = std::numeric_limits<float>::quiet_NaN();
    const RtLocalPick p = render::pick_rt_local_lights(slots, candidates_of({0.0f, nan, -3.0f, 2.0f}));
    CHECK(p.candidates == 4);  // they asked, the status says so
    CHECK(p.traced == 1);
    CHECK(p.light[0] == 3);
    CHECK(p.light[1] == -1);
    CHECK(p.count == 1);
}

TEST_CASE("rt local shadows: a light keeps its slot while it stays a candidate, and is replaced only by a clearly "
          "better one") {
    RtLocalSlots slots;
    std::vector<RtLocalCandidate> c = candidates_of({10.0f, 8.0f, 6.0f, 4.0f});
    RtLocalPick p = render::pick_rt_local_lights(slots, c);
    REQUIRE(p.traced == 3);
    CHECK(p.light[2] == 2);
    // The same frame again: nothing moves, nothing changed (the denoiser's history holds).
    p = render::pick_rt_local_lights(slots, c);
    CHECK_FALSE(p.changed);
    CHECK(p.light[0] == 0);
    CHECK(p.light[1] == 1);
    CHECK(p.light[2] == 2);
    // The outsider becomes 1.2 times as important as the weakest holder: not enough (hysteresis 1.25).
    c[3].importance = 6.0f * 1.2f;
    p = render::pick_rt_local_lights(slots, c);
    CHECK_FALSE(p.changed);
    CHECK(p.light[2] == 2);
    // 1.3 times: it takes that slot, and only that one.
    c[3].importance = 6.0f * 1.3f;
    p = render::pick_rt_local_lights(slots, c);
    CHECK(p.changed);
    CHECK(p.light[0] == 0);
    CHECK(p.light[1] == 1);
    CHECK(p.light[2] == 3);
    // The holders' own order does not matter: light 1 becomes the strongest and light 0 the weakest holder, nobody moves.
    c[1].importance = 50.0f;
    p = render::pick_rt_local_lights(slots, c);
    CHECK_FALSE(p.changed);
    CHECK(p.light[0] == 0);
    CHECK(p.light[1] == 1);
    CHECK(p.light[2] == 3);
}

TEST_CASE("rt local shadows: the slots of a camera that is gone are purged after two frames without a request") {
    std::map<std::uint64_t, RtLocalSlots> all;
    all[1].lastUsed = 10;
    all[2].lastUsed = 12;
    all[3].lastUsed = 8;
    render::sweep_rt_local_slots(all, 12);  // serial 12: a camera used at 10 is 2 frames old and stays; 8 goes
    CHECK(all.size() == 2);
    CHECK(all.count(1) == 1);
    CHECK(all.count(2) == 1);
    render::sweep_rt_local_slots(all, 13);  // 10 + 2 < 13
    CHECK(all.size() == 1);
    CHECK(all.count(2) == 1);
    render::sweep_rt_local_slots(all, 14);  // 12 + 2 < 14 is false: still there
    CHECK(all.size() == 1);
    render::sweep_rt_local_slots(all, 15);
    CHECK(all.empty());
}

TEST_CASE("rt local shadows: a slot follows the light's entity when the light table is ordered differently, and a "
          "light that goes frees its slot") {
    RtLocalSlots slots;
    std::vector<RtLocalCandidate> c = candidates_of({10.0f, 8.0f, 6.0f});
    RtLocalPick p = render::pick_rt_local_lights(slots, c);
    REQUIRE(p.traced == 3);
    // The same three entities at other indices of the table: the slots keep the entities.
    std::vector<RtLocalCandidate> shuffled = {{102, 0, 6.0f}, {100, 1, 10.0f}, {101, 2, 8.0f}};
    p = render::pick_rt_local_lights(slots, shuffled);
    CHECK_FALSE(p.changed);
    CHECK(p.light[0] == 1);  // entity 100
    CHECK(p.light[1] == 2);  // entity 101
    CHECK(p.light[2] == 0);  // entity 102
    // The entity of slot 1 is gone: its slot is empty, the highest slot still counts (the kernel loops to it and skips the empty one).
    std::vector<RtLocalCandidate> fewer = {{100, 0, 10.0f}, {102, 1, 6.0f}};
    p = render::pick_rt_local_lights(slots, fewer);
    CHECK(p.changed);
    CHECK(p.traced == 2);
    CHECK(p.count == 3);
    CHECK(p.light[0] == 0);
    CHECK(p.light[1] == -1);
    CHECK(p.light[2] == 1);
    // A new light takes the free slot (not the holder's), and that is a change too.
    std::vector<RtLocalCandidate> back = {{100, 0, 10.0f}, {102, 1, 6.0f}, {200, 2, 1.0f}};
    p = render::pick_rt_local_lights(slots, back);
    CHECK(p.changed);
    CHECK(p.traced == 3);
    CHECK(p.light[1] == 2);
    // When every candidate is gone the slots are free again.
    p = render::pick_rt_local_lights(slots, {});
    CHECK(p.changed);
    CHECK(p.count == 0);
    CHECK_FALSE(slots.used[0]);
}

// ---- the kernel's constants ---------------------------------------------------------------------------------------------------------------

namespace {

LightData point_light(float x, float y, float z, float range) {
    LightData l{};
    l.pos = {x, y, z, range};
    l.color = {1, 1, 1, 1.0f};  // w: 1 point, 2 spot, 3 area (shaders/light_data.glsl)
    l.dir = {0, -1, 0, -2.0f};
    l.shadow.casts = true;
    l.shadow.softness = 1.0f;
    return l;
}

}  // namespace

TEST_CASE("rt local shadows: the record of a point light has the cone of rays its softness asks for, and none when it "
          "is hard") {
    LightData soft = point_light(1, 2, 3, 10);
    RtLocalLight r = render::make_rt_local_light(soft);
    CHECK(r.kind[0] == 1.0f);
    CHECK(r.posReach[0] == 1.0f);
    CHECK(r.posReach[2] == 3.0f);
    CHECK(r.posReach[3] == 10.0f);
    CHECK(r.axisCos[3] == -2.0f);  // no cone
    CHECK(r.kind[1] == doctest::Approx(std::tan(0.05f)));
    // Light.shadowFilter Hard: one ray to the centre, soft mode or not. Light.shadowSoftness 0 too.
    LightData hard = soft;
    hard.shadow.filter = 1;
    CHECK(render::make_rt_local_light(hard).kind[1] == 0.0f);
    LightData zero = soft;
    zero.shadow.softness = 0.0f;
    CHECK(render::make_rt_local_light(zero).kind[1] == 0.0f);
    // A number a user can write that is not finite or too large is clamped (the kernel never sees it).
    LightData bad = soft;
    bad.shadow.softness = std::numeric_limits<float>::quiet_NaN();
    CHECK(render::make_rt_local_light(bad).kind[1] == 0.0f);
    bad.shadow.softness = 1.0e9f;
    CHECK(render::make_rt_local_light(bad).kind[1] == doctest::Approx(std::tan(0.5f)));
}

TEST_CASE(
    "rt local shadows: the record of a spot light has its axis and cone, the one of an area light its shape and axes") {
    LightData spot = point_light(0, 5, 0, 12);
    spot.color.w = 2.0f;
    spot.dir = {0, -1, 0, 0.8f};
    RtLocalLight s = render::make_rt_local_light(spot);
    CHECK(s.kind[0] == 2.0f);
    CHECK(s.axisCos[1] == -1.0f);
    CHECK(s.axisCos[3] == 0.8f);

    LightData area = point_light(0, 5, 0, 10);
    area.color.w = 3.0f;
    area.hasExt = true;
    area.extent = 0.5f;
    area.dir = {0, -1, 0, 0};
    area.ext[0] = {1, 0, 0, 2.0f};  // an axis and its half size
    area.ext[1] = {0, 0, 1, 0.5f};
    for (int shape = 0; shape < 3; ++shape) {
        area.ext[2] = {0, 0, 0, float(shape)};
        const RtLocalLight a = render::make_rt_local_light(area);
        CHECK(a.kind[0] == float(3 + shape));            // rectangle, disc, tube
        CHECK(a.kind[2] == 1.0f);                        // the factor on its half sizes: Light.shadowSoftness
        CHECK(a.posReach[3] == doctest::Approx(10.5f));  // the range is measured from the emitter's surface
        CHECK(a.right[0] == 2.0f);
        CHECK(a.up[2] == 0.5f);
        CHECK(a.axisCos[1] == -1.0f);
    }
    area.shadow.filter = 1;  // a hard area light is a point at its centre
    CHECK(render::make_rt_local_light(area).kind[2] == 0.0f);
}

TEST_CASE("rt local shadows: the constants block has the lights in their slots and an empty slot reaches nowhere") {
    std::vector<LightData> table = {point_light(0, 1, 0, 5), point_light(1, 1, 0, 6), point_light(2, 1, 0, 7)};
    RtLocalPick pick;
    pick.light = {2, -1, 0};
    pick.count = 3;
    pick.traced = 2;
    const RtLocalParams p = render::make_rt_local_params(table, pick);
    CHECK(p.header[0] == 3.0f);
    CHECK(p.header[1] == doctest::Approx(render::kRtLocalStopMetres));
    CHECK(p.header[2] == doctest::Approx(render::kRtLocalStopCap));
    CHECK(p.lights[0].posReach[3] == 7.0f);
    CHECK(p.lights[1].posReach[3] == 0.0f);  // the kernel skips a light that reaches nowhere
    CHECK(p.lights[2].posReach[3] == 5.0f);
    // An index out of the table is an empty slot, not a read past it.
    pick.light = {9, -1, -1};
    pick.count = 1;
    const RtLocalParams q = render::make_rt_local_params(table, pick);
    CHECK(q.lights[0].posReach[3] == 0.0f);
    CHECK(sizeof(RtLocalParams) == 256);
    CHECK(sizeof(RtLocalLight) == 80);
}

// ---- the shaders and their tables -----------------------------------------------------------------------------------------------------

TEST_CASE("rt local shadows: RtLocalLight is the same struct in C++, HLSL and MSL, and the kernels are in the table") {
    const std::vector<std::string> expected(std::begin(render::kRtLocalLightNames),
                                            std::end(render::kRtLocalLightNames));
    REQUIRE(expected.size() == 5);
    CHECK(offsetof(RtLocalLight, axisCos) == 16);
    CHECK(offsetof(RtLocalLight, kind) == 32);
    CHECK(offsetof(RtLocalLight, right) == 48);
    CHECK(offsetof(RtLocalLight, up) == 64);
    CHECK(offsetof(RtLocalParams, lights) == 16);
    const rt_kernels::RtKernel* k = rt_kernels::find_rt_kernel("rt_shadow_local");
    const rt_kernels::RtKernel* pack = rt_kernels::find_rt_kernel("rt_shadow_local_pack");
    REQUIRE(k != nullptr);
    REQUIRE(pack != nullptr);
    const std::string hlsl = read_repo_file("engine/render/shaders/rt/rt_shadow_local.hlsl");
    REQUIRE_FALSE(hlsl.empty());
    CHECK(struct_fields(hlsl, "RtLocalLight") == expected);
    CHECK(struct_fields(std::string(k->msl), "RtLocalLight") == expected);
    // The constants block of the engine is the same in both kernels as in the sun's (the pack kernel reads it, too).
    const std::vector<std::string> params(std::begin(render::kRtEffectParamNames),
                                          std::end(render::kRtEffectParamNames));
    CHECK(struct_fields(hlsl, "RtEffectParams") == params);
    CHECK(struct_fields(std::string(k->msl), "RtEffectParams") == params);
    CHECK(struct_fields(read_repo_file("engine/render/shaders/rt/rt_shadow_local_pack.hlsl"), "RtEffectParams") ==
          params);
    CHECK(struct_fields(std::string(pack->msl), "RtEffectParams") == params);
    CHECK(k->msl.find("kernel void rt_shadow_local") != std::string_view::npos);
    CHECK(k->msl.find("accept_any_intersection(true)") != std::string_view::npos);
    CHECK(k->msl.find("constant RtLocalParams& local [[buffer(3)]]") != std::string_view::npos);
    CHECK(hlsl.find("[[vk::binding(7, 0)]] ConstantBuffer<RtLocalParams> g_local : register(b1);") !=
          std::string::npos);
    CHECK(read_repo_file("engine/render/shaders/rt/rt_shadow_local_pack.hlsl")
              .find("[[vk::binding(9, 0)]] Texture2D<float4> g_aux : register(t5);") != std::string::npos);
    CHECK(read_repo_file("engine/render/shaders/rt/rt_shadow_pack.hlsl")
              .find("[[vk::binding(9, 0)]] Texture2D<float4> g_aux : register(t5);") != std::string::npos);
    // One ray query call site per kernel (Metal's compiler unrolls a second one into a very long compile).
    std::size_t calls = 0;
    for (std::size_t at = k->msl.find(".reset("); at != std::string_view::npos; at = k->msl.find(".reset(", at + 1))
        ++calls;
    CHECK(calls == 1);
    CHECK_FALSE(k->dxil.empty());
    CHECK_FALSE(k->spirv.empty());
    CHECK_FALSE(pack->dxil.empty());
    CHECK_FALSE(pack->spirv.empty());
    const render::RtEffectKernelSpec* spec = render::find_rt_effect_spec("rt_shadow_local");
    const render::RtEffectKernelSpec* packSpec = render::find_rt_effect_spec("rt_shadow_local_pack");
    REQUIRE(spec != nullptr);
    REQUIRE(packSpec != nullptr);
    CHECK(spec->usesTlas);
    CHECK(spec->usesLocal);
    CHECK_FALSE(spec->usesHit);
    CHECK_FALSE(spec->usesAux);
    CHECK_FALSE(spec->usesRecords);
    CHECK_FALSE(packSpec->usesTlas);
    CHECK(packSpec->usesAux);
    CHECK_FALSE(packSpec->usesLocal);
}

TEST_CASE("rt local shadows: the two kernels declare the bindings of the contract in every backend's numbering") {
    const rt_kernels::RtKernel* k = rt_kernels::find_rt_kernel("rt_shadow_local");
    const rt_kernels::RtKernel* pack = rt_kernels::find_rt_kernel("rt_shadow_local_pack");
    REQUIRE(k != nullptr);
    REQUIRE(pack != nullptr);
    const render::RtEffectKernelSpec* spec = render::find_rt_effect_spec("rt_shadow_local");
    const render::RtEffectKernelSpec* packSpec = render::find_rt_effect_spec("rt_shadow_local_pack");
    REQUIRE(spec != nullptr);
    REQUIRE(packSpec != nullptr);
    for (gpu::Backend backend :
         {gpu::Backend::Metal, gpu::Backend::Recording, gpu::Backend::D3d12, gpu::Backend::Vulkan}) {
        INFO("backend " << int(backend));
        const gpu::ShaderDesc d = render::rt_effect_shader_desc(*k, *spec, backend);
        REQUIRE(d.compute());
        CHECK(d.usesRayQuery);
        CHECK(d.accelStructures[0].binding.hlslRegister == 0);
        CHECK(d.accelStructures[0].binding.mslIndex == 0);
        CHECK(d.accelStructures[0].binding.spirvBinding == 0);
        CHECK(d.uniformBlocks[0].size == sizeof(render::RtEffectParams));
        // The lights: b1 / buffer(3) / binding 7, 256 bytes.
        const auto& block = d.uniformBlocks[render::RtEffectBindings::kUniformHit];
        CHECK(block.stage == gpu::ShaderStage::Compute);
        CHECK(block.size == sizeof(RtLocalParams));
        CHECK(block.binding.hlslRegister == 1);
        CHECK(block.binding.mslIndex == 3);
        CHECK(block.binding.spirvBinding == 7);
        CHECK(d.views[0].storageImage.binding.hlslRegister == 0);
        CHECK(d.views[0].storageImage.binding.mslIndex == 0);
        CHECK(d.views[0].storageImage.binding.spirvBinding == 1);
        CHECK(d.views[1].texture.binding.hlslRegister == 1);
        CHECK(d.views[1].texture.binding.mslIndex == 1);
        CHECK(d.views[1].texture.binding.spirvBinding == 3);
        CHECK(d.views[2].stage() == gpu::ShaderStage::None);
        CHECK(d.views[5].stage() == gpu::ShaderStage::None);

        const gpu::ShaderDesc p = render::rt_effect_shader_desc(*pack, *packSpec, backend);
        REQUIRE(p.compute());
        CHECK_FALSE(p.usesRayQuery);
        CHECK(p.accelStructures[0].stage == gpu::ShaderStage::None);
        CHECK(p.uniformBlocks[0].size == sizeof(render::RtEffectParams));
        CHECK(p.uniformBlocks[render::RtEffectBindings::kUniformHit].stage == gpu::ShaderStage::None);
        CHECK(p.views[1].texture.binding.hlslRegister == 1);
        CHECK(p.views[5].texture.binding.hlslRegister == 5);  // the visibilities: the aux image
        CHECK(p.views[5].texture.binding.mslIndex == 4);
        CHECK(p.views[5].texture.binding.spirvBinding == 9);  // not 7: the hit and local constants' binding
        if (backend == gpu::Backend::Metal) CHECK(std::string(p.computeFunc.entry) == "rt_shadow_local_pack");
        if (backend == gpu::Backend::D3d12) CHECK(d.computeFunc.bytecode.size == k->dxil.size());
        if (backend == gpu::Backend::Vulkan) CHECK(d.computeFunc.bytecode.size == k->spirv.size());
    }
    CHECK_FALSE(render::rt_effect_shader_desc(*k, *spec, gpu::Backend::Gl).compute());
    CHECK_FALSE(render::rt_effect_shader_desc(*k, *spec, gpu::Backend::D3d11).compute());
}

TEST_CASE(
    "rt local shadows: only the point, spot and area lights' shadow factor of the lit shader reads the traced mask") {
    const std::string glsl = read_repo_file("engine/render/shaders/mesh_common.glsl");
    REQUIRE_FALSE(glsl.empty());
    const std::size_t fn = glsl.find("float fa_shadow_local_rt(");
    REQUIRE(fn != std::string::npos);
    // The depth slope is read from the per-fragment global (no derivative inside a light's branch), and the texels around the fragment's own are
    // searched in a 3 x 3 block, the darkest of those that show the surface answering (a silhouette does not flicker to "lit").
    const std::string body = glsl.substr(fn, glsl.find("\n}\n", fn) - fn);
    CHECK(body.find("fwidth(") == std::string::npos);
    CHECK(body.find("fa_rt_slope") != std::string::npos);
    CHECK(body.find("k < 9") != std::string::npos);
    CHECK(body.find("min(best,") != std::string::npos);
    const std::string loop = read_repo_file("engine/render/shaders/light_loop.glsl");
    // The light loops call the traced version; the full-shader path (user materials) keeps the maps only.
    CHECK(loop.find("fa_shadow_local_rt(") != std::string::npos);
    CHECK(loop.find("fa_shadow_local(") == std::string::npos);
    const std::string full = read_repo_file("engine/render/shaders/mesh_full_common.glsl");
    CHECK(full.find("fa_shadow_local_rt(") == std::string::npos);
}

// ---- the renderer's frame on the RecordingDevice ------------------------------------------------------------------------------------------

namespace {

struct Rig {
    Renderer renderer;
    gpu::RecordingDevice* dev = nullptr;
    explicit Rig(bool deviceTraces = true) {
        gfx();
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

    void rays(render::RtShadows shadows, int raysPerPixel = 4) {
        render::RayTracingSettings s;
        s.enabled = true;
        s.shadows = shadows;
        s.ao = false;
        s.raysPerPixel = raysPerPixel;
        renderer.set_ray_tracing(s);
    }
    void frame(World& w) {
        renderer.update(w);
        renderer.begin_frame();
        renderer.render_world(w, 0.0f);
        renderer.end_frame();
    }
    void frames(World& w, int n) {
        for (int i = 0; i < n; ++i) frame(w);
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
    std::string errors() const {
        std::string s;
        for (const std::string& e : dev->errors()) s += e + "\n";
        return s;
    }
    render::RtEffects& effects() { return *RendererTestAccess::rt_effects(renderer); }
    // What the status says: the lights that asked and those the last frame traced.
    void status(int& candidates, int& traced) const { renderer.ray_tracing_local_shadows(candidates, traced); }
};

int index_of(const std::vector<std::string>& lines, const std::string& needle) {
    for (std::size_t i = 0; i < lines.size(); ++i)
        if (lines[i].find(needle) != std::string::npos) return int(i);
    return -1;
}

int count_of(const std::vector<std::string>& lines, const std::string& needle) {
    int n = 0;
    for (const std::string& l : lines) n += l.find(needle) != std::string::npos ? 1 : 0;
    return n;
}

// A camera, a floor and a box. No sun: only the local lights ask for rays.
void make_room(World& w) {
    Entity cam = make(w, "cam", {0, 3, 12});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    Entity floor = make(w, "floor", {0, 0, 0});
    w.get<Transform>(floor)->scale = {16, 1, 16};
    w.add<MeshRenderer>(floor).mesh = "plane";
    Entity box = make(w, "box", {0, 1, 0});
    w.add<MeshRenderer>(box).mesh = "cube";
}

Entity add_point(World& w, const char* name, Vec3 pos, float range = 20.0f, float intensity = 5.0f) {
    Entity e = make(w, name, pos);
    auto& l = w.add<Light>(e);
    l.type = LightType::Point;
    l.range = range;
    l.intensity = intensity;
    l.castShadows = true;
    return e;
}

// `n` point lights on a line, the nearest to the camera first (so the importance goes down with the index).
void add_lights(World& w, int n) {
    for (int i = 0; i < n; ++i) {
        const std::string name = "light" + std::to_string(i);
        add_point(w, name.c_str(), {-3.0f + 1.5f * float(i), 4.0f, 6.0f - 3.0f * float(i)});
    }
}

}  // namespace

TEST_CASE("rt local shadows: with the shadows setting off, or no light that casts, nothing is declared, made or kept") {
    // Ray tracing on, shadows off, lights that cast.
    {
        Rig r;
        r.rays(render::RtShadows::Off);
        World w;
        make_room(w);
        add_lights(w, 2);
        for (int i = 0; i < 3; ++i) {
            r.dev->clear_commands();
            r.frame(w);
            CHECK(r.errors().empty());
            CHECK(r.compute_passes().empty());
        }
        CHECK(r.effects().empty());
        CHECK(r.effects().kernel_count() == 0);
        CHECK(r.effects().image_count() == 0);
        int candidates = -1, traced = -1;
        r.status(candidates, traced);
        CHECK(candidates == 0);
        CHECK(traced == 0);
        CHECK(RendererTestAccess::rt_shadow_draws(r.renderer).local == 0);
    }
    // Shadows on, lights that do not cast.
    {
        Rig r;
        r.rays(render::RtShadows::Hard);
        World w;
        make_room(w);
        add_lights(w, 2);
        w.each<Light>([](Entity, Light& l) { l.castShadows = false; });
        r.frames(w, 4);
        r.dev->clear_commands();
        r.frame(w);
        CHECK(r.compute_passes().empty());
        CHECK(r.effects().empty());
        CHECK_FALSE(RendererTestAccess::rt_denoiser(r.renderer)->shaders_made());
        CHECK(RendererTestAccess::rt_shadow_draws(r.renderer).local == 0);
    }
}

TEST_CASE("rt local shadows: lights that cast declare the trace and the pack after the TLAS and the prepass, with the "
          "bindings of the contract") {
    Rig r;
    r.rays(render::RtShadows::Hard);
    World w;
    make_room(w);
    add_lights(w, 2);
    r.frames(w, 3);  // the first frames build the BLASes
    r.dev->clear_commands();
    r.frame(w);
    INFO(r.errors());
    CHECK(r.errors().empty());
    const std::vector<std::string> passes = r.compute_passes();
    REQUIRE(passes.size() == 2);
    CHECK(passes[0].find("camera:0/rt-shadows-local-trace") != std::string::npos);
    CHECK(passes[1].find("camera:0/rt-shadows-local") != std::string::npos);
    CHECK(passes[1].find("trace") == std::string::npos);
    const std::vector<std::string> lines = r.lines();
    const int tlas = index_of(lines, "build_tlas");
    const int prepass = index_of(lines, "begin_pass 'prepass'");
    const int trace = index_of(lines, "rt-shadows-local-trace");
    const int pack = index_of(lines, "begin_compute_pass 'camera:0/rt-shadows-local'");
    const int game = index_of(lines, "begin_pass 'game'");
    REQUIRE(tlas >= 0);
    REQUIRE(prepass >= 0);
    REQUIRE(trace >= 0);
    REQUIRE(pack >= 0);
    REQUIRE(game >= 0);
    CHECK(tlas < trace);
    CHECK(prepass < trace);
    CHECK(trace < pack);
    CHECK(pack < game);
    // The trace: one pipeline, the output and the prepass as views (and the sampler Metal wants), the two constants blocks (400 and 256 bytes), one
    // dispatch of the camera's rectangle in 8 x 8 groups.
    REQUIRE(std::size_t(trace) + 5 < lines.size());
    CHECK(lines[std::size_t(trace) + 1].find("set_pipeline") != std::string::npos);
    CHECK(lines[std::size_t(trace) + 2].find("views=2 samplers=1") != std::string::npos);
    CHECK(lines[std::size_t(trace) + 3].find("set_uniforms 0 400B") != std::string::npos);
    CHECK(lines[std::size_t(trace) + 4].find("set_uniforms 1 256B") != std::string::npos);
    CHECK(lines[std::size_t(trace) + 5].find("dispatch 20 12 1") != std::string::npos);
    // The pack: the output, the prepass (no sun is traced) and the visibilities; no TLAS, one constants block.
    REQUIRE(std::size_t(pack) + 4 < lines.size());
    CHECK(lines[std::size_t(pack) + 2].find("views=3") != std::string::npos);
    CHECK(lines[std::size_t(pack) + 3].find("set_uniforms 0 400B") != std::string::npos);
    CHECK(lines[std::size_t(pack) + 4].find("dispatch 20 12 1") != std::string::npos);
    CHECK(r.count(gpu::CommandKind::Dispatch) == 2);
    // Two lights, hard: no denoiser, two images (the trace and the packed one), two kernels.
    CHECK(r.effects().image_count() == 2);
    CHECK(r.effects().kernel_count() == 2);
    CHECK(count_of(lines, "rtd-") == 0);
    CHECK_FALSE(RendererTestAccess::rt_denoiser(r.renderer)->shaders_made());
    int candidates = 0, traced = 0;
    r.status(candidates, traced);
    CHECK(candidates == 2);
    CHECK(traced == 2);
    // The lit pass reads the packed image for the local lights.
    CHECK(RendererTestAccess::rt_shadow_draws(r.renderer).local > 0);
    CHECK(RendererTestAccess::rt_effect_failure(r.renderer).empty());
}

TEST_CASE("rt local shadows: the recorded frame is the same every frame (no clock, no random number)") {
    Rig r;
    r.rays(render::RtShadows::Soft);
    World w;
    make_room(w);
    add_lights(w, 3);
    r.frames(w, 6);
    r.dev->clear_commands();
    r.frame(w);
    const std::vector<std::string> a = r.lines();
    r.dev->clear_commands();
    r.frame(w);
    const std::vector<std::string> b = r.lines();
    REQUIRE(a.size() > 30);
    CHECK(a == b);
}

TEST_CASE("rt local shadows: at most three lights are traced, the others keep their maps, and the status says so") {
    constexpr int kCap = render::kRtLocalShadowMaxLights;
    // The draws of the shadow maps of a frame: the lights that are traced have no map drawn, so a frame that traces fewer lights draws more.
    const auto draws_of = [](int lights, render::RtShadows mode) {
        Rig r;
        r.rays(mode);
        World w;
        make_room(w);
        add_lights(w, lights);
        r.frames(w, 5);
        r.dev->clear_commands();
        r.frame(w);
        CHECK(r.errors().empty());
        int candidates = 0, traced = 0;
        r.status(candidates, traced);
        return std::array<int, 3>{r.count(gpu::CommandKind::Draw), candidates, traced};
    };
    const auto off = draws_of(5, render::RtShadows::Off);
    const auto five = draws_of(5, render::RtShadows::Hard);
    const auto three = draws_of(3, render::RtShadows::Hard);
    CHECK(five[1] == 5);
    CHECK(five[2] == kCap);
    CHECK(three[1] == 3);
    CHECK(three[2] == 3);
    CHECK(off[1] == 0);
    CHECK(off[2] == 0);
    // Every map of the three traced lights is not drawn; the two others are.
    CHECK(five[0] < off[0]);
    CHECK(three[0] < five[0]);
    // The traced lights are the three nearest to the camera (the importance), and which ones does not change from frame to frame.
    Rig r;
    r.rays(render::RtShadows::Hard);
    World w;
    make_room(w);
    add_lights(w, 5);
    r.frames(w, 4);
    const std::vector<std::string> before = [&] {
        r.dev->clear_commands();
        r.frame(w);
        return r.lines();
    }();
    r.dev->clear_commands();
    r.frame(w);
    CHECK(before == r.lines());
}

TEST_CASE("rt local shadows: the maps of the lights that stay on the maps are drawn after the pack pass, which decides "
          "whether the traced lights need theirs") {
    Rig r;
    r.rays(render::RtShadows::Hard);
    World w;
    make_room(w);
    add_lights(w, 5);  // three traced, two on their maps: the shadow pass exists
    r.frames(w, 4);
    r.dev->clear_commands();
    r.frame(w);
    CHECK(r.errors().empty());
    const std::vector<std::string> lines = r.lines();
    const int pack = index_of(lines, "begin_compute_pass 'camera:0/rt-shadows-local'");
    const int shadow = index_of(lines, "begin_pass 'shadow'");
    REQUIRE(pack >= 0);
    REQUIRE(shadow >= 0);
    CHECK(pack < shadow);
}

TEST_CASE("rt local shadows: the status names the traced lights and the cap in its reason") {
    // The renderer answers the numbers; the reason itself is the runtime's (tests/ray_tracing_engine_tests.cpp). Here: the numbers move with the
    // scene, a frame later than the scene (they are published when the next frame begins).
    Rig r;
    r.rays(render::RtShadows::Hard);
    World w;
    make_room(w);
    add_lights(w, 4);
    r.frames(w, 5);
    int candidates = 0, traced = 0;
    r.status(candidates, traced);
    CHECK(candidates == 4);
    CHECK(traced == 3);
    // A light that stops casting is not a candidate any more.
    w.get<Light>(w.find("light0"))->castShadows = false;
    r.frames(w, 3);
    r.status(candidates, traced);
    CHECK(candidates == 3);
    CHECK(traced == 3);
    // Ray tracing off: nothing is traced and the numbers go to 0.
    render::RayTracingSettings off;
    off.enabled = false;
    r.renderer.set_ray_tracing(off);
    r.frames(w, 3);
    r.status(candidates, traced);
    CHECK(candidates == 0);
    CHECK(traced == 0);
}

TEST_CASE("rt local shadows: spot and area lights are traced like point lights") {
    Rig r;
    r.rays(render::RtShadows::Hard);
    World w;
    make_room(w);
    Entity spot = make(w, "spot", {2, 5, 4});
    w.get<Transform>(spot)->rotation = {-70, 0, 0};
    auto& s = w.add<Light>(spot);
    s.type = LightType::Spot;
    s.range = 20;
    s.intensity = 5;
    s.castShadows = true;
    Entity area = make(w, "area", {-2, 5, 2});
    w.get<Transform>(area)->rotation = {-90, 0, 0};
    auto& a = w.add<Light>(area);
    a.type = LightType::Area;
    a.shape = LightShape::Disc;
    a.size = {2, 2};
    a.range = 20;
    a.intensity = 5;
    a.castShadows = true;
    r.frames(w, 5);
    INFO(r.errors());
    CHECK(r.errors().empty());
    int candidates = 0, traced = 0;
    r.status(candidates, traced);
    CHECK(candidates == 2);
    CHECK(traced == 2);
    r.dev->clear_commands();
    r.frame(w);
    CHECK(r.compute_passes().size() == 2);
}

TEST_CASE("rt local shadows: soft lights are denoised as one signal, hard ones and the hard setting are not") {
    // Soft setting, lights with a penumbra (Light.shadowSoftness 1): one trace, the denoiser's passes, one pack.
    {
        Rig r;
        r.rays(render::RtShadows::Soft);
        World w;
        make_room(w);
        add_lights(w, 2);
        r.frames(w, 5);
        r.dev->clear_commands();
        r.frame(w);
        INFO(r.errors());
        CHECK(r.errors().empty());
        REQUIRE(r.compute_passes().size() == 2);
        const std::vector<std::string> lines = r.lines();
        CHECK(count_of(lines, "begin_pass 'rtd-guide'") == 1);
        CHECK(count_of(lines, "begin_pass 'rtd-temporal'") == 1);  // one signal for the two lights
        CHECK(count_of(lines, "begin_pass 'rtd-atrous'") >= 1);
        const int trace = index_of(lines, "rt-shadows-local-trace");
        const int guide = index_of(lines, "begin_pass 'rtd-guide'");
        const int pack = index_of(lines, "begin_compute_pass 'camera:0/rt-shadows-local'");
        CHECK(trace < guide);
        CHECK(guide < pack);
        CHECK(RendererTestAccess::rt_denoiser(r.renderer)->history_image_count() > 0);
    }
    // Soft setting, hard lights (Light.shadowFilter Hard): one ray each, no denoiser.
    {
        Rig r;
        r.rays(render::RtShadows::Soft);
        World w;
        make_room(w);
        add_lights(w, 2);
        w.each<Light>([](Entity, Light& l) { l.shadowFilter = ShadowFilter::Hard; });
        r.frames(w, 5);
        r.dev->clear_commands();
        r.frame(w);
        CHECK(r.compute_passes().size() == 2);
        CHECK(count_of(r.lines(), "rtd-") == 0);
        CHECK_FALSE(RendererTestAccess::rt_denoiser(r.renderer)->shaders_made());
    }
    // Hard setting, lights with a penumbra: one ray at the centre, no denoiser.
    {
        Rig r;
        r.rays(render::RtShadows::Hard);
        World w;
        make_room(w);
        add_lights(w, 2);
        r.frames(w, 5);
        r.dev->clear_commands();
        r.frame(w);
        CHECK(r.compute_passes().size() == 2);
        CHECK(count_of(r.lines(), "rtd-") == 0);
    }
}

TEST_CASE(
    "rt local shadows: the history of the signal starts again when a light enters or leaves a slot, and only then") {
    Rig r;
    r.rays(render::RtShadows::Soft);
    World w;
    make_room(w);
    add_lights(w, 2);
    const std::uint64_t cam = w.find("cam").bits();
    render::RtDenoiser* dn = RendererTestAccess::rt_denoiser(r.renderer);
    REQUIRE(dn != nullptr);
    constexpr std::uint32_t kSignal = 6;  // Renderer::Impl::kRtLocalSignalId
    r.frames(w, 6);
    CHECK(dn->last_used_history(cam, kSignal));
    CHECK(dn->last_reset(cam, kSignal) == render::DenoiseReset::None);
    const int resets = dn->resets();
    // Frames in which nothing changes keep the history.
    r.frames(w, 3);
    CHECK(dn->last_used_history(cam, kSignal));
    CHECK(dn->resets() == resets);
    // A third light enters the free slot: the history is another light's mix, it starts again (once).
    add_point(w, "light2", {2.0f, 4.0f, 2.0f});
    r.frame(w);
    CHECK_FALSE(dn->last_used_history(cam, kSignal));
    CHECK(dn->resets() > resets);
    r.frames(w, 3);
    CHECK(dn->last_used_history(cam, kSignal));
    // One leaves: the same.
    const int afterEnter = dn->resets();
    w.get<Light>(w.find("light1"))->castShadows = false;
    r.frame(w);
    CHECK_FALSE(dn->last_used_history(cam, kSignal));
    CHECK(dn->resets() > afterEnter);
    r.frames(w, 3);
    CHECK(dn->last_used_history(cam, kSignal));
    // The lights that stay keep their slots when another leaves: no other change follows.
    const int stable = dn->resets();
    r.frames(w, 3);
    CHECK(dn->resets() == stable);
    CHECK(r.errors().empty());
}

TEST_CASE(
    "rt local shadows: turning the shadows off, or ray tracing off, frees the kernels, the images and the denoiser") {
    Rig r;
    r.rays(render::RtShadows::Soft);
    World w;
    make_room(w);
    add_lights(w, 2);
    r.frames(w, 5);
    CHECK(r.effects().kernel_count() == 2);  // the trace and the pack
    CHECK(RendererTestAccess::rt_denoiser(r.renderer)->history_image_count() > 0);
    r.rays(render::RtShadows::Off);
    r.frames(w, 6);
    CHECK(r.effects().empty());
    CHECK(r.effects().image_count() == 0);
    CHECK(RendererTestAccess::rt_denoiser(r.renderer)->history_image_count() == 0);
    r.dev->clear_commands();
    r.frame(w);
    CHECK(r.compute_passes().empty());
    // And back: the frame is made again.
    r.rays(render::RtShadows::Soft);
    r.frames(w, 3);
    r.dev->clear_commands();
    r.frame(w);
    CHECK(r.compute_passes().size() == 2);
    // Ray tracing off: nothing is kept.
    render::RayTracingSettings off;
    off.enabled = false;
    r.renderer.set_ray_tracing(off);
    r.frames(w, 3);
    CHECK(r.effects().empty());
    CHECK(RendererTestAccess::rt_denoiser(r.renderer)->history_image_count() == 0);
    CHECK(r.errors().empty());
}

TEST_CASE("rt local shadows: the sun and the local lights are two effects of the same frame, and the lit pass reads "
          "one image") {
    Rig r;
    r.rays(render::RtShadows::Hard);
    World w;
    make_room(w);
    Entity sun = make(w, "sun", {0, 5, 0});
    w.get<Transform>(sun)->rotation = {-50, 30, 0};
    auto& l = w.add<Light>(sun);
    l.type = LightType::Directional;
    l.castShadows = true;
    add_lights(w, 2);
    r.frames(w, 4);
    r.dev->clear_commands();
    r.frame(w);
    CHECK(r.errors().empty());
    const std::vector<std::string> passes = r.compute_passes();
    // The sun's trace, then the lights' trace and pack (the pack keeps the sun's depth, visibility and mesh flag).
    REQUIRE(passes.size() == 3);
    CHECK(passes[0].find("rt-shadows") != std::string::npos);
    CHECK(passes[0].find("local") == std::string::npos);
    CHECK(passes[1].find("rt-shadows-local-trace") != std::string::npos);
    CHECK(passes[2].find("camera:0/rt-shadows-local") != std::string::npos);
    const std::vector<std::string> lines = r.lines();
    const int pack = index_of(lines, "begin_compute_pass 'camera:0/rt-shadows-local'");
    REQUIRE(pack >= 0);
    CHECK(lines[std::size_t(pack) + 2].find("views=3") !=
          std::string::npos);  // the output, the sun's image, the visibilities
    const auto d = RendererTestAccess::rt_shadow_draws(r.renderer);
    CHECK(d.mask > 0);
    CHECK(d.local > 0);
}

TEST_CASE("rt local shadows: a device that cannot trace says so once and draws the frame it would draw with ray "
          "tracing off") {
    Logs log;
    auto stream = [&](bool deviceTraces, bool setting) {
        Rig r(deviceTraces);
        if (setting) r.rays(render::RtShadows::Hard);
        World w;
        make_room(w);
        add_lights(w, 3);
        r.frames(w, 3);
        r.dev->clear_commands();
        r.frame(w);
        CHECK(r.errors().empty());
        CHECK(r.compute_passes().empty());
        CHECK(r.effects().empty());
        int candidates = -1, traced = -1;
        r.status(candidates, traced);
        CHECK(traced == 0);
        CHECK(RendererTestAccess::rt_shadow_draws(r.renderer).local == 0);
        return r.lines();
    };
    const std::vector<std::string> off = stream(true, false);
    const std::vector<std::string> unsupported = stream(false, true);
    REQUIRE(off.size() > 5);
    CHECK(off == unsupported);  // the maps of every light are drawn
    CHECK(log.count("cannot trace rays") == 1);
    CHECK(log.count("ray traced shadows of point, spot and area lights cannot run") == 0);
}

TEST_CASE("rt local shadows: a caster the rays cannot see keeps the maps of the lights") {
    // More casters than render.rayTracing.maxInstances: the ones over the cap are not in the TLAS, so the maps stay (the lit pass takes min(rays, map)).
    const auto draws = [](int maxInstances) {
        Rig r;
        render::RayTracingSettings s;
        s.enabled = true;
        s.shadows = render::RtShadows::Hard;
        s.ao = false;
        s.maxInstances = maxInstances;
        r.renderer.set_ray_tracing(s);
        World w;
        make_room(w);
        add_lights(w, 2);
        r.frames(w, 5);
        r.dev->clear_commands();
        r.frame(w);
        return std::array<int, 2>{r.count(gpu::CommandKind::Draw),
                                  int(RendererTestAccess::rt_scene(r.renderer)->stats().untracedCasters)};
    };
    const auto all = draws(1000);
    const auto few = draws(1);
    CHECK(all[1] == 0);
    CHECK(few[1] > 0);
    CHECK(few[0] > all[0]);  // the maps are drawn: a caster is missing from the rays
}

TEST_CASE("rt local shadows: a terrain keeps the maps of the lights (the rays do not see it, and its own shader reads "
          "the map)") {
    Rig r;
    r.rays(render::RtShadows::Hard);
    World w;
    make_room(w);
    add_lights(w, 2);
    Entity ground = make(w, "terrain", {0, -1, 0});
    auto& t = w.add<Terrain3D>(ground);
    t.size = {16, 16};
    r.frames(w, 5);
    CHECK(RendererTestAccess::rt_scene(r.renderer)->stats().untracedCasters > 0);
    const std::size_t drawsWithTerrain = std::size_t(r.count(gpu::CommandKind::Draw));
    World clean;
    make_room(clean);
    add_lights(clean, 2);
    Rig q;
    q.rays(render::RtShadows::Hard);
    q.frames(clean, 5);
    q.dev->clear_commands();
    q.frame(clean);
    CHECK(q.count(gpu::CommandKind::Draw) > 0);
    CHECK(drawsWithTerrain > 0);
    CHECK(r.errors().empty());
}

TEST_CASE("rt local shadows: the volumetric fog's march reads the maps, so a traced light that shines in the fog keeps "
          "its map") {
    // The march (volumetric.glsl, vol_shadow_local) samples the local maps of the atlas: a traced light with Light.volumetric above 0, in a camera that
    // draws the fog, has its map drawn; a traced light with none, or any light with the fog off, skips it as before.
    const auto draws_of = [](render::RtShadows mode, bool fog, float volumetric) {
        Rig r;
        r.rays(mode);
        World w;
        make_room(w);
        add_lights(w, 3);
        w.each<Light>([&](Entity, Light& l) { l.volumetric = volumetric; });
        w.settings().volumetricFog = fog;
        w.settings().volumetricDensity = 0.05f;
        r.frames(w, 5);
        r.dev->clear_commands();
        r.frame(w);
        CHECK(r.errors().empty());
        int candidates = 0, traced = 0;
        r.status(candidates, traced);
        CHECK(traced == (mode == render::RtShadows::Off ? 0 : 3));
        return r.count(gpu::CommandKind::Draw);
    };
    {
        Rig probe;
        World w;
        make_room(w);
        add_lights(w, 1);
        w.each<Light>([](Entity, Light& l) { l.volumetric = 1.0f; });
        w.settings().volumetricFog = true;
        w.settings().volumetricDensity = 0.05f;
        probe.frame(w);
        REQUIRE(probe.renderer.stats().volumetricCameras ==
                1);  // the camera draws the fog: without it nothing would be tested
    }
    const int raster = draws_of(render::RtShadows::Off, true, 1.0f);
    const int shining = draws_of(render::RtShadows::Hard, true, 1.0f);
    const int dark = draws_of(render::RtShadows::Hard, true, 0.0f);
    const int noFog = draws_of(render::RtShadows::Hard, false, 1.0f);
    CHECK(shining == raster);  // every map is drawn: the march reads them
    CHECK(dark < shining);     // no light shines in the fog: the maps are not drawn
    CHECK(noFog < shining);    // no fog: the same
}
