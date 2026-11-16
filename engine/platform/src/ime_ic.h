// The Android IME backend's decisions, without Android: what ime_android.cpp does with the calls the input method makes on
// the engine's InputConnection (platforms/android/app/src/main/java/factoria/engine/Ime.java: setComposingText,
// commitText, finishComposingText, deleteSurroundingText, performEditorAction, closeConnection) and with what the UI asks
// (ime_set_enabled, ime_cancel). Plain data in, Input calls out, so the tests cover it on every host
// (tests/ime_ic_tests.cpp). Private to fa_platform.
//
// Threads: push() is for any thread (Java calls the InputConnection on the app's UI thread, which is not the sokol_app
// loop thread the game runs on); everything else runs on the game thread, which also feeds Input.
//
// Generations: every change of the IME's state (on, off, a cancel that aborted a composition) starts a new generation,
// and Java creates each InputConnection with the generation it was told last. An event of an older generation is about a
// composition the UI already dealt with (a click committed it, the focus moved away), so it is dropped: no later update
// and no commit of THAT composition reach Input, and the next connection's composition starts normally.
#pragma once

#include <cstddef>
#include <cstdint>
#include <deque>
#include <mutex>
#include <string>
#include <vector>

#include "fa/platform/input.h"
#include "ime_text.h"

namespace fa::ime_ic {

// What one call on the InputConnection said. Strings are UTF-16, as Java has them.
struct Event {
    enum class Kind : std::uint8_t {
        Compose,  // setComposingText: the pre-edit string is now `text` (empty: the composition is gone)
        Commit,   // commitText: `text` replaces the composition (if any) and is typed
        Finish,   // finishComposingText: the pre-edit string is typed as it is
        Delete,   // deleteSurroundingText: `before` presses of Backspace, then `after` presses of Delete
        Action,   // performEditorAction: the keyboard's Enter key
        Close,    // closeConnection: the connection is gone, its composition with it (nothing is typed)
    };
    Kind kind = Kind::Compose;
    std::int32_t generation = 0;
    std::u16string text;                 // Compose, Commit
    int cursor = 1;                      // Compose: setComposingText's newCursorPosition (see compose_caret)
    std::vector<ime_text::Run> clauses;  // Compose: the runs the IME highlights (the clause it converts: emphasized)
    int before = 0, after = 0;           // Delete, in what the IME counts (UTF-16 units or code points: one press each)
};

inline constexpr std::size_t kMaxText = 65536;   // UTF-16 units of one event's text; the rest is cut (a paste that big)
inline constexpr std::size_t kMaxClauses = 64;   // highlighted runs read from one composition
inline constexpr std::size_t kMaxQueued = 4096;  // events waiting for the game thread; more are dropped (and logged)
inline constexpr int kMaxDeletes = 64;           // presses of one deleteSurroundingText, each way

// The caret inside a pre-edit string of `length` UTF-16 units for setComposingText's newCursorPosition: > 0 counts from
// the end of the text (1 = right after it), <= 0 from its start (0 = right before it). Clamped to the text.
std::size_t compose_caret(std::size_t length, int newCursorPosition);

// `text` cut at kMaxText units, never between the two halves of a surrogate pair.
std::u16string clamp_text(std::u16string text);

class Session {
public:
    // Any thread: queues an event for the next feed(). Returns false when the queue is full and the event was dropped.
    bool push(Event e);

    // ---- the game thread
    // A text field has the focus (on) or none has (off). A change starts a new generation, which Java must be told: what
    // the old connection still sends is dropped. Turning it off ends the composition this session opened in Input
    // (cancelled: nothing is typed) at the next feed(), when it is still open then.
    std::int32_t set_enabled(bool on);
    bool enabled() const { return enabled_; }
    // ime_cancel(). The UI has already committed what it keeps and cancelled Input's composition. When a composition was
    // open (fed to Input, or still waiting in the queue) this starts a new generation and returns true: Java restarts the
    // input with it, and nothing of that composition is delivered any more. With none open it returns false and changes
    // nothing (every tap in a field cancels; a commit that came with no composition still types).
    bool cancel();
    std::int32_t generation() const { return generation_; }
    // Whether the IME's composition is open in Input (an update with text was fed and not yet ended).
    bool composing() const { return composing_; }

    // Once per frame, before the game runs: the queued events of the current generation into `input`, in order. Commits
    // and updates go to on_composition_*; control characters in a commit become keys (a line break is Enter, a tab Tab);
    // Delete and Action are presses of Backspace / Delete / Enter. A TextField reads one press of a key per frame, so a
    // key press ends this frame's feed: what comes after it waits for the next frame (deleteSurroundingText(3, 0) is three
    // frames of Backspace). Nothing is delivered while the IME is off.
    void feed(Input& input);
    // Events waiting (queued or behind a key press): for tests.
    std::size_t pending();

private:
    // Handles the front of backlog_; true when it pressed a key (the frame's feed ends).
    bool step(Input& input);
    bool has_open_compose();

    std::mutex mutex_;
    std::vector<Event> queue_;   // guarded by mutex_: what push() added since the last feed()
    std::deque<Event> backlog_;  // game thread: what feed() has not handled yet (behind a key press)
    std::int32_t generation_ = 0;
    bool enabled_ = false;
    bool composing_ = false;
    std::u32string compositionText_;  // the last pre-edit string fed (finishComposingText types it)
    bool endInput_ = false;           // set_enabled(false) with a composition open: the next feed() cancels it in Input
};

}  // namespace fa::ime_ic
