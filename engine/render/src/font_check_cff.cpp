// Bounds check of the 'CFF ' table of an OpenType font with PostScript outlines (an .otf), before stb_truetype reads it
// (font_internal.h, check_cff_table; called from check_font_bytes in font_check.cpp).
//
// stbtt_InitFont gives its CFF reader a window of 512 MB from the start of the table (a @TODO of stb_truetype: "use size from
// table"), so every INDEX count, offset size, Top DICT offset and Private DICT reference of the file is followed as it stands
// and a damaged table reads outside the font file. This walks what stbtt_InitFont_internal reads, with the same steps in the
// same order, with the length of the table in hand: any read, seek or range past the end of the table, and any value on which
// stb_truetype asserts (an offset size outside 1..4, a reserved DICT operand, an INDEX entry that does not exist), is a damaged
// font. After that it checks what the glyph code follows later through the same window: the Private DICT and local subroutines
// of every font dict of a CID font, and the FDSelect that picks one for each glyph. A glyph whose FDSelect entry names no font
// dict, or that the CharStrings INDEX does not hold, is listed as unsafe (the engine draws .notdef in its place).
// What is not checked is the content of the charstrings: stb_truetype's charstring interpreter works on bounded copies of the
// INDEX entries (the buffers this walk proves lie inside the table), keeps its operand stack inside 48 entries and its
// subroutine nesting inside 10, so it reads only inside those entries whatever they say.
#include <algorithm>
#include <cstdint>
#include <format>
#include <string>
#include <utility>
#include <vector>

#include "font_internal.h"

namespace fa::render {

namespace {

constexpr std::int64_t kWindow = 512ll * 1024 * 1024;  // the size stb_truetype gives the table
constexpr std::uint64_t kMaxWork = 20'000'000;  // bytes read and glyphs visited; a real font needs a few thousand

// stbtt__buf: `size` and `cursor` count in bytes from `d`. `root` marks a buffer that stb_truetype gives a window past the
// table (the table itself, and the FDSelect, which it sizes to the end of the window): reading past `size` there would leave
// the table, so it is an error. In the small buffers stb_truetype cuts from it, a read past the end only returns 0.
struct Buf {
    const unsigned char* d = nullptr;
    std::int64_t size = 0, cursor = 0;
    bool root = false;
};

struct Walk {
    const unsigned char* base = nullptr;
    std::int64_t length = 0;
    std::string problem;
    std::string where;  // what is being read, for the message
    std::uint64_t work = 0;

    bool ok() const { return problem.empty(); }
    void fail(const std::string& what, std::int64_t offset) {
        if (problem.empty())
            problem =
                std::format("its 'CFF ' table is damaged: {} {} (at offset {} of the table, which holds {} bytes)",
                            where, what, offset, length);
    }
    std::int64_t offset_of(const Buf& b, std::int64_t at) const { return (b.d ? b.d - base : 0) + at; }

    bool count_work(std::uint64_t n = 1) {
        work += n;
        if (work > kMaxWork) {
            fail("needs more work to read than a font can ask for", 0);
            return false;
        }
        return true;
    }

    // stbtt__buf_get8, peek8, seek, skip, get
    unsigned get8(Buf& b) {
        if (!ok() || !count_work()) return 0;
        if (b.cursor >= b.size) {
            if (b.root) fail("is read past the end of the table", offset_of(b, b.cursor));
            return 0;
        }
        return b.d[b.cursor++];
    }
    unsigned peek8(const Buf& b) {
        if (!ok()) return 0;
        if (b.cursor >= b.size) {
            if (b.root) fail("is read past the end of the table", offset_of(b, b.cursor));
            return 0;
        }
        return b.d[b.cursor];
    }
    void seek(Buf& b, std::int64_t o) {
        if (!ok()) return;
        if (o > b.size || o < 0) {
            fail(std::format("points to offset {}, outside the {} bytes it can address", o, b.size),
                 offset_of(b, b.cursor));
            return;
        }
        b.cursor = o;
    }
    void skip(Buf& b, std::int64_t o) { seek(b, b.cursor + o); }
    std::uint32_t get(Buf& b, int n) {
        std::uint32_t v = 0;
        for (int i = 0; i < n && ok(); ++i) v = (v << 8) | get8(b);
        return v;
    }
    // stbtt__buf_range: stb_truetype returns an empty buffer for a range outside `b`; that is harmless inside a small buffer and
    // a read outside the table in a root one. `asRoot`: the range keeps the table's window (the FDSelect).
    Buf range(const Buf& b, std::int64_t o, std::int64_t s, bool asRoot = false) {
        Buf r;
        if (!ok()) return r;
        if (o < 0 || s < 0 || o > b.size || s > b.size - o) {
            if (b.root)
                fail(std::format("points to {} bytes at offset {}, outside the table", s, o), offset_of(b, b.cursor));
            return r;
        }
        r.d = b.d + o;
        r.size = s;
        r.root = asRoot;
        return r;
    }

