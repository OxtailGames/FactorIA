void surface(in SurfaceInput i, inout Surface s) {
    s.alpha = texture(sampler2D(mask, mask_smp), i.uv * 2.0).r;
}
