#include "render_upscale_dlss.h"

#include <algorithm>
#include <cfloat>
#include <cmath>
#include <cstring>
#include <mutex>
#include <span>
#include <utility>

#include "fa/core/log.h"
#include "fa/core/math.h"

#include "streamline_runtime.h"

namespace fa::render {

namespace {

using namespace sl_abi;
using SlResult = sl_abi::Result;

constexpr float kModeBand =
    0.13f;  // the closest two modes are 0.2 apart: a band of 0.13 keeps a wobbling ratio on one mode near a boundary
constexpr std::uint32_t kRenderSizeSlack = 2;  // pixels of difference to DLSS's own render size the frame may have

struct ModeRow {
    std::uint32_t mode;
    float ratio;
    const char* name;
};
constexpr ModeRow kModes[] = {
    {kDlssDlaa, 1.0f, "DLAA"},
    {kDlssUltraQuality, 1.3f, "Ultra Quality"},
    {kDlssMaxQuality, 1.5f, "Quality"},
    {kDlssBalanced, 1.72f, "Balanced"},
    {kDlssMaxPerformance, 2.0f, "Performance"},
    {kDlssUltraPerformance, 3.0f, "Ultra Performance"},
};

constexpr unsigned bit(gpu::Backend b) { return 1u << unsigned(b); }

// The Direct3D 12 and Vulkan states the images are in inside the native section (CommandList::begin_native declares them: a shader reads
// color, depth and velocity; DLSS writes the output).
constexpr std::uint32_t kD3d12ShaderReadGraphics = 0xC0;  // PIXEL_SHADER_RESOURCE | NON_PIXEL_SHADER_RESOURCE
constexpr std::uint32_t kD3d12ShaderReadCompute = 0x40;   // NON_PIXEL_SHADER_RESOURCE
constexpr std::uint32_t kD3d12UnorderedAccess = 0x8;
constexpr std::uint32_t kVkLayoutGeneral = 1, kVkLayoutShaderRead = 5;

void* handle_of(std::uint64_t v) {
    return reinterpret_cast<void*>(static_cast<std::uintptr_t>(v));  // NOLINT: a Vulkan handle
}

// A 16-float matrix in the order of fa::Mat4 (column-major, a column vector on the right) as the Float4x4 Streamline reads: the same memory is
// a row-major matrix with a row vector on its left (the transpose), which multiplies the same way.
Float4x4 to_float4x4(const Mat4& m) {
    static_assert(sizeof(Float4x4) == sizeof(m.m), "a Float4x4 is 16 floats");
    Float4x4 r;
    std::memcpy(&r, m.m, sizeof(r));
    return r;
}

Mat4 to_mat4(const float (&a)[16]) {
    Mat4 m;
    std::memcpy(m.m, a, sizeof(m.m));
    return m;
}

// Whether the frame's render size is inside the range DLSS (`product`) gives for the mode at this output; "" or the sentence.
template <class Settings>
std::string check_render_size(const Settings& settings, const char* product, std::uint32_t dlssMode,
                              const UpscaleInput& in) {
    if (settings.optimalRenderWidth == 0 || settings.optimalRenderHeight == 0)
        return std::string(product) + " does not support its " + dlss_mode_name(dlssMode) + " mode for an output of " +
               std::to_string(in.outW) + "x" + std::to_string(in.outH) +
               ". Choose another quality (render.upscaler.quality) or a larger window.";
    const auto low_of = [](std::uint32_t lo, std::uint32_t optimal) {
        return std::min(lo == 0 ? optimal : lo, optimal);
    };
    const auto high_of = [](std::uint32_t hi, std::uint32_t optimal) {
        return std::max(hi == 0 ? optimal : hi, optimal);
    };
    const auto within = [&](int value, std::uint32_t lo, std::uint32_t hi, std::uint32_t optimal) {
        return std::uint32_t(value) + kRenderSizeSlack >= low_of(lo, optimal) &&
               std::uint32_t(value) <= high_of(hi, optimal) + kRenderSizeSlack;
    };
    if (!within(in.renderW, settings.renderWidthMin, settings.renderWidthMax, settings.optimalRenderWidth) ||
        !within(in.renderH, settings.renderHeightMin, settings.renderHeightMax, settings.optimalRenderHeight)) {
        const std::uint32_t optW = settings.optimalRenderWidth, optH = settings.optimalRenderHeight;
        return std::string(product) + "'s " + dlss_mode_name(dlssMode) + " mode draws at " + std::to_string(optW) +
               "x" + std::to_string(optH) + " for an output of " + std::to_string(in.outW) + "x" +
               std::to_string(in.outH) + " and takes render sizes from " +
               std::to_string(low_of(settings.renderWidthMin, optW)) + "x" +
               std::to_string(low_of(settings.renderHeightMin, optH)) + " to " +
               std::to_string(high_of(settings.renderWidthMax, optW)) + "x" +
               std::to_string(high_of(settings.renderHeightMax, optH)) + ", and the frame was drawn at " +
               std::to_string(in.renderW) + "x" + std::to_string(in.renderH) +
               ". Choose another render.upscaler.quality (or window.renderScale).";
    }
    return {};
}

class DlssProvider final : public VendorUpscaler {
public:
    std::string_view name() const override { return "DLSS"; }
    std::string_view mode() const override { return "dlss"; }
    std::string_view setup_id() const override { return "streamline"; }
    // The Streamline runtime hooks the D3D12 and Vulkan devices only: a Direct3D 11 device is made without it.
    unsigned backends() const override { return bit(gpu::Backend::D3d12) | bit(gpu::Backend::Vulkan); }
    // DLSS writes the output image from a compute shader.
    bool needs_output_storage() const override { return true; }

