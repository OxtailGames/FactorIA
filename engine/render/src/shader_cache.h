// Shader program creation with a disk cache where the backend allows one (docs/PERFORMANCE.md "Startup", per-backend table).
//
//   D3D11  sokol compiles the HLSL of a shader with D3DCompile every start (8 built-in programs: ~0.3-1 s cold). The engine
//          compiles it itself the first time, stores the bytecode (DXBC) in fs::cache_dir() and hands sokol the bytecode
//          next time: no compiler is loaded or run. DXBC does not depend on the graphics card or driver (the driver turns it
//          into machine code), so the key is the backend, the compiler target and flags, the engine version and a hash of the
//          source: a changed shader, another engine version or other flags make a file Stale and it is rebuilt.
//   others sokol_gfx gives no way to hand it a compiled program (GL links from source inside the driver call, Metal builds
//          its library from MSL source), so there is nothing to cache from here: the driver's own shader cache and the OS's
//          Metal cache do that. The creation is still timed, so the startup report says what it costs.
//
// Everything here runs on the thread that owns the graphics context (the main thread).
#pragma once

#include <cstdint>
#include <filesystem>
#include <functional>
#include <string>
#include <string_view>
#include <vector>

#include "sokol_gfx.h"

#include "fa/core/blob_cache.h"
#include "fa/core/json.h"

namespace fa::render {

struct ShaderBuildStats {
    int programs = 0;          // shader programs made
    int stages = 0;            // vertex / fragment stages that came through the cache layer (D3D11 only)
    int cacheHits = 0;         // stages whose bytecode came from the disk cache
    int cacheMisses = 0;       // stages with no cache file: compiled and stored
    int cacheStale = 0;        // stages whose cache file was made for another key: compiled and stored again
    int cacheDamaged = 0;      // stages whose cache file was damaged (cut short, bad checksum, ...): compiled and stored again
    int cacheStored = 0;       // files written
    int cacheStoreFailed = 0;  // files that could not be written (the game runs without them)
    double createMs = 0;       // wall time spent in make_shader
    Json to_json(const char* backend) const;
};

// Compiles one stage to bytecode: returns false and sets `error` when it cannot (the caller lets sokol compile and report).
using StageCompiler = std::function<bool(const sg_shader_function& fn, std::vector<std::uint8_t>& bytecode, std::string& error)>;

// The bytecode of one stage through the cache: a Hit returns the cached bytes; a Miss, Stale or Damaged file compiles with
// `compile` and stores the result. `keyBase` says what every blob of this run depends on ("d3d11|<version>|<flags>"); the
// source, entry and target are added to it. Returns false when the stage could not be compiled. `cache` may be disabled
// (then it only compiles). Counts into `stats`.
bool cached_stage_bytecode(const std::filesystem::path& cacheDir, std::string_view keyBase, std::string_view label, std::string_view stage,
                           const sg_shader_function& fn, const StageCompiler& compile, std::vector<std::uint8_t>& out,
                           ShaderBuildStats& stats);

// A cache file name for a program label and stage: letters, digits, '.', '_' and '-' only, bounded, unique per label.
std::string shader_cache_file_name(std::string_view label, std::string_view stage);

// sg_make_shader through the cache layer. `label` names the program in the cache file and logs (desc->label when null).
sg_shader make_shader(const sg_shader_desc* desc, const char* label = nullptr);

const ShaderBuildStats& shader_build_stats();
void reset_shader_build_stats();
// "d3d11-dxbc" where the engine caches, "none" elsewhere or when there is no cache folder.
const char* shader_cache_mode();

}  // namespace fa::render
