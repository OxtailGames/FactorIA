// M76-P6a: the graphics preset tables (fa/render/graphics_preset.h), what the GPU caps (src/quality.h), the cap on a camera's post stack,
// the GPU classification and the preset a benchmark suggests (fa/render/gpu_info.h), and on a GPU: a preset changes the picture, `custom`
// brings the game's own back bit for bit, and the benchmark leaves the renderer as it found it.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <string>
#include <vector>

#include "fa/render/gpu_info.h"
#include "fa/render/graphics_preset.h"
#include "postprocess_resolve.h"
#include "quality.h"
#include "render_internal.h"
#include "render_features.h"
#include "renderer_test_access.h"

using namespace fa;
using namespace fa::render;
using namespace fa::test;

namespace {

FeatureEnv env_of(FeatureBackend b, bool half = true, bool packed = true, bool depth = true, bool compute = false,
                  bool float32 = true) {
    FeatureEnv e;
    e.backend = b;
    e.float32 = float32;
    e.halfTargets = half;
    e.r11g11b10 = packed;
    e.sampledDepth = depth;
    e.compute = compute;
    e.maxTextureSize = 16384;
    return e;
}

int differing(const Image& a, const Image& b) {
    REQUIRE(a.width == b.width);
    REQUIRE(a.height == b.height);
    int n = 0;
    for (std::size_t i = 0; i + 3 < a.rgba.size(); i += 4)
        if (a.rgba[i] != b.rgba[i] || a.rgba[i + 1] != b.rgba[i + 1] || a.rgba[i + 2] != b.rgba[i + 2] ||
            a.rgba[i + 3] != b.rgba[i + 3])
            ++n;
    return n;
}

// The stack the renderer would resolve for a camera whose own PostProcess is `pp` (no volumes).
PostStack stack_of(const PostProcess& pp) {
    PostStack s;
    s.fx = pp;
    const auto set = [&](PostEffect e, bool on) {
        if (on) s.mask |= 1u << int(e);
    };
    set(PostEffect::Ssao, pp.ssaoEnabled);
    set(PostEffect::Ssr, pp.ssrEnabled);
    set(PostEffect::SunShafts, pp.sunShaftsEnabled);
    set(PostEffect::TemporalAA, pp.temporalAAEnabled);
    set(PostEffect::DepthOfField, pp.depthOfFieldEnabled);
    set(PostEffect::MotionBlur, pp.motionBlurEnabled);
    return s;
}

}  // namespace

TEST_CASE("graphics presets: Low, Medium, High, Ultra are monotone on every knob and Ultra is no limit") {
    const std::vector<std::string>& names = quality_knob_names();
    REQUIRE(names.size() > 20);
    std::vector<double> prev = quality_knob_levels(graphics_preset_table(GraphicsPreset::Low).limits);
    REQUIRE(prev.size() == names.size());
    for (GraphicsPreset p : {GraphicsPreset::Medium, GraphicsPreset::High, GraphicsPreset::Ultra}) {
        const std::vector<double> now = quality_knob_levels(graphics_preset_table(p).limits);
        REQUIRE(now.size() == names.size());
        for (std::size_t i = 0; i < names.size(); ++i)
            CHECK_MESSAGE(now[i] >= prev[i], names[i], " of ", graphics_preset_name(p),
                          " is below the preset before it");
        prev = now;
    }
    // Each knob changes somewhere between Low and Ultra: a table that left one at its default everywhere would be dead.
    const std::vector<double> low = quality_knob_levels(graphics_preset_table(GraphicsPreset::Low).limits);
    for (std::size_t i = 0; i < names.size(); ++i)
        CHECK_MESSAGE(prev[i] > low[i], names[i], " never changes between low and ultra");
    // Ultra and Custom limit nothing and write no upscaler: nothing of the game's own look is touched (the pixel test of the Engine, in
    // engine/runtime/tests, compares them with the upscaler merged in).
    CHECK(graphics_preset_table(GraphicsPreset::Ultra).limits == QualityLimits{});
    CHECK(graphics_preset_table(GraphicsPreset::Custom).limits == QualityLimits{});
    CHECK_FALSE(graphics_preset_table(GraphicsPreset::Ultra).upscaler.has_value());
    CHECK_FALSE(graphics_preset_table(GraphicsPreset::Custom).upscaler.has_value());
    // Low, Medium and High set the upscaler to auto, with less scaling the higher the preset is.
    float last = 0.0f;
    for (GraphicsPreset p : {GraphicsPreset::Low, GraphicsPreset::Medium, GraphicsPreset::High}) {
        const auto& up = graphics_preset_table(p).upscaler;
        REQUIRE(up.has_value());
        CHECK(up->mode == UpscalerMode::Auto);
        const float scale = upscaler_quality_scale(up->quality);
        CHECK(scale > last);
        last = scale;
    }
    CHECK(last < 1.0f);
}

