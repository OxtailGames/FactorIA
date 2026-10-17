// The text engine: HarfBuzz shaping, bidirectional text, the fallback font chain, line breaking between CJK characters, one
// measurement for every kind of text, the text size option and the GPU-free glyph coverage check.
//
// The fonts are small subsets of Noto Sans JP, KR and Arabic (SIL Open Font License, tests/data/fonts) that keep their GSUB
// and GPOS tables, so the shaping is the real thing. make_subsets.py there lists the characters these tests may draw.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <filesystem>
#include <string>
#include <vector>

#include "fa/render/fonts.h"
#include "text_shaper.h"

using namespace fa;
using namespace fa::test;
namespace fr = fa::render;

namespace {

const char* const kJp = "assets/fonts/NotoSansJP-Regular-subset.ttf";
const char* const kKr = "assets/fonts/NotoSansKR-Regular-subset.ttf";
const char* const kAr = "assets/fonts/NotoSansArabic-Regular-subset.ttf";

// The test project with the fixture fonts copied into assets/fonts (once), so Text.font, the fallback chain and the
// coverage check can name them like a game would.
Gfx& with_fonts() {
    Gfx& g = gfx();  // sets the project root first; the GPU is not needed by the tests that only shape
    static const bool installed = [&] {
        const std::filesystem::path to = g.projectDir / "assets" / "fonts";
        std::filesystem::create_directories(to);
        for (const char* name : {"NotoSansJP-Regular-subset.ttf", "NotoSansKR-Regular-subset.ttf", "NotoSansArabic-Regular-subset.ttf"})
            std::filesystem::copy_file(std::filesystem::path(FA_RENDER_DATA_DIR) / "fonts" / name, to / name,
                                       std::filesystem::copy_options::overwrite_existing);
        return true;
    }();
    (void)installed;
    return g;
}

// Puts the renderer's text options back when a test ends, so the next test starts from the defaults.
struct TextOptions {
    Renderer& r;
    ~TextOptions() {
        r.set_fallback_fonts({});
        r.set_text_scale(1.0f);
    }
};

// Loaded fonts in chain order and a way to shape a text with them, without a GPU.
struct Faces {
    std::vector<std::unique_ptr<fr::FontFace>> faces;
    explicit Faces(const std::vector<std::string>& keys) {
        for (const std::string& k : keys) {
            faces.push_back(fr::load_font_face(k));
            REQUIRE_MESSAGE(faces.back()->ok, faces.back()->error);
        }
    }
    fr::ShapedText shape(std::string_view text, int px = 20, float maxW = 0) {
        return fr::shape_text(text, px, maxW, faces.size(), [&](std::size_t i) { return faces[i].get(); });
    }
    // The advance of a code point drawn on its own, without shaping, in pixels.
    float nominal_advance(std::size_t font, char32_t cp, int px) const {
        hb_codepoint_t gid = 0;
        hb_font_get_nominal_glyph(faces[font]->hbFont, cp, &gid);
        return float(hb_font_get_glyph_h_advance(faces[font]->hbFont, gid)) * float(px) / float(faces[font]->unitsPerEm);
    }
};

// The bounding box of the bright pixels of a white-on-black image inside a pixel rectangle.
struct Ink {
    int x0 = 1 << 20, y0 = 1 << 20, x1 = -1, y1 = -1;
    bool any() const { return x1 >= x0; }
    int w() const { return x1 - x0 + 1; }
    int h() const { return y1 - y0 + 1; }
};
Ink ink(const Image& img, int rx0 = 0, int ry0 = 0, int rx1 = 1 << 20, int ry1 = 1 << 20, float threshold = 0.35f) {
    Ink k;
    for (int y = std::max(ry0, 0); y < std::min(ry1, img.height); ++y)
        for (int x = std::max(rx0, 0); x < std::min(rx1, img.width); ++x)
            if (img.pixel(x, y).r > threshold) {
                k.x0 = std::min(k.x0, x); k.y0 = std::min(k.y0, y);
                k.x1 = std::max(k.x1, x); k.y1 = std::max(k.y1, y);
            }
    return k;
}

Entity put_text(World& w, const std::string& s, Vec3 pos, float size, const std::string& font = "", Align al = Align::Left,
                float maxW = 0, RenderSpace sp = RenderSpace::World, Vec2 pivot = {0, 1}) {
    Entity e = make(w, "t", pos);
    auto& t = w.add<Text>(e);
    t.text = s; t.fontSize = size; t.font = font; t.align = al; t.maxWidth = maxW; t.space = sp; t.pivot = pivot;
    return e;
}

void add_black_camera(World& w) { w.add<Camera>(make(w, "cam")).clearColor = Color::black(); }

// The clusters (the logical index of the character each glyph draws) of the first line from left to right on screen. A
// letter drawn by several glyphs (a base and its marks) counts once.
std::vector<std::uint32_t> screen_order(const fr::ShapedText& t) {
    std::vector<std::uint32_t> out;
    for (const fr::ShapedGlyph& g : t.lines.at(0).glyphs)
        if (out.empty() || out.back() != g.cluster) out.push_back(g.cluster);
    return out;
}

const std::string kArabicWord = "العربية";                                // al-arabiyya: 7 letters
const std::string kJapanese = "日本語の長い文章はスペースがなくても折り返されます。";  // no spaces
const std::string kChinese = "這是一段沒有空格的中文文本需要自動換行";                 // no spaces
const std::string kKorean = "한국어도 글자 사이에서 줄이 바뀝니다";

}  // namespace

