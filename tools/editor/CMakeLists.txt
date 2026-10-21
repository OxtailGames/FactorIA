# fa_editor: the visual editor (Dear ImGui docking + sokol). Entry point:
# fa::run_editor() in <fa/editor/editor.h>, called by `factoria editor`.
add_library(fa_editor STATIC)
file(GLOB_RECURSE editor_srcs CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)
if(APPLE)
    # *_apple.mm: Metal window read-back for the autotest screenshots.
    file(GLOB_RECURSE editor_objc_srcs CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/*_apple.mm)
    set_source_files_properties(${editor_objc_srcs} PROPERTIES COMPILE_OPTIONS "-fobjc-arc")
    list(APPEND editor_srcs ${editor_objc_srcs})
endif()
target_sources(fa_editor PRIVATE ${editor_srcs})
target_include_directories(fa_editor PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
target_link_libraries(fa_editor PUBLIC fa_tooling PRIVATE fa_warnings)
target_link_libraries(fa_editor PUBLIC fa_ai fa_mcp PRIVATE fa_ext_imgui fa_ext_sokol)
target_link_libraries(fa_editor PRIVATE ${CMAKE_DL_LIBS})
set_property(SOURCE src/update.cpp APPEND PROPERTY COMPILE_DEFINITIONS FA_UPDATE_REPO="${FA_UPDATE_REPO}")
if(WIN32)
    target_link_libraries(fa_editor PRIVATE ole32 shell32 uuid)  # folder_picker.cpp: IFileOpenDialog
endif()

# The editor UI font (DejaVu Sans) is embedded; header "editor_fonts.h", namespace fa_editor_fonts.
fa_embed_files(fa_editor fa_editor_fonts editor_fonts
    FILES ${FA_ROOT}/engine/render/assets/fonts/DejaVuSans.ttf
    BASE ${FA_ROOT}/engine/render/assets/fonts)

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
        target_include_directories(fa_test_editor PRIVATE ${FA_GENERATED_DIR})  # fa_test_paths.h: FA_REPO_ROOT
        add_test(NAME editor COMMAND fa_test_editor WORKING_DIRECTORY ${FA_ROOT})
    endif()
    # Windowed end-to-end test: opens a temp project in the real editor window,
    # exercises select/edit commands/undo/play/stop/AI marshaling and writes screenshots.
    # Window screenshots read the back buffer (ui::read_backbuffer): GL on Linux, under xvfb-run, and Metal on macOS and D3D11 on
    # Windows (swap chain buffer copied to a staging texture), in a real window (the user's session).
    file(GLOB editor_autotest CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/tests/gpu/*.cpp)
    find_program(FA_XVFB_RUN_EDITOR xvfb-run)
    if(editor_autotest)
        add_executable(fa_editor_autotest ${editor_autotest})
        target_link_libraries(fa_editor_autotest PRIVATE fa_editor fa_warnings)
        set(editor_autotest_launcher "")
        set(editor_autotest_runs OFF)
        if(FA_XVFB_RUN_EDITOR AND FA_PLATFORM STREQUAL "linux")
            set(editor_autotest_launcher ${FA_XVFB_RUN_EDITOR} -a -s "-screen 0 1600x900x24")
            set(editor_autotest_runs ON)
        elseif(FA_PLATFORM STREQUAL "macos" OR FA_PLATFORM STREQUAL "windows")
            set(editor_autotest_runs ON)
        endif()
        if(editor_autotest_runs)
            add_test(NAME editor_autotest
                COMMAND ${editor_autotest_launcher} $<TARGET_FILE:fa_editor_autotest>
                WORKING_DIRECTORY ${FA_ROOT})
            set_tests_properties(editor_autotest PROPERTIES LABELS "gpu" RUN_SERIAL TRUE TIMEOUT 180
                ENVIRONMENT "FA_EDITOR_AUTOTEST=1")
            # No-project start: welcome dialog, then Open/New switches to a real project (graphics teardown/rebuild).
            add_test(NAME editor_autotest_welcome
                COMMAND ${editor_autotest_launcher} $<TARGET_FILE:fa_editor_autotest>
                WORKING_DIRECTORY ${FA_ROOT})
            set_tests_properties(editor_autotest_welcome PROPERTIES LABELS "gpu" RUN_SERIAL TRUE TIMEOUT 120
                ENVIRONMENT "FA_EDITOR_AUTOTEST=welcome")
        endif()
    endif()
endif()
