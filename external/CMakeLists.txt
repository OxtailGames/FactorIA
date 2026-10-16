# Third-party dependencies, vendored verbatim (see external/VERSIONS.md).
# Every target here is prefixed `fa_ext_` and compiled with warnings silenced.

set(FA_EXT ${CMAKE_CURRENT_SOURCE_DIR})

# ---- header-only -----------------------------------------------------------
add_library(fa_ext_json INTERFACE)
target_include_directories(fa_ext_json SYSTEM INTERFACE ${FA_EXT}/nlohmann_json)

add_library(fa_ext_stb INTERFACE)
target_include_directories(fa_ext_stb SYSTEM INTERFACE ${FA_EXT}/stb)

add_library(fa_ext_cgltf INTERFACE)
target_include_directories(fa_ext_cgltf SYSTEM INTERFACE ${FA_EXT}/cgltf)

add_library(fa_ext_drlibs INTERFACE)
target_include_directories(fa_ext_drlibs SYSTEM INTERFACE ${FA_EXT}/dr_libs)

add_library(fa_ext_doctest INTERFACE)
target_include_directories(fa_ext_doctest SYSTEM INTERFACE ${FA_EXT}/doctest)
# MSVC's operator<<(ostream, string_view) needs a complete std::ostream; doctest only forward-declares it,
# so CHECK(string_view == ...) fails to compile unless <ostream> is included first.
if(MSVC)
    target_compile_options(fa_ext_doctest INTERFACE "$<$<COMPILE_LANGUAGE:CXX>:/FIostream>")
endif()

# sokol headers + the graphics backend selected per platform.
# The single implementation translation unit lives in engine/platform.
add_library(fa_ext_sokol INTERFACE)
target_include_directories(fa_ext_sokol SYSTEM INTERFACE ${FA_EXT}/sokol ${FA_EXT}/sokol/util)
target_compile_definitions(fa_ext_sokol INTERFACE ${FA_SOKOL_BACKEND})

# ---- QuickJS-ng (JavaScript engine for gameplay scripts) -------------------
add_library(fa_ext_quickjs STATIC
    ${FA_EXT}/quickjs/dtoa.c
    ${FA_EXT}/quickjs/libregexp.c
    ${FA_EXT}/quickjs/libunicode.c
    ${FA_EXT}/quickjs/quickjs.c)
set_target_properties(fa_ext_quickjs PROPERTIES C_STANDARD 11 C_STANDARD_REQUIRED ON)
target_include_directories(fa_ext_quickjs SYSTEM PUBLIC ${FA_EXT}/quickjs)
target_compile_definitions(fa_ext_quickjs PRIVATE _GNU_SOURCE QUICKJS_NG_BUILD)
if(WIN32)
    target_compile_definitions(fa_ext_quickjs PRIVATE WIN32_LEAN_AND_MEAN _WIN32_WINNT=0x0601)
else()
    target_link_libraries(fa_ext_quickjs PUBLIC m)
endif()

target_link_libraries(fa_ext_quickjs PUBLIC ${CMAKE_DL_LIBS} Threads::Threads)

