// M79-P4b-1: per-pixel ray traced global illumination (render.rayTracing.gi = "perPixel"; shaders/rt/rt_gi_pixel.{hlsl,metal}, src/rt_effect.h,
// docs/design/ARCHITECTURE_RT_GI.md "Per pixel"). Here, on every host: the constants block and the binding contract shared by the HLSL, the MSL and the
// renderer, the lit shader's two constants blocks, and the renderer's frame on the RecordingDevice (nothing when off, the kernel and the denoiser's
// passes when on, the fallback with the reason when the device refuses). The kernel runs for real in rt_gi_pixel_metal_tests.cpp.
#include "test_util.h"

#include <algorithm>
#include <cstddef>
#include <fstream>
#include <iterator>
#include <set>
#include <sstream>
#include <string>
#include <vector>

#include "fa/render/raytracing.h"
#include "fa/scene/light_probes.h"
#include "fa/scene/lightmap_manifest.h"
#include "fa/scene/lightmap_uv.h"
#include "fa/scene/terrain.h"
#include "gpu/recording_device.h"
#include "renderer_test_access.h"
#include "rt_denoise.h"
#include "rt_effect.h"
#include "rt_gi.h"
#include "mesh_buffer_draw.h"
#include "rt_kernels.h"

using namespace fa;
using namespace fa::test;
using fa::render::RtEffectParams;
using fa::render::RtGiPixelParams;
using fa::render::RtGiPixelTail;

namespace {

std::string read_repo_file(const std::string& relative) {
    std::ifstream in(std::string(FA_REPO_ROOT) + "/" + relative, std::ios::binary);
    return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
}

// The member names between `// BEGIN <name>` and `// END <name>` of a kernel source, in order (comments, types and array sizes left out).
std::vector<std::string> block_fields(const std::string& source, const std::string& name) {
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
    const std::set<std::string> types = {"struct", name, "float4", "uint4", "RtEffectParams", "RtGiPixelTail"};
    std::istringstream in(clean);
    std::string tok;
    while (in >> tok) {
        if (types.count(tok)) continue;
        const std::size_t bracket = tok.find('[');
        out.push_back(bracket == std::string::npos ? tok : tok.substr(0, bracket));
    }
    return out;
}

std::vector<std::string> names_of(const std::string_view* first, const std::string_view* last) {
    std::vector<std::string> out;
    for (; first != last; ++first) out.emplace_back(*first);
    return out;
}

std::size_t count_of(std::string_view text, std::string_view needle) {
    std::size_t n = 0;
    for (std::size_t at = text.find(needle); at != std::string_view::npos; at = text.find(needle, at + 1)) ++n;
    return n;
}

}  // namespace

// ---- the contract shared by the HLSL, the MSL and the renderer -----------------------------------------------------------------------

TEST_CASE("rt gi pixel: the constants blocks are the same structs in C++, HLSL and MSL") {
    const std::string hlsl = read_repo_file("engine/render/shaders/rt/rt_gi_pixel.hlsl");
    REQUIRE_FALSE(hlsl.empty());
    const rt_kernels::RtKernel* k = rt_kernels::find_rt_kernel("rt_gi_pixel");
    REQUIRE(k != nullptr);
    const std::string msl(k->msl);
    const std::vector<std::string> effect =
        names_of(std::begin(render::kRtEffectParamNames), std::end(render::kRtEffectParamNames));
    const std::vector<std::string> tail =
        names_of(std::begin(render::kRtGiPixelTailNames), std::end(render::kRtGiPixelTailNames));
    const std::vector<std::string> params =
        names_of(std::begin(render::kRtGiPixelParamNames), std::end(render::kRtGiPixelParamNames));
    REQUIRE(effect.size() == 25);
    REQUIRE(tail.size() == 5);
    for (const std::string* src : {&hlsl, &msl}) {
        INFO(std::string(src == &hlsl ? "hlsl" : "msl"));
        CHECK(block_fields(*src, "RtEffectParams") == effect);
        CHECK(block_fields(*src, "RtGiPixelTail") == tail);
        CHECK(block_fields(*src, "RtGiPixelParams") == params);
    }
    CHECK(sizeof(RtGiPixelTail) == 17 * 16);
    CHECK(sizeof(RtGiPixelParams) == 42 * 16);
    CHECK(sizeof(RtGiPixelParams) <= 4096);  // Metal's limit for a uniform block set by bytes
    CHECK(offsetof(RtGiPixelParams, e) == 0);
    CHECK(offsetof(RtGiPixelParams, tail) == sizeof(RtEffectParams));
    CHECK(offsetof(RtGiPixelTail, count) == 0);
    CHECK(offsetof(RtGiPixelTail, grid0) == 16);
    CHECK(offsetof(RtGiPixelTail, grid1) == 16 + 4 * 16);
    CHECK(offsetof(RtGiPixelTail, grid2) == 16 + 8 * 16);
    CHECK(offsetof(RtGiPixelTail, grid3) == 16 + 12 * 16);
    CHECK(render::kRtGiPixelMaxGrids == 4);
}

