void surface(in SurfaceInput i, inout Surface s) {
    s.emission += glow.rgb * glow.a;
}
