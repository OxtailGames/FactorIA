// The Windows IME backend's decisions, without Windows: what ime_win32.cpp's window procedure does with the IMM32 messages
// (WM_IME_STARTCOMPOSITION / COMPOSITION / ENDCOMPOSITION, WM_IME_CHAR, WM_CHAR, WM_KEYDOWN / UP) once it has read the
// input context. Plain data in, Input calls out, so the tests cover it on every host (tests/ime_imm_tests.cpp). Private to
// fa_platform; everything runs on the thread of the window (sokol_app's main thread).
#pragma once

#include <bitset>
#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

#include "ime_text.h"

namespace fa {
class Input;
}

namespace fa::ime_imm {

// <imm.h> and <winuser.h> values (ime_win32.cpp checks each one against the SDK with a static_assert).
inline constexpr std::uint32_t kGcsCompStr = 0x0008;
inline constexpr std::uint32_t kGcsCompAttr = 0x0010;
inline constexpr std::uint32_t kGcsCompClause = 0x0020;
inline constexpr std::uint32_t kGcsCursorPos = 0x0080;
inline constexpr std::uint32_t kGcsResultStr = 0x0800;
inline constexpr std::uint8_t kAttrInput = 0x00;
inline constexpr std::uint8_t kAttrTargetConverted = 0x01;
inline constexpr std::uint8_t kAttrConverted = 0x02;
inline constexpr std::uint8_t kAttrTargetNotConverted = 0x03;
inline constexpr unsigned kVkProcessKey = 0xE5;  // VK_PROCESSKEY: the IME took the key
inline constexpr std::size_t kScanCodes = 512;   // sokol_app's key code: HIWORD(lParam) & 0x1FF (extended bit included)

// One WM_IME_COMPOSITION as ime_win32.cpp read it from the input context. Strings are UTF-16, as
// ImmGetCompositionStringW gives them (its byte counts divided by sizeof(wchar_t)).
struct Composition {
    std::uint32_t flags = 0;  // the message's lParam: which parts changed (GCS_*)
    std::u16string result;    // GCS_RESULTSTR, read when `flags` has it
    std::u16string comp;      // GCS_COMPSTR, read when wants_comp(flags)
    // GCS_COMPATTR, one per UTF-16 unit of `comp` (ATTR_*). Another size counts as not given.
    std::vector<std::uint8_t> attrs;
    // GCS_COMPCLAUSE: the UTF-16 offsets where the clauses start, then comp's size. Anything not rising from 0 to that size
    // counts as not given.
    std::vector<std::uint32_t> clauses;
    long cursor = -1;  // GCS_CURSORPOS in UTF-16 units, when `flags` has it; < 0 = not given (the end of `comp`)
};

// Whether a message with these flags says something about the pre-edit string, so ime_win32.cpp reads GCS_COMPSTR (and its
// attributes and clauses): every message but one that carries only a result. A message with neither GCS_COMPSTR nor
// GCS_RESULTSTR (an IME that cleared the string sends lParam 0; another that moved the caret sends GCS_CURSORPOS alone) is
// answered from what the context holds now.
bool wants_comp(std::uint32_t flags);

// The pre-edit string as Input::on_composition_update takes it: code points; the clause being converted is the first run of
// ATTR_TARGET_CONVERTED / ATTR_TARGET_NOTCONVERTED attributes, cut at the end of the GCS_COMPCLAUSE clause it starts in
// (caret = its start, selLength = its length). Without one the caret is GCS_CURSORPOS (the end when not given) and
// selLength 0. A boundary inside a surrogate pair moves outwards (ime_text::utf16_range_to_cp).
ime_text::Marked marked(const Composition& c);

// The typed text of a result: UTF-32 without control characters (what app.cpp's CHAR events drop too).
std::u32string result_text(std::u16string_view result);

// The backend's state between messages: whether a composition is open in the OS, the text a commit delivered (Windows may
// send it again as WM_IME_CHAR / WM_CHAR: swallowed), the keys the IME took (their key up is not the game's either), and a
// cancelled composition whose messages are dropped.
class Session {
public:
    // Which Input the composition goes to (nullptr: none, nothing is delivered). Changing it cancels the composition the
    // old one had open and forgets the state.
    void attach(Input* target);
    // No Input any more, without calling the old one (the window is being destroyed and it may be gone).
    void forget();
    Input* input() const { return input_; }
    // A text field has the focus. Turning it off ends Input's composition (cancelled) and drops the rest of the OS's one;
    // turning it on ends any dropping (a new field: what the IME says now is about it).
    void set_enabled(bool on);
    bool enabled() const { return enabled_; }
    bool active() const { return input_ != nullptr && enabled_; }
    bool os_composing() const { return osComposing_; }
    bool dropping() const { return dropping_; }

    // WM_IME_STARTCOMPOSITION. A new composition: a cancelled one's messages are no longer dropped.
    void start();
    // WM_IME_COMPOSITION: the result first (Windows sends GCS_RESULTSTR | GCS_COMPSTR together when one composition ends
    // and the next begins: Korean), then the pre-edit string. An empty pre-edit string ends the composition (cancelled).
    // An empty result (the context could not be read) commits nothing: the composition stays as it was.
    void composition(const Composition& c);
    // WM_IME_ENDCOMPOSITION. A composition still open in Input ends without typing (cancelled).
    void end();
    // ime_cancel(): Input's composition ends (cancelled) and, when one was open (in Input or the OS), every message of the
    // OS's one is dropped from now on, until the next WM_IME_STARTCOMPOSITION, key down or set_enabled(true) (an IME that
    // ignores the cancel keeps its text: what it sends after the player types again is about the field that has the focus
    // now). With none open nothing is dropped: every click in a field cancels, and a result that comes with no key before
    // it (the IME pad, the touch keyboard) still types. ime_win32.cpp tells the IME right after.
    void cancel();
    // WM_KILLFOCUS: the keys held now get their key up elsewhere; what the session knew about them is forgotten.
    void focus_lost();

    // WM_CHAR and WM_IME_CHAR, one UTF-16 unit each: true = swallow, the unit repeats (in order) the result a commit already
    // delivered. A unit that does not match ends the repeat: it and the rest are typed as usual.
    bool take_char(char16_t unit);
    // WM_KEYDOWN / WM_SYSKEYDOWN: true = swallow, the IME took the key (VK_PROCESSKEY while active); its key up is
    // swallowed too. A key whose down reached the game always gets its up.
    bool key_down(unsigned vk, unsigned scanCode);
    // WM_KEYUP / WM_SYSKEYUP: true = swallow.
    bool key_up(unsigned scanCode);

private:
    void reset();
    Input* input_ = nullptr;
    bool enabled_ = false;
    bool osComposing_ = false;
    bool dropping_ = false;
    std::u16string echo_;  // the last result's units still expected as WM_IME_CHAR / WM_CHAR
    std::size_t echoPos_ = 0;
    std::bitset<kScanCodes> swallowed_, delivered_;
};

}  // namespace fa::ime_imm
