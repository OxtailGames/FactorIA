# fa_tooling: shared developer-tool logic (desktop only): project scaffolding
# from templates/, validation, ENGINE_FEEDBACK.json handling, embedded docs,
# API export (JSON / Markdown / TypeScript), project-sandboxed file commands.
set(FA_TOOLING_TARGET_NAME tooling)
add_library(fa_tooling STATIC)
file(GLOB_RECURSE tooling_srcs CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)
# Host-platform files (script_instrument_thread_posix.cpp / _win32.cpp). Not _fa_filter_platform_sources: here
# _android / _web name an export target (export_android.cpp, setup_android.cpp), built on every host.
if(WIN32)
    list(FILTER tooling_srcs EXCLUDE REGEX "_posix\\.cpp$")
else()
    list(FILTER tooling_srcs EXCLUDE REGEX "_win32\\.cpp$")
endif()
target_sources(fa_tooling PRIVATE ${tooling_srcs})
target_include_directories(fa_tooling PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
# The Basis Universal encoder and stb_rect_pack make the compressed textures and atlases of `factoria export`.
target_link_libraries(fa_tooling PUBLIC fa_ext_harfbuzz_subset fa_authoring fa_runtime PRIVATE fa_warnings fa_ext_basisu_encoder fa_ext_stb fa_ext_quickjs fa_ext_nanosvg fa_ext_clipper2)
if(MSVC)
    # nanosvg's implementation has unreachable code (nanosvg.h, the end of nsvg__convertToPixels). The optimizer reports
    # C4702 for it and does not honour #pragma warning around the include, so it is off on the command line for the two
    # files that compile nanosvg (external/ is not edited).
    set_source_files_properties(src/assets_svg.cpp src/assets_svg_layers.cpp PROPERTIES COMPILE_OPTIONS /wd4702)
endif()
if(WIN32)
    target_link_libraries(fa_tooling PRIVATE ws2_32 iphlpapi bcrypt)  # net.cpp: sockets, the adapters' addresses, random bytes
endif()

# Bake docs, templates and schemas into the binary (offline AI access), plus the Android/iOS project templates of
# platforms/ so that `factoria export --platform android|ios` works without the engine source (prebuilt mode).
file(GLOB_RECURSE FA_EMBED_DOCS CONFIGURE_DEPENDS ${FA_ROOT}/docs/*.md)
# Translations (docs/i18n/<lang>/) are for humans browsing the repo; AIs get the English reference docs.
list(FILTER FA_EMBED_DOCS EXCLUDE REGEX "/docs/i18n/")
# The browsable reference (docs/reference/) is generated from the data AIs get via docs.components/docs.commands.
list(FILTER FA_EMBED_DOCS EXCLUDE REGEX "/docs/reference/")
# docs/COMPONENTS.md (1.8 MB, generated for GitHub readers) is served per component by docs.components, never embedded.
list(FILTER FA_EMBED_DOCS EXCLUDE REGEX "/docs/COMPONENTS\\.md$")
# Design documents (docs/design/) are for engine developers, not game makers.
list(FILTER FA_EMBED_DOCS EXCLUDE REGEX "/docs/design/")
file(GLOB_RECURSE FA_EMBED_TEMPLATES CONFIGURE_DEPENDS ${FA_ROOT}/templates/*)
file(GLOB_RECURSE FA_EMBED_SCHEMAS CONFIGURE_DEPENDS ${FA_ROOT}/schemas/*.json)
# The engine's own Agent Skills (skills/<name>/SKILL.md and the files beside it): fa/tooling/skills.h, docs/SKILLS.md.
file(GLOB_RECURSE FA_EMBED_SKILLS CONFIGURE_DEPENDS LIST_DIRECTORIES false ${FA_ROOT}/skills/*)
file(GLOB_RECURSE FA_EMBED_PLATFORMS CONFIGURE_DEPENDS ${FA_ROOT}/platforms/*)
# The tests of a store backend template (platforms/plugins/<name>/tests/: its mock SDK) are for the engine's CI, not for games.
list(FILTER FA_EMBED_PLATFORMS EXCLUDE REGEX "/platforms/plugins/[^/]+/tests/")
# License texts for the notices the export writes next to every game (fa/tooling/notices.h). A library that ships a NOTICE
# file (Apache-2.0) or a LICENSES/ folder for parts of it has those embedded too.
file(GLOB FA_EMBED_LICENSES CONFIGURE_DEPENDS LIST_DIRECTORIES false ${FA_ROOT}/external/*/LICENSE* ${FA_ROOT}/external/*/NOTICE*
     ${FA_ROOT}/external/*/COPYING ${FA_ROOT}/external/harfbuzz/src/ms-use/COPYING
     ${FA_ROOT}/external/*/LICENSES/* ${FA_ROOT}/engine/render/assets/fonts/*.txt
     ${FA_ROOT}/engine/render/assets/fonts/extra/*.txt)
# sokol-shdc and what it statically links (tools/shaders/licenses/): in the notices of the factoria downloads, not of games.
file(GLOB FA_EMBED_SHADER_LICENSES CONFIGURE_DEPENDS LIST_DIRECTORIES false ${FA_ROOT}/tools/shaders/licenses/*.txt)
list(APPEND FA_EMBED_LICENSES ${FA_EMBED_SHADER_LICENSES})
list(APPEND FA_EMBED_LICENSES ${FA_ROOT}/LICENSE)
# The built-in fonts that are not inside the player (serif, hand, blackletter, display: fa/render/builtin_fonts.h). factoria and the
# editor carry them; `factoria export` copies the ones a project names into the game.
file(GLOB FA_EMBED_EXTRA_FONTS CONFIGURE_DEPENDS LIST_DIRECTORIES false ${FA_ROOT}/engine/render/assets/fonts/extra/*.ttf)
list(APPEND FA_EMBED_LICENSES ${FA_EMBED_EXTRA_FONTS})
# The mesh shader template (engine/render/shaders/*_common.glsl, @included by every mesh program): custom materials are
# compiled against it (docs/design/CUSTOM_SHADERS.md), also by an installed factoria without the engine source.
file(GLOB FA_EMBED_SHADER_TEMPLATES CONFIGURE_DEPENDS ${FA_ROOT}/engine/render/shaders/*_common.glsl)
# The files the templates @include (the sprite template: the colour-space and 2D shadow helpers; keep in step with
# template_file_names() in tools/common/src/shaders_generate.cpp and FA_TEMPLATE_FILES_* in engine/render/CMakeLists.txt).
# The mesh template's lighting files (light_data.glsl, light_loop.glsl; shadow_common.glsl matches the glob above) too.
list(APPEND FA_EMBED_SHADER_TEMPLATES ${FA_ROOT}/engine/render/shaders/color_space.glsl
    ${FA_ROOT}/engine/render/shaders/light_shadow.glsl ${FA_ROOT}/engine/render/shaders/light_data.glsl
    ${FA_ROOT}/engine/render/shaders/light_loop.glsl)
# The C API of native plugins: project.new_plugin copies it into every new plugin.
# The VS Code extension of the script debugger (tools/vscode/): `factoria setup vscode` copies it into VS Code's extensions folder.
file(GLOB FA_EMBED_VSCODE CONFIGURE_DEPENDS LIST_DIRECTORIES false ${FA_ROOT}/tools/vscode/*)
# Which version added each component, field and command (fa/tooling/api_export.h).
set(FA_EMBED_ALL ${CMAKE_CURRENT_SOURCE_DIR}/api_since.json ${FA_EMBED_DOCS} ${FA_EMBED_TEMPLATES} ${FA_EMBED_SCHEMAS} ${FA_EMBED_SKILLS} ${FA_EMBED_PLATFORMS} ${FA_EMBED_LICENSES}
    ${FA_EMBED_SHADER_TEMPLATES} ${FA_EMBED_VSCODE}
    # The macOS icon of the app `factoria setup launcher` writes (Linux uses platforms/linux/factoria.png, embedded above).
    ${FA_ROOT}/tools/editor/icon/factoria.icns
    # The script debugger's instrumenter and the parser it runs (fa/tooling/script_instrument.h).
    ${FA_ROOT}/external/acorn/dist/acorn.js ${CMAKE_CURRENT_SOURCE_DIR}/src/js/instrument.js
    ${FA_ROOT}/engine/runtime/include/fa/runtime/fa_plugin.h
    # The gaps fixed in each engine release: `feedback.check_fixed` closes the matching local entries (fa/tooling/feedback_fixed.h).
    ${FA_ROOT}/feedback/fixed.json)
if(FA_EMBED_ALL)
    fa_embed_files(fa_tooling fa::embedded fa_embedded_files BASE ${FA_ROOT} FILES ${FA_EMBED_ALL})
    target_compile_definitions(fa_tooling PRIVATE FA_HAS_EMBEDDED_FILES=1)
endif()
# Only on the files that use it: an absolute path on every command line would stop worktrees sharing the ccache.
set_source_files_properties(src/bundle.cpp src/export.cpp src/setup_webplayer.cpp PROPERTIES COMPILE_DEFINITIONS FA_SOURCE_ROOT="${FA_ROOT}")
# The release packages set FA_UPDATE_REPO: the CI workflow downloads FactorIA from there (fa/tooling/ci_workflow.h).
set_property(SOURCE src/ci_workflow.cpp APPEND PROPERTY COMPILE_DEFINITIONS FA_UPDATE_REPO="${FA_UPDATE_REPO}")
# Feedback sharing (docs/design/FEEDBACK_SHARING.md): the developer's server and the public client id of the GitHub app that
# identifies the sender. Empty = sharing (sign-in) is unavailable in this build; the user's `endpoint` setting still works.
set(FA_FEEDBACK_URL "" CACHE STRING "URL of the feedback server (tools/feedback-server) that `factoria feedback share` sends to; empty = unavailable")
set(FA_FEEDBACK_GITHUB_CLIENT_ID "" CACHE STRING "Public client id of the GitHub OAuth app for `factoria feedback signin github`; empty = unavailable")
set_property(SOURCE src/feedback_share.cpp src/feedback_share_auth.cpp APPEND PROPERTY COMPILE_DEFINITIONS
    FA_FEEDBACK_URL="${FA_FEEDBACK_URL}" FA_FEEDBACK_GITHUB_CLIENT_ID="${FA_FEEDBACK_GITHUB_CLIENT_ID}")

if(FA_BUILD_TESTS)
    file(GLOB_RECURSE tooling_tests CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/tests/*.cpp)
    if(tooling_tests)
        add_executable(fa_test_tooling ${tooling_tests} ${FA_ROOT}/cmake/doctest_main.cpp)
        target_link_libraries(fa_test_tooling PRIVATE fa_tooling fa_ai fa_ext_doctest fa_warnings fa_ext_cgltf fa_ext_basisu_encoder fa_ext_quickjs)  # script_instrument_test.cpp runs the instrumented code in QuickJS; # export_web_test.cpp unzips with its miniz; api_since_test.cpp registers ai.* like the CLI
        fa_allow_duplicate_libraries(fa_test_tooling)
        target_include_directories(fa_test_tooling PRIVATE ${FA_GENERATED_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/src)  # fa_test_paths.h: FA_REPO_ROOT; src: export_script_commands_test.cpp tests the private player_commands.h
        # One process ran all the test cases one after another and took 100 s (more than any other test of the suite; 20 minutes
        # under ASan), so the files are split over five ctest entries that `ctest -j` runs at the same time, each in its own
        # process (temp folders are named after the process id; nothing else is shared, see docs/design/ARCHITECTURE.md, "Testing"):
        # tooling_1..tooling_4 run the files named below, tooling_5 runs every other file, so a new test file needs no edit here
        # (cmake/doctest_main.cpp: --fa-files, --fa-files-exclude). tooling_split_check fails unless the five together list
        # exactly the test cases of the whole executable. ctest -L tooling runs all of them.
        # The table holds only the heavy files, balanced by the seconds their test cases took in the Debug tree of an M5 MacBook
        # Air (about 22 s per entry of the 111 s in all, 21 to 25 s since M73; Windows and the sanitizers scale it, they do
        # not reorder it much).
        # Refresh it when an entry gets much slower than the others: `fa_test_tooling -r=junit -d=true > tooling.xml` has the
        # seconds of every test case, `classname` is its file; add up each file, put the biggest ones in the lightest entry.
        set(tooling_test_entries
            "1:review_sheet_test.cpp,assets_capsules_test.cpp,model_texture_test.cpp,serve_web_test.cpp,admob_tools_test.cpp,msix_test.cpp,perf_test.cpp,assets_sfx_test.cpp,examples_download_test.cpp,material_graph_test.cpp"
            "2:steam_setup_test.cpp,model_doc_test.cpp,sign_macos_store_test.cpp,sign_macos_test.cpp,export_icons_test.cpp,publish_test.cpp,assets_recipe_test.cpp,export_web_test.cpp,shaders_fixtures_test.cpp"
            "3:export_android_test.cpp,script_instrument_test.cpp,test_export.cpp,feedback_test.cpp,recipe_schema_test.cpp,shaders_test.cpp,export_textures_test.cpp,sign_windows_test.cpp,checkpoint_test.cpp"
            "4:music_render_test.cpp,music_test.cpp,feedback_share_test.cpp,efficiency_share_test.cpp,assets_fbx_test.cpp,assets_bake_test.cpp,shaders_docs_test.cpp,assets_animate_test.cpp,efficiency_test.cpp")
        set(tooling_test_names "")
        foreach(tooling_test_file IN LISTS tooling_tests)
            get_filename_component(tooling_test_name ${tooling_test_file} NAME)
            if(tooling_test_name IN_LIST tooling_test_names)
                message(FATAL_ERROR "tools/common/CMakeLists.txt: two test files are named ${tooling_test_name}. The ctest entries "
                    "tooling_<n> pick files by name (cmake/doctest_main.cpp): rename one of them.")
            endif()
            list(APPEND tooling_test_names ${tooling_test_name})
        endforeach()
        set(tooling_test_named "")
        set(tooling_test_args "")
        foreach(tooling_test_entry IN LISTS tooling_test_entries)
            string(REGEX REPLACE ":.*$" "" tooling_test_n "${tooling_test_entry}")
            string(REGEX REPLACE "^[0-9]+:" "" tooling_test_files "${tooling_test_entry}")
            string(REPLACE "," ";" tooling_test_picked "${tooling_test_files}")
            foreach(tooling_test_file IN LISTS tooling_test_picked)
                if(NOT tooling_test_file IN_LIST tooling_test_names)
                    string(REPLACE ";" ", " tooling_test_all "${tooling_test_names}")
                    message(FATAL_ERROR "tools/common/CMakeLists.txt: the ctest entry tooling_${tooling_test_n} names the file "
                        "'${tooling_test_file}', which is not in tools/common/tests. Its files: ${tooling_test_all}. Fix the name "
                        "(or remove it) in tooling_test_entries.")
                endif()
                if(tooling_test_file IN_LIST tooling_test_named)
                    message(FATAL_ERROR "tools/common/CMakeLists.txt: the file '${tooling_test_file}' is in two tooling entries. "
                        "Keep it in one of tooling_test_entries: every test case runs exactly once.")
                endif()
                list(APPEND tooling_test_named ${tooling_test_file})
            endforeach()
            list(APPEND tooling_test_args "--fa-files=${tooling_test_files}")
            add_test(NAME tooling_${tooling_test_n} COMMAND fa_test_tooling "--fa-files=${tooling_test_files}" WORKING_DIRECTORY ${FA_ROOT})
            set_tests_properties(tooling_${tooling_test_n} PROPERTIES LABELS "tooling")
        endforeach()
        list(LENGTH tooling_test_entries tooling_test_rest)
        math(EXPR tooling_test_rest "${tooling_test_rest} + 1")
        string(REPLACE ";" "," tooling_test_named_list "${tooling_test_named}")
        add_test(NAME tooling_${tooling_test_rest} COMMAND fa_test_tooling "--fa-files-exclude=${tooling_test_named_list}" WORKING_DIRECTORY ${FA_ROOT})
        list(APPEND tooling_test_args "--fa-files-exclude=${tooling_test_named_list}")
        set_tests_properties(tooling_${tooling_test_rest} PROPERTIES LABELS "tooling")
        string(REPLACE ";" "|" tooling_test_entry_args "${tooling_test_args}")
        add_test(NAME tooling_split_check
            COMMAND ${CMAKE_COMMAND} -DFA_TEST_EXE=$<TARGET_FILE:fa_test_tooling> "-DFA_SPLIT_ENTRIES=${tooling_test_entry_args}"
                -P ${FA_ROOT}/cmake/fa_doctest_split_check.cmake
            WORKING_DIRECTORY ${FA_ROOT})
        set_tests_properties(tooling_split_check PROPERTIES LABELS "tooling")
        if(WIN32 AND TARGET factoria_player)  # pe_icon_test checks the real player's subsystem and version placeholders
            set_source_files_properties(tests/pe_icon_test.cpp PROPERTIES
                COMPILE_DEFINITIONS FA_PLAYER_EXE="$<TARGET_FILE:factoria_player>")  # its one file: the ccache, above
            add_dependencies(fa_test_tooling factoria_player)
        endif()
        if(APPLE AND NOT IOS AND TARGET factoria_player)  # sign_macos_store_test.cpp runs the real player inside the App Sandbox
            set_property(SOURCE tests/sign_macos_store_test.cpp APPEND PROPERTY COMPILE_DEFINITIONS FA_PLAYER_EXE="$<TARGET_FILE:factoria_player>")
            add_dependencies(fa_test_tooling factoria_player)
        endif()
        # publish_test.cpp runs this stand-in for steamcmd, butler... (no test talks to a real store).
        add_executable(fa_fake_store_tool test_tools/fake_store_tool.cpp)
        target_link_libraries(fa_fake_store_tool PRIVATE fa_warnings)
        add_dependencies(fa_test_tooling fa_fake_store_tool)
        set_source_files_properties(tests/publish_test.cpp PROPERTIES COMPILE_DEFINITIONS FA_FAKE_STORE_TOOL="$<TARGET_FILE:fa_fake_store_tool>")
    endif()
endif()
