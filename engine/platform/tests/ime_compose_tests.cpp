// The Linux (XIM) and web (DOM composition events) IME backends' decisions (src/ime_compose.h), driven like
// ime_linux.cpp and ime_web.cpp drive them, against a real Input. Compiled and run on every host: the X11 and browser glue
// only builds there.
#include <doctest.h>

#include <string>
#include <vector>

#include "../src/ime_compose.h"
#include "fa/platform/input.h"

using namespace fa;
using namespace fa::ime_compose;

namespace {
Draw insert(int first, int length, std::u32string chars, int caret, std::vector<unsigned long> feedback = {}) {
    Draw d;
    d.first = first;
    d.length = length;
    d.caret = caret;
    d.hasText = true;
    d.chars = std::move(chars);
    d.feedback = std::move(feedback);
    return d;
}

Draw erase(int first, int length, int caret) {
    Draw d;
    d.first = first;
    d.length = length;
    d.caret = caret;
    return d;
}

ime_text::Marked marked(std::u32string text, int caret = -1, int sel = 0) {
    ime_text::Marked m;
    m.caret = caret < 0 ? static_cast<int>(text.size()) : caret;
    m.text = std::move(text);
    m.selLength = sel;
    return m;
}
}  // namespace

TEST_CASE("IME compose: printable drops control characters, to_utf16 makes surrogate pairs") {
    CHECK(printable(U"a\nb\tc\x7f"
                    U"d") == U"abcd");
    CHECK(printable(U"\r").empty());
    CHECK(printable(U"日本😀") == U"日本😀");
    CHECK(to_utf16(U"aé") == u"aé");
    CHECK(to_utf16(U"😀") == u"\xD83D\xDE00");
    const std::u32string bad{static_cast<char32_t>(0xD800), static_cast<char32_t>(0x110000)};
    CHECK(to_utf16(bad) == u"\xFFFD\xFFFD");
}

TEST_CASE("IME compose: an XIM pre-edit string is drawn piece by piece") {
    Preedit p;
    p.draw(insert(0, 0, U"に", 1));
    CHECK(p.text() == U"に");
    p.draw(insert(1, 0, U"ほ", 2));
    CHECK(p.text() == U"にほ");
    CHECK(p.caret() == 2);

    SUBCASE("a draw replaces a range") {
        p.draw(insert(0, 2, U"日本", 2, {kXimReverse, kXimReverse}));
        CHECK(p.text() == U"日本");
        const auto m = p.marked();
        CHECK(m.text == U"日本");
        CHECK(m.caret == 0);
        CHECK(m.selLength == 2);
    }
    SUBCASE("a draw without text deletes") {
        p.draw(erase(1, 1, 1));
        CHECK(p.text() == U"に");
        CHECK(p.caret() == 1);
        p.draw(erase(0, 1, 0));
        CHECK(p.text().empty());
    }
    SUBCASE("a feedback-only draw keeps the characters") {
        Draw d;
        d.first = 1;
        d.length = 1;
        d.caret = 2;
        d.hasText = true;
        d.feedbackOnly = true;
        d.feedback = {kXimHighlight};
        p.draw(d);
        CHECK(p.text() == U"にほ");
        const auto m = p.marked();
        CHECK(m.caret == 1);
        CHECK(m.selLength == 1);
    }
    SUBCASE("reverse wins over highlight; without either the caret is XIM's") {
        p.draw(insert(0, 2, U"日本語", 3, {kXimHighlight, kXimUnderline, kXimReverse | kXimUnderline}));
        auto m = p.marked();
        CHECK(m.caret == 2);
        CHECK(m.selLength == 1);
        p.draw(insert(0, 3, U"日本語", 1, {kXimUnderline, kXimUnderline, kXimUnderline}));
        m = p.marked();
        CHECK(m.caret == 1);
        CHECK(m.selLength == 0);
    }
    SUBCASE("ranges and the caret an input method gets wrong are clamped") {
        p.draw(insert(10, 99, U"x", 50));
        CHECK(p.text() == U"にほx");
        CHECK(p.caret() == 3);
        p.draw(erase(-4, 1, -1));  // from 0
        CHECK(p.text() == U"ほx");
        CHECK(p.caret() == 0);
        Draw d;
        d.first = 1;
        d.hasText = true;
        d.feedbackOnly = true;
        d.feedback = {kXimReverse, kXimReverse, kXimReverse, kXimReverse};  // more than the string has
        p.draw(d);
        CHECK(p.marked().selLength == 1);
    }
    SUBCASE("a string longer than kMaxPreedit is cut") {
        p.draw(insert(0, 0, std::u32string(kMaxPreedit + 10, U'a'), 0));
        CHECK(p.text().size() == kMaxPreedit);
    }
    SUBCASE("caret moves") {
        CHECK(p.move_caret(kXimBackwardChar, 0) == 1);
        CHECK(p.move_caret(kXimBackwardChar, 0) == 0);
        CHECK(p.move_caret(kXimBackwardChar, 0) == 0);
        CHECK(p.move_caret(kXimLineEnd, 0) == 2);
        CHECK(p.move_caret(kXimForwardChar, 0) == 2);
        CHECK(p.move_caret(kXimLineStart, 0) == 0);
        CHECK(p.move_caret(kXimAbsolutePosition, 1) == 1);
        CHECK(p.move_caret(kXimAbsolutePosition, 99) == 2);
        CHECK(p.move_caret(kXimDontChange, 0) == 2);
        CHECK(p.move_caret(12345, 0) == 2);
    }
    p.clear();
    CHECK(p.text().empty());
    CHECK(p.caret() == 0);
}

