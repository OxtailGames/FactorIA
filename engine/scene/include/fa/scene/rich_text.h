// Rich text: the markup of `Text.markup` (and of the labels of Button, Toggle, Slider and TouchButton) and the project's
// "text" section of factoria.json that gives it colours, icons and bold fonts. The markup parser lives here, below the
// renderer, so that the text layout, the headless measurement (bounds.h) and `factoria validate` read the same string the
// same way.
//
//   [b]bold[/b]          the project's bold face of the font (a font with none is emboldened by the engine)
//   [i]italic[/i]        the italic face of the font (a font with none stays upright)
//   [c:good]green[/c]    a colour: a name of "text.colors", a built-in colour name or #rgb / #rrggbb / #rrggbbaa
//   [icon:fish]          a picture of "text.icons", as tall as the line
//   [[                   a literal [
//
// Tags nest ([c:] inside [c:] restores the outer colour at its [/c]). A mistake never hides the sentence: an unknown tag or a
// '[' without ']' is shown as written, a stray closing tag is ignored, and each is reported by `markup_problems`.
#pragma once

#include <map>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"

namespace fa {

// A picture drawn inline: a rectangle of a project texture, in pixels from its top-left corner.
struct RichIcon {
    std::string texture;
    int x = 0, y = 0, w = 0, h = 0;
    bool operator==(const RichIcon&) const = default;
};

// The "text" section of factoria.json (docs/TEXT.md "Rich text").
struct RichTextStyle {
    std::map<std::string, Color> colors;              // [c:name]
    std::map<std::string, RichIcon> icons;            // [icon:name]
    std::map<std::string, std::string> boldFonts;     // a font as a Text names it ("" = the built-in font) -> its bold face
    std::map<std::string, std::string> italicFonts;   // the same -> its italic face ([i])
    bool empty() const { return colors.empty() && icons.empty() && boldFonts.empty() && italicFonts.empty(); }
    bool operator==(const RichTextStyle&) const = default;
};

// One problem of the "text" section, with the JSON pointer it is at ("/text/icons/fish/region").
struct TextSettingsIssue {
    std::string pointer, message, hint;
};
struct TextSettingsParse {
    RichTextStyle style;
    std::vector<TextSettingsIssue> issues;    // every problem found; `style` is only usable without any
    std::vector<TextSettingsIssue> warnings;  // keys the engine does not know (a typo), with "did you mean"
    bool ok() const { return issues.empty(); }
};
// Reads the value of "text" (null = the section is absent = empty style). Reports every mistake with its pointer, a fix and
// a "did you mean".
TextSettingsParse parse_text_settings(const Json& section);

// The colour a tag names: the project's "text.colors", else a built-in name ("red") or #rgb / #rrggbb / #rrggbbaa. False when
// it is none of these.
bool rich_color(const RichTextStyle& style, std::string_view name, Color& out);

// The character an icon takes in the laid-out text. It does not break from the letters next to it (a number glued to its
// icon stays on one line).
inline constexpr char32_t kIconChar = 0xFFFC;

// Markup read: the visible text and what styles each of its characters.
struct MarkupAttr {
    bool bold = false;
    bool italic = false;
    int color = 0;   // 0 = the Text's colour, k = colors[k - 1] of the MarkupText
    int icon = -1;   // >= 0: this character (kIconChar) is the picture icons[icon]
};
struct MarkupProblem {
    std::size_t position = 0;  // code point index in the source
    std::string message;
};
struct MarkupText {
    std::u32string text;             // without tags; every icon is one kIconChar
    std::vector<MarkupAttr> attrs;   // one per character of `text`
    std::vector<std::string> colors; // the colour names the text uses, in order of appearance (not yet resolved)
    std::vector<std::string> icons;  // the icon names the text uses, in order of appearance
    std::vector<MarkupProblem> problems;
};
// Reads `source` (code points as the text layout decodes them). Never fails.
MarkupText parse_markup(std::u32string_view source);

// The problems of the markup of a UTF-8 `text`: syntax (an unknown tag, a '[' without ']', an unclosed [b] or [c:]) and, with
// a `style`, colours and icons it does not define. Each entry says where and what to do; empty = clean.
std::vector<std::string> markup_problems(std::string_view text, const RichTextStyle* style = nullptr);

// The text without tags, an icon written as "[name]": what a screen reader, a log or a test compares.
std::string markup_plain_text(std::string_view text);

}  // namespace fa
