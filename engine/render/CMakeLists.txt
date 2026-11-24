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
# test compares both). The mesh template @includes light_data.glsl, light_loop.glsl, ltc.glsl, shadow_common.glsl and brdf_layers.glsl (the lighting,
# M73-P0 and the material layers of M73.6: docs/design/ARCHITECTURE_RENDERING_LIGHTING.md), so a change to any of them changes the mesh hash.
set(FA_TEMPLATE_FILES_MESH mesh_common.glsl light_data.glsl light_loop.glsl ltc.glsl shadow_common.glsl brdf_layers.glsl)
# A mesh material in "full" mode (its own vertex and fragment stage, docs/shaders/SHADERS_FULL.md) is built from mesh_common.glsl's blocks plus
# mesh_full_common.glsl; its twin carries this hash (no snippet twin is made stale by a change to the full-shader template).
set(FA_TEMPLATE_FILES_MESH_FULL mesh_common.glsl light_data.glsl light_loop.glsl ltc.glsl shadow_common.glsl brdf_layers.glsl mesh_full_common.glsl)
# The sprite template @includes color_space.glsl, light_cookie.glsl and light_shadow.glsl (the other programs that use them include them too), so a
# change to any of them changes the sprite hash.
set(FA_TEMPLATE_FILES_SPRITE color_space.glsl light_cookie.glsl light_shadow.glsl quad_common.glsl)
# The sky template @includes color_space.glsl (fa_scene_rgb), so a change to it changes the sky hash too.
set(FA_TEMPLATE_FILES_SKY color_space.glsl sky_common.glsl)
set(FA_TEMPLATE_FILES_POST post_common.glsl)
set(FA_TEMPLATE_FILES_COMPUTE compute_common.glsl)
set(FA_TEMPLATE_DEFINITIONS "")
foreach(kind MESH MESH_FULL SPRITE SKY POST COMPUTE)
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
    # A kind without a template (compute) defines nothing: an empty quoted define is not portable (material_template_hash returns {}).
    if(NOT list STREQUAL "")
        list(APPEND FA_TEMPLATE_DEFINITIONS "FA_TEMPLATE_HASH_${kind}=\"${FA_TEMPLATE_HASH_${kind}}\"")
    endif()
endforeach()
set_source_files_properties(src/custom_shader.cpp PROPERTIES COMPILE_DEFINITIONS "${FA_TEMPLATE_DEFINITIONS}")

# Third-party implementation TUs: no warnings.
if(MSVC)
    set_source_files_properties(src/stb_impl.cpp PROPERTIES COMPILE_OPTIONS "/w")
else()
    set_source_files_properties(src/stb_impl.cpp PROPERTIES COMPILE_OPTIONS "-w")
endif()
if(APPLE)
    set_source_files_properties(src/readback_metal.mm src/gpu_info_metal.mm src/metalfx_apple.mm PROPERTIES COMPILE_OPTIONS "-fobjc-arc")
endif()

fa_add_tests(render LABELS gpu)  # REQUIRE a GPU (Gfx::ok): a host without one runs `ctest -LE gpu`
# The CPU core of the frame graph needs no GPU: its tests also run on a host that runs `ctest -LE gpu`.
if(TARGET fa_test_render)
    add_test(NAME render_frame_graph_core
        COMMAND fa_test_render --fa-files=frame_graph_tests.cpp
        WORKING_DIRECTORY ${FA_ROOT})
    # The GPU interface (src/gpu/): RecordingDevice and the conversions need no GPU; the SokolDevice case skips itself.
    add_test(NAME render_gpu_interface_core
        COMMAND fa_test_render --fa-files=gpu_interface_tests.cpp
        WORKING_DIRECTORY ${FA_ROOT})
    # The engine's own D3D12 backend (src/gpu/d3d12_*): on Windows its cases run on WARP with the debug layer (and say
    # so and pass when this Windows has neither); elsewhere one case checks the factory's error.
    add_test(NAME render_d3d12_device
        COMMAND fa_test_render --fa-files=d3d12_device_tests.cpp
        WORKING_DIRECTORY ${FA_ROOT})
    # Its DirectStorage reads of game.pak into buffers and textures (src/gpu/d3d12_pack_reads_win32.cpp): with the DLLs
    # of `factoria setup directstorage` (FA_DIRECTSTORAGE_DIR) DirectStorage writes them, else the CPU fallback does (the
    # DirectStorage cases say so and pass, or fail with FA_DIRECTSTORAGE_REQUIRE=1).
    add_test(NAME render_d3d12_pack_reads
        COMMAND fa_test_render --fa-files=d3d12_pack_reads_tests.cpp
        WORKING_DIRECTORY ${FA_ROOT})
    # The engine's own Vulkan backend (src/gpu/vulkan_*): its cases run on the machine's Vulkan device (MoltenVK on
    # macOS, lavapipe on Linux CI) with the validation layer, and say so and pass where there is no loader or no device;
    # where the backend is not built one case checks the factory's error.
    add_test(NAME render_vulkan_device
        COMMAND fa_test_render --fa-files=vulkan_device_tests.cpp
        WORKING_DIRECTORY ${FA_ROOT})
