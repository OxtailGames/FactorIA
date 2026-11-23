// The impostors' programs (M75-P1c, docs/BIG_WORLDS_LOD.md "Impostors"): a MeshRenderer far away is drawn as one camera-facing card that shows
// the baked picture of the model (an atlas of `views` x `views` frames, see fa/scene/impostor.h) from the three directions nearest to the
// camera's. The mesh template (mesh_common.glsl) with a vertex() that places the card and a surface() that reads the atlas; the lighting,
// the shadows, the fog, the clustered lights and the dithered LOD cross-fade are the ones of every MeshRenderer (alpha cutout: FA_ALPHA_CLIP).
// This file is the GLSL twin of impostor_direction, impostor_encode, impostor_basis and impostor_pick of engine/scene/src/impostor.cpp:
// engine/render/tests/impostor_render_tests.cpp compares the drawn pixels with the CPU side.
//
// Compiled with FA_HAS_VERTEX, FA_INST_2 and FA_ALPHA_CLIP (the `// shdc-defines:` line below; tools/shaders/compile_shaders.sh passes it
// to sokol-shdc).
// shdc-defines: FA_HAS_VERTEX:FA_INST_2:FA_ALPHA_CLIP
//
// Per card (instance data, two vec4): fa_id0 = (the world centre of the atlas, the world radius of its square; NEGATIVE for an entity whose
// matrix mirrors, a negative determinant: the model is then its x axis flipped and turned by a proper rotation), fa_id1 = that rotation world
// -> model as a quaternion (x, y, z, w).
// Per draw (the material block, binding 4 in the vertex stage and 5 in the fragment stage; the same four vec4):
//   fa_i_cam   xyz the camera's world position, w = frames per side of the atlas
//   fa_i_right xyz the camera's right axis, w = 1 for hemiOctahedral, 0 for octahedral
//   fa_i_up    xyz the camera's up axis, w = the fix of the albedo samples (fa_tex_fix of mesh_common.glsl: 0 as sampled, 1 sRGB to linear, 2 linear to sRGB)
//   fa_i_misc  x = the same fix for the normal samples, y = roughness, z = pixels of one frame's side
// The atlas: fragment view 6 (albedo, straight alpha) and 7 (model-space normal * 0.5 + 0.5), samplers 2 and 3, linear and clamped.
@module impostor

@block fa_user
// vertex() ignores the model matrix: the prepass derives the previous position from the matrices alone (mesh_common.glsl fa_prepass_vertex).
#define FA_VEL_STATIC_VERTEX
#ifdef GL_VERTEX_SHADER
layout(binding=4) uniform fa_material_vs {
    vec4 fa_i_cam; vec4 fa_i_right; vec4 fa_i_up; vec4 fa_i_misc;
};
#else
layout(binding=5) uniform fa_material {
    vec4 fa_i_cam; vec4 fa_i_right; vec4 fa_i_up; vec4 fa_i_misc;
};
layout(binding=6) uniform texture2D fa_i_albedo;
layout(binding=7) uniform texture2D fa_i_normal;
layout(binding=2) uniform sampler fa_i_albedo_smp;
layout(binding=3) uniform sampler fa_i_normal_smp;
#endif

const float alphaCutoff = 0.5;

// The per-card values, set from the instance buffer before vertex() / surface() run.
vec4 fa_id0;
vec4 fa_id1;
void fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2) {
    fa_id0 = fa_d0;
    fa_id1 = fa_d1;
}

#ifdef GL_VERTEX_SHADER
void vertex(inout VertexData v) {
    // The card: the square of side 2 * radius around the centre, facing the camera. The quad of the mesh has its corners at (+-1, +-1, 0).
    vec2 k = v.object_pos.xy;
    v.world_pos = fa_id0.xyz + (fa_i_right.xyz * k.x + fa_i_up.xyz * k.y) * abs(fa_id0.w);
    v.world_normal = normalize(fa_i_cam.xyz - fa_id0.xyz);
    v.world_tangent = vec4(fa_i_right.xyz, 1.0);
    v.uv = k * 0.5 + 0.5;
}
#else
float fa_i_sign(float x) { return x < 0.0 ? -1.0 : 1.0; }

