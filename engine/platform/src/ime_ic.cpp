#include "ime_ic.h"

#include <algorithm>
#include <utility>

namespace fa::ime_ic {

namespace {
bool is_high(char16_t c) { return c >= 0xD800 && c <= 0xDBFF; }

// The key a control character of a commit is: a line break is Enter (the keyboard's Enter commits "\n" when the field asks
// for no action), a tab is Tab. Any other control character is dropped.
Key control_key(char16_t c) {
    if (c == u'\n' || c == u'\r') return Key::Enter;
    if (c == u'\t') return Key::Tab;
    return Key::Unknown;
}
bool is_control(char16_t c) { return c < 0x20 || c == 0x7F; }

void tap(Input& input, Key key) {
    input.on_key(key, true);
    input.on_key(key, false);
}

std::int32_t next(std::int32_t g) { return std::int32_t(std::uint32_t(g) + 1u); }  // wraps instead of overflowing
}  // namespace

std::size_t compose_caret(std::size_t length, int newCursorPosition) {
    // 64-bit arithmetic: newCursorPosition comes from the IME and may be any int.
    const std::int64_t n = std::int64_t(length);
    const std::int64_t caret = newCursorPosition > 0 ? n + newCursorPosition - 1 : std::int64_t(newCursorPosition);
    return std::size_t(std::clamp<std::int64_t>(caret, 0, n));
}

std::u16string clamp_text(std::u16string text) {
    if (text.size() <= kMaxText) return text;
    std::size_t n = kMaxText;
    if (is_high(text[n - 1])) --n;  // its low half is past the cut
    text.resize(n);
    return text;
}

bool Session::push(Event e) {
    e.text = clamp_text(std::move(e.text));
    if (e.clauses.size() > kMaxClauses) e.clauses.resize(kMaxClauses);
    std::lock_guard<std::mutex> lock(mutex_);
    if (queue_.size() >= kMaxQueued) return false;
    queue_.push_back(std::move(e));
    return true;
}

std::size_t Session::pending() {
    std::lock_guard<std::mutex> lock(mutex_);
    return queue_.size() + backlog_.size();
}

std::int32_t Session::set_enabled(bool on) {
    if (on == enabled_) return generation_;
    enabled_ = on;
    generation_ = next(generation_);
    backlog_.clear();  // all of the old generation
    if (!on && composing_) endInput_ = true;
    composing_ = false;
    compositionText_.clear();
    return generation_;
}

bool Session::has_open_compose() {
    // A composition that began after the last feed and has not ended in the queue: the UI never saw it, but it is the one
    // the IME would carry on into the field the UI moves to.
    bool open = composing_;
    auto scan = [&](const Event& e) {
        if (e.generation != generation_) return;
        if (e.kind == Event::Kind::Compose)
            open = !e.text.empty();
        else if (e.kind == Event::Kind::Commit || e.kind == Event::Kind::Finish || e.kind == Event::Kind::Close)
            open = false;
    };
    for (const Event& e : backlog_) scan(e);
    std::lock_guard<std::mutex> lock(mutex_);
    for (const Event& e : queue_) scan(e);
    return open;
}

bool Session::cancel() {
    if (!enabled_ || !has_open_compose()) return false;
    generation_ = next(generation_);
    backlog_.clear();
    composing_ = false;  // the UI has cancelled Input's composition already (fa/platform/ime.h)
    compositionText_.clear();
    return true;
}

void Session::feed(Input& input) {
    if (endInput_) {
        endInput_ = false;
        if (input.composing()) input.on_composition_cancel();
    }
    {
        std::lock_guard<std::mutex> lock(mutex_);
        for (Event& e : queue_) backlog_.push_back(std::move(e));
        queue_.clear();
    }
    while (!backlog_.empty()) {
        if (!enabled_ || backlog_.front().generation != generation_) {
            backlog_.pop_front();  // about a composition the UI is done with, or a field that no longer has the focus
            continue;
        }
        if (step(input)) return;
    }
}

bool Session::step(Input& input) {
    Event& e = backlog_.front();
    switch (e.kind) {
        case Event::Kind::Compose: {
            std::vector<ime_text::Run> runs = e.clauses;
            std::sort(runs.begin(), runs.end(),
                      [](const ime_text::Run& a, const ime_text::Run& b) { return a.start < b.start; });
            ime_text::Marked m = ime_text::marked_from_utf16(e.text, compose_caret(e.text.size(), e.cursor), 0, runs);
            if (m.text.empty()) {
                if (composing_) input.on_composition_cancel();  // Backspace took the last character back: nothing typed
                composing_ = false;
                compositionText_.clear();
            } else {
                compositionText_ = m.text;
                input.on_composition_update(std::move(m.text), m.caret, m.selLength);
                composing_ = true;
            }
            backlog_.pop_front();
            return false;
        }
        case Event::Kind::Commit: {
            // The text up to the first control character is typed (ending the composition, which it replaces); the control
            // character becomes a key press, and the rest waits in this event for the next frame.
            const std::size_t cut =
                std::size_t(std::find_if(e.text.begin(), e.text.end(), is_control) - e.text.begin());
            std::u32string typed = ime_text::utf16_to_utf32(std::u16string_view(e.text).substr(0, cut));
            if (composing_ || !typed.empty()) input.on_composition_commit(std::move(typed));
            composing_ = false;
            compositionText_.clear();
            if (cut == e.text.size()) {
                backlog_.pop_front();
                return false;
            }
            const Key key = control_key(e.text[cut]);
            e.text.erase(0, cut + 1);
            if (e.text.empty()) backlog_.pop_front();
            if (key == Key::Unknown) return false;
            tap(input, key);
            return true;
        }
        case Event::Kind::Finish: {
            if (composing_) input.on_composition_commit(std::move(compositionText_));
            composing_ = false;
            compositionText_.clear();
            backlog_.pop_front();
            return false;
        }
        case Event::Kind::Delete: {
            e.before = std::clamp(e.before, 0, kMaxDeletes);
            e.after = std::clamp(e.after, 0, kMaxDeletes);
            Key key = Key::Unknown;
            if (e.before > 0) {
                key = Key::Backspace;
                --e.before;
            } else if (e.after > 0) {
                key = Key::Delete;
                --e.after;
            }
            if (e.before == 0 && e.after == 0) backlog_.pop_front();
            if (key == Key::Unknown) return false;
            tap(input, key);
            return true;
        }
        case Event::Kind::Action: {
            backlog_.pop_front();
            tap(input, Key::Enter);
            return true;
        }
        case Event::Kind::Close: {
            if (composing_) input.on_composition_cancel();
            composing_ = false;
            compositionText_.clear();
            backlog_.pop_front();
            return false;
        }
    }
    backlog_.pop_front();
    return false;
}

}  // namespace fa::ime_ic
