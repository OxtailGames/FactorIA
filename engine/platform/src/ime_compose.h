// The IME backends of Linux (XIM, ime_linux.cpp) and the web (DOM composition events, ime_web.cpp), without X11 or a
// browser: the pre-edit string XIM draws piece by piece, and the session that turns either platform's events into Input's
// composition events (start, update, commit, end, the keys the input method took, a cancelled composition whose events are
// dropped). Plain data in, Input calls out, so tests/ime_compose_tests.cpp covers it on every host. Private to fa_platform;
// everything runs on the thread of the window (sokol_app's main thread, the browser's main thread).
#pragma once

#include <array>
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

namespace fa::ime_compose {

// What a commit types: the text without control characters (app.cpp drops them from CHAR events too).
std::u32string printable(std::u32string_view text);
// UTF-32 to UTF-16 (a code point that is no character, a surrogate or one past U+10FFFF, becomes U+FFFD).
std::u16string to_utf16(std::u32string_view text);

// XIMFeedback bits and XIMCaretDirection values of <X11/Xlib.h> (ime_linux.cpp checks each one with a static_assert).
inline constexpr unsigned long kXimReverse = 1ul;
inline constexpr unsigned long kXimUnderline = 1ul << 1;
inline constexpr unsigned long kXimHighlight = 1ul << 2;
inline constexpr int kXimForwardChar = 0;
inline constexpr int kXimBackwardChar = 1;
inline constexpr int kXimLineStart = 8;
inline constexpr int kXimLineEnd = 9;
inline constexpr int kXimAbsolutePosition = 10;
inline constexpr int kXimDontChange = 11;

// A pre-edit string is a few dozen characters: a draw that would make it longer than this is cut there.
inline constexpr std::size_t kMaxPreedit = 4096;

// One XIMPreeditDrawCallbackStruct as ime_linux.cpp read it. Counts are characters (code points), as XIM's are.
struct Draw {
    int caret = 0;   // the caret after the draw
    int first = 0;   // chg_first
    int length = 0;  // chg_length: how many characters from `first` the draw replaces
    // What replaces them. Without text (XIMText NULL) they are deleted; with `feedbackOnly` (an XIMText whose string is
    // NULL) they keep their characters and the `feedback.size()` characters from `first` take the new feedback.
    bool hasText = false;
    bool feedbackOnly = false;
    std::u32string chars;
    std::vector<unsigned long> feedback;  // one per character of `chars`; missing ones are 0 (plain)
};

// The pre-edit string of an on-the-spot (XIMPreeditCallbacks) input context: XIM sends what changed, the backend keeps
// the whole string. Ranges and the caret are clamped to the string, so an input method that gets them wrong cannot index
// past it.
class Preedit {
public:
    void clear();
    void draw(const Draw& d);
    // XIMPreeditCaretCallbackStruct: moves the caret (`position` is read for kXimAbsolutePosition only; directions this
    // backend does not know leave it) and returns where it is now, which XIM wants back in the struct.
    int move_caret(int direction, int position);
    const std::u32string& text() const { return text_; }
    int caret() const { return caret_; }
    // The string as Input::on_composition_update takes it: the clause being converted is the first run drawn reversed
    // (XIMReverse: ibus and fcitx mark the converted clause so), else the first highlighted one (XIMHighlight); caret =
    // its start, selLength = its length. Without one the caret is XIM's and selLength 0.
    ime_text::Marked marked() const;

private:
    std::u32string text_;
    std::vector<unsigned long> feedback_;  // one per character of text_
    int caret_ = 0;
};

// How a platform's events differ.
struct Options {
    // Linux: XIM may end a composition (an empty draw, PreeditDone) before it sends the commit (a later event). The end
    // then waits for flush(), which ime_linux.cpp calls before each batch of events, so the field does not show the text
    // vanish for a frame and come back typed.
    bool deferEnds = false;
    // The web: a phone's keyboard composes into the hidden <input> even while the IME is off (a password field), and what
    // it commits there is typed, as before the IME existed. Off: a commit while the IME is off types nothing.
    bool typeWhenOff = false;
};

// The backend's state between events: whether a composition is open in the OS, the keys the input method took (their key
// up is not the game's either) and a cancelled composition whose events are dropped.
class Session {
public:
    explicit Session(Options options = {}) : options_(options) {}

