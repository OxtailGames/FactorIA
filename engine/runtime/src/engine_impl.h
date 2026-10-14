// Private state of fa::Engine, shared by engine.cpp, commands.cpp and runners.cpp.
#pragma once

#include <map>
#include <memory>
#include <string>
#include <vector>

#include "fa/runtime/engine.h"
#include "fa/scene/serialize.h"

namespace fa {

struct Engine::Impl {
    Engine* self = nullptr;
    EngineConfig cfg;
    std::uint64_t logSeqAtInit = 0;  // state() only reports logs emitted by THIS engine
    ProjectSettings project;
    bool initialized = false;
    bool windowed = false;  // GPU comes from the platform window (GfxEnvironment passed to init)

    World world;
    Input input;
    Physics physics;
    Audio audio;
    ScriptSystem scripts;
    CommandRegistry commands;
    std::unique_ptr<HeadlessGpu> gpu;
    std::unique_ptr<Renderer> renderer;

    bool renderStale = false;       // OnDemand: simulated since the last draw
    double lastRenderDt = 0.0;
    std::uint64_t renderedFrame = 0;  // frame index at the last draw
    std::uint64_t frame = 0;
    bool paused = false;
    bool quit = false;
    bool inFrame = false;  // between the start and the end of run_frame (commands defer risky work)
    double accumulator = 0.0;
    double fixedDt = 1.0 / 60.0;
    std::string pendingScene;
    bool hasPendingScene = false;
    std::string currentScene;
    // The current scene is the project's mainScene, loaded at start because no start scene was given (no EngineConfig::scene),
    // and no scene was loaded since. scene.import_ascii refuses `save` without `path` then: see level_commands.cpp.
    bool implicitStartScene = false;
    std::vector<std::string> sceneIssues;  // every LoadMessage of the last scene load (errors + warnings)
    std::size_t sceneErrorCount = 0;
    std::vector<std::string> startupProblems;

    // Hot reload
    std::map<std::string, std::int64_t> watched;
    bool watchSeeded = false;
    double watchTimer = 0.0;

    // Lifecycle helpers
    void run_frame(double dt, int fixedSteps);
    void render(double dt);       // per-frame: draws in Always mode, only simulates visuals in OnDemand
    void draw(double dt);         // draws the world now
    void finish_scene_load(const LoadReport& report, const std::string& label, std::string* error);
    bool load_scene_json_impl(const Json& scene, std::string_view sourceName, std::string* error);
    void end_of_frame(double dt);
    bool load_scene_impl(const std::string& path, std::string* error);
    void poll_hot_reload(bool force = false);
    void apply_scene_change();

    // Input injection by name: action ("jump"), key ("Space") or mouse button ("MouseLeft").
    // Returns false (and a message) for an unknown name.
    bool inject_named(const std::string& name, bool down, std::string* error);
};

void register_builtin_commands(Engine& engine, Engine::Impl& impl);
void register_level_commands(Engine& engine, Engine::Impl& impl);  // level_commands.cpp: scene.import_ascii
void register_scene_file_commands(Engine& engine, Engine::Impl& impl);  // scene_file_commands.cpp: prefab.save, scene.format

// Entity named by the string argument `key` (id or name). Throws CommandError("not_found") with a "did you mean".
Entity need_entity(World& world, const Json& args, const char* key = "id");

}  // namespace fa
