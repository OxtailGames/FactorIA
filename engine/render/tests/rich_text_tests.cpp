// Rich text: Text.markup ([b], [c:], [icon:]) and Text.bold drawn and measured by the renderer. The markup parser and the
// "text" section have their own tests in engine/scene/tests/test_rich_text.cpp.
#include "test_util.h"

#include <algorithm>
#include <cmath>
#include <filesystem>
#include <string>

#include "fa/render/fonts.h"
#include "fa/scene/bounds.h"
#include "fa/scene/rich_text.h"

using namespace fa;
using namespace fa::test;

namespace {

constexpr float kLineEps = 0.01f;
const TextStyle kMarkup{true, false};
const TextStyle kBold{false, true};

// The project style of these tests: two colours and two icons (a red and a blue square of a 16 x 8 texture, the second one
// twice as wide as high), written into the test project once.
RichTextStyle test_style() {
    static const bool written = [] {
        Image img;
        img.width = 24;
        img.height = 8;
        img.rgba.resize(std::size_t(24 * 8 * 4));
        for (int y = 0; y < 8; ++y)
            for (int x = 0; x < 24; ++x) img.set_pixel(x, y, x < 8 ? Color{1, 0, 0, 1} : Color{0, 0, 1, 1});
        REQUIRE(save_png(img, "assets/rich_icons.png").ok());
        return true;
    }();
    (void)written;
    RichTextStyle s;
    s.colors["good"] = Color{0.2f, 1.0f, 0.2f, 1.0f};
    s.colors["bad"] = Color{1.0f, 0.2f, 0.2f, 1.0f};
    s.icons["fish"] = {"assets/rich_icons.png", 0, 0, 8, 8};   // a red square
    s.icons["wide"] = {"assets/rich_icons.png", 8, 0, 16, 8};  // a blue rectangle, twice as wide as high
    return s;
}

// Installs the style for one test and puts the renderer back to the defaults when it ends.
struct RichStyleGuard {
    Renderer& r;
    explicit RichStyleGuard(Renderer& renderer, RichTextStyle s = test_style()) : r(renderer) { r.set_rich_text_style(std::move(s)); }
    ~RichStyleGuard() {
        r.set_rich_text_style({});
        r.set_fallback_fonts({});
        r.set_text_scale(1.0f);
    }
};

float line_height(Renderer& r, float size) { return r.measure_text("Ag", size).y; }

Entity put_markup(World& w, const std::string& s, Vec3 pos, float size, float maxW = 0, bool bold = false) {
    Entity e = make(w, "t", pos);
    Text& t = w.add<Text>(e);
    t.text = s;
    t.fontSize = size;
    t.maxWidth = maxW;
    t.markup = true;
    t.bold = bold;
    t.pivot = {0, 1};
    return e;
}

void add_camera(World& w) { w.add<Camera>(make(w, "cam")).clearColor = Color::black(); }

struct Box {
    int x0 = 1 << 20, y0 = 1 << 20, x1 = -1, y1 = -1, count = 0;
    bool any() const { return count > 0; }
    int w() const { return x1 - x0 + 1; }
    int h() const { return y1 - y0 + 1; }
};
// The bounding box of the pixels `pick` accepts.
template <class Pick>
Box box_of(const Image& img, Pick pick) {
    Box b;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x)
            if (pick(img.pixel(x, y))) {
                b.x0 = std::min(b.x0, x); b.y0 = std::min(b.y0, y);
                b.x1 = std::max(b.x1, x); b.y1 = std::max(b.y1, y);
                ++b.count;
            }
    return b;
}
bool is_green(const Color& c) { return c.g > 0.6f && c.r < 0.45f && c.b < 0.45f; }
bool is_red(const Color& c) { return c.r > 0.6f && c.g < 0.45f && c.b < 0.45f; }
bool is_blue(const Color& c) { return c.b > 0.6f && c.r < 0.45f && c.g < 0.45f; }

}  // namespace

