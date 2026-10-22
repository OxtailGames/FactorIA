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
target_link_libraries(fa_tooling PUBLIC fa_runtime PRIVATE fa_warnings fa_ext_basisu_encoder fa_ext_stb fa_ext_quickjs)

# Bake docs, templates and schemas into the binary (offline AI access), plus the Android/iOS project templates of
# platforms/ so that `factoria export --platform android|ios` works without the engine source (prebuilt mode).
file(GLOB_RECURSE FA_EMBED_DOCS CONFIGURE_DEPENDS ${FA_ROOT}/docs/*.md)
# Translations (docs/i18n/<lang>/) are for humans browsing the repo; AIs get the English reference docs.
list(FILTER FA_EMBED_DOCS EXCLUDE REGEX "/docs/i18n/")
# The browsable reference (docs/reference/) is generated from the data AIs get via docs.components/docs.commands.
list(FILTER FA_EMBED_DOCS EXCLUDE REGEX "/docs/reference/")
# Design documents (docs/design/) are for engine developers, not game makers.
list(FILTER FA_EMBED_DOCS EXCLUDE REGEX "/docs/design/")
file(GLOB_RECURSE FA_EMBED_TEMPLATES CONFIGURE_DEPENDS ${FA_ROOT}/templates/*)
file(GLOB_RECURSE FA_EMBED_SCHEMAS CONFIGURE_DEPENDS ${FA_ROOT}/schemas/*.json)
file(GLOB_RECURSE FA_EMBED_PLATFORMS CONFIGURE_DEPENDS ${FA_ROOT}/platforms/*)
# The tests of a store backend template (platforms/plugins/<name>/tests/: its mock SDK) are for the engine's CI, not for games.
list(FILTER FA_EMBED_PLATFORMS EXCLUDE REGEX "/platforms/plugins/[^/]+/tests/")
# License texts for the notices the export writes next to every game (fa/tooling/notices.h). A library that ships a NOTICE
# file (Apache-2.0) or a LICENSES/ folder for parts of it has those embedded too.
file(GLOB FA_EMBED_LICENSES CONFIGURE_DEPENDS LIST_DIRECTORIES false ${FA_ROOT}/external/*/LICENSE* ${FA_ROOT}/external/*/NOTICE*
     ${FA_ROOT}/external/*/COPYING ${FA_ROOT}/external/harfbuzz/src/ms-use/COPYING
     ${FA_ROOT}/external/*/LICENSES/* ${FA_ROOT}/engine/render/assets/fonts/*.txt)
# sokol-shdc and what it statically links (tools/shaders/licenses/): in the notices of the factoria downloads, not of games.
file(GLOB FA_EMBED_SHADER_LICENSES CONFIGURE_DEPENDS LIST_DIRECTORIES false ${FA_ROOT}/tools/shaders/licenses/*.txt)
list(APPEND FA_EMBED_LICENSES ${FA_EMBED_SHADER_LICENSES})
list(APPEND FA_EMBED_LICENSES ${FA_ROOT}/LICENSE)
# The mesh shader template (engine/render/shaders/*_common.glsl, @included by every mesh program): custom materials are
# compiled against it (docs/design/CUSTOM_SHADERS.md), also by an installed factoria without the engine source.
file(GLOB FA_EMBED_SHADER_TEMPLATES CONFIGURE_DEPENDS ${FA_ROOT}/engine/render/shaders/*_common.glsl)
# The C API of native plugins: project.new_plugin copies it into every new plugin.
# The VS Code extension of the script debugger (tools/vscode/): `factoria setup vscode` copies it into VS Code's extensions folder.
file(GLOB FA_EMBED_VSCODE CONFIGURE_DEPENDS LIST_DIRECTORIES false ${FA_ROOT}/tools/vscode/*)
# Which version added each component, field and command (fa/tooling/api_export.h).
set(FA_EMBED_ALL ${CMAKE_CURRENT_SOURCE_DIR}/api_since.json ${FA_EMBED_DOCS} ${FA_EMBED_TEMPLATES} ${FA_EMBED_SCHEMAS} ${FA_EMBED_PLATFORMS} ${FA_EMBED_LICENSES}
    ${FA_EMBED_SHADER_TEMPLATES} ${FA_EMBED_VSCODE}
    # The script debugger's instrumenter and the parser it runs (fa/tooling/script_instrument.h).
    ${FA_ROOT}/external/acorn/dist/acorn.js ${CMAKE_CURRENT_SOURCE_DIR}/src/js/instrument.js
    ${FA_ROOT}/engine/runtime/include/fa/runtime/fa_plugin.h)
if(FA_EMBED_ALL)
    fa_embed_files(fa_tooling fa::embedded fa_embedded_files BASE ${FA_ROOT} FILES ${FA_EMBED_ALL})
    target_compile_definitions(fa_tooling PRIVATE FA_HAS_EMBEDDED_FILES=1)
endif()
# Only on the files that use it: an absolute path on every command line would stop worktrees sharing the ccache.
set_source_files_properties(src/bundle.cpp src/export.cpp PROPERTIES COMPILE_DEFINITIONS FA_SOURCE_ROOT="${FA_ROOT}")
# The release packages set FA_UPDATE_REPO: the CI workflow downloads FactorIA from there (fa/tooling/ci_workflow.h).
set_property(SOURCE src/ci_workflow.cpp APPEND PROPERTY COMPILE_DEFINITIONS FA_UPDATE_REPO="${FA_UPDATE_REPO}")

if(FA_BUILD_TESTS)
    file(GLOB_RECURSE tooling_tests CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/tests/*.cpp)
    if(tooling_tests)
        add_executable(fa_test_tooling ${tooling_tests} ${FA_ROOT}/cmake/doctest_main.cpp)
        target_link_libraries(fa_test_tooling PRIVATE fa_tooling fa_ai fa_ext_doctest fa_warnings fa_ext_cgltf fa_ext_basisu_encoder fa_ext_quickjs)  # script_instrument_test.cpp runs the instrumented code in QuickJS; # export_web_test.cpp unzips with its miniz; api_since_test.cpp registers ai.* like the CLI
        target_include_directories(fa_test_tooling PRIVATE ${FA_GENERATED_DIR})  # fa_test_paths.h: FA_REPO_ROOT
        add_test(NAME tooling COMMAND fa_test_tooling WORKING_DIRECTORY ${FA_ROOT})
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
