// The edits of PostProcess.customPasses the Post-processing panel offers (postfx_panel.cpp), as pure data: each
// function takes the array the target holds and returns the array to send in ONE postprocess.set call (the command
// replaces the whole array, so an add, a reorder, a removal and a param edit are each one undo step). No GPU, no world:
// tested in tests/postfx_custom_tests.cpp.
#pragma once

#include <cstddef>
#include <string>

#include "fa/core/json.h"

namespace fa::editor {

// `list` with a new entry (material `material`, position "before:tonemap", enabled) at the end. A `list` that is not an
// array counts as empty.
Json custom_pass_add(const Json& list, const std::string& material);

// The entry `index` moved `delta` places (-1 earlier, +1 later), stopping at the ends. An index out of range or a delta
// of 0 gives `list` back unchanged. Entries at the same position run in array order, so this is what "reorder" means in
// the panel.
Json custom_pass_move(const Json& list, std::size_t index, int delta);

// `list` without the entry `index` (out of range: unchanged).
Json custom_pass_remove(const Json& list, std::size_t index);

// The entry `index` with `key` (enabled, position, material, name) set to `value`; a null removes the key (back to its
// default). Setting `material` also drops the entry's params, which belong to the old material. Out of range:
// unchanged.
Json custom_pass_set(const Json& list, std::size_t index, const std::string& key, const Json& value);

// The entry `index` with the param `name` overridden by `value` (a null removes the override: the material's default
// shows again); an empty materialParams object is dropped. Out of range: unchanged.
Json custom_pass_set_param(const Json& list, std::size_t index, const std::string& name, const Json& value);

// The entry's own label: its name, else the file name of its material without ".material.json", else "(no material)".
std::string custom_pass_label(const Json& entry);

}  // namespace fa::editor