TEST_CASE("graphics presets: the JSON of the limits names every knob once and round-trips the names") {
    const Json j = quality_limits_to_json(graphics_preset_table(GraphicsPreset::Medium).limits);
    REQUIRE(j.is_object());
    CHECK(j.size() == quality_knob_names().size());
    for (const std::string& k : quality_knob_names()) CHECK_MESSAGE(j.contains(k), k);
    CHECK(j["shadowCascades"] == 2);
    CHECK(j["ssaoQuality"] == "medium");
    CHECK(j["lodDistanceScale"] == 1.5);
    CHECK(j["temporalAA"] == true);
    CHECK(j["ssr"] == false);
    for (int i = 0; i < kGraphicsPresetCount; ++i) {
        const std::string n(graphics_preset_name(GraphicsPreset(i)));
        REQUIRE(parse_graphics_preset(n).has_value());
        CHECK(int(*parse_graphics_preset(n)) == i);
    }
    CHECK(quality_limits_to_json(QualityLimits{}) ==
          quality_limits_to_json(graphics_preset_table(GraphicsPreset::Ultra).limits));
}

TEST_CASE("graphics presets: every limit of every preset is inside what the backends support, and the cap says why") {
    struct B {
        FeatureBackend b;
        FeatureEnv env;
    };
    const std::vector<B> backends = {
        {FeatureBackend::D3d11, env_of(FeatureBackend::D3d11, true, true, true, true)},
        {FeatureBackend::Metal, env_of(FeatureBackend::Metal, true, true, true, true)},
        {FeatureBackend::Gl, env_of(FeatureBackend::Gl, true, true, true, true)},
        {FeatureBackend::Gles3, env_of(FeatureBackend::Gles3, true, true, true, false)},
        {FeatureBackend::WebGl2, env_of(FeatureBackend::WebGl2, false, false, false, false, false)}};
    for (const B& be : backends) {
        for (int i = 0; i < kGraphicsPresetCount; ++i) {
            if (GraphicsPreset(i) == GraphicsPreset::Custom)
                continue;  // no limit at all: nothing to cap, the scene decides
            const QualityResolved r = resolve_quality(GraphicsPreset(i), be.env);
            CHECK(r.gpu);
            const QualityLimits& q = r.limits;
            const auto on = [&](const char* feature) {
                const int f = find_feature(feature);
                REQUIRE(f >= 0);
                return feature_supported(be.env, f);
            };
            // A knob left on is a feature the backend draws.
            if (q.ssao) CHECK(on("ssao"));
            if (q.ssr) CHECK(on("ssr"));
            if (q.temporalAA) CHECK(on("temporalAA"));
            if (q.sunShafts) CHECK(on("sunShafts"));
            if (q.depthOfField) CHECK(on("depthOfField"));
            if (q.motionBlur) CHECK(on("motionBlur"));
            if (q.contactShadows) CHECK(on("contactShadows"));
            if (q.volumetricFog) CHECK(on("volumetricFog"));
            if (q.gi2d) CHECK(on("2dGlobalIllumination"));
            if (q.shadowCascades > 0) CHECK(on("cascadedShadows"));
            if (q.localShadows) CHECK((on("pointShadows") && on("spotShadows")));
            CHECK(q.shadowAtlasSize <= be.env.maxTextureSize);
            CHECK(q.shadowTileSize <= q.shadowAtlasSize);
            // The caps never raise a knob over the table, and each carries a reason.
            const QualityLimits& t = graphics_preset_table(GraphicsPreset(i)).limits;
            const std::vector<double> lt = quality_knob_levels(t), lq = quality_knob_levels(q);
            for (std::size_t k = 0; k < lt.size(); ++k) CHECK(lq[k] <= lt[k]);
            for (const QualityCap& c : r.capped) {
                CHECK_FALSE(c.reason.empty());
                CHECK(c.wanted != c.effective);
            }
        }
    }
    // A GPU with everything: Ultra and Custom are not capped. The web (no float or half targets) caps what needs them, with a reason.
    // (temporalAA is a row of the table that says "planned, not drawn yet": it is the only cap a GPU with everything gets, until it lands.)
    const FeatureEnv full = env_of(FeatureBackend::D3d11, true, true, true, true);
    const QualityResolved ultra = resolve_quality(GraphicsPreset::Ultra, full);
    CHECK(ultra.capped.size() == (feature_supported(full, find_feature("temporalAA")) ? 0u : 1u));
    for (const QualityCap& c : ultra.capped) CHECK(c.knob == "temporalAA");
    CHECK(resolve_quality(GraphicsPreset::Custom, full).capped.empty());
    const QualityResolved web = resolve_quality(GraphicsPreset::Ultra, backends.back().env);
    CHECK_FALSE(web.capped.empty());
    CHECK_FALSE(web.limits.volumetricFog);
    CHECK(web.limits.shadowCascades == 0);
    // No GPU (the headless backend): the table as it is.
    const QualityResolved none = resolve_quality(GraphicsPreset::High, FeatureEnv{});
    CHECK_FALSE(none.gpu);
    CHECK(none.capped.empty());
    CHECK(none.limits == graphics_preset_table(GraphicsPreset::High).limits);
    CHECK(resolve_graphics_preset_uncapped(GraphicsPreset::Low).limits ==
          graphics_preset_table(GraphicsPreset::Low).limits);
    // The atlas is no larger than the GPU's largest texture.
    FeatureEnv small = env_of(FeatureBackend::Gles3, true, true, true, false);
    small.maxTextureSize = 2048;
    const QualityResolved capped = resolve_quality(GraphicsPreset::Ultra, small);
    CHECK(capped.limits.shadowAtlasSize == 2048);
    CHECK(capped.limits.shadowTileSize == 2048);
}

