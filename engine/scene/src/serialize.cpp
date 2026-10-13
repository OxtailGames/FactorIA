#include "fa/scene/serialize.h"

#include <algorithm>
#include <set>

#include "fa/core/fs.h"
#include "fa/core/strings.h"

namespace fa {

constexpr const char* kSceneFormat = "factoria.scene/1";
constexpr const char* kPrefabFormat = "factoria.prefab/1";

// ------------------------------------------------------------ LoadReport --
std::string LoadMessage::to_string() const {
    std::string s = source;
    if (!pointer.empty()) s += "#" + pointer;
    s += ": " + message;
    if (!hint.empty()) s += " (hint: " + hint + ")";
    return s;
}

bool LoadReport::ok() const { return error_count() == 0; }

std::size_t LoadReport::error_count() const {
    return std::size_t(std::count_if(messages.begin(), messages.end(),
                                     [](const LoadMessage& m) { return m.severity == LoadMessage::Severity::Error; }));
}

std::string LoadReport::summary() const {
    std::size_t errors = error_count(), warnings = messages.size() - errors;
    std::string s = "Loaded " + std::to_string(created.size()) + " entities with " + std::to_string(errors) +
                    (errors == 1 ? " error" : " errors") + " and " + std::to_string(warnings) +
                    (warnings == 1 ? " warning" : " warnings");
    s += messages.empty() ? "." : ":";
    for (const LoadMessage& m : messages)
        s += std::string("\n  [") + (m.severity == LoadMessage::Severity::Error ? "error" : "warning") + "] " + m.to_string();
    return s;
}

namespace {

std::string escape_token(const std::string& s) {
    std::string out;
    for (char c : s) {
        if (c == '~') out += "~0";
        else if (c == '/') out += "~1";
        else out += c;
    }
    return out;
}

bool is_special_type(const TypeInfo& t) { return t.name == "EntityInfo" || t.name == "SceneSettings"; }

const std::vector<std::string>& entity_keys() {
    static const std::vector<std::string> keys = {"id", "name", "tags", "active", "prefab", "components", "children"};
    return keys;
}

std::vector<std::string> component_names() {
    std::vector<std::string> out;
    for (const TypeInfo* t : TypeRegistry::global().all())
        if (!is_special_type(*t)) out.push_back(t->name);
    return out;
}

EntityInfo& info_of(World& w, Entity e) { return w.info(e); }

// Entity id string for JSON; null if the reference is empty or dead.
Json entity_ref_json(const World& w, Entity target) {
    if (target.is_null() || !w.alive(target)) return nullptr;
    return w.id_of(target);
}

// --------------------------------------------------------------- loading --
// Pending Entity-typed field assignment, resolved after every entity exists.
struct PendingRef {
    Entity owner;
    const TypeInfo* type;
    const FieldInfo* field;
    Json value;
    std::string pointer;
};

class Loader {
public:
    Loader(World& w, LoadReport& r, std::string source) : world_(w), report_(r), source_(std::move(source)) {}

    void message(LoadMessage::Severity sev, const std::string& ptr, std::string msg, std::string hint = {}) {
        if (!hint.empty() && !note_.empty()) hint += " " + note_;
        report_.messages.push_back({sev, source_, ptr, std::move(msg), std::move(hint)});
    }
    void error(const std::string& ptr, std::string msg, std::string hint = {}) {
        message(LoadMessage::Severity::Error, ptr, std::move(msg), std::move(hint));
    }
    void warn(const std::string& ptr, std::string msg, std::string hint = {}) {
        message(LoadMessage::Severity::Warning, ptr, std::move(msg), std::move(hint));
    }

    Entity load_entity(const Json& jIn, Entity parent, const std::string& ptr, bool quietIds);
    // Applies EntityInfo-style keys (id, name, tags, active).
    void apply_info_key(Entity e, const std::string& key, const Json& v, const std::string& ptr, bool quietIds);
    // Adds/patches a component from JSON. Returns false if nothing could be applied.
    bool apply_component(Entity e, const TypeInfo& type, const Json& fields, const std::string& ptr, bool deferEntities);
    void resolve_pending();
    World& world() { return world_; }

private:
    bool expand_prefab(const Json& j, const std::string& ptr, Json& out);
    void resolve_one(const PendingRef& ref);

