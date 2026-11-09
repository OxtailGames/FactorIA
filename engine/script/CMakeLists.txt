fa_add_module(script
    DEPS fa_core fa_scene fa_platform fa_render fa_physics fa_audio fa_ui fa_services
    PRIVATE_DEPS fa_ext_quickjs)

# JavaScript preludes + API description are baked into the binary.
file(GLOB FA_SCRIPT_JS CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/js/*.js ${CMAKE_CURRENT_SOURCE_DIR}/src/js/*.json)
fa_embed_files(fa_script fa::script_js fa_script_js BASE ${CMAKE_CURRENT_SOURCE_DIR}/src/js FILES ${FA_SCRIPT_JS})

fa_add_tests(script)

# ---- deterministic Math for the scripts (M91.3) -----------------------------------------------------------------------
# QuickJS calls the C library for Math.sin/cos/tan/exp/log/pow/atan2/... and for **. Those round differently on every platform,
# so a script's result (and a replay) would differ between machines. quickjs_det_math.h is force-included into the QuickJS C
# files and turns each such call into fa_det_*, which quickjs_det_shim.cpp forwards to fa::det::f64 (core/det_math.h). external/
# stays untouched; the shim is compiled into fa_ext_quickjs so the symbols resolve inside that library whatever the link order.
set(FA_QUICKJS_DET_DIR ${CMAKE_CURRENT_SOURCE_DIR}/quickjs_det)
target_sources(fa_ext_quickjs PRIVATE ${FA_QUICKJS_DET_DIR}/quickjs_det_shim.cpp)
target_include_directories(fa_ext_quickjs PRIVATE ${FA_QUICKJS_DET_DIR} ${FA_ROOT}/engine/core/include)
# The header is named without a directory: it is found through the include directory above (-include / /FI search the include
# path like #include "..."), so a checkout path with spaces needs no quoting in either option. SHELL: keeps "-include" and
# its argument together when CMake removes duplicate options.
if(MSVC)
    target_compile_options(fa_ext_quickjs PRIVATE "$<$<COMPILE_LANGUAGE:C>:/FIquickjs_det_math.h>")
else()
    target_compile_options(fa_ext_quickjs PRIVATE "$<$<COMPILE_LANGUAGE:C>:SHELL:-include quickjs_det_math.h>")
endif()
