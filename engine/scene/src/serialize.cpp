#include "fa/scene/serialize.h"

#include <algorithm>
#include <iterator>
#include <limits>
#include <set>
#include <span>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/scene/tilemap.h"

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
    void defer_missing_refs() { deferMissing_ = true; }
    World& world() { return world_; }

private:
    bool expand_prefab(const Json& j, const std::string& ptr, Json& out);
    bool apply_child_overrides(Json& root, const Json& overrides, const std::string& ptr, const std::string& prefabPath);
    void resolve_one(const PendingRef& ref);

    World& world_;
    LoadReport& report_;
    std::string source_;
    std::string note_;  // appended to hints while inside a prefab-expanded entity
    std::vector<PendingRef> pending_;
    bool deferMissing_ = false;  // a reference to an id that does not exist yet is a warning and goes to report_.deferred
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
                     "Entity ids must be unique within a scene. References to '" + want + "' point at the first entity with that id. "
                     "If the file lists entities that a script also spawns at start, it was probably saved by an older engine "
                     "that wrote script-spawned entities into the scene: delete those entries from the scene file (the script "
                     "creates them again on load). Otherwise give the entities different ids.");
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
            // null and "" both mean "no entity" (Joint3D.connected: "" = the world, as the field doc says).
            if (it.value().is_null() || (it.value().is_string() && it.value().get_ref<const std::string&>().empty())) {
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
        const std::string where = "'" + v.get<std::string>() + "' for field '" + ref.type->name + "." + ref.field->name + "'";
        if (deferMissing_) {
            warn(ref.pointer, "No entity with id " + where + " yet; the field stays empty until one appears",
                 "Spawn the entity with that id (e.g. as a child right after this one) and the field is set then; if it never "
                 "appears the engine warns again and leaves the field empty. " + did_you_mean(v.get<std::string>(), ids, 20));
            report_.deferred.push_back({ref.owner, ref.type, ref.field, v.get<std::string>(), ref.pointer});
            return;
        }
        error(ref.pointer, "No entity with id " + where, did_you_mean(v.get<std::string>(), ids, 20));
        return;
    }
    *static_cast<Entity*>(ref.field->ptr(obj)) = target;
}

void Loader::resolve_pending() {
    for (const PendingRef& r : pending_) resolve_one(r);
    pending_.clear();
}

namespace {
// Collects every descendant of `node` as (path of ids-or-names, pointer to the JSON), pre-order.
void collect_descendants(Json& node, const std::string& prefix, std::vector<std::pair<std::string, Json*>>& out) {
    if (!node.contains("children") || !node["children"].is_array()) return;
    for (Json& c : node["children"]) {
        if (!c.is_object()) continue;
        std::string label;
        if (c.contains("id") && c["id"].is_string()) label = c["id"].get<std::string>();
        else if (c.contains("name") && c["name"].is_string()) label = c["name"].get<std::string>();
        else label = "#" + std::to_string(&c - &node["children"][0]);
        std::string path = prefix.empty() ? label : prefix + "/" + label;
        out.emplace_back(path, &c);
        collect_descendants(c, path, out);
    }
}
bool json_names(const Json& c, const std::string& seg) {
    return (c.contains("id") && c["id"].is_string() && c["id"].get<std::string>() == seg) ||
           (c.contains("name") && c["name"].is_string() && c["name"].get<std::string>() == seg);
}
}  // namespace

