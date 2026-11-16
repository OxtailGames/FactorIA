// The IME backend of Windows (docs/TEXT.md, "What composes where"): IMM32 on the window sokol_app made. sokol_app is not
// edited: while an Input is attached its window procedure is subclassed (SetWindowLongPtrW(GWLP_WNDPROC)), and every
// message goes on to it (CallWindowProcW) except these:
//  - WM_IME_SETCONTEXT goes on without ISC_SHOWUICOMPOSITIONWINDOW: the IME does not draw its own composition window (the
//    TextField draws the composition at its caret); its candidate window stays.
//  - WM_IME_STARTCOMPOSITION / COMPOSITION / ENDCOMPOSITION are read from the input context and become Input's composition
//    events (ime_imm.h decides; tests/ime_imm_tests.cpp covers it on every host). They do not reach DefWindowProc, so
//    Windows makes no WM_IME_CHAR / WM_CHAR of a result: the commit is its only delivery (and a repeat an IME posts itself
//    is swallowed).
//  - A key the IME took (VK_PROCESSKEY) is not a game key, and neither is its key up.
// While no TextField has the focus the window has no input context (ImmAssociateContextEx), so the IME leaves the game's
// keys alone. Everything runs on the main thread, where sokol_app dispatches the window's messages and runs the game.
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
// <windows.h> leaves <imm.h> out under WIN32_LEAN_AND_MEAN.
#include <imm.h>

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/log.h"
#include "fa/platform/ime.h"
#include "ime_imm.h"
#include "ime_impl.h"
#include "ime_win32.h"
#include "sokol_app.h"

#if defined(_MSC_VER)
#pragma comment(lib, "imm32.lib")
#endif

namespace imm = fa::ime_imm;

static_assert(static_cast<std::uint32_t>(GCS_COMPSTR) == imm::kGcsCompStr);
static_assert(static_cast<std::uint32_t>(GCS_COMPATTR) == imm::kGcsCompAttr);
static_assert(static_cast<std::uint32_t>(GCS_COMPCLAUSE) == imm::kGcsCompClause);
static_assert(static_cast<std::uint32_t>(GCS_CURSORPOS) == imm::kGcsCursorPos);
static_assert(static_cast<std::uint32_t>(GCS_RESULTSTR) == imm::kGcsResultStr);
static_assert(static_cast<std::uint8_t>(ATTR_INPUT) == imm::kAttrInput);
static_assert(static_cast<std::uint8_t>(ATTR_TARGET_CONVERTED) == imm::kAttrTargetConverted);
static_assert(static_cast<std::uint8_t>(ATTR_CONVERTED) == imm::kAttrConverted);
static_assert(static_cast<std::uint8_t>(ATTR_TARGET_NOTCONVERTED) == imm::kAttrTargetNotConverted);
static_assert(static_cast<unsigned>(VK_PROCESSKEY) == imm::kVkProcessKey);
static_assert(sizeof(wchar_t) == sizeof(char16_t), "ImmGetCompositionStringW writes UTF-16 units");
static_assert(sizeof(DWORD) == sizeof(std::uint32_t), "GCS_COMPCLAUSE is an array of DWORD");

