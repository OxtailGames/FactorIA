// Text shaping and line layout: per-character font fallback, HarfBuzz shaping, the Unicode bidirectional algorithm
// (SheenBidi), line breaking and visual reordering. No GPU, no atlas: fonts.cpp draws what comes out.
#include "text_shaper.h"

#include <algorithm>
#include <cmath>

#include <SheenBidi/SheenBidi.h>

namespace fa::render {
namespace {

hb_unicode_funcs_t* ucd() { return hb_unicode_funcs_get_default(); }

// Drawn as nothing in every font; a font that lacks them is not "missing" them.
bool is_default_ignorable(char32_t c) {
    return c == 0xAD || c == 0x34F || (c >= 0x180B && c <= 0x180F) || (c >= 0x200B && c <= 0x200F) || (c >= 0x202A && c <= 0x202E) ||
           (c >= 0x2060 && c <= 0x206F) || (c >= 0xFE00 && c <= 0xFE0F) || c == 0xFEFF || (c >= 0xE0100 && c <= 0xE01EF);
}

// Draws with its base character: combining marks, joiners, variation selectors and the Hangul vowels and final consonants.
bool is_extender(char32_t c) {
    if (c == 0x200C || c == 0x200D || (c >= 0xFE00 && c <= 0xFE0F) || (c >= 0xE0100 && c <= 0xE01EF) || (c >= 0x1160 && c <= 0x11FF))
        return true;
    switch (hb_unicode_general_category(ucd(), c)) {
        case HB_UNICODE_GENERAL_CATEGORY_NON_SPACING_MARK:
        case HB_UNICODE_GENERAL_CATEGORY_ENCLOSING_MARK:
        case HB_UNICODE_GENERAL_CATEGORY_SPACING_MARK:
            return true;
        default:
            return false;
    }
}

// Hangul syllables and the compatibility jamo (written with spaces between words).
bool is_hangul(char32_t c) { return (c >= 0xAC00 && c <= 0xD7A3) || (c >= 0x3130 && c <= 0x318F); }

// Ideographs, kana and (with WordBreak::Normal) Hangul syllables: a line may end before or after each of them. Hangul is
// not one of them in Auto and KeepAll, and neither is anything else in KeepAll: those lines end at spaces only.
bool breaks_everywhere(char32_t c, WordBreak wb) {
    if (wb == WordBreak::KeepAll) return false;
    if (is_hangul(c)) return wb == WordBreak::Normal;
    return (c >= 0x2E80 && c <= 0x2FDF) || (c >= 0x3000 && c <= 0x4DBF) || (c >= 0x4E00 && c <= 0x9FFF) || (c >= 0xAC00 && c <= 0xD7A3) ||
           (c >= 0xF900 && c <= 0xFAFF) || (c >= 0xFF00 && c <= 0xFFEF) || (c >= 0x20000 && c <= 0x3FFFF);
}

// ponytail: simple kinsoku, not UAX #14. A line never starts with these (closing brackets, stops, the prolonged sound mark,
// small kana, the iteration mark) and never ends with an opening bracket. Upgrade to the full line-break classes when a
// language needs more (hyphens, numbers with units, Thai and Khmer dictionary breaks).
constexpr std::u32string_view kNoBreakBefore =
    U"、。，．：；！？）］｝〉》」』】〕〗〙〛｠,.:;!?)]}%’”»›ゝゞヽヾーぁぃぅぇぉっゃゅょゎゕゖァィゥェォッャュョヮヵヶ々〻‥…・〜～";
constexpr std::u32string_view kNoBreakAfter = U"（［｛〈《「『【〔〖〘〚｟([{‘“«‹";

// A space a line may end with: U+0020, U+200B ZERO WIDTH SPACE (how a translator marks the word boundaries of Thai, Khmer,
// Lao and Burmese) and the UAX #14 class BA spaces (Ogham, the en/em/thin spaces, the medium mathematical space). It hangs on
// the end of a line and is dropped when the line wraps. The no-break spaces (U+00A0, U+2007, U+202F) are not in the list.
bool is_break_space(char32_t c) {
    return c == U' ' || c == 0x200B || c == 0x1680 || (c >= 0x2000 && c <= 0x2006) || (c >= 0x2008 && c <= 0x200A) || c == 0x205F;
}

// A hyphen a line may end after: U+002D and U+2010, unless a number follows ("-5", "x -5") or another hyphen.
bool is_break_hyphen(char32_t c) { return c == U'-' || c == 0x2010; }

// A line may break between two clusters whose first code points are `a` and `b`.
bool can_break_between(char32_t a, char32_t b, WordBreak wb) {
    if (is_break_space(b)) return false;  // spaces hang on the end of the line
    if (is_break_space(a)) return true;
    if (is_break_hyphen(a) && !is_break_hyphen(b) && !(b >= U'0' && b <= U'9') && kNoBreakBefore.find(b) == std::u32string_view::npos) return true;
    if (!breaks_everywhere(a, wb) && !breaks_everywhere(b, wb)) return false;
    return kNoBreakBefore.find(b) == std::u32string_view::npos && kNoBreakAfter.find(a) == std::u32string_view::npos;
}

// Only text with right-to-left letters or direction controls needs the bidirectional algorithm; everything else is one
// left-to-right level.
bool needs_bidi(std::u32string_view p) {
    for (char32_t c : p)
        if ((c >= 0x0590 && c <= 0x08FF) || (c >= 0xFB1D && c <= 0xFDFF) || (c >= 0xFE70 && c <= 0xFEFF) || (c >= 0x10800 && c <= 0x10FFF) ||
            (c >= 0x1E800 && c <= 0x1EFFF) || (c >= 0x202A && c <= 0x202E) || (c >= 0x2066 && c <= 0x2069) || c == 0x200F || c == 0x061C)
            return true;
    return false;
}

// SheenBidi's view of one paragraph: embedding levels, and visual runs of a line. The base direction is the first strong
// character's (left to right when there is none).
struct Bidi {
    SBCodepointSequence seq{};
    SBAlgorithmRef algo = nullptr;
    SBParagraphRef para = nullptr;

