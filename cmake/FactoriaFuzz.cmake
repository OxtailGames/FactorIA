# Fuzzing (tools/fuzz, docs/BUILDING.md "Fuzzing").
#
#   FA_FUZZ=ON   Clang only: every target of tools/fuzz links libFuzzer, and the whole tree is built with AddressSanitizer
#                and UndefinedBehaviorSanitizer (a UBSan finding stops the run like a crash, except inside external/: tools/fuzz/ubsan_ignorelist.txt), so the fuzzer sees the coverage
#                of the engine libraries. Not for the normal test suite: the CI job `linux-fuzz` is the only user.
#   FA_FUZZ=OFF  (default, every compiler, MSVC included) every target links a small replay driver (tools/fuzz/replay_main.cpp)
#                instead and is a ctest (label `fuzz`) that runs each file of its corpus once: the corpus is a regression suite.
#
# fa_add_fuzz_target(<name> DEPS <libraries>) in tools/fuzz/CMakeLists.txt builds tools/fuzz/targets/<name>.cpp as
# fa_fuzz_<name> with the corpus tools/fuzz/corpus/<name>/. `fa_fuzz_all` builds every target.

option(FA_FUZZ "Build the fuzz targets with libFuzzer, ASan and UBSan (Clang only; docs/BUILDING.md, 'Fuzzing')" OFF)

if(FA_FUZZ)
    # AppleClang has no libFuzzer (a Homebrew LLVM clang does, and its id is plain "Clang").
    if(NOT CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        message(FATAL_ERROR "FA_FUZZ needs Clang with libFuzzer (compiler is ${CMAKE_CXX_COMPILER_ID}). Use clang/clang++ from LLVM; "
                            "without FA_FUZZ the fuzz targets still build and replay their corpus as ctests.")
    endif()
    # fuzzer-no-link: coverage instrumentation in every library, the fuzzer's own main only in the fuzz executables.
    # UBSan stays silent inside external/ (tools/fuzz/ubsan_ignorelist.txt); ASan does not.
    add_compile_options(-fsanitize=fuzzer-no-link,address,undefined -fno-sanitize-recover=undefined -fno-omit-frame-pointer
                        "-fsanitize-ignorelist=${CMAKE_CURRENT_LIST_DIR}/../tools/fuzz/ubsan_ignorelist.txt")
    add_link_options(-fsanitize=address,undefined)
    message(STATUS "FactorIA: FA_FUZZ is on (libFuzzer + ASan + UBSan)")
endif()

add_custom_target(fa_fuzz_all COMMENT "Every fuzz target")

function(fa_add_fuzz_target name)
    cmake_parse_arguments(ARG "" "" "DEPS" ${ARGN})
    set(src ${CMAKE_CURRENT_SOURCE_DIR}/targets/${name}.cpp)
    set(corpus ${CMAKE_CURRENT_SOURCE_DIR}/corpus/${name})
    if(NOT EXISTS ${src})
        message(FATAL_ERROR "fa_add_fuzz_target(${name}): ${src} does not exist")
    endif()
    if(NOT IS_DIRECTORY ${corpus})
        message(FATAL_ERROR "fa_add_fuzz_target(${name}): the corpus directory ${corpus} does not exist (put a few small seed files in it)")
    endif()
    if(FA_FUZZ)
        add_executable(fa_fuzz_${name} ${src})
        target_link_options(fa_fuzz_${name} PRIVATE -fsanitize=fuzzer)
    else()
        add_executable(fa_fuzz_${name} ${src} ${FA_ROOT}/tools/fuzz/replay_main.cpp)
        # A corpus path relative to the repository root: no machine path (accents on Windows) goes through argv.
        add_test(NAME fuzz_${name} COMMAND fa_fuzz_${name} tools/fuzz/corpus/${name} WORKING_DIRECTORY ${FA_ROOT})
        set_tests_properties(fuzz_${name} PROPERTIES LABELS fuzz TIMEOUT 300)
    endif()
    target_link_libraries(fa_fuzz_${name} PRIVATE ${ARG_DEPS} fa_warnings)
    target_include_directories(fa_fuzz_${name} PRIVATE ${FA_ROOT}/tools/fuzz)
    add_dependencies(fa_fuzz_all fa_fuzz_${name})
endfunction()
