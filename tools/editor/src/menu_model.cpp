#include "menu_model.h"

#include <algorithm>
#include <cctype>

namespace fa::editor::menu {

Item Item::without_children() const {
    Item c;
    c.kind = kind;
    c.label = label;
    c.shortcut = shortcut;
    c.macShortcut = macShortcut;
    c.enabled = enabled;
    c.checked = checked;
    c.yieldsToText = yieldsToText;
    c.tooltip = tooltip;
    c.tooltipFn = tooltipFn;
    c.atName = atName;
    c.action = action;
    c.lazyChildren = lazyChildren;
    return c;
}

Item action(std::string label, std::function<void()> fn, bool enabled) {
    Item i;
    i.label = std::move(label);
    i.action = std::move(fn);
    i.enabled = enabled;
    return i;
}

Item separator() {
    Item i;
    i.kind = Item::Kind::Separator;
    return i;
}

Item submenu(std::string label, std::vector<Item> children, bool enabled) {
    Item i;
    i.kind = Item::Kind::Menu;
    i.label = std::move(label);
    i.children = std::move(children);
    i.enabled = enabled;
    return i;
}

Item lazy_submenu(std::string label, std::function<std::vector<Item>()> make, bool enabled) {
    Item i;
    i.kind = Item::Kind::Menu;
    i.label = std::move(label);
    i.lazyChildren = std::move(make);
    i.enabled = enabled;
    return i;
}

Shortcut parse_shortcut(const std::string& text) {
    Shortcut s;
    std::size_t start = 0;
    while (start <= text.size()) {
        std::size_t plus = text.find('+', start);
        // A trailing "+" is the key itself ("Ctrl++"): the part after the last separator is empty.
        if (plus == start && start + 1 == text.size()) { s.key = "+"; break; }
        const std::string part = text.substr(start, plus == std::string::npos ? std::string::npos : plus - start);
        std::string low;
        for (char c : part) low += char(std::tolower(static_cast<unsigned char>(c)));
        if (plus == std::string::npos) {
            if (low == "comma") low = ",";
            if (low == "period") low = ".";
            s.key = low;
            break;
        }
        if (low == "ctrl" || low == "cmd" || low == "command" || low == "super") s.ctrl = true;
        else if (low == "shift") s.shift = true;
        else if (low == "alt" || low == "option" || low == "opt") s.alt = true;
        else return Shortcut{};  // an unknown modifier: not a shortcut
        start = plus + 1;
    }
    return s;
}

std::string shortcut_label(const std::string& neutral, bool apple) {
    if (!apple || neutral.empty()) return neutral;
    std::string out;
    std::size_t start = 0;
    while (start <= neutral.size()) {
        const std::size_t plus = neutral.find('+', start);
        const std::string part = neutral.substr(start, plus == std::string::npos ? std::string::npos : plus - start);
        if (!out.empty()) out += '+';
        out += part == "Ctrl" ? "Cmd" : part == "Alt" ? "Option" : part;
        if (plus == std::string::npos) break;
        start = plus + 1;
    }
    return out;
}

const Item* find_by_at_name(const std::vector<Item>& items, const std::string& atName) {
    for (const Item& i : items) {
        if (i.atName == atName) return &i;
        if (const Item* c = find_by_at_name(i.children, atName)) return c;
    }
    return nullptr;
}

namespace {
void collect_at_names(const std::vector<Item>& items, std::vector<std::string>& out) {
    for (const Item& i : items) {
        if (!i.atName.empty()) out.push_back(i.atName);
        collect_at_names(i.children, out);
    }
}
}  // namespace

std::vector<std::string> at_names(const std::vector<Item>& items) {
    std::vector<std::string> out;
    collect_at_names(items, out);
    return out;
}

}  // namespace fa::editor::menu