    explicit Bidi(std::u32string_view p) {
        seq.stringEncoding = SBStringEncodingUTF32;
        seq.stringBuffer = p.data();
        seq.stringLength = p.size();
        algo = SBAlgorithmCreate(&seq);
        if (algo) para = SBAlgorithmCreateParagraph(algo, 0, p.size(), SBLevelDefaultLTR);
        if (para && SBParagraphGetLength(para) != p.size()) {  // cannot happen after decode_text; do not trust half a paragraph
            SBParagraphRelease(para);
            para = nullptr;
        }
    }
    ~Bidi() {
        if (para) SBParagraphRelease(para);
        if (algo) SBAlgorithmRelease(algo);
    }
    Bidi(const Bidi&) = delete;
    Bidi& operator=(const Bidi&) = delete;
    bool active() const { return para != nullptr; }
    const SBLevel* levels() const { return SBParagraphGetLevelsPtr(para); }
};

struct HbBuffer {
    hb_buffer_t* b = hb_buffer_create();
    ~HbBuffer() { hb_buffer_destroy(b); }
};

struct Glyph {
    FontFace* face;
    std::uint32_t gid;
    float adv, xOff, yOff;  // pixels
    int icon = -1;
    bool synth = false;
};

// A group of code points drawn by one or more glyphs that move together (a letter, a ligature, a base with its marks).
struct Cluster {
    std::uint32_t first = 0, end = 0;  // code points [first, end) of the paragraph
    std::uint32_t g0 = 0, g1 = 0;      // glyphs [g0, g1) of the pool
    float adv = 0;
    bool space = false;
};

struct Chain {
    std::size_t size;
    const std::function<FontFace*(std::size_t)>& get;
    std::vector<FontFace*> resolved;
    std::vector<char> tried;
    Chain(std::size_t n, const std::function<FontFace*(std::size_t)>& g) : size(n), get(g), resolved(n, nullptr), tried(n, 0) {}
    FontFace* at(std::size_t k) {
        if (!tried[k]) {
            tried[k] = 1;
            FontFace* f = get(k);
            resolved[k] = f && f->ok ? f : nullptr;
        }
        return resolved[k];
    }
};

void shape_run(hb_buffer_t* buf, std::u32string_view p, std::size_t a, std::size_t b, FontFace* f, hb_script_t script, bool rtl, int px,
               bool synth, float synthExtra, std::vector<Glyph>& pool, std::vector<Cluster>& clusters) {
    hb_buffer_clear_contents(buf);
    hb_buffer_add_utf32(buf, reinterpret_cast<const std::uint32_t*>(p.data()), int(p.size()), unsigned(a), int(b - a));
    hb_buffer_set_direction(buf, rtl ? HB_DIRECTION_RTL : HB_DIRECTION_LTR);
    hb_buffer_set_script(buf, script);
    hb_shape(f->hbFont, buf, nullptr, 0);
    unsigned n = 0;
    const hb_glyph_info_t* info = hb_buffer_get_glyph_infos(buf, &n);
    const hb_glyph_position_t* pos = hb_buffer_get_glyph_positions(buf, &n);
    const float scale = float(px) / float(f->unitsPerEm);
    const std::size_t first = clusters.size();
    for (unsigned i = 0; i < n; ++i) {
        if (i == 0 || info[i].cluster != info[i - 1].cluster) {
            Cluster c;
            c.first = info[i].cluster;
            c.g0 = c.g1 = std::uint32_t(pool.size());
            c.space = is_break_space(p[c.first]);
            clusters.push_back(c);
        }
        const float adv = float(pos[i].x_advance) * scale;
        pool.push_back({f, info[i].codepoint, adv > 0 && synth ? adv + synthExtra : adv, float(pos[i].x_offset) * scale,
                        float(pos[i].y_offset) * scale, -1, synth});
        clusters.back().g1 = std::uint32_t(pool.size());
        clusters.back().adv += pool.back().adv;
    }
    if (clusters.size() == first) return;
    if (rtl) std::reverse(clusters.begin() + std::ptrdiff_t(first), clusters.end());  // HarfBuzz hands right-to-left runs back in visual order
    clusters[first].first = std::uint32_t(a);                                          // the run's clusters cover [a, b) without gaps
    for (std::size_t k = first; k < clusters.size(); ++k) clusters[k].end = k + 1 < clusters.size() ? clusters[k + 1].first : std::uint32_t(b);
}

void shape_paragraph(std::u32string_view p, std::uint32_t base, int px, float maxW, WordBreak wordBreak, Chain& chain, HbBuffer& buf,
                     const RichShaping* rich, ShapedText& out) {
    const std::size_t n = p.size();
    if (n == 0) {
        out.lines.emplace_back();
        return;
    }
    FontFace* const primary = chain.at(0);
    const auto attr_of = [&](std::size_t i) -> MarkupAttr {
        return rich && rich->attrs && base + i < rich->attrs->size() ? (*rich->attrs)[base + i] : MarkupAttr{};
    };
    const auto is_icon = [&](std::size_t i) { return attr_of(i).icon >= 0; };

    // ---- which font draws each character ----
    std::vector<FontFace*> faceOf(n, primary);
    std::vector<char> synth(n, 0);  // bold, and no bold face has the character: the engine emboldens it
    for (std::size_t i = 0; i < n; ++i) {
        const char32_t c = p[i];
        FontFace* f = nullptr;
        if (is_icon(i)) continue;  // a picture: no font
        const bool ext = i > 0 && is_extender(c);
        if (ext) {  // stays with its base character's font, as long as that font can draw it
            f = faceOf[i - 1];
            if (!is_default_ignorable(c) && !f->has_glyph(c)) f = nullptr;
        }
        for (std::size_t k = 0; !f && k < chain.size; ++k) {
            FontFace* cand = chain.at(k);
            if (cand && cand->has_glyph(c)) f = cand;
        }
        if (!f) {
            f = ext ? faceOf[i - 1] : primary;  // nobody has it: .notdef of the base's font, drawn as nothing
            if (is_visible(c) && out.missing.size() < 8 && std::find(out.missing.begin(), out.missing.end(), c) == out.missing.end())
                out.missing.push_back(c);
        }
        faceOf[i] = f;
        if (rich && attr_of(i).bold) {
            FontFace* bf = rich->boldFace ? rich->boldFace(f) : nullptr;
            if (bf && (bf->has_glyph(c) || is_default_ignorable(c))) faceOf[i] = bf;
            else synth[i] = 1;
        }
        for (char32_t part : composed_parts(c))  // the shaper decomposes SARA AM whatever the font has
            if (!f->has_glyph(part) && out.missing.size() < 8 && std::find(out.missing.begin(), out.missing.end(), part) == out.missing.end())
                out.missing.push_back(part);
    }

    // ---- scripts (Common and Inherited take the script of what comes before) and bidirectional levels ----
    std::vector<hb_script_t> script(n);
    hb_script_t last = HB_SCRIPT_INVALID;
    for (std::size_t i = 0; i < n; ++i) {
        hb_script_t s = hb_unicode_script(ucd(), p[i]);
        if (s == HB_SCRIPT_COMMON || s == HB_SCRIPT_INHERITED || s == HB_SCRIPT_UNKNOWN) s = last;
        else last = s;
        script[i] = s;
    }
    hb_script_t firstScript = HB_SCRIPT_COMMON;
    for (std::size_t i = 0; i < n; ++i)
        if (script[i] != HB_SCRIPT_INVALID) { firstScript = script[i]; break; }
    for (std::size_t i = 0; i < n && script[i] == HB_SCRIPT_INVALID; ++i) script[i] = firstScript;

    std::unique_ptr<Bidi> bidi;
    if (needs_bidi(p)) {
        bidi = std::make_unique<Bidi>(p);
        if (!bidi->active()) bidi.reset();
    }
    const SBLevel* level = bidi ? bidi->levels() : nullptr;
    auto level_of = [&](std::size_t i) { return level ? level[i] : SBLevel(0); };

    // ---- shape runs of one font, script and level ----
    std::vector<Glyph> pool;
    std::vector<Cluster> clusters;
    for (std::size_t i = 0; i < n;) {
        std::size_t j = i + 1;
        if (is_icon(i)) {  // a picture is its own cluster, as wide as the rich text says
            Cluster c;
            c.first = std::uint32_t(i);
            c.end = std::uint32_t(i + 1);
            c.g0 = std::uint32_t(pool.size());
            const int icon = attr_of(i).icon;
            const float adv = std::size_t(icon) < rich->iconAdvance.size() ? rich->iconAdvance[std::size_t(icon)] : float(px);
            pool.push_back({nullptr, 0, adv, 0, 0, icon, false});
            c.g1 = std::uint32_t(pool.size());
            c.adv = adv;
            clusters.push_back(c);
            ++i;
            continue;
        }
        while (j < n && !is_icon(j) && faceOf[j] == faceOf[i] && synth[j] == synth[i] && script[j] == script[i] && level_of(j) == level_of(i))
            ++j;
        shape_run(buf.b, p, i, j, faceOf[i], script[i], (level_of(i) & 1) != 0, px, synth[i] != 0, rich ? rich->syntheticExtra : 0.0f, pool,
                  clusters);
        i = j;
    }
    std::vector<std::uint32_t> clusterOf(n + 1, 0);  // code point -> index of its cluster
    for (std::size_t k = 0; k < clusters.size(); ++k)
        for (std::uint32_t c = clusters[k].first; c < clusters[k].end && c < n; ++c) clusterOf[c] = std::uint32_t(k);

    // ---- line breaking on the logical order: after spaces, and around ideographs, kana and Hangul ----
    struct Span { std::size_t c0 = 0, c1 = 0; float width = 0; };
    std::vector<Span> spans;
    Span cur;
    bool curEmpty = true;
    auto close_line = [&](bool trim) {
        if (trim)
            while (cur.c1 > cur.c0 && clusters[cur.c1 - 1].space) cur.width -= clusters[--cur.c1].adv;
        spans.push_back(cur);
        cur = Span{};
        curEmpty = true;
    };
    auto can_break_before = [&](std::size_t k) { return can_break_between(p[clusters[k - 1].first], p[clusters[k].first], wordBreak); };
    for (std::size_t k = 0; k < clusters.size();) {
        std::size_t j = k + 1;
        while (j < clusters.size() && !can_break_before(j)) ++j;
        float wordW = 0, trailW = 0;  // a unit is a word and the spaces after it
        for (std::size_t c = k; c < j; ++c) (clusters[c].space ? trailW : wordW) += clusters[c].adv;
        if (maxW > 0 && curEmpty && wordW == 0) { k = j; continue; }  // no leading spaces on a wrapped line
        if (maxW > 0 && !curEmpty && cur.width + wordW > maxW) close_line(true);
        if (curEmpty) { cur.c0 = k; curEmpty = false; }
        cur.c1 = j;
        cur.width += wordW + trailW;
        k = j;
    }
    if (!curEmpty || spans.empty()) close_line(false);

    // ---- one line at a time: visual order, then glyph positions ----
    for (const Span& s : spans) {
        ShapedLine line;
        if (s.c1 > s.c0) {
            const std::size_t lo = clusters[s.c0].first, hi = clusters[s.c1 - 1].end;
            line.text = std::u32string(p.substr(lo, hi - lo));
            std::vector<std::size_t> order;  // cluster indices, left to right
            SBLineRef sbLine = bidi ? SBParagraphCreateLine(bidi->para, lo, hi - lo) : nullptr;
            if (sbLine) {
                const SBRun* runs = SBLineGetRunsPtr(sbLine);
                for (SBUInteger r = 0; r < SBLineGetRunCount(sbLine); ++r) {
                    const std::size_t from = order.size();
                    for (std::size_t c = clusterOf[runs[r].offset]; c < s.c1 && clusters[c].first < runs[r].offset + runs[r].length; ++c)
                        if (clusters[c].first >= runs[r].offset) order.push_back(c);
                    if (runs[r].level & 1) std::reverse(order.begin() + std::ptrdiff_t(from), order.end());
                }
                SBLineRelease(sbLine);
            } else {
                for (std::size_t c = s.c0; c < s.c1; ++c) order.push_back(c);
            }
            float pen = 0;
            for (std::size_t c : order)
                for (std::uint32_t g = clusters[c].g0; g < clusters[c].g1; ++g) {
                    const Glyph& gl = pool[g];
                    line.glyphs.push_back({gl.face, gl.gid, base + clusters[c].first, pen + gl.xOff, gl.yOff, gl.adv, gl.icon, gl.synth});
                    pen += gl.adv;
                }
            line.width = pen;
        }
        out.lines.push_back(std::move(line));
    }
}

}  // namespace

std::vector<std::uint32_t> grapheme_index(std::u32string_view text) {
    std::vector<std::uint32_t> out(text.size(), 0);
    std::uint32_t g = 0;
    bool oddRegional = false;  // the previous code point was the first of a pair of regional indicators (a flag)
    for (std::size_t i = 0; i < text.size(); ++i) {
        const char32_t c = text[i];
        const bool regional = c >= 0x1F1E6 && c <= 0x1F1FF;
        bool joins = false;
        if (i > 0) {
            const char32_t prev = text[i - 1];
            joins = is_extender(c) || (c >= 0x1F3FB && c <= 0x1F3FF) || prev == 0x200D || (prev == U'\r' && c == U'\n') ||
                    (regional && oddRegional);
        }
        if (!joins) ++g;
        oddRegional = regional && !(joins && oddRegional);
        out[i] = g - 1;
    }
    return out;
}

ShapedText shape_text(std::string_view utf8, int px, float maxWidth, std::size_t chainSize,
                      const std::function<FontFace*(std::size_t)>& chainFn, WordBreak wordBreak) {
    return shape_text(decode_text(utf8), px, maxWidth, chainSize, chainFn, nullptr, wordBreak);
}

ShapedText shape_text(std::u32string_view text, int px, float maxWidth, std::size_t chainSize,
                      const std::function<FontFace*(std::size_t)>& chainFn, const RichShaping* rich, WordBreak wordBreak) {
    ShapedText out;
    Chain chain(std::max<std::size_t>(chainSize, 1), chainFn);
    if (!chain.at(0)) {
        out.lines.emplace_back();
        return out;
    }
    HbBuffer buf;
    for (std::size_t start = 0;;) {
        const std::size_t nl = text.find(U'\n', start);
        const std::size_t end = nl == std::u32string::npos ? text.size() : nl;
        shape_paragraph(text.substr(start, end - start), std::uint32_t(start), px, maxWidth, wordBreak, chain, buf, rich, out);
        if (nl == std::u32string::npos) break;
        start = nl + 1;
    }
    return out;
}

}  // namespace fa::render
