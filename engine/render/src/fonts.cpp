// Fonts: the fallback chain of a Text, stb_truetype rasterization into a shared R8 glyph atlas (by glyph index), and the
// quads of a text. Shaping, bidirectional text and line breaking are text_shaper.cpp.
#include <algorithm>
#include <cstring>
#include <format>
#include <unordered_set>

#include <stb_truetype.h>

#include "fa/core/log.h"
#include "font_internal.h"
#include "render_internal.h"
#include "text_shaper.h"

namespace fa::render {

namespace {
struct GlyphKey {
    int face;
    int px;
    std::uint32_t gid;
    bool operator==(const GlyphKey& o) const { return face == o.face && px == o.px && gid == o.gid; }
};
struct GlyphKeyHash {
    std::size_t operator()(const GlyphKey& k) const {
        return std::size_t(k.gid) * 2654435761u ^ std::size_t(k.px) * 40503u ^ std::size_t(k.face) * 977u;
    }
};

std::string font_label(const std::string& key) {
    if (key == "builtin") return "'' (DejaVu Sans, the default font)";
    if (key == "builtin:pixel") return "'builtin:pixel' (Press Start 2P, and DejaVu Sans behind it)";
    return "'" + key + "'";
}
}  // namespace

struct Fonts::Impl {
    std::unordered_map<std::string, std::unique_ptr<FontFace>> faces;
    std::unordered_map<GlyphKey, GlyphInfo, GlyphKeyHash> glyphs;
    // Finished layouts of the texts drawn lately: shaping runs once per distinct text and size, not once per frame.
    // ponytail: dropped whole when it holds more than 4096 entries (a game with that many live texts re-shapes them
    // every frame); upgrade to an LRU when that shows in a profile.
    std::unordered_map<std::string, TextLayout> layouts;
    std::vector<std::string> fallbackKeys;  // Renderer::set_fallback_fonts
    int atlasSize = 1024;
    unsigned atlasEpoch = 0;  // counts atlas resets: a layout made across one holds stale UVs
    std::vector<unsigned char> pixels;  // R8
    struct Shelf { int y, h, x; };
    std::vector<Shelf> shelves;
    bool dirty = true;
    bool warnedFull = false;
    std::unordered_set<std::string> warnedMissing;  // fonts already warned about a missing glyph
    int nextId = 1;

