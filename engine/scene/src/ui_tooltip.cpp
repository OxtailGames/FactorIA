#include "fa/scene/ui_tooltip.h"

#include <cmath>
#include <optional>
#include <vector>

#include "fa/core/strings.h"

namespace fa {

namespace {

Error bad(const std::string& at, const std::string& pointer, const std::string& expected, const Json& got, const std::string& hint) {
    return make_error(at + pointer + ": expected " + expected + ", got " + describe_json_value(got), hint);
}

}  // namespace

Result<UiTooltipSettings> parse_tooltip_settings(const Json& ui, const std::string& at) {
    UiTooltipSettings s;
    if (!ui.is_object()) return s;
    if (auto it = ui.find("tooltipDelay"); it != ui.end() && !it->is_null()) {
        if (!it->is_number() || !(it->get<double>() >= 0.0) || it->get<double>() > 60.0)
            return bad(at, "/tooltipDelay", "a number of seconds from 0 to 60", *it,
                       "How long the pointer rests on a widget before its tooltip shows (default 0.5); 0 shows it at once. Scripts change it with ui.tooltipDelay.");
        s.delay = float(it->get<double>());
    }
    if (auto it = ui.find("tooltipOnTouch"); it != ui.end() && !it->is_null()) {
        if (!it->is_boolean())
            return bad(at, "/tooltipOnTouch", "true or false", *it,
                       "false (default): tooltips stay off while the last input was a touch (a finger has no hover). true: they show there too.");
        s.onTouch = it->get<bool>();
    }
    auto it = ui.find("tooltip");
    if (it == ui.end() || it->is_null()) return s;
    const std::string base = "/tooltip";
    if (!it->is_object())
        return bad(at, base, "an object like {\"color\": \"#10141c\", \"fontSize\": 18}", *it,
                   "The look of every tooltip: color, textColor, titleColor, texture, slice, font, fontSize, titleSize, maxWidth, spacing, padding, gap, layer.");
    static const char* kKeys[] = {"color", "textColor", "titleColor", "texture", "slice", "font", "fontSize", "titleSize",
                                  "maxWidth", "spacing", "padding", "gap", "layer"};
    for (const auto& [key, value] : it->items()) {
        bool known = false;
        for (const char* k : kKeys) known = known || key == k;
        if (!known) {
            std::vector<std::string> names(std::begin(kKeys), std::end(kKeys));
            return make_error(at + base + "/" + key + ": unknown tooltip setting. " + did_you_mean(key, names),
                              "The settings are: color, textColor, titleColor, texture, slice, font, fontSize, titleSize, maxWidth, spacing, padding, gap, layer.");
        }
    }
    UiTooltipStyle& st = s.style;
    std::string err;
    auto color = [&](const char* key, Color& out) -> std::optional<Error> {
        auto f = it->find(key);
        if (f == it->end() || f->is_null()) return std::nullopt;
        if (!json_to(*f, out, &err)) return bad(at, base + "/" + key, "a colour [r,g,b,a], \"#rrggbb\" or a name", *f, err);
        return std::nullopt;
    };
    auto number = [&](const char* key, float& out, double lo, double hi) -> std::optional<Error> {
        auto f = it->find(key);
        if (f == it->end() || f->is_null()) return std::nullopt;
        if (!f->is_number() || !(f->get<double>() >= lo) || f->get<double>() > hi)
            return bad(at, base + "/" + key, "a number from " + std::to_string(int(lo)) + " to " + std::to_string(int(hi)), *f,
                       "Sizes are in UI units (design pixels before ui.scale).");
        out = float(f->get<double>());
        return std::nullopt;
    };
    auto text = [&](const char* key, std::string& out) -> std::optional<Error> {
        auto f = it->find(key);
        if (f == it->end() || f->is_null()) return std::nullopt;
        if (!f->is_string()) return bad(at, base + "/" + key, "a project path string", *f, "For example \"assets/ui/tooltip.png\".");
        out = f->get<std::string>();
        return std::nullopt;
    };
    auto vec4 = [&](const char* key, Vec4& out) -> std::optional<Error> {
        auto f = it->find(key);
        if (f == it->end() || f->is_null()) return std::nullopt;
        if (!json_to(*f, out, &err)) return bad(at, base + "/" + key, "four numbers [left, top, right, bottom]", *f, err);
        return std::nullopt;
    };
    for (const std::optional<Error>& e :
         {color("color", st.color), color("textColor", st.textColor), color("titleColor", st.titleColor), text("texture", st.texture),
          vec4("slice", st.slice), text("font", st.font), number("fontSize", st.fontSize, 1, 512), number("titleSize", st.titleSize, 1, 512),
          number("maxWidth", st.maxWidth, 20, 4096), number("spacing", st.spacing, 0, 256), vec4("padding", st.padding),
          number("gap", st.gap, 0, 512)})
        if (e) return *e;
    if (auto f = it->find("layer"); f != it->end() && !f->is_null()) {
        if (!f->is_number_integer()) return bad(at, base + "/layer", "a whole number", *f, "The draw order among UI widgets; the default 1000 is above every widget.");
        st.layer = f->get<int>();
    }
    return s;
}

Json ui_tooltip_json(const UiTooltipView& v, float k) {
    if (!v.shown) return nullptr;
    std::string title;
    Json lines = Json::array();
    for (const UiTooltipLine& l : v.lines) {
        if (l.title) title = l.text;
        else lines.push_back(l.text);
    }
    return Json::object({{"title", title},
                         {"lines", std::move(lines)},
                         {"rect", Json::array({v.rect.x * k, v.rect.y * k, v.rect.w * k, v.rect.h * k})},
                         {"source", v.source},
                         {"widget", v.widget.empty() ? Json(nullptr) : Json(v.widget)}});
}

}  // namespace fa