endif()
# The Vulkan backend (src/gpu/vulkan_*.cpp): built on Linux, Windows and Android, and on macOS for its tests only (through
# MoltenVK; never a macOS product backend); not on the web or iOS. No Vulkan library is linked: the sources compile with
# VK_NO_PROTOTYPES against the vendored Khronos headers and open the system's loader at run time.
if(FA_PLATFORM STREQUAL "linux" OR FA_PLATFORM STREQUAL "windows" OR FA_PLATFORM STREQUAL "android" OR
   FA_PLATFORM STREQUAL "macos")
    set(FA_VULKAN_BACKEND_DEFAULT ON)
else()
    set(FA_VULKAN_BACKEND_DEFAULT OFF)
endif()
option(FA_VULKAN_BACKEND "Build the engine's own Vulkan backend (fa::gpu::make_vulkan_device)" ${FA_VULKAN_BACKEND_DEFAULT})
if(FA_VULKAN_BACKEND AND (FA_PLATFORM STREQUAL "web" OR FA_PLATFORM STREQUAL "ios"))
    message(STATUS "FactorIA: FA_VULKAN_BACKEND is not built for ${FA_PLATFORM}")
    set(FA_VULKAN_BACKEND OFF)
endif()
if(FA_VULKAN_BACKEND)
    foreach(t fa_render fa_test_render)
        if(TARGET ${t})
            target_compile_definitions(${t} PRIVATE FA_VULKAN_BACKEND=1 VK_NO_PROTOTYPES)
            target_include_directories(${t} SYSTEM PRIVATE ${FA_ROOT}/external/vulkan_headers/include)
        endif()
    endforeach()
    if(FA_PLATFORM STREQUAL "linux" OR FA_PLATFORM STREQUAL "android")
        target_link_libraries(fa_render PRIVATE ${CMAKE_DL_LIBS})  # dlopen of libvulkan.so.1
    endif()
endif()
# The D3D12 backend (src/gpu/d3d12_*_win32.cpp) links the D3D12 runtime and DXGI; fa_platform links dxgi and dxguid
# already (D3D11), named again here because this module calls them itself.
if(FA_PLATFORM STREQUAL "windows")
    target_link_libraries(fa_render PRIVATE d3d12 dxgi dxguid)
endif()
# The D3D12 backend reads pack ranges with DirectStorage through fa_core's plan and declarations of its API: that one
# private folder of fa_core, and nothing else of it (docs/design/ARCHITECTURE_FILES.md, "DirectStorage").
target_include_directories(fa_render PRIVATE ${FA_ROOT}/engine/core/src/direct_storage)
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
        COMMAND fa_test_render --fa-files=postprocess_resolve_tests.cpp,hdr_encode_tests.cpp,postfx_tests.cpp,mesh_slots_tests.cpp,light_clusters_tests.cpp,shadow_cascades_tests.cpp,local_shadows_tests.cpp,decal_tests.cpp,ies_tests.cpp,light_atlas_tests.cpp,probe_tests.cpp,gi_tests.cpp,terrain_lod_tests.cpp,occlusion_tests.cpp,portal_graph_tests.cpp,spirv_shader_tests.cpp
        WORKING_DIRECTORY ${FA_ROOT})
endif()
