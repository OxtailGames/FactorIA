#include "undo_inverse.h"

#include <algorithm>

#include "fa/core/reflect.h"
#include "fa/scene/components.h"
#include "fa/scene/serialize.h"

namespace fa::editor {

namespace {

using Builder = std::optional<UndoPlan> (*)(const World&, const Json&);
using Finisher = void (*)(UndoPlan&, const Json& result);

struct BuilderRow {
    const char* name;
    Builder build;
    Finisher finish;  // null when the plan needs nothing from the result
};

// The entity and component type a scene.set_component / scene.remove_component call names, or false.
struct Target {
    Entity entity;
    std::string id;  // the canonical id: the call may name the entity by its display name
    const TypeInfo* type = nullptr;
};

bool resolve_target(const World& world, const Json& a, Target& out) {
    if (!a.is_object() || !a.contains("id") || !a["id"].is_string() || !a.contains("component") ||
        !a["component"].is_string())
        return false;
    out.entity = world.find(a["id"].get<std::string>());
    if (out.entity.is_null() || !world.alive(out.entity)) return false;
    out.id = world.id_of(out.entity);
    out.type = TypeRegistry::global().find_ci(a["component"].get<std::string>());
    return out.type != nullptr;
}

UndoCommand make_call(const char* cmd, const Target& t, Json extra = Json::object()) {
    UndoCommand c;
    c.cmd = cmd;
    c.args = Json::object({{"id", t.id}, {"component", t.type->name}});
    for (auto it = extra.begin(); it != extra.end(); ++it) c.args[it.key()] = it.value();
    return c;
}

// "scene.set_component|<entity>|<component>|<field>,<field>|<merge>": a later call with the same text sets the same fields
// of the same component, so it replaces this one in the entry (UndoStack::push_command, CoalesceMode::Merge).
std::string set_target(const Target& t, const Json& fields, bool merge) {
    std::vector<std::string> keys;
    for (auto it = fields.begin(); it != fields.end(); ++it) keys.push_back(it.key());
    std::sort(keys.begin(), keys.end());
    std::string s = "scene.set_component|" + t.id + "|" + t.type->name + "|";
    for (const std::string& k : keys) s += k + ",";
    return s + (merge ? "|merge" : "|");
}

// The values `fields` names on an EntityInfo. "id" is left out on purpose: renaming the id rewrites the references to it
// elsewhere in the scene, which only a snapshot gives back.
std::optional<Json> old_info_values(const World& world, Entity e, const Json& fields) {
    const EntityInfo& info = world.info(e);
    Json old = Json::object();
    for (auto it = fields.begin(); it != fields.end(); ++it) {
        const std::string& k = it.key();
        if (k == "name")
            old[k] = info.name;
        else if (k == "active")
            old[k] = info.active;
        else if (k == "tags")
            old[k] = Json(info.tags);
        else
            return std::nullopt;
    }
    return old;
}

// The values `fields` names on a component the entity has, in the form scene.set_component takes them back. A field that
// is not serialized (runtime state) or read only gives nullopt: the call is refused or leaves no trace in the scene.
std::optional<Json> old_component_values(const World& world, const Target& t, const void* current, const Json& fields) {
    Json old = Json::object();
    Json whole;  // only built when an Entity field needs the world to turn its handle into an id
    for (auto it = fields.begin(); it != fields.end(); ++it) {
        const FieldInfo* f = t.type->field(it.key());
        if (!f || !f->serialized || f->readOnly) return std::nullopt;
        if (f->kind == FieldKind::Entity) {
            if (whole.is_null()) whole = component_to_json(world, t.entity, *t.type, true, false);
            if (!whole.contains(f->name)) return std::nullopt;
            old[f->name] = whole[f->name];
        } else {
            old[f->name] = field_to_json(*f, current);
        }
    }
    return old;
}

// scene.set_component {id, component, fields, merge?}: undo sets the old value of exactly the fields the call names (a
// whole value, whatever `merge` was); a component the entity did not have is removed again.
std::optional<UndoPlan> plan_set_component(const World& world, const Json& a) {
    Target t;
    if (!resolve_target(world, a, t)) return std::nullopt;
    const Json fields = a.contains("fields") ? a["fields"] : Json::object();
    if (!fields.is_object()) return std::nullopt;
    const bool merge = a.contains("merge") && a["merge"].is_boolean() && a["merge"].get<bool>();

    UndoPlan plan;
    UndoCommand fwd = make_call("scene.set_component", t, Json::object({{"fields", fields}}));
    if (merge) fwd.args["merge"] = true;
    fwd.target = set_target(t, fields, merge);
    plan.forward.push_back(std::move(fwd));

    if (t.type->name == "EntityInfo") {
        const std::optional<Json> old = old_info_values(world, t.entity, fields);
        if (!old) return std::nullopt;
        plan.inverse.push_back(make_call("scene.set_component", t, Json::object({{"fields", *old}})));
        return plan;
    }
    const void* current = world.get(t.entity, *t.type);
    if (!current) {
        plan.inverse.push_back(make_call("scene.remove_component", t));
        return plan;
    }
    const std::optional<Json> old = old_component_values(world, t, current, fields);
    if (!old) return std::nullopt;
    plan.inverse.push_back(make_call("scene.set_component", t, Json::object({{"fields", *old}})));
    return plan;
}

// scene.remove_component {id, component}: undo adds the component back with every serialized field it had.
std::optional<UndoPlan> plan_remove_component(const World& world, const Json& a) {
    Target t;
    if (!resolve_target(world, a, t)) return std::nullopt;
    if (t.type->name == "Transform" || t.type->name == "EntityInfo") return std::nullopt;  // the command refuses it
    if (!world.get(t.entity, *t.type)) return std::nullopt;                                // nothing to remove
    UndoPlan plan;
    plan.forward.push_back(make_call("scene.remove_component", t));
    plan.inverse.push_back(make_call(
        "scene.set_component", t, Json::object({{"fields", component_to_json(world, t.entity, *t.type, true, false)}})));
    return plan;
}

// The table: one row per command that has an inverse. M98.7e2 adds the structural commands here.
const BuilderRow kBuilders[] = {
    {"scene.set_component", &plan_set_component, nullptr},
    {"scene.remove_component", &plan_remove_component, nullptr},
};

const BuilderRow* find_row(const std::string& name) {
    for (const BuilderRow& r : kBuilders)
        if (name == r.name) return &r;
    return nullptr;
}

}  // namespace

std::optional<UndoPlan> plan_undo(const World& world, const std::string& name, const Json& args) {
    const BuilderRow* row = find_row(name);
    return row ? row->build(world, args) : std::nullopt;
}

bool has_undo_builder(const std::string& name) { return find_row(name) != nullptr; }

void finish_undo_plan(const std::string& name, UndoPlan& plan, const Json& result) {
    const BuilderRow* row = find_row(name);
    if (row && row->finish) row->finish(plan, result);
}

}  // namespace fa::editor
