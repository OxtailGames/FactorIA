# Code coverage (scripts/coverage-report.sh, docs/BUILDING.md "Coverage").
#
#   FA_COVERAGE=ON  Clang only (Clang or AppleClang): every target is built with -fprofile-instr-generate -fcoverage-mapping, and
#                   every ctest process writes its raw profile to <build>/coverage/raw/ (LLVM_PROFILE_FILE with %4m: online merge
#                   mode, so the processes of one binary update a few shared files (a pool of 4 per binary) instead of leaving a
#                   full profile per process: cli_integration and the examples start thousands). The TIMEOUT of every test that
#                   has one is multiplied by FA_COVERAGE_TIMEOUT_SCALE (default 3): instrumented Debug runs are slow, and a test
#                   killed by its timeout writes no profile. external/ is instrumented too (the flags are global);
#                   scripts/coverage-report.sh leaves it out of the report with llvm-cov's ignore regex.
#   FA_COVERAGE=OFF (default) nothing changes.

option(FA_COVERAGE "Instrument the build for llvm-cov source coverage (Clang only; docs/BUILDING.md, 'Coverage')" OFF)
set(FA_COVERAGE_TIMEOUT_SCALE 3 CACHE STRING "FA_COVERAGE: factor applied to the TIMEOUT property of every test")

if(FA_COVERAGE)
    if(NOT CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        message(FATAL_ERROR "FA_COVERAGE needs Clang (compiler is ${CMAKE_CXX_COMPILER_ID}): it uses clang's source-based coverage "
                            "and llvm-cov. Configure with -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ (on macOS the "
                            "Apple clang works), or leave FA_COVERAGE off.")
    endif()
    add_compile_options(-fprofile-instr-generate -fcoverage-mapping)
    add_link_options(-fprofile-instr-generate)
    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/coverage/raw)

    # At the end of the top-level CMakeLists.txt, when every directory has registered its tests (set(TIMEOUT) needs CMake 3.28
    # for the DIRECTORY option; the Ubuntu 24.04 runner has 3.28).
    function(fa_coverage_scale_timeouts dir)
        get_property(tests DIRECTORY ${dir} PROPERTY TESTS)
        foreach(t IN LISTS tests)
            get_property(timeout TEST ${t} DIRECTORY ${dir} PROPERTY TIMEOUT)
            if(timeout)
                math(EXPR scaled "${timeout} * ${FA_COVERAGE_TIMEOUT_SCALE}")
                set_property(TEST ${t} DIRECTORY ${dir} PROPERTY TIMEOUT ${scaled})
            endif()
        endforeach()
        get_property(subdirs DIRECTORY ${dir} PROPERTY SUBDIRECTORIES)
        foreach(sub IN LISTS subdirs)
            fa_coverage_scale_timeouts(${sub})
        endforeach()
    endfunction()
    cmake_language(DEFER DIRECTORY ${CMAKE_SOURCE_DIR} CALL fa_coverage_scale_timeouts ${CMAKE_SOURCE_DIR})
    message(STATUS "FactorIA: FA_COVERAGE is on (profiles in ${CMAKE_BINARY_DIR}/coverage/raw, test timeouts x${FA_COVERAGE_TIMEOUT_SCALE})")
endif()
