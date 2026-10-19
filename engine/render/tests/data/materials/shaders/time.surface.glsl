void surface(in SurfaceInput i, inout Surface s) {
    s.emission += vec3(0.5 + 0.5 * sin(fa_time.x * 3.0), 0.25 * fract(fa_time.x), 0.0);
}
