# Tests of the Steam backend plugin (platforms/plugins/steam/): the plugin is built from its template sources, with the
# name "steam", next to a mock of the Steamworks redistributable, and an Engine runs it with platformBackend="steam".
# Nothing of Valve's is involved: the mock (mock_steam_api.cpp) is a shared library with the file name of the real one that
# keeps everything in memory. Added by the root CMakeLists.txt when FA_BUILD_TESTS is on, on desktop.
#
# One ctest entry per scenario, each its own process: a plugin is loaded once per process (and a failed start is
# remembered), so "Steam is not running" and "Steam is running" cannot share one.

set(steam_dir ${CMAKE_CURRENT_LIST_DIR}/..)
file(GLOB steam_sources CONFIGURE_DEPENDS ${steam_dir}/src/*.cpp)

# The plugin, built like the template builds it (CMakeLists.txt there), but not copied into the source tree.
add_library(fa_steam_plugin SHARED ${steam_sources})
target_include_directories(fa_steam_plugin PRIVATE ${FA_ROOT}/engine/runtime/include/fa/runtime)
target_compile_definitions(fa_steam_plugin PRIVATE FA_PLUGIN_NAME=steam)
target_compile_features(fa_steam_plugin PRIVATE cxx_std_17)
target_link_libraries(fa_steam_plugin PRIVATE ${CMAKE_DL_LIBS} fa_warnings)
set_target_properties(fa_steam_plugin PROPERTIES CXX_VISIBILITY_PRESET hidden VISIBILITY_INLINES_HIDDEN ON
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/plugin RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/plugin)
if(MSVC)
    set_property(TARGET fa_steam_plugin PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()

# The mock Steamworks library, in four variants of the same source (each in its own folder: the file name is the real one).
#   current  the SDK 1.62 to 1.64 interface versions, SteamAPI_InitFlat
#   legacy   the SDK 1.58 to 1.60 ones: no InitFlat, older accessors, stats that must be requested
#   next     one interface version above the newest the plugin knows (what SDK 1.65 does to ISteamUtils): used, with a warning
#   future   interface versions far above the ones the plugin knows: refused
if(WIN32)
    set(steam_mock_name steam_api64)
    set(steam_mock_prefix "")
else()
    set(steam_mock_name steam_api)
    set(steam_mock_prefix lib)
endif()
foreach(variant current legacy next future)
    add_library(fa_steam_mock_${variant} SHARED ${CMAKE_CURRENT_LIST_DIR}/mock_steam_api.cpp)
    target_include_directories(fa_steam_mock_${variant} PRIVATE ${steam_dir}/src)
    target_compile_features(fa_steam_mock_${variant} PRIVATE cxx_std_17)
    target_link_libraries(fa_steam_mock_${variant} PRIVATE fa_ext_json fa_warnings)
    set_target_properties(fa_steam_mock_${variant} PROPERTIES OUTPUT_NAME ${steam_mock_name} PREFIX "${steam_mock_prefix}"
        CXX_VISIBILITY_PRESET hidden VISIBILITY_INLINES_HIDDEN ON
        LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/mock_${variant}
        RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/mock_${variant})
    if(MSVC)
        set_property(TARGET fa_steam_mock_${variant} PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    endif()
endforeach()
target_compile_definitions(fa_steam_mock_legacy PRIVATE MOCK_LEGACY=1)
target_compile_definitions(fa_steam_mock_next PRIVATE MOCK_NEXT=1)
target_compile_definitions(fa_steam_mock_future PRIVATE MOCK_FUTURE=1)

# The test program: an Engine that runs the plugin.
add_executable(fa_test_steam_plugin ${CMAKE_CURRENT_LIST_DIR}/steam_plugin_tests.cpp ${FA_ROOT}/cmake/doctest_main.cpp)
target_link_libraries(fa_test_steam_plugin PRIVATE fa_runtime fa_ext_doctest fa_warnings ${CMAKE_DL_LIBS})
target_compile_definitions(fa_test_steam_plugin PRIVATE
    FA_STEAM_PLUGIN_FILE="$<TARGET_FILE:fa_steam_plugin>"
    FA_STEAM_MOCK_CURRENT="$<TARGET_FILE:fa_steam_mock_current>"
    FA_STEAM_MOCK_LEGACY="$<TARGET_FILE:fa_steam_mock_legacy>"
    FA_STEAM_MOCK_NEXT="$<TARGET_FILE:fa_steam_mock_next>"
    FA_STEAM_MOCK_FUTURE="$<TARGET_FILE:fa_steam_mock_future>"
    FA_STEAM_TEST_EXE="$<TARGET_FILE:fa_test_steam_plugin>")
add_dependencies(fa_test_steam_plugin fa_steam_plugin fa_steam_mock_current fa_steam_mock_legacy fa_steam_mock_next fa_steam_mock_future)

# scenario name -> doctest filter. "next" runs the services scenario again on the "next" mock (the test program picks the
# library from FA_STEAM_TEST_VARIANT) plus the test that checks the warning. The working directory is the build folder: the
# plugin also looks for a steam_appid.txt in the folder the game started in, and the repository root must not decide that.
set(steam_scenarios
    "services|steam services*"
    "legacy|steam legacy*"
    "next|steam services*,steam next*"
    "future|steam future*"
    "no_library|steam without library*"
    "not_running|steam not running*"
    "no_app_id|steam without app id*"
    "exit|steam exit*")
foreach(scenario ${steam_scenarios})
    string(REPLACE "|" ";" parts "${scenario}")
    list(GET parts 0 scenario_name)
    list(GET parts 1 scenario_filter)
    add_test(NAME steam_plugin_${scenario_name}
        COMMAND fa_test_steam_plugin "--test-case=${scenario_filter}"
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
endforeach()
set_tests_properties(steam_plugin_next PROPERTIES ENVIRONMENT "FA_STEAM_TEST_VARIANT=next")
