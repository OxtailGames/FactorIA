#include "undo_inverse.h"

#include <algorithm>
#include <cstdint>
#include <set>

#include "fa/core/reflect.h"
#include "fa/scene/components.h"
#include "fa/scene/serialize.h"

namespace fa::editor {

namespace {

using Builder = std::optional<UndoPlan> (*)(const World&, const Json&);
// Completes a plan with what only the finished command knows (the id a spawn got); the world is the one AFTER the command.
// False when the result does not hold what the plan needs.
using Finisher = bool (*)(const World&, UndoPlan&, const Json& result);

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
    plan.inverse.push_back(
        make_call("scene.set_component", t,
                  Json::object({{"fields", component_to_json(world, t.entity, *t.type, true, false)}})));
    return plan;
}

// ------------------------------------------------------------------------------------------------ structure ----
// The structural commands (spawn, destroy, paste, reparent) are undone by re-creating entities through
// scene.paste_entities, which keeps the id of every entity of its text that is free in the scene: after a destroy (or an
// undone spawn) the ids are free, so the entities come back with the SAME ids, components, prefab links and children. The
// text is what scene.copy_entities writes (PrefabSave::Marks, as the old whole-scene snapshots did).

std::vector<Entity> subtree_of(const World& w, Entity e) {
    std::vector<Entity> out{e};
    for (size_t i = 0; i < out.size(); ++i)
        for (Entity c : w.children(out[i])) out.push_back(c);
    return out;
}

UndoCommand destroy_call(const std::string& id) {
    UndoCommand c;
    c.cmd = "scene.destroy";
    c.args = Json::object({{"id", id}});
    return c;
}

// Commands that re-create `roots` (each with its subtree) where they are now: one paste (so the references between the
// roots stay), then a set_parent for every root that was not the last child of its parent.
std::vector<UndoCommand> restore_commands(const World& w, const std::vector<Entity>& roots) {
    EntityJsonOptions o;
    o.prefabs = PrefabSave::Marks;
    Json entries = Json::array();
    for (Entity e : roots) {
        Json entry = Json::object();
        if (Entity p = w.parent(e); !p.is_null()) entry["parent"] = w.id_of(p);
        entry["entity"] = entity_to_json(w, e, o);
        entries.push_back(std::move(entry));
    }
    const Json payload = Json::object({{"format", "factoria.entities/1"}, {"entities", std::move(entries)}});
    std::vector<UndoCommand> cmds;
    UndoCommand paste;
    paste.cmd = "scene.paste_entities";
    paste.args = Json::object(
        {{"text", payload.dump(-1, ' ', false, Json::error_handler_t::replace)}, {"keepParents", true}});
    cmds.push_back(std::move(paste));
    for (Entity e : roots) {
        const Entity p = w.parent(e);
        if (p.is_null()) continue;  // the top level keeps no order the commands can set
        const std::vector<Entity>& sib = w.children(p);
        const auto at = size_t(std::find(sib.begin(), sib.end(), e) - sib.begin());
        if (at + 1 >= sib.size()) continue;  // last: where a paste puts it
        UndoCommand c;
        c.cmd = "scene.set_parent";
        c.args = Json::object({{"id", w.id_of(e)},
                               {"parent", w.id_of(p)},
                               {"index", int64_t(at)},
                               {"keepWorldTransform", false}});
        cmds.push_back(std::move(c));
    }
    return cmds;
}

// The Entity fields of entities OUTSIDE `inside` that name an entity of it: a destroy leaves them dead, and a paste cannot
// bring them back (they are not in its text), so the inverse sets them again once the entities exist.
std::vector<UndoCommand> outside_reference_commands(const World& w, const std::vector<Entity>& inside) {
    std::set<uint64_t> in;
    for (Entity e : inside) in.insert(e.bits());
    std::vector<UndoCommand> cmds;
    for (const TypeInfo* type : TypeRegistry::global().all()) {
        std::vector<const FieldInfo*> fields;
        for (const FieldInfo& f : type->fields)
            if (f.kind == FieldKind::Entity && f.serialized && !f.readOnly) fields.push_back(&f);
        if (fields.empty()) continue;
        for (Entity owner : w.entities_with(type)) {
            if (in.count(owner.bits())) continue;
            const void* obj = w.get(owner, *type);
            if (!obj) continue;
            Json set = Json::object();
            for (const FieldInfo* f : fields) {
                const Entity target = *static_cast<const Entity*>(f->ptr(obj));
                if (!target.is_null() && in.count(target.bits()) && w.alive(target)) set[f->name] = w.id_of(target);
            }
            if (set.empty()) continue;
            UndoCommand c;
            c.cmd = "scene.set_component";
            c.args = Json::object({{"id", w.id_of(owner)}, {"component", type->name}, {"fields", std::move(set)}});
            cmds.push_back(std::move(c));
        }
    }
    return cmds;
}

Entity live_entity(const World& w, const Json& a, const char* key) {
    if (!a.is_object() || !a.contains(key) || !a[key].is_string()) return kNullEntity;
    const Entity e = w.find(a[key].get<std::string>());
    return !e.is_null() && w.alive(e) && !w.pending_destroy(e) ? e : kNullEntity;
}

// scene.destroy {id}: undo pastes the entity and its subtree back, puts it at its place among its siblings and sets the
// references other entities held to it.
std::optional<UndoPlan> plan_destroy(const World& w, const Json& a) {
    const Entity e = live_entity(w, a, "id");
    if (e.is_null()) return std::nullopt;
    UndoPlan plan;
    plan.forward.push_back(destroy_call(w.id_of(e)));
    plan.inverse = restore_commands(w, {e});
    for (UndoCommand& c : outside_reference_commands(w, subtree_of(w, e))) plan.inverse.push_back(std::move(c));
    return plan;
}

// scene.spawn: redo re-creates what the spawn made (the same ids, whatever the call left to chance), undo destroys it.
std::optional<UndoPlan> plan_spawn(const World&, const Json& a) {
    if (!a.is_object() || a.empty()) return std::nullopt;
    UndoPlan plan;
    UndoCommand fwd;
    fwd.cmd = "scene.spawn";
    fwd.args = a;
    plan.forward.push_back(std::move(fwd));
    return plan;  // finish_spawn fills the rest from the result
}

bool finish_spawn(const World& w, UndoPlan& plan, const Json& result) {
    if (!result.is_object() || !result.contains("id") || !result["id"].is_string()) return false;
    const Entity e = w.find_by_id(result["id"].get<std::string>());
    if (e.is_null() || !w.alive(e)) return false;
    plan.forward = restore_commands(w, {e});
    plan.inverse = {destroy_call(w.id_of(e))};
    return true;
}

// scene.paste_entities: redo pastes the same entities again (with the ids the paste gave them), undo destroys the roots.
std::optional<UndoPlan> plan_paste(const World&, const Json& a) {
    if (!a.is_object()) return std::nullopt;
    UndoPlan plan;
    UndoCommand fwd;
    fwd.cmd = "scene.paste_entities";
    fwd.args = a;
    plan.forward.push_back(std::move(fwd));
    return plan;
}

bool finish_paste(const World& w, UndoPlan& plan, const Json& result) {
    if (!result.is_object() || !result.contains("ids") || !result["ids"].is_array() || result["ids"].empty())
        return false;
    std::vector<Entity> roots;
    for (const Json& id : result["ids"]) {
        const Entity e = id.is_string() ? w.find_by_id(id.get<std::string>()) : kNullEntity;
        if (e.is_null() || !w.alive(e)) return false;
        roots.push_back(e);
    }
    plan.forward = restore_commands(w, roots);
    plan.inverse.clear();
    for (auto it = roots.rbegin(); it != roots.rend(); ++it) plan.inverse.push_back(destroy_call(w.id_of(*it)));
    return true;
}

// bones.create: the chain is new, and nests (bone 1 holds bone 2...), so one root stands for all of it.
bool finish_bones_create(const World& w, UndoPlan& plan, const Json& result) {
    if (!result.is_object() || !result.contains("bones") || !result["bones"].is_array() || result["bones"].empty() ||
        !result["bones"][0].is_object() || !result["bones"][0].contains("id") || !result["bones"][0]["id"].is_string())
        return false;
    const Entity first = w.find_by_id(result["bones"][0]["id"].get<std::string>());
    if (first.is_null() || !w.alive(first)) return false;
    plan.forward = restore_commands(w, {first});
    plan.inverse = {destroy_call(w.id_of(first))};
    return true;
}

std::optional<UndoPlan> plan_bones_create(const World& w, const Json& a) {
    if (live_entity(w, a, "parent").is_null()) return std::nullopt;
    UndoPlan plan;
    UndoCommand fwd;
    fwd.cmd = "bones.create";
    fwd.args = a;
    plan.forward.push_back(std::move(fwd));
    return plan;
}

// scene.set_parent {id, parent?, keepWorldTransform?, index?}: undo puts the entity back under its old parent at its old
// place and, when the parent changed, gives the old local Transform back exactly (a keepWorldTransform move rewrote it).
// The UI layout's slot is not part of it: the layout puts a child in its slot again on the next frame.
std::optional<UndoPlan> plan_set_parent(const World& w, const Json& a) {
    const Entity e = live_entity(w, a, "id");
    if (e.is_null()) return std::nullopt;
    Entity newParent = kNullEntity;
    if (a.contains("parent") && !a["parent"].is_null()) {
        if (!a["parent"].is_string()) return std::nullopt;
        if (!a["parent"].get<std::string>().empty()) {
            newParent = live_entity(w, a, "parent");
            if (newParent.is_null()) return std::nullopt;
        }
    }
    const Entity oldParent = w.parent(e);
    UndoPlan plan;
    UndoCommand fwd;
    fwd.cmd = "scene.set_parent";
    fwd.args = Json::object({{"id", w.id_of(e)}, {"parent", newParent.is_null() ? Json(nullptr) : Json(w.id_of(newParent))}});
    if (a.contains("keepWorldTransform")) fwd.args["keepWorldTransform"] = a["keepWorldTransform"];
    if (a.contains("index") && !a["index"].is_null()) fwd.args["index"] = a["index"];
    plan.forward.push_back(std::move(fwd));

    UndoCommand back;
    back.cmd = "scene.set_parent";
    back.args = Json::object({{"id", w.id_of(e)},
                              {"parent", oldParent.is_null() ? Json(nullptr) : Json(w.id_of(oldParent))},
                              {"keepWorldTransform", false}});
    if (!oldParent.is_null()) {
        const std::vector<Entity>& sib = w.children(oldParent);
        back.args["index"] = int64_t(std::find(sib.begin(), sib.end(), e) - sib.begin());
    }
    plan.inverse.push_back(std::move(back));
    if (oldParent != newParent) {
        const TypeInfo* transform = TypeRegistry::global().find("Transform");
        if (!transform || !w.get(e, *transform)) return std::nullopt;
        UndoCommand t;
        t.cmd = "scene.set_component";
        t.args = Json::object({{"id", w.id_of(e)},
                               {"component", "Transform"},
                               {"fields", component_to_json(w, e, *transform, true, false)}});
        plan.inverse.push_back(std::move(t));
    }
    return plan;
}

// The table: one row per command that has an inverse.
const BuilderRow kBuilders[] = {
    {"scene.set_component", &plan_set_component, nullptr},
    {"scene.remove_component", &plan_remove_component, nullptr},
    {"scene.spawn", &plan_spawn, &finish_spawn},
    {"scene.destroy", &plan_destroy, nullptr},
    {"scene.set_parent", &plan_set_parent, nullptr},
    {"scene.paste_entities", &plan_paste, &finish_paste},
    {"bones.create", &plan_bones_create, &finish_bones_create},
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

bool finish_undo_plan(const World& world, const std::string& name, UndoPlan& plan, const Json& result) {
    const BuilderRow* row = find_row(name);
    return !row || !row->finish || row->finish(world, plan, result);
}

}  // namespace fa::editor
