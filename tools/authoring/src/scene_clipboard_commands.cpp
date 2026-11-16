// The entity clipboard, as commands (the editor's Copy, Cut, Paste and Duplicate use them; so can an AI or a script):
//   scene.copy_entities   writes entities of the running world, with their subtrees, as one self-contained JSON text;
//   scene.paste_entities  creates the entities of such a text in the running world and returns the new ids.
// The text is {"format": "factoria.entities/1", "entities": [{"parent": "<id>"?, "entity": <entity JSON>}, ...]}. The entity
// JSON is what an undo snapshot holds (PrefabSave::Marks): inline components and children, plus the "$prefab" and
// "$fromPrefab" keys that keep an instance linked to its prefab. Nothing in it names a file of this project, so it can be
// pasted into another scene, another project or another editor.
// Paste gives every entity an id that is free in the destination, and rewrites the Entity fields that name an entity of the
// copied set so they name the new copy. A field that names an entity outside the set keeps its target when the destination
// scene has an entity with that id, and is cleared (and listed in the result) when it has not.
#include <algorithm>
#include <cctype>
#include <set>
#include <unordered_map>

#include "authoring_internal.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/scene/serialize.h"

namespace fa {

namespace {

constexpr const char* kEntitiesFormat = "factoria.entities/1";
constexpr const char* kEntitiesFormatPrefix = "factoria.entities/";

[[noreturn]] void bad_arg(const std::string& message, const std::string& hint = {}) {
    throw CommandError("invalid_argument", message, hint);
}

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

void count_tree(const World& w, Entity e, std::size_t& n) {
    ++n;
    for (Entity c : w.children(e)) count_tree(w, c, n);
}

bool all_digits(const std::string& s, std::size_t from) {
    return from < s.size() && std::all_of(
                                  s.begin() + static_cast<std::ptrdiff_t>(from), s.end(),
                                  [](unsigned char c) { return std::isdigit(c) != 0; });
}

// ------------------------------------------------------------------------------------------ scene.copy_entities
Json copy_entities(Engine::Impl& I, const Json& a) {
    World& W = I.world;
    if (!a.contains("ids") || !a["ids"].is_array() || a["ids"].empty())
        bad_arg("/ids: 'ids' must be a non-empty array of entity ids (or names).",
                "Example: scene.copy_entities {\"ids\":[\"player\",\"coin_3\"]}. scene.list_entities lists the ids.");
    std::vector<Entity> picked;
    for (std::size_t i = 0; i < a["ids"].size(); ++i) {
        if (!a["ids"][i].is_string())
            bad_arg("/ids/" + std::to_string(i) + ": an entity id must be a string.",
                    "Use scene.list_entities to find entity ids.");
        const Entity e = need_entity(W, Json::object({{"id", a["ids"][i]}}));
        if (std::find(picked.begin(), picked.end(), e) == picked.end()) picked.push_back(e);
    }
    // An entity whose ancestor is in the list is copied with that ancestor.
    std::vector<Entity> roots;
    for (Entity e : picked) {
        bool covered = false;
        for (Entity p = W.parent(e); !p.is_null() && !covered; p = W.parent(p))
            covered = std::find(picked.begin(), picked.end(), p) != picked.end();
        if (!covered) roots.push_back(e);
    }
    const PoseRest pose = collect_pose_rest(W);  // an animated field is copied at its rest value, not at the pose
    EntityJsonOptions o;
    o.prefabs = PrefabSave::Marks;
    if (!pose.empty()) o.poseRest = &pose;
    Json entries = Json::array();
    Json rootIds = Json::array();
    std::size_t count = 0;
    for (Entity e : roots) {
        Json entry = Json::object();
        if (Entity p = W.parent(e)) entry["parent"] = W.id_of(p);
        entry["entity"] = entity_to_json(W, e, o);
        entries.push_back(std::move(entry));
        rootIds.push_back(W.id_of(e));
        count_tree(W, e, count);
    }
    Json payload = Json::object({{"format", kEntitiesFormat}, {"entities", std::move(entries)}});
    if (a.contains("primary") && !a["primary"].is_null()) {
        if (!a["primary"].is_string())
            bad_arg("/primary: 'primary' must be an entity id (or name) string.",
                    "Use scene.list_entities to find ids.");
        const Entity p = need_entity(W, Json::object({{"id", a["primary"]}}));
        bool inside = false;  // it is one of the copied entities, or below one
        for (Entity x = p; !x.is_null() && !inside; x = W.parent(x))
            inside = std::find(roots.begin(), roots.end(), x) != roots.end();
        if (!inside)
            bad_arg("/primary: '" + a["primary"].get<std::string>() + "' is not one of the copied entities.",
                    "'primary' marks the copied entity that a paste reports as `primary` (the editor selects it "
                    "last): pass one of 'ids', or an entity below one.");
        payload["primary"] = W.id_of(p);
    }
    Json out = Json::object();
    out["text"] = payload.dump(-1, ' ', false, Json::error_handler_t::replace);  // bad UTF-8 in a name does not throw
    out["count"] = count;
    out["roots"] = std::move(rootIds);
    return out;
}

// ---------------------------------------------------------------------------------------- scene.paste_entities
// One entity of the text, wherever it sits in the tree.
struct PayloadEntity {
    Json* json = nullptr;
    std::string pointer;   // where it is in the text, for error messages
    std::size_t root = 0;  // which entry of "entities" it belongs to
};

constexpr int kMaxPayloadDepth = 64;  // levels of children in a pasted text

// A "$prefab" mark names the prefab file an instance came from; one that leaves the project is refused.
void check_prefab_mark(const Json& entity, const std::string& pointer) {
    if (!entity.contains("$prefab") || !entity["$prefab"].is_string()) return;
    const std::string path = entity["$prefab"].get<std::string>();
    if (path.empty()) return;
    auto norm = fs::normalize_checked(path);
    if (fs::is_absolute(path) || !norm.ok() || path.find("..") != std::string::npos)
        bad_arg(pointer + "/$prefab: '" + path + "' is not a project-relative prefab path.",
                "A copied text holds the entities inline and links an instance to its prefab with a path such as "
                "prefabs/enemy.prefab.json inside this project. Copy the entities again with scene.copy_entities.");
}

void collect_payload(Json& entity, const std::string& pointer, std::size_t root, int depth,
                     std::vector<PayloadEntity>& out) {
    if (!entity.is_object())
        bad_arg(pointer + ": an entity must be a JSON object.", "Copy the entities again with scene.copy_entities.");
    if (depth > kMaxPayloadDepth)
        bad_arg(pointer + ": the entities are nested more than " + std::to_string(kMaxPayloadDepth) + " levels deep.",
                "A copied text is as deep as the entities were: copy fewer levels with scene.copy_entities.");
    if (entity.contains("prefab"))
        bad_arg(pointer +
                    "/prefab: a copied text holds the entities inline and has no 'prefab' key (it would load a file).",
                "Spawn a prefab with scene.spawn {\"prefab\": path}, or copy the entities again with "
                "scene.copy_entities.");
    check_prefab_mark(entity, pointer);
    out.push_back({&entity, pointer, root});
    if (!entity.contains("children")) return;
    Json& kids = entity["children"];
    if (!kids.is_array())
        bad_arg(pointer + "/children: 'children' must be an array of entities.",
                "Copy the entities again with scene.copy_entities.");
    for (std::size_t i = 0; i < kids.size(); ++i)
        collect_payload(kids[i], pointer + "/children/" + std::to_string(i), root, depth + 1, out);
}

bool is_auto_id(const std::string& id) { return id.size() >= 2 && id[0] == 'e' && all_digits(id, 1); }

// Ids that are free in the destination: "coin_3" -> "coin_4", "coin" -> "coin_2", the engine's own "e12" -> "e<next>".
class IdMaker {
public:
    IdMaker(const World& w, std::set<std::string> reserved) : w_(w), reserved_(std::move(reserved)) {}
    std::string make(const std::string& wanted) {
        std::string base = "e";
        unsigned long long n = static_cast<unsigned long long>(w_.entity_count()) + 1;
        if (!wanted.empty() && !is_auto_id(wanted)) {
            base = wanted;
            n = 2;
            const std::size_t us = wanted.rfind('_');
            if (us != std::string::npos && wanted.size() - us <= 10 && all_digits(wanted, us + 1)) {
                base = wanted.substr(0, us);
                n = std::stoull(wanted.substr(us + 1)) + 1;
            }
        }
        for (;; ++n) {
            const std::string candidate = base + (base == "e" ? "" : "_") + std::to_string(n);
            if (w_.find_by_id(candidate).is_null() && !used_.count(candidate) && !reserved_.count(candidate)) {
                used_.insert(candidate);
                return candidate;
            }
        }
    }

private:
    const World& w_;
    std::set<std::string> reserved_;  // ids of the text that keep their name
    std::set<std::string> used_;
};

// An Entity field of a pasted entity, set once every entity of the text exists.
struct PendingRef {
    std::string owner;  // new id of the entity that holds the field
    const TypeInfo* type = nullptr;
    const FieldInfo* field = nullptr;
    std::string target;  // id of the entity the field names in the destination
};

const FieldInfo* find_field_ci(const TypeInfo& t, const std::string& key) {
    if (const FieldInfo* f = t.field(key)) return f;
    for (const FieldInfo& f : t.fields)
        if (iequals(f.name, key)) return &f;
    return nullptr;
}

Json paste_entities(Engine::Impl& I, const Json& a) {
    World& W = I.world;
    const bool keepParents = a.value("keepParents", false);
    if (keepParents && a.contains("parent"))
        bad_arg("/keepParents: contradicts /parent: 'parent' puts every pasted entity under one parent, 'keepParents' "
                "puts each under the parent it had when it was copied.",
                "Pass one of them. parent null puts everything at the top level.");
    const std::string suffix = a.value("nameSuffix", std::string());
    Entity parent = kNullEntity;
    if (a.contains("parent") && !a["parent"].is_null()) {
        if (!a["parent"].is_string())
            bad_arg("/parent: 'parent' must be an entity id string or null.", "Use scene.list_entities to find ids.");
        if (!a["parent"].get<std::string>().empty()) parent = need_entity(W, a, "parent");
    }

    // ---- the text
    std::string text;
    if (a.contains("text") && a["text"].is_string()) text = a["text"].get<std::string>();
    const std::string hintCopy =
        "Make the text with scene.copy_entities (the editor's Copy does) and paste it unchanged.";
    if (text.find_first_not_of(" \t\r\n") == std::string::npos)
        bad_arg("/text: the text is empty, so there is nothing to paste.", hintCopy);
    auto parsed = parse_json(text, "clipboard text");
    if (!parsed.ok()) {
        const std::size_t first = text.find_first_not_of(" \t\r\n");
        if (text.compare(first, std::string("{\"format\":\"").size() + std::string(kEntitiesFormatPrefix).size(),
                         std::string("{\"format\":\"") + kEntitiesFormatPrefix) == 0)
            bad_arg("/text: the text starts like an entity clipboard but is not valid JSON: it looks cut short (" +
                        parsed.error().message + ").",
                    "Something cut the text (a clipboard or a message has a size limit): copy fewer entities, or pass "
                    "the whole text of scene.copy_entities.");
        bad_arg("/text: this is not an entity clipboard: " + parsed.error().message, hintCopy);
    }
    Json payload = std::move(parsed.value());
    if (!payload.is_object() || !payload.contains("format") || !payload["format"].is_string())
        bad_arg("/format: this JSON is not an entity clipboard: it has no \"format\" key (expected \"" +
                    std::string(kEntitiesFormat) + "\").",
                hintCopy);
    const std::string format = payload["format"].get<std::string>();
    if (format != kEntitiesFormat) {
        if (format.rfind(kEntitiesFormatPrefix, 0) == 0)
            bad_arg("/format: the clipboard is version '" + format.substr(std::string(kEntitiesFormatPrefix).size()) +
                        "' and this engine reads '" + kEntitiesFormat + "'.",
                    "Copy the entities again with this engine, or update FactorIA if the text comes from a newer one.");
        const bool file = format.rfind("factoria.scene", 0) == 0 || format.rfind("factoria.prefab", 0) == 0;
        bad_arg("/format: this JSON is '" + format + "', not an entity clipboard (\"" + kEntitiesFormat + "\").",
                (file ? "A scene or prefab file is loaded with scene.load, or spawned with scene.spawn "
                        "{\"prefab\": path}. "
                      : "") +
                    hintCopy);
    }
    if (!payload.contains("entities") || !payload["entities"].is_array() || payload["entities"].empty())
        bad_arg("/entities: 'entities' must be a non-empty array.", hintCopy);
    Json& entries = payload["entities"];
    std::vector<PayloadEntity> all;
    std::vector<Json*> rootJson;
    std::vector<std::string> rootParent;
    for (std::size_t i = 0; i < entries.size(); ++i) {
        const std::string ptr = "/entities/" + std::to_string(i);
        Json& entry = entries[i];
        if (!entry.is_object() || !entry.contains("entity"))
            bad_arg(ptr + ": every entry must be {\"entity\": {...}, \"parent\": \"<id>\"?}.", hintCopy);
        if (entry.contains("parent") && !entry["parent"].is_string())
            bad_arg(ptr + "/parent: 'parent' must be an entity id string.", hintCopy);
        rootParent.push_back(entry.value("parent", std::string()));
        rootJson.push_back(&entry["entity"]);
        collect_payload(entry["entity"], ptr + "/entity", i, 0, all);
    }
    // ---- new ids
    std::set<std::string> oldIds;
    for (const PayloadEntity& pe : all) {
        const Json& j = *pe.json;
        if (!j.contains("id")) continue;
        if (!j["id"].is_string() || j["id"].get_ref<const std::string&>().empty())
            bad_arg(pe.pointer + "/id: 'id' must be a non-empty string.", hintCopy);
        oldIds.insert(j["id"].get<std::string>());
    }
    std::string primaryOld;  // id (in the text) of the entity the copy marked as primary
    if (payload.contains("primary")) {
        if (!payload["primary"].is_string()) bad_arg("/primary: 'primary' must be an entity id string.", hintCopy);
        primaryOld = payload["primary"].get<std::string>();
    }
    // Which pasted root holds the primary: found now, while the ids in the text are still the old ones (and checked).
    std::size_t primaryRoot = entries.size();
    if (!primaryOld.empty())
        for (const PayloadEntity& pe : all)
            if (pe.json->value("id", std::string()) == primaryOld) {
                primaryRoot = pe.root;
                break;
            }
    // An id that is free in the destination stays; the others get a new one that no entity of the text wants either.
    std::set<std::string> keeping;
    for (const std::string& id : oldIds)
        if (W.find_by_id(id).is_null()) keeping.insert(id);
    IdMaker ids(W, keeping);
    std::set<std::string> claimed;
    std::unordered_map<std::string, std::string> remap;  // old id -> new id
    for (const PayloadEntity& pe : all) {
        Json& j = *pe.json;
        const std::string old = j.contains("id") ? j["id"].get<std::string>() : std::string();
        std::string fresh;
        if (!old.empty() && keeping.count(old) && claimed.insert(old).second)
            fresh = old;
        else
            fresh = ids.make(old);
        if (!old.empty() && !remap.count(old)) remap[old] = fresh;
        j["id"] = fresh;
    }

    // ---- Entity fields: inside the set they name the copies, outside they keep an existing target or are cleared
    Json cleared = Json::array();
    std::vector<PendingRef> pending;
    for (const PayloadEntity& pe : all) {
        Json& j = *pe.json;
        if (!j.contains("components") || !j["components"].is_object()) continue;
        const std::string owner = j["id"].get<std::string>();
        for (auto cit = j["components"].begin(); cit != j["components"].end(); ++cit) {
            const TypeInfo* type = TypeRegistry::global().find_ci(cit.key());
            if (!type || !cit.value().is_object()) continue;  // the load reports it
            Json& fields = cit.value();
            std::vector<std::string> keys;
            for (auto fit = fields.begin(); fit != fields.end(); ++fit) keys.push_back(fit.key());
            for (const std::string& key : keys) {
                const FieldInfo* f = find_field_ci(*type, key);
                if (!f || f->kind != FieldKind::Entity) continue;
                const Json value = fields[key];
                fields.erase(key);  // set below, when every entity exists
                if (!value.is_string() || value.get_ref<const std::string&>().empty()) continue;
                const std::string target = value.get<std::string>();
                if (auto m = remap.find(target); m != remap.end())
                    pending.push_back({owner, type, f, m->second});
                else if (!W.find_by_id(target).is_null())
                    pending.push_back({owner, type, f, target});
                else
                    cleared.push_back(Json::object(
                        {{"entity", owner}, {"component", type->name}, {"field", f->name}, {"target", target}}));
            }
        }
    }

    // ---- the entities
    if (!suffix.empty())
        for (std::size_t i = 0; i < rootJson.size(); ++i)
            if (rootJson[i]->contains("name") && !(*rootJson[i])["name"].is_string())
                bad_arg("/entities/" + std::to_string(i) + "/entity/name: 'name' must be a string.", hintCopy);
    LoadReport report;
    std::vector<Entity> created;
    Json newRoots = Json::array();
    // Every entity of the text got an id that was free here, so whatever exists under those ids was made by this paste: one
    // clean-up for the error path and for an exception, even from the middle of a load.
    auto rollback = [&] {
        for (const PayloadEntity& pe : all) {
            const Entity e = W.find_by_id((*pe.json)["id"].get<std::string>());
            if (!e.is_null() && W.alive(e)) W.destroy(e);
        }
        W.flush();
    };
    try {
        for (std::size_t i = 0; i < rootJson.size(); ++i) {
            Json& spec = *rootJson[i];
            if (!suffix.empty()) {
                const std::string name = spec.value("name", std::string());
                spec["name"] = (name.empty() ? std::string("Entity") : name) + suffix;
            }
            Entity where = parent;
            if (keepParents && !rootParent[i].empty()) where = W.find_by_id(rootParent[i]);
            LoadReport one;
            const Entity e = entity_from_json(W, spec, where, one, "scene.paste_entities",
                                              "/entities/" + std::to_string(i) + "/entity");
            for (Entity c : one.created) created.push_back(c);
            for (LoadMessage& m : one.messages) report.messages.push_back(std::move(m));
            if (e.is_null() || !W.alive(e)) {
                report.messages.push_back({LoadMessage::Severity::Error,
                                           "scene.paste_entities",
                                           "/entities/" + std::to_string(i),
                                           "The entity could not be created.",
                                           {}});
                break;
            }
            newRoots.push_back(W.id_of(e));
        }
    } catch (...) {
        rollback();
        throw;
    }
    if (report.error_count() > 0) {
        rollback();
        throw CommandError("invalid_argument", "Paste failed, nothing was created:\n" + report.summary(),
                           "The text came from another version or was edited: copy the entities again with "
                           "scene.copy_entities; api.components describes every component.");
    }
    for (const PendingRef& p : pending) {
        const Entity owner = W.find_by_id(p.owner);
        const Entity target = W.find_by_id(p.target);
        if (owner.is_null() || target.is_null()) continue;
        if (void* obj = W.get(owner, *p.type)) *static_cast<Entity*>(p.field->ptr(obj)) = target;
    }

    Json out = Json::object();
    if (primaryRoot < newRoots.size()) out["primary"] = newRoots[primaryRoot];
    out["ids"] = std::move(newRoots);
    out["count"] = created.size();
    out["cleared"] = std::move(cleared);
    if (!report.messages.empty()) {
        Json msgs = Json::array();
        for (const LoadMessage& m : report.messages) msgs.push_back(m.to_string());
        out["messages"] = std::move(msgs);
    }
    return out;
}

}  // namespace

void register_scene_clipboard_commands(Engine& engine, Engine::Impl& I) {
    (void)engine;
    I.commands.add(
        {"scene.copy_entities", "Write entities of the running world, with their subtrees, as one JSON text.",
         "Returns {text, count, roots}: `text` is self-contained (components, children, links to prefabs), so it can "
         "be kept, sent, or given to scene.paste_entities in this scene, another scene or another editor. `ids` are "
         "ids "
         "or names; an entity whose ancestor is also listed is copied with that ancestor, once. `count` is every "
         "entity "
         "in the text, `roots` the ids that head it. The world is not changed. Example: scene.copy_entities "
         "{\"ids\":[\"player\",\"coin_3\"]}" FA_COMMAND_DETAILS
         "The text is {\"format\":\"factoria.entities/1\",\"entities\":[{\"parent\":\"<id the root had>\"?,"
         "\"entity\":{...}}]}. The entity JSON is the one the editor's undo keeps: every serialized field that differs "
         "from its default, the children inline, and the `$prefab` / `$fromPrefab` keys that keep an instance of a "
         "prefab linked to it. Runtime state (velocities, animation time) is not copied, and a field an animation "
         "drives is copied at its rest value. Entity fields stay as the ids they hold; scene.paste_entities remaps "
         "them.",
         parse_schema(R"({"type":"object","required":["ids"],"properties":{
               "ids":{"type":"array","minItems":1,"items":{"type":"string"},"description":"Ids (or names) of the entities to copy; each is copied with all its children."},
               "primary":{"type":"string","description":"One of the copied entities (or one below them): scene.paste_entities returns the pasted root that holds its copy as `primary`, so the editor can select it last."}}})"),
         true, "scene"},
        [&I](const Json& a) { return copy_entities(I, a); });

    I.commands.add(
        {"scene.paste_entities", "Create the entities of a scene.copy_entities text in the running world.",
         "`text` is what scene.copy_entities returned, from this scene or another. Every pasted entity gets an id that "
         "is free here (the copied id when it is free, else the next number: coin_3 -> coin_4). Entity fields that "
         "name "
         "an entity of the copied set name its new copy; a field that names an entity outside the set keeps it when "
         "this scene has an entity with that id and is cleared when it has not (listed in `cleared`). The pasted roots "
         "go under `parent` (null or \"\" = top level), or with keepParents under the parent each had when copied "
         "(top level when that parent is gone); without either, at the top level. Returns {ids, count, cleared, "
         "primary?, messages?}: `ids` are the new roots in the order of the text; `primary` is the pasted root that is "
         "or "
         "holds the copy of the entity scene.copy_entities got as `primary`. Nothing is created when anything is "
         "wrong. "
         "Example: scene.paste_entities {\"text\":\"<what scene.copy_entities "
         "returned>\",\"parent\":\"level\"}" FA_COMMAND_DETAILS
         "`nameSuffix` is appended to the name of every pasted root (an unnamed one becomes \"Entity\" + suffix): "
         "nameSuffix \" copy\" with keepParents is a duplicate. `parent` and keepParents together are refused. A text "
         "that is not an entity clipboard (not JSON, another `format`, another version) is an error that names the "
         "JSON pointer of the problem; a text with a \"prefab\" key, a `$prefab` path outside the project or more than "
         "64 levels "
         "of children is refused. Only Entity fields are remapped: an id inside a Json field (Script.props, for "
         "example) is "
         "copied as it is. `cleared` entries are {entity, component, field, target}.",
         parse_schema(R"({"type":"object","required":["text"],"properties":{
               "text":{"type":"string","description":"The text scene.copy_entities returned (the system clipboard in the editor)."},
               "parent":{"type":["string","null"],"description":"Id of the entity the pasted roots go under; null or \"\" = top level. Not with keepParents."},
               "keepParents":{"type":"boolean","default":false,"description":"Put each pasted root under the parent it had when copied, when that entity exists here. Not with parent."},
               "nameSuffix":{"type":"string","description":"Appended to the name of every pasted root, e.g. \" copy\"."}}})"),
         false, "scene"},
        [&I](const Json& a) { return paste_entities(I, a); });

    declare_command_capabilities(I.commands, {
                                                 {"scene.copy_entities", capability_sets::reads()},
                                                 {"scene.paste_entities", capability_sets::changes_state()},
                                             });
}

}  // namespace fa
