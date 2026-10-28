// The catalog of built-in fonts (fa/render/builtin_fonts.h) and where their files come from.
#include "fa/render/builtin_fonts.h"

#include <algorithm>
#include <cctype>

namespace fa {

const std::vector<BuiltinFont>& builtin_fonts() {
    static const std::vector<BuiltinFont> list = {
        {"builtin", "DejaVu Sans", "the default font: Latin, Greek, Cyrillic, Hebrew, Arabic and many symbols; \"\" means the same", true,
         false, false, false, {}},
        {"builtin:pixel", "Press Start 2P", "an 8-bit pixel font (Latin, Greek, Cyrillic; capitals and digits are its best)", true, false,
         false, false, {}},
        {"builtin:serif", "Crimson Text",
         "a book serif for running text, with real bold, italic and bold italic faces (Latin with Spanish, German and French accents)",
         false, true, true, true,
         {"CrimsonText-Regular.ttf", "CrimsonText-Bold.ttf", "CrimsonText-Italic.ttf", "CrimsonText-BoldItalic.ttf"}},
        {"builtin:hand", "Kalam", "handwriting, with a real bold face (Latin with accents, Devanagari)", false, true, false, false,
         {"Kalam-Regular.ttf", "Kalam-Bold.ttf"}},
        {"builtin:blackletter", "UnifrakturMaguntia", "a blackletter title face (Latin only: use it for short titles)", false, false,
         false, false, {"UnifrakturMaguntia-Book.ttf"}},
        {"builtin:display", "IM Fell English", "an old-print storybook face for titles and text, with a real italic face (Latin)", false,
         false, true, false, {"IMFeENrm28P.ttf", "IMFeENit28P.ttf"}},
    };
    return list;
}

std::string builtin_font_list() {
    std::string out;
    for (const BuiltinFont& f : builtin_fonts()) {
        if (!out.empty()) out += ", ";
        out += (f.name == "builtin" ? std::string("\"\"") : "\"" + f.name + "\"") + " (" + f.family + ")";
    }
    return out;
}

const BuiltinFont* find_builtin_font(std::string_view name) {
    if (name.empty()) name = "builtin";
    for (const BuiltinFont& f : builtin_fonts())
        if (f.name == name) return &f;
    return nullptr;
}

std::vector<const BuiltinFont*> builtin_fonts_named_in(std::string_view text) {
    std::vector<const BuiltinFont*> out;
    for (const BuiltinFont& f : builtin_fonts()) {
        if (f.embedded) continue;
        for (std::size_t at = text.find(f.name); at != std::string_view::npos; at = text.find(f.name, at + 1)) {
            const std::size_t end = at + f.name.size();
            const unsigned char next = end < text.size() ? static_cast<unsigned char>(text[end]) : 0;
            if (std::isalnum(next) || next == '-' || next == '_') continue;
            out.push_back(&f);
            break;
        }
    }
    return out;
}

std::string builtin_variant_file(const BuiltinFont& f, bool bold, bool italic) {
    if (f.files.empty()) return {};
    std::size_t idx = 0;
    const std::size_t boldIdx = f.hasBold ? ++idx : 0;
    const std::size_t italicIdx = f.hasItalic ? ++idx : 0;
    const std::size_t boldItalicIdx = f.hasBoldItalic ? ++idx : 0;
    if (bold && italic) return boldItalicIdx ? f.files[boldItalicIdx] : std::string();
    if (bold) return boldIdx ? f.files[boldIdx] : std::string();
    if (italic) return italicIdx ? f.files[italicIdx] : std::string();
    return f.files[0];
}

namespace {
BuiltinFontSource& source() {
    static BuiltinFontSource s;
    return s;
}
}  // namespace

void set_builtin_font_source(BuiltinFontSource s) { source() = std::move(s); }

std::optional<std::string> builtin_font_file(std::string_view file) {
    if (!source()) return std::nullopt;
    return source()(file);
}

}  // namespace fa
