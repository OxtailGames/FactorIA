# FA_SANITIZE: build everything with the sanitizers of Clang or GCC (docs/BUILDING.md, "Sanitizers").
#
#   -DFA_SANITIZE=address;undefined   AddressSanitizer + UndefinedBehaviorSanitizer (the CI job `linux-asan`)
#   -DFA_SANITIZE=thread              ThreadSanitizer (the CI job `linux-tsan`)
#   (empty, the default)              no sanitizer
#
# The flags are set for EVERY target, external/ included (this file is included before add_subdirectory(external)):
#  * ASan must see every allocation: a std::vector built in our code and grown in a library that is not instrumented gives
#    container-overflow false positives, and memory a library frees that we allocated confuses the shadow state.
#  * TSan must see every access of the shared data; uninstrumented code makes the races it takes part in invisible.
#  * UBSan findings inside external/ are not ours to fix (external/ is never edited): tools/ci/sanitizers/ubsan_ignorelist.txt lists
#    the ones we accepted, each with its reason (Clang's -fsanitize-ignorelist: the listed code is compiled without that check).
# `-fno-sanitize-recover=undefined`: a UBSan finding ends the test with a failure instead of one line in a log nobody reads. The
# runtime ignores UBSAN_OPTIONS=suppressions for the checks of such a build, which is why the ignorelist is a compile-time one.
# Tests get the *_OPTIONS environment variables from add_test() in FactoriaHelpers.cmake (fa_sanitizer_test_environment below).

set(FA_SANITIZE "" CACHE STRING
    "Sanitizers for every target: empty, 'address;undefined' (ASan + UBSan) or 'thread' (TSan). GCC and Clang on Linux and macOS only.")
set_property(CACHE FA_SANITIZE PROPERTY STRINGS "" "address;undefined" "address" "undefined" "thread")

set(FA_SANITIZE_ADDRESS OFF)
set(FA_SANITIZE_UNDEFINED OFF)
set(FA_SANITIZE_THREAD OFF)

