// fa::validate_json, apply_schema_defaults, CompiledSchema (run next to them: it must give the same errors and defaults),
// close_object_schemas and check_schema_patterns. The input is one of
//   <schema JSON>\n---\n<value JSON>      both come from the input
//   @<name>\n<value JSON>                 the value against schemas/<name>.schema.json of the repository (run from its root;
//                                         this is how real project, scene, sfx... files are checked against the real schemas)
//   <value JSON>                          the value against a schema that uses every keyword the validator knows
// A `pattern` in a schema taken from the input is dropped: schemas are written by the engine and by developers, never by
// the files being checked, and std::regex can need exponential time for a hostile pattern; a hostile VALUE against the real
// patterns is still tested.
#include <cstddef>
#include <cstdint>
#include <fstream>
#include <map>
#include <sstream>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/json_schema.h"
#include "fuzz_support.h"

namespace {

const char* const kBuiltinSchema = R"({
  "type": "object",
  "properties": {
    "name": {"type": "string", "minLength": 1, "pattern": "^[a-z][a-z0-9_]*$", "default": "x"},
    "n": {"type": ["integer", "null"], "minimum": 0, "maximum": 100},
    "list": {"type": "array", "items": {"$ref": "#/$defs/item"}, "minItems": 1, "maxItems": 8},
    "mode": {"enum": ["a", "b", 3, null]},
    "fixed": {"const": {"k": [1, 2]}},
    "either": {"oneOf": [{"type": "string"}, {"type": "number", "minimum": 1}]},
    "any": {"anyOf": [{"type": "boolean"}, {"$ref": "#/$defs/item"}]},
    "free": {"type": "object", "additionalProperties": {"type": "number"}}
  },
  "required": ["name"],
  "additionalProperties": false,
  "$defs": {"item": {"type": "object", "properties": {"id": {"type": "integer", "default": 0}, "kids": {"type": "array", "items": {"$ref": "#/$defs/item"}}}}}
})";

void drop_patterns(fa::Json& j, int depth = 0) {
    if (depth > 200) return;
    if (j.is_object()) {
        j.erase("pattern");
        for (auto it = j.begin(); it != j.end(); ++it) drop_patterns(it.value(), depth + 1);
    } else if (j.is_array()) {
        for (auto& e : j) drop_patterns(e, depth + 1);
    }
}

const fa::Json* real_schema(const std::string& name) {
    static std::map<std::string, fa::Json> cache;
    if (name.empty() || name.size() > 40) return nullptr;
    for (char c : name)
        if (!((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '-')) return nullptr;
    if (auto it = cache.find(name); it != cache.end()) return it->second.is_null() ? nullptr : &it->second;
    std::ifstream in("schemas/" + name + ".schema.json", std::ios::binary);
    std::stringstream text;
    text << in.rdbuf();
    auto parsed = fa::parse_json(text.str(), name);
    return &(cache[name] = parsed ? parsed.value() : fa::Json());
}

}  // namespace

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) {
    static const bool once = (fa::fuzz::quiet(), true);
    (void)once;
    static const fa::Json builtin = fa::Json::parse(kBuiltinSchema);
    const std::string_view text = fa::fuzz::as_text(data, size);

    fa::Json own;  // a schema taken from the input
    const fa::Json* schema = &builtin;
    std::string_view valueText = text;
    if (!text.empty() && text[0] == '@') {
        const std::size_t eol = text.find('\n');
        const std::string name(text.substr(1, eol == std::string_view::npos ? text.size() : eol - 1));
        valueText = eol == std::string_view::npos ? std::string_view() : text.substr(eol + 1);
        const fa::Json* real = real_schema(name);
        if (!real) return 0;
        schema = real;
    } else if (const std::size_t sep = text.find("\n---\n"); sep != std::string_view::npos) {
        auto parsedSchema = fa::parse_json(text.substr(0, sep), "fuzz.schema.json");
        if (!parsedSchema) return 0;
        own = std::move(parsedSchema.value());
        drop_patterns(own);
        schema = &own;
        valueText = text.substr(sep + 5);
    }
    auto value = fa::parse_json(valueText, "fuzz.json");
    if (!value) return 0;

    // The compiled schema must answer exactly like the Json it was built from: same errors (pointer, message, hint), same
    // value once the defaults are applied.
    const fa::CompiledSchema compiled(*schema);
    const std::vector<fa::SchemaError> errors = fa::validate_json(*schema, value.value());
    const std::vector<fa::SchemaError> compiledErrors = fa::validate_json(compiled, value.value());
    for (const fa::SchemaError& e : errors) (void)e.to_string();
    if (errors.size() != compiledErrors.size()) fa::fuzz::fail("compiled schema: a different number of errors");
    for (std::size_t i = 0; i < errors.size(); ++i)
        if (errors[i].pointer != compiledErrors[i].pointer || errors[i].message != compiledErrors[i].message ||
            errors[i].hint != compiledErrors[i].hint)
            fa::fuzz::fail("compiled schema: an error differs from the interpreted one");
    fa::Json defaulted = value.value();
    fa::apply_schema_defaults(*schema, defaulted);
    fa::Json compiledDefaulted = value.value();
    fa::apply_schema_defaults(compiled, compiledDefaulted);
    if (defaulted != compiledDefaulted) fa::fuzz::fail("compiled schema: the defaults differ from the interpreted ones");
    if (!compiled.has_defaults() && defaulted != value.value())
        fa::fuzz::fail("compiled schema: has_defaults() is false but the defaults changed the value");
    (void)fa::validate_json(fa::close_object_schemas(*schema), defaulted);
    (void)fa::check_schema_patterns(*schema);
    return 0;
}
