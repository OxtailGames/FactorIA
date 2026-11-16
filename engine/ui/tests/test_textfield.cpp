// TextField editing: the pure model (text_edit.h) and the UiSystem wiring (keys, clipboard, pointer, IME composition, caret
// rectangle).
#include <doctest.h>

#include <memory>
#include <string>

#include "../src/text_edit.h"
#include "fa/platform/ime.h"
#include "fa/scene/text_field_view.h"
#include "fa/ui/ui.h"

using namespace fa;

#include "ui_fixture.h"

namespace {
using fa_ui_test::Ui;
using fa_ui_test::V;
namespace te = fa::text_edit;

te::State st(const char* text, int caret, int anchor = -1) {
    return te::State{text, caret, anchor < 0 ? caret : anchor};
}

constexpr const char* kEAcute = "\xC3\xA9";  // U+00E9
constexpr const char* kEComb = "e\xCC\x81";  // e + U+0301: two code points, one character
constexpr const char* kFamily = "\xF0\x9F\x91\xA8\xE2\x80\x8D\xF0\x9F\x91\xA9";  // man ZWJ woman
constexpr const char* kFlagEs = "\xF0\x9F\x87\xAA\xF0\x9F\x87\xB8";              // two regional indicators

// The key that makes arrows and Backspace work by word: Alt on macOS, Ctrl elsewhere (Input::word_modifier_down).
#ifdef __APPLE__
constexpr Key kWord = Key::LeftAlt;
#else
constexpr Key kWord = Key::LeftControl;
#endif

struct ImeGuard {
    ImeGuard() { ime_reset_state(); }
    ~ImeGuard() { ime_reset_state(); }
};

// Presses and releases a key with the given modifier keys held.
void tap(Ui& t, Key k, std::initializer_list<Key> mods = {}) {
    for (Key m : mods) t.in.on_key(m, true);
    t.in.on_key(k, true);
    t.frame();
    t.in.on_key(k, false);
    for (Key m : mods) t.in.on_key(m, false);
    t.frame();
}
void type(Ui& t, const std::u32string& s) {
    for (char32_t c : s) t.in.on_text(c);
    t.frame();
}

struct Field {
    Ui t;
    Entity e;
    TextField* f;
    explicit Field(const char* text = "", Vec2 size = {200, 30}) {
        e = t.add<TextField>("f", {0, 0}, size);
        f = t.w.get<TextField>(e);
        f->autoFocus = true;
        f->maxLength = 0;
        f->text = text;
        t.frame();  // takes the focus: the caret is at the end
        t.events();
    }
};
}  // namespace

// ----------------------------------------------------------------------------------------------- the pure model --
TEST_CASE("text_edit insert: at the caret, over a selection, UTF-8, maxLength in code points, newlines dropped") {
    te::Options o;
    te::State s = st("held", 2);
    CHECK(te::insert(s, "XY", o));
    CHECK(s.text == "heXYld");
    CHECK(s.caret == 4);
    CHECK(s.anchor == 4);
    s = st("hello", 3, 1);  // the selection "el" l...: anchor 1, caret 3 selects "el"
    CHECK(te::insert(s, kEAcute, o));
    CHECK(s.text == std::string("h") + kEAcute + "lo");
    CHECK(s.caret == 2);
    s = st("abcd", 4, 0);  // backwards selection of everything
    CHECK(te::insert(s, "z", o));
    CHECK(s.text == "z");
    // maxLength counts code points and the selection makes room
    o.maxLength = 4;
    s = st("abcd", 4);
    CHECK_FALSE(te::insert(s, "e", o));
    CHECK(s.text == "abcd");
    s = st("abcd", 1, 3);
    CHECK(te::insert(s, "XYZW", o));
    CHECK(s.text == "aXYd");  // 2 removed, 2 fit
    s = st("ab", 2);
    CHECK(te::insert(s, "cdef", o));
    CHECK(s.text == "abcd");
    // single line: newlines, tabs and control characters are dropped, nothing left = no change (and a selection stays)
    o.maxLength = 0;
    s = st("a", 1, 0);
    CHECK_FALSE(te::insert(s, "\r\n\t\x01", o));
    CHECK(s.text == "a");
    CHECK(s.anchor == 0);
    s = st("", 0);
    CHECK(te::insert(s, "x\ny\r\nz\tw", o));
    CHECK(s.text == "xyzw");
    CHECK(te::sanitize("a\nb", false) == "a\nb");
    CHECK(te::sanitize("a\r\nb\tc", false) == "a\n\nbc");
}