// ---- shaping and bidirectional text ---------------------------------------------------------------------------------------

TEST_CASE("text: Arabic letters take their joined forms, and a right-to-left line starts at its right end") {
    with_fonts();
    Faces f({kAr});
    const fr::ShapedText t = f.shape(kArabicWord);
    REQUIRE(t.lines.size() == 1);
    const auto& gl = t.lines[0].glyphs;
    const std::u32string cps = fr::decode_text(kArabicWord);
    REQUIRE(cps.size() == 7);
    CHECK(t.missing.empty());
    int joined = 0;
    for (const fr::ShapedGlyph& g : gl) {
        CHECK(g.gid != 0);
        if (g.advance <= 0) continue;  // a mark (the dots of a letter) sits on its base letter
        hb_codepoint_t isolated = 0;
        hb_font_get_nominal_glyph(f.faces[0]->hbFont, cps[g.cluster], &isolated);
        if (g.gid != isolated) ++joined;  // initial, medial or final form instead of the letter's own glyph
    }
    CHECK(joined >= 5);  // alef alone keeps its own shape; the other six letters join
    // the first letter of the word is the rightmost one: the letters run 6, 5, ... 0 from left to right on screen
    CHECK(screen_order(t) == std::vector<std::uint32_t>{6, 5, 4, 3, 2, 1, 0});
    CHECK(gl.back().cluster == 0);
    CHECK(gl.back().x > gl.front().x);
    // shaping the word is not the same as drawing its letters one by one in logical order
    float isolatedWidth = 0;
    for (char32_t c : cps) isolatedWidth += f.nominal_advance(0, c, 20);
    CHECK(std::fabs(t.lines[0].width - isolatedWidth) > 1.0f);
}

TEST_CASE("text: the base direction comes from the first strong character, and mixed text reorders per the Unicode algorithm") {
    with_fonts();
    Faces f({kAr});
    // Left-to-right paragraph: "abc " stays on the left; the digits after Arabic letters read left to right, but they come
    // before the Arabic on screen because the Arabic run flows from the right.
    const fr::ShapedText mixed = f.shape("abc العربية 123");
    CHECK(mixed.missing.empty());
    CHECK(screen_order(mixed) == std::vector<std::uint32_t>{0, 1, 2, 3, 12, 13, 14, 11, 10, 9, 8, 7, 6, 5, 4});
    // Right-to-left paragraph (the first strong character is Arabic): the Latin word lands on the left.
    const fr::ShapedText rtl = f.shape("العربية abc");
    CHECK(screen_order(rtl) == std::vector<std::uint32_t>{8, 9, 10, 7, 6, 5, 4, 3, 2, 1, 0});
    // Wrapping happens on the logical text first, then each line is reordered: two lines, each one a whole prefix of the text.
    const fr::ShapedText wrapped = f.shape("العربية abc العربية", 20, 90);
    REQUIRE(wrapped.lines.size() >= 2);
    std::u32string joinedText;
    for (const fr::ShapedLine& l : wrapped.lines) {
        joinedText += l.text;
        joinedText += U' ';
        CHECK(l.width <= 90.01f);
    }
    CHECK(joinedText.substr(0, joinedText.size() - 1) == fr::decode_text("العربية abc العربية").substr(0, joinedText.size() - 1));
}

