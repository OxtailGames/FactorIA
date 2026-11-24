void surface(in SurfaceInput i, inout Surface s) {
    s.albedo = vec3(-fa_mip_bias * 0.25);
    s.alpha = 1.0;
}
