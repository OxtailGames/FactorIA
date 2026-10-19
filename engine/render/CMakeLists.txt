fa_add_module(render
    DEPS fa_core fa_scene fa_platform
    PRIVATE_DEPS fa_ext_sokol fa_ext_stb fa_ext_cgltf fa_ext_basisu_transcoder fa_ext_harfbuzz fa_ext_sheenbidi)

# Built-in fonts are embedded in the binary (namespace fa_render_fonts, header embedded_fonts.h).
fa_embed_files(fa_render fa_render_fonts embedded_fonts
    FILES ${CMAKE_CURRENT_SOURCE_DIR}/assets/fonts/DejaVuSans.ttf
          ${CMAKE_CURRENT_SOURCE_DIR}/assets/fonts/PressStart2P-Regular.ttf
    BASE ${CMAKE_CURRENT_SOURCE_DIR}/assets/fonts)

# mesh_template_hash(): SHA-256 of the mesh template files, the value the tooling writes into every material twin
# (fa/tooling/shaders.h shader_template_hash() returns it): per file, by name, "<name>\n<sha256 of content>\n", all hashed,
# with CRs removed so that every checkout gives the same value (.gitattributes also checks the shaders out with LF).
file(GLOB FA_MESH_TEMPLATE_FILES CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/shaders/*_common.glsl)
list(SORT FA_MESH_TEMPLATE_FILES)
set(FA_MESH_TEMPLATE_LIST "")
foreach(f ${FA_MESH_TEMPLATE_FILES})
    get_filename_component(n ${f} NAME)
    file(READ ${f} c)
    string(REPLACE "\r" "" c "${c}")
    string(SHA256 h "${c}")
    string(APPEND FA_MESH_TEMPLATE_LIST "${n}\n${h}\n")
endforeach()
string(SHA256 FA_MESH_TEMPLATE_HASH "${FA_MESH_TEMPLATE_LIST}")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${FA_MESH_TEMPLATE_FILES})
set_source_files_properties(src/custom_shader.cpp PROPERTIES COMPILE_DEFINITIONS "FA_MESH_TEMPLATE_HASH=\"${FA_MESH_TEMPLATE_HASH}\"")

# Third-party implementation TUs: no warnings.
if(MSVC)
    set_source_files_properties(src/stb_impl.cpp PROPERTIES COMPILE_OPTIONS "/w")
else()
    set_source_files_properties(src/stb_impl.cpp PROPERTIES COMPILE_OPTIONS "-w")
endif()
if(APPLE)
    set_source_files_properties(src/readback_metal.mm PROPERTIES COMPILE_OPTIONS "-fobjc-arc")
endif()

fa_add_tests(render)
if(TARGET fa_test_render)
    target_link_libraries(fa_test_render PRIVATE fa_ext_basisu_transcoder)  # tests/data fixtures are checked against it directly
    # The text tests look at the shaped glyphs (src/text_shaper.h), which needs the private headers and HarfBuzz and stb.
    target_link_libraries(fa_test_render PRIVATE fa_ext_harfbuzz fa_ext_stb fa_ext_sokol)  # render3d_tests include mesh_batch.h
    target_include_directories(fa_test_render PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
endif()

# Windowed smoke test (needs a display; runs under xvfb when available).
find_program(FA_XVFB_RUN xvfb-run)
if(TARGET fa_test_render AND FA_XVFB_RUN AND FA_PLATFORM STREQUAL "linux")
    add_test(NAME render_windowed_smoke
        COMMAND ${CMAKE_COMMAND} -E env FA_WINDOWED_SMOKE=1 ${FA_XVFB_RUN} -a -s "-screen 0 1280x720x24"
                $<TARGET_FILE:fa_test_render> -tc=windowed*
        WORKING_DIRECTORY ${FA_ROOT})
endif()
