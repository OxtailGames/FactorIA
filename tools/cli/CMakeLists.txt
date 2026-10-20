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

# Windows: FactorIA-Editor.exe opens the editor without a console window (factoria.exe is a console program).
# Not "FactorIA.exe": Windows file names ignore case, so it would be factoria.exe.
if(WIN32 AND TARGET fa_editor)
    add_executable(factoria_editor_launcher WIN32 ${CMAKE_CURRENT_SOURCE_DIR}/launcher/editor_launcher_win32.cpp)
    set_target_properties(factoria_editor_launcher PROPERTIES OUTPUT_NAME FactorIA-Editor)
    target_link_libraries(factoria_editor_launcher PRIVATE fa_warnings)
    if(MINGW)
        target_link_options(factoria_editor_launcher PRIVATE -municode)
    endif()
    add_dependencies(factoria_editor_launcher factoria)
endif()

if(FA_BUILD_TESTS)
    file(GLOB cli_tests CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/tests/*.cpp)
    if(cli_tests)
        add_executable(fa_test_cli ${cli_tests} ${FA_ROOT}/cmake/doctest_main.cpp)
        target_link_libraries(fa_test_cli PRIVATE fa_cli fa_ext_doctest fa_warnings)
        target_include_directories(fa_test_cli PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)  # common.h: Session, run_project_tests
        target_include_directories(fa_test_cli PRIVATE ${FA_GENERATED_DIR})  # fa_test_paths.h: FA_REPO_ROOT
        add_test(NAME cli COMMAND fa_test_cli WORKING_DIRECTORY ${FA_ROOT})
    endif()

    # End-to-end: drives the real binary (new/validate/run/test/call/mcp) for every template.
    find_package(Python3 COMPONENTS Interpreter)
    if(Python3_FOUND)
        add_test(NAME cli_integration
            COMMAND ${Python3_EXECUTABLE} -I ${CMAKE_CURRENT_SOURCE_DIR}/tests/integration.py $<TARGET_FILE:factoria>
            WORKING_DIRECTORY ${FA_ROOT})
        # Template JS tests must pass (strict): templates are what every new game starts from.
        set_tests_properties(cli_integration PROPERTIES TIMEOUT 600 ENVIRONMENT "FA_CLI_STRICT_TESTS=1" LABELS "gpu")

        # Native plugins end to end: the template plugin (platforms/plugin) built as the plugin "example", loaded by
        # `factoria run` and by the game `factoria export` makes (which opens a window: label gpu).
        add_library(fa_test_plugin_example SHARED ${FA_ROOT}/platforms/plugin/src/plugin.c)
        target_include_directories(fa_test_plugin_example PRIVATE ${FA_ROOT}/engine/runtime/include/fa/runtime)
        target_compile_definitions(fa_test_plugin_example PRIVATE FA_PLUGIN_NAME=example)
        set_target_properties(fa_test_plugin_example PROPERTIES OUTPUT_NAME example C_VISIBILITY_PRESET hidden)
        add_test(NAME cli_plugin
            COMMAND ${Python3_EXECUTABLE} -I ${CMAKE_CURRENT_SOURCE_DIR}/tests/plugin_test.py $<TARGET_FILE:factoria>
                    $<TARGET_FILE:fa_test_plugin_example> $<TARGET_FILE:factoria_player>
            WORKING_DIRECTORY ${FA_ROOT})
        set_tests_properties(cli_plugin PROPERTIES TIMEOUT 300 LABELS "gpu")

        # factoria_player --frames N: exits 0 after N frames, 1 after a script error (opens a window: label gpu).
        add_test(NAME cli_player_frames
            COMMAND ${Python3_EXECUTABLE} -I ${CMAKE_CURRENT_SOURCE_DIR}/tests/player_frames_test.py $<TARGET_FILE:factoria>
                    $<TARGET_FILE:factoria_player>
            WORKING_DIRECTORY ${FA_ROOT})
        set_tests_properties(cli_player_frames PROPERTIES TIMEOUT 300 LABELS "gpu")
    endif()
endif()

# The example games (examples/*) are integration tests too: each must validate cleanly and pass its
# own JS tests. They were written by AI agents through the public interface only, so a failure here
# usually means a behaviour change that would also break games made by users.
if(FA_BUILD_TESTS)
    # CONFIGURE_DEPENDS: a new example becomes a test at the next build, without a manual re-configure.
    file(GLOB FA_EXAMPLE_PROJECTS LIST_DIRECTORIES true CONFIGURE_DEPENDS ${FA_ROOT}/examples/*)
    foreach(ex ${FA_EXAMPLE_PROJECTS})
        if(EXISTS ${ex}/factoria.json)
            get_filename_component(ex_name ${ex} NAME)
            add_test(NAME example_${ex_name}_validate COMMAND factoria validate ${ex} WORKING_DIRECTORY ${FA_ROOT})
            add_test(NAME example_${ex_name}_test COMMAND factoria test ${ex} WORKING_DIRECTORY ${FA_ROOT})
            set_tests_properties(example_${ex_name}_test PROPERTIES LABELS "gpu" TIMEOUT 300)
        endif()
    endforeach()
    # The menu kit of docs/MENUS.md as a project, checked the same way and driven with a gamepad only.
    set(fx ${CMAKE_CURRENT_SOURCE_DIR}/tests/fixtures/menus)
    add_test(NAME fixture_menus_validate COMMAND factoria validate ${fx} WORKING_DIRECTORY ${FA_ROOT})
    add_test(NAME fixture_menus_test COMMAND factoria test ${fx} WORKING_DIRECTORY ${FA_ROOT})
    set_tests_properties(fixture_menus_test PROPERTIES LABELS "gpu" TIMEOUT 300)
    # The finished project of docs/MAKE_BY_HAND.md. Tutorial and fixture are one thing: when one changes, change the other
    # (the `cli` test "docs/MAKE_BY_HAND.md: every file it gives is the tested fixture's" fails when they differ).
    set(fx ${CMAKE_CURRENT_SOURCE_DIR}/tests/fixtures/gem-grab)
    add_test(NAME fixture_gem_grab_validate COMMAND factoria validate ${fx} WORKING_DIRECTORY ${FA_ROOT})
    add_test(NAME fixture_gem_grab_test COMMAND factoria test ${fx} WORKING_DIRECTORY ${FA_ROOT})
    set_tests_properties(fixture_gem_grab_test PROPERTIES LABELS "gpu" TIMEOUT 300)
endif()
