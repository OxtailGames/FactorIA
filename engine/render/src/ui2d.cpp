// Draws the game UI widgets (Panel, Button, Toggle, Slider, TextField, ScrollList, TouchStick, TouchButton, Captions, Video, Chart) into the
// screen quad list. Where a widget is comes from fa_scene's ui_rect.h (the same code behind layout and hit-testing); how
// it reacts (focus, hover, values) is fa_ui's, read here from the components' runtime flags.
//
// The interface scale (ui.scale, ui_rect.h): a widget is drawn in UI units, the rectangle of ui_layout_rect and fixed margins
// and line widths included, and every quad is scaled by Ctx::k when it is emitted. Text is rasterized at k times the size
// (a pixels-per-unit of renderScale * k), so it stays sharp. Scissor rectangles (clip) are in screen pixels.
#include <algorithm>
#include <cmath>
#include <format>
#include <vector>

#include "fa/scene/chart.h"
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

TextExtent frame_text_extent(Frame& f, float ppu) {
    return [&f, ppu](const std::string& s, const std::string& font, float px, float wrap, TextStyle style) {
        Text probe;
        probe.text = s;
        probe.font = font;
        probe.maxWidth = wrap;
        probe.markup = style.markup;
        probe.bold = style.bold;
        return f.fonts->layout(probe, px, ppu).size;
    };
}