namespace {

HWND g_hwnd = nullptr;       // the hooked window while an Input is attached
HWND g_chainHwnd = nullptr;  // the window whose procedure chain holds ime_wndproc (it stays there when it cannot leave)
WNDPROC g_original = nullptr;  // sokol_app's procedure, which ime_wndproc passes the messages on to
imm::Session g_session;
fa::Rect g_caret;  // framebuffer pixels, as ime_set_caret_rect() gave it
bool g_haveCaret = false;

// A pre-edit string is a few dozen units: a context that claims more than this is not read.
constexpr LONG kMaxBytes = 1 << 20;

// The key code sokol_app reads from a key message (HIWORD(lParam) & 0x1FF: the scan code and its extended bit).
unsigned scan_code(LPARAM lp) { return static_cast<unsigned>(HIWORD(lp)) & 0x1FFu; }

std::u16string read_string(HIMC himc, DWORD which) {
    const LONG bytes = ImmGetCompositionStringW(himc, which, nullptr, 0);
    if (bytes <= 0 || bytes > kMaxBytes) return {};
    std::u16string s(static_cast<std::size_t>(bytes) / sizeof(wchar_t), u'\0');
    if (s.empty()) return s;
    const LONG got = ImmGetCompositionStringW(himc, which, s.data(), static_cast<DWORD>(s.size() * sizeof(wchar_t)));
    if (got <= 0) return {};
    s.resize(std::min(s.size(), static_cast<std::size_t>(got) / sizeof(wchar_t)));
    return s;
}

template <class T>
std::vector<T> read_array(HIMC himc, DWORD which) {
    const LONG bytes = ImmGetCompositionStringW(himc, which, nullptr, 0);
    if (bytes <= 0 || bytes > kMaxBytes) return {};
    std::vector<T> v(static_cast<std::size_t>(bytes) / sizeof(T));
    if (v.empty()) return v;
    const LONG got = ImmGetCompositionStringW(himc, which, v.data(), static_cast<DWORD>(v.size() * sizeof(T)));
    if (got <= 0) return {};
    v.resize(std::min(v.size(), static_cast<std::size_t>(got) / sizeof(T)));
    return v;
}

LONG to_long(float v) {
    if (!std::isfinite(v)) return 0;
    return static_cast<LONG>(std::lround(std::clamp(v, -1.0e7f, 1.0e7f)));
}

// The window's input context: the default one while a TextField has the focus, none otherwise (the IME is off for it).
void associate(bool on) {
    if (g_hwnd) ImmAssociateContextEx(g_hwnd, nullptr, on ? static_cast<DWORD>(IACE_DEFAULT) : static_cast<DWORD>(0));
}

// The candidate window under the caret. The composition window is not shown, but some IMEs place their candidates from
// its position, others from the candidate form (CFS_CANDIDATEPOS, or CFS_EXCLUDE: keep out of the caret's rectangle).
void apply_caret() {
    if (!g_hwnd || !g_session.active() || !g_haveCaret) return;
    // Framebuffer pixels are client pixels unless sokol_app scales the framebuffer (AppDesc::highDpi off).
    float sx = 1.0f, sy = 1.0f;
    RECT client{};
    const int fw = sapp_width(), fh = sapp_height();
    if (GetClientRect(g_hwnd, &client) && fw > 0 && fh > 0 && client.right > 0 && client.bottom > 0) {
        sx = static_cast<float>(client.right) / static_cast<float>(fw);
        sy = static_cast<float>(client.bottom) / static_cast<float>(fh);
    }
    const LONG x = to_long(g_caret.x * sx), y = to_long(g_caret.y * sy);
    const LONG w = std::max<LONG>(1, to_long(g_caret.w * sx)), h = std::max<LONG>(1, to_long(g_caret.h * sy));
    HIMC himc = ImmGetContext(g_hwnd);
    if (!himc) return;
    COMPOSITIONFORM comp{};
    comp.dwStyle = CFS_POINT;
    comp.ptCurrentPos.x = x;
    comp.ptCurrentPos.y = y;
    ImmSetCompositionWindow(himc, &comp);
    CANDIDATEFORM pos{};
    pos.dwIndex = 0;
    pos.dwStyle = CFS_CANDIDATEPOS;
    pos.ptCurrentPos.x = x;
    pos.ptCurrentPos.y = y + h;
    ImmSetCandidateWindow(himc, &pos);
    CANDIDATEFORM exclude{};
    exclude.dwIndex = 0;
    exclude.dwStyle = CFS_EXCLUDE;
    exclude.ptCurrentPos.x = x;
    exclude.ptCurrentPos.y = y + h;
    exclude.rcArea.left = x;
    exclude.rcArea.top = y;
    exclude.rcArea.right = x + w;
    exclude.rcArea.bottom = y + h;
    ImmSetCandidateWindow(himc, &exclude);
    ImmReleaseContext(g_hwnd, himc);
}

// The IME drops its composition (it answers with WM_IME_COMPOSITION / ENDCOMPOSITION, which the session drops).
void cancel_os() {
    if (!g_hwnd) return;
    if (HIMC himc = ImmGetContext(g_hwnd)) {
        ImmNotifyIME(himc, NI_COMPOSITIONSTR, CPS_CANCEL, 0);
        ImmReleaseContext(g_hwnd, himc);
    }
}

void on_composition(HWND hwnd, LPARAM lp) {
    imm::Composition c;
    c.flags = static_cast<std::uint32_t>(lp);
    if (HIMC himc = ImmGetContext(hwnd)) {
        if ((c.flags & imm::kGcsResultStr) != 0) c.result = read_string(himc, GCS_RESULTSTR);
        if (imm::wants_comp(c.flags)) {
            c.comp = read_string(himc, GCS_COMPSTR);
            c.attrs = read_array<std::uint8_t>(himc, GCS_COMPATTR);
            c.clauses = read_array<std::uint32_t>(himc, GCS_COMPCLAUSE);
            if ((c.flags & imm::kGcsCursorPos) != 0)
                c.cursor = ImmGetCompositionStringW(himc, GCS_CURSORPOS, nullptr, 0);
        }
        ImmReleaseContext(hwnd, himc);
    }
    g_session.composition(c);
}

void unhook();

LRESULT CALLBACK ime_wndproc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
    const WNDPROC original = g_original;
    if (hwnd == g_hwnd && g_session.input() != nullptr) {
        switch (msg) {
            case WM_IME_SETCONTEXT:
                lp = static_cast<LPARAM>(static_cast<ULONG_PTR>(lp) &
                                         ~static_cast<ULONG_PTR>(ISC_SHOWUICOMPOSITIONWINDOW));
                break;
            case WM_IME_STARTCOMPOSITION:
                g_session.start();
                apply_caret();
                return 0;
            case WM_IME_COMPOSITION: on_composition(hwnd, lp); return 0;
            case WM_IME_ENDCOMPOSITION: g_session.end(); return 0;
            case WM_IME_CHAR:
            case WM_CHAR:
                if (g_session.take_char(static_cast<char16_t>(wp & 0xFFFFu))) return 0;
                break;
            case WM_KEYDOWN:
            case WM_SYSKEYDOWN:
                if (g_session.key_down(static_cast<unsigned>(wp), scan_code(lp)))
                    return DefWindowProcW(hwnd, msg, wp, lp);
                break;
            case WM_KEYUP:
            case WM_SYSKEYUP:
                if (g_session.key_up(scan_code(lp))) return DefWindowProcW(hwnd, msg, wp, lp);
                break;
            case WM_NCDESTROY:  // the window goes before app.cpp detached: forget it without calling the Input
                g_session.forget();
                g_haveCaret = false;
                unhook();
                break;
            default: break;
        }
    }
    return original ? CallWindowProcW(original, hwnd, msg, wp, lp) : DefWindowProcW(hwnd, msg, wp, lp);
}

