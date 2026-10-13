fa_add_module(script
    DEPS fa_core fa_scene fa_platform fa_render fa_physics fa_audio
    PRIVATE_DEPS fa_ext_quickjs)

# JavaScript preludes + API description are baked into the binary.
file(GLOB FA_SCRIPT_JS CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/js/*.js ${CMAKE_CURRENT_SOURCE_DIR}/src/js/*.json)
fa_embed_files(fa_script fa::script_js fa_script_js BASE ${CMAKE_CURRENT_SOURCE_DIR}/src/js FILES ${FA_SCRIPT_JS})

fa_add_tests(script)
