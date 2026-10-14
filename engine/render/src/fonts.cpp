// Fonts: stb_truetype rasterization into a shared R8 glyph atlas, text layout.
#include <algorithm>
#include <cstring>
#include <format>

#include <stb_truetype.h>

#include "embedded_fonts.h"
#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "render_internal.h"

namespace fa::render {

struct FontFace {
    std::string key;
    std::vector<unsigned char> ownedData;   // for project fonts
    const unsigned char* data = nullptr;
    stbtt_fontinfo info{};
    bool ok = false;
    int id = 0;
};

namespace {
struct GlyphKey {
    int face;
    int px;
    std::uint32_t cp;
    bool operator==(const GlyphKey& o) const { return face == o.face && px == o.px && cp == o.cp; }
};
struct GlyphKeyHash {
    std::size_t operator()(const GlyphKey& k) const {
        return std::size_t(k.cp) * 2654435761u ^ std::size_t(k.px) * 40503u ^ std::size_t(k.face) * 977u;
    }
};

std::uint32_t next_codepoint(const std::string& s, std::size_t& i) {
    unsigned char c = (unsigned char)s[i++];
    if (c < 0x80) return c;
    int extra = (c >= 0xF0) ? 3 : (c >= 0xE0) ? 2 : (c >= 0xC0) ? 1 : 0;
    if (extra == 0) return 0xFFFD;
    std::uint32_t cp = c & (0x3F >> extra);
    for (int k = 0; k < extra && i < s.size(); ++k) cp = (cp << 6) | ((unsigned char)s[i++] & 0x3F);
    return cp;
}
}  // namespace

struct Fonts::Impl {
    std::unordered_map<std::string, std::unique_ptr<FontFace>> faces;
    std::unordered_map<GlyphKey, GlyphInfo, GlyphKeyHash> glyphs;
    int atlasSize = 1024;
    std::vector<unsigned char> pixels;  // R8
    struct Shelf { int y, h, x; };
    std::vector<Shelf> shelves;
    bool dirty = true;
    bool warnedFull = false;
    int nextId = 1;

