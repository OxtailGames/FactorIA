# `factoria`: the single developer binary (CLI + headless runner + MCP server +
# AI agent + editor). See docs/CLI.md.
# fa_cli holds everything except main() so tests can call fa::cli::cli_main in-process.
file(GLOB cli_srcs CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)
list(FILTER cli_srcs EXCLUDE REGEX "/main\\.cpp$")
add_library(fa_cli STATIC ${cli_srcs})
target_include_directories(fa_cli PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
target_link_libraries(fa_cli PUBLIC fa_tooling fa_mcp fa_ai PRIVATE fa_warnings)
if(TARGET fa_editor)
    target_link_libraries(fa_cli PUBLIC fa_editor)
    target_compile_definitions(fa_cli PRIVATE FA_WITH_EDITOR=1)
endif()

add_executable(factoria ${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp)
target_link_libraries(factoria PRIVATE fa_cli fa_warnings)

if(FA_BUILD_TESTS)
    file(GLOB cli_tests CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/tests/*.cpp)
    if(cli_tests)
        add_executable(fa_test_cli ${cli_tests} ${FA_ROOT}/cmake/doctest_main.cpp)
        target_link_libraries(fa_test_cli PRIVATE fa_cli fa_ext_doctest fa_warnings)
        target_compile_definitions(fa_test_cli PRIVATE FA_REPO_ROOT="${FA_ROOT}")
        add_test(NAME cli COMMAND fa_test_cli WORKING_DIRECTORY ${FA_ROOT})
    endif()

    # End-to-end: drives the real binary (new/validate/run/test/call/mcp) for every template.
    find_package(Python3 COMPONENTS Interpreter)
    if(Python3_FOUND)
        add_test(NAME cli_integration
            COMMAND ${Python3_EXECUTABLE} -I ${CMAKE_CURRENT_SOURCE_DIR}/tests/integration.py $<TARGET_FILE:factoria>
            WORKING_DIRECTORY ${FA_ROOT})
        set_tests_properties(cli_integration PROPERTIES TIMEOUT 600)
    endif()
endif()