TEST_CASE("text_edit backspace and delete: a character, a selection, a word, a whole cluster") {
    te::State s = st("hello world", 11);
    CHECK(te::backspace(s, false));
    CHECK(s.text == "hello worl");
    CHECK(te::backspace(s, true));  // the word before the caret
    CHECK(s.text == "hello ");
    CHECK(s.caret == 6);
    CHECK(te::backspace(s, true));  // the space and the word before it
    CHECK(s.text == "");
    CHECK_FALSE(te::backspace(s, false));
    s = st("hello world", 0);
    CHECK_FALSE(te::backspace(s, false));
    CHECK(te::del(s, false));
    CHECK(s.text == "ello world");
    CHECK(te::del(s, true));  // to the end of the word
    CHECK(s.text == " world");
    CHECK(te::del(s, true));  // the space and the next word
    CHECK(s.text == "");
    CHECK_FALSE(te::del(s, false));
    // a selection goes whole, either direction, whatever the key
    s = st("abcdef", 4, 1);
    CHECK(te::backspace(s, true));
    CHECK(s.text == "aef");
    CHECK(s.caret == 1);
    s = st("abcdef", 1, 4);
    CHECK(te::del(s, false));
    CHECK(s.text == "aef");
    CHECK(s.caret == 1);
    // punctuation is a word of its own
    s = st("a, b", 4);
    CHECK(te::backspace(s, true));
    CHECK(s.text == "a, ");
    // clusters
    s = st((std::string("a") + kEComb + "b").c_str(), 4);
    CHECK(te::backspace(s, false));  // b
    CHECK(te::backspace(s, false));  // e + the accent
    CHECK(s.text == "a");
    s = st((std::string("a") + kEComb + "b").c_str(), 1);
    CHECK(te::del(s, false));
    CHECK(s.text == "ab");
    s = st((std::string("x") + kFamily + kFlagEs).c_str(), 6);
    CHECK(te::backspace(s, false));  // the flag is two indicators
    CHECK(s.text == std::string("x") + kFamily);
    CHECK(te::backspace(s, false));  // man ZWJ woman: one
    CHECK(s.text == "x");
}

TEST_CASE("text_edit movement: arrows, words, Home / End, extending, collapsing, select all and word") {
    te::State s = st("one two  three", 14);
    te::move_left(s, true, false);
    CHECK(s.caret == 9);
    te::move_left(s, true, false);
    CHECK(s.caret == 4);
    te::move_left(s, true, false);
    CHECK(s.caret == 0);
    te::move_left(s, false, false);
    CHECK(s.caret == 0);
    te::move_right(s, true, false);
    CHECK(s.caret == 3);
    te::move_right(s, true, false);
    CHECK(s.caret == 7);
    te::move_right(s, false, true);  // Shift+Right: the anchor stays
    CHECK(s.caret == 8);
    CHECK(s.anchor == 7);
    CHECK(te::selected_text(s) == " ");
    te::move_left(s, false, false);  // with a selection and no Shift: to the left end of it
    CHECK(s.caret == 7);
    CHECK(s.anchor == 7);
    te::move_home(s, true);
    CHECK(s.caret == 0);
    CHECK(s.anchor == 7);
    CHECK(te::selected_text(s) == "one two");
    te::move_right(s, false, false);  // to the right end of the selection
    CHECK(s.caret == 7);
    CHECK(s.anchor == 7);
    te::move_end(s, false);
    CHECK(s.caret == 14);
    CHECK(s.anchor == 14);
    te::select_all(s);
    CHECK(s.anchor == 0);
    CHECK(s.caret == 14);
    te::select_word_at(s, 5);
    CHECK(te::selected_text(s) == "two");
    te::select_word_at(s, 7);  // on the spaces: the spaces
    CHECK(te::selected_text(s) == "  ");
    te::select_word_at(s, 14);  // at the end: the last word
    CHECK(te::selected_text(s) == "three");
    te::set_caret(s, 2, false);
    CHECK(s.caret == 2);
    CHECK(s.anchor == 2);
    te::set_caret(s, 6, true);
    CHECK(s.anchor == 2);
    CHECK(te::selected_text(s) == "e tw");
}