TEST_CASE("text: kerning and ligatures come from HarfBuzz, not from adding up each letter's advance") {
    with_fonts();
    {
        Faces f({"builtin"});
        const int px = 100;
        const fr::ShapedText t = f.shape("AVAT", px);
        const float unshaped = f.nominal_advance(0, U'A', px) + f.nominal_advance(0, U'V', px) + f.nominal_advance(0, U'A', px) +
                               f.nominal_advance(0, U'T', px);
        CHECK(t.lines[0].width < unshaped - 5.0f);  // the AV, VA and AT pairs are kerned closer
        const fr::ShapedText plain = f.shape("HHHH", px);  // no pairs to kern: the sum is exact
        CHECK(plain.lines[0].width == doctest::Approx(4 * f.nominal_advance(0, U'H', px)).epsilon(0.001));
    }
    {
        Faces f({"builtin"});
        const fr::ShapedText t = f.shape("fi ffi", 20);  // DejaVu Sans has ligatures for fi and ffi: one glyph for 2 and 3 letters
        const auto& gl = t.lines.at(0).glyphs;
        REQUIRE(gl.size() == 3);  // fi, space, ffi
        hb_codepoint_t gf = 0, gi = 0;
        hb_font_get_nominal_glyph(f.faces[0]->hbFont, U'f', &gf);
        hb_font_get_nominal_glyph(f.faces[0]->hbFont, U'i', &gi);
        CHECK(gl[0].cluster == 0);
        CHECK(gl[0].gid != gf);
        CHECK(gl[0].gid != gi);
        CHECK(gl[2].cluster == 3);
        // without shaping the same characters are one glyph each
        CHECK(f.shape("f i", 20).lines.at(0).glyphs.size() == 3);
        CHECK(f.shape("fi", 20).lines.at(0).glyphs.size() == 1);
    }
}

// ---- line breaking ----------------------------------------------------------------------------------------------------------

TEST_CASE("text: Japanese, Chinese and Korean wrap at maxWidth without any space") {
    with_fonts();
    Faces f({"builtin", kJp, kKr});
    for (const std::string* s : {&kJapanese, &kChinese}) {
        const fr::ShapedText t = f.shape(*s, 16, 100);
        CHECK(t.missing.empty());
        CHECK(t.lines.size() >= 3);
        std::u32string all;
        for (const fr::ShapedLine& l : t.lines) {
            CHECK(l.width <= 100.01f);
            CHECK(!l.text.empty());
            all += l.text;
        }
        CHECK(all == fr::decode_text(*s));  // nothing lost, nothing added: the breaks fall between characters
    }
    // Korean breaks between words at spaces, and inside a long word between syllables
    const fr::ShapedText ko = f.shape(kKorean, 14, 90);
    CHECK(ko.missing.empty());
    CHECK(ko.lines.size() >= 3);
    const fr::ShapedText longWord = f.shape("한국어는띄어쓰기없이도줄바꿈됩니다", 14, 60);
    CHECK(longWord.lines.size() >= 3);
    for (const fr::ShapedLine& l : longWord.lines) CHECK(l.width <= 60.01f);
}

TEST_CASE("text: kinsoku keeps closing punctuation off the start of a line and opening brackets off the end") {
    with_fonts();
    Faces f({"builtin", kJp});
    const std::string s = "吾輩は「猫」である。名前は『無い』。（テスト）日本語の「長い文章」。";
    const std::u32string noStart = U"。、」』）！？ー";
    const std::u32string noEnd = U"「『（";
    int widthsTried = 0;
    for (float maxW = 36; maxW <= 260; maxW += 5) {
        const fr::ShapedText t = f.shape(s, 16, maxW);
        CHECK(t.missing.empty());
        for (const fr::ShapedLine& l : t.lines) {
            REQUIRE(!l.text.empty());
            INFO("maxWidth " << maxW);
            CHECK(noStart.find(l.text.front()) == std::u32string::npos);
            CHECK(noEnd.find(l.text.back()) == std::u32string::npos);
        }
        ++widthsTried;
    }
    CHECK(widthsTried > 40);
}

