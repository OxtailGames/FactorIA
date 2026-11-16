// The Android IME backend's decisions (src/ime_ic.h), driven like ime_android.cpp drives them from the engine's
// InputConnection (platforms/android/.../factoria/engine/Ime.java), against a real Input. Compiled and run on every host:
// the JNI glue itself only builds for Android.
#include <doctest.h>

#include <string>
#include <thread>
#include <vector>

#include "../src/ime_ic.h"
#include "fa/platform/input.h"

using namespace fa;
using namespace fa::ime_ic;

namespace {
Event compose(std::int32_t gen, std::u16string text, int cursor = 1, std::vector<ime_text::Run> clauses = {}) {
    Event e;
    e.kind = Event::Kind::Compose;
    e.generation = gen;
    e.text = std::move(text);
    e.cursor = cursor;
    e.clauses = std::move(clauses);
    return e;
}
Event commit(std::int32_t gen, std::u16string text) {
    Event e;
    e.kind = Event::Kind::Commit;
    e.generation = gen;
    e.text = std::move(text);
    return e;
}
Event simple(Event::Kind kind, std::int32_t gen) {
    Event e;
    e.kind = kind;
    e.generation = gen;
    return e;
}
Event del(std::int32_t gen, int before, int after) {
    Event e = simple(Event::Kind::Delete, gen);
    e.before = before;
    e.after = after;
    return e;
}
// One frame: the backend feeds, the game reads, the next frame begins.
struct Frame {
    std::u32string text;
    bool backspace = false, del = false, enter = false, tab = false;
};
Frame frame(Session& s, Input& in) {
    s.feed(in);
    Frame f{in.text_input(), in.key_pressed(Key::Backspace), in.key_pressed(Key::Delete), in.key_pressed(Key::Enter),
            in.key_pressed(Key::Tab)};
    in.begin_frame();
    return f;
}
}  // namespace

TEST_CASE("Android IME: setComposingText's newCursorPosition") {
    CHECK(compose_caret(3, 1) == 3);   // right after the text: what every IME sends
    CHECK(compose_caret(3, 0) == 0);   // right before it
    CHECK(compose_caret(3, -1) == 0);  // before the text: clamped
    CHECK(compose_caret(3, 2) == 3);   // past it: clamped
    CHECK(compose_caret(0, 1) == 0);
    CHECK(compose_caret(3, 2147483647) == 3);
    CHECK(compose_caret(3, -2147483647 - 1) == 0);
}

TEST_CASE("Android IME: a text is cut at kMaxText units, never inside a surrogate pair") {
    std::u16string t(kMaxText + 10, u'a');
    CHECK(clamp_text(t).size() == kMaxText);
    t = std::u16string(kMaxText - 1, u'a') + u"\xD83D\xDE00";
    CHECK(clamp_text(t).size() == kMaxText - 1);
    CHECK(clamp_text(u"abc") == u"abc");
}

TEST_CASE("Android IME: a composition, its commit, typed once") {
    Input in;
    Session s;
    const std::int32_t g = s.set_enabled(true);
    s.push(compose(g, u"に"));
    Frame f = frame(s, in);
    CHECK(f.text.empty());  // an update never types
    CHECK(in.composing());
    CHECK(in.composition_text() == U"に");
    CHECK(in.composition_caret() == 1);
    // Gboard Japanese: the converted clause highlighted (BackgroundColorSpan), the rest only underlined.
    s.push(compose(g, u"日本語です", 1, {{3, 2, true}, {0, 3, true}}));
    s.feed(in);
    CHECK(in.composition_text() == U"日本語です");
    CHECK(in.composition_caret() == 0);  // the first clause by position, whatever order Java listed the spans in
    CHECK(in.composition_selection_length() == 3);
    in.begin_frame();
    s.push(commit(g, u"日本語です"));
    f = frame(s, in);
    CHECK(f.text == U"日本語です");
    CHECK_FALSE(in.composing());
    CHECK_FALSE(s.composing());
    f = frame(s, in);
    CHECK(f.text.empty());
}

TEST_CASE("Android IME: finishComposingText types the composition as it is") {
    Input in;
    Session s;
    const std::int32_t g = s.set_enabled(true);
    s.push(compose(g, u"hel"));
    s.push(compose(g, u"hello"));
    s.push(simple(Event::Kind::Finish, g));
    Frame f = frame(s, in);
    CHECK(f.text == U"hello");
    CHECK_FALSE(in.composing());
    // A finish with nothing composed types nothing (Gboard sends one before most commits).
    s.push(simple(Event::Kind::Finish, g));
    f = frame(s, in);
    CHECK(f.text.empty());
}

