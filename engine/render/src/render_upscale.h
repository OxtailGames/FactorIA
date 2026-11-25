// The upscale stage (M76-P3a): brings the frame's picture from the render resolution (design size * renderScale) back to the output
// resolution (the design size) when the game is drawn below it, and is the seam the spatial, temporal and MetalFX upscalers plug into
// (docs/design/ARCHITECTURE_RENDERING.md, "Upscale stage (M76)"). The stage is a pass of the frame graph that runs after the post
// stack and the colour filter of the render-resolution picture; the screen-space items (HUD, UI, debug text) are drawn after it, into
// the output image, at the output resolution.
//
// Off (no pass, no image) unless Renderer::set_upscale_stage(true) and the render scale is below 1: the picture then goes from
// the game target to present() as it always did.
#pragma once

#include <cstdint>
#include <string_view>

#include "fa/render/upscaler.h"

#include "gpu/types.h"

namespace fa::render {

// How the picture is brought to the output resolution. Stretch is a copy through a Linear sampler (Nearest for pixel art): the image
// the renderer made at scale 1 is never touched by it. Spatial (M76-P3b, shaders/upscale_spatial.glsl) is the edge-adaptive upsample
// and the contrast-adaptive sharpen. Temporal (M76-P4): the camera is jittered at the render resolution and the TAA resolve accumulates the
// frames into a history of the OUTPUT resolution (renderer_taa.h, TaaFx::upscale); where it cannot run, spatial draws. MetalFx (M76-P5b):
// Apple's temporal scaler (the same jittered frame, the depth and motion of the prepass) or its spatial scaler (renderer_metalfx.cpp); where
// it cannot run for a frame, Temporal draws, and Spatial where that cannot either. Dlss, Xess and Fsr (M78): a vendor SDK's temporal
// upscaler through its provider (render_upscale_vendor.h) on the same jittered frame, depth and motion; a provider that cannot draw a frame
// (and is then off for the rest of the run) makes the Temporal upscaler draw it.
enum class UpscaleImpl : std::uint8_t { Stretch, Spatial, Temporal, MetalFx, Dlss, Xess, Fsr };

// Whether `impl` is one of the vendor SDK implementations, and which (0 dlss, 1 xess, 2 fsr; -1 none): the index of vendor_provider().
constexpr int vendor_impl_index(UpscaleImpl impl) {
    return impl == UpscaleImpl::Dlss ? 0 : impl == UpscaleImpl::Xess ? 1 : impl == UpscaleImpl::Fsr ? 2 : -1;
}
constexpr UpscaleImpl vendor_impl(int index) {
    return index == 0   ? UpscaleImpl::Dlss
           : index == 1 ? UpscaleImpl::Xess
           : index == 2 ? UpscaleImpl::Fsr
                        : UpscaleImpl::Stretch;
}

// The implementation a mode name selects ("stretch", "spatial", "temporal", "metalfx", "dlss", "xess", "fsr"). A name this build does not know (a
// typo, a mode of a later version, an implementation the GPU cannot run) selects Stretch: the game is never left without a picture.
// `known`, when given, says whether the name was understood. ("auto" is not an implementation: effective_upscaler_mode picks one.)
UpscaleImpl select_upscale_impl(std::string_view mode, bool* known = nullptr);
const char* upscale_impl_name(UpscaleImpl impl);

// The length of the jitter sequence of the temporal upscaler: ceil(8 * (output area / render area)), so every output pixel is covered by
// about eight samples of the sequence whatever the ratio (8 at a ratio of 1, 18 at 1.5 per side, 32 at 2, 72 at 3), at most
// kJitterPhasesMax. Pure CPU. A size below 1 reads as 1.
int upscale_jitter_phases(int renderW, int renderH, int outW, int outH);

// What an upscaler reads. `color` is the picture at the render resolution (display values after a final pass, else the scene's
// colour: the format of the output image is the same, so the copy never converts). `depth` (linear view depth) and `velocity` are
// null views until the passes that make them exist; an implementation that needs them must work without (camera reprojection).
// The camera the frame was drawn with, for the upscalers that are told its matrices (DLSS Ray Reconstruction, M78-P4c). The matrices are in
// the order of fa::Mat4 (column-major, a column vector on the right: the memory of a row-major matrix with a row vector on the left, which is
// how Streamline reads them) and unjittered, with the depth range of the backend (0..1 on D3D12, Vulkan and Metal).
struct UpscaleCamera {
    bool valid = false;  // false: a test or a frame without a camera; the provider then sends identity matrices
    bool perspective = true;
    float view[16] = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1};  // world -> camera view
    float proj[16] = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1};  // camera view -> clip
    // A view-space position of this frame -> the clip position it had on the frame before; valid only with prevValid.
    float prevFromView[16] = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1};
    bool prevValid = false;
    float position[3] = {0, 0, 0}, right[3] = {1, 0, 0}, up[3] = {0, 1, 0},
          forward[3] = {0, 0, -1};  // the camera's frame in the world
    float nearPlane = 0.1f, farPlane = 1000.0f;
};

