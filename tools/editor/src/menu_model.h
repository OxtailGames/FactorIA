// The editor's main menu as plain data, independent of who draws it.
//
// Editor::build_main_menu() builds a tree of Items from the editor's state every frame (labels, enabled and checked
// flags, tooltips, actions). Two renderers show it:
//   - menu_imgui.cpp draws it in the window with Dear ImGui (Windows, Linux, and the autotest everywhere);
//   - native_menu_apple.mm mirrors it into the macOS system menu bar (NSMenu).
// Neither renderer knows the editor: an Item carries what it needs, including the callback that does the work.
#pragma once

#include <functional>
#include <string>
#include <vector>

namespace fa::editor::menu {

// True where the system menu bar and the Cmd key rule (macOS).
inline constexpr bool kApple =
#ifdef __APPLE__
    true;
#else
    false;
#endif

struct Item {
    enum class Kind { Action, Menu, Separator };
    Kind kind = Kind::Action;
    std::string label;
    // Platform-neutral keyboard shortcut shown beside the label, e.g. "Ctrl+S" or "Ctrl+Shift+Z". "Ctrl" is the main
    // modifier: it reads "Cmd" on macOS (shortcut_label) and is the Command key of a native menu item.
    std::string shortcut;
    std::string macShortcut;      // when set, replaces `shortcut` on macOS (Redo is Cmd+Shift+Z there)
    bool enabled = true;
    bool checked = false;         // a check mark before the label
    // True for the shortcuts that must reach a focused text field instead (Save, Undo, Redo): the native menu disables
    // them while a text box has the keyboard, so Cmd+Z undoes the typing and not the scene.
    bool yieldsToText = false;
    std::string tooltip;
    std::function<std::string()> tooltipFn;  // evaluated only when the tooltip is wanted (hover, menu opening); wins over `tooltip`
    std::string atName;           // the autotest's handle for this item (menu:file...); empty = not tracked
    std::function<void()> action; // an Action: what a click does
    std::vector<Item> children;   // a Menu: its items
    // A Menu whose items are built only when it opens (a file listing must not run every frame). Used instead of `children`.
    std::function<std::vector<Item>()> lazyChildren;

    bool is_menu() const { return kind == Kind::Menu; }
    bool is_separator() const { return kind == Kind::Separator; }
    // The items of a Menu right now: `children`, or what `lazyChildren` returns (it runs on every call).
    std::vector<Item> resolved_children() const { return lazyChildren ? lazyChildren() : children; }
    // This item without its children (lazy or not): what a native menu keeps for each node. Copies every field but `children`.
    Item without_children() const;
    std::string tooltip_text() const { return tooltipFn ? tooltipFn() : tooltip; }
    // The shortcut to show / bind on this platform.
    const std::string& shortcut_for(bool apple) const { return apple && !macShortcut.empty() ? macShortcut : shortcut; }
};

Item action(std::string label, std::function<void()> fn, bool enabled = true);
Item separator();
Item submenu(std::string label, std::vector<Item> children, bool enabled = true);
Item lazy_submenu(std::string label, std::function<std::vector<Item>()> make, bool enabled = true);

struct MainMenu {
    // Top level: Menu items, or (Windows/Linux bar only) an Action that is a click item on the bar itself.
    std::vector<Item> items;
    // Windows/Linux bar only: text at the right end of the bar (the engine version) and its tooltip / autotest name.
    std::string trailing, trailingTooltip, trailingAtName;
};

// A shortcut string taken apart. `key` is one lowercase character ("s", ",") or a name ("f5"); empty when not valid.
struct Shortcut {
    bool ctrl = false, shift = false, alt = false;
    std::string key;
    bool valid() const { return !key.empty(); }
};
Shortcut parse_shortcut(const std::string& text);
// What a menu shows for a neutral shortcut: "Ctrl+S" stays on Windows/Linux and reads "Cmd+S" on macOS (Alt is Option).
std::string shortcut_label(const std::string& neutral, bool apple);

// The first item of the tree with the given autotest name, or null (lazy menus are not opened).
const Item* find_by_at_name(const std::vector<Item>& items, const std::string& atName);
// Every autotest name in the tree, in order (lazy menus are not opened).
std::vector<std::string> at_names(const std::vector<Item>& items);

// ---- Dear ImGui renderer (menu_imgui.cpp) -------------------------------------------------------------------------
// Draws the tree as the window's main menu bar: BeginMainMenuBar, one BeginMenu per top-level Menu, a MenuItem per
// Action, the trailing text at the right end. `track(name, enabled)` is called right after each item with an autotest
// name, while it is the last ImGui item (Editor::at_track). Actions run inside the call, as ImGui reports the click.
// Returns false when the bar was not drawn (no room: ImGui hides it).
bool draw_imgui_bar(const MainMenu& menu, const std::function<void(const std::string&, bool)>& track);

}  // namespace fa::editor::menu