TEST_CASE("rt gi pixel: the kernel table has rt_gi_pixel, a spec that asks for the records and the atlas, and the "
          "binding contract of every backend") {
    const rt_kernels::RtKernel* k = rt_kernels::find_rt_kernel("rt_gi_pixel");
    REQUIRE(k != nullptr);
    const render::RtEffectKernelSpec* spec = render::find_rt_effect_spec("rt_gi_pixel");
    REQUIRE(spec != nullptr);
    CHECK(spec->usesTlas);
    CHECK(spec->usesRecords);
    CHECK(spec->usesHit);
    CHECK(spec->usesAtlas);
    CHECK_FALSE(spec->usesGbuffer);
    CHECK_FALSE(spec->usesAux);
    CHECK_FALSE(spec->outHalf);  // RtEffects makes RGBA32F images
    CHECK(spec->paramsSize == sizeof(RtGiPixelParams));
    CHECK(k->msl.find("kernel void rt_gi_pixel") != std::string_view::npos);
    // One query site: Metal's compiler unrolls a kernel that has several (docs/design/ARCHITECTURE_RT_EFFECTS.md).
    CHECK(count_of(k->msl, "intersection_query<") == 1);
    CHECK(count_of(k->msl, "rt_gi_pixel(") >= 1);
    for (gpu::Backend backend :
         {gpu::Backend::Metal, gpu::Backend::Recording, gpu::Backend::D3d12, gpu::Backend::Vulkan}) {
        INFO("backend " << int(backend));
        const gpu::ShaderDesc d = render::rt_effect_shader_desc(*k, *spec, backend);
        REQUIRE(d.compute());
        CHECK(d.usesRayQuery);
        CHECK(d.uniformBlocks[0].size == sizeof(RtGiPixelParams));
        CHECK(d.uniformBlocks[0].binding.hlslRegister == 0);
        CHECK(d.uniformBlocks[0].binding.mslIndex == 1);
        CHECK(d.uniformBlocks[0].binding.spirvBinding == 2);
        const gpu::ShaderStorageImageView& out = d.views[0].storageImage;
        CHECK(out.stage == gpu::ShaderStage::Compute);
        CHECK(out.accessFormat == gpu::PixelFormat::Rgba32F);
        CHECK(out.binding.spirvBinding == 1);
        CHECK(d.views[1].texture.binding.hlslRegister == 1);  // the prepass
        CHECK(d.views[1].texture.binding.mslIndex == 1);
        CHECK(d.views[1].texture.binding.spirvBinding == 3);
        CHECK(d.views[2].storageBuffer.binding.mslIndex == 8);  // the records
        CHECK(d.views[2].storageBuffer.binding.spirvBinding == 4);
        CHECK(d.views[3].texture.stage == gpu::ShaderStage::Compute);  // the probe atlas, at the albedo slot
        CHECK(d.views[3].texture.binding.hlslRegister == 3);
        CHECK(d.views[3].texture.binding.mslIndex == 2);
        CHECK(d.views[3].texture.binding.spirvBinding == 5);
        CHECK(d.views[4].stage() == gpu::ShaderStage::None);  // no material image
        if (backend == gpu::Backend::D3d12) CHECK(d.computeFunc.bytecode.size == k->dxil.size());
        if (backend == gpu::Backend::Vulkan) CHECK(d.computeFunc.bytecode.size == k->spirv.size());
        if (backend == gpu::Backend::Metal) CHECK(std::string(d.computeFunc.entry) == "rt_gi_pixel");
    }
    // The kernel of the probes shares its grid sampling with this one: the same two include files.
    CHECK(k->msl.find("gi_grid_light") != std::string_view::npos);
    const rt_kernels::RtKernel* probes = rt_kernels::find_rt_kernel("rt_gi");
    REQUIRE(probes != nullptr);
    CHECK(probes->msl.find("gi_grid_light") != std::string_view::npos);
}

