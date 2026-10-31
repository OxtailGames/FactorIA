// fa/scene/rich_text.h: the markup parser every text layout, measurement and `factoria validate` reads, and the project's
// "text" section.
#include <doctest.h>

#include <string>

#include "fa/core/utf8.h"
#include "fa/scene/rich_text.h"

using namespace fa;

namespace {

MarkupText parse(const std::string& s) { return parse_markup(utf8_decode(s)); }
std::string visible(const MarkupText& m) {
    std::string out;
    for (char32_t c : m.text) utf8_append(out, c);
    return out;
}

}  // namespace

TEST_CASE("markup: tags set the weight, the colour and the icons of the characters, and take no room") {
    const MarkupText m = parse("a[b]b[/b][c:good]c[c:bad]d[/c]e[/c]f[icon:fish]g");
    CHECK(m.problems.empty());
    REQUIRE(m.text.size() == 8);
    CHECK(m.text.substr(0, 6) == U"abcdef");
    CHECK(m.text[6] == kIconChar);
    CHECK(m.text[7] == U'g');
    CHECK(m.colors == std::vector<std::string>{"good", "bad"});
    CHECK(m.icons == std::vector<std::string>{"fish"});
    // weights
    CHECK_FALSE(m.attrs[0].bold);
    CHECK(m.attrs[1].bold);
    CHECK_FALSE(m.attrs[2].bold);
    // colours nest: [/c] restores the outer colour
    CHECK(m.attrs[0].color == 0);
    CHECK(m.attrs[2].color == 1);  // good
    CHECK(m.attrs[3].color == 2);  // bad
    CHECK(m.attrs[4].color == 1);  // good again
    CHECK(m.attrs[5].color == 0);
    CHECK(m.attrs[6].icon == 0);
    CHECK(m.attrs[7].icon == -1);
}

TEST_CASE("markup: a mistake never hides the sentence, and is reported with where it is") {
    // an unknown tag and a lone '[' show as written
    MarkupText unknown = parse("see [x] here");
    CHECK(visible(unknown) == "see [x] here");
    REQUIRE(unknown.problems.size() == 1);
    CHECK(unknown.problems[0].position == 4);
    CHECK(unknown.problems[0].message.find("unknown tag [x]") != std::string::npos);
    CHECK(visible(parse("a [ b")) == "a [ b");
    CHECK(parse("a [ b").problems.size() == 1);
    // '[[' is a literal bracket and no problem
    const MarkupText literal = parse("a [[b]] c");
    CHECK(visible(literal) == "a [b]] c");
    CHECK(literal.problems.empty());
    // a stray closing tag is dropped; unclosed tags are told
    CHECK(visible(parse("a[/b]b")) == "ab");
    CHECK(parse("a[/b]b").problems.size() == 1);
    CHECK(parse("a[/c]b").problems.size() == 1);
    CHECK(parse("[b]a").problems.size() == 1);
    CHECK(parse("[c:red]a").problems.size() == 1);
    CHECK_FALSE(parse("[c:]a").problems.empty());
    CHECK_FALSE(parse("[icon:]a").problems.empty());
    // the icon character is the engine's: a literal one is replaced
    const MarkupText fffc = parse("a\xEF\xBF\xBC" "b");
    CHECK(fffc.text[1] == kReplacementChar);
    CHECK(fffc.attrs[1].icon == -1);
}

TEST_CASE("markup: markup_problems checks the colours and icons against the project's style, with a suggestion") {
    // without a style only the syntax is checked
    CHECK(markup_problems("[b]x[/b] [c:red]y[/c] [c:#ff8800]z[/c] [icon:fish] [c:nope]w[/c]").empty());
    RichTextStyle style;
    style.colors["good"] = Color{0, 1, 0, 1};
    style.icons["fish"] = {"assets/atlas.png", 0, 0, 16, 16};
    CHECK(markup_problems("[c:good]x[/c] [c:red]y[/c] [icon:fish]", &style).empty());
    const auto bad = markup_problems("[c:gode]x[/c] [icon:fsh]", &style);
    REQUIRE(bad.size() == 2);
    CHECK(bad[0].find("unknown colour 'gode'") != std::string::npos);
    CHECK(bad[0].find("good") != std::string::npos);  // did you mean
    CHECK(bad[1].find("unknown icon 'fsh'") != std::string::npos);
    CHECK(bad[1].find("fish") != std::string::npos);
}

