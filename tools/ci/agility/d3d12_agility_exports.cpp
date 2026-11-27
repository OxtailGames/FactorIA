// What makes D3D12 run a program on the Agility SDK runtime instead of the system's (M79, engine/render/CMakeLists.txt, the
// ctest render_d3d12_raytracing): the program exports the SDK version and the folder, relative to the program and with the
// trailing backslash, of the D3D12Core.dll of that version. D3D12 then loads D3D12\D3D12Core.dll (and D3D12\d3d12SDKLayers.dll
// for the debug layer) beside the program, and fails device creation when the folder or the version is not there: no
// fallback to the system's runtime. Only fa_test_render_d3d12_rt has these exports; FA_D3D12_AGILITY_SDK_VERSION comes from
// CMake (the middle number of the package version: Microsoft.Direct3D.D3D12 1.620.2 is 620).
#if defined(_WIN32)
#include <windows.h>

#ifndef FA_D3D12_AGILITY_SDK_VERSION
#error "FA_D3D12_AGILITY_SDK_VERSION is set by CMake (-DFA_D3D12_AGILITY_SDK_VERSION=620)"
#endif

extern "C" {
__declspec(dllexport) extern const UINT D3D12SDKVersion = FA_D3D12_AGILITY_SDK_VERSION;
__declspec(dllexport) extern const char* D3D12SDKPath = ".\\D3D12\\";
}
#endif
