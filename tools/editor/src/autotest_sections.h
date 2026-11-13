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

// clang-format off: tools/editor/CMakeLists.txt reads this table one row per line
inline constexpr AutotestSection kAutotestSections[] = {
    {"S", "Start: select, edit, undo, play, AI marshaling, feedback, viewport click and keys"},
    {"T", "Toolbar Screenshot button"},
    {"A", "Audio panel"},
    {"A2", "Profiler panel"},
    {"A3", "Paid asset calls wait for the user's yes: the card under the chat (what, how many, provider, estimate), Approve, Approve all for this run, Cancel, Stop while it waits"},
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
    {"Q2", "AI settings per project: a copied file waits for Accept (Ignore, Review), switching project shows the other roles, Reset of a row, Save as my defaults, a project Save, an invalid file"},
    {"Y", "Recipes: stale badge, the banner when a source is saved, Regenerate (toolbar and banner), a missing source"},
    {"Z", "Sprite sheets: the Project panel previews a sheet's clips, the Inspector lists them and one click sets SpriteAnimator.clip"},
    {"B2", "Animation panel: new clip, keys recorded by a gizmo drag, a key moved and undone, easing, an event, scrubbing, onion skin"},
    {"C2", "Bone tools: a chain drawn by clicks, a sprite bound, weights painted (one undo step), an IK handle dragged, the overlay of the selected bone"},
    {"D2", "AI settings, External tools tab: add a server with the form, Test, paste Claude Code JSON, Save keeps the other keys, Remove"},
    {"E2", "Feedback sharing: consent dialog, Send feedback window (AI check, uncheck, Send, Cancel), Add feedback window, archive, Settings sign-in and Send now"},
    {"E3", "AI settings, Extensions tab: a plugin folder and pasted hooks added, a role switched off, Save keeps the other keys, a project's hooks need the trust and a changed file drops it"},
    {"H2", "AI settings, Extensions tab, Hooks: saved hooks with where each runs, three real runs (ok, failed, blocked) listed, Clear"},
    {"S2", "AI settings, Extensions tab, Token savers: switches and judge saved in ai.json (other keys kept), proposals from the project's runs, accept/decline change AGENTS.md and the tool groups only on accept"},
    {"K2", "AI settings, Extensions tab, Skills: the engine's and the project's skills listed, a role and an On box switched, Save keeps them as skill entries"},
    {"F2", "AI settings, Extensions tab, Add TokenEconomizer: the confirmation, a fake Claude Code CLI run, the entry added, Save keeps the other keys, entry-only when the plugin is already installed"},
    {"E4", "Rejected feedback: the engine rejects what it already has, a double click opens an entry in a window, the status combo asks why, closed lists the archive, Copy, Delete asks first, the engine developers' verdict comes back"},
    {"R2", "Retrospective: the Feedback panel's button looks back at the project's recorded runs, files an efficiency entry with the fast role's model, says what happened and adds up the saving; a second click finds nothing new"},
    {"I2", "Image panel: a document opened, a layer added, a stroke painted, a rectangle selected and moved, an adjustment edited, Undo/Redo through the editor's stack, Save bakes the PNG"},
    {"L3", "Image panel pixel-art tools: the pixel grid and the Tiled preview, the palette bar (add a colour, secondary colour, undo), a frame added with the onion skin, play, Save bakes"},
    {"J2", "Vector panel: an svg opened, a path drawn with the Pen, an anchor moved and made smooth with the Node tool, a marquee and Union, Undo/Redo through the editor's stack, an image document's svg layer edited from the Image panel and baked by Save"},
    {"K3", "Sound panel: a patch opened, a knob turned, played, a selection zoomed, two variants A/B compared at the same loudness, an audio document's chain edited and its loop point dragged, Undo/Redo through the editor's stack, Save bakes the sounds"},
    {"M3", "Music panel: a song opened, a note drawn, moved and deleted on the piano roll, a drum hit, a section repeat and a mute in the mixer, Undo/Redo through the editor's stack, played with a moving playhead, the intensity buttons fading a layer, a looped section, Save bakes the mix and the stems"},
    {"N3", "Model panel: a model document opened as its operation tree and a live view of the mesh, a node picked to highlight its part, a slider clicked (one model.edit), Undo/Redo through the editor's stack, a node added, switched off and removed, the view orbited, the 1.8 m figure and Check, Save bakes the .glb"},
    {"P3", "Particles panel: New writes a starter effect and opens it, the preview plays it, the time scrubber is dragged (the same moment shows the same particles), a gradient key and curve keys are dragged (one vfx.edit and one undo step each), a part is added and removed, Undo/Redo through the editor's stack back to the file as New wrote it"},
    {"O3", "Animation panel, 3D clips: a generated walk opened on a rigged model, a bone picked in the list and in the view, the rotation gizmo dragged (one key, one undo step), an IK handle dragged, a key moved and deleted in the dopesheet, Mirror pose, the filmstrip sheet, Undo/Redo through the editor's stack"},
    {"R3", "Level generator window: a drawn level as the sample, Generate, Next / Previous seed (the same seed gives the same level), Keep builds it in the scene as one undo step, Save writes a level file"},
    {"T2", "Play on phone window: Start without a web player says how to get one, with a stand-in player the server answers on its token, the LAN address is drawn as a QR code, a log line POSTed like the phone's page lands in the log (category phone), a new file exports again, Stop closes the port; the checklist for a phone that cannot connect"},
    {"S3", "Play > Let the AI Play: the Play sessions list marks the AI's sessions, Attach last play session picks the one you played, a real play.auto run on a worker thread ends with its session listed and opened, Cancel writes none"},
    {"R4", "Review window: a sheet made by a command is offered in a toast and opens on its button, 3 and the arrows select, Compare shows 1 and 2 side by side, Enter and the confirmation pick through review.pick (the other files move to the drop folder), History shows the pick and opens the sheet read-only, the Level generator's Sheet of seeds makes a sheet in a child factoria whose pick sets the seed"},
};
// clang-format on

// The ids named by FA_EDITOR_AUTOTEST_SECTIONS: separated by commas or spaces, in any case ("k,a2" picks K and A2).
// An unknown id is an error that lists the sections.
Result<std::set<std::string>> parse_autotest_sections(std::string_view text);

}  // namespace fa::editor
