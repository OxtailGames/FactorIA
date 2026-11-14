fa_add_module(physics
    DEPS fa_core fa_scene
    PRIVATE_DEPS fa_ext_box2d)
fa_add_tests(physics)
# The cross-platform replay hash on its own, so CI prints it: `ctest -R physics_determinism -V` (test_determinism.cpp).
if(TARGET fa_test_physics)
    # test_manifold3d.cpp includes the private physics_internal.h, which includes Box2D.
    target_link_libraries(fa_test_physics PRIVATE fa_ext_box2d)
    add_test(NAME physics_determinism COMMAND fa_test_physics "-tc=physics replay*" WORKING_DIRECTORY ${FA_ROOT})
endif()
