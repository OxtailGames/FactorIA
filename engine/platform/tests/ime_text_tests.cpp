// The IME helpers every backend shares (src/ime_text.h) and, on macOS, the NSTextInputClient the game's view forwards to
// (src/ime_apple.mm) driven against a real Input.
#include <doctest.h>

#include "../src/ime_text.h"
#include "fa/platform/input.h"

#if defined(__APPLE__)
#include <TargetConditionals.h>
#if !TARGET_OS_IPHONE
#include "../src/ime_apple.h"
#define FA_TEST_APPLE_IME 1
#endif
#endif

using namespace fa;
using namespace fa::ime_text;

TEST_CASE("ime text: UTF-16 to UTF-32") {
    CHECK(utf16_to_utf32(u"abc") == U"abc");
    CHECK(utf16_to_utf32(u"あい") == U"あい");
    CHECK(utf16_to_utf32(u"a\xD83D\xDE00z") == U"a\U0001F600z");        // a surrogate pair is one code point
    CHECK(utf16_to_utf32(u"a\xD83Dz") == U"a�z");                   // a lone high surrogate
    CHECK(utf16_to_utf32(u"a\xDE00z") == U"a�z");                   // a lone low surrogate
    CHECK(utf16_to_utf32(u"").empty());
}

TEST_CASE("ime text: UTF-16 ranges become code point ranges") {
    const std::u16string t = u"a\xD83D\xDE00z\xD83D\xDE01";  // a, U+1F600, z, U+1F601: 6 units, 4 code points
    auto r = utf16_range_to_cp(t, 0, 6);
    CHECK(r.start == 0);
    CHECK(r.length == 4);
    r = utf16_range_to_cp(t, 1, 2);  // exactly the first emoji
    CHECK(r.start == 1);
    CHECK(r.length == 1);
    r = utf16_range_to_cp(t, 3, 3);  // z and the second emoji
    CHECK(r.start == 2);
    CHECK(r.length == 2);
    r = utf16_range_to_cp(t, 2, 1);  // inside a pair: grows to the whole code point
    CHECK(r.start == 1);
    CHECK(r.length == 1);
    r = utf16_range_to_cp(t, 2, 0);  // an empty range inside a pair stays empty, at the pair's start
    CHECK(r.start == 1);
    CHECK(r.length == 0);
    r = utf16_range_to_cp(t, 3, 0);
    CHECK(r.start == 2);
    CHECK(r.length == 0);
    r = utf16_range_to_cp(t, 99, 5);  // beyond the text (and NSNotFound): the end
    CHECK(r.start == 4);
    CHECK(r.length == 0);
    r = utf16_range_to_cp(t, 4, 100);  // a length past the end
    CHECK(r.start == 3);
    CHECK(r.length == 1);
    r = utf16_range_to_cp(t, std::size_t(-1), 1);
    CHECK(r.start == 4);
    CHECK(r.length == 0);
}

TEST_CASE("ime text: the clause of a marked text") {
    // The selected range, when it has a length, is the clause.
    Marked m = marked_from_utf16(u"かんじ", 1, 2, {});
    CHECK(m.text == U"かんじ");
    CHECK(m.caret == 1);
    CHECK(m.selLength == 2);
    // No selection length: the caret is the selection's start.
    m = marked_from_utf16(u"abc", 2, 0, {});
    CHECK(m.caret == 2);
    CHECK(m.selLength == 0);
    // No selection length but a thick run: that run is the clause (the first one).
    const Run runs[] = {{0, 1, false}, {1, 2, true}, {3, 1, true}};
    m = marked_from_utf16(u"abcd", 0, 0, runs);
    CHECK(m.caret == 1);
    CHECK(m.selLength == 2);
    // The selected range wins over the runs.
    m = marked_from_utf16(u"abcd", 3, 1, runs);
    CHECK(m.caret == 3);
    CHECK(m.selLength == 1);
    // Runs that are not emphasized give no clause; a run past the text is ignored.
    const Run plain[] = {{0, 4, false}};
    m = marked_from_utf16(u"abcd", 4, 0, plain);
    CHECK(m.caret == 4);
    CHECK(m.selLength == 0);
    const Run beyond[] = {{9, 2, true}};
    m = marked_from_utf16(u"abcd", 1, 0, beyond);
    CHECK(m.caret == 1);
    CHECK(m.selLength == 0);
    // Indices count code points, not UTF-16 units.
    m = marked_from_utf16(u"\xD83D\xDE00xy", 3, 1, {});
    CHECK(m.caret == 2);
    CHECK(m.selLength == 1);
    // NSNotFound as a location: the caret goes to the end.
    m = marked_from_utf16(u"ab", std::size_t(-1), 0, {});
    CHECK(m.caret == 2);
}

TEST_CASE("ime text: what a key down becomes") {
    KeyOutcome o;
    CHECK(decide_key(o) == KeyAction::Game);  // nothing happened: an Enter, an arrow
    o.plainText = o.plainTextIsEventText = true;
    CHECK(decide_key(o) == KeyAction::Game);  // a letter of a plain layout: sokol_app sends it
    o.plainTextIsEventText = false;
    CHECK(decide_key(o) == KeyAction::GameWithoutText);  // a full-width letter: the IME's text, not the event's
    o = {};
    o.consumed = true;
    o.composing = true;
    CHECK(decide_key(o) == KeyAction::Swallow);  // the IME marked text
    o = {};
    o.wasComposing = true;
    o.consumed = true;
    CHECK(decide_key(o) == KeyAction::Swallow);  // the IME committed: Enter must not also submit the field
    o = {};
    o.wasComposing = true;
    o.composing = true;
    CHECK(decide_key(o) == KeyAction::Swallow);  // the IME used the key without telling the client (Space converts)
    o = {};
    o.wasComposing = true;
    o.composing = false;
    o.command = true;
    CHECK(decide_key(o) == KeyAction::Game);  // the IME did not want it (and it ended nothing)
}