TEST_CASE("rich text: tags are not characters, and a colour or [b] change nothing about where the line wraps") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    RichStyleGuard style(g.renderer);
    const Vec2 plain = g.renderer.measure_text("aaa bbb ccc", 20);
    const Vec2 coloured = g.renderer.measure_text("[c:good]aaa[/c] [c:bad]bbb[/c] ccc", 20, "", 0, RenderSpace::World, kMarkup);
    CHECK(coloured.x == doctest::Approx(plain.x).epsilon(kLineEps));
    CHECK(coloured.y == doctest::Approx(plain.y).epsilon(kLineEps));
    // wrapped: the same breaks as the plain text
    for (float maxW : {60.0f, 80.0f, 100.0f, 400.0f}) {
        INFO("maxWidth " << maxW);
        const Vec2 a = g.renderer.measure_text("aaa bbb ccc", 20, "", maxW);
        const Vec2 b = g.renderer.measure_text("[c:good]aaa[/c] [c:bad]bbb[/c] ccc", 20, "", maxW, RenderSpace::World, kMarkup);
        CHECK(b.x == doctest::Approx(a.x).epsilon(kLineEps));
        CHECK(b.y == doctest::Approx(a.y).epsilon(kLineEps));
    }
}

TEST_CASE("rich text: an icon is as tall as the line, as wide as its proportions, and wraps like a word") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    RichStyleGuard style(g.renderer);
    const float lineH = line_height(g.renderer, 20);
    const auto measure = [&](const std::string& s, float maxW = 0) {
        return g.renderer.measure_text(s, 20, "", maxW, RenderSpace::World, kMarkup);
    };
    CHECK(measure("[icon:fish]").x == doctest::Approx(lineH));  // 1:1
    CHECK(measure("[icon:fish]").y == doctest::Approx(lineH));
    CHECK(measure("[icon:wide]").x == doctest::Approx(lineH * 2));  // 2:1
    const float ab = g.renderer.measure_text("ab", 20).x, cd = g.renderer.measure_text("cd", 20).x;
    const float space = g.renderer.measure_text("a b", 20).x - g.renderer.measure_text("ab", 20).x;
    const float one = ab + space + lineH + space + cd;
    CHECK(measure("ab [icon:fish] cd").x == doctest::Approx(one).epsilon(kLineEps));
    CHECK(measure("ab [icon:fish] cd").y == doctest::Approx(lineH));
    // one pixel too narrow: the line breaks before the last word, the icon stays with the first
    const Vec2 narrower = measure("ab [icon:fish] cd", one - 1);
    CHECK(narrower.y == doctest::Approx(lineH * 2));
    CHECK(narrower.x == doctest::Approx(ab + space + lineH).epsilon(kLineEps));
    // an icon glued to the word before it does not break from it: "9[icon:fish]" moves as one
    const float glued = g.renderer.measure_text("9", 20).x + lineH;
    CHECK(measure("ab 9[icon:fish]", glued + 1).y == doctest::Approx(lineH * 2));
    CHECK(measure("ab 9[icon:fish]", glued + 1).x == doctest::Approx(glued).epsilon(kLineEps));
    // an icon the project does not define takes a square box and still shows the sentence around it
    CHECK(measure("[icon:nope]").x == doctest::Approx(lineH));
    CHECK(measure("a[icon:nope]b").x == doctest::Approx(g.renderer.measure_text("ab", 20).x + lineH).epsilon(kLineEps));
}

