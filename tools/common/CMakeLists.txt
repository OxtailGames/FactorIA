# fa_tooling: shared developer-tool logic (desktop only): project scaffolding
# from templates/, validation, ENGINE_FEEDBACK.json handling, embedded docs,
# API export (JSON / Markdown / TypeScript), project-sandboxed file commands.
set(FA_TOOLING_TARGET_NAME tooling)
add_library(fa_tooling STATIC)
file(GLOB_RECURSE tooling_srcs CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)
target_sources(fa_tooling PRIVATE ${tooling_srcs})
target_include_directories(fa_tooling PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
target_link_libraries(fa_tooling PUBLIC fa_runtime PRIVATE fa_warnings)

# Bake docs, templates and schemas into the binary (offline AI access), plus the Android/iOS project templates of
# platforms/ so that `factoria export --platform android|ios` works without the engine source (prebuilt mode).
file(GLOB_RECURSE FA_EMBED_DOCS CONFIGURE_DEPENDS ${FA_ROOT}/docs/*.md)
# Translations (docs/i18n/<lang>/) are for humans browsing the repo; AIs get the English reference docs.
list(FILTER FA_EMBED_DOCS EXCLUDE REGEX "/docs/i18n/")
file(GLOB_RECURSE FA_EMBED_TEMPLATES CONFIGURE_DEPENDS ${FA_ROOT}/templates/*)
file(GLOB_RECURSE FA_EMBED_SCHEMAS CONFIGURE_DEPENDS ${FA_ROOT}/schemas/*.json)
file(GLOB_RECURSE FA_EMBED_PLATFORMS CONFIGURE_DEPENDS ${FA_ROOT}/platforms/*)
# License texts for the notices the export writes next to every game (fa/tooling/notices.h).
file(GLOB FA_EMBED_LICENSES CONFIGURE_DEPENDS ${FA_ROOT}/external/*/LICENSE* ${FA_ROOT}/engine/render/assets/fonts/*.txt)
list(APPEND FA_EMBED_LICENSES ${FA_ROOT}/LICENSE)
# The C API of native plugins: project.new_plugin copies it into every new plugin.
set(FA_EMBED_ALL ${FA_EMBED_DOCS} ${FA_EMBED_TEMPLATES} ${FA_EMBED_SCHEMAS} ${FA_EMBED_PLATFORMS} ${FA_EMBED_LICENSES}
    ${FA_ROOT}/engine/runtime/include/fa/runtime/fa_plugin.h)
if(FA_EMBED_ALL)
    fa_embed_files(fa_tooling fa::embedded fa_embedded_files BASE ${FA_ROOT} FILES ${FA_EMBED_ALL})
    target_compile_definitions(fa_tooling PRIVATE FA_HAS_EMBEDDED_FILES=1)
endif()
target_compile_definitions(fa_tooling PUBLIC FA_SOURCE_ROOT="${FA_ROOT}")

if(FA_BUILD_TESTS)
    file(GLOB_RECURSE tooling_tests CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/tests/*.cpp)
    if(tooling_tests)
        add_executable(fa_test_tooling ${tooling_tests} ${FA_ROOT}/cmake/doctest_main.cpp)
        target_link_libraries(fa_test_tooling PRIVATE fa_tooling fa_ext_doctest fa_warnings)
        target_compile_definitions(fa_test_tooling PRIVATE FA_REPO_ROOT="${FA_ROOT}")
        add_test(NAME tooling COMMAND fa_test_tooling WORKING_DIRECTORY ${FA_ROOT})
        if(WIN32 AND TARGET factoria_player)  # pe_icon_test checks the real player's subsystem and version placeholders
            target_compile_definitions(fa_test_tooling PRIVATE FA_PLAYER_EXE="$<TARGET_FILE:factoria_player>")
            add_dependencies(fa_test_tooling factoria_player)
        endif()
    endif()
endif()