TEST_CASE("markup: markup_plain_text is what a log or a test compares") {
    CHECK(markup_plain_text("[c:good]Sold[/c] [b]3[/b] [icon:fish] [[x]") == "Sold 3 [fish] [x]");
    CHECK(markup_plain_text("plain") == "plain");
}

TEST_CASE("text settings: colours, icons and bold fonts of the project, every mistake with its pointer") {
    const auto parse_section = [](const char* json) {
        auto j = parse_json(json, "text");
        REQUIRE(j.ok());
        return parse_text_settings(j.value());
    };
    const TextSettingsParse good = parse_section(R"({
        "colors": {"good": "#80dc80", "bad": [1, 0.48, 0.42, 1], "alias": "orange"},
        "icons": {"fish": {"texture": "assets/atlas.png", "region": [0, 32, 24, 24]}},
        "fonts": {"assets/fonts/Body.ttf": {"bold": "assets/fonts/Body-Bold.ttf"}, "": {"bold": "assets/fonts/Ui-Bold.ttf"}}})");
    CHECK(good.ok());
    CHECK(good.warnings.empty());
    CHECK(good.style.colors.size() == 3);
    CHECK(good.style.colors.at("good").g == doctest::Approx(0xdc / 255.0f));
    CHECK(good.style.icons.at("fish") == RichIcon{"assets/atlas.png", 0, 32, 24, 24});
    CHECK(good.style.boldFonts.at("assets/fonts/Body.ttf") == "assets/fonts/Body-Bold.ttf");
    CHECK(good.style.boldFonts.at("") == "assets/fonts/Ui-Bold.ttf");

    CHECK(parse_text_settings(Json()).ok());  // absent = empty
    CHECK(parse_text_settings(Json()).style.empty());

    const TextSettingsParse bad = parse_section(R"({
        "colors": {"good": 12, "bad name": "#fff"},
        "icons": {"fish": {"texture": "assets/atlas.png"}, "coin": {"texture": "assets/atlas.png", "region": [0, 0, 0, 5]}, "gem": 3},
        "fonts": {"a.ttf": {"bold": 7}, "b.ttf": {}},
        "colours": {}})");
    CHECK_FALSE(bad.ok());
    const auto has_pointer = [&](const std::string& p) {
        for (const TextSettingsIssue& i : bad.issues)
            if (i.pointer == p) return true;
        return false;
    };
    CHECK(has_pointer("/text/colors/good"));
    CHECK(has_pointer("/text/colors/bad name"));
    CHECK(has_pointer("/text/icons/fish"));           // no region
    CHECK(has_pointer("/text/icons/coin/region"));    // zero width
    CHECK(has_pointer("/text/icons/gem"));
    CHECK(has_pointer("/text/fonts/a.ttf/bold"));
    CHECK(has_pointer("/text/fonts/b.ttf"));
    for (const TextSettingsIssue& i : bad.issues) {
        CHECK_FALSE(i.message.empty());
        CHECK_FALSE(i.hint.empty());
    }
    // a typo in a key is a warning with a suggestion
    REQUIRE(bad.warnings.size() == 1);
    CHECK(bad.warnings[0].pointer == "/text/colours");
    CHECK(bad.warnings[0].message.find("colors") != std::string::npos);
    // a path outside the project is refused
    CHECK_FALSE(parse_section(R"({"fonts": {"": {"bold": "/etc/x.ttf"}}})").ok());
    CHECK_FALSE(parse_section(R"([1, 2])").ok());
}

TEST_CASE("text settings: rich_color reads the project's names first, then built-in names and hex") {
    RichTextStyle style;
    style.colors["red"] = Color{0.5f, 0, 0, 1};  // the project may redefine a built-in name
    Color c;
    REQUIRE(rich_color(style, "red", c));
    CHECK(c.r == doctest::Approx(0.5f));
    REQUIRE(rich_color(style, "#00ff00", c));
    CHECK(c.g == doctest::Approx(1.0f));
    CHECK_FALSE(rich_color(style, "no-such-colour", c));
}