#ifdef FA_TEST_APPLE_IME
namespace {
std::u32string typed(const Input& in) { return in.text_input(); }
}  // namespace

TEST_CASE("macOS IME client: marked text becomes composition updates") {
    Input in;
    ime_apple_test::Client* c = ime_apple_test::create(in, true);
    CHECK_FALSE(ime_apple_test::has_marked(c));
    ime_apple_test::set_marked(c, u"か", 1, 0);
    CHECK(ime_apple_test::has_marked(c));
    CHECK(in.composing());
    CHECK(in.composition_text() == U"か");
    CHECK(in.composition_caret() == 1);
    CHECK(in.composition_selection_length() == 0);
    CHECK(typed(in).empty());  // an update never types

    // A conversion: the IME marks the clause it converts.
    ime_apple_test::set_marked(c, u"漢字だ", 0, 2);
    CHECK(in.composition_text() == U"漢字だ");
    CHECK(in.composition_caret() == 0);
    CHECK(in.composition_selection_length() == 2);

    // Or by the thick underline when the selected range has no length.
    const ime_text::Run runs[] = {{0, 1, false}, {1, 2, true}};
    ime_apple_test::set_marked(c, u"abc", 3, 0, runs);
    CHECK(in.composition_caret() == 1);
    CHECK(in.composition_selection_length() == 2);

    // A surrogate pair counts as one code point.
    ime_apple_test::set_marked(c, u"\xD83D\xDE00x", 2, 1);
    CHECK(in.composition_text() == U"\U0001F600x");
    CHECK(in.composition_caret() == 1);
    CHECK(in.composition_selection_length() == 1);
    ime_apple_test::destroy(c);
}

TEST_CASE("macOS IME client: insertText while composing commits once") {
    Input in;
    ime_apple_test::Client* c = ime_apple_test::create(in, true);
    ime_apple_test::set_marked(c, u"かん", 2, 0);
    ime_apple_test::insert_text(c, u"漢");
    CHECK_FALSE(in.composing());
    CHECK_FALSE(ime_apple_test::has_marked(c));
    CHECK(typed(in) == U"漢");  // once
    // Outside a composition (the emoji picker, dictation) the text is typed, control characters are not.
    ime_apple_test::insert_text(c, u"\xD83D\xDE00\n");
    CHECK(typed(in) == U"漢\U0001F600");
    ime_apple_test::destroy(c);
}

TEST_CASE("macOS IME client: unmarkText and an empty marked text discard the composition") {
    Input in;
    ime_apple_test::Client* c = ime_apple_test::create(in, true);
    ime_apple_test::set_marked(c, u"ab", 2, 0);
    ime_apple_test::unmark(c);
    CHECK_FALSE(in.composing());
    CHECK_FALSE(ime_apple_test::has_marked(c));
    CHECK(typed(in).empty());
    ime_apple_test::set_marked(c, u"a", 1, 0);
    ime_apple_test::set_marked(c, u"", 0, 0);  // the IME took back its last character
    CHECK_FALSE(in.composing());
    CHECK(typed(in).empty());
    ime_apple_test::unmark(c);  // nothing marked: nothing happens
    CHECK(typed(in).empty());
    ime_apple_test::destroy(c);
}

TEST_CASE("macOS IME client: ime_cancel and a disabled IME") {
    Input in;
    ime_apple_test::Client* c = ime_apple_test::create(in, true);
    ime_apple_test::set_marked(c, u"ab", 2, 0);
    ime_apple_test::cancel(c);
    CHECK_FALSE(in.composing());
    CHECK_FALSE(ime_apple_test::has_marked(c));
    CHECK(typed(in).empty());
    ime_apple_test::set_marked(c, u"ab", 2, 0);
    ime_apple_test::set_enabled(c, false);  // no TextField has the focus any more: the composition goes
    CHECK_FALSE(in.composing());
    // Disabled: marked text and text from the system are ignored, the game's keys are sokol_app's.
    ime_apple_test::set_marked(c, u"cd", 2, 0);
    ime_apple_test::insert_text(c, u"x");
    CHECK_FALSE(in.composing());
    CHECK(typed(in).empty());
    ime_apple_test::destroy(c);
}

TEST_CASE("macOS IME client: the candidate window sits under the caret") {
    Input in;
    ime_apple_test::Client* c = ime_apple_test::create(in, true);
    ime_apple_test::set_caret_rect(c, {100, 60, 2, 20});  // framebuffer pixels, y down
    const Rect r = ime_apple_test::first_rect(c);
    // The test view is 400 x 300 points with no window, and the display scale is 1 while sokol_app is not running. AppKit's y
    // goes up: a caret 60 down from the top and 20 high starts 300 - 60 - 20 = 220 up from the bottom.
    CHECK(r.x == doctest::Approx(100));
    CHECK(r.y == doctest::Approx(220));
    CHECK(r.w == doctest::Approx(2));
    CHECK(r.h == doctest::Approx(20));
    ime_apple_test::destroy(c);
}
#endif
