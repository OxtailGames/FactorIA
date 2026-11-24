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
    {"G2", "Post-processing panel: the stack and its effects, the A/B switch, a field and a look through postprocess.set / postprocess.apply_preset, undo"},
    {"H", "Export window and its report"},
    {"I", "Platform settings window"},
    {"J", "Set Up This Computer"},
    {"K", "Custom material: params, snippet reload, a broken snippet"},
    {"L", "Hand editing in the Hierarchy and the Inspector"},
    {"M", "Transform gizmos: 2D, 3D and a HUD entity"},
    {"M4", "Several entities selected: Ctrl and Shift clicks in the Hierarchy, a marquee and Ctrl click in the viewport, the move gizmo and the Inspector write to all of them as one undo step, Esc puts them back, Add Component, Duplicate and Delete on the selection"},
    {"M5", "Copy, cut and paste of entities: Ctrl+C, Ctrl+X and Ctrl+V in the Hierarchy through the system clipboard, one undo step each, the copy of the primary selected last, text that is not entities pastes nothing, another panel keeps the keys, the row menu's Copy and Paste"},
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
    {"G3", "Graph panel: a material with a one-node graph opened, three nodes added from the palette (right click, search), four links dragged port to port, the live preview compiles the dissolve graph and draws it, Save writes the material and the snippet, a hand-edited snippet is only overwritten after the question, Undo/Redo through the editor's stack, a sprite graph and a post graph made with the kind combo next to New graph material (no 3D nodes, noise into the alpha of the sprite, the preview on the 2D quad, the post preview over its scene and Try on scene camera, Save generating post())"},
    {"Q3", "Scene settings panel: View > Scene settings lists the sky fields, a sky material picked (one undo step) shows its params typed by material.info, a param set and taken back with its Reset, the field's Reset puts the gradient back, Undo/Redo through the editor's stack, a refused value changes nothing and leaves no step"},
    {"Q4", "Graphics settings window: View > Graphics opens it with the defaults, the mode and the preset picked with real clicks on the combos, Save writes render.upscaler and render.graphicsPreset to factoria.json (read back by the engine's own reader), a misspelt mode is named with its pointer and disables Save, Revert reads the saved values again"},
    {"L4", "Lightmap panel: View > Lightmap opens it, Start on a scene with no 3D mesh says what to add (a teaching error, no job), a floor, a box and a baked sun added, Start bakes on a job thread with a progress bar and a phase, Cancel stops a second bake and writes nothing, a LightProbeGroup added before a finished bake, which lists its pages and probes (the probe file is written) and sets SceneSettings.lightmaps as one undo step, Undo takes it back"},
    {"T3", "Terrain tool: View > Terrain tool, a sculpt, a paint and a holes stroke dragged over the viewport each change the terrain and are ONE editor undo step and one terrain step (Ctrl+Z / Redo give back exact heights, splat weights and holes), the cursor ring is drawn, an undo of an unrelated edit keeps the unsaved terrain, a save that cannot write says why and keeps the edits, Save writes the files, an unsaved terrain counts as unsaved work, Esc gives the dirty state back, a click that misses the terrain keeps the selection and the tool, Play then Stop gives back the exact terrain"},
    {"F3", "Foliage tool: View > Foliage tool, an Add stroke and a Remove stroke dragged over the viewport each change the instances file and are ONE editor undo step however many foliage.paint pieces were sent (Ctrl+Z / Redo give back the exact count), the cursor ring is drawn, Scatter all and Clear (it asks first) are one undo step each, Esc takes a stroke back and gives the dirty state back, a click that misses the terrain keeps the selection and the tool, and more edits than the history keeps drop the undo rows of the forgotten steps with a toast"},
    {"W2", "Cells panel (editing a streamed world): View > Cells opens it, a world of three cells opened in Edit mode streams nothing by distance, Load around the view loads the cell under the camera and not the far one, an edit marks only its cell dirty, Save cells writes that cell's file and neither the other file nor the index, an entity moved across the border is written into the other cell's file, Play streams by distance and Stop brings the loaded cells back clean"},
    {"O3", "Animation panel, 3D clips: a generated walk opened on a rigged model, a bone picked in the list and in the view, the rotation gizmo dragged (one key, one undo step), an IK handle dragged, a key moved and deleted in the dopesheet, Mirror pose, the filmstrip sheet, Undo/Redo through the editor's stack"},
    {"R3", "Level generator window: a drawn level as the sample, Generate, Next / Previous seed (the same seed gives the same level), Keep builds it in the scene as one undo step, Save writes a level file"},
    {"T2", "Play on phone window: Start without a web player says how to get one, with a stand-in player the server answers on its token, the LAN address is drawn as a QR code, a log line POSTed like the phone's page lands in the log (category phone), a new file exports again, Stop closes the port; the checklist for a phone that cannot connect"},
    {"S3", "Play > Let the AI Play: the Play sessions list marks the AI's sessions, Attach last play session picks the one you played, a real play.auto run on a worker thread ends with its session listed and opened, Cancel writes none"},
    {"R4", "Review window: a sheet made by a command is offered in a toast and opens on its button, 3 and the arrows select, Compare shows 1 and 2 side by side, Enter and the confirmation pick through review.pick (the other files move to the drop folder), History shows the pick and opens the sheet read-only, the Level generator's Sheet of seeds makes a sheet in a child factoria whose pick sets the seed"},
    {"P4", "Prefab overrides in the Inspector: an overridden field is marked and counted, Revert to prefab and Apply to prefab from the field's menu, Undo, the other instance follows an apply, Apply all asks first, a removed component named and given back, Apply greyed out while the game plays"},
    {"X2", "Start window, Examples tab (a fake release): offline with no saved copy the error and Retry, the list, the saved list shown at once and dropped when the window closes mid-refresh, a failed refresh marked stale, a bad hash is an error that leaves nothing, Cancel, Create makes and opens the project"},
};
// clang-format on

// The ids named by FA_EDITOR_AUTOTEST_SECTIONS: separated by commas or spaces, in any case ("k,a2" picks K and A2).
// An unknown id is an error that lists the sections.
Result<std::set<std::string>> parse_autotest_sections(std::string_view text);

}  // namespace fa::editor
