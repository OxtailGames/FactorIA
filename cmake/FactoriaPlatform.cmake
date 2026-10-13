# Detects the target platform and picks the sokol graphics backend.
#   FA_PLATFORM      windows | macos | ios | android | linux | web
#   FA_DESKTOP       ON for windows/macos/linux
#   FA_SOKOL_BACKEND SOKOL_D3D11 | SOKOL_METAL | SOKOL_GLCORE | SOKOL_GLES3 | SOKOL_WGPU
# Override the backend with -DFA_GFX_BACKEND=GLCORE (etc.) for debugging.

if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
    set(FA_PLATFORM ios)
elseif(APPLE)
    set(FA_PLATFORM macos)
elseif(ANDROID)
    set(FA_PLATFORM android)
elseif(WIN32)
    set(FA_PLATFORM windows)
elseif(EMSCRIPTEN)
    set(FA_PLATFORM web)
else()
    set(FA_PLATFORM linux)
endif()

if(FA_PLATFORM STREQUAL "windows" OR FA_PLATFORM STREQUAL "macos" OR FA_PLATFORM STREQUAL "linux")
    set(FA_DESKTOP ON)
else()
    set(FA_DESKTOP OFF)
endif()

if(DEFINED FA_GFX_BACKEND)
    set(FA_SOKOL_BACKEND SOKOL_${FA_GFX_BACKEND})
elseif(FA_PLATFORM STREQUAL "windows")
    set(FA_SOKOL_BACKEND SOKOL_D3D11)
elseif(FA_PLATFORM STREQUAL "macos" OR FA_PLATFORM STREQUAL "ios")
    set(FA_SOKOL_BACKEND SOKOL_METAL)
elseif(FA_PLATFORM STREQUAL "android" OR FA_PLATFORM STREQUAL "web")
    set(FA_SOKOL_BACKEND SOKOL_GLES3)
else()
    set(FA_SOKOL_BACKEND SOKOL_GLCORE)
endif()

message(STATUS "FactorIA: platform=${FA_PLATFORM} gfx=${FA_SOKOL_BACKEND} desktop=${FA_DESKTOP}")