    VendorProbe probe(const VendorEnv& env) override;
    VendorProbe probe_ray_reconstruction(const VendorEnv& env) override;
    bool upscale(const UpscaleInput& in, VendorFrame& frame) override;
    void release(gpu::Device& device) override;

private:
    // What DLSS was last told, and the functions of this set-up of Streamline.
    struct State {
        const gpu::Device* device = nullptr;
        std::uint64_t generation = 0;  // StreamlineStatus::generation the functions and options are for
        DlssSetOptionsFn setOptions = nullptr;
        DlssGetOptimalSettingsFn getOptimal = nullptr;
        bool optionsSet = false;
        std::uint32_t mode = 0;
        int outW = 0, outH = 0;
        float preExposure = 1.0f;
        bool hdr = false;
        bool needReset = true;  // the next frame starts the history again (new options, or an evaluate that failed)
        bool sizeChecked = false;
        int renderW = 0, renderH = 0;
        // Ray Reconstruction (M78-P4c) is a feature of its own in Streamline: its functions, and what it was last told. Its options carry the
        // camera's matrices, so they are set every frame; the rest of them (mode, sizes) is remembered to know when the history starts again.
        DlssdSetOptionsFn rrSetOptions = nullptr;
        DlssdGetOptimalSettingsFn rrGetOptimal = nullptr;
        bool rrOptionsSet = false;
        std::uint32_t rrMode = 0;
        int rrOutW = 0, rrOutH = 0, rrRenderW = 0, rrRenderH = 0;
        bool rrSizeChecked = false;
        bool lastRr =
            false;  // the last frame was drawn with Ray Reconstruction (a switch to the other feature starts the history again)
        // Vulkan: the storage view of the output image DLSS writes (made when the image changes).
        gpu::Image outputImage{};
        gpu::View outputView{};
    };

    void bind_state(gpu::Device& device, std::uint64_t generation);
    std::string ensure_options(const StreamlineApi& api, const UpscaleInput& in);
    std::string ensure_rr_options(const StreamlineApi& api, const UpscaleInput& in);
    std::string ensure_output_view(gpu::Device& device, gpu::Image output);
    // The frame's constants, tags and evaluate with Super Resolution (`rr` false) or Ray Reconstruction; "" when drawn, else what failed.
    std::string draw(const UpscaleInput& in, VendorFrame& frame, const StreamlineApi& api, StreamlineRuntime& runtime,
                     bool rr);
    void drop_output_view(gpu::Device& device) {
        if (state_.outputView.valid()) device.destroy_view(state_.outputView);
        state_.outputView = {};
        state_.outputImage = {};
    }
    bool fail(VendorFrame& frame, std::string why) {
        state_.needReset = true;
        frame.error = std::move(why);
        return false;
    }