    void reset_atlas(int size) {
        atlasSize = size;
        pixels.assign(std::size_t(size) * size, 0);
        shelves.clear();
        glyphs.clear();
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
    impl_->reset_atlas(1024);
}

FontFace* Fonts::face(const std::string& fontIn) {
    std::string font = fontIn;
    if (font.empty()) font = "builtin";
    auto it = impl_->faces.find(font);
    if (it != impl_->faces.end()) return it->second.get();
    auto f = std::make_unique<FontFace>();
    f->key = font;
    f->id = impl_->nextId++;
    auto init_builtin = [&](const char* name) {
        for (const auto& file : fa_render_fonts::files()) {
            if (file.path == name) {
                f->data = reinterpret_cast<const unsigned char*>(file.data.data());
                return true;
            }
        }
        return false;
    };
    if (font == "builtin") init_builtin("DejaVuSans.ttf");
    else if (font == "builtin:pixel") init_builtin("PressStart2P-Regular.ttf");
    else {
        auto bytes = fs::read_bytes(font);
        if (!bytes) {
            assets_.note_failure("font", font, std::format("font '{}' not found: {}", font, bytes.error().message),
                                 "Use \"\" (DejaVu Sans), \"builtin:pixel\" (Press Start 2P) or a .ttf path inside the project, e.g. assets/fonts/MyFont.ttf.");
        } else {
            f->ownedData = std::move(*bytes);
            f->data = f->ownedData.data();
        }
    }
    if (f->data && stbtt_InitFont(&f->info, f->data, stbtt_GetFontOffsetForIndex(f->data, 0))) {
        f->ok = true;
    } else if (f->data) {
        assets_.note_failure("font", font, std::format("'{}' is not a usable TrueType font (stb_truetype cannot parse it)", font),
                             "Only .ttf (and TrueType-flavoured .otf) files are supported; convert other formats.");
    }
    FontFace* raw = f.get();
    impl_->faces[font] = std::move(f);
    if (!raw->ok && font != "builtin") return face("builtin");
    return raw;
}

TextLayout Fonts::layout(const Text& t, float rasterPx, float unitsPerPx) {
    TextLayout out;
    FontFace* f = face(t.font);
    FontFace* fallback = face("builtin");
    if (!f || !f->ok) return out;
    int px = std::clamp(int(std::lround(rasterPx)), 4, 400);
    Impl& im = *impl_;

    struct Lookup { FontFace* face; float scale; };
    auto scale_for = [&](FontFace* ff) { return stbtt_ScaleForMappingEmToPixels(&ff->info, float(px)); };
    float scale = scale_for(f);
    int asc, desc, gap;
    stbtt_GetFontVMetrics(&f->info, &asc, &desc, &gap);
    FontMetrics fm{asc * scale, desc * scale, gap * scale};
    float lineH = std::round(fm.lineHeight());
    if (lineH < 1) lineH = float(px);

    auto get_glyph = [&](std::uint32_t cp) -> GlyphInfo {
        FontFace* ff = f;
        if (!stbtt_FindGlyphIndex(&ff->info, int(cp)) && cp > 32 && fallback && fallback != f &&
            stbtt_FindGlyphIndex(&fallback->info, int(cp)))
            ff = fallback;
        GlyphKey key{ff->id, px, cp};
        auto it = im.glyphs.find(key);
        if (it != im.glyphs.end()) return it->second;
        GlyphInfo g;
        int gi = stbtt_FindGlyphIndex(&ff->info, int(cp));
        float s = scale_for(ff);
        int adv, lsb;
        stbtt_GetGlyphHMetrics(&ff->info, gi, &adv, &lsb);
        g.advance = adv * s;
        g.valid = gi != 0 || cp == ' ';
        int x0, y0, x1, y1;
        stbtt_GetGlyphBitmapBox(&ff->info, gi, s, s, &x0, &y0, &x1, &y1);
        int w = x1 - x0, h = y1 - y0;
        if (w <= 0 || h <= 0 || gi == 0) {
            g.empty = true;
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
            if (!im.pack(w, h, ax, ay)) { g.empty = true; return g; }
        }
        stbtt_MakeGlyphBitmap(&ff->info, &im.pixels[std::size_t(ay) * im.atlasSize + ax], w, h, im.atlasSize, s, s, gi);
        im.dirty = true;
        float inv = 1.0f / float(im.atlasSize);
        g.u0 = ax * inv; g.v0 = ay * inv; g.u1 = (ax + w) * inv; g.v1 = (ay + h) * inv;
        g.x0 = float(x0); g.y0 = float(y0); g.x1 = float(x1); g.y1 = float(y1);
        im.glyphs[key] = g;
        return g;
    };

    // ---- break into lines ----
    float maxW = t.maxWidth > 0 ? t.maxWidth / unitsPerPx : 0.0f;  // in raster pixels
    struct Line { std::vector<std::uint32_t> cps; float width = 0; };
    std::vector<Line> lines(1);
    auto word_width = [&](const std::vector<std::uint32_t>& w) {
        float s = 0;
        for (auto c : w) s += get_glyph(c).advance;
        return s;
    };
    std::vector<std::uint32_t> word;
    auto flush_word = [&]() {
        if (word.empty()) return;
        float ww = word_width(word);
        if (maxW > 0 && lines.back().width + ww > maxW && !lines.back().cps.empty()) {
            // trim trailing spaces of the previous line
            while (!lines.back().cps.empty() && lines.back().cps.back() == ' ') {
                lines.back().width -= get_glyph(' ').advance;
                lines.back().cps.pop_back();
            }
            lines.emplace_back();
        }
        for (auto c : word) lines.back().cps.push_back(c);
        lines.back().width += ww;
        word.clear();
    };
    std::size_t i = 0;
    while (i < t.text.size()) {
        std::uint32_t cp = next_codepoint(t.text, i);
        if (cp == '\n') { flush_word(); lines.emplace_back(); continue; }
        if (cp == '\r') continue;
        if (cp == ' ' || cp == '\t') {
            flush_word();
            if (maxW > 0 && lines.back().cps.empty()) continue;  // no leading spaces on wrapped lines
            lines.back().cps.push_back(' ');
            lines.back().width += get_glyph(' ').advance * (cp == '\t' ? 4 : 1);
            continue;
        }
        word.push_back(cp);
    }
    flush_word();

    float boxW = 0;
    for (auto& l : lines) boxW = std::max(boxW, l.width);
    if (maxW > 0) boxW = std::max(boxW, maxW);
    float boxH = lineH * float(lines.size());
    out.size = {boxW * unitsPerPx, boxH * unitsPerPx};

    // ---- place glyphs (raster pixels, y down from the box top) ----
    float ox = -t.pivot.x * boxW;
    float top = (1.0f - t.pivot.y) * boxH;  // distance of the box top above the anchor (y up)
    for (std::size_t li = 0; li < lines.size(); ++li) {
        const Line& l = lines[li];
        float x = 0;
        if (t.align == Align::Center) x = (boxW - l.width) * 0.5f;
        else if (t.align == Align::Right) x = boxW - l.width;
        x = std::round(x);
        float baselineY = top - std::round(fm.ascent) - lineH * float(li);  // y up
        float pen = x;
        for (auto cp : l.cps) {
            GlyphInfo g = get_glyph(cp);
            ++glyphsLaidOut_;
            if (!g.empty) {
                float gx0 = std::round(pen) + g.x0, gx1 = std::round(pen) + g.x1;
                float gy0 = baselineY - g.y1, gy1 = baselineY - g.y0;  // y up
                out.quads.push_back({(ox + gx0) * unitsPerPx, gy0 * unitsPerPx, (ox + gx1) * unitsPerPx, gy1 * unitsPerPx,
                                     g.u0, g.v0, g.u1, g.v1});
            }
            pen += g.advance;
        }
    }
    return out;
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
