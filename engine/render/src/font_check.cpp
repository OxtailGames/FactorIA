// Bounds check of a TrueType / OpenType font file before stb_truetype reads it (font_internal.h, check_font_bytes).
//
// stb_truetype is handed a pointer and no length: every table offset, glyph offset and cmap index in the file is followed
// as it stands, so a truncated or hand-made font reads outside the buffer. This walks the same structures it walks, with
// the length in hand, and refuses a file that would make it leave the buffer. What is wrong with one glyph only (it would
// assert, read past its arrays, include itself) does not condemn the font: the glyph is reported as unsafe and the engine
// draws the .notdef box in its place.
// What it checks is what the engine's glyph code uses: the table directory, head, hhea, hmtx, maxp, loca, glyf and the
// cmap subtables of formats 0, 4, 6, 12 and 13. A 'CFF ' outline table (an .otf with PostScript outlines) is not walked: only its
// place in the file is checked, and stb_truetype's CFF reader (which bounds itself by 512 MB, not by the file) stays the open risk.
#include <algorithm>
#include <cstdint>
#include <cstring>
#include <set>
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
    std::uint32_t u16(std::uint64_t at) const {
        return at + 2 <= n ? std::uint32_t(d[at]) << 8 | d[at + 1] : (bad = true, 0u);
    }
    std::uint32_t u32(std::uint64_t at) const {
        return at + 4 <= n ? std::uint32_t(d[at]) << 24 | std::uint32_t(d[at + 1]) << 16 |
                                 std::uint32_t(d[at + 2]) << 8 | d[at + 3]
                           : (bad = true, 0u);
    }
};

struct Table {
    std::uint64_t at = 0, len = 0;
    bool present = false;
};

constexpr int kMaxComponentDepth = 32;              // nesting of composite glyphs (fonts use 2 or 3)
constexpr std::uint64_t kMaxComponentWork = 20000;  // glyphs drawn by one composite glyph, every nesting level counted

std::string check_cmap(const Be& f, const Table& cmap) {
    if (cmap.len < 4) return "its 'cmap' table is too short";
    const std::uint32_t records = f.u16(cmap.at + 2);
    if (4 + 8ull * records > cmap.len) return "its 'cmap' table lists more subtables than it holds";
    std::int64_t chosenFormat = -1;
    std::set<std::uint64_t> checked4;  // format 4 subtables already checked (many records may share one)
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
            const std::int64_t searchRange = f.u16(at + 8) >> 1;
            const std::uint32_t entrySelector = f.u16(at + 10);
            const std::uint64_t rangeShift = f.u16(at + 12) >> 1;
            if (seg == 0 || 16 + 8 * seg > room) return "a format 4 'cmap' subtable has more segments than it holds";
            if (checked4.insert(sub).second) {  // else another record pointed at this subtable and it was checked
                // stb_truetype binary-searches the end codes with these three header fields. Real fonts do not always write the values
                // the specification gives (Shree714.ttc has a rangeShift past its segments), so the search is simulated the way
                // stb_truetype runs it, taking every "go higher" branch (the furthest it can reach). `items` is how many entries of the
                // segment arrays any lookup can touch; each of them is checked like a segment, so a lookup that lands on one reads
                // inside the subtable whatever the header says (it may find a wrong glyph, never memory outside the font).
                std::int64_t s = std::int64_t(rangeShift) - 1, step = searchRange, reach = std::int64_t(rangeShift);
                for (std::uint32_t left = entrySelector; left; --left) {
                    step >>= 1;
                    reach = std::max(reach, s + step);
                    if (step == 0) break;  // every later round reads the same entry
                    s += step;
                }
                reach = std::max(reach, s + 1);
                const std::uint64_t items = std::max<std::uint64_t>(seg, std::uint64_t(reach) + 1);
                if (16 + 6 * seg + 2 * items > room)
                    return "a format 4 'cmap' subtable has search fields (searchRange, entrySelector, rangeShift) that "
                           "point past its end";
                for (std::uint64_t i = 0; i < items; ++i) {
                    const std::uint64_t end = f.u16(at + 14 + 2 * i), start = f.u16(at + 16 + 2 * seg + 2 * i);
                    const std::uint64_t rangeOffset = f.u16(at + 16 + 6 * seg + 2 * i);
                    if (rangeOffset == 0 || start > end) continue;
                    // the glyph index array is addressed from the idRangeOffset entry itself. A real segment keeps it inside its
                    // subtable; an entry past the segments is whatever bytes follow them (Shree714.ttc), which only has to lie in the file.
                    const std::uint64_t lastRead = 16 + 6 * seg + 2 * i + rangeOffset + 2 * (end - start) + 2;
                    if (i < seg ? lastRead > room : at + lastRead > f.n)
                        return "a format 4 'cmap' segment points past the end of its subtable";
                }
            }
        } else if (format == 6) {
            if (room < 10 || 10 + 2ull * f.u16(at + 8) > room) return "a format 6 'cmap' subtable is cut short";
        } else if (format == 12 || format == 13) {
            if (room < 16 || 16 + 12ull * f.u32(at + 12) > room)
                return "a format 12 or 13 'cmap' subtable is cut short";
        }
        // stb_truetype uses the LAST Unicode subtable (platform 0, or platform 3 with encoding 1 or 10) and asserts on a format it
        // does not read, so a font whose choice is one of those is refused instead of failing in every glyph lookup.
        const std::uint32_t platform = f.u16(cmap.at + 4 + 8ull * r), encoding = f.u16(cmap.at + 4 + 8ull * r + 2);
        if (platform == 0 || (platform == 3 && (encoding == 1 || encoding == 10))) chosenFormat = format;
    }
    if (chosenFormat >= 0 && chosenFormat != 0 && chosenFormat != 4 && chosenFormat != 6 && chosenFormat != 12 &&
        chosenFormat != 13)
        return "its Unicode 'cmap' table has format " + std::to_string(chosenFormat) +
               ", and the engine reads formats 0, 4, 6, 12 and 13";
    return f.bad ? "its 'cmap' table is cut short" : std::string();
}