TEST_CASE("text_edit: UTF-8 multi-byte text, clusters never split, indices are clamped and snapped") {
    const std::string text = std::string("h") + kEAcute + kEComb + "z";  // h, é, e + accent, z: 5 code points
    te::State s = st(text.c_str(), 5);
    CHECK(te::length(s) == 5);
    te::move_left(s, false, false);  // before z
    CHECK(s.caret == 4);
    te::move_left(s, false, false);  // before "e + accent": two code points at once
    CHECK(s.caret == 2);
    te::move_left(s, false, false);
    CHECK(s.caret == 1);
    te::move_right(s, false, false);
    te::move_right(s, false, false);
    CHECK(s.caret == 4);
    CHECK(te::snap_to_boundary(text, 3) == 2);  // inside the cluster
    CHECK(te::snap_to_boundary(text, 99) == 5);
    CHECK(te::snap_to_boundary(text, -4) == 0);
    s = st(text.c_str(), 3, 99);
    te::normalize(s);
    CHECK(s.caret == 2);
    CHECK(s.anchor == 5);
    CHECK(te::selected_text(s) == std::string(kEComb) + "z");
    // an ill-formed byte is one U+FFFD and does not break the model
    const char kBadBytes[] = "a\xFF"
                             "b";  // two literals: "a\xFFb" would read the b as part of the escape
    te::State bad = st(kBadBytes, 3);
    CHECK(te::length(bad) == 3);
    CHECK(te::backspace(bad, false));
    CHECK(te::length(bad) == 2);
    // an emoji with a skin tone and a variation selector are one character
    te::State e = st("\xF0\x9F\x91\x8D\xF0\x9F\x8F\xBD\xE2\x9D\xA4\xEF\xB8\x8F", 4);  // thumbs up + tone, heart + VS16
    te::move_left(e, false, false);
    CHECK(e.caret == 2);
    te::move_left(e, false, false);
    CHECK(e.caret == 0);
}

TEST_CASE("text_edit cut and copy of the selection") {
    te::State s = st("abcdef", 4, 2);
    CHECK(te::selected_text(s) == "cd");
    CHECK(te::cut(s) == "cd");
    CHECK(s.text == "abef");
    CHECK(s.caret == 2);
    CHECK(te::cut(s).empty());  // nothing selected: nothing cut
    CHECK(s.text == "abef");
    CHECK(te::selected_text(s).empty());
}

TEST_CASE("text_field_view: caret, selection and click positions follow the text, a narrow field scrolls") {
    TextField tf;
    tf.focused = true;
    tf.text = "abcdefghij";
    const TextFieldMeasure m = [](const std::string& s) { return Vec2{float(utf8_length(s)) * 10.0f, 20.0f}; };
    const Rect r{0, 0, 74, 30};  // inner width 50: five characters
    tf.caretIndex = 0;
    TextFieldView v = text_field_view(tf, r, m);
    CHECK(v.inner.x == doctest::Approx(12));
    CHECK(v.scroll == doctest::Approx(0));
    CHECK(v.caretX == doctest::Approx(12));
    CHECK(v.lineH == doctest::Approx(20));
    CHECK(v.lineY == doctest::Approx(5));
    tf.caretIndex = 10;  // at the end of a text wider than the field: the end shows
    v = text_field_view(tf, r, m);
    CHECK(v.scroll == doctest::Approx(52));  // 100 + caret width 2 - 50
    CHECK(v.caretX == doctest::Approx(12 + 100 - 52));
    tf.scrollX = v.scroll;
    tf.caretIndex = 7;  // moving the caret left keeps the scroll until it would leave the field
    v = text_field_view(tf, r, m);
    CHECK(v.scroll == doctest::Approx(52));
    CHECK(v.caretX == doctest::Approx(12 + 70 - 52));
    tf.caretIndex = 3;
    v = text_field_view(tf, r, m);
    CHECK(v.scroll == doctest::Approx(30));
    CHECK(v.caretX == doctest::Approx(12));
    tf.selectionStart = 2;
    tf.selectionEnd = 5;
    v = text_field_view(tf, r, m);
    CHECK(v.hasSelection);
    CHECK(v.selX1 - v.selX0 == doctest::Approx(30));
    // password: every character is a mask
    tf.password = true;
    tf.scrollX = 0;
    v = text_field_view(tf, r, m);
    CHECK(v.display == "**********");
    // click positions: the nearest edge
    tf.password = false;
    CHECK(text_field_index_at(tf, r, m, 12 + 14) == 1);
    CHECK(text_field_index_at(tf, r, m, 12 + 16) == 2);
    CHECK(text_field_index_at(tf, r, m, -50) == 0);
    CHECK(text_field_index_at(tf, r, m, 5000) == 10);
}

// ------------------------------------------------------------------------------------------------ through UiSystem --
TEST_CASE("ui textfield editing: typing goes in at the caret, arrows move it, focus puts it at the end") {
    Field F("hello");
    TextField& f = *F.f;
    CHECK(f.caretIndex == 5);
    CHECK(f.selectionStart == 5);
    CHECK(f.selectionEnd == 5);
    tap(F.t, Key::Left);
    tap(F.t, Key::Left);
    CHECK(f.caretIndex == 3);
    type(F.t, U"XY");
    CHECK(f.text == "helXYlo");
    CHECK(f.caretIndex == 5);
    CHECK(F.t.events() == V{"ui.change:f=\"helXYlo\""});
    tap(F.t, Key::Home);
    CHECK(f.caretIndex == 0);
    type(F.t, U"é");
    CHECK(f.text == "\xC3\xA9helXYlo");
    tap(F.t, Key::End);
    CHECK(f.caretIndex == 8);
    tap(F.t, Key::Backspace);
    CHECK(f.text == "\xC3\xA9helXYl");
    tap(F.t, Key::Left, {});
    tap(F.t, Key::Delete);
    CHECK(f.text == "\xC3\xA9helXY");
    tap(F.t, Key::Left, {});
    tap(F.t, Key::Backspace, {kWord});  // a word
    CHECK(f.text == "Y");
    // Up and Down still move the focus, not the caret
    CHECK(F.t.ui.focused() == F.e);
}

