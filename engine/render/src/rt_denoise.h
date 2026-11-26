// Private: the renderer's own spatio-temporal denoiser for the ray traced signals (M79-P1n; docs/design/ARCHITECTURE_DENOISE.md).
// Shadows, ambient occlusion, reflections and global illumination come out of the ray passes as a few noisy samples a pixel. This module turns
// one such image into a clean one: a temporal accumulation with reprojection (the history of the frames before, rejected where a surface was
// uncovered or turned), then N variance-guided a-trous wavelet iterations (the family of SVGF and A-SVGF; the code is our own).
//
// A caller declares the passes of one signal in its frame graph with RtDenoiser::add_passes and reads the denoised image the call returns. It
// gives the kind of the signal, the noisy image, the guides of the camera (the prepass, the velocity, a roughness image for a specular signal)
// and the camera's matrices; the module owns the history (per camera and signal), makes it, resets it and frees it.
//
//   guide     once per camera and frame: the prepass -> the guide history (linear depth + WORLD normal), for the next frame's disocclusion test
//   temporal  noisy + guides + history -> the accumulated colour and its variance (transient), the moments (history)
//   atrous    N iterations (steps 1, 2, 4, ...); the first one's result is the history, the last one's is the denoised image
//   debug     (optional) the history length or the variance as a grey picture
//
// What is free when nothing asks: no shader is compiled, no pipeline, image or history exists until a first add_passes with an enabled signal
// (ready()); a signal whose `enabled` is false (a vendor denoiser, DLSS Ray Reconstruction, does its job) declares nothing and frees its
// history at once; a camera that stops asking is swept (sweep()). Everything runs as full-screen fragment passes, on every backend.
#pragma once

#include <cstdint>
#include <map>
#include <memory>
#include <string>
#include <vector>

#include "fa/core/math.h"

#include "frame_graph.h"
#include "render_internal.h"
#include "transient_targets.h"