// What walking glyph `g` found. `cost` is what drawing it draws: 1 for a simple glyph, the sum of its components for a composite
// one. `height` is how deep its components nest (0 for a simple glyph). `unsafe` marks a glyph stb_truetype must never be asked
// for: one it would assert on or read past its arrays for, or one that includes such a glyph. It is a fact about this glyph
// alone, so the font stays usable and the engine draws the .notdef box in its place (FontFace::stb_glyph).
struct Walked {
    std::uint64_t cost = 1;
    int height = 0;
    bool unsafe = false;
};

// Walks the outline of every glyph. `problem` is set for what makes the whole file unusable: a glyph that starts or ends
// outside the 'glyf' table (the 'loca' and 'glyf' tables do not agree with the file).
struct GlyphWalk {
    const Be& f;
    const Table& glyf;
    const std::vector<std::uint64_t>& start;  // loca offsets, one per glyph and one more
    std::vector<Walked> memo;
    std::vector<unsigned char> done, inProgress;
    std::string problem;

    Walked walk(std::uint32_t g, int depth) {
        if (!problem.empty()) return {};
        if (g >= start.size() - 1) return {};  // stb_truetype draws nothing for a glyph index it does not have
        if (done[g]) return memo[g];
        // A cycle, or a chain deeper than stb_truetype should be asked to follow (it has no limit of its own, and thousands of
        // levels overflow a 1 MB stack): not memoized, the glyphs above it are unsafe because of it.
        if (inProgress[g] || depth > kMaxComponentDepth) return Walked{1, kMaxComponentDepth + 1, true};
        inProgress[g] = 1;
        Walked out;
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
                    const std::uint64_t points =
                        contours ? std::uint64_t(f.u16(at + 10 + 2ull * std::uint64_t(contours) - 2)) + 1 : 0;
                    // stb_truetype sizes its vertex array from the last end point and, for a contour that starts off the curve, also
                    // reads the point after the first one: the end points must rise, and a last contour of one point must be on the
                    // curve (its flag is checked below, with the flags).
                    std::uint64_t lone = ~0ull;  // the index of that single point
                    for (std::int32_t c = 0; c < contours && !f.bad; ++c) {
                        const std::uint32_t end = f.u16(at + 10 + 2ull * std::uint64_t(c));
                        const std::uint32_t before = c ? f.u16(at + 10 + 2ull * std::uint64_t(c - 1)) : 0;
                        if (c && end <= before) out.unsafe = true;  // the contours do not end at rising points
                        if (c == contours - 1 && end == (c ? before + 1 : 0)) lone = end;
                    }
                    p += 2 + f.u16(p);
                    std::uint64_t xBytes = 0, yBytes = 0;
                    for (std::uint64_t i = 0; i < points && !f.bad;) {
                        const std::uint32_t flag = f.u8(p++);
                        std::uint64_t repeat = 1;
                        if (flag & 8) repeat += f.u8(p++);
                        repeat = std::min(repeat, points - i);
                        if (lone >= i && lone < i + repeat && !(flag & 1))
                            out.unsafe = true;  // a last contour of one point, off the curve
                        i += repeat;
                        xBytes += repeat * ((flag & 2) ? 1 : (flag & 16) ? 0 : 2);
                        yBytes += repeat * ((flag & 4) ? 1 : (flag & 32) ? 0 : 2);
                    }
                    if (p + xBytes + yBytes > glyf.at + glyf.len || f.bad)
                        problem = "a glyph's outline runs past the end of the 'glyf' table";
                } else {
                    // composite glyph: components until one has no "more" bit
                    std::uint64_t p = at + 10;
                    for (int guard = 0;; ++guard) {
                        const std::uint32_t flags = f.u16(p), part = f.u16(p + 2);
                        p += 4 + ((flags & 1) ? 4 : 2) +
                             ((flags & 8)      ? 2
                              : (flags & 0x40) ? 4
                              : (flags & 0x80) ? 8
                                               : 0);
                        if (f.bad || p > glyf.at + glyf.len) {
                            problem = "a composite glyph runs past the end of the 'glyf' table";
                            break;
                        }
                        // ARGS_ARE_XY_VALUES clear: the parts are placed by matching points, which stb_truetype asserts on
                        if (!(flags & 2)) out.unsafe = true;
                        const Walked w = walk(part, depth + 1);
                        out.cost += w.cost;
                        out.height = std::max(out.height, w.height + 1);
                        out.unsafe = out.unsafe || w.unsafe;
                        if (out.cost > kMaxComponentWork || guard >= 4096)
                            out.unsafe = true;  // it would draw too many glyphs
                        if (!(flags & 0x20) || out.unsafe) break;
                    }
                    if (out.height > kMaxComponentDepth) out.unsafe = true;
                }
            }
        }
        inProgress[g] = 0;
        if (out.unsafe) out.cost = std::min(out.cost, kMaxComponentWork + 1);
        memo[g] = out;
        done[g] = 1;
        return out;
    }
};

}  // namespace