TEST_CASE("rich text: Japanese with colour tags wraps between characters exactly like the plain text") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    RichStyleGuard style(g.renderer);
    const std::filesystem::path to = g.projectDir / "assets" / "fonts";
    std::filesystem::create_directories(to);
    std::filesystem::copy_file(std::filesystem::path(FA_RENDER_DATA_DIR) / "fonts" / "NotoSansJP-Regular-subset.ttf",
                               to / "NotoSansJP-Regular-subset.ttf", std::filesystem::copy_options::overwrite_existing);
    g.renderer.set_fallback_fonts({"assets/fonts/NotoSansJP-Regular-subset.ttf"});
    const std::string jp = "日本語の長い文章はスペースがなくても折り返されます。";
    const std::string marked = "[c:good]日本語[/c]の長い[c:bad]文章はスペース[/c]がなくても折り返されます。";
    for (float maxW : {0.0f, 90.0f, 140.0f, 200.0f}) {
        INFO("maxWidth " << maxW);
        const Vec2 a = g.renderer.measure_text(jp, 20, "", maxW);
        const Vec2 b = g.renderer.measure_text(marked, 20, "", maxW, RenderSpace::World, kMarkup);
        CHECK(b.x == doctest::Approx(a.x).epsilon(kLineEps));
        CHECK(b.y == doctest::Approx(a.y).epsilon(kLineEps));
        if (maxW > 0) CHECK(b.y > line_height(g.renderer, 20) * 1.5f);  // it really wrapped
    }
    // an icon between two ideographs may break on either side
    const float lineH = line_height(g.renderer, 20);
    const Vec2 withIcon = g.renderer.measure_text("日本[icon:fish]語", 20, "", 0, RenderSpace::World, kMarkup);
    CHECK(withIcon.x == doctest::Approx(g.renderer.measure_text("日本語", 20).x + lineH).epsilon(kLineEps));
}

TEST_CASE("rich text: [b] and Text.bold embolden the regular glyphs when the project has no bold face") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    RichStyleGuard style(g.renderer);
    const float regular = g.renderer.measure_text("Hello", 24).x;
    const float bold = g.renderer.measure_text("Hello", 24, "", 0, RenderSpace::World, kBold).x;
    CHECK(bold > regular);
    CHECK(bold < regular * 1.2f);
    // [b]..[/b] around the whole text is the bold flag
    CHECK(g.renderer.measure_text("[b]Hello[/b]", 24, "", 0, RenderSpace::World, kMarkup).x == doctest::Approx(bold).epsilon(kLineEps));
    // only the bold word is wider
    const float mixed = g.renderer.measure_text("Hello [b]Hello[/b]", 24, "", 0, RenderSpace::World, kMarkup).x;
    const float twoRegular = g.renderer.measure_text("Hello Hello", 24).x;
    CHECK(mixed > twoRegular);
    CHECK(mixed == doctest::Approx(twoRegular + (bold - regular)).epsilon(kLineEps));
    // the line height does not change
    CHECK(g.renderer.measure_text("Hello", 24, "", 0, RenderSpace::World, kBold).y == doctest::Approx(g.renderer.measure_text("Hello", 24).y));
    // drawn: bold ink is a little wider and has more lit pixels than the regular
    const auto lit = [&](bool boldText) {
        World w; add_camera(w);
        Entity e = make(w, "t", {-120, 70, 0});
        Text& t = w.add<Text>(e);
        t.text = "Hill";
        t.fontSize = 36;
        t.bold = boldText;
        t.pivot = {0, 1};
        const Image img = g.render(w);
        float sum = 0;
        for (int y = 0; y < img.height; ++y)
            for (int x = 0; x < img.width; ++x) sum += img.pixel(x, y).r;
        return sum;
    };
    CHECK(lit(true) > lit(false) * 1.08f);
}

TEST_CASE("rich text: the project's bold face draws [b] and Text.bold, a glyph it lacks falls back to the regular face") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    RichTextStyle s = test_style();
    s.boldFonts[""] = "builtin:pixel";  // the pixel font is monospaced at 1 em: a clearly different face
    RichStyleGuard style(g.renderer, s);
    const float pixelAb = g.renderer.measure_text("ab", 20, "builtin:pixel").x;
    const float regularAb = g.renderer.measure_text("ab", 20).x;
    REQUIRE(std::fabs(pixelAb - regularAb) > 2.0f);
    CHECK(g.renderer.measure_text("[b]ab[/b]", 20, "", 0, RenderSpace::World, kMarkup).x == doctest::Approx(pixelAb).epsilon(kLineEps));
    CHECK(g.renderer.measure_text("ab", 20, "", 0, RenderSpace::World, kBold).x == doctest::Approx(pixelAb).epsilon(kLineEps));
    CHECK(g.renderer.measure_text("ab [b]ab[/b]", 20, "", 0, RenderSpace::World, kMarkup).x ==
          doctest::Approx(regularAb + g.renderer.measure_text("a b", 20).x - g.renderer.measure_text("ab", 20).x + pixelAb).epsilon(kLineEps));
    // a font the section does not name keeps the engine's emboldening
    const float other = g.renderer.measure_text("ab", 20, "builtin:pixel").x;
    CHECK(g.renderer.measure_text("ab", 20, "builtin:pixel", 0, RenderSpace::World, kBold).x > other);
}

