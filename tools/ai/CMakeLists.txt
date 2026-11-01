# fa_ai: AI providers (Anthropic API, OpenAI-compatible APIs, CLI agents such as
# Claude Code / Codex), asset providers (images, sounds, 3D models), roles, config, agent loop. Depends on fa_core
# (the CommandRegistry is its tool source) and fa_tooling (palette lock, AI disclosure); the CLI binary wires it to a project.
file(GLOB_RECURSE ai_srcs CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)
_fa_filter_platform_sources(ai_srcs ${ai_srcs})

# The JSON Schema for ai.json is baked into the library (single source of
# truth: schemas/ai-config.schema.json).
set(FA_AI_SCHEMA_FILE ${FA_ROOT}/schemas/ai-config.schema.json)
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${FA_AI_SCHEMA_FILE})
file(READ ${FA_AI_SCHEMA_FILE} FA_AI_SCHEMA_JSON)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/src/config_schema.cpp.in
               ${CMAKE_CURRENT_BINARY_DIR}/generated/config_schema.cpp @ONLY)

add_library(fa_ai STATIC ${ai_srcs} ${CMAKE_CURRENT_BINARY_DIR}/generated/config_schema.cpp)
target_include_directories(fa_ai PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
target_compile_features(fa_ai PUBLIC cxx_std_20)
target_link_libraries(fa_ai PUBLIC fa_core fa_tooling PRIVATE fa_warnings fa_ext_quickjs)  # fa_ext_quickjs: the sandbox of JavaScript hooks (hook_js.cpp)

# HTTP: libcurl when available, otherwise the `curl` executable at runtime.
find_package(CURL QUIET)
if(CURL_FOUND)
    target_link_libraries(fa_ai PRIVATE CURL::libcurl)
    target_compile_definitions(fa_ai PRIVATE FA_HAVE_CURL=1)
else()
    message(STATUS "fa_ai: libcurl not found; falling back to spawning the curl executable")
endif()
if(WIN32)
    target_compile_definitions(fa_ai PRIVATE NOMINMAX WIN32_LEAN_AND_MEAN)
endif()

if(FA_BUILD_TESTS)
    file(GLOB_RECURSE ai_tests CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/tests/*.cpp)
    list(FILTER ai_tests EXCLUDE REGEX "/tests/programs/")  # programs the tests run (their own main()), built below
    if(ai_tests)
        add_executable(fa_test_ai ${ai_tests} ${FA_ROOT}/cmake/doctest_main.cpp)
        target_link_libraries(fa_test_ai PRIVATE fa_ai fa_ext_cgltf fa_ext_doctest fa_warnings)
        target_include_directories(fa_test_ai PRIVATE ${FA_GENERATED_DIR})  # fa_test_paths.h: FA_AI_FIXTURES...
        # tests/test_mcp_client.cpp talks to this MCP server over stdio; ctest hands the test its path (FA_FAKE_MCP_SERVER).
        add_executable(fa_fake_mcp_server tests/programs/fake_mcp_server.cpp)
        target_link_libraries(fa_fake_mcp_server PRIVATE fa_core fa_warnings)
        add_dependencies(fa_test_ai fa_fake_mcp_server)
        add_test(NAME ai COMMAND fa_test_ai WORKING_DIRECTORY ${FA_ROOT})
        set_tests_properties(ai PROPERTIES ENVIRONMENT "FA_FAKE_MCP_SERVER=$<TARGET_FILE:fa_fake_mcp_server>")
    endif()
endif()