namespace fa::render {

// What a signal is. The input image of every kind is an RGBA image; the denoiser reads the channels as the kind says.
enum class DenoiseKind : std::uint8_t {
    Visibility,  // a shadow: 0 .. 1 in r (one channel); the result is in r, g and b alike
    Occlusion,   // ambient occlusion: 0 .. 1 in r (one channel); the result is in r, g and b alike
    Diffuse,     // diffuse radiance: rgb, linear; a firefly clamp applies
    Specular,  // specular radiance: rgb + the hit distance in a (world units, negative = the ray missed); the filter follows the lobe
    Coverage   // M79-P3a-2: where the specular signal's rays ended on a surface: one channel, 1 where the alpha of the input is > 0 (a hit distance),
               // else 0. The input is the specular signal's own image; its hit distance steers the reprojection the same way
};
const char* denoise_kind_name(DenoiseKind k);
// 1 for a shadow, an occlusion and a coverage, 3 for the radiance kinds.
int denoise_channels(DenoiseKind k);

// The numbers of one signal. sanitize_denoise_settings clamps them (a number that is not finite takes its default).
struct DenoiseSettings {
    int iterations = 5;  // 2 .. 6 a-trous iterations; the result of the first is the history, so there are at least two
    float maxHistory = 32.0f;  // 1 .. 255 frames the temporal accumulation averages over (then an exponential mean)
    float fireflyClamp =
        8.0f;  // 0 .. 64: a radiance sample brighter than this times its neighbours' mean is brought down to that (0 = off)
    float depthTolerance =
        0.02f;  // 0.001 .. 0.5: the share of a pixel's depth another pixel may be off the plane and still count (both stages)
    float normalPower = 64.0f;  // 1 .. 256: the exponent of the cosine between two normals in the filter's weight
    float lumaSigma =
        4.0f;  // 0.5 .. 16: how many standard deviations of the variance two luminances may differ by (the filter)
    float roughness = 0.5f;  // 0 .. 1: the roughness of a specular pixel when no roughness image is given
};
DenoiseSettings sanitize_denoise_settings(const DenoiseSettings& s);

// What to show instead of the signal (the module's debug views).
enum class DenoiseDebug : std::uint8_t { None, HistoryLength, Variance };

// One signal of one camera. `id` names it in the history (a camera may denoise several: its own number for shadows, AO, ...); `name` is part of
// the pass names (empty: the kind's).
struct DenoiseSignal {
    bool enabled =
        true;  // false: nothing is drawn and the history of this signal is freed now (a vendor denoiser takes the signal)
    DenoiseKind kind = DenoiseKind::Diffuse;
    std::uint32_t id = 0;
    std::string name;
    DenoiseSettings settings;
    DenoiseDebug debug = DenoiseDebug::None;
};

// What the denoiser needs of the camera and the frame (the history is keyed by camKey; the rules of TaaPlan decide when it holds).
struct DenoiseCamera {
    Mat4 view;  // world -> camera view (the unjittered matrix of the frame)
    Mat4
        prevFromView;  // a view-space position of this frame -> the clip position it had on the frame before (unjittered)
    float proj[8]{};  // P00, P11, P02, P12, P03, P13, P32, P33 of the unjittered projection
    float
        halfX = 1.0f,
        halfY =
            1.0f;  // what a unit of normalised device coordinates is in view space at depth 1 (an orthographic camera: at any depth)
    bool ortho = false;
    bool prevValid = false;          // the camera drew the frame before and no cut happened since (PostPlan::prevValid)
    std::uint64_t camKey = 0;        // the camera's entity
    std::uint64_t serial = 0;        // the game frame (Renderer::Impl::postSerial)
    std::uint64_t sceneKey = 0;      // the scene's identity: another one drops the history
    std::uint64_t originShifts = 0;  // the floating-origin rebases so far: another number drops the history
};
DenoiseCamera make_denoise_camera(const CameraInfo& cam, std::uint64_t camKey, std::uint64_t serial,
                                  std::uint64_t sceneKey, std::uint64_t originShifts, const Mat4& prevViewProj,
                                  bool prevValid);

// An image the denoiser reads: a transient of the frame graph (res + targets: its pass declares it in its reads and takes the view when it
// runs) or any texture view the caller keeps (a persistent image: `res` not valid, `targets` null).
struct DenoiseImage {
    ResourceId res;
    const TransientTargets* targets = nullptr;
    gpu::View view{};
    bool valid() const { return targets ? res.valid() : view.id != 0; }
    // The texture view inside a pass that declared `res` in its reads (a transient), else the view given.
    gpu::View get(const PassContext& c) const {
        if (!targets) return view;
        const Target* t = targets->get(c.handle(res));
        return t ? t->texView : gpu::View{};
    }
};

// One call of add_passes. Every image is the size of the camera's rectangle (`width` x `height`, the prepass's size).
struct DenoiseInputs {
    DenoiseImage
        noisy;  // the signal, one sample set per pixel (Rgba16F or Rgba32F; the kind says what its channels are)
    DenoiseImage
        prepass;  // the camera's prepass: r = linear view depth, gb = octahedral view-space normal, a = 1 where a mesh was drawn
    DenoiseImage
        velocity;  // optional: rg = uvPrev - uvCurr of the moved objects (VelocityRef), the sentinel 1024 where none moved
    DenoiseImage roughness;  // optional, specular: r = the roughness of the surface (0 .. 1)
    int width = 0, height = 0;
};

// Why the history of a signal does not hold (the frame starts a new one).
enum class DenoiseReset : std::uint8_t {
    None,      // the history holds
    Fresh,     // there is none yet (a first frame, a signal that was off)
    Resize,    // the images have another size
    Gap,       // the camera or the signal did not run in the frame before
    Scene,     // another scene (a load, a reload)
    Origin,    // a floating-origin shift
    Settings,  // the kind or the settings changed
    Cut        // the camera of the frame before is not the camera of this one (PostPlan::prevValid)
};
const char* denoise_reset_name(DenoiseReset r);

// What a history remembers of the frame it was written in.
struct DenoiseHistoryState {
    bool wrote = false;
    int width = 0, height = 0;
    std::uint64_t serial = 0, sceneKey = 0, originShifts = 0, configKey = 0;
};
// The first rule that breaks the history of `state` for a frame of `cam` at width x height with `configKey` (pure CPU).
DenoiseReset denoise_reset_reason(const DenoiseHistoryState& state, const DenoiseCamera& cam, int width, int height,
                                  std::uint64_t configKey);

// What one signal costs this frame (pure CPU, tested without a GPU). `on` false: nothing is drawn, nothing is allocated.
struct DenoisePlan {
    bool on = false;
    DenoiseKind kind = DenoiseKind::Diffuse;
    int channels = 0;
    DenoiseSettings settings;
    int width = 0, height = 0;
    int signalPasses = 0;  // the signal's own passes: the temporal one, the iterations and the debug view
    int guidePasses =
        0;  // the camera's shared pass (1 when this call is the camera's first this frame and the guide is needed)
    int transients =
        0;  // the frame's images the graph makes (the accumulation, the two a-trous buffers, the debug picture)
    int historyImages = 0;     // the persistent images of the signal (two of the colour, two of the moments)
    bool hitDistance = false;  // the signal carries a hit distance (specular, and the coverage of one)
    std::uint64_t configKey = 0;
    std::uint64_t historyBytes = 0;  // of the signal's history images (saturated)
    std::uint64_t guideBytes = 0;    // of the camera's guide history (saturated)
};
// `momentsF32`: the moments are 32-bit floats (else 16-bit: a GPU that cannot render to RGBA32F).
DenoisePlan make_denoise_plan(const DenoiseSignal& signal, int width, int height, bool momentsF32);

// What add_passes returns.
struct DenoiseOutput {
    bool valid = false;  // the passes were declared; `res` is the denoised image
    ResourceId
        res;  // transient: r, g, b = the signal (a one-channel signal in all three), a = the variance of the estimate
    ResourceId debug;  // transient, valid when DenoiseSignal::debug asked for a view: a grey picture
    int width = 0, height = 0;
    int passes = 0;  // passes declared by this call (the guide pass included when this call made it)
    DenoiseReset reset =
        DenoiseReset::Fresh;  // why the frame started a new history (None: it blends with the one of the frame before)
    std::string why;          // when !valid: what stopped it
    // The image inside a pass that declared `res` (or `debug`) in its reads; null when it is gone.
    const Target* target(const PassContext& c, const TransientTargets& t) const { return t.get(c.handle(res)); }
    const Target* debug_target(const PassContext& c, const TransientTargets& t) const { return t.get(c.handle(debug)); }
};

class RtDenoiser {
public:
    RtDenoiser() = default;
    RtDenoiser(const RtDenoiser&) = delete;
    RtDenoiser& operator=(const RtDenoiser&) = delete;

