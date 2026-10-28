#include "fa/scene/rich_text.h"

#include <algorithm>
#include <cctype>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/core/utf8.h"

namespace fa {

namespace {

std::string utf8_of(std::u32string_view s) {
    std::string out;
    for (char32_t c : s) utf8_append(out, c);
    return out;
}

bool valid_name(std::string_view s) {
    if (s.empty()) return false;
    for (char c : s)
        if (!(std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '-' || c == '.')) return false;
    return true;
}

}  // namespace

bool rich_color(const RichTextStyle& style, std::string_view name, Color& out) {
    if (const auto it = style.colors.find(std::string(name)); it != style.colors.end()) {
        out = it->second;
        return true;
    }
    return parse_color(name, out);
}

MarkupText parse_markup(std::u32string_view src) {
    MarkupText out;
    out.text.reserve(src.size());
    out.attrs.reserve(src.size());
    int bold = 0, italic = 0;
    std::vector<int> colorStack;  // indices into out.colors + 1 (0 = no colour: a malformed [c:] still nests)
    const auto color_index = [&](const std::string& name) {
        const auto it = std::find(out.colors.begin(), out.colors.end(), name);
        if (it != out.colors.end()) return int(it - out.colors.begin()) + 1;
        out.colors.push_back(name);
        return int(out.colors.size());
    };
    const auto put = [&](char32_t c, int icon = -1) {
        MarkupAttr a;
        a.bold = bold > 0;
        a.italic = italic > 0;
        a.color = colorStack.empty() ? 0 : colorStack.back();
        a.icon = icon;
        out.text.push_back(c);
        out.attrs.push_back(a);
    };
    const auto problem = [&](std::size_t at, std::string message) { out.problems.push_back({at, std::move(message)}); };

    for (std::size_t i = 0; i < src.size(); ++i) {
        const char32_t ch = src[i];
        if (ch == kIconChar) {  // the icon character is the engine's: a literal one in a string is a replacement character
            put(kReplacementChar);
            continue;
        }
        if (ch != U'[') {
            put(ch);
            continue;
        }
        if (i + 1 < src.size() && src[i + 1] == U'[') {
            put(U'[');
            ++i;
            continue;
        }
        const std::size_t end = src.find(U']', i);
        if (end == std::u32string_view::npos) {
            problem(i, "'[' without ']' (write [[ for a literal bracket)");
            put(ch);
            continue;
        }
        const std::string tag = utf8_of(src.substr(i + 1, end - i - 1));
        if (tag == "b") {
            ++bold;
        } else if (tag == "/b") {
            if (bold == 0) problem(i, "[/b] without [b]");
            else --bold;
        } else if (tag == "i") {
            ++italic;
        } else if (tag == "/i") {
            if (italic == 0) problem(i, "[/i] without [i]");
            else --italic;
        } else if (starts_with(tag, "c:")) {
            const std::string name = tag.substr(2);
            if (name.empty()) {
                problem(i, "[c:] needs a colour: [c:good], [c:red] or [c:#ff8800]");
                colorStack.push_back(colorStack.empty() ? 0 : colorStack.back());
            } else {
                colorStack.push_back(color_index(name));
            }
        } else if (tag == "/c") {
            if (colorStack.empty()) problem(i, "[/c] without [c:...]");
            else colorStack.pop_back();
        } else if (starts_with(tag, "icon:")) {
            const std::string name = tag.substr(5);
            if (name.empty()) {
                problem(i, "[icon:] needs a name: [icon:fish]");
            } else {
                auto it = std::find(out.icons.begin(), out.icons.end(), name);
                if (it == out.icons.end()) it = out.icons.insert(out.icons.end(), name);
                put(kIconChar, int(it - out.icons.begin()));
            }
        } else {
            problem(i, "unknown tag [" + tag + "] (tags: [b] [/b], [i] [/i], [c:<colour>] [/c], [icon:<name>], [[ for a literal [)");
            for (std::size_t k = i; k <= end; ++k) put(src[k]);  // shown as written
        }
        i = end;
    }
    if (bold > 0) problem(src.size(), "[b] is never closed (add [/b])");
    if (italic > 0) problem(src.size(), "[i] is never closed (add [/i])");
    if (!colorStack.empty()) problem(src.size(), "[c:...] is never closed (add [/c])");
    return out;
}

namespace {
std::string suggestion(const std::string& s) { return s.empty() ? s : s + " "; }
}  // namespace

std::vector<std::string> markup_problems(std::string_view text, const RichTextStyle* style) {
    const MarkupText m = parse_markup(utf8_decode(text));
    std::vector<std::string> out;
    for (const MarkupProblem& p : m.problems) out.push_back("position " + std::to_string(p.position) + ": " + p.message);
    if (!style) return out;
    std::vector<std::string> colorNames;
    for (const auto& [k, v] : style->colors) colorNames.push_back(k);
    for (const std::string& name : m.colors) {
        Color c;
        if (!rich_color(*style, name, c))
            out.push_back("unknown colour '" + name + "' in [c:" + name + "] (the text keeps its colour). " +
                          suggestion(did_you_mean(name, colorNames)) + "Define it in factoria.json (\"text\": {\"colors\": {...}}) or write #rrggbb.");
    }
    std::vector<std::string> iconNames;
    for (const auto& [k, v] : style->icons) iconNames.push_back(k);
    for (const std::string& name : m.icons)
        if (!style->icons.contains(name))
            out.push_back("unknown icon '" + name + "' in [icon:" + name + "] (it draws as an empty box). " + suggestion(did_you_mean(name, iconNames)) +
                          "Define it in factoria.json (\"text\": {\"icons\": {...}}).");
    return out;
}

std::string markup_plain_text(std::string_view text) {
    const MarkupText m = parse_markup(utf8_decode(text));
    std::string out;
    for (std::size_t i = 0; i < m.text.size(); ++i) {
        if (m.attrs[i].icon >= 0) out += "[" + m.icons[std::size_t(m.attrs[i].icon)] + "]";
        else utf8_append(out, m.text[i]);
    }
    return out;
}

TextSettingsParse parse_text_settings(const Json& section) {
    TextSettingsParse r;
    const auto issue = [&](const std::string& pointer, const std::string& message, const std::string& hint) {
        r.issues.push_back({"/text" + pointer, message, hint});
    };
    if (section.is_null()) return r;
    if (!section.is_object()) {
        issue("", "expected an object like {\"colors\": {...}, \"icons\": {...}, \"fonts\": {...}}, got " + describe_json_value(section),
              "The \"text\" section gives rich text (Text.markup) its colours, icons and bold fonts (docs/TEXT.md).");
        return r;
    }
    static const std::vector<std::string> keys = {"colors", "icons", "fonts"};
    for (auto it = section.begin(); it != section.end(); ++it)
        if (std::find(keys.begin(), keys.end(), it.key()) == keys.end())
            r.warnings.push_back({"/text/" + it.key(), "unknown key \"" + it.key() + "\" in \"text\" (ignored). " + did_you_mean(it.key(), keys),
                                  "Remove it or fix the spelling."});

    const auto read_path = [&](const Json& v, const std::string& pointer, const char* what, std::string& into) {
        if (!v.is_string() || v.get<std::string>().empty()) {
            issue(pointer, std::string("expected the path of ") + what + ", got " + describe_json_value(v),
                  "A project-relative path with forward slashes, such as \"assets/atlas.png\".");
            return false;
        }
        const std::string raw = v.get<std::string>();
        const std::string path = fs::is_absolute(raw) ? std::string() : fs::normalize(raw);
        if (path.empty()) {
            issue(pointer, "\"" + raw + "\" is not a path inside the project", "Copy the file into the project and write its project-relative path.");
            return false;
        }
        into = path;
        return true;
    };

    if (auto it = section.find("colors"); it != section.end() && !it->is_null()) {
        if (!it->is_object()) {
            issue("/colors", "expected an object of colour names, got " + describe_json_value(*it),
                  "{\"good\": \"#80dc80\", \"bad\": [1, 0.48, 0.42, 1]}; then write [c:good] in a text.");
        } else {
            for (auto c = it->begin(); c != it->end(); ++c) {
                const std::string where = "/colors/" + c.key();
                if (!valid_name(c.key())) {
                    issue(where, "\"" + c.key() + "\" is not a colour name", "Use letters, digits, '_', '-' and '.' (no spaces, ':' or ']').");
                    continue;
                }
                Color col;
                std::string err;
                if (!json_to(*c, col, &err)) {
                    issue(where, "expected a colour such as \"#80dc80\", \"orange\" or [r, g, b, a], got " + describe_json_value(*c), err);
                    continue;
                }
                r.style.colors[c.key()] = col;
            }
        }
    }
    if (auto it = section.find("icons"); it != section.end() && !it->is_null()) {
        if (!it->is_object()) {
            issue("/icons", "expected an object of icons, got " + describe_json_value(*it),
                  "{\"fish\": {\"texture\": \"assets/atlas.png\", \"region\": [0, 0, 32, 32]}}; then write [icon:fish] in a text.");
        } else {
            for (auto c = it->begin(); c != it->end(); ++c) {
                const std::string where = "/icons/" + c.key();
                if (!valid_name(c.key())) {
                    issue(where, "\"" + c.key() + "\" is not an icon name", "Use letters, digits, '_', '-' and '.' (no spaces, ':' or ']').");
                    continue;
                }
                if (!c->is_object()) {
                    issue(where, "expected {\"texture\": ..., \"region\": [x, y, w, h]}, got " + describe_json_value(*c),
                          "The region is in pixels of the texture, from its top-left corner.");
                    continue;
                }
                static const std::vector<std::string> iconKeys = {"texture", "region"};
                for (auto k = c->begin(); k != c->end(); ++k)
                    if (std::find(iconKeys.begin(), iconKeys.end(), k.key()) == iconKeys.end())
                        r.warnings.push_back({"/text" + where + "/" + k.key(),
                                              "unknown key \"" + k.key() + "\" in an icon (ignored). " + did_you_mean(k.key(), iconKeys),
                                              "Remove it or fix the spelling."});
                RichIcon icon;
                bool ok = true;
                if (auto t = c->find("texture"); t != c->end()) {
                    ok = read_path(*t, where + "/texture", "the icon's texture", icon.texture) && ok;
                } else {
                    issue(where, "icon \"" + c.key() + "\" has no \"texture\"", "Add \"texture\": \"assets/atlas.png\" (the image the icon is a part of).");
                    ok = false;
                }
                if (auto g = c->find("region"); g != c->end()) {
                    bool good = g->is_array() && g->size() == 4;
                    for (std::size_t k = 0; good && k < 4; ++k) good = (*g)[k].is_number() && (*g)[k].get<double>() >= (k >= 2 ? 1 : 0);
                    if (!good) {
                        issue(where + "/region",
                              "expected [x, y, width, height] in pixels (width and height at least 1), got " + describe_json_value(*g),
                              "The part of the texture the icon shows, from its top-left corner: [0, 0, 32, 32].");
                        ok = false;
                    } else {
                        icon.x = (*g)[0].get<int>();
                        icon.y = (*g)[1].get<int>();
                        icon.w = (*g)[2].get<int>();
                        icon.h = (*g)[3].get<int>();
                    }
                } else {
                    issue(where, "icon \"" + c.key() + "\" has no \"region\"", "Add \"region\": [x, y, w, h] (pixels of the texture, from its top-left corner).");
                    ok = false;
                }
                if (ok) r.style.icons[c.key()] = icon;
            }
        }
    }
    if (auto it = section.find("fonts"); it != section.end() && !it->is_null()) {
        if (!it->is_object()) {
            issue("/fonts", "expected an object keyed by font, got " + describe_json_value(*it),
                  "{\"assets/fonts/Body-Regular.ttf\": {\"bold\": \"assets/fonts/Body-Bold.ttf\"}}; the key is the font a Text names (\"\" = the built-in font).");
        } else {
            for (auto c = it->begin(); c != it->end(); ++c) {
                const std::string where = "/fonts/" + c.key();
                if (!c->is_object()) {
                    issue(where, "expected {\"bold\": \"<font file>\"}, got " + describe_json_value(*c),
                          "Name the font file that draws [b] text and Text.bold for this font, and/or the one that draws [i] text: "
                          "{\"bold\": \"assets/fonts/Body-Bold.ttf\", \"italic\": \"assets/fonts/Body-Italic.ttf\"}.");
                    continue;
                }
                static const std::vector<std::string> fontKeys = {"bold", "italic"};
                for (auto k = c->begin(); k != c->end(); ++k)
                    if (k.key() != "bold" && k.key() != "italic")
                        r.warnings.push_back({"/text" + where + "/" + k.key(),
                                              "unknown key \"" + k.key() + "\" in a font entry (ignored). " + did_you_mean(k.key(), fontKeys),
                                              "Only \"bold\" and \"italic\" are read."});
                if (c->find("bold") == c->end() && c->find("italic") == c->end()) {
                    issue(where, "font entry has neither \"bold\" nor \"italic\"",
                          "Add \"bold\": \"assets/fonts/Body-Bold.ttf\" and/or \"italic\": \"assets/fonts/Body-Italic.ttf\".");
                    continue;
                }
                std::string key = c.key();
                if (!key.empty() && key != "builtin" && key.rfind("builtin:", 0) != 0) key = fs::normalize(key);
                for (const char* which : {"bold", "italic"}) {
                    const auto v = c->find(which);
                    if (v == c->end()) continue;
                    std::string file;
                    if (read_path(*v, where + "/" + which, which[0] == 'b' ? "the bold font" : "the italic font", file))
                        (std::string_view(which) == "bold" ? r.style.boldFonts : r.style.italicFonts)[key] = file;
                }
            }
        }
    }
    return r;
}

}  // namespace fa