    // stbtt__cff_get_index: walks past an INDEX (count, offset size, the offsets, the data the last offset ends) and returns it.
    Buf cff_get_index(Buf& b) {
        const std::int64_t start = b.cursor;
        const std::uint32_t count = get(b, 2);
        if (count) {
            const int offsize = int(get8(b));
            if (!ok()) return {};
            if (offsize < 1 || offsize > 4) {
                fail(std::format("has an offset size of {} (it must be 1 to 4)", offsize), offset_of(b, b.cursor - 1));
                return {};
            }
            skip(b, std::int64_t(offsize) * count);
            skip(b, std::int32_t(get(b, offsize) - 1u));
        }
        return range(b, start, b.cursor - start);
    }

    // stbtt__cff_index_get: entry `i` of an INDEX.
    Buf cff_index_get(Buf b, int i) {
        seek(b, 0);
        const int count = int(get(b, 2));
        const int offsize = int(get8(b));
        if (!ok()) return {};
        if (i < 0 || i >= count) {
            fail(std::format("has {} entries, and entry {} is needed", count, i), offset_of(b, 0));
            return {};
        }
        if (offsize < 1 || offsize > 4) {
            fail(std::format("has an offset size of {} (it must be 1 to 4)", offsize), offset_of(b, 2));
            return {};
        }
        skip(b, std::int64_t(i) * offsize);
        const std::int64_t start = std::int32_t(get(b, offsize)), end = std::int32_t(get(b, offsize));
        return range(b, 2 + std::int64_t(count + 1) * offsize + start, end - start);
    }

    // stbtt__cff_int: one DICT number. 30 (a real number) and the reserved bytes 31 and 255 are what stb_truetype asserts on.
    std::uint32_t cff_int(Buf& b) {
        const int b0 = int(get8(b));
        if (b0 >= 32 && b0 <= 246) return std::uint32_t(b0 - 139);
        if (b0 >= 247 && b0 <= 250) return std::uint32_t((b0 - 247) * 256 + int(get8(b)) + 108);
        if (b0 >= 251 && b0 <= 254) return std::uint32_t(-(b0 - 251) * 256 - int(get8(b)) - 108);
        if (b0 == 28) return get(b, 2);
        if (b0 == 29) return get(b, 4);
        fail(std::format("has the operand byte {}, which a font dict does not use here", b0),
             offset_of(b, b.cursor - 1));
        return 0;
    }
    void cff_skip_operand(Buf& b) {
        if (peek8(b) == 30) {
            skip(b, 1);
            while (ok() && b.cursor < b.size) {
                const unsigned v = get8(b);
                if ((v & 0xF) == 0xF || (v >> 4) == 0xF) break;
            }
        } else {
            cff_int(b);
        }
    }
    Buf dict_get(Buf& b, int key) {
        seek(b, 0);
        while (ok() && b.cursor < b.size) {
            const std::int64_t start = b.cursor;
            while (ok() && peek8(b) >= 28) cff_skip_operand(b);
            const std::int64_t end = b.cursor;
            int op = int(get8(b));
            if (op == 12) op = int(get8(b)) | 0x100;
            if (op == key) return range(b, start, end - start);
        }
        return range(b, 0, 0);
    }
    void dict_get_ints(Buf& b, int key, int outcount, std::uint32_t* out) {
        Buf operands = dict_get(b, key);
        for (int i = 0; i < outcount && ok() && operands.cursor < operands.size; ++i) out[i] = cff_int(operands);
    }

