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

// Skinned variant (same joint palette layout as mesh.glsl, vertex buffer 2: joints at location 5, weights at 6).
@vs vs_skin
layout(binding=0) uniform shadow_vs_params {
    mat4 light_vp;
};
layout(binding=1) uniform shadow_skin {
    vec4 joint_rows[192];
};
layout(location=0) in vec3 position;
layout(location=1) in vec4 inst_m0;
layout(location=2) in vec4 inst_m1;
layout(location=3) in vec4 inst_m2;
layout(location=4) in vec4 inst_m3;
layout(location=5) in vec4 joints;
layout(location=6) in vec4 weights;
void main() {
    vec4 r0 = vec4(0.0), r1 = vec4(0.0), r2 = vec4(0.0);
    for (int i = 0; i < 4; ++i) {
        int j = int(joints[i] * 255.0 + 0.5) * 3;
        float w = weights[i];
        r0 += joint_rows[j] * w;
        r1 += joint_rows[j + 1] * w;
        r2 += joint_rows[j + 2] * w;
    }
    mat4 skin = mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0),
                     vec4(r0.w, r1.w, r2.w, 1.0));
    gl_Position = light_vp * (mat4(inst_m0, inst_m1, inst_m2, inst_m3) * skin * vec4(position, 1.0));
}
@end

@fs fs
out vec4 frag_color;
void main() {
    frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);
}
@end

@program shadow vs fs
@program shadow_skin vs_skin fs
