// Runtime reflection for components and other data types.
//
// Reflection is the backbone of the AI-friendliness of FactorIA: ONE
// registration per component powers
//   * scene/prefab JSON load + save (fa_scene)
//   * the editor inspector (fa_editor)
//   * script access `entity.get("Sprite").color` (fa_script)
//   * MCP / CLI commands that read or patch components (fa_runtime)
//   * generated docs, JSON Schemas and TypeScript .d.ts (fa_tooling)
// so every field carries documentation that AIs read via `factoria api`.
//
// Registering a type:
//
//   struct Health { float current = 100; float max = 100; };
//
//   void register_my_types(fa::TypeRegistry& r) {
//       r.add<Health>("Health", "Hit points of a damageable entity.", "Gameplay")
//           .field("current", &Health::current, "Current hit points.").range(0, 1000)
//           .field("max", &Health::max, "Maximum hit points.");
//   }
//
// Supported field C++ types -> FieldKind:
//   bool->Bool, int/int32->Int, float->Float, std::string->String,
//   Vec2/Vec3/Vec4/Color/Rect, fa::Entity->Entity, fa::Json->Json,
//   any `enum class E : int32_t`->Enum (via .enum_field), std::string asset
//   paths->Asset (via .asset_field).
#pragma once

#include <cstddef>
#include <initializer_list>
#include <memory>
#include <new>
#include <string>
#include <string_view>
#include <type_traits>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"

namespace fa {

enum class FieldKind : std::uint8_t {
    Bool, Int, Float, String, Vec2, Vec3, Vec4, Color, Rect, Entity, Enum, Asset, Json
};
const char* field_kind_name(FieldKind k);  // "bool", "int", "float", "string", "vec2", ...

struct FieldInfo {
    std::string name;          // JSON / script key, camelCase
    FieldKind kind = FieldKind::Float;
    std::size_t offset = 0;    // byte offset inside the owning struct
    std::string doc;           // one or two sentences; shown to humans and AIs
    std::vector<std::string> enumNames;  // Enum: value i <-> enumNames[i] (lowercase)
    std::string assetType;     // Asset: "texture" | "mesh" | "audio" | "font" | "script" | "scene" | "prefab" | "any"
    float minValue = 0.0f;     // UI/validation hint; minValue == maxValue means unbounded
    float maxValue = 0.0f;
    bool serialized = true;    // false = runtime-only state (not saved to scenes)
    bool readOnly = false;     // scripts/tools may read but not write

    void* ptr(void* object) const { return static_cast<char*>(object) + offset; }
    const void* ptr(const void* object) const { return static_cast<const char*>(object) + offset; }
};

using TypeId = std::uint32_t;
inline constexpr TypeId kInvalidTypeId = UINT32_MAX;

struct TypeInfo {
    TypeId id = kInvalidTypeId;  // dense index in the registry (stable per process)
    std::string name;            // PascalCase, e.g. "Sprite"
    std::string doc;
    std::string category;        // grouping for docs/editor: "Core", "2D", "3D", "Physics", "Audio", "Gameplay"...
    std::size_t size = 0;
    std::size_t align = 0;
    std::vector<FieldInfo> fields;

    // Type-erased lifecycle (used by the ECS pools and serialization).
    void (*construct)(void* dst) = nullptr;               // placement default-construct
    void (*destruct)(void* obj) = nullptr;
    void (*copy_assign)(void* dst, const void* src) = nullptr;
    void (*move_construct)(void* dst, void* src) = nullptr;  // leaves src valid-but-unspecified

    const FieldInfo* field(std::string_view fieldName) const;
};

// A default-constructed instance of a reflected type (RAII; aligned storage).
class DefaultObject {
public:
    explicit DefaultObject(const TypeInfo& t);
    ~DefaultObject();
    DefaultObject(const DefaultObject&) = delete;
    DefaultObject& operator=(const DefaultObject&) = delete;
    void* get() { return p_; }
    const void* get() const { return p_; }

private:
    const TypeInfo* t_;
    void* p_;
};

// Generic field access (no entity references resolution — fa_scene handles Entity fields).
Json field_to_json(const FieldInfo& f, const void* object);
// Writes a JSON value into the field. Accepts the lenient forms from json.h and
// enum names. On failure returns an Error whose message names the field and the
// expected form. Entity fields are rejected here (resolve them in fa_scene).
Result<void> field_from_json(const FieldInfo& f, void* object, const Json& value);
// The field's range() check on its own (ok when the field has no range): the error field_from_json gives for a number
// outside it, for writers that do not go through JSON (script property writes).
Result<void> check_range(const FieldInfo& f, double value);
// Whole object <-> JSON object (unknown keys -> error with "did you mean" hint).
// includeDefaults=false omits fields equal to a default-constructed instance. Runtime-only
// fields (serialized == false) are skipped unless includeRuntime is true.
Json object_to_json(const TypeInfo& t, const void* object, bool includeDefaults = true, bool includeRuntime = false);
Result<void> object_patch_from_json(const TypeInfo& t, void* object, const Json& patch);
// JSON Schema (draft 2020-12 subset) describing the type's JSON form.
Json type_json_schema(const TypeInfo& t);
// Machine-readable description (name, doc, category, fields with kind/doc/default/enum/range).
Json type_describe(const TypeInfo& t);

template <class T>
class TypeBuilder;

class TypeRegistry {
public:
    // The process-wide registry used by the engine.
    static TypeRegistry& global();

    template <class T>
    TypeBuilder<T> add(std::string name, std::string doc, std::string category);