TEST_CASE("rt gi pixel: the lit shader's constants block has fa_gi_px, in the same place in both templates") {
    for (const char* file : {"engine/render/shaders/mesh_common.glsl", "engine/render/shaders/mesh_full_common.glsl"}) {
        INFO(file);
        const std::string text = read_repo_file(file);
        REQUIRE_FALSE(text.empty());
        const std::size_t gi = text.find("vec4 fa_gi;");
        const std::size_t px = text.find("vec4 fa_gi_px;");
        REQUIRE(gi != std::string::npos);
        REQUIRE(px != std::string::npos);
        CHECK(px > gi);
        CHECK(text.find("vec4", gi + 5) == px);  // the next member after fa_gi, the last one of the block
    }
    const std::string lit = read_repo_file("engine/render/shaders/mesh_common.glsl");
    CHECK(lit.find("fa_gi_px.x > 0.5") != std::string::npos);
}

// ---- the renderer's frame on the RecordingDevice -------------------------------------------------------------------------------------

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

    void gi(render::RtGi mode, int raysPerPixel = 1, bool enabled = true) {
        render::RayTracingSettings s;
        s.enabled = enabled;
        s.gi = mode;
        s.raysPerPixel = raysPerPixel;
        renderer.set_ray_tracing(s);
    }
    void frame(World& w) {
        renderer.update(w);
        renderer.begin_frame();
        renderer.render_world(w, 0.0f);
        renderer.end_frame();
    }
    render::RtEffects& effects() { return *RendererTestAccess::rt_effects(renderer); }
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
    render::RtGiPixelStatus status() const { return renderer.ray_tracing_gi_pixel_status(); }
};

// A camera, a floor, a box, a sun and (optionally) one realtime GI grid.
void make_scene(World& w, bool withGrid = false) {
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
    w.add<Light>(sun).type = LightType::Directional;
    if (withGrid) {
        Entity g = make(w, "gi", {0, 2, 0});
        auto& gi = w.add<RealtimeGI>(g);
        gi.size = {8, 0, 8};
        gi.spacing = 4.0f;
    }
}

int index_of(const std::vector<std::string>& lines, const std::string& needle) {
    for (std::size_t i = 0; i < lines.size(); ++i)
        if (lines[i].find(needle) != std::string::npos) return int(i);
    return -1;
}

int count_labels(const std::vector<std::string>& lines, const std::string& needle) {
    int n = 0;
    for (const std::string& l : lines) n += l.find(needle) != std::string::npos ? 1 : 0;
    return n;
}

}  // namespace

TEST_CASE("rt gi pixel: with gi off, or probes, nothing of the per-pixel mode is declared, made or kept") {
    for (const render::RtGi mode : {render::RtGi::Off, render::RtGi::Probes}) {
        Rig r;
        r.gi(mode);
        World w;
        make_scene(w, mode == render::RtGi::Probes);
        for (int i = 0; i < 3; ++i) {
            r.dev->clear_commands();
            r.frame(w);
            CHECK(r.errors().empty());
            CHECK(count_labels(r.lines(), "rt-gipixel") == 0);
            CHECK(count_labels(r.lines(), "rtd-") == 0);
        }
        CHECK(r.effects().image_count() == 0);
        CHECK(r.effects().kernel_count() == 0);
        const auto* denoiser = RendererTestAccess::rt_denoiser(r.renderer);
        REQUIRE(denoiser != nullptr);
        CHECK(denoiser->history_image_count() == 0);
        const render::RtGiPixelStatus st = r.status();
        CHECK_FALSE(st.wanted);
        CHECK_FALSE(st.active);
        CHECK(st.reason.empty());
    }
}