TEST_CASE("text: Latin text still breaks only at spaces") {
    with_fonts();
    Faces f({"builtin", kJp});
    const std::string s = "Hello wrapped world of text";
    const fr::ShapedText t = f.shape(s, 20, 110);
    REQUIRE(t.lines.size() >= 3);
    std::u32string rebuilt;
    for (const fr::ShapedLine& l : t.lines) {
        CHECK(l.width <= 110.01f);
        CHECK(l.text.back() != U' ');  // the space the line broke at is not drawn at its end
        rebuilt += (rebuilt.empty() ? U"" : U" ") + l.text;
    }
    CHECK(rebuilt == fr::decode_text(s));  // every break was a space: no word was cut
}

// ---- the fallback chain ---------------------------------------------------------------------------------------------------

TEST_CASE("text: each character is drawn by the first font of the chain that has it") {
    with_fonts();
    {
        Faces f({"builtin", kJp, kKr});
        const fr::ShapedText t = f.shape("a\xE6\x97\xA5\xED\x95\x9C");  // a, JP/KR ideograph "ri" (U+65E5), Hangul syllable han (U+D55C)
        const auto& gl = t.lines.at(0).glyphs;
        REQUIRE(gl.size() == 3);
        CHECK(gl[0].face == f.faces[0].get());  // DejaVu Sans has the Latin letter
        CHECK(gl[1].face == f.faces[1].get());  // the ideograph: both JP and KR have it; JP comes first
        CHECK(gl[2].face == f.faces[2].get());  // only Korean has Hangul
        CHECK(t.missing.empty());
    }
    {
        Faces f({"builtin", kKr, kJp});  // the other order: the same ideograph now comes from Korean
        const fr::ShapedText t = f.shape("\xE6\x97\xA5");
        const auto& gl = t.lines.at(0).glyphs;
        REQUIRE(gl.size() == 1);
        CHECK(gl[0].face == f.faces[1].get());
    }
    {
        // a combining mark is shaped with its base letter, in the same font when that font has the mark...
        Faces f({kJp, "builtin"});  // (JP first: it has no Latin, so the letter and its accent both come from DejaVu Sans)
        const fr::ShapedText t = f.shape("a\xCC\x81");  // a + U+0301 combining acute
        REQUIRE(t.lines.at(0).glyphs.size() >= 1);
        for (const fr::ShapedGlyph& g : t.lines.at(0).glyphs) CHECK(g.face == f.faces[1].get());
        // ...and drawn by the next font that has it when the base letter's font lacks it, instead of vanishing
        const fr::ShapedText jp = f.shape("\xE6\x97\xA5\xCC\x81");  // ideograph (JP) + the same accent (not in the JP subset)
        REQUIRE(jp.lines.at(0).glyphs.size() == 2);
        CHECK(jp.lines.at(0).glyphs[0].face == f.faces[0].get());
        CHECK(jp.lines.at(0).glyphs[1].face == f.faces[1].get());
        CHECK(jp.missing.empty());
    }
    {
        // a character no font has is reported, and is not drawn
        Faces f({"builtin", kJp});
        const fr::ShapedText t = f.shape("a\xF0\x9F\xAB\xA0" "b");  // U+1FAE0 melting face: a colour emoji, in no font here
        CHECK(t.missing == std::vector<char32_t>{0x1FAE0});
        const auto& gl = t.lines.at(0).glyphs;
        CHECK(std::count_if(gl.begin(), gl.end(), [](const fr::ShapedGlyph& g) { return g.gid == 0; }) == 1);  // its .notdef: never drawn
    }
}

