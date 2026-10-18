// Depth-only pass for the directional shadow map. Instanced like mesh.glsl (model matrix columns at locations 1..4: attributes must be contiguous).
@module shadow

@vs vs
layout(binding=0) uniform shadow_vs_params {
    mat4 light_vp;
};
layout(location=0) in vec3 position;
layout(location=1) in vec4 inst_m0;
layout(location=2) in vec4 inst_m1;
layout(location=3) in vec4 inst_m2;
layout(location=4) in vec4 inst_m3;
void main() {
    gl_Position = light_vp * (mat4(inst_m0, inst_m1, inst_m2, inst_m3) * vec4(position, 1.0));
}
@end

@fs fs
out vec4 frag_color;
void main() {
    frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);
}
@end

@program shadow vs fs
