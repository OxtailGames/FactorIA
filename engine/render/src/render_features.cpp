#include "render_features.h"

#include <cstring>

#include "fa/core/log.h"
#include "fa/scene/postprocess.h"
#include "sokol_gfx.h"

namespace fa::render {

namespace {

constexpr unsigned bit(FeatureBackend b) { return 1u << unsigned(b); }
constexpr unsigned kEveryGpu = bit(FeatureBackend::Gl) | bit(FeatureBackend::Gles3) | bit(FeatureBackend::WebGl2) |
                               bit(FeatureBackend::D3d11) | bit(FeatureBackend::Metal);

struct EffectRow {
    const char* needs;
    const char* doc;
};

// One row per effect, in the order of kPostEffectOrder (checked below).
constexpr EffectRow kEffectRows[kPostEffectCount] = {
    {"depth", "Screen-space ambient occlusion (GTAO) from the depth buffer: creases and contacts of 3D models darken."},
    {"half+depth", "Screen-space reflections: shiny surfaces reflect what is on the screen."},
    {"depth", "Distance and height fog drawn from the depth buffer."},
    {"depth", "Light shafts spreading from the sun through the scene."},
    {"", "Exposure, manual or automatic with an adaptation speed."},
    {"depth", "Depth of field with near and far blur, bokeh and autofocus."},
    {"depth", "Camera motion blur, from the depth buffer."},
    {"", "Radial blur from a point of the picture."},
    {"", "Barrel and pincushion lens distortion."},
    {"", "Chromatic aberration: colour fringes toward the edges."},
    {"", "Bloom with a soft knee and a lens dirt texture."},
    {"", "Tonemap: none, neutral, ACES, AgX or Reinhard."},
    {"", "Colour grading: lift/gamma/gain, white balance, curves and .cube LUTs."},
    {"", "Vignette: the edges of the picture darken toward a colour."},
    {"", "Sharpening: a light unsharp mask for crisper detail."},
    {"depth", "Outline: depth and normal edges (3D) or the border of 2D sprites."},
    {"", "Pixelation: the picture drawn in big square pixels."},
    {"", "Posterization: colours reduced to a few levels per channel."},
    {"", "Film grain: animated noise over the picture."},
    {"", "The accessibility colour filter, the last pass of the frame."},
};
static_assert(sizeof(kEffectRows) / sizeof(kEffectRows[0]) == std::size_t(kPostEffectCount),
              "one row of kEffectRows per effect of kPostEffectOrder");

// The effects the renderer draws today (postprocess.cpp, bloom.cpp, post.glsl); each M71 package adds its own here.
constexpr bool effect_drawn(PostEffect e) {
    return e == PostEffect::Exposure || e == PostEffect::Bloom || e == PostEffect::Tonemap ||
           e == PostEffect::ColorFilter;
}

}  // namespace

std::uint32_t post_drawn_mask() {
    std::uint32_t m = 0;
    for (int i = 0; i < kPostEffectCount; ++i)
        if (effect_drawn(PostEffect(i))) m |= 1u << i;
    return m;
}

namespace {

std::vector<FeatureDef> build_table() {
    std::vector<FeatureDef> t;
    // The capabilities: facts about the GPU, answered from what it reports.
    t.push_back(
        {"floatTargets", FeatureKind::Capability, kEveryGpu, "half", nullptr,
         "Render targets of 16-bit float colour (RGBA16F) that blend and filter: the frame keeps colours above white. "
         "Without them the frame is RGBA8 and clips at white."});
    t.push_back(
        {"r11g11b10", FeatureKind::Capability, kEveryGpu, "r11g11b10", nullptr,
         "The packed float render target R11G11B10 (half the memory of RGBA16F, no alpha), for HDR frames on phones."});
    t.push_back(
        {"sampledDepth", FeatureKind::Capability, kEveryGpu, "depth", nullptr,
         "The scene's depth and normals as images that a later pass can sample (the depth and normal prepass, drawn "
         "only "
         "for a frame with an effect that reads them): what ambient occlusion, depth of field, fog, reflections and "
         "motion blur read."});
    t.push_back({"computeShaders", FeatureKind::Capability,
                 bit(FeatureBackend::Gl) | bit(FeatureBackend::D3d11) | bit(FeatureBackend::Metal), "compute", nullptr,
                 "Compute shaders and storage buffers (D3D11, Metal, OpenGL 4.3; never GLES3 or WebGL2)."});
    // The engine features built on them.
    t.push_back(
        {"linearColor", FeatureKind::Engine, kEveryGpu, "", nullptr,
         "Lighting and blending in linear light (SceneSettings.colorSpace linear). The frame is RGBA16F where the GPU "
         "has it, else R11G11B10 (no alpha), else 8 bits that hold linear light (SRGB8A8), else plain RGBA8 with "
         "banding in the darks, so every GPU can."});
    t.push_back(
        {"hdrOutput", FeatureKind::Engine, bit(FeatureBackend::D3d11) | bit(FeatureBackend::Metal), "", nullptr,
         "Showing the picture on a high dynamic range display (SceneSettings.hdrOutput auto): EDR on macOS and iOS, "
         "scRGB or HDR10 on Windows once the HDR encode of M71 lands; the display and the OS must allow it. "
         "render.output says what the window shows."});
    for (int i = 0; i < kPostEffectCount; ++i)
        t.push_back({kPostEffectOrder[std::size_t(i)].data(), FeatureKind::Effect, kEveryGpu, kEffectRows[i].needs,
                     effect_drawn(PostEffect(i)) ? nullptr : "M71", kEffectRows[i].doc});
    return t;
}

bool needs_met(const FeatureEnv& env, const char* needs, std::string* missing) {
    auto need = [&](const char* word, bool have, const char* what) {
        if (std::strstr(needs, word) && !have) {
            if (missing && missing->empty()) *missing = what;
            return false;
        }
        return true;
    };
    bool ok = true;
    ok &= need("half", env.halfTargets, "RGBA16F render targets that blend and filter");
    ok &= need("r11g11b10", env.r11g11b10, "the R11G11B10 float render target");
    ok &= need("depth", env.sampledDepth,
               "sampling the depth of the scene in a shader (a float render target for the depth prepass)");
    ok &= need("compute", env.compute, "compute shaders");
    return ok;
}

}  // namespace

const char* feature_backend_label(FeatureBackend b) {
    switch (b) {
        case FeatureBackend::Gl: return "GL";
        case FeatureBackend::Gles3: return "GLES3";
        case FeatureBackend::WebGl2: return "WebGL2";
        case FeatureBackend::D3d11: return "D3D11";
        case FeatureBackend::Metal: return "Metal";
        case FeatureBackend::Headless: return "Headless";
    }
    return "?";
}

const std::vector<FeatureDef>& feature_table() {
    static const std::vector<FeatureDef> table = build_table();
    return table;
}

std::vector<std::string> feature_names() {
    std::vector<std::string> out;
    for (const FeatureDef& f : feature_table()) out.push_back(f.name);
    return out;
}

int find_feature(std::string_view name) {
    const std::vector<FeatureDef>& t = feature_table();
    for (std::size_t i = 0; i < t.size(); ++i)
        if (name == t[i].name) return int(i);
    return -1;
}

bool feature_supported(const FeatureEnv& env, int index, std::string* why) {
    const std::vector<FeatureDef>& t = feature_table();
    if (index < 0 || std::size_t(index) >= t.size()) {
        if (why) *why = "unknown feature";
        return false;
    }
    const FeatureDef& f = t[std::size_t(index)];
    if (env.backend == FeatureBackend::Headless) {
        if (why) *why = "there is no GPU (the headless backend draws nothing)";
        return false;
    }
    if (!(f.backends & bit(env.backend))) {
        if (why)
            *why = std::string("the ") + feature_backend_label(env.backend) + " backend cannot do this (" +
                   (std::strcmp(f.name, "hdrOutput") == 0        ? "it has no HDR output here"
                    : std::strcmp(f.name, "computeShaders") == 0 ? "it has no compute shaders"
                                                                 : "it is not available there") +
                   ")";
        return false;
    }
    std::string missing;
    if (!needs_met(env, f.needs, &missing)) {
        if (why) *why = std::string("this GPU lacks ") + missing;
        return false;
    }
    if (f.planned) {
        if (why) *why = std::string("planned (") + f.planned + ")";
        return false;
    }
    if (std::strcmp(f.name, "hdrOutput") == 0 && !env.hdrOutput) {
        if (why)
            *why = env.hdrWhy.empty() ? "the display has not been asked yet (no frame shown in a window)" : env.hdrWhy;
        return false;
    }
    return true;
}

const char* const kHdrPending = "planned (M71): the renderer does not write scRGB or HDR10 yet";

unsigned hdr_encodable(FeatureBackend b) {
    return b == FeatureBackend::Metal ? hdr_encoding_bit(HdrEncoding::Edr) : 0u;
}

HdrRequest hdr_request(FeatureBackend b, bool want, float paperWhiteNits) {
    HdrRequest r;
    r.want = want;
    r.paperWhiteNits = paperWhiteNits;
    r.encodable = hdr_encodable(b);
    r.edrLinear = false;  // the present pass writes sRGB-encoded values: extended sRGB, not extended linear sRGB
    if (b == FeatureBackend::D3d11) r.pending = kHdrPending;
    if (b == FeatureBackend::Metal)
        r.activeNote = "the picture stays within white until the HDR encode of M71 sends brighter values";
    return r;
}

void set_hdr_env(FeatureEnv& env, const HdrDisplay& display) {
    const HdrRequest request = hdr_request(env.backend, true, 200.0f);
    if (request.encodable == 0 && !request.pending.empty()) {  // whatever the display says: the renderer is not ready
        env.hdrOutput = false;
        env.hdrWhy = request.pending;
        return;
    }
    const HdrDecision d = decide_hdr_output(request, display);
    env.hdrOutput = d.encoding != HdrEncoding::Sdr;
    env.hdrWhy = d.why;
}

FeatureEnv feature_env_from_sokol() {
    FeatureEnv env;
    switch (sg_query_backend()) {
        case SG_BACKEND_GLCORE: env.backend = FeatureBackend::Gl; break;
        case SG_BACKEND_GLES3:
#if defined(__EMSCRIPTEN__)
            env.backend = FeatureBackend::WebGl2;
#else
            env.backend = FeatureBackend::Gles3;
#endif
            break;
        case SG_BACKEND_D3D11: env.backend = FeatureBackend::D3d11; break;
        case SG_BACKEND_METAL_IOS:
        case SG_BACKEND_METAL_MACOS:
        case SG_BACKEND_METAL_SIMULATOR: env.backend = FeatureBackend::Metal; break;
        default:
            env.backend = FeatureBackend::Headless;
            break;  // the dummy backend (and any sokol backend the engine never builds)
    }
    const sg_pixelformat_info half = sg_query_pixelformat(SG_PIXELFORMAT_RGBA16F);
    env.halfTargets = half.render && half.blend && half.filter;
    const sg_pixelformat_info packed = sg_query_pixelformat(SG_PIXELFORMAT_RG11B10F);
    // The rule of Gpu::init: sokol-gfx reports no blend flag for RG11B10F on GL, where the format blends when it renders at all.
    env.r11g11b10 = packed.render && packed.filter && (packed.blend || env.backend == FeatureBackend::Gl);
    // sampledDepth: the renderer's prepass (Gpu::prepass_color_format) writes the depth into a float colour image, because a depth buffer
    // cannot be sampled when it is multisampled and its range differs per backend; so the answer follows that image's format.
    const sg_pixelformat_info depth = sg_query_pixelformat(SG_PIXELFORMAT_DEPTH);
    const sg_pixelformat_info f32 = sg_query_pixelformat(SG_PIXELFORMAT_RGBA32F);
    const sg_pixelformat_info f16 = sg_query_pixelformat(SG_PIXELFORMAT_RGBA16F);
    env.sampledDepth = depth.render && ((f32.render && f32.sample) || (f16.render && f16.sample));
    env.compute = sg_query_features().compute;
    return env;
}

Json feature_report(const FeatureEnv& env, const char* backendName) {
    Json out = Json::object();
    out["backend"] = backendName;
    out["backendLabel"] = feature_backend_label(env.backend);
    Json list = Json::array();
    const std::vector<FeatureDef>& t = feature_table();
    for (std::size_t i = 0; i < t.size(); ++i) {
        const FeatureDef& f = t[i];
        std::string why;
        const bool ok = feature_supported(env, int(i), &why);
        Json row = Json::object();
        row["name"] = f.name;
        row["kind"] = f.kind == FeatureKind::Capability ? "capability"
                      : f.kind == FeatureKind::Engine   ? "engine"
                                                        : "effect";
        row["supported"] = ok;
        row["status"] = ok ? std::string("supported") : why;
        row["doc"] = f.doc;
        Json backends = Json::object();
        for (int b = 0; b < kFeatureBackendCount; ++b)
            backends[feature_backend_label(FeatureBackend(b))] = (f.backends & bit(FeatureBackend(b))) != 0;
        row["backends"] = backends;
        list.push_back(row);
    }
    out["features"] = list;
    return out;
}

}  // namespace fa::render