bool hook(HWND hwnd) {
    if (g_original && g_chainHwnd == hwnd) {  // still in this window's chain from an earlier attach
        g_hwnd = hwnd;
        return true;
    }
    if (g_original) return false;  // in another window's chain: one window at a time
    SetLastError(0);
    const LONG_PTR old = SetWindowLongPtrW(hwnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(&ime_wndproc));
    if (old == 0) {
        FA_WARN("platform", "IME: cannot hook the window procedure (error {}): text fields do not compose",
                static_cast<unsigned long>(GetLastError()));
        return false;
    }
    g_original = reinterpret_cast<WNDPROC>(old);
    g_chainHwnd = hwnd;
    g_hwnd = hwnd;
    return true;
}

// sokol_app's procedure back, when ime_wndproc is still the window's (another hook on top keeps it in the chain, passing
// every message on).
void unhook() {
    if (g_chainHwnd && IsWindow(g_chainHwnd) &&
        GetWindowLongPtrW(g_chainHwnd, GWLP_WNDPROC) == reinterpret_cast<LONG_PTR>(&ime_wndproc)) {
        SetWindowLongPtrW(g_chainHwnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(g_original));
        g_original = nullptr;
        g_chainHwnd = nullptr;
    } else if (g_chainHwnd && !IsWindow(g_chainHwnd)) {
        g_original = nullptr;
        g_chainHwnd = nullptr;
    }
    g_hwnd = nullptr;
}

void detach() {
    if (!g_hwnd) return;
    g_session.cancel();  // Input's composition ends; what the IME answers to the cancel is dropped
    cancel_os();
    g_session.attach(nullptr);
    g_haveCaret = false;
    associate(true);  // the window's default input context back
    unhook();
}

}  // namespace

namespace fa {

void ime_win32_attach(Input* input) {
    if (!input) {
        detach();
        return;
    }
    HWND hwnd = static_cast<HWND>(const_cast<void*>(sapp_win32_get_hwnd()));
    if (!hwnd) return;
    if (g_hwnd != hwnd) {
        detach();
        if (!hook(hwnd)) return;
    }
    g_session.attach(input);
    const ImeState s = ime_state();
    g_session.set_enabled(s.enabled);
    associate(s.enabled);
    g_caret = s.caretRect;
    g_haveCaret = s.enabled && (s.caretRect.w > 0.0f || s.caretRect.h > 0.0f);
    apply_caret();
}

void ime_backend_set_enabled(bool enabled) {
    if (!g_hwnd) return;  // not attached (tests, the editor's Play mode): nothing to tell the OS
    if (!enabled) {
        const bool open = g_session.os_composing();
        g_session.set_enabled(false);  // Input's composition ends; the rest of the OS's one is dropped
        if (open) cancel_os();
        g_haveCaret = false;
        associate(false);
        return;
    }
    g_session.set_enabled(true);
    associate(true);
    apply_caret();
}

void ime_backend_set_caret_rect(Rect framebufferPixels) {
    if (!g_hwnd) return;
    g_caret = framebufferPixels;
    g_haveCaret = true;
    apply_caret();
}

void ime_backend_cancel() {
    if (!g_hwnd) return;
    g_session.cancel();
    cancel_os();
}

}  // namespace fa
