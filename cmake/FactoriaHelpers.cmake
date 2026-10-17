# Helpers that keep per-module CMakeLists tiny. Modules glob their sources, so
# adding a .cpp file never requires touching CMake.
#
# Platform-specific files are selected by suffix:
#   *_linux.cpp  *_win32.cpp  *_android.cpp  *_apple.mm / *_apple.m  *_web.cpp
#   *_posix.cpp  (linux, macos, ios, android)
#   *_egl.cpp    (linux, android)

add_library(fa_warnings INTERFACE)
if(MSVC)
    target_compile_options(fa_warnings INTERFACE /W4 /permissive- /utf-8 /wd4100 /wd4201)
    # windows.h defines min/max macros that break std::min/std::max;  silence the CRT "unsafe" (getenv, fopen) warnings.
    target_compile_definitions(fa_warnings INTERFACE NOMINMAX _CRT_SECURE_NO_WARNINGS)
    if(FA_WARNINGS_AS_ERRORS)
        target_compile_options(fa_warnings INTERFACE /WX)
    endif()
else()
    target_compile_options(fa_warnings INTERFACE -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers)
    if(FA_WARNINGS_AS_ERRORS)
        target_compile_options(fa_warnings INTERFACE -Werror)
    endif()
endif()

function(_fa_filter_platform_sources out_var)
    set(result "")
    foreach(f ${ARGN})
        get_filename_component(stem ${f} NAME_WE)
        set(keep ON)
        if(stem MATCHES "_linux$" AND NOT FA_PLATFORM STREQUAL "linux")
            set(keep OFF)
        elseif(stem MATCHES "_win32$" AND NOT FA_PLATFORM STREQUAL "windows")
            set(keep OFF)
        elseif(stem MATCHES "_android$" AND NOT FA_PLATFORM STREQUAL "android")
            set(keep OFF)
        elseif(stem MATCHES "_apple$" AND NOT APPLE)
            set(keep OFF)
        elseif(stem MATCHES "_web$" AND NOT FA_PLATFORM STREQUAL "web")
            set(keep OFF)
        elseif(stem MATCHES "_posix$" AND WIN32)
            set(keep OFF)
        elseif(stem MATCHES "_egl$" AND NOT (FA_PLATFORM STREQUAL "linux" OR FA_PLATFORM STREQUAL "android"))
            set(keep OFF)
        endif()
        # On Apple, an `foo_apple.mm` replaces `foo.cpp`-style generic files only if the module says so.
        if(keep)
            list(APPEND result ${f})
        endif()
    endforeach()
    set(${out_var} ${result} PARENT_SCOPE)
endfunction()

# fa_add_module(<name> [DEPS a b] [PRIVATE_DEPS c d] [EXTRA_SOURCES ...])
#   Creates static library target fa_<name> from src/**/*.{c,cpp,m,mm},
#   public include dir include/ (headers live in include/fa/<name>/).
function(fa_add_module name)
    cmake_parse_arguments(ARG "" "" "DEPS;PRIVATE_DEPS;EXTRA_SOURCES" ${ARGN})
    file(GLOB_RECURSE srcs CONFIGURE_DEPENDS
        ${CMAKE_CURRENT_SOURCE_DIR}/src/*.c
        ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)
    if(APPLE)
        file(GLOB_RECURSE objc_srcs CONFIGURE_DEPENDS
            ${CMAKE_CURRENT_SOURCE_DIR}/src/*.m
            ${CMAKE_CURRENT_SOURCE_DIR}/src/*.mm)
        list(APPEND srcs ${objc_srcs})
    endif()
    file(GLOB_RECURSE hdrs CONFIGURE_DEPENDS
        ${CMAKE_CURRENT_SOURCE_DIR}/include/*.h
        ${CMAKE_CURRENT_SOURCE_DIR}/src/*.h)
    _fa_filter_platform_sources(srcs ${srcs})
    add_library(fa_${name} STATIC ${srcs} ${hdrs} ${ARG_EXTRA_SOURCES})
    target_include_directories(fa_${name} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
    target_include_directories(fa_${name} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
    target_link_libraries(fa_${name} PUBLIC ${ARG_DEPS} PRIVATE ${ARG_PRIVATE_DEPS} fa_warnings)
    target_compile_features(fa_${name} PUBLIC cxx_std_20)
    target_compile_definitions(fa_${name} PUBLIC FA_ENGINE_VERSION="${FA_ENGINE_VERSION}"
        FA_PLATFORM_NAME="${FA_PLATFORM}")
endfunction()

# fa_add_tests(<name> [DEPS ...] [LABELS ...])
#   Builds tests/*.cpp of the current module into fa_test_<name> (doctest) and
#   registers it with CTest. Tests run from the repo root so fixtures resolve.
#   LABELS: e.g. `gpu` for tests needing a (software) GPU; CI on hosts without
#   one runs `ctest -LE gpu`.
function(fa_add_tests name)
    if(NOT FA_BUILD_TESTS)
        return()
    endif()
    cmake_parse_arguments(ARG "" "" "DEPS;LABELS" ${ARGN})
    file(GLOB_RECURSE tsrcs CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/tests/*.cpp)
    if(NOT tsrcs)
        return()
    endif()
    _fa_filter_platform_sources(tsrcs ${tsrcs})
    add_executable(fa_test_${name} ${tsrcs} ${FA_ROOT}/cmake/doctest_main.cpp)
    target_link_libraries(fa_test_${name} PRIVATE fa_${name} ${ARG_DEPS} fa_ext_doctest fa_warnings)
    target_include_directories(fa_test_${name} PRIVATE ${FA_GENERATED_DIR})  # fa_test_paths.h: FA_REPO_ROOT...
    add_test(NAME ${name} COMMAND fa_test_${name} WORKING_DIRECTORY ${FA_ROOT})
    if(ARG_LABELS)
        set_tests_properties(${name} PROPERTIES LABELS "${ARG_LABELS}")
    endif()
endfunction()

# fa_embed_files(<target> <namespace> <header_name> FILES <abs paths...> BASE <dir>)
#   Generates a C++ source exposing the files as string_views:
#     namespace <ns> { struct EmbeddedFile { std::string_view path, data; };
#                      std::span<const EmbeddedFile> files(); }
#   Used to bake docs/ and templates/ into the factoria binary so AIs can read
#   them offline (`factoria docs`, MCP docs tools, `factoria new`).
function(fa_embed_files target ns header_name)
    cmake_parse_arguments(ARG "" "BASE" "FILES" ${ARGN})
    set(out_dir ${CMAKE_CURRENT_BINARY_DIR}/embedded)
    set(out_cpp ${out_dir}/${header_name}.cpp)
    set(out_h   ${out_dir}/${header_name}.h)
    file(MAKE_DIRECTORY ${out_dir})
    add_custom_command(
        OUTPUT ${out_cpp} ${out_h}
        COMMAND ${CMAKE_COMMAND} -DNS=${ns} -DOUT_CPP=${out_cpp} -DOUT_H=${out_h}
                -DBASE=${ARG_BASE} "-DFILES=${ARG_FILES}"
                -P ${FA_ROOT}/cmake/EmbedFiles.cmake
        DEPENDS ${ARG_FILES} ${FA_ROOT}/cmake/EmbedFiles.cmake
        COMMENT "Embedding ${header_name}"
        VERBATIM)
    target_sources(${target} PRIVATE ${out_cpp} ${out_h})
    target_include_directories(${target} PRIVATE ${out_dir})
endfunction()
