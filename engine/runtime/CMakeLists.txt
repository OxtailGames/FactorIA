fa_add_module(runtime
    DEPS fa_core fa_scene fa_platform fa_render fa_physics fa_audio fa_ui fa_services fa_script)
fa_add_tests(runtime)

# The Apple backend plugin (platforms/plugins/apple, Swift): its template is instantiated and built into this build tree, and
# tests/apple_backend_tests.cpp loads it into a real Engine. Only on a Mac with Xcode's Swift; without it that file compiles to nothing.
if(TARGET fa_test_runtime AND CMAKE_SYSTEM_NAME STREQUAL "Darwin" AND CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
    execute_process(COMMAND xcrun --find swiftc OUTPUT_VARIABLE fa_swiftc OUTPUT_STRIP_TRAILING_WHITESPACE RESULT_VARIABLE fa_swiftc_status
                    ERROR_QUIET)
    if(fa_swiftc_status EQUAL 0 AND fa_swiftc)
        set(FA_APPLE_PLUGIN_DIR ${CMAKE_CURRENT_BINARY_DIR}/apple-plugin)
        set(fa_apple_template ${FA_ROOT}/platforms/plugins/apple)
        # What project.new_plugin does: every file with {{NAME}} replaced (a file is rewritten only when its text changes,
        # so the build is not redone at every configure), plus the API header.
        file(GLOB_RECURSE fa_apple_sources CONFIGURE_DEPENDS LIST_DIRECTORIES false ${fa_apple_template}/*)
        list(FILTER fa_apple_sources EXCLUDE REGEX "/build/|\\.(a|dylib|o)$")  # a template someone built in place
        set(fa_apple_instance ${FA_APPLE_PLUGIN_DIR}/include/fa_plugin.h)
        configure_file(${FA_ROOT}/engine/runtime/include/fa/runtime/fa_plugin.h ${FA_APPLE_PLUGIN_DIR}/include/fa_plugin.h COPYONLY)
        foreach(source IN LISTS fa_apple_sources)
            file(RELATIVE_PATH relative ${fa_apple_template} ${source})
            file(READ ${source} text)
            string(REPLACE "{{NAME}}" "apple" text "${text}")
            set(destination ${FA_APPLE_PLUGIN_DIR}/${relative})
            set(current "")
            if(EXISTS ${destination})
                file(READ ${destination} current)
            endif()
            if(NOT current STREQUAL text)
                file(WRITE ${destination} "${text}")
            endif()
            list(APPEND fa_apple_instance ${destination})
        endforeach()
        add_custom_command(OUTPUT ${FA_APPLE_PLUGIN_DIR}/macos/libapple.dylib
            COMMAND ${CMAKE_COMMAND} -S ${FA_APPLE_PLUGIN_DIR} -B ${FA_APPLE_PLUGIN_DIR}/build -DCMAKE_BUILD_TYPE=Release
                    -DFA_APPLE_SLICES=macos
            COMMAND ${CMAKE_COMMAND} --build ${FA_APPLE_PLUGIN_DIR}/build
            DEPENDS ${fa_apple_instance}
            COMMENT "Building the Apple plugin (Swift) for the runtime tests" VERBATIM)
        add_custom_target(fa_apple_plugin DEPENDS ${FA_APPLE_PLUGIN_DIR}/macos/libapple.dylib)
        add_dependencies(fa_test_runtime fa_apple_plugin)
        target_compile_definitions(fa_test_runtime PRIVATE FA_APPLE_PLUGIN_DIR="${FA_APPLE_PLUGIN_DIR}")
        target_link_libraries(fa_test_runtime PRIVATE "-framework CoreFoundation")
    else()
        message(STATUS "Swift not found (xcrun --find swiftc): the Apple backend plugin is not built, its tests are skipped")
    endif()
endif()

# Real-window check of window.* (needs a display; runs under xvfb when available). Alone in its process: sokol_gfx is a
# singleton, so it is filtered away from the "windowed smoke" case.
find_program(FA_XVFB_RUN xvfb-run)
if(TARGET fa_test_runtime AND FA_XVFB_RUN AND FA_PLATFORM STREQUAL "linux")
    add_test(NAME runtime_windowed_fullscreen
        COMMAND ${CMAKE_COMMAND} -E env FA_WINDOWED_SMOKE=1 ${FA_XVFB_RUN} -a -s "-screen 0 1280x720x24"
                $<TARGET_FILE:fa_test_runtime> "-tc=windowed fullscreen*"
        WORKING_DIRECTORY ${FA_ROOT})
endif()
