@vertex
void main() {
    vec3 p = fa_position;
#ifdef FA_PASS_OUTLINE
    p += normalize(fa_normal) * outlineWidth;
#endif
    gl_Position = fa_view_proj * vec4(fa_world_position(p), 1.0);
}

@fragment
void main() {
#ifdef FA_PASS_OUTLINE
    fa_frag_color = vec4(outlineColor.rgb, 1.0);
#else
    fa_frag_color = vec4(bodyColor.rgb, 1.0);
#endif
}