struct UpscaleInput {
    gpu::View color{};
    gpu::View depth{};
    gpu::View velocity{};
    // The reactive mask of the frame (R8, the picture's size: 1 where particles and other items blend over the scene and the history must not
    // be trusted); null when no item asked for one. The temporal upscaler and MetalFX read it from the frame graph's transient; the vendor
    // SDKs get it here.
    gpu::View reactive{};
    // The factor the scene's colour was multiplied by before the stage (the exposure of the camera): 1 today, because the scene is exposed
    // (and tone mapped) before the upscale pass, as MetalFX is told too (pre-exposure 1). The vendor SDKs take it as their pre-exposure.
    float exposure = 1.0f;
    float jitter[2] = {0.0f, 0.0f};  // this frame's camera jitter, in render pixels (0 until a temporal mode jitters)
    int renderW = 0, renderH = 0;    // size of `color`
    int outW = 0, outH = 0;          // size of the output image
    std::uint64_t frameIndex = 0;    // the renderer's frame counter (Renderer::Impl::frameSerial)
    bool resetHistory = false;       // a cut, a resize or a change of mode: drop what was accumulated
    bool pixelArt = false;           // ScaleMode::PixelPerfect: sample with Nearest, never blend
    bool linear =
        false;  // `color` holds linear light (a linear scene without a final pass): filters work on a perceptual curve
    float sharpness = 0.0f;  // UpscalerSettings::sharpness, 0..1: the sharpen of Spatial (Stretch ignores it)
    // What the vendor SDKs (M78) ask besides the picture; filled by Renderer::Impl::vendor_upscale.
    UpscalerQuality quality = UpscalerQuality::Native;  // the quality the game asked for (UpscalerSettings::quality)
    int maxRenderW = 0, maxRenderH = 0;  // the largest render size the game can draw at (its base scale); >= renderW/H
    bool dynamicResolution = false;      // the render size moves under the game's base scale (the dynamic resolution)
    float frameTimeMs =
        0.0f;  // the time this frame stands for, in milliseconds: the engine clock's dt (not the wall clock)
    float cameraNear =
        0.1f;  // the near plane the prepared depth was made for (render_upscale_vendor.h, reversed depth)
    float cameraFovY = 1.0f;  // the camera's vertical field of view in radians (2 * atan(1 / P11))
    UpscaleCamera camera;     // the frame's camera (valid when the renderer filled it in)
    // DLSS Ray Reconstruction (M78-P4c): the setting asks for it and the renderer made the guides below at the picture's size. Only the DLSS
    // provider reads them; it draws with Super Resolution when it cannot use them (VendorFrame::rayReconstructionFallback says why).
    bool rayReconstruction = false;
    gpu::View normalRoughness{};  // RGBA16F: the world-space normal (xyz, unit length) and the roughness (w, 0..1)
    gpu::View
        diffuseAlbedo{};  // RGBA8: the diffuse reflectance (a constant today: the renderer has no material G-buffer)
    gpu::View specularAlbedo{};  // RGBA8: the specular reflectance (a constant today)
    // R32F: the hardware depth of `camera.proj` (clip z / clip w of the unjittered projection, 0..1, 1 for the sky). Ray Reconstruction is
    // told the projection and rebuilds the view position from this depth, so it reads it instead of `depth` (d / (d + 1)).
    gpu::View rrDepth{};
};

}  // namespace fa::render