    // Declares the passes of `signal` for the camera `cam` in `graph` (after the passes that write the inputs' resources; the denoised image
    // is a transient that the caller's later passes list in their reads). Each pass adds one to *drawCalls when it runs (may be null).
    // `job` prefixes the pass names. Not valid (nothing declared; `why` says): the signal is disabled, an input is missing, the shaders did not
    // compile, the history is over the budget, or the signal was already declared for this camera in this graph.
    DenoiseOutput add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, const DenoiseCamera& cam,
                             const DenoiseSignal& signal, const DenoiseInputs& in, int* drawCalls,
                             const std::string& job);

    // Compiles the shaders on the first call; false (and unavailable()) when they did not compile. add_passes calls it.
    bool ready(gpu::Device& device);
    // True once the shaders failed (the signals are then not denoised); refused() once a history was refused (budget or GPU) since forget_targets().
    bool unavailable() const { return state_ < 0; }
    bool refused() const { return refused_; }
    // Tests: the bytes of all the histories together (0: the default, 1 GB; 256 MB on wasm32).
    void set_budget(std::uint64_t bytes) { budgetOverride_ = bytes; }
    // Tests: 16-bit moments, as a GPU that cannot render to RGBA32F has.
    void force_moments_f16(bool force);

    // Frees what a camera or a signal did not use in the frame before `serial`.
    void sweep(std::uint64_t serial);
    // Drops what a camera accumulated (camKey 0: every camera): the next frame of each signal starts a new history.
    void reset(std::uint64_t camKey = 0);
    // Frees the history of one signal now.
    void drop_signal(std::uint64_t camKey, std::uint32_t signalId);

