// FactorIA visual editor (Dear ImGui docking + sokol), entry point for `factoria editor`.
//
// AI-first: no hand-editing UI. Panels: Toolbar, Viewport, AI Assistant, Console,
// Engine Feedback, Audio, Status bar, and the Export window. See docs/EDITOR.md.
//
// Hidden test hook: environment FA_EDITOR_AUTOTEST=1 opens a temp project made
// from templates/2d-platformer, exercises the editor programmatically, saves
// window screenshots (FA_EDITOR_AUTOTEST_OUT = output directory) and quits.
#pragma once

#include <string>

namespace fa {

struct EditorOptions {
    std::string projectDir;  // folder with factoria.json; "" = show the Open/New project dialog
};

// Opens the editor window and blocks until it is closed. Returns the process exit code.
int run_editor(const EditorOptions& options);

}  // namespace fa
