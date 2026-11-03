#include "sound_schema.h"

#include <algorithm>
#include <cmath>

#include "fa/tooling/bundle.h"

namespace fa::editor {

namespace {

const Json& schema() {
    static const Json s = [] {
        auto text = bundled_read("schemas/sfx.schema.json");
        if (!text) return Json::object();
        auto parsed = parse_json(*text, "schemas/sfx.schema.json");
        return parsed.ok() ? *parsed : Json::object();
    }();
    return s;
}

std::vector<std::string> split_pointer(const std::string& pointer) {
    std::vector<std::string> out;
    std::size_t i = 0;
    while (i < pointer.size()) {
        if (pointer[i] == '/') ++i;
        std::size_t j = pointer.find('/', i);
        if (j == std::string::npos) j = pointer.size();
        std::string t = pointer.substr(i, j - i);
        for (std::size_t k = 0; (k = t.find("~1", k)) != std::string::npos;) t.replace(k, 2, "/");
        for (std::size_t k = 0; (k = t.find("~0", k)) != std::string::npos;) t.replace(k, 2, "~");
        out.push_back(t);
        i = j;
    }
    return out;
}

// The schema node with its $ref and allOf folded in and, for a oneOf, the branch that `value` picks by its "type".
Json resolve(const Json& node, const Json* value, int depth = 0) {
    if (depth > 8 || !node.is_object()) return node;
    if (node.contains("$ref") && node["$ref"].is_string()) {
        const std::string ref = node["$ref"].get<std::string>();
        const std::string prefix = "#/$defs/";
        if (ref.rfind(prefix, 0) == 0 && schema().contains("$defs") && schema()["$defs"].contains(ref.substr(prefix.size()))) {
            Json target = resolve(schema()["$defs"][ref.substr(prefix.size())], value, depth + 1);
            for (auto it = node.begin(); it != node.end(); ++it)
                if (it.key() != "$ref") target[it.key()] = it.value();
            return target;
        }
    }
    if (node.contains("allOf") && node["allOf"].is_array() && !node["allOf"].empty()) {
        Json target = resolve(node["allOf"][0], value, depth + 1);
        for (auto it = node.begin(); it != node.end(); ++it)
            if (it.key() != "allOf") target[it.key()] = it.value();
        return target;
    }
    if (node.contains("oneOf") && node["oneOf"].is_array()) {
        const std::string type = value && value->is_object() ? value->value("type", std::string()) : std::string();
        for (const Json& branch : node["oneOf"]) {
            Json b = resolve(branch, value, depth + 1);
            if (b.contains("properties") && b["properties"].contains("type") && b["properties"]["type"].value("const", std::string()) == type && !type.empty()) return b;
        }
        for (const Json& branch : node["oneOf"]) {
            Json b = resolve(branch, value, depth + 1);
            if (b.is_object() && b.value("type", std::string()) == (value && value->is_number() ? "number" : "object")) return b;
        }
        return resolve(node["oneOf"][0], value, depth + 1);
    }
    return node;
}

// The schema node of `pointer` in `patch`, with its parent chain resolved against the values.
std::optional<Json> node_at(const Json& patch, const std::string& pointer) {
    Json node = resolve(schema(), &patch);
    const Json* value = &patch;
    for (const std::string& token : split_pointer(pointer)) {
        const Json* next = nullptr;
        if (value && value->is_object() && value->contains(token)) next = &(*value)[token];
        else if (value && value->is_array() && !token.empty() && std::all_of(token.begin(), token.end(), ::isdigit) && std::stoul(token) < value->size()) next = &(*value)[std::stoul(token)];
        Json child;
        if (node.contains("properties") && node["properties"].is_object() && node["properties"].contains(token)) child = node["properties"][token];
        else if (node.contains("items")) child = node["items"];
        else if (node.contains("additionalProperties") && node["additionalProperties"].is_object()) child = node["additionalProperties"];
        else return std::nullopt;
        node = resolve(child, next);
        value = next;
    }
    return node;
}

const Json* value_at(const Json& patch, const std::string& pointer) {
    try {
        const Json::json_pointer p(pointer);
        return patch.contains(p) ? &patch.at(p) : nullptr;
    } catch (const std::exception&) {
        return nullptr;
    }
}

std::string kind_of(const Json& node) {
    if (node.contains("enum")) return "enum";
    if (node.contains("const")) return "other";
    if (node.contains("oneOf")) return "other";
    const std::string t = node.value("type", std::string());
    if (t == "number" || t == "integer" || t == "boolean" || t == "string" || t == "object" || t == "array") return t;
    return "other";
}

}  // namespace

std::vector<SoundField> sfx_fields(const Json& patch, const std::string& pointer) {
    std::vector<SoundField> out;
    auto node = node_at(patch, pointer);
    if (!node || !node->contains("properties") || !(*node)["properties"].is_object()) return out;
    const Json* obj = pointer.empty() ? &patch : value_at(patch, pointer);
    Json required = node->contains("required") ? (*node)["required"] : Json::array();
    for (auto it = (*node)["properties"].begin(); it != (*node)["properties"].end(); ++it) {
        if (it.key() == "$schema" || it.key() == "format" || it.key() == "type") continue;
        if (pointer.empty() && it.key() == "macros") continue;  // the knobs
        const Json* childValue = obj && obj->is_object() && obj->contains(it.key()) ? &(*obj)[it.key()] : nullptr;
        const Json prop = resolve(it.value(), childValue);
        SoundField f;
        f.key = it.key();
        f.pointer = pointer + "/" + it.key();
        f.kind = kind_of(prop);
        f.doc = prop.value("description", std::string());
        if (prop.contains("minimum") && prop["minimum"].is_number()) f.min = prop["minimum"].get<double>();
        if (prop.contains("maximum") && prop["maximum"].is_number()) f.max = prop["maximum"].get<double>();
        if (prop.contains("default")) f.def = prop["default"];
        if (prop.contains("enum"))
            for (const Json& c : prop["enum"])
                if (c.is_string()) f.choices.push_back(c.get<std::string>());
        f.required = std::find(required.begin(), required.end(), Json(it.key())) != required.end();
        f.present = childValue != nullptr;
        if (childValue) f.value = *childValue;
        out.push_back(std::move(f));
    }
    return out;
}

SoundArrayInfo sfx_array_info(const Json& patch, const std::string& pointer) {
    SoundArrayInfo info;
    auto node = node_at(patch, pointer);
    if (!node || node->value("type", std::string()) != "array") return info;
    info.known = true;
    info.doc = node->value("description", std::string());
    info.minItems = node->value("minItems", 0);
    info.maxItems = node->value("maxItems", 1000);
    if (node->contains("items")) info.itemKind = kind_of(resolve((*node)["items"], nullptr));
    return info;
}

std::vector<std::string> sfx_effect_types() {
    std::vector<std::string> out;
    if (!schema().contains("$defs") || !schema()["$defs"].contains("effect")) return out;
    for (const Json& b : schema()["$defs"]["effect"].value("oneOf", Json::array()))
        if (b.contains("properties") && b["properties"].contains("type") && b["properties"]["type"].contains("const")) out.push_back(b["properties"]["type"]["const"].get<std::string>());
    return out;
}

Json sfx_new_value(const Json& patch, const std::string& pointer, const std::string& type) {
    // `pointer` names the new thing: /layers/1 (an array item), /layers/0/filter (an absent object), /master/effects/2.
    std::optional<Json> node;
    std::string parent = pointer.substr(0, pointer.find_last_of('/'));
    const std::string last = pointer.substr(pointer.find_last_of('/') + 1);
    auto p = node_at(patch, parent);
    if (p && p->value("type", std::string()) == "array" && p->contains("items")) {
        Json probe = Json::object({{"type", type}});
        node = resolve((*p)["items"], &probe);
    } else {
        node = node_at(patch, pointer);
    }
    if (!node) return Json::object();
    const std::string t = kind_of(*node);
    if (t == "array") return Json::array();
    if (t != "object") {
        if (node->contains("default")) return (*node)["default"];
        if (t == "boolean") return false;
        if (t == "string") return "";
        return node->contains("minimum") ? (*node)["minimum"] : Json(0);
    }
    Json out = Json::object();
    Json required = node->contains("required") ? (*node)["required"] : Json::array();
    for (const Json& r : required) {
        const std::string key = r.get<std::string>();
        if (!node->contains("properties") || !(*node)["properties"].contains(key)) continue;
        const Json prop = resolve((*node)["properties"][key], nullptr);
        if (key == "type" && !type.empty()) out[key] = type;
        else if (prop.contains("const")) out[key] = prop["const"];
        else if (prop.contains("default")) out[key] = prop["default"];
        else if (prop.contains("enum") && !prop["enum"].empty()) out[key] = prop["enum"][0];
        else if (kind_of(prop) == "object") out[key] = sfx_new_value(patch, pointer + "/" + key, "");
        else if (kind_of(prop) == "array") {
            Json arr = Json::array();
            if (prop.value("minItems", 0) > 0 && prop.contains("items") && prop["items"].is_object()) {
                const Json item = resolve(prop["items"], nullptr);
                if (kind_of(item) == "number") arr.push_back(0);
                for (int i = 1; i < prop.value("minItems", 0) && kind_of(item) == "number"; ++i) arr.push_back(0);
            }
            out[key] = arr;
        } else if (kind_of(prop) == "boolean") out[key] = false;
        else if (kind_of(prop) == "string") out[key] = "";
        else out[key] = prop.contains("minimum") ? prop["minimum"] : Json(0);
    }
    if (!type.empty() && !out.contains("type") && node->contains("properties") && (*node)["properties"].contains("type")) out["type"] = type;
    return out;
}

double sound_round_to_step(double v, double min, double max) {
    const double span = std::max(1e-9, max - min);
    const double step = span >= 1000 ? 1.0 : span >= 100 ? 0.1 : span >= 10 ? 0.01 : span >= 1 ? 0.001 : 0.0001;
    return std::round(v / step) * step;
}

}  // namespace fa::editor
