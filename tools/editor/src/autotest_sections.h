#pragma once
// The sections of the editor autotest (FA_EDITOR_AUTOTEST=1), in the order a full run plays them. FA_EDITOR_AUTOTEST_SECTIONS=K,M
// runs only those (docs/EDITOR.md, "Run only some sections"). Every section after S starts from the same clean 2D fixture
// (Editor::at_build_tools_script), so a section alone passes or fails as it does in the full run.
//
// tools/editor/CMakeLists.txt reads the ids of this table to check that the ctest entries cover every section exactly once:
// keep one `{"<id>", "<title>"},` per line.
#include <set>
#include <string>
#include <string_view>

#include "fa/core/types.h"

namespace fa::editor {

struct AutotestSection {
    const char* id;
    const char* title;
};

inline constexpr AutotestSection kAutotestSections[] = {
    {"S", "Start: select, edit, undo, play, AI marshaling, feedback, viewport click and keys"},
    {"T", "Toolbar Screenshot button"},
    {"A", "Audio panel"},
    {"A2", "Profiler panel"},
    {"B", "Commands that rebuild the open scene file"},
    {"C", "Pick bounds and the selection outline"},
    {"D", "Bloom in the viewport"},
    {"E", "Ctrl+V into the AI Assistant input"},
    {"F", "AI Assistant text: wrapping, right-click menu, selectable messages"},
    {"G", "Delete a project from the Open project dialog"},
    {"H", "Export window and its report"},
    {"I", "Platform settings window"},
    {"J", "Set Up This Computer"},
    {"K", "Custom material: params, snippet reload, a broken snippet"},
    {"L", "Hand editing in the Hierarchy and the Inspector"},
    {"M", "Transform gizmos: 2D, 3D and a HUD entity"},
    {"N", "Project panel"},
    {"O", "CLI agent through the editor's MCP endpoint"},
    {"P", "Revert an AI run: checkpoint, Revert, Undo revert"},
    {"Q", "AI agent liveness: stuck warning, Check activity, a worker that outlives the orchestrator's turn"},
    {"R", "Program updated on disk: the Restart notice, its button state, Not now"},
    {"U", "Editor layout kept: changed panels come back after reopening and after the welcome screen; Reset layout"},
    {"V", "AI reviews: the buttons, a read-only reviewer, the saved report, Send to orchestrator"},
    {"W", "Several AI chats at once: both finish, same-file warning, the cap, Revert of one run, Stop of one run"},
    {"X", "AI settings window: asset providers, a key, asset sites; a bad site stops Save; Remove stored key"},
    {"Y", "Recipes: stale badge, the banner when a source is saved, Regenerate (toolbar and banner), a missing source"},
    {"Z", "Sprite sheets: the Project panel previews a sheet's clips, the Inspector lists them and one click sets SpriteAnimator.clip"},
    {"B2", "Animation panel: new clip, keys recorded by a gizmo drag, a key moved and undone, easing, an event, scrubbing, onion skin"},
    {"C2", "Bone tools: a chain drawn by clicks, a sprite bound, weights painted (one undo step), an IK handle dragged, the overlay of the selected bone"},
    {"D2", "AI settings, External tools tab: add a server with the form, Test, paste Claude Code JSON, Save keeps the other keys, Remove"},
    {"E2", "Feedback sharing: consent dialog, ask-mode review list, panel share column and boxes, Review with AI, Settings sign-in and Send now"},
    {"E3", "AI settings, Extensions tab: a plugin folder and pasted hooks added, a role switched off, Save keeps the other keys, a project's hooks need the trust and a changed file drops it"},
    {"K2", "AI settings, Extensions tab, Skills: the engine's and the project's skills listed, a role and an On box switched, Save keeps them as skill entries"},
};

// The ids named by FA_EDITOR_AUTOTEST_SECTIONS: separated by commas or spaces, in any case ("k,a2" picks K and A2).
// An unknown id is an error that lists the sections.
Result<std::set<std::string>> parse_autotest_sections(std::string_view text);

}  // namespace fa::editor
