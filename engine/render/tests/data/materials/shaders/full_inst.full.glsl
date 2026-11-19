@common
varying vec2 v_uv;

@vertex
void main() {
    float h = texture(sampler2D(height, height_smp), fa_texcoord0).r;
    vec3 world = fa_world_position(fa_position) + vec3(0.0, raise + h * 0.1, 0.0);
    v_uv = fa_texcoord0;
    gl_Position = fa_view_proj * vec4(world, 1.0);
}

@fragment
void main() {
    float h = texture(sampler2D(height, height_smp), v_uv).r;
#ifdef FA_SHADOW_PASS
    if (h < 0.01) discard;
#endif
    fa_frag_color = vec4(tint.rgb * boost * h, 1.0);
}
