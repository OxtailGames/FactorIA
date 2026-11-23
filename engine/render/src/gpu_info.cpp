// The GPU the renderer is on (fa/render/gpu_info.h): the adapter's name, vendor and memory from the graphics API.
#include "fa/render/gpu_info.h"

#include <algorithm>
#include <cctype>
#include <cstring>

#include "render_internal.h"

#if defined(SOKOL_D3D11)
#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <d3d11.h>
#include <dxgi.h>
#elif defined(SOKOL_GLCORE) || defined(SOKOL_GLES3)
#if defined(SOKOL_GLES3)
#include <GLES3/gl3.h>
#else
#define GL_GLEXT_PROTOTYPES 1
#include <GL/gl.h>
#include <GL/glext.h>
#endif
#endif

#if defined(SOKOL_METAL)
namespace fa::render {
bool gpu_info_metal(GpuInfo& info);  // gpu_info_metal.mm
}
#endif

namespace fa::render {

namespace {

std::string lower(std::string_view s) {
    std::string out(s);
    std::transform(out.begin(), out.end(), out.begin(), [](unsigned char c) { return char(std::tolower(c)); });
    return out;
}
bool has(const std::string& hay, const char* needle) { return hay.find(needle) != std::string::npos; }

}  // namespace

void classify_gpu(GpuInfo& info, std::string_view vendorString) {
    const std::string n = lower(info.name), v = lower(vendorString);
    const std::string all = n + " | " + v;
    info.software = has(all, "llvmpipe") || has(all, "softpipe") || has(all, "swrast") || has(all, "swiftshader") ||
                    has(all, "software rasterizer") || has(all, "microsoft basic render") || has(all, "warp");
    if (info.software) {
        info.vendor = has(all, "microsoft") ? "microsoft" : "mesa";
        if (has(all, "swiftshader")) info.vendor = "other";
        return;
    }
    if (has(all, "nvidia") || has(all, "geforce") || has(all, "quadro") || has(all, "rtx ") || has(all, "tegra"))
        info.vendor = "nvidia";
    else if (has(all, "apple"))
        info.vendor = "apple";
    else if (has(all, "amd") || has(all, "radeon") || has(all, "ati ") || has(all, "advanced micro"))
        info.vendor = "amd";
    else if (has(all, "intel"))
        info.vendor = "intel";
    else if (has(all, "adreno") || has(all, "qualcomm"))
        info.vendor = "qualcomm";
    else if (has(all, "mali") || has(all, "arm"))
        info.vendor = "arm";
    else if (has(all, "microsoft"))
        info.vendor = "microsoft";
    else if (has(all, "mesa"))
        info.vendor = "mesa";
    else
        info.vendor = info.name.empty() && vendorString.empty() ? "" : "other";
}

Json GpuInfo::to_json() const {
    Json j = Json::object();
    j["backend"] = backend;
    j["name"] = name;
    j["vendor"] = vendor;
    j["driver"] = driver;
    j["memoryMB"] = memoryMB;
    j["unifiedMemory"] = unifiedMemory;
    j["software"] = software;
    return j;
}

#if defined(SOKOL_D3D11)
namespace {
std::string wide_to_utf8(const wchar_t* w) {
    const int n = WideCharToMultiByte(CP_UTF8, 0, w, -1, nullptr, 0, nullptr, nullptr);
    if (n <= 1) return {};
    std::string s(std::size_t(n), '\0');
    WideCharToMultiByte(CP_UTF8, 0, w, -1, s.data(), n, nullptr, nullptr);
    s.resize(std::size_t(n - 1));
    return s;
}
}  // namespace
#endif

GpuInfo query_gpu_info() {
    GpuInfo info;
    if (!sg_isvalid()) return info;  // no graphics device: backend "none"
    info.backend = Renderer::backend_name();
#if defined(SOKOL_D3D11)
    if (ID3D11Device* dev = static_cast<ID3D11Device*>(const_cast<void*>(sg_d3d11_device()))) {
        IDXGIDevice* dxgiDevice = nullptr;
        if (SUCCEEDED(dev->QueryInterface(__uuidof(IDXGIDevice), reinterpret_cast<void**>(&dxgiDevice))) && dxgiDevice) {
            IDXGIAdapter* adapter = nullptr;
            if (SUCCEEDED(dxgiDevice->GetAdapter(&adapter)) && adapter) {
                DXGI_ADAPTER_DESC desc{};
                if (SUCCEEDED(adapter->GetDesc(&desc))) {
                    info.name = wide_to_utf8(desc.Description);
                    // Integrated GPUs report little dedicated memory and a lot of shared system memory.
                    const std::uint64_t dedicated = std::uint64_t(desc.DedicatedVideoMemory);
                    info.memoryMB = std::int64_t(std::min<std::uint64_t>(dedicated / (1024 * 1024), 1u << 30));
                    if (info.memoryMB < 512) {
                        const std::uint64_t shared = std::uint64_t(desc.SharedSystemMemory);
                        info.memoryMB = std::int64_t(std::min<std::uint64_t>(shared / (1024 * 1024) / 2, 1u << 30));
                        info.unifiedMemory = true;
                    }
                }
                adapter->Release();
            }
            dxgiDevice->Release();
        }
    }
    classify_gpu(info);
#elif defined(SOKOL_GLCORE) || defined(SOKOL_GLES3)
    const auto str = [](GLenum e) {
        const GLubyte* s = glGetString(e);
        return s ? std::string(reinterpret_cast<const char*>(s)) : std::string();
    };
    info.name = str(GL_RENDERER);
    info.driver = str(GL_VERSION);
    const std::string vendorString = str(GL_VENDOR);
#if defined(SOKOL_GLCORE)
    // Video memory: the two vendor extensions that report it. GL_GPU_MEMORY_INFO_DEDICATED_VIDMEM_NVX is in KB, GL_TEXTURE_FREE_MEMORY_ATI
    // (its first number) is the free texture memory in KB, the best an AMD driver on GL says.
    GLint count = 0;
    glGetIntegerv(GL_NUM_EXTENSIONS, &count);
    bool nvx = false, ati = false;
    for (GLint i = 0; i < count && i < 4096; ++i) {
        const GLubyte* e = glGetStringi(GL_EXTENSIONS, GLuint(i));
        if (!e) continue;
        const char* s = reinterpret_cast<const char*>(e);
        nvx = nvx || std::strcmp(s, "GL_NVX_gpu_memory_info") == 0;
        ati = ati || std::strcmp(s, "GL_ATI_meminfo") == 0;
    }
    GLint kb = 0;
    if (nvx) {
        glGetIntegerv(0x9047 /* GL_GPU_MEMORY_INFO_DEDICATED_VIDMEM_NVX */, &kb);
        info.memoryMB = kb / 1024;
    } else if (ati) {
        GLint v[4] = {0, 0, 0, 0};
        glGetIntegerv(0x87FC /* GL_TEXTURE_FREE_MEMORY_ATI */, v);
        info.memoryMB = v[0] / 1024;
    }
    while (glGetError() != GL_NO_ERROR) {
    }  // an extension query must leave no error for the frame that follows
#endif
    classify_gpu(info, vendorString);
    sg_reset_state_cache();
#elif defined(SOKOL_METAL)
    if (gpu_info_metal(info)) classify_gpu(info);
#endif
    return info;
}

}  // namespace fa::render
