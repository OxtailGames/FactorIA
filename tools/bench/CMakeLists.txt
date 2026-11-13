# fa_bench: the engine's microbenchmarks (docs/PERFORMANCE.md, "Microbenchmarks"). The harness and the comparison with a baseline
# (src/core) know only fa_core and have their own test; the benchmarks (src/benches) use the engine modules.
add_library(fa_bench_core STATIC src/core/bench.cpp)
target_include_directories(fa_bench_core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/src/core)
target_link_libraries(fa_bench_core PUBLIC fa_core PRIVATE fa_warnings)

file(GLOB bench_srcs CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/benches/*.cpp)
add_executable(fa_bench ${bench_srcs} src/main.cpp)
target_include_directories(fa_bench PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src ${CMAKE_CURRENT_SOURCE_DIR}/src/benches)
target_link_libraries(fa_bench PRIVATE fa_bench_core fa_render fa_physics fa_audio fa_script fa_warnings)
fa_allow_duplicate_libraries(fa_bench)

if(FA_BUILD_TESTS)
    file(GLOB bench_tests CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/tests/*.cpp)
    if(bench_tests)
        add_executable(fa_test_bench ${bench_tests} ${FA_ROOT}/cmake/doctest_main.cpp)
        target_link_libraries(fa_test_bench PRIVATE fa_bench_core fa_ext_doctest fa_warnings)
        add_test(NAME bench_compare COMMAND fa_test_bench WORKING_DIRECTORY ${FA_ROOT})
    endif()
    # The exit status of the program itself (main.cpp): a failed comparison exits 1 with --json too.
    add_test(NAME bench_exit_status
        COMMAND ${CMAKE_COMMAND} -DBENCH=$<TARGET_FILE:fa_bench> -DWORK=${CMAKE_CURRENT_BINARY_DIR}
                -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/exit_status.cmake)
endif()
