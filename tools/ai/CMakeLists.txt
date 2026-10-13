# fa_ai: AI providers (Anthropic API, OpenAI-compatible APIs, CLI agents such as
# Claude Code / Codex), roles, config, agent loop. Depends only on fa_core (the
# CommandRegistry is its tool source); the CLI binary wires it to a project.
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
target_link_libraries(fa_ai PUBLIC fa_core PRIVATE fa_warnings)

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
    if(ai_tests)
        add_executable(fa_test_ai ${ai_tests} ${FA_ROOT}/cmake/doctest_main.cpp)
        target_link_libraries(fa_test_ai PRIVATE fa_ai fa_ext_doctest fa_warnings)
        target_compile_definitions(fa_test_ai PRIVATE FA_REPO_ROOT="${FA_ROOT}"
            FA_AI_FIXTURES="${CMAKE_CURRENT_SOURCE_DIR}/tests/fixtures")
        add_test(NAME ai COMMAND fa_test_ai WORKING_DIRECTORY ${FA_ROOT})
    endif()
endif()
