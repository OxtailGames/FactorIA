fa_add_module(core
    DEPS fa_ext_json
    PRIVATE_DEPS fa_ext_stb)
if(FA_PLATFORM STREQUAL "android")
    target_link_libraries(fa_core PRIVATE android log)
endif()
fa_add_tests(core)
