// The inverse of an editing command, built from the scene as it is BEFORE the command runs (docs/EDITOR.md, "Undo entries").
//
// Editor::edit_command asks `plan_undo` for the command it is about to run. A plan holds the forward commands (what redo
// runs: the call itself, with the entity id spelled out) and the inverse commands (what undo runs). A command with no
// builder in the table gives no plan and keeps the snapshot path, so adding an undoable command is adding one row to
// the table in undo_inverse.cpp (M98.7e2 adds the structural ones: spawn, destroy, reparent...).
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
};

// The plan of the call `name(args)` on the scene as it is now; nullopt when the command has no builder or its arguments
// do not describe an edit the builder understands (an unknown entity or component, a field that is not there): the caller
// then takes a snapshot, and the command itself reports what is wrong.
std::optional<UndoPlan> plan_undo(const World& world, const std::string& name, const Json& args);

// True when `name` has a builder (some of its calls may still give no plan).
bool has_undo_builder(const std::string& name);

// Called with the command's result once it succeeded, for a builder whose inverse needs it (a spawn: the id the scene
// gave). Does nothing for the commands of this table that need nothing from the result.
void finish_undo_plan(const std::string& name, UndoPlan& plan, const Json& result);

}  // namespace fa::editor
