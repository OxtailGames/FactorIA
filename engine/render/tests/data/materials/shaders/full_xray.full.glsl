@vertex
void main() {
    gl_Position = fa_view_proj * vec4(fa_world_position(fa_position), 1.0);
}

@fragment
void main() {
#ifdef FA_PASS_XRAY
    fa_frag_color = vec4(1.0, 1.0, 0.0, 1.0);
#else
    fa_frag_color = vec4(0.0, 0.0, 1.0, 1.0);
#endif
}
