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
// Every `pattern` of the schema (at any depth) that is not a valid ECMAScript regex, with the pointer of the pattern. Empty
// when all compile. Compiled patterns are cached for the process (thread-safe), so validate_json compiles each pattern
// once, not once per value; this call compiles them ahead, so a bad pattern is reported when the schema is loaded.
std::vector<SchemaError> check_schema_patterns(const Json& schema);
// Returns `schema` with every object schema that declares "properties" but no "additionalProperties" closed
// ("additionalProperties": false), at the root and in nested schemas (properties, items, anyOf/oneOf, $defs, an
// additionalProperties schema). A schema that says "additionalProperties": true (or gives a schema) stays open: that is
// the explicit opt-out for objects that really take open-ended keys. Objects with no "properties" at all are left alone.
// CommandRegistry::add applies it to every command's inputSchema, so what describe/MCP show is what call enforces.
Json close_object_schemas(Json schema);
// Fills missing properties that have a "default" in the schema (recursively).
void apply_schema_defaults(const Json& schema, Json& value);

}  // namespace fa