FontCheck check_font_bytes(const unsigned char* data, std::size_t size, int offset) {
    auto refuse = [](std::string why) {
        FontCheck c;
        c.problem = std::move(why);
        return c;
    };
    const Be f{data, size};
    const std::uint64_t dir = std::uint64_t(offset);
    const std::uint32_t tables = f.u16(dir + 4);
    if (f.bad || dir + 12 + 16ull * tables > size) return refuse("its table directory is cut short");
    auto find = [&](const char* tag) {
        Table t;
        for (std::uint32_t i = 0; i < tables; ++i) {
            const std::uint64_t rec = dir + 12 + 16ull * i;
            if (std::memcmp(data + rec, tag, 4) != 0) continue;
            t.at = f.u32(rec + 8);
            t.len = f.u32(rec + 12);
            t.present = true;
            if (t.at + t.len > size)
                t.present = false, t.len = ~std::uint64_t(0);  // marks "listed, but outside the file"
            return t;
        }
        return t;
    };
    const Table cmap = find("cmap"), head = find("head"), hhea = find("hhea"), hmtx = find("hmtx"), maxp = find("maxp"),
                loca = find("loca"), glyf = find("glyf"), cff = find("CFF ");
    for (const Table* t : {&cmap, &head, &hhea, &hmtx, &maxp, &loca, &glyf, &cff})
        if (t->len == ~std::uint64_t(0))
            return refuse("a table of its directory lies outside the file (the file is truncated)");
    if (!cmap.present || !head.present || !hhea.present || !hmtx.present)
        return {};  // stb_truetype refuses it with its own message
    if (head.len < 54 || hhea.len < 36) return refuse("its 'head' or 'hhea' table is too short");
    if (std::string why = check_cmap(f, cmap); !why.empty()) return refuse(std::move(why));
    if (!glyf.present) return {};  // outlines in a 'CFF ' table (or none): stb_truetype's own checked reader

    if (!loca.present) return {};  // refused by stb_truetype
    const std::uint64_t glyphs = maxp.present && maxp.len >= 6 ? f.u16(maxp.at + 4) : 0xffffull;
    if (glyphs == 0) return refuse("its 'maxp' table says it has no glyphs");
    const std::uint64_t entry = f.u16(head.at + 50) == 0 ? 2 : 4;
    if (loca.len < (glyphs + 1) * entry)
        return refuse("its 'loca' table has fewer entries than the glyph count in 'maxp'");
    const std::uint64_t longMetrics = f.u16(hhea.at + 34);
    if (longMetrics == 0) return refuse("its 'hhea' table says there are no horizontal metrics");
    if (hmtx.len < (glyphs <= longMetrics ? 4 * glyphs : 4 * longMetrics + 2 * (glyphs - longMetrics)))
        return refuse("its 'hmtx' table has fewer metrics than the glyph count in 'maxp'");

    std::vector<std::uint64_t> start(glyphs + 1);
    for (std::uint64_t g = 0; g <= glyphs; ++g)
        start[g] = entry == 2 ? 2ull * f.u16(loca.at + 2 * g) : f.u32(loca.at + 4 * g);
    GlyphWalk w{f,
                glyf,
                start,
                std::vector<Walked>(glyphs),
                std::vector<unsigned char>(glyphs),
                std::vector<unsigned char>(glyphs),
                {}};
    for (std::uint32_t g = 0; g < glyphs && w.problem.empty(); ++g) w.walk(g, 0);
    if (!w.problem.empty()) return refuse(w.problem);
    if (f.bad) return refuse("a table is cut short");
    if (w.memo[0].unsafe)
        return refuse(
            "its glyph 0 (the .notdef box, drawn in place of every glyph that cannot be drawn) cannot be read");
    FontCheck c;
    for (std::uint32_t g = 0; g < glyphs; ++g) {
        if (!w.memo[g].unsafe) continue;
        c.unsafeGlyphs.resize(glyphs, 0);
        c.unsafeGlyphs[g] = 1;
    }
    return c;
}

}  // namespace fa::render
