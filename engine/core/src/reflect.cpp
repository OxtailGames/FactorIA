#include "fa/core/reflect.h"

#include <cmath>

#include "fa/core/strings.h"

namespace fa {

const char* field_kind_name(FieldKind k) {
    switch (k) {
        case FieldKind::Bool: return "bool";
        case FieldKind::Int: return "int";
        case FieldKind::Float: return "float";
        case FieldKind::String: return "string";
        case FieldKind::Vec2: return "vec2";
        case FieldKind::Vec3: return "vec3";
        case FieldKind::Vec4: return "vec4";
        case FieldKind::Color: return "color";
        case FieldKind::Rect: return "rect";
        case FieldKind::Entity: return "entity";
        case FieldKind::Enum: return "enum";
        case FieldKind::Asset: return "asset";
        case FieldKind::Json: return "json";
    }
    return "?";
}

const FieldInfo* TypeInfo::field(std::string_view fieldName) const {
    for (const FieldInfo& f : fields)
        if (f.name == fieldName) return &f;
    return nullptr;
}

DefaultObject::DefaultObject(const TypeInfo& t) : t_(&t) {
    p_ = ::operator new(t.size, std::align_val_t(t.align));
    t.construct(p_);
}
DefaultObject::~DefaultObject() {
    t_->destruct(p_);
    ::operator delete(p_, std::align_val_t(t_->align));
}

// ------------------------------------------------------------ registry --
TypeRegistry& TypeRegistry::global() {
    static TypeRegistry registry;
    return registry;
}

TypeInfo& TypeRegistry::add_raw(std::unique_ptr<TypeInfo> info) {
    info->id = TypeId(types_.size());
    types_.push_back(std::move(info));
    return *types_.back();
}

const TypeInfo* TypeRegistry::find(std::string_view name) const {
    for (const auto& t : types_)
        if (t->name == name) return t.get();
    return nullptr;
}

const TypeInfo* TypeRegistry::find_ci(std::string_view name) const {
    if (const TypeInfo* exact = find(name)) return exact;
    for (const auto& t : types_)
        if (iequals(t->name, name)) return t.get();
    return nullptr;
}

const TypeInfo* TypeRegistry::get(TypeId id) const { return id < types_.size() ? types_[id].get() : nullptr; }

std::vector<const TypeInfo*> TypeRegistry::all() const {
    std::vector<const TypeInfo*> out;
    out.reserve(types_.size());
    for (const auto& t : types_) out.push_back(t.get());
    return out;
}

std::vector<std::string> TypeRegistry::names() const {
    std::vector<std::string> out;
    for (const auto& t : types_) out.push_back(t->name);
    return out;
}

std::string TypeRegistry::suggest(std::string_view unknownName) const {
    return closest_match(unknownName, names());
}

Json TypeRegistry::describe_all() const {
    Json arr = Json::array();
    for (const auto& t : types_) arr.push_back(type_describe(*t));
    return arr;
}

// --------------------------------------------------------------- fields --
namespace {

template <class T>
const T& as(const FieldInfo& f, const void* object) {
    return *static_cast<const T*>(f.ptr(object));
}
template <class T>
T& as(const FieldInfo& f, void* object) {
    return *static_cast<T*>(f.ptr(object));
}

std::string enum_list(const FieldInfo& f) {
    std::string out;
    for (std::size_t i = 0; i < f.enumNames.size(); ++i) {
        if (i) out += ", ";
        out += "\"" + f.enumNames[i] + "\"";
    }
    return out;
}

bool has_range(const FieldInfo& f) { return f.minValue != f.maxValue; }

std::string kind_expectation(const FieldInfo& f) {
    switch (f.kind) {
        case FieldKind::Bool: return "true or false";
        case FieldKind::Int: return "an integer";
        case FieldKind::Float: return "a number";
        case FieldKind::String: return "a string";
        case FieldKind::Vec2: return "[x, y] or {\"x\":..,\"y\":..}";
        case FieldKind::Vec3: return "[x, y, z] or {\"x\":..,\"y\":..,\"z\":..}";
        case FieldKind::Vec4: return "[x, y, z, w]";
        case FieldKind::Color: return "[r, g, b, a] (0..1), \"#rrggbb\" or a color name";
        case FieldKind::Rect: return "[x, y, w, h]";
        case FieldKind::Entity: return "an entity id string";
        case FieldKind::Enum: return "one of " + enum_list(f);
        case FieldKind::Asset: return "an asset path string" + (f.assetType.empty() ? "" : " (" + f.assetType + ")");
        case FieldKind::Json: return "any JSON value";
    }
    return "?";
}

Error field_error(const FieldInfo& f, const std::string& why) {
    std::string hint = "Expected " + kind_expectation(f) + ".";
    if (!f.doc.empty()) hint += " " + f.doc;
    return make_error("Field '" + f.name + "': " + why, hint);
}

// A number outside the field's range(): refused, never clamped on the side (a file that says 200 while the game
// shows 64 would be a silent lie). The hint gives the allowed interval and the nearest allowed value.
Error range_error(const FieldInfo& f, double value) {
    auto number = [](double v) {  // 3, 0.001, 179: no trailing ".0"
        const Json j = to_json(float(v));
        const double d = j.get<double>();
        return d == std::floor(d) && std::fabs(d) < 1e15 ? std::to_string(std::int64_t(d)) : j.dump();
    };
    const std::string lo = number(f.minValue), hi = number(f.maxValue), text = number(value);
    std::string hint = "Use a value from " + lo + " to " + hi + " (both allowed); the nearest is " +
                       (value < f.minValue ? lo : hi) + ".";
    if (!f.doc.empty()) hint += " " + f.doc;
    return make_error("Field '" + f.name + "': value " + text + " is outside the allowed range " + lo + ".." + hi, hint);
}

}  // namespace

Result<void> check_range(const FieldInfo& f, double value) {
    if (has_range(f) && (value < f.minValue || value > f.maxValue)) return range_error(f, value);
    return {};
}

Json field_to_json(const FieldInfo& f, const void* o) {
    switch (f.kind) {
        case FieldKind::Bool: return as<bool>(f, o);
        case FieldKind::Int: return as<std::int32_t>(f, o);
        case FieldKind::Float: return to_json(as<float>(f, o));
        case FieldKind::String:
        case FieldKind::Asset: return as<std::string>(f, o);
        case FieldKind::Vec2: return to_json(as<Vec2>(f, o));
        case FieldKind::Vec3: return to_json(as<Vec3>(f, o));
        case FieldKind::Vec4: return to_json(as<Vec4>(f, o));
        case FieldKind::Color: return to_json(as<Color>(f, o));
        case FieldKind::Rect: return to_json(as<Rect>(f, o));
        case FieldKind::Entity: {
            // Raw handle; fa_scene replaces this with the entity's string id.
            Entity e = as<Entity>(f, o);
            return e.is_null() ? Json(nullptr) : Json(e.bits());
        }
        case FieldKind::Enum: {
            std::int32_t v = as<std::int32_t>(f, o);
            if (v >= 0 && std::size_t(v) < f.enumNames.size()) return f.enumNames[std::size_t(v)];
            return v;
        }
        case FieldKind::Json: return as<Json>(f, o);
    }
    return nullptr;
}

Result<void> field_from_json(const FieldInfo& f, void* o, const Json& value) {
    std::string err;
    auto bad = [&]() -> Result<void> { return field_error(f, err); };
    switch (f.kind) {
        case FieldKind::Bool: {
            bool v;
            if (!json_to(value, v, &err)) return bad();
            as<bool>(f, o) = v;
            return {};
        }
        case FieldKind::Int: {
            int v;
            if (!json_to(value, v, &err)) return bad();
            if (has_range(f) && (float(v) < f.minValue || float(v) > f.maxValue)) return range_error(f, v);
            as<std::int32_t>(f, o) = v;
            return {};
        }
        case FieldKind::Float: {
            float v;
            if (!json_to(value, v, &err)) return bad();
            if (has_range(f) && (v < f.minValue || v > f.maxValue)) return range_error(f, v);
            as<float>(f, o) = v;
            return {};
        }
        case FieldKind::String:
        case FieldKind::Asset: {
            std::string v;
            if (!json_to(value, v, &err)) return bad();
            as<std::string>(f, o) = std::move(v);
            return {};
        }
        case FieldKind::Vec2: {
            Vec2 v;
            if (!json_to(value, v, &err)) return bad();
            as<Vec2>(f, o) = v;
            return {};
        }
        case FieldKind::Vec3: {
            Vec3 v;
            if (!json_to(value, v, &err)) return bad();
            as<Vec3>(f, o) = v;
            return {};
        }
        case FieldKind::Vec4: {
            Vec4 v;
            if (!json_to(value, v, &err)) return bad();
            as<Vec4>(f, o) = v;
            return {};
        }
        case FieldKind::Color: {
            Color v;
            if (!json_to(value, v, &err)) return bad();
            as<Color>(f, o) = v;
            return {};
        }
        case FieldKind::Rect: {
            Rect v;
            if (!json_to(value, v, &err)) return bad();
            as<Rect>(f, o) = v;
            return {};
        }
        case FieldKind::Entity:
            if (value.is_null()) {  // clearing a reference needs no scene lookup
                as<Entity>(f, o) = kNullEntity;
                return {};
            }
            return make_error("Field '" + f.name + "' references another entity and cannot be set through generic reflection",
                              "Resolve entity ids through fa_scene: use fa::patch_component(world, entity, type, fields) "
                              "or load the scene/prefab JSON.");
        case FieldKind::Enum: {
            if (value.is_string()) {
                const std::string& s = value.get_ref<const std::string&>();
                for (std::size_t i = 0; i < f.enumNames.size(); ++i) {
                    if (iequals(f.enumNames[i], s)) {
                        as<std::int32_t>(f, o) = std::int32_t(i);
                        return {};
                    }
                }
                err = "unknown value \"" + s + "\".";
                std::string tail = did_you_mean(s, f.enumNames);
                return make_error("Field '" + f.name + "': " + err, tail);
            }
            if (value.is_number_integer() || value.is_number_unsigned()) {
                std::int64_t i = value.get<std::int64_t>();
                if (i >= 0 && std::size_t(i) < f.enumNames.size()) {
                    as<std::int32_t>(f, o) = std::int32_t(i);
                    return {};
                }
                err = "index " + std::to_string(i) + " is out of range (0.." + std::to_string(f.enumNames.size() - 1) + ").";
                return make_error("Field '" + f.name + "': " + err, "Use one of " + enum_list(f) + ".");
            }
            err = "expected a string, got " + describe_json_value(value);
            return bad();
        }
        case FieldKind::Json:
            as<Json>(f, o) = value;
            return {};
    }
    return make_error("Unsupported field kind");
}

Json object_to_json(const TypeInfo& t, const void* object, bool includeDefaults, bool includeRuntime) {
    Json out = Json::object();
    std::unique_ptr<DefaultObject> def;
    if (!includeDefaults) def = std::make_unique<DefaultObject>(t);
    for (const FieldInfo& f : t.fields) {
        if (!f.serialized && !includeRuntime) continue;
        Json v = field_to_json(f, object);
        if (def && v == field_to_json(f, def->get())) continue;
        out[f.name] = std::move(v);
    }
    return out;
}

Result<void> object_patch_from_json(const TypeInfo& t, void* object, const Json& patch) {
    if (!patch.is_object()) {
        return make_error("Patch for '" + t.name + "' must be a JSON object of field values, got " + describe_json_value(patch),
                          "Example: {\"" + (t.fields.empty() ? std::string("field") : t.fields[0].name) + "\": ...}");
    }
    // Work on a copy so a bad value leaves the object untouched.
    DefaultObject scratch(t);
    t.copy_assign(scratch.get(), object);
    std::vector<std::string> fieldNames;
    for (const FieldInfo& f : t.fields) fieldNames.push_back(f.name);
    std::string messages, hint;
    auto note = [&](const Error& e) {
        if (!messages.empty()) messages += "; ";
        messages += e.message;
        if (hint.empty()) hint = e.hint;
    };
    for (auto it = patch.begin(); it != patch.end(); ++it) {
        const FieldInfo* f = t.field(it.key());
        if (!f) {
            note(make_error("Unknown field '" + it.key() + "' on " + t.name, did_you_mean(it.key(), fieldNames)));
            continue;
        }
        if (f->readOnly && it.value() == field_to_json(*f, scratch.get())) continue;  // echoing the current value is harmless
        if (f->readOnly) {
            note(make_error("Field '" + t.name + "." + f->name + "' is read-only",
                            "Read-only fields are maintained by the engine; remove it from the patch."));
            continue;
        }
        if (auto r = field_from_json(*f, scratch.get(), it.value()); !r) note(r.error());
    }
    if (!messages.empty()) return make_error(t.name + ": " + messages, hint);
    t.copy_assign(object, scratch.get());
    return {};
}

// --------------------------------------------------------------- schema --
namespace {

Json number_array_schema(int n) {
    return Json::object({{"type", "array"}, {"items", Json::object({{"type", "number"}})}, {"minItems", n}, {"maxItems", n}});
}

Json field_schema(const FieldInfo& f, const Json& def) {
    Json s = Json::object();
    switch (f.kind) {
        case FieldKind::Bool: s["type"] = "boolean"; break;
        case FieldKind::Int: s["type"] = "integer"; break;
        case FieldKind::Float: s["type"] = "number"; break;
        case FieldKind::String: s["type"] = "string"; break;
        case FieldKind::Asset:
            s["type"] = "string";
            s["x-assetType"] = f.assetType;
            break;
        case FieldKind::Vec2:
            s["anyOf"] = Json::array({number_array_schema(2), Json::object({{"type", "object"}})});
            break;
        case FieldKind::Vec3:
            s["anyOf"] = Json::array({number_array_schema(3), Json::object({{"type", "object"}})});
            break;
        case FieldKind::Vec4:
        case FieldKind::Rect:
            s["anyOf"] = Json::array({number_array_schema(4), Json::object({{"type", "object"}})});
            break;
        case FieldKind::Color:
            s["anyOf"] = Json::array({Json::object({{"type", "array"}, {"items", Json::object({{"type", "number"}})},
                                                    {"minItems", 3}, {"maxItems", 4}}),
                                      Json::object({{"type", "string"}})});
            break;
        case FieldKind::Entity:
            s["type"] = Json::array({"string", "null"});
            break;
        case FieldKind::Enum: {
            Json names = Json::array();
            for (const auto& n : f.enumNames) names.push_back(n);
            s["type"] = "string";
            s["enum"] = names;
            break;
        }
        case FieldKind::Json: break;
    }
    if (!f.doc.empty()) s["description"] = f.doc;
    if (has_range(f)) {
        s["minimum"] = to_json(f.minValue);
        s["maximum"] = to_json(f.maxValue);
    }
    if (f.kind != FieldKind::Entity) s["default"] = def;
    return s;
}

}  // namespace

Json type_json_schema(const TypeInfo& t) {
    DefaultObject def(t);
    Json props = Json::object();
    for (const FieldInfo& f : t.fields) {
        if (!f.serialized) continue;
        props[f.name] = field_schema(f, field_to_json(f, def.get()));
    }
    Json s = Json::object();
    s["type"] = "object";
    if (!t.doc.empty()) s["description"] = t.doc;
    s["properties"] = std::move(props);
    s["additionalProperties"] = false;
    return s;
}

Json type_describe(const TypeInfo& t) {
    DefaultObject def(t);
    Json fields = Json::array();
    for (const FieldInfo& f : t.fields) {
        Json j = Json::object();
        j["name"] = f.name;
        j["kind"] = field_kind_name(f.kind);
        j["doc"] = f.doc;
        if (f.kind != FieldKind::Entity) j["default"] = field_to_json(f, def.get());
        if (f.kind == FieldKind::Enum) {
            Json names = Json::array();
            for (const auto& n : f.enumNames) names.push_back(n);
            j["enum"] = names;
        }
        if (has_range(f)) {
            j["min"] = to_json(f.minValue);
            j["max"] = to_json(f.maxValue);
        }
        if (f.kind == FieldKind::Asset) j["assetType"] = f.assetType;
        if (f.readOnly) j["readOnly"] = true;
        if (!f.serialized) j["runtimeOnly"] = true;
        fields.push_back(std::move(j));
    }
    return Json::object({{"name", t.name}, {"doc", t.doc}, {"category", t.category}, {"fields", std::move(fields)}});
}

}  // namespace fa