// The rotation of the quaternion q applied to v.
vec3 fa_i_qrot(vec4 q, vec3 v) {
    vec3 t = 2.0 * cross(q.xyz, v);
    return v + q.w * t + cross(q.xyz, t);
}

// As fa_tex_fix of mesh_common.glsl, which is declared after this block.
vec3 fa_i_fix(vec3 c, float mode) {
    c = max(c, vec3(0.0));
    if (mode > 1.5) return mix(1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, c * 12.92, step(c, vec3(0.0031308)));
    if (mode > 0.5) return mix(pow((c + 0.055) / 1.055, vec3(2.4)), c / 12.92, step(c, vec3(0.04045)));
    return c;
}

// impostor_encode: the octahedral coordinates (-1..1) of a unit direction.
vec2 fa_i_encode(vec3 d, bool hemi) {
    if (hemi) {
        float l1 = abs(d.x) + abs(d.z) + max(d.y, 0.0);
        if (!(l1 > 1e-8)) return vec2(0.0);
        vec2 p = vec2(d.x, d.z) / l1;
        return clamp(vec2(p.x + p.y, p.x - p.y), vec2(-1.0), vec2(1.0));
    }
    float l1 = abs(d.x) + abs(d.y) + abs(d.z);
    if (!(l1 > 1e-8)) return vec2(0.0);
    vec2 p = vec2(d.x, d.z) / l1;
    if (d.y < 0.0) p = (vec2(1.0) - abs(vec2(p.y, p.x))) * vec2(fa_i_sign(p.x), fa_i_sign(p.y));
    return clamp(p, vec2(-1.0), vec2(1.0));
}

// impostor_direction: the direction the frame at the coordinates uv (-1..1) looks from.
vec3 fa_i_decode(vec2 uv, bool hemi) {
    float x, y, z;
    if (hemi) {
        x = (uv.x + uv.y) * 0.5;
        z = (uv.x - uv.y) * 0.5;
        y = 1.0 - abs(x) - abs(z);
    } else {
        x = uv.x;
        z = uv.y;
        y = 1.0 - abs(uv.x) - abs(uv.y);
        if (y < 0.0) {
            x = (1.0 - abs(uv.y)) * fa_i_sign(uv.x);
            z = (1.0 - abs(uv.x)) * fa_i_sign(uv.y);
        }
    }
    return normalize(vec3(x, y, z));
}

// What one frame (the cell, weighed w) adds at the model-space offset xl from the centre: its colour weighed by its alpha, its alpha and its
// normal turned to world space by qc.
// `lod` is the mip level both pictures are read at (a whole number, see surface()): the point is kept half a texel of that level inside the frame,
// so a smaller mip never averages in the neighbouring frame.
void fa_i_add(ivec2 cell, float w, vec3 xl, vec4 qc, float mirror, float radius, float n, bool hemi, float lod, inout vec4 acc, inout vec3 nrm) {
    vec3 d = fa_i_decode(vec2(cell) / (n - 1.0) * 2.0 - vec2(1.0), hemi);
    vec3 ref = abs(d.y) > 0.99 ? vec3(0.0, 0.0, -1.0) : vec3(0.0, 1.0, 0.0);  // impostor_basis
    vec3 r = normalize(cross(ref, d));
    vec3 u = cross(d, r);
    vec2 p = vec2(dot(xl, r), -dot(xl, u)) / (2.0 * radius) + vec2(0.5);  // 0..1 across the frame, v downwards
    float inside = (p.x >= 0.0 && p.x <= 1.0 && p.y >= 0.0 && p.y <= 1.0) ? 1.0 : 0.0;
    float half_px = min(0.5 * exp2(lod) / fa_i_misc.z, 0.5);
    vec2 f = mix(vec2(half_px), vec2(1.0 - half_px), clamp(p, vec2(0.0), vec2(1.0)));
    vec2 auv = (vec2(cell) + f) / n;
    vec4 c = textureLod(sampler2D(fa_i_albedo, fa_i_albedo_smp), auv, lod);
    vec3 nm = fa_i_fix(textureLod(sampler2D(fa_i_normal, fa_i_normal_smp), auv, lod).rgb, fa_i_misc.x) * 2.0 - vec3(1.0);
    float a = c.a * inside * w;
    acc += vec4(fa_i_fix(c.rgb, fa_i_up.w) * a, a);
    nm.x *= mirror;
    nrm += fa_i_qrot(qc, nm) * a;
}

