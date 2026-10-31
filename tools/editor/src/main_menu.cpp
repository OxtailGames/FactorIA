// The editor's main menu: the tree built from the editor's state (build_main_menu) and the two ways it is shown (draw_main_menu):
// the system menu bar on macOS (native_menu_apple.mm), the in-window ImGui bar elsewhere (menu_imgui.cpp). See menu_model.h.
#include "editor_internal.h"
#include "fa/core/build_info.h"
#include "fa/tooling/docs.h"
#include "native_menu.h"
#include "sokol_app.h"

namespace fa::editor {

menu::MainMenu Editor::build_main_menu(bool native) {
    using menu::Item;
    const bool have = engine_ != nullptr;
    const bool editing = have && play_ == PlayState::Edit;
    auto with = [](Item i, std::string at, std::string tip = "") {
        i.atName = std::move(at);
        i.tooltip = std::move(tip);
        return i;
    };
    auto toggle = [](const char* label, bool& flag) {
        Item i = menu::action(label, [&flag] { flag = !flag; });
        i.checked = flag;
        return i;
    };
    auto doc_item = [this](const char* label, const char* doc, const char* title) {
        return menu::action(label, [this, doc, title] {
            auto d = read_doc(doc);
            docsTitle_ = title;
            docsText_ = d ? *d : d.error().to_string();
            showDocs_ = true;
        });
    };

    // ---- File
    std::vector<Item> file;
    file.push_back(menu::action("New Project...", [this] { showProjectDialog_ = true; }));
    file.push_back(menu::action("Open Project...", [this] { showProjectDialog_ = true; }));
    file.push_back(menu::lazy_submenu("Recent Projects", [this] {
        std::vector<Item> items;
        for (const std::string& r : recentProjects_) items.push_back(menu::action(r, [this, r] { open_project(r); }));
        return items;
    }, !recentProjects_.empty()));
    file.push_back(menu::separator());
    Item save = menu::action("Save Scene", [this] { save_scene_now(); }, editing);
    save.shortcut = "Ctrl+S";
    save.yieldsToText = true;
    file.push_back(std::move(save));
    file.push_back(menu::action("Reload Scene", [this] { if (dirty_) showReloadConfirm_ = true; else reload_scene_from_disk(); }, have));
    // The scene list is read from disk only when the submenu opens.
    file.push_back(menu::lazy_submenu("Open Scene", [this] {
        std::vector<Item> items;
        for (const auto& f : fs::list("", true))
            if (f.size() > 11 && f.ends_with(".scene.json") && f[0] != '.') {
                Item i = menu::action(f, [this, f] { if (dirty_) pendingScene_ = f; else open_scene(f); });
                i.checked = f == scenePath_;
                items.push_back(std::move(i));
            }
        return items;
    }, have));
    file.push_back(menu::separator());
    file.push_back(menu::action("Open Screenshots Folder", [this] { open_screenshots_folder(); }, have));
    file.push_back(with(menu::action("Export Game...", [this] { open_export_window(); }, have), "",
                        "Package the game for Windows, macOS, Linux, Android or iOS"));
    file.push_back(with(menu::action("Platform Settings...", [this] { open_platform_settings(); }, have), "menu:platform-settings",
                        "The game icon and what each platform's export needs: Android version and signing key, macOS category, iOS team..."));
    file.push_back(with(menu::action("Set Up This Computer...", [this] { open_setup_window(); }), "menu:setup",
                        "Install what an export needs: the Android build tools, the players of other platforms, CMake, Xcode"));
    if (!native) {  // on macOS Quit is in the app menu
        file.push_back(menu::separator());
        file.push_back(menu::action("Quit", [] { sapp_request_quit(); }));
    }

    // ---- Edit
    std::vector<Item> edit;
    Item undoItem = menu::action("Undo", [this] { undo(); }, editing && !undo_.empty());
    undoItem.shortcut = "Ctrl+Z";
    undoItem.yieldsToText = true;
    edit.push_back(std::move(undoItem));
    Item redoItem = menu::action("Redo", [this] { redo(); }, editing && !redo_.empty());
    redoItem.shortcut = "Ctrl+Y";
    redoItem.macShortcut = "Ctrl+Shift+Z";  // the Mac's redo
    redoItem.yieldsToText = true;
    edit.push_back(std::move(redoItem));
    edit.push_back(menu::separator());
    const int lastRun = ai_last_revertable_run();
    edit.push_back(with(menu::action("Revert Last AI Run", [this] { ai_revert_request(chat_.current().id, ai_last_revertable_run()); },
                                     editing && !ai_chat_busy(chat_.current().id) && lastRun >= 0),
                        "menu:revert-ai",
                        "Puts the project's files and the open scene back as they were before the last run of the AI Assistant in this chat."));

    // ---- View
    std::vector<Item> view;
    view.push_back(toggle("Viewport", showViewport_));
    view.push_back(with(toggle("Hierarchy", showHierarchy_), "menu:hierarchy"));
    view.push_back(with(toggle("Inspector", showInspector_), "menu:inspector"));
    view.push_back(toggle("Console", showConsole_));
    view.push_back(with(toggle("Project", showProject_), "menu:project",
                        "The project's files: filter, search, drag onto the Inspector or the Viewport, open scenes"));
    view.push_back(toggle("AI Assistant", showAi_));
    view.push_back(toggle("Engine Feedback", showFeedback_));
    view.push_back(with(toggle("Audio", showAudio_), "menu:audio",
                        "The live audio.log: every sound played, with its bus, volume, source entity and whether the clip loaded"));
    view.push_back(with(toggle("Profiler", showProfiler_), "menu:profiler",
                        "Where the time goes while the game plays: milliseconds per engine system and per script behaviour class, GPU time, memory"));
    view.push_back(with(toggle("Animation", showAnimation_), "menu:animation",
                        "The clips of the selected entity's Animator: dopesheet and curves, scrubbing, record mode, event markers and the onion skin"));
    view.push_back(with(toggle("Bone tools", showBoneTools_), "menu:bonetools",
                        "Draw a bone chain by clicking in the viewport, bind a sprite to bones, paint weights and drag IK targets"));
    view.push_back(menu::separator());
    view.push_back(toggle("Show colliders", showColliders_));
    view.push_back(with(toggle("Show navmesh", showNav_), "",
                        "Draws the walkable cells of every NavMesh3D (green; red where a moving obstacle blocks; blue on a walkable moving body) and its off-mesh links (yellow lines), the ground nav.findPath walks on"));
    view.push_back(toggle("Selection overlay", showOverlay_));
    view.push_back(menu::action("Reset layout", [this] { resetLayout_ = true; }));

    // ---- AI
    std::vector<Item> ai;
    ai.push_back(with(menu::action("AI Settings...", [this] { open_ai_settings(); }), "menu:ai-settings",
                      "The roles (which provider and model plays the orchestrator, worker, artist, critics...), which service makes the\n"
                      "AI's images, sounds and 3D models (with its key), and the websites it looks at for assets"));
    const bool detected = aiDetected_.load();
    Item roles = with(menu::action("Roles...", [this] { open_ai_settings(true); }, detected), "menu:ai-roles");
    roles.tooltipFn = [this, detected] {
        if (!detected) return std::string("Reading ai.json...");
        return std::string("Choose the provider and model of each role (AI Settings, Roles tab). Takes effect with the next message.\n") +
               ai_roles_summary();
    };
    ai.push_back(std::move(roles));

    // ---- Help
    std::vector<Item> help;
    help.push_back(doc_item("AI providers setup", "ai-providers", "AI_PROVIDERS.md"));
    help.push_back(doc_item("Scripting guide", "scripting", "SCRIPTING.md"));
    help.push_back(doc_item("Engine feedback guide", "engine-feedback", "ENGINE_FEEDBACK.md"));

    menu::MainMenu m;
    m.items.push_back(with(menu::submenu("File", std::move(file)), "menu:file"));
    m.items.push_back(menu::submenu("Edit", std::move(edit)));
    m.items.push_back(with(menu::submenu("View", std::move(view)), "menu:view"));
    m.items.push_back(with(menu::submenu("AI", std::move(ai)), "menu:ai"));
    if (native) {
        // A system menu bar cannot hold a click item: Export is a menu of its own, with the shortcut.
        Item exp = with(menu::action("Export Game...", [this] { open_export_window(); }, have), "menu:export",
                        "Package the game for Windows, macOS, Linux, Android or iOS");
        exp.shortcut = "Ctrl+E";
        std::vector<Item> items;
        items.push_back(std::move(exp));
        m.items.push_back(menu::submenu("Export", std::move(items)));
    }
    m.items.push_back(menu::submenu("Help", std::move(help)));
    if (!native) {
        // Not a menu: a click on the bar itself, always in reach.
        m.items.push_back(with(menu::action("Export Game", [this] { open_export_window(); }, have), "menu:export",
                               "Package the game for Windows, macOS, Linux, Android or iOS (File > Export Game... does the same)"));
        // The engine version at the right end of the bar, so it is always clear which FactorIA is running.
        m.trailing = std::string("FactorIA ") + FA_ENGINE_VERSION;
        m.trailingTooltip = std::string("FactorIA ") + FA_ENGINE_VERSION + ", build " + build_fingerprint();
        m.trailingAtName = "menu:version";
    }
    return m;
}

void Editor::draw_main_menu() {
    if (!nativeMenuChecked_) {
        nativeMenuChecked_ = true;
        // The autotest clicks the ImGui bar; FA_EDITOR_NATIVE_MENU=0 asks for it too.
        if (!autotest_ && native_menu_wanted()) {
            NativeAppMenuSpec spec;
            spec.version = FA_ENGINE_VERSION;
            spec.build = build_fingerprint();
            spec.openSettings = [this] { open_ai_settings(); };
            spec.quit = [] { sapp_request_quit(); };
            nativeMenu_ = make_native_menu(spec);
        }
    }
    const menu::MainMenu m = build_main_menu(nativeMenu_ != nullptr);
    if (nativeMenu_) {
        nativeMenu_->update(m, ImGui::GetIO().WantTextInput);
        nativeMenu_->drain();  // what the user picked in the system menu since the last frame
        return;
    }
    menu::draw_imgui_bar(m, [this](const std::string& name, bool enabled) { at_track(name, enabled); });
}

}  // namespace fa::editor
