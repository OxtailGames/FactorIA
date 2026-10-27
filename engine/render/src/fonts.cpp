// Fonts: the fallback chain of a Text, stb_truetype rasterization into a shared R8 glyph atlas (by glyph index), and the
// quads of a text. Shaping, bidirectional text and line breaking are text_shaper.cpp.
#include <algorithm>
#include <cstring>
#include <format>
#include <unordered_set>

#include <stb_truetype.h>

#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/core/utf8.h"
#include "font_internal.h"
#include "render_internal.h"
#include "text_shaper.h"

namespace fa::render {

namespace {
struct GlyphKey {
    int face;
    int px;
    std::uint32_t gid;
    bool synth;  // emboldened by the engine (no bold face)
    bool operator==(const GlyphKey& o) const { return face == o.face && px == o.px && gid == o.gid && synth == o.synth; }
};
struct GlyphKeyHash {
    std::size_t operator()(const GlyphKey& k) const {
        return std::size_t(k.gid) * 2654435761u ^ std::size_t(k.px) * 40503u ^ std::size_t(k.face) * 977u ^ (k.synth ? 0x9e3779b9u : 0u);
    }
};

// How much wider the engine makes a letter it emboldens (a font with no bold face), in raster pixels: a stem about 4 % of the
// size thicker, never less than 0.7 px so the pixel font and small sizes still show it.
float synthetic_bold_extra(int px) { return std::clamp(float(px) * 0.04f, 0.7f, 6.0f); }

std::string font_label(const std::string& key) {
    if (key == "builtin") return "'' (DejaVu Sans, the default font)";
    if (key == "builtin:pixel") return "'builtin:pixel' (Press Start 2P, and DejaVu Sans behind it)";
    return "'" + key + "'";
}
}  // namespace

constexpr int kMaxAtlas = 4096;

struct Fonts::Impl {
    std::unordered_map<std::string, std::unique_ptr<FontFace>> faces;
    std::unordered_map<GlyphKey, GlyphInfo, GlyphKeyHash> glyphs;
    // Finished layouts of the texts drawn lately: shaping runs once per distinct text and size, not once per frame.
    // ponytail: dropped whole when it holds more than 4096 entries (a game with that many live texts re-shapes them
    // every frame); upgrade to an LRU when that shows in a profile.
    std::unordered_map<std::string, TextLayout> layouts;
    std::vector<std::string> fallbackKeys;  // Renderer::set_fallback_fonts
    RichTextStyle style;                    // Renderer::set_rich_text_style; boldFonts keyed by FontFace::key ("builtin" for "")
    std::unordered_set<std::string> warnedRich;  // markup problems already reported (capped)
    int atlasSize = 1024;
    unsigned atlasEpoch = 0;  // counts atlas resets: a layout made across one holds stale UVs
    std::vector<unsigned char> pixels;  // R8
    struct Shelf { int y, h, x; };
    std::vector<Shelf> shelves;
    bool dirty = true;
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

void Fonts::set_rich_style(const RichTextStyle& style) {
    if (style == impl_->style) return;
    impl_->style = style;
    if (auto it = impl_->style.boldFonts.find(""); it != impl_->style.boldFonts.end()) {  // "" names the built-in font
        impl_->style.boldFonts["builtin"] = it->second;
        impl_->style.boldFonts.erase(it);
    }
    impl_->layouts.clear();
    impl_->warnedRich.clear();
}

// The bold face the project gives `regular`, or null (the engine emboldens its letters).
FontFace* Fonts::bold_face(FontFace* regular) {
    const auto it = impl_->style.boldFonts.find(regular->key);
    if (it == impl_->style.boldFonts.end() || it->second == regular->key) return nullptr;
    FontFace* b = load(it->second);
    return b->ok ? b : nullptr;
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
GlyphInfo Fonts::glyph(FontFace* ff, int px, std::uint32_t gid, bool synthBold) {
    Impl& im = *impl_;
    const GlyphKey key{ff->id, px, gid, synthBold};
    auto it = im.glyphs.find(key);
    if (it != im.glyphs.end()) return it->second;
    GlyphInfo g;
    g.empty = true;
    const float s = stbtt_ScaleForMappingEmToPixels(&ff->info, float(px));
    int x0, y0, x1, y1;
    stbtt_GetGlyphBitmapBox(&ff->info, int(gid), s, s, &x0, &y0, &x1, &y1);
    const int w0 = x1 - x0, h = y1 - y0;
    // An emboldened glyph is smeared to the right by `extra` pixels (a whole part and a fraction), so it is wider.
    const float extra = synthBold ? synthetic_bold_extra(px) : 0.0f;
    const int extraWhole = int(extra), extraCols = int(std::ceil(extra));
    const int w = w0 + extraCols;
    if (w0 <= 0 || h <= 0 || gid == 0) {  // whitespace, or the .notdef box of a missing character: nothing to draw
        im.glyphs[key] = g;
        return g;
    }
    int ax, ay;
    if (!im.pack(w, h, ax, ay)) {
        // Grow first (1024 -> 2048 -> 4096), clear only when the largest page is full. Either way the old UVs are
        // invalid: the layout cache is dropped (the texts lay out again on their next draw) and atlasEpoch moves, so the
        // frame being gathered is gathered again (Renderer::Impl::render).
        if (im.atlasSize < kMaxAtlas) {
            const int next = im.atlasSize * 2;
            FA_INFO("render", "glyph atlas is full ({0}x{0}); growing it to {1}x{1}. Every text lays out again.", im.atlasSize, next);
            im.reset_atlas(next);
        } else {
            FA_WARN("render", "glyph atlas is full ({0}x{0}); clearing it. Every text lays out again. Use fewer distinct font sizes "
                              "and scripts on screen at once to avoid the cost.", im.atlasSize);
            im.reset_atlas(im.atlasSize);
        }
        if (!im.pack(w, h, ax, ay)) return g;
    }
    stbtt_MakeGlyphBitmap(&ff->info, &im.pixels[std::size_t(ay) * im.atlasSize + ax], w0, h, im.atlasSize, s, s, int(gid));
    if (extraCols > 0) {  // out[x] = max of in[x - k] for k = 0..whole, and the fraction of in[x - whole - 1]; right to left, in place
        const float frac = extra - float(extraWhole);
        for (int yy = 0; yy < h; ++yy) {
            unsigned char* row = &im.pixels[std::size_t(ay + yy) * im.atlasSize + ax];
            for (int xx = w - 1; xx >= 0; --xx) {
                float v = 0;
                for (int k = 0; k <= extraWhole; ++k)
                    if (xx - k >= 0 && xx - k < w0) v = std::max(v, float(row[xx - k]));
                if (frac > 0 && xx - extraWhole - 1 >= 0 && xx - extraWhole - 1 < w0) v = std::max(v, frac * float(row[xx - extraWhole - 1]));
                row[xx] = static_cast<unsigned char>(std::min(255.0f, v + 0.5f));
            }
        }
    }
    im.dirty = true;
    const float inv = 1.0f / float(im.atlasSize);
    g.empty = false;
    g.u0 = ax * inv; g.v0 = ay * inv; g.u1 = (ax + w) * inv; g.v1 = (ay + h) * inv;
    g.x0 = float(x0); g.y0 = float(y0); g.x1 = float(x1 + extraCols); g.y1 = float(y1);
    im.glyphs[key] = g;
    return g;
}

TextLayout Fonts::layout(const Text& t, float fontSize, float pixelsPerUnit, bool tightBox) {
    Impl& im = *impl_;
    FontFace* primary = face(t.font);
    if (!primary || !primary->ok) return {};
    const float rasterPx = fontSize * pixelsPerUnit;
    const int px = std::clamp(int(std::lround(rasterPx)), 4, 400);
    const float unitsPerPx = fontSize / float(px);          // local units per raster pixel
    const float maxW = t.maxWidth > 0 ? t.maxWidth / unitsPerPx : 0.0f;  // in raster pixels

    struct KeyHead { float fontSize, maxWidth, pivotX, pivotY; int px, align, wordBreak; } head{};
    head.fontSize = fontSize; head.maxWidth = t.maxWidth; head.pivotX = t.pivot.x; head.pivotY = t.pivot.y;
    head.px = px; head.align = int(t.align) + (tightBox ? 1000 : 0) + (t.markup ? 2000 : 0) + (t.bold ? 4000 : 0);
    head.wordBreak = int(t.wordBreak);  // visibleCharacters is not part of the key: it clips a layout, it never changes one
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

    // ---- rich text: the visible characters, what styles each, and the pictures ----
    const bool rich = t.markup || t.bold;
    std::u32string text = decode_text(t.text);
    MarkupText mk;
    if (t.markup) {
        mk = parse_markup(text);
        text = mk.text;
        if (!mk.problems.empty() || !mk.colors.empty() || !mk.icons.empty()) warn_markup(t.text, mk);
    }
    std::vector<MarkupAttr> attrs = std::move(mk.attrs);
    if (t.bold) {
        attrs.resize(text.size());
        for (MarkupAttr& a : attrs) a.bold = true;
    }
    RichShaping shaping;
    TextLayout out;
    std::vector<int> iconDef(mk.icons.size(), -1);  // by markup icon index: index in out.iconDefs, or -1 (not defined: a blank box)
    std::vector<int> colorSlot(mk.colors.size() + 1, 0);  // by attr.color: 0 = the Text's colour, else palette index + 1
    if (rich) {
        shaping.attrs = &attrs;
        shaping.syntheticExtra = synthetic_bold_extra(px);
        shaping.boldFace = [this](FontFace* f) { return bold_face(f); };
        for (std::size_t i = 0; i < mk.icons.size(); ++i) {
            float aspect = 1.0f;
            if (const auto it = im.style.icons.find(mk.icons[i]); it != im.style.icons.end()) {
                aspect = float(it->second.w) / float(std::max(1, it->second.h));
                iconDef[i] = int(out.iconDefs.size());
                out.iconDefs.push_back(it->second);
            }
            shaping.iconAdvance.push_back(std::max(1.0f, std::round(lineH * aspect)));
        }
        out.palette.assign(mk.colors.size(), Color{1, 1, 1, 1});
        for (std::size_t i = 0; i < mk.colors.size(); ++i)
            if (rich_color(im.style, mk.colors[i], out.palette[i])) colorSlot[i + 1] = int(i) + 1;
    }
    const std::vector<RichIcon> iconDefs = out.iconDefs;
    const std::vector<Color> palette = out.palette;

    ShapedText shaped;
    for (int attempt = 0; attempt < 2; ++attempt) {  // a second pass when the atlas was reset halfway: UVs of the first are stale
        const unsigned epoch = im.atlasEpoch;
        shaped = shape_text(text, px, maxW, chainSize, chain, rich ? &shaping : nullptr, t.wordBreak);
        const std::vector<std::uint32_t> graphemeOf = grapheme_index(text);
        const auto grapheme_at = [&](std::uint32_t cluster) { return cluster < graphemeOf.size() ? std::int32_t(graphemeOf[cluster]) : std::int32_t(0); };
        out = TextLayout{};
        out.iconDefs = iconDefs;
        out.palette = palette;
        float boxW = 0;
        for (const ShapedLine& l : shaped.lines) boxW = std::max(boxW, l.width);
        const float boxH = lineH * float(shaped.lines.size());
        out.size = {boxW * unitsPerPx, boxH * unitsPerPx};  // the widest line: what measuring and ui.overflowed see
        // Centre and right alignment still work inside the maxWidth box (the pivot is that box's); the reported size is not.
        if (maxW > 0 && !tightBox && t.align != Align::Left) boxW = std::max(boxW, maxW);

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
                if (sg.icon >= 0) {  // a picture as tall as the line, from its top to its bottom
                    const int def = iconDef[std::size_t(sg.icon)];
                    if (def < 0) continue;
                    const float pen = std::round(x + sg.x);
                    out.icons.push_back({(ox + pen) * unitsPerPx, (top - lineH * float(li + 1)) * unitsPerPx,
                                         (ox + pen + sg.advance) * unitsPerPx, (top - lineH * float(li)) * unitsPerPx, def, grapheme_at(sg.cluster)});
                    continue;
                }
                if (sg.gid == 0) continue;
                const GlyphInfo g = glyph(sg.face, px, sg.gid, sg.synth);
                if (g.empty) continue;
                const float pen = std::round(x + sg.x), lift = std::round(sg.y);
                const float gx0 = pen + g.x0, gx1 = pen + g.x1;
                const float gy0 = baselineY - g.y1 + lift, gy1 = baselineY - g.y0 + lift;  // y up
                TextQuad q{(ox + gx0) * unitsPerPx, gy0 * unitsPerPx, (ox + gx1) * unitsPerPx, gy1 * unitsPerPx, g.u0, g.v0, g.u1, g.v1};
                q.grapheme = grapheme_at(sg.cluster);
                if (t.markup && sg.cluster < attrs.size()) q.color = std::uint16_t(colorSlot[std::size_t(attrs[sg.cluster].color)]);
                out.quads.push_back(q);
            }
        }
        if (im.atlasEpoch == epoch) break;
    }

