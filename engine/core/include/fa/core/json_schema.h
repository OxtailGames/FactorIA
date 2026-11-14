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

#include <memory>
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

// A schema compiled once: `$ref`s resolved to their targets (recursive ones included), the keywords read out of the JSON, the
// defaults collected and every `pattern` held as its compiled regex. validate_json and apply_schema_defaults on it give the
// same result as on the Json it was built from (same errors: message, pointer and hint), without walking the Json, resolving
// a `$ref` or looking a keyword up on every call. It copies what it needs, so the Json may go away; it is immutable, cheap
// to copy (a shared pointer) and safe to use from any number of threads. Build it where a schema lives long (a command's
// inputSchema, compiled by CommandRegistry::add); for one validation of a schema that is parsed on the spot, the Json
// overloads are cheaper. A `pattern` that is not a valid regex is reported by validate_json at the same point as ever.
class CompiledSchema {
public:
    CompiledSchema() = default;  // accepts every value and has no defaults (what a null schema does)
    explicit CompiledSchema(const Json& schema);
    // True when apply_schema_defaults can add something to some value: callers skip copying a value that cannot change.
    bool has_defaults() const;

private:
    struct Impl;
    std::shared_ptr<const Impl> impl_;
    friend std::vector<SchemaError> validate_json(const CompiledSchema& schema, const Json& value);
    friend void apply_schema_defaults(const CompiledSchema& schema, Json& value);
};

std::vector<SchemaError> validate_json(const CompiledSchema& schema, const Json& value);
void apply_schema_defaults(const CompiledSchema& schema, Json& value);

}  // namespace fa