TEST_CASE("graphics presets: a limit lowers the post stack of a camera and never raises it") {
    PostProcess pp;
    pp.ssaoEnabled = true;
    pp.ssaoQuality = SsaoQuality::Ultra;
    pp.ssrEnabled = true;
    pp.ssrSteps = 100;
    pp.motionBlurEnabled = true;
    pp.motionBlurSamples = 20;
    pp.depthOfFieldEnabled = true;
    pp.depthOfFieldBokeh = true;
    pp.temporalAAEnabled = true;
    pp.sunShaftsEnabled = true;
    PostStack full = stack_of(pp);
    REQUIRE(full.has(PostEffect::Ssao));
    PostStack low = full;
    apply_quality_limits(low, graphics_preset_table(GraphicsPreset::Low).limits);
    for (PostEffect e : {PostEffect::Ssao, PostEffect::Ssr, PostEffect::MotionBlur, PostEffect::DepthOfField,
                         PostEffect::TemporalAA, PostEffect::SunShafts})
        CHECK_FALSE(low.has(e));
    PostStack medium = full;
    apply_quality_limits(medium, graphics_preset_table(GraphicsPreset::Medium).limits);
    CHECK(medium.has(PostEffect::Ssao));
    CHECK(medium.fx.ssaoQuality == SsaoQuality::Medium);
    CHECK(medium.fx.motionBlurSamples == 8);
    CHECK_FALSE(medium.fx.depthOfFieldBokeh);
    CHECK_FALSE(medium.has(PostEffect::Ssr));
    // A scene that asks for less than the limit keeps what it asked for.
    PostProcess gentle;
    gentle.ssaoEnabled = true;
    gentle.ssaoQuality = SsaoQuality::Low;
    gentle.motionBlurEnabled = true;
    gentle.motionBlurSamples = 6;
    PostStack g = stack_of(gentle);
    apply_quality_limits(g, graphics_preset_table(GraphicsPreset::High).limits);
    CHECK(g.fx.ssaoQuality == SsaoQuality::Low);
    CHECK(g.fx.motionBlurSamples == 6);
    // Ultra changes nothing.
    PostStack u = full;
    apply_quality_limits(u, graphics_preset_table(GraphicsPreset::Ultra).limits);
    CHECK(u.mask == full.mask);
    CHECK(u.fx.ssrSteps == 100);
}

