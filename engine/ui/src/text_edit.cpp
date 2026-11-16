#include "text_edit.h"

#include <algorithm>

#include "fa/core/utf8.h"

namespace fa::text_edit {

namespace {

using U = std::u32string;

bool is_extender(char32_t c) {
    return (c >= 0x0300 && c <= 0x036F) || (c >= 0x0483 && c <= 0x0489) || (c >= 0x0591 && c <= 0x05BD) ||
           (c >= 0x064B && c <= 0x065F) || c == 0x0670 || (c >= 0x0900 && c <= 0x0903) ||
           (c >= 0x093A && c <= 0x094F && c != 0x093D) || (c >= 0x0E31 && c <= 0x0E3A && c != 0x0E32 && c != 0x0E33) ||
           (c >= 0x0E47 && c <= 0x0E4E) || (c >= 0x1AB0 && c <= 0x1AFF) || (c >= 0x1DC0 && c <= 0x1DFF) ||
           c == 0x200C || c == 0x200D || (c >= 0x20D0 && c <= 0x20FF) || (c >= 0x3099 && c <= 0x309A) ||
           (c >= 0xFE00 && c <= 0xFE0F) || (c >= 0xFE20 && c <= 0xFE2F) || (c >= 0x1F3FB && c <= 0x1F3FF) ||
           (c >= 0xE0020 && c <= 0xE007F) || (c >= 0xE0100 && c <= 0xE01EF);
}
bool is_regional(char32_t c) { return c >= 0x1F1E6 && c <= 0x1F1FF; }

// True when a caret may stand before code point `i` (0 and n always).
bool is_boundary(const U& u, std::size_t i) {
    if (i == 0 || i >= u.size()) return true;
    if (u[i - 1] == U'\r' && u[i] == U'\n') return false;
    if (is_extender(u[i])) return false;
    if (u[i - 1] == 0x200D) return false;  // a joiner glues the next character on
    if (is_regional(u[i]) && is_regional(u[i - 1])) {
        std::size_t run = 0;
        for (std::size_t k = i; k > 0 && is_regional(u[k - 1]); --k) ++run;
        return run % 2 == 0;  // flags are pairs
    }
    return true;
}
std::size_t prev_boundary(const U& u, std::size_t i) {
    if (i == 0) return 0;
    --i;
    while (i > 0 && !is_boundary(u, i)) --i;
    return i;
}
std::size_t next_boundary(const U& u, std::size_t i) {
    if (i >= u.size()) return u.size();
    ++i;
    while (i < u.size() && !is_boundary(u, i)) ++i;
    return i;
}

enum class Cls { Space, Word, Punct };
Cls cls(char32_t c) {
    if (c == U' ' || c == U'\t' || c == U'\n' || c == U'\r' || c == 0xA0 || c == 0x3000 || (c >= 0x2000 && c <= 0x200A))
        return Cls::Space;
    if (c < 0x80)
        return (c >= U'0' && c <= U'9') || (c >= U'a' && c <= U'z') || (c >= U'A' && c <= U'Z') || c == U'_'
                   ? Cls::Word
                   : Cls::Punct;
    if ((c >= 0x2010 && c <= 0x2027) || (c >= 0x3001 && c <= 0x3003) || (c >= 0xFF01 && c <= 0xFF0F)) return Cls::Punct;
    return Cls::Word;
}

// Start of the word before `i`: the spaces before the caret, then the run of one class.
std::size_t word_left(const U& u, std::size_t i) {
    while (i > 0 && cls(u[i - 1]) == Cls::Space) --i;
    if (i == 0) return 0;
    const Cls c = cls(u[i - 1]);
    while (i > 0 && cls(u[i - 1]) == c) --i;
    return i;
}
// End of the word after `i`: the spaces after the caret are skipped, then the run of one class.
std::size_t word_right(const U& u, std::size_t i) {
    while (i < u.size() && cls(u[i]) == Cls::Space) ++i;
    if (i >= u.size()) return u.size();
    const Cls c = cls(u[i]);
    while (i < u.size() && cls(u[i]) == c) ++i;
    return i;
}

std::size_t clampi(std::int32_t v, std::size_t n) {
    return std::size_t(std::clamp<std::int64_t>(v, 0, std::int64_t(n)));
}

// Runs `f(u, caret, anchor)` on the decoded text and writes everything back; true when the text changed.
template <class F>
bool edit(State& s, F&& f) {
    U u = utf8_decode(s.text);
    std::size_t caret = clampi(s.caret, u.size()), anchor = clampi(s.anchor, u.size());
    const U before = u;
    f(u, caret, anchor);
    const bool changed = u != before;
    if (changed) {
        s.text.clear();
        for (const char32_t c : u) utf8_append(s.text, c);
    }
    s.caret = std::int32_t(caret);
    s.anchor = std::int32_t(anchor);
    return changed;
}

}  // namespace

std::int32_t length(const State& s) { return std::int32_t(std::min<std::size_t>(utf8_length(s.text), 1000000000)); }
bool has_selection(const State& s) { return s.caret != s.anchor; }
std::int32_t selection_min(const State& s) { return std::min(s.caret, s.anchor); }
std::int32_t selection_max(const State& s) { return std::max(s.caret, s.anchor); }

std::string selected_text(const State& s) {
    if (!has_selection(s)) return {};
    const U u = utf8_decode(s.text);
    const std::size_t a = clampi(selection_min(s), u.size()), b = clampi(selection_max(s), u.size());
    std::string out;
    for (std::size_t i = a; i < b; ++i) utf8_append(out, u[i]);
    return out;
}

void normalize(State& s) {
    s.caret = snap_to_boundary(s.text, s.caret);
    s.anchor = snap_to_boundary(s.text, s.anchor);
}

std::int32_t snap_to_boundary(const std::string& text, std::int32_t index) {
    const U u = utf8_decode(text);
    std::size_t i = clampi(index, u.size());
    while (i > 0 && !is_boundary(u, i)) --i;
    return std::int32_t(i);
}

std::string sanitize(std::string_view text, bool singleLine) {
    std::string out;
    for (std::size_t i = 0; i < text.size();) {
        const char32_t c = utf8_next(text, i);
        if (c == U'\n' || c == U'\r' || c == U'\t') {
            if (singleLine) continue;
            if (c == U'\t') continue;
            utf8_append(out, c == U'\r' ? U'\n' : c);
            continue;
        }
        if (c < 32 || c == 127 || (c >= 0x80 && c < 0xA0)) continue;
        utf8_append(out, c);
    }
    return out;
}

bool insert(State& s, std::string_view text, const Options& o) {
    const U add = utf8_decode(sanitize(text, o.singleLine));
    if (add.empty()) return false;
    return edit(s, [&](U& u, std::size_t& caret, std::size_t& anchor) {
        const std::size_t a = std::min(caret, anchor), b = std::max(caret, anchor);
        std::size_t room = add.size();
        if (o.maxLength > 0) {
            const std::size_t kept = u.size() - (b - a);
            room = kept >= std::size_t(o.maxLength) ? 0 : std::min(room, std::size_t(o.maxLength) - kept);
            while (room > 0 && room < add.size() && !is_boundary(add, room)) --room;  // never inside an emoji sequence
        }
        if (room == 0) return;
        u.replace(a, b - a, add.substr(0, room));
        caret = anchor = a + room;
    });
}

bool backspace(State& s, bool word) {
    return edit(s, [&](U& u, std::size_t& caret, std::size_t& anchor) {
        if (caret != anchor) {
            const std::size_t a = std::min(caret, anchor), b = std::max(caret, anchor);
            u.erase(a, b - a);
            caret = anchor = a;
            return;
        }
        if (caret == 0) return;
        const std::size_t from = word ? (s.oneWord ? 0 : word_left(u, caret)) : prev_boundary(u, caret);
        u.erase(from, caret - from);
        caret = anchor = from;
    });
}

bool del(State& s, bool word) {
    return edit(s, [&](U& u, std::size_t& caret, std::size_t& anchor) {
        if (caret != anchor) {
            const std::size_t a = std::min(caret, anchor), b = std::max(caret, anchor);
            u.erase(a, b - a);
            caret = anchor = a;
            return;
        }
        if (caret >= u.size()) return;
        const std::size_t to = word ? (s.oneWord ? u.size() : word_right(u, caret)) : next_boundary(u, caret);
        u.erase(caret, to - caret);
        anchor = caret;
    });
}

std::string cut(State& s) {
    std::string out = selected_text(s);
    if (!out.empty()) backspace(s, false);
    return out;
}

void move_left(State& s, bool word, bool extend) {
    edit(s, [&](U& u, std::size_t& caret, std::size_t& anchor) {
        if (!extend && caret != anchor) {
            caret = anchor = std::min(caret, anchor);
            return;
        }
        caret = word ? (s.oneWord ? 0 : word_left(u, caret)) : prev_boundary(u, caret);
        if (!extend) anchor = caret;
    });
}

void move_right(State& s, bool word, bool extend) {
    edit(s, [&](U& u, std::size_t& caret, std::size_t& anchor) {
        if (!extend && caret != anchor) {
            caret = anchor = std::max(caret, anchor);
            return;
        }
        caret = word ? (s.oneWord ? u.size() : word_right(u, caret)) : next_boundary(u, caret);
        if (!extend) anchor = caret;
    });
}

void move_home(State& s, bool extend) {
    s.caret = 0;
    if (!extend) s.anchor = 0;
}

void move_end(State& s, bool extend) {
    s.caret = length(s);
    if (!extend) s.anchor = s.caret;
}

void select_all(State& s) {
    s.anchor = 0;
    s.caret = length(s);
}

void select_word_at(State& s, std::int32_t index) {
    edit(s, [&](U& u, std::size_t& caret, std::size_t& anchor) {
        if (u.empty()) {
            caret = anchor = 0;
            return;
        }
        if (s.oneWord) {
            anchor = 0;
            caret = u.size();
            return;
        }
        std::size_t i = clampi(index, u.size());
        if (i >= u.size()) i = u.size() - 1;  // at the end: the last word
        const Cls c = cls(u[i]);
        std::size_t a = i, b = i + 1;
        while (a > 0 && cls(u[a - 1]) == c) --a;
        while (b < u.size() && cls(u[b]) == c) ++b;
        anchor = a;
        caret = b;
    });
}

void set_caret(State& s, std::int32_t index, bool extend) {
    s.caret = snap_to_boundary(s.text, index);
    if (!extend) s.anchor = s.caret;
}

}  // namespace fa::text_edit