    World& world_;
    LoadReport& report_;
    std::string source_;
    std::string note_;  // appended to hints while inside a prefab-expanded entity
    std::vector<PendingRef> pending_;
    std::vector<std::string> prefabStack_;
};

void Loader::apply_info_key(Entity e, const std::string& key, const Json& v, const std::string& ptr, bool quietIds) {
    EntityInfo& inf = info_of(world_, e);
    if (key == "id") {
        if (!v.is_string() || v.get<std::string>().empty()) {
            error(ptr, "'id' must be a non-empty string, got " + describe_json_value(v), "Example: \"id\": \"player\".");
            return;
        }
        const std::string& want = v.get_ref<const std::string&>();
        if (inf.id == want) return;
        Entity other = world_.find_by_id(want);
        if (!other.is_null() && other != e) {
            // Pick the next free suffix, exactly like World::create does.
            std::string unique = want;
            for (int n = 2; !world_.find_by_id(unique).is_null(); ++n) unique = want + "_" + std::to_string(n);
            if (!quietIds)
                warn(ptr, "id '" + want + "' is already used; renamed to '" + unique + "'",
                     "Entity ids must be unique within a scene. References to '" + want + "' point at the first entity with that id.");
            (void)world_.set_id(e, unique);
        } else {
            (void)world_.set_id(e, want);
        }
    } else if (key == "name") {
        if (!v.is_string()) error(ptr, "'name' must be a string, got " + describe_json_value(v));
        else inf.name = v.get<std::string>();
    } else if (key == "active") {
        if (!v.is_boolean()) error(ptr, "'active' must be true or false, got " + describe_json_value(v));
        else inf.active = v.get<bool>();
    } else if (key == "tags") {
        if (!v.is_array()) {
            error(ptr, "'tags' must be an array of strings, got " + describe_json_value(v), "Example: \"tags\": [\"enemy\", \"flying\"].");
            return;
        }
        std::vector<std::string> tags;
        for (std::size_t i = 0; i < v.size(); ++i) {
            if (!v[i].is_string()) {
                error(ptr + "/" + std::to_string(i), "tag must be a string, got " + describe_json_value(v[i]));
                continue;
            }
            tags.push_back(v[i].get<std::string>());
        }
        inf.tags = std::move(tags);
    }
}

bool Loader::apply_component(Entity e, const TypeInfo& type, const Json& fields, const std::string& ptr, bool deferEntities) {
    if (type.name == "EntityInfo") {
        error(ptr, "EntityInfo is not a component entry; its fields are the entity's top-level keys",
              "Write \"id\", \"name\", \"tags\" and \"active\" directly on the entity instead of under \"components\".");
        return false;
    }
    if (type.name == "SceneSettings") {
        error(ptr, "SceneSettings is not a component", "Scene-wide values go under the top-level \"settings\" key of the scene file.");
        return false;
    }
    if (!fields.is_object() && !fields.is_null()) {
        error(ptr, "component '" + type.name + "' must be a JSON object of field values, got " + describe_json_value(fields),
              "Example: \"" + type.name + "\": {\"" + (type.fields.empty() ? "field" : type.fields[0].name) + "\": ...}. Use {} for all defaults.");
        return false;
    }
    void* obj = world_.add(e, type);
    if (fields.is_null()) return true;
    std::vector<std::string> fieldNames;
    for (const FieldInfo& f : type.fields) fieldNames.push_back(f.name);

    for (auto it = fields.begin(); it != fields.end(); ++it) {
        std::string key = it.key();
        std::string fptr = ptr + "/" + escape_token(key);
        const FieldInfo* f = type.field(key);
        if (!f) {
            for (const FieldInfo& cand : type.fields)
                if (iequals(cand.name, key)) { f = &cand; break; }
            if (f) {
                warn(fptr, "field '" + key + "' of " + type.name + " should be spelled '" + f->name + "'", "Field names are case-sensitive camelCase; accepted anyway.");
            } else {
                error(fptr, "Unknown field '" + key + "' on " + type.name, did_you_mean(key, fieldNames));
                continue;
            }
        }
        if (f->readOnly) {
            error(fptr, "Field '" + type.name + "." + f->name + "' is read-only", "Remove it; the engine maintains this value.");
            continue;
        }
        if (f->kind == FieldKind::Entity) {
            if (it.value().is_null()) {
                *static_cast<Entity*>(f->ptr(obj)) = kNullEntity;
            } else if (deferEntities) {
                pending_.push_back({e, &type, f, it.value(), fptr});
            } else {
                resolve_one({e, &type, f, it.value(), fptr});
            }
            continue;
        }
        if (auto r = field_from_json(*f, obj, it.value()); !r) error(fptr, r.error().message, r.error().hint);
    }
    return true;
}

void Loader::resolve_one(const PendingRef& ref) {
    if (!world_.alive(ref.owner)) return;
    void* obj = world_.get(ref.owner, *ref.type);
    if (!obj) return;
    const Json& v = ref.value;
    if (!v.is_string()) {
        error(ref.pointer, "Field '" + ref.field->name + "' must be the string id of an entity (or null), got " + describe_json_value(v),
              "Example: \"" + ref.field->name + "\": \"player\". Ids are listed by scene.list_entities.");
        return;
    }
    Entity target = world_.find_by_id(v.get_ref<const std::string&>());
    if (target.is_null()) {
        std::vector<std::string> ids;
        for (Entity x : world_.entities()) ids.push_back(world_.id_of(x));
        error(ref.pointer, "No entity with id '" + v.get<std::string>() + "' for field '" + ref.type->name + "." + ref.field->name + "'",
              did_you_mean(v.get<std::string>(), ids, 20));
        return;
    }
    *static_cast<Entity*>(ref.field->ptr(obj)) = target;
}

void Loader::resolve_pending() {
    for (const PendingRef& r : pending_) resolve_one(r);
    pending_.clear();
}

// Replaces {"prefab": path, ...overrides} by the merged entity JSON. Returns true if expanded.
bool Loader::expand_prefab(const Json& j, const std::string& ptr, Json& out) {
    const Json& pv = j["prefab"];
    if (!pv.is_string()) {
        error(ptr + "/prefab", "'prefab' must be a project-relative path string, got " + describe_json_value(pv),
              "Example: \"prefab\": \"prefabs/enemy.prefab.json\".");
        return false;
    }
    std::string path = pv.get<std::string>();
    if (std::find(prefabStack_.begin(), prefabStack_.end(), path) != prefabStack_.end() || prefabStack_.size() > 8) {
        error(ptr + "/prefab", "Prefab '" + path + "' includes itself (directly or indirectly)", "Remove the cycle in the prefab files.");
        return false;
    }
    auto loaded = load_json_file(path);
    if (!loaded) {
        error(ptr + "/prefab", loaded.error().message, loaded.error().hint);
        return false;
    }
    const Json& pj = loaded.value();
    if (!pj.is_object() || !pj.contains("entity") || !pj["entity"].is_object()) {
        error(ptr + "/prefab", "Prefab '" + path + "' has no \"entity\" object",
              std::string("A prefab file looks like {\"format\": \"") + kPrefabFormat + "\", \"entity\": {...}}.");
        return false;
    }
    Json merged = pj["entity"];
    for (auto it = j.begin(); it != j.end(); ++it) {
        const std::string& k = it.key();
        if (k == "prefab") continue;
        if (k == "components" && it->is_object()) {
            if (!merged.contains("components") || !merged["components"].is_object()) merged["components"] = Json::object();
            json_merge(merged["components"], *it);
        } else if (k == "children" && it->is_array()) {
            if (!merged.contains("children") || !merged["children"].is_array()) merged["children"] = Json::array();
            for (const Json& c : *it) merged["children"].push_back(c);
        } else {
            merged[k] = *it;
        }
    }
    out = std::move(merged);
    return true;
}

Entity Loader::load_entity(const Json& jIn, Entity parent, const std::string& ptr, bool quietIds) {
    if (!jIn.is_object()) {
        error(ptr, "entity must be a JSON object, got " + describe_json_value(jIn),
              "Example: {\"id\": \"player\", \"components\": {\"Sprite\": {}}}.");
        return kNullEntity;
    }
    Json expanded;
    const Json* jp = &jIn;
    std::string savedNote = note_;
    bool pushedPrefab = false;
    if (jIn.contains("prefab")) {
        std::string path = jIn["prefab"].is_string() ? jIn["prefab"].get<std::string>() : std::string();
        if (expand_prefab(jIn, ptr, expanded)) {
            jp = &expanded;
            quietIds = true;
            note_ = "(entity expanded from prefab '" + path + "')";
            prefabStack_.push_back(path);
            pushedPrefab = true;
        }
    }
    const Json& j = *jp;

    Entity e = world_.create();
    report_.created.push_back(e);
    if (!parent.is_null()) world_.set_parent(e, parent);

    // Unknown keys
    for (auto it = j.begin(); it != j.end(); ++it) {
        const std::string& key = it.key();
        const auto& valid = entity_keys();
        if (std::find(valid.begin(), valid.end(), key) != valid.end()) continue;
        if (key == "$schema" || key == "_comment" || key == "comment" || key == "description") continue;
        std::string hint;
        if (const TypeInfo* t = TypeRegistry::global().find_ci(key); t && !is_special_type(*t))
            hint = "'" + key + "' is a component: put it under \"components\", e.g. \"components\": {\"" + t->name + "\": {...}}.";
        else
            hint = did_you_mean(key, valid);
        warn(ptr + "/" + escape_token(key), "Unknown entity key '" + key + "' (ignored)", hint);
    }

    for (const char* k : {"id", "name", "active", "tags"})
        if (j.contains(k)) apply_info_key(e, k, j[k], ptr + "/" + k, quietIds);

    if (j.contains("components")) {
        const Json& comps = j["components"];
        std::string cptr = ptr + "/components";
        if (!comps.is_object()) {
            error(cptr, "'components' must be an object mapping component names to field objects, got " + describe_json_value(comps),
                  "Example: \"components\": {\"Sprite\": {\"texture\": \"assets/a.png\"}, \"Transform\": {\"position\": [0, 0, 0]}}.");
        } else {
            for (auto it = comps.begin(); it != comps.end(); ++it) {
                std::string name = it.key();
                std::string kptr = cptr + "/" + escape_token(name);
                const TypeInfo* t = TypeRegistry::global().find(name);
                if (!t) {
                    t = TypeRegistry::global().find_ci(name);
                    if (t && !is_special_type(*t)) {
                        warn(kptr, "Component '" + name + "' should be spelled '" + t->name + "'", "Component names are case-sensitive; accepted anyway.");
                    } else {
                        t = nullptr;
                    }
                }
                if (!t) {
                    error(kptr, "Unknown component '" + name + "'", did_you_mean(name, component_names(), 30));
                    continue;
                }
                apply_component(e, *t, it.value(), kptr, true);
            }
        }
    }

    if (j.contains("children")) {
        const Json& kids = j["children"];
        if (!kids.is_array()) {
            error(ptr + "/children", "'children' must be an array of entity objects, got " + describe_json_value(kids));
        } else {
            for (std::size_t i = 0; i < kids.size(); ++i) load_entity(kids[i], e, ptr + "/children/" + std::to_string(i), quietIds);
        }
    }

    if (pushedPrefab) prefabStack_.pop_back();
    note_ = savedNote;
    return e;
}

// ---------------------------------------------------------------- saving --
Json json_for_field(const World& w, const FieldInfo& f, const void* obj) {
    if (f.kind == FieldKind::Entity) return entity_ref_json(w, *static_cast<const Entity*>(f.ptr(obj)));
    return field_to_json(f, obj);
}

}  // namespace

// ------------------------------------------------------------- components --
Json component_to_json(const World& world, Entity e, const TypeInfo& type, bool includeDefaults, bool includeRuntime) {
    Json out = Json::object();
    const void* obj = world.get(e, type);
    if (!obj) return out;
    DefaultObject def(type);
    for (const FieldInfo& f : type.fields) {
        if (!f.serialized && !includeRuntime) continue;
        Json v = json_for_field(world, f, obj);
        if (!includeDefaults && v == json_for_field(world, f, def.get())) continue;
        out[f.name] = std::move(v);
    }
    return out;
}

Result<void> patch_component(World& world, Entity e, const TypeInfo& type, const Json& fields) {
    if (!world.alive(e)) return make_error("Cannot patch a component on a dead entity", "Check that the entity still exists.");
    LoadReport report;
    Loader loader(world, report, "<patch>");
    bool existed = world.get(e, type) != nullptr;
    std::unique_ptr<DefaultObject> backup;
    if (existed && type.name != "EntityInfo") {
        backup = std::make_unique<DefaultObject>(type);
        type.copy_assign(backup->get(), world.get(e, type));
    }

    if (type.name == "EntityInfo") {
        if (!fields.is_object()) return make_error("EntityInfo patch must be a JSON object", "Fields: id, name, tags, active.");
        for (auto it = fields.begin(); it != fields.end(); ++it) {
            const std::string& k = it.key();
            if (k == "id" || k == "name" || k == "tags" || k == "active")
                loader.apply_info_key(e, k, it.value(), "/" + k, false);
            else
                loader.error("/" + k, "Unknown field '" + k + "' on EntityInfo", "Valid: id, name, tags, active.");
        }
    } else {
        loader.apply_component(e, type, fields, "", false);
    }

    if (report.error_count() > 0) {
        if (backup) type.copy_assign(world.get(e, type), backup->get());  // all-or-nothing
        else if (!existed && type.name != "EntityInfo") world.remove(e, type);
        std::string msg;
        std::string hint;
        for (const LoadMessage& m : report.messages) {
            if (m.severity != LoadMessage::Severity::Error) continue;
            if (!msg.empty()) msg += "; ";
            msg += (m.pointer.empty() ? "" : m.pointer.substr(1) + ": ") + m.message;
            if (hint.empty()) hint = m.hint;
        }
        return make_error(type.name + ": " + msg, hint);
    }
    return {};
}

// --------------------------------------------------------------- entities --
Json entity_to_json(const World& world, Entity e, const EntityJsonOptions& opts) {
    Json j = Json::object();
    if (!world.alive(e)) return j;
    const EntityInfo& inf = world.info(e);
    j["id"] = inf.id;
    if (!inf.name.empty() || opts.includeDefaults) j["name"] = inf.name;
    if (!inf.tags.empty() || opts.includeDefaults) {
        Json tags = Json::array();
        for (const auto& t : inf.tags) tags.push_back(t);
        j["tags"] = tags;
    }
    if (!inf.active || opts.includeDefaults) j["active"] = inf.active;

    Json comps = Json::object();
    for (const TypeInfo* t : world.components_of(e)) {
        if (t->name == "EntityInfo") continue;
        Json c = component_to_json(world, e, *t, opts.includeDefaults, opts.includeRuntime);
        if (t->name == "Transform" && c.empty()) continue;  // default transform is implicit
        comps[t->name] = std::move(c);
    }
    if (!comps.empty()) j["components"] = std::move(comps);

    if (opts.includeChildren && !world.children(e).empty()) {
        Json kids = Json::array();
        for (Entity c : world.children(e)) kids.push_back(entity_to_json(world, c, opts));
        j["children"] = std::move(kids);
    }
    return j;
}

Entity entity_from_json(World& world, const Json& entity, Entity parent, LoadReport& report, std::string_view sourceName,
                        std::string_view pointer) {
    Loader loader(world, report, std::string(sourceName));
    Entity e = loader.load_entity(entity, parent, std::string(pointer), false);
    loader.resolve_pending();
    return e;
}

// ----------------------------------------------------------------- scenes --
LoadReport load_scene(World& world, const Json& scene, std::string_view sourceName, const SceneLoadOptions& opts) {
    LoadReport report;
    Loader loader(world, report, std::string(sourceName));
    if (!scene.is_object()) {
        loader.error("", "A scene file must be a JSON object, got " + describe_json_value(scene),
                     std::string("Start from {\"format\": \"") + kSceneFormat + "\", \"entities\": []}.");
        return report;
    }
    if (scene.contains("format") && scene["format"].is_string()) {
        const std::string fmt = scene["format"].get<std::string>();
        if (fmt == kPrefabFormat) {
            loader.error("/format", "This file is a prefab, not a scene",
                         "Instantiate it with a scene entity {\"prefab\": \"<path>\"} or the scene.instantiate_prefab command.");
            return report;
        }
        if (fmt != kSceneFormat)
            loader.warn("/format", "Unknown scene format '" + fmt + "'; expected '" + std::string(kSceneFormat) + "'",
                        "Loading continues, but newer files may use features this engine does not know.");
    } else {
        loader.warn("/format", "Missing \"format\"", std::string("Add \"format\": \"") + kSceneFormat + "\" as the first key.");
    }
    static const std::vector<std::string> topKeys = {"format", "settings", "entities"};
    for (auto it = scene.begin(); it != scene.end(); ++it) {
        const std::string& k = it.key();
        if (std::find(topKeys.begin(), topKeys.end(), k) != topKeys.end()) continue;
        if (k == "$schema" || k == "name" || k == "description" || k == "_comment") continue;
        loader.warn("/" + escape_token(k), "Unknown top-level key '" + k + "' (ignored)", did_you_mean(k, topKeys));
    }

    if (!opts.additive) world.clear();

    if (scene.contains("settings") && !opts.additive) {
        const Json& s = scene["settings"];
        const TypeInfo* st = TypeRegistry::global().find("SceneSettings");
        if (!s.is_object()) {
            loader.error("/settings", "'settings' must be an object, got " + describe_json_value(s), "Example: \"settings\": {\"gravity2D\": [0, -980]}.");
        } else if (st) {
            std::vector<std::string> names;
            for (const FieldInfo& f : st->fields) names.push_back(f.name);
            for (auto it = s.begin(); it != s.end(); ++it) {
                std::string fptr = "/settings/" + escape_token(it.key());
                const FieldInfo* f = st->field(it.key());
                if (!f) {
                    loader.error(fptr, "Unknown scene setting '" + it.key() + "'", did_you_mean(it.key(), names));
                    continue;
                }
                if (auto r = field_from_json(*f, &world.settings(), it.value()); !r) loader.error(fptr, r.error().message, r.error().hint);
            }
        }
    }

    if (scene.contains("entities")) {
        const Json& ents = scene["entities"];
        if (!ents.is_array()) {
            loader.error("/entities", "'entities' must be an array of entity objects, got " + describe_json_value(ents),
                         "Example: \"entities\": [{\"id\": \"player\", \"components\": {...}}].");
        } else {
            for (std::size_t i = 0; i < ents.size(); ++i) loader.load_entity(ents[i], opts.parent, "/entities/" + std::to_string(i), false);
        }
    }
    loader.resolve_pending();
    if (!opts.additive && !sourceName.empty() && sourceName.front() != '<') world.set_scene_path(std::string(sourceName));
    return report;
}

LoadReport load_scene_file(World& world, std::string_view path, const SceneLoadOptions& opts) {
    auto json = load_json_file(path);
    if (!json) {
        LoadReport report;
        report.messages.push_back({LoadMessage::Severity::Error, std::string(path), "", json.error().message, json.error().hint});
        return report;
    }
    return load_scene(world, json.value(), path, opts);
}

Json save_scene(const World& world) {
    Json scene = Json::object();
    scene["format"] = kSceneFormat;
    const TypeInfo* st = TypeRegistry::global().find("SceneSettings");
    scene["settings"] = st ? object_to_json(*st, &world.settings(), false) : Json::object();
    Json ents = Json::array();
    for (Entity e : world.roots()) ents.push_back(entity_to_json(world, e));
    scene["entities"] = std::move(ents);
    return scene;
}

Result<void> save_scene_file(const World& world, std::string_view path) { return save_json_file(path, save_scene(world)); }

// ---------------------------------------------------------------- prefabs --
Entity instantiate_prefab(World& world, std::string_view prefabPath, Entity parent, LoadReport& report, const Json& overrides) {
    std::string path(prefabPath);
    Json holder = Json::object({{"prefab", path}});
    if (overrides.is_object())
        for (auto it = overrides.begin(); it != overrides.end(); ++it) holder[it.key()] = *it;
    else if (!overrides.is_null())
        report.messages.push_back({LoadMessage::Severity::Error, path, "", "Prefab overrides must be a JSON object, got " + describe_json_value(overrides),
                                   "Example: {\"name\": \"Boss\", \"components\": {\"Transform\": {\"position\": [0, 0, 0]}}}."});
    Loader loader(world, report, path);
    Entity e = loader.load_entity(holder, parent, "", true);
    loader.resolve_pending();
    return e;
}

Json make_prefab(const World& world, Entity root) {
    Json p = Json::object();
    p["format"] = kPrefabFormat;
    p["entity"] = entity_to_json(world, root);
    return p;
}

// ---------------------------------------------------------------- schemas --
namespace {

Json entity_schema() {
    Json compProps = Json::object();
    for (const TypeInfo* t : TypeRegistry::global().all()) {
        if (is_special_type(*t)) continue;
        compProps[t->name] = Json::object({{"$ref", "#/$defs/" + t->name}});
    }
    Json tags = Json::object({{"type", "array"}, {"items", Json::object({{"type", "string"}})},
                              {"description", "Free-form labels, e.g. [\"enemy\", \"flying\"]. Find entities with world.findByTag."}});
    Json props = Json::object();
    props["id"] = Json::object({{"type", "string"}, {"description", "Stable unique id within the scene (e.g. \"player\"). Auto-generated if omitted. Entity fields reference entities by this id."}});
    props["name"] = Json::object({{"type", "string"}, {"description", "Display name (not unique)."}});
    props["tags"] = tags;
    props["active"] = Json::object({{"type", "boolean"}, {"default", true}, {"description", "false disables the entity and its children."}});
    props["prefab"] = Json::object({{"type", "string"}, {"x-assetType", "prefab"},
                                    {"description", "Optional prefab file to start from; the keys below are applied as overrides (components deep-merge, children are appended)."}});
    props["components"] = Json::object({{"type", "object"}, {"properties", compProps}, {"additionalProperties", false},
                                        {"description", "Component name -> (partial) field object. Missing fields keep their defaults."}});
    props["children"] = Json::object({{"type", "array"}, {"items", Json::object({{"$ref", "#/$defs/Entity"}})},
                                      {"description", "Child entities (positions are relative to this entity)."}});
    return Json::object({{"type", "object"}, {"properties", props}, {"additionalProperties", false}});
}

Json schema_defs() {
    Json defs = Json::object();
    defs["Entity"] = entity_schema();
    for (const TypeInfo* t : TypeRegistry::global().all()) {
        if (t->name == "EntityInfo") continue;
        defs[t->name] = type_json_schema(*t);
    }
    return defs;
}

}  // namespace

Json scene_json_schema() {
    Json s = Json::object();
    s["$schema"] = "https://json-schema.org/draft/2020-12/schema";
    s["title"] = "FactorIA scene";
    s["description"] = "A scene: settings plus a tree of entities, each with components.";
    s["type"] = "object";
    s["properties"] = Json::object({
        {"$schema", Json::object({{"type", "string"}})},
        {"name", Json::object({{"type", "string"}})},
        {"format", Json::object({{"const", kSceneFormat}})},
        {"settings", Json::object({{"$ref", "#/$defs/SceneSettings"}})},
        {"entities", Json::object({{"type", "array"}, {"items", Json::object({{"$ref", "#/$defs/Entity"}})}})},
    });
    s["required"] = Json::array({"format", "entities"});
    s["additionalProperties"] = false;
    s["$defs"] = schema_defs();
    return s;
}

Json prefab_json_schema() {
    Json s = Json::object();
    s["$schema"] = "https://json-schema.org/draft/2020-12/schema";
    s["title"] = "FactorIA prefab";
    s["description"] = "A reusable entity tree. Instantiate with scene entities {\"prefab\": path} or the scene.instantiate_prefab command.";
    s["type"] = "object";
    s["properties"] = Json::object({
        {"$schema", Json::object({{"type", "string"}})},
        {"format", Json::object({{"const", kPrefabFormat}})},
        {"entity", Json::object({{"$ref", "#/$defs/Entity"}})},
    });
    s["required"] = Json::array({"format", "entity"});
    s["additionalProperties"] = false;
    s["$defs"] = schema_defs();
    return s;
}

}  // namespace fa
