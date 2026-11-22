// The inverse of an editing command, built from the scene as it is BEFORE the command runs (docs/EDITOR.md, "Undo entries").
//
// Editor::edit_command asks `plan_undo` for the command it is about to run. A plan holds the forward commands (what redo
// runs: the call itself, with the entity id spelled out) and the inverse commands (what undo runs). A command with no
// builder in the table gives no plan and keeps the snapshot path, so adding an undoable command is adding one row to
// the table in undo_inverse.cpp (the structural ones, spawn, destroy, paste, reparent, are there too).
//
// Plain functions of (World, command name, args): no ImGui, no Editor, tested in undo_inverse_tests.cpp.
#pragma once

#include <optional>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/scene/world.h"
#include "undo_stack.h"

namespace fa::editor {

struct UndoPlan {
    std::vector<UndoCommand> forward;  // run in this order by redo
    std::vector<UndoCommand> inverse;  // run in this order by undo
    // The call changes nothing the scene keeps (a scene.set_parent to the place the entity already has): it runs, and
    // Editor::edit_command records no step and marks nothing dirty.
    bool noop = false;
};

// The plan of the call `name(args)` on the scene as it is now; nullopt when the command has no builder or its arguments
// do not describe an edit the builder understands (an unknown entity or component, a field that is not there): the caller
// then takes a snapshot, and the command itself reports what is wrong.
std::optional<UndoPlan> plan_undo(const World& world, const std::string& name, const Json& args);

// True when plan_undo gives a plan for the call, without building it: a destroy only checks what makes a plan impossible
// (Hierarchy delete asks it for every selected entity before the commands run).
bool has_undo_plan(const World& world, const std::string& name, const Json& args);

// True when `name` has a builder (some of its calls may still give no plan).
bool has_undo_builder(const std::string& name);

// Called with the command's result once it succeeded (`world` is the scene AFTER it), for a builder whose plan needs it: a
// spawn or a paste knows its ids only now, and its redo then re-creates exactly what the call made. Does nothing for the
// commands that need nothing from the result. False when the result is not what the builder expects: the plan is then
// unusable (the command ran, and nothing can undo it).
bool finish_undo_plan(const World& world, const std::string& name, UndoPlan& plan, const Json& result);

// How many terrain.undo calls of `entityId` the inverse list of `entry` holds (0 for any entry that is not a Command one).
std::size_t terrain_undo_count(const UndoEntry& entry, const std::string& entityId);
// What drop_terrain_steps removed.
struct TerrainDrop {
    std::size_t steps = 0;    // terrain.undo calls of the entity taken out of the list
    std::size_t entries = 0;  // entries that held nothing else to undo and left the list
};
// A terrain keeps its last kTerrainHistorySteps edits (and a byte budget): a step it let go can only answer "nothing to undo", and
// its entry would stand in front of older entries that still work. Takes out, oldest entry first, the terrain.undo calls of
// `entityId` (and the terrain.redo calls of it in the entry's forward list) until `steps` of them are gone (the number the terrain's
// history_lost() grew by). Only the terrain calls go: an entry that holds anything else to undo (a Chain of several edits) stays with
// that, and one left with no inverse at all leaves the list.
TerrainDrop drop_terrain_steps(UndoStack& stack, const std::string& entityId, std::size_t steps);

}  // namespace fa::editor
