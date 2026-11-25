// shdc-slang: spirv_vk
// The test shaders of the engine's own Vulkan backend (engine/render/tests/vulkan_device_tests.cpp): the GLSL twins of the
// HLSL ones d3d12_device_tests.cpp compiles at run time. tools/shaders/compile_shaders.sh makes vulkan_test.glsl.h next to
// this file, with SPIR-V only; a test includes it with FA_SHADERS_SPIRV defined.
@module vktest

// A fullscreen triangle at depth vs_params.depth.x, filled with fs_params.color.
@vs fill_vs
layout(binding=0) uniform vs_params { vec4 depth; };
void main() {
    vec2 p = vec2(float((gl_VertexIndex << 1) & 2), float(gl_VertexIndex & 2));
    gl_Position = vec4(p * vec2(2.0, -2.0) + vec2(-1.0, 1.0), depth.x, 1.0);
}
@end

@fs fill_fs
layout(binding=1) uniform fs_params { vec4 color; };
out vec4 frag_color;
void main() { frag_color = color; }
@end

@program fill fill_vs fill_fs

// The same triangle at depth 0, no uniforms.
@vs plain_vs
void main() {
    vec2 p = vec2(float((gl_VertexIndex << 1) & 2), float(gl_VertexIndex & 2));
    gl_Position = vec4(p * vec2(2.0, -2.0) + vec2(-1.0, 1.0), 0.0, 1.0);
}
@end

// The sum of two textures, each sampled at its centre with its own sampler, times two_params.scale.
@fs two_views_fs
layout(binding=0) uniform texture2D tex_a;
layout(binding=1) uniform texture2D tex_b;
layout(binding=0) uniform sampler smp_a;
layout(binding=1) uniform sampler smp_b;
layout(binding=0) uniform two_params { vec4 scale; };
out vec4 frag_color;
void main() {
    frag_color = (texture(sampler2D(tex_a, smp_a), vec2(0.5)) + texture(sampler2D(tex_b, smp_b), vec2(0.5))) * scale;
}
@end

@program two_views plain_vs two_views_fs

// Positions from vertex buffer 0, moved right by the instance index; instance 0 is red, the others green.
@vs instance_vs
layout(location=0) in vec2 pos;
flat out int inst;
void main() {
    gl_Position = vec4(pos.x + float(gl_InstanceIndex), pos.y, 0.0, 1.0);
    inst = gl_InstanceIndex;
}
@end

@fs instance_fs
flat in int inst;
out vec4 frag_color;
void main() { frag_color = inst == 0 ? vec4(1.0, 0.0, 0.0, 1.0) : vec4(0.0, 1.0, 0.0, 1.0); }
@end

@program instance instance_vs instance_fs

// Two vertex buffers: a position and a colour in buffer 0 (offsets left at 0: packed), a shift at an offset of its own
// in buffer 1 (the mesh vertex next to the instance data). The colour is drawn as it is.
@vs two_buffers_vs
layout(location=0) in vec2 pos;
layout(location=1) in vec4 color0;
layout(location=2) in vec2 shift;
out vec4 color;
void main() {
    gl_Position = vec4(pos + shift, 0.0, 1.0);
    color = color0;
}
@end

@fs two_buffers_fs
in vec4 color;
out vec4 frag_color;
void main() { frag_color = color; }
@end

@program two_buffers two_buffers_vs two_buffers_fs

// Mode 0 writes texel (x, y) of an 8x8 image and word x + 8y of a buffer; mode 1 doubles each word plus one, so it
// reads what mode 0 wrote.
@cs compute_cs
layout(local_size_x=8, local_size_y=8, local_size_z=1) in;
layout(binding=0, rgba8) uniform writeonly image2D img;
struct word_item { uint v; };
layout(binding=1) buffer words_buf { word_item words[]; };
layout(binding=0) uniform cs_params { ivec4 mode; };
void main() {
    uint i = gl_GlobalInvocationID.x + gl_GlobalInvocationID.y * 8u;
    if (mode.x == 0) {
        imageStore(img, ivec2(gl_GlobalInvocationID.xy),
                   vec4(float(gl_GlobalInvocationID.x * 32u) / 255.0, float(gl_GlobalInvocationID.y * 32u) / 255.0, 0.0, 1.0));
        words[i].v = i;
    } else {
        words[i].v = words[i].v * 2u + 1u;
    }
}
@end

@program compute compute_cs

// Copies texel (x, y) of a texture into an 8x8 storage image: a compute shader that samples (the texture and the
// storage image are views 0 and 1).
@cs sample_cs
layout(local_size_x=8, local_size_y=8, local_size_z=1) in;
layout(binding=0) uniform texture2D src_tex;
layout(binding=0) uniform sampler src_smp;
layout(binding=1, rgba8) uniform writeonly image2D dst_img;
void main() {
    ivec2 p = ivec2(gl_GlobalInvocationID.xy);
    imageStore(dst_img, p, texelFetch(sampler2D(src_tex, src_smp), p, 0));
}
@end

@program sample sample_cs
