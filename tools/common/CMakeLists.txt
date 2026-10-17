# fa_tooling: shared developer-tool logic (desktop only): project scaffolding
# from templates/, validation, ENGINE_FEEDBACK.json handling, embedded docs,
# API export (JSON / Markdown / TypeScript), project-sandboxed file commands.
set(FA_TOOLING_TARGET_NAME tooling)
add_library(fa_tooling STATIC)
file(GLOB_RECURSE tooling_srcs CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)
target_sources(fa_tooling PRIVATE ${tooling_srcs})
target_include_directories(fa_tooling PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
# The Basis Universal encoder and stb_rect_pack make the compressed textures and atlases of `factoria export`.
target_link_libraries(fa_tooling PUBLIC fa_runtime PRIVATE fa_warnings fa_ext_basisu_encoder fa_ext_stb)

# Bake docs, templates and schemas into the binary (offline AI access), plus the Android/iOS project templates of
# platforms/ so that `factoria export --platform android|ios` works without the engine source (prebuilt mode).
file(GLOB_RECURSE FA_EMBED_DOCS CONFIGURE_DEPENDS ${FA_ROOT}/docs/*.md)
# Translations (docs/i18n/<lang>/) are for humans browsing the repo; AIs get the English reference docs.
list(FILTER FA_EMBED_DOCS EXCLUDE REGEX "/docs/i18n/")
file(GLOB_RECURSE FA_EMBED_TEMPLATES CONFIGURE_DEPENDS ${FA_ROOT}/templates/*)
file(GLOB_RECURSE FA_EMBED_SCHEMAS CONFIGURE_DEPENDS ${FA_ROOT}/schemas/*.json)
file(GLOB_RECURSE FA_EMBED_PLATFORMS CONFIGURE_DEPENDS ${FA_ROOT}/platforms/*)
# The tests of a store backend template (platforms/plugins/<name>/tests/: its mock SDK) are for the engine's CI, not for games.
list(FILTER FA_EMBED_PLATFORMS EXCLUDE REGEX "/platforms/plugins/[^/]+/tests/")
# License texts for the notices the export writes next to every game (fa/tooling/notices.h). A library that ships a NOTICE
# file (Apache-2.0) or a LICENSES/ folder for parts of it has those embedded too.
file(GLOB FA_EMBED_LICENSES CONFIGURE_DEPENDS LIST_DIRECTORIES false ${FA_ROOT}/external/*/LICENSE* ${FA_ROOT}/external/*/NOTICE*
     ${FA_ROOT}/external/*/LICENSES/* ${FA_ROOT}/engine/render/assets/fonts/*.txt)
list(APPEND FA_EMBED_LICENSES ${FA_ROOT}/LICENSE)
# The C API of native plugins: project.new_plugin copies it into every new plugin.
set(FA_EMBED_ALL ${FA_EMBED_DOCS} ${FA_EMBED_TEMPLATES} ${FA_EMBED_SCHEMAS} ${FA_EMBED_PLATFORMS} ${FA_EMBED_LICENSES}
    ${FA_ROOT}/engine/runtime/include/fa/runtime/fa_plugin.h)
if(FA_EMBED_ALL)
    fa_embed_files(fa_tooling fa::embedded fa_embedded_files BASE ${FA_ROOT} FILES ${FA_EMBED_ALL})
    target_compile_definitions(fa_tooling PRIVATE FA_HAS_EMBEDDED_FILES=1)
endif()
# Only on the files that use it: an absolute path on every command line would stop worktrees sharing the ccache.
set_source_files_properties(src/bundle.cpp src/export.cpp PROPERTIES COMPILE_DEFINITIONS FA_SOURCE_ROOT="${FA_ROOT}")

if(FA_BUILD_TESTS)
    file(GLOB_RECURSE tooling_tests CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/tests/*.cpp)
    if(tooling_tests)
        add_executable(fa_test_tooling ${tooling_tests} ${FA_ROOT}/cmake/doctest_main.cpp)
        target_link_libraries(fa_test_tooling PRIVATE fa_tooling fa_ext_doctest fa_warnings fa_ext_cgltf)
        target_include_directories(fa_test_tooling PRIVATE ${FA_GENERATED_DIR})  # fa_test_paths.h: FA_REPO_ROOT
        add_test(NAME tooling COMMAND fa_test_tooling WORKING_DIRECTORY ${FA_ROOT})
        if(WIN32 AND TARGET factoria_player)  # pe_icon_test checks the real player's subsystem and version placeholders
            set_source_files_properties(tests/pe_icon_test.cpp PROPERTIES
                COMPILE_DEFINITIONS FA_PLAYER_EXE="$<TARGET_FILE:factoria_player>")  # its one file: the ccache, above
            add_dependencies(fa_test_tooling factoria_player)
        endif()
    endif()
endif()
