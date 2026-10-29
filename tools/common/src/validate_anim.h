// Clip checks of `factoria validate` (docs/ANIMATION.md, "2D clips"): every *.anim.json of the project, and the clips each
// Animator of a scene or prefab names. Called by validate.cpp while the VFS root is the project.
#pragma once

#include <set>
#include <string>

#include "fa/core/json.h"
#include "fa/scene/world.h"
#include "fa/tooling/validate.h"

namespace fa::validate_detail {

// Each Animator of `world` (a loaded scene or prefab file `file`) that plays clip files: the file of every clip must exist
// and its tracks must resolve to parts of that entity. `source` is the file's JSON, used to point at the entity; the clip
// files found are added to `named`.
void check_animator_clips(const std::string& file, const World& world, const Json& source, std::set<std::string>& named,
                          ValidationReport& report);

// Every *.anim.json under the project (hidden folders, node_modules and a top-level build/ skipped) and every file in
// `named`: valid JSON and a valid clip (parse_anim_clip's own messages, with the JSON pointer inside the file).
void check_clip_files(const std::set<std::string>& named, ValidationReport& report);

}  // namespace fa::validate_detail
