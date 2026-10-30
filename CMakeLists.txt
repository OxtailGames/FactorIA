cmake_minimum_required(VERSION 3.24)
# CMake 3.25+: the MSVC debug information format is a property, so ccache can get /Z7 below instead of /Zi.
if(POLICY CMP0141)
    cmake_policy(SET CMP0141 NEW)
endif()

project(FactorIA
    VERSION 0.7.5
    DESCRIPTION "AI-native 2D/3D game engine"
    LANGUAGES C CXX)

if(APPLE)
    enable_language(OBJC OBJCXX)
endif()

# Faster rebuilds when ccache is available (optional; -DFA_CCACHE=OFF turns it off).
# base_dir: paths inside this checkout are hashed relative to the build directory, so git worktrees of the repository
# share one cache. hash_dir=false: for the same reason; the working directory recorded in an object's debug info may
# then name another checkout (debuggers may ask where a source file is).
# Not with MSVC: on a cache hit ccache replays cl's /showIncludes output as it was recorded, with the absolute header
# paths of the checkout that filled the cache, so Ninja would watch another worktree's headers and not rebuild the
# objects that include a header changed here (stale objects: crashes, or tests that pass on old code). GCC and Clang
# hand Ninja a depfile, which ccache writes with paths relative to the build directory: those resolve in each checkout.
# Not with an MSVC in another language either: on a miss Ninja reads cl's /showIncludes lines in the console code page,
# on a hit ccache replays them in UTF-8, so a non-ASCII prefix (Spanish "Nota: inclusión del archivo:") stops matching
# and Ninja records no header dependencies for every object that was a cache hit: stale objects again.
find_program(FA_CCACHE ccache)
if(FA_CCACHE AND MSVC AND CMAKE_CL_SHOWINCLUDES_PREFIX MATCHES "[^ -~]")
    message(STATUS "ccache not used: cl's /showIncludes prefix is not ASCII ('${CMAKE_CL_SHOWINCLUDES_PREFIX}'), and "
        "Ninja would lose header dependencies on cache hits. English cl messages (VSLANG=1033, English language pack) keep it.")
elseif(FA_CCACHE AND NOT CMAKE_CXX_COMPILER_LAUNCHER)
    set(CMAKE_C_COMPILER_LAUNCHER ${FA_CCACHE})
    execute_process(COMMAND ${FA_CCACHE} --version OUTPUT_VARIABLE _fa_ccache_version ERROR_QUIET)
    string(REGEX MATCH "[0-9]+\\.[0-9]+" _fa_ccache_version "${_fa_ccache_version}")
    # Settings as arguments came in ccache 4.8 (Ubuntu 22.04 has 4.5).
    if(_fa_ccache_version VERSION_GREATER_EQUAL 4.8 AND NOT MSVC)
        list(APPEND CMAKE_C_COMPILER_LAUNCHER base_dir=${CMAKE_CURRENT_SOURCE_DIR} hash_dir=false)
    endif()
    set(CMAKE_CXX_COMPILER_LAUNCHER ${CMAKE_C_COMPILER_LAUNCHER})
    # MSVC: ccache cannot cache /Zi (one .pdb shared by all objects of a target); /Z7 keeps debug info in each object.
    set(CMAKE_MSVC_DEBUG_INFORMATION_FORMAT "$<$<CONFIG:Debug,RelWithDebInfo>:Embedded>")
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

