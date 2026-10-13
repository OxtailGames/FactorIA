#include "fa/core/json_schema.h"

#include <cmath>
#include <regex>

#include "fa/core/strings.h"

namespace fa {

std::string SchemaError::to_string() const {
    std::string s = (pointer.empty() ? std::string("(root)") : pointer) + ": " + message;
    if (!hint.empty()) s += " (hint: " + hint + ")";
    return s;
}

namespace {

struct Ctx {
    const Json& root;
    int depth = 0;
};

std::string escape_token(const std::string& s) {
    std::string out;
    for (char c : s) {
        if (c == '~') out += "~0";
        else if (c == '/') out += "~1";
        else out += c;
    }
    return out;
}

std::string json_type_name(const Json& v) {
    switch (v.type()) {
        case Json::value_t::null: return "null";
        case Json::value_t::boolean: return "boolean";
        case Json::value_t::string: return "string";
        case Json::value_t::number_integer:
        case Json::value_t::number_unsigned: return "integer";
        case Json::value_t::number_float: return "number";
        case Json::value_t::array: return "array";
        case Json::value_t::object: return "object";
        default: return "value";
    }
}

bool type_matches(const std::string& type, const Json& v) {
    if (type == "null") return v.is_null();
    if (type == "boolean") return v.is_boolean();
    if (type == "string") return v.is_string();
    if (type == "array") return v.is_array();
    if (type == "object") return v.is_object();
    if (type == "number") return v.is_number();
    if (type == "integer") {
        if (v.is_number_integer() || v.is_number_unsigned()) return true;
        return v.is_number_float() && v.get<double>() == std::floor(v.get<double>());
    }
    return true;  // unknown type keyword: do not reject
}

std::vector<std::string> schema_types(const Json& schema) {
    std::vector<std::string> out;
    auto it = schema.find("type");
    if (it == schema.end()) return out;
    if (it->is_string()) out.push_back(it->get<std::string>());
    else if (it->is_array())
        for (const Json& t : *it)
            if (t.is_string()) out.push_back(t.get<std::string>());
    return out;
}

std::string or_list(const std::vector<std::string>& v) {
    std::string out;
    for (std::size_t i = 0; i < v.size(); ++i) {
        if (i) out += i + 1 == v.size() ? " or " : ", ";
        out += v[i];
    }
    return out;
}

std::string doc_of(const Json& schema) {
    auto it = schema.find("description");
    return it != schema.end() && it->is_string() ? it->get<std::string>() : std::string();
}

// Follows "$ref": "#/$defs/Name" (any JSON pointer after '#').
const Json* resolve_ref(const Ctx& ctx, const Json& schema) {
    auto it = schema.find("$ref");
    if (it == schema.end() || !it->is_string()) return &schema;
    const std::string& ref = it->get_ref<const std::string&>();
    if (ref.empty() || ref[0] != '#') return nullptr;
    const Json* target = json_at(ctx.root, ref.substr(1));
    return target;
}

void validate_at(Ctx& ctx, const Json& schemaIn, const Json& value, const std::string& ptr,
                 std::vector<SchemaError>& errors);

void add(std::vector<SchemaError>& errors, const std::string& ptr, std::string message, std::string hint = {}) {
    errors.push_back({ptr, std::move(message), std::move(hint)});
}

// anyOf / oneOf: prefer reporting the single branch whose "type" matches the value.
void validate_alternatives(Ctx& ctx, const Json& branches, bool exactlyOne, const Json& value, const std::string& ptr,
                           std::vector<SchemaError>& errors) {
    if (!branches.is_array() || branches.empty()) return;
    int matched = 0;
    std::vector<std::vector<SchemaError>> branchErrors(branches.size());
    for (std::size_t i = 0; i < branches.size(); ++i) {
        validate_at(ctx, branches[i], value, ptr, branchErrors[i]);
        if (branchErrors[i].empty()) ++matched;
    }
    if (matched == 1 || (matched > 1 && !exactlyOne)) return;
    if (matched > 1) {
        add(errors, ptr, "value matches more than one of the allowed forms", "Make the value match exactly one form.");
        return;
    }
    // No branch matched. Which branches accept this JSON type at all?
    std::vector<std::size_t> typed;
    std::vector<std::string> expected;
    bool allTyped = true;
    for (std::size_t i = 0; i < branches.size(); ++i) {
        const Json* b = resolve_ref(ctx, branches[i]);
        std::vector<std::string> types = b ? schema_types(*b) : std::vector<std::string>();
        if (types.empty()) allTyped = false;
        bool ok = false;
        for (const std::string& t : types) {
            if (std::find(expected.begin(), expected.end(), t) == expected.end()) expected.push_back(t);
            ok |= type_matches(t, value);
        }
        if (ok) typed.push_back(i);
    }
    if (typed.size() == 1) {
        for (auto& e : branchErrors[typed[0]]) errors.push_back(std::move(e));
        return;
    }
    if (allTyped && typed.empty()) {
        add(errors, ptr, "expected " + or_list(expected) + ", got " + json_type_name(value));
        return;
    }
    std::string hint = "Accepted forms: ";
    for (std::size_t i = 0; i < branches.size(); ++i) {
        if (i) hint += "; ";
        hint += "(" + std::to_string(i + 1) + ") " + (branchErrors[i].empty() ? "ok" : branchErrors[i][0].message);
    }
    add(errors, ptr, "value does not match any of the allowed forms", hint);
}

void validate_object(Ctx& ctx, const Json& schema, const Json& value, const std::string& ptr,
                     std::vector<SchemaError>& errors) {
    const Json* props = nullptr;
    if (auto it = schema.find("properties"); it != schema.end() && it->is_object()) props = &*it;

    std::vector<std::string> propNames;
    if (props)
        for (auto it = props->begin(); it != props->end(); ++it) propNames.push_back(it.key());

    if (auto it = schema.find("required"); it != schema.end() && it->is_array()) {
        for (const Json& r : *it) {
            if (!r.is_string()) continue;
            const std::string& name = r.get_ref<const std::string&>();
            if (value.contains(name)) continue;
            std::string hint = "Add \"" + name + "\"";
            if (props && props->contains(name)) {
                std::string d = doc_of((*props)[name]);
                if (!d.empty()) hint += " (" + d + ")";
            }
            hint += ".";
            // A near-miss spelling among the keys the caller did provide?
            std::vector<std::string> given;
            for (auto g = value.begin(); g != value.end(); ++g)
                if (std::find(propNames.begin(), propNames.end(), g.key()) == propNames.end()) given.push_back(g.key());
            std::string near = closest_match(name, given);
            if (!near.empty()) hint += " You wrote '" + near + "', did you mean '" + name + "'?";
            add(errors, ptr, "missing required property '" + name + "'", hint);
        }
    }

    const Json* additional = nullptr;
    bool additionalAllowed = true;
    if (auto it = schema.find("additionalProperties"); it != schema.end()) {
        if (it->is_boolean()) additionalAllowed = it->get<bool>();
        else if (it->is_object()) additional = &*it;
    }
    for (auto it = value.begin(); it != value.end(); ++it) {
        std::string childPtr = ptr + "/" + escape_token(it.key());
        if (props && props->contains(it.key())) {
            validate_at(ctx, (*props)[it.key()], it.value(), childPtr, errors);
        } else if (additional) {
            validate_at(ctx, *additional, it.value(), childPtr, errors);
        } else if (!additionalAllowed) {
            add(errors, childPtr, "unknown property '" + it.key() + "'",
                propNames.empty() ? "This object takes no properties." : did_you_mean(it.key(), propNames));
        }
    }
}

void validate_at(Ctx& ctx, const Json& schemaIn, const Json& value, const std::string& ptr,
                 std::vector<SchemaError>& errors) {
    if (schemaIn.is_boolean()) {
        if (!schemaIn.get<bool>()) add(errors, ptr, "no value is allowed here");
        return;
    }
    if (!schemaIn.is_object() || ++ctx.depth > 64) { --ctx.depth; return; }
    struct DepthGuard { Ctx& c; ~DepthGuard() { --c.depth; } } guard{ctx};

    const Json* schemaPtr = resolve_ref(ctx, schemaIn);
    if (!schemaPtr) {
        add(errors, ptr, "schema error: cannot resolve $ref '" + schemaIn.value("$ref", "") + "'");
        return;
    }
    const Json& schema = *schemaPtr;

    // type
    std::vector<std::string> types = schema_types(schema);
    if (!types.empty()) {
        bool ok = false;
        for (const std::string& t : types) ok |= type_matches(t, value);
        if (!ok) {
            std::string hint = "Provide a value of type " + or_list(types) + ".";
            if (std::string d = doc_of(schema); !d.empty()) hint += " " + d;
            add(errors, ptr, "expected " + or_list(types) + ", got " + json_type_name(value), hint);
            return;  // further checks would only produce noise
        }
    }

    if (auto it = schema.find("const"); it != schema.end() && value != *it)
        add(errors, ptr, "value must be " + it->dump(), "Use exactly " + it->dump() + ".");

    if (auto it = schema.find("enum"); it != schema.end() && it->is_array()) {
        bool found = false;
        for (const Json& e : *it) found |= (e == value);
        if (!found) {
            std::vector<std::string> allowed;
            bool allStrings = true;
            for (const Json& e : *it) {
                if (e.is_string()) allowed.push_back(e.get<std::string>());
                else { allStrings = false; allowed.push_back(e.dump()); }
            }
            std::string hint = value.is_string() && allStrings ? did_you_mean(value.get<std::string>(), allowed, 20)
                                                               : "Allowed values: " + join(allowed, ", ") + ".";
            add(errors, ptr, "value " + describe_json_value(value) + " is not one of the allowed values", hint);
        }
    }

    if (value.is_number()) {
        double v = value.get<double>();
        if (auto it = schema.find("minimum"); it != schema.end() && it->is_number() && v < it->get<double>())
            add(errors, ptr, "value " + value.dump() + " is below the minimum " + it->dump(), "Use a value >= " + it->dump() + ".");
        if (auto it = schema.find("maximum"); it != schema.end() && it->is_number() && v > it->get<double>())
            add(errors, ptr, "value " + value.dump() + " is above the maximum " + it->dump(), "Use a value <= " + it->dump() + ".");
    }

    if (value.is_string()) {
        const std::string& s = value.get_ref<const std::string&>();
        if (auto it = schema.find("minLength"); it != schema.end() && it->is_number_unsigned() && s.size() < it->get<std::size_t>())
            add(errors, ptr, "string is too short (minimum length " + it->dump() + ")", "Provide at least " + it->dump() + " characters.");
        if (auto it = schema.find("pattern"); it != schema.end() && it->is_string()) {
            try {
                std::regex re(it->get<std::string>(), std::regex::ECMAScript);
                if (!std::regex_search(s, re))
                    add(errors, ptr, "string " + describe_json_value(value) + " does not match the pattern " + it->dump(),
                        "Use a value matching /" + it->get<std::string>() + "/.");
            } catch (const std::regex_error&) {
                add(errors, ptr, "schema error: invalid pattern " + it->dump());
            }
        }
    }

    if (value.is_array()) {
        if (auto it = schema.find("minItems"); it != schema.end() && it->is_number_unsigned() && value.size() < it->get<std::size_t>())
            add(errors, ptr, "array has " + std::to_string(value.size()) + " items, minimum is " + it->dump(),
                "Provide at least " + it->dump() + " items.");
        if (auto it = schema.find("maxItems"); it != schema.end() && it->is_number_unsigned() && value.size() > it->get<std::size_t>())
            add(errors, ptr, "array has " + std::to_string(value.size()) + " items, maximum is " + it->dump(),
                "Provide at most " + it->dump() + " items.");
        if (auto it = schema.find("items"); it != schema.end() && (it->is_object() || it->is_boolean()))
            for (std::size_t i = 0; i < value.size(); ++i) validate_at(ctx, *it, value[i], ptr + "/" + std::to_string(i), errors);
    }

    if (value.is_object()) validate_object(ctx, schema, value, ptr, errors);

    if (auto it = schema.find("anyOf"); it != schema.end()) validate_alternatives(ctx, *it, false, value, ptr, errors);
    if (auto it = schema.find("oneOf"); it != schema.end()) validate_alternatives(ctx, *it, true, value, ptr, errors);
}

void defaults_at(const Json& root, const Json& schemaIn, Json& value, int depth) {
    if (!schemaIn.is_object() || depth > 32) return;
    Ctx ctx{root};
    const Json* sp = resolve_ref(ctx, schemaIn);
    if (!sp) return;
    const Json& schema = *sp;
    if (value.is_object()) {
        if (auto props = schema.find("properties"); props != schema.end() && props->is_object()) {
            for (auto it = props->begin(); it != props->end(); ++it) {
                if (!value.contains(it.key())) {
                    if (it->is_object() && it->contains("default")) value[it.key()] = (*it)["default"];
                } else {
                    defaults_at(root, it.value(), value[it.key()], depth + 1);
                }
            }
        }
    } else if (value.is_array()) {
        if (auto items = schema.find("items"); items != schema.end() && items->is_object())
            for (Json& e : value) defaults_at(root, *items, e, depth + 1);
    }
}

}  // namespace

std::vector<SchemaError> validate_json(const Json& schema, const Json& value) {
    std::vector<SchemaError> errors;
    Ctx ctx{schema};
    validate_at(ctx, schema, value, "", errors);
    return errors;
}

void apply_schema_defaults(const Json& schema, Json& value) { defaults_at(schema, schema, value, 0); }

}  // namespace fa