# ---- Box2D v3 (2D physics) --------------------------------------------------
file(GLOB FA_BOX2D_SOURCES ${FA_EXT}/box2d/src/*.c)
add_library(fa_ext_box2d STATIC ${FA_BOX2D_SOURCES})
set_target_properties(fa_ext_box2d PROPERTIES C_STANDARD 17 C_STANDARD_REQUIRED ON)
target_include_directories(fa_ext_box2d SYSTEM PUBLIC ${FA_EXT}/box2d/include)
target_include_directories(fa_ext_box2d PRIVATE ${FA_EXT}/box2d/src)
if(NOT MSVC)
    target_link_libraries(fa_ext_box2d PUBLIC m)
endif()

# ---- Dear ImGui (editor + debug UI) ----------------------------------------
add_library(fa_ext_imgui STATIC
    ${FA_EXT}/imgui/imgui.cpp
    ${FA_EXT}/imgui/imgui_draw.cpp
    ${FA_EXT}/imgui/imgui_tables.cpp
    ${FA_EXT}/imgui/imgui_widgets.cpp
    ${FA_EXT}/imgui/imgui_demo.cpp
    ${FA_EXT}/imgui/misc/cpp/imgui_stdlib.cpp)
target_include_directories(fa_ext_imgui SYSTEM PUBLIC ${FA_EXT}/imgui ${FA_EXT}/imgui/misc/cpp)

# ---- Basis Universal (GPU texture compression, KTX2) ------------------------
# The transcoder turns a KTX2 file into the GPU format the device samples (fa_render, every platform). The encoder
# makes the files (fa_tooling, desktop only; `factoria export` compresses textures). Both must see the same BASISD_*
# settings, so the transcoder target carries them as PUBLIC definitions. The engine only asks for ASTC 4x4, BC7, ETC2
# RGBA8 and RGBA8, so every other output format is compiled out of the transcoder (it stays small), and KTX2 files are
# not Zstandard-supercompressed (no zstd to vendor or link).
set(FA_BASISU ${FA_EXT}/basis_universal)
add_library(fa_ext_basisu_transcoder STATIC ${FA_BASISU}/transcoder/basisu_transcoder.cpp)
target_include_directories(fa_ext_basisu_transcoder SYSTEM PUBLIC ${FA_BASISU})
# No SSE or OpenCL paths either (one code path on x86 and ARM).
target_compile_definitions(fa_ext_basisu_transcoder PUBLIC
    BASISU_SUPPORT_SSE=0 BASISU_SUPPORT_OPENCL=0 BASISD_SUPPORT_KTX2=1 BASISD_SUPPORT_KTX2_ZSTD=0
    BASISD_SUPPORT_DXT1=0 BASISD_SUPPORT_DXT5A=0 BASISD_SUPPORT_PVRTC1=0 BASISD_SUPPORT_PVRTC2=0
    BASISD_SUPPORT_ATC=0 BASISD_SUPPORT_FXT1=0 BASISD_SUPPORT_ETC2_EAC_RG11=0
    BASISD_SUPPORT_ASTC_HIGHER_OPAQUE_QUALITY=0)

if(FA_BUILD_TOOLS)
    set(FA_BASISU_ENCODER_SOURCES
        basisu_backend basisu_basis_file basisu_comp basisu_enc basisu_etc basisu_frontend basisu_gpu_texture
        basisu_pvrtc1_4 basisu_resampler basisu_resample_filters basisu_ssim basisu_uastc_enc basisu_bc7e_scalar
        basisu_dds_export basisu_bc7enc basisu_bc15_spmd basisu_opencl basisu_kernels_sse basisu_bc15_spmd_sse
        basisu_uastc_hdr_4x4_enc basisu_astc_hdr_6x6_enc basisu_astc_hdr_common basisu_astc_ldr_common
        basisu_astc_ldr_encode basisu_astc_ldr_fencode basisu_tinyexr jpgd pvpngreader 3rdparty/android_astc_decomp)
    list(TRANSFORM FA_BASISU_ENCODER_SOURCES PREPEND ${FA_BASISU}/encoder/)
    list(TRANSFORM FA_BASISU_ENCODER_SOURCES APPEND .cpp)
    # XBC7, an experimental format the engine never writes, is the one encoder file that needs zstd whatever the
    # settings, and zstd is not vendored. basisu_comp.cpp still calls three of its functions: they exist here, failing.
    file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/basisu_xbc7_stub.cpp [=[
#include "basisu_xbc7_encode.h"
namespace basisu::xbc7 {
void pack_options::set_rdo_level(uint32_t) {}
uint32_t pack_options::set_num_stripes_for_image(const image&, uint32_t) { return 1; }
bool pack_image(const image&, const pack_options&, uint8_vec&, vector2D<basist::bc7u::log_bc7_block>&) { return false; }
}
]=])
    add_library(fa_ext_basisu_encoder STATIC ${FA_BASISU_ENCODER_SOURCES} ${CMAKE_CURRENT_BINARY_DIR}/basisu_xbc7_stub.cpp)
    target_include_directories(fa_ext_basisu_encoder PRIVATE ${FA_BASISU}/encoder)
    target_link_libraries(fa_ext_basisu_encoder PUBLIC fa_ext_basisu_transcoder Threads::Threads)
    target_compile_definitions(fa_ext_basisu_encoder PUBLIC BASISU_SUPPORT_ASTCENC=0)
endif()

foreach(t fa_ext_quickjs fa_ext_box2d fa_ext_imgui fa_ext_basisu_transcoder fa_ext_basisu_encoder)
    if(NOT TARGET ${t})
        continue()
    endif()
    if(MSVC)
        target_compile_options(${t} PRIVATE /w)
    else()
        target_compile_options(${t} PRIVATE -w)
        if(t MATCHES "basisu")  # Basis Universal must be compiled without strict aliasing (its README)
            target_compile_options(${t} PRIVATE -fno-strict-aliasing)
        endif()
    endif()
endforeach()