    const TypeInfo* find(std::string_view name) const;          // exact match
    const TypeInfo* find_ci(std::string_view name) const;       // case-insensitive
    const TypeInfo* get(TypeId id) const;
    template <class T>
    const TypeInfo* of() const {
        TypeId id = type_slot<T>();
        return id == kInvalidTypeId ? nullptr : get(id);
    }
    template <class T>
    TypeId id_of() const { return type_slot<T>(); }

    std::vector<const TypeInfo*> all() const;  // registration order
    std::vector<std::string> names() const;
    // "Unknown component 'Sprit'" -> suggestion "Sprite" (edit distance), or "".
    std::string suggest(std::string_view unknownName) const;

    Json describe_all() const;

private:
    template <class T>
    static TypeId& type_slot() {
        static TypeId id = kInvalidTypeId;
        return id;
    }
    TypeInfo& add_raw(std::unique_ptr<TypeInfo> info);
    std::vector<std::unique_ptr<TypeInfo>> types_;
};

namespace detail {
template <class T>
constexpr FieldKind kind_of() {
    if constexpr (std::is_same_v<T, bool>) return FieldKind::Bool;
    else if constexpr (std::is_same_v<T, int> || std::is_same_v<T, std::int32_t>) return FieldKind::Int;
    else if constexpr (std::is_same_v<T, float>) return FieldKind::Float;
    else if constexpr (std::is_same_v<T, std::string>) return FieldKind::String;
    else if constexpr (std::is_same_v<T, Vec2>) return FieldKind::Vec2;
    else if constexpr (std::is_same_v<T, Vec3>) return FieldKind::Vec3;
    else if constexpr (std::is_same_v<T, Vec4>) return FieldKind::Vec4;
    else if constexpr (std::is_same_v<T, Color>) return FieldKind::Color;
    else if constexpr (std::is_same_v<T, Rect>) return FieldKind::Rect;
    else if constexpr (std::is_same_v<T, Entity>) return FieldKind::Entity;
    else if constexpr (std::is_same_v<T, Json>) return FieldKind::Json;
    else static_assert(sizeof(T) == 0, "Unsupported reflected field type; see reflect.h");
}

template <class T, class M>
std::size_t offset_of(M T::*member) {
    // Computed on a real object: valid for non-standard-layout types too.
    static const T sample{};
    return std::size_t(reinterpret_cast<const char*>(&(sample.*member)) - reinterpret_cast<const char*>(&sample));
}
}  // namespace detail

template <class T>
class TypeBuilder {
public:
    explicit TypeBuilder(TypeInfo& info) : info_(&info) {}

    template <class M>
    TypeBuilder& field(const char* name, M T::*member, const char* doc) {
        FieldInfo f;
        f.name = name;
        f.kind = detail::kind_of<M>();
        f.offset = detail::offset_of(member);
        f.doc = doc;
        info_->fields.push_back(std::move(f));
        return *this;
    }

    // enum class E : int32_t { A, B, C } with names {"a", "b", "c"} (index = value).
    template <class E>
    TypeBuilder& enum_field(const char* name, E T::*member, std::initializer_list<const char*> names, const char* doc) {
        static_assert(std::is_enum_v<E> && sizeof(E) == sizeof(std::int32_t), "enum fields must be 32-bit enums");
        FieldInfo f;
        f.name = name;
        f.kind = FieldKind::Enum;
        f.offset = detail::offset_of(member);
        f.doc = doc;
        for (const char* n : names) f.enumNames.emplace_back(n);
        info_->fields.push_back(std::move(f));
        return *this;
    }

    // std::string holding a project-relative asset path ("assets/hero.png").
    TypeBuilder& asset_field(const char* name, std::string T::*member, const char* assetType, const char* doc) {
        FieldInfo f;
        f.name = name;
        f.kind = FieldKind::Asset;
        f.offset = detail::offset_of(member);
        f.doc = doc;
        f.assetType = assetType;
        info_->fields.push_back(std::move(f));
        return *this;
    }

    // Modifiers apply to the most recently added field.
    TypeBuilder& range(float lo, float hi) { last().minValue = lo; last().maxValue = hi; return *this; }
    TypeBuilder& runtime_only() { last().serialized = false; return *this; }
    TypeBuilder& read_only() { last().readOnly = true; return *this; }

    const TypeInfo& info() const { return *info_; }

private:
    FieldInfo& last() {
        FA_ASSERT(!info_->fields.empty(), "modifier used before any field");
        return info_->fields.back();
    }
    TypeInfo* info_;
};

template <class T>
TypeBuilder<T> TypeRegistry::add(std::string name, std::string doc, std::string category) {
    static_assert(std::is_default_constructible_v<T>, "reflected types must be default constructible");
    FA_ASSERT(type_slot<T>() == kInvalidTypeId, "type registered twice");
    auto info = std::make_unique<TypeInfo>();
    info->name = std::move(name);
    info->doc = std::move(doc);
    info->category = std::move(category);
    info->size = sizeof(T);
    info->align = alignof(T);
    info->construct = [](void* dst) { new (dst) T(); };
    info->destruct = [](void* obj) { static_cast<T*>(obj)->~T(); };
    info->copy_assign = [](void* dst, const void* src) { *static_cast<T*>(dst) = *static_cast<const T*>(src); };
    info->move_construct = [](void* dst, void* src) { new (dst) T(std::move(*static_cast<T*>(src))); };
    TypeInfo& stored = add_raw(std::move(info));
    type_slot<T>() = stored.id;
    return TypeBuilder<T>(stored);
}

}  // namespace fa
