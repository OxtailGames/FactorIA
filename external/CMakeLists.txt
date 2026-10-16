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

add_library(fa_ext_qoa INTERFACE)
target_include_directories(fa_ext_qoa SYSTEM INTERFACE ${FA_EXT}/qoa)

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

foreach(t fa_ext_quickjs fa_ext_box2d fa_ext_imgui)
    if(MSVC)
        target_compile_options(${t} PRIVATE /w)
    else()
        target_compile_options(${t} PRIVATE -w)
    endif()
endforeach()