TEST_CASE("IME compose: a composition is shown while it is built and typed once") {
    Input in;
    Session s;
    s.attach(&in);
    s.set_enabled(true);
    s.start();
    s.update(marked(U"にほ"));
    CHECK(in.composing());
    CHECK(in.composition_text() == U"にほ");
    CHECK(in.text_input().empty());
    s.update(marked(U"日本", 0, 2));
    CHECK(in.composition_selection_length() == 2);
    s.commit(U"日本");
    s.end();
    CHECK_FALSE(in.composing());
    CHECK(in.text_input() == U"日本");
    s.commit(U"");  // an empty commit types nothing
    CHECK(in.text_input() == U"日本");
}

TEST_CASE("IME compose: an end before the commit does not type, the next start is normal") {
    Input in;
    Session s;
    s.attach(&in);
    s.set_enabled(true);
    s.start();
    s.update(marked(U"a"));
    s.update(marked(U""));  // the player deleted it all
    CHECK_FALSE(in.composing());
    s.update(marked(U"b"));
    CHECK(in.composing());
    s.end();
    CHECK_FALSE(in.composing());
    CHECK(in.text_input().empty());
}

TEST_CASE("IME compose: with deferEnds an end waits for flush and a commit replaces it") {
    Input in;
    Session s({.deferEnds = true});
    s.attach(&in);
    s.set_enabled(true);
    s.start();
    s.update(marked(U"日本"));
    s.update(marked(U""));  // XIM clears the pre-edit string...
    s.end();                // ...ends it...
    CHECK(in.composing());  // ...the field still shows it
    s.commit(U"日本");      // ...and commits in the next event
    CHECK_FALSE(in.composing());
    CHECK(in.text_input() == U"日本");
    s.flush();
    CHECK(in.text_input() == U"日本");

    in.begin_frame();
    s.start();
    s.update(marked(U"x"));
    s.end();
    CHECK(in.composing());
    s.flush();  // no commit came: it ends without typing
    CHECK_FALSE(in.composing());
    CHECK(in.text_input().empty());

    s.start();
    s.update(marked(U"y"));
    s.update(marked(U""));
    s.update(marked(U"yz"));  // a new update cancels the pending end
    s.flush();
    CHECK(in.composing());
    CHECK(in.composition_text() == U"yz");
}

TEST_CASE("IME compose: after a cancel, what the OS still says about the composition is dropped") {
    Input in;
    Session s;
    s.attach(&in);
    s.set_enabled(true);
    s.start();
    s.update(marked(U"にほ"));
    // The UI commits it itself (a click elsewhere), then ime_cancel.
    in.on_composition_cancel();
    s.cancel();
    CHECK(s.dropping());
    s.update(marked(U"にほん"));
    s.commit(U"にほん");
    s.end();
    CHECK_FALSE(in.composing());
    CHECK(in.text_input().empty());

    SUBCASE("a later start composes normally") {
        s.start();
        s.update(marked(U"か"));
        CHECK(in.composing());
        s.commit(U"か");
        CHECK(in.text_input() == U"か");
    }
    SUBCASE("a key down ends the dropping") {
        CHECK_FALSE(s.key_down(38, false));
        CHECK_FALSE(s.dropping());
        s.commit(U"é");
        CHECK(in.text_input() == U"é");
    }
    SUBCASE("a new field ends the dropping") {
        s.set_enabled(false);
        s.set_enabled(true);
        s.commit(U"x");
        CHECK(in.text_input() == U"x");
    }
}

