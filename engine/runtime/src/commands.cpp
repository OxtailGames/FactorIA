// Built-in commands: the AI/tool surface of a running game.
#include <algorithm>
#include <cmath>
#include <filesystem>

#include "engine_impl.h"
#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/runtime/project.h"
#include "fa/runtime/test_files.h"
#include "fa/scene/serialize.h"
#include "fa/services/platform_commands.h"

namespace fa {

namespace {

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

}  // namespace

static std::vector<std::string> all_entity_names(World& w) {
    std::vector<std::string> out;
    for (Entity e : w.entities()) {
        out.push_back(w.id_of(e));
        if (!w.info(e).name.empty()) out.push_back(w.info(e).name);
    }
    return out;
}

Entity need_entity(World& w, const Json& args, const char* key) {
    if (!args.contains(key) || !args[key].is_string())
        throw CommandError("invalid_argument", std::string("Missing string argument '") + key + "'.",
                           "Use scene.list_entities to find entity ids.");
    std::string id = args[key].get<std::string>();
    Entity e = w.find(id);
    if (!e) {
        auto names = all_entity_names(w);
        throw CommandError("not_found", "No entity with id or name '" + id + "'. " + did_you_mean(id, names),
                           "Use scene.list_entities to see the valid ids.");
    }
    return e;
}

namespace {

const TypeInfo& need_component_type(const std::string& name) {
    const TypeInfo* t = TypeRegistry::global().find_ci(name);
    if (!t) {
        std::string s = TypeRegistry::global().suggest(name);
        throw CommandError("not_found",
                           "Unknown component '" + name + "'." + (s.empty() ? "" : " Did you mean '" + s + "'?"),
                           "Use api.components to list every component with its fields.");
    }
    return *t;
}

// `merge: true` of scene.set_component: `patch` read as an RFC 7386 JSON merge-patch against the component's current
// values, field by field. A null removes the field's value, i.e. resets it to its default (a key that was never set); an
// object for a Json-valued field (Script.props) is merged into the current object, recursively, null deleting a key;
// every other value replaces the field, as without merge. Returns the plain `fields` patch_component applies.
Json merge_fields(const World& world, Entity e, const TypeInfo& type, const Json& patch) {
    if (!patch.is_object()) return patch;  // patch_component explains what is wrong
    DefaultObject defaults(type);
    const void* current = world.get(e, type);
    Json out = Json::object();
    for (auto it = patch.begin(); it != patch.end(); ++it) {
        const FieldInfo* f = type.field(it.key());
        const bool plain = f && !f->readOnly && f->kind != FieldKind::Entity;  // the rest is patch_component's to report
        if (plain && it->is_null()) {
            out[it.key()] = field_to_json(*f, defaults.get());
        } else if (plain && f->kind == FieldKind::Json && it->is_object()) {
            Json merged = field_to_json(*f, current ? current : defaults.get());
            merged.merge_patch(*it);
            out[it.key()] = std::move(merged);
        } else {
            out[it.key()] = *it;
        }
    }
    return out;
}

}  // namespace

// scene.set_component on `world`: `a` is {id, component, fields?, merge?}.
Json set_component(World& world, const Json& a) {
    Entity e = need_entity(world, a);
    const std::string cname = a["component"].get<std::string>();
    const TypeInfo& t = need_component_type(cname);
    Json fields = a.contains("fields") ? a["fields"] : Json::object();
    if (a.value("merge", false)) fields = merge_fields(world, e, t, fields);
    auto r = patch_component(world, e, t, fields);
    if (!r.ok())
        throw CommandError("invalid_argument", r.error().message,
                           r.error().hint.empty() ? "Use api.components to see the fields of " + t.name + "." : r.error().hint);
    return Json::object({{"id", world.id_of(e)}, {"component", t.name}, {"value", component_to_json(world, e, t, true, true)}});
}

namespace {

Json vec_json(Vec3 v) { return Json::array({to_json(v.x), to_json(v.y), to_json(v.z)}); }

// The options physics.raycast and physics.shape_cast share: mask, ignore (an entity; its children are skipped too) and
// ignoreTriggers. ONE parser and ONE schema fragment, so the two commands (and the script API they mirror) cannot drift.
RaycastOptions cast_options(World& world, const Json& a) {
    RaycastOptions opt;
    opt.mask = a.value("mask", -1);
    opt.ignoreTriggers = a.value("ignoreTriggers", true);
    if (a.contains("ignore") && !a["ignore"].is_null()) opt.ignore = need_entity(world, a, "ignore");
    return opt;
}

// `schema` (an object schema with "properties") plus the schema of cast_options().
Json with_cast_options(Json schema) {
    Json& props = schema["properties"];
    props["mask"] = parse_schema(R"({"type":"integer","default":-1,"description":"Collision layer mask: bit i = layer i; -1 hits every layer."})");
    props["ignore"] = parse_schema(R"({"type":"string","description":"Entity id or name whose colliders (and its children's) are skipped, usually the caster."})");
    props["ignoreTriggers"] = parse_schema(R"({"type":"boolean","default":true,"description":"Skip trigger colliders; false hits them too."})");
    return schema;
}

Json hit_json(const World& world, const std::optional<RaycastHit>& hit) {
    Json j = Json::object({{"hit", hit.has_value()}});
    if (hit) {
        j["entity"] = hit->entity ? Json(world.id_of(hit->entity)) : Json(nullptr);
        j["point"] = vec_json(hit->point);
        j["normal"] = vec_json(hit->normal);
        j["distance"] = hit->distance;
    }
    return j;
}

Json load_messages_json(const LoadReport& r) {
    Json a = Json::array();
    for (const LoadMessage& m : r.messages) a.push_back(m.to_string());
    return a;
}

std::string abs_path(const std::string& p) {
    if (fs::is_absolute(p)) return p;
    return fs::resolve(p).generic_string();
}

Json brief_state(Engine::Impl& I, std::uint64_t errorsBefore, std::uint64_t lastSeq) {
    Json j = Json::object();
    j["frame"] = I.frame;
    j["time"] = I.world.time();
    j["scene"] = I.currentScene;
    j["paused"] = I.paused;
    j["entityCount"] = I.world.entity_count();
    j["scriptErrors"] = I.scripts.errors().size();
    j["newLogErrors"] = error_count() - errorsBefore;
    Json logs = Json::array();
    for (const LogEntry& l : recent_logs(10, LogLevel::Warn, lastSeq))
        logs.push_back(Json::object({{"level", log_level_name(l.level)}, {"category", l.category}, {"message", l.message}}));
    if (!logs.empty()) j["newWarnings"] = logs;
    if (I.quit) j["quitRequested"] = true;
    return j;
}

std::uint64_t last_log_seq() {
    auto l = recent_logs(1);
    return l.empty() ? 0 : l.back().seq;
}

void apply_input_lists(Engine::Impl& I, const Json& args) {
    std::string err;
    for (const char* key : {"press", "release"}) {
        if (!args.contains(key)) continue;
        if (!args[key].is_array())
            throw CommandError("invalid_argument", std::string("'") + key + "' must be an array of action/key names.",
                               std::string("Example: {\"") + key + "\": [\"jump\"]}");
        for (const Json& n : args[key]) {
            if (!n.is_string()) throw CommandError("invalid_argument", "Input names must be strings.");
            if (!I.inject_named(n.get<std::string>(), std::string(key) == "press", &err))
                throw CommandError("invalid_argument", err, "Use project.info to see the input actions of this game.");
        }
    }
}

}  // namespace

void register_builtin_commands(Engine& engine, Engine::Impl& I) {

    // ------------------------------------------------------------ engine/project
    I.commands.add({"engine.info", "Show engine version, platform, graphics backend and loop state.",
           "Returns {engineVersion, platform, graphics, headless, frame, paused, fixedHz, components, commands}. "
           "Example: engine.info {}",
           parse_schema(R"({"type":"object","properties":{}})"), true, "engine"},
          [&engine, &I](const Json&) {
              Json j = Json::object();
              j["engineVersion"] = FA_ENGINE_VERSION;
              j["platform"] = FA_PLATFORM_NAME;
              j["graphics"] = I.renderer ? Json(I.gpu ? I.gpu->description() : "window") : Json("none");
              j["headless"] = I.cfg.headless;
              j["editorMode"] = I.cfg.editorMode;
              j["frame"] = I.frame;
              j["paused"] = I.paused;
              j["fixedHz"] = I.project.fixedHz;
              j["components"] = TypeRegistry::global().all().size();
              j["commands"] = I.commands.list().size();
              if (!I.startupProblems.empty()) j["startupProblems"] = I.startupProblems;
              return j;
          });

    I.commands.add({"project.info", "Show the project settings, input actions, current scene, scenes and scripts.",
           "Returns the parsed factoria.json plus {currentScene, scenes[], scripts[], prefabs[], sceneErrors}. "
           "Example: project.info {}",
           parse_schema(R"({"type":"object","properties":{}})"), true, "project"},
          [&engine, &I](const Json&) {
              Json j = Json::object();
              j["project"] = I.project.to_json();
              j["currentScene"] = I.currentScene;
              Json scenes = Json::array(), scripts = Json::array(), prefabs = Json::array();
              for (const auto& f : fs::list("scenes", true, ".json")) scenes.push_back(f);
              for (const auto& f : fs::list("scripts", true, ".js")) scripts.push_back(f);
              for (const auto& f : fs::list("prefabs", true, ".json")) prefabs.push_back(f);
              j["scenes"] = scenes;
              j["scripts"] = scripts;
              j["prefabs"] = prefabs;
              Json acts = Json::array();
              for (const auto& a : I.input.action_names()) acts.push_back(a);
              j["inputActions"] = acts;
              j["sceneErrors"] = I.sceneIssues;
              return j;
          });

    // -------------------------------------------------------------------- scene
    I.commands.add({"scene.list_entities", "List entities (id, name, tags, components) with optional filters.",
           "Filters: name (substring, case-insensitive), tag (exact), component (name). limit defaults to 100. "
           "Use scene.get_entity for full data. Example: scene.list_entities {\"tag\":\"enemy\",\"limit\":20}",
           parse_schema(R"({"type":"object","properties":{
               "name":{"type":"string","description":"Substring of the entity name or id."},
               "tag":{"type":"string","description":"Only entities having this tag."},
               "component":{"type":"string","description":"Only entities having this component, e.g. RigidBody2D."},
               "limit":{"type":"integer","default":100,"minimum":1,"description":"Maximum entities returned."}}})"),
           true, "scene"},
          [&engine, &I](const Json& a) {
              std::string nameF = to_lower(a.value("name", std::string()));
              std::string tagF = a.value("tag", std::string());
              const TypeInfo* compT = nullptr;
              if (a.contains("component") && a["component"].is_string()) {
                  const std::string cname = a["component"].get<std::string>();
                  compT = &need_component_type(cname);
              }
              std::size_t limit = std::size_t(a.value("limit", 100));
              Json list = Json::array();
              std::size_t total = 0;
              for (Entity e : I.world.entities()) {
                  const EntityInfo& inf = I.world.info(e);
                  if (!nameF.empty() && to_lower(inf.name).find(nameF) == std::string::npos &&
                      to_lower(inf.id).find(nameF) == std::string::npos) continue;
                  if (!tagF.empty() && !I.world.has_tag(e, tagF)) continue;
                  if (compT && !I.world.get(e, *compT)) continue;
                  ++total;
                  if (list.size() >= limit) continue;
                  Json j = Json::object();
                  j["id"] = inf.id;
                  j["name"] = inf.name;
                  j["tags"] = inf.tags;
                  j["active"] = inf.active;
                  Json cs = Json::array();
                  for (const TypeInfo* t : I.world.components_of(e))
                      if (t->name != "EntityInfo" && t->name != "Transform") cs.push_back(t->name);
                  j["components"] = cs;
                  j["position"] = vec_json(I.world.world_position(e));
                  if (Entity p = I.world.parent(e)) j["parent"] = I.world.id_of(p);
                  list.push_back(std::move(j));
              }
              return Json::object({{"total", total}, {"count", list.size()}, {"entities", list}});
          });

