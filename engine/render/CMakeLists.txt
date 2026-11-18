fa_add_module(render
    DEPS fa_core fa_scene fa_platform
    PRIVATE_DEPS fa_ext_sokol fa_ext_stb fa_ext_cgltf fa_ext_basisu_transcoder fa_ext_harfbuzz fa_ext_sheenbidi)

# Built-in fonts are embedded in the binary (namespace fa_render_fonts, header embedded_fonts.h).
fa_embed_files(fa_render fa_render_fonts embedded_fonts
    FILES ${CMAKE_CURRENT_SOURCE_DIR}/assets/fonts/DejaVuSans.ttf
          ${CMAKE_CURRENT_SOURCE_DIR}/assets/fonts/PressStart2P-Regular.ttf
    BASE ${CMAKE_CURRENT_SOURCE_DIR}/assets/fonts)

# fa::material_template_hash(kind): SHA-256 of the template files of one material kind, the value the tooling writes into
# every material twin of that kind (fa/tooling/shaders.h shader_template_hash(kind) returns it): per file, by name,
# "<name>\n<sha256 of content>\n", all hashed, with CRs removed so that every checkout gives the same value (.gitattributes
# also checks the shaders out with LF). Each kind hashes only its own files, so editing the sprite template leaves every
# mesh twin valid. THE LISTS ARE EXPLICIT and must equal template_file_names() of tools/common/src/shaders_generate.cpp (a
# test compares both). The mesh list is the file set the hash was computed from before kinds existed, so its value did not
# change.
set(FA_TEMPLATE_FILES_MESH mesh_common.glsl)
set(FA_TEMPLATE_FILES_SPRITE quad_common.glsl)
set(FA_TEMPLATE_FILES_SKY sky_common.glsl)
set(FA_TEMPLATE_FILES_POST post_common.glsl)
set(FA_TEMPLATE_FILES_COMPUTE compute_common.glsl)
set(FA_TEMPLATE_DEFINITIONS "")
foreach(kind MESH SPRITE SKY POST COMPUTE)
    set(list "")
    foreach(n ${FA_TEMPLATE_FILES_${kind}})
        set(f ${CMAKE_CURRENT_SOURCE_DIR}/shaders/${n})
        file(READ ${f} c)
        string(REPLACE "\r" "" c "${c}")
        string(SHA256 h "${c}")
        string(APPEND list "${n}\n${h}\n")
        set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${f})
    endforeach()
    if(list STREQUAL "")
        set(FA_TEMPLATE_HASH_${kind} "")
    else()
        string(SHA256 FA_TEMPLATE_HASH_${kind} "${list}")
    endif()
    list(APPEND FA_TEMPLATE_DEFINITIONS "FA_TEMPLATE_HASH_${kind}=\"${FA_TEMPLATE_HASH_${kind}}\"")
endforeach()
set_source_files_properties(src/custom_shader.cpp PROPERTIES COMPILE_DEFINITIONS "${FA_TEMPLATE_DEFINITIONS}")

# Third-party implementation TUs: no warnings.
if(MSVC)
    set_source_files_properties(src/stb_impl.cpp PROPERTIES COMPILE_OPTIONS "/w")
else()
    set_source_files_properties(src/stb_impl.cpp PROPERTIES COMPILE_OPTIONS "-w")
endif()
if(APPLE)
    set_source_files_properties(src/readback_metal.mm PROPERTIES COMPILE_OPTIONS "-fobjc-arc")
endif()

fa_add_tests(render LABELS gpu)  # REQUIRE a GPU (Gfx::ok): a host without one runs `ctest -LE gpu`
# The CPU core of the frame graph needs no GPU: its tests also run on a host that runs `ctest -LE gpu`.
if(TARGET fa_test_render)
    add_test(NAME render_frame_graph_core
        COMMAND fa_test_render --fa-files=frame_graph_tests.cpp
        WORKING_DIRECTORY ${FA_ROOT})
endif()
if(TARGET fa_test_render)
    target_link_libraries(fa_test_render PRIVATE fa_ext_basisu_transcoder)  # tests/data fixtures are checked against it directly
    # The text tests look at the shaped glyphs (src/text_shaper.h), which needs the private headers and HarfBuzz and stb.
    target_link_libraries(fa_test_render PRIVATE fa_ext_harfbuzz fa_ext_stb fa_ext_sokol)  # render3d_tests include mesh_batch.h
    target_include_directories(fa_test_render PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
endif()

# The 2D light buffer on a GPU that cannot blend half floats (RGBA8 at half range) and on one that cannot blend at all (the
# per-pixel loop over 16 lights): FA_LIGHT_FORMAT picks the format at start-up (gpu.cpp), the same tests must hold.
if(TARGET fa_test_render)
    foreach(fmt rgba8 none)
        add_test(NAME render_light_${fmt}
            COMMAND ${CMAKE_COMMAND} -E env FA_LIGHT_FORMAT=${fmt} $<TARGET_FILE:fa_test_render> "-tc=Light2D buffer*,lit sprites*"
            WORKING_DIRECTORY ${FA_ROOT})
    endforeach()
endif()

# Windowed smoke test (needs a display; runs under xvfb when available).
find_program(FA_XVFB_RUN xvfb-run)
if(TARGET fa_test_render AND FA_XVFB_RUN AND FA_PLATFORM STREQUAL "linux")
    add_test(NAME render_windowed_smoke
        COMMAND ${CMAKE_COMMAND} -E env FA_WINDOWED_SMOKE=1 ${FA_XVFB_RUN} -a -s "-screen 0 1280x720x24"
                $<TARGET_FILE:fa_test_render> -tc=windowed*
        WORKING_DIRECTORY ${FA_ROOT})
endif()

# The CPU side of the post-processing stack, the feature table and the HDR encodes need no GPU either.
if(TARGET fa_test_render)
    add_test(NAME render_postprocess_core
        COMMAND fa_test_render --fa-files=postprocess_resolve_tests.cpp,hdr_encode_tests.cpp,postfx_tests.cpp
        WORKING_DIRECTORY ${FA_ROOT})
endif()
