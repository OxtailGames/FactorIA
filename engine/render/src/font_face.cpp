// Loading font files (built-in or from the project) and decoding UTF-8 text.
#include <algorithm>
#include <format>

#include "embedded_fonts.h"
#include "fa/core/fs.h"
#include "font_internal.h"

namespace fa::render {

FontFace::~FontFace() {
    if (hbFont) hb_font_destroy(hbFont);
    if (hbFace) hb_face_destroy(hbFace);
    if (blob) hb_blob_destroy(blob);
}

bool FontFace::has_glyph(std::uint32_t cp) const {
    hb_codepoint_t glyph = 0;
    return hbFont && hb_font_get_nominal_glyph(hbFont, cp, &glyph) && glyph != 0;
}

std::unique_ptr<FontFace> load_font_face(const std::string& keyIn) {
    auto f = std::make_unique<FontFace>();
    f->key = keyIn.empty() ? "builtin" : keyIn;
    const std::string& font = f->key;
    auto init_builtin = [&](const char* name) {
        for (const auto& file : fa_render_fonts::files()) {
            if (file.path == name) {
                f->data = reinterpret_cast<const unsigned char*>(file.data.data());
                f->size = file.data.size();
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
            f->error = std::format("font '{}' not found: {}", font, bytes.error().message);
            f->hint = "Use \"\" (DejaVu Sans), \"builtin:pixel\" (Press Start 2P) or a .ttf path inside the project, e.g. assets/fonts/MyFont.ttf.";
            return f;
        }
        f->ownedData = std::move(*bytes);
        f->data = f->ownedData.data();
        f->size = f->ownedData.size();
    }
    if (!f->data || !stbtt_InitFont(&f->info, f->data, stbtt_GetFontOffsetForIndex(f->data, 0))) {
        f->error = std::format("'{}' is not a usable TrueType font (stb_truetype cannot parse it)", font);
        f->hint = "Only .ttf (and TrueType-flavoured .otf) files are supported; convert other formats.";
        return f;
    }
    f->blob = hb_blob_create(reinterpret_cast<const char*>(f->data), static_cast<unsigned>(f->size), HB_MEMORY_MODE_READONLY,
                             nullptr, nullptr);
    f->hbFace = hb_face_create(f->blob, 0);
    if (hb_face_get_glyph_count(f->hbFace) == 0) {
        f->error = std::format("'{}' is not a usable font (HarfBuzz finds no glyphs in it)", font);
        f->hint = "Only .ttf (and TrueType-flavoured .otf) files are supported; convert other formats.";
        return f;
    }
    f->unitsPerEm = std::max(16, int(hb_face_get_upem(f->hbFace)));
    f->hbFont = hb_font_create(f->hbFace);
    hb_font_set_scale(f->hbFont, f->unitsPerEm, f->unitsPerEm);
    f->ok = true;
    return f;
}

// ---- text ------------------------------------------------------------------------------------------------------------

std::u32string decode_utf8(std::string_view s) {
    std::u32string out;
    out.reserve(s.size());
    std::size_t i = 0;
    while (i < s.size()) {
        const unsigned char c = static_cast<unsigned char>(s[i]);
        int extra = c < 0x80 ? 0 : (c >= 0xF0 && c < 0xF8) ? 3 : (c >= 0xE0 && c < 0xF0) ? 2 : (c >= 0xC2 && c < 0xE0) ? 1 : -1;
        char32_t cp = extra == 0 ? c : extra > 0 ? char32_t(c & (0x3F >> extra)) : 0xFFFD;
        ++i;
        for (int k = 0; k < extra; ++k) {
            if (i >= s.size() || (static_cast<unsigned char>(s[i]) & 0xC0) != 0x80) { cp = 0xFFFD; break; }
            cp = (cp << 6) | (static_cast<unsigned char>(s[i++]) & 0x3F);
        }
        if (cp > 0x10FFFF || (cp >= 0xD800 && cp <= 0xDFFF)) cp = 0xFFFD;
        out.push_back(cp);
    }
    return out;
}

std::u32string decode_text(std::string_view utf8) {
    std::u32string out;
    for (char32_t cp : decode_utf8(utf8)) {
        if (cp == '\n' || cp == 0x85 || cp == 0x2028 || cp == 0x2029) out.push_back('\n');
        else if (cp == '\t') out.append(4, U' ');
        else if (cp < 0x20 || (cp >= 0x7F && cp < 0xA0)) continue;  // '\r' and the other controls draw nothing
        else out.push_back(cp);
    }
    return out;
}

std::string encode_utf8(char32_t cp) {
    std::string o;
    if (cp < 0x80) o += char(cp);
    else if (cp < 0x800) o += char(0xC0 | (cp >> 6)), o += char(0x80 | (cp & 0x3F));
    else if (cp < 0x10000) o += char(0xE0 | (cp >> 12)), o += char(0x80 | ((cp >> 6) & 0x3F)), o += char(0x80 | (cp & 0x3F));
    else o += char(0xF0 | (cp >> 18)), o += char(0x80 | ((cp >> 12) & 0x3F)), o += char(0x80 | ((cp >> 6) & 0x3F)), o += char(0x80 | (cp & 0x3F));
    return o;
}

bool is_visible(char32_t cp) {
    return cp > 32 && !(cp >= 0x7F && cp < 0xA0) && cp != 0xAD && cp != 0x34F && !(cp >= 0x200B && cp <= 0x200F) &&
           !(cp >= 0x2028 && cp <= 0x202E) && !(cp >= 0x2060 && cp <= 0x206F) && !(cp >= 0xFE00 && cp <= 0xFE0F) && cp != 0xFEFF &&
           !(cp >= 0xE0100 && cp <= 0xE01EF);
}

bool is_cjk(char32_t cp) {
    return (cp >= 0x1100 && cp <= 0x11FF) || (cp >= 0x2E80 && cp <= 0x9FFF) || (cp >= 0xA960 && cp <= 0xA97F) ||
           (cp >= 0xAC00 && cp <= 0xD7FF) || (cp >= 0xF900 && cp <= 0xFAFF) || (cp >= 0xFF00 && cp <= 0xFFEF) ||
           (cp >= 0x20000 && cp <= 0x3FFFF);
}

bool is_emoji(char32_t cp) { return (cp >= 0x1F000 && cp <= 0x1FAFF) || (cp >= 0x2600 && cp <= 0x27BF); }

}  // namespace fa::render