TEST_CASE("text: set_fallback_fonts takes effect on the next layout, and a font that cannot be read is skipped") {
    Gfx& g = with_fonts();
    REQUIRE(g.ok);
    TextOptions restore{g.renderer};
    g.renderer.clear_asset_cache();
    clear_recent_logs();
    World w; add_black_camera(w);
    put_text(w, "\xE6\x97\xA5\xE6\x9C\xAC\xE8\xAA\x9E", {-120, 40, 0}, 30);  // the ideographs of "Japanese"
    Image none = g.render(w);
    CHECK_FALSE(ink(none).any());  // DejaVu Sans has none: nothing is drawn
    g.renderer.set_fallback_fonts({kJp});
    Image with = g.render(w);  // the same Text, now drawn: no entity changed
    Ink k = ink(with);
    REQUIRE(k.any());
    CHECK(k.w() > 40);
    g.renderer.set_fallback_fonts({});
    CHECK_FALSE(ink(g.render(w)).any());
    // the width is the fallback font's advance: measure_text sees the same chain
    g.renderer.set_fallback_fonts({kJp});
    Faces f({kJp});
    CHECK(g.renderer.measure_text("\xE6\x97\xA5", 20).x == doctest::Approx(f.nominal_advance(0, 0x65E5, 20)).epsilon(0.001));
    // a font that cannot be read is skipped, with the failure reported once
    g.renderer.set_fallback_fonts({"assets/fonts/not-there.ttf", kJp});
    CHECK(ink(g.render(w)).any());
    int failures = 0;
    for (const auto& l : recent_logs(200, LogLevel::Error))
        if (l.message.find("not-there.ttf") != std::string::npos) ++failures;
    CHECK(failures == 1);
}

TEST_CASE("text: DejaVu Sans is the last font of every chain, and the missing-glyph warning names only what no font has") {
    Gfx& g = with_fonts();
    REQUIRE(g.ok);
    TextOptions restore{g.renderer};
    g.renderer.set_fallback_fonts({kJp});
    g.renderer.clear_asset_cache();
    clear_recent_logs();
    World w; add_black_camera(w);
    // Press Start 2P has no Hebrew (DejaVu Sans, behind it, does) and no Hangul (nobody has it: the JP subset has none)
    put_text(w, "Pixel \xD7\x90 \xE6\x97\xA5\xE6\x9C\xAC \xED\x95\x9C", {-150, 60, 0}, 16, "builtin:pixel");
    for (int i = 0; i < 3; ++i) g.render(w);
    std::vector<std::string> warnings;
    for (const auto& l : recent_logs(200, LogLevel::Warn))
        if (l.message.find("no glyph for") != std::string::npos) warnings.push_back(l.message);
    REQUIRE(warnings.size() == 1);  // once per font, not per frame
    const std::string& m = warnings[0];
    CHECK(m.find("U+D55C") != std::string::npos);        // the Hangul syllable
    CHECK(m.find("U+65E5") == std::string::npos);        // the JP fallback drew the ideographs
    CHECK(m.find("U+05D0") == std::string::npos);        // DejaVu Sans, last in the chain, drew the Hebrew letter
    CHECK(m.find("builtin:pixel") != std::string::npos);
    CHECK(m.find(kJp) != std::string::npos);             // the chain that was searched
    CHECK(m.find("Noto Sans") != std::string::npos);     // what to do about Korean
}

// ---- one measurement for every kind of text -----------------------------------------------------------------------------------

TEST_CASE("text: measure_text is the box Text drawing lays out, wrapped or not, and the ink stays inside it") {
    Gfx& g = with_fonts();
    REQUIRE(g.ok);
    TextOptions restore{g.renderer};
    g.renderer.set_fallback_fonts({kJp, kAr});
    Faces f({"builtin", kJp, kAr});
    int asc = 0, desc = 0, gap = 0;
    stbtt_GetFontVMetrics(&f.faces[0]->info, &asc, &desc, &gap);
    const float scale = stbtt_ScaleForMappingEmToPixels(&f.faces[0]->info, 20.0f);
    struct Case { std::string text; float size, maxW; };
    const std::vector<Case> cases = {{"HHHH", 20, 0},
                                     {kJapanese, 20, 120},
                                     {"abc " + kArabicWord + " 123", 20, 0},
                                     {"Hello wrapped world of text", 20, 100},
                                     {"two\nlines", 20, 0}};
    for (const Case& c : cases) {
        INFO("text " << c.text);
        const float lineH = std::round((float(asc - desc + gap)) * scale);
        const fr::ShapedText shaped = f.shape(c.text, 20, c.maxW);
        float widest = 0;
        for (const fr::ShapedLine& l : shaped.lines) widest = std::max(widest, l.width);
        const Vec2 m = g.renderer.measure_text(c.text, c.size, "", c.maxW);
        CHECK(m.x == doctest::Approx(c.maxW > 0 ? std::max(widest, c.maxW) : widest).epsilon(0.001));
        CHECK(m.y == doctest::Approx(lineH * float(shaped.lines.size())).epsilon(0.001));
        // drawn: the ink is inside the measured rectangle (top-left of the Text is world (-120, 70) = pixel (40, 20))
        World w; add_black_camera(w);
        put_text(w, c.text, {-120, 70, 0}, c.size, "", Align::Left, c.maxW);
        const Image img = g.render(w);
        const Ink k = ink(img);
        REQUIRE(k.any());
        CHECK(k.x0 >= 40 - 1);
        CHECK(k.y0 >= 20 - 1);
        CHECK(float(k.x1) <= 40 + m.x + 1);
        CHECK(float(k.y1) <= 20 + m.y + 1);
        CHECK(float(k.h()) >= m.y * 0.4f);
        if (c.maxW <= 0) CHECK(float(k.w()) >= m.x * 0.7f);
    }
}

