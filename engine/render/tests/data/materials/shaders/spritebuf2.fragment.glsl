// Test fixture: two buffers read for the same instance; `points` places and colours it, `extra` can hide it.
void vertex(inout QuadVertex v) {
    vec4 p = points.data[fa_instance_index].pos;
    float hide = extra.data[fa_instance_index].pos.w < -1.0 ? 0.0 : 1.0;
    v.world_pos.xy = p.xy + v.world_pos.xy * p.w * hide;
}

void fragment(in QuadInput i, inout QuadSurface s) {
    s.color.rgb = points.data[fa_instance_index].tint.rgb;
}