TEST_CASE("Android IME: Korean, one syllable committed as the next begins") {
    Input in;
    Session s;
    const std::int32_t g = s.set_enabled(true);
    s.push(compose(g, u"한"));
    s.push(commit(g, u"한"));
    s.push(compose(g, u"그"));
    Frame f = frame(s, in);
    CHECK(f.text == U"한");
    CHECK(in.composing());
    CHECK(in.composition_text() == U"그");
}

TEST_CASE("Android IME: a composition emptied by Backspace, or a closed connection, types nothing") {
    Input in;
    Session s;
    const std::int32_t g = s.set_enabled(true);
    s.push(compose(g, u"a"));
    s.push(compose(g, u""));
    Frame f = frame(s, in);
    CHECK(f.text.empty());
    CHECK_FALSE(in.composing());
    s.push(compose(g, u"ab"));
    frame(s, in);
    CHECK(in.composing());
    s.push(simple(Event::Kind::Close, g));
    s.push(simple(Event::Kind::Finish, g));  // what the old connection's finishComposingText would add: nothing left
    f = frame(s, in);
    CHECK(f.text.empty());
    CHECK_FALSE(in.composing());
}

TEST_CASE("Android IME: a commit with no composition types (punctuation, a suggestion, a paste)") {
    Input in;
    Session s;
    const std::int32_t g = s.set_enabled(true);
    s.push(commit(g, u","));
    s.push(commit(g, u"a\xD83D\xDE00"));
    Frame f = frame(s, in);
    CHECK(f.text == U",a\U0001F600");
    CHECK_FALSE(in.composing());
}

TEST_CASE("Android IME: a line break in a commit is Enter, a tab is Tab, one key per frame") {
    Input in;
    Session s;
    const std::int32_t g = s.set_enabled(true);
    s.push(compose(g, u"ok"));
    s.push(commit(g, u"ok\n"));
    s.push(commit(g, u"x"));
    Frame f = frame(s, in);
    CHECK(f.text == U"ok");
    CHECK(f.enter);
    f = frame(s, in);  // what came after the key press: the next frame
    CHECK(f.text == U"x");
    CHECK_FALSE(f.enter);
    s.push(commit(g, u"a\tb\x01"));
    f = frame(s, in);
    CHECK(f.text == U"a");
    CHECK(f.tab);
    f = frame(s, in);
    CHECK(f.text == U"b");  // the other control characters are dropped
    CHECK_FALSE(f.tab);
    CHECK(s.pending() == 0);
}

TEST_CASE("Android IME: deleteSurroundingText presses Backspace and Delete, one per frame") {
    Input in;
    Session s;
    const std::int32_t g = s.set_enabled(true);
    s.push(del(g, 2, 1));
    s.push(commit(g, u"z"));
    Frame f = frame(s, in);
    CHECK(f.backspace);
    CHECK(f.text.empty());
    f = frame(s, in);
    CHECK(f.backspace);
    f = frame(s, in);
    CHECK_FALSE(f.backspace);
    CHECK(f.del);
    f = frame(s, in);
    CHECK_FALSE(f.del);
    CHECK(f.text == U"z");
    CHECK_FALSE(in.key_down(Key::Backspace));  // every press is released
    // Negative counts are nothing; a huge one stops at kMaxDeletes.
    s.push(del(g, -5, -1));
    s.push(del(g, 1000000, 0));
    int presses = 0;
    for (int i = 0; i < kMaxDeletes * 2; ++i) presses += frame(s, in).backspace ? 1 : 0;
    CHECK(presses == kMaxDeletes);
    CHECK(s.pending() == 0);
}

TEST_CASE("Android IME: performEditorAction is Enter") {
    Input in;
    Session s;
    const std::int32_t g = s.set_enabled(true);
    s.push(simple(Event::Kind::Action, g));
    CHECK(frame(s, in).enter);
}

