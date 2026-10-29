// The editor's main menu: the platform-neutral model (menu_model.h), the tree the editor builds (Editor::build_main_menu) and, on
// macOS, the NSMenu mirror (native_menu.h).
#include <algorithm>
#include <set>

#include "doctest.h"
#include "editor_internal.h"
#include "menu_model.h"
#include "native_menu.h"

using namespace fa;
using namespace fa::editor;

namespace {
const menu::Item* top(const menu::MainMenu& m, const std::string& label) {
    for (const menu::Item& i : m.items)
        if (i.label == label) return &i;
    return nullptr;
}
const menu::Item* child(const menu::Item& parent, const std::string& label) {
    for (const menu::Item& i : parent.children)
        if (i.label == label) return &i;
    return nullptr;
}
}  // namespace

TEST_CASE("menu: shortcuts read Ctrl on Windows and Linux and Cmd on macOS") {
    CHECK(menu::shortcut_label("Ctrl+S", false) == "Ctrl+S");
    CHECK(menu::shortcut_label("Ctrl+S", true) == "Cmd+S");
    CHECK(menu::shortcut_label("Ctrl+Shift+Z", true) == "Cmd+Shift+Z");
    CHECK(menu::shortcut_label("Ctrl+Alt+K", true) == "Cmd+Option+K");
    CHECK(menu::shortcut_label("", true).empty());

    menu::Item redo = menu::action("Redo", nullptr);
    redo.shortcut = "Ctrl+Y";
    redo.macShortcut = "Ctrl+Shift+Z";
    CHECK(redo.shortcut_for(false) == "Ctrl+Y");
    CHECK(redo.shortcut_for(true) == "Ctrl+Shift+Z");
    menu::Item save = menu::action("Save", nullptr);
    save.shortcut = "Ctrl+S";
    CHECK(save.shortcut_for(true) == "Ctrl+S");  // no Mac-specific one: the neutral shortcut
}

TEST_CASE("menu: parse_shortcut splits modifiers and key") {
    menu::Shortcut s = menu::parse_shortcut("Ctrl+Shift+Z");
    CHECK(s.ctrl);
    CHECK(s.shift);
    CHECK_FALSE(s.alt);
    CHECK(s.key == "z");
    s = menu::parse_shortcut("Cmd+,");
    CHECK(s.ctrl);
    CHECK(s.key == ",");
    s = menu::parse_shortcut("Alt+F5");
    CHECK(s.alt);
    CHECK(s.key == "f5");
    CHECK(menu::parse_shortcut("Ctrl++").key == "+");
    CHECK_FALSE(menu::parse_shortcut("").valid());
    CHECK_FALSE(menu::parse_shortcut("Hyper+S").valid());
}

TEST_CASE("menu: lazy children are evaluated only when asked for") {
    int calls = 0;
    menu::Item recent = menu::lazy_submenu("Recent Projects", [&calls] {
        ++calls;
        return std::vector<menu::Item>{menu::action("a", nullptr), menu::action("b", nullptr)};
    });
    menu::MainMenu m;
    m.items.push_back(menu::submenu("File", {menu::action("New", nullptr), recent}));
    // Walking the tree for names, copying it, looking for an item: none of it opens the lazy menu.
    menu::MainMenu copy = m;
    (void)menu::at_names(copy.items);
    (void)menu::find_by_at_name(copy.items, "x");
    CHECK(calls == 0);
    const menu::Item& r = m.items[0].children[1];
    CHECK(r.is_menu());
    CHECK(r.children.empty());
    CHECK(r.resolved_children().size() == 2);  // opening it
    CHECK(calls == 1);
}