TEST_CASE("IME compose: a cancel with nothing open drops nothing") {
    Input in;
    Session s;
    s.attach(&in);
    s.set_enabled(true);
    s.cancel();  // every click in a field cancels
    CHECK_FALSE(s.dropping());
    s.commit(U"😀");  // an emoji picker commits without a composition
    CHECK(in.text_input() == U"😀");
    CHECK_FALSE(in.composing());
}

TEST_CASE("IME compose: turning the IME off mid-composition ends it and drops the rest") {
    Input in;
    Session s;
    s.attach(&in);
    s.set_enabled(true);
    s.start();
    s.update(marked(U"に"));
    s.set_enabled(false);  // a password field takes the focus
    CHECK_FALSE(in.composing());
    s.update(marked(U"にほ"));
    s.commit(U"に");
    CHECK_FALSE(in.composing());
    CHECK(in.text_input().empty());
    CHECK_FALSE(s.active());
}

TEST_CASE("IME compose: a commit while the IME is off types only with typeWhenOff") {
    Input in;
    Session off;
    off.attach(&in);
    off.commit(U"a");
    CHECK(in.text_input().empty());
    off.update(marked(U"b"));
    CHECK_FALSE(in.composing());

    Session web({.typeWhenOff = true});
    web.attach(&in);
    web.update(marked(U"b"));  // a phone keyboard composing into a password field: not shown...
    CHECK_FALSE(in.composing());
    web.commit(U"bc");  // ...but typed
    CHECK(in.text_input() == U"bc");
}

TEST_CASE("IME compose: keys the input method took are swallowed with their key up") {
    Input in;
    Session s;
    s.attach(&in);
    constexpr unsigned kA = 38, kShift = 50;

    SUBCASE("while the IME is off every key reaches the game") {
        CHECK_FALSE(s.key_down(kA, true));
        CHECK_FALSE(s.key_up(kA, true));
    }
    s.set_enabled(true);
    SUBCASE("a key the input method took") {
        CHECK(s.key_down(kA, true));
        CHECK(s.key_up(kA, false));  // its up too, even when the input method lets it through
    }
    SUBCASE("a key the game got keeps its up") {
        CHECK_FALSE(s.key_down(kShift, false));
        CHECK_FALSE(s.key_up(kShift, true));
        CHECK_FALSE(s.key_down(kShift, false));
        CHECK(s.key_down(kShift, true));  // auto-repeat taken by the input method: its up stays the game's
        CHECK_FALSE(s.key_up(kShift, true));
    }
    SUBCASE("a key up the input method took with no down seen") {
        CHECK(s.key_up(kA, true));
        CHECK_FALSE(s.key_up(kA, false));
    }
    SUBCASE("an XIM server that sends a key back twice") {
        CHECK_FALSE(s.key_down(kA, false, 1000));
        CHECK(s.key_down(kA, false, 1000));  // the same time: a copy
        CHECK_FALSE(s.key_down(kA, false, 1016));
        CHECK_FALSE(s.key_down(kA, false, 0));         // no time: never a copy
        CHECK_FALSE(s.key_down(kShift, false, 1016));  // another key with the same time
        CHECK_FALSE(s.key_up(kA, true, 1100));  // the input method looked at it: the game got the down, so the up
        CHECK(s.key_up(kA, false, 1100));       // ...and the copy it sends back is dropped
        CHECK_FALSE(s.key_up(kA, false, 1200));
    }
    SUBCASE("time wraps around") {
        CHECK_FALSE(s.key_down(kA, false, 0xFFFFFFF0u));
        CHECK_FALSE(s.key_down(kA, false, 0x10u));
    }
    SUBCASE("losing the focus forgets held keys") {
        CHECK(s.key_down(kA, true));
        s.focus_lost();
        CHECK_FALSE(s.key_up(kA, false));
    }
}

TEST_CASE("IME compose: attach and forget") {
    Input a, b;
    Session s;
    s.attach(&a);
    s.set_enabled(true);
    s.start();
    s.update(marked(U"x"));
    s.attach(&b);  // another Input: the old one's composition ends
    CHECK_FALSE(a.composing());
    CHECK_FALSE(s.enabled());
    s.set_enabled(true);
    s.update(marked(U"y"));
    CHECK(b.composing());
    s.forget();
    CHECK(s.input() == nullptr);
    s.commit(U"z");
    CHECK(b.text_input().empty());
    s.attach(nullptr);
    s.cancel();
    CHECK_FALSE(s.dropping());
}
