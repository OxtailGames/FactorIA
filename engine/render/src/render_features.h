// What the renderer can do on the backend and GPU it runs on (Renderer::supports, the `render.supports` command): one table of named
// features, each with the backends it can ever run on, what it needs from the GPU, and whether the engine implements it yet. The table
// and the decision are pure (a FeatureEnv in, an answer out) so a test can ask "what would D3D11 say"; only feature_env_from_sokol()
// touches the GPU.
//
// Names: the capabilities of the GPU the M71 pipeline relies on (floatTargets, r11g11b10, sampledDepth, computeShaders), the engine
// features built on them (linearColor, hdrOutput) and one entry per post effect (the names of kPostEffectOrder, fa/scene/postprocess.h).
// An effect or feature the engine does not draw yet answers false with the status "planned (M71)": the table is where each M71 package
// switches its own on (the `planned` field becomes nullptr), so `supports` never claims what the renderer cannot do.
#pragma once

#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/platform/hdr_output.h"

namespace fa::render {

// The rows of the per-backend table. Headless is the backend without a GPU (sokol's dummy backend: nothing is drawn); a headless run
// with Mesa/EGL is a GL or GLES3 backend like any other and answers as one.
enum class FeatureBackend { Gl, Gles3, WebGl2, D3d11, Metal, Headless };
inline constexpr int kFeatureBackendCount = 6;
// "GL", "GLES3", "WebGL2", "D3D11", "Metal", "Headless": the column names of the documentation table.
const char* feature_backend_label(FeatureBackend b);

// What the GPU reported (sg_query_pixelformat / sg_query_features), plus the backend.
struct FeatureEnv {
    FeatureBackend backend = FeatureBackend::Headless;
    bool halfTargets = false;   // RGBA16F renders, blends and filters
    bool r11g11b10 = false;     // RG11B10F renders and filters
    bool sampledDepth = false;  // a depth buffer can be sampled as a texture by a later pass
    bool compute = false;       // storage buffers and compute shaders
    // hdrOutput: whether the window can show HDR now (the display the window is on offers an encoding the renderer writes), and
    // why not. Renderer::supports fills both with set_hdr_env() from the display of the last frame; a FeatureEnv made by hand
    // without them answers "the display has not been asked yet".
    bool hdrOutput = false;
    std::string hdrWhy;
};

// The HDR encodings the present pass writes correctly on `b` (hdr_encoding_bit): EDR on Metal (the picture as for an SDR screen,
// sRGB-encoded in extended sRGB, so it looks the same and stays within white); none on D3D11 until the scRGB / HDR10 encode of
// M71 (an sRGB-encoded picture read as linear scRGB or as PQ would look wrong). Every other backend: none.
unsigned hdr_encodable(FeatureBackend b);
// "planned (M71): ...": why a backend whose displays can show HDR does not use them yet (D3D11).
extern const char* const kHdrPending;
// What the renderer asks app_update_hdr_output() for on backend `b`.
HdrRequest hdr_request(FeatureBackend b, bool want, float paperWhiteNits);
// Fills env.hdrOutput / env.hdrWhy from `display`, the scene's hdrOutput setting aside (supports answers whether the window could
// show HDR, not whether the scene asks for it).
void set_hdr_env(FeatureEnv& env, const HdrDisplay& display);

// The effects of kPostEffectOrder the renderer draws today, as a mask (bit i = PostEffect(i)): what `supports` answers true for (when the GPU
// has what the effect needs) and what the prepass is made for (postprocess.cpp). A stack that switches on an effect outside it draws
// nothing for that effect.
std::uint32_t post_drawn_mask();

enum class FeatureKind { Capability, Engine, Effect };

struct FeatureDef {
    const char* name;
    FeatureKind kind;
    unsigned backends;  // bit (1 << FeatureBackend) of every backend the feature can ever run on
    const char*
        needs;  // "": nothing; "half", "r11g11b10", "depth", "compute", "half+depth": what the GPU must also report
    const char*
        planned;  // nullptr: the engine draws/does it; else the milestone it is planned in ("M71"), and it answers false
    const char* doc;  // one sentence: what it is and what it costs
};

// Every feature, in a fixed order: capabilities, engine features, then the effects in the canonical order of kPostEffectOrder.
const std::vector<FeatureDef>& feature_table();
// The names of feature_table(), in its order.
std::vector<std::string> feature_names();

// Index into feature_table() of `name`, -1 when unknown.
int find_feature(std::string_view name);

// Whether feature `index` of the table works under `env`; when it does not, `why` (when given) says why in one sentence that names the
// backend or the missing GPU capability, or "planned (M71)" for a feature the engine does not draw yet.
bool feature_supported(const FeatureEnv& env, int index, std::string* why = nullptr);

// The environment of the running backend (needs sg_setup done). Reads the GPU's pixel formats and features.
FeatureEnv feature_env_from_sokol();

// The answer of render.supports for every feature under `env`:
// {backend, backendLabel, features: [{name, kind, supported, status, doc, backends: {GL, GLES3, WebGL2, D3D11, Metal, Headless}}]}.
// `status` is "supported", "planned (M71)" or why it is not supported here.
Json feature_report(const FeatureEnv& env, const char* backendName);

}  // namespace fa::render
