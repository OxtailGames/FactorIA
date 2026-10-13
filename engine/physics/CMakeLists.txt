fa_add_module(physics
    DEPS fa_core fa_scene
    PRIVATE_DEPS fa_ext_box2d)
fa_add_tests(physics)