TEST_CASE("gpu info: classify_gpu names the vendor and finds the software rasterisers") {
    const auto of = [](const char* name, const char* vendor = "") {
        GpuInfo i;
        i.name = name;
        classify_gpu(i, vendor);
        return i;
    };
    CHECK(of("NVIDIA GeForce RTX 4070/PCIe/SSE2", "NVIDIA Corporation").vendor == "nvidia");
    CHECK(of("AMD Radeon RX 7800 XT").vendor == "amd");
    CHECK(of("Intel(R) UHD Graphics 770").vendor == "intel");
    CHECK(of("Apple M5").vendor == "apple");
    CHECK(of("Adreno (TM) 740", "Qualcomm").vendor == "qualcomm");
    CHECK(of("Mali-G710", "ARM").vendor == "arm");
    CHECK(of("Something unheard of").vendor == "other");
    // "arm" and "ati" are vendors only as whole words (Karma, Mediatek, a "...ation " are not).
    CHECK(of("Karma Render Engine").vendor == "other");
    CHECK(of("Integrated Graphics Corporation").vendor == "other");
    CHECK(of("ARM Mali-G78").vendor == "arm");
    CHECK(of("ATI Radeon HD 5870").vendor == "amd");
    CHECK(of("ATI Technologies Inc.").vendor == "amd");
    CHECK(of("").vendor.empty());
    CHECK_FALSE(of("NVIDIA GeForce RTX 4070").software);
    for (const char* sw : {"llvmpipe (LLVM 19.1.1, 256 bits)", "Microsoft Basic Render Driver", "SwiftShader Device",
                           "softpipe", "Microsoft Basic Render Driver WARP"})
        CHECK_MESSAGE(of(sw).software, sw);
    CHECK(of("llvmpipe (LLVM 19.1.1, 256 bits)", "Mesa").vendor == "mesa");
    const Json j = of("llvmpipe").to_json();
    for (const char* k : {"backend", "name", "vendor", "driver", "memoryMB", "unifiedMemory", "software"})
        CHECK_MESSAGE(j.contains(k), k);
}

