// HDR display output: what the display the game window is on can show, and the window's swapchain switched to a high
// dynamic range format when the scene asks for it (SceneSettings.hdrOutput "auto") and the display, the OS and the renderer
// allow it (docs/RENDERING.md, "HDR output").
//
//   * Windows (D3D11): the DXGI output the window is on (IDXGIOutput6::GetDesc1): HDR is on when Windows composes it in
//     HDR10 (Settings > System > Display > Use HDR); its luminances in nits. The swapchain becomes R16G16B16A16_FLOAT in
//     scRGB (DXGI_COLOR_SPACE_RGB_FULL_G10_NONE_P709), or R10G10B10A2 in HDR10 (ST.2084, Rec.2020) when scRGB is refused.
//   * macOS and iOS (Metal): the screen's extended dynamic range (EDR) headroom: how many times brighter than white it can
//     go (NSScreen / UIScreen). The CAMetalLayer becomes RGBA16Float with wantsExtendedDynamicRangeContent and an
//     extended linear sRGB colour space (HdrRequest::edrLinear; the renderer asks for it).
//   * Linux, Android, the web and headless runs: no HDR output.
//
// The display is asked again each frame while the scene wants HDR (cheap calls only), else every 120th frame: the window
// moving to another monitor, the user switching HDR on or off and a display change all reach the next frame, and the
// swapchain goes back to the standard range cleanly when the display loses HDR.
#pragma once

#include <string>

namespace fa {

// How the window's pixels are encoded. Sdr: 8-bit sRGB, white is the brightest. ScRgb (Windows): 16-bit float, linear,
// 1.0 = 80 nits. Hdr10 (Windows): 10-bit ST.2084 (PQ) in Rec.2020, absolute nits. Edr (macOS, iOS): 16-bit float in
// extended sRGB (extended linear sRGB with HdrRequest::edrLinear), 1.0 = the display's white (its current brightness), values up to the EDR headroom are brighter.
enum class HdrEncoding { Sdr, ScRgb, Hdr10, Edr };
inline constexpr int kHdrEncodingCount = 4;
// "sdr", "scRGB", "hdr10", "edr".
const char* hdr_encoding_name(HdrEncoding e);
constexpr unsigned hdr_encoding_bit(HdrEncoding e) { return 1u << unsigned(e); }

// What the display the window is on can show now.
struct HdrDisplay {
    bool known = false;   // the platform answered (false: no window, or a platform without HDR output)
    bool hdr = false;     // it can show HDR right now
    unsigned offers = 0;  // hdr_encoding_bit() of each HDR encoding it takes (Windows: scRGB and HDR10; Apple: EDR)
    std::string name;     // the monitor's name ("" when unknown)
    // Luminances in nits (cd/m2) as the display reports them (Windows); 0 = the platform does not say (macOS, iOS).
    float maxNits = 0.0f;
    float minNits = 0.0f;
    float maxFullFrameNits = 0.0f;
    // EDR (macOS, iOS): how many times brighter than white the screen can ever go (maximumPotentialExtendedDynamicRange-
    // ColorComponentValue / potentialEDRHeadroom), and can go now (it falls as the brightness rises, and stays 1.0 until a
    // window asks for EDR). 1 elsewhere.
    float maxHeadroom = 1.0f;
    float headroom = 1.0f;
    std::string why;  // !hdr: why, in one sentence ("Windows: HDR is off for this display in Settings > ...")
};

// What the game asks for (Renderer::update_output fills it from SceneSettings and from what its present pass can write).
struct HdrRequest {
    bool want = false;              // SceneSettings.hdrOutput == auto
    float paperWhiteNits = 200.0f;  // SceneSettings.paperWhiteNits
    unsigned encodable = 0;         // hdr_encoding_bit() of each HDR encoding the renderer writes correctly
    bool edrLinear = false;  // Edr: the renderer writes linear light (extended linear sRGB), not sRGB-encoded values
    // What the renderer cannot write yet, for the reason given when the display offers only that ("" = nothing pending).
    std::string pending;
    // Added to the status while an HDR encoding is active: what the picture still lacks ("" = nothing).
    std::string activeNote;
    // Non-empty: this window never switches (the editor draws the game in its own view), and this is why.
    std::string blocked;
};

// The decision: the encoding to use, and the one to try when the platform refuses it (Windows: HDR10 after scRGB).
struct HdrDecision {
    HdrEncoding encoding = HdrEncoding::Sdr;
    HdrEncoding fallback = HdrEncoding::Sdr;
    std::string why;  // Sdr: why not HDR, one sentence
};

// Pure: which encoding a request gets on a display. HDR only when the request wants it, the display offers an encoding the
// renderer writes, in the order EDR, scRGB, HDR10.
HdrDecision decide_hdr_output(const HdrRequest& request, const HdrDisplay& display);

// What the window shows now (Renderer::output_info, the render.output command).
struct HdrOutputInfo {
    bool requested = false;  // SceneSettings.hdrOutput is auto
    bool active = false;     // the swapchain is in an HDR encoding
    HdrEncoding encoding = HdrEncoding::Sdr;
    std::string swapchainFormat;  // "BGRA8", "RGBA16F", "RGB10A2"; "" without a window or before the first frame
    float maxNits = 0.0f;         // the display's peak (0 = unknown)
    float paperWhiteNits = 200.0f;
    // How many times brighter than white (paper white) the output can go now: the current EDR headroom, maxNits /
    // paperWhiteNits in scRGB and HDR10 (1 when the display does not say), 1 in SDR. Rounded to 2 decimals.
    float headroom = 1.0f;
    std::string status;  // one sentence: what is shown, or why the picture stays in the standard range
    HdrDisplay display;
};

// Pure: the info for `decision` once the platform applied `applied` (what really is on the swapchain).
HdrOutputInfo make_hdr_output_info(const HdrRequest& request, const HdrDisplay& display, const HdrDecision& decision,
                                   HdrEncoding applied, const std::string& swapchainFormat);

// Windows (pure, for tests): the display from what DXGI_OUTPUT_DESC1 says. `pqColorSpace`: its ColorSpace is
// DXGI_COLOR_SPACE_RGB_FULL_G2084_NONE_P2020 (Windows composes it in HDR).
HdrDisplay hdr_display_from_dxgi(bool pqColorSpace, float maxNits, float minNits, float maxFullFrameNits,
                                 const std::string& name);
// Apple (pure, for tests): the display from its EDR headroom (potential and current).
HdrDisplay hdr_display_from_edr(float maxHeadroom, float headroom, const std::string& name);

// The display the game window is on, asked now. Without a window (headless runs, tests, the editor before its window):
// known == false. Call on the thread that runs the window's callbacks.
HdrDisplay app_hdr_display();
// Once per frame before app_gfx_swapchain(): decides and switches the window's swapchain (only when the answer changes)
// and returns what is shown. Window thread only. The display is asked each call while the request wants HDR (and is not
// blocked), else every 120th call.
HdrOutputInfo app_update_hdr_output(const HdrRequest& request);
// The same, for a caller that calls it every frame: fills `info` and returns true when it did, false (`info` untouched, nothing
// built, copied or locked) when the request is the one of the last update, it does not want HDR (or is blocked) and the display
// is not due to be asked: the answer of the last update still stands.
bool app_update_hdr_output(const HdrRequest& request, HdrOutputInfo& info);
// The last answer of app_update_hdr_output (any thread). Before the first one: SDR, status "no frame presented yet".
HdrOutputInfo app_hdr_output();

}  // namespace fa