TEST_CASE("menu: the editor's tree has the menus, the autotest names and the platform differences") {
    Editor ed{EditorOptions{}};
    const menu::MainMenu bar = ed.build_main_menu(false);
    std::vector<std::string> labels;
    for (const menu::Item& i : bar.items) labels.push_back(i.label);
    CHECK(labels == std::vector<std::string>{"File", "Edit", "View", "AI", "Help", "Export Game"});
    CHECK(bar.items.back().kind == menu::Item::Kind::Action);  // a click item on the bar itself
    CHECK(bar.trailing.rfind("FactorIA ", 0) == 0);
    CHECK(bar.trailingAtName == "menu:version");

    const std::set<std::string> names(menu::at_names(bar.items).begin(), menu::at_names(bar.items).end());
    for (const char* n : {"menu:file", "menu:view", "menu:ai", "menu:export", "menu:setup", "menu:platform-settings",
                          "menu:revert-ai", "menu:hierarchy", "menu:inspector", "menu:project", "menu:audio", "menu:profiler",
                          "menu:ai-settings", "menu:ai-roles"})
        CHECK_MESSAGE(names.count(n) == 1, n);

    const menu::Item* file = top(bar, "File");
    REQUIRE(file);
    CHECK(child(*file, "Quit"));
    const menu::Item* save = child(*file, "Save Scene");
    REQUIRE(save);
    CHECK(save->shortcut == "Ctrl+S");
    CHECK_FALSE(save->enabled);  // no project open
    const menu::Item* recent = child(*file, "Recent Projects");
    const menu::Item* scenes = child(*file, "Open Scene");
    REQUIRE(recent);
    REQUIRE(scenes);
    CHECK(static_cast<bool>(recent->lazyChildren));
    CHECK(static_cast<bool>(scenes->lazyChildren));  // fs::list runs only when the submenu opens
    CHECK(scenes->children.empty());

    const menu::MainMenu nativeBar = ed.build_main_menu(true);
    labels.clear();
    for (const menu::Item& i : nativeBar.items) labels.push_back(i.label);
    CHECK(labels == std::vector<std::string>{"File", "Edit", "View", "AI", "Export", "Help"});
    for (const menu::Item& i : nativeBar.items) CHECK(i.is_menu());
    CHECK_FALSE(child(*top(nativeBar, "File"), "Quit"));  // Quit is in the app menu
    CHECK(nativeBar.trailing.empty());                    // the version is in About and the window title
    const menu::Item* exportMenu = top(nativeBar, "Export");
    REQUIRE(exportMenu);
    REQUIRE(exportMenu->children.size() == 1);
    CHECK(exportMenu->children[0].label == "Export Game...");
    CHECK(exportMenu->children[0].shortcut == "Ctrl+E");

    const menu::Item* edit = top(nativeBar, "Edit");
    REQUIRE(edit);
    CHECK(child(*edit, "Undo")->shortcut_for(true) == "Ctrl+Z");
    CHECK(child(*edit, "Redo")->shortcut_for(true) == "Ctrl+Shift+Z");
    CHECK(child(*edit, "Redo")->shortcut_for(false) == "Ctrl+Y");
}

TEST_CASE("menu: View items toggle the panel flags") {
    Editor ed{EditorOptions{}};
    const menu::MainMenu m = ed.build_main_menu(false);
    const menu::Item* view = top(m, "View");
    REQUIRE(view);
    const menu::Item* hierarchy = child(*view, "Hierarchy");
    REQUIRE(hierarchy);
    CHECK(hierarchy->checked == ed.showHierarchy_);
    const bool before = ed.showHierarchy_;
    hierarchy->action();
    CHECK(ed.showHierarchy_ == !before);
    CHECK(ed.build_main_menu(false).items[2].children[1].checked == !before);
}

#ifdef __APPLE__
namespace {
struct Spy {
    int settings = 0, quit = 0, lazyCalls = 0, saves = 0, undos = 0, exports = 0;
    bool saveEnabled = true, undoEnabled = true;
    std::string saveLabel = "Save Scene";
};

menu::MainMenu sample_tree(Spy& s) {
    menu::MainMenu m;
    menu::Item save = menu::action(s.saveLabel, [&s] { ++s.saves; }, s.saveEnabled);
    save.shortcut = "Ctrl+S";
    save.yieldsToText = true;
    save.tooltip = "Save it";
    menu::Item recent = menu::lazy_submenu("Recent", [&s] {
        ++s.lazyCalls;
        return std::vector<menu::Item>{menu::action("proj-a", nullptr), menu::action("proj-b", nullptr)};
    });
    m.items.push_back(menu::submenu("File", {save, menu::separator(), recent}));
    menu::Item undo = menu::action("Undo", [&s] { ++s.undos; }, s.undoEnabled);
    undo.shortcut = "Ctrl+Z";
    undo.yieldsToText = true;
    menu::Item redo = menu::action("Redo", nullptr);
    redo.shortcut = "Ctrl+Y";
    redo.macShortcut = "Ctrl+Shift+Z";
    redo.yieldsToText = true;
    m.items.push_back(menu::submenu("Edit", {undo, redo}));
    menu::Item check = menu::action("Panel", nullptr);
    check.checked = true;
    m.items.push_back(menu::submenu("View", {check}));
    menu::Item exp = menu::action("Export Game...", [&s] { ++s.exports; });
    exp.shortcut = "Ctrl+E";
    m.items.push_back(menu::submenu("Export", {exp}));
    return m;
}

std::unique_ptr<NativeMenu> make(Spy& s) {
    NativeAppMenuSpec spec;
    spec.version = "9.9.9";
    spec.build = "abc123";
    spec.openSettings = [&s] { ++s.settings; };
    spec.quit = [&s] { ++s.quit; };
    spec.install = false;  // no NSApplication in the test binary
    return make_native_menu(spec);
}

const NativeItemInfo* find(const std::vector<NativeItemInfo>& v, const std::string& title) {
    for (const NativeItemInfo& i : v)
        if (i.title == title) return &i;
    return nullptr;
}
}  // namespace

