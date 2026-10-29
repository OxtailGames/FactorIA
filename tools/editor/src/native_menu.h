// The macOS system menu bar (NSMenu / NSApp.mainMenu) showing the editor's menu tree (menu_model.h).
//
// On every other platform make_native_menu() returns null and the editor draws the tree in its window with ImGui
// (menu_imgui.cpp). The native menu lives in native_menu_apple.mm.
#pragma once

#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <vector>

#include "menu_model.h"

namespace fa::editor {

// What the app menu ("FactorIA": About, Settings..., Services, Hide..., Quit) needs from the editor.
struct NativeAppMenuSpec {
    std::string appName = "FactorIA";
    std::string version;                  // About: FA_ENGINE_VERSION
    std::string build;                    // About: the build fingerprint
    std::function<void()> openSettings;   // Settings... (Cmd+,)
    std::function<void()> quit;           // Quit (Cmd+Q): sapp_request_quit, so the unsaved-changes dialog still runs
    // False builds the menus without making them the application's main menu (the unit tests: no NSApplication needed).
    bool install = true;
};

// One native menu item as the system shows it (NativeMenu::snapshot, for tests).
struct NativeItemInfo {
    std::string title;
    std::string keyEquivalent;            // "s"; empty when none
    bool command = false, shift = false, option = false, control = false;  // its key equivalent's modifiers
    bool enabled = true, checked = false, separator = false, hasSubmenu = false;
    std::string tooltip;
    std::vector<NativeItemInfo> children;
};

class NativeMenu {
public:
    virtual ~NativeMenu() = default;
    // Mirrors the tree into the native menus: when only enabled / checked / actions changed the items are updated in place,
    // when a label, shortcut or the structure changed the menus are rebuilt. Call it once per frame on the main thread.
    // `textInputActive`: a text box has the keyboard, so the items marked yieldsToText are disabled and their keys reach it.
    virtual void update(const menu::MainMenu& menu, bool textInputActive) = 0;
    // Runs the actions of the items the user picked since the last call (menu actions arrive from the Cocoa event loop,
    // outside the ImGui frame, so they wait here until the frame starts). An item that is no longer enabled is dropped.
    // Returns how many ran. Main thread.
    virtual int drain() = 0;
    virtual int pending() const = 0;

    // ---- for tests ----
    // The bar as the system would show it. Opens the lazy menus first, like opening them does.
    virtual std::vector<NativeItemInfo> snapshot() = 0;
    // Clicks the item reached by these titles (top-level menu first); queues its action. False if there is none or it is disabled.
    virtual bool trigger(const std::vector<std::string>& titlePath) = 0;
    // Presses a key combination ("Ctrl+S" as in the model; Ctrl is Cmd) while the menus are closed. True when a menu took it.
    virtual bool press_key(const std::string& shortcut) = 0;
};

// The native menu bar, or null when this platform has none. Installs it as the application's main menu unless spec.install is false.
std::unique_ptr<NativeMenu> make_native_menu(const NativeAppMenuSpec& spec);

// Whether the editor should use the native menu: macOS, and FA_EDITOR_NATIVE_MENU is not "0". (The autotest draws the ImGui
// bar regardless: it clicks it.)
bool native_menu_wanted();

}  // namespace fa::editor
