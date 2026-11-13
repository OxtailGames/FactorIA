# Code coverage (scripts/coverage-report.sh, docs/BUILDING.md "Coverage").
#
#   FA_COVERAGE=ON  Clang only (Clang or AppleClang): every target is built with -fprofile-instr-generate -fcoverage-mapping, and
#                   every ctest process writes its raw profile to <build>/coverage/raw/ (LLVM_PROFILE_FILE, %p = process id,
#                   %m = binary signature, so parallel tests and child processes never share a file). external/ is instrumented
#                   too (the flags are global); scripts/coverage-report.sh leaves it out of the report with llvm-cov's ignore regex.
#   FA_COVERAGE=OFF (default) nothing changes.

option(FA_COVERAGE "Instrument the build for llvm-cov source coverage (Clang only; docs/BUILDING.md, 'Coverage')" OFF)

if(FA_COVERAGE)
    if(NOT CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        message(FATAL_ERROR "FA_COVERAGE needs Clang (compiler is ${CMAKE_CXX_COMPILER_ID}): it uses clang's source-based coverage "
                            "and llvm-cov. Configure with -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ (on macOS the "
                            "Apple clang works), or leave FA_COVERAGE off.")
    endif()
    add_compile_options(-fprofile-instr-generate -fcoverage-mapping)
    add_link_options(-fprofile-instr-generate)
    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/coverage/raw)
    message(STATUS "FactorIA: FA_COVERAGE is on (profiles in ${CMAKE_BINARY_DIR}/coverage/raw)")
endif()