TEST_CASE("native menu: the NSMenu has the app menu, the tree's menus, titles, key equivalents, enabled and checked state") {
    Spy s;
    auto nm = make(s);
    REQUIRE(nm);
    nm->update(sample_tree(s), false);
    const auto bar = nm->snapshot();
    std::vector<std::string> titles;
    for (const auto& i : bar) titles.push_back(i.title);
    CHECK(titles == std::vector<std::string>{"FactorIA", "File", "Edit", "View", "Export", "Window"});

    const NativeItemInfo* app = find(bar, "FactorIA");
    REQUIRE(app);
    const NativeItemInfo* about = find(app->children, "About FactorIA");
    CHECK(about);
    const NativeItemInfo* settings = find(app->children, "Settings...");
    REQUIRE(settings);
    CHECK(settings->keyEquivalent == ",");
    CHECK(settings->command);
    CHECK(find(app->children, "Services"));
    const NativeItemInfo* hide = find(app->children, "Hide FactorIA");
    REQUIRE(hide);
    CHECK(hide->keyEquivalent == "h");
    const NativeItemInfo* others = find(app->children, "Hide Others");
    REQUIRE(others);
    CHECK(others->option);
    CHECK(find(app->children, "Show All"));
    const NativeItemInfo* quit = find(app->children, "Quit FactorIA");
    REQUIRE(quit);
    CHECK(quit->keyEquivalent == "q");
    CHECK(quit->command);

    const NativeItemInfo* file = find(bar, "File");
    REQUIRE(file);
    const NativeItemInfo* save = find(file->children, "Save Scene");
    REQUIRE(save);
    CHECK(save->keyEquivalent == "s");
    CHECK(save->command);
    CHECK_FALSE(save->shift);
    CHECK(save->enabled);
    CHECK(save->tooltip == "Save it");
    CHECK(file->children[1].separator);
    const NativeItemInfo* recent = find(file->children, "Recent");
    REQUIRE(recent);
    CHECK(recent->hasSubmenu);
    CHECK(recent->children.size() == 2);  // snapshot opens the lazy menu

    const NativeItemInfo* edit = find(bar, "Edit");
    REQUIRE(edit);
    const NativeItemInfo* redo = find(edit->children, "Redo");
    REQUIRE(redo);
    CHECK(redo->command);
    CHECK(redo->shift);
    CHECK(redo->keyEquivalent == "Z");  // Cmd+Shift+Z on the Mac, not the neutral Ctrl+Y
    CHECK(redo->enabled);
    const NativeItemInfo* view = find(bar, "View");
    REQUIRE(view);
    CHECK(find(view->children, "Panel")->checked);
    const NativeItemInfo* exp = find(find(bar, "Export")->children, "Export Game...");
    REQUIRE(exp);
    CHECK(exp->keyEquivalent == "e");
    CHECK(exp->command);
}

TEST_CASE("native menu: a click queues the action and the next drain runs it") {
    Spy s;
    auto nm = make(s);
    REQUIRE(nm);
    nm->update(sample_tree(s), false);
    CHECK(nm->pending() == 0);
    CHECK(nm->trigger({"File", "Save Scene"}));
    CHECK(s.saves == 0);  // not inside the Cocoa event
    CHECK(nm->pending() == 1);
    CHECK(nm->drain() == 1);
    CHECK(s.saves == 1);
    CHECK(nm->pending() == 0);
    CHECK(nm->drain() == 0);

    // The app menu's items go through the same queue.
    CHECK(nm->trigger({"FactorIA", "Settings..."}));
    CHECK(nm->trigger({"FactorIA", "Quit FactorIA"}));
    CHECK(s.settings == 0);
    CHECK(s.quit == 0);
    CHECK(nm->drain() == 2);
    CHECK(s.settings == 1);
    CHECK(s.quit == 1);

    CHECK_FALSE(nm->trigger({"File", "No such item"}));
    CHECK_FALSE(nm->trigger({"File"}));  // a menu is not an action

    // An item that was turned off between the click and the drain does not run.
    CHECK(nm->trigger({"Edit", "Undo"}));
    s.undoEnabled = false;
    nm->update(sample_tree(s), false);
    CHECK(nm->drain() == 0);
    CHECK(s.undos == 0);
    CHECK_FALSE(nm->trigger({"Edit", "Undo"}));  // and a disabled item cannot be clicked
}

