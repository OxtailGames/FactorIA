// An .otf with PostScript outlines: the 'CFF ' table is checked (font_check_cff.cpp) before stb_truetype reads it.
// stb_truetype reads a CFF table in a window of 512 MB from its start, so a damaged INDEX or offset read outside the file (the
// weekly fuzz run found one: tools/fuzz/corpus/font/cff_index_out_of_bounds.otf, replayed by the ctest `fuzz_font`). These tests
// build a small CFF font from scratch and damage it. A damaged table is an error that says where, never a read outside the
// buffer (the sanitizer builds and the fuzz target `font` look for that).
#include <doctest.h>

#include <algorithm>
#include <cstdint>
#include <initializer_list>
#include <string>
#include <utility>
#include <vector>

#include "fa/render/fonts.h"
#include "font_internal.h"

using namespace fa;

namespace {

using Bytes = std::vector<std::uint8_t>;

void set16(Bytes& b, std::size_t at, std::uint32_t v) {
    b[at] = std::uint8_t(v >> 8);
    b[at + 1] = std::uint8_t(v);
}
void set32(Bytes& b, std::size_t at, std::uint32_t v) {
    set16(b, at, v >> 16);
    set16(b, at + 2, v & 0xFFFF);
}
std::uint32_t be16(const Bytes& b, std::size_t at) { return std::uint32_t(b[at]) << 8 | b[at + 1]; }
std::uint32_t be32(const Bytes& b, std::size_t at) { return be16(b, at) << 16 | be16(b, at + 2); }

std::size_t table_at(const Bytes& b, const char* tag) {
    for (std::uint32_t i = 0, n = be16(b, 4); i < n; ++i) {
        const std::size_t rec = 12 + 16 * std::size_t(i);
        if (std::equal(tag, tag + 4, b.begin() + std::ptrdiff_t(rec))) return be32(b, rec + 8);
    }
    return 0;
}

// What rasterize_text says about `font`: "" when it draws, else the error's message.
std::string says(const Bytes& font, const char* text = "A") {
    auto bitmap = rasterize_text(text, font, 20.0f);
    if (bitmap.ok()) return {};
    CHECK_FALSE(bitmap.error().hint.empty());
    return bitmap.error().message;
}

bool has(const std::string& s, const char* part) { return s.find(part) != std::string::npos; }

struct CffFont {
    Bytes cff;  // the table
    // where things are in the table
    std::size_t nameIndex = 0, topDict = 0, topCharStrings = 0, topFdArray = 0, topFdSelect = 0, fdArray = 0,
                fontDict = 0, privateDict = 0, fdSelect = 0, charStrings = 0;
};

// A CFF table with two glyphs (.notdef and one that moves to 0,0). `cid`: a CID font (FDArray with one font dict that has a
// Private DICT and a local subroutine INDEX, and an FDSelect of format 3 that gives both glyphs to that font dict).
CffFont make_cff(bool cid) {
    CffFont c;
    Bytes& t = c.cff;
    auto put = [&](std::initializer_list<int> bytes) {
        for (int v : bytes) t.push_back(std::uint8_t(v));
    };
    auto i32 = [&]() { put({0x1d, 0, 0, 0, 0}); };  // an integer operand, patched later
    put({1, 0, 4, 1});                              // header: major, minor, hdrSize, offSize
    c.nameIndex = t.size();
    put({0, 1, 1, 1, 5, 'T', 'e', 's', 't'});
    put({0, 1, 1, 1, cid ? 21 : 7});  // Top DICT INDEX with one entry
    c.topDict = t.size();
    i32();
    c.topCharStrings = t.size() - 4;
    put({0x11});  // CharStrings
    if (cid) {
        i32();
        c.topFdArray = t.size() - 4;
        put({0x0c, 0x24});  // FDArray
        i32();
        c.topFdSelect = t.size() - 4;
        put({0x0c, 0x25});  // FDSelect
    }
    put({0, 0, 0, 0});  // String INDEX, Global Subr INDEX
    if (cid) {
        c.fdArray = t.size();
        put({0, 1, 1, 1, 12});
        c.fontDict = t.size();
        i32();  // Private: size, offset
        i32();
        put({0x12});
        c.privateDict = t.size();
        i32();  // Subrs: offset from the Private DICT
        put({0x13});
        put({0, 0});  // the local subroutine INDEX, empty
        c.fdSelect = t.size();
        put({3, 0, 1, 0, 0, 0, 0, 2});  // format 3, one range from glyph 0 to glyph 2 for font dict 0
        set32(t, c.fontDict + 1, 6);
        set32(t, c.fontDict + 6, std::uint32_t(c.privateDict));
        set32(t, c.privateDict + 1, 6);
        set32(t, c.topFdArray, std::uint32_t(c.fdArray));
        set32(t, c.topFdSelect, std::uint32_t(c.fdSelect));
    }
    c.charStrings = t.size();
    put({0, 2, 1, 1, 2, 6, 0x0e, 0x8b, 0x8b, 0x15, 0x0e});  // .notdef: endchar; glyph 1: 0 0 rmoveto endchar
    set32(t, c.topCharStrings, std::uint32_t(c.charStrings));
    return c;
}

// An OpenType font ('OTTO') around a CFF table; its 'cmap' maps 'A' to glyph 1.
Bytes make_otf(const Bytes& cff, std::uint32_t numGlyphs = 2) {
    Bytes cmap(24, 0), head(54, 0), hhea(36, 0), hmtx(8, 0), maxp(6, 0);
    set16(cmap, 2, 1);
    set16(cmap, 4, 3);
    set16(cmap, 6, 1);
    set32(cmap, 8, 12);
    set16(cmap, 12, 6);
    set16(cmap, 14, 12);
    set16(cmap, 18, 65);
    set16(cmap, 20, 1);
    set16(cmap, 22, 1);
    set16(head, 18, 1000);
    set16(hhea, 4, 800);
    set16(hhea, 34, 2);
    set16(hmtx, 0, 500);
    set16(hmtx, 4, 500);
    set32(maxp, 0, 0x00005000);
    set16(maxp, 4, numGlyphs);
    const std::vector<std::pair<const char*, const Bytes*>> tables = {
        {"CFF ", &cff}, {"cmap", &cmap}, {"head", &head}, {"hhea", &hhea}, {"hmtx", &hmtx}, {"maxp", &maxp}};
    Bytes out(12 + 16 * tables.size(), 0);
    out[0] = 'O', out[1] = 'T', out[2] = 'T', out[3] = 'O';
    set16(out, 4, std::uint32_t(tables.size()));
    for (std::size_t i = 0; i < tables.size(); ++i) {
        while (out.size() % 4) out.push_back(0);
        const std::size_t rec = 12 + 16 * i;
        std::copy(tables[i].first, tables[i].first + 4, out.begin() + std::ptrdiff_t(rec));
        set32(out, rec + 8, std::uint32_t(out.size()));
        set32(out, rec + 12, std::uint32_t(tables[i].second->size()));
        out.insert(out.end(), tables[i].second->begin(), tables[i].second->end());
    }
    return out;
}

std::string problem_of(const Bytes& font) { return render::check_font_bytes(font.data(), font.size(), 0).problem; }

}  // namespace

