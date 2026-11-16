// TextField editing: the keys, the clipboard, the pointer and the per-frame layout (scroll, IME caret rectangle). The model
// itself is text_edit.h; the geometry is fa/scene/text_field_view.h, shared with the renderer.
#include <algorithm>

#include "fa/core/utf8.h"
#include "fa/platform/ime.h"
#include "fa/scene/text_field_view.h"
#include "fa/ui/ui.h"
#include "text_edit.h"

namespace fa {

namespace {

constexpr float kMultiClickSeconds = 0.45f, kMultiClickPixels = 8.0f;

void emit_field(World& w, const char* name, Entity source, Json value) {
    Json data = Json::object({{"id", Json(w.id_of(source))}, {"value", std::move(value)}});
    w.events().game.push_back(GameEvent{name, std::move(data), source});
}

// A text measure for the field's font, like the one the renderer builds from its layout.
TextFieldMeasure field_measure(const TextField& tf, const VisualMeasure& m) {
    return [&tf, &m](const std::string& s) {
        Text t;
        t.text = s;
        t.font = tf.font;
        t.fontSize = tf.fontSize;
        t.maxTextScale = tf.maxTextScale;
        t.space = RenderSpace::Screen;
        return m.textSize ? m.textSize(t) : approx_text_size(t, m.textScale);
    };
}

}  // namespace

void UiSystem::field_sync(Entity e, TextField& tf, std::int32_t& caret, std::int32_t& anchor) {
    tf.clamp_indices();
    const std::int32_t n = std::int32_t(std::min<std::size_t>(utf8_length(tf.text), 1000000));
    const bool known = fieldMemo_.e == e;
    const bool textChanged = known && tf.text != fieldMemo_.text,
               caretMoved = known && tf.caretIndex != fieldMemo_.caret,
               selChanged = known && (tf.selectionStart != fieldMemo_.selStart || tf.selectionEnd != fieldMemo_.selEnd);
    if (selChanged && !caretMoved) {  // a script selected a range: the caret is its moving end
        caret = tf.selectionEnd;
        anchor = tf.selectionStart;
    } else if (caretMoved && !selChanged) {  // a script moved the caret: nothing stays selected
        caret = anchor = tf.caretIndex;
    } else if (textChanged && !caretMoved &&
               !selChanged) {  // a script wrote the text and left the caret: it goes to the end
        caret = anchor = n;
    } else {
        caret = tf.caretIndex;
        anchor = tf.selectionStart != tf.selectionEnd ? (caret == tf.selectionEnd     ? tf.selectionStart
                                                         : caret == tf.selectionStart ? tf.selectionEnd
                                                                                      : caret)
                                                      : caret;
    }
    text_edit::State st{tf.text, caret, anchor, tf.password};
    text_edit::normalize(st);
    caret = st.caret;
    anchor = st.anchor;
}

void UiSystem::field_store(Entity e, TextField& tf, std::int32_t caret, std::int32_t anchor) {
    tf.caretIndex = caret;
    tf.selectionStart = anchor;
    tf.selectionEnd = caret;
    // What the UI last wrote to the FOCUSED field: a commit into another field (the focus has just moved) must not point it back.
    if (fieldMemo_.e == e || !fieldMemo_.e) fieldMemo_ = FieldMemo{e, tf.text, caret, anchor, caret};
}

void UiSystem::field_focus(World& w, Entity e) {
    TextField* tf = w.get<TextField>(e);
    fieldMemo_ = FieldMemo{};
    if (!tf) return;
    const std::int32_t n = std::int32_t(std::min<std::size_t>(utf8_length(tf->text), 1000000));
    field_store(e, *tf, n, n);
}

void UiSystem::field_keys(World& w, Entity e, TextField& tf, Input& in, float dt) {
    std::int32_t caret = 0, anchor = 0;
    field_sync(e, tf, caret, anchor);
    text_edit::State st{tf.text, caret, anchor, tf.password};
    const text_edit::Options opt{tf.maxLength, true};
    const bool shift = in.modifier_down(modifier::Shift), word = in.word_modifier_down(), composing = in.composing();
    bool changed = false;
    // A Ctrl or Cmd chord (Ctrl+V) is a command, not typing; Ctrl+Alt is AltGr, which does type.
    const bool chord = (in.key_down(Key::LeftControl) || in.key_down(Key::RightControl) ||
                        in.key_down(Key::LeftSuper) || in.key_down(Key::RightSuper)) &&
                       !in.key_down(Key::LeftAlt) && !in.key_down(Key::RightAlt);
    if (!chord) {
        std::string typed;
        for (const char32_t c : in.text_input()) {
            if (c < 32 || c == 127 || c > 0x10FFFF || (c >= 0xD800 && c <= 0xDFFF)) continue;
            utf8_append(typed, c);
        }
        changed = text_edit::insert(st, typed, opt) || changed;
    }
    if (clipboard_ && in.paste_pressed()) changed = text_edit::insert(st, clipboard_->get(), opt) || changed;
    if (in.select_all_pressed()) text_edit::select_all(st);
    if (clipboard_ && !tf.password && text_edit::has_selection(st)) {
        if (in.copy_pressed()) clipboard_->set(text_edit::selected_text(st));
        if (in.cut_pressed()) {
            clipboard_->set(text_edit::cut(st));
            changed = true;
        }
    }
    const bool back = backspace_.tick(in.key_pressed(Key::Backspace), in.key_down(Key::Backspace), dt);
    const bool forward = delete_.tick(in.key_pressed(Key::Delete), in.key_down(Key::Delete), dt);
    if (!composing) {  // the input method owns these keys while it composes
        if (back) changed = text_edit::backspace(st, word) || changed;
        if (forward) changed = text_edit::del(st, word) || changed;
        if (in.key_pressed(Key::Home)) text_edit::move_home(st, shift);
        if (in.key_pressed(Key::End)) text_edit::move_end(st, shift);
    }
    if (changed || st.caret != caret || st.anchor != anchor) {
        caretStart_ = clock_;
        tf.text = st.text;
        field_store(e, tf, st.caret, st.anchor);
    }
    if (changed) emit_field(w, "ui.change", e, Json(tf.text));
}

void UiSystem::field_arrow(World&, Entity e, TextField& tf, Input& in, bool left) {
    if (in.composing()) return;
    std::int32_t caret = 0, anchor = 0;
    field_sync(e, tf, caret, anchor);
    text_edit::State st{tf.text, caret, anchor, tf.password};
    const bool shift = in.modifier_down(modifier::Shift), word = in.word_modifier_down();
    if (left)
        text_edit::move_left(st, word, shift);
    else
        text_edit::move_right(st, word, shift);
    field_store(e, tf, st.caret, st.anchor);
    caretStart_ = clock_;
}

void UiSystem::field_pointer(World& w, Entity e, TextField& tf, Input& in, Vec2 design, Vec2 mouse, bool pressed,
                             bool down, const VisualMeasure& measure) {
    if (!pressed && !down) return;
    const std::optional<Rect> px = ui_own_rect(w, e, design), units = ui_layout_rect(w, e, design);
    if (!px || !units) return;
    // A click on the field the composition began in commits it (typed once); one that moves the focus here leaves it to the
    // focus change, which commits it into the field it began in.
    if (pressed && in.composing() && imeField_ == e) {
        field_commit_composition(w, e, in);
        if (imeOn_) ime_cancel();
    }
    const float k = ui_scale_clamped(w.ui_scale());
    const TextFieldMeasure m = field_measure(tf, measure);
    const Rect local{0, 0, units->w, units->h};
    const float x =
        (ui_local_point(w, e, design, mouse).x - px->x) / k;  // a turned field: the pointer in its own frame
    const std::int32_t index = text_field_index_at(tf, local, m, x);
    std::int32_t caret = 0, anchor = 0;
    field_sync(e, tf, caret, anchor);
    text_edit::State st{tf.text, caret, anchor, tf.password};
    if (pressed) {
        const bool again = clickField_ == e && clock_ - clickTime_ <= kMultiClickSeconds &&
                           std::abs(mouse.x - clickPos_.x) <= kMultiClickPixels &&
                           std::abs(mouse.y - clickPos_.y) <= kMultiClickPixels;
        clickCount_ = again ? clickCount_ + 1 : 1;
        clickField_ = e;
        clickTime_ = clock_;
        clickPos_ = mouse;
        if (clickCount_ == 2)
            text_edit::select_word_at(st, text_field_char_at(tf, local, m, x));
        else if (clickCount_ >= 3)
            text_edit::select_all(st);
        else
            text_edit::set_caret(st, index, in.modifier_down(modifier::Shift));
    } else if (clickCount_ < 2) {
        text_edit::set_caret(st, index, true);  // a drag moves the caret, the anchor stays where the press was
    } else {
        return;  // after a double click the word stays selected
    }
    field_store(e, tf, st.caret, st.anchor);
    caretStart_ = clock_;
}

void UiSystem::field_commit_composition(World& w, Entity e, Input& in) {
    std::string typed;
    for (const char32_t c : in.composition_text()) utf8_append(typed, c);
    // The text is typed below, at the caret it was composed at: Input must not deliver it a second time.
    in.on_composition_cancel();
    TextField* tf = e && w.alive(e) ? w.get<TextField>(e) : nullptr;
    if (!tf || typed.empty()) return;
    std::int32_t caret = 0, anchor = 0;
    field_sync(e, *tf, caret, anchor);
    text_edit::State st{tf->text, caret, anchor, tf->password};
    const bool changed = text_edit::insert(st, typed, text_edit::Options{tf->maxLength, true});
    tf->text = st.text;
    field_store(e, *tf, st.caret, st.anchor);
    caretStart_ = clock_;
    if (changed) emit_field(w, "ui.change", e, Json(tf->text));
}

void UiSystem::field_frame(World& w, Entity e, TextField& tf, Input& in, Vec2 design, const VisualMeasure& measure) {
    // A script may have written the text, caret or selection since the last frame: then they are read, fixed and written back.
    // Nothing changed (the usual frame) costs a comparison, not a copy of the text.
    const bool untouched = fieldMemo_.e == e && tf.caretIndex == fieldMemo_.caret &&
                           tf.selectionStart == fieldMemo_.selStart && tf.selectionEnd == fieldMemo_.selEnd &&
                           tf.text == fieldMemo_.text;
    if (!untouched) {
        std::int32_t caret = 0, anchor = 0;
        field_sync(e, tf, caret, anchor);
        field_store(e, tf, caret, anchor);
    }
    tf.compositionCaret = in.composing() ? in.composition_caret() : 0;
    tf.compositionSelection = in.composing() ? in.composition_selection_length() : 0;
    const std::optional<Rect> px = ui_own_rect(w, e, design), units = ui_layout_rect(w, e, design);
    if (!px || !units) return;
    const TextFieldView v = text_field_view(tf, Rect{0, 0, units->w, units->h}, field_measure(tf, measure));
    tf.scrollX = v.scroll;
    const float k = ui_scale_clamped(w.ui_scale());
    const float x = std::clamp(v.caretX, v.inner.x, v.inner.x + v.inner.w);
    imeCaret_ = Rect{px->x + x * k, px->y + v.lineY * k, kTextFieldCaretWidth * k, v.lineH * k};
    if (!ui_transform(w, e, design).is_identity()) {  // a turned field: the bounding box of the caret bar as drawn
        const Vec2 c0 = ui_world_point(w, e, design, {imeCaret_.x, imeCaret_.y});
        const Vec2 c1 = ui_world_point(w, e, design, {imeCaret_.x + imeCaret_.w, imeCaret_.y + imeCaret_.h});
        const Vec2 c2 = ui_world_point(w, e, design, {imeCaret_.x + imeCaret_.w, imeCaret_.y});
        const Vec2 c3 = ui_world_point(w, e, design, {imeCaret_.x, imeCaret_.y + imeCaret_.h});
        const float x0 = std::min({c0.x, c1.x, c2.x, c3.x}), y0 = std::min({c0.y, c1.y, c2.y, c3.y});
        imeCaret_ = Rect{x0, y0, std::max({c0.x, c1.x, c2.x, c3.x}) - x0, std::max({c0.y, c1.y, c2.y, c3.y}) - y0};
    }
    imeCaretValid_ = true;
}

}  // namespace fa
