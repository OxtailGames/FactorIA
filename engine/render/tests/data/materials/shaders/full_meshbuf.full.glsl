@vertex
void main() {
    vec4 p = points.data[fa_instance_index].pos;
    vec4 clip = fa_view_proj * vec4(fa_world_position(fa_position) + p.xyz, 1.0);
    gl_Position = p.w < 0.5 ? vec4(2.0, 2.0, 2.0, 1.0) : clip;
}

@fragment
void main() {
    fa_frag_color = vec4(points.data[0].tint.rgb, 1.0);
}