    if (!shaped.missing.empty() && im.warnedMissing.insert(primary->key).second) warn_missing_glyphs(primary, t.text, shaped.missing);
    if (im.layouts.size() >= 4096) im.layouts.clear();
    im.layouts[cacheKey] = out;
    return out;
}

// Markup mistakes show on screen as written; the first time a text has one, the log says where and how to fix it.
void Fonts::warn_markup(const std::string& source, const MarkupText& m) {
    Impl& im = *impl_;
    (void)m;  // already parsed by the caller; markup_problems reads the same string against the project style
    const std::vector<std::string> problems = markup_problems(source, &im.style);
    for (const std::string& p : problems) {
        if (im.warnedRich.size() >= 256) return;  // a game full of bad strings does not flood the log
        if (!im.warnedRich.insert(source + "\n" + p).second) continue;
        std::string excerpt;
        const std::u32string cps = utf8_decode(source);
        for (std::size_t i = 0; i < cps.size() && i < 40; ++i) utf8_append(excerpt, cps[i]);
        if (cps.size() > 40) excerpt += "...";
        FA_WARN("render", "markup in text \"{}\": {} (Text.markup is on: docs/TEXT.md \"Rich text\"; reported once per text.)", excerpt, p);
    }
}

// Text that draws as nothing is the worst kind of bug to find, so the first missing glyph of each font says which
// characters, and what to do: a font already in use that has them, else the kind of font that does.
void Fonts::warn_missing_glyphs(FontFace* f, const std::string& text, const std::vector<char32_t>& missing) {
    std::string chars;
    for (char32_t cp : missing) chars += std::format("{}U+{:04X} '{}'", chars.empty() ? "" : ", ", unsigned(cp), utf8_encode(cp));
    std::string excerpt;
    const std::u32string cps = utf8_decode(text);
    for (std::size_t i = 0; i < cps.size() && i < 24; ++i) utf8_append(excerpt, cps[i]);
    if (cps.size() > 24) excerpt += "...";
    std::string label = font_label(f->key);
    if (!impl_->fallbackKeys.empty()) {  // the whole chain was searched
        label += " (and its fallback fonts";
        for (std::size_t i = 0; i < impl_->fallbackKeys.size(); ++i) label += (i ? ", " : " ") + font_label(impl_->fallbackKeys[i]);
        label += ")";
    }
    // The fix that suits every Text of the game: the font lists of factoria.json. A Text's own "font" works for one Text.
    const std::string project = "list it in factoria.json (localization.fallbackFonts, or localization.languageFonts for one language: "
                                "docs/TEXT.md) or set the Text's \"font\" to it";
    std::string hint;
    for (const auto& [key, other] : impl_->faces) {
        if (other.get() == f || !other->ok) continue;
        bool all = true;
        for (char32_t cp : missing) all = all && other->has_glyph(cp);
        if (all) {
            hint = std::format("The font {} (already used in this game) has them: {}.", font_label(key), project);
            break;
        }
    }
    if (hint.empty()) {
        if (std::any_of(missing.begin(), missing.end(), is_cjk))
            hint = "Chinese, Japanese and Korean need a font that covers them, such as Noto Sans SC, JP or KR (SIL Open Font "
                   "License): put its .ttf in assets/fonts/ and " + project + ". The built-in fonts cover Latin, Greek, Cyrillic, "
                   "Hebrew and Arabic.";
        else if (std::any_of(missing.begin(), missing.end(), is_emoji))
            hint = "Colour emoji fonts are not supported (only TrueType outlines): draw emoji as sprites.";
        else
            hint = "Use a .ttf that covers them (the Noto fonts have one per script): put it in assets/fonts/ and " + project + ".";
    }
    FA_WARN("render", "text \"{}\" has characters the font {} has no glyph for, so they draw as nothing: {}. {} (Reported once per font.)",
            excerpt, label, chars, hint);
}

unsigned Fonts::atlas_epoch() const { return impl_->atlasEpoch; }
int Fonts::atlas_size() const { return impl_->atlasSize; }

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
