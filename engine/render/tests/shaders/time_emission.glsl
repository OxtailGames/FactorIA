// Test material of render3d_tests.cpp: the mesh template with a snippet whose emission follows fa_time, so a golden
// shows that the renderer fills fa_time from the engine clock. Compiled by tools/shaders/compile_shaders.sh like the
// engine's shaders (header committed next to it).
@module fa_test_time

@block fa_user
void surface(in SurfaceInput i, inout Surface s) {
    s.emission += vec3(0.5 + 0.5 * sin(fa_time.x * 3.0), 0.25 * fract(fa_time.x), 0.0);
}
@end

@include ../../shaders/mesh_common.glsl

@program mesh vs fs
