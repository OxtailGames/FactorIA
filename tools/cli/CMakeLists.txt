# `factoria`: the single developer binary (CLI + headless runner + MCP server +
# AI agent + editor). See docs/CLI.md.
file(GLOB_RECURSE cli_srcs CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)
add_executable(factoria ${cli_srcs})
target_link_libraries(factoria PRIVATE fa_tooling fa_mcp fa_ai fa_warnings)
if(TARGET fa_editor)
    target_link_libraries(factoria PRIVATE fa_editor)
    target_compile_definitions(factoria PRIVATE FA_WITH_EDITOR=1)
endif()
