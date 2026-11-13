// FontSet: the fonts of a game and the CPU side of laying a text out (font_set.h). Placing the glyphs in the GPU atlas is
// fonts.cpp.
#include "font_set.h"

#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/fs.h"
#include "fa/core/load_trace.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/core/utf8.h"
#include "fa/render/builtin_fonts.h"

namespace fa::render {

float synthetic_bold_extra(int px) { return std::clamp(float(px) * 0.04f, 0.7f, 6.0f); }

int text_raster_px(float fontSize, float pixelsPerUnit) {
    return std::clamp(int(std::lround(fontSize * pixelsPerUnit)), 4, 400);
}

std::string font_face_key(const std::string& font) {
    if (font.empty()) return "builtin";
    if (font == "builtin" || font.rfind("builtin:", 0) == 0) return font;
    std::string n = fs::normalize(font);
    return n.empty() ? font : n;
}

namespace {
std::string font_label(const std::string& key) {
    if (key == "builtin") return "'' (DejaVu Sans, the default font)";
    if (const BuiltinFont* b = key.rfind("builtin:", 0) == 0 ? find_builtin_font(key) : nullptr)
        return "'" + key + "' (" + b->family + ", and DejaVu Sans behind it)";
    return "'" + key + "'";
}
}  // namespace

FontSet::FontSet(FailureNote note) : note_(std::move(note)) {}

void FontSet::clear() {
    faces_.clear();
    warnedMissing_.clear();
    sizes_.clear();
    ++generation_;
}

void FontSet::set_fallback_fonts(std::vector<std::string> fonts) {
    if (fonts == fallbackKeys_) return;
    fallbackKeys_ = std::move(fonts);
    sizes_.clear();
    warnedMissing_.clear();  // a new chain may cover (or miss) other characters
    ++generation_;
}

void FontSet::set_rich_style(const RichTextStyle& style) {
    if (style == style_) return;
    style_ = style;
    for (auto* m : {&style_.boldFonts, &style_.italicFonts}) {
        std::map<std::string, std::string> keyed;  // keyed like the faces (font_face_key): "" names the built-in font
        for (const auto& [regular, variant] : *m) keyed[font_face_key(regular)] = variant;
        *m = std::move(keyed);
    }
    sizes_.clear();
    warnedRich_.clear();
    ++generation_;
}

// The face a project or a built-in family gives `regular` for bold and/or italic text, or null (a bold character is then
// emboldened by the engine; an italic one stays upright). The project's text.fonts entry wins over the built-in family's face.
// Bold italic asks for the family's own bold italic face; without one it settles for the bold face, then the italic one.
FontFace* FontSet::variant_face(FontFace* regular, bool bold, bool italic, bool& boldDrawn) {
    boldDrawn = false;
    const auto from_map = [&](const std::map<std::string, std::string>& m) -> FontFace* {
        const auto it = m.find(regular->key);
        if (it == m.end() || it->second == regular->key) return nullptr;
        FontFace* f = load(it->second);
        return f->ok ? f : nullptr;
    };
    const auto builtin = [&](bool b, bool i) -> FontFace* {
        if (regular->key.rfind("builtin:", 0) != 0 || regular->key.find('#') != std::string::npos) return nullptr;
        const BuiltinFont* family = find_builtin_font(regular->key);
        if (!family || builtin_variant_file(*family, b, i).empty()) return nullptr;
        FontFace* f = load(regular->key + (b && i ? "#bolditalic" : b ? "#bold" : "#italic"));
        return f->ok ? f : nullptr;
    };
    if (bold && italic) {
        if (FontFace* f = builtin(true, true)) {
            boldDrawn = true;
            return f;
        }
    }
    if (bold) {
        FontFace* f = from_map(style_.boldFonts);
        if (!f) f = builtin(true, false);
        if (f) {
            boldDrawn = true;
            return f;
        }
    }
    if (italic) {
        FontFace* f = from_map(style_.italicFonts);
        if (!f) f = builtin(false, true);
        if (f) return f;
    }
    return nullptr;
}

FontFace* FontSet::load(const std::string& fontIn) {
    const std::string font = font_face_key(fontIn);
    auto it = faces_.find(font);
    if (it != faces_.end()) {
        FontFace* f = it->second.get();
        if (!f->untraced.empty() && LoadTrace::current_ahead_tag() == 0) {  // loaded in the background: first use now
            for (const std::string& file : f->untraced) LoadTrace::file_used(file);
            f->untraced.clear();
        }
        return f;
    }
    std::unique_ptr<FontFace> f = load_font_face(font);
    f->id = nextId_++;
    if (!f->ok && note_) note_(font, f->error, f->hint);
    FontFace* raw = f.get();
    faces_[font] = std::move(f);
    return raw;
}

bool FontSet::has_face(const std::string& font) const { return faces_.count(font_face_key(font)) > 0; }

void FontSet::adopt(std::unique_ptr<FontFace> f, std::vector<std::string> files) {
    if (!f) return;
    f->key = font_face_key(f->key);
    if (faces_.count(f->key)) return;  // loaded on first use meanwhile: that one stays
    f->id = nextId_++;
    if (!f->ok && note_) note_(f->key, f->error, f->hint);  // as a load on first use reports it
    f->untraced = std::move(files);
    const std::string key = f->key;
    faces_[key] = std::move(f);
}

FontFace* FontSet::face(const std::string& font) {
    FontFace* f = load(font);
    return f->ok || f->key == "builtin" ? f : load("builtin");
}

Json FontSet::report() const {
    Json j = Json::array();
    for (const auto& [k, f] : faces_) j.push_back({{"font", k}, {"ok", f->ok}});
    return j;
}

TextPrep FontSet::prepare(const Text& t, float fontSize, float pixelsPerUnit) {
    TextPrep out;
    FontFace* primary = face(t.font);
    if (!primary || !primary->ok) return out;
    out.primary = primary;
    out.px = text_raster_px(fontSize, pixelsPerUnit);
    out.unitsPerPx = fontSize / float(out.px);                       // local units per raster pixel
    out.maxW = t.maxWidth > 0 ? t.maxWidth / out.unitsPerPx : 0.0f;  // in raster pixels
    const int px = out.px;

    // The chain: the Text's font, the project's fallback fonts, the built-in DejaVu Sans last.
    const std::size_t chainSize = fallbackKeys_.size() + 2;
    const auto chain = [&](std::size_t k) -> FontFace* {
        if (k == 0) return primary;
        return load(k == chainSize - 1 ? std::string("builtin") : fallbackKeys_[k - 1]);
    };

    const float scale = stbtt_ScaleForMappingEmToPixels(&primary->info, float(px));
    int asc, desc, gap;
    stbtt_GetFontVMetrics(&primary->info, &asc, &desc, &gap);
    out.fm = FontMetrics{asc * scale, desc * scale, gap * scale};
    // ponytail: every line is as tall as the Text's own font says, whatever fallback fonts draw on it; a fallback with much
    // taller letters (some CJK fonts) can touch the next line. Take the tallest font used in the text when that matters.
    out.lineH = std::round(out.fm.lineHeight());
    if (out.lineH < 1) out.lineH = float(px);

    // ---- rich text: the visible characters, what styles each, and the pictures ----
    out.rich = t.markup || t.bold;
    out.text = decode_text(t.text);
    MarkupText mk;
    if (t.markup) {
        mk = parse_markup(out.text);
        out.text = mk.text;
        if (!mk.problems.empty() || !mk.colors.empty() || !mk.icons.empty()) warn_markup(t.text);
    }
    out.attrs = std::move(mk.attrs);
    if (t.bold) {
        out.attrs.resize(out.text.size());
        for (MarkupAttr& a : out.attrs) a.bold = true;
    }
    RichShaping shaping;
    out.iconDef.assign(mk.icons.size(), -1);
    out.colorSlot.assign(mk.colors.size() + 1, 0);
    if (out.rich) {
        shaping.attrs = &out.attrs;
        shaping.syntheticExtra = synthetic_bold_extra(px);
        shaping.variantFace = [this](FontFace* f, bool bold, bool italic, bool& boldDrawn) {
            return variant_face(f, bold, italic, boldDrawn);
        };
        for (std::size_t i = 0; i < mk.icons.size(); ++i) {
            float aspect = 1.0f;
            if (const auto it = style_.icons.find(mk.icons[i]); it != style_.icons.end()) {
                aspect = float(it->second.w) / float(std::max(1, it->second.h));
                out.iconDef[i] = int(out.iconDefs.size());
                out.iconDefs.push_back(it->second);
            }
            shaping.iconAdvance.push_back(std::max(1.0f, std::round(out.lineH * aspect)));
        }
        out.palette.assign(mk.colors.size(), Color{1, 1, 1, 1});
        for (std::size_t i = 0; i < mk.colors.size(); ++i)
            if (rich_color(style_, mk.colors[i], out.palette[i])) out.colorSlot[i + 1] = int(i) + 1;
    }

    out.shaped =
        shape_text(out.text, px, out.maxW, chainSize, chain, out.rich ? &shaping : nullptr, t.wordBreak, t.direction);
    float boxW = 0;
    for (const ShapedLine& l : out.shaped.lines) boxW = std::max(boxW, l.width);
    const float boxH = out.lineH * float(out.shaped.lines.size());
    out.size = {boxW * out.unitsPerPx, boxH * out.unitsPerPx};  // the widest line: what measuring and ui.overflowed see

    if (!out.shaped.missing.empty() && warnedMissing_.insert(primary->key).second)
        warn_missing_glyphs(primary, t.text, out.shaped.missing);
    return out;
}

std::optional<Vec2> FontSet::measure(const Text& t, float fontSize, float pixelsPerUnit) {
    FontFace* primary = face(t.font);
    if (!primary || !primary->ok) return std::nullopt;
    struct KeyHead {
        float fontSize, maxWidth;
        int px, flags, wordBreak, direction;
    } head{};
    head.fontSize = fontSize;
    head.maxWidth = t.maxWidth;
    head.px = text_raster_px(fontSize, pixelsPerUnit);
    head.flags = (t.markup ? 1 : 0) + (t.bold ? 2 : 0);
    head.wordBreak = int(t.wordBreak);
    head.direction = int(t.direction);
    std::string key(reinterpret_cast<const char*>(&head), sizeof head);
    key += t.font;
    key.push_back('\0');
    key += t.text;
    if (const auto hit = sizes_.find(key); hit != sizes_.end()) return hit->second;
    const TextPrep prep = prepare(t, fontSize, pixelsPerUnit);
    if (!prep.primary) return std::nullopt;
    if (sizes_.size() >= 4096) sizes_.clear();
    sizes_[key] = prep.size;
    return prep.size;
}

// Markup mistakes show on screen as written; the first time a text has one, the log says where and how to fix it.
void FontSet::warn_markup(const std::string& source) {
    const std::vector<std::string> problems = markup_problems(source, &style_);
    for (const std::string& p : problems) {
        if (warnedRich_.size() >= 256) return;  // a game full of bad strings does not flood the log
        if (!warnedRich_.insert(source + "\n" + p).second) continue;
        std::string excerpt;
        const std::u32string cps = utf8_decode(source);
        for (std::size_t i = 0; i < cps.size() && i < 40; ++i) utf8_append(excerpt, cps[i]);
        if (cps.size() > 40) excerpt += "...";
        FA_WARN("render",
                "markup in text \"{}\": {} (Text.markup is on: docs/TEXT.md \"Rich text\"; reported once per text.)",
                excerpt, p);
    }
}

// Text that draws as nothing is the worst kind of bug to find, so the first missing glyph of each font says which
// characters, and what to do: a font already in use that has them, else the kind of font that does.
void FontSet::warn_missing_glyphs(FontFace* f, const std::string& text, const std::vector<char32_t>& missing) {
    std::string chars;
    for (char32_t cp : missing)
        chars += std::format("{}U+{:04X} '{}'", chars.empty() ? "" : ", ", unsigned(cp), utf8_encode(cp));
    std::string excerpt;
    const std::u32string cps = utf8_decode(text);
    for (std::size_t i = 0; i < cps.size() && i < 24; ++i) utf8_append(excerpt, cps[i]);
    if (cps.size() > 24) excerpt += "...";
    std::string label = font_label(f->key);
    if (!fallbackKeys_.empty()) {  // the whole chain was searched
        label += " (and its fallback fonts";
        for (std::size_t i = 0; i < fallbackKeys_.size(); ++i) label += (i ? ", " : " ") + font_label(fallbackKeys_[i]);
        label += ")";
    }
    // The fix that suits every Text of the game: the font lists of factoria.json. A Text's own "font" works for one Text.
    const std::string project =
        "list it in factoria.json (localization.fallbackFonts, or localization.languageFonts for one language: "
        "docs/TEXT.md) or set the Text's \"font\" to it";
    std::string hint;
    for (const auto& [key, other] : faces_) {
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
            hint = "Chinese, Japanese and Korean need a font that covers them, such as Noto Sans SC, JP or KR (SIL "
                   "Open Font "
                   "License): put its .ttf in assets/fonts/ and " +
                   project +
                   ". The built-in fonts cover Latin, Greek, Cyrillic, "
                   "Hebrew and Arabic.";
        else if (std::any_of(missing.begin(), missing.end(), is_emoji))
            hint = "Colour emoji fonts are not supported (only TrueType outlines): draw emoji as sprites.";
        else
            hint = "Use a .ttf that covers them (the Noto fonts have one per script): put it in assets/fonts/ and " +
                   project + ".";
    }
    FA_WARN("render",
            "text \"{}\" has characters the font {} has no glyph for, so they draw as nothing: {}. {} (Reported once "
            "per font.)",
            excerpt, label, chars, hint);
}

}  // namespace fa::render
