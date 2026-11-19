// Test fixture: instance k reads element k in vertex() (place, collapse) and in fragment() (colour).
void vertex(inout QuadVertex v) {
    vec4 p = points.data[fa_instance_index].pos;
    v.world_pos.xy = p.xy + v.world_pos.xy * p.w;
}

void fragment(in QuadInput i, inout QuadSurface s) {
    s.color.rgb = points.data[fa_instance_index].tint.rgb;
}