TEST_CASE("ui textfield editing: Backspace and the arrows repeat while held") {
    Field F("abcdefgh");
    F.t.in.on_key(Key::Backspace, true);
    F.t.frame();
    CHECK(F.f->text == "abcdefg");
    F.t.frame(10);  // 0.15 s: below the repeat delay
    CHECK(F.f->text == "abcdefg");
    F.t.frame(40);  // past the delay: it repeats
    CHECK(F.f->text.size() < 6);
    F.t.in.on_key(Key::Backspace, false);
    F.t.frame();
    F.f->text = "abcdefgh";
    F.t.frame();
    F.t.in.on_key(Key::Left, true);
    F.t.frame(60);
    CHECK(F.f->caretIndex < 6);
    CHECK(F.f->caretIndex >= 0);
    F.t.in.on_key(Key::Left, false);
    F.t.frame();
}

TEST_CASE("ui textfield editing: Shift+arrows select, typing replaces, Ctrl+A selects all, both directions") {
    Field F("hello world");
    TextField& f = *F.f;
    tap(F.t, Key::Left, {Key::LeftShift});
    tap(F.t, Key::Left, {Key::LeftShift});
    CHECK(f.selectionStart == 11);  // the anchor
    CHECK(f.selectionEnd == 9);     // the moving end
    CHECK(f.caretIndex == 9);
    tap(F.t, Key::Right, {Key::LeftShift});
    CHECK(f.selectionEnd == 10);
    tap(F.t, Key::Left, {kWord, Key::LeftShift});  // by word
    CHECK(f.selectionEnd == 6);
    type(F.t, U"W");
    CHECK(f.text == "hello W");
    CHECK(f.caretIndex == 7);
    CHECK(f.selectionStart == 7);
    tap(F.t, Key::A, {Key::LeftControl});
    CHECK(f.selectionStart == 0);
    CHECK(f.selectionEnd == 7);
    CHECK(f.caretIndex == 7);
    tap(F.t, Key::Right);  // collapses to the right end
    CHECK(f.selectionStart == 7);
    tap(F.t, Key::Home, {Key::LeftShift});
    CHECK(f.selectionStart == 7);
    CHECK(f.selectionEnd == 0);  // a selection to the left of the anchor
    tap(F.t, Key::Delete);
    CHECK(f.text.empty());
    CHECK(F.t.events().size() >= 1);
}

TEST_CASE("ui textfield editing: cut, copy and paste go through the clipboard at the caret") {
    Field F("hello world");
    MemoryClipboard clip;
    F.t.ui.set_clipboard(&clip);
    TextField& f = *F.f;
    tap(F.t, Key::Left, {kWord, Key::LeftShift});  // select "world"
    tap(F.t, Key::C, {Key::LeftControl});
    CHECK(clip.get() == "world");
    CHECK(f.text == "hello world");
    tap(F.t, Key::X, {Key::LeftControl});
    CHECK(clip.get() == "world");
    CHECK(f.text == "hello ");
    CHECK(f.caretIndex == 6);
    tap(F.t, Key::Home);
    clip.set("a\nb");  // a newline is dropped in a single line field
    tap(F.t, Key::V, {Key::LeftControl});
    CHECK(f.text == "abhello ");
    CHECK(f.caretIndex == 2);
    // paste over a selection, with the maximum length
    f.maxLength = 8;
    tap(F.t, Key::Right, {Key::LeftShift});
    tap(F.t, Key::Right, {Key::LeftShift});
    clip.set("WXYZ");
    tap(F.t, Key::V, {Key::LeftControl});
    CHECK(f.text == "abWXllo ");  // 8 code points at most: two of the four fit
    // Cmd is the chord on macOS: Cmd+A, Cmd+C
    tap(F.t, Key::A, {Key::LeftSuper});
    tap(F.t, Key::C, {Key::LeftSuper});
    CHECK(clip.get() == f.text);
}