    void reset_atlas(int size) {
        atlasSize = size;
        pixels.assign(std::size_t(size) * size, 0);
        shelves.clear();
        glyphs.clear();
        layouts.clear();
        ++atlasEpoch;
        dirty = true;
    }
    bool pack(int w, int h, int& ox, int& oy) {
        w += 1; h += 1;  // padding
        for (auto& s : shelves) {
            if (h <= s.h && h * 10 >= s.h * 6 && s.x + w <= atlasSize) {
                ox = s.x; oy = s.y; s.x += w;
                return true;
            }
        }
        int y = shelves.empty() ? 0 : shelves.back().y + shelves.back().h;
        if (y + h > atlasSize || w > atlasSize) return false;
        shelves.push_back({y, h, w});
        ox = 0; oy = y;
        return true;
    }
};

Fonts::Fonts(Gpu& gpu, Assets& assets) : gpu_(gpu), assets_(assets), impl_(std::make_unique<Impl>()) {
    impl_->reset_atlas(1024);
    atlasTex_.path = "<glyph-atlas>";
}

Fonts::~Fonts() { clear(); }

void Fonts::clear() {
    if (atlasTex_.view.id) sg_destroy_view(atlasTex_.view);
    if (atlasTex_.image.id) sg_destroy_image(atlasTex_.image);
    atlasTex_.view = {};
    atlasTex_.image = {};
    impl_->faces.clear();
    impl_->warnedMissing.clear();
    impl_->reset_atlas(1024);
}

void Fonts::set_fallback_fonts(std::vector<std::string> fonts) {
    if (fonts == impl_->fallbackKeys) return;
    impl_->fallbackKeys = std::move(fonts);
    impl_->layouts.clear();
    impl_->warnedMissing.clear();  // a new chain may cover (or miss) other characters
}

FontFace* Fonts::load(const std::string& fontIn) {
    const std::string font = fontIn.empty() ? "builtin" : fontIn;
    auto it = impl_->faces.find(font);
    if (it != impl_->faces.end()) return it->second.get();
    std::unique_ptr<FontFace> f = load_font_face(font);
    f->id = impl_->nextId++;
    if (!f->ok) assets_.note_failure("font", font, f->error, f->hint);
    FontFace* raw = f.get();
    impl_->faces[font] = std::move(f);
    return raw;
}

FontFace* Fonts::face(const std::string& font) {
    FontFace* f = load(font);
    return f->ok || f->key == "builtin" ? f : load("builtin");
}

// A glyph of a face by glyph index, rasterized into the atlas on first use.
GlyphInfo Fonts::glyph(FontFace* ff, int px, std::uint32_t gid) {
    Impl& im = *impl_;
    const GlyphKey key{ff->id, px, gid};
    auto it = im.glyphs.find(key);
    if (it != im.glyphs.end()) return it->second;
    GlyphInfo g;
    g.empty = true;
    const float s = stbtt_ScaleForMappingEmToPixels(&ff->info, float(px));
    int x0, y0, x1, y1;
    stbtt_GetGlyphBitmapBox(&ff->info, int(gid), s, s, &x0, &y0, &x1, &y1);
    const int w = x1 - x0, h = y1 - y0;
    if (w <= 0 || h <= 0 || gid == 0) {  // whitespace, or the .notdef box of a missing character: nothing to draw
        im.glyphs[key] = g;
        return g;
    }
    int ax, ay;
    if (!im.pack(w, h, ax, ay)) {
        if (im.atlasSize < 2048) {
            // Grow: old UVs become invalid, so everything is re-rasterized on demand.
            im.reset_atlas(2048);
        } else {
            if (!im.warnedFull) {
                FA_WARN("render", "glyph atlas is full (2048x2048); clearing it. Use fewer distinct font sizes to avoid flicker.");
                im.warnedFull = true;
            }
            im.reset_atlas(2048);
        }
        if (!im.pack(w, h, ax, ay)) return g;
    }
    stbtt_MakeGlyphBitmap(&ff->info, &im.pixels[std::size_t(ay) * im.atlasSize + ax], w, h, im.atlasSize, s, s, int(gid));
    im.dirty = true;
    const float inv = 1.0f / float(im.atlasSize);
    g.empty = false;
    g.u0 = ax * inv; g.v0 = ay * inv; g.u1 = (ax + w) * inv; g.v1 = (ay + h) * inv;
    g.x0 = float(x0); g.y0 = float(y0); g.x1 = float(x1); g.y1 = float(y1);
    im.glyphs[key] = g;
    return g;
}

TextLayout Fonts::layout(const Text& t, float fontSize, float pixelsPerUnit) {
    Impl& im = *impl_;
    FontFace* primary = face(t.font);
    if (!primary || !primary->ok) return {};
    const float rasterPx = fontSize * pixelsPerUnit;
    const int px = std::clamp(int(std::lround(rasterPx)), 4, 400);
    const float unitsPerPx = fontSize / float(px);          // local units per raster pixel
    const float maxW = t.maxWidth > 0 ? t.maxWidth / unitsPerPx : 0.0f;  // in raster pixels

    struct KeyHead { float fontSize, maxWidth, pivotX, pivotY; int px, align; } head{};
    head.fontSize = fontSize; head.maxWidth = t.maxWidth; head.pivotX = t.pivot.x; head.pivotY = t.pivot.y;
    head.px = px; head.align = int(t.align);
    std::string cacheKey(reinterpret_cast<const char*>(&head), sizeof head);
    cacheKey += t.font;
    cacheKey.push_back('\0');
    cacheKey += t.text;
    if (auto hit = im.layouts.find(cacheKey); hit != im.layouts.end()) return hit->second;

    // The chain: the Text's font, the project's fallback fonts, the built-in DejaVu Sans last.
    const std::size_t chainSize = im.fallbackKeys.size() + 2;
    const auto chain = [&](std::size_t k) -> FontFace* {
        if (k == 0) return primary;
        return load(k == chainSize - 1 ? std::string("builtin") : im.fallbackKeys[k - 1]);
    };

    const float scale = stbtt_ScaleForMappingEmToPixels(&primary->info, float(px));
    int asc, desc, gap;
    stbtt_GetFontVMetrics(&primary->info, &asc, &desc, &gap);
    const FontMetrics fm{asc * scale, desc * scale, gap * scale};
    // ponytail: every line is as tall as the Text's own font says, whatever fallback fonts draw on it; a fallback with much
    // taller letters (some CJK fonts) can touch the next line. Take the tallest font used in the text when that matters.
    float lineH = std::round(fm.lineHeight());
    if (lineH < 1) lineH = float(px);

    ShapedText shaped;
    TextLayout out;
    for (int attempt = 0; attempt < 2; ++attempt) {  // a second pass when the atlas was reset halfway: UVs of the first are stale
        const unsigned epoch = im.atlasEpoch;
        shaped = shape_text(t.text, px, maxW, chainSize, chain);
        out = TextLayout{};
        float boxW = 0;
        for (const ShapedLine& l : shaped.lines) boxW = std::max(boxW, l.width);
        if (maxW > 0) boxW = std::max(boxW, maxW);
        const float boxH = lineH * float(shaped.lines.size());
        out.size = {boxW * unitsPerPx, boxH * unitsPerPx};

        // ---- place glyphs (raster pixels, y down from the box top) ----
        const float ox = -t.pivot.x * boxW;
        const float top = (1.0f - t.pivot.y) * boxH;  // distance of the box top above the anchor (y up)
        for (std::size_t li = 0; li < shaped.lines.size(); ++li) {
            const ShapedLine& l = shaped.lines[li];
            float x = 0;  // Align is explicit: Left is the left edge even for right-to-left text
            if (t.align == Align::Center) x = (boxW - l.width) * 0.5f;
            else if (t.align == Align::Right) x = boxW - l.width;
            x = std::round(x);
            const float baselineY = top - std::round(fm.ascent) - lineH * float(li);  // y up
            for (const ShapedGlyph& sg : l.glyphs) {
                if (sg.gid == 0) continue;
                const GlyphInfo g = glyph(sg.face, px, sg.gid);
                if (g.empty) continue;
                const float pen = std::round(x + sg.x), lift = std::round(sg.y);
                const float gx0 = pen + g.x0, gx1 = pen + g.x1;
                const float gy0 = baselineY - g.y1 + lift, gy1 = baselineY - g.y0 + lift;  // y up
                out.quads.push_back({(ox + gx0) * unitsPerPx, gy0 * unitsPerPx, (ox + gx1) * unitsPerPx, gy1 * unitsPerPx,
                                     g.u0, g.v0, g.u1, g.v1});
            }
        }
        if (im.atlasEpoch == epoch) break;
    }

    if (!shaped.missing.empty() && im.warnedMissing.insert(primary->key).second) warn_missing_glyphs(primary, t.text, shaped.missing);
    if (im.layouts.size() >= 4096) im.layouts.clear();
    im.layouts[cacheKey] = out;
    return out;
}

// Text that draws as nothing is the worst kind of bug to find, so the first missing glyph of each font says which
// characters, and what to do: a font already in use that has them, else the kind of font that does.
void Fonts::warn_missing_glyphs(FontFace* f, const std::string& text, const std::vector<char32_t>& missing) {
    std::string chars;
    for (char32_t cp : missing) chars += std::format("{}U+{:04X} '{}'", chars.empty() ? "" : ", ", unsigned(cp), encode_utf8(cp));
    std::string excerpt;
    const std::u32string cps = decode_utf8(text);
    for (std::size_t i = 0; i < cps.size() && i < 24; ++i) excerpt += encode_utf8(cps[i]);
    if (cps.size() > 24) excerpt += "...";
    std::string label = font_label(f->key);
    if (!impl_->fallbackKeys.empty()) {  // the whole chain was searched
        label += " (and its fallback fonts";
        for (std::size_t i = 0; i < impl_->fallbackKeys.size(); ++i) label += (i ? ", " : " ") + font_label(impl_->fallbackKeys[i]);
        label += ")";
    }
    std::string hint;
    for (const auto& [key, other] : impl_->faces) {
        if (other.get() == f || !other->ok) continue;
        bool all = true;
        for (char32_t cp : missing) all = all && other->has_glyph(cp);
        if (all) {
            hint = std::format("The font {} (already used in this game) has them: set the Text's \"font\" to it.", font_label(key));
            break;
        }
    }
    if (hint.empty()) {
        if (std::any_of(missing.begin(), missing.end(), is_cjk))
            hint = "Chinese, Japanese and Korean need a font that covers them, such as Noto Sans SC, JP or KR (SIL Open Font "
                   "License): put its .ttf in assets/fonts/ and set the Text's \"font\" to that path. The built-in fonts cover "
                   "Latin, Greek, Cyrillic, Hebrew and Arabic.";
        else if (std::any_of(missing.begin(), missing.end(), is_emoji))
            hint = "Colour emoji fonts are not supported (only TrueType outlines): draw emoji as sprites.";
        else
            hint = "Use a .ttf that covers them (the Noto fonts have one per script): put it in assets/fonts/ and set the Text's "
                   "\"font\" to that path.";
    }
    FA_WARN("render", "text \"{}\" has characters the font {} has no glyph for, so they draw as nothing: {}. {} (Reported once per font.)",
            excerpt, label, chars, hint);
}

void Fonts::sync() {
    Impl& im = *impl_;
    if (!im.dirty && atlasTex_.image.id) return;
    if (atlasTex_.view.id) sg_destroy_view(atlasTex_.view);
    if (atlasTex_.image.id) sg_destroy_image(atlasTex_.image);
    sg_image_desc d{};
    d.width = d.height = im.atlasSize;
    d.pixel_format = SG_PIXELFORMAT_R8;
    d.data.mip_levels[0] = {im.pixels.data(), im.pixels.size()};
    d.label = "glyph-atlas";
    atlasTex_.image = make_image(d);
    sg_view_desc vd{};
    vd.texture.image = atlasTex_.image;
    vd.label = "glyph-atlas";
    atlasTex_.view = sg_make_view(&vd);
    atlasTex_.width = atlasTex_.height = im.atlasSize;
    im.dirty = false;
}

Json Fonts::report() const {
    Json j = Json::array();
    for (const auto& [k, f] : impl_->faces) j.push_back({{"font", k}, {"ok", f->ok}});
    return j;
}

}  // namespace fa::render
