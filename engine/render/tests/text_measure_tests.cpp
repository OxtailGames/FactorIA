// Text measuring without a GPU (fa/render/text_measure.h): a TextMeasurer gives the very numbers Renderer::measure_text does, for the
// built-in fonts and for a project's, for Latin, CJK, Arabic and the fallback chain, wrapped or not, with rich text, the text scale,
// the interface scale and the fit options of a Text. The sizes are compared with ==, not with a tolerance: the two go through one
// implementation (render/src/font_set.h), so a layout that is a pixel wider in a run with no graphics is a bug.
#include "test_util.h"

#include <cmath>
#include <filesystem>
#include <string>
#include <vector>

#include "fa/render/text_measure.h"
#include "fa/scene/bounds.h"

using namespace fa;
using namespace fa::test;

namespace {

const char* const kJp = "assets/fonts/NotoSansJP-Regular-subset.ttf";
const char* const kKr = "assets/fonts/NotoSansKR-Regular-subset.ttf";
const char* const kAr = "assets/fonts/NotoSansArabic-Regular-subset.ttf";

// The test project with the fixture fonts copied into assets/fonts (once), so Text.font and the fallback chain can name them like a game would.
Gfx& with_fonts() {
    Gfx& g = gfx();
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

// Both measurers with the same settings, and the renderer's put back to the defaults when a test ends.
struct Pair {
    Renderer& r;
    TextMeasurer cpu;
    explicit Pair(Gfx& g) : r(g.renderer) {}
    ~Pair() {
        r.set_fallback_fonts({});
        r.set_text_scale(1.0f);
        r.set_ui_scale(1.0f);
    }
    void fallback(std::vector<std::string> fonts) {
        r.set_fallback_fonts(fonts);
        cpu.set_fallback_fonts(std::move(fonts));
    }
    void text_scale(float s) {
        r.set_text_scale(s);
        cpu.set_text_scale(s);
    }
    void ui_scale(float s) {
        r.set_ui_scale(s);
        cpu.set_ui_scale(s);
    }
};

const std::string kArabicWord = "العربية";
const std::string kJapanese = "日本語の長い文章はスペースがなくても折り返されます。";
const std::string kKorean = "한국어도 글자 사이에서 줄이 바뀝니다";

}  // namespace

TEST_CASE("measure: a TextMeasurer gives the numbers of Renderer::measure_text for Latin, CJK, Arabic and wrapped text") {
    Gfx& g = with_fonts();
    REQUIRE(g.ok);
    Pair p(g);
    p.fallback({kJp, kKr, kAr});
    struct Case { std::string text; float size; std::string font; float maxW; };
    const std::vector<Case> cases = {{"Hello world", 20, "", 0},
                                     {"VSync", 12, "", 0},
                                     {"Hello wrapped world of text that is long", 20, "", 100},
                                     {"two\nlines", 24, "", 0},
                                     {kJapanese, 20, "", 120},
                                     {kKorean, 18, "", 90},
                                     {"abc " + kArabicWord + " 123", 20, "", 0},
                                     {kArabicWord, 30, kAr, 0},
                                     {"a\xF0\x9F\xAB\xA0" "b", 20, "", 0},  // melting face: in no font, drawn as the missing glyph
                                     {"Mixed ", 16, kJp, 0}};
    for (const Case& c : cases) {
        INFO("text " << c.text << " size " << c.size << " font '" << c.font << "' maxWidth " << c.maxW);
        for (const RenderSpace space : {RenderSpace::World, RenderSpace::Screen}) {
            const Vec2 gpu = p.r.measure_text(c.text, c.size, c.font, c.maxW, space);
            const Vec2 cpu = p.cpu.measure_text(c.text, c.size, c.font, c.maxW, space);
            CHECK(cpu.x == gpu.x);
            CHECK(cpu.y == gpu.y);
            CHECK(cpu.x > 0);
            CHECK(cpu.y > 0);
        }
    }
}

TEST_CASE("measure: the same sizes with the text scale and the interface scale, for plain text and for a Text") {
    Gfx& g = with_fonts();
    REQUIRE(g.ok);
    Pair p(g);
    p.fallback({kJp});
    for (const float textScale : {0.5f, 1.0f, 1.75f, 3.0f}) {
        for (const float uiScale : {1.0f, 1.5f, 2.0f}) {
            INFO("textScale " << textScale << " uiScale " << uiScale);
            p.text_scale(textScale);
            p.ui_scale(uiScale);
            for (const RenderSpace space : {RenderSpace::World, RenderSpace::Screen}) {
                const Vec2 gpu = p.r.measure_text("Score: 12345 " + kJapanese, 18, "", 160, space);
                const Vec2 cpu = p.cpu.measure_text("Score: 12345 " + kJapanese, 18, "", 160, space);
                CHECK(cpu.x == gpu.x);
                CHECK(cpu.y == gpu.y);
                Text t;
                t.text = "Settings and more settings";
                t.fontSize = 22;
                t.maxWidth = 150;
                t.space = space;
                const Vec2 tg = p.r.measure_text(t), tc = p.cpu.measure_text(t);
                CHECK(tc.x == tg.x);
                CHECK(tc.y == tg.y);
            }
        }
    }
}

TEST_CASE("measure: maxTextScale, autoShrink and minFontSize give the same Text size without a renderer") {
    Gfx& g = with_fonts();
    REQUIRE(g.ok);
    Pair p(g);
    p.text_scale(2.5f);
    struct Case { float maxTextScale; bool autoShrink; float minFontSize, maxHeight; float maxWidth; };
    const std::vector<Case> cases = {{0, false, 10, 0, 0},  {1.3f, false, 10, 0, 0}, {0, true, 10, 40, 120},
                                     {0, true, 14, 30, 100}, {2.0f, true, 8, 60, 200}};
    for (const Case& c : cases) {
        Text t;
        t.text = "A heading that does not quite fit";
        t.fontSize = 30;
        t.space = RenderSpace::Screen;
        t.maxTextScale = c.maxTextScale;
        t.autoShrink = c.autoShrink;
        t.minFontSize = c.minFontSize;
        t.maxHeight = c.maxHeight;
        t.maxWidth = c.maxWidth;
        const Vec2 gpu = p.r.measure_text(t), cpu = p.cpu.measure_text(t);
        INFO("maxTextScale " << c.maxTextScale << " autoShrink " << c.autoShrink << " maxWidth " << c.maxWidth);
        CHECK(cpu.x == gpu.x);
        CHECK(cpu.y == gpu.y);
    }
}

TEST_CASE("measure: rich text (tags are not characters, bold, icons) is the same size without a renderer") {
    Gfx& g = with_fonts();
    REQUIRE(g.ok);
    Pair p(g);
    TextStyle plain, markup;
    markup.markup = true;
    TextStyle bold = markup;
    bold.bold = true;
    const std::string rich = "Sold [c:good]3[/c] [b]big[/b] fish for [c:bad]12[/c] coins";
    const Vec2 gpuMarkup = p.r.measure_text(rich, 20, "", 0, RenderSpace::World, markup);
    const Vec2 cpuMarkup = p.cpu.measure_text(rich, 20, "", 0, RenderSpace::World, markup);
    CHECK(cpuMarkup.x == gpuMarkup.x);
    CHECK(cpuMarkup.y == gpuMarkup.y);
    // the tags take no room: the same words without them are as wide
    const Vec2 bare = p.cpu.measure_text("Sold 3 big fish for 12 coins", 20, "", 0, RenderSpace::World, plain);
    CHECK(cpuMarkup.x > bare.x);  // [b] draws bold, which is wider
    const Vec2 colourOnly = p.cpu.measure_text("Sold [c:good]3[/c] fish [c:bad]12[/c]", 20, "", 0, RenderSpace::World, markup);
    CHECK(colourOnly.x == p.cpu.measure_text("Sold 3 fish 12", 20, "", 0, RenderSpace::World, plain).x);
    // a whole Text drawn bold, and wrapped
    const Vec2 gpuBold = p.r.measure_text(rich, 20, "", 90, RenderSpace::World, bold);
    const Vec2 cpuBold = p.cpu.measure_text(rich, 20, "", 90, RenderSpace::World, bold);
    CHECK(cpuBold.x == gpuBold.x);
    CHECK(cpuBold.y == gpuBold.y);
    CHECK(cpuBold.y > cpuMarkup.y);  // wrapped into several lines
    // a Text component
    Text t;
    t.text = rich;
    t.markup = true;
    t.fontSize = 18;
    t.maxWidth = 120;
    CHECK(p.cpu.measure_text(t).x == p.r.measure_text(t).x);
    CHECK(p.cpu.measure_text(t).y == p.r.measure_text(t).y);
}

TEST_CASE("measure: a font that cannot be read measures like the renderer does, and the built-in font alone needs no project file") {
    Gfx& g = with_fonts();
    REQUIRE(g.ok);
    Pair p(g);
    p.fallback({"assets/fonts/not-there.ttf", kJp});  // skipped, the next font of the chain serves
    const Vec2 gpu = p.r.measure_text(kJapanese, 20, "", 0);
    const Vec2 cpu = p.cpu.measure_text(kJapanese, 20, "", 0);
    CHECK(cpu.x == gpu.x);
    CHECK(cpu.y == gpu.y);
    CHECK(cpu.x > 0);
    const Vec2 missingOwn = p.cpu.measure_text("abc", 20, "assets/fonts/not-there.ttf", 0);
    CHECK(missingOwn.x == p.r.measure_text("abc", 20, "assets/fonts/not-there.ttf", 0).x);
    // nothing to measure
    CHECK(p.cpu.measure_text("", 20).x == 0);
    CHECK(p.cpu.measure_text("abc", 0).x == 0);
}