TEST_CASE("gpu info: the suggestion follows the benchmark, and the machine caps it") {
    GpuInfo gpu;
    gpu.backend = "d3d11";
    gpu.name = "A GPU";
    gpu.memoryMB = 8192;
    GpuBenchmark b;
    b.ran = true;
    b.samples = 5;
    DeviceClass desktop;
    desktop.tier = "high";
    const auto at = [&](double ms, const GpuInfo& g, const DeviceClass& d) {
        b.frameMs = ms;
        return suggest_graphics_preset(g, b, d);
    };
    CHECK(at(2.0, gpu, desktop).preset == GraphicsPreset::Ultra);
    CHECK(at(6.0, gpu, desktop).preset == GraphicsPreset::High);
    CHECK(at(12.0, gpu, desktop).preset == GraphicsPreset::Medium);
    CHECK(at(30.0, gpu, desktop).preset == GraphicsPreset::Low);
    CHECK_FALSE(at(2.0, gpu, desktop).reason.empty());
    // The reason names the budget and holds no measured time: it reaches scripts, and a time differs from machine to machine.
    CHECK(at(2.7, gpu, desktop).reason.find("2.7") == std::string::npos);
    CHECK(at(6.3, gpu, desktop).reason == at(7.9, gpu, desktop).reason);
    DeviceClass phone;
    phone.tier = "high";
    phone.formFactor = "phone";
    phone.handheld = true;
    const PresetSuggestion onPhone = at(2.0, gpu, phone);
    CHECK(onPhone.preset == GraphicsPreset::Medium);
    CHECK(onPhone.reason.find("capped at medium") != std::string::npos);
    DeviceClass deck;
    deck.tier = "high";
    deck.handheld = true;
    CHECK(at(2.0, gpu, deck).preset == GraphicsPreset::High);
    DeviceClass weak;
    weak.tier = "low";
    CHECK(at(2.0, gpu, weak).preset == GraphicsPreset::Medium);
    GpuInfo small = gpu;
    small.memoryMB = 1024;
    CHECK(at(2.0, small, desktop).preset == GraphicsPreset::Medium);
    small.unifiedMemory = true;  // shared memory is not a small video memory
    CHECK(at(2.0, small, desktop).preset == GraphicsPreset::Ultra);
    GpuInfo software = gpu;
    software.software = true;
    CHECK(at(0.5, software, desktop).preset == GraphicsPreset::Low);
    // Nothing measured: the tier decides, never ultra.
    GpuBenchmark none;
    none.why = "no GPU";
    CHECK(suggest_graphics_preset(GpuInfo{}, none, desktop).preset == GraphicsPreset::High);
    CHECK(suggest_graphics_preset(GpuInfo{}, none, weak).preset == GraphicsPreset::Low);
    DeviceClass mid;
    mid.tier = "medium";
    CHECK(suggest_graphics_preset(GpuInfo{}, none, mid).preset == GraphicsPreset::Medium);
    CHECK(suggest_graphics_preset(GpuInfo{}, none, desktop).reason.find("no GPU") != std::string::npos);
}

TEST_CASE("graphics presets on a GPU: custom brings back the game's own picture bit for bit, a low preset changes it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity cam = make(w, "cam", {0, 3, 9});
    w.get<Transform>(cam)->rotation = {-12, 0, 0};
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    PostProcess& pp = camera_post(w, cam);
    pp.ssaoEnabled = true;
    pp.ssaoQuality = SsaoQuality::High;
    pp.motionBlurEnabled = true;
    w.settings().ambientLight = Color{0.25f, 0.25f, 0.3f, 1};
    w.settings().shadowCascades = 4;
    Entity ground = make(w, "ground", {0, 0, 0});
    w.get<Transform>(ground)->scale = {30, 1, 30};
    w.add<MeshRenderer>(ground).mesh = "plane";
    for (int i = 0; i < 6; ++i) {
        Entity e = make(w, "ball", {float(i) * 2.0f - 5.0f, 1.0f, float(i % 3) * -3.0f});
        auto& m = w.add<MeshRenderer>(e);
        m.mesh = i % 2 ? "cube" : "sphere";
        m.color = Color::hex(0xc08040 + i * 0x101010);
    }
    Entity sun = make(w, "sun", {0, 5, 0});
    w.get<Transform>(sun)->rotation = {-50, 25, 0};
    auto& l = w.add<Light>(sun);
    l.type = LightType::Directional;
    l.castShadows = true;
    Entity pt = make(w, "lamp", {2, 3, 1});
    auto& pl = w.add<Light>(pt);
    pl.type = LightType::Point;
    pl.range = 12;
    pl.castShadows = true;

    g.renderer.set_quality(QualityLimits{});
    g.draw(w);
    const Image own = g.draw(w);
    const QualityLimits low = graphics_preset_table(GraphicsPreset::Low).limits;
    g.renderer.set_quality(low);
    CHECK(g.renderer.quality() == low);
    g.draw(w);
    const Image lowPic = g.draw(w);
    g.renderer.set_quality(graphics_preset_table(GraphicsPreset::Ultra).limits);  // Ultra = no limit
    g.draw(w);
    const Image ultraPic = g.draw(w);
    g.renderer.set_quality(QualityLimits{});  // custom
    g.draw(w);
    const Image back = g.draw(w);
    CHECK(differing(own, back) == 0);
    CHECK(differing(own, ultraPic) == 0);
    const FeatureEnv env = feature_env_from_device(RendererTestAccess::gpu(g.renderer)->device());
    const bool anyFeature =
        feature_supported(env, find_feature("ssao")) || feature_supported(env, find_feature("cascadedShadows"));
    if (anyFeature) {
        CHECK(differing(own, lowPic) > 0);
    } else {
        MESSAGE("this backend draws neither ambient occlusion nor cascaded shadows: low cannot change the picture");
    }
    // The components were never written.
    CHECK(w.get<PostProcess>(cam)->ssaoEnabled);
    CHECK(w.settings().shadowCascades == 4);
    // resolve_graphics_preset on a live renderer knows the GPU.
    const QualityResolved r = g.renderer.resolve_graphics_preset(GraphicsPreset::Ultra);
    CHECK(r.gpu);
    CHECK(r.preset == GraphicsPreset::Ultra);
}

