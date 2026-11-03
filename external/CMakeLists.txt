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

add_library(fa_ext_nanosvg INTERFACE)
target_include_directories(fa_ext_nanosvg SYSTEM INTERFACE ${FA_EXT}/nanosvg)

# Clipper2 (polygon booleans and offsetting; fa_tooling only). Doubles, no Z coordinate; the library throws on bad input and
# every call in tools/common/src/vector_clip.cpp catches it.
add_library(fa_ext_clipper2 STATIC
    ${FA_EXT}/clipper2/src/clipper.engine.cpp
    ${FA_EXT}/clipper2/src/clipper.offset.cpp
    ${FA_EXT}/clipper2/src/clipper.rectclip.cpp
    ${FA_EXT}/clipper2/src/clipper.triangulation.cpp)
target_include_directories(fa_ext_clipper2 SYSTEM PUBLIC ${FA_EXT}/clipper2/include)
set_target_properties(fa_ext_clipper2 PROPERTIES CXX_STANDARD 17 CXX_STANDARD_REQUIRED ON)

add_library(fa_ext_qoa INTERFACE)
target_include_directories(fa_ext_qoa SYSTEM INTERFACE ${FA_EXT}/qoa)

add_library(fa_ext_tinysoundfont INTERFACE)
target_include_directories(fa_ext_tinysoundfont SYSTEM INTERFACE ${FA_EXT}/tinysoundfont)

add_library(fa_ext_plmpeg INTERFACE)
target_include_directories(fa_ext_plmpeg SYSTEM INTERFACE ${FA_EXT}/pl_mpeg)

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
if(FA_PLATFORM STREQUAL "web")
    # Box2D's WebAssembly path uses the SSE2 compatibility header, which needs -msimd128 and so a browser with WebAssembly
    # SIMD in the whole module. The scalar path runs in every browser; it gives the same simulation, a little slower.
    target_compile_definitions(fa_ext_box2d PRIVATE BOX2D_DISABLE_SIMD)
endif()