TEST_CASE("cff font: a small OpenType font with PostScript outlines passes, plain and CID") {
    for (bool cid : {false, true}) {
        const Bytes font = make_otf(make_cff(cid).cff);
        CHECK(problem_of(font).empty());
        CHECK(says(font).empty());
        CHECK(render::check_font_bytes(font.data(), font.size(), 0).unsafeGlyphs.empty());
    }
}

TEST_CASE("cff font: an INDEX, offset or DICT that leaves the 'CFF ' table is refused with where and why") {
    const CffFont plain = make_cff(false), cid = make_cff(true);
    auto damaged = [&](const CffFont& c, auto&& patch) {
        CffFont d = c;
        patch(d.cff, d);
        return make_otf(d.cff);
    };

    // the fuzzer's find: a Name INDEX that claims 65535 entries of 4-byte offsets reads far past the table
    std::string why = problem_of(damaged(plain, [](Bytes& t, const CffFont& c) {
        set16(t, c.nameIndex, 0xFFFF);
        t[c.nameIndex + 2] = 4;
    }));
    CHECK(has(why, "'CFF ' table is damaged"));
    CHECK(has(why, "the Name INDEX"));
    CHECK(has(why, "outside"));
    CHECK(has(why, "at offset"));

    why = problem_of(damaged(plain, [](Bytes& t, const CffFont& c) { t[c.nameIndex + 2] = 9; }));
    CHECK(has(why, "offset size of 9"));

    why = problem_of(damaged(plain, [](Bytes& t, const CffFont&) { t[2] = 0xFF; }));  // header size past the table
    CHECK(has(why, "the header"));
    why = problem_of(damaged(plain, [](Bytes& t, const CffFont&) { t[2] = 1; }));  // under the 4 bytes of a header
    CHECK(has(why, "the header"));

    why = problem_of(damaged(plain, [](Bytes& t, const CffFont& c) { set32(t, c.topCharStrings, 0x7FFFFFF0); }));
    CHECK(has(why, "the CharStrings INDEX"));
    why = problem_of(damaged(plain, [](Bytes& t, const CffFont& c) { t[c.topDict] = 0xFF; }));  // a reserved operand
    CHECK(has(why, "the Top DICT"));
    CHECK(has(why, "operand byte 255"));

    why = problem_of(damaged(cid, [](Bytes& t, const CffFont& c) { set32(t, c.topFdArray, 0x00FFFFFF); }));
    CHECK(has(why, "the FDArray INDEX"));
    why = problem_of(damaged(cid, [](Bytes& t, const CffFont& c) { set32(t, c.topFdSelect, 0x00FFFFFF); }));
    CHECK(has(why, "the FDSelect"));
    why = problem_of(damaged(cid, [](Bytes& t, const CffFont& c) { set32(t, c.fontDict + 6, 0x00FFFFFF); }));
    CHECK(has(why, "Private DICT"));
    why = problem_of(damaged(cid, [](Bytes& t, const CffFont& c) { set32(t, c.privateDict + 1, 0x00FFFFFF); }));
    CHECK(has(why, "local subroutine INDEX"));
    why = problem_of(damaged(cid, [](Bytes& t, const CffFont& c) { t[c.fdSelect] = 7; }));
    CHECK(has(why, "FDSelect has format 7"));
    why =
        problem_of(damaged(cid, [](Bytes& t, const CffFont& c) { set16(t, c.fdSelect + 1, 60000); }));  // 60000 ranges
    CHECK(has(why, "FDSelect"));

    // an offset that is the length of the table points at its first byte past the end: reading from there leaves the table
    // (stb_truetype gives the FDSelect, and every other part, the window up to 512 MB, not the table's length)
    const std::uint32_t end = std::uint32_t(cid.cff.size());
    why = problem_of(damaged(cid, [&](Bytes& t, const CffFont& c) { set32(t, c.topFdSelect, end); }));
    CHECK(has(why, "FDSelect"));
    CHECK(has(why, "past the end of the table"));
    why = problem_of(damaged(cid, [&](Bytes& t, const CffFont& c) { set32(t, c.topFdArray, end); }));
    CHECK(has(why, "the FDArray INDEX"));
    why = problem_of(damaged(cid, [&](Bytes& t, const CffFont& c) { set32(t, c.topCharStrings, end); }));
    CHECK(has(why, "the CharStrings INDEX"));
    why = problem_of(
        damaged(cid, [&](Bytes& t, const CffFont& c) { set32(t, c.fontDict + 6, end); }));  // Private at the end
    CHECK(has(why, "Private DICT"));
    why = problem_of(damaged(
        cid, [&](Bytes& t, const CffFont& c) { set32(t, c.privateDict + 1, end - std::uint32_t(c.privateDict)); }));
    CHECK(has(why, "local subroutine INDEX"));
    why = problem_of(damaged(plain, [&](Bytes& t, const CffFont&) { t[2] = std::uint8_t(t.size()); }));  // header size
    CHECK(has(why, "the Name INDEX"));

    // 'maxp' counts glyphs the 'hmtx' table has no metrics for (stb_truetype reads them for a glyph of a CFF font too)
    CHECK(has(problem_of(make_otf(plain.cff, 0xFFFF)), "hmtx"));

    // the whole error reaches the caller, with a hint
    const Bytes bad = damaged(plain, [](Bytes& t, const CffFont& c) { t[c.nameIndex + 2] = 9; });
    auto bitmap = rasterize_text("A", bad, 20.0f);
    REQUIRE_FALSE(bitmap.ok());
    CHECK(has(bitmap.error().message, "damaged"));
    CHECK(has(bitmap.error().message, "'CFF ' table"));
    CHECK_FALSE(bitmap.error().hint.empty());
}

