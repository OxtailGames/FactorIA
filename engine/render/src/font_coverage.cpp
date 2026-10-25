// FontCoverage: which characters of a text no font of a chain has (fa/render/fonts.h).
#include "fa/render/fonts.h"

#include <algorithm>

#include "font_internal.h"

namespace fa {

struct FontCoverage::Impl {
    std::vector<std::unique_ptr<render::FontFace>> fonts;
};

Result<FontCoverage> FontCoverage::load(const std::vector<std::string>& fontChain) {
    auto impl = std::make_shared<Impl>();
    std::vector<std::string> keys = fontChain;
    keys.push_back("builtin");
    for (std::size_t i = 0; i < keys.size(); ++i) {
        // the same file twice (e.g. a Text font that is also a fallback) is read once
        if (std::any_of(impl->fonts.begin(), impl->fonts.end(), [&](const auto& f) { return f->key == (keys[i].empty() ? "builtin" : keys[i]); }))
            continue;
        auto face = render::load_font_face(keys[i]);
        if (!face->ok) return make_error(face->error, face->hint);
        impl->fonts.push_back(std::move(face));
    }
    FontCoverage c;
    c.impl_ = std::move(impl);
    return c;
}

std::vector<std::uint32_t> FontCoverage::missing(std::string_view utf8) const {
    std::vector<std::uint32_t> out;
    if (!impl_) return out;
    std::u32string cps;  // the composed vowels become the parts the shaper draws them with
    for (char32_t cp : render::decode_text(utf8)) {
        const auto parts = render::composed_parts(cp);
        if (parts.empty()) cps.push_back(cp);
        else cps.append(parts);
    }
    for (char32_t cp : cps) {
        if (!render::is_visible(cp) || std::find(out.begin(), out.end(), std::uint32_t(cp)) != out.end()) continue;
        const bool covered = std::any_of(impl_->fonts.begin(), impl_->fonts.end(), [&](const auto& f) { return f->has_glyph(cp); });
        if (!covered) out.push_back(std::uint32_t(cp));
    }
    return out;
}

Result<std::vector<std::uint32_t>> missing_glyphs(std::string_view utf8, const std::vector<std::string>& fontChain) {
    auto coverage = FontCoverage::load(fontChain);
    if (!coverage) return coverage.error();
    return coverage->missing(utf8);
}

}  // namespace fa