TEST_CASE(
    "rt gi pixel: perPixel declares one compute pass after the TLAS and the prepass, then the denoiser, before the "
    "lit pass") {
    Rig r;
    r.gi(render::RtGi::PerPixel, 2);
    World w;
    make_scene(w, true);
    r.frame(w);  // the first frames build the BLASes
    r.frame(w);
    r.dev->clear_commands();
    r.frame(w);
    INFO(r.errors());
    CHECK(r.errors().empty());
    const std::vector<std::string> passes = r.compute_passes();
    REQUIRE(passes.size() == 1);
    CHECK(passes[0].find("rt-gipixel") != std::string::npos);
    const std::vector<std::string> lines = r.lines();
    const int tlas = index_of(lines, "build_tlas");
    const int prepass = index_of(lines, "begin_pass 'prepass'");
    const int kernel = index_of(lines, "rt-gipixel");
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
    CHECK(count_labels(lines, "begin_pass 'rtd-guide'") == 1);
    CHECK(count_labels(lines, "begin_pass 'rtd-temporal'") == 1);
    CHECK(r.count(gpu::CommandKind::Dispatch) == 1);
    CHECK(r.effects().image_count() == 1);
    CHECK(r.effects().kernel_count() == 1);
    // The output, the prepass, the records and the atlas, the 672-byte block, the 96-byte hit block, one dispatch over 160 x 96 pixels.
    REQUIRE(std::size_t(kernel) + 5 < lines.size());
    CHECK(lines[std::size_t(kernel) + 2].find("views=") != std::string::npos);
    bool block = false, hit = false, dispatch = false;
    for (std::size_t i = std::size_t(kernel); i < lines.size() && i < std::size_t(kernel) + 8; ++i) {
        block = block || lines[i].find("set_uniforms 0 672B") != std::string::npos;
        hit = hit || lines[i].find("set_uniforms 1 ") != std::string::npos;
        dispatch = dispatch || lines[i].find("dispatch 20 12 1") != std::string::npos;
    }
    CHECK(block);
    CHECK(hit);
    CHECK(dispatch);
    const render::RtGiPixelStatus st = r.status();
    CHECK(st.wanted);
    CHECK(st.active);
    CHECK(st.reason.empty());
}

TEST_CASE("rt gi pixel: the denoiser has its own signal, and the recorded frame is the same every run") {
    std::vector<std::string> first;
    for (int run = 0; run < 2; ++run) {
        Rig r;
        r.gi(render::RtGi::PerPixel);
        World w;
        make_scene(w, true);
        r.frame(w);
        r.frame(w);
        const auto* denoiser = RendererTestAccess::rt_denoiser(r.renderer);
        REQUIRE(denoiser != nullptr);
        CHECK(denoiser->shaders_made());
        CHECK(denoiser->history_image_count() > 0);
        r.dev->clear_commands();
        r.frame(w);
        const std::vector<std::string> lines = r.lines();
        if (run == 0)
            first = lines;
        else
            CHECK(lines == first);  // the seed is the frame serial's: no clock, no random number
    }
    CHECK_FALSE(first.empty());
}

TEST_CASE(
    "rt gi pixel: turning the mode off frees the kernel, the image and the denoiser, and ray tracing off frees all") {
    Rig r;
    r.gi(render::RtGi::PerPixel);
    World w;
    make_scene(w);
    for (int i = 0; i < 3; ++i) r.frame(w);
    CHECK(r.effects().image_count() == 1);
    CHECK(r.effects().kernel_count() == 1);
    const auto* denoiser = RendererTestAccess::rt_denoiser(r.renderer);
    REQUIRE(denoiser != nullptr);
    CHECK(denoiser->history_image_count() > 0);
    r.gi(render::RtGi::Off);
    r.dev->clear_commands();
    for (int i = 0; i < 6; ++i) r.frame(w);
    CHECK(r.effects().image_count() == 0);
    CHECK(r.effects().kernel_count() == 0);
    CHECK(denoiser->history_image_count() == 0);
    CHECK_FALSE(r.status().wanted);
    r.gi(render::RtGi::PerPixel);
    r.frame(w);
    r.frame(w);
    CHECK(r.effects().image_count() == 1);
    r.gi(render::RtGi::PerPixel, 1, false);  // the master switch off
    r.frame(w);
    CHECK(r.effects().empty());
    CHECK_FALSE(denoiser->shaders_made());
    CHECK(denoiser->history_image_count() == 0);
    CHECK(r.errors().empty());
}

