// Private state of fa::Engine, shared by engine.cpp, commands.cpp and runners.cpp.
#pragma once

#include <map>
#include <memory>
#include <string>
#include <vector>

#include "fa/runtime/engine.h"

namespace fa {

struct Engine::Impl {
    Engine* self = nullptr;
    EngineConfig cfg;
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

    std::uint64_t frame = 0;
    bool paused = false;
    bool quit = false;
    bool inFrame = false;  // between the start and the end of run_frame (commands defer risky work)
    double accumulator = 0.0;
    double fixedDt = 1.0 / 60.0;
    std::string pendingScene;
    bool hasPendingScene = false;
    std::string currentScene;
    std::vector<std::string> sceneIssues;  // every LoadMessage of the last scene load (errors + warnings)
    std::size_t sceneErrorCount = 0;
    std::vector<std::string> startupProblems;

    // Hot reload
    std::map<std::string, std::int64_t> watched;
    bool watchSeeded = false;
    double watchTimer = 0.0;

    // Lifecycle helpers
    void run_frame(double dt, int fixedSteps);
    void render(double dt);
    void end_of_frame(double dt);
    bool load_scene_impl(const std::string& path, std::string* error);
    void poll_hot_reload(bool force = false);
    void apply_scene_change();

    // Input injection by name: action ("jump"), key ("Space") or mouse button ("MouseLeft").
    // Returns false (and a message) for an unknown name.
    bool inject_named(const std::string& name, bool down, std::string* error);
};

void register_builtin_commands(Engine& engine, Engine::Impl& impl);

}  // namespace fa
