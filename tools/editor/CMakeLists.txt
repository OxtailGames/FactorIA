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

# The FactorIA icon (window and Dock; tools/editor/icon/make_icons.py makes it); header "editor_icon.h", namespace
# fa_editor_icon.
file(GLOB editor_icon_pngs CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/icon/*.png)
fa_embed_files(fa_editor fa_editor_icon editor_icon FILES ${editor_icon_pngs} BASE ${CMAKE_CURRENT_SOURCE_DIR}/icon)

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
        set(editor_autotest_runs OFF)
        set(editor_autotest_xvfb OFF)
        if(FA_XVFB_RUN_EDITOR AND FA_PLATFORM STREQUAL "linux")
            set(editor_autotest_runs ON)
            set(editor_autotest_xvfb ON)
        elseif(FA_PLATFORM STREQUAL "macos" OR FA_PLATFORM STREQUAL "windows")
            set(editor_autotest_runs ON)
        endif()
        if(editor_autotest_runs)
            # The sections of the autotest (src/autotest_sections.h) in four ctest entries that ctest -j runs at the same time,
            # each in its own window, temp project and output folder (test-output/editor/<entry>, uploaded by CI on failure).
            # Balanced by the frames each section draws (the table a run prints at the end: about 750 per entry); E, F and N
            # share an entry because they use the system clipboard. FA_EDITOR_AUTOTEST=1 alone still plays every section in one
            # window, and FA_EDITOR_AUTOTEST_SECTIONS=K,M only those (docs/EDITOR.md).
            set(editor_autotest_entries
                "1:I,J,Q,R,U,X,Z,D2"
                "2:S,A,G,H,L,V,B2,C2,E2"
                "3:B,C,D,M,O,P,W"
                "4:T,A2,E,F,K,N,Y")
            set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/autotest_sections.h)
            file(STRINGS ${CMAKE_CURRENT_SOURCE_DIR}/src/autotest_sections.h editor_autotest_rows REGEX "^ *\\{\"[A-Z0-9]+\", ")
            set(editor_autotest_ids "")
            foreach(editor_autotest_row IN LISTS editor_autotest_rows)
                string(REGEX REPLACE "^ *\\{\"([A-Z0-9]+)\".*" "\\1" editor_autotest_id "${editor_autotest_row}")
                list(APPEND editor_autotest_ids ${editor_autotest_id})
            endforeach()
            list(JOIN editor_autotest_ids ", " editor_autotest_all)
            set(editor_autotest_seen "")
            set(editor_autotest_server 110)
            foreach(editor_autotest_entry IN LISTS editor_autotest_entries)
                string(REPLACE ":" ";" editor_autotest_parts "${editor_autotest_entry}")
                list(GET editor_autotest_parts 0 editor_autotest_n)
                list(GET editor_autotest_parts 1 editor_autotest_sections)
                string(REPLACE "," ";" editor_autotest_picked "${editor_autotest_sections}")
                foreach(editor_autotest_id IN LISTS editor_autotest_picked)
                    if(NOT editor_autotest_id IN_LIST editor_autotest_ids)
                        message(FATAL_ERROR "tools/editor/CMakeLists.txt: the ctest entry editor_autotest_${editor_autotest_n} "
                            "names the section '${editor_autotest_id}', which src/autotest_sections.h does not have. Its sections: "
                            "${editor_autotest_all}. Fix the name in editor_autotest_entries.")
                    endif()
                    if(editor_autotest_id IN_LIST editor_autotest_seen)
                        message(FATAL_ERROR "tools/editor/CMakeLists.txt: the section '${editor_autotest_id}' is in two "
                            "editor_autotest entries. Keep it in one of editor_autotest_entries: every section runs exactly once.")
                    endif()
                    list(APPEND editor_autotest_seen ${editor_autotest_id})
                endforeach()
                # Under xvfb-run -a, each entry looks for a free display from its own number: two entries starting at the same
                # moment would otherwise both take the first free one, and one Xvfb would fail to start.
                set(editor_autotest_launcher "")
                if(editor_autotest_xvfb)
                    set(editor_autotest_launcher ${FA_XVFB_RUN_EDITOR} -a -n ${editor_autotest_server} -s "-screen 0 1600x900x24")
                endif()
                math(EXPR editor_autotest_server "${editor_autotest_server} + 10")
                add_test(NAME editor_autotest_${editor_autotest_n}
                    COMMAND ${editor_autotest_launcher} $<TARGET_FILE:fa_editor_autotest>
                    WORKING_DIRECTORY ${FA_ROOT})
                set_tests_properties(editor_autotest_${editor_autotest_n} PROPERTIES LABELS "gpu" TIMEOUT 120
                    ENVIRONMENT "FA_EDITOR_AUTOTEST=1;FA_EDITOR_AUTOTEST_SECTIONS=${editor_autotest_sections};FA_EDITOR_AUTOTEST_OUT=${CMAKE_BINARY_DIR}/test-output/editor/autotest_${editor_autotest_n}")
            endforeach()
            foreach(editor_autotest_id IN LISTS editor_autotest_ids)
                if(NOT editor_autotest_id IN_LIST editor_autotest_seen)
                    message(FATAL_ERROR "tools/editor/CMakeLists.txt: the autotest section '${editor_autotest_id}' "
                        "(src/autotest_sections.h) is in no editor_autotest entry, so ctest would never run it. Add it to one of "
                        "editor_autotest_entries: the one with the fewest frames in the table the autotest prints at the end.")
                endif()
            endforeach()
            # No-project start: welcome dialog, then Open/New switches to a real project (graphics teardown/rebuild).
            set(editor_autotest_launcher "")
            if(editor_autotest_xvfb)
                set(editor_autotest_launcher ${FA_XVFB_RUN_EDITOR} -a -n ${editor_autotest_server} -s "-screen 0 1600x900x24")
            endif()
            add_test(NAME editor_autotest_welcome
                COMMAND ${editor_autotest_launcher} $<TARGET_FILE:fa_editor_autotest>
                WORKING_DIRECTORY ${FA_ROOT})
            set_tests_properties(editor_autotest_welcome PROPERTIES LABELS "gpu" TIMEOUT 120
                ENVIRONMENT "FA_EDITOR_AUTOTEST=welcome;FA_EDITOR_AUTOTEST_OUT=${CMAKE_BINARY_DIR}/test-output/editor/welcome")
        endif()
    endif()
endif()
