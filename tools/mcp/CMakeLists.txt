add_library(fa_mcp STATIC)
file(GLOB_RECURSE mcp_srcs CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)
# Host-platform files (stdio_reader_posix.cpp / _win32.cpp, update_restart_posix.cpp / _win32.cpp).
if(WIN32)
    list(FILTER mcp_srcs EXCLUDE REGEX "_posix\\.cpp$")
else()
    list(FILTER mcp_srcs EXCLUDE REGEX "_win32\\.cpp$")
endif()
target_sources(fa_mcp PRIVATE ${mcp_srcs})
target_include_directories(fa_mcp PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
target_link_libraries(fa_mcp PUBLIC fa_tooling PRIVATE fa_warnings)
if(WIN32)
    target_link_libraries(fa_mcp PRIVATE ws2_32)  # http_server.cpp
endif()
if(FA_BUILD_TESTS)
    file(GLOB_RECURSE mcp_tests CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/tests/*.cpp)
    if(mcp_tests)
        add_executable(fa_test_mcp ${mcp_tests} ${FA_ROOT}/cmake/doctest_main.cpp)
        # fa_ai: its HTTP client and the fake CLI fixtures drive the HTTP endpoint end to end.
        target_link_libraries(fa_test_mcp PRIVATE fa_mcp fa_ai fa_ext_doctest fa_warnings)
        target_include_directories(fa_test_mcp PRIVATE ${FA_GENERATED_DIR})  # fa_test_paths.h: FA_AI_FIXTURES...
        add_test(NAME mcp COMMAND fa_test_mcp WORKING_DIRECTORY ${FA_ROOT})
    endif()
endif()
