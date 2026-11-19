@common
varying vec3 v_pos;
varying vec3 v_normal;

@vertex
void main() {
    vec3 world = fa_world_position(fa_position);
    v_pos = world;
    v_normal = fa_world_direction(fa_normal);
    gl_Position = fa_view_proj * vec4(world, 1.0);
}

@fragment
void main() {
    vec3 n = normalize(v_normal);
    vec3 v = normalize(FA_CAMERA - v_pos);
    // The sky the engine's own meshes reflect: fa_sky_reflection is fa_environment weighted by fa_env_brdf, written out by hand
    // in the first half, called in the second.
    vec3 r = reflect(-v, n);
    vec2 ab = fa_env_brdf(0.1, max(dot(n, v), 1e-4));
    vec3 byHand = fa_environment(r, 0.1) * (vec3(1.0) * ab.x + ab.y);
    vec3 sky = 0.5 * byHand + 0.5 * fa_sky_reflection(n, v, vec3(1.0), 0.1);
    fa_frag_color = vec4(sky, 1.0);
}
