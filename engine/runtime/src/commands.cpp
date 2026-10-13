// Built-in commands: the AI/tool surface of a running game.
#include <algorithm>
#include <filesystem>

#include "engine_impl.h"
#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/scene/serialize.h"

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

Json vec_json(Vec3 v) { return Json::array({to_json(v.x), to_json(v.y), to_json(v.z)}); }

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
               "name":{"type":"string"},"id":{"type":"string"},
               "tags":{"type":"array","items":{"type":"string"}},
               "components":{"type":"object","description":"Component name -> field object."}}})"),
           false, "scene"},
          [&engine, &I](const Json& a) {
              Entity parent = kNullEntity;
              if (a.contains("parent")) parent = need_entity(I.world, a, "parent");
              Json spec = a.contains("entity") && a["entity"].is_object() ? a["entity"] : Json::object();
              if (!a.contains("entity"))
                  for (const char* k : {"name", "id", "tags", "components", "active", "children"})
                      if (a.contains(k)) spec[k] = a[k];
              if (a.contains("position")) {
                  Json pos = a["position"];
                  if (pos.is_array() && pos.size() == 2) pos.push_back(0);
                  spec["components"]["Transform"]["position"] = pos;
              }
              LoadReport report;
              Entity e;
              if (a.contains("prefab") && a["prefab"].is_string()) {
                  e = instantiate_prefab(I.world, a["prefab"].get<std::string>(), parent, report, spec);
              } else {
                  if (!spec.contains("components") && !spec.contains("name") && !spec.contains("prefab") && !spec.contains("id"))
                      throw CommandError("invalid_argument", "Nothing to spawn: pass 'prefab' or entity JSON.",
                                         "Example: {\"name\":\"Box\",\"components\":{\"Shape2D\":{\"size\":[50,50]}}}");
                  e = entity_from_json(I.world, spec, parent, report, "scene.spawn", "");
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

    I.commands.add({"scene.set_component", "Add a component to an entity (if missing) and set the given fields.",
           "`fields` is a partial object; unspecified fields keep their value. Errors name the field and valid values. "
           "Example: scene.set_component {\"id\":\"player\",\"component\":\"Sprite\",\"fields\":{\"color\":\"red\"}}",
           parse_schema(R"({"type":"object","required":["id","component"],"properties":{
               "id":{"type":"string","description":"Entity id (or name)."},
               "component":{"type":"string","description":"Component name, e.g. Transform, Sprite, RigidBody2D."},
               "fields":{"type":"object","description":"Field name -> value."}}})"),
           false, "scene"},
          [&engine, &I](const Json& a) {
              Entity e = need_entity(I.world, a);
              const std::string cname = a["component"].get<std::string>();
              const TypeInfo& t = need_component_type(cname);
              Json fields = a.contains("fields") ? a["fields"] : Json::object();
              auto r = patch_component(I.world, e, t, fields);
              if (!r.ok())
                  throw CommandError("invalid_argument", r.error().message,
                                     r.error().hint.empty() ? "Use api.components to see the fields of " + t.name + "." : r.error().hint);
              return Json::object({{"id", I.world.id_of(e)}, {"component", t.name}, {"value", component_to_json(I.world, e, t, true, true)}});
          });

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
           "Loads immediately (outside a frame) or at the end of the current frame. Load problems are returned in "
           "`messages`. Example: scene.load {\"path\":\"scenes/level2.scene.json\"}",
           parse_schema(R"({"type":"object","required":["path"],"properties":{
               "path":{"type":"string","description":"Project-relative scene path."}}})"),
           false, "scene"},
          [&engine, &I](const Json& a) {
              std::string path = a["path"].get<std::string>();
              if (!fs::exists(path)) {
                  auto scenes = fs::list("scenes", true, ".json");
                  throw CommandError("not_found", "Scene file '" + path + "' not found. " + did_you_mean(path, scenes),
                                     "Use project.info to list scenes.");
              }
              if (I.inFrame) {
                  engine.request_scene_change(path);
                  return Json::object({{"scheduled", true}, {"path", path}});
              }
              std::string err;
              bool ok = I.load_scene_impl(path, &err);
              return Json::object({{"ok", ok}, {"path", path}, {"entityCount", I.world.entity_count()}, {"messages", I.sceneIssues}});
          });

    I.commands.add({"scene.save", "Save the running world to a scene file (current scene path by default).",
           "Writes canonical scene JSON (only non-default fields). Files inside .factoria/ belong to the engine and its tools: "
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
           "Resets the world to the saved scene file. Example: scene.reload {}",
           parse_schema(R"({"type":"object","properties":{}})"), false, "scene"},
          [&engine, &I](const Json&) {
              if (I.currentScene.empty()) throw CommandError("unavailable", "No scene is loaded.", "Use scene.load first.");
              std::string err;
              bool ok = I.load_scene_impl(I.currentScene, &err);
              return Json::object({{"ok", ok}, {"scene", I.currentScene}, {"messages", I.sceneIssues}});
          });

    register_level_commands(engine, I);       // scene.import_ascii
    register_scene_file_commands(engine, I);  // prefab.save, scene.format

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

    I.commands.add({"game.input", "Inject input: press/release actions or keys, or set an action state, mouse position/buttons.",
           "Names may be input actions from factoria.json, key names (Space, A, Left...) or MouseLeft/MouseRight/MouseMiddle. "
           "Forms: {\"action\":\"jump\",\"down\":true}, {\"key\":\"Space\",\"down\":false}, "
           "{\"press\":[\"jump\"],\"release\":[\"fire\"]}, {\"mouse\":{\"position\":[640,360]}}. "
           "The input is applied now and seen by the next frame (game.step). Example: game.input {\"press\":[\"jump\"]}",
           parse_schema(R"({"type":"object","properties":{
               "action":{"type":"string","description":"Action name (with `down`)."},
               "key":{"type":"string","description":"Key or mouse button name (with `down`)."},
               "down":{"type":"boolean","default":true,"description":"New state for action/key."},
               "press":{"type":"array","items":{"type":"string"}},
               "release":{"type":"array","items":{"type":"string"}},
               "mouse":{"type":"object","description":"{position:[x,y] in design pixels, left/right/middle: bool}."}}})"),
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
              return I.input.snapshot();
          });

    I.commands.add({"game.screenshot", "Capture the game view as a PNG and show it.",
           "Saves the last rendered frame (design resolution) and returns the path; clients display the image. Step the "
           "game first so the picture shows what you expect. Default path .factoria/screenshots/frame_<n>.png. "
           "Example: game.screenshot {\"path\":\"shots/start.png\"}",
           parse_schema(R"({"type":"object","properties":{
               "path":{"type":"string","description":"Output PNG (project-relative or absolute)."}}})"),
           true, "game"},
          [&engine, &I](const Json& a) {
              std::string path = a.value("path", ".factoria/screenshots/frame_" + std::to_string(I.frame) + ".png");
              std::string err;
              if (!engine.screenshot(path, &err))
                  throw CommandError("unavailable", err, "Screenshots need graphics (headless needs Mesa/EGL).");
              std::string abs = abs_path(path);
              Json j = Json::object();
              j["path"] = abs;
              j["width"] = I.renderer->target_width();
              j["height"] = I.renderer->target_height();
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

    I.commands.add({"audio.log", "List the sounds played so far (clip path, frame, volume, bus, source entity), oldest first.",
           "Every play request is logged: audio.play and audio.music from scripts, AudioSource components and scene "
           "music (`music: true`), with `ok: false` when the clip failed to load. `frame`/`time` are the scene clock "
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

    I.commands.add({"script.errors", "List script errors (load/runtime) and scene load problems.",
           "Clear them with a scene reload. Example: script.errors {}",
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
           "Example: project.test {\"filter\":\"player\"}",
           parse_schema(R"({"type":"object","properties":{
               "filter":{"type":"string","description":"Only run test cases whose name contains this."},
               "files":{"type":"array","items":{"type":"string"},"description":"Test files (default: tests/*.test.js)."}}})"),
           false, "project"},
          [&engine, &I](const Json& a) {
              std::vector<std::string> files;
              if (a.contains("files") && a["files"].is_array())
                  for (const Json& f : a["files"]) files.push_back(f.get<std::string>());
              else
                  for (const auto& f : fs::list("tests", true, ".js"))
                      if (ends_with(f, ".test.js")) files.push_back(f);
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
           "2D: {from:[x,y], to:[x,y]}. 3D: {dimension:\"3d\", origin:[x,y,z], direction:[x,y,z], maxDistance}. Triggers are "
           "ignored. Example: physics.raycast {\"from\":[0,300],\"to\":[0,-300]}",
           parse_schema(R"({"type":"object","properties":{
               "dimension":{"type":"string","enum":["2d","3d"],"default":"2d"},
               "from":{"type":"array","description":"2D start [x,y]."},"to":{"type":"array","description":"2D end [x,y]."},
               "origin":{"type":"array","description":"3D origin [x,y,z]."},"direction":{"type":"array","description":"3D direction."},
               "maxDistance":{"type":"number","default":1000},
               "mask":{"type":"integer","default":-1,"description":"Collision layer mask."}}})"),
           true, "physics"},
          [&engine, &I](const Json& a) {
              std::string err;
              std::optional<RaycastHit> hit;
              auto need = [&](const char* key, auto& out) {
                  if (!a.contains(key)) throw CommandError("invalid_argument", std::string("Missing '") + key + "'.", "See the command description for the 2D/3D forms.");
                  if (!json_to(a[key], out, &err)) throw CommandError("invalid_argument", std::string(key) + ": " + err);
              };
              int mask = a.value("mask", -1);
              if (a.value("dimension", std::string("2d")) == "3d") {
                  Vec3 o, d;
                  need("origin", o);
                  need("direction", d);
                  hit = I.physics.raycast3d(I.world, o, d, a.value("maxDistance", 1000.0f), mask);
              } else {
                  Vec2 f, t;
                  need("from", f);
                  need("to", t);
                  hit = I.physics.raycast2d(I.world, f, t, mask);
              }
              Json j = Json::object({{"hit", hit.has_value()}});
              if (hit) {
                  j["entity"] = hit->entity ? Json(I.world.id_of(hit->entity)) : Json(nullptr);
                  j["point"] = vec_json(hit->point);
                  j["normal"] = vec_json(hit->normal);
                  j["distance"] = hit->distance;
              }
              return j;
          });

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
    I.commands.add({"assets.list", "List project asset files with type and size.",
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
                  std::string ext = fs::extension(f);
                  const char* type = "other";
                  if (ext == ".png" || ext == ".jpg" || ext == ".jpeg" || ext == ".tga" || ext == ".bmp") type = "texture";
                  else if (ext == ".wav" || ext == ".ogg" || ext == ".mp3") type = "audio";
                  else if (ext == ".ttf" || ext == ".otf") type = "font";
                  else if (ext == ".obj" || ext == ".gltf" || ext == ".glb") type = "mesh";
                  else if (ext == ".js") type = "script";
                  else if (ends_with(f, ".scene.json")) type = "scene";
                  else if (ends_with(f, ".prefab.json")) type = "prefab";
                  std::error_code ec;
                  auto sz = std::filesystem::file_size(fs::resolve(f), ec);
                  list.push_back(Json::object({{"path", f}, {"type", type}, {"size", ec ? 0 : std::uint64_t(sz)}}));
              }
              return Json::object({{"folder", folder}, {"count", list.size()}, {"files", list}});
          });
}

}  // namespace fa