    std::mutex mutex_;
    State state_{};
};

VendorProbe DlssProvider::probe(const VendorEnv& env) {
    VendorProbe p;
    // What the machine decides first: the GPU's maker, the backend and the system. A library that is missing is last: installing it is of no
    // use where the GPU or the backend cannot run DLSS.
    if (env.vendor != GpuVendor::Nvidia) {
        p.reason = "DLSS needs an NVIDIA RTX GPU; this GPU is " + vendor_describe_gpu(env.vendor) + ".";
        return p;
    }
    p.reason = vendor_environment_problem(*this, env);
    if (!p.reason.empty()) return p;
    StreamlineRuntime& runtime = streamline_runtime();
    const StreamlineStatus status = runtime.status();
    if (status.ready) {
        if (status.backend != env.backend) {
            p.reason = std::string("NVIDIA Streamline was started for ") + vendor_backend_label(status.backend) +
                       " and this device is " + vendor_backend_label(env.backend) + ".";
            return p;
        }
        if (const std::string why = runtime.feature_reason(kFeatureDlss); !why.empty()) {
            p.reason = "DLSS is not available on this machine: " + why;
            return p;
        }
        p.available = true;
        return p;
    }
    if (status.tried) {
        p.reason = status.reason.empty() ? "NVIDIA Streamline did not start with the graphics device." : status.reason;
        return p;
    }
    // Streamline never saw this device: say whether the library is there, which is what the user can do something about.
    std::string why;
    const VendorLibrarySpec spec{"streamline", "FA_STREAMLINE_DIR", "sl.interposer.dll"};
    if (vendor_loader().find(spec, &why).empty()) {
        p.reason = "DLSS is not installed: run `factoria setup streamline` (" + why + ").";
        return p;
    }
    p.reason = "NVIDIA Streamline is installed, but it was not started when the graphics device was made (the renderer "
               "starts it before "
               "it makes a Direct3D 12 or Vulkan device): restart the game.";
    return p;
}

// Ray Reconstruction runs where Super Resolution runs (an RTX GPU on D3D12 or Vulkan with Streamline started) and needs its own plugin
// (sl.dlss_d.dll and nvngx_dlssd.dll) to have loaded: Streamline says why not in feature_reason.
VendorProbe DlssProvider::probe_ray_reconstruction(const VendorEnv& env) {
    VendorProbe p = probe(env);
    if (!p.available) {
        p.reason = "DLSS Ray Reconstruction is not available: " + p.reason;
        return p;
    }
    StreamlineRuntime& runtime = streamline_runtime();
    if (runtime.status().ready && !runtime.feature_asked(kFeatureDlssRr)) {
        // The plugin is loaded with Streamline, before the device: only a project that asks for it at start gets it.
        p.available = false;
        p.reason = "DLSS Ray Reconstruction is not available in this run: its plugin is loaded when the game starts, "
                   "and the project did "
                   "not ask for it. Set render.upscaler.rayReconstruction to true in factoria.json and restart.";
    } else if (const std::string why = runtime.feature_reason(kFeatureDlssRr); !why.empty()) {
        p.available = false;
        p.reason = "DLSS Ray Reconstruction is not available on this machine: " + why;
    }
    return p;
}

// Another device or another set-up of Streamline: nothing of the earlier one is valid (the view of the same device is destroyed).
void DlssProvider::bind_state(gpu::Device& device, std::uint64_t generation) {
    if (state_.device == &device && state_.generation == generation) return;
    if (state_.device == &device) drop_output_view(device);
    state_ = State{};
    state_.device = &device;
    state_.generation = generation;
}

// Sets DLSS's options when the mode, the output size, the exposure or the colour space changed. "" or the sentence of what failed.
std::string DlssProvider::ensure_options(const StreamlineApi& api, const UpscaleInput& in) {
    if (!state_.setOptions || !state_.getOptimal) {
        void* setOptions = nullptr;
        void* getOptimal = nullptr;
        if (const SlResult r = api.getFeatureFunction(kFeatureDlss, "slDLSSSetOptions", &setOptions);
            r != kOk || !setOptions)
            return streamline_refusal("slGetFeatureFunction(slDLSSSetOptions)", r == kOk ? kErrorFeatureMissing : r);
        if (const SlResult r = api.getFeatureFunction(kFeatureDlss, "slDLSSGetOptimalSettings", &getOptimal);
            r != kOk || !getOptimal)
            return streamline_refusal("slGetFeatureFunction(slDLSSGetOptimalSettings)",
                                      r == kOk ? kErrorFeatureMissing : r);
        state_.setOptions = reinterpret_cast<DlssSetOptionsFn>(setOptions);          // NOLINT: the function's address
        state_.getOptimal = reinterpret_cast<DlssGetOptimalSettingsFn>(getOptimal);  // NOLINT
    }
    const float ratio = std::max(float(in.outW) / float(in.renderW), float(in.outH) / float(in.renderH));
    const std::uint32_t dlssMode = dlss_mode_for_ratio(ratio, state_.optionsSet ? state_.mode : 0);
    const float preExposure = in.exposure > 0.0f && std::isfinite(in.exposure) ? in.exposure : 1.0f;
    const bool hdr = in.linear;
    const bool sameSizes = state_.sizeChecked && state_.mode == dlssMode && state_.outW == in.outW &&
                           state_.outH == in.outH && state_.renderW == in.renderW && state_.renderH == in.renderH;
    DlssOptions options;
    init_dlss_options(options);
    options.mode = dlssMode;
    options.outputWidth = std::uint32_t(in.outW);
    options.outputHeight = std::uint32_t(in.outH);
    options.sharpness = 0.0f;  // the engine sharpens in its own pass
    options.preExposure = preExposure;
    options.exposureScale = 1.0f;
    options.colorBuffersHdr = hdr ? kTrue : kFalse;
    options.indicatorInvertAxisX = options.indicatorInvertAxisY = kFalse;
    options.useAutoExposure = kTrue;  // the frame's colour is exposed already: DLSS finds its own scene exposure
    options.alphaUpscalingEnabled = kFalse;
    if (!sameSizes) {
        // DLSS says what render size the mode asks for at this output: the frame must be drawn within its range.
        DlssOptimalSettings settings;
        init_dlss_optimal_settings(settings);
        if (const SlResult r = state_.getOptimal(&options, &settings); r != kOk)
            return streamline_refusal("slDLSSGetOptimalSettings", r);
        if (std::string e = check_render_size(settings, "DLSS", dlssMode, in); !e.empty()) return e;
    }
    const bool changed = !state_.optionsSet || state_.mode != dlssMode || state_.outW != in.outW ||
                         state_.outH != in.outH || state_.preExposure != preExposure || state_.hdr != hdr;
    if (changed) {
        ViewportHandle viewport;
        init_viewport(viewport, 0);
        state_.optionsSet = false;
        if (const SlResult r = state_.setOptions(&viewport, &options); r != kOk)
            return streamline_refusal("slDLSSSetOptions", r);
        state_.optionsSet = true;
        state_.needReset = true;  // the history of the old mode means nothing to the new one
    }
    state_.mode = dlssMode;
    state_.outW = in.outW;
    state_.outH = in.outH;
    state_.renderW = in.renderW;
    state_.renderH = in.renderH;
    state_.preExposure = preExposure;
    state_.hdr = hdr;
    state_.sizeChecked = true;
    return {};
}

// The options of Ray Reconstruction (sl_dlss_d.h). The mode follows the quality like Super Resolution's; the colour is HDR (Ray
// Reconstruction only takes HDR); the normals and the roughness come packed in one image (roughness in w) and in world space, so DLSS is
// told the camera's world-to-view matrix and its inverse; sharpness and auto exposure do not exist in it. Set every frame: the matrices move
// with the camera. "" or the sentence of what failed (state_ is for this device: ensure_options ran first).
std::string DlssProvider::ensure_rr_options(const StreamlineApi& api, const UpscaleInput& in) {
    if (!state_.rrSetOptions || !state_.rrGetOptimal) {
        void* setOptions = nullptr;
        void* getOptimal = nullptr;
        if (const SlResult r = api.getFeatureFunction(kFeatureDlssRr, "slDLSSDSetOptions", &setOptions);
            r != kOk || !setOptions)
            return streamline_refusal("slGetFeatureFunction(slDLSSDSetOptions)", r == kOk ? kErrorFeatureMissing : r);
        if (const SlResult r = api.getFeatureFunction(kFeatureDlssRr, "slDLSSDGetOptimalSettings", &getOptimal);
            r != kOk || !getOptimal)
            return streamline_refusal("slGetFeatureFunction(slDLSSDGetOptimalSettings)",
                                      r == kOk ? kErrorFeatureMissing : r);
        state_.rrSetOptions = reinterpret_cast<DlssdSetOptionsFn>(setOptions);  // NOLINT: the function's address
        state_.rrGetOptimal = reinterpret_cast<DlssdGetOptimalSettingsFn>(getOptimal);  // NOLINT
    }
    const float ratio = std::max(float(in.outW) / float(in.renderW), float(in.outH) / float(in.renderH));
    const std::uint32_t dlssMode = dlss_mode_for_ratio(ratio, state_.rrOptionsSet ? state_.rrMode : 0);
    const bool sameSizes = state_.rrSizeChecked && state_.rrMode == dlssMode && state_.rrOutW == in.outW &&
                           state_.rrOutH == in.outH && state_.rrRenderW == in.renderW && state_.rrRenderH == in.renderH;
    const Mat4 view = to_mat4(in.camera.view);
    DlssdOptions options;
    init_dlssd_options(options);
    options.mode = dlssMode;
    options.outputWidth = std::uint32_t(in.outW);
    options.outputHeight = std::uint32_t(in.outH);
    options.sharpness = 0.0f;
    options.preExposure = in.exposure > 0.0f && std::isfinite(in.exposure) ? in.exposure : 1.0f;
    options.exposureScale = 1.0f;
    options.colorBuffersHdr = kTrue;
    options.indicatorInvertAxisX = options.indicatorInvertAxisY = kFalse;
    options.normalRoughnessMode = kDlssdNormalRoughnessPacked;
    options.worldToCameraView = to_float4x4(view);
    options.cameraViewToWorld = to_float4x4(view.inverse());
    options.alphaUpscalingEnabled = kFalse;
    if (!sameSizes) {
        DlssdOptimalSettings settings;
        init_dlssd_optimal_settings(settings);
        if (const SlResult r = state_.rrGetOptimal(&options, &settings); r != kOk)
            return streamline_refusal("slDLSSDGetOptimalSettings", r);
        if (std::string e = check_render_size(settings, "DLSS Ray Reconstruction", dlssMode, in); !e.empty()) return e;
    }
    ViewportHandle viewport;
    init_viewport(viewport, 0);
    state_.rrOptionsSet = false;
    if (const SlResult r = state_.rrSetOptions(&viewport, &options); r != kOk)
        return streamline_refusal("slDLSSDSetOptions", r);
    if (!state_.rrSizeChecked || state_.rrMode != dlssMode || state_.rrOutW != in.outW || state_.rrOutH != in.outH)
        state_.needReset = true;  // the history of the old mode means nothing to the new one
    state_.rrOptionsSet = true;
    state_.rrMode = dlssMode;
    state_.rrOutW = in.outW;
    state_.rrOutH = in.outH;
    state_.rrRenderW = in.renderW;
    state_.rrRenderH = in.renderH;
    state_.rrSizeChecked = true;
    return {};
}

// Vulkan: DLSS wants the output as an image with a view (the storage view of the output image, made once per output image).
std::string DlssProvider::ensure_output_view(gpu::Device& device, gpu::Image output) {
    if (state_.outputView.valid() && state_.outputImage != output) drop_output_view(device);
    if (state_.outputView.valid()) return {};
    gpu::ViewDesc v;
    v.storageImage.image = output;
    v.label = "dlss-output";
    state_.outputView = device.make_view(v);
    state_.outputImage = output;
    if (!state_.outputView.valid())
        return "the GPU could not make the storage view of the output image (the image was not made with storage "
               "usage)";
    return {};
}

std::string DlssProvider::draw(const UpscaleInput& in, VendorFrame& frame, const StreamlineApi& api,
                               StreamlineRuntime& runtime, bool rr) {
    gpu::Device& device = *frame.device;
    if (std::string e = rr ? ensure_rr_options(api, in) : ensure_options(api, in); !e.empty()) return e;
    if (state_.lastRr != rr) state_.needReset = true;  // the other feature's history means nothing here

    // The frame's token: the same one tags the resources, sets the constants and evaluates (Streamline's frame based resource tagging).
    std::string why;
    void* const token = runtime.frame_token(nullptr, &why);
    if (!token) return why;

    ViewportHandle viewport;
    init_viewport(viewport, 0);
    const auto finite = [](float v, float limit) { return std::isfinite(v) ? std::clamp(v, -limit, limit) : 0.0f; };
    Constants constants;
    init_constants(constants);
    // The jitter is in render pixels, the way XeSS takes it; the motion vectors are in UV units (the picture is 1 wide) pointing to the
    // previous position, y down, so Streamline's scale is 1. Super Resolution reads none of the matrices (identity); Ray Reconstruction
    // reads the camera's.
    constants.jitterOffset = {finite(in.jitter[0], 0.5f), finite(in.jitter[1], 0.5f)};
    constants.mvecScale = {1.0f, 1.0f};
    constants.cameraNear = 0.1f;
    constants.cameraFar = 1000.0f;
    constants.cameraFov = 1.0f;
    constants.cameraAspectRatio = float(in.outW) / float(in.outH);
    constants.motionVectorsInvalidValue = FLT_MIN;
    constants.depthInverted =
        kFalse;  // Super Resolution: the prep pass writes 0..1 growing with the distance; Ray Reconstruction: the projection's depth
    constants.cameraMotionIncluded = kTrue;
    constants.motionVectors3d = kFalse;
    constants.orthographicProjection = kFalse;
    constants.motionVectorsDilated = kFalse;
    constants.motionVectorsJittered = kFalse;
    bool reset = in.resetHistory || state_.needReset;
    if (rr) {
        const UpscaleCamera& cam = in.camera;
        const Mat4 proj = to_mat4(cam.proj);
        const Mat4 clipToView = proj.inverse();
        // The motion is reprojected with the camera of the frame before; without one (a cut) the history starts again and the matrices of
        // the previous frame are the current ones.
        const Mat4 clipToPrev = cam.prevValid ? to_mat4(cam.prevFromView) * clipToView : Mat4::identity();
        constants.cameraViewToClip = to_float4x4(proj);
        constants.clipToCameraView = to_float4x4(clipToView);
        constants.clipToPrevClip = to_float4x4(clipToPrev);
        constants.prevClipToClip = to_float4x4(clipToPrev.inverse());
        constants.cameraPos = {cam.position[0], cam.position[1], cam.position[2]};
        constants.cameraUp = {cam.up[0], cam.up[1], cam.up[2]};
        constants.cameraRight = {cam.right[0], cam.right[1], cam.right[2]};
        constants.cameraFwd = {cam.forward[0], cam.forward[1], cam.forward[2]};
        constants.cameraNear = cam.nearPlane;
        constants.cameraFar = cam.farPlane;
        constants.cameraFov = in.cameraFovY;
        constants.orthographicProjection = cam.perspective ? kFalse : kTrue;
        if (!cam.prevValid) reset = true;
    }
    constants.reset = reset ? kTrue : kFalse;
    if (const SlResult r = api.setConstants(&constants, token, &viewport); r != kOk)
        return streamline_refusal("slSetConstants", r);

    const gpu::Backend backend = device.backend();
    // The images of the frame and how each is tagged: the colour in, depth, motion, the colour out, and for Ray Reconstruction the three
    // guides (the diffuse albedo, the specular albedo, the normals with the roughness in w).
    struct Item {
        std::uint32_t type;
        gpu::Image image;
        gpu::View view;
        int w, h;
        bool write;
    };
    constexpr int kMaxItems = 8;
    Item items[kMaxItems] = {
        {kBufferScalingInputColor, frame.color, in.color, in.renderW, in.renderH, false},
        {kBufferDepth, frame.depth, in.depth, in.renderW, in.renderH, false},
        {kBufferMotionVectors, frame.velocity, in.velocity, in.renderW, in.renderH, false},
        {kBufferScalingOutputColor, frame.output, state_.outputView, in.outW, in.outH, true},
    };
    int count = 4;
    if (!rr && frame.reactive.valid() && in.reactive.valid())
        // Where particles and other items blend over the scene: DLSS Super Resolution weighs the current frame's colour more there.
        items[count++] = {kBufferBiasCurrentColorHint, frame.reactive, in.reactive, in.renderW, in.renderH, false};
    if (rr) {
        items[1] = {kBufferDepth, frame.rrDepth, in.rrDepth,
                    in.renderW,   in.renderH,    false};  // the depth of the projection it is told
        items[count++] = {kBufferAlbedo, frame.diffuseAlbedo, in.diffuseAlbedo, in.renderW, in.renderH, false};
        items[count++] = {
            kBufferSpecularAlbedo, frame.specularAlbedo, in.specularAlbedo, in.renderW, in.renderH, false};
        items[count++] = {
            kBufferNormalRoughness, frame.normalRoughness, in.normalRoughness, in.renderW, in.renderH, false};
    }
    gpu::NativeUse uses[kMaxItems];
    for (int i = 0; i < count; ++i) {
        uses[i].image = items[i].image;
        uses[i].state = items[i].write ? gpu::NativeState::UnorderedAccess : gpu::NativeState::ShaderRead;
    }

    // The resources, with their native objects, sizes and states; the handles are read before the section opens, so a failure leaves the
    // list as it was.
    struct Tagged {
        Resource resource;
        ResourceTag tag;
    };
    Tagged tagged[kMaxItems];
    const auto describe = [&](Tagged& t, const Item& item, gpu::QueueKind kind) -> std::string {
        init_resource(t.resource);
        const gpu::NativeImage ni = device.native_image(item.image);
        t.resource.width = std::uint32_t(item.w);
        t.resource.height = std::uint32_t(item.h);
        t.resource.mipLevels = 1;
        t.resource.arrayLayers = 1;
        if (backend == gpu::Backend::Vulkan) {
            const gpu::NativeView nv = device.native_view(item.view);
            if (!ni.vkImage || !nv.vkImageView)
                return "the Vulkan image or view of a DLSS input is not known to the device";
            t.resource.native = handle_of(ni.vkImage);
            t.resource.view = handle_of(nv.vkImageView);
            t.resource.nativeFormat = nv.nativeFormat;
            t.resource.mipLevels = std::uint32_t(std::max(nv.mipCount, 1));
            t.resource.arrayLayers = std::uint32_t(std::max(nv.sliceCount, 1));
            t.resource.usage = ni.vkUsage;
            t.resource.flags = 0;
            t.resource.state = item.write ? kVkLayoutGeneral : kVkLayoutShaderRead;
        } else {
            if (!ni.resource) return "the device gave no native resource for a DLSS input";
            t.resource.native = const_cast<void*>(ni.resource);
            t.resource.nativeFormat = ni.nativeFormat;
            t.resource.state =
                item.write ? kD3d12UnorderedAccess
                           : (kind == gpu::QueueKind::Compute ? kD3d12ShaderReadCompute : kD3d12ShaderReadGraphics);
        }
        init_resource_tag(t.tag);
        t.tag.resource = &t.resource;
        t.tag.type = item.type;
        t.tag.lifecycle = kOnlyValidNow;
        t.tag.extent = Extent{0, 0, std::uint32_t(item.w), std::uint32_t(item.h)};
        return {};
    };
    const gpu::QueueKind queue = frame.list->queue();
    ResourceTag tags[kMaxItems];
    for (int i = 0; i < count; ++i) {
        if (std::string e = describe(tagged[i], items[i], queue); !e.empty()) return e;
        tags[i] = tagged[i].tag;
    }

    const fa::Result<gpu::NativeCommands> native =
        frame.list->begin_native(std::span<const gpu::NativeUse>(uses, std::size_t(count)));
    if (!native) return "DLSS could not open a native command section: " + native.error().message;
    void* const list = const_cast<void*>(native->list);
    SlResult r = api.setTagForFrame(token, &viewport, tags, std::uint32_t(count), list);
    std::string what = "slSetTagForFrame";
    if (r == kOk) {
        const Base* inputs[] = {&viewport.base};
        r = api.evaluateFeature(rr ? kFeatureDlssRr : kFeatureDlss, token, inputs, 1, list);
        what = "slEvaluateFeature";
    }
    // The section is closed whatever Streamline answered: the images are left in the states they were declared in.
    const fa::Result<void> closed = frame.list->end_native();
    if (r != kOk) return "DLSS failed to draw a frame: " + streamline_refusal(what.c_str(), r);
    if (!closed) return "DLSS drew, but its native command section could not be closed: " + closed.error().message;
    state_.needReset = false;
    state_.lastRr = rr;
    return {};
}

bool DlssProvider::upscale(const UpscaleInput& in, VendorFrame& frame) {
    std::lock_guard<std::mutex> lock(mutex_);
    frame.error.clear();
    frame.usedRayReconstruction = false;
    frame.rayReconstructionFallback.clear();
    if (!frame.device || !frame.list) {
        frame.error = "DLSS was given no device or no command list.";
        return false;
    }
    gpu::Device& device = *frame.device;
    StreamlineRuntime& runtime = streamline_runtime();
    const StreamlineStatus status = runtime.status();
    const StreamlineApi* api = status.ready ? runtime.api() : nullptr;
    if (!api) {
        frame.error = status.reason.empty() ? "NVIDIA Streamline is not running on this device." : status.reason;
        return false;
    }
    if (device.backend() != status.backend) {
        frame.error = "NVIDIA Streamline was started for " + std::string(vendor_backend_label(status.backend)) +
                      " and this device is " + vendor_backend_label(device.backend()) + ".";
        return false;
    }
    if (!frame.color.valid() || !frame.output.valid() || !frame.depth.valid() || !frame.velocity.valid()) {
        frame.error = "DLSS needs the colour, depth, velocity and output images of the frame (the frame has no " +
                      std::string(!frame.color.valid()      ? "colour"
                                  : !frame.depth.valid()    ? "depth"
                                  : !frame.velocity.valid() ? "velocity"
                                                            : "output") +
                      " image).";
        return false;
    }
    if (in.renderW <= 0 || in.renderH <= 0 || in.outW <= 0 || in.outH <= 0) {
        frame.error = "DLSS was given an empty picture (" + std::to_string(in.renderW) + "x" +
                      std::to_string(in.renderH) + " -> " + std::to_string(in.outW) + "x" + std::to_string(in.outH) +
                      ").";
        return false;
    }
    bind_state(device, status.generation);
    if (device.backend() == gpu::Backend::Vulkan) {
        if (std::string e = ensure_output_view(device, frame.output); !e.empty())
            return fail(frame, "DLSS: " + e + ".");
    }

    if (in.rayReconstruction) {
        // Ray Reconstruction needs the guides and the camera of the frame, linear HDR colour, no dynamic resolution; a frame that has not
        // got them, or that Streamline refuses, is drawn with Super Resolution and says why.
        std::string why;
        if (!frame.normalRoughness.valid() || !frame.diffuseAlbedo.valid() || !frame.specularAlbedo.valid() ||
            !in.normalRoughness.valid() || !in.diffuseAlbedo.valid() || !in.specularAlbedo.valid() ||
            !frame.rrDepth.valid() || !in.rrDepth.valid())
            why = "the frame has no guide images (normal and roughness, diffuse albedo, specular albedo, depth of the "
                  "projection)";
        else if (!in.camera.valid)
            why = "the frame has no camera matrices";
        else if (!in.linear)
            why = "the frame is not in linear HDR light";
        else if (in.dynamicResolution)
            why = "the frame is drawn with a dynamic resolution";
        else
            why = draw(in, frame, *api, runtime, true);
        if (why.empty()) {
            frame.usedRayReconstruction = true;
            return true;
        }
        frame.rayReconstructionFallback = "DLSS Ray Reconstruction could not draw a frame (" + why + ").";
        state_.needReset =
            true;  // whatever the failed attempt left in Streamline, the next frame starts its history again
    }
    if (std::string e = draw(in, frame, *api, runtime, false); !e.empty()) return fail(frame, std::move(e));
    return true;
}

void DlssProvider::release(gpu::Device& device) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (state_.device != &device) return;  // it never drew on this device
    StreamlineRuntime& runtime = streamline_runtime();
    const StreamlineStatus status = runtime.status();
    const StreamlineApi* api = status.ready && status.generation == state_.generation ? runtime.api() : nullptr;
    if (api) {
        // The GPU may still be running the last frame with DLSS's resources: wait, then give them back.
        if (const fa::Result<void> idle = device.wait_idle(); !idle)
            FA_WARN("render", "DLSS: {}", idle.error().message);
        ViewportHandle viewport;
        init_viewport(viewport, 0);
        if (state_.optionsSet && state_.setOptions) {
            DlssOptions off;
            init_dlss_options(off);
            off.mode = kDlssOff;
            state_.setOptions(&viewport, &off);
        }
        if (state_.rrOptionsSet && state_.rrSetOptions) {
            DlssdOptions off;
            init_dlssd_options(off);
            off.mode = kDlssOff;
            state_.rrSetOptions(&viewport, &off);
        }
        if (api->freeResources) {
            api->freeResources(kFeatureDlss, &viewport);
            if (state_.rrSetOptions)
                api->freeResources(kFeatureDlssRr, &viewport);  // only when Ray Reconstruction ever drew
        }
    }
    drop_output_view(device);
    state_ = State{};
}

}  // namespace

std::uint32_t dlss_mode_for_ratio(float ratio, std::uint32_t current) {
    if (current != 0) {
        for (const ModeRow& m : kModes)
            if (m.mode == current && std::fabs(ratio - m.ratio) <= kModeBand) return current;
    }
    std::uint32_t best = kModes[0].mode;
    float bestDistance = FLT_MAX;
    for (const ModeRow& m : kModes) {
        const float d = std::fabs(ratio - m.ratio);
        if (d < bestDistance) {
            bestDistance = d;
            best = m.mode;
        }
    }
    return best;
}

float dlss_mode_ratio(std::uint32_t mode) {
    for (const ModeRow& m : kModes)
        if (m.mode == mode) return m.ratio;
    return 1.0f;
}

const char* dlss_mode_name(std::uint32_t mode) {
    for (const ModeRow& m : kModes)
        if (m.mode == mode) return m.name;
    return "unknown";
}

std::unique_ptr<VendorUpscaler> make_dlss_provider() { return std::make_unique<DlssProvider>(); }

}  // namespace fa::render
