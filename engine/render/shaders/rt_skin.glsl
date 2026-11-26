// shdc-slang: glsl430:metal_macos:metal_ios:metal_sim:hlsl5:spirv_vk
// The skinning of the ray tracing scene (M79 P1k, engine/render/src/rt_scene.cpp, docs/design/ARCHITECTURE_RT_SCENE.md, "Skinned meshes"): one thread
// per vertex of a skinned part writes the skinned position (x, y, z; model space, the instance's transform is applied by the TLAS) into a
// per-instance storage buffer, which the acceleration structure build of that instance reads. It is the vertex shader's maths (mesh_common.glsl,
// fa_skin_matrix and vs_skin): the same 64-joint palette of 3 rows per joint (a 3x4 matrix), the same four influences, the same bytes of
// joints. rt_skin.h holds the CPU twin the tests compare with. No GLES3 / WebGL2 version exists (compute shaders), like hiz.glsl: the
// compile script gives this file its own dialect list.
@module rt_skin

@cs cs
layout(local_size_x=64, local_size_y=1, local_size_z=1) in;
struct rt_skin_vertex { float f; };                       // MeshVertex: 13 floats, the position first (stride 52 bytes)
struct rt_skin_influence { uint u; };                     // SkinVertex: 5 words: the four joint bytes, then the four weights as float bits
struct rt_skin_row { vec4 v; };                           // the palette: 3 rows per joint
struct rt_skin_out { float f; };                          // 3 floats per vertex
layout(binding=0) readonly buffer rt_skin_vertices_buf { rt_skin_vertex data[]; } rt_skin_vertices;
layout(binding=1) readonly buffer rt_skin_influences_buf { rt_skin_influence data[]; } rt_skin_influences;
layout(binding=2) readonly buffer rt_skin_palette_buf { rt_skin_row data[]; } rt_skin_palette;
layout(binding=3) writeonly buffer rt_skin_out_buf { rt_skin_out data[]; } rt_skin_dst;
layout(binding=0) uniform rt_skin_params {
    ivec4 dims;     // x = the vertex count of the part, y = the first row of this instance's palette in the palette buffer (192 rows each)
};

void main() {
    uint i = gl_GlobalInvocationID.x;
    if (i >= uint(dims.x)) return;
    vec3 p = vec3(rt_skin_vertices.data[i * 13u].f, rt_skin_vertices.data[i * 13u + 1u].f, rt_skin_vertices.data[i * 13u + 2u].f);
    uint packed_joints = rt_skin_influences.data[i * 5u].u;
    vec4 r0 = vec4(0.0), r1 = vec4(0.0), r2 = vec4(0.0);
    for (uint k = 0u; k < 4u; ++k) {
        uint j = min((packed_joints >> (8u * k)) & 255u, 63u);   // a byte past the palette: the last joint, never a read out of range
        float w = uintBitsToFloat(rt_skin_influences.data[i * 5u + 1u + k].u);
        uint row = uint(dims.y) + j * 3u;
        r0 += rt_skin_palette.data[row].v * w;
        r1 += rt_skin_palette.data[row + 1u].v * w;
        r2 += rt_skin_palette.data[row + 2u].v * w;
    }
    vec4 q = vec4(p, 1.0);
    rt_skin_dst.data[i * 3u].f = dot(r0, q);
    rt_skin_dst.data[i * 3u + 1u].f = dot(r1, q);
    rt_skin_dst.data[i * 3u + 2u].f = dot(r2, q);
}
@end

@program rt_skin cs