TEST_CASE("rt gi pixel: raysPerPixel out of range (0, 40) still draws one clean frame, the kernel clamps it to 1..16") {
    Rig r;
    World w;
    make_scene(w);
    for (const int asked : {3, 40, 0}) {
        INFO("asked " << asked);
        r.gi(render::RtGi::PerPixel, asked);
        r.frame(w);
        r.frame(w);
        r.dev->clear_commands();
        r.frame(w);
        CHECK(r.errors().empty());
        CHECK(count_labels(r.lines(), "rt-gipixel") == 1);
        CHECK(r.status().active);
    }
}

TEST_CASE("rt gi pixel: a pipeline the driver refuses falls back at once with the reason and tries again after 120 "
          "frames") {
    Rig r;
    r.dev->inject_faults(true, false);
    r.gi(render::RtGi::PerPixel);
    World w;
    make_scene(w);
    for (int i = 0; i < 6; ++i) r.frame(w);
    render::RtGiPixelStatus st = r.status();
    CHECK(st.wanted);
    CHECK_FALSE(st.active);
    INFO(st.reason);
    CHECK(st.reason.find("pipeline") != std::string::npos);
    // The device recovers; the fallback keeps the probes until its 120 frames are over, then the kernel is tried again.
    r.dev->inject_faults(false, false);
    int firstActive = -1;
    for (int i = 0; i < 2 * render::kGiRtRetryFrames + 8; ++i) {
        r.frame(w);
        if (firstActive < 0 && r.status().active) firstActive = i;
    }
    MESSAGE("first active frame after the recovery: " << firstActive);
    CHECK(firstActive >= 0);
    CHECK(firstActive > render::kGiRtRetryFrames / 4);  // not at once: the retry is counted in frames
    CHECK(firstActive <= render::kGiRtRetryFrames + 8);
    CHECK(r.status().active);
}

TEST_CASE("rt gi pixel: a traced scene that never builds falls back after a few frames, and the rays come back when it "
          "does") {
    Rig r;
    r.dev->inject_faults(false, true);
    r.gi(render::RtGi::PerPixel);
    World w;
    make_scene(w);
    r.frame(w);
    render::RtGiPixelStatus st = r.status();
    CHECK_FALSE(st.active);  // the first frame has no result yet
    for (int i = 0; i < 6; ++i) r.frame(w);
    st = r.status();
    CHECK(st.wanted);
    CHECK_FALSE(st.active);
    INFO(st.reason);
    CHECK_FALSE(st.reason.empty());
    // While the fallback runs the pass is not declared at all: the lit shader reads the probes and the ambient.
    r.dev->clear_commands();
    r.frame(w);
    CHECK(count_labels(r.lines(), "rt-gipixel") == 0);
    r.dev->inject_faults(false, false);
    int firstActive = -1;
    for (int i = 0; i < 2 * render::kGiRtRetryFrames + 8; ++i) {
        r.frame(w);
        if (firstActive < 0 && r.status().active) firstActive = i;
    }
    MESSAGE("first active frame after the recovery: " << firstActive);
    CHECK(firstActive >= 0);
    CHECK(r.status().active);
}

TEST_CASE(
    "rt gi pixel: a device that cannot trace keeps the probes and the ambient, says why and spends nothing on rays") {
    Rig r(false);
    r.gi(render::RtGi::PerPixel);
    World w;
    make_scene(w, true);
    for (int i = 0; i < 3; ++i) {
        r.dev->clear_commands();
        r.frame(w);
        CHECK(r.errors().empty());
        CHECK(r.compute_passes().empty());
        CHECK(count_labels(r.lines(), "rt-gipixel") == 0);
    }
    CHECK(r.effects().image_count() == 0);
    const render::RtGiPixelStatus st = r.status();
    CHECK_FALSE(st.active);
}

// ---- which draws read the image --------------------------------------------------------------------------------------------------------

