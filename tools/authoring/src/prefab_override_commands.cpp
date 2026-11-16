// What a prefab instance of the open scene overrides, and how to give it back or keep it:
//   prefab.overrides  lists what differs from the prefab, one entry per difference;
//   prefab.revert     puts the prefab's values back into the instance (the running world only);
//   prefab.apply      writes the instance's values into the prefab FILE and updates the other instances of it.
// All three are built on diff_entity_with_prefab (engine/scene/src/prefab_instance.cpp), which is what scene.save writes
// for an instance, so what they list is exactly what the scene file would carry.
#include <algorithm>
#include <filesystem>
#include <set>

#include "authoring_internal.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/scene/serialize.h"

namespace fa {

namespace {

namespace sfs = std::filesystem;

constexpr const char* kPrefabExt = ".prefab.json";
// How many changes are listed in an error message.
constexpr std::size_t kListedInErrors = 4;

[[noreturn]] void bad_arg(const std::string& message, const std::string& hint = {}) {
    throw CommandError("invalid_argument", message, hint);
}

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

const char* kind_name(PrefabChange::Kind k) {
    switch (k) {
        case PrefabChange::Kind::Field: return "field";
        case PrefabChange::Kind::Component: return "component";
        case PrefabChange::Kind::Child: return "child";
    }
    return "field";
}

// Why the change cannot be written to the prefab file ("" = it can).
std::string apply_blocker(const World& w, const PrefabChange& c) {
    if (!c.nodeInFile)
        return "'" + w.id_of(c.entity) +
               "' is inside a prefab that this prefab itself instances, so the prefab file has no node for it (edit "
               "the inner prefab instead)";
    return c.fileError;
}

Json change_json(const World& w, const PrefabChange& c) {
    Json j = Json::object();
    j["kind"] = kind_name(c.kind);
    j["entity"] = w.id_of(c.entity);
    if (c.kind != PrefabChange::Kind::Child) j["component"] = c.component;
    if (c.kind == PrefabChange::Kind::Field) {
        j["field"] = c.field;
        j["value"] = c.value;
        j["prefabValue"] = c.prefabValue;
    } else if (c.kind == PrefabChange::Kind::Component) {
        j["value"] = c.value;
    }
    if (c.placement) j["placement"] = true;
    if (const std::string blocker = apply_blocker(w, c); !blocker.empty()) j["applyBlocked"] = blocker;
    return j;
}

// An entity of the open scene with the prefab it is an instance of.
struct Instance {
    Entity root;   // the root of the instance
    Entity scope;  // the entity the caller named: it and what is below it
    std::string path;
    PrefabDiff diff;
};

PrefabDiff diff_instance(World& w, Entity root, const std::string& path) {
    PrefabDiffOptions opts;
    opts.useMarks = true;  // the scene was loaded by this engine: the children carry their marks
    const PoseRest pose = collect_pose_rest(w);
    if (!pose.empty()) opts.poseRest = &pose;
    return diff_entity_with_prefab(w, root, path, opts);
}

Instance need_instance(Engine::Impl& I, const Json& a, bool mustBeExpressible, const char* what) {
    World& w = I.world;
    Instance inst;
    inst.scope = need_entity(w, a, "id");
    inst.root = prefab_instance_root(w, inst.scope);
    if (inst.root.is_null())
        throw CommandError(
            "not_a_prefab_instance",
            "'" + w.id_of(inst.scope) + "' is not part of a prefab instance, so it has no prefab to compare with.",
            "A prefab instance comes from scene.spawn {\"prefab\": path} or a scene entity {\"prefab\": path}; "
            "an entity created by hand, or a child added under an instance, has no prefab of its own (name the "
            "instance's root, or use prefab.save to make a prefab of it).");
    inst.path = w.info(inst.root).prefab;
    inst.diff = diff_instance(w, inst.root, inst.path);
    if (mustBeExpressible && !inst.diff.expressible)
        throw CommandError("not_expressible",
                           "Cannot " + std::string(what) + " '" + w.id_of(inst.scope) + "': its differences from '" +
                               inst.path + "' cannot be listed one by one: " + inst.diff.reason + ".",
                           "Fix what the sentence names (restore the removed part, or move the added child under the "
                           "instance's root), or use prefab.save to save the entity as a new prefab.");
    return inst;
}

bool in_subtree(const World& w, Entity scope, Entity e) { return e == scope || w.is_ancestor(scope, e); }

const TypeInfo* find_type(const std::string& name) { return TypeRegistry::global().find_ci(name); }

// "position" and "/position" both name the field `position`; a pointer into the field's value is not supported.
std::string field_pointer(const std::string& raw) {
    const std::string name = !raw.empty() && raw[0] == '/' ? raw.substr(1) : raw;
    if (name.empty() || name.find('/') != std::string::npos)
        bad_arg("'field' is '" + raw + "', but it must name ONE field of the component, as a JSON pointer.",
                "Use \"/position\" (or \"position\") to revert or apply the whole field; a part of a value (a single "
                "number of a vector) is not handled on its own.");
    return "/" + name;
}

// The changes a call names. Without `component` every change of the entity and what is below it (a whole instance when the
// entity is its root), except where the instance stands (the root's Transform.position). With `component` only that
// component of the entity itself, and with `field` that one field: where the instance stands is touched only when it is
// named with `field`.
struct Selection {
    std::vector<const PrefabChange*> changes;
    std::string note;
};

Selection select_changes(const World& w, const Instance& inst, const Json& a) {
    const std::string rawComponent = a.value("component", std::string());
    const std::string rawField = a.value("field", std::string());
    Selection sel;
    if (rawComponent.empty() && !rawField.empty())
        bad_arg("'field' is given without 'component'.",
                "Say which component the field belongs to, e.g. {\"component\": \"Transform\", \"field\": "
                "\"/position\"}; name, tags and active are fields of the component EntityInfo.");
    std::string component, field;
    if (!rawComponent.empty()) {
        const TypeInfo* t = find_type(rawComponent);
        if (!t) {
            const std::string s = TypeRegistry::global().suggest(rawComponent);
            bad_arg("Unknown component '" + rawComponent + "'." + (s.empty() ? "" : " Did you mean '" + s + "'?"),
                    "api.components lists every component with its fields.");
        }
        component = t->name;
        if (!rawField.empty()) {
            field = field_pointer(rawField);
            const bool known = std::any_of(t->fields.begin(), t->fields.end(),
                                           [&](const FieldInfo& f) { return f.serialized && "/" + f.name == field; });
            if (!known) {
                std::vector<std::string> names;
                for (const FieldInfo& f : t->fields)
                    if (f.serialized) names.push_back(f.name);
                bad_arg(t->name + " has no field '" + field.substr(1) + "'. " + did_you_mean(field.substr(1), names),
                        "api.components lists the fields of " + t->name + ".");
            }
        }
    }
    for (const PrefabChange& c : inst.diff.list) {
        if (component.empty()) {
            if (!in_subtree(w, inst.scope, c.entity) || c.placement) continue;
        } else {
            if (c.entity != inst.scope || c.kind == PrefabChange::Kind::Child || c.component != component) continue;
            if (!field.empty()) {
                if (c.kind != PrefabChange::Kind::Field || c.field != field) continue;
            } else if (c.placement) {
                continue;
            }
        }
        sel.changes.push_back(&c);
    }
    if (sel.changes.empty()) {
        std::string what = component.empty() ? "'" + w.id_of(inst.scope) + "'" : component;
        if (!field.empty()) what = component + field;
        sel.note = "Nothing to do: " + what + " already equals the prefab '" + inst.path + "'.";
    }
    return sel;
}

// ---------------------------------------------------------------------------------------------------------- overrides
Json prefab_overrides(Engine::Impl& I, const Json& a) {
    World& w = I.world;
    Instance inst = need_instance(I, a, false, "list the overrides of");
    Json out = Json::object();
    out["id"] = w.id_of(inst.scope);
    out["root"] = w.id_of(inst.root);
    out["prefab"] = inst.path;
    out["expressible"] = inst.diff.expressible;
    Json list = Json::array();
    std::size_t count = 0;
    if (!inst.diff.expressible) {
        out["reason"] = inst.diff.reason;
    } else {
        for (const PrefabChange& c : inst.diff.list) {
            if (!in_subtree(w, inst.scope, c.entity)) continue;
            list.push_back(change_json(w, c));
            if (!c.placement) ++count;
        }
    }
    out["count"] = count;
    out["overrides"] = std::move(list);
    return out;
}

// ------------------------------------------------------------------------------------------------------------ revert
void revert_change(Engine::Impl& I, const PrefabChange& c) {
    World& w = I.world;
    switch (c.kind) {
        case PrefabChange::Kind::Field: {
            Json fields = Json::object();
            fields[c.field.substr(1)] = c.prefabValue;
            set_component(w, Json::object({{"id", w.id_of(c.entity)}, {"component", c.component}, {"fields", fields}}));
            break;
        }
        case PrefabChange::Kind::Component:
            if (const TypeInfo* t = find_type(c.component)) w.remove(c.entity, *t);
            break;
        case PrefabChange::Kind::Child: w.destroy(c.entity); break;
    }
}

Json prefab_revert(Engine::Impl& I, const Json& a) {
    World& w = I.world;
    Instance inst = need_instance(I, a, true, "revert");
    Selection sel = select_changes(w, inst, a);
    Json reverted = Json::array();
    for (const PrefabChange* c : sel.changes) reverted.push_back(change_json(w, *c));  // before the entities go
    for (const PrefabChange* c : sel.changes) revert_change(I, *c);
    if (!I.inFrame) w.flush();
    Json out = Json::object();
    out["id"] = w.id_of(inst.scope);
    out["root"] = w.id_of(inst.root);
    out["prefab"] = inst.path;
    out["reverted"] = std::move(reverted);
    if (!sel.note.empty()) out["notes"] = Json::array({sel.note});
    return out;
}

// -------------------------------------------------------------------------------------------------------------- apply
std::string join_path(const std::vector<std::size_t>& p) {
    std::string s;
    for (std::size_t i : p) s += std::to_string(i) + "/";
    return s;
}
// The key a change has in the set of what an instance overrides: the same place of the prefab, the same field.
std::string change_key(const PrefabChange& c) {
    return join_path(c.nodePath) + "|" + c.component + "|" + (c.kind == PrefabChange::Kind::Component ? "" : c.field) +
           "|" + kind_name(c.kind);
}

// The node of the prefab file's entity JSON that `path` names (child indexes); null when the file does not have it.
Json* node_at(Json& root, const std::vector<std::size_t>& path) {
    Json* n = &root;
    for (std::size_t i : path) {
        if (!n->is_object() || !n->contains("children") || !(*n)["children"].is_array() ||
            i >= (*n)["children"].size() || !(*n)["children"][i].is_object())
            return nullptr;
        n = &(*n)["children"][i];
    }
    return n;
}

Json& components_of(Json& node) {
    if (!node.contains("components") || !node["components"].is_object()) node["components"] = Json::object();
    return node["components"];
}

// Writes one change into the node of the prefab file. `childJson` is the added child's entity JSON.
void patch_node(Json& node, const PrefabChange& c, const Json& childJson) {
    switch (c.kind) {
        case PrefabChange::Kind::Field:
            if (c.component == "EntityInfo") {
                node[c.field.substr(1)] = c.fileValue;
            } else {
                Json& comps = components_of(node);
                if (!comps.contains(c.component) || !comps[c.component].is_object())
                    comps[c.component] = Json::object();
                comps[c.component][c.field.substr(1)] = c.fileValue;
            }
            break;
        case PrefabChange::Kind::Component: components_of(node)[c.component] = c.fileValue; break;
        case PrefabChange::Kind::Child:
            if (!node.contains("children") || !node["children"].is_array()) node["children"] = Json::array();
            node["children"].push_back(childJson);
            break;
    }
}

void mark_from_prefab(World& w, Entity e) {
    w.info(e).fromPrefab = true;
    for (Entity c : w.children(e)) mark_from_prefab(w, c);
}

std::size_t content_children(const World& w, Entity root) {
    std::size_t n = 0;
    for (Entity c : w.children(root)) n += w.info(c).fromPrefab ? 1 : 0;
    return n;
}

Entity child_at(const World& w, Entity e, const std::vector<std::size_t>& path) {
    for (std::size_t i : path) {
        const auto& kids = w.children(e);
        if (i >= kids.size()) return kNullEntity;
        e = kids[i];
    }
    return e;
}

// The entity of the instance under `root` that stands for the prefab's entity with id `prefabId`: the same id, or the id
// the world gave it when it was taken ("coin_2").
Entity find_counterpart(const World& w, Entity root, const std::string& prefabId) {
    Entity best;
    std::vector<Entity> stack{root};
    while (!stack.empty()) {
        const Entity e = stack.back();
        stack.pop_back();
        const std::string& id = w.info(e).id;
        if (id == prefabId) return e;
        if (best.is_null() && id.size() > prefabId.size() + 1 && id.compare(0, prefabId.size(), prefabId) == 0 &&
            id[prefabId.size()] == '_' &&
            std::all_of(id.begin() + std::ptrdiff_t(prefabId.size()) + 1, id.end(),
                        [](char ch) { return ch >= '0' && ch <= '9'; }))
            best = e;
        for (auto it = w.children(e).rbegin(); it != w.children(e).rend(); ++it) stack.push_back(*it);
    }
    return best;
}

// The value of a prefab file field for an instance: an Entity field names the prefab's id; the instance's own entity
// stands for it. `json` is the whole component (or just the field when `fieldName` is given).
Json localize_field(const World& w, Entity root, const FieldInfo& f, const Json& value) {
    if (f.kind != FieldKind::Entity || !value.is_string()) return value;
    const Entity target = find_counterpart(w, root, value.get<std::string>());
    return target.is_null() ? Json(nullptr) : Json(w.id_of(target));
}
Json localize_component(const World& w, Entity root, const TypeInfo& t, Json value) {
    for (const FieldInfo& f : t.fields)
        if (f.kind == FieldKind::Entity && value.is_object() && value.contains(f.name))
            value[f.name] = localize_field(w, root, f, value[f.name]);
    return value;
}

// Another instance of the prefab as it was before the file changed.
struct OtherInstance {
    Entity root;
    std::set<std::string> overridden;  // change_key of what it overrides: it keeps its own values there
};

// Gives `other` the change that was applied to the prefab file, unless it overrides that very thing. Returns false and
// says why in `note` when it could not.
bool update_other(Engine::Impl& I, const OtherInstance& other, const PrefabChange& c, const Json& childJson,
                  std::string& note) {
    World& w = I.world;
    if (c.placement || other.overridden.count(change_key(c))) return true;
    const std::string where = "'" + w.id_of(other.root) + "'";
    try {
        if (c.kind == PrefabChange::Kind::Child) {
            LoadReport report;
            const int index = int(content_children(w, other.root));
            Entity made = entity_from_json(w, childJson, other.root, report, "prefab.apply", "", index);
            if (made.is_null() || !report.ok()) {
                note = "The child added to the prefab could not be created under " + where + ": " + report.summary();
                if (!made.is_null()) mark_from_prefab(w, made);
                return false;
            }
            mark_from_prefab(w, made);
            return true;
        }
        const Entity target = child_at(w, other.root, c.nodePath);
        if (target.is_null()) {
            note = where + " does not have the part of the prefab that changed, so it was left as it is.";
            return false;
        }
        const TypeInfo* t = find_type(c.component);
        if (!t) return true;
        if (c.kind == PrefabChange::Kind::Component) {
            if (w.get(target, *t)) return true;  // it added the same component itself
            auto r = patch_component(w, target, *t, localize_component(w, other.root, *t, c.fileValue));
            if (!r.ok()) {
                note = "Could not add " + c.component + " to " + where + ": " + r.error().message;
                return false;
            }
            return true;
        }
        Json fields = Json::object();
        const std::string name = c.field.substr(1);
        Json value = c.fileValue;
        for (const FieldInfo& f : t->fields)
            if (f.name == name) value = localize_field(w, other.root, f, value);
        fields[name] = value;
        set_component(w, Json::object({{"id", w.id_of(target)}, {"component", c.component}, {"fields", fields}}));
    } catch (const CommandError& e) {
        note = std::string("Could not update ") + where + ": " + e.what();
        return false;
    }
    return true;
}

Json prefab_apply(Engine::Impl& I, const Json& a) {
    World& w = I.world;
    Instance inst = need_instance(I, a, true, "apply");
    Selection sel = select_changes(w, inst, a);
    Json out = Json::object();
    out["id"] = w.id_of(inst.scope);
    out["root"] = w.id_of(inst.root);
    out["prefab"] = inst.path;
    out["applied"] = Json::array();
    out["files"] = Json::array();
    out["updated"] = Json::array();
    out["skipped"] = Json::array();
    if (sel.changes.empty()) {
        out["notes"] = Json::array({sel.note});
        return out;
    }

    // What cannot be written to the file stops the whole call: a half-applied instance would be worse than none.
    std::vector<std::string> blocked;
    for (const PrefabChange* c : sel.changes)
        if (const std::string b = apply_blocker(w, *c); !b.empty()) blocked.push_back(b);
    if (!blocked.empty()) {
        std::string list;
        for (std::size_t i = 0; i < blocked.size() && i < kListedInErrors; ++i) list += (i ? "; " : "") + blocked[i];
        throw CommandError("cannot_apply",
                           std::to_string(blocked.size()) + " change(s) of '" + w.id_of(inst.scope) +
                               "' cannot be written to the prefab '" + inst.path + "': " + list + ".",
                           "Apply the other changes one by one (name `component` and `field`), revert these with "
                           "prefab.revert, or make the entity they point at part of the prefab first.");
    }

    // The file: inside the project, a prefab, there, and writable. Checked before anything changes.
    const std::string rel = resolve_caller_project_path(inst.path, "prefab.apply");
    if (!ends_with(to_lower(rel), kPrefabExt))
        bad_arg("'" + inst.path + "' does not end in " + kPrefabExt + ", so prefab.apply will not write to it.",
                "Prefab files are named prefabs/<name>.prefab.json.");
    const sfs::path full = fs::resolve(rel);
    std::error_code ec;
    if (!sfs::is_regular_file(full, ec))
        throw CommandError("not_found", "The prefab file '" + rel + "' does not exist.",
                           "The instance was made from a prefab that has been moved or deleted. Restore the file, or "
                           "use prefab.save to save '" +
                               w.id_of(inst.root) + "' as a new prefab.");
    const auto perms = sfs::status(full, ec).permissions();
    if (!ec &&
        (perms & (sfs::perms::owner_write | sfs::perms::group_write | sfs::perms::others_write)) == sfs::perms::none)
        throw CommandError("read_only",
                           "The prefab file '" + rel + "' is read-only, so '" + w.id_of(inst.scope) +
                               "' cannot be applied to it.",
                           "Make the file writable (check it out of version control, or clear its read-only flag) and "
                           "call prefab.apply again; prefab.revert gives the prefab's values back to the instance "
                           "instead.");
    auto loaded = load_json_file(rel);
    if (!loaded.ok())
        throw CommandError("failed", loaded.error().message,
                           loaded.error().hint.empty() ? "Fix the JSON of the prefab file first."
                                                       : loaded.error().hint);
    Json file = std::move(loaded.value());
    if (!file.is_object() || !file.contains("entity") || !file["entity"].is_object())
        throw CommandError("failed", "The prefab '" + rel + "' has no \"entity\" object.",
                           "A prefab file is {\"format\": \"factoria.prefab/1\", \"entity\": {...}}.");

    // The other instances, as they are before the file changes: what each of them overrides stays its own.
    std::vector<OtherInstance> others;
    std::size_t nested = 0;
    for (Entity x : w.entities()) {
        const EntityInfo& inf = w.info(x);
        if (inf.prefab != inst.path || x == inst.root) continue;
        if (inf.fromPrefab) {
            ++nested;
            continue;
        }
        PrefabDiff d = diff_instance(w, x, inst.path);
        if (!d.expressible) {
            out["skipped"].push_back(Json::object({{"id", inf.id}, {"reason", d.reason}}));
            continue;
        }
        OtherInstance o;
        o.root = x;
        for (const PrefabChange& c : d.list) o.overridden.insert(change_key(c));
        others.push_back(std::move(o));
    }

    // Write.
    std::vector<std::string> notes;
    std::vector<Json> childJson(sel.changes.size());
    for (std::size_t i = 0; i < sel.changes.size(); ++i) {
        const PrefabChange& c = *sel.changes[i];
        if (c.kind == PrefabChange::Kind::Child) childJson[i] = prefab_child_json(w, c.entity, notes);
        Json* node = node_at(file["entity"], c.nodePath);
        if (!node)
            throw CommandError("cannot_apply",
                               "The prefab file '" + rel + "' has no node for '" + w.id_of(c.entity) +
                                   "' (it changed since the scene was loaded).",
                               "Reload the scene (scene.reload) and try again.");
        patch_node(*node, c, childJson[i]);
    }
    if (auto saved = save_scene_json_file(rel, file); !saved.ok())
        throw CommandError("failed", saved.error().message, saved.error().hint);

    // The instance itself now has nothing to override there; a child it added is now the prefab's own.
    Json applied = Json::array();
    for (std::size_t i = 0; i < sel.changes.size(); ++i) {
        const PrefabChange& c = *sel.changes[i];
        applied.push_back(change_json(w, c));
        if (c.kind != PrefabChange::Kind::Child) continue;
        mark_from_prefab(w, c.entity);
        w.set_parent(c.entity, inst.root, false, int(content_children(w, inst.root)) - 1);
    }
    // The others get the same, unless they override it.
    for (const OtherInstance& o : others) {
        bool all = true;
        for (std::size_t i = 0; i < sel.changes.size(); ++i) {
            std::string note;
            if (!update_other(I, o, *sel.changes[i], childJson[i], note)) {
                all = false;
                if (!note.empty()) notes.push_back(note);
            }
        }
        if (all) out["updated"].push_back(w.id_of(o.root));
    }
    if (nested > 0)
        notes.push_back(std::to_string(nested) +
                        " instance(s) of this prefab inside other prefabs' content were not updated: reload the scene "
                        "(scene.reload) to see the change there.");
    std::set<std::string> seen;
    Json noteList = Json::array();
    for (const std::string& n : notes)
        if (seen.insert(n).second) noteList.push_back(n);
    out["applied"] = std::move(applied);
    out["files"] = Json::array({rel});
    if (!noteList.empty()) out["notes"] = std::move(noteList);
    return out;
}

}  // namespace

void register_prefab_override_commands(Engine& engine, Engine::Impl& I) {
    (void)engine;
    I.commands.add(
        {"prefab.overrides", "List what a prefab instance of the open scene overrides: what differs from its prefab.",
         "`id` is an entity of a prefab instance, its root or a part of it; the list covers that entity and what is "
         "below "
         "it (the whole instance for the root). Returns {id, root, prefab, expressible, count, overrides: [{kind, "
         "entity, component, field, value, prefabValue}]}: kind \"field\" (a field of a component, as a JSON pointer: "
         "\"/position\"; name, tags and active are fields of EntityInfo), \"component\" (one the prefab lacks, with "
         "its "
         "whole value) or \"child\" (added under the instance's root). Example: prefab.overrides "
         "{\"id\":\"enemy_1\"}" FA_COMMAND_DETAILS "`prefabValue` is what prefab.revert puts back; an Entity field "
         "gives the id of the instance's own entity. The "
         "root's Transform.position is listed with placement: true and not counted: where an instance stands is not "
         "an override of the prefab. An entry with `applyBlocked` cannot be written to the prefab file by prefab.apply "
         "(it points at an entity outside the prefab, or at a part that a prefab inside the prefab made): the text "
         "says "
         "why. When the differences cannot be listed (a part of the prefab was removed, a child was added under a part "
         "of it) `expressible` is false, `reason` says what to fix and the list is empty. It reads the prefab file and "
         "changes nothing.",
         parse_schema(R"({"type":"object","required":["id"],"properties":{
               "id":{"type":"string","description":"Id (or name) of the instance's root or of a part of it."}}})"),
         true, "scene"},
        [&I](const Json& a) { return prefab_overrides(I, a); });

    I.commands.add(
        {"prefab.revert", "Put the prefab's values back into an instance: one field, one component, or everything.",
         "`id` is the instance's root or a part of it. Without `component` everything the entity and what is below it "
         "overrides goes back to the prefab (for the root: the whole instance, added components and children "
         "included); with `component`, that component of the entity; with `component` and `field`, that one field "
         "(a JSON pointer such as \"/position\"; name, tags and active are fields of EntityInfo). Changes the open "
         "scene only: the prefab file stays as it is. Example: prefab.revert "
         "{\"id\":\"enemy_1\",\"component\":\"Sprite\","
         "\"field\":\"/color\"}" FA_COMMAND_DETAILS
         "Where the instance stands (the root's Transform.position) is not reverted unless named: {\"component\": "
         "\"Transform\", \"field\": \"/position\"}. A component the prefab lacks is removed, a child added under the "
         "instance is destroyed. Returns {id, root, prefab, reverted: [the entries prefab.overrides lists], notes?}. "
         "Refuses (code not_expressible) an instance whose differences cannot be listed; prefab.overrides says why. "
         "The editor calls it through its command undo, so Ctrl+Z puts the values back.",
         parse_schema(R"({"type":"object","required":["id"],"properties":{
               "id":{"type":"string","description":"Id (or name) of the instance's root or of a part of it."},
               "component":{"type":"string","description":"Only this component of the entity (e.g. Sprite, Transform, EntityInfo). Without it: everything of the entity and below."},
               "field":{"type":"string","description":"With `component`: only this field, as a JSON pointer inside the component, e.g. \"/color\" (\"color\" works too)."}}})"),
         false, "scene"},
        [&I](const Json& a) { return prefab_revert(I, a); });

    I.commands.add(
        {"prefab.apply",
         "Write an instance's values into its prefab file: one field, one component, or everything; the other "
         "instances follow.",
         "`id` is the instance's root or a part of it; `component` and `field` narrow it as in prefab.revert (without "
         "them: everything the entity and what is below it overrides, added components and children included). The "
         "prefab file keeps its own layout (its nested prefabs and the parts you did not touch stay), and every other "
         "instance of the prefab in the open scene gets the same change, except where it overrides that thing itself. "
         "Example: prefab.apply {\"id\":\"enemy_1\",\"component\":\"Sprite\",\"field\":\"/color\"}" FA_COMMAND_DETAILS
         "Returns {id, root, prefab, applied: [the entries prefab.overrides lists], files: [the prefab file written], "
         "updated: [ids of the other instances that were updated], skipped: [{id, reason}] (instances whose "
         "differences "
         "cannot be listed: left as they are), notes?}. Where the instance stands (the root's Transform.position) is "
         "not written unless named, like prefab.save. Refuses, changing nothing, a read-only file (code read_only), a "
         "prefab that does not exist, an instance whose differences cannot be listed (not_expressible) and changes the "
         "file has no place for (cannot_apply; each entry of prefab.overrides says so in `applyBlocked`). The "
         "file is written for good (the editor's Ctrl+Z puts the open scene back, not the file: use version control "
         "to go back), and instances of this prefab inside other prefabs are only updated after a scene.reload.",
         parse_schema(R"({"type":"object","required":["id"],"properties":{
               "id":{"type":"string","description":"Id (or name) of the instance's root or of a part of it."},
               "component":{"type":"string","description":"Only this component of the entity (e.g. Sprite, Transform, EntityInfo). Without it: everything of the entity and below."},
               "field":{"type":"string","description":"With `component`: only this field, as a JSON pointer inside the component, e.g. \"/color\" (\"color\" works too)."}}})"),
         false, "scene"},
        [&I](const Json& a) { return prefab_apply(I, a); });

    declare_command_capabilities(I.commands, {
                                                 {"prefab.overrides", capability_sets::reads()},
                                                 {"prefab.revert", capability_sets::changes_state()},
                                                 {"prefab.apply", capability_sets::edits_project()},
                                             });
}

}  // namespace fa
