# fa_ltc: our own Linearly Transformed Cosines tables for area lights (docs/design/ARCHITECTURE_AREA_LIGHTS.md): the deterministic fit
# of the tables for the BRDF of engine/render/shaders/mesh_common.glsl, the CPU reference of the polygon integral and the generator
# of the committed header engine/render/src/ltc_tables.h (tools/ltc/generate_ltc.sh, or the target fa_ltc_regenerate). It uses only
# fa_core (the job system); nothing of the engine includes it, the renderer includes the generated header.
fa_add_module(ltc DEPS fa_core)

add_executable(fa_ltc_gen gen/main.cpp)
target_link_libraries(fa_ltc_gen PRIVATE fa_ltc fa_warnings)

# `cmake --build <dir> --target fa_ltc_regenerate` rewrites the header from the fit. Not part of `all`: the header is committed.
add_custom_target(fa_ltc_regenerate
    COMMAND fa_ltc_gen --out ${FA_ROOT}/engine/render/src/ltc_tables.h
    WORKING_DIRECTORY ${FA_ROOT}
    DEPENDS fa_ltc_gen
    COMMENT "Fitting the LTC tables (seconds in a Release tree, minutes in Debug: it builds fa_ltc_gen in the tree's configuration) and writing engine/render/src/ltc_tables.h"
    VERBATIM)

if(FA_BUILD_TESTS)
    # Written out instead of fa_add_tests(): the quick cases and the slow one are two ctest entries of the same program.
    file(GLOB fa_ltc_tests CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/tests/*.cpp)
    add_executable(fa_test_ltc ${fa_ltc_tests} ${FA_ROOT}/cmake/doctest_main.cpp)
    target_link_libraries(fa_test_ltc PRIVATE fa_ltc fa_ext_doctest fa_warnings)
    # fa_test_paths.h (FA_REPO_ROOT), and the generated header, included by name from the renderer's private folder.
    target_include_directories(fa_test_ltc PRIVATE ${FA_GENERATED_DIR} ${FA_ROOT}/engine/render/src)
    add_test(NAME ltc COMMAND fa_test_ltc "--test-case-exclude=*(slow)*" WORKING_DIRECTORY ${FA_ROOT})
    # The slow case fits the whole 64 x 64 table again and compares it with the committed header (about a minute in an
    # optimized build, much longer unoptimized): ctest label `slow`, DISABLED in a Debug build like the example games' tests
    # (docs/design/BUILDING_TESTS.md); `ctest -L slow` runs it.
    set(fa_ltc_slow_disabled false)
    if(FA_SANITIZE OR ((CMAKE_BUILD_TYPE STREQUAL "Debug" OR CMAKE_BUILD_TYPE STREQUAL "") AND NOT CMAKE_CONFIGURATION_TYPES))
        set(fa_ltc_slow_disabled true)
    endif()
    # A multi-config generator (Visual Studio, Xcode) runs it only for the optimized configurations: `ctest -C Debug` would fit the table
    # unoptimised and may pass the TIMEOUT.
    set(fa_ltc_slow_configs)
    if(CMAKE_CONFIGURATION_TYPES)
        set(fa_ltc_slow_configs CONFIGURATIONS Release RelWithDebInfo MinSizeRel)
    endif()
    add_test(NAME ltc_tables_up_to_date COMMAND fa_test_ltc "--test-case=*(slow)*" WORKING_DIRECTORY ${FA_ROOT}
             ${fa_ltc_slow_configs})
    set_tests_properties(ltc_tables_up_to_date PROPERTIES LABELS "slow" TIMEOUT 900 DISABLED ${fa_ltc_slow_disabled})
endif()
