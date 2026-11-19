// Test fixture: two buffers read for the same instance in vertex(); `points` places and colours it, `extra` can hide it.
void vertex(inout VertexData v) {
    vec4 p = points.data[fa_instance_index].pos;
    if (p.w < 0.5 || extra.data[fa_instance_index].pos.w < -1.0) {
        v.world_pos = vec3(1.0e9);  // outside the clip volume: nothing of this instance is drawn
        return;
    }
    v.world_pos += p.xyz;
    v.color = points.data[fa_instance_index].tint;
}

void surface(in SurfaceInput i, inout Surface s) {
    s.emission += i.vertex_color.rgb * points.data[0].tint.a;
}
