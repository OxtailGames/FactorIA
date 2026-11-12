// The commands of background loading (docs/PERFORMANCE.md, "Background loading"): scene.preload, assets.preload,
// load.status and load.cancel. scene.load {async: true} is in commands.cpp, next to scene.load. The work is the engine's
// BackgroundLoader (background_loader.h): these commands only start, look at and stop its jobs, which advance in the
// frames the engine runs.
#include "engine_impl.h"

namespace fa {

namespace {

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

Json started(Engine::Impl& I, const Result<int>& r) {
    if (!r.ok()) throw CommandError("not_found", r.error().message, r.error().hint);
    Json out = I.loader->status(r.value());
    out["loadId"] = r.value();
    return out;
}

int need_id(const Json& a, const char* command) {
    const Json& id = a["id"];
    if (!id.is_number_integer() || id.get<std::int64_t>() < 1 || id.get<std::int64_t>() > 0x7fffffff)
        throw CommandError("invalid_argument", std::string(command) + ": `id` must be the loadId a load answered (a whole number from 1)",
                           "load.status {} lists the loads that run and the last ones that ended.");
    return int(id.get<std::int64_t>());
}

}  // namespace

void register_background_load_commands(Engine& engine, Engine::Impl& I) {
    (void)engine;
    I.commands.add({"scene.preload", "Read a scene's files in the background, so a later scene.load waits for nothing.",
           "Starts a background load of the scene file and everything it uses (prefabs, materials, scripts, models, textures, "
           "fonts, sounds): the IO thread reads them and jobs decode them while frames run; each frame the main thread uploads "
           "a share to the GPU (docs/PERFORMANCE.md, \"Background loading\"). Answers at once with `loadId` and the load's "
           "status; it advances in the frames the game runs (game.step, play.auto, a running window). The files stay ready "
           "until the second scene load after the preload finished (load.cancel drops them earlier). A missing scene is an "
           "error with \"did you mean\". Example: scene.preload {\"path\":\"scenes/level2.scene.json\"}",
           parse_schema(R"({"type":"object","required":["path"],"properties":{
               "path":{"type":"string","description":"Project-relative scene path, e.g. scenes/level2.scene.json."}}})"),
           false, "scene"},
          [&I](const Json& a) {
              if (!I.loader) throw CommandError("unavailable", "The engine is not running.", "");
              return started(I, I.start_background_load(BackgroundLoader::Kind::ScenePreload, {a["path"].get<std::string>()},
                                                        std::nullopt, BackgroundLoader::Origin::Tool));
          });

    I.commands.add({"assets.preload", "Read a list of asset files in the background, ready for their first use.",
           "Starts a background load of the listed files: textures, models, fonts and sounds are decoded into the engine's "
           "caches (a .gltf brings its buffers and textures, a .prefab.json or .material.json what it names); any other file "
           "is read into memory. Answers at once with `loadId` and the status; it advances in the frames the game runs. A "
           "missing file is an error with \"did you mean\"; a folder is an error too. Example: "
           "assets.preload {\"paths\":[\"assets/boss.glb\",\"sounds/boss_theme.ogg\"]}",
           parse_schema(R"({"type":"object","required":["paths"],"properties":{
               "paths":{"type":"array","minItems":1,"items":{"type":"string"},"description":"Project-relative files to read ahead."}}})"),
           false, "assets"},
          [&I](const Json& a) {
              if (!I.loader) throw CommandError("unavailable", "The engine is not running.", "");
              std::vector<std::string> paths;
              for (const Json& p : a["paths"]) paths.push_back(p.get<std::string>());
              return started(I, I.start_background_load(BackgroundLoader::Kind::Assets, paths, std::nullopt,
                                                        BackgroundLoader::Origin::Tool));
          });

    I.commands.add({"load.status", "Show the background loads: progress, items, bytes, errors.",
           "With `id`: that load (from scene.preload, assets.preload, scene.load {async:true}, or a script's handle). "
           "Without: {jobs, threaded, warmBytes}, the loads that run and the last 16 that ended. A load is {id, kind, paths, "
           "origin (script|tool), state (scanning|loading|done|failed|cancelled), progress (0..1, never goes down), items "
           "{done, total} (the scan counts as one), bytes, uploadedBytes, error?, hint?}. `threaded` is false when the job pool "
           "has no worker thread: the files are then read on the main thread, a share per frame. Example: load.status {\"id\":1}",
           parse_schema(R"({"type":"object","properties":{
               "id":{"type":"integer","minimum":1,"description":"A loadId. Default: every running and recent load."}}})"),
           true, "scene"},
          [&I](const Json& a) {
              if (!I.loader) throw CommandError("unavailable", "The engine is not running.", "");
              if (!a.contains("id")) return I.loader->status_all();
              const int id = need_id(a, "load.status");
              Json s = I.loader->status(id);
              if (s.is_null())
                  throw CommandError("not_found", "load.status: no background load " + std::to_string(id) + " (or it ended long ago)",
                                     "load.status {} lists the loads that run and the last 16 that ended.");
              return s;
          });

    I.commands.add({"load.cancel", "Stop a background load, or drop the files a finished one read ahead.",
           "A running load stops: what it decoded is thrown away, an async scene.load does not switch, and a script's handle "
           "rejects with \"cancelled\" in the next frame. A finished load's files read ahead are dropped now, and an async "
           "scene.load whose files were ready this frame does not switch at its end. Answers {id, cancelled}. "
           "Example: load.cancel {\"id\":1}",
           parse_schema(R"({"type":"object","required":["id"],"properties":{
               "id":{"type":"integer","minimum":1,"description":"The loadId to stop."}}})"),
           false, "scene"},
          [&I](const Json& a) {
              if (!I.loader) throw CommandError("unavailable", "The engine is not running.", "");
              const int id = need_id(a, "load.cancel");
              if (!I.cancel_background_load(id))
                  throw CommandError("not_found", "load.cancel: no background load " + std::to_string(id),
                                     "load.status {} lists the loads that run.");
              return Json::object({{"id", id}, {"cancelled", true}});
          });

    // Capabilities (capability.h): what each command does outside the engine's memory.
    declare_command_capabilities(I.commands, {
        {"scene.preload", capability_sets::changes_state()},
        {"assets.preload", capability_sets::changes_state()},
        {"load.cancel", capability_sets::changes_state()},
        {"load.status", capability_sets::reads()},
    });
}

}  // namespace fa
