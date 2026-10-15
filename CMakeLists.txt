cmake_minimum_required(VERSION 3.24)

project(FactorIA
    VERSION 0.1.2
    DESCRIPTION "AI-native 2D/3D game engine"
    LANGUAGES C CXX)

if(APPLE)
    enable_language(OBJC OBJCXX)
endif()

# Faster rebuilds when ccache is available (optional).
find_program(FA_CCACHE ccache)
if(FA_CCACHE AND NOT CMAKE_CXX_COMPILER_LAUNCHER)
    set(CMAKE_C_COMPILER_LAUNCHER ${FA_CCACHE})
    set(CMAKE_CXX_COMPILER_LAUNCHER ${FA_CCACHE})
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
# MSVC: link the C/C++ runtime statically (external/ included), so the exes run on a clean Windows without the
# Visual C++ Redistributable.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
# Visual Studio generator: compile a target's sources in parallel (MSBuild otherwise runs one cl per file in turn).
if(CMAKE_GENERATOR MATCHES "Visual Studio")
    add_compile_options(/MP)
endif()

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
include(FactoriaPlatform)   # sets FA_PLATFORM, FA_SOKOL_BACKEND, FA_DESKTOP
include(FactoriaHelpers)    # fa_add_module(), fa_add_tests(), fa_embed_files()

# ---- options ----------------------------------------------------------------
option(FA_BUILD_TESTS  "Build unit tests"                                   ON)
option(FA_BUILD_TOOLS  "Build the factoria CLI, MCP server, AI hub, editor" ${FA_DESKTOP})
option(FA_BUILD_EDITOR "Build the visual editor (requires FA_BUILD_TOOLS)"   ${FA_DESKTOP})
option(FA_WARNINGS_AS_ERRORS "Treat engine warnings as errors"              OFF)
# The release packages set it (.github/workflows/release.yml): their editor offers the updates published there.
set(FA_UPDATE_REPO "" CACHE STRING "GitHub owner/repo whose Releases the editor updates from (empty: no updates)")

set(FA_ENGINE_VERSION ${PROJECT_VERSION})
set(FA_ROOT ${CMAKE_CURRENT_SOURCE_DIR})

if(FA_BUILD_TESTS)
    enable_testing()
endif()

# ---- third party ------------------------------------------------------------
find_package(Threads REQUIRED)
add_subdirectory(external)

# ---- engine runtime (ships inside every game) --------------------------------
add_subdirectory(engine/core)       # fa_core      math, log, json, fs, reflection, commands
add_subdirectory(engine/scene)      # fa_scene     ECS world, components, scene/prefab JSON
add_subdirectory(engine/platform)   # fa_platform  window/app loop, headless GPU, input
add_subdirectory(engine/render)     # fa_render    2D + 3D renderer, text, particles, capture
add_subdirectory(engine/physics)    # fa_physics   Box2D 2D physics + simple 3D physics
add_subdirectory(engine/audio)      # fa_audio     mixer, wav/ogg/mp3
add_subdirectory(engine/script)     # fa_script    QuickJS gameplay scripting + test runner
add_subdirectory(engine/runtime)    # fa_runtime   Engine: ties everything, game loop, commands
add_subdirectory(player)            # factoria_player: minimal shipping runtime for games

# ---- developer tools (desktop only) -----------------------------------------
if(FA_BUILD_TOOLS)
    add_subdirectory(tools/common)  # fa_tooling   project scaffolding, validation, feedback, docs
    add_subdirectory(tools/mcp)     # fa_mcp       Model Context Protocol server (stdio)
    add_subdirectory(tools/ai)      # fa_ai        AI providers (API keys + Claude Code/Codex CLIs), agent loop
    if(FA_BUILD_EDITOR)
        add_subdirectory(tools/editor)  # fa_editor  ImGui editor with AI assistant panel
    endif()
    add_subdirectory(tools/cli)     # factoria     the single developer binary
endif()
