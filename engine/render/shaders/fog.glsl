// FactorIA distance and height fog (PostProcess.fogEnabled, M71-D3b): one full-screen triangle over ONE camera's rectangle of the picture.
//
// The fog is blended over the finished scene colour: the pass reads only the prepass (r = linear view depth, a = 1 where an opaque mesh was
// drawn) and writes fogColor * f with alpha f, which the pipeline blends as `src + dst * (1 - f)` (the premultiplied "over": the same as
// mix(scene, fogColor, f)). Where nothing was drawn (the sky, 2D, the background) the pass writes nothing: the sky is not fogged, as the
// forward fog of the mesh shader does not fog it either.
//
// The view-space position of a pixel comes from the linear depth and the projection (the terms the CPU passes in `pa` and `pb`, as
// motion_blur.glsl does), so perspective and orthographic cameras share one code path. Along the view ray, from fogStart to the surface:
//   tau  = (density * L)^2                      the distance fog: the law of SceneSettings.fogDensity (exponential squared), so a
//                                               scene that moves its fog into the stack keeps its look
//        + integral of the height density       the height fog: hd above `base` falls off as exp(-falloff * (y - base)), and is hd
//                                               at and below it; integrated in closed form along the (straight) ray
//   f    = 1 - exp(-tau)
@module fog

@vs vs
layout(binding=0) uniform fog_vs_params {
    vec4 flip;      // x = 1 when render targets have their origin at the bottom (OpenGL), 0 otherwise
};
layout(location=0) in vec2 pos;
out vec2 uv;
void main() {
    gl_Position = vec4(pos, 0.0, 1.0);
    float v_top_down = 0.5 - pos.y * 0.5;
    float v_bottom_up = 0.5 + pos.y * 0.5;
    uv = vec2(pos.x * 0.5 + 0.5, mix(v_top_down, v_bottom_up, flip.x));
}
@end

@fs fs_fog
layout(binding=0) uniform texture2D tex_p;
layout(binding=0) uniform sampler smp_pt;
@image_sample_type tex_p unfilterable_float
@sampler_type smp_pt nonfiltering
layout(binding=1) uniform fog_params {
    vec4 a;         // x = 1 when render targets are bottom-up (OpenGL), y = 1 for an orthographic camera, zw = 0
    vec4 col;       // rgb = the fog colour (in the scene's colour space), w = density (distance fog)
    vec4 d;         // x = fogStart, y = height density, z = height base (world y), w = height falloff per world unit
    vec4 pa;        // the projection of the camera: P00, P11, P02, P12
    vec4 pb;        // P03, P13, P32, P33
    vec4 eye;       // xyz = the camera's world position, w = 0
    vec4 ax;        // the y components of the camera axes in world space: right.y, up.y, forward.y, 0
};
in vec2 uv;
out vec4 frag_color;

vec2 fl(vec2 s) { return vec2(s.x, mix(s.y, 1.0 - s.y, a.x)); }

// The height density at world y, and its integral from the base up to y (0 at the base, negative below it).
float h_at(float y) {
    float k = y - d.z;
    if (k <= 0.0 || d.w < 1e-4) return d.y;
    return d.y * exp(-min(d.w * k, 80.0));
}
float h_int(float y) {
    float k = y - d.z;
    if (k <= 0.0 || d.w < 1e-4) return d.y * k;
    return d.y * (1.0 - exp(-min(d.w * k, 80.0))) / d.w;
}

void main() {
    vec2 s = fl(uv);
    vec4 pre = textureLod(sampler2D(tex_p, smp_pt), fl(s), 0.0);
    if (pre.a < 0.5) {
        frag_color = vec4(0.0);  // nothing was drawn here: the sky is not fogged
        return;
    }
    float dep = pre.r;
    vec2 ndc = vec2(s.x * 2.0 - 1.0, 1.0 - s.y * 2.0);
    float z = -dep;
    float w = pb.z * z + pb.w;                       // clip w: -z for a perspective camera, 1 for an orthographic one
    vec3 vp = vec3((ndc.x * w - pa.z * z - pb.x) / pa.x, (ndc.y * w - pa.w * z - pb.y) / pa.y, z);
    float dist = a.y > 0.5 ? dep : length(vp);      // the length of the view ray to the surface
    float len = dist - d.x;                          // the part of it inside the fog
    if (!(len > 0.0)) {
        frag_color = vec4(0.0);
        return;
    }
    float tau = col.w * len;
    tau *= tau;
    if (d.y > 0.0) {
        float py = eye.y + ax.x * vp.x + ax.y * vp.y + ax.z * dep;   // world y of the surface
        float ey = a.y > 0.5 ? py - ax.z * dep : eye.y;               // world y where the ray starts (the eye, or the near plane's pixel)
        float ya = mix(ey, py, clamp(d.x / dist, 0.0, 1.0));          // world y where the fog begins
        float dy = py - ya;
        float avg = abs(dy) < 1e-3 ? h_at(ya) : (h_int(py) - h_int(ya)) / dy;
        tau += len * max(avg, 0.0);
    }
    float f = 1.0 - exp(-clamp(tau, 0.0, 80.0));
    frag_color = vec4(col.rgb * f, f);
}
@end

@program fog vs fs_fog