TEST_CASE("rich text: unknown tags, a lone '[' and '[[' show as written and never hide the sentence") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    RichStyleGuard style(g.renderer);
    const auto markup = [&](const std::string& s) { return g.renderer.measure_text(s, 20, "", 0, RenderSpace::World, kMarkup).x; };
    const auto plain = [&](const std::string& s) { return g.renderer.measure_text(s, 20).x; };
    CHECK(markup("a [x] b") == doctest::Approx(plain("a [x] b")).epsilon(kLineEps));
    CHECK(markup("a [ b") == doctest::Approx(plain("a [ b")).epsilon(kLineEps));
    CHECK(markup("a [[ b") == doctest::Approx(plain("a [ b")).epsilon(kLineEps));
    CHECK(markup("a [/b] b") == doctest::Approx(plain("a  b")).epsilon(kLineEps));  // a stray closing tag is dropped
    CHECK(markup("a [c:nope]b[/c]") == doctest::Approx(plain("a b")).epsilon(kLineEps));  // an unknown colour keeps the text's own
    // a literal U+FFFC in the source is not mistaken for an icon
    CHECK(markup("a\xEF\xBF\xBC" "b") == doctest::Approx(plain("a\xEF\xBF\xBD" "b")).epsilon(kLineEps));
    // Text.markup off: the tags are text
    CHECK(plain("[b]x[/b]") > plain("x") * 3);
}

TEST_CASE("rich text: two colours, a bold word and an icon draw their colours, and the glyphs of a line are one batch") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    RichStyleGuard style(g.renderer);
    const auto draw = [&](const std::string& text, bool markup, Image* out = nullptr) {
        World w; add_camera(w);
        if (markup) {
            put_markup(w, text, {-150, 70, 0}, 28);
        } else {
            Entity e = make(w, "t", {-150, 70, 0});
            Text& t = w.add<Text>(e);
            t.text = text;
            t.fontSize = 28;
            t.pivot = {0, 1};
        }
        Image img = g.render(w);
        if (out) *out = std::move(img);
        return g.renderer.stats().drawCalls;
    };
    // glyphs only: any number of colours and weights is the draw call of one colour of plain text
    const int plainCalls = draw("Sold 3 fish", false);
    Image glyphsOnly;
    CHECK(draw("[c:good]Sold[/c] [b]3[/b] [c:bad]fish[/c]", true, &glyphsOnly) == plainCalls);
    CHECK(box_of(glyphsOnly, is_green).any());
    CHECK(box_of(glyphsOnly, is_red).any());
    // the colours are where the words are: green is left of red
    CHECK(box_of(glyphsOnly, is_green).x1 < box_of(glyphsOnly, is_red).x0);
    // an icon adds one batch for its texture (it cannot share the glyph atlas), however many icons the line has
    Image withIcons;
    const int oneIcon = draw("[c:good]Sold[/c] [b]3[/b] [icon:fish] [c:bad]fish[/c]", true, &withIcons);
    CHECK(oneIcon == plainCalls + 1);
    CHECK(draw("[icon:fish][icon:fish] [icon:wide] a [icon:fish]", true) == plainCalls + 1);
    // the icon is the red square of the texture, as tall as the line
    const float lineH = line_height(g.renderer, 28);
    World w; add_camera(w);
    put_markup(w, "[icon:fish]", {-150, 70, 0}, 28);
    const Image iconImg = g.render(w);
    const Box red = box_of(iconImg, is_red);
    REQUIRE(red.any());
    CHECK(std::fabs(float(red.h()) - lineH) <= 1.5f);
    CHECK(std::fabs(float(red.w()) - lineH) <= 1.5f);
    CHECK(red.y0 == doctest::Approx(20).epsilon(0.1));  // the top of the line
    // the wide icon keeps its 2:1 proportions
    World w2; add_camera(w2);
    put_markup(w2, "[icon:wide]", {-150, 70, 0}, 28);
    const Box blue = box_of(g.render(w2), is_blue);
    REQUIRE(blue.any());
    CHECK(std::fabs(float(blue.w()) - 2 * lineH) <= 2.0f);
    CHECK(std::fabs(float(blue.h()) - lineH) <= 1.5f);
}