TEST_CASE("ui textfield editing: a script that sets the caret or the selection is honoured") {
    Field F("hello");
    TextField& f = *F.f;
    f.caretIndex = 2;  // moves the caret, nothing selected
    type(F.t, U"X");
    CHECK(f.text == "heXllo");
    CHECK(f.caretIndex == 3);
    f.selectionStart = 1;  // selects "eXl" with the caret at its end
    f.selectionEnd = 4;
    f.caretIndex = 4;
    tap(F.t, Key::Backspace);
    CHECK(f.text == "hlo");
    CHECK(f.caretIndex == 1);
    f.selectionStart = 0;  // only the selection written: the caret follows its end
    f.selectionEnd = 2;
    type(F.t, U"Z");
    CHECK(f.text == "Zo");
    // a script writing the text only: the caret goes to the end
    f.text = "brand new";
    type(F.t, U"!");
    CHECK(f.text == "brand new!");
    // an index outside the text is clamped
    f.caretIndex = 99;
    F.t.frame();
    CHECK(f.caretIndex == 10);
}

TEST_CASE("ui textfield editing: a click places the caret, a drag selects, a double click selects a word") {
    Field F("hello brave world", {400, 30});
    TextField& f = *F.f;
    const float x0 = 12.0f, cw = 14.4f;  // inner left edge, a character in the approximate measure
    F.t.click({x0 + cw * 2.0f + 2.0f, 15});
    CHECK(f.caretIndex == 2);
    CHECK(f.selectionStart == 2);
    F.t.frame(60);  // long enough: not a double click
    // drag from 1 to 4
    F.t.in.on_mouse_move({x0 + cw * 1.0f + 1.0f, 15});
    F.t.in.on_mouse_button(MouseButton::Left, true);
    F.t.frame();
    F.t.in.on_mouse_move({x0 + cw * 4.0f + 1.0f, 15});
    F.t.frame();
    F.t.in.on_mouse_button(MouseButton::Left, false);
    F.t.frame();
    CHECK(f.selectionStart == 1);
    CHECK(f.selectionEnd == 4);
    CHECK(f.caretIndex == 4);
    F.t.frame(60);
    // double click selects the word under the pointer, a third click all
    const Vec2 on_brave{x0 + cw * 8.0f, 15};
    F.t.click(on_brave);
    F.t.click(on_brave);
    CHECK(f.selectionStart == 6);
    CHECK(f.selectionEnd == 11);
    F.t.click(on_brave);
    CHECK(f.selectionStart == 0);
    CHECK(f.selectionEnd == 17);
    // click past the end
    F.t.frame(60);
    F.t.click({390, 15});
    CHECK(f.caretIndex == 17);
}

TEST_CASE("ui textfield editing: the caret and the selection are the ones drawn: view and caret rectangle agree") {
    ImeGuard guard;
    Ui t;
    t.ui.set_design_to_window([](Vec2 p) { return Vec2{p.x * 2.0f, p.y * 2.0f}; });
    Entity e = t.add<TextField>("f", {10, 20}, {200, 30});
    TextField& f = *t.w.get<TextField>(e);
    f.autoFocus = true;
    f.text = "abcd";
    t.frame();
    tap(t, Key::Left);
    tap(t, Key::Left);
    REQUIRE(f.caretIndex == 2);
    const float lineH = 24.0f * 1.2f, cw = 24.0f * 0.6f;
    const Rect r = ime_state().caretRect;
    CHECK(r.x == doctest::Approx(2.0f * (10.0f + 12.0f + 2.0f * cw)));
    CHECK(r.y == doctest::Approx(2.0f * (20.0f + (30.0f - lineH) * 0.5f)));
    CHECK(r.w == doctest::Approx(2.0f * kTextFieldCaretWidth));
    CHECK(r.h == doctest::Approx(2.0f * lineH));
}

