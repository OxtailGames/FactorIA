// Draws the game UI widgets (Panel, Button, Toggle, Slider, TextField, ScrollList, TouchStick, TouchButton) into the
// screen quad list. Where a widget is comes from fa_scene's ui_rect.h (the same code behind layout and hit-testing); how
// it reacts (focus, hover, values) is fa_ui's, read here from the components' runtime flags.
#include <algorithm>
#include <cmath>
#include <format>

#include "fa/scene/ui_rect.h"
#include "frame.h"
#include "nine_slice.h"

namespace fa::render {

bool screen_clip(const World& world, Entity e, const Frame& f, Rect& clip) {
    clip = Rect{};
    const std::optional<Rect> c = ui_clip_rect(world, e, Vec2{float(f.targetW), float(f.targetH)});
    if (!c) return true;
    clip = *c;
    return !c->empty();
}

namespace {

// What one widget draws into: the screen list, the clip of its ScrollList ancestors and the fade of a widget that is not
// interactable.
struct Ctx {
    Frame& f;
    Rect clip;
    float fade = 1.0f;
    QuadList& list() const { return f.screen; }
};

std::uint32_t pack(Color c, float fade) {
    c.a *= fade;
    return pack_color(c);
}

// A screen rectangle (y down) with its uv rectangle; skipped when it has no area.
void quad(const Ctx& c, float x0, float y0, float x1, float y1, float u0, float v0, float u1, float v1, std::uint32_t col) {
    if (x1 <= x0 || y1 <= y0) return;
    QuadEmitter{c.list(), Mat4::identity(), true, col, kModeTextured, 0}.rect(x0, -y1, x1, -y0, u0, v0, u1, v1);
}

void fill(const Ctx& c, int layer, const Rect& r, Color col, const Rect& clip) {
    c.list().begin_item(layer, 0, c.f.assets->white(), SamplerKind::Nearest, BlendMode::Alpha, clip);
    quad(c, r.x, r.y, r.x + r.w, r.y + r.h, 0, 0, 1, 1, pack(col, c.fade));
    c.list().end_item();
}

// A rectangle outline `t` pixels thick that grows inward.
void outline(const Ctx& c, int layer, const Rect& r, float t, Color col) {
    t = std::min(t, std::min(r.w, r.h) * 0.5f);
    const float x1 = r.x + r.w, y1 = r.y + r.h;
    const std::uint32_t k = pack(col, c.fade);
    c.list().begin_item(layer, 0, c.f.assets->white(), SamplerKind::Nearest, BlendMode::Alpha, c.clip);
    quad(c, r.x, r.y, x1, r.y + t, 0, 0, 1, 1, k);
    quad(c, r.x, y1 - t, x1, y1, 0, 0, 1, 1, k);
    quad(c, r.x, r.y + t, r.x + t, y1 - t, 0, 0, 1, 1, k);
    quad(c, x1 - t, r.y + t, x1, y1 - t, 0, 0, 1, 1, k);
    c.list().end_item();
}

// The widget's background: the whole rectangle in `tint`, or the texture as a 9-slice. The corners keep their size (one
// texture pixel = one design pixel), the edges stretch along one axis and the centre along both; borders that do not fit
// shrink together. Every edge is rounded to a whole pixel so a texture is never resampled between texels.
void background(const Ctx& c, const UiBox& b, const Rect& r, Color tint) {
    const bool textured = !b.texture.empty();
    TextureAsset* tex = textured ? c.f.assets->texture(b.texture) : c.f.assets->white();
    float border[4] = {0, 0, 0, 0}, uvBorder[4] = {0, 0, 0, 0};  // left, top, right, bottom: on screen and in uv
    if (textured)
        nine_slice_fit(b.slice, float(std::max(1, tex->width)), float(std::max(1, tex->height)), r.w, r.h, border, uvBorder);
    const float xs[4] = {std::round(r.x), std::round(r.x + border[0]), std::round(r.x + r.w - border[2]), std::round(r.x + r.w)};
    const float ys[4] = {std::round(r.y), std::round(r.y + border[1]), std::round(r.y + r.h - border[3]), std::round(r.y + r.h)};
    const float us[4] = {0, uvBorder[0], 1 - uvBorder[2], 1}, vs[4] = {0, uvBorder[1], 1 - uvBorder[3], 1};
    c.list().begin_item(b.layer, 0, tex, SamplerKind::Nearest, BlendMode::Alpha, c.clip);
    for (int j = 0; j < 3; ++j)
        for (int i = 0; i < 3; ++i) {
            // Inside the atlas when the texture is packed (an export's `atlas` import setting).
            const Vec2 lo = tex->uv(us[i] * float(tex->width), vs[j] * float(tex->height));
            const Vec2 hi = tex->uv(us[i + 1] * float(tex->width), vs[j + 1] * float(tex->height));
            quad(c, xs[i], ys[j], xs[i + 1], ys[j + 1], lo.x, lo.y, hi.x, hi.y, pack(tint, c.fade));
        }
    c.list().end_item();
}

// A single line of text laid out with the widget's font; `top-left` is placed by text().
TextLayout line(const Ctx& c, const std::string& s, const std::string& font, float size, float maxWidth = 0.0f,
                Align align = Align::Left) {
    Text t;
    t.text = s;
    t.font = font;
    t.fontSize = size;
    t.pivot = {0, 1};
    t.maxWidth = maxWidth;
    t.align = align;
    // Same layout as screen-space Text at scale 1, including the player's text size option.
    return c.f.fonts->layout(t, size * c.f.textScale, c.f.renderScale);
}

void text(const Ctx& c, const TextLayout& lay, float x, float y, Color col, int layer, const Rect& clip) {
    if (lay.quads.empty()) return;
    c.list().begin_item(layer, 0, c.f.fonts->atlas(), SamplerKind::Linear, BlendMode::Alpha, clip);
    QuadEmitter em{c.list(), Mat4::translate({std::round(x), std::round(y), 0}), true, pack(col, c.fade), kModeGlyph, 0};
    for (const TextQuad& q : lay.quads) em.rect(q.x0, q.y0, q.x1, q.y1, q.u0, q.v0, q.u1, q.v1);
    c.list().end_item();
    c.f.stats->textGlyphs += int(lay.quads.size());
}

// Text of the given height box vertically centred in `r`, its left edge at `x`.
void text_left(const Ctx& c, const std::string& s, const std::string& font, float size, Color col, int layer, float x, const Rect& r,
               const Rect& clip) {
    if (s.empty()) return;
    const TextLayout lay = line(c, s, font, size);
    text(c, lay, x, r.y + (r.h - lay.size.y) * 0.5f, col, layer, clip);
}

Color scaled(Color k, float mul, float add) { return {k.r * mul + add, k.g * mul + add, k.b * mul + add, k.a}; }
Color with_alpha(Color k, float a) { return {k.r, k.g, k.b, k.a * a}; }

// A disc (an ellipse when `r` is not square) filling `r`.
void disc(const Ctx& c, int layer, const Rect& r, Color col) {
    if (r.empty()) return;
    c.list().begin_item(layer, 0, c.f.assets->white(), SamplerKind::Nearest, BlendMode::Alpha, c.clip);
    QuadEmitter{c.list(), Mat4::identity(), true, pack(col, c.fade), kModeCircle, 0}.rect(r.x, -(r.y + r.h), r.x + r.w, -r.y, -1, -1, 1, 1);
    c.list().end_item();
}

// TouchStick / TouchButton: the background is the texture when there is one, else a disc; then the knob or the label.
void draw_touch_control(const Ctx& c, const World& world, Entity e, const UiBox& b, const Rect& r) {
    const TouchStick* stick = world.get<TouchStick>(e);
    const TouchButton* button = world.get<TouchButton>(e);
    if (stick ? !stick->shown : !button->shown) return;
    const Color tint = button && button->pressed ? scaled(b.color, 0.6f, 0.0f) : b.color;
    if (!b.texture.empty()) background(c, b, r, tint);
    else disc(c, b.layer, r, tint);
    if (stick) {
        const float radius = std::min(r.w, r.h) * 0.5f, knob = radius * 0.45f;
        const Vec2 at = r.center() + Vec2{stick->value.x, -stick->value.y} * radius;
        disc(c, b.layer + 1, Rect::from_center(at, {knob * 2, knob * 2}), stick->knobColor);
    } else if (!button->text.empty()) {
        const TextLayout lay = line(c, button->text, button->font, button->fontSize);
        text(c, lay, r.x + (r.w - lay.size.x) * 0.5f, r.y + (r.h - lay.size.y) * 0.5f, button->textColor, b.layer + 1, c.clip);
    }
}

void draw_widget(Frame& f, const World& world, Entity e, UiKind kind, const UiBox& b) {
    Ctx c{f, Rect{}};
    if (!screen_clip(world, e, f, c.clip)) return;
    const Rect r = *ui_rect(world, e, Vec2{float(f.targetW), float(f.targetH)});
    if (kind == UiKind::TouchStick || kind == UiKind::TouchButton) return draw_touch_control(c, world, e, b, r);
    const UiControl* ctl = ui_control(world, e);
    Color tint = b.color;
    if (ctl) {
        if (!ctl->interactable) c.fade = 0.5f;
        else if (ctl->pressed) tint = scaled(tint, 0.8f, 0.0f);
        else if (ctl->hovered) tint = scaled(tint, 1.15f, 0.04f);
    }
    background(c, b, r, tint);
    const int layer = b.layer + 1;  // labels and marks; the focus ring is one more
    if (kind == UiKind::Button) {
        const Button& btn = *world.get<Button>(e);
        // Every line centred (also inside a wrap box); a label that does not fit is cut at the button's edge.
        const TextLayout lay = line(c, btn.text, btn.font, btn.fontSize, btn.maxWidth, Align::Center);
        const Rect clip = c.clip.empty() ? r : ui_intersect(r, c.clip);
        if (!clip.empty())
            text(c, lay, r.x + (r.w - lay.size.x) * 0.5f, r.y + (r.h - lay.size.y) * 0.5f, btn.textColor, layer, clip);
    } else if (kind == UiKind::Toggle) {
        const Toggle& t = *world.get<Toggle>(e);
        const float side = std::max(0.0f, r.h - 12.0f);
        const Rect box{r.x + 6, r.y + 6, side, side};
        fill(c, layer, box, with_alpha(t.textColor, 0.25f), c.clip);
        outline(c, layer, box, 2, t.textColor);
        if (t.value) fill(c, layer, Rect{box.x + 5, box.y + 5, std::max(0.0f, side - 10), std::max(0.0f, side - 10)}, t.accentColor, c.clip);
        text_left(c, t.label, t.font, t.fontSize, t.textColor, layer, box.x + side + 10, r, c.clip);
    } else if (kind == UiKind::Slider) {
        const Slider& s = *world.get<Slider>(e);
        const float innerLeft = r.x + 8, innerW = std::max(0.0f, r.w - 16);
        const auto [left, right] = ui_slider_track(s, r);
        const float span = s.max - s.min, t = span > 0 ? std::clamp((s.value - s.min) / span, 0.0f, 1.0f) : 0.0f;
        const float knobX = left + (right - left) * t, midY = r.y + r.h * 0.5f;
        fill(c, layer, Rect{left, midY - 3, right - left, 6}, with_alpha(s.textColor, 0.25f), c.clip);
        fill(c, layer, Rect{left, midY - 3, knobX - left, 6}, s.accentColor, c.clip);
        fill(c, layer, Rect{knobX - 5, midY - std::min(12.0f, (r.h - 8) * 0.5f), 10, std::min(24.0f, r.h - 8)}, s.accentColor, c.clip);
        text_left(c, s.label, s.font, s.fontSize, s.textColor, layer, innerLeft, r, c.clip);
        if (s.showValue) {
            const TextLayout lay = line(c, ui_slider_value_text(s, s.value),s.font, s.fontSize);
            const float zone = innerLeft + innerW * 0.85f;
            text(c, lay, zone + (innerLeft + innerW - zone - lay.size.x) * 0.5f, r.y + (r.h - lay.size.y) * 0.5f, s.textColor, layer, c.clip);
        }
    } else if (kind == UiKind::TextField) {
        const TextField& tf = *world.get<TextField>(e);
        const Rect inner{r.x + 12, r.y, std::max(0.0f, r.w - 24), r.h};
        const Rect clip = c.clip.empty() ? inner : ui_intersect(inner, c.clip);  // the text never leaves the field
        if (!clip.empty()) {
            const bool empty = tf.text.empty();
            const TextLayout lay = line(c, empty ? tf.placeholder : tf.text, tf.font, tf.fontSize);
            const float width = empty ? 0.0f : lay.size.x, x = inner.x + std::min(0.0f, inner.w - width);  // long text shows its end
            const float y = r.y + (r.h - lay.size.y) * 0.5f;
            text(c, lay, empty ? inner.x : x, y, with_alpha(tf.textColor, empty ? 0.5f : 1.0f), layer, clip);
            if (tf.caret) fill(c, layer, Rect{x + width + 1, y + 2, 2, std::max(0.0f, lay.size.y - 4)}, tf.accentColor, clip);
        }
    }
    if (ctl && ctl->focused && ctl->interactable) outline(c, b.layer + 2, r, 3, ctl->accentColor);
}

// Parents before children, siblings in order: a Panel is drawn before the widgets on it when their layers are equal.
void visit(Frame& f, const World& world, Entity e) {
    if (!world.info(e).active) return;
    if (const UiKind kind = ui_kind(world, e); kind != UiKind::None) draw_widget(f, world, e, kind, *ui_box(world, e));
    for (Entity child : world.children(e)) visit(f, world, child);
}

}  // namespace

void gather_ui(World& world, Frame& f) {
    bool any = false;
    for (const TypeInfo* t : {&World::type_of<Panel>(), &World::type_of<Button>(), &World::type_of<Toggle>(), &World::type_of<Slider>(),
                              &World::type_of<TextField>(), &World::type_of<ScrollList>(), &World::type_of<TouchStick>(),
                              &World::type_of<TouchButton>()})
        any = any || !world.entities_with(t).empty();
    if (!any) return;
    for (Entity root : world.roots()) visit(f, world, root);
}

}  // namespace fa::render
