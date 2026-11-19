@vertex
void main() {
    gl_Position = fa_view_proj * vec4(fa_world_position(fa_position), 1.0);
}

@fragment
void main() {
    fa_frag_color = vec4(tint.rgb, 1.0);
}