TEST_CASE("ui textfield editing: the composition shows at the caret and is typed there when committed") {
    ImeGuard guard;
    Ui t;
    t.ui.set_design_to_window([](Vec2 p) { return Vec2{p.x * 2.0f, p.y * 2.0f}; });
    Entity e = t.add<TextField>("f", {0, 0}, {300, 30});
    TextField& f = *t.w.get<TextField>(e);
    f.autoFocus = true;
    f.text = "abcd";
    t.frame();
    tap(t, Key::Left);
    tap(t, Key::Left);
    const float cw = 24.0f * 0.6f;
    t.in.on_composition_update(U"あいう", 2, 1);
    t.frame();
    CHECK(f.composition == "\xE3\x81\x82\xE3\x81\x84\xE3\x81\x86");
    CHECK(f.compositionCaret == 2);
    CHECK(f.compositionSelection == 1);
    CHECK(f.text == "abcd");  // not typed yet
    CHECK(f.caretIndex == 2);
    // the view draws it between ab and cd and puts the caret inside it
    // The UI of this test measures with approx_text_size (0.6 em per byte): the same here.
    const TextFieldMeasure m = [&](const std::string& s) { return approx_text_size(s, 24.0f, 0.0f); };
    const TextFieldView v = text_field_view(f, Rect{0, 0, 300, 30}, m);
    CHECK(v.display == "ab\xE3\x81\x82\xE3\x81\x84\xE3\x81\x86"
                       "cd");
    CHECK(v.composing);
    CHECK(v.compX0 == doctest::Approx(12 + 2 * cw));
    CHECK(v.compX1 == doctest::Approx(12 + 2 * cw + 9 * cw));
    CHECK(v.caretX == doctest::Approx(12 + 2 * cw + 6 * cw));  // two code points of three bytes into the composition
    CHECK(v.clauseX0 == doctest::Approx(v.caretX));
    CHECK(v.clauseX1 == doctest::Approx(12 + 2 * cw + 9 * cw));
    CHECK(ime_state().caretRect.x ==
          doctest::Approx(2.0f * v.caretX));  // the IME's window follows the composition caret
    // an arrow or Backspace belongs to the IME meanwhile
    tap(t, Key::Backspace);
    CHECK(f.text == "abcd");
    t.in.on_composition_commit(U"あい");
    t.frame();
    CHECK(f.text == "ab\xE3\x81\x82\xE3\x81\x84"
                    "cd");
    CHECK(f.composition.empty());
    CHECK(f.caretIndex == 4);
    CHECK(t.events().back() == "ui.change:f=\"ab\xE3\x81\x82\xE3\x81\x84"
                               "cd\"");
    // a click inside the field commits the composition at the caret it began at (once), then puts the caret where it landed
    t.in.on_composition_update(U"う", 1, 0);
    t.frame();
    const int cancels = ime_state().cancels;
    t.click({20, 15});
    CHECK_FALSE(t.in.composing());
    CHECK(f.composition.empty());
    CHECK(f.text == "ab\xE3\x81\x82\xE3\x81\x84\xE3\x81\x86"
                    "cd");
    CHECK(ime_state().cancels == cancels + 1);  // the backend was told to forget it, and delivered nothing
    CHECK(t.in.text_input().empty());
    CHECK(f.caretIndex <= 1);  // the click landed at the start of the field
}

TEST_CASE("ui textfield editing: moving the focus to another field commits the composition into the first one") {
    ImeGuard guard;
    Ui t;
    Entity a = t.add<TextField>("a", {0, 0}, {300, 30});
    Entity b = t.add<TextField>("b", {0, 100}, {300, 30});
    TextField& fa_ = *t.w.get<TextField>(a);
    TextField& fb = *t.w.get<TextField>(b);
    fa_.autoFocus = true;
    fa_.text = "ab";
    t.frame();
    t.in.on_composition_update(U"xy", 2, 0);
    t.frame();
    t.click({20, 115});  // the second field takes the focus
    CHECK(fa_.text == "abxy");
    CHECK(fb.text.empty());
    CHECK_FALSE(t.in.composing());
}

TEST_CASE("ui textfield editing: the focus-move commit types the text once and tells the platform to forget it") {
    ImeGuard guard;
    Ui t;
    Entity a = t.add<TextField>("a", {0, 0}, {300, 30});
    Entity b = t.add<TextField>("b", {0, 100}, {300, 30});
    TextField& fa_ = *t.w.get<TextField>(a);
    TextField& fb = *t.w.get<TextField>(b);
    fa_.autoFocus = true;
    fa_.text = "ab";
    t.frame();
    t.in.on_composition_update(U"xy", 2, 0);
    t.frame();
    const int cancels = ime_state().cancels;
    t.click({20, 115});
    CHECK(fa_.text == "abxy");  // typed once, not twice
    CHECK(t.in.text_input().empty());
    CHECK(ime_state().cancels == cancels + 1);
    CHECK(ime_state().enabled);  // the second field takes the input method
    // The commit into the first field did not point the memory of what the UI wrote back at it: a script writing the new
    // focused field is noticed (its caret goes to the end).
    fb.text = "hello";
    t.frame();
    CHECK(fb.caretIndex == 5);
}

TEST_CASE(
    "ui textfield editing: a focus move into a password field commits the composition and turns the input method off") {
    ImeGuard guard;
    Ui t;
    Entity a = t.add<TextField>("a", {0, 0}, {300, 30});
    Entity b = t.add<TextField>("b", {0, 100}, {300, 30});
    TextField& fa_ = *t.w.get<TextField>(a);
    t.w.get<TextField>(b)->password = true;
    fa_.autoFocus = true;
    fa_.text = "ab";
    t.frame();
    CHECK(ime_state().enabled);
    t.in.on_composition_update(U"xy", 2, 0);
    t.frame();
    t.click({20, 115});
    CHECK(fa_.text == "abxy");
    CHECK_FALSE(t.in.composing());
    CHECK_FALSE(ime_state().enabled);
}

