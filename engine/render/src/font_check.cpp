// Bounds check of a TrueType / OpenType font file before stb_truetype reads it (font_internal.h, check_font_bytes).
//
// stb_truetype is handed a pointer and no length: every table offset, glyph offset and cmap index in the file is followed
// as it stands, so a truncated or hand-made font reads outside the buffer. This walks the same structures it walks, with
// the length in hand, and refuses a file that would make it leave the buffer or run away (a glyph that includes itself).
// What it checks is what the engine's glyph code uses: the table directory, head, hhea, hmtx, maxp, loca, glyf and the
// cmap subtables of formats 0, 4, 6, 12 and 13. A 'CFF ' outline table (an .otf with PostScript outlines) is not walked: only its
// place in the file is checked, and stb_truetype's CFF reader (which bounds itself by 512 MB, not by the file) stays the open risk.
#include <algorithm>
#include <cstdint>
#include <cstring>
#include <string>
#include <vector>

#include "font_internal.h"

namespace fa::render {

namespace {

// Big-endian reads that cannot leave the buffer: an offset out of range reads 0 and marks the font as damaged.
struct Be {
    const unsigned char* d;
    std::uint64_t n;
    mutable bool bad = false;
    std::uint32_t u8(std::uint64_t at) const { return at < n ? d[at] : (bad = true, 0u); }
    std::uint32_t u16(std::uint64_t at) const { return at + 2 <= n ? std::uint32_t(d[at]) << 8 | d[at + 1] : (bad = true, 0u); }
    std::uint32_t u32(std::uint64_t at) const {
        return at + 4 <= n ? std::uint32_t(d[at]) << 24 | std::uint32_t(d[at + 1]) << 16 | std::uint32_t(d[at + 2]) << 8 | d[at + 3] : (bad = true, 0u);
    }
};

struct Table {
    std::uint64_t at = 0, len = 0;
    bool present = false;
};

constexpr int kMaxComponentDepth = 32;           // nesting of composite glyphs (fonts use 2 or 3)
constexpr std::uint64_t kMaxComponentWork = 20000;  // glyphs drawn by one composite glyph, every nesting level counted

std::string check_cmap(const Be& f, const Table& cmap) {
    if (cmap.len < 4) return "its 'cmap' table is too short";
    const std::uint32_t records = f.u16(cmap.at + 2);
    if (4 + 8ull * records > cmap.len) return "its 'cmap' table lists more subtables than it holds";
    std::int64_t chosenFormat = -1;
    for (std::uint32_t r = 0; r < records; ++r) {
        const std::uint64_t sub = f.u32(cmap.at + 4 + 8ull * r + 4);
        if (sub + 4 > cmap.len) return "a 'cmap' subtable starts outside the table";
        const std::uint64_t at = cmap.at + sub, room = cmap.len - sub;  // bytes from the subtable to the end of 'cmap'
        const std::uint32_t format = f.u16(at);
        if (format == 0) {
            if (room < 262) return "a format 0 'cmap' subtable is cut short";
        } else if (format == 4) {
            if (room < 16) return "a format 4 'cmap' subtable is cut short";
            const std::uint64_t seg = f.u16(at + 6) >> 1;
            const std::uint64_t searchRange = f.u16(at + 8) >> 1, entrySelector = f.u16(at + 10), rangeShift = f.u16(at + 12) >> 1;
            if (seg == 0 || 16 + 8 * seg > room) return "a format 4 'cmap' subtable has more segments than it holds";
            // stb_truetype binary-searches with these three header fields: they must be what a font tool writes for `seg` segments,
            // else the search reads outside the segment arrays.
            std::uint64_t power = 1, selector = 0;
            while (power * 2 <= seg) power *= 2, ++selector;
            if (searchRange != power || entrySelector != selector || rangeShift != seg - power)
                return "a format 4 'cmap' subtable has search fields (searchRange, entrySelector, rangeShift) that do not match its segment count";
            for (std::uint64_t i = 0; i < seg; ++i) {
                const std::uint64_t end = f.u16(at + 14 + 2 * i), start = f.u16(at + 16 + 2 * seg + 2 * i);
                const std::uint64_t rangeOffset = f.u16(at + 16 + 6 * seg + 2 * i);
                if (rangeOffset == 0 || start > end) continue;
                // the glyph index array is addressed from the idRangeOffset entry itself
                if (16 + 6 * seg + 2 * i + rangeOffset + 2 * (end - start) + 2 > room)
                    return "a format 4 'cmap' segment points past the end of its subtable";
            }
        } else if (format == 6) {
            if (room < 10 || 10 + 2ull * f.u16(at + 8) > room) return "a format 6 'cmap' subtable is cut short";
        } else if (format == 12 || format == 13) {
            if (room < 16 || 16 + 12ull * f.u32(at + 12) > room) return "a format 12 or 13 'cmap' subtable is cut short";
        }
        // stb_truetype uses the LAST Unicode subtable (platform 0, or platform 3 with encoding 1 or 10) and asserts on a format it
        // does not read, so a font whose choice is one of those is refused instead of failing in every glyph lookup.
        const std::uint32_t platform = f.u16(cmap.at + 4 + 8ull * r), encoding = f.u16(cmap.at + 4 + 8ull * r + 2);
        if (platform == 0 || (platform == 3 && (encoding == 1 || encoding == 10))) chosenFormat = format;
    }
    if (chosenFormat >= 0 && chosenFormat != 0 && chosenFormat != 4 && chosenFormat != 6 && chosenFormat != 12 && chosenFormat != 13)
        return "its Unicode 'cmap' subtable has format " + std::to_string(chosenFormat) + ", and the engine reads formats 0, 4, 6, 12 and 13";
    return f.bad ? "its 'cmap' table is cut short" : std::string();
}

// What walking the outline of glyph `g` draws: 1 for a simple glyph, the sum of its components for a composite one. 0 and
// `problem` set when the glyph reads outside the 'glyf' table, includes a glyph too deep or draws too much.
struct GlyphWalk {
    const Be& f;
    const Table& glyf;
    const std::vector<std::uint64_t>& start;  // loca offsets, one per glyph and one more
    std::vector<std::uint64_t> work;          // memo: work + 1 once known, 0 not yet
    std::vector<unsigned char> inProgress;
    std::string problem;

