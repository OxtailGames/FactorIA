fa_add_module(script
    DEPS fa_core fa_scene fa_platform fa_render fa_physics fa_audio
    PRIVATE_DEPS fa_ext_quickjs)
fa_add_tests(script DEPS fa_runtime)
