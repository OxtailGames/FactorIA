// Tooltips, the data part: the style and timing a project sets ("ui" section of factoria.json), and the tooltip that is on
// screen right now. fa_ui (tooltip.cpp) decides what shows, when and where, and writes it here; fa_render draws it (ui2d.cpp);
// scripts read it (ui.tooltip) and tests check it (ui.state). It lives in the World, like ui_scale(): it is a setting and a
// piece of UI state, not an entity, so a tooltip adds nothing to a scene's entity count or draw order. docs/MENUS.md, "Tooltips".
#pragma once

#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"

namespace fa {

// How a tooltip looks: factoria.json "ui": {"tooltip": {...}} is the theme of the whole game. Sizes are UI units (ui_rect.h),
// like every widget's: ui.scale and ui.textScale apply to them.
struct UiTooltipStyle {
    Color color{0.03f, 0.04f, 0.07f, 0.96f};     // background, multiplied with `texture` when there is one
    Color textColor{0.92f, 0.94f, 0.98f, 1.0f};  // body lines without a colour of their own
    Color titleColor{1.0f, 0.82f, 0.3f, 1.0f};   // the title line
    std::string texture;                         // optional 9-slice background (project path)
    Vec4 slice{0, 0, 0, 0};                      // its borders [left, top, right, bottom] in texture pixels
    std::string font;                            // project path of a .ttf, "" = the built-in font
    float fontSize = 18.0f;                      // body lines
    float titleSize = 20.0f;                     // the title
    float maxWidth = 300.0f;                     // a longer line wraps at this width (the box is this wide plus the padding)
    float spacing = 3.0f;                        // between lines
    Vec4 padding{10, 8, 10, 8};                  // left, top, right, bottom
    float gap = 16.0f;                           // from the pointer to the box
    std::int32_t layer = 1000;                   // draw order among the UI; above every widget by default
    bool operator==(const UiTooltipStyle&) const = default;
};

struct UiTooltipSettings {
    float delay = 0.5f;       // seconds of rest before a widget's tooltip shows (ui.tooltipDelay)
    bool onTouch = false;     // true: tooltips also show while the last input was a touch (otherwise they stay off)
    UiTooltipStyle style;
    bool operator==(const UiTooltipSettings&) const = default;
};

// Reads the "ui" object of factoria.json (only the tooltip keys: tooltipDelay, tooltipOnTouch, tooltip). Errors name the pointer
// under `at` (e.g. "factoria.json /ui/tooltip/fontSize"), what is wrong and what to write.
Result<UiTooltipSettings> parse_tooltip_settings(const Json& ui, const std::string& at);

// A line of the tooltip that is on screen, with the place it is drawn at.
struct UiTooltipLine {
    std::string text;
    Color color;           // the colour it is drawn in
    Vec2 pos{};            // top-left corner on the screen, UI units
    float fontSize = 18.0f;
    bool title = false;
};

// The tooltip on screen (shown false: none). Everything is in UI units; multiply by the interface scale for pixels.
struct UiTooltipView {
    bool shown = false;
    Rect rect;                     // the box, UI units
    std::vector<UiTooltipLine> lines;
    std::string source;            // "widget" (a tooltip set on the widget), "script" (a function from ui.setTooltip), "world" (ui.setWorldTooltip) or "manual" (ui.showTooltip)
    std::string widget;            // the id of the widget that owns it ("" for world and script tooltips)
};

// The view as scripts and tests read it (ui.tooltip, "tooltip" of ui.state): null when none shows, else {title, lines: [text],
// rect: [x, y, w, h] in screen pixels (`k` = the interface scale), source, widget}.
Json ui_tooltip_json(const UiTooltipView& view, float k);

}  // namespace fa