    std::uint64_t walk(std::uint32_t g, int depth) {
        if (!problem.empty()) return 0;
        if (g >= start.size() - 1) return 1;  // stb_truetype draws nothing for a glyph index it does not have
        if (work[g]) return work[g] - 1;
        if (inProgress[g] || depth > kMaxComponentDepth) {
            problem = "a composite glyph includes itself or is nested more than " + std::to_string(kMaxComponentDepth) + " levels deep";
            return 0;
        }
        inProgress[g] = 1;
        std::uint64_t cost = 1;
        const std::uint64_t s = start[g];
        if (start[g + 1] != s) {
            if (s + 10 > glyf.len) {
                problem = "a glyph starts outside the 'glyf' table";
            } else {
                const std::uint64_t at = glyf.at + s;
                const std::int32_t contours = std::int16_t(f.u16(at));
                if (contours >= 0) {
                    // simple glyph: end points, instructions, then one flag per point (with repeats) and its x and y offsets
                    std::uint64_t p = at + 10 + 2ull * std::uint64_t(contours);
                    const std::uint64_t points = contours ? std::uint64_t(f.u16(at + 10 + 2ull * std::uint64_t(contours) - 2)) + 1 : 0;
                    // stb_truetype sizes its vertex array from the last end point and, for a contour that starts off the curve, also
                    // reads the point after the first one: the end points must rise, and a last contour of one point must be on the
                    // curve (its flag is checked below, with the flags).
                    std::uint64_t lone = ~0ull;  // the index of that single point
                    for (std::int32_t c = 0; c < contours && !f.bad; ++c) {
                        const std::uint32_t end = f.u16(at + 10 + 2ull * std::uint64_t(c));
                        const std::uint32_t before = c ? f.u16(at + 10 + 2ull * std::uint64_t(c - 1)) : 0;
                        if (c && end <= before) problem = "a glyph's contours do not end at rising points";
                        if (c == contours - 1 && end == (c ? before + 1 : 0)) lone = end;
                    }
                    if (!problem.empty()) {
                        work[g] = 0;
                        inProgress[g] = 0;
                        return 0;
                    }
                    p += 2 + f.u16(p);
                    std::uint64_t xBytes = 0, yBytes = 0;
                    for (std::uint64_t i = 0; i < points && !f.bad;) {
                        const std::uint32_t flag = f.u8(p++);
                        std::uint64_t repeat = 1;
                        if (flag & 8) repeat += f.u8(p++);
                        repeat = std::min(repeat, points - i);
                        if (lone >= i && lone < i + repeat && !(flag & 1)) problem = "a glyph's last contour is a single point off the curve";
                        i += repeat;
                        xBytes += repeat * ((flag & 2) ? 1 : (flag & 16) ? 0 : 2);
                        yBytes += repeat * ((flag & 4) ? 1 : (flag & 32) ? 0 : 2);
                    }
                    if (p + xBytes + yBytes > glyf.at + glyf.len || f.bad) problem = "a glyph's outline runs past the end of the 'glyf' table";
                } else {
                    // composite glyph: components until one has no "more" bit
                    std::uint64_t p = at + 10;
                    for (int guard = 0; guard < 4096 && problem.empty(); ++guard) {
                        const std::uint32_t flags = f.u16(p), part = f.u16(p + 2);
                        if (!(flags & 2)) {  // ARGS_ARE_XY_VALUES clear: the parts are placed by matching points, which stb_truetype asserts on
                            problem = "a composite glyph places its parts by matching points, which the engine does not read";
                            break;
                        }
                        p += 4 + ((flags & 1) ? 4 : 2) + ((flags & 8) ? 2 : (flags & 0x40) ? 4 : (flags & 0x80) ? 8 : 0);
                        if (f.bad || p > glyf.at + glyf.len) {
                            problem = "a composite glyph runs past the end of the 'glyf' table";
                            break;
                        }
                        cost += walk(part, depth + 1);
                        if (cost > kMaxComponentWork) {
                            problem = "a composite glyph draws more than " + std::to_string(kMaxComponentWork) + " glyphs";
                            break;
                        }
                        if (!(flags & 0x20)) break;
                    }
                }
            }
        }
        inProgress[g] = 0;
        work[g] = cost + 1;
        return cost;
    }
};

}  // namespace

std::string check_font_bytes(const unsigned char* data, std::size_t size, int offset) {
    const Be f{data, size};
    const std::uint64_t dir = std::uint64_t(offset);
    const std::uint32_t tables = f.u16(dir + 4);
    if (f.bad || dir + 12 + 16ull * tables > size) return "its table directory is cut short";
    auto find = [&](const char* tag) {
        Table t;
        for (std::uint32_t i = 0; i < tables; ++i) {
            const std::uint64_t rec = dir + 12 + 16ull * i;
            if (std::memcmp(data + rec, tag, 4) != 0) continue;
            t.at = f.u32(rec + 8);
            t.len = f.u32(rec + 12);
            t.present = true;
            if (t.at + t.len > size) t.present = false, t.len = ~std::uint64_t(0);  // marks "listed, but outside the file"
            return t;
        }
        return t;
    };
    const Table cmap = find("cmap"), head = find("head"), hhea = find("hhea"), hmtx = find("hmtx"), maxp = find("maxp"),
                loca = find("loca"), glyf = find("glyf"), cff = find("CFF ");
    for (const Table* t : {&cmap, &head, &hhea, &hmtx, &maxp, &loca, &glyf, &cff})
        if (t->len == ~std::uint64_t(0)) return "a table of its directory lies outside the file (the file is truncated)";
    if (!cmap.present || !head.present || !hhea.present || !hmtx.present) return {};  // stb_truetype refuses it with its own message
    if (head.len < 54 || hhea.len < 36) return "its 'head' or 'hhea' table is too short";
    if (std::string why = check_cmap(f, cmap); !why.empty()) return why;
    if (!glyf.present) return {};  // outlines in a 'CFF ' table (or none): stb_truetype's own checked reader

    if (!loca.present) return {};  // refused by stb_truetype
    const std::uint64_t glyphs = maxp.present && maxp.len >= 6 ? f.u16(maxp.at + 4) : 0xffffull;
    if (glyphs == 0) return "its 'maxp' table says it has no glyphs";
    const std::uint64_t entry = f.u16(head.at + 50) == 0 ? 2 : 4;
    if (loca.len < (glyphs + 1) * entry) return "its 'loca' table has fewer entries than the glyph count in 'maxp'";
    const std::uint64_t longMetrics = f.u16(hhea.at + 34);
    if (longMetrics == 0) return "its 'hhea' table says there are no horizontal metrics";
    if (hmtx.len < (glyphs <= longMetrics ? 4 * glyphs : 4 * longMetrics + 2 * (glyphs - longMetrics)))
        return "its 'hmtx' table has fewer metrics than the glyph count in 'maxp'";

    std::vector<std::uint64_t> start(glyphs + 1);
    for (std::uint64_t g = 0; g <= glyphs; ++g)
        start[g] = entry == 2 ? 2ull * f.u16(loca.at + 2 * g) : f.u32(loca.at + 4 * g);
    GlyphWalk w{f, glyf, start, std::vector<std::uint64_t>(glyphs), std::vector<unsigned char>(glyphs), {}};
    for (std::uint32_t g = 0; g < glyphs && w.problem.empty(); ++g) w.walk(g, 0);
    if (!w.problem.empty()) return w.problem;
    return f.bad ? "a table is cut short" : std::string();
}

}  // namespace fa::render