if(FA_SANITIZE)
    set(_fa_san_known address undefined thread)
    foreach(_san ${FA_SANITIZE})
        if(NOT _san IN_LIST _fa_san_known)
            message(FATAL_ERROR "FA_SANITIZE: unknown sanitizer '${_san}' in '${FA_SANITIZE}'.\n"
                "  Allowed values: empty (none), 'address;undefined' (ASan + UBSan), 'address', 'undefined' or 'thread' (TSan).\n"
                "  Quote the semicolon in a shell: -DFA_SANITIZE=\"address;undefined\". The presets linux-asan, macos-asan and "
                "linux-tsan set it (CMakePresets.json).")
        endif()
        string(TOUPPER "${_san}" _SAN)
        set(FA_SANITIZE_${_SAN} ON)
    endforeach()
    if(FA_SANITIZE_THREAD AND FA_SANITIZE_ADDRESS)
        message(FATAL_ERROR "FA_SANITIZE='${FA_SANITIZE}': ThreadSanitizer and AddressSanitizer cannot be combined (they map the "
            "same shadow memory). Build two trees: -DFA_SANITIZE=\"address;undefined\" and -DFA_SANITIZE=thread.")
    endif()
    if(MSVC OR NOT CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        message(FATAL_ERROR "FA_SANITIZE='${FA_SANITIZE}' needs GCC or Clang (found ${CMAKE_CXX_COMPILER_ID}). MSVC's AddressSanitizer "
            "is not wired in; use the Linux or macOS presets (linux-asan, macos-asan, linux-tsan), or leave FA_SANITIZE empty.")
    endif()
    if(NOT (CMAKE_SYSTEM_NAME STREQUAL "Linux" OR CMAKE_SYSTEM_NAME STREQUAL "Darwin"))
        message(FATAL_ERROR "FA_SANITIZE='${FA_SANITIZE}' is for desktop Linux and macOS builds (this one targets "
            "${CMAKE_SYSTEM_NAME}: Emscripten, Android and iOS do not run the unit tests under a sanitizer). Leave FA_SANITIZE empty.")
    endif()
    if(NOT CMAKE_BUILD_TYPE STREQUAL "Debug" AND NOT CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
        message(WARNING "FA_SANITIZE: configure with -DCMAKE_BUILD_TYPE=Debug (or RelWithDebInfo) for readable stack traces "
            "(this tree is '${CMAKE_BUILD_TYPE}').")
    endif()

    string(REPLACE ";" "," _fa_san_list "${FA_SANITIZE}")
    set(_fa_san_flags -fsanitize=${_fa_san_list} -fno-omit-frame-pointer)
    set(_fa_san_compile_only "")
    if(FA_SANITIZE_UNDEFINED)
        list(APPEND _fa_san_flags -fno-sanitize-recover=undefined)
        if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
            set(_fa_san_compile_only -fsanitize-ignorelist=${CMAKE_CURRENT_SOURCE_DIR}/tools/ci/sanitizers/ubsan_ignorelist.txt)
        else()
            message(STATUS "FactorIA: ${CMAKE_CXX_COMPILER_ID} has no sanitizer ignorelist: the UBSan findings listed in "
                "tools/ci/sanitizers/ubsan_ignorelist.txt (Dear ImGui) will be reported. Use Clang for the clean run.")
        endif()
    endif()
    add_compile_options(${_fa_san_flags} ${_fa_san_compile_only})
    add_link_options(${_fa_san_flags})
    message(STATUS "FactorIA: sanitizers on for every target: -fsanitize=${_fa_san_list} (FA_SANITIZE)")
endif()

# fa_sanitizer_test_environment(<out var>): the NAME=value pairs a test needs under the sanitizers of this tree (empty without).
# The suppression files are read at run time by the sanitizer runtimes, so a path is enough.
function(fa_sanitizer_test_environment out_var)
    set(env "")
    set(dir ${FA_ROOT}/tools/ci/sanitizers)
    if(FA_SANITIZE_ADDRESS)
        # detect_leaks: LeakSanitizer exists on Linux only (the macOS runtime refuses the option). halt_on_error: the first
        # report ends the test with a failure (exit code 1) and the report on stderr, which ctest prints.
        set(asan "strict_string_checks=1:check_initialization_order=1:detect_stack_use_after_return=1:halt_on_error=1:suppressions=${dir}/asan.supp")
        if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
            string(APPEND asan ":detect_leaks=1")
            list(APPEND env "LSAN_OPTIONS=suppressions=${dir}/lsan.supp:print_suppressions=0")
        endif()
        list(APPEND env "ASAN_OPTIONS=${asan}")
    endif()
    if(FA_SANITIZE_UNDEFINED)
        list(APPEND env "UBSAN_OPTIONS=print_stacktrace=1:halt_on_error=1")
    endif()
    if(FA_SANITIZE_THREAD)
        list(APPEND env "TSAN_OPTIONS=suppressions=${dir}/tsan.supp:second_deadlock_stack=1:halt_on_error=0")
    endif()
    set(${out_var} "${env}" PARENT_SCOPE)
endfunction()

# fa_label_tsan(<test>...): the tests of the calling directory that run threads and so belong to the CI job linux-tsan
# (`ctest -L tsan`). Does nothing without FA_SANITIZE=thread.
function(fa_label_tsan)
    if(FA_SANITIZE_THREAD)
        foreach(_t ${ARGN})
            if(TEST ${_t})
                set_property(TEST ${_t} APPEND PROPERTY LABELS tsan)
            endif()
        endforeach()
    endif()
endfunction()

# Timeouts under a sanitizer. Instrumented code is 2-3x slower (ASan + UBSan) or 5-15x slower (TSan), and the CI job runs four tests
# at once on four vCPUs with a software GPU, so the TIMEOUT every test sets (editor_autotest_*, cli_integration, cli_dap...) is
# multiplied by FA_SANITIZE_TIMEOUT_FACTOR; a test that sets none gets ctest's own 1500 s default times the factor. The
# TIMEOUT of a test is set after its add_test(), so add_test() in cmake/FactoriaHelpers.cmake defers this to the end of the
# directory that created the test (cmake_language(DEFER)), when the property is final.
if(FA_SANITIZE)
    if(FA_SANITIZE_THREAD)
        set(_fa_san_factor 5)
    else()
        set(_fa_san_factor 3)
    endif()
    set(FA_SANITIZE_TIMEOUT_FACTOR ${_fa_san_factor} CACHE STRING "Multiplier of every test's TIMEOUT in a build with FA_SANITIZE.")
endif()
function(fa_sanitizer_scale_test_timeout name)
    get_test_property(${name} TIMEOUT timeout)
    if(NOT timeout OR NOT timeout MATCHES "^[0-9]+$")
        set(timeout 1500)
    endif()
    math(EXPR timeout "${timeout} * ${FA_SANITIZE_TIMEOUT_FACTOR}")
    set_tests_properties(${name} PROPERTIES TIMEOUT ${timeout})
endfunction()
