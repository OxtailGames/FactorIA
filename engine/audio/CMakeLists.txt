fa_add_module(audio
    DEPS fa_core fa_scene fa_platform
    PRIVATE_DEPS fa_ext_sokol fa_ext_stb fa_ext_drlibs fa_ext_qoa)
fa_add_tests(audio)