    I.commands.add({"scene.get_entity", "Get one entity with every component field (including defaults and runtime values).",
           "Accepts the entity id or its name. Example: scene.get_entity {\"id\":\"player\"}",
           parse_schema(R"({"type":"object","required":["id"],"properties":{
               "id":{"type":"string","description":"Entity id (or name)."}}})"),
           true, "scene"},
          [&engine, &I](const Json& a) {
              Entity e = need_entity(I.world, a);
              EntityJsonOptions o;
              o.includeDefaults = true;
              o.includeRuntime = true;
              Json j = entity_to_json(I.world, e, o);
              if (Entity p = I.world.parent(e)) j["parent"] = I.world.id_of(p);
              return j;
          });

    I.commands.add({"scene.spawn", "Create an entity from entity JSON, or instantiate a prefab at a position.",
           "Either pass entity JSON ({name, id?, tags?, components:{...}}) or {prefab, position?}. Optional parent id. "
           "Returns the created entity (with defaults) plus load messages. Example: "
           "scene.spawn {\"name\":\"Coin\",\"components\":{\"Transform\":{\"position\":[100,50,0]},"
           "\"Shape2D\":{\"shape\":\"circle\",\"size\":[20,20],\"color\":\"gold\"}}}  or  "
           "scene.spawn {\"prefab\":\"prefabs/enemy.prefab.json\",\"position\":[300,0]}",
           parse_schema(R"({"type":"object","properties":{
               "prefab":{"type":"string","description":"Project-relative prefab path to instantiate."},
               "position":{"type":"array","description":"[x, y] or [x, y, z] world position (Transform.position)."},
               "entity":{"type":"object","description":"Entity JSON; alternatively put its fields (name, components...) at top level."},
               "parent":{"type":"string","description":"Parent entity id."},
               "index":{"type":"integer","minimum":0,"description":"Place among the parent's children (0 = first, up to their count). Omitted = last. Needs parent."},
               "overrides":{"type":"object","description":"With prefab: patches for the prefab's children, keyed by child id, name or path (see docs/MENUS.md)."},
               "name":{"type":"string"},"id":{"type":"string"},
               "tags":{"type":"array","items":{"type":"string"}},
               "components":{"type":"object","description":"Component name -> field object."}}})"),
           false, "scene"},
          [&engine, &I](const Json& a) {
              Entity parent = kNullEntity;
              if (a.contains("parent")) parent = need_entity(I.world, a, "parent");
              int index = -1;
              if (a.contains("index") && !a["index"].is_null()) {
                  if (!a["index"].is_number()) throw CommandError("invalid_argument", "'index' must be a whole number.", "Example: \"index\": 0 puts the entity first.");
                  std::string bad = I.world.check_child_index(parent, kNullEntity, a["index"].get<double>());
                  if (!bad.empty()) throw CommandError("invalid_argument", bad, "scene.get_entity on the parent lists its children in order.");
                  index = a["index"].get<int>();
              }
              Json spec = a.contains("entity") && a["entity"].is_object() ? a["entity"] : Json::object();
              if (!a.contains("entity"))
                  for (const char* k : {"name", "id", "tags", "components", "active", "children", "overrides"})
                      if (a.contains(k)) spec[k] = a[k];
              if (a.contains("position")) {
                  Json pos = a["position"];
                  if (pos.is_array() && pos.size() == 2) pos.push_back(0);
                  spec["components"]["Transform"]["position"] = pos;
              }
              LoadReport report;
              Entity e;
              if (a.contains("prefab") && a["prefab"].is_string()) {
                  e = instantiate_prefab(I.world, a["prefab"].get<std::string>(), parent, report, spec, index);
              } else {
                  if (!spec.contains("components") && !spec.contains("name") && !spec.contains("prefab") && !spec.contains("id"))
                      throw CommandError("invalid_argument", "Nothing to spawn: pass 'prefab' or entity JSON.",
                                         "Example: {\"name\":\"Box\",\"components\":{\"Shape2D\":{\"size\":[50,50]}}}");
                  e = entity_from_json(I.world, spec, parent, report, "scene.spawn", "", index);
              }
              if (!e || !I.world.alive(e))
                  throw CommandError("invalid_argument", "Spawn failed:\n" + report.summary(),
                                     "Use api.components for valid component names and fields; prefabs live in prefabs/.");
              if (report.error_count() > 0) {
                  // Unknown component/field names etc.: no half-built entity is left behind, the caller gets the fix.
                  for (Entity c : report.created)
                      if (I.world.alive(c)) I.world.destroy(c);
                  I.world.flush();
                  throw CommandError("invalid_argument", "Spawn failed, nothing was created:\n" + report.summary(),
                                     "Fix the names above (the hints list valid ones); api.components describes every component.");
              }
              EntityJsonOptions o;
              o.includeDefaults = true;
              Json out = Json::object();
              out["id"] = I.world.id_of(e);
              out["entity"] = entity_to_json(I.world, e, o);
              out["created"] = report.created.size();
              if (!report.messages.empty()) out["messages"] = load_messages_json(report);
              return out;
          });

    I.commands.add({"scene.destroy", "Destroy an entity and its children.",
           "Destruction is applied immediately when called outside a frame. Example: scene.destroy {\"id\":\"coin_3\"}",
           parse_schema(R"({"type":"object","required":["id"],"properties":{"id":{"type":"string","description":"Entity id (or name)."}}})"),
           false, "scene"},
          [&engine, &I](const Json& a) {
              Entity e = need_entity(I.world, a);
              std::string id = I.world.id_of(e);
              I.world.destroy(e);
              if (!I.inFrame) I.world.flush();
              return Json::object({{"destroyed", id}});
          });

    I.commands.add({"scene.set_parent", "Move an entity under another entity, or to the top level of the scene.",
           "`parent` null or \"\" makes it a root. By default (`keepWorldTransform` true) the entity stays where it is on "
           "screen: its local Transform is recomputed for the new parent; with false the local Transform is kept, so the "
           "entity moves with the new parent. The entity becomes the LAST child of its new parent unless `index` says "
           "where: 0 = first; it counts the new parent's other children, so moving within the same parent works (index 0 on the "
           "last child makes it first); an index below 0 or above the number of other children is refused, and `index` needs a "
           "parent (top-level order is creation order). Scene files keep the order. A parent that is the "
           "entity itself or one of its children is refused (a cycle). Example: scene.set_parent {\"id\":\"coin_3\",\"parent\":\"chest\"}",
           parse_schema(R"({"type":"object","required":["id"],"properties":{
               "id":{"type":"string","description":"Entity id (or name) to move."},
               "parent":{"type":["string","null"],"description":"New parent's id (or name); null or empty = top level."},
               "keepWorldTransform":{"type":"boolean","default":true,"description":"true = keep the world position, rotation and scale (the local Transform changes); false = keep the local Transform."},
               "index":{"type":"integer","minimum":0,"description":"Place among the new parent's other children (0 = first). Omitted = last. Needs a parent."}}})"),
           false, "scene"},
          [&I](const Json& a) {
              Entity e = need_entity(I.world, a);
              Entity parent = kNullEntity;
              if (a.contains("parent") && !a["parent"].is_null()) {
                  if (!a["parent"].is_string())
                      throw CommandError("invalid_argument", "'parent' must be an entity id string, null or \"\".",
                                         "Use scene.list_entities to find entity ids.");
                  if (!a["parent"].get<std::string>().empty()) parent = need_entity(I.world, a, "parent");
              }
              for (Entity p = parent; p; p = I.world.parent(p))
                  if (p == e)
                      throw CommandError("invalid_argument",
                                         "Cannot make '" + I.world.id_of(e) + "' a child of '" + I.world.id_of(parent) +
                                             "': that would put an entity inside itself (a cycle).",
                                         "Pick a parent that is not the entity or one of its children, or move the other entity first.");
              int index = -1;
              if (a.contains("index") && !a["index"].is_null()) {
                  if (!a["index"].is_number()) throw CommandError("invalid_argument", "'index' must be a whole number.", "Example: \"index\": 0 puts the entity first.");
                  std::string bad = I.world.check_child_index(parent, e, a["index"].get<double>());
                  if (!bad.empty()) throw CommandError("invalid_argument", bad, "scene.get_entity on the parent lists its children in order.");
                  index = a["index"].get<int>();
              }
              I.world.set_parent(e, parent, a.value("keepWorldTransform", true), index);
              Entity now = I.world.parent(e);
              Json out = Json::object({{"id", I.world.id_of(e)}, {"parent", now ? Json(I.world.id_of(now)) : Json(nullptr)}});
              if (now) {
                  const auto& sib = I.world.children(now);
                  out["index"] = std::find(sib.begin(), sib.end(), e) - sib.begin();
              }
              return out;
          });

    I.commands.add({"scene.set_component", "Add a component to an entity (if missing) and set the given fields.",
           "`fields` is a partial object; unspecified fields keep their value. A value outside a field's range (see "
           "api.components) is refused, and a bad field changes nothing: errors name the field, the allowed values and "
           "the range. A field with free-form JSON content (Script.props) is REPLACED as a whole by default; with "
           "`merge` true `fields` is an RFC 7386 JSON merge-patch instead: an object for such a field is merged into "
           "the current one recursively (keys you do not mention stay, a null value deletes the key), and a null for any "
           "other field resets it to its default. Example: scene.set_component "
           "{\"id\":\"player\",\"component\":\"Sprite\",\"fields\":{\"color\":\"red\"}}; change one prop and keep the rest: "
           "scene.set_component {\"id\":\"level\",\"component\":\"Script\",\"fields\":{\"props\":{\"levelIndex\":3,\"oldProp\":null}},\"merge\":true}",
           parse_schema(R"({"type":"object","required":["id","component"],"properties":{
               "id":{"type":"string","description":"Entity id (or name)."},
               "component":{"type":"string","description":"Component name, e.g. Transform, Sprite, RigidBody2D."},
               "fields":{"type":"object","description":"Field name -> value."},
               "merge":{"type":"boolean","default":false,"description":"true = read `fields` as an RFC 7386 JSON merge-patch: objects (Script.props) merge into the current value recursively, null deletes a key (or resets a plain field to its default). false = every given field is replaced as a whole."}}})"),
           false, "scene"},
          [&I](const Json& a) { return set_component(I.world, a); });

    I.commands.add({"scene.remove_component", "Remove a component from an entity.",
           "Transform and EntityInfo cannot be removed. Example: scene.remove_component {\"id\":\"player\",\"component\":\"Script\"}",
           parse_schema(R"({"type":"object","required":["id","component"],"properties":{
               "id":{"type":"string"},"component":{"type":"string"}}})"),
           false, "scene"},
          [&engine, &I](const Json& a) {
              Entity e = need_entity(I.world, a);
              const std::string cname = a["component"].get<std::string>();
              const TypeInfo& t = need_component_type(cname);
              if (t.name == "Transform" || t.name == "EntityInfo")
                  throw CommandError("invalid_argument", t.name + " cannot be removed.", "Destroy the entity instead (scene.destroy).");
              bool had = I.world.get(e, t) != nullptr;
              I.world.remove(e, t);
              return Json::object({{"id", I.world.id_of(e)}, {"component", t.name}, {"removed", had}});
          });

    I.commands.add({"scene.load", "Replace the running scene with a scene file.",
           "Loads immediately (outside a frame) or at the end of the current frame. Like scene.reload it first re-reads script modules "
           "and factoria.json input actions that changed on disk and clears script errors. Load problems are returned in "
           "`messages`. `props` (a JSON object) is handed to the new scene's scripts: game.sceneProps() returns it from their first "
           "start(). A reload (scene.reload, hot reload) keeps the props; a scene.load without props gives the scene none. "
           "Example: scene.load {\"path\":\"scenes/level2.scene.json\",\"props\":{\"difficulty\":\"hard\"}}",
           parse_schema(R"({"type":"object","required":["path"],"properties":{
               "path":{"type":"string","description":"Project-relative scene path."},
               "props":{"type":"object","description":"Plain JSON the new scene's scripts read with game.sceneProps() (default: none, {})."}}})"),
           false, "scene"},
          [&engine, &I](const Json& a) {
              std::string path = a["path"].get<std::string>();
              if (!fs::exists(path)) {
                  auto scenes = fs::list("scenes", true, ".json");
                  throw CommandError("not_found", "Scene file '" + path + "' not found. " + did_you_mean(path, scenes),
                                     "Use project.info to list scenes.");
              }
              const bool hasProps = a.contains("props") && a["props"].is_object();
              if (I.inFrame) {
                  if (hasProps) engine.request_scene_change_with_props(path, a["props"]);
                  else engine.request_scene_change(path);
                  return Json::object({{"scheduled", true}, {"path", path}});
              }
              if (hasProps) I.nextProps = a["props"];
              std::string err;
              bool ok = I.load_scene_impl(path, &err);
              return Json::object({{"ok", ok}, {"path", path}, {"entityCount", I.world.entity_count()}, {"messages", I.sceneIssues}});
          });

    I.commands.add({"scene.save", "Save the running world to a scene file (current scene path by default).",
           "Writes canonical scene JSON (only non-default fields, except settings.gravity2D and settings.gravity3D, which are "
           "always written so the file shows the gravity the level uses). Files inside .factoria/ belong to the engine and its tools: "
           "only the scratch folder .factoria/tmp/ may be written there (the same rule as fs.write and fs.delete). To change a "
           "scene FILE without touching the running world use scene.import_ascii with `path`. Example: "
           "scene.save {\"path\":\"scenes/snapshot.scene.json\"}",
           parse_schema(R"({"type":"object","properties":{
               "path":{"type":"string","description":"Project-relative output path. Default: the current scene."}}})"),
           false, "scene"},
          [&engine, &I](const Json& a) {
              std::string path = a.value("path", I.currentScene);
              if (path.empty())
                  throw CommandError("invalid_argument", "No current scene path.", "Pass {\"path\":\"scenes/name.scene.json\"}.");
              if (auto w = fs::check_writable(path); !w.ok()) throw CommandError("invalid_argument", w.error().message, w.error().hint);
              auto r = save_scene_file(I.world, path);
              if (!r.ok()) throw CommandError("failed", r.error().message, r.error().hint);
              if (I.watchSeeded) I.watched[path] = fs::modified_time(path);
              if (I.currentScene.empty()) I.currentScene = path;
              return Json::object({{"saved", path}, {"entityCount", I.world.entity_count()}});
          });

    I.commands.add({"scene.reload", "Reload the current scene from disk (discards runtime changes).",
           "Resets the world to the saved scene file. Also re-reads what changed on disk: script modules (and the modules importing "
           "them), factoria.json input actions, fixedHz and deadzone; script errors are cleared. Example: scene.reload {}",
           parse_schema(R"({"type":"object","properties":{}})"), false, "scene"},
          [&engine, &I](const Json&) {
              if (I.currentScene.empty()) throw CommandError("unavailable", "No scene is loaded.", "Use scene.load first.");
              std::string err;
              bool ok = I.load_scene_impl(I.currentScene, &err, true);  // the same scene starts again with its props
              return Json::object({{"ok", ok}, {"scene", I.currentScene}, {"messages", I.sceneIssues}});
          });

    register_level_commands(engine, I);       // scene.import_ascii
    register_scene_file_commands(engine, I);  // prefab.save, scene.format
    register_play_session_commands(engine, I);  // play.sessions, play.report
    register_i18n_commands(engine, I);          // i18n.state, i18n.set_language
    register_ui_check_commands(engine, I);      // ui.check_layout
    register_platform_commands(I.commands, I.platform);  // platform.state, platform.respond, ... (fa/services)

    // --------------------------------------------------------------------- game
    I.commands.add({"game.step", "Advance the simulation by N fixed frames (deterministic) and return a state summary.",
           "Each frame is exactly 1/fixedHz seconds. `press` holds actions/keys down and `release` lets go; they are "
           "applied BEFORE the first frame and stay in effect (a press without release stays held). To tap a button "
           "use game.step {\"frames\":1,\"press\":[\"jump\"]} then game.step {\"frames\":1,\"release\":[\"jump\"]}. "
           "Works while paused. Example: game.step {\"frames\":60,\"press\":[\"move_right\"]}",
           parse_schema(R"({"type":"object","properties":{
               "frames":{"type":"integer","default":1,"minimum":0,"maximum":100000,"description":"Number of frames."},
               "press":{"type":"array","items":{"type":"string"},"description":"Actions/keys to press first."},
               "release":{"type":"array","items":{"type":"string"},"description":"Actions/keys to release first."}}})"),
           false, "game"},
          [&engine, &I](const Json& a) {
              std::uint64_t errs = error_count(), seq = last_log_seq();
              apply_input_lists(I, a);
              engine.step(a.value("frames", 1));
              return brief_state(I, errs, seq);
          });

    I.commands.add({"input.record", "Record the input the game receives as an input replay (start / stop).",
           "`start` begins recording every key, mouse, touch, gamepad and Back event the game receives (from a window, a test, "
           "game.input or a replay), the dt and fixed steps of each frame, the clipboard reads, the answers of http.fetch and the "
           "calendar date; what is held "
           "at that moment (keys, buttons, pads) is part of it. `stop` ends it and returns the replay in `replay`: the JSON that "
           "`factoria run --headless --input <file>` plays (frame numbers count from the start; typed text, the mouse wheel and "
           "locked-mouse movement have no field in the format and are not recorded). `path` (with stop) also writes the replay to "
           "that project-relative file. A replay run from the same scene, seed and props reaches the same state. Start and stop "
           "between frames. Starting while recording begins again. Example: input.record {\"action\":\"start\"} ... "
           "input.record {\"action\":\"stop\",\"path\":\"replays/run1.json\"}",
           parse_schema(R"({"type":"object","required":["action"],"properties":{
               "action":{"type":"string","enum":["start","stop"],"description":"start: begin recording now. stop: end it and return the replay."},
               "path":{"type":"string","description":"stop only: also write the replay to this project-relative file (e.g. replays/run1.json)."}}})"),
           false, "game"},
          [&engine, &I](const Json& a) {
              const std::string action = a["action"].get<std::string>();
              if (action == "start") {
                  const bool restarted = engine.input_recording();
                  engine.start_input_recording();
                  return Json::object({{"recording", true}, {"startFrame", I.frame}, {"restarted", restarted}});
              }
              if (!engine.input_recording())
                  throw CommandError("unavailable", "Nothing is being recorded.", "Start with input.record {\"action\":\"start\"}.");
              const std::size_t frames = engine.input_recording_frames();
              Json replay = engine.stop_input_recording();
              Json out = Json::object({{"recording", false}, {"frames", frames}, {"replay", replay}});
              if (a.contains("path") && a["path"].is_string()) {
                  const std::string path = a["path"].get<std::string>();
                  if (auto w = fs::check_writable(path); !w.ok()) throw CommandError("invalid_argument", w.error().message, w.error().hint);
                  if (auto r = fs::write_text(path, replay.dump(1)); !r.ok()) throw CommandError("failed", r.error().message, r.error().hint);
                  out["path"] = path;
              }
              return out;
          });

    I.commands.add({"game.input", "Inject input: press/release actions or keys, or set an action state, mouse position/buttons, "
           "gamepad buttons/sticks, touches.",
           "Names may be input actions from factoria.json, key names (Space, A, Left...) or MouseLeft/MouseRight/MouseMiddle. "
           "Forms: {\"action\":\"jump\",\"down\":true}, {\"key\":\"Space\",\"down\":false}, "
           "{\"press\":[\"jump\"],\"release\":[\"fire\"]}, {\"mouse\":{\"position\":[640,360]}}, "
           "{\"gamepad\":{\"index\":0,\"buttons\":{\"A\":true},\"axes\":{\"LeftX\":-1}}}, "
           "{\"touch\":{\"id\":1,\"position\":[200,300],\"down\":true}}. "
           "gamepad: index 0..3 (default 0), connected (bool), buttons {A, B, X, Y, Start, Back, Guide, DpadLeft/Right/Up/Down, "
           "LeftShoulder, RightShoulder, LeftThumb, RightThumb: bool}, axes {LeftX, LeftY, RightX, RightY: -1..1 with +Y up; "
           "LeftTrigger, RightTrigger: 0..1}; the state stays until set again (axes back to 0 to release the stick). "
           "touch: id (default 1), position in design pixels, down (default true: a new id begins, a known id moves; false lifts); "
           "the first finger also drives the mouse like a device. gamepad and touch also take an array for several pads/fingers. "
           "{\"back\":true} presses the system Back button of Android: the input.onBack handlers of the game run at the next "
           "frame, and when none consumes it the game asks to quit (game.state shows quitRequested). "
           "The input is applied now and seen by the next frame (game.step). Example: game.input {\"press\":[\"jump\"]}",
           parse_schema(R"({"type":"object","properties":{
               "action":{"type":"string","description":"Action name (with `down`)."},
               "key":{"type":"string","description":"Key or mouse button name (with `down`)."},
               "down":{"type":"boolean","default":true,"description":"New state for action/key."},
               "press":{"type":"array","items":{"type":"string"}},
               "release":{"type":"array","items":{"type":"string"}},
               "mouse":{"type":"object","description":"{position:[x,y] in design pixels, left/right/middle: bool}."},
               "gamepad":{"type":["object","array"],"description":"{index?: 0..3, connected?: bool, buttons?: {A: true, DpadLeft: false...}, axes?: {LeftX: -1, RightTrigger: 0.5...}}, or an array of those for several pads."},
               "touch":{"type":["object","array"],"description":"{id?: number (default 1), position?: [x,y] design pixels, down?: bool (default true)}, or an array of those for several fingers."},
               "back":{"type":"boolean","description":"true: press the system Back button (Android)."}}})"),
           false, "game"},
          [&engine, &I](const Json& a) {
              std::string err;
              bool down = a.value("down", true);
              for (const char* k : {"action", "key"})
                  if (a.contains(k) && a[k].is_string() && !I.inject_named(a[k].get<std::string>(), down, &err))
                      throw CommandError("invalid_argument", err, "Use project.info to see the input actions.");
              apply_input_lists(I, a);
              if (a.contains("mouse") && a["mouse"].is_object()) {
                  const Json& m = a["mouse"];
                  if (m.contains("position")) {
                      Vec2 p;
                      std::string perr;
                      if (!json_to(m["position"], p, &perr)) throw CommandError("invalid_argument", "mouse.position: " + perr);
                      I.input.on_mouse_move(p);
                  }
                  if (m.contains("left")) I.input.on_mouse_button(MouseButton::Left, m["left"].get<bool>());
                  if (m.contains("right")) I.input.on_mouse_button(MouseButton::Right, m["right"].get<bool>());
                  if (m.contains("middle")) I.input.on_mouse_button(MouseButton::Middle, m["middle"].get<bool>());
              }
              std::vector<std::string> problems;  // the valid parts are applied; the rest is reported with a hint
              if (a.contains("gamepad")) apply_gamepad_json(I.input, a["gamepad"], problems);
              if (a.contains("touch")) apply_touch_json(I.input, a["touch"], problems);
              if (a.value("back", false)) I.input.on_back();
              if (!problems.empty())
                  throw CommandError("invalid_argument", join(problems, "\n"),
                                     "gamepad: {\"index\":0,\"buttons\":{\"A\":true},\"axes\":{\"LeftX\":-1}}; "
                                     "touch: {\"id\":1,\"position\":[x,y],\"down\":true}.");
              return I.input.snapshot();
          });

    I.commands.add({"game.screenshot", "Capture the game view as a PNG and show it.",
           "Draws the game view as it is now (design resolution), saves it and returns the path; clients display the "
           "image. Scripts only run when frames are stepped: step the game first so the picture shows what you expect. "
           "Default path .factoria/screenshots/frame_<n>.png. `scale` (0.25 to 4, default 1) draws the same frame into an image "
           "scale times larger, sharp and not upscaled, for store screenshots: HUD, camera and visible area stay the same, "
           "so a 1280x720 game at scale 1.5 gives a 1920x1080 PNG. `simulate` (greyscale, protanopia, deuteranopia, tritanopia) converts the saved "
           "PNG to what a colour-blind viewer sees (Machado 2009 matrices, severity 1.0, applied to the sRGB pixels in linear light; "
           "greyscale = Rec. 709 luminance) without changing what the player sees: use it to check that hazards, pickups and buttons "
           "read without their colour. Example: game.screenshot {\"path\":\"shots/start.png\",\"scale\":1.5} or "
           "game.screenshot {\"path\":\"shots/deut.png\",\"simulate\":\"deuteranopia\"}",
           parse_schema(R"({"type":"object","properties":{
               "path":{"type":"string","description":"Output PNG (project-relative or absolute)."},
               "scale":{"type":"number","default":1,"minimum":0.25,"maximum":4,"description":"Render scale: image size = design size * scale, drawn natively (sharp), same HUD and visible area. 1.5 on 1280x720 = 1920x1080."},
               "simulate":{"type":"string","enum":["none","greyscale","protanopia","deuteranopia","tritanopia"],"default":"none","description":"Convert the saved PNG to what a colour-blind viewer sees (Machado 2009, severity 1.0, linear light) to check that things read without colour. The player's view is unchanged."}}})"),
           true, "game"},
          [&engine, &I](const Json& a) {
              std::string path = a.value("path", ".factoria/screenshots/frame_" + std::to_string(I.frame) + ".png");
              std::string err;
              const double scale = a.value("scale", 1.0);
              if (!(scale >= 0.25 && scale <= 4.0))
                  throw CommandError("invalid_argument", "scale " + std::to_string(scale) + " is out of range.",
                                     "scale must be between 0.25 and 4: the image is design size * scale. Example: 1.5 on a 1280x720 game gives 1920x1080.");
              const std::string simulate = a.value("simulate", std::string("none"));
              if (auto parsed = parse_color_simulation(simulate); !parsed.ok())
                  throw CommandError("invalid_argument", parsed.error().message, parsed.error().hint);
              if (!engine.screenshot_simulated(path, scale, simulate, &err))
                  throw CommandError("unavailable", err, "Screenshots need graphics (headless needs Mesa/EGL).");
              std::string abs = abs_path(path);
              Json j = Json::object();
              j["path"] = abs;
              j["width"] = int(std::lround(I.renderer->target_width() * scale));
              j["height"] = int(std::lround(I.renderer->target_height() * scale));
              j["frame"] = I.frame;
              j["$image"] = Json::object({{"path", abs}, {"mimeType", "image/png"}});
              return j;
          });

    I.commands.add({"game.state", "Dump the game state as JSON: entities, physics, script errors, recent warnings, render stats.",
           "Filters: entities (ids), components (names to include), includeDefaults, maxEntities (default 200). "
           "Example: game.state {\"entities\":[\"player\"],\"components\":[\"Transform\",\"RigidBody2D\"]}",
           parse_schema(R"({"type":"object","properties":{
               "entities":{"type":"array","items":{"type":"string"},"description":"Only these entity ids."},
               "components":{"type":"array","items":{"type":"string"},"description":"Only these components per entity."},
               "includeDefaults":{"type":"boolean","default":false},
               "maxEntities":{"type":"integer","default":200,"minimum":0}}})"),
           true, "game"},
          [&engine, &I](const Json& a) { return engine.state(a); });

    I.commands.add({"game.render_stats", "What the renderer drew in the picture now: draw calls, triangles, lights, shadow casters, texture memory.",
           "Draws a frame first when none was drawn since the last change (a headless run or an on-demand render may not have "
           "drawn one yet), then returns {drawCalls, sprites, shapes, textGlyphs, particles, meshes, meshesCulled, meshBatches, "
           "triangles, shadowCasters, lights, lightsDropped, lights2d, lights2dDropped, lights2dShadowed, materials, materialFallbacks, textureMB, "
           "width, height, renderScale}. lights and lightsDropped count the 3D lights of the main pass (at most 32); lights2d "
           "and lights2dDropped count the Light2D lights (at most 256: the ones that reach the camera view are kept first), lights2dShadowed those with a shadow (castShadows, at most 32). "
           "width and height are the size of the picture in pixels (design size * window.renderScale). Same as game.renderStats() "
           "in tests. Needs graphics. Example: game.render_stats {}",
           parse_schema(R"({"type":"object","properties":{}})"),
           true, "game"},
          [&engine](const Json&) {
              Json j = engine.render_stats_now();
              if (j.is_null())
                  throw CommandError("unavailable", "This run has no renderer, so nothing is drawn and there are no render stats.",
                                     "Run with graphics (headless needs Mesa/EGL on Linux) and not graphics=false.");
              return j;
          });

    I.commands.add({"game.logs", "Read recent log lines (engine, scripts, assets...).",
           "Use `after` (a seq from a previous call) to fetch only new lines. Example: game.logs {\"minLevel\":\"warn\",\"max\":50}",
           parse_schema(R"({"type":"object","properties":{
               "minLevel":{"type":"string","enum":["trace","debug","info","warn","error"],"default":"info"},
               "after":{"type":"integer","default":0,"description":"Only entries with seq greater than this."},
               "max":{"type":"integer","default":100,"minimum":1}}})"),
           true, "game"},
          [&engine, &I](const Json& a) {
              LogLevel lv = LogLevel::Info;
              if (!parse_log_level(a.value("minLevel", std::string("info")), lv))
                  throw CommandError("invalid_argument", "Unknown log level.", "Use trace, debug, info, warn or error.");
              auto entries = recent_logs(std::size_t(a.value("max", 100)), lv, a.value("after", std::uint64_t(0)));
              Json list = Json::array();
              for (const LogEntry& l : entries)
                  list.push_back(Json::object({{"seq", l.seq}, {"frame", l.frame}, {"level", log_level_name(l.level)},
                                               {"category", l.category}, {"message", l.message}}));
              return Json::object({{"count", list.size()}, {"lastSeq", entries.empty() ? a.value("after", std::uint64_t(0)) : entries.back().seq},
                                   {"logs", list}});
          });

    I.commands.add({"ui.state", "List the UI widgets on screen (Panel, Button, Toggle, Slider, TextField, ScrollList, TouchStick, TouchButton, and screen-space Text) and which has focus.",
           "Returns {focused, hovered, widgets: [{id, kind, rect: [x, y, w, h], focused, hovered, pressed, interactable, visible, "
           "value?, text?}]} in reading order (top to bottom, then left to right). Only widgets that are active in the hierarchy "
           "are listed. rect is in design pixels, top-left origin, +Y down: click a widget with game.input {\"mouse\": "
           "{\"position\": [x, y], \"left\": true}} or move the focus with the ui_up / ui_down / ui_left / ui_right and "
           "ui_submit actions (game.input {\"press\": [\"ui_down\"]}). `visible` is false when a ScrollList clips the widget away "
           "entirely, and for an on-screen gamepad control that is hidden (touchOnly while the player is not using touch). "
           "`value` is a Toggle's boolean, a Slider's number or a TouchStick's [x, y]; `pressed` of a TouchStick or TouchButton "
           "is a finger holding it (drive one with game.input {\"touch\": ...}); `text` is a Button's or TouchButton's text, a "
           "Toggle's or Slider's label or a TextField's contents. Screen-space Text entities (space \"screen\") follow the widgets as "
           "{id, kind: \"Text\", rect, text} (they are never focused or pressed; use it to check where HUD text is). `textScale` is the text size option (ui.set_text_scale). Example: ui.state {}",
           parse_schema(R"({"type":"object","properties":{}})"), true, "ui"},
          [&engine, &I](const Json&) {
              Json state = I.ui.state(I.world, I.design_size(), I.measure());
              state["textScale"] = engine.text_scale();
              return state;
          });

    I.commands.add({"ui.set_slider", "Set a Slider the way a drag does: clamped, snapped to step, and ui.change is sent.",
           "For tests and tools (game.setSlider(id, value) in a test calls it). The slider takes focus, `value` is clamped to "
           "[min, max] and snapped to `step` exactly as dragging the track does, and the \"ui.change\" event {id, value} is sent "
           "when the number changed (not when it was already there). Writing Slider.value from a script sends no event: that "
           "is the difference. Needs an active, interactable Slider. Returns {id, value, changed}. Example: ui.set_slider "
           "{\"id\":\"music_volume\",\"value\":0.5}",
           parse_schema(R"({"type":"object","required":["id","value"],"properties":{
               "id":{"type":"string","description":"Entity id (or name) of the Slider."},
               "value":{"type":"number","description":"The wanted value; clamped to [min, max] and snapped to step."}}})"),
           false, "ui"},
          [&I](const Json& a) {
              const Entity e = need_entity(I.world, a, "id");
              const std::string id = I.world.id_of(e);
              const Slider* s = I.world.get<Slider>(e);
              if (!s) throw CommandError("invalid_argument", "'" + id + "' has no Slider component.", "Use the id of a Slider (ui.state lists them).");
              if (!I.world.active_in_hierarchy(e) || !s->interactable)
                  throw CommandError("invalid_argument", "Slider '" + id + "' cannot be dragged: it is " + (s->interactable ? "inactive" : "not interactable") + ".",
                                     "A player cannot drag it either; activate it or set interactable true first.");
              const float before = s->value;
              const float now = I.ui.set_slider(I.world, e, a.at("value").get<float>());
              return Json::object({{"id", id}, {"value", now}, {"changed", now != before}});
          });

    I.commands.add({"ui.set_text_scale", "Set the text size option: screen-space Text and the labels of UI widgets get bigger or smaller.",
           "The player's \"text size\" setting (accessibility), the same as `ui.textScale = value` in a script: the font size of "
           "every screen-space Text (space \"screen\") and of the labels of Button, Toggle, Slider and TextField is multiplied by "
           "`scale`, and so is what ui.measureText returns for them (space \"screen\", the default). World-space Text is "
           "part of the world and is not scaled, nor is its entity.bounds(). 1 is normal size; the range is 0.5 to 3. Wrapped text keeps its maxWidth and "
           "grows taller, and widgets keep their rectangles, so lay a menu out with room for the biggest size you offer. The "
           "engine does not save the option: the game stores it (storage) and sets it at start. Look at the result with "
           "game.screenshot. Example: ui.set_text_scale {\"scale\":1.5}",
           parse_schema(R"({"type":"object","required":["scale"],"properties":{
               "scale":{"type":"number","minimum":0.5,"maximum":3,"description":"Text size multiplier: 1 = normal, 1.5 = 50% bigger, 0.5 = half."}}})"),
           false, "ui"},
          [&engine](const Json& a) {  // the schema has already checked the range
              engine.set_text_scale(a.at("scale").get<float>());
              return Json::object({{"textScale", engine.text_scale()}});
          });

    I.commands.add({"ui.speak", "Say a line aloud with the system's text to speech (or record it, headless).",
           "The same as `ui.speak(text, { interrupt })` in a script: the line is said in the game's current language (i18n.language) "
           "with the system voice for it. `interrupt` (default true) stops what is being said first; false queues the line. "
           "Output only: it never changes the simulation. A system without speech (Linux without speech-dispatcher, Android "
           "without a speech engine) says nothing and `spoken` is false. Headless runs, tests and the editor say nothing and "
           "record the line (game.spoken() in tests). Example: ui.speak {\"text\":\"Play\"}",
           parse_schema(R"({"type":"object","required":["text"],"properties":{
               "text":{"type":"string","description":"What to say, already localized."},
               "interrupt":{"type":"boolean","description":"Stop what is being said first (default true); false queues the line."}}})"),
           false, "ui"},
          [&engine](const Json& a) {
              const I18n* L = engine.i18n();
              const std::string language = L && L->enabled() ? L->language() : std::string();
              const bool said = engine.speech().speak(a.at("text").get<std::string>(), language, a.value("interrupt", true));
              return Json::object({{"spoken", said}, {"language", language}});
          });

    I.commands.add({"ui.caption", "Show a subtitle line on the Captions component for a few seconds.",
           "The same as `ui.caption(text, seconds, { key, speaker })` in a script: a line without a sound, drawn by the Captions "
           "component (docs/TEXT.md, \"Captions\") for `seconds` of the game clock; the newest Captions.maxLines lines show. With "
           "`key` (a localization key) the line is the translation and follows a language change. Without a Captions entity the "
           "line is only tracked and the log says so once. Example: ui.caption {\"text\":\"Watch out!\",\"seconds\":2,\"speaker\":\"Mara\"}",
           parse_schema(R"({"type":"object","properties":{
               "text":{"type":"string","description":"The line (the fallback when `key` is set and no string table has it)."},
               "key":{"type":"string","description":"Localization key of the line."},
               "speaker":{"type":"string","description":"Name drawn before the line."},
               "seconds":{"type":"number","exclusiveMinimum":0,"description":"How long it shows, in game-clock seconds (default 3)."}}})"),
           false, "ui"},
          [&engine](const Json& a) {
              CaptionLine line;
              line.key = a.value("key", std::string());
              line.text = a.value("text", std::string());
              if (line.text.empty()) line.text = line.key;
              if (line.text.empty())
                  throw CommandError("invalid_argument", "ui.caption: nothing to show", "pass \"text\" (the line) or \"key\" (a localization key)");
              line.speaker = a.value("speaker", std::string());
              line.source = "ui";
              line.endsAt = engine.world().time() + a.value("seconds", 3.0);
              engine.captions().add(std::move(line), engine.i18n());
              return Json::object({{"captions", engine.captions().size()}});
          });

    I.commands.add({"ui.clear_captions", "Remove every subtitle from the screen now.",
           "The same as `ui.clearCaptions()` in a script. Sounds that have a caption keep playing. Example: ui.clear_captions {}",
           parse_schema(R"({"type":"object","properties":{}})"), false, "ui"},
          [&engine](const Json&) {
              engine.captions().clear();
              return Json::object();
          });

    I.commands.add({"ui.stop_speaking", "Stop what is being said by ui.speak and drop the queued lines.",
           "The same as `ui.stopSpeaking()` in a script. Does nothing when nothing is being said or the system has no speech. "
           "Example: ui.stop_speaking {}",
           parse_schema(R"({"type":"object","properties":{}})"), false, "ui"},
          [&engine](const Json&) {
              engine.speech().stop();
              return Json::object();
          });

    I.commands.add({"screen.set_safe_area", "Pretend the device has a notch, rounded corners or system bars (a notched phone, headless).",
           "The safe area is the part of the screen a notch, rounded corners and the system bars of a phone leave free; items with "
           "`safeArea: true` are anchored to it and screen.safeArea in scripts reports it. A real phone reports it by itself; a "
           "headless run, a test or the editor has none (the whole screen), so this sets one to check a layout: either a "
           "`profile` (\"phone-portrait\": notch at the top and home indicator at the bottom; \"phone-landscape\": notch on a "
           "side; \"none\"), as fractions of the design size, or insets in design pixels from each edge (`left`, `top`, `right`, "
           "`bottom`, default 0). Take a game.step and a game.screenshot to see the result. A windowed run on a phone overwrites it "
           "every frame with the device's real value. Example: screen.set_safe_area {\"profile\":\"phone-portrait\"}",
           parse_schema(R"({"type":"object","properties":{
               "profile":{"type":"string","description":"none, phone-portrait or phone-landscape. Replaces left/top/right/bottom."},
               "left":{"type":"number","minimum":0,"default":0,"description":"Design pixels covered at the left edge."},
               "top":{"type":"number","minimum":0,"default":0,"description":"Design pixels covered at the top edge."},
               "right":{"type":"number","minimum":0,"default":0,"description":"Design pixels covered at the right edge."},
               "bottom":{"type":"number","minimum":0,"default":0,"description":"Design pixels covered at the bottom edge."}}})"),
           false, "screen"},
          [&engine](const Json& a) {
              World& w = engine.world();
              const Vec2 size = engine.renderer() && engine.renderer()->initialized()
                                    ? Vec2{float(engine.renderer()->target_width()), float(engine.renderer()->target_height())}
                                    : Vec2{float(engine.project().width), float(engine.project().height)};
              EdgeInsets e{a.value("left", 0.0f), a.value("top", 0.0f), a.value("right", 0.0f), a.value("bottom", 0.0f)};
              if (a.contains("profile")) {
                  const std::string name = a["profile"].is_string() ? a["profile"].get<std::string>() : std::string();
                  if (!safe_area_profile(name, size, e))
                      throw CommandError("invalid_argument", "Unknown profile " + describe_json_value(a["profile"]) + ". " +
                                                                 did_you_mean(name, safe_area_profile_names()),
                                         "Use one of: " + join(safe_area_profile_names(), ", ") + "; or pass left, top, right, bottom.");
              }
              if (e.left + e.right >= size.x || e.top + e.bottom >= size.y)
                  throw CommandError("invalid_argument", "The insets leave no safe area on a " + std::to_string(int(size.x)) + " x " +
                                                             std::to_string(int(size.y)) + " screen.",
                                     "left + right must be less than the width and top + bottom less than the height.");
              w.set_safe_insets(e);
              return Json::object({{"insets", Json::object({{"left", e.left}, {"top", e.top}, {"right", e.right}, {"bottom", e.bottom}})},
                                   {"safeArea", Json::object({{"x", e.left}, {"y", e.top}, {"w", size.x - e.left - e.right},
                                                              {"h", size.y - e.top - e.bottom}})}});
          });

    I.commands.add({"audio.log", "List the sounds played so far (clip path, frame, volume, bus, source entity), oldest first.",
           "Every play request is logged: audio.play and audio.music from scripts, AudioSource components and scene "
           "music (`music: true`; `layer` names the stem of audio.musicLayers), with `ok: false` when the clip failed to load. `frame`/`time` are the scene clock "
           "(time.frame / time.elapsed in scripts). Use it after game.step to check that a sound fired. `after` (a seq "
           "from a previous call) returns only newer entries; `path` keeps entries whose path equals it or ends with "
           "/<path>. Example: audio.log {\"path\":\"jump.wav\"}",
           parse_schema(R"({"type":"object","properties":{
               "after":{"type":"integer","default":0,"minimum":0,"description":"Only entries with seq greater than this."},
               "path":{"type":"string","description":"Only this clip: a project-relative path or a file name like \"jump.wav\"."},
               "max":{"type":"integer","default":200,"minimum":1,"description":"Return at most this many (the newest)."}}})"),
           true, "audio"},
          [&I](const Json& a) {
              const std::string path = fs::normalize(a.value("path", std::string()));
              const std::size_t max = std::size_t(std::max<std::int64_t>(1, a.value("max", std::int64_t(200))));
              std::vector<AudioEvent> evs = I.audio.play_log(a.value("after", std::uint64_t(0)));
              const std::uint64_t lastSeq = evs.empty() ? a.value("after", std::uint64_t(0)) : evs.back().seq;
              std::vector<const AudioEvent*> keep;
              for (const AudioEvent& ev : evs)
                  if (path.empty() || ev.path == path || ends_with(ev.path, "/" + path)) keep.push_back(&ev);
              Json list = Json::array();
              for (std::size_t i = keep.size() > max ? keep.size() - max : 0; i < keep.size(); ++i) list.push_back(keep[i]->to_json());
              Json out = Json::object({{"count", list.size()}, {"matched", keep.size()}, {"lastSeq", lastSeq},
                                       {"dropped", I.audio.play_log_dropped()}, {"plays", list}});
              if (!path.empty() && keep.empty()) {
                  std::vector<std::string> played;
                  for (const AudioEvent& ev : evs)
                      if (std::find(played.begin(), played.end(), ev.path) == played.end()) played.push_back(ev.path);
                  out["hint"] = played.empty() ? std::string("no sound has been played yet; step the game first (game.step)")
                                               : "'" + path + "' was not played; played clips: " + join(played, ", ") + ". " +
                                                     did_you_mean(path, played);
              }
              return out;
          });

    I.commands.add({"audio.bus", "Set a bus's volume and effects (low-pass, reverb, ducking), or read its state.",
           "Buses are \"sfx\", \"music\", \"ui\" and \"master\" (the master has no ducking). Every voice of a bus is summed into its own buffer; "
           "the effects run on that sum in this order: low-pass, reverb, volume, ducking. `volume` is the player's volume (what "
           "audio.setVolume sets); `lowpass` is a 12 dB per octave cutoff in Hz (0 or null = off); `reverb` is the wet mix 0..1 "
           "(0 = off); `duck` lowers the bus by `amount` (the fraction removed) while the bus `by` is louder than -40 dBFS, with "
           "`attack` and `release` time constants in seconds (63% of the way in that time; null = off). `fade` (seconds) makes volume, lowpass and reverb slide instead of "
           "jumping (a volume change always ramps over about 10 ms so it does not click). Only the keys you pass change; with just "
           "`bus` it returns the state. Returns volume, snapshotVolume, lowpass, reverb and duck. A bus with no effect does no effect "
           "work. Example: audio.bus {\"bus\":\"music\",\"lowpass\":800,\"fade\":0.5}",
           parse_schema(R"({"type":"object","required":["bus"],"properties":{
               "bus":{"enum":["sfx","music","ui","master"],"description":"The bus."},
               "volume":{"type":"number","minimum":0,"maximum":4,"description":"The bus volume, 1 = as recorded."},
               "lowpass":{"type":["number","null"],"minimum":0,"maximum":20000,"description":"Low-pass cutoff in Hz; 0 or null = off."},
               "reverb":{"type":"number","minimum":0,"maximum":1,"description":"Reverb wet mix; 0 = off."},
               "duck":{"type":["object","null"],"description":"Ducking by another bus; null = off.","properties":{
                   "by":{"enum":["sfx","music","ui"],"description":"The bus that triggers it."},
                   "amount":{"type":"number","minimum":0,"maximum":1,"default":0.5,"description":"Fraction of the volume removed while `by` plays."},
                   "attack":{"type":"number","minimum":0,"default":0.05,"description":"Attack time constant in seconds: 63% of the way down in this time, about 95% in three times it."},
                   "release":{"type":"number","minimum":0,"default":0.5,"description":"Release time constant in seconds: 63% of the way back up in this time."}}},
               "fade":{"type":"number","minimum":0,"default":0,"description":"Seconds volume, lowpass and reverb take to move."}}})"),
           false, "audio"},
          [&I](const Json& a) {
              const std::string bus = a.value("bus", std::string());
              const float fade = a.value("fade", 0.0f);
              const auto check = [](const Result<void>& r) {
                  if (!r.ok()) throw CommandError("invalid_argument", r.error().message, r.error().hint);
              };
              if (a.contains("volume")) I.audio.set_bus_volume(bus, a["volume"].get<float>(), fade);
              if (a.contains("lowpass")) check(I.audio.set_bus_lowpass(bus, a["lowpass"].is_null() ? 0.0f : a["lowpass"].get<float>(), fade));
              if (a.contains("reverb")) check(I.audio.set_bus_reverb(bus, a["reverb"].get<float>(), fade));
              if (a.contains("duck")) {
                  DuckSettings d;
                  if (!a["duck"].is_null()) {
                      const Json& dj = a["duck"];
                      if (!dj.contains("by"))
                          throw CommandError("invalid_argument", "audio.bus: duck needs \"by\", the bus that ducks this one",
                                             "Example: \"duck\": {\"by\": \"sfx\", \"amount\": 0.5}; null turns ducking off.");
                      d.by = dj["by"].get<std::string>();
                      d.amount = dj.value("amount", 0.5f);
                      d.attack = dj.value("attack", 0.05f);
                      d.release = dj.value("release", 0.5f);
                  }
                  check(I.audio.set_bus_duck(bus, d));
              }
              Json state = I.audio.bus_state(bus);
              state["bus"] = bus;
              return state;
          });

    I.commands.add({"audio.snapshot", "Apply a named mixer snapshot from factoria.json, or list the snapshots.",
           "A snapshot is a named set of bus settings (volume scale, low-pass, reverb, ducking) from factoria.json "
           "\"audio\".\"snapshots\". Applying one moves every bus to the snapshot's state over `fade` seconds (default: the "
           "snapshot's own \"fade\", 0.5 when it has none): a bus the snapshot does not list goes back to neutral, so a snapshot "
           "is the whole picture and a snapshot with no buses is the way back. The volumes the player set are not touched. "
           "Without `name` it lists the snapshots and the one applied last. An unknown name fails with a \"did you mean\". "
           "Example: audio.snapshot {\"name\":\"underwater\",\"fade\":1}",
           parse_schema(R"({"type":"object","properties":{
               "name":{"type":"string","description":"The snapshot to apply; omit to list them."},
               "fade":{"type":"number","minimum":0,"description":"Seconds the move takes; default the snapshot's own."}}})"),
           false, "audio"},
          [&I](const Json& a) {
              if (!a.contains("name")) {
                  Json names = Json::array();
                  for (const std::string& n : I.audio.snapshot_names()) names.push_back(n);
                  return Json::object({{"snapshots", names}, {"current", I.audio.current_snapshot()}});
              }
              const std::string name = a["name"].get<std::string>();
              auto r = I.audio.apply_snapshot(name, a.contains("fade") ? a["fade"].get<float>() : -1.0f);
              if (!r.ok()) throw CommandError("invalid_argument", r.error().message, r.error().hint);
              return Json::object({{"snapshot", name}, {"current", I.audio.current_snapshot()}});
          });

    I.commands.add({"game.pause", "Pause the simulation (frame() stops simulating; game.step still works).",
           "Example: game.pause {}", parse_schema(R"({"type":"object","properties":{}})"), false, "game"},
          [&engine, &I](const Json&) {
              I.paused = true;
              return Json::object({{"paused", true}});
          });
    I.commands.add({"game.resume", "Resume the simulation after game.pause.", "Example: game.resume {}",
           parse_schema(R"({"type":"object","properties":{}})"), false, "game"},
          [&engine, &I](const Json&) {
              I.paused = false;
              return Json::object({{"paused", false}});
          });

    // ------------------------------------------------------------------- script
    I.commands.add({"script.eval", "Evaluate JavaScript in the running game context (REPL) and return the value.",
           "The last expression is returned as JSON. Example: script.eval {\"code\":\"world.find('player').get('Transform').position\"}",
           parse_schema(R"({"type":"object","required":["code"],"properties":{
               "code":{"type":"string","description":"JavaScript source."}}})"),
           false, "script"},
          [&engine, &I](const Json& a) {
              auto r = I.scripts.eval(a["code"].get<std::string>());
              if (!r.ok()) throw CommandError("script_error", r.error().message, r.error().hint);
              return Json::object({{"value", r.value()}});
          });

    I.commands.add({"script.reload", "Re-import script modules edited on disk and restart the behaviours (the world is kept).",
           "scene.load and scene.reload already re-import every module whose file changed (by modification time) and clear "
           "the script errors; use this to do the same without reloading the scene (entity state is kept, onStart runs "
           "again), or with `force` to re-import every module even if no file changed. Example: script.reload {}",
           parse_schema(R"({"type":"object","properties":{
               "force":{"type":"boolean","default":false,"description":"Re-import all modules, not only the changed ones."}}})"),
           false, "script"},
          [&engine, &I](const Json& a) {
              std::vector<std::string> files = I.scripts.refresh_modules(a.value("force", false));
              I.scripts.on_scene_loaded();
              return Json::object({{"reloaded", files}, {"errors", I.scripts.errors().size()}});
          });

    I.commands.add({"script.errors", "List script errors (load/runtime) and scene load problems.",
           "Cleared by scene.load, scene.reload and script.reload. Example: script.errors {}",
           parse_schema(R"({"type":"object","properties":{}})"), true, "script"},
          [&engine, &I](const Json&) {
              Json errs = Json::array();
              for (const ScriptError& e : I.scripts.errors())
                  errs.push_back(Json::object({{"file", e.file}, {"line", e.line}, {"column", e.column}, {"message", e.message},
                                               {"stack", e.stack}, {"entityId", e.entityId}, {"text", e.to_string()}}));
              return Json::object({{"count", errs.size()}, {"errors", errs}, {"sceneIssues", I.sceneIssues}});
          });

    I.commands.add({"project.test", "Run the project's JavaScript tests (tests/*.test.js) headless and return the report.",
           "Tests run inside this engine instance and change the world; reload the scene afterwards (scene.reload). "
           "`files` runs only those test files: project-relative paths, folders or globs such as tests/ui*.test.js (a path that is not a "
           "*.test.js file is an error that says what to pass). Example: project.test {\"filter\":\"player\",\"files\":[\"tests/saves.test.js\"]}",
           parse_schema(R"({"type":"object","properties":{
               "filter":{"type":"string","description":"Only run test cases whose name contains this."},
               "files":{"type":"array","items":{"type":"string"},"description":"Test files, folders or globs, project-relative (default: every tests/**/*.test.js)."}}})"),
           false, "project"},
          [&engine, &I](const Json& a) {
              I.refresh_from_disk();  // factoria.json input actions and edited scripts, like a scene load
              std::vector<std::string> wanted;
              if (a.contains("files") && a["files"].is_array())
                  for (const Json& f : a["files"]) wanted.push_back(f.get<std::string>());
              auto resolved = resolve_test_files(wanted);
              if (!resolved.ok()) throw CommandError("invalid_argument", resolved.error().message, resolved.error().hint);
              const std::vector<std::string> files = *resolved;
              TestReport rep = I.scripts.run_tests(files, a.value("filter", std::string()));
              Json j = rep.to_json();
              if (j.is_object()) {
                  j["ok"] = rep.ok();
                  j["summary"] = rep.summary();
                  j["files"] = files;
              }
              return j;
          });

    // ------------------------------------------------------------------ physics
    I.commands.add({"physics.raycast", "Cast a ray against colliders (2D segment or 3D ray) and return the first hit.",
           "2D: {from:[x,y], to:[x,y]}. 3D: {dimension:\"3d\", origin:[x,y,z], direction:[x,y,z], maxDistance}. Options, the same as "
           "physics.shape_cast and the script API physics.raycast(a, b, {mask, ignore, ignoreTriggers}): mask = collision layer "
           "bit mask (bit i = layer i, -1 = all layers); ignore = id (or name) of an entity whose colliders, and its children's, "
           "are skipped (usually the caster, so a ray starting at a body's edge does not hit the body itself); ignoreTriggers "
           "(default true) skips trigger colliders, false hits them too. A collider that contains the ray origin is always "
           "skipped. Result: {hit:false} or {hit:true, entity, point, normal, distance}. Example: "
           "physics.raycast {\"from\":[0,300],\"to\":[0,-300],\"ignore\":\"player\",\"ignoreTriggers\":false}",
           with_cast_options(parse_schema(R"({"type":"object","properties":{
               "dimension":{"type":"string","enum":["2d","3d"],"default":"2d"},
               "from":{"type":"array","description":"2D start [x,y]."},"to":{"type":"array","description":"2D end [x,y]."},
               "origin":{"type":"array","description":"3D origin [x,y,z]."},"direction":{"type":"array","description":"3D direction."},
               "maxDistance":{"type":"number","default":1000}}})")),
           true, "physics"},
          [&engine, &I](const Json& a) {
              std::string err;
              std::optional<RaycastHit> hit;
              auto need = [&](const char* key, auto& out) {
                  if (!a.contains(key)) throw CommandError("invalid_argument", std::string("Missing '") + key + "'.", "See the command description for the 2D/3D forms.");
                  if (!json_to(a[key], out, &err)) throw CommandError("invalid_argument", std::string(key) + ": " + err);
              };
              const RaycastOptions opt = cast_options(I.world, a);
              if (a.value("dimension", std::string("2d")) == "3d") {
                  Vec3 o, d;
                  need("origin", o);
                  need("direction", d);
                  hit = I.physics.raycast3d(I.world, o, d, a.value("maxDistance", 1000.0f), opt);
              } else {
                  Vec2 f, t;
                  need("from", f);
                  need("to", t);
                  hit = I.physics.raycast2d(I.world, f, t, opt);
              }
              return hit_json(I.world, hit);
          });

    I.commands.add({"physics.shape_cast",
           "Sweep a circle, sphere or box from one point to another and return the first collider it touches.",
           "Like physics.raycast, but the shape has size: use it to ask whether a character fits or how far a box can move "
           "before it hits something. 2 numbers in from/to = 2D, 3 numbers = 3D. shape: 2D {\"shape\":\"circle\",\"radius\":8} "
           "or {\"shape\":\"box\",\"size\":[16,24]}; 3D {\"shape\":\"sphere\",\"radius\":0.5} or {\"shape\":\"box\",\"size\":[1,2,1]} "
           "(2D pixels, 3D meters, full sizes). The shape is centred on the cast position and axis-aligned. Result: "
           "{hit:false} or {hit:true, entity, point, normal, distance}: distance is how far the CENTRE travels before contact, "
           "point the contact point, normal the hit surface's normal (pointing back at the shape). Colliders the shape "
           "already overlaps at `from` are skipped (like a ray starting inside one); a collider it only touches blocks the "
           "cast only if it moves towards it. Options as for physics.raycast: mask; ignore = id of an entity whose colliders "
           "(and its children's) are skipped, usually the caster; triggers are skipped unless ignoreTriggers=false. Example: "
           "physics.shape_cast {\"shape\":{\"shape\":\"box\",\"size\":[32,48]},\"from\":[0,100],\"to\":[0,-300],\"ignore\":\"player\"}",
           with_cast_options(parse_schema(R"({"type":"object","required":["shape","from","to"],"properties":{
               "shape":{"type":"object","description":"2D: {shape:\"circle\",radius} or {shape:\"box\",size:[w,h]}. 3D: {shape:\"sphere\",radius} or {shape:\"box\",size:[x,y,z]}."},
               "from":{"type":"array","items":{"type":"number"},"description":"Start of the shape's centre, [x,y] (2D) or [x,y,z] (3D)."},
               "to":{"type":"array","items":{"type":"number"},"description":"End of the shape's centre, same dimension as from."}}})")),
           true, "physics"},
          [&engine, &I](const Json& a) {
              auto point = [&](const char* key, std::size_t& n) {
                  if (!a.contains(key))
                      throw CommandError("invalid_argument", std::string("Missing '") + key + "'.",
                                         "Pass from and to as [x,y] (2D) or [x,y,z] (3D). Example: physics.shape_cast "
                                         "{\"shape\":{\"shape\":\"circle\",\"radius\":8},\"from\":[0,100],\"to\":[0,-300]}");
                  const Json& v = a[key];
                  bool ok = v.is_array() && (v.size() == 2 || v.size() == 3);
                  for (std::size_t i = 0; ok && i < v.size(); ++i) ok = v[i].is_number();
                  if (!ok)
                      throw CommandError("invalid_argument", std::string("'") + key + "' must be [x,y] (2D) or [x,y,z] (3D), but got " + v.dump() + ".",
                                         "Use plain numbers, for example \"" + std::string(key) + "\":[0,100].");
                  n = v.size();
                  return Vec3{v[0].get<float>(), v[1].get<float>(), n == 3 ? v[2].get<float>() : 0.0f};
              };
              std::size_t nf = 0, nt = 0;
              const Vec3 from = point("from", nf), to = point("to", nt);
              if (nf != nt)
                  throw CommandError("invalid_argument", "'from' has " + std::to_string(nf) + " numbers but 'to' has " + std::to_string(nt) + ".",
                                     "Both are [x,y] for a 2D cast or both [x,y,z] for a 3D cast.");
              const bool is3d = nf == 3;
              auto shape = cast_shape_from_json(a.value("shape", Json()), is3d);
              if (!shape.ok()) throw CommandError("invalid_argument", "shape: " + shape.error().message, shape.error().hint);
              const RaycastOptions opt = cast_options(I.world, a);
              std::optional<RaycastHit> hit = is3d ? I.physics.shape_cast3d(I.world, *shape, from, to, opt)
                                                   : I.physics.shape_cast2d(I.world, *shape, {from.x, from.y}, {to.x, to.y}, opt);
              return hit_json(I.world, hit);
          });

    I.commands.add({"nav.bake",
           "Bake the NavMesh3D walkable grid from the static 3D colliders and return its stats.",
           "A NavMesh3D component marks a box of the level. Baking voxelizes the static colliders inside it (no RigidBody3D "
           "or a static one; triggers, Collider3D.navObstacle and Collider3D.navWalkable colliders are left out; navWalkable ones are added as moving cells) into a grid of walkable cells: not "
           "steeper than maxSlope, agentHeight of room above, agentRadius from walls and drops, neighbours joined when they "
           "differ by at most stepHeight. It is baked by itself when the scene loads and when the colliders change "
           "(autoBake); call this to bake on demand, for example with autoBake off. mesh = id of the entity with the "
           "NavMesh3D; omitted = every enabled one. Result: a list of {mesh, cellsX, cellsZ, cells, spans, walkableCells, "
           "regions, obstacles, links, walkableBodies}; NavLink3D entities add off-mesh links; no timing, so the same level gives the same result. Example: nav.bake {\"mesh\":\"navmesh\"}",
           parse_schema(R"({"type":"object","properties":{"mesh":{"type":"string","description":"Id of the entity with the NavMesh3D to bake; omitted = all enabled ones."}}})"),
           true, "physics"},
          [&I](const Json& a) {
              auto r = I.physics.nav_bake(I.world, a.value("mesh", std::string()));
              if (!r.ok()) throw CommandError("nav_error", r.error().message, r.error().hint);
              Json out = Json::array();
              for (const NavBakeStats& s : r.value()) out.push_back(s.to_json());
              return out;
          });

    I.commands.add({"nav.find_path",
           "Find a walkable path between two 3D points on the baked NavMesh3D.",
           "A* over the walkable grid, then string pulling: the result is few corner points from `from` to `to` on the "
           "walkable surface (meters). Result {found:true, points:[[x,y,z],...], length, complete, links?:[{point, entity}], from, to, mesh} or "
           "{found:false, reason, message, hint}: reason is start_off_mesh / goal_off_mesh (not on walkable ground; "
           "nearest and nearestDistance say where the nearest walkable point is) or disconnected (the two are in "
           "different walkable areas, a moving obstacle blocks the way, or a navWalkable platform is away). A start or goal within `snap` meters of "
           "walkable ground is moved onto it. closest=true returns a path to the reachable point nearest the goal "
           "(complete=false) instead of failing when disconnected. radius = agent radius of this query; larger than the "
           "NavMesh3D.agentRadius it was baked for is an error: bake for the bigger agent (a second NavMesh3D). "
           "mesh = id of the NavMesh3D entity; omitted = the first enabled one that contains `from`. Scripts: "
           "nav.findPath(from, to, {radius}). Example: nav.find_path {\"from\":[0,0,0],\"to\":[10,0,5]}",
           parse_schema(R"({"type":"object","required":["from","to"],"properties":{
               "from":{"type":"array","items":{"type":"number"},"description":"Start point [x,y,z] in meters (the agent's feet)."},
               "to":{"type":"array","items":{"type":"number"},"description":"Goal point [x,y,z] in meters."},
               "radius":{"type":"number","description":"Agent radius for this query; must not exceed NavMesh3D.agentRadius. Default: the mesh's."},
               "snap":{"type":"number","description":"How far (meters) a start or goal off the walkable cells is moved onto the nearest one. Default: agentRadius + 2 cells."},
               "closest":{"type":"boolean","description":"When the goal is unreachable, return a path to the reachable point nearest to it (complete=false)."},
               "mesh":{"type":"string","description":"Id of the entity with the NavMesh3D to use. Default: the first enabled one that contains `from`."}}})"),
           true, "physics"},
          [&I](const Json& a) {
              auto point = [&](const char* key) {
                  const Json v = a.value(key, Json());
                  bool ok = v.is_array() && v.size() == 3;
                  for (std::size_t i = 0; ok && i < v.size(); ++i) ok = v[i].is_number();
                  if (!ok)
                      throw CommandError("invalid_argument",
                                         std::string("'") + key + "' must be [x,y,z] numbers, but got " + v.dump() + ".",
                                         "Pass 3D points in meters, for example \"" + std::string(key) + "\":[0,0,0].");
                  return Vec3{v[0].get<float>(), v[1].get<float>(), v[2].get<float>()};
              };
              const Vec3 from = point("from"), to = point("to");
              NavPathOptions o;
              o.radius = a.value("radius", -1.0f);
              o.snap = a.value("snap", -1.0f);
              o.closest = a.value("closest", false);
              o.mesh = a.value("mesh", std::string());
              auto r = I.physics.nav_find_path(I.world, from, to, o);
              if (!r.ok()) throw CommandError("nav_error", r.error().message, r.error().hint);
              return r.value().to_json();
          });

    I.commands.add({"nav.find_tile_path",
           "Find a path over the cells of a Tilemap (or a plain cost grid) with A*.",
           "Cells are (col, row), 0-based, row 0 = the top row. Pass `tilemap` (id of an entity with a Tilemap: tiles in "
           "solidTiles block, every other cell costs 1, `costs` {\"<tile index>\": cost | null} overrides per tile, null = "
           "blocked, key \"-1\" = empty cells) OR `grid` {width, height, cost: [..row-major..], origin?, cellSize?} (cost = the "
           "cost of entering a cell, >= 0; null or negative = blocked). Steps are 4-way; diagonals=true allows 8-way and a "
           "diagonal never cuts a corner (both cells it passes between must be open). The start cell is always allowed; a "
           "blocked goal fails with goal_blocked unless allowBlockedGoal=true (it is then entered at cost 1) or closest=true. "
           "closest=true returns the path to the reachable cell nearest the goal (complete=false) when the goal cannot be "
           "reached; maxNodes bounds the search (reason too_far). Result {found, complete, cells:[[col,row]..], points:[[x,y]..] "
           "(cell centres: WORLD positions for a tilemap, origin + (col+0.5, -(row+0.5)) * cellSize for a grid), cost, length} "
           "or {found:false, reason: start_off_map | goal_off_map | goal_blocked | blocked | too_far, message, hint}. "
           "Deterministic. Scripts: nav.findTilePath(map, from, to, opts). Example: nav.find_tile_path "
           "{\"tilemap\":\"ground\",\"from\":[0,0],\"to\":[5,3],\"diagonals\":true}",
           parse_schema(R"({"type":"object","required":["from","to"],"properties":{
               "tilemap":{"type":"string","description":"Id of the entity with the Tilemap. Give this or `grid`."},
               "grid":{"type":"object","description":"A plain grid: {width, height, cost: [width*height numbers, row-major, row 0 = top; null or negative = blocked], origin?: [x,y] top-left corner, cellSize?: number | [w,h]}."},
               "from":{"type":"array","items":{"type":"number"},"description":"Start cell [col,row]."},
               "to":{"type":"array","items":{"type":"number"},"description":"Goal cell [col,row]."},
               "costs":{"type":"object","description":"Tilemap only: cost of entering a cell by tile index, {\"3\": 2.5, \"7\": null}; null or negative blocks, a solid tile listed here is walkable."},
               "diagonals":{"type":"boolean","description":"Allow 8-way steps (no corner cutting). Default false."},
               "maxNodes":{"type":"integer","description":"Most cells the search expands before it gives up (too_far). Default 100000."},
               "closest":{"type":"boolean","description":"Goal unreachable: return the path to the nearest reachable cell (complete=false)."},
               "allowBlockedGoal":{"type":"boolean","description":"A blocked goal cell can still be entered (cost 1)."}}})"),
           true, "physics"},
          [&I](const Json& a) {
              auto r = nav_tile_query(I.world, a);
              if (!r.ok()) throw CommandError("nav_error", r.error().message, r.error().hint);
              return r.value();
          });

    I.commands.add({"nav.info",
           "List the NavMesh3D components with their bounds, agent size, bake state and stats.",
           "Use it to check that a level was baked and how much of it is walkable. Result: a list of {mesh, enabled, "
           "autoBake, baked, error?, boundsMin, boundsMax, cellSize, agentRadius, agentHeight, stepHeight, maxSlope, "
           "staleSinceBake, stats} (stats include links and walkableBodies). staleSinceBake is true when the colliders changed after the last bake of a mesh with "
           "autoBake off (call nav.bake).",
           parse_schema(R"({"type":"object","properties":{}})"), true, "physics"},
          [&I](const Json&) { return I.physics.nav_info(I.world); });

    // ---------------------------------------------------------------------- api
    I.commands.add({"api.components", "Describe every component type: fields, kinds, defaults, docs.",
           "Read this before writing scene JSON. Example: api.components {}",
           parse_schema(R"({"type":"object","properties":{}})"), true, "api"},
          [&engine, &I](const Json&) { return TypeRegistry::global().describe_all(); });
    I.commands.add({"api.commands", "Describe every registered command (name, summary, schema).",
           "Example: api.commands {}", parse_schema(R"({"type":"object","properties":{}})"), true, "api"},
          [&engine, &I](const Json&) { return I.commands.describe(); });
    I.commands.add({"api.scripting", "Machine-readable JavaScript API (modules, classes, functions) for gameplay scripts.",
           "Example: api.scripting {}", parse_schema(R"({"type":"object","properties":{}})"), true, "api"},
          [&engine, &I](const Json&) { return I.scripts.api_manifest(); });

    // ------------------------------------------------------------------- assets
    I.commands.add({"assets.list", "List project asset files with type and size. Types: texture, audio, font, mesh, script, scene, prefab, material, other (by file name).",
           "Example: assets.list {\"folder\":\"assets\",\"extension\":\".png\"}",
           parse_schema(R"({"type":"object","properties":{
               "folder":{"type":"string","default":"assets","description":"Project-relative folder."},
               "extension":{"type":"string","description":"Only files with this extension, e.g. .png"}}})"),
           true, "assets"},
          [&engine, &I](const Json& a) {
              std::string folder = a.value("folder", std::string("assets"));
              auto files = fs::list(folder, true, a.value("extension", std::string()));
              Json list = Json::array();
              for (const std::string& f : files) {
                  const std::string type = asset_type_of(f);
                  const auto sz = fs::file_size(f);
                  list.push_back(Json::object({{"path", f}, {"type", type}, {"size", sz < 0 ? std::uint64_t(0) : std::uint64_t(sz)}}));
              }
              return Json::object({{"folder", folder}, {"count", list.size()}, {"files", list}});
          });
}

}  // namespace fa
