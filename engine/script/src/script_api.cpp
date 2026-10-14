// Machine-readable API description and TypeScript declarations. Both come from src/js/api.json (hand-written
// signatures + docs) plus the component types reflected in TypeRegistry (so new components appear automatically).
#include <algorithm>
#include <format>

#include "fa/core/reflect.h"
#include "script_internal.h"

namespace fa {

namespace {

struct Param {
    std::string name, type;
    bool optional = false, rest = false;
};
struct Sig {
    std::string name, typeParams, returns, type;  // returns for methods, type for properties
    std::vector<Param> params;
    bool isMethod = false, readonly = false, optional = false;
};

std::vector<std::string> split_top(const std::string& s, char sep) {
    std::vector<std::string> out;
    int depth = 0;
    std::string cur;
    for (size_t i = 0; i < s.size(); ++i) {
        char c = s[i];
        if (c == '<' || c == '(' || c == '{' || c == '[') ++depth;
        else if (c == '>' && !(i > 0 && s[i - 1] == '=')) --depth;
        else if (c == ')' || c == '}' || c == ']') --depth;
        if (c == sep && depth == 0) { out.push_back(cur); cur.clear(); }
        else cur += c;
    }
    if (!cur.empty() || !out.empty()) out.push_back(cur);
    for (auto& p : out) {
        size_t a = p.find_first_not_of(' ');
        size_t b = p.find_last_not_of(' ');
        p = a == std::string::npos ? "" : p.substr(a, b - a + 1);
    }
    return out;
}

Sig parse_sig(std::string s) {
    Sig r;
    if (s.rfind("readonly ", 0) == 0) { r.readonly = true; s = s.substr(9); }
    size_t i = 0;
    while (i < s.size() && (std::isalnum(static_cast<unsigned char>(s[i])) || s[i] == '_' || s[i] == '$')) ++i;
    r.name = s.substr(0, i);
    if (i < s.size() && s[i] == '?') { r.optional = true; ++i; }
    if (i < s.size() && (s[i] == '(' || s[i] == '<')) {
        r.isMethod = true;
        if (s[i] == '<') {
            int d = 0; size_t j = i;
            for (; j < s.size(); ++j) { if (s[j] == '<') ++d; else if (s[j] == '>') { if (--d == 0) break; } }
            r.typeParams = s.substr(i, j - i + 1);
            i = j + 1;
        }
        int d = 0; size_t j = i;
        for (; j < s.size(); ++j) { if (s[j] == '(') ++d; else if (s[j] == ')') { if (--d == 0) break; } }
        std::string inner = s.substr(i + 1, j - i - 1);
        for (const std::string& p : split_top(inner, ',')) {
            if (p.empty()) continue;
            Param pr;
            std::string t = p;
            if (t.rfind("...", 0) == 0) { pr.rest = true; t = t.substr(3); }
            size_t colon = t.find(':');
            std::string nm = colon == std::string::npos ? t : t.substr(0, colon);
            pr.type = colon == std::string::npos ? "any" : t.substr(colon + 1);
            if (!pr.type.empty() && pr.type[0] == ' ') pr.type.erase(0, 1);
            if (!nm.empty() && nm.back() == '?') { pr.optional = true; nm.pop_back(); }
            pr.name = nm;
            r.params.push_back(pr);
        }
        size_t colon = s.find(':', j);
        r.returns = colon == std::string::npos ? "void" : s.substr(colon + 1);
        if (!r.returns.empty() && r.returns[0] == ' ') r.returns.erase(0, 1);
    } else {
        size_t colon = s.find(':', i);
        r.type = colon == std::string::npos ? "any" : s.substr(colon + 1);
        if (!r.type.empty() && r.type[0] == ' ') r.type.erase(0, 1);
    }
    return r;
}

std::string jsdoc(const std::string& doc, const std::string& indent) {
    if (doc.empty()) return {};
    std::string out;
    size_t pos = 0;
    std::string body;
    while (pos <= doc.size()) {
        size_t nl = doc.find('\n', pos);
        std::string line = doc.substr(pos, nl == std::string::npos ? std::string::npos : nl - pos);
        size_t star;
        while ((star = line.find("*/")) != std::string::npos) line.replace(star, 2, "* /");
        body += indent + " * " + line + "\n";
        if (nl == std::string::npos) break;
        pos = nl + 1;
    }
    return indent + "/**\n" + body + indent + " */\n";
}

const Json& api_data() {
    static Json data = [] {
        Json j = Json::parse(embedded_script("api.json"), nullptr, false);
        return j.is_discarded() ? Json::object() : j;
    }();
    return data;
}

std::string lit_union(const std::vector<std::string>& names) {
    std::string out;
    for (size_t i = 0; i < names.size(); ++i) out += (i ? " | " : "") + Json(names[i]).dump();
    return out.empty() ? "string" : out;
}

std::string like_type(FieldKind k) {
    switch (k) {
        case FieldKind::Vec2: return "Vec2Like";
        case FieldKind::Vec3: return "Vec3Like";
        case FieldKind::Vec4: return "readonly number[] | { x: number; y: number; z: number; w: number }";
        case FieldKind::Color: return "ColorLike";
        case FieldKind::Rect: return "RectLike";
        default: return {};
    }
}

std::string value_type(const FieldInfo& f) {
    switch (f.kind) {
        case FieldKind::Bool: return "boolean";
        case FieldKind::Int:
        case FieldKind::Float: return "number";
        case FieldKind::String:
        case FieldKind::Asset: return "string";
        case FieldKind::Vec2: return "Vec2";
        case FieldKind::Vec3: return "Vec3";
        case FieldKind::Vec4: return "Vec3 & { w: number }";
        case FieldKind::Color: return "Color";
        case FieldKind::Rect: return "Rect";
        case FieldKind::Entity: return "Entity | null";
        case FieldKind::Enum: return lit_union(f.enumNames);
        case FieldKind::Json: return "any";
    }
    return "any";
}

std::string init_type(const FieldInfo& f) {
    switch (f.kind) {
        case FieldKind::Vec2: case FieldKind::Vec3: case FieldKind::Vec4: case FieldKind::Color: case FieldKind::Rect: return like_type(f.kind);
        case FieldKind::Entity: return "EntityLike";
        default: return value_type(f);
    }
}

std::string emit_member(const Json& mem, const std::string& indent, bool isStatic, bool inClass) {
    Sig s = parse_sig(mem.value("sig", ""));
    std::string doc = mem.value("doc", "");
    std::string out = jsdoc(doc, indent);
    out += indent;
    if (isStatic) out += "static ";
    if (s.readonly) out += "readonly ";
    out += s.name + (s.optional ? "?" : "");
    if (s.isMethod) {
        out += s.typeParams + "(";
        for (size_t i = 0; i < s.params.size(); ++i) {
            const Param& p = s.params[i];
            out += (i ? ", " : "") + std::string(p.rest ? "..." : "") + p.name + (p.optional ? "?" : "") + ": " + p.type;
        }
        out += "): " + s.returns + ";\n";
    } else {
        out += ": " + s.type + ";\n";
    }
    (void)inClass;
    return out;
}

std::string emit_item(const Json& it, const std::string& indent, bool inModule) {
    std::string kind = it.value("kind", "");
    std::string name = it.value("name", "");
    std::string doc = it.value("doc", "");
    std::string out;
    const std::string exp = inModule ? "export " : "";
    if (kind == "alias") {
        out += jsdoc(doc, indent) + indent + exp + "type " + name + " = " + it.value("type", "any") + ";\n";
    } else if (kind == "const") {
        out += jsdoc(doc, indent) + indent + exp + "const " + name + ": " + it.value("type", "any") + ";\n";
    } else if (kind == "function") {
        Sig s = parse_sig(it.value("sig", ""));
        out += jsdoc(doc, indent) + indent + exp + "function " + s.name + s.typeParams + "(";
        for (size_t i = 0; i < s.params.size(); ++i) {
            const Param& p = s.params[i];
            out += (i ? ", " : "") + std::string(p.rest ? "..." : "") + p.name + (p.optional ? "?" : "") + ": " + p.type;
        }
        out += "): " + s.returns + ";\n";
    } else if (kind == "interface" || kind == "class") {
        out += jsdoc(doc, indent) + indent + exp + (kind == "class" ? "class " : "interface ") + name;
        if (it.contains("generics")) out += "<" + it["generics"].get<std::string>() + ">";
        if (it.contains("extends")) out += " extends " + it["extends"].get<std::string>();
        out += " {\n";
        if (kind == "class" && it.contains("ctor")) out += indent + "  constructor(" + it["ctor"].get<std::string>() + ");\n";
        if (it.contains("members"))
            for (const Json& m : it["members"]) out += emit_member(m, indent + "  ", false, kind == "class");
        if (it.contains("statics"))
            for (const Json& m : it["statics"]) out += emit_member(m, indent + "  ", true, true);
        out += indent + "}\n";
    }
    return out;
}

// Interfaces for every reflected component (+ the name maps).
std::string emit_components() {
    std::string out;
    out += "  // ---- Components (generated from the engine's reflection registry) ----\n";
    for (const TypeInfo* t : TypeRegistry::global().all()) {
        out += jsdoc(t->doc + "\n\nCategory: " + t->category, "  ");
        out += "  export interface " + t->name + "Component {\n";
        for (const FieldInfo& f : t->fields) {
            std::string doc = f.doc;
            if (f.kind == FieldKind::Asset) doc += " (asset path: " + f.assetType + ")";
            if (f.readOnly) doc += " Read-only.";
            if (f.kind == FieldKind::Json) doc += " Returns a plain-object COPY; assign a new value to write.";
            out += jsdoc(doc, "    ");
            std::string lk = like_type(f.kind);
            if (f.kind == FieldKind::Entity) lk = "EntityLike";
            if (!lk.empty() && !f.readOnly) {
                out += "    get " + f.name + "(): " + value_type(f) + ";\n";
                out += "    set " + f.name + "(value: " + lk + ");\n";
            } else {
                out += std::string("    ") + (f.readOnly ? "readonly " : "") + f.name + ": " + value_type(f) + ";\n";
            }
        }
        out += "  }\n";
    }
    out += "  /** Component views by name, as returned by entity.get(name). */\n  export interface Components {\n";
    for (const TypeInfo* t : TypeRegistry::global().all()) out += "    " + t->name + ": " + t->name + "Component;\n";
    out += "  }\n";
    out += "  /** Field objects accepted by entity.add(name, fields) / entity.set(name, fields) and world.spawn. */\n  export interface ComponentInit {\n";
    for (const TypeInfo* t : TypeRegistry::global().all()) {
        out += "    " + t->name + ": {";
        bool first = true;
        for (const FieldInfo& f : t->fields) {
            if (f.readOnly) continue;
            out += std::string(first ? " " : "; ") + f.name + "?: " + init_type(f);
            first = false;
        }
        out += first ? " }" : " }";
        out += ";\n";
    }
    out += "  }\n";
    return out;
}

}  // namespace

std::string ScriptSystem::Impl::typescript_declarations() const {
    const Json& data = api_data();
    std::string out;
    out += "// Generated by `factoria api --dts`. Do not edit; regenerate after adding components or changing the engine.\n";
    out += "// Declares the \"factoria\" and \"factoria:test\" modules used by gameplay scripts, tools and tests.\n\n";
    if (!data.contains("modules")) return out;
    for (const Json& mod : data["modules"]) {
        std::string name = mod.value("name", "");
        out += jsdoc(mod.value("doc", ""), "");
        out += "declare module \"" + name + "\" {\n";
        if (name == "factoria:test") {
            out += "  import type { Entity, WorldAPI, TimeAPI, Json, Vec2Like, GamepadButton, GamepadAxis } from \"factoria\";\n";
        }
        for (const Json& it : mod["items"]) out += emit_item(it, "  ", true) + "\n";
        if (name == "factoria") out += emit_components();
        out += "}\n\n";
    }
    return out;
}

Json ScriptSystem::Impl::api_manifest() const {
    const Json& data = api_data();
    Json out = Json::object();
    out["format"] = "factoria.scripting-api/1";
    out["doc"] = "JavaScript (ES2023 modules, QuickJS). Behaviours extend Behaviour from \"factoria\". See docs/SCRIPTING.md.";
    Json mods = Json::array();
    if (data.contains("modules")) {
        for (const Json& mod : data["modules"]) {
            Json m = Json::object({{"name", mod.value("name", "")}, {"doc", mod.value("doc", "")}});
            Json exports = Json::array();
            auto member_json = [](const Json& mem) {
                Sig s = parse_sig(mem.value("sig", ""));
                Json j = Json::object({{"name", s.name}, {"doc", mem.value("doc", "")}});
                if (s.isMethod) {
                    j["kind"] = "method";
                    Json ps = Json::array();
                    for (const Param& p : s.params) ps.push_back(Json::object({{"name", p.name}, {"type", p.type}, {"optional", p.optional}, {"rest", p.rest}}));
                    j["params"] = ps;
                    j["returns"] = s.returns;
                } else {
                    j["kind"] = "property";
                    j["type"] = s.type;
                    j["readonly"] = s.readonly;
                }
                j["signature"] = mem.value("sig", "");
                return j;
            };
            for (const Json& it : mod["items"]) {
                std::string kind = it.value("kind", "");
                Json e = Json::object({{"kind", kind}, {"name", it.value("name", "")}, {"doc", it.value("doc", "")}});
                if (kind == "function") {
                    Json f = member_json(Json::object({{"sig", it.value("sig", "")}, {"doc", it.value("doc", "")}}));
                    f["kind"] = "function";
                    e = f;
                } else if (kind == "const") {
                    e["type"] = it.value("type", "any");
                } else if (kind == "alias") {
                    e["type"] = it.value("type", "any");
                } else {
                    Json members = Json::array(), statics = Json::array();
                    if (it.contains("members")) for (const Json& mm : it["members"]) members.push_back(member_json(mm));
                    if (it.contains("statics")) for (const Json& mm : it["statics"]) statics.push_back(member_json(mm));
                    e["members"] = members;
                    if (!statics.empty()) e["statics"] = statics;
                    if (it.contains("ctor")) e["constructor"] = it["ctor"];
                }
                exports.push_back(e);
            }
            m["exports"] = exports;
            mods.push_back(m);
        }
    }
    out["modules"] = mods;
    out["components"] = TypeRegistry::global().describe_all();
    out["lifecycle"] = Json::array({"onStart()", "onUpdate(dt)", "onFixedUpdate(dt)", "onLateUpdate(dt)", "onDestroy()",
                                    "onCollisionEnter(other, info)", "onCollisionExit(other)", "onTriggerEnter(other)",
                                    "onTriggerExit(other)", "onEvent(name, data, source)"});
    out["notes"] = Json::array({"Component views are live: body.velocity.x = 3 writes into the engine.",
                                "Enums are lowercase strings; asset fields are path strings; Json fields are plain-object copies.",
                                "Math.random is routed to the deterministic world RNG; prefer rng.*.",
                                "Callbacks that run longer than 2 s are aborted with 'script took too long'."});
    return out;
}

}  // namespace fa