# Linux: the C++ code needs a compiler newer than the oldest distribution the programs must run on (std::format wants GCC
# 13+; the Steam Runtime "sniper", Ubuntu 20.04/22.04 and Debian 11/12 ship libstdc++ 10 to 12). Linking libstdc++ and
# libgcc statically leaves only glibc as a requirement of the program, and the build container's glibc sets how old a
# system it runs on. The `linux-sniper` preset sets this inside the Steam Runtime sniper SDK (scripts/build-sniper.sh); it is
# also what the Linux release packages use (.github/workflows/release.yml).
option(FA_LINUX_STATIC_LIBSTDCXX "Linux: link libstdc++ and libgcc statically (programs that run on systems older than the compiler)" OFF)
if(FA_LINUX_STATIC_LIBSTDCXX AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
    add_link_options(-static-libstdc++ -static-libgcc)
    message(STATUS "FactorIA: libstdc++ and libgcc are linked statically (FA_LINUX_STATIC_LIBSTDCXX)")
endif()

# Linux: one section per function and per data object, so the player's --gc-sections (player/CMakeLists.txt) can drop what
# no game calls. Set for every target (the engine archives and external/ too) because the linker only removes whole sections.
# The Android NDK toolchain already sets both flags, Apple's -dead_strip needs neither, MSVC Release has /OPT:REF.
if(CMAKE_SYSTEM_NAME STREQUAL "Linux" AND CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    add_compile_options(-ffunction-sections -fdata-sections)
endif()

if(FA_BUILD_TESTS)
    enable_testing()
    # This checkout's paths for tests, in a header rather than -D flags: only the tests that include it differ between
    # git worktrees, so the others share the ccache. Test targets get FA_GENERATED_DIR on their include path.
    set(FA_GENERATED_DIR ${CMAKE_BINARY_DIR}/generated)
    file(CONFIGURE OUTPUT ${FA_GENERATED_DIR}/fa_test_paths.h CONTENT [[
// Generated by CMake (CMakeLists.txt): absolute paths of the checkout this build comes from.
#pragma once
#define FA_REPO_ROOT "@FA_ROOT@"
#define FA_AI_FIXTURES FA_REPO_ROOT "/tools/ai/tests/fixtures"
#define FA_RENDER_GOLDEN_DIR FA_REPO_ROOT "/engine/render/tests/golden"
#define FA_RENDER_DATA_DIR FA_REPO_ROOT "/engine/render/tests/data"
#define FA_VIDEO_FIXTURE FA_REPO_ROOT "/engine/core/tests/data/colors.mpg"
]] @ONLY)
endif()

# ---- floating point: the same source gives the same numbers on more CPUs and compilers (CC/FB-0055) --------------------
# Set for EVERY target, not only fa_physics and fa_scene: inline functions of fa_core's headers (normalize, rotations, quaternion
# maths) are emitted by every module that uses them and the linker keeps ONE copy; if that copy came from a module built
# with other flags, physics would run it. (A Debug test binary did exactly that: its physics differed from Release.)
#  * No contraction: a*b+c is a multiply then an add. Clang on arm64 (macOS, iOS, Android) fuses it by default, GCC does on any
#    CPU with FMA. Emscripten has no FMA (the flag changes nothing); MSVC /fp:precise is its default, set explicitly.
#  * -fmath-errno (Clang; GCC has it already): sin, cos, atan2... stay calls into the C library. Without it Clang folds them with
#    its own arithmetic and merges sin(x) with cos(x) into one sincos call (macOS: __sincosf_stret), which rounds differently
#    from the two calls, so the same source gave different physics at -O0 and -O3.
# Nothing uses -ffast-math. docs/AI_GUIDE.md ("Physics and platforms") says what this does and does not give.
# One genex per language: the Visual Studio generators only accept $<COMPILE_LANGUAGE:> with a single language.
set(_fa_fp_langs C CXX)
if(APPLE)
    list(APPEND _fa_fp_langs OBJC OBJCXX)
endif()
foreach(_lang ${_fa_fp_langs})
    if(MSVC)
        add_compile_options("$<$<COMPILE_LANGUAGE:${_lang}>:/fp:precise>")
    else()
        add_compile_options("$<$<COMPILE_LANGUAGE:${_lang}>:-ffp-contract=off>" "$<$<COMPILE_LANGUAGE:${_lang}>:-fmath-errno>")
    endif()
endforeach()

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
add_subdirectory(engine/ui)         # fa_ui        game UI: layout, focus and navigation, widget events
add_subdirectory(engine/services)   # fa_services  platform services: achievements, purchases, cloud saves; the fake backend
add_subdirectory(engine/script)     # fa_script    QuickJS gameplay scripting + test runner
add_subdirectory(engine/runtime)    # fa_runtime   Engine: ties everything, game loop, commands
add_subdirectory(player)            # factoria_player: minimal shipping runtime for games

# The Steam backend plugin (platforms/plugins/steam/) is built and run against a mock of the Steamworks library.
if(FA_BUILD_TESTS AND FA_DESKTOP)
    add_subdirectory(platforms/plugins/steam/tests)
endif()

# ---- developer tools (desktop only) -----------------------------------------
if(FA_BUILD_TOOLS)
    add_subdirectory(tools/common)  # fa_tooling   project scaffolding, validation, feedback, docs
    add_subdirectory(tools/mcp)     # fa_mcp       Model Context Protocol server (stdio)
    add_subdirectory(tools/dap)     # fa_dap      Debug Adapter Protocol server of the script debugger (stdio)
    add_subdirectory(tools/ai)      # fa_ai        AI providers (API keys + Claude Code/Codex CLIs), agent loop
    if(FA_BUILD_EDITOR)
        add_subdirectory(tools/editor)  # fa_editor  ImGui editor with AI assistant panel
    endif()
    add_subdirectory(tools/cli)     # factoria     the single developer binary
endif()