void surface(in SurfaceInput i, inout Surface s) {
    vec3 centre = fa_id0.xyz;
    float radius = abs(fa_id0.w);
    float mirror = fa_id0.w < 0.0 ? -1.0 : 1.0;  // a mirroring matrix: the model's x axis is flipped after the rotation
    vec4 q = fa_id1;                       // world -> model
    vec4 qc = vec4(-q.xyz, q.w);           // model -> world
    float n = fa_i_cam.w;
    bool hemi = fa_i_right.w > 0.5;
    vec3 dl = normalize(fa_i_qrot(q, normalize(fa_i_cam.xyz - centre)));  // from the model towards the camera, in model space
    dl.x *= mirror;
    // impostor_pick: the corners of the triangle of the grid that holds the direction.
    float last = n - 1.0;
    vec2 g = clamp((fa_i_encode(dl, hemi) * 0.5 + vec2(0.5)) * last, vec2(0.0), vec2(last));
    ivec2 i0 = min(ivec2(floor(g)), ivec2(int(n + 0.5) - 2));
    vec2 fr = g - vec2(i0);
    ivec2 c0, c1, c2;
    vec3 w;
    if (fr.x + fr.y < 1.0) {
        c0 = i0;
        c1 = i0 + ivec2(1, 0);
        c2 = i0 + ivec2(0, 1);
        w = vec3(1.0 - fr.x - fr.y, fr.x, fr.y);
    } else {
        c0 = i0 + ivec2(1, 1);
        c1 = i0 + ivec2(0, 1);
        c2 = i0 + ivec2(1, 0);
        w = vec3(fr.x + fr.y - 1.0, 1.0 - fr.x, 1.0 - fr.y);
    }
    vec3 xl = fa_i_qrot(q, i.world_pos - centre);  // the fragment's offset from the centre, in model space
    xl.x *= mirror;
    // The mip level: the texels of a frame's side that one screen pixel covers on the card, as a whole level (the samplers pick the nearest
    // mip anyway), at most 3 and at most log2(frame) - 1, so a smaller card never reads a level whose texels are wider than a frame's border.
    float footprint = max(length(dFdx(i.world_pos)), length(dFdy(i.world_pos))) / (2.0 * radius) * fa_i_misc.z;
    float maxLod = max(min(3.0, floor(log2(fa_i_misc.z)) - 1.0), 0.0);
    float lod = clamp(floor(log2(max(footprint, 1.0)) + 0.5), 0.0, maxLod);
    vec4 acc = vec4(0.0);
    vec3 nrm = vec3(0.0);
    fa_i_add(c0, w.x, xl, qc, mirror, radius, n, hemi, lod, acc, nrm);
    fa_i_add(c1, w.y, xl, qc, mirror, radius, n, hemi, lod, acc, nrm);
    fa_i_add(c2, w.z, xl, qc, mirror, radius, n, hemi, lod, acc, nrm);
    s.albedo = acc.rgb / max(acc.a, 1e-4);
    s.alpha = acc.a;
    float nl = length(nrm);
    s.normal = nl > 1e-4 ? nrm / nl : i.world_normal;
    s.roughness = fa_i_misc.y;
    s.metallic = 0.0;
}
#endif
@end

@include mesh_common.glsl

@program impostor vs fs
@program shadow shadow_vs shadow_fs
@program prepass prepass_vs prepass_fs