namespace {

// A baked probe set (one grid group around the origin, every probe holding the same SH) written as the scene's lightmap manifest.
void write_probe_manifest(World& w, const char* name) {
    std::filesystem::create_directories(gfx().projectDir / "scenes");
    ProbeSet set;
    LightProbeGroup comp;
    comp.size = {24, 8, 24};
    comp.spacing = 4.0f;
    REQUIRE(add_probe_group(set, "group", comp, {0, 0, 0}).ok());
    ShL2 sh;
    for (Vec3& c : sh.c) c = {0, 0, 0};
    sh.c[0] = {0.5f * 3.5449077f, 0.5f * 3.5449077f, 0.5f * 3.5449077f};
    set.sh.assign(set.size(), sh);
    set.valid.assign(set.size(), 1);
    const std::string probesFile = std::string("scenes/") + name + ".lightmap.probes";
    const std::vector<std::uint8_t> bytes = encode_probe_set(set);
    REQUIRE(fs::write_bytes(probesFile, bytes.data(), bytes.size()).ok());
    LightmapManifest m;
    m.uvVersion = kLightmapUvVersion;
    m.settingsHash = "0123456789abcdef";
    m.probes.file = probesFile;
    m.probes.count = int(set.size());
    m.probes.invalid = 0;
    const std::string path = std::string("scenes/") + name + ".lightmap.json";
    REQUIRE(fs::write_text(path, lightmap_manifest_to_json(m).dump(2)).ok());
    w.settings().lightmaps = path;
}

// A few frames so that the traced scene is built and the kernel has run (the main pass binds its image from then on); the draws of the last one.
RendererTestAccess::GiPixelDraws draws_after(Rig& r, World& w) {
    for (int i = 0; i < 5; ++i) r.frame(w);
    REQUIRE(r.status().active);
    return RendererTestAccess::rt_gi_pixel_draws(r.renderer);
}

}  // namespace

TEST_CASE("rt gi pixel: the opaque meshes read the image; a mesh with baked light probes keeps them (the baked light "
          "has priority)") {
    {
        Rig r;
        r.gi(render::RtGi::PerPixel);
        World w;
        make_scene(w);
        const auto d = draws_after(r, w);
        CHECK(d.on >= 2);  // the floor and the box
        CHECK(d.off == 0);
    }
    {
        Rig r;
        r.gi(render::RtGi::PerPixel);
        gfx().renderer.clear_asset_cache();
        World w;
        make_scene(w);
        write_probe_manifest(w, "gipx_probes");
        const auto d = draws_after(r, w);
        INFO(r.errors());
        CHECK(d.off >= 2);  // both meshes sit in the grid: their SH lights them, the traced image is not read
        CHECK(d.on == 0);
    }
}

TEST_CASE("rt gi pixel: a part the prepass does not draw (a full shader that keeps out of it, buffers with no prepass "
          "program) is no receiver") {
    using fa::render::MeshBufferUse;
    using fa::render::prepass_draws;
    MeshBufferUse plain;  // a mesh with no buffers
    CHECK(prepass_draws(false, plain, true));
    CHECK(prepass_draws(false, plain, false));      // the engine's program draws it
    CHECK_FALSE(prepass_draws(true, plain, true));  // a full shader with "prepass": false
    MeshBufferUse buffers;
    buffers.active = true;
    CHECK(prepass_draws(false, buffers, true));         // the material's own prepass program places the instances
    CHECK_FALSE(prepass_draws(false, buffers, false));  // the engine's program cannot place what the buffers place
    MeshBufferUse failed;
    failed.skip = true;
    CHECK_FALSE(prepass_draws(false, failed, true));
}

TEST_CASE("rt gi pixel: a terrain keeps the probes and the ambient light, the meshes beside it read the image") {
    Rig r;
    r.gi(render::RtGi::PerPixel);
    constexpr int kSamples = 33;
    GrayImage16 g;
    g.width = g.height = kSamples;
    g.sixteenBit = true;
    g.samples.assign(std::size_t(kSamples) * kSamples, std::uint16_t(20000));
    const auto png = encode_png_gray16(g);
    const std::string file = fs::path_to_utf8(gfx().projectDir / "gipx_flat.png");
    REQUIRE(fs::write_bytes(file, png.data(), png.size()).ok());
    World w;
    make_scene(w);
    Entity ground = make(w, "ground", {0, -2, 0});
    auto& t = w.add<Terrain3D>(ground);
    t.heightmap = file;
    t.size = {32.0f, 32.0f};
    t.heightScale = 4.0f;
    const auto d = draws_after(r, w);
    INFO(r.errors());
    CHECK(d.on >= 2);   // the floor and the box
    CHECK(d.off >= 1);  // the terrain's nodes
}