TEST_CASE("text: UI labels and debug text use the same layout and the same fallback chain") {
    Gfx& g = with_fonts();
    REQUIRE(g.ok);
    TextOptions restore{g.renderer};
    g.renderer.set_fallback_fonts({kJp});
    World w; add_black_camera(w);
    Entity e = make(w, "play", {20, 20, 0});
    Button& b = w.add<Button>(e);
    b.size = {200, 50};
    b.pivot = {0, 1};
    b.color = Color{0, 0, 0, 0};
    b.text = "\xE6\x97\xA5\xE6\x9C\xAC\xE8\xAA\x9E";  // the ideographs of "Japanese": drawn only through the fallback chain
    b.fontSize = 24;
    Image img = g.render(w);
    const Ink label = ink(img, 20, 20, 220, 70);
    REQUIRE(label.any());
    CHECK(label.w() > 30);
    // the label is centred in its button, as before
    CHECK(std::abs((label.x0 + label.x1) / 2 - 120) < 12);
    // debug text goes through the same layout: it draws the ideographs too
    g.renderer.debug().text({10, 120}, "\xE6\x97\xA5\xE6\x9C\xAC\xE8\xAA\x9E", Color::white(), 24);
    World empty; add_black_camera(empty);
    CHECK(ink(g.render(empty), 0, 110, 320, 170).any());
    g.renderer.set_fallback_fonts({});
    g.renderer.debug().text({10, 120}, "\xE6\x97\xA5\xE6\x9C\xAC\xE8\xAA\x9E", Color::white(), 24);
    CHECK_FALSE(ink(g.render(empty), 0, 110, 320, 170).any());
}

// ---- the text size option -----------------------------------------------------------------------------------------------------

