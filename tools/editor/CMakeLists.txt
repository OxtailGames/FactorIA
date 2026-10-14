# fa_editor: the visual editor (Dear ImGui docking + sokol). Entry point:
# fa::run_editor() in <fa/editor/editor.h>, called by `factoria editor`.
add_library(fa_editor STATIC)
file(GLOB_RECURSE editor_srcs CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)
target_sources(fa_editor PRIVATE ${editor_srcs})
target_include_directories(fa_editor PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
target_link_libraries(fa_editor PUBLIC fa_tooling PRIVATE fa_warnings)
target_link_libraries(fa_editor PUBLIC fa_ai fa_mcp PRIVATE fa_ext_imgui fa_ext_sokol)
target_link_libraries(fa_editor PRIVATE ${CMAKE_DL_LIBS})

# The editor UI font (DejaVu Sans) is embedded; header "editor_fonts.h", namespace fa_editor_fonts.
fa_embed_files(fa_editor fa_editor_fonts editor_fonts
    FILES ${FA_ROOT}/engine/render/assets/fonts/DejaVuSans.ttf
    BASE ${FA_ROOT}/engine/render/assets/fonts)
# Monospaced font (DejaVu Sans Mono, same license) for text boxes where columns must line up: ASCII level rows, JSON.
fa_embed_files(fa_editor fa_editor_mono editor_mono_font
    FILES ${CMAKE_CURRENT_SOURCE_DIR}/assets/fonts/DejaVuSansMono.ttf
    BASE ${CMAKE_CURRENT_SOURCE_DIR}/assets/fonts)

# The sokol_imgui implementation TU embeds third-party code: relax warnings there.
if(MSVC)
    set_source_files_properties(src/imgui_backend.cpp PROPERTIES COMPILE_OPTIONS "/w")
else()
    set_source_files_properties(src/imgui_backend.cpp PROPERTIES COMPILE_OPTIONS "-w")
endif()

if(FA_BUILD_TESTS)
    file(GLOB editor_tests CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/tests/*.cpp)
    if(editor_tests)
        add_executable(fa_test_editor ${editor_tests} ${FA_ROOT}/cmake/doctest_main.cpp)
        target_link_libraries(fa_test_editor PRIVATE fa_editor fa_ext_imgui fa_ext_sokol fa_ext_doctest fa_warnings)
        target_include_directories(fa_test_editor PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
        target_compile_definitions(fa_test_editor PRIVATE FA_REPO_ROOT="${FA_ROOT}")
        add_test(NAME editor COMMAND fa_test_editor WORKING_DIRECTORY ${FA_ROOT})
    endif()
    # Windowed end-to-end test: opens a temp project in the real editor window,
    # exercises select/inspect/undo/play/stop/AI marshaling and writes screenshots.
    file(GLOB editor_autotest CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/tests/gpu/*.cpp)
    find_program(FA_XVFB_RUN_EDITOR xvfb-run)
    if(editor_autotest)
        add_executable(fa_editor_autotest ${editor_autotest})
        target_link_libraries(fa_editor_autotest PRIVATE fa_editor fa_warnings)
        if(FA_XVFB_RUN_EDITOR AND FA_PLATFORM STREQUAL "linux")
            add_test(NAME editor_autotest
                COMMAND ${FA_XVFB_RUN_EDITOR} -a -s "-screen 0 1600x900x24" $<TARGET_FILE:fa_editor_autotest>
                WORKING_DIRECTORY ${FA_ROOT})
            set_tests_properties(editor_autotest PROPERTIES LABELS "gpu" RUN_SERIAL TRUE TIMEOUT 180
                ENVIRONMENT "FA_EDITOR_AUTOTEST=1")
            # No-project start: welcome dialog, then Open/New switches to a real project (graphics teardown/rebuild).
            add_test(NAME editor_autotest_welcome
                COMMAND ${FA_XVFB_RUN_EDITOR} -a -s "-screen 0 1600x900x24" $<TARGET_FILE:fa_editor_autotest>
                WORKING_DIRECTORY ${FA_ROOT})
            set_tests_properties(editor_autotest_welcome PROPERTIES LABELS "gpu" RUN_SERIAL TRUE TIMEOUT 120
                ENVIRONMENT "FA_EDITOR_AUTOTEST=welcome")
        endif()
    endif()
endif()
