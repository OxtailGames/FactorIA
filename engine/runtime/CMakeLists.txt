fa_add_module(runtime
    DEPS fa_core fa_scene fa_platform fa_render fa_physics fa_audio fa_ui fa_services fa_script)
fa_add_tests(runtime)

# Real-window check of window.* (needs a display; runs under xvfb when available). Alone in its process: sokol_gfx is a
# singleton, so it is filtered away from the "windowed smoke" case.
find_program(FA_XVFB_RUN xvfb-run)
if(TARGET fa_test_runtime AND FA_XVFB_RUN AND FA_PLATFORM STREQUAL "linux")
    add_test(NAME runtime_windowed_fullscreen
        COMMAND ${CMAKE_COMMAND} -E env FA_WINDOWED_SMOKE=1 ${FA_XVFB_RUN} -a -s "-screen 0 1280x720x24"
                $<TARGET_FILE:fa_test_runtime> "-tc=windowed fullscreen*"
        WORKING_DIRECTORY ${FA_ROOT})
endif()
