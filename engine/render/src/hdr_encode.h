// The HDR display output, renderer side (M71; docs/RENDERING.md, "HDR output"): which encode a frame is drawn for, the tonemap that
// goes above paper white, and the encodes of the present pass. Pure CPU: the shaders do the same maths (post.glsl: the HDR tonemap,
// blit.glsl: the encodes), and the tests check these functions and compare the GPU's answer with them.
//
// The picture between the passes. The final pass of the post stack (post.glsl) writes display-referred light ENCODED with the sRGB
// transfer function, extended above 1 (1.0 = paper white): in SDR it stays within [0, 1], exactly as before; for an HDR window it goes
// up to the output's headroom. The HUD is drawn over it in the same space, within 1, so it stays at paper white. The present pass
// (blit.glsl) decodes it to linear light and encodes it for the swapchain:
//
//   Sdr        8-bit sRGB: the values as they are, clamped to [0, 1]
//   ScRgb      D3D11 R16G16B16A16_FLOAT: linear Rec.709 where 1.0 = 80 nits, so light x paperWhiteNits / 80
//   Hdr10      D3D11 R10G10B10A2_UNORM: Rec.709 -> Rec.2020, nits = light x paperWhiteNits, the ST 2084 (PQ) inverse EOTF
//   EdrLinear  Metal RGBA16Float, extended LINEAR sRGB: the light as it is (1.0 = the screen's white: on Apple the system sets it,
//              paperWhiteNits does not apply), values above 1 up to the screen's current EDR headroom
//
// A frame without the final pass (no exposure, tonemap or colour filter) is never brighter than paper white in any encoding: only the
// tonemap decides what goes above it.
#pragma once

#include <array>
#include <cstdint>

#include "fa/platform/hdr_output.h"

namespace fa::render {

enum class OutputEncode : std::uint8_t { Sdr, ScRgb, Hdr10, EdrLinear };
inline constexpr int kOutputEncodeCount = 4;
// "sdr", "scRGB", "hdr10", "edrLinear".
const char* output_encode_name(OutputEncode e);

// The top of the PQ curve, 10000 nits, over the lowest paper white (80): no output goes further above paper white.
inline constexpr float kMaxHeadroom = 125.0f;

// What a frame is drawn for. `headroom` is how many times paper white the final pass may write (1: within paper white, the SDR
// tonemap); `paperWhiteNits` is what 1.0 is on the display (scRGB and HDR10; 80..1000).
struct OutputTarget {
    OutputEncode encode = OutputEncode::Sdr;
    float headroom = 1.0f;
    float paperWhiteNits = 200.0f;
    // The final pass draws the HDR tonemap (above paper white): an HDR encode with room above white.
    bool extended() const { return encode != OutputEncode::Sdr && headroom > 1.0f; }
};

// Pure: the encode of the window's output now. `floatDisplay`: the images the final pass writes hold values above 1 (RGBA16F,
// R11G11B10); without, the picture is encoded for the HDR swapchain but stays within paper white (headroom 1). The headroom is the
// output's (HdrOutputInfo::headroom: the EDR headroom now, the display's peak over paper white in scRGB and HDR10), at most
// 10000 nits over paper white; NaN or below 1 is 1.
OutputTarget select_output(const HdrOutputInfo& info, bool floatDisplay);

using Rgb = std::array<float, 3>;

// SMPTE ST 2084 (PQ): absolute luminance in nits (0..10000) -> the 0..1 signal, and back. Clamped to that range; NaN is 0.
float pq_from_nits(float nits);
float nits_from_pq(float signal);
// Linear Rec.709 (sRGB primaries) -> linear Rec.2020 (ITU-R BT.2087): white stays white.
Rgb rec709_to_rec2020(const Rgb& c);
// What the present pass writes for linear light `light` (1.0 = paper white, already within the output's range): the values the
// swapchain of `encode` stores (Sdr: sRGB-encoded, clamped to [0, 1]).
Rgb encode_output(OutputEncode encode, const Rgb& light, float paperWhiteNits);

// An IEEE 754 half (the RGBA16F texels a test reads back) as a float.
float half_to_float(std::uint16_t h);

// ---- the tonemap above paper white (post.glsl, tonemap_hdr) -------------------------------------------------------------------
// The tonemaps of the final pass (PostProcess.tonemapMode as an int: 0 none, 1 neutral, 2 aces, 3 agx, 4 reinhard), as post.glsl
// computes them: scene-linear in, display-linear 0..1 out.
Rgb tonemap_sdr(const Rgb& c, int mode);
// Where the HDR curve leaves the SDR one: the display value `start` (0.76 for neutral, where its own shoulder begins; 0.5 for
// the others), the scene value `input` the SDR curve maps there, and the curve's slope at that point.
struct HdrShoulder {
    float start = 0.5f;
    float input = 1.0f;
    float slope = 0.25f;
};
HdrShoulder hdr_shoulder(int mode);
// The tonemap for a display `headroom` times brighter than paper white. Below the shoulder it is the SDR curve, so mid tones and
// shadows look as on an SDR screen; above it the brightest channel rolls off toward the headroom instead of toward 1:
// start + (H - start) x / (1 + x), x = slope (c - input) / (H - start) (the same value and slope where the two meet), and the colour
// keeps the SDR curve's ratios between its channels. Between headroom 1 and 2 it is mixed with the SDR curve (weight H - 1), so a
// headroom that follows the screen's brightness never jumps. `none` (mode 0) clips at the headroom instead of at 1.
Rgb tonemap_hdr(const Rgb& c, int mode, float headroom);

}  // namespace fa::render
