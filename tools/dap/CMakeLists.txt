# fa_dap: the Debug Adapter Protocol server of the script debugger (framing, DapServer, launch arguments). No I/O of its
# own: `factoria dap` (tools/cli/src/cmd_dap.cpp) wires it to stdin/stdout. docs/DEBUGGING.md, docs/design/SCRIPT_DEBUGGER.md.
add_library(fa_dap STATIC)
file(GLOB_RECURSE dap_srcs CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)
target_sources(fa_dap PRIVATE ${dap_srcs})
target_include_directories(fa_dap PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
target_link_libraries(fa_dap PUBLIC fa_tooling PRIVATE fa_warnings)
if(FA_BUILD_TESTS)
    file(GLOB_RECURSE dap_tests CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/tests/*.cpp)
    if(dap_tests)
        add_executable(fa_test_dap ${dap_tests} ${FA_ROOT}/cmake/doctest_main.cpp)
        target_link_libraries(fa_test_dap PRIVATE fa_dap fa_ext_doctest fa_warnings)
        target_include_directories(fa_test_dap PRIVATE ${FA_GENERATED_DIR})  # fa_test_paths.h: FA_REPO_ROOT
        add_test(NAME dap COMMAND fa_test_dap WORKING_DIRECTORY ${FA_ROOT})
    endif()
endif()
