// What the D3D12 WARP adapter of this Windows machine can trace (M79, .github/workflows/ci.yml, "D3D12 ray tracing probe").
// Ray tracing in the engine is inline ray query only (DXR 1.1 in compute kernels, DXIL shader model 6.5): the OS WARP of an
// old runner image may predate it, which is why the CI job can add the Microsoft.Direct3D.WARP NuGet package's d3d10warp.dll
// next to this executable (D3D12 loads a WARP library that sits beside the process before the system one). Prints one
// `key=value` per line and always exits 0 when the adapter could be created:
//
//   adapter=<description>  tier=<D3D12_RAYTRACING_TIER: 0 none, 10 DXR 1.0, 11 DXR 1.1, 12 DXR 1.2>
//   shaderModel=<highest shader model, hex: 65 = 6.5>  warpDll=<the d3d10warp.dll loaded>  warpVersion=<its file version>
//
// Build (an MSVC prompt): cl /nologo /EHsc /O1 d3d12_rt_probe.cpp /link d3d12.lib dxgi.lib
#include <windows.h>

#include <d3d12.h>
#include <dxgi1_4.h>

#include <cstddef>
#include <cstdio>
#include <string>

#pragma comment(lib, "d3d12.lib")
#pragma comment(lib, "dxgi.lib")
#pragma comment(lib, "version.lib")

namespace {

std::string narrow(const wchar_t* w) {
    const int n = WideCharToMultiByte(CP_UTF8, 0, w, -1, nullptr, 0, nullptr, nullptr);
    std::string s(n > 0 ? std::size_t(n - 1) : 0, '\0');
    if (n > 1) WideCharToMultiByte(CP_UTF8, 0, w, -1, &s[0], n, nullptr, nullptr);
    return s;
}

std::string file_version(const std::wstring& path) {
    DWORD ignored = 0;
    const DWORD size = GetFileVersionInfoSizeW(path.c_str(), &ignored);
    if (!size) return "unknown";
    std::string data(size, '\0');
    if (!GetFileVersionInfoW(path.c_str(), 0, size, &data[0])) return "unknown";
    VS_FIXEDFILEINFO* info = nullptr;
    UINT len = 0;
    if (!VerQueryValueW(&data[0], L"\\", reinterpret_cast<void**>(&info), &len) || !info) return "unknown";
    char buf[64];
    std::snprintf(buf, sizeof buf, "%u.%u.%u.%u", HIWORD(info->dwFileVersionMS), LOWORD(info->dwFileVersionMS),
                  HIWORD(info->dwFileVersionLS), LOWORD(info->dwFileVersionLS));
    return buf;
}

}  // namespace

int main() {
    IDXGIFactory4* factory = nullptr;
    if (FAILED(CreateDXGIFactory1(IID_PPV_ARGS(&factory)))) {
        std::printf("error=CreateDXGIFactory1 failed\n");
        return 1;
    }
    IDXGIAdapter* warp = nullptr;
    if (FAILED(factory->EnumWarpAdapter(IID_PPV_ARGS(&warp)))) {
        std::printf("error=no WARP adapter\n");
        return 1;
    }
    DXGI_ADAPTER_DESC desc{};
    warp->GetDesc(&desc);
    std::printf("adapter=%s\n", narrow(desc.Description).c_str());
    ID3D12Device* device = nullptr;
    if (FAILED(D3D12CreateDevice(warp, D3D_FEATURE_LEVEL_11_0, IID_PPV_ARGS(&device)))) {
        std::printf("error=D3D12CreateDevice failed on WARP\n");
        return 1;
    }
    D3D12_FEATURE_DATA_D3D12_OPTIONS5 o5{};
    int tier = 0;
    if (SUCCEEDED(device->CheckFeatureSupport(D3D12_FEATURE_D3D12_OPTIONS5, &o5, sizeof o5)))
        tier = int(o5.RaytracingTier);
    std::printf("tier=%d\n", tier);
    // The highest shader model: ask from the newest known value down (an older runtime answers E_INVALIDARG for a newer one).
    int sm = 0;
    for (int candidate : {0x6A, 0x69, 0x68, 0x67, 0x66, 0x65, 0x64, 0x63, 0x62, 0x61, 0x60}) {
        D3D12_FEATURE_DATA_SHADER_MODEL model{D3D_SHADER_MODEL(candidate)};
        if (SUCCEEDED(device->CheckFeatureSupport(D3D12_FEATURE_SHADER_MODEL, &model, sizeof model))) {
            sm = int(model.HighestShaderModel);
            break;
        }
    }
    std::printf("shaderModel=%x\n", sm);
    if (HMODULE m = GetModuleHandleW(L"d3d10warp.dll")) {
        wchar_t path[MAX_PATH]{};
        GetModuleFileNameW(m, path, MAX_PATH);
        std::printf("warpDll=%s\nwarpVersion=%s\n", narrow(path).c_str(), file_version(path).c_str());
    } else {
        std::printf("warpDll=not loaded\nwarpVersion=unknown\n");
    }
    device->Release();
    warp->Release();
    factory->Release();
    return 0;
}