TEST_CASE("text: the text scale resizes screen-space Text and UI labels, never world-space Text") {
    Gfx& g = with_fonts();
    REQUIRE(g.ok);
    TextOptions restore{g.renderer};
    World w; add_black_camera(w);
    put_text(w, "HHHH", {10, 10, 0}, 20, "", Align::Left, 0, RenderSpace::Screen);  // top-left of the screen
    put_text(w, "HHHH", {-150, -30, 0}, 20);                                        // world: pixel (10, 120)
    Entity e = make(w, "btn", {150, 10, 0});
    Button& b = w.add<Button>(e);
    b.size = {160, 60};
    b.pivot = {0, 1};
    b.color = Color{0, 0, 0, 0};
    b.text = "HHHH";
    b.fontSize = 20;
    auto boxes = [&](Ink& screen, Ink& world, Ink& button) {
        const Image img = g.render(w);
        screen = ink(img, 0, 0, 140, 100);
        world = ink(img, 0, 100, 140, 180);
        button = ink(img, 150, 0, 320, 100);
    };
    Ink s1, w1, b1, s2, w2, b2;
    boxes(s1, w1, b1);
    const Vec2 screenM1 = g.renderer.measure_text("HHHH", 20, "", 0, RenderSpace::Screen);
    const Vec2 worldM1 = g.renderer.measure_text("HHHH", 20, "", 0, RenderSpace::World);
    REQUIRE((s1.any() && w1.any() && b1.any()));
    CHECK(screenM1.x == doctest::Approx(worldM1.x));

    g.renderer.set_text_scale(2.0f);
    CHECK(g.renderer.text_scale() == 2.0f);
    boxes(s2, w2, b2);
    REQUIRE((s2.any() && w2.any() && b2.any()));
    CHECK(std::abs(s2.w() - 2 * s1.w()) <= 4);     // screen-space Text: twice as big
    CHECK(std::abs(s2.h() - 2 * s1.h()) <= 4);
    CHECK(std::abs(b2.w() - 2 * b1.w()) <= 4);     // the label of a widget: twice as big
    CHECK(std::abs(b2.h() - 2 * b1.h()) <= 4);
    CHECK(w2.x0 == w1.x0);                         // world-space Text: untouched, pixel for pixel
    CHECK(w2.x1 == w1.x1);
    CHECK(w2.y0 == w1.y0);
    CHECK(w2.y1 == w1.y1);
    // the measurements agree with what is drawn
    CHECK(g.renderer.measure_text("HHHH", 20, "", 0, RenderSpace::Screen).x == doctest::Approx(2 * screenM1.x).epsilon(0.01));
    CHECK(g.renderer.measure_text("HHHH", 20, "", 0, RenderSpace::World).x == doctest::Approx(worldM1.x));
    CHECK(g.renderer.measure_text("HHHH", 20, "", 0, RenderSpace::Screen).y == doctest::Approx(2 * screenM1.y).epsilon(0.05));

    g.renderer.set_text_scale(1.0f);
    boxes(s2, w2, b2);
    CHECK(s2.w() == s1.w());  // back to normal
}

TEST_CASE("text: the text scale is clamped to 0.5 .. 3 and ignores NaN") {
    Renderer r;  // the option is kept before init, so no GPU is needed
    CHECK(r.text_scale() == 1.0f);
    r.set_text_scale(1.5f);
    CHECK(r.text_scale() == 1.5f);
    r.set_text_scale(10.0f);
    CHECK(r.text_scale() == kMaxTextScale);
    r.set_text_scale(0.1f);
    CHECK(r.text_scale() == kMinTextScale);
    r.set_text_scale(std::nanf(""));
    CHECK(r.text_scale() == 1.0f);
}

// ---- the picture --------------------------------------------------------------------------------------------------------------

TEST_CASE("text: Japanese, Chinese, Korean and Arabic draw together through the fallback chain (golden)") {
    Gfx& g = with_fonts();
    REQUIRE(g.ok);
    TextOptions restore{g.renderer};
    g.renderer.set_fallback_fonts({kJp, kKr});
    World w;
    w.add<Camera>(make(w, "cam")).clearColor = Color::hex(0x101820);
    // the Arabic font is the Text's own font: the ideographs and Hangul come from the fallback fonts, behind it
    put_text(w, "日本語 中文 한국어 العربية", {-155, 84, 0}, 20, kAr);
    put_text(w, "abc " + kArabicWord + " 123", {-155, 58, 0}, 20, kAr);
    put_text(w, kJapanese, {-155, 26, 0}, 16, "", Align::Left, 150);
    put_text(w, kChinese, {10, 26, 0}, 16, "", Align::Left, 145);
    put_text(w, kKorean, {-155, -40, 0}, 14, "", Align::Left, 150);
    put_text(w, "مرحبا بالعالم", {155, -80, 0}, 20, kAr, Align::Right, 0, RenderSpace::World, {1, 0});
    put_text(w, "\xE6\x97\xA5\xE6\x9C\xAC\xE8\xAA\x9E", {314, 4, 0}, 12, "", Align::Right, 0, RenderSpace::Screen, {1, 1});
    const Image img = g.render(w);
    expect_golden(img, "2d_text_scripts");
    CHECK(g.renderer.stats().textGlyphs > 60);
}

