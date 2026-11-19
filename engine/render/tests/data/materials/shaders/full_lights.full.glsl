@common
varying vec3 v_pos;
varying vec3 v_normal;
varying vec4 v_shadow;

@vertex
void main() {
    vec3 world = fa_world_position(fa_position);
    v_pos = world;
    v_normal = fa_world_direction(fa_normal);
    v_shadow = fa_shadow_coord(world);
    gl_Position = fa_view_proj * vec4(world, 1.0);
}

@fragment
void main() {
    vec3 n = normalize(v_normal);
    vec3 lit = fa_ambient.rgb * base.rgb;
    for (int i = 0; i < fa_light_count(); ++i) {
        LightSample l = fa_light(i, v_pos, n, v_shadow);
        lit += base.rgb * l.color * max(dot(n, l.direction), 0.0);
    }
    fa_frag_color = vec4(fa_apply_fog(lit, v_pos), 1.0);
}
