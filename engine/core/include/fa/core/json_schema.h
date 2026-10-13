// Small JSON Schema validator (the subset FactorIA generates and uses):
// type (incl. arrays of types), properties, required, additionalProperties
// (bool or schema), items, enum, const, minimum, maximum, minItems, maxItems,
// minLength, pattern (ECMAScript regex), oneOf/anyOf, $ref to "#/$defs/..",
// default (applied by apply_defaults).
//
// Errors carry a JSON pointer and a fix hint so an AI can correct the input
// in one step, e.g.
//   /entities/3/components/Sprite/color: expected array or string, got number
#pragma once

#include <string>
#include <vector>

#include "fa/core/json.h"

namespace fa {

struct SchemaError {
    std::string pointer;  // JSON pointer into the validated value ("" = root)
    std::string message;
    std::string hint;
    std::string to_string() const;
};

std::vector<SchemaError> validate_json(const Json& schema, const Json& value);
// Fills missing properties that have a "default" in the schema (recursively).
void apply_schema_defaults(const Json& schema, Json& value);

}  // namespace fa