TEST_CASE("gpu benchmark on a GPU: bounded, leaves the preset and the world alone, never run on a software renderer") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const GpuInfo info = g.renderer.gpu_info();
    CHECK(info.backend == Renderer::backend_name());
    const QualityLimits low = graphics_preset_table(GraphicsPreset::Low).limits;
    g.renderer.set_quality(low);
    const GpuBenchmark b = run_gpu_benchmark(g.renderer, info);
    CHECK(g.renderer.quality() == low);  // the preset in force was lifted while it ran and put back
    if (info.software) {
        CHECK_FALSE(b.ran);
        CHECK_FALSE(b.why.empty());
    } else if (b.ran) {
        CHECK(b.samples >= 1);
        CHECK(b.samples <= kBenchmarkSamples);
        CHECK(b.frameMs > 0.0);
        CHECK(b.totalMs >= b.frameMs);
        CHECK(b.width == 960);
        CHECK(b.height == 540);
    } else {
        MESSAGE("the benchmark did not run: " << b.why);
    }
    const Json j = b.to_json();
    CHECK(j.contains("ran"));
    CHECK(j.contains("frameMs"));
    g.renderer.set_quality(QualityLimits{});
    // A renderer that is not initialized has nothing to measure.
    Renderer none;
    const GpuBenchmark nb = run_gpu_benchmark(none, info);
    CHECK_FALSE(nb.ran);
    CHECK_FALSE(nb.why.empty());
}

TEST_CASE("graphics presets on a GPU: without soft shadows a PCSS sun is drawn with the PCF filter, as the local "
          "lights are") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    if (!g.renderer.supports("cascadedShadows")) {
        MESSAGE("cascadedShadows is not supported on this GPU: the test did not run");
        return;
    }
    World w;
    Entity cam = make(w, "cam", {0, 6, 9});
    w.get<Transform>(cam)->rotation = {-30, 0, 0};
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    w.settings().ambientLight = Color{0.1f, 0.1f, 0.12f, 1};
    w.settings().shadowCascades = 1;
    w.settings().shadowDistance = 30;
    Entity ground = make(w, "ground", {0, -0.5f, 0});
    w.get<Transform>(ground)->scale = {20, 1, 20};
    auto& gm = w.add<MeshRenderer>(ground);
    gm.mesh = "plane";
    gm.color = Color::hex(0xc8c8c8);
    Entity pillar = make(w, "pillar", {-1, 3.5f, 0});
    w.get<Transform>(pillar)->scale = {0.6f, 6, 0.6f};
    auto& pm = w.add<MeshRenderer>(pillar);
    pm.mesh = "cube";
    pm.color = Color::hex(0xd0d0d0);
    Entity sun = make(w, "sun", {0, 5, 0});
    w.get<Transform>(sun)->rotation = {-50, 35, 0};
    auto& l = w.add<Light>(sun);
    l.type = LightType::Directional;
    l.castShadows = true;
    l.shadowSoftness = 4;
    l.shadowFilter = ShadowFilter::Pcf;
    g.renderer.set_quality(QualityLimits{});
    g.draw(w);
    const Image pcf = g.draw(w);
    l.shadowFilter = ShadowFilter::Pcss;
    g.draw(w);
    const Image pcss = g.draw(w);
    CHECK(differing(pcf, pcss) > 20);  // the filter is visible in this scene
    QualityLimits noSoft;
    noSoft.softShadows = false;
    g.renderer.set_quality(noSoft);
    g.draw(w);
    const Image limited = g.draw(w);
    CHECK(differing(limited, pcf) == 0);  // the limit turns the PCSS sun into the PCF one
    g.renderer.set_quality(QualityLimits{});
    g.draw(w);
    CHECK(differing(g.draw(w), pcss) == 0);  // and lifting it brings the scene's own filter back
}