    // stbtt__get_subrs: the local subroutine INDEX of a font dict (the Top DICT of a font that is not a CID font), reached
    // through its Private DICT (a size and an offset in the table).
    Buf get_subrs(Buf cff, Buf fontdict) {
        std::uint32_t subrsoff = 0, loc[2] = {0, 0};
        dict_get_ints(fontdict, 18, 2, loc);
        if (!ok() || !loc[1] || !loc[0]) return {};
        where = "the Private DICT it names";
        Buf pdict = range(cff, std::int32_t(loc[1]), std::int32_t(loc[0]));
        dict_get_ints(pdict, 19, 1, &subrsoff);
        if (!ok() || !subrsoff) return {};
        where = "the local subroutine INDEX of its Private DICT";
        seek(cff, std::int32_t(loc[1] + subrsoff));
        return cff_get_index(cff);
    }
};

}  // namespace

CffCheck check_cff_table(const unsigned char* table, std::uint64_t length, std::uint64_t glyphs) {
    Walk w;
    w.base = table;
    w.length = std::int64_t(std::min<std::uint64_t>(length, std::uint64_t(kWindow)));
    Buf root{table, w.length, 0, true};
    CffCheck out;
    auto done = [&]() {
        out.problem = w.problem;
        return out;
    };

    // stbtt_InitFont_internal, step by step
    Buf b = root;
    w.where = "the header";
    w.skip(b, 2);
    const unsigned hdrsize = w.get8(b);
    if (w.ok() && hdrsize < 4) w.fail(std::format("says it is {} bytes long (at least 4)", hdrsize), 2);
    w.seek(b, std::int64_t(hdrsize));
    w.where = "the Name INDEX";
    w.cff_get_index(b);
    w.where = "the Top DICT INDEX";
    Buf topdictidx = w.cff_get_index(b);
    Buf topdict = w.cff_index_get(topdictidx, 0);
    w.where = "the String INDEX";
    w.cff_get_index(b);
    w.where = "the Global Subr INDEX";
    w.cff_get_index(b);
    if (!w.ok()) return done();

    std::uint32_t cstype = 2, charstrings = 0, fdarrayoff = 0, fdselectoff = 0;
    w.where = "the Top DICT";
    w.dict_get_ints(topdict, 17, 1, &charstrings);
    w.dict_get_ints(topdict, 0x100 | 6, 1, &cstype);
    w.dict_get_ints(topdict, 0x100 | 36, 1, &fdarrayoff);
    w.dict_get_ints(topdict, 0x100 | 37, 1, &fdselectoff);
    w.get_subrs(b, topdict);
    if (!w.ok()) return done();
    if (cstype != 2 || charstrings == 0) return done();  // stb_truetype refuses it with its own message

    Buf fontdicts, fdselect;
    if (fdarrayoff) {  // a CID font
        if (!fdselectoff) return done();
        w.where = "the FDArray INDEX";
        w.seek(b, std::int32_t(fdarrayoff));
        fontdicts = w.cff_get_index(b);
        w.where = "the FDSelect";
        fdselect = w.range(b, std::int32_t(fdselectoff), b.size - std::int32_t(fdselectoff), true);
    }
    w.where = "the CharStrings INDEX";
    w.seek(b, std::int32_t(charstrings));
    Buf charIndex = w.cff_get_index(b);
    if (!w.ok()) return done();

    // What the glyph code reaches later, through the window of the whole table.
    Buf countBuf = charIndex;
    const std::uint64_t glyphCount = (w.seek(countBuf, 0), w.get(countBuf, 2));
    if (glyphCount == 0) {
        w.where = "the CharStrings INDEX";
        w.fail("holds no glyphs", w.offset_of(charIndex, 0));
        return done();
    }
    out.unsafeGlyphs.assign(glyphs, 0);
    for (std::uint64_t g = glyphCount; g < glyphs; ++g) out.unsafeGlyphs[g] = 1;  // no charstring for it

    if (fdarrayoff) {
        Buf fdCount = fontdicts;
        const std::uint64_t dicts = (w.seek(fdCount, 0), w.get(fdCount, 2));
        for (std::uint64_t i = 0; i < dicts && w.ok(); ++i) {
            w.where = std::format("font dict {} of the FDArray", i);
            Buf cff = root;  // stbtt__cid_get_glyph_subrs hands stbtt__get_subrs the whole table
            w.get_subrs(cff, w.cff_index_get(fontdicts, int(i)));
        }
        if (!w.ok()) return done();
        w.where = "the FDSelect";
        // glyph -> font dict, as stbtt__cid_get_glyph_subrs reads it; a glyph with no font dict (or one the FDArray lacks)
        // would make stb_truetype assert, and is drawn as .notdef
        // stb_truetype sizes the FDSelect to the end of its window, so even one that starts at the end of the table is read
        // (its first byte lies past the table): no guard for an empty one, get8 refuses the read
        const std::int64_t room = fdselect.size;
        {
            Buf s = fdselect;
            const unsigned fmt = w.get8(s);
            if (fmt == 0) {
                // one font dict number per glyph, from byte 1
                for (std::uint64_t g = 0; g < glyphs && w.count_work(); ++g) {
                    const bool inside = std::int64_t(1 + g) < room;
                    if (!inside || fdselect.d[1 + g] >= dicts) out.unsafeGlyphs[g] = 1;
                }
            } else if (fmt == 3) {
                const std::uint32_t nranges = w.get(s, 2);
                std::uint32_t start = w.get(s, 2);
                std::vector<std::uint8_t> covered(glyphs, 0);
                for (std::uint32_t r = 0; r < nranges && w.ok(); ++r) {
                    const unsigned v = w.get8(s);
                    const std::uint32_t end = w.get(s, 2);
                    if (!w.ok()) break;
                    if (end < start) {
                        w.fail("has ranges of glyphs that do not rise (a range ends before it starts)",
                               w.offset_of(fdselect, s.cursor - 2));
                        break;
                    }
                    for (std::uint64_t g = start; g < std::min<std::uint64_t>(end, glyphs) && w.count_work(); ++g) {
                        covered[g] = 1;
                        if (v >= dicts) out.unsafeGlyphs[g] = 1;
                    }
                    start = end;
                }
                for (std::uint64_t g = 0; g < glyphs; ++g)
                    if (!covered[g]) out.unsafeGlyphs[g] = 1;
            } else {
                w.fail(std::format("has format {} (a CFF font has 0 or 3)", fmt), w.offset_of(fdselect, 0));
            }
        }
    }
    return done();
}

}  // namespace fa::render
