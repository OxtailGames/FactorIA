#include "shader_cache.h"

#include <chrono>
#include <cmath>
#include <cstring>

#include "fa/core/engine_version.h"
#include "fa/core/fs.h"
#include "fa/core/hash.h"
#include "fa/core/log.h"

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

bool engine_caches_here() {
#if defined(SOKOL_D3D11)
    return sg_query_backend() == SG_BACKEND_D3D11;
#else
    return false;
#endif
}

#if defined(SOKOL_D3D11)
// D3DCompile is loaded from d3dcompiler_47.dll like sokol does (no import library, no header of the compiler needed).
using PD3DCompile = HRESULT(WINAPI*)(LPCVOID, SIZE_T, LPCSTR, const D3D_SHADER_MACRO*, ID3DInclude*, LPCSTR, LPCSTR, UINT, UINT,
                                     ID3DBlob**, ID3DBlob**);
constexpr UINT kCompileFlags = D3DCOMPILE_PACK_MATRIX_COLUMN_MAJOR | D3DCOMPILE_OPTIMIZATION_LEVEL3;
// The flags sokol_gfx uses when shader_debugging is off (sokol_gfx.h, _sg_d3d11_compile_shader). The cache key names them.
constexpr const char* kCompileFlagsText = "column_major+O3";

bool d3d_compile_stage(const sg_shader_function& fn, std::vector<std::uint8_t>& out, std::string& error) {
    static HMODULE dll = LoadLibraryA("d3dcompiler_47.dll");
    static PD3DCompile compile = dll ? reinterpret_cast<PD3DCompile>(reinterpret_cast<void*>(GetProcAddress(dll, "D3DCompile"))) : nullptr;
    if (!compile) {
        error = "d3dcompiler_47.dll could not be loaded";
        return false;
    }
    ID3DBlob* code = nullptr;
    ID3DBlob* messages = nullptr;
    const HRESULT hr = compile(fn.source, strlen(fn.source), fn.d3d11_filepath, nullptr, nullptr, fn.entry ? fn.entry : "main",
                               fn.d3d11_target, kCompileFlags, 0, &code, &messages);
    if (messages) messages->Release();  // warnings: sokol shows them when it compiles; here a failure falls back to sokol, which reports it
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

}  // namespace

Json ShaderBuildStats::to_json(const char* backend) const {
    Json j = Json::object();
    j["backend"] = backend;
    j["cache"] = shader_cache_mode();
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
    return j;
}

std::string shader_cache_file_name(std::string_view label, std::string_view stage, std::string_view variant) {
    std::string safe;
    for (char c : label) {
        const bool ok = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '.' || c == '-';
        safe += ok ? c : '_';
        if (safe.size() >= 60) break;
    }
    // Two labels that differ only in characters mapped to '_' (or past the limit) must not share a file.
    const std::string hash = sha256_hex(label).substr(0, 8);
    std::string name = "shader-" + safe + "-" + hash + "-" + std::string(stage);
    if (!variant.empty()) name += "-" + std::string(variant.substr(0, 8));
    return name;
}

bool cached_stage_bytecode(const stdfs::path& cacheDir, std::string_view keyBase, std::string_view label, std::string_view stage,
                           const sg_shader_function& fn, const StageCompiler& compile, std::vector<std::uint8_t>& out,
                           ShaderBuildStats& stats) {
    ++stats.stages;
    Sha256 h;
    h.update(fn.source ? std::string_view(fn.source) : std::string_view());
    h.update(std::string_view("\0", 1));
    h.update(fn.entry ? std::string_view(fn.entry) : std::string_view());
    h.update(std::string_view("\0", 1));
    h.update(fn.d3d11_target ? std::string_view(fn.d3d11_target) : std::string_view());
    const std::string key = std::string(keyBase) + "|src:" + h.finish_hex();
    const BlobCache cache(cacheDir, key);
    const std::string name = shader_cache_file_name(label, stage, sha256_hex(key));
    const BlobCache::Status status = cache.load(name, out);
    if (status == BlobCache::Status::Hit) {
        ++stats.cacheHits;
        return true;
    }
    if (status == BlobCache::Status::Stale) ++stats.cacheStale;
    else if (status == BlobCache::Status::Damaged) ++stats.cacheDamaged;
    else ++stats.cacheMisses;
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

sg_shader make_shader(const sg_shader_desc* desc, const char* label) {
    const auto start = std::chrono::steady_clock::now();
    sg_shader shader{};
#if defined(SOKOL_D3D11)
    if (engine_caches_here() && !fs::cache_dir().empty() && desc) {
        const std::string name = label ? label : desc->label ? desc->label : "shader";
        const std::string keyBase = std::string("d3d11|") + FA_ENGINE_VERSION + "|" + kCompileFlagsText;
        sg_shader_desc copy = *desc;
        std::vector<std::uint8_t> vs, fsb;
        bool viaCache = true;
        struct Stage {
            sg_shader_function* fn;
            std::vector<std::uint8_t>* bytes;
            const char* name;
        };
        const Stage stages[] = {{&copy.vertex_func, &vs, "vs"}, {&copy.fragment_func, &fsb, "fs"}};
        for (const Stage& st : stages) {
            if (st.fn->bytecode.ptr || !st.fn->source) continue;  // given as bytecode already, or no such stage
            if (!cached_stage_bytecode(fs::cache_dir() / "shaders", keyBase, name, st.name, *st.fn, d3d_compile_stage, *st.bytes, g_stats)) {
                viaCache = false;  // sokol compiles it and reports what is wrong
                break;
            }
            st.fn->bytecode = {st.bytes->data(), st.bytes->size()};
            st.fn->source = nullptr;
        }
        shader = sg_make_shader(viaCache ? &copy : desc);  // copy's bytes (vs, fsb) outlive this call
    } else {
        shader = sg_make_shader(desc);
    }
#else
    (void)label;
    shader = sg_make_shader(desc);
#endif
    ++g_stats.programs;
    g_stats.createMs += std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - start).count();
    return shader;
}

const ShaderBuildStats& shader_build_stats() { return g_stats; }
void reset_shader_build_stats() { g_stats = ShaderBuildStats{}; }

const char* shader_cache_mode() {
    return engine_caches_here() && !fs::cache_dir().empty() ? "d3d11-dxbc" : "none";
}

}  // namespace fa::render