# ---- Manifold (solid booleans for model documents) ---------------------------------------------------------
# Manifold v3.5.4 core (Apache-2.0): robust union, difference and intersection of closed triangle meshes (fa_scene, model_boolean.cpp).
# Built serial (MANIFOLD_PAR=-1: no TBB, no threads), without its CrossSection (Clipper2) and without bindings or tests: only
# src/*.cpp and include/manifold as released. It reports problems through a status, and the few internal asserts throw: the wrapper
# catches them (the Web build already uses WebAssembly exceptions, see cmake/FactoriaPlatform.cmake).
file(GLOB FA_MANIFOLD_SOURCES ${FA_EXT}/manifold/src/*.cpp)
add_library(fa_ext_manifold STATIC ${FA_MANIFOLD_SOURCES})
target_include_directories(fa_ext_manifold SYSTEM PUBLIC ${FA_EXT}/manifold/include)
target_include_directories(fa_ext_manifold PRIVATE ${FA_EXT}/manifold/src)
target_compile_definitions(fa_ext_manifold PUBLIC MANIFOLD_PAR=-1)
set_target_properties(fa_ext_manifold PROPERTIES CXX_STANDARD 17 CXX_STANDARD_REQUIRED ON)
target_link_libraries(fa_ext_manifold PUBLIC Threads::Threads)
if(MSVC)
    target_compile_definitions(fa_ext_manifold PRIVATE NOMINMAX)
    target_compile_options(fa_ext_manifold PRIVATE /bigobj)
else()
    # A Debug build of the engine keeps this library optimized: unoptimized, a boolean of two small solids takes seconds.
    target_compile_options(fa_ext_manifold PRIVATE $<$<CONFIG:Debug>:-O2>)
endif()

# ---- xatlas (UV unwrapping and chart packing for model documents) ---------------------------------------------
# xatlas (MIT, jpcy/xatlas): automatic UV parameterization and chart packing (fa_scene, model_uv_*.cpp). xatlas.cpp and xatlas.h
# are upstream's, unmodified; xatlas_fa.cpp (ours) includes xatlas.cpp with sinf, cosf, acosf and atan2f swapped for fa::det's so the
# UVs are the same on every platform. Single-threaded (XA_MULTITHREADED=0: no std::thread, so the Web and Android builds need no
# threads), no debug asserts or print hooks.
add_library(fa_ext_xatlas STATIC ${FA_EXT}/xatlas/xatlas_fa.cpp)
target_include_directories(fa_ext_xatlas SYSTEM PUBLIC ${FA_EXT}/xatlas)
target_include_directories(fa_ext_xatlas PRIVATE ${FA_EXT}/xatlas ${CMAKE_SOURCE_DIR}/engine/core/include)
target_compile_definitions(fa_ext_xatlas PRIVATE XA_MULTITHREADED=0 XA_DEBUG=0)
set_target_properties(fa_ext_xatlas PROPERTIES CXX_STANDARD 17 CXX_STANDARD_REQUIRED ON)
if(MSVC)
    target_compile_definitions(fa_ext_xatlas PRIVATE NOMINMAX _CRT_SECURE_NO_WARNINGS)
    target_compile_options(fa_ext_xatlas PRIVATE /bigobj)
else()
    # A Debug build of the engine keeps this library optimized: the packer rasterizes every chart, unoptimized it is far too slow.
    target_compile_options(fa_ext_xatlas PRIVATE $<$<CONFIG:Debug>:-O2>)
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

# ---- HarfBuzz (text shaping) and SheenBidi (Unicode bidirectional algorithm) ------------------------------------
# HarfBuzz is built as its own amalgamation (src/harfbuzz.cc) with the OpenType shaper only: no FreeType, ICU, GLib,
# Graphite, CoreText, DirectWrite or Uniscribe (their files compile to nothing without the HAVE_* macros), no AAT
# (Apple morx/kerx) and HB_LEAN's cuts of everything a game's text layout never calls (variations, naming, drawing,
# colour fonts, serialization). The `kern` table and the fallback shapers stay: old fonts have no GPOS kerning.
set(FA_HB ${FA_EXT}/harfbuzz)
add_library(fa_ext_harfbuzz STATIC ${FA_HB}/src/harfbuzz.cc)
target_include_directories(fa_ext_harfbuzz SYSTEM PUBLIC ${FA_HB}/src)
target_compile_definitions(fa_ext_harfbuzz PRIVATE HB_LEAN HB_NO_AAT HB_OPTIMIZE_SIZE)

# The same HarfBuzz with its subsetter and instancer (src/harfbuzz-subset.cc, which includes everything harfbuzz.cc does) for
# the tools: assets.subset_font. It is a superset of fa_ext_harfbuzz, so it replaces it where both are linked (a game never
# links this one). fa_tooling lists it before fa_runtime so that it is the library that defines every hb_* symbol.
add_library(fa_ext_harfbuzz_subset STATIC ${FA_HB}/src/harfbuzz-subset.cc)
target_include_directories(fa_ext_harfbuzz_subset SYSTEM PUBLIC ${FA_HB}/src)
target_compile_definitions(fa_ext_harfbuzz_subset PRIVATE HB_OPTIMIZE_SIZE)
if(MSVC)  # a Debug build of it has more sections than a default object file holds (C1128)
    target_compile_options(fa_ext_harfbuzz_subset PRIVATE /bigobj)
endif()

# SheenBidi: its unity build (Source/SheenBidi.c) is one translation unit; only the paragraph/line API is used.
add_library(fa_ext_sheenbidi STATIC ${FA_EXT}/sheenbidi/Source/SheenBidi.c)
set_target_properties(fa_ext_sheenbidi PROPERTIES C_STANDARD 11 C_STANDARD_REQUIRED ON)
target_include_directories(fa_ext_sheenbidi SYSTEM PUBLIC ${FA_EXT}/sheenbidi/Headers)
target_include_directories(fa_ext_sheenbidi PRIVATE ${FA_EXT}/sheenbidi/Source)
target_compile_definitions(fa_ext_sheenbidi PRIVATE SB_CONFIG_UNITY)

foreach(t fa_ext_quickjs fa_ext_box2d fa_ext_imgui fa_ext_basisu_transcoder fa_ext_basisu_encoder fa_ext_harfbuzz fa_ext_harfbuzz_subset fa_ext_sheenbidi fa_ext_manifold fa_ext_xatlas)
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
