@common
varying vec4 v_color;
varying vec2 v_uv;

@vertex
void main() {
    v_color = vertex_color1;
    v_uv = vertex_uv1;
    gl_Position = fa_view_proj * vec4(fa_world_position(fa_position), 1.0);
}

@fragment
void main() {
    fa_frag_color = vec4(v_color.rgb * (v_uv.x * 2.0), 1.0);
}
