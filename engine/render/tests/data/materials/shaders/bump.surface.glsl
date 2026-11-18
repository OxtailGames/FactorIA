void vertex(inout VertexData v) {
    v.world_pos.y += texture(sampler2D(height, height_smp), v.uv).r * lift;
}

void surface(in SurfaceInput i, inout Surface s) {
    s.albedo *= mix(0.5, 1.0, texture(sampler2D(height, height_smp), i.uv).r);
}