TEST_CASE("Android IME: after ime_cancel nothing of that composition reaches Input") {
    Input in;
    Session s;
    const std::int32_t g = s.set_enabled(true);
    s.push(compose(g, u"にほ"));
    frame(s, in);
    REQUIRE(in.composing());
    // A tap in the field: the UI types what was built and cancels Input's composition, then ime_cancel().
    in.on_composition_commit(in.composition_text());
    CHECK(s.cancel());
    const std::int32_t g2 = s.generation();
    CHECK(g2 != g);
    // What the old connection still says (the IME's own update, its commit or finish as the input restarts) is dropped.
    s.push(compose(g, u"にほん"));
    s.push(commit(g, u"にほん"));
    s.push(simple(Event::Kind::Finish, g));
    Frame f = frame(s, in);
    CHECK(f.text == U"にほ");  // the UI's commit, once
    f = frame(s, in);
    CHECK(f.text.empty());
    CHECK_FALSE(in.composing());
    // The restarted connection's composition starts normally.
    s.push(compose(g2, u"か"));
    s.push(commit(g2, u"か"));
    f = frame(s, in);
    CHECK(f.text == U"か");
}

TEST_CASE("Android IME: ime_cancel drops what is queued behind a key press too") {
    Input in;
    Session s;
    const std::int32_t g = s.set_enabled(true);
    s.push(compose(g, u"a"));
    s.push(simple(Event::Kind::Action, g));
    s.push(compose(g, u"b"));
    frame(s, in);  // the composition "a", then Enter: "b" waits
    in.on_composition_cancel();
    CHECK(s.cancel());
    Frame f = frame(s, in);
    CHECK_FALSE(in.composing());
    CHECK(f.text.empty());
    CHECK(s.pending() == 0);
}

TEST_CASE("Android IME: ime_cancel sees a composition that began after the last frame") {
    Input in;
    Session s;
    const std::int32_t g = s.set_enabled(true);
    s.push(compose(g, u"x"));  // queued, not fed: the UI has not seen it, the IME has it open
    CHECK(s.cancel());
    Frame f = frame(s, in);
    CHECK_FALSE(in.composing());
    CHECK(f.text.empty());
}

TEST_CASE("Android IME: ime_cancel with no composition open drops nothing") {
    Input in;
    Session s;
    const std::int32_t g = s.set_enabled(true);
    CHECK_FALSE(s.cancel());  // every tap in a field cancels
    CHECK(s.generation() == g);
    s.push(compose(g, u"a"));
    s.push(commit(g, u"ab"));  // a composition that ended in the queue
    CHECK_FALSE(s.cancel());
    s.push(commit(g, u"c"));
    CHECK(frame(s, in).text == U"abc");
}

TEST_CASE("Android IME: turning it off drops the old connection and ends the composition") {
    Input in;
    Session s;
    const std::int32_t g = s.set_enabled(true);
    CHECK(s.set_enabled(true) == g);  // no change, no new generation
    s.push(compose(g, u"ab"));
    frame(s, in);
    REQUIRE(in.composing());
    const std::int32_t off = s.set_enabled(false);
    CHECK(off != g);
    CHECK_FALSE(s.enabled());
    s.push(commit(g, u"ab"));
    Frame f = frame(s, in);
    CHECK_FALSE(in.composing());  // cancelled: nothing typed
    CHECK(f.text.empty());
    // While off nothing is delivered, whatever its generation.
    s.push(commit(off, u"q"));
    CHECK(frame(s, in).text.empty());
    CHECK_FALSE(s.cancel());
    // On again: a new generation, and only its connection types.
    const std::int32_t on = s.set_enabled(true);
    CHECK(on != off);
    s.push(commit(off, u"old"));
    s.push(commit(on, u"new"));
    CHECK(frame(s, in).text == U"new");
}

TEST_CASE("Android IME: the generation wraps instead of overflowing") {
    Session s;
    std::int32_t last = s.generation();
    for (int i = 0; i < 6; ++i) {
        const std::int32_t g = s.set_enabled(i % 2 == 0);
        CHECK(g != last);
        last = g;
    }
}

TEST_CASE("Android IME: events pushed from another thread arrive in order; a full queue drops and says so") {
    Input in;
    Session s;
    const std::int32_t g = s.set_enabled(true);
    std::thread ui([&] {
        for (char16_t c = u'a'; c <= u'z'; ++c) s.push(commit(g, std::u16string(1, c)));
    });
    ui.join();
    CHECK(frame(s, in).text == U"abcdefghijklmnopqrstuvwxyz");
    for (std::size_t i = 0; i < kMaxQueued; ++i) REQUIRE(s.push(simple(Event::Kind::Finish, g)));
    CHECK_FALSE(s.push(commit(g, u"lost")));
    frame(s, in);
    CHECK(s.push(commit(g, u"ok")));  // the feed emptied it
    CHECK(frame(s, in).text == U"ok");
}