namespace {

// What one widget draws into: the screen list, the clip of its ScrollList ancestors and the fade of a widget that is not
// interactable.
struct Ctx {
    Frame& f;
    Rect clip;
    float fade = 1.0f;
    float capScale = 0.0f;  // the widget's maxTextScale (0 = none): line() draws its labels at most at this text scale
    float k = 1.0f;         // the interface scale: UI units -> screen pixels
    TextDirection dir = TextDirection::Auto;  // base direction of the labels: the language's for a widget with a localization key
    QuadList& list() const { return f.screen; }
    Mat4 to_screen() const { return Mat4::scale({k, k, 1.0f}); }
};

// A UI coordinate rounded so it lands on a whole screen pixel once scaled by k.
float snap(const Ctx& c, float v) { return std::round(v * c.k) / c.k; }
// A rectangle of UI units as screen pixels (for the scissor).
Rect to_pixels(const Ctx& c, const Rect& r) { return Rect{r.x * c.k, r.y * c.k, r.w * c.k, r.h * c.k}; }

std::uint32_t pack(Color c, float fade) {
    c.a *= fade;
    return pack_color(c);
}

// A screen rectangle (y down) with its uv rectangle; skipped when it has no area.
void quad(const Ctx& c, float x0, float y0, float x1, float y1, float u0, float v0, float u1, float v1, std::uint32_t col) {
    if (x1 <= x0 || y1 <= y0) return;
    QuadEmitter{c.list(), c.to_screen(), true, col, kModeTextured, 0}.rect(x0, -y1, x1, -y0, u0, v0, u1, v1);
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
// texture pixel = one UI unit), the edges stretch along one axis and the centre along both; borders that do not fit
// shrink together. Every edge is rounded to a whole pixel so a texture is never resampled between texels.
void background(const Ctx& c, const UiBox& b, const Rect& r, Color tint) {
    const bool textured = !b.texture.empty();
    TextureAsset* tex = textured ? c.f.assets->texture(b.texture) : c.f.assets->white();
    float border[4] = {0, 0, 0, 0}, uvBorder[4] = {0, 0, 0, 0};  // left, top, right, bottom: on screen and in uv
    if (textured)
        nine_slice_fit(b.slice, float(std::max(1, tex->width)), float(std::max(1, tex->height)), r.w, r.h, border, uvBorder);
    const float xs[4] = {snap(c, r.x), snap(c, r.x + border[0]), snap(c, r.x + r.w - border[2]), snap(c, r.x + r.w)};
    const float ys[4] = {snap(c, r.y), snap(c, r.y + border[1]), snap(c, r.y + r.h - border[3]), snap(c, r.y + r.h)};
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

// A single line of text laid out with the widget's font; `top-left` is placed by text(). `size` is the design font size:
// it is drawn at the player's text size capped by the widget's maxTextScale, or at `px` (> 0) when autoShrink decided one.
TextLayout line(const Ctx& c, const std::string& s, const std::string& font, float size, float maxWidth = 0.0f,
                Align align = Align::Left, float px = 0.0f, TextStyle style = {}) {
    Text t;
    t.text = s;
    t.markup = style.markup;
    t.bold = style.bold;
    t.font = font;
    t.fontSize = size;
    t.pivot = {0, 1};
    t.maxWidth = maxWidth;
    t.align = align;
    t.direction = c.dir;
    // Same layout as screen-space Text at scale 1, including the player's text size option.
    return c.f.fonts->layout(t, px > 0.0f ? px : size * effective_text_scale(c.f.textScale, c.capScale), c.f.renderScale * c.k, true);
}

// The font size of the label of widget `e` in rectangle `r`: autoShrink decides it from the laid-out size (fit_text, the same
// code as ui.overflowed), else it is the design size at the capped text scale. 0 = no label.
float label_px(const Ctx& c, const World& world, Entity e, const Rect& r) {
    const std::optional<UiLabelFit> l = ui_label_fit(world, e, r, c.f.textScale, frame_text_extent(c.f, c.f.uiScale));
    return l ? l->fit.px : 0.0f;
}

void text(const Ctx& c, const TextLayout& lay, float x, float y, Color col, int layer, const Rect& clip) {
    if (lay.quads.empty() && lay.icons.empty()) return;
    col.a *= c.fade;
    emit_text(c.list(), Mat4::translate({std::round(x * c.k), std::round(y * c.k), 0}) * c.to_screen(), true, lay, col, *c.f.fonts,
              *c.f.assets, layer, 0, clip);
    c.f.stats->textGlyphs += int(lay.quads.size());
}

// A label (wrapped at `maxWidth` > 0, left aligned) vertically centred in `zoneY .. zoneY + zoneH`, its left edge at `x`.
// `px` > 0 is the size autoShrink decided.
void text_left(const Ctx& c, const std::string& s, const std::string& font, float size, float maxWidth, float px, Color col, int layer,
               float x, float zoneY, float zoneH, const Rect& clip, TextStyle style = {}) {
    if (s.empty()) return;
    const TextLayout lay = line(c, s, font, size, maxWidth, Align::Left, px, style);
    text(c, lay, x, zoneY + (zoneH - lay.size.y) * 0.5f, col, layer, clip);
}

// The same, its RIGHT edge at `x` (a mirrored widget's label).
void text_right(const Ctx& c, const std::string& s, const std::string& font, float size, float maxWidth, float px, Color col, int layer,
                float x, float zoneY, float zoneH, const Rect& clip, TextStyle style = {}) {
    if (s.empty()) return;
    const TextLayout lay = line(c, s, font, size, maxWidth, Align::Left, px, style);
    text(c, lay, x - lay.size.x, zoneY + (zoneH - lay.size.y) * 0.5f, col, layer, clip);
}

// A Button's icon: its region of the texture (whole texture for a zero-size region) stretched over `dst`.
void icon(const Ctx& c, const Button& b, const Rect& dst, int layer, const Rect& clip) {
    if (dst.empty()) return;
    TextureAsset* tex = c.f.assets->texture(b.icon);
    const Rect& reg = b.iconRegion;
    const bool whole = reg.w <= 0 || reg.h <= 0;
    const float tw = float(std::max(1, tex->width)), th = float(std::max(1, tex->height));
    const Vec2 lo = tex->uv(whole ? 0.0f : reg.x, whole ? 0.0f : reg.y);
    const Vec2 hi = tex->uv(whole ? tw : reg.x + reg.w, whole ? th : reg.y + reg.h);
    c.list().begin_item(layer, 0, tex, SamplerKind::Linear, BlendMode::Alpha, clip);
    quad(c, snap(c, dst.x), snap(c, dst.y), snap(c, dst.x + dst.w), snap(c, dst.y + dst.h), lo.x, lo.y, hi.x, hi.y,
         pack(Color{1, 1, 1, 1}, c.fade));
    c.list().end_item();
}

Color scaled(Color k, float mul, float add) { return {k.r * mul + add, k.g * mul + add, k.b * mul + add, k.a}; }
Color with_alpha(Color k, float a) { return {k.r, k.g, k.b, k.a * a}; }

// A disc (an ellipse when `r` is not square) filling `r`.
void disc(const Ctx& c, int layer, const Rect& r, Color col) {
    if (r.empty()) return;
    c.list().begin_item(layer, 0, c.f.assets->white(), SamplerKind::Nearest, BlendMode::Alpha, c.clip);
    QuadEmitter{c.list(), c.to_screen(), true, pack(col, c.fade), kModeCircle, 0}.rect(r.x, -(r.y + r.h), r.x + r.w, -r.y, -1, -1, 1, 1);
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
        const TextLayout lay = line(c, button->text, button->font, button->fontSize, 0.0f, Align::Left,
                                    button->autoShrink ? label_px(c, world, e, r) : 0.0f, {button->markup, button->bold});
        text(c, lay, r.x + (r.w - lay.size.x) * 0.5f, r.y + (r.h - lay.size.y) * 0.5f, button->textColor, b.layer + 1, c.clip);
    }
}

// Captions: the newest lines (Captions.lines, written by the engine) in a block at the bottom of the rectangle, on a
// background that hugs them. Each line is "Speaker:" in speakerColor then the text; a long text wraps and its next lines stay
// under the first one's text. In a right-to-left language the speaker goes to the right of the text.
void draw_captions(const Ctx& c, const World& world, const Captions& cap, const UiBox& b, const Rect& r) {
    if (!cap.lines.is_array() || cap.lines.empty()) return;
    const bool rtl = world.rtl();
    Align a = cap.align;  // start / end are the edges of the current language's direction; the font layer only knows left / right
    if (a == Align::Start || a == Align::End) a = (a == Align::Start) != rtl ? Align::Left : Align::Right;
    const float padL = cap.padding.x, padT = cap.padding.y, padR = cap.padding.z, padB = cap.padding.w;
    const float availW = std::max(1.0f, r.w - padL - padR);
    const float gap = cap.fontSize * c.f.textScale * 0.35f;
    struct Entry {
        TextLayout speaker, body;
        float speakerW = 0, w = 0, h = 0;
    };
    std::vector<Entry> entries;
    float contentW = 0, contentH = 0;
    for (const Json& j : cap.lines) {
        if (!j.is_object()) continue;
        Entry e;
        const std::string speaker = j.value("speaker", std::string()), text = j.value("text", std::string());
        if (!speaker.empty()) {
            e.speaker = line(c, speaker + ":", cap.font, cap.fontSize);
            e.speakerW = e.speaker.size.x + gap;
        }
        const float limit = std::max(availW - e.speakerW, cap.fontSize * c.f.textScale * 2.0f);
        e.body = line(c, text, cap.font, cap.fontSize);
        if (e.body.size.x > limit) e.body = line(c, text, cap.font, cap.fontSize, limit, a);
        e.w = e.speakerW + e.body.size.x;
        e.h = std::max(e.speaker.size.y, e.body.size.y);
        contentW = std::max(contentW, e.w);
        contentH += e.h + (entries.empty() ? 0.0f : cap.spacing);
        entries.push_back(std::move(e));
    }
    if (entries.empty()) return;
    const float w = std::min(r.w, contentW + padL + padR), h = contentH + padT + padB;
    const float x = a == Align::Left ? r.x : a == Align::Right ? r.x + r.w - w : r.x + (r.w - w) * 0.5f;
    const Rect box{x, r.y + r.h - h, w, h};
    background(c, b, box, b.color);
    float y = box.y + padT;
    for (const Entry& e : entries) {
        const float room = box.w - padL - padR;
        const float ex = box.x + padL + (a == Align::Left ? 0.0f : a == Align::Right ? room - e.w : (room - e.w) * 0.5f);
        if (rtl) {
            text(c, e.body, ex, y, cap.textColor, b.layer + 1, c.clip);
            if (!e.speaker.quads.empty()) text(c, e.speaker, ex + e.w - e.speaker.size.x, y, cap.speakerColor, b.layer + 1, c.clip);
        } else {
            if (!e.speaker.quads.empty()) text(c, e.speaker, ex, y, cap.speakerColor, b.layer + 1, c.clip);
            text(c, e.body, ex + e.speakerW, y, cap.textColor, b.layer + 1, c.clip);
        }
        y += e.h + cap.spacing;
    }
}

// A Video: its background, then its picture inside its rectangle `r`: `contain` shows all of it with bars, `cover` fills the
// rectangle and crops what overflows (by uv, so nothing is drawn outside), `stretch` ignores the aspect ratio. The
// background is left out when the picture hides all of it (opaque, over every pixel the background fills): a full-screen
// video would otherwise fill the screen twice. An opaque picture is drawn without blending. Only the background is drawn
// while the file is not open (a missing or unplayable file).
void draw_video(const Ctx& c, const Video& v, const UiBox& b, const Rect& r) {
    if (!v.rt.decoder || r.w <= 0 || r.h <= 0) return background(c, b, r, b.color);
    TextureAsset* tex = c.f.assets->video_texture(v.rt.decoder);
    const float pw = float(std::max(1, tex->width)), ph = float(std::max(1, tex->height));
    Rect dst = r;
    float u0 = 0, v0 = 0, u1 = 1, v1 = 1;
    if (v.fit == VideoFit::Contain) {
        const float s = std::min(r.w / pw, r.h / ph);
        dst = Rect{r.x + (r.w - pw * s) * 0.5f, r.y + (r.h - ph * s) * 0.5f, pw * s, ph * s};
    } else if (v.fit == VideoFit::Cover) {
        const float s = std::max(r.w / pw, r.h / ph);
        const float visibleU = r.w / (pw * s), visibleV = r.h / (ph * s);  // fractions of the picture that fit
        u0 = (1 - visibleU) * 0.5f;
        u1 = u0 + visibleU;
        v0 = (1 - visibleV) * 0.5f;
        v1 = v0 + visibleV;
    }
    // The decoded picture is opaque, so only the tint can let the background through. background() rounds its edges to
    // whole pixels: the picture must reach those.
    constexpr float kEps = 1e-3f;
    const bool opaque = v.tint.a * c.fade >= 1.0f;
    const bool hidden = opaque && dst.x <= snap(c, r.x) + kEps && dst.y <= snap(c, r.y) + kEps &&
                        dst.x + dst.w >= snap(c, r.x + r.w) - kEps && dst.y + dst.h >= snap(c, r.y + r.h) - kEps;
    if (!hidden) background(c, b, r, b.color);
    c.list().begin_item(v.layer + 1, 0, tex, SamplerKind::LinearClamp, BlendMode::Alpha, c.clip);
    if (opaque) c.list().set_opaque();  // the same pixels without blending: less work for software rasterizers
    quad(c, dst.x, dst.y, dst.x + dst.w, dst.y + dst.h, u0, v0, u1, v1, pack(v.tint, c.fade));
    c.list().end_item();
}

// A thick segment from `a` to `b` (UI units) as one quad of the current item.
void segment(const Ctx& c, Vec2 a, Vec2 b, float thickness, std::uint32_t col) {
    const Vec2 d = b - a;
    const float len = std::sqrt(d.x * d.x + d.y * d.y);
    Vec2 n = len > 1e-4f ? Vec2{-d.y / len, d.x / len} * (thickness * 0.5f) : Vec2{0, thickness * 0.5f};
    const QuadEmitter q{c.list(), c.to_screen(), true, col, kModeTextured, 0};
    auto v = [&](Vec2 p) {
        const Vec3 w = q.xf(p.x, -p.y);  // like quad(): the emitter flips y, so the screen's y goes in negated
        return Vertex2D{w.x, w.y, w.z, 0.5f, 0.5f, col, kModeTextured, 0};
    };
    c.list().quad(v(a + n), v(a - n), v(b - n), v(b + n));
}

// A Chart: its background, then every rule, bar and line in ONE item of the white texture, then the axis labels. The geometry is
// fa_scene's chart.h (the pointer's hover uses the same).
void draw_chart(const Ctx& c, const World& world, const Chart& ch, const UiBox& b, const Rect& r) {
    background(c, b, r, b.color);
    const auto series = chart_series(ch);
    const ChartLayout L = chart_layout(ch, series, r);
    const int layer = b.layer + 1;
    if (L.plot.w > 0 && L.plot.h > 0) {
        c.list().begin_item(layer, 0, c.f.assets->white(), SamplerKind::Nearest, BlendMode::Alpha, c.clip);
        // Rules first, so the data is over them.
        if (ch.marks.is_array())
            for (const Json& m : ch.marks) {
                if (!m.is_number() || L.count == 0) continue;
                const int slot = L.first + int(std::lround(m.get<double>()));
                if (slot < 0 || slot >= L.slots) continue;
                const float x = snap(c, L.x_of(slot) - (L.line ? 0.0f : L.slot_width() * 0.5f));
                quad(c, x, L.plot.y, x + std::max(1.0f / c.k, 1.0f), L.plot.y + L.plot.h, 0, 0, 1, 1, pack(ch.markColor, c.fade));
            }
        if (ch.showBaseline && ch.baseline >= L.lo && ch.baseline <= L.hi) {
            const float y = snap(c, L.y_of(ch.baseline));
            quad(c, L.plot.x, y, L.plot.x + L.plot.w, y + 1.0f, 0, 0, 1, 1, pack(ch.baselineColor, c.fade));
        }
        for (int s = 0; s < L.series; ++s) {
            const std::uint32_t col = pack(chart_series_color(ch, s), c.fade);
            const std::vector<double>& v = series[s];
            const int off = L.slots - int(v.size());  // each series is right-aligned on its own
            if (L.line) {
                const float w = std::max(0.0f, ch.lineWidth);
                for (std::size_t i = 0; i + 1 < v.size(); ++i)
                    segment(c, {L.x_of(off + int(i)), L.y_of(v[i])}, {L.x_of(off + int(i) + 1), L.y_of(v[i + 1])}, w, col);
                if (v.size() == 1) segment(c, {L.x_of(off) - w * 0.5f, L.y_of(v[0])}, {L.x_of(off) + w * 0.5f, L.y_of(v[0])}, w, col);
            } else {
                for (std::size_t i = 0; i < v.size(); ++i) {
                    const Rect bar = L.bar(s, off + int(i), v[i], ch.baseline);
                    quad(c, snap(c, bar.x), snap(c, bar.y), snap(c, bar.x + bar.w), snap(c, bar.y + bar.h), 0, 0, 1, 1, col);
                }
            }
        }
        c.list().end_item();
    }
    if (ch.showLabels && !series.empty()) {
        const Rect clip = c.clip.empty() ? to_pixels(c, r) : ui_intersect(to_pixels(c, r), c.clip);
        const TextLayout hi = line(c, chart_label(ch, L.hi, world.language()), ch.font, ch.fontSize);
        const TextLayout lo = line(c, chart_label(ch, L.lo, world.language()), ch.font, ch.fontSize);
        text(c, hi, L.plot.x + 2, L.plot.y, ch.textColor, layer + 1, clip);
        text(c, lo, L.plot.x + 2, L.plot.y + L.plot.h - lo.size.y, ch.textColor, layer + 1, clip);
    }
}

void draw_widget(Frame& f, const World& world, Entity e, UiKind kind, const UiBox& b) {
    Ctx c{f, Rect{}};
    if (!screen_clip(world, e, f, c.clip)) return;
    c.k = ui_scale_clamped(world.ui_scale());
    const Rect r = *ui_layout_rect(world, e, Vec2{float(f.targetW), float(f.targetH)});  // UI units
    const bool mirrored = ui_mirrored(world, e);
    if (kind == UiKind::TouchButton) c.capScale = world.get<TouchButton>(e)->maxTextScale;
    if (kind == UiKind::TouchStick || kind == UiKind::TouchButton) return draw_touch_control(c, world, e, b, r);
    if (kind == UiKind::Captions) return draw_captions(c, world, *world.get<Captions>(e), b, r);
    if (kind == UiKind::Video) return draw_video(c, *world.get<Video>(e), b, r);
    if (kind == UiKind::Chart) return draw_chart(c, world, *world.get<Chart>(e), b, r);
    const UiControl* ctl = ui_control(world, e);
    if (ctl) {
        c.capScale = ctl->maxTextScale;
        if (!ctl->key.empty() && world.language() != std::string()) c.dir = world.rtl() ? TextDirection::Rtl : TextDirection::Ltr;
    }
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
        const bool alone = !btn.icon.empty() && btn.iconPosition == ButtonIconPosition::Alone;
        // Every line centred (also inside a wrap box); a label that does not fit is cut at the button's edge.
        const TextLayout lay = alone ? TextLayout{}
                                     : line(c, btn.text, btn.font, btn.fontSize, btn.maxWidth, Align::Center,
                                            btn.autoShrink ? label_px(c, world, e, r) : 0.0f, {btn.markup, btn.bold});
        const UiButtonContent content = ui_button_content(btn, r, lay.size, mirrored);
        const Rect clip = c.clip.empty() ? to_pixels(c, r) : ui_intersect(to_pixels(c, r), c.clip);
        if (!clip.empty()) {
            if (!btn.icon.empty()) icon(c, btn, content.icon, layer, clip);
            text(c, lay, content.labelPos.x, content.labelPos.y, btn.textColor, layer, clip);
        }
    } else if (kind == UiKind::Toggle) {
        const Toggle& t = *world.get<Toggle>(e);
        const float side = ui_toggle_box_side(t, r.h, c.f.textScale);
        Rect box{r.x + 6, r.y + (r.h - side) * 0.5f, side, side};
        if (mirrored) box = ui_mirror_in(r, box);  // the box at the right of the label
        fill(c, layer, box, with_alpha(t.textColor, 0.25f), c.clip);
        outline(c, layer, box, 2, t.textColor);
        if (t.value) fill(c, layer, Rect{box.x + 5, box.y + 5, std::max(0.0f, side - 10), std::max(0.0f, side - 10)}, t.accentColor, c.clip);
        if (!mirrored)
            text_left(c, t.label, t.font, t.fontSize, t.maxWidth, t.autoShrink ? label_px(c, world, e, r) : 0.0f, t.textColor, layer,
                      box.x + side + 10, r.y, r.h, c.clip, {t.markup, t.bold});
        else
            text_right(c, t.label, t.font, t.fontSize, t.maxWidth, t.autoShrink ? label_px(c, world, e, r) : 0.0f, t.textColor, layer,
                       box.x - 10, r.y, r.h, c.clip, {t.markup, t.bold});
    } else if (kind == UiKind::Slider) {
        const Slider& s = *world.get<Slider>(e);
        const float innerLeft = r.x + 8, innerW = std::max(0.0f, r.w - 16);
        const auto [left, right] = ui_slider_track(s, r, mirrored);
        const float span = s.max - s.min, t = span > 0 ? std::clamp((s.value - s.min) / span, 0.0f, 1.0f) : 0.0f;
        const float knobX = mirrored ? right - (right - left) * t : left + (right - left) * t, midY = ui_slider_mid_y(s, r);
        const bool above = ui_slider_label_above(s);
        fill(c, layer, Rect{left, midY - 3, right - left, 6}, with_alpha(s.textColor, 0.25f), c.clip);
        if (mirrored) fill(c, layer, Rect{knobX, midY - 3, right - knobX, 6}, s.accentColor, c.clip);  // grows from the right end
        else fill(c, layer, Rect{left, midY - 3, knobX - left, 6}, s.accentColor, c.clip);
        fill(c, layer, Rect{knobX - 5, midY - std::min(12.0f, (r.h - 8) * 0.5f), 10, std::min(24.0f, r.h - 8)}, s.accentColor, c.clip);
        const float labelPx = s.autoShrink ? label_px(c, world, e, r) : 0.0f;
        const float labelY = above ? r.y + 2 : r.y, labelH = above ? std::max(1.0f, r.h - kUiSliderRowHeight - 2) : r.h;
        if (mirrored) text_right(c, s.label, s.font, s.fontSize, s.maxWidth, labelPx, s.textColor, layer, innerLeft + innerW, labelY, labelH,
                                 c.clip, {s.markup, s.bold});
        else text_left(c, s.label, s.font, s.fontSize, s.maxWidth, labelPx, s.textColor, layer, innerLeft, labelY, labelH, c.clip,
                       {s.markup, s.bold});
        if (s.showValue) {
            const TextLayout lay = line(c, ui_slider_value_text(s, s.value),s.font, s.fontSize);
            const float zone = innerLeft + innerW * 0.85f;
            const float vx = zone + (innerLeft + innerW - zone - lay.size.x) * 0.5f;
            text(c, lay, mirrored ? 2.0f * r.x + r.w - vx - lay.size.x : vx, midY - lay.size.y * 0.5f, s.textColor, layer, c.clip);
        }
    } else if (kind == UiKind::TextField) {
        const TextField& tf = *world.get<TextField>(e);
        const Rect inner{r.x + 12, r.y, std::max(0.0f, r.w - 24), r.h};
        const Rect clip = c.clip.empty() ? to_pixels(c, inner) : ui_intersect(to_pixels(c, inner), c.clip);  // the text never leaves the field
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

// The tooltip on screen (World::ui_tooltip(), fa_ui decides what shows): a background and its lines, above the widgets.
void draw_tooltip(Frame& f, const World& world) {
    const UiTooltipView& v = world.ui_tooltip();
    if (!v.shown) return;
    const UiTooltipStyle& st = world.ui_tooltip_settings().style;
    Ctx c{f, Rect{}};
    c.k = ui_scale_clamped(world.ui_scale());
    UiBox box;
    box.color = st.color;
    box.texture = st.texture;
    box.slice = st.slice;
    box.layer = st.layer;
    background(c, box, v.rect, st.color);
    for (const UiTooltipLine& l : v.lines) {
        const TextLayout lay = line(c, l.text, st.font, l.fontSize, st.maxWidth);
        text(c, lay, l.pos.x, l.pos.y, l.color, st.layer + 1, c.clip);
    }
}

}  // namespace

void gather_ui(World& world, Frame& f) {
    bool any = false;
    for (const TypeInfo* t : {&World::type_of<Panel>(), &World::type_of<Button>(), &World::type_of<Toggle>(), &World::type_of<Slider>(),
                              &World::type_of<TextField>(), &World::type_of<ScrollList>(), &World::type_of<TouchStick>(),
                              &World::type_of<TouchButton>(), &World::type_of<Captions>(), &World::type_of<Video>(), &World::type_of<Chart>()})
        any = any || !world.entities_with(t).empty();
    if (any)
        for (Entity root : world.roots()) visit(f, world, root);
    draw_tooltip(f, world);
    f.assets->end_video_frame();  // the textures of videos that were not drawn this frame are freed
}

}  // namespace fa::render
