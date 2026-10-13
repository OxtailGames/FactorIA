// Vertical sky gradient for perspective cameras (full-screen triangle).
@module sky

@vs vs
layout(binding=0) uniform sky_vs_params {
    mat4 inv_view_proj;
    vec4 cam_pos;
};
layout(location=0) in vec2 pos;
out vec3 ray_dir;
void main() {
    gl_Position = vec4(pos, 1.0, 1.0);
    vec4 far_pt = inv_view_proj * vec4(pos, 1.0, 1.0);
    ray_dir = far_pt.xyz / far_pt.w - cam_pos.xyz;
}
@end

@fs fs
layout(binding=1) uniform sky_fs_params {
    vec4 sky_color;
    vec4 horizon_color;
};
in vec3 ray_dir;
out vec4 frag_color;
void main() {
    float h = clamp(normalize(ray_dir).y, 0.0, 1.0);
    float t = pow(h, 0.55);
    frag_color = vec4(mix(horizon_color.rgb, sky_color.rgb, t), 1.0);
}
@end

@program sky vs fs
