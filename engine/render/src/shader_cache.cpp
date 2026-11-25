#include "shader_cache.h"

#include <chrono>
#include <cmath>
#include <cstring>
#include <string>
#include <string_view>
#include <utility>

#include "fa/core/engine_version.h"
#include "fa/core/fs.h"
#include "fa/core/hash.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "gpu/d3d12_device.h"
#include "gpu/device.h"

#if defined(SOKOL_D3D11)
#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <d3dcompiler.h>  // the D3DCOMPILE_* flag values only: D3DCompile itself is loaded below
#endif

namespace stdfs = std::filesystem;

namespace fa::render {

namespace {

ShaderBuildStats g_stats;
// Whether the engine compiles and caches the shader stages itself: on the Windows build (D3D11 and D3D12 both take
// bytecode from it),
// answered by the build, not by the last program made, so a report before the first shader is right too.
bool engine_caches_here() {
#if defined(SOKOL_D3D11)
    return true;
#else
    return false;
#endif
}

#if defined(SOKOL_D3D11)
// D3DCompile is loaded from d3dcompiler_47.dll (no import library, no header of the compiler needed).
using PD3DCompile = HRESULT(WINAPI*)(LPCVOID, SIZE_T, LPCSTR, const D3D_SHADER_MACRO*, ID3DInclude*, LPCSTR, LPCSTR,
                                     UINT, UINT, ID3DBlob**, ID3DBlob**);
// The flags the engine compiles with: the ones sokol_gfx uses for D3D11 when shader_debugging is off, plus
// PREFER_FLOW_CONTROL: without
// it d3dcompiler_47 flattens the branches of the 3D lighting into one straight line and, on some programs (a custom material
// whose lighting() walks the lights and then reads the shadow of one), recurses until its stack overflows and the process
// dies (fxc /O3 crashes the same way; /Gfp is this flag). The cache key names them.
constexpr UINT kCompileFlags =
    D3DCOMPILE_PACK_MATRIX_COLUMN_MAJOR | D3DCOMPILE_OPTIMIZATION_LEVEL3 | D3DCOMPILE_PREFER_FLOW_CONTROL;
constexpr const char* kCompileFlagsText = "column_major+O3+flow";

bool d3d_compile_stage(const gpu::ShaderFunction& fn, std::vector<std::uint8_t>& out, std::string& error) {
    static HMODULE dll = LoadLibraryA("d3dcompiler_47.dll");
    static PD3DCompile compile =
        dll ? reinterpret_cast<PD3DCompile>(reinterpret_cast<void*>(GetProcAddress(dll, "D3DCompile"))) : nullptr;
    if (!compile) {
        error = "d3dcompiler_47.dll could not be loaded";
        return false;
    }
    ID3DBlob* code = nullptr;
    ID3DBlob* messages = nullptr;
    const HRESULT hr = compile(fn.source, strlen(fn.source), fn.d3d11Filepath, nullptr, nullptr,
                               fn.entry ? fn.entry : "main", fn.d3d11Target, kCompileFlags, 0, &code, &messages);
    if (messages)
        messages
            ->Release();  // warnings: the device shows them when it compiles; here a failure falls back to the device, which reports it
    if (FAILED(hr) || !code) {
        if (code) code->Release();
        error = "D3DCompile failed";
        return false;
    }
    const auto* p = static_cast<const std::uint8_t*>(code->GetBufferPointer());
    out.assign(p, p + code->GetBufferSize());
    code->Release();
    return !out.empty();
}
#endif

// Vulkan: a stage given as text is SPIR-V in base64 (a custom material's spirv_vk twin); it becomes the bytecode the
// device takes. False when a stage is not base64 of a whole number of 32-bit words: the backend then gets the desc as
// it is and reports the stage.
bool decode_spirv_stages(gpu::ShaderDesc& copy, std::vector<std::uint8_t> (&bytes)[3]) {
    gpu::ShaderFunction* const fns[3] = {&copy.vertexFunc, &copy.fragmentFunc, &copy.computeFunc};
    for (int i = 0; i < 3; ++i) {
        gpu::ShaderFunction& fn = *fns[i];
        if (fn.bytecode.ptr || !fn.source) continue;  // given as bytecode already, or no such stage
        // base64_decode skips what is outside the alphabet, so text (GLSL given where the SPIR-V twin belongs) would
        // decode to garbage: such a stage is rejected here.
        const std::string_view text(fn.source);
        const bool alphabet =
            text.find_first_not_of("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/-_= \t\r\n") ==
            std::string_view::npos;
        const std::vector<unsigned char> decoded = alphabet ? base64_decode(text) : std::vector<unsigned char>();
        if (decoded.empty() || decoded.size() % 4 != 0) {
            log(LogLevel::Error, "render",
                std::string("Vulkan shader stage ") +
                    (i == 0   ? "vertex"
                     : i == 1 ? "fragment"
                              : "compute") +
                    " is not base64 SPIR-V: the shader has no spirv_vk twin (it was given GLSL or other text). "
                    "Regenerate the header with tools/shaders/compile_shaders.sh (a custom material needs its "
                    "spirv_vk source).");
            return false;
        }
        bytes[i].assign(decoded.begin(), decoded.end());
        fn.bytecode = {bytes[i].data(), bytes[i].size()};
        fn.source = nullptr;
    }
    return true;
}

}  // namespace

Json ShaderBuildStats::to_json(const char* backend) const {
    Json j = Json::object();
    j["backend"] = backend;
    // The backend of that name (the build's sokol one when the name is none of the engine's).
    gpu::Backend named = gpu::built_sokol_backend();
    for (int b = 0; b <= int(gpu::Backend::Recording); ++b)
        if (std::string_view(gpu::backend_name(gpu::Backend(b))) == (backend ? backend : "")) named = gpu::Backend(b);
    j["cache"] = shader_cache_mode(named);
    j["programs"] = programs;
    j["createMs"] = std::round(createMs * 10.0) / 10.0;
    if (stages > 0 || engine_caches_here()) {
        j["stages"] = stages;
        j["cacheHits"] = cacheHits;
        j["cacheMisses"] = cacheMisses;
        j["cacheStale"] = cacheStale;
        j["cacheDamaged"] = cacheDamaged;
        j["cacheStored"] = cacheStored;
        j["cacheStoreFailed"] = cacheStoreFailed;
    }
    if (named == gpu::Backend::D3d12) {
        // The D3D12 devices' on-disk PSO cache (an ID3D12PipelineLibrary per device, gpu/d3d12_pipelines_win32.cpp).
        const gpu::D3d12PipelineCacheTotals t = gpu::d3d12_pipeline_cache_totals();
        Json p = Json::object();
        const stdfs::path file = gpu::d3d12_pipeline_cache_file();
        p["file"] = file.empty() ? std::string() : fs::path_to_utf8(file);
        p["hits"] = t.libraryHits;
        p["misses"] = t.libraryMisses;
        p["filesLoaded"] = t.filesLoaded;
        p["stored"] = t.filesStored;
        p["discarded"] = t.filesDiscarded;
        p["storeFailed"] = t.storeFailed;
        p["trimmed"] = t.filesTrimmed;
        j["pipelineCache"] = std::move(p);
    }
    return j;
}

std::string shader_cache_file_name(std::string_view label, std::string_view stage, std::string_view variant) {
    std::string safe;
    for (char c : label) {
        const bool ok =
            (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '.' || c == '-';
        safe += ok ? c : '_';
        if (safe.size() >= 60) break;
    }
    // Two labels that differ only in characters mapped to '_' (or past the limit) must not share a file.
    const std::string hash = sha256_hex(label).substr(0, 8);
    std::string name = "shader-" + safe + "-" + hash + "-" + std::string(stage);
    if (!variant.empty()) name += "-" + std::string(variant.substr(0, 8));
    return name;
}

bool cached_stage_bytecode(const stdfs::path& cacheDir, std::string_view keyBase, std::string_view label,
                           std::string_view stage, const gpu::ShaderFunction& fn, const StageCompiler& compile,
                           std::vector<std::uint8_t>& out, ShaderBuildStats& stats) {
    ++stats.stages;
    Sha256 h;
    h.update(fn.source ? std::string_view(fn.source) : std::string_view());
    h.update(std::string_view("\0", 1));
    h.update(fn.entry ? std::string_view(fn.entry) : std::string_view());
    h.update(std::string_view("\0", 1));
    h.update(fn.d3d11Target ? std::string_view(fn.d3d11Target) : std::string_view());
    const std::string key = std::string(keyBase) + "|src:" + h.finish_hex();
    const BlobCache cache(cacheDir, key);
    const std::string name = shader_cache_file_name(label, stage, sha256_hex(key));
    const BlobCache::Status status = cache.load(name, out);
    if (status == BlobCache::Status::Hit) {
        ++stats.cacheHits;
        return true;
    }
    if (status == BlobCache::Status::Stale)
        ++stats.cacheStale;
    else if (status == BlobCache::Status::Damaged)
        ++stats.cacheDamaged;
    else
        ++stats.cacheMisses;
    std::string error;
    if (!compile(fn, out, error)) {
        out.clear();
        return false;
    }
    if (cache.enabled()) {
        if (auto stored = cache.store(name, out); stored.ok()) {
            ++stats.cacheStored;
        } else {
            ++stats.cacheStoreFailed;
            FA_WARN("cache", "{}", stored.error().to_string());
        }
    }
    return true;
}

gpu::Shader make_shader_via(gpu::Backend backend, const gpu::ShaderDesc& desc, const char* label,
                            const std::function<gpu::Shader(const gpu::ShaderDesc* prepared)>& make) {
    const auto start = std::chrono::steady_clock::now();
    gpu::Shader shader{};
#if defined(SOKOL_D3D11)
    // D3D11 and D3D12: the engine compiles every stage with its own flags (kCompileFlags), through the disk cache when
    // there is a cache folder and directly when there is none; the backend compiles a stage only when this fails, and
    // reports why. D3D12 compiles to shader model 5.1 (register spaces), so its stages have targets of their own and
    // keys of their own.
    const bool d3d12 = backend == gpu::Backend::D3d12;
    if (backend == gpu::Backend::D3d11 || d3d12) {
        const bool cached = !fs::cache_dir().empty();
        const std::string name = label && *label ? label : desc.label && *desc.label ? desc.label : "shader";
        const std::string keyBase =
            std::string(d3d12 ? "d3d12|" : "d3d11|") + FA_ENGINE_VERSION + "|" + kCompileFlagsText;
        gpu::ShaderDesc copy = desc;
        if (d3d12) {
            copy.vertexFunc.d3d11Target = "vs_5_1";
            copy.fragmentFunc.d3d11Target = "ps_5_1";
            copy.computeFunc.d3d11Target = "cs_5_1";
        }
        std::vector<std::uint8_t> vs, fsb, csb;
        bool viaCache = true;
        struct Stage {
            gpu::ShaderFunction* fn;
            std::vector<std::uint8_t>* bytes;
            const char* name;
        };
        // the D3D11 device compiles compute itself: only D3D12 takes a compute stage from here.
        const Stage stages[] = {{&copy.vertexFunc, &vs, "vs"},
                                {&copy.fragmentFunc, &fsb, "fs"},
                                {d3d12 ? &copy.computeFunc : nullptr, &csb, "cs"}};
        for (const Stage& st : stages) {
            if (!st.fn || st.fn->bytecode.ptr || !st.fn->source)
                continue;  // given as bytecode already, or no such stage
            std::string error;
            const bool made = cached ? cached_stage_bytecode(fs::cache_dir() / "shaders", keyBase, name, st.name,
                                                             *st.fn, d3d_compile_stage, *st.bytes, g_stats)
                                     : d3d_compile_stage(*st.fn, *st.bytes, error);
            if (!made) {
                viaCache = false;  // the backend compiles it and reports what is wrong
                break;
            }
            st.fn->bytecode = {st.bytes->data(), st.bytes->size()};
            st.fn->source = nullptr;
        }
        shader = make(viaCache ? &copy : nullptr);  // copy's bytes (vs, fsb) outlive this call
    } else if (backend == gpu::Backend::Vulkan) {
        gpu::ShaderDesc copy = desc;
        std::vector<std::uint8_t> bytes[3];
        shader = make(decode_spirv_stages(copy, bytes) ? &copy : nullptr);  // bytes outlive this call
    } else {
        shader = make(nullptr);
    }
#else
    (void)label;
    if (backend == gpu::Backend::Vulkan) {
        gpu::ShaderDesc copy = desc;
        std::vector<std::uint8_t> bytes[3];
        shader = make(decode_spirv_stages(copy, bytes) ? &copy : nullptr);  // bytes outlive this call
    } else {
        shader = make(nullptr);
    }
#endif
    ++g_stats.programs;
    g_stats.createMs += std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - start).count();
    return shader;
}

gpu::Shader make_shader(gpu::Device& device, const gpu::ShaderDesc& desc, const char* label) {
    return make_shader_via(device.backend(), desc, label, [&](const gpu::ShaderDesc* prepared) {
        return device.make_shader(prepared ? *prepared : desc);
    });
}

const ShaderBuildStats& shader_build_stats() { return g_stats; }
void reset_shader_build_stats() { g_stats = ShaderBuildStats{}; }

const char* shader_cache_mode(gpu::Backend backend) {
    if (!engine_caches_here() || fs::cache_dir().empty()) return "none";
    if (backend == gpu::Backend::D3d12) return "d3d12-dxbc";
    return backend == gpu::Backend::D3d11 ? "d3d11-dxbc" : "none";
}

}  // namespace fa::render
