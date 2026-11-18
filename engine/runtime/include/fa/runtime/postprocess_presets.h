// The named post-processing looks of `postprocess.presets` / `postprocess.apply_preset` and of the editor's Post-processing panel.
// They are DATA, not code: engine/runtime/data/postprocess_presets.json, embedded in the binary, a list of {name, doc, fields} where
// `fields` are PostProcess fields (the camelCase names of api.components) with values in their range. A test checks that every
// field of every preset exists and is in range, so a preset cannot rot when a field is renamed.
#pragma once

#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"

namespace fa {

struct PostPreset {
    std::string name;
    std::string doc;
    Json fields;  // object: PostProcess field name -> value; only the fields the look changes (neutral has none)
};

// Every preset, in the order of the file (neutral first). Parsed once from the embedded JSON; an invalid file is an engine bug and
// trips an assertion (a test loads it).
const std::vector<PostPreset>& postprocess_presets();

// The preset called `name`, nullptr when there is none.
const PostPreset* find_postprocess_preset(std::string_view name);

// The PostProcess fields `postprocess.apply_preset` writes for `preset`: the preset's own fields, and unless `keep` first every
// effect field (not a volume's meta fields) at its default, so the result is exactly the look. The editor's undo of the command
// builds its plan from the same object.
Json postprocess_preset_fields(const PostPreset& preset, bool keep);

}  // namespace fa