    // Tests and the debug output: the history images alive (guides and signals), the histories started, the reason the last frame of a signal
    // started a new one, whether it blended, and the programs made.
    int history_image_count() const;
    int resets() const { return resets_; }
    DenoiseReset last_reset(std::uint64_t camKey, std::uint32_t signalId) const;
    bool last_used_history(std::uint64_t camKey, std::uint32_t signalId) const;
    bool shaders_made() const { return state_ != 0; }
    int pipeline_count() const { return int(pipelines_.size()); }

    // Destroys the shaders, the pipelines and the histories; call while the graphics context is open.
    void release();
    // The GPU lost its targets or the window was resized: the histories go (they are made again for the new size).
    void forget_targets();

    enum class Prog { Guide, Temporal, Atrous, Debug, Count };
    gpu::Pipeline pipeline(Prog prog, const TargetFormat& format);

private:
    struct PipelineEntry {
        Prog prog;
        TargetFormat format;
        gpu::Pipeline pipeline;
    };
    struct GuideSlot {
        Target img[2];  // Rgba16F: r = linear depth (0 = nothing drawn), gba = world normal
        int w = 0, h = 0;
        int last = -1;
        bool wrote = false;
        std::uint64_t serial = 0, sceneKey = 0, originShifts = 0, planned = 0;
        // The decision of the frame being declared (the first signal of the camera makes it).
        std::uint64_t frameSerial = 0;
        const FrameGraph* frameGraph = nullptr;
        bool frameValid = false;
        DenoiseReset frameReason = DenoiseReset::Fresh;
        int frameRead = -1, frameWrite = 0;
    };
    struct SignalSlot {
        Target col[2];  // Rgba16F: the history colour (the first a-trous iteration's result) and its variance
        Target mom[2];  // RGBA32F (RGBA16F): moments of the luminance, the history length, the accumulated hit distance
        gpu::PixelFormat momFormat = gpu::PixelFormat::None;
        int w = 0, h = 0;
        int last = -1;
        bool wrote = false;
        std::uint64_t serial = 0, sceneKey = 0, originShifts = 0, configKey = 0, planned = 0;
        std::uint64_t frameSerial = 0;
        const FrameGraph* frameGraph = nullptr;
        std::uint64_t temporalSerial = 0;  // the frame whose temporal pass ran (the moments are written)
        DenoiseReset lastReset = DenoiseReset::Fresh;
        bool usedHistory = false;
    };
    struct CamSlot {
        GuideSlot guide;
        std::map<std::uint32_t, std::shared_ptr<SignalSlot>> signals;
    };
    struct DrawArgs {
        gpu::View views[8]{};
        const void* params = nullptr;
        std::size_t paramBytes = 0;
        int paramSlot = 1;
    };

    gpu::Device* device_ = nullptr;  // the device of the first ready(): everything is made and destroyed on it
    gpu::Shader shaders_[int(Prog::Count)]{};
    std::vector<PipelineEntry> pipelines_;
    int state_ = 0;  // 0 = shaders not made yet, 1 = ready, -1 = failed (logged)
    bool refused_ = false;
    bool forceF16_ = false;
    std::uint64_t budgetOverride_ = 0;
    int resets_ = 0;
    std::map<std::uint64_t, std::shared_ptr<CamSlot>> cams_;

    std::uint64_t used_bytes(const GuideSlot* exceptGuide, const SignalSlot* exceptSignal) const;
    static std::uint64_t guide_bytes_of(const GuideSlot& g);
    static std::uint64_t signal_bytes_of(const SignalSlot& s);
    void destroy(GuideSlot& g);
    void destroy(SignalSlot& s);
    bool draw(gpu::CommandList& list, Gpu& gpu, Prog prog, const PassDesc& pd, const DrawArgs& args);
};

}  // namespace fa::render