TEST_CASE("text: Align is explicit: Left stays at the left edge for right-to-left text too") {
    Gfx& g = with_fonts();
    REQUIRE(g.ok);
    TextOptions restore{g.renderer};
    auto box = [&](Align a) {
        World w; add_black_camera(w);
        put_text(w, kArabicWord, {-100, 40, 0}, 24, kAr, a, 200);  // a 200 px wide box from pixel x = 60
        return ink(g.render(w));
    };
    const Ink left = box(Align::Left), right = box(Align::Right), center = box(Align::Center);
    REQUIRE((left.any() && right.any() && center.any()));
    CHECK(left.x0 < 60 + 8);
    CHECK(right.x1 > 260 - 8);
    CHECK(std::abs((center.x0 + center.x1) / 2 - 160) < 8);
}

// ---- the coverage check (no GPU) ------------------------------------------------------------------------------------------------

TEST_CASE("fonts: missing_glyphs lists what no font of the chain can draw") {
    with_fonts();
    auto u = [](std::vector<std::uint32_t> v) { return v; };
    // DejaVu Sans is always last: Latin, Greek, Cyrillic and Hebrew are covered with no chain at all
    auto latin = missing_glyphs("Año ñandú, Ωμέγα, Привет, \xD7\x90", {});
    REQUIRE(latin.ok());
    CHECK(latin->empty());
    auto cjk = missing_glyphs("a日本語b日", {});
    REQUIRE(cjk.ok());
    CHECK(*cjk == u({0x65E5, 0x672C, 0x8A9E}));  // in order of first appearance, each once
    // the project's fonts cover them
    auto covered = missing_glyphs("日本語 中文 한국어 العربية", {kJp, kKr, kAr});
    REQUIRE(covered.ok());
    CHECK(covered->empty());
    auto partial = missing_glyphs("日本語 한국어", {kJp});
    REQUIRE(partial.ok());
    CHECK(*partial == u({0xD55C, 0xAD6D, 0xC5B4}));
    // the Text's own font comes first in the chain but does not hide the others
    auto pixel = missing_glyphs("Pixel 日", {"builtin:pixel"});
    REQUIRE(pixel.ok());
    CHECK(*pixel == u({0x65E5}));
    // reuse: one load, many texts
    auto chain = FontCoverage::load({kJp, kKr});
    REQUIRE(chain.ok());
    CHECK(chain->missing("日本語한국어").empty());
    CHECK(chain->missing("\xF0\x9F\xAB\xA0") == u({0x1FAE0}));  // colour emoji: no font has them
}

TEST_CASE("fonts: characters that draw nothing never count as missing") {
    with_fonts();
    // zero-width joiner and non-joiner, direction marks, variation selector, BOM, soft hyphen, tab, newline, controls
    auto none = missing_glyphs("a\xE2\x80\x8D" "b\xE2\x80\x8C" "c\xE2\x80\x8E\xE2\x80\x8F\xEF\xB8\x8F\xEF\xBB\xBF\xC2\xAD\t\n\r\x01 ", {});
    REQUIRE(none.ok());
    CHECK(none->empty());
    // the visible ones next to them still count
    auto some = missing_glyphs("\xE2\x80\x8D" "日\xEF\xB8\x8F", {});
    REQUIRE(some.ok());
    CHECK(*some == std::vector<std::uint32_t>{0x65E5});
    // malformed UTF-8 counts as U+FFFD, which DejaVu Sans has
    auto bad = missing_glyphs("a\xFF" "b", {});
    REQUIRE(bad.ok());
    CHECK(bad->empty());
}

TEST_CASE("fonts: a font that cannot be loaded is an error that says which file and what to do, never missing glyphs") {
    Gfx& g = with_fonts();
    auto absent = missing_glyphs("abc", {"assets/fonts/not-there.ttf"});
    REQUIRE_FALSE(absent.ok());
    CHECK(absent.error().message.find("not-there.ttf") != std::string::npos);
    CHECK_FALSE(absent.error().hint.empty());
    REQUIRE(fs::write_text("assets/fonts/bogus.ttf", "this is not a font").ok());
    auto bogus = missing_glyphs("abc", {kJp, "assets/fonts/bogus.ttf"});
    REQUIRE_FALSE(bogus.ok());
    CHECK(bogus.error().message.find("bogus.ttf") != std::string::npos);
    CHECK_FALSE(bogus.error().hint.empty());
    auto load = FontCoverage::load({"assets/fonts/bogus.ttf"});
    CHECK_FALSE(load.ok());
    (void)g;
}
