#include "fa/scene/ui_rect.h"

#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/det_math.h"
#include "fa/scene/bounds.h"

namespace fa {

const char* ui_kind_name(UiKind k) {
    switch (k) {
        case UiKind::Panel: return "Panel";
        case UiKind::Button: return "Button";
        case UiKind::Toggle: return "Toggle";
        case UiKind::Slider: return "Slider";
        case UiKind::TextField: return "TextField";
        case UiKind::ScrollList: return "ScrollList";
        case UiKind::TouchStick: return "TouchStick";
        case UiKind::TouchButton: return "TouchButton";
        case UiKind::Captions: return "Captions";
        case UiKind::Video: return "Video";
        case UiKind::Chart: return "Chart";
        case UiKind::CameraView: return "CameraView";
        case UiKind::None: break;
    }
    return "";
}

UiKind ui_kind(const World& w, Entity e) {
    if (w.has<Button>(e)) return UiKind::Button;
    if (w.has<Toggle>(e)) return UiKind::Toggle;
    if (w.has<Slider>(e)) return UiKind::Slider;
    if (w.has<TextField>(e)) return UiKind::TextField;
    if (w.has<ScrollList>(e)) return UiKind::ScrollList;
    if (w.has<Panel>(e)) return UiKind::Panel;
    if (w.has<TouchStick>(e)) return UiKind::TouchStick;
    if (w.has<TouchButton>(e)) return UiKind::TouchButton;
    if (w.has<Captions>(e)) return UiKind::Captions;
    if (w.has<Video>(e)) return UiKind::Video;
    if (w.has<Chart>(e)) return UiKind::Chart;
    if (w.has<CameraView>(e)) return UiKind::CameraView;
    return UiKind::None;
}

const UiBox* ui_box(const World& w, Entity e) {
    switch (ui_kind(w, e)) {
        case UiKind::Panel: return w.get<Panel>(e);
        case UiKind::Button: return w.get<Button>(e);
        case UiKind::Toggle: return w.get<Toggle>(e);
        case UiKind::Slider: return w.get<Slider>(e);
        case UiKind::TextField: return w.get<TextField>(e);
        case UiKind::ScrollList: return w.get<ScrollList>(e);
        case UiKind::TouchStick: return w.get<TouchStick>(e);
        case UiKind::TouchButton: return w.get<TouchButton>(e);
        case UiKind::Captions: return w.get<Captions>(e);
        case UiKind::Video: return w.get<Video>(e);
        case UiKind::Chart: return w.get<Chart>(e);
        case UiKind::CameraView: return w.get<CameraView>(e);
        case UiKind::None: break;
    }
    return nullptr;
}

bool ui_layout_places(const World& w, Entity parent, Entity child) {
    if (!parent || !child) return false;
    bool container = w.has<ScrollList>(parent);
    if (const Panel* p = w.get<Panel>(parent))
        container = container || p->layout != UiLayout::None || p->fallbackLayout != UiLayout::None;
    if (!container) return false;
    if (ui_box(w, child)) return true;
    if (const Text* t = w.get<Text>(child)) return t->space == RenderSpace::Screen;
    if (const Sprite* s = w.get<Sprite>(child)) return s->space == RenderSpace::Screen;
    if (const Shape2D* s = w.get<Shape2D>(child)) return s->space == RenderSpace::Screen;
    return false;
}

const UiControl* ui_control(const World& w, Entity e) {
    return ui_is_control(ui_kind(w, e)) ? static_cast<const UiControl*>(ui_box(w, e)) : nullptr;
}

bool ui_mirrored(const World& w, Entity e) {
    if (!w.ui_mirror()) return false;
    bool inWidget = false;
    for (Entity a = e; a; a = w.parent(a))
        if (const UiBox* b = ui_box(w, a)) {
            if (!b->mirror) return false;
            inWidget = true;
        }
    return inWidget;
}

Vec2 anchor_point(Vec2 anchor, bool safeArea, Vec2 designSize, const EdgeInsets& insets) {
    if (!safeArea) return {anchor.x * designSize.x, anchor.y * designSize.y};
    return {insets.left + anchor.x * (designSize.x - insets.left - insets.right),
            insets.top + anchor.y * (designSize.y - insets.top - insets.bottom)};
}

const std::vector<std::string>& safe_area_profile_names() {
    static const std::vector<std::string> names = {"none", "phone-portrait", "phone-landscape"};
    return names;
}

bool safe_area_profile(std::string_view name, Vec2 designSize, EdgeInsets& out) {
    if (name == "none") out = {};
    // iPhone 15 in points: 393 x 852, notch area 59 at the top and home indicator 34 at the bottom; turned, 59 on each
    // side and 21 at the bottom.
    else if (name == "phone-portrait")
        out = {0, designSize.y * (59.0f / 852.0f), 0, designSize.y * (34.0f / 852.0f)};
    else if (name == "phone-landscape")
        out = {designSize.x * (59.0f / 852.0f), 0, designSize.x * (59.0f / 852.0f), designSize.y * (21.0f / 393.0f)};
    else
        return false;
    return true;
}

float ui_scale_clamped(float k) {
    if (!(k > 0.0f)) return 1.0f;
    return std::clamp(k, kMinUiScale, kMaxUiScale);
}

Vec2 ui_layout_screen(const World& w, Vec2 designSize) {
    const float k = ui_scale_clamped(w.ui_scale());
    return {designSize.x / k, designSize.y / k};
}

EdgeInsets ui_layout_insets(const World& w) {
    const float k = ui_scale_clamped(w.ui_scale());
    const EdgeInsets& i = w.safe_insets();
    return {i.left / k, i.top / k, i.right / k, i.bottom / k};
}

namespace {

float finite_or(float v, float fallback) { return std::isfinite(v) ? v : fallback; }

// True when `t` turns or scales its entity (a NaN counts as none).
bool turns_or_scales(const Transform& t) {
    return finite_or(t.rotation.z, 0.0f) != 0.0f || finite_or(t.scale.x, 1.0f) != 1.0f ||
           finite_or(t.scale.y, 1.0f) != 1.0f;
}

bool chain_transforms(const World& w, Entity e) {
    for (Entity a = e; a; a = w.parent(a))
        if (const Transform* t = w.get<Transform>(a))
            if (turns_or_scales(*t)) return true;
    return false;
}

// Transform.position plus the layout's placement (World::ui_layout_offset): what an entity adds to the layout-space
// sum.
Vec3 layout_position(const World& w, Entity e) {
    Vec3 p{0, 0, 0};
    if (const Transform* tr = w.get<Transform>(e)) p = tr->position;
    const Vec2 o = w.ui_layout_offset(e);
    return {p.x + o.x, p.y + o.y, p.z};
}

// ui_layout_translation when the caller already knows whether the chain turns or scales (chain_transforms): the parents are
// walked once, not twice, per ui_rect.
Vec3 layout_translation(const World& w, Entity e, bool turns) {
    if (!turns) return w.world_matrix(e).translation();
    Vec3 t{0, 0, 0};
    for (Entity a = e; a; a = w.parent(a)) t = t + layout_position(w, a);
    return t;
}

}  // namespace

// The translation in layout space: the sum of the local positions (and layout offsets) up the parents. Without rotation
// or scale in the chain it is the world translation, bit for bit.
Vec3 ui_layout_translation(const World& w, Entity e) { return layout_translation(w, e, chain_transforms(w, e)); }

bool ui_widget_ancestor_turns(const World& w, Entity e) {
    for (Entity a = w.parent(e); a; a = w.parent(a))
        if (const Transform* t = w.get<Transform>(a))
            if (turns_or_scales(*t) && ui_box(w, a)) return true;
    return false;
}

namespace {

struct Place {
    Rect rect;    // own frame, UI units
    Vec2 origin;  // where the entity's origin is: position + anchor point
    Vec2 pivot;   // the pivot used (flipped when mirrored)
};

std::optional<Place> place_of(const World& w, Entity e, Vec2 designSize, bool turns) {
    const UiBox* b = ui_box(w, e);
    if (!b) return std::nullopt;
    Vec3 t = layout_translation(w, e, turns);
    Vec2 anchor = b->anchor, pivot = b->pivot;
    if (ui_mirrored(w, e)) {  // the mirror image: anchor, pivot and position flip left to right
        anchor.x = 1.0f - anchor.x;
        pivot.x = 1.0f - pivot.x;
        t.x = -t.x;
    }
    const Vec2 a = anchor_point(anchor, b->safeArea, ui_layout_screen(w, designSize), ui_layout_insets(w));
    return Place{Rect{t.x + a.x - pivot.x * b->size.x, t.y + a.y - (1.0f - pivot.y) * b->size.y, b->size.x, b->size.y},
                 Vec2{t.x + a.x, t.y + a.y}, pivot};
}

UiAffine compose(const UiAffine& g, const UiAffine& v) {  // g after v
    UiAffine r;
    r.a = g.a * v.a + g.c * v.b;
    r.b = g.b * v.a + g.d * v.b;
    r.c = g.a * v.c + g.c * v.d;
    r.d = g.b * v.c + g.d * v.d;
    r.tx = g.a * v.tx + g.c * v.ty + g.tx;
    r.ty = g.b * v.tx + g.d * v.ty + g.ty;
    return r;
}

float to_k(const World& w) { return ui_scale_clamped(w.ui_scale()); }

}  // namespace

std::optional<UiAffine> UiAffine::inverse() const {
    const float det = a * d - b * c;
    if (!std::isfinite(det) || std::fabs(det) < 1e-12f) return std::nullopt;
    UiAffine r;
    r.a = d / det;
    r.b = -b / det;
    r.c = -c / det;
    r.d = a / det;
    r.tx = -(r.a * tx + r.c * ty);
    r.ty = -(r.b * tx + r.d * ty);
    return r;
}

bool UiAffine::axis_aligned() const {
    const float m = std::max({std::fabs(a), std::fabs(b), std::fabs(c), std::fabs(d)});
    const float eps = 1e-4f * std::max(m, 1e-6f);
    return (std::fabs(b) <= eps && std::fabs(c) <= eps) || (std::fabs(a) <= eps && std::fabs(d) <= eps);
}

std::optional<Rect> ui_layout_rect(const World& w, Entity e, Vec2 designSize) {
    const std::optional<Place> p = place_of(w, e, designSize, chain_transforms(w, e));
    if (!p) return std::nullopt;
    return p->rect;
}

std::optional<Rect> ui_footprint_rect(const World& w, Entity e, Vec2 designSize) {
    const std::optional<Place> p = place_of(w, e, designSize, chain_transforms(w, e));
    if (!p) return std::nullopt;
    const Transform* t = w.get<Transform>(e);
    const float sx = t ? std::fabs(finite_or(t->scale.x, 1.0f)) : 1.0f,
                sy = t ? std::fabs(finite_or(t->scale.y, 1.0f)) : 1.0f;
    if (sx == 1.0f && sy == 1.0f) return p->rect;
    const float ww = p->rect.w * sx, hh = p->rect.h * sy;
    return Rect{p->origin.x - p->pivot.x * ww, p->origin.y - (1.0f - p->pivot.y) * hh, ww, hh};
}

Mat4 ui_layout_matrix(const World& w, Entity e) {
    if (!chain_transforms(w, e)) return w.world_matrix(e);
    const Transform* t = w.get<Transform>(e);
    const Vec3 s = t ? Vec3{finite_or(t->scale.x, 1.0f), finite_or(t->scale.y, 1.0f), 1.0f} : Vec3{1, 1, 1};
    return Mat4::translate(ui_layout_translation(w, e)) * Mat4::scale(s);
}

namespace {

// The chain of `e` up to the root, e first. Up to 32 levels sit on the stack (ui_transform runs several times per widget per
// frame); a deeper tree spills into a vector.
class Chain {
public:
    Chain(const World& w, Entity e) {
        for (Entity a = e; a; a = w.parent(a)) {
            if (n_ < kInline)
                inline_[n_] = a;
            else {
                if (spill_.empty()) spill_.assign(inline_, inline_ + kInline);
                spill_.push_back(a);
            }
            ++n_;
        }
    }
    std::size_t size() const { return n_; }
    Entity operator[](std::size_t i) const { return n_ <= kInline ? inline_[i] : spill_[i]; }

private:
    static constexpr std::size_t kInline = 32;
    Entity inline_[kInline];
    std::vector<Entity> spill_;
    std::size_t n_ = 0;
};

// ui_transform when the caller already knows whether the chain turns or scales.
UiAffine transform_of(const World& w, Entity e, Vec2 designSize, bool turns) {
    UiAffine v;
    if (!turns) return v;
    const Chain chain(w, e);
    // The layout translation of chain[i] is the positions from the root down to it: summed root first, as layout_translation
    // does, so the two agree to the last bit. Running sums are kept on the stack for the usual shallow tree.
    constexpr std::size_t kInline = 32;
    Vec3 inlineSums[kInline];
    std::vector<Vec3> spill;
    if (chain.size() > kInline) spill.resize(chain.size());
    Vec3* sums = chain.size() > kInline ? spill.data() : inlineSums;
    Vec3 sum{0, 0, 0};
    for (std::size_t i = chain.size(); i-- > 0;) {
        sum = sum + layout_position(w, chain[i]);
        sums[i] = sum;
    }
    for (std::size_t i = 0; i < chain.size(); ++i) {  // e's own turn first, then each parent's around its own origin
        const Transform* tr = w.get<Transform>(chain[i]);
        if (!tr || !turns_or_scales(*tr)) continue;
        const bool mirrored = ui_mirrored(w, chain[i]);
        Vec3 t = sums[i];
        Vec2 anchor{0, 0};
        if (const UiBox* b = ui_box(w, chain[i])) {
            Vec2 an = b->anchor;
            if (mirrored) an.x = 1.0f - an.x;
            anchor = anchor_point(an, b->safeArea, ui_layout_screen(w, designSize), ui_layout_insets(w));
        }
        if (mirrored) t.x = -t.x;
        const float ox = t.x + anchor.x, oy = t.y + anchor.y;
        const float deg = finite_or(tr->rotation.z, 0.0f) * (mirrored ? -1.0f : 1.0f);
        const float sx = finite_or(tr->scale.x, 1.0f), sy = finite_or(tr->scale.y, 1.0f);
        float sn = 0.0f, cs = 1.0f;
        det::sin_cos(deg * kDegToRad, sn, cs);
        UiAffine g;
        g.a = cs * sx;
        g.b = sn * sx;
        g.c = -sn * sy;
        g.d = cs * sy;
        g.tx = ox - (g.a * ox + g.c * oy);
        g.ty = oy - (g.b * ox + g.d * oy);
        v = compose(g, v);
    }
    return v;
}

std::optional<std::array<Vec2, 4>> quad_of(const World& w, Entity e, Vec2 designSize, bool turns) {
    const std::optional<Place> p = place_of(w, e, designSize, turns);
    if (!p) return std::nullopt;
    const Rect& r = p->rect;
    const UiAffine x = transform_of(w, e, designSize, turns);
    const float k = to_k(w);
    const Vec2 c[4] = {{r.x, r.y}, {r.x + r.w, r.y}, {r.x + r.w, r.y + r.h}, {r.x, r.y + r.h}};
    std::array<Vec2, 4> out;
    for (int i = 0; i < 4; ++i) {
        const Vec2 q = x.apply(c[i]);
        out[std::size_t(i)] = {q.x * k, q.y * k};
    }
    return out;
}

std::optional<Rect> own_rect_of(const World& w, Entity e, Vec2 designSize, bool turns) {
    const std::optional<Place> p = place_of(w, e, designSize, turns);
    if (!p) return std::nullopt;
    const float k = to_k(w);
    return Rect{p->rect.x * k, p->rect.y * k, p->rect.w * k, p->rect.h * k};
}

}  // namespace

UiAffine ui_transform(const World& w, Entity e, Vec2 designSize) {
    return transform_of(w, e, designSize, chain_transforms(w, e));
}

std::optional<std::array<Vec2, 4>> ui_quad(const World& w, Entity e, Vec2 designSize) {
    return quad_of(w, e, designSize, chain_transforms(w, e));
}

std::optional<Rect> ui_own_rect(const World& w, Entity e, Vec2 designSize) {
    return own_rect_of(w, e, designSize, chain_transforms(w, e));
}

std::optional<Rect> ui_rect(const World& w, Entity e, Vec2 designSize) {
    const bool turns = chain_transforms(w, e);  // the parents are walked once for all of it
    if (!turns) return own_rect_of(w, e, designSize, false);
    const std::optional<std::array<Vec2, 4>> q = quad_of(w, e, designSize, true);
    if (!q) return std::nullopt;
    float x0 = (*q)[0].x, y0 = (*q)[0].y, x1 = x0, y1 = y0;
    for (const Vec2& p : *q) {
        x0 = std::min(x0, p.x);
        y0 = std::min(y0, p.y);
        x1 = std::max(x1, p.x);
        y1 = std::max(y1, p.y);
    }
    return Rect{x0, y0, x1 - x0, y1 - y0};
}

bool ui_contains(const World& w, Entity e, Vec2 designSize, Vec2 p) {
    const bool turns = chain_transforms(w, e);
    if (!turns) {
        const std::optional<Rect> r = own_rect_of(w, e, designSize, false);
        return r && r->contains(p);
    }
    const std::optional<std::array<Vec2, 4>> q = quad_of(w, e, designSize, true);
    if (!q) return false;
    for (const Vec2& c : *q)
        if (!std::isfinite(c.x) || !std::isfinite(c.y)) return false;  // point_in_quad answers true on NaN
    return point_in_quad(p, *q);
}

Vec2 ui_local_point(const World& w, Entity e, Vec2 designSize, Vec2 p) {
    const UiAffine x = ui_transform(w, e, designSize);
    if (x.is_identity()) return p;
    const std::optional<UiAffine> inv = x.inverse();
    if (!inv) return p;
    const float k = to_k(w);
    const Vec2 u = inv->apply({p.x / k, p.y / k});
    return {u.x * k, u.y * k};
}

Vec2 ui_world_point(const World& w, Entity e, Vec2 designSize, Vec2 p) {
    const UiAffine x = ui_transform(w, e, designSize);
    if (x.is_identity()) return p;
    const float k = to_k(w);
    const Vec2 u = x.apply({p.x / k, p.y / k});
    return {u.x * k, u.y * k};
}

Rect ui_intersect(const Rect& a, const Rect& b) {
    const float x0 = std::max(a.x, b.x), y0 = std::max(a.y, b.y);
    const float x1 = std::min(a.x + a.w, b.x + b.w), y1 = std::min(a.y + a.h, b.y + b.h);
    return Rect{x0, y0, std::max(0.0f, x1 - x0), std::max(0.0f, y1 - y0)};
}

std::optional<Rect> ui_clip_rect(const World& w, Entity e, Vec2 designSize) {
    std::optional<Rect> clip;
    for (Entity p = w.parent(e); p; p = w.parent(p)) {
        if (!w.has<ScrollList>(p)) continue;
        const std::optional<Rect> r = ui_rect(w, p, designSize);
        if (r) clip = clip ? ui_intersect(*clip, *r) : *r;
    }
    return clip;
}

bool ui_clip_contains(const World& w, Entity e, Vec2 designSize, Vec2 p) {
    for (Entity a = w.parent(e); a; a = w.parent(a))
        if (w.has<ScrollList>(a) && ui_box(w, a) && !ui_contains(w, a, designSize, p)) return false;
    return true;
}

float ui_slider_fraction(std::pair<float, float> track, float x, bool mirrored) {
    if (!(track.second > track.first)) return 0.0f;
    const float t = std::clamp((x - track.first) / (track.second - track.first), 0.0f, 1.0f);
    return mirrored ? 1.0f - t : t;
}

std::pair<float, float> ui_slider_track(const Slider& s, const Rect& r, bool mirrored) {
    const float inner0 = r.x + 8.0f, innerW = std::max(0.0f, r.w - 16.0f);
    const bool side = !s.label.empty() && !s.labelAbove;  // a label above the track leaves the whole width to it
    const float labelW = side ? innerW * 0.35f : 0.0f;
    const float zone0 = inner0 + labelW, zoneW = innerW * (side ? 0.5f : 0.85f);
    const float left = zone0 + 8.0f, right = std::max(zone0 + 8.0f, zone0 + zoneW - 8.0f);
    if (mirrored) return {2.0f * r.x + r.w - right, 2.0f * r.x + r.w - left};
    return {left, right};
}

float ui_slider_mid_y(const Slider& s, const Rect& r) {
    return ui_slider_label_above(s) ? r.y + std::max(r.h - kUiSliderRowHeight * 0.5f, r.h * 0.5f) : r.y + r.h * 0.5f;
}

namespace {
std::string trimmed_number(float value) {
    std::string t = std::format("{:.2f}", value);
    while (t.back() == '0') t.pop_back();
    if (t.back() == '.') t.pop_back();
    return t == "-0" ? "0" : t;
}
}  // namespace

std::string ui_slider_value_text(const Slider& s, float value) {
    if (!s.format.empty()) {
        std::string out;
        const std::string& f = s.format;
        for (std::size_t i = 0; i < f.size(); ++i) {
            const char c = f[i];
            if ((c == '{' || c == '}') && i + 1 < f.size() && f[i + 1] == c) {
                out += c;
                ++i;
            } else if (c == '{') {
                const std::size_t close = f.find('}', i + 1);
                const std::string name = close == std::string::npos ? std::string() : f.substr(i + 1, close - i - 1);
                if (name == "v") {
                    out += trimmed_number(value);
                } else if (name == "percent") {
                    out += std::format("{}", int(std::lround(value * 100.0f)));
                } else if (name.size() == 3 && name[0] == 'v' && name[1] == ':' && name[2] >= '0' && name[2] <= '6') {
                    out += std::format("{:.{}f}", value, name[2] - '0');
                } else {
                    out += c;  // not a placeholder: drawn as written
                    continue;
                }
                i = close;
            } else {
                out += c;
            }
        }
        return out;
    }
    if (s.min == 0.0f && s.max == 1.0f) return std::format("{}%", int(std::lround(value * 100.0f)));
    return trimmed_number(value);
}

}  // namespace fa