TEST_CASE("rich text: the alpha of the Text fades runs and icons, and a run colour does not hide the Text's alpha") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    RichStyleGuard style(g.renderer);
    World w; add_camera(w);
    Entity e = put_markup(w, "[icon:fish]", {-150, 70, 0}, 28);
    w.get<Text>(e)->color.a = 0.5f;
    const Image img = g.render(w);
    const Box any = box_of(img, [](const Color& c) { return c.r > 0.3f; });
    REQUIRE(any.any());
    const Color px = img.pixel((any.x0 + any.x1) / 2, (any.y0 + any.y1) / 2);
    CHECK(px.r == doctest::Approx(0.5f).epsilon(0.1));  // red at half alpha over black
}

TEST_CASE("rich text: a Button label takes markup and the button measures what it draws") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    RichStyleGuard style(g.renderer);
    World w; add_camera(w);
    Entity e = make(w, "play", {20, 20, 0});
    Button& b = w.add<Button>(e);
    b.size = {200, 50};
    b.pivot = {0, 1};
    b.color = Color{0, 0, 0, 0};
    b.text = "[c:good]Go[/c] [icon:fish]";
    b.fontSize = 24;
    b.markup = true;
    const Image img = g.render(w);
    const Box green = box_of(img, is_green), red = box_of(img, is_red);
    REQUIRE(green.any());
    REQUIRE(red.any());
    CHECK(green.x1 < red.x0);
    // centred in the button as a whole: the label spans from the first letter to the icon
    CHECK(std::abs((green.x0 + red.x1) / 2 - 120) < 6);
    // the same label with markup off shows the tags
    b.markup = false;
    const Box tags = box_of(g.render(w), [](const Color& c) { return c.r > 0.35f; });
    CHECK(tags.w() > (red.x1 - green.x0) + 40);
}

TEST_CASE("rich text: set_rich_text_style changes the next layout of a Text already on screen") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    RichStyleGuard style(g.renderer, RichTextStyle{});
    World w; add_camera(w);
    put_markup(w, "[c:good]Hi[/c]", {-150, 70, 0}, 28);
    // "good" is not declared: the colour tag still names no built-in colour, so the text keeps its own white
    Image before = g.render(w);
    CHECK_FALSE(box_of(before, is_green).any());
    g.renderer.set_rich_text_style(test_style());
    CHECK(box_of(g.render(w), is_green).any());
}

TEST_CASE("rich text: headless measurement skips the tags and counts an icon as two characters") {
    const float size = 20;
    const Vec2 visible = approx_text_size("Sold 3 ii fish", size, 0);
    const Vec2 marked = approx_text_size("[c:good]Sold[/c] [b]3[/b] [icon:fish] [c:bad]fish[/c]", size, 0, true);
    CHECK(marked.x == doctest::Approx(visible.x));
    CHECK(marked.y == doctest::Approx(visible.y));
    // wrapped: the same lines as the visible characters
    CHECK(approx_text_size("[c:good]aaaa[/c] bbbb", size, 60, true).y == approx_text_size("aaaa bbbb", size, 60).y);
    // a literal [[ is one character
    CHECK(approx_text_size("a[[b", size, 0, true).x == doctest::Approx(approx_text_size("a[b", size, 0).x));
    // Text.markup off: the tags are characters
    Text t;
    t.text = "[b]x[/b]";
    t.fontSize = size;
    const Vec2 off = approx_text_size(t, 1.0f);
    t.markup = true;
    CHECK(approx_text_size(t, 1.0f).x < off.x);
}
