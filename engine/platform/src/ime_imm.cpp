#include "ime_imm.h"

#include <algorithm>

#include "fa/platform/input.h"

namespace fa::ime_imm {

namespace {
bool is_target(std::uint8_t a) { return a == kAttrTargetConverted || a == kAttrTargetNotConverted; }

bool clauses_valid(const std::vector<std::uint32_t>& b, std::size_t n) {
    if (b.size() < 2 || b.front() != 0 || b.back() != n) return false;
    for (std::size_t i = 1; i < b.size(); ++i)
        if (b[i] < b[i - 1]) return false;
    return true;
}
}  // namespace

bool wants_comp(std::uint32_t flags) { return (flags & kGcsCompStr) != 0 || (flags & kGcsResultStr) == 0; }

ime_text::Marked marked(const Composition& c) {
    const std::size_t n = c.comp.size();
    std::size_t start = n, end = n;
    if (c.attrs.size() == n)
        for (std::size_t i = 0; i < n; ++i)
            if (is_target(c.attrs[i])) {
                start = end = i;
                while (end < n && is_target(c.attrs[end])) ++end;
                break;
            }
    if (start < end) {
        if (clauses_valid(c.clauses, n))
            for (std::size_t k = 0; k + 1 < c.clauses.size(); ++k)
                if (c.clauses[k] <= start && start < c.clauses[k + 1]) {
                    end = std::min<std::size_t>(end, c.clauses[k + 1]);
                    break;
                }
        return ime_text::marked_from_utf16(c.comp, start, end - start, {});
    }
    const std::size_t caret = c.cursor < 0 ? n : std::min<std::size_t>(static_cast<std::size_t>(c.cursor), n);
    return ime_text::marked_from_utf16(c.comp, caret, 0, {});
}

std::u32string result_text(std::u16string_view result) {
    std::u32string t = ime_text::utf16_to_utf32(result);
    t.erase(std::remove_if(t.begin(), t.end(), [](char32_t ch) { return ch < 32 || ch == 127; }), t.end());
    return t;
}

void Session::reset() {
    osComposing_ = false;
    dropping_ = false;
    echo_.clear();
    echoPos_ = 0;
    swallowed_.reset();
    delivered_.reset();
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

void Session::set_enabled(bool on) {
    if (on == enabled_) return;
    if (!on) {
        if (input_ && input_->composing()) input_->on_composition_cancel();
        if (osComposing_) dropping_ = true;  // ime_win32.cpp cancels it; what the IME still says about it is dropped
    } else {
        dropping_ = false;
    }
    enabled_ = on;
}

void Session::start() {
    osComposing_ = true;
    dropping_ = false;
}

void Session::composition(const Composition& c) {
    const bool deliver = active() && !dropping_;
    if ((c.flags & kGcsResultStr) != 0 && !c.result.empty()) {
        // Windows sends a result again as WM_IME_CHAR (and that as WM_CHAR) when the window passes the message on; this
        // backend does not, but an IME may post them itself: they are swallowed, also for a dropped composition.
        echo_ = c.result;
        echoPos_ = 0;
        if (deliver) input_->on_composition_commit(result_text(c.result));
    }
    if (!wants_comp(c.flags)) return;
    if (!c.comp.empty()) osComposing_ = true;
    if (!deliver) return;
    if (c.comp.empty()) {
        if (input_->composing()) input_->on_composition_cancel();
        return;
    }
    ime_text::Marked m = marked(c);
    input_->on_composition_update(std::move(m.text), m.caret, m.selLength);
}

void Session::end() {
    osComposing_ = false;
    if (active() && !dropping_ && input_->composing()) input_->on_composition_cancel();
}

void Session::cancel() {
    if (!input_) return;
    const bool open = osComposing_ || input_->composing();
    if (input_->composing()) input_->on_composition_cancel();
    if (open) dropping_ = true;
}

void Session::focus_lost() {
    swallowed_.reset();
    delivered_.reset();
}

bool Session::take_char(char16_t unit) {
    if (echoPos_ < echo_.size() && echo_[echoPos_] == unit) {
        if (++echoPos_ == echo_.size()) {
            echo_.clear();
            echoPos_ = 0;
        }
        return true;
    }
    echo_.clear();
    echoPos_ = 0;
    return false;
}

bool Session::key_down(unsigned vk, unsigned scanCode) {
    const std::size_t sc = scanCode % kScanCodes;
    dropping_ = false;
    if (!active() || vk != kVkProcessKey) {
        // A key the IME did not take: a result's repeat can no longer come (Windows posts it before the next key).
        echo_.clear();
        echoPos_ = 0;
        delivered_.set(sc);
        swallowed_.reset(sc);
        return false;
    }
    if (!delivered_.test(sc)) swallowed_.set(sc);
    return true;
}

bool Session::key_up(unsigned scanCode) {
    const std::size_t sc = scanCode % kScanCodes;
    echo_.clear();
    echoPos_ = 0;
    const bool swallow = swallowed_.test(sc) && !delivered_.test(sc);
    swallowed_.reset(sc);
    delivered_.reset(sc);
    return swallow;
}

}  // namespace fa::ime_imm