TEST_CASE(
    "cff font: a glyph with no charstring or no font dict is drawn as .notdef, a font without glyph 0 is refused") {
    CffFont plain = make_cff(false);
    set16(plain.cff, plain.charStrings, 1);  // one charstring, 'maxp' says two glyphs
    const Bytes font = make_otf(plain.cff);
    const render::FontCheck check = render::check_font_bytes(font.data(), font.size(), 0);
    CHECK(check.problem.empty());
    REQUIRE(check.unsafeGlyphs.size() == 2);
    CHECK(check.unsafeGlyphs[0] == 0);
    CHECK(check.unsafeGlyphs[1] == 1);
    CHECK(says(font).empty());

    set16(plain.cff, plain.charStrings, 0);
    CHECK(has(problem_of(make_otf(plain.cff)), "holds no glyphs"));

    CffFont cid = make_cff(true);
    cid.cff[cid.fdSelect + 5] = 4;  // both glyphs name font dict 4; the FDArray has one
    CHECK(has(problem_of(make_otf(cid.cff)), "glyph 0"));
    cid = make_cff(true);
    set16(cid.cff, cid.fdSelect + 3, 1);  // the first range starts at glyph 1: glyph 0 has no font dict
    CHECK(has(problem_of(make_otf(cid.cff)), "glyph 0"));
}

TEST_CASE(
    "cff font: every byte of a CFF table set to 0, 0x80 or 0xFF, and every cut of the font, is an error or draws") {
    for (bool cid : {false, true}) {
        const CffFont c = make_cff(cid);
        const Bytes good = make_otf(c.cff);
        const std::size_t at = table_at(good, "CFF ");
        REQUIRE(at != 0);
        for (std::size_t i = 0; i < c.cff.size(); ++i) {
            for (std::uint8_t v : {0x00, 0x80, 0xFF}) {
                Bytes font = good;
                font[at + i] = v;
                (void)says(font);
            }
        }
        for (std::size_t n = 0; n < good.size(); ++n) {
            const Bytes cut(good.begin(), good.begin() + std::ptrdiff_t(n));
            (void)says(cut);
        }
    }
}
