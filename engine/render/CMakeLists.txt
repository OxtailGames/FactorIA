fa_add_module(render
    DEPS fa_core fa_scene fa_platform
    PRIVATE_DEPS fa_ext_sokol fa_ext_stb fa_ext_cgltf)

# Built-in fonts are embedded in the binary (namespace fa_render_fonts, header embedded_fonts.h).
fa_embed_files(fa_render fa_render_fonts embedded_fonts
    FILES ${CMAKE_CURRENT_SOURCE_DIR}/assets/fonts/DejaVuSans.ttf
          ${CMAKE_CURRENT_SOURCE_DIR}/assets/fonts/PressStart2P-Regular.ttf
    BASE ${CMAKE_CURRENT_SOURCE_DIR}/assets/fonts)

# Third-party implementation TUs: no warnings.
if(MSVC)
    set_source_files_properties(src/stb_impl.cpp src/cgltf_impl.cpp PROPERTIES COMPILE_OPTIONS "/w")
else()
    set_source_files_properties(src/stb_impl.cpp src/cgltf_impl.cpp PROPERTIES COMPILE_OPTIONS "-w")
endif()
if(APPLE)
    set_source_files_properties(src/readback_metal.mm PROPERTIES COMPILE_OPTIONS "-fobjc-arc")
endif()

fa_add_tests(render)
if(TARGET fa_test_render)
    # Golden images live next to the tests.
    target_compile_definitions(fa_test_render PRIVATE FA_RENDER_GOLDEN_DIR="${CMAKE_CURRENT_SOURCE_DIR}/tests/golden")
endif()
