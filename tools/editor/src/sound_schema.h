// What the Sound panel's inspector knows about a sound patch's fields, read from the embedded schemas/sfx.schema.json (the same file editors and AIs
// validate patches with): which fields an object may have, their kind, range, default, choices and doc string. No ImGui. The panel draws one widget
// per field and every doc string is a tooltip, so the schema's descriptions ARE the inspector's help.
#pragma once

#include <optional>
#include <string>
#include <vector>

#include "fa/core/json.h"

namespace fa::editor {

struct SoundField {
    std::string key;
    std::string pointer;               // JSON pointer of the field in the patch
    std::string kind;                  // number, integer, boolean, enum, string, object, array, other
    std::string doc;
    std::optional<double> min, max;
    std::optional<Json> def;
    std::vector<std::string> choices;
    bool required = false;
    bool present = false;              // the patch has the field
    Json value;                        // its value when present
};

// The fields of the object at `pointer` of `patch` ("" = the patch itself), in the schema's order. A oneOf (an effect) is resolved by the value's "type".
std::vector<SoundField> sfx_fields(const Json& patch, const std::string& pointer);

// The kind, range and doc of the array at `pointer`, and of what it holds.
struct SoundArrayInfo {
    bool known = false;
    std::string itemKind;              // number, object, ...
    int minItems = 0, maxItems = 1000;
    std::string doc;
};
SoundArrayInfo sfx_array_info(const Json& patch, const std::string& pointer);

// The types an effect may have (filter, distortion, ...), for the "add effect" menu, and a starting value for each.
std::vector<std::string> sfx_effect_types();
// A starting value for something new at `pointer` of `patch` (an item of an array, or an absent object field): required fields filled with their
// default or lowest allowed value. `type` picks the kind of effect when the schema says oneOf.
Json sfx_new_value(const Json& patch, const std::string& pointer, const std::string& type = "");

// Rounds to what a slider can show.
double sound_round_to_step(double v, double min, double max);

}  // namespace fa::editor
