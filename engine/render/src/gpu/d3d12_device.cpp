// make_d3d12_device() where Direct3D 12 does not exist: a teaching error. The Windows factory is in
// d3d12_device_win32.cpp (docs/design/ARCHITECTURE_RENDERING_GPU.md, "D3D12 backend"). The pipeline cache's file name
// and process totals are here, on every platform (the shader cache's report reads them).
#include "gpu/d3d12_device.h"

#include <atomic>

#include "fa/core/fs.h"

namespace fa::gpu {

namespace {

std::atomic<std::uint64_t> g_libraryHits{0}, g_libraryMisses{0}, g_filesLoaded{0}, g_filesStored{0},
    g_filesDiscarded{0}, g_storeFailed{0};

}  // namespace

std::filesystem::path d3d12_pipeline_cache_file() {
    const std::filesystem::path dir = fs::cache_dir();
    if (dir.empty()) return {};
    return dir / "shaders" / "d3d12-pipelines.bin";
}

D3d12PipelineCacheTotals d3d12_pipeline_cache_totals() {
    D3d12PipelineCacheTotals t;
    t.libraryHits = g_libraryHits.load(std::memory_order_relaxed);
    t.libraryMisses = g_libraryMisses.load(std::memory_order_relaxed);
    t.filesLoaded = g_filesLoaded.load(std::memory_order_relaxed);
    t.filesStored = g_filesStored.load(std::memory_order_relaxed);
    t.filesDiscarded = g_filesDiscarded.load(std::memory_order_relaxed);
    t.storeFailed = g_storeFailed.load(std::memory_order_relaxed);
    return t;
}

void d3d12_pipeline_cache_count(const D3d12PipelineCacheTotals& add) {
    g_libraryHits.fetch_add(add.libraryHits, std::memory_order_relaxed);
    g_libraryMisses.fetch_add(add.libraryMisses, std::memory_order_relaxed);
    g_filesLoaded.fetch_add(add.filesLoaded, std::memory_order_relaxed);
    g_filesStored.fetch_add(add.filesStored, std::memory_order_relaxed);
    g_filesDiscarded.fetch_add(add.filesDiscarded, std::memory_order_relaxed);
    g_storeFailed.fetch_add(add.storeFailed, std::memory_order_relaxed);
}

}  // namespace fa::gpu

#if !defined(_WIN32)

#include <string>

namespace fa::gpu {

Result<std::unique_ptr<Device>> make_d3d12_device(const D3d12Options&) {
    return make_error(std::string("gpu: the d3d12 backend runs on Windows only (this binary was built for another "
                                  "platform, whose sokol backend is ") +
                          backend_name(built_sokol_backend()) + ")",
                      "use make_device(built_sokol_backend()) here; Direct3D 12 exists only on Windows 10 and later");
}

}  // namespace fa::gpu

#endif