    // Which Input the composition goes to (nullptr: none, nothing is delivered). Changing it cancels the composition the
    // old one had open and forgets the state.
    void attach(Input* target);
    // No Input any more, without calling the old one (the window is being destroyed and it may be gone).
    void forget();
    Input* input() const { return input_; }
    // A text field has the focus. Turning it off ends Input's composition (cancelled) and drops the rest of the OS's one;
    // turning it on ends any dropping (a new field: what the input method says now is about it).
    void set_enabled(bool on);
    bool enabled() const { return enabled_; }
    bool active() const { return input_ != nullptr && enabled_; }
    bool os_composing() const { return osComposing_; }
    bool dropping() const { return dropping_; }
    // A composition is open in the OS or in Input: what the backend must tell the OS to drop on a cancel.
    bool open() const;

    // A composition starts (XIM PreeditStart, DOM compositionstart): a cancelled one's events are no longer dropped.
    void start();
    // The pre-edit string now. An empty one ends Input's composition (cancelled; with deferEnds at the next flush()), the
    // OS's stays open until end().
    void update(ime_text::Marked m);
    // The input method typed `text` (an XIM commit, the data of compositionend): delivered once, as typed text, also with
    // no composition open (an emoji picker, a full-width letter). Control characters are dropped; an empty text commits
    // nothing.
    void commit(std::u32string text);
    // The OS's composition ended (PreeditDone, compositionend after its commit). One still open in Input ends without
    // typing (cancelled; with deferEnds at the next flush()).
    void end();
    // Applies an end deferred by deferEnds: Input's composition ends now unless a commit or an update came since.
    void flush();
    // ime_cancel(): Input's composition ends (cancelled) and, when one was open (in Input or the OS), every event of the
    // OS's one is dropped from now on, until the next start(), key down or set_enabled(true) (an input method that ignores
    // the cancel keeps its text: what it sends after the player types again is about the field that has the focus now).
    // With none open nothing is dropped: every click in a field cancels, and a commit with no composition before it (an
    // emoji picker) still types. The backend tells the OS right after.
    void cancel();
    // The window lost the focus: the keys held now get their key up elsewhere; what the session knew about them is
    // forgotten.
    void focus_lost();

    // A key down (an X keycode, a sokol_app key code on the web; taken modulo kKeys). Code 0 is no key (an X keycode is
    // never 0 here, sokol_app's SAPP_KEYCODE_INVALID is 0: a key the browser names that sokol_app does not know): all of
    // those would share one slot, so they keep no state: the down and the up are swallowed when the input method took
    // them and the IME is on, delivered otherwise. `imeTook`: the input method used it
    // (XFilterEvent returned True; the browser's keyCode 229, or a composition is open). true = swallow: the game does
    // not see it, nor its key up. A key whose down reached the game always gets its up. `time` (X server milliseconds,
    // 0 = none) drops a key down that repeats one already delivered with the same time: some XIM servers send a key back
    // twice. Every key down ends the dropping of a cancelled composition.
    bool key_down(unsigned code, bool imeTook, std::uint32_t time = 0);
    // A key up: true = swallow (its down was swallowed, or the input method used it and its down never reached the game).
    // `time` drops a copy of a key up already delivered, as for key_down (an XIM server that sends back a key up the game
    // already got).
    bool key_up(unsigned code, bool imeTook, std::uint32_t time = 0);

    static constexpr std::size_t kKeys = 512;

private:
    void reset();
    Options options_;
    Input* input_ = nullptr;
    bool enabled_ = false;
    bool osComposing_ = false;
    bool dropping_ = false;
    bool endPending_ = false;  // deferEnds: Input's composition ends at the next flush()
    std::bitset<kKeys> swallowed_, delivered_;
    std::array<std::uint32_t, kKeys> lastDown_{};  // the time of the last key down delivered, per key (0 = none)
    std::array<std::uint32_t, kKeys> lastUp_{};    // the same for key ups
};

}  // namespace fa::ime_compose
