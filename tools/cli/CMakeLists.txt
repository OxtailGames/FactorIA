# `factoria`: the single developer binary (CLI + headless runner + MCP server +
# AI agent + editor). See docs/CLI.md.
# fa_cli holds everything except main() so tests can call fa::cli::cli_main in-process.
file(GLOB cli_srcs CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)
list(FILTER cli_srcs EXCLUDE REGEX "/main\\.cpp$")
add_library(fa_cli STATIC ${cli_srcs})
target_include_directories(fa_cli PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
target_link_libraries(fa_cli PUBLIC fa_tooling fa_mcp fa_dap fa_ai PRIVATE fa_warnings)
if(TARGET fa_editor)
    target_link_libraries(fa_cli PUBLIC fa_editor)
    target_compile_definitions(fa_cli PRIVATE FA_WITH_EDITOR=1)
endif()

add_executable(factoria ${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp)
target_link_libraries(factoria PRIVATE fa_cli fa_warnings)

# Windows: the FactorIA icon and name (version resource) in factoria.exe and FactorIA-Editor.exe (windows/factoria.rc).
# CMake compiles .rc files with rc.exe (MSVC) or windres (MinGW); the include directories are where both look for the
# .ico and the generated factoria_version.h.
if(WIN32)
    set(fa_cli_rc ${CMAKE_CURRENT_SOURCE_DIR}/windows/factoria.rc)
    set(fa_cli_rc_includes ${CMAKE_CURRENT_SOURCE_DIR}/windows ${CMAKE_CURRENT_BINARY_DIR}/windows)
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/windows/factoria_version.h.in
                   ${CMAKE_CURRENT_BINARY_DIR}/windows/factoria_version.h @ONLY)
    set_source_files_properties(${fa_cli_rc} PROPERTIES OBJECT_DEPENDS
        "${CMAKE_CURRENT_SOURCE_DIR}/windows/factoria.ico;${CMAKE_CURRENT_BINARY_DIR}/windows/factoria_version.h")
    target_sources(factoria PRIVATE ${fa_cli_rc})
    target_include_directories(factoria PRIVATE ${fa_cli_rc_includes})
endif()

# Windows: FactorIA-Editor.exe opens the editor without a console window (factoria.exe is a console program).
# Not "FactorIA.exe": Windows file names ignore case, so it would be factoria.exe.
if(WIN32 AND TARGET fa_editor)
    add_executable(factoria_editor_launcher WIN32 ${CMAKE_CURRENT_SOURCE_DIR}/launcher/editor_launcher_win32.cpp ${fa_cli_rc})
    target_include_directories(factoria_editor_launcher PRIVATE ${fa_cli_rc_includes})
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

        # factoria_player --input / --dump-state / --screenshot: an exported build plays a replay headless and its state and
        # screenshot equal `factoria run`'s (offscreen GPU: label gpu).
        add_test(NAME cli_player_replay
            COMMAND ${Python3_EXECUTABLE} -I ${CMAKE_CURRENT_SOURCE_DIR}/tests/player_replay_test.py $<TARGET_FILE:factoria>
                    $<TARGET_FILE:factoria_player>
            WORKING_DIRECTORY ${FA_ROOT})
        set_tests_properties(cli_player_replay PROPERTIES TIMEOUT 300 LABELS "gpu")

        # Larkspur Lodge on the exported player: a replay that presses Play, skips the intro and saves in slot 1 leaves a real
        # save file with --persist-storage (the check of a sandboxed build, LL/FB-0801).
        add_test(NAME cli_larkspur_ship
            COMMAND ${Python3_EXECUTABLE} -I ${CMAKE_CURRENT_SOURCE_DIR}/tests/larkspur_ship_test.py $<TARGET_FILE:factoria>
                    $<TARGET_FILE:factoria_player>
            WORKING_DIRECTORY ${FA_ROOT})
        set_tests_properties(cli_larkspur_ship PROPERTIES TIMEOUT 600 LABELS "gpu")

        # factoria dap: the Debug Adapter Protocol server driven over stdio (breakpoint, stack, locals, evaluate, step, logpoint,
        # test mode, disconnect). Headless GPU may be created for test mode: label gpu.
        add_test(NAME cli_dap
            COMMAND ${Python3_EXECUTABLE} -I ${CMAKE_CURRENT_SOURCE_DIR}/tests/dap_test.py $<TARGET_FILE:factoria>
            WORKING_DIRECTORY ${FA_ROOT})
        set_tests_properties(cli_dap PROPERTIES TIMEOUT 600 LABELS "gpu")

        # factoria mcp after an update: a copy of the binary is replaced under a running server (restart in place, list_changed,
        # the notice in the first tool result) and a project .mcp.json without a timeout is fixed and reported.
        add_test(NAME cli_mcp_update
            COMMAND ${Python3_EXECUTABLE} -I ${CMAKE_CURRENT_SOURCE_DIR}/tests/mcp_update_test.py $<TARGET_FILE:factoria>
            WORKING_DIRECTORY ${FA_ROOT})
        set_tests_properties(cli_mcp_update PROPERTIES TIMEOUT 300)
    endif()
endif()

# The example games (examples/*) are integration tests too: each must validate cleanly and pass its
# own JS tests. They were written by AI agents through the public interface only, so a failure here
# usually means a behaviour change that would also break games made by users.
if(FA_BUILD_TESTS)
    # CONFIGURE_DEPENDS: a new example becomes a test at the next build, without a manual re-configure.
    file(GLOB FA_EXAMPLE_PROJECTS LIST_DIRECTORIES true CONFIGURE_DEPENDS ${FA_ROOT}/examples/*)
    set(fa_perf_require false)
    if(DEFINED ENV{CI} AND NOT "$ENV{CI}" STREQUAL "" AND NOT "$ENV{CI}" STREQUAL "0" AND NOT "$ENV{CI}" STREQUAL "false")
        set(fa_perf_require true)
    endif()
    # Scripts run several times slower in a Debug build: Clockwork Courier's tests take about 50 s in Release (CI) and
    # 250-420 s in Debug on a busy developer machine.
    set(fa_example_timeout 300)
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(fa_example_timeout 900)
    endif()
    foreach(ex ${FA_EXAMPLE_PROJECTS})
        if(EXISTS ${ex}/factoria.json)
            get_filename_component(ex_name ${ex} NAME)
            add_test(NAME example_${ex_name}_validate COMMAND factoria validate ${ex} WORKING_DIRECTORY ${FA_ROOT})
            add_test(NAME example_${ex_name}_test COMMAND factoria test ${ex} WORKING_DIRECTORY ${FA_ROOT})
            set_tests_properties(example_${ex_name}_test PROPERTIES LABELS "gpu" TIMEOUT ${fa_example_timeout})
            # Performance budget (docs/PERFORMANCE.md): a fixed number of frames with the GPU renderer, compared with the
            # baseline of this runner in tests/perf/<example>.perf.json. Memory and draw calls fail always, a time only in CI
            # (the CI environment variable). A runner with no baseline fails in CI and prints the entry to commit; on a
            # developer machine it passes.
            # One example may measure several scenes: <example>.perf.json and <example>-*.perf.json (not <example>*, which
            # would catch another example with the same prefix). Each file names its scene.
            file(GLOB ex_perf_files CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/tests/perf/${ex_name}.perf.json
                ${CMAKE_CURRENT_SOURCE_DIR}/tests/perf/${ex_name}-*.perf.json)
            foreach(perf_file ${ex_perf_files})
                get_filename_component(perf_name ${perf_file} NAME)
                string(REGEX REPLACE "\\.perf\\.json$" "" perf_name "${perf_name}")
                file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/perf/${perf_name}.args.json
                    "{\"file\":\"${perf_file}\",\"requireBaseline\":${fa_perf_require}}")
                add_test(NAME example_${perf_name}_perf
                    COMMAND factoria call --no-graphics --project ${ex} perf.check @${CMAKE_CURRENT_BINARY_DIR}/perf/${perf_name}.args.json
                    WORKING_DIRECTORY ${FA_ROOT})
                set_tests_properties(example_${perf_name}_perf PROPERTIES LABELS "gpu;perf" TIMEOUT 600)
            endforeach()
        endif()
    endforeach()
    # The menu kit of docs/MENUS.md as a project, checked the same way and driven with a gamepad only.
    set(fx ${CMAKE_CURRENT_SOURCE_DIR}/tests/fixtures/menus)
    add_test(NAME fixture_menus_validate COMMAND factoria validate ${fx} WORKING_DIRECTORY ${FA_ROOT})
    add_test(NAME fixture_menus_test COMMAND factoria test ${fx} WORKING_DIRECTORY ${FA_ROOT})
    set_tests_properties(fixture_menus_test PROPERTIES LABELS "gpu" TIMEOUT 300)
    # 2D bones, skinned sprites and IK (docs/ANIMATION.md, "Bones and IK"): 50 skinned sprites, 10 of them with IK2D, in one
    # draw call. Its budget is the perf case of the package: tests/perf/skinned-sprites.perf.json.
    set(fx ${CMAKE_CURRENT_SOURCE_DIR}/tests/fixtures/skinned-sprites)
    add_test(NAME fixture_skinned_sprites_validate COMMAND factoria validate ${fx} WORKING_DIRECTORY ${FA_ROOT})
    add_test(NAME fixture_skinned_sprites_test COMMAND factoria test ${fx} WORKING_DIRECTORY ${FA_ROOT})
    set_tests_properties(fixture_skinned_sprites_test PROPERTIES LABELS "gpu" TIMEOUT 300)
    file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/perf/skinned-sprites.args.json
        "{\"file\":\"${CMAKE_CURRENT_SOURCE_DIR}/tests/perf/skinned-sprites.perf.json\",\"requireBaseline\":${fa_perf_require}}")
    add_test(NAME fixture_skinned_sprites_perf
        COMMAND factoria call --no-graphics --project ${fx} perf.check @${CMAKE_CURRENT_BINARY_DIR}/perf/skinned-sprites.args.json
        WORKING_DIRECTORY ${FA_ROOT})
    set_tests_properties(fixture_skinned_sprites_perf PROPERTIES LABELS "gpu;perf" TIMEOUT 600)
    set(fx ${CMAKE_CURRENT_SOURCE_DIR}/tests/fixtures/menus)
    # The budget check must fail on a game heavier than its baseline: tests/perf/regression.perf.json holds an impossibly
    # small baseline for the runner id "regression-test" (FACTORIA_PERF_RUNNER), so memory and draw calls are over it.
    file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/perf/regression.args.json "{\"file\":\"${CMAKE_CURRENT_SOURCE_DIR}/tests/perf/regression.perf.json\"}")
    add_test(NAME perf_regression_detected
        COMMAND factoria call --no-graphics --project ${fx} perf.check @${CMAKE_CURRENT_BINARY_DIR}/perf/regression.args.json
        WORKING_DIRECTORY ${FA_ROOT})
    set_tests_properties(perf_regression_detected PROPERTIES LABELS "gpu;perf" TIMEOUT 300
        ENVIRONMENT "FACTORIA_PERF_RUNNER=regression-test" PASS_REGULAR_EXPRESSION "perf_budget_exceeded")
    # The finished project of docs/MAKE_BY_HAND.md. Tutorial and fixture are one thing: when one changes, change the other
    # (the `cli` test "docs/MAKE_BY_HAND.md: every file it gives is the tested fixture's" fails when they differ).
    set(fx ${CMAKE_CURRENT_SOURCE_DIR}/tests/fixtures/gem-grab)
    add_test(NAME fixture_gem_grab_validate COMMAND factoria validate ${fx} WORKING_DIRECTORY ${FA_ROOT})
    add_test(NAME fixture_gem_grab_test COMMAND factoria test ${fx} WORKING_DIRECTORY ${FA_ROOT})
    set_tests_properties(fixture_gem_grab_test PROPERTIES LABELS "gpu" TIMEOUT 300)
endif()
