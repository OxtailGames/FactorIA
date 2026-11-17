// The editing model of a single-line TextField as pure functions over (UTF-8 text, caret, anchor): no World, no Input, no
// clipboard (the caller moves the selection in and out). Positions are CODE POINT indices into the text; the selection is
// the range between `anchor` and `caret` (equal = none), so a drag or Shift+arrow moves only `caret`.
//
// Graphemes: a caret never stops inside a cluster made of a base character and combining marks (U+0300..036F and the other
// combining blocks), variation selectors, emoji skin tones, tag characters, zero width joiner sequences (family and flag
// emoji) or a pair of regional indicators (a flag); CR LF is one too. Backspace and Delete remove the whole cluster. Not
// covered: Hangul jamo sequences, Indic conjuncts and other extended grapheme rules (they move one code point at a time).
#pragma once

#include <cstdint>
#include <string>
#include <string_view>

namespace fa::text_edit {

struct State {
    std::string text;
    std::int32_t caret = 0;   // code points from the start, 0..length
    std::int32_t anchor = 0;  // the fixed end of the selection; == caret when nothing is selected
    bool oneWord =
        false;  // a password: the whole text is one word (word moves go to its ends, a double click selects all)
};

struct Options {
    std::int32_t maxLength = 0;  // code points; 0 = unlimited
    bool singleLine = true;      // newlines and tabs are dropped from pasted and typed text
};

std::int32_t length(const State& s);  // code points of the text
bool has_selection(const State& s);
std::int32_t selection_min(const State& s);
std::int32_t selection_max(const State& s);
std::string selected_text(const State& s);

// Puts caret and anchor inside 0..length and moves them off the inside of a grapheme cluster.
void normalize(State& s);
// `index` moved to the nearest cluster boundary at or before it / after it.
std::int32_t snap_to_boundary(const std::string& text, std::int32_t index);

// What may be typed or pasted: control characters (and newlines / tabs in a single line field) are dropped.
std::string sanitize(std::string_view text, bool singleLine);
// Replaces the selection (or inserts at the caret) with `text` cut at maxLength; the caret ends after it. Returns
// true when
// the text changed. An empty `text` (after sanitize) changes nothing, not even a selection.
bool insert(State& s, std::string_view text, const Options& o);
// Backspace / Delete: remove the selection, else the cluster (or with `word` the word) before / after the caret.
bool backspace(State& s, bool word);
bool del(State& s, bool word);
// Removes the selection and returns it (what Cut copies); "" and no change when nothing is selected.
std::string cut(State& s);

// Arrow keys: with a selection and no `extend`, the caret goes to that side's end of the selection. `word` jumps a
// word.
void move_left(State& s, bool word, bool extend);
void move_right(State& s, bool word, bool extend);
void move_home(State& s, bool extend);
void move_end(State& s, bool extend);
void select_all(State& s);
// Selects the word (a run of letters and digits, of punctuation or of spaces) that code point `index` is part of (the
// character under the pointer: double-click); the whole text when the field is a password (one word).
void select_word_at(State& s, std::int32_t index);
// Puts the caret at `index` (a click, or a drag when `extend`: the anchor stays).
void set_caret(State& s, std::int32_t index, bool extend);

}  // namespace fa::text_edit