// Applies {"<child id|name|path>": {name, tags, active, components}} to the descendants of a prefab's entity JSON.
bool Loader::apply_child_overrides(Json& root, const Json& overrides, const std::string& ptr, const std::string& prefabPath) {
    if (!overrides.is_object()) {
        error(ptr, "'overrides' must be an object mapping a child of the prefab to the fields to change, got " + describe_json_value(overrides),
              "Example: \"overrides\": {\"Title\": {\"components\": {\"Text\": {\"text\": \"You won\"}}}}.");
        return false;
    }
    std::vector<std::pair<std::string, Json*>> all;
    collect_descendants(root, "", all);
    bool ok = true;
    static const std::vector<std::string> allowed = {"name", "tags", "active", "components"};
    for (auto it = overrides.begin(); it != overrides.end(); ++it) {
        const std::string key = it.key();
        const std::string kptr = ptr + "/" + escape_token(key);
        Json* target = nullptr;
        if (key.find('/') == std::string::npos) {
            for (auto& [path, node] : all)
                if (json_names(*node, key)) { target = node; break; }
        } else {
            // A path: each segment is the id or the name of a child of the previous one.
            Json* cur = &root;
            std::size_t pos = 0;
            while (cur && pos <= key.size()) {
                std::size_t slash = key.find('/', pos);
                const std::string seg = key.substr(pos, slash == std::string::npos ? std::string::npos : slash - pos);
                Json* next = nullptr;
                if (cur->contains("children") && (*cur)["children"].is_array())
                    for (Json& c : (*cur)["children"])
                        if (c.is_object() && json_names(c, seg)) { next = &c; break; }
                cur = next;
                if (slash == std::string::npos) break;
                pos = slash + 1;
            }
            target = cur;
        }
        if (!target) {
            std::vector<std::string> cands;
            auto add = [&](const std::string& c) {
                if (std::find(cands.begin(), cands.end(), c) == cands.end()) cands.push_back(c);
            };
            for (auto& [path, node] : all) {
                add(path);
                for (const char* k : {"id", "name"})
                    if (node->contains(k) && (*node)[k].is_string()) add((*node)[k].get<std::string>());
            }
            error(kptr, "Prefab '" + prefabPath + "' has no child '" + key + "' to override",
                  cands.empty() ? "The prefab has no children; to change its root put the fields next to \"prefab\"."
                                : did_you_mean(key, cands, 20) + " A child is named by its id, its name or a path like \"Panel/Title\".");
            ok = false;
            continue;
        }
        if (!it->is_object()) {
            error(kptr, "The override of '" + key + "' must be an object, got " + describe_json_value(*it),
                  "Example: {\"components\": {\"Text\": {\"text\": \"Hello\"}}}.");
            ok = false;
            continue;
        }
        for (auto f = it->begin(); f != it->end(); ++f) {
            if (std::find(allowed.begin(), allowed.end(), f.key()) == allowed.end()) {
                error(kptr + "/" + escape_token(f.key()), "Unknown key '" + f.key() + "' in the override of '" + key + "'",
                      did_you_mean(f.key(), allowed) + " An override changes name, tags, active and components.");
                ok = false;
            } else if (f.key() == "components" && f->is_object()) {
                if (!target->contains("components") || !(*target)["components"].is_object()) (*target)["components"] = Json::object();
                json_merge((*target)["components"], *f);
            } else {
                (*target)[f.key()] = *f;
            }
        }
    }
    return ok;
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
    if (j.contains("overrides") && !apply_child_overrides(merged, j["overrides"], ptr + "/overrides", path)) {
        // errors are reported; keep expanding so every problem of the file shows up at once
    }
    for (auto it = j.begin(); it != j.end(); ++it) {
        const std::string& k = it.key();
        if (k == "prefab" || k == "overrides") continue;
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
        // Tilemap data (tiles vs width*height, rows, solidTiles) is checked once all its fields are in.
        if (const Tilemap* tm = world_.get<Tilemap>(e)) {
            for (const TilemapIssue& issue : check_tilemap(*tm)) {
                std::string tptr = cptr + "/Tilemap" + issue.pointer;
                if (issue.error) error(tptr, issue.message, issue.hint);
                else warn(tptr, issue.message, issue.hint);
            }
            if (!tm->normalMap.empty() && !tm->lit)
                warn(cptr + "/Tilemap/normalMap", "Tilemap.normalMap is set but Tilemap.lit is false, so the normal map is not used",
                     "Set \"lit\": true and add a Light2D entity, or remove normalMap.");
        }
        if (const Sprite* sp = world_.get<Sprite>(e)) {
            if (!sp->normalMap.empty() && !sp->lit)
                warn(cptr + "/Sprite/normalMap", "Sprite.normalMap is set but Sprite.lit is false, so the normal map is not used",
                     "Set \"lit\": true and add a Light2D entity, or remove normalMap.");
            if (sp->slice.x < 0 || sp->slice.y < 0 || sp->slice.z < 0 || sp->slice.w < 0)
                error(cptr + "/Sprite/slice", "Sprite.slice has a negative border [" + std::to_string(sp->slice.x) + ", " + std::to_string(sp->slice.y) +
                      ", " + std::to_string(sp->slice.z) + ", " + std::to_string(sp->slice.w) + "]",
                      "slice is [left, top, right, bottom] in texture pixels, each 0 or more. Example: \"slice\": [8, 8, 8, 8].");
        }
        if (const Camera* cam = world_.get<Camera>(e)) {
            const std::string problem = camera_viewport_problem(cam->viewport);
            if (!problem.empty())
                error(cptr + "/Camera/viewport", problem,
                      "viewport is [x, y, width, height] as fractions of the screen with [0, 0] the top-left corner and +Y down, "
                      "inside 0..1. Left half: [0, 0, 0.5, 1]. Bottom-right quarter: [0.5, 0.5, 0.5, 0.5]. Whole screen: [0, 0, 1, 1].");
            const std::string targetProblem = camera_render_target_problem(*cam);
            if (!targetProblem.empty())
                error(cptr + "/Camera/renderTarget", targetProblem,
                      "renderTarget is a short name (letters, digits, '_', '-', '.') and renderTargetSize [width, height] is 1..4096 pixels "
                      "each. Example: \"renderTarget\": \"book\", \"renderTargetSize\": [1024, 768]; then use \"target:book\" as a texture.");
        }
        if (const Joint2D* jt = world_.get<Joint2D>(e)) {
            if (jt->enableLimit && jt->lowerLimit > jt->upperLimit)
                error(cptr + "/Joint2D/lowerLimit", "Joint2D.lowerLimit " + std::to_string(jt->lowerLimit) + " is above upperLimit " + std::to_string(jt->upperLimit),
                      "Swap them: lowerLimit <= upperLimit (revolute in degrees, prismatic and distance in world units).");
            if (jt->type == JointType2D::Revolute && jt->enableLimit && (jt->lowerLimit < -178.0f || jt->upperLimit > 178.0f))
                warn(cptr + "/Joint2D/lowerLimit", "A revolute limit beyond +-178 degrees is clamped to +-178 degrees",
                     "Box2D cannot limit a hinge to a full turn; use a motor or no limit for a free-spinning joint.");
            if (jt->type == JointType2D::Prismatic && jt->axis.x == 0.0f && jt->axis.y == 0.0f)
                error(cptr + "/Joint2D/axis", "A prismatic Joint2D needs a non-zero axis, got [0, 0]", "Example: \"axis\": [1, 0] slides along the entity's local x, [0, 1] along y.");
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
namespace {
std::size_t subtree_size(const World& world, Entity e) {
    std::size_t n = 1;
    for (Entity c : world.children(e)) n += subtree_size(world, c);
    return n;
}
// True when `e` was spawned by a script and so is left out (with its children); records it in opts.skipped.
bool skip_spawned_subtree(const World& world, Entity e, const EntityJsonOptions& opts) {
    if (!world.info(e).scriptSpawned) return false;
    if (opts.skipped) {
        opts.skipped->count += subtree_size(world, e);
        if (opts.skipped->labels.size() < 5) {
            const EntityInfo& inf = world.info(e);
            opts.skipped->labels.push_back(inf.name.empty() || inf.name == inf.id ? inf.id : inf.id + " (" + inf.name + ")");
        }
    }
    return true;
}

// Puts the rest value of every posed field of component `t` of `e` in `c` (the component's JSON): a field equal to its
// default is left out unless `includeDefaults`, like component_to_json does.
void apply_pose_rest(const PoseRest& pose, Entity e, const TypeInfo& t, bool includeDefaults, Json& c) {
    const auto first = std::lower_bound(pose.entries.begin(), pose.entries.end(), e.bits(),
                                        [](const PoseRestEntry& r, std::uint64_t bits) { return r.entity.bits() < bits; });
    for (auto it = first; it != pose.entries.end() && it->entity == e; ++it) {
        const PoseRestEntry& r = *it;
        if (r.type != &t) continue;
        DefaultObject def(t);
        if (!includeDefaults && r.value == field_to_json(*r.field, def.get())) c.erase(r.field->name);
        else c[r.field->name] = r.value;
    }
}
}  // namespace

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
        if (opts.poseRest) apply_pose_rest(*opts.poseRest, e, *t, opts.includeDefaults, c);
        if (t->name == "Transform" && c.empty()) continue;  // default transform is implicit
        comps[t->name] = std::move(c);
    }
    if (!comps.empty()) j["components"] = std::move(comps);

    if (opts.includeChildren && !world.children(e).empty()) {
        Json kids = Json::array();
        for (Entity c : world.children(e)) {
            if (opts.skipSpawned && skip_spawned_subtree(world, c, opts)) continue;
            kids.push_back(entity_to_json(world, c, opts));
        }
        if (!kids.empty()) j["children"] = std::move(kids);
    }
    return j;
}

Entity entity_from_json(World& world, const Json& entity, Entity parent, LoadReport& report, std::string_view sourceName,
                        std::string_view pointer, int index, bool deferMissingRefs) {
    Loader loader(world, report, std::string(sourceName));
    if (deferMissingRefs) loader.defer_missing_refs();
    Entity e = loader.load_entity(entity, parent, std::string(pointer), false);
    if (!e.is_null() && !parent.is_null() && index >= 0) world.set_parent(e, parent, false, index);
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

namespace {

// `settings` of a saved scene: the non-default fields, plus the gravity ALWAYS, even at its default. A scene that says
// `"settings": {}` hides what pulls its bodies down (and by how much), which a reader of the file cannot work out.
// Fields keep the order of the reflected type.
Json settings_to_json(const World& world) {
    const TypeInfo* st = TypeRegistry::global().find("SceneSettings");
    if (!st) return Json::object();
    static const char* const kAlwaysWritten[] = {"gravity2D", "gravity3D"};
    Json changed = object_to_json(*st, &world.settings(), false);
    Json all = object_to_json(*st, &world.settings(), true);
    Json out = Json::object();
    for (auto it = all.begin(); it != all.end(); ++it) {
        const bool always = std::find_if(std::begin(kAlwaysWritten), std::end(kAlwaysWritten),
                                         [&](const char* name) { return it.key() == name; }) != std::end(kAlwaysWritten);
        if (always || changed.contains(it.key())) out[it.key()] = *it;
    }
    return out;
}

}  // namespace

Json save_scene(const World& world, bool skipSpawned, SpawnedSkip* skipped) {
    const PoseRest pose = collect_pose_rest(world);
    EntityJsonOptions eo;
    eo.skipSpawned = skipSpawned;
    eo.skipped = skipped;
    if (!pose.empty()) eo.poseRest = &pose;
    Json scene = Json::object();
    scene["format"] = kSceneFormat;
    scene["settings"] = settings_to_json(world);
    Json ents = Json::array();
    for (Entity e : world.roots()) {
        if (skipSpawned && skip_spawned_subtree(world, e, eo)) continue;
        ents.push_back(entity_to_json(world, e, eo));
    }
    scene["entities"] = std::move(ents);
    return scene;
}

namespace {

// Elements per line for a flat Tilemap `tiles` array: the component's `width` (0 = no row layout).
int tilemap_row_length(std::span<const std::string> path, const Json& parent, const Json&) {
    const std::size_t n = path.size();
    if (n < 3 || path[n - 1] != "tiles" || path[n - 2] != "Tilemap" || path[n - 3] != "components") return 0;
    if (!parent.is_object()) return 0;
    auto it = parent.find("width");
    if (it == parent.end() || !it->is_number_integer()) return 0;
    const std::int64_t width = it->get<std::int64_t>();
    return width > 0 && width <= std::numeric_limits<int>::max() ? static_cast<int>(width) : 0;
}

const JsonFormat& scene_json_format() {
    static const JsonFormat format = [] {
        JsonFormat f;
        f.maxWidth = 100;
        f.rowLength = tilemap_row_length;
        return f;
    }();
    return format;
}

}  // namespace

std::string dump_scene_json(const Json& sceneOrPrefab) { return dump_json(sceneOrPrefab, scene_json_format()); }

Result<void> save_scene_json_file(std::string_view path, const Json& sceneOrPrefab) {
    return save_json_file(path, sceneOrPrefab, scene_json_format());
}

Result<CanonicalScene> canonical_scene_layout(std::string_view file) {
    auto bytes = fs::read_bytes(file);
    if (!bytes.ok()) return bytes.error();
    const std::string text(bytes->begin(), bytes->end());
    const bool bom = starts_with(text, "\xEF\xBB\xBF");
    auto parsed = parse_json(std::string_view(text).substr(bom ? 3 : 0), file);
    if (!parsed.ok()) return parsed.error();
    if (!parsed->is_object())
        return make_error(std::string(file) + ": a scene or prefab file must be a JSON object, got " + describe_json_value(*parsed),
                          "Start from {\"format\": \"factoria.scene/1\", \"entities\": []} or "
                          "{\"format\": \"factoria.prefab/1\", \"entity\": {...}}.");
    CanonicalScene out;
    out.text = dump_scene_json(*parsed);
    auto again = parse_json(out.text, file);
    if (!again.ok() || *again != *parsed)
        return make_error(std::string(file) + ": the canonical layout would not read back as the same data.",
                          "This is an engine bug: report it with feedback.report and attach the file.");
    out.same = text == out.text;
    return out;
}

bool is_scene_or_prefab_file(std::string_view path) {
    const std::string lower = to_lower(path);
    return ends_with(lower, ".scene.json") || ends_with(lower, ".prefab.json");
}

std::vector<std::string> project_scene_files(std::string_view dir) {
    std::vector<std::string> out;
    const std::string prefix = dir.empty() ? std::string() : std::string(dir) + "/";
    for (const std::string& f : fs::list(dir.empty() ? "." : dir, true, ".json")) {
        if (!is_scene_or_prefab_file(f)) continue;
        const std::vector<std::string> parts = split(f.substr(prefix.size()), '/');
        const bool skip = [&] {  // a folder of tool state or copies somewhere on the way
            for (std::size_t i = 0; i + 1 < parts.size(); ++i)
                if ((!parts[i].empty() && parts[i][0] == '.') || parts[i] == "node_modules" || (i == 0 && dir.empty() && parts[i] == "build"))
                    return true;
            return false;
        }();
        if (!skip) out.push_back(f);
    }
    return out;
}

Result<void> save_scene_file(const World& world, std::string_view path, bool includeSpawned, SpawnedSkip* skipped) {
    return save_scene_json_file(path, save_scene(world, !includeSpawned, skipped));
}

// ---------------------------------------------------------------- prefabs --
Entity instantiate_prefab(World& world, std::string_view prefabPath, Entity parent, LoadReport& report, const Json& overrides, int index) {
    std::string path(prefabPath);
    Json holder = Json::object({{"prefab", path}});
    if (overrides.is_object())
        for (auto it = overrides.begin(); it != overrides.end(); ++it) holder[it.key()] = *it;
    else if (!overrides.is_null())
        report.messages.push_back({LoadMessage::Severity::Error, path, "", "Prefab overrides must be a JSON object, got " + describe_json_value(overrides),
                                   "Example: {\"name\": \"Boss\", \"components\": {\"Transform\": {\"position\": [0, 0, 0]}}}."});
    Loader loader(world, report, path);
    Entity e = loader.load_entity(holder, parent, "", true);
    if (!e.is_null() && !parent.is_null() && index >= 0) world.set_parent(e, parent, false, index);
    loader.resolve_pending();
    return e;
}

Json make_prefab(const World& world, Entity root) {
    Json p = Json::object();
    p["format"] = kPrefabFormat;
    const PoseRest pose = collect_pose_rest(world);
    EntityJsonOptions eo;
    if (!pose.empty()) eo.poseRest = &pose;
    p["entity"] = entity_to_json(world, root, eo);
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
    props["overrides"] = Json::object({{"type", "object"}, {"additionalProperties", Json::object({{"type", "object"}})},
                                       {"description", "Only with \"prefab\": patches for the prefab's own descendants. Each key is a child's id or name, "
                                                       "or a path of ids/names like \"Panel/Title\"; each value holds name, tags, active and components "
                                                       "(components deep-merge). A key that matches no child is an error."}});
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
