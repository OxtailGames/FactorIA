#include "fa/core/json_schema.h"

#include <algorithm>
#include <cmath>
#include <deque>
#include <memory>
#include <mutex>
#include <regex>
#include <unordered_map>

#include "fa/core/strings.h"

namespace fa {

std::string SchemaError::to_string() const {
    std::string s = (pointer.empty() ? std::string("(root)") : pointer) + ": " + message;
    if (!hint.empty()) s += " (hint: " + hint + ")";
    return s;
}

namespace {

// Compiled `pattern` regexes, shared by every validation on every thread (validation runs on job threads). A
// std::regex is only read while it matches, so one compiled object serves any number of threads; the map is guarded.
// A pattern that does not compile is cached too (null). The cache holds at most kMaxPatterns patterns: past that it
// starts over, which only costs a recompile and never changes a result.
constexpr std::size_t kMaxPatterns = 512;

std::shared_ptr<const std::regex> compiled_pattern(const std::string& pattern) {
    static std::mutex mutex;
    static std::unordered_map<std::string, std::shared_ptr<const std::regex>> cache;
    {
        std::lock_guard<std::mutex> lock(mutex);
        if (auto it = cache.find(pattern); it != cache.end()) return it->second;
    }
    std::shared_ptr<const std::regex> re;  // compiled outside the lock: it is the slow part
    try {
        re = std::make_shared<const std::regex>(pattern, std::regex::ECMAScript);
    } catch (const std::regex_error&) {
    }
    std::lock_guard<std::mutex> lock(mutex);
    if (cache.size() >= kMaxPatterns) cache.clear();
    return cache.emplace(pattern, re).first->second;
}

struct Ctx {
    const Json& root;
    int depth = 0;
};

std::string escape_token(const std::string& s) {
    std::string out;
    for (char c : s) {
        if (c == '~')
            out += "~0";
        else if (c == '/')
            out += "~1";
        else
            out += c;
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
    if (it->is_string())
        out.push_back(it->get<std::string>());
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
        if (it->is_boolean())
            additionalAllowed = it->get<bool>();
        else if (it->is_object())
            additional = &*it;
    }
    for (auto it = value.begin(); it != value.end(); ++it) {
        std::string childPtr = ptr + "/" + escape_token(it.key());
        if (props && props->contains(it.key())) {
            validate_at(ctx, (*props)[it.key()], it.value(), childPtr, errors);
        } else if (additional) {
            validate_at(ctx, *additional, it.value(), childPtr, errors);
        } else if (!additionalAllowed) {
            // Valid: lists the accepted keys (up to 40), after a "Did you mean" for a near miss.
            const std::string hint = propNames.empty() ? std::string("This object takes no properties.")
                                                       : did_you_mean(it.key(), propNames, 40);
            add(errors, childPtr, "unknown property '" + it.key() + "'", hint);
        }
    }
}

void validate_at(Ctx& ctx, const Json& schemaIn, const Json& value, const std::string& ptr,
                 std::vector<SchemaError>& errors) {
    if (schemaIn.is_boolean()) {
        if (!schemaIn.get<bool>()) add(errors, ptr, "no value is allowed here");
        return;
    }
    if (!schemaIn.is_object()) return;
    if (++ctx.depth > 64) {
        --ctx.depth;
        return;
    }
    struct DepthGuard {
        Ctx& c;
        ~DepthGuard() { --c.depth; }
    } guard{ctx};

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
                if (e.is_string())
                    allowed.push_back(e.get<std::string>());
                else {
                    allStrings = false;
                    allowed.push_back(e.dump());
                }
            }
            std::string hint = value.is_string() && allStrings ? did_you_mean(value.get<std::string>(), allowed, 20)
                                                               : "Allowed values: " + join(allowed, ", ") + ".";
            add(errors, ptr, "value " + describe_json_value(value) + " is not one of the allowed values", hint);
        }
    }

    if (value.is_number()) {
        double v = value.get<double>();
        if (auto it = schema.find("minimum"); it != schema.end() && it->is_number() && v < it->get<double>())
            add(errors, ptr, "value " + value.dump() + " is below the minimum " + it->dump(),
                "Use a value >= " + it->dump() + ".");
        if (auto it = schema.find("maximum"); it != schema.end() && it->is_number() && v > it->get<double>())
            add(errors, ptr, "value " + value.dump() + " is above the maximum " + it->dump(),
                "Use a value <= " + it->dump() + ".");
    }

    if (value.is_string()) {
        const std::string& s = value.get_ref<const std::string&>();
        if (auto it = schema.find("minLength");
            it != schema.end() && it->is_number_unsigned() && s.size() < it->get<std::size_t>())
            add(errors, ptr, "string is too short (minimum length " + it->dump() + ")",
                "Provide at least " + it->dump() + " characters.");
        if (auto it = schema.find("pattern"); it != schema.end() && it->is_string()) {
            const std::string& pattern = it->get_ref<const std::string&>();
            if (auto re = compiled_pattern(pattern)) {
                // std::regex_search can throw regex_error (error_complexity / error_stack) on a long value; validation runs
                // outside the handler's try and on job threads, so it must never escape.
                bool matches = false, tooComplex = false;
                try {
                    matches = std::regex_search(s, *re);
                } catch (const std::regex_error&) {
                    tooComplex = true;
                }
                if (tooComplex)
                    add(errors, ptr,
                        "string " + describe_json_value(value) +
                            " is too long or too complex to check against the pattern " + it->dump(),
                        "Use a shorter value (" + std::to_string(s.size()) +
                            " characters here), or simplify the pattern in the schema.");
                else if (!matches)
                    add(errors, ptr,
                        "string " + describe_json_value(value) + " does not match the pattern " + it->dump(),
                        "Use a value matching /" + pattern + "/.");
            } else {
                add(errors, ptr, "schema error: invalid pattern " + it->dump(),
                    "The pattern must be an ECMAScript regular expression; fix the schema, not the value.");
            }
        }
    }

    if (value.is_array()) {
        if (auto it = schema.find("minItems");
            it != schema.end() && it->is_number_unsigned() && value.size() < it->get<std::size_t>())
            add(errors, ptr, "array has " + std::to_string(value.size()) + " items, minimum is " + it->dump(),
                "Provide at least " + it->dump() + " items.");
        if (auto it = schema.find("maxItems");
            it != schema.end() && it->is_number_unsigned() && value.size() > it->get<std::size_t>())
            add(errors, ptr, "array has " + std::to_string(value.size()) + " items, maximum is " + it->dump(),
                "Provide at most " + it->dump() + " items.");
        if (auto it = schema.find("items"); it != schema.end() && (it->is_object() || it->is_boolean()))
            for (std::size_t i = 0; i < value.size(); ++i)
                validate_at(ctx, *it, value[i], ptr + "/" + std::to_string(i), errors);
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

std::vector<SchemaError> check_schema_patterns(const Json& schema) {
    struct Node {
        const Json* json;
        std::string ptr;
        bool
            names;  // an object whose keys are names of properties or definitions (each value is a schema), not keywords
    };
    std::vector<SchemaError> errors;
    std::vector<Node> todo{{&schema, "", false}};
    // Walk every nested object and array of the schema, so a pattern in a property, in items, in $defs or in a branch is
    // found. The keywords that hold data (default, enum, const, examples) are skipped, but only as keywords: in
    // "properties" a property may well be called "default" and then holds a schema.
    while (!todo.empty()) {
        Node n = std::move(todo.back());
        todo.pop_back();
        if (n.json->is_object()) {
            for (auto it = n.json->begin(); it != n.json->end(); ++it) {
                std::string childPtr = n.ptr + "/" + escape_token(it.key());
                if (n.names) {
                    todo.push_back({&*it, std::move(childPtr), false});
                    continue;
                }
                const std::string& key = it.key();
                if (key == "pattern" && it->is_string()) {
                    if (!compiled_pattern(it->get_ref<const std::string&>()))
                        errors.push_back({childPtr,
                                          "invalid pattern " + it->dump() + " (not an ECMAScript regular expression)",
                                          "Fix the regular expression in the schema; every string checked against it "
                                          "would be rejected."});
                } else if (key != "default" && key != "enum" && key != "const" && key != "examples") {
                    const bool nameMap = it->is_object() && (key == "properties" || key == "$defs" ||
                                                             key == "definitions" || key == "patternProperties");
                    todo.push_back({&*it, std::move(childPtr), nameMap});
                }
            }
        } else if (n.json->is_array()) {
            for (std::size_t i = 0; i < n.json->size(); ++i)
                todo.push_back({&(*n.json)[i], n.ptr + "/" + std::to_string(i), false});
        }
    }
    return errors;
}

std::vector<SchemaError> validate_json(const Json& schema, const Json& value) {
    std::vector<SchemaError> errors;
    Ctx ctx{schema};
    validate_at(ctx, schema, value, "", errors);
    return errors;
}

void apply_schema_defaults(const Json& schema, Json& value) { defaults_at(schema, schema, value, 0); }

// ---- Compiled schemas ---------------------------------------------------------------------------------------------------
// Every behaviour below mirrors the interpreted code above (validate_at, validate_object, validate_alternatives,
// defaults_at) keyword by keyword; test_json_schema.cpp and the json_schema fuzz target compare the two. Change one, change
// the other.

namespace schema_detail {

enum class TypeKind { Null, Boolean, String, Array, Object, Number, Integer, Unknown };

struct Node;

struct PropEntry {
    std::string name;
    const Node* node = nullptr;
    bool hasDefault = false;  // the property's own schema object has a "default" (a $ref is not followed, as before)
    Json defaultValue;
};

struct RequiredEntry {
    std::string name;
    std::string doc;  // the "description" of the property of that name in `properties`, "" when there is none
};

// The keywords of one schema object.
struct Body {
    std::vector<std::string> types;
    std::vector<TypeKind> typeKinds;
    std::string doc;  // "description"
    bool hasConst = false;
    Json constValue;
    bool hasEnum = false;
    std::vector<Json> enumValues;
    bool hasMinimum = false, hasMaximum = false;
    double minimum = 0, maximum = 0;
    Json minimumJson, maximumJson;  // dumped into the message as the schema wrote them (5 or 5.0)
    bool hasMinLength = false, hasMinItems = false, hasMaxItems = false;
    std::size_t minLength = 0, minItems = 0, maxItems = 0;
    bool hasPattern = false;
    std::string pattern;
    std::shared_ptr<const std::regex> regex;  // null: the pattern does not compile
    const Node* items = nullptr;              // an object or boolean "items"
    bool itemsIsObject = false;               // ...and only an object one carries defaults
    bool hasProps = false;
    std::vector<PropEntry> props;
    std::unordered_map<std::string, std::size_t> propIndex;
    std::vector<std::string> propNames;
    std::vector<RequiredEntry> required;
    const Node* additional = nullptr;  // "additionalProperties" as a schema
    bool additionalAllowed = true;     // "additionalProperties" as a boolean
    std::vector<const Node*> anyOf, oneOf;
};

struct Node {
    enum class Kind { Skip, True, False, Schema };
    Kind kind = Kind::Skip;  // Skip: neither an object nor a boolean, accepts everything
    bool hasRef = false;
    std::string ref;                  // the "$ref" text
    const Node* refTarget = nullptr;  // null: the reference does not resolve
    Body body;                        // used when !hasRef, or when another node's $ref points here
    bool relevant = false;            // apply_schema_defaults can add something below this node
};

}  // namespace schema_detail

struct CompiledSchema::Impl {
    std::deque<schema_detail::Node> nodes;  // stable addresses: nodes point at each other
    const schema_detail::Node* root = nullptr;
};

namespace {

using schema_detail::Body;
using schema_detail::Node;
using schema_detail::TypeKind;

TypeKind type_kind(const std::string& type) {
    if (type == "null") return TypeKind::Null;
    if (type == "boolean") return TypeKind::Boolean;
    if (type == "string") return TypeKind::String;
    if (type == "array") return TypeKind::Array;
    if (type == "object") return TypeKind::Object;
    if (type == "number") return TypeKind::Number;
    if (type == "integer") return TypeKind::Integer;
    return TypeKind::Unknown;
}

bool kind_matches(TypeKind kind, const Json& v) {
    switch (kind) {
        case TypeKind::Null: return v.is_null();
        case TypeKind::Boolean: return v.is_boolean();
        case TypeKind::String: return v.is_string();
        case TypeKind::Array: return v.is_array();
        case TypeKind::Object: return v.is_object();
        case TypeKind::Number: return v.is_number();
        case TypeKind::Integer:
            if (v.is_number_integer() || v.is_number_unsigned()) return true;
            return v.is_number_float() && v.get<double>() == std::floor(v.get<double>());
        case TypeKind::Unknown: break;
    }
    return true;  // unknown type keyword: do not reject
}

class Compiler {
public:
    Compiler(const Json& root, std::deque<Node>& nodes) : root_(root), nodes_(nodes) {}

    const Node* node_for(const Json& j) {
        if (auto it = memo_.find(&j); it != memo_.end()) return it->second;
        Node& n = nodes_.emplace_back();
        memo_.emplace(&j, &n);  // before the children: a recursive $ref finds this node
        // A schema nested deeper than kMaxDepth (a tool registered from JavaScript can send any depth) would use the native
        // stack: below that depth the node stays Skip, which accepts everything (the validator stops at 64 levels too).
        if (depth_ >= kMaxDepth) return &n;
        ++depth_;
        fill(n, j);
        --depth_;
        return &n;
    }

private:
    void fill(Node& n, const Json& j) {
        if (j.is_boolean()) {
            n.kind = j.get<bool>() ? Node::Kind::True : Node::Kind::False;
            return;
        }
        if (!j.is_object()) return;
        n.kind = Node::Kind::Schema;
        if (auto it = j.find("$ref"); it != j.end() && it->is_string()) {
            n.hasRef = true;
            n.ref = it->get<std::string>();
            if (!n.ref.empty() && n.ref[0] == '#') {
                if (const Json* target = json_at(root_, std::string_view(n.ref).substr(1)))
                    n.refTarget = node_for(*target);
            }
        }
        fill_body(n.body, j);
    }

    void fill_body(Body& b, const Json& j) {
        b.types = schema_types(j);
        for (const std::string& t : b.types) b.typeKinds.push_back(type_kind(t));
        b.doc = doc_of(j);
        if (auto it = j.find("const"); it != j.end()) {
            b.hasConst = true;
            b.constValue = *it;
        }
        if (auto it = j.find("enum"); it != j.end() && it->is_array()) {
            b.hasEnum = true;
            b.enumValues.assign(it->begin(), it->end());
        }
        if (auto it = j.find("minimum"); it != j.end() && it->is_number()) {
            b.hasMinimum = true;
            b.minimum = it->get<double>();
            b.minimumJson = *it;
        }
        if (auto it = j.find("maximum"); it != j.end() && it->is_number()) {
            b.hasMaximum = true;
            b.maximum = it->get<double>();
            b.maximumJson = *it;
        }
        if (auto it = j.find("minLength"); it != j.end() && it->is_number_unsigned()) {
            b.hasMinLength = true;
            b.minLength = it->get<std::size_t>();
        }
        if (auto it = j.find("pattern"); it != j.end() && it->is_string()) {
            b.hasPattern = true;
            b.pattern = it->get<std::string>();
            b.regex = compiled_pattern(b.pattern);
        }
        if (auto it = j.find("minItems"); it != j.end() && it->is_number_unsigned()) {
            b.hasMinItems = true;
            b.minItems = it->get<std::size_t>();
        }
        if (auto it = j.find("maxItems"); it != j.end() && it->is_number_unsigned()) {
            b.hasMaxItems = true;
            b.maxItems = it->get<std::size_t>();
        }
        if (auto it = j.find("items"); it != j.end() && (it->is_object() || it->is_boolean())) {
            b.items = node_for(*it);
            b.itemsIsObject = it->is_object();
        }
        const Json* props = nullptr;
        if (auto it = j.find("properties"); it != j.end() && it->is_object()) props = &*it;
        if (props) {
            b.hasProps = true;
            for (auto it = props->begin(); it != props->end(); ++it) {
                schema_detail::PropEntry e;
                e.name = it.key();
                e.node = node_for(it.value());
                if (it->is_object() && it->contains("default")) {
                    e.hasDefault = true;
                    e.defaultValue = (*it)["default"];
                }
                b.propIndex.emplace(e.name, b.props.size());
                b.propNames.push_back(e.name);
                b.props.push_back(std::move(e));
            }
        }
        if (auto it = j.find("required"); it != j.end() && it->is_array()) {
            for (const Json& r : *it) {
                if (!r.is_string()) continue;
                schema_detail::RequiredEntry e;
                e.name = r.get<std::string>();
                if (props && props->contains(e.name)) e.doc = doc_of((*props)[e.name]);
                b.required.push_back(std::move(e));
            }
        }
        if (auto it = j.find("additionalProperties"); it != j.end()) {
            if (it->is_boolean())
                b.additionalAllowed = it->get<bool>();
            else if (it->is_object())
                b.additional = node_for(*it);
        }
        for (const char* key : {"anyOf", "oneOf"}) {
            auto it = j.find(key);
            if (it == j.end() || !it->is_array()) continue;
            std::vector<const Node*>& out = key[0] == 'a' ? b.anyOf : b.oneOf;
            for (const Json& branch : *it) out.push_back(node_for(branch));
        }
    }

    static constexpr int kMaxDepth = 64;
    const Json& root_;
    std::deque<Node>& nodes_;
    std::unordered_map<const Json*, const Node*> memo_;
    int depth_ = 0;
};

// The body a node validates against: its own, or the one its $ref points at; null for a $ref that does not resolve.
const Body* effective_body(const Node& n) {
    if (!n.hasRef) return &n.body;
    return n.refTarget ? &n.refTarget->body : nullptr;
}

// Marks the nodes below which apply_schema_defaults can add a value: a property with a default, or a property or items
// schema of such a node. Propagated from the nodes that start it up the edges that point at them (a recursive $ref makes the
// graph cyclic, so each node is marked once): linear in the size of the graph, not a loop until nothing changes.
void mark_defaults(std::deque<Node>& nodes) {
    // The nodes whose relevance depends on `n`: the ones whose effective body has n as a property or items schema.
    std::unordered_map<const Node*, std::vector<Node*>> dependents;
    std::vector<Node*> todo;
    for (Node& n : nodes) {
        if (n.kind != Node::Kind::Schema) continue;
        const Body* b = effective_body(n);
        if (!b) continue;
        bool start = false;
        for (const schema_detail::PropEntry& p : b->props) {
            start = start || p.hasDefault;
            dependents[p.node].push_back(&n);
        }
        if (b->itemsIsObject) dependents[b->items].push_back(&n);
        if (start) {
            n.relevant = true;
            todo.push_back(&n);
        }
    }
    while (!todo.empty()) {
        const Node* done = todo.back();
        todo.pop_back();
        auto it = dependents.find(done);
        if (it == dependents.end()) continue;
        for (Node* d : it->second) {
            if (d->relevant) continue;
            d->relevant = true;
            todo.push_back(d);
        }
    }
}

// A JSON pointer built only when an error needs it: the validated value's path as a chain on the stack.
struct Path {
    const Path* parent;
    const std::string* key;  // an object member, or null for an array index
    std::size_t index;
};

std::string render(const Path* p) {
    std::vector<const Path*> chain;
    for (; p; p = p->parent) chain.push_back(p);
    std::string out;
    for (auto it = chain.rbegin(); it != chain.rend(); ++it) {
        out += '/';
        out += (*it)->key ? escape_token(*(*it)->key) : std::to_string((*it)->index);
    }
    return out;
}

void add(std::vector<SchemaError>& errors, const Path* path, std::string message, std::string hint = {}) {
    errors.push_back({render(path), std::move(message), std::move(hint)});
}

struct VCtx {
    int depth = 0;
};

void cvalidate(VCtx& ctx, const Node& node, const Json& value, const Path* path, std::vector<SchemaError>& errors);

void cvalidate_alternatives(VCtx& ctx, const std::vector<const Node*>& branches, bool exactlyOne, const Json& value,
                            const Path* path, std::vector<SchemaError>& errors) {
    if (branches.empty()) return;
    int matched = 0;
    std::vector<std::vector<SchemaError>> branchErrors(branches.size());
    for (std::size_t i = 0; i < branches.size(); ++i) {
        cvalidate(ctx, *branches[i], value, path, branchErrors[i]);
        if (branchErrors[i].empty()) ++matched;
    }
    if (matched == 1 || (matched > 1 && !exactlyOne)) return;
    if (matched > 1) {
        add(errors, path, "value matches more than one of the allowed forms", "Make the value match exactly one form.");
        return;
    }
    // No branch matched. Which branches accept this JSON type at all?
    std::vector<std::size_t> typed;
    std::vector<std::string> expected;
    bool allTyped = true;
    for (std::size_t i = 0; i < branches.size(); ++i) {
        const Node& n = *branches[i];
        const Body* b = n.kind == Node::Kind::Schema ? effective_body(n) : nullptr;
        if (!b || b->types.empty()) allTyped = false;
        bool ok = false;
        if (b) {
            for (std::size_t t = 0; t < b->types.size(); ++t) {
                if (std::find(expected.begin(), expected.end(), b->types[t]) == expected.end())
                    expected.push_back(b->types[t]);
                ok |= kind_matches(b->typeKinds[t], value);
            }
        }
        if (ok) typed.push_back(i);
    }
    if (typed.size() == 1) {
        for (auto& e : branchErrors[typed[0]]) errors.push_back(std::move(e));
        return;
    }
    if (allTyped && typed.empty()) {
        add(errors, path, "expected " + or_list(expected) + ", got " + json_type_name(value));
        return;
    }
    std::string hint = "Accepted forms: ";
    for (std::size_t i = 0; i < branches.size(); ++i) {
        if (i) hint += "; ";
        hint += "(" + std::to_string(i + 1) + ") " + (branchErrors[i].empty() ? "ok" : branchErrors[i][0].message);
    }
    add(errors, path, "value does not match any of the allowed forms", hint);
}

void cvalidate_object(VCtx& ctx, const Body& b, const Json& value, const Path* path,
                      std::vector<SchemaError>& errors) {
    for (const schema_detail::RequiredEntry& r : b.required) {
        if (value.contains(r.name)) continue;
        std::string hint = "Add \"" + r.name + "\"";
        if (!r.doc.empty()) hint += " (" + r.doc + ")";
        hint += ".";
        // A near-miss spelling among the keys the caller did provide?
        std::vector<std::string> given;
        for (auto g = value.begin(); g != value.end(); ++g)
            if (std::find(b.propNames.begin(), b.propNames.end(), g.key()) == b.propNames.end())
                given.push_back(g.key());
        std::string near = closest_match(r.name, given);
        if (!near.empty()) hint += " You wrote '" + near + "', did you mean '" + r.name + "'?";
        add(errors, path, "missing required property '" + r.name + "'", hint);
    }

    for (auto it = value.begin(); it != value.end(); ++it) {
        const std::string& key = it.key();
        const Path child{path, &key, 0};
        if (auto p = b.propIndex.find(key); p != b.propIndex.end()) {
            cvalidate(ctx, *b.props[p->second].node, it.value(), &child, errors);
        } else if (b.additional) {
            cvalidate(ctx, *b.additional, it.value(), &child, errors);
        } else if (!b.additionalAllowed) {
            const std::string hint = b.propNames.empty() ? std::string("This object takes no properties.")
                                                         : did_you_mean(key, b.propNames, 40);
            add(errors, &child, "unknown property '" + key + "'", hint);
        }
    }
}

void cvalidate(VCtx& ctx, const Node& node, const Json& value, const Path* path, std::vector<SchemaError>& errors) {
    if (node.kind == Node::Kind::False) add(errors, path, "no value is allowed here");
    if (node.kind != Node::Kind::Schema) return;
    if (++ctx.depth > 64) {
        --ctx.depth;
        return;
    }
    struct DepthGuard {
        VCtx& c;
        ~DepthGuard() { --c.depth; }
    } guard{ctx};

    const Body* bp = effective_body(node);
    if (!bp) {
        add(errors, path, "schema error: cannot resolve $ref '" + node.ref + "'");
        return;
    }
    const Body& b = *bp;

    // type
    if (!b.types.empty()) {
        bool ok = false;
        for (TypeKind t : b.typeKinds) ok |= kind_matches(t, value);
        if (!ok) {
            std::string hint = "Provide a value of type " + or_list(b.types) + ".";
            if (!b.doc.empty()) hint += " " + b.doc;
            add(errors, path, "expected " + or_list(b.types) + ", got " + json_type_name(value), hint);
            return;  // further checks would only produce noise
        }
    }

    if (b.hasConst && value != b.constValue)
        add(errors, path, "value must be " + b.constValue.dump(), "Use exactly " + b.constValue.dump() + ".");

    if (b.hasEnum) {
        bool found = false;
        for (const Json& e : b.enumValues) found |= (e == value);
        if (!found) {
            std::vector<std::string> allowed;
            bool allStrings = true;
            for (const Json& e : b.enumValues) {
                if (e.is_string())
                    allowed.push_back(e.get<std::string>());
                else {
                    allStrings = false;
                    allowed.push_back(e.dump());
                }
            }
            std::string hint = value.is_string() && allStrings ? did_you_mean(value.get<std::string>(), allowed, 20)
                                                               : "Allowed values: " + join(allowed, ", ") + ".";
            add(errors, path, "value " + describe_json_value(value) + " is not one of the allowed values", hint);
        }
    }

    if (value.is_number()) {
        double v = value.get<double>();
        if (b.hasMinimum && v < b.minimum)
            add(errors, path, "value " + value.dump() + " is below the minimum " + b.minimumJson.dump(),
                "Use a value >= " + b.minimumJson.dump() + ".");
        if (b.hasMaximum && v > b.maximum)
            add(errors, path, "value " + value.dump() + " is above the maximum " + b.maximumJson.dump(),
                "Use a value <= " + b.maximumJson.dump() + ".");
    }

    if (value.is_string()) {
        const std::string& s = value.get_ref<const std::string&>();
        if (b.hasMinLength && s.size() < b.minLength)
            add(errors, path, "string is too short (minimum length " + std::to_string(b.minLength) + ")",
                "Provide at least " + std::to_string(b.minLength) + " characters.");
        if (b.hasPattern) {
            if (b.regex) {
                // std::regex_search can throw regex_error (error_complexity / error_stack) on a long value; validation runs
                // outside the handler's try and on job threads, so it must never escape.
                bool matches = false, tooComplex = false;
                try {
                    matches = std::regex_search(s, *b.regex);
                } catch (const std::regex_error&) {
                    tooComplex = true;
                }
                if (tooComplex)
                    add(errors, path,
                        "string " + describe_json_value(value) +
                            " is too long or too complex to check against the pattern " + Json(b.pattern).dump(),
                        "Use a shorter value (" + std::to_string(s.size()) +
                            " characters here), or simplify the pattern in the schema.");
                else if (!matches)
                    add(errors, path,
                        "string " + describe_json_value(value) + " does not match the pattern " +
                            Json(b.pattern).dump(),
                        "Use a value matching /" + b.pattern + "/.");
            } else {
                add(errors, path, "schema error: invalid pattern " + Json(b.pattern).dump(),
                    "The pattern must be an ECMAScript regular expression; fix the schema, not the value.");
            }
        }
    }

    if (value.is_array()) {
        if (b.hasMinItems && value.size() < b.minItems)
            add(errors, path,
                "array has " + std::to_string(value.size()) + " items, minimum is " + std::to_string(b.minItems),
                "Provide at least " + std::to_string(b.minItems) + " items.");
        if (b.hasMaxItems && value.size() > b.maxItems)
            add(errors, path,
                "array has " + std::to_string(value.size()) + " items, maximum is " + std::to_string(b.maxItems),
                "Provide at most " + std::to_string(b.maxItems) + " items.");
        if (b.items)
            for (std::size_t i = 0; i < value.size(); ++i) {
                const Path child{path, nullptr, i};
                cvalidate(ctx, *b.items, value[i], &child, errors);
            }
    }

    if (value.is_object()) cvalidate_object(ctx, b, value, path, errors);

    cvalidate_alternatives(ctx, b.anyOf, false, value, path, errors);
    cvalidate_alternatives(ctx, b.oneOf, true, value, path, errors);
}

void cdefaults(const Node& node, Json& value, int depth) {
    if (node.kind != Node::Kind::Schema || depth > 32 || !node.relevant) return;
    const Body* bp = effective_body(node);
    if (!bp) return;
    if (value.is_object()) {
        for (const schema_detail::PropEntry& p : bp->props) {
            auto found = value.find(p.name);
            if (found == value.end()) {
                if (p.hasDefault) value[p.name] = p.defaultValue;
            } else {
                cdefaults(*p.node, *found, depth + 1);
            }
        }
    } else if (value.is_array()) {
        if (bp->itemsIsObject)
            for (Json& e : value) cdefaults(*bp->items, e, depth + 1);
    }
}

}  // namespace

CompiledSchema::CompiledSchema(const Json& schema) {
    auto impl = std::make_shared<Impl>();
    Compiler compiler(schema, impl->nodes);
    impl->root = compiler.node_for(schema);
    mark_defaults(impl->nodes);
    impl_ = std::move(impl);
}

bool CompiledSchema::has_defaults() const { return impl_ && impl_->root->relevant; }

std::vector<SchemaError> validate_json(const CompiledSchema& schema, const Json& value) {
    std::vector<SchemaError> errors;
    if (!schema.impl_) return errors;
    VCtx ctx;
    cvalidate(ctx, *schema.impl_->root, value, nullptr, errors);
    return errors;
}

void apply_schema_defaults(const CompiledSchema& schema, Json& value) {
    if (schema.impl_) cdefaults(*schema.impl_->root, value, 0);
}

namespace {

void close_in_place(Json& schema, int depth) {
    if (!schema.is_object() || depth > 32) return;
    auto props = schema.find("properties");
    const bool hasProps = props != schema.end() && props->is_object();
    // Recurse first: adding a key to an ordered_json object may move its members, which would invalidate `props`.
    if (hasProps)
        for (auto it = props->begin(); it != props->end(); ++it) close_in_place(it.value(), depth + 1);
    if (hasProps && !schema.contains("additionalProperties")) schema["additionalProperties"] = false;
    if (auto it = schema.find("items"); it != schema.end()) {
        if (it->is_object())
            close_in_place(*it, depth + 1);
        else if (it->is_array())
            for (Json& e : *it) close_in_place(e, depth + 1);
    }
    if (auto it = schema.find("additionalProperties"); it != schema.end() && it->is_object())
        close_in_place(*it, depth + 1);
    for (const char* key : {"anyOf", "oneOf"}) {
        if (auto it = schema.find(key); it != schema.end() && it->is_array())
            for (Json& e : *it) close_in_place(e, depth + 1);
    }
    for (const char* key : {"$defs", "definitions"}) {
        if (auto it = schema.find(key); it != schema.end() && it->is_object())
            for (auto d = it->begin(); d != it->end(); ++d) close_in_place(d.value(), depth + 1);
    }
}

}  // namespace

Json close_object_schemas(Json schema) {
    close_in_place(schema, 0);
    return schema;
}

}  // namespace fa
