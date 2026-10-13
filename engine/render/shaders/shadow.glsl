// Depth-only pass for the directional shadow map.
@module shadow

@vs vs
layout(binding=0) uniform shadow_vs_params {
    mat4 mvp;
};
layout(location=0) in vec3 position;
void main() {
    gl_Position = mvp * vec4(position, 1.0);
}
@end

@fs fs
out vec4 frag_color;
void main() {
    frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);
}
@end

@program shadow vs fs