TEST_CASE("native menu: key equivalents work with the menus closed and run through the queue") {
    Spy s;
    auto nm = make(s);
    REQUIRE(nm);
    nm->update(sample_tree(s), false);
    CHECK(nm->press_key("Ctrl+S"));
    CHECK(s.saves == 0);
    CHECK(nm->pending() == 1);
    CHECK(nm->drain() == 1);
    CHECK(s.saves == 1);
    CHECK(nm->press_key("Ctrl+Z"));
    CHECK(nm->press_key("Ctrl+E"));
    CHECK(nm->press_key("Ctrl+,"));
    CHECK(nm->press_key("Ctrl+Q"));
    CHECK(nm->drain() == 4);
    CHECK(s.undos == 1);
    CHECK(s.exports == 1);
    CHECK(s.settings == 1);
    CHECK(s.quit == 1);
    CHECK(nm->press_key("Ctrl+Shift+Z"));  // Redo: no callback, nothing runs
    CHECK(nm->drain() == 0);
    CHECK_FALSE(nm->press_key("Ctrl+J"));  // not a shortcut: the key goes on to the window
    CHECK_FALSE(nm->press_key("S"));       // without Cmd it is typing
    // Looking a key up never opens the lazy menus (no file listing for every key pressed).
    CHECK(s.lazyCalls == 0);
}

TEST_CASE("native menu: a text box with the keyboard gets Save, Undo and Redo keys; a disabled item lets the key through") {
    Spy s;
    auto nm = make(s);
    REQUIRE(nm);
    nm->update(sample_tree(s), true);  // typing in a text field
    CHECK_FALSE(nm->press_key("Ctrl+S"));
    CHECK_FALSE(nm->press_key("Ctrl+Z"));
    CHECK(nm->press_key("Ctrl+E"));  // Export is not a text-editing key
    CHECK(nm->drain() == 1);
    CHECK(s.saves == 0);
    nm->update(sample_tree(s), false);
    CHECK(nm->press_key("Ctrl+S"));
    s.saveEnabled = false;  // e.g. the game is playing
    nm->update(sample_tree(s), false);
    CHECK(nm->drain() == 0);  // turned off after the key: dropped
    CHECK(nm->press_key("Ctrl+S") == nm->press_key("Ctrl+S"));  // whether AppKit says handled for a disabled item is its business
    CHECK(nm->drain() == 0);                                      // ... but the action does not run
    CHECK(s.saves == 0);
}

TEST_CASE("native menu: enabled and checked are updated in place; a changed label rebuilds the menus") {
    Spy s;
    auto nm = make(s);
    REQUIRE(nm);
    nm->update(sample_tree(s), false);
    s.saveEnabled = false;
    nm->update(sample_tree(s), false);
    auto bar = nm->snapshot();
    auto file = find(bar, "File");
    REQUIRE(file);
    CHECK_FALSE(find(file->children, "Save Scene")->enabled);
    CHECK(bar.size() == 6);

    s.saveLabel = "Save";
    s.saveEnabled = true;
    nm->update(sample_tree(s), false);
    bar = nm->snapshot();
    file = find(bar, "File");
    REQUIRE(file);
    CHECK_FALSE(find(file->children, "Save Scene"));
    CHECK(find(file->children, "Save")->enabled);
    CHECK(find(file->children, "Save")->keyEquivalent == "s");
    CHECK(bar.size() == 6);  // the app menu is kept, the others are not doubled
    CHECK(nm->trigger({"File", "Save"}));
    CHECK(nm->drain() == 1);
    CHECK(s.saves == 1);
}

TEST_CASE("native menu: a click item on the top level becomes a menu of its own") {
    Spy s;
    auto nm = make(s);
    REQUIRE(nm);
    menu::MainMenu m;
    m.items.push_back(menu::submenu("File", {menu::action("New", nullptr)}));
    m.items.push_back(menu::action("Export Game", [&s] { ++s.exports; }));
    nm->update(m, false);
    const auto bar = nm->snapshot();
    const NativeItemInfo* exp = find(bar, "Export Game");
    REQUIRE(exp);
    CHECK(exp->hasSubmenu);
    CHECK(nm->trigger({"Export Game", "Export Game"}));
    CHECK(nm->drain() == 1);
    CHECK(s.exports == 1);
}
#else
TEST_CASE("native menu: there is none outside macOS") {
    NativeAppMenuSpec spec;
    CHECK(make_native_menu(spec) == nullptr);
    CHECK_FALSE(native_menu_wanted());
}
#endif
