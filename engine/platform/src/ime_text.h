// Text helpers every IME backend shares: the OS counts a composition in UTF-16 units (macOS, iOS, Windows, Android, the web),
// Input in code points. Pure functions, compiled and tested on every host (tests/ime_text_tests.cpp). Private to fa_platform.
#pragma once

#include <cstddef>
#include <span>
#include <string>
#include <string_view>

namespace fa::ime_text {

// UTF-16 to UTF-32. A lone surrogate becomes U+FFFD, one code point per lone unit, so the indices below stay consistent.
std::u32string utf16_to_utf32(std::u16string_view text);

// A range of code points.
struct CpRange {
    int start = 0;
    int length = 0;
};

// The UTF-16 range [loc, loc + len) of `text` as code points. Clamped to the text (a `loc` of NSNotFound or beyond the end
// is the end). A boundary that falls inside a surrogate pair moves outwards: the start to the pair's first code point, the end
// past it. A zero length stays zero.
CpRange utf16_range_to_cp(std::u16string_view text, std::size_t loc, std::size_t len);

// One run of an attributed marked text (macOS: the NSUnderlineStyleAttributeName runs of setMarkedText). `emphasized` is the
// run the IME draws thick: the clause it is converting.
struct Run {
    std::size_t start = 0;
    std::size_t length = 0;
    bool emphasized = false;
};

// A pre-edit string as Input::on_composition_update takes it.
struct Marked {
    std::u32string text;
    int caret = 0;      // code points, 0..size
    int selLength = 0;  // the clause being converted, from `caret`; 0 = none
};

// The marked text with its caret and clause. The clause is the IME's selected range when it has a length, else its first
// emphasized run, else there is none (selLength 0) and the caret is the selected range's start.
Marked marked_from_utf16(std::u16string_view text, std::size_t selLoc, std::size_t selLen, std::span<const Run> runs);

// What a key down becomes once the input method has seen it (macOS: the view called interpretKeyEvents and the client methods
// answered). The flags are what happened during that call.
struct KeyOutcome {
    bool wasComposing = false;  // a composition was open before the key
    bool composing = false;     // and after it
    bool consumed = false;      // the IME changed the composition: marked text set, committed or ended
    bool command = false;       // it asked for a command (Enter, an arrow, Backspace: doCommandBySelector)
    bool plainText = false;     // it inserted text with no composition open (a letter of a plain layout)
    bool plainTextIsEventText = false;  // ... and that text is what the key event itself carries
};
enum class KeyAction {
    Game,             // the game gets the key and its characters, as without an IME
    GameWithoutText,  // the game gets the key only; the inserted text is delivered as text by the backend (full-width letters)
    Swallow,          // the IME used the key (it composes, converts, confirms): the game gets neither key nor text
};
KeyAction decide_key(const KeyOutcome& o);

}  // namespace fa::ime_text
