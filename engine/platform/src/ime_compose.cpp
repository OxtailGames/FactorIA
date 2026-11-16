#include "ime_compose.h"

#include <algorithm>

#include "fa/platform/input.h"

namespace fa::ime_compose {

std::u32string printable(std::u32string_view text) {
    std::u32string out;
    out.reserve(text.size());
    for (const char32_t c : text) {
        if (c < 32 || c == 127 || c > 0x10FFFF || (c >= 0xD800 && c <= 0xDFFF)) continue;
        out.push_back(c);
    }
    return out;
}

std::u16string to_utf16(std::u32string_view text) {
    std::u16string out;
    out.reserve(text.size());
    for (char32_t c : text) {
        if (c > 0x10FFFF || (c >= 0xD800 && c <= 0xDFFF)) c = 0xFFFD;
        if (c < 0x10000) {
            out.push_back(static_cast<char16_t>(c));
        } else {
            c -= 0x10000;
            out.push_back(static_cast<char16_t>(0xD800 + (c >> 10)));
            out.push_back(static_cast<char16_t>(0xDC00 + (c & 0x3FF)));
        }
    }
    return out;
}

// ---- Preedit -------------------------------------------------------------------------------------------------------------

void Preedit::clear() {
    text_.clear();
    feedback_.clear();
    caret_ = 0;
}

void Preedit::draw(const Draw& d) {
    const int n = static_cast<int>(text_.size());
    const int first = std::clamp(d.first, 0, n);
    const int length = std::clamp(d.length, 0, n - first);
    const auto at = static_cast<std::size_t>(first);
    if (d.hasText && d.feedbackOnly) {
        const std::size_t count = std::min(d.feedback.size(), text_.size() - at);
        for (std::size_t i = 0; i < count; ++i) feedback_[at + i] = d.feedback[i];
    } else {
        text_.erase(at, static_cast<std::size_t>(length));
        feedback_.erase(feedback_.begin() + first, feedback_.begin() + first + length);
        if (d.hasText) {
            const std::size_t room = kMaxPreedit > text_.size() ? kMaxPreedit - text_.size() : 0;
            const std::size_t count = std::min(d.chars.size(), room);
            text_.insert(at, d.chars, 0, count);
            std::vector<unsigned long> fb(count, 0ul);
            std::copy_n(d.feedback.begin(), std::min(count, d.feedback.size()), fb.begin());
            feedback_.insert(feedback_.begin() + first, fb.begin(), fb.end());
        }
    }
    caret_ = std::clamp(d.caret, 0, static_cast<int>(text_.size()));
}

int Preedit::move_caret(int direction, int position) {
    switch (direction) {
        case kXimForwardChar: ++caret_; break;
        case kXimBackwardChar: --caret_; break;
        case kXimLineStart: caret_ = 0; break;
        case kXimLineEnd: caret_ = static_cast<int>(text_.size()); break;
        case kXimAbsolutePosition: caret_ = position; break;
        default: break;  // kXimDontChange, words, lines: the caret stays
    }
    caret_ = std::clamp(caret_, 0, static_cast<int>(text_.size()));
    return caret_;
}

ime_text::Marked Preedit::marked() const {
    ime_text::Marked m;
    m.text = text_;
    m.caret = caret_;
    for (const unsigned long bit : {kXimReverse, kXimHighlight}) {
        std::size_t i = 0;
        while (i < feedback_.size() && (feedback_[i] & bit) == 0) ++i;
        if (i == feedback_.size()) continue;
        std::size_t j = i;
        while (j < feedback_.size() && (feedback_[j] & bit) != 0) ++j;
        m.caret = static_cast<int>(i);
        m.selLength = static_cast<int>(j - i);
        break;
    }
    return m;
}

// ---- Session -------------------------------------------------------------------------------------------------------------

void Session::reset() {
    enabled_ = false;
    osComposing_ = false;
    dropping_ = false;
    endPending_ = false;
    swallowed_.reset();
    delivered_.reset();
    lastDown_.fill(0);
    lastUp_.fill(0);
}

void Session::attach(Input* target) {
    if (target == input_) return;
    if (input_ && input_->composing()) input_->on_composition_cancel();
    input_ = target;
    reset();
}

void Session::forget() {
    input_ = nullptr;
    reset();
}

bool Session::open() const { return osComposing_ || (input_ != nullptr && input_->composing()); }

void Session::set_enabled(bool on) {
    if (on == enabled_) return;
    endPending_ = false;
    if (!on) {
        if (input_ && input_->composing()) input_->on_composition_cancel();
        if (osComposing_)
            dropping_ = true;  // the backend cancels it; what the input method still says about it is dropped
    } else {
        dropping_ = false;
    }
    enabled_ = on;
}

void Session::start() {
    osComposing_ = true;
    dropping_ = false;
}

void Session::update(ime_text::Marked m) {
    if (!m.text.empty()) osComposing_ = true;
    if (!active() || dropping_) return;
    if (m.text.empty()) {
        if (!input_->composing()) return;
        if (options_.deferEnds)
            endPending_ = true;
        else
            input_->on_composition_cancel();
        return;
    }
    endPending_ = false;
    input_->on_composition_update(std::move(m.text), m.caret, m.selLength);
}

void Session::commit(std::u32string text) {
    if (!input_ || dropping_) return;
    text = printable(text);
    if (text.empty()) return;
    if (!enabled_ && !options_.typeWhenOff) return;
    endPending_ = false;
    input_->on_composition_commit(std::move(text));
}

void Session::end() {
    osComposing_ = false;
    if (!active() || dropping_ || !input_->composing()) return;
    if (options_.deferEnds)
        endPending_ = true;
    else
        input_->on_composition_cancel();
}

void Session::flush() {
    if (!endPending_) return;
    endPending_ = false;
    if (input_ && input_->composing()) input_->on_composition_cancel();
}

void Session::cancel() {
    if (!input_) return;
    endPending_ = false;
    const bool wasOpen = open();
    if (input_->composing()) input_->on_composition_cancel();
    if (wasOpen) dropping_ = true;
}

void Session::focus_lost() {
    swallowed_.reset();
    delivered_.reset();
}

bool Session::key_down(unsigned code, bool imeTook, std::uint32_t time) {
    const std::size_t k = code % kKeys;
    dropping_ = false;
    if (k == 0) return active() && imeTook;  // code 0 is no key (ime_compose.h)
    if (!active() || !imeTook) {
        if (active() && time != 0) {
            // The same key with the same time again (or an older one): a copy of a key down already delivered.
            if (lastDown_[k] != 0 && static_cast<std::int32_t>(time - lastDown_[k]) <= 0) return true;
            lastDown_[k] = time;
        }
        delivered_.set(k);
        swallowed_.reset(k);
        return false;
    }
    if (!delivered_.test(k)) swallowed_.set(k);
    return true;
}

bool Session::key_up(unsigned code, bool imeTook, std::uint32_t time) {
    const std::size_t k = code % kKeys;
    if (k == 0) return active() && imeTook;  // code 0 is no key (ime_compose.h)
    if (active() && time != 0 && !delivered_.test(k) && !swallowed_.test(k) && lastUp_[k] != 0 &&
        static_cast<std::int32_t>(time - lastUp_[k]) <= 0)
        return true;  // a copy of a key up already delivered
    bool swallow = false;
    if (delivered_.test(k))
        swallow = false;
    else if (swallowed_.test(k))
        swallow = true;
    else
        swallow = imeTook && active();
    if (!swallow && time != 0) lastUp_[k] = time;
    swallowed_.reset(k);
    delivered_.reset(k);
    return swallow;
}

}  // namespace fa::ime_compose