TEST_CASE(
    "graphics presets on a GPU: the Low preset caps the shadow map of a spot light with no size of its own at 512") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    CHECK(graphics_preset_table(GraphicsPreset::Low).limits.shadowTileSize == 512);
    if (!g.renderer.supports("spotShadows")) {
        MESSAGE("spotShadows is not supported on this GPU: the test did not run");
        return;
    }
    World w;
    Entity cam = make(w, "cam", {0, 4, 9});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    w.get<Transform>(cam)->rotation = {-25, 0, 0};
    w.settings().ambientLight = Color{0.05f, 0.05f, 0.06f, 1};
    Entity floor = make(w, "floor", {0, 0, 0});
    w.get<Transform>(floor)->scale = {16, 1, 16};
    w.add<MeshRenderer>(floor).mesh = "plane";
    Entity pillar = make(w, "pillar", {-1.5f, 1, -1});
    w.get<Transform>(pillar)->scale = {1, 2, 1};
    w.add<MeshRenderer>(pillar).mesh = "cube";
    Entity lamp = make(w, "lamp", {0, 6, 2});
    w.get<Transform>(lamp)->rotation = {-90, 0, 0};
    auto& l = w.add<Light>(lamp);
    l.type = LightType::Spot;
    l.intensity = 3;
    l.range = 14;  // the camera is nearer than the range: the light would ask for 1024 texels
    l.spotAngle = 55;
    l.castShadows = true;
    l.shadowFilter = ShadowFilter::Hard;
    QualityLimits cap;  // only the tile cap: every other limit is the game's own
    cap.shadowTileSize = 512;
    g.renderer.set_quality(QualityLimits{});
    g.draw(w);
    const Image own = g.draw(w);
    g.renderer.set_quality(cap);
    g.draw(w);
    const Image capped = g.draw(w);
    g.renderer.set_quality(QualityLimits{});
    l.shadowResolution = 512;  // the size the cap asks for, written by hand
    g.draw(w);
    const Image by_hand = g.draw(w);
    CHECK(differing(capped, by_hand) == 0);
    CHECK(differing(own, capped) > 0);  // 1024 texels against 512: the edge of the shadow is not the same
}

TEST_CASE("gpu benchmark on a GPU: a game in the Linear colour space keeps its targets and histories") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const GpuInfo info = g.renderer.gpu_info();
    World w;
    Entity cam = make(w, "cam", {0, 3, 9});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    camera_post(w, cam).temporalAAEnabled = true;
    w.settings().colorSpace = ColorSpace::Linear;
    Entity ball = make(w, "ball", {0, 1, 0});
    w.add<MeshRenderer>(ball).mesh = "sphere";
    for (int i = 0; i < 4; ++i) g.draw(w);
    REQUIRE(g.renderer.color_space() == ColorSpace::Linear);
    const int histories = RendererTestAccess::taa_images(g.renderer);
    if (histories == 0) {
        MESSAGE("this backend keeps no temporal history: the test did not run");
        return;
    }
    const GpuBenchmark b = run_gpu_benchmark(g.renderer, info);
    if (!b.ran) {
        MESSAGE("the benchmark did not run: " << b.why);
        return;
    }
    // The benchmark drew in the colour space of the game: its targets were not made again, and the history is still
    // there.
    CHECK(g.renderer.color_space() == ColorSpace::Linear);
    CHECK(RendererTestAccess::taa_images(g.renderer) == histories);
}
