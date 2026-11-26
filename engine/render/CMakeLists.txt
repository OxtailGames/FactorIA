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
    set_source_files_properties(src/readback_metal.mm src/gpu_info_metal.mm src/metalfx_apple.mm src/gpu/metal_accel_apple.mm PROPERTIES COMPILE_OPTIONS "-fobjc-arc")
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
    # macOS; Mesa's lavapipe on the Linux CI job, which installs it and the validation layers and sets
    # FA_VULKAN_REQUIRE=1 so a skip fails) with the validation layer and its synchronization validation, and say so and
    # pass where there is no loader or no device; where the backend is not built one case checks the factory's error.
    add_test(NAME render_vulkan_device
        COMMAND fa_test_render --fa-files=vulkan_device_tests.cpp
        WORKING_DIRECTORY ${FA_ROOT})
    # Native access for vendor SDKs (M78): the neutral checks and the sokol device, then raw commands recorded between
    # begin_native and end_native on Vulkan and on D3D12 (WARP), and the device hooks (vulkan_hooks_tests.cpp, the
    # D3D12 ones in d3d12_native_tests.cpp), under the same skip rules as the two backends' cases.
    add_test(NAME render_gpu_native
        COMMAND fa_test_render
            --fa-files=gpu_native_tests.cpp,vulkan_native_tests.cpp,vulkan_hooks_tests.cpp,d3d12_native_tests.cpp
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
# The renderer on the Vulkan backend (make_device(Backend::Vulkan), RendererDesc::backend): fa_render compiles the SPIR-V
# of every built-in shader (FA_SHADERS_SPIRV opens its guard in the generated headers), about 3.4 MB. AUTO (the
# default, worked out again at every configure): ON on Windows, where one player carries D3D11, D3D12 and Vulkan; on
# Linux, Android and macOS it follows FA_BUILD_TESTS, so the render tests draw a frame on Vulkan (lavapipe, MoltenVK)
# while a build without tests (the release players and editor) carries no SPIR-V; OFF on the web and iOS. ON or OFF
# overrides it. Needs FA_VULKAN_BACKEND.
set(FA_RENDER_VULKAN AUTO CACHE STRING
    "The renderer draws on the Vulkan backend (fa_render carries the SPIR-V of its shaders): AUTO, ON or OFF")
set_property(CACHE FA_RENDER_VULKAN PROPERTY STRINGS AUTO ON OFF)
string(TOUPPER "${FA_RENDER_VULKAN}" _fa_render_vulkan_mode)
if(_fa_render_vulkan_mode STREQUAL "AUTO")
    if(FA_PLATFORM STREQUAL "windows")
        set(_fa_render_vulkan ON)
    elseif(FA_PLATFORM STREQUAL "linux" OR FA_PLATFORM STREQUAL "android" OR FA_PLATFORM STREQUAL "macos")
        set(_fa_render_vulkan ${FA_BUILD_TESTS})
    else()
        set(_fa_render_vulkan OFF)
    endif()
elseif(FA_RENDER_VULKAN)
    set(_fa_render_vulkan ON)
else()
    set(_fa_render_vulkan OFF)
endif()
if(_fa_render_vulkan AND NOT FA_VULKAN_BACKEND)
    message(STATUS "FactorIA: FA_RENDER_VULKAN needs FA_VULKAN_BACKEND, which is off: the renderer has no Vulkan")
    set(_fa_render_vulkan OFF)
endif()
message(STATUS "FactorIA: the renderer on Vulkan (FA_RENDER_VULKAN ${FA_RENDER_VULKAN}): ${_fa_render_vulkan}")
if(_fa_render_vulkan)
    target_compile_definitions(fa_render PRIVATE FA_RENDER_VULKAN=1 FA_SHADERS_SPIRV)
    # The tests ask whether the renderer has Vulkan; a test file that needs the SPIR-V defines FA_SHADERS_SPIRV itself.
    if(TARGET fa_test_render)
        target_compile_definitions(fa_test_render PRIVATE FA_RENDER_VULKAN=1)
    endif()
endif()
# The Vulkan player of Linux and Android (M77-P9e2, docs/RENDERING.md "Choosing the GPU backend"): factoria_player_vulkan
# (libfactoria_player_vulkan.so) draws with Vulkan and hands over to factoria_player (OpenGL) when Vulkan cannot start, so
# the OpenGL player stays as small as it was. Its renderer is fa_render with FA_RENDER_VULKAN: target fa_render_vulkan.
# Where fa_render has it already (a build with the tests), fa_render_vulkan adds nothing. Otherwise it is an OBJECT library
# of only the sources whose code depends on the defines (the ones that include a generated shaders/*.glsl.h, directly or
# through a header such as renderer_impl.h, and the ones that test FA_RENDER_VULKAN or FA_SHADERS_SPIRV), compiled with
# fa_render's flags plus the defines. The player links those objects before libfa_render.a, so the linker takes them and
# never pulls the archive's members of the same sources (a symbol defined twice fails the link loudly). The list is worked
# out at configure time: a source that starts including a shader header joins it at the next configure (CI configures
# from scratch).
set(FA_PLAYER_VULKAN_DEFAULT OFF)
if(FA_VULKAN_BACKEND AND (FA_PLATFORM STREQUAL "linux" OR FA_PLATFORM STREQUAL "android"))
    set(FA_PLAYER_VULKAN_DEFAULT ON)
endif()
option(FA_PLAYER_VULKAN "Build the Vulkan player of Linux and Android (factoria_player_vulkan) next to the OpenGL one"
       ${FA_PLAYER_VULKAN_DEFAULT})
# macOS only when asked for (-DFA_PLAYER_VULKAN=ON): a check of the build on a Mac, never a macOS product (MoltenVK).
if(FA_PLAYER_VULKAN AND (NOT FA_VULKAN_BACKEND OR NOT (FA_PLATFORM STREQUAL "linux" OR FA_PLATFORM STREQUAL "android" OR
                                                       FA_PLATFORM STREQUAL "macos")))
    message(STATUS "FactorIA: FA_PLAYER_VULKAN is for Linux and Android with FA_VULKAN_BACKEND: no Vulkan player")
    set(FA_PLAYER_VULKAN OFF)
endif()
set(FA_PLAYER_VULKAN ${FA_PLAYER_VULKAN} PARENT_SCOPE)
if(FA_PLAYER_VULKAN AND _fa_render_vulkan)
    add_library(fa_render_vulkan INTERFACE)
    message(STATUS "FactorIA: the Vulkan player uses fa_render as it is (it has FA_RENDER_VULKAN)")
elseif(FA_PLAYER_VULKAN)
    file(GLOB_RECURSE _fa_rv_headers ${CMAKE_CURRENT_SOURCE_DIR}/src/*.h)
    file(GLOB_RECURSE _fa_rv_sources ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)
    _fa_filter_platform_sources(_fa_rv_sources ${_fa_rv_sources})
    set(_fa_rv_marker "\n[ \t]*#[ \t]*(if|ifdef|ifndef|elif)[^\n]*(FA_RENDER_VULKAN|FA_SHADERS_SPIRV)")
    # The generated shader headers depend on FA_SHADERS_SPIRV by construction (and are megabytes: not read).
    set(_fa_rv_names "")
    set(_fa_rv_rest "")
    set(_fa_rv_i 0)
    foreach(h ${_fa_rv_headers})
        get_filename_component(n ${h} NAME)
        if(n MATCHES "\\.glsl\\.h$")
            list(APPEND _fa_rv_names ${n})
            continue()
        endif()
        file(READ ${h} t)
        set(t "\n${t}")
        if(t MATCHES "${_fa_rv_marker}")
            list(APPEND _fa_rv_names ${n})
            continue()
        endif()
        string(REGEX MATCHALL "#[ \t]*include[ \t]*\"[^\"]+\"" incs "${t}")
        string(REGEX REPLACE "#[ \t]*include[ \t]*\"([^\"]*/)?([^\"/]+)\"" "\\2" incs "${incs}")
        math(EXPR _fa_rv_i "${_fa_rv_i} + 1")
        set(_fa_rv_name_${_fa_rv_i} ${n})
        set(_fa_rv_incs_${_fa_rv_i} ${incs})
        list(APPEND _fa_rv_rest ${_fa_rv_i})
    endforeach()
    # Headers that include a variant header are variant too, until nothing more is added.
    set(_fa_rv_changed ON)
    while(_fa_rv_changed)
        set(_fa_rv_changed OFF)
        set(_fa_rv_left "")
        foreach(i ${_fa_rv_rest})
            set(hit OFF)
            foreach(inc ${_fa_rv_incs_${i}})
                if(inc IN_LIST _fa_rv_names)
                    set(hit ON)
                    break()
                endif()
            endforeach()
            if(hit)
                list(APPEND _fa_rv_names ${_fa_rv_name_${i}})
                set(_fa_rv_changed ON)
            else()
                list(APPEND _fa_rv_left ${i})
            endif()
        endforeach()
        set(_fa_rv_rest ${_fa_rv_left})
    endwhile()
    set(_fa_rv_variant "")
    foreach(c ${_fa_rv_sources})
        file(READ ${c} t)
        set(t "\n${t}")
        set(hit OFF)
        if(t MATCHES "${_fa_rv_marker}")
            set(hit ON)
        else()
            string(REGEX MATCHALL "#[ \t]*include[ \t]*\"[^\"]+\"" incs "${t}")
            string(REGEX REPLACE "#[ \t]*include[ \t]*\"([^\"]*/)?([^\"/]+)\"" "\\2" incs "${incs}")
            foreach(inc ${incs})
                if(inc IN_LIST _fa_rv_names)
                    set(hit ON)
                    break()
                endif()
            endforeach()
        endif()
        if(hit)
            list(APPEND _fa_rv_variant ${c})
        endif()
    endforeach()
    list(LENGTH _fa_rv_variant _fa_rv_count)
    list(LENGTH _fa_rv_sources _fa_rv_total)
    message(STATUS "FactorIA: the Vulkan player compiles ${_fa_rv_count} of the ${_fa_rv_total} fa_render sources again with FA_RENDER_VULKAN")
    add_library(fa_render_vulkan OBJECT ${_fa_rv_variant})
    target_include_directories(fa_render_vulkan PRIVATE $<TARGET_PROPERTY:fa_render,INCLUDE_DIRECTORIES>)
    target_include_directories(fa_render_vulkan SYSTEM PRIVATE ${FA_ROOT}/external/vulkan_headers/include)
    target_compile_definitions(fa_render_vulkan PRIVATE $<TARGET_PROPERTY:fa_render,COMPILE_DEFINITIONS>
                               FA_RENDER_VULKAN=1 FA_SHADERS_SPIRV)
    target_compile_options(fa_render_vulkan PRIVATE $<TARGET_PROPERTY:fa_render,COMPILE_OPTIONS>)
    target_compile_features(fa_render_vulkan PRIVATE cxx_std_20)
    target_link_libraries(fa_render_vulkan PRIVATE $<TARGET_PROPERTY:fa_render,LINK_LIBRARIES>)
    add_dependencies(fa_render_vulkan fa_render)  # generated headers (embedded fonts) come with fa_render
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
        COMMAND fa_test_render --fa-files=postprocess_resolve_tests.cpp,hdr_encode_tests.cpp,postfx_tests.cpp,mesh_slots_tests.cpp,light_clusters_tests.cpp,shadow_cascades_tests.cpp,local_shadows_tests.cpp,decal_tests.cpp,ies_tests.cpp,light_atlas_tests.cpp,probe_tests.cpp,gi_tests.cpp,terrain_lod_tests.cpp,occlusion_tests.cpp,portal_graph_tests.cpp,spirv_shader_tests.cpp,rt_denoise_plan_tests.cpp
        WORKING_DIRECTORY ${FA_ROOT})
endif()