TEST_CASE("ui textfield editing: a commit into a field that is full types nothing and sends no ui.change") {
    ImeGuard guard;
    Field F("abc");
    TextField& f = *F.f;
    f.maxLength = 3;
    F.t.in.on_composition_update(U"xy", 2, 0);
    F.t.frame();
    F.t.click({20, 15});  // a click in the field commits the composition at the caret
    CHECK(f.text == "abc");
    CHECK_FALSE(F.t.in.composing());
    for (const std::string& e : F.t.events()) CHECK(e.rfind("ui.change", 0) != 0);
}

TEST_CASE("ui textfield editing: a commit longer than the text one frame can carry is cut at that cap, not lost") {
    ImeGuard guard;
    Field F("");
    TextField& f = *F.f;
    F.t.in.on_composition_commit(std::u32string(Input::kMaxTextPerView + 500, U'a'));
    CHECK(F.t.in.text_input().size() == Input::kMaxTextPerView);  // Input itself cuts the burst at the cap
    F.t.frame();
    CHECK(f.text.size() == Input::kMaxTextPerView);
    CHECK(f.caretIndex == int(Input::kMaxTextPerView));
    int changes = 0;
    for (const std::string& e : F.t.events()) changes += e.rfind("ui.change", 0) == 0 ? 1 : 0;
    CHECK(changes == 1);
}

TEST_CASE("ui textfield editing: only one UI of the process holds the input method, and it gives it back") {
    ImeGuard guard;
    auto first = std::make_unique<Field>("ab");
    first->t.frame();  // the UI that updates first takes it (not a side effect of building the field)
    CHECK(ime_state().enabled);
    Field second("cd");
    const Rect rect = ime_state().caretRect;
    second.t.frame(
        3);  // the second UI's field is focused too: it types as a plain field and leaves the input method alone
    CHECK(ime_state().caretRect.x == rect.x);
    CHECK(ime_state().caretRect.y == rect.y);
    first.reset();  // destroying the holder gives the input method back
    CHECK_FALSE(ime_state().enabled);
    second.t.frame();
    CHECK(ime_state().enabled);  // and the other UI takes it on its next frame
    CHECK(ime_state().caretRect.x > 0.0f);
}

TEST_CASE("ui textfield editing: a UI that stopped updating with a focused field loses the input method to another") {
    ImeGuard guard;
    Field stale("ab");
    CHECK(ime_state().enabled);  // taken by `stale`
    Field live("cdefg", {200, 30});
    live.t.frame(5);  // a few updates of the other UI: the holder is only idle, it keeps the input method
    const int cancels = ime_state().cancels;
    const Rect heldRect = ime_state().caretRect;
    CHECK(ime_state().enabled);
    live.t.frame(40);  // far more updates than a holder may miss: `stale` is taken to have stopped
    CHECK(ime_state().enabled);
    CHECK(ime_state().cancels == cancels + 1);     // what the old holder was composing is dropped, once
    CHECK(ime_state().caretRect.x != heldRect.x);  // the rectangle is the live field's now (its text is not the same)
    // The old holder, back at last, has lost it: it does not move the caret rectangle and does not turn the input method off
    // or cancel anything.
    const Rect rect = ime_state().caretRect;
    stale.t.frame(3);
    CHECK(ime_state().enabled);
    CHECK(ime_state().caretRect.x == rect.x);
    CHECK(ime_state().cancels == cancels + 1);
}

TEST_CASE("ui textfield editing: the field that loses the focus forgets its scroll when a script empties it") {
    Ui t;
    Entity a = t.add<TextField>("a", {0, 0}, {120, 30});
    Entity b = t.add<TextField>("b", {0, 100}, {120, 30});
    TextField& fa_ = *t.w.get<TextField>(a);
    fa_.autoFocus = true;
    fa_.text = "abcdefghijklmnopqrstuvwxyz";
    t.frame();
    CHECK(fa_.scrollX > 0.0f);
    t.click({20, 115});         // b has the focus now
    CHECK(fa_.scrollX > 0.0f);  // a keeps what it shows while it has text
    fa_.text.clear();
    t.frame();
    CHECK(fa_.scrollX == 0.0f);
    (void)b;
}

TEST_CASE("ui textfield editing: a script writing the text of the focused field moves the caret and the IME rectangle "
          "at once") {
    ImeGuard guard;
    Field F("ab");
    TextField& f = *F.f;
    const float cw = 24.0f * 0.6f;
    f.text = "hello world";
    F.t.frame();  // no key pressed
    CHECK(f.caretIndex == 11);
    CHECK(f.selectionStart == 11);
    CHECK(f.selectionEnd == 11);
    CHECK(ime_state().caretRect.x == doctest::Approx(12.0f + 11 * cw));
}

