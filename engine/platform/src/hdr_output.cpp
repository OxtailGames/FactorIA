// HDR display output (fa/platform/hdr_output.h): the pure decision and info, and the per-platform display query and
// swapchain switch (Windows in hdr_output_win32.cpp, Apple through sokol_impl_apple.m).
#include "fa/platform/hdr_output.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <mutex>

#include "fa/core/log.h"
#include "sokol_app.h"
#include "sokol_window.h"

#if defined(_WIN32) && defined(SOKOL_D3D11)
#include "hdr_output_impl.h"
#define FA_HDR_DXGI 1
#elif defined(__APPLE__) && defined(SOKOL_METAL)
#define FA_HDR_EDR 1
#endif

namespace fa {

namespace {

float round2(float v) { return std::isfinite(v) ? std::round(v * 100.0f) / 100.0f : 0.0f; }
float nits(float v) { return std::isfinite(v) && v > 0.0f ? round2(v) : 0.0f; }
float paper_white(float v) { return std::isfinite(v) ? std::clamp(v, 80.0f, 1000.0f) : 200.0f; }

std::string number(float v) {
    char buf[32];
    std::snprintf(buf, sizeof(buf), "%.2f", double(v));
    std::string s = buf;
    while (!s.empty() && s.back() == '0') s.pop_back();
    if (!s.empty() && s.back() == '.') s.pop_back();
    return s;
}

constexpr HdrEncoding kOrder[] = {HdrEncoding::Edr, HdrEncoding::ScRgb, HdrEncoding::Hdr10};

}  // namespace

const char* hdr_encoding_name(HdrEncoding e) {
    switch (e) {
        case HdrEncoding::Sdr: return "sdr";
        case HdrEncoding::ScRgb: return "scRGB";
        case HdrEncoding::Hdr10: return "hdr10";
        case HdrEncoding::Edr: return "edr";
    }
    return "sdr";
}

HdrDecision decide_hdr_output(const HdrRequest& request, const HdrDisplay& display) {
    HdrDecision d;
    if (!request.want) {
        d.why = "SceneSettings.hdrOutput is off (set it to \"auto\" to use an HDR display)";
        return d;
    }
    if (!request.blocked.empty()) {
        d.why = request.blocked;
        return d;
    }
    if (!display.known) {
        d.why = display.why.empty() ? "the display the window is on is unknown" : display.why;
        return d;
    }
    if (!display.hdr || display.offers == 0) {
        d.why = display.why.empty() ? "the display cannot show HDR now" : display.why;
        return d;
    }
    const unsigned usable = display.offers & request.encodable;
    int picked = 0;
    for (HdrEncoding e : kOrder) {
        if (!(usable & hdr_encoding_bit(e))) continue;
        if (picked++ == 0)
            d.encoding = e;
        else if (d.fallback == HdrEncoding::Sdr)
            d.fallback = e;
    }
    if (picked == 0) {
        std::string offered;
        for (HdrEncoding e : kOrder)
            if (display.offers & hdr_encoding_bit(e))
                offered += (offered.empty() ? "" : " or ") + std::string(hdr_encoding_name(e));
        d.why = request.pending.empty() ? "the display takes " + offered + ", which the renderer does not write"
                                        : request.pending;
    }
    return d;
}

HdrOutputInfo make_hdr_output_info(const HdrRequest& request, const HdrDisplay& display, const HdrDecision& decision,
                                   HdrEncoding applied, const std::string& swapchainFormat) {
    HdrOutputInfo info;
    info.requested = request.want;
    info.active = applied != HdrEncoding::Sdr;
    info.encoding = applied;
    info.swapchainFormat = swapchainFormat;
    info.maxNits = nits(display.maxNits);
    info.paperWhiteNits = paper_white(request.paperWhiteNits);
    info.display = display;
    float headroom = 1.0f;
    if (applied == HdrEncoding::Edr)
        headroom = display.headroom;
    else if (info.active && info.maxNits > 0.0f)
        headroom = info.maxNits / info.paperWhiteNits;
    info.headroom = round2(std::isfinite(headroom) ? std::max(1.0f, headroom) : 1.0f);
    const std::string on = display.name.empty() ? "" : " on " + display.name;
    if (info.active) {
        info.status = std::string("HDR output in ") + hdr_encoding_name(applied) + on + ", up to " +
                      number(info.headroom) + " times paper white";
        if (!request.activeNote.empty()) info.status += "; " + request.activeNote;
    } else if (decision.encoding != HdrEncoding::Sdr) {
        info.status =
            std::string("the display takes ") + hdr_encoding_name(decision.encoding) +
            " but the swapchain could not switch to it (the graphics driver refused), so the picture stays in "
            "the standard range";
    } else {
        info.status = decision.why;
    }
    return info;
}

HdrDisplay hdr_display_from_dxgi(bool pqColorSpace, float maxNits, float minNits, float maxFullFrameNits,
                                 const std::string& name) {
    HdrDisplay d;
    d.known = true;
    d.name = name;
    d.maxNits = nits(maxNits);
    d.minNits = nits(minNits);
    d.maxFullFrameNits = nits(maxFullFrameNits);
    d.hdr = pqColorSpace;
    if (pqColorSpace)
        d.offers = hdr_encoding_bit(HdrEncoding::ScRgb) | hdr_encoding_bit(HdrEncoding::Hdr10);
    else if (d.maxNits >= 400.0f)
        d.why = "Windows: HDR is off for this display (Settings > System > Display > Use HDR)";
    else
        d.why = "Windows: this display shows the standard range only (Windows does not compose it in HDR)";
    return d;
}

HdrDisplay hdr_display_from_edr(float maxHeadroom, float headroom, const std::string& name) {
    HdrDisplay d;
    d.known = true;
    d.name = name;
    d.maxHeadroom = std::isfinite(maxHeadroom) ? std::max(1.0f, round2(maxHeadroom)) : 1.0f;
    d.headroom = std::isfinite(headroom) ? std::max(1.0f, round2(headroom)) : 1.0f;
    d.hdr = d.maxHeadroom > 1.0f;
    if (d.hdr)
        d.offers = hdr_encoding_bit(HdrEncoding::Edr);
    else
        d.why = "this screen has no extended dynamic range (its EDR headroom is 1: nothing brighter than white)";
    return d;
}

// ---- the window ------------------------------------------------------------------------------------------------------

namespace {

struct OutputState {
    std::mutex mutex;
    HdrOutputInfo info;
    bool updated = false;
    // What the last switch asked for and got (window thread only). The switch is tried again only when the decision changes,
    // so a driver that refuses is not asked every frame.
    HdrEncoding asked = HdrEncoding::Sdr;
    HdrEncoding applied = HdrEncoding::Sdr;
    bool askedLinear = false;
    HdrEncoding logged = HdrEncoding::Sdr;  // what the log line last said
    bool loggedWant = false;
};
OutputState& output_state() {
    static OutputState s;
    return s;
}

HdrDisplay no_window() {
    HdrDisplay d;
    d.why = "there is no window (a headless run draws offscreen, in the standard range)";
    return d;
}

std::string swapchain_format() {
    if (!sapp_isvalid()) return {};
    if (fa_sapp_swapchain_kind() == 2) return "RGB10A2";
    switch (sapp_color_format()) {
        case SAPP_PIXELFORMAT_RGBA8: return "RGBA8";
        case SAPP_PIXELFORMAT_SRGB8A8: return "SRGBA8";
        case SAPP_PIXELFORMAT_BGRA8: return "BGRA8";
        case SAPP_PIXELFORMAT_SBGR8A8: return "SBGRA8";
        case SAPP_PIXELFORMAT_RGBA16F: return "RGBA16F";
        default: return "?";
    }
}

HdrEncoding apply(HdrEncoding e, bool linear) {
#if defined(FA_HDR_DXGI)
    (void)linear;
    return hdr_impl::dxgi_apply(e);
#elif defined(FA_HDR_EDR)
    return fa_sapp_set_swapchain_kind(e == HdrEncoding::Edr ? 1 : 0, linear) == 1 ? HdrEncoding::Edr : HdrEncoding::Sdr;
#else
    (void)e;
    (void)linear;
    return HdrEncoding::Sdr;
#endif
}

}  // namespace

HdrDisplay app_hdr_display() {
    if (!sapp_isvalid()) return no_window();
#if defined(FA_HDR_DXGI)
    return hdr_impl::dxgi_display();
#elif defined(FA_HDR_EDR)
    fa_sapp_edr_screen s;
    if (!fa_sapp_edr(&s)) {
        HdrDisplay d;
        d.why = s.old_os ? "iOS before 16 has no extended dynamic range for apps" : "the window has no screen yet";
        return d;
    }
    return hdr_display_from_edr(s.max_headroom, s.headroom, s.name);
#else
    HdrDisplay d;
#if defined(_WIN32)
    d.why = "only the D3D11 backend has HDR output on Windows (this build draws with OpenGL)";
#elif defined(__APPLE__)
    d.why = "only the Metal backend has HDR output on Apple platforms";
#elif defined(__ANDROID__)
    d.why = "Android has no HDR output in FactorIA yet (the standard range on every phone)";
#elif defined(__EMSCRIPTEN__)
    d.why = "the web has no HDR output in FactorIA (browsers show the canvas in the standard range)";
#else
    d.why = "Linux has no HDR output in FactorIA (X11 has none; the window shows the standard range)";
#endif
    return d;
#endif
}

HdrOutputInfo app_update_hdr_output(const HdrRequest& request) {
    OutputState& s = output_state();
    const HdrDisplay display = app_hdr_display();
    const HdrDecision decision = decide_hdr_output(request, display);
    const bool linear = decision.encoding == HdrEncoding::Edr && request.edrLinear;
    if (sapp_isvalid() && (decision.encoding != s.asked || linear != s.askedLinear)) {
        s.asked = decision.encoding;
        s.askedLinear = linear;
        s.applied = apply(decision.encoding, linear);
        if (s.applied != decision.encoding && decision.fallback != HdrEncoding::Sdr)
            s.applied = apply(decision.fallback, false);
    }
    // A switch the driver refused is not counted as asked for again while the decision stays; the fallback that took is
    // what the info reports.
    HdrDecision shown = decision;
    if (s.applied == decision.fallback && decision.fallback != HdrEncoding::Sdr) shown.encoding = decision.fallback;
    HdrOutputInfo info = make_hdr_output_info(request, display, shown, s.applied, swapchain_format());
    // One line in the log when the window changes encoding (or a request for HDR first meets a display), never per frame.
    if (sapp_isvalid() && (s.applied != s.logged || (request.want && !s.loggedWant))) {
        FA_INFO("render", "HDR output: {} (display '{}': EDR headroom {} now, {} at most; {} nits peak)", info.status,
                display.name, number(display.headroom), number(display.maxHeadroom), number(display.maxNits));
        s.logged = s.applied;
    }
    s.loggedWant = request.want;
    std::lock_guard<std::mutex> lock(s.mutex);
    s.info = info;
    s.updated = true;
    return info;
}

HdrOutputInfo app_hdr_output() {
    OutputState& s = output_state();
    {
        std::lock_guard<std::mutex> lock(s.mutex);
        if (s.updated) return s.info;
    }
    HdrOutputInfo info;
    if (!sapp_isvalid()) {
        info.display = no_window();
        info.status = info.display.why;
    } else {
        info.swapchainFormat = swapchain_format();
        info.status = "no frame has been presented yet";
    }
    return info;
}

}  // namespace fa
