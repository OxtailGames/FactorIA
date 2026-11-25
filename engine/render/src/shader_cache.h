// Shader program creation with a disk cache where the backend allows one (docs/PERFORMANCE.md "Startup", per-backend table).
//
//   D3D11, D3D12  Without the engine's help the device compiles the HLSL of a shader with D3DCompile every start (8
//          built-in programs: ~0.3-1 s cold). The engine compiles it itself the first time (D3D12: to shader model 5.1,
//          which has its own targets and keys), stores the bytecode (DXBC) in fs::cache_dir() and hands the device the
//          bytecode next time: no compiler is loaded or run. DXBC does not depend on the graphics card or driver (the
//          driver turns it into machine code), so the key is the backend, the compiler target and flags, the engine
//          version and a hash of the source: a changed shader, another engine version or other flags make a file Stale
//          and it is rebuilt. D3D12 also keeps a pipeline library of its own (gpu/d3d12_pipelines_win32.cpp).
//   Vulkan  The generated header carries SPIR-V; it is decoded and handed to the device, which has no compiler to run, so
//          there is nothing to cache here (the pipeline cache of the device is what a restart reuses).
//   others  Metal and OpenGL cannot be given a compiled program (GL links from source inside the driver call, Metal builds
//          its library from MSL source), so there is nothing to cache from here: the driver's own shader cache and the OS's
//          Metal cache do that. The creation is still timed, so the startup report says what it costs.
//
// Everything here runs on the thread that owns the graphics context (the main thread). It reaches the GPU through
// gpu::Device (no graphics API header here).
#pragma once

#include <cstdint>
#include <filesystem>
#include <functional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/blob_cache.h"
#include "fa/core/json.h"
#include "gpu/types.h"

namespace fa::gpu {
class Device;
}

namespace fa::render {

struct ShaderBuildStats {
    int programs = 0;     // shader programs made
    int stages = 0;       // vertex / fragment stages that came through the cache layer (D3D11 only)
    int cacheHits = 0;    // stages whose bytecode came from the disk cache
    int cacheMisses = 0;  // stages with no cache file: compiled and stored
    int cacheStale = 0;   // stages whose cache file was made for another key: compiled and stored again
    int cacheDamaged =
        0;  // stages whose cache file was damaged (cut short, bad checksum, ...): compiled and stored again
    int cacheStored = 0;       // files written
    int cacheStoreFailed = 0;  // files that could not be written (the game runs without them)
    double createMs = 0;       // wall time spent in make_shader
    Json to_json(const char* backend) const;
};

// Compiles one stage to bytecode: returns false and sets `error` when it cannot (the caller lets the device compile and report).
using StageCompiler =
    std::function<bool(const gpu::ShaderFunction& fn, std::vector<std::uint8_t>& bytecode, std::string& error)>;

// The bytecode of one stage through the cache: a Hit returns the cached bytes; a Miss, Stale or Damaged file compiles with
// `compile` and stores the result. `keyBase` says what every blob of this run depends on ("d3d11|<version>|<flags>"); the
// source, entry and target are added to it. Returns false when the stage could not be compiled. `cache` may be disabled
// (then it only compiles). Counts into `stats`.
bool cached_stage_bytecode(const std::filesystem::path& cacheDir, std::string_view keyBase, std::string_view label,
                           std::string_view stage, const gpu::ShaderFunction& fn, const StageCompiler& compile,
                           std::vector<std::uint8_t>& out, ShaderBuildStats& stats);

// A cache file name for a program label and stage: letters, digits, '.', '_' and '-' only, bounded, unique per label.
// `variant` (a few hex characters of the hash of the whole cache key: engine version, flags, source) is appended, so two
// engine versions, or two games with a material of the same path, keep separate files instead of replacing each other's
// entry on every start. The folder grows by one small file per shader per version; deleting it is always safe.
std::string shader_cache_file_name(std::string_view label, std::string_view stage, std::string_view variant = {});

// Device::make_shader through the cache layer. `label` names the program in the cache file and logs (desc.label when
// null or empty).
gpu::Shader make_shader(gpu::Device& device, const gpu::ShaderDesc& desc, const char* label = nullptr);
// The cache layer itself, for a caller that makes the program some other way: `make` is called
// once, with the desc to make (`prepared`: the stages compiled to bytecode on D3D11 and D3D12, decoded SPIR-V on Vulkan) or nullptr for `desc` itself
// (another backend, or a stage the engine could not compile: the backend compiles it and reports why).
gpu::Shader make_shader_via(gpu::Backend backend, const gpu::ShaderDesc& desc, const char* label,
                            const std::function<gpu::Shader(const gpu::ShaderDesc* prepared)>& make);

// The counters are PROCESS-WIDE: every renderer in the process (the editor has several) adds to them and no renderer resets
// them; a report is "since the process started". reset_shader_build_stats is for tests.
const ShaderBuildStats& shader_build_stats();
void reset_shader_build_stats();
// The cache of a device of `backend`: "d3d11-dxbc" or "d3d12-dxbc" (shader model 5.1 stages) where the engine caches,
// "none" on the other backends, on builds where the engine does not compile stages, or when there is no cache folder.
const char* shader_cache_mode(gpu::Backend backend);

}  // namespace fa::render