TEST_CASE("ui textfield editing: a double click selects the character under the pointer's word, not the nearest edge") {
    Field F("hello brave world", {400, 30});
    TextField& f = *F.f;
    const float x0 = 12.0f, cw = 14.4f;
    F.t.frame(60);
    // the right half of the last letter of "hello" (index 4): still "hello"
    const Vec2 lastLetter{x0 + cw * 4.0f + cw * 0.8f, 15};
    F.t.click(lastLetter);
    F.t.click(lastLetter);
    CHECK(f.selectionStart == 0);
    CHECK(f.selectionEnd == 5);
    F.t.frame(60);
    // the right half of the single space (index 5): the space only
    const Vec2 onSpace{x0 + cw * 5.0f + cw * 0.8f, 15};
    F.t.click(onSpace);
    F.t.click(onSpace);
    CHECK(f.selectionStart == 5);
    CHECK(f.selectionEnd == 6);
}

TEST_CASE("ui textfield editing: the platform keyboard request carries the password flag") {
    Ui t;
    std::vector<TextInputRequest> seen;
    t.ui.set_text_input_handler([&](const TextInputRequest& r) {
        seen.push_back(r);
        return true;
    });
    t.in.set_last_device(InputDevice::Gamepad);
    Entity e = t.add<TextField>("f", {0, 0}, {300, 30});
    TextField& f = *t.w.get<TextField>(e);
    f.autoFocus = true;
    f.password = true;
    t.frame();
    REQUIRE_FALSE(seen.empty());
    CHECK(seen.front().focused);
    CHECK(seen.front().password);
}

TEST_CASE("ui textfield editing: a password is one word, and the input method stays off") {
    ImeGuard guard;
    Field F("pass word-1", {400, 30});
    TextField& f = *F.f;
    CHECK(ime_state().enabled);
    f.password = true;
    F.t.frame();
    CHECK_FALSE(ime_state().enabled);
    tap(F.t, Key::Left, {kWord});  // the whole text is one word: the caret goes to the start
    CHECK(f.caretIndex == 0);
    tap(F.t, Key::Delete, {kWord});  // and the word after the caret is all of it
    CHECK(f.text.empty());
    f.text = "pass word-1";
    F.t.frame();
    F.t.frame(60);
    F.t.click({40, 15});
    F.t.click({40, 15});  // a double click selects all
    CHECK(f.selectionStart == 0);
    CHECK(f.selectionEnd == 11);
}

TEST_CASE("ui textfield editing: maxLength never cuts inside an emoji sequence") {
    Field F("", {400, 30});
    TextField& f = *F.f;
    f.maxLength = 3;
    MemoryClipboard clip;
    F.t.ui.set_clipboard(&clip);
    clip.set(std::string("a") + kFamily + "b");  // a, man ZWJ woman, b: five code points; 3 would cut after ZWJ
    tap(F.t, Key::V, {Key::LeftControl});
    CHECK(f.text == "a");
}

TEST_CASE("ui textfield editing: a password field masks the text and the composition and never copies") {
    ImeGuard guard;
    Ui t;
    MemoryClipboard clip;
    t.ui.set_clipboard(&clip);
    clip.set("before");
    Entity e = t.add<TextField>("f", {0, 0}, {300, 30});
    TextField& f = *t.w.get<TextField>(e);
    f.autoFocus = true;
    f.password = true;
    t.frame();
    type(t, U"s3crét");
    CHECK(f.text == "s3cr\xC3\xA9t");
    tap(t, Key::A, {Key::LeftControl});
    tap(t, Key::C, {Key::LeftControl});
    tap(t, Key::X, {Key::LeftControl});
    CHECK(clip.get() == "before");
    CHECK(f.text == "s3cr\xC3\xA9t");
    t.in.on_composition_update(U"あ", 1, 0);
    t.frame();
    const TextFieldMeasure m = [](const std::string& s) { return Vec2{float(utf8_length(s)) * 10.0f, 20.0f}; };
    const TextFieldView v = text_field_view(f, Rect{0, 0, 300, 30}, m);
    CHECK(v.display == "*******");  // 6 characters and the composition, all masked
    // the reflected field is saved with the scene
    const TypeInfo* info = TypeRegistry::global().find("TextField");
    REQUIRE(info);
    bool seen = false;
    for (const FieldInfo& fi : info->fields) seen |= fi.name == "password" && fi.serialized;
    CHECK(seen);
}

TEST_CASE("ui textfield editing: a field narrower than its text scrolls to keep the caret visible") {
    Field F("abcdefghijklmnopqrstuvwxyz", {120, 30});  // inner 96: six characters in the approximate measure
    TextField& f = *F.f;
    CHECK(f.scrollX > 0.0f);  // focus put the caret at the end: the end shows
    const float atEnd = f.scrollX;
    tap(F.t, Key::Left);
    CHECK(f.scrollX == doctest::Approx(atEnd));  // the caret is still in view
    tap(F.t, Key::Home);
    CHECK(f.scrollX == doctest::Approx(0.0f));
    tap(F.t, Key::End);
    CHECK(f.scrollX == doctest::Approx(atEnd));
}
