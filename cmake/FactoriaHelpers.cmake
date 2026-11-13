# Helpers that keep per-module CMakeLists tiny. Modules glob their sources, so
# adding a .cpp file never requires touching CMake.
#
# Platform-specific files are selected by suffix:
#   *_linux.cpp  *_win32.cpp  *_android.cpp  *_apple.mm / *_apple.m  *_web.cpp
#   *_posix.cpp  (linux, macos, ios, android)
#   *_egl.cpp    (linux, android)

add_library(fa_warnings INTERFACE)
if(MSVC)
    target_compile_options(fa_warnings INTERFACE /W4 /permissive- /utf-8 /bigobj /wd4100 /wd4201)
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
    target_compile_definitions(fa_${name} PUBLIC FA_PLATFORM_NAME="${FA_PLATFORM}")
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
    list(FILTER tsrcs EXCLUDE REGEX "/tests/programs/")  # programs the tests run (their own main()), built by the module
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

# fa_test_timeout_factor(<out var>): what the TIMEOUT of every test is multiplied by in this tree: the product of the factors of
# the options that slow the run down (FA_COVERAGE_TIMEOUT_SCALE, 3, with FA_COVERAGE; FA_SANITIZE_TIMEOUT_FACTOR, 3 for ASan +
# UBSan and 5 for TSan, with FA_SANITIZE), 1 when none is on. Read when add_test() is called and again when the scaling runs.
function(fa_test_timeout_factor out_var)
    set(factor 1)
    if(FA_COVERAGE)
        math(EXPR factor "${factor} * ${FA_COVERAGE_TIMEOUT_SCALE}")
    endif()
    if(FA_SANITIZE)
        math(EXPR factor "${factor} * ${FA_SANITIZE_TIMEOUT_FACTOR}")
    endif()
    set(${out_var} ${factor} PARENT_SCOPE)
endfunction()

# Multiplies the TIMEOUT of one test by fa_test_timeout_factor, once (add_test() below defers one call per test). A test that sets
# no TIMEOUT gets ctest's own default of 1500 s times the factor. The TIMEOUT of a test is set after its add_test(), so the call
# runs at the end of the directory that created the test (cmake_language(DEFER), CMake 3.19; get_test_property and
# set_tests_properties work on the current directory's tests, so this needs neither the DIRECTORY option of set_property(TEST),
# which is CMake 3.28, nor a walk over the directories).
function(fa_scale_test_timeout name)
    fa_test_timeout_factor(factor)
    if(factor EQUAL 1)
        return()
    endif()
    get_test_property(${name} TIMEOUT timeout)
    if(NOT timeout OR NOT timeout MATCHES "^[0-9]+$")
        set(timeout 1500)
    endif()
    math(EXPR timeout "${timeout} * ${factor}")
    set_tests_properties(${name} PROPERTIES TIMEOUT ${timeout})
endfunction()

# add_test() that also gives every test the Windows file rules emulation of fa::fs (FA_TEST_WINDOWS_FILE_RULES, top-level
# CMakeLists.txt; engine/core/include/fa/core/fs.h). FA_FS_WINDOWS_RULES_DEFAULT is only a default: the variable
# FA_FS_WINDOWS_RULES in the environment of the ctest run wins, so `FA_FS_WINDOWS_RULES=0 ctest` turns it off for one run.
# Every test also gets FA_CACHE_DIR=<build dir>/test-cache (fs::cache_dir(), the shader cache), so a test run never writes the
# user's real cache folder; delete the folder to start a run with a cold cache.
# It is the "NAME <name> COMMAND ..." form only (all this repo uses). A test that sets its own ENVIRONMENT must APPEND to
# the property (set_property(TEST <name> APPEND PROPERTY ENVIRONMENT ...)): set_tests_properties(... ENVIRONMENT ...)
# replaces this one.
function(add_test)
    _add_test(${ARGV})
    if("${ARGV0}" STREQUAL "NAME")
        set_property(TEST ${ARGV1} APPEND PROPERTY ENVIRONMENT "FA_CACHE_DIR=${CMAKE_BINARY_DIR}/test-cache")
    endif()
    if(FA_COVERAGE AND "${ARGV0}" STREQUAL "NAME")
        set_property(TEST ${ARGV1} APPEND PROPERTY ENVIRONMENT "LLVM_PROFILE_FILE=${CMAKE_BINARY_DIR}/coverage/raw/%4m.profraw")
    endif()
    if(NOT WIN32 AND FA_TEST_WINDOWS_FILE_RULES AND "${ARGV0}" STREQUAL "NAME")
        set_property(TEST ${ARGV1} APPEND PROPERTY ENVIRONMENT "FA_FS_WINDOWS_RULES_DEFAULT=1")
    endif()
    # A tree built with FA_SANITIZE: ASAN_OPTIONS / UBSAN_OPTIONS / LSAN_OPTIONS / TSAN_OPTIONS with the suppressions of
    # tools/ci/sanitizers (cmake/FactoriaSanitize.cmake). Here and not in the test presets, so a plain
    # `cmake -DFA_SANITIZE=... && ctest` and scripts/agent-build.sh get them too.
    if(FA_SANITIZE AND "${ARGV0}" STREQUAL "NAME")
        fa_sanitizer_test_environment(_fa_san_env)
        set_property(TEST ${ARGV1} APPEND PROPERTY ENVIRONMENT ${_fa_san_env})
    endif()
    # Its TIMEOUT times the factor of FA_COVERAGE and FA_SANITIZE (fa_scale_test_timeout), once the directory has set it.
    # (EVAL: the name has to be in the deferred call itself; a ${} in it would be read when the call runs, after this function)
    if((FA_COVERAGE OR FA_SANITIZE) AND "${ARGV0}" STREQUAL "NAME")
        cmake_language(EVAL CODE "cmake_language(DEFER CALL fa_scale_test_timeout ${ARGV1})")
    endif()
endfunction()

# Apple's linker (Xcode 15 and later) warns "ignoring duplicate libraries" when a static library appears twice in a link
# line. CMake repeats a library on purpose when static libraries depend on each other in a cycle (render <-> script, the
# tooling libraries), and the repeat is harmless: it is how a static link resolves such a cycle. A target whose link
# line has such a repeat calls this to say so; elsewhere the linker's warning stays on.
if(APPLE)
    include(CheckLinkerFlag)
    check_linker_flag(CXX "LINKER:-no_warn_duplicate_libraries" FA_LINKER_HAS_NO_WARN_DUPLICATE_LIBRARIES)
endif()
function(fa_allow_duplicate_libraries target)
    if(APPLE AND FA_LINKER_HAS_NO_WARN_DUPLICATE_LIBRARIES)
        target_link_options(${target} PRIVATE "LINKER:-no_warn_duplicate_libraries")
    endif()
endfunction()
